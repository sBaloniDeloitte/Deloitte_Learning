@IsTest
public class BuilderSellerUploadTest {

    @TestSetup
    static void setupData() {

        // Loan Application (Opportunity)
        Opportunity loanApp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Sales Login',
            CloseDate = Date.today().addDays(10),
            Product__c='Home Loan'
        );
        insert loanApp;

        // Seller Applicant
        Application_Applicant__c sellerApplicant = new Application_Applicant__c(
            Name = 'Test Seller',
            Applicant_Type__c = 'Seller',
            Is_Financial_applicant__c = 'Yes',
            Loan_Application__c = loanApp.Id
        );
        insert sellerApplicant;

        // Document Master
        Document_Master__c docMaster = new Document_Master__c(
            Name = 'Seller KYC',
            Document_Category__c = 'Applicant Level',
            Requirement_At__c = 'Applicant Level',
            Document_Name__c ='Seller KYC'
        );
        insert docMaster;
    }

    /**
     * Covers path where NO existing document exists
     * → new Document_Details__c is inserted
     */
    @IsTest
    static void testUploadDocument_NewDocument() {

        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c seller = [
            SELECT Id FROM Application_Applicant__c WHERE Applicant_Type__c = 'Seller' LIMIT 1
        ];

        Map<String, String> inputMap = new Map<String, String>{
            'applicantId'   => seller.Id,
            'applicationId'=> loan.Id
        };

        Test.startTest();
        Document_Details__c doc =
            BuilderSellerDocumentUploadController.uploadDocumentInSeller(inputMap);
        Test.stopTest();

        System.assertNotEquals(null, doc, 'Document should be created');
        System.assertEquals('Seller KYC', doc.Name);
        System.assertEquals(seller.Id, doc.Applicant__c);
        System.assertEquals(loan.Id, doc.Loan_Application__c);
    }

    /**
     * Covers path where existing document exists
     * → return latest existing document
     */
    @IsTest
    static void testUploadDocument_ExistingDocument() {

        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c seller = [
            SELECT Id FROM Application_Applicant__c WHERE Applicant_Type__c = 'Seller' LIMIT 1
        ];
        Document_Master__c docMaster = [
            SELECT Id FROM Document_Master__c WHERE Name = 'Seller KYC' LIMIT 1
        ];

        // Existing Document
        Document_Details__c existingDoc = new Document_Details__c(
            Name = 'Seller KYC',
            Applicant__c = seller.Id,
            Loan_Application__c = loan.Id,
            Document_Master__c = docMaster.Id
        );
        insert existingDoc;

        Map<String, String> inputMap = new Map<String, String>{
            'applicantId'   => seller.Id,
            'applicationId'=> loan.Id
        };

        Test.startTest();
        Document_Details__c returnedDoc =
            BuilderSellerDocumentUploadController.uploadDocumentInSeller(inputMap);
        Test.stopTest();

        System.assertEquals(existingDoc.Id, returnedDoc.Id,
            'Existing document should be returned');
    }

    /**
     * Covers getContentVersionURL()
     */
    @IsTest
    static void testGetContentVersionURL() {

        // Create ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = 'SellerKYC',
            PathOnClient = 'SellerKYC.pdf',
            VersionData = Blob.valueOf('Test File Data')
        );
        insert cv;

        ContentVersion insertedCV = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        Test.startTest();
        Map<String, String> result =
            BuilderSellerDocumentUploadController.getContentVersionURL(
                insertedCV.ContentDocumentId
            );
        Test.stopTest();

        System.assertEquals('SellerKYC', result.get('title'));
        System.assert(result.get('downloadUrl') != null,
            'Download URL should not be null');
    }
}