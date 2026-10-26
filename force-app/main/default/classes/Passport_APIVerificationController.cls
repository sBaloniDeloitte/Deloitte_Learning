public with sharing class Passport_APIVerificationController implements DynamicInvoker {
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
            inputMap.put('applicantId', appId);

            return initiatePassportValidation(inputMap);
        // } catch (Exception e) {
        //     throw new AuraHandledException(e.getMessage());
        // }
    }
    @AuraEnabled
    public static String initiatePassportValidation(Map<String, String> inputMap) {
        String resultMessage; // = 'Building in progress';
        String loanId = inputMap.get('recordId');
        String processName = inputMap.get('processName');
        String appId = inputMap.get('applicantId');
        Map<String,API_Exceptions__mdt> allMetaData = API_Exceptions__mdt.getAll();
        List<Application_Applicant__c> applicantDetails = [SELECT Id, Name, Voter_ID_Number__c FROM Application_Applicant__c WHERE Id = :appId AND Loan_Application__c = :loanId];
        Integration_Master__mdt metadata = [SELECT 
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
                                            WHERE Activity_Name__c = :processName LIMIT 1];

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
        wrapper.handlername =  metadata.Handler_Class__c;
        // wrapper.voterId = applicantDetails[0].Voter_ID_Number__c;
        System.debug('wrapper --> '+wrapper);
        intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
        System.debug('respWrapper -->' + respWrapper);
        List<Integration_Settings__c> intSettingList = [
                SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c 
                FROM Integration_Settings__c 
                WHERE Name = 'Loan Passport Verification' LIMIT 1
            ];
            Integration_Settings__c intSetting = intSettingList[0];
            System.debug('respWrapper.prerequisiteError --> '+respWrapper.prerequisiteError);
            System.debug('respWrapper.prerequisiteError '+respWrapper.prerequisiteError);

        Map<String,String> integrationRequestMap = new Map<String,String>();
        integrationRequestMap.put('intSettingName','Loan Passport Verification');
        integrationRequestMap.put('requestJSON',respWrapper.payload);
        String bearer=Utility.getAccessToken();
        System.debug('bearer----'+bearer);
        integrationRequestMap.put('bearer',bearer);
        System.debug('integrationRequestMap --> '+integrationRequestMap);
        HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
        if(resp != null) {
            System.debug('resp '+resp);
            System.debug('resp Status '+resp.getStatusCode());
            System.debug('resp Body '+resp.getBody());
            String jsonResp = resp.getBody();
			PassportRespWrapper passportResp = (PassportRespWrapper) JSON.deserialize(jsonResp, PassportRespWrapper.class);
            System.debug('passportResp: '+passportResp);
            System.debug('passportResp.statusCode: '+passportResp.statusCode);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            integrationDetail.Calling_Source__c = wrapper.type; 
            integrationDetail.Request_JSON__c = respWrapper.payload; 
            integrationDetail.Response_JSON__c = JSON.serialize(resp.getBody()); 
            integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
            integrationDetail.Method_Type__c = 'POST'; 
            integrationDetail.EndPoint__c = intSetting.Endpoint__c; 
            integrationDetail.Object_Name__c = 'Application_Applicant__c';
            integrationDetail.Name = processName; 
            integrationDetail.Loan_Application__c = loanid;
            integrationDetail.Related_Record_Id__c = appId;
            if (String.valueof(passportResp.statusCode) == '101') {
                integrationDetail.Is_Success_Response__c = true;
            }
            insert integrationDetail;
			
            if (String.valueof(passportResp.statusCode) == '101') {
                List<Triangulation_Data__c> triangulationDatas = [SELECT Id, Loan_Application__c, Application_Applicant__c, Name__c, Father__c, Date_Of_Birth__c, 
                                                                    Passport__c, Date_Of_Issue__c FROM Triangulation_Data__c WHERE Loan_Application__c = :loanId 
                                                                    AND Application_Applicant__c = :appId AND Source_Type__c = 'Validation API' AND Document_Type__c = 'Passport Back'];
    
                if (passportResp != null && passportResp.result != null) {
                    String passportNumber = passportResp.result.passportNumber.passportNumberFromSource != null ? passportResp.result.passportNumber.passportNumberFromSource : null;
                    System.debug('passportNumber--> '+passportNumber);
                    String applicationDate = passportResp.result.applicationDate;
                    System.debug('applicationDate--> '+applicationDate);
                    String dateOfIssue = passportResp.result.dateOfIssue != null ? passportResp.result.dateOfIssue.dispatchedOnFromSource : null;
                    String name = passportResp.result.name != null ? passportResp.result.name.nameFromPassport + ' ' + passportResp.result.name.surnameFromPassport : null;
                    System.debug('name--> '+name);
    
                    if (!triangulationDatas.isEmpty()) {
                        Triangulation_Data__c data = triangulationDatas[0];
    
                        if (passportNumber != null) data.Passport__c = passportNumber;
                        if (dateOfIssue != null) data.Date_Of_Issue__c = dateOfIssue;
                        if (name != null) data.Name__c = name;
    
                        update data;
                    } else {
                        Triangulation_Data__c newData = new Triangulation_Data__c();
                        newData.Application_Applicant__c = appId;
                        newData.Loan_Application__c = loanId;
                        newData.Source_Type__c = 'Validation API';
                        newData.Document_Type__c = 'Passport Back';
    
                        if (passportNumber != null) newData.Passport__c = passportNumber;
                        if (dateOfIssue != null) newData.Date_Of_Issue__c = dateOfIssue;
                        if (name != null) newData.Name__c = name;
    
                        insert newData;
                    }
                }
                resultMessage = 'Success';
            } else {
                for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                    if(execeptionMeta.Error_Code__c == String.valueOf(passportResp.statusCode)){
                        resultMessage = 'Error: ' + execeptionMeta.Error_Message__c;
                        
                    }
                }
            }
        }
        return resultMessage;
    }

    public class PassportRespWrapper {
        public Result result;
        public String requestId;
        public Integer statusCode;
        public ClientData clientData;
    }
    
    public class Result {
        public PassportNumber passportNumber;
        public String applicationDate;
        public String typeOfApplication;
        public DateOfIssue dateOfIssue;
        public Name name;
    }
    
    public class PassportNumber {
        public String passportNumberFromSource;
        public Boolean passportNumberMatch;
    }
    
    public class DateOfIssue {
        public String dispatchedOnFromSource;
        public Boolean dateOfIssueMatch;
    }
    
    public class Name {
        public Decimal nameScore;
        public Boolean nameMatch;
        public String surnameFromPassport;
        public String nameFromPassport;
    }
    
    public class ClientData {
        public String caseId;
    }
    
    

    public String invokeMethod(String loanId, String appId, String activityName) {
        return createInputMap(loanId, activityName, appId);
    }

}