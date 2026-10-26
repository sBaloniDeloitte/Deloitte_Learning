@isTest
public class SalesLoanEntireViewControllerTest {
    @testSetup static void setupData(){
        String jsonData = '{'+
        '\"finReference\":\"GFL3001BD0014530\",'+
        '\"stp\":true,'+
        '\"financeSchedule\":{'+
            '\"financeDetail\":{'+
                '\"applicationNo\":\"APP12345\",'+
                '\"finType\":\"BD\",'+
                '\"finCcy\":\"INR\",'+
                '\"finBranch\":\"3001\",'+
                '\"finReference\":\"GFL3001BD0014530\",'+
                '\"finAmount\":30000000,'+
                '\"finStartDate\":\"2044-03-15\",'+
                '\"status\":\"Approved\",'+
                '\"numberOfTerms\":24,'+
                '\"maturityDate\":\"2046-03-26\",'+
                '\"finRepayMethod\":\"NACH\",'+
                '\"profitDaysBasis\":\"A/A_365L\",'+
                '\"repayRateBasis\":\"R\",'+
                '\"repayPftRate\":16.96,'+
                '\"repayBaseRate\":\"GFLPLRBL\",'+
                '\"scheduleMethod\":\"PFT\",'+
                '\"nextRepayDate\":\"2044-04-26\",'+
                '\"nextRepayPftDate\":\"2044-04-26\",'+
                '\"nextRepayRvwDate\":\"2044-04-26\"'+
            '},'+
            '\"repayInstruction\":[{'+
                '\"repayDate\":\"2044-04-26\",'+
                '\"repayAmount\":1500000,'+
                '\"repaySchdMethod\":\"PFT\",'+
                '\"version\":0'+
            '}],'+
            '\"schedules\":[{'+
                '\"schDate\":\"2044-03-15\",'+
                '\"pftAmount\":0,'+
                '\"schdPft\":0,'+
                '\"schdPftPaid\":0,'+
                '\"schdPri\":0,'+
                '\"schdPriPaid\":0,'+
                '\"feeSchd\":0,'+
                '\"tDSAmount\":0,'+
                '\"totalAmount\":0,'+
                '\"endBal\":30000000,'+
                '\"limitDrop\":0,'+
                '\"dropLineLimit\":1000000000,'+
                '\"availableLimit\":970000000,'+
                '\"dueDate\":\"2044-04-06\",'+
                '\"version\":0'+
            '}],'+
            '\"overdue\":{'+
                '\"applyODPenalty\":true,'+
                '\"odIncGrcDays\":false,'+
                '\"odGraceDays\":7,'+
                '\"odChargeType\":\"D\",'+
                '\"odChargeCalOn\":\"STOT\",'+
                '\"odChargeAmtOrPerc\":24,'+
                '\"odAllowWaiver\":true,'+
                '\"odMaxWaiverPerc\":100'+
            '},'+
            '\"summary\":{'+
                '\"effectiveRateOfReturn\":18.369918468,'+
                '\"totalProfit\":10318500,'+
                '\"totalRepayAmt\":40318500,'+
                '\"feeChargeAmount\":2399800,'+
                '\"numberOfTerms\":24,'+
                '\"loanTenor\":24,'+
                '\"maturityDate\":\"2046-03-26\",'+
                '\"firstDisbDate\":\"2044-03-15\",'+
                '\"lastDisbDate\":\"2044-03-15\",'+
                '\"firstEmiAmount\":430900,'+
                '\"nextSchDate\":\"2044-06-26\",'+
                '\"nextRepayAmount\":430900,'+
                '\"futureInst\":22,'+
                '\"futureTenor\":21,'+
                '\"firstInstDate\":\"2044-04-26\",'+
                '\"paidTotal\":0,'+
                '\"paidPri\":0,'+
                '\"paidPft\":0,'+
                '\"lastRepayDate\":\"2044-05-26\",'+
                '\"outstandingTotal\":40318500,'+
                '\"outstandingPri\":30000000,'+
                '\"outstandingPft\":10318500,'+
                '\"overdueTotal\":1001000,'+
                '\"overduePri\":0,'+
                '\"overduePft\":1001000,'+
                '\"overdueInst\":3,'+
                '\"overDueChargesVal\":20300,'+
                '\"overdueTotalIncludeCharges\":1021300'+
            '},'+
            '\"disbursements\":[{'+
                '\"disbParty\":\"CS\",'+
                '\"disbType\":\"NEFT\",'+
                '\"disbDate\":\"2044-03-15\",'+
                '\"disbAmount\":28800100,'+
                '\"bankCode\":\"176\",'+
                '\"branchBankName\":\"RATNAKAR BANK LTD\",'+
                '\"branchCode\":\"0000114\",'+
                '\"ifsc\":\"RATN0000114\",'+
                '\"accountNo\":\"7865432456\",'+
                '\"acHolderName\":\"gfdsa\",'+
                '\"partnerBankId\":154'+
            '}]'+
        '},'+
        '\"mandateDetail\":{'+
        '\"cif\":\"119808\",'+
        '\"finReference\":\"GFL3001BD0014530\",'+
        '\"useExisting\":true,'+
        '\"mandateID\":3151,'+
        '\"mandateType\":\"NACH\",'+
        '\"bankCode\":\"485\",'+
        '\"branchCode\":\"0000207\",'+
        '\"ifsc\":\"KKBK0000207\",'+
        '\"accType\":\"12\",'+
        '\"accNumber\":\"4545465656545656\",'+
        '\"accHolderName\":\"yhtgrfdes\",'+
        '\"startDate\":\"2044-04-16\",'+
        '\"expiryDate\":\"2060-12-18\",'+
        '\"maxLimit\":3000000000,'+
        '\"periodicity\":\"M0001\",'+
        '\"status\":\"NEW\",'+
        '\"active\":true,'+
        '\"totEMIAmount\":430900,'+
        '\"entityCode\":\"GFL\",'+
        '\"version\":1,'+
        '\"defaultMandate\":false'+
        '},'+
        '\"coApplicants\":[{'+
        '\"cif\":\"120836\",'+
        '\"shortName\":\"jinkya Daduuu More\",'+
        '\"includeRepay\":true,'+
        '\"authoritySignatory\":false,'+
        '\"sequence\":0,'+
        '\"version\":1,'+
        '\"catOfcoApplicant\":\"MOTHER\",'+
        '\"includeIncome\":true'+
        '}],'+
        '\"guarantors\":[{'+
        '\"cif\":\"120836\",'+
        '\"shortName\":\"jinkya Daduuu More\",'+
        '\"includeRepay\":true,'+
        '\"authoritySignatory\":false,'+
        '\"sequence\":0,'+
        '\"version\":1,'+
        '\"catOfcoApplicant\":\"MOTHER\",'+
        '\"includeIncome\":true'+
        '}],'+
        '\"documents\":[{'+
        '\"finReference\":\"GFL3001BD0014530\",'+
        '\"docCategory\":\"CAM\",'+
        '\"docName\":\"GFL3001BD0014530_CAM.pdf\",'+
        '\"docFormat\":\"PDF\",'+
        '\"version\":1,'+
        '\"docTypeId\":0'+
        '}],'+
        '\"collaterals\":[{'+
        '\"collateralRef\":\"COL123\",'+
        '\"assignPerc\":100,'+
        '\"version\":1,'+
        '\"seq\":1'+
        '}],'+
        '\"fees\":[{'+
        '\"feeCategory\":\"FC\",'+
        '\"feeCode\":\"PROCFEE\",'+
        '\"feeAmount\":999900,'+
        '\"waiverAmount\":0,'+
        '\"paidAmount\":999900,'+
        '\"feeMethod\":\"DISB\",'+
        '\"scheduleTerms\":0,'+
        '\"feeBalance\":0,'+
        '\"version\":1'+
        '}],'+
        '\"transactions\":[], '+
        '\"extendedDetails\":[{'+
        '\"extendedFields\":[{'+
        '\"fieldName\":\"instructionuid\",'+
        '\"fieldValue\":\"733232\"'+
        '}]'+
        '}],'+
        '\"returnStatus\":{'+
        '\"returnCode\":\"0000\",'+
        '\"returnText\":\"Success\"'+
        '},'+
        '\"receiptId\":0,'+
        '\"interfaceDetailList\":[], '+
        '\"disbStp\":false,'+
        '\"maxPPAmount\":0,'+
        '\"maxPPPercentage\":0,'+
        '\"covenantDetails\":[], '+
        '\"collateralDetails\":[]'+
        '}';

        
        Trigger_Settings__c triggerSettings = new Trigger_Settings__c(
            Name='Trigger Settings',
            Application_Applicant_Trigger__c = true, 
            City_Master_Trigger__c = true, 
            Lead_Trigger__c = true, 
            Opportunity_Trigger__c = true, 
            Application_Verification_Trigger__c = true
        );
        insert triggerSettings;
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        customer.Customer_LMS_Id__c='CIF123';
        update customer;
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        Application_Verification__c appVer = new Application_Verification__c();
        appVer.Stage__c = 'Draft';
        appVer.Loan_Application__c = loan.Id;
        insert appVer;
        
        // create the ContentVersion that contains the JSON you want the controller to read
        ContentVersion cv = new ContentVersion(
            Title = 'LoanJson',
            PathOnClient = 'Loan.json',
            VersionData = Blob.valueOf(jsonData)
        );
        insert cv;
        
        // query back to get ContentDocumentId (needed by Document_Details__c)
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        // if your factory returns a Document_Details__c, set its Content_Document_Id__c to this new CV's document id
        // (Make sure bankDocDetailsObj is declared in this scope. If createBankSentimentAnalysisDetails returns the record, capture it.)
        Document_Details__c bankDocDetailsObj = FITestDataFactory.createBankSentimentAnalysisDetails(cv);
        
        // now attach the ContentDocumentId to the Document_Details__c and update it
        bankDocDetailsObj.Content_Document_Id__c = cv.ContentDocumentId;
        bankDocDetailsObj.Application_Verification__c = appVer.Id;
        bankDocDetailsObj.Account__c = customer.Id;
        update bankDocDetailsObj;
        
        // then insert Integration_Details__c referencing bankDocDetailsObj.Id
        Integration_Details__c integration = new Integration_Details__c(
            Name = 'Get Loan Details',
            GC_Loan_Number__c = 'LN12345',
            Object_Name__c = 'Document_Details__c',
            Customer_Id__c = 'CIF123',
            Endpoint__c='test.com',
            Loan_Application__c = loan.Id,
            Related_Record_Id__c = bankDocDetailsObj.Id
        );
        insert integration;

        Integration_Settings__c integrationSettingsRec = TestDataFactory.setupIntegrationSetting('Get Customer', 'NA', 'NA','Callout:LOS_BL_Get_Customer' , 'GET');
        
    }
    @isTest static void getLoanDetailsFromCustIdTest(){
        Account accRec = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        try{
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        SalesLoanEntireViewController.getLoanDetailsFromCustId(accRec.Id);
        }
        catch(exception e){}
        Test.stopTest();
    }
    @isTest static void getgetLoanDetailsFromCIFTest(){
        Account accRec = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        SalesLoanEntireViewController.getLoanDetailsFromCIF('CIF123');
        Test.stopTest();
    }
    @isTest static void getFinanceDetailsTest(){
        Account accRec = [SELECT Id FROM Account LIMIT 1];
        Integration_Details__c integration =[select id from Integration_Details__c limit 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        SalesLoanEntireViewController.getFinanceDetails('CIF123');
        Test.stopTest();
    }
    @isTest static void testGetLoanDetailsFromCIF() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loan = FITestDataFactory.createOpportunity(customer);
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loan);
        
