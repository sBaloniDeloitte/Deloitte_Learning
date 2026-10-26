public with sharing class SMSRequestService {
    static string conLabels = 'Salesforce';
    public static Map<String, String> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<String, String> getConstants(){
        return constants;
    }
    
    public static Map<String, Object> sendWhatsappSMS(String mobileNumber, String templateName, List<String> params) {
        Map<String, Object> resultMap = new Map<String, Object>();
        String requestJSON = '';
        HttpResponse resp;
        try {
            // Build payload JSON
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('to', mobileNumber);
            payload.put('templateName', templateName);
            payload.put('params', params);
            // Convert to JSON string
            requestJSON = JSON.serialize(payload);
            Integration_Settings__c intSetting = [SELECT Name, Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                                                      FROM Integration_Settings__c WHERE Name ='whatsappSMS' Limit 1];
            // Build integration request map
            Map<String, String> integrationRequestMap = new Map<String, String>();
            integrationRequestMap.put('intSettingName', intSetting.Name); // Integration setting name
            integrationRequestMap.put('requestJSON', requestJSON);
            System.debug('Integration Request Map: ' + integrationRequestMap);
            // Call existing utility method to execute API request
            resp = Utility.executeAPIRequest(integrationRequestMap);
            System.debug('WhatsApp API Response: ' + resp.getBody());
        } catch (Exception ex) {
            System.debug('Exception in sendWhatsappSMS: ' + ex.getLineNumber() + ' - ' + ex.getMessage());
            resp = null;
        }
        resultMap.put('requestJSON', requestJSON);
        resultMap.put('resp', resp != null ? resp.getBody() : null);
        return resultMap;
    }
    
    public static void sendSMS(List<String>  mobileNumbers, String message, String source){
        try {
            Integration_Details__c integrationDetails = new Integration_Details__c();
            System.debug('Inside CYKC');
            SMSRequestServiceWrapper sw = new SMSRequestServiceWrapper();
            sw.content=message;
            sw.source='Salesforce';//constants.get('Salesforce');
            sw.listOfMobileNumbers = new List<String>();
            for(String mob: mobileNumbers){
                sw.listOfMobileNumbers.add(mob);
            }
            Map<String,String> integrationRequestMap = new Map<String,String>();
            String bearer = Utility.getAccessToken();
            integrationRequestMap.put('intSettingName','SMS API');
            integrationRequestMap.put('requestJSON',JSON.serialize(sw));
            integrationRequestMap.put('bearer', bearer);
            HTTPResponse resp = Utility.executeRESTAPIRequest(integrationRequestMap);
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class SMSRequestServiceWrapper{
        public String[] listOfMobileNumbers;
        public String content;	//Dear Mr. DOnt use ops data , We are pleased to welcome you to Godrej Finance. Your Business Loan Flexi Funds is disbursed. Loan details are: Loan Account Number - GFL3001BD0014428, Total Withdrawal limit - INR 1,00,00,000, Utilized limit - INR 10,00,000, Total tenure - 12 months, Rate of interest - 10.0 % (Fixed Rate). For complete details, download your Welcome Letter here https://utc.godrejhf.com/GFLINC/wl/EtZLGu1. For any queries, please reach out to us on 022-68815555 or write to us at customercare@godrejcapital.com. Thank you. Team Godrej Finance.
        public String source;	//
    }
    public class cls_listOfMobileNumbers {
        public String mobileNumber;
    }
}