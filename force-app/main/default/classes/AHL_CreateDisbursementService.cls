public class AHL_CreateDisbursementService {
    @future(callout=true)
    public static void callCreateDisbursement(Set<Id> txnIds) {
        String processName = 'Create Disbursement';

        // Fetch Metadata
        Integration_Master__mdt metadata = [
            SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, Client_Id__c, 
                Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, Refresh_Allowed__c, Activity_Name__c
            FROM Integration_Master__mdt 
            WHERE Activity_Name__c = :processName 
            LIMIT 1
        ];

        if(metadata == null) {
            throw new AuraHandledException('Error: No metadata found for the given process.');
        }

        // Fetch Integration Settings
        Integration_Settings__c intSetting = [
                SELECT Id,Name,Authorization__c,Content_Type__c,Cookie__c,Request_Method__c,Message_Id__c,Entity_Id__c,Endpoint__c
                FROM Integration_Settings__c 
                WHERE Name = :processName 
                LIMIT 1
            ];

        try {
            for (Id txn : txnIds) {
                String loanId = txn.toString();    
                
                if(String.isEmpty(loanId) || String.isEmpty(processName)) {
                throw new AuraHandledException('Error: Missing required parameters.');
                }

                intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
                wrapper.recordId = loanId;
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

                intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
                system.debug('respWrapper='+respWrapper);

                Integration_Details__c integrationDetail = new Integration_Details__c();

                CreateDisbursementResponseWrapper responseWrapperObj;

                if(Test.isRunningTest()){
                    respWrapper.payload ='respWrapper.payload';
                }
                String base64StringFromContentVersion = '';
                if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                    integrationDetail.Status__c = String.valueof('412');
                    integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                    integrationDetail.Name = processName;
                    integrationDetail.Object_Name__c = '';
                }
                else {
                    Map<String, String> requestInput = new Map<String, String>();
                    requestInput.put('endPoint', intSetting.Endpoint__c);
                    requestInput.put('serviceName', 'createDisbursementInstructions');
                    requestInput.put('reqBody', respWrapper.payload); 
                    String bearer;
                    if(Test.isRunningTest()){
                        bearer ='12343';
                    }else{
                        bearer = Utility.getAccessToken();
                    }
                    requestInput.put('Authorization', 'Bearer ' + bearer);
                    requestInput.put('Cookie', intSetting.Cookie__c);
                    requestInput.put('MESSAGEID', intSetting.Message_Id__c);
                    requestInput.put('ENTITYID', intSetting.Entity_Id__c); 
                    requestInput.put('Content-Type', intSetting.Content_Type__c);
                    requestInput.put('method', intSetting.Request_Method__c);

                    HTTPResponse resp = executeRESTAPIRequest(requestInput);

                    if(resp != null && resp.getStatusCode() == 200){ //success
                        System.debug('resp.getBody(): '+resp.getBody());
                        try {
                            responseWrapperObj = (CreateDisbursementResponseWrapper) JSON.deserialize(resp.getBody(), CreateDisbursementResponseWrapper.class);
                            if(responseWrapperObj!=NULL){
                                if(responseWrapperObj.returnStatus!=NULL && (String.isNotBlank(responseWrapperObj.returnStatus.returnText))){
                                    if(responseWrapperObj.returnStatus.returnText == 'Success'){
                                        if (responseWrapperObj.disbursements != null) {
                                            System.debug('Disbursements Found: ' + responseWrapperObj.disbursements);
                                            Map<String,Integer> mapDisbursement = new Map<String,Integer>();
                                            for (Disbursements disb : responseWrapperObj.disbursements) {
                                                mapDisbursement.put(disb.remarks, disb.paymentId);
                                            }
                                            List<Loan_Transaction__c> disbursementRecs = [SELECT Id, Name,Payment_Sequence__c,Payment_Ext_Id__c FROM Loan_Transaction__c 
                                                          WHERE Loan_Application__c = :loanId And RecordType.DeveloperName = 'Payment' AND QDP_Status__c = 'New'];

                                            for (Loan_Transaction__c disbRec : disbursementRecs) {
                                                disbRec.Payment_Ext_Id__c = mapDisbursement.containsKey(disbRec.Id) ? mapDisbursement.get(disbRec.Id).toString() : null;
                                            }
                                            update disbursementRecs;
                                        }
                                    }
                                }
                            }
                        } 
                        catch (Exception innerEx) {
                            responseWrapperObj = new CreateDisbursementResponseWrapper();
                            responseWrapperObj.returnStatus.returnCode = '404';
                            responseWrapperObj.returnStatus.returnText = 'Error parsing response: ' + innerEx.getMessage();
                        }
                    } 
                    
                    integrationDetail.Calling_Source__c = wrapper.type;
                    integrationDetail.Request_JSON__c = respWrapper.payload;
                    integrationDetail.Response_JSON__c =  resp.getBody();
                    integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                    integrationDetail.Method_Type__c = intSetting.Request_Method__c;
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                    integrationDetail.Object_Name__c = 'Opportunity';
                    integrationDetail.Name = processName;
                    integrationDetail.Loan_Application__c = loanId;
                    //integrationDetail.Is_Success_Response__c = isSuccessResponse;
                    insert integrationDetail;
                }
           }        
        } 
        catch (Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'AHL_CreateDisbursementService', '', '') });
            throw new AuraHandledException('Error: ' + e.getMessage());
        }

    }

    private static HTTPResponse executeRESTAPIRequest(Map<String, String> integrationInput){ 
          HTTPResponse resp ;
        try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(integrationInput.get('endPoint'));
            request.setMethod(integrationInput.get('method'));
            request.setTimeout(120000);
            request.setHeader('Content-Type', integrationInput.get('Content-Type'));
            request.setHeader('Authorization', integrationInput.get('Authorization'));
            request.setHeader('Cookie', integrationInput.get('Cookie'));
            request.setHeader('MESSAGEID', integrationInput.get('MESSAGEID'));
            request.setHeader('Language', 'ENG');
            request.setHeader('ServiceName', integrationInput.get('serviceName'));
            request.setHeader('ENTITYID', integrationInput.get('ENTITYID'));
            request.setHeader('ServiceVersion', '1');
            request.setHeader('RequestTime', Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss'));
            request.setBody(integrationInput.get('reqBody'));
            System.debug('Executing API Request: ' + integrationInput.get('reqBody'));
            // Send the HTTP request
                if(!Test.isRunningTest()){
					resp= http.send(request);                    
                }else{
                    HttpResponse res = new HttpResponse();
                    res.setHeader('Content-Type','application/json');
                    Map<String,Object> body = new Map<String,Object>();
                    body.put('finReference','GHF1001HL0005309');
                    body.put('returnStatus',new Map< String,String>{'returnCode'=>'009','returnText'=>'Success'});
                    body.put('disbursements',new List<Object>());
                    res.setBody(JSON.serialize(body));
                    res.setStatusCode(200);
                    resp =res;
                }

            System.debug('API Response: ' + resp.getBody());

            return resp;
        } catch (Exception e){
            System.debug('AHL_CreateDisbursementService->executeRESTAPIRequest ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }        
    }

    public class CreateDisbursementResponseWrapper {
       public String finReference;	//GHF1001HL0005309
       public ReturnStatus returnStatus;
       public List<Disbursements> disbursements;
    }

    public class ReturnStatus {
		public String returnCode;	//0000
		public String returnText;	//Success
	}

    public class Disbursements {
        public String disbParty;
        public String disbType;
        public String disbDate;
        public Integer disbAmount;
        public String accountNo;
        public String acHolderName;
        public Integer partnerBankId;
        public String phoneCountryCode;
        public String phoneAreaCode;
        public String phoneNumber;
        public String remarks;
        public String favourName;
        public String payableLoc;
        public String printingLoc;
        public String valueDate;
        public Integer version;
        public Integer paymentId;
        public Integer disbSeq;
        public String issueBank;
	}
}