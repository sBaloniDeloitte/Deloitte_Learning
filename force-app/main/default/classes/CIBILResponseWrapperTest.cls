@isTest
public class CIBILResponseWrapperTest {

    @isTest
    static void testDeserializeSuccess() {
        // Sample valid JSON based on wrapper structure
        String sampleJson = '{'+
            '"leadcibilid":12345,'+
            '"applicationkey":67890,'+
            '"leadid":111,'+
            '"cibilapplicationid":"APP123",'+
            '"cibildocumentid":"DOC456",'+
            '"cibilresponse":{'+
                '"EnquiryControlNumber":"ECN789",'+
                '"ApplicationReferenceNumber":"REF987",'+
                '"Version":"1.0",'+
                '"TimeProcessed":"10:30:00",'+
                '"DateProcessed":"2025-10-03",'+
                '"SegmentTag":"SEG1",'+
                '"SubjectReturnCode":"00",'+
                '"EnquiryMemberUserID":"USER123"'+
            '}'+
        '}';

        Test.startTest();
        CIBILResponseWrapper.CIBILResponse resp = 
            CIBILResponseWrapper.getDeserializedResponse(sampleJson);
        Test.stopTest();

        // Assertions to validate deserialization
        System.assertNotEquals(null, resp, 'Response should not be null');
        System.assertEquals(12345, resp.leadcibilid, 'Lead CIBIL ID mismatch');
        System.assertEquals(67890, resp.applicationkey, 'Application key mismatch');
        System.assertEquals('APP123', resp.cibilapplicationid, 'Application ID mismatch');
        System.assertEquals('DOC456', resp.cibildocumentid, 'Document ID mismatch');

        // Validate nested object (CIBILHeader)
        System.assertNotEquals(null, resp.cibilresponse, 'CIBILHeader should not be null');
        System.assertEquals('ECN789', resp.cibilresponse.EnquiryControlNumber);
        System.assertEquals('REF987', resp.cibilresponse.ApplicationReferenceNumber);
        System.assertEquals('USER123', resp.cibilresponse.EnquiryMemberUserID);
    }

    @isTest
    static void testDeserializeFailure() {
        // Invalid JSON to force exception
        String invalidJson = 'Invalid JSON Text';
        try {
            CIBILResponseWrapper.getDeserializedResponse(invalidJson);
            System.assert(false, 'Script-thrown exception');
        } catch (Exception e) {
            System.assert(
                e.getMessage().contains('Script-thrown exception'),
                'Expected error message not found. Actual: ' + e.getMessage()
            );
        }
    }
}