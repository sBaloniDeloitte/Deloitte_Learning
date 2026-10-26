public with sharing class PANToGSTController {
    @AuraEnabled
    public static String initiateAPIRequest(Map<String, String> inputMap) {
        // try {
            String loanId = inputMap.get('loanId');
            String applicantId = inputMap.get('applicantId');
            String processName = inputMap.get('processName');
            String returnResp;
            String resultMessage;

            Integration_Master__mdt metadata = [SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c,
                                                Client_Id__c, Client_Secret__c, Allowed_Retry__c, Gestation_Period__c,
                                                Refresh_Allowed__c, Activity_Name__c FROM Integration_Master__mdt 
                                                WHERE Activity_Name__c = :processName LIMIT 1];

            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper(); 
            wrapper.recordId = applicantId;
            wrapper.loanApplicationId = loanId;  
            wrapper.type = processName;
            wrapper.endpoint = metadata.Endpoint__c;
            wrapper.requestMethod = metadata.Request_Method__c;
            wrapper.handlerClass = metadata.Handler_Class__c;
            wrapper.clientId = metadata.Client_Id__c;
            wrapper.clientSecret = metadata.Client_Secret__c;
            wrapper.allowedRetry = metadata.Allowed_Retry__c;
            wrapper.gestationPeriod = metadata.Gestation_Period__c;
            wrapper.activityname = metadata.Activity_Name__c;
            wrapper.refreshallowed = metadata.Refresh_Allowed__c;
            wrapper.handlername = metadata.Handler_Class__c;
            
            IntHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);

            List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                                                            FROM Integration_Settings__c WHERE Name = 'Loan Applicant GST Search' LIMIT 1];

            Integration_Settings__c intSetting = intSettingList[0];

            Integration_Details__c integrationDetail = new Integration_Details__c();

            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = '412';
                integrationDetail.Prerequisite__c = String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                resultMessage = String.join(respWrapper.prerequisiteError, ', ');
                System.debug('resultMessage: ' + resultMessage);
                returnResp = resultMessage;
            } else {
                Map<String, String> integrationRequestMap = new Map<String, String>();
                integrationRequestMap.put('intSettingName', 'Loan Applicant GST Search');
                integrationRequestMap.put('requestJSON', respWrapper.payload);
                
                String bearer = Utility.getAccessToken();
                System.debug('bearer----' + bearer);
                integrationRequestMap.put('bearer', bearer);

                HTTPResponse resp; 
                //if(!Test.isrunningTest()){  
                //Commented by - Atika For testing
                resp  = Utility.executeAPIRequest(integrationRequestMap);
                //string responseData = '{"statusCode": "101","requestId": "7ad45acb-dc33-11e8-8063-cba6293b15e6","result": [{"emailId": "","applicationStatus": "","mobNum": "","pan": "AAACR5055K","gstinRefId": "","regType": "","authStatus": "Active","gstinId": "09AAACR5055K1Z5", "registrationName": "","tinNumber": ""},{"emailId": "","applicationStatus": "","mobNum": "","pan": "AAACR5055K","gstinRefId": "","regType": "","authStatus": "Active","gstinId": "03AAACR5055K2ZG","registrationName": "","tinNumber": ""}],"clientData": {"caseId": "123456"}}';
                //string response = '[{"emailId": "","applicationStatus": "","mobNum": "","pan": "AAACR5055K","gstinRefId": "","regType": "","authStatus": "Active","gstinId": "09AAACR5055K1Z5","registrationName": "","tinNumber": ""},{"emailId": "","applicationStatus": "","mobNum": "","pan": "AAACR5055K","gstinRefId": "","regType": "","authStatus": "Active","gstinId": "03AAACR5055K2ZG","registrationName": "","tinNumber": ""}]';
                //}

                if(resp != null){
                    //Commented by - Atika For testing
                	GstinResponseWrapper mcaResp = (GstinResponseWrapper) JSON.deserialize(resp.getBody(), GstinResponseWrapper.class);
                	System.debug('mcaResp: ' + mcaResp);

                    returnResp = JSON.serialize(mcaResp);
                }
                /*if(responseData != null){
                    //Commented by - Atika For testing
                	GstinResponseWrapper mcaResp = (GstinResponseWrapper) JSON.deserialize(responseData, GstinResponseWrapper.class);
                	System.debug('mcaResp: ' + mcaResp);

                    returnResp = JSON.serialize(mcaResp);
                }*/

                integrationDetail.Calling_Source__c = wrapper.type;
                integrationDetail.Request_JSON__c = respWrapper.payload;
                //Commented by - Atika For testing
                if(resp != null) {
                    integrationDetail.Response_JSON__c = resp.getBody();//response;
                    integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                }
                /*if(response != null) {
                    integrationDetail.Response_JSON__c = response;//resp.getBody();
                    integrationDetail.Status__c = '200';
                }*/
                integrationDetail.Method_Type__c = intSetting.Request_Method__c;
                integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.Name = processName;
                integrationDetail.Loan_Application__c = loanId;
                integrationDetail.Related_Record_Id__c = applicantId;
                integrationDetail.Is_Success_Response__c = true;

                insert integrationDetail;
            }

            return returnResp;
        // } catch (Exception e) {
        //    throw new AuraHandledException(e.getMessage());
        // }
    }

    public class GstinResponseWrapper {
        public String statusCode;
        public String requestId;
        public List<ResultItem> result;
        public ClientData clientData;
    }

    public class ResultItem {
        public String emailId;
        public String applicationStatus;
        public String mobNum;
        public String pan;
        public String gstinRefId;
        public String regType;
        public String authStatus;
        public String gstinId;
        public String registrationName;
        public String tinNumber;
    }

    public class ClientData {
        public String caseId;
    }
    
}