@isTest
public class LoanExposureResponseServiceTest {
    
    @isTest
    static void testGetDeserializedResponse_ValidJson() {
        // Step 1: Build sample data matching the structure of LoanExposureResponseServiceWrapper
        String jsonResponse = '{' +
            '"returnStatus": {' +
                '"returnCode": "200",' +
                '"returnText": "Success",' +
                '"valid": true' +
            '},' +
            '"bankingDetails": {' +
                '"totalExposure": 100000.50,' +
                '"totalExposureGHF_HFC": 50000.25,' +
                '"totalExposureGFL_NBFC": 25000.25,' +
                '"totalExposureGC": 25000.00' +
            '},' +
            '"summaryExposure": {' +
                '"exposureGHF": {' +
                    '"wipLoan": "10",' +
                    '"disburstLoan": "5"' +
                '},' +
                '"exposureGFL": "15"' +
            '},' +
            '"existingLoans": [' +
                '{' +
                    '"ucic": "UCIC001",' +
                    '"lan_no": "LAN001",' +
                    '"full_name": "John Doe",' +
                    '"cif": "CIF001",' +
                    '"original_amount": 50000,' +
                    '"installment_amount": 5000,' +
                    '"outstanding_amount": 20000,' +
                    '"loan_date": "2023-01-01",' +
                    '"loan_status": "Active",' +
                    '"entity": "HFC",' +
                    '"dpd_string": "0",' +
                    '"dob": "1990-01-01",' +
                    '"employment_type": "Salaried",' +
                    '"employer_name": "ABC Corp",' +
                    '"loan_type": "Home Loan",' +
                    '"no_of_bounce": "0",' +
                    '"booking_date": "2023-02-01",' +
                    '"undisbursed_amount": 0,' +
                    '"applicant": "Primary"' +
                '}' +
            '],' +
            '"linklanDetails": {' +
                '"linkedLoans": {' +
                    '"Group1": [' +
                        '{' +
                            '"groupcode": "G001",' +
                            '"groupdesc": "Test Group",' +
                            '"lan": "LAN001"' +
                        '}' +
                    ']' +
                '}' +
            '}' +
        '}';

        // Step 2: Call the method under test
        LoanExposureResponseService.LoanExposureResponseServiceWrapper result =
            LoanExposureResponseService.getDeserailizedResponse(jsonResponse);

        // Step 3: Assertions to verify successful deserialization
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('200', result.returnStatus.returnCode, 'Return code should match');
        System.assertEquals(true, result.returnStatus.valid, 'Valid flag should match');
        System.assertEquals(100000.50, result.bankingDetails.totalExposure, 'Total exposure should match');
        System.assertEquals('10', result.summaryExposure.exposureGHF.wipLoan, 'WIP loan should match');
        System.assertEquals('LAN001', result.existingLoans[0].lan_no, 'LAN number should match');
        System.assertEquals('Test Group', result.linklanDetails.linkedLoans.get('Group1')[0].groupdesc, 'Group description should match');
    }
    
    @isTest
    static void testGetDeserializedResponse_InvalidJson() {
        // Step 1: Prepare invalid JSON
        String invalidJson = '{"returnStatus": "invalid_json_value"'; // Missing closing brace
        
        // Step 2: Expect an AuraHandledException to be thrown
        try {
            LoanExposureResponseService.getDeserailizedResponse(invalidJson);
            System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            /*System.assert(e.getMessage().contains('Unexpected character') ||
                          e.getMessage().contains('Unexpected end of JSON input'),
                          'Expected a JSON parsing error message');*/
        } catch (Exception ex) {
            System.assert(false, 'Unexpected exception type: ' + ex.getTypeName());
        }
    }
}