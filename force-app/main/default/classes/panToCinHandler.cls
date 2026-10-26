public with sharing class panToCinHandler implements IntegrationInterface{
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

    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();
        System.debug('panToCinHandler wrapper construct --> ' + wrapper);
        System.debug('panToCinHandler integrationSettings --> ' + integrationSettings);
        System.debug('panToCinHandler wrapper.recordId --> '+wrapper.recordId);
        System.debug('panToCinHandler wrapper.loanApplicationId --> '+wrapper.loanApplicationId);

        //implementing the approach of fetching the case Id from Integration_mappings__mdt metadata
        Integration_mapping__mdt caseIdMeta = [SELECT Target_Value__c FROM Integration_Mapping__mdt WHERE DeveloperName = 'Case_Id' LIMIT 1];
        String caseIdValue = caseIdMeta != null ? caseIdMeta.Target_Value__c : null;

        List<Application_Applicant__c> applicantDetails;
        if(wrapper.recordId != null ) {
            applicantDetails = [SELECT Id, Name, PAN_Number__c FROM Application_Applicant__c WHERE Id = :wrapper.recordId LIMIT 1];
        } else if(wrapper.loanApplicationId != null) {
            applicantDetails = [SELECT Id, Name, PAN_Number__c FROM Application_Applicant__c WHERE Loan_Application__c = :wrapper.loanApplicationId AND Applicant_Type__c = 'Primary Applicant' LIMIT 1];
        }
        System.debug('panToCinHandler applicantDetails --> '+applicantDetails);
        if(!applicantDetails.isEmpty()) {
            String pan = applicantDetails[0].PAN_Number__c;
            System.debug('pan --> '+pan);
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('consent', 'Y');
            requestBody.put('pan', pan);
        
            Map<String, Object> clientData = new Map<String, Object>();
            clientData.put('caseId', caseIdValue);
            requestBody.put('clientData', clientData);
        
            String requestJSON = JSON.serialize(requestBody);
            System.debug('panToCinHandler Request JSON: ' + requestJSON);
            return requestJSON;
        } else {
            System.debug('panToCinHandler errorMessages --> '+errorMessages);
            return JSON.serialize(errorMessages);
        }
    }

    
}