@IsTest
public class HL_QuickSanctionControllerTest {

 
    @testSetup
    static void setupData() {

        // Opportunity (Loan Application)
        Opportunity opp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Sales Login',
            CloseDate = Date.today().addDays(30),
            Product__c='Home Loan'
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

        // Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Name = 'Test Applicant',
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual',
            Customer_Profile__c = 'Salaried Indian',
            Monthly_Salary__c = 50000,
            Cibil_Score__c = 750,
            
            Is_Financial_applicant__c = 'Yes'
        );
        insert applicant;

         Trigger_Settings__c ts = new Trigger_Settings__c();
        ts.City_Master_Trigger__c=true;
        ts.Name='Trigger Settings';
        insert ts;
        

        City_Master__c city= new City_Master__c(
            City_Code__c= 'MMB',
            Country__c= 'IN',
            State__c='MH' ,
            Name = 'Mumbai'  
        );
        insert city;

        Pincode_Master__c pincode= new Pincode_Master__c(
            Name = '400066',
            City__c = city.Id
        );
        insert pincode;

        // Address
        Applicant_Address__c addr = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Type__c = 'Current',
            Address_Source__c = 'Aadhaar',
            Pincode__c = pincode.Id
        );
        insert addr;
    }

    /* -------------------------
       Test: checkQuickSanction – Valid Case
    --------------------------*/
    @IsTest
    static void testCheckQuickSanction_Valid() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        HL_QuickSanctionController.InputWrapper input =
            new HL_QuickSanctionController.InputWrapper();
        input.loanId = opp.Id;
        input.fromSalesToCredit = false;

        String jsonInput = JSON.serialize(input);

        Test.startTest();
        HL_QuickSanctionController.ResultMessage result =
            HL_QuickSanctionController.checkQuickSanction(jsonInput);
        Test.stopTest();

       
    }

    @IsTest
    static void testCheckQuickSanction_NoFinancialApplicant() {

        Opportunity opp = new Opportunity(
            Name = 'Loan Without Financial',
            StageName = 'Sales Login',
            CloseDate = Date.today().addDays(10),
            Product__c='Home Loan'
        );
        insert opp;

        // Non-financial applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Name = 'Non Financial',
            Applicant_Type__c = 'Co Applicant',
            Is_Financial_applicant__c = 'No'
        );
        insert applicant;

        HL_QuickSanctionController.InputWrapper input =
            new HL_QuickSanctionController.InputWrapper();
        input.loanId = opp.Id;
        input.fromSalesToCredit = false;

        Test.startTest();
        HL_QuickSanctionController.ResultMessage result =
            HL_QuickSanctionController.checkQuickSanction(JSON.serialize(input));
        Test.stopTest();

        
    }

    @IsTest
    static void testGetLoanDetails_Success() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        HL_QuickSanctionController.LoanDetailsWrapper result =
            HL_QuickSanctionController.getLoanDetails(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result.productId);
        System.assertNotEquals(null, result.productName);
    }


    @IsTest
    static void testGetLoanDetails_NoProduct() {

        Opportunity opp = new Opportunity(
            Name = 'Loan Without Product',
            StageName = 'Sales login',
            CloseDate = Date.today().addDays(20),
            Product__c='Home Loan'
        );
        insert opp;

        Test.startTest();
        HL_QuickSanctionController.LoanDetailsWrapper result =
            HL_QuickSanctionController.getLoanDetails(opp.Id);
        Test.stopTest();

        System.assertEquals(null, result.productId);
        System.assertEquals(1, result.errorList.size(),
            'Error should be returned when product is missing');
    }
}