public class GSTAuthenticationController {
	@AuraEnabled
    public static String initiateAPIRequest(Map<String,String> inputMap){
        String loanId = inputMap.get('loanId');
        String applicantId = inputMap.get('applicantId');
        String processName = inputMap.get('processName');
        String gstNumber = inputMap.get('gstNumber');
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
        wrapper.registrationNo = gstNumber;
        
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
            request.setEndpoint('Callout:AHL_GST_Authentication');
        	request.setMethod('POST');
            // Set headers
            request.setHeader('Authorization','bearer ' + bearer);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Cookie', 'JSESSIONID=t5A7XoAi0wgRKIZswgYioy6bMq9WQm5dX6pJsfFJNmejlMqxf62c!-1502083697; TS019fc7a5=01c841f7c532dac8fef8c6e93cd44dff6d56b60147aaaa21ab346bc027365d552a9559c32ffa5f465bf335cef2d4634bcbab9529c0');
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
            integrationDetail.EndPoint__c = 'Callout:AHL_GST_Authentication'; 
            integrationDetail.Object_Name__c = 'Application_Applicant__c';
            integrationDetail.Name = processName; 
            integrationDetail.Related_Record_Id__c = applicantId;
            integrationDetail.Loan_Application__c = loanid;
            insert integrationDetail;
            
            if(resp.getStatusCode() == 200) {
                GSTAuthenticationController parsedResponse = 
                        (GSTAuthenticationController) System.JSON.deserialize(apiResponse, GSTAuthenticationController.class);
                if(parsedResponse.statusCode == 101) {
                    returnResp = 'success';
                }
                
            }else {
                returnResp = apiResponse;
            }
            
        }
        return returnResp;
        
    }
    @AuraEnabled
    public static GSTNumber getGSTNumbers(String recordId, String applicantId) {
        GSTNumber gstWrap = new GSTNumber();
        gstWrap.isGSTPresent = false;
        List<String> options = new List<String>();
        List<Integration_Details__c> lstGstApiRec = [SELECT id,Response_JSON__c FROM Integration_Details__c WHERE Loan_Application__c =:recordId 
                                                     AND Related_Record_Id__c =: applicantId AND Name = 'GST Search' AND Status__c = '200'
                                                     order by createddate desc limit 1];
        if(lstGstApiRec.size() > 0 && String.isNotBlank(lstGstApiRec[0].Response_JSON__c)) {
            GSTSearchController gstAuthRes = (GSTSearchController)JSON.deserialize(lstGstApiRec[0].Response_JSON__c, GSTSearchController.class);
            if(gstAuthRes.result.size() > 0) {
                for(GSTSearchController.cls_result iterRes : gstAuthRes.result) {
                	options.add(iterRes.gstinId);
            	}
                gstWrap.isGSTPresent = true;
                gstWrap.msg = 'Record fetched.';
                gstWrap.gstOptions = options;
            }else {
                gstWrap.isGSTPresent = true;
                gstWrap.msg = 'No GSTIN number found.';
                gstWrap.gstOptions = options;
            }
            
        }else {
            gstWrap.isGSTPresent = false;
            gstWrap.msg = 'GST Search needed.';
            gstWrap.gstOptions = options;
            return gstWrap;
        }
        return gstWrap;
    }
    @AuraEnabled
    public static Boolean checkIfAlreadyFetched(String recordId, String applicantId, String gstinNumber) {
        Boolean isFetched = false;
        List<Integration_Details__c> lstGstApiRec = [SELECT id,Response_JSON__c,Request_JSON__c FROM Integration_Details__c WHERE Loan_Application__c =:recordId 
                                                     AND Related_Record_Id__c =: applicantId AND Name = 'GST Authentication' AND Status__c = '200'];
        if(lstGstApiRec.size() > 0) {
            for(Integration_Details__c iterInte : lstGstApiRec) {
                GSTAuthenticationHandler.RequestWrapper reqWrap =  (GSTAuthenticationHandler.RequestWrapper)JSON.deserialize(iterInte.Request_JSON__c, GSTAuthenticationHandler.RequestWrapper.class);
                if(reqWrap.gstin == gstinNumber) {
                    isFetched = true;
                    break;
                }

            }
        }else {
            isFetched = false;
        }
        return isFetched;
    }
    
    @AuraEnabled
    public static GSTAuthenticationController getIfAlreadyFetched(String recordId, String applicantId, String gstinNumber) {
        GSTAuthenticationController resWrap;
        List<Integration_Details__c> lstGstApiRec = [SELECT id,Response_JSON__c,Request_JSON__c FROM Integration_Details__c WHERE Loan_Application__c =:recordId 
                                                     AND Related_Record_Id__c =: applicantId AND Name = 'GST Authentication' AND Status__c = '200'];
        if(lstGstApiRec.size() > 0) {
            for(Integration_Details__c iterInte : lstGstApiRec) {
                GSTAuthenticationHandler.RequestWrapper reqWrap =  (GSTAuthenticationHandler.RequestWrapper)JSON.deserialize(iterInte.Request_JSON__c, GSTAuthenticationHandler.RequestWrapper.class);
                if(reqWrap.gstin == gstinNumber) {
                    resWrap = (GSTAuthenticationController)JSON.deserialize(iterInte.Response_JSON__c, GSTAuthenticationController.class);
                    break;
                }

            }
        }else {
            resWrap = null;
        }
        return resWrap;
    }
    
    @AuraEnabled
    public static String getPanNumber(String applicantId) {
        String pan = 'Fail';
        List<Application_Applicant__c> appObj = [SELECT id,PAN_Number__c FROM Application_Applicant__c WHERE id=:applicantId];
        if(appObj.size() > 0 && String.isNotBlank(appObj[0].PAN_Number__c)) {
            pan = appObj[0].PAN_Number__c;
        }
        return pan;
    }
    
    @AuraEnabled public String requestId;	//820d1c65-e259-4107-a65e-226901f7cbcd
	@AuraEnabled public cls_result result;
	@AuraEnabled public Integer statusCode;	//101
	@AuraEnabled public cls_clientData clientData;
	public class cls_result {
		@AuraEnabled public String canFlag;
		@AuraEnabled public cls_contacted contacted;
		@AuraEnabled public String ppr;
		@AuraEnabled public String cmpRt;	//NA
		@AuraEnabled public String rgdt;	//01/07/2017
		@AuraEnabled public String tradeNam;	//RELIANCE INDUSTRIES LIMITED
		@AuraEnabled public List<String> nba;
		@AuraEnabled public List<String> mbr;
		@AuraEnabled public cls_adadr[] adadr;
		@AuraEnabled public cls_pradr pradr;
		@AuraEnabled public String stjCd;
		@AuraEnabled public String lstupdt;
		@AuraEnabled public String gstin;	//27AAACR5055K1Z7
		@AuraEnabled public String ctjCd;
		@AuraEnabled public String stj;	//State - Maharashtra,Zone - RAIGAD,Division - RAIGAD-NORTH,Charge - URAN_701
		@AuraEnabled public String dty;	//Regular
		@AuraEnabled public String cxdt;	//
		@AuraEnabled public String ctb;	//Public Limited Company
		@AuraEnabled public String sts;	//Active
		@AuraEnabled public String lgnm;	//RELIANCE INDUSTRIES LIMITED
		@AuraEnabled public String ctj;	//State - CBIC,Zone - MUMBAI,Commissionerate - BELAPUR,Division - DIVISION IV,Range - RANGE-IV (Jurisdictional Office)
	}
	
	public class cls_contacted {
		@AuraEnabled public String email;	//ril.mhgst@ril.com
		@AuraEnabled public Decimal mobNum;	//9662506520
		@AuraEnabled public String name;	//Nikhil Rasiklal Meswani
	}
	
	public class cls_adadr {
		@AuraEnabled public String adr;	//IV, MAKER CHAMBERS, NARIMAN POINT, MUMBAI, Mumbai, Maharashtra, 400021
		@AuraEnabled public String em;	//
		@AuraEnabled public String mb;	//
		@AuraEnabled public String ntr;	//Factory / Manufacturing, Retail Business, Input Service Distributor (ISD), Bonded Warehouse, SEZ, Works Contract, Warehouse / Depot, Service Provision, Leasing Business, Office / Sale Office, Recipient of Goods or Services, Wholesale Business, EOU / STP / EHTP
		@AuraEnabled public String addr = '';
		@AuraEnabled public String lastUpdatedDate = '';
	}
	
	public class cls_pradr {
		@AuraEnabled public String adr;	//5, TTC Industrial Area, 5, Reliance Corporate Park, Thane Belapur Road, Ghansoli, Navi Mumbai, Thane, Maharashtra, 400701
		@AuraEnabled public String em;	//
		@AuraEnabled public String mb;	//
		@AuraEnabled public String ntr;	//Factory / Manufacturing, Retail Business, Input Service Distributor (ISD), Bonded Warehouse, SEZ, Works Contract, Warehouse / Depot, Service Provision, Leasing Business, Office / Sale Office, Recipient of Goods or Services, Wholesale Business, EOU / STP / EHTP
		@AuraEnabled public String addr = '';
		@AuraEnabled public String lastUpdatedDate = '';
	}
	public class cls_clientData {
		@AuraEnabled public String caseId;	//123456
	}
    public class GSTNumber{
        @AuraEnabled public Boolean isGSTPresent;
        @AuraEnabled public List<String> gstOptions;
        @AuraEnabled public String msg;
    }
}