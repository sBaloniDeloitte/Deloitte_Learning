/**
 * @description       : Handles Aadhar Consent API integration.
 * @author            : 
 * @last modified on  : 
 * @last modified by  : 
**/
public with sharing class AadharConsentHandler implements IntegrationInterface {
    static String conLabels = '';
    public static Map<String, String> constants = Utility.getConstants(conLabels);

    @TestVisible
    private static String testIpAddress;
    
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
                                                        Id, Aadhaar_Number__c, First_Name__c
                                                    FROM Application_Applicant__c
                                                    WHERE Loan_Application__c = :loanApplicationId AND Id = :applicantId
                                                    ];
        if (applicants.isEmpty()) {
            errorMessages.add('Error: No applicant found with the provided ID.');
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
                                                                Id, First_Name__c, Aadhaar_Number__c
                                                            FROM Application_Applicant__c
                                                            WHERE Id = :applicantId
                                                            ];
            if (applicantList.isEmpty()) {
                throw new AuraHandledException('Applicant not found');
            }

            AadharConsentWrapper aadharConsentWrapper = new AadharConsentWrapper();
            
            aadharConsentWrapper.name = applicantList[0].First_Name__c;
            aadharConsentWrapper.consentText = 'I authorize Perfios Software Solutions Private Limited to access my Aadhaar number and help me fetch my details. I understand that Perfios will not be storing or sharing the same in any manner.';
            aadharConsentWrapper.consent = 'Y';
            aadharConsentWrapper.userAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36';
            aadharConsentWrapper.lat = wrapper.latitude;
            aadharConsentWrapper.longi = wrapper.longitude;
            Datetime consentTime = Datetime.now();
            Long unixTimestamp = consentTime.getTime() / 1000;
            System.debug(unixTimestamp);
            aadharConsentWrapper.consentTime = String.valueOf(unixTimestamp);
            String userIp = getUserIPAddress();
            System.debug('User IP Address: ' + userIp);
            aadharConsentWrapper.ipAddress = userIp;
            aadharConsentWrapper.deviceId = 'xxxxxx';
            aadharConsentWrapper.deviceInfo = '1234';

            ClientDetails clientDataWrapper = new ClientDetails();
            clientDataWrapper.caseId = applicantList[0].Id;
            
            aadharConsentWrapper.clientData = clientDataWrapper;
            String requestJSON = JSON.serialize(aadharConsentWrapper);
            String requestJSONFinal = requestJSON.replace('longi', 'long');
            System.debug('Aadhar Consent final requestJSON::: ' + requestJSONFinal);
            return requestJSONFinal;

        } catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'CreatePanAadharLinkPayload', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
    }

    public static String getUserIPAddress() {
    if (System.Test.isRunningTest()) {
            if (testIpAddress != null) {
                return testIpAddress;
            }
            return '0.0.0.0';
        }
        Map<String, String> session = Auth.SessionManagement.getCurrentSession();
        if (session != null && session.containsKey('SourceIp')) {
        return session.get('SourceIp');
    }
    return null;
    }
    
    public class AadharConsentWrapper{
        public String name;
        public ClientDetails clientData;
        public String consentText;
        public String consent;
        public String lat;
        public String longi;
        public String userAgent;
        public String consentTime;  
        public String ipAddress;
        public String deviceId;
        public String deviceInfo;
    }
    
    public class ClientDetails {
        public String caseId;
    }
   
}