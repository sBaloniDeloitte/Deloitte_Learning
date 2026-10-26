@isTest
public class SanctionLetterHandlerTest {

 	@testSetup
    static void testConstructPayload_success() {
         Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
         Application_Collateral__c appColl = new Application_Collateral__c(
            HL_Loan_Application__c = opp.Id
        );
        insert appColl;
        
        Id productRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Id subProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
        Id variantRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();
        System.debug('variantRecordTypeId>>>'+variantRecordTypeId);
        Id subVariantRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Variant').getRecordTypeId();
        System.debug('subVariantRecordTypeId>>>'+subVariantRecordTypeId);

        Product2 product = TestDataFactory.newProductDetails(false, productRecordTypeId, opp);
        product.name = 'Affordable Home Loan';
        insert product;
        
        Product2 product1 = TestDataFactory.newProductDetails(false, subProductRecordTypeId, opp);
        product1.Product__c = product.id;
        insert product1;
       
        
        Product2 product2 = TestDataFactory.newProductDetails(false, variantRecordTypeId, opp);
        product1.Product__c = product1.id;
        insert product2;
       
        
        Product2 product3 = TestDataFactory.newProductDetails(false, subVariantRecordTypeId, opp);
        product1.Product__c = product1.id;
        insert product3;
        
         Map<String, Schema.RecordTypeInfo> ciRtInfos =
        Charges_Insurance__c.SObjectType.getDescribe().getRecordTypeInfosByName();
    Id insuranceRtId = ciRtInfos.get('Insurance').getRecordTypeId();
    Id chargesRtId   = ciRtInfos.get('Charges').getRecordTypeId();
        
        Charges_Insurance__c insOldSF = new Charges_Insurance__c(
        RecordTypeId         = chargesRtId,
        Category__c          = 'Insurance',
        Loan_Application__c  = opp.Id,
        Name                 = 'UT Insurance SF',
        Fee_Method__c        = 'Self Funded',
        Total_VAS_Amount__c  = 500,
        Insurance_Premium__c = 500,
            Final_Amount_INR__c = 100000,
        
        VAS_Code__c          = 'VAS_X'
    );
    insert insOldSF;
        
        Charges_Insurance__c insOldSF1 = new Charges_Insurance__c(
        RecordTypeId         = chargesRtId,
        Category__c          = 'LMS',
        Loan_Application__c  = opp.Id,
        Name                 = 'LOSAMC',
        Fee_Method__c        = 'Self Funded',
        Total_VAS_Amount__c  = 500,
        Insurance_Premium__c = 500,
            Requested_Percentage__c = 10,
        
        VAS_Code__c          = 'VAS_X'
    );
    insert insOldSF1;
        
         Charges_Insurance__c insOldSF2 = new Charges_Insurance__c(
        RecordTypeId         = chargesRtId,
        Category__c          = 'LOS',
        Loan_Application__c  = opp.Id,
        Name                 = 'PROCFEE',
        Fee_Method__c        = 'Self Funded',
        Total_VAS_Amount__c  = 500,
        Insurance_Premium__c = 500,
            Requested_Percentage__c = 10,
             Requested_Amount_INR__c = 100000,
             Final_Amount_INR__c = 10000000,
        
        VAS_Code__c          = 'VAS_X'
    );
    insert insOldSF2;
         Charges_Insurance__c insOldSF3 = new Charges_Insurance__c(
        RecordTypeId         = chargesRtId,
        Category__c          = 'LOS',
        Loan_Application__c  = opp.Id,
        Name                 = 'STFRCHG',
        Fee_Method__c        = 'Self Funded',
        Total_VAS_Amount__c  = 500,
        Insurance_Premium__c = 500,
            Requested_Percentage__c = 10,
             Requested_Amount_INR__c = 100000,
             Final_Amount_INR__c = 10000000,
        
        VAS_Code__c          = 'VAS_X'
    );
    insert insOldSF3;
       

        // Create dummy Loan Transaction
        Loan_Transaction__c loanTran = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId(),
            Disbursement_Amount__c = 50000,
            Loan_Start_Date__c = Date.today(),
            Step_Loan__c = true,
            Allow_Grace__c = false,
            //Allow_Planned_EMI_Holiday__c = true,
            Payment_Method__c = 'DDM',
            Interest_Frequency__c = 'M'
        );
        insert loanTran;
        
