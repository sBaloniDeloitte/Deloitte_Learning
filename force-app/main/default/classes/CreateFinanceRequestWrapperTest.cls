@IsTest
private class CreateFinanceRequestWrapperTest {
    @IsTest
    static void testParseMethod() {
        // Sample minimal JSON for deserialization
        String jsonData = '{' +
            '"stp": true,' +
            '"finReference": "FIN123",' +
            '"processStage": "Stage1",' +
            '"financeSchedule": {' +
                '"externalReference": "EXT123",' +
                '"financeDetail": {' +
                    '"finType": "HL",' +
                    '"cif": "105374",' +
                    '"finBranch": 1001,' +
                    '"sourcingBranch": 1001,' +
                    '"finAmount": 500000' +
                '},' +
                '"step": [],' +
                '"vas": [],' +
                '"fees": []' +
            '},' +
            '"coApplicants": [],' +
            '"collaterals": [],' +
            '"covenantDetails": [],' +
            '"disbursement": [],' +
            '"mandateDetail": {' +
                '"useExisting": false,' +
                '"mandateType": "NACH",' +
                '"accHolderName": "John"' +
            '},' +
            '"chequeHeaders": [],' +
            '"finOCRHeader": {' +
                '"ocrID": "2080",' +
                '"totalDemand": "10000000"' +
            '},' +
            '"createPLMGroup": false,' +
            '"existingGroup": false,' +
            '"groupCode": "GRP01",' +
            '"plmHeaderList": []' +
        '}';

        Test.startTest();
        // ✅ Parse the JSON into wrapper
        CreateFinanceRequestWrapper wrapper = CreateFinanceRequestWrapper.parse(jsonData);
        Test.stopTest();

        // ✅ Assertions to ensure deserialization worked
        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
        System.assertEquals('FIN123', wrapper.finReference, 'Finance Reference should match');
        System.assertEquals(true, wrapper.stp, 'STP flag should match');
        System.assertNotEquals(null, wrapper.financeSchedule, 'Finance Schedule should be parsed');
        System.assertEquals('HL', wrapper.financeSchedule.financeDetail.finType, 'Finance Type should be HL');
    }
}