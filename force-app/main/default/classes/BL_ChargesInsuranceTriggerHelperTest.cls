@isTest
public class BL_ChargesInsuranceTriggerHelperTest {
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

    }

    @isTest
    static void testbeforeInsert() {
        Test.startTest();
     	List<Opportunity> opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, SObject> newMap = new Map<Id, SObject>{ opp[0].Id => opp[0] };
        
        BL_ChargesInsuranceTriggerHelper.beforeInsert(opp
        );             
        
        BL_ChargesInsuranceTriggerHelper.beforeUpdate(opp,
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
        
        BL_ChargesInsuranceTriggerHelper.beforeUpdate(opp,
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
        
        BL_ChargesInsuranceTriggerHelper.beforeDelete(charList,
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
        
        BL_ChargesInsuranceTriggerHelper.afterDelete(opp,
        newMap
        );             
        Test.stopTest();

    }
    
    @isTest
    static void testafterUndelete() {
        Test.startTest();
     	List<Opportunity> opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, SObject> newMap = new Map<Id, SObject>{ opp[0].Id => opp[0] };
        
        BL_ChargesInsuranceTriggerHelper.afterUndelete(opp,
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
, Insurance_Premium__c=100, Loan_Application__c=opp.Id, Fee_Method__c = 'POSP',recordTypeId=insuranceRecordTypeId);
		
        Test.startTest();
     	List<Charges_Insurance__c> charList = [SELECT Id,Loan_Application__c,RecordTypeId,Fee_Method__c,Insurance_Premium__c,Total_Fee_to_be_deducted__c FROM Charges_Insurance__c LIMIT 1];
       Map<Id, Charges_Insurance__c> newMap = new Map<Id, Charges_Insurance__c>(
    												[SELECT Id, Loan_Application__c,RecordTypeId,Fee_Method__c,Insurance_Premium__c,Total_Fee_to_be_deducted__c FROM Charges_Insurance__c]); 
        BL_ChargesInsuranceTriggerHelper.afterUpdate(charList,
        newMap,
        charList,
        newMap
        );             
        Test.stopTest();

    }
    
     @isTest
    static void testafterUpdate2() {
     	Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
          Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.getGlobalDescribe()
            .get('Charges_Insurance__c')
            .getDescribe()
            .getRecordTypeInfosByName();
        
        Id insuranceRecordTypeId = recordTypeMap.get('Insurance').getRecordTypeId();
        insert new Charges_Insurance__c(Name='TestInsurance',Total_VAS_Amount__c =10,Loan_Amount__c=10,Loan_tenure__c=10,Policy_Tenure__c=1,Value_Date__c=Date.newInstance(2025, 3, 18)
, Insurance_Premium__c=100, Loan_Application__c=opp.Id, Fee_Method__c = 'POSP',recordTypeId=insuranceRecordTypeId);
        
        
		
        Test.startTest();
     	List<Charges_Insurance__c> oldList = [SELECT Id,Loan_Application__c,RecordTypeId,Fee_Method__c,Insurance_Premium__c,Total_Fee_to_be_deducted__c FROM Charges_Insurance__c LIMIT 1];
        
       Map<Id, Charges_Insurance__c> oldMap = new Map<Id, Charges_Insurance__c>(
    												[SELECT Id, Loan_Application__c,RecordTypeId,Fee_Method__c,Insurance_Premium__c,Total_Fee_to_be_deducted__c FROM Charges_Insurance__c]);
        Charges_Insurance__c rec = [SELECT Id,Name,Fee_Method__c FROM Charges_Insurance__c LIMIT 1];
        rec.Fee_Method__c = 'Self Funded';
        update rec;
        List<Charges_Insurance__c> neList = [SELECT Id,Loan_Application__c,RecordTypeId,Fee_Method__c,Insurance_Premium__c,Total_Fee_to_be_deducted__c,Name FROM Charges_Insurance__c LIMIT 1];
        
       Map<Id, Charges_Insurance__c> neMap = new Map<Id, Charges_Insurance__c>(
    												[SELECT Id, Loan_Application__c,RecordTypeId,Fee_Method__c,Insurance_Premium__c,Total_Fee_to_be_deducted__c,Name FROM Charges_Insurance__c]);
        BL_ChargesInsuranceTriggerHelper.afterUpdate(neList,
        neMap,
        oldList,
        oldMap
        );   
        rec.Fee_Method__c = 'DISB';
        rec.Name = 'LIFEINS';
        update rec;
        List<Charges_Insurance__c> neList2 = [SELECT Id,Name,VAS_Code__c,Loan_Application__c,RecordTypeId,Fee_Method__c,Insurance_Premium__c,Total_Fee_to_be_deducted__c,
                                              Charges_Fee_Type__c,Charges_Insurance_Master__c
                                              ,Total_VAS_Amount__c,Final_Amount_INR__c
                                              FROM Charges_Insurance__c LIMIT 1];
        
       Map<Id, Charges_Insurance__c> neMap2 = new Map<Id, Charges_Insurance__c>(
    												[SELECT Id, Name,VAS_Code__c,Charges_Fee_Type__c,Charges_Insurance_Master__c,Loan_Application__c
                                              ,Insurance_Premium__c,Total_VAS_Amount__c,Final_Amount_INR__c,RecordTypeId,Fee_Method__c,Total_Fee_to_be_deducted__c FROM Charges_Insurance__c]);
        BL_ChargesInsuranceTriggerHelper.afterUpdate(neList2,
        neMap2,
        neList,
        neMap
        );   
        
        
        
        
        Test.stopTest();
        

    }
    
      @isTest
    static void testIsDisabledMethod() {
        // Create an instance of the class (if it's not static)
        BL_ChargesInsuranceTriggerHelper helper = new BL_ChargesInsuranceTriggerHelper();

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
        BL_ChargesInsuranceTriggerHelper.afterInsert(
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
//     BL_ChargesInsuranceTriggerHelper.afterUpdate(newList, newMap, oldList, oldMap);
//     Test.stopTest();

//     // Add asserts here to verify behavior if desired
// }


}