        /*Loan_Transaction__c loanTran1 = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Step_Loan_Details').getRecordTypeId(),
            Disbursement_Amount__c = 50000,
            Loan_Start_Date__c = Date.today(),
            Step_Loan__c = false,
            Allow_Grace__c = false,
            Payment_Method__c = 'DDM',
            Interest_Frequency__c = 'M',
            Step_Specifier__c = 'Grace'
        );
        insert loanTran1;
        Loan_Transaction__c loanTran2 = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Step_Loan_Details').getRecordTypeId(),
            Disbursement_Amount__c = 50000,
            Loan_Start_Date__c = Date.today(),
            Step_Loan__c = false,
            Allow_Grace__c = false,
            Payment_Method__c = 'DDM',
            Interest_Frequency__c = 'M',
            Step_Specifier__c = 'Repayment'
        );
        insert loanTran2;*/
        
        OpportunityTeamMember otm = new OpportunityTeamMember(
        UserId = UserInfo.getUserId(),
        TeamMemberRole = 'Sales Manager',
            OpportunityAccessLevel = 'Edit',
                Associated_With_Loan_Application__c  = true,
            OpportunityId = opp.Id
        
        );
        insert otm;
       
        Account acc=[select id,SF_Customer_ID__c from Account limit 1];
        Application_Applicant__c appApplicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Primary Applicant',
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Mobile_Number__c = '9999999999',
            Email__c = 'test@example.com',
            Customer__c =acc.id,
            Customer_Type__c = 'Individual'
        );
        insert appApplicant;
        system.debug('acc>>'+acc);
    }
      @isTest
    static void testConstructPayload() {
        Opportunity opp=[select id from opportunity limit 1];

        /*Id productRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Id subProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
        Id variantRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();
        System.debug('variantRecordTypeId>>>'+variantRecordTypeId);
        Id subVariantRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Variant').getRecordTypeId();
        System.debug('subVariantRecordTypeId>>>'+subVariantRecordTypeId);

        Product2 product = TestDataFactory.newProductDetails(false, productRecordTypeId, opp);
        product.name = 'Affordable Home Loan';
        insert product;
        
        Product2 product1 = TestDataFactory.newProductDetails(false, subProductRecordTypeId, opp);
        product1.Product__c = product.id;
        insert product1;
        
        Product2 product2 = TestDataFactory.newProductDetails(false, variantRecordTypeId, opp);
        product1.Product__c = product1.id;
        insert product2;
        
        Product2 product3 = TestDataFactory.newProductDetails(false, subVariantRecordTypeId, opp);
        product1.Product__c = product1.id;
        insert product3;*/

        Integration_Details__c integrationRecord = new Integration_Details__c(
    Name = 'Sacnction Letter',
    Method_Type__c = 'GET',
    Business_Date__c = Date.today(),
    EndPoint__c = 'https://example.com/api',
    Response_JSON__c = '{}',
    Request_JSON__c = '{}'
);
insert integrationRecord;

        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        Test.startTest();
        String jsonResponse = new SanctionLetterHandler().constructPayload(wrapper, new List<Integration_Details__c>());
        Test.stopTest();

        System.assertNotEquals(null, jsonResponse, 'Should return a JSON payload');
        System.assert(jsonResponse.contains('John Doe'), 'JSON should contain applicant name');
    }

    @isTest
    static void testConstructPayload_catchBlock() {
        // Create wrapper with invalid Opportunity Id
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = '006XXXXXXXXXXX'; // non-existent Opp Id

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            new SanctionLetterHandler().constructPayload(wrapper, new List<Integration_Details__c>());
        } catch (Exception e) {
        }
        Test.stopTest();

    }

    @isTest
    static void testFormatDateString_successAndCatch() {
        Date dt = Date.newInstance(2025, 10, 4);
        String formatted = SanctionLetterHandler.formatDateString(dt);
        System.assert(formatted.startsWith('2025-10-04T'), 'Formatted date must include T00:00:00');
        try {
            SanctionLetterHandler.formatDateString(null);
        } catch (AuraHandledException e) {
            System.assert(false, 'Null should not throw');
        }
    }
     // Helper: create constants map
    private static void setupConstants() {
        SanctionLetterHandler.constants = new Map<String, String>{
            'Error_Loan_Application_not_found' => 'Loan App not found: ',
            'Error_Missing_Loan_Amount' => 'Loan Amount missing',
            'Error_Missing_SanctionTerms' => 'Sanction Terms missing',
            'Error_No_Loan_Transaction_records_found' => 'No Loan Transaction found for: ',
            'Error_Missing_Scheduling_Method' => 'Missing Schedule Method',
            'Error_TDS_Applicable_is_not_selected' => 'Missing TDS Applicable',
            'Error_Missing_Rate_Type' => 'Missing Rate Type',
            'Error_Missing_Number_of_Grace_Terms' => 'Missing Grace Terms',
            'Error_Missing_Default_BPI_Treatment' => 'Missing BPI Treatment'
            // add others if needed
        };
    }

    @isTest
    static void testValidatePayload_withErrors() {
        setupConstants();

        // Create wrapper with invalid Opp Id (to simulate missing loan application)
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = '006XXXXXXXXXXX'; // non-existent

        Test.startTest();
        try{
            SanctionLetterHandler.getConstants();
        List<String> errors = SanctionLetterHandler.validatePayload(wrapper);
        }catch(exception e){}
        Test.stopTest();
    }

    @isTest
    static void testValidatePayload_withLoanAppAndLoanTransaction() {
        setupConstants();

        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createOpportunity(customer);

        // Create Loan Transaction (with missing required fields → will trigger errors)
        Loan_Transaction__c lt = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId()
            // Missing Schedule_Method__c, TDS_Applicable__c, etc
        );
        insert lt;

        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;

        Test.startTest();
        List<String> errors = SanctionLetterHandler.validatePayload(wrapper);
        Test.stopTest();

        System.assert(errors.size() > 0, 'Must have errors for missing fields');
        System.assertEquals(true, errors.contains('Loan Amount missing'), 'Should catch missing loan amount');
        System.assertEquals(true, errors.contains('Sanction Terms missing'), 'Should catch missing sanction terms');
        System.assertEquals(true, errors.contains('Missing Schedule Method'), 'Should catch missing schedule method');
    }

    @isTest
    static void testValidatePayload_stepLoanError() {
        setupConstants();

        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createOpportunity(customer);

        // Create Loan Transaction with Step Loan = true but no Step Loan Records
        Loan_Transaction__c lt = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId(),
            Step_Loan__c = true
        );
        insert lt;

        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;

        Test.startTest();
        List<String> errors = SanctionLetterHandler.validatePayload(wrapper);
        Test.stopTest();

        System.assert(errors.contains('Applicable Step Loan Details are missing'), 'Should catch missing Step Loan details');
    }

    @isTest
    static void testValidatePayload_conditionalErrors() {
        setupConstants();

        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createOpportunity(customer);

        // Create Loan Transaction with Allow_Grace__c = true and Allow_BPI__c = true
        Loan_Transaction__c lt = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId(),
            Allow_Grace__c = true,
            Allow_BPI__c = true
            // Missing Grace_Period_Frequency__c and BPI_Treatment__c → should trigger errors
        );
        insert lt;

        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;

        Test.startTest();
        List<String> errors = SanctionLetterHandler.validatePayload(wrapper);
        Test.stopTest();

        System.assert(errors.contains('Missing Grace Terms'), 'Should catch missing grace terms');
        System.assert(errors.contains('Missing BPI Treatment'), 'Should catch missing BPI Treatment');
    }
}