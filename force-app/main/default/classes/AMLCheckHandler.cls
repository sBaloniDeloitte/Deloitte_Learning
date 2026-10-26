public with sharing class AMLCheckHandler implements IntegrationInterface{
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String loanApplicationId = wrapper.loanApplicationId;
        String appId= wrapper.recordId;

        List<Application_Applicant__c> applicants = [
            SELECT Id, Applicant_Name__c, DOB__c, Gender__c,First_Name__c, Last_Name__c
            FROM Application_Applicant__c 
            WHERE Loan_Application__c = :loanApplicationId AND Id= :appId 
        ];

        for (Application_Applicant__c applicant : applicants) { 
            if (String.isBlank(applicant.Applicant_Name__c)) {
                errorMessages.add('Error: Missing Name for Applicant ' + applicant.First_Name__c + ' ' + applicant.Last_Name__c);
            }
            if (applicant.DOB__c == null ) {
                errorMessages.add('Error: Missing DOB for applicant:' + applicant.First_Name__c);
            } 
            if (String.isBlank(applicant.Gender__c) ) {
                errorMessages.add('Error: Missing Gender for applicant:' + applicant.First_Name__c);
            } 
        }

        return errorMessages;
    }

    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();

        try {
            system.debug('are we inside construct??');
            AMLCheckRequestWrapper request = new AMLCheckRequestWrapper();
            string appID = wrapper.recordId;
            
            Integration_Details__c integrationDetails = new Integration_Details__c();
            
            List<Application_Applicant__c> appApplicantsOnLoan1 = [
                                                                SELECT Id, Applicant_Name__c, DOB__c, Gender__c	
                                                                FROM Application_Applicant__c 
                                                                WHERE Id = :appID 
                                                            ];
            
            for (Application_Applicant__c app : appApplicantsOnLoan1) {
                request.name = app.Applicant_Name__c;
                request.gender = app.Gender__c;
                request.dateOfBirth = String.valueOf(app.DOB__c);
                request.agency = '';
                request.pdfReport = true;
                request.nameMatch = true;
                request.nameMatchThreshold = true;

                AMLCheckClientData checkClientData= new AMLCheckClientData();
                checkClientData.caseId = '';

                request.clientData = checkClientData;
            }

            String requestJSON = JSON.serialize(request);
            return requestJSON;
          
        } catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'AMLCheckHandler', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }

    }

    public class AMLCheckRequestWrapper{
        public String name;
        public String dateOfBirth;
        public String gender;
        public String agency;
        public Boolean pdfReport;
        public Boolean nameMatch;
        public Boolean nameMatchThreshold;
        public AMLCheckClientData clientData;
    }

    public class AMLCheckClientData {
        public String caseId;
    }

}