@isTest
public class UCICCreateAndSearchCustomerCtlrTest {
    @TestSetup
    static void setupData() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        customer.Customer_LMS_Id__c = 'LMS123';
        update customer;
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        applicant.DOB__c = Date.today().addYears(-20);
        Update applicant;
        Application_Verification__c appVer = new Application_Verification__c();
        appVer.Stage__c = 'Draft';
        appVer.Loan_Application__c = loan.Id;
        insert appVer;
        
        ContentVersion contentVersionObj = FITestDataFactory.createContentVersionDetails();
        Document_Details__c bankDocDetailsObj = FITestDataFactory.createBankSentimentAnalysisDetails(contentVersionObj);
        bankDocDetailsObj.Application_Verification__c=appVer.Id;
        update bankDocDetailsObj;
        Lead testLead = new Lead(
            LastName = 'TestLead',
            Company = 'TestCompany',
            MobilePhone = '9342345676',
            Product__c = 'Affordable Home Loan',
            Channel__c = 'Direct',
            Status = 'Open',
            Customer_Type__c='Individual',
            FirstName='test',
            PAN__c='test123c'
            //  Lead_Number__c='test123'
        );
        insert testLead;
        Integration_Details__c integrationDetail = new Integration_Details__c(
            Name = 'Fetch Application Date',
            Loan_Application__c = loan.Id,
            Related_Record_Id__c = loan.Id,
            Endpoint__c = 'test.com',
            Response_JSON__c = 'responseJson',
            status__c='200',
            Business_Date__c=date.today()
        );
        insert integrationDetail;
        Integration_Settings__c setting = new Integration_Settings__c();
        // setting.Name = 'Get Token';
        setting.Name= 'UCIC Search Customer';
        setting.Client_Id__c ='XXXXXXXXXX';
        setting.Cookie__c='XXXXXXXXXXX';
        setting.Client_Secret__c='XXXXXXXXXXX';
        setting.Endpoint__c='Callout:LOS_BL_Bearer';
        setting.Content_Type__c='application/json';
        setting.Authorization__c='XXXXXXXXXXX';
        setting.Request_Method__c='GET';
        setting.Message_Id__c = 'settingMSGID';
        setting.Entity_Id__c ='ENTITYID';
        insert setting;
        Integration_Settings__c intDetails = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'NA',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_FICO',
            Content_Type__c = 'application/json',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Request_Method__c = 'POST'
        );
        insert intDetails;
    }
    private class MockHttpResponseGeneratorUCIC implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"Response":{"StatusInfo":{"RequestId":"1767350032032","CUSTUNQID":"0015605","Status":"C","StatusMessage":"Success","ResponseCode":"200","Description":"Request processed successfully","MatchCount":"0","UCIC":"1000412236","UCIC_Type":"N"}}}');
            return res;
        }
    }
    @isTest
    static void testMethod1() {
        Account acc=[select id from Account limit 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Customer__c FROM Application_Applicant__c LIMIT 1];
        app.Name = 'Test Applicant';
        app.UCIC_Number__c = '123456789';
        app.Customer__c=acc.Id;
        update app;
        Integration_Details__c intDetail = new Integration_Details__c(
            Name = 'UCIC Search Customer',
            Endpoint__c = 'https://test.endpoint.com'
        );
        insert intDetail;
        
        Date myDate = Date.newInstance(2016, 12, 9);
        //String formattedDate = myDate.format('MM/dd/yyyy'); // e.g., "10/07/2025"
        //String defaultDateString = 
        
        Map<String, String> inputMap = new Map<String, String>{
            'recordId' => opp.Id,
                'applicantId' => app.Id,
                'processName' => 'UCIC Search AND Create',
                'panNum' => 'ABCPE1234F',
                'dob' => String.valueOf(myDate)
                
                };
                    
                    Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorUCIC());
        //List<COMM_GetFinanceDetailsByUCICController.Finance> financeList = COMM_GetFinanceDetailsByUCICController.getCustomerFinances('129989', 'Get Customer By UCIC');
        try{
            String result = UCICCreateAndSearchCustomerController.initiateAPIRequest(inputMap);
        }
        catch (exception e){}
        Test.stopTest();
    }
}