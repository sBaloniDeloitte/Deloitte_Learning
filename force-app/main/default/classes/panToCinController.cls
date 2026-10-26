public with sharing class panToCinController implements DynamicInvoker {
    @AuraEnabled
    public static String createInputMap(Id loanId, String processName, String appId) {
        System.debug('inside createInputMap');
        System.debug('loanId: '+loanId);
        System.debug('processName: '+processName);
        System.debug('appId: '+appId);
        try {
            Map<String, String> inputMap = new Map<String, String>();
            inputMap.put('recordId', loanId); 
            inputMap.put('processName', processName); 
            inputMap.put('applicantId', appId);
            if(loanId != null && appId!= null){
                List<Application_Applicant__c> appLists = [SELECT Id, PAN_Number__c FROM Application_Applicant__c WHERE Id = :appId AND Loan_Application__c = :loanId];
                if(!appLists.isEmpty() && appLists[0].PAN_Number__c != null){
                    System.debug('pan found'+appLists[0].PAN_Number__c);
                    inputMap.put('pan', appLists[0].PAN_Number__c);
                }
                
            }
            // inputMap.put('pan', 'BTQPP1549D');

            return initiatePanToCin(inputMap);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String initiatePanToCin(Map<String, String> inputMap) {
        System.debug('inside initiatePanToCin');
        String resultMessage = 'Building in progress'; // for bypass
        String loanId = inputMap.get('recordId');
        String processName = inputMap.get('processName');
        String pan = inputMap.get('pan');
        String appId = inputMap.get('applicantId');
        // List<Application_Applicant__c> applicantDetails = [SELECT Id, Name, Voter_ID_Number__c FROM Application_Applicant__c WHERE Id = :appId AND Loan_Application__c = :loanId];
        // Integration_Master__mdt metadata = [SELECT 
        //                                         Process_Name__c,
        //                                         Handler_Class__c,
        //                                         Endpoint__c,
        //                                         Request_Method__c,
        //                                         Client_Id__c,
        //                                         Client_Secret__c,
        //                                         Allowed_Retry__c,
        //                                         Gestation_Period__c,
        //                                         Refresh_Allowed__c,
        //                                         Activity_Name__c
        //                                     FROM Integration_Master__mdt 
        //                                     WHERE Activity_Name__c = :processName LIMIT 1];

        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.recordId = appId;
        wrapper.loanApplicationId = loanId;
        wrapper.type = processName;
        /* wrapper.endpoint = metadata.Endpoint__c;
        wrapper.requestMethod = metadata.Request_Method__c;
        wrapper.clientId = metadata.Client_Id__c;
        wrapper.clientSecret = metadata.Client_Secret__c;
        wrapper.allowedRetry = metadata.Allowed_Retry__c;
        wrapper.gestationPeriod = metadata.Gestation_Period__c;
        wrapper.activityname = metadata.Activity_Name__c;
        wrapper.refreshallowed = metadata.Refresh_Allowed__c;
        wrapper.handlername =  metadata.Handler_Class__c; */
        // wrapper.voterId = applicantDetails[0].Voter_ID_Number__c;
        System.debug('wrapper panToCinController --> '+wrapper);
        intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
        System.debug('respWrapper panToCinController-->' + respWrapper);
        // List<Integration_Settings__c> intSettingList = [
        //         SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c 
        //         FROM Integration_Settings__c 
        //         WHERE Name = 'Loan PAN To CIN' LIMIT 1
        //     ];
        //     Integration_Settings__c intSetting = intSettingList[0];
        //     System.debug('respWrapper.prerequisiteError --> '+respWrapper.prerequisiteError);
        //     System.debug('respWrapper.prerequisiteError '+respWrapper.prerequisiteError);

        Map<String,String> integrationRequestMap = new Map<String,String>();
        integrationRequestMap.put('intSettingName','Loan PAN To CIN');
        integrationRequestMap.put('requestJSON',respWrapper.payload);
        String bearer=Utility.getAccessToken();
        System.debug('bearer panToCinController ----'+bearer);
        integrationRequestMap.put('bearer',bearer);
        System.debug('integrationRequestMap panToCinController--> '+integrationRequestMap);
        HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
        if(resp != null) {
            System.debug('resp panToCinController'+resp);
            System.debug('resp Status panToCinController'+resp.getStatusCode());
            System.debug('resp Body panToCinController'+resp.getBody());
        }

        Integration_Details__c inteDetails = new Integration_Details__c();
        inteDetails.Name = processName;
        inteDetails.Loan_Application__c = loanId;
        inteDetails.Related_Record_Id__c = appId;
        inteDetails.Object_Name__c = 'Application_Applicant__c';
        inteDetails.Is_Success_Response__c = true; 
        inteDetails.Endpoint__c = 'https://uat-ss-sf.godrejcapital.com/karza/v2/cinlookup';
        insert inteDetails;
        return resultMessage;
        
    }

    public String invokeMethod(String loanId, String appId, String activityName) {
        return createInputMap(loanId, activityName, appId);
    }

}