@RestResource(urlMapping='/api/exotel-callback')
global with sharing class TelePDAPI_REST {
    
    @HttpPost
    global static String updateExotelCallback() {
        String status = 'fail';
        RestRequest restReq = RestContext.request;
        System.debug('restReq '+restReq.requestBody);
        String requestBody = restReq.requestBody.toString();
        requestBody = requestBody.replace('From','FromNumber');
        System.debug('requestBody '+requestBody);
        TelePdCallbackWrapper response = (TelePdCallbackWrapper)JSON.deserialize(requestBody, TelePdCallbackWrapper.class);
        if(String.isBlank(response.CallSid)) {
            return 'fail';
        }
        List<Application_Verification__c> appVeri = [SELECT id,Tele_PD_Call_Recording_URL__c,Crime_Check_Status__c,Completion_Date__c,
                                                     Applicant__r.Applicant_Name__c,Loan_Application__c
                                                     FROM Application_Verification__c 
                                                     WHERE Crime_Check_Request_Id__c =:response.CallSid];
        if(appVeri.size() > 0 && String.isNotBlank(response.RecordingUrl)) {
            appVeri[0].Tele_PD_Call_Recording_URL__c = response.RecordingUrl; //save this on SF after authentication
            appVeri[0].Crime_Check_Status__c = 'Completed';
            appVeri[0].Completion_Date__c = System.now();
            appVeri[0].Call_Status__c = response.Status;
            Datetime startTime = Datetime.now();
            Integer count = 0;
            while (Datetime.now().getTime() - startTime.getTime() < 1000) {
               
            }
            Blob base64 = getAudioRecording(response.RecordingUrl);
            if(base64 != null) {
                //Blob mp3Blob = base64.getBodyAsBlob();
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
                crimeCheckDoc.Loan_Application__c = appVeri[0].Loan_Application__c;
                crimeCheckDoc.Application_Verification__c = appVeri[0].id;
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
            }
            if(response.Legs.size() > 0) {
                for(cls_Legs legsIter : response.Legs) {
                    if(legsIter.Status == 'completed') {
                        appVeri[0].Call_Duration__c = legsIter.OnCallDuration;
                    }
                }
            }
            update appVeri;
            Refresh_Event__e event = new Refresh_Event__e(
                Loan_Application_Id__c = appVeri[0].Loan_Application__c
            );
            EventBus.publish(event);
            return 'success';
            
        }else {
            status = 'fail';
        }
        
        return status;
    }
    
    public static Blob getAudioRecording(String recodingUrl){
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        // Set the endpoint URL (Replace with your API URL)
        request.setEndpoint(recodingUrl);
        request.setMethod('GET'); 
        request.setHeader('Authorization', 'Basic NTMxMjYwNjJlMTAyNWExY2Q5MzlhYjMxMmQ4NmQ0MzE0OWZhOGVhNjBkNDI3N2NhOjI1YTY4NTU1NDk3OWU5YjZhMzU4NTdjMDJmYzVkMTU3MDM3ZTkyNzg2NmJmZmNlNg==');
        
        // Optionally set request body for POST/PUT calls
        // request.setBody('{"key1":"value1", "key2":"value2"}');
        
        // Send the HTTP request
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
    
    public class TelePdCallbackWrapper{
        public String CallSid;	//492205107c5fb48f4ac25d1f77759339
        public String EventType;	//terminal
        public String DateCreated;	//2019-04-08 03:17:59
        public String DateUpdated;	//2019-04-08 03:18:35
        public String Status;	//no-answer
        public String To;	//+91886799XXXX
        public String FromNumber;	//+91941374XXXX
        public String PhoneNumberSid;	//0113083XXXX
        public String StartTime;	//2019-04-08 03:17:59
        public String EndTime;	//2019-04-08 03:18:36
        public String Direction;	//outbound-api
        public String RecordingUrl;	//https://s3-ap-southeast-1.amazonaws.com/exotelrecordings/<your_sid>/492205107c5fb48f4ac25d1f77759339.mp3
        public Integer ConversationDuration;	//32
        public cls_Legs[] Legs;
        
    }
    public class cls_Legs {
        public Integer OnCallDuration;	//41
        public String Status;	//completed
    }
    
}