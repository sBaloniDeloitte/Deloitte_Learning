@IsTest
private class HL_SquareYardHandlerTest {

    @testSetup
    static void setupData() {
        // 0) IMPORTANT: insert trigger settings like CKYC test (prevents CityMasterTrigger NPE)
        insert new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = true
        );

        // 1) Parent dataset (controller style)
        Account acc = new Account(Name='Test Customer');
        insert acc;

        Opportunity loan = new Opportunity(
            Name='Test Loan',
            StageName='Prospecting',
            CloseDate=Date.today().addDays(10),
            Product__c='Affordable Home Loan',
            AccountId=acc.Id
        );
        insert loan;

        // 2) City + Pincode (same pattern as CKYC test)
        City_Master__c city = new City_Master__c(
            Name='Gudivada',
            City_Code__c='C01',
            Country__c='IN',
            State__c='AP'
        );
        insert city;

        Pincode_Master__c pin = new Pincode_Master__c(
            Name='521301',
            City__c = city.Id
        );
        insert pin;
        Id tmUserId1 = UserInfo.getUserId();
        // 3A) Tech Eval for "ALL MISSING" validations
        Technical_Evaluation__c techMissing = new Technical_Evaluation__c(
            // If required in your org, keep it; else remove it:
            // HL_Loan_Application__c = loan.Id
            // Intentionally blank fields to hit all "Missing ..." messages
            HL_Assigned_to_Technical_Manager__c = tmUserId1,
            HL_Pincode__c = null
        );
        insert techMissing;
        Id tmUserId = UserInfo.getUserId();
        // 3B) Tech Eval for constructPayload SUCCESS (must have all required fields)
        Technical_Evaluation__c techGood = new Technical_Evaluation__c(
            // If required in your org, keep it; else remove it:
            // HL_Loan_Application__c = loan.Id,
            HL_Assigned_to_Technical_Manager__c = tmUserId,
            HL_Name_of_Project__c        = 'My Project',
            HL_Area_Type__c              = 'carpet',
            HL_Area_of_Property__c       = '450',        // must be numeric string
            Unit_Type__c                 = '1 BHK',
            HL_Pincode__c                = pin.Id,       // IMPORTANT for City__r.Name
            HL_SquareYard_ProjectId__c   = '8761',
            HL_Image_Url__c              = 'https://example.com/img.jpg',
            HL_Architecture_Cert_Url__c  = 'https://example.com/arch.pdf',
            HL_Cost_Sheet_Url__c         = 'https://example.com/cost.pdf',
            HL_LAN_ID__c                 = 'LAN123',
            HL_Name_of_Applicant__c      = 'John Doe'
        );
        insert techGood;
    }

    @IsTest
    static void testValidatePayload_SqYdInitiation_AllMissing() {
        Technical_Evaluation__c tech = [
            SELECT Id
            FROM Technical_Evaluation__c
            WHERE HL_Name_of_Project__c = null
            LIMIT 1
        ];

        IntHandler.ProcessReqWrapper w = new IntHandler.ProcessReqWrapper();
        w.type     = 'SqYd Initiation';
        w.recordId = tech.Id;

        Test.startTest();
        List<String> errs = HL_SquareYardHandler.validatePayload(w);
        Test.stopTest();

        System.assert(errs.size() > 0, 'Expected validation errors');
        System.assert(errs.contains('Error: Missing Project Name'));
        System.assert(errs.contains('Error: Missing Area Type'));
        System.assert(errs.contains('Error: Missing Area'));
        System.assert(errs.contains('Error: Missing Configuration'));
        System.assert(errs.contains('Error: Missing Pincode'));
        System.assert(errs.contains('Error: Missing Project Id'));
        System.assert(errs.contains('Error: Missing Image'));
        System.assert(errs.contains('Error: Missing Architecture Cert'));
        System.assert(errs.contains('Error: Missing Cost Sheet'));
        System.assert(errs.contains('Error: Missing Lan Id'));
        System.assert(errs.contains('Error: Missing Main Applicant Name'));
    }

    @IsTest
    static void testValidatePayload_NonInitiation_ReturnsEmpty() {
        Technical_Evaluation__c tech = [SELECT Id FROM Technical_Evaluation__c LIMIT 1];

        IntHandler.ProcessReqWrapper w = new IntHandler.ProcessReqWrapper();
        w.type     = 'Some Other Type';
        w.recordId = tech.Id;

        List<String> errs = HL_SquareYardHandler.validatePayload(w);
        System.assertEquals(0, errs.size());
    }

    @IsTest
    static void testConstructPayload_Success() {
        Technical_Evaluation__c tech = [
            SELECT Id
            FROM Technical_Evaluation__c
            WHERE HL_Name_of_Project__c != null
            LIMIT 1
        ];

        HL_SquareYardHandler h = new HL_SquareYardHandler();

        IntHandler.ProcessReqWrapper w = new IntHandler.ProcessReqWrapper();
        w.type     = 'SqYd Initiation';
        w.recordId = tech.Id;

        Test.startTest();
        String payload = h.constructPayload(w, new List<Integration_Details__c>());
        Test.stopTest();

        System.assertNotEquals(null, payload);
        System.assert(payload.contains('"projectName"'));
        System.assert(payload.contains('"additionalInfo"'));

        // Optional: validate key fields via deserialize
        Map<String,Object> root = (Map<String,Object>) JSON.deserializeUntyped(payload);
        System.assertEquals('My Project', (String)root.get('projectName'));
        //System.assertEquals('carpet', (String)root.get('areaType'));
        System.assertEquals(450, (Integer)root.get('area'));
    }

    @IsTest
    static void testConstructPayload_Exception_BadRecordId() {
        HL_SquareYardHandler h = new HL_SquareYardHandler();

        IntHandler.ProcessReqWrapper w = new IntHandler.ProcessReqWrapper();
        w.type     = 'SqYd Initiation';
        w.recordId = 'a0Z000000000000AAA'; // invalid / not existing tech eval id

        Boolean thrown = false;
        try {
            Test.startTest();
            h.constructPayload(w, new List<Integration_Details__c>());
            Test.stopTest();
        } catch (AuraHandledException ex) {
            thrown = true;
            //System.assert(ex.getMessage().contains('An error occurred'));
        }
        System.assert(thrown);
    }
}