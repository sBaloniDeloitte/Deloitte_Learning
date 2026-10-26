@isTest
public class Sales_LoanLoginDetailsControllerTest {
    @testSetup
    static void setupData() {
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        Application_Verification__c appVer = new Application_Verification__c();
        appVer.Stage__c = 'Draft';
        appVer.Loan_Application__c = loan.Id;
        insert appVer;
        Id screenRecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Screen' AND SObjectType = 'Screen_Field__c' LIMIT 1].Id;
        // Create test Screen_Field__c records
        List<Screen_Field__c> screenFields = new List<Screen_Field__c>{
            new Screen_Field__c(
                Screen_Name__c = 'Get Customer Consent',
                Applicable_Login_Stage__c = 'Basic Info Capture Stage',
                Form_Name__c = 'Login Checklist',
                Is_Screen_Active__c = true,
                Applicable_For__c = 'Both',
                RecordTypeId = screenRecordTypeId,
                Master_Screen_Sequence__c = 1,
                Master_Screen_Name__c ='Additional Information',
                Screen_Sequence__c = 1
                ),
            new Screen_Field__c(
                Screen_Name__c = 'Validate PAN',
                Applicable_Login_Stage__c = 'Pan Capture Stage',
                Form_Name__c = 'Loan Application Login Form',
                Is_Screen_Active__c = true,
                Applicable_For__c = 'Both',
                RecordTypeId = screenRecordTypeId,
                Master_Screen_Sequence__c = 2,
                Master_Screen_Name__c ='Additional Information',
                Screen_Sequence__c = 2
                ),
              new Screen_Field__c(
                Screen_Name__c = 'Validate PAN',
                Applicable_Login_Stage__c = 'Aadhar Capture Stage',
                Form_Name__c = 'Loan Application Login Form',
                Is_Screen_Active__c = true,
                Applicable_For__c = 'Both',
                RecordTypeId = screenRecordTypeId,
                Master_Screen_Sequence__c = 3,
                Master_Screen_Name__c ='PAN/Form 60 Details',
                Screen_Sequence__c = 3
                )
        };
        insert screenFields;

    }

    @isTest
    static void testGetSubStageList() {
        Opportunity testLoan = [SELECT Id FROM Opportunity LIMIT 1];
		Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Loan_Application__c=:testLoan.Id LIMIT 1];
        Test.startTest();
        List<Sales_LoanLoginDetailsController.SubStageWrapper> result = Sales_LoanLoginDetailsController.getSubStageList(testLoan.Id, 'Basic Info Capture Stage');
       
        Test.stopTest();
        

    }

    @isTest
    static void testGetPrimaryApplicantList() {
        Opportunity testLoan = [SELECT Id FROM Opportunity LIMIT 1];
		Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Loan_Application__c=:testLoan.Id LIMIT 1];
        Test.startTest();
        List<Sales_LoanLoginDetailsController.ApplicantWrapper> result = Sales_LoanLoginDetailsController.getPrimaryApplicantList(testLoan.Id, 'Basic Info Capture Stage');
        app.Pan_OCR_Confirmed__c=true;
        update app;
          Sales_LoanLoginDetailsController.getPrimaryApplicantList(testLoan.Id, 'Aadhar Capture Stage');
        try{
        Sales_LoanLoginDetailsController.getPrimaryApplicantList('1w2wee', 'test');
        }catch(exception e){}
        Test.stopTest();

    }
    
    @isTest
    static void testGetPrimaryApplicantList1() {
        Opportunity testLoan = [SELECT Id FROM Opportunity LIMIT 1];
		Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Loan_Application__c=:testLoan.Id LIMIT 1];
        Test.startTest();
        //List<Sales_LoanLoginDetailsController.ApplicantWrapper> result = Sales_LoanLoginDetailsController.getPrimaryApplicantList(testLoan.Id, 'Basic Info Capture Stage');
        List<Sales_LoanLoginDetailsController.ApplicantWrapper> result1 = Sales_LoanLoginDetailsController.getPrimaryApplicantList(testLoan.Id, 'Aadhar Capture Stage');
        app.Pan_OCR_Confirmed__c=true;
        update app;
          Sales_LoanLoginDetailsController.getPrimaryApplicantList(testLoan.Id, 'Aadhar Capture Stage');
        try{
        Sales_LoanLoginDetailsController.getPrimaryApplicantList('1werwerwerwer324232wee', 'test');
        }catch(exception e){}
        Test.stopTest();

    }
    
    
    @isTest
    static void testGetNextScreenDetails() {
        // Create test Screen_Field__c record for Loan Login Form
        Screen_Field__c screen = new Screen_Field__c(
            Form_Name__c = 'Loan Login Form',
            Is_Active__c = TRUE,
            Is_Screen_Active__c = TRUE,
            Master_Screen_Name__c = 'NextScreen',
            Screen_Sequence__c = 2
        );
        insert screen;

        Test.startTest();
        String result = Sales_LoanLoginDetailsController.getNextScreenDetails('1', 'Screen1', 'Loan Login Form');
        
        //Sales_LoanLoginDetailsController.getNextScreenDetails(null, null, null);
        Test.stopTest();
        
        System.assertEquals('NextScreen', result, 'Should return the correct next screen name');
    }
    
     // Test method to cover catch block in getPrimaryApplicantList
    @IsTest
    static void testGetPrimaryApplicantList_Exception() {
        Test.startTest();
        try {
            // Passing null LoanId to cause a query failure and trigger exception
            List<Sales_LoanLoginDetailsController.ApplicantWrapper> applicants = 
                Sales_LoanLoginDetailsController.getPrimaryApplicantList('testloadid', 'Stage 1');
            //System.assert(false, 'Expected an exception but none was thrown.');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('unexpected token'), 'Exception should be caught and handled.');
        }
        Test.stopTest();
    }

    // Test method to cover catch block in getNextScreenDetails
    @IsTest
    static void testGetNextScreenDetails_Exception() {
        Test.startTest();
        try {
            // Passing a non-numeric currentAppSeq to cause an exception
            String nextScreen = Sales_LoanLoginDetailsController.getNextScreenDetails('ABC', 'Personal Details', 'Loan Login Form');
           // System.assert(false, 'Expected an exception but none was thrown.');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('invalid integer'), 'Exception should be caught and handled.');
        }
        Test.stopTest();
    }
    
}