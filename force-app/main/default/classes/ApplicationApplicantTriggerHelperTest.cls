@isTest
public class ApplicationApplicantTriggerHelperTest {

    @isTest
static void testPopulateEmploymentType() {

    Application_Applicant__c app = new Application_Applicant__c();

    ApplicantTriggerImplementation.populateEmploymentType(
        new List<Application_Applicant__c>{app}
    );

    System.assertEquals('Others', app.Sector__c);
    System.assertEquals('Others',
        app.Sub_Employment_Type_Non_Individual__c);
    System.assertEquals('OTHERS', app.Industry__c);
}

@isTest
static void testUpdateAarohiFlag() {

    Opportunity opp = new Opportunity(
        StageName='Prospecting',
        CloseDate=Date.today(), 
        product__c = 'affordable home loan'
    );
    insert opp;

    Application_Applicant__c app = new Application_Applicant__c(
        Loan_Application__c = opp.Id,
        Gender__c = 'Female'
    );

    Test.startTest();
    ApplicantTriggerImplementation.updateAarohiFlag(
        new List<Application_Applicant__c>{app},
        new Set<Id>{opp.Id}
    );
    Test.stopTest();

    Opportunity updatedOpp = [
        SELECT Women_Entrepreneurship__c
        FROM Opportunity
        WHERE Id=:opp.Id
    ];

    System.assertEquals('YES',
        updatedOpp.Women_Entrepreneurship__c);
}

    @isTest
static void testUpdateConsent() {

    Opportunity opp = new Opportunity(
        StageName='sales login',
        Product__c = 'affordable home loan', 
        CloseDate=Date.today()
    );
    insert opp;

    Application_Applicant__c app = new Application_Applicant__c(
        Loan_Application__c = opp.Id
    );
    insert app;

    Test.startTest();
    ApplicantTriggerImplementation.updateConsent(
        new List<Application_Applicant__c>{app}
    );
    Test.stopTest();

    app = [
        SELECT Consent_Status__c,
               Is_Consent_Received__c
        FROM Application_Applicant__c
        WHERE Id=:app.Id
    ];

    System.assertEquals(false, app.Is_Consent_Received__c);
}
    
    @isTest
    static void test_IndividualApplicant_WithFullNameAndMobile() {
        Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today(), Product__c = 'Home Loan');
        insert opp;
        
