@isTest
public class LegalTriggerImplementationTest {
    
    @testSetup static void setupData(){
        Account acc = TestDataFactory.getTestAccounts(1, 'Customer', false)[0];
        insert acc;
        Opportunity oppRec = TestDataFactory.createLoanApplicationRecord('Loan Account Created', 'Home Loan', 'Sales Login', Date.today());
        insert oppRec;
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, oppRec.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = oppRec.Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        applicant.Customer__c = acc.Id;
        insert applicant;
    }
    
    @isTest static void addAndUpdateStageTATRecordsTest(){
        Opportunity oppRec = [Select id from Opportunity LIMIT 1];
        
        Legal__c legalObj = FITestDataFactory.returnLegalRecord(oppRec.Id,true);
        List<Id> lstOfIds = new List<Id>{legalObj.Id};
        LegalTriggerImplementation.addAndUpdateStageTATRecords(lstOfIds,'insert');
        LegalTriggerImplementation.addAndUpdateStageTATRecords(lstOfIds,'update');
    }
}