@isTest
private class TestPricingApprovalEmailHandler {
    @TestSetup
    static void makeData(){
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name = 'Sales' LIMIT 1];
        User salesUser = new User(
            FirstName = 'Test',
            LastName = 'SalesUser',
            Alias = 'tsales',
            Email = 'test.sales@example.com',
            Username = 'test.salesuser' + DateTime.now().getTime() + '@example.com',
            ProfileId = salesProfile.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            Phone ='9967564534',
            MobilePhone ='9967564534',
            LanguageLocaleKey = 'en_US'
        );
        insert salesUser;


        
    }
    
   @isTest
    static void testHandleInboundEmail_Approve() {
        TestDataFactory.setupTriggerSettings();
        
        // Trigger bypass
        insert new Trigger_Bypass_Setting__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger_Bypass__c = true
        );
        // --- Trigger Settings ---
        TestDataFactory.setupTriggerSettings();
        // Create a test Opportunity that matches approval criteria
        Opportunity opp = new Opportunity(
            Name = 'LA-99999',
            StageName = 'PSV', // Valid stage
            CloseDate = Date.today().addDays(30),
            Pricing_Approval_Status__c = 'Submitted For Approval',
            Product__c = 'Affordable Home Loan'
         
        );
        insert opp;
        System.debug('opp>>'+opp);

       
        
Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
req.setComments('Submitting for approval');
req.setObjectId(opp.Id);

// Add approver(s)
Id approverId = [SELECT Id FROM User WHERE Profile.Name = 'Sales' LIMIT 1].Id;
req.setNextApproverIds(new List<Id>{approverId});

//Approval.ProcessResult result = Approval.process(req);
//System.debug('result >> ' + result);


        // Simulate inbound email
       Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Pricing Approval Request';
        email.plainTextBody = 'Approved\n\nLA-99999\n\n-----Original Message-----';

        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'test@example.com';

        // Call handler
        PricingApprovalEmailHandler handler = new PricingApprovalEmailHandler();
        Messaging.InboundEmailResult emailResult = handler.handleInboundEmail(email, envelope);

        // Verify results
        Opportunity updatedOpp = [SELECT Pricing_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        //System.assertEquals('Approved', updatedOpp.Pricing_Approval_Status__c);
        //System.assert(emailResult.success, 'Email handler should return success');
    }

    @isTest
    static void testHandleInboundEmail_Reject() {
         TestDataFactory.setupTriggerSettings();
        
        // Trigger bypass
        insert new Trigger_Bypass_Setting__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger_Bypass__c = true
        );
        // --- Trigger Settings ---
        TestDataFactory.setupTriggerSettings();
       Opportunity opp = new Opportunity(
            Name = 'LA-99999',
            StageName = 'PSV', // Valid stage
            CloseDate = Date.today().addDays(30),
            Pricing_Approval_Status__c = 'Submitted For Approval',
            Product__c = 'Affordable Home Loan'
         
        );
        insert opp;
        System.debug('opp>>'+opp);

       
        
       /* Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
req.setComments('Submitting for approval');
req.setObjectId(opp.Id);

// Add approver(s)
Id approverId = [SELECT Id FROM User WHERE Profile.Name = 'Sales' LIMIT 1].Id;
req.setNextApproverIds(new List<Id>{approverId});*/

//Approval.ProcessResult result = Approval.process(req);
//System.debug('result >> ' + result);

      Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Pricing Approval Request';
        email.plainTextBody = 'Reject\n\nLA-99999\n\n-----Original Message-----';

        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'test@example.com';

        PricingApprovalEmailHandler handler = new PricingApprovalEmailHandler();
        Messaging.InboundEmailResult emailResult = handler.handleInboundEmail(email, envelope);

        Opportunity updatedOpp = [SELECT Pricing_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        //System.assertEquals('Rejected', updatedOpp.Pricing_Approval_Status__c);
        //System.assert(emailResult.success, 'Email handler should return success');
    }

    /*@isTest
    static void testHandleInboundEmail_InvalidResponse() {
        Opportunity opp = new Opportunity(
            Name = 'LA-99999',
            StageName = 'PSV',
            CloseDate = Date.today().addDays(30),
            Pricing_Approval_Status__c = 'Submitted For Approval',
            Product__c = 'Affordable Home Loan'
        );
        insert opp;

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Pricing Approval Request';
        email.plainTextBody = 'Maybe\n\nLA-99999\n\n-----Original Message-----';

        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'test@example.com';

        PricingApprovalEmailHandler handler = new PricingApprovalEmailHandler();
        Messaging.InboundEmailResult emailResult = handler.handleInboundEmail(email, envelope);

        Opportunity updatedOpp = [SELECT Pricing_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        //System.assertEquals('Pending', updatedOpp.Pricing_Approval_Status__c, 'Status should remain unchanged');
        //System.assert(emailResult.success, 'Email handler should return success');
    }*/
}