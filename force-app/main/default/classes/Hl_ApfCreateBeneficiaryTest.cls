@isTest class Hl_ApfCreateBeneficiaryTest {
    
    @testSetup static void DataSetup(){
        Bank_Details__c bank = new Bank_Details__c( Account_Holder_Name__c = 'John Doe',
                                                   Account_Type__c = 'Saving');
        insert bank;
         Integration_Details__c intDet = new Integration_Details__c(
            Name = 'Existing Beneficiary',
            Bank_Details__c = bank.Id,
            Customer_Id__c = 'BEN12345',
            Is_Sync__c = true,
            EndPoint__c = 'https://example.com'
        );
        insert intDet;
        TestDataFactory.setupIntegrationSettings('Get Token');
        
    }
    
    @isTest static void test1(){
        Bank_Details__c b = [SELECT ID FROM Bank_Details__c LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CalloutMock());
        Hl_ApfCreateBeneficiary.initiateApfCreateBeneficiary(new List<Id>{b.Id},'test');    
        Hl_ApfCreateBeneficiary.beneficiaryApexToJson(b.Id);
        Hl_ApfCreateBeneficiary.CalloutInputWrapper input =new Hl_ApfCreateBeneficiary.CalloutInputWrapper();
        input.BeneficiaryId = b.Id;
        input.Operation = 'create';
        try{
        Hl_ApfCreateBeneficiary.initiateCallout(new List<Hl_ApfCreateBeneficiary.CalloutInputWrapper>{ input });
        }catch(exception e){}
        Test.stopTest();
        Hl_ApfCreateBeneficiary.parse(JSON.serialize(new Map<String,String>()));
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