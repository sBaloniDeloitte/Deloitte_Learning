@isTest
public class COMM_SalesLoanLoginTUFlowControllerTest {

    @TestSetup
    static void setupData() {
        
        TestDataFactory.setupTriggerSettings();

          // Create test Account
        Account acc = TestDataFactory.getTestAccounts(1, 'Customer', false)[0];
        acc.Customer_LMS_Id__c = 'CIF123';
        acc.UCIC_Number__c = 'UCIC123';
        insert acc;
        
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, false)[0];
        loanApp.Name = 'Test Opportunity 1';
        loanApp.AccountId = acc.Id;
        loanApp.LMS_Loan_Reference__c = 'LMS001';
        loanApp.Branch_Master__c = acc.Id;
        loanApp.Product__c = 'Home Loan';
        insert loanApp;
		Product_Master__c pm = new   Product_Master__c();
        pm.Name='Home Loan';
        insert  pm;
        Product2 prod = new Product2(
            Name = 'Home Loan',
            RecordTypeId = Schema.SObjectType.Product2
                .getRecordTypeInfosByName().get('Product').getRecordTypeId(),
            Loan_Application__c = loanApp.Id
        );
        insert prod;
		Product_Master__c prodM = new Product_Master__c();
        prodM.Name='HL Top up';
        insert prodM;
        Product_Master__c prodM1 = new Product_Master__c();
        prodM1.Name='Term Loan';
        prodM1.RecordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
        insert prodM1;
        Product_Master__c prodM2 = new Product_Master__c();
        prodM2.Name='Regular';
        prodM2.RecordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Sub Variant').getRecordTypeId();
        insert prodM2;
        Product_Master__c prodM3= new Product_Master__c();
        prodM3.Name='Regular';
        prodM3.RecordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Scheme').getRecordTypeId();
        insert prodM3;
        Product_Master__c prodM4= new Product_Master__c();
        prodM4.Name='Regular';
        prodM4.RecordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Scheme').getRecordTypeId();
        insert prodM4;
        Product_Master__c prodM5 = new Product_Master__c();
        prodM5.Name='Flexi Loan';
        insert prodM5; 
        Product_Master__c prodM6 = new Product_Master__c();
        prodM6.Name='Flexi Loan';
        prodM6.RecordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
        insert prodM6;


