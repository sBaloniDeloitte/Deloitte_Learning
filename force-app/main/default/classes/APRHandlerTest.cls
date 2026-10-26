@isTest
public class APRHandlerTest {
    @testSetup static void setupData(){
        Trigger_Settings__c triggerSettings = new Trigger_Settings__c(
            Name='Trigger Settings',
            Application_Applicant_Trigger__c = true, 
            City_Master_Trigger__c = true, 
            Lead_Trigger__c = true, 
            Opportunity_Trigger__c = true, 
            Application_Verification_Trigger__c = true
        );
        insert triggerSettings;
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        List<Opportunity> oppRecList = TestDataFactory.getTestOpportunityData(1, false);
        oppRecList[0].Product__c = 'Flexi Loan';
        insert oppRecList;
        OpportunityTeamMember teamMember = new OpportunityTeamMember();
        teamMember.OpportunityId = oppRecList[0].Id;
        teamMember.TeamMemberRole = 'Sales Manager';
        teamMember.UserId = userInfo.getUserId();
        insert teamMember;
        Product2 mainProduct = new Product2();
        mainProduct.Name = 'Flexi Loan';
        mainProduct.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        mainProduct.Loan_Application__c = oppRecList[0].Id;
        insert mainProduct;
        // Create Sub Product (RecordType = 'Sub Product')
        Product2 subProduct = new Product2();
        subProduct.Name = 'Sub Product';
        subProduct.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
        subProduct.Loan_Application__c = oppRecList[0].Id;
        subProduct.Product__c = mainProduct.Id;
        insert subProduct;
        Product2 subProduct3 = new Product2();
        subProduct3.Name = 'Sub Product3';
        subProduct3.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();
        subProduct3.Loan_Application__c = oppRecList[0].Id;
        subProduct3.Product__c = subProduct.Id;
        insert subProduct3;
		   // Create Loan Transaction
        RecordType transRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Loan_Transaction__c' AND DeveloperName = 'Transaction_Details' LIMIT 1];
        Loan_Transaction__c trans = new Loan_Transaction__c(
            Loan_Application__c = oppRecList[0].Id,
            Disbursement_Amount__c = 100000,
            Allow_Payment_in_Grace_Period__c = true,
            Allow_Grace__c = true,
            TDS_Applicable__c = true,
            Step_Loan__c = false,
            Grace_Period_Frequency__c = 1,
            Allow_BPI__c = true,
            Allow_Planned_EMI_Holiday__c = true,
            Allow_Planned_EMI_Holiday_in_Grace__c = false,
            Max_per_Year__c = 1,
            Max__c = 2,
            Lock_Period_Months__c = 3,
            Capitalize__c = true,
            Rate_Type__c = 'R',
            First_Disbursement_Amount__c = 100000,
            RecordTypeId = transRT.Id
        );
        insert trans;

        // Create Charges records
        RecordType chargesRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Charges_Insurance__c' AND Name = 'Charges' LIMIT 1];

        insert new Charges_Insurance__c(
            Loan_Application__c = oppRecList[0].Id,
            RecordTypeId = chargesRT.Id,
            Category__c = 'LMS',
            Charges_Fee_Type__c = 'PPMCHG',
            Default_Percentage__c = null,
            Requested_Percentage__c = null
        );

        insert new Charges_Insurance__c(
            Loan_Application__c = oppRecList[0].Id,
            RecordTypeId = chargesRT.Id,
            Category__c = 'LOS',
            Charges_Fee_Type__c = 'PROCFEE',
            Default_Amount_INR__c = 5000,
            Requested_Amount_INR__c = 5500,
            Final_Amount_INR__c = null
        );

        insert new Charges_Insurance__c(
            Loan_Application__c = oppRecList[0].Id,
            RecordTypeId = chargesRT.Id,
            Category__c = 'Insurance',
            Charges_Fee_Type__c = 'PROCFEE',
            Total_VAS_Amount__c = null
        );
    }
    @isTest static void testGetConstants() {
        Test.startTest();
        Map<String, String> result = APRHandler.getConstants();
        Test.stopTest();

    }
    @isTest static void testValidatePayloadNullLoanApp(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.Final_Tenure__c = null;
        update opp;
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        
        wrapper.loanApplicationId = opp.Id;
        try{
         	APRHandler.validatePayload(wrapper);   
        }catch(Exception ex){}
        
    }
    @isTest static void testValidatePayloadNullLoanTransction(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        delete [SELECT Id FROM Loan_Transaction__c];
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        
        wrapper.loanApplicationId = opp.Id;
        try{
         	APRHandler.validatePayload(wrapper);   
        }catch(Exception ex){}
        
    }
    @isTest static void testValidatePayloadNullLoanTransction2(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Loan_Transaction__c loanTrans = [SELECT Id FROM Loan_Transaction__c];
        loanTrans.First_Disbursement_Amount__c = null;
        update loanTrans;
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        
        wrapper.loanApplicationId = opp.Id;
        try{
         	APRHandler.validatePayload(wrapper);   
        }catch(Exception ex){}
        
    }
    @isTest static void formatDateStringTest(){
        APRHandler.formatDateString(date.today());
    }
    @isTest static void constructPayloadTest(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        List<Integration_Details__c> integrationDetails = new List<Integration_Details__c>();
        try{
            APRHandler handler = new APRHandler();
         	handler.constructPayload(wrapper, integrationDetails);   
        }catch(Exception ex){}
    }
}