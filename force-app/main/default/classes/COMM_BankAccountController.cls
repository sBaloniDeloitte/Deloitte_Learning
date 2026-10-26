public class COMM_BankAccountController {
	@AuraEnabled
    public static Boolean isBankAdded(String loanAppId) {
        Set<String> devTypeSet = new Set<String>();
        devTypeSet.add('Co Applicant');
        devTypeSet.add('Guarantor');
        devTypeSet.add('Primary Applicant');
        Boolean isBank = false;
        List<Application_Applicant__c> adList = [SELECT Id, Applicant_Type__c, Customer__r.name, Customer__c
                                            FROM Application_Applicant__c WHERE Loan_Application__c = :loanAppId AND Applicant_Type__c IN : devTypeSet ORDER BY Applicant_Type__c];
        

        List<Bank_Details__c> bankList = [SELECT Id FROM Bank_Details__c WHERE Application_Applicant__c IN : adList ];
        if(!bankList.isEmpty()){
            isBank = true;
        }
        
        
        return isbank;
    }

    @AuraEnabled(cacheable=true)
    public static List<CustomerWrapper> getCustomerDetails(String loanAppId){
        try {
            Map<Id, String> customerMap = new Map<Id, String>();
            List<Application_Applicant__c> relatedCustomerLst = [SELECT Id, Customer__c, Name, Applicant_Type__c From Application_Applicant__c 
                                    Where Loan_Application__c = :loanAppId];
            List<CustomerWrapper> custWrapLst = new List<CustomerWrapper>();
    
            for(Application_Applicant__c appDetail: relatedCustomerLst){
                CustomerWrapper custWrap = new CustomerWrapper();
                custWrap.custId = appDetail.Id;
                custWrap.custName = appDetail.Name;
                custWrap.applicantType = appDetail.Applicant_Type__c;
                custWrapLst.add(custWrap);
            }
            return custWrapLst;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static IFSCWrapper getIFSCDetails(String ifsc,String loanId){

        Bank_Branch_Master__c bankmaster= [select id,Bank_Name__c,Branch_Name__c,IFSC__c from Bank_Branch_Master__c where id=:ifsc];
        IFSCWrapper ifsccode = new IFSCWrapper();
        ifsccode.bankname=bankmaster.Bank_Name__c;
        ifsccode.branch=bankmaster.Branch_Name__c;
        ifsccode.ifscVal=bankmaster.IFSC__c;

        return ifsccode;
       
    }
    
    @AuraEnabled
    public static Boolean isDupBank(String loanAppId, String ifsc, String acNumber) {
    	Boolean isDup = false;
        Set<String> devTypeSet = new Set<String>();
        devTypeSet.add('Co Applicant');
        devTypeSet.add('Guarantor');
        devTypeSet.add('Primary Applicant');

        List<Application_Applicant__c> adList = [SELECT Id, Applicant_Type__c, Customer__r.name, Customer__c
                                            FROM Application_Applicant__c WHERE Loan_Application__c =: loanAppId AND Applicant_Type__c IN : devTypeSet ORDER BY Applicant_Type__c];
        

        List<Bank_Details__c> bankList = [SELECT Id FROM Bank_Details__c WHERE Application_Applicant__c IN : adList  AND Account_Number__c =:acNumber AND Bank_Master__c =:ifsc];
        if(!bankList.isEmpty()){
            isDup = true;
        }
        
        
        return isDup;
    } 
    
    public class CustomerWrapper{
        @AuraEnabled public String custId {get; set;}
        @AuraEnabled public String custName {get; set;}
        @AuraEnabled public String applicantType {get; set;}
        @AuraEnabled public String custFirstName {get; set;}
        @AuraEnabled public String custLastName {get; set;}
    }

    public class IFSCWrapper{
        @AuraEnabled public String bankname {get; set;}
        @AuraEnabled public String branch {get; set;}
        @AuraEnabled public String ifscVal {get; set;}

       
    }

    @AuraEnabled
    public static Bank_Details__c getBankDetails( String applicantId){
        Bank_Details__c bankdetail= new Bank_Details__c();
        try {
            List<Bank_Details__c> bankdetailList = [SELECT Id,  Account_Type__c, Bank_Master__c, Is_Consider_for_Eligibility__c, Account_Holder_Name__c, Debit_Card_Status__c, Account_Number__c, Application_Applicant__c, Bank_Master__r.Bank_Name__c, Bank_Master__r.Branch_Name__c, Bank_Master__r.Name, Bank_Master__r.MICR__c FROM Bank_Details__c WHERE Application_Applicant__c = : applicantId ORDER BY CreatedDate DESC LIMIT 1];
            if(bankdetailList.size()>0){
                bankdetail = bankdetailList[0];
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return bankdetail;
    }

    @AuraEnabled
    public static ReturnBankWrapper checkExistingBank(String loanAppId, String ifsc, String acNumber){
        System.debug('existing bank details'+loanAppId);
        Set<String> devTypeSet = new Set<String>();
        devTypeSet.add('Co Applicant');
        devTypeSet.add('Guarantor');
        devTypeSet.add('Primary Applicant');

        ReturnBankWrapper bankWrap= new ReturnBankWrapper();
        bankWrap.bankExist = false;
        try {
            List<Application_Applicant__c> adList = [SELECT Id, Applicant_Type__c, Customer__r.name, Customer__c
                                            FROM Application_Applicant__c WHERE Loan_Application__c =: loanAppId  ORDER BY Applicant_Type__c];
        

            List<Bank_Details__c> bankList = [SELECT Id,  Account_Type__c, Bank_Master__c, Is_Consider_for_Eligibility__c, Account_Holder_Name__c, Debit_Card_Status__c, Account_Number__c, Application_Applicant__c, Bank_Master__r.Bank_Name__c, Bank_Master__r.Branch_Name__c, Bank_Master__r.Name, Bank_Master__r.MICR__c FROM Bank_Details__c WHERE Application_Applicant__c = :loanAppId  AND Account_Number__c =:acNumber AND Bank_Master__c =:ifsc];
            if(!bankList.isEmpty()){
                bankWrap.bankExist = true;
                bankWrap.bankDetail = bankList[0];
            }
        } catch (Exception ex) {
            System.debug('exception in checkExistingBank'+ex.getMessage());
        }
        return bankWrap;
    }

    public class ReturnBankWrapper{
        @AuraEnabled public Boolean bankExist {get; set;}
        @AuraEnabled public Bank_Details__c bankDetail {get; set;}
    }
}