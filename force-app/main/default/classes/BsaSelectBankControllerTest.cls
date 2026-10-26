@isTest
public class BsaSelectBankControllerTest {

    @testSetup
    static void setupData() {
        // Create a Loan Application
        Opportunity loanApp = new Opportunity(
            Name = 'Test Loan Application',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(10),
			Product__c = 'Affordable Home Loan' 
        );
        insert loanApp;

        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = loanApp.Id
        );
        insert applicant;
   Id bankAanalysis = Schema.SObjectType.Bank_Statement_Analysis__c.getRecordTypeInfosByName().get('Derived Analysis').getRecordTypeId();

        // Create Bank Details
        List<Bank_Details__c> banks = new List<Bank_Details__c>{
            new Bank_Details__c(
                Name = 'Bank A',
               
                Account_Holder_Name__c = 'Bank A',
                Application_Applicant__c = applicant.Id,
                Account_Number__c = '123456',
                Account_Type__c = 'Saving',
                Is_Disbursal_Account__c = false,
                Is_Repayment_Account__c = false,
                Is_Consider_for_Eligibility__c = true
            ),
            new Bank_Details__c(
                Name = 'Bank B',
                Account_Holder_Name__c = 'Bank A',
                Application_Applicant__c = applicant.Id,
                Account_Number__c = '789012',
                Account_Type__c = 'Current',
                Is_Disbursal_Account__c = false,
                Is_Repayment_Account__c = false,
                Is_Consider_for_Eligibility__c = true
            )
        };
        insert banks;
        
           Bank_Statement_Analysis__c txn = new Bank_Statement_Analysis__c(
            Name = 'Txn 1',
            Bank_Details__c = banks[0].Id,
            Amount__c = 100,
            XNS_Date__c = Date.newInstance(2025, 1, 10),
            Salesforce_Category__c = 'Business Credit',
               Total_Number_of_Business_Debits__c = 1,
               Total_Number_of_Business_Credits__c = 1
        );
        insert txn;
        
          Bank_Statement_Analysis__c bsaRecord = new Bank_Statement_Analysis__c(
            Bank_Details__c = banks[0].Id,
            Month__c = 'Jan-25',
              Parent_Bant_Statement__c = txn.Id,
            Total_Self_and_Related_Party_Credit__c = 1000,
            Average_Limit_Utilisation__c = 30,
            ABB__c = 15,
            RecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis'),
              Total_Number_of_Business_Debits__c = 1,
              Total_Number_of_Business_Credits__c = 1
        );
        insert bsaRecord;
        
        // Transaction Record to be recategorized
     

        Bank_Statement_Analysis__c bsaXnsRecord = new Bank_Statement_Analysis__c(
            Bank_Details__c = banks[0].Id,
            Cheque_Number__c = 'CHK123',
            Narration__c = 'Bounce Transaction',
            Amount__c = 1000,
            Balance__c = 5000,
            XNS_Date__c = Date.today(),
            Category__c = 'Bounced',
            RecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','XNS'),
            Total_Number_of_Business_Debits__c = 1,
            Total_Number_of_Business_Credits__c = 1
        );
        insert bsaXnsRecord;
        
        // Fetch RecordTypeId for XNS (Bounce records)
    String xnsRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','XNS');

