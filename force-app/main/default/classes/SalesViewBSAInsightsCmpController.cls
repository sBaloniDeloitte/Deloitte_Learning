public without sharing class SalesViewBSAInsightsCmpController {
    
    @AuraEnabled
    public static List<BankAccountWrapper> getBankAccounts( String loanId){
        List<BankAccountWrapper> bankList= new List<BankAccountWrapper>();
        try {
            List<Bank_Details__c> bankDetails = [SELECT Id, Perfios_Bank_Account_Type__c,Account_Number__c,Account_Holder_Name__c, Account_Type__c, Name,Application_Applicant__r.Loan_Application__r.StageName  FROM Bank_Details__c WHERE Application_Applicant__r.Loan_Application__c = :loanId AND Application_Applicant__r.Loan_Application__c !=null ORDER BY CreatedDate desc];
            for(Bank_Details__c bank : bankDetails){
                BankAccountWrapper bankWrapper = new BankAccountWrapper();
                bankWrapper.bankId = bank.Id;
                bankWrapper.perfiosAccountType = bank.Perfios_Bank_Account_Type__c;
                bankWrapper.accountHolderName = bank.Account_Holder_Name__c;
                bankWrapper.accountType = bank.Account_Type__c;
                bankWrapper.accountNumber = bank.Account_Number__c;
                bankWrapper.bankName = bank.Name;
                bankWrapper.isEdittable =  bank.Application_Applicant__r.Loan_Application__r.StageName=='Sales Login' ?true:false;
                // bankWrapper.isEdittable = bank.Account_Type__c != null ? (bank.Perfios_Bank_Account_Type__c!= null ? false : true): true;
                bankList.add(bankWrapper);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return bankList;
    }

    public class BankAccountWrapper{
        @AuraEnabled public String bankId;
        @AuraEnabled public String bankName;
        @AuraEnabled public String accountHolderName;
        @AuraEnabled public String accountNumber;
        @AuraEnabled public String accountType;
        @AuraEnabled public String perfiosAccountType;
        @AuraEnabled public Boolean isEdittable;
    }

    @AuraEnabled
    public static string updateAccountType( String bankId, String accountType){
        String res = 'fail';
        try {
            Bank_Details__c bank= new Bank_Details__c();
            bank.Id = bankId;
            bank.Account_Type__c = accountType;
            update bank;

            res= 'success';
        } catch (Exception e) {
            // throw new AuraHandledException(e.getMessage());
            res = e.getMessage();
        }

        return res;
    }

   @AuraEnabled
    public static Boolean checkAllAccountTypesFilled(String recordId) {
        try {
            System.debug('recordId------'+recordId);
            List<Bank_Details__c> bankDetails = [
                SELECT Id 
                FROM Bank_Details__c 
                WHERE Application_Applicant__r.Loan_Application__c = :recordId 
                AND Account_Type__c = NULL
            ];
            if (bankDetails.size() > 0) {
                   System.debug('recordId------'+recordId);
                return true;
            } else {
                return false;
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


}