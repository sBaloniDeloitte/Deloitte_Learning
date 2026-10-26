@isTest
public class ShowRemarksControllerTest {
    @testSetup
    static void setupTestData() {
       Lead testLead = new Lead(
            LastName = 'TestLead',
            Company = 'TestCompany',
            MobilePhone = '9342345676',
            Product__c = 'Affordable Home Loan',
            Channel__c = 'Direct',
            Status = 'Open',
            Customer_Type__c='Individual',
            FirstName='test'
        );
        insert testLead;
        
        Account testAccount = new Account(
            Name = 'Test Account',
            Customer_LMS_Id__c = 'CUST123',
            Mobile_Number__c = '1234567890',
            Date_of_Birth__c = Date.newInstance(1990, 1, 1)
        );
        insert testAccount;
        
        testLead.Customer__c = testAccount.Id;
        update testLead;
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);

        // Create Application_Verification__c record (FI Remarks)
        Application_Verification__c fiRecord = new Application_Verification__c(
            RecordTypeId = Schema.SObjectType.Application_Verification__c.getRecordTypeInfosByName().get('Personal Discussion AHL').getRecordTypeId(),
            Stantard_Remark__c = generateSampleRemark('Standard'),
            Credit_Manager_s_Remarks__c = generateSampleRemark('Credit Manager'),
            Admin_s_Remarks__c = generateSampleRemark('Admin'),
            Any_Remarks_Reasons__c = generateSampleRemark('Any Reason'),
            Waiver_Remark__c = generateSampleRemark1('Waiver'),
            Loan_Application__c=loan.id
        );
        insert fiRecord;
         Application_Verification__c fiRecord1 = new Application_Verification__c(
            RecordTypeId = Schema.SObjectType.Application_Verification__c.getRecordTypeInfosByName().get('Personal Discussion AHL').getRecordTypeId(),
            Stantard_Remark__c = generateSampleRemark1('Standard'),
            Credit_Manager_s_Remarks__c = generateSampleRemark1('Credit Manager'),
            Admin_s_Remarks__c = generateSampleRemark1('Admin'),
            Any_Remarks_Reasons__c = generateSampleRemark1('Any Reason'),
            Waiver_Remark__c = generateSampleRemark1('Waiver'),
            Loan_Application__c=loan.id,
             Stage__c='Accepted'
        );
        insert fiRecord1;

        

      //  Test.setMock(HttpCalloutMock.class, new YourHttpCalloutMock()); 
    }

    @isTest
    static void testGetLeadRemarks() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        ShowRemarksController.RemarksWrapper result = ShowRemarksController.getRemarksDetails(lead.Id, 'Lead Remarks');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(result.allowCreation, 'Should allow creation for Open lead');
    }

    @isTest
    static void testGetFIRemarks() {
        Application_Verification__c fi = [SELECT Id FROM Application_Verification__c LIMIT 1];

        Test.startTest();
        ShowRemarksController.RemarksWrapper result = ShowRemarksController.getRemarksDetails(fi.Id, 'FI Remarks');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.remarks);
        System.assertEquals(false, result.allowCreation, 'Should not allow creation for FI Remarks');
    }

    @isTest
    static void testGetVendorPDRemarks() {
        Application_Verification__c vendorPd = [SELECT Id FROM Application_Verification__c where Stage__c='Accepted' LIMIT 1];

        Test.startTest();
        ShowRemarksController.RemarksWrapper result = ShowRemarksController.getRemarksDetails(vendorPd.Id, 'Vendor PD');
        Test.stopTest();

       System.assertNotEquals(null, result);
      System.assertNotEquals(null, result.remarks);
      System.assertEquals(false, result.allowCreation);
    }

    @isTest
    static void testUpdateLeadRemark() {
        Lead lead = [SELECT Id, Remarks_History__c FROM Lead LIMIT 1];

        String newRemark = 'Updated test remark';
        Test.startTest();
        String result = ShowRemarksController.updateRemark(lead.Id, newRemark, 'Lead Remarks');
        Test.stopTest();

        // Refetch lead to verify
        Lead updatedLead = [SELECT Remarks_History__c FROM Lead WHERE Id = :lead.Id];
        System.assert(updatedLead.Remarks_History__c.containsIgnoreCase('Updated test remark'));
    }
       private static String generateSampleRemark(String label) {
        DateTime dt = System.now();
        String dateStr = dt.format('dd-MM-yyyy');
        String timeStr = dt.format('hh:mm a').toLowerCase();
        return label + ' remark - ' + dateStr + ', ' + timeStr;
    }
     private static String generateSampleRemark1(String label) {
        DateTime dt = System.now();
        String dateStr = dt.format('dd/MM/yyyy');
        String timeStr = dt.format('hh:mm a').toLowerCase();
        return label + ' remark - ' + dateStr + ', ' + timeStr;
    }
}