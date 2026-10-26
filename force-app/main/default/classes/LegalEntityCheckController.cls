public with sharing class LegalEntityCheckController implements DynamicInvoker {
    @AuraEnabled
    public static String createInputMap(Id loanId, String processName, String appId) {
        System.debug('Inside createInputMap');
        System.debug('loanId: ' + loanId);
        System.debug('processName: ' + processName);
        System.debug('appId: ' + appId);
        try {
            List<Application_Applicant__c> applicants = [SELECT Id, Legal_Entity_Number__c FROM Application_Applicant__c 
                                                        WHERE Id = :appId AND Loan_Application__c = :loanId];
            InputWrapper inputWrapper = new InputWrapper();
            inputWrapper.loanId = loanId;
            inputWrapper.processName = processName;
            inputWrapper.applicantId = appId;
            inputWrapper.leiNo = applicants[0].Legal_Entity_Number__c;
            // String inputWrapperString = JSON.serialize(inputWrapper);

            return initiateLegalCheck(inputWrapper);

        } catch (Exception e) {
            throw new AuraHandledException('Error in createInputMap: ' + e.getMessage());
        }
    }

    static string conLabels = 'Legal_Enitity_check';
                         
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }


    @AuraEnabled
    public static string initiateLegalCheck(InputWrapper inputWrapper ){
        String res= 'fail';

        try {
            String resultMessage;
            String loanId = InputWrapper.loanId;
            String applicantId= InputWrapper.applicantId;
            String processName = InputWrapper.processName;
              processName = 'Loan Legal Entity';

            List<String> customerType = new List<String>();
            customerType.add('Individual');
            List<Integration_Master__mdt> metadata = [SELECT 
                                                        Process_Name__c,
                                                        Handler_Class__c,
                                                        Endpoint__c,
                                                        Request_Method__c,
                                                        Client_Id__c,
                                                        Client_Secret__c,
                                                        Allowed_Retry__c,
                                                        Gestation_Period__c,
                                                        Refresh_Allowed__c,
                                                        Activity_Name__c,Customer_Type__c,Content_Type__c
                                                    FROM Integration_Master__mdt 
                                                    WHERE Activity_Name__c = :processName];


            Map<String,Integration_Master__mdt> customerTypeMD = new Map<String,Integration_Master__mdt>();
            for(Integration_Master__mdt iterMeta : metadata) {
                customerTypeMD.put(iterMeta.Customer_Type__c,iterMeta);
            }

            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
            
            wrapper.recordId = applicantId;
            wrapper.loanApplicationId = loanId;  
            wrapper.type = processName;
            wrapper.endpoint = metadata[0].Endpoint__c;
            wrapper.requestMethod = metadata[0].Request_Method__c;
            wrapper.clientId = metadata[0].Client_Id__c;
            wrapper.clientSecret = metadata[0].Client_Secret__c;
            wrapper.allowedRetry = metadata[0].Allowed_Retry__c;
            wrapper.gestationPeriod = metadata[0].Gestation_Period__c;
            wrapper.activityname = metadata[0].Activity_Name__c;
            wrapper.refreshallowed = metadata[0].Refresh_Allowed__c;
            wrapper.handlername =  metadata[0].Handler_Class__c;
            wrapper.registrationNo = InputWrapper.leiNo;

            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);

            Integration_Details__c integrationDetail = new Integration_Details__c();
            integrationDetail.Related_Record_Id__c = loanId;
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                // Collect all validation errors and send back to JS
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = 'Loan_Application__c';
                
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                return resultMessage;
            }else{
                Map<String,String> integrationRequestMap = new Map<String,String>();
                integrationRequestMap.put('intSettingName','Legal_Enitity_check');
                integrationRequestMap.put('requestJSON',respWrapper.payload);
                String bearer=Utility.getAccessToken();
                System.debug('bearer----'+bearer);
                integrationRequestMap.put('bearer',bearer);
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                // String resp= '{"statusCode": 101,"requestId": "31c75ba2-8c5a-48cb-8ced-a8c8fb2b510e","result": {"entityRecordDetail": {"legal/RegisteredEntityAddress": {"city": "Mumbai","country": "India","region": "Maharashtra","registeredFirstAddressLine": "Hinduja House, No. 171, Dr. Annie Besant Road, Worli","postalPincode": "400018","additionalAddressLine": ""},"entityIdentifiers": {"legalForm": "Private Limited Companies","entityExpirationDate": "","successorLei": "","registrationAuthorityId": "U32304MH2007PTC167602","jurisdiction": "IN","registrationAuthorityName/Type": "Ministry of Corporate Affairs","leiRegistrationDate": "2017-11-01","entityStatus": "ACTIVE","entityExpirationReason": "","louId": "LEIL","leiValidationSource": "FULLY_CORROBORATED","leiNextRenewalDate": "2018-11-01","leiRegistrationStatus": "LAPSED","leiRegLastUpdateDate": "2018-11-01"},"headquartersEntityAddress": {"city": "Bangalore","firstAddressLine": "HGS International Services Pvt LTD, 1st Floor,","country": "India","region": "Karnataka","postalPincode": "560068","additionalAddressLine": "Gold Hill Square Software Park, No. 690, Bommanahalli, Hosur Road,"},"registeredEntityDetails": {"lei": "3358008J1F38JKKWXK61","legalName": "HGS International Services Private Limited"}},"leiExceptionDetails": {"ultimateParentExceptionDetails": {"exceptionReason": "NATURAL_PERSONS"},"directParentExceptionDetails": {"exceptionReason": "NATURAL_PERSONS"}},"leiRelationshipRecordDetails": {"directParentRelationshipRecordDetails": {"accountingStandard": "OTHER_ACCOUNTING_STANDARD","startDate(documentFilingPeriod)": "","relationshipQualifiersCategory": "ACCOUNTING_STANDARD","endDate(accountingPeriod)": "2017-03-31","initialRegistrationDate": "2017-11-01","registrationStatus": "Lapsed","endDate(documentFilingPeriod)": "","relationshipType": "IS_DIRECTLY_CONSOLIDATED_BY","percentShareholding": "100","validationSources": "FULLY_CORROBORATED","nextRenewalDate": "2018-11-01","leiCode": "335800BXIL3V4Q8HFQ18","startDate(accountingPeriod)": "2016-04-01","relationshipQuantifiers": "ACCOUNTING_CONSOLIDATION","relationshipStatus": "Active","endDateOfRelationship": "","periodType": "ACCOUNTING_PERIOD","startDateOfRelationship": "2007-02-06","lastUpdateDate": "2018-11-01","legalEntityName": "HINDUJA GLOBAL SOLUTIONS LIMITED","validationReference": "","managingLOU": "335800FVH4MOKZS9VH40"},"ultimateParentRelationshipRecordDetails": {"accountingStandard": "OTHER_ACCOUNTING_STANDARD","startDate(documentFilingPeriod)": "","relationshipQualifiersCategory": "ACCOUNTING_STANDARD","endDate(accountingPeriod)": "2017-03-31","initialRegistrationDate": "2017-11-01","registrationStatus": "Lapsed","endDate(documentFilingPeriod)": "","relationshipType": "IS_ULTIMATELY_CONSOLIDATED_BY","percentShareholding": "100","validationSources": "FULLY_CORROBORATED","nextRenewalDate": "2018-11-01","leiCode": "335800BXIL3V4Q8HFQ18","startDate(accountingPeriod)": "2016-04-01","relationshipQuantifiers": "ACCOUNTING_CONSOLIDATION","relationshipStatus": "Active","endDateOfRelationship": "","startDateOfRelationship": "2007-02-06","lastUpdateDate": "2018-11-01","legalEntityName": "HINDUJA GLOBAL SOLUTIONS LIMITED","validationReference": "","managingLOU": "335800FVH4MOKZS9VH40"}}},"clientData": {"caseId": "123456"}}';

                LegalEntityCheckResponseWrapper response= (LegalEntityCheckResponseWrapper)JSON.deserialize(resp.getBody(), LegalEntityCheckResponseWrapper.class);
                resultMessage = 'Sucess';
                integrationDetail.Calling_Source__c = wrapper.type; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 
                integrationDetail.Response_JSON__c = JSON.serialize(resp.getBody()); 
                integrationDetail.Status__c = String.valueof('200'); 
                integrationDetail.Method_Type__c = 'POST'; 
                integrationDetail.EndPoint__c = wrapper.endpoint; 
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.Name = processName; 
                integrationDetail.Loan_Application__c = loanid;
				integrationDetail.Is_Success_Response__c = true;
                insert integrationDetail;
                res= 'success';
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        return res;
    }

    @AuraEnabled
    public static List<LegalEntityCheckResponseWrapper> getLegalEntityCheckdata( String loanId){
        List<LegalEntityCheckResponseWrapper> caCheckWrapper= new List<LegalEntityCheckResponseWrapper>();
        try {
            Map<String, String> inteToApplicant= new Map<String, String>();
            List<Integration_Details__c> integrationDetails=  Utility.getIntegrationRecordsForCreditAPIs(loanId, 'Loan Legal Entity');
            for(Integration_Details__c integration: integrationDetails){
                inteToApplicant.put(integration.Id, integration.Related_Record_Id__c);
            }
            Map<Id,Application_Applicant__c> applicantList= new Map<Id,Application_Applicant__c>([SELECT Id, Name, Applicant_Name__c,Legal_Entity_Number__c FROM Application_Applicant__c WHERE Id IN :inteToApplicant.values()]);
            for(Integration_Details__c inte: integrationDetails){
                String response= inte.Response_JSON__c.replace('legal/RegisteredEntityAddress', 'legalRegisteredEntityAddress').replace('registrationAuthorityName/Type', 'registrationAuthorityNameType');
                LegalEntityCheckResponseWrapper respWrapper = (LegalEntityCheckResponseWrapper)JSON.deserialize(response, LegalEntityCheckResponseWrapper.Class);
                Application_Applicant__c applicant = applicantList.get(inte.Related_Record_Id__c);
                respWrapper.applicantName = applicant.Name;
                respWrapper.legalEntityNumber = applicant.Legal_Entity_Number__c;//added by oj
                caCheckWrapper.add(respWrapper);

            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return caCheckWrapper;
    }

    public class InputWrapper{
        @AuraEnabled public String loanId;
        @AuraEnabled public String applicantId;
        @AuraEnabled public String leiNo;
        @AuraEnabled public String processName;
    }

    public class LegalEntityCheckResponseWrapper{
        @AuraEnabled public String applicantName;
        @AuraEnabled public String legalEntityNumber { get; set; } //added by oj
        @AuraEnabled public Integer statusCode { get; set; }
        @AuraEnabled public String requestId { get; set; }
        @AuraEnabled public Cls_ResultWrapper result { get; set; }
        @AuraEnabled public Cls_ClientDataWrapper clientData { get; set; }
    }

    public class Cls_ResultWrapper {
        @AuraEnabled public Cls_EntityRecordDetailWrapper entityRecordDetail { get; set; }
        @AuraEnabled public Cls_LEIExceptionDetailsWrapper leiExceptionDetails { get; set; }
        @AuraEnabled public Cls_LEIRelationshipRecordDetailsWrapper leiRelationshipRecordDetails { get; set; }
    }

    public class Cls_EntityRecordDetailWrapper {
        @AuraEnabled public Cls_RegisteredEntityAddressWrapper legalRegisteredEntityAddress { get; set; }
        @AuraEnabled public Cls_EntityIdentifiersWrapper entityIdentifiers { get; set; }
        @AuraEnabled public Cls_HeadquartersEntityAddressWrapper headquartersEntityAddress { get; set; }
        @AuraEnabled public Cls_RegisteredEntityDetailsWrapper registeredEntityDetails { get; set; }
    }

    public class Cls_RegisteredEntityAddressWrapper {
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String country { get; set; }
        @AuraEnabled public String region { get; set; }
        @AuraEnabled public String registeredFirstAddressLine { get; set; }
        @AuraEnabled public String postalPincode { get; set; }
        @AuraEnabled public String additionalAddressLine { get; set; }
    }

    public class Cls_EntityIdentifiersWrapper {
        @AuraEnabled public String legalForm { get; set; }
        @AuraEnabled public String entityExpirationDate { get; set; }
        @AuraEnabled public String successorLei { get; set; }
        @AuraEnabled public String registrationAuthorityId { get; set; }
        @AuraEnabled public String jurisdiction { get; set; }
        @AuraEnabled public String registrationAuthorityNameType { get; set; }
        @AuraEnabled public String leiRegistrationDate { get; set; }
        @AuraEnabled public String entityStatus { get; set; }
        @AuraEnabled public String entityExpirationReason { get; set; }
        @AuraEnabled public String louId { get; set; }
        @AuraEnabled public String leiValidationSource { get; set; }
        @AuraEnabled public String leiNextRenewalDate { get; set; }
        @AuraEnabled public String leiRegistrationStatus { get; set; }
        @AuraEnabled public String leiRegLastUpdateDate { get; set; }
    }

    public class Cls_HeadquartersEntityAddressWrapper {
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String firstAddressLine { get; set; }
        @AuraEnabled public String country { get; set; }
        @AuraEnabled public String region { get; set; }
        @AuraEnabled public String postalPincode { get; set; }
        @AuraEnabled public String additionalAddressLine { get; set; }
    }

    public class Cls_RegisteredEntityDetailsWrapper {
        @AuraEnabled public String lei { get; set; }
        @AuraEnabled public String legalName { get; set; }
    }

    public class Cls_LEIExceptionDetailsWrapper {
        @AuraEnabled public Cls_ParentExceptionDetailsWrapper ultimateParentExceptionDetails { get; set; }
        @AuraEnabled public Cls_ParentExceptionDetailsWrapper directParentExceptionDetails { get; set; }
    }

    public class Cls_ParentExceptionDetailsWrapper {
        @AuraEnabled public String exceptionReason { get; set; }
    }

    public class Cls_LEIRelationshipRecordDetailsWrapper {
        @AuraEnabled public Cls_ParentRelationshipRecordWrapper directParentRelationshipRecordDetails { get; set; }
        @AuraEnabled public Cls_ParentRelationshipRecordWrapper ultimateParentRelationshipRecordDetails { get; set; }
    }

    public class Cls_ParentRelationshipRecordWrapper {
        @AuraEnabled public String accountingStandard { get; set; }
        @AuraEnabled public String startDateDocumentFilingPeriod { get; set; }
        @AuraEnabled public String relationshipQualifiersCategory { get; set; }
        @AuraEnabled public String endDateAccountingPeriod { get; set; }
        @AuraEnabled public String initialRegistrationDate { get; set; }
        @AuraEnabled public String registrationStatus { get; set; }
        @AuraEnabled public String endDateDocumentFilingPeriod { get; set; }
        @AuraEnabled public String relationshipType { get; set; }
        @AuraEnabled public String percentShareholding { get; set; }
        @AuraEnabled public String validationSources { get; set; }
        @AuraEnabled public String nextRenewalDate { get; set; }
        @AuraEnabled public String leiCode { get; set; }
        @AuraEnabled public String startDateAccountingPeriod { get; set; }
        @AuraEnabled public String relationshipQuantifiers { get; set; }
        @AuraEnabled public String relationshipStatus { get; set; }
        @AuraEnabled public String endDateOfRelationship { get; set; }
        @AuraEnabled public String startDateOfRelationship { get; set; }
        @AuraEnabled public String lastUpdateDate { get; set; }
        @AuraEnabled public String legalEntityName { get; set; }
        @AuraEnabled public String validationReference { get; set; }
        @AuraEnabled public String managingLOU { get; set; }
    }

    public class Cls_ClientDataWrapper {
        @AuraEnabled public String caseId { get; set; }
    }

  //added by oj from BL
      @AuraEnabled
    public static List<appWrapper> getAllApplicants(String loanId) {
        List<appWrapper> appWrapList = new List<appWrapper>();
        try {
            List<Application_Applicant__c> appList = [
                SELECT Id, Name, Legal_Entity_Number__c 
                FROM Application_Applicant__c 
                WHERE Loan_Application__c =: loanId
            ];

            for (Application_Applicant__c app : appList) {
                appWrapper appWrap = new appWrapper();
                appWrap.Name = app.Name;
                appWrap.legalEntityNumber = String.isNotBlank(app.Legal_Entity_Number__c) ? app.Legal_Entity_Number__c : '-';
                appWrap.applicantId = app.Id;
                appWrapList.add(appWrap);
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return appWrapList;
    }
      //added by oj from BL
     public class appWrapper {
        @AuraEnabled public String Name { get; set; }
        @AuraEnabled public String legalEntityNumber { get; set; }
        @AuraEnabled public Id applicantId { get; set; }
    } 


    public String invokeMethod(String loanId, String appId, String activityName) {
        return createInputMap(loanId, activityName, appId);
    }
}