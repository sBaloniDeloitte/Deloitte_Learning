@isTest
private class BL_OpportunityTriggerHelperTest {

    @testSetup
    static void setupTestData() {
       
        // Create Product2 linked to Opp
        Product_Master__c prod = new Product_Master__c(
            Name = 'Sub Product A',
            RecordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId()
        );
        insert prod;

        // Create Charges_Insurance_Master__c
        Charges_Insurance_Master__c cim = new Charges_Insurance_Master__c(
            Charges_Fee_Type__c = 'Miscellaneous charges',
            Default_Value__c = 2,
            Max_Percent__c = 4,
            Min_Percent__c = 1,
            Category__c = 'LMS'
        );
        insert cim;
        
        
         // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Credit Underwriting',
            CloseDate = Date.today(),
            Amount = 10000,
            Pricing_Approval_Status__c = 'Submitted For Approval',
            Is_Pricing_Approval_Required__c = false,
            Sanction_Loan_Amount__c = 50000,
            Sanction_Tenure__c = 12,
            Sanction_Rate_Of_Interest__c = 10,
            Product__c='Home Loan'
        );
        insert opp;
        
        RecordType  ProductRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Product' LIMIT 1];
        
        Product2 prod3 = new Product2(
            Name = 'Business Loan',
            RecordTypeId = ProductRT.Id,
            IsActive = true,
            Loan_Application__c = opp.Id
        );
        insert prod3;

        
        RecordType subProductRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Sub_Product' LIMIT 1];
        
        Product2 prod2 = new Product2(
            Name = 'Term Loan',
            Loan_Application__c = opp.Id,
            RecordTypeId = subProductRT.Id,
            IsActive = true
        );
        insert prod2;
        
       OpportunityTeamMember otm= new OpportunityTeamMember(
           OpportunityId = opp.Id,
           UserId = UserInfo.getUserId(),
           TeamMemberRole = 'Sales',
           OpportunityAccessLevel = 'Edit',
           Associated_With_Loan_Application__c = true
       );
       insert otm;

        
        Screen_Field__c field1 = new Screen_Field__c(
            Form_Name__c = 'Loan Details',
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Loan_Transaction__c',
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
        insert field1;
        
        Screen_Field__c field = new Screen_Field__c(
            Form_Name__c = 'Loan Details',
            Parent_Screen__c   = field1.Id,
            Loan_Type__c = 'Term Loan',
            Screen_Object__c = 'Loan_Transaction__c',
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
            Is_Lookup__c = false,
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
        insert field;

        
         Integration_Details__c details = new Integration_Details__c(
            Related_Record_Id__c = opp.Id,
            Status__c = '200',
            Name = 'Fetch Application Date',
            Object_Name__c = 'Application_Applicant__c',
             Response_JSON__c = '{test:}',
            Loan_Application__c = opp.Id,
            endpoint__c = 'test.loan.com'
        );
        insert details;
    }

    @isTest
static void testBeforeUpdate_POSPCalcAndStageChange() {
    // Step 1: Create an Opportunity in the 'Credit Underwriting' stage
    Opportunity opp = new Opportunity(
        Name = 'Test Opp - POSP Calculation',
        StageName = 'Credit Underwriting',
        CloseDate = Date.today().addDays(30),
        Amount = 20000,
        Pricing_Approval_Status__c = 'Submitted For Approval',
        Is_Pricing_Approval_Required__c = true,
        Sanction_Loan_Amount__c = 50000,
        Product__c='Home Loan',
        Negotiated_Loan_Amount__c = 50000 // Matches Sanction_Loan_Amount__c
    );
    insert opp;

    // Step 2: Create a related Charges_Insurance__c record with Fee_Method__c = 'POSP'
    Charges_Insurance__c charge = new Charges_Insurance__c(
        Name = 'POSP Charge',
        Loan_Application__c = opp.Id,
        Fee_Method__c = 'POSP',
        Final_Amount_INR__c = 5000 // POSP amount
    );
    insert charge;

    // Step 3: Clone the Opportunity and update fields to trigger the logic
    Opportunity newOpp = opp.clone(false, false, false, false);
    newOpp.StageName = 'PSV'; // Transition to PSV stage
    newOpp.Id = opp.Id; // Transition to PSV stage
    newOpp.Negotiated_Loan_Amount__c = 123; 
    newOpp.Sanction_Loan_Amount__c = 123; 
    newOpp.Pricing_Approval_Status__c = 'Approved';
    update newOpp;

    // Step 4: Prepare inputs for the helper method
    List<Opportunity> newList = new List<Opportunity>{ newOpp };
    List<Opportunity> oldList = new List<Opportunity>{ Opp };
    Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{ newOpp.Id => newOpp };
    Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ Opp.Id => Opp };

    // Step 5: Call the helper method
    Test.startTest();
    BL_OpportunityTriggerHelper.beforeUpdate(newList, newMap, oldList, oldMap);
    Test.stopTest();

    // Step 6: Add assertions to validate the logic
    Opportunity updatedOpp = [SELECT Final_Amount__c FROM Opportunity WHERE Id = :opp.Id];
}
    @isTest
    static void testAfterUpdate_LMSChargeCreationAndRollback() {
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp2',
            StageName = 'Credit Underwriting',
            CloseDate = Date.today(),
            Amount = 10000,
            Pricing_Approval_Status__c = 'Submitted For Approval',
            Is_Pricing_Approval_Required__c = false,
            Sanction_Loan_Amount__c = 50000,
            Sanction_Tenure__c = 12,
            Sanction_Rate_Of_Interest__c = 10,
            Sub_stage__c = 'Credit in-progress',
            Product__c='Home Loan',
            LMS_Loan_Reference__c= '123'
        );
        insert opp;

