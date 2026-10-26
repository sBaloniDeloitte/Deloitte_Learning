@isTest
global class CreateFinanceAhlControllerHttpMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"returnStatus":{"returnText":"Success"},"finReference":"FIN12345","financeSchedule":{"summary":{"effectiveRateOfReturn":8.5}}}');
        res.setStatusCode(200);
        return res;
    }
}