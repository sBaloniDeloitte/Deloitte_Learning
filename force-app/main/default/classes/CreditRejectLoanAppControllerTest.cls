@isTest
public class CreditRejectLoanAppControllerTest {

    @testSetup
    static void setupData() {
        // Create a user (for field history tracking)
        Profile prof = [SELECT Id FROM Profile WHERE Name ='Standard User'];
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            Phone ='9967564534',
            MobilePhone ='9967564534',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'testuser' + DateTime.now().getTime() + '@test.com'
        );
        insert u;
        Id maindrt = Utility.getRecordTypeIdByDeveloperName('Product2','Product');
 Id prodrt = Utility.getRecordTypeIdByDeveloperName('Product2','Variant');
        Product2 grandparent = new Product2(
    Name = 'Affordable Home Loan',
    Description = 'Business Loan Description',
    RecordTypeId = maindrt
);
insert grandparent;
        
        Product2 parent = new Product2(
    Name = 'Intermediate Product',
    Description = 'Intermediate Description',
    RecordTypeId = prodrt,
    Product__c = grandparent.Id // Custom lookup to Product2
);
insert parent;
        // Create a Product2
        Product2 prod = new Product2(Name = 'Business Loan', Description = 'Product Desc',RecordTypeId = prodrt,Product__c = parent.Id );
        insert prod;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Product__c = 'Home Loan',
            Approval_Status__c = 'Hard Rejected'
            //Reasons_for_Rejecting_Loan__c = null,
            //Detailed_Rejection_Reason__c = null
        );
        insert opp;

        // Attach Product to Loan via custom field
        grandparent.Loan_Application__c = opp.Id;
        grandparent.Product_Type__c = 'Parent';
        update grandparent;

        // Create related Customer record
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account acc = new Account(Name = 'Test Account', RecordTypeId = customerRecordTypeId);
        insert acc;

        // Account acc = new Account(Name = 'Test Account');
        // insert acc;

        // Create Application_Applicant__c
        Application_Applicant__c app = new Application_Applicant__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Applicant_Type__c = 'Primary Applicant',
            Customer__c = acc.Id,
            Loan_Application__c = opp.Id,
            Customer_Type__c = 'Individual',
            Mobile_Number__c = '9999999999',
            Email__c = 'john@example.com',
            Salutation__c = 'Mr.'
        );
        insert app;

    }

    @isTest
    static void testGetRejectionReasons() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Rejection_Reason_Mapping__mdt > softRejectMetadata = [
                                                                        SELECT Rejection_Reasons__c, Rejection_Status__c
                                                                        FROM Rejection_Reason_Mapping__mdt 
                                                                        WHERE Rejection_Status__c = 'Soft Rejected 1'
                                                                    ];
        Test.startTest();
        List<String> reasons = CreditRejectLoanApplicationController.getRejectionReasons();
        System.assertNotEquals(null, reasons);
        Test.stopTest();
    }

    @isTest
    static void testRejectLoanHardRejection() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
       
List<String> rList= new List<String>{'Credit Referred'};
        Test.startTest();
        try{
        	CreditRejectLoanApplicationController.rejectLoan(opp.Id,rList , 'Detailed Reason for Rejection');
            
        }catch(Exception e){ }
        Test.stopTest();
    }

    @isTest
    static void testRejectLoanSoftRejection() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Rejection_Reason_Mapping__mdt > softRejectMetadata = [
    SELECT Rejection_Reasons__c, Rejection_Status__c
    FROM Rejection_Reason_Mapping__mdt 
    WHERE Rejection_Status__c = 'Soft Rejected 1'
];
	List<String> rList= new List<String>{'Customer Cancel - Customer Not Responding'};
List<String> rList1= new List<String>{'Pan of the co-applicant'};
        Test.startTest();
        try{
        String result = CreditRejectLoanApplicationController.rejectLoan(opp.Id,rList , 'Some soft rejection reason');
        //CreditRejectLoanApplicationController.rejectLoan(opp.Id,rList1 , 'Detailed Reason for Rejection');
        System.assertEquals('success', result);
        }catch(Exception e){ 
        
}
        Test.stopTest();
        
    }

    @isTest
    static void testRejectLoanException() {
        Test.startTest();
        try {
            CreditRejectLoanApplicationController.rejectLoan(null, null, null);
            System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        }
        Test.stopTest();
    }

    @isTest
    static void testFetchComments() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        // Create field history tracking
 		opp.Approval_Status__c = 'Soft Rejected 1';
        opp.Name='testing';
        update opp;
        
        String oppField = opp.Approval_Status__c;
        
        OpportunityFieldHistory OFH = new OpportunityFieldHistory();
        OFH.OpportunityId = opp.Id;
        OFH.Field = 'Approval_Status__c';
        insert OFH;
        
        Test.startTest();
        List<CreditRejectLoanApplicationController.CommentsWrapper> comments = CreditRejectLoanApplicationController.fetchComments(opp.Id);
        String comments1 = CreditRejectLoanApplicationController.getApprovalStatus(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, comments);
    }
}