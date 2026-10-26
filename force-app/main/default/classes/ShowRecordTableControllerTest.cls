@IsTest
public class ShowRecordTableControllerTest {
    @TestSetup
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
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        applicant.Customer__c=customer.id;
        applicant.Email__c='test@gmail.com';
        update applicant;

        RecordType businessVerificationRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Application_Verification__c' AND Name = 'Business Verification' LIMIT 1];
        Application_Verification__c appVerif = new Application_Verification__c(
            Loan_Application__c = loan.Id,
            RecordTypeId = businessVerificationRT.Id,
            Stage__c = 'Approved by CM',
            OverAll_Status__c = 'Positive',
            Assigned_To_User__c = UserInfo.getUserId(),
            Applicant__c = applicant.Id,
            Credit_Managers_Disposition__c = 'Approve',
            Credit_Manager_s_Remarks__c = 'All good',
            Completion_Date__c = DateTime.now().addDays(-1)
        );
        insert appVerif;

        AccountTeamMember atm = new AccountTeamMember(
            AccountId = testAccount.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'Manager'
        );
        insert atm;
    }
    
    @IsTest
    static void testGetRecordList_LinkedLead() {
        Lead testLead = [SELECT Id, MobilePhone FROM Lead LIMIT 1];
        String filter = '';
        
        ShowRecordTableController.TableWrapper result = ShowRecordTableController.getRecordList(testLead.Id, 'Linked Lead', filter);
        
        System.assertNotEquals(null, result);
        System.assert(result.headerColumns.size() > 0, 'Header columns should be present');
    }
    
    @IsTest
    static void testGetRecordList_InitiatedFI() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        String filter = '';
        
        ShowRecordTableController.TableWrapper result = ShowRecordTableController.getRecordList(loanApp.Id, 'Initiated FI', filter);
        
        System.assertNotEquals(null, result);
        System.assert(result.headerColumns.size() > 0, 'Header columns should be present');
        System.assert(result.recordList.size() > 0, 'Record list should have records');
        
        Boolean foundStyle = false;
        for(ShowRecordTableController.RecordWrapper rw : result.recordList){
            if(rw.styleTr == 'background-color: cornsilk;'){
                foundStyle = true;
                break;
            }
        }
        System.assert(foundStyle, 'At least one record should have style for Approved by CM');
    }
    
    @IsTest
    static void testGetRecordList_BranchUsers() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String filter = '';
        
        ShowRecordTableController.TableWrapper result = ShowRecordTableController.getRecordList(testAccount.Id, 'Branch Users', filter);
        
        System.assertNotEquals(null, result);
        System.assert(result.headerColumns.size() > 0, 'Header columns should be present');
        System.assert(result.recordList.size() > 0, 'Record list should have records');
    }
    
    @IsTest
    static void testGetRecordList_ExistingCustomers() {
        Lead testLead = [SELECT Id FROM Lead WHERE Customer__c != null LIMIT 1];
        String filter = '';
        
        ShowRecordTableController.TableWrapper result = ShowRecordTableController.getRecordList(testLead.Id, 'Existing Customers', filter);
        
        System.assertNotEquals(null, result);
        System.assert(result.headerColumns.size() > 0, 'Header columns should be present');
        System.assert(result.recordList.size() > 0, 'Record list should have records');
    }
}