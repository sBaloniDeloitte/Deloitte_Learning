@isTest
public class HL_CovenantApprovalControllerTest {
    @testSetup static void setupData(){
        Account acc = TestDataFactory.getTestAccounts(1, 'Customer', false)[0];
        insert acc;
        Opportunity oppRec = TestDataFactory.createLoanApplicationRecord('Loan Account Created', 'Home Loan', 'Sales Login', Date.today());
        insert oppRec;
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, oppRec.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = oppRec.Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        applicant.Customer__c = acc.Id;
        insert applicant;
    }
    
    @isTest static void getCreditATMsTest(){
        Opportunity oppRec = [Select id from Opportunity LIMIT 1];
		Account branch = FITestDataFactory.createAccount('Test Branch', 'Branch');
        oppRec.Branch_Master__c = branch.id;
        update oppRec;
        AccountTeamMember accTeamMember2 = new AccountTeamMember(
            AccountId = branch.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'Credit',
            Assigned_Loans__c = 1,
            Authorized_Signatory__c= 'Yes',
            Level__c='L1',
            Last_Application_Assigned_DateTime__c = System.now().addDays(-1) ,
            Eligible_Approver_Exception_Reasons__c ='Fraud Check;No PAN Card Available'
        );
        insert accTeamMember2;
        HL_CovenantApprovalController.getCreditATMs(oppRec.Id);
    }
    @isTest static void sendForApprovalTest(){
        Opportunity oppRec = [Select Id from Opportunity LIMIT 1];
		Account branch = FITestDataFactory.createAccount('Test Branch', 'Branch');
        oppRec.Branch_Master__c = branch.Id;
        update oppRec;
            Sanction_Condition__c sanction = new Sanction_Condition__c(
        Condition_Name__c = 'Sanction Upload Test',
        Loan_Application__c = oppRec.Id
    );
    insert sanction;
        Profile objProfile = [Select Id from Profile where Name = 'System Administrator'];
        User testUser = TestDataFactory.getTestUser(objProfile.Id,true);
        List<Document_Details__c> docs = new List<Document_Details__c>();
        for (Integer i = 0; i < 2; i++) {
            docs.add(new Document_Details__c(
                Name = 'Doc ' + i,
                Loan_Application__c = oppRec.Id
            ));
        }
        insert docs;
        List<Id> lstOfDocIds = new List<Id>();
        for (Document_Details__c doc : docs) {
            lstOfDocIds.add(doc.Id);
        }
        //HL_CovenantApprovalController.sendForApproval(testUser.Id,oppRec.Id,lstOfDocIds,false,false);
        HL_CovenantApprovalController.sendForApproval(testUser.Id,oppRec.Id,lstOfDocIds,true,false);
        HL_CovenantApprovalController.sendForApproval(testUser.Id,oppRec.Id,lstOfDocIds,false,true);
        HL_CovenantApprovalController.createDocumentDetailsParent(testUser.Id,lstOfDocIds);
        HL_CovenantApprovalController.createSanctionConditionParent(testUser.Id,lstOfDocIds);
        HL_CovenantApprovalController.sendCustomApprovalEmail(testUser.Id,null,oppRec.Id,false,false);
    }
    
     @isTest static void sendForApprovalTest1(){
        Opportunity oppRec = [Select Id from Opportunity LIMIT 1];
		Account branch = FITestDataFactory.createAccount('Test Branch', 'Branch');
        oppRec.Branch_Master__c = branch.Id;
        update oppRec;
            Sanction_Condition__c sanction = new Sanction_Condition__c(
        Condition_Name__c = 'Sanction Upload Test',
        Loan_Application__c = oppRec.Id
    );
    insert sanction;
        Profile objProfile = [Select Id from Profile where Name = 'System Administrator'];
        User testUser = TestDataFactory.getTestUser(objProfile.Id,true);
        List<Document_Details__c> docs = new List<Document_Details__c>();
        for (Integer i = 0; i < 2; i++) {
            docs.add(new Document_Details__c(
                Name = 'Doc ' + i,
                Loan_Application__c = oppRec.Id
            ));
        }
        insert docs;
        List<Id> lstOfDocIds = new List<Id>();
        for (Document_Details__c doc : docs) {
            lstOfDocIds.add(doc.Id);
        }
        lstOfDocIds.add(sanction.id);
        Test.startTest();
        HL_CovenantApprovalController.createSanctionConditionParent(testUser.Id,lstOfDocIds);
        HL_CovenantApprovalController objClass = new HL_CovenantApprovalController();
        objClass.getChildDocList();
        objClass.getChildDocCount();
        objClass.getChildSanctionCount();
        Test.stopTest();
    }
    
    
}