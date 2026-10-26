@isTest
public class AHL_LoanApplicationActionControllerTest {
    //added
    @testSetup
    static void setupData() {
        User adminUser = [SELECT Id, Profile.Name FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        
        // Step 2: Create Account using existing method
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
        
        Application_Verification__c appVer = FITestDataFactory.createAppVerification(opp, vendor, adminUser, applicant);
        // Create Main Product (RecordType = 'Product')
        Product2 mainProduct = new Product2();
        mainProduct.Name = 'Flexi Loan';
        mainProduct.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        mainProduct.Loan_Application__c = opp.Id;
        mainProduct.Product_Type__c  = 'Parent';
        insert mainProduct;
        Product_Master__c prodM2 = new Product_Master__c(
            Name = 'Flexi Loan',
            RecordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Variant').getRecordTypeId()
        );
        insert prodM2;
        Product2 mainProduct2 = new Product2();
        mainProduct2.Name = 'Flexi Loan';
        mainProduct2.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        mainProduct2.Loan_Application__c = opp.Id;
        mainProduct2.Product_Type__c  = 'Child';
        mainProduct2.Product_Master__c = prodM2.Id;
        insert mainProduct2;
        // Create Sub Product (RecordType = 'Sub Product')
        Product2 subProduct = new Product2();
        subProduct.Name = 'Sub Product';
        subProduct.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
        subProduct.Loan_Application__c = opp.Id;
        subProduct.Product_Type__c = 'Child';
        subProduct.Product__c = mainProduct2.Id;
        subProduct.Product_Master__c = prodM2.Id;
        insert subProduct;
        Product2 subProduct2 = new Product2();
        subProduct2.Name = 'Sub Product2';
        subProduct2.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
        subProduct2.Loan_Application__c = opp.Id;
        subProduct2.Product__c = mainProduct.Id;
        insert subProduct2;
        Product2 subProduct3 = new Product2();
        subProduct3.Name = 'Sub Product3';
        subProduct3.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();
        subProduct3.Loan_Application__c = opp.Id;
        subProduct3.Product__c = subProduct.Id;
        insert subProduct3;
        Product2 subProduct4 = new Product2();
        subProduct4.Name = 'Sub Product3';
        subProduct4.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Variant').getRecordTypeId();
        subProduct4.Loan_Application__c = opp.Id;
        subProduct4.Product__c = subProduct.Id;
        subProduct4.Variant__c = subProduct3.Id;
        insert subProduct4;
        Product2 subProduct5 = new Product2();
        subProduct5.Name = 'Sub Product3';
        subProduct5.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Hybrid Tenure').getRecordTypeId();
        subProduct5.Loan_Application__c = opp.Id;
        subProduct5.Product__c = subProduct4.Id;
        subProduct5.Variant__c = subProduct3.Id;
        subProduct5.Sub_Variant__c = subProduct4.Id;
        insert subProduct5;
        Product2 subProduct6 = new Product2();
        subProduct6.Name = 'Sub Product6';
        subProduct6.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Scheme').getRecordTypeId();
        subProduct6.Loan_Application__c = opp.Id;
        subProduct6.Product__c = subProduct.Id;
        subProduct6.Sub_Variant__c = subProduct4.Id;
        subProduct6.Variant__c = subProduct3.Id;
        insert subProduct6;
        Product2 subProduct7 = new Product2();
        subProduct7.Name = 'Sub Product7';
        subProduct7.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Full EMI').getRecordTypeId();
        subProduct7.Loan_Application__c = opp.Id;
        subProduct7.Product__c = subProduct.Id;
        subProduct7.Sub_Variant__c = subProduct4.Id;
        subProduct7.Variant__c = subProduct3.Id;
        insert subProduct7;
        Product2 subProduct8 = new Product2();
        subProduct8.Name = 'Sub Product8';
        subProduct8.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Total Tenure').getRecordTypeId();
        subProduct8.Loan_Application__c = opp.Id;
        subProduct8.Product__c = subProduct.Id;
        subProduct8.Sub_Variant__c = subProduct4.Id;
        subProduct8.Variant__c = subProduct3.Id;
        insert subProduct8;
        
    }
    @isTest
    static void testGetApplicantsByLoanApplication() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        AHL_LoanApplicationActionController.getConstants();
        Test.startTest();
        List<Application_Applicant__c> applicants = AHL_LoanApplicationActionController.getApplicantsByLoanApplication(loanApp.Id);
        AHL_LoanApplicationActionController.sanctionLetterGeneratedValidation(loanApp.Id);
        AHL_LoanApplicationActionController.sanctionLetterGeneratedValidation(null);
        Document_Details__c dd= TestDataFactory.getTestDocumentDetailsData(1, loanApp.Id, false)[0];
        dd.Name = 'Sanction Letter';
        dd.Active__c = true;
        dd.Target_Date__c = null;
        dd.Status__c = 'Pending';
        dd.Document_Type__c = 'PDD';
        insert dd;
        RecordType rt = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Loan_Transaction__c' 
            AND DeveloperName = 'Transaction_Details' 
            LIMIT 1
        ];
        Loan_Transaction__c loanTxn = new Loan_Transaction__c(
            Loan_Application__c = loanApp.Id,
            RecordTypeId = rt.Id,
            Disbursement_Amount__c = 100000,
            Allow_Payment_in_Grace_Period__c = true,
            Allow_Grace__c = true,
            TDS_Applicable__c = true,
            Step_Loan__c = false,
            Grace_Period_Frequency__c = 1, 
            Interest_Frequency__c = 'Q',     
            Allow_BPI__c = true,
            Allow_Planned_EMI_Holiday__c = true,
            Allow_Planned_EMI_Holiday_in_Grace__c = false,
            Capitalize__c = true,
            Loan_Start_Date__c = Date.today(),
            Schedule_Method__c = 'PFT',         
            Rate_Type__c = 'R',        
            BPI_Treatment__c = 'N',         
            Lock_Period_Months__c = 6
        );
        insert loanTxn;
        Integration_Details__c ind= TestDataFactory.getTestIntegrationDetails(1, loanApp.Id, false)[0];
        ind.Calling_Source__c = 'Loan Scheduler Create Charges';
        ind.Object_Name__c = 'Document_Details__c';
        insert ind;    
        AHL_LoanApplicationActionController.sanctionLetterGeneratedValidation(loanApp.Id);
        try{
            Profile salesProfile = [SELECT Id FROM Profile WHERE Name = 'sales' LIMIT 1];
            User u = new User(
                Username = 'systemsales0090@example.com',
                Alias = 'sysadmin',
                LastName= 'admin',
                Email = 'systemadmin@example.com',
                ProfileId = salesProfile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
                
            );
            insert u;
            system.runAs(u){
                AHL_LoanApplicationActionController.quickActionYes(loanApp.Id, 'SendBack');
                //AHL_LoanApplicationActionController.quickActionYes(loanApp.Id, 'Send_Back');
            }           
        }catch(Exception ex){}
        AHL_LoanApplicationActionController.subStageTONewole('substage');
        try{
            AHL_LoanApplicationActionController.handleQuickDisbursementProcess(loanApp.Id);          
        }catch(Exception ex){}
        AHL_LoanApplicationActionController.getLoanTransactionDetails(loanApp.Id);
        AHL_LoanApplicationActionController.validateQuickDisbursementProcess(loanApp.Id);
        AHL_LoanApplicationActionController.checkQDEComments(loanApp.Id);
        AHL_LoanApplicationActionController.checkQDE(loanApp.Id);
        AHL_LoanApplicationActionController.checkOPSMakerStageValidation(loanApp.Id, false);
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetApplicantsByLoanApplication1() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        AHL_LoanApplicationActionController.getConstants();
        Test.startTest();
        List<Application_Applicant__c> applicants = AHL_LoanApplicationActionController.getApplicantsByLoanApplication(loanApp.Id);
        AHL_LoanApplicationActionController.sanctionLetterGeneratedValidation(loanApp.Id);
        AHL_LoanApplicationActionController.sanctionLetterGeneratedValidation(null);
        Document_Details__c dd= TestDataFactory.getTestDocumentDetailsData(1, loanApp.Id, false)[0];
        dd.Name = 'Sanction Letter';
        dd.Active__c = true;
        dd.Target_Date__c = null;
        dd.Status__c = 'Pending';
        dd.Document_Type__c = 'PDD';
        insert dd;
        RecordType rt = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Loan_Transaction__c' 
            AND DeveloperName = 'Transaction_Details' 
            LIMIT 1
        ];
        Loan_Transaction__c loanTxn = new Loan_Transaction__c(
            Loan_Application__c = loanApp.Id,
            RecordTypeId = rt.Id,
            Disbursement_Amount__c = 100000,
            Allow_Payment_in_Grace_Period__c = true,
            Allow_Grace__c = true,
            TDS_Applicable__c = true,
            Step_Loan__c = false,
            Grace_Period_Frequency__c = 1, 
            Interest_Frequency__c = 'Q',     
            Allow_BPI__c = true,
            Allow_Planned_EMI_Holiday__c = true,
            Allow_Planned_EMI_Holiday_in_Grace__c = false,
            Capitalize__c = true,
            Loan_Start_Date__c = Date.today(),
            Schedule_Method__c = 'PFT',         
            Rate_Type__c = 'R',        
            BPI_Treatment__c = 'N',         
            Lock_Period_Months__c = 6,
            Payment_Method__c = 'PDC'
        );
        insert loanTxn;
        Integration_Details__c ind= TestDataFactory.getTestIntegrationDetails(1, loanApp.Id, false)[0];
        ind.Calling_Source__c = 'Loan Scheduler Create Charges';
        ind.Object_Name__c = 'Document_Details__c';
        insert ind;    
        AHL_LoanApplicationActionController.sanctionLetterGeneratedValidation(loanApp.Id);
        try{
            Profile salesProfile = [SELECT Id FROM Profile WHERE Name = 'sales' LIMIT 1];
            User u = new User(
                Username = 'systemsales0090@example.com',
                Alias = 'sysadmin',
                LastName= 'admin',
                Email = 'systemadmin@example.com',
                ProfileId = salesProfile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
                
            );
            insert u;
            system.runAs(u){
                AHL_LoanApplicationActionController.quickActionYes(loanApp.Id, 'Send_Back');
            }           
        }catch(Exception ex){}
        
        
    }
    
    @isTest
    static void testCheckDedupeAtExist() {
        
        // Get an applicant
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        
        // Mocking static method if checkSFDedupe is complex — assuming it's test-safe.
        Test.startTest();
        try{Boolean result = AHL_LoanApplicationActionController.checkDedupeAtExist(applicant.Id);
           }
        catch(exception ex){}
        Test.stopTest();
        
    }
    
    @isTest static void quickActionSaveTest1(){
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        loanApp.StageName = 'Sales login';
        update loanApp;
        try{
            Profile salesProfile = [SELECT Id FROM Profile WHERE Name = 'sales' LIMIT 1];
            User u = new User(
                Username = 'systemsales0090@example.com',
                Alias = 'sysadmin',
                LastName= 'admin',
                Email = 'systemadmin@example.com',
                ProfileId = salesProfile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
                
            );
            insert u;
            system.runAs(u){
                AHL_LoanApplicationActionController.quickActionSave(loanApp.Id, 'Mark as complete', 'remarks', 'test username');
            }           
        }catch(Exception ex){}
    }

    @isTest
    static void checkIfSendBackCandidateInOtmTest(){
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        insert new Trigger_Bypass_Setting__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger_Bypass__c = true
        );
        
        TestDataFactory.setupTriggerSettings();
        loanApp.StageName = 'PSV';
        loanApp.Sub_stage__c = 'PSV Sales';
        update loanApp;
        
        /*StagechangeRules__mdt mdt = new StagechangeRules__mdt();
        mdt.Button__c = 'Send back';
        mdt.Stage_from__c = 'PSV';
        mdt.Sub_stage_from__c = 'PSV Sales';
        mdt.Stage_to__c = 'Credit Underwriting';
        mdt.Sub_stage_to__c = 'Credit in-progress';
        mdt.Profile__c = 'System Administrator';
        upsert mdt;*/
  


        
        
        
        Test.startTest();
        AHL_LoanApplicationActionController.addUsertoOtm(UserInfo.getUserId(),'Sales',loanApp.Id);
        AHL_LoanApplicationActionController.fetchBranchUsers('Sales',loanApp.Id);
        AHL_LoanApplicationActionController.fetchNextUserProfile(loanApp.Id,'Credit in-progress');
        
        Test.stopTest();
        
    }
    
    @isTest static void quickActionSaveTest2(){
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        loanApp.StageName = 'Sales login';
        update loanApp;
        try{
            Profile salesProfile = [SELECT Id FROM Profile WHERE Name = 'sales' LIMIT 1];
            User u = new User(
                Username = 'systemsales0090@example.com',
                Alias = 'sysadmin',
                LastName= 'admin',
                Email = 'systemadmin@example.com',
                ProfileId = salesProfile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
                
            );
            insert u;
            system.runAs(u){
                AHL_LoanApplicationActionController.quickActionSave(loanApp.Id, 'Send_Back', 'remarks', 'test username');
            }           
        }catch(Exception ex){}
    }
    
    @isTest
    static void testQuickActionSave() {
        try{
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            opp.StageName = 'Sales login';
            opp.Sub_stage__c = 'Login in-progress';
            update opp;
            Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
            User u = new User(
                Username = 'systemadmin@example.com',
                Alias = 'sysadmin',
                LastName= 'admin',
                Email = 'systemadmin@example.com',
                ProfileId = adminProfile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                UserRoleId = null
                
            );
            insert u;
            
            Test.startTest();
            System.RunAs(u)
            {
                String result = AHL_LoanApplicationActionController.quickActionSave(
                    opp.Id, '', 'Test remark', 'OpsUser'
                );            
            }
            Test.stopTest();
        }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
        }
    }
    @isTest
    static void testSendLoanApplicationReturnedEmailHTML() {
        Test.startTest();
        AHL_LoanApplicationActionController.sendLoanApplicationReturnedEmailHTML(
            'OpsUser', 'test@example.com', 'Ops Manager',
            'Loan123', 'Please check the document', 'https://example.com/loanapp'
        );
        Test.stopTest();
        // No assertion possible here, but we can confirm it runs without exception
    }
    
    @isTest
    static void testCreditUnderwritingToPSVValidations() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<String> errors = AHL_LoanApplicationActionController.creditUnderwritingToPSVValidations(opp.Id);
        Test.stopTest();
        System.assert(!errors.isEmpty(), 'Expected validation errors for missing data');
    }
    @isTest
    static void getSendBackRemarksTest() {
        Opportunity opp= TestDataFactory.getTestOpportunityData(1, false)[0];
        opp.Send_Back_Remarks__c ='{ Send Back }  { PSV to Credit Underwriting } { 05:46:16 PM }  { September 17, 2025 }  { Anshu Sales } {test } || { Send Back }  { PSV to Credit Underwriting } { 06:02:04 PM }  { September 17, 2025 }  { Anshu Sales } {Yes } || { Send Back }  { PSV to Credit Underwriting } { 06:16:46 PM }  { September 17, 2025 }  { Anshu Sales } {Yes } || { Send Back }  { PSV to Credit Underwriting } { 06:38:59 PM }  { September 17, 2025 }  { Anshu Sales } {Yes } || { Send Back }  { PSV to Credit Underwriting } { 06:52:40 PM }  { September 17, 2025 }  { Anshu Sales } {Yes } || { Mark as complete }  { PSV to Disbursement } { 07:41:48 PM }  { September 21, 2025 }  { Anshu Sales } {K } || { Mark as complete }  { PSV to PSV } { 07:48:41 PM }  { September 21, 2025 }  { Anshu Sales } {A } || { Mark as complete }  { PSV to Disbursement } { 07:49:51 PM }  { September 21, 2025 }  { Anshu Sales } {A } || { Mark as complete }  { PSV to PSV } { 07:50:37 PM }  { September 21, 2025 }  { Anshu Sales } {A } || { Mark as complete }  { PSV to PSV } { 07:55:27 PM }  { September 21, 2025 }  { Anshu Sales } {A }';
        insert opp;
        Test.startTest();
        AHL_LoanApplicationActionController.getSendBackRemarks(opp.Id);
        AHL_LoanApplicationActionController.calculateWaiverAmount(opp.Id);
        Test.stopTest();
    }
    
    @isTest
    static void callStageChangeAPITest() {
        Opportunity opp= TestDataFactory.getTestOpportunityData(1, false)[0];
        opp.Send_Back_Remarks__c ='{ Send Back }  { PSV to Credit Underwriting } { 05:46:16 PM }  { September 17, 2025 }  { Anshu Sales } {test } || { Send Back }  { PSV to Credit Underwriting } { 06:02:04 PM }  { September 17, 2025 }  { Anshu Sales } {Yes } || { Send Back }  { PSV to Credit Underwriting } { 06:16:46 PM }  { September 17, 2025 }  { Anshu Sales } {Yes } || { Send Back }  { PSV to Credit Underwriting } { 06:38:59 PM }  { September 17, 2025 }  { Anshu Sales } {Yes } || { Send Back }  { PSV to Credit Underwriting } { 06:52:40 PM }  { September 17, 2025 }  { Anshu Sales } {Yes } || { Mark as complete }  { PSV to Disbursement } { 07:41:48 PM }  { September 21, 2025 }  { Anshu Sales } {K } || { Mark as complete }  { PSV to PSV } { 07:48:41 PM }  { September 21, 2025 }  { Anshu Sales } {A } || { Mark as complete }  { PSV to Disbursement } { 07:49:51 PM }  { September 21, 2025 }  { Anshu Sales } {A } || { Mark as complete }  { PSV to PSV } { 07:50:37 PM }  { September 21, 2025 }  { Anshu Sales } {A } || { Mark as complete }  { PSV to PSV } { 07:55:27 PM }  { September 21, 2025 }  { Anshu Sales } {A }';
        insert opp;
        TestDataFactory.setupIntegrationSettings('Stage Change');
        TestDataFactory.setupIntegrationSettings('Get Token');
        Test.setMock(HttpCalloutMock.class, new CalloutMock());
        Test.startTest();
        
        AHL_LoanApplicationActionController.callStageChangeAPI(opp.Id, 'GHF1001HL0005309');
        AHL_LoanApplicationActionController.getLoanTxnDetails(opp.Id);
        AHL_LoanApplicationActionController.validateQDPPaymentRec(opp.Id, 100.9);
        
        PLF_Master__c mas = new PLF_Master__c(
            Name = 'test',
            Master_Type__c = 'Disbursement Party',
            Description__c = 'Manufacturing',
            FICO_Code__c = 'Manu',
            Gender_Code__c = 'BD'
        );
        insert mas;
        AHL_LoanApplicationActionController.getMasterCode();
        Test.stopTest();
    }
    @isTest
    static void getApplicantAddressTest() {
        TestDataFactory.setupTriggerSettings();
        Opportunity opp= TestDataFactory.getTestOpportunityData(1, false)[0];
        opp.Send_Back_Remarks__c ='{ Send Back }  { PSV to Credit Underwriting } { 05:46:16 PM }  { September 17, 2025 }  { Anshu Sales } {test } || { Send Back }  { PSV to Credit Underwriting } { 06:02:04 PM }  { September 17, 2025 }  { Anshu Sales } {Yes } || { Send Back }  { PSV to Credit Underwriting } { 06:16:46 PM }  { September 17, 2025 }  { Anshu Sales } {Yes } || { Send Back }  { PSV to Credit Underwriting } { 06:38:59 PM }  { September 17, 2025 }  { Anshu Sales } {Yes } || { Send Back }  { PSV to Credit Underwriting } { 06:52:40 PM }  { September 17, 2025 }  { Anshu Sales } {Yes } || { Mark as complete }  { PSV to Disbursement } { 07:41:48 PM }  { September 21, 2025 }  { Anshu Sales } {K } || { Mark as complete }  { PSV to PSV } { 07:48:41 PM }  { September 21, 2025 }  { Anshu Sales } {A } || { Mark as complete }  { PSV to Disbursement } { 07:49:51 PM }  { September 21, 2025 }  { Anshu Sales } {A } || { Mark as complete }  { PSV to PSV } { 07:50:37 PM }  { September 21, 2025 }  { Anshu Sales } {A } || { Mark as complete }  { PSV to PSV } { 07:55:27 PM }  { September 21, 2025 }  { Anshu Sales } {A }';
        insert opp;
        
        PLF_Master__c mas1 = new PLF_Master__c(Name = 'Gender',Master_Type__c = 'Gender', Description__c = 'Male',FICO_Code__c = 'Manu',Gender_Code__c = 'BD');
        PLF_Master__c mas2 = new PLF_Master__c(Name = 'Nationality',Master_Type__c = 'Nationality', Description__c = 'Indian',FICO_Code__c = 'Manu',Gender_Code__c = 'BD');
        PLF_Master__c mas3 = new PLF_Master__c(Name = 'Qualification',Master_Type__c = 'Qualification', Description__c = 'Male',FICO_Code__c = 'Manu',Gender_Code__c = 'BD');
        PLF_Master__c mas4 = new PLF_Master__c(Name = 'Caste',Master_Type__c = 'Caste', Description__c = 'Male',FICO_Code__c = 'Manu',Gender_Code__c = 'BD');
        PLF_Master__c mas5 = new PLF_Master__c(Name = 'Religion',Master_Type__c = 'Religion', Description__c = 'Male',FICO_Code__c = 'Manu',Gender_Code__c = 'BD');
        PLF_Master__c mas6 = new PLF_Master__c(Name = 'Residency Status',Master_Type__c = 'Residency Status', Description__c = 'Male',FICO_Code__c = 'Manu',Gender_Code__c = 'BD');
        PLF_Master__c mas7 = new PLF_Master__c(Name = 'Sub sector',Master_Type__c = 'Sub sector',Sector_Code__c='SENP', Description__c = 'Male',FICO_Code__c = 'Manu',Gender_Code__c = 'BD');
        PLF_Master__c mas8 = new PLF_Master__c(Name = 'Address Type',Master_Type__c = 'Address Type', Description__c = 'Male',FICO_Code__c = 'Manu',Gender_Code__c = 'BD');
        
        insert new List<PLF_Master__c> {mas1,mas2,mas3,mas4,mas5,mas6,mas7,mas8};
            City_Master__c city = TestDataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1,city.Id,true)[0];
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = opp.Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        applicant.Applicant_Type__c ='Primary Applicant';
        applicant.Customer_Profile__c = 'SENP';
        insert applicant;
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Customer_Address__c custAddRecord = new Customer_Address__c();
        custAddRecord.Customer__c = customer.Id;
        insert custAddRecord;
        Applicant_Address__c appadd=   TestDataFactory.getTestApplicantAddressData(1, applicant.Id, custAddRecord.Id, pinCode.Id, false)[0];
        appadd.Address_Priority__c = '5';
        appadd.Address_Type__c = 'Permanent';
        appadd.Document_Details__c = TestDataFactory.getTestDocumentDetailsData(1, opp.Id, true)[0].Id;
        appadd.Address_Line_1__c ='djjfd';
        insert appadd;
        TestDataFactory.setupIntegrationSettings('Stage Change');
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('Create Customer');
        
        Test.setMock(HttpCalloutMock.class, new CalloutMock());
        
        Test.startTest();
        AHL_LoanApplicationActionController.getApplicantAddress(new Set<String>{applicant.Id});
        try{
            AHL_LoanApplicationActionController.initiateAPIRequest(opp.Id, false);
        }catch(exception e){}
       
        Test.stopTest();
    }
    
    
    class CalloutMock implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type','application/json');
            Map<String,Object> body = new Map<String,Object>();
            body.put('finReference','GHF1001HL0005309');
            body.put('returnStatus',new Map< String,String>{'returnCode'=>'009','returnText'=>'Success'});
            body.put('disbursement',new List<Object>());
            res.setBody(JSON.serialize(body));
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest static void saveSplitLoansTest(){
      
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1]; 
        Id recordTypeId = [
    SELECT Id 
    FROM RecordType 
    WHERE SObjectType = 'Charges_Insurance__c' 
    AND Name = 'Charges' 
    LIMIT 1
].Id;
        
