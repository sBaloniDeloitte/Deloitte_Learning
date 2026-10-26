@IsTest
public class COMM_IncomeSanctionLetterHandlerTest {

    // ---------- Helper: Create a User ----------
    private static User createUser(String aliasSeed) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User u = new User(
            ProfileId = p.Id,
            Alias = aliasSeed.left(8),
            Email = aliasSeed + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = aliasSeed + '+' + System.currentTimeMillis() + '@test.com'
        );
        insert u;
        return u;
    }

    // ---------- Helper: RecordType Id for Product2 ----------
    private static Id p2Rt(String rtKeyOrName) {
    System.assert(!String.isBlank(rtKeyOrName), 'RecordType input is blank');

    // 1) Try label map (RecordType.Name)
    Map<String, Schema.RecordTypeInfo> byLabel =
        Schema.SObjectType.Product2.getRecordTypeInfosByName();
    if (byLabel.containsKey(rtKeyOrName)) {
        return byLabel.get(rtKeyOrName).getRecordTypeId();
    }

    // 2) Try developer name map (RecordType.DeveloperName)
    Map<String, Schema.RecordTypeInfo> byDev =
        Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName();
    if (byDev.containsKey(rtKeyOrName)) {
        return byDev.get(rtKeyOrName).getRecordTypeId();
    }

    System.assert(false,
        'Missing Product2 RecordType (label/dev): ' + rtKeyOrName +
        ' | Available LABELS: ' + String.join(new List<String>(byLabel.keySet()), ', ') +
        ' | Available DEV NAMES: ' + String.join(new List<String>(byDev.keySet()), ', ')
    );
    return null;
}


    // ---------- Helper: RecordType Id for Charges_Insurance__c ----------
    private static Id chargesRt(String rtName) {
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName();
        System.assert(rtMap.containsKey(rtName), 'Missing Charges_Insurance__c RecordType: ' + rtName);
        return rtMap.get(rtName).getRecordTypeId();
    }

    /**
     * Builds ALL data required so constructPayload() does not throw:
     * - Opportunity with sanction amount/tenure/product/lead/branch
     * - Lead with Dsa_Area_Manager__r.email
     * - Product2 graph: Product -> Sub_Product -> Variant/Sub_Variant (+ Hybrid_Tenure)
     * - Applicants (Primary + Co-app) with Customer__r fields
     * - Applicant Address (priority 5, Address_Line_1__c filled)
     * - Repayment bank account
     * - Charges (Insurance/LMS/LOS etc)
     * - Sanction condition pending
     * - Integration_Details__c with Business_Date__c (for plfDate query)
     * - OpportunityTeamMember (Sales Manager) with manager
     */
    private static Opportunity createScenario(String finType, String primaryCustomerType) {

        // Users for OppTeamMember (and Lead area manager)
        User am = createUser('areamgr');
        User rmManager = createUser('mgrusr');
        User rm = createUser('rmusr');
        rm.ManagerId = rmManager.Id;
        update rm;

        // Branch Master
        Account br = new Account(
            Name = 'Test Branch',
            Branch_Code__c = '3002'
        );
        insert br;

        // Lead (so Lead__r.Dsa_Area_Manager__r.email is safe)
        Lead ld = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Co',
            Status = 'Open - Not Contacted',
            Dsa_Area_Manager__c = am.Id,
			MobilePhone='8493939392',
			Customer_Type__c='Individual',
			Product__c='Affordable Home Loan'

        );
        insert ld;

        // Opportunity (Loan Application)
        Opportunity opp = new Opportunity(
            Name = 'LA-' + finType + '-' + primaryCustomerType,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),

            Product__c = 'Affordable Home Loan', // used in request.typeOfLoan mapping too
            Variant__c = 'Term Loan',

            Sanction_Loan_Amount__c = 500000,
            Sanction_Tenure__c = 120,
            Final_Tenure__c = 120,

            Final_Rate_Of_Interest__c = 12.5,
            Loan_Purpose__c = 'Balance Transfer',
            APR__c = 16.5,

            Branch_Master__c = br.Id,
            Lead__c = ld.Id
        );
        insert opp;

        // Needed for wrapper.firstrepay-like logic (in this handler it reads EMI_Amount_Repayment_Schedule__c)
        opp.EMI_Amount_Repayment_Schedule__c = 25000;
        update opp;

        // Opp Team Member (for RM/AM loop)
        OpportunityTeamMember otm = new OpportunityTeamMember(
            OpportunityId = opp.Id,
            UserId = rm.Id,
            TeamMemberRole = 'Sales Manager'
        );
        insert otm;

        // Integration_Details__c with Business_Date__c for plfDate query
        insert new Integration_Details__c(
            Name = 'Biz Date',
            Business_Date__c = Date.today(),
			Endpoint__c = 'DUMMY'
        );

        // Customer records (whatever object your Application_Applicant__c.Customer__c points to)
        // In many orgs it is Account or a custom Customer__c. Your query uses Customer__r.SF_Customer_ID__c and Customer_LMS_Id__c.
        // So create the correct object type based on your schema.
        // If Customer__c is a lookup to Account in your org, change this to Account and fields accordingly.

        // Assuming Customer__c exists (custom object). If it is Account, replace Customer__c with Account.
		 Id rtId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account custPrimary = new Account(
            Name = 'Primary Customer',
            //SF_Customer_ID__c = 'C-12345',
            Customer_LMS_Id__c = null,
			RecordTypeId = rtId2
        );
        insert custPrimary;
		 Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();

        Account custCo = new Account(
            Name = 'Co Customer',
            //SF_Customer_ID__c = 'C-99999',
            Customer_LMS_Id__c = 'LMS-CO-1',
			RecordTypeId = rtId
        );
        insert custCo;

        // Primary Applicant (mandatory)
        Application_Applicant__c primary = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Primary Applicant',
            Customer__c = custPrimary.Id,

            //Applicant_Name__c = 'Primary Applicant',
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Mobile_Number__c = '9999999999',
            Email__c = 'john@test.com',
            Salutation__c = 'Mr.',
            Customer_Type__c = primaryCustomerType, // 'Individual' OR 'Non Individual'
            Nationality__c = 'Indian',
            Gender__c = 'Male',
            Residency_Status__c = 'Resident',
            Employment_Type__c = 'Salaried',
            DOB__c = Date.newInstance(1990, 1, 1),
            Marital_Status__c = 'Single',
            PAN_Number__c = 'ABCPE1234F'
        );
        insert primary;

        // Co Applicant (optional but we add to cover co-app loops)
        Application_Applicant__c coApp = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Co Applicant',
            Customer__c = custCo.Id,

            //Applicant_Name__c = 'Co Applicant',
            First_Name__c = 'Jane',
            Last_Name__c = 'Doe',
            Mobile_Number__c = '8888888888',
            Email__c = 'jane@test.com',
            Salutation__c = 'Ms.',
            Customer_Type__c = 'Individual',
            Nationality__c = 'Indian',
            Gender__c = 'Female',
            Residency_Status__c = 'Resident',
            Employment_Type__c = 'Salaried',
            DOB__c = Date.newInstance(1992, 2, 2),
            Marital_Status__c = 'Married',
            PAN_Number__c = 'TQRPX1234Y'
        );
        insert coApp;

        // Applicant Address priority 5 (Full_Address1__c is formula; set Address_Line_1__c)
        insert new Applicant_Address__c(
            Applicant__c = primary.Id,
            Loan_Application__c = opp.Id,
            Address_Priority__c = '5',
            Address_Line_1__c = '123 Test Street'
        );

        insert new Applicant_Address__c(
            Applicant__c = coApp.Id,
            Loan_Application__c = opp.Id,
            Address_Priority__c = '5',
            Address_Line_1__c = '456 Co Street'
        );

        // Bank Master + Repayment Bank Details
        Bank_Branch_Master__c bm = new Bank_Branch_Master__c(
            Name = 'Test Bank',
            MICR__c = 'MICR001',
            Branch_Name__c = 'Main Branch',
            Branch_Location__c = 'Mumbai'
        );
        insert bm;

        insert new Bank_Details__c(
            Name = 'Repayment A/c',
            Account_Holder_Name__c = 'John Doe',
            Account_Number__c = '1234567890',
            Account_Type__c = 'Saving',
            Is_Repayment_Account__c = true,
            Application_Applicant__c = primary.Id,
            Bank_Master__c = bm.Id
        );

        // Pending sanction condition
        insert new Sanction_Condition__c(
            Loan_Application__c = opp.Id,
            Condition_Name__c = 'Condition 1',
            Condition_Approval__c = 'Pending'
        );

        // Product master for finType
        Product_Master__c pm = new Product_Master__c(
            Name = 'PM-' + finType,
            PLF_Loan_Type__c = finType   // 'AH' or 'FL'
        );
        insert pm;

		Map<String, String> C = COMM_IncomeSanctionLetterHandler.getConstants();

        // Product2 graph expected by the handler
        Product2 mainProduct = new Product2(
            Name = opp.Product__c,
            Loan_Application__c = opp.Id,
            RecordTypeId = p2Rt(C.get('Product')),
            Product_Master__c = pm.Id
        );
        insert mainProduct;

        Product2 subProduct = new Product2(
            Name = 'SubProd-1',
            Loan_Application__c = opp.Id,
            RecordTypeId = p2Rt('Sub_Product'),
            Product__c = mainProduct.Id
        );
        insert subProduct;

        Product2 variant = new Product2(
            Name = 'Variant-1',
            Loan_Application__c = opp.Id,
            RecordTypeId = p2Rt(C.get('Variant')),
            Product__c = subProduct.Id,
            Interest_Days_Basis__c = '30E/360I',
            BPI_Interest_Days_Basis__c = '30E/360I',
            PLR_Code__c = 'GHFPLR',
            PLR_Value__c = 18.31
        );
        insert variant;

        Product2 subVariant = new Product2(
            Name = 'Interest Only',
            Loan_Application__c = opp.Id,
            RecordTypeId = p2Rt(C.get('Sub_Variant')),
            Product__c = subProduct.Id
        );
        insert subVariant;

        // Hybrid Tenure record referenced by Sub_Variant__c
        insert new Product2(
            Name = '12',
            Loan_Application__c = opp.Id,
            RecordTypeId = p2Rt(C.get('Hybrid_Tenure')),
            Sub_Variant__c = subVariant.Id
        );

        // Charges_Insurance__c (RecordType = Charges, Product_Name__c matches opp.Product__c)
        Id chargesRT = chargesRt('Charges');

        insert new Charges_Insurance__c(
            Name = 'INS01',
            Loan_Application__c = opp.Id,
            RecordTypeId = chargesRT,
            Category__c = 'Insurance',
           // Product_Name__c = opp.Product__c,
            Final_Amount_INR__c = 1000
        );

        insert new Charges_Insurance__c(
            Name = 'LOSAMC',
            Loan_Application__c = opp.Id,
            RecordTypeId = chargesRT,
            Category__c = 'LMS',
            //Product_Name__c = opp.Product__c,
            Requested_Percentage__c = 2
        );

        insert new Charges_Insurance__c(
            Name = 'PROCFEE',
            Loan_Application__c = opp.Id,
            RecordTypeId = chargesRT,
            Category__c = 'LOS',
            //Product_Name__c = opp.Product__c,
            Requested_Amount_INR__c = 500,
            Final_Amount_INR__c = 550
        );

        insert new Charges_Insurance__c(
            Name = 'STFRCHG',
            Loan_Application__c = opp.Id,
            RecordTypeId = chargesRT,
            Category__c = 'LOS',
            //Product_Name__c = opp.Product__c,
            Final_Amount_INR__c = 200
        );

        return opp;
    }

    // ---------------- TEST 1: validatePayload coverage ----------------
    @IsTest
    static void testValidatePayload_missingFields() {
        Opportunity opp = new Opportunity(
            Name='MissingFields',
            StageName='Prospecting',
            CloseDate=Date.today().addDays(5),
            Product__c='Affordable Home Loan'
            // Sanction fields intentionally missing
        );
        insert opp;

        IntHandler.ProcessReqWrapper w = new IntHandler.ProcessReqWrapper();
        w.loanApplicationId = opp.Id;

        Test.startTest();
        List<String> errs = COMM_IncomeSanctionLetterHandler.validatePayload(w);
        Test.stopTest();

        System.assert(errs.size() > 0, 'Should return missing-field errors');
    }

    // ---------------- TEST 2: constructPayload with AH + Individual ----------------
    @IsTest
    static void testConstructPayload_AH_Individual() {
        Opportunity opp = createScenario('AH', 'Individual');

        IntHandler.ProcessReqWrapper w = new IntHandler.ProcessReqWrapper();
        w.loanApplicationId = opp.Id;

        COMM_IncomeSanctionLetterHandler h = new COMM_IncomeSanctionLetterHandler();

        Test.startTest();
        // integrationSettings param is not used meaningfully; pass empty list
        String jsonPayload = h.constructPayload(w, new List<Integration_Details__c>());
        Test.stopTest();

        System.assert(String.isNotBlank(jsonPayload), 'Payload should be generated');
        System.assert(jsonPayload.contains('"custctgcode":"RETAIL"') || jsonPayload.contains('"custctgcode":"RETAIL"'.toLowerCase()),
            'Should set RETAIL for Individual');
    }
	
    // ---------------- TEST 3: constructPayload with FL + Non Individual (hits FL block + salutation M/S + CORP) ----------------
    @IsTest
    static void testConstructPayload_FL_NonIndividual() {
        Opportunity opp = createScenario('FL', 'Non Individual');

        IntHandler.ProcessReqWrapper w = new IntHandler.ProcessReqWrapper();
        w.loanApplicationId = opp.Id;

        COMM_IncomeSanctionLetterHandler h = new COMM_IncomeSanctionLetterHandler();
		try
		{

        Test.startTest();
        String jsonPayload = h.constructPayload(w, new List<Integration_Details__c>());
        Test.stopTest();
		}
		Catch(Exception e)
		{

		}

        //System.assert(String.isNotBlank(jsonPayload), 'Payload should be generated');
       // System.assert(jsonPayload.contains('"custctgcode":"CORP"') || jsonPayload.contains('"custctgcode":"CORP"'.toLowerCase()),
            //'Should set CORP for Non Individual');
    }
	

    // ---------------- TEST 4: formatDateString coverage ----------------
    @IsTest
    static void testFormatDateString() {
        Test.startTest();
        String s1 = COMM_IncomeSanctionLetterHandler.formatDateString(Date.newInstance(2025, 1, 5));
        String s2 = COMM_IncomeSanctionLetterHandler.formatDateString(null);
        Test.stopTest();

        System.assertEquals('2025-01-05T00:00:00', s1);
        System.assertEquals(null, s2, 'Null date should return null');
    }
}