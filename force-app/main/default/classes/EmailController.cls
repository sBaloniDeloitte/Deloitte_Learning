public with sharing class EmailController {
    static string conLabels = 'SMS_API';
                         
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }

    @AuraEnabled
    public static String initiateAPIRequest(Map<String,String> inputMap){
        try {
            return initiateAPIRequestInternal(inputMap);
        }
        catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }


    public static String initiateAPIRequestInternal(Map<String,String> inputMap){
        try {
            System.debug('initiateAPIRequestInternal inputMap for queueable: ' + inputMap);
            Integration_Details__c integrationDetails = new Integration_Details__c();
            String loanId = inputMap.get('loanId');
            String applicantId = inputMap.get('applicantId');
            String processName = inputMap.get('processName');
            String content = inputMap.get('content');
            String subject = inputMap.get('subject');
            String email = inputMap.get('email');
            string fileType = inputMap.get('fileType');
            string filename = inputMap.get('filename');
            string base64 = inputMap.get('base64String');
            Id recordId;
            String objectName = 'Unknown';
            if (applicantId != null) {
                recordId = (Id)applicantId;
                objectName = recordId.getSObjectType().getDescribe().getName();
            }
            String returnResp;
            String resultMessage;

            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
            wrapper.recordId = applicantId;
            wrapper.loanApplicationId = loanId;
            wrapper.type = processName;
            wrapper.email =email;
            wrapper.content  = content;
            wrapper.subject = subject;
            wrapper.base64String = base64;	
            wrapper.fileType = fileType;	
            wrapper.filename = filename;

           
            
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                                                            FROM Integration_Settings__c WHERE Name = 'Email Notification' LIMIT 1];
            if (intSettingList.isEmpty()) {
                System.debug('No Integration_Settings__c record found for Name = "Email Notification". Please configure the integration settings.');
            }
            Integration_Settings__c intSetting = intSettingList[0];
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name =processName ;
                integrationDetail.Object_Name__c = objectName;
                integrationDetail.Related_Record_Id__c  = recordId;
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                System.debug('resultMessage: '+resultMessage);
                returnResp = resultMessage;
            }
            else{
                Map<String,String> integrationRequestMap = new Map<String,String>();
                integrationRequestMap.put('intSettingName','Email Notification');
                integrationRequestMap.put('requestJSON',respWrapper.payload);
                String bearer = Utility.getAccessToken();
                System.debug('bearer----'+bearer);
                integrationRequestMap.put('bearer',bearer);
              
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                System.debug('resp'+resp);
                // system.debug('Request-->'+respWrapper.payload);

                
                
                if(String.isNotBlank(base64)){
                    ContentVersion cv = new ContentVersion();
                    cv.Title = 'LoanApplicationForm_Request.txt';
                    cv.PathOnClient = 'LoanApplicationForm_Request.txt';
                    cv.VersionData = Blob.valueOf(respWrapper.payload);
                    cv.IsMajorVersion = true;
                    insert cv;
                    List<ContentVersion> contentVersions = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
                    
                    integrationDetail.Object_Name__c = 'ContentDocument';
                    integrationDetail.Related_Record_Id__c = contentVersions[0].ContentDocumentId;
                }
                
                integrationDetail.Calling_Source__c = wrapper.type; 
                // integrationDetail.Request_JSON__c = String.isNotBlank(base64) ? '' : respWrapper.payload; 
                integrationDetail.Request_JSON__c = inputMap.get('email'); 
                integrationDetail.Response_JSON__c = JSON.serialize(resp.getBody());
                integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
                integrationDetail.Method_Type__c = intSetting.Request_Method__c; 
                integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                
                integrationDetail.Object_Name__c = String.isNotBlank(base64) ? 'ContentDocument' : objectName;
                if(integrationDetail.Related_Record_Id__c == null || integrationDetail.Related_Record_Id__c == ''){
                    integrationDetail.Related_Record_Id__c  = recordId;
                }
                integrationDetail.Name = processName; 
                integrationDetail.Loan_Application__c = loanid;
                insert integrationDetail;

            }
            return returnResp; 
        } catch (Exception e) {
            System.debug('Exception in UCIC Controller: ' + e.getMessage() + 'at' + e.getLineNumber());
            return 'ERROR: ' + e.getMessage();
        }
    }

    public class EmailResponseWrapper{
        public String message;	//Success
        public boolean status;
        public String personalizations;
    }
	
}