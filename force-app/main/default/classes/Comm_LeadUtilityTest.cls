@isTest
public class Comm_LeadUtilityTest {

    @TestSetup
    static void setupData() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        List<Lead> testLead = TestDataFactory.getTestLeadData(4, false);
        testLead[0].PAN__c = 'ABCPG1234';
        testLead[0].MobilePhone = '9999999999';
        testLead[0].Phone = '9999999999';
        testLead[0].Assigned_Sales_User__c = u.Id;
        insert testLead;
    }

    @isTest
    static void testGetExistingLead() {
        Map<String, String> mobileMap = new Map<String, String>{
            '9999999999' => 'Individual'
        };

        Test.startTest();
        try{
            Map<String, Lead> result = Comm_LeadUtility.getExistingLead(mobileMap, 'API');
        }catch (exception e){}
        
        Test.stopTest();

        //System.assertEquals(1, result.size());
        //System.assert(result.containsKey('9999999999'));
    }

    @isTest
    static void testGetActiveLeadDetails() {
        Lead l = [SELECT Lead_Number__c FROM Lead LIMIT 1];
        Test.startTest();
        Comm_LeadUtility.leadWrapper lw = Comm_LeadUtility.getActiveLeadDetails(l.Lead_Number__c);
        Test.stopTest();

        System.assertEquals(l.Lead_Number__c, lw.activeLeadName);
        System.assertEquals(l.Id, lw.activeLeadId);
    }

    @isTest
    static void testGetReferenceLead() {
        Lead l = [SELECT Id, MobilePhone, Customer_Type__c FROM Lead LIMIT 1];
        Test.startTest();
        String refId = Comm_LeadUtility.getreferenceLead(l.MobilePhone, l.Id, l.Customer_Type__c);
        Test.stopTest();

        System.assertEquals(null, refId);
      
    }

    @isTest
    static void testGetReferenceLeadForPan() {
        Lead l = [SELECT Pan__c FROM Lead LIMIT 1];
        Test.startTest();
        String refId = Comm_LeadUtility.getreferenceLeadforPan(l.Pan__c);
        Test.stopTest();

        System.assertNotEquals(null, refId);
    }

    @isTest
    static void testEvaluateLeadConditions() {
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        Test.startTest();
        Boolean result = Comm_LeadUtility.evaluateLeadConditions(l.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetReportIdByName() {
        Test.startTest();
        String reportId = Comm_LeadUtility.getReportIdByName('Any Report');
        Test.stopTest();

        //System.assertEquals('00OXXXXXXXXXXXX', reportId);
    }

    @isTest
    static void testAssignUserRoundRobinBulk(){
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 10];
        List<Id> leadIds = new List<Id>();
        for(Lead l : leads){
            leadIds.add(l.Id);
        }
        Test.startTest();
        Comm_LeadUtility.assignUserRoundRobinBulk(leadIds);
        Test.stopTest();
    }

    @isTest
    static void testFetchLeadDetails(){
         List<Lead> leads = [SELECT Id FROM Lead LIMIT 1];

         Test.startTest();
         List<Lead> result = Comm_LeadUtility.fetchLeadDetails(leads[0].Id,'LeadManagement');
         Test.stopTest();


    }

    @isTest
    static void testCreateTask(){
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 1];
        Test.startTest();
        Comm_LeadUtility.createTask(leads[0].Id);
        Test.stopTest();


    }

}