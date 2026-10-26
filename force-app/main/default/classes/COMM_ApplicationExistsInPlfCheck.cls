public class COMM_ApplicationExistsInPlfCheck {

    public class ExistingApplicationCalloutInput {
        @InvocableVariable(label='applicationNo' required=true)
        public String applicationNo;
    }

    public class ExistingApplicationCalloutOutput {
        @InvocableVariable(label='Response Body')
        public String responseBody;
    }

    @InvocableMethod(label='Initiate checkIfLanExistsForAppNo API Callout')
    public static List<ExistingApplicationCalloutOutput> initiateFlowCallout(List<ExistingApplicationCalloutInput> inputList) {
        List<ExistingApplicationCalloutOutput> outputResList = new List<ExistingApplicationCalloutOutput>();
        if (inputList == null || inputList.isEmpty()) {
            return outputResList;
        }
        Map<String, String> inputMap = new Map<String, String>();
        for (ExistingApplicationCalloutInput input : inputList) {
            ExistingApplicationCalloutOutput output = new ExistingApplicationCalloutOutput();
            if (String.isNotBlank(input.applicationNo)) {
                inputMap.put('applicationNo', input.applicationNo);
            }
            if(inputMap!=null && inputMap.containsKey('applicationNo')){
                String respBody = initiateRequest(inputMap);
                System.debug('respBody>>'+ respBody);
                output.responseBody = respBody;
                outputResList.add(output);
            }
        }
        return outputResList;
    }

    public static String initiateRequest(Map<String,String> inputMap){
        try{
            Integration_Master__mdt metadata = [
                SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, Client_Id__c, 
                Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, Refresh_Allowed__c, Activity_Name__c
                FROM Integration_Master__mdt 
                WHERE Activity_Name__c = 'Existing Application' 
                LIMIT 1
            ];  
            if(metadata == null) {
                throw new AuraHandledException('Error: No metadata found for the given process.');
            }
            Http http = new Http();
            HttpRequest httpReq = new  HttpRequest();
            String bearer = Utility.getAccessToken();
            System.debug('Token:::'+bearer);
            String endpoint = metadata.Endpoint__c;
            httpReq.setEndpoint( endpoint );
            httpReq.setMethod( 'POST' );
            httpReq.setHeader( 'Content-Type', 'application/json' );
            httpReq.setHeader('Authorization','Bearer '+bearer);
            Map<String,List<String>> jsonPlusErrorMap = createRequestJson(inputMap);
            List<String> payload = jsonPlusErrorMap.get('json');
            System.debug('Payload:::'+payload);
            String finReference = '';
            String effRateOfReturnStr = '';
            HttpResponse httpRes;
            Map<String, String> remarksToPaymentMap = new Map<String, String>(); //added by Kunal Bisht for SFHL-1959
            if(String.isNotBlank(payload[0])){
                httpReq.setBody(payload[0]);
                //httpReq.setTimeout(100000);
                httpRes = http.send( httpReq );
                System.debug('resp'+httpRes.getBody());
                if(httpRes.getStatusCode() == 200){
                    finReference+= 'finReference:';
                    Map<String, Object> node = (Map<String, Object>) JSON.deserializeUntyped(httpRes.getBody());
                    List<Object> dataList = (List<Object>) node.get('data');
                    if (dataList != null && !dataList.isEmpty()) {
                        Map<String, Object> firstNodeAttach = (Map<String, Object>) dataList[0];
                        String frResp =  (String) firstNodeAttach.get('finreference'); 
                        if (String.isNotBlank(frResp) && frResp.toLowerCase() != 'null') {
                            frResp = frResp.trim();
                            while (frResp.startsWith(':')) {
                                frResp = frResp.substring(1).trim();
                            }
                            finReference += frResp;
                        }
                        Object effObj = firstNodeAttach.get('effectiverateofreturn');
                        if (effObj != null) {
                            effRateOfReturnStr = String.valueOf((Decimal) effObj);   
                        }
                        //Armann : attaching it to the string so I could easily fetch in flow response.
                        //added by Kunal Bisht for SFHL-1959 - start
                        List<Object> qdpList = (List<Object>) firstNodeAttach.get('qdp');
                        
                        if (qdpList != null) {
                            for (Object qdpObj : qdpList) {
                                Map<String, Object> qdpMap = (Map<String, Object>) qdpObj;
                            
                                String remarks = (String) qdpMap.get('remarks');
                                String paymentId = String.valueOf(qdpMap.get('paymentid'));
                            
                                if (String.isNotBlank(remarks)) {
                                    remarksToPaymentMap.put(remarks, paymentId);
                                }
                            }
                        }
                        
                        if (!remarksToPaymentMap.isEmpty()) {
                        
                            List<Loan_Transaction__c> loanTxnsToUpdate = new List<Loan_Transaction__c>();
                        
                            for (String txnId : remarksToPaymentMap.keySet()) {
                                loanTxnsToUpdate.add(new Loan_Transaction__c(
                                    Id = txnId,
                                    Payment_Ext_Id__c = remarksToPaymentMap.get(txnId),
                                    QDP_Status__c = 'Print'
                                ));
                            }
                        
                            if (!loanTxnsToUpdate.isEmpty()) {
                                update loanTxnsToUpdate;
                            }
                        }
                        //added by Kunal Bisht for SFHL-1959 - end
                    }
                }
            }
            Id applicationId = [SELECT Id,Name FROM Opportunity WHERE Name = :inputMap.get('applicationNo')].Id;  // Armann : this will throw an error if the Id and Name mismatchess.. lets see
            Integration_Details__c integration = new Integration_Details__c();
            integration.Name = 'Existing Application Check';
            integration.Process_Name__c ='Existing Application';
            integration.Object_Name__c='Loan Application';
            integration.Endpoint__c = endpoint; 
            integration.Loan_Application__c =  applicationId;
            integration.Communication_Status__c = 'Published';
            integration.Request_JSON__c = payload[0];
            integration.Response_JSON__c = httpRes!=null && httpRes.getBody() !=null ? httpRes.getBody() :'';
            List<Integration_Details__c> integrationList = new List<Integration_Details__c>{integration};
            insert integrationList;
        
            String finRefVal = '';
            if (String.isNotBlank(finReference) && finReference.contains(':')) {
                List<String> parts = finReference.split(':');
                if (parts.size() > 1) {
                    finRefVal = parts[1];
                }
            }

            if (String.isNotBlank(finRefVal)) {
                List<Loan_Transaction__c> transactionObj = [SELECT Id,Quick_Disbursement__c,Loan_Application__c,RecordType.Name,RecordTypeId FROM Loan_Transaction__c WHERE Loan_Application__c=:applicationId AND RecordType.Name = 'Transaction Details' LIMIT 1 ];
                List<Opportunity> oppList = [SELECT Id,Name,LMS_Loan_Reference__c,LMS_Effective_Rate_of_Return__c FROM Opportunity WHERE Id =:applicationId];
                if(!oppList.isEmpty()){
                    if(String.isBlank(oppList[0].LMS_Loan_Reference__c)){
                        if(transactionObj[0].Quick_Disbursement__c == false){
                            oppList[0].Sub_stage__c = 'Disbursed';
                        }
                        //added by Kunal Bisht for SFHL-1959 - start
                        else if(transactionObj[0].Quick_Disbursement__c && !remarksToPaymentMap.isEmpty()){
                            oppList[0].Sub_stage__c = 'Ops Author';
                        }
                        //added by Kunal Bisht for SFHL-1959 - end
                        oppList[0].LMS_Loan_Reference__c = finRefVal;
                        oppList[0].LMS_Effective_Rate_of_Return__c = String.isNotBlank(effRateOfReturnStr) ? effRateOfReturnStr : '';
                        update oppList;
                    }
                }
            }
            System.debug('finRef'+ finReference);
            return String.isNotBlank(finReference) ? finReference : httpRes.getBody();
        }
        catch(Exception e){
            System.debug('COMM_ApplicationExistsInPlfCheck->initiateRequest ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString() + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static Map<String, List<String>> createRequestJson(Map<String, String> inputMap) {
        applicationRequestWrapper request = new applicationRequestWrapper();
        request.applicationNo = inputMap.containsKey('applicationNo') ? inputMap.get('applicationNo') : '';
        request.entity = 'GHF';
        return new Map<String, List<String>> {'json' => new List<String> { JSON.serialize(request) }};
    }


    public class applicationRequestWrapper{
        public String applicationNo;
        public String entity; //GHF
    }
    public static applicationRequestWrapper parse(String json){
        return (applicationRequestWrapper) System.JSON.deserialize(json, applicationRequestWrapper.class);
    }
}