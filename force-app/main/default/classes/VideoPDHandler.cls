public class VideoPDHandler implements IntegrationInterface {
public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String applicantId = wrapper.recordId;
        List<Application_Applicant__c> applicants = [
            SELECT Id, Applicant_Name__c, Applicant_Type__c, Mobile_Number__c, PAN_Number__c, Customer_Type__c,
            Email__c, DOB__c, Father_s_First_Name__c, Father_s_Last_Name__c,Company__c,Business_Type__c,GSTIN__c
            
            FROM Application_Applicant__c 
            WHERE Id =:applicantId
        ];
        
        for (Application_Applicant__c applicant : applicants) { 
            if (String.isEmpty(applicant.Email__c)) {
                errorMessages.add('Error: Missing email id for applicant ' + applicant.Applicant_Name__c);
            }
            if (String.isEmpty(applicant.Mobile_Number__c)) {
                errorMessages.add('Error: Missing mobile number for applicant ' + applicant.Applicant_Name__c);
            }
            
        }
        
        return errorMessages;
    }
    
    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();
        
        try {
            system.debug('are we inside construct??');
            
            String applicantId = wrapper.recordId;
            
            
            Integration_Details__c integrationDetails = new Integration_Details__c();
            /*
            List<Application_Applicant__c> applicants = [SELECT Id, Applicant_Name__c, Applicant_Type__c, Mobile_Number__c, PAN_Number__c, Customer_Type__c,Loan_Application__c,
                                                         Email__c, DOB__c, Father_s_First_Name__c, Father_s_Last_Name__c,Company__c,Business_Type__c,GSTIN__c,
                                                         (SELECT Id, Full_Address__c,Address_Type__c, Building_Street_Name__c, Town__c, Pincode__r.Name, State__c FROM Applicant_Address__r 
                                                          WHERE Address_Type__c ='Business' OR Address_Type__c ='Permanent')
                                                         FROM Application_Applicant__c 
                                                         WHERE Id = :applicantId
                                                        ];
x
            
            if (applicants.size() > 0) {
                
                
            }*/
            String requestJSON;
            Organization org = [SELECT IsSandbox FROM Organization LIMIT 1];
            if(org.IsSandbox) {
                requestJSON = '{"username":"admin@godrejcapital.com"}';
            }else {
                requestJSON = '{"username":"'+UserInfo.getUserEmail()+'"}';
            }
            
            //requestJSON = JSON.serialize(requestJSON);
            //
            
            return requestJSON;
            
        } catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'VideoPDHandler', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
        
    }
    
}