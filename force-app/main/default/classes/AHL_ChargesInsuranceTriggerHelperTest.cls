@isTest
public class AHL_ChargesInsuranceTriggerHelperTest {
    public class FetchAppDateMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('15');  // ✅ Integer as string (valid)
        return res;
    }
}


    @testSetup
    static void setupTestData() {
       
        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
             Product__c = 'Home Loan',
            StageName = 'Credit Underwriting',
            CloseDate = Date.today(),
            Amount = 10000,
            Pricing_Approval_Status__c = 'Submitted For Approval',
            Is_Pricing_Approval_Required__c = false,
            Sanction_Loan_Amount__c = 50000,
            Sanction_Tenure__c = 12,
            Sanction_Rate_Of_Interest__c = 10
        );
        insert opp;

         Map<String, Schema.RecordTypeInfo> ciRtInfos =
        Charges_Insurance__c.SObjectType.getDescribe().getRecordTypeInfosByName();
    Id insuranceRtId = ciRtInfos.get('Insurance').getRecordTypeId();
    Id chargesRtId   = ciRtInfos.get('Charges').getRecordTypeId();




    Charges_Insurance__c insOldSF = new Charges_Insurance__c(
        RecordTypeId         = insuranceRtId,
        Category__c          = 'Insurance',
        Loan_Application__c  = opp.Id,
        Name                 = 'UT Insurance SF',
        Fee_Method__c        = 'Self Funded',
        Total_VAS_Amount__c  = 500,
        Insurance_Premium__c = 500,
        Loan_Amount__c = 100000,
        Loan_tenure__c = 10,
        
        
        VAS_Code__c          = 'VAS_X',
        Policy_Tenure__c = 10
    );
    insert insOldSF;

    List<Charges_Insurance__c> ciList = new List<Charges_Insurance__c>{
        new Charges_Insurance__c(Id = insOldSF.Id,
            RecordTypeId         = insuranceRtId,
            Category__c          = 'Insurance',
            Loan_Application__c  = opp.Id,
            Name                 = 'UT Insurance SF',
            Fee_Method__c        = 'POSP')};
            update ciList;

    }

    @isTest
    static void testAfterUpdate2(){
        Test.startTest();

    Map<String, Schema.RecordTypeInfo> ciRtInfos =
        Charges_Insurance__c.SObjectType.getDescribe().getRecordTypeInfosByName();
    Id insuranceRtId = ciRtInfos.get('Insurance').getRecordTypeId();
    Id chargesRtId   = ciRtInfos.get('Charges').getRecordTypeId();


   /* Opportunity opp = new Opportunity(Name='UT Loan', StageName='Prospecting', CloseDate=Date.today());
    insert opp;

    Charges_Insurance__c insOldSF = new Charges_Insurance__c(
        RecordTypeId         = insuranceRtId,
        Category__c          = 'Insurance',
        Loan_Application__c  = opp.Id,
        Name                 = 'UT Insurance SF',
        Fee_Method__c        = 'Self Funded',
        Total_VAS_Amount__c  = 500,
        Insurance_Premium__c = 500,
        Product__c           = 'ProdX',
        VAS_Code__c          = 'VAS_X'
    );
    insert insOldSF;

    List<Charges_Insurance__c> ciList = new List<Charges_Insurance__c>{
        new Charges_Insurance__c(Id = insOldSF.Id,
            RecordTypeId         = insuranceRtId,
            Category__c          = 'Insurance',
            Loan_Application__c  = opp.Id,
            Name                 = 'UT Insurance SF',
            Fee_Method__c        = 'POSP')};
            update ciList;*/

    Test.stopTest();


    

    }

    @isTest
    static void testbeforeInsert() {
        Test.startTest();
     	List<Opportunity> opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, SObject> newMap = new Map<Id, SObject>{ opp[0].Id => opp[0] };
        
        AHL_ChargesInsuranceTriggerHelper.beforeInsert(opp
        );             
        
        AHL_ChargesInsuranceTriggerHelper.beforeUpdate(opp,
        newMap,
        opp,
        newMap
        );             
        Test.stopTest();

    }
    
    @isTest
    static void testbeforeUpdate() {
        Test.startTest();
     	List<Opportunity> opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, SObject> newMap = new Map<Id, SObject>{ opp[0].Id => opp[0] };
        
        AHL_ChargesInsuranceTriggerHelper.beforeUpdate(opp,
        newMap,
        opp,
        newMap
        );             
        Test.stopTest();

    }
    
    @isTest
    static void testbeforeDelete() {
     	Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        insert new Charges_Insurance__c(Name='TestInsurance', Loan_Application__c=opp.Id, Fee_Method__c = 'POSP');
		
        Test.startTest();
     	List<Charges_Insurance__c> charList = [SELECT Id,Loan_Application__c FROM Charges_Insurance__c LIMIT 1];
        Map<Id, SObject> newMap = new Map<Id, SObject>{ charList[0].Id => charList[0] };
        
        AHL_ChargesInsuranceTriggerHelper.beforeDelete(charList,
        newMap,
        charList,
        newMap
        );             
        Test.stopTest();

    }
    
    
    @isTest
    static void testafterDelete() {
        Test.startTest();
     	List<Opportunity> opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, SObject> newMap = new Map<Id, SObject>{ opp[0].Id => opp[0] };
        
        AHL_ChargesInsuranceTriggerHelper.afterDelete(opp,
        newMap
        );             
        Test.stopTest();

    }
    
    @isTest
    static void testafterUndelete() {
        Test.startTest();
     	List<Opportunity> opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, SObject> newMap = new Map<Id, SObject>{ opp[0].Id => opp[0] };
        
        AHL_ChargesInsuranceTriggerHelper.afterUndelete(opp,
        newMap
        );             
        Test.stopTest();

    }

    @isTest
    static void testafterUpdate() {
     	Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
          Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.getGlobalDescribe()
            .get('Charges_Insurance__c')
            .getDescribe()
            .getRecordTypeInfosByName();
        
        Id insuranceRecordTypeId = recordTypeMap.get('Insurance').getRecordTypeId();
        insert new Charges_Insurance__c(Name='TestInsurance',Total_VAS_Amount__c =10,Loan_Amount__c=10,Loan_tenure__c=10,Policy_Tenure__c=1,Value_Date__c=Date.newInstance(2025, 3, 18)
, Insurance_Premium__c=100, Loan_Application__c=opp.Id, Fee_Method__c = 'Self Funded',recordTypeId=insuranceRecordTypeId,VAS_Code__c = 'LIFEINS');
		
        Test.startTest();
     	List<Charges_Insurance__c> charList = [SELECT Id,Name,Charges_Fee_Type__c,Total_VAS_Amount__c,Charges_Insurance_Master__c,Loan_Application__c,RecordTypeId,Fee_Method__c,Insurance_Premium__c,VAS_Code__c,Total_Fee_to_be_deducted__c,Product__c FROM Charges_Insurance__c LIMIT 1];
         charList[0].Fee_Method__c = 'POSP';
       Map<Id, Charges_Insurance__c> newMap = new Map<Id, Charges_Insurance__c>(
    												[SELECT Id, Loan_Application__c,RecordTypeId,Fee_Method__c,Insurance_Premium__c,Total_Fee_to_be_deducted__c,Product__c FROM Charges_Insurance__c]); 
       
        AHL_ChargesInsuranceTriggerHelper.afterUpdate(charList,
        newMap,
        charList,
        newMap
        );             
        Test.stopTest();

    }
    
      @isTest
    static void testIsDisabledMethod() {
        // Create an instance of the class (if it's not static)
        AHL_ChargesInsuranceTriggerHelper helper = new AHL_ChargesInsuranceTriggerHelper();

        // Optionally, set the isTriggerDisabled flag if needed (if it's accessible)

        // Call the method
        Boolean result = helper.isDisabled();

        // Add assertion if desired
        System.assertNotEquals(null, result);
    }

    
 @IsTest
