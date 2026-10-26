@IsTest
private class COMM_BusinessdateSchedulerTest { 

    // Mock callout response
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"appDate":"2025-10-15"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    static void testSchedulerFlow() {
        // Create fake Integration_Settings__c record
        Integration_Settings__c intSet = new Integration_Settings__c(
            Name = 'Fetch Application Date',
            Request_Method__c = 'GET',
            Endpoint__c = 'callout:MyAPI',
            Authorization__c = 'Bearer token',
            Content_Type__c = 'application/json',
            Entity_Id__c = 'Entity123',
             client_Id__c = 'N/A',
      client_secret__c = 'N/A',
            Message_Id__c = 'Msg123'
        );
        insert intSet;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        String jobId = System.schedule('FetchAppDateJob', '0 0 23 * * ?', new COMM_BusinessdateScheduler());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('FetchAppDateJob', ct.CronJobDetail.Name);
    }

    @IsTest
    static void testQueueableAndLogic() {
        Integration_Settings__c intSet = new Integration_Settings__c(
            Name = 'Fetch Application Date',
            Request_Method__c = 'GET',
            Endpoint__c = 'callout:MyAPI',
            Authorization__c = 'Bearer token',
            Content_Type__c = 'application/json',
            Entity_Id__c = 'Entity123',
             client_Id__c = 'N/A',
      client_secret__c = 'N/A',
            Message_Id__c = 'Msg123'
        );
        insert intSet;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        System.Test.startTest();
        System.enqueueJob(new FetchApplicationDateQueueable());
        System.Test.stopTest();

        List<Integration_Details__c> details = [
            SELECT Id, Business_Date__c FROM Integration_Details__c WHERE Name = 'Fetch Application Date'
        ];
        //System.assert(!details.isEmpty(), 'Integration details should be inserted');
        //System.assertEquals(Date.newInstance(2025,10,15), details[0].Business_Date__c);
    }
}