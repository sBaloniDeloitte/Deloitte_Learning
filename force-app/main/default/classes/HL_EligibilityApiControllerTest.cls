@isTest
public class HL_EligibilityApiControllerTest {
    private static String processName = 'Credit Eligibility';
    private static Id primaryProductId;

    @testSetup
    static void setupTestData() {
        TestDataFactory.setupIntegrationSettings('Get Token');
        
        TestDataFactory.setupIntegrationSettings('Loan FICO API');
        
        TestDataFactory.setupTriggerSettings();
        
        // Trigger bypass
        insert new Trigger_Bypass_Setting__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger_Bypass__c = true
        );

        // --- Trigger Settings ---
        TestDataFactory.setupTriggerSettings();
        Account acc = TestDataFactory.createAccountRecord('TestAcc');
        Account branch = new Account(Name='Test Branch', Branch_Code__c ='1001');
        insert branch;

        Opportunity opp = TestDataFactory.getTestOpportunityData(1, false)[0];
        opp.AccountId = acc.Id; 
        opp.Branch_Master__c = branch.id;
        opp.HL_Construction_Stage__c = 'READY PROPERTY';
        opp.StageName = 'Credit Underwriting';
        insert opp; 
        System.debug('Opportunity Inserted: ' + opp);
        
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Product2.getRecordTypeInfosByName();
        Id totalTenureRecordTypeId  = rtMap.get('Total Tenure').getRecordTypeId();
        Id hybridTenureRecordTypeId = rtMap.get('Hybrid Tenure').getRecordTypeId();
        Id schemeRecordTypeId       = rtMap.get('Scheme').getRecordTypeId();
        Id fullEMIRecordTypeId      = rtMap.get('Full EMI').getRecordTypeId();
        Id variantRecordTypeId      = rtMap.get('Variant').getRecordTypeId();
        Id subVariantRecordTypeId      = rtMap.get('Sub Variant').getRecordTypeId();
        Id productRT = rtMap.get('Product').getRecordTypeId();
        Id subProductRT = rtMap.get('Sub Product').getRecordTypeId();
        Id subProductLowerRT;
        if (rtMap.containsKey('Sub product')) {
            subProductLowerRT = rtMap.get('Sub product').getRecordTypeId();
        }

        Product_Master__c prodM2 = new Product_Master__c(
            Name = 'Variant',
            PLF_Loan_Type__c ='FL',
            PLR_Value__c = 80.00,
            RecordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Variant').getRecordTypeId()
        );
        insert prodM2;

        Product2 mainProduct = TestDataFactory.createProductRecord('Home Loan', true);
        mainProduct.Product_Master__c = prodM2.Id;
        mainProduct.recordTypeId = productRT;
        mainProduct.Loan_Application__c = opp.Id;
        insert mainProduct;
        primaryProductId = mainProduct.Id;

        Product2 subProduct = new Product2(
            Name = 'Sub Product',
            isActive = true,
            Loan_Application__c = opp.Id,
            Product__c = mainProduct.Id,
            Product_Type__c = 'Parent',
            RecordTypeId =  subProductRT 
        );
        insert subProduct;

        if (subProductLowerRT != null) {
            Product2 subProductLowerName = new Product2(
                Name = 'Sub product',
                isActive = true,
                Loan_Application__c = opp.Id,
                Product__c = mainProduct.Id,
                Product_Type__c = 'Parent',
                RecordTypeId = subProductLowerRT
            );
            insert subProductLowerName;
        }

        List<Product2> productsToInsert = new List<Product2>{
            new Product2(
                Name = '30',
                isActive = true,
                Loan_Application__c = opp.Id,
                Product__c = subProduct.Id,
                RecordTypeId = hybridTenureRecordTypeId,
                Variant__c = mainProduct.Id,
                Sub_Variant__c = subProduct.Id
            ),
            new Product2(
                Name = 'Scheme Rec',
                isActive = true,
                Loan_Application__c = opp.Id,
                Product__c = subProduct.Id,
                RecordTypeId = schemeRecordTypeId,
                Variant__c = mainProduct.Id,
                Sub_Variant__c = subProduct.Id
            ),
            new Product2(
                Name = 'Hybrid',
                isActive = true,
                Loan_Application__c = opp.Id,
                Product__c = subProduct.Id,
                RecordTypeId = subVariantRecordTypeId,
                EMI_Amount__c = 10000,
                Variant__c = mainProduct.Id,
                Sub_Variant__c = subProduct.Id
            ),
            new Product2(
                Name = 'Full EMI',
                isActive = true,
                Loan_Application__c = opp.Id,
                Product__c = subProduct.Id,
                RecordTypeId = fullEMIRecordTypeId,
                EMI_Amount__c = 10000,
                Variant__c = mainProduct.Id,
                Sub_Variant__c = subProduct.Id
            )
        };

        insert productsToInsert;

        Product2 variant = new Product2(
            Name = 'Flexi Funds',
            isActive = true,
            Loan_Application__c = opp.Id,
            Product__c = subProduct.Id,
            RecordTypeId = variantRecordTypeId,
            EMI_Amount__c = 10000,
            Variant__c = mainProduct.Id,
            Sub_Variant__c = subProduct.Id
        );
        insert variant;
        
        Product2 tottenor = new Product2(
            Name = '260',
            isActive = true,
            Loan_Application__c = opp.Id,
            Product__c = subProduct.Id,
            RecordTypeId = totalTenureRecordTypeId,
            Variant__c = variant.Id,
            Sub_Variant__c = subProduct.Id
        );
        insert tottenor;
        
