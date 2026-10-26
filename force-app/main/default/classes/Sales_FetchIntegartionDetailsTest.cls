@isTest
public class Sales_FetchIntegartionDetailsTest {
    @TestSetup
    static void makeData(){
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
        Integration_Details__c integrationDetails = FITestDataFactory.createintegrationDetailsData();
        integrationDetails.Object_Name__c = 'Application_Applicant__c';
        integrationDetails.Loan_Application__c = opp.Id;
        integrationDetails.Related_Record_Id__c = applicant.Id;
        integrationDetails.Name = 'Loan Applicant PAN Validation';
        integrationDetails.Response_JSON__c = '	{"statusCode":101,"result":{"message":"Request Submitted Successfully"},"request_id":null,"clientData":{"caseId":"a0TBi000003boFSMAY"}}';
        integrationDetails.Request_JSON__c = '{"panno":"1974-11-23","custdob":null}';
        update integrationDetails;
        Integration_Details__c integrationDetails2 = FITestDataFactory.createintegrationDetailsData();
        integrationDetails2.Object_Name__c = 'Application_Applicant__c';
        integrationDetails2.Loan_Application__c = opp.Id;
        integrationDetails2.Related_Record_Id__c = applicant.Id;
        integrationDetails2.Name = 'Pan Status';
        integrationDetails2.Response_JSON__c = '{"statusCode":101,"result":{"message":"Request Submitted Successfully"},"request_id":null,"clientData":{"caseId":"a0TBi000003boFSMAY"}}';
        integrationDetails2.Request_JSON__c = '{"panno":"1974-11-23","custdob":null}';
        update integrationDetails2;
        Integration_Details__c integrationDetails3 = FITestDataFactory.createintegrationDetailsData();
        integrationDetails3.Object_Name__c = 'Application_Applicant__c';
        integrationDetails3.Loan_Application__c = opp.Id;
        integrationDetails3.Related_Record_Id__c = applicant.Id;
        integrationDetails3.Name = 'Drivers License';
        integrationDetails3.Response_JSON__c = '{"statusCode":101,"result":{"message":"Request Submitted Successfully"},"request_id":null,"clientData":{"caseId":"a0TBi000003boFSMAY"}}';
        integrationDetails3.Request_JSON__c = '{"panno":"1974-11-23","custdob":null}';
        update integrationDetails3;
        Integration_Details__c integrationDetails4 = FITestDataFactory.createintegrationDetailsData();
        integrationDetails4.Object_Name__c = 'Application_Applicant__c';
        integrationDetails4.Loan_Application__c = opp.Id;
        integrationDetails4.Related_Record_Id__c = applicant.Id;
        integrationDetails4.Name = 'Voter Id';
        integrationDetails4.Response_JSON__c = '{"statusCode":101,"result":{"message":"Request Submitted Successfully"},"request_id":null,"clientData":{"caseId":"a0TBi000003boFSMAY"}}';
        integrationDetails4.Request_JSON__c = '{"panno":"1974-11-23","custdob":null}';
        update integrationDetails4;
        Integration_Details__c integrationDetails5 = FITestDataFactory.createintegrationDetailsData();
        integrationDetails5.Object_Name__c = 'Application_Applicant__c';
        integrationDetails5.Loan_Application__c = opp.Id;
        integrationDetails5.Related_Record_Id__c = applicant.Id;
        integrationDetails5.Name = 'Passport Verification';
        integrationDetails5.Response_JSON__c = '{"statusCode":101,"result":{"message":"Request Submitted Successfully"},"request_id":null,"clientData":{"caseId":"a0TBi000003boFSMAY"}}';
        integrationDetails5.Request_JSON__c = '{"panno":"1974-11-23","custdob":null,"passportNumber":"1234","name":"pass"}';
        update integrationDetails5;
        Integration_Details__c integrationDetails6 = FITestDataFactory.createintegrationDetailsData();
        integrationDetails6.Object_Name__c = 'Application_Applicant__c';
        integrationDetails6.Loan_Application__c = opp.Id;
        integrationDetails6.Related_Record_Id__c = applicant.Id;
        integrationDetails6.Name = 'Pan Profile';
        integrationDetails6.Response_JSON__c = '{"statusCode":101,"result":{"message":"Request Submitted Successfully"},"request_id":null,"clientData":{"caseId":"a0TBi000003boFSMAY"}}';
        integrationDetails6.Request_JSON__c = '{"panno":"1974-11-23","custdob":null,"passportNumber":"1234","name":"pass"}';
        update integrationDetails6;

        
    }

    @isTest
    public static void getAllApplicants_Test(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        Sales_FetchIntegartionDetails.getAllApplicants(opp.Id);
        Test.stopTest();
    }

    @isTest
    public static void getApplicantsIntegrationInfo_Test(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Test.startTest();
        Sales_FetchIntegartionDetails.getApplicantsIntegrationInfo(opp.Id,app.Id);
        Test.stopTest();
    }

}