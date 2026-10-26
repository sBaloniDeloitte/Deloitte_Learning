/**
* @File Name : CKYCSearchAPIHandler.cls
* @Description : CKYC Search API Payload Construction and Validation
* @Author :
* @Last Modified By :
* @Last Modified On : July 31, 2025
* @Modification Log :
*==============================================================================
* Ver | Date       | Author | Modification
*==============================================================================
* 1.0 | July 31, 2025 |        | Initial Version
**/

public with sharing class COMM_CKYCSearchAPIHandler implements IntegrationInterface {
    static String conLabels = 'CKYC_Search_API';
    public static Map<String, String> constants = Utility.getConstants(conLabels);

    @AuraEnabled
    public static Map<String, String> getConstants() {
        return constants;
    }

	public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) {
		List<String> errorMessages = new List<String>();

		String loanApplicationId = wrapper.loanApplicationId;
		String applicantId = wrapper.recordId;
		String idType = wrapper.fileType;
		String idNumber = wrapper.filename;

		if (String.isBlank(applicantId) || String.isBlank(loanApplicationId)) {
			errorMessages.add('Error: Applicant Id or Loan Application Id is missing');
			return errorMessages;
		}

		Application_Applicant__c applicant = [
			SELECT Id, First_Name__c, Last_Name__c, PAN_Number__c, Aadhaar_Number_Masked__c,
				DOB__c, Gender__c, Customer_Type__c, DOI__c, Email__c, Pincode__c, Mobile_Number__c,CKYC_Document_Type__c
			FROM Application_Applicant__c
			WHERE Id = :applicantId
			LIMIT 1
		];
		if(String.isBlank(idType) || String.isBlank(idNumber)){
			errorMessages.add('Error: Both ID Type and Id Number should be filled');
		}


		if (applicant.Customer_Type__c == 'Individual') {
			// ---------- Individual Rules ----------
			/*if (String.isBlank(applicant.PAN_Number__c) && String.isBlank(applicant.Aadhaar_Number_Masked__c)) {
				errorMessages.add('Error: Both PAN and Aadhaar are missing.');
			}*/
			if (String.isBlank(applicant.Mobile_Number__c)) {
			errorMessages.add('Error: Mobile Number is mandatory for Individual.');
			}
			

		} else {
			// ---------- Non-Individual (LE) Rules ----------
			/*if (String.isBlank(applicant.PAN_Number__c)) {
				errorMessages.add('Error: PAN is mandatory for Non Individual.');
			}*/
			if (String.isBlank(applicant.Mobile_Number__c) && 
			applicant.DOI__c == null && String.isBlank(applicant.Email__c) && String.isBlank(applicant.Pincode__c)){
				errorMessages.add('Error: Either one of Email, Pincode, Mobile No. or DOI is mandatory for Non Individual.');
			}
		}

		return errorMessages;
	}

	public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
		try {
			String applicantId = wrapper.recordId;
			String loanApplicationId = wrapper.loanApplicationId;
			String idType = wrapper.fileType;
			String idNumber = wrapper.filename;
			Map<String, Map<String, String>> mapMasterCode = getPlfMasterCode();
			Application_Applicant__c app = [
				SELECT Id, First_Name__c, Middle_Name__c,DOI__c, Last_Name__c, DOB__c, Aadhaar_Number_Masked__c, PAN_Number__c, Gender__c, Customer_Type__c, Mobile_Number__c, Email__c, Pincode__c
				FROM Application_Applicant__c WHERE Id = :applicantId LIMIT 1];

			// Prepare wrapper
			A99RequestDataWrapper reqWrapper = new A99RequestDataWrapper();

			// ID type based on available fields
			//if (!String.isBlank(app.PAN_Number__c)) {
			//put it in custom label >>
				reqWrapper.ApiToken = Label.CKYC_API_Token;//'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJBcGlTdWJzY3JpcHRpb25JZCI6IjQiLCJUZW5hbnRJZGVudGlmaWVyIjoiODllMjgxMjk5MWJiNDI4NWE0MTc5YmFkYWRhNjZhYTIiLCJBcGlJZCI6IjE4IiwiRW5jcnlwdGlvblByb3ZpZGVySWQiOiIxIiwiQWdlbmN5SWQiOiI4IiwiZXhwIjoxODczNDc3ODAwLCJpc3MiOiJUcmFja3dpenpOZXh0IiwiYXVkIjoidGVuYW50Y2xpZW50Y29uc29sZSJ9.hxQaGH2F4SmEke0kLgT0nB13QB_z3FYdc3x378Senu4';
				//reqWrapper.InputIdType = String.isNotBlank(idType) ? mapMasterCode.get('CKYC Document Type'.toLowerCase()).get(idType.toLowerCase()) : '' ;  //C for PAN
				reqWrapper.InputIdNo = String.isNotBlank(idNumber) ? idNumber : ''; // app.PAN_Number__c;
			/*}else if (!String.isBlank(app.Aadhaar_Number_Masked__c)) {
				String adharNumber = Utility.getDecryptedBase64String(app.Aadhaar_Number_Masked__c);
				reqWrapper.InputIdType = 'E'; // Aadhaar
				reqWrapper.InputIdNo = adharNumber;
			}*/
			// Determine type and populate fields accordingly
			if (app.Customer_Type__c != null && app.Customer_Type__c.equalsIgnoreCase('Individual')) {
				reqWrapper.GetRecordType = 'IND';
				reqWrapper.FirstName = String.isNotBlank(app.First_Name__c) ? app.First_Name__c : '';
				reqWrapper.MiddleName = String.isNotBlank(app.Middle_Name__c) ? app.Middle_Name__c : '';
				reqWrapper.LastName = String.isNotBlank(app.Last_Name__c) ? app.Last_Name__c : '';
				reqWrapper.Gender = String.isNotBlank(app.Gender__c) ? app.Gender__c : '';
				reqWrapper.DateOfBirth = app.DOB__c != null ? formatDateString(app.DOB__c) : '';
				reqWrapper.MobileNumber = String.isNotBlank(app.Mobile_Number__c) ? app.Mobile_Number__c : '';
			} else {
				// Non-Individual / Legal Entity
				reqWrapper.GetRecordType = 'LE';
				reqWrapper.DateOfBirth = app.DOI__c != null ? formatDateString(app.DOI__c) : '';
				reqWrapper.MobileNumber = String.isNotBlank(app.Mobile_Number__c) ? app.Mobile_Number__c : '';
				//reqWrapper.Email = String.isNotBlank(app.Email__c) ? app.Email__c : '';
				//reqWrapper.Pincode = String.isNotBlank(app.Pincode__c) ? app.Pincode__c : '';
			}
			System.debug('dob'+ reqWrapper.DateOfBirth);
			reqWrapper.RequestId = String.valueOf(System.currentTimeMillis());
			reqWrapper.Tags = '';
			reqWrapper.ParentCompany = 'GHFL';
			reqWrapper.ApplicationRefNumber = '';
			reqWrapper.ResultLimit = 'Latest';
			//reqWrapper.photo = '';
			//reqWrapper.AdditionalAction = '';

			// Convert to JSON then XML
			String jsonStr = JSON.serialize(reqWrapper);
			String xmlBody = JSONTOXMLConvertor.convertJsonToXml(jsonStr, 'A99RequestData');

			// Add namespaces
			xmlBody = xmlBody.replace(
				'<A99RequestData>',
				'<A99RequestData xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' +
				'xmlns:xsd="http://www.w3.org/2001/XMLSchema">'
			);

			String finalXml = '<?xml version="1.0" encoding="utf-8"?>' + xmlBody;

			String encryptedJson = COMM_CrifEncryptionUtil.prepareEncryptedCrifRequest(finalXml);
			Map<String, String> requestMap = new Map<String, String>();
				requestMap.put('payload', encryptedJson);
				requestMap.put('apiName', 'searchdownloadckyc');
            String requestJSON = JSON.serialize(requestMap);
            System.debug('Step 14 - Final Request JSON: ' + requestJSON);
            return requestJSON;

		} catch (Exception exp) {
			System.debug('Exception: ' + exp.getMessage());
			Utility.createErrorLogRecord(new List<Error_Logs__c>{
				Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'CreateA99Payload', '', '')
			});
			throw new AuraHandledException('An error occurred: ' + exp.getMessage());
		}
	}


	public static Map<String, Map<String, String>> getPlfMasterCode(){
        try {
            Map<String, Map<String, String>> masterDataMap = new Map<String, Map<String, String>>();
            List<PLF_Master__c> masterRecords = [SELECT Id,Master_Type__c, Description__c, FICO_Code__c FROM PLF_Master__c];
            for (PLF_Master__c record : masterRecords) {
                if (!masterDataMap.containsKey(record.Master_Type__c.toLowerCase())) {
                    masterDataMap.put(record.Master_Type__c.toLowerCase(), new Map<String, String>());
                }                
                masterDataMap.get(record.Master_Type__c.toLowerCase()).put(record.Description__c.toLowerCase(), record.FICO_Code__c);
            }
            return masterDataMap;
        } catch (Exception e) {
            System.debug('COMM_CKYCSearchAPIHandler->getPlfMasterCode ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        } 
    }

	public static String formatDateString(Date myDate) {
		try {
			String formattedDate = '';

			if (myDate != null) {
				// Convert Date to DateTime at midnight
				DateTime myDateTime = DateTime.newInstance(myDate.year(), myDate.month(), myDate.day(), 0, 0, 0);
				formattedDate = myDateTime.format('dd-MM-yyyy');
			}
			System.debug('Convert Date String Format : ' + formattedDate);
			return formattedDate;

		} catch (Exception e) {
			System.debug('ckycSearchAPIHandler->formatDateString :: ' + e.getMessage() + ' AT ' + e.getLineNumber() + ' STACKTRACE ' + e.getStackTraceString());
			throw new AuraHandledException(e.getMessage());
		}
	}

	// Wrapper class
	public class A99RequestDataWrapper {
		public String ApiToken; //new tag
		public String InputIdType;
		public String InputIdNo;
		public String GetRecordType;
		public String MobileNumber;
		public String DateOfBirth;
		public String RequestId;
		public String Tags;
		public String ParentCompany;
		public String ApplicationRefNumber;
		public String FirstName;
		public String MiddleName;
		public String LastName;
		public String Gender;
		public String ResultLimit;
		/*public String Email;
		public String Pincode;
		public String photo;
		public String AdditionalAction;*/
	}
}