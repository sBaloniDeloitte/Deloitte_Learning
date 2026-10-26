public class PANStatusCheckController implements DynamicInvoker{
    static string conLabels = 'PAN_Validation_API';
                         
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }

    public String invokeMethod(String loanId, String appId, String activityName) {
        return createInputMap(loanId, activityName, appId);
    }

    @AuraEnabled
    public static String createInputMap(Id loanId, String processName, String appId) {
        System.debug('inside createInputMap');
        System.debug('loanId: '+loanId);
        System.debug('processName: '+processName);
        System.debug('appId: '+appId);
        try {
            Map<String, String> inputMap = new Map<String, String>();
            inputMap.put('loanId', loanId); 
            inputMap.put('processName', processName); 
            inputMap.put('applicantId', appId);
            if(loanId != null && appId!= null){
                List<Application_Applicant__c> appLists = [SELECT Id, PAN_Number__c, Customer_Type__c, DOB__c, DOI__c FROM Application_Applicant__c WHERE Id = :appId AND Loan_Application__c = :loanId];
                if(!appLists.isEmpty() && appLists[0].PAN_Number__c != null){
                    System.debug('pan found'+appLists[0].PAN_Number__c);
                    inputMap.put('panNum', appLists[0].PAN_Number__c);
                    inputMap.put('dob', String.valueof(System.today()));
                    
                }
                
            }
            // inputMap.put('pan', 'BTQPP1549D');

            return initiateAPIRequest(inputMap);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String initiateAPIRequest(Map<String,String> inputMap){
        // try {
			Integration_Details__c integrationDetails = new Integration_Details__c();
			String loanId = inputMap.get('loanId');
            String applicantId = inputMap.get('applicantId');
			String processName = inputMap.get('processName');
            String panNum = inputMap.get('panNum');
            String dob = inputMap.get('dob');
            String returnResp;
            String resultMessage;
            Integer statusCode;
        	system.debug('inputMap--->' +inputMap);
            List<Application_Applicant__c> applicantList = new List<Application_Applicant__c>();
            Map<String,API_Exceptions__mdt> allMetaData = API_Exceptions__mdt.getAll();
            applicantList = [Select Id,Applicant_Name__c,DOB__c,DOI__c,Email__c,Company__c,Loan_Application__c,PAN_Number__c,Customer_Type__c,Pan_Status__c FROM Application_Applicant__c WHERE Id =: applicantId];
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
            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper(); 
            wrapper.recordId =applicantId ;
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
            wrapper.handlername =  metadata.Handler_Class__c;
            wrapper.panNumber = panNum ;
            wrapper.customerDOB =Date.valueof(dob);
            
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
            FROM Integration_Settings__c WHERE Name = 'Loan Applicant PAN Validation' LIMIT 1];
            Integration_Settings__c intSetting = intSettingList[0];
        if(Test.isRUnningTest()){
            respWrapper.payload='{"pan":"CFMPS8909K","name":"Virendra Sehgal","dob":"30/12/1990","consent":"Y","clientData":{"caseId":"a01C200000NQYFOIA5"}}';
        }
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name =processName ;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                System.debug('resultMessage: '+resultMessage);
                returnResp = resultMessage;
            }
             else{
            //             String jsonResp=		'{'+
            //     '  "result": {'+
            //     '    "status": "Active",'+
            //     '    "duplicate": null,'+
            //     '    "nameMatch": true,'+
            //     '    "dobMatch": true'+
            //     '  },'+
            //     '  "request_id": "deff5ed8-0460-11e9-a082-4742912ca12a",'+
            //     '  "status-code": "101",'+
            //     '  "clientData": {'+
            //     '    "caseId": "123456"'+
            //     '  }'+
            //     '}';
                
                Map<String,String> integrationRequestMap = new Map<String,String>();
                integrationRequestMap.put('intSettingName',constants.get('PAN_Validation_API'));
                integrationRequestMap.put('requestJSON',respWrapper.payload);
                String bearer = Utility.getAccessToken();
                System.debug('bearer----'+bearer);
                System.debug('integrationRequestMap----'+integrationRequestMap);
                integrationRequestMap.put('bearer',bearer);
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                String apiResponse = resp.getBody();
                 
                    
                apiResponse = apiResponse.replace('status-code','status_code');
                PanResponseWrapper panrResp = (PanResponseWrapper) JSON.deserialize(apiResponse, PanResponseWrapper.class);
                System.debug('panrResp: '+panrResp);
                returnResp=JSON.serialize(panrResp);
                integrationDetail.Calling_Source__c = wrapper.type; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 
                integrationDetail.Response_JSON__c = JSON.serialize(apiResponse);
                integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
                integrationDetail.Method_Type__c = intSetting.Request_Method__c; 
                integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.Name = processName; 
                integrationDetail.Loan_Application__c = loanid;
                insert integrationDetail;
                //returnResp =jsonResp;

                if(resp.getStatusCode() == 200){
           
                String respCode = panrResp.response_Code;
                if(respCode == '1'){
                        List<Triangulation_Data__c> triangulationDatas = [SELECT Id, Loan_Application__c, Application_Applicant__c, Pan__c, Name__c, Date_Of_Birth__c FROM Triangulation_Data__c 
                        WHERE Loan_Application__c =: loanId AND Application_Applicant__c =: applicantId AND Source_Type__c = 'Validation API' AND Document_Type__c = 'PAN'];

                        List<Application_Applicant__c> applicants = [SELECT Id, Name, DOB__c FROM Application_Applicant__c WHERE Id =: applicantId AND Loan_Application__c =: loanId];
                    
                    if (panrResp != null && panrResp.outputData != null && !panrResp.outputData.isEmpty()) {
                        cls_outputData outputItem = panrResp.outputData[0];
                        Boolean nameMatch = (outputItem.name == 'Y');
                        Boolean dobMatch = (outputItem.dob == 'Y');

                        String matchedName = (applicants.isEmpty() || applicants[0].Name == null || !nameMatch) ? null : applicants[0].Name;
                        String matchedDOB = (applicants.isEmpty() || applicants[0].DOB__c == null || !dobMatch) ? null : String.valueOf(applicants[0].DOB__c);
                            
                            if (!triangulationDatas.isEmpty()) {
                                Triangulation_Data__c data = triangulationDatas[0];
                                if (matchedName != null) {
                                    data.Name__c = matchedName;
                                }
                                if (matchedDOB != null) {
                                    data.Date_Of_Birth__c = matchedDOB;
                                }
                                update data;
                            } else {
                                Triangulation_Data__c triangulationData = new Triangulation_Data__c();
                                triangulationData.Application_Applicant__c = applicantId;
                                triangulationData.Loan_Application__c = loanId;
                                triangulationData.Source_Type__c = 'Validation API';
                                triangulationData.Document_Type__c = 'PAN';
                    
                                if (matchedName != null) {
                                    triangulationData.Name__c = matchedName;
                                }
                                if (matchedDOB != null) {
                                    triangulationData.Date_Of_Birth__c = matchedDOB;
                                }
                                
                                insert triangulationData;
                            }
                        }
                    }
                    else {
                        applicantList[0].Pan_Status__c = 'Failed';
                        update applicantList;
                        for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                            if(execeptionMeta.Error_Code__c == String.valueOf(respCode)){
                                returnResp = 'Error: ' + execeptionMeta.Error_Message__c;
                                
                            }
                        }
                    }
                }
                else{
                     applicantList[0].Pan_Status__c = 'Failed';
                        update applicantList;
                }
             }
            
            // PanResponseWrapper panResp = (PanResponseWrapper) JSON.deserialize(returnResp, PanResponseWrapper.class);
            
            
            
            return returnResp; 
        // } catch (Exception e) {
        //     throw new AuraHandledException(e.getMessage());
        // }
    }

   
    public class PanResponseWrapper {
        @AuraEnabled public String response_Code;
        @AuraEnabled public String response_Code_description;
        @AuraEnabled public List<cls_outputData> outputData;
        }

    public class cls_outputData {
        @AuraEnabled public String pan;
        @AuraEnabled public String pan_status;
        @AuraEnabled public String name;
        @AuraEnabled public String fathername;
        @AuraEnabled public String dob;
        @AuraEnabled public String seeding_status;
        @AuraEnabled public String pan_status_description;
        @AuraEnabled public String seeding_status_description;
    }
}