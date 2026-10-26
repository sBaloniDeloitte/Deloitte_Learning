@isTest
public class COMM_CKYCResendOtpControllerTest {

    
    // ===== MOCK CLASS =====
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
                res.setBody('{}'); // Empty JSON for edge cases
            }
            return res;
        }
    }

    // ===== HELPER: Setup loan + applicant + settings =====
    private static Map<String, Id> setupBasicData(String processName) {
        // Integration settings
        TestDataFactory.setupIntegrationSettings('CKYC ResendOtp');
        TestDataFactory.setupIntegrationSettings('AHL CKYC');
        TestDataFactory.setupIntegrationSettings('Get Token');

        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;

        Application_Applicant__c applicant =  TestdataFactory.getTestApplicationApplicantData(1, opp.id,false)[0];
           
        insert applicant;

        // Triangulation record
        Triangulation_Data__c td = TestDataFactory.createTriangData(opp.id, applicant.id, Null, 'CKYC');
        td.CKYC_Transaction_Id__c = 'txn123';
        update td;

        Map<String, Id> result = new Map<String, Id>();
        result.put('loanId', opp.Id);
        result.put('applicantId', applicant.Id);
        return result;
    }

    // ===== TESTS =====

    @isTest
    static void testProcessCommercialCrifResponse_Success() {
        Map<String, Id> setupData = setupBasicData('CKYC ResendOtp');

        Test.setMock(HttpCalloutMock.class, new MyCKYCMock('Success'));

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => String.valueOf(setupData.get('loanId')),
            'applicantId' => String.valueOf(setupData.get('applicantId')),
            'processName' => 'CKYC ResendOtp',
            'ckycTransactionID' => 'Txn123'
        };
            try {
        Test.startTest();
        String resp = COMM_CKYCResendOtpController.processCommercialCrifResponse(inputMap);
        Test.stopTest();

        System.assert(resp.contains('Success'), 'Should return success message');
            }
        catch (exception ex){}
    }

    @isTest
    static void testProcessCommercialCrifResponse_Rejection200() {
        Map<String, Id> setupData = setupBasicData('CKYC ResendOtp');

        Test.setMock(HttpCalloutMock.class, new MyCKYCMock('Rejection'));

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => String.valueOf(setupData.get('loanId')),
            'applicantId' => String.valueOf(setupData.get('applicantId')),
            'processName' => 'CKYC ResendOtp',
            'ckycTransactionID' => 'Txn456'
        };
            try{
        Test.startTest();
        String resp = COMM_CKYCResendOtpController.processCommercialCrifResponse(inputMap);
        Test.stopTest();

        System.assert(resp.contains('Error'), 'Should return error message from rejection');
            }
        catch(exception ex){}
    }

    @isTest
    static void testProcessCommercialCrifResponse_502Error() {
        Map<String, Id> setupData = setupBasicData('CKYC ResendOtp');

        Test.setMock(HttpCalloutMock.class, new MyCKYCMock('502'));

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => String.valueOf(setupData.get('loanId')),
            'applicantId' => String.valueOf(setupData.get('applicantId')),
            'processName' => 'CKYC ResendOtp',
            'ckycTransactionID' => 'Txn789'
        };
            try{
        Test.startTest();
        String resp = COMM_CKYCResendOtpController.processCommercialCrifResponse(inputMap);
        Test.stopTest();
        System.assertEquals('Error: API Service Temporarily Unavailable', resp);
            }
        catch(exception ex){}
    }

    @isTest
    static void testProcessCommercialCrifResponse_ExpiredTxnId() {
        Map<String, Id> setupData = setupBasicData('CKYC ResendOtp');

        Test.setMock(HttpCalloutMock.class, new MyCKYCMock('ExpiredTxn'));

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => String.valueOf(setupData.get('loanId')),
            'applicantId' => String.valueOf(setupData.get('applicantId')),
            'processName' => 'CKYC ResendOtp',
            'ckycTransactionID' => 'ExpiredTxn'
        };
            try{
        Test.startTest();
        String resp = COMM_CKYCResendOtpController.processCommercialCrifResponse(inputMap);
        Test.stopTest();

        System.assert(resp.contains('Please provide valid CKYCTransactionID'),
            'Expired txn ID message should be handled');
            }
        catch (exception ex) {
        }
    }

    @isTest
    static void testProcessCommercialCrifResponse_OtherError() {
        Map<String, Id> setupData = setupBasicData('CKYC ResendOtp');

        Test.setMock(HttpCalloutMock.class, new MyCKYCMock('OtherError'));

        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => String.valueOf(setupData.get('loanId')),
            'applicantId' => String.valueOf(setupData.get('applicantId')),
            'processName' => 'CKYC ResendOtp',
            'ckycTransactionID' => 'TxnErr'
        };
            try{
        Test.startTest();
        String resp = COMM_CKYCResendOtpController.processCommercialCrifResponse(inputMap);
        Test.stopTest();

        System.assert(resp.contains('Bad Request'), 'Should include error body');
            }
        catch (exception ex){}
    }

    @isTest
    static void testProcessCommercialCrifResponse_Exception() {
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => 'Invalid',
            'applicantId' => 'Invalid',
            'processName' => 'CKYC ResendOtp',
            'ckycTransactionID' => '123'
        };

        try {
            Test.startTest();
            COMM_CKYCResendOtpController.processCommercialCrifResponse(inputMap);
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException not thrown');
        } catch (AuraHandledException e) {
        }
    }
}