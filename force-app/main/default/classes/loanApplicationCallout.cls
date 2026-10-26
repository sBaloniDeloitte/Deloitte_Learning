/**
 * LoanApplicationCallout.cls
 * ─────────────────────────────────────────────────────────────────
 * Builds the full loan-application JSON payload from an Opportunity
 * (loan_application) and all related objects, then performs an HTTP
 * callout.  Accepts a single Opportunity Id.
 * 
 *
 * Object Relationships
 * ────────────────────
 *  Opportunity                          = loan_application
 *  Application_Applicant__c             WHERE Loan_Application__c = oppId
 *      ├─ Applicant_Address__c          WHERE Applicant__c = applicantId
 *      ├─ Application_Verification__c   WHERE Applicant__c = applicantId
 *      └─ Bank_Details__c               WHERE Application_Applicant__c = applicantId
 *  Application_Collateral__c            WHERE HL_Loan_Application__c = oppId
 *      └─ Collateral__c                 (lookup on Application_Collateral__c)
 *  Product2                             WHERE Loan_Application__c = oppId
 *                                        AND RecordType.Name = 'Product'
 *  Technical_Evaluation__c              WHERE HL_Loan_Application__c = oppId
 *  Legal__c                             WHERE Loan_Application__c = oppId
 *  Document_Details__c                  WHERE Loan_Application__c = oppId
 *  Instrument_Mandate__c               WHERE Loan_Application__c = oppId
 */