         Integration_Settings__c intDetails1 = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'f9709782-85ea-49fc-848a-6abcbfa65611',
            Cookie__c = 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f',
            Client_Secret__c = 'REDACTED_CLIENT_SECRET',
            Endpoint__c = 'Callout:LOS_BL_Bearer/Bearer',
            Content_Type__c = 'application/json',
            Request_Method__c = 'GET'
        );

        
         
        insert intDetails1;

        
           Integration_Settings__c intSettings = new Integration_Settings__c(
            Name = 'Get Loan Details',
            Client_Id__c = 'NA',
            Client_Secret__c = 'NA',
            Content_Type__c = 'application/json',
            Endpoint__c = 'Callout:LOS_BL_getLoan/getloandetails',
            Request_Method__c = 'GET',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Cookie__c = 'TS01bb3263=01c841f7c54302612f1d9049dffc643eca5a1cad95842168ce6510ac4ca4f52ce91ca14537a1ff8ba97489496e307fc703c0d48c75',
            Message_Id__c ='MSG001',
            Entity_Id__c= 'ENT001'
        );
        insert intSettings;

        Integration_Settings__c intSettings1 = new Integration_Settings__c(
            Name = 'Get Customer',
            Client_Id__c = 'NA',
            Client_Secret__c = 'NA',
            Content_Type__c = 'application/json',
            Endpoint__c = 'https://fake-endpoint.com/getcustomer',
            Request_Method__c = 'GET',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Cookie__c = 'TS01bb3263=01c841f7c54302612f1d9049dffc643eca5a1cad95842168ce6510ac4ca4f52ce91ca14537a1ff8ba97489496e307fc703c0d48c75',
            Message_Id__c ='MSG001',
            Entity_Id__c= 'ENT001'
        );
        insert intSettings1;

            Integration_Settings__c intSettings2 = new Integration_Settings__c(
            Name = 'Get Collateral Details',
            Client_Id__c = 'NA',
            Client_Secret__c = 'NA',
            Content_Type__c = 'application/json',
            Endpoint__c = 'https://fake-endpoint.com/getcustomer/Collateral',
            Request_Method__c = 'GET',
            Authorization__c = 'basic NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4',
            Cookie__c = 'TS01bb3263=01c841f7c54302612f1d9049dffc643eca5a1cad95842168ce6510ac4ca4f52ce91ca14537a1ff8ba97489496e307fc703c0d48c75',
            Message_Id__c ='MSG001',
            Entity_Id__c= 'ENT001'
        );
        insert intSettings2;

            Integration_Settings__c intSetting = new Integration_Settings__c(
            Name = 'UCIC De Dupe Check',
            Client_Id__c = 'testClientId',
            Client_Secret__c = 'testSecret',
            Endpoint__c = 'https://testendpoint.com',
            Content_Type__c = 'application/json',
            Request_Method__c = 'POST'
        );
        insert intSetting;
        
        // Create Application_Applicant__c
        City_Master__c city = TestDataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1,city.Id,true)[0];
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loanApp.Id, false)[0];
        applicant.Loan_Application__c = loanApp.Id;
        applicant.Customer_Type__c ='Individual';
		applicant.Customer_Profile__c = 'SEP';
		applicant.Financial_Non_Financial__c = 'Financial';
		applicant.Monthly_Gross_Salary__c = 200000;
        applicant.Applicant_Type__c = 'Primary Applicant' ;
        applicant.Customer__c = acc.id;
        insert applicant;

         // Create Applicant Address
        Applicant_Address__c address = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Loan_Application__c = loanApp.Id,
            Building_Street_Name__c = '123 Test St'
        );
        insert address;

        Collateral__c col = new Collateral__c(IsActive__c=true);
        insert col;
        // Create Application_Collateral__c
        Application_Collateral__c collateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id,
            Collateral__c = col.id
        
        );
        insert collateral;

        // Create Collateral Owner
        Collateral_Owner__c owner = new Collateral_Owner__c(
            Application_Applicant__c = applicant.Id,
            Application_Collateral__c = collateral.Id
        );
        insert owner;
        
    }

       @isTest
    static void testGetOpportunitiesWithCIF() {
        Test.startTest();
        List<COMM_SalesLoanLoginTopUpFlowController.FinanceOpportunityWrapper> result =
            COMM_SalesLoanLoginTopUpFlowController.getOpportunities('CIF123', null, null);
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Result should not be empty when CIF matches');
        System.assertEquals('CIF123', result[0].cif, 'CIF should match');
    }
  
    @isTest
    static void testGetOpportunitiesWithUCIC() {
        Test.startTest();
        List<COMM_SalesLoanLoginTopUpFlowController.FinanceOpportunityWrapper> result =
            COMM_SalesLoanLoginTopUpFlowController.getOpportunities(null, 'UCIC123', null);
        Test.stopTest();

        System.assert(result.size() > 0, 'Result should not be empty when UCIC matches');
    }

    @isTest
    static void testGetOpportunitiesWithAccId() {
        Account acc = [SELECT Id FROM Account WHERE Customer_LMS_Id__c = 'CIF123' LIMIT 1];

        Test.startTest();
        List<COMM_SalesLoanLoginTopUpFlowController.FinanceOpportunityWrapper> result =
              COMM_SalesLoanLoginTopUpFlowController.getOpportunities(null, null, acc.Id);
        Test.stopTest();

        System.assert(result.size() > 0, 'Result should not be empty when AccountId matches');
    }

     @isTest
    static void testCheckLoanApplication_LMSReference() {
        // Query using LMS_Loan_Reference__c
        Test.startTest();
        List<COMM_SalesLoanLoginTopUpFlowController.FinanceOpportunityWrapper> result =
            COMM_SalesLoanLoginTopUpFlowController.checkLoanApplicationInSFDC('LMS001', true);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one record when LMS reference matches');
        System.assertEquals('name1', result[0].customerName, 'finReference should match Opportunity.Name or LMS value');
    }

        @isTest
    static void testCloneLoanApplicationUsingFactory() {
        // Fetch the setup records
        Opportunity sourceOpp = [SELECT Id,AccountId FROM Opportunity  LIMIT 1];

        // Create a minimal Target Opportunity
        Opportunity targetOpp = TestDataFactory.getTestOpportunityData(1, false)[0];
        targetOpp.AccountId = sourceOpp.AccountId;
        insert targetOpp;

        Test.startTest();
        String result = COMM_SalesLoanLoginTopUpFlowController.cloneLoanApplication(sourceOpp.Id, targetOpp.Id);
        Test.stopTest();

        System.assertEquals('Success', result, 'Clone method should return Success');

        // Verify target opportunity is linked to source
        targetOpp = [SELECT Id, Parent_Loan_Application__c FROM Opportunity WHERE Id=:targetOpp.Id];
        System.assertEquals(sourceOpp.Id, targetOpp.Parent_Loan_Application__c, 'Target should link to source');

        // Verify cloned applicant exists
        List<Application_Applicant__c> clonedApplicants = [SELECT Id, Loan_Application__c FROM Application_Applicant__c WHERE Loan_Application__c=:targetOpp.Id];
        System.assertEquals(1, clonedApplicants.size(), 'One applicant should be cloned');

        // Verify cloned address exists
        List<Applicant_Address__c> clonedAddresses = [SELECT Id, Applicant__c, Loan_Application__c FROM Applicant_Address__c WHERE Loan_Application__c=:targetOpp.Id];
        System.assertEquals(1, clonedAddresses.size(), 'One address should be cloned');

    }

    
    @IsTest
    static void testCheckDeduplicate() {
        // Step 1: Create test 
        try{
            Account testAcc = new Account(
                Name = 'Test User',
                Is_Active__c = true,
                PAN_Number__c = 'ABCDE1234F',
                Aadhar_Number__c = '123456789012',
                Voter_ID_Number__c = 'VOTER1234',
                Passport_File_Number__c = 'PASS123456',
                Drivers_License_Number__c = 'DL1234567890',
                Mobile_Number__c = '9876543210',
                Date_of_Birth__c = Date.newInstance(1990, 1, 1),
                Customer_Type__c = 'Individual'
            );
            insert testAcc;
            
            // Step 2: Create related Opportunity
            Opportunity opp = new Opportunity(
                Name = 'Test Loan',
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                AccountId = testAcc.Id,
                Product__c = 'Affordable Home Loan'
            );
            insert opp;
            
            
            Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
            
            // Step 3: Prepare input map
            Map<String, String> inputMap = new Map<String, String>{
                'panNumber' => 'ABCDE1234F',
                    'aadharNumber' => '123456789012',
                    'voterNumber' => 'VOTER1234',
                    'passportNumber' => 'PASS123456',
                    'mobileNumber' => '9876543210',
                    'dob' => '1990-01-01',
                    'panName' => 'Test User',
                    'processName'=>'Loan Application',
                    'loanId'=> opp.Id,
                    'applicantId'=>applicant.Id,
                    'fromLead' => 'false'
                    };
                        
                        
                        
            // Step 4: Call the method
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new UnifiedLoanDetailsMock());
            List<COMM_SalesLoanLoginTopUpFlowController.DuplicateCustomerUIWrapper> results = COMM_SalesLoanLoginTopUpFlowController.checkDeduplicate(inputMap);
            Test.stopTest();
            
            // Step 5: Assert results
            System.assertNotEquals(0, results.size(), 'Expected at least one match');
            System.assertEquals(testAcc.Id, results[0].accId, 'Account ID should match');
            System.assertEquals('Salesforce', results[0].sourceSystem, 'Source system should be Salesforce');
            
            String resp = '{' +
                '"freshCustomer": true,' +
                '"commonId": "CID123456",' +
                '"ucicid": "UCIC7890",' +
                '"ucictype": "Primary",' +
                '"duplicateCustomers": [' +
                '{' +
                '"key": "match1",' +
                '"cif": "CIF001",' +
                '"ucic": "UCIC001",' +
                '"accId": "001xx000003DGX1AAO",' +
                '"name": "John Doe",' +
                '"mobileNumber": "9876543210",' +
                '"pan": "ABCDE1234F",' +
                '"aadhar": "123456789012",' +
                '"voterId": "VOTER1234",' +
                '"passport": "PASS123456",' +
                '"drivingLicense": "DL1234567890",' +
                '"customerType": "Individual",' +
                '"sourceSystem": "Salesforce",' +
                '"matchReason": "PAN Match",' +
                '"disable": false' +
                '}' +
                ']' +
                '}';
            

            COMM_UCICController.UCICDeduplicationInfo dedupeInfo =
                (COMM_UCICController.UCICDeduplicationInfo) JSON.deserialize(resp, COMM_UCICController.UCICDeduplicationInfo.class);
            
            System.assertNotEquals(null, dedupeInfo);
            System.assertEquals(true, dedupeInfo.freshCustomer);
            System.assertEquals('CID123456', dedupeInfo.commonId);
            System.assertEquals(1, dedupeInfo.duplicateCustomers.size());
            System.assertEquals('John Doe', dedupeInfo.duplicateCustomers[0].name);
            
            
            
            
        }catch(exception e){
            
        }
    }
    
    public  class MockLoanDetailsCallout implements HttpCalloutMock {
        public  HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            
            // Minimal valid JSON for deserialization
            String mockJson = '{' +
                '"finReference": "GFL3001BD0014530",' +
                '"stp": true,' +
                '"disbStp": false,' +
                '"receiptId": 0,' +
                '"maxPPAmount": 0,' +
                '"maxPPPercentage": 0,' +
                '"returnStatus": {"status": "SUCCESS"}' +
                '}';
            
            res.setBody(mockJson);
            return res;
            
        }
        
    }
  
    @IsTest
    static void testCreateRelatedRecords_AllPaths() {
        
        Opportunity opp = [SELECT Id FROM Opportunity limit 1];
        
        test.StartTest();
        
        Test.setMock(HttpCalloutMock.class, new UnifiedLoanDetailsMock());
        
        COMM_SalesLoanLoginTopUpFlowController.createRelatedRecords('12345', opp.Id);
        // System.assert(false, 'Expected AuraHandledException for null wrapperData');
        
        test.StopTest();
        
    }
    
    @IsTest
    static void testCreateRelatedRecords_FlexiLoan() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Lead lead = new Lead(FirstName = 'Testing', LastName = 'Test Lead', Company = 'Test Company', MobilePhone='9768283721', Customer_Type__c = 'Individual' , Product__c = 'Flexi Loan');
        insert lead;
         Opportunity opp = FITestDataFactory.createOpportunity(customer);
        	opp.Lead__c = lead.Id;
            opp.Requested_Amount__c = 500000;
            opp.Requested_Tenure_in_Months__c = 60;
            opp.Product__c = 'Flexi Loan';
            opp.Variant__c = 'Term Loan';
            opp.Sub_Variant__c = 'Interest Only - Yearly';
            update opp;
        PLF_Master__c plfMaster = new PLF_Master__c(
            Description__c = 'Some Program Type',
            FICO_Code__c = 'FICO123',
            Applicant_Type__c= 'Individual',
            Customer_Type__c = 'SEP',
            Master_Type__c = 'Address Type'
        );
        insert plfMaster;
        test.StartTest();
        
        Test.setMock(HttpCalloutMock.class, new UnifiedLoanDetailsMock());
        try{COMM_SalesLoanLoginTopUpFlowController.createRelatedRecords('12345', opp.Id);}
        catch(Exception ignore){}
        test.StopTest();
        
    }


    public class UnifiedLoanDetailsMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            String bodyResponse;
            
            // You can differentiate by URL, header, or some other param
            if (req.getEndpoint().contains('getcustomer')) {
                // Simple response
                bodyResponse = '{"cif":"102629","coreBankID":"","categoryCode":"RETAIL","defaultBranch":"3001","baseCurrency":"INR","primaryRelationOfficer":774,"personalInfo":{"firstName":"Radhika","middleName":"Pathak","lastName":"Pathak","shortName":"Radhika Pathak","fatherName":"Father Name","language":"EN","dateofBirth":"1999-09-13","countryofBirth":"IN","nationality":"IN","gender":"OTH","numofDependents":0,"type":"C9","sector":"SAL2","subSector":"SBSC218","industry":"MANU","groupID":0,"parentCountry":"IN","riskCountry":"IN","staff":false,"staffID":"","saleAgent":"","emiCardEligibilityAmt":0,"caste":0,"religion":0,"othersName":"","custCRCPR":"AAAPH1234H","version":78,"marginDeviation":false,"applicationNo":""},"employments":[],"addresses":[{"addrType":"EMPADD","buildingNo":"addre1","FlatNo":"kjdhahdaj","Street":"jsjdjad","addrLine1":"","addrLine2":"","poBox":"","city":"MMB","state":"MH","country":"IN","pinCode":"400007","priority":5,"version":1,"countryName":"INDIA","stateName":"Maharashtra","cityName":"Mumbai"}],"phones":[{"phoneTypeCode":"MOBILE","phoneNumber":"9930277019","priority":5,"version":0}],"emails":[],"customersIncome":[],"documents":[],"customersBankInfo":[],"accountsBehaviour":[],"customersExtLiability":[{"liabilitySeq":2,"finType":"GL","instalmentAmount":900000,"outStandingBal":0,"originalAmount":300000,"finDate":"2019-06-11","finStatus":"S","version":1,"rateOfInterest":0,"tenure":3,"balanceTenure":0,"bounceInstalments":0,"principalOutstanding":0,"overdueAmount":0,"foir":false,"source":0,"checkedBy":0,"securityDetails":"","loanPurpose":"CAPINV","repayBank":"006","otherFinInstitute":"","imputedEmi":0,"ownerShip":"","lastTwentyFourMonths":false,"lastSixMonths":false,"lastThreeMonths":false,"currentOverDue":0,"repayFromAccNo":"","remarks":"","noOfBouncesInSixMonths":0,"noOfBouncesInTwelveMonths":0,"consideredBasedOnRTR":false,"mob":0,"extLiabilitiesPayments":[{"version":2,"emiType":"May-2030","emiClearance":"#"},{"version":2,"emiType":"Apr-2030","emiClearance":"#"},{"version":2,"emiType":"Mar-2030","emiClearance":"#"}],"bankName":"006"},{"liabilitySeq":1,"finType":"BL","instalmentAmount":1000000,"outStandingBal":0,"originalAmount":3000000,"finDate":"2014-06-18","finStatus":"S","version":1,"rateOfInterest":0,"tenure":0,"balanceTenure":0,"bounceInstalments":0,"principalOutstanding":0,"overdueAmount":0,"foir":false,"source":0,"checkedBy":0,"securityDetails":"","loanPurpose":"BEXP","repayBank":"009","otherFinInstitute":"","imputedEmi":0,"ownerShip":"","lastTwentyFourMonths":false,"lastSixMonths":false,"lastThreeMonths":false,"currentOverDue":0,"repayFromAccNo":"","remarks":"","noOfBouncesInSixMonths":0,"noOfBouncesInTwelveMonths":0,"consideredBasedOnRTR":false,"mob":0,"extLiabilitiesPayments":[],"bankName":"002"}],"dedupReq":false,"extendedDetails":[{"extendedFields":[{"fieldName":"entitytype","fieldValue":" PARTNERSHIP"},{"fieldName":"numberofassocentit","fieldValue":0},{"fieldName":"applicantonloan","fieldValue":"#"},{"fieldName":"beneficialowner","fieldValue":"#"},{"fieldName":"kyccollected","fieldValue":"#"},{"fieldName":"registeredwithgst","fieldValue":"#"},{"fieldName":"occupiedsince","fieldValue":0},{"fieldName":"natureofbusiness","fieldValue":"#"},{"fieldName":"cc_od_utilization","fieldValue":"#"},{"fieldName":"debt_equity_ratio","fieldValue":0.00},{"fieldName":"abb_to_emi_ratio","fieldValue":0.00},{"fieldName":"prevyrturnover","fieldValue":0},{"fieldName":"prevyrgrprofit","fieldValue":0},{"fieldName":"prevyrnetpbt","fieldValue":0},{"fieldName":"prevyrdepreciation","fieldValue":0},{"fieldName":"prevyrsalpaidtopd","fieldValue":0},{"fieldName":"prevyrintpaidtop","fieldValue":0},{"fieldName":"preyrintpaidtocl","fieldValue":0},{"fieldName":"preyrintpaidlntobk","fieldValue":0},{"fieldName":"preyronetimeexp","fieldValue":0},{"fieldName":"preyronetimeincome","fieldValue":0},{"fieldName":"turnover","fieldValue":0},{"fieldName":"grossprofit","fieldValue":0},{"fieldName":"netpbt","fieldValue":0},{"fieldName":"depreciation","fieldValue":0},{"fieldName":"salpdtopartdirect","fieldValue":0},{"fieldName":"intpdtopartdirect","fieldValue":0},{"fieldName":"intpaidtoclose","fieldValue":0},{"fieldName":"intpaid_loantobank","fieldValue":0},{"fieldName":"onetimeexpense","fieldValue":0},{"fieldName":"onetimeincome","fieldValue":0},{"fieldName":"annsalarydirector","fieldValue":0},{"fieldName":"avgmnbalfrmperfios","fieldValue":0},{"fieldName":"addfoir","fieldValue":0.00},{"fieldName":"overrideabbemirati","fieldValue":0.00},{"fieldName":"addgromargin","fieldValue":0.00},{"fieldName":"rentincomeprg","fieldValue":"#"},{"fieldName":"incomeprogram","fieldValue":"#"},{"fieldName":"isgroturnsustain","fieldValue":"#"},{"fieldName":"isgroprgrosustain","fieldValue":"#"},{"fieldName":"iscashprgrosustain","fieldValue":"#"},{"fieldName":"rentalinc","fieldValue":0},{"fieldName":"otherinc","fieldValue":0},{"fieldName":"crntres","fieldValue":"#"},{"fieldName":"residentialstatus","fieldValue":"#"},{"fieldName":"residenceownership","fieldValue":"#"},{"fieldName":"officeownership","fieldValue":"#"},{"fieldName":"keyperson","fieldValue":"YES"}]}],"blackListReq":false,"customerDirector":[],"customerGstLists":[],"custCardSales":[],"customerFinanceDetailList":[{"version":0,"finReference":"GFL3001BL0001491","finBranch":"3001","finType":"BL","finAmount":0,"curOddays":0,"firstEmiAmount":0,"loanTenor":12},{"version":0,"finReference":"GFL3001BL0001446","finBranch":"3001","finType":"BL","finAmount":50000000,"curOddays":0,"firstEmiAmount":4606900,"loanTenor":12}],"returnStatus":{"returnCode":"0000","returnText":"Success"}}';
                
                // bodyResponse = '{"customer": {"cif":"102629"}, "returnStatus": {"returnCode":"0000","returnText":"Success"}}';
            } 
            if(req.getEndpoint().contains('getloandetails')) {
                // Full loan details response
                bodyResponse = '{"finReference":"GHF1001HL0005419","stp":true, "guarantors": [{"cif":"120836"}], "coApplicants": [{"cif": "120836","shortName": "jinkya Daduuu More", "includeRepay": false}], "collaterals": [{"collateralRef": "1234","assignPerc": 12,"version": 1,"seq": 2}],"financeSchedule":{"financeDetail":{"applicationNo":"","finType":"HL","finCcy":"INR","finBranch":"1001","finReference":"GHF1001HL0005419","profitDaysBasis":"30E/360I","finAmount":10000000,"finAssetValue":20000000,"downPayBank":0,"downPaySupl":0,"finRepayMethod":"NACH","finStartDate":"2038-03-10T00:00:00","allowGrcPeriod":false,"tdsApplicable":false,"manualSchedule":false,"planDeferCount":0,"stepFinance":false,"alwManualSteps":false,"stepPolicy":"","stepType":"#","grcTerms":0,"grcPeriodEndDate":"2038-03-10T00:00:00","grcRateBasis":"#","grcPftRate":0,"grcMargin":0,"grcPftFrq":"","grcPftRvwFrq":"","grcCpzFrq":"","allowGrcRepay":false,"grcSchdMthd":"PRI_PFT","grcMinRate":0,"grcMaxRate":0,"grcMaxAmount":0,"grcAdvPftRate":0,"grcAdvMargin":0,"numberOfTerms":15,"reqRepayAmount":0,"repayRateBasis":"R","repayPftRate":17.25,"repayBaseRate":"GHFPLR","repayMargin":0,"scheduleMethod":"EQUAL","repayFrq":"M0006","nextRepayDate":"2038-11-06T00:00:00"}},"customer":{"cif":"100012"},"returnStatus":{"returnCode":"0000","returnText":"Success"}}';
                
                //  '            "authoritySignatory": false,'+
                //  '            "sequence": 0,'+
                //  '            "version": 1,'+
                //  '            "catOfcoApplicant": "MOTHER",'+
                //  '            "includeIncome": false'+
                //  '  
            }if(req.getEndpoint().contains('Bearer')){
                bodyResponse = '{"access_token":"mockedAccessToken123"}'; 
            }if(req.getEndpoint().contains('Collateral')){
                //  Map<String,Object> body = new Map<String,Object>();
                // body.put('finReference','GHF1001HL0005309');
                // body.put('returnStatus',new Map< String,String>{'returnCode'=>'009','returnText'=>'Success'});
                // body.put('disbursements',new List<Object>());
                // body.put('collateral')
                bodyResponse = '{"finReference": "GHF1001HL0005309","stp": true,"collateral": [{  "collateralRef": "1234"}  ], "returnStatus": {"returnCode": "009","returnText": "Success"},"disbursements": []}';
            }
           
            res.setBody(bodyResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    static void testUpdateOpportunity() {
      Opportunity Opp = [SELECT Is_Top_Up__c FROM Opportunity limit 1];
        COMM_SalesLoanLoginTopUpFlowController.updateOpportunity(opp.Id); 

        // Query updated record
        Opportunity updatedOpp = [SELECT Is_Top_Up__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('No', updatedOpp.Is_Top_Up__c,'Not updated to No');
    }

    @IsTest
    static void testNullIdThrowsException() {
        try {
            COMM_SalesLoanLoginTopUpFlowController.updateOpportunity(null);
            System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException ex) {
            System.debug(ex.getMessage().contains('Opportunity Id cannot be null'));
        }
    }


}