        // Step 2: Create Integration_Details__c
        Integration_Details__c integration =[select id from Integration_Details__c limit 1];
        ContentVersion contentVersionObj = FITestDataFactory.createContentVersionDetails();
        Document_Details__c bankDocDetailsObj = FITestDataFactory.createBankSentimentAnalysisDetails(contentVersionObj);
        bankDocDetailsObj.Content_Document_Id__c=null;
        update bankDocDetailsObj;
        // Update Integration_Details__c with Related_Record_Id__c
        integration.Related_Record_Id__c = bankDocDetailsObj.Id;
        update integration;
        
        GetExistingLoanDetailsController.GetExistingLoanDetailsWrapper wrapper = new GetExistingLoanDetailsController.GetExistingLoanDetailsWrapper();
        wrapper.finReference = 'LN12345';
        wrapper.financeSchedule = new GetExistingLoanDetailsController.cls_financeSchedule();
        wrapper.financeSchedule.financeDetail = new GetExistingLoanDetailsController.cls_financeDetail();
        wrapper.financeSchedule.financeDetail.applicationNo = 'APP001';
        wrapper.financeSchedule.financeDetail.finType = 'TypeA';
        
        String jsonData = JSON.serialize(wrapper);
        
        // Create ContentVersion with the JSON string in VersionData
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'TestContentVersion';
        contentVersion.PathOnClient = 'TestContentVersion.json';
        contentVersion.VersionData = Blob.valueOf(jsonData);
        insert contentVersion;
        
