public with sharing class StepLoanController {
    @AuraEnabled
    public static Id createAndUpdateStepLoan(StepLoanWrapper stepLoanDetails,String loanApplicationId,String relatedTransactionId){
        try {
            Loan_Transaction__c record = new Loan_Transaction__c();
            if(stepLoanDetails.stepLoanId != ''){
                record.Id = stepLoanDetails.stepLoanId;
            }
            record.Related_Transaction__c = relatedTransactionId;
            record.Loan_Application__c = loanApplicationId;
            record.RecordTypeId = SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get(CONSTANTS.STEP_LOAN_RECORD_TYPE_DEVELOPER_NAME).getRecordTypeId();
            record.Step_Number__c = stepLoanDetails.stepNumber;
            record.Step_Specifier__c = stepLoanDetails.stepIdentifier;
            record.Loan_Tenor__c = stepLoanDetails.stepLoanTenure;
            record.Step_Amount__c = stepLoanDetails.stepLoanAmount;
            record.Tenor_Split__c = stepLoanDetails.tenurePercentage;
            if(record != NULL){
                upsert record;
            }
            return record.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage()+e.getLineNumber());
        }
    }

    @AuraEnabled
    public static TransactionDetailsWrapper getTransactionDetails(Id loanId){
        try {
            TransactionDetailsWrapper transactionDetail = new TransactionDetailsWrapper();
            List<Loan_Transaction__c> loanTransanctionList = [SELECT Id,Allow_Grace__c,Step_Loan__c,Allow_Payment_in_Grace_Period__c ,Grace_Period_Frequency__c
                                                              FROM Loan_Transaction__c 
                                                              WHERE Loan_Application__c = :loanId 
                                                              AND RecordType.DeveloperName = 'Transaction_Details'];
            if(!loanTransanctionList.isEmpty()){
                transactionDetail.id = loanTransanctionList[0].Id;
                transactionDetail.allowGrace = loanTransanctionList[0].Allow_Grace__c;
                transactionDetail.stepLoan = loanTransanctionList[0].Step_Loan__c;
                transactionDetail.allowPayment = loanTransanctionList[0].Allow_Payment_in_Grace_Period__c;
                transactionDetail.gracePeriod = loanTransanctionList[0].Grace_Period_Frequency__c;
            }
            return transactionDetail;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<StepLoanWrapper> getStepLoan(Id loanId){
        try {
        List<StepLoanWrapper> stepLoanWrapperList = new List<StepLoanWrapper>();
        List<Loan_Transaction__c> stepLoanList = [SELECT Id,Loan_Tenor__c,Step_Specifier__c,Step_Number__c,Tenor_Split__c,Number_of_Instruments__c,Step_Amount__c 
                                                  FROM Loan_Transaction__c 
                                                  WHERE Loan_Application__c = :loanId 
                                                  AND RecordType.DeveloperName = 'Step_Loan_Details' 
                                                  ORDER BY Step_Number__c ASC];
        for(Loan_Transaction__c loan : stepLoanList){
            stepLoanWrapperList.add(new StepLoanWrapper(loan));
        }
        return stepLoanWrapperList;
    }catch (Exception e) {
            throw new AuraHandledException(e.getMessage()+e.getLineNumber());
        }
    }

    @AuraEnabled
    public static List<StepLoanWrapper> deleteAndRecalculateStepLoan(Id toBeDeletedStepLoanId){
        try{
            String loanAppId = '';
            Loan_Transaction__c toBeDeletedStepLoanRecord = [SELECT Id,Loan_Application__c 
                                                             FROM Loan_Transaction__c
                                                             WHERE Id = :toBeDeletedStepLoanId
                                                             LIMIT 1];
            if(toBeDeletedStepLoanRecord != null){
                loanAppId = toBeDeletedStepLoanRecord.Loan_Application__c;
                delete toBeDeletedStepLoanRecord;
            }
            List<Loan_Transaction__c> stepLoanList = [SELECT Id,Loan_Tenor__c,Step_Specifier__c,Step_Number__c,Tenor_Split__c,Number_of_Instruments__c,Step_Amount__c 
                                                      FROM Loan_Transaction__c 
                                                      WHERE Loan_Application__c = :loanAppId 
                                                      AND RecordType.DeveloperName = 'Step_Loan_Details' 
                                                      ORDER BY Step_Number__c ASC];                                     
            for(Integer i = 0; i < stepLoanList.size(); i++){
                stepLoanList[i].Step_Number__c = i+1; 
            }
            
            if(!stepLoanList.isEmpty()){
                update stepLoanList;
            }             
            return getStepLoan(loanAppId);

        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage()+e.getLineNumber());
        }                                    
    }  

    public static void recalculateStepNumbers(List<Loan_Transaction__c> stepLoanList){
        try{

            for(Integer i = 0; i < stepLoanList.size(); i++){
                stepLoanList[i].Step_Number__c = i+1;
            }
            if(stepLoanList.size() > 0){
                update stepLoanList;
            }
           
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage()+e.getLineNumber());
        }
    }

    public class TransactionDetailsWrapper{
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public Boolean allowGrace { get; set; }
        @AuraEnabled public Boolean stepLoan { get; set; }
        @AuraEnabled public Boolean allowPayment { get; set; }
        @AuraEnabled public Decimal gracePeriod { get; set; }

    }

    public class StepLoanWrapper {
        @AuraEnabled public Decimal stepNumber { get; set; }
        @AuraEnabled public String stepLoanId {get; set; }
        @AuraEnabled public String stepIdentifier { get; set; }
        @AuraEnabled public Decimal stepLoanAmount { get; set; }
        @AuraEnabled public Decimal stepLoanTenure { get; set; }
        @AuraEnabled public Decimal tenurePercentage { get; set; }
        @AuraEnabled public Boolean disabledRow { get; set; }
        @AuraEnabled public Boolean showEdit { get; set;}
        @AuraEnabled public Boolean showDelete { get; set;}
        @AuraEnabled public Boolean disableInput { get; set; }

        public StepLoanWrapper(Loan_Transaction__c loanTransaction) {
            this.stepNumber = loanTransaction.Step_Number__c;
            this.stepLoanId = loanTransaction.Id;
            this.stepIdentifier = loanTransaction.Step_Specifier__c;
            this.stepLoanAmount = loanTransaction.Step_Amount__c;
            this.stepLoanTenure = loanTransaction.Loan_Tenor__c;
            this.tenurePercentage = loanTransaction.Tenor_Split__c;
            this.disabledRow = true;
            this.showEdit = false;
            this.showDelete = true;
            this.disableInput = true;
        }
        public StepLoanWrapper() {

        }
    }
}