static void testAfterInsert() {
    // Get Record Type IDs
    Map<String, Schema.RecordTypeInfo> masterRecordTypeMap = Schema.SObjectType.Charges_Insurance_Master__c.getRecordTypeInfosByName();
    Id vasProviderRecordTypeId = masterRecordTypeMap.get('VAS Provider').getRecordTypeId();
    Id insuranceMasterRecordTypeId = masterRecordTypeMap.get('Insurance').getRecordTypeId();

    Map<String, Schema.RecordTypeInfo> insuranceRecordTypeMap = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName();
    Id insuranceRecordTypeId = insuranceRecordTypeMap.get('Insurance').getRecordTypeId();

    // Create Loan Application (Opportunity)
    Opportunity loanApp = new Opportunity(
        Name = 'Test Loan Application',
        StageName = 'Approved',
        CloseDate = Date.today(),
         Product__c = 'Home Loan',
        Sanction_Loan_Amount__c = 500000
    );
    insert loanApp;

    // Create Application Applicant
    Application_Applicant__c applicant = new Application_Applicant__c(
        Name = 'John Doe',
        Loan_Application__c = loanApp.Id,
        Applicant_Type__c = 'Primary Applicant',
        Mobile_Number__c = '9876543210'
    );
    insert applicant;

    // Create VAS Provider Charges_Insurance_Master__c record
    Charges_Insurance_Master__c vasProviderMaster = new Charges_Insurance_Master__c(
        RecordTypeId = vasProviderRecordTypeId,
        Dealer_Telephone__c = '1234567890',
        Payment_Mode__c = 'NEFT',
        Account_Number__c = '9876543210',
        Partner_Bank_Id__c = 154 // assuming this is a text field
    );
    insert vasProviderMaster;

    // Create Insurance Charges_Insurance_Master__c record linked to VAS Provider
    Charges_Insurance_Master__c insuranceMaster = new Charges_Insurance_Master__c(
        RecordTypeId = insuranceMasterRecordTypeId,
        VAS_Provider__c = vasProviderMaster.Id
    );
    insert insuranceMaster;

    // Create Charges_Insurance__c record (Insurance type to trigger logic)
    Charges_Insurance__c insuranceRecord = new Charges_Insurance__c(
        Name = 'Insurance Record',
        RecordTypeId = insuranceRecordTypeId,
        Fee_Method__c = 'POSP',
        Loan_Amount__c = 1000000,
        Loan_tenure__c = 2,
        Policy_Tenure__c = 1,
        Charges_Insurance_Master__c = insuranceMaster.Id,
        Loan_Application__c = loanApp.Id,
        VAS_Code__c = 'VAS001',
        Charges_Fee_Type__c = 'PPMCHG',
        Insurance_Premium__c = 2000,
        Total_VAS_Amount__c = 2000,
        Application_Applicant__c = applicant.Id
    );
    insert insuranceRecord;
    // Insert Integration_Details__c record to satisfy getFetchAppDateIntDetails method query
Integration_Details__c integrationRecord = new Integration_Details__c(
    Name = 'Fetch Application Date',
    Method_Type__c = 'GET',
    Business_Date__c = Date.today(),
    EndPoint__c = 'https://example.com/api',
    Response_JSON__c = '{}',
    Request_JSON__c = '{}'
);
insert integrationRecord;


    Test.startTest();
        // Mocking FetchApplicationDateController only if it's an HTTP call
        // If it's a static method returning data, mock accordingly
        // Example: Mocking can be skipped unless it makes HTTP callouts
        // Test.setMock(HttpCalloutMock.class, new FetchAppDateMock());

        // Call the method (simulate Trigger behavior)
        AHL_ChargesInsuranceTriggerHelper.afterInsert(
            new List<SObject>{ insuranceRecord }, 
            new Map<Id, SObject>{ insuranceRecord.Id => insuranceRecord }
        );
    Test.stopTest();

    // Assert Loan Transaction creation
    List<Loan_Transaction__c> payments = [
        SELECT Id, Status__c, Net_Amount__c 
        FROM Loan_Transaction__c 
        WHERE Charges_Insurance__c = :insuranceRecord.Id
    ];
    System.assertEquals(1, payments.size(), 'One Loan Transaction should be created');
    System.assertEquals(2000, payments[0].Net_Amount__c, 'Net Amount should match Insurance Premium');
    System.assertEquals('New', payments[0].Status__c, 'Loan Transaction status should be New');

    // Assert Total Charges record creation
    List<Charges_Insurance__c> totalCharges = [
        SELECT Id, Name 
        FROM Charges_Insurance__c 
        WHERE Loan_Application__c = :loanApp.Id AND Name = 'Total Charges'
    ];
    System.assertEquals(1, totalCharges.size(), 'One Total Charges record should be created');
}

    // Mock for FetchApplicationDateController.getFetchAppDateIntDetails
