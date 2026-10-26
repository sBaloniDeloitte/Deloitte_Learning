/*
* Author    :   Deloitte India
* Purpose   :   Controller class for FCU record page
* @last modified on  : 
* @last modified by  : 
*/

public with sharing class FCURecordPageController {

    public static final String FCU_OBJECT_NAME = 'Application_Verification__c';
    public static final List<String> PARENT_FIELDS = new List<String>{'Verification_Status__c'};
    public static final String APPROVAL_STATUS_APPROVED = 'Approved';
    public static final Set<String> APPROVAL_FINAL_STATUS = new Set<String>{'Approved','Rejected','Re-Assigned','Sent for Approval','Initiated'};
    public static final Set<String> APPROVAL_INITIATION_STATUS = new Set<String>{'Pending','Sent Back'};
    public FCURecordPageController() {}

    @AuraEnabled
    public static Map<String,Object> getDynamicFieldLayout(Id recordId){
        Map<String,Object> outputMap = new Map<String,Object>{'records'=>null};
        Map<Id,List<SObjectFieldWrapper>> recordFieldWrapperMap = new Map<Id,List<SObjectFieldWrapper>>();
        try {
            List<Application_Verification__c> controlUnits = [SELECT Id,Verification_Status__c,Verification_Remarks__c FROM Application_Verification__c WHERE  Id =:recordId];
            for(Application_Verification__c fraudControlUnit: controlUnits){
                if(!recordFieldWrapperMap.containsKey(fraudControlUnit.Id)){
                   recordFieldWrapperMap.put(fraudControlUnit.Id,new List<SObjectFieldWrapper>());
                }
                recordFieldWrapperMap.get(fraudControlUnit.Id).addAll(setFieldLayout(PARENT_FIELDS,fraudControlUnit));
            }
            outputMap.put('records',recordFieldWrapperMap);
            return outputMap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String,Boolean> setFCUProgress(Id recordId){
        try {
            Boolean isDetailPresent,isSubmitted,isApproved;
            isDetailPresent = true;
            isSubmitted = isApproved = false;
            List<Application_Verification__c> controlUnits = [SELECT Id,Is_Submitted__c,Approval_Status__c,Verification_Remarks__c,Verification_Status__c,Stage__c  FROM Application_Verification__c WHERE Id =:recordId OR Parent_FCU__c =:recordId];
            for(Application_Verification__c fcuRecord : controlUnits){
                if(fcuRecord.Id == recordId){
                
                    if(String.isBlank(fcuRecord.Verification_Status__c)){isDetailPresent = false;}
                    if(!isDetailPresent){continue;}
                    if(fcuRecord.Is_Submitted__c == true){isSubmitted = true;}
                    if(!isSubmitted){continue;}
                    if(APPROVAL_STATUS_APPROVED.equalsIgnoreCase(fcuRecord.Stage__c)){isApproved = true;}
               }else{
                    if(!((APPROVAL_INITIATION_STATUS.contains(fcuRecord.Approval_Status__c) && fcuRecord.Verification_Remarks__c!=null) || APPROVAL_FINAL_STATUS.contains(fcuRecord.Approval_Status__c))){
                        isDetailPresent = isSubmitted = isApproved = false;
                        break;
                    }
                       
               }
            }
            return new Map<String,Boolean>{
                'isDetailPresent' => isDetailPresent,
                'isSubmitted' => isSubmitted,
                'isApproved' => isApproved
            };
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<ActionWrapper> setFCUAction(Id recordId){
        List<ActionWrapper> wrapper = new List<ActionWrapper>();
        String contentId;
        List<Application_Verification__c> controlUnits = [SELECT Id,Report_Name__c,Document_Detail__r.Content_Document_Id__c FROM Application_Verification__c WHERE Parent_FCU__c =:recordId];
        for(Application_Verification__c fcuRecord : controlUnits){
            contentId = fcuRecord.Document_Detail__r.Content_Document_Id__c;
            wrapper.add(new ActionWrapper(fcuRecord.Report_Name__c,contentId));
        }
        return wrapper;
    }

    public class ActionWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public String trimmedName;
        @AuraEnabled public String contentId;
        public ActionWrapper(String actionName,String contentId){
            this.name = actionName;
            this.trimmedName = actionName.length() > 30 ? actionName.substring(0,30) + '...' : actionName;
            this.contentId = contentId == null ? 'no record id' : contentId;
        }
    }

    public static List<SObjectFieldWrapper> setFieldLayout(List<String> fieldAPINames, SObject genericObject) {
    List<SObjectFieldWrapper> wrapper = new List<SObjectFieldWrapper>();

    // Get the object name from the SObject itself
    String objectName = genericObject.getSObjectType().getDescribe().getName();

    // Describe the fields map only once
    Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();

    for (String fieldAPIName : fieldAPINames) {
        if (fieldMap.containsKey(fieldAPIName)) {
            Schema.SObjectField fieldType = fieldMap.get(fieldAPIName);
            wrapper.add(new SObjectFieldWrapper(fieldType, String.valueOf(genericObject.get(fieldType))));
        }
    }

    return wrapper;
}

    @AuraEnabled
    public static Boolean checkShowSubmit(String recId){
        Boolean showSubmit = false;
        try {
            String profile = [SELECT Id,Name FROM Profile WHERE Id =: UserInfo.getProfileId() LIMIT 1].Name;
            if(profile == 'FCU Agent' || profile == 'System Administrator'){
                List<Application_Verification__c> fcuList = [Select Id, RecordType.Name, Verification_Status__c, Verification_Remarks__c, Stage__c from Application_Verification__c where id =: recId];
                if(fcuList.size()>0 && (fcuList[0].Stage__c =='Assigned To Agent' || fcuList[0].Stage__c =='Sent Back By Admin')){
                    if(fcuList[0].RecordType.Name == 'Profile'){
                        List<Document_Details__c> docList = [Select id from Document_Details__c where Application_Verification__c =: recId and Content_Document_Id__c
                        != null];
                        if(docList.size()>0 && fcuList[0].Verification_Status__c != null && fcuList[0].Verification_Remarks__c != null){
                            showSubmit = true;
                        }
                    }
                    else{
                        if(fcuList[0].Verification_Status__c != null && fcuList[0].Verification_Remarks__c != null){
                            showSubmit = true;
                        }
                    }
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return showSubmit;
    }

    /**
 * @description     :   Method that checks if FCU is related to Loan Application
 * @since           :   
 * @param           :   FCU record Id
 * @return          :   Boolean
 */
    @AuraEnabled
    public static boolean checkFCUNotRelatedToLoanApplication(String parentFCU) {
        Boolean isFCUNotRelatedToLoanApplication = false;

        try {
            // Query to get the Fraud Control Unit record
            Application_Verification__c parentRecord = [
                SELECT Id, Loan_Application__c,Vendor__c,External_Vendor__c
                FROM Application_Verification__c 
                WHERE Id = :parentFCU 
                LIMIT 1
            ];
            
            // Check if Loan Application is null
            if (parentRecord != null) {
                isFCUNotRelatedToLoanApplication = (parentRecord.External_Vendor__c != null);
            }

            return isFCUNotRelatedToLoanApplication;

        } catch (Exception exp) {
            Utility.generateException(exp, Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, 'FCURecordPageController');
            return false;
        }
    }
}