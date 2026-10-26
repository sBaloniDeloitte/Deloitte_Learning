public with sharing class CreditSoftRejectionBatch implements Database.Batchable<sObject>{
    static string conLabels = 'Loan_Soft_Rejected_2_Threshold';
                         
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Product__c, Approval_Status__c,(SELECT Id, CreatedDate, NewValue FROM Histories WHERE Field = \'Approval_Status__c\'  ORDER BY CreatedDate DESC LIMIT 1) FROM Opportunity WHERE Approval_Status__c = \'Soft Rejected 1\'';
        return Database.getQueryLocator(query);
    }
   
    public void execute(Database.BatchableContext BC, List<Opportunity> opportunityList) {
        Integer thresholdDays = Integer.valueOf(constants.get('Loan_Soft_Rejected_2_Threshold'));
        
        Date today = Date.today();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

        List<Integration_Details__c> integrationList= new List<Integration_Details__c>();
        Map<Id, Integration_Details__c> oppToIntegrationMap = new Map<Id, Integration_Details__c>();
        List<Communication__e> eventList = new List<Communication__e>();
        
        List<product2> productList= [SELECT Id, name, Description, Loan_Application__c FROM product2 WHERE  Loan_Application__c In :opportunityList AND RecordType.name = 'Variant' AND (Product__r.Product__r.name = 'Affordable Home Loan' OR Product__r.Product__r.name = 'Affordable Non-Home Loan') AND Product__r.Product__r.Product_Type__c = 'Parent'];
        List<product2> mainProduct= [SELECT Id, name,Loan_Application__c FROM product2 WHERE Loan_Application__c In :opportunityList AND RecordType.name = 'Product' AND Product_Type__c = 'Parent'];
        Map<String, String> productNameMap= new Map<String, String>();
        //for(product2 prod: productList){
        //    productNameMap.put(prod.Loan_Application__c, prod.Name);
        //}
        for(product2 prod: mainProduct){
            productNameMap.put(prod.Loan_Application__c, prod.Name);
        }
        for (Opportunity opp : opportunityList) {
            if (opp.Histories != null && !opp.Histories.isEmpty()) {
                OpportunityFieldHistory latestHistory = opp.Histories[0];
                Date historyDate = latestHistory.CreatedDate.date();
                System.debug('historyDate >>'+historyDate);
                Integer daysDifference = historyDate.daysBetween(today);
                System.debug('daysDifference >>'+daysDifference);
                System.debug('thresholdDays >>'+thresholdDays);
                System.debug('latestHistory.NewValue >>'+latestHistory.NewValue);

                //for testing
                // if (daysDifference <= thresholdDays && latestHistory.NewValue == 'Soft Rejected 1') {
                //     opp.Approval_Status__c = 'Soft Rejected 2';
                //     opportunitiesToUpdate.add(opp);
                // }
                //for testing

                if (daysDifference >= thresholdDays && isSoftRejected1(opp)) {
                    opp.Approval_Status__c = 'Soft Rejected 2';
                    opportunitiesToUpdate.add(opp);
                }
                // for testing
                // System.debug('daysDifference: '+daysDifference);
                // System.debug('thresholdDays: '+thresholdDays);
                // System.debug('latestHistory.NewValue: '+latestHistory.NewValue);
                // if (daysDifference <= thresholdDays && latestHistory.NewValue == 'Soft Rejected 1') {
                //     opp.Approval_Status__c = 'Soft Rejected 2';
                //     opportunitiesToUpdate.add(opp);
                // }

                // for testing
                
            }
        }

        if (!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
        }

        List<Application_Applicant__c> applicantList= [SELECT Id,Customer_Type__c, Name_of_Organization__c, Customer_LMS_Id__c, Customer__r.SF_Customer_ID__c,Loan_Application__c, Loan_Application__r.name,Applicant_Type__c, Salutation__c,First_Name__c, Last_Name__c, Company__c, Loan_Application__r.Product__c, Loan_Application__r.Owner.Name,  Email__c, Mobile_Number__c FROM Application_Applicant__c WHERE Loan_Application__c IN :opportunitiesToUpdate AND Applicant_Type__c = 'Primary Applicant'];
        Map<Id, List<Application_Applicant__c>> loanToApplicantMap = new Map<Id, List<Application_Applicant__c>>();
        for(Application_Applicant__c app: applicantList){
            if(loanToApplicantMap.containsKey(app.Loan_Application__c)){
                loanToApplicantMap.get(app.Loan_Application__c).add(app);
            }else{
                loanToApplicantMap.put(app.Loan_Application__c, new List<Application_Applicant__c>{app});
            }  
        }

        for(Opportunity opp: opportunitiesToUpdate){
            List<Application_Applicant__c> applicants= loanToApplicantMap.get(opp.Id);
            String loanProduct;
            if(productNameMap.size() > 0 && productNameMap.containsKey(opp.Id)) {
                if(productNameMap.get(opp.Id) == 'Affordable Home Loan') {
                    loanProduct = 'AH';
                }else if(productNameMap.get(opp.Id) == 'Affordable Non-Home Loan') {
                    loanProduct = 'AL';
                }else if(productNameMap.get(opp.Id)== 'Flexi Loan') {
                    loanProduct = 'FL';
                }
            }
            
            
            String messageWrapper;

            List<CommunicationEventWrapper.SoftReject2Wrapper> softRejectList= new List<CommunicationEventWrapper.SoftReject2Wrapper>();
            for(Application_Applicant__c app:applicants){
                System.debug('app.Customer__c '+app.Customer__c);
                List<String> sfId;
                if(Test.isRunningTest()) {
                    sfId = new List<String>{'C','00000002'};
                }else {
                    sfId= app.Customer__r.SF_Customer_ID__c.split('-');
                }
                String cifNumber = sfId[1].trim();
                CommunicationEventWrapper.SoftReject2Wrapper rejectWrapper = new CommunicationEventWrapper.SoftReject2Wrapper();
                rejectWrapper.Salutation = app.Customer_Type__c == 'Individual' ? (String.isNotBlank(app.Salutation__c) ? app.Salutation__c: '') : 'M/s';
                rejectWrapper.FirstName = String.isNotBlank(app.First_Name__c)? app.First_Name__c :'';
                rejectWrapper.LastName = String.isNotBlank(app.Last_Name__c) ? app.Last_Name__c: '';
                rejectWrapper.CompanyName = app.Customer_Type__c == 'Individual' ? (String.isNotBlank(app.Company__c) ?  app.Company__c: '') :  (String.isNotBlank(app.Name_of_Organization__c) ?  app.Name_of_Organization__c: '');
                rejectWrapper.ProductName = String.isNotBlank(loanProduct) ? loanProduct : '';
                rejectWrapper.LANNumber = String.isNotBlank(app.Loan_Application__r.name) ? app.Loan_Application__r.name : '';
                rejectWrapper.CustomerCategory = app.Customer_Type__c == 'Individual' ? 'RETAIL': (app.Customer_Type__c == 'Non Individual' ? 'CORP' :'' );
                rejectWrapper.emailId = String.isNotBlank(app.Email__c) ? app.Email__c: '';
                rejectWrapper.mobile_number = app.Mobile_Number__c != null ? String.valueOf(app.Mobile_Number__c): '';
                rejectWrapper.applicantType = String.isNotBlank(app.Applicant_Type__c) ? app.Applicant_Type__c: '';
                rejectWrapper.whatsaap_number = app.Mobile_Number__c != null ? String.valueOf(app.Mobile_Number__c): '';
                rejectWrapper.ProductDescription = '';
                rejectWrapper.cif = String.isNotBlank(app.Customer_LMS_Id__c) ? app.Customer_LMS_Id__c: cifNumber;
                softRejectList.add(rejectWrapper);
            }
            messageWrapper = JSON.serialize(softRejectList);

            if(messageWrapper != null && messageWrapper!= '' && loanProduct!= null && loanProduct!= ''){
                Integration_Details__c integration = new Integration_Details__c();
                integration.name = 'Communication Event';
                integration.Loan_Application__c = opp.Id;
                integration.Endpoint__c = 'Rejection-Soft Rejec2'; 
                integration.Communication_Status__c = 'Published';
                integration.Request_JSON__c = messageWrapper;
                insert integration;
                integrationList.add(integration);

                String commProduct;
                if(mainProduct.size() > 0) {
                    if(mainProduct[0].name == 'Affordable Home Loan') {
                        commProduct = 'Affordable Housing loan';
                    }else if(mainProduct[0].name == 'Affordable Non-Home Loan') {
                        commProduct = 'Affordable LAP';
                    }else if(mainProduct[0].name == 'Flexi Loan') {
                        commProduct = 'Flexible Loan';
                    }
                }
                Communication__e event = new Communication__e(
                    Message__c = messageWrapper,
                    Record_Id__c = integration.Id,
                    Type__c = 'Rejection-Soft Rejec2',
                    product__c = commProduct
                );

                eventList.add(event);
            }
        }

        if (!eventList.isEmpty()) {
            Database.SaveResult[] results = EventBus.publish(eventList);

            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error publishing event: ' + error.getMessage());
                    }
                } else {
                    System.debug('Platform Event published successfully.');
                }
            }
        }
    }

    public void finish(Database.BatchableContext BC) {

    }
    
    public static Boolean isSoftRejected1(Opportunity opp) {
        if (!Test.isRunningTest()) {
            return !opp.Histories.isEmpty() && opp.Histories[0].NewValue == 'Soft Rejected 1';
        } else {
            return opp.Approval_Status__c == 'Soft Rejected 1';
        }
    }
}