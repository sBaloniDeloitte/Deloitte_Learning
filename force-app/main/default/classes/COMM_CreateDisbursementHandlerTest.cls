@IsTest
public class COMM_CreateDisbursementHandlerTest {

    /* -----------------------------
       Helper: Create minimal wrapper
       ----------------------------- */
    private static intHandler.ProcessReqWrapper buildWrapper(Id oppId) {
        intHandler.ProcessReqWrapper w = new intHandler.ProcessReqWrapper();
        w.loanApplicationId = oppId;
        return w;
    }

    /* -----------------------------
       Test: validatePayload
       ----------------------------- */
    @IsTest
    static void testValidatePayload() {
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();

        List<String> errors =
            COMM_CreateDisbursementHandler.validatePayload(wrapper);

        System.assertNotEquals(null, errors);
        System.assertEquals(0, errors.size());
    }

    /* -----------------------------
       Test: constructPayload (minimal)
       ----------------------------- */
    @IsTest
    static void testConstructPayload() {

        // 1️⃣ Opportunity (Loan Application)
        Opportunity opp = new Opportunity(
            StageName = 'Sales login',
            CloseDate = Date.today(),
            LMS_Loan_Reference__c = 'LMS12345',
            Product__c = 'Home Loan'
        );
        insert opp;

        // 2️⃣ Loan Transaction (Payment)
        Loan_Transaction__c txn = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            Net_Amount__c = 1000,
            Scheduled_Disbursement_Date__c = Date.today().addDays(5),
            Disbursement_Party__c = 'Customer',
            Disbursement_Type__c = 'NEFT',
            QDP_Status__c = 'New'
        );
        insert txn;

        // 3️⃣ Wrapper
        intHandler.ProcessReqWrapper wrapper = buildWrapper(opp.Id);

        // 4️⃣ Execute
        COMM_CreateDisbursementHandler handler =
            new COMM_CreateDisbursementHandler();

        Test.startTest();
        String jsonPayload =
            handler.constructPayload(wrapper, new List<Integration_Details__c>());
        Test.stopTest();

        // 5️⃣ Assert
        System.assertNotEquals(
            null,
            jsonPayload,
            'Payload JSON should not be null'
        );
        System.assert(
            jsonPayload.contains('disbursements'),
            'Payload should contain disbursements'
        );
    }

    /* -----------------------------
       Test: addTwoZeros
       ----------------------------- */
    @IsTest
    static void testAddTwoZeros() {
        Integer result =
            COMM_CreateDisbursementHandler.addTwoZeros(10.5);

        System.assertEquals(1050, result);
    }

    /* -----------------------------
       Test: formatDateString
       ----------------------------- */
    @IsTest
    static void testFormatDateString() {
        String formatted =
            COMM_CreateDisbursementHandler.formatDateString(
                Date.newInstance(2025, 1, 1)
            );

        System.assertEquals(
            '2025-01-01T00:00:00',
            formatted
        );
    }
}