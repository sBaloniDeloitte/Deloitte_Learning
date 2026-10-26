@isTest
public class TestDataFactory {
    
        public static OpportunityTeamMember createOpportunityTeamMember(Boolean isInsert, Opportunity loanApp) {
            Id currentUserId = UserInfo.getUserId(); // current running user
            
            OpportunityTeamMember teamMember = new OpportunityTeamMember(
                OpportunityId = loanApp.Id,
                UserId = currentUserId,
                TeamMemberRole = 'Sales Rep'
            );
            
            if (isInsert) {
                insert teamMember;
            }
            
            return teamMember;
        }
    public static Charges_Insurance__c createChargesInsurance(Boolean isInsert, Id recordTypeId, opportunity loan) {
        Charges_Insurance__c insurance = new Charges_Insurance__c(
            Loan_Application__c = loan.Id,
            RecordTypeId = recordTypeId,
            Total_VAS_Amount__c = 2000,
            VAS_Code__c = 'VC001',
            Description__c = 'Test Charge',
            Self_Funded__c = true,
            Mode_of_Payment__c = 'Pay Upfront',
            Fee_Accural_Date__c = Date.today(),
            Value_Date__c = Date.today().addDays(1),
            Insurance_Premium__c = 100,
            Loan_Amount__c = 200000,
            Loan_tenure__c = 10,
            Policy_Tenure__c = 5
        );
        
        if (isInsert) {
            insert insurance;
        }
        
        return insurance;
    }
    public static Charges_Insurance_Master__c createChargesInsuranceMaster(Boolean isInsert, Integer sequence) {
        Charges_Insurance_Master__c master = new Charges_Insurance_Master__c(
            VAS_Code__c = 'VAS001',
            Tab_Name__c = 'Tab' + sequence,
            Section_Fields__c = (sequence == 1) ? 'Test_Picklist_Field__c,Other_Field__c' : 'Test_Picklist_Field__c',
            Sequence__c = sequence,
            Section_Name__c = 'Section ' + sequence,
            VAS_Description__c = 'Test Description ' + sequence
        );
        
        if (isInsert) {
            insert master;
        }
        
        return master;
    }
    public static Product2 newProductDetails(Boolean isInsert, Id recordTypeId, Opportunity loanApp) {
        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true,
            Is_loan_VAS_only__c = true,
            Sanctioned_Loan_Amount__c = 5000,
            Loan_Application__c = loanApp.Id,
            RecordTypeId = recordTypeId
        );
        
        if (isInsert) {
            insert prod;
        }
        
