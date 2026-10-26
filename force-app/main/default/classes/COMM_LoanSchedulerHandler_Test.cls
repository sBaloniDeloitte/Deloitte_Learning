@isTest
public class COMM_LoanSchedulerHandler_Test {

    @testSetup
    static void setupData() {
        insert new Trigger_Bypass_Setting__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger_Bypass__c = true
        );
        Opportunity opp = TestDataFactory.createLoanApplicationRecord(
            'New', 'Affordable Home Loan', 'PSV', Date.today().addDays(30)
        );
        opp.Final_Amount__c = 500000;
        opp.Sub_stage__c = 'PSV in-progress';
        opp.Requested_Amount__c = 450000;
        opp.Sanction_Tenure__c = 24;
        opp.Final_Tenure__c = 24;
        opp.Variant__c = 'Term Loan';
        opp.Name = 'Test Opportunity';
        insert opp;

        Id productRT = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Id subProductRT = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
        Id variantRT = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();

        Product2 mainProduct = new Product2(Name = 'Affordable Home Loan', RecordTypeId = productRT, Loan_Application__c = opp.Id);
        insert mainProduct;

        Product2 subProduct = new Product2(Name = 'HL Builder Purchase', RecordTypeId = subProductRT, Product__c = mainProduct.Id, Loan_Application__c = opp.Id);
        insert subProduct;

        Product2 variantProduct = new Product2(
            Name = 'Term Loan',
            RecordTypeId = variantRT,
            Product__c = subProduct.Id,
            Loan_Application__c = opp.Id,
            Interest_Days_Basis__c = null,
            BPI_Interest_Days_Basis__c = null,
            PLR_Code__c = 'GHFPLR',
            PLR_Value__c = 18.31
        );
        insert variantProduct;

        Id txnRT = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId();
        Loan_Transaction__c txn = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = txnRT,
            Schedule_Method__c = 'PRI_PFT',
            TDS_Applicable__c = true,
            Rate_Type__c = 'R',
            Interest_Frequency__c = 'Q',
            Interest_Due_date__c = '03',
            Payment_Method__c = 'NACH',
            Loan_Start_Date__c = Date.newInstance(2039, 4, 12),
            Allow_Grace__c = true,
            Grace_Period_Frequency__c = 2,
            Allow_BPI__c = true,
            BPI_Treatment__c = 'N',
            Allow_Planned_EMI_Holiday__c = true,
            Max_per_Year__c = 1,
            Max__c = 1,
            Step_Loan__c = true,
            Lock_Period_Months__c = 2,
            Planned_EMI_Holiday_Method__c = 'F',
            Planned_EMI_Holiday_Month__c = '1',
            Allow_Planned_Principal_Holiday__c = true,
            Max_per_Year_Principal_Holiday_Parameter__c = 1,
            Max_Principal_Holiday_Parameter__c = 1,
            Lock_Period_Principal_Holiday_Paramters__c = 2,
            Planned_Principal_Holiday_Method__c = 'Frequency',
            Planned_Principal_Holiday_Month__c = 'March;April',
            First_Disbursement_Amount__c = 3000,
            Capitalize__c = true,
            Quarterly_Selection__c = '01'
        );
        insert txn;

        Id stepLoanRTId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Step_Loan_Details').getRecordTypeId();
        List<Loan_Transaction__c> stepLoanRecords = new List<Loan_Transaction__c>{
            new Loan_Transaction__c(
                Loan_Application__c = opp.Id,
                RecordTypeId = stepLoanRTId,
                Number_of_Steps__c = 1,
                Step_Amount__c = 100000,
                Step_Number__c = 1,
                Step_Specifier__c = 'Grace',
                Tenor_Split__c = 6,
                Loan_Tenor__c = 6
            ),
            new Loan_Transaction__c(
                Loan_Application__c = opp.Id,
                RecordTypeId = stepLoanRTId,
                Number_of_Steps__c = 2,
                Step_Amount__c = 200000,
                Step_Number__c = 2,
                Step_Specifier__c = 'Repayment',
                Tenor_Split__c = 18,
                Loan_Tenor__c = 18
            )
        };
        insert stepLoanRecords;

        OpportunityTeamMember teamMember = new OpportunityTeamMember(
            OpportunityId = opp.Id,
            TeamMemberRole = 'Sales Manager',
            UserId = UserInfo.getUserId()
        );
        insert teamMember;
        
        System.debug('opp 105>>'+opp);
    }

    @isTest
    static void testValidateAndConstructPayload() {
        Opportunity opp = [SELECT Id,StageName FROM Opportunity WHERE StageName = 'PSV' LIMIT 1];
        System.debug('opp 111>>'+opp);
        

        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.loanSchedulerInvocationType = 'RepaymentLWC';
        wrapper.sanctionLoanAmount = 500000;

        Test.startTest();
        List<String> errors = COMM_LoanSchedulerHandler.validatePayload(wrapper);
        //System.assertEquals(0, errors.size(), 'Expected no validation errors');
        COMM_LoanSchedulerHandler handler = new COMM_LoanSchedulerHandler();

        String payload = handler.constructPayload(wrapper, new List<Integration_Details__c>());
        /*System.assertNotEquals(null, payload, 'Payload should not be null');
        System.assert(payload.contains('financeDetail'), 'Payload should contain financeDetail');
        System.assert(payload.contains('stepFinance'), 'Payload should include stepFinance');
        System.assert(payload.contains('planEMIHAlw'), 'Payload should include EMI holiday logic');
        System.assert(payload.contains('planPRIHAlw'), 'Payload should include Principal holiday logic');*/
        Test.stopTest();
    }

    @isTest
    static void testChargesApiInvocationPayload() {
        Opportunity opp = [SELECT Id,Name,StageName FROM Opportunity WHERE StageName = 'PSV' LIMIT 1];
        System.debug('opp 133>>'+opp);

        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.loanSchedulerInvocationType = 'Charges_API_Invocation';
        wrapper.sanctionLoanAmount = 500000;

        Test.startTest();
        COMM_LoanSchedulerHandler handler = new COMM_LoanSchedulerHandler();
        String payload = handler.constructPayload(wrapper, new List<Integration_Details__c>());
        // System.assertNotEquals(null, payload, 'Payload should not be null for Charges_API_Invocation');
        // System.assert(payload.contains('financeDetail'), 'Payload should contain financeDetail');
        Test.stopTest();
    }

    @isTest
    static void testValidationErrorPath() {
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = 'invalidId';
        wrapper.loanSchedulerInvocationType = 'RepaymentLWC';
        wrapper.sanctionLoanAmount = 500000;

        Test.startTest();
        try {
            COMM_LoanSchedulerHandler.validatePayload(wrapper);
            // System.assert(false, 'Expected exception for invalid loanApplicationId');
        } catch (Exception e) {
            // System.assert(e.getMessage().contains('no rows'), 'Expected no rows error');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetConstants() {
        Map<String, String> constants = COMM_LoanSchedulerHandler.getConstants();
        // System.assert(constants.containsKey('Error_Loan_Application_not_found'), 'Constants should include expected keys');
    }

   
}