// @isTest
// static void testFullCoverage() {
//     // Prepare opportunity with Sanction_Loan_Amount__c
//     Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today().addDays(30), Sanction_Loan_Amount__c = 100000);
//     insert opp;

//     // Get record type id for Insurance
//     Id insuranceRTId = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName().get('Insurance').getRecordTypeId();

//     // Insert a Charges_Insurance__c parent insurance record
//     Charges_Insurance__c parentInsurance = new Charges_Insurance__c(
//         Name = 'Parent Insurance',
//         Loan_Application__c = opp.Id,
//         Fee_Method__c = 'POSP',
//          Loan_Amount__c = 1000000,
//         Loan_tenure__c = 2,
//         Policy_Tenure__c = 1,
//         Insurance_Premium__c = 100,
//         Total_VAS_Amount__c = 50,
//         RecordTypeId = insuranceRTId
//     );
//     insert parentInsurance;

//     // Insert child Charges_Insurance__c records referencing parentInsurance in Related_Insurance__c (to test updatedInsuranceRecords and relatedChargesToUpdate)
//     Charges_Insurance__c childCharge1 = new Charges_Insurance__c(
//         Name = 'Child 1',
//         Loan_Application__c = opp.Id,
//         Fee_Method__c = 'POSP',
//          Loan_Amount__c = 1000000,
//         Loan_tenure__c = 2,
//         Policy_Tenure__c = 1,
//         Related_Insurance__c = parentInsurance.Id,
//         Total_VAS_Amount__c = 0, // will be updated
//         RecordTypeId = insuranceRTId
//     );
//     insert childCharge1;

