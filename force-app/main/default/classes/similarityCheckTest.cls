@isTest
public class similarityCheckTest {
    @TestSetup
    static void makeData(){
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        List<Opportunity> oppRecList = TestDataFactory.getTestOpportunityData(1, false);
        oppRecList[0].Branch_Master__c = customer.Id;
        insert oppRecList;
          Application_Applicant__c applicant = FITestDataFactory.createApplicant2(oppRecList[0], false);
        applicant.Customer_Type__c = 'Non Individual';
        insert applicant;

         Document_Details__c doc = new Document_Details__c(
            Name = 'Doc - UT',
            Loan_Application__c = oppRecList[0].Id,

            Active__c = false,
            Consider_for_Loan_Application__c = false
        );
        insert doc;
        
    }


    private static Id createContentDocumentId() {
        ContentVersion cv = new ContentVersion(
            Title        = 'UnitTestFile',
            PathOnClient = 'UnitTestFile.txt',
            VersionData  = Blob.valueOf('Dummy content for unit test')
        );
        insert cv;

        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        return cv.ContentDocumentId;
    }

    @IsTest
    static void test_insertFileRecord_positive() {

        Id contentDocumentId = createContentDocumentId();
        Opportunity loan = [SELECT Id FROM Opportunity LIMIT 1];
        Document_Details__c doc = [SELECT ID FROM Document_Details__c LIMIT 1];

        Test.startTest();
        similarityCheck.insertFileRecord(
            String.valueOf(contentDocumentId),
            String.valueOf(doc.Id),
            String.valueOf(loan.Id)
        );
        Test.stopTest();

        ContentDocumentLink cdl = [
            SELECT Id, ContentDocumentId, LinkedEntityId, ShareType, Visibility
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :doc.Id
            LIMIT 1
        ];
        System.assertEquals(contentDocumentId, cdl.ContentDocumentId, 'CDL should reference the ContentDocument.');
        System.assertEquals('I', cdl.ShareType, 'ShareType should be "I".');
        System.assertEquals('AllUsers', cdl.Visibility, 'Visibility should be "AllUsers".');

        Document_Details__c updatedDoc = [
            SELECT Id, Content_Document_Id__c, Status__c, Active__c,
                   Consider_for_Loan_Application__c, Loan_Application__c,
                   Applicant__c, Uploaded_Date_Time__c
            FROM Document_Details__c
            WHERE Id = :doc.Id
        ];
        System.assertEquals(contentDocumentId, updatedDoc.Content_Document_Id__c);
        System.assertEquals('Uploaded', updatedDoc.Status__c);
        System.assertEquals(true, updatedDoc.Active__c);
        System.assertEquals(true, updatedDoc.Consider_for_Loan_Application__c);
        System.assertEquals(loan.Id, updatedDoc.Loan_Application__c);
        System.assertEquals(Date.today(), updatedDoc.Uploaded_Date_Time__c, 'Uploaded date should be today.');
    }



    @isTest
    static void testGetNormalizedLevenshtein_SimilarStrings() {
        String s1 = 'Salesforce';
        String s2 = 'salesforce';
        Decimal similarity = similarityCheck.getNormalizedLevenshtein(s1, s2);
        System.assertEquals(1, similarity, 'Strings differing only in case should have similarity 1');
    }

    @isTest
    static void testGetNormalizedLevenshtein_DifferentStrings() {
        String s1 = 'Salesforce';
        String s2 = 'Trailhead';
        Decimal similarity = similarityCheck.getNormalizedLevenshtein(s1, s2);
        System.assert(similarity < 1, 'Completely different strings should have similarity less than 1');
        System.assert(similarity >= 0, 'Similarity should not be negative');
    }

    @isTest
    static void testGetNormalizedLevenshtein_PartialSimilarity() {
        String s1 = 'kitten';
        String s2 = 'sitting';
        Decimal similarity = similarityCheck.getNormalizedLevenshtein(s1, s2);
        System.assert(similarity > 0 && similarity < 1, 'Partially similar strings should have similarity between 0 and 1');
    }

    @isTest
    static void testGetNormalizedLevenshtein_BlankInputs() {
        Decimal sim1 = similarityCheck.getNormalizedLevenshtein(null, 'test');
        Decimal sim2 = similarityCheck.getNormalizedLevenshtein('test', '');
        Decimal sim3 = similarityCheck.getNormalizedLevenshtein('', null);
        Decimal sim4 = similarityCheck.getNormalizedLevenshtein(null, null);

        System.assertEquals(0, sim1, 'Null input should return similarity 0');
        System.assertEquals(0, sim2, 'Blank input should return similarity 0');
        System.assertEquals(0, sim3, 'Blank input should return similarity 0');
        System.assertEquals(0, sim4, 'Null inputs should return similarity 0');
    }
}