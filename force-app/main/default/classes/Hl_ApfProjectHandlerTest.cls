@isTest class Hl_ApfProjectHandlerTest {
    
    @testSetup static void testSetup(){
        
        Project__c project = new Project__c(Name = 'Test Project',Is_APF_Generated__c=true,
                                            RecordTypeId = Schema.SObjectType.Project__C.getRecordTypeInfosByName().get('Project').getRecordTypeId());
        insert project;
        TestDataFactory.setupIntegrationSettings('update_plf_master');
        TestDataFactory.setupIntegrationSettings('Get Token');
    }
    
    @isTest static void test1(){
        Project__c b= [SELECT ID from Project__c LIMIT 1];
        List<Hl_ApfProjectHandler.ProjectCalloutInput> inputList = new List<Hl_ApfProjectHandler.ProjectCalloutInput>();        
        Hl_ApfProjectHandler.initiateCallout(inputList);
        Hl_ApfProjectHandler.ProjectCalloutInput bi = new Hl_ApfProjectHandler.ProjectCalloutInput();
        bi.projectRecordId = b.Id;
        bi.operationType = 'insert';
        inputList.add(bi);
        try{
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CalloutMock());
        Hl_ApfProjectHandler.initiateCallout(inputList);
        Hl_ApfProjectHandler.parse(JSON.serialize(new Map<String,String>()));
        }catch(exception e){}
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