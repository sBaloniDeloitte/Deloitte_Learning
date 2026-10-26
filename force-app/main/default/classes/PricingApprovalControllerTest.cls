@isTest
public class PricingApprovalControllerTest {
    
    @testSetup static void setupData(){
        Opportunity oppRec = TestDataFactory.createLoanApplicationRecord('Loan Account Created', 'Home Loan', 'Sales Login', Date.today());
        insert oppRec;
        // Create Main Product (RecordType = 'Product')
        Product2 mainProduct = new Product2();
        mainProduct.Name = 'Main Product';
        mainProduct.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        mainProduct.Loan_Application__c = oppRec.Id;
        insert mainProduct;
        // Create Sub Product (RecordType = 'Sub Product')
        Product2 subProduct = new Product2();
        subProduct.Name = 'Sub Product';
        subProduct.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
        subProduct.Loan_Application__c = oppRec.Id;
        subProduct.Product__c = mainProduct.Id;
        insert subProduct;
        // Create Variant Product (RecordType = 'Variant')
        Product2 variantProduct = new Product2();
        variantProduct.Name = 'variant Product';
        variantProduct.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();
        variantProduct.Loan_Application__c = oppRec.Id;
        variantProduct.Product__c = subProduct.Id;
        insert variantProduct;
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, oppRec.Id, true)[0];
    }
    @isTest static void getMetadataValueTest(){
        PricingApprovalController.getMetadataValue('CIBIL_API');
    }
    @isTest static void loanRecordTest(){
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];
        PricingApprovalController.getLoanRecords(oppRec.Id);
        PricingApprovalController.getLatestLoanRecords(oppRec.Id);
        PricingApprovalController.resetResanctionFlag(oppRec.Id);
		PricingApprovalController.submitforResanction(oppRec.Id);        
    }
    @isTest static void getChargesApprovalCriteriaTest(){
        PricingApprovalController.getChargesApprovalCriteria();
    }
	@isTest static void testUpdateNegotiatedValues() {
        Opportunity oppRec = [SELECT Id, StageName, CloseDate FROM Opportunity LIMIT 1];
        oppRec.Sanction_Loan_Amount__c = 100000.00;
        oppRec.Sanction_Rate_Of_Interest__c = 10.0;
        oppRec.Sanction_Tenure__c = 12.0;
		update oppRec;
        Map<String, Object> updatedFields = new Map<String, Object> {
            'Negotiated_Loan_Amount__c' => '80000.00',
            'Negotiated_Rate_Of_Interest__c' => '8.0',
            'Negotiated_Tenure__c' => '10.0'
        };
        PricingApprovalController.updateNegotiatedValues(oppRec.Id, updatedFields);
        Opportunity updatedOpp = [SELECT Id, Negotiated_Loan_Amount__c, 
                                 Negotiated_Rate_Of_Interest__c, Negotiated_Tenure__c,
                                 Final_Amount__c, Final_Rate_Of_Interest__c, Final_Tenure__c
                                 FROM Opportunity WHERE Id = :oppRec.Id];
        
        System.assertEquals(80000.00, updatedOpp.Negotiated_Loan_Amount__c);
        System.assertEquals(8.0, updatedOpp.Negotiated_Rate_Of_Interest__c);
        System.assertEquals(10.0, updatedOpp.Negotiated_Tenure__c);
        System.assertEquals(80000.00, updatedOpp.Final_Amount__c);
        System.assertEquals(10.0, updatedOpp.Final_Tenure__c);
    }    
    @isTest static void getVariantRecordTest() {
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];
        List<Product2> productRecordList = [SELECT Id, Name, Loan_Application__c, Product__c, RecordType.Name FROM Product2];
        Product2 result = PricingApprovalController.getVariantRecord('Main Product', oppRec.Id);

    }
    @isTest static void getCustomerProfileTest(){
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];
        PricingApprovalController.getCustomerProfile(oppRec.Id);
    }
}