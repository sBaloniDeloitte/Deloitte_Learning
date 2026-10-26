@IsTest
private class OpportunityUtilityTest {
    
    @TestSetup
    static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Email='testuser@example.com',
            LastName='Test',
            Alias='tuser',
            TimeZoneSidKey='Asia/Kolkata',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey='en_US'
        );
        insert u;
        
        System.runAs(u) {
            // Create Opportunity
            Opportunity opp = new Opportunity(
                Name = 'Test Opp',
                StageName = 'Credit Underwriting',
                Sub_stage__c = 'PSV Sales',
                CloseDate = Date.today(),
                Product__c = 'Affordable Home Loan'
            );
            insert opp;
            // Main Product (RecordType = 'Product')
            Product2 mainProduct = new Product2(
                Name = opp.Product__c, // must match Opportunity.Product__c
                RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Product' LIMIT 1].Id,
                Loan_Application__c = opp.Id
            );
            insert mainProduct;
            
            // Sub Product
            Product2 subProduct = new Product2(
                Name = 'Affordable Home Sub',
                RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Sub Product' LIMIT 1].Id,
                Product__c = mainProduct.Id,
                Loan_Application__c = opp.Id
            );
            insert subProduct;
            
            // Variant (note: DeveloperName must be 'Variant')
            Product2 variantProduct = new Product2(
                Name = 'Variant 1',
                RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND DeveloperName='Variant' LIMIT 1].Id,
                Product__c = subProduct.Id,
                Loan_Application__c = opp.Id
            );
            insert variantProduct;
            
            // Integration Details for Loan Start Date
            Integration_Details__c objintegrationDetails = new Integration_Details__c();
            objintegrationDetails.Loan_Application__c = opp.id;
            objintegrationDetails.Name = 'Fetch Application Date';
            objintegrationDetails.Endpoint__c = 'SLSF_SALES';
            objintegrationDetails.Communication_Status__c = 'Published';
            insert objintegrationDetails;
            
                        
            
            // Application Applicant
            Application_Applicant__c applicant = new Application_Applicant__c(
                Loan_Application__c = opp.Id,
                Applicant_Type__c = 'Primary Applicant',
                Customer_Type__c = 'Individual',
                First_Name__c = 'Test',
                Last_Name__c = 'User',
                Mobile_Number__c = '9999999999',
                Email__c = 'test@example.com',
                Customer__c = null
            );
            insert applicant;
            Product_Master__c prod = new Product_Master__c(
                Name = 'Sub Product A',
                RecordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Variant').getRecordTypeId()
            );
            insert prod;
            
            Charges_Insurance_Master__c cim = new Charges_Insurance_Master__c(
                Charges_Fee_Type__c = 'Miscellaneous charges',
                Default_Value__c = 2,
                Max_Percent__c = 4,
                Min_Percent__c = 1,
                Category__c = 'LMS',
                Sub_Product__c = prod.Id
            );
            insert cim;
            
                    Screen_Field__c field1 = new Screen_Field__c(
                Form_Name__c = 'Loan Details',
                Loan_Type__c = 'Affordable Home Loan',
                Screen_Object__c = 'Loan_Transaction__c',
                Master_Screen_Name__c = 'Basic Details',
                Screen_Name__c = 'Basic Details',
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
                Screen_Name__c = 'Basic Details',
                Loan_Type__c = 'Affordable Home Loan',
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
            
            // Already inserted Date field (Loan_Start_Date__c)
            // Now add more Screen_Field__c records for other data types:
            
            List<Screen_Field__c> extraFields = new List<Screen_Field__c>();
            
            // Integer
            extraFields.add(new Screen_Field__c(
                Form_Name__c = 'Loan Details',
                Parent_Screen__c = field1.Id,
                Screen_Name__c = 'Basic Details',
                Loan_Type__c = 'Affordable Home Loan',
                Screen_Object__c = 'Loan_Transaction__c',
                Field_Label__c = 'Number of Instruments',
                Is_Active__c = true,
                Storage_Object__c = 'Loan_Transaction__c',
                Storage_Field__c = 'Number_of_Instruments__c', // must exist on Loan_Transaction__c
                Field_Type__c = 'Number',
                Default_Value__c = '12'
            ));
            
            // Double
            extraFields.add(new Screen_Field__c(
                Form_Name__c = 'Loan Details',
                Parent_Screen__c = field1.Id,
                Screen_Name__c = 'Basic Details',
                Loan_Type__c = 'Affordable Home Loan',
                Screen_Object__c = 'Loan_Transaction__c',
                Field_Label__c = 'Total Demand Received (Inc Curr Receipt)',
                Is_Active__c = true,
                Storage_Object__c = 'Loan_Transaction__c',
                Storage_Field__c = 'Total_Demand_Received__c', // must exist
                Field_Type__c = 'Number',
                Default_Value__c = '8.5'
            ));
            
            // Boolean
            extraFields.add(new Screen_Field__c(
                Form_Name__c = 'Loan Details',
                Parent_Screen__c = field1.Id,
                Screen_Name__c = 'Basic Details',
                Loan_Type__c = 'Affordable Home Loan',
                Screen_Object__c = 'Loan_Transaction__c',
                Field_Label__c = 'Pay on Interest Frequency',
                Is_Active__c = true,
                Storage_Object__c = 'Loan_Transaction__c',
                Storage_Field__c = 'Pay_on_Interest_Frequency__c',
                Field_Type__c = 'Boolean',
                Default_Value__c = 'true'
            ));
            
            // DateTime
            extraFields.add(new Screen_Field__c(
                Form_Name__c = 'Loan Details',
                Parent_Screen__c = field1.Id,
                Screen_Name__c = 'Basic Details',
                Loan_Type__c = 'Affordable Home Loan',
                Screen_Object__c = 'Loan_Transaction__c',
                Field_Label__c = 'Last Updated',
                Is_Active__c = true,
                Storage_Object__c = 'Loan_Transaction__c',
                Storage_Field__c = 'Sanction_Letter_Generated_Time__c',
                Field_Type__c = 'datetime',
                Default_Value__c = '2025-04-01 18:30:00'
            ));
            
            // Fallback (Text)
            extraFields.add(new Screen_Field__c(
                Form_Name__c = 'Loan Details',
                Parent_Screen__c = field1.Id,
                Screen_Name__c = 'Basic Details',
                Loan_Type__c = 'Affordable Home Loan',
                Screen_Object__c = 'Loan_Transaction__c',
                Field_Label__c = 'Grace Base Rate Code',
                Is_Active__c = true,
                Storage_Object__c = 'Loan_Transaction__c',
                Storage_Field__c = 'Grace_Base_Rate_Code__c',
                Field_Type__c = 'Text',
                Default_Value__c = 'Some'
            ));
            
            insert extraFields;

        }
    }
    
    @IsTest
    static void testCreateLoanTransaction() {
        Opportunity opp = [SELECT Id,Product__c  FROM Opportunity LIMIT 1];
        
        Test.startTest();
        OpportunityUtility.createLoanTransaction(new List<Opportunity>{opp});
        Test.stopTest();
        
        List<Loan_Transaction__c> loans = [SELECT Id, Loan_Application__c FROM Loan_Transaction__c WHERE Loan_Application__c = :opp.Id];
        //System.assertEquals(1, loans.size(), 'Loan Transaction should be created');
    }
        
    @IsTest
    static void testUpdateLMSChargesBasedOnProductChange() {
        Opportunity opp = [SELECT Id,Product__c FROM Opportunity LIMIT 1];
        
        Test.startTest();
        OpportunityUtility.updateLMSChargesBasedOnProductChange(new List<Opportunity>{opp});
        Test.stopTest();
        
        List<Charges_Insurance__c> charges = [SELECT Id, Loan_Application__c FROM Charges_Insurance__c WHERE Loan_Application__c = :opp.Id];
        //System.assert(!charges.isEmpty(), 'LMS Charges should be created');
    }
    
    @IsTest
    static void testCreateSantionLetterEventRecord() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Loan_Transaction__c txn = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Loan_Transaction__c' AND Name='Transaction Details' LIMIT 1].Id
        );
        insert txn;
        
        Document_Details__c doc = new Document_Details__c(
            Loan_Application__c = opp.Id,
            Name = 'Sanction Letter',
            Active__c = true
        );
        insert doc;
        
        Test.startTest();
        OpportunityUtility.createSantionLetterEventRecord(new Set<Id>{opp.Id}, true);
        Test.stopTest();
        
        Loan_Transaction__c updatedTxn = [SELECT Id, Sanction_Letter_Generated_Time__c FROM Loan_Transaction__c WHERE Id = :txn.Id];
        //System.assertNotEquals(null, updatedTxn.Sanction_Letter_Generated_Time__c, 'Sanction Letter Generated Time should be set');
    }
    
    @IsTest
    static void testUpdateProduct2FieldsOnStageChange() {
        Opportunity opp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Product__c = 'Home loan'
        );
        insert opp;
        Id subProductRTId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
        Product2 subProd = new Product2(
            Name = 'Test Sub Product',
            RecordTypeId = subProductRTId,
            Loan_Application__c = opp.Id,
            Sanctioned_Loan_Amount__c = 500000,
            Sanctioned_ROI__c = 8.5,
            Sanctioned_Tenor__c = 240
        );
        insert subProd;
        Test.startTest();
        	OpportunityUtility.updateProduct2FieldsOnStageChange(new List<Opportunity>{ opp });
        	OpportunityUtility.updateProduct2FieldsAfterApproval(new List<Opportunity>{ opp });
        Test.stopTest();
	}
}