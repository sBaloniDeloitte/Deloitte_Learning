public with sharing class HL_SquareYardCheckController {

    @AuraEnabled
    public static List<SqYdProjectWrapper> getProjectSuggestion(string loanId, String projectName, String city) {
        string processName = 'SqYd Project Suggestion';

        try {
            List<SqYdProjectWrapper> result = new List<SqYdProjectWrapper>();

            if(String.isEmpty(projectName) || String.isEmpty(city)) {
                throw new AuraHandledException('Error: Missing required parameters.');
            }

            // Fetch Metadata
            Integration_Master__mdt metadata = [
                SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, Client_Id__c, 
                Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, Refresh_Allowed__c, Activity_Name__c
                FROM Integration_Master__mdt 
                WHERE Activity_Name__c =: processName
                LIMIT 1
            ];

            if(metadata == null) {
                throw new AuraHandledException('Error: No metadata found for the given process.');
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
            system.debug('respWrapper.prerequisiteError: '+ respWrapper.prerequisiteError);
            
            if(respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                throw new AuraHandledException('Error: ' + String.join(respWrapper.prerequisiteError, ', '));
            }
            else {
                // Prepare API Request
                Map<String, String> integrationRequestMap = new Map<String, String>();
                integrationRequestMap.put('intSettingName', processName);
                integrationRequestMap.put('client_id', metadata.Client_Id__c);
                integrationRequestMap.put('client_key', metadata.Client_Secret__c);
                integrationRequestMap.put('endPoint', metadata.Endpoint__c +'?projectName='+ projectName +'&city='+ city);

                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                System.debug('resp: '+resp);

                Boolean isSuccessResponse = false;

                if(resp.getStatusCode() == 200){
                    //Deserialize the actual API response
                    SqYdProjListResponseWrapper response = (SqYdProjListResponseWrapper)JSON.deserialize(resp.getBody(), SqYdProjListResponseWrapper.class);
                    //system.debug('response: '+response);

                    isSuccessResponse = true;
                    result.addAll(response.data);
                }
            
                // Save API Response in Integration_Details__c
                Integration_Details__c integrationDetail = new Integration_Details__c();
                integrationDetail.Calling_Source__c = wrapper.type;
                integrationDetail.Request_JSON__c = respWrapper.payload;
                integrationDetail.Response_JSON__c = resp.getBody();
                integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                integrationDetail.Method_Type__c = metadata.Request_Method__c;
                integrationDetail.EndPoint__c = metadata.Endpoint__c;
                integrationDetail.Name = processName;
                integrationDetail.Loan_Application__c = loanId;
                integrationDetail.Is_Success_Response__c = isSuccessResponse;
                insert integrationDetail;
            }

            return result;
        } 
        catch(Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), processName, '', '') });
            throw new AuraHandledException('Salesforce Exception: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Id initiateTechnical(String param) {
        try{
            Map<string, string> paramMap = (Map<String, String>) JSON.deserialize(param, Map<String, String>.class);
            Map<String,String> inputMapUtility = new  Map<String,String>();
            Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
            Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
            //System.debug('initiateTechnical param: '+param);
            Id hlRecordId;
            if(isHlRelated){
                hlRecordId = Schema.SObjectType.Technical_Evaluation__c
                    .getRecordTypeInfosByName()
                    .get('HL Square Yard').getRecordTypeId();
            }
            // logic for Credit Manager while initiating TV
            // if(Utility.getCurrentUserProfileName() == 'Credit Manager') {
            //     List<Technical_Evaluation__c> existingTechRec = [SELECT Id FROM Technical_Evaluation__c WHERE HL_Loan_Application__c =: paramMap.get('loanId') 
            //                                                     AND HL_Application_Collateral__c =: paramMap.get('aplicationcolatteral') 
            //                                                     AND CreatedById =: UserInfo.getUserId() 
            //                                                     AND (HL_Stage__c != 'Rejected by Technical Manager' AND HL_Stage__c != 'Rejected by Admin') LIMIT 1];
                
            //     if(!existingTechRec.isEmpty()) {
            //         throw new AuraHandledException('You have already initiated a Technical Evaluation for this Collateral.');
            //     }
            // }
            
            List<Application_Collateral__c> appCollateralList = [SELECT Id, Name_of_Collateral__c, State__c, Collateral__r.State__c, Collateral__c, Collateral__r.Plot_Number__c, 
                                                                Collateral__r.Floor_Number__c, Collateral__r.Landmark__c, Collateral__r.Building_Street_Name__c, 
                                                                Collateral__r.Pincode__c, Collateral__r.Pincode__r.Name, Collateral__r.Address_Line_1__c, Asset_Type__c ,
                                                                Collateral__r.Address_Line_2__c, Collateral__r.Address_Line_3__c
                                                                from Application_Collateral__c where ID =: paramMap.get('aplicationcolatteral')];
            if(appCollateralList.isEmpty()) {
                throw new AuraHandledException('Application Collateral not found.');
            }

            //upload images to S3
            Map<String,String> inputMap = new Map<String,String>();
            inputMap.put('processName', 'S3 Upload');
            inputMap.put('loanId', paramMap.get('loanId'));
            inputMap.put('contentDocId', paramMap.get('costSheetDocId'));
            string costSheetS3Url = S3UploadController.uploadFile(inputMap);
            system.debug('costSheetS3Url: '+costSheetS3Url);
            //string costSheetS3Url = 'https://lt.godrejhf.com/GHFINC/3KEXqGo';

            inputMap.put('contentDocId', paramMap.get('architectCertDocId'));
            string architectCertS3Url = S3UploadController.uploadFile(inputMap);
            system.debug('architectCertS3Url: '+architectCertS3Url);
            //string architectCertS3Url = 'https://lt.godrejhf.com/GHFINC/3KEXqGo';

            inputMap.put('contentDocId', paramMap.get('imageDocId'));
            string imageS3Url = S3UploadController.uploadFile(inputMap);
            system.debug('imageS3Url: '+imageS3Url);
            //string imageS3Url = 'https://lt.godrejhf.com/GHFINC/3KEXqGo';

            if(String.isBlank(costSheetS3Url) || costSheetS3Url == 'null' || costSheetS3Url.contains('Error:') 
                || String.isBlank(architectCertS3Url) || architectCertS3Url == 'null' || architectCertS3Url.contains('Error:')
                || String.isBlank(imageS3Url) || imageS3Url == 'null' || imageS3Url.contains('Error:'))
            {
                system.debug('Some error in uploading documents to S3.');
                throw new AuraHandledException('Some error in uploading documents to S3.');
            }
            
            String addressData = COMM_TechnicalRecordPageController.buildAddress(appCollateralList[0].Collateral__r);
            
            String primaryApplicant = '';
            List<String> coApplicants = new List<String>();
            for(Application_Applicant__c app : [SELECT Applicant_Type__c, First_Name__c, Last_Name__c FROM Application_Applicant__c WHERE Loan_Application__c =: paramMap.get('loanId') ORDER BY Applicant_Type__c]) {
                String fullName = app.First_Name__c + ' ' + app.Last_Name__c;
                if(app.Applicant_Type__c == Constants.APPLICANT_TYPE_APPLICANT) {
                    primaryApplicant = fullName;
                }
                else if(app.Applicant_Type__c == Constants.APPLICANT_TYPE_CO_APPLICANT) {
                    coApplicants.add(fullName);
                }
            }
            
            Technical_Evaluation__c tech = new Technical_Evaluation__c();
            tech.HL_Loan_Application__c = paramMap.get('loanId');
            tech.HL_Application_Collateral__c = appCollateralList[0].Id;
            tech.HL_Collateral_Address__c = addressData;
            tech.HL_Technical_Type__c = 'External';
            tech.HL_Sent_Back_Count__c = 0;
            tech.HL_Record_Type__c ='SquareYard';
            tech.HL_Report_Date__c = Date.today();
            tech.HL_Customer_Name__c = primaryApplicant;
            tech.HL_Name_of_Applicant__c = primaryApplicant + (coApplicants.isEmpty() ? '' : ', ' + String.join(coApplicants, ', '));
            tech.HL_Stage__c = 'In progress';
            tech.HL_Name_of_Project__c = paramMap.get('projectName');
            tech.HL_Area_Type__c = paramMap.get('areaType');
            tech.HL_Area_of_Property__c = paramMap.get('area');
            tech.Unit_Type__c = paramMap.get('configuration');
            tech.HL_Pincode__c = paramMap.get('pincodeId');
            tech.HL_SquareYard_ProjectId__c = paramMap.get('projectId');
            tech.HL_LAN_ID__c = paramMap.get('loanId');
            tech.HL_Cost_Sheet_Url__c = costSheetS3Url;
            tech.HL_Architecture_Cert_Url__c = architectCertS3Url;
            tech.HL_Image_Url__c = imageS3Url;
            if(isHlRelated){
                tech.RecordTypeId = hlRecordId;
            }
            insert tech;
            Applicant_Address__c appAdd = [SELECT Id,Application_Collateral__c,Address_Type__c,Applicant__c,Legal__c,HL_Address_Line_1__c,HL_Address_Line_2__c,HL_Address_Line_3__c,Pincode__c  FROM Applicant_Address__c where 
                                                Application_Collateral__c =:  paramMap.get('aplicationcolatteral') limit 1];
                Applicant_Address__c newAppAddress = appAdd.clone(false, false, false, false);
                newAppAddress.Address_Type__c = appAdd.Address_Type__c;
                newAppAddress.Applicant__c = appAdd.Applicant__c;
                newAppAddress.Loan_Application__c =  paramMap.get('loanId');
                newAppAddress.Technical_Evaluation__c = tech.Id;
                insert newAppAddress;
            
            //Ceate Technical Report records
            Document_Details__c docCheck = new Document_Details__c();
            docCheck.Requirement_At__c = 'Collateral Level';
            docCheck.Document_Category__c = Constants.DOCUEMNT_TYPE_TECHNICAL_TYPE;
            docCheck.Name = Constants.TECHNICAL_DOCUMENT_NAME;
            docCheck.Collateral_Master__c = appCollateralList[0].Collateral__c;
            docCheck.Application_Collateral__c = appCollateralList[0].Id;
            docCheck.Loan_Application__c = paramMap.get('loanId');
            docCheck.Document_Required__c = Constants.DOCUMENT_CHECKLIST_REQUIRED;
            docCheck.Technical__c = tech.Id;
            insert docCheck;

            //call Sq Yd Create API
            String processName = 'SqYd Initiation';

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

            intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
            wrapper.recordId = tech.Id;
            wrapper.loanApplicationId = paramMap.get('loanId');
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
            system.debug('respWrapper.prerequisiteError: '+ respWrapper.prerequisiteError);
            
            if(respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                throw new AuraHandledException('Error: ' + String.join(respWrapper.prerequisiteError, ', '));
            }
            else {
                initiateSqYdCheck(paramMap.get('loanId'), tech.Id, processName, respWrapper.payload);
            }

            return tech.Id;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @future(callout=true)
    public static void initiateSqYdCheck(string loanId, String techId, string processName, String payload) {

        try {
            Integration_Master__mdt metadata = [
                SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, Client_Id__c, 
                Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, Refresh_Allowed__c, Activity_Name__c
                FROM Integration_Master__mdt 
                WHERE Activity_Name__c = :processName 
                LIMIT 1
            ];

            // Prepare API Request
            Map<String, String> integrationRequestMap = new Map<String, String>();
            integrationRequestMap.put('intSettingName', processName);
            integrationRequestMap.put('client_id', metadata.Client_Id__c);
            integrationRequestMap.put('client_key', metadata.Client_Secret__c);
            integrationRequestMap.put('requestJSON', payload);
            integrationRequestMap.put('endPoint', metadata.Endpoint__c);

            HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
            //System.debug('resp: '+resp);

            Boolean isSuccessResponse = false;

            if(resp.getStatusCode() == 200){
                // Deserialize the actual API response
                SqYdCreateResponseWrapper response = (SqYdCreateResponseWrapper)JSON.deserialize(resp.getBody(), SqYdCreateResponseWrapper.class);
                system.debug('response: '+response);

                isSuccessResponse = true;

                Technical_Evaluation__c tech = new Technical_Evaluation__c(
                    Id = techId, 
                    HL_SquareYard_RequestId__c = response.data.requestId, 
                    HL_SquareYard_LogId__c = response.data.logId
                );
                
                update tech;
            }
        
            // Save API Response in Integration_Details__c
            Integration_Details__c integrationDetail = new Integration_Details__c();
            integrationDetail.Calling_Source__c = processName;
            integrationDetail.Request_JSON__c = payload;
            integrationDetail.Response_JSON__c = resp.getBody();
            integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
            integrationDetail.Method_Type__c = metadata.Request_Method__c;
            integrationDetail.EndPoint__c = metadata.Endpoint__c;
            integrationDetail.Name = processName;
            integrationDetail.Loan_Application__c = loanId;
            integrationDetail.Is_Success_Response__c = isSuccessResponse;
            insert integrationDetail;
        }
        catch(Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), processName, '', '') });
            System.debug('Error: '+e.getMessage());
        }
    }

    public class SqYdProjectWrapper {
        @AuraEnabled public String projectId;
        @AuraEnabled public String projectName;
        @AuraEnabled public String city;
        @AuraEnabled public String locality;
        @AuraEnabled public String location;
    }

    public class SqYdProjListResponseWrapper {
        public Integer code;	    //200
        public String status;	    //OK
        public List<SqYdProjectWrapper> data;
    }

    public class SqYdCreateResponseWrapper {
        public Integer code;	    //200
        public String status;	    //OK
        public Data data;
    }

    public class Data {
        public String message;	    //Request received successfully
        public String requestId;	    // GCP-EV36FF94424388
        public String logId;	    //95352efe-c9cf-4273-ae5a-5245e2b37ab7
    }
}