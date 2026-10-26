@IsTest
public class FITestDataFactory { 
        
    public static final string contentVersionProperDoc = 'contentVersionProperDocCreation';
    public static final string contentVersionErrorDoc = 'contentVersionErrorDocCreation';
    public static final string pathOnClient = 'test.csv';
    public static final string TriggerSettingName = 'Trigger Settings';
    public static final string LeadObjectName = 'Lead';
    public static Bank_Statement_Analysis__c getBsaXnsRecord(
    Boolean isInsert,
    Id bankDetailId
) {
    Bank_Statement_Analysis__c bsaXnsRecord = new Bank_Statement_Analysis__c(
        Bank_Details__c = bankDetailId,
        Cheque_Number__c = 'CHK123',
        Narration__c = 'Bounce Transaction',
        Amount__c = 1000,
        Balance__c = 5000,
        XNS_Date__c = Date.today(),
        Category__c = 'Bounced',
        RecordTypeId = Utility.getRecordTypeIdByDeveloperName(
            'Bank_Statement_Analysis__c',
            'XNS'
        )
    );

    if (isInsert) {
        insert bsaXnsRecord;
    }

    return bsaXnsRecord;
}
    public static Bank_Statement_Analysis__c getBankstatement (Boolean isInsert , string  bankdetailID){
        
          Bank_Statement_Analysis__c bsaRecord = new Bank_Statement_Analysis__c(
            Bank_Details__c = bankdetailID,
            Month__c = 'Jan-25',
            Total_Self_and_Related_Party_Credit__c = 1000,
            Average_Limit_Utilisation__c = 30,
            ABB__c = 15,
            Amount_of_Self_and_Related_Party_Credit__c =1,
            Total_Number_of_Business_Credits__c = 1,
            Total_Amount_of_Business_Credits__c=1,
            Total_Self_and_Related_Party_Debit__c =1,
            Amount_of_Self_and_Related_Party_Debit__c =1,
            Total_Number_of_Business_Debits__c = 1,
            Total_Amount_of_Business_Debits__c =1,
            Cash_Deposit_to_total_Credit__c =1,
            Cash_withdrwal_to_total_Debit__c =1,
            Total_number_of_inward_return__c =1,
            Total_number_of_inward_ECS_return__c =1,Total_number_of_outward_return__c =1,
            O_w_retruns_as_of_total_credits__c =1,
            Total_Amount_of_Intrest_Charged__c =1,
            Total_Number_of_circular_transactions__c =1,
            Total_Amount_of_EMI__c =1,
            Average_EOD_Balance__c =1,
            Sanction_Limit__c =1,
            Count_of_loan_disbursal__c =1,
            Value_of_loan_disbursal__c =1,
            RecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis')
        );
        if(isInsert){ insert bsaRecord;}
        return bsaRecord;
       
    }
     public static Bank_Statement_Analysis__c getBankstatementTXN (Boolean isInsert , string  bankdetailID  , string bsaRecord){
        Bank_Statement_Analysis__c txn = new Bank_Statement_Analysis__c(
            Name = 'Txn 1',
            Bank_Details__c = bankdetailID,
            Amount__c = 100,
            Parent_Bant_Statement__c = bsaRecord,
            XNS_Date__c = Date.newInstance(2025, 1, 10),
            Salesforce_Category__c = 'Business Credit',
            Source__c = 'Manual',
            Month__c='Sep-21',
            Total_Self_and_Related_Party_Credit__c = 1000,
            Average_Limit_Utilisation__c = 30,
            ABB__c = 15,
            Amount_of_Self_and_Related_Party_Credit__c =1,
            Total_Number_of_Business_Credits__c = 1,
            Total_Amount_of_Business_Credits__c=1,
            Total_Self_and_Related_Party_Debit__c =1,
            Amount_of_Self_and_Related_Party_Debit__c =1,
            Total_Number_of_Business_Debits__c = 1,
            Total_Amount_of_Business_Debits__c =1,
            Cash_Deposit_to_total_Credit__c =1,
            Cash_withdrwal_to_total_Debit__c =1,
            Total_number_of_inward_return__c =1,
            Total_number_of_inward_ECS_return__c =1,Total_number_of_outward_return__c =1,
            O_w_retruns_as_of_total_credits__c =1,
            Total_Amount_of_Intrest_Charged__c =1,
            Total_Number_of_circular_transactions__c =1,
            Total_Amount_of_EMI__c =1,
            Average_EOD_Balance__c =1,
            Sanction_Limit__c =1,
            Count_of_loan_disbursal__c =1,
            Value_of_loan_disbursal__c =1,
            RecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis')
        );
        if (isinsert ) {   insert txn;}
        return txn; 
     
    }
    public static Bank_Details__c getBankdetails (Boolean isInsert , string  applicationid ){
          Bank_Details__c bankDetail = new Bank_Details__c(
            Application_Applicant__c = applicationid,
            Account_Type__c = 'Saving',
            Is_Consider_for_Eligibility__c = true,
            Account_Number__c = '1234567890',
            Name = 'John Bank',
            Account_Holder_Name__c ='John Bank'
        );
        if (isInsert) { insert bankDetail;}
        return bankDetail; 
       
    }
    
