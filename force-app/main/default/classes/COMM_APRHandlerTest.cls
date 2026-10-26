@isTest
public class COMM_APRHandlerTest {
    /*
@isTest
    static void testValidatePayload_AllValidData() {
     

        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
               
        Opportunity opp2 = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Sales login',
            CloseDate = Date.today(),
            AccountId = customer.Id,
             Product__c = 'Home Loan',
            Primary_LAN__c ='GFL3001BL0001834' 
        );
        insert opp2;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Sales login',
            CloseDate = Date.today(),
            AccountId = customer.Id,
             Product__c = 'Home Loan',
            Primary_LAN__c ='GFL3001BL0001834' ,
            Loan_Hierarchy__c = 'Child' ,
            Split_Parent_Loan_Application__c	= opp2.id
            
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
        

            // Insert Integration_Details__c
            Integration_Details__c integrationDetail = new Integration_Details__c(
                Name = 'Loan Scheduler Create Charges',
                Business_Date__c = Date.today(),
                Endpoint__c = 'https://mockapi.example.com/schedule',
                Object_Name__c = 'Opportunity'
            );
            insert integrationDetail;
 
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
            Name = 'Home Loan',
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
        
        RecordType chargesRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Charges_Insurance__c' AND DeveloperName  = 'Charges' LIMIT 1];


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
            Total_VAS_Amount__c = 1500, 
            	Product__c = mainProduct.id
        );
        insert chargeRec;
        // Prepare wrapper
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;

  List<Charges_Insurance__c> chargesList = [Select Id, Category__c, Charges_Fee_Type__c, Final_Amount_INR__c, Default_Amount_INR__c, Requested_Amount_INR__c,
                                                    Default_Percentage__c, Requested_Percentage__c, Total_VAS_Amount__c
                                                    From Charges_Insurance__c Where Loan_Application__c = : opp.Id
                                                    And RecordType.Name = 'Charges' And Charges_Fee_Type__c != '' AND Product_Name__c = 'Home Loan'];
system.debug('chargesList-->'+ chargesList);
        Test.startTest();
        List<String> errors = COMM_APRHandler.validatePayload(wrapper); // Replace with actual class name
        Test.stopTest();

    }

    @isTest
    static void testValidatePayload_AllValidData2() {
     

        // Create test Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Open',
            CloseDate = Date.today(),
            Final_Amount__c = 1000000,
            Sanction_Tenure__c = 12,
            Final_Tenure__c = 12,
            Product__c='Affordable Home Loan',
            Final_Rate_Of_Interest__c = 8.5,
            Primary_LAN__c ='GFL3001BL0001834'
        );
        insert opp;

        // Create Product hierarchy
        RecordType productRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND Name = 'Product' LIMIT 1];
          Id subProductRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Product').getRecordTypeId();   
        RecordType variantRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND Name = 'Variant' LIMIT 1];

        Product2 mainProd = new Product2(Name = 'Affordable Home Loan', Loan_Application__c = opp.Id, RecordTypeId = productRT.Id, isActive = true);
        insert mainProd;

        Product2 subProd = new Product2(Name = 'Affordable Home Loan', Product__c = mainProd.Id, Loan_Application__c = opp.Id, RecordTypeId = subProductRT, isActive = true);
        insert subProd;

        Product2 variant = new Product2(Name = 'Over Draft', Product__c = subProd.Id, Loan_Application__c = opp.Id, RecordTypeId = variantRT.Id, isActive = true);
        insert variant;

        // Create Loan Transaction
        RecordType transRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Loan_Transaction__c' AND DeveloperName = 'Transaction_Details' LIMIT 1];
        Loan_Transaction__c trans = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
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
            Loan_Application__c = opp.Id,
            RecordTypeId = chargesRT.Id,
            Category__c = 'LMS',
            Charges_Fee_Type__c = 'PPMCHG',
            Default_Percentage__c = 1,
            Requested_Percentage__c = 1.5
        );

        insert new Charges_Insurance__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = chargesRT.Id,
            Category__c = 'LOS',
            Charges_Fee_Type__c = 'PROCFEE',
            Default_Amount_INR__c = 5000,
            Requested_Amount_INR__c = 5500,
            Final_Amount_INR__c = 5300
        );

        insert new Charges_Insurance__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = chargesRT.Id,
            Category__c = 'Insurance',
            Total_VAS_Amount__c = 1000
        );

        // Prepare wrapper
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;

        Test.startTest();
        List<String> errors = COMM_APRHandler.validatePayload(wrapper); // Replace with actual class name
        Test.stopTest();

    }

    @isTest
    static void testValidatePayload_MissingData_ShouldReturnErrors() {
        Opportunity opp = new Opportunity(Name = 'Missing Fields Loan', StageName = 'Open', CloseDate = Date.today(), Primary_LAN__c ='GFL3001BL0001834' ,
                                          Product__c='Affordable Home Loan');
        insert opp;

        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;

        Test.startTest();
        try{
        List<String> errors = COMM_APRHandler.validatePayload(wrapper); // Replace with actual class name
        }
        catch(exception ex){}
        Test.stopTest();

    }
    
    /*@isTest
    static void testConstructPayload() {
       
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Sales login',
            CloseDate = Date.today(),
            AccountId = customer.Id,
            Primary_LAN__c ='GFL3001BL0001834'
        );
        insert opp;
        
        opp.Final_Amount__c = 500000;                  // Example Final Amount
        opp.Sanction_Tenure__c = 24;                   // Example Tenure in months
        opp.Variant__c = 'Term Loan';                   
        opp.Final_Tenure__c = 24;
        opp.Final_Rate_Of_Interest__c = 11.25;  
        opp.Primary_LAN__c ='GFL3001BL0001834';
        opp.Product__c ='Affordable Home Loan';
        
        update opp;       
        
        Id ProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        // Create Main Product
        Product2 mainProduct = new Product2(
            Name = 'Affordable Home Loan',
            Loan_Application__c = opp.Id,
            RecordTypeId = ProductRecordTypeId,
            IsActive = true
        );
        insert mainProduct;
   Id subProductRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Product').getRecordTypeId();   

        Product2 prod2 = new Product2(
            Name = 'Term Loan',
            Product__c = mainProduct.Id,
            Loan_Application__c = opp.Id, 
            RecordTypeId = subProductRT,
            IsActive = true
        );
        insert prod2;
        
         Id variantRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Variant').getRecordTypeId();       
       
        Product2 prod3 = new Product2(
            Name = 'Over Draft',
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
       
        RecordType chargesRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Charges_Insurance__c' AND Name = 'Charges' LIMIT 1];

        insert new Charges_Insurance__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = chargesRT.Id,
            Category__c = 'LOS',
            Charges_Fee_Type__c = 'PROCFEE',
            Default_Amount_INR__c = 5000,
            Requested_Amount_INR__c = 5500,
            Final_Amount_INR__c = 5300
        );
        // Create mock wrapper object
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;

        // Create mock integration settings
        List<Integration_Details__c> integrationSettings = new List<Integration_Details__c>();
        integrationSettings.add( new Integration_Details__c(
            Calling_Source__c = 'TestSource',
            Request_JSON__c = '{"key":"value"}',
            Response_JSON__c = '{"result":"success"}',
           // Status__c = 'Success',
            Method_Type__c = 'POST',
            EndPoint__c = 'https://test.endpoint.com',
            Object_Name__c = 'TestObject',
            Related_Record_Id__c = '1234567890ABCDEF',
            Name = 'Sanction Letter Generation',
            Loan_Application__c = opp.Id
        ));
        insert integrationSettings;
        // Call the method to be tested
        String result = new COMM_APRHandler().constructPayload(wrapper, integrationSettings);

    }*/
   /*  @isTest
    static void testGetConstants() {
        Test.startTest();
        Map<String, String> result = COMM_APRHandler.getConstants();
        Test.stopTest();

    } */
}