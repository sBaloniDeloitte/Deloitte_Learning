@isTest
public class ITRCmpControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create Account and Opportunity (if Applicant requires a Loan Application reference)
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            Product__c='Affordable Home Loan',
            CloseDate = System.today().addDays(5),
            AccountId = acc.Id
        );
        insert opp;
        
        // Create Application Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            PAN_Number__c = 'ABCDE1234F',
            DOB__c = Date.newInstance(1990,1,1),
            Applicant_Type__c = 'Primary Applicant'
        );
        insert applicant;
         // Insert dummy ContentVersion
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Dummy ITR File';
        cv.PathOnClient = 'DummyITR.pdf';
        cv.VersionData = Blob.valueOf('This is a test file content');
        insert cv;

        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        String contentDocumentId = cv.ContentDocumentId;
        // Create Document_Details__c record linked to the applicant
        Document_Details__c doc = new Document_Details__c(
            Name = 'ITR Report',
            Applicant__c = applicant.Id,
             Document_Type__c ='Template Document',
            Content_Document_Id__c = contentDocumentId // dummy Id
        );
        insert doc;
        
    }
    
    @isTest
    static void testGetApplicantDetails() {
        // Fetch the Applicant created in @testSetup
        Application_Applicant__c applicant = [SELECT Id, PAN_Number__c, DOB__c FROM Application_Applicant__c LIMIT 1];
        
        Test.startTest();
        Application_Applicant__c result = ITRCmpController.getApplicantDetails(applicant.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Applicant should not be null');
        System.assertEquals(applicant.PAN_Number__c, result.PAN_Number__c, 'PAN should match');
        System.assertEquals(applicant.DOB__c, result.DOB__c, 'DOB should match');
    }
    
    @isTest
    static void testGetItrDoc() {
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        
        Test.startTest();
        Document_Details__c result = ITRCmpController.getItrDoc(applicant.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'ITR Doc should not be null');
       // System.assertEquals('ITR Report', result.Name, 'Document name should be ITR Report');
        System.assertEquals(applicant.Id, result.Applicant__c, 'Applicant Id should match');
    }
    
    @isTest
    static void testgetItrvInfoUsingWrapper() {
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
            '\"finStartDate\":\"2044-03-15T00:00:00\",'+
            '\"status\":\"Approved\",'+
            '\"numberOfTerms\":24,'+
            '\"maturityDate\":\"2046-03-26T00:00:00\"'+
            '},'+
            '\"repayInstruction\":[{'+
            '\"repayDate\":\"2044-04-26T00:00:00\",'+
            '\"repayAmount\":1500000,'+
            '\"repaySchdMethod\":\"PFT\",'+
            '\"version\":0'+
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
            '}]'+
            '},'+
            '\"customer\":{'+
            '\"cif\":\"119808\",'+
            '\"categoryCode\":\"RETAIL\",'+
            '\"defaultBranch\":\"3000\",'+
            '\"baseCurrency\":\"INR\",'+
            '\"primaryRelationOfficer\":791,'+
            '\"personalInfo\":{'+
            '\"firstName\":\"raj\",'+
            '\"motherName\":\"pooja\",'+
            '\"dateofBirth\":\"2024-12-03T00:00:00\",'+
            '\"gender\":\"OTH\",'+
            '\"maritalStatus\":\"M\",'+
            '\"qualification\":\"GD\"'+
            '}'+
            '},'+
            '\"disbursement\":[{'+
            '\"disbParty\":\"CS\",'+
            '\"disbType\":\"NEFT\",'+
            '\"disbDate\":\"2044-03-15T00:00:00\",'+
            '\"disbAmount\":28800100,'+
            '\"bankCode\":\"176\",'+
            '\"branchBankName\":\"RATNAKAR BANK LTD\",'+
            '\"branchCode\":\"0000114\",'+
            '\"ifsc\":\"RATN0000114\",'+
            '\"accountNo\":\"7865432456\",'+
            '\"acHolderName\":\"gfdsa\",'+
            '\"partnerBankId\":154'+
            '}],'+
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
            '\"startDate\":\"2044-04-16T00:00:00\",'+
            '\"expiryDate\":\"2060-12-18T00:00:00\",'+
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
            '\"extendedDetails\":{'+
            '\"extendedFields\":[{'+
            '\"fieldName\":\"instructionuid\",'+
            '\"fieldValue\":\"733232\"'+
            '}]'+
            '},'+
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
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        
        Integration_Details__c intDet = new Integration_Details__c(
		//Loan_Application__c = opp.Id,
		Name = 'ITR Response',
        Response_JSON__c = jsonData,
		Endpoint__c = 'Callout:CalculateGST',
		Object_Name__c = 'Opportunity',
		Method_type__c = 'POST',
        Related_Record_Id__c = applicant.Id,
        Status__c = '200'
		);
		insert intDet;
        
        Test.startTest();
		ITRCmpController.getItrvInfoUsingWrapper(applicant.Id);
        Test.stopTest();
        
       // System.assertNotEquals(null, result, 'ITR Doc should not be null');
       // System.assertEquals('ITR Report', result.Name, 'Document name should be ITR Report');
        //System.assertEquals(applicant.Id, result.Applicant__c, 'Applicant Id should match');
    }
    
    @isTest
    static void testgetItrvInfoUsingWrapper1() {
        String jsonData = '{"data":{"xlsxByteReport":"","perfiosCallbackData":{"callback_id":0,"errorCode":"","clientTransactionId":"4948ae07-6b73-46b3-b11e-475f3ebfc772","message":"","perfiosTransactionId":"PIBLCL4ITJRKPY7KDS5PI","status":"COMPLETED"},"jsonReport":{"itrvDetails":{"itrvInfoList":[{"originalOrRevised":"NA","personalInfo":{"address":"15,3rdFloor,SECTOR17,POCKETC-8,DELHI,DWARKA,09-Delhi,91-India,110075","name":"SPINEINFRATECHPRIVATELIMITED","adhaarNumber":"NA","pan":"AARCS2320M","status":"Private"},"incomeDetail":{"adjTotIncUnderAMT":"0","deductionsUnderChapter6A":"","exemptIncome":{"agriculture":"","others":""},"taxPayable":"","bookProfitUnderMAT":"631113","totalIncome":"1099200","netTaxPayable":"285792","grossTotalIncome":"","taxesPaid":{"selfAssessmentTax":"","tds":"","advanceTax":"","tcs":"","totalTaxPaid":"293545"},"dividend":{"totIntAndFeesPayable":"","taxPayableOrRefund":"","taxPayable":"","taxesPaid":"","interestPayable":""},"totalTaxAndInterestPayable":"293549","currentYearLoss":"0","interestPayable":"7757","refund":"0"},"eFilingStatus":"NA","filedus":"NA","financialYear":"2021-22","acknowledgementNumber":"851274181171222","formNumber":"ITR-6","dateOfSubmission":"2022-12-17","dateOfVerification":"17-\nDec-2022","assessmentYear":"2022-23","designationOfAO":"","itrVerifiedBy":""}],"sourceOfData":"StatementUpload"}},"clientTransactionId":"4948ae07-6b73-46b3-b11e-475f3ebfc772","uploadedFile":["https://s3.ap-south-1.amazonaws.com/dev-uat-ghfl-senp-files/2023/10/6/ITR/PIBLCL4ITJRKPY7KDS5PI/1_2_spine_ITR%20Ack_31.03.2023.pdf","https://s3.ap-south-1.amazonaws.com/dev-uat-ghfl-senp-files/2023/10/6/ITR/PIBLCL4ITJRKPY7KDS5PI/2_2_spine_ITR%20Ack_31.03.2022.pdf"],"perfiosTransactionId":"PIBLCL4ITJRKPY7KDS5PI","status":"COMPLETED"},"status":true}';
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        
        Integration_Details__c intDet = new Integration_Details__c(
		//Loan_Application__c = opp.Id,
		Name = 'ITR Response',
        Response_JSON__c = jsonData,
		Endpoint__c = 'Callout:CalculateGST',
		Object_Name__c = 'Opportunity',
		Method_type__c = 'POST',
        Related_Record_Id__c = applicant.Id,
        Status__c = '200'
		);
		insert intDet;
        
        Test.startTest();
		ITRCmpController.getItrvInfoUsingWrapper(applicant.Id);
        ITRCmpController.checkIfRequestInitiated(applicant.Id);
        Test.stopTest();
        
       // System.assertNotEquals(null, result, 'ITR Doc should not be null');
       // System.assertEquals('ITR Report', result.Name, 'Document name should be ITR Report');
        //System.assertEquals(applicant.Id, result.Applicant__c, 'Applicant Id should match');
    }
}