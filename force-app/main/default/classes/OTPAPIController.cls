public with sharing class OTPAPIController {
    @AuraEnabled
    public static String initiateGenerateOTPValidation(Map<String, String> inputMap) {
        String resultMessage; // for bypass
        // String loanId = inputMap.get('recordId');
        //System.debug('inputMap --> '+inputMap);
        // String resultMessage;)
        String processName = inputMap.get('processName');
        String sObjId = inputMap.get('sObjId');
        //System.debug('sObjId --> '+sObjId);
        Schema.SObjectType sObjType = Id.valueOf(sObjId).getSObjectType();
        //System.debug('sObjType --> '+sObjType);
        String sObjName = sObjType.getDescribe().getName();
        String fieldSet;
        if(sObjName == 'Application_Applicant__c'){
            fieldSet = 'Id, Name, Salutation__c,Mobile_Number__c, Email__c,First_Name__c, Last_Name__c,Applicant_Name__c';
        }
        else if(sObjName == 'Lead'){
            fieldSet = 'Id, Salutation, MobilePhone, Email, FirstName, LastName';
        }
        // List<Application_Applicant__c> applicantDetails = [SELECT Id, Name, Voter_ID_Number__c FROM Application_Applicant__c WHERE Id = :appId AND Loan_Application__c = :loanId];
        /*Integration_Master__mdt metadata = [SELECT 
                                                Process_Name__c,
                                                Handler_Class__c,
                                                Endpoint__c,
                                                Request_Method__c,
                                                Client_Id__c,
                                                Client_Secret__c,
                                                Allowed_Retry__c,
                                                Gestation_Period__c,
                                                Refresh_Allowed__c,
                                                Activity_Name__c
                                            FROM Integration_Master__mdt 
                                            WHERE Activity_Name__c = :processName LIMIT 1];*/

        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        system.debug('wrapper>>'+wrapper);
        system.debug('debug>>'+wrapper.type);
        wrapper.recordId = sObjId;
        // wrapper.loanApplicationId = loanId;
        wrapper.type = processName;
        /*wrapper.endpoint = metadata.Endpoint__c;
        wrapper.requestMethod = metadata.Request_Method__c;
        wrapper.clientId = metadata.Client_Id__c;
        wrapper.clientSecret = metadata.Client_Secret__c;
        wrapper.allowedRetry = metadata.Allowed_Retry__c;
        wrapper.gestationPeriod = metadata.Gestation_Period__c;
        wrapper.activityname = metadata.Activity_Name__c;
        wrapper.refreshallowed = metadata.Refresh_Allowed__c;
        wrapper.handlername =  metadata.Handler_Class__c;*/
        wrapper.fieldSet = fieldSet;
        wrapper.objectName = sObjName;
        // wrapper.otp = otp;
        //System.debug('wrapper initiateGenerateOTPValidation--> '+wrapper);
        intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
        //System.debug('respWrapper initiateGenerateOTPValidation-->' + respWrapper);
        /* List<Integration_Settings__c> intSettingList = [
                SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c 
                FROM Integration_Settings__c 
                WHERE Name = 'Loan Generate OTP' LIMIT 1
            ];
            Integration_Settings__c intSetting = intSettingList[0];
            System.debug('respWrapper.prerequisiteError --> '+respWrapper.prerequisiteError);
            System.debug('respWrapper.prerequisiteError '+respWrapper.prerequisiteError); */

        Map<String,String> integrationRequestMap = new Map<String,String>();
        integrationRequestMap.put('intSettingName','Loan Generate OTP');
        integrationRequestMap.put('requestJSON',respWrapper.payload);
        String bearer=Utility.getAccessToken();
        //System.debug('bearer----'+bearer);
        integrationRequestMap.put('bearer',bearer);
        System.debug('integrationRequestMap --> '+integrationRequestMap);
        HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
        if(resp != null) {
            System.debug('resp '+resp);
            System.debug('resp Status '+resp.getStatusCode());
            System.debug('resp Body '+resp.getBody());
            resultMessage = resp.getBody();
           
        } else {
            resultMessage = 'Building in progress';
        }
        return resultMessage;
    }

    @AuraEnabled
    public static String initiateOTPValidation(Map<String, String> inputMap) {
        String resultMessage; // for bypass
        String loanId = inputMap.get('recordId');
        String processName = inputMap.get('processName');
        String appId = inputMap.get('applicantId');
        String otp = inputMap.get('generatedOTP');
        //List<Application_Applicant__c> applicantDetails = [SELECT Id, Name, Voter_ID_Number__c FROM Application_Applicant__c WHERE Id = :appId AND Loan_Application__c = :loanId];
        /*Integration_Master__mdt metadata = [SELECT 
                                                Process_Name__c,
                                                Handler_Class__c,
                                                Endpoint__c,
                                                Request_Method__c,
                                                Client_Id__c,
                                                Client_Secret__c,
                                                Allowed_Retry__c,
                                                Gestation_Period__c,
                                                Refresh_Allowed__c,
                                                Activity_Name__c
                                            FROM Integration_Master__mdt 
                                            WHERE Activity_Name__c = :processName LIMIT 1];*/

        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.recordId = appId;
        wrapper.loanApplicationId = loanId;
        wrapper.type = processName;
        /*wrapper.endpoint = metadata.Endpoint__c;
        wrapper.requestMethod = metadata.Request_Method__c;
        wrapper.clientId = metadata.Client_Id__c;
        wrapper.clientSecret = metadata.Client_Secret__c;
        wrapper.allowedRetry = metadata.Allowed_Retry__c;
        wrapper.gestationPeriod = metadata.Gestation_Period__c;
        wrapper.activityname = metadata.Activity_Name__c;
        wrapper.refreshallowed = metadata.Refresh_Allowed__c;
        wrapper.handlername =  metadata.Handler_Class__c;*/
        wrapper.otp = otp;
        //System.debug('wrapper --> '+wrapper);
        intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
        //System.debug('respWrapper -->' + respWrapper);
        // List<Integration_Settings__c> intSettingList = [
        //         SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c 
        //         FROM Integration_Settings__c 
        //         WHERE Name = 'Loan Generate OTP' LIMIT 1
        //     ];
        //     Integration_Settings__c intSetting = intSettingList[0];
        //     System.debug('respWrapper.prerequisiteError --> '+respWrapper.prerequisiteError);

        //System.debug('respWrapper.payload '+respWrapper.payload);

        Map<String,String> integrationRequestMap = new Map<String,String>();
        integrationRequestMap.put('intSettingName','Loan Validate OTP');
        integrationRequestMap.put('requestJSON',respWrapper.payload);
        String bearer=Utility.getAccessToken();
        //System.debug('bearer----'+bearer);
        integrationRequestMap.put('bearer',bearer);
        //System.debug('integrationRequestMap --> '+integrationRequestMap);
        HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
        if(resp != null) {
            //System.debug('resp '+resp);
            //System.debug('resp Status '+resp.getStatusCode());
            //System.debug('resp Body '+resp.getBody());
            resultMessage = resp.getBody();
            
        } else {
            resultMessage = 'Building in progress';
            
        }
        return resultMessage;
       
    }
}