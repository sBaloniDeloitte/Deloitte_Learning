@IsTest
private class ShopAndEstablishmentCheckControllerTest {
    Private static  string processname = 'Shop & Establishment';
    // Mock class for HTTP callouts
    class ShopAndEstablishmentMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            // Sample success JSON response
            res.setBody('{"statusCode":101,"result":{"category":"Commercial Establishment","status":"Active","ownerName":"Ramanand","entityName":"Shiva Enterprises","registrationDate":"2/1/2017","validTo":"2/1/2025","contact":"9560084286","commenceDate":"2/1/2017","totalWorkers":"5","natureOfBusiness":"Others","address":"N-18/242, L-block Jj Colony Wazirpur Delhi, Delhi. PIN-110052","email":"spraygunsales@gmail.com","websiteUrl":"www.example.com","applicantName":"Ramanand","regNo": "S12345"}}');
            return res;
        }
    }
    
    @TestSetup
    static void setupTestData() {
        TestDataFactory.setupIntegrationSettings('Gen AI');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Account Aggregator');
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('Loan URL Shortening Service');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Hunter');
        TestDataFactory.setupIntegrationSettings('Loan Applicant Net Banking');
        TestDataFactory.setupTriggerSettings();
        // Create a test Opportunity
        Account acc = TestDataFactory.createAccountRecord('TestAcc');
        insert acc;
        
        Opportunity loan = TestDataFactory.getTestOpportunityData(1, false)[0];
        loan.AccountId = acc.Id;
        loan.StageName = 'Prospecting';
        loan.CloseDate = Date.today();
        loan.Product__c = 'Affordable Home Loan';
        insert loan;
        
        
        
        // Jurisdiction Area Codes metadata
        /* Jurisdiction_Area_Code__mdt area = new Jurisdiction_Area_Code__mdt(
DeveloperName = 'SHOP_001',
Label = 'Area 1',
Activity_Name__c = 'Shop & Establishment'
);
insert area; */
    }
    
    @IsTest
    static void testInitiateAPIRequest_Success() {
        Test.setMock(HttpCalloutMock.class, new ShopAndEstablishmentMock());
        
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => [SELECT Id FROM Opportunity LIMIT 1].Id,
                'processName' => processname,
                'registrationNumber' => 'S12345',
                'areaCode' => 'SHOP_001'
                };
                    
                    Test.startTest();
        String response = ShopAndEstablishmentCheckController.initiateAPIRequest(inputMap);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testGetAreaCodes() {
        Map<String,String> areaCodes = ShopAndEstablishmentCheckController.getAreaCodes(processname);
     
    }
    
    @IsTest
    static void testCheckIfAlreadyFetch() {
        // Insert a dummy Integration_Details__c record
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        ShopAndEstablishmentCheckController.ShopAndEstablishmentRequestWrapper req = new ShopAndEstablishmentCheckController.ShopAndEstablishmentRequestWrapper();
        req.regNo = 'S12345';
        String reqJson = JSON.serialize(req);
        Integration_Details__c integrationDetail =  fitestdatafactory.createIntegrationDetails(false );
        integrationDetail.Name = processname ;
        integrationDetail.Loan_Application__c = opp.id;
        integrationDetail.Related_Record_Id__c = opp.id ;
        integrationDetail.Endpoint__c = 'test.com';
        integrationDetail.status__c='200';
        integrationDetail.Object_Name__c = 'Opportunity' ;
        integrationDetail.Request_JSON__c = '{"regNo":"S12345","pdfRequired":false,"consent":"Y","areaCode":"SHOP_001"}';
        integrationDetail.Response_JSON__c =  '{"requestId":"REQ-12345","statusCode":101,"result":{"category":"Commercial Establishment","status":"Active","ownerName":"Ramanand","entityName":"Shiva Enterprises","registrationDate":"2020-01-15","validTo":"2025-01-15","contact":"9876543210","commenceDate":"2020-01-15","totalWorkers":"5","natureOfBusiness":"Retail","address":"123 Market Road, Delhi","validFrom":"2020-01-15","email":"test@example.com","websiteUrl":"www.shivaenterprises.com","applicantName":"Ramanand","regNo":"S12345"},"clientData":{"caseId":"CASE-001"}}' ;
        
        
        insert integrationDetail ;
        
        Boolean isCalled = ShopAndEstablishmentCheckController.checkIfAlreadyFetch(opp.Id, 'S12345');
    }
    
    @IsTest
    static void testGetShopExistingData() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Insert Integration_Details__c with request and response JSON
        ShopAndEstablishmentCheckController.ShopAndEstablishmentRequestWrapper reqWrapper = new ShopAndEstablishmentCheckController.ShopAndEstablishmentRequestWrapper();
        reqWrapper.regNo = 'S12345';
        String reqJson = JSON.serialize(reqWrapper);
        
        ShopAndEstablishmentCheckController.ShopAndEstablishmentResponseWrapper respWrapper = new ShopAndEstablishmentCheckController.ShopAndEstablishmentResponseWrapper();
        respWrapper.statusCode = 101;
        respWrapper.result = new ShopAndEstablishmentCheckController.cls_result();
        respWrapper.result.category = 'Commercial Establishment';
        String respJson = JSON.serialize(respWrapper);
        Integration_Details__c integrationDetail =   TestDataFactory.getTestIntegrationDetails(1,  opp.id,  false)[0];
        integrationDetail.Name = processname ;
        integrationDetail.Loan_Application__c = opp.id;
        integrationDetail.Related_Record_Id__c = opp.id ;
        integrationDetail.Endpoint__c = 'test.com';
        integrationDetail.status__c='200';
        integrationDetail.Object_Name__c = 'Opportunity' ;
        integrationDetail.Request_JSON__c = '{"regNo":"S12345","pdfRequired":false,"consent":"Y","areaCode":"SHOP_001"}';
        integrationDetail.Response_JSON__c =  '{"requestId":"REQ-12345","statusCode":101,"result":{"category":"Commercial Establishment","status":"Active","ownerName":"Ramanand","entityName":"Shiva Enterprises","registrationDate":"2020-01-15","validTo":"2025-01-15","contact":"9876543210","commenceDate":"2020-01-15","totalWorkers":"5","natureOfBusiness":"Retail","address":"123 Market Road, Delhi","validFrom":"2020-01-15","email":"test@example.com","websiteUrl":"www.shivaenterprises.com","applicantName":"Ramanand","regNo":"S12345"},"clientData":{"caseId":"CASE-001"}}' ;
        
        
        insert integrationDetail ;
        
        
        List<ShopAndEstablishmentCheckController.cls_result> results = ShopAndEstablishmentCheckController.getShopExistingData(opp.Id, processname);
    }
}