public class PennyDropCallout {
    
    public class RequestBody {
        public String consent;
        public String ifsc;
        public String accountNumber;
        
        public RequestBody(String consent, String ifsc, String accountNumber) {
            this.consent = consent;
            this.ifsc = ifsc;
            this.accountNumber = accountNumber;
        }
    }
    
    public static String sendHttpRequest(String ifscCode, String accountNumber) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        String endpoint = 'callout:Penny_Drop';
        request.setEndpoint(endpoint);
        System.debug('Endpoint: ' + endpoint);
        String bearer = Utility.getAccessToken();
        request.setMethod('POST');
        request.setHeader('Authorization', 'bearer '+ bearer);
        request.setHeader('ENTITYID', '14587854555');
        request.setHeader('Language', 'ENG');
        request.setHeader('ServiceVersion', '1');
        request.setHeader('MESSAGEID', '1683120193332CF4517');
        request.setHeader('RequestTime', '2023-05-04T12:00:00');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        
        RequestBody body = new RequestBody('Y', ifscCode, accountNumber);
        
        String requestBody = JSON.serialize(body);
        
        request.setBody(requestBody);
        
        HttpResponse response = http.send(request);
        
        String res = response.getBody();
        System.debug('Response Body: ' + res);
        
        return res;
    }
}