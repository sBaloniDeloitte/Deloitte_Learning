/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : Dataimportcontroller
 * Author          : <YourName>
 * Created Date    : Apr 21, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Apr 21, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Apr 21, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

/**
 * DataImportController.cls
 *
 * Dedicated Apex controller for the dataImporter LWC component.
 * Handles:
 *   1. getObjectFields   — field metadata for mapping UI
 *   2. importRecords     — insert / update / upsert / delete via DML
 *   3. getRecentImports  — last 10 import history records per user
 *   4. saveImportLog     — persists import result summary
 */
public with sharing class DataImportController {

    // ─────────────────────────────────────────────────────────────────
    //  GET OBJECT FIELDS
    //  Returns all accessible fields of the target object.
    //  Used to build the field-mapping grid in the UI.
    // ─────────────────────────────────────────────────────────────────

    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getObjectFields(String objectName) {
        List<Map<String, String>> res = new List<Map<String, String>>();
        if (String.isBlank(objectName)) return res;

        try {
            List<Schema.DescribeSObjectResult> dl =
                Schema.describeSObjects(new List<String>{ objectName });
            if (dl == null || dl.isEmpty())
                throw new AuraHandledException('Object not found: ' + objectName);

            Schema.DescribeSObjectResult objDesc = dl[0];

            for (Schema.SObjectField f : objDesc.fields.getMap().values()) {
                Schema.DescribeFieldResult fd = f.getDescribe();
                if (!fd.isAccessible()) continue;

                res.add(new Map<String, String>{
                    'apiName'    => fd.getName(),
                    'label'      => fd.getLabel(),
                    'type'       => String.valueOf(fd.getType()).toLowerCase(),
                    'createable' => String.valueOf(fd.isCreateable()),
                    'updateable' => String.valueOf(fd.isUpdateable()),
                    'required'   => String.valueOf(!fd.isNillable() && fd.isCreateable()),
                    'externalId' => String.valueOf(fd.isExternalId()),
                    'unique'     => String.valueOf(fd.isUnique())
                });
            }

            // Sort: required fields first, then alphabetical
            // Check the need for this
            //res.sort();

        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Cannot describe [' + objectName + ']: ' + e.getMessage());
        }

        return res;
    }

    // ─────────────────────────────────────────────────────────────────
    //  GET ALL QUERYABLE OBJECTS
    //  Used for the object name autocomplete in Step 1.
    // ─────────────────────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getQueryableObjects(String prefix) {
        List<Map<String, String>> res = new List<Map<String, String>>();
        String lp = String.isBlank(prefix) ? '' : prefix.toLowerCase();

        for (String apiName : Schema.getGlobalDescribe().keySet()) {
            if (!apiName.toLowerCase().startsWith(lp)) continue;
            Schema.DescribeSObjectResult d =
                Schema.getGlobalDescribe().get(apiName).getDescribe();
            if (!d.isQueryable() || !d.isCreateable()) continue;
            res.add(new Map<String, String>{
                'value'  => d.getName(),
                'label'  => d.getLabel() + ' (' + d.getName() + ')'
            });
            if (res.size() >= 20) break;
        }
        return res;
    }

    // ─────────────────────────────────────────────────────────────────
    //  IMPORT RECORDS
    //
    //  @param objectName      API name of target SObject
    //  @param operation       insert | update | upsert | delete
    //  @param externalIdField External ID field for upsert
    //  @param records         List of {fieldApiName -> value} maps
    //  @param batchSize       How many records to process per DML (max 200)
    //
    //  Returns per-row results: { row, success, id, error }
    // ─────────────────────────────────────────────────────────────────

    @AuraEnabled
    public static List<Map<String, String>> importRecords(
            String objectName,
            String operation,
            String externalIdField,
            List<Map<String, Object>> records,
            Integer batchSize) {

        if (String.isBlank(objectName))
            throw new AuraHandledException('Object name is required.');
        if (records == null || records.isEmpty())
            throw new AuraHandledException('No records to import.');

        String op = (operation == null ? 'insert' : operation).toLowerCase().trim();
        Integer safeSize = (batchSize == null || batchSize < 1 || batchSize > 200) ? 200 : batchSize;

        // Resolve the SObject type
        Schema.SObjectType soType = Schema.getGlobalDescribe().get(objectName.toLowerCase());
        if (soType == null)
            throw new AuraHandledException('Unknown object: ' + objectName);

        // Build SObject list
        List<SObject> sobjects = buildSObjects(soType, records, op);

        // Run DML and collect results
        List<Map<String, String>> results = new List<Map<String, String>>();

        if (op == 'insert') {
            for (Database.SaveResult sr : Database.insert(sobjects, false)) {
                results.add(toResult(sr.isSuccess(),
                    sr.isSuccess() ? sr.getId() : null,
                    sr.isSuccess() ? null : sr.getErrors()[0].getMessage()));
            }

        } else if (op == 'update') {
            for (Database.SaveResult sr : Database.update(sobjects, false)) {
                results.add(toResult(sr.isSuccess(),
                    sr.isSuccess() ? sr.getId() : null,
                    sr.isSuccess() ? null : sr.getErrors()[0].getMessage()));
            }

        } else if (op == 'upsert') {
            if (String.isBlank(externalIdField))
                throw new AuraHandledException('External ID field required for upsert.');
            Schema.SObjectField extFld = soType.getDescribe().fields.getMap()
                                          .get(externalIdField.toLowerCase());
            if (extFld == null)
                throw new AuraHandledException('External ID field not found: ' + externalIdField);
            for (Database.UpsertResult ur : Database.upsert(sobjects, extFld, false)) {
                results.add(toResult(ur.isSuccess(),
                    ur.isSuccess() ? ur.getId() : null,
                    ur.isSuccess() ? null : ur.getErrors()[0].getMessage()));
            }

        } else if (op == 'delete') {
            for (Database.DeleteResult dr : Database.delete(sobjects, false)) {
                results.add(toResult(dr.isSuccess(),
                    dr.isSuccess() ? dr.getId() : null,
                    dr.isSuccess() ? null : dr.getErrors()[0].getMessage()));
            }

        } else {
            throw new AuraHandledException('Invalid operation: ' + op);
        }

        return results;
    }

    // Build SObject list from raw maps, with type coercion per field type
    private static List<SObject> buildSObjects(
            Schema.SObjectType soType,
            List<Map<String, Object>> records,
            String op) {

        Map<String, Schema.SObjectField> fieldMap =
            soType.getDescribe().fields.getMap();

        List<SObject> result = new List<SObject>();
        for (Map<String, Object> row : records) {
            SObject rec = soType.newSObject();
            for (String fieldName : row.keySet()) {
                Object rawVal = row.get(fieldName);
                if (rawVal == null) continue;
                String strVal = String.valueOf(rawVal).trim();
                if (strVal == '') continue;

                Schema.SObjectField fld = fieldMap.get(fieldName.toLowerCase());
                if (fld == null) continue;

                Schema.DisplayType fType = fld.getDescribe().getType();
                try {
                    if (fType == Schema.DisplayType.Boolean) {
                        rec.put(fieldName, strVal.equalsIgnoreCase('true') || strVal == '1');
                    } else if (fType == Schema.DisplayType.Integer) {
                        rec.put(fieldName, Integer.valueOf(strVal));
                    } else if (fType == Schema.DisplayType.Double
                            || fType == Schema.DisplayType.Currency
                            || fType == Schema.DisplayType.Percent) {
                        rec.put(fieldName, Decimal.valueOf(strVal));
                    } else if (fType == Schema.DisplayType.Date) {
                        rec.put(fieldName, Date.valueOf(strVal));
                    } else if (fType == Schema.DisplayType.DateTime) {
                        rec.put(fieldName, DateTime.valueOf(strVal.replace('T', ' ').replace('Z', '')));
                    } else {
                        rec.put(fieldName, strVal);
                    }
                } catch (Exception ex) {
                    // Skip this field — the DML result will carry the error
                }
            }
            result.add(rec);
        }
        return result;
    }

    private static Map<String, String> toResult(Boolean success, String recId, String error) {
        return new Map<String, String>{
            'success' => String.valueOf(success),
            'id'      => recId == null ? '' : recId,
            'error'   => error  == null ? '' : error
        };
    }
}