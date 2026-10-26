@isTest
public class COMM_GetFinanceDetailsUCICControllerTest {

    @isTest
    static void testMethod1() {
        TestDataFactory.setupIntegrationSettings('Get Customer By UCIC');
        TestDataFactory.setupIntegrationSettings('Get Token');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        List<COMM_GetFinanceDetailsByUCICController.Finance> financeList = COMM_GetFinanceDetailsByUCICController.getCustomerFinances('129989', 'Get Customer By UCIC');
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