    public static Legal__c returnLegalRecord(string loanApplicationId, Boolean isInsert){
        Profile legalAdminProfile = [SELECT Id FROM Profile WHERE Name = 'Partner Community User' LIMIT 1];
        
        Legal__c legalObj = new Legal__c();
        legalObj.Loan_Application__c = loanApplicationId;
        legalObj.Assigned_to_Admin__c = UserInfo.getUserId();
        if(isInsert){
            insert legalObj;
		}
        return legalObj;
    }
    
    public static ContentVersion getContentVersion (string path, string title , boolean isinsert){
        ContentVersion con = new ContentVersion();
    con.Title = title;
    con.PathOnClient = path;
    
    if (isInsert) {
        insert con;
    }
    return con;
    }
    public static Integration_Details__c createIntegrationDetails(

        Boolean isInsert
    ) {
        Integration_Details__c intg = new Integration_Details__c(
            Name = 'FICO123',
            Status__c = '200',
            Eligibility_Status__c = 'Eligible',
            IsConsideredEligibility__c = true,
            Endpoint__c = 'test@test.com',
            Response_JSON__c = '<finalOffer><ROINTR>18.0</ROINTR><MAXLOELIGINC>1500000.0</MAXLOELIGINC><LOANTENU>120</LOANTENU><EMIFINOFF>10811.11</EMIFINOFF></finalOffer>'
        );
        if (isInsert) {
            insert intg;
        }
        return intg;
    }
    public static Integration_Settings__c createIntegrationSetting(Boolean isInsert) {
        Integration_Settings__c setting = new Integration_Settings__c(
            Name = 'Loan FICO API',  // You can add parameters if you want more flexibility
            Client_Id__c = 'mock-client-id',
            Client_Secret__c = 'mock-client-secret',
            Cookie__c = 'mock-cookie',
            Endpoint__c = 'https://mock.endpoint.com',
            Content_Type__c = 'application/json',
            Authorization__c = 'Bearer mock-token',
            Request_Method__c = 'POST'
        );
        if (isInsert) {
            insert setting;
        }
        return setting;
    }
    public static Product2 createProduct(String productName, Boolean isInsert) {
        Product2 product = new Product2(
            Name = productName,
            IsActive = true
        );
        if (isInsert) {
            insert product;
        }
        return product;
    }


