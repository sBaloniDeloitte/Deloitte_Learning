public with sharing class DLVerificationHandler implements IntegrationInterface{
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) {
        System.debug('wrapper --> '+wrapper);
        List<String> errorMessages = new List<String>();
        String loanApplicationId = wrapper.loanApplicationId;
        return errorMessages;
    }

    // public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
    //     List<String> errorMessages = new List<String>();
    //     System.debug('wrapper construct --> '+wrapper);
    //     System.debug('integrationSettings --> '+integrationSettings);
    //     // Map<String, String> requestBody = new Map<String, String>();
    //     Map<String, Object> requestBody = new Map<String, Object>();
    //     requestBody.put('consent', 'Y');
    //     requestBody.put('epicNo', 'SXXXXXXXX8');
    //     Map<String, String> clientData = new Map<String, String>();
    //     clientData.put('caseId', '123456');
    //     requestBody.put('clientData', clientData);
    //     HTTPResponse resp = Utility.executeAPIRequest(requestBody);
    //     // System.debug('resp --> '+JSON.deserialize(resp));
    //     return JSON.serialize(requestBody);

    //     // return JSON.serialize(errorMessages);
    // }

    // public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
    //     List<String> errorMessages = new List<String>();
    //     System.debug('wrapper construct --> ' + wrapper);
    //     System.debug('integrationSettings --> ' + integrationSettings);
    //     System.debug('wrapper.recordId --> '+wrapper.recordId);
    //     if(wrapper.recordId != null ) {
    //         List<Application_Applicant__c> applicantDetails = [SELECT Id, Name, Drivers_License_Number__c, DOB__c,First_Name__c, Last_Name__c FROM Application_Applicant__c WHERE Id = :wrapper.recordId LIMIT 1];
    //         String dlNo = applicantDetails[0].Drivers_License_Number__c;
    //         String dob = String.valueOf(applicantDetails[0].DOB__c);
    //         String name = applicantDetails[0].First_Name__c+''+applicantDetails[0].Last_Name__c;
    //         Map<String, Object> requestBody = new Map<String, Object>();
    //         requestBody.put('consent', 'Y');
    //         requestBody.put('dlNo', dlNo);
    //         requestBody.put('additionalDetails', 'true');
    //         requestBody.put('dob', dob);
    //         // requestBody.put('name', name);
    //         Map<String, Object> clientData = new Map<String, Object>();
    //         clientData.put('caseId', '123456');
    //         requestBody.put('clientData', clientData);
        
    //         String requestJSON = JSON.serialize(requestBody);
    //         System.debug('Request JSON: ' + requestJSON);
    //         return requestJSON;
    //     } else {
    //         return JSON.serialize(errorMessages);
    //     }
    // }

    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();
        System.debug('wrapper construct --> ' + wrapper);
        System.debug('integrationSettings --> ' + integrationSettings);
        System.debug('wrapper.recordId --> ' + wrapper.recordId);

        //implementing the approach of fetching the case Id from Integration_mappings__mdt metadata
        Integration_mapping__mdt caseIdMeta = [SELECT Target_Value__c FROM Integration_Mapping__mdt WHERE DeveloperName = 'Case_Id' LIMIT 1];
        String caseIdValue = caseIdMeta != null ? caseIdMeta.Target_Value__c : null;
    
        if (wrapper.recordId != null) {
            List<Application_Applicant__c> applicantDetails = [
                SELECT Id, Name, Drivers_License_Number__c, Drivers_License_DOB__c, First_Name__c, Last_Name__c
                FROM Application_Applicant__c 
                WHERE Id = :wrapper.recordId 
                LIMIT 1
            ];
    
            if (!applicantDetails.isEmpty()) {
                Application_Applicant__c applicant = applicantDetails[0];
                System.debug('Applicant Details --> ' + applicant);
    
                RequestBodyWrapper requestBodyWrapper = new RequestBodyWrapper();
                requestBodyWrapper.consent = 'Y';
                requestBodyWrapper.dlNo = applicant.Drivers_License_Number__c;
                // requestBodyWrapper.dob = String.valueOf(applicant.DOB__c);
                // requestBodyWrapper.dob = String.valueOf(applicant.DOB__c) != null ? String.valueOf(applicant.DOB__c).format('dd-MM-yyyy') : null;
                Date dob = applicant.Drivers_License_DOB__c;
                String day = dob.day() < 10 ? '0' + dob.day() : String.valueOf(dob.day());
                String month = dob.month() < 10 ? '0' + dob.month() : String.valueOf(dob.month());
                String year = String.valueOf(dob.year());

                requestBodyWrapper.dob = day + '-' + month + '-' + year;

                requestBodyWrapper.additionalDetails = true;
    
                requestBodyWrapper.clientData = new ClientDataWrapper();
                requestBodyWrapper.clientData.caseId = caseIdValue;
    
                String requestJSON = JSON.serialize(requestBodyWrapper);
                System.debug('Request JSON: ' + requestJSON);
                return requestJSON;
            }
        }
    
        return JSON.serialize(errorMessages);
    }
    
    public class RequestBodyWrapper {
        public String consent;
        public String dlNo;
        public String dob;
        public Boolean additionalDetails;
        public ClientDataWrapper clientData;
    }
    
    public class ClientDataWrapper {
        public String caseId;
    }
    
}