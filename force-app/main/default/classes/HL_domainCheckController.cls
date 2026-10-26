/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-24-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class HL_domainCheckController implements DynamicInvoker {
    
    @AuraEnabled
    public static String createInputMap(Id loanId, String processName, String appId) {
        System.debug('inside createInputMap');
        System.debug('loanId: '+loanId);
        System.debug('processName: '+processName);
        System.debug('appId: '+appId);
        // try {
            Map<String, String> inputMap = new Map<String, String>();
            inputMap.put('recordId', loanId); 
            inputMap.put('processName', processName); 
            inputMap.put('recordId', appId);
            return initiateAPIRequest(inputMap);
        // } catch (Exception e) {
        //     throw new AuraHandledException(e.getMessage());
        // }
    }
    @AuraEnabled
    public static String initiateAPIRequest(Map<String,String> inputMap) {
        try {
            String loanId = inputMap.get('loanId');
            String processName = inputMap.get('processName');
            String appId = inputMap.get('recordId');
            System.debug('loanId : '+loanId);
            System.debug('appId : '+appId);
            System.debug('processName : '+processName);
            String returnText;
            if(String.isEmpty(loanId) || String.isEmpty(appId)) {
                throw new AuraHandledException('Error: Missing required parameters.');
            }

            // Fetch Metadata
            Integration_Master__mdt metadata = [
                SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, Client_Id__c, 
                Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, Refresh_Allowed__c, Activity_Name__c
                FROM Integration_Master__mdt 
                WHERE Activity_Name__c = :processName 
                LIMIT 1
            ];
           System.debug('metadata : '+metadata);
            if(metadata == null) {
                throw new AuraHandledException('Error: No metadata found for the given process.');
            }

            intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
            wrapper.recordId = appId;
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
            
            if(respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                return 'Error: ' + String.join(respWrapper.prerequisiteError, ', ');
            }
            else {
                Integration_Details__c integrationDetail = new Integration_Details__c();

                // Fetch Integration Settings
                Integration_Settings__c intSetting = [
                    SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c, Authorization__c, Cookie__c
                    FROM Integration_Settings__c 
                    WHERE Name = :processName
                    LIMIT 1
                ];
            
                // Prepare API Request
                Map<String, String> integrationRequestMap = new Map<String, String>();
                integrationRequestMap.put('intSettingName', 'domainCheck');

                String bearer = Utility.getAccessToken();
                System.debug('bearer----' + bearer);
                integrationRequestMap.put('bearer', bearer);
                integrationRequestMap.put('requestJSON', respWrapper.payload);
                //integrationRequestMap.put('Origin', Constants.GHFL_ORIGIN_URL);

                // HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                            //String testPayload = '{"lan":"GFL3001BL0001834","accounts":[{"txnId":"TW4P1744707094286","accountNo":"044205011953"},{"txnId":"TW4P1744707094286","accountNo":"044205011934"},{"txnId":"XGH21742378782690","accountNo":"913020021488624"},{"txnId":"CB6N1674474969259","accountNo":"01432320017524"}]}';
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            // String bearer=Utility.getAccessToken();
            request.setEndpoint('Callout:HL_domainCheck');
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer '+bearer);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Accept', '*/*');
            // request.setHeader('Cookie', 'TS019fc7a5=01c841f7c5ab76d57459b62ba71d76fed1e39db6aeda549b8b219f3733ecc932a075d57df6a4703aa9d24d5e576e352e8a8c4c302e;session=ARAAafyU23bbnHGE8AHl6kH9bxoZE3G-7U15MRpFh4nO-W2cZ75oAAAAAABcBgA65IiKfBiYETBsqcbB6tOqAAAA_Cx9g1RLJIBVeshePagFEgYO2SjlbVfCb-sVRgSjAvvNWvsgG09xRrg9diEvf6jFu7U-6c7Li5BsfCjnIewv7s__MD8aV093gHY-R1XR42eUDanDIlMbhLaCK-ycMYb2kqSABZsrP1SJJpd-Maz5xjh0Rwn27hNQ_1yHcJwcn89lwAcpaqWSOKjjLonWgsNvVXPu_tXpM46neD6_HqW_lMWvoODqHleYGJRcoR1q1pYaICIQ_ie1ZpNEX54yt0h9UaJbKW-o-5nYQkDXCoPe1dvjResJ020ldZXuZJV7bapvXp5cH8TNisBBgl73iD6f7nfDpC8BiQfdWsQfhFZWzH17QqvoshXjQU7lcQn7AEaq9IJ9Vi2vKMyZ860c-NZ_Gh1YWacsR6Ziys6dhHRuXHNFCMQz0QhwwzFfA_5XaxYWDbVfIydfx6-Xrnp2ptJCmvLUyFp9doeMW3P3OT7aDbxT0hABF2tMiAD9X3Lp9WrpQllOkNTRpt97iIx9OuaglTusooewleApNIfeCwjsgML2CJqQCc4musmyYIdz0lrUW2enTjwKMo5kA6EBpriKTbxeMMBR7mGthiahJ4Y-au1peIMTHXpUD36dU964Cu1lATwcOddHcUq2NuSeSVFvdwxhHzb1deTHSAJwtaU-nsQVAdHOuh6F375FOZtXUB1x5XIAOyU5pFA7ExM3abQHAZb31Z9rJ2sJeAv3NBBkWvfQnvdkEAehxZCStzjFGdubktidEfKJwxd41XPsao_BXuL3ZULRYjI5L_8AcT4rvbuGQGhPn6Kp0zTGrf46dbzJUSFdrdEjsaZ9yjli0CFlDM2hTrAUXQUDFEjj2CvOSKm9pBBxFaox3ncz7Jfa1hgiUNySAz0nOuGLlWSi7k3cXJjG4ckV6wP6iXFDnwkkU3dc4euV4va6p1cvJOAfFNLgXzzt_x5AxEGICt9O_3-qELVA1BWGkrFMpfsIYc_qlCQRX0QqFT2R_E9r_X6UxOZYJsD8hNYssg3oN0xLBj8ohisAYBfxAjxf6gha41f8UpMCJhLIstINuR_w2yvJxk147L46Y4Hyksp9bg8RBPi8AVE_wMyORHUTq_p9l5sdx1OL98PGik4_OZzIMrbzsSKy5AHSZOOzU1cfW1Xjzhq4J989c5cgM3iVhhjh0Vdy9bX2ZbW6TNiutIA9iQP2UVtGkL9ZIxluQOIgthgZmpSMHpS1OgJ-V_5dmtKuw2TOQGHHJ5tCSR_7-hBihsNhkKsMJJClHc5kTtLSJQp0NfGbFDEdPeedlF2_PUrItKFHcOo0bAi6cZBp2aTuhfgTDtPJhhxCOWmfWKAkxPePFg_9b68MGKWpVeLfK6l3vMVhYflr-ZD-GX5h0fe7c0PK0582vZsCJN6sfvNtMAMAGLu1ctmF3BMYJq4SQehZeQ3BbEQT4vyj2cF5Py6WfMULY2q2_TE-D5P0UJM0ktoOx8-9tdi6vf9--vwXxaI1HrLCravXHc3equn-v90mRnihOoFZmpljWJ5_bb3ltJuwUI78jUqhPSF3p4cRMNv6Mm4nHdzkweRzCXIR-EvIyvHqdApW_DLmm_XkkW1ZUOxchAxuQYYMHNJTrynuclXpLiSys5mdQ4yfX1w0YI1T68LXBiGROHppwF');
            request.setBody(respWrapper.payload);
            System.debug('request body '+respWrapper.payload);
            
            HttpResponse response = http.send(request);
            System.debug('Status Code: ' + response.getStatusCode());
            System.debug('Response Body: ' + response.getBody());
            System.debug('resp: '+response);
                Boolean isSuccessResponse = false;

                if(response.getStatusCode() == 200){
                    // system.debug('response: '+resp);
                    // isSuccessResponse = true;
                    // returnText = 'Success';
                    String responseBody = response.getBody();
                    System.debug('Response Body: ' + responseBody);
                    // Deserialize JSON response into a generic map
                    Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                    // Extract status-code (as String)
                    String statusCode = (String) resultMap.get('status-code');
                    System.debug('status-code: ' + statusCode);
                    // Now check your status code and handle accordingly
                    if (statusCode == '101') {
                        returnText = 'Success';
                        Application_Applicant__c aap = new Application_Applicant__c();
                        aap.Id = appId;
                        aap.Official_Mail_Validity__c = 'Valid';
                        Update aap;
                    }
                    else{
                        returnText = 'Fail';
                        Application_Applicant__c aap = new Application_Applicant__c();
                        aap.Id = appId;
                        aap.Official_Mail_Validity__c = 'Invalid';
                        Update aap;
                    }
                }
                else{
                    returnText = 'Fail';
                }
            
                // Save API Response in Integration_Details__c
                integrationDetail.Calling_Source__c = wrapper.type;
                integrationDetail.Request_JSON__c = respWrapper.payload;
                integrationDetail.Response_JSON__c = response.getBody();
                integrationDetail.Status__c = String.valueOf(response.getStatusCode());
                integrationDetail.Method_Type__c = intSetting.Request_Method__c;
                integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                integrationDetail.Name = processName;
                integrationDetail.Loan_Application__c = loanId;
                integrationDetail.Is_Success_Response__c = isSuccessResponse;
                insert integrationDetail;
            }

            return returnText;
        } 
        catch (Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'Loan Domain Check', '', '') });
            return 'Salesforce Exception: ' + e.getMessage();
        }
    }
        public String invokeMethod(String loanId, String appId, String activityName) {
        return createInputMap(loanId, activityName, appId);
    }

}