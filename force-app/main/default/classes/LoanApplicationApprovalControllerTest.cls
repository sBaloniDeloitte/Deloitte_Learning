@isTest
public class LoanApplicationApprovalControllerTest {
    @isTest
    public static void testInstantiation(){
        LoanApplicationApprovalController obj = new LoanApplicationApprovalController();
    }
    @TestSetup
    static void makeData(){
        Account branch = FITestDataFactory.createAccount('Test Branch', 'Branch');
                // Create Users for different roles
        Profile fcuExecutiveProfile = [SELECT Id FROM Profile WHERE Name = 'Partner Community User' LIMIT 1];
        Profile fcuAdminProfile = [SELECT Id FROM Profile WHERE Name = 'Partner Community User' LIMIT 1];
        Profile samplerProfile = [SELECT Id FROM Profile WHERE Name = 'GC Standard User' LIMIT 1];
         Profile salesProfile = [SELECT Id FROM Profile WHERE Name = 'Sales' LIMIT 1];
        Profile creditManagerProfile = [SELECT Id FROM Profile WHERE Name = 'Credit Manager' LIMIT 1];
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,branch);
        loanApplication.Sanction_Loan_Amount__c = 100;
        loanApplication.Reasons_For_Execption_Approval__c ='Low Cibil Score';
        loanApplication.Product__c = 'Affordable Home Loan';
        loanApplication.Branch_Master__c = branch.Id;
        loanApplication.Requested_Amount__c = 500;
        loanApplication.Sanction_Rate_Of_Interest__c = 15;
        loanApplication.Negotiated_Rate_Of_Interest__c = 14;
        loanApplication.StageName = 'PSV';
        update loanApplication;
        
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApplication);
        applicant.Applicant_Type__c ='Primary Applicant';
        update applicant;
        
        User adminUser = FITestDataFactory.createUser('System Administrator', 'tuser');
        adminUser.MobilePhone = '9987876789';
        update adminUser;
        Charges_Insurance__c charge = FITestDataFactory.createInsurance(true,loanApplication.Id);
        charge.Final_Amount_INR__c =10;
        charge.Category__c = 'LOS';
        update charge; 
        
        Charges_Insurance__c ci = new Charges_Insurance__c(
            Loan_Application__c = loanApplication.Id,
            Category__c = 'LOS',
            RecordTypeId = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName().get('Charges').getRecordTypeId(),
            Charges_Fee_Type__c = 'PROCFEE'
        );
        insert ci; 

        
        Income_Expense_Obligation__c incomeExpenseObligation = new Income_Expense_Obligation__c(
            Loan_Application__c = loanApplication.Id,         // Link to the Opportunity
            Approver_s_Name__c = 'Test Approver Name'  // Example Approver Name
        );
        insert incomeExpenseObligation;
        
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
        
        AccountTeamMember accTeamMember3 = new AccountTeamMember(
            AccountId = branch.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'Credit',
            Assigned_Loans__c = 1,
            Authorized_Signatory__c= 'Yes',
            //Level__c='Test Approver Name',\
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
            Loan_Application__c = loanApplication.Id
        );
        insert mainProduct;
        
        // Sub Product
        Product2 subProduct = new Product2(
            Name = 'Affordable Home Sub',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Sub Product' LIMIT 1].Id,
            Product__c = mainProduct.Id,
            Loan_Application__c = loanApplication.Id
        );
        insert subProduct;
        
        // Variant (note: DeveloperName must be 'Variant')
        Product2 variantProduct = new Product2(
            Name = 'Term Loan',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND DeveloperName='Variant' LIMIT 1].Id,
            Product__c = subProduct.Id,
            Loan_Application__c = loanApplication.Id
        );
        insert variantProduct;
          
        Applicant_Address__c applicantAddress = new Applicant_Address__c(
            Loan_Application__c = loanApplication.Id,
            Applicant__c = applicant.Id,
            Screening_Status__c = 'Added to sampling queue',
            FCU_Initiated__c = false,
            
            Address_Type__c = 'Permanent'
            //Pincode__c = pinCode.Id
        );
        insert applicantAddress;
                // Create ContentDocumentLink
        ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
        contentLink.LinkedEntityId = loanApplication.Id; // Replace with the record ID to which the document is linked (e.g., a Case, Opportunity, etc.)
        contentLink.ShareType = 'I'; // 'I' for Inferred permission, 'V' for Viewer permission, 'C' for Collaborator permission
        contentLink.Visibility = 'AllUsers'; // 'AllUsers' or 'InternalUsers'
        insert contentLink;
        
         Document_Details__c doc2 = new Document_Details__c(
            Name = 'Test Document',
            Loan_Application__c = loanApplication.Id,
            Content_Document_Id__c = contentLink.ContentDocumentId,
            Remarks__c = 'Remarks');
        insert doc2;
        

        Application_Verification__c fcu = new Application_Verification__c(
            Report_Name__c = 'Loan Report ABC',
            Loan_Application__c = loanApplication.Id,
            OwnerId = UserInfo.getUserId(),
            IsParent__c = false,
             Document_details__c = doc2.id,
            Personal_Discussion_Type__c ='Tele PD'
        );
        insert fcu;

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



         AccountTeamMember accTeamMember4 = new AccountTeamMember(
            AccountId = branch.Id,
            UserId = salesUser.Id,
            TeamMemberRole = 'Sales',
            Assigned_Loans__c = 1,
            Level__c='L1'
        );
        insert accTeamMember4;

                User fcuAdmin = new User(
            Username = 'fcuAdmin@example.com.user',
            Alias = 'FCUAdm',
            LastName= 'fadm',
            Email = 'fcuAdmin@example.com',
            ProfileId = fcuAdminProfile.Id,
            Phone ='9967564534',
            MobilePhone ='9967564534',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            UserRoleId = null            
        );
        //  insert fcuAdmin;
        
        User sampler = new User(
            Username = 'sampler@example.com.user',
            Alias = 'Sampl',
            LastName= 'sampl',
            Email = 'sampler@example.com',
            ProfileId = samplerProfile.Id,
            Phone ='9967564534',
            MobilePhone ='9967564534',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            UserRoleId = null,
            FirstName = 'firsttest'
        );
        insert sampler;
        
        User creditManager = new User(
            Username = 'creditManager@example.com.user',
            Alias = 'CredM',
            LastName= 'credm',
            Email = 'creditManager@example.com',
            ProfileId = creditManagerProfile.Id,
            Phone ='9967564534',
            MobilePhone ='9967564534',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            UserRoleId = null,
            FirstName = 'firsttest'
        );
        
        insert creditManager;
                        
        Application_Verification__c appVerification2 = new Application_Verification__c(
            Loan_Application__c = loanApplication.Id,
            Report_Name__c = 'Test Report sampler',
            Parent_FCU__c= fcu.Id,
            Verification_Status__c = 'Positive',
            OwnerId = sampler.Id,
            Address__c = applicantAddress.Id,
            Document_details__c = doc2.id,
            IsParent__c = false,
            Personal_Discussion_Type__c ='Tele PD',
            RecordTypeId = Schema.SObjectType.Application_Verification__c.getRecordTypeInfosByName().get('Personal Discussion AHL').getRecordTypeId()
        );
        
       insert appVerification2;
        
        
        
          

        
         Application_Verification__c appVerificationchild = new Application_Verification__c(
            Loan_Application__c = loanApplication.Id,
            Document_Detail__c = doc2.id,
             Address__c = applicantAddress.Id,
            Report_Name__c = 'Test Report sampler child',
            Parent_FCU__c= appVerification2.Id,
            Verification_Status__c = 'Positive',
            OwnerId = sampler.Id,
             IsParent__c = false,
             Document_details__c = doc2.id,
             Personal_Discussion_Type__c ='Tele PD',
             RecordTypeId = Schema.SObjectType.Application_Verification__c.getRecordTypeInfosByName().get('Personal Discussion AHL').getRecordTypeId()

        );
        
        
        insert appVerificationchild;
        
        Application_Verification__c appVerification3 = new Application_Verification__c(
            Loan_Application__c = loanApplication.Id,
            Report_Name__c = 'Test Report credit',
            Verification_Status__c = 'Positive',
            Parent_FCU__c= fcu.Id,
            OwnerId = creditManager.Id,
            IsParent__c = false,
            Document_details__c = doc2.id,
            Personal_Discussion_Type__c ='Tele PD',
            RecordTypeId = Schema.SObjectType.Application_Verification__c.getRecordTypeInfosByName().get('Personal Discussion AHL').getRecordTypeId()

        );
        
        insert appVerification3; 
        system.runAs(creditManager){
            EmailTemplate testTemplate = new EmailTemplate(
            Name = 'Sales_Exception_Approval',
            Subject = 'Test Email Subject',
            Body = 'This is the body of the test email template.',
            IsActive = true,
                folderId = creditManager.Id,
                developerName = 'Sales_Exception_Approval',
                TemplateType = 'text'
        );
        insert testTemplate;
        }
        
    }
    
    
    
    @isTest
    public static void submitLoanForApproval_Test(){
        Opportunity loanApplication = [SELECT Id,Loan_Application_Number__c FROM Opportunity LIMIT 1];
        AccountTeamMember team = [SELECT Id FROM AccountTeamMember LIMIT 1];
        team.Level__c ='L2';
        update team;
        Charges_Insurance__c charge = [SELECT Id FROM Charges_Insurance__c LIMIT 1];
        
        LoanApplicationApprovalController.submitLoanForApproval(loanApplication.Id,'pricing Approval','');
    }
    @isTest
    public static void submitLoanForApproval_Test1(){
        Opportunity loanApplication = [SELECT Id,Branch_Master__c FROM Opportunity LIMIT 1];
        AccountTeamMember team = [SELECT Id FROM AccountTeamMember LIMIT 1];
        team.Level__c ='L1';
        team.TeamMemberRole ='Credit';
        update team;
        System.debug('submitLoanForApproval_Test1 '+loanApplication.Branch_Master__c);
        Charges_Insurance__c charge = [SELECT Id FROM Charges_Insurance__c LIMIT 1];
        LoanApplicationApprovalController.submitLoanForApproval(loanApplication.Id,'Exception Approval','');
    }
     @isTest
    public static void submitLoanForApproval_Test2(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Charges_Insurance__c charge = [SELECT Id FROM Charges_Insurance__c LIMIT 1];
        LoanApplicationApprovalController.submitLoanForApproval(loanApplication.Id,'Exception Approval','');
    }
    
    @isTest
    public static void getConstants_Test(){
        Test.startTest();
        LoanApplicationApprovalController.getConstants();
        Test.stopTest();
    }
    
    @isTest
    public static void getCurrentUserName_Test(){
        Test.startTest();
        LoanApplicationApprovalController.getCurrentUserName();
        Test.stopTest();
    }
    /*
    @isTest
    public static void getHighestApproverLevel_Test(){
        Account branch = FITestDataFactory.createAccount('Test Branch', 'Branch');
        
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,branch);
        loanApplication.Sanction_Loan_Amount__c = 100;
        loanApplication.Reasons_For_Execption_Approval__c ='Low Cibil Score';
        loanApplication.Product__c = 'Home Loan';
        loanApplication.Branch_Master__c = branch.Id;
        loanApplication.Requested_Amount__c = 500;
        loanApplication.Sanction_Rate_Of_Interest__c = 15;
        loanApplication.Negotiated_Rate_Of_Interest__c = 10;
        loanApplication.StageName = 'PSV';
        update loanApplication;
        
        Product2 prd = TestDataFactory.createProductRecord('Test Product', true);
    insert prd;
      
    // Step 2: Create Product2 (Sub Product)
    RecordType subProdRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Sub_Product' LIMIT 1];
    Product2 prod = new Product2(
        Name = 'Test Product org',
        Loan_Application__c = loanApplication.Id,
        RecordTypeId = subProdRT.Id,
        Sanctioned_Loan_Amount__c = 5000,
        Sanctioned_Tenor__c = 0,
        Sanctioned_ROI__c = 15,
        Negotiated_ROI__c = 10,
        EMI_Amount__c = 0,
        Product__c = prd.id,
        Loan_Purpose__c = 'Home Laon',
        Combined_LTV__c = 2,
        LTV__c=2,
        Combined_FOIR__c = 2
    );
    insert prod;
        
        Test.startTest();
        LoanApplicationApprovalController.getHighestApproverLevel(loanApplication.Id,'pricing Approval');
        Test.stopTest();
    }*/
    
    @isTest
    public static void getRecommendUsers_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        AccountTeamMember team = [SELECT Id FROM AccountTeamMember LIMIT 1];
        team.Level__c ='L2';
        update team;
        Test.startTest();
        LoanApplicationApprovalController.getRecommendUsers(loanApplication.Id);
        Test.stopTest();
    }
    
    @isTest
    public static void getOriginator_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        LoanApplicationApprovalController.getOriginator(loanApplication.Id);
        Test.stopTest();
    }
    
    @isTest
    public static void recommendLoanApproval_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        loanApplication.Eligible_Loan_Amount__c =2000;
        update loanApplication;
        AccountTeamMember team = [SELECT Id FROM AccountTeamMember LIMIT 1];
        User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId()];
        Test.startTest();
        try{
            System.runAs(currentUser){
                LoanApplicationApprovalController.recommendLoanApproval(loanApplication.Id,'No Comment','pricing Approval');
                
                team.level__c ='L2';
                update team;
                LoanApplicationApprovalController.recommendLoanApproval(loanApplication.Id,'No Comment','pricing Approval');
                
                Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                // set stuff
                req1.setComments('Submitting request for approval.');
                req1.setObjectId(loanApplication.Id);
                req1.setSkipEntryCriteria(true);
                req1.setNextApproverIds(new Id[] {userInfo.getUserId()});
                
                Approval.ProcessResult result = Approval.process(req1);
                LoanApplicationApprovalController.recommendLoanApproval(loanApplication.Id,'No Comment','pricing Approval');
                
                LoanApplicationApprovalController.recommendLoanApproval(loanApplication.Id,'No Comment','Exception Approval');
            }
        }catch(exception e){ }        
        Test.stopTest();
    }

    @isTest
    public static void sendEmailToAllApproversTest(){
        List<Opportunity> loanData = [SELECT Id,Branch_Master__c,Branch_Master__r.Name,Name FROM Opportunity LIMIT 1];
        String branchId = loanData[0].Branch_Master__c;
        
        AccountTeamMember currentApprover = [SELECT Id,User.NAme,TeamMemberRole,User.Email 
                                             FROM AccountTeamMember 
                                             WHERE AccountId = :branchId 
                                             AND TeamMemberRole = 'Sales' 
                                             AND Level__c = 'L1'][0];
        Test.startTest(); 
        try{
        LoanApplicationApprovalController.sendEmailToAllApprovers(currentApprover,new List<Opportunity>(loanData),'sending test email');
        }catch(exception e){}
        Test.stopTest();
    }
    
    @isTest
    public static void getLoanApprovalDetails_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        loanApplication.Approval_Comments__c = 'this loan is approved';
        update loanApplication;
        AccountTeamMember team = [SELECT Id FROM AccountTeamMember LIMIT 1];
        // Create test Profile
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name LIKE '%Sales%' LIMIT 1];
        
        // Create test User with Sales profile
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
        Charges_Approval_Criteria__mdt md = new Charges_Approval_Criteria__mdt(
            DeveloperName = 'Criteria1',
            MasterLabel = 'Criteria1'
            //Some_Field__c = 'TestValue' // Replace with a real field if needed
            //Product__c = 'Home Loan'
        );
        User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId()];
        Test.startTest(); 
        try{
            System.runAs(currentUser){
                Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                // set stuff
                req1.setComments('Submitting request for approval.');
                req1.setObjectId(loanApplication.Id);
                req1.setSkipEntryCriteria(true);
                req1.setNextApproverIds(new Id[] { currentUser.Id });
                
                Approval.ProcessResult result = Approval.process(req1);
                
                LoanApplicationApprovalController.getLoanApprovalDetails(loanApplication.Id,'Exception Approval');
                LoanApplicationApprovalController.getLoanApprovalDetails(loanApplication.Id,'pricing Approval');
                
                
                // Now approve the WorkItem manually
                List<ProcessInstanceWorkitem> workItems = [SELECT Id, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :loanApplication.Id];
                
                if (!workItems.isEmpty()) {
                    Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
                    req2.setComments('Approved by Test Class;Test');  
                    req2.setAction('Approve');
                    req2.setWorkitemId(workItems[0].Id);
                    Approval.ProcessResult result2 = Approval.process(req2);
                    
                    
                }
                
                
                
                LoanApplicationApprovalController.getLoanApprovalDetails(loanApplication.Id,'Exception Approval');
                
                
                LoanApplicationApprovalController.getLoanApprovalDetails(loanApplication.Id,'pricing Approval');
            }
            
        }catch(exception e){}
        Test.stopTest();
    }
    
    @isTest
    public static void getLoanApprovalDetailsWithoutApproval_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        
        
        AccountTeamMember team = [SELECT Id FROM AccountTeamMember LIMIT 1];
        
        Charges_Approval_Criteria__mdt md = new Charges_Approval_Criteria__mdt(
            DeveloperName = 'Criteria1',
            MasterLabel = 'Criteria1'
            //Some_Field__c = 'TestValue' // Replace with a real field if needed
            //Product__c = 'Home Loan'
        );
        User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId()];
        
        Test.startTest(); 
        loanApplication.Approval_Comments__c = 'this loan is approved';
        loanApplication.Exception_Approval_Status__c = null;
        update loanApplication;
        LoanApplicationApprovalController.getLoanApprovalDetails(loanApplication.Id,'Exception Approval');
        
        LoanApplicationApprovalController.getLoanApprovalDetails(loanApplication.Id,'pricing Approval');
        loanApplication.Exception_Approval_Status__c = 'Approved';
        update loanApplication;
        LoanApplicationApprovalController.getLoanApprovalDetails(loanApplication.Id,'Exception Approval');
        LoanApplicationApprovalController.getLoanApprovalDetails(loanApplication.Id,'pricing Approval');
        
        LoanApplicationApprovalController.getLoanApprovalDetails(loanApplication.Id,'Loan Approval');
        Test.stopTest();
    }
    
    @isTest
    public static void getLoanApprovalDetailsWithoutApproval_Test1(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        
        
        AccountTeamMember team = [SELECT Id FROM AccountTeamMember LIMIT 1];
        
        Charges_Approval_Criteria__mdt md = new Charges_Approval_Criteria__mdt(
            DeveloperName = 'Criteria1',
            MasterLabel = 'Criteria1'
            //Some_Field__c = 'TestValue' // Replace with a real field if needed
            //Product__c = 'Home Loan'
        );
        User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId()];
        
        Test.startTest(); 
        loanApplication.Approval_Comments__c = null;
        loanApplication.Exception_Approval_Status__c = null;
        update loanApplication;
        LoanApplicationApprovalController.getLoanApprovalDetails(loanApplication.Id,'Exception Approval');
        
        LoanApplicationApprovalController.getLoanApprovalDetails(loanApplication.Id,'pricing Approval');
        loanApplication.Exception_Approval_Status__c = 'Approved';
        update loanApplication;
        LoanApplicationApprovalController.getLoanApprovalDetails(loanApplication.Id,'Exception Approval');
        LoanApplicationApprovalController.getLoanApprovalDetails(loanApplication.Id,'pricing Approval');
        
        LoanApplicationApprovalController.getLoanApprovalDetails(loanApplication.Id,'Loan Approval');
        Test.stopTest();
    }
    
    @isTest
    public static void getLoanapprovers_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        AccountTeamMember team = [SELECT Id FROM AccountTeamMember LIMIT 1];
        Application_Deviation__c deviation = new Application_Deviation__c(
            Loan_Application__c = loanApplication.Id,
            Approving_Authority__c = '1'
        );
        insert deviation;
        Test.startTest();
        LoanApplicationApprovalController.getLoanapprovers(loanApplication.Id,'pricing Approval');
        Test.stopTest();
    }
    
    @isTest
    public static void sendBackLoan_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        AccountTeamMember team = [SELECT Id FROM AccountTeamMember LIMIT 1];
        Test.startTest();
        try{
            LoanApplicationApprovalController.sendBackLoan(loanApplication.Id,'No','Originator',UserInfo.getUserId(),'pricing Approval');
            LoanApplicationApprovalController.sendBackLoan(loanApplication.Id,'No','Originator',UserInfo.getUserId(),'other Approval');
        }catch(exception e){ }
        Test.stopTest();
    }
    
    @isTest
    public static void sendBackLoan_Test2(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityTeamMember otm = [SELECT Id,TeamMemberRole FROM OpportunityTeamMember LIMIT 1];
        otm.TeamMemberRole= 'Field Investigation';
        update otm;
        AccountTeamMember team = [SELECT Id FROM AccountTeamMember LIMIT 1];
        try{
            Test.startTest();
            LoanApplicationApprovalController.sendBackLoan(loanApplication.Id,'No','Search',UserInfo.getUserId(),'pricing Approval');
            
            
            LoanApplicationApprovalController.sendBackLoan(loanApplication.Id,'No','Search',UserInfo.getUserId(),'pricing Approval');
            OpportunityTeamMember oppTeamMember = new OpportunityTeamMember(
                OpportunityId = loanApplication.Id,
                UserId = UserInfo.getUserId(),
                TeamMemberRole = 'Credit'
            );
            insert oppTeamMember;
        }catch(exception e){ }
        Test.stopTest();
    }
    
    @isTest
    public static void performApprovalAction_Test(){
        Opportunity loanApplication = [SELECT Id,Is_Eligible_for_Exception_Approval__c FROM Opportunity LIMIT 1];
        loanApplication.Eligible_Loan_Amount__c =2000;
        update loanApplication;
        AccountTeamMember team = [SELECT Id FROM AccountTeamMember LIMIT 1];
        List<ProcessDefinition> defs = [SELECT Id,Name FROM ProcessDefinition limit 1];
        User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId()];
        Application_Deviation__c deviation = new Application_Deviation__c(
            Loan_Application__c = loanApplication.Id,
            Approving_Authority__c = '1',
            Approval_Status__c='Approved'
        );
        insert deviation;
        
        Product2 prd = TestDataFactory.createProductRecord('Test Product', true);
    insert prd;
      
    // Step 2: Create Product2 (Sub Product)
    RecordType subProdRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Sub_Product' LIMIT 1];
    Product2 prod = new Product2(
        Name = 'Test Product',
        Loan_Application__c = loanApplication.Id,
        RecordTypeId = subProdRT.Id,
        Sanctioned_Loan_Amount__c = 5000,
        Sanctioned_Tenor__c = 0,
        Sanctioned_ROI__c = 15,
        Negotiated_ROI__c = 10,
        EMI_Amount__c = 0,
        Product__c = prd.id,
        Loan_Purpose__c = 'Home Laon',
        Combined_LTV__c = 2,
        LTV__c=2,
        Combined_FOIR__c = 2
    );
    insert prod;
        
        Test.startTest();
                LoanApplicationApprovalController.performApprovalAction(loanApplication.Id,'Approv','No','Exception Approval');
                loanApplication.Login_Completion_Stage__c='Applicant Information';
                //update loanApplication;
                LoanApplicationApprovalController.performApprovalAction(loanApplication.Id,'Approv','No','pricing Approval');
                LoanApplicationApprovalController.performApprovalAction(loanApplication.Id,'Reject','No','Exception Approval');
            /*}
        }catch(exception e){ }*/
        Test.stopTest();
    }
    
    
    @isTest
    public static void performApprovalActionElse_Test(){
        Opportunity loanApplication = [SELECT Id,Is_Eligible_for_Exception_Approval__c FROM Opportunity LIMIT 1];
        system.debug('loanApplication '+ loanApplication.Is_Eligible_for_Exception_Approval__c);
        AccountTeamMember team = [SELECT Id FROM AccountTeamMember LIMIT 1];
        List<ProcessDefinition> defs = [SELECT Id,Name FROM ProcessDefinition limit 1];
        
        Test.startTest();
        LoanApplicationApprovalController.performApprovalAction(loanApplication.Id,'Approv','No','Loan Approval');
        LoanApplicationApprovalController.performApprovalAction(loanApplication.Id,'Reject','No','Loan Approval');
        Test.stopTest();
    }
    
    @isTest
    public static void submitLoanForExceptionApproval_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        AccountTeamMember team = [SELECT Id FROM AccountTeamMember LIMIT 1];
        
        String ContentDocumentId =  [SELECT Id, ContentDocumentId FROM ContentVersion limit 1].ContentDocumentId;
        List<String> strList = new List<String>();
        strList.add('Fraud Check');
        
        Test.startTest();
        LoanApplicationApprovalController.submitLoanForExceptionApproval(loanApplication.Id,strList,ContentDocumentId,'Exception Approval');
        Document_Details__c docDetail = new Document_Details__c(
            Name = 'Loan Exception Approval Document',
            Loan_Application__c = loanApplication.Id,
            Remarks__c = 'Remarks'
        );
        insert docDetail;
        LoanApplicationApprovalController.submitLoanForExceptionApproval(loanApplication.Id,strList,ContentDocumentId,'Exception Approval');
        Test.stopTest();
    }
    
    @isTest
    public static void submitLoanForExceptionApprovalElse_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        AccountTeamMember team = [SELECT Id FROM AccountTeamMember LIMIT 1];
        String ContentDocumentId =  [SELECT Id, ContentDocumentId FROM ContentVersion limit 1].ContentDocumentId;
        List<String> strList = new List<String>();
        strList.add('Test');
        Test.startTest();
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setObjectId(loanApplication.Id);
        req1.setProcessDefinitionNameOrId('Loan_Application_Approval');
        req1.setSkipEntryCriteria(true);
        req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        req1.setComments('Submitting request for approval.'); 
        //Approval.ProcessResult result = Approval.process(req1);
        
        List<ProcessInstanceWorkitem> workItems = [
            SELECT Id FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObjectId = :loanApplication.Id
        ];
        
        if (!workItems.isEmpty()) {
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(workItems[0].Id);
            req.setAction('Approve'); // or 'Reject' or 'Reassign'
            req.setComments('Approving the request with comments.');
            Approval.ProcessResult result2 = Approval.process(req);
        }
        LoanApplicationApprovalController.submitLoanForExceptionApproval(loanApplication.Id,strList,ContentDocumentId,'Exception Approval');
        
        strList.add('Test123');
        LoanApplicationApprovalController.submitLoanForExceptionApproval(loanApplication.Id,strList,ContentDocumentId,'Exception Approval');
        Test.stopTest();
    }
    
    
    @isTest
    static void testSendActionNotification_Approval() {
        // Retrieve test data inserted in @testSetup
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Set up the parameters for sendActionNotification
        String loanId = loan.Id;
        String action = 'Approve';
        Set<String> recipients = new Set<String>{'user@example.com'};
            String actionPerson = 'John Doe';
        String approvalType = 'Loan Approval';
        
        Test.startTest();
        
        // Call the method to test
        LoanApplicationApprovalController.sendActionNotification(loanId, action, recipients, actionPerson, approvalType);
        
        // End the test
        Test.stopTest();
    }
    
    @isTest
    static void testSendActionNotification_Reject() {
        // Retrieve test data inserted in @testSetup
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Set up the parameters for sendActionNotification
        String loanId = loan.Id;
        String action = 'Reject';
        Set<String> recipients = new Set<String>{'user2@example.com'};
            String actionPerson = 'Jane Doe';
        String approvalType = 'Loan Approval';
        
        Test.startTest();
        
        // Call the method to test
        LoanApplicationApprovalController.sendActionNotification(loanId, action, recipients, actionPerson, approvalType);
        
        // End the test
        Test.stopTest();
    }
    
    @isTest
    static void testSendActionNotification_Sent() {
        // Retrieve test data inserted in @testSetup
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Set up the parameters for sendActionNotification
        String loanId = loan.Id;
        String action = 'Sent';
        Set<String> recipients = new Set<String>{'user3@example.com'};
            String actionPerson = 'Sarah Smith';
        String approvalType = 'Loan Approval';
        
        Test.startTest();
        
        // Call the method to test
        LoanApplicationApprovalController.sendActionNotification(loanId, action, recipients, actionPerson, approvalType);
        
        // End the test
        Test.stopTest();
    }
    
    
    @isTest
    static void testSendActionNotification_Recommend() {
        // Retrieve test data inserted in @testSetup
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Set up the parameters for sendActionNotification
        String loanId = loan.Id;
        String action = 'Recommend';
        Set<String> recipients = new Set<String>{'user3@example.com'};
            String actionPerson = 'Sarah Smith';
        String approvalType = 'Loan Approval';
        
        Test.startTest();
        
        // Call the method to test
        LoanApplicationApprovalController.sendActionNotification(loanId, action, recipients, actionPerson, approvalType);
        
        // End the test
        Test.stopTest();
    }
    
    @isTest
    static void testSendActionNotification_ExceptionApproval() {
        // Retrieve test data inserted in @testSetup
        Opportunity loan = [SELECT Id FROM Opportunity  LIMIT 1];
        
        // Set up the parameters for sendActionNotification
        String loanId = loan.Id;
        String action = 'Submit';
        Set<String> recipients = new Set<String>{'user4@example.com'};
            String actionPerson = 'Tom Hanks';
        String approvalType = 'Exception Approval';
        String action1 = 'Reject';
        Test.startTest();
        
        // Call the method to test
        LoanApplicationApprovalController.sendActionNotification(loanId, action, recipients, actionPerson, approvalType);
        
        LoanApplicationApprovalController.sendActionNotification(loanId, action1, recipients, actionPerson, approvalType);
        // End the test
        Test.stopTest();
    }
    
    @isTest
    static void testGetNextApproverLevel() {
        // Retrieve the Opportunity (loan) we inserted
        Opportunity loan = [SELECT Id, Branch_Master__c, Requested_Amount__c FROM Opportunity LIMIT 1];
        
        // Test scenario where currentLevel is 'L1' and highestApprover is 'L2'
        String currentLevel = 'L1';
        String highestApprover = 'L2';
        Boolean isFinalApprover = false;
        
        // Call the method
        Test.startTest();
        String nextApprover = LoanApplicationApprovalController.getNextApproverLevel(currentLevel, highestApprover, loan.Id, 'Loan Approval', isFinalApprover);
        LoanApplicationApprovalController.checkHigherApprovers(currentLevel, highestApprover, loan.Id, 'Loan Approval');
        
        // Test the case when currentLevel is the highest level and isFinalApprover is false
        currentLevel = 'L2';
        highestApprover = 'L2';
        isFinalApprover = false;
        
        nextApprover = LoanApplicationApprovalController.getNextApproverLevel(currentLevel, highestApprover, loan.Id, 'Loan Approval', isFinalApprover);
        LoanApplicationApprovalController.checkHigherApprovers(currentLevel, highestApprover, loan.Id, 'Loan Approval');
        // Test case when an invalid currentLevel is passed
        currentLevel = 'InvalidLevel';
        
        nextApprover = LoanApplicationApprovalController.getNextApproverLevel(currentLevel, highestApprover, loan.Id, 'Loan Approval', isFinalApprover);
        LoanApplicationApprovalController.checkHigherApprovers(currentLevel, highestApprover, loan.Id, 'Loan Approval');
        
        currentLevel = 'L2';
        highestApprover = 'L1';
        isFinalApprover = false;
        
        nextApprover = LoanApplicationApprovalController.getNextApproverLevel(currentLevel, highestApprover, loan.Id, 'Loan Approval', isFinalApprover);
        LoanApplicationApprovalController.checkHigherApprovers(currentLevel, highestApprover, loan.Id, 'Loan Approval');
        Test.stopTest();
        
    }
    @isTest
    static void testsendExceptionApprovalEmail() {
        Test.startTest();
        LoanApplicationApprovalController.sendExceptionApprovalEmail('abc@gmail.com','ABC','687898','test','Testing');
        Test.stopTest();
        
    }
    
    @isTest
    static void testMitigantsFound() {
        Account vendor = FITestDataFactory.createAccount('Test Acc for Opp', 'Partner');
        Opportunity opp = FITestDataFactory.createOpportunity(vendor);
        
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
        applicant.DOB__c = Date.today().addYears(-19);
        update applicant;
        // Create Deviation
        Application_Deviation__c deviation = new Application_Deviation__c(
            Loan_Application__c = opp.Id,
            Approval_Status__c = 'Pending'
        );
        insert deviation;
        Test.startTest();
        	LoanApplicationApprovalController.mitigantsFound(String.ValueOf(opp.Id));
        Test.stopTest();
        
    }
    
    @IsTest
