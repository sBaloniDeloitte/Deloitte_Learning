@IsTest
private class DocGenESignJSONCreator_Test {

    @IsTest
    static void testDocGenESignJSONCreatorStructure() {
        // Create main object
        DocGenESignJSONCreator docGen = new DocGenESignJSONCreator();
        docGen.contentId = 'sdfghj12345';
        docGen.lan = 'GFL3001BL0015103';

        // Fill authSignatoryDetails
        docGen.authSignatoryDetails = new DocGenESignJSONCreator.cls_authSignatoryDetails();
        docGen.authSignatoryDetails.emailID = 'sachin.shah@godrejcapital.com';
        docGen.authSignatoryDetails.mobileNumber = '9876543210';
        docGen.authSignatoryDetails.name = 'Sachin Shah';

        // Fill coApplicantDetails with one applicant
        docGen.coApplicantDetails = new DocGenESignJSONCreator.cls_coApplicantDetails();
        DocGenESignJSONCreator.cls_applicants applicant = new DocGenESignJSONCreator.cls_applicants();
        applicant.emailID = 'amritha@example.com';
        applicant.id = 'APP001';
        applicant.mobileNumber = '9657129890';
        applicant.name = 'Amritha Nikhil';
        docGen.coApplicantDetails.applicants = new List<DocGenESignJSONCreator.cls_applicants>{ applicant };

        // Fill customer details
        docGen.customerDetails = new DocGenESignJSONCreator.cls_customerDetails();
        docGen.customerDetails.emailID = 'dhiraj@example.com';
        docGen.customerDetails.mobileNumber = '9137335330';
        docGen.customerDetails.name = 'Dhiraj Traders';

        // Fill documentAndPageNumbers
        DocGenESignJSONCreator.cls_documentAndPageNumbers docAndPage =
            new DocGenESignJSONCreator.cls_documentAndPageNumbers();
        docAndPage.documentName = 'BLAB';
        docAndPage.pageNumbers = 43;
        docGen.documentAndPageNumbers = new List<DocGenESignJSONCreator.cls_documentAndPageNumbers>{ docAndPage };

        // Fill estampDetails
        DocGenESignJSONCreator.cls_estampDetails est =
            new DocGenESignJSONCreator.cls_estampDetails();
        est.tagName = 'GA-100-GA-100';
        est.tagQuantity = 2;
        docGen.estampDetails = new List<DocGenESignJSONCreator.cls_estampDetails>{ est };

        // Fill DocGenEsigncompleteWrapper
        DocGenESignJSONCreator.DocGenEsigncompleteWrapper esignWrap =
            new DocGenESignJSONCreator.DocGenEsigncompleteWrapper();
        esignWrap.docusignstring = 'Some docusign string';
        esignWrap.signedCoordinates = 'Some coordinates';

        // Exercise JSON serialization & deserialization to test structure
        String jsonString = JSON.serialize(docGen);
        System.debug('Serialized JSON: ' + jsonString);

        // Deserialize back
        DocGenESignJSONCreator docGen2 = (DocGenESignJSONCreator) JSON.deserialize(jsonString, DocGenESignJSONCreator.class);

        // Assertions
        System.assertEquals('sdfghj12345', docGen2.contentId);
        System.assertEquals('Sachin Shah', docGen2.authSignatoryDetails.name);
        System.assertEquals('BLAB', docGen2.documentAndPageNumbers[0].documentName);
        System.assertEquals('GA-100-GA-100', docGen2.estampDetails[0].tagName);
    }
}