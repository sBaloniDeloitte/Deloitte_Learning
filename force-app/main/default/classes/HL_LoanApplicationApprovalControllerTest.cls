@isTest
public class HL_LoanApplicationApprovalControllerTest {

    @TestSetup
    static void makeData(){
        Account branch = FITestDataFactory.createAccount('Test Branch', 'Branch');
        
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true, branch);
        loanApplication.Sanction_Loan_Amount__c = 100;
        loanApplication.Product__c = 'Home Loan';
        loanApplication.Branch_Master__c = branch.Id;
        loanApplication.Requested_Amount__c = 500;
        loanApplication.Sanction_Rate_Of_Interest__c = 7.85;
        loanApplication.Negotiated_Rate_Of_Interest__c = 7.85;
        loanApplication.StageName = 'Credit Underwriting';
        loanApplication.Final_Tenure__c = 240;
        loanApplication.IsApprovalAssignedToLevel__c = true;
        update loanApplication;
        
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApplication);
        applicant.Applicant_Type__c ='Primary Applicant';
        applicant.Customer_Type__c = 'Individual';
        applicant.Borrower_Profile__c = 'Cat-A';
        update applicant;
        
        User adminUser = FITestDataFactory.createUser('System Administrator', 'tuser');
        adminUser.MobilePhone = '9987876789';
        update adminUser;
        
        AccountTeamMember accTeamMember2 = new AccountTeamMember(
            AccountId = branch.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'Credit',
            Assigned_Loans__c = 1,
            Authorized_Signatory__c= 'Yes',
            Level__c='L1',
            Last_Application_Assigned_DateTime__c = System.now().addDays(-1) ,
            Maximum_authority_loan_amount__c= 1200000,
            Minimum_authority_loan_amount__c= 0
        );
        insert accTeamMember2;
        
        AccountTeamMember accTeamMember3 = new AccountTeamMember(
            AccountId = branch.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'Credit',
            Assigned_Loans__c = 1,
            Authorized_Signatory__c= 'Yes',
            Maximum_authority_loan_amount__c= 1200000,
            Minimum_authority_loan_amount__c= 0,
            Level__c='L1',
            Last_Application_Assigned_DateTime__c = System.now().addDays(-1) 
        );
        insert accTeamMember3;
        
        OpportunityTeamMember oppTeamMember = new OpportunityTeamMember(
            OpportunityId = loanApplication.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'Credit'
        );
        insert oppTeamMember;
        
        FITestDataFactory.addTeamMember(branch, adminUser, 'Credit');
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Test Document';
        contentVersion.VersionData = Blob.valueOf('Test document content');
        contentVersion.PathOnClient = 'testdocument.txt';
        insert contentVersion;
        
        // Main Product (RecordType = 'Product')
        Product2 mainProduct = new Product2(
            Name = loanApplication.Product__c, // must match Opportunity.Product__c
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Product' LIMIT 1].Id,
            Loan_Application__c = loanApplication.Id,
            Draft_PD_Note__c = 'Some approval notest',
            HL_Maximum_LTV_as_per_Policy_1__c = 1000,
            Product_Type__c = 'Parent'
        );
        insert mainProduct;
        
        // Sub Product
        Product2 subProduct = new Product2(
            Name = 'HL Builder Purchase',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Sub Product' LIMIT 1].Id,
            Product__c = mainProduct.Id,
            Loan_Application__c = loanApplication.Id,
            Sanctioned_Loan_Amount__c = 10000,
            Final_Loan_Amount__c = 10000,
            Sanctioned_ROI__c = 7.85,
            Sanctioned_Tenor__c = 240,
            HL_Final_LTVSanctioned_Terms__c = 10000
        );
        insert subProduct;

        Product2 subProduct2 = new Product2(
            Name = 'Flexi Loan',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Sub Product' LIMIT 1].Id,
            Product__c = mainProduct.Id,
            Loan_Application__c = loanApplication.Id,
            Sanctioned_Loan_Amount__c = 10000,
            Final_Loan_Amount__c = 10000,
            Sanctioned_ROI__c = 7.85,
            Sanctioned_Tenor__c = 240
        );
        insert subProduct2;
        
        Product2 fullEmiProduct = new Product2(
            Name = '240',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND DeveloperName='Full_Emi' LIMIT 1].Id,
            Product__c = subProduct.Id,
            Loan_Application__c = loanApplication.Id
        );
        insert fullEmiProduct;

        Product2 variantProduct = new Product2(
            Name = 'Term Loan',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND DeveloperName='Variant' LIMIT 1].Id,
            Product__c = subProduct.Id,
            Loan_Application__c = loanApplication.Id
        );
        insert variantProduct;

        Product2 subVarProduct = new Product2(
            Name = 'Freedom',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND DeveloperName='Sub_Variant' LIMIT 1].Id,
            Product__c = variantProduct.Id,
            Loan_Application__c = loanApplication.Id
        );
        insert subVarProduct;

        Product2 hydProduct = new Product2(
            Name = '10',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND DeveloperName='Hybrid_Tenure' LIMIT 1].Id,
            Product__c = subVarProduct.Id,
            Loan_Application__c = loanApplication.Id
        );
        insert hydProduct;
          
        Applicant_Address__c applicantAddress = new Applicant_Address__c(
            Loan_Application__c = loanApplication.Id,
            Applicant__c = applicant.Id,
            Screening_Status__c = 'Added to sampling queue',
            FCU_Initiated__c = false,
            Address_Type__c = 'Permanent',
            Address_Priority__c = '4'
        );
        insert applicantAddress;

        /* Current Address */
        Applicant_Address__c crAddress = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Type__c = 'Current',
            Address_Priority__c = '5'
        );
        insert crAddress;

        // Collateral
        Collateral__c collateral = new Collateral__c(
            IsActive__c = true,
            Market_Value__c = 5000000,
            APF__c = 'Yes',
            Remarks__c = 'Some coll remarks',
            RERA_End_Date__c = Date.today().addMonths(6)
        );
        insert collateral;

        Application_Collateral__c appColl = new Application_Collateral__c(
            HL_Loan_Application__c = loanApplication.Id,
            Collateral__c = collateral.Id,
            Assigned_Percentage__c = 100
        );
        insert appColl;

        Technical_Evaluation__c techEval = new Technical_Evaluation__c(
            HL_Loan_Application__c = loanApplication.Id,
            HL_Stage__c = 'Accepted by Technical Manager'
        );
        insert techEval;

        Application_Deviation__c deviation = new Application_Deviation__c(
            Loan_Application__c = loanApplication.Id,
            Approving_Authority__c = '1',
            Approval_Status__c = 'Pending',
            Mitigants__c = 'Some mitigants'
        );
        insert deviation;

        // Repayment Bank Account
        Bank_Details__c bank = new Bank_Details__c(
            Application_Applicant__c = applicant.Id,
            Is_Repayment_Account__c = true,
            Account_Holder_Name__c = 'Ria'
        );
        insert bank;

        // Create HOLD TAT record
        TAT__c tat = new TAT__c(
            Loan_Application__c = loanApplication.Id,
            Activity__c = 'Hold'
        );
        insert tat;
    }

    @isTest
    public static void testOtherMethods1(){
        
        List<Opportunity> opp = [Select Id From Opportunity];

        Test.startTest();

        HL_LoanApplicationApprovalController.checkProductValidations(opp[0].Id);
        HL_LoanApplicationApprovalController.checkUserAuthorisationForApprove(opp[0].Id);
        HL_LoanApplicationApprovalController.checkIfAllDeviationsApproved(opp[0].Id);
        HL_LoanApplicationApprovalController.getApprovalLevel(opp[0].Id);
        HL_LoanApplicationApprovalController.assignToMe(opp[0].Id);
        HL_LoanApplicationApprovalController.checkPolicyLTV(opp[0].Id);

        Test.stopTest();
    }

    @isTest
    public static void testOtherMethods2(){
        
        List<Opportunity> opp = [Select Id From Opportunity];
        List<Collateral__c> coll = [Select Id, RERA_End_Date__c From Collateral__c];
        coll[0].RERA_End_Date__c = Date.today().addMonths(60);
        update coll[0];

        Product2 mainProduct = [Select Id From Product2 Where Loan_Application__c =: opp[0].Id And RecordType.Name = 'Product' Limit 1];

        String commentData = 'NA Submitted &&-<p>Oksafd</p>&&-2025-12-31, 16:54:28&&-Test Dummy Credit Manager%%-NA Approved&&-<p>ok</p>&&-2025-12-31, 17:00:08&&-Test Dummy Credit Manager%%-NA Approved&&-<p>ok</p>&&-2025-12-31, 17:00:18&&-Test Dummy Credit Manager%%-NA Approved&&-<p>ok</p>&&-2025-12-31, 17:03:12&&-Test Dummy Credit Manager%%-NA Approved&&-<p>ok</p>&&-2025-12-31, 17:03:31&&-Test Dummy Credit Manager%%-NA Approved&&-<p>ok</p>&&-2025-12-31, 17:04:28&&-Test Dummy Credit Manager%%-NA Approved&&-<p>ok</p>&&-2025-12-31, 17:16:28&&-Test Dummy Credit Manager%%-NA Approved&&-<p>ok</p>&&-2025-12-31, 17:27:13&&-Test Dummy Credit Manager%%-NA Submitted &&-<p>ok</p>&&-2026-01-02, 12:16:43&&-Test Dummy Credit Manager%%-NA Submitted &&-<p>ok</p>&&-2026-01-02, 12:38:12&&-Test Dummy Credit Manager%%-NA Approved&&-<p>Ok</p>&&-2026-01-02, 15:23:40&&-Test Dummy Credit Manager%%-NA Approved&&-<p>ok</p>&&-2026-01-02, 16:50:09&&-Test Dummy Credit Manager%%-NA Submitted &&-<p>Ok</p>&&-2026-01-02, 17:02:54&&-Test Dummy Credit Manager%%-NA Approved&&-<p>Ok</p>&&-2026-01-02, 17:03:06&&-Test Dummy Credit Manager%%-NA Approved&&-<p>Ok</p>&&-2026-01-02, 17:09:55&&-Test Dummy Credit Manager%%-NA Submitted &&-<p>okokok</p>&&-2026-01-02, 18:24:45&&-Test Dummy Credit Manager%%-NA Approved&&-<p>ok</p>&&-2026-01-02, 18:27:37&&-Test Dummy Credit Manager%%-NA Approved&&-<p>OK</p>&&-2026-01-02, 18:59:03&&-Test Dummy Credit Manager%%-CM Approved&&-<p>okokokok</p>&&-2026-01-02, 19:32:03&&-Test Dummy Credit Manager%%-CM Approved&&-<p>okz</p>&&-2026-01-02, 19:43:00&&-Test Dummy Credit Manager';
        ContentVersion cv = new ContentVersion(
            Title = 'Approval Comments',
            PathOnClient = 'LoanApprovalComments.txt',
            VersionData = Blob.valueOf(commentData)
        );
        insert cv;

        String contentDocId= [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        Document_Details__c document= new Document_Details__c(
            Name= 'Loan Approval Comments',
            Content_Document_Id__c= contentDocId,
            Loan_Application__c = opp[0].Id,
            Product__c = mainProduct.Id
        );
        insert document;

        // Create ContentDocumentLink
        ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.ContentDocumentId = contentDocId;
        contentLink.LinkedEntityId = document.Id; // Replace with the record ID to which the document is linked (e.g., a Case, Opportunity, etc.)
        contentLink.ShareType = 'I'; // 'I' for Inferred permission, 'V' for Viewer permission, 'C' for Collaborator permission
        contentLink.Visibility = 'AllUsers'; // 'AllUsers' or 'InternalUsers'
        insert contentLink;

        Test.startTest();

        HL_LoanApplicationApprovalController.getLoanApprovalDetails(opp[0].Id);
        HL_LoanApplicationApprovalController.performApprovalAction(opp[0].Id, 'Approv', 'Some comments', 'Income Approval');

        Test.stopTest();
    }

    @isTest
    public static void testpPerformApprovalAction(){
        
        List<Opportunity> opp = [Select Id From Opportunity];
        List<Collateral__c> coll = [Select Id, RERA_End_Date__c From Collateral__c];
        coll[0].RERA_End_Date__c = Date.today().addMonths(60);
        update coll[0];

        Test.startTest();

        HL_LoanApplicationApprovalController.performApprovalAction(opp[0].Id, 'Approv', 'Some comments', 'Final Approval');

        Test.stopTest();
    }

    @isTest
    public static void testRecommendLoanApproval(){
        
        List<Opportunity> opp = [Select Id From Opportunity];
        List<Collateral__c> coll = [Select Id, RERA_End_Date__c From Collateral__c];
        coll[0].RERA_End_Date__c = Date.today().addMonths(60);
        update coll[0];

        Test.startTest();

        HL_LoanApplicationApprovalController.recommendLoanApproval(opp[0].Id, 'Income Approval', 'L1', true);

        Test.stopTest();
    }

    @isTest
    public static void testUnHoldApplication(){
        
        List<Opportunity> opp = [Select Id From Opportunity];

        Test.startTest();

        HL_LoanApplicationApprovalController.unHoldApplication(opp[0].Id);
        HL_LoanApplicationApprovalController.holdLoanApp(opp[0].Id);

        Test.stopTest();
    }
}