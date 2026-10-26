/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-24-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class SalesLoanLoginIntegrationDetailsCheck { 
    @AuraEnabled
    public static List<IntegrationMasterDataWrapper> checkMasterData(Id loanId, String stage) {
        // List<Integration_Master__mdt> intMdts = [SELECT Id, API_Applicability__c, Stage__c, Activity_Name__c, Mandatory_Object_and_Field__c, Process_Name__c
        //                                         FROM Integration_Master__mdt WHERE Stage__c = 'Draft' AND API_Applicability__c IN ('Mandatory', 'Conditional Mandatory')];
        List<Integration_Master__mdt> intMdts;
        if (stage == null) {
            intMdts = [
                SELECT Id, Label, API_Applicability__c, Stage__c, Activity_Name__c, Mandatory_Object_and_Field__c, Process_Name__c
                FROM Integration_Master__mdt
                WHERE Controller_Class_and_Method__c != null AND API_Applicability__c IN ('Mandatory', 'Conditional Mandatory')
            ];
        } else if (stage == 'Credit') {
            intMdts = [
                SELECT Id, Label, API_Applicability__c, Stage__c, Activity_Name__c, Mandatory_Object_and_Field__c, Process_Name__c
                FROM Integration_Master__mdt
                WHERE Is_KYC__c = true AND Controller_Class_and_Method__c != null AND API_Applicability__c IN ('Mandatory', 'Conditional Mandatory')
            ];
        } else {
            intMdts = [
                SELECT Id, Label, API_Applicability__c, Stage__c, Activity_Name__c, Mandatory_Object_and_Field__c, Process_Name__c
                FROM Integration_Master__mdt
                WHERE Stage__c = :stage AND Controller_Class_and_Method__c != null AND API_Applicability__c IN ('Mandatory', 'Conditional Mandatory')
            ];
        }
        List<IntegrationMasterDataWrapper> wrapperList = new List<IntegrationMasterDataWrapper>();
        Map<String, List<String>> objectFieldMap = new Map<String, List<String>>();
        Map<String, IntegrationMasterDataWrapper> wrapperMap = new Map<String, IntegrationMasterDataWrapper>();

        for (Integration_Master__mdt intMdt : intMdts) {
            IntegrationMasterDataWrapper wrapper = new IntegrationMasterDataWrapper(
                intMdt.Id,
                intMdt.Stage__c, 
                intMdt.Activity_Name__c,
                intMdt.Label,
                intMdt.API_Applicability__c == 'Mandatory'
            );

            if (intMdt.Process_Name__c == 'Application Applicant') {
                System.debug('inside Application Applicant Process Name');
                wrapper.applicantWrappers = getApplicantsForLoan(loanId, intMdt.Label);
            }

            if (intMdt.API_Applicability__c == 'Conditional Mandatory' && String.isNotBlank(intMdt.Mandatory_Object_and_Field__c)) {
                parseMandatoryFields(intMdt.Mandatory_Object_and_Field__c, objectFieldMap, intMdt.Activity_Name__c);

                for (String pair : intMdt.Mandatory_Object_and_Field__c.split(',')) {
                    String[] objField = pair.trim().split('-');
                    if (objField.size() == 2) {
                        String uniqueKey = objField[0].trim() + '-' + objField[1].trim() + '-' + intMdt.Activity_Name__c;
                        wrapperMap.put(uniqueKey, wrapper);
                    }
                }
            }

            wrapperList.add(wrapper);
        }

        System.debug('Final objectFieldMap before running queries --> ' + objectFieldMap);

        updateWrapperWithQueryResults(objectFieldMap, loanId, wrapperMap);
        
        System.debug('Final Wrapper List Data: ' + JSON.serialize(wrapperList));
        return wrapperList;
    }

    private static void parseMandatoryFields(String mandatoryFields, Map<String, List<String>> objectFieldMap, String activityName) {
        for (String pair : mandatoryFields.split(',')) {
            String[] objField = pair.trim().split('-');
    
            if (objField.size() == 2) {
                String objectName = objField[0].trim();
                String fieldName = objField[1].trim();
    
                String uniqueKey = objectName + '-' + fieldName + '-' + activityName;
    
                if (!objectFieldMap.containsKey(uniqueKey)) {
                    objectFieldMap.put(uniqueKey, new List<String>{fieldName});
                }
            }
        }
    }
    
    private static void updateWrapperWithQueryResults(Map<String, List<String>> objectFieldMap, Id loanId, Map<String, IntegrationMasterDataWrapper> wrapperMap) { 
        System.debug('Executing updateWrapperWithQueryResults...');
        
        Map<String, String> objectQueries = new Map<String, String>();
        Set<Id> applicantIds = new Set<Id>();

        System.debug('objectFieldMap : ' + objectFieldMap);

        for (IntegrationMasterDataWrapper wrapper : wrapperMap.values()) {
            wrapper.viewWrapper = false;  
            for (ApplicantWrapper applicant : wrapper.applicantWrappers) {
                applicant.viewApplicant = false; 
                applicantIds.add(applicant.applicantId);
            }
        }

        for (String uniqueKey : objectFieldMap.keySet()) {
            List<String> fields = objectFieldMap.get(uniqueKey);
            if (fields.isEmpty()) continue;

            String[] keyParts = uniqueKey.split('-');
            String objectName = keyParts[0];
            String fieldName = keyParts[1];
            String activityName = keyParts[2];
            System.debug('Object Name: ' + objectName + ' | Field Name: ' + fieldName);

            if (objectName == 'Application_Applicant__c') {
                if (!applicantIds.isEmpty()) {
                    System.debug('applicantIds: ' + applicantIds);
                    String applicantQuery = 'SELECT Id FROM Application_Applicant__c WHERE Id IN :applicantIds AND ' + fieldName + ' != NULL';
                    System.debug('Executing Batch Query for Application_Applicant__c: ' + applicantQuery);

                    try {
                        List<Application_Applicant__c> applicantRecords = Database.query(applicantQuery);
                        System.debug('applicantRecords :' + applicantRecords);

                        Set<Id> foundApplicantIds = new Set<Id>();
                        if(applicantRecords.size() > 0) {
                            System.debug('inside applicant rcord size');
                            for (Application_Applicant__c record : applicantRecords) {
                                foundApplicantIds.add(record.Id);
                                for (IntegrationMasterDataWrapper wrapper : wrapperMap.values()) {
                                    if (wrapper.activityName == activityName) {
                                        for (ApplicantWrapper applicant : wrapper.applicantWrappers) {
                                            if (applicant.applicantId == record.Id) {  
                                                applicant.hasData = true;
                                                System.debug('Updated hasData to true for applicant: ' + applicant.applicantId);
                                            }
                                        }
                                    }
                                }                 
                            }
                        }

                        System.debug('foundApplicantIds: ' + foundApplicantIds);
                        if(foundApplicantIds.size()>0) {
                            for (IntegrationMasterDataWrapper wrapper : wrapperMap.values()) {
                                Boolean hasValidApplicant = false;
                                System.debug('Inside for 1'+wrapper);
                                for (ApplicantWrapper applicant : wrapper.applicantWrappers) {
                                    System.debug('Inside for 2');
                                    if(applicant.hasData == true) {
                                        if (foundApplicantIds.contains(applicant.applicantId)) {
                                            System.debug('contains true');
                                            applicant.viewApplicant = true;
                                            hasValidApplicant = true;
                                        }
                                    }
                                }

                                wrapper.viewWrapper = hasValidApplicant;
                            }
                        }

                    } catch (Exception e) {
                        System.debug('SOQL Query Error for Application_Applicant__c - ' + e.getMessage());
                    }
                }
            } else {
                String lookupField = getLookupFieldToLoan(objectName);
                if (String.isEmpty(lookupField)) continue;
   
                String query = 'SELECT Id FROM ' + objectName +
                               ' WHERE ' + lookupField + ' = :loanId AND ' + fieldName + ' != NULL LIMIT 1';
   
                objectQueries.put(uniqueKey, query);
            }
        }
   
        for (String uniqueKey : objectQueries.keySet()) {
            String query = objectQueries.get(uniqueKey);
            System.debug('Executing Query for ' + uniqueKey.split('-')[0] + ': ' + query);
   
            try {
                List<SObject> records = Database.query(query);
                Boolean hasRecords = !records.isEmpty();
   
                if (wrapperMap.containsKey(uniqueKey)) {
                    wrapperMap.get(uniqueKey).viewWrapper = hasRecords;
                }
            } catch (Exception e) {
                System.debug('SOQL Query Error for Object: ' + uniqueKey.split('-')[0] + ' - ' + e.getMessage());
            }
        }
    }

    public static String getLookupFieldToLoan(String objectName) {
        if (objectName == 'Opportunity') return 'Id';

        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType == null) {
            System.debug('Invalid object: ' + objectName);
            return null;
        }

        Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
        for (Schema.SObjectField field : fieldMap.values()) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                for (Schema.SObjectType refType : fieldDescribe.getReferenceTo()) {
                    if (refType.getDescribe().getName() == 'Opportunity') {
                        return fieldDescribe.getName();
                    }
                }
            }
        }
        return null;
    }

    private static List<ApplicantWrapper> getApplicantsForLoan(Id loanId, String label) {
        List<ApplicantWrapper> applicantWrappers = new List<ApplicantWrapper>();

        List<Application_Applicant__c> applicants = [SELECT Id, Customer__c, Applicant_Type__c, Name,Customer_Type__c,
                                                        Aadhaar_Number__c, PAN_Number__c 
                                                    FROM Application_Applicant__c 
                                                    WHERE Loan_Application__c = :loanId];
        System.debug('applicants: '+applicants);
        for (Application_Applicant__c applicant : applicants) {
            if(label == 'Pan Aadhar Link' && (applicant.PAN_Number__c == null || applicant.Aadhaar_Number__c == null)) {
                continue;
            }
            if(label=='Pan To CIN' && (applicant.Customer_Type__c=='Individual')){
                continue;
            }
            applicantWrappers.add(new ApplicantWrapper(applicant.Id, applicant.Name, applicant.Applicant_Type__c));
        }

        return applicantWrappers;
    }

    public class IntegrationMasterDataWrapper {
        @AuraEnabled public Id masterDataId;
        @AuraEnabled public String stage;
        @AuraEnabled public String activityName;
        @AuraEnabled public String label;
        @AuraEnabled public Boolean viewWrapper;
        @AuraEnabled public List<ApplicantWrapper> applicantWrappers;
    
        public IntegrationMasterDataWrapper(Id masterDataId, String stage, String activityName, String label, Boolean viewWrapper) {
            this.masterDataId = masterDataId;
            this.stage = stage;
            this.activityName = activityName;
            this.label = label;
            this.viewWrapper = viewWrapper;
            this.applicantWrappers = new List<ApplicantWrapper>();
        }
    }

    public class ApplicantWrapper {
        @AuraEnabled public Id applicantId;
        @AuraEnabled public String applicantName;
        @AuraEnabled public String applicantType;
        @AuraEnabled public Boolean viewApplicant;
        @AuraEnabled public Boolean hasData;
    
        public ApplicantWrapper(Id applicantId, String applicantName, String applicantType) {
            this.applicantId = applicantId;
            this.applicantName = applicantName;
            this.applicantType = applicantType;
            // this.viewApplicant = false;
            this.viewApplicant = true;
            this.hasData = false;
        }
    }


    @AuraEnabled
    public static List<Integration_Details__c> getIntegrationDetails(List<String> masterDataNames, Id loanId, List<String> applicantIds) {
        if(applicantIds.isEmpty()){
            return [SELECT Related_Record_Id__c, Is_Success_Response__c,CreatedDate, Name FROM Integration_Details__c WHERE Name IN :masterDataNames AND Loan_Application__c =: loanId ORDER BY CreatedDate DESC];
        } else {
            return [SELECT Related_Record_Id__c, CreatedDate,Is_Success_Response__c, Name FROM Integration_Details__c WHERE Name IN :masterDataNames AND (Loan_Application__c =: loanId OR Related_Record_Id__c IN :applicantIds) AND (Object_Name__c = 'Application_Applicant__c' OR Object_Name__c = 'Loan_Application__c') ORDER BY CreatedDate DESC];
        }
    }

    @AuraEnabled
    public static String getClassAndMethodName(String masterId, String loanId, String apiName, String appId) {
        // try {
        System.debug('masterId: '+masterId);
        System.debug('apiName: '+apiName);
            List<Integration_Master__mdt> integrationMasters = [SELECT Id, Activity_Name__c, Controller_Class_and_Method__c 
                                                                FROM Integration_Master__mdt WHERE Id =: masterId AND Activity_Name__c =: apiName LIMIT 1]; 

            if (!integrationMasters.isEmpty() && integrationMasters[0].Controller_Class_and_Method__c != null) {
                String[] methodNameParts = integrationMasters[0].Controller_Class_and_Method__c.split('-'); 
                
                if (methodNameParts.size() == 2) {
                    String className = methodNameParts[0].trim();
                    String classMethodName = methodNameParts[1].trim();
                    
                    System.debug('Class: ' + className + ', Method: ' + classMethodName);

                    Type dynamicClass = Type.forName(className);
                    if (dynamicClass != null) {
                        Object classInstance = dynamicClass.newInstance();

                        if (classInstance instanceof DynamicInvoker) {
                            DynamicInvoker invoker = (DynamicInvoker) classInstance;
                            return invoker.invokeMethod(loanId, appId, integrationMasters[0].Activity_Name__c);
                        } else {
                            throw new AuraHandledException('Class does not implement DynamicInvoker interface: ' + className);
                        }
                    } else {
                        throw new AuraHandledException('Class not found: ' + className);
                    }
                } else {
                    throw new AuraHandledException('Invalid format for Controller_Class_and_Method__c');
                }
            } else {
                throw new AuraHandledException('No matching record found in Integration_Master__mdt');
            }
        // } catch (Exception e) {
        //     System.debug('Error: ' + e.getMessage());
        //     throw new AuraHandledException('Error invoking method: ' + e.getMessage());
        // }
    }
