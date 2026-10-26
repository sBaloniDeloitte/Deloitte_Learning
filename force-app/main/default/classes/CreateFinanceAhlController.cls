public without sharing class CreateFinanceAhlController {

    @AuraEnabled
    public static CreateFinanceResponseWrapper initiateAPIRequest(Map<String,Map<String,String>> inputMap, Map<String,String> lmsIdMap) {
        try {   
            system.debug('inputMap::: ' + inputMap);
            String loanId = inputMap.get('inputMap').get('loanId');
            String processName = inputMap.get('inputMap').get('processName');
            String qdpFlag = inputMap.get('inputMap').get('isQdp');
            String applicantId = inputMap.get('inputMap').get('applicantId');
            Boolean isQdp = Boolean.valueOf(qdpFlag);
            //Boolean isRegenerate = inputMap.get('inputMap').containsKey('isRegenerate') && String.valueOf(inputMap.get('inputMap').get('isRegenerate')).toLowerCase() == 'true';
            Map<String,String> appColIdToPlfIdMap = inputMap.containsKey('colRefId') ? inputMap.get('colRefId') : new Map<String,String>();
            CreateFinanceResponseWrapper responseWrapperObj;

            if(String.isEmpty(loanId) || String.isEmpty(processName)) {
                if (responseWrapperObj == null) {
                    responseWrapperObj = new CreateFinanceResponseWrapper();
                }
                if (responseWrapperObj.returnStatus == null) {
                    responseWrapperObj.returnStatus = new CreateFinanceResponseWrapper.ReturnStatus();
                }
                responseWrapperObj.returnStatus.returnText = 'Error: Missing required parameters. Application Id and Process Name';
                //throw new AuraHandledException('Error: Missing required parameters.');
            }

            // Fetch Metadata >> Activity_Name__c = 'Create Finance'
            List<Integration_Master__mdt> metadataList = [
                SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, Client_Id__c, 
                    Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, Refresh_Allowed__c, Activity_Name__c
                FROM Integration_Master__mdt 
                WHERE Activity_Name__c = :processName 
                LIMIT 1
            ];
            Integration_Master__mdt metadata = metadataList.isEmpty() ? null : metadataList[0];

            System.debug('isempty meta'+metadata);
            System.debug('At 28 '+metadata);
            if(metadata == null) {
                if (responseWrapperObj == null) {
                    responseWrapperObj = new CreateFinanceResponseWrapper();
                }
                if (responseWrapperObj.returnStatus == null) {
                    responseWrapperObj.returnStatus = new CreateFinanceResponseWrapper.ReturnStatus();
                }
                responseWrapperObj.returnStatus.returnText = 'Error: No metadata found for the given process.';
                //throw new AuraHandledException('Error: No metadata found for the given process.');
            }

            intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
            wrapper.recordId = applicantId;
            wrapper.loanApplicationId = loanId;  
            wrapper.type = processName;
            wrapper.endpoint = metadata.Endpoint__c;
            wrapper.requestMethod = metadata.Request_Method__c;
            wrapper.clientId = metadata.Client_Id__c;
            wrapper.clientSecret = metadata.Client_Secret__c;
            wrapper.allowedRetry = metadata.Allowed_Retry__c;
            wrapper.gestationPeriod = metadata.Gestation_Period__c;
            wrapper.activityname = metadata.Activity_Name__c;
            wrapper.refreshallowed = metadata.Refresh_Allowed__c;
            wrapper.handlername = metadata.Handler_Class__c;
            wrapper.inputMap = lmsIdMap;
            wrapper.isQdp = isQdp;
            wrapper.mapOfappColIdPlfId = appColIdToPlfIdMap; //map for app COl id to plf id
            System.debug('At 55');
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            System.debug('respWrapper At 59'+respWrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            system.debug('At 61'+processName);
            System.debug('Integration_Settings__c found: ' + [
    SELECT Name FROM Integration_Settings__c WHERE Name = :processName
]);
            Integration_Settings__c intSetting = [
                SELECT Client_Id__c, Client_Secret__c,Authorization__c, Endpoint__c, Content_Type__c, Request_Method__c ,Cookie__c,Entity_Id__c,Message_Id__c
                FROM Integration_Settings__c 
                WHERE Name = :processName 
                LIMIT 1
            ];
            System.debug('intSetting '+intSetting);
            System.debug('At 68'+respWrapper.prerequisiteError);
            if(respWrapper != null && respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                System.debug('At 70');
                //return 'Error: ' + String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Prerequisite_CF__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Endpoint__c = intSetting.Endpoint__c;
                insert integrationDetail;
                //adding the error in returnText
                if (responseWrapperObj == null) {
                    responseWrapperObj = new CreateFinanceResponseWrapper();
                }
                if (responseWrapperObj.returnStatus == null) {
                    responseWrapperObj.returnStatus = new CreateFinanceResponseWrapper.ReturnStatus();
                }

                responseWrapperObj.returnStatus.returnText = String.join(respWrapper.prerequisiteError, ', ');
                return responseWrapperObj;
            }
            else{
                System.debug('At 89');

                Opportunity loanApplication = [SELECT Id, LMS_Loan_Reference__c,LMS_Effective_Rate_of_Return__c,Sub_stage__c FROM Opportunity WHERE Id =: loanId];                
            
                //prerequisite error already returned
                String apiResponse = '';
                if (responseWrapperObj == null) {
                    responseWrapperObj = new CreateFinanceResponseWrapper();
                }
                String applicationNo='';
                Double effectiveRateOfReturn;
                Map<String, String> integrationRequestMap = new Map<String, String>();
                
                String bearer = Utility.getAccessToken();
                System.debug('bearer '+bearer);
                integrationRequestMap.put('Authorization', 'Bearer ' + bearer);
                integrationRequestMap.put('intSettingName', processName);
                integrationRequestMap.put('requestJSON', respWrapper.payload);
                integrationRequestMap.put('endpoint',intSetting.Endpoint__c);
                integrationRequestMap.put('requestMethod',intSetting.Request_Method__c);
                //integrationRequestMap.put('Authorization', intSetting.Authorization__c);
                integrationRequestMap.put('Cookie', intSetting.Cookie__c);
                integrationRequestMap.put('ENTITYID', intSetting.Entity_Id__c); 
                integrationRequestMap.put('Content-Type', intSetting.Content_Type__c);
                integrationRequestMap.put('ServiceName', 'createFinance');
                integrationRequestMap.put('MESSAGEID', intSetting.Message_Id__c);

                HTTPResponse resp = executeRESTAPIRequest(integrationRequestMap);

                if(resp != null && resp.getStatusCode() == 200){ //success
                        System.debug('resp.getBody(): '+resp.getBody());
                    try {     
                        responseWrapperObj = (CreateFinanceResponseWrapper) JSON.deserialize(resp.getBody(), CreateFinanceResponseWrapper.class);
                        if(responseWrapperObj!=NULL){
                             apiResponse = JSON.serialize(responseWrapperObj);
                             System.debug('returnStatus>>>'+responseWrapperObj.returnStatus);
                            if(responseWrapperObj.returnStatus!=NULL && (String.isNotBlank(responseWrapperObj.returnStatus.returnText))){
                                if(responseWrapperObj.returnStatus.returnText == 'Success'){
                                    System.debug('success >> ');
                                    System.debug(responseWrapperObj.finReference);
                                    System.debug( responseWrapperObj.financeSchedule.summary.effectiveRateOfReturn);
                                    //need t put application no here>>
                                    applicationNo = String.isNotBlank(responseWrapperObj.finReference) ? responseWrapperObj.finReference : ''; //ASK ANIL FOR A VALID RESPONSE BODY > GIVEN 
                                    if (responseWrapperObj!= null && responseWrapperObj.financeSchedule != null && responseWrapperObj.financeSchedule.summary != null &&
                                        responseWrapperObj.financeSchedule.summary.effectiveRateOfReturn != null) {
                                        effectiveRateOfReturn = responseWrapperObj.financeSchedule.summary.effectiveRateOfReturn;
                                    } else {
                                        effectiveRateOfReturn = null;
                                    }
                                }
                            }
                        }
                    } 
                    catch (Exception innerEx) {
                        responseWrapperObj = new CreateFinanceResponseWrapper();
                        if (responseWrapperObj.returnStatus == null) {
                            responseWrapperObj.returnStatus = new CreateFinanceResponseWrapper.ReturnStatus();
                            }
                        responseWrapperObj.returnStatus.returnCode = '404';
                        responseWrapperObj.returnStatus.returnText = 'Error parsing response: ' + innerEx.getMessage() + innerEx.getStackTraceString();
                    }
                } 

                apiResponse = apiResponse != '' ? apiResponse : resp.getBody();
                //If not 200 >> only print code in status field
                //insert Integration Det rec >> 
                integrationDetail.Calling_Source__c = wrapper.type;
                integrationDetail.Request_JSON__c = (String.isNotBlank(respWrapper.payload) && respWrapper.payload.length() > 131071) ? respWrapper.payload.substring(0, 131071) : respWrapper.payload;
                integrationDetail.Response_JSON__c = (resp.getBody() != null && resp.getBody().length() > 131071) ? resp.getBody().substring(0, 131071) : resp.getBody();
                integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                integrationDetail.Method_Type__c = intSetting.Request_Method__c;
                integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                integrationDetail.Object_Name__c = 'Opportunity';
                integrationDetail.Name = processName;
                integrationDetail.Loan_Application__c = loanId;
                //integrationDetail.Is_Success_Response__c = isSuccessResponse;
                insert integrationDetail;

                if(String.isNotBlank(applicationNo) && effectiveRateOfReturn!=null){
                    loanApplication.LMS_Loan_Reference__c = applicationNo;
                    loanApplication.LMS_Effective_Rate_of_Return__c = String.valueOf(effectiveRateOfReturn);
                    Update loanApplication;
                } 
            }
            
        return responseWrapperObj;

         } catch (Exception e) {
              System.debug('CreateFinanceAHLController->initiateAPIRequest ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
             Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'CreateFinance', '', '') });
             throw new AuraHandledException('issue in initiate API Create FInance request');
         }
    }

    private static HTTPResponse executeRESTAPIRequest(Map<String, String> integrationRequestMap) { //using SanctionLetterController's method >> in case it remains same. only use its instance
        try {
            System.debug('integrationRequestMap >>>>>'+integrationRequestMap);
            System.debug('1'+integrationRequestMap.get('endpoint'));
            System.debug('2'+integrationRequestMap.get('requestMethod'));
            System.debug('3'+integrationRequestMap.get('Content-Type'));
            System.debug('4'+integrationRequestMap.get('Authorization'));
            System.debug('5'+integrationRequestMap.get('MESSAGEID'));
            System.debug('6'+integrationRequestMap.get('ServiceName'));
            System.debug('7'+integrationRequestMap.get('ENTITYID'));
            System.debug('8'+integrationRequestMap.get('requestJSON'));
            HttpRequest request = new HttpRequest();
            Http http = new Http();
            // Set Headers endpoint and method
            request.setTimeout(120000);
            request.setEndpoint(integrationRequestMap.get('endpoint'));
            request.setMethod(integrationRequestMap.get('requestMethod'));
            request.setHeader('Content-Type', integrationRequestMap.get('Content-Type'));
            request.setHeader('Authorization', integrationRequestMap.get('Authorization'));
            //request.setHeader('Cookie', integrationRequestMap.get('Cookie'));
            request.setHeader('MESSAGEID', integrationRequestMap.get('MESSAGEID'));
            request.setHeader('Language', 'ENG');
            request.setHeader('ServiceName', integrationRequestMap.get('ServiceName'));
            request.setHeader('ENTITYID', integrationRequestMap.get('ENTITYID'));
            request.setHeader('ServiceVersion', '1');
            request.setHeader('RequestTime', Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss'));
            //set bodyy
            if(!Test.isRunningTest()) {
            request.setBody(integrationRequestMap.get('requestJSON'));
            }
            HttpResponse response = http.send(request);
            

            return response;
        } 
        catch (Exception e) {
            System.debug('API Call Failed: ' + e.getMessage());
            //throw new AuraHandledException('API Call Failed: ' + e.getMessage());
            throw e;
        }
    }
}