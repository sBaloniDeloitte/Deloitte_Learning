@isTest class UpsertCustomerHandlerTest {
    
    @testSetup static void dataSetup(){
        
        Opportunity opp= TestDataFactory.getTestOpportunityData(1, false)[0];
        opp.Name = 'Test Loan Opportunity';
        opp.StageName = 'Prospecting';
        opp.CloseDate = System.today().addDays(30);
        opp.Product__c='Home Loan';
        insert opp;
        
        TestDataFactory.setupIntegrationSettings('LoanProcess');
        
        // Create Charges_Insurance_Master__c
        Charges_Insurance_Master__c cim = new Charges_Insurance_Master__c(
            Tax__c = 5,
            Category__c = 'LMS',
            Min_Percent__c = 1,
            Max_Percent__c = 10
        );
        insert cim;
    }
    
    
    
    @isTest
    static void getApplicantAddressTest() {
        TestDataFactory.setupTriggerSettings();
        Opportunity opp= TestDataFactory.getTestOpportunityData(1, false)[0];
        opp.Send_Back_Remarks__c ='{ Send Back }  { PSV to Credit Underwriting } { 05:46:16 PM }  { September 17, 2025 }  { Anshu Sales } {test } || { Send Back }  { PSV to Credit Underwriting } { 06:02:04 PM }  { September 17, 2025 }  { Anshu Sales } {Yes } || { Send Back }  { PSV to Credit Underwriting } { 06:16:46 PM }  { September 17, 2025 }  { Anshu Sales } {Yes } || { Send Back }  { PSV to Credit Underwriting } { 06:38:59 PM }  { September 17, 2025 }  { Anshu Sales } {Yes } || { Send Back }  { PSV to Credit Underwriting } { 06:52:40 PM }  { September 17, 2025 }  { Anshu Sales } {Yes } || { Mark as complete }  { PSV to Disbursement } { 07:41:48 PM }  { September 21, 2025 }  { Anshu Sales } {K } || { Mark as complete }  { PSV to PSV } { 07:48:41 PM }  { September 21, 2025 }  { Anshu Sales } {A } || { Mark as complete }  { PSV to Disbursement } { 07:49:51 PM }  { September 21, 2025 }  { Anshu Sales } {A } || { Mark as complete }  { PSV to PSV } { 07:50:37 PM }  { September 21, 2025 }  { Anshu Sales } {A } || { Mark as complete }  { PSV to PSV } { 07:55:27 PM }  { September 21, 2025 }  { Anshu Sales } {A }';
        insert opp;
        
        PLF_Master__c mas1 = new PLF_Master__c(Name = 'Gender',Master_Type__c = 'Gender', Description__c = 'Male',FICO_Code__c = 'Manu',Gender_Code__c = 'BD');
        PLF_Master__c mas2 = new PLF_Master__c(Name = 'Nationality',Master_Type__c = 'Nationality', Description__c = 'Indian',FICO_Code__c = 'Manu',Gender_Code__c = 'BD');
        PLF_Master__c mas3 = new PLF_Master__c(Name = 'Qualification',Master_Type__c = 'Qualification', Description__c = 'Male',FICO_Code__c = 'Manu',Gender_Code__c = 'BD');
        PLF_Master__c mas4 = new PLF_Master__c(Name = 'Caste',Master_Type__c = 'Caste', Description__c = 'Male',FICO_Code__c = 'Manu',Gender_Code__c = 'BD');
        PLF_Master__c mas5 = new PLF_Master__c(Name = 'Religion',Master_Type__c = 'Religion', Description__c = 'Male',FICO_Code__c = 'Manu',Gender_Code__c = 'BD');
        PLF_Master__c mas6 = new PLF_Master__c(Name = 'Residency Status',Master_Type__c = 'Residency Status', Description__c = 'Male',FICO_Code__c = 'Manu',Gender_Code__c = 'BD');
        PLF_Master__c mas7 = new PLF_Master__c(Name = 'Sub sector',Master_Type__c = 'Sub sector',Sector_Code__c='SENP', Description__c = 'Male',FICO_Code__c = 'Manu',Gender_Code__c = 'BD');
        PLF_Master__c mas8 = new PLF_Master__c(Name = 'Address Type',Master_Type__c = 'Address Type', Description__c = 'Male',FICO_Code__c = 'Manu',Gender_Code__c = 'BD');
        
        insert new List<PLF_Master__c> {mas1,mas2,mas3,mas4,mas5,mas6,mas7,mas8};
            City_Master__c city = TestDataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1,city.Id,true)[0];
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = opp.Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        applicant.Applicant_Type__c ='Primary Applicant';
        insert applicant;
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Customer_Address__c custAddRecord = new Customer_Address__c();
        custAddRecord.Customer__c = customer.Id;
        insert custAddRecord;
        Applicant_Address__c appadd=   TestDataFactory.getTestApplicantAddressData(1, applicant.Id, custAddRecord.Id, pinCode.Id, false)[0];
        appadd.Address_Priority__c = '5';
        appadd.Address_Type__c = 'Permanent';
        appadd.Document_Details__c = TestDataFactory.getTestDocumentDetailsData(1, opp.Id, true)[0].Id;
        appadd.Address_Line_1__c ='djjfd';
        insert appadd;
        TestDataFactory.setupIntegrationSettings('Stage Change');
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('Create Customer');
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.applicantId = applicant.Id;
        Test.startTest();
        Integration_Details__c detail = new Integration_Details__c(
            Name = 'Loan Applicant Hunter',
            Loan_Application__c=opp.Id,
            Endpoint__c = 'https://test.salesforce.com/mock'
        );
        insert detail;
        
        new UpsertCustomerHandler().constructPayload(wrapper, new List<Integration_Details__c>{detail});
        UpsertCustomerHandler.validatePayload(wrapper);
        Test.stopTest();
    }
    
    
}