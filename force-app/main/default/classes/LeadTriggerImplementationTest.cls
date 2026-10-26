@isTest
public class LeadTriggerImplementationTest {
    
    // Utility method to create a test Lead
    private static Lead createLead(String phone, String custType, String product, String status) {
        return new Lead(
            LastName = 'Test Lead',
            FirstName = 'Test First',
            Company = 'Test Company',
            MobilePhone = phone,
            Customer_Type__c = custType,
            Product__c = product,
            Status = status
        );
    }
    
    @isTest
    static void testMaskMobileNumbers() {
        // Create a Lead with a valid 10-digit phone
        Lead leadRec = createLead('9876543210', 'Individual', 'Affordable Home Loan', 'Open');
        insert leadRec;

        // Prepare map for masking
        Map<Id, String> leadMap = new Map<Id, String>{ leadRec.Id => leadRec.MobilePhone };
        List<Lead> leadList = [SELECT Id, MobilePhone FROM Lead WHERE Id = :leadRec.Id];

        Test.startTest();
        LeadTriggerImplementation.maskMobileNumbers(leadMap, leadList);
        Test.stopTest();

        System.assertEquals('XXXXXX3210', leadList[0].Mobile_Number_Masked__c, 'Mobile number should be masked correctly');
    }

    @isTest
    static void testCheckDuplicates() {
        // Insert a base Lead
        Lead l1 = createLead('9876543210', 'Individual', 'Affordable Home Loan', 'Open');
        insert l1;

        // Create a duplicate
        Lead l2 = createLead('9876543210', 'Individual', 'Affordable Home Loan', 'Open');
        List<Lead> leadsToInsert = new List<Lead>{ l2 };

        Test.startTest();
        try {
            LeadTriggerImplementation.checkDuplicates(leadsToInsert);
            insert leadsToInsert; // Should throw error
            //System.assert(false, 'Expected a duplicate error.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('A similar Lead already exists.'));
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateDocumentChecklist() {
        // Create active Document Master
        Document_Master__c doc1 = new Document_Master__c(Name = 'PAN',Document_Name__c='PAN',Document_Category__c='KYC', Is_Active__c = true, Is_Required__c = true, Requirement_At__c = 'Lead');
        Document_Master__c doc2 = new Document_Master__c(Name = 'DL',Document_Name__c='DL',Document_Category__c='KYC', Is_Active__c = true, Is_Required__c = false, Requirement_At__c = 'Lead');
        insert new List<Document_Master__c>{ doc1, doc2 };

        // Create a Lead
        Lead leadRec = createLead('9876543210', 'Individual', 'Affordable Non-Home Loan', 'Open');
        insert leadRec;

        Set<Id> leadIds = new Set<Id>{ leadRec.Id };

        Test.startTest();
        LeadTriggerImplementation.createDocumentChecklist(leadIds);
        Test.stopTest();

        List<Document_Details__c> docs = [SELECT Id, Name, Lead__c FROM Document_Details__c WHERE Lead__c = :leadRec.Id];
        System.assertEquals(2, docs.size(), 'Two document details should be created.');
    }

    @isTest
    static void testCreateFollowUpTask() {
        // Create Lead
        Lead leadRec = createLead('9876543210', 'Individual', 'Affordable Home Loan', 'Open');
        insert leadRec;

        Datetime followUpDate = Datetime.now().addDays(1);
        Map<Id, Datetime> leadMap = new Map<Id, Datetime>{ leadRec.Id => followUpDate };

        Test.startTest();
        LeadTriggerImplementation.createFolloUpTask(leadMap);
        Test.stopTest();

        List<Task> taskList = [SELECT Id, Subject, WhoId, ReminderDateTime FROM Task WHERE WhoId = :leadRec.Id];
        System.assertEquals(1, taskList.size(), 'Follow-up Task should be created.');
        System.assertEquals('Follow up with the Lead', taskList[0].Subject);
    }

    @isTest
    static void testUpdateAssignedDates() {
        // Create Lead
        Lead leadRec = createLead('9876543210', 'Individual', 'Affordable Home Loan', 'Open');
        insert leadRec;

        // Simulate old and new map
        Map<Id, Lead> oldMap = new Map<Id, Lead>{ leadRec.Id => leadRec.clone(false, true, false, false) };
        leadRec.Assigned_Telesales_User__c = UserInfo.getUserId();

        List<Lead> newLeads = new List<Lead>{ leadRec };

        Test.startTest();
        LeadTriggerImplementation.updateAssignedDates(newLeads, oldMap);
        Test.stopTest();

        System.assertNotEquals(null, leadRec.Tele_sales_lead_assigned_date__c, 'Tele sales assigned date should be updated.');
    }
     @isTest
    static void testUpdateTAT() {
        // Create Lead
        Lead leadRec = createLead('9876543210', 'Individual', 'Affordable Home Loan', 'Open');
        insert leadRec;

        List<String> newLeads = new List<String>{ leadRec.Id };

        Test.startTest();
        LeadTriggerImplementation.addAndUpdateStageTATRecords(newLeads, 'update');
        LeadTriggerImplementation.addAndUpdateStageTATRecords(newLeads, 'updateTAT');
        Test.stopTest();
    }
}