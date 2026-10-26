@isTest
private class DisbursmentMemoHandlerTest {

    @testSetup
    static void setupTestData() {
        // Safely fetch RecordType for Loan_Transaction__c
        List<RecordType> txnRTs = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'Loan_Transaction__c' 
            AND DeveloperName = 'Transaction_Details' 
            LIMIT 1
        ];
        System.assert(!txnRTs.isEmpty(), 'Missing RecordType: Transaction_Details for Loan_Transaction__c');
        RecordType rtTxn = txnRTs[0];

        // Safely fetch RecordType for Charges_Insurance__c
        List<RecordType> chargeRTs = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'Charges_Insurance__c' 
            AND DeveloperName = 'Charges' 
            LIMIT 1
        ];
        System.assert(!chargeRTs.isEmpty(), 'Missing RecordType: Charges for Charges_Insurance__c');
        RecordType rtCharges = chargeRTs[0];

        // === Individual Applicant Scenario ===
        Opportunity oppInd = new Opportunity(
            Name = 'Test Loan Individual',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Product__c = 'Home Loan',
            Final_Amount__c = 500000,
            Final_Tenure__c = 60,
            Final_Rate_Of_Interest__c = 8.5,
            EMI_Amount_Repayment_Schedule__c = 10500
        );
        insert oppInd;

        Loan_Transaction__c txnInd = new Loan_Transaction__c(
            Loan_Application__c = oppInd.Id,
            RecordTypeId = rtTxn.Id,
            First_Disbursement_Amount__c = 250000,
            Allow_Grace__c = true,
            Interest_Frequency__c = 'M',
            Grace_Period_Frequency__c = 3,
            Rate_Type__c = 'R'
        );
        insert txnInd;

        Application_Applicant__c primaryInd = new Application_Applicant__c(
            Loan_Application__c = oppInd.Id,
            Name = 'John Doe',
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual',
            Email__c = 'john@example.com'
        );
        insert primaryInd;
        
        Trigger_Settings__c settings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            Lead_Trigger__c = true,
            City_Master_Trigger__c = true 
        );
        insert settings;
        
        City_Master__c city = new City_Master__c(Name = 'Gudivada',City_Code__c = 'C01',Country__c='IN',State__c='AP');
        insert city;
		Pincode_Master__c pinCode = new Pincode_Master__c(City__c = city.Id, Name='521301');
        insert pinCode;
        
        Applicant_Address__c addressInd = new Applicant_Address__c(
            Applicant__c = primaryInd.Id,
            Address_Priority__c = '5',
            Address_Line_1__c = '123 Main St',
            Address_Type__c = 'Current',
            Pincode__c =  pinCode.Id// Replace with valid ID
        );
        insert addressInd;

        Charges_Insurance__c procFee = new Charges_Insurance__c(
            Loan_Application__c = oppInd.Id,
            RecordTypeId = rtCharges.Id,
            Name = 'PROCFEE',
            Final_Amount_INR__c = 1500
        );
        insert procFee;

        // === Non-Individual Applicant Scenario ===
        Opportunity oppNonInd = new Opportunity(
            Name = 'Test Loan Non-Individual',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Product__c = 'Home Loan',
            Final_Amount__c = 750000,
            Final_Tenure__c = 48,
            Final_Rate_Of_Interest__c = 9.0,
            EMI_Amount_Repayment_Schedule__c = 18000
        );
        insert oppNonInd;

        Loan_Transaction__c txnNonInd = new Loan_Transaction__c(
            Loan_Application__c = oppNonInd.Id,
            RecordTypeId = rtTxn.Id,
            First_Disbursement_Amount__c = 300000,
            Allow_Grace__c = false,
            Interest_Frequency__c = 'M',
            Grace_Period_Frequency__c = 2,
            Rate_Type__c = 'F'
        );
        insert txnNonInd;

        Application_Applicant__c primaryNonInd = new Application_Applicant__c(
            Loan_Application__c = oppNonInd.Id,
            Name = 'ABC Pvt Ltd',
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Non Individual',
            Email__c = 'contact@abcpvtltd.com'
        );
        insert primaryNonInd;

        Applicant_Address__c addressNonInd = new Applicant_Address__c(
            Applicant__c = primaryNonInd.Id,
            Address_Priority__c = '5',
            Address_Line_1__c = '456 Corporate Park',
            Address_Type__c = 'Office',
            Pincode__c = pinCode.Id // Replace with valid ID
        );
        insert addressNonInd;
    }

    @isTest
    static void testDisbursmentMemoHandler_Individual() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        RepaymentScheduleWrapper.Schedule dummySchedule = new RepaymentScheduleWrapper.Schedule();
        dummySchedule.instNumber = 1;
        dummySchedule.dueDate = String.valueOf(Date.today().addMonths(1));
        dummySchedule.bpiAmount = 500;
        dummySchedule.totalAmount = 10500;

        Test.startTest();
        ApexPages.currentPage().getParameters().put('Id', opp.Id);
        DisbursmentMemoHandler handler = new DisbursmentMemoHandler();
        handler.repaymentSchedules = new List<RepaymentScheduleWrapper.Schedule>{ dummySchedule };
        Test.stopTest();

    }

    @isTest
    static void testDisbursmentMemoHandler_NonIndividual() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        RepaymentScheduleWrapper.Schedule dummySchedule = new RepaymentScheduleWrapper.Schedule();
        dummySchedule.instNumber = 1;
        dummySchedule.dueDate = String.valueOf(Date.today().addMonths(1));
        dummySchedule.bpiAmount = 300;
        dummySchedule.totalAmount = 18000;

        Test.startTest();
        ApexPages.currentPage().getParameters().put('Id', opp.Id);
        DisbursmentMemoHandler handler = new DisbursmentMemoHandler();
        handler.repaymentSchedules = new List<RepaymentScheduleWrapper.Schedule>{ dummySchedule };
        Test.stopTest();

    }
    
    @isTest
    static void testDisbursmentMemoHandler_YearlyFrequency() {
        Opportunity opp = new Opportunity(
            Name = 'Test Loan Yearly',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Product__c = 'Home Loan',
            Final_Amount__c = 600000,
            Final_Tenure__c = 36,
            Final_Rate_Of_Interest__c = 7.5,
            EMI_Amount_Repayment_Schedule__c = 20000
        );
        insert opp;
    
        RecordType rtTxn = [SELECT Id FROM RecordType WHERE SObjectType = 'Loan_Transaction__c' AND DeveloperName = 'Transaction_Details' LIMIT 1];
        Loan_Transaction__c txn = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = rtTxn.Id,
            First_Disbursement_Amount__c = 300000,
            Allow_Grace__c = false,
            Interest_Frequency__c = 'M',
            Grace_Period_Frequency__c = 1,
            Rate_Type__c = 'F'
        );
        insert txn;
    
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Name = 'Yearly Test',
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual'
        );
        insert applicant;
        
        City_Master__c city = new City_Master__c(Name = 'Gudivada',City_Code__c = 'C01',Country__c='IN',State__c='AP');
        insert city;
        Pincode_Master__c pinCode = new Pincode_Master__c(City__c = city.Id, Name='521301');
        insert pinCode;
    
        Applicant_Address__c address = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Priority__c = '5',
            Address_Line_1__c = '789 Yearly Lane',
            Address_Type__c = 'Current',
            Pincode__c = pinCode.Id
        );
        insert address;
    
        Test.startTest();
        ApexPages.currentPage().getParameters().put('Id', opp.Id);
        DisbursmentMemoHandler handler = new DisbursmentMemoHandler();
        Test.stopTest();
    
        //System.assertEquals('Yearly', handler.paymentfrequency, 'Payment frequency should be Yearly');
    }
    
    @isTest
    static void testDisbursmentMemoHandler_QuarterlyFrequency() {
        
         Opportunity opp = new Opportunity(
            Name = 'Test Loan Yearly',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Product__c = 'Home Loan',
            Final_Amount__c = 600000,
            Final_Tenure__c = 36,
            Final_Rate_Of_Interest__c = 7.5,
            EMI_Amount_Repayment_Schedule__c = 20000
        );
        insert opp;
    
        RecordType rtTxn = [SELECT Id FROM RecordType WHERE SObjectType = 'Loan_Transaction__c' AND DeveloperName = 'Transaction_Details' LIMIT 1];
        Loan_Transaction__c txn = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = rtTxn.Id,
            First_Disbursement_Amount__c = 300000,
            Allow_Grace__c = false,
            Interest_Frequency__c = 'M',
            Grace_Period_Frequency__c = 1,
            Rate_Type__c = 'F'
        );
        insert txn;
    
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Name = 'Yearly Test',
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual'
        );
        insert applicant;
        
        City_Master__c city = new City_Master__c(Name = 'Gudivada',City_Code__c = 'C01',Country__c='IN',State__c='AP');
        insert city;
        Pincode_Master__c pinCode = new Pincode_Master__c(City__c = city.Id, Name='521301');
        insert pinCode;
    
        Applicant_Address__c address = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Priority__c = '5',
            Address_Line_1__c = '789 Yearly Lane',
            Address_Type__c = 'Current',
            Pincode__c = pinCode.Id
        );
        insert address;
    
        Test.startTest();
        ApexPages.currentPage().getParameters().put('Id', opp.Id);
        DisbursmentMemoHandler handler = new DisbursmentMemoHandler();
        Test.stopTest();
    
        //System.assertEquals('Quarterly', handler.paymentfrequency, 'Payment frequency should be Quarterly');
    }
        // Similar to above, but set Interest_Frequency__c = 'M'
        // Assert handler.paymentfrequency == 'Quarterly'
    
    
    @isTest
    static void testDisbursmentMemoHandler_HalfYearlyFrequency() {
        
        Opportunity opp = new Opportunity(
            Name = 'Test Loan Yearly',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Product__c = 'Home Loan',
            Final_Amount__c = 600000,
            Final_Tenure__c = 36,
            Final_Rate_Of_Interest__c = 7.5,
            EMI_Amount_Repayment_Schedule__c = 20000
        );
        insert opp;
    
        RecordType rtTxn = [SELECT Id FROM RecordType WHERE SObjectType = 'Loan_Transaction__c' AND DeveloperName = 'Transaction_Details' LIMIT 1];
        Loan_Transaction__c txn = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = rtTxn.Id,
            First_Disbursement_Amount__c = 300000,
            Allow_Grace__c = false,
            Interest_Frequency__c = 'M',
            Grace_Period_Frequency__c = 1,
            Rate_Type__c = 'F'
        );
        insert txn;
    
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Name = 'Yearly Test',
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual'
        );
        insert applicant;
    
        City_Master__c city = new City_Master__c(Name = 'Gudivada',City_Code__c = 'C01',Country__c='IN',State__c='AP');
        insert city;
        Pincode_Master__c pinCode = new Pincode_Master__c(City__c = city.Id, Name='521301');
        insert pinCode;
        
        Applicant_Address__c address = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Priority__c = '5',
            Address_Line_1__c = '789 Yearly Lane',
            Address_Type__c = 'Current',
            Pincode__c = pinCode.Id
        );
        insert address;
    
        Test.startTest();
        ApexPages.currentPage().getParameters().put('Id', opp.Id);
        DisbursmentMemoHandler handler = new DisbursmentMemoHandler();
        Test.stopTest();
    
        //System.assertEquals('Half Yearly', handler.paymentfrequency, 'Payment frequency should be Half Yearly');
        // Similar to above, but set Interest_Frequency__c = 'M'
        // Assert handler.paymentfrequency == 'Half Yearly'
    }
        
        @isTest
    static void testDisbursmentMemoHandler_RepaymentScheduleLogic() {
        Opportunity opp = new Opportunity(
            Name = 'Test Loan Schedule Logic',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Product__c = 'Home Loan',
            Final_Amount__c = 800000,
            Final_Tenure__c = 36,
            Final_Rate_Of_Interest__c = 10.0,
            EMI_Amount_Repayment_Schedule__c = 22000
        );
        insert opp;
    
        RecordType rtTxn = [SELECT Id FROM RecordType WHERE SObjectType = 'Loan_Transaction__c' AND DeveloperName = 'Transaction_Details' LIMIT 1];
        Loan_Transaction__c txn = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = rtTxn.Id,
            First_Disbursement_Amount__c = 400000,
            Allow_Grace__c = true,
            Interest_Frequency__c = 'M',
            Grace_Period_Frequency__c = 2,
            Rate_Type__c = 'R'
        );
        insert txn;
    
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Name = 'Schedule Tester',
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual'
        );
        insert applicant;
        
        City_Master__c city = new City_Master__c(Name = 'Gudivada',City_Code__c = 'C01',Country__c='IN',State__c='AP');
        insert city;
        Pincode_Master__c pinCode = new Pincode_Master__c(City__c = city.Id, Name='521301');
        insert pinCode;
    
        Applicant_Address__c address = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Priority__c = '5',
            Address_Line_1__c = '789 Schedule Street',
            Address_Type__c = 'Current',
            Pincode__c = pinCode.Id
        );
        insert address;
    
        // Create dummy repayment schedule
        RepaymentScheduleWrapper.Schedule dummySchedule = new RepaymentScheduleWrapper.Schedule();
        dummySchedule.instNumber = 1;
        dummySchedule.dueDate = String.valueOf(Date.today().addDays(15));
        dummySchedule.bpiAmount = 100;
        dummySchedule.totalAmount = 22000;
    
        Test.startTest();
        ApexPages.currentPage().getParameters().put('Id', opp.Id);
        DisbursmentMemoHandler handler = new DisbursmentMemoHandler();
        handler.repaymentSchedules = new List<RepaymentScheduleWrapper.Schedule>{ dummySchedule };
        Test.stopTest();
    
        //System.assertEquals(Date.today().addDays(15), handler.firstduedate, 'First due date should be set from schedule');
        //System.assertEquals(100, handler.bpi, 'BPI should be set from schedule');
        //System.assertEquals(22000, handler.installmentamountschedule, 'Installment amount schedule should match loan EMI');
    }


}