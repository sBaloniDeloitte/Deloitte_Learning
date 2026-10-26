public without sharing class WhatsAppHandler implements IntegrationInterface {
    static String conLabels = 'WHATSAPP_API';
    public static Map<String, String> constants = Utility.getConstants(conLabels);

    @AuraEnabled
    public static Map<String, String> getConstants() {
        return constants;
    }

    public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) {
        List<String> errorMessages = new List<String>();
        if (String.isBlank(wrapper.mobNumber)) {
            errorMessages.add('Error: Please provide recipient mobile number');
        }
        if (String.isBlank(wrapper.templateName)) {
            errorMessages.add('Error: Please provide template name');
        }
        if (String.isBlank(wrapper.content)) {
            errorMessages.add('Error: Please provide template parameters');
        }
        return errorMessages;
    }

    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        try {
            WhatsAppRequestWrapper req = new WhatsAppRequestWrapper();
            req.to = wrapper.mobNumber;
            req.templateName = wrapper.templateName;
            // Assuming wrapper.content is a comma-separated string of parameters
            if (!String.isBlank(wrapper.content)) {
                req.params = wrapper.content.split(',');
            } else {
                req.params = new List<String>();
            }
            String requestJSON = JSON.serialize(req);
            System.debug('WhatsApp requestJSON: ' + requestJSON);
            return requestJSON;
        } catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'WhatsAppHandler', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
    }

    public class WhatsAppRequestWrapper {
        public String to;
        public String templateName;
        public List<String> params;
    }
}