@isTest
public class APRControllerTest {


    @isTest static void test1(){
        TestDataFactory.setupTriggerSettings();
          TestDataFactory.setupIntegrationSettings('Loan APR Calculation');
          TestDataFactory.setupIntegrationSettings('Get Token');
      
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, false)[0];
        loanApp.Final_Amount__c= 196;
        loanApp.Sanction_Tenure__c =200;
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
        
            Map<String, String> inputMap = new Map<String, String>{
            'loanId' => loanApp.Id,
            'processName' => 'Loan APR Calculation'
        };

            Loan_Transaction__c loanTxn = new Loan_Transaction__c(
            Loan_Application__c = loanApp.Id,
            RecordTypeId = SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByDeveloperName()
            .get('Transaction_Details')
            .getRecordTypeId(),
            isActive__c = false,Step_Loan__c = true,Interest_Frequency__c= 'H',
            Allow_Grace__c = true,First_Disbursement_Amount__c= 45,
            Allow_BPI__c = true,Allow_Planned_EMI_Holiday__c = true,Allow_Planned_Principal_Holiday__c =true
        );
        insert loanTxn;
        Integration_Details__c detail = new Integration_Details__c(
            Name = 'Loan Applicant Hunter',
            Loan_Application__c=loanApp.Id,
            Endpoint__c = 'https://test.salesforce.com/mock'
        );
        insert detail;
        
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Product2.getRecordTypeInfosByName();
        Id totalTenureRecordTypeId  = rtMap.get('Total Tenure').getRecordTypeId();
        Id hybridTenureRecordTypeId = rtMap.get('Hybrid Tenure').getRecordTypeId();
        Id schemeRecordTypeId       = rtMap.get('Scheme').getRecordTypeId();
        Id fullEMIRecordTypeId      = rtMap.get('Full EMI').getRecordTypeId();
        Id variantRecordTypeId      = rtMap.get('Variant').getRecordTypeId();
        Id subVariantRecordTypeId      = rtMap.get('Sub Variant').getRecordTypeId();
        Id productRT = rtMap.get('Product').getRecordTypeId();
        Id subProductRT = rtMap.get('Sub Product').getRecordTypeId();
        
        Product_Master__c prodM2 = new Product_Master__c(
            Name = 'Variant',
            PLF_Loan_Type__c ='FL',
            PLR_Value__c = 80.00,
            RecordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Variant').getRecordTypeId()
        );
        insert prodM2;
        
        Product2 mainProduct = TestDataFactory.createProductRecord(loanApp.Product__c, true);
        mainProduct.Product_Master__c = prodM2.Id;
        mainProduct.recordTypeId = productRT;
        mainProduct.Loan_Application__c = loanApp.Id;
        insert mainProduct;
        
        Product2 subProduct = new Product2(
            Name = 'Sub Product',
            isActive = true,
            Loan_Application__c = loanApp.Id,
            Product__c = mainProduct.Id,
            RecordTypeId =  subProductRT 
        );
        insert subProduct;
        
        
        
        List<Product2> productsToInsert = new List<Product2>();
        
        Product2 TotalTenure = new Product2(
            Name = 'Total Tenure',
            isActive = true,
            Loan_Application__c = loanApp.Id,
            Product__c = subProduct.Id,
            RecordTypeId = totalTenureRecordTypeId,
            Variant__c = mainProduct.Id,
            Sub_Variant__c = subProduct.Id
        );
        
        Product2 scRec=   new Product2(
            Name = 'Scheme Rec',
            isActive = true,
            Loan_Application__c = loanApp.Id,
            Product__c = subProduct.Id,
            RecordTypeId = schemeRecordTypeId,
            Variant__c = mainProduct.Id,
            Sub_Variant__c = subProduct.Id
        );
        Product2 varient=  new Product2(
            Name = 'Variant',
            isActive = true,
            Loan_Application__c = loanApp.Id,
            Product__c = subProduct.Id,
            RecordTypeId = variantRecordTypeId,
            EMI_Amount__c = 10000,
            Variant__c = mainProduct.Id,
            Sub_Variant__c = subProduct.Id
        );
        Product2 subVarient= new Product2(
            Name = 'Sub Variant',
            isActive = true,
            Loan_Application__c = loanApp.Id,
            Product__c = subProduct.Id,
            RecordTypeId = subVariantRecordTypeId,
            EMI_Amount__c = 10000,
            Variant__c = mainProduct.Id,
            Sub_Variant__c = subProduct.Id
        );
        Product2 fullemi =
            new Product2(
                Name = 'Full EMI',
                isActive = true,
                Loan_Application__c = loanApp.Id,
                Product__c = subProduct.Id,
                RecordTypeId = fullEMIRecordTypeId,
                EMI_Amount__c = 10000,
                Variant__c = mainProduct.Id,
                Sub_Variant__c = subProduct.Id
            );
        
