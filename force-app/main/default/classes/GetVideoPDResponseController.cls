public class GetVideoPDResponseController {
    @AuraEnabled
    public static String checkVideoPD(Id loanId , Id appId) {
        List<Application_Verification__c> applicationVeifList = [SELECT Id, Crime_Check_Status__c FROM Application_Verification__c 
                                                                    WHERE Loan_Application__c =: loanId AND Id =: appId];
        String applicationVerificationListId;
        if(!applicationVeifList.isEmpty()){
            if(applicationVeifList[0].Crime_Check_Status__c == 'Completed') {
                applicationVerificationListId = applicationVeifList[0].Id;
            } else {
                applicationVerificationListId = 'The Application has not been verifed.';
            }
        }
        return applicationVerificationListId;
    }

    public static void testWrapper(){
        String respo = '[{"firstName":"Sneha","email":"43cb3f1f-577e-413f-8535-9fde61cb0ac3","data":[{"key":"CustomerName","value":"Sneha"},{"key":"LanNumber","value":"4f6f5e6b-b283-485c-9627-f9247b0f3d751738651624956"}],"scpUrl":"https://uat.videocx.io/scp/c8878e2be2e311efb20e026edc5d8937","encrypted":false,"id":190096,"agent":{"username":"admin@godrejcapital.com","userId":126700,"isCoworker":false,"isPwdEncrypted":true},"gclStatus":"Open","statusUpdatedDate":"2025-02-04T10:35:42.155Z","callDuration":"","agentConnectedOn":"2025-02-04T10:35:42.155Z","groupName":"Sneha"},{"firstName":"Sneha","email":"8f633f0e-12bb-4a0f-b247-214f0a3c6eae","data":[{"key":"CustomerName","value":"Sneha"},{"key":"LanNumber","value":"4f6f5e6b-b283-485c-9627-f9247b0f3d751738651624956"}],"scpUrl":"https://uat.videocx.io/scp/82f107f2e2e411efb20e026edc5d8937","encrypted":false,"id":190099,"agent":{"username":"admin@godrejcapital.com","userId":126700,"isCoworker":false,"isPwdEncrypted":true},"documents":[{"id":899106,"url":"https://uat.videocx.io/owb/attachments/system/download/ba19afbbd71f42b5a19da19d4b052f671738665687652","fileName":"sharedimage.jpg","fileSize":"34KB","createdDate":"2025-02-04T16:11:27.000Z"}],"gclStatus":"Open","statusUpdatedDate":"2025-02-04T10:40:54.903Z","callDuration":"","agentConnectedOn":"2025-02-04T10:40:54.903Z","groupName":"Sneha"},{"firstName":"test","email":"6e92cbd9-7ac2-4d42-90b3-1a05b0beb9ca","data":[{"key":"CustomerName","value":"test"},{"key":"LanNumber","value":"4f6f5e6b-b283-485c-9627-f9247b0f3d751738651624956"}],"scpUrl":"https://uat.videocx.io/scp/04e9f9f2e2eb11efb20e026edc5d8937","encrypted":false,"id":190114,"agent":{"username":"admin@godrejcapital.com","userId":126700,"isCoworker":false,"isPwdEncrypted":true},"gclStatus":"Open","statusUpdatedDate":"2025-02-04T11:27:29.941Z","callDuration":"","agentConnectedOn":"2025-02-04T11:27:29.941Z","groupName":"test"}]';
        List<VedioPdResponseWrapper> responseJSON = (List<VedioPdResponseWrapper>) JSON.deserialize(respo, List<VedioPdResponseWrapper>.class);
        System.debug('responseJSON '+responseJSON);
    }
    /* @AuraEnabled
    public static String getVedioPdResponse(Map<String,String> inputMap) {
        // try {
            List<string> validatemandate = new List<string>();
            List<string> constructpayload = new List<string>();
            String resultMessage;
            String loanId = inputMap.get('loanId');
            String applicantId = inputMap.get('recordId');
            String processName = inputMap.get('processName');
            
            List<Application_Verification__c> applicationVeifList = [SELECT Id, Crime_Check_Status__c FROM Application_Verification__c 
                                                                    WHERE Loan_Application__c =: loanId AND Applicant__c =: applicantId];

            String returnResp;
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
            wrapper.handlername =  metadata.Handler_Class__c;
            
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            System.debug('respWrapper iNT Handler--> ' + respWrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');
                returnResp = resultMessage;
            } else {
                Map<String,String> integrationRequestMap = new Map<String,String>();
                integrationRequestMap.put('intSettingName','Video PD Response');
                integrationRequestMap.put('requestJSON',respWrapper.payload);
                HTTPResponse resp = executeAPIRequest(integrationRequestMap, 'mainAPi', '');
                System.debug('resp --> ' + resp);

                if(resp != null) {
                    if (resp.getStatusCode() == 200) {
                        returnResp = resp.getBody();
                        List<VedioPdResponseWrapper> responseJSON = (List<VedioPdResponseWrapper>) JSON.deserialize(returnResp, List<VedioPdResponseWrapper>.class);
                        System.debug('responseJSON : ' + responseJSON);
                        System.debug('responseJSON serialize : ' + JSON.serialize(responseJSON));
                        
                        Integer docCounter = 1;

                        for (VedioPdResponseWrapper docRecord : responseJSON) {
                            System.debug('docRecord --> ' + docRecord);

                            if (docRecord.documents != null) {
                                for (cls_documents doc : docRecord.documents) {
                                    System.debug('Document URL: ' + doc.url);
                                    System.debug('Document File Name: ' + doc.fileName);
                                    Map<String,String> integrationRequestDocMap = new Map<String,String>();
                                    integrationRequestDocMap.put('intSettingName','Video PD Response');
                                    HTTPResponse response = executeAPIRequest(integrationRequestDocMap, doc.fileName, doc.url);
                                    System.debug('response --> '+ docCounter +'--> ' + response);
                                    docCounter++;
                                }
                            } else {
                                System.debug('No documents found for record ID: ' + docRecord.id);
                            }
                        }
                    }
                }
            }
            return returnResp;
        // } catch (Exception e) {
        //     throw new AuraHandledException('Error: ' + e.getMessage());
        // }
    } */
    @AuraEnabled
    public static List<Map<String, String>> getVedioPdResponse(Map<String,String> inputMap) {
        // try {
            List<string> validatemandate = new List<string>();
            List<string> constructpayload = new List<string>();
            String resultMessage;
            String loanId = inputMap.get('loanId');
            String applicantId = inputMap.get('recordId');
            String processName = inputMap.get('processName');
            
            List<Application_Verification__c> applicationVeifList = [SELECT Id, Crime_Check_Status__c FROM Application_Verification__c 
                                                                    WHERE Loan_Application__c =: loanId AND Id =: applicantId];

            String returnResp;
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
            wrapper.handlername =  metadata.Handler_Class__c;
            
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            System.debug('respWrapper iNT Handler--> ' + respWrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Map<String, String>> documentList = new List<Map<String, String>>();
            
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');
                returnResp = resultMessage;
            } else {
                Map<String,String> integrationRequestMap = new Map<String,String>();
                integrationRequestMap.put('intSettingName','Video PD Response');
                integrationRequestMap.put('requestJSON',respWrapper.payload);
                HTTPResponse resp = executeAPIRequest(integrationRequestMap, 'mainAPi', '', loanId, applicantId);
                System.debug('resp --> ' + resp);

                if(resp != null) {
                    if (resp.getStatusCode() == 200) {
                        returnResp = resp.getBody();
                        List<VedioPdResponseWrapper> responseJSON = (List<VedioPdResponseWrapper>) JSON.deserialize(returnResp, List<VedioPdResponseWrapper>.class);
                        System.debug('responseJSON : ' + responseJSON);
                        System.debug('responseJSON serialize : ' + JSON.serialize(responseJSON));

                        for (VedioPdResponseWrapper docRecord : responseJSON) {
                            System.debug('docRecord --> ' + docRecord);

                            if (docRecord.documents != null) {
                                for (cls_documents doc : docRecord.documents) {
                                    Map<String, String> docMap = new Map<String, String>();
                                    System.debug('Document URL: ' + doc.url);
                                    System.debug('Document File Name: ' + doc.fileName);
                                    docMap.put('url', doc.url);
                                    docMap.put('fileName', doc.fileName);
                                    documentList.add(docMap);
                                }
                            } else {
                                System.debug('No documents found for record ID: ' + docRecord.id);
                            }
                        }
                    }
                }
            }
            return documentList;
        // } catch (Exception e) {
        //     throw new AuraHandledException('Error: ' + e.getMessage());
        // }
    }
    public class VedioPdResponseWrapper {
        public String firstName;	//Sneha
        public String email;	//8f633f0e-12bb-4a0f-b247-214f0a3c6eae
        public cls_data[] data;
        public String scpUrl;	//https://uat.videocx.io/scp/82f107f2e2e411efb20e026edc5d8937
        public boolean encrypted;
        public Integer id;	//190099
        public cls_agent agent;
        public cls_documents[] documents;
        public String gclStatus;	//Open
        public String statusUpdatedDate;	//2025-02-04T10:40:54.903Z
        public String callDuration;	//
        public String agentConnectedOn;	//2025-02-04T10:40:54.903Z
        public String groupName;	//Sneha
    }
    public class cls_data {
        public String key;	//Customer Name
        public String value;	//test
    }
    public class cls_agent {
        public String username;	//admin@godrejcapital.com
        public Integer userId;	//126700
        public boolean isCoworker;
        public boolean isPwdEncrypted;
    }
    public class cls_documents {
        public Integer id;	//899106
        public String url;	//https://uat.videocx.io/owb/attachments/system/download/ba19afbbd71f42b5a19da19d4b052f671738665687652
        public String fileName;	//shared image.jpg
        public String fileSize;	//34 KB
        public String createdDate;	//2025-02-04T16:11:27.000Z
    }

    @AuraEnabled
    public static string getDocs(Map<String, String> docDetails, String loanId, String appId){
        String url = docDetails.get('url');
        String fileName = docDetails.get('fileName');
        Map<String,String> integrationRequestDocMap = new Map<String,String>();
        integrationRequestDocMap.put('intSettingName','Video PD Response');
        HTTPResponse response = executeAPIRequest(integrationRequestDocMap, fileName, url, loanId, appId);
        System.debug('response --> '+ response);
        return response.getBody();
    }

    public static HTTPResponse executeAPIRequest(Map<string, string> apiParam, String requestFor, String docURL, String loanId, String appId ){
        // try{
            Integration_Settings__c intDetails = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                                                    FROM Integration_Settings__c WHERE Name =: apiParam.get('intSettingName') Limit 1];
            String apiKey = intDetails.Client_Secret__c;

            DateTime timestamp = DateTime.now();
            Long epochMillis = timestamp.getTime();
            String epochString = String.valueOf(epochMillis);
            System.debug('epoch --> '+epochString);

            String apiSecret = 'a56d0e83552245ea92c0c0209af65f60';
            String path = apiKey + ':' + epochString;
            Blob data = crypto.generateMac('HmacSHA256',Blob.valueOf(path),Blob.valueOf(apiSecret));
            String signature = EncodingUtil.base64Encode(data);
            System.debug('signature --> '+signature);
            String uniqueId = UUid.randomUUID().toString(); 
            System.debug('uniqueId --> '+uniqueId);
            System.debug('Content-Type --> '+intDetails.Content_Type__c);
            HttpRequest req = new HttpRequest();
            req.setHeader('Content-Type', intDetails.Content_Type__c);
            req.setHeader('client-id', intDetails.Client_Id__c);
            req.setHeader('apiKey', apiKey);
            req.setHeader('x-request-id', uniqueId);
            req.setHeader('timestamp', epochString); // epochString
            req.setHeader('signature', signature); // signature
            if(requestFor == 'mainAPi') {
                string endpoint = intDetails.EndPoint__c;
                req.setEndpoint(endpoint);
                req.setMethod(intDetails.Request_Method__c);
            } else {
                req.setEndpoint(docURL);
                req.setMethod('GET');
            }
            // req.setMethod(intDetails.Request_Method__c);
            req.setTimeout(60000);
            
            if(apiParam.containsKey('requestJSON')){
                string requestJSON = apiParam.get('requestJSON');
                req.setBody(requestJSON);
                system.debug('requestJSON: '+ requestJSON);
            }
            
            System.debug('Request: '+ req);
            System.debug('Request Headers:');
            // for (String key : req.getHeaderKeys()) {
            System.debug('Content-Type: '+req.getHeader('Content-Type'));
            System.debug('client-id: '+req.getHeader('client-id'));
            System.debug('apiKey: '+req.getHeader('apiKey'));
            System.debug('x-request-id: '+req.getHeader('x-request-id'));
            System.debug('timestamp: '+req.getHeader('timestamp'));
            System.debug('signature: '+req.getHeader('signature'));

            // }
            Http http = new Http();
            HTTPResponse res = http.send(req);
            System.debug('Response body: ' + res.getBody());
            System.debug('Response code: ' + res.getStatusCode());
            
            if(requestFor == 'mainAPi') {
                return res;
            } else {
                Blob responseBlob = res.getBodyAsBlob();

                ContentVersion cv = new ContentVersion();
                cv.VersionData = responseBlob;
                cv.Title = requestFor + 'Downloaded Video PD Document';
                cv.PathOnClient = 'DownloadedVideoPDDocument.jpg';
                insert cv;

                cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = cv.ContentDocumentId;
                cdl.LinkedEntityId = loanId; // UserInfo.getUserId();
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                insert cdl;  

                String s3StyleURL = '/sfc/servlet.shepherd/document/download/' + cv.ContentDocumentId;

                List<Application_Verification__c> applicationVeifList = [SELECT Id, Crime_Check_Status__c,Applicant__c FROM Application_Verification__c 
                                                                            WHERE Loan_Application__c =: loanId AND Id =: appId];

                Document_Details__c docDetail = new Document_Details__c();
                docDetail.Name = requestFor + ' VideoPD Doc';
                docDetail.Content_Document_Id__c = cv.ContentDocumentId;
                docDetail.Document_URL__c = s3StyleURL;
                docDetail.Reference_Id__c = applicationVeifList[0].Id;
                docDetail.Loan_Application__c = loanId;
                docDetail.Applicant__c = applicationVeifList[0].Applicant__c;
                insert docDetail;

                applicationVeifList[0].Crime_Check_Status__c = 'Completed'; 

                update  applicationVeifList[0];             
                return res;
            }
        // }
        // catch(System.Exception e){
        //     System.debug('Error: ' + e);
        //     System.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
            
        //     return null;
        // }
    }


    public class DocumentWrapper {
        @AuraEnabled public String name;
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String documentUrl;
        @AuraEnabled public String fileType;
        @AuraEnabled public Boolean isPDF;

        public DocumentWrapper(String name, String contentDocumentId, String documentUrl, String fileType) {
            this.name = name;
            this.contentDocumentId = contentDocumentId;
            this.documentUrl = documentUrl;
            this.fileType = fileType;
            this.isPDF = 'PDF'.equalsIgnoreCase(fileType);
        }
    }

    @AuraEnabled
    public static List<DocumentWrapper> getDocuments(Id appId, Id loanId) {
        try {
            List<DocumentWrapper> wrapperList = new List<DocumentWrapper>();

            List<Application_Verification__c> applicationVeifList = [SELECT Id FROM Application_Verification__c WHERE Loan_Application__c = :loanId AND Applicant__c = :appId];

            if (applicationVeifList.isEmpty()) return wrapperList;

            List<Document_Details__c> docDetailsList = [SELECT Id, Name, Content_Document_Id__c, Document_URL__c FROM Document_Details__c 
                                                        WHERE Loan_Application__c = :loanId AND Applicant__c = :appId AND Reference_Id__c = :applicationVeifList[0].Id];

            Set<Id> contentDocIds = new Set<Id>();
            for (Document_Details__c doc : docDetailsList) {
                if (doc.Content_Document_Id__c != null) {
                    contentDocIds.add(doc.Content_Document_Id__c);
                }
            }

            Map<Id, ContentDocument> contentDocMap = new Map<Id, ContentDocument>(
                [SELECT Id, FileType FROM ContentDocument WHERE Id IN :contentDocIds]
            );

            for (Document_Details__c doc : docDetailsList) {
                String fileType = '';
                if (contentDocMap.containsKey(doc.Content_Document_Id__c)) {
                    fileType = contentDocMap.get(doc.Content_Document_Id__c).FileType;
                }

                wrapperList.add(new DocumentWrapper(
                    doc.Name,
                    doc.Content_Document_Id__c,
                    doc.Document_URL__c,
                    fileType
                ));
            }

            return wrapperList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static String getVPDLink(Map<String,String> inputMap){
        String result= 'No link found';
        String loanId = inputMap.get('loanId');
        String applicantId = inputMap.get('recordId');
        Boolean callAPI= false;
        List<Integration_Details__c> intList= [SELECT Id, Response_JSON__c  FROM Integration_Details__c WHERE Loan_Application__c = :loanId AND Related_Record_Id__c = :applicantId AND Status__c = '200' AND Name = 'Get Video PD'];
        List<VedioPdResponseWrapper> responseJSON= new List<VedioPdResponseWrapper>();
        if(intList.size()>0){
            if(intList[0].Response_JSON__c != null){
                responseJSON= (List<VedioPdResponseWrapper>) JSON.deserialize(intList[0].Response_JSON__c, List<VedioPdResponseWrapper>.class);
            }else{
                callAPI=true;
            }
        }
        else {
            callAPI = true;
        }
        if(callAPI){
            String processName = 'Get Video PD';
            
            List<Application_Verification__c> applicationVeifList = [SELECT Id, Crime_Check_Status__c FROM Application_Verification__c 
                                                                    WHERE Loan_Application__c =: loanId AND Id =: applicantId AND Personal_Discussion_Type__c = 'Video PD'];

            String returnResp;
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
            wrapper.handlername =  metadata.Handler_Class__c;
            
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            System.debug('respWrapper iNT Handler--> ' + respWrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Map<String, String>> documentList = new List<Map<String, String>>();
            
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
            } else {
                Map<String,String> integrationRequestMap = new Map<String,String>();
                integrationRequestMap.put('intSettingName','Video PD Response');
                integrationRequestMap.put('requestJSON',respWrapper.payload);
                HTTPResponse resp = executeAPIRequest(integrationRequestMap, 'mainAPi', '', loanId, applicantId);
                System.debug('resp --> ' + resp);

                if(resp != null) {
                    if (resp.getStatusCode() == 200) {
                        returnResp = resp.getBody();
                        integrationDetail.Calling_Source__c = wrapper.type; 
                        integrationDetail.Request_JSON__c = respWrapper.payload; 
                        integrationDetail.Response_JSON__c = returnResp; 
                        integrationDetail.Status__c = String.valueof('200'); 
                        integrationDetail.Method_Type__c = wrapper.requestMethod; 
                        integrationDetail.EndPoint__c = wrapper.endpoint; 
                        integrationDetail.Object_Name__c = 'Application_Applicant__c';
                        integrationDetail.Name = processName;
                        integrationDetail.Loan_Application__c = loanid;
                        integrationDetail.Related_Record_Id__c = applicationVeifList[0].Id;
                        insert integrationDetail;
                        
                        responseJSON = (List<VedioPdResponseWrapper>) JSON.deserialize(returnResp, List<VedioPdResponseWrapper>.class);
                        System.debug('responseJSON : ' + responseJSON);
                        System.debug('responseJSON serialize : ' + JSON.serialize(responseJSON));

                        
                    }
                }
            }
        }
        for (VedioPdResponseWrapper docRecord : responseJSON) {
            if (docRecord.scpUrl != null) {
                result = docRecord.scpUrl;
            }
        }
        return result;
    }
    
}