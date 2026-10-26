@isTest
public class DoctorCheckHandlerTest {

    @testSetup
    static void setupTestData() {

    }

    @isTest
    static void testValidatePayload_AllFieldsMissing() {
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        List<String> errors = DoctorCheckHandler.validatePayload(wrapper);
        System.assertEquals(3, errors.size(), 'Should return 3 errors for missing fields');
        System.assert(errors.contains('Council name is not added'));
        System.assert(errors.contains('Registration number is not added'));
        System.assert(errors.contains('Year of registration is not provided'));
    }

    @isTest
    static void testValidatePayload_AllFieldsPresent() {
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.councilName = 'Medical Council of India';
        wrapper.registrationNo = 'REG12345';
        wrapper.yearOfReg = '2020';

        List<String> errors = DoctorCheckHandler.validatePayload(wrapper);
        System.assertEquals(0, errors.size(), 'Should return no errors when all fields are present');
    }

    @isTest
    static void testConstructPayload() {
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.councilName = 'Medical Council of India';
        wrapper.registrationNo = 'REG12345';
        wrapper.yearOfReg = '2020';

        List<Integration_Details__c> integrationSettings = new List<Integration_Details__c>();

        Test.startTest();
        String payload = (new DoctorCheckHandler()).constructPayload(wrapper, integrationSettings);
        Test.stopTest();

        System.assertNotEquals(null, payload, 'Payload should not be null');
        System.assert(payload.contains('REG12345'), 'Payload should contain registration number');
        System.assert(payload.contains('2020'), 'Payload should contain year of registration');
        System.assert(payload.contains('Medical Council of India'), 'Payload should contain council name');
        System.assert(payload.contains('Yes') || payload.contains('Y'), 'Payload should contain consent');
       
    }

}