@IsTest
class AHL_CalculateGstHandlerTest {
    @IsTest
    static void testValidatePayload() {
        // Step 1: Create a Branch record (custom object assumed)
        Account branch = new Account(Name = 'Test Branch', Pincode__c = null);
        insert branch;
        
        // Step 2: Create an Opportunity (Loan Application)
        Opportunity opp = new Opportunity(
            Name = 'Test Loan Application',
            StageName = 'Qualification',
            CloseDate = Date.today(),
            Product__c = 'Home Loan'
        );
        insert opp;
        
        // Step 3: Create Applicant record (lookup to Opportunity assumed)
        Application_Applicant__c  applicant = new Application_Applicant__c (
            Name = 'Test Applicant',
            Applicant_Type__c = 'Primary Applicant',
            Loan_Application__c = opp.Id
        );
        insert applicant;
        
        // Step 4: Create Applicant_Address__c record
        Applicant_Address__c address = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Priority__c = '5',
            Address_Type__c = 'Permanent',
            //Document_Details__c = 'Some Doc',
            Address_Line_1__c = '123 Test Street'
        );
        insert address;
        
        // Step 5: Prepare wrapper
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.recordId = applicant.Id;
        wrapper.productName = 'Test Product';
        wrapper.feeType = 'Test Fee';
        
        // Step 6: Call the method
        List<String> errors = AHL_CalculateGstHandler.validatePayload(wrapper); // Replace YourClassName with actual class name
        
        // Step 7: Assertions
        System.assertNotEquals(null, errors, 'Error messages list should not be null');
        System.assert(errors.contains('Error: Pincode not added in Branch record') || errors.contains('Error: Highest priority address is missing'),
                      'Expected error messages were not returned');
    }
    @isTest
    static void setupData() {
        TestDataFactory.setupIntegrationSettings('Loan Applicant Account Aggregator');
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('Loan URL Shortening Service');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Hunter');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Net Banking');
        TestDataFactory.setupTriggerSettings();
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, false)[0];
        insert loanApp;
        
        City_Master__c city = TestDataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1,city.Id,true)[0];
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loanApp.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = loanApp.Id;
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
        appadd.Address_Type__c = 'Local';
        appadd.Document_Details__c = TestDataFactory.getTestDocumentDetailsData(1, loanApp.Id, true)[0].Id;
        appadd.Address_Line_1__c ='djjfd';
        insert appadd;
        
        Integration_Details__c objintegrationDetails = new Integration_Details__c();
        objintegrationDetails.Loan_Application__c = loanApp.Id;
        objintegrationDetails.Name = 'test';
        objintegrationDetails.Related_Record_Id__c = loanApp.Id;
        objintegrationDetails.Endpoint__c = 'www.salesforce.com';
        insert objintegrationDetails;
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        Map<String, String> inputMap = new Map<String, String>{
            'recordId' => loanApp.Id,
                'applicantId' => applicant.Id,
                'processName' => 'CalculateGST',
                'mobileNumber' => applicant.Mobile_Number__c,
                'isWaiverAmountCalc' => 'false'
                };
                    
                    List<Integration_Master__mdt> metadataList = [
                        SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, 
                        Client_Id__c, Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, 
                        Refresh_Allowed__c, Activity_Name__c
                        FROM Integration_Master__mdt 
                        WHERE Activity_Name__c = 'CalculateGST' 
                        LIMIT 1
                    ];
        String loanId = inputMap.get('loanId');
        String processName = inputMap.get('processName');
        String feeType = inputMap.get('feeType');
        String waiverAmountCalcFlag = inputMap.get('isWaiverAmountCalc');
        Boolean isWaiverAmountCalc = Boolean.valueOf(waiverAmountCalcFlag);
        Product2 prod = new Product2(Name = 'Test Product', Product_Type__c = 'Parent');
        insert prod;
        
        Charges_Insurance__c insuranceRecord = new Charges_Insurance__c(
            Name = 'Insurance Record', // this must match feeType in wrapper
            Loan_Application__c = loanApp.Id,
            Product__c = prod.Id, // link product
            Requested_Amount_INR__c = 1000,
            GST_Exempt__c = 'E',
            Default_Amount_INR__c = 1200,
            Adjusted_Login_Fee__c = 200,
            Balance_Fees__c = 1000,
            Waived_Charge_Amount__c = 0
        );
        insert insuranceRecord;
        Integration_Master__mdt metadata = metadataList[0];
        // Prepare request wrapper
        wrapper.loanApplicationId = loanApp.Id;  
        wrapper.type = processName;
        wrapper.feeType = 'Insurance Record';
        wrapper.endpoint = metadata.Endpoint__c;
        wrapper.requestMethod = metadata.Request_Method__c;
        wrapper.handlerClass = metadata.Handler_Class__c;
        wrapper.clientId = metadata.Client_Id__c;
        wrapper.clientSecret = metadata.Client_Secret__c;
        wrapper.allowedRetry = metadata.Allowed_Retry__c;
        wrapper.gestationPeriod = metadata.Gestation_Period__c;
        wrapper.activityname = metadata.Activity_Name__c;
        wrapper.refreshallowed = metadata.Refresh_Allowed__c;
        wrapper.handlername = metadata.Handler_Class__c;
        wrapper.isWaiverAmountCalc = true;
        wrapper.productName = prod.Id;
        Map<String, Schema.RecordTypeInfo> insuranceRecordTypeMap = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName();
        Id insuranceRecordTypeId = insuranceRecordTypeMap.get('Insurance').getRecordTypeId();
        new AHL_CalculateGstHandler().constructPayload(wrapper, new List<Integration_Details__c> {objintegrationDetails});        
    }
}