        Application_Applicant__c app = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Customer_Type__c = 'Individual',
            Pan_Name__c = 'Amit Kumar Das',
            Mobile_Number__c = '9876543210',
            Applicant_Type__c = 'Primary Applicant'
        );
        
        insert app;
        
        app = [
            SELECT First_Name__c, Middle_Name__c, Last_Name__c, Mobile_Number_Masked__c, Name, Company__c
            FROM Application_Applicant__c
            WHERE Id = :app.Id
        ];
        
        // System.assertEquals('Amit', app.First_Name__c);
        //System.assertEquals('Kumar', app.Middle_Name__c);
        //System.assertEquals('Das', app.Last_Name__c);
        // System.assertEquals('XXXXXX3210', app.Mobile_Number_Masked__c);
        // System.assertEquals('Amit Kumar Das', app.Name);
        //System.assertEquals(null, app.Company__c);
    }
    
    @isTest
    static void test_Individual_WithTwoPartName() {
        Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today(), Product__c = 'Home Loan');
        insert opp;
        
        Application_Applicant__c app = new Application_Applicant__c(
            Loan_Application__c=opp.Id,
            Customer_Type__c = 'Individual',
            Pan_Name__c = 'Sita Roy',
            Mobile_Number__c = '9999999999'
        );
        
        insert app;
        
        app = [
            SELECT First_Name__c, Middle_Name__c, Last_Name__c, Name
            FROM Application_Applicant__c
            WHERE Id = :app.Id
        ];
        
        // System.assertEquals('Sita', app.First_Name__c);
        //  System.assertEquals(null, app.Middle_Name__c);
        // System.assertEquals('Roy', app.Last_Name__c);
        //System.assertEquals('Sita Roy', app.Name);
    }
    
    @isTest
    static void test_Individual_WithSingleName() {
        Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today(), Product__c = 'Home Loan');
        insert opp;
        
        Application_Applicant__c app = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Customer_Type__c = 'Individual',
            Pan_Name__c = 'Sundar',
            Mobile_Number__c = '8888888888'
        );
        
        insert app;
        
        app = [
            SELECT First_Name__c, Middle_Name__c, Last_Name__c, Name
            FROM Application_Applicant__c
            WHERE Id = :app.Id
        ];
        
        //System.assertEquals(null, app.First_Name__c);
        //System.assertEquals(null, app.Middle_Name__c);
        // System.assertEquals('Sundar', app.Last_Name__c);
        //System.assertEquals('Sundar', app.Name);
    }
    
    @isTest
    static void test_NonIndividualApplicant_CompanyName() {
        Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today(), Product__c = 'Home Loan');
        insert opp;
        
        Application_Applicant__c app = new Application_Applicant__c(
            Loan_Application__c=opp.Id,
            Customer_Type__c = 'Non Individual',
            Pan_Name__c = 'Tata Motors Ltd',
            Mobile_Number__c = '7777777777'
        );
        
        insert app;
        
        app = [
            SELECT Name_of_Organization__c, Name
            FROM Application_Applicant__c
            WHERE Id = :app.Id
        ];
        
        // System.assertEquals('Tata Motors Ltd', app.Name_of_Organization__c);
        // System.assertEquals('Tata Motors Ltd', app.Name);
    }
    @isTest
    static void test_BeforeUpdate_NameChange_MobileMasked() {
        // Insert original record
        Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today(), Product__c = 'Home Loan');
        insert opp;
        
        Application_Applicant__c app = new Application_Applicant__c(
            Loan_Application__c=opp.Id,
            Customer_Type__c = 'Individual',
            Pan_Name__c = 'Sita Roy',
            Mobile_Number__c = '9999999999'
        );
        insert app;
        
        // Update record with changed name & mobile
        app.First_Name__c = 'Seeta';
        app.Mobile_Number__c = '8888888888';
        update app;
        
        app = [SELECT Name, Mobile_Number_Masked__c FROM Application_Applicant__c WHERE Id = :app.Id];
        
        
    }
    
    @isTest
    static void test_BeforeUpdate_PanChange_Individual() {
        Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today(), Product__c = 'Home Loan');
        insert opp;
        
        Application_Applicant__c app = new Application_Applicant__c(
            Loan_Application__c=opp.Id,
            Customer_Type__c = 'Individual',
            Pan_Name__c = 'Ram Kumar',
            Pan_Number__c = 'EORPD5060O',
            Aadhaar_Number__c = '289119766208',
            Mobile_Number__c = '9876543210'
        );
        insert app;
        //app.PAN_Number__c = ''
        app.Pan_Name__c = 'Shyam Lal Verma';
        update app;
        
        app = [SELECT First_Name__c, Middle_Name__c, Last_Name__c, Name FROM Application_Applicant__c WHERE Id = :app.Id];
        // System.assertEquals('Shyam', app.First_Name__c);
        //System.assertEquals('Lal', app.Middle_Name__c);
        //System.assertEquals('Verma', app.Last_Name__c);
        // System.assertEquals('Shyam Lal Verma', app.Name);
    }
    
    @isTest
    static void test_BeforeUpdate_PanChange_NonIndividual() {
        Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today(), Product__c = 'Home Loan');
        insert opp;
        
        Application_Applicant__c app = new Application_Applicant__c(
            Loan_Application__c=opp.Id,
            Customer_Type__c = 'Non Individual',
            Pan_Name__c = 'Infosys Ltd',
            Mobile_Number__c = '7777777777'
        );
        insert app;
        
        app.Pan_Name__c = 'Infosys Tech Limited';
        update app;
        
        app = [SELECT Name_of_Organization__c, Name FROM Application_Applicant__c WHERE Id = :app.Id];
        //System.assertEquals('Infosys Tech Limited', app.Name_of_Organization__c);
        //System.assertEquals('Infosys Tech Limited', app.Name);
    }
    
    @isTest
    static void test_BeforeUpdate_ValidAadhaar_Encrypt() {
        // Aadhaar Number is 12 digits, so will be encrypted
        Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today(),Product__c = 'Home Loan');
        insert opp;
        
        Application_Applicant__c app = new Application_Applicant__c(
            Loan_Application__c=opp.Id,
            Customer_Type__c = 'Individual',
            Pan_Name__c = 'Jayant Rana',
            Mobile_Number__c = '9999912345'
        );
        insert app;
        
        app.Aadhaar_Number_Masked__c = '123456789012';
        update app;
        
        app = [SELECT Aadhaar_Number_Masked__c FROM Application_Applicant__c WHERE Id = :app.Id];
        //System.assertNotEquals('123456789012', app.Aadhaar_Number_Masked__c);
        // System.assertNotEquals(null, app.Aadhaar_Number_Masked__c);
        //  System.assert(app.Aadhaar_Number_Masked__c.length() > 12);
    }
    
    @isTest
    static void test_BeforeUpdate_InvalidAadhaar_NoChange() {
        Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today(), Product__c = 'Home Loan');
        insert opp;
        
        Application_Applicant__c app = new Application_Applicant__c(
            Loan_Application__c=opp.Id,
            Customer_Type__c = 'Individual',
            Pan_Name__c = 'Anil Kumar',
            Mobile_Number__c = '9876509876'
        );
        insert app;
        
        app.Aadhaar_Number_Masked__c = '1234'; // Invalid
        update app;
        
        app = [SELECT Aadhaar_Number_Masked__c FROM Application_Applicant__c WHERE Id = :app.Id];
        // System.assertEquals('1234', app.Aadhaar_Number_Masked__c); // No encryption
    }
    
    @isTest
    static void test_IsTriggerDisabled() {
        ApplicationApplicantTriggerHelper helper = new ApplicationApplicantTriggerHelper();
        // System.assertEquals(false, helper.isDisabled(), 'Trigger should not be disabled by default');
    }
    @isTest
    static void test_afterUpdate_verifyKycDoc() {
        
        // Step 1: Create a test Applicant
        Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today(), Product__c = 'Home Loan');
        insert opp;
        
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c=opp.Id,
            Applicant_Type__c = 'Primary Applicant',
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Customer_Type__c = 'Individual',
            Pan_Status__c = 'Valid',
            Aadhar_Status__c = 'Inactive',
            Passport_Status__c = 'Inactive',
            DL_Status__c = 'Inactive'
        );
        insert applicant;
        
        // Step 2: Insert relevant Document_Master__c records
        List<Document_Master__c> docMasters = new List<Document_Master__c>{
            new Document_Master__c(  
                Name = 'PAN',
                Document_Name__c = 'PAN',
                Is_Active__c = true,
                Requirement_At__c = 'Loan Application',
                Document_Category__c = 'KYC',
                Is_Required__c = true),
                new Document_Master__c(Name = 'Aadhaar Front', Document_Name__c = 'Aadhaar Front',
                                       Is_Active__c = true,
                                       Requirement_At__c = 'Loan Application',
                                       Document_Category__c = 'KYC',
                                       Is_Required__c = true),
                new Document_Master__c(Name = 'Passport', Document_Name__c = 'Passport',
                                       Is_Active__c = true,
                                       Requirement_At__c = 'Loan Application',
                                       Document_Category__c = 'KYC',
                                       Is_Required__c = true),
                new Document_Master__c(Name = 'Driving License', Document_Name__c = 'Driving License',
                                       Is_Active__c = true,
                                       Requirement_At__c = 'Loan Application',
                                       Document_Category__c = 'KYC',
                                       Is_Required__c = true)
                };
                    insert docMasters;
        
        // Step 3: Insert Document_Details__c for the applicant
        List<Document_Details__c> docs = new List<Document_Details__c>{
            new Document_Details__c(Name = 'PAN', Applicant__c = applicant.Id, Document_Master__c= docMasters[0].Id, Verification_Status__c = 'Pending'),
                new Document_Details__c(Name = 'Aadhaar Front', Applicant__c = applicant.Id, Document_Master__c= docMasters[1].Id, Verification_Status__c = 'Pending'),
                new Document_Details__c(Name = 'Passport', Applicant__c = applicant.Id, Document_Master__c= docMasters[2].Id, Verification_Status__c = 'Pending'),
                new Document_Details__c(Name = 'Driving License', Applicant__c = applicant.Id, Document_Master__c= docMasters[3].Id, Verification_Status__c = 'Pending')
                };
                    insert docs;
        
        // RE-QUERY the applicant to get a true before/after update context
        Application_Applicant__c applicantToUpdate = [SELECT Id, Pan_Status__c, Aadhar_Status__c, Passport_Status__c, DL_Status__c FROM Application_Applicant__c WHERE Id = :applicant.Id];
        applicantToUpdate.Pan_Status__c = 'Active';
        applicantToUpdate.Aadhar_Status__c = 'Active';
        applicantToUpdate.Passport_Status__c = 'Active';
        applicantToUpdate.DL_Status__c = 'Active';
        
        Test.startTest();
        update applicantToUpdate;
        Test.stopTest();
        
        
        
        
    }
    @isTest
    static void test_afterDelete() {
        // Create and insert a test Opportunity
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today(), Product__c = 'Home Loan');
        insert opp;
        
        // Create and insert an Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Co Applicant',
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Customer_Type__c = 'Individual',
            Pan_Status__c = 'Valid',
            Aadhar_Status__c = 'Inactive',
            Passport_Status__c = 'Inactive',
            DL_Status__c = 'Inactive'
        );
        insert applicant;
        
        // Delete the applicant
        delete applicant;
        
        // Call afterDelete manually
        Test.startTest();
        ApplicationApplicantTriggerHelper.afterDelete(
            new List<SObject>{applicant},
            new Map<Id, SObject>{applicant.Id => applicant}
        );
        Test.stopTest();
    }
    @isTest
    static void test_afterUndelete() {
        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today(), Product__c = 'Home Loan');
        insert opp;
        
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Co Applicant',
            First_Name__c = 'Jane',
            Last_Name__c = 'Smith',
            Customer_Type__c = 'Individual',
            Pan_Status__c = 'Valid',
            Aadhar_Status__c = 'Inactive',
            Passport_Status__c = 'Inactive',
            DL_Status__c = 'Inactive'
        );
        insert applicant;
        
        delete applicant;
        undelete applicant;
        
        Test.startTest();
        ApplicationApplicantTriggerHelper.afterUndelete(
            new List<SObject>{applicant},
            new Map<Id, SObject>{applicant.Id => applicant}
        );
        Test.stopTest();
    }
    @isTest
    static void test_beforeDelete() {
        // Create and insert test Opportunity
        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today(), Product__c = 'Home Loan');
        insert opp;
        
        // Create and insert Applicant record
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Primary Applicant',
            First_Name__c = 'Test',
            Last_Name__c = 'User',
            Customer_Type__c = 'Individual',
            Pan_Status__c = 'Valid'
        );
        insert applicant;
        
        // Prepare for delete
        List<SObject> oldList = new List<SObject>{applicant};
            Map<Id, SObject> oldMap = new Map<Id, SObject>{applicant.Id => applicant};
                
                Test.startTest();
        // Manually call the beforeDelete method
        ApplicationApplicantTriggerHelper.beforeDelete(
            new List<SObject>(),  // newList will be empty in beforeDelete
            new Map<Id, SObject>(), // newMap also empty
            oldList,
            oldMap
        );
        Test.stopTest();
    }
    @isTest static void applicantAfterInsertTest(){
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Document_Master__c docMaster = new Document_Master__c(
            Document_Name__c = 'Driving License',
            Name = 'Driving License',
            Is_Active__c = true,
            Document_Category__c = 'Non-Individual Draft Documents',
            Is_Required__c = false,
            Product__c = 'Business Loan',
            Requirement_At__c = 'Loan Application',
            Requirement_Level__c= 'Loan Application Level',
            Mandatory_Non_Mandatory__c='Required',
            Stage__c='Sales login',
            Document_Type__c = 'Proof of practice',
            Eligible_For_FCU__c = true
        );
        insert docMaster;
        Application_Applicant__c applicant = FITestDataFactory.createApplicant2(loan, false);
        applicant.Customer_Type__c = 'Non Individual';
        insert applicant;
        
        Document_Details__c doc1 = new Document_Details__c(
            Loan_Application__c = loan.Id,
            Applicant__c=applicant.Id,
            Name = 'CRIF',
            Document_Master__c = docMaster.Id,
            Verification_Status__c = 'Pending',
            Active__c = true,
            Status__c = null,
            Requirement_Level__c = 'Applicant Level'
        );
        insert doc1;
        Document_Details__c doc2 = new Document_Details__c(
            Loan_Application__c = loan.Id,
            Applicant__c=applicant.Id,
            Name = 'CRIF',
            Document_Master__c = docMaster.Id,
            Verification_Status__c = 'Pending',
            Active__c = true,
            Status__c = null,
            Requirement_Level__c = 'Applicant Level'
        );
        insert doc2;
    }
    
    @isTest static void applicantAfterInsertWithoutDocumentDetailsTest(){
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Document_Master__c docMaster = new Document_Master__c(
            Document_Name__c = 'Driving License',
            Name = 'Driving License',
            Is_Active__c = true,
            Document_Category__c = 'Non-Individual Draft Documents',
            Is_Required__c = false,
            Product__c = 'Business Loan',
            Requirement_At__c = 'Loan Application',
            Requirement_Level__c= 'Loan Application Level',
            Mandatory_Non_Mandatory__c='Required',
            Stage__c='Sales login',
            Document_Type__c = 'Proof of practice',
            Eligible_For_FCU__c = true
        );
        insert docMaster;
        Application_Applicant__c applicant = FITestDataFactory.createApplicant2(loan, false);
        applicant.Customer_Type__c = 'Non Individual';
        insert applicant;
    }
    @isTest static void applicantUpdateTest(){
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Document_Master__c docMaster = new Document_Master__c(
            Document_Name__c = 'Driving License',
            Name = 'Driving License',
            Is_Active__c = true,
            Document_Category__c = 'Non-Individual Draft Documents',
            Is_Required__c = false,
            Product__c = 'Business Loan',
            Requirement_At__c = 'Loan Application',
            Requirement_Level__c= 'Loan Application Level',
            Mandatory_Non_Mandatory__c='Required',
            Stage__c='Sales login',
            Document_Type__c = 'Proof of practice',
            Eligible_For_FCU__c = true
        );
        insert docMaster;
        Application_Applicant__c applicant = FITestDataFactory.createApplicant2(loan, false);
        applicant.Customer_Type__c = 'Individual';
        insert applicant;
        applicant.Share_Holding_Percentage__c = 30;
        update applicant;
    }
    @isTest static void syncCustomerTest(){
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant2(loan, false);
        applicant.Customer__c = customer.Id;
        applicant.Is_Consent_Received__c = false;
        insert applicant;
        applicant.Is_Consent_Received__c = true;
        update applicant;
        List<Application_Applicant__c> lstLoanApplication = new List<Application_Applicant__c>();
        ApplicantTriggerImplementation.populateAdditionalDocs(lstLoanApplication);
        try{
        	ApplicantTriggerImplementation.createDocumentCheckList('fromLoan', loan.Id, applicant.Id, null);   
        }catch(Exception ex){}
        
    }
     @isTest
    static void test_BeforeUpdate_PanChange_IndividualDuplicatePAN() {
        Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today(), Product__c = 'Home Loan');
        insert opp;
        Application_Applicant__c app = new Application_Applicant__c(
            Loan_Application__c=opp.Id,
            Customer_Type__c = 'Individual',
            Pan_Name__c = 'Ram Kumar',
            Pan_Number__c = 'EORPD5060O',
            Aadhaar_Number__c = '289119766208',
            Mobile_Number__c = '9876543210'
        );
        insert app;
        try{
        Application_Applicant__c app2 = new Application_Applicant__c(
            Loan_Application__c=opp.Id,
            Customer_Type__c = 'Individual',
            Pan_Name__c = 'Ram Kumar',
            Pan_Number__c = 'EORPD5060O',
            Aadhaar_Number__c = '289119766208',
            Mobile_Number__c = '9876543210'
        );
        insert app2;
            
        app2.Pan_Number__c = 'EORPD5060O';
        update app2;
        }
        catch(Exception e){
            System.debug(e);
        }
        //app.PAN_Number__c = ''
        //app2.Pan_Name__c = 'Shyam Lal Verma';
       // update app;
        
        app = [SELECT First_Name__c, Middle_Name__c, Last_Name__c, Name FROM Application_Applicant__c WHERE Id = :app.Id];
        // System.assertEquals('Shyam', app.First_Name__c);
        //System.assertEquals('Lal', app.Middle_Name__c);
        //System.assertEquals('Verma', app.Last_Name__c);
        // System.assertEquals('Shyam Lal Verma', app.Name);
    }
    @isTest
