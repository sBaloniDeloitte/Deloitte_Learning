public with sharing class COMM_CollateralDedupFindAllcteController {

    static String conLabels = 'COLLATERAL_DEDUPE_F&A';
    public static Map<String, String> constants = Utility.getConstants(conLabels);

    @AuraEnabled
    public static Map<String, String> getConstants() {
        return constants;
    }

    @AuraEnabled
    public static String initiateAPIRequest(Map<String, String> inputMap) {
        String returnresp='';
        try {
            String loanId = inputMap.get('loanId');
            String processName = inputMap.get('processName');
            String collateralJson = inputMap.get('collateralJson');
            String resultMessage;

            // Optional - provide from inputMap if needed
            String applicantId = inputMap.containsKey('applicantId') ? inputMap.get('applicantId') : null;

            Integration_Master__mdt metadata = [
                SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c,
                    Client_Id__c, Client_Secret__c, Allowed_Retry__c, Gestation_Period__c,
                    Refresh_Allowed__c, Activity_Name__c
                FROM Integration_Master__mdt
                WHERE Activity_Name__c = :processName
                LIMIT 1
            ];
            System.debug('metadata26--' + metadata);

            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper(); 
            wrapper.loanApplicationId = loanId;
            wrapper.collateralJson = collateralJson;  
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

            List<Integration_Settings__c> intSettingList = [
                SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                FROM Integration_Settings__c
                WHERE Name = 'Collateral Dedupe F&A' LIMIT 1
            ];

            Integration_Settings__c intSetting = intSettingList.isEmpty() ? null : intSettingList[0];

            Integration_Details__c integrationDetail = new Integration_Details__c();

            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueOf('412');
                integrationDetail.Prerequisite__c = String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = '';
                integrationDetail.Loan_Application__c = loanId;
                integrationDetail.EndPoint__c = intSetting != null ? intSetting.Endpoint__c : null; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 

                resultMessage = String.join(respWrapper.prerequisiteError, ', ');
                System.debug('resultMessage: ' + resultMessage);
                returnResp = resultMessage;

            } else {
                Map<String, String> integrationRequestMap = new Map<String, String>();
                integrationRequestMap.put('intSettingName', 'Collateral Dedupe F&A');
                integrationRequestMap.put('requestJSON', respWrapper.payload);

                String bearer = Utility.getAccessToken();
                integrationRequestMap.put('bearer', bearer);

                HttpResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                String respBody = resp.getBody();
                returnresp= respBody; 
                system.debug('respBody--'+respBody);

                if (resp.getStatusCode() == 200 && respBody != null && respBody != '') {
                    COMM_CollateralDedupeFindAllcteHandler.FindPropertyRequestWrapper req = 
                        (COMM_CollateralDedupeFindAllcteHandler.FindPropertyRequestWrapper) 
                        JSON.deserialize(respWrapper.payload, COMM_CollateralDedupeFindAllcteHandler.FindPropertyRequestWrapper.class);

                    FindAndGenerateCollateralResponseWrapper responseWrapper = 
                        (FindAndGenerateCollateralResponseWrapper) 
                        JSON.deserialize(respBody, FindAndGenerateCollateralResponseWrapper.class);

                    if (responseWrapper != null && responseWrapper.Response != null && !responseWrapper.Response.isEmpty()) {
                        List<Response> records = responseWrapper.Response;

                        if (records.size() == 1 && records[0].MATCH_COUNT == '0') {
                            Map<String, String> noMatchResult = new Map<String, String>();
                            noMatchResult.put('UPID', records[0].UPID);
                            noMatchResult.put('Status', 'No match found');
                            noMatchResult.put('UNIQUEREQUEST_ID', req.UNIQUEREQUEST_ID);
                            noMatchResult.put('EXTERNAL_ID', req.EXTERNAL_ID);
                            noMatchResult.put('ASSIGNMENT_PERCENTAGE', records[0].ASSIGNMENT_PERCENTAGE);

                            returnResp = JSON.serialize(noMatchResult);
                        } 
                        else if (records.size() > 0 && Integer.valueOf(records[0].MATCH_COUNT) > 0) {
                            List<Map<String, Object>> processedRecords = new List<Map<String, Object>>();

                            for (Response rec : records) {
                                if(rec.UPID != null && rec.UPID != ''){
                                Map<String, Object> recMap = new Map<String, Object>();
                                recMap.put('upid', rec.UPID);                                    
                                recMap.put('matchType', rec.MATCH_TYPE);
                                recMap.put('cscore', rec.MATCHPERCENTAGE);
                                recMap.put('responseUPID', rec);
                                recMap.put('floorNumber', rec.FLOOR_NUMBER);
                                recMap.put('apfNumber', rec.APF_NUMBER);
                                recMap.put('tower', rec.TOWER_NAME);
                                recMap.put('unitNumber', rec.UNIT_NUMBER);
                                recMap.put('picode', rec.PINCODE);
                                recMap.put('city', rec.DISTRICT_CITY);
                                recMap.put('state', rec.STATE);
                                recMap.put('address3', rec.ADDRESS_3);
                                recMap.put('address2', rec.ADDRESS_2);
                                recMap.put('address1', rec.ADDRESS_1);
                                recMap.put('address', rec.ADDRESS);
                                recMap.put('externalId',rec.EXTERNAL_ID);
                                recMap.put('ASSIGNMENT_PERCENTAGE', rec.ASSIGNMENT_PERCENTAGE);
                                recMap.put('collateralType',rec.COLLATERAL_TYPE);
                                processedRecords.add(recMap);
                            }
                            }

                            Map<String, Object> responseWrapperData = new Map<String, Object>();
                            responseWrapperData.put('status', 'matches found');
                            responseWrapperData.put('records', processedRecords);
                            responseWrapperData.put('UNIQUEREQUEST_ID', req.UNIQUEREQUEST_ID);
                            responseWrapperData.put('EXTERNAL_ID', req.EXTERNAL_ID);

                            returnResp = JSON.serialize(responseWrapperData);
                        }
                    }
                } else {
                    returnResp = resp.getBody();
                }
            }

            // 🔹 Always insert integration record once, at the end
            integrationDetail.Status__c = (respWrapper != null && respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty())
                                            ? '412'
                                            : (returnResp != null && returnResp.startsWith('Error:') 
                                                ? String.valueOf(500) 
                                                : String.valueOf(200));
            integrationDetail.Name = processName;
            integrationDetail.Object_Name__c = '';
            integrationDetail.Loan_Application__c = loanId;
            integrationDetail.EndPoint__c = intSetting != null ? intSetting.Endpoint__c : null;
            integrationDetail.Request_JSON__c = respWrapper.payload;
            //integrationDetail.Response_JSON__c = returnResp;
           
            ContentVersion responseContent = new ContentVersion();
            responseContent.Title = 'dedupeResponse'+loanId+'_TXT';
            responseContent.PathOnClient = 'dedupeResponse'+loanId+'.txt';
            responseContent.VersionData = Blob.valueOf(returnResp);
            // integrationDetail.Response_JSON__c = null;
			Insert responseContent;
            insert integrationDetail;
            
         
            List<ContentVersion> dedupeResponseVersion = [Select Id, ContentDocumentId from ContentVersion where id =: responseContent.Id];
            // List<ContentDocumentLink> cdlToInsert = new List<ContentDocumentLink>();
            // for(Integer i = 0; i<dedupeResponseVersion.size();i++){
                ContentDocumentLink cdl2 = new ContentDocumentLink();
                cdl2.ContentDocumentId = dedupeResponseVersion[0].ContentDocumentId;
                cdl2.LinkedEntityId = integrationDetail.Id;
                cdl2.ShareType = 'V'; // Private
                cdl2.Visibility = 'AllUsers'; // Or 'AllUsers'
                // cdlToInsert.add(cdl2);
            // }
            Insert cdl2;

            return returnResp;

        } catch (Exception e) {
            return returnresp;
            //throw new AuraHandledException('Error occurred while processing API: ' +e.getMessage()+' '+ e.getStackTraceString());
            
        }
    }

    public class FindAndGenerateCollateralResponseWrapper {
        public List<Response> Response;
    }

    public class Response {
        public String ADDRESS;
        public String ADDRESS_1; 
        public String ADDRESS_2;
        public String ADDRESS_3;
        public String ADDRESS_TYPE;
        public String AFFORDABLE;
        public String APF_NONAPF;
        public String APF_NUMBER;
        public String ASSIGNMENT_PERCENTAGE;
        public String BUILDER_ID;
        public String BUILDER_NAME;
        public String BUILDING_NAME;
        public String CERSAINUMBER;
        public String CIF_NUMBER;
        public String COLLATERAL_TYPE;
        public String CONSTRUCTION_TYPE;
        public String MATCHPERCENTAGE;
        public String DEVELOPER_NAME;
        public String DISTRICT_CITY;
        public String DOCUMENTEDVALUE;
        public String ENTITY_NAME;
        public String EXTENT_OF_BUILTUP_AREA;
        public String EXTENT_OF_LAND;
        public String EXTERNAL_ID;
        public String FLAG1;
        public String FLAG2;
        public String FLAG3;
        public String FLAT_PLOT_NUMBER;
        public String FLOOR_NUMBER;
        public String GOLBALUPID;
        public String HOUSE_NUMBER;
        public String LANDMARK1;
        public String LANDMARK2;
        public String LANREFERENCE_NO;
        public String LATITUDE;
        public String LOANAPPLICATION_ID;
        public String LOAN_TYPE;
        public String LOCALITY;
        public String LONGITUDE;
        public String MARKETVALUE;
        public String MATCH_COUNT;
        public String MATCH_TYPE;
        public String PINCODE;
        public String PROJECT_ID;
        public String PROJECT_NAME;
        public String PROPERTY_ID;
        public String PROPERTY_NATURE;
        public String PROPERTY_STATUS;
        public String PROPERTY_TYPE;
        public String RECORD_TYPE;
        public String REGION_THESIL;
        public String SCALE_TYPE;
        public String SOURCE_SYSTEM;
        public String STATE;
        public String STATUS_MESSAGE;
        public String SURVEY_NUMBER;
        public String TOWER_NAME;
        public String UNIQUEREQUEST_ID;
        public String UNIT_NUMBER;
        public String UPID;
        public String UPID_TYPE;
        public String UTILITY_TYPE;
        public String Message;
 public String ResponseCode;
 public String Status;       
 public String MatchCount;
 public String LanReferenceNo;
 public String UniqueRequestId;

    }

    @AuraEnabled