//     Charges_Insurance__c childCharge2 = new Charges_Insurance__c(
//         Name = 'Child 2',
//         Loan_Application__c = opp.Id,
//         Fee_Method__c = 'POSP',
//          Loan_Amount__c = 1000000,
//         Loan_tenure__c = 2,
//         Policy_Tenure__c = 1,
//         Related_Insurance__c = parentInsurance.Id,
//         Total_VAS_Amount__c = 0,
//         RecordTypeId = insuranceRTId
//     );
//     insert childCharge2;

//     // Prepare maps and lists for old and new records as in an update trigger
//     Charges_Insurance__c parentInsuranceOld = parentInsurance.clone(false,true,false,false);
//     // Change Fee_Method__c or Insurance_Premium__c to simulate update
//     parentInsurance.Fee_Method__c = 'Self Funded';
//     parentInsurance.Insurance_Premium__c = 200;
//     update parentInsurance;

//     List<Charges_Insurance__c> newList = new List<Charges_Insurance__c>{parentInsurance};
//     Map<Id, Charges_Insurance__c> newMap = new Map<Id, Charges_Insurance__c>{parentInsurance.Id => parentInsurance};
//     List<Charges_Insurance__c> oldList = new List<Charges_Insurance__c>{parentInsuranceOld};
//     Map<Id, Charges_Insurance__c> oldMap = new Map<Id, Charges_Insurance__c>{parentInsuranceOld.Id => parentInsuranceOld};

//     // Manually create collections to simulate deletion and insertion (if your helper method uses them)
//     // For example, create a record for deletion
//     Charges_Insurance__c toDelete = new Charges_Insurance__c(
//         Name = 'To Delete',
//         Loan_Application__c = opp.Id,
//         Fee_Method__c = 'POSP',
//         RecordTypeId = insuranceRTId
//     );
//     insert toDelete;

//     // Now call your helper method with the simulated inputs
//     Test.startTest();
//     AHL_ChargesInsuranceTriggerHelper.afterUpdate(newList, newMap, oldList, oldMap);
//     Test.stopTest();

