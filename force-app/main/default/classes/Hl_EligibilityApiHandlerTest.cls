@isTest
public class Hl_EligibilityApiHandlerTest {
    
    @TestSetup static void createTestData() {
        Account dummyAcc = new Account(Name = 'Dummy Account');
        insert dummyAcc;
        dummyAcc.Branch_Code__c = '1001';
        update dummyAcc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp2',
            StageName = 'Sales Login',
            CloseDate = Date.today(),
            Amount = 10000,
            Pricing_Approval_Status__c = 'Submitted For Approval',
            Is_Pricing_Approval_Required__c = false,
            Sanction_Loan_Amount__c = 50000,
            Sanction_Tenure__c = 12,
            Sanction_Rate_Of_Interest__c = 10,
            Product__c='Home Loan',
            Sub_stage__c='PSV Sales',
            Branch_Master__c =  dummyAcc.ParentID,
            Sub_Branch__c =dummyAcc.id,
            Status__c='Soft Rejected',
            Is_Loan_Unassigned__c =true,
            Resanction__c = false
        );
        insert opp;
        Integration_Details__c intDet = new Integration_Details__c(
            Name = 'Dummy Integration Setting',
            Endpoint__c = 'Callout:CalculateGST',
            Object_Name__c = 'Opportunity',
            Method_type__c = 'POST'
        );
        insert intDet;
        
        Technical_Evaluation__c t = new Technical_Evaluation__c(
            HL_Stage__c = '',
            HL_Is_Final_Valuation__c = true,
            HL_Loan_Application__c = opp.id
        );
        insert t;
        
        Collateral__c col = new Collateral__c(
            Address_Line_1__c = 'Test Street',
            IsActive__c = true,
            APF__c = 'Yes'
        );
        insert col;
        
