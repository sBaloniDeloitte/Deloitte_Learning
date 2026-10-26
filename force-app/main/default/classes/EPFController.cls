public class EPFController {
    @AuraEnabled
    public static EPFController checkAndHitApi(String recordId, String uanNumber, String applicantId) {
        String res = '';
        EPFController parsedResponse;
        List<Integration_Details__c> idcRecords = [
            SELECT Id, Response_JSON__c FROM Integration_Details__c 
            WHERE Loan_Application__c = :recordId AND Name = 'EPF' AND Status__c = '200' AND Related_Record_Id__c =: applicantId
        ];
        if(idcRecords.size() > 0) {
            if (String.isNotBlank(idcRecords[0].Response_JSON__c)) {
                parsedResponse = 
                        (EPFController) System.JSON.deserialize(idcRecords[0].Response_JSON__c, EPFController.class);
                return parsedResponse;
            }
        }else {
            Map<String,String> inputMap = new Map<String,String>();
            inputMap.put('loanId',recordId);
            inputMap.put('applicantId',applicantId);
            inputMap.put('processName','EPF');
            inputMap.put('uan',uanNumber);
            res = initiateAPIRequest(inputMap);
            parsedResponse = 
                        (EPFController) System.JSON.deserialize(res, EPFController.class);
            return parsedResponse;
            
        }
        
        
        return parsedResponse;
    }
	@AuraEnabled
    public static String initiateAPIRequest(Map<String,String> inputMap){
        String loanId = inputMap.get('loanId');
        String applicantId = inputMap.get('applicantId');
        String processName = inputMap.get('processName');
        String uan = inputMap.get('uan');
        String returnResp;
        String resultMessage;
        
        Integration_Master__mdt metadata = [SELECT 
                                            Process_Name__c,
                                            Handler_Class__c,
                                            Endpoint__c,
                                            Request_Method__c,
                                            Client_Id__c,
                                            Client_Secret__c,
                                            Allowed_Retry__c,
                                            Gestation_Period__c,
                                            Refresh_Allowed__c,
                                            Activity_Name__c
                                            FROM Integration_Master__mdt 
                                            WHERE Activity_Name__c = :processName LIMIT 1];
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper(); 
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
        wrapper.uan = uan;
        
        intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
        Integration_Details__c integrationDetail = new Integration_Details__c();
        if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
            integrationDetail.Status__c = String.valueof('412');
            integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
            integrationDetail.Name =processName ;
            integrationDetail.Object_Name__c = 'Application_Applicant__c';
            resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
            System.debug('resultMessage: '+resultMessage);
            returnResp = resultMessage;
        }
        else{
            String bearer=Utility.getAccessToken();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:AHL_EPFO');
            request.setMethod('POST');
            
            // Set headers
            request.setHeader('Authorization','bearer ' + bearer);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('x-karza-key', 'lkaueM605kzIIuwO');
            // Set the request body
            request.setBody(respWrapper.payload);
            
            // Create the HTTP object
            Http http = new Http();
            
            // Send the HTTP request
            HttpResponse resp = http.send(request);
            String apiResponse = resp.getBody();
            
            integrationDetail.Calling_Source__c = wrapper.type; 
            integrationDetail.Request_JSON__c = respWrapper.payload; 
            integrationDetail.Response_JSON__c = apiResponse;
            integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
            integrationDetail.Method_Type__c = wrapper.requestMethod; 
            integrationDetail.EndPoint__c = wrapper.endpoint; 
            integrationDetail.Object_Name__c = 'Application_Applicant__c';
            integrationDetail.Name = processName; 
            integrationDetail.Related_Record_Id__c = applicantId;
            integrationDetail.Loan_Application__c = loanid;
            insert integrationDetail;
            
            if(resp.getStatusCode() == 200) {
                EPFController parsedResponse = 
                        (EPFController) System.JSON.deserialize(apiResponse, EPFController.class);
                if(parsedResponse.statusCode == 101) {
                    return apiResponse;
                }
                
            }else {
                
            }
            
        }
        return returnResp;
        
    }
    
    @AuraEnabled
    public static String getUANNumber(String applicantId) {
        List<Application_Applicant__c> appObj = [SELECT id,UAN_of_Employee__c FROM Application_Applicant__c WHERE id =:applicantId];
        if(appObj.size() > 0 && String.isNotBlank(appObj[0].UAN_of_Employee__c)) {
            return appObj[0].UAN_of_Employee__c;
        }
        return null;
    }
    
    @AuraEnabled public String requestId;	//276e5b93-0782-45d2-ba1e-4e4e0d7f62cf
	@AuraEnabled public cls_result result;
	@AuraEnabled public Integer statusCode;	//101
	@AuraEnabled public cls_clientData clientData;
	public class cls_result {
		@AuraEnabled public cls_employers[] employers;
		@AuraEnabled public cls_personalDetails personalDetails;
		@AuraEnabled public cls_summary summary;
		@AuraEnabled public String remark;	//
	}
	public class cls_employers {
		@AuraEnabled public String startMonthYear;	//05-2022
		@AuraEnabled public String lastMonthYear;	//06-2023
		@AuraEnabled public String establishmentId;	//MHBANxxxxxxxxxx
		@AuraEnabled public String establishmentName;	//Perfios Software Solutions Private Limited
		@AuraEnabled public cls_address address;
		@AuraEnabled public String memberId;	//MHBANxxxxxxxxxxxxxxxxx
		@AuraEnabled public String exitReason;
		@AuraEnabled public String status;	//EMPLOYMENT_PERIOD_FOUND
	}
	public class cls_address {
		@AuraEnabled public String city;	//Worli
		@AuraEnabled public String state;	//MAHARASHTRA
		@AuraEnabled public String pincode;	//400018
		@AuraEnabled public String district;	//MUMBAI CITY
		@AuraEnabled public String address;	//1302, Orchid, Bg Kher Road Campacola Compound
	}
	
	public class cls_personalDetails {
		@AuraEnabled public String name;	//
		@AuraEnabled public String fatherOrHusbandName;
		@AuraEnabled public String aadhaarVerificationStatus;
		@AuraEnabled public String bankAccountStatus;
		@AuraEnabled public String panVerificationStatus;
		@AuraEnabled public String contactNo;
	}
	
	public class cls_summary {
		@AuraEnabled public Integer minimumWorkExperienceInMonths;	//54
		@AuraEnabled public cls_lastEmployer lastEmployer;
	}
	public class cls_lastEmployer {
		@AuraEnabled public String employerName;	//Perfios Software Solutions Private Limited
		@AuraEnabled public String startMonthYear;	//05-2022
		@AuraEnabled public String lastMonthYear;	//06-2023
		@AuraEnabled public Integer vintageInMonths;	//13
	}
	public class cls_clientData {
		@AuraEnabled public String caseId;	//123456
	}
}