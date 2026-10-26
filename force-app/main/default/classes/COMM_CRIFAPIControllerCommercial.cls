public with sharing class COMM_CRIFAPIControllerCommercial {
    static string conLabels = 'CRIF_API_COMMERCIAL';
                            
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
    
	@AuraEnabled
	public static String initiateAPIRequest(Map<String,String> inputMap){
		try {
			Integration_Details__c integrationDetails = new Integration_Details__c();
			String loanId = inputMap.get('loanId');
			String applicantId = inputMap.get('applicantId');
			String processName = inputMap.get('processName');
			String returnResp;
			String resultMessage;
			List<Application_Applicant__c> applicantList = new List<Application_Applicant__c>();
			applicantList = [Select Id,Applicant_Name__c,Cibil_Score__c,DOB__c,DOI__c,Email__c,Company__c,Loan_Application__c,PAN_Number__c,Customer_Type__c FROM Application_Applicant__c WHERE Id =: applicantId];
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
			Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(respWrapper.payload);

			String originalXML = (String) payloadMap.get('originalXML');
			String encryptedRequestJson = (String) payloadMap.get('encryptedRequestJson');

			System.debug('Original XML: ' + originalXML);
			System.debug('Encrypted Request JSON: ' + encryptedRequestJson);

			Integration_Details__c integrationDetail = new Integration_Details__c();
			List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
			FROM Integration_Settings__c WHERE Name = 'Loan Applicant CRIF Commercial' LIMIT 1];
			Integration_Settings__c intSetting = intSettingList[0];
			if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
				integrationDetail.Status__c = String.valueof('412');
				integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
				integrationDetail.Name =processName ;
				integrationDetail.Object_Name__c = 'Application_Applicant__c';
				integrationDetail.Loan_Application__c = loanId;
				integrationDetail.Related_Record_Id__c = applicantId;
				integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
				integrationDetail.Request_JSON__c = originalXML; 
								insert integrationDetail;

				resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
				System.debug('resultMessage: '+resultMessage);
				returnResp = resultMessage;
			}
			else {
				Map<String, String> integrationRequestMap = new Map<String, String>();
				System.debug('respWrapper.payload: '+respWrapper.payload);
				String bearer = Utility.getAccessToken();
                System.debug('bearer----' + bearer);
                integrationRequestMap.put('bearer', bearer);
				integrationRequestMap.put('intSettingName', 'Loan Applicant CRIF Commercial');
				integrationRequestMap.put('requestJSON', encryptedRequestJson);
				//integrationRequestMap.put('userId', metadata.UserId__c);
				//integrationRequestMap.put('password', metadata.Password__c);
				//integrationRequestMap.put('customerId', metadata.CustomerId__c);
				//integrationRequestMap.put('productType', metadata.Product_Type__c);
               // integrationRequestMap.put('productVersion', metadata.Product_Version__c); 
				//integrationRequestMap.put('endPoint', metadata.Endpoint__c);           
			
				System.debug('integrationRequestMap ' + integrationRequestMap);
				// Calling API To get the Report Id
				HTTPResponse resp1 = Utility.executeAPIRequest(integrationRequestMap);
				System.debug('83 resp: '+resp1);
				String xmlResponse1 = resp1.getBody();
				System.debug('API Response: ' + xmlResponse1);
				
				if(resp1.getStatusCode() == 200 && xmlResponse1 != null && xmlResponse1 != ''){
					String updatedXml = prepareModifiedXml(originalXML, xmlResponse1);
					System.debug('API Response1: ' + updatedXml);
					if(updatedXml != null && updatedXml != ''){
						integrationDetail.Name = 'Loan Crif Report Id';
						integrationDetail.Status__c = String.valueOf(resp1.getStatusCode());
						integrationDetail.Object_Name__c = 'Application_Applicant__c';
						integrationDetail.Loan_Application__c = loanId;
						integrationDetail.Related_Record_Id__c = applicantId;
						integrationDetail.EndPoint__c = intSetting.EndPoint__c;
						integrationDetail.Request_JSON__c = originalXML;
						integrationDetail.Response_JSON__c = updatedXml;
						insert integrationDetail;
						returnResp = updatedXml;
					}else{
						integrationDetail.Name = 'Loan Crif Report Id Error';
						integrationDetail.Status__c = String.valueOf(resp1.getStatusCode());
						integrationDetail.Object_Name__c = 'Application_Applicant__c';
						integrationDetail.Loan_Application__c = loanId;
						integrationDetail.Related_Record_Id__c = applicantId;
						integrationDetail.EndPoint__c = intSetting.EndPoint__c;
						integrationDetail.Request_JSON__c = originalXML;
						integrationDetail.Response_JSON__c = resp1.getBody();
						insert integrationDetail;
						returnResp = 'Error:';
					}
					
				}
				else{
					integrationDetail.Status__c = String.valueof(resp1.getStatusCode());
					integrationDetail.Name = 'Loan Crif' ;
					integrationDetail.Object_Name__c = 'Application_Applicant__c';
					integrationDetail.Loan_Application__c = loanId;
					integrationDetail.Related_Record_Id__c = applicantId;
					integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
					integrationDetail.Request_JSON__c = respWrapper.payload; 
					integrationDetail.Response_JSON__c = resp1.getBody();
					returnResp = 'Error:';
									insert integrationDetail;

				}
		}
							return returnResp; 
		}
		catch (Exception e) {
			system.debug('e'+ e.getLineNumber() + ' ' + e.getMessage());
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static Boolean checkIntegrationRecord(Id loanId, Id applicantId) {
		List<Integration_Details__c> records = [
			SELECT Id, Response_JSON__c 
			FROM Integration_Details__c 
			WHERE Loan_Application__c = :loanId 
			AND Related_Record_Id__c = :applicantId 
			AND Status__c = '200' AND Name = 'Loan Crif Report Id'
			LIMIT 1
		];

		if (records.isEmpty()) {
			return false;
		}

		Integration_Details__c rec = records[0];
		if (String.isBlank(rec.Response_JSON__c)) {
			return false;
		}

		try {
			// Parse XML
			Dom.Document doc = new Dom.Document();
			doc.load(rec.Response_JSON__c);
			Dom.XmlNode root = doc.getRootElement(); // REQUEST-REQUEST-FILE
			Dom.XmlNode inquiryNode = root.getChildElement('INQUIRY', null);

			if (inquiryNode != null) {
				Dom.XmlNode reportIdNode = inquiryNode.getChildElement('REPORT-ID', null);
				if (reportIdNode != null && String.isNotBlank(reportIdNode.getText())) {
					return true;
				}
			}
		} catch (Exception e) {
			System.debug('Error parsing Response_JSON__c as XML: ' + e.getMessage());
		}

		return false;
	}

	public static String prepareModifiedXml(String originalXml, String xmlResponse) {
		try {
			String inquiryUniqueRefNo = '';
			String newReportId = '';

			// Step 1: Extract INQUIRY-UNIQUE-REF-NO from original XML
			Pattern refPattern = Pattern.compile('<INQUIRY-UNIQUE-REF-NO>(.*?)</INQUIRY-UNIQUE-REF-NO>');
			Matcher refMatcher = refPattern.matcher(originalXml);
			if (refMatcher.find()) {
				inquiryUniqueRefNo = refMatcher.group(1);
			}

			// Step 2: Extract REPORT-ID from response XML
			Pattern reportIdPattern = Pattern.compile('<REPORT-ID>(.*?)</REPORT-ID>');
			Matcher reportIdMatcher = reportIdPattern.matcher(xmlResponse);
			if (reportIdMatcher.find()) {
				newReportId = reportIdMatcher.group(1);
			}

			if (String.isBlank(newReportId)) {
				return null;
			}

			// Step 3: Format current date as dd-MM-yyyy
			String requestDate = DateTime.now().format('dd-MM-yyyy');

			// Step 4: Construct new INQUIRY block
			String newInquiryBlock =
				'<INQUIRY>' +
				'<INQUIRY-UNIQUE-REF-NO>' + inquiryUniqueRefNo + '</INQUIRY-UNIQUE-REF-NO>' +
				'<REQUEST-DT-TM>' + requestDate + '</REQUEST-DT-TM>' +
				'<REPORT-ID>' + newReportId + '</REPORT-ID>' +
				'</INQUIRY>';

			// Step 5: Replace existing INQUIRY block
			originalXml = originalXml.replaceFirst(
				'<INQUIRY>[\\s\\S]*?</INQUIRY>',
				Matcher.quoteReplacement(newInquiryBlock)
			);

			// Step 6: Replace REQ-ACTN-TYP with AT02
			originalXml = originalXml.replaceAll(
				'<REQ-ACTN-TYP>.*?</REQ-ACTN-TYP>',
				'<REQ-ACTN-TYP>AT02</REQ-ACTN-TYP>'
			);

			// Step 7: Set RES-FRMT-EMBD to Y
			originalXml = originalXml.replaceAll(
				'<RES-FRMT-EMBD>.*?</RES-FRMT-EMBD>',
				'<RES-FRMT-EMBD>Y</RES-FRMT-EMBD>'
			);

			// Step 8: Set LOS-VERSION to 1.0
			originalXml = originalXml.replaceAll(
				'<LOS-VERSION>.*?</LOS-VERSION>',
				'<LOS-VERSION>1.0</LOS-VERSION>'
			);

			return originalXml;

		} catch (Exception e) {
			System.debug('Error in prepareModifiedXml: ' + e.getMessage());
			return null;
		}
	}

	}