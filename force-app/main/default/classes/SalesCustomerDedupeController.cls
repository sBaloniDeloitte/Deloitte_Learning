public  without sharing class  SalesCustomerDedupeController {
	public class InputWrapper{
		@AuraEnabled public String loanId;
		@AuraEnabled public String applicantId;
		@AuraEnabled public String panNumber;
		@AuraEnabled public String custUniqueId;
		@AuraEnabled public String source;
		@AuraEnabled public String accId;
		@AuraEnabled public Account accToBeTagged;
		@AuraEnabled public String custId;
		@AuraEnabled public String ucic;
		@AuraEnabled public Boolean fromDedupeCmp= false;
	}
	public class ResponseWrapper{
		@AuraEnabled public String result;
		@AuraEnabled public Boolean freshCustomer;
		@AuraEnabled public String loanId;
		@AuraEnabled public String custId;
		@AuraEnabled public Boolean isAPISuccess;
	}	
	@AuraEnabled
	public static ResponseWrapper checkCustomerDedupe(String inputStr){
		String finalResp;
		ResponseWrapper finalResponse = new ResponseWrapper();
		finalResponse.freshCustomer = true;
		InputWrapper reqWrap = (InputWrapper)JSON.deserialize(inputStr, InputWrapper.class);
		String appId = reqWrap.applicantId;
		String loanId = reqWrap.loanId;
		String panNum = reqWrap.panNumber;
		finalResponse.loanId = loanId;
		finalResponse.isAPISuccess = false;
		List<Application_Applicant__c> currentApplicant = [Select Id,DOB__c,Applicant_Name__c,Customer__c,Customer__r.UCIC_Number__c,Drivers_License_Number__c,Voter_ID_Number__c,
														Pan_Name__c, DOI__c,Customer_Type__c,PAN_Number__c,Name_of_Organization__c,First_Name__c,Middle_Name__c,
														Last_Name__c,Mobile_Number__c,Aadhaar_Number__c,Passport_Number__c,Customer__r.Applicant_Identifier__c,Customer__r.Customer_Type__c
														from Application_Applicant__c where Id =: appId limit 1];
         System.debug('current applicant>'+currentApplicant);
		Map<String, String> inputMap = new Map<String, String>();
        
		String dobOrdoi;
		finalResponse.custId = currentApplicant[0].Id;
        if(currentApplicant[0].DOB__c!=null){
            dobOrdoi = String.valueof(currentApplicant[0].DOB__c);
        }
        else if(currentApplicant[0].DOI__c!=null){
            dobOrdoi = String.valueof(currentApplicant[0].DOI__c);
        }
		System.debug('currentApplicant[0].Pan_Name__c'+currentApplicant[0].Pan_Name__c);
        inputMap.put('loanId',loanId);
        inputMap.put('applicantId',appId);
        inputMap.put('processName','UCIC De Dupe Check');
        inputMap.put('panNumber',panNum);
        inputMap.put('panName',currentApplicant[0].Applicant_Name__c);
        inputMap.put('dob',dobOrdoi);
        inputMap.put('mobileNumber',String.valueOf(currentApplicant[0].Mobile_Number__c));
        inputMap.put('dlNumber',currentApplicant[0].Drivers_License_Number__c);
        inputMap.put('voterNumber',currentApplicant[0].Voter_ID_Number__c);
        inputMap.put('aadharNumber',currentApplicant[0].Aadhaar_Number__c);
        String resp;
		List<Integration_Details__c> integrationList = new List<Integration_Details__c>();
		try{
        	resp = COMM_UCICController.initiateAPIRequest(inputMap);
			List<String> custIdExisiting = new  List<String> ();
			Map<String,Account> custToAccountMap = new Map<String,Account>  ();
        COMM_UCICController.UCICDeduplicationInfo dedupeInfo = new COMM_UCICController.UCICDeduplicationInfo();
        dedupeInfo = (COMM_UCICController.UCICDeduplicationInfo)JSON.deserialize(resp,COMM_UCICController.UCICDeduplicationInfo.class);
		finalResponse.isAPISuccess = dedupeInfo.isAPISuccess;
		if(dedupeInfo.integrationDetails != null){
			finalResp = dedupeInfo.integrationDetails.responseBody;
			
			Integration_Details__c integrationDetail = new Integration_Details__c();
			integrationDetail.Calling_Source__c = 'PLF';
			integrationDetail.Request_JSON__c = dedupeInfo.integrationDetails.requestStr;
			// if( dedupeInfo.integrationDetails.responseBody!=null &&  dedupeInfo.integrationDetails.responseBody.length()>131072){
			// 	integrationDetail.Response_JSON__c = dedupeInfo.integrationDetails.responseBody.substring(0, 131072);
			// }
			// else{
			// 	integrationDetail.Response_JSON__c =  dedupeInfo.integrationDetails.responseBody;
			// }
			
			integrationDetail.Status__c = dedupeInfo.integrationDetails.statusCode;
			integrationDetail.Method_Type__c = dedupeInfo.integrationDetails.methodType;
			integrationDetail.EndPoint__c = dedupeInfo.integrationDetails.endpoint;
			integrationDetail.Object_Name__c = 'Application_Applicant__c';
			integrationDetail.Name = dedupeInfo.integrationDetails.name;
			integrationDetail.Loan_Application__c = loanId;
			integrationDetail.Related_Record_Id__c = appId;
			integrationList.add(integrationDetail);
		}
		if(dedupeInfo == null || dedupeInfo.freshCustomer){
			if(String.isBlank(currentApplicant[0].Customer__r.UCIC_Number__c)){
				Map<String, String> ucicCreateInputMap = new Map<String, String>();
                ucicCreateInputMap.put('recordId',loanId);
                ucicCreateInputMap.put('applicantId',appId);
                ucicCreateInputMap.put('processName','UCIC Search AND Create');
                ucicCreateInputMap.put('panNum',panNum);
                ucicCreateInputMap.put('dob',dobOrdoi);
                UCICCreateAndSearchCustomerController.initiateAPIRequest(ucicCreateInputMap);
			}
		}
		else if(dedupeInfo.duplicateCustomers != null && !dedupeInfo.duplicateCustomers.isEmpty()){
			finalResponse.freshCustomer = false;
			for (COMM_UCICController.CustomerMatch match : dedupeInfo.duplicateCustomers) {
                if(match.customerId != null && match.customerId != ''){
					custIdExisiting.add(match.customerId);
                }
            }
			List<Account> accToUpsert = new List<Account>();
				List<Account> accList = [Select Id, Customer_LMS_Id__c, Applicant_Identifier__c, Gender__c,Duplicate_Customer_Source__c from Account where Customer_LMS_Id__c in: custIdExisiting and Is_Active__c = true];
			Map<String,Account> lmsIdToAccMap = new Map<String,Account>();
			for(Account acc : accList){
				lmsIdToAccMap.put(acc.Customer_LMS_Id__c, acc);
			}
			String custUniqueID = appId;
            System.debug('custUniqueID------' + custUniqueID);
			List<Application_Applicant__c> appList = [Select Id from Application_Applicant__c where Customer__c =: currentApplicant[0].Customer__c and Id !=: currentApplicant[0].Id];
			if(!appList.isEmpty()){
				for(Application_Applicant__c ap : appList){
					custUniqueID = custUniqueID + ','+ap.Id;
				}
			}
			Boolean panMatchFound = false;
            Integer panMatchCount = 0;
			for(COMM_UCICController.CustomerMatch match : dedupeInfo.duplicateCustomers){
                String decodedMatchReason = match.matchReason != null ? match.matchReason.replaceAll('&#124;', '|').toLowerCase() : '';
                if(decodedMatchReason.contains('pan')&&  currentApplicant[0].Customer_Type__c == match.customerType  && dedupeInfo.ucictype!='T'){
                    panMatchCount++;
                }
            }
			for (COMM_UCICController.CustomerMatch match : dedupeInfo.duplicateCustomers) {
                String decodedMatchReason = match.matchReason != null ? match.matchReason.replaceAll('&#124;', '|').toLowerCase() : '';
                Boolean isPanMatch = decodedMatchReason.contains('pan');
				if(isPanMatch && panMatchCount == 1 && !panMatchFound && currentApplicant[0].Customer__r.Customer_Type__c == match.customerType && dedupeInfo.ucictype!='T') {
					InputWrapper updateCustReq = new InputWrapper();
					updateCustReq.loanId = loanId;
					updateCustReq.applicantId = appId;
					updateCustReq.custUniqueId = custUniqueID;
					updateCustReq.panNumber = panNum;
					updateCustReq.source = 'PLF';
					if(lmsIdToAccMap.containsKey(match.customerId)){
						updateCustReq.accToBeTagged = lmsIdToAccMap.get(match.customerId);
					}
					else{
					}
					updateCustReq.custId = match.customerId;
					UpdateResponseWrap result = updateApplicantRecords(JSON.serialize(updateCustReq));
					if(result.intDetails != null){
						integrationList.add(result.intDetails);
					}
					panMatchFound = true;
				}
				else{
					Account acc = new Account();
					if(lmsIdToAccMap.containsKey(match.customerId)){
						acc = lmsIdToAccMap.get(match.customerId);
					}
					acc.Name = match.name != null ? match.name : 'Unknown Customer';
					acc.Customer_LMS_Id__c = match.customerId;
					acc.PAN_Number__c = match.panNumber!=null?match.panNumber :'';
					if(acc.Gender__c == 'M'){
						acc.Gender__c = 'Male';
					}
					else if(acc.Gender__c == 'F'){
						acc.Gender__c = 'Female';
					}
					acc.Mobile_Number__c = match.mobileNumber;
					acc.Date_of_Birth__c = match.dob;
					acc.Duplicate_Customer_Source__c = 'PLF';
					acc.Match_Response__c = match.matchReason;
					acc.UCIC_Number__c = match.UCIC != null ? match.UCIC : '';
					acc.Customer_Type__c = match.customerType;
					if(acc.Applicant_Identifier__c != null){
						if(!acc.Applicant_Identifier__c.contains(custUniqueID)){
							acc.Applicant_Identifier__c = acc.Applicant_Identifier__c +',' +custUniqueID;
						}
					}
					else{
						acc.Applicant_Identifier__c = custUniqueID;
					}
					acc.Description = isPanMatch
						? 'Created from UCIC Deduplication (Multiple PAN matches)'
						: 'Created from UCIC Deduplication (Non-PAN match)';
					accToUpsert.add(acc);
				}
			}
			if(!accToUpsert.isEmpty()){
				Upsert accToUpsert;
			}
		}
		}
		catch(System.CalloutException e){
			if(String.isBlank(currentApplicant[0].Customer__r.UCIC_Number__c)){
				Map<String, String> ucicCreateInputMap = new Map<String, String>();
				ucicCreateInputMap.put('recordId',loanId);
				ucicCreateInputMap.put('applicantId',appId);
				ucicCreateInputMap.put('processName','UCIC Search AND Create');
				ucicCreateInputMap.put('panNum',currentApplicant[0].Pan_Number__c);
				ucicCreateInputMap.put('dob',dobOrdoi);
				UCICCreateAndSearchCustomerController.initiateAPIRequest(ucicCreateInputMap);
			}
		}
		String firstname;
        String lastName;
        String middleName;
        Date dob;
        String mobileNumber;
        String passport;
        String dl;
        String aadhar;
        String voterID;
        String address;
        String nameOfOrg;
        String panName;
		String voterIdnumber;
		Set<Id> propCustIdSet = new Set<Id>();
		List<Account> sfdcAccount = new List<Account>();
        List<Account> accToUpdateWithDup = new List<Account>();
        List<Application_Applicant__c> sameLoanApplicants = [Select id,Customer__c,Customer__r.Pan_Number__c,Pan_Number__c from Application_Applicant__c where Loan_Application__c=:loanId];
        for(Application_Applicant__c sl : sameLoanApplicants){
            propCustIdSet.add(sl.Customer__c);
        }
		if(currentApplicant[0].Mobile_Number__c !=null){
			mobileNumber=currentApplicant[0].Mobile_Number__c;
		}
		if(currentApplicant[0].Pan_Number__c!=null){
			panNum =currentApplicant[0].Pan_Number__c;
			System.debug('panNumber----' +panNum);
		}
		if(currentApplicant[0].Customer_Type__c =='Individual'){
			if(currentApplicant[0].First_Name__c!=null ){
				firstname =currentApplicant[0].First_Name__c;
			}
			if(currentApplicant[0].Middle_Name__c!=null){
				middleName=currentApplicant[0].Middle_Name__c;
			}
			if(currentApplicant[0].Last_Name__c!=null){
				lastName=currentApplicant[0].Last_Name__c;
			}
			if(currentApplicant[0].DOB__c!=null){
				dob=currentApplicant[0].DOB__c;
			}
			if(currentApplicant[0].Pan_Name__c!=null){
				panName =currentApplicant[0].Pan_Name__c;
			}
			if(currentApplicant[0].Drivers_License_Number__c !=null){
				dl =currentApplicant[0].Drivers_License_Number__c;
			}
			if(currentApplicant[0].Voter_ID_Number__c !=null){
				voterIdnumber=currentApplicant[0].Voter_ID_Number__c;
			}
			if(currentApplicant[0].Passport_Number__c!=null){
				passport=currentApplicant[0].Passport_Number__c;
			}
            System.debug('Aadhar of current app>>'+currentApplicant[0].Aadhaar_Number__c);
			if(currentApplicant[0].Aadhaar_Number__c!=null){
                System.debug('inside aadhar>>');
				aadhar = (currentApplicant[0].Aadhaar_Number__c);
			}
			System.debug('aadhar>>>'+aadhar);
			System.debug('Name>>>'+panName);
			System.debug('Name>>>'+mobileNumber);
			System.debug('Name>>>'+propCustIdSet);
			sfdcAccount =[Select id,Name,Date_of_Birth__c,Customer_LMS_Id__c,Applicant_Identifier__c,Match_Response__c,Duplicate_Customer_Source__c,Pan_Number__c,Mobile_Number__c,Exisiting_Customer__c,Voter_ID_Number__c,Drivers_License_Number__c,Aadhar_Number__c,Passport_File_Number__c ,UCIC_Number__c from Account where  ((PAN_Number__c =: panNum AND  PAN_Number__c!=null) OR (Name =:panName AND Mobile_Number__c=:mobileNumber AND Date_of_Birth__c =:dob AND Name!=null AND  Date_of_Birth__c!=null AND Mobile_Number__c!=null)  OR (Voter_ID_Number__c=:voterIdnumber AND Voter_ID_Number__c!=null)  OR (Drivers_License_Number__c =:dl  AND Drivers_License_Number__c!=null) or(Aadhar_Number__c=:aadhar  AND Aadhar_Number__c!=null ) OR(Passport_File_Number__c=:passport and Passport_File_Number__c!=null  )) AND Duplicate_Customer_Source__c!='PLF' and (id!=:currentApplicant[0].Customer__c AND Id Not In : propCustIdSet) and Is_Active__c = true];
			System.debug('sfdc accounts>>'+sfdcAccount);
		}
		else{
			if(currentApplicant[0].Pan_Number__c!=null){
				panNum =currentApplicant[0].Pan_Number__c;
				System.debug('panNumber----' +panNum);
			}
			if(currentApplicant[0].Name_of_Organization__c!=null){
				nameOfOrg=currentApplicant[0].Name_of_Organization__c;
			}
			if(currentApplicant[0].DOI__c!=null){
				dob=currentApplicant[0].DOI__c;
			}
			if(currentApplicant[0].Drivers_License_Number__c !=null){
				dl =currentApplicant[0].Drivers_License_Number__c;
			}
			if(currentApplicant[0].Voter_ID_Number__c !=null){
				voterIdnumber=currentApplicant[0].Voter_ID_Number__c;
			}
			if(currentApplicant[0].Passport_Number__c!=null){
				passport=currentApplicant[0].Passport_Number__c;
			}
			if(currentApplicant[0].Aadhaar_Number__c!=null){
				aadhar =Utility.getDecryptedBase64String(currentApplicant[0].Aadhaar_Number__c);
			}
			sfdcAccount =[Select id,Name,Date_of_Birth__c,Customer_LMS_Id__c,Applicant_Identifier__c,Match_Response__c,Duplicate_Customer_Source__c,Pan_Number__c,Mobile_Number__c,Exisiting_Customer__c,Voter_ID_Number__c,Drivers_License_Number__c,Aadhar_Number__c,Passport_File_Number__c,UCIC_Number__c from Account where  ((PAN_Number__c =: panNum AND  PAN_Number__c!=null ) OR (Name =:nameOfOrg AND Mobile_Number__c=:mobileNumber AND Date_of_Birth__c =:dob AND Name!=null AND  Date_of_Birth__c!=null AND Mobile_Number__c!=null  )OR (Voter_ID_Number__c=:voterIdnumber AND Voter_ID_Number__c!=null)  OR (Drivers_License_Number__c =:dl  AND Drivers_License_Number__c!=null) or(Aadhar_Number__c=:aadhar  AND Aadhar_Number__c!=null ) OR(Passport_File_Number__c=:passport and Passport_File_Number__c!=null)) AND Duplicate_Customer_Source__c!='PLF' AND  (id!=:currentApplicant[0].Customer__c AND Id Not In : propCustIdSet) and Is_Active__c = true];
			System.debug('sfdc accounts>>'+sfdcAccount);
		}
		if(sfdcAccount.size()>0){
			finalResponse.freshCustomer = false;
			for(Account sfdcAccountFound :sfdcAccount){
                sfdcAccountFound.Duplicate_Customer_Source__c  ='Salesforce';
                if(sfdcAccountFound.Name ==panName && sfdcAccountFound.Date_of_Birth__c ==dob &&  sfdcAccountFound.Mobile_Number__c==mobileNumber &&  sfdcAccountFound.Name!=null &&  sfdcAccountFound.Date_of_Birth__c!=null && sfdcAccountFound.Mobile_Number__c!=null  ){
                    sfdcAccountFound.Match_Response__c = 'Name & Mobile Number & DOB Match';
                }
                else if( sfdcAccountFound.Voter_ID_Number__c!=null && sfdcAccountFound.Voter_ID_Number__c==voterIdnumber){
                    sfdcAccountFound.Match_Response__c = 'Voter Id';
                }
                else if( sfdcAccountFound.Drivers_License_Number__c!=null && sfdcAccountFound.Drivers_License_Number__c ==dl ){
                    sfdcAccountFound.Match_Response__c = 'Drivers License';
                }
                else if( sfdcAccountFound.Aadhar_Number__c!=null && sfdcAccountFound.Aadhar_Number__c==aadhar ){
                    sfdcAccountFound.Match_Response__c = 'Aadhar';
                }
                else if( sfdcAccountFound.Passport_File_Number__c!=null && sfdcAccountFound.Passport_File_Number__c==passport){
                    sfdcAccountFound.Match_Response__c = 'Passport';
                }
                else if(sfdcAccountFound.PAN_Number__c == panNum && sfdcAccountFound.PAN_Number__c!=null ){
                    sfdcAccountFound.Match_Response__c = 'PAN';
                }
                if( sfdcAccountFound.Applicant_Identifier__c != null){
                    if(!sfdcAccountFound.Applicant_Identifier__c.contains(currentApplicant[0].Id)){
                        sfdcAccountFound.Applicant_Identifier__c = sfdcAccountFound.Applicant_Identifier__c +',' +currentApplicant[0].Id;
                    }
                }
                else{
                    sfdcAccountFound.Applicant_Identifier__c = currentApplicant[0].Id;
                }
            }
			Update sfdcAccount;
		}
		List<Applicant_Address__c> appAdd = [Select id, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c,Full_Address__c, Pincode__c,Full_Address1__c from Applicant_Address__c where Applicant__c=:appId AND Full_Address1__c!=null ];
		List<String> addressToBeMatched = new List<String>();
		for(Applicant_Address__c appAddToBeChecked : appAdd){
			addressToBeMatched.add(appAddToBeChecked.Full_Address1__c);
		}
        System.debug('addressToBeMatched=:'+addressToBeMatched);
		List<Customer_Address__c> custSFDCacc = [Select id,Full_Address1__c,Customer__r.Applicant_Identifier__c from Customer_Address__c where Full_Address1__c IN :addressToBeMatched  and Customer__c Not In : propCustIdSet];
        if(custSFDCacc.size()>0){
			finalResponse.freshCustomer = false;
            List<Account> custAccList = new List<Account>();
            for(Customer_Address__c cust : custSFDCacc){
                Account accCustomer = new Account();
                accCustomer.id = cust.Customer__c;
                if(cust.Customer__r.Applicant_Identifier__c!= null){
                    if(!cust.Customer__r.Applicant_Identifier__c.contains(currentApplicant[0].Id)){
                        
                        accCustomer.Applicant_Identifier__c=cust.Customer__r.Applicant_Identifier__c+',' +currentApplicant[0].Id;
                    }
                }
                else{
                    accCustomer.Applicant_Identifier__c= currentApplicant[0].Id;
                }
                accCustomer.Match_Response__c = 'Address';
                custAccList.add(accCustomer);
            }
            update custAccList;
        }
		if(!integrationList.isEmpty()){
			ContentVersion responseContent = new ContentVersion();
			responseContent.Title = 'dedupeResponse'+appId+'_TXT';
			responseContent.PathOnClient = 'dedupeResponse'+appId+'.txt';
			responseContent.VersionData = Blob.valueOf(finalResp);//Blob.valueOf(restReq.requestBody.toString());
			insert responseContent;
			Insert integrationList;
			List<ContentVersion> dedupeResponseVersion = [Select Id, ContentDocumentId from ContentVersion where id =: responseContent.Id];
			ContentDocumentLink cdl2 = new ContentDocumentLink();
			cdl2.ContentDocumentId = dedupeResponseVersion[0].ContentDocumentId;
			cdl2.LinkedEntityId = integrationList[0].Id;
			cdl2.ShareType = 'V'; // Private
			cdl2.Visibility = 'AllUsers'; // Or 'AllUsers'
			insert cdl2;
 
			
		}
		if(finalResponse.freshCustomer == true && finalResponse.isAPISuccess){
			String applicantIdToCheck = '%'+appId+'%';
			List<Account> accountToUntag = [Select id, Applicant_Identifier__c from Account where Applicant_Identifier__c!=null AND Applicant_Identifier__c LIKE:applicantIdToCheck AND Duplicate_Customer_Source__c!='Salesforce'];
			if(!accountToUntag.isEmpty()){
				for(Account acc : accountToUntag){
					String currentValues = (String)acc.get('Applicant_Identifier__c');
                    List<String> valuesList = new List<String>();
                    if (currentValues != null) {
                        valuesList = currentValues.split(',');
                    }
                    List<String> newValuelist = new List<String>();
                    for(String str : valuesList){
                        if(str != appId){
                            newValuelist.add(str);
                        }
                    }
                    String updatedValues = String.join(newValuelist, ',');
					acc.put('Applicant_Identifier__c',updatedValues);
				}
				update accountToUntag;
			}
		}

		return finalResponse;
	}
	@AuraEnabled
	public static UpdateResponseWrap updateApplicantRecords(String inputStr){
		UpdateResponseWrap finalResult = new UpdateResponseWrap();
		InputWrapper reqWrap = (InputWrapper)JSON.deserialize(inputStr, InputWrapper.class);
		List<Integration_Mapping__mdt> integrationMappings = [
            SELECT MasterLabel, Source_Value__c, Target_Value__c, GroupBy__c 
            FROM Integration_Mapping__mdt 
            WHERE GroupBy__c = 'Address_Type__c'
        ];
        System.debug('integrationMappings>>'+integrationMappings);
		String custId = reqWrap.custId;
		String applicantId = reqWrap.applicantId;
		String loanId = reqWrap.loanId;
		String custUniqueId = reqWrap.custUniqueId;
		String source = reqWrap.source;
		String accountId = reqWrap.accId;
		String ucic = reqWrap.ucic;
		if(custId != null){
			Account accToBeTagged =  reqWrap.accToBeTagged;
			Account deactivateAcc = new Account();
			List<Application_Applicant__c> currentApplicant = [Select Id,DOB__c,Customer__c,Customer__r.UCIC_Number__c,Drivers_License_Number__c,Voter_ID_Number__c, Customer__r.Customer_Type__c,
																Pan_Name__c, DOI__c,Customer_Type__c,PAN_Number__c,Name_of_Organization__c,First_Name__c,Middle_Name__c,
																Last_Name__c,Mobile_Number__c,Aadhaar_Number__c,Passport_Number__c,Customer__r.Applicant_Identifier__c, Loan_Application__c
																from Application_Applicant__c where Id =: applicantId limit 1];
			if(accToBeTagged == null){
				accToBeTagged = [Select Id, Date_of_Birth__c,Gender__c, Duplicate_Customer_Source__c, Applicant_Identifier__c  from Account where Id =: currentApplicant[0].Customer__c limit 1];
			}
			else{
				deactivateAcc = [Select Id,Duplicate_Customer_Source__c from Account where Id =: currentApplicant[0].Customer__c limit 1];
			}
			List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Cookie__c, Client_Secret__c, Endpoint__c, Content_Type__c, Authorization__c, Request_Method__c
                                                  FROM Integration_Settings__c where  Name = 'Get Customer' LIMIT 1];
			COMM_GetCustomerController.ResponseWrapper finalResp = COMM_GetCustomerController.getCustomerDetails(custId, 'Get Customer');
			Integration_Details__c integrationDetail = new Integration_Details__c();
			integrationDetail.Calling_Source__c = 'PLF';
			//integrationDetail.Response_JSON__c = finalResp.respBody;
			integrationDetail.Status__c = String.valueOf(finalResp.resp.getStatusCode());
			integrationDetail.Method_Type__c = 'GET';
			integrationDetail.EndPoint__c = intSettingList[0].Endpoint__c;
			integrationDetail.Object_Name__c = 'Application_Applicant__c';
			integrationDetail.Name = 'Get Customer API';
			integrationDetail.Loan_Application__c = loanId;
			integrationDetail.Related_Record_Id__c = applicantId;
			finalResult.intDetails = integrationDetail;
			COMM_GetCustomerController.Response custRespnse = (COMM_GetCustomerController.Response)JSON.deserialize(finalResp.respBody,COMM_GetCustomerController.Response.class);
            System.debug('custRespnse>>'+custRespnse);
			List<COMM_GetCustomerController.cls_addresses> addrFromRespList = custRespnse.addresses;
            System.debug('addrFromRespList>>'+addrFromRespList);
			
			Application_Applicant__c app = currentApplicant[0];
            if(custRespnse.personalInfo!=null){
                app.Pan_Name__c = custRespnse.personalInfo.shortName;
                Date parsedDate = Date.valueOf(custRespnse.personalInfo.dateofBirth);
                if(app.Customer_Type__c == 'Individual'){
                	app.DOB__c = parsedDate;
                }
                else{
					app.DOI__c = parsedDate;
                }
                List<String> nameParts = custRespnse.personalInfo.shortName.trim().split(' ');
                app.First_Name__c = nameParts[0];
                app.Middle_Name__c = (nameParts.size() == 3) ? nameParts[1] : '';
                app.Last_Name__c = (nameParts.size() >= 2) ? nameParts[nameParts.size() - 1] : '';
                if(custRespnse.phones!=null){
                    app.Mobile_Number__c = (custRespnse.phones != null && !custRespnse.phones.isEmpty()) 
                        ? custRespnse.phones[0].phoneNumber : null;
                }
                app.Gender__c = custRespnse.personalInfo.gender == 'F' ? 'Female' :
                custRespnse.personalInfo.gender == 'M' ? 'Male' : '';
            }
            app.PAN_Number__c = currentApplicant[0].Pan_Number__c;
			app.Customer__c = accToBeTagged.Id;
			Update app;
			if(deactivateAcc != null){
				deactivateAcc.Is_Active__c = false;
			}
			if(custRespnse.personalInfo!=null){
				Date parsedDate = Date.valueOf(custRespnse.personalInfo.dateofBirth);
				accToBeTagged.Date_of_Birth__c = parsedDate;
				if(custRespnse.personalInfo.gender =='OTH'){
					accToBeTagged.Gender__c ='Transgender';                  
				}
				else if(custRespnse.personalInfo.gender =='F'){
					accToBeTagged.Gender__c ='Female';     
				}
				else if(custRespnse.personalInfo.gender =='M'){
					accToBeTagged.Gender__c ='Male';     
				}
				else{
					accToBeTagged.Gender__c = custRespnse.personalInfo.gender;
				}
			}
			accToBeTagged.Pan_Number__c = app.Pan_Number__c;
			
			accToBeTagged.Mobile_Number__c = app.Mobile_Number__c;
			if(reqWrap.fromDedupeCmp){
				accToBeTagged.Dedupe_Disposition__c= 'Match found';
			}
			accToBeTagged.Duplicate_Customer_Source__c = (source != null) ? source : (accToBeTagged.Duplicate_Customer_Source__c == null ? 'PLF' : accToBeTagged.Duplicate_Customer_Source__c);
			accToBeTagged.Customer_LMS_Id__c = custId;
			accToBeTagged.Exisiting_Customer__c = true;
			if(ucic!=null){
				accToBeTagged.UCIC_Number__c = ucic;
			}
			accToBeTagged.Match_Response__c = 'Pan|Rule0';
			accToBeTagged.Applicant_Identifier__c = (accToBeTagged.Applicant_Identifier__c != null && !accToBeTagged.Applicant_Identifier__c.contains(custUniqueID))
				? accToBeTagged.Applicant_Identifier__c + ',' + custUniqueID
				: (accToBeTagged.Applicant_Identifier__c == null ? custUniqueID : accToBeTagged.Applicant_Identifier__c);
			update accToBeTagged;
		}
		else if(accountId != null){
			List<Account> sfdcAccount = [SELECT Id, Gender__c, Name, Date_of_Birth__c, Customer_LMS_Id__c, Applicant_Identifier__c, 
										Match_Response__c, Duplicate_Customer_Source__c, Pan_Number__c, Mobile_Number__c, 
										Exisiting_Customer__c FROM Account WHERE Id = :accountId];
			if (!sfdcAccount.isEmpty()) {
				Application_Applicant__c appDetails = new Application_Applicant__c(Id = applicantId);
				List<String> nameParts = sfdcAccount[0].Name.trim().split(' ');
				appDetails.First_Name__c = nameParts[0];
				if (nameParts.size() == 3) {
					appDetails.Middle_Name__c = nameParts[1];
					appDetails.Last_Name__c = nameParts[2];
				} else if (nameParts.size() == 2) {
					appDetails.Last_Name__c = nameParts[1];
					appDetails.Middle_Name__c = null;
				}
				else{
					appDetails.Last_Name__c = null;
					appDetails.Middle_Name__c = null;
				}
				appDetails.Pan_Name__c = sfdcAccount[0].Name;
				appDetails.PAN_Number__c = sfdcAccount[0].Pan_Number__c;
				if(appDetails.Customer_Type__c =='Individual'){
				appDetails.DOB__c = sfdcAccount[0].Date_of_Birth__c;
				}
				else{
					appDetails.DOI__c = sfdcAccount[0].Date_of_Birth__c;
				}
				appDetails.Gender__c = sfdcAccount[0].Gender__c;
				appDetails.Mobile_Number__c = sfdcAccount[0].Mobile_Number__c;
				appDetails.Customer__c = sfdcAccount[0].Id;
				update appDetails;
			}
		}
		return finalResult;
	}
	public class UpdateResponseWrap{
		@AuraEnabled public Integration_Details__c intDetails;
		@AuraEnabled public String errorMsg;
	}
}