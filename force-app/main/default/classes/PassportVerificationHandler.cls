public with sharing class PassportVerificationHandler implements IntegrationInterface{
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
    //         List<Application_Applicant__c> applicantDetails = [SELECT Id, Name, Passport_Number__c, Passport_File_Number__c, DOB__c,First_Name__c, Last_Name__c FROM Application_Applicant__c WHERE Id = :wrapper.recordId LIMIT 1];
    //         String passport = applicantDetails[0].Passport_Number__c;
    //         String dob = String.valueOf(applicantDetails[0].DOB__c);
    //         String name = applicantDetails[0].First_Name__c+''+applicantDetails[0].Last_Name__c;
    //         String fileNo = applicantDetails[0].First_Name__c+''+applicantDetails[0].Passport_File_Number__c;
    //         Map<String, Object> requestBody = new Map<String, Object>();
    //         requestBody.put('consent', 'Y');
    //         requestBody.put('fileNo', fileNo);
    //         requestBody.put('passport', passport);
    //         requestBody.put('doi', dob);
    //         requestBody.put('name', name);
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
                SELECT Id, Name, Passport_Number__c, Passport_File_Number__c, DOB__c, First_Name__c, Last_Name__c, Passport_Date_of_Issue__c  
                FROM Application_Applicant__c 
                WHERE Id = :wrapper.recordId 
                LIMIT 1
            ];
    
            if (!applicantDetails.isEmpty()) {
                Application_Applicant__c applicant = applicantDetails[0];
                System.debug('Applicant Details --> ' + applicant);
    
                RequestBodyWrapper requestBodyWrapper = new RequestBodyWrapper();
                requestBodyWrapper.consent = 'y';
                requestBodyWrapper.fileNo = applicant.Passport_File_Number__c; // applicant.First_Name__c + '' + 
                //Updating the name of parameter that stores passport number, as per the Request format shared
                requestBodyWrapper.passportNo = applicant.Passport_Number__c;
                // requestBodyWrapper.doi = String.valueOf(applicant.DOB__c);
                Date doi = applicant.Passport_Date_of_Issue__c ;
                String passDay = doi.day() < 10 ? '0' + doi.day() : String.valueOf(doi.day());
                String passMonth = doi.month() < 10 ? '0' + doi.month() : String.valueOf(doi.month());
                String passYear = String.valueOf(doi.year());

                requestBodyWrapper.doi = passDay + '/' + passMonth + '/' + passYear;

                Date dob = applicant.DOB__c ;
                String day = dob.day() < 10 ? '0' + dob.day() : String.valueOf(dob.day());
                String month = dob.month() < 10 ? '0' + dob.month() : String.valueOf(dob.month());
                String year = String.valueOf(dob.year());

                requestBodyWrapper.dob = day + '/' + month + '/' + year;
               // requestBodyWrapper.name = applicant.First_Name__c + ' ' + applicant.Last_Name__c;
    			requestBodyWrapper.name = applicant.Name;
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
        public String fileNo;
        public String passportNo;
        public String doi;
        public String name;
        public String dob;
        public ClientDataWrapper clientData;
    }
    
    public class ClientDataWrapper {
        public String caseId;
    }
    
}