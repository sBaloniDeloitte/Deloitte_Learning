public class upfrontFeeController {
    

    @AuraEnabled
    public static String initiateAPIRequest(Map<String, String> inputMap) {
        String loanId = inputMap.get('loanId');
        String processName = inputMap.get('processName');
        String upfrontFeeObjJson = inputMap.get('upfrontFeeObj');

        Charges_Insurance__c upfrontFeeObj; 
        if(String.isNotBlank(upfrontFeeObjJson)){
            upfrontFeeObj = new Charges_Insurance__c();
            upfrontFeeObj = (Charges_Insurance__c) JSON.deserialize(upfrontFeeObjJson, Charges_Insurance__c.class);
        }

        // 1. HARDCODED LOCAL RESPONSES - Mirroring the exact structure your calculations need
        String returnText = 'Success'; 
        
        // This simulates the raw body text that would normally come from your API callout
        String mockResponseBody = '{' +
            '"returnStatus": {"returnText": "Success"},' +
            '"finReceiptHeaders": [' +
                '{' +
                    '"feeDetails": [' +
                        '{"feeCode": "PROCFEE", "paidAmount": 1000.00, "paidAmountOriginal": 900.00},' +
                        '{"feeCode": "STFRCHG", "paidAmount": 500.00, "paidAmountOriginal": 400.00}' +
                    ']' +
                '}' +
            ']' +
        '}';
        
        // Deserialize the mock payload structurally 
        UpfrontFeeResponseWrapper responseJSON = (UpfrontFeeResponseWrapper)JSON.deserialize(mockResponseBody, UpfrontFeeResponseWrapper.class); 
        
        // 2. QUERY EXISTING LOCAL DATA - Only targets records linked to the working Loan Application
        List<String> chargeFeeTypes = new List<String>{'PROCFEE','STFRCHG'};
        Map<String, Charges_Insurance__c> chargeRecordMap = new Map<String, Charges_Insurance__c>();
        List<Charges_Insurance__c> chargesRecToUpdate = new List<Charges_Insurance__c>();
        
        List<Charges_Insurance__c> chargeRecords = [
            SELECT Id, Charges_Fee_Type__c, Paid_Orginal__c, Paid_Amount_Gst__c, Final_Amount_INR__c, Balance_Fees__c, Adjusted_Login_Fee__c
            FROM Charges_Insurance__c 
            WHERE Charges_Fee_Type__c IN :chargeFeeTypes AND Loan_Application__c = :loanId AND Product__r.Product_Type__c ='Parent'
        ];

        for(Charges_Insurance__c c : chargeRecords) {
            chargeRecordMap.put(c.Charges_Fee_Type__c, c);
        }
        
        // 3. EXECUTE MATHEMATICAL ENGINE - Runs adjustments dynamically against queried records
        if(responseJSON.finReceiptHeaders != null && !responseJSON.finReceiptHeaders.isEmpty()) {
            List<UpfrontFeeResponseWrapper.FeeDetail> feeDetails = responseJSON.finReceiptHeaders[0].feeDetails;
            for(UpfrontFeeResponseWrapper.FeeDetail fee : feeDetails) {
                if(chargeRecordMap.containsKey(fee.feeCode)) {
                    Charges_Insurance__c cRecord = chargeRecordMap.get(fee.feeCode);
                    
                    if(fee.feeCode == 'PROCFEE') {
                        cRecord.Final_Amount_INR__c = fee.paidAmount != null ? (cRecord.Final_Amount_INR__c - Utility.truncateTwoZeros(fee.paidAmount)) : cRecord.Final_Amount_INR__c; 
                        if(cRecord.Balance_Fees__c != null){
                            cRecord.Balance_Fees__c = fee.paidAmountOriginal != null ? (cRecord.Balance_Fees__c - Utility.truncateTwoZeros(fee.paidAmountOriginal)) : cRecord.Balance_Fees__c;
                        } else {
                            cRecord.Balance_Fees__c = fee.paidAmountOriginal != null ? Utility.truncateTwoZeros(fee.paidAmountOriginal) : 0;
                        }
                        cRecord.Adjusted_Login_Fee__c = fee.paidAmountOriginal != null ? (cRecord.Adjusted_Login_Fee__c != null ? (cRecord.Adjusted_Login_Fee__c + Utility.truncateTwoZeros(fee.paidAmountOriginal)) : Utility.truncateTwoZeros(fee.paidAmountOriginal)) : cRecord.Adjusted_Login_Fee__c;
                    
                    } else if(fee.feeCode == 'STFRCHG') {
                        cRecord.Final_Amount_INR__c = fee.paidAmount != null ? (cRecord.Final_Amount_INR__c - Utility.truncateTwoZeros(fee.paidAmount)) : cRecord.Final_Amount_INR__c;
                        cRecord.Balance_Fees__c = fee.paidAmountOriginal != null ? (cRecord.Balance_Fees__c != null ? (cRecord.Balance_Fees__c - Utility.truncateTwoZeros(fee.paidAmountOriginal)) : cRecord.Final_Amount_INR__c) : cRecord.Balance_Fees__c;
                        cRecord.Adjusted_Login_Fee__c = fee.paidAmountOriginal != null ? (cRecord.Adjusted_Login_Fee__c != null ? (cRecord.Adjusted_Login_Fee__c + Utility.truncateTwoZeros(fee.paidAmountOriginal)) : Utility.truncateTwoZeros(fee.paidAmountOriginal)) : cRecord.Adjusted_Login_Fee__c;
                    }
                    chargesRecToUpdate.add(cRecord);
                }
            }
        }
        
        // Update the adjusted record details locally
        if (!chargesRecToUpdate.isEmpty()) {
            update chargesRecToUpdate; 
        }
        
        // 4. INSERT FUNCTIONAL UPFRONT RECORD
        if(String.isNotBlank(upfrontFeeObjJson) && returnText == 'Success'){
            Charges_Insurance__c upfrontRecObj = new Charges_Insurance__c(); 
            upfrontRecObj.Sub_Receipt_Mode__c = upfrontFeeObj.Sub_Receipt_Mode__c;
            upfrontRecObj.Remarks__c = upfrontFeeObj.Remarks__c;
            upfrontRecObj.Receipt_No__c = upfrontFeeObj.Receipt_No__c;
            upfrontRecObj.Transaction_Reference__c = upfrontFeeObj.Transaction_Reference__c;
            upfrontRecObj.Final_Amount_INR__c = upfrontFeeObj.Final_Amount_INR__c;
            upfrontRecObj.Processing_Fee_Inc_Tax_Upfront__c = upfrontFeeObj.Processing_Fee_Inc_Tax_Upfront__c;
            upfrontRecObj.Stamp_Fee_Inc_Tax_Upfront__c = upfrontFeeObj.Stamp_Fee_Inc_Tax_Upfront__c;
            upfrontRecObj.Loan_Application__c = loanId;
            upfrontRecObj.Charges_Fee_Type__c = 'Upfront Fee';
            upfrontRecObj.Name = 'Upfront Fee';
            upfrontRecObj.Product__c = upfrontFeeObj.Product__c;
            insert upfrontRecObj;
        }
        
        return returnText;  
    }

    /*@AuraEnabled
    public static String initiateAPIRequest(Map<String, String> inputMap) {
        String loanId = inputMap.get('loanId');
        String processName = inputMap.get('processName');
        String upfrontFeeObjJson = inputMap.get('upfrontFeeObj');
        Charges_Insurance__c upfrontFeeObj; //= new Charges_Insurance__c();
        if(String.isNotBlank(upfrontFeeObjJson)){
            upfrontFeeObj = new Charges_Insurance__c();
            upfrontFeeObj = (Charges_Insurance__c) JSON.deserialize(upfrontFeeObjJson, Charges_Insurance__c.class);
        }
    
        string returnText;
        Integer statusCode;
        string responseBody;
        UpfrontFeeResponseWrapper responseJSON ;
        // Fetch Metadata
        Integration_Master__mdt metadata = [
            SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, Client_Id__c, 
                Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, Refresh_Allowed__c, Activity_Name__c
            FROM Integration_Master__mdt 
            WHERE Activity_Name__c = :processName 
            LIMIT 1
        ];

        if(metadata == null) {
            throw new AuraHandledException('Error: No metadata found for the given process.');
        }
        
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.recordId = loanId;
        wrapper.loanApplicationId = loanId;  
        wrapper.type = processName;
        wrapper.endpoint = metadata.Endpoint__c;
        wrapper.requestMethod = metadata.Request_Method__c;
        wrapper.clientId = metadata.Client_Id__c;
        wrapper.clientSecret = metadata.Client_Secret__c;
        wrapper.allowedRetry = metadata.Allowed_Retry__c;
        wrapper.gestationPeriod = metadata.Gestation_Period__c;
        wrapper.activityname = metadata.Activity_Name__c;
        wrapper.refreshallowed = metadata.Refresh_Allowed__c;
        wrapper.handlername = metadata.Handler_Class__c;
        wrapper.upfrontFeeObj = upfrontFeeObj;

        intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
        System.debug('respWrapper='+respWrapper);
        Integration_Details__c integrationDetail = new Integration_Details__c();
        if(respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
            return 'Error: ' + String.join(respWrapper.prerequisiteError, ', ');
        }
        // Fetch Integration Settings
        Integration_Settings__c intSetting = [
            SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c 
            FROM Integration_Settings__c 
            WHERE Name = :processName 
            LIMIT 1
        ];
            
        String base64StringFromContentVersion = '';
        if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
            integrationDetail.Status__c = String.valueof('412');
            integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
            integrationDetail.Name = processName;
            integrationDetail.Object_Name__c = '';
        }
        else {
            string reqStr = respWrapper.payload.replaceAll('"loanCurrency"','"currency"');
            Map<String, String> integrationRequestMap = new Map<String, String>();
            integrationRequestMap.put('intSettingName', processName);
            integrationRequestMap.put('requestJSON', respWrapper.payload);
            integrationRequestMap.put('endpoint',intSetting.Endpoint__c);
            integrationRequestMap.put('contentType',intSetting.Content_Type__c);
            integrationRequestMap.put('requestMethod',intSetting.Request_Method__c);

            HTTPResponse resp = executeRESTAPIRequest(integrationRequestMap);
            System.debug('line 68-->>'+resp);
            System.debug('Response Status => ' + resp.getStatus());
            System.debug('Response Body => ' + resp.getBody());
            returnText = resp.getBody();
            if(resp != null && resp.getStatusCode() ==200){
                responseJSON = (UpfrontFeeResponseWrapper)JSON.deserialize(resp.getBody(), UpfrontFeeResponseWrapper.class); //Arman 09-12 : Code check >> Where is this being used? 
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                if (responseMap.containsKey('returnStatus')) { //Arman : this should not have happened and must have been catered in the response wrapper > But I'll not correct it. Deadline issues
                    Map<String, Object> returnStatusMap = (Map<String, Object>) responseMap.get('returnStatus');
                    if (returnStatusMap != null && returnStatusMap.containsKey('returnText')) {
                        returnText = String.valueOf(returnStatusMap.get('returnText'));
                    } else {
                        returnText = resp.getBody();
                    }
                }
                
                List<String> chargeFeeTypes = new List<String>{'PROCFEE','STFRCHG'};
                Map<String, Charges_Insurance__c> chargeRecordMap = new Map<String, Charges_Insurance__c>();
                List<Charges_Insurance__c> chargesRecToUpdate = new List<Charges_Insurance__c>();
                List<Charges_Insurance__c> chargeRecords = [SELECT Id, Charges_Fee_Type__c,Paid_Orginal__c,Paid_Amount_Gst__c,Final_Amount_INR__c,Balance_Fees__c,Adjusted_Login_Fee__c
                FROM Charges_Insurance__c WHERE Charges_Fee_Type__c IN :chargeFeeTypes AND Loan_Application__c = :loanId AND Product__r.Product_Type__c ='Parent'];

                for(Charges_Insurance__c c : chargeRecords) {
                    chargeRecordMap.put(c.Charges_Fee_Type__c, c);
                }
                if(responseJSON.finReceiptHeaders != null && !responseJSON.finReceiptHeaders.isEmpty()) {
                    List<UpfrontFeeResponseWrapper.FeeDetail> feeDetails = responseJSON.finReceiptHeaders[0].feeDetails;
                    for(UpfrontFeeResponseWrapper.FeeDetail fee : feeDetails) {
                        if(chargeRecordMap.containsKey(fee.feeCode)) {
                            Charges_Insurance__c cRecord = chargeRecordMap.get(fee.feeCode);
                            if(fee.feeCode == 'PROCFEE') {
                                //cRecord.Paid_Orginal__c = fee.paidAmountOriginal != null ? Utility.truncateTwoZeros(fee.paidAmountOriginal) : 0;
                                //cRecord.Paid_Amount_Gst__c = fee.paidAmountGST != null ? Utility.truncateTwoZeros(fee.paidAmountGST) : 0;
                                cRecord.Final_Amount_INR__c = fee.paidAmount!=null ? (cRecord.Final_Amount_INR__c - Utility.truncateTwoZeros(fee.paidAmount)) : cRecord.Final_Amount_INR__c; //Armani : adding this to adjust the final amount in upfront 
                                if(cRecord.Balance_Fees__c != null){
                                cRecord.Balance_Fees__c = fee.paidAmountOriginal!=null ? (cRecord.Balance_Fees__c - Utility.truncateTwoZeros(fee.paidAmountOriginal)) : cRecord.Balance_Fees__c;

                                }
                                else{
                                    cRecord.Balance_Fees__c = fee.paidAmountOriginal!=null ? Utility.truncateTwoZeros(fee.paidAmountOriginal) : 0;
                                }
                                cRecord.Adjusted_Login_Fee__c = fee.paidAmountOriginal!=null ?  (cRecord.Adjusted_Login_Fee__c!=null ? (cRecord.Adjusted_Login_Fee__c + Utility.truncateTwoZeros(fee.paidAmountOriginal)) : Utility.truncateTwoZeros(fee.paidAmountOriginal)) : cRecord.Adjusted_Login_Fee__c;
                            } else if(fee.feeCode == 'STFRCHG') {
                                //cRecord.Paid_Orginal__c = fee.paidAmountOriginal != null ? Utility.truncateTwoZeros(fee.paidAmountOriginal) : 0;
                                //cRecord.Paid_Amount_Gst__c = fee.paidAmountGST != null ? Utility.truncateTwoZeros(fee.paidAmountGST) : 0;
                                cRecord.Final_Amount_INR__c = fee.paidAmount!=null ? (cRecord.Final_Amount_INR__c - Utility.truncateTwoZeros(fee.paidAmount)) : cRecord.Final_Amount_INR__c;
                                cRecord.Balance_Fees__c = fee.paidAmountOriginal!=null ? (cRecord.Balance_Fees__c!=null ? (cRecord.Balance_Fees__c - Utility.truncateTwoZeros(fee.paidAmountOriginal)) : cRecord.Final_Amount_INR__c) : cRecord.Balance_Fees__c;
                                cRecord.Adjusted_Login_Fee__c = fee.paidAmountOriginal!=null ?  (cRecord.Adjusted_Login_Fee__c!=null ? (cRecord.Adjusted_Login_Fee__c + Utility.truncateTwoZeros(fee.paidAmountOriginal)) : Utility.truncateTwoZeros(fee.paidAmountOriginal)) : cRecord.Adjusted_Login_Fee__c;
                            }
                            chargesRecToUpdate.add(cRecord);
                        }
                    }
                }
                update chargesRecToUpdate; //chargeRecords; //Arman : 9th Dec : > you inserted these records in a map > how are these getting updated? Added the records in a list and updated
                //Arman added 24th Dex 2025:
                if(String.isNotBlank(upfrontFeeObjJson) && returnText == 'Success'){
                    Charges_Insurance__c upfrontRecObj = new Charges_Insurance__c(); //will create this to hold the upfront solutioning
                    upfrontRecObj.Sub_Receipt_Mode__c = upfrontFeeObj.Sub_Receipt_Mode__c;
                    upfrontRecObj.Remarks__c = upfrontFeeObj.Remarks__c;
                    upfrontRecObj.Receipt_No__c = upfrontFeeObj.Receipt_No__c;
                    upfrontRecObj.Transaction_Reference__c = upfrontFeeObj.Transaction_Reference__c;
                    upfrontRecObj.Final_Amount_INR__c = upfrontFeeObj.Final_Amount_INR__c;
                    upfrontRecObj.Processing_Fee_Inc_Tax_Upfront__c = upfrontFeeObj.Processing_Fee_Inc_Tax_Upfront__c;
                    upfrontRecObj.Stamp_Fee_Inc_Tax_Upfront__c = upfrontFeeObj.Stamp_Fee_Inc_Tax_Upfront__c;
                    upfrontRecObj.Loan_Application__c = loanId;
                    upfrontRecObj.Charges_Fee_Type__c = 'Upfront Fee';
                    upfrontRecObj.Name = 'Upfront Fee';
                    upfrontRecObj.Product__c = upfrontFeeObj.Product__c;
                    insert upfrontRecObj;
                }
            }
            //Arman : insertt int det
            integrationDetail.Calling_Source__c = wrapper.type;
            integrationDetail.Request_JSON__c = respWrapper.payload;
            integrationDetail.Is_Success_Response__c = returnText == 'Success' ? true : false; //Armani :creating a specific Int Detail record to stop double API hit.
            integrationDetail.Response_JSON__c = resp.getBody();
            integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
            integrationDetail.Method_Type__c = intSetting.Request_Method__c;
            integrationDetail.EndPoint__c = intSetting.EndPoint__c;
            integrationDetail.Object_Name__c = 'Opportunity';
            integrationDetail.Name = processName;
            integrationDetail.Loan_Application__c = loanId;
            insert integrationDetail;
        }
        return String.isNotBlank(returnText) ? returnText : 'Some issue in API, empty returnText' ;  
    }*/

    @AuraEnabled
    public static void updateLoginFeeStatus(Id loginFeeId, String status) {
        System.debug('status------'+status);
    Charges_Insurance__c fee = new Charges_Insurance__c(Id = loginFeeId, API_Status__c = status);
    update fee;
    String loanId = [Select id,Loan_Application__c from Charges_Insurance__c where id=:loginFeeId].Loan_Application__c;
    List<Document_Details__c> docDet = [Select id,Login_Fee_Status__c,Loan_Application__c from Document_Details__c where Name='Login Fee Receipt' and Loan_Application__c=:loanId];
        if(docDet.size()>0){
            docDet[0].Login_Fee_Status__c=status;
        }
        update docDet;

    }
    @AuraEnabled(cacheable=true)
    public static String getLoginFeeStatus(Id loanId) {
        Charges_Insurance__c fee = [
            SELECT Id, API_Status__c,Charges_Fee_Type__c
            FROM Charges_Insurance__c 
            WHERE Loan_Application__c = :loanId and Charges_Fee_Type__c = 'Login Fee'
            LIMIT 1
        ];
    
        return fee.API_Status__c;
    }

    @AuraEnabled
    public static List<Charges_Insurance__c> getUpfrontFeeRecords(String loanApplicationId){
        try {
            return [SELECT ID,Sub_Receipt_Mode__c,Remarks__c,Receipt_No__c,Transaction_Reference__c,Final_Amount_INR__c,Processing_Fee_Inc_Tax_Upfront__c,Stamp_Fee_Inc_Tax_Upfront__c,Loan_Application__c,Charges_Fee_Type__c
             from Charges_Insurance__c WHERE Charges_Fee_Type__c = 'Upfront Fee' AND Loan_Application__c =:loanApplicationId];
            
        } catch (Exception e) {
            throw new AuraHandledException('ERROR: '+e.getStackTraceString());
        }
    }
    
        
        
       private static HTTPResponse executeRESTAPIRequest(Map<String, String> integrationRequestMap) {
        try {
            //String requestBody = integrationRequestMap.get('requestJSON');
           HttpRequest req = new HttpRequest();
            Http http = new Http();

            // Extract data from Map
            String endpoint = integrationRequestMap.get('endpoint');
            String requestBody = integrationRequestMap.get('requestJSON');
            String contentType = integrationRequestMap.get('contentType');
            String requestMethod = integrationRequestMap.get('requestMethod');
			String bearer = Utility.getAccessToken();
 
 
            req.setEndpoint(endpoint);
            req.setMethod(requestMethod);

            // Set Headers
            req.setHeader('Content-Type', contentType);
            req.setHeader('Authorization', 'Bearer '+bearer);
            req.setHeader('MESSAGEID', '167036797111');
            req.setHeader('ENTITYID', '14589954555');
            req.setHeader('Cookie', 'TS019fc7a5=0135ac00a26d29fc2e9a67624ac24d82245f89301556bdb58a890de16f3edc47eb360fc9b4a3807d1e226e64a4a41221d34a32ee18');
            req.setHeader('ServiceVersion', '1');
            req.setHeader('Language', 'ENG');
            req.setHeader('ServiceName', 'feePayment');
            req.setHeader('RequestTime', '2025-08-22T15:25:00');
            req.setHeader('ServiceVersion', '1');
            //req.setTimeout(120000);
            // Set Body
            req.setBody(requestBody);
            system.debug('line 122--->>'+req);
            System.debug('Executing API Request: ' + requestBody);

            // Send the HTTP request
            HTTPResponse res = http.send(req);
            System.debug('API Response: ' + res);
            
           /* HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint('callout:upfrontFeePayment');
            httpReq.setMethod('POST');
            httpReq.setHeader('Content-Type', 'application/json');
            httpReq.setBody(requestBody);
            httpReq.setHeader('Authorization', '79Nwl3B+WTrUnQ4rbcxqawY2/W6p1CtpaA36Clv0LpPGO2+q');
            httpReq.setHeader('MESSAGEID', '167036797111');
            httpReq.setHeader('ENTITYID', '14589954555');
            httpReq.setHeader('Cookie', 'TS019fc7a5=0135ac00a26d29fc2e9a67624ac24d82245f89301556bdb58a890de16f3edc47eb360fc9b4a3807d1e226e64a4a41221d34a32ee18');
            httpReq.setHeader('ServiceVersion', '1');
            httpReq.setHeader('Language', 'ENG');
            httpReq.setHeader('ServiceName', 'feePayment');
            httpReq.setHeader('RequestTime', '2025-08-22T15:25:00');
            
            // Send HTTP Callout
            HttpResponse res = http.send(httpReq);
            system.debug('line 148-->>'+res);*/


            
            return res;
        } 
        catch (Exception e) {
            System.debug('API Call Failed: ' + e.getMessage());
            //throw new AuraHandledException('API Call Failed: ' + e.getMessage());
            throw e;
        }
    }
}