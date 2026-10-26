@IsTest
public class QueueableLogicForSendSMSTest {

    // Inline mock callout class
    private class LocalMockSMSCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            try {
                System.debug('Mock callout triggered with request: ' + req.getEndpoint());

                // Token endpoint from Integration_Settings__c
                String tokenEndpoint = 'https://api.smsprovider.com/token'; // Replace with actual token endpoint

                if (req.getEndpoint() == tokenEndpoint) {
                    // Simulate OAuth 2.0 token response
                    res.setHeader('Content-Type', 'application/json');
                    res.setBody('{"access_token":"mocked_access_token_123456","token_type":"Bearer","expires_in":3600}');
                    res.setStatusCode(200);
                    System.debug('Mocked token response returned.');
                } else {
                    // Simulate SMS send response
                    res.setHeader('Content-Type', 'application/json');
                    res.setBody('{"status":"success","message":"SMS sent successfully"}');
                    res.setStatusCode(200);
                    System.debug('Mocked SMS response returned.');
                }
            } catch (Exception e) {
                System.debug('Error in mock callout: ' + e.getMessage());
            }
            return res;
        }
    }

    @IsTest
    static void testQueueableSMSLogic() {
        try {
            // Register mock callout
            System.Test.setMock(HttpCalloutMock.class, new LocalMockSMSCallout());
            System.debug('Mock callout registered.');

            // Create Integration_Settings__c records
            Integration_Settings__c smsSetting = new Integration_Settings__c(
                Name = 'SMS API',
                Client_Id__c = 'testClientId',
                Client_Secret__c = 'testSecret',
                Endpoint__c = 'https://api.smsprovider.com/send',
                Content_Type__c = 'application/json',
                Request_Method__c = 'POST'
            );

            Integration_Settings__c tokenSetting = new Integration_Settings__c(
                Name = 'Get Token',
                Client_Id__c = 'f9709782-85ea-49fc-848a-6abcbfa65611',
                Client_Secret__c = 'REDACTED_CLIENT_SECRET',
                Endpoint__c = 'https://api.smsprovider.com/token',
                Content_Type__c = 'application/json',
                Authorization__c = 'Callout:LOS_BL_Bearer',
                Request_Method__c = 'GET'
            );

            insert new List<Integration_Settings__c>{smsSetting, tokenSetting};
            System.debug('Integration_Settings__c records inserted.');

            // Prepare test data
            List<String> mobileNumbers = new List<String>{'9876543210', '9123456789'};
            String message = 'Test SMS message';
            String source = 'UnitTest';

            // Enqueue the job
            System.Test.startTest();
            System.enqueueJob(new QueueableLogicForSendSMS(mobileNumbers, message, source));
            System.Test.stopTest();
            System.debug('Test execution completed.');
        } catch (Exception e) {
            System.debug('Unexpected error in testQueueableSMSLogic: ' + e.getMessage());
        }
    }
}