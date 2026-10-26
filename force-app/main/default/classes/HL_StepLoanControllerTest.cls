@IsTest
public class HL_StepLoanControllerTest {
    
    /* =========================
TEST SETUP
========================= */
    @testSetup
    static void setupTestData() {
        
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Corp',
            Status = 'Open - Not Contacted',
            Product__c = 'Home Loan',
            MobilePhone = '9876543210',
            Customer_Type__c = 'Individual'
        );
        insert lead;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Loan Application',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Lead__c = lead.Id,
            Product__c = 'Home Loan'
        );
        insert opp;
        
        // Product
        Product2 prod = new Product2(
            Name = 'Home Loan Product',
            IsActive = true,
            Loan_Application__c = opp.Id,
            Product_Type__c = 'Parent'
        );
        insert prod;
        
        Application_Applicant__c applicant = new Application_Applicant__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Mobile_Number__c = '9876543210',
            PAN_Number__c = 'ABCDE1234F',
            DOB__c = Date.newInstance(1990, 1, 1),
            Gender__c = 'Male',
            Loan_Application__c = opp.Id
        );
        insert applicant;
        
        Trigger_Settings__c ts = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = true
        );
        insert ts;
        
        City_Master__c city = new City_Master__c(
            Name = 'Mumbai',
            City_Code__c = 'MMB',
            Country__c = 'IN',
            State__c = 'MH'
        );
        insert city;
        
        Pincode_Master__c pincode = new Pincode_Master__c(
            Name = '400066',
            City__c = city.Id
        );
        insert pincode;
        
        Applicant_Address__c address = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Landmark__c = 'Near Park',
            Building_Street_Name__c = 'Main Street',
            Pincode__c = pincode.Id
        );
        insert address;
        
        Integration_Details__c intDetail = new Integration_Details__c(
            Name = 'Test Detail',
            Endpoint__c = 'https://test.endpoint.com'
        );
        insert intDetail;
    }
    
    /* =========================
TEST createAndUpdateStepLoan
========================= */
    @IsTest
    static void testCreateAndUpdateStepLoan() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        HL_StepLoanController.StepLoanWrapper wrapper =
            new HL_StepLoanController.StepLoanWrapper();
        wrapper.stepNumber = 1;
        wrapper.stepIdentifier = 'Grace';
        wrapper.stepLoanAmount = 100000;
        wrapper.stepLoanTenure = 12;
        wrapper.tenurePercentage = 50;
        wrapper.autoCal = false;
        
        Test.startTest();
        Id stepLoanId = HL_StepLoanController.createAndUpdateStepLoan(
            wrapper,
            opp.Id,
            null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, stepLoanId, 'Step Loan record should be created');
    }
    
    /* =========================
TEST getTransactionDetails
========================= */
    @IsTest
    static void testGetTransactionDetails() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Id transactionRTId = Schema.SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByDeveloperName()
            .get('Transaction_Details')
            .getRecordTypeId();
        
        Loan_Transaction__c txn = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = transactionRTId,
            Allow_Grace__c = true,
            Step_Loan__c = true,
            Allow_Payment_in_Grace_Period__c = true,
            Grace_Period_Frequency__c = 6,
            Step_Specifier__c='Grace',
            Auto_Cal__c = false
        );
        insert txn;
        
        Test.startTest();
        HL_StepLoanController.TransactionDetailsWrapper result =
            HL_StepLoanController.getTransactionDetails(opp.Id, txn.Id);
        Test.stopTest();
        
        System.assertEquals(txn.Id, result.id);
        System.assertEquals(true, result.allowGrace);
        System.assertEquals(true, result.stepLoan);
    }
    
    /* =========================
TEST getStepLoan
========================= */
    @IsTest
    static void testGetStepLoan() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Id stepLoanRTId = Schema.SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByDeveloperName()
            .get('Step_Loan_Details')
            .getRecordTypeId();
        
        Loan_Transaction__c parentTxn = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = stepLoanRTId
        );
        insert parentTxn;
        
        Loan_Transaction__c stepLoan = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            Related_Transaction__c = parentTxn.Id,
            RecordTypeId = stepLoanRTId,
            Step_Number__c = 1,
            Step_Amount__c = 50000,
            Loan_Tenor__c = 6,
            Step_Specifier__c='Grace',
            Auto_Cal__c = false
        );
        insert stepLoan;
        
        Test.startTest();
        List<HL_StepLoanController.StepLoanWrapper> result =
            HL_StepLoanController.getStepLoan(opp.Id, parentTxn.Id);
        Test.stopTest();
        
        System.assertEquals(1, result.size());
        System.assertEquals(1, result[0].stepNumber);
    }
    
    /* =========================
TEST deleteAndRecalculateStepLoan
========================= */
    @IsTest
    static void testDeleteAndRecalculateStepLoan() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Id stepLoanRTId = Schema.SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByDeveloperName()
            .get('Step_Loan_Details')
            .getRecordTypeId();
        
        Loan_Transaction__c parentTxn = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = stepLoanRTId,
            Auto_Cal__c = false
        );
        insert parentTxn;
        
        Loan_Transaction__c stepLoan1 = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            Related_Transaction__c = parentTxn.Id,
            RecordTypeId = stepLoanRTId,
            Step_Number__c = 1,
            Auto_Cal__c = false
        );
        insert stepLoan1;
        
        Test.startTest();
        List<HL_StepLoanController.StepLoanWrapper> result =
            HL_StepLoanController.deleteAndRecalculateStepLoan(
                stepLoan1.Id,
                parentTxn.Id
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result);
    }
    
    /* =========================
TEST getTransactionsByProductIds
========================= */
    @IsTest
    static void testGetTransactionsByProductIds() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [Select id from Product2 where Loan_Application__c=:opp.id];
        Loan_Transaction__c txn = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            Product__c =prod.id,
            Auto_Cal__c = false
        );
        insert txn;
        
        Test.startTest();
        Map<Id, Loan_Transaction__c> result =
            HL_StepLoanController.getTransactionsByProductIds(
                new List<Id>{ prod.Id }, opp.Id
            );
        Test.stopTest();
        
        
    }
    
    @IsTest
    static void testRecalculateStepNumbers() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Id stepLoanRTId = Schema.SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByDeveloperName()
            .get('Step_Loan_Details')
            .getRecordTypeId();
        
        Loan_Transaction__c stepLoan1 = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = stepLoanRTId,
            Step_Number__c = 5,
            Auto_Cal__c = false
        );
        
        Loan_Transaction__c stepLoan2 = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = stepLoanRTId,
            Step_Number__c = 10,
            Auto_Cal__c = false
        );
        
        insert new List<Loan_Transaction__c>{ stepLoan1, stepLoan2 };
            
            List<Loan_Transaction__c> stepLoans =
            [SELECT Id, Step_Number__c FROM Loan_Transaction__c
             WHERE Id IN :new List<Id>{ stepLoan1.Id, stepLoan2.Id }
             ORDER BY Step_Number__c];
        
        Test.startTest();
        HL_StepLoanController.recalculateStepNumbers(stepLoans);
        Test.stopTest();
        
        List<Loan_Transaction__c> updated =
            [SELECT Step_Number__c FROM Loan_Transaction__c
             WHERE Id IN :stepLoans];
        
        System.assertEquals(1, updated[0].Step_Number__c);
        System.assertEquals(2, updated[1].Step_Number__c);
    }
    
    
    @IsTest
    static void testGetTransactionsByProductIds_HLBranch() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // -------------------------------
        // Create Record Types dynamically
        // -------------------------------
        Id productRT = Schema.SObjectType.Product2
            .getRecordTypeInfosByName()
            .get('Product')
            .getRecordTypeId();
        
        Id subProductRT = Schema.SObjectType.Product2
            .getRecordTypeInfosByName()
            .get('Sub Product')
            .getRecordTypeId();
        
        Id subVariantRT = Schema.SObjectType.Product2
            .getRecordTypeInfosByDeveloperName()
            .get('Sub_Variant')
            .getRecordTypeId();
        
        // -------------------------------
        // Create Main Product
        // -------------------------------
        Product2 mainProduct = new Product2(
            Name = 'Main Product',
            IsActive = true,
            RecordTypeId = productRT
        );
        insert mainProduct;
        
        // -------------------------------
        // Create Sub Product
        // -------------------------------
        Product2 subProduct = new Product2(
            Name = 'Sub Product',
            IsActive = true,
            RecordTypeId = subProductRT,
            Product__c = mainProduct.Id
        );
        insert subProduct;
        
        // -------------------------------
        // Create Sub Variant
        // -------------------------------
        Product2 subVariant = new Product2(
            Name = 'Sub Variant',
            IsActive = true,
            RecordTypeId = subVariantRT,
            Product__c = subProduct.Id,
            Loan_Application__c = opp.Id
        );
        insert subVariant;
        
        // -------------------------------
        // Create Loan Transaction WITHOUT Subvariant
        // -------------------------------
        Loan_Transaction__c txn = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            Product__c = mainProduct.Id,
            Auto_Cal__c = false
        );
        insert txn;
        
        Test.startTest();
        
        Map<Id, Loan_Transaction__c> result =
            HL_StepLoanController.getTransactionsByProductIds(
                new List<Id>{ mainProduct.Id },
                opp.Id
            );
        
        Test.stopTest();
        
        System.assert(result.containsKey(mainProduct.Id),
                      'Result map should contain product');
        
        Loan_Transaction__c updatedTxn =
            [SELECT Product_Subvariant__c
             FROM Loan_Transaction__c
             WHERE Id = :txn.Id];
        
        /*System.assertNotEquals(null, updatedTxn.Product_Subvariant__c,
                               'Sub Variant should be populated for HL case');*/
    }
}