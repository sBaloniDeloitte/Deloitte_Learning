@IsTest
public class AHL_ScorecardHandlerTest {

    /* -----------------------------------------------------------
       Helper Method : Create Test Data
    ------------------------------------------------------------*/
    private static Id createCRIFDocument(Id loanAppId, Id applicantId) {

        // Create ContentVersion (File)
        ContentVersion cv = new ContentVersion();
        cv.Title = 'CRIF Test File';
        cv.PathOnClient = 'crif.json';
        cv.VersionData = Blob.valueOf(
            '{"test_key":"value","another_key":{"inner_key":"data"}}'
        );
        insert cv;

        // Get ContentDocumentId
        cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        // Create Document_Details__c
        Document_Details__c doc = new Document_Details__c(
            Name = 'CRIF Response',
            Loan_Application__c = loanAppId,
            Applicant__c = applicantId,
            Content_Document_Id__c = cv.ContentDocumentId
        );
        insert doc;

        return doc.Id;
    }

    /* -----------------------------------------------------------
       TEST validatePayload() - Error Scenario
    ------------------------------------------------------------*/
    @IsTest
    static void testValidatePayload_Error() {

        IntHandler.ProcessReqWrapper wrapper =
            new IntHandler.ProcessReqWrapper();

        wrapper.loanApplicationId = 'a00123456789001';
        wrapper.applicantId = 'a01123456789001';

        Test.startTest();
        List<String> errors =
            AHL_ScorecardHandler.validatePayload(wrapper);
        Test.stopTest();

        System.assertEquals(1, errors.size());
        System.assertEquals('Please hit crif first.', errors[0]);
    }

    /* -----------------------------------------------------------
       TEST validatePayload() - Success Scenario
    ------------------------------------------------------------*/
    @IsTest
    static void testValidatePayload_Success() {


        // Loan Application (replace object if custom)
        Opportunity loan =
            new Opportunity(Name='Test Loan',Product__c = 'Home Loan');
        insert loan;

        // Create Applicant (replace with correct object if different)
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',Loan_Application__c = loan.Id
        );
        insert applicant;

        createCRIFDocument(loan.Id, applicant.Id);

        IntHandler.ProcessReqWrapper wrapper =
            new IntHandler.ProcessReqWrapper();

        wrapper.loanApplicationId = loan.Id;
        wrapper.applicantId = applicant.Id;

        Test.startTest();
        List<String> errors =
            AHL_ScorecardHandler.validatePayload(wrapper);
        Test.stopTest();

        System.assertEquals(0, errors.size());
    }

    /* -----------------------------------------------------------
       TEST constructPayload()
    ------------------------------------------------------------*/
    @IsTest
    static void testConstructPayload() {

        // Loan Application
        Opportunity loan =
            new Opportunity(Name='Test Loan',Product__c = 'Home Loan');
        insert loan;

        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',Loan_Application__c = loan.Id
        );
        insert applicant;

        createCRIFDocument(loan.Id, applicant.Id);

        IntHandler.ProcessReqWrapper wrapper =
            new IntHandler.ProcessReqWrapper();

        wrapper.loanApplicationId = loan.Id;
        wrapper.applicantId = applicant.Id;

        AHL_ScorecardHandler handler =
            new AHL_ScorecardHandler();

        Test.startTest();
        String resultJSON =
            handler.constructPayload(wrapper, new List<Integration_Details__c>());
        Test.stopTest();

        System.assertNotEquals(null, resultJSON);
        System.assert(resultJSON.contains('"Response":{}'),
            'Response node should be injected');

        // underscore replacement validation
        System.assert(
            !resultJSON.contains('test_key'),
            'Underscore keys should be replaced'
        );
        System.assert(
            resultJSON.contains('test-key'),
            'Key should contain hyphen'
        );
    }

    /* -----------------------------------------------------------
       TEST replaceUnderscoreInKeys()
    ------------------------------------------------------------*/
    @IsTest
static void testReplaceUnderscoreInKeys() {
    // 1. Prepare raw map data
    Map<String, Object> inputMap = new Map<String, Object>{
        'first_key' => 'value',
        'second_key' => new Map<String, Object>{'inner_key' => 'x'}
    };

    // 2. Call the actual visible method
    Test.startTest();
    Map<String, Object> outputMap = (Map<String, Object>) AHL_ScorecardHandler.transformKeys(inputMap);
    Test.stopTest();

    // 3. Verify the keys are transformed correctly
    System.assert(outputMap.containsKey('first-key'), 'Should contain first-key');
    System.assert(outputMap.containsKey('second-key'), 'Should contain second-key');
    
    Map<String, Object> innerMap = (Map<String, Object>) outputMap.get('second-key');
    System.assert(innerMap.containsKey('inner-key'), 'Should contain inner-key');
}
}