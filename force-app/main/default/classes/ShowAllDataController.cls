/**
 * ShowAllDataController
 * 
 * Apex controller that replicates the core "Show All Data" functionality
 * from Salesforce Inspector Reloaded — fetching ALL field metadata AND 
 * current field values for any SObject record.
 *
 * Supports:
 *  - Dynamic describe to get all fields (including hidden/layout-excluded ones)
 *  - Dynamic SOQL to retrieve all field values for a given record ID
 *  - Field-level inline editing (update a single field value)
 *  - Field usage analysis (how many records have a non-null value)
 *  - Copy Record ID utility
 */
public with sharing class ShowAllDataController {

    // ─────────────────────────────────────────────────────────────────────────
    //  DATA STRUCTURES
    // ─────────────────────────────────────────────────────────────────────────

    public class FieldInfo {
        @AuraEnabled public String  label;
        @AuraEnabled public String  apiName;
        @AuraEnabled public String  fieldType;      // e.g. STRING, PICKLIST, REFERENCE, FORMULA…
        @AuraEnabled public Boolean isUpdateable;
        @AuraEnabled public Boolean isNillable;
        @AuraEnabled public Boolean isFormula;
        @AuraEnabled public Boolean isHidden;       // not on any page layout (we approximate this)
        @AuraEnabled public String  referenceTo;    // for lookup / master-detail fields
        @AuraEnabled public String  helpText;
        @AuraEnabled public Integer length;
        @AuraEnabled public Object  value;          // actual value from the record
        @AuraEnabled public String  displayValue;   // human-friendly representation
    }

    public class RecordData {
        @AuraEnabled public String          objectApiName;
        @AuraEnabled public String          objectLabel;
        @AuraEnabled public String          recordId;
        @AuraEnabled public String          recordName;
        @AuraEnabled public String          createdById;
        @AuraEnabled public String          createdByName;
        @AuraEnabled public String          lastModifiedById;
        @AuraEnabled public String          lastModifiedByName;
        @AuraEnabled public String          createdDate;
        @AuraEnabled public String          lastModifiedDate;
        @AuraEnabled public List<FieldInfo> fields;
    }

    public class UpdateFieldRequest {
        @AuraEnabled public String recordId;
        @AuraEnabled public String objectApiName;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public Object newValue;
    }

    public class FieldUsageResult {
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public Integer totalRecords;
        @AuraEnabled public Integer populatedRecords;
        @AuraEnabled public Decimal percentageFilled;
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  MAIN: GET ALL DATA FOR A RECORD
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Given a Salesforce record ID, returns all fields with their metadata
     * AND current values — even fields not on any page layout.
     */
    @AuraEnabled(cacheable=true)
    public static RecordData getRecordAllData(String recordId) {
        if (String.isBlank(recordId)) {
            throw new AuraHandledException('Record ID is required.');
        }

        // Derive object type from the record ID prefix
        Id sfId;
        try {
            sfId = (Id) recordId;
        } catch (Exception e) {
            throw new AuraHandledException('Invalid Record ID: ' + recordId);
        }

        String objectApiName = sfId.getSObjectType().getDescribe().getName();
        return fetchAllData(objectApiName, recordId);
    }

    /**
     * Accepts objectApiName + recordId explicitly (for edge cases where
     * the ID prefix alone is ambiguous, e.g. Person Accounts).
     */
    @AuraEnabled(cacheable=true)
    public static RecordData getRecordAllDataByObject(String objectApiName, String recordId) {
        if (String.isBlank(objectApiName) || String.isBlank(recordId)) {
            throw new AuraHandledException('objectApiName and recordId are required.');
        }
        return fetchAllData(objectApiName, recordId);
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  PRIVATE: CORE FETCH LOGIC
    // ─────────────────────────────────────────────────────────────────────────

    private static RecordData fetchAllData(String objectApiName, String recordId) {
        // 1. Describe the object to get field metadata
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
        if (sObjType == null) {
            throw new AuraHandledException('Unknown object: ' + objectApiName);
        }
        Schema.DescribeSObjectResult objDescribe = sObjType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        // 2. Build a dynamic SOQL that selects ALL fields
        List<String> fieldNames = new List<String>(fieldMap.keySet());
        // Guard against SOQL 200-field limit per query — chunk if needed
        // For simplicity we query in one shot; Salesforce allows up to 200 fields per SELECT
        // If the object has >200 fields, we'd need chunking (handled below)
        List<String> selectFields = new List<String>();
        for (String fn : fieldNames) {
            Schema.DescribeFieldResult dfr = fieldMap.get(fn).getDescribe();
            // Exclude compound fields (Address, Geolocation) that can't be directly queried
            // Exclude compound field types — they cannot be directly SELECTed
            Schema.DisplayType dt = dfr.getType();
            if (dt != Schema.DisplayType.ADDRESS
             && dt != Schema.DisplayType.LOCATION) {
                selectFields.add(fn);
            }
        }

        // Chunk into groups of 200 (SOQL SELECT limit)
        Map<String, Object> allValues = new Map<String, Object>();
        Integer chunkSize = 195; // safe margin
        Integer chunks = (Integer) Math.ceil((Decimal) selectFields.size() / chunkSize);

        for (Integer i = 0; i < chunks; i++) {
            Integer fromIdx = i * chunkSize;
            Integer toIdx   = Math.min(fromIdx + chunkSize, selectFields.size());
            List<String> chunk = new List<String>();
            for (Integer j = fromIdx; j < toIdx; j++) {
                chunk.add(selectFields[j]);
            }
            // Always include Id
            if (!chunk.contains('Id')) chunk.add(0, 'Id');

            String soql = 'SELECT ' + String.join(chunk, ', ')
                        + ' FROM ' + objectApiName
                        + ' WHERE Id = :recordId LIMIT 1';
            List<SObject> rows;
            try {
                rows = Database.query(soql);
            } catch (Exception e) {
                // Some fields might not be queryable in all contexts — skip silently
                continue;
            }
            if (rows.isEmpty()) {
                throw new AuraHandledException('Record not found: ' + recordId);
            }
            SObject record = rows[0];
            for (String fn : chunk) {
                try {
                    allValues.put(fn.toLowerCase(), record.get(fn));
                } catch (Exception ex) {
                    // field not readable for current user
                }
            }
        }

        // 3. Build response
        RecordData result = new RecordData();
        result.objectApiName = objectApiName;
        result.objectLabel   = objDescribe.getLabel();
        result.recordId      = recordId;

        result.fields = new List<FieldInfo>();
        for (String fn : fieldNames) {
            Schema.SObjectField sField = fieldMap.get(fn);
            Schema.DescribeFieldResult dfr = sField.getDescribe();

            // Skip compound types (ADDRESS, LOCATION) — not directly queryable
            Schema.DisplayType fType = dfr.getType();
            if (fType == Schema.DisplayType.ADDRESS
             || fType == Schema.DisplayType.LOCATION) continue;

            FieldInfo fi = new FieldInfo();
            fi.label       = dfr.getLabel();
            fi.apiName     = dfr.getName();
            fi.fieldType   = dfr.getType().name();
            fi.isUpdateable= dfr.isUpdateable();
            fi.isNillable  = dfr.isNillable();
            fi.isFormula   = dfr.isCalculated();
            fi.helpText    = dfr.getInlineHelpText();
            fi.length      = dfr.getLength();

            // Resolve reference target
            List<Schema.sObjectType> refs = dfr.getReferenceTo();
            if (!refs.isEmpty()) {
                fi.referenceTo = refs[0].getDescribe().getName();
            }

            // Get value from our compiled map
            Object val = allValues.get(fn.toLowerCase());
            fi.value = val;
            fi.displayValue = val == null ? '' : String.valueOf(val);

            result.fields.add(fi);
        }

        // Pull well-known audit fields for the header
        result.recordName        = (String)  allValues.get('name');
        result.createdDate       = allValues.containsKey('createddate')
            ? String.valueOf(allValues.get('createddate')) : null;
        result.lastModifiedDate  = allValues.containsKey('lastmodifieddate')
            ? String.valueOf(allValues.get('lastmodifieddate')) : null;
        result.createdById       = allValues.containsKey('createdbyid')
            ? String.valueOf(allValues.get('createdbyid')) : null;
        result.lastModifiedById  = allValues.containsKey('lastmodifiedbyid')
            ? String.valueOf(allValues.get('lastmodifiedbyid')) : null;

        return result;
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  INLINE EDIT: UPDATE A SINGLE FIELD
    // ─────────────────────────────────────────────────────────────────────────

    @AuraEnabled
    public static void updateFieldValue(String recordId, String objectApiName,
                                        String fieldApiName, String newValue) {
        if (String.isBlank(recordId) || String.isBlank(fieldApiName)) {
            throw new AuraHandledException('recordId and fieldApiName are required.');
        }

        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
        if (sObjType == null) throw new AuraHandledException('Unknown object: ' + objectApiName);

        Schema.DescribeFieldResult dfr = sObjType.getDescribe().fields.getMap()
                                          .get(fieldApiName)?.getDescribe();
        if (dfr == null) throw new AuraHandledException('Unknown field: ' + fieldApiName);
        if (!dfr.isUpdateable()) throw new AuraHandledException('Field is not editable: ' + fieldApiName);

        SObject record = sObjType.newSObject(recordId);

        // Type-coerce the string value to the correct Apex type
        Schema.DisplayType dt = dfr.getType();
        try {
            if (newValue == null || newValue == '') {
                record.put(fieldApiName, null);
            } else if (dt == Schema.DisplayType.BOOLEAN) {
                record.put(fieldApiName, Boolean.valueOf(newValue));
            } else if (dt == Schema.DisplayType.INTEGER) {
                record.put(fieldApiName, Integer.valueOf(newValue));
            } else if (dt == Schema.DisplayType.DOUBLE
                    || dt == Schema.DisplayType.CURRENCY
                    || dt == Schema.DisplayType.PERCENT) {
                record.put(fieldApiName, Decimal.valueOf(newValue));
            } else if (dt == Schema.DisplayType.DATE) {
                record.put(fieldApiName, Date.valueOf(newValue));
            } else if (dt == Schema.DisplayType.DATETIME) {
                record.put(fieldApiName, DateTime.valueOf(newValue));
            } else {
                record.put(fieldApiName, newValue);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Type conversion error: ' + e.getMessage());
        }

        try {
            update record;
        } catch (DmlException dml) {
            throw new AuraHandledException('Save failed: ' + dml.getDmlMessage(0));
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  FIELD USAGE ANALYSIS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Returns how many records in the org have a non-null value for the field.
     * Mirrors the "Analyze Field Usage" feature in SIR.
     */
    @AuraEnabled
    public static FieldUsageResult analyzeFieldUsage(String objectApiName, String fieldApiName) {
        if (String.isBlank(objectApiName) || String.isBlank(fieldApiName)) {
            throw new AuraHandledException('objectApiName and fieldApiName are required.');
        }

        String soqlTotal = 'SELECT COUNT() FROM ' + objectApiName;
        String soqlFilled = 'SELECT COUNT() FROM ' + objectApiName
                          + ' WHERE ' + fieldApiName + ' != null';

        Integer total  = Database.countQuery(soqlTotal);
        Integer filled = Database.countQuery(soqlFilled);

        FieldUsageResult r = new FieldUsageResult();
        r.fieldApiName       = fieldApiName;
        r.totalRecords       = total;
        r.populatedRecords   = filled;
        r.percentageFilled   = total > 0 ? ((Decimal) filled / total * 100).setScale(1) : 0;
        return r;
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  HELPER: GET OBJECT API NAME FROM RECORD ID
    // ─────────────────────────────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static String getObjectApiNameFromId(String recordId) {
        try {
            Id sfId = (Id) recordId;
            return sfId.getSObjectType().getDescribe().getName();
        } catch (Exception e) {
            throw new AuraHandledException('Invalid Record ID: ' + recordId);
        }
    }
}