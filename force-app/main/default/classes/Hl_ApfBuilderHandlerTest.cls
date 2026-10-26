@isTest class Hl_ApfBuilderHandlerTest {
    
    
    @testSetup static void testSetup(){
        
        Builder__c builder = new Builder__c(Name = 'Test Builder');
        insert builder;
        TestDataFactory.setupIntegrationSettings('update_plf_master');
        TestDataFactory.setupIntegrationSettings('Get Token');
    }
    
    @isTest static void test1(){
        Builder__c b= [SELECT ID from Builder__c LIMIT 1];
        List<Hl_ApfBuilderHandler.BuilderCalloutInput> inputList = new List<Hl_ApfBuilderHandler.BuilderCalloutInput>();
        
        Hl_ApfBuilderHandler.initiateCallout(inputList);
        Hl_ApfBuilderHandler.BuilderCalloutInput bi = new Hl_ApfBuilderHandler.BuilderCalloutInput();
        bi.builderRecordId = b.Id;
        bi.operationType = 'insert';
        inputList.add(bi);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CalloutMock());
        Hl_ApfBuilderHandler.initiateCallout(inputList);
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