        insert new list<Product2>{TotalTenure,scRec,subVarient,varient,fullemi};
            
            
            insert  new Product2(
                Name = '100',
                isActive = true,
                Loan_Application__c = loanApp.Id,
                Product__c = subProduct.Id,
                RecordTypeId = hybridTenureRecordTypeId,
                Variant__c = varient.Id,
                Sub_Variant__c = subVarient.Id
            );
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        APRController.initiateAPRAPIRequest(inputMap);
        TEst.stopTest();
    }
    
    
    @isTest
    static void testInitiateAPRAPIRequest_Success() {
       

        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = new Opportunity(
            //Name = 'Test Opportunity',
            StageName = 'Sales login',
            CloseDate = Date.today(),
            AccountId = customer.Id,
             Product__c = 'Home Loan',
            Primary_LAN__c ='GFL3001BL0001834'
        );
        insert opp;
        
        opp.Final_Amount__c = 500000;                  // Example Final Amount
        opp.Sanction_Tenure__c = 24;                   // Example Tenure in months
        opp.Variant__c = 'Term Loan';                   
        opp.Final_Tenure__c = 24;
        opp.Final_Rate_Of_Interest__c = 11.25;  
        opp.Primary_LAN__c ='GFL3001BL0001834';
        
        update opp;        
        // Create Integration Settings
        Integration_Settings__c settings = new Integration_Settings__c(
            Name = 'Loan APR Calculation',
            Client_Id__c = 'client_id',
            Client_Secret__c = 'client_secret',
            Endpoint__c = 'https://example.com/apr',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c = 'Bearer',
            Cookie__c = 'test'
        );
        insert settings;
        
        Integration_Settings__c settings2 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'client_id',
            Client_Secret__c = 'client_secret',
            Endpoint__c = 'https://example.com/apr',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Authorization__c = 'Bearer',
            Cookie__c = 'test'
        );
        insert settings2;
        

            /*// Insert Integration_Details__c
            Integration_Details__c integrationDetail = new Integration_Details__c(
                Name = 'Loan Scheduler Create Charges',
                Business_Date__c = Date.today(),
                Endpoint__c = 'https://mockapi.example.com/schedule',
                Object_Name__c = 'Opportunity'
            );
            insert integrationDetail;*/
 
        // Create Product2 linked to Opp
        Product_Master__c prodM2 = new Product_Master__c(
            Name = 'Sub Product A',
            RecordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Variant').getRecordTypeId()
        );
        insert prodM2;

          Id subProductRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Product').getRecordTypeId();   
        Id variantRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Variant').getRecordTypeId();       
        Id ProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        // Create Main Product
        Product2 mainProduct = new Product2(
            Name = 'Business Loan',
            Loan_Application__c = opp.Id,
            RecordTypeId = ProductRecordTypeId,
            IsActive = true
        );
        insert mainProduct;

        Product2 prod2 = new Product2(
            Name = 'Term Loan',
            Product__c = mainProduct.Id,
            Loan_Application__c = opp.Id, 
            RecordTypeId = subProductRT,
            IsActive = true
        );
        insert prod2;
        
        Product2 prod = new Product2(
            Name = 'Over Draft',
            Loan_Application__c = opp.Id, 
            RecordTypeId = subProductRT,
            IsActive = true
        );
        insert prod;
        
        Product2 prod3 = new Product2(
            Name = 'Term Loan',
            Loan_Application__c = opp.Id, 
            Product__c = prod2.Id,
            RecordTypeId = variantRT,
            IsActive = true
        );
        insert prod3;
        
        Loan_Transaction__c lt = FITestDataFactory.createLoanTransactiondata(opp);
        lt.Allow_BPI__c =false;
        lt.Allow_Planned_EMI_Holiday__c = false;
        lt.Lock_Period_Months__c = 1;
        lt.Capitalize__c = false;
        update lt;
        // Create Charges_Insurance_Master__c
        Charges_Insurance_Master__c cim = new Charges_Insurance_Master__c(
            Charges_Fee_Type__c = 'Miscellaneous charges',
            Default_Value__c = 2,
            Max_Percent__c = 4,
            Min_Percent__c = 1,
            Category__c = 'LMS',
            Sub_Product__c = prodM2.Id
        );
        insert cim;
        
        Charges_Insurance_Master__c cim2 = new Charges_Insurance_Master__c(
            Charges_Fee_Type__c = 'Miscellaneous charges',
            Max_Percent__c = 4,
            Min_Percent__c = 1,
            Category__c = 'LOS',
            Is_Active__c=TRUE
        );
        insert cim2;
        
        RecordType chargesRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Charges_Insurance__c' AND Name = 'Charges' LIMIT 1];

        Charges_Insurance__c chargeRec = new Charges_Insurance__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = chargesRT.Id,
            Charges_Fee_Type__c = 'PPMCHG', 
            Category__c = 'LMS',
            Final_Amount_INR__c = 1500,
            Default_Amount_INR__c = 1000,
            Requested_Amount_INR__c = 1200,
            Default_Percentage__c = 10,
            Requested_Percentage__c = 12,
            Total_VAS_Amount__c = 1500
        );
        insert chargeRec;
        
        // Set up mocks by swapping out real utility with the mock one
        Test.startTest();

        // Replace Utility method calls with mocks
        // This assumes you inject/mock Utility class using dependency injection or design pattern in real code

        // Mock `IntHandler.validateProcess`
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
            'processName' => 'Loan APR Calculation'
        };

        String result = APRController.initiateAPRAPIRequest(inputMap);
        Test.stopTest();
    }

    @isTest
    static void testInitiateAPRAPIRequest_MissingParams() {
        Map<String, String> inputMap = new Map<String, String>{};
        String result = APRController.initiateAPRAPIRequest(inputMap);
    }

    @isTest
    static void testInitiateAPRAPIRequest_MetadataMissing() {
        Opportunity opp = new Opportunity(Name = 'Test Loan',  Product__c = 'Home Loan', StageName = 'Submitted', CloseDate = Date.today(),Primary_LAN__c ='GFL3001BL0001834');
        insert opp;

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
            'processName' => 'InvalidProcess'
        };

        String result = APRController.initiateAPRAPIRequest(inputMap);
    }

    // Mock IntHandler class
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse resp = new HTTPResponse();
            resp.setStatusCode(200);
            APRController.APRResponseWrapper wrapper = new APRController.APRResponseWrapper();
            wrapper.apr = 12.34;
            resp.setBody(JSON.serialize(wrapper));
            return resp;
        }
    }
    
}