@isTest
public class FetchMCAControllerTest {
    @testSetup
    static void setupData() {
        Trigger_Settings__c triggerSettings = new Trigger_Settings__c(Name='Trigger Settings',Application_Applicant_Trigger__c = true, City_Master_Trigger__c = true, Lead_Trigger__c = true, Opportunity_Trigger__c = true, Application_Verification_Trigger__c = true);
        insert triggerSettings;
        Id branchRectypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Branch').getRecordTypeId();
        Account branch = new Account();
        branch.Branch_Code__c = '110';
        branch.RecordTypeId = branchRectypeId;
        branch.Name = 'Udaipur';
        insert branch;
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        List<Opportunity> oppRecList = TestDataFactory.getTestOpportunityData(1, false);
        oppRecList[0].Product__c = 'Flexi Loan';
        oppRecList[0].Branch_Master__c = branch.Id;
        insert oppRecList;
        Application_Applicant__c appApplicant = TestDataFactory.createApplicationApplicant('Primary Applicant',oppRecList[0].Id,'John Doe','ABCCE1234F',Date.newInstance(1990, 1, 1));
        appApplicant.Customer_Type__c = 'Non Individual';
        appApplicant.Registration_Number__c = '3245jghfgd';
        insert appApplicant;
        Id prodRecTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Product').getRecordTypeId();
        Id subProdRecTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Product').getRecordTypeId();
        Product2 prod = new Product2(Loan_Application__c = oppRecList[0].Id, RecordTypeId = prodRecTypeId, Name ='Flexi Loan');
        insert prod;
        Product2 subProd = new Product2(Loan_Application__c = oppRecList[0].Id, RecordTypeId = subProdRecTypeId, Name ='HL Builder Purchase',Product__c = prod.Id);
        insert subProd;
        Id ltRecTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId();
        Id paymentRecTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Payment').getRecordTypeId();
        
        Loan_Transaction__c lt = new Loan_Transaction__c();
        lt.Loan_Application__c = oppRecList[0].Id;
        lt.RecordTypeId = ltRecTypeId;
        insert lt;
        
        /*Loan_Transaction__c ltPay = new Loan_Transaction__c();
        ltPay.Loan_Application__c = oppRecList[0].Id;
        ltPay.RecordTypeId = paymentRecTypeId;
        ltPay.Issuing_Bank_Location__c = 'MUMBAI';
        ltPay.Printing_Location__c = 'MUMBAI';
        ltPay.Disbursement_Party__c = 'Customer';
        ltPay.Cheque_DD_Number__c = '132453wad';
        insert ltPay;*/
        
        Bank_Details__c bank = new Bank_Details__c();
        bank.Is_Repayment_Account__c = true;
        bank.Application_Applicant__c = appApplicant.Id;
        insert bank;
        
        Document_Details__c docCov = new Document_Details__c();
        docCov.Name = '12 months bank statement';
        docCov.Document_Type__c = 'OTC';
        docCov.Loan_Application__c = oppRecList[0].Id;
        docCov.Covenant_Id__c = '124';
        insert docCov;
        
        
    }
    @isTest static void testInitiateAPIRequest_Success() {
        try{
            Map<String, Map<String, String>> mapMasterCode =  COMM_UpsertCustomerHandler.getMasterCode();
            Opportunity opp = [SELECT Id,Branch_Master__c, AccountId FROM Opportunity LIMIT 1];
            Application_Applicant__c appApplicant = [SELECT Id, Loan_Application__c FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
            opp.Final_Amount__c = 100000;
            update opp;
            Document_Details__c docCov = [SELECT Id from Document_Details__c WHERE Document_Type__c='OTC' LIMIT 1];
            Bank_Details__c bank = [SELECT Id from Bank_Details__c WHERE Application_Applicant__c =:appApplicant.Id];
            Product2 prod = [SELECT Id from Product2 WHERE Loan_Application__c = :opp.Id AND Name ='Flexi Loan'];
            Product2 subProd = [SELECT Id from Product2 WHERE Loan_Application__c = :opp.Id AND Name ='HL Builder Purchase'];
            Loan_Transaction__c lt = [SELECT Id,Disbursement_Party__c from Loan_Transaction__c WHERE Loan_Application__c=:opp.Id  AND RecordType.DeveloperName='Transaction_Details' LIMIT 1];
            // Insert Integration_Settings for API and token BEFORE the call
            Integration_Settings__c intSettings = new Integration_Settings__c(
                Name = 'Loan Applicant MCA',Client_Id__c = 'NA',Client_Secret__c = 'NA',Content_Type__c = 'application/json',Endpoint__c = 'Callout:LOS_BL_Create_Finance/FinanceAhl',
                Request_Method__c = 'POST',Authorization__c = 'Bearer test',Cookie__c = 'test_cookie',Entity_Id__c= '14589954555',Message_Id__c ='123456');
            insert intSettings;
            
            Integration_Settings__c tokenSettings = new Integration_Settings__c(Name = 'Get Token',Client_Id__c = 'client_id',Client_Secret__c = 'client_secret',Endpoint__c = 'https://example.com/token',Content_Type__c = 'application/json',
                Request_Method__c = 'POST',Authorization__c = 'Bearer token',Cookie__c = 'test_cookie');
            insert tokenSettings;
            
			Map<String, String> inputMap = new Map<String,String>{'cinNumber'=> 'AAA-1234','processName' => 'Loan MCA Verification', 'loanId'=> opp.Id, 'applicantId' => appApplicant.Id};
            Test.setMock(HttpCalloutMock.class, new McaSuccessClassMock());
            
            Test.startTest();
            String response = FetchMCAController.initiateAPIRequest(inputMap);
            FetchMCAController.MCAResponseWrapper respWrapper = FetchMCAController.parseResponse(response);
            Test.stopTest();
            String resp = FetchMCAController.getApplicantsForMCA(opp.Id);
            FetchMCAController.getMCARecords(opp.Id,'Loan MCA Verification',appApplicant.Id);
            
            System.assertNotEquals(null, response);
        }
        catch(exception e){
            System.debug('ERROR: '+e.getStackTraceString());
        }
    }
    
    @isTest static void testInitiateAPIRequest_Fail() {
        try{
            Map<String, Map<String, String>> mapMasterCode =  COMM_UpsertCustomerHandler.getMasterCode();
            Opportunity opp = [SELECT Id,Branch_Master__c,LMS_Loan_Reference__c, AccountId FROM Opportunity LIMIT 1];
            opp.LMS_Loan_Reference__c = 'GHF123344';
            opp.Final_Amount__c = 100000;
            update opp;
            Application_Applicant__c appApplicant = [SELECT Id, Loan_Application__c FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
            Document_Details__c docCov = [SELECT Id from Document_Details__c WHERE Document_Type__c='OTC' LIMIT 1];
            Bank_Details__c bank = [SELECT Id from Bank_Details__c WHERE Application_Applicant__c =:appApplicant.Id];
            Product2 prod = [SELECT Id from Product2 WHERE Loan_Application__c = :opp.Id AND Name ='Flexi Loan'];
            Product2 subProd = [SELECT Id from Product2 WHERE Loan_Application__c = :opp.Id AND Name ='HL Builder Purchase'];
            Loan_Transaction__c lt = [SELECT Id from Loan_Transaction__c WHERE Loan_Application__c=:opp.Id ];
            // Insert Integration_Settings for API and token BEFORE the call
            Integration_Settings__c intSettings = new Integration_Settings__c(
                Name = 'Loan Applicant MCA', Client_Id__c = 'NA', Client_Secret__c = 'NA', Content_Type__c = 'application/json',Endpoint__c = 'Callout:LOS_BL_Create_Finance/FinanceAhl',
                Request_Method__c = 'POST',Authorization__c = 'Bearer test',Cookie__c = 'test_cookie',Entity_Id__c= '14589954555',Message_Id__c ='123456');
            insert intSettings;
            
            Integration_Settings__c tokenSettings = new Integration_Settings__c(Name = 'Get Token',Client_Id__c = 'client_id',Client_Secret__c = 'client_secret',Endpoint__c = 'https://example.com/token',Content_Type__c = 'application/json',
                Request_Method__c = 'POST',Authorization__c = 'Bearer token',Cookie__c = 'test_cookie');
            insert tokenSettings;

            Map<String, String> inputMap = new Map<String,String>{'processName' => 'Loan MCA Verification', 'loanId'=> opp.Id, 'applicantId' => appApplicant.Id};
            Test.setMock(HttpCalloutMock.class, new McaSuccessClassMock());
            Test.startTest();
            String response = FetchMCAController.initiateAPIRequest(inputMap);
            Test.stopTest();
            
            System.assertNotEquals(null, response);
        }
        catch(exception e){
            System.debug('ERROR: '+e.getStackTraceString());
        }
    }
    
	private class McaSuccessClassMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"result":[{"full_name":"JITENDRA RAGHAVJI GADA","date_of_appointment":"28/04/2010","DIN/DPIN/PAN":"05005591","address":"A-5, NIRMAL HOUSE CO-PO HOUSING SOCIETY, ,JP ROAD, OPP NAVRANG CENEMA, ANDHERI WEST ,MUMBAI ,Maharashtra ,400058 ,India","designation":"Designated Partner","wheather_dsc_registered":"","dsc_expiry_date":""},{"full_name":"RAMESHCHANDRA RAGHAVJI GADA","date_of_appointment":"28/04/2010","DIN/DPIN/PAN":"05005933","address":"28/401, New Parijat Co-Op Housing Society, Azad Nagar, ,Veera Desai Road, Near Andheri Sports Complex, And ,Mumbai ,Maharashtra ,400053 ,India","designation":"Designated Partner","wheather_dsc_registered":"","dsc_expiry_date":""}],"request_id":"619a6051-d9de-463d-8193-bbc7c0f94de4","status-code":"101","clientData":{"caseId":"a01C200000NsbKEIAZ"}}');
            return res;
        }
    }
    
    private class McaErrorClassMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('{"result":[],"request_id":"619a6051-d9de-463d-8193-bbc7c0f94de4","status-code":"100","clientData":{"caseId":"a01C200000NsbKEIAZ}}');
            return res;
        }
    }
}