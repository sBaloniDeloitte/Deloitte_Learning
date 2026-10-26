@RestResource(urlMapping='/api/crimeCheck')
global class CrimeCheck_REST {
    @HttpPost
    global static String updateCrimeCheck() {
        String status = 'fail';
        RestRequest restReq = RestContext.request;
        System.debug('restReq '+restReq.requestBody);
        String requestBody = restReq.requestBody.toString();
        System.debug('requestBody '+requestBody);
        ResWrap response = (ResWrap)JSON.deserialize(requestBody, ResWrap.class);
        System.debug('responseOOO '+response);
        String reqId = String.valueOf(response.data.requestId);
        System.debug('reqId '+reqId);
        List<Application_Verification__c> appVeri = [SELECT id,Completion_Date__c,Applicant__r.Applicant_Name__c,Loan_Application__c,
                                                     Crimewatch__c,Request_Time__c,Risk_Type__c,Crime_Check_File_Link__c,
                                                     Crime_Check_Request_Id__c,Number_of_Cases__c,Any_Remarks_Reasons__c,Verification_Remarks__c,
                                                     Crime_Check_Status__c, Applicant__c,Disposition__c FROM Application_Verification__c 
                                                     WHERE Crime_Check_Request_Id__c =:reqId];
        if(appVeri.size() > 0) {
            //appVeri[0].Completion_Date__c = Datetime.valueOf(response.responseTime);
            //appVeri[0].Crimewatch__c = response.crimewatch;
            appVeri[0].Crime_Check_Status__c = 'Completed';
            appVeri[0].Completion_Date__c = System.now();
            appVeri[0].Risk_Type__c = response.data.riskType;
            appVeri[0].Any_Remarks_Reasons__c = response.data.disclaimer;
            appVeri[0].Verification_Remarks__c = response.data.riskSummary;
            appVeri[0].Number_of_Cases__c = response.data.numberOfCases;
            appVeri[0].Crime_Check_File_Link__c = response.data.downloadLink;
            /*
            String base64 = getBase64(response.downloadLink);
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
			*/
            //
            ApplicationVerificationTriggerHandler.isTriggerDisabled = true;
            update appVeri;
            ApplicationVerificationTriggerHandler.isTriggerDisabled = false;
            
            status = 'success';
            
        }else {
            status = 'fail';
        }
        return status;
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
    public class ResWrap {
        public cls_data data;
    }
    
	public class cls_data {
		public String responseTime;	//11/09/2025 04:06 pm
		public String riskSummary;	//As per our court records search, there are no cases found against or instituted by the subject.
		public boolean crimewatch;
		public String requestTime;	//11/09/2025 04:05 pm
		public cls_searchTerm[] searchTerm;
		public String riskType;	//No Risk
		public String downloadLink;	//https://crime.getupforchange.com/api/v3/downloadReport/2771136657464/bf993571-f72b-4d82-94f7-78fa60bff53b
		public String requestId;	//2771136657464
		public String lan;	//006C200000F2Kd7IAF
		public cls_caseDetails[] caseDetails;
		public Integer numberOfCases;	//0
		public String disclaimer;	//This report contains information about the Subject in question which has been compiled using data collected from the public domain. This report was generated from a database which contains 25.47 Crore crime records from all courts, Tribunals & Defaulters List across India and 2.7 Crore eFIRs from various state Police department online records. To that effect, the correctness, accuracy, and completeness of this report are directly related to the data available online in the public domain at the time of report generation. This report is not to be treated as advice in any form and the users are advised to carry out necessary due diligence/ verification or to seek proper professional advice as may be necessary on the information provided in this report before taking any decision.
		public String status;	//OK
	}
	public class cls_searchTerm {
		public String fatherName;	//CHANDRA NAUDIYAL
		public String address;	//201020 (Uttar Pradesh)
		public String dob;	//1988-07-01
		public String name;	//SAURABH NAUDIYAL
		public String clientRefNo;	//
	}
	public class cls_caseDetails {
	}

}