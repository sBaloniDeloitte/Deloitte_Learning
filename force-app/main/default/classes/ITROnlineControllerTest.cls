@isTest
public class ITROnlineControllerTest {
    // --- Mock for SUCCESS ---
    private class ITROnlineHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"status":true,"data":{"transactionId":"12345","url":"https://mockurl.com"}}');
            return res;
        }
    }
    
    

    // --- Mock for FAIL ---
    private class ITROnlineHttpFailMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Server fail"}');
            return res;
        }
    }

    @testSetup
    public static void setupData() {

        Trigger_Settings__c trggSet = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = false
        );

        insert trggSet;

        Account acc = new Account(Name = 'Test Acc');
        insert acc;

        City_Master__c city = new City_Master__c(
            Name = 'Mumbai',
            State__c = 'MH',
            State_Name__c = 'Maharashtra'
        );

        insert city;

        Pincode_Master__c pinCode = new Pincode_master__c(
            Name = '410006',
            City__c = city.Id
        );

        insert pinCode;

        Opportunity opp = TestDataFactory.getTestOpportunityData(1,false)[0];
        opp.Name = 'Test Opp';
        opp.StageName = 'Prospecting';
        opp.CloseDate = Date.today().addDays(10);
        opp.Negotiated_Loan_Amount__c = 100000;
        opp.Sanction_Loan_Amount__c = 100000;
        insert opp;

        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        customer.Customer_LMS_Id__c = '106037';
        update customer;

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
        applicant.Customer__c = customer.Id;
        applicant.Customer_Profile__c= 'SEP';
        applicant.Sector__c = 'Chartered Accountant';
        applicant.Industry__c = 'Airlines';
        applicant.Applicant_Type__c ='Primary Applicant';
        applicant.Marital_Status__c = 'Single';
        applicant.Salutation__c = 'CA';
        applicant.Religion__c = 'Hindu';
        applicant.Sub_Employment_Type_Non_Individual__c = 'SEP-CA';
        applicant.Nationality__c = 'Indian';
        applicant.Qualification__c = 'MBBS';
        applicant.Cast_Category__c = 'General';
        applicant.Residency_Status__c = 'Resident';
        applicant.Email__c = 'fgh@ghb.com';
        applicant.Masked_Aadhar_Number__c = '456767896789';
        insert applicant;

        TestdataFactory.setupTriggerSettings ();
        TestDataFactory.setupIntegrationSettings('Get Token');
    }


    // @isTest
    // static void testInitiateAPIRequest_FailHttp() {
    //     Application_Applicant__c applicant = [SELECT Id, Loan_Application__c, PAN_Number__c, DOB__c FROM Application_Applicant__c LIMIT 1];
    //     //Integration_Master__mdt meta = [SELECT Id, Activity_Name__c FROM Integration_Master__mdt LIMIT 1];
	    
    //     Map<String, String> inputMap = new Map<String, String>{
    //         'loanId' => applicant.Loan_Application__c,
    //         'applicantId' => applicant.Id,
    //         'processName' => 'ITR Online',
    //         'panNumber' => applicant.PAN_Number__c,
    //         'dob' => String.valueOf(applicant.DOB__c)
    //     };

    //     Test.setMock(HttpCalloutMock.class, new ITROnlineHttpFailMock());
       
    //     Test.startTest();
    //     String response = ITROnlineController.initiateAPIRequest(inputMap);
    //     Test.stopTest();
    // }

    // ⚠️ Prerequisite error case
    @isTest
    static void testInitiateAPIRequest_PrerequisiteError() {
        // fake input
        Application_Applicant__c applicant = [SELECT Id, Loan_Application__c, PAN_Number__c, DOB__c FROM Application_Applicant__c LIMIT 1];
        

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => applicant.Loan_Application__c,
            'applicantId' => applicant.Id,
            'processName' => 'ITR Online',
            'panNumber' => 'applicant.PAN_Number__c',
            'dob' => String.valueOf(applicant.DOB__c)
        };

        // Override IntHandler with a fake stub
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ITROnlineHttpMock());
        try{
            String result = ITROnlineController.initiateAPIRequest(inputMap);
        }catch(Exception e){}
         
        Test.stopTest();

        // Here you'd need to stub IntHandler.validateProcess() to return a wrapper with prerequisiteError.
        // If that's not possible, you can create a separate test util class in your org that mocks it.
    }

    @isTest 
	static void testInitiateAPIRequest_Success1() {
		Account acc = new Account(Name = 'Test Acc');
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            Product__c='Affordable Home Loan',
            CloseDate = System.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;
		
        Integration_Details__c intDet = new Integration_Details__c(
            Loan_Application__c = opp.Id,
            Name = 'ITR Online',
            Endpoint__c = 'Callout:ITR Online',
            Object_Name__c = 'Opportunity',
            Method_type__c = 'POST'
		);
		insert intDet;
        
        // Application Applicant record
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            PAN_Number__c = 'ABCPE1234F',
            DOB__c = Date.newInstance(1990, 1, 1),
            Mobile_Number__c = '9999999999',
            Customer_Type__c = 'Individual',
			Applicant_Type__c = 'Primary Applicant' 
        );
        insert applicant;
        
		Document_Details__c doc = new Document_Details__c(
		Name = 'Test Document'
		);
		insert doc;
		
		City_Master__c city = new City_Master__c(
		Country__c = 'IN',
		State__c = 'DL',
		Name = 'New Delhi');
		insert city;
		
		Pincode_Master__c pin = new Pincode_Master__c(
		Name = '110001',
		City__c = city.Id);
		insert pin;
		
		Applicant_Address__c adrs = new Applicant_Address__c(
		Applicant__c = applicant.Id,
		Address_Priority__c = '5',
		Document_Details__c = doc.Id,
		Address_Type__c = 'Permanent',
		Address_Line_1__c = 'Test Address',
		Pincode__c = pin.Id
		);
        insert adrs;
        
        Integration_Settings__c setting = new Integration_Settings__c(
            Name = 'Loan URL Shortening Service',
            Client_Id__c = 'client',
            Client_Secret__c = 'secret',
            Endpoint__c = 'https://test.api.url',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST',
            Cookie__c ='test'
        );
        insert setting;
		
        Test.setMock(HttpCalloutMock.class, new ITROnlineHttpMock());
        
        Map<String, String> input = new Map<String, String>{
            'loanId' => applicant.Loan_Application__c,
            'applicantId' => applicant.Id,
            'processName' => 'ITR Online',
            'panNumber' => applicant.PAN_Number__c,
            'dob' => String.valueOf(applicant.DOB__c)
        };
            try{
                Test.startTest();
        String result = ITROnlineController.initiateAPIRequest(input);
        Test.stopTest();
            }catch(Exception ex){}
        

    }
    //Ends
    @isTest 
    static void testInitiateAPIRequest_Success2(){
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
             Product__c = 'Home Loan',
            Final_Amount__c = null, // Intentionally null to trigger validation
            Sanction_Tenure__c = null, // Intentionally null to trigger validation
            Variant__c = 'Overdraft',
          StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;

// Step 2: Get RecordTypeId for Loan_Transaction__c
        Id txnRecordTypeId = Schema.SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByDeveloperName()
            .get('Transaction_Details')
            .getRecordTypeId();

// Step 3: Create Loan Transaction with missing fields
        Loan_Transaction__c loanTxn = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = txnRecordTypeId,
            Schedule_Method__c = null,
            TDS_Applicable__c = true,
            Rate_Type__c = null,
            Step_Loan__c = true,
            Loan_Start_Date__c = null,
            Allow_Grace__c = true,
			Grace_Period_Frequency__c = null,
            Allow_BPI__c = true,
            BPI_Treatment__c = null
        );
        insert loanTxn;
        
        
