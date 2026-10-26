public without sharing class COMM_CommercialCrifGetData {

	@AuraEnabled
    public static String processCommercialCrifResponse(Map<String,String> inputMap){

        try {
			Integration_Details__c integrationDetail = new Integration_Details__c();
			
			String loanId = inputMap.get('loanId');
			String applicantId = inputMap.get('applicantId');
			String processName = inputMap.get('processName');
			String returnResp;
			String resultMessage;
			List<Integration_Details__c> detailList = [SELECT Id, Response_JSON__c  FROM Integration_Details__c WHERE Name = 'Loan Crif Report Id' AND Loan_Application__c = :loanId AND Related_Record_Id__c = :applicantId ORDER BY CreatedDate DESC LIMIT 1];

				String updatedRequest = '';
				if (!detailList.isEmpty()) {
					updatedRequest = detailList[0].Response_JSON__c ;
				}

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
			
			List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
			FROM Integration_Settings__c WHERE Name = 'Loan Applicant CRIF Commercial' LIMIT 1];
			Integration_Settings__c intSetting = intSettingList[0];
			Application_Applicant__c app = [
                SELECT Id, First_Name__c, Last_Name__c, DOI__c,DOB__c,Sector__c, PAN_Number__c, Mobile_Number__c, Email__c,
                       Loan_Application__c, Loan_Application__r.Lead__c
                FROM Application_Applicant__c WHERE Id = :applicantId LIMIT 1
            ];

			String encryptedXML = COMM_CrifEncryptionUtil.prepareEncryptedCrifRequest(updatedRequest);
            Map<String, String> requestMap = new Map<String, String>();
				requestMap.put('encryptedData', encryptedXML);
				requestMap.put('hit', '1');
				requestMap.put('fileFormate', 'XML');
			 updatedRequest = JSON.serialize(requestMap);

			Map<String, String> integrationRequestMap = new Map<String, String>();
			String bearer = Utility.getAccessToken();
                integrationRequestMap.put('bearer', bearer);
				integrationRequestMap.put('intSettingName', 'Loan Applicant CRIF Commercial');
				integrationRequestMap.put('requestJSON', updatedRequest);
				//integrationRequestMap.put('userId', metadata.UserId__c);
				//integrationRequestMap.put('password', metadata.Password__c);
				//integrationRequestMap.put('customerId', metadata.CustomerId__c);
				//integrationRequestMap.put('productType', metadata.Product_Type__c);
                //integrationRequestMap.put('productVersion', metadata.Product_Version__c); 
				//integrationRequestMap.put('endPoint', metadata.Endpoint__c); 
							//String updatedXml = '<REQUEST-REQUEST-FILE><HEADER-SEGMENT><PRODUCT-TYP>COMM_ACE_PLUS_REPORT</PRODUCT-TYP><PRODUCT-VER>4.0</PRODUCT-VER><REQ-MBR>HFC0000126</REQ-MBR><SUB-MBR-ID>GODREJ HOUSING FINANCE LIMITED</SUB-MBR-ID><INQ-DT-TM>01-12-2021</INQ-DT-TM><REQ-VOL-TYP>INDV</REQ-VOL-TYP><REQ-ACTN-TYP>AT02</REQ-ACTN-TYP><TEST-FLG>Y</TEST-FLG><USER-ID>godrejhousing_uat</USER-ID><PWD>6DF60F86F86F70130E464C07472FF59ADB106EFC</PWD><AUTH-FLG>N</AUTH-FLG><AUTH-TITLE>USER</AUTH-TITLE><RES-FRMT>XML/HTML</RES-FRMT><MEMBER-PRE-OVERRIDE>N</MEMBER-PRE-OVERRIDE><RES-FRMT-EMBD>Y</RES-FRMT-EMBD><LOS-NAME>TEST</LOS-NAME><LOS-VENDER>TEST</LOS-VENDER><LOS-VERSION>1.0</LOS-VERSION><COMMERCIAL><CIR>true</CIR><SCORE>true</SCORE></COMMERCIAL><CONSUMER><CIR>true</CIR><SCORE>true</SCORE></CONSUMER></HEADER-SEGMENT><INQUIRY><INQUIRY-UNIQUE-REF-NO>1908927821COMM54647</INQUIRY-UNIQUE-REF-NO><REQUEST-DT-TM>25-07-2025</REQUEST-DT-TM><REPORT-ID>GODR250725CR382495779</REPORT-ID></INQUIRY></REQUEST-REQUEST-FILE>';
							HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
							String jsonResponse = resp.getBody();

						if(resp.getStatusCode() == 200 && (jsonResponse != null || jsonResponse != '' || !jsonResponse.contains('"ERRORS"'))){
								//System.debug('83 jsonResponse: '+jsonResponse);
									storeCrifResponseAsFile(jsonResponse, applicantid, loanId);

									String contentId = null;
									Integer sfDetailsStart = jsonResponse.indexOf('<SalesforceDetails>');
									Integer sfDetailsEnd = jsonResponse.indexOf('</SalesforceDetails>');

									if(sfDetailsStart > -1 && sfDetailsEnd > sfDetailsStart) {
										String salesforceDetailsXml = jsonResponse.substring(sfDetailsStart, sfDetailsEnd + '</SalesforceDetails>'.length());
										Integer sfIdStart = salesforceDetailsXml.indexOf('<id>');
										Integer sfIdEnd = salesforceDetailsXml.indexOf('</id>');
										if (sfIdStart > -1 && sfIdEnd > sfIdStart) {
											sfIdStart += '<id>'.length();
											contentId = salesforceDetailsXml.substring(sfIdStart, sfIdEnd);
										}
									}
									system.debug('contentId---'+contentId);
							if(contentId != null){
										storeCrifHtmlReport(contentId,applicantid, loanId);

										// Extract only the <COMMERCIAL-REPORT>...</COMMERCIAL-REPORT> portion
										Integer startIndex = jsonResponse.indexOf('<COMMERCIAL-REPORT>');
										Integer endIndex = jsonResponse.indexOf('</COMMERCIAL-REPORT>') + '</COMMERCIAL-REPORT>'.length();

										String commercialReportSegment = '';
										String tradelines = '';
											String scores = '';
										if (startIndex >= 0 && endIndex > startIndex) {
											String fullSegment = jsonResponse.substring(startIndex, endIndex);

											// Directly extract <TRADELINES>...</TRADELINES>
											Integer tradelinesStart = fullSegment.indexOf('<TRADELINES>');
											Integer tradelinesEnd = fullSegment.indexOf('</TRADELINES>') + '</TRADELINES>'.length();
											if (tradelinesStart >= 0 && tradelinesEnd > tradelinesStart) {
												tradelines = fullSegment.substring(tradelinesStart, tradelinesEnd);

												// Count <Tradeline> occurrences
												Integer tradelineCount = 0;
												Integer idx = tradelines.indexOf('<TRADELINE>');
												while (idx != -1) {
													tradelineCount++;
													idx = tradelines.indexOf('<TRADELINE>', idx + 1);
												}

												if (tradelineCount == 1) {
													// Replace using simple String.replace since tags are fixed strings (not regex)
													tradelines = tradelines.replace('<TRADELINE>', '<SINGLETRADELINE>');
													tradelines = tradelines.replace('</TRADELINE>', '</SINGLETRADELINE>');

													// Put replaced tradelines back into fullSegment
													fullSegment = fullSegment.substring(0, tradelinesStart) 
																+ tradelines 
																+ fullSegment.substring(tradelinesEnd);
												}
											}


									// Directly extract <SCORES>...</SCORES>
									Integer scoresStart = fullSegment.indexOf('<SCORES>');
									Integer scoresEnd = fullSegment.indexOf('</SCORES>') + '</SCORES>'.length();
									if (scoresStart >= 0 && scoresEnd > scoresStart) {
										scores = fullSegment.substring(scoresStart, scoresEnd);
									}
									// Construct final segment
									commercialReportSegment = '<COMMERCIAL-REPORT>' + (!String.isBlank(tradelines) ? tradelines : '')  + (!String.isBlank(scores) ? scores : '')  + '</COMMERCIAL-REPORT>';
								}

								// Convert XML to JSON
								String JSONRes = '';
								if (String.isBlank(tradelines) && String.isBlank(scores)) {
									JSONRes = '{"COMMERCIAL-REPORT":{}}';
								} else {
									JSONRes = XmlToJSONParserController.XMLToJSON(commercialReportSegment);
									JSONRes = JSONRes.replace('"__cdata":', '"cdata":');
									JSONRes = JSONRes.replace('{}', '""');
									JSONRes = replaceHyphensBetweenLetters(JSONRes);
								}
								system.debug('JSONRes-143--'+JSONRes);


								// Deserialize into wrapper
							CommercialReportWrapper report = (CommercialReportWrapper) JSON.deserialize(JSONRes, CommercialReportWrapper.class);

							Id obligationRecordTypeId = Schema.SObjectType.Income_Expense_Obligation__c.getRecordTypeInfosByName().get('Income Expense & Obligation').getRecordTypeId();
							List<Income_Expense_Obligation__c> parent = [SELECT id from Income_Expense_Obligation__c where Loan_Application__c =:loanId AND Type__c='Obligation' AND IsParent__c = true];
							if(parent.size() > 0) {
								// parent exists, do nothing
							} else {
								Income_Expense_Obligation__c parentObj = new Income_Expense_Obligation__c();
								parentObj.IsParent__c = true;
								parentObj.Loan_Application__c = loanId;
								parentObj.Type__c = 'Obligation';
								parentObj.RecordTypeId = obligationRecordTypeId; 
								insert parentObj;
							}
							List<Income_Expense_Obligation__c> bureauLstToInsert = new List<Income_Expense_Obligation__c>();
							List<Income_Expense_Obligation__c> lstToBeRemoved = [SELECT id FROM Income_Expense_Obligation__c WHERE Loan_Application__c =:loanId AND Application_Applicant__c=:applicantid AND RecordTypeId=:obligationRecordTypeId AND Bureau_Type__c = 'CRIF'];
								
							
								if (report != null  && report.COMMERCIAL_REPORT != null && report.COMMERCIAL_REPORT.TRADELINES != null) {

									TradelinesWrapper tradelinesWrapper = report.COMMERCIAL_REPORT.TRADELINES;
									 Map<String, Account_Type_Mapping__mdt> acctTypeToMetaMap = new Map<String, Account_Type_Mapping__mdt>();

                                    for (Account_Type_Mapping__mdt meta : [
                                        SELECT Id, Account_Type__c, CC_NON_CC__c, Secured_Unsecured__c 
                                        FROM Account_Type_Mapping__mdt
                                    ]) {
                                        if (meta.Account_Type__c != null) {
                                            acctTypeToMetaMap.put(meta.Account_Type__c.toLowerCase(), meta);
                                        }
                                    }

    								if (tradelinesWrapper.TRADELINE != null && !tradelinesWrapper.TRADELINE.isEmpty()) {
										for (ClsTradeline iterAccount : tradelinesWrapper.TRADELINE) {
												Income_Expense_Obligation__c iterObl = new Income_Expense_Obligation__c();

										iterObl.RecordTypeId = obligationRecordTypeId;
										iterObl.Bureau_Type__c = 'CRIF';
										iterObl.Application_Applicant__c = applicantList[0].id;
										iterObl.Loan_Application__c = applicantList[0].Loan_Application__c;

										String acctTypeKey = iterAccount.CREDIT_FACILITY_TYPE != null ? iterAccount.CREDIT_FACILITY_TYPE.toLowerCase() : null;

										iterObl.Account_Type__c = (acctTypeKey != null && acctTypeToMetaMap.containsKey(acctTypeKey)) ? acctTypeToMetaMap.get(acctTypeKey).Account_Type__c : null;
                                        
											iterObl.Loan_Amount__c = (iterAccount.SANCTIONED_AMOUNT != null && iterAccount.SANCTIONED_AMOUNT.trim() != '') ? Double.valueOf((iterAccount.SANCTIONED_AMOUNT).replaceAll(',', '')) : 0;

										iterObl.Current_Balance__c = (iterAccount.CURRENT_BALANCE != null && iterAccount.CURRENT_BALANCE.trim() != '') ? Double.valueOf((iterAccount.CURRENT_BALANCE).replaceAll(',', '')) : 0;
										iterObl.Overdue__c = (iterAccount.OVERDUE_AMOUNT != null && iterAccount.OVERDUE_AMOUNT.trim() != '') ? Double.valueOf((iterAccount.OVERDUE_AMOUNT).replaceAll(',', '')) : 0;
										// iterObl.Imputed_EMI__c = (iterAccount.INSTALLMENT_AMT !=null && iterAccount.INSTALLMENT_AMT != '') ? Double.valueOf(iterAccount.INSTALLMENT_AMT ):0;
										// iterObl.Ownership__c = iterAccount.OWNERSHIP_TYPE;

										String dateStr = iterAccount.SANCTION_DATE;
										if (dateStr != null && dateStr.length() == 10) { // Your date format is 'dd-MM-yyyy'
											// Convert from dd-MM-yyyy to yyyy-MM-dd
											String day = dateStr.substring(0, 2);
											String mon = dateStr.substring(3, 5);
											String year = dateStr.substring(6, 10);
											dateStr = year + '-' + mon + '-' + day;
											iterObl.Start_Date__c = Date.valueOf(dateStr);
										}

										String dateLastStr = String.isNotBlank(iterAccount.LAST_REPORTED_DATE) ? iterAccount.LAST_REPORTED_DATE : '';
										if (dateLastStr.length() == 10) { // dd-MM-yyyy
											String day = dateLastStr.substring(0, 2);
											String mon = dateLastStr.substring(3, 5);
											String year = dateLastStr.substring(6, 10);
											dateLastStr = year + '-' + mon + '-' + day;
											iterObl.Last_Payment_Date__c = Date.valueOf(dateLastStr);
										}

										String dateClosStr = String.isNotBlank(iterAccount.LAST_REPORTED_DATE) ? iterAccount.LAST_REPORTED_DATE : '';
										if (iterAccount.CREDIT_FACILITY_STATUS != null && iterAccount.CREDIT_FACILITY_STATUS.toUpperCase() == 'CLOSED') {
											iterObl.Type__c = 'Closed Loan';
										} else {
											iterObl.Type__c = 'Live Loan';
										}

										/*if(dateClosStr.length() == 10){
											String day = dateClosStr.substring(0,2);
											String mon = dateClosStr.substring(3,5);
											String year = dateClosStr.substring(6,10);
											dateClosStr = year+'-'+mon+'-'+day;
											iterObl.Closed_Date__c = Date.valueOf(dateClosStr);
										}*/

										String paymentHistoryStartDate = '';
										String paymentHistoryEndDate = '';
										String dpdStr = '';
										Boolean dpdTradeline = false;
										String dpdReason = '';
										Set<String> dpdList = new Set<String>{'000', 'XXX', 'STD'};

										if (String.isNotBlank(iterAccount.PAYMENT_HISTORY)) {
											List<String> monthlyRecords = iterAccount.PAYMENT_HISTORY.split('\\|');
											if (!monthlyRecords.isEmpty()) {
												paymentHistoryEndDate = monthlyRecords[monthlyRecords.size() - 1].split(',')[0];
												paymentHistoryStartDate = monthlyRecords[0].split(',')[0];
											}
											for (String record : monthlyRecords) {
												if (String.isNotBlank(record)) {
													List<String> parts = record.split(',');
													if (parts.size() > 1) {
														String dpdPart = parts[1].split('/')[0].trim();
														dpdStr += dpdPart + ' ';
														if (!dpdList.contains(dpdPart)) {
															dpdTradeline = true;
														}
													}
												}
											}
										}

										String datePaymentStartStr = String.isNotBlank(paymentHistoryStartDate) ? paymentHistoryStartDate : '';
										String datePaymentEndStr = String.isNotBlank(paymentHistoryEndDate) ? paymentHistoryEndDate : '';

										if (datePaymentStartStr.length() == 7) {
											String[] parts = datePaymentStartStr.split(':');
											if (parts.size() == 2) {
												String mon = parts[0];
												String year = parts[1];
												datePaymentStartStr = year + '-' + getMonthNumber(mon) + '-01';
											}
										}

										if (datePaymentEndStr.length() == 7) {
											String[] parts = datePaymentEndStr.split(':');
											if (parts.size() == 2) {
												String mon = parts[0];
												String year = parts[1];
												datePaymentEndStr = year + '-' + getMonthNumber(mon) + '-01';
											}
										}

										dpdStr = dpdStr.trim();
										iterObl.DPD__c = datePaymentStartStr + ' ' + dpdStr + ' ' + datePaymentEndStr;
										if (dpdTradeline) {
											iterObl.DPD_in_Tradeline__c = 'Yes';
										} else {
											if (iterAccount.SUIT_FILED_AND_WILFUL_DEFAULTS != null && String.isNotBlank(iterAccount.SUIT_FILED_AND_WILFUL_DEFAULTS.WILFUL_DEFAULTER) && iterAccount.SUIT_FILED_AND_WILFUL_DEFAULTS.SUIT_AMOUNT != '00') {
												iterObl.DPD_in_Tradeline__c = 'Yes';
												if (dpdReason != null && dpdReason != '') {
													dpdReason = dpdReason + ', Suit Filed Or Wilful Default - ' + iterAccount.SUIT_FILED_AND_WILFUL_DEFAULTS.WILFUL_DEFAULTER;
												} else {
													dpdReason = 'Suit Filed Or Wilful Default - ' + iterAccount.SUIT_FILED_AND_WILFUL_DEFAULTS.WILFUL_DEFAULTER;
												}
											} else if (String.isNotBlank(iterAccount.WRITEOFF_AMOUNT)) {
												iterObl.DPD_in_Tradeline__c = 'Yes';
												if (dpdReason != null && dpdReason != '') {
													dpdReason = dpdReason + ', Written Off Total Amount - ' + iterAccount.WRITEOFF_AMOUNT;
												} else {
													dpdReason = 'Written Off Total Amount - ' + iterAccount.WRITEOFF_AMOUNT;
												}
											} else {
												iterObl.DPD_in_Tradeline__c = 'No';
											}
										}
										iterObl.DPD_Reason__c = dpdReason;
										iterObl.Secured_Unsecured__c = acctTypeToMetaMap.containsKey(iterAccount.CREDIT_FACILITY_TYPE) ? acctTypeToMetaMap.get(iterAccount.CREDIT_FACILITY_TYPE).Secured_Unsecured__c : null;

										String datereportedStr = String.isNotBlank(iterAccount.LAST_REPORTED_DATE) ? iterAccount.LAST_REPORTED_DATE : '';
										if (datereportedStr.length() == 10) {
											String day = datereportedStr.substring(0, 2);
											String mon = datereportedStr.substring(3, 5);
											String year = datereportedStr.substring(6, 10);
											datereportedStr = year + '-' + mon + '-' + day;
											iterObl.Reported_Date__c = Date.valueOf(datereportedStr);
										}

										if (iterObl.Type__c == 'Live Loan') {
											Income_Expense_Obligation__c iterObl1 = iterObl.clone(false, true, false, false);
											iterObl1.Type__c = 'Obligation';
											iterObl1.Is_Considered_Obligation__c = true;
											bureauLstToInsert.add(iterObl1);
										}

										bureauLstToInsert.add(iterObl);
									}
								}else if (tradelinesWrapper.SingleTradeline  != null) {
										ClsTradeline iterAccount = tradelinesWrapper.SingleTradeline;
																			Income_Expense_Obligation__c iterObl = new Income_Expense_Obligation__c();
										iterObl.RecordTypeId = obligationRecordTypeId;
										iterObl.Bureau_Type__c = 'CRIF';
										iterObl.Application_Applicant__c = applicantList[0].id;
										iterObl.Loan_Application__c = applicantList[0].Loan_Application__c;

										String acctTypeKey = iterAccount.CREDIT_FACILITY_TYPE != null ? iterAccount.CREDIT_FACILITY_TYPE.toLowerCase() : null;

                                        iterObl.Account_Type__c = acctTypeKey != null && acctTypeToMetaMap.containsKey(acctTypeKey) ? acctTypeToMetaMap.get(acctTypeKey).Account_Type__c: null;                                       
                                       
											iterObl.Loan_Amount__c = (iterAccount.SANCTIONED_AMOUNT != null && iterAccount.SANCTIONED_AMOUNT != '') ? Double.valueOf((iterAccount.SANCTIONED_AMOUNT).replaceAll(',', '')) : 0;
										

										iterObl.Current_Balance__c = (iterAccount.CURRENT_BALANCE != null && iterAccount.CURRENT_BALANCE != '') ? Double.valueOf((iterAccount.CURRENT_BALANCE).replaceAll(',', '')) : 0;
										iterObl.Overdue__c = (iterAccount.OVERDUE_AMOUNT != null && iterAccount.OVERDUE_AMOUNT != '') ? Double.valueOf((iterAccount.OVERDUE_AMOUNT).replaceAll(',', '')) : 0;
										// iterObl.Imputed_EMI__c = (iterAccount.INSTALLMENT_AMT !=null && iterAccount.INSTALLMENT_AMT != '') ? Double.valueOf(iterAccount.INSTALLMENT_AMT ):0;
										// iterObl.Ownership__c = iterAccount.OWNERSHIP_TYPE;

										String dateStr = iterAccount.SANCTION_DATE;
										if (dateStr != null && dateStr.length() == 10) { // Your date format is 'dd-MM-yyyy'
											// Convert from dd-MM-yyyy to yyyy-MM-dd
											String day = dateStr.substring(0, 2);
											String mon = dateStr.substring(3, 5);
											String year = dateStr.substring(6, 10);
											dateStr = year + '-' + mon + '-' + day;
											iterObl.Start_Date__c = Date.valueOf(dateStr);
										}

										String dateLastStr = String.isNotBlank(iterAccount.LAST_REPORTED_DATE) ? iterAccount.LAST_REPORTED_DATE : '';
										if (dateLastStr.length() == 10) { // dd-MM-yyyy
											String day = dateLastStr.substring(0, 2);
											String mon = dateLastStr.substring(3, 5);
											String year = dateLastStr.substring(6, 10);
											dateLastStr = year + '-' + mon + '-' + day;
											iterObl.Last_Payment_Date__c = Date.valueOf(dateLastStr);
										}

										String dateClosStr = String.isNotBlank(iterAccount.LAST_REPORTED_DATE) ? iterAccount.LAST_REPORTED_DATE : '';
										if (iterAccount.CREDIT_FACILITY_STATUS != null && iterAccount.CREDIT_FACILITY_STATUS.toUpperCase() == 'CLOSED') {
											iterObl.Type__c = 'Closed Loan';
										} else {
											iterObl.Type__c = 'Live Loan';
										}

										/*if(dateClosStr.length() == 10){
											String day = dateClosStr.substring(0,2);
											String mon = dateClosStr.substring(3,5);
											String year = dateClosStr.substring(6,10);
											dateClosStr = year+'-'+mon+'-'+day;
											iterObl.Closed_Date__c = Date.valueOf(dateClosStr);
										}*/

										String paymentHistoryStartDate = '';
										String paymentHistoryEndDate = '';
										String dpdStr = '';
										Boolean dpdTradeline = false;
										String dpdReason = '';
										Set<String> dpdList = new Set<String>{'000', 'XXX', 'STD'};

										if (String.isNotBlank(iterAccount.PAYMENT_HISTORY)) {
											List<String> monthlyRecords = iterAccount.PAYMENT_HISTORY.split('\\|');
											if (!monthlyRecords.isEmpty()) {
												paymentHistoryEndDate = monthlyRecords[monthlyRecords.size() - 1].split(',')[0];
												paymentHistoryStartDate = monthlyRecords[0].split(',')[0];
											}
											for (String record : monthlyRecords) {
												if (String.isNotBlank(record)) {
													List<String> parts = record.split(',');
													if (parts.size() > 1) {
														String dpdPart = parts[1].split('/')[0].trim();
														dpdStr += dpdPart + ' ';
														if (!dpdList.contains(dpdPart)) {
															dpdTradeline = true;
														}
													}
												}
											}
										}

										String datePaymentStartStr = String.isNotBlank(paymentHistoryStartDate) ? paymentHistoryStartDate : '';
										String datePaymentEndStr = String.isNotBlank(paymentHistoryEndDate) ? paymentHistoryEndDate : '';

										if (datePaymentStartStr.length() == 7) {
											String[] parts = datePaymentStartStr.split(':');
											if (parts.size() == 2) {
												String mon = parts[0];
												String year = parts[1];
												datePaymentStartStr = year + '-' + getMonthNumber(mon) + '-01';
											}
										}

										if (datePaymentEndStr.length() == 7) {
											String[] parts = datePaymentEndStr.split(':');
											if (parts.size() == 2) {
												String mon = parts[0];
												String year = parts[1];
												datePaymentEndStr = year + '-' + getMonthNumber(mon) + '-01';
											}
										}

										dpdStr = dpdStr.trim();
										iterObl.DPD__c = datePaymentStartStr + ' ' + dpdStr + ' ' + datePaymentEndStr;
										if (dpdTradeline) {
											iterObl.DPD_in_Tradeline__c = 'Yes';
										} else {
											if (iterAccount.SUIT_FILED_AND_WILFUL_DEFAULTS != null && String.isNotBlank(iterAccount.SUIT_FILED_AND_WILFUL_DEFAULTS.WILFUL_DEFAULTER) && iterAccount.SUIT_FILED_AND_WILFUL_DEFAULTS.SUIT_AMOUNT != '00') {
												iterObl.DPD_in_Tradeline__c = 'Yes';
												if (dpdReason != null && dpdReason != '') {
													dpdReason = dpdReason + ', Suit Filed Or Wilful Default - ' + iterAccount.SUIT_FILED_AND_WILFUL_DEFAULTS.WILFUL_DEFAULTER;
												} else {
													dpdReason = 'Suit Filed Or Wilful Default - ' + iterAccount.SUIT_FILED_AND_WILFUL_DEFAULTS.WILFUL_DEFAULTER;
												}
											} else if (String.isNotBlank(iterAccount.WRITEOFF_AMOUNT)) {
												iterObl.DPD_in_Tradeline__c = 'Yes';
												if (dpdReason != null && dpdReason != '') {
													dpdReason = dpdReason + ', Written Off Total Amount - ' + iterAccount.WRITEOFF_AMOUNT;
												} else {
													dpdReason = 'Written Off Total Amount - ' + iterAccount.WRITEOFF_AMOUNT;
												}
											} else {
												iterObl.DPD_in_Tradeline__c = 'No';
											}
										}
										iterObl.DPD_Reason__c = dpdReason;
										iterObl.Secured_Unsecured__c = acctTypeToMetaMap.containsKey(iterAccount.CREDIT_FACILITY_TYPE) ? acctTypeToMetaMap.get(iterAccount.CREDIT_FACILITY_TYPE).Secured_Unsecured__c : null;

										String datereportedStr = String.isNotBlank(iterAccount.LAST_REPORTED_DATE) ? iterAccount.LAST_REPORTED_DATE : '';
										if (datereportedStr.length() == 10) {
											String day = datereportedStr.substring(0, 2);
											String mon = datereportedStr.substring(3, 5);
											String year = datereportedStr.substring(6, 10);
											datereportedStr = year + '-' + mon + '-' + day;
											iterObl.Reported_Date__c = Date.valueOf(datereportedStr);
										}

										if (iterObl.Type__c == 'Live Loan') {
											Income_Expense_Obligation__c iterObl1 = iterObl.clone(false, true, false, false);
											iterObl1.Type__c = 'Obligation';
											iterObl1.Is_Considered_Obligation__c = true;
											bureauLstToInsert.add(iterObl1);
										}

										bureauLstToInsert.add(iterObl);
									}
								}

							if(lstToBeRemoved.size() > 0) {
								delete lstToBeRemoved;
							}
							if(bureauLstToInsert.size() > 0) {
								insert bureauLstToInsert;
							}

							
							List<Triangulation_Data__c> crifTriangulDataLst = [SELECT Id, PAN__c, Mobile_Number__c, Date_Of_Birth__c FROM Triangulation_Data__c WHERE Loan_Application__c =: loanId AND Application_Applicant__c =: applicantId AND Document_Type__c = 'PAN' AND Source_Type__c = 'CRIF'];

							if (!crifTriangulDataLst.isEmpty()) {
								Triangulation_Data__c triangulationData = crifTriangulDataLst[0];
								triangulationData.PAN__c = app.PAN_Number__c;
								triangulationData.Mobile_Number__c = app.Mobile_Number__c;
									triangulationData.Date_of_Incorporation__c =app.DOI__c;
								update triangulationData;
							} else {
								Triangulation_Data__c triangulationData = new Triangulation_Data__c();
									triangulationData.Date_of_Incorporation__c =app.DOI__c;
								triangulationData.PAN__c =app.PAN_Number__c;
								triangulationData.Mobile_Number__c = app.Mobile_Number__c;
								triangulationData.Document_Type__c = 'PAN';
								triangulationData.Source_Type__c = 'CRIF';
								triangulationData.Loan_Application__c = loanId;
								triangulationData.Application_Applicant__c = applicantId;
								insert triangulationData;
							}
							Application_Applicant__c appdet = new Application_Applicant__c();
							Decimal crfiScore = 0;
							if (report != null
									&& report.COMMERCIAL_REPORT != null
									&& report.COMMERCIAL_REPORT.SCORES != null
									&& report.COMMERCIAL_REPORT.SCORES.SCORE.SCORE_VALUE != null) {

									String crifScoreValue = report.COMMERCIAL_REPORT.SCORES.SCORE.SCORE_VALUE;
								crfiScore = (crifScoreValue != null && crifScoreValue != '') ? Decimal.valueOf(crifScoreValue) : null;
							}

							appdet.Cibil_Score__c = crfiScore;
							appdet.Id = applicantId;
							update appdet;

				
							integrationDetail.Status__c = String.valueof(resp.getStatusCode());
							integrationDetail.Name = 'Loan Crif' ;
							integrationDetail.Object_Name__c = 'Application_Applicant__c';
							integrationDetail.Loan_Application__c = loanId;
							integrationDetail.Related_Record_Id__c = applicantId;
							integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
							integrationDetail.Request_JSON__c = updatedRequest; 
							returnResp = JSON.serialize(report);
						}
						}
						else if(resp.getStatusCode()== 503){
							integrationDetail.Status__c = String.valueof(resp.getStatusCode());
							integrationDetail.Name = 'Loan Crif' ;
							integrationDetail.Object_Name__c = 'Application_Applicant__c';
							integrationDetail.Loan_Application__c = loanId;
							integrationDetail.Related_Record_Id__c = applicantId;
							integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
							integrationDetail.Request_JSON__c = updatedRequest; 
							integrationDetail.Response_JSON__c = resp.getBody();
							returnResp = 'Error:' + 'Service Temporarily Unavailable';
						}
						else{
                                    
                            integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                        						integrationDetail.Name = 'Loan Crif Report Error' ;
							integrationDetail.Object_Name__c = 'Application_Applicant__c';
							integrationDetail.Loan_Application__c = loanId;
							integrationDetail.Related_Record_Id__c = applicantId;
							integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
							integrationDetail.Request_JSON__c = updatedRequest;
							integrationDetail.Response_JSON__c = resp.getBody();
							returnResp = 'Error:';
						}
					insert integrationDetail;
					return returnResp; 
		}
		catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
    }

	public static String replaceHyphensBetweenLetters(String input) {
		Integer chunkSize = 5000;  // Tune this size based on your testing and limits
		Integer len = input.length();
		List<String> updatedChunks = new List<String>();

		for (Integer i = 0; i < len; i += chunkSize) {
			Integer endString = Math.min(i + chunkSize, len);
			String chunk = input.substring(i, endString);

			// Replace only hyphens between letters with underscore
			String updatedChunk = chunk.replaceAll('([A-Za-z])\\-([A-Za-z])', '$1_$2');

			updatedChunks.add(updatedChunk);
		}

		return String.join(updatedChunks, '');
	}

	public static void storeCrifHtmlReport(String contentId, Id applicantId, Id loanId) {
		try {

			Document_Master__c docMaster = [SELECT Id FROM Document_Master__c WHERE Name = 'CRIF' LIMIT 1];
			if (docMaster == null) {
				//System.debug('Document Master record not found for CRIF.');
				return;
			}

			ContentVersion insertedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentId LIMIT 1];

			Document_Details__c crifDoc = new Document_Details__c();
			crifDoc.Applicant__c = applicantId;
			crifDoc.Document_Master__c = docMaster.Id;
			crifDoc.Content_Document_Id__c = insertedVersion.ContentDocumentId;
			crifDoc.Loan_Application__c = loanId;
			crifDoc.Remarks__c = 'This HTML document is created at draft stage when we hit the CRIF API.';
			crifDoc.Name = 'CRIF';
			crifDoc.Status__c = 'Uploaded';
			insert crifDoc;

			ContentDocumentLink cdl = new ContentDocumentLink();
			cdl.LinkedEntityId = crifDoc.Id;
			cdl.ContentDocumentId = insertedVersion.ContentDocumentId;
			cdl.ShareType = 'V';  // Viewer permission
			cdl.Visibility = 'AllUsers';
			insert cdl;

			//System.debug('CRIF PDF Response stored successfully: ' + crifDoc.Id);
		} catch (Exception ex) {
			System.debug('Error in storeCrifPdfReport: ' + ex.getMessage());
		}
	}

    public static void storeCrifResponseAsFile(String fullResponse, Id applicantId, Id loanId) {
        Document_Master__c docMaster = [SELECT Id FROM Document_Master__c WHERE Name = 'CRIF' LIMIT 1];

        if (docMaster != null) {
            // Create ContentVersion (File)
            ContentVersion content = new ContentVersion();
            content.Title = 'CRIF_Full_Response.txt';
            content.PathOnClient = 'CRIF_Full_Response.txt';
            content.VersionData = Blob.valueOf(fullResponse);
            content.IsMajorVersion = true;
            insert content;

            // Fetch ContentDocumentId
            ContentVersion insertedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id LIMIT 1];

            // Create Document Details record
            Document_Details__c checklist = new Document_Details__c();
            checklist.Applicant__c = applicantId;
            checklist.Document_Master__c = docMaster.Id;
            checklist.Content_Document_Id__c = insertedVersion.ContentDocumentId;
            checklist.Loan_Application__c = loanId;
            checklist.Name = 'CRIF Response';
            checklist.Status__c = 'Uploaded'; 
            insert checklist;

            // Link the document to the checklist record
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = checklist.Id;
            cdl.ContentDocumentId = insertedVersion.ContentDocumentId;
            cdl.ShareType = 'V'; 
            cdl.Visibility = 'AllUsers';
            insert cdl;

            //System.debug('CRIF full response stored successfully.');
        } else {
            System.debug('Document Master record not found for CRIF.');
            }
    }

	public static String getMonthNumber(String monthName) {
												Map<String, String> monthMap = new Map<String, String>{
													'Jan' => '01', 'Feb' => '02', 'Mar' => '03', 'Apr' => '04',
													'May' => '05', 'Jun' => '06', 'Jul' => '07', 'Aug' => '08',
													'Sep' => '09', 'Oct' => '10', 'Nov' => '11', 'Dec' => '12'
												};
												return monthMap.containsKey(monthName) ? monthMap.get(monthName) : '01';
	}

	public static Integer countTagOccurrences(String xmlString, String tagName) {
		Integer count = 0;
		Integer index = 0;
		String openTag = '<' + tagName;
		
		while (true) {
			index = xmlString.indexOf(openTag, index);
			if (index == -1) break;
			count++;
			index += openTag.length();
		} 
		return count;
	}

	public class CommercialReportWrapper {
		public COMMERCIAL_REPORT COMMERCIAL_REPORT;
	}

    public class COMMERCIAL_REPORT {
        public TradelinesWrapper TRADELINES;
        public Scores SCORES;
    }

    public class Scores {
        public Score SCORE;
    }

    public class Score {
        public String SCORE_TYPE;
        public String SCORE_VALUE;
        public String SCORE_COMMENTS;
    }

    public class TradelinesWrapper {
        public List<ClsTradeline> TRADELINE;
		public ClsTradeline SingleTradeline;
    }

    public class ClsTradeline {
        public String ACCOUNT_NO;
        public String CREDIT_GRANTOR;
        public String LAST_REPORTED_DATE;
        public String ASSET_CLASSIFICATION;
        public String CURRENT_BALANCE;
        public String DATE_ACCT_CLOSED;
        public String DPD;
        public String CREDIT_FACILITY_TYPE;
        public String CREDIT_FACILITY_STATUS;
        public String SANCTIONED_AMOUNT;
        public String SANCTION_DATE;
        public String CLOSURE_REASON;
        public String DRAWING_POWER;
        public String ISSUED_CURRENCY;
        public SuitFiledWilfulDefaults SUIT_FILED_AND_WILFUL_DEFAULTS;
        public String BORROWER_NAME;
        public String PAYMENT_HISTORY;
        public String ACCOUNT_STATUS;
        public String LENDER_TYPE;
        public String OVERDUE_AMOUNT;
        public String WRITEOFF_AMOUNT;
        public String CREDIT_FACILITY_GROUP;
        public String CUR_BAL_HIST;
        public String DERIVED_ACCOUNT_STATUS;
    }

    public class SuitFiledWilfulDefaults {
        public String WILFUL_DEFAULTER;
        public String SUIT_AMOUNT;
    }
}