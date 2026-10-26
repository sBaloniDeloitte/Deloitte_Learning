@isTest class COMM_GetCollateraDetailsControllerTest {
    
    @testSetup static void dataSetup(){        
        TestDataFactory.setupIntegrationSettings('Get Token');
        
    }
    @isTest static void test1(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CalloutMock());
        COMM_GetCollateraDetailsController.getCollateralDetails('customerId', 'Get Token');
        Test.stopTest();
    }
    
    class CalloutMock implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type','application/json');
            Map<String,Object> body = new Map<String,Object>();
            body.put('finReference','GHF1001HL0005309');
            body.put('returnStatus',new Map< String,String>{'returnCode'=>'009','returnText'=>'Success'});
            body.put('disbursements',new List<Object>());
            res.setBody(JSON.serialize(body));
            res.setStatusCode(200);
            return res;
        }
    }
}