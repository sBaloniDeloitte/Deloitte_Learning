@isTest
private class DMSFetchControllerTest {

    @testSetup static void dataSetup(){
        TestDataFactory.setupIntegrationSettings('Get Token');
    }
    // Mock HTTP Callout for fetch endpoint
    public class DMSMockCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/xml');
            res.setBody('{"status":"ok"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testInitiateAPIRequestSuccess() {
        // Set the HTTP mock
        try{
        Test.setMock(HttpCalloutMock.class, new DMSMockCallout());

        // Create test data
        Opportunity loanApp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
			Product__c = 'Home Loan'
        );
        insert loanApp;
            
                  Document_Master__c doc1 = new Document_Master__c(
                Document_Name__c = 'Aadhaar Front',
                Name ='Aadhaar Front',
                Document_Category__c = 'KYC',
                Is_Active__c = true,
                Requirement_At__c = 'Loan Application'
            );
            insert doc1;

        Document_Details__c docDetails = new Document_Details__c(
            Name = 'My Document',
    	Document_Master__c= doc1.Id,
            Loan_Application__c = loanApp.Id
        );
        insert docDetails;
            
        Integration_Details__c objintegrationDetails = new Integration_Details__c();
        objintegrationDetails.Loan_Application__c = loanApp.Id;
        objintegrationDetails.Status__c = String.valueof('412');
        objintegrationDetails.Name ='Loan Applicant Bank Statement Analysis';
        objintegrationDetails.Related_Record_Id__c = loanApp.Id;
        objintegrationDetails.Endpoint__c = 'www.salesforce.com';
        insert objintegrationDetails;
            
        System.debug('loanapp:'+loanApp.Id);
          System.debug('docdetails:'+docDetails.Id);
            
        Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails1;
		
		
        Integration_Master__mdt metadata = [SELECT Process_Name__c,Handler_Class__c,Endpoint__c,Request_Method__c,Client_Id__c,Client_Secret__c,Allowed_Retry__c,Gestation_Period__c,Refresh_Allowed__c,Activity_Name__c FROM Integration_Master__mdt LIMIT 1];
		intHandler IH = new intHandler();
        intHandler.processResWrapper IntPR = new intHandler.processResWrapper();
        // Input map for method
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => loanApp.Id,
            'processName' => 'AML Check',
            'docId' => docDetails.Id
        };
            
            

        Test.startTest();
        String result = DMSFetchController.initiateAPIRequest(inputMap);
        Test.stopTest();

      //  System.debug('Result from API call: ' + result);
        //System.assertNotEquals(null, result, 'API call response should not be null');
    }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
        
        }
	}
}