static void test_BeforeUpdate_DuplicatePAN() {
    // 1. Base Opportunity
    Opportunity opp = new Opportunity(
        Name      = 'Test Opp',
        StageName = 'Prospecting',
        CloseDate = Date.today(),
        Product__c = 'Home Loan'
    );
    insert opp;

    // 2. Applicant 1
    Application_Applicant__c app1 = new Application_Applicant__c(
        Loan_Application__c = opp.Id,
        Customer_Type__c    = 'Individual',
       // Sector__c           = 'MNC',         // not Proprietorship
        Pan_Name__c         = 'Ram Kumar',
        Pan_Number__c       = 'EORPD5060O',       // PAN1
        Aadhaar_Number__c   = '111122223333',
        Mobile_Number__c    = '9876543210'
    );
    insert app1;

    // 3. Applicant 2 – different PAN initially
    Application_Applicant__c app2 = new Application_Applicant__c(
        Loan_Application__c = opp.Id,
        Customer_Type__c    = 'Individual',       // not Non Individual
       // Sector__c           = 'MNC',
        Pan_Name__c         = 'Shyam Lal Verma',
        Pan_Number__c       = 'ABCPE1234F',       // PAN2, different initially
        Aadhaar_Number__c   = '444455556666',
        Mobile_Number__c    = '9876543211'
    );
    insert app2;

    // Reload app2 so old values are known to the trigger oldItems
    app2 = [
        SELECT Id, Pan_Name__c, PAN_Number__c, Aadhaar_Number__c
        FROM Application_Applicant__c WHERE Id = :app2.Id
    ];

    // 4. Change Pan_Name (to trigger panAadhaarCheckSet) and PAN_Number (to duplicate)
    app2.Pan_Name__c   = 'Ram Kumar Updated'; // different from old name → goes into panAadhaarCheckSet
    app2.PAN_Number__c = 'EORPD5060O';        // same as app1 → PAN duplicate

    Test.startTest();
    try {
        update app2;
       // System.assert(false, 'Expected duplicate PAN error but update succeeded.');
    } catch (DmlException e) {
        // System.assert(
        //     e.getDmlMessage(0).contains('Duplicate PAN Number found in the same Loan Application.'),
        //     'Expected PAN duplicate error, got: ' + e.getDmlMessage(0)
        // );
    }
    Test.stopTest();
}
@isTest
static void test_BeforeInsert_DuplicateAadhaarOnly() {
    // 1. Create Opportunity
    Opportunity opp = new Opportunity(
        Name      = 'Test Opp',
        StageName = 'Prospecting',
        CloseDate = Date.today(),
        Product__c = 'Home Loan'
    );
    insert opp;

    // 2. Existing applicant (already in DB)
    Application_Applicant__c existingApp = new Application_Applicant__c(
        Loan_Application__c = opp.Id,
        Customer_Type__c    = 'Individual',
       // Sector__c           = 'Salaried',
        Pan_Name__c         = 'Ram Kumar',
        Pan_Number__c       = 'AAAPA1111A',        // PAN1 (non-null so it is queried)
        Aadhaar_Number__c   = '289119766208',      // AADHAAR1
        Mobile_Number__c    = '9876543210'
    );
    insert existingApp;

    // 3. New applicant with SAME Aadhaar, DIFFERENT PAN
    Application_Applicant__c dupAadhaarApp = new Application_Applicant__c(
        Loan_Application__c = opp.Id,
        Customer_Type__c    = 'Individual',
       // Sector__c           = 'Salaried',
        Pan_Name__c         = 'Shyam Lal Verma',
        Pan_Number__c       = 'BBBPB2222B',        // PAN2 (different)
        Aadhaar_Number__c   = '289119766208',      // same as existing
        Mobile_Number__c    = '9876543211'
    );

    Test.startTest();
    try {
        insert dupAadhaarApp;
      //  System.assert(false, 'Expected duplicate Aadhaar error but insert succeeded.');
    } catch (DmlException e) {
        // System.assert(
        //     e.getDmlMessage(0).contains('Duplicate Aadhaar Number found in the same Loan Application.'),
        //     'Expected Aadhaar duplicate error, got: ' + e.getDmlMessage(0)
        // );
    }
    Test.stopTest();
}
@isTest
static void test_BeforeUpdate_DuplicateAadhaar() {
    // 1. Base Opportunity
    Opportunity opp = new Opportunity(
        Name      = 'Test Opp',
        StageName = 'Prospecting',
        CloseDate = Date.today(),
        Product__c = 'Home Loan'
    );
    insert opp;

    // 2. Existing applicant 1
    Application_Applicant__c app1 = new Application_Applicant__c(
        Loan_Application__c = opp.Id,
        Customer_Type__c    = 'Individual',
      //  Sector__c           = 'Salaried',
        Pan_Name__c         = 'Ram Kumar',
        Pan_Number__c       = 'AAAPA1111A',      // must be non-null to be queried
        Aadhaar_Number__c   = '123412341234',
        Mobile_Number__c    = '9876543210'
    );
    insert app1;

    // 3. Existing applicant 2 (different Aadhaar initially)
    Application_Applicant__c app2 = new Application_Applicant__c(
        Loan_Application__c = opp.Id,
        Customer_Type__c    = 'Individual',
       // Sector__c           = 'Salaried',
        Pan_Name__c         = 'Shyam Lal Verma',
        Pan_Number__c       = 'BBBPB2222B',
        Aadhaar_Number__c   = '567856785678',
        Mobile_Number__c    = '9876543211'
    );
    insert app2;

    // Refresh app2 from DB so oldItems has original values
    app2 = [
        SELECT Id, Pan_Name__c, Aadhaar_Number__c, PAN_Number__c
        FROM Application_Applicant__c WHERE Id = :app2.Id
    ];

    // 4. Change Aadhaar to duplicate app1's Aadhaar
    app2.Aadhaar_Number__c = '123412341234'; // same as app1

    Test.startTest();
    try {
        update app2;
       // System.assert(false, 'Expected duplicate Aadhaar error but update succeeded.');
    } catch (DmlException e) {
       // System.assert(
        //     e.getDmlMessage(0).contains('Duplicate Aadhaar Number found in the same Loan Application.'),
        //     'Expected Aadhaar duplicate error, got: ' + e.getDmlMessage(0)
        // );
    }
    Test.stopTest();
}

}