        Application_Collateral__c appCol = new Application_Collateral__c(
            HL_Loan_Application__c = opp.Id,
            Collateral__c = col.Id
        );
        insert appCol;
        
        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual',
            Loan_Application__c = opp.Id
        );
        insert applicant;
        
        User adminUser = [SELECT Id, Profile.Name FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        Account vendor = FITestDataFactory.createAccount('Test Acc for Opp', 'Partner');
      	Application_Verification__c appVer = FITestDataFactory.createAppVerification(opp, vendor, adminUser, applicant);
        Application_Verification__c appVer1 = FITestDataFactory.createAppVerificationFCU(opp, vendor, adminUser, applicant);
        Application_Verification__c appVerification = new Application_Verification__c(
            Loan_Application__c = opp.Id,
            RecordTypeId = Schema.SObjectType.Application_Verification__c.getRecordTypeInfosByName().get('Personal Discussion AHL').getRecordTypeId(),
            Stage__c = 'Draft',
            Vendor__c = vendor.Id,
            Vendor_Admin__c = adminUser.Id,
            Assigned_To_User__c = adminUser.Id,
            Applicant__c = applicant.Id
        );
        insert appVerification;
        Application_Applicant__c applicant1 = new Application_Applicant__c(
            Applicant_Type__c = 'Co Applicant',
            Customer_Type__c = '',
            Loan_Application__c = opp.Id
        );
        insert applicant1;
        
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'POA';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Certificate of Incorporation';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = Null;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        Applicant_Address__c appAdd1 =Testdatafactory.getTestApplicantAddressData(1, applicant.Id, Null, Null, false)[0];
        appAdd1.Address_Type__c = 'Permanent';
        appAdd1.Address_Source__c = 'Passport';
        appAdd1.Document_Details__c  = docDetail.Id ;
        appAdd1.Applicant__c = applicant.id;
        appAdd1.Address_Priority__c = '4';
        insert appAdd1;
        
        Bank_Details__c bd = new Bank_Details__c();
        bd.Application_Applicant__c = applicant.id;
        bd.Account_Holder_Name__c = 'test';
        bd.Is_Consider_for_Eligibility__c = true;
        insert bd;
        
        Bank_Statement_Analysis__c bsaRecord  = FITestDataFactory.getBankstatement (true , bd.Id );
        
        Bank_Statement_Analysis__c txn = new Bank_Statement_Analysis__c(
            Name = 'Txn 1',
            Bank_Details__c = bd.Id,
            Amount__c = 100,
            Parent_Bant_Statement__c = bsaRecord.Id,
            XNS_Date__c = Date.newInstance(2025, 1, 10),
            Salesforce_Category__c = 'Business Credit',
            Source__c = 'Manual',
            Month__c='Sep-21',
            Total_Self_and_Related_Party_Credit__c = 1000,
            Average_Limit_Utilisation__c = 30,
            ABB__c = 15,
            Amount_of_Self_and_Related_Party_Credit__c =1,
            Total_Number_of_Business_Credits__c = 1,
            Total_Amount_of_Business_Credits__c=1,
            Total_Self_and_Related_Party_Debit__c =1,
            Amount_of_Self_and_Related_Party_Debit__c =1,
            Total_Number_of_Business_Debits__c = 1,
            Total_Amount_of_Business_Debits__c =1,
            Cash_Deposit_to_total_Credit__c =1,
            Cash_withdrwal_to_total_Debit__c =1,
            Total_number_of_inward_return__c =1,
            Total_number_of_inward_ECS_return__c =1,Total_number_of_outward_return__c =1,
            O_w_retruns_as_of_total_credits__c =1,
            Total_Amount_of_Intrest_Charged__c =1,
            Total_Number_of_circular_transactions__c =1,
            Total_Amount_of_EMI__c =1,
            Average_EOD_Balance__c =1,
            Sanction_Limit__c =1,
            Count_of_loan_disbursal__c =1,
            Value_of_loan_disbursal__c =1,
            RecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis')
        );
        insert txn; 
        
        // Parent Income Assessment
        Id salariedRT = Utility.getRecordTypeIdByDeveloperName(
            'Income_Assessment__c', 'Salaried_Individual'
        );
        
        Income_Assessment__c parentIA = new Income_Assessment__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            RecordTypeId = salariedRT,
            Net_Salary__c = 50000,
            Add_Less__c='Add'
        );
        insert parentIA;
        
        Income_Assessment__c parentIA1 = new Income_Assessment__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant1.Id,
            RecordTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByName().get('Director Renumeration').getRecordTypeId(),
            Net_Salary__c = 50000,
            Add_Less__c='Add'
        );
        insert parentIA1;
        
        Income_Assessment__c parentIA2 = new Income_Assessment__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant1.Id,
            RecordTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByName().get('Gross Margin').getRecordTypeId(),
            Net_Salary__c = 50000,
            Add_Less__c='Add'
        );
        insert parentIA2;
        
        Income_Assessment__c parentIA3 = new Income_Assessment__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            Parent__c = parentIA2.id,
            RecordTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByName().get('Cash Profit').getRecordTypeId(),
            Net_Salary__c = 50000,
            Add_Less__c='Add'
        );
        insert parentIA3;
        
        Income_Assessment__c childIa = new Income_Assessment__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            Parent__c = parentIA2.id,
            RecordTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByName().get('Salaried Incentive Component').getRecordTypeId(),
            Net_Salary__c = 50000,
            Add_Less__c='Add'
        );
        insert childIa;
        
        Income_Assessment__c childIa1 = new Income_Assessment__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            Parent__c = parentIA2.id,
            RecordTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByName().get('Salaried Yearly Component').getRecordTypeId(),
            Net_Salary__c = 50000,
            Add_Less__c='Add'
        );
        insert childIa1;
        
        Income_Assessment__c childIa2 = new Income_Assessment__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            Parent__c = parentIA2.id,
            RecordTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByName().get('Gross Margin').getRecordTypeId(),
            Net_Salary__c = 50000,
            Add_Less__c='Add'
        );
        insert childIa2;
        
        Income_Assessment__c childIa3 = new Income_Assessment__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            Parent__c = parentIA2.id,
            RecordTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByName().get('Salaried NRI').getRecordTypeId(),
            Net_Salary__c = 50000,
            Add_Less__c='Add'
        );
        insert childIa3;
        
        Income_Assessment__c childIa4 = new Income_Assessment__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            Parent__c = parentIA2.id,
            RecordTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByName().get('Merchant Navy').getRecordTypeId(),
            Net_Salary__c = 50000,
            Add_Less__c='Add'
        );
        insert childIa4;
        
        
        
        
        
        Income_Assessment__c parentIA4 = new Income_Assessment__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            RecordTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByName().get('Sep Multiplier').getRecordTypeId(),
            Net_Salary__c = 50000,
            Add_Less__c='Add'
        );
        insert parentIA4;
        
        Income_Assessment__c parentIA5 = new Income_Assessment__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            RecordTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByName().get('Banking').getRecordTypeId(),
            Net_Salary__c = 50000,
            Add_Less__c='Add'
        );
        insert parentIA5;
        
        Income_Assessment__c parentIA6 = new Income_Assessment__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            RecordTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByName().get('Low LTV Program').getRecordTypeId(),
            Net_Salary__c = 50000,
            Add_Less__c='Add'
        );
        insert parentIA6;
        
        Income_Assessment__c parentIA7 = new Income_Assessment__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            RecordTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByName().get('Rental Income Program').getRecordTypeId(),
            Net_Salary__c = 50000,
            Add_Less__c='Add'
        );
        insert parentIA7;
        
        Income_Assessment__c parentIA8 = new Income_Assessment__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            RecordTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByName().get('Liquid Income Program').getRecordTypeId(),
            Net_Salary__c = 50000,
            Add_Less__c='Add'
        );
        insert parentIA8;
        
        Product2 mainProduct = new Product2();
        mainProduct.Name = 'Flexi Loan';
        mainProduct.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        mainProduct.Loan_Application__c = opp.Id;
        mainProduct.Product_Type__c  = 'Child';
        insert mainProduct;
        Product_Master__c prodM2 = new Product_Master__c(
            Name = 'Sub Product A',
            RecordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Variant').getRecordTypeId()
        );
        insert prodM2;
        Product2 subProduct = new Product2();
        subProduct.Name = 'Flexi Loan 2';
        subProduct.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
        subProduct.Loan_Application__c = opp.Id;
        subProduct.Product_Type__c  = 'Parent';
        subProduct.Product__c = mainProduct.id;
        insert subProduct;
        
        Product2 subProduct5 = new Product2();
        subProduct5.Name = 'Flexi Funds';
        subProduct5.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();
        subProduct5.Loan_Application__c = opp.Id;
        subProduct5.Product_Type__c = 'Child';
        subProduct5.Product__c = subProduct.Id;
        subProduct5.Sanctioned_Loan_Amount__c = 10000;
        insert subProduct5;
        
        Product2 subProduct6 = new Product2();
        subProduct6.Name = 'Hybrid';
        subProduct6.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Variant').getRecordTypeId();
        subProduct6.Loan_Application__c = opp.Id;
        subProduct6.Product_Type__c = 'Child';
        subProduct6.Product__c = subProduct.Id;
        subProduct6.Sanctioned_Loan_Amount__c = 10000;
        subProduct6.Variant__c = subProduct5.id;
        insert subProduct6;
        
        
        Product2 totalTenureProduct = new Product2(
            Name = '12',
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Total Tenure').getRecordTypeId(),
            Loan_Application__c = opp.Id,
            Product_Type__c  = 'Parent',
            Product__c = subProduct.id,
            Variant__c = subProduct5.id,
            Sub_Variant__c = subProduct6.id
        );
        insert totalTenureProduct;
        
        Product2 transactionTypeProduct = new Product2(
            Name = 'Transaction Type',
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Transaction Type').getRecordTypeId(),
            Loan_Application__c = opp.Id,
            Product_Type__c  = 'Parent',
            Product__c = subProduct.id
        );
        insert transactionTypeProduct;
        
        Product2 loanPurposeProduct = new Product2(
            Name = 'Loan Purpose',
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Loan Purpose').getRecordTypeId(),
            Loan_Application__c = opp.Id,
            Product_Type__c  = 'Parent',
            Product__c = subProduct.id
        );
        insert loanPurposeProduct;
        
        Product2 hybridTenureProduct = new Product2(
            Name = '20',
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Hybrid Tenure').getRecordTypeId(),
            Loan_Application__c = opp.Id,
            Product_Type__c  = 'Parent',
            Product__c = subProduct6.id
        );
        insert hybridTenureProduct;
        
        List<PLF_Master__c> plfList= new List<PLF_Master__c>();
        PLF_Master__c master1= new PLF_Master__c(
            Master_Type__c= 'Sub sector',
            Description__c= 'FOOTWEAR',
            FICO_Code__c= 'SBSC2020',
            Sector_Code__c = 'SEP3'
        );
        plfList.add(master1);

        PLF_Master__c master2= new PLF_Master__c(
            Master_Type__c= 'Salutation',
            Description__c= 'CA',
            FICO_Code__c= '17',
            Gender_Code__c = 'M'
        );
        plfList.add(master2);

        PLF_Master__c master3= new PLF_Master__c(
            Master_Type__c= 'Sector',
            Description__c= 'Chartered Accountant',
            FICO_Code__c= 'SEP2'
        );
        plfList.add(master3);

        PLF_Master__c master4= new PLF_Master__c(
            Master_Type__c= 'Industry',
            Description__c= 'Wholesaler',
            FICO_Code__c= 'WHS'
        );
        plfList.add(master4);

        PLF_Master__c master5= new PLF_Master__c(
            Master_Type__c= 'Gender',
            Description__c= 'Male',
            FICO_Code__c= 'M'
        );
        plfList.add(master5);

        PLF_Master__c master6= new PLF_Master__c(
            Master_Type__c= 'Marital Status',
            Description__c= 'Single',
            FICO_Code__c= 'S'
        );
        plfList.add(master6);

        PLF_Master__c master7= new PLF_Master__c(
            Master_Type__c= 'Segment',
            Description__c= 'SEP-CA',
            FICO_Code__c= 'SEG4'
        );
        plfList.add(master7);

        PLF_Master__c master8= new PLF_Master__c(
            Master_Type__c= 'Nationality',
            Description__c= 'Indian',
            FICO_Code__c= 'IN'
        );
        plfList.add(master8);

        PLF_Master__c master9= new PLF_Master__c(
            Master_Type__c= 'Qualification',
            Description__c= 'MBBS',
            FICO_Code__c= 'MBBS'
        );
        plfList.add(master9);

        PLF_Master__c master10= new PLF_Master__c(
            Master_Type__c= 'Caste',
            Description__c= 'General',
            FICO_Code__c= '40'
        );
        plfList.add(master10);

        PLF_Master__c master11= new PLF_Master__c(
            Master_Type__c= 'Religion',
            Description__c= 'Hindu',
            FICO_Code__c= '13'
        );
        plfList.add(master11);

        PLF_Master__c master12= new PLF_Master__c(
            Master_Type__c= 'Residency Status',
            Description__c= 'Resident',
            FICO_Code__c= 'Re'
        );
        plfList.add(master12);

        PLF_Master__c master13= new PLF_Master__c(
            Master_Type__c= 'Address Type',
            Description__c= 'Permanent',
            FICO_Code__c= 'Re'
        );
        plfList.add(master13);
        PLF_Master__c master14= new PLF_Master__c(
            Master_Type__c= 'Customer Type',
            Description__c= 'Permanent',
            FICO_Code__c= 'Re'
        );
        plfList.add(master14);
        PLF_Master__c master15= new PLF_Master__c(
            Master_Type__c= 'Customer Category',
            Description__c= 'Permanent',
            FICO_Code__c= 'Re'
        );
        plfList.add(master15);
        PLF_Master__c master16= new PLF_Master__c(
            Master_Type__c= 'Sub segment',
            Description__c= 'Permanent',
            FICO_Code__c= 'Re'
        );
        plfList.add(master16);
        PLF_Master__c master17= new PLF_Master__c(
            Master_Type__c= 'Customer Profile',
            Description__c= 'Permanent',
            FICO_Code__c= 'Re'
        );
        plfList.add(master17);
        PLF_Master__c master18= new PLF_Master__c(
            Master_Type__c= 'Specialization',
            Description__c= 'Permanent',
            FICO_Code__c= 'Re'
        );
        plfList.add(master18);
        insert plfList;
    }
    
    @IsTest static void testGetConstants() {
        Map<String, String> constMap = HL_EligibilityApiHandler.getConstants();
        System.assertNotEquals(null, constMap, 'Constants map should not be null');
    }
    
    @IsTest static void testValidatePayloadForErrorMessageSam() {
        // 2a – blank loanApplicationId
        intHandler.ProcessReqWrapper blankWrapper = new intHandler.ProcessReqWrapper();
        blankWrapper.loanApplicationId = null;
        List<String> errorsBlank = HL_EligibilityApiHandler.validatePayload(blankWrapper);
        
        intHandler.ProcessReqWrapper invalidWrapper = new intHandler.ProcessReqWrapper();
        invalidWrapper.loanApplicationId = '006000000000001AAA';   // fake Id
        List<String> errorsInvalid = HL_EligibilityApiHandler.validatePayload(invalidWrapper);
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [Select id from product2 where name = 'Flexi Loan' Limit 1];
        intHandler.ProcessReqWrapper validWrapper = new intHandler.ProcessReqWrapper();
        validWrapper.loanApplicationId = opp.Id;
        validWrapper.productName = 'Flexi Loan';
        validWrapper.isIncomeFromSales = false;
        validWrapper.eligibilityType = 'test';
        
        List<String> errorsValid = HL_EligibilityApiHandler.validatePayload(validWrapper);
    }
    
    @IsTest static void createRequestWrapperTest() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String loanId = opp.id ;
        string productType = 'Flexi Loan';
        Boolean isIncomeFromSales = false;
        string userCalValues = '{"grossSalary":"100"}';
        Boolean isFromCalculator = true;
        String val = HL_EligibilityApiHandler.createRequestWrapper( loanId, productType, isIncomeFromSales, userCalValues, isFromCalculator);
        String val1 = HL_EligibilityApiHandler.createRequestWrapper( loanId, productType, isIncomeFromSales, userCalValues, false);
    }
    
    @IsTest static void createRequestWrapperTest2() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String loanId = opp.id ;
        string productType = 'Flexi Loan';
        Boolean isIncomeFromSales = false;
        string userCalValues = '{"grossSalary":"100"}';
        Boolean isFromCalculator = false;
        String val1 = HL_EligibilityApiHandler.createRequestWrapper( loanId, productType, isIncomeFromSales, userCalValues, isFromCalculator);
    }
    
    @IsTest static void testConstructPayload_MalformedJson() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Build a wrapper but corrupt the JSON string
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.loanApplicationId = opp.Id;
        wrapper.collateralJson    = '{ "invalidJson": ';   // deliberately broken
        
        // Expect an AuraHandledException
        try {
            (new HL_EligibilityApiHandler())
            .constructPayload(wrapper, new List<Integration_Details__c>());
        } catch (AuraHandledException ex) {
        }
    }
}