    // Insert Bank Statement Analysis records with 'Bounced' category
    Bank_Statement_Analysis__c xnsRecord1 = new Bank_Statement_Analysis__c(
        Bank_Details__c = banks[0].Id,
        Cheque_Number__c = 'CHK123',
        Narration__c = 'Bounce Transaction 1',
        Amount__c = 1000,
        Balance__c = 5000,
        XNS_Date__c = Date.today(),
        Category__c = 'Bounced',
        Category_Manual__c = 'Cheque Bounce',
        Salesforce_Category__c = 'Bounced',
        RecordTypeId = xnsRecordTypeId,
        Total_Number_of_Business_Debits__c = 1,
        Total_Number_of_Business_Credits__c = 1
    );
    insert xnsRecord1;

        
        
    }

    @isTest
    static void testGetAllBankRecords() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Bank_Details__c> result = BsaSelectBankController.getAllBankRecords(loanApp.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Expected bank records but got null');
       // System.assertEquals(2, result.size(), 'Should return 2 bank records');
    }

    @isTest
    static void testSelectDefault_Disbursal() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Bank_Details__c> banks = [SELECT Id FROM Bank_Details__c];

        Test.startTest();
        String result = BsaSelectBankController.selectDefault(loanApp.Id, banks[0].Id, 'Is_Disbursal_Account__c', true);
        String result1 = BsaSelectBankController.selectDefault(loanApp.Id, banks[1].Id, 'Is_Repayment_Account__c', true);

        Test.stopTest();

        System.assertEquals('success', result);
        Bank_Details__c updatedBank = [SELECT Is_Disbursal_Account__c FROM Bank_Details__c WHERE Id = :banks[0].Id];
        System.assertEquals(true, updatedBank.Is_Disbursal_Account__c);
    
    }
	@istest
    static void testSelectDefault_Eligibility() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Bank_Details__c> banks = [SELECT Id FROM Bank_Details__c];
        
        Id obligationRecordTypeId = Schema.SObjectType.Income_Expense_Obligation__c.getRecordTypeInfosByName().get('Income Expense & Obligation').getRecordTypeId();
		Income_Expense_Obligation__c testObli = new Income_Expense_Obligation__c();
        testObli.RecordTypeId = obligationRecordTypeId;
        testObli.Type__c = 'Obligation';
        testObli.IsParent__c = true;
        testObli.Loan_Application__c = loanApp.id;
        insert testObli;
        Test.startTest();
        String result = BsaSelectBankController.selectDefault(loanApp.Id, banks[0].Id, 'Is_Consider_for_Eligibility__c', true);
        Test.stopTest();

        System.assertEquals('success', result);
        Bank_Details__c updatedBank = [SELECT Is_Consider_for_Eligibility__c FROM Bank_Details__c WHERE Id = :banks[0].Id];
        System.assertEquals(true, updatedBank.Is_Consider_for_Eligibility__c);


    }

	 @isTest
   static void testCalculateEligibilityParam() {

        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];

        // Get or create RecordTypes
        Id derivedRT = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c', 'Derived_Analysis');
        Id eligibilityRT = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c', 'Eligibility_Input');
		Application_Applicant__c loanApplicant = [SELECT Id from Application_Applicant__c LIMIT 1];
        // Create Bank Details (lookup for BSA)
        Bank_Details__c bankDetail = new Bank_Details__c(
            Name = 'Test Bank',
            Application_Applicant__c = loanApplicant.Id,  // adjust if Applicant object is separate
            Is_Consider_for_Eligibility__c = true,
			Account_Holder_Name__c = 'Test Name'
        );
        insert bankDetail;

		Bank_Statement_Analysis__c eligibilityBSA = new Bank_Statement_Analysis__c(
            RecordTypeId = eligibilityRT,
            Loan_Application__c = loanApp.Id
        );
        insert eligibilityBSA;

        // Derived Analysis records
        Bank_Statement_Analysis__c derivedBSA = new Bank_Statement_Analysis__c(
            RecordTypeId = derivedRT,
            Bank_Details__c = bankDetail.Id,
            ABB__c = 100,
            Total_Number_of_Business_Credits__c = 5,
            Total_Number_of_Business_Debits__c = 10,
            Total_number_of_inward_Cheque_return__c = 2,
            Total_number_of_out_bounce__c = 1,
            Total_Amount_of_Business_Credits__c = 5000,
            Average_EOD_Balance__c = 200,
            Average_Limit_Utilisation__c = 50,
            Month__c = '202501',  // adjust format as per your org
            Parent_Bant_Statement__c = eligibilityBSA.id
        );
        insert derivedBSA;

        Test.startTest();
        String result = BsaSelectBankController.calculateEligibilityParam(loanApp.Id);
        Test.stopTest();
    }


       
    @isTest
    static void testGetEligibleRecord_found() {

  		Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Id eligibilityRT = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c', 'Eligibility_Input');

        Bank_Statement_Analysis__c eligibilityRec = new Bank_Statement_Analysis__c(
            Loan_Application__c = loanApp.Id,
            RecordTypeId = eligibilityRT,
            Minimum_Credit_Count__c = 3
        );
        insert eligibilityRec;
        
        Test.startTest();
        Bank_Statement_Analysis__c result = BsaSelectBankController.getEligibleRecord(loanApp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Eligibility record should be returned');
        System.assertEquals(3, result.Minimum_Credit_Count__c);
    }
    
    @isTest
    public static void testGetAccountTypePicklistValues() {
        Test.startTest();
        List<String> result = BsaSelectBankController.getAccountTypePicklistValues();
        Test.stopTest();
    
        System.assertNotEquals(null, result, 'Picklist result should not be null');
        System.assert(result.size() > 0, 'Picklist must contain at least one value');
    }

}