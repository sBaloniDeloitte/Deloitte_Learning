public class ErrorCode500Mock implements HttpCalloutMock {
    public HTTPResponse respond (HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(500);
        res.setBody('{"status_code":500}');
        return res;
    }


    public HTTPResponse respond418 (HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(418); // No mapping
        res.setBody('{"status_code":418}');
        return res;
    }
}