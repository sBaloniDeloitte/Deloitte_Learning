public class SanctionLetterController {
    static String conLabels = 'Term_Loan,Flexi_Funds,Over_Draft,Variant';

    public static Map <String,String> constants = Utility.getConstants(conLabels);

    //getting the value of constants
    public static Map <String,String> getConstants() {
        return constants;
    }

    @AuraEnabled
    public static String initiateAPIRequest(Map<String, String> inputMap) {
        try {
            system.debug('inputMap::: ' + inputMap);
            String loanId = inputMap.get('loanId');
            String processName = inputMap.get('processName');
            Boolean isRegenerate = inputMap.containsKey('isRegenerate') && String.valueOf(inputMap.get('isRegenerate')).toLowerCase() == 'true';

            if(String.isEmpty(loanId) || String.isEmpty(processName)) {
                throw new AuraHandledException('Error: Missing required parameters.');
            }

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

            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            system.debug('respWrapper='+respWrapper);

            Integration_Details__c integrationDetail = new Integration_Details__c();
            if(respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                return 'Error: ' + String.join(respWrapper.prerequisiteError, ', ');
            }

            SanctionLetterResponseWrapper responseJSON;
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
                Map<String, String> integrationRequestMap = new Map<String, String>();
                integrationRequestMap.put('intSettingName', processName);
                integrationRequestMap.put('requestJSON', respWrapper.payload);
                integrationRequestMap.put('endpoint',intSetting.Endpoint__c);
                integrationRequestMap.put('contentType',intSetting.Content_Type__c);
                integrationRequestMap.put('requestMethod',intSetting.Request_Method__c);

                HTTPResponse resp = executeRESTAPIRequest(integrationRequestMap);

                System.debug('resp: '+resp);
                if(resp != null && resp.getStatusCode() == 200){
                    System.debug('resp.getBody(): '+resp.getBody());

                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());

                    try {
                        if(responseMap.containsKey('response') && responseMap.get('response') instanceof Map<String, Object>) {
                            // Deserialize only when structure is valid
                            responseJSON = (SanctionLetterResponseWrapper) JSON.deserialize(resp.getBody(), SanctionLetterResponseWrapper.class);
                        } 
                        else {
                            // If response is a string or empty, build wrapper manually
                            responseJSON = new SanctionLetterResponseWrapper();
                            responseJSON.message = (String) responseMap.get('message');
                    
                            SanctionLetterResponseWrapper.Response errorResp = new SanctionLetterResponseWrapper.Response();
                            errorResp.status = false;
                            errorResp.exceptionMessage = responseJSON.message;
                            responseJSON.response = errorResp;
                        }
                    } 
                    catch (Exception innerEx) {
                        responseJSON = new SanctionLetterResponseWrapper();
                        responseJSON.message = 'Error parsing response: ' + innerEx.getMessage();
                    
                        SanctionLetterResponseWrapper.Response errorResp = new SanctionLetterResponseWrapper.Response();
                        errorResp.status = false;
                        errorResp.exceptionMessage = responseJSON.message;
                        responseJSON.response = errorResp;
                    }

                    // Check if the sanction letter document already exists
                    List<Document_Details__c> existingDocs = [
                        SELECT Id, Content_Document_Id__c 
                        FROM Document_Details__c 
                        WHERE Loan_Application__c = :loanId 
                        AND Name = 'Sanction Letter' AND Active__c = true Order by CreatedDate DESC
                        LIMIT 1
                    ];

                    if(!existingDocs.isEmpty()) {
                        if(isRegenerate) {
                            //Mark old SL as inactive
                            existingDocs[0].Active__c = false;
                            update existingDocs;
                        } 
                        else {
                            // Fetch the existing ContentVersion
                            ContentVersion existingContentVersion = [
                                SELECT VersionData 
                                FROM ContentVersion 
                                WHERE ContentDocumentId = :existingDocs[0].Content_Document_Id__c 
                                LIMIT 1
                            ];

                            String existingBase64String = EncodingUtil.base64Encode(existingContentVersion.VersionData);
                            List<Integration_Details__c> inDetails = [SELECT Id, Request_JSON__c FROM Integration_Details__c WHERE Loan_Application__c = :loanId AND Name = 'Sanction Letter Generation' ORDER BY CreatedDate DESC LIMIT 1];
                            if(inDetails.size()>0){
                                generateSanctionLetterEvent(loanId, inDetails[0].Request_JSON__c); 
                            }
                            return existingBase64String;
                        }
                    }
                    
                    // **Deserialize Response**
                    //responseJSON = (SanctionLetterResponseWrapper) JSON.deserialize(resp.getBody(), SanctionLetterResponseWrapper.class);
                    String base64PDF = responseJSON.response != null ? responseJSON.response.base64StringForPDF : null;

                    if(String.isNotBlank(base64PDF)) {
                        Blob fileBlob = EncodingUtil.base64Decode(base64PDF.trim());
                    
                        ContentVersion contentVersion = new ContentVersion();
                        contentVersion.Title = 'SanctionLetter';
                        contentVersion.PathOnClient = 'SanctionLetter.pdf';
                        contentVersion.VersionData = fileBlob;
                        contentVersion.FirstPublishLocationId = loanId;
                        insert contentVersion;

                        // Retrieve ContentDocumentId
                        ContentDocument contentDocument = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :contentVersion.Id LIMIT 1];

                        List<Document_Master__c> docMaster = [SELECT Id, Name, Requirement_Level__c 
                                                                    FROM Document_Master__c 
                                                                    WHERE Requirement_At__c = 'Loan Application' 
                                                                    AND Name = 'Sanction Letter' LIMIT 1];

                        Document_Details__c doc = new Document_Details__c();
                        doc.Status__c = 'Uploaded';
                        doc.Content_Document_Id__c = contentDocument.Id;
                        doc.Name = docMaster[0].Name;
                        doc.Loan_Application__c = loanId;
                        doc.Active__c = true;
                        insert doc;

                        // Fetch the inserted ContentVersion to get the base64 string
                        ContentVersion insertedContentVersion = [SELECT VersionData FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
                        base64StringFromContentVersion = EncodingUtil.base64Encode(insertedContentVersion.VersionData);   
                        
                        System.debug('PDF successfully inserted as ContentVersion.');

                        generateSanctionLetterEvent(loanId, respWrapper.payload);
                    }
                }
                
                integrationDetail.Calling_Source__c = wrapper.type;
                integrationDetail.Request_JSON__c = respWrapper.payload;
                //integrationDetail.Response_JSON__c = resp;
                integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                integrationDetail.Method_Type__c = intSetting.Request_Method__c;
                integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                integrationDetail.Object_Name__c = 'Opportunity';
                integrationDetail.Name = processName;
                integrationDetail.Loan_Application__c = loanId;
                //integrationDetail.Is_Success_Response__c = isSuccessResponse;
                insert integrationDetail;
            }

            //return base64StringFromContentVersion;
            return JSON.serialize(responseJSON);
        } 
        catch (Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'SanctionLetter', '', '') });
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    private static HTTPResponse executeRESTAPIRequest(Map<String, String> integrationRequestMap) {
        try {
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
            req.setHeader('Authorization', 'Bearer ' + bearer);
            req.setTimeout(120000);
            // Set Body
            req.setBody(requestBody);
            System.debug('Executing API Request: ' + requestBody);

            // Send the HTTP request
            HTTPResponse res = http.send(req);
            System.debug('API Response: ' + res);

            return res;
        } 
        catch (Exception e) {
            System.debug('API Call Failed: ' + e.getMessage());
            //throw new AuraHandledException('API Call Failed: ' + e.getMessage());
            throw e;
        }
    }

    @AuraEnabled
    public static Map<String, Object> getExistingSanctionLetter(String loanId) {
        try {

            Opportunity loanApp = [SELECT Is_Pricing_Approval_Required__c, Pricing_Approval_Status__c, StageName
                                    FROM Opportunity 
                                    WHERE Id = :loanId 
                                    LIMIT 1];
            Boolean shouldHitAPI = false;
            String existingBase64String = null; 
            String message = null;                    

            // Scenario 1: Pricing approval is required
            if (loanApp.Is_Pricing_Approval_Required__c) {
                // Check for pending approval process
                List<ProcessInstanceWorkitem> pendingApprovals = [
                    SELECT ActorId, Actor.Name, ProcessInstance.TargetObjectId 
                    FROM ProcessInstanceWorkitem 
                    WHERE ProcessInstance.TargetObjectId = :loanId 
                    AND ProcessInstance.Status = 'Pending' 
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];

                // If no pending approvals and status is Approved, we should hit the API
                if (pendingApprovals.isEmpty() && loanApp.Pricing_Approval_Status__c == 'Approved') {
                    List<Document_Details__c> existingDocs = [
                    SELECT Id, Content_Document_Id__c 
                    FROM Document_Details__c 
                    WHERE Loan_Application__c = :loanId 
                    AND Name = 'Sanction Letter' AND Active__c = true Order by CreatedDate DESC
                    LIMIT 1
                ];

                if (!existingDocs.isEmpty() && loanApp.StageName != 'Disbursement') {
                    delete existingDocs;
                    shouldHitAPI = true;
                }else if(existingDocs.isEmpty() && loanApp.StageName != 'Disbursement'){
                    shouldHitAPI = true;
                }else{
                    shouldHitAPI = false;
                    ContentVersion existingContentVersion = [
                        SELECT VersionData 
                        FROM ContentVersion 
                        WHERE ContentDocumentId = :existingDocs[0].Content_Document_Id__c 
                        LIMIT 1
                    ];
                    existingBase64String = EncodingUtil.base64Encode(existingContentVersion.VersionData);
                }
                }else{
                    shouldHitAPI = false;// If there are pending approvals or status is not Approved, we'll return without hitting API
                    // Set message when approval is pending or not yet approved
                    message = 'Pricing approval is still in progress. Sanction letter can be generated only once it is approved.';
                }
                
            }// Scenario 2: Pricing approval is not required
            else {
                // Check if sanction letter document already exists
                List<Document_Details__c> existingDocs = [
                    SELECT Id, Content_Document_Id__c 
                    FROM Document_Details__c 
                    WHERE Loan_Application__c = :loanId 
                    AND Name = 'Sanction Letter' AND Active__c = true Order by CreatedDate DESC
                    LIMIT 1
                ];

                if (!existingDocs.isEmpty()) {
                    shouldHitAPI = true;
                    // Fetch the existing ContentVersion
                    ContentVersion existingContentVersion = [
                        SELECT VersionData 
                        FROM ContentVersion 
                        WHERE ContentDocumentId = :existingDocs[0].Content_Document_Id__c 
                        LIMIT 1
                    ];
                    existingBase64String = EncodingUtil.base64Encode(existingContentVersion.VersionData);
                } else {
                    // If no document exists, we should hit the API
                    shouldHitAPI = true;
                }
            }
            // Return a map containing both the decision to hit API and any existing document
            return new Map<String, Object>{
                'shouldHitAPI' => shouldHitAPI,
                'existingDocument' => existingBase64String,
                'message' => message // Will be null unless the specific condition is met
            };

        } catch (Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'SanctionLetter', '', '') });
            throw new AuraHandledException('Salesforce Exception: ' + e.getMessage());
            //throw new AuraHandledException('There is a Salesforce Exception, please contact your Salesforce Administrator.');
        }
    }
	
    public static void generateSanctionLetterEvent( String loanId, String payload){
        // List<Opportunity> opportunityList = [SELECT Id, Name, Sanction_Loan_Amount__c, Final_Amount__c, Tenor_Months__c,Repayment_Facility__c, Final_Rate_Of_Interest__c, Sanction_EMI__c, Product__c, Loan_Purpose__c  FROM Opportunity WHERE Id = :loanId];
        // Product2 mainProduct =[SELECT Id, Description from Product2 WHERE RecordType.Name = 'Product' AND Name = :opportunityList[0].Product__c AND Loan_Application__c = :loanId LIMIT 1];
        // Product2 subProduct = [SELECT Id from Product2 WHERE RecordType.Name = 'Sub Product' AND Product__c =:mainProduct.Id AND Loan_Application__c = :loanId LIMIT 1];
        // List<Product2> productRecords = [
        //     SELECT Id, Name, RecordType.Name, PLR_Code__c, 
        //     PLR_Value__c, BPI_Interest_Days_Basis__c, Interest_Days_Basis__c 
        //     FROM Product2 
        //     WHERE Loan_Application__c = :loanId
        //     AND RecordType.Name = :constants.get('Variant') AND Product__c = :subProduct.Id
        //     LIMIT 1
        // ];
        // String loanProduct;
        // String plrCode;
        // for (Product2 prod : productRecords) {
        //     if (prod.Name == constants.get('Term_Loan')) {
        //         loanProduct = 'BL';
        //     } else if (prod.Name == constants.get('Over_Draft') || prod.Name == constants.get('Flexi_Funds')) {
        //         loanProduct = 'BD';
        //     }            
        // }
        String messageWrapper = payload;
        if(messageWrapper != null && messageWrapper!= ''){
            Integration_Details__c integration = new Integration_Details__c();
            integration.name = 'Communication Event';
            integration.Loan_Application__c = loanId;
            integration.Endpoint__c = 'SLSF'; 
            integration.Communication_Status__c = 'Published';
            integration.Request_JSON__c = messageWrapper;
            insert integration;

            //String commProduct = loanProduct != null ? (loanProduct == 'BL' ? 'Business Loan': (loanProduct == 'BD' ? 'Business Loan Flexi Funds': '')): '';
            Communication__e event = new Communication__e(
                Message__c = messageWrapper,
                Record_Id__c = integration.Id,
                Type__c = 'SLSF',
                product__c = 'Affordable Home Loan'
            );
        
            Database.SaveResult result = EventBus.publish(event);
            if (result.isSuccess()) {
                System.debug('Platform Event published successfully.'+result);
            } else {
                // Log errors if publishing failed
                for (Database.Error error : result.getErrors()) {
                    System.debug('Error publishing event: ' + error.getMessage());
                }
            }

            Integration_Details__c integration2 = new Integration_Details__c();
            integration2.name = 'Communication Event';
            integration2.Loan_Application__c = loanId;
            integration2.Endpoint__c = 'SLSF_SALES'; 
            integration2.Communication_Status__c = 'Published';
            integration2.Request_JSON__c = messageWrapper;
            insert integration2;

            Communication__e event2 = new Communication__e(
                Message__c = messageWrapper,
                Record_Id__c = integration2.Id,
                Type__c = 'SLSF_SALES',
                product__c = 'Affordable Home Loan'
            );
        
            Database.SaveResult result2 = EventBus.publish(event2);
            if (result2.isSuccess()) {
                System.debug('Platform Event published successfully.'+result2);
            } else {
                // Log errors if publishing failed
                for (Database.Error error : result2.getErrors()) {
                    System.debug('Error publishing event: ' + error.getMessage());
                }
            }
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getCurrentUserDetails(){
        List<string> result = new List<string>();
        result.add([Select Name From Profile Where Id =: UserInfo.getProfileId()].Name);
        result.add(UserInfo.getName());
        return result;
    }
}