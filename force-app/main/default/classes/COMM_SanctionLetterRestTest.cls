@isTest class COMM_SanctionLetterRestTest {

    @isTest static void test(){
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
          Opportunity opp = [SELECT Id, Name FROM opportunity];
      
        req.requestURI = '/services/apexrest/'+opp.Name; //Request URL
        req.httpMethod = 'POST';
        RestContext.request = req;
        COMM_SanctionLetterRest.getSanctionLetterpayload();
            
    }
    
    
    @isTest static void test1(){
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
          Opportunity opp = [SELECT Id, Name FROM opportunity];
      
        req.requestURI = '/services/apexrest/'; //Request URL
        req.httpMethod = 'POST';
        RestContext.request = req;
        COMM_SanctionLetterRest.getSanctionLetterpayload();
            
    }
    
    
    
    @isTest static void test2(){
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
      
        req.requestURI = '/services/apexrest/xvcs'; //Request URL
        req.httpMethod = 'POST';
        RestContext.request = req;
        COMM_SanctionLetterRest.getSanctionLetterpayload();
            
    }
}