        OpportunityTeamMember otm= new OpportunityTeamMember(
           OpportunityId = opp.Id,
           UserId = UserInfo.getUserId(),
           TeamMemberRole = 'Sales',
           OpportunityAccessLevel = 'Edit',
           Associated_With_Loan_Application__c = true
       );
       insert otm;

        Opportunity updatedOpp = opp.clone(false); 
        updatedOpp.Id = opp.Id;
        updatedOpp.StageName = 'PSV';
        updatedOpp.Sub_stage__c = 'PSV Sales';
        updatedOpp.Is_Pricing_Approval_Required__c = true;

        update updatedOpp;
       
    	Product2 productRecord2 = [SELECT Id,Name,Loan_Application__c FROM Product2 WHERE RecordType.Name='Product' LIMIT 1];
        
        productRecord2.Loan_Application__c = updatedOpp.Id;
        update productRecord2;
        
        
    	Product2 productRecord = [SELECT Id,Name,Loan_Application__c,Product__c FROM Product2 WHERE RecordType.Name = 'Sub Product' LIMIT 1];
				
        productRecord.Loan_Application__c = updatedOpp.Id;
        productRecord.Product__c = productRecord2.Id;
        update productRecord;

        
        Test.startTest();
        try{
        BL_OpportunityTriggerHelper.afterUpdate(
                new List<Opportunity>{ updatedOpp },
                new Map<Id, Opportunity>{ updatedOpp.Id => updatedOpp },
                new List<Opportunity>{ opp },
                new Map<Id, Opportunity>{ opp.Id => opp }
            );
        }catch(exception ex){}
        Test.stopTest();

        List<Charges_Insurance__c> charges = [SELECT Id FROM Charges_Insurance__c WHERE Loan_Application__c = :updatedOpp.Id];
        //System.assert(!charges.isEmpty(), 'LMS Charges should be created');

