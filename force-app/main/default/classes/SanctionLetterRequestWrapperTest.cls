@IsTest
public class SanctionLetterRequestWrapperTest {

    @IsTest
    static void testSanctionLetterRequestWrapperParse() {
        // Step 1: Build sample JSON with a few nested lists and fields
        String jsonInput = '{' +
            '"eventID":"EVT123",' +
            '"lettertype":"Sanction",' +
            '"mobile_number":"9999999999",' +
            '"email_id":"test@example.com",' +
            '"name":"John Doe",' +
            '"loan_amount":500000,' +
            '"rate_of_interest":8.5,' +
            '"repaymentPlanData":[{"step_no":1,"step_specifier":"Initial","installments":12,"stepped_emi":10000}],' +
            '"linkedLans":[{"reference":"REF001"}],' +
            '"coApplicant":[{"salutation":"Mr","name":"CoApp1","cif":"CIF123","email_address":"coapp1@mail.com"}],' +
            '"sanctionConditions":[{"seqno":1,"sanctioncondition":"Condition A"}],' +
            '"collateralPropertyDetails":[{"unit":"101","floornumber":"1","tower":"A","project_name":"Sunshine"}],' +
            '"appFormDetails":[{"custshrtname":"JD","mothername":"Mary"}],' +
            '"appFormCoappDetails":[{"custshrtname":"CoJD","mothername":"CoMary"}]' +
        '}';

        // Step 2: Call the parse method
        SanctionLetterRequestWrapper wrapper = SanctionLetterRequestWrapper.parse(jsonInput);

        // Step 3: Validate the main fields
        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
        System.assertEquals('EVT123', wrapper.eventID);
        System.assertEquals('Sanction', wrapper.lettertype);
        System.assertEquals('John Doe', wrapper.name);
        System.assertEquals(500000, wrapper.loan_amount);
        System.assertEquals(8.5, wrapper.rate_of_interest);

        // Step 4: Validate one nested object
        System.assertEquals(1, wrapper.repaymentPlanData.size());
        System.assertEquals(1, wrapper.repaymentPlanData[0].step_no);
        System.assertEquals('Initial', wrapper.repaymentPlanData[0].step_specifier);

        // Step 5: Validate co-applicant data
        System.assertEquals('CoApp1', wrapper.coApplicant[0].name);
        System.assertEquals('CIF123', wrapper.coApplicant[0].cif);

        // Step 6: Validate sanction conditions
        System.assertEquals(1, wrapper.sanctionConditions[0].seqno);
        System.assertEquals('Condition A', wrapper.sanctionConditions[0].sanctioncondition);

        // Step 7: Validate collateral details
        System.assertEquals('Sunshine', wrapper.collateralPropertyDetails[0].project_name);
    }
}