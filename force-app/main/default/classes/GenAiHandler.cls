/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-08-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class GenAiHandler implements IntegrationInterface {

    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
        try {
            List<String> errorMessages = new List<String>();
            String loanApplicationId = wrapper.loanApplicationId;
            String applicantId = wrapper.recordId;
            System.debug('loanApplicationId '+loanApplicationId);
            System.debug('applicantId '+applicantId);
            //List<Document_Details__c> '+loanApplicationId);
            List<Document_Details__c> docDetails = [Select id, Content_Document_Id__c from Document_Details__c where Loan_Application__c = :loanApplicationId 
                                                    AND Applicant__c = :applicantId AND Content_Document_Id__c!=null AND Name ='Cibil Response' ORDER BY CreatedDate  DESC  LIMIT 1];
                if (docDetails.size()==0) {
                    errorMessages.add(' Please hit Cibil API to fetch Eligibility');
                } 
            return errorMessages;
        }
        catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'CreateFICOPAYLOAD', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
    }
    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        String loanApplicationId = wrapper.loanApplicationId;
        String applicantId = wrapper.recordId;
        List<Document_Details__c> docLst= [SELECT id,createddate,Content_Document_Id__c,Applicant__c from Document_Details__c  where name = 'Cibil Response' AND Applicant__c =:applicantId  ORDER BY CreatedDate DESC LIMIT 1];
        Map<String,String> conDocIds = new Map<String,String>();
        Map<String,String> applicantTuffRes = new Map<String,String>();
        List<ContentVersion> conversionLst = [SELECT id,VersionData,ContentDocumentId  FROM ContentVersion WHERE ContentDocumentId=:docLst[0].Content_Document_Id__c];
        String cibilAllResponse =conversionLst[0].VersionData.toString();
        CibilAPIController.CIBILResponseWrapper cibilMainWrapper = ( CibilAPIController.CIBILResponseWrapper)JSON.deserialize(cibilAllResponse,  CibilAPIController.CIBILResponseWrapper.class);
        System.debug('cibilMainWrapper'+ cibilMainWrapper);
        String xmlResponse = cibilMainWrapper.tuffResponse;
        System.debug('xmlResponse-----'+xmlResponse);
        GenAiRequestWrapper genAiReqWrap = new GenAiRequestWrapper();
        genAiReqWrap.cibil_xml = xmlResponse;
        String requestJSON = JSON.serialize(genAiReqWrap);
        return requestJSON;
    }
    
    public class GenAiRequestWrapper  {
        public String cibil_xml;	//BRLPR4545L
    }
}