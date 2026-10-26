public with sharing class LoanExposureController {
    
    static string conLabels = 'Banking_Exposure_API';
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
        //
    @AuraEnabled
    public static String callAPIButtonClicked(string recordId, string processObject){
        
      	LoanExposureResponseServiceWrapper response = new LoanExposureResponseServiceWrapper();
        String returnStr;
        
        response = initiateAPIRequest(recordId, processObject);
        returnStr = JSON.serialize(response);
        
		System.debug('✅ returnStr Response: ' + returnStr);

    	return returnStr;
    }
    
    @AuraEnabled
    public static String getExposureFromIntegrationDetails(string recordId, string processObject){
        
        string returnStr = 'notfound';
        List<Integration_details__c> intDetailsList = [SELECT Id,Name,Response_JSON__c
                                                        FROM Integration_details__c 
                                                        WHERE Name = 'Loan Exposure API' 
                                                        AND (Loan_Application__c =: recordId Or Related_Record_Id__c =: recordId)
                                                        Order By Createddate Desc LIMIT 1];

        if(!intDetailsList.isEmpty() && String.isNotBlank(intDetailsList[0].Response_JSON__c) && intDetailsList[0].Response_JSON__c.toLowerCase().contains('success') ) {
            returnStr = intDetailsList[0].Response_JSON__c;
        }

        return returnStr;
    }
        
    @AuraEnabled
    public static String getSalesforceExposure(string recordId, string processObject){
        
        Id customerId;
        
        if(processObject != 'Account'){
            Opportunity loanApp = [SELECT Id,Name, StageName,
                                    (SELECT Id,Name,Customer__c FROM Application_Applicant__r WHERE Applicant_type__c ='Primary Applicant') 
                                    FROM Opportunity 
                                    WHERE Id = :recordId
                                    LIMIT 1];

            // Check if there are related Application_Applicant__r records
            // if (loanApp.Application_Applicant__r != null && !loanApp.Application_Applicant__r.isEmpty()) {
                for (Application_Applicant__c applicant : loanApp.Application_Applicant__r) {
                    customerId = applicant.Customer__c;
                    System.debug('Applicant Id: ' + applicant.Id);
                    System.debug('Applicant Name: ' + applicant.Name);
                    System.debug('Customer Id: ' + customerId);
                }
            // } 
            // else {
            //     System.debug('No Primary Applicant found.');
            // }
        }
        else{
            customerId = recordId;
        }
        
        List<Opportunity> relatedLoanApps = [SELECT Id,Name, StageName,Requested_Amount__c,Sanction_Loan_Amount__c,Final_Amount__c
                                       		FROM Opportunity 
                                       		WHERE Accountid =:customerId];
        
        // Map to store stage-wise amounts
        Map<String, Decimal> stageWiseAmountMap = new Map<String, Decimal>();
        
        // Iterate over the opportunities and store values based on stage conditions
        for (Opportunity opp : relatedLoanApps) {
            Decimal amount = 0; // Default to 0 to handle null cases 
        
            if (opp.StageName == 'Sales Login' || opp.StageName == 'Pre-Credit' || opp.StageName == 'Credit Underwriting' || opp.StageName == 'PSV') {
                
                if(opp.StageName == 'Sales Login' || opp.StageName == 'Pre-Credit' || opp.StageName == 'Credit Underwriting'){
                    amount = (opp.Requested_Amount__c != null) ? opp.Requested_Amount__c : 0;
                }
                else if(opp.StageName == 'PSV'){
                    amount = (opp.Sanction_Loan_Amount__c != null) ? opp.Sanction_Loan_Amount__c : 0;
                }
            	
                if (stageWiseAmountMap.containsKey('WIP')) {
                    stageWiseAmountMap.put('WIP', stageWiseAmountMap.get('WIP') + amount);
                } else {
                    stageWiseAmountMap.put('WIP', amount);
                }
            } 
            else if(opp.StageName == 'Disbursement') { 
                amount = (opp.Final_Amount__c != null) ? opp.Final_Amount__c : 0; 
                
                if (stageWiseAmountMap.containsKey('Disbursement')) {
                    stageWiseAmountMap.put('Disbursement', stageWiseAmountMap.get('Disbursement') + amount);
                } else {
                    stageWiseAmountMap.put('Disbursement', amount);
                }
            }
        }
        
        // Create an instance of the wrapper class
        SalesforceExposureFields exposureData = new SalesforceExposureFields();

        for (String stage : stageWiseAmountMap.keySet()) {
            if(stage=='WIP'){
                exposureData.totalWIPLoan = stageWiseAmountMap.get(stage);
            }
            else if(stage == 'Disbursement'){
                exposureData.totalDisbursedLoan = stageWiseAmountMap.get(stage);
            }
        }
        
		System.debug('Salesforce Deserialized Response: ' + JSON.serialize(exposureData));

    	return JSON.serialize(exposureData);
    }
    
    public static LoanExposureResponseServiceWrapper initiateAPIRequest(string recordId, string processObject){
        try {
			Integration_Details__c integrationDetails = new Integration_Details__c();
			String loanId = processObject != 'Account' ? recordId: '';
			String processName = 'Loan Exposure API';
            LoanExposureResponseServiceWrapper returnWrapper = new LoanExposureResponseServiceWrapper();
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
            wrapper.recordId = recordId;
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
            wrapper.processObject = processObject;
            
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
            FROM Integration_Settings__c WHERE Name = 'Loan Exposure API' LIMIT 1];
            Integration_Settings__c intSetting = intSettingList[0];

            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c = String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName ;
                integrationDetail.Object_Name__c = processObject == 'Account' ? processObject : 'Opportunity';

                resultMessage = String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                System.debug('resultMessage: '+resultMessage);
                LoanExposureResponseServiceWrapper responseWrapper = new LoanExposureResponseServiceWrapper();
        		responseWrapper.returnStatus = new ReturnStatus();
 				responseWrapper.returnStatus.returnCode = '9999';
            	responseWrapper.returnStatus.returnText = resultMessage;
            
                returnResp = JSON.serialize(responseWrapper);
                returnWrapper = responseWrapper;
            }
            else{
                String bearer = Utility.getAccessToken();
                Map<String,String> integrationRequestMap = new Map<String,String>();
                integrationRequestMap.put('intSettingName',constants.get('Banking_Exposure_API'));
                integrationRequestMap.put('requestJSON',respWrapper.payload);
                System.debug('bearer----'+bearer);
                integrationRequestMap.put('bearer',bearer);
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
               
                LoanExposureResponseServiceWrapper LoanExpoResp = (LoanExposureResponseServiceWrapper) JSON.deserialize(resp.getBody(), LoanExposureResponseServiceWrapper.class);
                System.debug('LoanExpoResp: '+LoanExpoResp);
                returnResp=JSON.serialize(LoanExpoResp);
                returnWrapper = LoanExpoResp;
                integrationDetail.Calling_Source__c = wrapper.type; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 
                integrationDetail.Response_JSON__c = JSON.serialize(resp.getBody());
                integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
                integrationDetail.Method_Type__c = intSetting.Request_Method__c; 
                integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                integrationDetail.Name = processName;
                

                if(processObject == 'Account'){
                    integrationDetail.Object_Name__c = processObject;
                    integrationDetail.Related_Record_Id__c = recordId;
                }
                else{
                    Opportunity op = new Opportunity();
                    op.id = loanid;
                    Decimal sfExposure = getSFExposure(loanid,processObject);
                    // if(LoanExpoResp.bankingDetails != null && LoanExpoResp.bankingDetails.totalExposure != null) {
                    //     sfExposure = sfExposure + (LoanExpoResp.bankingDetails.totalExposure != null ? LoanExpoResp.bankingDetails.totalExposure : 0);
                    // }
                    if(LoanExpoResp.summaryExposure != null && LoanExpoResp.summaryExposure.exposureGHF != null && LoanExpoResp.summaryExposure.exposureGHF.disburstLoan != null){
                        sfExposure = sfExposure + Integer.valueOf(LoanExpoResp.summaryExposure.exposureGHF.disburstLoan);
                    }
                    op.Exposure__c = sfExposure;
                    Decimal securedExpo = 0;
                    Decimal unsecuredexpo = 0;
                    if(LoanExpoResp.existingLoans.size() > 0) {
                        for(ExistingLoan iterLoan : LoanExpoResp.existingLoans) {
                            if(iterLoan.loan_status != 'Rejected' && iterLoan.loan_status != 'Cancelled') {
                                if(iterLoan.loan_type == 'FL' || iterLoan.loan_type == 'FT') {
                                    unsecuredexpo = unsecuredexpo + iterLoan.undisbursed_amount + iterLoan.outstanding_amount;
                                }else{
                                    securedExpo = securedExpo + iterLoan.undisbursed_amount + iterLoan.outstanding_amount;
                                }
                            }
                        }
                    }
                    op.Secured_Exposure__c = securedExpo;
                    op.Unsecured_Exposure__c = unsecuredexpo;
                    update op;
                    integrationDetail.Object_Name__c = 'Opportunity';
                    integrationDetail.Related_Record_Id__c = recordId;
                    integrationDetail.Loan_Application__c = loanid;
                }

                String jsonStr = JSON.serialize(integrationDetail);

                insertIntegrationDetail(jsonStr);
            }
            return returnWrapper; 
        } catch (Exception e) {
            System.debug('LoanExposureController->initiateAPIRequest ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @future
    public static void insertIntegrationDetail(String jsonStrIntegrationDetail) {
        Integration_Details__c integrationDetail = (Integration_Details__c) JSON.deserialize(jsonStrIntegrationDetail, Integration_Details__c.class);
        insert integrationDetail;
    }
    
    @AuraEnabled
    public static Decimal getSFExposure(String loanId , String processObject) {
        Decimal amount = 0;
        if(processObject != 'Account'){
            Set<String> rejectedStatus = new Set<String>{'Hard Rejected','Soft Rejected 1','Soft Rejected 2','Rejected'};

            List<Opportunity> currentLoanApps = [SELECT Id, Accountid FROM Opportunity WHERE Id =: loanId];

            Utility_V1.ProductWrapper prodWrapper = Utility_V1.getProductDetails(new Map<String,String>{'oppId' => loanId}); //for HL case

            if(!prodWrapper.isHLRelated){
                for(Opportunity iterOp : [SELECT Id, StageName,Requested_Amount__c,Sanction_Loan_Amount__c
                                            FROM Opportunity WHERE Accountid =:currentLoanApps[0].Accountid and id != :loanId 
                                            and Approval_Status__c NOT IN :rejectedStatus AND StageName != 'Disbursement']) {

                    if(iterOp.StageName == 'Sales Login' || iterOp.StageName == 'Credit Underwriting' || iterOp.StageName == 'PSV'){
                        if(iterOp.Sanction_Loan_Amount__c != null && iterOp.Sanction_Loan_Amount__c >0) {
                            amount = amount + iterOp.Sanction_Loan_Amount__c;
                        }else if(iterOp.StageName != 'PSV' && iterOp.Requested_Amount__c != null && iterOp.Requested_Amount__c >0) {
                            amount = amount + iterOp.Requested_Amount__c;
                        }
                    }
                }
            }
            else{
                for(Product2 prod : [SELECT Id, Requested_Loan_Amount__c, Final_Loan_Amount__c FROM Product2 WHERE RecordType.Name = 'Sub Product' 
                                        AND Loan_Application__r.Accountid =: currentLoanApps[0].Accountid And Loan_Application__r.Loan_Hierarchy__c != 'Child'
                                        and Loan_Application__r.Approval_Status__c NOT IN :rejectedStatus AND Loan_Application__r.StageName != 'Disbursement']){
                    
                    if(prod.Final_Loan_Amount__c != null && prod.Final_Loan_Amount__c >0) {
                        amount = amount + prod.Final_Loan_Amount__c;
                    }else if(prod.Requested_Loan_Amount__c != null && prod.Requested_Loan_Amount__c >0) {
                        amount = amount + prod.Requested_Loan_Amount__c;
                    }
                }
            }
        }

        return amount;
    }
    
    @AuraEnabled
    public static Decimal getTotalExposure(String loanId) {
        List<Opportunity> currentLoanApps = [SELECT Id,Name,Exposure__c
                                       		FROM Opportunity 
                                       		WHERE Id =:loanId];
        if(currentLoanApps.size() > 0) {
            return currentLoanApps[0].Exposure__c;
        }else {
            return 0;
        }
    }
        
    public class LoanExposureResponseServiceWrapper{
        public ReturnStatus returnStatus;
        public BankingDetails bankingDetails;
        public SummaryExposure summaryExposure;
        public List<ExistingLoan> existingLoans;
        public LinklanDetails linklanDetails;
    }
    
    public class LoanExposureFinalResult{
        public ReturnStatus returnStatus;
        public BankingDetails bankingDetails;
        public SummaryExposure summaryExposure;
        public List<ExistingLoan> existingLoans;
        public LinklanDetails linklanDetails;
    }
    
    public class ReturnStatus {
        public String returnCode;
        public String returnText;
        public Boolean valid;
    }

    public class BankingDetails {
        public Decimal totalExposure;
        public Decimal totalExposureGHF_HFC;
        public Decimal totalExposureGFL_NBFC;
        public Decimal totalExposureGC;
    }

    public class SummaryExposure {
        public ExposureGHF exposureGHF;
        public ExposureGHF exposureGFL;
    }

    public class ExposureGHF {
        public String wipLoan;
        public String disburstLoan;
    }

    public class ExistingLoan {
        public String ucic;
        public String lan_no;
        public String full_name;
        public String cif;
        public Decimal original_amount;
        public Decimal installment_amount;
        public Decimal outstanding_amount;
        public String loan_date;
        public String loan_status;
        public String entity;
        public String dpd_string;
        public String dob;
        public String employment_type;
        public String employer_name;
        public String loan_type;
        public String no_of_bounce;
        public String booking_date;
        public Decimal undisbursed_amount;
        public String applicant;
    }

    public class LinklanDetails {
        public Map<String, List<LinkedLoan>> linkedLoans;
    }

    public class LinkedLoan {
        public String groupcode;
        public String groupdesc;
        public String lan;
    }    
    
    public class SalesforceExposureFields {
        public Decimal totalWIPLoan;
        public Decimal totalDisbursedLoan;
    }
}