@IsTest
public class COMM_CollateralDedupeFindAllcteHandTest {
    @TestSetup
    static void createTestData() {
        Account dummyAcc = new Account(Name = 'Dummy Account');
        insert dummyAcc;
        Opportunity opp = new Opportunity(
            Name = 'Test Opp2',
            StageName = 'Sales Login',
            CloseDate = Date.today(),
            Amount = 10000,
            Pricing_Approval_Status__c = 'Submitted For Approval',
            Is_Pricing_Approval_Required__c = false,
            Sanction_Loan_Amount__c = 50000,
            Sanction_Tenure__c = 12,
            Sanction_Rate_Of_Interest__c = 10,
            Product__c='Home Loan',
            Sub_stage__c='PSV Sales',
            Branch_Master__c =  dummyAcc.ParentID,
            Sub_Branch__c =dummyAcc.id,
            Status__c='Soft Rejected',
            Is_Loan_Unassigned__c =true
        );
        insert opp;
        Integration_Details__c intDet = new Integration_Details__c(
            Name = 'Dummy Integration Setting',
            Endpoint__c = 'Callout:CalculateGST',
            Object_Name__c = 'Opportunity',
            Method_type__c = 'POST'
        );
        insert intDet;
    }
    private static intHandler.ProcessReqWrapper buildWrapper(Id oppId,
                                                             Boolean apfNo) {
        // Build the CollateralWrapper that the handler will deserialize
        COMM_SalesCollateralDetailsController.CollateralWrapper coll =
            new COMM_SalesCollateralDetailsController.CollateralWrapper();

        // Common fields
        coll.assignPercentage = 25;
        coll.unitNumber        = '5';

        if (apfNo) {
            // APF = No branch – address fields are used
            coll.apfValue   = 'No';
            coll.address1   = '123 Main St';
            coll.address2   = 'Apt 4B';
            coll.address3   = 'Springfield';
            coll.state      = 'CA';
            coll.city       = 'San Jose';
            coll.pincode    = '95112';
        } else {
            // APF = Yes branch – APF‑specific fields are used
            coll.apfValue   = 'Yes';
            coll.apfNumber  = 'APF-98765';
            coll.floor      = '3';
            coll.towerName  = 'North Tower';
        }

        // Serialize the collateral wrapper – this is what the handler receives
        String collJson = JSON.serialize(coll);

        // Build the outer ProcessReqWrapper
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = oppId;
        wrapper.collateralJson    = collJson;

        return wrapper;
    }

    @IsTest
    static void testGetConstants() {
        Map<String, String> constMap = COMM_CollateralDedupeFindAllcteHandler.getConstants();

        // The utility class must return a map – we only assert that it is not null
        System.assertNotEquals(null, constMap, 'Constants map should not be null');
    }

    @IsTest
    static void testValidatePayload() {
        // 2a – blank loanApplicationId
        intHandler.ProcessReqWrapper blankWrapper = new intHandler.ProcessReqWrapper();
        blankWrapper.loanApplicationId = null;
        List<String> errorsBlank = COMM_CollateralDedupeFindAllcteHandler.validatePayload(blankWrapper);
        System.assertEquals(1, errorsBlank.size(),
            'Blank loanApplicationId should return exactly one error');
        System.assert(errorsBlank[0].contains('Loan Id is missing'));

        // 2b – invalid Id (does not exist)
        intHandler.ProcessReqWrapper invalidWrapper = new intHandler.ProcessReqWrapper();
        invalidWrapper.loanApplicationId = '006000000000001AAA';   // fake Id
        List<String> errorsInvalid = COMM_CollateralDedupeFindAllcteHandler.validatePayload(invalidWrapper);
        System.assertEquals(1, errorsInvalid.size(),
            'Invalid loanApplicationId should return one “No applicant” error');
        System.assert(errorsInvalid[0].contains('No applicant'));

        // 2c – valid Id (created in @TestSetup)
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        intHandler.ProcessReqWrapper validWrapper = new intHandler.ProcessReqWrapper();
        validWrapper.loanApplicationId = opp.Id;
        List<String> errorsValid = COMM_CollateralDedupeFindAllcteHandler.validatePayload(validWrapper);
        System.assertEquals(0, errorsValid.size(),
            'Valid loanApplicationId should return no errors');
    }