@AuraEnabled
public static Boolean checkEmailDomain(String loanId) {
    try {
        List<Application_Applicant__c> aap = [SELECT Id, Official_Mail_ID__c FROM Application_Applicant__c 
            WHERE Loan_Application__c = :loanId AND Official_Mail_ID__c != null];
        return !aap.isEmpty();
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}
public class newApplicantWrapper {
    @AuraEnabled public String label { get; set; }
    @AuraEnabled public List<applicantDomainCheckWrapper> data { get; set; }
}

public class applicantDomainCheckWrapper {
    @AuraEnabled public Id appId { get; set; }
    @AuraEnabled public String applicantName { get; set; }
    @AuraEnabled public String apiResponse { get; set; }
    @AuraEnabled public Boolean apiSuccess { get; set; }
    @AuraEnabled public Boolean apiVerifyWrong { get; set; }
    @AuraEnabled public Boolean apiVerifyFail { get; set; }
}

@AuraEnabled
public static String fetchEmailDomain(String loanId) {
    try {
        List<Application_Applicant__c> aap = [
            SELECT Id, Applicant_Name__c, Official_Mail_ID__c, Official_Mail_Validity__c 
            FROM Application_Applicant__c 
            WHERE Loan_Application__c = :loanId AND Official_Mail_ID__c != null
        ];
        newApplicantWrapper re = new newApplicantWrapper();
        re.label = 'Email Domain Check';
        List<applicantDomainCheckWrapper> wpld = new List<applicantDomainCheckWrapper>();
        for (Application_Applicant__c aa : aap) {
            applicantDomainCheckWrapper adcw = new applicantDomainCheckWrapper();
            adcw.appId = aa.Id;
            adcw.applicantName = aa.Applicant_Name__c+'('+aa.Official_Mail_ID__c+')';
            adcw.apiResponse = aa.Official_Mail_Validity__c;
            adcw.apiSuccess = (aa.Official_Mail_Validity__c != null && aa.Official_Mail_Validity__c.equalsIgnoreCase('Valid'));
            adcw.apiVerifyWrong = (aa.Official_Mail_Validity__c != null && aa.Official_Mail_Validity__c.equalsIgnoreCase('Invalid'));
            adcw.apiVerifyFail = (aa.Official_Mail_Validity__c != null && aa.Official_Mail_Validity__c.equalsIgnoreCase('None'));
            wpld.add(adcw);
        }
        re.data = wpld;
        return JSON.serialize(re);
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}




}