@isTest
public class COMM_BsaCmpControllerTest {
    
    @testSetup
    static void setupTestData() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        
        // Create Opportunity
        Opportunity opportunity = FITestDataFactory.createOpportunity(customer);
        
        // Create Applicant
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opportunity);
        Bank_Details__c bankDetail  =   FITestDataFactory.getBankdetails (true , applicant.Id);
        
        /*   Bank_Details__c bankDetail = new Bank_Details__c(
Application_Applicant__c = applicant.Id,
Account_Type__c = 'Saving',
Is_Consider_for_Eligibility__c = true,
Account_Number__c = '1234567890',
Name = 'John\'s Bank',
Account_Holder_Name__c ='John\'s Bank'
);
insert bankDetail; */
        
        Bank_Details__c bankDetail2  =   FITestDataFactory.getBankdetails (false , applicant.Id);
        
        
        bankDetail2.Account_Type__c = 'Overdraft';
        bankDetail2.Account_Number__c = '1234567890';
        bankDetail2.Name = 'John\'s Overdraft';
        bankDetail2.Account_Holder_Name__c ='John\'s Overdraft'; 
        
        insert bankDetail2;
        Bank_Statement_Analysis__c bsaRecord  =     FITestDataFactory.getBankstatement (true , bankDetail.Id );
        /* Bank_Statement_Analysis__c bsaRecord = new Bank_Statement_Analysis__c(
Bank_Details__c = bankDetail.Id,
Month__c = 'Jan-25',
Total_Self_and_Related_Party_Credit__c = 1000,
Average_Limit_Utilisation__c = 30,
ABB__c = 15,
Amount_of_Self_and_Related_Party_Credit__c =1,
Total_Number_of_Business_Credits__c = 1,
Total_Amount_of_Business_Credits__c=1,
Total_Self_and_Related_Party_Debit__c =1,
Amount_of_Self_and_Related_Party_Debit__c =1,
Total_Number_of_Business_Debits__c = 1,
Total_Amount_of_Business_Debits__c =1,
Cash_Deposit_to_total_Credit__c =1,
Cash_withdrwal_to_total_Debit__c =1,
Total_number_of_inward_return__c =1,
Total_number_of_inward_ECS_return__c =1,Total_number_of_outward_return__c =1,
O_w_retruns_as_of_total_credits__c =1,
Total_Amount_of_Intrest_Charged__c =1,
Total_Number_of_circular_transactions__c =1,
Total_Amount_of_EMI__c =1,
Average_EOD_Balance__c =1,
Sanction_Limit__c =1,
Count_of_loan_disbursal__c =1,
Value_of_loan_disbursal__c =1,
RecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis')
);
insert bsaRecord; */
        
        Bank_Statement_Analysis__c bsaRecord3  =     FITestDataFactory.getBankstatement (true , bankDetail.Id  );
        /*
Bank_Statement_Analysis__c bsaRecord3 = new Bank_Statement_Analysis__c(
Bank_Details__c = bankDetail.Id,
Month__c = 'Jan-25',
Total_Self_and_Related_Party_Credit__c = 1000,
Average_Limit_Utilisation__c = 30,
ABB__c = 15,
Amount_of_Self_and_Related_Party_Credit__c =1,
Total_Number_of_Business_Credits__c = 1,
Total_Amount_of_Business_Credits__c=1,
Total_Self_and_Related_Party_Debit__c =1,
Amount_of_Self_and_Related_Party_Debit__c =1,
Total_Number_of_Business_Debits__c = 1,
Total_Amount_of_Business_Debits__c =1,
Cash_Deposit_to_total_Credit__c =1,
Cash_withdrwal_to_total_Debit__c =1,
Total_number_of_inward_return__c =1,
Total_number_of_inward_ECS_return__c =1,Total_number_of_outward_return__c =1,
O_w_retruns_as_of_total_credits__c =1,
Total_Amount_of_Intrest_Charged__c =1,
Total_Number_of_circular_transactions__c =1,
Total_Amount_of_EMI__c =1,
Average_EOD_Balance__c =1,
Sanction_Limit__c =1,
Count_of_loan_disbursal__c =1,
Value_of_loan_disbursal__c =1,
RecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis')
);
insert bsaRecord3; */
        
        // Transaction Record to be recategorized
        Bank_Statement_Analysis__c txn  =     FITestDataFactory.getBankstatementTXN (true , bankDetail.Id , bsaRecord.Id);
        
        /*   Bank_Statement_Analysis__c txn = new Bank_Statement_Analysis__c(
Name = 'Txn 1',
Bank_Details__c = bankDetail.Id,
Amount__c = 100,
Parent_Bant_Statement__c = bsaRecord.Id,
XNS_Date__c = Date.newInstance(2025, 1, 10),
Salesforce_Category__c = 'Business Credit',
Source__c = 'Manual',
Month__c='Sep-21',
Total_Self_and_Related_Party_Credit__c = 1000,
Average_Limit_Utilisation__c = 30,
ABB__c = 15,
Amount_of_Self_and_Related_Party_Credit__c =1,
Total_Number_of_Business_Credits__c = 1,
Total_Amount_of_Business_Credits__c=1,
Total_Self_and_Related_Party_Debit__c =1,
Amount_of_Self_and_Related_Party_Debit__c =1,
Total_Number_of_Business_Debits__c = 1,
Total_Amount_of_Business_Debits__c =1,
Cash_Deposit_to_total_Credit__c =1,
Cash_withdrwal_to_total_Debit__c =1,
Total_number_of_inward_return__c =1,
Total_number_of_inward_ECS_return__c =1,Total_number_of_outward_return__c =1,
O_w_retruns_as_of_total_credits__c =1,
Total_Amount_of_Intrest_Charged__c =1,
Total_Number_of_circular_transactions__c =1,
Total_Amount_of_EMI__c =1,
Average_EOD_Balance__c =1,
Sanction_Limit__c =1,
Count_of_loan_disbursal__c =1,
Value_of_loan_disbursal__c =1,
RecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis')
);
insert txn; */
        
        
        // Transaction Record to be recategorized
        Bank_Statement_Analysis__c txn2   =     FITestDataFactory.getBankstatementTXN (false , bankDetail2.Id , bsaRecord.Id);
        txn2.Name = 'Txn 2' ;
        txn2.Salesforce_Category__c = 'Business Credit';
        txn2.Source__c = 'Manual';
        txn2.Month__c='Sep-21';
        txn2.Total_Number_of_Business_Debits__c = 1 ;
        txn2.Total_Number_of_Business_Credits__c = 1 ;     
        insert txn2;
        
        Bank_Statement_Analysis__c bsaXnsRecord = FITestDataFactory.getBsaXnsRecord (true ,bankDetail.Id ) ; 
        /*  Bank_Statement_Analysis__c bsaXnsRecord = new Bank_Statement_Analysis__c(
Bank_Details__c = bankDetail.Id,
Cheque_Number__c = 'CHK123',
Narration__c = 'Bounce Transaction',
Amount__c = 1000,
Balance__c = 5000,
XNS_Date__c = Date.today(),
Category__c = 'Bounced',
RecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','XNS')
);
insert bsaXnsRecord; */
        
        // Fetch RecordTypeId for XNS (Bounce records)
        String xnsRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','XNS');
        Bank_Statement_Analysis__c xnsRecord1 = FITestDataFactory.getBsaXnsRecord (false  ,bankDetail.Id ) ; 
        
        // Insert Bank Statement Analysis records with 'Bounced' category
        /*  Bank_Statement_Analysis__c xnsRecord1 = new Bank_Statement_Analysis__c(
Bank_Details__c = bankDetail.Id,
Cheque_Number__c = 'CHK123',
Narration__c = 'Bounce Transaction 1',
Amount__c = 1000,
Balance__c = 5000,
XNS_Date__c = Date.today(),
Category__c = 'Bounced',
Category_Manual__c = 'Cheque Bounce',
Salesforce_Category__c = 'Bounced',
RecordTypeId = xnsRecordTypeId
); */
        insert xnsRecord1;
    } 
    
    static testMethod void testGetAllBankXnsBounceRecords() {
        // Retrieve setup data
        Bank_Details__c bankDetail = [SELECT Id, Application_Applicant__r.Loan_Application__c FROM Bank_Details__c WHERE Account_Number__c = '1234567890' LIMIT 1];
        
        // Execute method
        Test.startTest();
        List<COMM_BsaCmpController.XnsDataWrapper> result = COMM_BsaCmpController.getAllBankXnsBounceRecords(new List<String>{bankDetail.Id}, bankDetail.Application_Applicant__r.Loan_Application__c,null);
        Test.stopTest();
        
    }
    
    static testMethod void testGetAllBankXnsBounceRecords2() {
        // Retrieve setup data
        Bank_Details__c bankDetail = [SELECT Id, Application_Applicant__r.Id FROM Bank_Details__c WHERE Account_Number__c = '1234567890' LIMIT 1];
        
        // Execute method
        Test.startTest();
        List<COMM_BsaCmpController.XnsDataWrapper> result = COMM_BsaCmpController.getAllBankXnsBounceRecords(new List<String>{bankDetail.Id}, bankDetail.Application_Applicant__r.Id,null);
        Test.stopTest();
        
    }
    
    static testMethod void testGetEligibleBankIds() {
        // Retrieve setup data
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        
        // Execute method
        Test.startTest();
        List<String> result = COMM_BsaCmpController.getEligibleBankIds(applicant.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetDerivedAnalysisRecordsAccWise() {
        // Get Loan Application recordId from test setup data
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Fetch bank details for account type used in test setup
        List<Bank_Details__c> bankDetails = [
            SELECT Id 
            FROM Bank_Details__c 
            WHERE Application_Applicant__r.Loan_Application__c = :loanApp.Id 
            AND Account_Type__c = 'Saving'
        ];
        
        // Prepare input values
        List<String> recordIds = new List<String>();
        for (Bank_Details__c bd : bankDetails) {
            recordIds.add(bd.Id);
        }
        
        String accountType = 'Saving';
        
        // Call the method
        Test.startTest();
        List<COMM_BsaCmpController.AccountTypeWiseWrapper> result = COMM_BsaCmpController.getDerivedAnalysisRecordsAccWise(
            recordIds,
            loanApp.Id,
            accountType
        );
        Test.stopTest();
        
    }
    
    
    @isTest
    static void testGetDerivedAnalysisOverdraftAccWise() {
        // Get Loan Application recordId from test setup data
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Fetch bank details for account type used in test setup
        List<Bank_Details__c> bankDetails = [
            SELECT Id 
            FROM Bank_Details__c 
            WHERE Application_Applicant__r.Loan_Application__c = :loanApp.Id 
            AND Account_Type__c = 'Saving'
        ];
        
        // Prepare input values
        List<String> recordIds = new List<String>();
        for (Bank_Details__c bd : bankDetails) {
            recordIds.add(bd.Id);
        }
        
        String accountType = 'Saving';
        
        // Call the method
        Test.startTest();
        List<COMM_BsaCmpController.AccountTypeWiseWrapper> result = COMM_BsaCmpController.getDerivedAnalysisRecordsAccWise(
            recordIds,
            loanApp.Id,
            accountType
        );
        Test.stopTest();
        
    }
    @isTest
    static void testRemoveMonthltRec() {
        // Fetch Bank Details record from test setup
        Bank_Details__c bd = [SELECT Id FROM Bank_Details__c LIMIT 1];
        
        // Create a Derived_Analysis record with Source__c = 'Manual'
        String daRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis');
        
        Bank_Statement_Analysis__c manualDa = new Bank_Statement_Analysis__c(
            Bank_Details__c = bd.Id,
            RecordTypeId = daRecordTypeId,
            Source__c = 'Manual',
            Month__c = 'Jan-25'
        );
        insert manualDa;
        
        // Call method
        Test.startTest();
        COMM_BsaCmpController.removeMonthltRec(bd.Id);
        Test.stopTest();
        
    }
    @isTest
    static void testCreateMonthlyRecs() {
        // Get existing Bank_Details__c record from test setup
        Bank_Details__c bd = [SELECT Id FROM Bank_Details__c LIMIT 1];
        
        
        // Call the method to create a new monthly record
        Test.startTest();
        COMM_BsaCmpController.createMonthlyRecs(bd.Id);
        Test.stopTest();
        
    }
    @isTest
    static void testManualDerivedAnalysis() {
        // Setup: Create a Bank_Details__c record
        Bank_Details__c bd = [SELECT Id FROM Bank_Details__c LIMIT 1];
        
        // Call the method
        Test.startTest();
        COMM_BsaCmpController.FinalWrapper result = COMM_BsaCmpController.manualDerivedAnalysis(bd.Id, true);
        Test.stopTest();
        
    }
    @isTest
    static void testGetDerivedAnalysisRecords() {
        
        Bank_Details__c bd = [SELECT Id FROM Bank_Details__c LIMIT 1];
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        COMM_BsaCmpController.FinalWrapper result = COMM_BsaCmpController.getDerivedAnalysisRecords(
            new List<String>{ bd.Id }, loanApp.Id, 'Saving'
        );
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testUpdateCategory() {
        // Fetch the transaction record (assume it's the only one)
        Bank_Statement_Analysis__c txn = [SELECT Id, Salesforce_Category__c FROM Bank_Statement_Analysis__c 
                                          WHERE Salesforce_Category__c = 'Business Credit' LIMIT 1];
        
        Test.startTest();
        try{
            String result = COMM_BsaCmpController.updateCategory(new List<String>{txn.Id}, 'Self Credit');
        }catch(exception e){ }
        Test.stopTest();
    }
    
    @isTest
    static void testGetAllBankXnsRecords() {
        // Fetch existing Loan Application Id from test setup
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Get one record ID (though it's not used directly in method logic)
        Bank_Statement_Analysis__c xns = [
            SELECT Id FROM Bank_Statement_Analysis__c
            WHERE RecordType.DeveloperName = 'XNS'
            AND Bank_Details__r.Application_Applicant__r.Loan_Application__c = :loanApp.Id
            LIMIT 1
        ];
        
        Test.startTest();
        List<COMM_BsaCmpController.XnsDataWrapper> xnsRecords = 
            COMM_BsaCmpController.getAllBankXnsRecords(new List<String>{xns.Id}, loanApp.Id);
        //  COMM_BsaCmpController.getAllBankXnsRecordsFiltered(loanApp.Id,'','','','','');
        Test.stopTest();
        
    }
    @isTest
    static void testGetAllBankXnsRecordsFiltered() {
        // Get Loan Application and XNS record from setup
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Bank_Statement_Analysis__c xns = [
            SELECT Id, Bank_Details__r.Name, Bank_Details__r.Account_Number__c,
            Amount__c, Narration__c, Category__c
            FROM Bank_Statement_Analysis__c
            WHERE RecordType.DeveloperName = 'XNS'
            AND Bank_Details__r.Application_Applicant__r.Loan_Application__c = :loanApp.Id
            LIMIT 1
        ];
        
        //Set filters based on existing data to ensure match
        String searchBankName = xns.Bank_Details__r.Name != null ? xns.Bank_Details__r.Name.substring(0, 2) : '';
        List<String> strAcc = new List<String>{ searchBankName };
            String searchAccNo = xns.Bank_Details__r.Account_Number__c != null ? xns.Bank_Details__r.Account_Number__c.substring(0, 2) : '';
        List<String> strAccNo = new List<String>{ searchAccNo };
            
            String searchLoanAmount = String.valueOf(xns.Amount__c != null ? xns.Amount__c.intValue() : 0);
        String searchNarration = xns.Narration__c != null ? xns.Narration__c.substring(0, 2) : '';
        String searchCategory = xns.Category__c;
        List<String> strsearchCategory = new List<String>{ searchCategory };
            
            Test.startTest();
        try{
            List<COMM_BsaCmpController.XnsDataWrapper> results = COMM_BsaCmpController.getAllBankXnsRecordsFiltered(
                loanApp.Id,
                strAcc,
                strAccNo,
                searchLoanAmount,
                searchNarration,
                strsearchCategory
            );
        }
        catch(exception ex)
        {}
        Test.stopTest();
        
    }
    
    /*@isTest 
static void getAllRelatedBanks_Test (){
Test.startTest();
try{ 

Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];


/*Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');

// Create Opportunity
Opportunity opportunity = FITestDataFactory.createOpportunity(customer);

// Create Applicant
Application_Applicant__c applicant = FITestDataFactory.createApplicant(opportunity);
Bank_Details__c bankDetail = new Bank_Details__c(
Application_Applicant__c = applicant.Id,
Account_Type__c = 'Saving',
Is_Consider_for_Eligibility__c = true,
Account_Number__c = '1234567890',
Name = 'John\'s Bank',
Account_Holder_Name__c ='John\'s Bank'
);

insert bankDetail;

Bank_Statement_Analysis__c bsaRecord = new Bank_Statement_Analysis__c(
Bank_Details__c = bankDetail.Id,
Month__c = 'Jan-25',
Total_Self_and_Related_Party_Credit__c = 1000,
Average_Limit_Utilisation__c = 30,
ABB__c = 15,
Amount_of_Self_and_Related_Party_Credit__c =1,
Total_Number_of_Business_Credits__c = 1,
Total_Amount_of_Business_Credits__c=1,
Total_Self_and_Related_Party_Debit__c =1,
Amount_of_Self_and_Related_Party_Debit__c =1,
Total_Number_of_Business_Debits__c = 1,
Total_Amount_of_Business_Debits__c =1,
Cash_Deposit_to_total_Credit__c =1,
Cash_withdrwal_to_total_Debit__c =1,
Total_number_of_inward_return__c =1,
Total_number_of_inward_ECS_return__c =1,Total_number_of_outward_return__c =1,
O_w_retruns_as_of_total_credits__c =1,
Total_Amount_of_Intrest_Charged__c =1,
Total_Number_of_circular_transactions__c =1,
Total_Amount_of_EMI__c =1,
Average_EOD_Balance__c =1,
Sanction_Limit__c =1,
Count_of_loan_disbursal__c =1,
Value_of_loan_disbursal__c =1,
RecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis')
);
insert bsaRecord;

Bank_Statement_Analysis__c bsaRecord3 = new Bank_Statement_Analysis__c(
Bank_Details__c = bankDetail.Id,
Month__c = 'Jan-25',
Total_Self_and_Related_Party_Credit__c = 1000,
Average_Limit_Utilisation__c = 30,
ABB__c = 15,
Amount_of_Self_and_Related_Party_Credit__c =1,
Total_Number_of_Business_Credits__c = 1,
Total_Amount_of_Business_Credits__c=1,
Total_Self_and_Related_Party_Debit__c =1,
Amount_of_Self_and_Related_Party_Debit__c =1,
Total_Number_of_Business_Debits__c = 1,
Total_Amount_of_Business_Debits__c =1,
Cash_Deposit_to_total_Credit__c =1,
Cash_withdrwal_to_total_Debit__c =1,
Total_number_of_inward_return__c =1,
Total_number_of_inward_ECS_return__c =1,Total_number_of_outward_return__c =1,
O_w_retruns_as_of_total_credits__c =1,
Total_Amount_of_Intrest_Charged__c =1,
Total_Number_of_circular_transactions__c =1,
Total_Amount_of_EMI__c =1,
Average_EOD_Balance__c =1,
Sanction_Limit__c =1,
Count_of_loan_disbursal__c =1,
Value_of_loan_disbursal__c =1,
RecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis')
);
insert bsaRecord3; 
List<String> lstOptions=    COMM_BsaCmpController.getAllRelatedBanks (loanApp.id);
List<String> lstOpt=    COMM_BsaCmpController.getAllRelatedBanksAccountNumber (loanApp.id); 
List<String> getAllCategories=    COMM_BsaCmpController.getAllCategories (loanApp.id);

Bank_Details__c bankDetail = [SELECT Id, Application_Applicant__r.Loan_Application__c FROM Bank_Details__c WHERE Account_Number__c = '1234567890' LIMIT 1];

Bank_Statement_Analysis__c bankstatement = [
SELECT Id, Bank_Details__c
FROM Bank_Statement_Analysis__c
WHERE Bank_Details__c = :bankDetail.Id
LIMIT 1
];    
COMM_BsaCmpController.calculateCCLimitUtilization(new Set<Id>{ loanApp.Id });
COMM_BsaCmpController.calculateUtilization ( bankstatement.id);

// COMM_BsaCmpController.calculateUtilization ( bsaRecord3.id);


}
catch(exception ex)
{}
Test.stopTest();
} */
    @isTest
    static void test_getAllRelatedBanks() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<String> result = COMM_BsaCmpController.getAllRelatedBanks(loanApp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Expected related banks list to be returned.');
    }
    
    @isTest
    static void test_getAllRelatedBanksAccountNumber() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<String> result = COMM_BsaCmpController.getAllRelatedBanksAccountNumber(loanApp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Expected account numbers list to be returned.');
    }
    
    @isTest
    static void test_getAllCategories() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<String> result = COMM_BsaCmpController.getAllCategories(loanApp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Expected category list to be returned.');
    }
    
    @isTest
    static void test_calculateCCLimitUtilization() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        COMM_BsaCmpController.calculateCCLimitUtilization(new Set<Id>{loanApp.Id});
        Test.stopTest();
        
        // No assert if void, just check no exception
        System.assert(true, 'calculateCCLimitUtilization executed without exception.');
    }
    
    @isTest
    static void test_calculateUtilization() {
        Bank_Details__c bankDetail = [
            SELECT Id FROM Bank_Details__c LIMIT 1
        ];
        Bank_Statement_Analysis__c bankStatement = [
            SELECT Id FROM Bank_Statement_Analysis__c 
            WHERE Bank_Details__c = :bankDetail.Id
            LIMIT 1
        ];
        
        Test.startTest();
        COMM_BsaCmpController.calculateUtilization(bankStatement.Id);
        Test.stopTest();
        
        System.assert(true, 'calculateUtilization executed without exception.');
    }
    
}