        City_Master__c city = TestDataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1,city.Id,true)[0];

        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = opp.Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        applicant.Applicant_Type__c = 'Primary Applicant';
        applicant.Income_Method__c = 'Salaried';
        applicant.Customer__c = customer.Id;
        applicant.Customer_Profile__c = 'Salaried Indian';
        applicant.Qualification__c = 'MBBS';
        applicant.Marital_Status__c = 'Married';
        applicant.Cast_Category__c = 'General';
        insert applicant;
        
        Customer_Address__c custAddRecord = new Customer_Address__c();
        custAddRecord.Customer__c = customer.Id;
        insert custAddRecord;
        TestDataFactory.getTestApplicantAddressData(1, applicant.Id, custAddRecord.Id, pinCode.Id, true);
        // Setup Applicant
        
        Integration_Details__c integrationDetail =  fitestdatafactory.createIntegrationDetails(false );
        integrationDetail.Name = processname ;
        integrationDetail.Loan_Application__c = opp.id;
        integrationDetail.Related_Record_Id__c = opp.id ;
        integrationDetail.Endpoint__c = 'test.com';
        integrationDetail.status__c='200';
        integrationDetail.Object_Name__c = 'Opportunity' ;
        
        insert integrationDetail ;

        Map<String, Schema.RecordTypeInfo> rtMap1 = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByName();
        Id salariedIndividualId  = rtMap1.get('Salaried Individual').getRecordTypeId();
        Id salariedAmountDataId  = rtMap1.get('Salaried Amount Data').getRecordTypeId();
        Id salariedIncentiveId  = rtMap1.get('Salaried Incentive Component').getRecordTypeId();
        Id salariedYearlyId  = rtMap1.get('Salaried Yearly Component').getRecordTypeId();

        Income_Assessment__c parent = new Income_Assessment__c(
            Applicant__c = applicant.Id,
            Loan_Application__c = opp.id,
            RecordTypeId = salariedIndividualId,
            Net_Salary__c = 541072,
            Gross_Salary__c = 55000
        );
        insert parent;

        List<Income_Assessment__c> childList = new List<Income_Assessment__c>();

        Income_Assessment__c child = new Income_Assessment__c(
            Applicant__c = applicant.Id,
            Loan_Application__c = opp.id,
            RecordTypeId = salariedIndividualId,
            Parent__c = parent.Id,
            Type_Of_Component__c = 'Basic Salary',
            Add_Less__c = 'Add',
            Average_Amount__c = 15000
        );
        
        childList.add(child);

        Income_Assessment__c childBon1 = new Income_Assessment__c(
            Applicant__c = applicant.Id,
            Loan_Application__c = opp.id,
            RecordTypeId = salariedYearlyId,
            Parent__c = parent.Id,
            Gross_Amount__c = 20000,
            Tax_Slab__c = 10,
            Yearly_Component__c = 'Latest Year Bonus',
            Multiplier__c = 1,
            Net_Amount__c = 15000
        );

        childList.add(childBon1);

        Income_Assessment__c childBon2 = new Income_Assessment__c(
            Applicant__c = applicant.Id,
            Loan_Application__c = opp.id,
            RecordTypeId = salariedYearlyId,
            Parent__c = parent.Id,
            Gross_Amount__c = 20000,
            Tax_Slab__c = 10,
            Yearly_Component__c = 'Previous Year Bonus',
            Multiplier__c = 1,
            Net_Amount__c = 15000
        );

        childList.add(childBon2);

        Income_Assessment__c childIncent = new Income_Assessment__c(
            Applicant__c = applicant.Id,
            Loan_Application__c = opp.id,
            RecordTypeId = salariedIncentiveId,
            Parent__c = parent.Id,
            Gross_Amount__c = 20000,
            Tax_Slab__c = 10,
            Yearly_Component__c = 'Month 1',
            Multiplier__c = 1,
            Net_Amount__c = 15000
        );

        childList.add(childIncent);

        Income_Assessment__c childIncent2 = new Income_Assessment__c(
            Applicant__c = applicant.Id,
            Loan_Application__c = opp.id,
            RecordTypeId = salariedIncentiveId,
            Parent__c = parent.Id,
            Gross_Amount__c = 20000,
            Tax_Slab__c = 10,
            Yearly_Component__c = 'Month 2',
            Multiplier__c = 1,
            Net_Amount__c = 15000
        );

        childList.add(childIncent2);

        insert childList;

        Income_Assessment__c childMonth = new Income_Assessment__c(
            Applicant__c = applicant.Id,
            Loan_Application__c = opp.id,
            RecordTypeId = salariedAmountDataId,
            Parent__c = child.Id,
            Monthly_Salary__c = 20000,
            Salaried_Name__c = 'Jan'
        );
        insert childMonth;

        Bank_Branch_Master__c bankBranchMasterObj = FITestDataFactory.createBankMasterDetails();
        Bank_Details__c bankDetails = FITestDataFactory.createBankDetails(applicant,bankBranchMasterObj);

        PLF_Master__c plf = new PLF_Master__c(
            Master_Type__c = 'Customer Category',
            FICO_Code__c = 'AEFPS',
            Description__c = 'Individual'
        );
        insert plf;
        
        PLF_Master__c plf2 = new PLF_Master__c(
            Master_Type__c = 'PLR Master',
            FICO_Code__c = 'GHFPLR',
            Description__c = 'GHFPLR'
            
        );
        insert plf2;

        Id obligationRecordTypeId = Schema.SObjectType.Income_Expense_Obligation__c.getRecordTypeInfosByName().get('Income Expense & Obligation').getRecordTypeId();
		Income_Expense_Obligation__c testObli = new Income_Expense_Obligation__c();
        testObli.RecordTypeId = obligationRecordTypeId;
        testObli.Type__c = 'Obligation';
        testObli.Imputed_EMI__c = 2500;
        testObli.Is_Considered_Obligation__c = true;
        testObli.Loan_Application__c = opp.id;
        insert testObli;

        // Insert existing Application_Deviation__c records for deviation processing coverage
        Application_Deviation__c devPending = new Application_Deviation__c(
            Loan_Application__c = opp.Id,
            Deviation_Category__c = 'Automatic',
            Approval_Status__c = 'Pending',
            Deviation_Code__c = 'FICO_EXISTING_PENDING',
            HL_Product__c = mainProduct.Id
        );
        Application_Deviation__c devApproved = new Application_Deviation__c(
            Loan_Application__c = opp.Id,
            Deviation_Category__c = 'Automatic',
            Approval_Status__c = 'Approved',
            Deviation_Code__c = 'FICO_EXISTING_APPROVED',
            HL_Product__c = mainProduct.Id
        );
        insert new List<Application_Deviation__c>{devPending, devApproved};

        // --- Collateral records required by HL_EligibilityApiHandler.validatePayload() ---
        Application_Collateral__c appCollateral;
        String collateralRemarks = 'Automation collateral remarks';
        List<Application_Collateral__c> existingAppCollaterals = [
            SELECT Id, Collateral__c
            FROM Application_Collateral__c
            WHERE HL_Loan_Application__c = :opp.Id
            LIMIT 1
        ];

        if (!existingAppCollaterals.isEmpty()) {
            appCollateral = existingAppCollaterals[0];
            Collateral__c collateralUpdate = new Collateral__c(
                Id = appCollateral.Collateral__c,
                Collateral_Type__c = 'RESIDENTIAL',
                Current_Usage__c = 'SELF OCCUPIED',
                Market_Value__c = 5000000,
                Total_Property_Cost_Sum_of_all__c = 5000000,
                Remarks__c = collateralRemarks
            );
            update collateralUpdate;

            appCollateral.Total_Valuation__c = 5000000;
            update appCollateral;
        } else {
            Collateral__c collateral = new Collateral__c(
                Collateral_Type__c = 'RESIDENTIAL',
                Current_Usage__c = 'SELF OCCUPIED',
                Market_Value__c = 5000000,
                Total_Property_Cost_Sum_of_all__c = 5000000,
                Remarks__c = collateralRemarks
            );
            insert collateral;

            appCollateral = new Application_Collateral__c(
                HL_Loan_Application__c = opp.Id,
                Collateral__c = collateral.Id,
                Total_Valuation__c = 5000000
            );
            insert appCollateral;
        }

        Id vendorAgencyId;
        // Attempt to reuse any existing vendor agency record before creating a new one.
        for (String vendorObjectName : new List<String>{'Vendor_Agency__c', 'HL_Vendor_Agency__c'}) {
            try {
                List<SObject> existingVendors = Database.query('SELECT Id FROM ' + vendorObjectName + ' LIMIT 1');
                if (!existingVendors.isEmpty()) {
                    vendorAgencyId = (Id) existingVendors[0].get('Id');
                    break;
                }
            } catch (Exception ignore) {
                // Ignore lookup failures and fall back to creating a vendor record dynamically.
            }

            Schema.SObjectType vendorType = Schema.getGlobalDescribe().get(vendorObjectName);
            if (vendorType != null) {
                SObject vendorAgency = vendorType.newSObject();
                vendorAgency.put('Name', 'Test Vendor');
                insert vendorAgency;
                vendorAgencyId = (Id) vendorAgency.get('Id');
                break;
            }
        }

        // Technical Evaluation record to satisfy "Technical valuation not found" validation
        Technical_Evaluation__c techEval = new Technical_Evaluation__c(
            HL_Application_Collateral__c = appCollateral.Id,
            HL_Loan_Application__c = opp.Id,
            HL_Technical_Type__c = 'Internal',
            HL_Is_Final_Valuation__c = true
        );
        if (vendorAgencyId != null) {
            techEval.HL_Vendor_Agency__c = vendorAgencyId;
        }
        insert techEval;
    }

    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            string mainCust = [SELECT Customer__r.SF_Customer_ID__c FROM Application_Applicant__c WHERE Customer__r.SF_Customer_ID__c != null LIMIT 1].Customer__r.SF_Customer_ID__c;
            String numericCustomerId = mainCust.replaceAll('\\D', '');
            String finalCustomerId = String.valueOf(Integer.valueOf(numericCustomerId));

            res.setBody('{"data": "<response><systemDecisionDateTime>2025-10-28T20:08:08.117+05:30</systemDecisionDateTime><systemDecisionDate></systemDecisionDate><systemDecision>DEVIATION</systemDecision><strategyUsed></strategyUsed><scoreDecision></scoreDecision><responseDeviations><ruleName></ruleName><ruleLevel></ruleLevel><ruleId></ruleId><ruleDescription></ruleDescription><ruleCategory></ruleCategory><ruleAction></ruleAction><recommendationText></recommendationText><reasonText></reasonText><entityType></entityType><entityId></entityId><deviationType></deviationType><approvalLevel></approvalLevel><accountNo></accountNo></responseDeviations><finalApprovalLevel></finalApprovalLevel><errorResponse><errorType></errorType><errorText></errorText><errorName></errorName><errorId></errorId><errorCode></errorCode><errorAction></errorAction></errorResponse><calculatedVariables><purpose></purpose><productCode></productCode><fieldValue>true</fieldValue><fieldType></fieldType><fieldName>QuickSanction</fieldName><entityType></entityType><entityId></entityId></calculatedVariables><errorResponse><errorType>CONDMAND </errorType><errorId>ERRORIJ1_1826</errorId><errorName>ERRORIJ1_1826</errorName><errorAction></errorAction><errorCode>SOFT</errorCode><errorText>Sub Sector is Mandatory</errorText></errorResponse><errorResponse><errorType>CONDMAND </errorType><errorId>ERRORIJ1_1833</errorId><errorName>ERRORIJ1_1833</errorName><errorAction></errorAction><errorCode>SOFT</errorCode><errorText>Sub Sector is Mandatory</errorText></errorResponse><calculatedVariables><fieldName>noncc30PlusDpdInL9M_</fieldName><fieldType>integer</fieldType><productCode>Bureau</productCode><entityId>HL</entityId><entityType>1826</entityType><purpose>HL</purpose><fieldValue>0,PASS</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOfEnqInL3MHL</fieldName><fieldType>integer</fieldType><productCode>Bureau</productCode><entityId>HL</entityId><entityType>1826</entityType><purpose>HL</purpose><fieldValue>0,PASS</fieldValue></calculatedVariables><calculatedVariables><fieldName>noncc30PlusDpdInL9M_</fieldName><fieldType>integer</fieldType><productCode>Bureau</productCode><entityId>HL</entityId><entityType>1833</entityType><purpose>HL</purpose><fieldValue>0,PASS</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOfEnqInL3MHL</fieldName><fieldType>integer</fieldType><productCode>Bureau</productCode><entityId>HL</entityId><entityType>1833</entityType><purpose>HL</purpose><fieldValue>0,PASS</fieldValue></calculatedVariables><calculatedVariables><fieldName>C_SEGMENT</fieldName><fieldType>String</fieldType><productCode>HL</productCode><entityId>1826</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>NA</fieldValue></calculatedVariables><calculatedVariables><fieldName>C_SEGMENT</fieldName><fieldType>String</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>NA</fieldValue></calculatedVariables><errorResponse><errorType>CONDMAND </errorType><errorId>ERROBJ166</errorId><errorName>ERROBJ166</errorName><errorAction></errorAction><errorCode>SOFT</errorCode><errorText>Collateral Usage is empty</errorText></errorResponse><calculatedVariables><fieldName>CIBIL_Score</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>670.0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOfUnsecuredEnqInL3mExceptCC</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>maxHighCreSanctionAmt</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>446850.0</fieldValue></calculatedVariables><calculatedVariables><fieldName>creditCardUtilization</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>0.0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOf90PlusAccDpdInL12MUnSecLoan</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOf30PlusAccDpdInL6MUnSecLoan</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOf90PlusAccDpdInL12M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOf30PlusAccDpdInL6M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOfUnsecuredInLast3M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>7</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOfNonCcAccOverDueM5000</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOf30PlusAccDpdInL12M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOfAccWoffSettL36M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOfAcc1PlusDpd</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>isUnsecuredInLast6M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>7</fieldValue></calculatedVariables><calculatedVariables><fieldName>isUnsecuredInLast12M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>7</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOfLiveLoans</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>7</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOfNonCCAccSMAL12M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOfNonCCAccSMAL24M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>countTradeLinesInL36M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>Policy_Qualification</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1826</entityType><purpose>All</purpose><fieldValue>Not Eligible</fieldValue></calculatedVariables><calculatedVariables><fieldName>CIBIL_Score</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>670.0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOfUnsecuredEnqInL3mExceptCC</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>maxHighCreSanctionAmt</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>446850.0</fieldValue></calculatedVariables><calculatedVariables><fieldName>creditCardUtilization</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>0.0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOf90PlusAccDpdInL12MUnSecLoan</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOf30PlusAccDpdInL6MUnSecLoan</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOf90PlusAccDpdInL12M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOf30PlusAccDpdInL6M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOfUnsecuredInLast3M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>7</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOfNonCcAccOverDueM5000</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOf30PlusAccDpdInL12M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOfAccWoffSettL36M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOfAcc1PlusDpd</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>isUnsecuredInLast6M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>7</fieldValue></calculatedVariables><calculatedVariables><fieldName>isUnsecuredInLast12M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>7</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOfLiveLoans</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>7</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOfNonCCAccSMAL12M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>noOfNonCCAccSMAL24M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>countTradeLinesInL36M</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>Policy_Qualification</fieldName><fieldType>real</fieldType><productCode>Bureau</productCode><entityId>All</entityId><entityType>1833</entityType><purpose>All</purpose><fieldValue>Not Eligible</fieldValue></calculatedVariables><calculatedVariables><fieldName>negativeSubSec</fieldName><fieldType>integer</fieldType><productCode>Bureau</productCode><entityId>BL</entityId><entityType></entityType><purpose>BL</purpose><fieldValue>NA,pass</fieldValue></calculatedVariables><calculatedVariables><fieldName>HL_SEGMENTATION</fieldName><fieldType>STRING</fieldType><productCode>HL</productCode><entityId>HL</entityId><entityType>Application</entityType><purpose>HL</purpose><fieldValue>High Yield</fieldValue></calculatedVariables><calculatedVariables><fieldName>maxDPD24Months_NonCC</fieldName><fieldType>STRING</fieldType><productCode>HL</productCode><entityId>HL</entityId><entityType>Application</entityType><purpose>HL</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>maxDPD6Months_NonCC</fieldName><fieldType>STRING</fieldType><productCode>HL</productCode><entityId>HL</entityId><entityType>Application</entityType><purpose>HL</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>maxDPD12Months_NonCC</fieldName><fieldType>STRING</fieldType><productCode>HL</productCode><entityId>HL</entityId><entityType>Application</entityType><purpose>HL</purpose><fieldValue>0</fieldValue></calculatedVariables><calculatedVariables><fieldName>totalNonCCOverdueAmt</fieldName><fieldType>STRING</fieldType><productCode>HL</productCode><entityId>HL</entityId><entityType>Application</entityType><purpose>HL</purpose><fieldValue>0.0</fieldValue></calculatedVariables><calculatedVariables><fieldName>Branchwise</fieldName><fieldType>STRING</fieldType><productCode>HL</productCode><entityId>HL</entityId><entityType>Application</entityType><purpose>HL</purpose><fieldValue>true</fieldValue></calculatedVariables><calculatedVariables><fieldName>Is_nonDerog</fieldName><fieldType>STRING</fieldType><productCode>HL</productCode><entityId>HL</entityId><entityType>Application</entityType><purpose>HL</purpose><fieldValue>false</fieldValue></calculatedVariables><calculatedVariables><fieldName>NetAnnualSalaryApplicant</fieldName><fieldType>STRING</fieldType><productCode>HL</productCode><entityId>HL</entityId><entityType>Application</entityType><purpose>HL</purpose><fieldValue>300000.0</fieldValue></calculatedVariables><calculatedVariables><fieldName>Applicant_Age</fieldName><fieldType>STRING</fieldType><productCode>HL</productCode><entityId>HL</entityId><entityType>Application</entityType><purpose>HL</purpose><fieldValue>59.0</fieldValue></calculatedVariables><responseDeviations><ruleId>FICO_HAA_CP19_LP</ruleId><ruleName>FICO_HAA_CP19_LP</ruleName><ruleDescription>Age on loan maturity considered upto 63/70 yrs for Salaried/Self-Employed borrowers</ruleDescription><ruleAction>DEVIATION</ruleAction><ruleCategory>Client Profile</ruleCategory><reasonText>Age on loan maturity considered upto 63/70 yrs for Salaried/Self-Employed borrowers</reasonText><approvalLevel>L1,HL_CREDIT</approvalLevel><deviationType>Higher authority approval</deviationType><ruleLevel></ruleLevel><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><accountNo></accountNo><recommendationText></recommendationText></responseDeviations><responseDeviations><ruleId>FICO_DEV_B4</ruleId><ruleName>FICO_DEV_B4</ruleName><ruleDescription>Credit Bureau – CIBIL Score less than 675</ruleDescription><ruleAction>DEVIATION</ruleAction><ruleCategory>Bureau</ruleCategory><reasonText>Credit Bureau – CIBIL Score less than 675</reasonText><approvalLevel>L6,HL_CREDIT</approvalLevel><deviationType>Higher authority approval</deviationType><ruleLevel></ruleLevel><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><accountNo></accountNo><recommendationText></recommendationText></responseDeviations><responseDeviations><ruleId>FICO_HAA_CP27</ruleId><ruleName>FICO_HAA_CP27</ruleName><ruleDescription>Age on loan maturity considered above 70yrs / 65yrs for Self-Employed &amp; Salaried respectively</ruleDescription><ruleAction>DEVIATION</ruleAction><ruleCategory>Client Profile</ruleCategory><reasonText>Age on loan maturity considered above 70yrs / 65yrs for Self-Employed &amp; Salaried respectively</reasonText><approvalLevel>L1,HL_CREDIT</approvalLevel><deviationType>Higher authority approval</deviationType><ruleLevel></ruleLevel><entityId>1833</entityId><entityType>CoApp</entityType><accountNo></accountNo><recommendationText></recommendationText></responseDeviations><responseDeviations><ruleId>FICO_DEV_B4</ruleId><ruleName>FICO_DEV_B4</ruleName><ruleDescription>Credit Bureau – CIBIL Score less than 675</ruleDescription><ruleAction>DEVIATION</ruleAction><ruleCategory>Bureau</ruleCategory><reasonText>Credit Bureau – CIBIL Score less than 675</reasonText><approvalLevel>L6,HL_CREDIT</approvalLevel><deviationType>Higher authority approval</deviationType><ruleLevel></ruleLevel><entityId>1833</entityId><entityType>CoApp</entityType><accountNo></accountNo><recommendationText></recommendationText></responseDeviations><calculatedVariables><fieldName>RISKCATEGORIZATION</fieldName><fieldType>String</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>NA</fieldValue></calculatedVariables><calculatedVariables><fieldName>RISKCATEGORIZATION</fieldName><fieldType>String</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>NA</fieldValue></calculatedVariables><calculatedVariables><fieldName>MAXFOIRSEP</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>-1</fieldValue></calculatedVariables><calculatedVariables><fieldName>MAXABBEMIRATIOALWD</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>-1</fieldValue></calculatedVariables><calculatedVariables><fieldName>GROWPER</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>-1</fieldValue></calculatedVariables><calculatedVariables><fieldName>GROWANNRC</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>-1</fieldValue></calculatedVariables><calculatedVariables><fieldName>INCMG</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>-1</fieldValue></calculatedVariables><calculatedVariables><fieldName>CASHPROFLAST</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>-1</fieldValue></calculatedVariables><calculatedVariables><fieldName>CASHPROFPREV</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>-1</fieldValue></calculatedVariables><calculatedVariables><fieldName>TURNGROPER</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>-1</fieldValue></calculatedVariables><calculatedVariables><fieldName>GRPRGRPER</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>-1</fieldValue></calculatedVariables><calculatedVariables><fieldName>CASFPRGPER</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>-1</fieldValue></calculatedVariables><calculatedVariables><fieldName>SCORE_SEGMENTATION</fieldName><fieldType>String</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>Below Cut-Off</fieldValue></calculatedVariables><calculatedVariables><fieldName>MAXFOIRSENP</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>-1</fieldValue></calculatedVariables><calculatedVariables><fieldName>MAXFOIRSAL</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>55.00</fieldValue></calculatedVariables><calculatedVariables><fieldName>percentageOfDelqAcc</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>0.00</fieldValue></calculatedVariables><calculatedVariables><fieldName>C_QUALIFICATION</fieldName><fieldType>String</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>GD</fieldValue></calculatedVariables><calculatedVariables><fieldName>C_EMPLOYMENTTYPE</fieldName><fieldType>String</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>SALARIED</fieldValue></calculatedVariables><calculatedVariables><fieldName>C_SECTOR</fieldName><fieldType>String</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>SAL4</fieldValue></calculatedVariables><calculatedVariables><fieldName>C_SUBSECTOR</fieldName><fieldType>String</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>NA</fieldValue></calculatedVariables><calculatedVariables><fieldName>C_NATUREOFBUSINESS</fieldName><fieldType>String</fieldType><productCode>HL</productCode><entityId>'+finalCustomerId+'</entityId><entityType>MainApp</entityType><purpose>AutoPopulate</purpose><fieldValue>NA</fieldValue></calculatedVariables><calculatedVariables><fieldName>MAXFOIRSEP</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>80.00</fieldValue></calculatedVariables><calculatedVariables><fieldName>MAXABBEMIRATIOALWD</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>-1</fieldValue></calculatedVariables><calculatedVariables><fieldName>GROWPER</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>0.00</fieldValue></calculatedVariables><calculatedVariables><fieldName>GROWANNRC</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>0.00</fieldValue></calculatedVariables><calculatedVariables><fieldName>INCMG</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>1.5</fieldValue></calculatedVariables><calculatedVariables><fieldName>CASHPROFLAST</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>-1</fieldValue></calculatedVariables><calculatedVariables><fieldName>CASHPROFPREV</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>-1</fieldValue></calculatedVariables><calculatedVariables><fieldName>TURNGROPER</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>-1</fieldValue></calculatedVariables><calculatedVariables><fieldName>GRPRGRPER</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>-1</fieldValue></calculatedVariables><calculatedVariables><fieldName>CASFPRGPER</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>-1</fieldValue></calculatedVariables><calculatedVariables><fieldName>SCORE_SEGMENTATION</fieldName><fieldType>String</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>-</fieldValue></calculatedVariables><calculatedVariables><fieldName>MAXFOIRSENP</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>-1</fieldValue></calculatedVariables><calculatedVariables><fieldName>MAXFOIRSAL</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>55.00</fieldValue></calculatedVariables><calculatedVariables><fieldName>percentageOfDelqAcc</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>0.00</fieldValue></calculatedVariables><calculatedVariables><fieldName>C_QUALIFICATION</fieldName><fieldType>String</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>MBBS</fieldValue></calculatedVariables><calculatedVariables><fieldName>C_EMPLOYMENTTYPE</fieldName><fieldType>String</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>SEP</fieldValue></calculatedVariables><calculatedVariables><fieldName>C_SECTOR</fieldName><fieldType>String</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>SEP1</fieldValue></calculatedVariables><calculatedVariables><fieldName>C_SUBSECTOR</fieldName><fieldType>String</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>NA</fieldValue></calculatedVariables><calculatedVariables><fieldName>C_NATUREOFBUSINESS</fieldName><fieldType>String</fieldType><productCode>HL</productCode><entityId>1833</entityId><entityType>CoApp</entityType><purpose>AutoPopulate</purpose><fieldValue>NA</fieldValue></calculatedVariables><calculatedVariables><fieldName>C_LOANAMOUNT</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>LA-000000891</entityId><entityType>Application</entityType><purpose>AutoPopulate</purpose><fieldValue>197534.89</fieldValue></calculatedVariables><calculatedVariables><fieldName>C_FIRSTDISBAMOUNT</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>LA-000000891</entityId><entityType>Application</entityType><purpose>AutoPopulate</purpose><fieldValue>0.00</fieldValue></calculatedVariables><calculatedVariables><fieldName>C_BASERATE</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>LA-000000891</entityId><entityType>Application</entityType><purpose>AutoPopulate</purpose><fieldValue>15.00</fieldValue></calculatedVariables><calculatedVariables><fieldName>C_NUMBEROFINSTALLMENTS</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>LA-000000891</entityId><entityType>Application</entityType><purpose>AutoPopulate</purpose><fieldValue>12.00</fieldValue></calculatedVariables><calculatedVariables><fieldName>INCOMEMETHOD</fieldName><fieldType>String</fieldType><productCode>HL</productCode><entityId>LA-000000891</entityId><entityType>Application</entityType><purpose>AutoPopulate</purpose><fieldValue>NA</fieldValue></calculatedVariables><calculatedVariables><fieldName>BANKINGSURROGATE</fieldName><fieldType>String</fieldType><productCode>HL</productCode><entityId>LA-000000891</entityId><entityType>Application</entityType><purpose>AutoPopulate</purpose><fieldValue>NA</fieldValue></calculatedVariables><calculatedVariables><fieldName>GSTPROGRAM</fieldName><fieldType>String</fieldType><productCode>HL</productCode><entityId>LA-000000891</entityId><entityType>Application</entityType><purpose>AutoPopulate</purpose><fieldValue>NA</fieldValue></calculatedVariables><calculatedVariables><fieldName>LOANAMTOFFR</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>LA-000000891</entityId><entityType>Application</entityType><purpose>AutoPopulate</purpose><fieldValue>197534.89</fieldValue></calculatedVariables><calculatedVariables><fieldName>ROINTR</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>LA-000000891</entityId><entityType>Application</entityType><purpose>AutoPopulate</purpose><fieldValue>15.00</fieldValue></calculatedVariables><calculatedVariables><fieldName>LOANTENU</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>LA-000000891</entityId><entityType>Application</entityType><purpose>AutoPopulate</purpose><fieldValue>12.00</fieldValue></calculatedVariables><calculatedVariables><fieldName>MAXLOELIGINC</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>LA-000000891</entityId><entityType>Application</entityType><purpose>AutoPopulate</purpose><fieldValue>197534.89</fieldValue></calculatedVariables><calculatedVariables><fieldName>MAXLOELIGLTV</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>LA-000000891</entityId><entityType>Application</entityType><purpose>AutoPopulate</purpose><fieldValue>20000000.00</fieldValue></calculatedVariables><calculatedVariables><fieldName>MAXLTV</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>LA-000000891</entityId><entityType>Application</entityType><purpose>AutoPopulate</purpose><fieldValue>100.00</fieldValue></calculatedVariables><calculatedVariables><fieldName>EMIFINOFF</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>LA-000000891</entityId><entityType>Application</entityType><purpose>AutoPopulate</purpose><fieldValue>17829.16</fieldValue></calculatedVariables><calculatedVariables><fieldName>FINAL_FOIR</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>LA-000000891</entityId><entityType>Application</entityType><purpose>AutoPopulate</purpose><fieldValue>55.0</fieldValue></calculatedVariables><calculatedVariables><fieldName>FINAL_LTV</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>LA-000000891</entityId><entityType>Application</entityType><purpose>AutoPopulate</purpose><fieldValue>0.99</fieldValue></calculatedVariables><calculatedVariables><fieldName>FORECLOSURECHARGES</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>LA-000000891</entityId><entityType>Application</entityType><purpose>AutoPopulate</purpose><fieldValue>4%</fieldValue></calculatedVariables><calculatedVariables><fieldName>GCNUM</fieldName><fieldType>Double</fieldType><productCode>HL</productCode><entityId>LA-000000891</entityId><entityType>Application</entityType><purpose>AutoPopulate</purpose><fieldValue>GCLA-000000891</fieldValue></calculatedVariables><scoreCardDetails><scoreCardCharacteristics><characteristicName>maxDelinquencyInLife</characteristicName><partialScore>99.0</partialScore><characteristicValue>A. 0 DPD on SEC</characteristicValue></scoreCardCharacteristics><scoreCardCharacteristics><characteristicName>product_holding</characteristicName><partialScore>70.0</partialScore><characteristicValue>TW, CL LE 25K and Others</characteristicValue></scoreCardCharacteristics><scoreCardCharacteristics><characteristicName>currUtilizationOnLiveCCSegment</characteristicName><partialScore>80.0</partialScore><characteristicValue>0.0</characteristicValue></scoreCardCharacteristics><scoreCardCharacteristics><characteristicName>secGeoRiskRanking</characteristicName><partialScore>0.0</partialScore><characteristicValue>Unknown</characteristicValue></scoreCardCharacteristics><scoreCardCharacteristics><characteristicName>noOfAccOpenedInL12m</characteristicName><partialScore>86.0</partialScore><characteristicValue>0</characteristicValue></scoreCardCharacteristics><scoreCardCharacteristics><characteristicName>noOfEnqInL6m</characteristicName><partialScore>84.0</partialScore><characteristicValue>0</characteristicValue></scoreCardCharacteristics><scoreCardCharacteristics><characteristicName>currAvgUtilizationOnAllAccSalSegment</characteristicName><partialScore>78.0</partialScore><characteristicValue>49.65031306187102</characteristicValue></scoreCardCharacteristics><scoreCardCharacteristics><characteristicName>maxMOBonSecInYears</characteristicName><partialScore>77.0</partialScore><characteristicValue>3.0833333333333335</characteristicValue></scoreCardCharacteristics><scorecardName>Sal_Segment_Experian_Score_Card_Instance_Below Cut-Off</scorecardName><scorecardScore>574.0</scorecardScore><characteristicCount>8</characteristicCount><scorecardKey>experianScore</scorecardKey><purpose>AutoPopulate</purpose><entityType>MainApp</entityType><entityId>'+finalCustomerId+'</entityId></scoreCardDetails><scoreCardDetails><scoreCardCharacteristics><characteristicName>ranking1</characteristicName><partialScore>64.0</partialScore><characteristicValue>4</characteristicValue></scoreCardCharacteristics><scoreCardCharacteristics><characteristicName>worstProductHolding</characteristicName><partialScore>66.0</partialScore><characteristicValue>1. TW,2. GL , 4. STPL , 9. Others</characteristicValue></scoreCardCharacteristics><scoreCardCharacteristics><characteristicName>currAvgUtilizationOnAllAccSESegment</characteristicName><partialScore>67.0</partialScore><characteristicValue>49.65031306187102</characteristicValue></scoreCardCharacteristics><scoreCardCharacteristics><characteristicName>maxDpdInL12mScore</characteristicName><partialScore>80.0</partialScore><characteristicValue>3</characteristicValue></scoreCardCharacteristics><scoreCardCharacteristics><characteristicName>mobScore</characteristicName><partialScore>70.0</partialScore><characteristicValue>3</characteristicValue></scoreCardCharacteristics><scoreCardCharacteristics><characteristicName>accOpenedScore</characteristicName><partialScore>76.0</partialScore><characteristicValue>3</characteristicValue></scoreCardCharacteristics><scoreCardCharacteristics><characteristicName>noOfEnqInL6m</characteristicName><partialScore>78.0</partialScore><characteristicValue>0</characteristicValue></scoreCardCharacteristics><scoreCardCharacteristics><characteristicName>percentageOfDelqAcc</characteristicName><partialScore>33.0</partialScore><characteristicValue>0.0</characteristicValue></scoreCardCharacteristics><scoreCardCharacteristics><characteristicName>currUtilizationOnLiveRegUnSecAccSegment</characteristicName><partialScore>78.0</partialScore><characteristicValue>32.52534669618925</characteristicValue></scoreCardCharacteristics><scorecardName>Self_employed_Segment_Experian_Score_Card_Instance_Market Plus</scorecardName><scorecardScore>612.0</scorecardScore><characteristicCount>9</characteristicCount><scorecardKey>experianScore</scorecardKey><purpose>AutoPopulate</purpose><entityType>CoApp</entityType><entityId>1833</entityId></scoreCardDetails><scoreCardDetails><scoreCardCharacteristics><characteristicName>Employment Status</characteristicName><partialScore>0.0</partialScore><characteristicValue>Unknown</characteristicValue></scoreCardCharacteristics><scoreCardCharacteristics><characteristicName>Age</characteristicName><partialScore>1.5</partialScore><characteristicValue>59.0</characteristicValue></scoreCardCharacteristics><scoreCardCharacteristics><characteristicName>citySalary</characteristicName><partialScore>0.0</partialScore><characteristicValue>Unknown</characteristicValue></scoreCardCharacteristics><scoreCardCharacteristics><characteristicName>Bureau Score</characteristicName><partialScore>0.0</partialScore><characteristicValue>670.0</characteristicValue></scoreCardCharacteristics><scoreCardCharacteristics><characteristicName>bureauDelinquencyCategory</characteristicName><partialScore>15.0</partialScore><characteristicValue>DELINQUENCY CAT 1</characteristicValue></scoreCardCharacteristics><scorecardName>Salaried_Risk_Score_Card_Instance_Below Cut-Off</scorecardName><scorecardScore>16.5</scorecardScore><characteristicCount>5</characteristicCount><scorecardKey>appScore</scorecardKey><purpose>AutoPopulate</purpose><entityType>MainApp</entityType><entityId>'+finalCustomerId+'</entityId></scoreCardDetails></response><finalOffer><ROINTR>15.0</ROINTR><MAXLTV>100.0</MAXLTV><MAXLOELIGLTV>2.0E7</MAXLOELIGLTV><MAXLOELIGINC>197534.89959446693</MAXLOELIGINC><LOANTENU>12.0</LOANTENU><LOANAMTOFFR>197534.89959446693</LOANAMTOFFR><FINALLTV>0.9876744979723345</FINALLTV><FINALFOIR>55.000000000000014</FINALFOIR><EMIFINOFF>17829.16666666667</EMIFINOFF><additionalLtv></additionalLtv></finalOffer>"}');
            return res;
        }
    }

    private class FailureMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"message":"Internal Server Error"}');
            return res;
        }
    }

    @isTest
    static void testOtherMethods() {
        Opportunity testLoan = [SELECT Id FROM Opportunity LIMIT 1];
        Id prodId = getPrimaryProductId();
        
        Test.startTest();
        HL_EligibilityApiController.getLoanStatus(testLoan.id);
        HL_EligibilityApiController.fetchPLRValues();
        HL_EligibilityApiController.getScoreCardDetails(testLoan.id);
        HL_EligibilityApiController.updatePLROnProduct(testLoan.Id, 'GHFPLR - 8.5', '5', prodId);
        Test.stopTest();
    }

    @isTest
    static void testMethod1() {
        Opportunity testLoan = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        
        string userCalValues='{"finalLoanAmount" : 10000000,"roi" : 8.75,"tenor" : 260,"additionalFOIR" : 0}';

        Map<String,String> inputMap = new Map<String,String>{
            'loanId' => testLoan.Id,
            'processName' => processname,
            'productName' => 'Home Loan',
            'registrationNumber' => 'REG123456',
            'callForDeviation' => 'true' , 
            'isIncomeFromSales' => 'true',
            'showCalculator' => 'false',
            'userCalValues' => userCalValues
        };
                    
        Test.startTest();

        String result = HL_EligibilityApiController.initiateAPIRequest(inputMap);
        // System.assertNotEquals(null, result, 'Response should not be null for successful callout flow.');
        Test.stopTest();
    }

    @isTest
    static void testMethod2() {
        Opportunity testLoan = [SELECT Id FROM Opportunity LIMIT 1];
        Id prodId = getPrimaryProductId();

        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        
        string userCalValues='{"finalLoanAmount" : 10000000,"roi" : 8.75,"tenor" : 260,"additionalFOIR" : 0}';

        Map<String,String> inputMap = new Map<String,String>{
            'loanId' => testLoan.Id,
            'processName' => processname,
            'productName' => 'Home Loan',
            'registrationNumber' => 'REG123456',
            'callForDeviation' => 'true' , 
            'productId' => prodId,
            'isIncomeFromSales' => 'false',
            'showCalculator' => 'false',
            'userCalValues' => userCalValues
        };
                    
        Test.startTest();

        String result = HL_EligibilityApiController.initiateAPIRequest(inputMap);
        // System.assertNotEquals(null, result, 'Response should not be null for successful callout flow.');
        Test.stopTest();
    }

    private static Id getPrimaryProductId() {
        if (primaryProductId == null) {
            Product2 fallbackProduct = [SELECT Id FROM Product2 WHERE RecordType.Name = 'Product' LIMIT 1];
            primaryProductId = fallbackProduct.Id;
        }
        return primaryProductId;
    }
}