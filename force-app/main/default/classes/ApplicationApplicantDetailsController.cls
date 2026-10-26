/*_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________*/
/**
 * Controller for the applicantDetailsCmp LWC.
 * Field list is discovered dynamically via Schema describe on Application_Applicant__c —
 * every accessible field on the object is queried and rendered automatically, with no
 * hardcoded field list. Adding a new field to the object shows up on the UI with no
 * code change or deployment.
 */
public with sharing class ApplicationApplicantDetailsController {

    private static final Set<String> EXCLUDED_FIELDS = new Set<String>{
        'id', 'isdeleted', 'createddate', 'createdbyid', 'lastmodifieddate', 'lastmodifiedbyid',
        'systemmodstamp', 'lastactivitydate', 'lastvieweddate', 'lastreferenceddate', 'ownerid'
    };

    public class FieldValueWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public Boolean isLink;
        @AuraEnabled public String linkId;
        @AuraEnabled public String linkObjectName;
        @AuraEnabled public String columnPosition;
    }

    public class SectionWrapper {
        @AuraEnabled public String sectionName;
        @AuraEnabled public List<FieldValueWrapper> fields;
    }

    private class FieldMeta implements Comparable {
        String apiName;
        String label;
        String valueField;
        Boolean isLink = false;
        String linkObjectName;

        public Integer compareTo(Object other) {
            FieldMeta otherMeta = (FieldMeta) other;
            return this.label.compareTo(otherMeta.label);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<SectionWrapper> getApplicantDetails(Id recordId) {
        List<SectionWrapper> sectionList = new List<SectionWrapper>();

        if (recordId == null) {
            return sectionList;
        }

        List<FieldMeta> fieldMetas = describeAccessibleFields();
        fieldMetas.sort();

        if (fieldMetas.isEmpty()) {
            return sectionList;
        }

        Set<String> queryFields = new Set<String>{ 'Id' };
        for (FieldMeta meta : fieldMetas) {
            queryFields.add(meta.valueField);
            if (meta.isLink) {
                queryFields.add(meta.apiName);
            }
        }

        String soql = 'SELECT ' + String.join(new List<String>(queryFields), ', ') +
            ' FROM Application_Applicant__c WHERE Id = :recordId WITH USER_MODE LIMIT 1';
        List<SObject> records = Database.query(soql);

        if (records.isEmpty()) {
            return sectionList;
        }

        SObject applicantRecord = records[0];

        SectionWrapper section = new SectionWrapper();
        section.sectionName = 'Application Applicant Details';
        section.fields = new List<FieldValueWrapper>();

        Integer index = 0;
        for (FieldMeta meta : fieldMetas) {
            FieldValueWrapper wrapper = new FieldValueWrapper();
            wrapper.label = meta.label;
            wrapper.columnPosition = Math.mod(index, 2) == 0 ? 'Left' : 'Right';
            wrapper.isLink = meta.isLink;

            Object fieldValue = getFieldValue(applicantRecord, meta.valueField);
            wrapper.value = fieldValue == null ? '' : String.valueOf(fieldValue);

            if (wrapper.isLink) {
                Object linkIdValue = getFieldValue(applicantRecord, meta.apiName);
                wrapper.linkId = linkIdValue == null ? null : String.valueOf(linkIdValue);
                wrapper.linkObjectName = meta.linkObjectName;
                wrapper.isLink = wrapper.linkId != null;
            }

            section.fields.add(wrapper);
            index++;
        }

        sectionList.add(section);
        return sectionList;
    }

    /**
     * Describes every accessible, non-system field on Application_Applicant__c and resolves
     * lookup fields to a displayable relationship.Name path (when the referenced object exposes
     * an accessible Name field), falling back to the raw Id otherwise.
     */
    private static List<FieldMeta> describeAccessibleFields() {
        List<FieldMeta> fieldMetas = new List<FieldMeta>();

        Schema.DescribeSObjectResult objDescribe = Application_Applicant__c.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        for (String fieldName : fieldMap.keySet()) {
            if (EXCLUDED_FIELDS.contains(fieldName)) {
                continue;
            }

            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            if (!fieldDescribe.isAccessible() || fieldDescribe.getType() == Schema.DisplayType.BASE64) {
                continue;
            }

            FieldMeta meta = new FieldMeta();
            meta.apiName = fieldDescribe.getName();
            meta.label = fieldDescribe.getLabel();

            if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                String relationshipName = fieldDescribe.getRelationshipName();
                List<Schema.SObjectType> refTypes = fieldDescribe.getReferenceTo();

                if (relationshipName != null && !refTypes.isEmpty()) {
                    Schema.DescribeSObjectResult refDescribe = refTypes[0].getDescribe();
                    Map<String, Schema.SObjectField> refFieldMap = refDescribe.fields.getMap();

                    if (refFieldMap.containsKey('name') && refFieldMap.get('name').getDescribe().isAccessible()) {
                        meta.valueField = relationshipName + '.Name';
                        meta.isLink = true;
                        meta.linkObjectName = refDescribe.getName();
                    } else {
                        meta.valueField = meta.apiName;
                    }
                } else {
                    meta.valueField = meta.apiName;
                }
            } else {
                meta.valueField = meta.apiName;
            }

            fieldMetas.add(meta);
        }

        return fieldMetas;
    }

    /**
     * Resolves a (possibly dotted) relationship field path, e.g. "Owner.Name",
     * against a queried SObject.
     */
    private static Object getFieldValue(SObject record, String fieldPath) {
        if (record == null || String.isBlank(fieldPath)) {
            return null;
        }

        List<String> parts = fieldPath.split('\\.');
        SObject current = record;

        for (Integer i = 0; i < parts.size() - 1; i++) {
            if (current == null) {
                return null;
            }
            current = current.getSObject(parts[i]);
        }

        return current == null ? null : current.get(parts[parts.size() - 1]);
    }
}
/*__________________________GenAI: Generated code ends here______________________________*/