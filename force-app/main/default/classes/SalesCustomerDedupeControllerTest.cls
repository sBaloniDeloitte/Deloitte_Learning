@IsTest
public class SalesCustomerDedupeControllerTest {
    
    // ----------------------- MOCKS -----------------------
    class MockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String jsonResponse = '{'+
                '  "Response": {'+
                '    "StatusInfo": {'+
                '      "RequestId": "REQ123",'+
                '      "CUSTUNQID": "CUST456",'+
                '      "Status": "C",'+
                '      "StatusMessage": "Success",'+
                '      "ResponseCode": "200",'+
                '      "Description": "Customer found",'+
                '      "MatchCount": "1",'+
                '      "UCIC": "UCIC789",'+
                '      "UCIC_Type": "TypeA"'+
                '    },'+
                '    "CustomerMatchResponse": ['+
                '      {'+
                '        "Demographics": {'+
                '          "SourceSystem": "Salesforce1",'+
                '          "CustUnqId": "CUST456",'+
                '          "MatchReason": "PAN",'+
                '          "MatchCategory": "GODREJ_GOOD",'+
                '          "RecordType": "ONLINE",'+
                '          "Name": "John Doe",'+
                '          "Gender": "M",'+
                '          "PanNo": "ABCDE1234F",'+
                '          "VoterID": "V123456",'+
                '          "PassportNo": "P987654",'+
                '          "Aadhar": "123412341234",'+
                '          "CombinedStrength": "0",'+
                '          "CustomerCategory": "Individual",'+
                '          "Dob_doi": "01-01-1998",'+
                '          "Driving_License": "DL12345",'+
                '          "UCIC": "UCIC789"'+
                '        },'+
                '        "ACE": ['+
                '          {'+
                '            "AddressType": "OFFADD",'+
                '            "Address": "123 Main St",'+
                '            "City": "Mumbai",'+
                '            "State": "MH",'+
                '            "Country": "India",'+
                '            "Pincode": "400001",'+
                '            "Phone": "9876543210",'+
                '            "PhoneType": "MOBILE",'+
                '            "Email": "john@example.com",'+
                '            "EmailType": "WORK"'+
                '          }'+
                '        ]'+
                '      }'+
                '    ]'+
                '  }'+
                '}';
            res.setBody(jsonResponse);
            res.setStatusCode(200);
            return res;
        }
    }
    
    class MockResponseActual implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String jsonResponse = '{"Response":{"StatusInfo":{"RequestId":"1767080176939","CUSTUNQID":"0002377","Status":"C","StatusMessage":"Success","ResponseCode":"200","Description":"Request processed successfully","MatchCount":"1","UCIC":"8100001934","UCIC_Type":"E"},"CustomerMatchResponse":[{"Demographics":{"SourceSystem":"GHF","CustUnqId":"0002377","MatchReason":"pan&#124","MatchCategory":"Godrej_GOOD","RecordType":"ONLINE","Name":"Rohit K","Gender":null,"PanNo":"AIFPP5729A","VoterID":null,"PassportNo":null,"Aadhar":"XXXXXXXX8939","UCIC":"8100001934","CombinedStrength":"10","Dob_doi":"01-01-1990","Driving_License":null,"CustomerCategory":"Individual"},"ACE":[{"AddressType":"Permanent","Address":"2 , 30, ,, , Peddapally, Mahabub Nagar, Nagarkurnool,","Country":"IN","Pincode":"509385","Phone":"9763560400","PhoneType":"Mobile"},{"AddressType":"Registered Office","Address":"registered office address one, registered office address two","Country":"IN","Pincode":"400028","Phone":"9763560400","PhoneType":"Mobile"},{"AddressType":"Current","Address":"main applicant current address one, main applicant current address two","Country":"IN","Pincode":"400030","Phone":"9763560400","PhoneType":"Mobile"},{"AddressType":"Current","Address":"2 , 30, ,, , Peddapally, Mahabub Nagar, Nagarkurnool,","Country":"IN","Pincode":"509385","Phone":"9763560400","PhoneType":"Mobile"}]}]}}';
            res.setBody(jsonResponse);
            res.setStatusCode(200);
            return res;
        }
    }
    class MockResponseActual1 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String jsonResponse = '{"Response":{"StatusInfo":{"RequestId":"1767080176939","CUSTUNQID":"0002377","Status":"C","StatusMessage":"Success","ResponseCode":"200","Description":"Request processed successfully","MatchCount":"1","UCIC":"8100001934","UCIC_Type":"E"},"CustomerMatchResponse":[{"Demographics":{"SourceSystem":"GHF","CustUnqId":"0002377","MatchReason":"Pan|Rule0","MatchCategory":"Godrej_GOOD","RecordType":"ONLINE","Name":"Rohit K","Gender":null,"PanNo":"AIFPP5729A","VoterID":null,"PassportNo":null,"Aadhar":"XXXXXXXX8939","UCIC":"8100001934","CombinedStrength":"10","Dob_doi":"01-01-1990","Driving_License":null,"CustomerCategory":"Non Individual"},"ACE":[{"AddressType":"Permanent","Address":"2 , 30, ,, , Peddapally, Mahabub Nagar, Nagarkurnool,","Country":"IN","Pincode":"509385","Phone":"9763560400","PhoneType":"Mobile"},{"AddressType":"Registered Office","Address":"registered office address one, registered office address two","Country":"IN","Pincode":"400028","Phone":"9763560400","PhoneType":"Mobile"},{"AddressType":"Current","Address":"main applicant current address one, main applicant current address two","Country":"IN","Pincode":"400030","Phone":"9763560400","PhoneType":"Mobile"},{"AddressType":"Current","Address":"2 , 30, ,, , Peddapally, Mahabub Nagar, Nagarkurnool,","Country":"IN","Pincode":"509385","Phone":"9763560400","PhoneType":"Mobile"}]}]}}';
            res.setBody(jsonResponse);
            res.setStatusCode(200);
            return res;
        }
    }
    
    
    
    public class MockEmptyResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('');
            res.setStatusCode(400);
            return res;
        }
    }
    
    private class COMM_GetCustomerMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            String body = '{' +
                '"personalInfo": {' +
                '"firstName": "Radhika",' +
                '"middleName": "Pathak",' +
                '"lastName": "Pathak",' +
                '"shortName": "Radhika Pathak",' +
                '"dateofBirth": "1999-09-13",' +
                '"gender": "OTH",' +
                '"custCRCPR": "AAAPH1234H"' +
                '},' +
                '"phones": [{"phoneTypeCode": "MOBILE","phoneNumber": "9930277019","priority": 5,"version": 0}],' +
                '"addresses": [{"addrType": "EMPADD","buildingNo": "addre1","FlatNo": "kjdhahdaj","Street": "jsjdjad","city": "MMB","state": "MH","country": "IN","pinCode": "400007","countryName": "INDIA","stateName": "Maharashtra","cityName": "Mumbai"}]' +
                '}';
            res.setHeader('Content-Type', 'application/json');
            res.setBody(body);
            return res;
        }
    }
    
    private class MyCKYCMock implements HttpCalloutMock {
        private String scenario;
        MyCKYCMock(String s) { scenario = s; }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if(scenario == 'Success'){
                res.setStatusCode(200);
                res.setBody('{"response":{"A99ResponseData":{"CKYCDownloadResult":{"CKYCSuccessDescription":"OTP Resent Successfully"}}}}');
            }
            else if(scenario == 'Rejection'){
                res.setStatusCode(200);
                res.setBody('{"response":{"A99ResponseData":{"CKYCDownloadResult":{"CKYCRejectionDescription":"Invalid PAN"}}}}');
            }
            else if(scenario == 'ExpiredTxn'){
                res.setStatusCode(200);
                res.setBody('{"response":{"A99ResponseData":{"CKYCDownloadResult":{"CKYCSuccessDescription":"Please provide valid CKYCTransactionID"}}}}');
            }
            else if(scenario == '502'){
                res.setStatusCode(502);
                res.setBody('Service Unavailable');
            }
            else if(scenario == 'OtherError'){
                res.setStatusCode(400);
                res.setBody('{"error":"Bad Request"}');
            }
            else {
                res.setStatusCode(200);
                res.setBody('{}');
            }
            return res;
        }
    }
    
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            String sampleResponse = '{' +
                '"finances": [{' +
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
                '}],' +
                '"returnStatus": {"returnCode": "200", "returnText": "Success"}' +
                '}';
            res.setBody(sampleResponse);
            return res;
        }
    }
    
    // ----------------------- TEST SETUP -----------------------
    @TestSetup
    static void setupData() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        customer.Customer_LMS_Id__c = '171153';
        customer.Customer_Type__c='Individual';
        customer.PAN_Number__c='VZWPT2211A';
        update customer;
        Account customer1 = FITestDataFactory.createAccount('Test CustomerNonIndi', 'Customer');
        customer1.Customer_LMS_Id__c = '171159';
        customer1.Customer_Type__c='Non Individual';
        customer1.PAN_Number__c='VZWCT2211A';
        update customer1;
        
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        
        Application_Verification__c appVer = new Application_Verification__c();
        appVer.Stage__c = 'Draft';
        appVer.Loan_Application__c = loan.Id;
        insert appVer;
        
        ContentVersion contentVersionObj = FITestDataFactory.createContentVersionDetails();
        Document_Details__c bankDocDetailsObj = FITestDataFactory.createBankSentimentAnalysisDetails(contentVersionObj);
        bankDocDetailsObj.Application_Verification__c = appVer.Id;
        update bankDocDetailsObj;
        
        Lead testLead = new Lead(
            LastName = 'TestLead',
            Company = 'TestCompany',
            MobilePhone = '9342345676',
            Product__c = 'Affordable Home Loan',
            Channel__c = 'Direct',
            Status = 'Open',
            Customer_Type__c='Individual',
            FirstName='test',
            PAN__c='test123c'
        );
        insert testLead;
        
        Integration_Details__c integrationDetail = new Integration_Details__c(
            Name = 'Fetch Application Date',
            Loan_Application__c = loan.Id,
            Related_Record_Id__c = loan.Id,
            Endpoint__c = 'test.com',
            Response_JSON__c = 'responseJson',
            Status__c='200',
            Business_Date__c=date.today()
        );
        insert integrationDetail;
        
        // Mandatory: Insert UCIC Dedupe Integration_Settings__c with Handle_Type__c
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'UCIC De Dupe Check',
            
            Client_Id__c = 'NA',
            Cookie__c = 'dummycookie',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_De_Dupe',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic test',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
        Integration_Settings__c intDetails = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'f9709782-85ea-49fc-848a-6abcbfa65611',
            Cookie__c = '',
            Client_Secret__c = 'REDACTED_CLIENT_SECRET',
            Endpoint__c = 'Callout:LOS_BL_Bearer',
            Content_Type__c = 'application/json',
            Authorization__c = '',
            Request_Method__c = 'GET'
        );
        insert intDetails;
        System.debug('intDetails---'+intDetails);
        Integration_Settings__c intDetails2 = new Integration_Settings__c(
            Name = 'UCIC Search Customer',
            
            Client_Id__c = 'NA',
            Cookie__c = 'dummycookie',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_UCIC_Search',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic test',
            Request_Method__c = 'POST'
        );
        insert intDetails2;
    }
    @IsTest
    static void testCheckCustomerDedupe_FreshCustomerPathActual() {
        Boolean panMatchFound=false;
        Account acc = [SELECT Id FROM Account  LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id,Pan_Number__c FROM Application_Applicant__c LIMIT 1];
        app.Customer__c=acc.id;
        app.Customer_Type__c='Individual';
        update app;
        app.DOB__c = Date.today().addYears(-20);
        app.Customer_Type__c = 'Individual';
        app.Pan_Number__c='VZWPT2211A';
        app.Name = 'Test app';
        update app;
        
        Map<String,String> inputMap = new Map<String,String>();
        inputMap.put('loanId', opp.Id);
        inputMap.put('applicantId', app.Id);
        inputMap.put('processName', 'UCIC Search AND Create'); // Must match metadata
        inputMap.put('panNum', 'VZWPV2211A');
        inputMap.put('panName', 'John Doe');
        inputMap.put('aadharNumber', '');
        inputMap.put('voterNumber', '');
        inputMap.put('dlNumber', '');
        inputMap.put('passportNumber', '');
        inputMap.put('dob', '1998-08-08');
        inputMap.put('gender', 'Female');
        inputMap.put('isFromLead', 'false'); // Corrected
        
        Test.setMock(HttpCalloutMock.class, new MockResponse());        
        Test.startTest();
        COMM_UCICController.initiateAPIRequest(inputMap);
        SalesCustomerDedupeController.InputWrapper wrap = new SalesCustomerDedupeController.InputWrapper();
        wrap.loanId = opp.Id;
        wrap.applicantId = app.Id;
        wrap.panNumber = 'VZWPT2211A';
        String inputStr = JSON.serialize(wrap);
        SalesCustomerDedupeController.checkCustomerDedupe(inputStr);
        Test.stopTest();
        
    }
    
    
    // ----------------------- TEST METHODS -----------------------
    @IsTest
    static void testCheckCustomerDedupe_FreshCustomerPath() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id,Pan_Number__c FROM Application_Applicant__c LIMIT 1];
        
        app.DOB__c = Date.today().addYears(-20);
        app.Customer_Type__c = 'Individual';
        app.Pan_Number__c='VZWPT2211A';
        app.Name = 'Test app';
        update app;
        
        Map<String,String> inputMap = new Map<String,String>();
        inputMap.put('loanId', opp.Id);
        inputMap.put('applicantId', app.Id);
        inputMap.put('processName', 'UCIC De Dupe Check'); // Must match metadata
        inputMap.put('panNumber', 'VZWPT2211A');
        inputMap.put('panName', 'John Doe');
        inputMap.put('aadharNumber', '');
        inputMap.put('voterNumber', '');
        inputMap.put('dlNumber', '');
        inputMap.put('passportNumber', '');
        inputMap.put('dob', '1998-08-08');
        inputMap.put('gender', 'Female');
        inputMap.put('isFromLead', 'false'); // Corrected
        
        Test.setMock(HttpCalloutMock.class, new MockResponseActual());        
        Test.startTest();
        COMM_UCICController.initiateAPIRequest(inputMap);
        SalesCustomerDedupeController.InputWrapper wrap = new SalesCustomerDedupeController.InputWrapper();
        wrap.loanId = opp.Id;
        wrap.applicantId = app.Id;
        wrap.panNumber = 'VZWPT2211A';
        String inputStr = JSON.serialize(wrap);
        SalesCustomerDedupeController.checkCustomerDedupe(inputStr);
        Test.stopTest();
        
    }
    @IsTest
    static void testCheckCustomerDedupe_FreshCustomerPath2() {
        Account acc = [SELECT Id FROM Account where Customer_Type__c = 'Non Individual' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id,Pan_Number__c,Customer__c FROM Application_Applicant__c LIMIT 1];
        app.Customer_Type__c='Non Individual';
        app.DOI__c = Date.today().addYears(-20);
        app.Pan_Number__c='VZWCT2211A';
        app.Customer__c=acc.id;
        app.Name_of_Organization__c = 'Test app';
        update app;
        Applicant_Address__c addr = new Applicant_Address__c();
        addr.Address_Line_1__c = 'Test';
        addr.Applicant__c = app.Id;
        Insert addr;
        Account customer1 = FITestDataFactory.createAccount('Test CustomerNonIndit', 'Customer');
        customer1.Customer_LMS_Id__c = '171134';
        customer1.Customer_Type__c='Non Individual';
        customer1.PAN_Number__c='VZWCT2341A';
        update customer1;
        Customer_Address__c cr = new Customer_Address__c();
        cr.Address_Line_1__c = 'Test';
        cr.Customer__c = customer1.Id;
        Insert cr;
        
        Map<String,String> inputMap = new Map<String,String>();
        inputMap.put('loanId', opp.Id);
        inputMap.put('applicantId', app.Id);
        inputMap.put('processName', 'UCIC De Dupe Check'); // Must match metadata
        inputMap.put('panNumber', 'VZWCT2211A');
        inputMap.put('panName', 'John Doe');
        inputMap.put('aadharNumber', '');
        inputMap.put('voterNumber', '');
        inputMap.put('dlNumber', '');
        inputMap.put('passportNumber', '');
        inputMap.put('dob', '1998-08-08');
        inputMap.put('gender', '');
        inputMap.put('isFromLead', 'false'); // Corrected
        System.debug('inputMap----'+inputMap);
        Test.setMock(HttpCalloutMock.class, new MockResponseActual1());        
        Test.startTest();
        COMM_UCICController.initiateAPIRequest(inputMap);
        SalesCustomerDedupeController.InputWrapper wrap = new SalesCustomerDedupeController.InputWrapper();
        wrap.loanId = opp.Id;
        wrap.applicantId = app.Id;
        wrap.panNumber = 'VZWCT2211A';
        String inputStr = JSON.serialize(wrap);
        SalesCustomerDedupeController.checkCustomerDedupe(inputStr);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testUpdateApplicantRecords_WithCustId() {
        Account acc=[select id from Account limit 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Customer__c FROM Application_Applicant__c LIMIT 1];
        app.Customer__c=acc.Id;
        update app;
        
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Customer',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
        Test.setMock(HttpCalloutMock.class, new COMM_GetCustomerMock());
        SalesCustomerDedupeController.InputWrapper wrap = new SalesCustomerDedupeController.InputWrapper();
        wrap.custId = '171153';
        wrap.applicantId = app.Id;
        wrap.loanId = opp.Id;
        wrap.accToBeTagged = [SELECT Id FROM Account WHERE Customer_LMS_Id__c = '171153' LIMIT 1];
        String inputStr = JSON.serialize(wrap);
        Test.startTest();
        SalesCustomerDedupeController.UpdateResponseWrap out = SalesCustomerDedupeController.updateApplicantRecords(inputStr);
        Test.stopTest();
        
        System.assertNotEquals(null, out);
        System.assertNotEquals(null, out.intDetails, 'Integration detail should be set');
    }
    
    @IsTest
    static void testUpdateApplicantRecords_WithCustId2() {
        Account acc=[select id from Account limit 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Customer__c FROM Application_Applicant__c LIMIT 1];
        app.Customer__c=acc.Id;
        update app;
        
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Customer',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
        Test.setMock(HttpCalloutMock.class, new COMM_GetCustomerMock());
        SalesCustomerDedupeController.InputWrapper wrap = new SalesCustomerDedupeController.InputWrapper();
        wrap.custId = '';
        wrap.applicantId = app.Id;
        wrap.loanId = opp.Id;
        wrap.accId=acc.id;
        wrap.accToBeTagged = [SELECT Id FROM Account WHERE Customer_LMS_Id__c = '171153' LIMIT 1];
        String inputStr = JSON.serialize(wrap);
        Test.startTest();
        SalesCustomerDedupeController.UpdateResponseWrap out = SalesCustomerDedupeController.updateApplicantRecords(inputStr);
        Test.stopTest();
        
        System.assertNotEquals(null, out);
        System.assertNotEquals(null, out.intDetails, 'Integration detail should be set');
    }
    @IsTest
    static void testUpdateApplicantRecords_WithAccountId() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Customer__c FROM Application_Applicant__c LIMIT 1];
        
        // Set custId to null to go into accountId path
        SalesCustomerDedupeController.InputWrapper wrap = new SalesCustomerDedupeController.InputWrapper();
        wrap.custId = null;
        wrap.accId = acc.Id;
        wrap.applicantId = app.Id;
        wrap.loanId = opp.Id;
        
        String inputStr = JSON.serialize(wrap);
        
        Test.startTest();
        SalesCustomerDedupeController.UpdateResponseWrap out = SalesCustomerDedupeController.updateApplicantRecords(inputStr);
        Test.stopTest();
        
        System.assertNotEquals(null, out);
        //System.assertNotEquals(null, out.intDetails, 'Integration detail should be set');
    }
    
    
    
}