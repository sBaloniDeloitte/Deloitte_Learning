@IsTest
public class BlacklistCustomerControllerTest {

    /* =========================================================
       TEST SETUP
       ========================================================= */
    @testSetup
    static void setupTestData() {

        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');

        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        opp.Product__c = 'Affordable Home Loan';
        opp.Tenor_Months__c = 12;
        opp.Requested_Amount__c = 100000;
        update opp;

        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
        applicant.First_Name__c = 'Prasad';
        applicant.Mobile_Number__c = '9999999999';
        applicant.PAN_Number__c = 'ABCDE1234F';
        applicant.DOB__c = Date.newInstance(2000, 3, 1);
        update applicant;

        Trigger_Settings__c settings = new Trigger_Settings__c(
        Name = 'Trigger Settings',
        Opportunity_Trigger__c  = true,
        City_Master_Trigger__c = true 
        );
        insert settings;
        
        City_Master__c cityRec = new City_Master__c();
        cityRec.Name = 'Delhi';
        cityRec.Country__c = 'IN';
        cityRec.State__c = 'HR';
        cityRec.State_Name__c = 'Haryana';
        cityRec.Country_Name__c = 'India';
        cityRec.City_Code__c='DL';
        insert cityRec;
        
        Pincode_Master__c pinCodeRecord = new Pincode_Master__c();
        pinCodeRecord.Name = '110025';
        pinCodeRecord.City__c = cityRec.Id;
        insert pinCodeRecord;
        

        Customer_Address__c custAdd = new Customer_Address__c(
            Customer__c = customer.Id,
            Address_Type__c = 'Permanent',
            Address_Source__c = 'Manual'
        );
        insert custAdd;

        Applicant_Address__c appAdd = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Loan_Application__c = opp.Id,
            Address_Type__c = 'Permanent',
            Customer_Address__c = custAdd.Id,
            Pincode__c = pinCodeRecord.Id
        );
        insert appAdd;

        Integration_Settings__c intSetting = new Integration_Settings__c(
            Name = 'Blacklist Customers',
            Endpoint__c = 'https://dummy.endpoint',
            Request_Method__c = 'POST',
            Content_Type__c = 'application/json',
            Client_Id__c = 'NA',
            Client_Secret__c = 'NA'
        );
        insert intSetting;
    }

    /* =========================================================
       MAIN TEST : fetchBlackListCustomers (SANDBOX FLOW)
       ========================================================= */
    @IsTest
    static void testFetchBlackListCustomers_Success() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new BlacklistCustomerSuccessMock());

        Test.startTest();
        List<String> result =
            BlacklistCustomerController.fetchBlackListCustomers(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(result.contains('success'),
            'Expected success from blacklist check');

        // Verify Negative Dedupe created
        System.assert(
            [SELECT COUNT() FROM Negative_dedupe__c] > 0,
            'Negative dedupe records should be inserted'
        );

        // Verify integration logs
        System.assert(
            [SELECT COUNT() FROM Integration_Details__c] > 0,
            'Integration logs should be created'
        );
    }

    /* =========================================================
       createSOQL COVERAGE
       ========================================================= */
    @IsTest
    static void testCreateSOQL() {

        Map<String, String> inputMap = new Map<String, String>{
            'FIRST_NAME' => 'Prasad',
            'MOBILE_NUMBER' => '9999999999',
            'DOB' => '2000-03-01',
            'PAN_NUMBER' => 'ABCDE1234F',
            'ADDRESS' => 'Test Address'
        };

        String soql = BlacklistCustomerController.createSOQL(inputMap);

        System.assertNotEquals(null, soql);
        System.assert(soql.contains('PAN_NUMBER'));
    }

    /* =========================================================
       INNER CALLOUT MOCK (SUCCESS PATH)
       ========================================================= */
    public class BlacklistCustomerSuccessMock implements HttpCalloutMock {

         public HTTPResponse respond(HTTPRequest req) {

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);

        res.setBody(
            '{"data":[' +

            // PAN_NUMBER
            '["CIF001",0,0,0,"PRASAD","","9999999999","ABCDE1234F","2000-03-01","TEST ADDRESS","PAN_NUMBER"],' +

            // FIRST_NAME
            '["CIF002",0,0,0,"PRASAD","","NULL","NULL","NULL","TEST ADDRESS","FIRST_NAME"],' +

            // MOBILE_NUMBER
            '["CIF003",0,0,0,"PRASAD","","9999999999","NULL","NULL","TEST ADDRESS","MOBILE_NUMBER"],' +

            // FIRST_NAME_DOB
            '["CIF004",0,0,0,"PRASAD","","NULL","NULL","2000-03-01","TEST ADDRESS","FIRST_NAME_DOB"],' +

            // FIRST_NAME_ADDRESS
            '["CIF005",0,0,0,"PRASAD","","NULL","NULL","NULL","TEST ADDRESS","FIRST_NAME_ADDRESS"],' +

            // FIRST_NAME_DOB_ADDRESS
            '["CIF006",0,0,0,"PRASAD","","NULL","NULL","2000-03-01","TEST ADDRESS","FIRST_NAME_DOB_ADDRESS"],' +

            // FIRST_NAME_DOB_MOBILE
            '["CIF007",0,0,0,"PRASAD","","9999999999","NULL","2000-03-01","TEST ADDRESS","FIRST_NAME_DOB_MOBILE"],' +

            // ADDRESS_DOB
            '["CIF008",0,0,0,"PRASAD","","NULL","NULL","2000-03-01","TEST ADDRESS","ADDRESS_DOB"]' +

            ']}'
        );

        return res;
    }

    }
}