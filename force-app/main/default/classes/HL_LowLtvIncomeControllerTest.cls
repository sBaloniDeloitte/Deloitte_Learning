@IsTest
public class HL_LowLtvIncomeControllerTest {
    @testsetup
    public static void datacreation(){
        Account acc = new Account(Name = 'Vendor Account');
        insert acc;
        
        // Create user and assign profile
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User u = new User(
            FirstName = 'Test',
            LastName = 'TechAdmin',
            Alias = 'testta',
            Email = 'testtechadmin@example.com',
            Username = 'testtechadmin@example.com' + System.currentTimeMillis(),
            User_Type__c = 'External',
            IsActive = true,
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        
        Opportunity loanApp = new Opportunity(Name = 'Loan 1', Product__c = 'Affordable Home Loan');
        insert loanApp;
        
        //insert Collateral
        Collateral__c coll = new Collateral__c();
        coll.Document_Value__c = 100000;
        insert coll;
        
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id,
            Collateral__c = coll.Id
        );
        insert collateral;
        
        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            Loan_Application__c = loanApp.Id
        );
        insert applicant;
        
        //need to create trigger setting
        Trigger_Settings__c setting = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = true
        );
        insert setting;
        
        City_Master__c city = new City_Master__c(
            Name = 'testing City',
            Country__c = 'IN',
            State__c = 'RJ',   
            District__c = 'Agra'  
        );
        insert city;
        
        // Insert a Pincode Master
        Pincode_Master__c pin = new Pincode_Master__c(
            Name = '282007',
            City__c = city.id 
        );
        insert pin;
        
        //create the Applicant Address with Applicant__c
        Applicant_Address__c address = new Applicant_Address__c(
            Applicant__c = applicant.Id, 
            Application_Collateral__c = collateral.Id,
            Plot_Number__c = '123',
            Building_Street_Name__c = 'Street 1',
            Landmark__c = 'Near Church',
            Post_Office_Name__c = 'Test PO',
            Pincode__c = pin.Id
        );
        insert address;
        
          // Create a Document_Master__c record
        Document_Master__c docMaster = new Document_Master__c(
            Name = 'DL',
            Document_Name__c ='DL',
            Type__c = 'Technical',
            Requirement_At__c ='FCU',
            Document_Category__c ='KYC',
            Mandatory_Non_Mandatory__c = 'Optional'
        );
        insert docMaster;
        
        Document_Details__c docDetail = new Document_Details__c(
            Name = 'DL',
            Loan_Application__c = loanApp.Id,
            Document_Required__c = 'Optional'
        );
        insert docDetail;
    }

    @IsTest
    static void testCreateCamRecordsOnLoad() {
        Opportunity loan = [SELECT Id from Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT ID from Application_Applicant__c WHERE Loan_Application__c =:loan.Id];
        String recTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Low_LTV_Program').getRecordTypeId();

        Test.startTest();
        HL_LowLtvIncomeController.createCamRecordsOnLoad(
            loan.Id,
            app.Id
        );
        Test.stopTest();

        List<Income_Assessment__c> records = [
            SELECT Id, Parent__c
            FROM Income_Assessment__c
            WHERE Loan_Application__c = :loan.Id
            AND Applicant__c = :app.Id
            AND RecordTypeId = :recTypeId
        ];

        System.assertEquals(
            2,
            records.size(),
            'One parent and one child record should be created'
        );

        Boolean hasParent = false;
        Boolean hasChild = false;

        for (Income_Assessment__c ia : records) {
            if (ia.Parent__c == null) {
                hasParent = true;
            } else {
                hasChild = true;
            }
        }

        System.assert(hasParent, 'Parent record should exist');
        System.assert(hasChild, 'Child record should exist');
    }

    @IsTest
    static void testGetScreenData() {
       	 Opportunity loan = [SELECT Id from Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT ID from Application_Applicant__c WHERE Loan_Application__c =:loan.Id];
        String recTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Low_LTV_Program').getRecordTypeId();

        Income_Assessment__c parent = new Income_Assessment__c(
            Loan_Application__c = loan.Id,
            Applicant__c = app.Id,
            RecordTypeId = recTypeId
        );
        insert parent;

        Income_Assessment__c child = new Income_Assessment__c(
            Loan_Application__c = loan.Id,
            Applicant__c = app.Id,
            Parent__c = parent.Id,
            RecordTypeId = recTypeId,
            Average_Bank_Balance__c = 50000,
            HL_Abb_EMI_Ratio__c = 35
        );
        insert child;

        Test.startTest();
        List<HL_LowLtvIncomeController.BankingWrapper> result =
            HL_LowLtvIncomeController.getScreenData(
                loan.Id,
                app.Id
            );
        Test.stopTest();

        System.assertEquals(
            2,
            result.size(),
            'Two wrapper rows should be returned'
        );

        for (HL_LowLtvIncomeController.BankingWrapper bw : result) {
            System.assertNotEquals(null, bw.fieldLabel);
            System.assertNotEquals(null, bw.fieldAPIName);
            System.assertEquals(child.Id, bw.incomerecordId);
        }
    }

    @IsTest
    static void testGetApplicants() {
         Opportunity loan = [SELECT Id from Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT ID from Application_Applicant__c WHERE Loan_Application__c =:loan.Id];
        String recTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Low_LTV_Program').getRecordTypeId();

        Income_Assessment__c inc = new Income_Assessment__c(
            Loan_Application__c = loan.Id,
            Applicant__c = app.Id,
            RecordTypeId = recTypeId
        );
        insert inc;

        Test.startTest();
        List<HL_LowLtvIncomeController.ApplicantWrapper> result =
            HL_LowLtvIncomeController.getApplicants(loan.Id);
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(app.Id, result[0].appId);
        System.assertEquals(true, result[0].isDataCreated);
    }

    @IsTest
    static void testDeleteCamRecords() {
         Opportunity loan = [SELECT Id from Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT ID from Application_Applicant__c WHERE Loan_Application__c =:loan.Id];
        String recTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Low_LTV_Program').getRecordTypeId();

        Income_Assessment__c inc = new Income_Assessment__c(
            Loan_Application__c = loan.Id,
            Applicant__c = app.Id,
            RecordTypeId = recTypeId
        );
        insert inc;

        Test.startTest();
        HL_LowLtvIncomeController.deleteCamRecords(
            loan.Id,
            new List<Id>{ app.Id }
        );
        Test.stopTest();

        Integer countAfterDelete = [
            SELECT COUNT()
            FROM Income_Assessment__c
            WHERE Loan_Application__c = :loan.Id
        ];

        System.assertEquals(
            0,
            countAfterDelete,
            'Income Assessment records should be deleted'
        );
    }
}