static void testGetLoanApprovalDetails_AllApprovalTypes() {

    /* ---------- Arrange ---------- */
    Account branch = FITestDataFactory.createAccount('Branch', 'Branch');

    Opportunity loan = FITestDataFactory.createLoanApplication(true, branch);
    loan.StageName = 'PSV';
    loan.Product__c = 'Affordable Home Loan';
    loan.Sanction_Loan_Amount__c = 100;
    loan.Reasons_For_Execption_Approval__c = 'Low Cibil Score;No PAN Card Available';
    loan.Selected_Reasons_For_Exception_Approval__c = 'Low Cibil Score';
    loan.Exception_Approval_Status__c = 'Not Started';
    //loan.Pricing_Approval_Status__c = 'Not Started';
    loan.Approval_Status__c = 'In Progress';
    loan.Draft_PD_Note__c = 'Draft Note';
    Trigger_Bypass_Setting__c listSetting = new Trigger_Bypass_Setting__c();
    
    // 2. Set the Name and other custom fields
    listSetting.Opportunity_Trigger_Bypass__c = false;
    
    // 3. Perform DML insert
    insert listSetting;
    Trigger_Bypass_Setting__c tb = [SELECT Id, Opportunity_Trigger_Bypass__c FROM Trigger_Bypass_Setting__c LIMIT 1];
    tb.Opportunity_Trigger_Bypass__c = true;
    update tb;
    update loan;
    
    tb.Opportunity_Trigger_Bypass__c = false;
    update tb;
   

    AccountTeamMember creditUser = new AccountTeamMember(
        AccountId = branch.Id,
        UserId = UserInfo.getUserId(),
        TeamMemberRole = 'Credit',
        Level__c = 'L1',
        Eligible_Approver_Exception_Reasons__c =
            'Low Cibil Score;No PAN Card Available',
        Authorized_Signatory__c = 'Yes'
    );
    insert creditUser;

    OpportunityTeamMember oppTeam = new OpportunityTeamMember(
        OpportunityId = loan.Id,
        UserId = UserInfo.getUserId(),
        TeamMemberRole = 'Credit'
    );
    insert oppTeam;

    Document_Details__c doc = new Document_Details__c(
        Name = 'Loan Exception Approval Document',
        Loan_Application__c = loan.Id,
        Remarks__c = 'Test'
    );
    insert doc;

    /* ---------- Act ---------- */
    Test.startTest();

    LoanApplicationApprovalController.ApprovalWrapper pricingResult =
        LoanApplicationApprovalController.getLoanApprovalDetails(
            loan.Id, 'pricing Approval'
        );

    LoanApplicationApprovalController.ApprovalWrapper exceptionResult =
        LoanApplicationApprovalController.getLoanApprovalDetails(
            loan.Id, 'Exception Approval'
        );

    LoanApplicationApprovalController.ApprovalWrapper loanResult =
        LoanApplicationApprovalController.getLoanApprovalDetails(
            loan.Id, 'Loan Approval'
        );

    Test.stopTest();

}
@IsTest
    static void testOtherMethos() {
        Test.startTest();
        LoanApplicationApprovalController.htmlToText('');
        LoanApplicationApprovalController.htmlToText('<[^>]+>&nbsp;&amp;&lt;&gt;');
        Test.stopTest();
    }
    
    @IsTest
    static void testUnHoldApplication() {
        Opportunity loan = [SELECT Id, Branch_Master__c, Requested_Amount__c FROM Opportunity LIMIT 1];

        // Create HOLD TAT record
        TAT__c tat = new TAT__c(
            Loan_Application__c = loan.Id,
            Activity__c = 'Hold'
        );
        insert tat;

        Test.startTest();
        
        LoanApplicationApprovalController.unHoldApplication(loan.Id, 'Unhold Test Comment');
        
        String result = LoanApplicationApprovalController.holdLoanApp(loan.Id, 'Hold test comment');

        Test.stopTest();
    }
    
    
}