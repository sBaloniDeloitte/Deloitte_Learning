@isTest
public class LeadToLoanConversionControllerTest {
	
    @isTest static void createLoanFromLeadTest(){
        List<Lead> lstOflead = TestDataFactory.getTestLeadData(1,true);
        System.debug('Lead id -->'+lstOflead[0].Id);
        Lead objLead = new Lead();
        objLead.Pan__c = 'CFMPS7456L';
        objLead.Id = lstOflead[0].id;
        update objLead;
        Account branch = FITestDataFactory.createAccount('Test Branch', 'Branch');
        AccountTeamMember accTeamMember2 = new AccountTeamMember(
            AccountId = branch.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'Credit',
            Assigned_Loans__c = 1,
            Authorized_Signatory__c= 'Yes',
            Level__c='L1',
            Is_Default_Branch__c = true,
            Last_Application_Assigned_DateTime__c = System.now().addDays(-1) ,
            Eligible_Approver_Exception_Reasons__c ='Fraud Check;No PAN Card Available'
        );
        insert accTeamMember2;
        LeadToLoanConversionController.createLoanFromLead(lstOflead[0].Id);
    }
}