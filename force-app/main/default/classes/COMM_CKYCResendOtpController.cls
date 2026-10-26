/**
* @File Name : CKYCResendOtpController.cls
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

public class COMM_CKYCResendOtpController {
	@AuraEnabled
    public static String processCommercialCrifResponse(Map<String,String> inputMap){

        try {
			Integration_Details__c integrationDetail = new Integration_Details__c();
			String loanId = inputMap.get('loanId');
			String applicantId = inputMap.get('applicantId');
			String processName = inputMap.get('processName');
			String ckycTransactionID = inputMap.get('ckycTransactionID');
			String returnResp ='';
			String resultMessage;
			List<Application_Applicant__c> applicantList = new List<Application_Applicant__c>();
			applicantList = [Select Id,Applicant_Name__c,Cibil_Score__c,DOB__c,DOI__c,Email__c,Company__c,Loan_Application__c,PAN_Number__c,Customer_Type__c FROM Application_Applicant__c WHERE Id =: applicantId];
			Integration_Master__mdt metadata = [SELECT Process_Name__c,Product_Type__c,Product_Version__c, Handler_Class__c, Endpoint__c, Request_Method__c,
													Client_Id__c, Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, Refresh_Allowed__c,
													Activity_Name__c,CustomerId__c,UserId__c,Password__c FROM Integration_Master__mdt WHERE Activity_Name__c = :processName LIMIT 1];
			
			List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c,Entity_Id__c,Message_Id__c
			FROM Integration_Settings__c WHERE Name = 'AHL CKYC' LIMIT 1];
			Integration_Settings__c intSetting = intSettingList[0];

			IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper(); 
			wrapper.recordId =applicantId ;
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
					String bearer = Utility.getAccessToken();
				integrationRequestMap.put('bearer',bearer);
				integrationRequestMap.put('intSettingName', 'AHL CKYC');
				integrationRequestMap.put('requestJSON', respWrapper.payload);     
				integrationRequestMap.put('Origin', Label.CKYC_Origin);      
				
				System.debug('integrationRequestMap ' + integrationRequestMap);

				HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
				integrationDetail.EndPoint__c = intSetting.EndPoint__c;
				integrationDetail.Loan_Application__c = loanId;
				integrationDetail.Related_Record_Id__c = applicantId;
				integrationDetail.Name =processName ;
				integrationDetail.Object_Name__c = 'Application_Applicant__c';
				integrationDetail.Request_JSON__c = respWrapper.payload;
				integrationDetail.Response_JSON__c = resp.getBody();
				integrationDetail.Status__c = String.valueof(resp.getStatusCode());
				System.debug('83 resp: '+resp);
				System.debug('ckycResp resp getStatusCode '+resp.getStatusCode());
				String responseJson = resp.getBody();
				System.debug('API Response: ' + responseJson);
				String ckycSuccessDescription ='';
				List<Triangulation_Data__c> records = [SELECT CKYC_Number__c,API_hit_count__c, CKYC_Transaction_Id__c FROM Triangulation_Data__c WHERE 
				Loan_Application__c = :loanId AND Application_Applicant__c = :applicantId AND Source_Type__c = 'CKYC' ORDER BY CreatedDate DESC LIMIT 1];

				if( responseJson != '' && responseJson != null && resp.getStatusCode()== 200){
					Map<String, Object> rootMap = (Map<String, Object>) JSON.deserializeUntyped(responseJson);
					if (rootMap != null && rootMap.containsKey('response')) {
						Map<String, Object> responseMap = (Map<String, Object>) rootMap.get('response');
						if (responseMap != null && responseMap.containsKey('A99ResponseData')) {
							Map<String, Object> a99Map = (Map<String, Object>) responseMap.get('A99ResponseData');
							if (a99Map != null && a99Map.containsKey('CKYCDownloadResult')) {
								Object downloadResultObj = a99Map.get('CKYCDownloadResult');
								if (downloadResultObj != null && downloadResultObj instanceof Map<String, Object>) {
									Map<String, Object> downloadResultMap = (Map<String, Object>) downloadResultObj;
									if (downloadResultMap.containsKey('CKYCSuccessDescription')) {
										ckycSuccessDescription = (String) downloadResultMap.get('CKYCSuccessDescription');
										if (String.isNotBlank(ckycSuccessDescription)) {
											returnResp = 'Success: '+ckycSuccessDescription;
											//getting triangulation data to increase count of api hit by 1.
											if (records.size()>0 && records[0].API_hit_count__c!=null) {
												records[0].API_hit_count__c = records[0].API_hit_count__c + 1;
												update records[0];
											}
										}
									}
									else if(downloadResultMap.containsKey('CKYCRejectionDescription')){
										ckycSuccessDescription = (String) downloadResultMap.get('CKYCRejectionDescription');
										if (String.isNotBlank(ckycSuccessDescription)) {
											returnResp = 'Error: '+ckycSuccessDescription;
										}
									}
								}
							}
						}
					}
					//edge cases handle >>>>>also  once scenarios come
					if(returnResp.contains('Please provide valid CKYCTransactionID')){ //being done to handle transactionId expired scenario
						records[0].API_hit_count__c = 0;
						update records[0];
					}

					
					//returnResp+= 'Success';
				}
				else if(resp.getStatusCode() == 502){
					returnResp = 'Error: API Service Temporarily Unavailable';
				}
				else{
					returnResp+= resp.getBody();
				}
			}
			insert integrationDetail;
			return returnResp;
		}
		catch (Exception e) {
			throw new AuraHandledException(e.getMessage() + e.getStackTraceString());
		}
	}
}