        return prod;
    }
    
    Public static Screen_Field__c getScreenDetails ( string formName , string parentid){
        Screen_Field__c field1 = new Screen_Field__c(
            Parent_Screen__c   = parentid,
            
            Form_Name__c = formName,
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Loan_Transaction__c',
            Master_Screen_Name__c = 'Basic Details',
            Screen_Name__c = 'Basic Details',
            Filtered_Picklist_Values__c = 'Option1;Option2',
            Is_Picklist__c = true,
            Is_Active__c = true,
            Field_Label__c = 'Loan Start Date',
            Is_Mandatory__c = true,
            Storage_Object__c = 'Loan_Transaction__c',
            Storage_Field__c = 'Loan_Start_Date__c',
            Field_Sequence__c = 1,
            Section_Seperator__c = false,
            Section_Name__c = 'Loan Section',
            Field_Type__c = 'Date',
            Is_Screen_Active__c = true,
            Custom_Component_Name__c = null,
            Is_Controlling_Picklist__c = false,
            Dependent_Picklist__c = null,
            Read_Field_Name__c = null,
            Picklist_Dependent_On_RecordType__c = false,
            Visibility_Controlled_By__c = null,
            Visibility_Controlled_By_Value__c = null,
            Is_Hidden__c = false,
            Is_Disabled__c = false,
            Maximum_Length__c = 100,
            Is_Formula_Feild__c = false,
            Default_Value__c = '2024-04-15' // Meets the query filter
        );
        return field1;
    }
    public static Customer_Address__c getcustomeradd (string customerid){
        Customer_Address__c custAddRecord = new Customer_Address__c();
        custAddRecord.Customer__c = customerid;
        insert custAddRecord;
        return custAddRecord ;
    }
    
    public static void setupTriggerSettings() {
        if (Trigger_Settings__c.getInstance('Trigger Settings') == null) {
            Trigger_Settings__c settings = new Trigger_Settings__c(
                Name = 'Trigger Settings',
                Lead_Trigger__c = true ,
                Opportunity_Trigger__c = true , 
                City_Master_Trigger__c = true
                
            );
            insert settings;
        }
    }
    
    public static void setupIntegrationSettings(String name) {
        if (Integration_Settings__c.getInstance(name) == null) {
            Integration_Settings__c setting = new Integration_Settings__c();
            // setting.Name = 'Get Token';
            setting.Name= name;
            setting.Client_Id__c ='XXXXXXXXXX';
            setting.Cookie__c='XXXXXXXXXXX';
            setting.Client_Secret__c='XXXXXXXXXXX';
            setting.Endpoint__c='Callout:LOS_BL_Bearer';
            setting.Content_Type__c='application/json';
            setting.Authorization__c='XXXXXXXXXXX';
            setting.Request_Method__c='GET';
            setting.Message_Id__c = 'settingMSGID';
            setting.Entity_Id__c ='ENTITYID';
            insert setting;
        }
        
    }
    
    
    public static List<Account> getTestAccounts(Integer numOfRecs, String recordTypeDeveloperName, Boolean isInsert) {
        RecordType recordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = :recordTypeDeveloperName LIMIT 1];
        
        List<Account> accLst = new  List<Account>();
        for(integer i =1 ;i <= numOfRecs;i++){
            Account acc = new Account(
                Name = 'name'+i,
                RecordTypeId = recordType.Id
            );
            accLst.add(acc);
        }
        if(isInsert){
            insert accLst;
        }
        
        return accLst;
    }
    
    public static List<Integration_Details__c> getTestIntegrationDetails(Integer numOfRecs, String loanApplicationId,  Boolean isInsert) {
        
        List<Integration_Details__c> Lst = new  List<Integration_Details__c>();
        for(integer i =1 ;i <= numOfRecs;i++){
            Integration_Details__c objintegrationDetails = new Integration_Details__c();
            objintegrationDetails.Loan_Application__c = loanApplicationId;
            objintegrationDetails.Name = 'wrapper Loan CRIF';
            objintegrationDetails.Related_Record_Id__c = loanApplicationId;
            objintegrationDetails.Business_Date__c = System.today().addDays(20);
            objintegrationDetails.Endpoint__c = 'www.salesforce.com';
            Lst.add(objintegrationDetails);
        }
        if(isInsert){
            insert Lst;
        }
        
        return Lst;
    }

    public static List<Integration_Details__c> getTestIntegrationDetails2(Integer numOfRecs, String loanApplicationId,  Boolean isInsert, String name) {
        
        List<Integration_Details__c> Lst = new  List<Integration_Details__c>();
        for(integer i =1 ;i <= numOfRecs;i++){
            Integration_Details__c objintegrationDetails = new Integration_Details__c();
            objintegrationDetails.Loan_Application__c = loanApplicationId;
            objintegrationDetails.Name = name;
            objintegrationDetails.Related_Record_Id__c = loanApplicationId;
            objintegrationDetails.Business_Date__c = System.today().addDays(20);
            objintegrationDetails.Endpoint__c = 'www.salesforce.com';
            Lst.add(objintegrationDetails);
        }
        if(isInsert){
            insert Lst;
        }
        
        return Lst;
    }
    //Integration_Details__c
    
    public static List<Applicant_Address__c> getTestApplicantAddressData(Integer numberOfRecs,String applicantId, String custAddRecordId,String pinCodeId,   Boolean isInsert) {
        List<Applicant_Address__c> records = new List<Applicant_Address__c>();
        for(Integer i=1;i<= numberOfRecs;i++){
            Applicant_Address__c rec = new Applicant_Address__c(
                Applicant__c = applicantId,
                Address_Type__c = 'Permanent',
                Address_Source__c = 'Aadhaar',
                Floor_Number__c = '1',
                Building_Street_Name__c = 'Street 1',
                Plot_Number__c = 'Plot 1',
                Pincode__c = pinCodeId,
                Landmark__c = 'Landmark 1',
                Customer_Address__c = custAddRecordId,
                Address_Line_1__c = 'Street 1, Floor 1'
                
            );
            records.add(rec);   
        }
        if(isInsert){
            insert records;
        }
        return records;   
    }
    
    public static List<Pincode_Master__c> getTestPincodeMasterData(Integer numberOfRecs,String cityId,Boolean isInsert) {
        List<Pincode_Master__c> records = new List<Pincode_Master__c>();
        for(Integer i=1;i<= numberOfRecs;i++){
            Pincode_Master__c rec = new Pincode_Master__c();
            rec.Name = '11001'+i;
            rec.City__c = cityId;
            records.add(rec);   
        }
        if(isInsert){
            insert records;
        }
        return records;   
    }
    
    public static List<City_Master__c> getTestCityMasterData(Integer numberOfRecs,Boolean isInsert) {
        List<City_Master__c> records = new List<City_Master__c>();
        for(Integer i=1;i<= numberOfRecs;i++){
            City_Master__c rec = new City_Master__c();
            rec.Name = 'Delhi';
            rec.Country__c = 'IN';
            rec.State__c = 'HR';
            rec.State_Name__c = 'Haryana';
            rec.Country_Name__c = 'India';
            rec.City_Code__c='DL';
            records.add(rec);   
        }
        if(isInsert){
            insert records;
        }
        return records;   
    }
    
    
    public static List<Lead> getTestLeadData(Integer numberOfRecs,Boolean isInsert) {
        List<Lead> records = new List<Lead>();
        for(Integer i=1;i<= numberOfRecs;i++){
            Lead rec = new Lead();
            rec.FirstName = 'John';
            rec.LastName = 'Doe';
            rec.Company = 'ABC Corp';
            rec.MobilePhone = '999999999'+(i+numberOfRecs);
            rec.Status = 'Open';
            rec.Customer_Type__c = 'Individual';
            rec.Product__c = 'Affordable Home Loan';
            rec.Pan__c = 'ABCDE1'+i+'34F';
            records.add(rec);   
        }
        if(isInsert){
            insert records;
        }
        return records;   
    }
    
    public static User getTestUser(String profileId, Boolean isInsert){
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Utility',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = profileId,
            UserName = 'testuser' + DateTime.now().getTime() + '@test.com'
        );
        if(isInsert)
            insert u;
        return u;    
    }
    
    
    public static List<Opportunity> getTestOpportunityData(Integer numberOfRecs,Boolean isInsert) {
        List<Opportunity> records = new List<Opportunity>();
        for(Integer i=1;i<= numberOfRecs;i++){
            Opportunity rec = new Opportunity();
            rec.Name = 'Test Loan';
            rec.StageName = 'Prospecting';
            rec.Product__c = 'Affordable Home Loan';
            rec.CloseDate = Date.today().addDays(10);
            records.add(rec);   
        }
        if(isInsert){
            insert records;
        }
        return records;   
    }
    
    public static List<ContentVersion> getTestContentVersionData(Integer numberOfRecs,Boolean isInsert) {
        List<ContentVersion> records = new List<ContentVersion>();
        for(Integer i=1;i<= numberOfRecs;i++){
            ContentVersion rec = new ContentVersion();
            rec.Title = 'Fail Document';
            rec.PathOnClient = 'FailTest.pdf';
            rec.VersionData = Blob.valueOf('Fail test content');
            records.add(rec);   
        }
        if(isInsert){
            insert records;
        }
        return records;   
    }
    
    public static List<Application_Applicant__c> getTestApplicationApplicantData(Integer numberOfRecs,String loanId,Boolean isInsert) {
        List<Application_Applicant__c> records = new List<Application_Applicant__c>();
        for(Integer i=1;i<= numberOfRecs;i++){
            Application_Applicant__c rec = new Application_Applicant__c();
            rec.Loan_Application__c = loanId;
            rec.Email__c = 'john'+i+'@example.com';
            rec.Mobile_Number__c = '999999999'+i;
            rec.Customer_Type__c = 'Individual';
            rec.Applicant_Type__c = 'Primary Applicant';
            
            records.add(rec);   
        }
        if(isInsert){
            insert records;
        }
        return records;   
    }
    
    
    public static List<Document_Details__c> getTestDocumentDetailsData(Integer numberOfRecs,String loanId, Boolean isInsert) {
        List<Document_Details__c> records = new List<Document_Details__c>();
        for(Integer i=1;i<= numberOfRecs;i++){
            Document_Details__c rec = new Document_Details__c();
            rec.Name = 'SalesDoc.pdf';
            rec.Loan_Application__c = loanId;
            rec.DID_Number__c = 'DID123456';
            rec.Document_Type__c = 'Merged Document';
            rec.Active__c = true;
            rec.Esign_Document__c = true;
            records.add(rec);   
        }
        if(isInsert){
            insert records;
        }
        return records;   
    }
    
    
    public static List<Bank_Branch_Master__c> getTestBankBranchMasterData(Integer numberOfRecs, Boolean isInsert) {
        List<Bank_Branch_Master__c> records = new List<Bank_Branch_Master__c>();
        for(Integer i=1;i<= numberOfRecs;i++){
            Bank_Branch_Master__c rec = new Bank_Branch_Master__c(Name = 'BI'+i,Bank_Name__c = 'SBI Bank', Branch_Name__c = 'Mumbai'+i);
            records.add(rec);   
        }
        if(isInsert){
            insert records;
        }
        return records;   
    }
    
    public static List<Document_Master__c> getTestDocumentMasterData(Integer numberOfRecs, Boolean isInsert) {
        List<Document_Master__c> records = new List<Document_Master__c>();
        for(Integer i=1;i<= numberOfRecs;i++){
            
            Document_Master__c rec = new Document_Master__c(Name = 'Passport',
                                                            Requirement_At__c = 'Loan Application',
                                                            Document_Category__c = 'KYC',
                                                            Document_Name__c = 'Passport',
                                                            Is_Required__c = true
                                                           );
            records.add(rec);   
        }
        if(isInsert){
            insert records;
        }
        return records;   
    }
    
    public static List<Bank_Details__c> getTestBankDetailsData(Integer numberOfRecs,String applicantId, String bankId, Boolean isInsert) {
        List<Bank_Details__c> records = new List<Bank_Details__c>();
        for(Integer i=1;i<= numberOfRecs;i++){
            Bank_Details__c rec = new Bank_Details__c(
                Application_Applicant__c = applicantId,
                Account_Holder_Name__c = 'John Doe',
                Account_Type__c = 'Saving',
                Account_Number__c = '12345678'+i,
                Bank_Master__c = bankId,
                Month__c = 'April',
                Year__c = '2024',
                Source__c = 'Manual'
            );
            records.add(rec);   
        }
        if(isInsert){
            insert records;
        }
        return records;   
    }
    
    public static List<Bank_Statement_Analysis__c> getTestBankStatementAnalysisData(Integer numberOfRecs, String recordTypeId,String bankDetailsId, Boolean isInsert) {
        List<Bank_Statement_Analysis__c> records = new List<Bank_Statement_Analysis__c>();
        for(Integer i=1;i<= numberOfRecs;i++){
            Bank_Statement_Analysis__c rec = new Bank_Statement_Analysis__c( 
                Bank_Details__c = bankDetailsId,
                Source__c = 'Manual',
                Month__c = 'Jan',
                Total_Self_and_Related_Party_Credit__c = 10,
                Amount_of_Self_and_Related_Party_Credit__c = 10000,
                Total_Number_of_Business_Credits__c = 5,
                Total_Amount_of_Business_Credits__c = 5000,
                Number_of_Self_and_Related_Party_Debit__c = 3,
                Total_Self_and_Related_Party_Debit__c = 3000,
                Total_Number_of_Business_Debits__c = 4,
                Total_Amount_of_Business_Debits__c = 4000,
                Cash_Deposit_to_total_Credit__c = 50,
                Cash_withdrwal_to_total_Debit__c = 40,
                Total_number_of_inward_return__c = 1,
                Total_number_of_inward_ECS_return__c = 2,
                Total_number_of_outward_return__c = 1,
                O_w_retruns_as_of_total_credits__c = 5,
                Average_Limit_Utilisation__c = 70,
                ABB__c = 100,
                Total_number_of_inward_Cheque_return__c = 1,
                Value_of_loan_disbursal__c = 100000,
                Total_Number_of_circular_transactions__c = 2,
                Total_Amount_of_EMI__c = 1500,
                Total_Amount_of_Intrest_Charged__c = 500,
                Count_of_loan_disbursal__c = 1,
                Average_EOD_Balance__c = 2000
            );
            if(!String.isBlank(recordTypeId)){
                rec.RecordTypeId = recordTypeId;
            }
            records.add(rec);   
        }
        if(isInsert){
            insert records;
        }
        return records;   
    }    
    
    
    public static ContentDocumentLink getTestContentDocumentLinkData(String cdid,String linkedId, Boolean isInsert) {
        ContentDocumentLink rec =new ContentDocumentLink(
            ContentDocumentId = cdid,
            LinkedEntityId = linkedId,
            ShareType = 'I',
            Visibility = 'AllUsers');
        
        if(isInsert){
            insert rec;
        }
        return rec;   
    }
    
    public static List<Income_Expense_Obligation__c> getTestIncomeExpenseObligationData(Integer numberOfRecs,String applicantId,String recordTypeId, Boolean isInsert) {
        List<Income_Expense_Obligation__c> records = new List<Income_Expense_Obligation__c>();
        for(Integer i=1;i<= numberOfRecs;i++){
            Income_Expense_Obligation__c rec = new Income_Expense_Obligation__c(
                Application_Applicant__c = applicantId,
                RecordTypeId = recordTypeId,
                Year__c = '2023',
                Latest_Month_1_In_Lacs__c = 1.1,
                Latest_Month_2_In_Lacs__c = 2.2,
                Latest_Month_3_In_Lacs__c = 3.3,
                Latest_Month_4_In_Lacs__c = 4.4,
                Latest_Month_5_In_Lacs__c = 5.5,
                Latest_Month_6_In_Lacs__c = 6.6,
                Annualized_GST_Turnover_In_Lacs__c = 100.0
            );
            records.add(rec);
        } 
        if(isInsert){
            insert records;
        }
        return records;   
    }
    
    public static Lead createLeadRecord(String firstName, String middleName, String lastName, String mobileNumber, String company, String custType, String channel) {
        Lead testLead = new Lead();
        testLead.FirstName = firstName;
        testLead.MiddleName = middleName;
        testLead.LastName = lastName;
        testLead.MobilePhone = mobileNumber;
        testLead.Company = company;
        testLead.Customer_Type__c = custType;
        testLead.Status = 'Open';
        testLead.Remarks_History__c = 'Initial Remark';
        
        
        
        testLead.Channel__c = channel != null ? channel : 'Direct'; 
        
        return testLead;
    }
    
    public static void insertLeadRecords(Integer recordCount) {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < recordCount; i++) {
            leads.add(createLeadRecord(
                'First' + i,
                'Middle' + i,
                'Last' + i,
                '123456789' + i,
                'Company' + i,
                'Individual',
                'Direct' 
            ));
        }
        insert leads;
    }
    
    public static Opportunity createLoanApplicationRecord(String status, String productName, String stageName, Date closeDate1){
        
        Opportunity opp = new Opportunity(Name ='Opp test', Status__c = status,Product__c = productName, StageName = stageName, CloseDate = closeDate1);
        //insert opp;
        return opp;  
    }
    
    public static Application_Applicant__c createApplicationApplicant(String Applicant_Type,String Loan_Application, String panName, String panNumber, Date dob){
        Application_Applicant__c app = new Application_Applicant__c(Applicant_Type__c = Applicant_Type,Loan_Application__c = Loan_Application, Pan_Name__c= panName,
                                                                    PAN_Number__c=  panNumber, DOB__c= dob);
        return app;
    }
    
    
    public static Application_Verification__c createApplicationVerification(String applicantId,String Loan_ApplicationId,String Credit_Manager_Remark,String Waiver_Remark,String Admin_s_Remark,String Any_Remarks_Reasons){
        return  new Application_Verification__c(Loan_Application__c = Loan_ApplicationId, 
                                                Applicant__c = applicantId,
                                                Credit_Manager_s_Remarks__c = Credit_Manager_Remark,
                                                Waiver_Remark__c = Waiver_Remark,
                                                Admin_s_Remarks__c = Admin_s_Remark,
                                                Any_Remarks_Reasons__c = Any_Remarks_Reasons);
        
    }
    
    
    public static Document_Details__c createDocumentDetails(String docName, String applicantId, String loanAppId, String cdId){
        
        return  new Document_Details__c(
            Name = docName,
            
            Is_Required__c = True,
            Location__Latitude__s = 20.2,
            Location__Longitude__s = 23.1,
            Loan_Application__c = loanAppId,
            Applicant__c = applicantId,
            Content_Document_Id__c = cdId
        );
    }
    
    public static Document_Master__c createDocumentMaster(String Name){
        
        return  new Document_Master__c(Name = Name,
                                       Requirement_At__c = 'Applicant Level',
                                       Document_Category__c = 'Business Proof',
                                       Document_Name__c = 'Report',
                                       Is_Required__c = true
                                      );
    }
    
    public static Account createAccountRecord(String accountName){
        
        Account acc = new Account();
        acc.Name = accountName ;
        acc.Customer_Type__c = 'Individual' ; 
        return acc;  
    }
    
    public static Product2 createProductRecord(String productName, Boolean activeOrNot){
        
        Product2 prod = new Product2(Name = productName, IsActive = activeOrNot);
        return prod;  
    }
    public static Collateral__c insertCollateral(Boolean isActive) {
        Collateral__c col = new Collateral__c(
            IsActive__c = isActive
        );
        insert col;
        return col;
    }
    
    
    
    public static Integration_Settings__c setupIntegrationSetting(String name, String clientId, String clientSecret, String endPoint, String method) {
        // if (Integration_Settings__c.getInstance(name) == null) {
        //     Integration_Settings__c setting = new Integration_Settings__c();
        //     // setting.Name = 'Get Token';
        //     setting.Name= name;
        //     setting.Client_Id__c ='XXXXXXXXXX';
        //     setting.Cookie__c='XXXXXXXXXXX';
        //     setting.Client_Secret__c='XXXXXXXXXXX';
        //     setting.Endpoint__c='Callout:LOS_BL_Bearer';
        //     setting.Content_Type__c='application/json';
        //     setting.Authorization__c='XXXXXXXXXXX';
        //     setting.Request_Method__c='GET';
        //     insert setting;
        // }
        Integration_Settings__c intSettings = new Integration_Settings__c(
            Name = name,
            Client_Id__c = clientId,
            Client_Secret__c = clientSecret,
            Endpoint__c = endPoint,
            Content_Type__c = 'application/json',
            Request_Method__c = method
        );
        insert intSettings;
        return intSettings;
        
    }
    
    public static Triangulation_Data__c createTriangData(String loanAppId, String applicaApllId, String docType, String sourType) {
        Triangulation_Data__c triData = new Triangulation_Data__c(
            Loan_Application__c = loanAppId,
            Application_Applicant__c = applicaApllId,
            Document_Type__c = docType,
            Source_Type__c = sourType
        );
        //Date_Of_Birth__c = Date.today();
        insert triData;
        return triData;
    }
    
    public static Screen_Field__c createScreenFieldRecords(String name, String fieldLabel, String readFieldName, String storageObject, String parentScreen) {
        Screen_Field__c sc1 = new Screen_Field__c();
        sc1.Field_Label__c = fieldLabel;
        sc1.Read_Field_Name__c = readFieldName;
        sc1.Storage_Object__c = storageObject;
        sc1.Parent_Screen__c = parentScreen;
        insert sc1;
        return sc1;
    }
    
    public static Loan_Transaction__c createLoanTransactionRecord(String loanAppId, String txnRecordTypeId, Boolean quickDis, String qdpStatus) {
        Loan_Transaction__c txn = new Loan_Transaction__c(
            Loan_Application__c = loanAppId,
            RecordTypeId = txnRecordTypeId,
            Quick_Disbursement__c = quickDis,
            QDP_Status__c = qdpStatus
        );
        insert txn;
        return txn;
    }
    
    public static Charges_Insurance__c createChargesInsurance(String name, String loanAppId, String category, String recTypeId) {
        Charges_Insurance__c totalCharges = new Charges_Insurance__c(
            Name = name,
            Loan_Application__c = loanAppId,
            Category__c = category,
            RecordTypeId = recTypeId
        );
        insert totalCharges;
        return totalCharges;
    }
    
    public static Charges_Insurance__c createChargesInsuranc2e(String name, String loanAppId, String category, String recTypeId, Integer num) {
        Charges_Insurance__c totalCharges = new Charges_Insurance__c(
            Name = name,
            Loan_Application__c = loanAppId,
            Category__c = category,
            Insurance_Premium__c = num,
            RecordTypeId = recTypeId,
            Loan_Amount__c = 5000,
            Loan_tenure__c = 456,
            Policy_Tenure__c = 77,
            Total_VAS_Amount__c= 9876
        );
        insert totalCharges;
        return totalCharges;
    }
    
    public static OpportunityFieldHistory createOppFieldHist(String oppId, String field, String newValue) {
        OpportunityFieldHistory hist = new OpportunityFieldHistory(
            OpportunityId = oppId,
            Field = field
            // newValue = newValue
        );
        insert hist;
        return hist;
    }
    
    public static Contact createContactRecord(String name) {
        Contact con = new Contact(LastName = name);
        insert con;
        return con;
    }
    
    public static Opportunity createOppWithBranch(Boolean isInsert) {
    Account branch = new Account(Name = 'Test Offer Branch');
    insert branch;
    List<Opportunity> opps = getTestOpportunityData(1, false);
    Opportunity opp = opps[0];
    opp.Branch_Master__c = branch.Id;
    
    if (isInsert) {
        insert opp;
    }
    return opp;
    }
    
    public static Campaign createTestCampaign(Id branchId, Boolean isInsert) {
        Campaign camp = new Campaign(
            Name = 'Test Offer',
            IsActive = true,
            HL_Applicable_Branches__c = branchId, // Matches Branch_Master__c
            HL_Campaign_Start_Date_Time__c = System.now().addDays(-1),
            HL_Campaign_End_Date_Time__c = System.now().addDays(10),
            HL_Impact_on_ROI__c = 0.5,
            HL_Impact_on_Processing_Fee__c = 1000
        );
        
        if (isInsert) insert camp;
        return camp;
    }
    
}