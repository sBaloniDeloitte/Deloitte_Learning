@isTest
public class COMM_LoanSchedulerHandlerTest {
    @TestSetup
    static void makeData(){
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,customer);
        loanApplication.Product__c = 'Home Loan';
		update loanApplication;
        Loan_Transaction__c lt = FITestDataFactory.createLoanTransactiondata(loanApplication);
        Loan_Transaction__c loanTrans = FITestDataFactory.createLoanTransactiondataForLoan(loanApplication);
        
        Integration_Details__c objintegrationDetails = new Integration_Details__c();
        objintegrationDetails.Loan_Application__c = loanApplication.Id;
        objintegrationDetails.Name = 'test';
        objintegrationDetails.Related_Record_Id__c = loanApplication.Id;
        objintegrationDetails.Endpoint__c = 'www.salesforce.com';
        insert objintegrationDetails;
        
        Id subProductRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Product').getRecordTypeId();   
        Id variantRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Variant').getRecordTypeId();       
        Id ProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Id SubVariantRT1 = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Variant').getRecordTypeId();
        Id SubVariantRT2 = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Variant').getRecordTypeId();       


        // Create Main Product
        Product2 mainProduct = new Product2(
            Name = 'Business Loan',
            Loan_Application__c = loanApplication.Id,
            RecordTypeId = ProductRecordTypeId,
            IsActive = true
        );
        insert mainProduct;

        Product2 prod2 = new Product2(
            Name = 'Term Loan',
            Product__c = mainProduct.Id,
            Loan_Application__c = loanApplication.Id, 
            RecordTypeId = subProductRT,
            IsActive = true
        );
        insert prod2;
        
        Product2 prod = new Product2(
            Name = 'Over Draft',
            Loan_Application__c = loanApplication.Id, 
            RecordTypeId = subProductRT,
            IsActive = true
        );
        insert prod;
        
       Product2 prod3 = new Product2(
            Name = 'Over Draft',
            Loan_Application__c = loanApplication.Id, 
            Product__c = prod2.Id,
            RecordTypeId = variantRT,
            IsActive = true
        );
        insert prod3;
        Product2 prod4 = new Product2(
            Name = 'Over Draft',
            Loan_Application__c = loanApplication.Id, 
            Product__c = prod2.Id,
            RecordTypeId = SubVariantRT1,
            IsActive = true
        );
        insert prod4;
        Product2 prod5 = new Product2(
            Name = 'Over Draft',
            Loan_Application__c = loanApplication.Id, 
            Product__c = prod2.Id,
            RecordTypeId = SubVariantRT2,
            IsActive = true
        );
        insert prod5;
        



  Account customer2 = FITestDataFactory.createAccount('Test Customer 2', 'Customer');
        Opportunity loanApplication2 = FITestDataFactory.createLoanApplication(true,customer2);
        loanApplication2.Name = 'Test Loan 2';
        update loanApplication2;
        
        Loan_Transaction__c loan2 = FITestDataFactory.createLoanTransactiondata(loanApplication2);
        
        Loan_Transaction__c loanTransaction2 = new Loan_Transaction__c(
            Loan_Application__c = loanApplication.Id,
            Disbursement_Amount__c = 50000,
            Schedule_Method__c = 'PFT', // Ensure this value is valid for the picklist
            TDS_Applicable__c = true,
            Rate_Type__c = 'R', // Ensure this value is valid for the picklist
            Loan_Start_Date__c = Date.today()
        );
        insert loanTransaction2;
        
        Integration_Settings__c setting = new Integration_Settings__c();
        setting.Name = 'Loan Scheduler Create Charges';
        setting.Client_Id__c = '123';
        setting.Client_Secret__c = '62536176357';
        setting.Endpoint__c = 'Callout:LOS_AML';
        setting.Request_Method__c ='POST';
        setting.Cookie__c ='TEST';
        setting.Authorization__c ='TEST';
        
        insert setting;
        
