public with sharing class LoanSchedulerContoller {

    static String conLabels = 'MESSAGEID,Language,ServiceName,ENTITYID,ServiceVersion';

    public static Map <String,String> constants = Utility.getConstants(conLabels);

    //getting the value of constants
    public static Map <String,String> getConstants() {
        return constants;
    }

    @AuraEnabled
    public static List<Opportunity> getOpportunitiesForLWC(Id recordId) {
        return [SELECT Id, Name, StageName, Loan_Application_Number__c, Sanction_Loan_Amount__c 
                FROM Opportunity WHERE Id = :recordId];
    }
    
    @AuraEnabled
    public static String initiateAPIRequest(Map<String, String> inputMap, List<Opportunity> oppList, String invocationType) {
        //try {
            String resultMessage;
            String returnResp;
            String loanId = inputMap.get('loanId');
            String processName = inputMap.get('processName');
            String returnText;

            if (String.isEmpty(loanId) || String.isEmpty(processName)) {
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

            if (metadata == null) {
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
            wrapper.loanSchedulerInvocationType = invocationType;

            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();

            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                return 'Error: ' + String.join(respWrapper.prerequisiteError, ', ');
            }

            // Fetch Integration Settings
            Integration_Settings__c intSetting = [
                SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c,
                Authorization__c, Cookie__c
                FROM Integration_Settings__c 
                WHERE Name = :processName
                LIMIT 1
            ];
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = '';
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');
                System.debug('resultMessage: '+resultMessage);
                returnResp = resultMessage;
            }else {
                // Prepare API Request
                Map<String, String> integrationRequestMap = new Map<String, String>();
                String bearer = Utility.getAccessToken();
                integrationRequestMap.put('bearer',bearer);
                integrationRequestMap.put('intSettingName', 'Loan Scheduler Create Charges');
                integrationRequestMap.put('requestJSON', respWrapper.payload);
                integrationRequestMap.put('endpoint',intSetting.Endpoint__c);
                //integrationRequestMap.put('auth',intSetting.Authorization__c);
                integrationRequestMap.put('contentType',intSetting.Content_Type__c);
                integrationRequestMap.put('requestMethod',intSetting.Request_Method__c);
                integrationRequestMap.put('cookie',intSetting.Cookie__c);
            
                System.debug('request map initial API   '+integrationRequestMap);
                // Make API Call
                HTTPResponse resp = executeRESTAPIRequest(integrationRequestMap);

                String apiResponse = resp.getBody();
                ContentVersion content = new ContentVersion();
                content.Title = 'LoanScheduler.txt';
                content.PathOnClient = 'LoanScheduler_Response.txt';
                content.VersionData = Blob.valueOf((apiResponse));
                content.IsMajorVersion = true;
                insert content;

                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id LIMIT 1].ContentDocumentId;

               // Create Document_Details__c record
               Document_Details__c checklist = new Document_Details__c();
               checklist.Content_Document_Id__c = cdl.ContentDocumentId;
               checklist.Loan_Application__c = loanid;
               checklist.Name = 'Loan Scheduler Response';
               insert checklist;
                
               cdl.LinkedEntityId =checklist.id ; // Temp link to User so ContentDocument exists
               cdl.ShareType = 'V';
               cdl.Visibility = 'AllUsers';
               insert cdl;
            
                // Deserialize the actual API response
                LoanSchedulerCreateChargesResponseWrapper responseJSON = (LoanSchedulerCreateChargesResponseWrapper) 
                    JSON.deserialize(resp.getBody(), LoanSchedulerCreateChargesResponseWrapper.class);
                    
                // Extract returnText
                if(responseJSON.returnStatus != null && responseJSON.returnStatus.returnText != null){
                    returnText = responseJSON.returnStatus.returnText;
                }else{
                    returnText = 'Some issue in API, empty return status';
                }
                Boolean isSuccessResponse = false;
                if(returnText == 'Success'){
                    isSuccessResponse = true;
                }
            
                // Save API Response in Integration_Details__c
               integrationDetail.Calling_Source__c = wrapper.type;
               integrationDetail.Request_JSON__c = respWrapper.payload;
               //integrationDetail.Response_JSON__c = resp.getBody()/*mockApiResponse*/;
               integrationDetail.Comments__c = invocationType;
               integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
               integrationDetail.Method_Type__c = intSetting.Request_Method__c;
               integrationDetail.EndPoint__c = intSetting.EndPoint__c;
               integrationDetail.Name = processName;
               integrationDetail.Loan_Application__c = loanId;
               integrationDetail.Is_Success_Response__c = isSuccessResponse;
               integrationDetail.Object_Name__c = 'Document_Details__c';
               integrationDetail.Related_Record_Id__c = checklist.Id;
               insert integrationDetail;
            
                system.debug('invocationType::: '+invocationType);
                if (returnText == 'Success' && invocationType != 'RepaymentLWC') {
                    System.debug('Processing Loan Scheduler for LOS Charges');
            
                // **Charge Creation Logic**
                List<Charges_Insurance__c> chargeList = new List<Charges_Insurance__c>();
                List<Charges_Insurance__c> parentChargeList = new List<Charges_Insurance__c>();
                Map<Id, Opportunity> updatedOpportunityMap = new Map<Id, Opportunity>();
                Map<Id, Charges_Insurance__c> parentChargeMap = new Map<Id, Charges_Insurance__c>();
                Map<String, Map<String, Object>> feeTypeToMasterDataMap = new Map<String, Map<String, Object>>();
                String chargeRecordType = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName().get('Charges').getRecordTypeId();
                Map<Id, Charges_Insurance__c> oppIdVsChargeInsuranceMap = new Map<Id, Charges_Insurance__c>();
            
                    // **Query Charges_Insurance_Master__c Records**
                    List<Charges_Insurance_Master__c> chargesInsuranceMasterRecords = [
                        SELECT Id, Charges_Fee_Type__c, Tax__c, Category__c,Max_Percent__c,Min_Percent__c
                        FROM Charges_Insurance_Master__c
                        WHERE Category__c != 'LMS'
                    ];
            
                    // **Map Master Records by Fee Type**
                    for (Charges_Insurance_Master__c master : chargesInsuranceMasterRecords) {
                        Map<String, Object> masterData = new Map<String, Object>();
                        masterData.put('MasterId', master.Id);
                        masterData.put('Tax', master.Tax__c != null ? master.Tax__c : 0); // Default tax to 0 if null
                        masterData.put('Category',master.Category__c != null ? master.Category__c:'');
                        masterData.put('MinPercent',master.Min_Percent__c != null ? master.Min_Percent__c:0);
                        masterData.put('MaxPercent',master.Max_Percent__c != null ? master.Max_Percent__c:0);
                        feeTypeToMasterDataMap.put(master.Charges_Fee_Type__c, masterData);
                    }
            
                    // **Query Existing Total Charges Records**
                    Map<Id, Charges_Insurance__c> existingTotalChargesMap = new Map<Id, Charges_Insurance__c>();
                    List<Charges_Insurance__c> existingTotalChargesRecords = [
                        SELECT Id, Loan_Application__c, Total_Charges__c, Total_Fee_to_be_deducted__c
                        FROM Charges_Insurance__c
                        WHERE Loan_Application__c IN :oppList AND Name = 'Total Charges'
                    ];
            
                    // Store existing Total Charges records in a Map
                    for (Charges_Insurance__c totalCharge : existingTotalChargesRecords) {
                        existingTotalChargesMap.put(totalCharge.Loan_Application__c, totalCharge);
                    }
            
                    // **Create Parent Charge Records (Total Charges) Only If Needed**
                    for (Opportunity opp : oppList) {
                        Charges_Insurance__c parentCharge;
            
                        if (existingTotalChargesMap.containsKey(opp.Id)) {
                            // **Total Charges Record Exists, Update It**
                            parentCharge = existingTotalChargesMap.get(opp.Id);
                        } else {
                            // **Create a New Total Charges Record**
                            parentCharge = new Charges_Insurance__c();
                            parentCharge.Name = 'Total Charges';
                            parentCharge.Loan_Application__c = opp.Id;
                            parentCharge.RecordTypeID = chargeRecordType;
            
                            // **Initialize fields to prevent null issues**
                            parentCharge.Total_Charges__c = 0;
                            parentCharge.Total_Fee_to_be_deducted__c = 0;
            
                            parentChargeList.add(parentCharge);
                        }
            
                        // Store in Map for later processing
                        oppIdVsChargeInsuranceMap.put(opp.Id, parentCharge);
                    }
            
                    // Insert New Total Charges Records if Needed
                    if (!parentChargeList.isEmpty()) {
                        System.debug('Inserting Parent Charge Records: ' + parentChargeList);
                        insert parentChargeList;
            
                        // Update the Map with newly created records
                        for (Charges_Insurance__c newParentCharge : parentChargeList) {
                            oppIdVsChargeInsuranceMap.put(newParentCharge.Loan_Application__c, newParentCharge);
                        }
                    }
            
                    // **Process API Fees & Update Total Charges**
                    Map<Id, Charges_Insurance__c> updatedParentChargeMap = new Map<Id, Charges_Insurance__c>();
            
                    for (Opportunity opp : oppList) {
                        System.debug('Processing LOS Charges for Opportunity: ' + opp.Id);
            
                        if (!oppIdVsChargeInsuranceMap.containsKey(opp.Id)) {
                            System.debug('No Parent Charge Found for Opportunity: ' + opp.Id);
                            continue;
                        }
            
                        Charges_Insurance__c parentCharge = oppIdVsChargeInsuranceMap.get(opp.Id);
            
                        if (responseJSON != null && responseJSON.fees != null) {
                            System.debug('Fees Found: ' + responseJSON.fees);
            
                            for (Fee fee : responseJSON.fees) {
                                Charges_Insurance__c newCharge = new Charges_Insurance__c();
                                newCharge.Name = fee.feeCode;
                                newCharge.Fee_Method__c = fee.feeMethod;
                                newCharge.Charges_Insurance__c = parentCharge.Id;
                                newCharge.Charges_Fee_Type__c = fee.feeCode;
                                newCharge.Loan_Application__c = opp.Id;
                                newCharge.Default_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                newCharge.Requested_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                //newCharge.Category__c = 'LOS';
                                newCharge.RecordTypeID = chargeRecordType;

                                Decimal taxPercentage = 0; // Default to 0%
                                Decimal taxAmount = 0;      // Calculated tax amount
            
                                // **Tag the Master Record ID based on Fee Type**
                                if (feeTypeToMasterDataMap.containsKey(fee.feeCode)) {
                                    Map<String, Object> masterData = feeTypeToMasterDataMap.get(fee.feeCode);
                                    newCharge.Charges_Insurance_Master__c = (Id) masterData.get('MasterId');
                                    newCharge.Tax__c = (Decimal) masterData.get('Tax');
                                    newCharge.Category__c = (String) masterData.get('Category');
                                    newCharge.Min_Percent__c = (Decimal) masterData.get('MinPercent');
                                    newCharge.Max_Percent__c = (Decimal) masterData.get('MaxPercent');
                                    taxPercentage = (Decimal) masterData.get('Tax'); 
                                } else {
                                    newCharge.Tax__c = 0;
                                }
                                // **Calculate Tax Amount (Tax % of Fee Amount)**
                                /*if (taxPercentage > 0 && Utility.truncateTwoZeros(fee.feeAmount) != null) {
                                    taxAmount = (Utility.truncateTwoZeros(fee.feeAmount) * taxPercentage) / 100;
                                }
                                
                                newCharge.Final_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount) + taxAmount;*/
                                if (taxPercentage > 0 && Utility.truncateTwoZeros(fee.feeAmount) != null) {
                                    Decimal rawTaxAmount = (Utility.truncateTwoZeros(fee.feeAmount) * taxPercentage) / 100;
                                    Decimal decimalPart = rawTaxAmount - Math.floor(rawTaxAmount);
                                    taxAmount = decimalPart < 0.5 ? Math.floor(rawTaxAmount) : Math.ceil(rawTaxAmount);
                                }
                                
                                newCharge.Final_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount) + taxAmount;
                                
                                chargeList.add(newCharge);
            
                               // **Update Parent Charge Totals (Including Tax)**
                                Decimal totalChargeAmount = (Utility.truncateTwoZeros(fee.feeAmount) != null ? Utility.truncateTwoZeros(fee.feeAmount) : 0) + taxAmount;

                                parentCharge.Total_Charges__c += totalChargeAmount;
                                parentCharge.Total_Fee_to_be_deducted__c += totalChargeAmount;
                                updatedParentChargeMap.put(parentCharge.Id, parentCharge);
                            }
                        }
                    }
            
                    // **Insert and Update Records**
                    if (!chargeList.isEmpty()) {
                        System.debug('Inserting LOS Charges: ' + chargeList);
                        insert chargeList;
                    }
                
                    if (!updatedParentChargeMap.isEmpty()) {
                        List<Charges_Insurance__c> updatedParentChargeList = new List<Charges_Insurance__c>(updatedParentChargeMap.values());
                        System.debug('Updating Parent Charges: ' + updatedParentChargeList);
                        update updatedParentChargeList;
                    }
                
                    if (!updatedOpportunityMap.isEmpty()) {
                        List<Opportunity> updatedOpportunityList = new List<Opportunity>(updatedOpportunityMap.values());
                        System.debug('Updating Opportunities: ' + updatedOpportunityList);
                        update updatedOpportunityList;
                    }
                }
                else if(returnText == 'Success'){
                    system.debug('responseJSON.schedule: '+responseJSON.schedules);

                    for (Schedule sc : responseJSON.schedules) {
                          if (sc.specifier == 'R' && sc.bpiAmount == 0) {
                            System.debug('329 : '+sc.totalAmount);
                            Opportunity op = new Opportunity(
                                Id = loanId,
                                EMI_Amount_Repayment_Schedule__c = Utility.truncateTwoZeros(sc.totalAmount)
                            );
                            update op;
                            break;
                        }
                    }
                }
            } 

            return returnText;
      /*  } catch (Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'LoanScheduler', '', '') });
            //throw new AuraHandledException('Error: ' + e.getMessage() + e.getStackTraceString());
            throw new AuraHandledException('Salesforce Exception: ' + e.getMessage());
        }*/
    }

    public static HTTPResponse executeRESTAPIRequest(Map<String, String> integrationRequestMap) {
        try {            
            HttpRequest req = new HttpRequest();
            Http http = new Http();
    
            // Extract data from Map
            String endpoint = integrationRequestMap.get('endpoint');//'Callout:Create_Schedule_Simulation_API_LOS'; // Hardcoded Endpoint
            String requestBody = integrationRequestMap.get('requestJSON');
            String bearer = integrationRequestMap.get('bearer');
            String contentType = integrationRequestMap.get('contentType');
            String requestMethod = integrationRequestMap.get('requestMethod');
            String cookie = integrationRequestMap.get('cookie');

            System.debug('request body execute API   '+requestBody);
    
            req.setEndpoint(endpoint);
            req.setMethod(requestMethod);
            // req.setTimeout(30000);
    
            // Set Headers
            req.setHeader('Content-Type', contentType);
            req.setHeader('Authorization', 'Bearer ' + bearer);
            req.setHeader('Cookie', cookie);
            req.setHeader('MESSAGEID', constants.get('MESSAGEID')/*'167036797111'*/);
            req.setHeader('Language', constants.get('Language')/*'ENG'*/);
            req.setHeader('ServiceName', constants.get('ServiceName')/*'createLoanSchedule'*/);
            req.setHeader('ENTITYID', constants.get('ENTITYID')/*'14589954555'*/);
            req.setHeader('ServiceVersion', constants.get('ServiceVersion')/*'1'*/);
            req.setHeader('RequestTime', Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss'));
    
            // Set Body
            req.setBody(requestBody);
            System.debug('Executing API Request: ' + requestBody);
    
            // Send the HTTP request
            HTTPResponse res = http.send(req);
            System.debug('API Response: ' + res.getBody());
    
            return res;
    
        } catch (Exception e) {
            System.debug('API Call Failed: ' + e.getMessage());
            //throw new AuraHandledException('API Call Failed: ' + e.getMessage());
            throw e;
        }
    }
    

    // Wrapper Class for API Response
    public class LoanSchedulerCreateChargesResponseWrapper {
        public String finReference;
        public List<Fee> fees;
        public List<Insurance> insurance;
        public List<Schedule> schedules;
        public List<OverdueCharge> overdueCharges;
        public Decimal advPaymentAmount;
        public String finActiveStatus;
        public Boolean fullyDisb;
        public ReturnStatus returnStatus;
    }

    public class Fee {
        public String feeCategory;
        public String feeCode;
        public Decimal feeAmount;
        public Decimal waiverAmount;
        public String feeMethod;
        public Decimal paidAmount;
        public Integer scheduleTerms;
        public Integer paymentID;
        public Decimal feeBalance;
        public Integer version;
        public List<FinFeeReceipt> finFeeReceipts;
    }

    public class FinFeeReceipt {
        public Integer receiptID;
        public Decimal paidAmount;
    }

    public class Insurance {
        public String policyCode;
        public String insReference;
        public Boolean insuranceReq;
    }

    public class Schedule {
        public DateTime schDate;
        public String event;
        public Decimal pftAmount;
        public String specifier;
        public Decimal totalAmount;
        public Decimal bpiAmount;
    }

    public class OverdueCharge {
        public Date odDate;
        public Decimal odPftPaid;
    }

    public class ReturnStatus {
        public String returnCode;
        public String returnText;
    }
}