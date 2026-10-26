public with sharing class COMM_CreateCollateralApiController {

    @AuraEnabled
    public static Map<String,Object> initiateAPIRequest(Map<String,String> inputMap) {
        String returnResp = '';
        CollateralResponse colRespObj;
        Map<String,Object> returnObjMap = new Map<String,Object>();
        Integration_Details__c integrationDetail = new Integration_Details__c();
        try {
            String loanId              = inputMap.get('loanId');
            String processName         = inputMap.get('processName');
            String primaryApplicantCif = inputMap.get('primaryApplicantCif');
            String appColId            = inputMap.get('appColId'); // NEW: read appColId from input map

            if (String.isBlank(appColId)) {
                if (colRespObj == null) {
                    colRespObj = new CollateralResponse();
                }
                if (colRespObj.returnStatus == null) {
                    colRespObj.returnStatus = new ReturnStatus();
                }
                colRespObj.returnStatus.returnText = 'Error: Application Collateral Id (appColId) is missing in the request.';
                returnObjMap.put('colRespObj',  colRespObj);
                returnObjMap.put('intDetailObj', integrationDetail);
                return returnObjMap;
            }

            // Fetch Integration Metadata
            List<Integration_Master__mdt> metadataList = [
                SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, 
                       Client_Id__c, Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, 
                       Refresh_Allowed__c, Activity_Name__c
                FROM Integration_Master__mdt 
                WHERE Activity_Name__c = :processName //Create Collateral
                LIMIT 1
            ];
        
            if (metadataList.isEmpty()) {
                if (colRespObj == null) {
                    colRespObj = new CollateralResponse();
                }
                if (colRespObj.returnStatus == null) {
                    colRespObj.returnStatus = new ReturnStatus();
                }
                colRespObj.returnStatus.returnText = 'Error: No metadata found for the given process.';
                throw new AuraHandledException('No integration metadata found for process: ' + processName);
            }
            Integration_Master__mdt metadata = metadataList[0];

            // Prepare request wrapper
            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper(); 
            wrapper.loanApplicationId = loanId;  
            wrapper.type              = processName;
            wrapper.applicantId       = primaryApplicantCif; // primary applicant CIF
            wrapper.appColId          = appColId;            // NEW: pass appColId into the wrapper
            wrapper.endpoint          = metadata.Endpoint__c;
            wrapper.requestMethod     = metadata.Request_Method__c;
            wrapper.handlerClass      = metadata.Handler_Class__c;
            wrapper.clientId          = metadata.Client_Id__c;
            wrapper.clientSecret      = metadata.Client_Secret__c;
            wrapper.allowedRetry      = metadata.Allowed_Retry__c;
            wrapper.gestationPeriod   = metadata.Gestation_Period__c;
            wrapper.activityname      = metadata.Activity_Name__c;
            wrapper.refreshallowed    = metadata.Refresh_Allowed__c;
            wrapper.handlername       = metadata.Handler_Class__c;

            // Validate process & get payload
            IntHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            integrationDetail.Name                  = processName;
            integrationDetail.Object_Name__c        = 'Opportunity';
            integrationDetail.Loan_Application__c   = loanId;
            integrationDetail.EndPoint__c           = metadata.Endpoint__c;
            integrationDetail.Request_JSON__c       = respWrapper.payload;

            // Handle prerequisite errors
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c       = '412';
                integrationDetail.Prerequisite__c = String.join(respWrapper.prerequisiteError, ', ');
                if (colRespObj == null) {
                    colRespObj = new CollateralResponse();
                }
                if (colRespObj.returnStatus == null) {
                    colRespObj.returnStatus = new ReturnStatus();
                }
                colRespObj.returnStatus.returnText = String.join(respWrapper.prerequisiteError, ', ');
                returnObjMap.put('colRespObj',  colRespObj);
                returnObjMap.put('intDetailObj', integrationDetail);
                return returnObjMap;
            }

            String collateralId     = '';
            String collateralRefId  = '';

            // CHANGED: filter by Id (appColId) instead of HL_Loan_Application__c + ORDER BY ... LIMIT 1
            List<Application_Collateral__c> appColList = [
                SELECT Id, HL_Loan_Application__c, Collateral__c
                FROM   Application_Collateral__c
                WHERE  Id = :appColId
                LIMIT  1
            ];
            List<Collateral__c> colList = new List<Collateral__c>();
            if (appColList.size() > 0) {
                collateralId = appColList[0].Collateral__c;
                colList = [
                    SELECT Id, PLF_ID__c
                    FROM   Collateral__c
                    WHERE  Id = :collateralId
                ];
            }

            // Prepare request map for utility class
            Map<String, String> integrationRequestMap = new Map<String, String>();
            String bearer = Utility.getAccessToken();
            integrationRequestMap.put('bearer',        bearer);
            integrationRequestMap.put('intSettingName','createCollateral');
            integrationRequestMap.put('serviceName',   'createCollateral');
            integrationRequestMap.put('requestJSON',   respWrapper.payload);
            integrationRequestMap.put('MESSAGEID',     '167036797111');
            integrationRequestMap.put('ENTITYID',      '14589954555');
            integrationRequestMap.put('ServiceVersion','1');
            integrationRequestMap.put('RequestTime',   String.valueOf(DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss')));
            integrationRequestMap.put('Language',      'ENG');

            // Execute HTTP API Request
            System.debug('75 ' + respWrapper.payload);
            HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
            Integer statusCode = resp.getStatusCode();
            integrationDetail.Status__c            = String.valueOf(statusCode);
            integrationDetail.Response_JSON__c     = resp.getBody();
            integrationDetail.Related_Record_Id__c = loanId;
            integrationDetail.Method_Type__c       = metadata.Request_Method__c;

            if (statusCode == 200) {
                String jsonResponse = resp.getBody();
                colRespObj = (CollateralResponse) JSON.deserialize(jsonResponse, CollateralResponse.class);
                if (colRespObj != null && colRespObj.returnStatus != null) {
                    if (colRespObj.returnStatus.returnText == 'Success') {
                        collateralRefId = colRespObj.collateralRef;
                        if (colList.size() > 0) {
                            colList[0].PLF_ID__c = collateralRefId;
                            //update colList[0]; // PushToLMS.processCollateral handles this update
                        }
                    }
                } 
            }    
        } catch (Exception e) {
            System.debug('Error in initiate API create collateral controller' + e.getStackTraceString());
            throw new AuraHandledException('Error during processing: ' + e.getMessage());
        }
        returnObjMap.put('colRespObj',  colRespObj);
        returnObjMap.put('intDetailObj', integrationDetail);
        return returnObjMap;
    }


    public class CollateralResponse {
        public String  collateralRef;        // CT3910200005
        public Integer maxCollateralValue;   // 0
        public Integer splLtv;               // 0
        public Boolean alwMultiLoanAssign;
        public Boolean alwThirdPartyAssign;
        public ReturnStatus returnStatus;
        public Integer version;              // 0
    }

    public class ReturnStatus {
        public String returnCode; // 0000
        public String returnText; // Success
    }
}