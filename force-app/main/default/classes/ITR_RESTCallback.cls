@RestResource(urlMapping='/api/itr-callback')
global with sharing class ITR_RESTCallback {

    @HttpPost
    global static String updateExotelCallback() {
        String status = 'fail';
        RestRequest restReq = RestContext.request;
        System.debug('restReq '+restReq.requestBody);
        String requestBody = restReq.requestBody.toString();
        System.debug('requestBody '+requestBody);
        //handle 2 callback with condition
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        if (payload.containsKey('traceId')) {
            status = handleFileRequestSuccessCallback(requestBody);
        } else {
            status = handleSuccessCallback(requestBody);
        }
        
        
        return status;
    }
    
    public static String handleFileRequestSuccessCallback(String requestBody) {
        String status = '';
        RequestReceivedCallback response = (RequestReceivedCallback)JSON.deserialize(requestBody, RequestReceivedCallback.class);
        System.debug('responseOOO '+response);
        Integration_Details__c integrationDetail = new Integration_Details__c();
        integrationDetail.Name = 'ITR Request Success';
        integrationDetail.Object_Name__c = 'Application_Applicant__c';
        integrationDetail.EndPoint__c = 'NA'; 
        if(response.status) {
            
            List<Integration_Details__c> requestData = [SELECT id,Related_Record_Id__c,Loan_Application__c FROM
                                                        Integration_Details__c WHERE Customer_Id__c =:response.data.transactionId LIMIT 1];
            if(requestData.size() > 0) {
                integrationDetail.Related_Record_Id__c = requestData[0].Related_Record_Id__c;
            	integrationDetail.Loan_Application__c = requestData[0].Loan_Application__c;
                
            
            }else {
                return 'No request record found.';
            }
            integrationDetail.Status__c = '200';
            
            
            integrationDetail.Response_JSON__c = JSON.serialize(response);
            
        }else {
            integrationDetail.Status__c = '400';
        }
        insert integrationDetail;
        //save integartion record with name ITRResponse
        //Integration
        return status;
    }
    
    public static String handleSuccessCallback(String requestBody) {
        String status = '';
        ITR_RESTCallback response = (ITR_RESTCallback)JSON.deserialize(requestBody, ITR_RESTCallback.class);
        System.debug('responseOOO '+response);
        Integration_Details__c integrationDetail = new Integration_Details__c();
        integrationDetail.Name = 'ITR Response';
        integrationDetail.Object_Name__c = 'Application_Applicant__c';
        integrationDetail.EndPoint__c = 'NA'; 
        if(response.status) {
            
            List<Integration_Details__c> requestData = [SELECT id,Related_Record_Id__c,Loan_Application__c FROM
                                                        Integration_Details__c WHERE Customer_Id__c =:response.data.perfiosTransactionId LIMIT 1];
            if(requestData.size() > 0) {
                integrationDetail.Related_Record_Id__c = requestData[0].Related_Record_Id__c;
            	integrationDetail.Loan_Application__c = requestData[0].Loan_Application__c;
                
            
            }else {
                return 'No request record found.';
            }
            integrationDetail.Status__c = '200';
            
            ContentVersion contVer = new ContentVersion();
            contVer.Title = 'ITR Report';
            contVer.PathOnClient = 'ITRReport.xlsx';
            contVer.VersionData = EncodingUtil.base64Decode(response.data.xlsxByteReport);
            insert contVer;
            ContentVersion cvObj = [SELECT id,ContentDocumentId FROM ContentVersion WHERE id=:contVer.id];
            response.data.xlsxByteReport = '';
            integrationDetail.Response_JSON__c = JSON.serialize(response);
            Document_Details__c crimeCheckDoc = new Document_Details__c();
            crimeCheckDoc.Name = 'ITR Report';
            crimeCheckDoc.Content_Document_Id__c = cvObj.ContentDocumentId;
            crimeCheckDoc.Loan_Application__c = requestData[0].Loan_Application__c;
            crimeCheckDoc.Applicant__c = requestData[0].Related_Record_Id__c;
            crimeCheckDoc.Remarks__c = 'ITR excel report.';
            crimeCheckDoc.Status__c = 'Uploaded';
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
            
            
        }else {
            integrationDetail.Status__c = '400';
        }
        insert integrationDetail;
        //save integartion record with name ITRResponse
        //Integration
        return status;
    }
    
    public cls_data data;
	public boolean status;
	public class cls_data {
		public String lan_id;	//GFL3201BL0009467
		public String xlsxByteReport;	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
		public cls_perfiosCallbackData perfiosCallbackData;
		public cls_jsonReport jsonReport;
		public String clientTransactionId;	//4948ae07-6b73-46b3-b11e-475f3ebfc772
		public List<String> uploadedFile;
		public String perfiosTransactionId;	//PIBLCL4ITJRKPY7KDS5PI
		public String status;	//COMPLETED
	}
	public class cls_perfiosCallbackData {
		public Integer callback_id;	//0
		public String errorCode;	//
		public String clientTransactionId;	//4948ae07-6b73-46b3-b11e-475f3ebfc772
		public String message;	//
		public String perfiosTransactionId;	//PIBLCL4ITJRKPY7KDS5PI
		public String status;	//COMPLETED
	}
	public class cls_jsonReport {
		public cls_itrvDetails itrvDetails;
	}
	public class cls_itrvDetails {
		public cls_itrvInfoList[] itrvInfoList;
		public String sourceOfData;	//Statement Upload
	}
	public class cls_itrvInfoList {
		@AuraEnabled public String originalOrRevised;	//NA
		@AuraEnabled public cls_personalInfo personalInfo;
		@AuraEnabled public cls_incomeDetail incomeDetail;
		@AuraEnabled public String eFilingStatus;	//NA
		@AuraEnabled public String filedus;	//NA
		@AuraEnabled public String financialYear;	//2021-22
		@AuraEnabled public String acknowledgementNumber;	//851274181171222
		@AuraEnabled public String formNumber;	//ITR-6
		@AuraEnabled public String dateOfSubmission;	//2022-12-17
		@AuraEnabled public String dateOfVerification;	//17-Dec-2022
		@AuraEnabled public String assessmentYear;	//2022-23
		@AuraEnabled public String designationOfAO;	//
		@AuraEnabled public String itrVerifiedBy;	//
	}
	public class cls_personalInfo {
		@AuraEnabled public String address;	//15, 3rd Floor , SECTOR 17 , POCKET C-8 , DELHI,DWARKA , 09-Delhi , 91-India , 110075
		@AuraEnabled public String name;	//SPINE INFRATECH PRIVATE LIMITED
		@AuraEnabled public String adhaarNumber;	//NA
		@AuraEnabled public String pan;	//AARCS2320M
		@AuraEnabled public String status;	//Private
	}
	public class cls_incomeDetail {
		@AuraEnabled public String adjTotIncUnderAMT;	//0
		@AuraEnabled public String deductionsUnderChapter6A;	//
		@AuraEnabled public cls_exemptIncome exemptIncome;
		@AuraEnabled public String taxPayable;	//
		@AuraEnabled public String bookProfitUnderMAT;	//631113
		@AuraEnabled public String totalIncome;	//1099200
		@AuraEnabled public String netTaxPayable;	//285792
		@AuraEnabled public String grossTotalIncome;	//
		@AuraEnabled public cls_taxesPaid taxesPaid;
		@AuraEnabled public cls_dividend dividend;
		@AuraEnabled public String totalTaxAndInterestPayable;	//293549
		@AuraEnabled public String currentYearLoss;	//0
		@AuraEnabled public String interestPayable;	//7757
		@AuraEnabled public String refund;	//0
	}
	public class cls_exemptIncome {
		@AuraEnabled public String agriculture;	//
		@AuraEnabled public String others;	//
	}
	public class cls_taxesPaid {
		@AuraEnabled public String selfAssessmentTax;	//
		@AuraEnabled public String tds;	//
		@AuraEnabled public String advanceTax;	//
		@AuraEnabled public String tcs;	//
		@AuraEnabled public String totalTaxPaid;	//293545
	}
	public class cls_dividend {
		public String totIntAndFeesPayable;	//
		public String taxPayableOrRefund;	//
		public String taxPayable;	//
		public String taxesPaid;	//
		public String interestPayable;	//
	}
    
    public class RequestReceivedCallback {
        public String traceId;	//d6f3dc34-091d-4f10-9e97-8e20d15f5683
        public clsData data;
        public String message;	//Transaction Completed
        public boolean status;
        public String statusCode;	//itr-200-3000
    }
    
    
	public class clsData {
		public boolean success;
		public String transactionId;	//PIR3UR206X8M6TVZFAMKN
	}
	
}