public static String initiateDummyAPIRequest(Map<String, String> inputMap) {

    Map<String,Object> response = new Map<String,Object>();

    response.put('status', 'matches found');
    response.put('UNIQUEREQUEST_ID', 'REQ123456');
    response.put('EXTERNAL_ID', 'EXT123456');

    List<Map<String,Object>> records = new List<Map<String,Object>>();

    Map<String,Object> rec1 = new Map<String,Object>();
    rec1.put('upid','CT100001');
    rec1.put('matchType','Exact');
    rec1.put('cscore','98');
    rec1.put('floorNumber','2');
    rec1.put('apfNumber','APF001');
    rec1.put('tower','Tower A');
    rec1.put('unitNumber','201');
    rec1.put('picode','305001');
    rec1.put('city','Ajmer');
    rec1.put('state','Rajasthan');
    rec1.put('address1','Address Line 1');
    rec1.put('address2','Address Line 2');
    rec1.put('address3','Address Line 3');
    rec1.put('address','Complete Address');
    rec1.put('externalId','EXT123456');
    rec1.put('ASSIGNMENT_PERCENTAGE','25');
    rec1.put('collateralType','Residential');

    Map<String,Object> rec2 = new Map<String,Object>();
    rec2.put('upid','CT100002');
    rec2.put('matchType','Probable');
    rec2.put('cscore','91');
    rec2.put('floorNumber','3');
    rec2.put('apfNumber','APF002');
    rec2.put('tower','Tower B');
    rec2.put('unitNumber','302');
    rec2.put('picode','305001');
    rec2.put('city','Ajmer');
    rec2.put('state','Rajasthan');
    rec2.put('address1','Address Line 1');
    rec2.put('address2','Address Line 2');
    rec2.put('address3','Address Line 3');
    rec2.put('address','Complete Address');
    rec2.put('externalId','EXT123457');
    rec2.put('ASSIGNMENT_PERCENTAGE','');
    rec2.put('collateralType','Residential');

    records.add(rec1);
    records.add(rec2);

    response.put('records', records);

    return JSON.serialize(response);
}
}