Product2 mainProduct = [
    SELECT Id, Name, RecordTypeId, Loan_Application__c
    FROM Product2    where  RecordType.DeveloperName = 'Product'
    AND Name = 'Flexi Loan'
    LIMIT 1
];
       

        Charges_Insurance__c CI = TestDatafactory.createChargesInsurance(false ,recordTypeId, oppRec);
    CI.Loan_Application__c = oppRec.id;
        CI.Product__c  = mainProduct.id; 
             CI.Category__c = 'LOS';
             CI.Name ='PROCFEE';
        insert ci; 
        
        AHL_LoanApplicationActionController.saveSplitLoans(oppRec.Id);
    }
    
    @isTest static void saveSplitLoansTest2(){
      
        Opportunity oppRec = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert oppRec;
        Id recordTypeId = [
    SELECT Id 
    FROM RecordType 
    WHERE SObjectType = 'Charges_Insurance__c' 
    AND Name = 'Charges' 
    LIMIT 1
].Id;
        RecordType productRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND Name = 'Product' LIMIT 1];
        Product2 mainProduct1 = new Product2(Name = 'Home Loan',Product_Type__c = 'Parent',Loan_Application__c = oppRec.Id,RecordTypeId = productRt.Id);
        insert mainProduct1;
        
        Product2 mainProduct = new Product2();
        mainProduct.Name = 'Home Loan';
        mainProduct.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        mainProduct.Loan_Application__c = oppRec.Id;
        mainProduct.Product_Type__c  = 'Parent';
        insert mainProduct;
        Product_Master__c prodM2 = new Product_Master__c(
            Name = 'Home Loan',
            RecordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Variant').getRecordTypeId()
        );
        insert prodM2;
        Product2 mainProduct2 = new Product2();
        mainProduct2.Name = 'Home Loan';
        mainProduct2.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        mainProduct2.Loan_Application__c = oppRec.Id;
        mainProduct2.Product_Type__c  = 'Child';
        mainProduct2.Product_Master__c = prodM2.Id;
        insert mainProduct2;
        // Create Sub Product (RecordType = 'Sub Product')
        Product2 subProduct = new Product2();
        subProduct.Name = 'Sub Product';
        subProduct.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
        subProduct.Loan_Application__c = oppRec.Id;
        subProduct.Product_Type__c = 'Child';
        subProduct.Product__c = mainProduct2.Id;
        subProduct.Product_Master__c = prodM2.Id;
        insert subProduct;
        Product2 subProduct2 = new Product2();
        subProduct2.Name = 'Sub Product2';
        subProduct2.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
        subProduct2.Loan_Application__c = oppRec.Id;
        subProduct2.Product__c = mainProduct.Id;
        insert subProduct2;
        Product2 subProduct3 = new Product2();
        subProduct3.Name = 'Sub Product3';
        subProduct3.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();
        subProduct3.Loan_Application__c = oppRec.Id;
        subProduct3.Product__c = subProduct.Id;
        insert subProduct3;
        Product2 subProduct4 = new Product2();
        subProduct4.Name = 'Sub Product3';
        subProduct4.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Variant').getRecordTypeId();
        subProduct4.Loan_Application__c = oppRec.Id;
        subProduct4.Product__c = subProduct.Id;
        subProduct4.Variant__c = subProduct3.Id;
        insert subProduct4;
        Product2 subProduct5 = new Product2();
        subProduct5.Name = 'Sub Product3';
        subProduct5.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Hybrid Tenure').getRecordTypeId();
        subProduct5.Loan_Application__c = oppRec.Id;
        subProduct5.Product__c = subProduct4.Id;
        subProduct5.Variant__c = subProduct3.Id;
        subProduct5.Sub_Variant__c = subProduct4.Id;
        insert subProduct5;
        Product2 subProduct6 = new Product2();
        subProduct6.Name = 'Sub Product6';
        subProduct6.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Scheme').getRecordTypeId();
        subProduct6.Loan_Application__c = oppRec.Id;
        subProduct6.Product__c = subProduct.Id;
        subProduct6.Sub_Variant__c = subProduct4.Id;
        subProduct6.Variant__c = subProduct3.Id;
        insert subProduct6;
        Product2 subProduct7 = new Product2();
        subProduct7.Name = 'Sub Product7';
        subProduct7.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Full EMI').getRecordTypeId();
        subProduct7.Loan_Application__c = oppRec.Id;
        subProduct7.Product__c = subProduct.Id;
        subProduct7.Sub_Variant__c = subProduct4.Id;
        subProduct7.Variant__c = subProduct3.Id;
        insert subProduct7;
        Product2 subProduct8 = new Product2();
        subProduct8.Name = 'Sub Product8';
        subProduct8.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Total Tenure').getRecordTypeId();
        subProduct8.Loan_Application__c = oppRec.Id;
        subProduct8.Product__c = subProduct.Id;
        subProduct8.Sub_Variant__c = subProduct4.Id;
        subProduct8.Variant__c = subProduct3.Id;
        insert subProduct8;
        
         Product2 parentProduct = [SELECT Id,Name FROM Product2 WHERE Loan_Application__c = :oppRec.Id AND RecordType.Name = 'Product' LIMIT 1];
        Product2 variant;
        Product2 subVariant;
        Product2 hybrid;
        Product2 scheme;
        Product2 fullEmi;
        Product2 totalTenure;
       
            variant = [SELECT Id FROM Product2 WHERE Loan_Application__c = :oppRec.Id AND RecordType.Name = 'Variant' LIMIT 1];
            subVariant = [SELECT Id, Variant__c FROM Product2 WHERE Loan_Application__c = :oppRec.Id AND RecordType.Name = 'Sub Variant' LIMIT 1];
            hybrid = [SELECT Id FROM Product2 WHERE Loan_Application__c = :oppRec.Id AND RecordType.Name = 'Hybrid Tenure' LIMIT 1];
            scheme = [SELECT Id FROM Product2 WHERE Loan_Application__c = :oppRec.Id AND RecordType.Name = 'Scheme' LIMIT 1];
            fullEmi = [SELECT Id FROM Product2 WHERE Loan_Application__c = :oppRec.Id AND RecordType.Name = 'Full EMI' LIMIT 1];
            totalTenure = [SELECT Id FROM Product2 WHERE Loan_Application__c = :oppRec.Id AND RecordType.Name = 'Total Tenure' LIMIT 1];

        Charges_Insurance__c CI = TestDatafactory.createChargesInsurance(false ,recordTypeId, oppRec);
    CI.Loan_Application__c = oppRec.id;
        CI.Product__c  = mainProduct.id; 
             CI.Category__c = 'LOS';
             CI.Name ='PROCFEE';
        insert ci; 
        
        AHL_LoanApplicationActionController.saveSplitLoans(oppRec.Id);
    }
    
    @isTest static void fetchChildLoanDetailsTest(){
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        opp.Split_Parent_Loan_Application__c = oppRec.Id;
        insert opp;
        RecordType rt = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Loan_Transaction__c' 
            AND DeveloperName = 'Transaction_Details' 
            LIMIT 1
        ];
        Loan_Transaction__c loanTxn = new Loan_Transaction__c(
            Loan_Application__c = oppRec.Id,
            RecordTypeId = rt.Id,
            Disbursement_Amount__c = 100000,
            Allow_Payment_in_Grace_Period__c = true,
            Allow_Grace__c = true,
            TDS_Applicable__c = true,
            Step_Loan__c = false,
            Grace_Period_Frequency__c = 1, 
            Interest_Frequency__c = 'Q',     
            Allow_BPI__c = true,
            Allow_Planned_EMI_Holiday__c = true,
            Allow_Planned_EMI_Holiday_in_Grace__c = false,
            Capitalize__c = true,
            Loan_Start_Date__c = Date.today(),
            Schedule_Method__c = 'PFT',         
            Rate_Type__c = 'R',        
            BPI_Treatment__c = 'N',         
            Lock_Period_Months__c = 6,
            Repayment_Schedule_DateTime__c = Datetime.valueOfGmt('2025-04-10 10:13:11'),
            Latest_Sanction_Generated_DateTime__c =Datetime.valueOfGmt('2025-04-10 10:13:11')
        );
        insert loanTxn;
        AHL_LoanApplicationActionController.fetchChildLoanDetails(oppRec.Id);
        AHL_LoanApplicationActionController.checkBankDetailsFilledOrNot(oppRec.Id);
        AHL_LoanApplicationActionController.checkPsvSalesToPsvCreditValidation(oppRec.Id);
        AHL_LoanApplicationActionController.getMonthDiff(Date.today(),Date.today());
        AHL_LoanApplicationActionController.checkDPDOver30('agsdyasdasdweqe/.n.sadasdwe>asdasd');
    }
    @isTest static void fetchChildLoanDetailsNegativeTest(){
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];
        try{
            AHL_LoanApplicationActionController.fetchChildLoanDetails(oppRec.Id); 
        }catch(Exception ex){}
        
    }
    @isTest static void fetchParentLoanDetailTest(){
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        opp.Split_Parent_Loan_Application__c = oppRec.Id;
        insert opp;
        try{
            AHL_LoanApplicationActionController.fetchParentLoanDetail(opp.Id);
        }catch(Exception ex){
        }
    }
    @isTest static void fetchParentLoanDetailNegativeTest(){
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        opp.Split_Parent_Loan_Application__c = oppRec.Id;
        insert opp;
        try{
            AHL_LoanApplicationActionController.fetchParentLoanDetail(null);
        }catch(Exception ex){
        }
    }

    @isTest static void testHandleExistingCIF(){
        // Account that satisfies Customer__c lookup filter
        Id customerRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get('Customer')
            .getRecordTypeId();

        Account acc = new Account(
            Name = 'Test Customer',
            RecordTypeId = customerRtId,
            Customer_Type__c = 'Individual'
        );
        insert acc;

        // 2. Create Loan Application 
        Opportunity opp = new Opportunity(
            Name = 'Test Loan Application',
            Product__c = 'Affordable Home Loan'
        );
        insert opp;

        // 3. Create Application Applicant linked to Account
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            PAN_Number__c = 'OLPMT2453F',
            Customer__c = acc.Id,
            Loan_Application__c = opp.Id
        );
        insert applicant;

        // 4. Call future method
        Test.startTest();
        Map<Id,Account> accMapo = AHL_LoanApplicationActionController.handleExistingCIF(
            new List<String>{'PAN Number:OLPMT2453F already exists for Customer CIF: 183940'}
        );
        Test.stopTest();

        // 5. Verify Account update
        Account updatedAcc = [
            SELECT Customer_LMS_Id__c, Exisiting_Customer__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        // System.assertEquals(
        //     '183940',
        //     updatedAcc.Customer_LMS_Id__c,
        //     'CIF should be updated'
        // );
        // System.assertEquals(
        //     true,
        //     updatedAcc.Exisiting_Customer__c,
        //     'Existing customer flag should be true'
        // );

        
    }
    @isTest
    static void testValidateApplicantAddressPriorities(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app =[SELECT Id FROM Application_Applicant__c LIMIT 1];
        insert new Applicant_Address__c(Applicant__c = app.Id,Address_Type__c = 'Permanent', Flag_PO_as_High__c = true);
        Test.startTest();
        List<String> result =AHL_LoanApplicationActionController.validateApplicantAddressPriorities(opp.Id);
        Test.stopTest();
        System.assert(result.size() > 0);
    }
    @isTest
    static void testUpdateLoanSanctionTenureField(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        AHL_LoanApplicationActionController.updateLoanSanctionTenureField(opp.Id);
        Test.stopTest();
    }
    @isTest
    static void testCheckIfUserAlreadyExistsInOtm() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityTeamMember otm = new OpportunityTeamMember(OpportunityId = opp.Id,UserId = UserInfo.getUserId(),TeamMemberRole = 'Credit',Associated_With_Loan_Application__c = true);
        insert otm;
        Test.startTest();
        Decimal count =AHL_LoanApplicationActionController.checkIfUserAlreadyExistsInOtm('Credit',opp.Id);
        Test.stopTest();
        System.assertEquals(1, count);
    }
    @isTest
    static void testCheckCollateral() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // Create collateral with required fields intentionally left blank
        Collateral__c collateral = new Collateral__c();
        insert collateral;

        Application_Collateral__c appCollateral =
            new Application_Collateral__c(
                HL_Loan_Application__c = opp.Id,
                Collateral__c = collateral.Id
            );
        insert appCollateral;

        Test.startTest();

        List<String> validations =AHL_LoanApplicationActionController.checkCollateral(opp.Id);

        Test.stopTest();

        System.assert(validations.size() > 0);
    }
    @isTest
    static void testCheckCollateral_NoErrors() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Collateral__c collateral = new Collateral__c(Building_Name__c = 'Building A',Asset_Collateral__c = 'Collateral',Mortgage_Type__c = 'REGISTERED MORTGAGE',Pocket__c = 'A',
            Street_Name__c = 'MG Road',Survey_Number_Gat_No__c = '123',Plot_Number__c = '45',House_Flat_Shop_Unit_No__c = '101');
        insert collateral;
        insert new Application_Collateral__c(HL_Loan_Application__c = opp.Id,Collateral__c = collateral.Id);
        Test.startTest();
        List<String> validations =AHL_LoanApplicationActionController.checkCollateral(opp.Id);
        Test.stopTest();
        System.assertEquals(0, validations.size());
    }
    @isTest
    static void testCheckIfSendBackCandidateInOtm() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName = 'PSV';
        opp.Sub_stage__c = 'PSV Sales';
        update opp;
        Profile salesProfile =[SELECT Id FROM Profile WHERE Name = 'Sales' LIMIT 1];
        User salesUser = new User(Username='salesuser11223344@test.com',Alias='sales',LastName='User',Email='salesuser@test.com',ProfileId=salesProfile.Id,
            TimeZoneSidKey='Asia/Kolkata',LocaleSidKey='en_US',EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US');
        insert salesUser;
        Test.startTest();
        System.runAs(salesUser){
            String result =AHL_LoanApplicationActionController.checkIfSendBackCandidateInOtm(opp.Id);
        }
        Test.stopTest();
    }
    @isTest
    static void testCheckDPDOver30Coverage(){
        Test.startTest();
        Boolean result1 =AHL_LoanApplicationActionController.checkDPDOver30('XXX 45 STD');
        Boolean result2 =AHL_LoanApplicationActionController.checkDPDOver30('XXX 15 40 STD');
        Test.stopTest();
        System.assertEquals(true,result2);
    }
    @isTest
    static void testAddUserToOtm_UpdateBranch(){
        Opportunity opp =[SELECT Id FROM Opportunity LIMIT 1];
        OpportunityTeamMember oldOtm =new OpportunityTeamMember(OpportunityId = opp.Id,UserId = UserInfo.getUserId(),TeamMemberRole = 'Sales',OpportunityAccessLevel = 'Edit',Associated_With_Loan_Application__c = true);
        insert oldOtm;
        Test.startTest();
        AHL_LoanApplicationActionController.addUsertoOtm(UserInfo.getUserId(),'Sales',opp.Id);
        Test.stopTest();
        oldOtm =[SELECT Associated_With_Loan_Application__c FROM OpportunityTeamMember WHERE Id=:oldOtm.Id];
    }
    @isTest
    static void testFetchNextUserProfile_OPSMaker(){

        Opportunity opp =
            [SELECT Id FROM Opportunity LIMIT 1];

        Application_Applicant__c app =[SELECT Id,Customer_Profile__c FROM Application_Applicant__c WHERE Loan_Application__c=:opp.Id LIMIT 1];
        app.Customer_Type__c='Individual';
        app.Customer_Profile__c = 'Salaried Indian';
        app.Sector__c ='Central / State Government Employee';
        app.Sub_Employment_Type_Non_Individual__c='Salaried';
        update app;
        Test.startTest();
        String result =AHL_LoanApplicationActionController.fetchNextUserProfile(opp.Id,'PSV Credit');
        Test.stopTest();
        System.assertEquals('OPS Maker',result);
    }
    @isTest
    static void testFetchNextUserProfile_OPSMakerStage(){
        Opportunity opp =[SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        String result =AHL_LoanApplicationActionController.fetchNextUserProfile(opp.Id,'OPS Maker');
        Test.stopTest();
        System.assertEquals('OPS Maker',result);
    }
    @isTest
    static void testFetchNextUserProfile_OPSAuthor(){
        Opportunity opp =[SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        String result =AHL_LoanApplicationActionController.fetchNextUserProfile(opp.Id,'OPS Author');
        Test.stopTest();
        System.assertEquals('OPS Author',result);
    }
    @isTest
    static void testFetchNextUserProfile_Default(){
        Opportunity opp =[SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        String result =AHL_LoanApplicationActionController.fetchNextUserProfile(opp.Id,'Login in-progress');
        Test.stopTest();
        System.assertEquals('Sales',result);
    }
    @isTest
    static void quickActionSave_SendBack_OpsMaker_Path() {
        Opportunity opp =[SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName = 'Disbursement';
        opp.Sub_stage__c = 'Ops Maker';
        update opp;
        Application_Applicant__c app =[SELECT Id, Customer_Profile__c FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        app.Customer_Type__c='Individual';
        app.Customer_Profile__c = 'Salaried Indian';
        app.Sector__c ='Central / State Government Employee';
        app.Sub_Employment_Type_Non_Individual__c='Salaried';
        app.CIBIL_Score__c =760;
        update app;
        Profile salesProfile =[SELECT Id FROM Profile WHERE Name='Sales' LIMIT 1];
        User u = new User(Username='opsmaker1@test.com',Alias='ops1',LastName='Test',Email='opsmaker1@test.com',ProfileId=salesProfile.Id,
            TimeZoneSidKey='America/Los_Angeles',LocaleSidKey='en_US',EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US');
        insert u;
        Test.startTest();
        System.runAs(u){
            String result =AHL_LoanApplicationActionController.quickActionSave(opp.Id,'Send_Back','remarks','tester');
            System.assertEquals('Application sent back successfully', result);
        }
        Test.stopTest();
    }
    @isTest
    static void quickActionSave_QDE_Branch() {
        Opportunity opp =[SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName='Sales login';
        opp.Sub_stage__c='Login in-progress';
        update opp;
        Application_Applicant__c app =[SELECT Id,Customer_Profile__c,Applicant_Type__c FROM Application_Applicant__c WHERE Loan_Application__c=:opp.Id LIMIT 1];
        app.Customer_Type__c='Individual';
        app.Customer_Profile__c='SEP';
        app.Sector__c ='Doctor';
        app.Sub_Employment_Type_Non_Individual__c='SEP-Doctors';
        app.Applicant_Type__c='Primary Applicant';
        update app;
        Profile salesProfile =[SELECT Id FROM Profile WHERE Name='Sales' LIMIT 1];
        User salesUser = new User(Username='salesqde@test.com',Alias='sale',LastName='User',Email='salesqde@test.com',ProfileId=salesProfile.Id,
            TimeZoneSidKey='America/Los_Angeles',LocaleSidKey='en_US',EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US');
        insert salesUser;
        Test.startTest();
        System.runAs(salesUser){
            try{
                AHL_LoanApplicationActionController.quickActionSave(opp.Id,'Mark as complete','remarks','tester');
            }catch(Exception e){}
        }
        Test.stopTest();
    }
    @isTest
    static void quickActionSave_EditAccessOtm_Path() {
        Opportunity opp =[SELECT Id, StageName, Sub_stage__c FROM Opportunity LIMIT 1];
        opp.StageName = 'Sales login';
        opp.Sub_stage__c = 'Login in-progress';
        update opp;
        Application_Applicant__c app =[SELECT Id, Customer_Profile__c FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        app.Customer_Type__c='Individual';
        app.Customer_Profile__c = 'Salaried Indian';
        app.Sector__c ='Central / State Government Employee';
        app.Sub_Employment_Type_Non_Individual__c='Salaried';
        update app;
        OpportunityTeamMember creditOtm =new OpportunityTeamMember(OpportunityId = opp.Id,UserId = UserInfo.getUserId(),
                TeamMemberRole = 'Credit',Associated_With_Loan_Application__c = true,OpportunityAccessLevel = 'Read');
        insert creditOtm;
        Profile salesProfile =[SELECT Id FROM Profile WHERE Name = 'Sales' LIMIT 1];
        User salesUser = new User(Username='editaccessotm@test.com',Alias='edotm',LastName='User',Email='editaccessotm@test.com',
            ProfileId=salesProfile.Id,TimeZoneSidKey='America/Los_Angeles',LocaleSidKey='en_US',EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US');
        insert salesUser;
        Test.startTest();
        System.runAs(salesUser){
            try{
                AHL_LoanApplicationActionController.quickActionSave(opp.Id,'Mark as complete','remarks','tester');
            }
            catch(Exception ex){
                System.debug(ex.getMessage());
            }
        }
        Test.stopTest();
    }
    @isTest
    static void quickActionSave_ReassignNeeded_Path() {
        Opportunity opp =[SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName = 'PSV';
        opp.Sub_stage__c = 'PSV Sales';
        update opp;
        Profile salesProfile =[SELECT Id FROM Profile WHERE Name='Sales' LIMIT 1];
        User salesUser = new User(Username='reassignneeded@test.com',Alias='reasgn',LastName='User',Email='reassignneeded@test.com',ProfileId=salesProfile.Id,
            TimeZoneSidKey='America/Los_Angeles',LocaleSidKey='en_US',EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US');
        insert salesUser;
        Test.startTest();
        System.runAs(salesUser){
            String result =AHL_LoanApplicationActionController.quickActionSave(opp.Id,'Send_Back','remarks','tester');
        }
        Test.stopTest();
    }
    @isTest
    static void quickActionSave_SendBackToSalesLogin_Test() {
        Opportunity opp =[SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName = 'Credit Underwriting';
        opp.Sub_stage__c = 'Credit in-progress';
        update opp;
        Document_Details__c dd =TestDataFactory.getTestDocumentDetailsData(1,opp.Id,false)[0];
        dd.Name = 'Loan Application Form';
        dd.Active__c = true;
        insert dd;
        OpportunityTeamMember otm =new OpportunityTeamMember(OpportunityId = opp.Id,UserId = UserInfo.getUserId(),TeamMemberRole = 'Sales',
                Associated_With_Loan_Application__c = true,OpportunityAccessLevel = 'Edit');
        insert otm;
        Test.startTest();
        try{
            AHL_LoanApplicationActionController.quickActionSave(opp.Id,'Send_Back','Testing','Tester');
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        Test.stopTest();
        Document_Details__c updatedDoc =[SELECT Active__c FROM Document_Details__c WHERE Id = :dd.Id];
    }
    @isTest
    static void quickActionSave_SalesLoginCommunication_Test() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName = 'Sales login';
        opp.Sub_stage__c = 'Login in-progress';
        update opp;
        Opportunity verifyOpp = [SELECT Id, StageName, Sub_stage__c FROM Opportunity WHERE Id = :opp.Id];
        System.debug('FINAL STAGE=' + verifyOpp.StageName);
        System.debug('FINAL SUBSTAGE=' + verifyOpp.Sub_stage__c);
        Application_Applicant__c applicant = [SELECT Id,Applicant_Type__c,Email__c,Customer_Type__c FROM Application_Applicant__c WHERE Loan_Application__c = :opp.Id LIMIT 1];
        applicant.Applicant_Type__c = 'Primary Applicant';
        applicant.Customer_Type__c = 'Individual';
        applicant.Email__c = 'test@test.com';
        applicant.CIBIL_Score__c =760;
        update applicant;
        Document_Details__c dd =TestDataFactory.getTestDocumentDetailsData(1,opp.Id,false)[0];
        dd.Name = 'Loan Application Form';
        dd.Active__c = true;
        insert dd;
        insert new OpportunityTeamMember(OpportunityId = opp.Id,UserId = UserInfo.getUserId(),TeamMemberRole = 'Sales',Associated_With_Loan_Application__c = true,OpportunityAccessLevel = 'Edit');
        Profile salesProfile =[SELECT Id FROM Profile WHERE Name = 'Sales' LIMIT 1];
        User salesUser = new User(Alias='sales',Email='sales@test.com',EmailEncodingKey='UTF-8',LastName='Sales',LanguageLocaleKey='en_US',
        LocaleSidKey='en_US',ProfileId=salesProfile.Id,TimeZoneSidKey='Asia/Kolkata',UserName='sales'+System.currentTimeMillis()+'@test.com');
        insert salesUser;
        System.runAs(salesUser){
            Test.startTest();
            AHL_LoanApplicationActionController.quickActionSave(opp.Id,'Mark as complete','','');
            Test.stopTest();
        }
        List<Integration_Details__c> comms = [SELECT Id,Endpoint__c,Communication_Status__c FROM Integration_Details__c WHERE Loan_Application__c = :opp.Id AND Endpoint__c = 'Acknowledge of login'];
    }
    @isTest
    static void checkPsvSalesToPsvCreditValidation_TechnicalPending_Test() {
        Opportunity opp =LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        opp.FCU_Status__c = 'Pending';
        opp.Overall_FCU_Verification__c = 'Negative/Not Recommended (NR)';
        insert opp;
        Technical_Evaluation__c tech = new Technical_Evaluation__c(HL_Loan_Application__c = opp.Id,HL_Stage__c = 'In Progress');
        insert tech;
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType='Loan_Transaction__c' AND DeveloperName='Transaction_Details' LIMIT 1];
        insert new Loan_Transaction__c(Loan_Application__c = opp.Id,RecordTypeId = rt.Id,Repayment_Schedule_DateTime__c = null,Latest_Sanction_Generated_DateTime__c = null);
        Test.startTest();
        List<String> result =AHL_LoanApplicationActionController.checkPsvSalesToPsvCreditValidation(opp.Id);
        Test.stopTest();
        System.debug(result);
    }
    @isTest
    static void checkPsvSalesToPsvCreditValidation_LegalPending_Test() {
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        RecordType productRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND Name = 'Product' LIMIT 1];
        insert new Product2(Name = 'Home Loan',Product_Type__c = 'Parent',Loan_Application__c = opp.Id,RecordTypeId = productRt.Id);
        Technical_Evaluation__c tech = new Technical_Evaluation__c(HL_Loan_Application__c = opp.Id,HL_Stage__c = 'In progress');
        insert tech;
        Collateral__c collateral =new Collateral__c(IsActive__c = true,APF__c = 'No');
        insert collateral;
        insert new Application_Collateral__c(HL_Loan_Application__c = opp.Id,Collateral__c = collateral.Id);
        try {
            insert new Legal__c(Loan_Application__c = opp.Id,Stage__c = 'In progress');
        }
        catch(Exception e) {
            System.debug('Ignoring Legal Flow failure: ' + e.getMessage());
        }
        Test.startTest();
        try {
            List<String> result =AHL_LoanApplicationActionController.checkPsvSalesToPsvCreditValidation(opp.Id);
            System.debug('Result = ' + result);
        }
        catch(Exception e) {
            System.debug('Validation method exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    @isTest
    static void checkPsvSalesToPsvCreditValidation_NachMandate_Test() {
        Opportunity opp =LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        Product2 prod = new Product2(Name = 'Home Loan',Product_Type__c = 'Parent',Loan_Application__c = opp.Id);
        insert prod;
        RecordType txnRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Loan_Transaction__c' AND DeveloperName = 'Transaction_Details' LIMIT 1];
        Loan_Transaction__c txn =new Loan_Transaction__c(Loan_Application__c = opp.Id,RecordTypeId = txnRt.Id,Payment_Method__c = 'NACH');
        insert txn;
        Test.startTest();
        List<String> result =AHL_LoanApplicationActionController.checkPsvSalesToPsvCreditValidation(opp.Id);
        Test.stopTest();
        System.assert(result.contains('NACH Payment method is selected hence Mandates record is required.'));
    }
    @isTest
    static void checkPsvSalesToPsvCreditValidation_GST_Test() {
        Opportunity opp =LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        RecordType productRt = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Product' LIMIT 1];
        insert new Product2(Name='Home Loan',Product_Type__c='Parent',Loan_Application__c=opp.Id,RecordTypeId=productRt.Id);
        RecordType chargeRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Charges_Insurance__c' AND Name = 'Charges' LIMIT 1];
        Charges_Insurance__c charge =new Charges_Insurance__c(RecordTypeId = chargeRt.Id,Loan_Application__c = opp.Id,Name = 'PROCFEE',
                Balance_Fees__c = 1000,Final_Amount_INR__c = 1000);
        insert charge;
        RecordType txnRt = [SELECT Id FROM RecordType WHERE SObjectType='Loan_Transaction__c' AND DeveloperName='Transaction_Details' LIMIT 1];
        insert new Loan_Transaction__c(Loan_Application__c = opp.Id,RecordTypeId = txnRt.Id,Repayment_Schedule_DateTime__c = System.now(),Latest_Sanction_Generated_DateTime__c = System.now());
        Test.startTest();
        List<String> result =AHL_LoanApplicationActionController.checkPsvSalesToPsvCreditValidation(opp.Id);
        Test.stopTest();
        System.assert(result.contains('GST is not calculated on one or more of the charge records. Kindly contact the system admin.'));
    }
    @isTest
    static void checkOPSMakerStageValidation_NoSanctionLetter_Test(){
        Opportunity opp =LeadTestDataFactory.createLoanApplicationRecord('New','Affordable Home Loan');
        insert opp;
        RecordType productRt = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Product' LIMIT 1];
        insert new Product2(Name='Affordable Home Loan',Product_Type__c='Parent',Loan_Application__c=opp.Id,RecordTypeId=productRt.Id);
        Test.startTest();
        List<String> result =AHL_LoanApplicationActionController.checkOPSMakerStageValidation(opp.Id,true);
        Test.stopTest();
        System.assert(result.contains('Sanction Letter is not yet generated for the application to move to Disbursement.'));
    }
    @isTest
    static void checkOPSMakerStageValidation_ApplicantValidation_Test(){
        Opportunity opp =LeadTestDataFactory.createLoanApplicationRecord('New','Affordable Home Loan');
        insert opp;
        insert new Application_Applicant__c(Loan_Application__c = opp.Id,First_Name__c = 'Test',Last_Name__c='Applicant');
        List<String> result =AHL_LoanApplicationActionController.checkOPSMakerStageValidation(opp.Id,false);
    }
    @isTest
    static void checkOPSMakerStageValidation_BankIFSC_Test() {
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New','Affordable Home Loan');
        insert opp;
        RecordType productRt = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Product' LIMIT 1];
        insert new Product2(Name='Affordable Home Loan', Product_Type__c='Parent', Loan_Application__c=opp.Id,RecordTypeId=productRt.Id);
        Application_Applicant__c app =new Application_Applicant__c(Loan_Application__c = opp.Id,Applicant_Type__c = 'Primary Applicant',First_Name__c = 'Test',Last_Name__c='Applicant');
        insert app;
        insert new Bank_Details__c(Application_Applicant__c = app.Id,Is_Repayment_Account__c = true,Account_Holder_Name__c ='Test');
        Test.startTest();
        List<String> result =AHL_LoanApplicationActionController.checkOPSMakerStageValidation(opp.Id,false);
        Test.stopTest();
    }
    @isTest
    static void checkOPSMakerStageValidation_OCRMissing_Test() {
        Opportunity opp =LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        opp.Allow_OCR__c = true;
        opp.StageName = 'Disbursement';
        insert opp;
        RecordType productRt = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Product' LIMIT 1];
        insert new Product2(Name='Home Loan', Product_Type__c='Parent',Loan_Application__c=opp.Id,RecordTypeId=productRt.Id);
        Test.startTest();
        List<String> result = AHL_LoanApplicationActionController.checkOPSMakerStageValidation(opp.Id,false);
        Test.stopTest();
    }

    @isTest
    static void checkOPSMakerStageValidation_OCRMissing_Test2() {
        Opportunity opp =LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        opp.Allow_OCR__c = true;
        opp.StageName = 'Disbursement';
        insert opp;
        Covenant_Master__c covMaster = new Covenant_Master__c(
            Name = 'Insurance Covenant',
            category__c = 'Insurance'
        );
        insert covMaster;
        Document_Details__c covenant =TestDataFactory.getTestDocumentDetailsData(1,opp.Id,false)[0];
        covenant.Covenant_Master__c = covMaster.Id;
        covenant.Status__c = 'Pending';
        covenant.Document_Type__c = 'PDD';
        covenant.Active__c = true;
        insert covenant;
        RecordType productRt = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Product' LIMIT 1];
        insert new Product2(Name='Home Loan', Product_Type__c='Parent',Loan_Application__c=opp.Id,RecordTypeId=productRt.Id);
        Test.startTest();
        List<String> result = AHL_LoanApplicationActionController.checkOPSMakerStageValidation(opp.Id,false);
        Test.stopTest();
    }

    @isTest
    static void checkOPSMakerStageValidation_PendingCovenant_Test() {
        Opportunity opp =LeadTestDataFactory.createLoanApplicationRecord('New','Affordable Home Loan');
        insert opp;
        RecordType productRt = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Product' LIMIT 1];
        insert new Product2(Name='Affordable Home Loan',Product_Type__c='Parent',Loan_Application__c=opp.Id,RecordTypeId=productRt.Id);
        Document_Details__c covenant =TestDataFactory.getTestDocumentDetailsData(1,opp.Id,false)[0];
        covenant.Status__c = 'Pending';
        covenant.Document_Type__c = 'PDD';
        covenant.Active__c = true;
        insert covenant;
        Test.startTest();
        List<String> result =AHL_LoanApplicationActionController.checkOPSMakerStageValidation(opp.Id,false);
        Test.stopTest();
    }

    @isTest
    static void checkOPSMakerStageValidation_PendingCovenant_Test2() {
        Opportunity opp =LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        opp.Loan_Hierarchy__c = 'Parent';
        opp.Allow_OCR__c = true;
        opp.StageName ='Disbursement';
        insert opp;

        TestDataFactory.setupTriggerSettings();
        
        City_Master__c city = TestDataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1,city.Id,true)[0];

        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Customer_Address__c custAddRecord = new Customer_Address__c();
        custAddRecord.Customer__c = customer.Id;
        insert custAddRecord;

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = opp.Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        applicant.Applicant_Type__c ='Guarantor';
        applicant.Customer_Profile__c = 'SENP';
        insert applicant;

        Applicant_Address__c appadd=   TestDataFactory.getTestApplicantAddressData(1, applicant.Id, custAddRecord.Id, pinCode.Id, false)[0];
        appadd.Address_Priority__c = '5';
        appadd.Address_Type__c = 'Permanent';
        appadd.Document_Details__c = TestDataFactory.getTestDocumentDetailsData(1, opp.Id, true)[0].Id;
        appadd.Address_Line_1__c ='djjfd';
        insert appadd;

        RecordType productRt = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Product' LIMIT 1];
        insert new Product2(Name='Home Loan',Product_Type__c='Parent',Loan_Application__c=opp.Id,RecordTypeId=productRt.Id);
        Document_Details__c covenant =TestDataFactory.getTestDocumentDetailsData(1,opp.Id,false)[0];
        covenant.Status__c = 'Pending';
        covenant.Name = 'Sanction Letter';
        covenant.Document_Type__c = 'PDD';
        covenant.Active__c = true;
        insert covenant;
        Test.startTest();
        List<String> result =AHL_LoanApplicationActionController.checkOPSMakerStageValidation(opp.Id,true);
        Test.stopTest();
    }
    @isTest
    static void checkOPSMakerStageValidation_PendingCovenant_Test3() {
        Opportunity opp =LeadTestDataFactory.createLoanApplicationRecord('New','Affordable Home Loan');
        opp.Loan_Hierarchy__c = 'Parent';
        opp.Allow_OCR__c = true;
        opp.StageName ='Disbursement';
        insert opp;
        RecordType productRt = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Product' LIMIT 1];
        insert new Product2(Name='Affordable Home Loan',Product_Type__c='Parent',Loan_Application__c=opp.Id,RecordTypeId=productRt.Id);
        Document_Details__c covenant =TestDataFactory.getTestDocumentDetailsData(1,opp.Id,false)[0];
        covenant.Status__c = 'Pending';
        covenant.Name = 'Sanction Letter';
        covenant.Document_Type__c = 'PDD';
        covenant.Active__c = true;
        insert covenant;
        Test.startTest();
        List<String> result =AHL_LoanApplicationActionController.checkOPSMakerStageValidation(opp.Id,true);
        Test.stopTest();
    }

    @isTest
    static void checkOPSMakerStageValidation_PaymentRecordMissing_Test() {
        Opportunity opp =LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        opp.StageName = 'Disbursement';
        opp.Sub_stage__c = 'Ops Maker';
        insert opp;
        RecordType productRt = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Product' LIMIT 1];
        insert new Product2(Name='Home Loan', Product_Type__c='Parent', Loan_Application__c=opp.Id, RecordTypeId=productRt.Id);
        RecordType txnRt = [SELECT Id FROM RecordType WHERE SObjectType='Loan_Transaction__c' AND DeveloperName='Transaction_Details' LIMIT 1];
        insert new Loan_Transaction__c(Loan_Application__c = opp.Id, RecordTypeId = txnRt.Id,Total_Disbursed_Amount__c = 100000);
        Test.startTest();
        List<String> result =AHL_LoanApplicationActionController.checkOPSMakerStageValidation(opp.Id,false);
        Test.stopTest();
    }
    @isTest
    static void checkOPSMakerStageValidation_TechnicalPending_Test() {
        Opportunity opp =LeadTestDataFactory.createLoanApplicationRecord('New','Affordable Home Loan');
        insert opp;
        RecordType productRt = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Product' LIMIT 1];
        insert new Product2(Name='Affordable Home Loan', Product_Type__c='Parent', Loan_Application__c=opp.Id, RecordTypeId=productRt.Id);
        RecordType subProdRt = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Sub Product' LIMIT 1];
        insert new Product2(Name='HL Resale Purchase', Loan_Application__c=opp.Id, RecordTypeId=subProdRt.Id, Sanctioned_Loan_Amount__c=6000000);
        insert new Technical_Evaluation__c(HL_Loan_Application__c = opp.Id, HL_Stage__c = 'In Progress');
        Test.startTest();
        List<String> result =AHL_LoanApplicationActionController.checkOPSMakerStageValidation(opp.Id,false);
        Test.stopTest();
    }
    @isTest
    static void checkOPSMakerStageValidation_SanctionCondition_Test() {
        Opportunity opp =LeadTestDataFactory.createLoanApplicationRecord('New','Affordable Home Loan');
        insert opp;
        insert new Sanction_Condition__c(Loan_Application__c = opp.Id,Condition_Approval__c = 'Pending');
        Test.startTest();
        List<String> result =AHL_LoanApplicationActionController.checkOPSMakerStageValidation(opp.Id,false);
        Test.stopTest();
        System.assert(result.contains('Sanction conditions are pending.'));
    }
    @isTest
    static void checkOPSMakerStageValidation_NACHMandate_Test() {
        Opportunity opp =LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        RecordType productRt = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Product'LIMIT 1];
        insert new Product2(Name='Home Loan',Product_Type__c='Parent',Loan_Application__c=opp.Id,RecordTypeId=productRt.Id);
        RecordType txnRt = [SELECT Id FROM RecordType WHERE SObjectType='Loan_Transaction__c' AND DeveloperName='Transaction_Details' LIMIT 1];
        insert new Loan_Transaction__c(Loan_Application__c = opp.Id,RecordTypeId = txnRt.Id,Payment_Method__c = 'NACH');
        Test.startTest();
        List<String> result =AHL_LoanApplicationActionController.checkOPSMakerStageValidation(opp.Id,false);
        Test.stopTest();
        System.assert(result.contains('NACH Payment method is selected hence Mandates record is required.'));
    }
    @isTest
    static void validateCollateralOwners_NoCollateral_Test() {
        Opportunity opp =LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        Test.startTest();
        String result =AHL_LoanApplicationActionController.validateCollateralOwners(opp.Id);
        Test.stopTest();
        System.assertEquals('', result);
    }
    @isTest
    static void validateCollateralOwners_MissingOwner_Test() {
        Opportunity opp =LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        Collateral__c col = new Collateral__c(APF__c = 'Yes',IsActive__c = true);
        insert col;
        Application_Collateral__c appCol =new Application_Collateral__c(HL_Loan_Application__c = opp.Id,Collateral__c = col.Id);
        try{
            insert appCol;
        }
        catch(Exception ex){
            System.debug(ex.getMessage());
        }
        Test.startTest();
        String result =AHL_LoanApplicationActionController.validateCollateralOwners(opp.Id);
        Test.stopTest();
        System.assert(result.contains('Add Collateral Owner'));
    }
    @isTest
    static void validateCollateralOwners_WithOwner_Test() {
        Opportunity opp =LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        insert opp;
        Collateral__c col = new Collateral__c(APF__c = 'Yes',IsActive__c = true);
        insert col;
        Application_Collateral__c appCol =new Application_Collateral__c(HL_Loan_Application__c = opp.Id,Collateral__c = col.Id);
        try{
            insert appCol;
        }
        catch(Exception ex){
            System.debug(ex.getMessage());
        }
        Collateral_Owner__c owner =new Collateral_Owner__c(Application_Collateral__c = appCol.Id);
        try{
            insert owner;
        }
        catch(Exception ex){
            System.debug(ex.getMessage());
        }
        Test.startTest();
        String result =AHL_LoanApplicationActionController.validateCollateralOwners(opp.Id);
        Test.stopTest();
        System.assertEquals('',result);
    }
    @isTest
    static void revertLoanStatus_Test() {

        Opportunity opp =LeadTestDataFactory.createLoanApplicationRecord('New','Home Loan');
        opp.Sub_stage__c = 'PSV Credit';
        insert opp;
        Test.startTest();
        AHL_LoanApplicationActionController.revertLoanStatus( opp.Id);
        Test.stopTest();
        Opportunity updatedOpp = [SELECT Id,Sub_stage__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Ops Maker',updatedOpp.Sub_stage__c);
    }
    class CalloutMock2 implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        String endpoint = req.getEndpoint();
        Map<String, Object> body = new Map<String, Object>();

        if (endpoint.containsIgnoreCase('CREATE_CUSTOMER')) {
        body.put('cif', 'CIF12345');
        body.put('returnStatus', new Map<String, String>{
        'returnCode' => '000',
        'returnText' => 'Success'
        });
        } else if (endpoint.containsIgnoreCase('UPDATE_CUSTOMER')) {
        body.put('returnText', 'Success');
        body.put('cif', 'CIF12345');
        } else {
        body.put('finReference', 'GHF1001HL0005309');
        body.put('returnStatus', new Map<String, String>{
        'returnCode' => '009',
        'returnText' => 'Success'
        });
        body.put('disbursement', new List<Object>());
        }

        res.setBody(JSON.serialize(body));
        res.setStatusCode(200);
        return res;
        }
    }

    @isTest
    static void initiateAPIRequest_NTBAndETB_Test() {
        TestDataFactory.setupTriggerSettings();
        Opportunity opp = TestDataFactory.getTestOpportunityData(1, false)[0];
        insert opp;
        insert new List<PLF_Master__c>{
        new PLF_Master__c(Name='Gender', Master_Type__c='Gender', Description__c='Male', FICO_Code__c='M', Gender_Code__c='BD'),
        new PLF_Master__c(Name='Nationality', Master_Type__c='Nationality', Description__c='Indian', FICO_Code__c='IN', Gender_Code__c='BD'),
        new PLF_Master__c(Name='Qualification', Master_Type__c='Qualification', Description__c='Male', FICO_Code__c='Q', Gender_Code__c='BD'),
        new PLF_Master__c(Name='Caste', Master_Type__c='Caste', Description__c='Male', FICO_Code__c='C', Gender_Code__c='BD'),
        new PLF_Master__c(Name='Religion', Master_Type__c='Religion', Description__c='Male', FICO_Code__c='R', Gender_Code__c='BD'),
        new PLF_Master__c(Name='Residency Status',Master_Type__c='Residency Status',Description__c='Male', FICO_Code__c='RS', Gender_Code__c='BD'),
        new PLF_Master__c(Name='Sub sector', Master_Type__c='Sub sector', Sector_Code__c='SENP', Description__c='Male', FICO_Code__c='SS', Gender_Code__c='BD'),
        new PLF_Master__c(Name='Address Type', Master_Type__c='Address Type', Description__c='Male', FICO_Code__c='AT', Gender_Code__c='BD'),
        new PLF_Master__c(Name='Salutation', Master_Type__c='Salutation', Description__c='Mr', FICO_Code__c='1', Gender_Code__c='M'),
        new PLF_Master__c(Name='Marital Status', Master_Type__c='Marital Status', Description__c='Single', FICO_Code__c='S'),
        new PLF_Master__c(Name='Customer Type', Master_Type__c='Customer Type', Description__c='SENP', FICO_Code__c='SENP')
        };
        City_Master__c city = TestDataFactory.getTestCityMasterData(1, true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1, city.Id, true)[0];
        Account ntbCustomer = FITestDataFactory.createAccount('NTB Customer','Customer');
        Account etbCustomer = FITestDataFactory.createAccount('ETB Customer','Customer');

        etbCustomer.Exisiting_Customer__c = true;
        etbCustomer.Customer_LMS_Id__c = 'CIF99999';
        update etbCustomer;
        Application_Applicant__c ntbApplicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        ntbApplicant.Gender__c = 'Male';
        ntbApplicant.Mobile_Number__c = '9876543210';
        ntbApplicant.PAN_Number__c = 'ABCPE1234F';
        ntbApplicant.Pan_Name__c = 'Test PAN Name';
        ntbApplicant.DOB__c = Date.newInstance(1990, 1, 1);
        ntbApplicant.DOI__c = Date.newInstance(2010, 1, 1);
        ntbApplicant.Loan_Application__c = opp.Id;
        ntbApplicant.Employment_Type__c = 'SEP';
        ntbApplicant.Customer_Type__c = 'Individual';
        ntbApplicant.First_Name__c = 'NTB';
        ntbApplicant.Last_Name__c = 'User';
        ntbApplicant.Applicant_Type__c = 'Primary Applicant';
        ntbApplicant.Customer_Profile__c = 'SENP';
        ntbApplicant.Customer__c = ntbCustomer.Id;
        insert ntbApplicant;
        Application_Applicant__c verifyApp = [SELECT Id,First_Name__c,Last_Name__c,Customer_Profile__c,Customer_Type__c,Applicant_Type__c
            FROM Application_Applicant__c WHERE Id = :ntbApplicant.Id];

        System.debug('AFTER INSERT APPLICANT=' + verifyApp);
        Application_Applicant__c etbApplicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        etbApplicant.Gender__c = 'Male';
        etbApplicant.Mobile_Number__c = '9876543211';
        etbApplicant.PAN_Number__c = 'ABCPE5678G';
        etbApplicant.Pan_Name__c = 'ETB PAN Name';
        etbApplicant.DOB__c = Date.newInstance(1985, 5, 5);
        etbApplicant.DOI__c = Date.newInstance(2008, 3, 3);
        etbApplicant.Loan_Application__c = opp.Id;
        etbApplicant.Employment_Type__c = 'SEP';
        etbApplicant.Customer_Type__c = 'Individual';
        etbApplicant.First_Name__c = 'ETB';
        etbApplicant.Last_Name__c = 'User';
        etbApplicant.Applicant_Type__c = 'Co Applicant';
        etbApplicant.Customer_Profile__c = 'SENP';
        etbApplicant.Customer__c = etbCustomer.Id;
        insert etbApplicant;
        Application_Applicant__c verifyApp2 = [SELECT Id,First_Name__c,Last_Name__c,Customer_Profile__c,Customer_Type__c,Applicant_Type__c
            FROM Application_Applicant__c WHERE Id = :etbApplicant.Id];

        System.debug('AFTER INSERT APPLICANT=' + verifyApp2);

        Customer_Address__c custAddr1 = new Customer_Address__c(Customer__c = ntbCustomer.Id);
        Customer_Address__c custAddr2 = new Customer_Address__c(Customer__c = etbCustomer.Id);
        insert new List<Customer_Address__c>{ custAddr1, custAddr2 };
        Applicant_Address__c appAddr1 = TestDataFactory.getTestApplicantAddressData(1, ntbApplicant.Id, custAddr1.Id, pincode.Id, false)[0];
        appAddr1.Address_Priority__c = '5';
        appAddr1.Address_Type__c = 'Permanent';
        appAddr1.Address_Line_1__c = 'Line 1 NTB';
        appAddr1.Document_Details__c = TestDataFactory.getTestDocumentDetailsData(1, opp.Id, true)[0].Id;
        insert appAddr1;
        Applicant_Address__c appAddr2 = TestDataFactory.getTestApplicantAddressData(1, etbApplicant.Id, custAddr2.Id, pincode.Id, false)[0];
        appAddr2.Address_Priority__c = '4';
        appAddr2.Address_Type__c = 'Current';
        appAddr2.Address_Line_1__c = 'Line 1 ETB';
        appAddr2.Document_Details__c = TestDataFactory.getTestDocumentDetailsData(1, opp.Id, true)[0].Id;
        insert appAddr2;
        TestDataFactory.setupIntegrationSettings('Stage Change');
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('Create Customer');
        TestDataFactory.setupIntegrationSettings('Update Customer');

        Test.setMock(HttpCalloutMock.class, new CalloutMock2());

        Test.startTest();
        try {
            Map<String, List<String>> result =AHL_LoanApplicationActionController.initiateAPIRequest(opp.Id, false);
            System.assertNotEquals(null, result, 'Result map should not be null');
        } catch (Exception e) {
            System.debug('Test exception: ' + e.getMessage() + ' | ' + e.getStackTraceString());
        }
        Test.stopTest();
    }
    private class CalloutMock_CreateFinance implements HttpCalloutMock {

        String paymentId;

        public CalloutMock_CreateFinance(String paymentId) {
            this.paymentId = paymentId;
        }

        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            res.setBody(
                '{"finReference":"GHF1001HL0005309",' +
                '"financeSchedule":{"summary":{"effectiveRateOfReturn":7.026288585}},' +
                '"disbursement":[{"remarks":"' + paymentId + '","paymentId":6166}],' +
                '"returnStatus":{"returnCode":"0000","returnText":"Success"}}'
            );

            return res;
        }
    }
    @isTest
    static void initiateAPIRequest_NTBAndETB_Test2() {
        TestDataFactory.setupTriggerSettings();
        Opportunity opp = TestDataFactory.getTestOpportunityData(1, false)[0];
        insert opp;
        insert new List<PLF_Master__c>{
        new PLF_Master__c(Name='Gender', Master_Type__c='Gender', Description__c='Male', FICO_Code__c='M', Gender_Code__c='BD'),
        new PLF_Master__c(Name='Nationality', Master_Type__c='Nationality', Description__c='Indian', FICO_Code__c='IN', Gender_Code__c='BD'),
        new PLF_Master__c(Name='Qualification', Master_Type__c='Qualification', Description__c='Male', FICO_Code__c='Q', Gender_Code__c='BD'),
        new PLF_Master__c(Name='Caste', Master_Type__c='Caste', Description__c='Male', FICO_Code__c='C', Gender_Code__c='BD'),
        new PLF_Master__c(Name='Religion', Master_Type__c='Religion', Description__c='Male', FICO_Code__c='R', Gender_Code__c='BD'),
        new PLF_Master__c(Name='Residency Status',Master_Type__c='Residency Status',Description__c='Male', FICO_Code__c='RS', Gender_Code__c='BD'),
        new PLF_Master__c(Name='Sub sector', Master_Type__c='Sub sector', Sector_Code__c='SENP', Description__c='Male', FICO_Code__c='SS', Gender_Code__c='BD'),
        new PLF_Master__c(Name='Address Type', Master_Type__c='Address Type', Description__c='Male', FICO_Code__c='AT', Gender_Code__c='BD'),
        new PLF_Master__c(Name='Salutation', Master_Type__c='Salutation', Description__c='Mr', FICO_Code__c='1', Gender_Code__c='M'),
        new PLF_Master__c(Name='Marital Status', Master_Type__c='Marital Status', Description__c='Single', FICO_Code__c='S'),
        new PLF_Master__c(Name='Customer Type', Master_Type__c='Customer Type', Description__c='SENP', FICO_Code__c='SENP')
        };

        City_Master__c city = TestDataFactory.getTestCityMasterData(1, true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1, city.Id, true)[0];
        Account ntbCustomer = FITestDataFactory.createAccount('NTB Customer','Customer');
        Account etbCustomer = FITestDataFactory.createAccount('ETB Customer','Customer');

        etbCustomer.Exisiting_Customer__c = true;
        etbCustomer.Customer_LMS_Id__c = 'CIF99999';
        update etbCustomer;
        Application_Applicant__c ntbApplicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        ntbApplicant.Gender__c = 'Male';
        ntbApplicant.Mobile_Number__c = '9876543210';
        ntbApplicant.PAN_Number__c = 'ABCPE1234F';
        ntbApplicant.Pan_Name__c = 'Test PAN Name';
        ntbApplicant.DOB__c = Date.newInstance(1990, 1, 1);
        ntbApplicant.DOI__c = Date.newInstance(2010, 1, 1);
        ntbApplicant.Loan_Application__c = opp.Id;
        ntbApplicant.Employment_Type__c = 'SEP';
        ntbApplicant.Customer_Type__c = 'Individual';
        ntbApplicant.First_Name__c = 'NTB';
        ntbApplicant.Last_Name__c = 'User';
        ntbApplicant.Applicant_Type__c = 'Primary Applicant';
        ntbApplicant.Customer_Profile__c = 'SENP';
        ntbApplicant.Customer__c = ntbCustomer.Id;
        insert ntbApplicant;
        Application_Applicant__c verifyApp = [SELECT Id,First_Name__c,Last_Name__c,Customer_Profile__c,Customer_Type__c,Applicant_Type__c
            FROM Application_Applicant__c WHERE Id = :ntbApplicant.Id
        ];

        System.debug('AFTER INSERT APPLICANT=' + verifyApp);
        Application_Applicant__c etbApplicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        etbApplicant.Gender__c = 'Male';
        etbApplicant.Mobile_Number__c = '9876543211';
        etbApplicant.PAN_Number__c = 'ABCPE5678G';
        etbApplicant.Pan_Name__c = 'ETB PAN Name';
        etbApplicant.DOB__c = Date.newInstance(1985, 5, 5);
        etbApplicant.DOI__c = Date.newInstance(2008, 3, 3);
        etbApplicant.Loan_Application__c = opp.Id;
        etbApplicant.Employment_Type__c = 'SEP';
        etbApplicant.Customer_Type__c = 'Individual';
        etbApplicant.First_Name__c = 'ETB';
        etbApplicant.Last_Name__c = 'User';
        etbApplicant.Applicant_Type__c = 'Co Applicant';
        etbApplicant.Customer_Profile__c = 'SENP';
        etbApplicant.Customer__c = etbCustomer.Id;
        insert etbApplicant;
        Application_Applicant__c verifyApp2 = [SELECT Id, First_Name__c, Last_Name__c,Customer_Profile__c,Customer_Type__c,Applicant_Type__c
            FROM Application_Applicant__c WHERE Id = :etbApplicant.Id];

        System.debug('AFTER INSERT APPLICANT=' + verifyApp2);
        Customer_Address__c custAddr1 = new Customer_Address__c(Customer__c = ntbCustomer.Id);
        Customer_Address__c custAddr2 = new Customer_Address__c(Customer__c = etbCustomer.Id);
        insert new List<Customer_Address__c>{ custAddr1, custAddr2 };
        Applicant_Address__c appAddr1 = TestDataFactory.getTestApplicantAddressData(1, ntbApplicant.Id, custAddr1.Id, pincode.Id, false)[0];
        appAddr1.Address_Priority__c = '5';
        appAddr1.Address_Type__c = 'Permanent';
        appAddr1.Address_Line_1__c = 'Line 1 NTB';
        appAddr1.Document_Details__c = TestDataFactory.getTestDocumentDetailsData(1, opp.Id, true)[0].Id;
        insert appAddr1;
        Applicant_Address__c appAddr2 = TestDataFactory.getTestApplicantAddressData(1, etbApplicant.Id, custAddr2.Id, pincode.Id, false)[0];
        appAddr2.Address_Priority__c = '4';
        appAddr2.Address_Type__c = 'Current';
        appAddr2.Address_Line_1__c = 'Line 1 ETB';
        appAddr2.Document_Details__c = TestDataFactory.getTestDocumentDetailsData(1, opp.Id, true)[0].Id;
        insert appAddr2;
        TestDataFactory.setupIntegrationSettings('Stage Change');
        TestDataFactory.setupIntegrationSettings('Get Token');
        TestDataFactory.setupIntegrationSettings('Create Customer');
        TestDataFactory.setupIntegrationSettings('Update Customer');
        TestDataFactory.setupIntegrationSettings('Create Finance AHL');
        Collateral__c col = new Collateral__c(IsActive__c = true, APF__c = 'No');
        insert col;

        Application_Collateral__c appCol = new Application_Collateral__c(HL_Loan_Application__c = opp.Id, Collateral__c = col.Id);
        insert appCol;
        RecordType paymentRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Loan_Transaction__c' AND DeveloperName = 'Payment' LIMIT 1];

        Loan_Transaction__c paymentTxn = new Loan_Transaction__c(Loan_Application__c = opp.Id,RecordTypeId = paymentRt.Id,Disbursement_Party__c = 'Customer',Payment_Sequence__c = 1);
        insert paymentTxn;
        Test.setMock(HttpCalloutMock.class,new CalloutMock_CreateFinance(paymentTxn.Id));
        Test.startTest();
        try {
            Map<String, List<String>> result =AHL_LoanApplicationActionController.initiateAPIRequest(opp.Id, false);
            System.assertNotEquals(null, result, 'Result map should not be null');
        } catch (Exception e) {
            System.debug('Test exception: ' + e.getMessage() + ' | ' + e.getStackTraceString());
        }
        Test.stopTest();
    }
    @isTest
    static void testFetchQDEReasons() {
        Opportunity opp = new Opportunity(Name = 'Test Opp',StageName = 'Prospecting',CloseDate = System.today(),HL_QDE_Reasons__c = 'Reason1;Reason2;Reason3',Product__c='Home Loan');
        insert opp;
        Map<String,String> inputMap = new Map<String,String>();
        inputMap.put('recordId', opp.Id);
        Test.startTest();
        List<AHL_LoanApplicationActionController.QDEReasonWrapper> result = AHL_LoanApplicationActionController.fetchQDEReasons(inputMap);
        Test.stopTest();
        System.assertEquals(3, result.size());
        System.assertEquals(1, result[0].srno);
        System.assertEquals('Reason1', result[0].data);
        System.assertEquals(2, result[1].srno);
        System.assertEquals('Reason2', result[1].data);
        System.assertEquals(3, result[2].srno);
        System.assertEquals('Reason3', result[2].data);
    }
    @isTest
    static void testFetchQDEReasons_NullField() {
        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting',CloseDate = System.today(),Product__c ='Home Loan');
        insert opp;
        Map<String,String> inputMap = new Map<String,String>{'recordId' => opp.Id};
        Test.startTest();
        List<AHL_LoanApplicationActionController.QDEReasonWrapper> result = AHL_LoanApplicationActionController.fetchQDEReasons(inputMap);
        Test.stopTest();
        System.assertEquals(0, result.size());
    }
    @isTest
    static void saveSplitLoans_BranchCoverage_Test() {
        Opportunity parentOpp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        parentOpp.Recredit_Multiproduct__c =true;
        parentOpp.Loan_Hierarchy__c ='Parent';
        update parentOpp;

        Id chargesRtId = [SELECT Id FROM RecordType WHERE SobjectType = 'Charges_Insurance__c' AND Name = 'Charges' LIMIT 1].Id;
        Product2 mainProduct = [SELECT Id,Name,Loan_Application__c FROM Product2 WHERE RecordType.DeveloperName = 'Product' AND Loan_Application__c = :parentOpp.Id LIMIT 1];
        Charges_Insurance__c charge = new Charges_Insurance__c();
        charge.RecordTypeId = chargesRtId;
        charge.Loan_Application__c = parentOpp.Id;
        charge.Product__c = mainProduct.Id;
        charge.Category__c = 'LOS';
        charge.Name = 'PROCFEE';
        insert charge;

        Product2 subProd = [SELECT Id, Name,Product__c,Product__r.Product_Master__r.Name,Sanctioned_Loan_Amount__c,Sanctioned_ROI__c,Sanctioned_Tenor__c,
                Negotiated_Loan_Amount__c,Negotiated_ROI__c,Negotiated_Tenure__c,Final_Loan_Amount__c,Final_ROI__c,Final_Tenure__c
                FROM Product2 WHERE Loan_Application__c = :parentOpp.Id AND RecordType.Name = 'Sub Product' LIMIT 1];

        Opportunity existingChild = new Opportunity(Name = 'Existing Child Loan',StageName = 'PSV',CloseDate = Date.today(),
            Split_Parent_Loan_Application__c = parentOpp.Id,Loan_Hierarchy__c ='Child',Product__c ='Home Loan');
        insert existingChild;
        OpportunityTeamMember otm = new OpportunityTeamMember();
        otm.OpportunityId = parentOpp.Id;
        otm.UserId = UserInfo.getUserId();
        otm.TeamMemberRole = 'Sales';
        otm.Associated_With_Loan_Application__c = true;
        insert otm;

        Account acc = new Account(Name = 'Branch Account');
        insert acc;
        AccountTeamMember atm = new AccountTeamMember(AccountId = acc.Id,UserId = UserInfo.getUserId(),TeamMemberRole = 'Sales');
        insert atm;
        parentOpp.Branch_Master__c = acc.Id;
        parentOpp.Sub_Branch__c = acc.Id;
        update parentOpp;

        Id txnRtId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByName().get('Transaction Details').getRecordTypeId();
        Loan_Transaction__c parentTxn =new Loan_Transaction__c();
        parentTxn.RecordTypeId = txnRtId;
        parentTxn.Loan_Application__c = parentOpp.Id;
        insert parentTxn;
        subProd.PLR_Code__c = 'PLR001';
        update subProd;
        Product2 parentProduct = [SELECT Id,Name FROM Product2 WHERE Loan_Application__c = :parentOpp.Id AND RecordType.Name = 'Product' LIMIT 1];
        Product2 variant;
        Product2 subVariant;
        Product2 hybrid;
        Product2 scheme;
        Product2 fullEmi;
        Product2 totalTenure;
        Product2 loanPurpose;
        Product2 propertyType;
        Product2 transactionType;
        try {
            variant = [SELECT Id FROM Product2 WHERE Loan_Application__c = :parentOpp.Id AND RecordType.Name = 'Variant' LIMIT 1];
            subVariant = [SELECT Id, Variant__c FROM Product2 WHERE Loan_Application__c = :parentOpp.Id AND RecordType.Name = 'Sub Variant' LIMIT 1];
            hybrid = [SELECT Id FROM Product2 WHERE Loan_Application__c = :parentOpp.Id AND RecordType.Name = 'Hybrid Tenure' LIMIT 1];
            scheme = [SELECT Id FROM Product2 WHERE Loan_Application__c = :parentOpp.Id AND RecordType.Name = 'Scheme' LIMIT 1];
            fullEmi = [SELECT Id FROM Product2 WHERE Loan_Application__c = :parentOpp.Id AND RecordType.Name = 'Full EMI' LIMIT 1];
            totalTenure = [SELECT Id FROM Product2 WHERE Loan_Application__c = :parentOpp.Id AND RecordType.Name = 'Total Tenure' LIMIT 1];
            loanPurpose = [SELECT Id FROM Product2 WHERE Loan_Application__c = :parentOpp.Id AND RecordType.Name = 'Loan Purpose' LIMIT 1];
            propertyType = [SELECT Id FROM Product2 WHERE Loan_Application__c = :parentOpp.Id AND RecordType.Name = 'Property Type' LIMIT 1];
            transactionType = [SELECT Id FROM Product2 WHERE Loan_Application__c = :parentOpp.Id AND RecordType.Name = 'Transaction Type' LIMIT 1];

        } catch(Exception ex) {
            System.debug(ex.getMessage());
        }
        ContentVersion cv = new ContentVersion(Title = 'Loan Approval Comments',PathOnClient = 'LoanApproval.txt',VersionData = Blob.valueOf('Test File'));
        insert cv;
        cv = [SELECT Id,ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        Document_Details__c doc =new Document_Details__c();
        doc.Name = 'Loan Approval Comments';
        doc.Loan_Application__c = parentOpp.Id;
        doc.Product__c = parentProduct.Id;
        doc.Content_Document_Id__c = cv.ContentDocumentId;

        insert doc;
        Test.startTest();
        List<String> result =AHL_LoanApplicationActionController.saveSplitLoans(parentOpp.Id);
        Test.stopTest();
        System.assertNotEquals(null,result);
    }
    @isTest
    static void saveSplitLoans_ProductCloneAndDocBranch_Test() {
        Opportunity parentOpp = [SELECT Id, Name, AccountId, CloseDate, RecordTypeId, OwnerId FROM Opportunity LIMIT 1];
        parentOpp.Recredit_Multiproduct__c = true;
        parentOpp.Loan_Hierarchy__c = 'Parent';
        update parentOpp;
        Product2 childTypeProduct = [SELECT Id, Name, Product_Master__c, Product_Master__r.Name FROM Product2 WHERE Loan_Application__c = :parentOpp.Id AND RecordType.DeveloperName = 'Product' AND Product_Type__c = 'Child' LIMIT 1];
        List<Product2> allSubProducts = [SELECT Id, Product__r.Product_Master__r.Name FROM Product2 WHERE Loan_Application__c = :parentOpp.Id AND RecordType.Name = 'Sub Product'];
        Id chargesRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Charges_Insurance__c' AND Name = 'Charges' LIMIT 1].Id;
        List<Charges_Insurance__c> chargesList = new List<Charges_Insurance__c>();
        for (Product2 sp : allSubProducts) {
        chargesList.add(new Charges_Insurance__c(RecordTypeId = chargesRtId,Loan_Application__c = parentOpp.Id, Product__c = sp.Id, Category__c = 'LOS', Name = 'PROCFEE'));
        }
        insert chargesList;
        Id txnRtId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByName().get('Transaction Details').getRecordTypeId();
        Loan_Transaction__c parentTxn = new Loan_Transaction__c(
        RecordTypeId = txnRtId,
        Loan_Application__c = parentOpp.Id
        );
        insert parentTxn;
        Account branchAcc = new Account(Name = 'Test Branch');
        insert branchAcc;
        parentOpp.Branch_Master__c = branchAcc.Id;
        update parentOpp;
        OpportunityTeamMember otm = new OpportunityTeamMember(
        OpportunityId = parentOpp.Id,
        UserId = UserInfo.getUserId(),
        TeamMemberRole = 'Sales',
        Associated_With_Loan_Application__c = true
        );
        insert otm;
        AccountTeamMember atm = new AccountTeamMember(
        AccountId = branchAcc.Id,
        UserId = UserInfo.getUserId(),
        TeamMemberRole = 'Sales'
        );
        insert atm;
        ContentVersion cv = new ContentVersion(
        Title = 'Loan Approval Comments',
        PathOnClient = 'LoanApproval.pdf',
        VersionData = Blob.valueOf('Test content'),
        IsMajorVersion = true
        );
        insert cv;
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        Document_Details__c doc = new Document_Details__c(
        Name = 'Loan Approval Comments',
        Loan_Application__c = parentOpp.Id,
        Product__c = childTypeProduct.Id,
        Content_Document_Id__c = cv.ContentDocumentId
        );
        insert doc;
        Opportunity existingChildOpp = parentOpp.clone(false, false, false, false);
        existingChildOpp.Name = 'Existing Child';
        existingChildOpp.StageName = 'PSV';
        existingChildOpp.Loan_Hierarchy__c = 'Child';
        existingChildOpp.Split_Parent_Loan_Application__c = parentOpp.Id;
        existingChildOpp.Product__c = 'Flexi Loan'; // prodM2.Name
        existingChildOpp.Recredit_Multiproduct__c = false;
        insert existingChildOpp;
        Test.startTest();
        List<String> result =
        AHL_LoanApplicationActionController.saveSplitLoans(parentOpp.Id);
        AHL_LoanApplicationActionController.updateFCUInitiationDate(parentOpp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.debug('saveSplitLoans result: ' + result);
    }

}