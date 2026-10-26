/**
* @File Name : COMM_CKYCFetchRecordController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 16, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 16, 2025 |   | Initial Version
**/

public without sharing class COMM_CKYCFetchRecordController {
	static string conLabels = 'CKYC_API,Current,Permanent';
    
    public static Map<string, string> constantsMeta = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constantsMeta;
    }

	public static Date stringToDateParsing(String dateStr){
		List<String> parts = dateStr.split('-');
		Integer day = Integer.valueOf(parts[0]);
		String monthStr = parts[1];
		Integer year = Integer.valueOf(parts[2]);

		// Mapping mont to number
		Map<String, Integer> monthMap = new Map<String, Integer>{
		'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'May' => 5, 'Jun' => 6, 'Jul' => 7, 'Aug' => 8, 'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12};
		Integer month = monthMap.get(monthStr);

		// Construct the Date
		Date parsedDate = Date.newInstance(year, month, day);
		return parsedDate;
	}

	public static Map<String,Document_Details__c> storeCkycImageChecklist(List<String> contentVersionIds, Id applicantId, Id loanId) {
		try {
			Map<String,Document_Details__c> docTitleToDocMap = new Map<String,Document_Details__c>();
			Map<String, Document_Master__c> docMasterMap = new Map<String, Document_Master__c>();
			for (Document_Master__c dm : [SELECT Id, Name,Document_Category__c,Document_Name__c,Requirement_At__c FROM Document_Master__c WHERE Name IN ('Aadhaar Front', 'Aadhaar Back', 'Photograph','PAN')]) {
				if (!docMasterMap.containsKey(dm.Name)) {
					docMasterMap.put(dm.Name, dm); // how to make sure every time the same doc master will come? //Ask Cred team for unique aadhaar front and back records
				}
			}
			List<ContentVersion> versionList = [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Id IN :contentVersionIds];
			List<Document_Details__c> docDetailsList = new List<Document_Details__c>();
			List<ContentDocumentLink> docLinksList = new List<ContentDocumentLink>();

			for (ContentVersion cv : versionList) {
				System.debug('cv.Title >> ' + cv.Title);
				List<String> targetDocNames = cv.Title == 'AadharCard' ? new List<String>{'Aadhaar Front', 'Aadhaar Back'}: new List<String>{cv.Title};
				for (String docName : targetDocNames) {
					if (docMasterMap.containsKey(docName)) {
						Document_Master__c dm = docMasterMap.get(docName);
						Document_Details__c dd = new Document_Details__c(
							Applicant__c = applicantId,
							Document_Master__c = dm.Id,
							//Document_Category__c = dm.Document_Category__c,
							Content_Document_Id__c = cv.ContentDocumentId,
							Loan_Application__c = loanId,
							Remarks__c = '',
							//Document_Name__c = dm.Document_Name__c,
							Name = dm.Name,
							Requirement_At__c = dm.Requirement_At__c,
							Status__c = 'Uploaded'
						);
						docDetailsList.add(dd);
						docTitleToDocMap.put(cv.Title, dd); //however, this will insrert two docs of aadhaar front and back on the same title ? > lets see.
					}
				}
			}

			if (!docDetailsList.isEmpty()) {
				insert docDetailsList;

				for (Document_Details__c dd : docDetailsList) {
					docLinksList.add(new ContentDocumentLink(
						LinkedEntityId = dd.Id,
						ContentDocumentId = dd.Content_Document_Id__c,
						ShareType = 'V',
						Visibility = 'AllUsers'
					));
				}

				insert docLinksList;
			} else {
				System.debug('No matching Document Master or ContentVersion records found.');
			}
		return docTitleToDocMap;	
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage() + e.getStackTraceString());
		}
	}


	@AuraEnabled
	public static String processCkycFetchRecordAPI(Map<String,String> inputMap){
		Integration_Details__c integrationDetail = new Integration_Details__c();
		try {
			
			String loanId = inputMap.get('loanId');
			String applicantId = inputMap.get('applicantId');
			String processName = inputMap.get('processName');
			String otpNumber = inputMap.get('otpNumber');
			//got all fields due to time constraint for CKYC deadline but need to remove fields which are not in use in code here
			Application_Applicant__c app = [select Id, Name,Aadhaar_Address__c, Aadhaar_City_Town__c, Aadhaar_DOB__c, Aadhaar_First_Name__c, Aadhaar_Gender__c, 
			Aadhaar_Last_Name__c, Aadhaar_Middle_Name__c, Aadhaar_Number_Masked__c, Aadhaar_Number__c, Aadhaar_Pincode__c, Aadhar_Status__c, Additional_Infromation_Filled__c,
			Address_Information_Filled__c, Address_Ownership__c, Alternate_Email__c, Applicant_Type__c, Basic_Details_Filled__c, Business_Entity_Name__c, Business_Type__c,
			IsForm60Uploaded__c, CA_Membership_Number__c,CKYC_FirstName__c,  CIBIL_Score__c, CKYC_Aadhar__c, CKYC_AccountType__c, CKYC_KIN__c, CKYC_PAN__c, CKYC_ReferenceId__c, CLIPB_Business_Vintage__c,
			CLIPB_ID__c, CRIF_Score__c, CRIF_Segment__c, Cast_Category__c, Citizenship__c, Company__c, Consent_Mode__c, Consent_Status__c, Current_Work_Experience_Months__c, 
			Current_Work_Experience_Years__c, Customer_Tagged_From_Dedupe__c, Customer_Type__c, Customer__c, DL_Status__c, DOB__c, DOI__c, Degree_or_Membership_Certificate_ID__c, Disability__c, 
			Doctor_Registration_Number__c, Drivers_License_Address__c, Drivers_License_DOB__c, Drivers_License_Date_of_Issue__c, Drivers_License_First_Name__c, Drivers_License_Last_Name__c, 
			Drivers_License_Middle_Name__c, Drivers_License_Number__c, Drivers_License_Son_Daughter_Wife_of__c, Drivers_License_Validity__c, Email__c, Entity_1__c, Entity_2__c, Father_s_First_Name__c,
			Father_s_Last_Name__c, Father_s_Middle_Name__c, Financial_Non_Financial__c, First_Name__c, GSTIN__c, GST_Exempt__c, GST_ID__c, Gender__c, ITR_Number__c, Industry__c, Is_Consent_Received__c,
			Is_Existing_Customer__c, Is_Hunter_Executed__c, Is_Key_Applicant__c, Is_Mobile_Verified__c, Is_PAN_DOB_Mismatch__c, Is_PAN_Name_Mismatch__c, Is_Pan_Duplicate__c, 
			KYC_Risk_Categorisation_Category__c, LMS_Id__c, Last_Name__c, Legal_Entity_Number__c, LoanID__c, Loan_Application__c, Marital_Status__c, Masked_Aadhar_Number__c, Medical_Council_Name__c,
			Middle_Name__c, Mobile_Number_Masked__c, Mobile_Number__c, Mother_s_First_Name__c, Mother_s_Last_Name__c, Mother_s_Middle_Name__c, NPR_Letter_ID__c, Name_of_Organization__c, 
			Nationality__c, Nature_of_Business__c, Negative_List_Comment__c, Negative_list_dispostion__c, No_of_Associated_Entities__c, No_of_enquiries_in_last_3m__c,
			No_of_unsecured_loans_availed_last_6m__c, Notarized_Rent_Agreement_Registration__c, Number_Of_Applicants__c, Office_Ownership__c, PAN_DOB__c, PAN_Date_of_Issue__c, PAN_First_Name__c, 
			PAN_KYC_Verified__c, PAN_Last_Name__c, PAN_Middle_Name__c, PAN_Number__c, PEP__c, PSL__c, Pan_Father_s_Name__c, Pan_Name__c, Pan_OCR_Confirmed__c, Pan_Status__c, Passport_Address__c, 
			Passport_DOB__c, Passport_Date_of_Expiry__c, Passport_Date_of_Issue__c, Passport_File_Number__c, Passport_First_Name__c, Passport_Last_Name__c, Passport_Mother_s_Name__c, 
			Passport_Nationality__c, Passport_Number__c, Passport_Place_of_Birth__c, Passport_Place_of_Issue__c, Passport_Son_Daughter_Wife_of__c, Passport_Spouse_Name__c, Passport_Status__c, 
			Pincode__c, Qualification__c, Reference_1_Relation_with_Applicant__c, Reference_2_Relation_with_Applicant__c, Reference_Address_1__c, Reference_Address_2__c, Reference_Last_Name_1__c,
			Reference_Last_Name_2__c, Reference_Name_1__c, Reference_Name_2__c, Reference_Phone_1__c, Reference_Phone_2__c, Registration_Certificate_ID__c, Registration_Number__c, 
			Relationship_with_Primary_Applicant__c, Religion__c, Rent_Agreement_Registration_Number__c, Salutation__c, Share_Holding_Percentage__c, Specialization__c, Spouse_First_Name__c,
			Spouse_Last_Name__c, Spouse_Middle_Name__c, Sub_Segment__c, Sub_Stage_Completion__c, Total_Work_Experience_Months__c, Total_Work_Experience_Years__c, Turnover_Yearly__c,
			Udhyam_Registration_No__c, Voter_Address__c, Voter_ID_DOB__c, Voter_ID_First_Name__c, Voter_ID_Gender__c, Voter_ID_Last_Name__c, Voter_ID_Middle_Name__c, Voter_ID_Number__c, 
			Voter_ID_Son_Daughter_Wife_of__c, Voter_Id_Age__c, Year_of_Registration__c, Applicant_Name__c, Applicant_s_Age__c, Customer_LMS_Id__c, Customer_Profile__c, Employment_Type__c, 
			Existing_Customer__c, Mobile_and_Customer_Type__c, Residency_Status__c, Sector__c, Sub_Employment_Type_Non_Individual__c, Sub_Employment_Type__c, Business_Vintage__c, 
			Other_Employer_Name__c, Employer_Type__c, Employer_Industry__c, Monthly_Gross_Salary__c, Date_of_Joining__c, Profession__c, Official_Mail_ID__c, Employee_ID__c, Monthly_Salary__c, 
			Contract_Type__c, Employer_Pin_Code__c, Employer_Address__c, Employer_Phone_Number__c, TAN_of_the_Employer__c, UAN_of_Employee__c, Other_Qualification__c, Voter_ID_Status__c, 
			Driving_License_Status__c, UCIC_Type__c, MSME_Category__c, BSR_Code__c, Industry_Code__c, Business_Commencement_Date__c, Shareholder_Partner_Name__c, Certiifcate_Issuing_Authority__c,
			Certificate_Issue_Date__c, Certificate_Expiry_Date__c, Ex_Serviceman__c, Is_Financial_applicant__c, Trade_Name__c, Other_Nature_of_Business__c, Contact_Person_Name__c, 
			Contact_Person_Number__c, Employer_Name__c, Aadhaar_Front_OCR_Confirmed__c, Aadhaar_Back_OCR_Confirmed__c, Designation__c, Monthly_Net_Salary__c, Variable_Income__c, Other_Income__c,
			Rent__c, Interest__c, Is_MNRL_Blacklisted__c, Employer_Category__c, Remarks__c, Annual_Sales__c, Monthly_Sales__c, Annual_Expenses__c, Monthly_Expenses__c, Preferred_Language__c,
			Annual_Other_Income__c, Monthly_Other_Income__c, Annual_Rent__c, Monthly_Rent__c, Annual_Interest__c, Monthly_Interest__c, Income_Method__c, Total_Income__c,
			Annual_Net_Earnings__c, Monthly_Net_Earnings__c, Annual_Total_Income__c, Monthly_Total_Income__c from Application_Applicant__c where id = :applicantId];
			
			String returnResp = '';
			String resultMessage;
			List<Application_Applicant__c> applicantList = [
				SELECT Id,Applicant_Name__c,Loan_Application__c,PAN_Number__c,Customer_Type__c 
				FROM Application_Applicant__c 
				WHERE Id =: applicantId LIMIT 1
			];
			Integration_Master__mdt metadata = [
				SELECT Process_Name__c,Product_Type__c,Product_Version__c,
					Handler_Class__c,Endpoint__c,Request_Method__c,
					Client_Id__c,Client_Secret__c,Allowed_Retry__c,
					Gestation_Period__c,Refresh_Allowed__c,
					Activity_Name__c,CustomerId__c,UserId__c,Password__c
				FROM Integration_Master__mdt 
				WHERE Activity_Name__c = :processName LIMIT 1
			];
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
			wrapper.otpNumber = otpNumber;
			IntHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
			List<Integration_Settings__c> intSettingList = [
				SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
				FROM Integration_Settings__c WHERE Name = 'AHL CKYC' LIMIT 1
			];
			Integration_Settings__c intSetting = intSettingList[0];
			String ckycSuccessDescription = '';
			if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
				integrationDetail.Status__c = '412';
				integrationDetail.Prerequisite__c = String.join(respWrapper.prerequisiteError, ', ');
				integrationDetail.Name = processName;
				integrationDetail.Object_Name__c = 'Application_Applicant__c';
				integrationDetail.Loan_Application__c = loanId;
				integrationDetail.Related_Record_Id__c = applicantId;
				integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
				integrationDetail.Request_JSON__c = respWrapper.payload; 
				resultMessage = String.join(respWrapper.prerequisiteError, ', ');
				returnResp = resultMessage;
			}
			else {
				Map<String, String> integrationRequestMap = new Map<String, String>();
				String bearer = Utility.getAccessToken();
                integrationRequestMap.put('bearer',bearer);
				integrationRequestMap.put('intSettingName', 'AHL CKYC');
				integrationRequestMap.put('requestJSON', respWrapper.payload);    
				integrationRequestMap.put('Origin', Label.CKYC_Origin);         
				HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
				System.debug('CKYC API Response: ' + resp.getBody());
				System.debug('CKYC API Response Code: ' + resp.getStatusCode());
				integrationDetail.Name = processName;
				integrationDetail.Object_Name__c = 'Application_Applicant__c';
				integrationDetail.Loan_Application__c = loanId;
				integrationDetail.Related_Record_Id__c = applicantId;
				integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
				integrationDetail.Request_JSON__c = respWrapper.payload;
				integrationDetail.Response_JSON__c = resp.getBody();
				integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
				if(resp.getBody()!=null && resp.getStatusCode() == 200){
					CkycFetchResponseWrapper ckycResp = (CkycFetchResponseWrapper) JSON.deserialize(resp.getBody(), CkycFetchResponseWrapper.class);
					Map<String,Document_Details__c> docTitleToDocMap = new Map<String,Document_Details__c>();
					Map<String, Map<String, String>> mapMasterCode = COMM_CKYCSearchAPIHandler.getPlfMasterCode();
                    List<Applicant_Address__c> addListCurrent =[Select id, Customer_Address__c,Address_Type__c from Applicant_Address__c where Applicant__c=:app.Id And Address_Type__c=:constantsMeta.get('Current')];
                    List<Applicant_Address__c> addListPermanent =[Select id, Address_Type__c,Customer_Address__c from Applicant_Address__c where Applicant__c=:app.Id And Address_Type__c=:constantsMeta.get('Permanent')];
                    Account accCust = new Account();
                    System.debug('app.Applicant_Name__c '+app.Applicant_Name__c);
                    System.debug('app.Customer_Type__c '+app.Customer_Type__c);
                    System.debug('app.Customer__c '+app.Customer__c);
                    if(app.Customer__c==null){
                        accCust.Name=app.Applicant_Name__c;
                        insert accCust;
                        System.debug('accCust '+accCust);
                        app.Customer__c=accCust.id;
                    }
                    if(ckycResp.response!=null && ckycResp.response.A99ResponseData!=null && ckycResp.response.A99ResponseData.CKYCDownloadResult!=null){ //ideally should be nested if.. but lets see
						CKYCDownloadResult ckycDownloadResObj = ckycResp.response.A99ResponseData.CKYCDownloadResult;
						if(ckycDownloadResObj.CKYCStatus == 'CKYCSuccess'){
							//INSERT IMAGE
							List<String> contentVersionIdsList = new List<String>();
							if(ckycDownloadResObj.CKYCImageDetails!=null && ckycDownloadResObj.CKYCImageDetails.CKYCImageDetails.size()>0){
								for(CKYCImageDetails ckycImageObj : ckycDownloadResObj.CKYCImageDetails.CKYCImageDetails){
									if(String.isNotBlank(ckycImageObj.CKYCImageData)){
										contentVersionIdsList.add(ckycImageObj.CKYCImageData);
									}
								}
								if(contentVersionIdsList.size()>0){
									docTitleToDocMap = storeCkycImageChecklist(contentVersionIdsList,app.id,loanId);
								}
							}
							//MAPPPING APPLICANT DET STARTSS
							app.Salutation__c =  String.isNotBlank(ckycDownloadResObj.CKYCNamePrefix) ? mapMasterCode.get('Salutation CKYC'.toLowerCase()).get(ckycDownloadResObj.CKYCNamePrefix.toLowerCase()) : ''; //SALUTATION NEED TO DO >  
							//app.CKYC_DOB__c = String.isNotBlank(ckycDownloadResObj.CKYCDOB) ? stringToDateParsing(ckycDownloadResObj.CKYCDOB) : null;
							app.DOB__c = String.isNotBlank(ckycDownloadResObj.CKYCDOB) ? stringToDateParsing(ckycDownloadResObj.CKYCDOB) : null; //NEW
							app.First_Name__c = String.isNotBlank(ckycDownloadResObj.CKYCFirstName) ? ckycDownloadResObj.CKYCFirstName : '';
							app.Middle_Name__c = String.isNotBlank(ckycDownloadResObj.CKYCMiddleName) ? ckycDownloadResObj.CKYCMiddleName : '';
							app.Last_Name__c = String.isNotBlank(ckycDownloadResObj.CKYCLastName) ? ckycDownloadResObj.CKYCLastName : '';
							app.CKYC_FullName__c = String.isNotBlank(ckycDownloadResObj.CKYCFullName) ? ckycDownloadResObj.CKYCFullName : '';
							//app.CKYC_FirstName__c = String.isNotBlank(ckycDownloadResObj.CKYCFirstName) ? ckycDownloadResObj.CKYCFirstName : '';
							//app.CKYC_MiddleName__c = String.isNotBlank(ckycDownloadResObj.CKYCMiddleName) ? ckycDownloadResObj.CKYCMiddleName : '';
							//app.CKYC_LastName__c = String.isNotBlank(ckycDownloadResObj.CKYCLastName) ? ckycDownloadResObj.CKYCLastName : '';
							app.PAN_Number__c = String.isNotBlank(ckycDownloadResObj.CKYCPAN) ? ckycDownloadResObj.CKYCPAN : '';
							//app.CKYC_PAN__c = String.isNotBlank(ckycDownloadResObj.CKYCPAN) ? ckycDownloadResObj.CKYCPAN : '';
							app.Mother_s_First_Name__c = String.isNotBlank(ckycDownloadResObj.CKYCMotherFirstName) ? ckycDownloadResObj.CKYCMotherFirstName : '';
							app.Mother_s_Middle_Name__c = String.isNotBlank(ckycDownloadResObj.CKYCMotherMiddletName) ? ckycDownloadResObj.CKYCMotherMiddletName : '';
							app.Mother_s_Last_Name__c = String.isNotBlank(ckycDownloadResObj.CKYCMotherLastName) ? ckycDownloadResObj.CKYCMotherLastName : '';
							app.CKYC_Mother_FullName__c = String.isNotBlank(ckycDownloadResObj.CKYCMotherFullName) ? ckycDownloadResObj.CKYCMotherFullName : '';
							app.CKYC_Mother_Prefix__c = String.isNotBlank(ckycDownloadResObj.CKYCMotherNamePrefix) ? ckycDownloadResObj.CKYCMotherNamePrefix :'';
							app.Gender__c = String.isNotBlank(ckycDownloadResObj.CKYCGender) ? mapMasterCode.get('Gender CKYC'.toLowerCase()).get(ckycDownloadResObj.CKYCGender.toLowerCase()) : '';
							//for father & spouse confirm from Sreenivasan if diferent tags will be there for a married applicant
							app.CKYC_Father_Spouse_Prefix__c = String.isNotBlank(ckycDownloadResObj.CKYCFatherNamePrefix) ? ckycDownloadResObj.CKYCFatherNamePrefix : '';
							app.Father_s_First_Name__c = String.isNotBlank(ckycDownloadResObj.CKYCFatherFirstName) ? ckycDownloadResObj.CKYCFatherFirstName : ''; //new
							app.Father_s_Middle_Name__c = String.isNotBlank(ckycDownloadResObj.CKYCFatherMiddleName) ? ckycDownloadResObj.CKYCFatherMiddleName : '';//new
							app.Father_s_Last_Name__c = String.isNotBlank(ckycDownloadResObj.CKYCFatherLastName) ? ckycDownloadResObj.CKYCFatherLastName : '';//new
							app.Spouse_First_Name__c = String.isNotBlank(ckycDownloadResObj.CKYCSpouseFirstName) ? ckycDownloadResObj.CKYCSpouseFirstName : '';
							app.Spouse_Middle_Name__c = String.isNotBlank(ckycDownloadResObj.CKYCSpouseMiddleName) ? ckycDownloadResObj.CKYCSpouseMiddleName : '';
							app.Spouse_Last_Name__c = String.isNotBlank(ckycDownloadResObj.CKYCSpouseLastName) ? ckycDownloadResObj.CKYCSpouseLastName : '';
							app.Pan_Father_s_Name__c = String.isNotBlank(ckycDownloadResObj.CKYCFatherFullName) ? ckycDownloadResObj.CKYCFatherFullName : ''; //FULL name > 
							app.CKYC_ReferenceId__c = String.isNotBlank(ckycDownloadResObj.CKYCReferenceID) ? ckycDownloadResObj.CKYCReferenceID : '';
							app.CKYC_AccountType__c = String.isNotBlank(ckycDownloadResObj.CKYCAccType) ? Integer.valueOf(ckycDownloadResObj.CKYCAccType) : null;
							app.Mobile_Number__c = ckycDownloadResObj.CKYCMobileNumber!=null ? String.valueOf(ckycDownloadResObj.CKYCMobileNumber) : '';
							app.CKYC_KIN__c = ckycDownloadResObj.CKYCNumber!=null ? String.valueOf(ckycDownloadResObj.CKYCNumber) : ''; 
							app.Email__c =  String.isNotBlank(ckycDownloadResObj.CKYCEmailAdd) ? ckycDownloadResObj.CKYCEmailAdd : '';
							//MAPPING APPLICANT DET ENDS > 
							/*"CKYCMaidenNamePrefix": "",
							"CKYCMaidenFirstName": "",
							"CKYCMaidenMiddleName": "",
							"CKYCMaidenLastName": "", 
							"CKYCKYCVerificationDesg": "Manager",
							"CKYCKYCVerificationBranch": "Mumbai",
							"CKYCKYCVerificationName": "Manish Vichare",
							"CKYCOffTelNumber": "",
							"CKYCMobileISD": 91,
							"RequestId": 1758602260188,
							"CKYCDateofDeclaration": "16-Aug-2025",
							"CKYCNumberofRelatedPersons": 0,				
							"CKYCPlaceofDeclaration": "Mumbai",
							"CKYCResTelSTD": "",
							"ApplicationFormNo": "",
							"CKYCResTelNumber": "",
							"CKYCKYCVerificationDate": "19-Aug-2025",
							"CKYCOffTelSTD": "",
							"CKYCNumberofImages": 2,
							"CKYCRelatedPersonDetails": "",
							"CKYCKYCVerificationEmpcode": 716801,
							"CKYCConstiType": "01",
							"CKYCNumberofIds": 1,
							"CKYCTypeofDocSubmitted": "01",
							"ResidentialStatus": "Resident Individual",
							"CKYCRemarks": ">> MAP this after checking the situation in whioch it gets filled*/
							//MAPPING PERMANENT ADDRESS STARTS
							Applicant_Address__c appPermAdd = new  Applicant_Address__c();
							if(addListPermanent.size()!=0){
								appPermAdd.id=addListPermanent[0].id;
							}
							else{
								Customer_Address__c newCustomerAddressPermanent = new Customer_Address__c();
								newCustomerAddressPermanent.Customer__c = app.Customer__c;
								newCustomerAddressPermanent.Address_Type__c=constantsMeta.get('Permanent');
								insert newCustomerAddressPermanent; 
								appPermAdd.Customer_Address__c=newCustomerAddressPermanent.id;
							}
							appPermAdd.Address_Type__c=constantsMeta.get('Permanent');
							appPermAdd.Address_Line_1__c = String.isNotBlank(ckycDownloadResObj.CKYCPerAdd3) ? ckycDownloadResObj.CKYCPerAdd3 : '';
							appPermAdd.Address_Line_2__c =String.isNotBlank(ckycDownloadResObj.CKYCPerAdd2) ? ckycDownloadResObj.CKYCPerAdd2 : '' ;
							appPermAdd.Address_Line_3__c = String.isNotBlank(ckycDownloadResObj.CKYCPerAdd1) ? ckycDownloadResObj.CKYCPerAdd1 : '';
							//appPermAdd.CKYC_City__c = String.isNotBlank(ckycDownloadResObj.CKYCPerAddCity) ? ckycDownloadResObj.CKYCPerAddCity : '';
							List<Pincode_Master__c> pinList = [SELECT Id FROM Pincode_Master__c WHERE Name = :String.valueOf(ckycDownloadResObj.CKYCPerAddPin) LIMIT 1];
							appPermAdd.Pincode__c = !pinList.isEmpty() ? pinList[0].Id : null;
							//appPermAdd.CKYC_Pincode__c = ckycDownloadResObj.CKYCPerAddPin!=null ? String.valueOf(ckycDownloadResObj.CKYCPerAddPin) : '';
							//appPermAdd.CKYC_District__c = String.isNotBlank(ckycDownloadResObj.CKYCPerAddDistrict) ? ckycDownloadResObj.CKYCPerAddDistrict : '';
							//appPermAdd.CKYC_Country__c = String.isNotBlank(ckycDownloadResObj.CKYCPerAddCountry) ? ckycDownloadResObj.CKYCPerAddCountry : '';
							//appPermAdd.CKYC_State__c = String.isNotBlank(ckycDownloadResObj.CKYCPerAddState) ? ckycDownloadResObj.CKYCPerAddState : '';
							appPermAdd.Document_Details__c = docTitleToDocMap.containsKey(ckycDownloadResObj.CKYCPerAddPOA) ?  docTitleToDocMap.get(ckycDownloadResObj.CKYCPerAddPOA).Id : null; //mapping doc Detail
							appPermAdd.CKYC_POA_Submitted__c = String.isNotBlank(ckycDownloadResObj.CKYCPerAddPOA) ? ckycDownloadResObj.CKYCPerAddPOA : '';
							appPermAdd.Is_Current_Address_Same_As_Permanent__c = String.isNotBlank(ckycDownloadResObj.CKYCPerAddSameasCorAdd) && ckycDownloadResObj.CKYCPerAddSameasCorAdd == 'Y' ? 'Yes' : 'No';
							appPermAdd.Applicant__c=app.id;
							appPermAdd.Loan_Application__c = loanId;
							Upsert appPermAdd;
							//MAPPING PERMANENT ADDRESS ENDS
							//MAPPING CURRENT ADD STARTS
							Applicant_Address__c appCurrentAdd = new  Applicant_Address__c();
							if(addListCurrent.size()!=0){
								appCurrentAdd.id=addListCurrent[0].id;
							}
							else{
								Customer_Address__c newCustomerAddressCurrent = new Customer_Address__c();
								newCustomerAddressCurrent.Customer__c = app.Customer__c;
								newCustomerAddressCurrent.Address_Type__c=constantsMeta.get('Current');
								insert newCustomerAddressCurrent;
								appCurrentAdd.Customer_Address__c=newCustomerAddressCurrent.id;
							}
							appCurrentAdd.Address_Type__c=constantsMeta.get('Current');
							appCurrentAdd.Address_Line_1__c = String.isNotBlank(ckycDownloadResObj.CKYCCorAdd3) ? ckycDownloadResObj.CKYCCorAdd3 : '';
							appCurrentAdd.Address_Line_2__c = String.isNotBlank(ckycDownloadResObj.CKYCCorAdd2) ? ckycDownloadResObj.CKYCCorAdd2 : '' ;
							appCurrentAdd.Address_Line_3__c = String.isNotBlank(ckycDownloadResObj.CKYCCorAdd1) ? ckycDownloadResObj.CKYCCorAdd1 : '';
							//appCurrentAdd.CKYC_City__c = String.isNotBlank(ckycDownloadResObj.CKYCCorAddCity) ? ckycDownloadResObj.CKYCCorAddCity : '';
							appCurrentAdd.Document_Details__c = docTitleToDocMap.containsKey(ckycDownloadResObj.CKYCCorAddPOA) ?  docTitleToDocMap.get(ckycDownloadResObj.CKYCCorAddPOA).Id : null;
							//appCurrentAdd.CKYC_Pincode__c = ckycDownloadResObj.CKYCCorAddPin!=null ? String.valueOf(ckycDownloadResObj.CKYCCorAddPin) : '';
							List<Pincode_Master__c> pinListCurrent = [SELECT Id FROM Pincode_Master__c WHERE Name = :String.valueOf(ckycDownloadResObj.CKYCCorAddPin) LIMIT 1];
							appCurrentAdd.Pincode__c = !pinListCurrent.isEmpty() ? pinListCurrent[0].Id : null;
							//appCurrentAdd.CKYC_District__c = String.isNotBlank(ckycDownloadResObj.CKYCCorAddDistrict) ? ckycDownloadResObj.CKYCCorAddDistrict : '';
							//appCurrentAdd.CKYC_Country__c = String.isNotBlank(ckycDownloadResObj.CKYCCorAddCountry) ? ckycDownloadResObj.CKYCCorAddCountry : '';
							//appCurrentAdd.CKYC_State__c = String.isNotBlank(ckycDownloadResObj.CKYCCorAddState) ? ckycDownloadResObj.CKYCCorAddState : '';
							appCurrentAdd.CKYC_POA_Submitted__c = String.isNotBlank(ckycDownloadResObj.CKYCCorAddPOA) ? ckycDownloadResObj.CKYCCorAddPOA : '';
							appCurrentAdd.Applicant__c=app.id;
							appCurrentAdd.Loan_Application__c = loanId;
							Upsert appCurrentAdd;
							//updating applicant Now
							
							//get the document record and tag it to custoemr addr






							//INSERT TRIANGULATION DATAA
							List<Triangulation_Data__c> triangulationDatas = [SELECT Id,CKYC_Doc_Type__c,CKYC_Doc_ID__c, Loan_Application__c, Application_Applicant__c, Name__c, Pan__c, Gender__c, CKYC_Number__c, 
																				Date_Of_Birth__c, Father__c, Mother__c, Mobile_Number__c, KYC_Employee_Code__c, Address__c FROM Triangulation_Data__c 
																				WHERE Loan_Application__c =: loanId AND Application_Applicant__c =: app.id AND Source_Type__c ='CKYC'];
							if(!triangulationDatas.isEmpty()) {
								triangulationDatas[0].CKYC_Number__c = ckycDownloadResObj.CKYCNumber!=null ? String.valueOf(ckycDownloadResObj.CKYCNumber) : ''; 
								triangulationDatas[0].Name__c = String.isNotBlank(ckycDownloadResObj.CKYCFullName) ? ckycDownloadResObj.CKYCFullName : '';
								triangulationDatas[0].Pan__c = String.isNotBlank(ckycDownloadResObj.CKYCPAN) ? ckycDownloadResObj.CKYCPAN : '';
								triangulationDatas[0].Gender__c = String.isNotBlank(ckycDownloadResObj.CKYCGender) ? ckycDownloadResObj.CKYCGender : '';
								triangulationDatas[0].Father__c = String.isNotBlank(ckycDownloadResObj.CKYCFatherFullName) ? ckycDownloadResObj.CKYCFatherFullName : '';
								triangulationDatas[0].Date_Of_Birth__c = String.isNotBlank(ckycDownloadResObj.CKYCDOB) ? ckycDownloadResObj.CKYCDOB : '';
								triangulationDatas[0].Mother__c = String.isNotBlank(ckycDownloadResObj.CKYCMotherFullName) ? ckycDownloadResObj.CKYCMotherFullName : '';
								triangulationDatas[0].Mobile_Number__c = ckycDownloadResObj.CKYCMobileNumber!=null ? String.valueOf(ckycDownloadResObj.CKYCMobileNumber) : '';
								//triangulationDatas[0].KYC_Employee_Code__c = ckycDownloadResObj.CKYCKYCVerificationEmpcode!=null ?  String.valueOf(ckycDownloadResObj.CKYCKYCVerificationEmpcode) : '';
								triangulationDatas[0].Address__c = 'Current - '+ckycDownloadResObj.CKYCCorAdd1 + ', '+
																	ckycDownloadResObj.CKYCCorAdd2 + ', '+
																	ckycDownloadResObj.CKYCCorAdd3 +', '+
																	ckycDownloadResObj.CKYCCorAddCity + ', '+
																	String.valueOf(ckycDownloadResObj.CKYCCorAddPin)+', '+
																	ckycDownloadResObj.CKYCCorAddDistrict+', '+
																	ckycDownloadResObj.CKYCCorAddCountry+', '+
																	ckycDownloadResObj.CKYCCorAddState+' || '+
																	'Premanent - '+ckycDownloadResObj.CKYCPerAdd1 + ', '+
																	ckycDownloadResObj.CKYCPerAdd2 + ', '+
																	ckycDownloadResObj.CKYCPerAdd3 +', '+
																	ckycDownloadResObj.CKYCPerAddCity + ', '+
																	String.valueOf(ckycDownloadResObj.CKYCPerAddPin)+', '+
																	ckycDownloadResObj.CKYCPerAddDistrict+', '+
																	ckycDownloadResObj.CKYCPerAddCountry+', '+
																	ckycDownloadResObj.CKYCCorAddState;
								update triangulationDatas;
								//NEVER MIND > > > > >
								//app.CKYC_Document_Type__c = triangulationDatas[0].CKYC_Doc_Type__c!=null? triangulationDatas[0].CKYC_Doc_Type__c : null;
								//app.CKYC_Document_ID__c = String.isNotBlank(triangulationDatas[0].CKYC_Doc_ID__c) ? triangulationDatas[0].CKYC_Doc_ID__c : '';
								
							} else {
								Triangulation_Data__c triangulationData = new Triangulation_Data__c();
								triangulationData.CKYC_Number__c = ckycDownloadResObj.CKYCNumber!=null ? String.valueOf(ckycDownloadResObj.CKYCNumber) : '';  
								triangulationData.Name__c = String.isNotBlank(ckycDownloadResObj.CKYCFullName) ? ckycDownloadResObj.CKYCFullName : '';
								triangulationData.Pan__c = String.isNotBlank(ckycDownloadResObj.CKYCPAN) ? ckycDownloadResObj.CKYCPAN : '';
								triangulationData.Gender__c = String.isNotBlank(ckycDownloadResObj.CKYCGender) ? ckycDownloadResObj.CKYCGender : '';
								triangulationData.Father__c = String.isNotBlank(ckycDownloadResObj.CKYCFatherFullName) ? ckycDownloadResObj.CKYCFatherFullName : '';
								triangulationData.Date_Of_Birth__c =  String.isNotBlank(ckycDownloadResObj.CKYCDOB) ? ckycDownloadResObj.CKYCDOB : '';
								triangulationData.Mother__c = String.isNotBlank(ckycDownloadResObj.CKYCMotherFullName) ? ckycDownloadResObj.CKYCMotherFullName : '';
								triangulationData.Mobile_Number__c = ckycDownloadResObj.CKYCMobileNumber!=null ? String.valueOf(ckycDownloadResObj.CKYCMobileNumber) : '';
								//triangulationData.KYC_Employee_Code__c = ckycDownloadResObj.CKYCKYCVerificationEmpcode!=null ?  String.valueOf(ckycDownloadResObj.CKYCKYCVerificationEmpcode) : '';
								triangulationData.Address__c = 'Current - '+ckycDownloadResObj.CKYCCorAdd1 + ', '+ ckycDownloadResObj.CKYCCorAdd2 + ', '+ ckycDownloadResObj.CKYCCorAdd3 +', '+
									ckycDownloadResObj.CKYCCorAddCity + ', '+ String.valueOf(ckycDownloadResObj.CKYCCorAddPin)+', '+ ckycDownloadResObj.CKYCCorAddDistrict+', '+
									ckycDownloadResObj.CKYCCorAddCountry+', '+ ckycDownloadResObj.CKYCCorAddState+' || '+ 'Permanent - '+ckycDownloadResObj.CKYCPerAdd1 + ', '+ 
									ckycDownloadResObj.CKYCPerAdd2 + ', '+ ckycDownloadResObj.CKYCPerAdd3 +', '+ ckycDownloadResObj.CKYCPerAddCity + ', '+ String.valueOf(ckycDownloadResObj.CKYCPerAddPin)+', '+
									ckycDownloadResObj.CKYCPerAddDistrict+', '+ ckycDownloadResObj.CKYCPerAddCountry+', '+ckycDownloadResObj.CKYCCorAddState;
								// parameter setting
								triangulationData.Application_Applicant__c = app.id;
								triangulationData.Loan_Application__c = loanId;
								triangulationData.Source_Type__c = 'CKYC';
								insert triangulationData;
							}
							update app; //update applicant at theendddd
							returnResp = 'Success :CKYC FETCH API Executed Successfully and data updated in the system.';
						}
						else{
							returnResp = String.isNotBlank(ckycDownloadResObj.CKYCRejectionDescription) ? ckycDownloadResObj.CKYCRejectionDescription : '';

						}
					}
                }
				else if(resp.getStatusCode() == 503){
					integrationDetail.Status__c = '503';
					returnResp = 'Error: Service Temporarily Unavailable';
				}
				else {
					integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
					returnResp = 'Error: Unexpected API Failure';
				}
			}
			insert integrationDetail;
			return returnResp;    
		} catch (Exception e) {
			integrationDetail.Response_JSON__c = e.getMessage() + e.getStackTraceString();
			insert integrationDetail;
			System.debug('CKYCFetchRecordController->processCKYCFetchRecordapi ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
			throw new AuraHandledException(e.getMessage() + e.getStackTraceString());
		}
	}
	
	public class CkycFetchResponseWrapper{
	public response response;
	}
	class response {
		public A99ResponseData A99ResponseData;
	}
	class A99ResponseData {
		public CKYCDownloadResult CKYCDownloadResult;
		//public String xmlns:xsi;	//http://www.w3.org/2001/XMLSchema-instance
		//public String xmlns:xs;	//http://www.w3.org/2001/XMLSchema
		public String CKYCSearchResult;	//
		public String RequestStatus;	//AcceptedByTW
	}
	class CKYCDownloadResult {
		public String CKYCFormSixty;	//No
		//public CKYCIDDetails CKYCIDDetails; commenting for now as this was throwing an error >>
		public String CKYCRejectionDescription; //when ckycfails>>CKYCRejected >> when succeeeds CKYCSuccess
		public String CKYCStatus;	//CKYCSuccess
		public String CKYCNamePrefix;	//Mr
		public String CKYCKYCVerificationDesg;	//Manager
		public String CKYCCorAddPOA;	//AadharCard
		public String CKYCMaidenMiddleName;	//
		public String CKYCMotherFirstName;	//Devi
		public String CKYCPAN;	//GNYPM9875D
		public String CKYCMotherFullName;	//Mrs Devi  Murugan
		public String CKYCKYCVerificationBranch;	//Mumbai
		public String CKYCKYCVerificationName;	//Manish Vichare
		public String CKYCSpouseFirstName;
		public String CKYCSpouseMiddleName;
		public String CKYCSpouseLastName;
		public String CKYCAccType;	//01
		public String CKYCFatherNamePrefix;	//
		public String CKYCLastName;	//Murugan
		public String CKYCPerAddCity;	//Thane
		public String CKYCOffTelNumber;	//
		//public Integer CKYCMobileISD;	//91 datatype mismatch
		public Long RequestId;	//1758602260188
		public String CKYCDateofDeclaration;	//16-Aug-2025
		public String CKYCDOB;	//17-Mar-1996
		public String CKYCMotherNamePrefix;	//Mrs
		public String CKYCCorAddCity;	//Thane
		public Long CKYCMobileNumber;	//7738282592
		public Integer CKYCNumberofRelatedPersons;	//0
		public String CKYCCorAdd2;	//1st Rabodi
		public String CKYCCorAdd1;	//Gulmohar apt
		public String CKYCPlaceofDeclaration;	//Mumbai
		public String CKYCResTelSTD;	//
		public String CKYCFatherFullName;	//
		public String CKYCCorAdd3;	//
		public String CKYCReferenceID;	//INTPFZ12598071
		public String CKYCMaidenFirstName;	//
		public String ApplicationFormNo;	//
		public String CKYCResTelNumber;	//
		public String CKYCMaidenNamePrefix;	//
		public Integer CKYCPerAddPin;	//400601
		public String CKYCMaidenFullName;	//
		public Integer CKYCCorAddPin;	//400601
		public String CKYCMotherMiddletName;	//
		public String CKYCKYCVerificationDate;	//19-Aug-2025
		public String CKYCPerAddState;	//MH
		public String CKYCOffTelSTD;	//
		public Integer CKYCNumberofImages;	//2
		public String CKYCPerAddSameasCorAdd;	//Y
		public String CKYCRelatedPersonDetails;	//
		public String CKYCPerAddDistrict;	//Thane
		public String CKYCMiddleName;	//
		//public Integer CKYCKYCVerificationEmpcode;	//716801 datatype mismatch
		public String CKYCFullName;	//Mr Sreenivasan  Murugan
		public CKYCImageDetails CKYCImageDetails;
		public String CKYCConstiType;	//01
		public String CKYCPerAdd1;	//Gulmohar apt
		public String CKYCPerAdd3;	//
		public String CKYCMaidenLastName;	//
		public String CKYCPerAdd2;	//1st Rabodi
		public Long CKYCNumber;	//30035676981122
		public Integer CKYCNumberofIds;	//1
		public String CKYCFatherLastName;	//
		public String CKYCCorAddCountry;	//IN
		public String CKYCEmailAdd;	//
		public String CKYCCorAddState;	//MH
		public String CKYCFatherFirstName;	//
		public String CKYCFatherMiddleName;	//
		public String CKYCFirstName;	//Sreenivasan
		public String CKYCPerAddPOA;	//AadharCard
		public String CKYCCorAddDistrict;	//Thane
		public String CKYCTypeofDocSubmitted;	//01
		public String CKYCGender;	//M
		public String CKYCPerAddCountry;	//IN
		public String ResidentialStatus;	//Resident Individual
		public String CKYCMotherLastName;	//Murugan
		//public String CKYCRemarks;	// datatype mismatch
	}
	/*class CKYCIDDetails {
		public CKYCIdentityDetails CKYCIdentityDetails;
	}
	class CKYCIdentityDetails {
		public String CKYCIDType;	//E
		public String CKYCIDVerificationStatus;	//02
		public Integer CKYCIDSequence;	//1
		public String CKYCIDNumber;	//XXXXXXXX7498
	}*/
	class CKYCImageDetails {
		public CKYCImageDetails[] CKYCImageDetails;
		public String CKYCImageData;	//068C2000003oWHVIA2
		public String CKYCImageBranch;	//0011
		public String CKYCImageType;	//AadharCard
		public Integer CKYCImageSequence;	//1
		public String CKYCImageGlobalorLocal;	//
		public String CKYCImageExtension;	//jpg
	}
}