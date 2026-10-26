public with sharing class COMM_MNRLController {

    public class APIResponseWrapper {
        @AuraEnabled public Boolean isBlacklisted;
        @AuraEnabled public String message;
        @AuraEnabled public String error; // optional field for error details
    }

    @AuraEnabled
    public static APIResponseWrapper initiateAPIRequest(Map<String, String> inputMap) {
        APIResponseWrapper apiResponse = new APIResponseWrapper();
        apiResponse.isBlacklisted = false;
        apiResponse.message = '';
        apiResponse.error = '';

        try {
            System.debug('Input Map: ' + inputMap);
            String mobNumber = inputMap.get('mobNumber');
            String processName = inputMap.get('processName');
            String loanApplicationId = inputMap.get('loanApplicationId');
            String applicantId = inputMap.get('applicantId');

            // Fetch Integration Master Metadata
            Integration_Master__mdt metadata = [
                SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c,
                       Client_Id__c, Client_Secret__c, Allowed_Retry__c, Gestation_Period__c,
                       Refresh_Allowed__c, Activity_Name__c
                FROM Integration_Master__mdt
                WHERE Activity_Name__c = :processName
                LIMIT 1
            ];

            // Prepare wrapper for validation
            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
            wrapper.mobNumber = mobNumber;
            wrapper.applicantId = applicantId;
            wrapper.loanApplicationId = loanApplicationId;
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

            // Validate Process
            IntHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);

            // Fetch Integration Settings
            Integration_Settings__c intSetting = [
                SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                FROM Integration_Settings__c
                WHERE Name = 'MNRL Check' LIMIT 1
            ];

            // Prepare Integration Details record
            Integration_Details__c integrationDetail = new Integration_Details__c();
            integrationDetail.Name = processName;
            integrationDetail.EndPoint__c = intSetting.Endpoint__c;
            integrationDetail.Request_JSON__c = respWrapper.payload;

            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = '412';
                integrationDetail.Prerequisite__c = String.join(respWrapper.prerequisiteError, ', ');
                insert integrationDetail;

                apiResponse.message = 'Prerequisite error: ' + String.join(respWrapper.prerequisiteError, ', ');
                apiResponse.error = 'Validation failed before API call';
                return apiResponse;
            }

            // Call external API
            Map<String, String> integrationRequestMap = new Map<String, String>();
            integrationRequestMap.put('intSettingName', 'MNRL Check');
            integrationRequestMap.put('requestJSON', respWrapper.payload);
            String bearer = Utility.getAccessToken();
            integrationRequestMap.put('bearer', bearer);
            HttpResponse resp = Utility.executeAPIRequest(integrationRequestMap);
            String respBody = resp.getBody();
             system.debug('body84--'+respBody);
              system.debug('code--'+resp.getStatusCode());

            integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
            integrationDetail.Response_JSON__c = respBody;
            insert integrationDetail;

             if (resp.getStatusCode() == 200 && String.isNotBlank(respBody)) {
                MNRLResponseWrapper responseWrapper =
                    (MNRLResponseWrapper) JSON.deserialize(respBody, MNRLResponseWrapper.class);
                Application_Applicant__c objApplicant = new Application_Applicant__c();

                if (responseWrapper != null) {
                    System.debug('responseWrapper ---> ' + JSON.serialize(responseWrapper));

                    // --- safe typed access to first entry ---
                  List<cls_Record> records = responseWrapper.records !=null && !responseWrapper.records.isEmpty() ?responseWrapper.records : new List<cls_Record>();

                    apiResponse.isBlacklisted = (responseWrapper.isBlacklisted != null) ? responseWrapper.isBlacklisted : false;
                    apiResponse.message = responseWrapper.isBlacklisted
                        ? 'The mobile number ' + responseWrapper.mobileNo + ' is blacklisted. Reason: ' + (records.size() > 0 ? records[0].disconnectionReasonDescription : '')
                        : 'The mobile number ' + responseWrapper.mobileNo + ' is not blacklisted.';

                    if (String.isNotBlank(applicantId)) {
                        objApplicant.Id = applicantId;
                        objApplicant.Is_MNRL_Blacklisted__c = apiResponse.isBlacklisted;
                        update objApplicant;
                    }
                } else {
                    apiResponse.message = 'Error: Unable to parse response from MNRL service.';
                    apiResponse.error = 'Deserialization returned null or empty records';
                }
            } else {
                apiResponse.message = 'Error: Received status code ' + resp.getStatusCode() + ' from MNRL service.';
                apiResponse.error = respBody;
            }

        } catch (Exception e) {
            System.debug('Error in initiateAPIRequest: ' + e.getMessage());
            apiResponse.message = 'An unexpected error occurred.';
            apiResponse.error = e.getMessage();
        }
        System.debug('Final API Response: ' + JSON.serialize(apiResponse));
        return apiResponse;
    }

     public class MNRLResponseWrapper {
        public Boolean isBlacklisted;
        public cls_Record[] records;
        public String mobileNo;
        public String message;
        public String status;
     }

        public class cls_Record {
            public Integer disconnectionReasonId;
            public String disconnectionReasonDescription;
            public Integer referenceId;
            public String dateOfDisconnection;
        }
    }