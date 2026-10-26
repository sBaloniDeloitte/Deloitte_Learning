public class FDAController {
    @AuraEnabled
    public static String initiateAPIRequest(Map<String,String> inputMap){
        String loanId = inputMap.get('loanId');
        String processName = inputMap.get('processName');
        String registrationNumber = inputMap.get('registrationNumber');
        String areaCode = inputMap.get('areaCode');
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
        wrapper.recordId = loanId; 
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
        wrapper.registrationNo = registrationNumber;
        wrapper.areaCode = areaCode;
        
        intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
        Integration_Details__c integrationDetail = new Integration_Details__c();
        if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
            integrationDetail.Status__c = String.valueof('412');
            integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
            integrationDetail.Name =processName ;
            integrationDetail.Object_Name__c = 'Opportunity';
            resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
            System.debug('resultMessage: '+resultMessage);
            returnResp = resultMessage;
        }
        else{
            String bearer=Utility.getAccessToken();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:AHL_FDA');
            request.setMethod('POST');
            
            // Set headers
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('x-karza-key', 'lkaueM605kzIIuwO');
            // Set the request body
            request.setBody(respWrapper.payload);
            
            // Create the HTTP object
            Http http = new Http();
            
            // Send the HTTP request
            HttpResponse resp = http.send(request);
            String apiResponse = resp.getBody();
            apiResponse = apiResponse.replace('status-code','status_code');
            integrationDetail.Calling_Source__c = wrapper.type; 
            integrationDetail.Request_JSON__c = respWrapper.payload; 
            integrationDetail.Response_JSON__c = apiResponse;
            integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
            integrationDetail.Method_Type__c = wrapper.requestMethod; 
            integrationDetail.EndPoint__c = wrapper.endpoint; 
            integrationDetail.Object_Name__c = 'Opportunity';
            integrationDetail.Name = processName; 
            integrationDetail.Related_Record_Id__c = loanid;
            integrationDetail.Loan_Application__c = loanid;
            insert integrationDetail;
            
            if(resp.getStatusCode() == 200) {
                
                
            }else {
                
            }
            
        }
        return returnResp;
        
    }
    
    @AuraEnabled
    public static Boolean checkIfAlreadyFetch(String loanId, String licenceNumber) {
        Boolean isCalled = false;
        List<Integration_Details__c> idcRecords = [
            SELECT Id, Request_JSON__c FROM Integration_Details__c 
            WHERE Loan_Application__c = :loanId AND Name = 'FDA' AND Status__c = '200'
        ];
        for (Integration_Details__c record : idcRecords) {
            if (String.isNotBlank(record.Request_JSON__c)) {
                try {
                    FDAHandler.RequestWrapper parsedResponse = (FDAHandler.RequestWrapper) System.JSON.deserialize(record.Request_JSON__c, FDAHandler.RequestWrapper.class);
                    
                    if(parsedResponse.licence_no == licenceNumber){
                        isCalled = true;
                        break;
                    }
                } catch (Exception e) { 
                    System.debug('Error parsing JSON: ' + e.getMessage());
                }
            }
        }
        return isCalled;

    }
    
    
    @AuraEnabled
    public static List<cls_result> getFDAData(String loanId, String name) {
        List<cls_result> responseList = new List<cls_result>();

        List<Integration_Details__c> idcRecords = [SELECT Id, Response_JSON__c, Request_JSON__c FROM Integration_Details__c 
                                                    WHERE Loan_Application__c = :loanId AND Name = :name AND Status__c = '200'];

        for (Integration_Details__c record : idcRecords) {
            if (String.isNotBlank(record.Response_JSON__c) && String.isNotBlank(record.Request_JSON__c)) {
                try {
                    ResponseWrap parsedResponse =  (ResponseWrap) System.JSON.deserialize(record.Response_JSON__c, ResponseWrap.class);
                    System.debug('parsedResponse: ' + parsedResponse);
                    if (parsedResponse.status_code == '101') {
                        responseList.add(parsedResponse.result);
                    }

                    System.debug('Updated responseList: ' + responseList);
                } catch (Exception e) {
                    System.debug('Error parsing JSON: ' + e.getMessage());
                }
            }
        }

        return responseList;
    }
    
    public class ResponseWrap{
        public String status_code;	//101
        public String request_id;	//9632bba5-2479-11e8-bf84-4dc40ec92773
        public cls_result result;
        public cls_clientData clientData;
    }
    
    public class cls_result {
        @AuraEnabled public String store_name;	//PRUTHVI CHEMIST. (R)
        @AuraEnabled public String contact_number;	//9624793926
        @AuraEnabled public String license_detail;	//20 - 75202 (04/03/2008 - 04/03/2013 - 03/03/2018)
        @AuraEnabled public String name;	//Shri Giris
        @AuraEnabled public String address;	//plot no. 12,valam nagar society, simada gam,, surat.
    }
    public class cls_clientData {
        public String caseId;	//123456
    }
    @AuraEnabled
public static List<cls_result> getFDADataDummy(String loanId, String name) {

    List<cls_result> responseList = new List<cls_result>();

    cls_result dummy = new cls_result();

    dummy.store_name = 'ABC Medical Store';
    dummy.contact_number = '9876543210';
    dummy.license_detail = '20-75202 (04/03/2008 - 04/03/2013)';
    dummy.name = 'Abhilash Saini';
    dummy.address = 'ABC Market, Mumbai, 400001, Maharashtra';

    responseList.add(dummy);

    return responseList;
}
}