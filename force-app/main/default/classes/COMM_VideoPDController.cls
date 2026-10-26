public class COMM_VideoPDController {
    @AuraEnabled(cacheable=true)
    public static List<String> getPicklistValuesForDisposition() {
        List<String> picklistValues = new List<String>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get('Application_Verification__c');
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get('Crime_Check_Status__c').getDescribe();
        List<Schema.PicklistEntry> values = fieldDescribe.getPicklistValues();

        for (Schema.PicklistEntry val : values) {
            if (val.isActive()) {
                picklistValues.add(val.getLabel()); // Or use val.getValue() for API values
            }
        }
        return picklistValues;
    }
	@AuraEnabled
    public static RecordWrapper getApplicantData(String applicantId) {
        RecordWrapper resWrap = new RecordWrapper();
        List<Application_Applicant__c> itrObj = [SELECT id,Applicant_Name__c,Email__c,Mobile_Number__c
                                                     FROM Application_Applicant__c WHERE id =: applicantId];
        if(itrObj.size() > 0) {
            List<User> currentUser = [SELECT Id, Name, MobilePhone FROM User WHERE Id = :UserInfo.getUserId()];
            resWrap.applicantName = itrObj[0].Applicant_Name__c;
            resWrap.cmEmail = UserInfo.getUserEmail();
            resWrap.applicantMobileNumber = itrObj[0].Mobile_Number__c;
            resWrap.applicantEmail = itrObj[0].Email__c;
            resWrap.cmName = currentUser[0].Name;
            resWrap.cmMobileNumber = currentUser[0].MobilePhone != null ? String.valueOf(currentUser[0].MobilePhone): '';
            if(String.isNotBlank(resWrap.cmMobileNumber)){
                resWrap.cmMobileNumber = resWrap.cmMobileNumber.replaceAll('[^0-9]', '');
            }
        }
        return resWrap;
    }
    public class RecordWrapper {
        @AuraEnabled public String applicantName;
        @AuraEnabled public String cmEmail;
        @AuraEnabled public String applicantMobileNumber;
        @AuraEnabled public String applicantEmail;
        @AuraEnabled public String cmName;
        @AuraEnabled public String cmMobileNumber;
    }

    public class DetailsWrapper {
        @AuraEnabled public String applicantId;
        @AuraEnabled public String applicantName;
        @AuraEnabled public String applicantType;
        @AuraEnabled public String disposition;
        @AuraEnabled public String pdStatus;
        @AuraEnabled public String pdNotes;
        @AuraEnabled public String videoCallRecordings;
        @AuraEnabled public String audioCallRecordings;
        @AuraEnabled public String joinChat;
        @AuraEnabled public String reTrigger;
        @AuraEnabled public String cmdisposition;
        @AuraEnabled public String verifId= '';
        @AuraEnabled public Boolean enableNotes=false;
        @AuraEnabled public Boolean enablecmDisposition=false;
        @AuraEnabled public Boolean isCompleted=false;
        @AuraEnabled public String applicationVerificationId;
        @AuraEnabled public String callstatus;
        @AuraEnabled public DateTime startTime;
        @AuraEnabled public DateTime endTime;
        @AuraEnabled public String callDuration;
        @AuraEnabled public String customerType;
        @AuraEnabled public String customerProfile;
    }

    @AuraEnabled
    public static List<DetailsWrapper> getApplicantsInformation( String recordId, String pdType){
        List<DetailsWrapper> applicantDetails = new List<DetailsWrapper>();
        try {
            List<Application_Applicant__c> applicantList = [SELECT id,Applicant_Name__c,Applicant_Type__c
                                                        FROM Application_Applicant__c WHERE Loan_Application__c =: recordId ];
            Map<String,Application_Verification__c> applicantIdAVMap = new Map<String,Application_Verification__c>();
            String pdRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Personal_Discussion');
            List<Application_Verification__c> lstApplicationVerification = [SELECT id,Applicant__c,Applicant__r.Applicant_Name__c,
                                                                        Personal_Discussion_Notes__c,VPD_CM_Disposition__c,Applicant__r.Applicant_Type__c,
                                                                        Applicant_URL__c, Video_PD_CM_URL__c,Crime_Check_Status__c,Video_PD_Call_Recording_URL__c,Any_Remarks_Reasons__c,
                                                                        Disposition__c,Call_Status__c,CreatedDate,Completion_Date__c,Call_Duration__c,Applicant__r.Customer_Type__c,
                                                                        Applicant__r.Customer_Profile__c
                                                                        FROM Application_Verification__c 
                                                                        WHERE Loan_Application__c =: recordId AND
                                                                       recordTypeId =: pdRecordTypeId AND Personal_Discussion_Type__c = :pdType] ;
            if(lstApplicationVerification.size() > 0) {
                Map<String,String> appVerTODocId = new Map<String,String>();
                Map<String,String> appVerToDownDocId = new Map<String,String>();
					List<Document_Details__c> doclSt = [SELECT id,Content_Document_Id__c,Application_Verification__c FROM Document_Details__c WHERE Application_Verification__c IN:lstApplicationVerification];
                    if(doclSt.size() > 0) {
                        for(Document_Details__c iterDos : doclSt) {
                            appVerTODocId.put(iterDos.Content_Document_Id__c,iterDos.Application_Verification__c);
                        }
                    }
                    if(appVerTODocId.size() > 0) {
                        List<ContentDistribution> downloadLink = [SELECT id,DistributionPublicUrl,ContentDocumentId,ContentDownloadUrl FROM ContentDistribution where ContentDocumentId IN:appVerTODocId.keySet()];
                        if(downloadLink.size() > 0) {
                            for(ContentDistribution conIter : downloadLink) {
                                appVerToDownDocId.put(appVerTODocId.get(conIter.ContentDocumentId),conIter.ContentDownloadUrl);
                            }
                        }   
                    }
                for(Application_Verification__c iterAP : lstApplicationVerification) {
                    DetailsWrapper detWrap = new DetailsWrapper();
                    detWrap.applicantId = iterAP.Applicant__c;
                    detWrap.applicantName = iterAP.Applicant__r.Applicant_Name__c;
                    detWrap.applicantType = iterAP.Applicant__r.Applicant_Type__c;
                    detWrap.customerType =  iterAP.Applicant__r.Customer_Type__c;
                    detWrap.customerProfile = iterAP.Applicant__r.Customer_Profile__c;
                    detWrap.disposition = 'disposition';
                    detWrap.pdStatus = iterAP.Crime_Check_Status__c; 
                    detWrap.enableNotes= true;
                    detWrap.verifId= iterAP.Id;
                    detWrap.pdNotes = iterAP.Any_Remarks_Reasons__c != null ? iterAP.Any_Remarks_Reasons__c : '';
                    detWrap.enablecmDisposition= true;
                    detWrap.cmdisposition = iterAP.Disposition__c != null ? iterAP.Disposition__c : '';
                    detWrap.joinChat = iterAP.Video_PD_CM_URL__c;
                    detWrap.reTrigger = iterAP.Applicant_URL__c;
                    detWrap.startTime = iterAP.CreatedDate;
                    detWrap.videoCallRecordings = iterAP.Video_PD_Call_Recording_URL__c;
                    detWrap.audioCallRecordings = '';
                    detWrap.applicationVerificationId = iterAP.id;
                    if(appVerToDownDocId.containsKey(iterAP.id) && pdType == 'Tele PD') {
                        detWrap.audioCallRecordings = appVerToDownDocId.get(iterAP.id);
                        detWrap.callstatus = iterAP.Call_Status__c != null ? iterAP.Call_Status__c : '';
                        
                        detWrap.endTime = iterAP.Completion_Date__c != null ? iterAP.Completion_Date__c : null;
                        detWrap.callDuration = '';
                        if(iterAP.Call_Duration__c != null) {
                            Integer minutes = Integer.valueOf(iterAP.Call_Duration__c / 60);
                            Integer remainingSeconds = math.mod(Integer.valueOf(iterAP.Call_Duration__c), 60);
                            String callDurationStr = String.valueOf(minutes) +':'+String.valueOf(remainingSeconds);
                            detWrap.callDuration = callDurationStr;
                        }
                    }
                    if(iterAP.Crime_Check_Status__c == 'Completed') {
                        detWrap.isCompleted = true;
                    }
                    applicantDetails.add(detWrap);
                }
            }
            return applicantDetails;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getDownloadLink(String verificationId){
        String downloadLink='';
        try {
            List<Application_Verification__c> appVerification= [SELECT Id, Loan_Application__c, Tele_PD_Call_Recording_URL__c FROM Application_Verification__c WHERE Id = :verificationId];
            if(appVerification.size()>0 && appVerification[0].Tele_PD_Call_Recording_URL__c != null){
                Blob base64 = getAudioRecording(appVerification[0].Tele_PD_Call_Recording_URL__c);
                if(base64 != null) {
                    ContentVersion contentVersion = new ContentVersion();
                    contentVersion.Title = 'MyAudioFile.mp3';
                    contentVersion.PathOnClient = 'MyAudioFile.mp3'; // File name with extension
                    contentVersion.VersionData = base64;
                    contentVersion.IsMajorVersion = true;
                    insert contentVersion;
                    ContentVersion cvObj = [SELECT id,ContentDocumentId FROM ContentVersion WHERE id=:contentVersion.id];
                    
                    Document_Details__c crimeCheckDoc = new Document_Details__c();
                    crimeCheckDoc.Name = 'TelePD';
                    crimeCheckDoc.Content_Document_Id__c = cvObj.ContentDocumentId;
                    crimeCheckDoc.Loan_Application__c = appVerification[0].Loan_Application__c;
                    crimeCheckDoc.Application_Verification__c = appVerification[0].id;
                    crimeCheckDoc.Remarks__c = 'TelePD call recording.';
                    insert crimeCheckDoc;
                    //
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
                    ContentDistribution newDist = new ContentDistribution();
                    newDist.ContentVersionId = cvObj.id;
                    newDist.Name = 'External Link';
                    newDist.PreferencesNotifyOnVisit = false;
                    newDist.PreferencesAllowViewInBrowser = true;
                    newDist.PreferencesAllowOriginalDownload=true;
                    insert newDist;

                    downloadLink = newDist.Id;
                }
            }
        } catch (Exception e) {
            // throw new AuraHandledException(e.getMessage());
            System.debug('Error in getContent version----'+e.getMessage());
        }
        return downloadLink;
    }

    public static Blob getAudioRecording(String recodingUrl){
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        // Set the endpoint URL (Replace with your API URL)
        request.setEndpoint(recodingUrl);
        request.setMethod('GET'); 
        request.setHeader('Authorization', 'Basic NTMxMjYwNjJlMTAyNWExY2Q5MzlhYjMxMmQ4NmQ0MzE0OWZhOGVhNjBkNDI3N2NhOjI1YTY4NTU1NDk3OWU5YjZhMzU4NTdjMDJmYzVkMTU3MDM3ZTkyNzg2NmJmZmNlNg==');
        HttpResponse response = http.send(request);
        
        // Process the response
        if (response.getStatusCode() == 200) {
            System.debug('Response Body: ' + response.getBody());
            return response.getBodyAsBlob();
        } else {
            System.debug('Error: ' + response.getStatusCode() + ' - ' + response.getBody());
            return null;
        }
    }

        @AuraEnabled
    	public static String initiateVideoPD(String applicantId, String loanId,String applicantEmail) {
        	String res = 'fail';
            String resultMessage; 
            String processName = 'Trigger Video PD';
            Application_Applicant__c itrObj = [SELECT id,Applicant_Name__c,Email__c,Mobile_Number__c,Loan_Application__r.Name
                                               FROM Application_Applicant__c WHERE id =: applicantId];
            List<Integration_Master__mdt> metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,
                                                      Refresh_Allowed__c,Activity_Name__c,Customer_Type__c,Content_Type__c FROM Integration_Master__mdt WHERE Activity_Name__c = :processName];
            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
            wrapper.recordId = itrObj.Id;  
            wrapper.type = processName;
            wrapper.loanApplicationId = loanId;  
            wrapper.endpoint = metadata[0].Endpoint__c;
            wrapper.requestMethod = metadata[0].Request_Method__c;
            wrapper.clientId = metadata[0].Client_Id__c;
            wrapper.clientSecret = metadata[0].Client_Secret__c;
            wrapper.allowedRetry = metadata[0].Allowed_Retry__c;
            wrapper.gestationPeriod = metadata[0].Gestation_Period__c;
            wrapper.activityname = metadata[0].Activity_Name__c;
            wrapper.refreshallowed = metadata[0].Refresh_Allowed__c;
            wrapper.handlername =  metadata[0].Handler_Class__c;
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = 'Trigger Video PD';
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                return resultMessage;
            }
            else {
                User currectUser = [SELECT Email,Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
                String resp;
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('https://uat.videocx.io/ims/users/thirdparty-auth/signin');
                request.setMethod('POST');
                DateTime timestamp = DateTime.now();
                Long epochMillis = timestamp.getTime();
                String epochString = String.valueOf(epochMillis);
                System.debug('epoch --> '+epochString);
                String apiSecret = 'a56d0e83552245ea92c0c0209af65f60';
                String apiKey = '2b14e59f0fbb45d5bc2faee8a7961bd1';
                String path = apiKey + ':' + epochString;
                System.debug('path --> '+path);
                Blob data = crypto.generateMac('HmacSHA256',Blob.valueOf(path),Blob.valueOf(apiSecret));
                String signature = EncodingUtil.base64Encode(data);
                System.debug('signature --> '+signature);
                request.setHeader('client-id', '101');
                request.setHeader('Content-Type', 'application/json');
                request.setHeader('x-request-id', '839b7481-cc04-4229-84b1-4575df6f358b');
                request.setHeader('apiKey', '2b14e59f0fbb45d5bc2faee8a7961bd1');
                request.setHeader('timestamp', epochString);
                request.setHeader('signature', signature);
                request.setTimeout(30000);
                request.setBody(respWrapper.payload);
                HttpResponse httpResponse = http.send(request);
                VideoPDResponseWrapper response;
                if (httpResponse.getStatusCode() == 200) {
                    System.debug('Response: ' + httpResponse.getBody());
                    resp = httpResponse.getBody();
                    response = (VideoPDResponseWrapper)JSON.deserialize(resp, VideoPDResponseWrapper.class);
                    Map<String,String> inputMap = new Map<String,String>();
                    EmailTemplate emailTemplate =[SELECT Id, Subject, HtmlValue,Body  FROM EmailTemplate WHERE DeveloperName = 'Video_PD_Applicant_Mail' LIMIT 1];
                    String emailBody =  emailTemplate.HtmlValue;
                    String smsBody =  emailTemplate.Body;
                    Map<String,String> inputMapURL=new Map<String,String> ();
                    inputMapURL.put('s3link',response.customerUrl+'?lanNo='+EncodingUtil.convertToHex(Blob.valueOf(itrObj.Id))+epochString);
                    inputMapURL.put('processName','Loan URL Shortening Service');
                    inputMapURL.put('recordId',itrObj.Id);
                    inputMapURL.put('loanId', loanId);
                    String shortUrl=URLShorteningController.urlShoetening(inputMapURL);
                    if(shortUrl.contains('Error:')) {
                        res = shortUrl;
                    }
                    else {
                        URLShorteningController.URLShorteningResponseServiceWrapper urlRespWrapper = 
                            (URLShorteningController.URLShorteningResponseServiceWrapper) JSON.deserialize(
                                shortUrl,URLShorteningController.URLShorteningResponseServiceWrapper.class);
                        shortUrl = urlRespWrapper.data.short_link_with_domain;
                        emailBody = emailBody.replace('{loanLink}', shortUrl);
                        smsBody = smsBody.replace('{loanLink}', shortUrl);
                        inputMap.put('content',emailBody) ;
                        inputMap.put('subject','Godrej Capital | '+itrObj.Loan_Application__r.Name+' | VPD call invitation') ;
                        inputMap.put('email', applicantEmail);
                        inputMap.put('loanId', loanId);
                        inputMap.put('processName','Email');
                        inputMap.put('applicantId',applicantId);
                        EmailController.initiateAPIRequest(inputMap);
                        resultMessage = 'Success';
                        integrationDetail.Calling_Source__c = wrapper.type; 
                        integrationDetail.Request_JSON__c = respWrapper.payload; 
                        integrationDetail.Response_JSON__c = JSON.serialize(resp); 
                        System.debug('181 intttt'+ integrationDetail.Response_JSON__c);
                        integrationDetail.Status__c = String.valueof('200'); 
                        integrationDetail.Method_Type__c = wrapper.requestMethod; 
                        integrationDetail.EndPoint__c = wrapper.endpoint; 
                        integrationDetail.Object_Name__c = 'Application_Applicant__c';
                        integrationDetail.Name = 'TriggerVideo PD'; 
                        String pdRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Personal_Discussion');
                        Application_Verification__c appVerification = new Application_Verification__c();
                        appVerification.RecordTypeId = pdRecordTypeId;
                        appVerification.Applicant__c = itrObj.Id;
                        appVerification.Loan_Application__c =loanId;
                        appVerification.Applicant_URL__c = response.customerUrl+'?lanNo='+EncodingUtil.convertToHex(Blob.valueOf(itrObj.Id))+epochString;
                        appVerification.Video_PD_CM_URL__c = response.userRedirectUrl;
                        appVerification.Shorten_URL__c = shortUrl;
                        appVerification.Personal_Discussion_Type__c = 'Video PD';
                        appVerification.Request_Time__c = System.now();
                        appVerification.Crime_Check_Status__c = 'Initiated';
                        insert appVerification;
                        res = 'success';
                    }
                } else {
                    System.debug('Error: ' + httpResponse.getStatusCode() + ' - ' + httpResponse.getStatus());
                    res = httpResponse.getBody();
                    integrationDetail.Calling_Source__c = wrapper.type; 
                    integrationDetail.Request_JSON__c = respWrapper.payload; 
                    integrationDetail.Response_JSON__c = res; 
                    integrationDetail.Status__c = String.valueof(httpResponse.getStatusCode()); 
                    integrationDetail.Method_Type__c = wrapper.requestMethod; 
                    integrationDetail.EndPoint__c = wrapper.endpoint; 
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Name = 'TriggerVideo PD'; 
                }
            }
            insert integrationDetail;
        return res;
    }

    @AuraEnabled
    public static String sendMailForVPD(String applicantId, String loanId,String applicantEmail) {
        String res = 'fail';
        Application_Applicant__c itrObj = [SELECT id,Applicant_Name__c,Email__c,Mobile_Number__c,Loan_Application__r.Name
        FROM Application_Applicant__c WHERE id =: applicantId];
        String pdRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Personal_Discussion');
        Application_Verification__c appVer = [SELECT id,Applicant_URL__c,Shorten_URL__c FROM Application_Verification__c WHERE RecordTypeId =:pdRecordTypeId AND Applicant__c =:applicantId AND Personal_Discussion_Type__c = 'Video PD' order by CreatedDate desc limit 1];
        EmailTemplate emailTemplate =[SELECT Id, Subject, HtmlValue,Body  FROM EmailTemplate WHERE DeveloperName = 'Video_PD_Applicant_Mail' LIMIT 1];
        Map<String,String> inputMap = new Map<String,String>();
        if(String.isNotBlank(appVer.Shorten_URL__c)) {        
            String emailBody =  emailTemplate.HtmlValue;      
            emailBody = emailBody.replace('{loanLink}', appVer.Shorten_URL__c);    
            inputMap.put('content',emailBody) ;
            inputMap.put('subject','Godrej Capital | '+itrObj.Loan_Application__r.Name+' | VPD call invitation') ;
            inputMap.put('email', applicantEmail);
            inputMap.put('loanId', loanId);
            inputMap.put('processName','Email');
            inputMap.put('applicantId',applicantId);
            EmailController.initiateAPIRequest(inputMap);
            res = 'success';
        }
        else {
            String emailBody =  emailTemplate.HtmlValue;
            Map<String,String> inputMapURL=new Map<String,String> ();
            inputMapURL.put('s3link',appVer.Applicant_URL__c);
            inputMapURL.put('processName','Loan URL Shortening Service');
            inputMapURL.put('recordId',applicantId);
            inputMapURL.put('loanId', loanId);
            String shortUrl=URLShorteningController.urlShoetening(inputMapURL);
            if(shortUrl.contains('Error:')) {
                res = shortUrl;
            }else {
                URLShorteningController.URLShorteningResponseServiceWrapper urlRespWrapper =(URLShorteningController.URLShorteningResponseServiceWrapper) JSON.deserialize(
                        shortUrl,URLShorteningController.URLShorteningResponseServiceWrapper.class);
                emailBody = emailBody.replace('{loanLink}', urlRespWrapper.data.short_link_with_domain);
                inputMap.put('content',emailBody) ;
                inputMap.put('subject','Godrej Capital | '+itrObj.Loan_Application__r.Name+' | VPD call invitation') ;
                inputMap.put('email', applicantEmail);
                inputMap.put('loanId', loanId);
                inputMap.put('processName','Email');
                inputMap.put('applicantId',applicantId);
                EmailController.initiateAPIRequest(inputMap);
                appVer.Shorten_URL__c = urlRespWrapper.data.short_link_with_domain;
                update appVer;
                res = 'success';
            }
        }
        return res;
    }

    @AuraEnabled
    public static String sendSMSForVPD(String applicantId, String loanId) {
        String res = 'fail';
        Application_Applicant__c itrObj = [SELECT id,Applicant_Name__c,Email__c,Mobile_Number__c,Loan_Application__r.Name
        FROM Application_Applicant__c WHERE id =: applicantId];
        String pdRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Personal_Discussion');
        Application_Verification__c appVer = [SELECT id,Applicant_URL__c,Shorten_URL__c FROM Application_Verification__c WHERE RecordTypeId =:pdRecordTypeId AND Applicant__c =:applicantId AND Personal_Discussion_Type__c = 'Video PD' order by CreatedDate desc limit 1];
        EmailTemplate emailTemplate =[SELECT Id, Subject, HtmlValue,Body  FROM EmailTemplate WHERE DeveloperName = 'Video_PD_Applicant_Mail' LIMIT 1];
        String smsBody =  emailTemplate.Body;
        if(String.isNotBlank(appVer.Shorten_URL__c)) {
            smsBody = smsBody.replace('{loanLink}', appVer.Shorten_URL__c);
            SMSRequestService.sendSMS(new List<String> { itrObj.Mobile_Number__c },smsBody,'Salesforce');
            res = 'success';
        }
        else {
            Map<String,String> inputMapURL=new Map<String,String> ();
            inputMapURL.put('s3link',appVer.Applicant_URL__c);
            inputMapURL.put('processName','Loan URL Shortening Service');
            inputMapURL.put('recordId',applicantId);
            inputMapURL.put('loanId', loanId);
            String shortUrl=URLShorteningController.urlShoetening(inputMapURL);
            if(shortUrl.contains('Error:')) {
                res = shortUrl;
            }else {
                URLShorteningController.URLShorteningResponseServiceWrapper urlRespWrapper = (URLShorteningController.URLShorteningResponseServiceWrapper) JSON.deserialize(
                        shortUrl,URLShorteningController.URLShorteningResponseServiceWrapper.class);
                smsBody = smsBody.replace('{loanLink}', urlRespWrapper.data.short_link_with_domain);
                SMSRequestService.sendSMS(new List<String> { itrObj.Mobile_Number__c },smsBody,'Salesforce');
                appVer.Shorten_URL__c = urlRespWrapper.data.short_link_with_domain;
                update appVer;
                res = 'success';
            }
        }
        return res;
    }
    
    public class VideoPDResponseWrapper{
        public String userRedirectUrl;	
        public String customerUrl;
    }

    @AuraEnabled
    public static Boolean savePDNotes( String appVerifId, String notes){
        Boolean res= false;
        try {
            Application_Verification__c appVerif= new Application_Verification__c();
            appVerif.Id = appVerifId;
            appVerif.Any_Remarks_Reasons__c = notes;
            update appVerif;
            res= true;
        } catch (Exception e) {
            System.debug('Error in savePDNotes--'+e.getMessage()+'StackTrace--'+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        return res;
    }

    @AuraEnabled
    public static Boolean saveCMDispostion( String appVerifId, String cmDisposition){
        Boolean res= false;
        try {
            Application_Verification__c appVerif= new Application_Verification__c();
            appVerif.Id = appVerifId;
            appVerif.Disposition__c = cmDisposition;
            update appVerif;
            res= true;
        } catch (Exception e) {
            System.debug('Error in savePDNotes--'+e.getMessage()+'StackTrace--'+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        return res;
    }
}