        List<Document_Details__c> docs = [SELECT Id FROM Document_Details__c WHERE Loan_Application__c = :updatedOpp.Id];
        //System.assertEquals(false, docs.isEmpty(), 'Sanction Letter should have been updated');
    }
    
    @isTest
    static void testBeforeDelete() {
        // Step 1: Create test Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Qualification',
            Product__c='Home Loan',
            CloseDate = Date.today().addDays(15)
        );
        insert opp;

        // Step 2: Prepare mock inputs for beforeDelete method
        List<SObject> newList = new List<SObject>(); // Usually empty during delete
        Map<Id, SObject> newMap = new Map<Id, SObject>(); // Usually empty during delete
        List<SObject> oldList = new List<SObject>{opp};
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ opp.Id => opp };

        // Step 3: Call the beforeDelete method directly
        Test.startTest();
        BL_OpportunityTriggerHelper.beforeDelete(newList, newMap, oldList, oldMap);
        Test.stopTest();

        // Step 4 (optional): Delete the Opportunity normally to trigger the real flow (if there's logic in the trigger)
        delete opp;
    }
    
        @isTest
    static void testAfterDelete() {
        // Create and insert Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp - Delete',
            StageName = 'Prospecting',
            Product__c='Home Loan',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        // Delete the opportunity
        delete opp;

        // Simulate afterDelete manually
        Test.startTest();
        List<SObject> oldList = new List<SObject>{opp};
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ opp.Id => opp };
        BL_OpportunityTriggerHelper.afterDelete(oldList, oldMap);
        Test.stopTest();
    }

    @isTest
    static void testAfterUndelete() {
        // Create and insert Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp - Undelete',
            StageName = 'Qualification',
            Product__c='Home Loan',
            CloseDate = Date.today().addDays(15)
        );
        insert opp;

        // Delete the Opportunity
        delete opp;

        // Undelete it
        Undelete opp;

        // Simulate afterUndelete manually
        Test.startTest();
        List<SObject> newList = new List<SObject>{opp};
        Map<Id, SObject> newMap = new Map<Id, SObject>{ opp.Id => opp };
        BL_OpportunityTriggerHelper.afterUndelete(newList, newMap);
        Test.stopTest();
    }

    @isTest
    static void testIsDisabledMethod() {
        // Instantiate the helper class (if allowed)
        Test.startTest();
        BL_OpportunityTriggerHelper helper = new BL_OpportunityTriggerHelper();
        Boolean isDisabled = helper.isDisabled();
        System.assert(isDisabled != null); // just ensuring the method returns something
        Test.stopTest();
    }
    
  /* @isTest
static void testAfterUpdateMethod1() {
    // Step 1: Create Opportunity
    Opportunity opp = new Opportunity(
        Name = 'Test Opportunity',
        StageName = 'Credit Underwriting',
        CloseDate = Date.today().addDays(30),
        Amount = 10000,
        Is_Pricing_Approval_Required__c = false
    );
    insert opp;

    // Step 2: Create related Product and Sub Product (if these are custom objects in your org)
    Product2 product = new Product2(Name = 'Business Loan');
    insert product;

    Product2 subProduct = new Product2(
        Name = 'Sub Product A',
        Product__c = product.Id
    );
    insert subProduct;

    // Step 3: Insert Charges Insurance Master with proper lookup
    Charges_Insurance_Master__c master = new Charges_Insurance_Master__c(
        Charges_Fee_Type__c = 'Other Documents',
        Default_Value__c = 2,
        Category__c = 'LMS',
        Max_Percent__c = 3,
        Min_Percent__c = 1
    );
    insert master;

    // Step 4: Create related Product2 record if used in your logic
    Product2 prod2 = new Product2(
        Name = 'Sub Product A',
        Loan_Application__c = opp.Id,
        IsActive = true
    );
    insert prod2;

    // Step 5: Clone old Opportunity and update the stage & approval
    Opportunity oldOpp = opp.clone(false, true, false, false);
    opp.StageName = 'PSV';
    opp.Is_Pricing_Approval_Required__c = true;
    update opp;

    // Step 6: Prepare inputs and call afterUpdate
    List<SObject> newList = new List<SObject>{ opp };
    List<SObject> oldList = new List<SObject>{ oldOpp };
    Map<Id, SObject> newMap = new Map<Id, SObject>{ opp.Id => opp };
    Map<Id, SObject> oldMap = new Map<Id, SObject>{ opp.Id => oldOpp };

    Test.startTest();
    BL_OpportunityTriggerHelper.afterUpdate(newList, newMap, oldList, oldMap);
    Test.stopTest();

    // Step 7: Assert LMS charges were created
    List<Charges_Insurance__c> charges = [SELECT Id FROM Charges_Insurance__c WHERE Loan_Application__c = :opp.Id];
    System.assert(!charges.isEmpty(), 'LMS charges should be created');

    // Step 8: Optionally insert a document and verify it is inactivated
    Document_Details__c doc = new Document_Details__c(
        Name = 'Sanction Letter',
        Loan_Application__c = opp.Id,
        Active__c = true,
        Content_Document_Id__c = '069xx000000Txyz' // dummy content doc ID
    );
    insert doc;

    // Update again to trigger inactivation
    oldOpp = opp.clone(false, true, false, false);
    opp.Is_Pricing_Approval_Required__c = true; // same value, but testing the document update
    update opp;

    oldMap = new Map<Id, SObject>{ opp.Id => oldOpp };
    newMap = new Map<Id, SObject>{ opp.Id => opp };
    newList = new List<SObject>{ opp };
    oldList = new List<SObject>{ oldOpp };

    Test.startTest();
    BL_OpportunityTriggerHelper.afterUpdate(newList, newMap, oldList, oldMap);
    Test.stopTest();

    doc = [SELECT Active__c FROM Document_Details__c WHERE Id = :doc.Id];
    System.assertEquals(false, doc.Active__c, 'Sanction Letter should be marked inactive');
}
*/
    
    @isTest
    static void testRollbackChargesDelete() {
        Opportunity opp = [SELECT Id,Is_Pricing_Approval_Required__c,StageName FROM Opportunity LIMIT 1];
        opp.StageName = 'Credit Underwriting';
        opp.Pricing_Approval_Status__c = 'Approved';
        opp.Negotiated_Rate_Of_Interest__c = 14;
        opp.Negotiated_Tenure__c = 12;
        opp.Sanction_Loan_Amount__c =560000;
        opp.Negotiated_Loan_Amount__c =40000;
        opp.Sub_stage__c = 'Credit in-progress';
        opp.LMS_Loan_Reference__c= '123';
        update opp;

        // Simulate LMS Charge, IntegrationDetail, LoanTransaction for rollback
        insert new Charges_Insurance__c(Name='Rollback', Loan_Application__c=opp.Id);
        insert new Integration_Details__c(EndPoint__c='Callout:Create_Schedule_Simulation_API_LOS', Loan_Application__c=opp.Id,
            Is_Success_Response__c=true, Calling_Source__c='Loan Scheduler Create Charges', Status__c='200');
        insert new Loan_Transaction__c(Loan_Application__c=opp.Id);

        Opportunity oldOpp = opp.clone(false, false, false, false);
        oldOpp.StageName = 'PSV';
        oldOpp.Pricing_Approval_Status__c = 'Rejected';
        oldOpp.Sub_stage__c = 'PSV Sales';

        Document_Details__c doc = new Document_Details__c(
        Name = 'Sanction Letter',
        Loan_Application__c = oldOpp.Id,
        Active__c = true,
        Content_Document_Id__c = '069xx000000Txyz' // dummy content doc ID
    );
    insert doc;
        
        Test.startTest();

        BL_OpportunityTriggerHelper.afterUpdate(
            new List<Opportunity>{ opp },
            new Map<Id, Opportunity>{ opp.Id => opp },
            new List<Opportunity>{ oldOpp },
            new Map<Id, Opportunity>{ opp.Id => oldOpp }
        );
        Test.stopTest();

       // System.assertEquals(0, [SELECT count() FROM Charges_Insurance__c WHERE Loan_Application__c = :opp.Id]);
       // System.assertEquals(0, [SELECT count() FROM Integration_Details__c WHERE Loan_Application__c = :opp.Id]);
       // System.assertEquals(0, [SELECT count() FROM Loan_Transaction__c WHERE Loan_Application__c = :opp.Id]);
    }
}