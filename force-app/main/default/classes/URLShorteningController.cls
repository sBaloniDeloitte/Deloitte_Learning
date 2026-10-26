public with sharing class URLShorteningController {
    public static String urlShoetening ( Map<String,String> inputMap){
    try{
        List<string> validatemandate = new List<string>();
            List<string> constructpayload = new List<string>();
            String resultMessage;
            String loanId = inputMap.get('loanId');
            String applicantId = inputMap.get('recordId');
            String processName = inputMap.get('processName');
            String s3link = inputMap.get('s3link');
            Map<String,API_Exceptions__mdt> allMetaData = API_Exceptions__mdt.getAll();
            Application_Applicant__c app = [Select id, Pan_Name__c, PAN_Number__c,DOB__c,DOI__c from Application_Applicant__c where id = :applicantId];

             String returnResp;
             Integration_Master__mdt metadata = [SELECT 
                                                    Process_Name__c,
                                                    Handler_Class__c,
                                                    Endpoint__c,
                                                    Request_Method__c,
                                                    Client_Id__c,
                                                    Client_Secret__c,
                                                    Allowed_Retry__c,
                                                    Gestation_Period__c,
                                                    Refresh_Allowed__c,
                                                    Activity_Name__c
                                                FROM Integration_Master__mdt 
                                                WHERE Activity_Name__c = :processName LIMIT 1];
            
            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
            
            wrapper.recordId =applicantId ;
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
            wrapper.handlername =  metadata.Handler_Class__c;
            wrapper.s3URL = s3Link;
          
           
            
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
            FROM Integration_Settings__c WHERE Name = 'Loan URL Shortening Service' LIMIT 1];
            Integration_Settings__c intSetting = intSettingList[0];
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name =processName ;
                integrationDetail.EndPoint__c = intSetting.Endpoint__c;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                returnResp = resultMessage;
            }
            else{
                Map<String,String> integrationRequestMap = new Map<String,String>();
                integrationRequestMap.put('intSettingName','Loan URL Shortening Service');
                integrationRequestMap.put('requestJSON',respWrapper.payload);
                String bearer = Utility.getAccessToken();
                integrationRequestMap.put('bearer', bearer);
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                if(resp.getStatusCode()== 200 || resp.getStatusCode()== 400){
                    URLShorteningResponseServiceWrapper responseJSON = (URLShorteningResponseServiceWrapper) JSON.deserialize(resp.getBody(), URLShorteningResponseServiceWrapper.class);
                    if(resp.getStatusCode()== 200){
                        returnResp=JSON.serialize(responseJSON);
                    }
                    else{
                        for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                            System.debug('responseJSON.message----' + responseJSON.message);
                            if(execeptionMeta.Error_Code__c ==responseJSON.message){
                                returnResp = 'Error:' + execeptionMeta.Error_Message__c;
                            }
                         }
                    }
                }
                else{
                    if(resp.getStatusCode()== 503||resp.getStatusCode()== 401){
                        for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                             returnResp = 'Error:' + execeptionMeta.Error_Message__c;
                             }
                    }
                  
                    else{
                        for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                            if(execeptionMeta.Error_Code__c =='URL Shortening Error')
                            returnResp = 'Error:' + execeptionMeta.Error_Message__c;
                            }
                    }
                }
               
             }
            return returnResp;
        }
        catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
     }
     public class URLShorteningResponseServiceWrapper {
        public boolean status;
        public cls_data data;
        public String message;	//Short link has been created
        public String statusCode;	//lms-200-1001
        public cls_error error;
    }
	public class cls_data {
		public String short_link;	//CcGzPFJ
		public String persigned_link;	//https://s1gne47.s3.ap-south-1.amazonaws.com/1154%2021671800997771%20%281%291692681608359.png?X-Amz-Security-Token=FwoGZXIvYXdzED8aDF77ip%2FE9I2kFD2O6SKzARVkzA2e3IpGAmN1%2B8qtF7kflW%2FDIIHQcBQNUmYbqLMzW2GgAXSRMlaVBKR%2Fb3OOdNjwaGu2pEt7OKJb1etTisSmgM27TB63GsfUd9ZPl6iaoHPJEHkeszJI%2FgRDGxSWEQV1%2F6OA1S8RM58%2BLMZg6rcZIsky60kF%2FpY8%2BITuSo6bbyLrFtDEG4L8rHlW%2FJYN97rapi%2F4YY6dYABLxTrGium0hiLiB0cIZ3hJwWimMAvGZlMuKImLkacGMi3VUUJatyz6xu7%2B7M9fjDOhyaDh1eB6QzPIhiKBouRY8695X0IHvfjqy3SrTWE%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20230822T052009Z&X-Amz-SignedHeaders=host&X-Amz-Expires=3600&X-Amz-Credential=ASIAQVU77SYZWY3BL44L%2F20230822%2Fap-south-1%2Fs3%2Faws4_request&X-Amz-Signature=7e99186b3ea08f3d32d66ded7687e701092ca6a3166491cd464f3b00562f73a0
		public Integer validity;	//0
		public String application_name;	//SRM
		public Integer status;	//1
		public String short_link_with_domain;	//https://ut.godrejhf.com/sl/CcGzPFJ
		public String bucket;	//s1gne47
		public Integer is_s3_url;	//1
		public String createdat;	//2023-08-22T05:20:09.451+0000
		public String s3_link;	//https://s1gne47.s3.ap-south-1.amazonaws.com/1154 21671800997771 (1)1692681608359.png
		public String short_link_expiration_date;	//2023-08-22T05:20:09.451+0000
		public String persigned_url_expiration_date;	//2023-08-22T06:20:09.292+0000
	}
	public class cls_error {
	}
}