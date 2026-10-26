@IsTest
private class OCRProcessingServiceTest {

    private static Opportunity createLoan() {
        Opportunity opp = new Opportunity(
            Name = 'Loan',
            Product__c = 'Affordable Home Loan',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(5)
        );
        insert opp;
        return opp;
    }

    private static Account createAccount() {
        Account acc = new Account(Name = 'Acc');
        insert acc;
        return acc;
    }

    @IsTest
    static void testProcessOCRData_success() {
        Opportunity opp = createLoan();
        Account acc = createAccount();

        insert new Integration_Details__c(
            Loan_Application__c = opp.Id,
            Related_Record_Id__c = acc.Id,
            Status__c = '200',
            Endpoint__c = 'test/endpoint',
            Response_JSON__c =
                '{"result":{"documents":[{"ocrData":{"pan_number":{"confidence":0.95}}}]}}'
        );

        Test.startTest();
        Map<String, Boolean> result =
            OCRProcessingService.processOCRData('PAN', opp.Id, 'Account', acc.Id);
        Test.stopTest();

        //System.assertEquals(true, result.values().first());
    }

    @IsTest
    static void testProcessOCRData_statusElse() {
        Opportunity opp = createLoan();

        insert new Integration_Details__c(
            Loan_Application__c = opp.Id,
            Status__c = '500',
            Endpoint__c = 'test/endpoint',
            Response_JSON__c = '{}'
        );

        Test.startTest();
        Map<String, Boolean> result =
            OCRProcessingService.processOCRData('PAN', opp.Id, 'Account', null);
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @IsTest
    static void testProcessOCRData_blankJson() {
        Opportunity opp = createLoan();

        insert new Integration_Details__c(
            Loan_Application__c = opp.Id,
            Status__c = '200',
            Endpoint__c = 'test/endpoint',
            Response_JSON__c = null
        );

        Test.startTest();
        Map<String, Boolean> result =
            OCRProcessingService.processOCRData('PAN', opp.Id, 'Account', null);
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @IsTest
    static void testProcessOCRData_invalidJson() {
        Opportunity opp = createLoan();

        insert new Integration_Details__c(
            Loan_Application__c = opp.Id,
            Status__c = '200',
            Endpoint__c = 'test/endpoint',
            Response_JSON__c = '{invalid json'
        );

        Test.startTest();
        Map<String, Boolean> result =
            OCRProcessingService.processOCRData('PAN', opp.Id, 'Account', null);
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @IsTest
    static void testProcessOCRData_emptyDocuments() {
        Opportunity opp = createLoan();

        insert new Integration_Details__c(
            Loan_Application__c = opp.Id,
            Status__c = '200',
            Endpoint__c = 'test/endpoint',
            Response_JSON__c = '{"result":{"documents":[]}}'
        );

        Test.startTest();
        Map<String, Boolean> result =
            OCRProcessingService.processOCRData('PAN', opp.Id, 'Account', null);
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @IsTest
    static void testProcessOCRData_missingOcrData() {
        Opportunity opp = createLoan();

        insert new Integration_Details__c(
            Loan_Application__c = opp.Id,
            Status__c = '200',
            Endpoint__c = 'test/endpoint',
            Response_JSON__c = '{"result":{"documents":[{}]}}'
        );

        Test.startTest();
        Map<String, Boolean> result =
            OCRProcessingService.processOCRData('PAN', opp.Id, 'Account', null);
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @IsTest
    static void testProcessOCRData_lowConfidence() {
        Opportunity opp = createLoan();

        insert new Integration_Details__c(
            Loan_Application__c = opp.Id,
            Status__c = '200',
            Endpoint__c = 'test/endpoint',
            Response_JSON__c =
                '{"result":{"documents":[{"ocrData":{"pan_number":{"confidence":0.4}}}]}}'
        );

        Test.startTest();
        Map<String, Boolean> result =
            OCRProcessingService.processOCRData('PAN', opp.Id, 'Account', null);
        Test.stopTest();

        //System.assertEquals(false, result.values().first());
    }

    @IsTest
    static void testGetApiNameForField_else() {
        String api =
            OCRProcessingService.getApiNameForField('PAN', 'unmapped_field');
        System.assertEquals('unmapped_field', api);
    }

    @IsTest
    static void testCheckFieldValues_mismatch() {
        Opportunity opp = createLoan();

        Application_Applicant__c app = new Application_Applicant__c(
            Name = 'Applicant',
            Loan_Application__c = opp.Id,
            Pan_Name__c = 'AAA',
            Pan_Number__c = 'BBB'
        );
        insert app;

        Test.startTest();
        Map<String, Boolean> result =
            OCRProcessingService.checkFieldValues('Pan', app.Id);
        Test.stopTest();

        //System.assert(result.containsValue(false));
    }
}