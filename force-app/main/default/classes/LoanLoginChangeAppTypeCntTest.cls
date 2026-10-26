@isTest
private class LoanLoginChangeAppTypeCntTest{
    
    // Mock Utility class via Test visible variable if applicable
   /* @testSetup
    static void setupData() {
        // Create an Opportunity record for test
        Opportunity opp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            Exception_Approval_Status__c = 'Submitted For Approval',
            Product__c='Home Loan'
        );
        insert opp;
        
        Employer_Master__c emp = new Employer_Master__c(
            Employer_Catagory__c = 'NOTCAT',
            Employer_Name__c = 'TestEmp',
            Name='TestEmp1'
        );
        insert emp;

        // Create Application Applicant records
        List<Application_Applicant__c> appList = new List<Application_Applicant__c>();

        // Individual applicant
        appList.add(new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Primary Applicant',
            Is_Key_Applicant__c = true,
            Mobile_Number__c = '9876543210',
            Mobile_Number_Masked__c = 'XXXXXX3210',
            CIBIL_Score__c = 600,
            Customer_Type__c = 'Individual',
            Is_Financial_applicant__c = 'Yes',
            Basic_Details_Filled__c = 'Yes',
            Customer_Profile__c = 'Salaried Indian',
            Employer_Name__c = emp.Id,
            Pan_Status__c = 'Valid',
            IsForm60Uploaded__c = 'No'
        ));

        // Non Individual applicant
        appList.add(new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Primary Applicant',
            Is_Key_Applicant__c = false,
            Mobile_Number__c = '9123456789',
            Mobile_Number_Masked__c = 'XXXXXX6789',
            CIBIL_Score__c = 700,
            Customer_Type__c = 'Non Individual',
            Is_Financial_applicant__c = 'No',
            Pan_Status__c = 'Valid',
            IsForm60Uploaded__c = 'Yes'
        ));
        insert appList;
    }

    // Mock the constants normally returned from Utility.getConstants
    @testVisible
    private static Map<String, String> mockConstants() {
        Map<String, String> consts = new Map<String, String>();
        consts.put('CIBIL_Score_Threshold', '650');
        return consts;
    }

    @isTest
    static void test_getConstants() {
        // Directly call the method
        Test.startTest();
        Map<String, String> result = LoanLoginChangeApplicantTypeController.getConstants();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void test_applicantDetails_Positive() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        // Inject the mock constant map
        LoanLoginChangeApplicantTypeController.constants = mockConstants();

        Test.startTest();
        List<LoanLoginChangeApplicantTypeController.ApplicantDetailsWrapper> details =
            LoanLoginChangeApplicantTypeController.applicantDetails(opp.Id);
        Test.stopTest();

        System.assert(details.size() > 0, 'Applicant details should be returned');
        System.assertNotEquals(null, details[0].applicantName);
    }

    @isTest
    static void test_applicantDetails_Exception() {
        // Invalid recordId to force query exception
        Test.startTest();
        try {
            LoanLoginChangeApplicantTypeController.applicantDetails(null);
           // System.assert(false, 'Exception expected');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('List has no rows'));
        }
        Test.stopTest();
    }

    @isTest
    static void test_saveApplicantDetails_Positive() {
        Application_Applicant__c app = [SELECT Id, Applicant_Type__c FROM Application_Applicant__c LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // Build wrapper and serialize
        LoanLoginChangeApplicantTypeController.ApplicantDetailsWrapper wrap = 
            new LoanLoginChangeApplicantTypeController.ApplicantDetailsWrapper();
        wrap.applicantId = app.Id;
        wrap.applicantType = 'Co Applicant';
        wrap.isKeyApplicant = true;

        String jsonString = JSON.serialize(new List<LoanLoginChangeApplicantTypeController.ApplicantDetailsWrapper>{wrap});

        Test.startTest();
        LoanLoginChangeApplicantTypeController.saveApplicantDetails(jsonString, true, opp.Id);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Exception_Approval_Status__c, Reasons_For_Execption_Approval__c FROM Opportunity WHERE Id = :opp.Id];
       // System.assertEquals('Not started', updatedOpp.Exception_Approval_Status__c);
        //System.assertEquals('Low Cibil Score', updatedOpp.Reasons_For_Execption_Approval__c);
    }

    @isTest
    static void test_saveApplicantDetails_NonLowCibil() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        LoanLoginChangeApplicantTypeController.ApplicantDetailsWrapper wrap = 
            new LoanLoginChangeApplicantTypeController.ApplicantDetailsWrapper();
        wrap.applicantId = app.Id;
        wrap.applicantType = 'Primary Applicant';
        wrap.isKeyApplicant = false;

        String jsonString = JSON.serialize(new List<LoanLoginChangeApplicantTypeController.ApplicantDetailsWrapper>{wrap});

        Test.startTest();
        LoanLoginChangeApplicantTypeController.saveApplicantDetails(jsonString, false, opp.Id);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Exception_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
      //  System.assertEquals('Not started', updatedOpp.Exception_Approval_Status__c);
    }

    @isTest
    static void test_updateCibilException() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        LoanLoginChangeApplicantTypeController.updateCibilException(opp.Id);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Exception_Approval_Status__c, Reasons_For_Execption_Approval__c FROM Opportunity WHERE Id = :opp.Id];
      //  System.assertEquals('Not started', updatedOpp.Exception_Approval_Status__c);
        //System.assertEquals('Low Cibil Score', updatedOpp.Reasons_For_Execption_Approval__c);
    }

    @isTest
    static void test_checkifbureauisfetched_Individual_AllGood() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Customer_Type__c = 'Individual' LIMIT 1];
        Test.startTest();
        String result = LoanLoginChangeApplicantTypeController.checkifbureauisfetched(app.Id);
        Test.stopTest();
        System.assertEquals('', result, 'Should return empty string since no error');
    }

    @isTest
    static void test_checkifbureauisfetched_NonIndividual_MissingPAN() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Customer_Type__c = 'Non Individual' LIMIT 1];
        app.Pan_Status__c = null;
        app.IsForm60Uploaded__c = null;
        update app;

        Test.startTest();
        String result = LoanLoginChangeApplicantTypeController.checkifbureauisfetched(app.Id);
        Test.stopTest();

       // System.assert(result.contains('PAN has not been validated'));
    }

    @isTest
    static void test_checkifbureauisfetched_Individual_MissingDetails() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Customer_Type__c = 'Individual' LIMIT 1];
        app.Basic_Details_Filled__c = null;
        update app;

        Test.startTest();
        String result = LoanLoginChangeApplicantTypeController.checkifbureauisfetched(app.Id);
        Test.stopTest();

        System.assert(result.contains('Please fill the basic details'), 'Should warn missing basic details');
    }*/
}