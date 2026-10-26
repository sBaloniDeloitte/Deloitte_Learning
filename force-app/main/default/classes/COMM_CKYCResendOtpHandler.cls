/**
* @File Name : CKYCResendOtpHandler.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 1, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 1, 2025 |   | Initial Version
**/

public with sharing class COMM_CKYCResendOtpHandler implements IntegrationInterface {
	static String conLabels = 'CKYC_RESEND_OTP_API';
	public static Map<String, String> constants = Utility.getConstants(conLabels);

	@AuraEnabled
	public static Map<String, String> getConstants() {
		return constants;
	}

	public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) {
		List<String> errorMessages = new List<String>();

		String loanApplicationId = wrapper.loanApplicationId;
		String applicantId = wrapper.recordId;

		if (String.isBlank(applicantId) || String.isBlank(loanApplicationId)) {
			errorMessages.add('Error: Applicant Id or Loan Application Id is missing');
			return errorMessages;
		}

		List<Triangulation_Data__c> records = [SELECT CKYC_Number__c,API_hit_count__c, CKYC_Transaction_Id__c FROM Triangulation_Data__c WHERE Loan_Application__c = :loanApplicationId AND Application_Applicant__c = :applicantId AND Source_Type__c = 'CKYC' LIMIT 1];
		if (records.isEmpty() || String.isBlank(records[0].CKYC_Transaction_Id__c)) {
			errorMessages.add('Error: CKYC Transaction Id is missing');
		}
		/*if(records.size()>0 && records[0].API_hit_count__c!=null){
			Integer countHit =  Integer.valueOf(records[0].API_hit_count__c);
			if (Math.mod(countHit, 3) == 0 && countHit != 0) {
					errorMessages.add('Refresh OTP cannot be hit more than three times. Please re-initiate CKYC');
			} CHECK for this logic
		}*/
		return errorMessages;
	}

	public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
		try {
			String applicantId = wrapper.recordId;
			String loanApplicationId = wrapper.loanApplicationId;

			// Get CKYC Transaction Id
			Triangulation_Data__c data = [SELECT CKYC_Transaction_Id__c FROM Triangulation_Data__c WHERE Loan_Application__c = :loanApplicationId AND Application_Applicant__c = :applicantId AND Source_Type__c = 'CKYC' ORDER BY CreatedDate DESC LIMIT 1];
			Application_Applicant__c applicant = [SELECT ID,Customer_Type__c from Application_Applicant__c WHERE ID =:applicantId];

			// Construct wrapper for A99RequestData
			A99RequestDataWrapper reqWrapper = new A99RequestDataWrapper();
		    reqWrapper.RequestId = String.valueOf(System.currentTimeMillis());
			reqWrapper.ApiToken = Label.CKYC_API_Token;//'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJBcGlTdWJzY3JpcHRpb25JZCI6IjQiLCJUZW5hbnRJZGVudGlmaWVyIjoiODllMjgxMjk5MWJiNDI4NWE0MTc5YmFkYWRhNjZhYTIiLCJBcGlJZCI6IjE4IiwiRW5jcnlwdGlvblByb3ZpZGVySWQiOiIxIiwiQWdlbmN5SWQiOiI4IiwiZXhwIjoxODczNDc3ODAwLCJpc3MiOiJUcmFja3dpenpOZXh0IiwiYXVkIjoidGVuYW50Y2xpZW50Y29uc29sZSJ9.hxQaGH2F4SmEke0kLgT0nB13QB_z3FYdc3x378Senu4';
			reqWrapper.ParentCompany = 'GHFL'; 
			reqWrapper.CKYCTransactionID = data.CKYC_Transaction_Id__c;
			reqWrapper.GetRecordType = applicant!=null ? applicant.Customer_Type__c =='Individual' ? 'IND' : 'LE' : '';  //IND /LE
			reqWrapper.Tags = '';
			reqWrapper.ApplicationFormNo = '';

			// Convert wrapper → JSON → XML
			String jsonStr = JSON.serialize(reqWrapper);
			String xmlBody = JSONTOXMLConvertor.convertJsonToXml(jsonStr, 'A99RequestData');

			// Add namespaces + xml header
			xmlBody = xmlBody.replace(
				'<A99RequestData>',
				'<A99RequestData xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' +
				'xmlns:xsd="http://www.w3.org/2001/XMLSchema">'
			);

			String finalXml = '<?xml version="1.0" encoding="utf-16"?>' + xmlBody;
			String encryptedJson = COMM_CrifEncryptionUtil.prepareEncryptedCrifRequest(finalXml);

			Map<String, String> requestMap = new Map<String, String>();
				requestMap.put('payload', encryptedJson);
				requestMap.put('apiName', 'resendotp');
            String requestJSON = JSON.serialize(requestMap);
            System.debug('Step 14 - Final Request JSON: ' + requestJSON);
            return requestJSON;

		} catch (Exception exp) {
			System.debug('Exception: ' + exp.getMessage());
			Utility.createErrorLogRecord(new List<Error_Logs__c>{
				Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'CreateCKYCPayload', '', '')
			});
			throw new AuraHandledException('An error occurred: ' + exp.getMessage());
		}
	}

	public class A99RequestDataWrapper {
		public String RequestId;
		public String ParentCompany;
		public String ApiToken;
		public String CKYCTransactionID;
		public String GetRecordType;
		public String Tags;
		public String ApplicationFormNo;
	}

}