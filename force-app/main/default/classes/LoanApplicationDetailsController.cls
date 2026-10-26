/*_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________*/
/**
 * Controller for the loanApplicationDetailsCmp LWC.
 * Field list is driven dynamically by Loan_Application_Field_Config__mdt custom metadata records —
 * adding, removing, or reordering a field on the UI only requires editing metadata records,
 * no code change or deployment.
 */
public with sharing class LoanApplicationDetailsController {

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

    @AuraEnabled(cacheable=true)
    public static List<SectionWrapper> getLoanApplicationDetails(Id recordId) {
        List<SectionWrapper> sectionList = new List<SectionWrapper>();

        if (recordId == null) {
            return sectionList;
        }

        List<Loan_Application_Field_Config__mdt> fieldConfigs = [
            SELECT Field_Label__c,
                   Field_API_Name__c,
                   Is_Link__c,
                   Link_Id_Field__c,
                   Link_Object_Name__c,
                   Column_Position__c,
                   Section_Name__c
            FROM Loan_Application_Field_Config__mdt
            WHERE Is_Active__c = true
            ORDER BY Section_Order__c ASC, Column_Position__c ASC, Display_Order__c ASC
        ];

        if (fieldConfigs.isEmpty()) {
            return sectionList;
        }

        Set<String> queryFields = new Set<String>{ 'Id' };
        for (Loan_Application_Field_Config__mdt config : fieldConfigs) {
            if (String.isNotBlank(config.Field_API_Name__c)) {
                queryFields.add(config.Field_API_Name__c);
            }
            if (config.Is_Link__c == true && String.isNotBlank(config.Link_Id_Field__c)) {
                queryFields.add(config.Link_Id_Field__c);
            }
        }

        String soql = 'SELECT ' + String.join(new List<String>(queryFields), ', ') +
            ' FROM Opportunity WHERE Id = :recordId WITH USER_MODE LIMIT 1';
        List<SObject> records = Database.query(soql);

        if (records.isEmpty()) {
            return sectionList;
        }

        SObject loanApplication = records[0];

        Map<String, SectionWrapper> sectionsByName = new Map<String, SectionWrapper>();
        List<String> sectionOrder = new List<String>();

        for (Loan_Application_Field_Config__mdt config : fieldConfigs) {
            FieldValueWrapper wrapper = new FieldValueWrapper();
            wrapper.label = config.Field_Label__c;
            wrapper.columnPosition = config.Column_Position__c;
            wrapper.isLink = config.Is_Link__c == true;

            Object fieldValue = getFieldValue(loanApplication, config.Field_API_Name__c);
            wrapper.value = fieldValue == null ? '' : String.valueOf(fieldValue);

            if (wrapper.isLink) {
                Object linkIdValue = getFieldValue(loanApplication, config.Link_Id_Field__c);
                wrapper.linkId = linkIdValue == null ? null : String.valueOf(linkIdValue);
                wrapper.linkObjectName = config.Link_Object_Name__c;
                wrapper.isLink = wrapper.linkId != null;
            }

            String sectionName = config.Section_Name__c;
            SectionWrapper section = sectionsByName.get(sectionName);
            if (section == null) {
                section = new SectionWrapper();
                section.sectionName = sectionName;
                section.fields = new List<FieldValueWrapper>();
                sectionsByName.put(sectionName, section);
                sectionOrder.add(sectionName);
            }
            section.fields.add(wrapper);
        }

        for (String sectionName : sectionOrder) {
            sectionList.add(sectionsByName.get(sectionName));
        }

        return sectionList;
    }

    /**
     * Resolves a (possibly dotted) relationship field path, e.g. "Account.Name",
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