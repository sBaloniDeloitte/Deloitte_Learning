@isTest
public class EmiTrackingCmpControllerTest {

    @testSetup
    static void setupData() {
        Opportunity opp = TestDataFactory.createLoanApplicationRecord(
            'New', 'Affordable Home Loan', 'PSV', Date.today().addDays(30)
        );
        insert opp;

        Application_Applicant__c applicant = TestDataFactory.createApplicationApplicant(
            'Primary Applicant', opp.Id, 'Ria Goel', 'ABCDE1234F', Date.newInstance(1990, 1, 1)
        );
        insert applicant;

       List<Bank_Branch_Master__c> bank = TestDataFactory.getTestBankBranchMasterData(1, true);
        List<Bank_Details__c> bankDetail = TestDataFactory.getTestBankDetailsData(2,applicant.Id,bank[0].Id,true);
        List<Bank_Statement_Analysis__c> bsaRecord = TestDataFactory.getTestBankStatementAnalysisData(1, NULL,bankDetail[0].Id, false);
        bsaRecord[0].Emi_Date__c = Date.today().addMonths(12);
        bsaRecord[0].Category__c = 'Loan';
        bsaRecord[0].Amount__c = 1000000;

        insert bsaRecord;

    }

    @isTest
    static void testGetEligibleBankIds() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Bank_Details__c> result = EmiTrackingCmpController.getEligibleBankIds(loanApp.Id);
        System.assertNotEquals(0, result.size(), 'Should return bank details linked to applicants');
    }

    @isTest
    static void testGetTransposedData() {
        
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Id eligibilityRT = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c', 'Eligibility_Input');

        Bank_Branch_Master__c bankMaster = new Bank_Branch_Master__c(
            Name = 'HDFC',
            Bank_Name__c = 'HDFC Bank',
            Branch_Name__c = 'Kolkata',
            MICR__c = '123456789',
            Branch_Location__c = 'Test City'
        );
        insert bankMaster;
    
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = loanApp.Id,
            Applicant_Type__c = 'Primary Applicant'
        );
        insert applicant;
    
        Bank_Details__c bankDetail = new Bank_Details__c(
            Application_Applicant__c = applicant.Id,
            Account_Holder_Name__c = 'Test User',
            Account_Number__c = '1234567890',
            Account_Type__c = 'Saving',
            Is_Repayment_Account__c = true,
            Bank_Master__c = bankMaster.Id
        );
        insert bankDetail;
            
            Bank_Statement_Analysis__c eligibilityRec = new Bank_Statement_Analysis__c(
                Loan_Application__c = loanApp.Id,
                RecordTypeId = eligibilityRT,
                Minimum_Credit_Count__c = 3,
                Bank_Details__c =bankDetail.Id,
                Emi_Date__c = Date.newInstance(2025, 12, 9)
            );
            insert eligibilityRec;
        
        
        // System.assertNotEquals(0, result.size(), 'Should return transposed EMI data');
        // System.assert(result[0].containsKey('Amount'), 'Each row should contain Amount');
        // System.assert(result[0].containsKey('Category'), 'Each row should contain Category');
    }
    @isTest
    static void testgetMonthNameJan(){
        String res = EmiTrackingCmpController.getMonthName(1);
    }
    @isTest
    static void testgetMonthNameFeb(){
        String res = EmiTrackingCmpController.getMonthName(2);
    }
    @isTest
    static void testgetMonthNameMar(){
        String res = EmiTrackingCmpController.getMonthName(3);
    }
    @isTest
    static void testgetMonthNameApr(){
        String res = EmiTrackingCmpController.getMonthName(4);
    }
    @isTest
    static void testgetMonthNameMay(){
        String res = EmiTrackingCmpController.getMonthName(5);
    }
    @isTest
    static void testgetMonthNameJune(){
        String res = EmiTrackingCmpController.getMonthName(6);
    }
    @isTest
    static void testgetMonthNameJuly(){
        String res = EmiTrackingCmpController.getMonthName(7);
    }
    @isTest
    static void testgetMonthNameAug(){
        String res = EmiTrackingCmpController.getMonthName(8);
    }
    @isTest
    static void testgetMonthNameSep(){
        String res = EmiTrackingCmpController.getMonthName(9);
    }
    @isTest
    static void testgetMonthNameOct(){
        String res = EmiTrackingCmpController.getMonthName(10);
    }
    @isTest
    static void testgetMonthNameNov(){
        String res = EmiTrackingCmpController.getMonthName(11);
    }
    @isTest
    static void testgetMonthNameDec(){
        String res = EmiTrackingCmpController.getMonthName(12);
    }

    @isTest
    static void testGetFilteredTransposedData() {
        Bank_Details__c bank = [SELECT Id FROM Bank_Details__c LIMIT 1];
        Test.startTest();
        List<Map<String, String>> result = EmiTrackingCmpController.getFilteredTransposedData(bank.Id);
        Test.stopTest();
        System.assertNotEquals(0, result.size(), 'Should return filtered transposed EMI data');
        System.assert(result[0].containsKey('Amount'), 'Each row should contain Amount');
        System.assert(result[0].containsKey('Category'), 'Each row should contain Category');
    }
}