/**
 * @description       : Handles PAN Aadhar Link API integration.
 * @author            : 
 * @last modified on  : 
 * @last modified by  : 
**/
public with sharing class HL_PANAadharHandler implements IntegrationInterface {
    static String conLabels = '';
    public static Map<String, String> constants = Utility.getConstants(conLabels);

    @AuraEnabled
    public static Map<String, String> getConstants() {
        return constants;
    }

    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) {
        String loanApplicationId = wrapper.loanApplicationId;
        String applicantId = wrapper.recordId;
        List<String> errorMessages = new List<String>();

        if (String.isBlank(applicantId)) {
            errorMessages.add('Error: Applicant Id is missing');
            return errorMessages;
        }

        List<Application_Applicant__c> applicants = [SELECT 
                                                        Id, PAN_Number__c, Aadhaar_Number__c, First_Name__c
                                                    FROM Application_Applicant__c
                                                    WHERE Loan_Application__c = :loanApplicationId AND Id = :applicantId
                                                    ];
        if (applicants.isEmpty()) {
            errorMessages.add('Error: No applicant found with the provided ID.');
        } else if (String.isBlank(applicants[0].PAN_Number__c)) {
            errorMessages.add('Error: No PAN found for applicant: ' + applicants[0].First_Name__c);
        } else if (String.isBlank(applicants[0].Aadhaar_Number__c)) {
            errorMessages.add('Error: No Aadhaar Number found for applicant: ' + applicants[0].First_Name__c);
        }
        return errorMessages;
    }

    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        try {
            String applicantId = wrapper.recordId;
            String loanApplicationId = wrapper.loanApplicationId;

            List<Application_Applicant__c> applicantList = [SELECT 
                                                                Id, First_Name__c, PAN_Number__c, Aadhaar_Number__c
                                                            FROM Application_Applicant__c
                                                            WHERE Id = :applicantId
                                                            ];
            if (applicantList.isEmpty()) {
                throw new AuraHandledException('Applicant not found');
            }

            PANAadharLinkWrapper panAadharLinkWrapper = new PANAadharLinkWrapper();
            
            panAadharLinkWrapper.pan = applicantList[0].PAN_Number__c;
            panAadharLinkWrapper.aadhaarNo = applicantList[0].Aadhaar_Number__c;
            panAadharLinkWrapper.consent = 'Y';
            panAadharLinkWrapper.accessKey = wrapper.accessKey;

            ClientDetails clientDataWrapper = new ClientDetails();
            clientDataWrapper.caseId = applicantList[0].Id;
            
            panAadharLinkWrapper.clientData = clientDataWrapper;
            String requestJSON = JSON.serialize(panAadharLinkWrapper);
            return requestJSON;

        } catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'CreatePanAadharLinkPayload', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
    }
    
    public class PANAadharLinkWrapper {
        public String pan; 
        public String aadhaarNo; 
        public String consent;
        public String accessKey; 
        public ClientDetails clientData;
    }
    
    public class ClientDetails {
        public String caseId; 
    }    
}