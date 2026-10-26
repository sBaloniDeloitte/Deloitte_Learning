@isTest
public with sharing class DigitalSignatureControllerTest {

    @testSetup
    static void setupData() {

        // Create Technical Evaluation record
        Technical_Evaluation__c tech = new Technical_Evaluation__c(
            // Name = 'Test Technical Evaluation',
            Is_Signature_Generated__c = false
        );
        insert tech;

        // Create ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv;
    }

    @isTest
    static void testCheckSigned() {

        Technical_Evaluation__c tech = [
            SELECT Id, Is_Signature_Generated__c
            FROM Technical_Evaluation__c
            LIMIT 1
        ];

        Test.startTest();
        Boolean result = DigitalSignatureController.checkSigned(tech.Id);
        Test.stopTest();

        System.assertEquals(false, result);
    }

    @isTest
    static void testCreateDocumentDetail() {

        Technical_Evaluation__c tech = [
            SELECT Id
            FROM Technical_Evaluation__c
            LIMIT 1
        ];

        ContentVersion cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            LIMIT 1
        ];

        Test.startTest();
        DigitalSignatureController.createDocumentDetail(
            UserInfo.getUserId(),
            cv.Id
        );
        Test.stopTest();

        User usr = [
            SELECT FirstName
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];

        String expectedName = 'Digital Signature-' + usr.FirstName;

        List<Document_Details__c> docs = [
            SELECT Id,
                   Name,
                   Content_Document_Id__c,
                   Content_Version_Id__c,
                   Referred_By__c
            FROM Document_Details__c
            WHERE Name = :expectedName
        ];

        System.assertEquals(1, docs.size());
        System.assertEquals(cv.ContentDocumentId, docs[0].Content_Document_Id__c);
        System.assertEquals(cv.Id, docs[0].Content_Version_Id__c);

        List<ContentDocumentLink> links = [
            SELECT Id, LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :docs[0].Id
        ];

        System.assertEquals(1, links.size());
    }

    @isTest
    static void testGeneratePDF() {

        Technical_Evaluation__c tech = [
            SELECT Id, Is_Signature_Generated__c
            FROM Technical_Evaluation__c
            LIMIT 1
        ];

        ContentVersion cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            LIMIT 1
        ];

        User usr = [
            SELECT FirstName
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];

        // Create Document Detail record
        Document_Details__c doc = new Document_Details__c(
            Name = 'Digital Signature-' + usr.FirstName,
            Referred_By__c = UserInfo.getUserId(),
            Content_Document_Id__c = cv.ContentDocumentId,
            Content_Version_Id__c = cv.Id
        );
        insert doc;

        Test.startTest();
        String result = DigitalSignatureController.generatePDF(tech.Id);
        Test.stopTest();

        System.assertEquals('success', result);

        Technical_Evaluation__c updatedTech = [
            SELECT Is_Signature_Generated__c
            FROM Technical_Evaluation__c
            WHERE Id = :tech.Id
        ];

        System.assertEquals(true, updatedTech.Is_Signature_Generated__c);

        Document_Details__c updatedDoc = [
            SELECT Technical__c
            FROM Document_Details__c
            WHERE Id = :doc.Id
        ];

        System.assertEquals(tech.Id, updatedDoc.Technical__c);
    }

    @isTest
    static void testGetLatestFile() {

        ContentVersion cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            LIMIT 1
        ];

        User usr = [
            SELECT Id, FirstName
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];

        Document_Details__c doc = new Document_Details__c(
            Name = 'Digital Signature-' + usr.FirstName,
            Referred_By__c = usr.Id,
            Content_Document_Id__c = cv.ContentDocumentId,
            Content_Version_Id__c = cv.Id
        );
        insert doc;

        Test.startTest();
        Map<String, String> result =
            DigitalSignatureController.getLatestFile(usr.Id);
        Test.stopTest();

        System.assertEquals(cv.ContentDocumentId, result.get('contentId'));
        System.assertEquals(cv.ContentDocumentId, result.get('documentId'));
    }
}