public with sharing class FetchMCAController {

    @AuraEnabled
    public static String initiateAPIRequest(Map<String, String> inputMap) {
        String returnResp = '';
        try {
            String loanId = inputMap.get('loanId');
            String cin = inputMap.get('cinNumber'); 
            String applicantId = inputMap.get('applicantId');
            String processName = inputMap.get('processName');

            // Fetch Integration Metadata
            Integration_Master__mdt metadata = [
                SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c,
                    Client_Id__c, Client_Secret__c, Allowed_Retry__c, Gestation_Period__c,
                    Refresh_Allowed__c, Activity_Name__c
                FROM Integration_Master__mdt 
                WHERE Activity_Name__c = :processName 
                LIMIT 1
            ];

            // Prepare request wrapper
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
            wrapper.cin = cin;
            wrapper.applicantId = applicantId;

            // Validate and prepare request
            IntHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);

            // Integration Settings
            Integration_Settings__c intSetting = [
                SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                FROM Integration_Settings__c 
                WHERE Name = 'Loan Applicant MCA' 
                LIMIT 1
            ];

            Integration_Details__c integrationDetail = new Integration_Details__c();

            // Handle prerequisite failure
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = '412';
                integrationDetail.Prerequisite__c = String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                insert integrationDetail;

                returnResp = JSON.serialize(new Map<String, Object>{
                    'status' => 'error',
                    'message' => String.join(respWrapper.prerequisiteError, ', ')
                });
            } 
            else {
                // Prepare API input
                Map<String, String> integrationRequestMap = new Map<String, String>();
                integrationRequestMap.put('intSettingName', 'Loan Applicant MCA');
                integrationRequestMap.put('requestJSON', respWrapper.payload);
                integrationRequestMap.put('bearer', Utility.getAccessToken());

                // Call external API
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                String apiResponse = resp.getBody();

                // Log Integration Details
                integrationDetail.Calling_Source__c = wrapper.type; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 
                integrationDetail.Response_JSON__c = apiResponse;
                integrationDetail.Status__c = String.valueOf(resp.getStatusCode()); 
                integrationDetail.Method_Type__c = intSetting.Request_Method__c; 
                integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.Name = processName; 
                integrationDetail.Related_Record_Id__c = applicantId; 
                integrationDetail.Loan_Application__c = loanId;
                insert integrationDetail;

                if (resp.getStatusCode() == 200 && String.isNotBlank(resp.getBody())) {
                    return apiResponse;
                }
                return '{"status":"error","message":"Invalid or empty response from MCA API"}';
            }
        } catch (Exception e) {
            System.debug('⚠️ Error in initiateAPIRequest: ' + e.getStackTraceString());
            returnResp = JSON.serialize(new Map<String, Object>{
                'status' => 'error',
                'message' => e.getMessage()
            });
        }
        return returnResp;
    }

    @AuraEnabled
    public static String getApplicantsForMCA(String loanId) {
        Map<String, Object> finalResponse = new Map<String, Object>();
        List<Map<String, String>> applicantList = new List<Map<String, String>>();

        try {
            if (String.isBlank(loanId)) {
                finalResponse.put('message', 'Missing Loan Id');
                return JSON.serialize(finalResponse);
            }

            List<Application_Applicant__c> applicants = [
                SELECT Id, Name, Customer_Type__c, Registration_Number__c 
                FROM Application_Applicant__c 
                WHERE Loan_Application__c = :loanId 
                AND Customer_Type__c = 'Non Individual'
            ];

            if (applicants.isEmpty()) {
                finalResponse.put('message', 'No Non-Individual Applicant Found');
                return JSON.serialize(finalResponse);
            }

            for (Application_Applicant__c app : applicants) {
                Map<String, String> appMap = new Map<String, String>{
                    'label' => app.Name,
                    'value' => app.Id,
                    'CIN'   => (app.Registration_Number__c != null ? app.Registration_Number__c : '')
                };
                applicantList.add(appMap);
            }

            finalResponse.put('Applicants', applicantList);
            finalResponse.put('message', 'Applicants Found Successfully');

        } catch (Exception ex) {
            System.debug('⚠️ Error in getApplicantsForMCA: ' + ex.getMessage());
            finalResponse.put('error', ex.getMessage());
        }

        return JSON.serialize(finalResponse);
    }

    @AuraEnabled
    public static String getMCARecords(String loanId, String processName, String applicantId) {
        Map<String, Object> finalResponse = new Map<String, Object>();
        List<ResultWrapper> mcaResults = new List<ResultWrapper>();

        try {
            if (String.isBlank(loanId) || String.isBlank(applicantId)) {
                finalResponse.put('message', 'Missing Loan Id or Applicant Id');
                return JSON.serialize(finalResponse);
            }

            List<Integration_Details__c> integrationRecords = [
                SELECT Id, Name, Response_JSON__c, Related_Record_Id__c, Status__c
                FROM Integration_Details__c
                WHERE Loan_Application__c = :loanId
                AND Related_Record_Id__c = :applicantId
                AND Name = :processName
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if (integrationRecords.isEmpty()) {
                finalResponse.put('message', 'No MCA Record Found for this Applicant');
                return JSON.serialize(finalResponse);
            }

            Integration_Details__c integ = integrationRecords[0];

            if (String.isNotBlank(integ.Response_JSON__c)) {
                MCAResponseWrapper response = parseResponse(integ.Response_JSON__c);
                system.debug('response 175--'+response);
                if (response != null && response.status_code == '101' && integ.Status__c == '200') {
                    if (response.result != null) {
                        mcaResults.addAll(response.result);
                        finalResponse.put('MCA_Result', mcaResults);
                        finalResponse.put('message', 'MCA Data Found Successfully');
                    }
                } else {
                    finalResponse.put('message', 'MCA Data Not Available for this Applicant');
                }
            } else {
                finalResponse.put('message', 'Empty MCA Response for this Applicant');
            }

        } catch (Exception ex) {
            System.debug('⚠️ Error in getMCARecords: ' + ex.getMessage());
            finalResponse.put('error', ex.getMessage());
        }

        return JSON.serialize(finalResponse);
    }

   public class MCAResponseWrapper {
    @AuraEnabled public String status_code { get; set; }
    @AuraEnabled public String request_id { get; set; }
    @AuraEnabled public List<ResultWrapper> result { get; set; }
    @AuraEnabled public ClientDataWrapper clientData { get; set; }
   }

    public class ResultWrapper {
        @AuraEnabled public String date_of_appointment { get; set; }
        @AuraEnabled public String designation { get; set; }
        @AuraEnabled public String dsc_expiry_date { get; set; }
        @AuraEnabled public String address { get; set; }
        @AuraEnabled public String DIN_DPIN_PAN { get; set; }
        @AuraEnabled public String full_name { get; set; }
        @AuraEnabled public String wheather_dsc_registered { get; set; }
    }

    public class ClientDataWrapper {
        @AuraEnabled public String caseId { get; set; }
    }

    // ✅ Safe parser for all response formats
    public static MCAResponseWrapper parseResponse(String jsonString) {
        if (String.isNotBlank(jsonString)) {
            jsonString = jsonString
                .replace('"DIN/DPIN/PAN"', '"DIN_DPIN_PAN"')
                .replace('"status-code"', '"status_code"');

            // --- Step 1: Parse generically ---
            Map<String, Object> rawMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
            MCAResponseWrapper wrapper = new MCAResponseWrapper();
            wrapper.status_code = (String) rawMap.get('status_code');
            wrapper.request_id = (String) rawMap.get('request_id');
            
            // --- Step 2: Handle clientData ---
            if (rawMap.containsKey('clientData')) {
                wrapper.clientData = (ClientDataWrapper) JSON.deserialize(
                    JSON.serialize(rawMap.get('clientData')),
                    ClientDataWrapper.class
                );
            }

            // --- Step 3: Handle result safely ---
            Object resultObj = rawMap.get('result');
            if (resultObj instanceof List<Object>) {
                wrapper.result = (List<ResultWrapper>) JSON.deserialize(
                    JSON.serialize(resultObj),
                    List<ResultWrapper>.class
                );
            } else {
                // if result is {} or null
                wrapper.result = new List<ResultWrapper>();
            }

            return wrapper;
        }
        return null;
    }

}