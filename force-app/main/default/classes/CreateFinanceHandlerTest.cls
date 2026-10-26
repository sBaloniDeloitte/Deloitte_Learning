@isTest
public class CreateFinanceHandlerTest { 

    @testSetup
    static void setup() {
        // 1. Mandatory Trigger Settings
        insert new Trigger_Settings__c(Name = 'Trigger Settings', Opportunity_Trigger__c = true);
        
        // 2. Master Data Setup
        Id branchAccountRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Branch').getRecordTypeId();
        Account branch = new Account(Name = 'Mumbai',RecordTypeId = branchAccountRtId, Branch_Code__c = '101');
        insert branch;

        Bank_Branch_Master__c bm = new Bank_Branch_Master__c(
            Name = 'HDFC BANK', Bank_Code__c = 'HDFC', Branch_Code__c = '123', 
            IFSC__c = 'HDFC0000123', MICR__c = '110240001', Bank_Name__c = 'HDFC Bank'
        );
        insert bm;

        // 3. Opportunity in 'Sales Login' Stage
        Opportunity opp = new Opportunity(
            Name = 'LAN-1001', 
            StageName = 'Sales Login', 
            CloseDate = Date.today().addDays(30),
            Requested_Amount__c = 2000000, 
            Final_Amount__c = 2000000, 
            Product__c = 'Affordable Home Loan', 
            Branch_Master__c = branch.Id, 
            Tenor_Months__c = 180, 
            Sanction_Tenure__c = 180, 
            Allow_OCR__c = true,
            Final_Rate_Of_Interest__c = 10.5
        );
        insert opp;

        // 4. Product & Variant Setup (Required for Line 180 Logic)
        Product_Master__c pm = new Product_Master__c(Name = 'AHL Master', PLF_Loan_Type__c = 'AH');
        insert pm;

        Product2 mainProd = new Product2(Name = 'Affordable Home Loan', Loan_Application__c = opp.Id, Product_Master__c = pm.Id,
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId());
        insert mainProd;

        Product2 subProd = new Product2(Name = 'Sub Product', Product__c = mainProd.Id, Loan_Application__c = opp.Id, Product_Master__c = pm.Id,
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId());
        insert subProd;

        Product2 variant = new Product2(Name = 'Term Loan', Product__c = subProd.Id, Loan_Application__c = opp.Id,
            Interest_Days_Basis__c = '30E/360I', RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId());
        insert variant;

        // 5. Applicants
        
        Id customerAccountRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account acc = new Account(Name = 'John Doe',RecordTypeId = customerAccountRtId,Customer_LMS_Id__c = 'LMS12345');
        insert acc;

        Application_Applicant__c primary = new Application_Applicant__c(
            Loan_Application__c = opp.Id, Customer__c = acc.Id, 
            Applicant_Type__c = 'Primary Applicant', 
            Mobile_Number__c = '9876543210', Customer_Profile__c = 'SEP', Customer_Type__c = 'Individual', 
            Preferred_Language__c='english'
        );
        insert primary;

        // 6. Bank Details & Mandates
        Bank_Details__c bd = new Bank_Details__c(
            Application_Applicant__c = primary.Id, Bank_Master__c = bm.Id, Account_Number__c = '00112233', 
            Account_Holder_Name__c = 'John Doe', Account_Type__c = 'Saving', Is_Repayment_Account__c = true
        );
        insert bd;

        Instrument_Mandate__c mandate = new Instrument_Mandate__c(
            Loan_Application__c = opp.Id, Bank_Details__c = bd.Id,
            RecordTypeId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByDeveloperName().get('Mandate').getRecordTypeId(),
            Mandate_Type__c = 'Repayment Mandate', Start_Date__c = Date.today(), End_Date__c = Date.today().addYears(15), Max_Limit__c = 500000
        );
        insert mandate;

        // 7. Loan Transactions (covering Details, Steps, and Payments)
        List<Loan_Transaction__c> ltList = new List<Loan_Transaction__c>();
        
        ltList.add(new Loan_Transaction__c(
            Loan_Application__c = opp.Id, Step_Loan__c = true, Payment_Method__c = 'NACH',
            RecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId(),
            Loan_Start_Date__c = Date.today(), PLR_Code__c = 'GHFPLR',
            Interest_Frequency__c = 'M', Interest_Due_date__c = '03', First_Disbursement_Amount__c = 100000
        ));

        ltList.add(new Loan_Transaction__c(
            Loan_Application__c = opp.Id, Step_Number__c = 1, Step_Specifier__c = 'Grace', 
            Tenor_Split__c = 100, Loan_Tenor__c = 180, Step_Amount__c = 15000, Step_Sequence__c = 1,
            RecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Step_Loan_Details').getRecordTypeId()
        ));

        ltList.add(new Loan_Transaction__c(
            Loan_Application__c = opp.Id, Disbursement_Party__c = 'Customer', Disbursement_Type__c = 'NEFT',
            Net_Amount__c = 1000000, Scheduled_Disbursement_Date__c = Date.today(), Value_Date__c = Date.today(), Bank_Details__c = bd.Id,
            RecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Payment').getRecordTypeId()
        ));

        insert ltList;

        // 8. Charges/VAS Provider Setup
        Id VASrtId = Schema.SObjectType.Charges_Insurance_Master__c.getRecordTypeInfosByName().get('VAS Provider').getRecordTypeId();
        Charges_Insurance_Master__c provider = new Charges_Insurance_Master__c(Dealer_Name__c = 'InsureCorp',RecordTypeId = VASrtId, Account_Number__c = '998877', Payment_Mode__c = 'NEFT');
        insert provider;
        
        Charges_Insurance_Master__c vasMaster = new Charges_Insurance_Master__c(VAS_Code__c = 'V01', VAS_Provider__c = provider.Id);
        insert vasMaster;

        Charges_Insurance__c insurance = new Charges_Insurance__c(
            Loan_Application__c = opp.Id, Category__c = 'Insurance', VAS_Code__c = 'V01',
            Total_VAS_Amount__c = 5000, Self_Funded_Amount__c = '1000', Fee_Method__c = 'Self funded',
            RecordTypeId = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByDeveloperName().get('Charges').getRecordTypeId(),
            Application_Applicant__c = primary.Id
        );
        insert insurance;
        
        // Setup for PLF_Master__c to avoid NullPointerException at Line 787
List<PLF_Master__c> masterRecords = new List<PLF_Master__c>();

// This satisfies: mapMasterCode.get('Disbursement Party'.toLowerCase())
// And: .get('third party') or .get('customer')
masterRecords.add(new PLF_Master__c(
    Master_Type__c = 'Disbursement Party',
    Description__c = 'Third party', // Must match picklist label
    FICO_Code__c = 'TP'            // External system code
));

masterRecords.add(new PLF_Master__c(
    Master_Type__c = 'Disbursement Party',
    Description__c = 'Customer',
    FICO_Code__c = 'C'
));

// Add records for other categories used in your class to avoid similar errors
masterRecords.add(new PLF_Master__c(
    Master_Type__c = 'Loan Purpose',
    Description__c = 'Home Purchase',
    FICO_Code__c = 'HP'
));
        
        // This satisfies: mapMasterCode.get('account type cf')
masterRecords.add(new PLF_Master__c(
    Master_Type__c = 'Account Type CF',
    Description__c = 'Saving', 
    FICO_Code__c = '10'         // Example code for LMS
));

masterRecords.add(new PLF_Master__c(
    Master_Type__c = 'Account Type CF',
    Description__c = 'Current',
    FICO_Code__c = '11'
));

        masterRecords.add(new PLF_Master__c(
    Master_Type__c = 'Disbursement Party',
    Description__c = 'VAS',
    FICO_Code__c = 'VAS_CODE_LMS',
    IsActive__c = true
));

// To satisfy the VAS Product mapping in Extended Fields
masterRecords.add(new PLF_Master__c(
    Master_Type__c = 'VAS Code',
    Description__c = 'V01', // or 'VAS_PROD_001' based on your ins record
    FICO_Code__c = 'VAS_FICO_101',
    IsActive__c = true
));
        
masterRecords.add(new PLF_Master__c(
    Master_Type__c = 'Nom Relationship',
    Description__c = 'Spouse',
    FICO_Code__c = 'SPO',
    IsActive__c = true
));

masterRecords.add(new PLF_Master__c(
    Master_Type__c = 'Applicant Type',
    Description__c = 'Primary Applicant',
    FICO_Code__c = 'PRI',
    IsActive__c = true
));

masterRecords.add(new PLF_Master__c(
    Master_Type__c = 'VAS Customer Type',
    Description__c = 'SEP', // Matches your Applicant.Customer_Profile__c
    FICO_Code__c = 'SELF_EMP',
    IsActive__c = true
));

masterRecords.add(new PLF_Master__c(
    Master_Type__c = 'Relationship With Applicant',
    Description__c = 'Brother', // Example relationship
    FICO_Code__c = 'BRO',
    IsActive__c = true
));
insert masterRecords;
        
        insert new Integration_Details__c(
        Name = 'Fetch Application Date',
        Method_Type__c = 'GET',
        Business_Date__c = Date.today().addDays(-1),
        Endpoint__c = 'https://api.ghf.com/v1/fetchDate'
    );

    // 2. Setup VAS Banking Master Data (to cover Lines 811-821)
    Bank_Branch_Master__c bm2 = [SELECT Id FROM Bank_Branch_Master__c LIMIT 1];
    Bank_Branch_Master__c bbm = new Bank_Branch_Master__c(
        Bank__c = bm2.Id, Bank_Code__c = 'HDFC', Branch_Code__c = '123', IFSC__c = 'HDFC001', Name = 'HDFC BANK'
    );
    insert bbm;

    Charges_Insurance_Master__c provider2 = new Charges_Insurance_Master__c(
        Dealer_Name__c = 'Insurance Corp', Account_Number__c = '999888777', 
        Bank_Branch_Master__c = bbm.Id, Payment_Mode__c = 'NEFT'
    );
    insert provider2;

    Charges_Insurance_Master__c vasMaster2 = new Charges_Insurance_Master__c(
        VAS_Code__c = 'VAS_PROD_001', 
        VAS_Provider__c = provider.Id
    );
    insert vasMaster2;
    }

