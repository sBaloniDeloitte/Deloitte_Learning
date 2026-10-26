@IsTest
private class CreateFinanceResponseWrapperTest {
    private static String getSampleJson() {
        return '{' +
               '  "finReference":"GHF1001HL0005309",' +
               '  "financeSchedule":{' +
               '    "summary":{' +
               '      "effectiveRateOfReturn":7.026288585' +
               '    }' +
               '  },' +
               '  "disbursement":[' +
               '    {' +
               '      "remarks":"",' +
               '      "paymentId":6166' +
               '    },' +
               '    {' +
               '      "remarks":"Second payment",' +
               '      "paymentId":6167' +
               '    }' +
               '  ],' +
               '  "returnStatus":{' +
               '    "returnCode":"0000",' +
               '    "returnText":"Success"' +
               '  }' +
               '}';
    }

    @IsTest
    static void testParseMethod() {
        String json = getSampleJson();
        CreateFinanceResponseWrapper wrapper = CreateFinanceResponseWrapper.parse(json);
        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
        System.assertEquals('GHF1001HL0005309', wrapper.finReference, 'finReference mismatch');
        System.assertNotEquals(null, wrapper.financeSchedule, 'financeSchedule should not be null');
        System.assertNotEquals(null, wrapper.financeSchedule.summary, 'summary should not be null');
        System.assertEquals(7.026288585, wrapper.financeSchedule.summary.effectiveRateOfReturn,
                            'effectiveRateOfReturn mismatch');
        System.assertEquals(2, wrapper.disbursement.size(), 'Disbursement count mismatch');
        System.assertEquals('', wrapper.disbursement[0].remarks, 'First disbursement remarks mismatch');
        System.assertEquals(6166, wrapper.disbursement[0].paymentId, 'First disbursement paymentId mismatch');
        System.assertEquals('Second payment', wrapper.disbursement[1].remarks,
                            'Second disbursement remarks mismatch');
        System.assertEquals(6167, wrapper.disbursement[1].paymentId, 'Second disbursement paymentId mismatch');
        System.assertNotEquals(null, wrapper.returnStatus, 'returnStatus should not be null');
        System.assertEquals('0000', wrapper.returnStatus.returnCode, 'returnCode mismatch');
        System.assertEquals('Success', wrapper.returnStatus.returnText, 'returnText mismatch');
    }
    @IsTest
    static void testParseWithPartialJson() {
        String partialJson = '{"finReference":"ABC123"}';
        CreateFinanceResponseWrapper wrapper = CreateFinanceResponseWrapper.parse(partialJson);

        System.assertEquals('ABC123', wrapper.finReference);
        System.assertEquals(null, wrapper.financeSchedule, 'financeSchedule should be null for partial JSON');
        System.assertEquals(null, wrapper.disbursement, 'disbursement should be null for partial JSON');
        System.assertEquals(null, wrapper.returnStatus, 'returnStatus should be null for partial JSON');
    }
}