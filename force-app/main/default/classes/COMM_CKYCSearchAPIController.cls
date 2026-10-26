/**
* @File Name : CKYCSearchAPIController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 31, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 31, 2025 |   | Initial Version
**/

public with sharing class COMM_CKYCSearchAPIController {
    static string conLabels = 'CKYC_API,Current,Permanent';
    public static Map<string, string> constantsMeta = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constantsMeta;
    }

	@AuraEnabled
    public static String processCkycSearchAPI(Map<String,String> inputMap){
        Integration_Details__c integrationDetail = new Integration_Details__c();
        try {
			String loanId = inputMap.get('loanId');
			String applicantId = inputMap.get('applicantId');
			String processName = inputMap.get('processName');
            String idType = inputMap.get('idType');
            String idNumber = inputMap.get('idNumber');
            String ckycId;
            String ckycTransactionId = '';
            String ckycReferenceIdCorp ='';
            String ckycStatus = '';
		
			String returnResp;
			String resultMessage;
			List<Application_Applicant__c> applicantList = [Select Id,Applicant_Name__c,Loan_Application__c,PAN_Number__c,Customer_Type__c,Customer__c FROM Application_Applicant__c WHERE Id =: applicantId LIMIT 1];
            Application_Applicant__c app = applicantList[0];
			Integration_Master__mdt metadata = [SELECT 
													Process_Name__c,Product_Type__c,Product_Version__c,
													Handler_Class__c,
													Endpoint__c,
													Request_Method__c,
													Client_Id__c,
													Client_Secret__c,
													Allowed_Retry__c,
													Gestation_Period__c,
													Refresh_Allowed__c,
													Activity_Name__c,CustomerId__c,UserId__c,Password__c
												FROM Integration_Master__mdt 
												WHERE Activity_Name__c = :processName LIMIT 1];
			
			IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper(); 
            wrapper.recordId =applicantId ;
            wrapper.loanApplicationId = loanId;  
            wrapper.type = processName;
            wrapper.fileType = idType;
            wrapper.filename = idNumber;
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

            List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
            FROM Integration_Settings__c WHERE Name = 'Loan Applicant CKYC' LIMIT 1];
            Integration_Settings__c intSetting = intSettingList[0];
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name =processName ;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.Loan_Application__c = loanId;
                integrationDetail.Related_Record_Id__c = applicantId;
                integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                System.debug('resultMessage: '+resultMessage);
                returnResp = resultMessage;
            }
            else {
                Map<String, String> integrationRequestMap = new Map<String, String>();
                integrationRequestMap.put('intSettingName', 'Loan Applicant CKYC');
                integrationRequestMap.put('requestJSON', respWrapper.payload);     
                integrationRequestMap.put('Origin', Label.CKYC_Origin);    
                /*String bearer = Utility.getAccessToken();
                integrationRequestMap.put('bearer', bearer);*/
                HTTPResponse resp = Deloitte_BankSatamentAnalysisMockResp.getHttpckycMockResponse();            
                if(resp!=null && resp.getStatusCode()== 200){
                     List<Applicant_Address__c> addListCurrent =[Select id, Customer_Address__c,Address_Type__c from Applicant_Address__c where Applicant__c=:app.Id And Address_Type__c=:constantsMeta.get('Current')];
                    List<Applicant_Address__c> addListPermanent =[Select id, Address_Type__c,Customer_Address__c from Applicant_Address__c where Applicant__c=:app.Id And Address_Type__c=:constantsMeta.get('Permanent')];
                    integrationDetail.Response_JSON__c = resp.getBody();

                    String responseBody = resp.getBody();
                    String rejectionDescription ='';
                    Map<String, Object> rootMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
					if (rootMap != null && rootMap.containsKey('response')) {
						Map<String, Object> responseMap = (Map<String, Object>) rootMap.get('response');
						if (responseMap != null && responseMap.containsKey('A99ResponseData')) {
							Map<String, Object> a99Map = (Map<String, Object>) responseMap.get('A99ResponseData');
							if (a99Map != null && a99Map.containsKey('CKYCSearchResult')) {
								Object searchResultObj = a99Map.get('CKYCSearchResult');
								if (searchResultObj != null && searchResultObj instanceof Map<String, Object>) {
                                    Map<String, Object> searchResultMap = (Map<String, Object>) searchResultObj;
                                    String ckycAvailable = (String) searchResultMap.get('CKYCAvailable');
                                    if (String.isNotBlank(ckycAvailable) && ckycAvailable == 'No') {
                                        rejectionDescription = (String) searchResultMap.get('CKYCRejectionDescription');
                                    }
								}
							}
						}
					}
                    if (String.isNotBlank(rejectionDescription)) {
                        returnResp = 'Success';
                    } //DID this as the CKYCDownloadResult returns a string when CKYCAvailable in CKYCSearchResult is No. Otherwise it returns an obj
                    else{
                        CkycSearchResponseWrapper kycResp = (CkycSearchResponseWrapper) JSON.deserialize(responseBody, CkycSearchResponseWrapper.class);
                        if(kycResp!=null && kycResp.response!=null){
                            if(kycResp.response.A99ResponseData!=null && kycResp.response.A99ResponseData.CKYCDownloadResult!=null){
                                CKYCDownloadResult ckycDownloadResObj = kycResp.response.A99ResponseData.CKYCDownloadResult;
                                if(ckycDownloadResObj.CKYCStatus =='CKYCRejected' && String.isNotBlank(ckycDownloadResObj.CKYCRejectionDescription)){
                                    returnResp = 'Error:' + kycResp.response.A99ResponseData.CKYCDownloadResult.CKYCRejectionDescription;
                                    System.debug('insidee CKYC rejec scenario handle');
                                }
                                else{
                                    if (app.Customer_Type__c == 'Individual'){
                                        if(ckycDownloadResObj.CKYCStatus  == 'OTPTriggeredByCKYC'){
                                            ckycTransactionId = String.valueOf(ckycDownloadResObj.CKYCTransactionID);
                                            app.CKYC_ReferenceId__c = ckycTransactionId;
                                            update app;
                                            system.debug('Applicant CKYC Updated');
                                            returnResp = 'Success:' + '123456';
                                            //ckycStatus =ckycDownloadResObj.CKYCStatus; //will check if needs to be updated
                                        }
                                    }
                                    else if (app.Customer_Type__c == 'Non Individual'){//Non Individuallll case
                                        if(kycResp.response.A99ResponseData.CKYCSearchResult!=null){
                                            CKYCSearchResult searchResultObj = kycResp.response.A99ResponseData.CKYCSearchResult;
                                            if(searchResultObj.CKYCPIdDetails!=null && searchResultObj.CKYCPIdDetails.CKYCPID!=null){
                                                ckycReferenceIdCorp = searchResultObj.CKYCPIdDetails.CKYCPID.CKYCReferenceID;
                                                returnResp = 'Success:' + '123456';
                                            }
                                        }
                                    
                                        if(ckycDownloadResObj.CKYCStatus == 'CKYCSuccess'){
                                            Map<String,Document_Details__c> docTitleToDocMap = new Map<String,Document_Details__c>();
                                            //INSERT IMAGE
                                            List<String> contentVersionIdsList = new List<String>();
                                            if(ckycDownloadResObj.CKYCImageDetails!=null && ckycDownloadResObj.CKYCImageDetails.CKYCImageDetails.size()>0){
                                                for(CKYCImageDetails ckycImageObj : ckycDownloadResObj.CKYCImageDetails.CKYCImageDetails){
                                                    if(String.isNotBlank(ckycImageObj.CKYCImageData)){
                                                        contentVersionIdsList.add(ckycImageObj.CKYCImageData);
                                                    }
                                                }
                                                if(contentVersionIdsList.size()>0){
                                                    docTitleToDocMap = COMM_CKYCFetchRecordController.storeCkycImageChecklist(contentVersionIdsList,app.id,loanId);
                                                }
                                            }
                                            //MAPPPING APPLICANT DET STARTSS
                                            app.DOI__c = String.isNotBlank(ckycDownloadResObj.CKYCDOB) ? COMM_CKYCFetchRecordController.stringToDateParsing(ckycDownloadResObj.CKYCDOB) : null; //DOI
                                            app.Name = String.isNotBlank(ckycDownloadResObj.CKYCFullName) ? ckycDownloadResObj.CKYCFullName : '';
                                            app.Name_of_Organization__c = String.isNotBlank(ckycDownloadResObj.CKYCFullName) ? ckycDownloadResObj.CKYCFullName : '';
                                            app.PAN_Number__c = String.isNotBlank(ckycDownloadResObj.CKYCPAN) ? ckycDownloadResObj.CKYCPAN : '';
                                            //for father & spouse confirm from Sreenivasan if diferent tags will be there for a married applicant
                                            app.CKYC_ReferenceId__c = String.isNotBlank(ckycDownloadResObj.CKYCReferenceID) ? ckycDownloadResObj.CKYCReferenceID : '123456';
                                            //app.CKYC_AccountType__c = String.isNotBlank(ckycDownloadResObj.CKYCAccType) ? Integer.valueOf(ckycDownloadResObj.CKYCAccType) : null;
                                            app.Mobile_Number__c = ckycDownloadResObj.CKYCMobileNumber!=null ? String.valueOf(ckycDownloadResObj.CKYCMobileNumber) : '';
                                            app.CKYC_KIN__c = ckycDownloadResObj.CKYCNumber!=null ? String.valueOf(ckycDownloadResObj.CKYCNumber) : '';  //we are receiving ref id and no both in Non Indi
                                            update app;
                                            //MAPPING APPLICANT DET ENDS
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
                                            List<Pincode_Master__c> pinList = [SELECT Id FROM Pincode_Master__c WHERE Name = :String.valueOf(ckycDownloadResObj.CKYCPerAddPin) LIMIT 1];
                                            appPermAdd.Pincode__c = !pinList.isEmpty() ? pinList[0].Id : null;
                                            appPermAdd.Document_Details__c =  docTitleToDocMap.containsKey(ckycDownloadResObj.CKYCPerAddPOA) ?  docTitleToDocMap.get(ckycDownloadResObj.CKYCPerAddPOA).Id : null; //mapping doc Detail
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
                                            List<Pincode_Master__c> pinListCurrent = [SELECT Id FROM Pincode_Master__c WHERE Name = :String.valueOf(ckycDownloadResObj.CKYCCorAddPin) LIMIT 1];
                                            appCurrentAdd.Pincode__c = !pinListCurrent.isEmpty() ? pinListCurrent[0].Id : null;
                                            appCurrentAdd.Document_Details__c = docTitleToDocMap.containsKey(ckycDownloadResObj.CKYCCorAddPOA) ?  docTitleToDocMap.get(ckycDownloadResObj.CKYCCorAddPOA).Id : null;
                                            appCurrentAdd.CKYC_POA_Submitted__c = String.isNotBlank(ckycDownloadResObj.CKYCCorAddPOA) ? ckycDownloadResObj.CKYCCorAddPOA : '';
                                            appCurrentAdd.Applicant__c=app.id;
                                            appCurrentAdd.Loan_Application__c = loanId;
                                            Upsert appCurrentAdd;
                                            //updating applicant Now
                                        }
                                    }
                                    else{
                                        returnResp ='Customer Type is Blank on Applicant';
                                    }
                                }
                            }
                        }
                    }
                    

                    // Save to DB only if  OTPTriggered
                    if (/*String.isBlank(ckycId) || */String.isNotBlank(ckycTransactionId) || String.isNotBlank(ckycReferenceIdCorp)) {
                        List<Triangulation_Data__c> existingRecords = [
                            SELECT Id, CKYCID__c, CKYC_Transaction_Id__c ,CKYC_Doc_Type__c,CKYC_Doc_ID__c,API_hit_count__c,CKYC_Reference_Id__c FROM Triangulation_Data__c
                            WHERE Loan_Application__c = :loanId AND Application_Applicant__c = :applicantId AND Source_Type__c = 'CKYC' ORDER BY CreatedDate DESC LIMIT 1
                        ];

                        Triangulation_Data__c triData;
                        if (!existingRecords.isEmpty()) {
                            triData = existingRecords[0];
                           // triData.CKYCID__c = ckycId;
                            triData.CKYC_Doc_Type__c = idType; //doing this to control the UI on conn callback so that if all goes well this will be shown on UI as disabled
                            triData.CKYC_Doc_ID__c = idNumber;
                            triData.CKYC_Transaction_Id__c = String.isNotBlank(ckycTransactionId) ? ckycTransactionId : '';
                            triData.CKYC_Reference_Id__c = String.isNotBlank(ckycReferenceIdCorp) ? ckycReferenceIdCorp : '';
                            triData.API_hit_count__c = triData.API_hit_count__c == null ? 1 : triData.API_hit_count__c + 1;												
                            update triData;
                        } else {
                            triData = new Triangulation_Data__c(
                                Loan_Application__c = loanId,
                                Application_Applicant__c = applicantId,
                                Source_Type__c = 'CKYC',
                                //CKYCID__c = ckycId,
                                CKYC_Doc_Type__c = idType,
                                CKYC_Doc_ID__c = idNumber,
                                CKYC_Reference_Id__c = String.isNotBlank(ckycReferenceIdCorp) ? ckycReferenceIdCorp : '',
                                CKYC_Transaction_Id__c = String.isNotBlank(ckycTransactionId) ? ckycTransactionId : '',
                                API_hit_count__c = 1
                            );
                            insert triData;
                        }
                    }

                    integrationDetail.Status__c = String.valueof(resp.getStatusCode());
                    integrationDetail.Name =processName ;
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                   	integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                    integrationDetail.Loan_Application__c = loanId;
                    integrationDetail.Related_Record_Id__c = applicantId;
                    integrationDetail.Request_JSON__c = respWrapper.payload;
				}
                else if(resp.getStatusCode()== 503 || resp.getStatusCode()== 504 || resp.getStatusCode()== 502)
                {
                    integrationDetail.Status__c = String.valueof(resp.getStatusCode());
                    integrationDetail.Name = processName;
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Loan_Application__c = loanId;
                    integrationDetail.Related_Record_Id__c = applicantId;
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                    integrationDetail.Request_JSON__c = respWrapper.payload; 
                    returnResp = 'Error: Search API Service Temporarily Unavailable';
				}
                else{
                    integrationDetail.Status__c = String.valueof(resp.getStatusCode());
                    integrationDetail.Name = processName;
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Loan_Application__c = loanId;
                    integrationDetail.Related_Record_Id__c = applicantId;
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                    integrationDetail.Request_JSON__c = respWrapper.payload;
                    returnResp = 'Error:' + resp.getBody();
                }
            }
                insert integrationDetail;
				return returnResp;    
               
		}
		catch (Exception e) {
			throw new AuraHandledException(e.getMessage() + e.getStackTraceString());
		}
	}

    public class CkycSearchResponseWrapper{
	public response response;
    }
	class response {
		public A99ResponseData A99ResponseData;
	}
	class A99ResponseData {
		public CKYCDownloadResult CKYCDownloadResult;
		//public String xmlns:xsi;	//http://www.w3.org/2001/XMLSchema-instance
		//public String xmlns:xs;	//http://www.w3.org/2001/XMLSchema
		public CKYCSearchResult CKYCSearchResult;
		public String RequestStatus;	//AcceptedByTW
	}
	class CKYCDownloadResult {
		public String CKYCFormSixty;	//No
		public CKYCIDDetails CKYCIDDetails;
		public String CKYCStatus;	//CKYCSuccess
		public Integer CKYCTransactionID;	//13200009
		public String CKYCSuccessDescription;	//OTP has been sent to the registered mobile numberXXXXXX9950
        public String CKYCRejectionDescription;
		public String CKYCKYCVerificationDesg;	//Manager
		public String CKYCCorAddPOA;	//
		public String CKYCPAN;	//GNYPM9875D
		public String CKYCKYCVerificationBranch;	//Mumbai
		public String CKYCKYCVerificationName;	//Manish Vichare
		public String CKYCPerAddCity;	//Thane
		public String CKYCOffTelNumber;	//
		public Integer CKYCMobileISD;	//91
		public String CKYCMobileISD2;	//
		public Long RequestId;	//1758792238531
		public String CKYCDateofDeclaration;	//04-Aug-2025
		public String CKYCDOB;	//01-Aug-2017
		public String CKYCPOAOthersValue;	//UDYAM
		public String CKYCCorAddCity;	//Thane
		public Long CKYCMobileNumber;	//7738282592
		public Integer CKYCNumberofRelatedPersons;	//0
		public String CKYCCorAdd2;	//thane
		public String CKYCCorAdd1;	//302 Centrum it park
		public String CKYCPlaceofDeclaration;	//Mumbai
		public String CKYCCorAdd3;	//
		public String CKYCReferenceID;	//LEVNLM16359723
		public String ApplicationFormNo;	//
		public Integer CKYCPerAddPin;	//400604
		public Integer CKYCCorAddPin;	//400604
		public String CKYCKYCVerificationDate;	//19-Aug-2025
		public String CKYCPerAddState;	//MH
		public String CKYCOffTelSTD;	//
		public Integer CKYCNumberofImages;	//2
		public String CKYCPerAddSameasCorAdd;	//Y
		public String CKYCRelatedPersonDetails;	//
		public String CKYCPerAddDistrict;	//Thane
		public String CKYCEmailAdd2;	//
		public Integer CKYCKYCVerificationEmpcode;	//716801
		public String CKYCFullName;	//Khan Enterprise
		public CKYCImageDetails CKYCImageDetails;
		public String CKYCConstiType;	//A
		public String CKYCPerAdd1;	//302 Centrum it park
		public String CKYCPerAdd3;	//
		public String CKYCPerAdd2;	//thane
		public Long CKYCNumber;	//70086765618244
		public Integer CKYCNumberofIds;	//1
		public String CKYCCorAddCountry;	//IN
		public String CKYCEmailAdd;	//
		public String CKYCCorAddState;	//MH
		public String CKYCMobileNumber2;	//
		public String CKYCPerAddPOA;	//OthersPOACKYCInd
		public String CKYCCorAddDistrict;	//Thane
		public String CKYCTypeofDocSubmitted;	//01
		public String CKYCPerAddCountry;	//IN
		public String ConstitutionTypeOthers;	//
		public String CKYCRemarks;	//
	}
	class CKYCIDDetails {
		public CKYCIdentityDetails CKYCIdentityDetails;
	}
	class CKYCIdentityDetails {
		public String CKYCIDType;	//09
		public String CKYCIDVerificationStatus;	//
		public Integer CKYCIDSequence;	//1
		public String CKYCIDNumber;	//
	}
	class CKYCImageDetails {
		public CKYCImageDetails[] CKYCImageDetails;
		public String CKYCImageData;	//068C2000003pC8fIAE
		public String CKYCImageBranch;	//
		public String CKYCImageType;	//AP1
		public Integer CKYCImageSequence;	//1
		public String CKYCImageExtension;	//jpg
	}
	class CKYCSearchResult {
		public String CKYCAvailable;	//Yes
		public CKYCPIdDetails CKYCPIdDetails;
		public String CKYCRejectionDescription;
		public Long CKYCRequestId;
		public Long RequestId;	//1758792238531
		public String ApplicationReferenceNumber;	//
		public String CKYCStatus;	//CKYCSuccess
		public String CKYCRequestDate;	//25-Sep-2025
		public String Tags;	//
	}
	class CKYCPIdDetails {
		public CKYCPID CKYCPID;
	}
	class CKYCPID {
		public String CKYCReferenceID;	//LEVNLM16359723
		public String CKYCAccType;	//Normal
		public String CKYCID;	//XXXXXXXXXX8244
		//public CKYCIDDetails CKYCIDDetails;
		public String CKYCGenDate;	//21-Aug-2025
		public String CKYCUpdatedDate;	//21-Aug-2025
		public String RecordCategory;	//LE
		public String CKYCName;	//Khan Enterprise
		public String ConstitutionType;	//A-Sole Proprietorship
		public Integer CKYCAge;	//8
		public String CKYCRemarks;	//
	}
	/*class ID {
		public String CKYCIDRemarks;	//
		public String CKYCAvailableIDType;	//C
		public String CKYCAvailableIDTypeStatus;	//03
	}*/
}