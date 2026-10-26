@IsTest
public class COMM_IncomeSanctionLetterControllerTest {
    
    @testSetup
    public static void setup() {
        // ---- SETUP OBJECTS ONLY ----
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example11111.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert testUser;

        PermissionSet ps = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'PS_Sales_Executive_HL'
            LIMIT 1
        ];
        System.debug('ps '+ps);

        insert new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = ps.Id
        );
        System.debug('PermissionSetAssignment '+[select id from PermissionSetAssignment where AssigneeId =:testUser.Id]);
    }

    // Helper to get Product2 RecordType by name via your Utility constants
    private static Id productRt(String keyName) {
        Map<String,String> consts = COMM_IncomeSanctionLetterController.getConstants();
        String rtName = consts.get(keyName);
        System.assertNotEquals(null, rtName, 'Missing constant for ' + keyName + ' from Utility.getConstants');
        RecordType rt = [
            SELECT Id, Name
            FROM RecordType
            WHERE SObjectType = 'Product2' AND Name = :rtName
            LIMIT 1
        ];
        return rt.Id;
    }

    // Minimal creator for required lookups that appear in your SOQL/logic
    private static User makeUserWithManager(String alias, String mgrAlias) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User mgr = new User(
            FirstName='Mgr', LastName='User ' + mgrAlias,
            Alias=mgrAlias, Email=mgrAlias + '@test.com',
            Username=mgrAlias + '@test.com.' + System.currentTimeMillis(),
            CommunityNickname='mgr' + mgrAlias,
            TimeZoneSidKey='Asia/Kolkata',
            LocaleSidKey='en_US', EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            ProfileId=p.Id
        );
        insert mgr;

        User u = new User(
            FirstName='RM', LastName='User ' + alias,
            Alias=alias, Email=alias + '@test.com',
            Username=alias + '@test.com.' + System.currentTimeMillis(),
            CommunityNickname='rm' + alias,
            TimeZoneSidKey='Asia/Kolkata',
            LocaleSidKey='en_US', EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            ManagerId=mgr.Id,
            ProfileId=p.Id
        );
        insert u;
        return u;
    }

   /* private static Id ensureBranchMaster() {
        // Only the fields used in code are set
        Branch_Master__c b = new Branch_Master__c(Name='Test Branch', Branch_Code__c='3002');
        insert b;
        return b.Id;
    }*/

    private static Id ensureProductMaster(String loanType) {
        Product_Master__c pm = new Product_Master__c(Name='PM-'+loanType, PLF_Loan_Type__c=loanType);
        insert pm;
        return pm.Id;
    }

    private static void addOppTeam(Id oppId, Id userId) {
        // Ensure role string used in controller ('Sales Manager' OR 'Relationship Manager')
        OpportunityTeamMember tm = new OpportunityTeamMember(
            OpportunityId = oppId,
            UserId = userId,
            TeamMemberRole = 'Sales Manager'
        );
        insert tm;
    }

    private static Opportunity makeOpp(String name, String loanHierarchy, Id splitParentId) {
        Opportunity o = new Opportunity(
            Name = name,
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(10),
            Product__c = 'Affordable Home Loan', // referenced as productName
            Sanction_Loan_Amount__c = 1000000,
            Sanction_Tenure__c = 120,
            Final_Tenure__c = 120,
            Final_Rate_Of_Interest__c = 9.5,
            APR__c = 12.34,
            //Loan_Purpose__c = 'Business Expansion',
            Loan_Hierarchy__c = loanHierarchy,
            Split_Parent_Loan_Application__c = splitParentId
        );
        insert o;
        return o;
    }

    private static void setupApplicantsWithAddresses(Id oppId) {
        // Primary Applicant (Individual)
        Id customerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account acc = new Account(Name = 'Test Customer', RecordTypeId = customerRtId);
        acc.Customer_LMS_Id__c='CIFPRIM001';
        insert acc;
        Application_Applicant__c prim = new Application_Applicant__c(
            Loan_Application__c = oppId,
            Applicant_Type__c = 'Primary Applicant',
           // Applicant_Name__c = 'Primary Person',
            First_Name__c = 'Pri',
            Last_Name__c = 'Mary',
            Customer_Type__c = 'Individual',
            Employment_Type__c = 'Salaried',
            Gender__c = 'Male',
            Residency_Status__c = 'Resident',
            Nationality__c = 'Indian',
          //  Account_Holder_Name__c = 'test',
           // Salutation__c = 'Mr',
            Mobile_Number__c = '9999999999',
            Email__c = 'primary@test.com',
            Mother_s_First_Name__c = 'Mom',
            Father_s_First_Name__c = 'Dad',
            DOB__c = Date.newInstance(1990,1,1),
            PAN_Number__c = 'ABCPE1234F',
            customer__c = acc.Id
        );
        insert prim;

        // Co-Applicant (Individual)
        Application_Applicant__c co = new Application_Applicant__c(
            Loan_Application__c = oppId,
            Applicant_Type__c = 'Co Applicant',
           // Applicant_Name__c = 'Co Person',
            First_Name__c = 'Co',
            Last_Name__c = 'App',
            Customer_Type__c = 'Individual',
            //Employment_Type__c = 'Self Employed',
            Gender__c = 'Female',
            Residency_Status__c = 'Resident',
            Nationality__c = 'Indian',
            //Salutation__c = 'Ms',
            Mobile_Number__c = '8888888888',
            Email__c = 'co@test.com',
            Mother_s_First_Name__c = 'Mom2',
            Father_s_First_Name__c = 'Dad2',
            DOB__c = Date.newInstance(1992,2,2),
            PAN_Number__c = 'ABCPE1235G'
            
        );
        insert co;

        // Primary Address (priority 5)
        Applicant_Address__c primAddr = new Applicant_Address__c(
            Applicant__c = prim.Id,
            Address_Line_1__c = 'Line 1',
            Address_Priority__c = '5'
           // Full_Address1__c = 'Line 1, City, ST 123456'
        );
        insert primAddr;

        // Co-Applicant Address (priority 5)
        Applicant_Address__c coAddr = new Applicant_Address__c(
            Applicant__c = co.Id,
            Address_Line_1__c = 'C-Line 1',
            Address_Priority__c = '5'
            //Full_Address1__c = 'C-Line 1, City, ST 123456'
        );
        insert coAddr;

        // Repayment Bank for primary (picked first by ORDER)
       // Bank_Master__c bm = new Bank_Master__c(Name='Test Bank', MICR__c='123', Branch_Name__c='Main', Branch_Location__c='City');
     //   insert bm;

        Bank_Details__c bd = new Bank_Details__c(
            Application_Applicant__c = prim.Id,
            Is_Repayment_Account__c = true,
            Account_Number__c = '1234567890',
            Name = 'Test Bank A/c',
            Account_Holder_Name__c = 'test'
        );
        insert bd;
    }

    private static void setupCharges(Id oppId, String productName) {
        // Insurance category (sums to insuranceCharges)
        insert new Charges_Insurance__c(
            Loan_Application__c = oppId,
           // Product_Name__c = productName,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Charges_Insurance__c' AND Name='Charges' LIMIT 1].Id,
            Category__c = 'Insurance',
            Name = 'INS1',
            Final_Amount_INR__c = 2500
        );
        // LMS -> LOSAMC % (amcCharges used but not sent to request directly; ok to include)
        insert new Charges_Insurance__c(
            Loan_Application__c = oppId,
            //Product_Name__c = productName,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Charges_Insurance__c' AND Name='Charges' LIMIT 1].Id,
            Category__c = 'LMS',
            Name = 'LOSAMC',
            Requested_Percentage__c = 2
        );
        // LOS -> PROCFEE (Requested & Final used)
        insert new Charges_Insurance__c(
            Loan_Application__c = oppId,
          //  Product_Name__c = productName,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Charges_Insurance__c' AND Name='Charges' LIMIT 1].Id,
            Category__c = 'LOS',
            Name = 'PROCFEE',
            Requested_Amount_INR__c = 5000,
            Final_Amount_INR__c = 4500
        );
        // LOS -> STFRCHG (Final used)
        insert new Charges_Insurance__c(
            Loan_Application__c = oppId,
            //Product_Name__c = productName,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Charges_Insurance__c' AND Name='Charges' LIMIT 1].Id,
            Category__c = 'LOS',
            Name = 'STFRCHG',
            Final_Amount_INR__c = 1500
        );
    }

    private static void setupCollateral(Id oppId) {
        // dependencies for collateral address
       // Pincode__c pin = new Pincode__c(Name='400001');
       // insert pin;

        Collateral__c col = new Collateral__c(
           // Name='COL-1',
           // Unit_Number__c='U-101',
            Floor_Number__c='10',
            Tower_Building_Name__c='T1',
            Project__c = null, // optional in code (guarded)
            Address_Line_1__c='Addr1',
            Address_Line_2__c='Addr2',
            Address_Line_3__c='Addr3',
            Landmark__c='Near Park',
           // City__c='Mumbai',
            State__c='MH',
           // Pincode__c = pin.Id,
            Unit_Property_Type__c='Flat'
        );
        insert col;

        Application_Collateral__c ac = new Application_Collateral__c(
            HL_Loan_Application__c = oppId,
            Collateral__c = col.Id
        );
        insert ac;
    }

    private static void setupSanctionConditions(Id oppId) {
        insert new Sanction_Condition__c(
            Loan_Application__c = oppId,
            Condition_Approval__c = 'Pending',
            Condition_Name__c = 'Submit KYC'
        );
        insert new Sanction_Condition__c(
            Loan_Application__c = oppId,
            Condition_Approval__c = 'Pending',
            Condition_Name__c = 'Sign Agreement'
        );
    }

    private static void setupIntegrationBusinessDate() {
        insert new Integration_Details__c(
            Name = 'Business Date',
            Business_Date__c = System.today(),
            Endpoint__c = 'test'
        );
        insert new Integration_Details__c(
            Name = 'Communication Event',
            Business_Date__c = System.today(),
            Endpoint__c = 'test'
        );
    }

    private static void setupProductHierarchy(Id oppId, Id productMasterId) {
        // Use names from constants to ensure queries match
        Map<String,String> C = COMM_IncomeSanctionLetterController.getConstants();

        // Main Product (RecordType.Name = constants['Product'], Name = Opp.Product__c)
        Product2 mainProd = new Product2(
            Name = 'Affordable Home Loan',
            ProductCode = 'MAIN',
            IsActive = true,
            Loan_Application__c = oppId,
            Product_Master__c = productMasterId,
            RecordTypeId = productRt('Product'),
            Product_Type__c  = 'Parent'
        );
        insert mainProd;

        // Sub Product (RecordType.Name = constants['Sub_Product'], Product__c=mainProd.Id)
        Product2 subProd = new Product2(
            Name = 'SubProd-1',
            ProductCode = 'SUB',
            IsActive = true,
            Loan_Application__c = oppId,
            Product__c = mainProd.Id,
            RecordTypeId = productRt('Sub_Product')
        );
        insert subProd;

        // Variant (RecordType.Name = constants['Variant'], Product__c = subProd.Id)
        Product2 variant = new Product2(
            Name = 'Variant-1',
            ProductCode = 'VAR',
            IsActive = true,
            Loan_Application__c = oppId,
            Product__c = subProd.Id,
            PLR_Code__c = 'GHFPLR',
            PLR_Value__c = 18.31,
            Interest_Days_Basis__c = '30E/360I',
            BPI_Interest_Days_Basis__c = '30E/360I',
            RecordTypeId = productRt('Variant')
        );
        insert variant;

        // Sub Variant (RecordType.Name = constants['Sub_Variant'], Product__c = subProd.Id)
        Product2 subVariant = new Product2(
            Name = 'SubVariant-1',
            ProductCode = 'SVAR',
            IsActive = true,
            Loan_Application__c = oppId,
            Product__c = subProd.Id,
            RecordTypeId = productRt('Sub_Variant')
        );
        insert subVariant;

        // Optional: Hybrid Tenure child of Sub Variant (queried but not strictly used)
        // Only create if RecordType exists
        try {
            Id rtHy = productRt('Hybrid_Tenure');
            Product2 hy = new Product2(
                Name = '12', // tenure stored as Name per your comment
                ProductCode = 'HY',
                IsActive = true,
                Loan_Application__c = oppId,
                Sub_Variant__c = subVariant.Id,
                RecordTypeId = rtHy
            );
            insert hy;
        } catch (Exception ignore) {
            // If org has no such record type, it's fine—the code guards its usage
        }
    }

    @IsTest
    static void test_formatDateString_and_successFlow() {
        // Validate formatDateString
        Date d = Date.newInstance(2024, 12, 25);
        String iso = COMM_IncomeSanctionLetterController.formatDateString(d);
        System.assertEquals('2024-12-25T00:00:00', iso, 'Expected ISO date at midnight');

        // Test null date (should return null)
        System.assertEquals(null, COMM_IncomeSanctionLetterController.formatDateString(null));

        // Data setup
      //  Id branchId = ensureBranchMaster();
        Id prodMasterId = ensureProductMaster('AH'); // Affordable Housing
        Opportunity opp = makeOpp('Parent Opp', 'Parent', null);

        setupApplicantsWithAddresses(opp.Id);
        setupCharges(opp.Id, 'Affordable Home Loan');
        setupCollateral(opp.Id);
        setupSanctionConditions(opp.Id);
        setupIntegrationBusinessDate();
        setupProductHierarchy(opp.Id, prodMasterId);

        // Opp Team
        User rm = makeUserWithManager('rm01', 'mgr01');
        addOppTeam(opp.Id, rm.Id);

        Product2 prod= [SELECT Id, Name FROM Product2 LIMIT 1];
        Product2 subProd = new Product2(
            Name= 'sub prod',
            Product__c= prod.Id
        );
        insert subProd;
        Product2 subprodrec= [SELECT Id, Name, Product__r.Name, Product__c FROM Product2 WHERE Product__c!= null LIMIT 1];
        Test.startTest();
        String res = COMM_IncomeSanctionLetterController.sendIncomeSanctionEvent(opp.Id, '');
        COMM_IncomeSanctionLetterController.generateSanctionLetterEvent(opp.Id,'dfjhgsdfhsvdfjhsdvf', subprodrec);
        Test.stopTest();

        //System.assertEquals('success', res, 'Expected success from sendIncomeSanctionEvent');
    }

    @IsTest
    static void test_childLoanBranch_and_eventPublish() {
        // Parent-Loans and child scenario
       // Id branchId = ensureBranchMaster();
        Id prodMasterId = ensureProductMaster('AH');

       /* Opportunity parentOpp = makeOpp('Parent Opp 2', a0988999, 'Parent', null);
        Opportunity childOpp  = makeOpp('Child Opp', a0987899, 'Child', parentOpp.Id);

        setupApplicantsWithAddresses(parentOpp.Id); // data linked to parent (requiredLoanId logic)
        setupCharges(parentOpp.Id, 'Affordable Home Loan');
        setupCollateral(parentOpp.Id);
        setupSanctionConditions(parentOpp.Id);
        setupIntegrationBusinessDate();
        setupProductHierarchy(parentOpp.Id, prodMasterId);*/

        // Team on child or parent works; controller queries on loanApplicationId (child) for team, ok to add to child
        User rm = makeUserWithManager('rm02', 'mgr02');
       // addOppTeam(childOpp.Id, rm.Id);

        Test.startTest();
        // Also exercise generateSanctionLetterEvent directly
        String payload = '{"dummy":"json"}';
       // COMM_IncomeSanctionLetterController.generateSanctionLetterEvent(childOpp.Id, payload);

        // Main call should resolve to parent data because child points to parent
       // String res = COMM_IncomeSanctionLetterController.sendIncomeSanctionEvent(childOpp.Id);
        Test.stopTest();

       // System.assertEquals('success', res, 'Expected success for child -> parent resolution');
    }
    
