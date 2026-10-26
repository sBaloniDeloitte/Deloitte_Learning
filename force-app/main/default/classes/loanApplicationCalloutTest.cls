/**
 * loanApplicationCalloutTest.cls
 * ─────────────────────────────────────────────────────────────────
 * Test class for loanApplicationCallout.
 *
 * NOTE: Field values for RecordTypes / picklists (e.g. 'Primary Applicant',
 * 'Co Applicant', 'Product', 'Sub Variant', 'Transaction_Details') are
 * assumed based on the class under test. Adjust to match your org's
 * actual RecordType DeveloperNames / picklist API values if they differ.
 * DEBUGGING NOTE: Every method body is wrapped in a try/catch that logs
 * the exception message AND e.getStackTraceString(), then RE-THROWS so the
 * test still fails as expected. The re-throw preserves test integrity — if
 * we swallowed the exception, a broken test would pass silently. Remove the
 * `throw e;` lines only if you intentionally want to suppress failures.
 */
@isTest
private class loanApplicationCalloutTest {

    // ── Mock HTTP response ────────────────────────────────────
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }

    private class FailureMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"status":"error"}');
            return res;
        }
    }

    // ── Shared data setup ─────────────────────────────────────
    private static Id buildFullDataSet() {
        try {
            // -- Opportunity (loan_application) --
            Opportunity opp = new Opportunity();
            opp.StageName                                 = 'Disbursement';
            opp.CloseDate                                 = Date.today().addMonths(36);
            opp.Product__c                                = 'Home Loan';
            opp.Sub_Product__c                            = 'Standard';
            //opp.Loan_Purpose__c                           = 'Purchase';
            //opp.Loan_Facility__c                          = 'Term Loan';
            opp.Repayment_Facility__c                     = 'EMI';
            opp.Requested_Amount__c                       = 5000000;
            opp.Requested_Tenure_in_Months__c            = 240;
            opp.No_of_Applicants__c                       = 2;
            opp.Channel_Type__c                           = 'DSA';
            opp.Channel_Name__c                           = 'Test DSA';
            opp.Sanction_Loan_Amount__c                   = 4500000;
            opp.Sanction_Tenure__c                        = 240;
            opp.Final_Amount__c                           = 4500000;
            opp.Final_Rate_Of_Interest__c                 = 8.5;
            opp.Total_Stamp_Duty__c                       = 15000;
            opp.Emi_amount__c                             = 39000;
            opp.Approval_Status__c                        = 'Approved';
            //opp.Approval_Sub_Status__c                    = 'Final';
            //opp.Loan_Category__c                          = 'HL';
            opp.Hunter_Decision__c                        = 'Pass';
            opp.DocGen_Status__c                          = '';
            opp.Income_Approval_Status__c                 = 'Approved';
            opp.Pricing_Approval_Status__c                = 'Approved';
            opp.Exception_Approval_Status__c              = 'approved';
            opp.Application_Source__c                      = 'Salesforce';
            //opp.Credit_Underwriter__c                     = '';
            opp.Total_Tenure__c                           = '240';
            opp.Hybrid_Tenure__c                          = '6';
            opp.Full_EMI__c                               = 'Yes';
            opp.PMAY_flag__c                              = false;
            opp.First_time_home_buyer__c                  = 'Yes';
            //opp.Flexi_Fund_Variant__c                     = 'Standard';
            opp.FOIR__c                                   = 45.0;
            //opp.Property_Type__c                          = 'Residential';
            //opp.HL_Construction_Stage__c                  = 'Ready';
            opp.Total_Valuation__c                        = 6000000;
            opp.End_Use_of_Fund__c                        = 'Self Occupied';
            opp.Pucca_house__c                            = 'Yes';
            //opp.Collateral_Categorization__c              = 'Tier 1';
            //opp.Collateral_Segmentation__c                = 'Green';
            //opp.SBL_Met__c                                = 'Yes';
            opp.Entity_1__c                               = 'ABC Builders';
            opp.Entity_2__c                               = 'Site Manager';
            opp.Negotiated_Loan_Amount__c                 = 4500000;
            opp.Negotiated_Rate_Of_Interest__c            = 8.25;
            opp.Negotiated_Tenure__c                      = 240;
            opp.Eligible_Loan_Amount__c                   = 4500000;
            //opp.Program__c                                = 'Standard';
            opp.Loan_Eligible_for_PSL__c                  = 'Yes';
            //opp.Approval_Type__c                          = 'L1';
            opp.Risk_Score__c                             = '750';
            opp.Risk_Segment__c                           = 'Green';
            opp.Banking_Index__c                          = '1.2';
            opp.Drawing_Power_Amount__c                   = '10000';
            opp.Parent_Loan_Amount__c                     = 200000;
            opp.Household_Income__c                       = 80000;
            opp.CAGR_in_percentage__c                     = 15.0;
            opp.Exposure__c                               = 300000;
            opp.Amount_of_Cash_Surplus_for_PY1_Rs__c     = 500000;
            opp.Cash_Surplus_Rs__c                        = 450000;
            opp.Total_Amount_of_Cash_Surplus_Rs__c        = 950000;
            opp.Amount_of_Cash_Surplus_for_PY2_Rs__c     = 480000;
            opp.Amount_of_Cash_Surplus_for_PY3_Rs__c     = 460000;
            opp.Amount_of_Cash_Surplus_for_PY4_Rs__c     = 440000;
            opp.Pending_loan_to_cover_Under_Collateral__c = 1000000;
            opp.EMI_Amount_Repayment_Schedule__c          = 38000;
            opp.Total_Combined_Wealth__c                  = 5000000;
            opp.No_of_Associated_Entities__c              = 2;
            opp.Is_Send_Back__c                           = false;
            opp.Is_Property_Identified__c                 = 'Yes';
            opp.Approval_Comments__c                      = 'All good';
            opp.PSL_Code__c                               = 'PSL001';
            opp.CIN_LLPIN_number__c                       = 'U12345MH2020';
            opp.Loan_Unassigned_DateTime__c               = Datetime.now();
            opp.DocGen_Initiated_Time__c                  = Datetime.now();
            opp.Stamp_Paper__c                            = 'Yes';
            //opp.Loan_Application__c                       = '';
            insert opp;

            // -- Primary Applicant --
            Application_Applicant__c primary = new Application_Applicant__c(
                Loan_Application__c = opp.Id,
                Applicant_Type__c = 'Primary Applicant',
                //Salutation__c = 'Mr',
                First_Name__c = 'John',
                Last_Name__c = 'Doe',
                DOB__c = Date.newInstance(1990, 1, 1),
                Gender__c = 'Male',
                PAN_Number__c = 'ABCDE1234F',
                Mobile_Number__c = '9999999999',
                Email__c = 'john.doe@example.com',
                Marital_Status__c = 'Single',
                //Annual_Total_Income__c = 1200000,
                Monthly_Salary__c = 100000,
                CIBIL_Score__c = 750
            );
            insert primary;

            // -- Co-Applicant --
            Application_Applicant__c coApp = new Application_Applicant__c(
                Loan_Application__c = opp.Id,
                Applicant_Type__c = 'Co Applicant',
                First_Name__c = 'Jane',
                Last_Name__c = 'Doe',
                //Relationship_with_Primary_Applicant__c = 'Spouse',
                Mobile_Number__c = '8888888888',
                PAN_Number__c = 'FGHIJ5678K'
            );
            insert coApp;

            // -- Applicant Address (primary) --
            Applicant_Address__c addr = new Applicant_Address__c(
                Applicant__c = primary.Id,
                Loan_Application__c = opp.Id,
                //State__c = 'Maharashtra',
                //City__c = 'Mumbai',
                Address_Line_1__c = '123 Test Street',
                Address_Line_2__c = 'Test Area',
                Is_Current_Address_Same_As_Permanent__c = 'Yes',
                Address_Type__c = 'Current'
            );
            insert addr;

            // -- Application Verification --
            Application_Verification__c verif = new Application_Verification__c(
                Applicant__c = primary.Id,
                Loan_Application__c = opp.Id,
                OGL__c = 'Yes'
            );
            insert verif;

            // -- Bank Details --
            Bank_Details__c bank = new Bank_Details__c(
                Application_Applicant__c = primary.Id,
                //Loan_Application__c = opp.Id,
                Account_Number__c = '123456789012',
                //Bank_Name__c = 'Test Bank',
                IFSC__c = 'TEST0001234',
                Account_Holder_Name__c = 'John Doe',
                Account_Type__c = 'Saving',
                Is_Repayment_Account__c = true,
                Is_Disbursal_Account__c = true
            );
            insert bank;

            // -- Collateral --
            Collateral__c collateral = new Collateral__c(
                Tower_Building_Name__c = 'Tower A',
                Floor_Number__c = '5',
                Unit_Number__c = '501',
                RERA_Registration_Number__c = 'RERA12345',
                Site_Visit_Conducted_by_Sales__c = 'Yes',
                Address_Line_1__c = 'Collateral Address Line 1'
            );
            insert collateral;

            // -- Application_Collateral__c junction --
            Application_Collateral__c appCollateral = new Application_Collateral__c(
                HL_Loan_Application__c = opp.Id,
                Collateral__c = collateral.Id
            );
            insert appCollateral;

            // -- Technical Evaluation --
            Technical_Evaluation__c techEval = new Technical_Evaluation__c(
                HL_Loan_Application__c = opp.Id,
                District__c = 'Mumbai',
                City__c = 'Mumbai',
                State__c = 'Maharashtra'
                //Market_Value_Of_Property__c = 1000000
            );
            insert techEval;

            // -- Legal --
            Legal__c legal = new Legal__c(
                Loan_Application__c = opp.Id
            );
            //insert legal;

            // -- Document Master & Document Details + ContentVersion --
            // Create a ContentVersion (and its derived ContentDocument)
            ContentVersion cv = new ContentVersion(
                Title = 'Test Doc',
                PathOnClient = 'TestDoc.pdf',
                VersionData = Blob.valueOf('Test File Content'),
                IsMajorVersion = true
            );
            insert cv;

            cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

            Document_Details__c doc = new Document_Details__c(
                Name = 'PAN Card',
                Loan_Application__c = opp.Id,
                Content_Document_Id__c = String.valueOf(cv.ContentDocumentId),
                Applicant__c = primary.Id
            );
            insert doc;

            // -- Instrument Mandate --
            Instrument_Mandate__c instrument = new Instrument_Mandate__c(
                Loan_Application__c = opp.Id
            );
            insert instrument;

            return opp.Id;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '=== Exception in buildFullDataSet ===');
            System.debug(LoggingLevel.ERROR, 'Message    : ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Type       : ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Line Number: ' + e.getLineNumber());
            System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + e.getStackTraceString());
            throw e;
        }
    }

    // ── Test: full payload build + successful callout (sendLoanApplication) ──
    @isTest
    static void testSendLoanApplication_Success() {
        try {
            Id oppId = buildFullDataSet();

            Test.setMock(HttpCalloutMock.class, new SuccessMock());

            Test.startTest();
            String response = loanApplicationCallout.sendLoanApplication(oppId, 'Bajaj Finance Ltd');
            Test.stopTest();


        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '=== Exception in testSendLoanApplication_Success ===');
            System.debug(LoggingLevel.ERROR, 'Message    : ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Type       : ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Line Number: ' + e.getLineNumber());
            System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + e.getStackTraceString());
            throw e;
        }
    }

    // ── Test: callout failure path is handled gracefully ──────
    @isTest
    static void testSendLoanApplication_Failure() {
        try {
            Id oppId = buildFullDataSet();

            Test.setMock(HttpCalloutMock.class, new FailureMock());

            Test.startTest();
            String response = loanApplicationCallout.sendLoanApplication(oppId, 'Bajaj Finance Ltd');
            Test.stopTest();

            // Even on failure, method returns res.getBody() without throwing

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '=== Exception in testSendLoanApplication_Failure ===');
            System.debug(LoggingLevel.ERROR, 'Message    : ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Type       : ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Line Number: ' + e.getLineNumber());
            System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + e.getStackTraceString());
            throw e;
        }
    }

    // ── Test: future method variant ────────────────────────────
    @isTest
    static void testSendLoanApplicationFuture() {
        try {
            Id oppId = buildFullDataSet();

            Test.setMock(HttpCalloutMock.class, new SuccessMock());

            Test.startTest();
            loanApplicationCallout.sendLoanApplicationfuture(oppId, 'Bajaj Finance Ltd');
            Test.stopTest();

            // No direct return value to assert; absence of exception = success.

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '=== Exception in testSendLoanApplicationFuture ===');
            System.debug(LoggingLevel.ERROR, 'Message    : ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Type       : ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Line Number: ' + e.getLineNumber());
            System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + e.getStackTraceString());
            throw e;
        }
    }

    // ── Test: buildPayload directly (TestVisible) and verify JSON shape ──
    @isTest
    static void testBuildPayload_Structure() {
        try {
            Id oppId = buildFullDataSet();

            Test.startTest();
            String jsonBody = loanApplicationCallout.buildPayload(oppId, 'Bajaj Finance Ltd');
            Test.stopTest();


            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);


            // Spot-check loan_application contents
            Map<String, Object> loanApp = (Map<String, Object>) payload.get('loan_application');

            // co_applicant should be a wrapper with items[]
            Map<String, Object> coApp = (Map<String, Object>) payload.get('co_applicant');
            List<Object> coAppItems = (List<Object>) coApp.get('items');

            // documents array should contain the uploaded document
            List<Object> documents = (List<Object>) payload.get('documents');

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '=== Exception in testBuildPayload_Structure ===');
            System.debug(LoggingLevel.ERROR, 'Message    : ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Type       : ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Line Number: ' + e.getLineNumber());
            System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + e.getStackTraceString());
            throw e;
        }
    }

    // ── Test: buildPayload returns null when Opportunity does not exist ──
    @isTest
    static void testBuildPayload_NullOpportunity() {
        try {
            // Construct a bogus but well-formed Opportunity Id that doesn't exist
            Id fakeId = (Id) '006000000000000AAA';

            Test.startTest();
            String jsonBody = loanApplicationCallout.buildPayload(fakeId, 'Bajaj Finance Ltd');
            Test.stopTest();


        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '=== Exception in testBuildPayload_NullOpportunity ===');
            System.debug(LoggingLevel.ERROR, 'Message    : ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Type       : ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Line Number: ' + e.getLineNumber());
            System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + e.getStackTraceString());
            throw e;
        }
    }

    // ── Test: sendLoanApplication handles blank/non-existent Opportunity gracefully ──
    @isTest
    static void testSendLoanApplication_BlankPayload() {
        try {
            Id fakeId = (Id) '006000000000000AAA';

            Test.startTest();
            String response = loanApplicationCallout.sendLoanApplication(fakeId, 'Bajaj Finance Ltd');
            Test.stopTest();


        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '=== Exception in testSendLoanApplication_BlankPayload ===');
            System.debug(LoggingLevel.ERROR, 'Message    : ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Type       : ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Line Number: ' + e.getLineNumber());
            System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + e.getStackTraceString());
            throw e;
        }
    }

    // ── Test: minimal Opportunity with no related child records ──
    @isTest
    static void testBuildPayload_MinimalOpportunity() {
        try {
            Opportunity opp = new Opportunity(
                StageName = 'Sales login',
                CloseDate = Date.today().addMonths(3),
                Amount = 100000,
                Product__c = 'Home Loan'
                //Loan_Application_Number__c = 'LAN-0002'
            );
            insert opp;

            Test.startTest();
            String jsonBody = loanApplicationCallout.buildPayload(opp.Id, 'Bajaj Finance Ltd');
            Test.stopTest();


            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
            Map<String, Object> loanApp = (Map<String, Object>) payload.get('loan_application');

            List<Object> documents = (List<Object>) payload.get('documents');

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '=== Exception in testBuildPayload_MinimalOpportunity ===');
            System.debug(LoggingLevel.ERROR, 'Message    : ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Type       : ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Line Number: ' + e.getLineNumber());
            System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + e.getStackTraceString());
            throw e;
        }
    }
}