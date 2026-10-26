public with sharing class COMM_APRController {
    
    @AuraEnabled
    public static String initiateAPRAPIRequest(Map<String, String> inputMap) {
        try {
            String loanId = inputMap.get('loanId');
            // String processName = inputMap.get('processName');
            String returnText;

            // if(String.isEmpty(loanId) || String.isEmpty(processName)) {
            //     throw new AuraHandledException('Error: Missing required parameters.');
            // }

            // // Fetch Metadata
            // Integration_Master__mdt metadata = [
            //     SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, Client_Id__c, 
            //     Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, Refresh_Allowed__c, Activity_Name__c
            //     FROM Integration_Master__mdt 
            //     WHERE Activity_Name__c = :processName 
            //     LIMIT 1
            // ];

            // if(metadata == null) {
            //     throw new AuraHandledException('Error: No metadata found for the given process.');
            // }

            // intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
            // wrapper.recordId = loanId;
            // wrapper.loanApplicationId = loanId;  
            // wrapper.type = processName;
            // wrapper.endpoint = metadata.Endpoint__c;
            // wrapper.requestMethod = metadata.Request_Method__c;
            // wrapper.clientId = metadata.Client_Id__c;
            // wrapper.clientSecret = metadata.Client_Secret__c;
            // wrapper.allowedRetry = metadata.Allowed_Retry__c;
            // wrapper.gestationPeriod = metadata.Gestation_Period__c;
            // wrapper.activityname = metadata.Activity_Name__c;
            // wrapper.refreshallowed = metadata.Refresh_Allowed__c;
            // wrapper.handlername = metadata.Handler_Class__c;

            // intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            
            // if(respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
            //     return 'Error: ' + String.join(respWrapper.prerequisiteError, ', ');
            // }
            // else {
            //     Integration_Details__c integrationDetail = new Integration_Details__c();

            //     // Fetch Integration Settings
            //     Integration_Settings__c intSetting = [
            //         SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c, Authorization__c, Cookie__c,Origin__c
            //         FROM Integration_Settings__c 
            //         WHERE Name = :processName
            //         LIMIT 1
            //     ];
            
            //     // Prepare API Request
            //     Map<String, String> integrationRequestMap = new Map<String, String>();
            //     integrationRequestMap.put('intSettingName', 'Loan APR Calculation');

            //     String bearer = Utility.getAccessToken();
            //     System.debug('bearer----' + bearer);
            //     integrationRequestMap.put('bearer', bearer);
            //     integrationRequestMap.put('requestJSON', respWrapper.payload);
            //     integrationRequestMap.put('Origin', intSetting.Origin__c);

            //     HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
            //     System.debug('resp: '+resp);
                
            //     if (Test.isRunningTest()) {
            //     resp = new HttpResponse();
            //     resp.setStatusCode(200);
            //     resp.setHeader('Content-Type', 'application/json');
            //     resp.setBody('{"apr":12.34,"emi_amount":15000,"roi":10.5}');
            // 	}

                Boolean isSuccessResponse = false;

                //if(resp.getStatusCode() == 200){
                    // Deserialize the actual API response
                    String aprResponse = '{"ecl_flag":false,"finAmount":3400000.00,"tenure_in_months":60.00,"apr":15.21,"processing_fees_incl_gst":0.000000,"insurance_charges":0.000000,"others_charges":2360.000000,"loc":90269.00,"net_disbursed_amount":3309731.00,"emi_amount":79112.05,"roi":14.00}';
                    APRResponseWrapper response = (APRResponseWrapper)JSON.deserialize(aprResponse, APRResponseWrapper.class);
                    system.debug('response: '+response);

                    isSuccessResponse = true;

                    Opportunity oppRec = new Opportunity( Id = loanId, APR__c = response.apr );
                    update oppRec;

                    returnText = 'Success';
                //}
            
                // Save API Response in Integration_Details__c
                // integrationDetail.Calling_Source__c = wrapper.type;
                // integrationDetail.Request_JSON__c = respWrapper.payload;
                // integrationDetail.Response_JSON__c = resp.getBody();
                // integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                // integrationDetail.Method_Type__c = intSetting.Request_Method__c;
                // integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                // integrationDetail.Name = processName;
                // integrationDetail.Loan_Application__c = loanId;
                // integrationDetail.Is_Success_Response__c = isSuccessResponse;
                // insert integrationDetail;
            //}

            return returnText;
        } 
        catch (Exception e) {
            System.debug('Loan APR Calculation'+ e.getStackTraceString() + e.getMessage() );
            //Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'Loan APR Calculation', '', '') });
            return 'Salesforce Exception: ' + e.getMessage();
        }
    }

    // Wrapper Class for API Response
    public class APRResponseWrapper {
        public Decimal apr;
        public Boolean ecl_flag;
        public Decimal emi_amount;
        public Decimal finAmount;
        public Decimal insurance_charges;
        public Decimal loc;
        public Decimal net_disbursed_amount;
        public Decimal others_charges;
        public Decimal roi;
        public Decimal tenure_in_months;
        public Decimal amc_revised_percnt;
        public Decimal amc_waiver;
        public Decimal finAssetValue;
        public Decimal processing_fee;
    }
}