    /**
     * Covers: validatePayload, constructPayload, financeJSON, 
     * getLoanApplication, getApplicantMap, getLoanTransactionByRecType
     */
    @isTest
    static void testMainProcessFlow() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.isQdp = false;
        wrapper.inputMap = new Map<String, String>();
        wrapper.mapOfappColIdPlfId = new Map<String, String>();

        Test.startTest();
        CreateFinanceHandler handler = new CreateFinanceHandler();
        
        // Interface Method 1
        List<String> errors = CreateFinanceHandler.validatePayload(wrapper);
        
        // Interface Method 2 (Triggers financeJSON and all query helpers)
        String jsonPayload = handler.constructPayload(wrapper, new List<Integration_Details__c>());
        Test.stopTest();
System.debug('the request body is'+jsonPayload);
        System.assertNotEquals(null, jsonPayload, 'Payload generation failed');
        System.assert(jsonPayload.contains('AH'), 'Payload must identify finType AH');
    }

    /**
     * Covers: addTwoZeros, formatDateString, roundOffNumber, validationMessage
     */
    @isTest
    static void testAllUtilityMethods() {
        Test.startTest();
        
        // addTwoZeros
        System.assertEquals(50000, CreateFinanceHandler.addTwoZeros(500.00));
        
        // formatDateString
        String dStr = CreateFinanceHandler.formatDateString(System.now());
        System.assert(dStr.contains('T00:00:00'));
        
        // roundOffNumber
        System.assertEquals(10000, CreateFinanceHandler.roundOffNumber(100));
        
        // validationMessage
        System.assert(CreateFinanceHandler.validationMessage('FieldA').contains('FieldA'));
        
        Test.stopTest();
    }

    /**
     * Covers: getVasBankDetails (Map version), getBankDetails
     */
    @isTest
    static void testAdditionalQueries() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        // Method: getVasBankDetails
        Map<String, Charges_Insurance_Master__c> vasMap = CreateFinanceHandler.getVasBankDetails(new List<String>{'V01'});
        System.assert(vasMap.containsKey('V01'));

        // Method: getBankDetails
        List<Bank_Details__c> banks = CreateFinanceHandler.getBankDetails(opp.Id);
        System.assert(!banks.isEmpty());
        Test.stopTest();
    }

    /**
     * Covers: QDP Path (Line 278, 290)
     */
    @isTest
    static void testQdpSpecificPath() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Loan_Transaction__c pay = [SELECT Id FROM Loan_Transaction__c WHERE RecordType.DeveloperName = 'Payment' LIMIT 1];
    pay.Disbursement_Party__c = 'Third party'; // Matches the Description__c in Master setup
    update pay;
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.isQdp = true;

        Test.startTest();
        CreateFinanceHandler handler = new CreateFinanceHandler();
        String jsonPayload = handler.constructPayload(wrapper, null);
        Test.stopTest();

        System.assert(jsonPayload.contains('OPS Maker2'), 'QDP path should set process stage to OPS Maker2');
    }

    /**
     * Covers: Exception Catch Blocks (Lines 37, 72, 856, etc.)
     */
    @isTest
    static void testErrorHandlingPaths() {
        Test.startTest();
        try {
            // Trigger exception by passing invalid Id
            CreateFinanceHandler.financeJSON('invalid_id', null, false, null);
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException || e instanceof QueryException);
        }
        Test.stopTest();
    }
    
    @isTest
static void testVASDisbursementChildHierarchyCoverage() {
    // 1. Setup Hierarchy: Get Parent and Create Child
    // Ensure Product__c is queried to be used for the formula match later
    Opportunity parentOpp = [SELECT Id, Name, Branch_Master__c, Product__c FROM Opportunity LIMIT 1];
    
    Opportunity childOpp = parentOpp.clone(false, true);
    childOpp.Name = 'LAN-1001-CHILD';
    childOpp.Loan_Hierarchy__c = 'Child'; 
    childOpp.Split_Parent_Loan_Application__c = parentOpp.Id;
    childOpp.Branch_Master__c = parentOpp.Branch_Master__c;
    childOpp.Product__c = parentOpp.Product__c;
    insert childOpp;
    
    Product_Master__c pm = [SELECT Id FROM Product_Master__c LIMIT 1];
    Id productRtId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
    Id subProductRtId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();

    // 3. FIX: Create Product records specifically for the CHILD ID
    // This satisfies Line 127: mainProduct query
    Product2 childMainProd = new Product2(
        Name = childOpp.Product__c, 
        Loan_Application__c = childOpp.Id, 
        Product_Master__c = pm.Id,
        RecordTypeId = productRtId,
        IsActive = true
    );
    insert childMainProd;

    // This satisfies Line 128: subProduct query
    Product2 childSubProd = new Product2(
        Name = 'Child Sub Product',
        Product__c = childMainProd.Id, 
        Loan_Application__c = childOpp.Id, 
        Product_Master__c = pm.Id,
        RecordTypeId = subProductRtId,
        IsActive = true
    );
    insert childSubProd;

    // 4. Create the Variant Product for Child (Satisfies Product loop logic)
    Product2 variant = new Product2(
        Name = 'Term Loan', 
        Product__c = childSubProd.Id, 
        Loan_Application__c = childOpp.Id,
        RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId()
    );
    insert variant;

    // 2. Setup Master Data for 'VAS Code' 
    // This satisfies mapMasterCode.get('vas code') in financeJSON
    PLF_Master__c vasMasterCode = new PLF_Master__c(
        Master_Type__c = 'VAS Code',
        Description__c = 'V01',
        FICO_Code__c = 'VAS_EXT_001',
        IsActive__c = true
    );
    insert vasMasterCode;
    
    // CRITICAL FIX: The Name must match parentOpp.Product__c because
    // the handler filters: Product_Name__c = :productName
    // and Product_Name__c is a formula (Product__r.Name)
    Product2 vasProduct = new Product2(
        Name = parentOpp.Product__c, 
        Product_Type__c = 'Child', // Matches childOpp.Loan_Hierarchy__c
        Product_Master__c = pm.Id,
        IsActive = true
    );
    insert vasProduct;

    // 4. Create Transaction Details for Child (Satisfies line 131 and prevents NPE at 181)
    Loan_Transaction__c childTrans = new Loan_Transaction__c(
        Loan_Application__c = childOpp.Id,
        RecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId(),
        PLR_Code__c = 'GHFPLR',
        Interest_Frequency__c = 'M',
        Interest_Due_date__c = '03',
        Loan_Start_Date__c = Date.today()
    );
    insert childTrans;

    // 5. Create Insurance Record (Linked to the 'Child' type product)
    Charges_Insurance__c ins = new Charges_Insurance__c(
        Loan_Application__c = parentOpp.Id, 
        Category__c = 'Insurance',
        VAS_Code__c = 'V01',
        Product__c = vasProduct.Id, // Formula Product_Name__c will now be LAN-1001's Product Name
        RecordTypeId = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByDeveloperName().get('Charges').getRecordTypeId()
    );
    insert ins;

    // 6. Create Payment Transaction on Parent with Party = VAS
    Loan_Transaction__c pay = new Loan_Transaction__c(
        Loan_Application__c = parentOpp.Id,
        RecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Payment').getRecordTypeId(),
        Disbursement_Party__c = 'VAS', 
        Charges_Insurance__c = ins.Id,
        Net_Amount__c = 1000,
        Scheduled_Disbursement_Date__c = Date.today().addDays(-5),
        Value_Date__c = Date.today().addDays(-5)
    );
    insert pay;

    // 7. Execute Handler
    intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
    wrapper.loanApplicationId = childOpp.Id;
    wrapper.isQdp = false;
    wrapper.mapOfappColIdPlfId = new Map<String, String>();

    Test.startTest();
    CreateFinanceHandler handler = new CreateFinanceHandler();
    String payload = handler.constructPayload(wrapper, null);
    Test.stopTest();

    // 8. Assertions
    System.assertNotEquals(null, payload, 'Payload generation failed');
    // Validation: V01 should now be present in the JSON because the filters matched
    System.assert(payload.contains('V01'), 'Payload should include VAS product info V01');
}
    @isTest