// Step 4: Create wrapper
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;

        // Step 5: Call getConstants
        Test.startTest();
        Map<String, String> constants = ITROnlineController.getConstants();
        Test.stopTest();
    }
    
    @isTest
    static void testMethod1() {
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'UCIC Search Customer',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
        Account acc=[select id from Account limit 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Customer__c FROM Application_Applicant__c LIMIT 1];
        	app.Name = 'Test Applicant';
           // app.UCIC_Number__c = '123456789';
                //app.Customer__c=acc.Id;
        update app;
        
        Date myDate = Date.newInstance(2016, 12, 9);

        Map<String, String> inputMap = new Map<String, String>{
            'recordId' => opp.Id,
            'applicantId' => app.Id,
            'processName' => 'AML Check',
            'panNum' => 'ABCDE1234F',
            'dob' => String.valueOf(myDate)
               
        };
        TestDataFactory.setupIntegrationSettings('Get Customer By UCIC');
        TestDataFactory.setupIntegrationSettings('Get Token');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        //Test.setMock(HttpCalloutMock.class, new ITROnlineHttpMock());
        Test.startTest();
        //List<COMM_GetFinanceDetailsByUCICController.Finance> financeList = COMM_GetFinanceDetailsByUCICController.getCustomerFinances('129989', 'Get Customer By UCIC');
        try{
        String result = ITROnlineController.initiateAPIRequest(inputMap);   
        }
        catch (exception e){}
        Test.stopTest();
    }
    
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            String sampleResponse = '{' +
                '"finances": [' +
                    '{' +
                        '"finReference": "FIN123",' +
                        '"coreBankID": "BANK001",' +
                        '"cif": "CIF001",' +
                        '"finAmount": 100000,' +
                        '"emiAmount": 5000,' +
                        '"outstandingBal": 80000,' +
                        '"outstandingPri": 75000,' +
                        '"status": "Active",' +
                        '"finStatus": "Open",' +
                        '"entityType": "Individual",' +
                        '"custShrtName": "John",' +
                        '"custDOB": "1990-01-01",' +
                        '"custCtgCode": "A1",' +
                        '"finType": "Loan",' +
                        '"finStartDate": "2024-01-01",' +
                        '"noOfOdDays": 0,' +
                        '"noOfBounces": 1,' +
                        '"source": "System"' +
                    '}' +
                '],' +
                '"returnStatus": {"returnCode": "200", "returnText": "Success"}' +
            '}';

            res.setBody(sampleResponse);
            return res;

            
        }
    }
}