/*       @isTest
    static void testValidatePayload() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        
        Test.startTest();
        List<String> result = COMM_IncomeSanctionLetterHandler.validatePayload(wrapper);
        
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(0, result.size(), 'No validation errors expected for complete data');
    }

    @isTest
    static void testConstructPayload() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Integration_Details__c integrationSetting = [SELECT Id FROM Integration_Details__c LIMIT 1];
        List<Integration_Details__c> integrationList = new List<Integration_Details__c>{integrationSetting};

        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;

        Test.startTest();
        String payload = new COMM_IncomeSanctionLetterHandler().constructPayload(wrapper, integrationList);
        Test.stopTest();

        System.assertNotEquals(null, payload, 'Payload should not be null');
    }
    
   
    @isTest
    static void testgetExistingSanctionLetter() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Integration_Details__c integrationSetting = [SELECT Id,Name FROM Integration_Details__c Where Name='Communication Event' LIMIT 1];
        integrationSetting.Loan_Application__c = opp.Id;
        update integrationSetting;
        Test.startTest();
        COMM_IncomeSanctionLetterController.getExistingSanctionLetter(opp.Id);
        Test.stopTest();
    } */
    
    
    @isTest
    static void testSendIncomeSanctionEvent() {
        // 1. Setup Master Data
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // 2. Setup Opportunity (Loan Application)
        Opportunity opp = new Opportunity(
            Name = 'Test Loan Application',
            StageName = 'Processing',
            CloseDate = Date.today().addDays(30),
            Loan_Hierarchy__c = 'Parent',
            Sanction_Loan_Amount__c = 500000,
            Final_Rate_Of_Interest__c = 8.5,
            Product__c = 'Home Loan'
        );
        insert opp;

        // 3. Setup Primary Applicant
        Application_Applicant__c primaryApp = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Primary Applicant',
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Mobile_Number__c = '9876543210',
            Email__c = 'john@example.com'
        );
        insert primaryApp;

        // 4. Setup Applicant Address (Required for your 'Address_Priority__c = 5' filter)
        Applicant_Address__c addr = new Applicant_Address__c(
            Applicant__c = primaryApp.Id,
            Address_Line_1__c = '123 Main St',
            Address_Priority__c = '5'
        );
        insert addr;

        // 5. Setup Opportunity Team Member (Required for Sales Manager query)
        // Note: In real orgs, use a valid User ID
        OpportunityTeamMember otm = new OpportunityTeamMember(
            OpportunityId = opp.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'Sales Manager'
        );
        insert otm;
		
        List<Charges_Insurance__c> testCharges = new List<Charges_Insurance__c>();
        testCharges.add(new Charges_Insurance__c(
            Loan_Application__c = opp.Id,
            Category__c = 'Insurance',
            Final_Amount_INR__c = 5000
        ));
        testCharges.add(new Charges_Insurance__c(
        Loan_Application__c = opp.Id,
        Category__c = 'LMS',
        Name = 'LOSAMC',
        Requested_Percentage__c = 2.0
   		));
        insert testCharges;
        // 6. Execute the Method
        Test.startTest();
        // Correct static call syntax: ClassName.MethodName
        String result = COMM_IncomeSanctionLetterController.sendIncomeSanctionEvent(opp.Id, 'Test_Prod_ID');
        
        // Also cover the second method from your previous query
        List<Integration_Details__c> existingLetters = COMM_IncomeSanctionLetterController.getExistingSanctionLetter(opp.Id);
        Test.stopTest();

        // 7. Assertions
        System.assertNotEquals(null, result, 'The response should not be null');
        System.assertNotEquals(null, existingLetters, 'The existing letters list should be initialized');
    }
    
    @IsTest
    static void test_formatDateString_and_successFlow_1() {
        // Validate formatDateString
        Date d = Date.newInstance(2024, 12, 25);
        String iso = COMM_IncomeSanctionLetterController.formatDateString(d);
        System.assertEquals('2024-12-25T00:00:00', iso, 'Expected ISO date at midnight');

        // Test null date (should return null)
        System.assertEquals(null, COMM_IncomeSanctionLetterController.formatDateString(null));

        // Data setup
      //  Id branchId = ensureBranchMaster();
        Id prodMasterId = ensureProductMaster('AH'); // Affordable Housing
        Opportunity opp = makeOpp('Parent Opp', 'Parent', null);

        setupApplicantsWithAddresses(opp.Id);
        setupCharges(opp.Id, 'Affordable Non-Home Loan');
        setupCollateral(opp.Id);
        setupSanctionConditions(opp.Id);
        setupIntegrationBusinessDate();
        setupProductHierarchy(opp.Id, prodMasterId);

        // Opp Team
        User rm = makeUserWithManager('rm01', 'mgr01');
        addOppTeam(opp.Id, rm.Id);

        Product2 prod= [SELECT Id, Name FROM Product2 LIMIT 1];
        Product2 subProd = new Product2(
            Name= 'sub prod',
            Product__c= prod.Id
        );
        insert subProd;
        Product2 subprodrec= [SELECT Id, Name, Product__r.Name, Product__c FROM Product2 WHERE Product__c!= null LIMIT 1];
        Test.startTest();
        String res = COMM_IncomeSanctionLetterController.sendIncomeSanctionEvent(opp.Id, '');
        COMM_IncomeSanctionLetterController.generateSanctionLetterEvent(opp.Id,'dfjhgsdfhsvdfjhsdvf', subprodrec);
        Test.stopTest();

        //System.assertEquals('success', res, 'Expected success from sendIncomeSanctionEvent');
    }
    
    @IsTest
    static void test_formatDateString_and_successFlow_2() {
        // Validate formatDateString
        Date d = Date.newInstance(2024, 12, 25);
        String iso = COMM_IncomeSanctionLetterController.formatDateString(d);
        System.assertEquals('2024-12-25T00:00:00', iso, 'Expected ISO date at midnight');

        // Test null date (should return null)
        System.assertEquals(null, COMM_IncomeSanctionLetterController.formatDateString(null));
        

        
      //  Id branchId = ensureBranchMaster();
        User rm = makeUserWithManager('rm01', 'mgr01');
        Test.startTest();
        
       
        User u = [SELECT id from User where Email = 'testuser@example11111.com'];
        System.debug('u '+u);
       // }
        System.runAs(u) {
            Id prodMasterId = ensureProductMaster('HL'); // Affordable Housing
        Opportunity opp = makeOpp('Parent Opp', 'Parent', null);
		String oppId = opp.Id;
        setupApplicantsWithAddresses(opp.Id);
            setupProductHierarchy(opp.Id, prodMasterId);
            Product2 prod= [SELECT Id, Name FROM Product2 where Loan_Application__c =:opp.Id and recordtype.name = 'Product' ];
        insert new Charges_Insurance__c(
            Loan_Application__c = oppId,
           // Product_Name__c = productName,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Charges_Insurance__c' AND Name='Charges' LIMIT 1].Id,
            Category__c = 'Insurance',
            Name = 'INS1',
            Final_Amount_INR__c = 2500,
            Product__c = prod.id
        );
        // LMS -> LOSAMC % (amcCharges used but not sent to request directly; ok to include)
        insert new Charges_Insurance__c(
            Loan_Application__c = oppId,
            //Product_Name__c = productName,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Charges_Insurance__c' AND Name='Charges' LIMIT 1].Id,
            Category__c = 'LMS',
            Name = 'LOSAMC',
            Requested_Percentage__c = 2,
            Product__c = prod.id
        );
        // LOS -> PROCFEE (Requested & Final used)
        insert new Charges_Insurance__c(
            Loan_Application__c = oppId,
          //  Product_Name__c = productName,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Charges_Insurance__c' AND Name='Charges' LIMIT 1].Id,
            Category__c = 'LOS',
            Name = 'PROCFEE',
            Requested_Amount_INR__c = 5000,
            Final_Amount_INR__c = 4500,
            Product__c = prod.id
        );
        // LOS -> STFRCHG (Final used)
        insert new Charges_Insurance__c(
            Loan_Application__c = oppId,
            //Product_Name__c = productName,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Charges_Insurance__c' AND Name='Charges' LIMIT 1].Id,
            Category__c = 'LOS',
            Name = 'STFRCHG',
            Final_Amount_INR__c = 1500,
            Product__c = prod.id
        );
        setupCollateral(opp.Id);
        setupSanctionConditions(opp.Id);
        setupIntegrationBusinessDate();
        

        // Opp Team
        
        addOppTeam(opp.Id, rm.Id);

        
        Product2 subProd = new Product2(
            Name= 'sub prod',
            Product__c= prod.Id
        );
        insert subProd;
        Product2 subprodrec= [SELECT Id, Name, Product__r.Name, Product__c FROM Product2 WHERE Product__c!= null LIMIT 1];
                String res = COMM_IncomeSanctionLetterController.sendIncomeSanctionEvent(opp.Id, '');
                
           COMM_IncomeSanctionLetterController.generateSanctionLetterEvent(opp.Id,'dfjhgsdfhsvdfjhsdvf', subprodrec);
        }
        
        Test.stopTest();

        //System.assertEquals('success', res, 'Expected success from sendIncomeSanctionEvent');
    }
    
    @IsTest
    static void test_formatDateString_and_successFlow_3() {
        // Validate formatDateString
        Date d = Date.newInstance(2024, 12, 25);
        String iso = COMM_IncomeSanctionLetterController.formatDateString(d);
        System.assertEquals('2024-12-25T00:00:00', iso, 'Expected ISO date at midnight');

        // Test null date (should return null)
        System.assertEquals(null, COMM_IncomeSanctionLetterController.formatDateString(null));

        // Data setup
      //  Id branchId = ensureBranchMaster();
        Id prodMasterId = ensureProductMaster('FL'); // Affordable Housing
        Opportunity opp = makeOpp('Parent Opp', 'Parent', null);
        setupApplicantsWithAddresses(opp.Id);
        setupCharges(opp.Id, 'Affordable Non-Home Loan');
        setupCollateral(opp.Id);
        setupSanctionConditions(opp.Id);
        setupIntegrationBusinessDate();
        setupProductHierarchy(opp.Id, prodMasterId);

        // Opp Team
        User rm = makeUserWithManager('rm01', 'mgr01');
        addOppTeam(opp.Id, rm.Id);

        Product2 prod= [SELECT Id, Name FROM Product2 LIMIT 1];
        Product2 subProd = new Product2(
            Name= 'sub prod',
            Product__c= prod.Id
        );
        insert subProd;
        Product2 subprodrec= [SELECT Id, Name, Product__r.Name, Product__c FROM Product2 WHERE Product__c!= null LIMIT 1];
        Test.startTest();
        String res = COMM_IncomeSanctionLetterController.sendIncomeSanctionEvent(opp.Id, '');
        COMM_IncomeSanctionLetterController.generateSanctionLetterEvent(opp.Id,'dfjhgsdfhsvdfjhsdvf', subprodrec);
        Test.stopTest();

        //System.assertEquals('success', res, 'Expected success from sendIncomeSanctionEvent');
    }

}