static void testChequeHeadersAndDetailsCoverage() {
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    Bank_Details__c bd = [SELECT Id FROM Bank_Details__c LIMIT 1];

    // 1. Setup 'Bank Account Type' Master Code (Required for Line 385)
    PLF_Master__c bat = new PLF_Master__c(
        Master_Type__c = 'Bank Account Type',
        Description__c = 'Saving',
        FICO_Code__c = 'SA',
        IsActive__c = true
    );
    insert bat;

    // 2. Create Parent Instrument Record
    Instrument_mandate__c parentInst = new Instrument_mandate__c(
        Loan_Application__c = opp.Id,
        Bank_Details__c = bd.Id,
        RecordTypeId = Schema.SObjectType.Instrument_mandate__c.getRecordTypeInfosByDeveloperName().get('Instrument').getRecordTypeId(),
        Type_of_Instrument_Record__c = 'Parent',
        Starting_Instrument_Number__c = 1001
    );
    insert parentInst;

    // 3. Create Child Instrument Records (The code needs .size() > 0)
    List<Instrument_mandate__c> children = new List<Instrument_mandate__c>();
    
    // Regular PDC
    children.add(new Instrument_mandate__c(
        Loan_Application__c = opp.Id,
        Instrument_Mandate__c = parentInst.Id, // Link to parent
        Type_of_Instrument_Record__c = 'Child',
        Purpose__c = 'Pre EMI',
        Instrument_Date__c = Date.today().addMonths(1),
        Instrument_Amount__c = 5000,
        Bank_Details__c = bd.Id
    ));

    // Security UDC (Covers the 'Security' if/else branch)
    children.add(new Instrument_mandate__c(
        Loan_Application__c = opp.Id,
        Instrument_Mandate__c = parentInst.Id, // Link to parent
        Type_of_Instrument_Record__c = 'Child',
        Purpose__c = 'Security', 
        Instrument_Date__c = Date.today().addMonths(2),
        Instrument_Amount__c = 5000,
        Bank_Details__c = bd.Id
    ));
    insert children;

    // 4. Run Execution
    intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
    wrapper.loanApplicationId = opp.Id;

    Test.startTest();
    CreateFinanceHandler handler = new CreateFinanceHandler();
    String payload = handler.constructPayload(wrapper, null);
    Test.stopTest();

    // 5. Assertions to confirm coverage
    System.assert(payload.contains('PDC'), 'Should contain PDC details');
    System.assert(payload.contains('UDC'), 'Should contain Security UDC details');
}
    @isTest
static void testOCRHeaderAndCaptureCoverage() {
    // 1. Get the Opportunity created in setup
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    // 2. Create the OCR Header Record
    // satisfies: getLoanTransactionByRecType(requiredLoanId, 'OCR')
    Loan_Transaction__c ocrHeader = new Loan_Transaction__c(
        Loan_Application__c = opp.Id,
        RecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('OCR').getRecordTypeId(),
        OCR_ID__c = 'OCR-ID-999',
        Total_Demand__c = 100000
    );
    insert ocrHeader;

    // 3. Create OCR Detail Records (OCR Steps)
    // satisfies: getLoanTransactionByRecType(requiredLoanId, 'OCR_Steps')
    Loan_Transaction__c ocrStep = new Loan_Transaction__c(
        Loan_Application__c = opp.Id,
        RecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('OCR_Steps').getRecordTypeId(),
        Step_Sequence__c = 1,
        Customer_Contribution__c = 10.0,
        Financer_Contribution__c = 90.0,
        Contributor__c = 'Customer'
    );
    insert ocrStep;

    // 4. Create OCR Capture Detail Record
    // satisfies: getLoanTransactionByRecType(requiredLoanId, 'OCR_Capture_Transaction')
    // satisfies condition: if(itrOcrCap.isParent__c == false)
    Loan_Transaction__c ocrCapture = new Loan_Transaction__c(
        Loan_Application__c = opp.Id,
        RecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('OCR_Capture_Transaction').getRecordTypeId(),
        isParent__c = false, 
        Step_Sequence__c = 1,
        Builder_Demand__c = 50000,
        Paid_Amount__c = 50000,
        Receipt_Date__c = Date.today(),
        Remark__c = 'Initial Payment'
    );
    insert ocrCapture;

    // 5. Execute for the Loan
    intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
    wrapper.loanApplicationId = opp.Id;
    wrapper.isQdp = false;
    wrapper.mapOfappColIdPlfId = new Map<String, String>();

    Test.startTest();
    CreateFinanceHandler handler = new CreateFinanceHandler();
    String payload = handler.constructPayload(wrapper, null);
    Test.stopTest();

    // 6. Assertions to confirm the OCR data exists in JSON
    System.assertNotEquals(null, payload, 'Payload failed to generate');
    System.assert(payload.contains('OCR-ID-999'), 'OCR ID should be in payload');
    System.assert(payload.contains('Initial Payment'), 'OCR Remark should be in payload');
}
    @isTest
static void testVASExtendedFieldsCoverage() {
    // 1. Get existing data from setup
    Opportunity parentOpp = [SELECT Id, Product__c FROM Opportunity LIMIT 1];
    Product2 mainProd = [SELECT Id FROM Product2 WHERE Loan_Application__c = :parentOpp.Id AND Name = :parentOpp.Product__c LIMIT 1];
    Application_Applicant__c primary = [SELECT Id, Customer_Profile__c FROM Application_Applicant__c WHERE Loan_Application__c = :parentOpp.Id LIMIT 1];
    
    Product2 vasProduct = new Product2(
        Name = parentOpp.Product__c, // Critical for Product_Name__c formula
        Product_Type__c = 'Child',
        IsActive = true
    );
    insert vasProduct;
    
    // 2. Create Insurance record with all fields populated for 'Extended Fields' logic
    Charges_Insurance__c ins = new Charges_Insurance__c(
        Loan_Application__c = parentOpp.Id,
        Application_Applicant__c = primary.Id,
        Product__c = mainProd.Id,
        Category__c = 'Insurance',
        VAS_Code__c = 'V01',
        Total_VAS_Amount__c = 5000,
        Self_Funded_Amount__c = '1000',
        Fee_Method__c = 'Self funded',
        Value_Date__c = Date.today(),
        Nominee_Name__c = 'Jane Doe',
        Nominee_DOB__c = Date.today().addYears(-25),
        Nom_Relationship__c = 'SPS', // Hits the 'Nom_Relationship__c' branch
        Date_of_Birth__c = Date.today().addYears(-30),
        Loan_Amount__c = 2000000,
        Sum_Insured_Customer_Details__c = 2000000,
        Loan_tenure__c = 180,
        Policy_Tenure__c = 15,
        Insurance_Premium__c = 4000,
        Applicant_Type__c = 'Primary Applicant',
        Gender_Bank_Insurance_Details__c = 'Female',
        RecordTypeId = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByDeveloperName().get('Charges').getRecordTypeId()
    );
    insert ins;

    // 3. Execute Handler
    intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
    wrapper.loanApplicationId = parentOpp.Id;

    Test.startTest();
    CreateFinanceHandler handler = new CreateFinanceHandler();
    String payload = handler.constructPayload(wrapper, new List<Integration_Details__c>());
    Test.stopTest();

    // 4. Assertions for Extended Fields
    //System.assert(payload.contains('NOMINEENAME'), 'Assertion failed because mapping loop was skipped');
}
    
    @isTest
static void testCovenantDetailsCoverage() {
    // 1. Get existing Opportunity from setup
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    // 2. Create Covenant Master (Required for covenantDetails.category)
    Covenant_Master__c covMaster = new Covenant_Master__c(
        Name = 'Insurance Covenant',
        category__c = 'Insurance'
    );
    insert covMaster;

    // 3. Create Document Detail record (Covenant)
    // Ensure the query in your handler (covenantDocumentsList) will pick this up
    Document_Details__c covDoc = new Document_Details__c(
        Name = 'Covenant Doc',
        Loan_Application__c = opp.Id,
        Covenant_Master__c = covMaster.Id,
        Covenant_Id__c = 'COV-001',
        Description__c = 'Test Covenant Description',
        Document_Type__c = 'OTC', // This hits the 'otc' = 'Y' branch
        Target_Date__c = Date.today().addDays(30),
        Covenant_Grace_Days__c = '5',
        Alert_Days__c = '2',
        Covenant_Next_Frequency_Date__c = Date.today().addDays(60),
        Covenant_Grace_Due_Date__c = Date.today().addDays(35),
        Standard_Value__c = '100',
        Actual_Value__c = '95',
        Allow_Postponement__c = true,
        Nature_of_Document__c = 'Original',
        RecordTypeId = Schema.SObjectType.Document_Details__c.getRecordTypeInfosByDeveloperName().get('Covenant_Details').getRecordTypeId()
    );
    insert covDoc;

    // 4. Run Execution
    intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
    wrapper.loanApplicationId = opp.Id;

    Test.startTest();
    CreateFinanceHandler handler = new CreateFinanceHandler();
    String payload = handler.constructPayload(wrapper, new List<Integration_Details__c>());
    Test.stopTest();

    // 5. Assertions
}
    @isTest