     public static Bank_Statement_Analysis__c createBankStatementAnalysis(Id bankDetailId, Id recordTypeId, Boolean isInsert) {
        Bank_Statement_Analysis__c parentStmt = new Bank_Statement_Analysis__c(
            Name = 'Parent Statement',
            Bank_Details__c = bankDetailId,
            RecordTypeId = recordTypeId
        );
        if (isInsert) {
            insert parentStmt;
        }
        return parentStmt;
    }
     public static PLF_Master__c createPlfMaster(boolean isInsert) {
    PLF_Master__c plfMaster = new PLF_Master__c(
        Description__c = 'Some Program Type',
        FICO_Code__c = 'FICO123',
        Applicant_Type__c = 'Individual',
        Customer_Type__c = 'SEP', // adjust if needed
        Master_Type__c = 'Program types'
    );
    if (isInsert) {
        insert plfMaster;
    }
    return plfMaster;
}
    public static Account createAccount(String name, String recordTypeDeveloperName) {
        RecordType recordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = :recordTypeDeveloperName LIMIT 1];
        Account acc = new Account(
            Name = name,
            RecordTypeId = recordType.Id
        );
        insert acc;
        return acc;
    }

    public static User createUser(String profileName, String alias) {
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        User user = new User(
            FirstName = 'PROD',
            LastName = 'Test User',
            Email = alias +'@example.com',
            Username = alias + Datetime.now().getTime() +'@example.com.test',
            Alias = alias,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = userProfile.Id,
            MobilePhone ='9967564534',
            Phone ='9967564534'
        );
        insert user;
        return user;
    }

    public static Opportunity createOpportunity(Account account) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Sales login',
            CloseDate = Date.today(),
            AccountId = account.Id,
            Product__c = 'Affordable Home Loan'
        );
        insert opp;
        return opp;
    }
    public static Application_Applicant__c createApplicant2(Opportunity opportunity , Boolean Isinsert) {
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opportunity.Id,
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Applicant_Type__c = 'Primary Applicant',
            //Industry__c = 'Manufacturing',
            Gender__c = 'Male', 
            Marital_Status__c = 'Single', 
            Qualification__c = 'CA',
            Religion__c = 'Hindu',
           // Country_of_Birth__c = 'Indian', 
            Nationality__c = 'Indian',
            Residency_Status__c = 'Resident'
        );
        if(isInsert) {
              insert applicant;
}
      
        return applicant;
    }
    public static Application_Applicant__c createApplicant(Opportunity opportunity) {
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opportunity.Id,
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Applicant_Type__c = 'Primary Applicant',
            //Industry__c = 'Manufacturing',
            Gender__c = 'Male', 
            Marital_Status__c = 'Single', 
            Qualification__c = 'CA',
            Religion__c = 'Hindu',
           // Country_of_Birth__c = 'Indian', 
            Nationality__c = 'Indian',
            Residency_Status__c = 'Resident'
        );
        insert applicant;
        return applicant;
    }

    public static Application_Verification__c createAppVerification(Opportunity opportunity, Account vendor, User vendorAdmin, Application_Applicant__c applicant) {
        RecordType recordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' AND DeveloperName = 'Business_Verification' LIMIT 1];
        Application_Verification__c appVerification = new Application_Verification__c(
            Loan_Application__c = opportunity.Id,
            RecordTypeId = recordType.Id,
            Stage__c = 'Draft',
            Vendor__c = vendor.Id,
            Vendor_Admin__c = vendorAdmin.Id,
            Assigned_To_User__c = vendorAdmin.Id,
            Applicant__c = applicant.Id
        );
        insert appVerification;
        return appVerification;
    }
    public static Application_Verification__c createAppVerificationFCU(Opportunity opportunity, Account vendor, User vendorAdmin, Application_Applicant__c applicant) {
        RecordType recordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' AND DeveloperName = 'FCU' LIMIT 1];
        Application_Verification__c appVerification = new Application_Verification__c(
            Loan_Application__c = opportunity.Id,
            RecordTypeId = recordType.Id,
            Stage__c = 'Draft',
            Vendor__c = vendor.Id,
            Vendor_Admin__c = vendorAdmin.Id,
            Assigned_To_User__c = vendorAdmin.Id,
            Applicant__c = applicant.Id
        );
        insert appVerification;
        return appVerification;
    }

    public static Document_Master__c createDocumentMaster() {
        Document_Master__c docMaster = new Document_Master__c(
            Document_Name__c = 'Test Document',
            Document_Category__c = 'Business Verification',
            Is_Active__c = true,
            Requirement_At__c = 'Field Investigation'
        );
        insert docMaster;
        return docMaster;
    }

    public static void addTeamMember(Account account, User user, String role) {
        AccountTeamMember teamMember = new AccountTeamMember(
            AccountId = account.Id,
            UserId = user.Id,
            Authorized_Signatory__c = 'YES',
            TeamMemberRole = role,
            Minimum_authority_loan_amount__c = 100,
            Maximum_authority_loan_amount__c = 200,
            Eligible_Approver_Exception_Reasons__c = 'Fraud Check;Low Cibil Score',
            Level__c = '2'
        );
        insert teamMember;
    }

    public static void createTriggerSettings() {
        Trigger_Settings__c triggerSettings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger__c = true
        );
        insert triggerSettings;
    }
    // Created by Askhat Bhasin for BankAccountControllerTest
    public static Bank_Details__c createBankDetails(Application_Applicant__c applicationApplicant,Bank_Branch_Master__c bankBranchMasterObj) {
        List<Application_Applicant__c> appApp = [Select Customer__c From Application_Applicant__c Where Id =: applicationApplicant.Id];
        
        Bank_Details__c bankDetailsObj = new Bank_Details__c(
            Application_Applicant__c = applicationApplicant.Id,
            Account_Type__c = 'Current',
            Account_Holder_Name__c = 'Account Holder Name',
            Bank_Master__c = bankBranchMasterObj.Id,
            Is_Consider_for_Eligibility__c = true,
            Debit_Card_Status__c = 'Yes',
            Account_Number__c = '12344',
            Customer__c = appApp[0].Customer__c
        );
        insert bankDetailsObj;
        return bankDetailsObj;
    }
    // Created by Askhat Bhasin for BankAccountControllerTest
    public static Bank_Branch_Master__c createBankMasterDetails() {
        Bank_Branch_Master__c bankMasterObj = new Bank_Branch_Master__c(
            Name = 'AXIS5678987',
            IFSC__c = 'HDFC019505',
            Bank_Name__c = 'HDFC Bank',
            Branch_Name__c = 'Branch Name',
            MICR__c = '987654321'
        );
        
        insert bankMasterObj;
        return bankMasterObj;
    }
    // Created by Askhat Bhasin for BankStatementAnalysisHandlerTest
    public static Document_Details__c createBankSentimentAnalysisDetails(contentVersion obj) {
        Document_Details__c bankDocDetailsObj = new Document_Details__c(
            Name = '12 months bank statement',
            Content_Document_Id__c = obj.contentdocumentid,
            Year_Month_From__c = System.Today(),
            Year_month_to__c = System.Today().addDays(30),
            Password__c='test123',
            Institution_Id__c=1234
            
        );
        insert bankDocDetailsObj;
       
        return bankDocDetailsObj;
    }
    
    // Created by Askhat Bhasin for BankStatementAnalysisHandlerTest
    public static ContentVersion createContentVersionDetails() {
        
        ContentVersion objcontentVersion = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert objcontentVersion;
        contentversion cv=[select id,Title,PathonClient,VersionData,IsMajorVersion,contentdocumentid from ContentVersion where id=:objcontentversion.id limit 1];
        
        return cv;
    }
        // Created by Askhat Bhasin for BankStatementAnalysisControllerTest

    public static Integration_Settings__c createintegrationSettingsData() {
        Integration_Settings__c bankintegrationObj = new Integration_Settings__c(
            Name ='Bank Statement Analysis',
            Client_Id__c = 'NA',
            Client_Secret__c = 'NA',
            Endpoint__c = 'Callout:LOS_BL_Bank_statement_analysis',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST'
        );
        
        insert bankintegrationObj;
        return bankintegrationObj;
    }
    
    public static Integration_Details__c createintegrationDetailsData() {
        Integration_Details__c bankintdetailsObj = new Integration_Details__c(
            Name ='BSA',
            Endpoint__c = 'Callout:LOS_BL_Bank_statement_analysis',
            Status__c = '400',
            Method_Type__c = 'POST',
            Object_Name__c = 'Application_Applicant__c',
            Prerequisite__c = 'Error: Prerequisite Failed'
        );
        
        insert bankintdetailsObj;
        return bankintdetailsObj;
    }
    public static Loan_Transaction__c createLoanTransactiondata(Opportunity opp) {
        Id RT = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId();        
        
        
        Loan_Transaction__c LoanTransactionObj = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            Disbursement_Amount__c = 50000,
            First_Disbursement_Amount__c = 10000,
            Schedule_Method__c = 'PFT', // Ensure this value is valid for the picklist
            TDS_Applicable__c = true,
            Rate_Type__c = 'R',
            RecordTypeId = RT,
            Step_Loan__c = true,
            Allow_Planned_EMI_Holiday__c = true,
            Allow_Grace__c = true,
            Allow_BPI__c = true,
            Elastic_Credit_Line_Type__c = 'H',
            Loan_Start_Date__c = Date.today(),
            Interest_Frequency__c = 'Y',
            Allow_Planned_Principal_Holiday__c = true
        );
        
        insert LoanTransactionObj;
        return LoanTransactionObj;
    }
    
    public static Loan_Transaction__c createLoanTransactiondataForLoan(Opportunity opp) {
        Id RT = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Step_Loan_Details').getRecordTypeId();        
        
        
        Loan_Transaction__c LoanTransactionObj = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            Step_Amount__c = 1000,
            Step_Specifier__c = 'Grace',
            Disbursement_Amount__c = 50000,
            First_Disbursement_Amount__c = 10000,
            Schedule_Method__c = 'PFT', // Ensure this value is valid for the picklist
            TDS_Applicable__c = true,
            Rate_Type__c = 'R',
            RecordTypeId = RT,
            Step_Loan__c = true,
            Allow_Planned_EMI_Holiday__c = true,
            Allow_Grace__c = true,
            Allow_BPI__c = true,
            Elastic_Credit_Line_Type__c = 'H',
            Loan_Start_Date__c = Date.today(),
            Interest_Frequency__c = 'Y'
        );
        
        insert LoanTransactionObj;
        return LoanTransactionObj;
    }
    
    public static Opportunity createLoanApplication(Boolean isInsert,Account account){
        // Opportunity opp = new Opportunity();
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Sales login',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        opp.Login_Completion_Stage__c = 'Applicant Information';
        opp.Branch_Master__c = account.Id;
        opp.Requested_Amount__c = 150;
        opp.Final_Amount__c = 10000000;
        opp.Exception_Approval_Status__c = 'Submitted For Approval'; 
        opp.Reasons_For_Execption_Approval__c = 'Fraud Check';
        opp.Negotiated_Tenure__c = 240;
        opp.Sanction_Tenure__c = 240;
        opp.Negotiated_Loan_Amount__c = 1000000;
        opp.Sanction_Loan_Amount__c = 80000;
        opp.Product__c = 'Home Loan';
        opp.Is_Eligible_for_Exception_Approval__c = false;
        opp.Sourcing_Manager__c = UserInfo.getUserId();
        
        if(isInsert){
            insert opp;
        }
        return opp;
    }

    public static Charges_Insurance__c createInsurance(Boolean isInsert, Id opportunityId){
        Charges_Insurance__c chargeInsurance = new Charges_Insurance__c();
        chargeInsurance.Name = 'Test Charge';
        chargeInsurance.Loan_Application__c = opportunityId;
        chargeInsurance.Total_VAS_Amount__c = 9;
        chargeInsurance.Insurance_Premium__c = 1000;
        chargeInsurance.Loan_Amount__c = 10;
        chargeInsurance.Loan_tenure__c = 1;
        chargeInsurance.Policy_Tenure__c = 1;
        chargeInsurance.Value_Date__c = date.today();
        chargeInsurance.RecordTypeId = Utility.getRecordTypeIdByDeveloperName('Charges_Insurance__c','Insurance');
        if(isInsert){
            insert chargeInsurance;
        }
        return chargeInsurance;
    }

    public static string createContentDocument(String fileName, Blob fileData, string applicantId) {
        // Create ContentVersion record
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = fileName;
        contentVersion.PathOnClient = fileName;
        contentVersion.VersionData = fileData;
        contentVersion.IsMajorVersion = true;
        insert contentVersion;
        
        // Retrieve the ContentDocumentId from the ContentVersion
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
        
        // Create ContentDocumentLink record to link the ContentDocument to a record (e.g., Account)
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = contentDocumentId;
        contentDocumentLink.LinkedEntityId = applicantId; // Replace with the actual record ID
        contentDocumentLink.ShareType = 'V';
        contentDocumentLink.Visibility = 'AllUsers';
        insert contentDocumentLink;

        return contentDocumentId;
    }

    public static void createPlfMaster(String masterType, String description, string ficoCode) {

        PLF_Master__c mas = new PLF_Master__c(
            Name = 'test',
            Master_Type__c = masterType, //'Industry',
            Description__c = description, //'Manufacturing',
            FICO_Code__c = ficoCode, //'Manu'
            Gender_Code__c = 'F'
        );
        
        Insert mas;
    }    


}