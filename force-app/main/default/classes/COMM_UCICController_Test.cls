@isTest
public with sharing class COMM_UCICController_Test {
    @TestSetup
    static void makeData(){
        Account acc = FITestDataFactory.createAccount('Account name 1','Customer');
        Opportunity opp = FITestDataFactory.createLoanApplication(true,acc);
        FITestDataFactory.createApplicant(opp);
         TestDataFactory.setupIntegrationSettings('UCIC De Dupe Check');
        TestDataFactory.setupIntegrationSettings('Get Token');

    }
    @isTest
    static void initiateAPIRequest_Test(){
       try{
        Map<String, String> inputMap = new Map<String, String>();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
         
        inputMap.put('loanId',opp.Id);
        inputMap.put('applicantId',applicant.Id);
        inputMap.put('processName','UCIC De Dupe Check');
        inputMap.put('panNumber','ABCPE1234F');
        inputMap.put('panName','test name');
        inputMap.put('dob','2015-03-12');
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        COMM_UCICController.initiateAPIRequest(inputMap);
        Test.stopTest();

    }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
        }
}
    @isTest
    static void initiateAPIRequest_ExceptionTest(){
       try{
        Map<String, String> inputMap = new Map<String, String>();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
         
        inputMap.put('loanId',opp.Id);
        inputMap.put('applicantId',applicant.Id);
        inputMap.put('processName','UCIC De Dupe Check');
        inputMap.put('panNumber','ABCPE1234F');
        inputMap.put('panName','');
        inputMap.put('dob','2015-03-12');
        
        Test.startTest();
        COMM_UCICController.initiateAPIRequest(inputMap);
        Test.stopTest();


    }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
        }
}


  
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
            '          "Dob_doi": "1980-01-01",'+
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
}