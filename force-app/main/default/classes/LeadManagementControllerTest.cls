@isTest
private class LeadManagementControllerTest {

   
   @isTest
static void testPortalUserScenario() {
    // 1️⃣ Create non-setup records first
    Account acc = new Account(Name = 'Test Account');
    insert acc;

    Contact con = new Contact(
        FirstName = 'Test',
        LastName = 'Contact',
        AccountId = acc.Id,
        Email = 'testcontact'+Math.random()+'@test.com'
    );
    insert con;
	/*
    // 2️⃣ Setup portal user inside System.runAs() with admin context
    Profile p = [SELECT Id FROM Profile WHERE Name='Partner Community User' LIMIT 1];
      UserRole role = [SELECT Id FROM UserRole WHERE Name = 'DSA Partner User' LIMIT 1]; 

    System.runAs(new User(
        Username='adminuser'+Math.random()+'@test.com',
        FirstName ='tes'+Math.random(),
        LastName ='dat'+Math.random(),
        Email='adminuser'+Math.random()+'@test.com',
        Alias='adm'+Math.round(Math.random()*1000),
        ProfileId=[SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1].Id,
        TimeZoneSidKey='Asia/Kolkata',
        LocaleSidKey='en_US',
        EmailEncodingKey='UTF-8',
        LanguageLocaleKey='en_US',
        IsActive=true
    )) {
        User portalUser = new User(
            FirstName='Portal', 
            LastName='User',
            Username='portaluser'+Math.random()+'@test.com',
            Email='portaluser'+Math.random()+'@test.com',
            Alias='tuser'+Math.round(Math.random()*1000),
            ProfileId=p.Id,
            ContactId=con.Id,
            UserRoleId=role.Id,
            TimeZoneSidKey='Asia/Kolkata',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            IsActive=true
        );
        insert portalUser;
    }*/
}

    

    @isTest
    static void testCreateLead() {
        //User u = [SELECT Id FROM User WHERE FirstName = 'Portal' LIMIT 1];

        //System.runAs(u) {
            String leadId = LeadManagementController.createLead(
                'John', 'A', 'Doe', '9999999999', 'Test Company',
                'Contact Person', 'Individual', 'Direct', 'Salaried Indian', 'Home Loan', false
            );

            System.assertNotEquals(null, leadId, 'Lead should be created');
        //}
    }

    @isTest
    static void testBusinessSubSectorPicklist() {
        PLF_Master__c plf = new PLF_Master__c(Master_Type__c='Sub sector', Description__c='Test Sector');
        insert plf;

        Map<String,Object> picklist = LeadManagementController.businessSubSectorPicklist();
        System.assert(picklist.containsKey('picklistOptions'));
    }

    @isTest
    static void testGetAccountsForUser() {
       // User u = [SELECT Id FROM User LIMIT 1];
        //System.runAs(u) {
            // This will return null since internal users cannot have AccountId
            //String accName = LeadManagementController.getAccountsForUser(u.Id);
        	String accName = LeadManagementController.getAccountsForUser(userinfo.getUserId());
            System.assertEquals(null, accName);
        //}
    }
    
    @isTest
    static void getLeadNumberTest() {
        String leadId = LeadManagementController.createLead(
                'John', 'A', 'Doe', '9999999999', 'Test Company',
                'Contact Person', 'Individual', 'Direct', 'Salaried Indian', 'Home Loan', false
            );
        LeadManagementController.getLeadNumber(leadId);
    }
    
     @isTest
    static void getLeadCurrentStageTest() {
        String leadId = LeadManagementController.createLead(
                'John', 'A', 'Doe', '9999999999', 'Test Company',
                'Contact Person', 'Individual', 'Direct', 'Salaried Indian', 'Home Loan', false
            );
        LeadManagementController.getLeadCurrectStage(leadId);
    }
    
     @isTest
    static void checkImageUploadedTest() {
        String leadId = LeadManagementController.createLead(
                'John', 'A', 'Doe', '9999999999', 'Test Company',
                'Contact Person', 'Individual', 'Direct', 'Salaried Indian', 'Home Loan', false
            );
        LeadManagementController.checkImageUploaded(leadId);
    }
    
    @isTest
    static void closeLeadTest() {
        String leadId = LeadManagementController.createLead(
                'John', 'A', 'Doe', '9999999999', 'Test Company',
                'Contact Person', 'Individual', 'Direct', 'Salaried Indian', 'Home Loan', true
            );
        LeadManagementController.closeLead(leadId);
    }
    
    @isTest
    static void fetchLeadDetailsTest() {
        String leadId = LeadManagementController.createLead(
                'John', 'A', 'Doe', '9999999999', 'Test Company',
                'Contact Person', 'Individual', 'Direct', 'Salaried Indian', 'Home Loan', true
            );
        LeadManagementController.fetchLeadDetails(leadId,'Test');
    }
    
    @isTest
    static void checkpastDateTest() {
        LeadManagementController.checkpastDate(Date.today().addDays(-1));
    }
    
    @isTest
    static void getConstantsTest() {
        LeadManagementController.getConstants();
    }
    
    @isTest
    static void getNumberToWordTest() {
        LeadManagementController.getNumberToWord('20');
    }
}