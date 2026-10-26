public without sharing class WhatsAppController {
    static String conLabels = 'WHATSAPP_API';
    public static Map<String, String> constants = Utility.getConstants(conLabels);

    @AuraEnabled
    public static Map<String, String> getConstants() {
        return constants;
    }

    @AuraEnabled
    public static String initiateWhatsAppRequest(Map<String, String> inputMap) {
        try {
            String loanId = inputMap.get('loanId');
            String applicantId = inputMap.get('applicantId');
            String processName = inputMap.get('processName');
            String toNumber = inputMap.get('to');
            String templateName = inputMap.get('templateName');
            String paramsStr = inputMap.get('params'); // comma-separated string or JSON array

            Id recordId = (Id)applicantId;
            String returnResp;
            String resultMessage;

            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
            wrapper.recordId = applicantId;
            wrapper.loanApplicationId = loanId;
            wrapper.type = processName;
            wrapper.mobNumber = toNumber;
            wrapper.templateName = templateName;
            wrapper.content = paramsStr;

            IntHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);

            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Integration_Settings__c> intSettingList = [
                SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                FROM Integration_Settings__c WHERE Name = 'whatsappSMS' LIMIT 1
            ];
            Integration_Settings__c intSetting = intSettingList[0];

            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueOf('412');
                integrationDetail.Prerequisite__c = String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Related_Record_Id__c = recordId;
                resultMessage = String.join(respWrapper.prerequisiteError, ', ');
                returnResp = resultMessage;
            } else {
                Map<String, String> integrationRequestMap = new Map<String, String>();
                integrationRequestMap.put('intSettingName', 'whatsappSMS');
                integrationRequestMap.put('requestJSON', respWrapper.payload);

                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);

                integrationDetail.Calling_Source__c = wrapper.type;
                integrationDetail.Request_JSON__c = respWrapper.payload;
                integrationDetail.Response_JSON__c = JSON.serialize(resp.getBody());
                integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                integrationDetail.Method_Type__c = intSetting.Request_Method__c;
                integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                integrationDetail.Related_Record_Id__c = recordId;
                integrationDetail.Name = processName;
                integrationDetail.Loan_Application__c = loanId;
                insert integrationDetail;
            }
            return returnResp;
        } catch (Exception e) {
            System.debug('the exception for whatsapp sms is:'+e.getMessage()+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + e.getStackTraceString());
        }
    }

    public class WhatsAppResponseWrapper {
        public String message;
        public Boolean status;
    }
}