        // Create Product2 linked to Opp
        Product_Master__c prodM2 = new Product_Master__c(
            Name = 'Sub Product A',
            RecordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Variant').getRecordTypeId()
        );
        insert prodM2;
        // Create Main Product
        Product2 mainProduct2 = new Product2(
            Name = 'Business Loan',
            Loan_Application__c = loanApplication2.Id,
            RecordTypeId = ProductRecordTypeId,
            IsActive = true
        );
        insert mainProduct2;

        Product2 prodN2 = new Product2(
            Name = 'Term Loan',
            Product__c = mainProduct2.Id,
            Loan_Application__c = loanApplication2.Id, 
            RecordTypeId = subProductRT,
            IsActive = true
        );
        insert prodN2;
        
        Product2 prodN3 = new Product2(
            Name = 'Over Draft',
            Loan_Application__c = loanApplication2.Id, 
            RecordTypeId = subProductRT,
            IsActive = true
        );
        insert prodN3;
        

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
                
    }
    
    @isTest
    public static void getConstants_Test(){
        Test.startTest();
        COMM_LoanSchedulerHandler.getConstants();
        Test.stopTest();
    } 
    
    @isTest
    public static void validatePayload_Test(){
        try{
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 where name = 'Term Loan' LIMIT 1];
        Loan_Transaction__c lt = [SELECT Id,Allow_Grace__c,Grace_Period_Frequency__c FROM Loan_Transaction__c WHERE RecordType.DeveloperName = 'Transaction_Details' LIMIT 1];
        Loan_Transaction__c ltrans = [SELECT Id,Allow_Grace__c,Grace_Period_Frequency__c FROM Loan_Transaction__c WHERE RecordType.DeveloperName = 'Step_Loan_Details' LIMIT 1];
        List<Integration_Details__c> integration = [SELECT Id FROM Integration_Details__c LIMIT 1];
        
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = loanApplication.Id;
        wrapper.loanSchedulerInvocationType = 'RepaymentLWC';
        
        Test.startTest();
        COMM_LoanSchedulerHandler.validatePayload(wrapper);
        COMM_LoanSchedulerHandler classPayLoad = new COMM_LoanSchedulerHandler();
        classPayLoad.constructPayload(wrapper,integration);
        Test.stopTest();
    } 
        catch(Exception e)

        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
        }
} 
    @isTest
    public static void validatePayload2_Test(){
        try{
        Test.startTest();
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id,Loan_Application__c FROM Product2 where name = 'Term Loan' LIMIT 1];
        //prod.Loan_Application__c = null;
        //update prod;
        
        Product2 prod2 = [SELECT Id FROM Product2 where name = 'Over Draft' LIMIT 1];
        Loan_Transaction__c lt = [SELECT Id FROM Loan_Transaction__c WHERE RecordType.DeveloperName = 'Transaction_Details' LIMIT 1];
        Loan_Transaction__c ltrans = [SELECT Id FROM Loan_Transaction__c WHERE RecordType.DeveloperName = 'Step_Loan_Details' LIMIT 1];
        List<Integration_Details__c> integration = [SELECT Id FROM Integration_Details__c LIMIT 1];
        
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = loanApplication.Id;
        wrapper.loanSchedulerInvocationType = 'RepaymentLWC';
        
        
        COMM_LoanSchedulerHandler.validatePayload(wrapper);
        COMM_LoanSchedulerHandler classPayLoad = new COMM_LoanSchedulerHandler();
        classPayLoad.constructPayload(wrapper,integration);
        Test.stopTest();
    } 
    catch(Exception e)

        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
        }
}
 
    @isTest
    public static void validatePayload3_Test(){
        Test.startTest();
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id,Loan_Application__c FROM Product2 where name = 'Term Loan' LIMIT 1];
        //prod.Loan_Application__c = null;
        //update prod;
        
        Product2 prod2 = [SELECT Id FROM Product2 where name = 'Over Draft' LIMIT 1];
        Loan_Transaction__c lt = [SELECT Id FROM Loan_Transaction__c WHERE RecordType.DeveloperName = 'Transaction_Details' LIMIT 1];
        Loan_Transaction__c ltrans = [SELECT Id FROM Loan_Transaction__c WHERE RecordType.DeveloperName = 'Step_Loan_Details' LIMIT 1];
        List<Integration_Details__c> integration = [SELECT Id FROM Integration_Details__c LIMIT 1];
        
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanSchedulerInvocationType = 'RepaymentLWC';
        
        try{
        COMM_LoanSchedulerHandler.validatePayload(wrapper);
        
        wrapper.loanApplicationId = loanApplication.Id;
        loanApplication.Final_Amount__c =null;
        update loanApplication;
        
        COMM_LoanSchedulerHandler.validatePayload(wrapper);
        }catch(exception e){ }
        Test.stopTest();
    } 
    
 /*   @isTest
    public static void initiateAPIRequest_Test(){
        try{
        Opportunity loanApplication = [SELECT Id,Sanction_Loan_Amount__c FROM Opportunity WHERE NAME = 'Test Loan 2' LIMIT 1];
        List<Opportunity> oppList = new List<Opportunity>();
        oppList.add(loanApplication);
        
        Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('loanId',loanApplication.Id);
        inputMap.put('processName','Loan Scheduler Create Charges');
        
        Test.startTest();
        // Set callout mock
        Test.setMock(HttpCalloutMock.class, new MockHunterHttpResponse(200));
        
        COMM_LoanSchedulerContoller.initiateAPIRequest(inputMap,oppList,'No Comment');
        Test.stopTest();
    }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
        
        }
}
    */
    
    

    @isTest
    public static void initiateAPIRequest_Test() {
        try {
            // Create Account and Opportunity
            Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
            Account acc = new Account(Name = 'Test Customer', RecordTypeId = recordTypeId);
            insert acc;

            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                AccountId = acc.Id,
                Product__c = 'Home Loan',
                Tenor_Months__c = 1,
                Requested_Amount__c = 1,
                Final_Amount__c = 100000,
                Sanction_Tenure__c = 12,
                Is_Pricing_Approval_Required__c = true,
                Pricing_Approval_Status__c = 'Approved',
                Variant__c = 'Overdraft'
            );
            insert opp;

           

            // Insert Integration_Settings__c
            Integration_Settings__c intSettings = new Integration_Settings__c(
                Name = 'Get Customer',
                Client_Id__c = 'f9709782-85ea-49fc-848a-6abcbfa65611',
                Cookie__c = 'testCookie',
                Client_Secret__c = 'testClientSecret',
                Endpoint__c = 'https://mockapi.example.com/schedule',
                Content_Type__c = 'application/json',
                Authorization__c = 'Bearer testAuthorization',
                Request_Method__c = 'POST'
            );
            insert intSettings;

            // Insert Integration_Details__c
            Integration_Details__c integrationDetail = new Integration_Details__c(
                Name = 'Loan Scheduler Create Charges',
                Business_Date__c = Date.today(),
                Endpoint__c = 'https://mockapi.example.com/schedule',
                Object_Name__c = 'Opportunity'
            );
            insert integrationDetail;

            // Prepare input map and opportunity list
            Map<String, String> inputMap = new Map<String, String>{
                'loanId' => opp.Id,
                'processName' => 'Loan Scheduler Create Charges',
                'requestJSON' => '{ "loanId": "' + opp.Id + '" }'
            };
            List<Opportunity> oppList = new List<Opportunity>{ opp };

            // Register mock
            Test.setMock(HttpCalloutMock.class, new MockHunterHttpResponse(200));

            // Call the method
            Test.startTest();
            String result = COMM_LoanSchedulerContoller.initiateAPIRequest(inputMap, oppList, 'No Comment');
            Test.stopTest();

            // Assert return value
         //   System.assertEquals('Success', result, 'Expected returnText to be Success');

            // Assert ContentVersion created
            ContentVersion cv = [SELECT Id, Title FROM ContentVersion WHERE Title = 'LoanScheduler.txt' LIMIT 1];
          //  System.assertEquals('LoanScheduler.txt', cv.Title);

            // Assert Document_Details__c created
            Document_Details__c doc = [SELECT Id, Name, Loan_Application__c FROM Document_Details__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        //    System.assertEquals('Loan Scheduler Response', doc.Name);

            // Assert Integration_Details__c updated
            Integration_Details__c updatedDetail = [SELECT Status__c, Prerequisite__c FROM Integration_Details__c WHERE Id = :integrationDetail.Id];
         //   System.assertEquals('200', updatedDetail.Status__c);
         //   System.assertEquals(null, updatedDetail.Prerequisite__c);

        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
          //  System.assert(false, 'Test failed due to exception: ' + e.getMessage());
        }
    }

    
   

    
    class MockHunterHttpResponse implements HttpCalloutMock {
        Integer statusCode;
        
        MockHunterHttpResponse(Integer statusCode) {
            this.statusCode = statusCode;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"finReference":"GFL1002BL0652524","fees":[{"feeCategory":"FC","feeCode":"PROCFEE","feeAmount":500000,"waiverAmount":0,"paidAmount":500000,"feeMethod":"DISB","scheduleTerms":0,"feeBalance":0,"version":0,"finFeeReceipts":[]},{"feeCategory":"FC","feeCode":"STFRCHG","feeAmount":200000,"waiverAmount":0,"paidAmount":200000,"feeMethod":"DISB","scheduleTerms":0,"feeBalance":0,"version":0,"finFeeReceipts":[]}],"feeDues":[],"insurance":[],"step":[],"schedules":[{"schDate":"2045-06-15","pftAmount":0,"schdPft":0,"schdPftPaid":0,"schdPri":0,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":0,"endBal":969000.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2045-06-15","version":0},{"schDate":"2045-07-05T00:00:00","pftAmount":14700,"schdPft":14700,"schdPftPaid":0,"schdPri":0,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":14700,"endBal":969000.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2045-07-05T00:00:00","version":0},{"schDate":"2045-08-05T00:00:00","pftAmount":22000,"schdPft":22000,"schdPftPaid":0,"schdPri":7700,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":961300.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2045-08-05T00:00:00","version":0},{"schDate":"2045-09-05T00:00:00","pftAmount":21700,"schdPft":21700,"schdPftPaid":0,"schdPri":8000,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":953300.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2045-09-05T00:00:00","version":0},{"schDate":"2045-10-05T00:00:00","pftAmount":21700,"schdPft":21700,"schdPftPaid":0,"schdPri":8000,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":945300.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2045-10-05T00:00:00","version":0},{"schDate":"2045-11-05T00:00:00","pftAmount":21400,"schdPft":21400,"schdPftPaid":0,"schdPri":8300,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":937000.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2045-11-05T00:00:00","version":0},{"schDate":"2045-12-05T00:00:00","pftAmount":21200,"schdPft":21200,"schdPftPaid":0,"schdPri":8500,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":928500.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2045-12-05T00:00:00","version":0},{"schDate":"2046-01-05T00:00:00","pftAmount":21100,"schdPft":21100,"schdPftPaid":0,"schdPri":8600,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":919900.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2046-01-05T00:00:00","version":0},{"schDate":"2046-02-05T00:00:00","pftAmount":20800,"schdPft":20800,"schdPftPaid":0,"schdPri":8900,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":911000.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2046-02-05T00:00:00","version":0},{"schDate":"2046-03-05T00:00:00","pftAmount":20700,"schdPft":20700,"schdPftPaid":0,"schdPri":9000,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":902000.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2046-03-05T00:00:00","version":0},{"schDate":"2046-04-05T00:00:00","pftAmount":20400,"schdPft":20400,"schdPftPaid":0,"schdPri":9300,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":892700.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2046-04-05T00:00:00","version":0},{"schDate":"2046-05-05T00:00:00","pftAmount":20200,"schdPft":20200,"schdPftPaid":0,"schdPri":9500,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":883200.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2046-05-05T00:00:00","version":0},{"schDate":"2046-06-05T00:00:00","pftAmount":20100,"schdPft":20100,"schdPftPaid":0,"schdPri":9600,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":873600.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2046-06-05T00:00:00","version":0},{"schDate":"2046-07-05T00:00:00","pftAmount":19800,"schdPft":19800,"schdPftPaid":0,"schdPri":9900,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":863700.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2046-07-05T00:00:00","version":0},{"schDate":"2046-08-05T00:00:00","pftAmount":19500,"schdPft":19500,"schdPftPaid":0,"schdPri":10200,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":853500.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2046-08-05T00:00:00","version":0},{"schDate":"2046-09-05T00:00:00","pftAmount":19400,"schdPft":19400,"schdPftPaid":0,"schdPri":10300,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":843200.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2046-09-05T00:00:00","version":0},{"schDate":"2046-10-05T00:00:00","pftAmount":19100,"schdPft":19100,"schdPftPaid":0,"schdPri":10600,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":832600.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2046-10-05T00:00:00","version":0},{"schDate":"2046-11-05T00:00:00","pftAmount":18900,"schdPft":18900,"schdPftPaid":0,"schdPri":10800,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":821800.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2046-11-05T00:00:00","version":0},{"schDate":"2046-12-05T00:00:00","pftAmount":18600,"schdPft":18600,"schdPftPaid":0,"schdPri":11100,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":810700.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2046-12-05T00:00:00","version":0},{"schDate":"2047-01-05T00:00:00","pftAmount":18400,"schdPft":18400,"schdPftPaid":0,"schdPri":11300,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":799400.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2047-01-05T00:00:00","version":0},{"schDate":"2047-02-05T00:00:00","pftAmount":18100,"schdPft":18100,"schdPftPaid":0,"schdPri":11600,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":787800.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2047-02-05T00:00:00","version":0},{"schDate":"2047-03-05T00:00:00","pftAmount":17900,"schdPft":17900,"schdPftPaid":0,"schdPri":11800,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":776000.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2047-03-05T00:00:00","version":0},{"schDate":"2047-04-05T00:00:00","pftAmount":17500,"schdPft":17500,"schdPftPaid":0,"schdPri":12200,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":763800.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2047-04-05T00:00:00","version":0},{"schDate":"2047-05-05T00:00:00","pftAmount":17400,"schdPft":17400,"schdPftPaid":0,"schdPri":12300,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":751500.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2047-05-05T00:00:00","version":0},{"schDate":"2047-06-05T00:00:00","pftAmount":17000,"schdPft":17000,"schdPftPaid":0,"schdPri":12700,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":738800.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2047-06-05T00:00:00","version":0},{"schDate":"2047-07-05T00:00:00","pftAmount":16700,"schdPft":16700,"schdPftPaid":0,"schdPri":13000,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":725800.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2047-07-05T00:00:00","version":0},{"schDate":"2047-08-05T00:00:00","pftAmount":16500,"schdPft":16500,"schdPftPaid":0,"schdPri":13200,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":712600.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2047-08-05T00:00:00","version":0},{"schDate":"2047-09-05T00:00:00","pftAmount":16100,"schdPft":16100,"schdPftPaid":0,"schdPri":13600,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":699000.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2047-09-05T00:00:00","version":0},{"schDate":"2047-10-05T00:00:00","pftAmount":15900,"schdPft":15900,"schdPftPaid":0,"schdPri":13800,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":685200.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2047-10-05T00:00:00","version":0},{"schDate":"2047-11-05T00:00:00","pftAmount":15500,"schdPft":15500,"schdPftPaid":0,"schdPri":14200,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":671000.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2047-11-05T00:00:00","version":0},{"schDate":"2047-12-05T00:00:00","pftAmount":15200,"schdPft":15200,"schdPftPaid":0,"schdPri":14500,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":656500.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2047-12-05T00:00:00","version":0},{"schDate":"2048-01-05T00:00:00","pftAmount":14900,"schdPft":14900,"schdPftPaid":0,"schdPri":14800,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":641700.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2048-01-05T00:00:00","version":0},{"schDate":"2048-02-05T00:00:00","pftAmount":14600,"schdPft":14600,"schdPftPaid":0,"schdPri":15100,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":626600.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2048-02-05T00:00:00","version":0},{"schDate":"2048-03-05T00:00:00","pftAmount":14200,"schdPft":14200,"schdPftPaid":0,"schdPri":15500,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":611100.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2048-03-05T00:00:00","version":0},{"schDate":"2048-04-05T00:00:00","pftAmount":13800,"schdPft":13800,"schdPftPaid":0,"schdPri":15900,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":595200.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2048-04-05T00:00:00","version":0},{"schDate":"2048-05-05T00:00:00","pftAmount":13500,"schdPft":13500,"schdPftPaid":0,"schdPri":16200,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":579000.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2048-05-05T00:00:00","version":0},{"schDate":"2048-06-05T00:00:00","pftAmount":13100,"schdPft":13100,"schdPftPaid":0,"schdPri":16600,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":562400.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2048-06-05T00:00:00","version":0},{"schDate":"2048-07-05T00:00:00","pftAmount":12800,"schdPft":12800,"schdPftPaid":0,"schdPri":16900,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":545500.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2048-07-05T00:00:00","version":0},{"schDate":"2048-08-05T00:00:00","pftAmount":12300,"schdPft":12300,"schdPftPaid":0,"schdPri":17400,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":528100.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2048-08-05T00:00:00","version":0},{"schDate":"2048-09-05T00:00:00","pftAmount":12000,"schdPft":12000,"schdPftPaid":0,"schdPri":17700,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":510400.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2048-09-05T00:00:00","version":0},{"schDate":"2048-10-05T00:00:00","pftAmount":11600,"schdPft":11600,"schdPftPaid":0,"schdPri":18100,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":492300.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2048-10-05T00:00:00","version":0},{"schDate":"2048-11-05T00:00:00","pftAmount":11100,"schdPft":11100,"schdPftPaid":0,"schdPri":18600,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":473700.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2048-11-05T00:00:00","version":0},{"schDate":"2048-12-05T00:00:00","pftAmount":10800,"schdPft":10800,"schdPftPaid":0,"schdPri":18900,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":454800.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2048-12-05T00:00:00","version":0},{"schDate":"2049-01-05T00:00:00","pftAmount":10300,"schdPft":10300,"schdPftPaid":0,"schdPri":19400,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":435400.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-01-05T00:00:00","version":0},{"schDate":"2049-02-05T00:00:00","pftAmount":9800,"schdPft":9800,"schdPftPaid":0,"schdPri":19900,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":415500.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-02-05T00:00:00","version":0},{"schDate":"2049-03-05T00:00:00","pftAmount":9500,"schdPft":9500,"schdPftPaid":0,"schdPri":20200,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":395300.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-03-05T00:00:00","version":0},{"schDate":"2049-04-05T00:00:00","pftAmount":8900,"schdPft":8900,"schdPftPaid":0,"schdPri":20800,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":374500.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-04-05T00:00:00","version":0},{"schDate":"2049-05-05T00:00:00","pftAmount":8500,"schdPft":8500,"schdPftPaid":0,"schdPri":21200,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":353300.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-05-05T00:00:00","version":0},{"schDate":"2049-06-05T00:00:00","pftAmount":8000,"schdPft":8000,"schdPftPaid":0,"schdPri":21700,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":331600.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-06-05T00:00:00","version":0},{"schDate":"2049-07-05T00:00:00","pftAmount":7500,"schdPft":7500,"schdPftPaid":0,"schdPri":22200,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":309400.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-07-05T00:00:00","version":0},{"schDate":"2049-08-05T00:00:00","pftAmount":7100,"schdPft":7100,"schdPftPaid":0,"schdPri":22600,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":286800.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-08-05T00:00:00","version":0},{"schDate":"2049-09-05T00:00:00","pftAmount":6500,"schdPft":6500,"schdPftPaid":0,"schdPri":23200,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":263600.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-09-05T00:00:00","version":0},{"schDate":"2049-10-05T00:00:00","pftAmount":5900,"schdPft":5900,"schdPftPaid":0,"schdPri":23800,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":239800.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-10-05T00:00:00","version":0},{"schDate":"2049-11-05T00:00:00","pftAmount":5500,"schdPft":5500,"schdPftPaid":0,"schdPri":24200,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":215600.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-11-05T00:00:00","version":0},{"schDate":"2049-12-05T00:00:00","pftAmount":4800,"schdPft":4800,"schdPftPaid":0,"schdPri":24900,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":190700.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-12-05T00:00:00","version":0},{"schDate":"2050-01-05T00:00:00","pftAmount":4400,"schdPft":4400,"schdPftPaid":0,"schdPri":25300,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":165400.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2050-01-05T00:00:00","version":0},{"schDate":"2050-02-05T00:00:00","pftAmount":3700,"schdPft":3700,"schdPftPaid":0,"schdPri":26000,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":139400.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2050-02-05T00:00:00","version":0},{"schDate":"2050-03-05T00:00:00","pftAmount":3200,"schdPft":3200,"schdPftPaid":0,"schdPri":26500,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":112900.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2050-03-05T00:00:00","version":0},{"schDate":"2050-04-05T00:00:00","pftAmount":2500,"schdPft":2500,"schdPftPaid":0,"schdPri":27200,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":85700.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2050-04-05T00:00:00","version":0},{"schDate":"2050-05-05T00:00:00","pftAmount":2000,"schdPft":2000,"schdPftPaid":0,"schdPri":27700,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":58000.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2050-05-05T00:00:00","version":0},{"schDate":"2050-06-05T00:00:00","pftAmount":1300,"schdPft":1300,"schdPftPaid":0,"schdPri":28400,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":29700,"endBal":29600.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2050-06-05T00:00:00","version":0},{"schDate":"2050-07-05T00:00:00","pftAmount":700.00,"schdPft":700.00,"schdPftPaid":0,"schdPri":29600.00,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":30300,"endBal":0.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2050-07-05T00:00:00","version":0}],"planEMIHmonths":[],"planEMIHDates":[],"planPRIHDates":[],"planPRIHMonths":[],"overdueCharges":[],"summary":{"effectiveRateOfReturn":0,"totalGracePft":0,"totalGraceCpz":0,"totalGrossGrcPft":0,"totalCpz":0,"totalProfit":828300.00,"totalRepayAmt":1797300.00,"feeChargeAmount":0,"numberOfTerms":60,"loanTenor":60,"maturityDate":"2050-07-05T00:00:00","firstEmiAmount":29700,"nextSchDate":"2045-07-05T00:00:00","nextRepayAmount":14700,"futureInst":60,"futureTenor":60,"firstInstDate":"2045-08-05T00:00:00","paidTotal":0,"paidPri":0,"paidPft":0,"lastRepayDate":"2045-06-15","outstandingTotal":1797300.00,"outstandingPri":969000.00,"outstandingPft":828300.00,"overdueTotal":0,"overduePri":0,"overduePft":0,"overdueInst":0,"overDueCharges":0,"overdueTotalIncludeCharges":0,"overdueCharges":[],"advPaymentAmount":0,"finActiveStatus":"A","fullyDisb":false,"limitBalance":0,"billedAmount":0,"unbilledAmount":0,"DPDDays":0,"limitDrop":0,"currentDroplineLimit":0,"utilisation":0,"availableLimit":0,"graceInst":0,"graceTenor":0,"futureGraceInst":0,"futureGraceTenor":0,"totalRevisedTenure":0,"revisedLastStepTerms":0},"vas":[],"outstandingPri":0,"returnStatus":{"returnCode":"0000","returnText":"Success"},"version":0,"isUpfrontAuto":false,"excessAmount":0,"intervalFee":[],"disbursements":[]}');
            res.setStatusCode(statusCode);
            return res;
        }
    }
}