public without sharing class loanApplicationCallout {
    @future(callout=true)
    public static void sendLoanApplicationfuture(Id opportunityId, String partnerBank) {
        try {
            String jsonBody = buildPayload(opportunityId, partnerBank);
            if (String.isBlank(jsonBody)) {
                System.debug(LoggingLevel.ERROR, 'Payload is empty – aborting callout for Opp: ' + opportunityId);
                return;
            }
            system.debug('Payload for Opp ' + opportunityId + ': ' + jsonBody);
            HttpRequest req = new HttpRequest();
            req.setEndpoint(ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonBody);
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
                System.debug(LoggingLevel.ERROR,
                    'Callout failed | Status: ' + res.getStatusCode() +
                    ' | Body: ' + res.getBody());
            } else {
                System.debug(LoggingLevel.INFO, 'Callout success for Opp: ' + opportunityId);
            }
            return; 
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR,
                'Exception in sendLoanApplication: ' + ex.getMessage() +
                ' | Stack: ' + ex.getStackTraceString());
                return;
        }
    }


    // ── Named-credential / endpoint (update per environment) ──
    private static final String ENDPOINT = 'callout:loanApplicationColending';

    // ───────────────────────────────────────────────────────────
    //  PUBLIC ENTRY POINT
    // ───────────────────────────────────────────────────────────
    @AuraEnabled
    public static String sendLoanApplication(Id opportunityId, String partnerBank) {
        try {
            String jsonBody = buildPayload(opportunityId, partnerBank);
            if (String.isBlank(jsonBody)) {
                System.debug(LoggingLevel.ERROR, 'Payload is empty – aborting callout for Opp: ' + opportunityId);
                return '';
            }
            system.debug('Payload for Opp ' + opportunityId + ': ' + jsonBody);
            HttpRequest req = new HttpRequest();
            req.setEndpoint(ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonBody);
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
                System.debug(LoggingLevel.ERROR,
                    'Callout failed | Status: ' + res.getStatusCode() +
                    ' | Body: ' + res.getBody());
            } else {
                System.debug(LoggingLevel.INFO, 'Callout success for Opp: ' + opportunityId);
            }
            return res.getBody();
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR,
                'Exception in sendLoanApplication: ' + ex.getMessage() +
                ' | Stack: ' + ex.getStackTraceString());
                return '';
        }
    }

    // ───────────────────────────────────────────────────────────
    //  PAYLOAD BUILDER (testVisible so unit tests can assert)
    // ───────────────────────────────────────────────────────────
    @TestVisible
    private static String buildPayload(Id opportunityId, String partnerBank) {

        // ── 1. Query Opportunity ──────────────────────────────
        Opportunity opp = queryOpportunity(opportunityId);
        if (opp == null) return null;

        // ── 2. Applicants ─────────────────────────────────────
        List<Application_Applicant__c> allApplicants = queryApplicants(opportunityId);

        Application_Applicant__c primaryApp = null;
        List<Application_Applicant__c> coApplicants = new List<Application_Applicant__c>();

        for (Application_Applicant__c aa : allApplicants) {
            if (aa.Applicant_Type__c != null &&
                aa.Applicant_Type__c.equalsIgnoreCase('Primary Applicant')) {
                primaryApp = aa;
            } else if (aa.Applicant_Type__c != null &&
                    aa.Applicant_Type__c.equalsIgnoreCase('Co Applicant')) {
                coApplicants.add(aa);
            }
        }

        // Collect all applicant Ids for child queries
        Set<Id> applicantIds = new Set<Id>();
        for (Application_Applicant__c aa : allApplicants) {
            applicantIds.add(aa.Id);
        }

        // ── 3. Applicant Addresses ────────────────────────────
        Map<Id, List<Applicant_Address__c>> addrByApplicant = queryAddresses(applicantIds);

        // ── 4. Application Verifications ──────────────────────
        Map<Id, Application_Verification__c> verifByApplicant = queryVerifications(applicantIds);

        // ── 5. Bank Details ───────────────────────────────────
        Map<Id, List<Bank_Details__c>> bankByApplicant = queryBankDetails(applicantIds);

        // ── 6. Collaterals ────────────────────────────────────
        List<Collateral__c> collaterals = queryCollaterals(opportunityId);

        // ── 7. Product ────────────────────────────────────────
        Product2 product = queryProduct(opportunityId);

        // ── 8. Technical Evaluations ──────────────────────────
        List<Technical_Evaluation__c> techEvals = queryTechEvals(opportunityId);

        // ── 9. Legal ──────────────────────────────────────────
        List<Legal__c> legals = queryLegal(opportunityId);

        // ── 10. Documents ─────────────────────────────────────
        List<Document_Details__c> docs = queryDocuments(opportunityId);

        // ── 10b. Latest ContentVersion per ContentDocumentId ──
        // Collect all non-null Content Document Ids from Document_Details__c
        Set<Id> contentDocIds = new Set<Id>();
        for (Document_Details__c dd : docs) {
            if (String.isNotBlank(dd.Content_Document_Id__c)) {
                try {
                    contentDocIds.add(Id.valueOf(dd.Content_Document_Id__c));
                } catch (Exception e) {
                    // Skip invalid Ids
                }
            }
        }
        // Single bulk query – latest ContentVersion per ContentDocument
        Map<Id, ContentVersion> latestCVByDocId = queryLatestContentVersions(contentDocIds);

        // ── 11. Instrument & Mandate ──────────────────────────
        List<Instrument_Mandate__c> instruments = queryInstruments(opportunityId);

        // ══════════════════════════════════════════════════════
        //  BUILD JSON MAP
        // ══════════════════════════════════════════════════════
        Map<String, Object> payload = new Map<String, Object>();

        // ── loan_application ──────────────────────────────────
        payload.put('loan_application',
            buildLoanApplication(opp, product, instruments, partnerBank));

        // ── primary_applicant ─────────────────────────────────
        payload.put('primary_applicant',
            buildPrimaryApplicant(opp, primaryApp,
                primaryApp != null ? addrByApplicant.get(primaryApp.Id) : null,
                primaryApp != null ? verifByApplicant.get(primaryApp.Id) : null));

        // ── co_applicant (wrapper with loan_app_id + items[]) ─
        Map<String, Object> coAppWrapper = new Map<String, Object>();
        coAppWrapper.put('loan_app_id', s(opp.Loan_Application_Number__c));
        List<Map<String, Object>> coAppItems = new List<Map<String, Object>>();
        for (Application_Applicant__c ca : coApplicants) {
            coAppItems.add(
                buildCoApplicant(opp, ca,
                    addrByApplicant.get(ca.Id),
                    verifByApplicant.get(ca.Id)));
        }
        coAppWrapper.put('items', coAppItems);
        payload.put('co_applicant', coAppWrapper);

        // ── entity_applicant (first non-individual if exists) ─
        Application_Applicant__c entityApp = null;
        for (Application_Applicant__c aa : allApplicants) {
            if (aa.Sub_Employment_Type_Non_Individual__c != null) {
                entityApp = aa;
                break;
            }
        }
        payload.put('entity_applicant',
            buildEntityApplicant(opp, entityApp,
                entityApp != null ? addrByApplicant.get(entityApp.Id) : null));

        // ── collateral (with nested technical_evaluation) ─────
        payload.put('collateral',
            buildCollateralSection(opp, collaterals, techEvals, legals));

        // ── bank_decision ─────────────────────────────────────
        payload.put('bank_decision', buildBankDecision(opp));

        // ── bre_decision ──────────────────────────────────────
        payload.put('bre_decision', buildBreDecision(opp, product));

        // ── banking_financials ─────────────────────────────────
        List<Bank_Details__c> primaryBanks = primaryApp != null
            ? bankByApplicant.get(primaryApp.Id) : null;
        payload.put('banking_financials',
            buildBankingFinancials(opp, primaryBanks, product));

        // ── bureau_credit ─────────────────────────────────────
        payload.put('bureau_credit', buildBureauCredit(opp, primaryApp));

        // ── documents (flat array) ────────────────────────────
        payload.put('documents', buildDocuments(docs, latestCVByDocId));

        return JSON.serialize(payload);
    }

    // ═══════════════════════════════════════════════════════════
    //  SECTION BUILDERS
    // ═══════════════════════════════════════════════════════════

    // ── LOAN APPLICATION ──────────────────────────────────────
    private static Map<String, Object> buildLoanApplication(
            Opportunity opp, Product2 prod, List<Instrument_Mandate__c> instruments, String partnerBank) {
         List<Loan_Transaction__c> loanTrans = [
                        SELECT Id,First_Disbursement_Amount__c,Disbursement_Date__c
                        FROM Loan_Transaction__c 
                        WHERE Loan_Application__c = :opp.Id AND RecordType.DeveloperName = 'Transaction_Details'
                        LIMIT 1
                        ];
        List<Product2> product = [
                        SELECT Id,name FROM Product2 WHERE RecordType.name ='Sub Variant'
                        AND Loan_Application__c = :opp.Id LIMIT 1
                        ];
        Map<String, Object> m = new Map<String, Object>();
        m.put('loan_app_id',               s(opp.Loan_Application_Number__c));
        // m.put('roi_type',                   product.isEmpty() ? null : product[0].name);
        m.put('roi_type',  product.isEmpty() ? null : ('DEMI'.equalsIgnoreCase(product[0].name) ? 'CAT2' : 'CAT1'));
        m.put('first_disbursement_date',   loanTrans.isEmpty() ? null : loanTrans[0].Disbursement_Date__c);
        
        // ═══ CHANGE 1: Pass the Opportunity Id ═══
        m.put('opp_id',                    s(opp.Id));

        m.put('product_type',              s(opp.Product__c));
        m.put('product_variant_code',      s(opp.Sub_Product__c));
        m.put('loan_purpose',              s(opp.Loan_Purpose__c));
        m.put('loan_facility',             s(opp.Loan_Facility__c));
        m.put('repayment_variant_code',    s(opp.Repayment_Facility__c));
        m.put('requested_loan_amount',     opp.Requested_Amount__c);
        m.put('tenor_months',              opp.Requested_Tenure_in_Months__c);
        m.put('no_of_applicants',          opp.No_of_Applicants__c);

        m.put('sourcing_branch_code',      s(opp.Branch_Master__r.branch_code__c ));
        m.put('loan_branch_code',          s(opp.Sub_Branch__r.name));
        m.put('channel_category_code',     s(opp.Channel_Type__c));
        m.put('dsa_name',                  s(opp.Channel_Name__c));

        // ═══ CHANGE 2: Hardcode partner_bank_name ═══
        // m.put('partner_bank_name',         'Bajaj finance ltd');
        m.put('partner_bank_name',         partnerBank);
        System.debug('Partner Bank: ' + partnerBank);
        System.debug('first_disbursement_amount: ' + (loanTrans.isEmpty() ? null : loanTrans[0].First_Disbursement_Amount__c));
        System.debug('roi_type: ' + (product.isEmpty() ? null : product[0].name));

        m.put('sanctioned_amount',         opp.Sanction_Loan_Amount__c);
        m.put('sanctioned_tenor_months',   opp.Sanction_Tenure__c);
        m.put('total_finance_amount',      opp.Final_Amount__c);
        m.put('final_roi_pct',             opp.Final_Rate_Of_Interest__c);
        m.put('total_fee',                 opp.Total_Stamp_Duty__c);
        m.put('emi_amount',                opp.Emi_amount__c);
        m.put('first_disbursement_amount', loanTrans.isEmpty() ? null : loanTrans[0].First_Disbursement_Amount__c);
        m.put('loan_start_date',           dt(opp.Loan_Unassigned_DateTime__c));
        m.put('application_request_date',  dt(opp.CreatedDate));
        m.put('sanction_date',             d(opp.Sanction_Date__c));
        m.put('psl_category_code',         s(opp.PSL_Code__c));

        // Rate & repayment
        m.put('actual_interest_rate_pct',  opp.Final_Rate_Of_Interest__c);
        m.put('stp_status',               s('STP'));
        // m.put('colending_ratio',           s(opp.Co_lending__c));
        m.put('colending_ratio',         '90');


        // Benchmark & spread fields
        m.put('base_rate_benchmark',       prod != null ? s(prod.PLR_Value__c) : null);
        m.put('billing_date',              null);

        // ═══ FIX 1: number_of_installments must be a number, not a string ═══
        m.put('number_of_installments',    toNum(opp.Total_Tenure__c));

        // Stage & status
        m.put('loan_stage',                s(opp.StageName));
        m.put('approval_status',           s(opp.Approval_Status__c));
        m.put('approval_sub_status',       s(opp.Approval_Sub_Status__c));
        m.put('loan_category',             s(opp.Loan_Category__c));
        m.put('fcu_status',               s(opp.FCU_Status__c));
        m.put('hunter_decision',           s(opp.Hunter_Decision__c));
        m.put('docgen_status',             s(opp.DocGen_Status__c));
        m.put('income_approval_status',    s(opp.Income_Approval_Status__c));
        m.put('pricing_approval_status',   s(opp.Pricing_Approval_Status__c));
        m.put('exception_approval_status', s(opp.Exception_Approval_Status__c));
        m.put('rejection_reason',          s(opp.Reasons_for_Rejecting_Loan__c));
        m.put('application_source',        s(opp.Application_Source__c));
        m.put('pd_done_by',               s(opp.Credit_Underwriter__c));

        // Dates & disbursement
        // m.put('first_disbursement_date',   d(opp.Credit_Date__c));
        m.put('maturity_date',             d(opp.CloseDate));
        m.put('moratorium_applicable',     opp.Hybrid_Tenure__c != null);

        // ═══ FIX 2: moratorium_tenure_months must be a number, not a string ═══
        m.put('moratorium_tenure_months',  toNum(opp.Hybrid_Tenure__c));

        m.put('pre_emi_applicable',        opp.Full_EMI__c);
        m.put('pre_emi_amount',            opp.Emi_amount__c);
        m.put('pmay_flag',                 opp.PMAY_flag__c);
        m.put('first_time_home_buyer',     opp.First_time_home_buyer__c);
        m.put('flexi_fund_variant',        s(opp.Flexi_Fund_Variant__c));

        return m;
    }

    // ── PRIMARY APPLICANT ─────────────────────────────────────
    private static Map<String, Object> buildPrimaryApplicant(
            Opportunity opp,
            Application_Applicant__c pa,
            List<Applicant_Address__c> addrs,
            Application_Verification__c verif) {

        Map<String, Object> m = new Map<String, Object>();
        m.put('loan_app_id', s(opp.Loan_Application_Number__c));

        if (pa == null) { return m; }

        // Basic Details
        m.put('salutation',          s(pa.Salutation__c));
        m.put('first_name',          s(pa.First_Name__c));
        m.put('middle_name',         s(pa.Middle_Name__c));
        m.put('last_name',           s(pa.Last_Name__c));
        m.put('internal_dedupe_status', s(pa.Customer_Tagged_From_Dedupe__c));
        m.put('external_dedupe_status', s(pa.Negative_list_dispostion__c));
        m.put('date_of_birth',       d(pa.DOB__c));
        m.put('gender',              s(pa.Gender__c));
        m.put('nationality_code',    s(pa.Nationality__c));
        m.put('citizenship',         s(pa.Citizenship__c));

        m.put('father_name',         joinNames(pa.Father_s_First_Name__c,
                                            pa.Father_s_Middle_Name__c,
                                            pa.Father_s_Last_Name__c));
        m.put('mother_name',         joinNames(pa.Mother_s_First_Name__c,
                                            pa.Mother_s_Middle_Name__c,
                                            pa.Mother_s_Last_Name__c));
        m.put('marital_status',      s(pa.Marital_Status__c));
        m.put('spouse_name',         joinNames(pa.Spouse_First_Name__c,
                                            pa.Spouse_Middle_Name__c,
                                            pa.Spouse_Last_Name__c));

        m.put('pan',                 s(pa.PAN_Number__c));
        m.put('mobile_number',       s(pa.Mobile_Number__c));
        m.put('primary_email',       s(pa.Email__c));
        m.put('alternate_email',     s(pa.Alternate_Email__c));

        // Address (first match from list)
        Applicant_Address__c addr = (addrs != null && !addrs.isEmpty()) ? addrs[0] : null;
        m.put('current_pin',              addr != null ? s(addr.Pincode__r.name) : null);
        m.put('current_state',            addr != null ? s(addr.State__c) : null);
        m.put('current_city',             addr != null ? s(addr.City__c) : null);
        m.put('current_addr_line1',       addr != null ? s(addr.Address_Line_1__c) : null);
        m.put('current_addr_line2',       addr != null ? s(addr.Address_Line_2__c) : null);
        m.put('current_addr_line3',       addr != null ? s(addr.Address_Line_3__c) : null);
        m.put('perm_addr_same_as_current', addr != null ? addr.Is_Current_Address_Same_As_Permanent__c : null);
        m.put('perm_addr_line1',          addr != null ? s(addr.Permanent_Address_Line_1__c) : null);
        m.put('perm_addr_line2',          addr != null ? s(addr.Permanent_Address_Line_2__c) : null);
        m.put('perm_addr_line3',          addr != null ? s(addr.Permanent_Address_Line_3__c) : null);
        m.put('address_type',             addr != null ? s(addr.Address_Type__c) : null);
        m.put('block_taluka',             addr != null ? s(addr.Address_Line_3__c) : null);
        m.put('residence_ownership_type', addr != null ? s(addr.Address_Ownership__c) : null);

        // Bureau / KYC
        m.put('bureau_above_threshold',   pa.Is_Hunter_Executed__c);
        m.put('ogl_tag',                  verif != null ? verif.OGL__c : null);
        m.put('education',               s(pa.Other_Qualification__c));
        m.put('qualification',           s(pa.Qualification__c));
        m.put('ckyc_status',             s(pa.CKYC_Aadhar__c));
        m.put('aadhaar_masked',          s(pa.Masked_Aadhar_Number__c));
        m.put('mnrl_check_status',       s(pa.Is_MNRL_Blacklisted__c));
        m.put('bureau_score_cibil',      pa.CIBIL_Score__c);
        m.put('bureau_pull_date',        null);
        m.put('pep_flag',               toBool(pa.PEP__c));
        m.put('aml_check_status',        s(pa.Negative_list_dispostion__c));

        // Income
        m.put('total_annual_income',      pa.Annual_Total_Income__c);
        m.put('occupation',              s(pa.Applicant_Type__c));
        m.put('occupation_category_code', s(pa.Sub_Employment_Type__c));
        m.put('foir_current_pct',         opp.FOIR__c);
        m.put('foir_post_emi_pct',        opp.FOIR__c);

        // Employment
        m.put('employer_name_code',      s(pa.Employer_Name__c));
        m.put('employer_type_code',      s(pa.Employer_Type__c));
        m.put('employer_industry_code',  s(pa.Employer_Industry__c));
        m.put('designation_code',        s(pa.Designation__c));
        m.put('employment_start_date',   d(pa.Date_of_Joining__c));
        m.put('profession_code',         s(pa.Profession__c));
        m.put('official_email',          s(pa.Official_Mail_ID__c));
        m.put('employee_id',            s(pa.Employee_ID__c));
        m.put('monthly_salary',          pa.Monthly_Salary__c);
        m.put('current_work_exp',        joinExp(pa.Current_Work_Experience_Years__c,
                                                pa.Current_Work_Experience_Months__c));
        m.put('total_work_exp',          joinExp(pa.Total_Work_Experience_Years__c,
                                                pa.Total_Work_Experience_Months__c));

        // Social
        m.put('religion',          s(pa.Religion__c));
        m.put('caste_category',    s(pa.Cast_Category__c));
        m.put('disability',        s(pa.Disability__c));

        // Extended Income & Identity
        m.put('employment_type',        s(pa.Applicant_Type__c));
        m.put('income_method',          s(pa.Income_Method__c));
        m.put('contract_type',          s(pa.Contract_Type__c));
        m.put('num_of_dependents',      pa.No_of_Associated_Entities__c);

        // SENP Financials
        m.put('senp_turnover_latest',    opp.Amount_of_Cash_Surplus_for_PY1_Rs__c);
        m.put('senp_net_pbt_latest',     opp.Cash_Surplus_Rs__c);
        m.put('senp_gross_profit_latest', opp.Total_Amount_of_Cash_Surplus_Rs__c);
        m.put('senp_cash_profit_latest', opp.Amount_of_Cash_Surplus_for_PY2_Rs__c);
        m.put('senp_turnover_prev',      opp.Amount_of_Cash_Surplus_for_PY3_Rs__c);
        m.put('senp_net_pbt_prev',       opp.Amount_of_Cash_Surplus_for_PY4_Rs__c);

        // KYC & Identity
        m.put('crif_score',             pa.CRIF_Score__c);
        m.put('kyc_risk_category',      s(pa.KYC_Risk_Categorisation_Category__c));
        m.put('is_existing_customer',   pa.Is_Existing_Customer__c);
        m.put('customer_cif',           s(opp.LMS_Loan_Reference__c));
        m.put('aadhaar_kyc_verified',   pa.Aadhaar_KYC_Verified__c);
        m.put('pan_kyc_verified',       pa.PAN_KYC_Verified__c);
        m.put('form_60_uploaded',       toBool(pa.IsForm60Uploaded__c));

        return m;
    }

    // ── CO-APPLICANT (single item – called per co-applicant) ──
    private static Map<String, Object> buildCoApplicant(
            Opportunity opp,
            Application_Applicant__c ca,
            List<Applicant_Address__c> addrs,
            Application_Verification__c verif) {

        Map<String, Object> m = new Map<String, Object>();

        if (ca == null) { return m; }

        m.put('co_app_category',         s(ca.Applicant_Type__c));
        m.put('co_app_type',             s(ca.Sub_Employment_Type_Non_Individual__c));
        m.put('is_financial',            ca.Financial_Non_Financial__c);
        m.put('key_applicant_flag',      ca.Is_Key_Applicant__c);
        m.put('relationship_with_primary', s(ca.Relationship_with_Primary_Applicant__c));

        m.put('pan',              s(ca.PAN_Number__c));
        m.put('salutation',      s(ca.Salutation__c));
        m.put('first_name',      s(ca.First_Name__c));
        m.put('middle_name',     s(ca.Middle_Name__c));
        m.put('last_name',       s(ca.Last_Name__c));
        m.put('date_of_birth',   d(ca.DOB__c));
        m.put('gender',          s(ca.Gender__c));
        m.put('nationality_code', s(ca.Nationality__c));
        m.put('citizenship',     s(ca.Citizenship__c));

        m.put('father_name',     joinNames(ca.Father_s_First_Name__c,
                                        ca.Father_s_Middle_Name__c,
                                        ca.Father_s_Last_Name__c));
        m.put('mother_name',     joinNames(ca.Mother_s_First_Name__c,
                                        ca.Mother_s_Middle_Name__c,
                                        ca.Mother_s_Last_Name__c));
        m.put('marital_status',  s(ca.Marital_Status__c));
        m.put('spouse_name',     joinNames(ca.Spouse_First_Name__c,
                                        ca.Spouse_Middle_Name__c,
                                        ca.Spouse_Last_Name__c));
        m.put('mobile_number',   s(ca.Mobile_Number__c));
        m.put('primary_email',   s(ca.Email__c));
        m.put('alternate_email', s(ca.Alternate_Email__c));
        m.put('aadhaar_masked',  s(ca.Aadhaar_Number__c));

        // Address
        Applicant_Address__c addr = (addrs != null && !addrs.isEmpty()) ? addrs[0] : null;
        m.put('current_pin',          addr != null ? s(addr.Pincode__r.name) : null);
        m.put('current_state',        addr != null ? s(addr.State__c) : null);
        m.put('current_city',         addr != null ? s(addr.City__c) : null);
        m.put('current_addr_line1',   addr != null ? s(addr.Address_Line_1__c) : null);
        m.put('current_addr_line2',   addr != null ? s(addr.Address_Line_2__c) : null);
        m.put('perm_addr_line1',      addr != null ? s(addr.Permanent_Address_Line_1__c) : null);
        m.put('residence_ownership_type', addr != null ? s(addr.Address_Ownership__c) : null);
        m.put('address_type',         addr != null ? s(addr.Address_Type__c) : null);
        m.put('block_taluka',         addr != null ? s(addr.Address_Line_3__c) : null);

        // Education / Employment
        m.put('education',                s(ca.Other_Qualification__c));
        m.put('qualification',            s(ca.Qualification__c));
        m.put('university_name',          s(ca.Medical_Council_Name__c));
        m.put('occupation',               s(ca.Applicant_Type__c));
        m.put('occupation_category_code', s(ca.Sub_Employment_Type__c));
        m.put('business_address',         s(ca.Employer_Address__c));
        m.put('business_industry',        s(ca.Employer_Industry__c));
        m.put('business_vintage',         s(ca.Business_Vintage__c));
        m.put('gstin',                    s(ca.GSTIN__c));
        m.put('gst_exempt',              toBool(ca.GST_Exempt__c));
        m.put('udyam_reg_no',            s(ca.Udhyam_Registration_No__c));
        m.put('office_ownership_type',    s(ca.Office_Ownership__c));
        m.put('bureau_above_threshold',   ca.Is_Hunter_Executed__c);
        m.put('bureau_score_cibil',       ca.CIBIL_Score__c);
        m.put('ogl_tag',                  verif != null ? verif.OGL__c : null);

        // Social
        m.put('religion',          s(ca.Religion__c));
        m.put('caste_category',    s(ca.Cast_Category__c));

        // Extended
        m.put('monthly_gross_salary',  ca.Monthly_Gross_Salary__c);
        m.put('exposure_outstanding',  opp.Exposure__c);
        m.put('bureau_worst_status',   s(opp.Risk_Segment__c));

        return m;
    }

    // ── ENTITY APPLICANT ──────────────────────────────────────
    private static Map<String, Object> buildEntityApplicant(
            Opportunity opp,
            Application_Applicant__c ea,
            List<Applicant_Address__c> addrs) {

        Map<String, Object> m = new Map<String, Object>();
        m.put('loan_app_id', s(opp.Loan_Application_Number__c));

        if (ea == null) { return m; }

        m.put('business_entity_name',  s(ea.Business_Entity_Name__c));
        m.put('date_of_incorporation', d(ea.DOI__c));
        m.put('business_industry',     s(ea.Employer_Industry__c));
        m.put('nature_of_business',    s(ea.Nature_of_Business__c));
        m.put('business_vintage',      s(ea.Business_Vintage__c));
        m.put('constitution',          s(ea.Customer_Type__c));

        Applicant_Address__c addr = (addrs != null && !addrs.isEmpty()) ? addrs[0] : null;
        m.put('address_type',    addr != null ? s(addr.Address_Type__c) : null);
        m.put('address_pin',     addr != null ? s(addr.Pincode__r.name) : null);
        m.put('address_city',    addr != null ? s(addr.City__c) : null);
        m.put('address_state',   addr != null ? s(addr.State__c) : null);
        m.put('address_line1',   addr != null ? s(addr.Address_Line_1__c) : null);
        m.put('address_line2',   addr != null ? s(addr.Address_Line_2__c) : null);

        m.put('psl_category_code',   s(ea.PSL__c));
        m.put('registration_number', s(ea.Registration_Number__c));
        m.put('udyam_reg_no',        s(ea.Udhyam_Registration_No__c));
        m.put('office_ownership_type', s(ea.Office_Ownership__c));
        m.put('gst_exempt',          toBool(ea.GST_Exempt__c));
        m.put('gstin',               s(ea.GSTIN__c));
        m.put('shareholder_name',    s(ea.Shareholder_Partner_Name__c));
        m.put('shareholding_ratio_pct', ea.Share_Holding_Percentage__c);
        m.put('cin_llpin',           s(opp.CIN_LLPIN_number__c));
        m.put('pan_entity',          s(ea.PAN_Number__c));
        m.put('aml_check_status',    s(ea.Negative_list_dispostion__c));
        m.put('ubo_details',         joinNames(ea.Shareholder_Partner_Name__c,
                                            null,
                                            String.valueOf(ea.Share_Holding_Percentage__c)));

        m.put('total_annual_income',      ea.Annual_Total_Income__c);
        m.put('occupation',               s(ea.Applicant_Type__c));
        m.put('occupation_category_code', s(ea.Sub_Employment_Type__c));

        return m;
    }

    // ── COLLATERAL SECTION (with nested technical_evaluation) ─
    private static Map<String, Object> buildCollateralSection(
            Opportunity opp,
            List<Collateral__c> collaterals,
            List<Technical_Evaluation__c> techEvals,
            List<Legal__c> legals) {

        Map<String, Object> section = new Map<String, Object>();
        section.put('loan_app_id', s(opp.Loan_Application_Number__c));

        List<Map<String, Object>> items = new List<Map<String, Object>>();

        Technical_Evaluation__c te = (techEvals != null && !techEvals.isEmpty())
            ? techEvals[0] : null;
        Legal__c leg = (legals != null && !legals.isEmpty())
            ? legals[0] : null;

        if (collaterals != null && !collaterals.isEmpty()) {
            for (Collateral__c col : collaterals) {
                items.add(buildCollateralItem(opp, col, techEvals, legals));
            }
        } else {
            items.add(buildCollateralItem(opp, null, techEvals, legals));
        }

        section.put('items', items);
        return section;
    }

    private static Map<String, Object> buildCollateralItem(
            Opportunity opp, Collateral__c col,
            List<Technical_Evaluation__c> techEvals, List<Legal__c> legals) {

        Map<String, Object> m = new Map<String, Object>();

        Technical_Evaluation__c te = (techEvals != null && !techEvals.isEmpty())
            ? techEvals[0] : null;
        Legal__c leg = (legals != null && !legals.isEmpty())
            ? legals[0] : null;

        // From Opportunity
        m.put('property_identified',    opp.Is_Property_Identified__c);
        m.put('apf_flag',               opp.HL_APF_Approved__c);
        m.put('property_type',           s(opp.Property_Type__c));
        m.put('construction_stage',      s(opp.HL_Construction_Stage__c));
        m.put('estimated_value',         opp.Total_Valuation__c);
        m.put('gpl_flag',               opp.Pucca_house__c);

        // ═══ FIX 3: property_insurance_flag must be a boolean, not a string ═══
        // m.put('property_insurance_flag', opp.Stamp_Paper__c != null
        //     && String.isNotBlank(String.valueOf(opp.Stamp_Paper__c)));
        m.put('property_insurance_flag', opp.Stamp_Paper__c);
       
        m.put('collateral_dedupe_status', s(opp.Collateral_Categorization__c));
        m.put('threshold_match_score',   s(opp.Collateral_Segmentation__c));
        // m.put('site_visit_conducted',    opp.GBL_Met__c);
        m.put('site_visit_project_name', s(opp.Entity_1__c));
        m.put('person_met_at_site',      s(opp.Entity_2__c));
        m.put('lv_waiver',              opp.SBL_Met__c);
        m.put('flexi_loan_flag',         s(opp.Flexi_Fund_Variant__c));
        m.put('property_city',           s(opp.Collateral_Area_Pincode__r.city__r.name));
        m.put('property_pin',            s(opp.Collateral_Area_Pincode__r.name));

        // From Collateral__c
        if (col != null) {
           m.put('site_visit_conducted',   s(col.Site_Visit_Conducted_by_Sales__c));
            // m.put('site_visit_conducted',
            // 'Yes'.equalsIgnoreCase(String.valueOf(col.Site_Visit_Conducted_by_Sales__c)) ? true : false);
            m.put('project_name',          s(col.Project__r.Name));
            m.put('tower_building_name',   s(col.Tower_Building_Name__c));
            m.put('floor_code',            s(col.Floor_Number__c));
            m.put('unit_number',           s(col.Unit_Number__c));
            m.put('rera_reg_no',           s(col.RERA_Registration_Number__c));
            m.put('carpet_area_sqm',       col.Carpet_Area_of_Residential_Unit_sq_m__c);
            m.put('area_plot',             col.Area_of_Plot_Area__c);
            m.put('num_floors_constructed', col.Number_of_floors_constructed__c);
            m.put('age_of_property_years', col.Age_of_Property__c);
            m.put('occupancy_since',       s(col.Occupancy_Since__c));
        } else {
            m.put('project_name', null);
            m.put('developer_name', null);
            m.put('tower_building_name', null);
            m.put('floor_code', null);
            m.put('unit_number', null);
            m.put('rera_reg_no', null);
            m.put('carpet_area_sqm', null);
            m.put('area_plot', null);
            m.put('num_floors_constructed', null);
            m.put('payment_plan_type_code', null);
            m.put('age_of_property_years', null);
            m.put('occupancy_since', null);
        }

        // Fields sourced from Technical_Evaluation__c but kept at item level per schema
        m.put('property_description_code', te != null ? s(te.Property_Category_Description__c) : null);
        m.put('documented_value',          te != null ? te.Market_Value_Of_Property__c: null);
        m.put('final_tv_amount',           te != null ? te.Market_Value_Of_Property__c : null);

        // Fields without a direct collateral source default to null
        m.put('ownership_type_code', null);
        m.put('occupancy_type_code', null);
        m.put('num_tenants_occupants', null);
        m.put('property_addr_line1', col != null ? s(col.Address_Line_1__c) : null);
        m.put('property_addr_line2', col != null ? s(col.Address_Line_2__c) : null);
        m.put('property_addr_line3', col != null ? s(col.Address_Line_3__c) : null);
        m.put('property_address_type', null);
        m.put('block_taluka', null);

        // ── NESTED technical_evaluation array ─────────────────
        List<Map<String, Object>> teList = new List<Map<String, Object>>();
        if (techEvals != null && !techEvals.isEmpty()) {
            for (Technical_Evaluation__c teval : techEvals) {
                teList.add(buildTechnicalEvaluation(opp, teval, leg));
            }
        } else {
            teList.add(buildTechnicalEvaluation(opp, null, leg));
        }
        m.put('technical_evaluation', teList);

        return m;
    }

    /** Builds a single technical_evaluation sub-object (includes legal fields) */
    private static Map<String, Object> buildTechnicalEvaluation(
            Opportunity opp, Technical_Evaluation__c te, Legal__c leg) {

        Map<String, Object> m = new Map<String, Object>();

        // Technical fields
        m.put('plot_flat_khasra_no',    te != null ? s(te.HL_Plot_No_Flat_No_Khasra_No__c) : null);
        m.put('scheme_colony_building', te != null ? s(te.HL_Scheme_Colony_Building_Street_Name__c) : null);
        m.put('district',              te != null ? s(te.District__c) : null);
        m.put('village',               te != null ? s(te.HL_Village__c) : null);
        m.put('tehsil',               te != null ? s(te.HL_Tehsil__c) : null);
        m.put('tech_town_city',        te != null ? s(te.City__c) : null);
        m.put('tech_state',            te != null ? s(te.State__c) : null);
        m.put('tech_property_area',    te != null ? s(te.HL_Area_of_Property__c) : null);
        m.put('north_boundary',        te != null ? s(te.Plot_Bounded_by_North__c) : null);
        m.put('south_boundary',        te != null ? s(te.Plot_Bounded_by_South__c) : null);
        m.put('east_boundary',         te != null ? s(te.Plot_Bounded_by_East__c) : null);
        m.put('west_boundary',         te != null ? s(te.Plot_Bounded_by_West__c) : null);
        m.put('valuation_upload_date', te != null ? d(te.HL_Date_of_Valuation__c) : null);
        m.put('valuation_agency_code', te != null ? s(te.HL_Vendor_Agency__c) : null);
        m.put('market_value',          te != null ? te.Market_Value_Of_Property__c: null);
        m.put('property_usage_code',   s(opp.End_Use_of_Fund__c));
        m.put('cersai_date',           null);

        return m;
    }

    // ── BANK DECISION ─────────────────────────────────────────
    private static Map<String, Object> buildBankDecision(Opportunity opp) {
        Map<String, Object> m = new Map<String, Object>();
        m.put('loan_app_id',              s(opp.Loan_Application_Number__c));
        m.put('bank_decision',            s(opp.Approval_Status__c));
        m.put('bank_remarks',             s(opp.Approval_Comments__c));
        m.put('bank_sanctioned_amount',   opp.Sanction_Loan_Amount__c);
        m.put('bank_interest_rate_pct',   opp.Final_Rate_Of_Interest__c);
        m.put('approved_ltv_pct',         null);
        m.put('reject_reason_code',       s(opp.Reasons_for_Rejecting_Loan__c));
        m.put('refer_back_reason',        s(opp.Send_Back_Remarks__c));
        m.put('bank_officer_name',        null);
        m.put('bank_officer_emp_id',      null);
        m.put('bank_decision_timestamp',  dt(opp.Sanction_Date__c));
        m.put('bank_sanction_ref_no',     s(opp.Loan_Application_Number__c));
        m.put('bank_decision_status',     s(opp.Approval_Status__c));

        // ═══ FIX 4: dual_sanction_completion must be a boolean, not a record ID ═══
        m.put('dual_sanction_completion', opp.Authorized_Signatory__c != null);

        return m;
    }

    // ── BRE DECISION ──────────────────────────────────────────
    private static Map<String, Object> buildBreDecision(
            Opportunity opp, Product2 prod) {

        Map<String, Object> m = new Map<String, Object>();
        m.put('loan_app_id',              s(opp.Loan_Application_Number__c));
        m.put('product_category',         prod != null ? s(prod.Product_Type__c) : null);
        m.put('base_rate_pct',            prod != null ? prod.PLR_Value__c : null);
        m.put('sanctioned_roi_min_pct',   prod != null ? prod.Min_ROI__c : null);
        m.put('sanctioned_roi_max_pct',   prod != null ? prod.MAX_ROI__c : null);
        m.put('negotiated_loan_amount',   opp.Negotiated_Loan_Amount__c);
        m.put('negotiated_roi_pct',       opp.Negotiated_Rate_Of_Interest__c);
        m.put('negotiated_tenure_months', opp.Negotiated_Tenure__c);
        m.put('recommended_loan_amount',  prod != null ? prod.Recommended_Loan_Amount__c : null);
        m.put('eligible_loan_amount',     opp.Eligible_Loan_Amount__c);
        m.put('rental_income_program',    opp.Program__c);
        m.put('psl_flag',                toBool(opp.Loan_Eligible_for_PSL__c));
        m.put('bre_decision_datetime',    dt(opp.DocGen_Initiated_Time__c));
        m.put('final_approval_level',     s(opp.Approval_Type__c));
        m.put('max_ltv_allowed_pct',      prod != null ? prod.LTV__c : null);
        m.put('max_eligible_loan_ltv',    opp.Eligible_Loan_Amount__c);
        m.put('max_eligible_loan_income', opp.Eligible_Loan_Amount__c);
        m.put('max_foir_salaried_pct',    opp.FOIR__c);
        m.put('max_foir_senp_pct',        opp.FOIR__c);
        m.put('se_risk_score',            opp.Risk_Score__c);
        m.put('se_risk_segment',          s(opp.Risk_Segment__c));
        return m;
    }

    // ── BANKING & FINANCIALS ──────────────────────────────────
    private static Map<String, Object> buildBankingFinancials(
            Opportunity opp,
            List<Bank_Details__c> bankDets,
            Product2 prod) {

        Map<String, Object> m = new Map<String, Object>();
        m.put('loan_app_id', s(opp.Loan_Application_Number__c));

        Bank_Details__c bd = (bankDets != null && !bankDets.isEmpty()) ? bankDets[0] : null;
        m.put('repayment_account_no', bd != null ? s(bd.Account_Number__c) : null);
        m.put('bank_name',            bd != null ? s(bd.Bank_Name__c) : null);
        m.put('ifsc_code',            bd != null ? s(bd.IFSC__c) : null);
        m.put('account_holder_name',  bd != null ? s(bd.Account_Holder_Name__c) : null);
        m.put('account_type',         bd != null ? s(bd.Account_Type__c) : null);
        m.put('is_repayment_account', bd != null ? bd.Is_Repayment_Account__c : null);
        m.put('is_disbursal_account', bd != null ? bd.Is_Disbursal_Account__c : null);
        m.put('od_cc_limit',          bd != null ? bd.OD_CC_Limit__c : null);

        m.put('abb_avg_bank_balance',  opp.Banking_Index__c);
        m.put('emi_bounce_l3m',        null);
        m.put('emi_bounce_l6m',        null);
        m.put('emi_bounce_l12m',       null);

        m.put('ext_liabilities_instalment', opp.Drawing_Power_Amount__c);
        m.put('existing_loan_pos',          opp.Parent_Loan_Amount__c);
        m.put('total_proposed_exposure',    prod != null ? prod.Total_ProposedExposure__c : null);
        m.put('household_income',           opp.Household_Income__c);
        m.put('debt_equity_ratio',         opp.Risk_Score__c);
        m.put('abb_emi_ratio',              opp.CAGR_in_percentage__c);

        return m;
    }

    // ── BUREAU & CREDIT ───────────────────────────────────────
    private static Map<String, Object> buildBureauCredit(
            Opportunity opp, Application_Applicant__c pa) {

        Map<String, Object> m = new Map<String, Object>();
        m.put('loan_app_id',             s(opp.Loan_Application_Number__c));
        m.put('bureau_ref_no',           pa != null ? s(pa.LMS_Id__c) : null);
        m.put('enquiries_l3m',           pa != null ? pa.No_of_enquiries_in_last_3m__c : null);
        m.put('live_hl_lap_outstanding', opp.Pending_loan_to_cover_Under_Collateral__c);
        m.put('live_hl_lap_emi',         opp.EMI_Amount_Repayment_Schedule__c);
        m.put('live_pl_outstanding',     opp.Parent_Loan_Amount__c);
        m.put('live_pl_emi',             opp.Sanction_EMI__c);
        m.put('live_cc_outstanding',     opp.Total_Combined_Wealth__c);
        m.put('any_dpd_l12m',           opp.Negative_list_dispostion__c);
        m.put('plus60_dpd_l3m',          opp.No_of_Associated_Entities__c);
        m.put('derog_writeoff_flag',     s(opp.Detailed_Rejection_Reason__c));
        m.put('restructured_flag',       s(opp.Is_Send_Back__c));
        return m;
    }

    // ═══════════════════════════════════════════════════════════
    //  DOCUMENTS  (CHANGE 3 – pass latest ContentVersion Id
    //              and actual file type per document)
    // ═══════════════════════════════════════════════════════════

    /**
     * Builds the documents array.
     * For each Document_Details__c that has a Content_Document_Id__c,
     * looks up the latest ContentVersion (by CreatedDate DESC) from the
     * pre-queried map and emits its Id as document_obj_id and its
     * FileExtension (lowercased) as document_type.
     * Documents without a matching ContentVersion are skipped.
     */
    private static List<Map<String, Object>> buildDocuments(
            List<Document_Details__c> docs,
            Map<Id, ContentVersion> latestCVByDocId) {

        List<Map<String, Object>> items = new List<Map<String, Object>>();
        if (docs == null) return items;

        for (Document_Details__c dd : docs) {
            // Skip documents without a Content Document Id
            if (String.isBlank(dd.Content_Document_Id__c)) {
                continue;
            }

            Id contentDocId;
            try {
                contentDocId = Id.valueOf(dd.Content_Document_Id__c);
            } catch (Exception e) {
                continue; // skip invalid Ids
            }

            ContentVersion cv = latestCVByDocId.get(contentDocId);
            // Skip if no ContentVersion found for this ContentDocument
            if (cv == null) {
                continue;
            }
            // "documents": [
            //     {
            //         "document_key": "PAN",
            //         "document_obj_id": "068XXXXXXXXXXXXXXX",
            //         "file_type": "pdf",
            //         "document_type": "Identity Proof",
            //         "applicant_name": "John Doe",
            //         "applicant_type": "Primary Applicant",
            //         "document_name": "PAN Card",
            //         "doc_size": 102400,
            //         "doc_original_name": "pan_card.pdf",
            //         "uploaded_at": "2026-06-16T10:30:00.000Z",
            //         "uploaded_by": "sfdc.user@example.com"
            //     }
            //     ]
            Map<String, Object> item = new Map<String, Object>();
            item.put('document_key',    s(dd.document_master__r.Document_Category__c));
            // Pass the latest ContentVersion Id instead of the ContentDocument Id
            item.put('document_obj_id', s(cv.Id));
            // Pass the actual file extension (e.g. pdf, jpg, png, docx) lowercased
            item.put('file_type',   cv.FileExtension != null
                ? cv.FileExtension.toLowerCase() : null);
            item.put('document_type',   s(dd.Name));
            item.put('applicant_name',   s(dd.Applicant__r.First_Name__c) + ' ' + s(dd.Applicant__r.Last_Name__c));
            item.put('applicant_type',   s(dd.Applicant__r.Applicant_Type__c));
            item.put('document_name',    s(dd.Name));
            // item.put('doc_size',         cv.FileSize);
            item.put('doc_original_name', s(dd.Name));
            item.put('uploaded_at',      s(dd.CreatedDate));
            item.put('uploaded_by',      s(dd.CreatedBy.Email));    
            items.add(item);
        }
        System.debug('document_details data: ' + items);
        return items;
    }


    // ═══════════════════════════════════════════════════════════
    //  SOQL QUERIES  (field names aligned to builder methods)
    // ═══════════════════════════════════════════════════════════

    private static Opportunity queryOpportunity(Id oppId) {
        List<Opportunity> results = [
            SELECT Id, Name,
                Loan_Application_Number__c,
                Product__c,
                Sub_Product__c,
                Loan_Purpose__c,
                Loan_Facility__c,
                Repayment_Facility__c,
                Requested_Amount__c,
                Requested_Tenure_in_Months__c,
                No_of_Applicants__c,
                Branch_Master__c, branch_master__r.branch_code__c, 
                Sub_Branch__c,
                sub_branch__r.name,
                Channel_Type__c,
                Channel_Name__c,
                Sanction_Loan_Amount__c,
                Sanction_Tenure__c,
                Final_Amount__c,
                Final_Rate_Of_Interest__c,
                Total_Stamp_Duty__c,
                Emi_amount__c,
                First_Month_Interest__c,
                Loan_Unassigned_DateTime__c,
                CreatedDate,
                Sanction_Date__c,
                PSL__c,
                PSL_Code__c,
                Status__c,
                Co_lending__c,
                StageName,
                Approval_Status__c,
                Approval_Sub_Status__c,
                Loan_Category__c,
                FCU_Status__c,
                Hunter_Decision__c,
                DocGen_Status__c,
                Income_Approval_Status__c,
                Pricing_Approval_Status__c,
                Exception_Approval_Status__c,
                Reasons_for_Rejecting_Loan__c,
                Detailed_Rejection_Reason__c,
                Application_Source__c,
                Credit_Underwriter__c,
                Credit_Date__c,
                CloseDate,
                Total_Tenure__c,
                Hybrid_Tenure__c,
                Full_EMI__c,
                PMAY_flag__c,
                First_time_home_buyer__c,
                Flexi_Fund_Variant__c,
                CIN_LLPIN_number__c,
                Approval_Comments__c,
                Send_Back_Remarks__c,
                Authorized_Signatory__c,
                Loan_Division__c,
                FOIR__c,
                Collateral_Area_Pincode__c,
                Collateral_Area_Pincode__r.city__r.name, 
                Collateral_Area_Pincode__r.name, 
                Property_Value__c,
                Property_Type__c,
                HL_APF_Approved__c,
                HL_Construction_Stage__c,
                Total_Valuation__c,
                End_Use_of_Fund__c,
                Pucca_house__c,
                Stamp_Paper__c,
                Collateral_Categorization__c,
                Collateral_Segmentation__c,
                GBL_Met__c,
                SBL_Met__c,
                Entity_1__c,
                Entity_2__c,
                Negotiated_Loan_Amount__c,
                Negotiated_Rate_Of_Interest__c,
                Negotiated_Tenure__c,
                Eligible_Loan_Amount__c,
                Program__c,
                Loan_Eligible_for_PSL__c,
                DocGen_Initiated_Time__c,
                Approval_Type__c,
                Risk_Score__c,
                Risk_Segment__c,
                LMS_Loan_Reference__c,
                Banking_Index__c,
                Drawing_Power_Amount__c,
                Parent_Loan_Amount__c,
                Household_Income__c,
                CAGR_in_percentage__c,
                Exposure__c,
                Amount_of_Cash_Surplus_for_PY1_Rs__c,
                Cash_Surplus_Rs__c,
                Total_Amount_of_Cash_Surplus_Rs__c,
                Amount_of_Cash_Surplus_for_PY2_Rs__c,
                Amount_of_Cash_Surplus_for_PY3_Rs__c,
                Amount_of_Cash_Surplus_for_PY4_Rs__c,
                Pending_loan_to_cover_Under_Collateral__c,
                EMI_Amount_Repayment_Schedule__c,
                Sanction_EMI__c,
                Total_Combined_Wealth__c,
                Negative_list_dispostion__c,
                No_of_Associated_Entities__c,
                Is_Send_Back__c,
                Is_Form_60_Uploaded__c,
                Loan_to_senior_official__c,
                Is_Property_Identified__c
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];
        return results.isEmpty() ? null : results[0];
    }

    private static List<Application_Applicant__c> queryApplicants(Id oppId) {
        return [
            SELECT Id,
                Applicant_Type__c,
                Salutation__c,
                First_Name__c,
                Middle_Name__c,
                Last_Name__c,
                Customer_Tagged_From_Dedupe__c,
                Negative_list_dispostion__c,
                DOB__c,
                Gender__c,
                Nationality__c,
                Citizenship__c,
                Father_s_First_Name__c,
                Father_s_Middle_Name__c,
                Father_s_Last_Name__c,
                Mother_s_First_Name__c,
                Mother_s_Middle_Name__c,
                Mother_s_Last_Name__c,
                Marital_Status__c,
                Spouse_First_Name__c,
                Spouse_Middle_Name__c,
                Spouse_Last_Name__c,
                PAN_Number__c,
                Mobile_Number__c,
                Email__c,
                Alternate_Email__c,
                Pincode__c,
                pincode__r.name, 
                Is_Hunter_Executed__c,
                Other_Qualification__c,
                Qualification__c,
                CKYC_Aadhar__c,
                Masked_Aadhar_Number__c,
                Is_MNRL_Blacklisted__c,
                CIBIL_Score__c,
                PEP__c,
                Annual_Total_Income__c,
                Sub_Employment_Type__c,
                Employer_Name__c,
                Employer_Type__c,
                Employer_Industry__c,
                Designation__c,
                Date_of_Joining__c,
                Profession__c,
                Official_Mail_ID__c,
                Employee_ID__c,
                Monthly_Salary__c,
                Current_Work_Experience_Years__c,
                Current_Work_Experience_Months__c,
                Total_Work_Experience_Years__c,
                Total_Work_Experience_Months__c,
                Religion__c,
                Cast_Category__c,
                Disability__c,
                Income_Method__c,
                Contract_Type__c,
                No_of_Associated_Entities__c,
                CRIF_Score__c,
                KYC_Risk_Categorisation_Category__c,
                Is_Existing_Customer__c,
                Aadhaar_KYC_Verified__c,
                PAN_KYC_Verified__c,
                IsForm60Uploaded__c,
                LMS_Id__c,
                No_of_enquiries_in_last_3m__c,
                // Co-applicant specific
                Financial_Non_Financial__c,
                Is_Key_Applicant__c,
                Relationship_with_Primary_Applicant__c,
                Sub_Employment_Type_Non_Individual__c,
                Aadhaar_Number__c,
                Medical_Council_Name__c,
                Business_Vintage__c,
                GSTIN__c,
                GST_Exempt__c,
                Udhyam_Registration_No__c,
                Office_Ownership__c,
                Employer_Address__c,
                Employer_Pin_Code__c,
                Monthly_Gross_Salary__c,
                Monthly_Net_Salary__c,
                // Entity specific
                Business_Entity_Name__c,
                DOI__c,
                Nature_of_Business__c,
                Customer_Type__c,
                PSL__c,
                Registration_Number__c,
                Shareholder_Partner_Name__c,
                Share_Holding_Percentage__c
            FROM Application_Applicant__c
            WHERE Loan_Application__c = :oppId
        ];
    }

    private static Map<Id, List<Applicant_Address__c>> queryAddresses(Set<Id> applicantIds) {
        Map<Id, List<Applicant_Address__c>> result = new Map<Id, List<Applicant_Address__c>>();
        if (applicantIds == null || applicantIds.isEmpty()) return result;

        for (Applicant_Address__c addr : [
            SELECT Id,
                Applicant__c,
                Pincode__c,
                pincode__r.name, 
                State__c,
                City__c,
                Address_Line_1__c,
                Address_Line_2__c,
                Address_Line_3__c,
                Is_Current_Address_Same_As_Permanent__c,
                Permanent_Address_Line_1__c,
                Permanent_Address_Line_2__c,
                Permanent_Address_Line_3__c,
                Address_Type__c,
                Address_Ownership__c
            FROM Applicant_Address__c
            WHERE Applicant__c IN :applicantIds
        ]) {
            if (!result.containsKey(addr.Applicant__c)) {
                result.put(addr.Applicant__c, new List<Applicant_Address__c>());
            }
            result.get(addr.Applicant__c).add(addr);
        }
        return result;
    }

    private static Map<Id, Application_Verification__c> queryVerifications(Set<Id> applicantIds) {
        Map<Id, Application_Verification__c> result = new Map<Id, Application_Verification__c>();
        if (applicantIds == null || applicantIds.isEmpty()) return result;

        for (Application_Verification__c v : [
            SELECT Id, Applicant__c, OGL__c
            FROM Application_Verification__c
            WHERE Applicant__c IN :applicantIds
        ]) {
            result.put(v.Applicant__c, v);
        }
        return result;
    }

    private static Map<Id, List<Bank_Details__c>> queryBankDetails(Set<Id> applicantIds) {
        Map<Id, List<Bank_Details__c>> result = new Map<Id, List<Bank_Details__c>>();
        if (applicantIds == null || applicantIds.isEmpty()) return result;

        for (Bank_Details__c bd : [
            SELECT Id,
                Application_Applicant__c,
                Account_Number__c,
                Bank_Name__c,
                IFSC__c,
                Account_Holder_Name__c,
                Account_Type__c,
                Is_Repayment_Account__c,
                Is_Disbursal_Account__c,
                OD_CC_Limit__c,
                ABB__c
            FROM Bank_Details__c
            WHERE Application_Applicant__c IN :applicantIds
        ]) {
            if (!result.containsKey(bd.Application_Applicant__c)) {
                result.put(bd.Application_Applicant__c, new List<Bank_Details__c>());
            }
            result.get(bd.Application_Applicant__c).add(bd);
        }
        return result;
    }

    private static List<Collateral__c> queryCollaterals(Id oppId) {
        List<Application_Collateral__c> junctions = [
            SELECT Id, Collateral__c
            FROM Application_Collateral__c
            WHERE HL_Loan_Application__c = :oppId
        ];

        if (junctions.isEmpty()) return new List<Collateral__c>();

        Set<Id> collateralIds = new Set<Id>();
        for (Application_Collateral__c ac : junctions) {
            if (ac.Collateral__c != null) {
                collateralIds.add(ac.Collateral__c);
            }
        }

        if (collateralIds.isEmpty()) return new List<Collateral__c>();

        return [
            SELECT Id,
                Project__r.Name,
                Tower_Building_Name__c,
                Floor_Number__c,
                Unit_Number__c,
                RERA_Registration_Number__c,
                Carpet_Area_of_Residential_Unit_sq_m__c,
                Area_of_Plot_Area__c,
                Number_of_floors_constructed__c,
                Age_of_Property__c,
                Occupancy_Since__c,
                Property_Identified__c,
                Property_Usage__c,
                Site_Visit_Conducted_by_Sales__c, 
                address_line_1__c, 
                address_line_2__c,
                address_line_3__c
            FROM Collateral__c
            WHERE Id IN :collateralIds
        ];
    }

    private static Product2 queryProduct(Id oppId) {
        List<Product2> results = [
            SELECT Id,
                PLR_Value__c,
                Product_Type__c,
                Min_ROI__c,
                MAX_ROI__c,
                LTV__c,
                Recommended_Loan_Amount__c,
                Total_ProposedExposure__c,
                Negotiated_Loan_Amount__c,
                Negotiated_ROI__c,
                Negotiated_Tenure__c
            FROM Product2
            WHERE Loan_Application__c = :oppId
            AND RecordType.Name = 'Product'
            LIMIT 1
        ];
        return results.isEmpty() ? null : results[0];
    }

    private static List<Technical_Evaluation__c> queryTechEvals(Id oppId) {
        return [
            SELECT Id,
                HL_Plot_No_Flat_No_Khasra_No__c,
                HL_Scheme_Colony_Building_Street_Name__c,
                District__c,
                HL_Village__c,
                HL_Tehsil__c,
                City__c,
                State__c,
                HL_Area_of_Property__c,
                Plot_Bounded_by_North__c,
                Plot_Bounded_by_South__c,
                Plot_Bounded_by_East__c,
                Plot_Bounded_by_West__c,
                HL_Date_of_Valuation__c,
                HL_Vendor_Agency__c,
                Market_Value_Of_Property__c,
                Property_Category_Description__c
            FROM Technical_Evaluation__c
            WHERE HL_Loan_Application__c = :oppId
        ];
    }

    private static List<Legal__c> queryLegal(Id oppId) {
        return [
            SELECT Id
            FROM Legal__c
            WHERE Loan_Application__c = :oppId
        ];
    }

    private static List<Document_Details__c> queryDocuments(Id oppId) {
        return [
            SELECT Id,
                Name,
                Content_Document_Id__c,
                document_master__r.document_category__c,
                Document_Type__c,
                Document_Category__c,
                Applicant__r.First_Name__c,
                Applicant__r.Last_Name__c,
                Applicant__r.Applicant_Type__c,
                applicant__c, applicant__r.Customer_Type__c,
                Document_URL__c,
                CreatedDate,
                CreatedById,
                CreatedBy.Email
            FROM Document_Details__c
            WHERE Loan_Application__c = :oppId and content_document_id__c != '' and document_master__r.document_category__c != '' and Name !='Sanction Letter'
        ];
    }

    /**
     * CHANGE 3: Single bulk query to fetch the latest ContentVersion
     * for each ContentDocumentId.  Ordered by CreatedDate DESC so the
     * first record per ContentDocumentId is the most recent version.
     * Only one SOQL query regardless of the number of documents.
     */
    private static Map<Id, ContentVersion> queryLatestContentVersions(Set<Id> contentDocIds) {
        Map<Id, ContentVersion> result = new Map<Id, ContentVersion>();
        if (contentDocIds == null || contentDocIds.isEmpty()) return result;

        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId, FileExtension, FileType, CreatedDate
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocIds
            ORDER BY CreatedDate DESC
        ]) {
            // Keep only the first (latest) ContentVersion per ContentDocumentId
            if (!result.containsKey(cv.ContentDocumentId)) {
                result.put(cv.ContentDocumentId, cv);
            }
        }
        return result;
    }

    private static List<Instrument_Mandate__c> queryInstruments(Id oppId) {
        return [
            SELECT Id
            FROM Instrument_Mandate__c
            WHERE Loan_Application__c = :oppId
        ];
    }


    // ═══════════════════════════════════════════════════════════
    //  NULL-SAFE HELPERS
    // ═══════════════════════════════════════════════════════════

    /** Safe string – returns null instead of empty */
    private static String s(Object val) {
        if (val == null) return null;
        String str = String.valueOf(val);
        return String.isBlank(str) ? null : str;
    }

    /** Date → String (YYYY-MM-DD) or null */
    private static String d(Date val) {
        if (val == null) return null;
        return String.valueOf(val);
    }

    /** Date field that may actually be a Date stored in a Datetime field */
    private static String d(Datetime val) {
        if (val == null) return null;
        return val.format('yyyy-MM-dd');
    }

    /** Datetime → ISO 8601 or null */
    private static String dt(Datetime val) {
        if (val == null) return null;
        return val.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }

    /** Datetime override for Date inputs that come as Datetime */
    private static String dt(Date val) {
        if (val == null) return null;
        return String.valueOf(val) + 'T00:00:00Z';
    }

    /** Convert Yes/No or true/false string to Boolean */
    private static Boolean toBool(Object val) {
        if (val == null) return null;
        String str = String.valueOf(val).trim().toLowerCase();
        return str == 'yes' || str == 'true';
    }

    /**
     * Safe string-to-number conversion.
     * Converts text fields (e.g. Total_Tenure__c, Hybrid_Tenure__c) to Decimal
     * so that JSON.serialize emits an unquoted numeric value.
     * Returns null if the input is null, blank, or non-numeric.
     */
    private static Decimal toNum(Object val) {
        if (val == null) return null;
        String str = String.valueOf(val).trim();
        if (String.isBlank(str)) return null;
        try {
            return Decimal.valueOf(str);
        } catch (Exception e) {
            return null;
        }
    }

    /** Join first / middle / last names with space, null-safe */
    private static String joinNames(String first, String middle, String last) {
        String result = '';
        if (String.isNotBlank(first))  result += first;
        if (String.isNotBlank(middle)) result += ' ' + middle;
        if (String.isNotBlank(last))   result += ' ' + last;
        return String.isBlank(result) ? null : result.trim();
    }

    /** Join years + months into "X Years Y Months" */
    private static String joinExp(Object years, Object months) {
        if (years == null && months == null) return null;
        String result = '';
        if (years != null)  result += String.valueOf(years) + ' Years';
        if (months != null) result += (String.isNotBlank(result) ? ' ' : '') +
                                    String.valueOf(months) + ' Months';
        return String.isBlank(result) ? null : result;
    }
}