//     // Add asserts here to verify behavior if desired
// }




    private static Id rtId(SObjectType sobType, String name) {
        Map<String, Schema.RecordTypeInfo> m = sobType.getDescribe().getRecordTypeInfosByName();
        return (m != null && m.containsKey(name)) ? m.get(name).getRecordTypeId() : null;
    }

    /*@IsTest
    static void test_updatedInsuranceRecords_branch_covered() {
        // --- Minimal setup ---
        Account acc = new Account(Name = 'Acc');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'Opp',
            StageName = 'Sales login',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Product__c = 'Home Loan'
        );
        insert opp;

        Id rtInsurance = rtId(Charges_Insurance__c.SObjectType, 'Insurance');
        Id rtCharges   = rtId(Charges_Insurance__c.SObjectType, 'Charges');
        Id rtPayment   = rtId(Loan_Transaction__c.SObjectType, 'Payment'); // needed for LT SOQL
        System.assertNotEquals(null, rtInsurance, 'Missing RT: Insurance');
        System.assertNotEquals(null, rtCharges,   'Missing RT: Charges');
        System.assertNotEquals(null, rtPayment,   'Missing RT: Payment');

        // Parent Insurance (OLD values)
        Charges_Insurance__c insX = new Charges_Insurance__c(
            Name = 'Insurance X',
            RecordTypeId = rtInsurance,
            Loan_Application__c = opp.Id,
            Fee_Method__c = 'POSP',
            //Product__c = 'Home Loan',
            Total_VAS_Amount__c = 200,
            Insurance_Premium__c = 200,
            Loan_Amount__c = 100000,
            Loan_tenure__c = 10,
            Policy_Tenure__c = 10
        );
        insert insX;

        // Child Charges linked to Insurance (will be UPDATED when parent changes)
        Charges_Insurance__c chInsX = new Charges_Insurance__c(
            Name = 'Child Charges X',
            RecordTypeId = rtCharges,
            Category__c = 'Insurance',
            Loan_Application__c = opp.Id,
            Related_Insurance__c = insX.Id,
            Fee_Method__c = 'POSP',
            //Product__c = 'Prod-Old',
            Total_VAS_Amount__c = 200,
            Final_Amount_INR__c = 200,
            Insurance_Premium__c = 200
        );
        insert chInsX;

        // LT hooked to Insurance – to satisfy helper’s LT query (even if not strictly needed for this assertion)
        Loan_Transaction__c ltX = new Loan_Transaction__c(
            //Name = 'LT X',
            RecordTypeId = rtPayment,
            Disbursement_Party__c = 'VAS',
            Charges_Insurance__c = insX.Id,
            Insurance_Amount__c = 0,
            Net_Amount__c = 0
        );
        insert ltX;

        // --- Build OLD snapshot (pre-update) for oldItems map ---
        Charges_Insurance__c oldInsX = [
            SELECT Id, RecordTypeId, Fee_Method__c, Product__c, Insurance_Premium__c,
                   Total_VAS_Amount__c
            FROM Charges_Insurance__c
            WHERE Id = :insX.Id
        ];

        // --- Apply NEW values that trigger updatedInsuranceRecords condition ---
        insX.Insurance_Premium__c = 250; // changed
        //insX.Product__c = 'Prod-New';    // changed
        // keep Fee_Method same, but any 1 of the 3 changed is sufficient
        // insX.Fee_Method__c = 'Self Funded'; // optional: also change fee method

        // also set Total_VAS to match code behavior that copies this to child fields
        insX.Total_VAS_Amount__c = 300;
        update insX;

        // --- Build helper inputs (newList/newMap and oldList/oldItems) ---
        Charges_Insurance__c newInsX = [
            SELECT Id, RecordTypeId, Fee_Method__c, Product__c, Insurance_Premium__c,
                   Total_VAS_Amount__c
            FROM Charges_Insurance__c
            WHERE Id = :insX.Id
        ];

        List<SObject> newList = new List<SObject>{ newInsX };
        Map<Id, SObject> newMap = new Map<Id, SObject>{ newInsX.Id => newInsX };

        List<SObject> oldList = new List<SObject>{ oldInsX };
        Map<Id, SObject> oldItems = new Map<Id, SObject>{ oldInsX.Id => oldInsX };

        // --- Invoke helper (directly) ---
        Test.startTest();
        AHL_ChargesInsuranceTriggerHelper.afterUpdate(newList, newMap, oldList, oldItems);
        Test.stopTest();

        // --- Assertions: if updatedInsuranceRecords executed, the child is updated per code ---
        Charges_Insurance__c childAfter = [
            SELECT Id, RecordType.Name, Product__c, Fee_Method__c,
                   Total_VAS_Amount__c, Final_Amount_INR__c, Insurance_Premium__c,
                   Related_Insurance__c
            FROM Charges_Insurance__c
            WHERE Id = :chInsX.Id
        ];

        // Confirms the branch ran AND subsequent update block executed:
        System.assertEquals('Charges', childAfter.RecordType.Name);
        System.assertEquals(insX.Id, childAfter.Related_Insurance__c);
        System.assertEquals(newInsX.Fee_Method__c, childAfter.Fee_Method__c,
            'Child Fee Method should mirror parent after update when branch fires');
        System.assertEquals(newInsX.Product__c, childAfter.Product__c,
            'Child Product should follow parent (only for Charges RT) per code');
        System.assertEquals(newInsX.Total_VAS_Amount__c, childAfter.Total_VAS_Amount__c,
            'Child Total_VAS should copy parent insurance per code');
        System.assertEquals(newInsX.Total_VAS_Amount__c, childAfter.Final_Amount_INR__c,
            'Child Final Amount should copy parent insurance per code');
        System.assertEquals(newInsX.Total_VAS_Amount__c, childAfter.Insurance_Premium__c,
            'Child Insurance_Premium__c set to parent Total_VAS_Amount__c per code');
    }*/




}