public with sharing class VASWaiverController {

    @AuraEnabled
    public static void submitVASWaiver(Id opportunityId) {
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity ID cannot be null.');
        }
        Opportunity opp = [SELECT Id, Name, Branch_Master__c, VAS_Approval_Status__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        AccountTeamMember branchHead = [SELECT UserId, User.Email,User.Name FROM AccountTeamMember WHERE AccountId = :opp.Branch_Master__c AND TeamMemberRole = 'Sales' AND Is_Branch_Head__c = TRUE LIMIT 1];
        if (branchHead == null) {
            throw new AuraHandledException('Error: Branch Head Approver or Email not found.');
        }
        opp.VAS_Approval_Status__c = 'Pending VAS Waiver';
        try {
            update opp;
        } catch (DmlException e) {
            throw new AuraHandledException('Error updating VAS Approval status: ' + e.getMessage());
        }
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitted via VAS Waiver Quick Action.');
        req.setObjectId(opportunityId);
        req.setProcessDefinitionNameOrId('VAS_Approval');
        req.setNextApproverIds(new List<Id>{branchHead.UserId}); 
        Approval.ProcessResult approvalResult = Approval.process(req);
        if (!approvalResult.isSuccess()) {
             throw new AuraHandledException('Failed to submit for standard approval: ' + approvalResult.getErrors()[0].getMessage());
        }
        // 5. Send Custom Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String emailServiceAddress = 'vas_waiver_approval_reply@1aelllk9otz4bp1z5tllqp7saprsikudxbx2u269e7bag75e7i.c2-2rzrvma2.ind18s.apex.sandbox.salesforce.com'; 
        mail.setToAddresses(new List<String>{branchHead.User.Email});
        String orgWideEmailId = '0D2C200000009cnKAA';
        mail.setOrgWideEmailAddressId(orgWideEmailId);
        mail.setReplyTo(emailServiceAddress);
        mail.setSubject('VAS Waiver Approval Request: ' + opp.Name);
        String salesforceBaseUrl = System.Url.getOrgDomainUrl().toExternalForm();
        // Set Body and Instructions
        String body = 'Dear '+ branchHead.User.Name +'\n\nThe VAS Waiver Approval for Loan Application: ' + opp.Name + ' requires your attention.' + 
                      '\n\nTo **APPROVE**, simply reply to this email with the word: Approve' +
                      '\n\nTo **REJECT**, simply reply to this email with the word: Reject' +
                      '\n\nLoan Application Link: ' + salesforceBaseUrl + '/' + opp.Id;
        mail.setPlainTextBody(body);
        // Send the email
        if(!Test.isRunningTest()){
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        }
        // Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
    }
}