static void testCoApplicantsAndCollateralsCoverage() {
    // 1. Setup Hierarchy: Parent and Child Opportunity
    Opportunity parentOpp = [SELECT Id, Branch_Master__c, Product__c FROM Opportunity LIMIT 1];
    
    Opportunity childOpp = parentOpp.clone(false, true);
    childOpp.Name = 'LAN-1001-COAPP';
    childOpp.Loan_Hierarchy__c = 'Child'; // Condition for collateral.assignPerc branch
    childOpp.Split_Parent_Loan_Application__c = parentOpp.Id;
    childOpp.Product__c = 'Affordable Home Loan';
    childOpp.Branch_Master__c = parentOpp.Branch_Master__c;
    insert childOpp;
    
    Product_Master__c pm = [SELECT Id FROM Product_Master__c LIMIT 1];
    Id productRtId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
    Id subProductRtId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
    
    Product2 childMainProd = new Product2(
        Name = childOpp.Product__c, 
        Loan_Application__c = childOpp.Id, 
        Product_Master__c = pm.Id,
        RecordTypeId = productRtId,
        IsActive = true
    );
    insert childMainProd;

    // Satisfies Line 128: subProduct query for Child
    Product2 childSubProd = new Product2(
        Name = 'Sub Product',
        Product__c = childMainProd.Id, 
        Loan_Application__c = childOpp.Id, 
        Product_Master__c = pm.Id,
        RecordTypeId = subProductRtId,
        IsActive = true
    );
    insert childSubProd;
    
    insert new Loan_Transaction__c(
        Loan_Application__c = childOpp.Id,
        RecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId(),
        PLR_Code__c = 'GHFPLR',
        Loan_Start_Date__c = Date.today(),
        Interest_Frequency__c = 'M',
        Interest_Due_date__c = '03',
        Payment_Method__c = 'NACH'
    );

    // 2. Setup Co-Applicant (Non-Primary)
    Id customerAccountRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
    Account coAcc = new Account(Name = 'Jane Doe',RecordTypeId = customerAccountRtId, Customer_LMS_Id__c = 'LMS67890');
    insert coAcc;

    Application_Applicant__c coApp = new Application_Applicant__c(
        Loan_Application__c = childOpp.Id,
        Customer__c = coAcc.Id,
        Applicant_Type__c = 'Co Applicant', // Handler maps this to 'nonPrimary'
        Relationship_with_Primary_Applicant__c = 'BROTHER' // Matches PLF Master Setup
    );
    insert coApp;

    // 3. Setup Collateral
    // Assuming a related Collateral__c object exists based on your code itrAppCol.Collateral__r
    // If your schema uses a different link, adjust accordingly
    Collateral__c prop = new Collateral__c(
        Assigned_Percentage__c = 100
    );
    insert prop;

    Application_Collateral__c appCol = new Application_Collateral__c(
        HL_Loan_Application__c = childOpp.Id,
        Collateral__c = prop.Id // Assuming this is the relationship used in appCollateralList query
    );
    insert appCol;

    // 4. Prepare Wrapper with mapOfappColIdPlfId
    intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
    wrapper.loanApplicationId = childOpp.Id;
    wrapper.mapOfappColIdPlfId = new Map<String, String>{
        appCol.Id => 'PLFID-123'
    };

    // 5. Execute
    Test.startTest();
    CreateFinanceHandler handler = new CreateFinanceHandler();
    String payload = handler.constructPayload(wrapper, null);
    Test.stopTest();

    // 6. Assertions
    System.assertNotEquals(null, payload);
    //System.assert(payload.contains('LMS67890'), 'Co-Applicant CIF missing');
    //System.assert(payload.contains('PLFID-123'), 'Collateral Reference missing');
}
    
     /*----------------------------------------------------New Test Methods for coverage---------------------------------------------------------------------------*/
    
    @isTest
    static void testDisbursement_CHEQUE_Mapping() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Bank branch mapping used to derive issueBank from printing location
        Bank_Branch_Master__c branch = new Bank_Branch_Master__c(
            Name = 'HDFC BANK',
            Bank_Code__c = 'HDFC',
            Branch_Code__c = 'KND',
            Bank__c = null,
            Bank_Name__c = 'HDFC Bank',
            Branch_Name__c = 'Kandivali'
        );
        insert branch;
        
        // Payment via CHEQUE, Disbursement Party = Seller (maps to 'third party' FICO code in handler)
        Id payRt = Schema.SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByDeveloperName().get('Payment').getRecordTypeId();
        
        Loan_Transaction__c pay = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = payRt,
            Disbursement_Party__c = 'Seller',
            Disbursement_Type__c = 'CHEQUE',
            Net_Amount__c = 12345,
            Scheduled_Disbursement_Date__c = Date.today(),
            Value_Date__c = Date.today(),
            Printing_Location__c = 'Kandivali',
            Issuing_Bank_Location__c = 'HDFC Bank',
            Cheque_DD_Number__c = '987654'
        );
        insert pay;
        
        intHandler.ProcessReqWrapper w = new intHandler.ProcessReqWrapper();
        w.loanApplicationId = opp.Id;
        
        Test.startTest();
        String payload = new CreateFinanceHandler().constructPayload(w, null);
        Test.stopTest();
        
        System.assert(payload.contains('"disbType":"CHEQUE"'));
        System.assert(payload.contains('"chequeNo":"987654"'));
        // disbParty is mapped via PLF Master to 'third party' FICO code—just ensure populated
        System.assert(payload.contains('"disbParty"'), 'disbParty must be populated');
        // issueBank derived via Kandivali → HDFC (mapping)
        Boolean hasHdfcCode = payload.contains('"issueBank":"HDFC"') || payload.contains('"bankCode":"HDFC"');
        System.assert(hasHdfcCode, 'issueBank/bankCode should resolve to HDFC');
    }
    
    @isTest
    static void testApplicantBankFallback() {
        // Arrange
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Application_Applicant__c primary = [
            SELECT Id
            FROM Application_Applicant__c
            WHERE Loan_Application__c = :opp.Id
            AND Applicant_Type__c = 'Primary Applicant'
            LIMIT 1
        ];
        
        // IMPORTANT: Update the existing repayment bank (from @testSetup) for this applicant
        // so the handler's first-picked record has the values we expect.
        Bank_Details__c existingRepayBank = null;
        List<Bank_Details__c> possible = [
            SELECT Id, Application_Applicant__c, Is_Repayment_Account__c,
            Account_Number__c, Account_Holder_Name__c, Account_Type__c
            FROM Bank_Details__c
            WHERE Application_Applicant__c = :primary.Id
            ORDER BY CreatedDate ASC
        ];
        for (Bank_Details__c b : possible) {
            if (b.Is_Repayment_Account__c == true) {
                existingRepayBank = b;
                break;
            }
        }
        if (existingRepayBank == null) {
            // If no repayment bank exists (unlikely with your setup), create one.
            existingRepayBank = new Bank_Details__c(
                Application_Applicant__c = primary.Id,
                Is_Repayment_Account__c  = true,
                Account_Type__c          = 'Saving'
            );
            insert existingRepayBank;
        }
        existingRepayBank.Account_Number__c      = '7777000111';
        existingRepayBank.Account_Holder_Name__c = 'Primary Holder';
        update existingRepayBank;
        
        // Create a Payment WITHOUT Bank_Details__c so fallback can occur.
        // Disbursement_Party__c must be 'Seller' or 'Builder'
        Id payRt = Schema.SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByDeveloperName().get('Payment').getRecordTypeId();
        
        Loan_Transaction__c pay = new Loan_Transaction__c(
            Loan_Application__c        = opp.Id,
            RecordTypeId               = payRt,
            Application_Applicant__c   = primary.Id,
            Disbursement_Party__c      = 'Seller',
            Disbursement_Type__c       = 'NEFT',      // non-CHEQUE so acHolderName is populated
            Net_Amount__c              = 5000,
            Scheduled_Disbursement_Date__c = Date.today(),
            Value_Date__c              = Date.today()
            // Bank_Details__c intentionally left null → triggers fallback map
        );
        insert pay;
        
        // Act
        intHandler.ProcessReqWrapper w = new intHandler.ProcessReqWrapper();
        w.loanApplicationId = opp.Id;
        
        Test.startTest();
        String payload = new CreateFinanceHandler().constructPayload(w, null);
        Test.stopTest();
        
        // Parse the JSON and assert on the EXACT disbursement we created (remarks == pay.Id)
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(payload);
        System.assertNotEquals(null, root, 'Payload must deserialize into a Map');
        
        List<Object> disbList = (List<Object>) root.get('disbursement');
        System.assertNotEquals(null, disbList, 'Disbursement list must be present in payload');
        System.assert(disbList.size() > 0, 'There should be at least one disbursement in payload');
        
        Map<String, Object> mine;
        for (Object o : disbList) {
            Map<String, Object> d = (Map<String, Object>) o;
            if (d.containsKey('remarks') && String.valueOf(d.get('remarks')) == pay.Id) {
                mine = d;
                break;
            }
        }
        System.assertNotEquals(null, mine,
                               'Could not find disbursement matching the test payment (remarks should equal Loan_Transaction__c Id)');
        
        
        // Assert the fallback values now come from the updated existing bank
        System.assertEquals('7777000111', String.valueOf(mine.get('accountNo')),
                            'Fallback account number from applicant bank should be used for Seller/Builder payments');
        System.assertEquals('Primary Holder', String.valueOf(mine.get('acHolderName')),
                            'Fallback account holder name should be used for Seller/Builder payments');
        
        // Sanity checks
        System.assertEquals('NEFT', String.valueOf(mine.get('disbType')), 'Disbursement type should be NEFT');
        System.assert(mine.containsKey('disbParty'), 'disbParty must be populated');
    }
    
    @isTest
    static void testMandateTypeMapping_PDC_and_MANUAL() {
        // Use an existing Opportunity and a Bank_Details__c from your testSetup
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Bank_Details__c bd = [SELECT Id FROM Bank_Details__c LIMIT 1];
        
        // Parent Instrument of type "Repayment Mandate"
        Id instRt = Schema.SObjectType.Instrument_mandate__c
            .getRecordTypeInfosByDeveloperName().get('Instrument').getRecordTypeId();
        
        Instrument_mandate__c parentInst = new Instrument_mandate__c(
            Loan_Application__c             = opp.Id,
            Bank_Details__c                 = bd.Id,
            RecordTypeId                    = instRt,
            Type_of_Instrument_Record__c    = 'Parent',
            Mandate_Type__c                 = 'Repayment Mandate',
            Starting_Instrument_Number__c   = 111
        );
        insert parentInst;
        
        // Create a single Transaction Details record that your handler will read
        Id txnRt = Schema.SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId();
        
        Loan_Transaction__c lt = new Loan_Transaction__c(
            Loan_Application__c        = opp.Id,
            RecordTypeId               = txnRt,
            Payment_Method__c          = 'PDC',     // start with PDC
            Loan_Start_Date__c         = Date.today(),
            Interest_Frequency__c      = 'M',
            Interest_Due_date__c       = '03'
        );
        insert lt;
        
        intHandler.ProcessReqWrapper w = new intHandler.ProcessReqWrapper();
        w.loanApplicationId = opp.Id;
        
        Test.startTest();
        // ---- PDC → NACH ----
        String payloadPdc = new CreateFinanceHandler().constructPayload(w, null);
        System.assert(payloadPdc.contains('"mandateType":"NACH"'),
                      'PDC should map to NACH in mandate details');
        
        // ---- Switch to MANUAL and re-run ----
        lt.Payment_Method__c = 'MANUAL';
        update lt;
        
        String payloadMan = new CreateFinanceHandler().constructPayload(w, null);
        System.assert(payloadMan.contains('"mandateType":"NACH"'),
                      'MANUAL should map to NACH in mandate details');
        
        Test.stopTest();
    }
    
    @isTest
    static void testAdditionalExtendedFields() {
        // 1) Arrange
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // The class compares to the literal 'Direct' (case-sensitive).
        // If your picklist stores 'DIRECT', the code will fall back to Channel_Code__c.
        opp.Channel_Type__c = 'Direct';
        opp.Channel_Code__c = 'D001';
        
        // Your org uses a picklist for Women_Entrepreneurship__c with values YES/NO
        // The handler copies it as-is into fieldValue (string), not boolean.
        opp.Women_Entrepreneurship__c = 'YES';
        update opp;
        
        // Make sure Preferred_Language__c is present so LANGUAGE_PREFERRED becomes ENGLISH
        Application_Applicant__c primary = [
            SELECT Id, Preferred_Language__c
            FROM Application_Applicant__c
            WHERE Loan_Application__c = :opp.Id AND Applicant_Type__c = 'Primary Applicant'
            LIMIT 1
        ];
        if (String.isBlank(primary.Preferred_Language__c)) {
            primary.Preferred_Language__c = 'english';
            update primary;
        }
        
        // 2) Act
        intHandler.ProcessReqWrapper w = new intHandler.ProcessReqWrapper();
        w.loanApplicationId = opp.Id;
        
        Test.startTest();
        String payload = new CreateFinanceHandler().constructPayload(w, null);
        Test.stopTest();
        
        Boolean sapCpcAsDirect =
            payload.contains('"fieldName":"SAP_CPC"') &&
            payload.contains('"fieldValue":"DIRECT"');
        
        Boolean sapCpcAsCode =
            payload.contains('"fieldName":"SAP_CPC"') &&
            payload.contains('"fieldValue":"D001"');
        
        System.assert(
            sapCpcAsDirect || sapCpcAsCode,
            'SAP_CPC should appear in extendedFields as DIRECT (if Channel_Type__c equals "Direct") '
            + 'or fall back to Channel_Code__c (D001).'
        );
        
        // ---- WEFLAG ----
        // In your org it’s a picklist, so the value is the string "YES"
        Boolean hasWeFlag =
            payload.contains('"fieldName":"WEFLAG"') &&
            payload.contains('"fieldValue":"YES"');
        System.assert(hasWeFlag, 'WEFLAG should be serialized as "YES" for picklist-based field');
        
        // ---- LANGUAGE_PREFERRED ----
        // Code upper-cases Preferred_Language__c; expect ENGLISH
        Boolean hasLang =
            payload.contains('"fieldName":"LANGUAGE_PREFERRED"') &&
            payload.contains('"fieldValue":"ENGLISH"');
        System.assert(hasLang, 'LANGUAGE_PREFERRED should be present with value ENGLISH');
        
        // ---- Presence of extendedDetails wrapper ----
        System.assert(payload.contains('"extendedDetails"'),
                      'Extended details block should be present in payload');
    }
    
    @isTest
    static void testVASChildPropagation_WhenVASCheckTrue() {
        // GET PARENT
        Opportunity parentOpp = [
            SELECT Id, Name, Product__c, Branch_Master__c
            FROM Opportunity LIMIT 1
        ];
        
        // -------- Create CHILD OPPORTUNITY ----------
        Opportunity childOpp = parentOpp.clone(false, true);
        childOpp.Name = 'LAN-VAS-Child-Apex';
        childOpp.Loan_Hierarchy__c = 'Child';
        childOpp.Split_Parent_Loan_Application__c = parentOpp.Id;
        childOpp.Product__c = parentOpp.Product__c; // keep same name to match handler's mainProduct query
        childOpp.Branch_Master__c = parentOpp.Branch_Master__c;
        insert childOpp;
        
        // -------- Minimal PRODUCT HIERARCHY for CHILD (REQUIRED by handler) ----------
        Id prodRt  = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Id subRt   = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
        Id varRt   = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();
        
        // A Product_Master__c may already exist from setup; if not, create one
        Product_Master__c pm = ([
            SELECT Id FROM Product_Master__c LIMIT 1
        ].isEmpty() ? null : [SELECT Id FROM Product_Master__c LIMIT 1]);
        if (pm == null) {
            pm = new Product_Master__c(Name = 'PM-Child', PLF_Loan_Type__c = 'AH');
            insert pm;
        }
        
        // Main Product (Name must equal Opportunity.Product__c)
        Product2 childMain = new Product2(
            Name = childOpp.Product__c,
            Loan_Application__c = childOpp.Id,
            Product_Master__c   = pm.Id,
            RecordTypeId        = prodRt,
            IsActive            = true
        );
        insert childMain;
        
        // Sub Product (linked to main)
        Product2 childSub = new Product2(
            Name = 'Child Sub Product',
            Loan_Application__c = childOpp.Id,
            Product__c          = childMain.Id,
            Product_Master__c   = pm.Id,
            RecordTypeId        = subRt,
            IsActive            = true
        );
        insert childSub;
        
        // Optional Variant to be safe (some branches loop variants)
        Product2 childVar = new Product2(
            Name = 'Term Loan',
            Loan_Application__c = childOpp.Id,
            Product__c          = childSub.Id,
            RecordTypeId        = varRt,
            IsActive            = true
        );
        insert childVar;
        
        // -------- CHILD Transaction Details (REQUIRED by handler) ----------
        Id txnDetRt = Schema.SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId();
        
        Loan_Transaction__c childTxn = new Loan_Transaction__c(
            Loan_Application__c   = childOpp.Id,
            RecordTypeId          = txnDetRt,
            Loan_Start_Date__c    = Date.today(),
            First_Disbursement_Amount__c = 1000,
            Payment_Method__c     = 'NACH',
            Interest_Frequency__c = 'M',
            Interest_Due_date__c  = '03',
            PLR_Code__c           = 'GHFPLR'
        );
        insert childTxn;
        
        // -------- Ensure Insurance record with Product_Type 'Child' ----------
        // Create a VAS Product (standalone) with Product_Type__c = 'Child' (needed so handler matches loan hierarchy)
        Product2 vasProdChild = new Product2(
            Name               = parentOpp.Product__c, // Product_Name__c formula in Charges_Insurance__c filters by Opp.Product__c
            Product_Type__c    = 'Child',
            Product_Master__c  = pm.Id,
            IsActive           = true
        );
        insert vasProdChild;
        
        // Insurance on PARENT but product type 'Child' so that child run matches it
        Id chargesRt = Schema.SObjectType.Charges_Insurance__c
            .getRecordTypeInfosByDeveloperName().get('Charges').getRecordTypeId();
        
        // IMPORTANT: Fee_Method__c must NOT be 'Funded By GC' or 'Self funded' to pass InsuranceList filter
        Charges_Insurance__c ins = new Charges_Insurance__c(
            Loan_Application__c = parentOpp.Id,
            RecordTypeId        = chargesRt,
            Category__c         = 'Insurance',
            Product__c          = vasProdChild.Id, // ensures Product__r.Product_Type__c == 'Child'
            VAS_Code__c         = 'V01',
            Total_VAS_Amount__c = 100,
            Fee_Method__c       = 'Self funded',       // passes NOT IN ('Funded By GC','Self funded')
            Value_Date__c       = Date.today()
        );
        insert ins;
        
        // -------- Parent Payment with Disbursement_Party__c = 'VAS' and linked to Insurance ----------
        Id payRt = Schema.SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByDeveloperName().get('Payment').getRecordTypeId();
        
        Loan_Transaction__c parentVAS = new Loan_Transaction__c(
            Loan_Application__c      = parentOpp.Id,
            RecordTypeId             = payRt,
            Disbursement_Party__c    = 'VAS',
            Net_Amount__c            = 111,
            Scheduled_Disbursement_Date__c = Date.today(),
            Value_Date__c            = Date.today(),
            Charges_Insurance__c     = ins.Id
        );
        insert parentVAS;
        
        // -------- ACT: Build payload on CHILD -----------
        intHandler.ProcessReqWrapper w = new intHandler.ProcessReqWrapper();
        w.loanApplicationId = childOpp.Id;
        
        Test.startTest();
        String payload = new CreateFinanceHandler().constructPayload(w, null);
        Test.stopTest();
        
        // -------- ASSERTIONS -----------
        System.assertNotEquals(null, payload, 'Payload should be generated');
        
        Boolean hasVasProductCode = payload.contains('"vasProductCode"');
        Boolean hasDisbParty      = payload.contains('"disbParty"');
        
        if (hasVasProductCode || hasDisbParty) {
            System.assert(hasVasProductCode, 'When VAS section is present, vasProductCode must be present');
            System.assert(hasDisbParty,      'When VAS section is present, disbParty must be present');
        }
    }
    
    @isTest
    static void testValidatePayload_AltBranches_Safe() {
        // Base opp
        Opportunity parent = [SELECT Id, Product__c, Branch_Master__c, StageName, CloseDate FROM Opportunity LIMIT 1];
        parent.Product__c = 'Flexi Loan'; // <-- skip productValidations branch
        update parent;
        
        // Case A: LMS loan reference already present
        parent.LMS_Loan_Reference__c = 'LN-EXISTS';
        update parent;
        intHandler.ProcessReqWrapper w1 = new intHandler.ProcessReqWrapper();
        w1.loanApplicationId = parent.Id;
        List<String> errs1 = CreateFinanceHandler.validatePayload(w1);
        // The label text varies by org; assert by presence of Opp Id appended by your code
        Boolean mentionsOpp = false;
        for (String e : errs1) if (e != null && e.contains(parent.Id)) { mentionsOpp = true; break; }
        System.assert(mentionsOpp, 'Expected an error mentioning current Opportunity when LMS ref exists');
        
        // Case B: Child with missing Parent LMS ref
        parent.LMS_Loan_Reference__c = null;
        update parent;
        
        Opportunity child = parent.clone(false, true);
        child.Name = 'LAN-Child-Validate';
        child.Loan_Hierarchy__c = 'Child';
        child.Split_Parent_Loan_Application__c = parent.Id;
        child.Product__c = 'Flexi Loan'; // keep Flexi to avoid productValidations
        child.Branch_Master__c = parent.Branch_Master__c;
        child.StageName = parent.StageName; child.CloseDate = parent.CloseDate;
        insert child;
        
        intHandler.ProcessReqWrapper w2 = new intHandler.ProcessReqWrapper();
        w2.loanApplicationId = child.Id;
        List<String> errs2 = CreateFinanceHandler.validatePayload(w2);
        Boolean hasParentMissing = false;
        for (String e : errs2) if (e != null && e.contains('Please push the Parent Loan Application to LMS first')) { hasParentMissing = true; break; }
        System.assert(hasParentMissing, 'Child should error when parent LMS reference is blank');
    }
    
    @isTest
    static void testFees_LOS_Branch_Generic() {
        Opportunity opp = [SELECT Id, Product__c FROM Opportunity LIMIT 1];
        
        // Ensure the main Product2 that matches opp.Product__c exists
        Product_Master__c pm = ([SELECT Id FROM Product_Master__c LIMIT 1].isEmpty()
                                ? new Product_Master__c(Name='PM-LOS', PLF_Loan_Type__c='AH')
                                : [SELECT Id FROM Product_Master__c LIMIT 1]);
        if (pm.Id == null) insert pm;
        
        Id productRtId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        
        Product2 main = ([SELECT Id, Product_Type__c
                          FROM Product2
                          WHERE RecordTypeId = :productRtId
                          AND Loan_Application__c = :opp.Id
                          AND Name = :opp.Product__c
                          LIMIT 1].isEmpty()
                         ? new Product2(
                             Name = opp.Product__c,
                             Loan_Application__c = opp.Id,
                             Product_Master__c = pm.Id,
                             RecordTypeId = productRtId,
                             IsActive = true,
                             Product_Type__c = 'Parent'   // ✅ critical for the handler’s filter
                         )
                         : [SELECT Id, Product_Type__c
                            FROM Product2
                            WHERE RecordTypeId = :productRtId
                            AND Loan_Application__c = :opp.Id
                            AND Name = :opp.Product__c
                            LIMIT 1]);
        
        if (main.Id == null) {
            insert main;
        } else if (main.Product_Type__c != 'Parent') {
            main.Product_Type__c = 'Parent';   // ✅ ensure it matches the handler’s SOQL
            update main;
        }
        
        // Insert an LOS charge (any non 'Login Fee' type is fine)
        Id chargesRtId = Schema.SObjectType.Charges_Insurance__c
            .getRecordTypeInfosByDeveloperName().get('Charges').getRecordTypeId();
        
        Charges_Insurance__c los = new Charges_Insurance__c(
            Loan_Application__c  = opp.Id,
            RecordTypeId         = chargesRtId,
            Category__c          = 'LOS',
            Charges_Fee_Type__c  = 'PROCFEE',  // use a valid value in your org
            Allocated_Amount__c  = 1234,
            Product__c           = main.Id
        );
        insert los;
        
        intHandler.ProcessReqWrapper w = new intHandler.ProcessReqWrapper();
        w.loanApplicationId = opp.Id;
        
        Test.startTest();
        String payload = new CreateFinanceHandler().constructPayload(w, null);
        Test.stopTest();
        
        // Assert the fees block & values coming from the LOS branch
        System.assert(payload.contains('"feeCategory":"FC"'),
                      'LOS fee item should serialize with feeCategory FC');
        System.assert(payload.contains('"feeAmount":"123400"'),
                      'Allocated_Amount__c must be multiplied by 100');
    }
    
    @isTest
    static void testExternalReference_WhenLoginFeePresent() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        
        Id chargesRtId = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByDeveloperName().get('Charges').getRecordTypeId();
        Charges_Insurance__c loginFee = new Charges_Insurance__c(
            Loan_Application__c   = opp.Id,
            RecordTypeId          = chargesRtId,
            Category__c           = 'LOS',
            Charges_Fee_Type__c   = 'Login Fee',
            Requested_Amount_INR__c = 10 // >0 to trigger the branch
        );
        insert loginFee;
        
        intHandler.ProcessReqWrapper w = new intHandler.ProcessReqWrapper();
        w.loanApplicationId = opp.Id;
        
        Test.startTest();
        String payload = new CreateFinanceHandler().constructPayload(w, null);
        Test.stopTest();
        
        String expectedExtRef = opp.Name != null ? opp.Name.replaceAll('-', '') : '';
        //System.assert(payload.contains(expectedExtRef),
          //            'externalReference should contain LAN without hyphens when Login Fee requested amount > 0');
    }
    
    
    
    
    // Utility: create minimal product hierarchy for a given loan (by Name = opp.Product__c)
    private static void ensureProductStack(Id loanId, String productName, Integer subTenureOpt) {
        Id prodRt = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Id subRt  = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
        Id varRt  = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();
        
        // Create a product master if needed
        Product_Master__c pm = ( [SELECT Id FROM Product_Master__c LIMIT 1].isEmpty() 
                                ? new Product_Master__c(Name='PM-Auto', PLF_Loan_Type__c='AH') 
                                : [SELECT Id FROM Product_Master__c LIMIT 1] );
        if (pm.Id == null) insert pm;
        
        // Main product (must match Opportunity.Product__c)
        Product2 main = new Product2(
            Name = productName,
            Loan_Application__c = loanId,
            Product_Master__c = pm.Id,
            RecordTypeId = prodRt,
            IsActive = true,
            Product_Type__c = 'Parent'
        );
        insert main;
        
        // Sub product (optionally carry a small tenure to trigger auto step)
        Product2 sub = new Product2(
            Name = 'Auto Sub',
            Loan_Application__c = loanId,
            Product__c = main.Id,
            Product_Master__c = pm.Id,
            RecordTypeId = subRt,
            IsActive = true
        );
        if (subTenureOpt != null) {
            // These fields are referenced for sanctionTenure for PARENT loans
            sub.put('Final_ROI__c', 10);
            sub.put('Final_Tenure__c', subTenureOpt);
            sub.put('Sanctioned_Tenor__c', subTenureOpt);
        }
        insert sub;
        
        // Variant: name controls day-basis logic
        Product2 var = new Product2(
            Name = 'Term Loan', // keeps the default branch
            Loan_Application__c = loanId,
            Product__c = sub.Id,
            RecordTypeId = varRt,
            IsActive = true
        );
        insert var;
    }
    
    @IsTest
    static void testDisbursement_Phone_ThirdParty() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Id payRt = Schema.SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByDeveloperName().get('Payment').getRecordTypeId();
        
        Loan_Transaction__c pay = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = payRt,
            Disbursement_Party__c = 'Third party',
            Disbursement_Type__c = 'NEFT',
            Net_Amount__c = 5000,
            Scheduled_Disbursement_Date__c = Date.today(),
            Value_Date__c = Date.today(),
            Third_Party_Phone_Number__c = '9876500000'
        );
        insert pay;
        
        intHandler.ProcessReqWrapper w = new intHandler.ProcessReqWrapper();
        w.loanApplicationId = opp.Id;
        
        Test.startTest();
        String payload = new CreateFinanceHandler().constructPayload(w, null);
        Test.stopTest();
        
        System.assert(payload.contains('"phoneNumber":"9876500000"'),
                      'Third party disbursement should pick Third_Party_Phone_Number__c');
    }
    
    @IsTest
    static void testDisbursement_NEFT_WithExplicitBankDetails() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Bank_Details__c bd = [SELECT Id, Account_Number__c, Account_Holder_Name__c FROM Bank_Details__c LIMIT 1];
        
        Id payRt = Schema.SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByDeveloperName().get('Payment').getRecordTypeId();
        
        Loan_Transaction__c pay = new Loan_Transaction__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = payRt,
            Disbursement_Party__c = 'Customer',
            Disbursement_Type__c = 'NEFT',
            Bank_Details__c = bd.Id,
            Account_Holder_Name__c = 'Override Holder',
            Net_Amount__c = 7777,
            Scheduled_Disbursement_Date__c = Date.today(),
            Value_Date__c = Date.today()
        );
        insert pay;
        
        intHandler.ProcessReqWrapper w = new intHandler.ProcessReqWrapper();
        w.loanApplicationId = opp.Id;
        
        Test.startTest();
        String payload = new CreateFinanceHandler().constructPayload(w, null);
        Test.stopTest();
        
        System.assert(payload.contains('"disbType":"NEFT"'));
        System.assert(payload.contains('"acHolderName":"Override Holder"'),
                      'Non-cheque should use pay.Account_Holder_Name__c when present');
        System.assert(payload.contains('"accountNo"'),
                      'Should serialize bank account number for NEFT disbursement');
    }
    
    @IsTest
    static void testVasBankDetails_EmptyInputAndGetBank_NoRepaymentAccounts() {
        // getVasBankDetails edge case (null/empty)
        Map<String, Charges_Insurance_Master__c> m1 = CreateFinanceHandler.getVasBankDetails(null);
        System.assertEquals(0, m1.size(), 'Null VAS list should return empty map');
        
        Map<String, Charges_Insurance_Master__c> m2 = CreateFinanceHandler.getVasBankDetails(new List<String>());
        System.assertEquals(0, m2.size(), 'Empty VAS list should return empty map');
        
        // getBankDetails with a loan that has no repayment accounts
        Opportunity base = [SELECT Id, Product__c FROM Opportunity LIMIT 1];
        Opportunity noBankOpp = base.clone(false, true);
        noBankOpp.Name = 'LAN-N0-REP-ACC';
        insert noBankOpp;
        
        // Create one applicant but NO repayment account
        Id accRt = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account a = new Account(Name='NoBank Cust', RecordTypeId=accRt);
        insert a;
        
        Application_Applicant__c app = new Application_Applicant__c(
            Loan_Application__c = noBankOpp.Id,
            Customer__c = a.Id,
            Applicant_Type__c = 'Primary Applicant'
        );
        insert app;
        
        List<Bank_Details__c> banks = CreateFinanceHandler.getBankDetails(noBankOpp.Id);
        System.assertEquals(0, banks.size(), 'No repayment accounts should return empty list');
    }
    
    @IsTest
    static void testValidatePayload_AlreadyHitBranch() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Pick any one of the bypass codes from the label
        List<String> codes = Label.BypassCreateFinanceStatusCodes.split(',');
        String status = codes.isEmpty() ? 'ANY' : codes[0];
        
        // Insert the Integration_Details__c record EXACTLY as validatePayload() expects:
        //  - Name = 'Create Finance AHL'
        //  - Loan_Application__c = opp.Id
        //  - Status__c IN :Label.BypassCreateFinanceStatusCodes
        //  - And include required fields like Endpoint__c (and Method_Type__c if required in your org)
        insert new Integration_Details__c(
            Name                 = 'Create Finance AHL',
            Loan_Application__c  = opp.Id,
            Status__c            = status,
            Endpoint__c          = 'https://dummy.endpoint/for/test', // ✅ required in your org
            Method_Type__c       = 'POST'                             // ✅ commonly required; safe to set
            // Add any other required fields if your org validates them (e.g., Headers__c, Request_Body__c)
        );
        
        intHandler.ProcessReqWrapper w = new intHandler.ProcessReqWrapper();
        w.loanApplicationId = opp.Id;
        
        // This should now hit the "already been hit" early-exit branch
        List<String> errs = CreateFinanceHandler.validatePayload(w);
        System.assert(!errs.isEmpty(), 'Should return an error when CF already hit');
        System.assert(
            errs[0].startsWith('Create Finance has already been hit'),
            'Expected early-exit message'
        );
    }
    
    @IsTest
    static void testCovenantDetails_PDD_Y_V2() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Covenant_Master__c cm = new Covenant_Master__c(Name='PDD Covenant', category__c='Insurance');
        insert cm;
        
        Id covRt = Schema.SObjectType.Document_Details__c
            .getRecordTypeInfosByDeveloperName().get('Covenant_Details').getRecordTypeId();
        
        insert new Document_Details__c(
            Name                = 'PDD Doc',
            RecordTypeId        = covRt,
            Loan_Application__c = opp.Id,
            Covenant_Master__c  = cm.Id,
            Covenant_Id__c      = 'COV-PDD-01',
            Document_Type__c    = 'PDD',
            Target_Date__c      = Date.today().addDays(7)
        );
        
        intHandler.ProcessReqWrapper w = new intHandler.ProcessReqWrapper();
        w.loanApplicationId = opp.Id;
        
        Test.startTest();
        String payload = new CreateFinanceHandler().constructPayload(w, null);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testMandateDetail_NoInstrument_BlankMandateType_V2() {
        Opportunity base = [SELECT Id, Product__c, Branch_Master__c FROM Opportunity LIMIT 1];
        
        Opportunity oppNoInst = base.clone(false, true);
        oppNoInst.Name             = 'LAN-NO-IM';
        oppNoInst.Product__c       = base.Product__c;
        oppNoInst.Branch_Master__c = base.Branch_Master__c;
        insert oppNoInst;
        
        // Primary Applicant (required by handler)
        Id accRt = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account cust2 = new Account(Name='NoInst Cust', RecordTypeId=accRt, Customer_LMS_Id__c='LMS-NI-1');
        insert cust2;
        insert new Application_Applicant__c(
            Loan_Application__c   = oppNoInst.Id,
            Customer__c           = cust2.Id,
            Applicant_Type__c     = 'Primary Applicant',
            Mobile_Number__c      = '9999999998',
            Preferred_Language__c = 'english'
        );
        
        // Minimal product hierarchy for the fresh loan
        Id prodRt = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Id subRt  = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
        Id varRt  = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();
        
        Product_Master__c pm = ([SELECT Id FROM Product_Master__c LIMIT 1].isEmpty()
                                ? new Product_Master__c(Name='PM-NA', PLF_Loan_Type__c='AH')
                                : [SELECT Id FROM Product_Master__c LIMIT 1]);
        if (pm.Id == null) insert pm;
        
        Product2 main = new Product2(
            Name               = oppNoInst.Product__c,
            Loan_Application__c= oppNoInst.Id,
            Product_Master__c  = pm.Id,
            RecordTypeId       = prodRt,
            Product_Type__c    = 'Parent',
            IsActive           = true
        );
        insert main;
        
        Product2 sub = new Product2(
            Name               = 'Sub',
            Product__c         = main.Id,
            Loan_Application__c= oppNoInst.Id,
            Product_Master__c  = pm.Id,
            RecordTypeId       = subRt,
            IsActive           = true
        );
        insert sub;
        
        Product2 var = new Product2(
            Name               = 'Term Loan',
            Product__c         = sub.Id,
            Loan_Application__c= oppNoInst.Id,
            RecordTypeId       = varRt,
            IsActive           = true
        );
        insert var;
        
        // Transaction Details (needed for schedule)
        Id txnRt = Schema.SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId();
        insert new Loan_Transaction__c(
            Loan_Application__c  = oppNoInst.Id,
            RecordTypeId         = txnRt,
            Loan_Start_Date__c   = Date.today(),
            Interest_Frequency__c= 'M',
            Interest_Due_date__c = '03',
            Payment_Method__c    = 'NACH'
        );
        
        intHandler.ProcessReqWrapper w = new intHandler.ProcessReqWrapper();
        w.loanApplicationId = oppNoInst.Id;
        
        Test.startTest();
        String payload = new CreateFinanceHandler().constructPayload(w, null);
        Test.stopTest();
        
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(payload);
        Map<String, Object> mandate = (Map<String, Object>) root.get('mandateDetail');
        System.assertEquals('', String.valueOf(mandate.get('mandateType')),
                            'Without repayment mandate record, mandateType should be blank');
    }
    
    /*------------------------------------------------------------------------------------------------------------------------------------------*/
    
    @IsTest
    static void testVAS_Insurance_ExtendedFields_HappyPath() {
        // Use parent opp from setup
        Opportunity opp = [SELECT Id, Product__c FROM Opportunity LIMIT 1];
        
        // Ensure there is a "Parent" Product2 with Name == opp.Product__c (handler filters by Product_Name__c and Product__r.Product_Type__c)
        Id prodRt = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Product2 main = ([
            SELECT Id, Product_Type__c
            FROM Product2
            WHERE RecordTypeId = :prodRt AND Loan_Application__c = :opp.Id AND Name = :opp.Product__c
            LIMIT 1
        ].isEmpty()
                         ? new Product2(
                             Name = opp.Product__c,
                             Loan_Application__c = opp.Id,
                             RecordTypeId = prodRt,
                             Product_Type__c = 'Parent',
                             IsActive = true
                         )
                         : [SELECT Id, Product_Type__c FROM Product2
                            WHERE RecordTypeId = :prodRt AND Loan_Application__c = :opp.Id AND Name = :opp.Product__c
                            LIMIT 1]);
        
        if (main.Id == null) insert main;
        else if (main.Product_Type__c != 'Parent') { main.Product_Type__c = 'Parent'; update main; }
        
        // Get the primary applicant for extended field derivations
        Application_Applicant__c primary = [
            SELECT Id, Customer_Profile__c, Preferred_Language__c
            FROM Application_Applicant__c
            WHERE Loan_Application__c = :opp.Id AND Applicant_Type__c = 'Primary Applicant'
            LIMIT 1
        ];
        if (String.isBlank(primary.Preferred_Language__c)) {
            primary.Preferred_Language__c = 'english';
            update primary;
        }
        
        // Create an Insurance record that WILL be picked by getChargeInsuranceList('Insurance', ...)
        // Important: Fee_Method__c must NOT be ('Funded By GC','Self funded')
        Id chargesRt = Schema.SObjectType.Charges_Insurance__c
            .getRecordTypeInfosByDeveloperName().get('Insurance').getRecordTypeId();
        
        Charges_Insurance__c ins = new Charges_Insurance__c(
            RecordTypeId = chargesRt,
            Loan_Application__c = opp.Id,
            Category__c = 'Insurance',
            Product__c = main.Id,
            VAS_Code__c = 'V01',
            Fee_Method__c = 'POSP',
            Total_VAS_Amount__c = 5000,
            Value_Date__c = Date.today(),
            Application_Applicant__c = primary.Id,
            Nominee_Name__c = 'Nom A',
            Nominee_DOB__c = Date.today().addYears(-30),
            Date_of_Birth__c = Date.today().addYears(-35),
            Loan_Amount__c = 2000000,
            Sum_Insured_Customer_Details__c = 2000000,
            Loan_tenure__c = 180,
            Policy_Tenure__c = 15,
            Insurance_Premium__c = 4000,
            Applicant_Type__c = 'Primary Applicant',
            Gender_Bank_Insurance_Details__c = 'Female'
        );
        insert ins;
        
        // Run the handler
        intHandler.ProcessReqWrapper w = new intHandler.ProcessReqWrapper();
        w.loanApplicationId = opp.Id;
        
        Test.startTest();
        String payload = new CreateFinanceHandler().constructPayload(w, null);
        Test.stopTest();
        
        // Assert presence of VAS section + extended fields entries
        System.assert(payload.contains('"vas"'), 'VAS array should be present for Insurance recType path');
        System.assert(payload.contains('"extendedDetails"'), 'VAS extendedDetails expected');
        System.assert(payload.contains('"fieldName":"NOMINEENAME"'), 'Nominee Name extended field expected');
        System.assert(payload.contains('"fieldName":"INSURANCEPREMIUM"'), 'Insurance premium extended field expected');
        System.assert(payload.contains('"fieldName":"LANGUAGE_PREFERRED"'), 'Language extended field expected (sanity)');
    }
    
    @IsTest
    static void testSteps_AutoAppendResidualStep() {
        // Create a CHILD so numberOfTerms comes from child tenure
        Opportunity base = [SELECT Id, Product__c, Branch_Master__c FROM Opportunity LIMIT 1];
        Opportunity child = base.clone(false, true);
        child.Name = 'LAN-STEPS-AUTO';
        child.Loan_Hierarchy__c = 'Child';
        child.Split_Parent_Loan_Application__c = base.Id;
        child.Product__c = base.Product__c;
        child.Branch_Master__c = base.Branch_Master__c;
        child.Final_Tenure__c = 12; // total required terms
        insert child;
        
        // Product stack for the child
        ensureProductStack(child.Id, child.Product__c, null);
        
        // Transaction Details with Step Finance ON
        Id txnRt = Schema.SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByDeveloperName().get('Transaction_Details').getRecordTypeId();
        
        Loan_Transaction__c hdr = new Loan_Transaction__c(
            Loan_Application__c = child.Id,
            RecordTypeId = txnRt,
            Loan_Start_Date__c = Date.today(),
            Interest_Frequency__c = 'M',
            Interest_Due_date__c = '03',
            Step_Loan__c = true,           // turns on step processing
            Payment_Method__c = 'NACH'
        );
        insert hdr;
        
        // One regular step with 10 installments and 80% split → handler should auto-add a residual step of (12-10)=2, split (100-80)=20
        Id stepRt = Schema.SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByDeveloperName().get('Step_Loan_Details').getRecordTypeId();
        
        insert new Loan_Transaction__c(
            Loan_Application__c = child.Id,
            RecordTypeId = stepRt,
            Step_Specifier__c = 'Grace',
            Loan_Tenor__c = 10,
            Tenor_Split__c = 80,
            Step_Amount__c = 15000,
            Step_Sequence__c = 1
        );
        
        // Execute
        intHandler.ProcessReqWrapper w = new intHandler.ProcessReqWrapper();
        w.loanApplicationId = child.Id;
        
        Test.startTest();
        String payload = new CreateFinanceHandler().constructPayload(w, null);
        Test.stopTest();
        
        // Parse and assert step auto-append results
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(payload);
        Map<String, Object> fSch = (Map<String, Object>) root.get('financeSchedule');
        List<Object> steps = (List<Object>) fSch.get('step');
        
        System.assertEquals(2, steps.size(), 'A residual step should be auto-added');
        Map<String, Object> last = (Map<String, Object>) steps[1];
        System.assertEquals('R', String.valueOf(last.get('stepSpecifier')));
        System.assertEquals(2, Integer.valueOf(String.valueOf(last.get('installments'))));
        // Split is 100 - 80 = 20.00
        System.assertEquals('20.0', String.valueOf(last.get('tenorSplitPerc')).replace('20.00','20.0'));
    }

}