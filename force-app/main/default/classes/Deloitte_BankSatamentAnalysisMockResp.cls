public with sharing class Deloitte_BankSatamentAnalysisMockResp {
    
    public static HttpResponse getHttpBankSatamentAnalysisMockResponse() {
        
        HttpResponse resp = new HttpResponse();
        resp.setHeader('Content-Type', 'application/json');
        resp.setStatusCode(200);
        
        //String mockJson = '{"status":true,"message":"Transaction Cancelled Successfully","statusCode":"bsa-200","traceId":"3ec94af3-81bf-4b41-9074-c0d2dd5c11ed","perfiosTransactionId":"L2PA1739172727009","isMockResponse":true,"data":{"perfiosTransactionId":"L2PA1739172727009","canceltransactionResult":"successfully cancel transaction","files":[{"filename":"Financial-Examples-for-I20.pdf","fileID":"cc40d8afe6e60f7dd5187106f124aad0377bd9a4","StatusCode":"bsa-200","Message":{"message":"File processing ","error":{"code":"CannotProcessFile","message":"We could not process the statement file uploaded by the Client","details":[{"code":"E_STATEMENT_WRONG_FORMAT","field":"file","message":"This statement contains images. Please upload again and select scanned images option.","value":{"type":"PDF","issue":"Image-based content"}}]}}}],"error":{"code":"PARTIAL_SUCCESS","message":"Transaction cancelled but some files failed processing","details":[{"code":"FILE_ERROR","field":"files[0]","message":"One or more files failed during processing","value":{"failedFile":"Financial-Examples-for-I20.pdf"}}]}}}';
        String mockJson = '{"status":true,"message":"Transaction Cancelled Successfully","statusCode":"bsa-200","traceId":"3ec94af3-81bf-4b41-9074-c0d2dd5c11ed","perfiosTransactionId":"L2PA1739172727009","isMockResponse":true,"data":{"perfiosTransactionId":"L2PA1739172727009","canceltransactionResult":"successfully cancel transaction","files":[{"filename":"Financial-Examples-for-I20.pdf","fileID":"cc40d8afe6e60f7dd5187106f124aad0377bd9a4","StatusCode":"bsa-200","Message":{"message":"File processing ","error":null}}],"error": null}}';
        resp.setBody(mockJson);
        
        return resp;
    }

    public static HttpResponse getHttpckycMockResponse() {
        
        HttpResponse resp = new HttpResponse();
        resp.setHeader('Content-Type', 'application/json');
        resp.setStatusCode(200);
        
        //String mockJson = '{"response":{"A99ResponseData":{"CKYCDownloadResult":"","xmlns:xsi":"http://www.w3.org/2001/XMLSchema-instance","xmlns:xs":"http://www.w3.org/2001/XMLSchema","CKYCSearchResult":{"CKYCAvailable":"No","CKYCStatus":"OTPTriggeredByCKYC","CKYCRequestId":10000002,"CKYCTransactionID" : 1234567890},"RequestStatus":"AcceptedByTW"}}}';
        String mockJson = '{"response":{"A99ResponseData":{"CKYCDownloadResult":{"CKYCStatus":"OTPTriggeredByCKYC","CKYCTransactionID":1234567890,"CKYCReferenceID":"123456"},"CKYCSearchResult":{"CKYCAvailable":"No","CKYCStatus":"OTPTriggeredByCKYC","CKYCRequestId":10000002,"CKYCTransactionID":1234567890},"RequestStatus":"AcceptedByTW"}}}';
        resp.setBody(mockJson);
        
        return resp;
    }
    
    public static HttpResponse getFailureResponse() {
        
        HttpResponse resp = new HttpResponse();
        resp.setHeader('Content-Type', 'application/json');
        resp.setStatusCode(200);
        
        String mockJson = '{' +
            '"status": false,' +
            '"message": "Transaction Failed",' +
            '"statusCode": "bsa-500",' +
            '"traceId": "fail-trace-001",' +
            '"perfiosTransactionId": "FAIL123456",' +
            '"isMockResponse": true,' +
            '"data": {' +
            '"perfiosTransactionId": "FAIL123456",' +
            '"canceltransactionResult": "failure",' +
            '"files": [],' +
            '"error": {' +
            '"code": "TRANSACTION_FAILED",' +
            '"message": "Unable to cancel transaction",' +
            '"details": [' +
            '{' +
            '"code": "TXN_ERROR",' +
            '"field": "transaction",' +
            '"message": "Invalid transaction ID",' +
            '"value": "FAIL123456"' +
            '}' +
            ']' +
            '}' +
            '}' +
            '}';
        
        resp.setBody(mockJson);
        return resp;
    }
    
    public static HttpResponse getAcceptedResponse() {
        
        HttpResponse resp = new HttpResponse();
        resp.setHeader('Content-Type', 'application/json');
        resp.setStatusCode(202); // ✅ Accepted
        
        String mockJson = '{' +
            '"status": true,' +
            '"message": "Request accepted for processing",' +
            '"statusCode": "bsa-202",' +
            '"traceId": "async-trace-002",' +
            '"perfiosTransactionId": "ASYNC123456",' +
            '"isMockResponse": true,' +
            '"data": {' +
            '"perfiosTransactionId": "ASYNC123456",' +
            '"canceltransactionResult": "processing",' +
            '"files": [],' +
            '"error": null' +
            '}' +
            '}';
        
        resp.setBody(mockJson);
        return resp;
    }
    
    public static HttpResponse getBadRequestResponse() {
        
        HttpResponse resp = new HttpResponse();
        resp.setHeader('Content-Type', 'application/json');
        resp.setStatusCode(400); // ❌ Bad Request
        
        String mockJson = '{' +
            '"status": false,' +
            '"message": "Bad Request",' +
            '"statusCode": "bsa-400",' +
            '"traceId": "badreq-trace-003",' +
            '"perfiosTransactionId": null,' +
            '"isMockResponse": true,' +
            '"data": {' +
            '"perfiosTransactionId": null,' +
            '"canceltransactionResult": null,' +
            '"files": [],' +
            '"error": {' +
            '"code": "INVALID_REQUEST",' +
            '"message": "Required parameters are missing",' +
            '"details": [' +
            '{' +
            '"code": "MISSING_FIELD",' +
            '"field": "perfiosTransactionId",' +
            '"message": "Transaction ID is required",' +
            '"value": null' +
            '}' +
            ']' +
            '}' +
            '}' +
            '}';
        
        resp.setBody(mockJson);
        return resp;
    }
    
    
}