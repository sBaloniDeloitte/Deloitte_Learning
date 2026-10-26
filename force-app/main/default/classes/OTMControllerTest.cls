@IsTest
private class OTMControllerTest {

    @IsTest
    static void testGetTeamMembers() {

        // 1️⃣ Create test User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
		Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        opp.Product__c = 'Affordable Home Loan';

        // 3️⃣ Create Opportunity Team Members
        OpportunityTeamMember otm1 = new OpportunityTeamMember(
            OpportunityId = opp.Id,
            UserId = testUser.Id,
            TeamMemberRole = 'Sales',
            Associated_with_Loan_Application__c = true
        );

        OpportunityTeamMember otm2 = new OpportunityTeamMember(
            OpportunityId = opp.Id,
            UserId = testUser.Id,
            TeamMemberRole = 'Support',
            Associated_with_Loan_Application__c = false
        );

        insert new List<OpportunityTeamMember>{ otm1, otm2 };

        // 4️⃣ Call method
        Test.startTest();
        List<OTMController.OpportunityTeamWrapper> result =
            OTMController.getTeamMembers(opp.Id);
        Test.stopTest();

        // 5️⃣ Assertions
        //System.assertEquals(2, result.size(), 'Should return 2 team members');

        // Because of DESC order, first should be true
        //System.assertEquals(true, result[0].associated_with_Loan_Application);
        //System.assertEquals('Sales', result[0].teamMemberRole);
        //System.assertEquals(true, result[0].isDisabled);

       // System.assertEquals(false, result[1].associated_with_Loan_Application);
        //System.assertEquals('Support', result[1].teamMemberRole);

        // Validate username mapping
        //System.assertEquals(testUser.Name, result[0].userName);
    }
}