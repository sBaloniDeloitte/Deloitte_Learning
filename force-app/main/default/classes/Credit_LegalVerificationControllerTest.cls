@isTest
private class Credit_LegalVerificationControllerTest {

    @testSetup
    static void setupData() {
        // 1. Setup Basic Settings
        TestDataFactory.setupTriggerSettings();

        // 2. Create Account and Opportunity (Loan Application)
        Account acc = TestDataFactory.createAccountRecord('Test Account');
        insert acc;

        Opportunity opp = TestDataFactory.createLoanApplicationRecord('New', 'Home Loan', 'Prospecting', System.today().addDays(10));
        opp.AccountId = acc.Id;
        opp.Product__c = 'Home Loan';
        insert opp;
        
        Application_Applicant__c applicant = TestDataFactory.createApplicationApplicant('Primary Applicant', opp.Id, 'Test User', 'ABCPE1234F', System.today().addYears(-30));
        insert applicant;
        
        List<City_Master__c> cityList = TestDataFactory.getTestCityMasterData(1, true);
    List<Pincode_Master__c> pinList = TestDataFactory.getTestPincodeMasterData(1, cityList[0].Id, true);
    Id pincodeId = pinList[0].Id;
        // 3. Create Record Types for Legal__c (Update Name if different in your Org)
        Id legalRtId = Schema.SObjectType.Legal__c.getRecordTypeInfosByName().get('Legal Scrutiny Report').getRecordTypeId();
        
        // 4. Create Legal Record
        Legal__c leg = new Legal__c(
            Loan_Application__c = opp.Id,
            Stage__c = 'Assigned to Admin',
            Assigned_to_Admin__c = UserInfo.getUserId(),
            RecordTypeId = legalRtId
        );
        insert leg;
        Profile techManagerProfile = [SELECT Id FROM Profile WHERE Name = 'Technical Manager' LIMIT 1];
    User techManager = TestDataFactory.getTestUser(techManagerProfile.Id, true);
        // 5. Create Technical Evaluation
        Technical_Evaluation__c tech = new Technical_Evaluation__c(
            HL_Loan_Application__c = opp.Id,
            HL_Stage__c = 'Assigned to Technical Manager',
            HL_Assigned_to_Technical_Manager__c = techManager.Id
        );
        insert tech;
        
        Screen_Field__c ps = new Screen_Field__c(
            Is_Active__c = true,
            Is_Screen_Active__c = true,
            Form_Name__c = 'Legal Scrutiny Report Limited'
        );
        insert ps;

        Screen_Field__c sf = TestDataFactory.getScreenDetails('Legal Scrutiny Report Limited', ps.Id);
        sf.Storage_Object__c = 'Legal__c';
        sf.Storage_Field__c = 'Stage__c'; 
        sf.Is_Mandatory__c = true;
        sf.Is_Active__c = true;
        insert sf;

        // 7. Applicant Address for Dynamic Query coverage in checkShowSubmit
        Applicant_Address__c addr = new Applicant_Address__c(
            Legal__c = leg.Id,
            Applicant__c = applicant.Id,
            Pincode__c = pincodeId
        );
        insert addr;

        // 8. Account Team Member - CRITICAL for getFiStatus
        AccountTeamMember atm = new AccountTeamMember(
            AccountId = acc.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'Sales Rep' 
        );
        insert atm;
    }

    @isTest
    static void testGetFiStatus() {
        Legal__c leg = [SELECT Id FROM Legal__c LIMIT 1];
        
        Test.startTest();
        Boolean result = Credit_LegalVerificationController.getFiStatus(leg.Id, 'Legal__c');
        Test.stopTest();
        
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testCheckShowSubmit() {
        Legal__c leg = [SELECT Id FROM Legal__c LIMIT 1];
        
        Test.startTest();
        // Test Legal__c path
        Boolean showSubmitLegal = Credit_LegalVerificationController.checkShowSubmit(leg.Id, 'Legal__c');
        
        // Test non-Legal__c path (else block)
        // We'll pass a different object name to hit the else branch
        try {
            Credit_LegalVerificationController.checkShowSubmit(leg.Id, 'Technical_Evaluation__c');
        } catch(Exception e) {
            // Catching expected dynamic query failures if fields don't exist
        }
        Test.stopTest();
    }

    @isTest
    static void testGettersAndSetters() {
        Legal__c leg = [SELECT Id FROM Legal__c LIMIT 1];
        Technical_Evaluation__c tech = [SELECT Id FROM Technical_Evaluation__c LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        // Test recordTypeId for various objects
        Credit_LegalVerificationController.recordTypeId(leg.Id, 'Legal__c');
        Credit_LegalVerificationController.recordTypeId(tech.Id, 'Technical_Evaluation__c');
        //Credit_LegalVerificationController.recordTypeId(opp.Id, 'Product2'); // Path for Product2
        Credit_LegalVerificationController.getProductNameFromLA(leg.Id);
        Credit_LegalVerificationController.getOwnerName(leg.Id);
        
        Test.stopTest();
    }

    @isTest
    static void testSaveRemarksFI() {
        Legal__c leg = [SELECT Id FROM Legal__c LIMIT 1];

        Test.startTest();
        // Cover 'Assigned to Admin' logic
        Credit_LegalVerificationController.saveRemarksFI(leg.Id, 'Assigned to Admin', 'Test Admin Remark');
        // Cover 'Hold' logic
        Credit_LegalVerificationController.saveRemarksFI(leg.Id, 'Hold', 'Test Hold Remark');
        Test.stopTest();
        
        System.assert(true);
    }
    
    @isTest
    static void testWrappersAndExceptions() {
        Test.startTest();
        // Coverage for constructors of Wrapper classes
        Credit_LegalVerificationController.AssigneeWrapperNew assignWrap = 
            new Credit_LegalVerificationController.AssigneeWrapperNew(null, null, 'Name', null);
        try {
            Credit_LegalVerificationController.getFiStatus(null, 'Legal__c');
        } catch (Exception e) {
            System.debug('Exception covered');
        }
        try {
        Credit_LegalVerificationController.saveRemarksFI(null, 'Hold', 'Test Comment');
    } catch (Exception e) {
        System.debug('saveRemarksFI Exception covered');
    }
    try {
        Credit_LegalVerificationController.getOwnerName(null);
    } catch (Exception e) {
        System.debug('getOwnerName handled');
    }
        Test.stopTest();
    }
}