@IsTest
public class TechnicalEvaluationPDFControllerTest {
    
    @TestSetup
    static void setupData() {
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        // Create Technical Evaluation
        Technical_Evaluation__c techEval = new Technical_Evaluation__c(
            HL_Loan_Application__c = loanApp.Id,
            Area_Government__c = 100,
            Rate_Government__c = 50,
            DLC_Value_in_Rs__c = 5000,
            Area_Fair_Market__c = 100,
            Rate_Fair_Market__c = 60,
            Market_Value_in_Rs_Fair_Market__c = 6000,
            Area_Post_Completion__c = 120,
            Rate_Post_Completion__c = 70,
            Market_Value_in_Rs_Post_Completion__c = 8400
        );
        insert techEval;
        
        // Create Technical Detail Records
        List<Technical_Detail__c> details = new List<Technical_Detail__c>();
        
        details.add(new Technical_Detail__c(
            Technical_Evaluation__c = techEval.Id,
            Sections__c = 'Property Details',
            Floor__c = 'GF',
            As_per_Plan_BUA_SFT__c = 100,
            Actual_BUA_SFT__c = 95,
            Documented_Area_SFT__c = 90,
            Permissible_Area_SFT__c = 100,
            Adopted_Area_for_Valuation_SFT__c = 90,
            Area__c = 100,
            Rate__c = 50,
            Market_Value_in_Rs_Government__c = 5000,
            Area_Fair_Market_Value__c = 100,
            Rate_Fair_Market_Value__c = 60,
            Market_Value_in_Rs__c = 6000,
            Area_Post_Completion__c = 120,
            Rate_Post_Completion__c = 70,
            Market_Value_Post_Completion__c = 8400
        ));
        
        details.add(new Technical_Detail__c(
            Technical_Evaluation__c = techEval.Id,
            Sections__c = 'Dimension of Property (For Land & Building , Offices & Shops)',
            Property_Details_Category__c = 'Boundaries Details'
        ));
        
        details.add(new Technical_Detail__c(
            Technical_Evaluation__c = techEval.Id,
            Sections__c = 'Proposed Estimate of Project',
            Floor__c = 'FF',
            Estimation_as_per_Customer_sqft__c = 200,
            Vetted_Estimation_Permissible_sqft__c = 180
        ));
        
        insert details;
        
        // Create Applicant
        Application_applicant__c applicant = new Application_applicant__c(
            Name = 'Primary Applicant',
            Loan_Application__c = loanApp.Id,
            Applicant_Type__c = 'Primary Applicant',
            Mobile_Number__c = '9999999999'
        );
        insert applicant;
        
        // Create ContentVersion (Photo Section)
        ContentVersion cv = new ContentVersion(
            Title = 'Test Image',
            PathOnClient = 'test.jpg',
            VersionData = Blob.valueOf('Test Data')
        );
        insert cv;
        
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        Document_Details__c doc = new Document_Details__c(
            Name = 'Test Photo',
            Technical__c = techEval.Id,
            Content_Document_Id__c = cv.ContentDocumentId
        );
        insert doc;
    }
    
    @IsTest
    static void testConstructor() {
        
        Technical_Evaluation__c techEval =
            [SELECT Id FROM Technical_Evaluation__c LIMIT 1];
        
        Test.startTest();
        
        ApexPages.StandardController sc =
            new ApexPages.StandardController(techEval);
        
        TechnicalEvaluationPDFController controller =
            new TechnicalEvaluationPDFController(sc);
        
        Test.stopTest();
        
        System.assertNotEquals(null, controller.techEval);
        System.assert(controller.floorDetails.size() > 0);
        System.assert(controller.governmentValues.size() > 0);
        System.assert(controller.fairMarketValues.size() > 0);
        System.assert(controller.postCompletionValues.size() > 0);
        System.assert(controller.photoRows.size() >= 0);
    }
    
    @IsTest
    static void testGenerateAndSavePDF() {
        
        Technical_Evaluation__c techEval =
            [SELECT Id FROM Technical_Evaluation__c LIMIT 1];
        
        Test.startTest();
        
        Map<String, String> result =
            TechnicalEvaluationPDFController.generateAndSavePDF(techEval.Id);
        
        Test.stopTest();
        
        System.assert(result.containsKey('ContentVersionId'));
        System.assert(result.containsKey('ContentDocumentId'));
        
        Technical_Evaluation__c updated =
            [SELECT Is_Report_Uploaded__c FROM Technical_Evaluation__c WHERE Id = :techEval.Id];
        
        System.assertEquals(true, updated.Is_Report_Uploaded__c);
        
        List<Document_Details__c> docs =
            [SELECT Id FROM Document_Details__c WHERE Technical__c = :techEval.Id
             AND Name = 'Technical Report'];
        
        System.assert(docs.size() > 0);
    }
     @IsTest
    static void testFetchAllProducts() {
        Id productRT = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Id subProductRT = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
        Id variantRT = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();
        Id subVariantRT = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Variant').getRecordTypeId();
        Opportunity loan =[select id from opportunity limit 1];
        Technical_Evaluation__c technical =[SELECT id FROM Technical_Evaluation__c limit 1];
        Product2 mainProduct = new Product2(
            Name = 'Home Loan',
            RecordTypeId = productRT,
            IsActive = true,
            Loan_Application__c = loan.Id
        );
        insert mainProduct;

        Product2 subProduct = new Product2(
            Name = 'Home Loan Sub',
            RecordTypeId = subProductRT,
            IsActive = true,
            Product__c = mainProduct.Id,
            Loan_Application__c = loan.Id,
            Loan_Purpose__c = 'Purchase'
        );
        insert subProduct;

        Product2 variant = new Product2(
            Name = 'EMI Variant',
            RecordTypeId = variantRT,
            IsActive = true,
            Product__c = subProduct.Id,
            Loan_Application__c = loan.Id
        );
        insert variant;

        Product2 subVariant = new Product2(
            Name = 'Fixed EMI',
            RecordTypeId = subVariantRT,
            IsActive = true,
            Product__c = subProduct.Id,
            Loan_Application__c = loan.Id
        );
        insert subVariant;

        Test.startTest();
        List<TechnicalEvaluationPDFController.ProductWrapper> result =TechnicalEvaluationPDFController.fetchAllProducts(technical.Id);
        Test.stopTest();
    }
}