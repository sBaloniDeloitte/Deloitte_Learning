@isTest
public class Comm_TelePDControllerTest {
    
    // Mock class to handle both token and TelePD callouts
    class MultiCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();
            
            if (endpoint.contains('token')) {
                // Mock auth token callout
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"access_token":"mocked_token"}');
                res.setStatusCode(200);
            } else if (endpoint.contains('Callout:LOS_BL_Tele_PD')) {
                // Mock actual TelePD request
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"Call":{"Sid":"abc123"}}');
                res.setStatusCode(200);
            } else {
                res.setStatusCode(400);
                res.setBody('Unexpected endpoint: ' + endpoint);
            }
            return res;
        }
    }
    
    
    @isTest
    static void testInitiateTelePD_Success() {
        try{
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            User testUser = TestDataFactory.getTestUser(p.Id, false);
            testUser.MobilePhone = '9876543210';
            insert testUser;
            TestDataFactory.setupIntegrationSettings('Get Token');
            
            System.runAs(testUser) {
                
                Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, false)[0];
                Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loanApp.Id, false)[0];
                loanApp.Name = 'Test Loan';
                loanApp.StageName = 'Prospecting';
                loanApp.Product__c = 'Affordable Home Loan';
                
                applicant.Name = 'Test Applicant';
                applicant.Mobile_Number__c = '9876543210';
                
                insert loanApp;
                applicant.Loan_Application__c = loanApp.Id; // ensure FK is set correctly
                insert applicant;
                // Ensure RecordType exists
                RecordType rt = [
                    SELECT Id 
                    FROM RecordType 
                    WHERE SObjectType = 'Application_Verification__c' 
                    AND DeveloperName = 'Personal_Discussion' 
                    LIMIT 1
                ];
                //System.assertNotEquals(null, rt, 'RecordType must exist');
                // Create test user
                Test.startTest();
                Integration_Details__c integrationDetail = new Integration_Details__c();
                
                integrationDetail.Name = 'TriggerVPD';
                integrationDetail.Loan_Application__c  = loanApp.Id; 
                integrationDetail.Related_Record_Id__c = applicant.Id;
                //insert integrationDetail;
                
                list < Integration_Details__c > integrationDetails = [
                    SELECT Id, Name 
                    FROM Integration_Details__c 
                    WHERE Name = : integrationDetail.name And (Loan_Application__c =:  integrationDetail.Loan_Application__c Or Related_Record_Id__c =: applicant.Id ) 
                    ORDER BY CreatedDate DESC
                ];
                system.debug('integrationDetail--> '+ integrationDetail);
            Test.setMock(HttpCalloutMock.class, new MultiCalloutMock());

                String result = Comm_TelePdController.initiateTelePD(
                    loanApp.Id,
                    applicant.Id,
                    applicant.Mobile_Number__c,
                    testUser.MobilePhone
                );
                
                Test.stopTest();
                
                System.assertEquals('success', result);
                List<Application_Verification__c> verifications = [
                    SELECT Id, Crime_Check_Status__c 
                    FROM Application_Verification__c 
                    WHERE Applicant__c = :applicant.Id
                ];
                // System.assertEquals(1, verifications.size());
                //System.assertEquals('Initiated', verifications[0].Crime_Check_Status__c);
            }
        }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
        }
    }
    
}