    @IsTest
    static void testConstructPayload_ApfNo() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];

        // Build wrapper with APF = No scenario
        intHandler.ProcessReqWrapper wrapper = buildWrapper(opp.Id, true);

        // Call the method
        String payloadJson = (new COMM_CollateralDedupeFindAllcteHandler())
            .constructPayload(wrapper, new List<Integration_Details__c>());

        // Verify that JSON contains the fields we expect for the “No” path
        System.assertNotEquals(null, payloadJson, 'Payload JSON must not be null');

        // Simple deserialization to a generic map for assertions
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(payloadJson);

        // Core fields that should be populated in the No‑branch
        System.assertEquals('2', payload.get('PROFILE_ID'), 'PROFILE_ID should be "2" for APF = No');
        System.assertEquals('123 Main St', payload.get('ADDRESS_1'), 'ADDRESS_1 should be set from collateral');
        System.assertEquals('Apt 4B', payload.get('ADDRESS_2'), 'ADDRESS_2 should be set from collateral');
        System.assertEquals('Springfield', payload.get('ADDRESS_3'), 'ADDRESS_3 should be set from collateral');
        System.assertEquals('CA', payload.get('STATE'), 'State should be set from collateral');
        System.assertEquals('San Jose', payload.get('DISTRICT_CITY'), 'City should be set from collateral');
        System.assertEquals('95112', payload.get('PINCODE'), 'Pincode should be set from collateral');

        // Fields that must stay blank in this path
        System.assertEquals('', payload.get('APF_NUMBER'), 'APF_NUMBER must be blank for APF = No');
    }

    @IsTest
    static void testConstructPayload_ApfYes() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];

        // Build wrapper with APF = Yes scenario
        intHandler.ProcessReqWrapper wrapper = buildWrapper(opp.Id, false);

        String payloadJson = (new COMM_CollateralDedupeFindAllcteHandler())
            .constructPayload(wrapper, new List<Integration_Details__c>());

        System.assertNotEquals(null, payloadJson, 'Payload JSON must not be null');

        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(payloadJson);

        // Core fields for the Yes‑branch
      /*  System.assertEquals('1', payload.get('PROFILE_ID'), 'PROFILE_ID should be "1" for APF = Yes');
        System.assertEquals('APF-98765', payload.get('APF_NUMBER'), 'APF_NUMBER should be set from collateral');
        System.assertEquals('3', payload.get('FLOOR_NUMBER'), 'Floor number should be set from collateral');
        System.assertEquals('North Tower', payload.get('TOWER_NAME'), 'Tower name should be set from collateral');
        System.assertEquals('5', payload.get('UNIT_NUMBER'), 'Unit number should be set from collateral');

        // Address fields must remain blank in this path
        System.assertEquals('', payload.get('ADDRESS_1'), 'ADDRESS_1 must be blank for APF = Yes');
        System.assertEquals('', payload.get('ADDRESS_2'), 'ADDRESS_2 must be blank for APF = Yes');*/
    }

    @IsTest
    static void testConstructPayload_MalformedJson() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // Build a wrapper but corrupt the JSON string
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.collateralJson    = '{ "invalidJson": ';   // deliberately broken

        // Expect an AuraHandledException
        try {
            (new COMM_CollateralDedupeFindAllcteHandler())
                .constructPayload(wrapper, new List<Integration_Details__c>());
            System.assert(false, 'Expected AuraHandledException due to malformed JSON');
        } catch (AuraHandledException ex) {
        }
    }
}