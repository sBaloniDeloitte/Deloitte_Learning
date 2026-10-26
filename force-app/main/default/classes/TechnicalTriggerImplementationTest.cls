@isTest
public class TechnicalTriggerImplementationTest {
    
    @testSetup
    static void setupData() {
        // Create sample Loan Application
      Opportunity loanApp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            Product__c = 'Affordable Home Loan',
            Exception_Approval_Status__c = 'Submitted For Approval'
        );
        insert loanApp;
         //insert Collateral
        Collateral__c coll = new Collateral__c();
        insert coll;
        
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id,
            Collateral__c = coll.Id
        );
        insert collateral;

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
        
        // Create sample Technical Evaluation record
       // Insert Technical Evaluation record 
        Technical_Evaluation__c existingTechEval = new Technical_Evaluation__c(
            HL_Application_Collateral__c = collateral.Id,
            HL_Loan_Application__c = loanApp.Id,
            HL_Stage__c = 'Assigned to Technical Manager',
            HL_Assigned_To_Technical_Manager__c = u.Id
        );
        insert existingTechEval;
    
// Get Legal__c record type
        RecordType rt = [SELECT Id, Name, SObjectType FROM RecordType 
                         WHERE SObjectType = 'Legal__c' and name = 'Legal Scrutiny Report'
                         LIMIT 1];

        // Create Legal__c record
        Legal__c legal = new Legal__c(
            Loan_Application__c = loanApp.Id,
            Stage__c = 'Draft',
            Report_Generation_Date__c = Date.today(),
            RecordTypeId = rt.Id,
            OwnerId = UserInfo.getUserId(),
            Assigned_to_Admin__c = UserInfo.getUserId(),
            Assigned_to_Executive__c = UserInfo.getUserId(),
            Name_of_the_Mortgator__c = 'Test Mortgator'
        );
        insert legal;
    }
    
    @isTest
    static void testInsertActionCreatesTATRecord() {
        // Get the test Legal record
        Legal__c legalRec = [SELECT Id, Loan_Application__c FROM Legal__c LIMIT 1];
        
        // 3️⃣ Call the class method with 'insert'
        Test.startTest();
        LegalTriggerImplementation.addAndUpdateStageTATRecords(
            new List<String>{ legalRec.Id },
            'insert'
        );
        Test.stopTest();
        
        // 4️⃣ Validate TAT__c record creation
        List<TAT__c> tatRecords = [
            SELECT Id, Activity__c, Sub_Activity__c, Stage__c, Loan_Application__c, Related_Legal__c, End_Timestamp__c
            FROM TAT__c
            WHERE Related_Legal__c = :legalRec.Id
        ];
        
        System.assertEquals(1, tatRecords.size(), 'One TAT record should be created');
        //System.assertEquals('Legal Verification', tatRecords[0].Activity__c);
        //System.assertEquals('Case submitted for Legal Verification', tatRecords[0].Sub_Activity__c);
        //System.assertEquals(legalRec.Loan_Application__c, tatRecords[0].Loan_Application__c);
        //System.assertEquals(null, tatRecords[0].End_Timestamp__c, 'End timestamp should be null after insert');
    }

    @isTest
    static void testUpdateActionUpdatesEndTimestamp() {
        // Ensure a TAT record exists from insert flow
        Legal__c legalRec = [SELECT Id FROM Legal__c LIMIT 1];
        LegalTriggerImplementation.addAndUpdateStageTATRecords(
            new List<String>{ legalRec.Id },
            'insert'
        );
        
        // Verify existing TAT record
        TAT__c tatRec = [SELECT Id, Related_Legal__c, End_Timestamp__c FROM TAT__c WHERE Related_Legal__c = :legalRec.Id LIMIT 1];
        System.assertEquals(null, tatRec.End_Timestamp__c);

        // 5️⃣ Call method with 'update' action to close the TAT record
        Test.startTest();
        LegalTriggerImplementation.addAndUpdateStageTATRecords(
            new List<String>{ legalRec.Id },
            'update'
        );
        Test.stopTest();

        // 6️⃣ Verify End_Timestamp__c got populated
        TAT__c updatedTat = [SELECT End_Timestamp__c FROM TAT__c WHERE Id = :tatRec.Id LIMIT 1];
        System.assertNotEquals(null, updatedTat.End_Timestamp__c, 'End timestamp should be updated');
    }

    @isTest
    static void testAddTATRecordsOnInsert() {
        // Fetch Technical Evaluation record created in setup
        Technical_Evaluation__c techEval = [SELECT Id, HL_Loan_Application__c FROM Technical_Evaluation__c LIMIT 1];

        // Call the method with 'insert' action
        Test.startTest();
        TechnicalTriggerImplementation.addAndUpdateStageTATRecords(
            new List<String>{ techEval.Id },
            'insert'
        );
        Test.stopTest();

        // Validate TAT__c record is created
        TAT__c createdTat = [SELECT Id, Stage__c, Activity__c, Sub_Activity__c, Loan_Application__c, Related_Technical__c
                             FROM TAT__c
                             WHERE Related_Technical__c = :techEval.Id
                             LIMIT 1];

        System.assertEquals('Technical Verification', createdTat.Activity__c);
        //System.assertEquals('Case submitted for Technical Verification', createdTat.Sub_Activity__c);
        //System.assertEquals(techEval.HL_Loan_Application__c, createdTat.Loan_Application__c);
        //System.assertEquals(techEval.Id, createdTat.Related_Technical__c);
    }

    @isTest
    static void testUpdateTATRecords() {
        // First create a TAT record via the insert method
        Technical_Evaluation__c techEval = [SELECT Id FROM Technical_Evaluation__c LIMIT 1];
        TechnicalTriggerImplementation.addAndUpdateStageTATRecords(
            new List<String>{ techEval.Id },
            'insert'
        );
        
        // Verify TAT record created
        TAT__c tat = [SELECT Id, Related_Technical__c, End_Timestamp__c 
                      FROM TAT__c WHERE Related_Technical__c = :techEval.Id LIMIT 1];
        System.assertEquals(null, tat.End_Timestamp__c);

        // Call update method
        Test.startTest();
        TechnicalTriggerImplementation.addAndUpdateStageTATRecords(
            new List<String>{ techEval.Id },
            'update'
        );
        Test.stopTest();

        // Verify End_Timestamp__c got updated
        TAT__c updatedTat = [SELECT End_Timestamp__c FROM TAT__c WHERE Id = :tat.Id LIMIT 1];
        System.assertNotEquals(null, updatedTat.End_Timestamp__c);
    }
}