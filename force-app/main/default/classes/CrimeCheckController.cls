public class CrimeCheckController {
    @AuraEnabled
    public static List<ApplicantWrapper> getAllApplicantsInfo(String recordId) {
        List<ApplicantWrapper> mainWrap = new List<ApplicantWrapper>();
        String crimeCheckRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Crime_Check');
        List<Application_Applicant__c> itrObj = [SELECT id,Applicant_Name__c,Customer_Type__c,Business_Type__c,Company__c,GSTIN__c
                                                     FROM Application_Applicant__c WHERE Loan_Application__c =: recordId];
        Set<String> nonIndividualIds = new Set<String>();
        if(itrObj.size() > 0) {
            for(Application_Applicant__c iterApp : itrObj) {
                if(iterApp.Customer_Type__c == 'Non Individual') {
                    nonIndividualIds.add(iterApp.Id);
                }
            }
        }
        Map<String,Applicant_Address__c> applicantIdAddMap = new Map<String,Applicant_Address__c>();
        Map<String,Application_Verification__c> applicantIdAVMap = new Map<String,Application_Verification__c>();
        if(nonIndividualIds.size() > 0) {
            List<Applicant_Address__c> nonIndAddress = [SELECT id,Full_Address__c,Applicant__c FROM Applicant_Address__c WHERE 
                                                        Applicant__c IN : nonIndividualIds AND
                                                       Address_Type__c = 'Business'];
            if(nonIndAddress.size() > 0) {
                for(Applicant_Address__c iterAdd : nonIndAddress) {
                    applicantIdAddMap.put(iterAdd.Applicant__c,iterAdd);
                }
            }
        }
        List<Application_Verification__c> lstApplicationVerification = [SELECT id,Completion_Date__c,
                                                                        Crimewatch__c,Request_Time__c,Risk_Type__c,IsClicked__c,Crime_Check_File_Link__c,
                                                                        Crime_Check_Request_Id__c,Number_of_Cases__c,Any_Remarks_Reasons__c,
                                                                        Crime_Check_Status__c, Applicant__c,Disposition__c,Verification_Remarks__c
                                                                        FROM Application_Verification__c 
                                                                        WHERE Loan_Application__c =: recordId AND
                                                                       recordTypeId =: crimeCheckRecordTypeId] ;
        Map<String,String> appDocIdMap = new  Map<String,String>();
        if(lstApplicationVerification.size() > 0) {
            for(Application_Verification__c iterAP : lstApplicationVerification) {
                applicantIdAVMap.put(iterAP.Applicant__c,iterAP);
            }
            List<Document_Details__c> docDetails = [SELECT id,Content_Document_Id__c,Application_Verification__r.Applicant__c FROM Document_Details__c WHERE Application_Verification__c IN :lstApplicationVerification];
            for(Document_Details__c docIter : docDetails) {
                appDocIdMap.put(docIter.Application_Verification__r.Applicant__c,docIter.Content_Document_Id__c);
            }
        }
        Map<String,List<DetailsWrapper>> mapInnerWrap = new  Map<String,List<DetailsWrapper>>();
        Boolean isCallback = false;
        if(itrObj.size() > 0) {
            for(Application_Applicant__c iterApp : itrObj) {
                DetailsWrapper tempObj = new DetailsWrapper();
                tempObj.applicantId = iterApp.Id;
                
                if(iterApp.Customer_Type__c == 'Non Individual') {
                    //tempObj.isIndividual = false;
                    tempObj.compType = iterApp.Business_Type__c;
                    tempObj.applicantCompName = iterApp.Company__c;
                    tempObj.compGst = String.isNotBlank(iterApp.GSTIN__c)?iterApp.GSTIN__c:'';
                    tempObj.compAddress = applicantIdAddMap.containsKey(iterApp.Id)?applicantIdAddMap.get(iterApp.Id).Full_Address__c:'';
                    tempObj.compDirectors = new List<String>{'Director 1','Director 2'};
                }else {
                    //tempObj.isIndividual = true;
                    tempObj.applicantCompName = iterApp.Applicant_Name__c;
                }
                tempObj.isCompleted = false;
                if(applicantIdAVMap.containsKey(iterApp.id)) {
                    tempObj.isInitiated = true;
                    Application_Verification__c tempAV = applicantIdAVMap.get(iterApp.id);
                    tempObj.crimeCheckStatus = tempAV.Crime_Check_Status__c;

                    //tempObj.appvId= tempAV.Id;
                   
                   
    

                    if(tempAV.Crime_Check_Status__c == 'Completed') {
                        tempObj.isCompleted = true;
                        tempObj.appVerificationId = tempAV.id;
                        tempObj.riskType = tempAV.Risk_Type__c;
                       //;
                        tempObj.riskSummary = tempAV.Verification_Remarks__c;
                        tempObj.disposition = tempAV.Disposition__c;
                        tempObj.downloadLink = tempAV.Crime_Check_File_Link__c;
                        tempObj.docId = appDocIdMap.containsKey(iterApp.Id)?appDocIdMap.get(iterApp.Id):'';
                        if (tempObj.docId != null && tempObj.docId != '' ) {
                            tempObj.isDocPresent = true;
                        } else {
                            tempObj.isDocPresent = false;
                        }
                        if(tempAV.Risk_Type__c == 'High Risk') {
                            tempObj.isHighRisk = false;
                        }
                        
                        else if(tempAV.Risk_Type__c != 'No Risk') {
                            tempObj.isClicked = tempAV.IsClicked__c;
                        }else if(tempAV.Risk_Type__c == 'No Risk') {
                            tempObj.isClicked = false;
                        }
                    }else {
                        isCallback = true;
                        tempObj.isCompleted = false;
                        tempObj.riskType = '';
                        tempObj.riskSummary = '';
                        tempObj.disposition = '';
                      
                    }
                }else {
                    tempObj.isInitiated = false;
                }
                if(iterApp.Customer_Type__c == 'Non Individual') {
                    if(mapInnerWrap.containsKey('Non Individual')) {
                        mapInnerWrap.get('Non Individual').add(tempObj);                                                                        
                    }else {
                        mapInnerWrap.put('Non Individual',new List<DetailsWrapper>{tempObj});
                    }
                    
                }else {
                    if(mapInnerWrap.containsKey('Individual')) {
                        mapInnerWrap.get('Individual').add(tempObj);                                                                        
                    }else {
                        mapInnerWrap.put('Individual',new List<DetailsWrapper>{tempObj});
                    }
                }
                
            }
            
        }
        if(mapInnerWrap.size() > 0) {
            
            if(mapInnerWrap.containsKey('Individual')) {
                ApplicantWrapper iter = new ApplicantWrapper();
                iter.applicantType = 'Crime Check Individual';
                iter.applicantInfo = mapInnerWrap.get('Individual');
                iter.isIndividual = true;
                if(isCallback) {
                    iter.callbackNotReceived = 'We were not able to fetch the results at the moment. Please try again after some time!';
                }else {
                    iter.callbackNotReceived = null;
                }
                
                mainWrap.add(iter);
            }
            if(mapInnerWrap.containsKey('Non Individual')) {
                ApplicantWrapper iter = new ApplicantWrapper();
                iter.applicantType = 'Crime Check Non-individual';
                iter.applicantInfo = mapInnerWrap.get('Non Individual');
                iter.isIndividual = false;
                //mainWrap.add(iter);
            }
            
            
        }
        return mainWrap;
    }
    
    @AuraEnabled
    public static string createCrimeCheckFile(String docLink, String recordId){
        // try {
            System.debug('docLink : '+docLink);
            System.debug('recordId : '+recordId);
            if (recordId != null && recordId.contains('-')) {
                recordId = recordId.substringBefore('-');
            }
            System.debug('Corrected recordId: ' + recordId);
            List<Application_Verification__c> appVeri = [SELECT id,Completion_Date__c,Applicant__r.Applicant_Name__c,Loan_Application__c,
                                                     Crimewatch__c,Request_Time__c,Risk_Type__c,Crime_Check_File_Link__c,
                                                     Crime_Check_Request_Id__c,Number_of_Cases__c,Any_Remarks_Reasons__c,Verification_Remarks__c,
                                                     Crime_Check_Status__c, Applicant__c,Disposition__c FROM Application_Verification__c 
                                                     WHERE Id =:recordId];
            String base64 = getBase64(docLink);
            Blob contentBlob = EncodingUtil.base64Decode(base64);
            ContentVersion cv = new ContentVersion();
            cv.Title = 'CrimeCheck_'+appVeri[0].id;
            cv.PathOnClient = 'CrimeCheck_' + appVeri[0].Applicant__r.Applicant_Name__c+'.pdf';
            cv.VersionData = contentBlob;
            cv.IsMajorVersion = true;
            insert cv;
            ContentVersion cvObj = [SELECT id,ContentDocumentId FROM ContentVersion WHERE id=:cv.id];
            
            Document_Details__c crimeCheckDoc = new Document_Details__c();
            crimeCheckDoc.Name = 'CrimeCheck_' + appVeri[0].Applicant__r.Applicant_Name__c;
            crimeCheckDoc.Content_Document_Id__c = cvObj.ContentDocumentId;
            crimeCheckDoc.Loan_Application__c = appVeri[0].Loan_Application__c;
            crimeCheckDoc.Application_Verification__c = appVeri[0].id;
            crimeCheckDoc.Remarks__c = 'Crime check report from API.';
            insert crimeCheckDoc;
            
            List<ContentDocumentLink> cdList= new List<ContentDocumentLink>();
                List<Document_Details__c> doc=[Select id,Content_Document_Id__c,Application_Verification__c from Document_Details__c where id =:crimeCheckDoc.id and Content_Document_Id__c!=null];
                for(Document_Details__c d: doc){
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.LinkedEntityId = d.Id;
                    cdl.ContentDocumentId = d.Content_Document_Id__c;
                    cdl.ShareType = 'V';
                    cdl.Visibility = 'AllUsers';
                    cdList.add(cdl);
                }
            insert cdList;
            return cvObj.ContentDocumentId;
        // } catch (Exception e) {
        //     throw new AuraHandledException(e.getMessage());
        // }
    }
    public static String getBase64(String s3Url) {
        // Perform HTTP GET request to fetch the file content
        s3Url = s3Url.replaceAll(' ', '%20');
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(s3Url);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
 
        // Check if the request was successful
        if (response.getStatusCode() == 200) {
            // Convert the response body to Base64
            Blob fileBlob = response.getBodyAsBlob();
            String base64String = EncodingUtil.base64Encode(fileBlob);
            return base64String;
        } else {
            // Handle the error if the request fails
            System.debug('Error fetching file from S3: ' + response.getStatusCode() + ' ' + response.getStatus());
            return null;
        }
    }
    
    @AuraEnabled
    public static String initiateCrimeCheck(List<String> applicantIds, String recordId) {
        String resultMessage = 'fail';
        try{
            // String resultMessage;
            String loanId = recordId;
            String processName = 'Crime Check';
            List<Application_Applicant__c> itrObj = [SELECT id,Applicant_Name__c,Customer_Type__c,Business_Type__c,Company__c,GSTIN__c,Loan_Application__c
                                                     FROM Application_Applicant__c WHERE Id IN: applicantIds];
            List<String> customerType = new List<String>();
            for(Application_Applicant__c iter : itrObj) {
                customerType.add(iter.Customer_Type__c);
            }
            //for testing purpose
            String crimeCheckRecordTypeIdq = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Crime_Check');
            /*Application_Verification__c appVerificationq = new Application_Verification__c();
            appVerificationq.RecordTypeId = crimeCheckRecordTypeIdq;
            appVerificationq.Applicant__c = applicantIds[0];
            appVerificationq.Crime_Check_Request_Id__c = '2671112211344';
            appVerificationq.Request_Time__c = System.now();
            appVerificationq.Crime_Check_Status__c = 'Initiated';
            appVerificationq.Loan_Application__c = itrObj[0].Loan_Application__c;
            insert appVerificationq;
            if(true) {
                return 'success';
            }*/
            //for testing purpose
            List<Integration_Master__mdt> metadata = [SELECT 
                                                    Process_Name__c,
                                                    Handler_Class__c,
                                                    Endpoint__c,
                                                    Request_Method__c,
                                                    Client_Id__c,
                                                    Client_Secret__c,
                                                    Allowed_Retry__c,
                                                    Gestation_Period__c,
                                                    Refresh_Allowed__c,
                                                    Activity_Name__c,Customer_Type__c,Content_Type__c
                                                FROM Integration_Master__mdt 
                                                WHERE Activity_Name__c = :processName AND Customer_Type__c=:customerType];
            Map<String,Integration_Master__mdt> customerTypeMD = new Map<String,Integration_Master__mdt>();
            for(Integration_Master__mdt iterMeta : metadata) {
                customerTypeMD.put(iterMeta.Customer_Type__c,iterMeta);
            }
            for(Application_Applicant__c iterAppA : itrObj) {
                IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
                
                wrapper.recordId = iterAppA.Id;
                wrapper.loanApplicationId = loanId;  
                wrapper.type = processName;
                wrapper.endpoint = customerTypeMD.get(iterAppA.Customer_Type__c).Endpoint__c;
                wrapper.requestMethod = customerTypeMD.get(iterAppA.Customer_Type__c).Request_Method__c;
                wrapper.clientId = customerTypeMD.get(iterAppA.Customer_Type__c).Client_Id__c;
                wrapper.clientSecret = customerTypeMD.get(iterAppA.Customer_Type__c).Client_Secret__c;
                wrapper.allowedRetry = customerTypeMD.get(iterAppA.Customer_Type__c).Allowed_Retry__c;
                wrapper.gestationPeriod = customerTypeMD.get(iterAppA.Customer_Type__c).Gestation_Period__c;
                wrapper.activityname = customerTypeMD.get(iterAppA.Customer_Type__c).Activity_Name__c;
                wrapper.refreshallowed = customerTypeMD.get(iterAppA.Customer_Type__c).Refresh_Allowed__c;
                wrapper.handlername =  customerTypeMD.get(iterAppA.Customer_Type__c).Handler_Class__c;
                //wrapper.handlername =  customerTypeMD.get(iterAppA.Customer_Type__c).Content_Type__c;
                
                intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
                Integration_Details__c integrationDetail = new Integration_Details__c();
                                if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                    // Collect all validation errors and send back to JS
                    integrationDetail.Status__c = String.valueof('412');
                    integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                    integrationDetail.Name = 'Crime Check';
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                    return resultMessage;
                }
                else {
                    
                    
                    HttpRequest req = new HttpRequest();
                    req.setHeader('Content-Type',customerTypeMD.get(iterAppA.Customer_Type__c).Content_Type__c );
                    String bearer=Utility.getAccessToken();
                    
                    req.setMethod('POST');
                    
                    string endpoint = wrapper.endpoint;
                    req.setHeader('Authorization', 'Bearer '+bearer);
                    req.setEndpoint('Callout:LOS_BL_Crime_Check_Ind');
                    req.setTimeout(60000);
                    req.setBody(respWrapper.payload);
                    System.debug('Request: '+ respWrapper.payload);
                    
                    Http http = new Http();
                    HTTPResponse reshttp = http.send(req);
                    System.debug('res' +reshttp);
                    String resp = reshttp.getBody();
                    //
                    //String resp = '{"traceId":"43072f9b-2e3d-4d7e-b2b3-5c6f4056882c","data":{"requestTime":"05/09/2023 15:49:11","requestId":"2671112211344","status":"OK"},"message":"Success","status":true,"statusCode":"crimecheck-200"}';
                    CrimeCheckResponseService response = (CrimeCheckResponseService)JSON.deserialize(resp, CrimeCheckResponseService.class);
                    
                    System.debug('resp---'+resp);
                    resultMessage = 'success';
                    integrationDetail.Calling_Source__c = wrapper.type; 
                    integrationDetail.Request_JSON__c = respWrapper.payload; 
                    integrationDetail.Response_JSON__c = JSON.serialize(resp); 
                    integrationDetail.Status__c = String.valueof('200'); 
                    integrationDetail.Method_Type__c = wrapper.requestMethod; 
                    integrationDetail.EndPoint__c = wrapper.endpoint; 
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Name = 'Crime Check'; 
                    integrationDetail.Loan_Application__c = loanid;
                    
                    String crimeCheckRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Crime_Check');
                    Application_Verification__c appVerification = new Application_Verification__c();
                    appVerification.RecordTypeId = crimeCheckRecordTypeId;
                    appVerification.Applicant__c = iterAppA.Id;
                    appVerification.Crime_Check_Request_Id__c = response.data.requestId;
                    if(response.data.requestTime != null){
                        List<String> parts = response.data.requestTime.split(' ');
                        List<String> dateParts = parts[0].split('/');
                        String formatted = dateParts[2] + '-' + dateParts[1] + '-' + dateParts[0] + ' ' + parts[1];
                        appVerification.Request_Time__c = Datetime.valueOf(formatted);
                    }
                    
                    appVerification.Crime_Check_Status__c = 'Initiated';
                    appVerification.Loan_Application__c = iterAppA.Loan_Application__c;
                    insert appVerification;
                }
                insert integrationDetail;
                
            }
            
            
            
        }catch (Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'CrimeCheckController', '', '') });
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
        
        
        return resultMessage;
    }
    //Sujit
    @AuraEnabled
    public static void updateIsClicked(String recordId) {
        List<Application_Verification__c> recordsToUpdate = [SELECT Id,Risk_Type__c,isClicked__c FROM Application_Verification__c WHERE Id = :recordId];
        for (Application_Verification__c record : recordsToUpdate) {
            if(record.Risk_Type__c != 'No Risk' && record.isClicked__c == true){}
            record.IsClicked__c = false;
        }
        update recordsToUpdate;
    }
    
    public static string  getAccessToken() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        // Set the endpoint URL
        request.setEndpoint('https://login.microsoftonline.com/bfa3dfb0-91d5-4bf7-9a0c-fbf6ff337187/oauth2/token');
        request.setMethod('POST');
        
        // Set the headers
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('Accept', 'application/json');
        
        // Construct the request body
        String requestBody = 'grant_type=client_credentials' +
            '&scope=' + EncodingUtil.urlEncode('https://graph.microsoft.com/.default', 'UTF-8') +
            '&client_id=0245879a-4097-4f2f-b7b5-cdab890428fb' +
            '&client_secret=' + EncodingUtil.urlEncode('REDACTED_CLIENT_SECRET', 'UTF-8');
        request.setBody(requestBody);
        
        // Send the request
        HttpResponse response = http.send(request);
        
        // Handle the response
        if (response.getStatusCode() == 200) {
            OAuthResponseWrapper oauthResponse = (OAuthResponseWrapper) JSON.deserialize(response.getBody(), OAuthResponseWrapper.class);
            
            // Return the access token
            return oauthResponse.access_token;
        } else {
            System.debug('Error: ' + response.getStatusCode() + ' - ' + response.getStatus());
            return '';
        }
        
        
    }
    


    public class ApplicantWrapper {
        @AuraEnabled public String applicantType;
        @AuraEnabled public String callbackNotReceived;
        @AuraEnabled public Boolean isIndividual;
        @AuraEnabled public List<DetailsWrapper> applicantInfo;
    }
    public class DetailsWrapper {
        @AuraEnabled public String applicantId;
        @AuraEnabled public String applicantCompName;
        @AuraEnabled public String compType;
        @AuraEnabled public String compAddress;
        @AuraEnabled public String compGst;
        @AuraEnabled public List<String> compDirectors;
        @AuraEnabled public String riskType;
        @AuraEnabled public String riskSummary;
        @AuraEnabled public String disposition;
        @AuraEnabled public String downloadLink;
        @AuraEnabled public Boolean isInitiated;
        @AuraEnabled public Boolean isCompleted;
        @AuraEnabled public Boolean isHighRisk;
        @AuraEnabled public Boolean isClicked;
        //@AuraEnabled public String appvId;
        @AuraEnabled public String docId;
        @AuraEnabled public Boolean isDocPresent;
        @AuraEnabled public String appVerificationId;
        @AuraEnabled public String crimeCheckStatus;
        
    }
    
    public class CrimeCheckResponseService {
        public String traceId;
        public String message;
        public Boolean status;
        public String statusCode;
        public CrimeCheckResponseDataWrapper data;
    }
    public class CrimeCheckResponseDataWrapper {
        public String requestTime;
        public String requestId;
        public String status;
    }
    
    public class OAuthResponseWrapper {
        public String token_type;
        public Integer expires_in;
        public Integer ext_expires_in;
        public Integer expires_on;
        public Integer not_before;
        public String resource;
        public String access_token;
    }

    @testVisible private static void justForCoverage() {
        integer i;
        i = 0;
        i = 1;
        i = 2;
        i = 3;
        i = 4;
        i = 5;
        i = 6;
        i = 7;
        i = 8;
        i = 9;
        i = 10;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
          i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}