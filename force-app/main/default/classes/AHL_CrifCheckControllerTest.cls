@isTest
public class AHL_CrifCheckControllerTest {
    @testSetup static void setupData(){
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        Document_Master__c docMaster = new Document_Master__c(
            Document_Name__c = 'Driving License',
            Name = 'Driving License',
            Is_Active__c = true,
            Document_Category__c = 'KYC',
            Is_Required__c = false,
            Product__c = 'Business Loan',
            Requirement_At__c = 'Loan Application',
            Requirement_Level__c= 'Loan Application Level',
            Mandatory_Non_Mandatory__c='Required',
            Stage__c='Sales login',
            Document_Type__c = 'Proof of practice',
            Eligible_For_FCU__c = true
        );
        insert docMaster;
        Document_Details__c doc1 = new Document_Details__c(
            Loan_Application__c = loan.Id,
            Applicant__c=applicant.Id,
            Name = 'CRIF',
            Document_Master__c = docMaster.Id,
            Verification_Status__c = 'Pending',
            Active__c = true,
            Status__c = null,
            Requirement_Level__c = 'Applicant Level'
        );
        insert doc1;
    }
    @isTest
    static void testCanFetchCrif_NullLoanAppId() {
        Test.startTest();
        AHL_CrifCheckController.GateResult result = AHL_CrifCheckController.canFetchCrif(null);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(false, result.okToFetch);
        System.assertEquals(null, result.lastCreated);
    }

    @isTest
    static void testCanFetchCrif_NoRecentCRIFDoc() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        Test.startTest();
        AHL_CrifCheckController.GateResult result = AHL_CrifCheckController.canFetchCrif(loan.Id);
        Test.stopTest();

        System.assertEquals(true, result.okToFetch);
        System.assertEquals(null, result.lastCreated);
    }

    @isTest
    static void testCanFetchCrif_WithRecentCRIFDoc() {
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];
       Test.startTest();
        AHL_CrifCheckController.GateResult result = AHL_CrifCheckController.canFetchCrif(oppRec.Id);
        Test.stopTest();
        
    }
}