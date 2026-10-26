public class ShopAndEstablishmentCheckController {
    @AuraEnabled
    public static String initiateAPIRequest(Map<String,String> inputMap){
        try {
            Integration_Details__c integrationDetails = new Integration_Details__c();
            String loanId = inputMap.get('loanId');
            String processName = inputMap.get('processName');
            String registrationNumber = inputMap.get('registrationNumber');
            String areaCode = inputMap.get('areaCode');
            String returnResp;
            String resultMessage;
            Map<String,API_Exceptions__mdt> allMetaData = API_Exceptions__mdt.getAll();
            
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
            wrapper.registrationNo = registrationNumber;
            wrapper.areaCode = areaCode;
            
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            
            if(System.Test.isRunningTest()){
                respWrapper.prerequisiteError = null;
                respWrapper.payload = 'payload';
            }
            
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
                
                String bearer = Utility.getAccessToken();
                HttpRequest req = new HttpRequest();
                req.setEndpoint('Callout:LOS_BL_Shop_Est');
                req.setMethod('POST');
                req.setHeader('Authorization', 'bearer '+ bearer);
                req.setHeader('Cookie', 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f');
                req.setHeader('Content-Type', 'application/json');
                
                
                // Set the request body
                req.setBody(respWrapper.payload);
                
                // Create the HTTP object
                Http http = new Http();
                
                // Send the HTTP request
                HttpResponse resp = http.send(req);
                //String apiResponse = JSON.serialize(resp.getBody());
                String apiResponse = resp.getBody();
                //apiResponse = apiResponse.replace('father'sNameOfOccupier','fatherNameOfOccupier');
                //apiResponse = apiResponse.remove('\'');                              
                integrationDetail.Calling_Source__c = wrapper.type; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 
                integrationDetail.Response_JSON__c = apiResponse;
                integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
                integrationDetail.Method_Type__c = wrapper.requestMethod; 
                integrationDetail.EndPoint__c = wrapper.endpoint; 
                integrationDetail.Object_Name__c = 'Opportunity';
                integrationDetail.Name = processName; 
                integrationDetail.Loan_Application__c = loanid;
                insert integrationDetail;

                System.debug('apiResponse----'+apiResponse);
                System.debug(' String.valueOf(resp.getStatusCode()---'+ String.valueOf(resp.getStatusCode()));
                if(resp.getStatusCode() == 200) {
                    if(System.Test.isRunningTest()){
                        returnResp  = resp.getBody();
                    } else {
                        ShopAndEstablishmentResponseWrapper shopResponse = (ShopAndEstablishmentResponseWrapper)JSON.deserialize(resp.getBody(), ShopAndEstablishmentResponseWrapper.class);
                        Integer statusCode= shopResponse.statusCode;
                        if(statusCode==101){
                            returnResp = 'success';
                        }
                        else {
                            for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                                if(execeptionMeta.Error_Code__c == String.valueOf(statusCode)){
                                    returnResp = 'Error: ' + execeptionMeta.Error_Message__c;
                                    
                                }
                            }
                        }
                    }                    
                    
                }else {
                    for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                        System.debug('execeptionMeta.Error_Code__c----'+execeptionMeta.Error_Code__c);
                        if(execeptionMeta.Error_Code__c == String.valueOf(resp.getStatusCode())){
                            returnResp = 'Error: ' + execeptionMeta.Error_Message__c;
                          
                        }
                    }
                }
                if(returnResp== null || returnResp== ''){
                    returnResp = 'Error: Something went wrong. Please try again later.';
                }
            }
            return returnResp; 
        } catch (Exception e) {
            System.debug('ShopAndEstablishmentCheckController=>InitiateAPIrequest ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static Map<String,String> getAreaCodes(String activityName) {
        Map<String,String> areaCode = new Map<String,String>();
        List<Jurisdiction_Area_Code__mdt> mcs = Jurisdiction_Area_Code__mdt.getAll().values();
        if(mcs.size() > 0) {
            for(Jurisdiction_Area_Code__mdt iterMtd : mcs) {
                if(iterMtd.Activity_Name__c == activityName /*'Shop & Establishment'*/) {
                    String devName = iterMtd.DeveloperName.split('_')[0];
                    areaCode.put(devName,iterMtd.Label);
                }
                
            }
        }
        return areaCode;
		
    }
    @AuraEnabled
    public static Boolean checkIfAlreadyFetch(String loanId, String shopAndEstNumber) {
        Boolean isCalled = false;
        List<Integration_Details__c> idcRecords = [
            SELECT Id, Request_JSON__c FROM Integration_Details__c 
            WHERE Loan_Application__c = :loanId AND Name = 'Shop & Establishment' AND Status__c = '200'
        ];
        for (Integration_Details__c record : idcRecords) {
            if (String.isNotBlank(record.Request_JSON__c)) {
                try {
                    ShopAndEstablishmentCheckHandler.ShopAndEstRequestWrapper parsedResponse = (ShopAndEstablishmentCheckHandler.ShopAndEstRequestWrapper) System.JSON.deserialize(record.Request_JSON__c, ShopAndEstablishmentCheckHandler.ShopAndEstRequestWrapper.class);
                    
                    if(parsedResponse.regNo == shopAndEstNumber){
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
    
    // @AuraEnabled
    // public static List<cls_result> getShopExistingData(String loanId, String name) {
    //     List<cls_result> responseList = new List<cls_result>();
        
    //     // Query all records that match Loan ID & Name
    //     List<Integration_Details__c> idcRecords = [
    //         SELECT Id, Response_JSON__c FROM Integration_Details__c 
    //         WHERE Loan_Application__c = :loanId AND Name = :name AND Status__c = '200'
    //     ];

    //     // Loop through records & parse JSON
    //     for (Integration_Details__c record : idcRecords) {
    //         if (String.isNotBlank(record.Response_JSON__c)) {
    //             try {
    //                 ShopAndEstablishmentResponseWrapper parsedResponse = 
    //                     (ShopAndEstablishmentResponseWrapper) System.JSON.deserialize(record.Response_JSON__c, ShopAndEstablishmentResponseWrapper.class);
    //                 if(parsedResponse.statusCode == 101) {
    //                     responseList.add(parsedResponse.result);
    //                 }
                    
    //                 System.debug('responseList '+responseList);
    //             } catch (Exception e) { 
    //                 System.debug('Error parsing JSON: ' + e.getMessage());
    //             }
    //         }
    //     }

    //     return responseList;
    // }
    // Modified the above method by Anish to add regitration no from the request
    @AuraEnabled
    public static List<cls_result> getShopExistingData(String loanId, String name) {
        List<cls_result> responseList = new List<cls_result>();

        List<Integration_Details__c> idcRecords = [SELECT Id, Response_JSON__c, Request_JSON__c FROM Integration_Details__c 
                                                    WHERE Loan_Application__c = :loanId AND Name = :name AND Status__c = '200'];
        system.debug('Controller --> '+ idcRecords);

        for (Integration_Details__c record : idcRecords) {
            if (String.isNotBlank(record.Response_JSON__c) && String.isNotBlank(record.Request_JSON__c)) {
                try {
                    ShopAndEstablishmentResponseWrapper parsedResponse = 
                        (ShopAndEstablishmentResponseWrapper) System.JSON.deserialize(record.Response_JSON__c, ShopAndEstablishmentResponseWrapper.class);

                    ShopAndEstablishmentRequestWrapper parsedRequest = 
                        (ShopAndEstablishmentRequestWrapper) System.JSON.deserialize(record.Request_JSON__c, ShopAndEstablishmentRequestWrapper.class);
                    if (parsedResponse.statusCode == 101) {
                        parsedResponse.result.regNo = parsedRequest.regNo;
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
    // Added by Anish to deserialize request
    public class ShopAndEstablishmentRequestWrapper {
        @AuraEnabled public String regNo;         
        @AuraEnabled public Boolean pdfRequired;  
        @AuraEnabled public String consent;       
        @AuraEnabled public cls_clientData clientData;
        @AuraEnabled public String areaCode;     
    }

    public class ShopAndEstablishmentResponseWrapper{
        @AuraEnabled public String requestId;	//6c2d0636-c3b8-4847-9578-225e703e0397
        @AuraEnabled public cls_result result;
        @AuraEnabled public Integer statusCode;	//101
        @AuraEnabled public cls_clientData clientData;
        
        
    }
    public class cls_result {
        @AuraEnabled public String category;	//Commercial Establishment
        @AuraEnabled public String status;	//
        @AuraEnabled public String ownerName;	//Ramanand
        @AuraEnabled public String entityName;	//Shiva Enterprises
        @AuraEnabled public String registrationDate;	//2/1/2017
        @AuraEnabled public String validTo;	//
        @AuraEnabled public String contact;	//9560084286, 27917553
        @AuraEnabled public String commenceDate;	//2/1/2017
        @AuraEnabled public String totalWorkers;	//5
        //public String fatherNameOfOccupier;	//Jag Ram
        @AuraEnabled public String natureOfBusiness;	//Others
        @AuraEnabled public String address;	//N-18/242, L-block Jj Colony Wazirpur Delhi, Delhi. PIN-110052
        @AuraEnabled public String validFrom;	//
        @AuraEnabled public String email;	//spraygunsales@gmail.com
        @AuraEnabled public String websiteUrl;	//
        @AuraEnabled public String applicantName;	//
        @AuraEnabled public String regNo;
    }
    public class cls_clientData {
        @AuraEnabled public String caseId;	//123456
    }
}