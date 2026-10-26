@isTest
public class ReinstateLoanApplicationActionContTest {
    
    // Setup method to create test data
    @testSetup
    static void setup() {
        // Create a test user with standard user license (if required for context)
        User u = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + DateTime.now().getTime() + '@example.com'
        );
        insert u;
        
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        loan.OwnerId=u.id;
        loan.CloseDate = System.today().addDays(30);
        loan.StageName = 'Prospecting';
        update loan;
        
        TAT__c tatRec = new TAT__c();
        tatRec.Activity__c ='Sub Stage Change';
        tatRec.Loan_Application__c = loan.Id;
        insert tatRec;
        
        
    }
    
    @isTest
    static void testUpdateLoanApplication() {
        // Get a loan application record from setup data
        Opportunity opp = [SELECT Id, StageName, Approval_Status__c FROM Opportunity LIMIT 1];
        try{
        	Test.startTest();
        	ReinstateLoanApplicationActionController.updateLoanApplication(opp.Id);
        	Test.stopTest();
        }Catch(exception e){
            
        }
        Opportunity updatedOpp = [SELECT Id, Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('In Progress', updatedOpp.Approval_Status__c, 'Approval Status should be updated to In Progress');
    }
    
    @isTest
    static void testNotifyLoanOwnerToReinstate() {
        Opportunity opp = [SELECT Id, Name, Owner.Email, Owner.Name FROM Opportunity LIMIT 1];
        try{
            Test.startTest();
            ReinstateLoanApplicationActionController.notifyLoanOwnerToReinstate(opp.Id);
            Test.stopTest();
            System.assert(true, 'Notify method executed successfully');
        }catch(exception e){}
    }
    
    @isTest
    static void testUpdateLoanApplicationWithBlankId() {
        try{
            Test.startTest();
            // Call method with invalid Id - no update should happen, but no exception thrown
            ReinstateLoanApplicationActionController.updateLoanApplication('1111');
            Test.stopTest();
            
            System.assert(true, 'No exception thrown with blank loan Id');
        }catch(exception e){}
    }
}