public with sharing class IntHandler {

    public static processResWrapper validateProcess(ProcessReqWrapper wrapper) { 
        List<String> validationErrors = new List<String>();
        processResWrapper respWrapper = new processResWrapper();
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
                                            WHERE Activity_Name__c =: wrapper.type LIMIT 1];

        wrapper.endpoint = metadata.Endpoint__c;
        wrapper.requestMethod = metadata.Request_Method__c;
        wrapper.clientId = metadata.Client_Id__c;
        wrapper.clientSecret = metadata.Client_Secret__c;
        wrapper.allowedRetry = metadata.Allowed_Retry__c;
        wrapper.gestationPeriod = metadata.Gestation_Period__c;
        wrapper.activityname = metadata.Activity_Name__c;
        wrapper.refreshallowed = metadata.Refresh_Allowed__c;
        wrapper.handlername = metadata.Handler_Class__c;
        system.debug('line 29--->>'+wrapper.handlername);
        System.debug('type wrapper '+wrapper.type);
        System.debug('recordId wrapper '+wrapper.recordId);
        System.debug('loanapplicationid wrapper '+wrapper.loanApplicationId);
        List<Integration_Details__c> integrationDetails = new List<Integration_Details__c>();
        if(wrapper.recordId != null && wrapper.recordId != '' && wrapper.recordId != wrapper.loanApplicationId &&  wrapper.loanApplicationId != null){
            System.debug('At 36');
            integrationDetails = [
                SELECT Id, Name 
                FROM Integration_Details__c 
                WHERE Name = :wrapper.type And (Loan_Application__c =: wrapper.loanApplicationId Or Related_Record_Id__c =: wrapper.recordId) 
                ORDER BY CreatedDate DESC
            ];
            System.debug('integrationDetails >>>'+integrationDetails);
            System.debug('At 40');
        }
        else if (wrapper.loanApplicationId != null && (wrapper.recordId == null || wrapper.recordId == '')){
            System.debug('At 47');
            integrationDetails = [
                SELECT Id, Name 
                FROM Integration_Details__c 
                WHERE Loan_Application__c =: wrapper.loanApplicationId AND Name =: wrapper.type
                ORDER BY CreatedDate DESC
            ];
            System.debug('At 49');

        }
        else if ((wrapper.recordId != null && wrapper.recordId != '') && wrapper.loanApplicationId == null){
             System.debug('At 58');
             integrationDetails = [
                SELECT Id, Name 
                FROM Integration_Details__c 
                WHERE Related_Record_Id__c =: wrapper.recordId AND Name =: wrapper.type
                ORDER BY CreatedDate DESC
            ];
            System.debug('At 59');

        }
        system.debug('integrationDetails '+ integrationDetails.size());
        System.debug('integration refresh ' + JSON.serialize(wrapper));
        System.debug('>>'+integrationDetails.isEmpty());
        
        if(!integrationDetails.isEmpty()) {
            System.debug('Wrapper >>>>>'+wrapper);
            if(wrapper.allowedRetry == null || wrapper.allowedRetry == 0) {
                System.debug('At 73');
                validationErrors.add('Error:Retry not allowed');
            }
            else if(wrapper.allowedRetry > 0){
                System.debug('At 77');
                if(integrationDetails.size() > wrapper.allowedRetry + 1){
                    validationErrors.add('Error: Maximum retries exceeded');
                }
            }

            if(wrapper.gestationPeriod > 0) { // gestation period related validations here
                System.debug('At 84');
                if(wrapper.gestationPeriod < 18 || wrapper.gestationPeriod > 39) {
                    validationErrors.add('Error:Gestation period error');
                }
            }
            System.debug('At 89');
            if(wrapper.refreshallowed == false) {
                validationErrors.add('Error:Refresh is not allowed');
            }
        }
        system.debug('validationErrors'+validationErrors);


        if(validationErrors.size() == 0)
        {
            System.debug('wrapper 100>>>>'+wrapper);
            system.debug('inside first if::=====wrapper.handlername'+wrapper.handlername);
            Type handlertype = System.Type.forName(wrapper.handlername);
            system.debug('inside first if 2::'+handlertype);
            IntegrationInterface handlerservice = (IntegrationInterface)handlertype.newInstance();
            system.debug('inside first if 3::'+handlerservice);
            List<String> handlerErrors = handlerservice.validatePayload(wrapper);
            system.debug('inside first if 4::'+handlerErrors);
            validationErrors.addAll(handlerErrors);
            system.debug('validationErrors 2'+validationErrors);
            
            if(!validationErrors.isEmpty()){
                system.debug('inside if::');
                respWrapper.prerequisiteError = validationErrors;
                //return respWrapper;
            }
            else
            {
                //system.debug('inside else::');
                list<Integration_Details__c> intdetails = new list<Integration_Details__c>();
                string response = handlerservice.constructPayload(wrapper, intdetails);
                system.debug('inside else 2::'+response);
                respWrapper.payload = response;
                //return respWrapper;
            }
        }
        else {
            respWrapper.prerequisiteError = validationErrors;
            //return respWrapper;
        }
        system.debug('respWrapper'+respWrapper);
        return respWrapper;
    }

    public class ProcessReqWrapper {
        @AuraEnabled public String appColId           { get; set; }   
        @AuraEnabled public String recordId { get; set; }
        @AuraEnabled public String loanApplicationId { get; set; }
        @AuraEnabled public String applicantId { get; set; }
        @AuraEnabled public String type { get; set; } 
        @AuraEnabled public String endpoint { get; set; }
        @AuraEnabled public String requestMethod { get; set; }
        @AuraEnabled public String handlerClass { get; set; }
        @AuraEnabled public String clientId { get; set; }
        @AuraEnabled public String clientSecret { get; set; }
        @AuraEnabled public Decimal allowedRetry { get; set; }
        @AuraEnabled public Boolean refreshallowed { get; set; }
        @AuraEnabled public Decimal gestationPeriod { get; set; }
        @AuraEnabled public String activityname { get; set; }
        @AuraEnabled public String handlername { get; set; }
        @AuraEnabled public String fileBase64 { get; set; }
        @AuraEnabled public String docType { get; set; }
        @AuraEnabled public String contentVersionId { get; set; }
        @AuraEnabled public String panNumber { get; set; }
        @AuraEnabled public String customerFirstName { get; set; }
        @AuraEnabled public String customerLastName { get; set; }
        @AuraEnabled public Date customerDOB { get; set; }
        @AuraEnabled public String mobNumber { get; set; }
        @AuraEnabled public String docId { get; set; }
        @AuraEnabled public String s3URL { get; set; }
        @AuraEnabled public String voterNumber { get; set; }  
        @AuraEnabled public List<String> contentVersionIdList { get; set;}   
        @AuraEnabled public String applicantName { get; set; }
        @AuraEnabled public String applicantEmail { get; set; }
        @AuraEnabled public String applicantMobile { get; set; }
        @AuraEnabled public String councilName { get; set; }
        @AuraEnabled public String registrationNo { get; set; }
        @AuraEnabled public String yearOfReg { get; set; }  
        @AuraEnabled public String otp { get; set; } 
        @AuraEnabled public Boolean isIncomeRelated { get; set; } 
        @AuraEnabled public Map<String, String> inputMap { get; set; } 
        @AuraEnabled public String areaCode { get; set; }
        @AuraEnabled public String loanSchedulerInvocationType {get; set;} //added for differntiating LS invocation
        @AuraEnabled public String eligibilityType {get; set;}
        @AuraEnabled public String email {get; set;}
        @AuraEnabled public String content {get; set;}
        @AuraEnabled public String base64String {get; set;}
        @AuraEnabled public String fileType {get; set;}
        @AuraEnabled public String filename {get; set;}
        @AuraEnabled public String subject {get; set;}
        @AuraEnabled public boolean isIncomeFromSales {get; set;}
        @AuraEnabled public boolean callForDeviation {get; set;}
        @AuraEnabled public String adb {get; set;}
        @AuraEnabled public Decimal dto {get; set;}
        @AuraEnabled public String processObject {get; set;}
        @AuraEnabled public String cmMobile {get; set;}
         @AuraEnabled public String documentDetailsResponse {get; set;}
        @AuraEnabled public String documentDetailsExcel {get; set;}
        @AuraEnabled public String fieldSet{get; set;}
        @AuraEnabled public String objectName{get;set;}
        @AuraEnabled public String collateralJson{get;set;}
        @AuraEnabled public String aadharNumber {get; set;}
        @AuraEnabled public String dlNumber {get; set;}
        @AuraEnabled public String passportNumber {get; set;}
        @AuraEnabled public String uniqueReqId { get; set; }
        @AuraEnabled public String externalId { get; set; }
        @AuraEnabled public boolean scannedCopy {get; set;}
        @AuraEnabled public String otpNumber {get; set;}
        @AuraEnabled public String uan { get; set; }
        @AuraEnabled public String gender {get;set;}
        @AuraEnabled public Decimal sanctionLoanAmount {get;set;}
        @AuraEnabled public Integer sanctionLoanTenure {get;set;}
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public Boolean isQdp { get; set; } 
        @AuraEnabled public String feeType { get; set; }
        @AuraEnabled public Map<String,String> mapOfappColIdPlfId {get; set;} 
        @AuraEnabled public List<String> colRefIdList { get; set; }
        @AuraEnabled public Boolean isWaiverAmountCalc { get; set; } 
        @AuraEnabled public String latitude { get; set; } 
        @AuraEnabled public String longitude { get; set; } 
        @AuraEnabled public String accessKey { get; set; } 
        //HL-Prachi-31/10
        @AuraEnabled public String cin { get; set; } 
        //HL-Prachi-31/10
        //HL-Ishi-31/10
        @AuraEnabled public Boolean isforFL { get; set; } 
        //HL-Ishi-31/10
       @AuraEnabled public String userCalValues { get; set; }
        @AuraEnabled public Boolean showCalculator { get; set; }
        @AuraEnabled public Decimal gstAmountForApi {get; set;} //Arman :18th Dec 2205
        @AuraEnabled public Charges_Insurance__c upfrontFeeObj {get; set;} //Arman  19th Dec 20225
        @AuraEnabled public String modeOfTrigger { get; set; }
        @AuraEnabled public String templateName {get; set;}
    }
    
    public class processResWrapper{
        @AuraEnabled public List<string> prerequisiteError {get; set;}
        @AuraEnabled public String payload {get; set;}
        @Auraenabled public Integration_Details__c integrationDetail {get; set;}
      
    } 
}