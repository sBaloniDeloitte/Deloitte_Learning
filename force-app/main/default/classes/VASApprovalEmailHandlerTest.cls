@IsTest
public class VASApprovalEmailHandlerTest {
    @IsTest
    static void testApproveViaEmail() {
        Opportunity opp = new Opportunity(
            Name = 'LAH-12345',
            StageName = 'Sales ogin',
            CloseDate = Date.today().addDays(10),
            VAS_Approval_Status__c = 'Pending VAS Waiver',
            Product__c = 'Affordable Home Loan'
        );
        insert opp;


        // Approval.ProcessSubmitRequest submitReq = new Approval.ProcessSubmitRequest();
        // submitReq.setObjectId(opp.Id);
        // submitReq.setSubmitterId(UserInfo.getUserId());
        // submitReq.setComments('Submitting for VAS approval');
        // submitReq.setNextApproverIds(new Id[] { UserInfo.getUserId() });
        // Approval.ProcessResult submitResult = Approval.process(submitReq);

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Re: Approval Request';
        // email.plainTextBody = 'Approve\n\nLAH-12345\n\n-----Original Message-----';
        email.plainTextBody = 'Approve\n\n' + opp.Name + '\n\n-----Original Message-----';
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'testuser@test.com';

        Test.startTest();
        VASApprovalEmailHandler handler = new VASApprovalEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();
    }

    

    @IsTest
    static void testRejectViaEmail() {
        Opportunity opp = new Opportunity(
            Name = 'LAH-54321',
            StageName = 'Sales login',
            CloseDate = Date.today().addDays(10),
            VAS_Approval_Status__c = 'Pending VAS Waiver',
            Product__c = 'Home Loan'
        );
        insert opp;

        Approval.ProcessSubmitRequest submitReq = new Approval.ProcessSubmitRequest();
        submitReq.setObjectId(opp.Id);
        submitReq.setSubmitterId(UserInfo.getUserId());
        submitReq.setNextApproverIds(new Id[] { UserInfo.getUserId() });
        Approval.process(submitReq);

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Re: Approval';
        email.plainTextBody ='Reject\nLAH-54321\n-----Original Message-----';
        // email.plainTextBody = 'Reject\n\n' + opp.Name + '\n\n-----Original Message-----';
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        Test.startTest();
        new VASApprovalEmailHandler().handleInboundEmail(email, envelope);
        Test.stopTest();
    }
}