        // Query ContentDocument Id from ContentVersion after insert
        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        
        // Update Document_Details__c with Content_Document_Id__c
        bankDocDetailsObj.Content_Document_Id__c = contentVersion.ContentDocumentId;
        update bankDocDetailsObj;
        
        // Now run the method under test
        Test.startTest();
        List<GetExistingLoanDetailsController.GetExistingLoanDetailsWrapper> results =SalesLoanEntireViewController.getLoanDetailsFromCIF('CIF123');
        Test.stopTest();
        
        // Validate results
        System.assertNotEquals(null, results);
        
    }
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"cif":"102629","coreBankID":"","categoryCode":"CORP","defaultBranch":"3001","baseCurrency":"INR","primaryRelationOfficer":774,"personalInfo":{"firstName":"Radhika","middleName":"Pathak","lastName":"Pathak","shortName":"Radhika Pathak","fatherName":"","language":"EN","dateofBirth":"1999-09-13","countryofBirth":"IN","nationality":"IN","gender":"OTH","numofDependents":0,"type":"C9","sector":"SAL2","subSector":"SBSC218","industry":"MANU","groupID":0,"parentCountry":"IN","riskCountry":"IN","staff":false,"staffID":"","saleAgent":"","emiCardEligibilityAmt":0,"caste":0,"religion":0,"othersName":"","custCRCPR":"AAAPH1234H","version":78,"marginDeviation":false,"applicationNo":""},"returnStatus":{"returnCode":"0000","returnText":"Success"}}');
            return res;
        }
    }
}