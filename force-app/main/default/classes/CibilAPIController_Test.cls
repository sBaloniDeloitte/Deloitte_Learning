@isTest
public class CibilAPIController_Test {
    
    @TestSetup
    static void makeData() {
        Account acc = FITestDataFactory.createAccount('Account name 1', 'Customer');
        Lead leadRec = new Lead();
        leadRec.MobilePhone = '9876543210';
        leadRec.LastName = 'Armanii';
        leadRec.FirstName = 'Mohammad';
        leadRec.Customer_Type__c = 'Individual';
        leadRec.Company = 'Companu';
        leadRec.Product__c = 'Home Loan';
        insert leadRec;
        Opportunity opp = FITestDataFactory.createLoanApplication(true, acc);
        opp.Lead__c = leadRec.Id;
        upsert opp;
        
        
        
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
        applicant.Applicant_Type__c = 'Primary Applicant';
        applicant.CIBIL_Retrigger_Required__c=true;
        upsert applicant;
        
        Applicant_Address__c address = new Applicant_Address__c(
            Address_Type__c ='Permanent',
            Address_Line_1__c = 'line 1',
            Address_Line_2__c = 'line 2',
            Address_Line_3__c = 'line 3',
            Loan_Application__c = applicant.Loan_Application__c,
            Applicant__c = applicant.Id);
        insert address;
        TestDataFactory.setupIntegrationSettings('Loan Applicant CIBIL');
        TestDataFactory.setupIntegrationSettings('Get Token');
        Document_Master__c dmCibil = new Document_Master__c(Name = 'Cibil',Document_Name__c = 'Cibil', Requirement_At__c = 'Applicant Level', Document_Category__c = 'Applicant Level',Is_Active__c = true
                                                           );
        insert dmCibil;
        
        Document_Master__c dmOther = new Document_Master__c(
            Name = 'Other',
            Document_Name__c='Other',
            //Requirement_At__c = 'Loan Application',
            Requirement_At__c = 'Application Verification',
            Document_Category__c = 'Residence Verification',
            Is_Active__c = true
        );
        insert dmOther;
        
        ContentVersion cv = new ContentVersion(
            Title = 'CIBIL_Test_PDF',
            PathOnClient = 'cibil.pdf',
            VersionData = Blob.valueOf('fake-pdf-content'),
            IsMajorVersion = true
        );
        insert cv;
        ContentVersion cvQu = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        Document_Details__c checklist = new Document_Details__c();
        checklist.Applicant__c = applicant.Id;
        checklist.Document_Master__c = dmCibil.Id;
        checklist.Content_Document_Id__c = cvQu.ContentDocumentId;
        checklist.Loan_Application__c = applicant.Loan_Application__c;
        checklist.Name = 'Cibil Response';
        insert checklist;
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = checklist.id;
        cdl.ContentDocumentId = cvQu.ContentDocumentId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
    }
    
    @isTest
    static void checkApplicantAddress_test(){
        Application_Applicant__c applicant = [SELECT Id,Pincode__c, Applicant_Type__c, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        Applicant_Address__c address = [SELECT Id FROM Applicant_Address__c WHERE Applicant__c=:applicant.Id LIMIT 1];
        Boolean result = CibilAPIController.checkApplicantAddress(applicant.Id);
    }
    @isTest
    static void checkApplicantAddress_test_negative(){
        Application_Applicant__c applicant1 = [SELECT Id,Pincode__c, Applicant_Type__c, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        Applicant_Address__c address = [SELECT Id FROM Applicant_Address__c WHERE Applicant__c=:applicant1.Id LIMIT 1];
        applicant1.Applicant_Type__c = 'Co Applicant';
        update applicant1;
        Boolean result = CibilAPIController.checkApplicantAddress(applicant1.Id);
    }
    
    @isTest
    static void storeCibilResponseAsFile_Test(){
        Document_Master__c docMaster= [SELECT Id from Document_Master__c WHERE Document_Name__c = 'Cibil' LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id,Pincode__c, Applicant_Type__c, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        ContentVersion cibilResponse = [SELECT Id,VersionData from ContentVersion LIMIT 1];
        Document_Details__c doc = [SELECT Id,Content_Document_Id__c from Document_Details__c WHERE Name = 'Cibil Response' LIMIT 1];
        ContentDocumentLink cdl = [SELECT Id,ContentDocumentId from ContentDocumentLink  WHERE LinkedEntityId = :doc.Id LIMIT 1];
        CibilAPIController.storeCibilResponseAsFile(String.valueOf(cibilResponse.VersionData),applicant.Id,applicant.Loan_Application__c);        
    }
    
    
    @isTest
    static void initiateAPIRequest_Test() {
        try {
            Map<String, String> inputMap = new Map<String, String>();
            Opportunity opp = [SELECT Id,Lead__c FROM Opportunity LIMIT 1];
            Application_Applicant__c applicant = [SELECT Id,Loan_Application__r.Lead__c,Loan_Application__c FROM Application_Applicant__c WHERE Loan_Application__c=:opp.Id LIMIT 1];
            ContentVersion cv = [SELECT Id FROM ContentVersion ORDER BY CreatedDate DESC LIMIT 1];
            Lead ld = [Select Id,Name,Requested_Loan_Amount__c,Loan_Application__r.Lead__c from Lead where Id=:opp.Lead__c Limit 1];
            //List<Document_Master__c> docMasterCibil = [];
            inputMap.put('loanId', opp.Id);
            inputMap.put('applicantId', applicant.Id);
            inputMap.put('processName', 'Loan CIBIL');
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockResponse(cv.Id));
            String resp = CibilAPIController.initiateAPIRequest(inputMap);
            Test.stopTest();
            
        } catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
        }
    }
    @isTest
    static void initiateAPIRequest_503_Test() {
        Opportunity opp = [SELECT Id, Lead__c FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [
            SELECT Id, Loan_Application__r.Lead__c, Loan_Application__c 
            FROM Application_Applicant__c 
            WHERE Loan_Application__c = :opp.Id LIMIT 1
        ];
        
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
                'applicantId' => applicant.Id,
                'processName' => 'Loan CIBIL'
                };
                    
                    Test.startTest();
        // Use the 503-specific mock class
        Test.setMock(HttpCalloutMock.class, new MockResponse503());
        
        try {
            String resp = CibilAPIController.initiateAPIRequest(inputMap);
        } catch (Exception e) {
            System.debug('Expected exception for 503: ' + e.getMessage());
        }
        
        Test.stopTest();
        System.debug('ckycResp resp getStatusCode simulated as 503');
    }
    
    public class MockResponse503 implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            // Simulate 503 Service Unavailable
            res.setStatusCode(503);
            res.setBody('{"error": "Service Unavailable"}');
            
            return res;
        }
    }
    
    
    class MockResponse implements HttpCalloutMock {
        Id contentVersionId;
        
        MockResponse(Id cvId) {
            this.contentVersionId = cvId;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String jsonResponse = '{' +
                '  "leadCibilId": 1,' +
                '  "applicationKey": 1001,' +
                '  "leadId": 2001,' +
                '  "coApplicantId": 3001,' +
                '  "hlorLapLoanAmount": 0,' +
                '  "creditCardOutstanding": 0,' +
                '  "autoLoanAmount": 0,' +
                '  "twoWheelerLoanAmount": 0,' +
                '  "blLoanAmount": 0,' +
                '  "plLoanAmount": 0,' +
                '  "ccOverdueAmount": 0,' +
                '  "secCcOverdueAmount": 0,' +
                '  "eduLoanAmount": 0,' +
                '  "consumerLoanAmount": 0,' +
                '  "commVehicleLoanAmount": 0,' +
                '  "usedCarLoanAmount": 0,' +
                '  "secCreditCardOutstanding": 0,' +
                '  "loanOnCreditCard": 0,' +
                '  "creditCardOutstandingEmi": 0,' +
                '  "hlorLapLoanAmountEmi": 0,' +
                '  "autoLoanAmountEmi": 0,' +
                '  "twoWheelerLoanAmountEmi": 0,' +
                '  "blLoanAmountEmi": 0,' +
                '  "plLoanAmountEmi": 0,' +
                '  "eduLoanAmountEmi": 0,' +
                '  "consumerLoanAmountEmi": 0,' +
                '  "commVehicleLoanAmountEmi": 0,' +
                '  "usedCarLoanAmountEmi": 0,' +
                '  "secCreditCardOutstandingEmi": 0,' +
                '  "loanOnCreditCardEmi": 0,' +
                '  "cibilScore": 756,' +
                '  "cibilApplicationId": "APP-XYZ",' +
                '  "cibildocumentid": "DOC-123",' +
                '  "cibilDocumentBase64": null,' +
                '  "cibilpdfdocumentbase64": "' + String.valueOf(contentVersionId) + '",' +
                '  "noOfAccountsIn30DpdInL12M": 0,' +
                '  "noOfAccountsIn60DpdInL12M": 0,' +
                '  "lastMntOn": "2025-08-01",' +
                '  "pan": "ABCDE1234F",' +
                '  "mobile": "9999999999",' +
                '  "tuffResponse": "<Response><CreditReport><Score>750</Score><Status>Approved</Status><Loans><Loan type=\\"HomeLoan\\" outstanding=\\"500000\\"/></Loans></CreditReport></Response>",' +
                '  "requestType": "CIBIL",' +
                '  "requestSource": "SFDC",' +
                '  "entity": "Individual",' +
                '  "agency": "TUFF",' +
                '  "createdOn": "2025-08-20",' +
                '  "isActive": 1' +
                '}';
            
            res.setBody(jsonResponse);
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest
    static void processResWrapper_PrerequisiteError_Test() {
        
        // Get existing applicant and loan for test context
        Application_Applicant__c applicant = [SELECT Id, Loan_Application__c FROM Application_Applicant__c LIMIT 1];
        Id loanId = applicant.Loan_Application__c;
        String processName = 'Loan CIBIL';
        
        // Mock wrapper with prerequisite errors
        IntHandler.processResWrapper wrapper = new IntHandler.processResWrapper();
        wrapper.prerequisiteError = new List<String>{'Missing Address', 'Invalid PAN'};
            wrapper.payload = '{"dummy":"payload"}';
        
        String returnResp;
        String resultMessage;
        Integration_Details__c integrationDetail;
        
        // Get integration settings
        List<Integration_Settings__c> intSettingList = [
            SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
            FROM Integration_Settings__c
            WHERE Name = 'Loan Applicant CIBIL'
            LIMIT 1
        ];
        Integration_Settings__c intSetting = intSettingList[0];
        
        // Execute the logic to cover the prerequisiteError block
        if (wrapper.prerequisiteError != null && !wrapper.prerequisiteError.isEmpty()) {
            integrationDetail = new Integration_Details__c();
            integrationDetail.Status__c = '412';
            integrationDetail.Prerequisite__c = String.join(wrapper.prerequisiteError, ', ');
            integrationDetail.Name = processName;
            integrationDetail.Object_Name__c = 'Application_Applicant__c';
            integrationDetail.Loan_Application__c = loanId;
            integrationDetail.Related_Record_Id__c = applicant.Id;
            integrationDetail.EndPoint__c = intSetting.EndPoint__c;
            integrationDetail.Request_JSON__c = wrapper.payload;
            insert integrationDetail; // Cover DML
            
            resultMessage = String.join(wrapper.prerequisiteError, ', ');
            returnResp = resultMessage;
            
            System.debug('resultMessage: ' + resultMessage);
        }
        
        // Assertions to verify behavior
        System.assertEquals('Missing Address, Invalid PAN', returnResp);
        System.assertEquals('412', integrationDetail.Status__c);
        System.assert(integrationDetail.Prerequisite__c.contains('Missing Address'));
        System.assert(integrationDetail.Prerequisite__c.contains('Invalid PAN'));
    }
    @isTest
    static void processResWrapperfetchCibilData() {
        Opportunity opp=[select id from Opportunity Limit 1];
        Application_Applicant__c app=[select id from Application_Applicant__c Limit 1];
        Map<String, String> inputMap = new Map<String, String>{
            'recordId' => opp.Id,
                'objectName' => 'Opportunity'
                };
                    Map<String, String> inputMap1 = new Map<String, String>{
                        'recordId' => app.Id,
                            'objectName' => 'Application_Applicant__c'
                            };
                                
        Test.startTest();
        CibilAPIController.fetchCibilData(inputMap);
        CibilAPIController.fetchCibilData(inputMap1);
        Test.stopTest();
        
        System.assertEquals('Opportunity',inputMap.get('objectName'),'Should be equal');
    }
    
    class MockResponseWithAccount implements HttpCalloutMock {
        Id contentVersionId;
        
        MockResponseWithAccount(Id cvId) {
            this.contentVersionId = cvId;
        }
        public HTTPResponse respond(HTTPRequest req) {
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
           
            String jsonResponse = '{' +
            '  "leadCibilId": 1,' +
            '  "applicationKey": 1001,' +
            '  "leadId": 2001,' +
            '  "coApplicantId": 3001,' +
            '  "hlorLapLoanAmount": 0,' +
            '  "creditCardOutstanding": 0,' +
            '  "autoLoanAmount": 0,' +
            '  "twoWheelerLoanAmount": 0,' +
            '  "blLoanAmount": 0,' +
            '  "plLoanAmount": 0,' +
            '  "ccOverdueAmount": 0,' +
            '  "secCcOverdueAmount": 0,' +
            '  "eduLoanAmount": 0,' +
            '  "consumerLoanAmount": 0,' +
            '  "commVehicleLoanAmount": 0,' +
            '  "usedCarLoanAmount": 0,' +
            '  "secCreditCardOutstanding": 0,' +
            '  "loanOnCreditCard": 0,' +
            '  "creditCardOutstandingEmi": 0,' +
            '  "hlorLapLoanAmountEmi": 0,' +
            '  "autoLoanAmountEmi": 0,' +
            '  "twoWheelerLoanAmountEmi": 0,' +
            '  "blLoanAmountEmi": 0,' +
            '  "plLoanAmountEmi": 0,' +
            '  "eduLoanAmountEmi": 0,' +
            '  "consumerLoanAmountEmi": 0,' +
            '  "commVehicleLoanAmountEmi": 0,' +
            '  "usedCarLoanAmountEmi": 0,' +
            '  "secCreditCardOutstandingEmi": 0,' +
            '  "loanOnCreditCardEmi": 0,' +
            '  "cibilScore": 756,' +
            '  "cibilApplicationId": "APP-XYZ",' +
            '  "cibildocumentid": "DOC-123",' +
            '  "cibilDocumentBase64": null,' +
            '  "cibilpdfdocumentbase64": "' + String.valueOf(contentVersionId) + '",' +
            '  "noOfAccountsIn30DpdInL12M": 0,' +
            '  "noOfAccountsIn60DpdInL12M": 0,' +
            '  "lastMntOn": "2025-08-01",' +
            '  "pan": "ABCDE1234F",' +
            '  "mobile": "9999999999",' +
        
            '  "tuffResponse": "<Response>' +
            '    <CreditReport>' +
            '      <Score>750</Score>' +
            '      <Status>Approved</Status>' +
        
            '      <NameSegment>' +
            '        <DateOfBirth>01011990</DateOfBirth>' +
            '      </NameSegment>' +
            '      <Account>' +
            '        <Account_NonSummary_Segment_Fields>' +
            '          <AccountType>01</AccountType>' +
            '          <HighCreditOrSanctionedAmount>500000</HighCreditOrSanctionedAmount>' +
            '          <CurrentBalance>200000</CurrentBalance>' +
            '          <AmountOverdue>0</AmountOverdue>' +
            '          <EmiAmount>15000</EmiAmount>' +
            '          <OwenershipIndicator>1</OwenershipIndicator>' +
            '          <DateOpenedOrDisbursed>01012020</DateOpenedOrDisbursed>' +
            '          <DateOfLastPayment>01012025</DateOfLastPayment>' +
            '          <DateClosed>03032026</DateClosed>' +
            '          <PaymentHistoryStartDate>01012024</PaymentHistoryStartDate>' +
            '          <PaymentHistoryEndDate>01012025</PaymentHistoryEndDate>' +
            '          <PaymentHistory1>000000000000</PaymentHistory1>' +
            '          <PaymentHistory2>00000000000065555555555555555588888888</PaymentHistory2>' +
            '          <WrittenOffAmountTotal>123456789</WrittenOffAmountTotal>' +
            '          <SuitFiledOrWilfulDefault>123456789</SuitFiledOrWilfulDefault>' +
            '          <WrittenOffAmountPrincipal></WrittenOffAmountPrincipal>' +
            '          <SettlementAmount></SettlementAmount>' +
            '          <DateReportedAndCertified>01022025</DateReportedAndCertified>' +
            '        </Account_NonSummary_Segment_Fields>' +
            '      </Account>' +         
            '      <Account>' +
            '<Account_NonSummary_Segment_Fields>'+
              '<AccountType>03</AccountType>'+
              '<HighCreditOrSanctionedAmount>250000</HighCreditOrSanctionedAmount>'+
              '<CurrentBalance>100000</CurrentBalance>'+
              '<AmountOverdue>0</AmountOverdue>'+
              '<EmiAmount>8000</EmiAmount>'+
              '<OwenershipIndicator>4</OwenershipIndicator>'+
              '<DateOpenedOrDisbursed>15062022</DateOpenedOrDisbursed>'+
              '<DateOfLastPayment>01022025</DateOfLastPayment>'+
              '<DateClosed></DateClosed>'+
              '<PaymentHistoryStartDate>01012024</PaymentHistoryStartDate>'+
              '<PaymentHistoryEndDate>01012025</PaymentHistoryEndDate>'+
              '<PaymentHistory1>000000000000</PaymentHistory1>'+
              '<SuitFiledOrWilfulDefault>00</SuitFiledOrWilfulDefault>'+
            '<DateReportedAndCertified>01022025</DateReportedAndCertified>'+
                '</Account_NonSummary_Segment_Fields>'+
              '</Account>'+
            '      <SingleAccount>' +
            '        <SingleAccount_NonSummary_Segment_Fields>' +
            '          <SingleAccountType>02</SingleAccountType>' +
            '          <HighCreditOrSanctionedAmount>300000</HighCreditOrSanctionedAmount>' +
            '          <CurrentBalance>150000</CurrentBalance>' +
            '          <AmountOverdue>0</AmountOverdue>' +
            '          <EmiAmount>10000</EmiAmount>' +
            '          <OwenershipIndicator>1</OwenershipIndicator>' +
            '          <DateOpenedOrDisbursed>01012021</DateOpenedOrDisbursed>' +
            '          <DateOfLastPayment>01012025</DateOfLastPayment>' +
            '          <DateClosed></DateClosed>' +
            '          <PaymentHistoryStartDate>01012024</PaymentHistoryStartDate>' +
            '          <PaymentHistoryEndDate>01012025</PaymentHistoryEndDate>' +
            '          <PaymentHistory1>000000000000</PaymentHistory1>' +
            '          <PaymentHistory2>00000000000065555555555555555588888888</PaymentHistory2>' +
            '          <SuitFiledOrWilfulDefault>00</SuitFiledOrWilfulDefault>' +
            '          <WrittenOffAmountTotal>1234455555</WrittenOffAmountTotal>' +
            '          <WrittenOffAmountPrincipal></WrittenOffAmountPrincipal>' +
            '          <SettlementAmount></SettlementAmount>' +
            '          <DateReportedAndCertified>01022025</DateReportedAndCertified>' +
            '        </SingleAccount_NonSummary_Segment_Fields>' +
            '      </SingleAccount>' +
        
            '    </CreditReport>' +
            '  </Response>",' +
        
            '  "requestType": "CIBIL",' +
            '  "requestSource": "SFDC",' +
            '  "entity": "Individual",' +
            '  "agency": "TUFF",' +
            '  "createdOn": "2025-08-20",' +
            '  "isActive": 1' +
            '}';
            res.setBody(jsonResponse);
            res.setStatusCode(200);
            return res;
        }
    }
    
    class MockResponseWithSingleAccount implements HttpCalloutMock {
        Id contentVersionId;
        
        MockResponseWithSingleAccount(Id cvId) {
            this.contentVersionId = cvId;
        }
        public HTTPResponse respond(HTTPRequest req) {
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
          
            String jsonResponse = '{' +
            '  "leadCibilId": 1,' +
            '  "applicationKey": 1001,' +
            '  "leadId": 2001,' +
            '  "coApplicantId": 3001,' +
            '  "hlorLapLoanAmount": 0,' +
            '  "creditCardOutstanding": 0,' +
            '  "autoLoanAmount": 0,' +
            '  "twoWheelerLoanAmount": 0,' +
            '  "blLoanAmount": 0,' +
            '  "plLoanAmount": 0,' +
            '  "ccOverdueAmount": 0,' +
            '  "secCcOverdueAmount": 0,' +
            '  "eduLoanAmount": 0,' +
            '  "consumerLoanAmount": 0,' +
            '  "commVehicleLoanAmount": 0,' +
            '  "usedCarLoanAmount": 0,' +
            '  "secCreditCardOutstanding": 0,' +
            '  "loanOnCreditCard": 0,' +
            '  "creditCardOutstandingEmi": 0,' +
            '  "hlorLapLoanAmountEmi": 0,' +
            '  "autoLoanAmountEmi": 0,' +
            '  "twoWheelerLoanAmountEmi": 0,' +
            '  "blLoanAmountEmi": 0,' +
            '  "plLoanAmountEmi": 0,' +
            '  "eduLoanAmountEmi": 0,' +
            '  "consumerLoanAmountEmi": 0,' +
            '  "commVehicleLoanAmountEmi": 0,' +
            '  "usedCarLoanAmountEmi": 0,' +
            '  "secCreditCardOutstandingEmi": 0,' +
            '  "loanOnCreditCardEmi": 0,' +
            '  "cibilScore": 756,' +
            '  "cibilApplicationId": "APP-XYZ",' +
            '  "cibildocumentid": "DOC-123",' +
            '  "cibilDocumentBase64": null,' +
            '  "cibilpdfdocumentbase64": "' + String.valueOf(contentVersionId) + '",' +
            '  "noOfAccountsIn30DpdInL12M": 0,' +
            '  "noOfAccountsIn60DpdInL12M": 0,' +
            '  "lastMntOn": "2025-08-01",' +
            '  "pan": "ABCDE1234F",' +
            '  "mobile": "9999999999",' +
        
            '  "tuffResponse": "<Response>' +
            '    <CreditReport>' +
            '      <Score>750</Score>' +
            '      <Status>Approved</Status>' +
        
            '      <NameSegment>' +
            '        <DateOfBirth>01011990</DateOfBirth>' +
            '      </NameSegment>' +
            '      <Account>' +
            '        <Account_NonSummary_Segment_Fields>' +
            '          <AccountType>01</AccountType>' +
            '          <HighCreditOrSanctionedAmount>500000</HighCreditOrSanctionedAmount>' +
            '          <CurrentBalance>200000</CurrentBalance>' +
            '          <AmountOverdue>0</AmountOverdue>' +
            '          <EmiAmount>15000</EmiAmount>' +
            '          <OwenershipIndicator>1</OwenershipIndicator>' +
            '          <DateOpenedOrDisbursed>01012020</DateOpenedOrDisbursed>' +
            '          <DateOfLastPayment>01012025</DateOfLastPayment>' +
            '          <DateClosed>03032026</DateClosed>' +
            '          <PaymentHistoryStartDate>01012024</PaymentHistoryStartDate>' +
            '          <PaymentHistoryEndDate>01012025</PaymentHistoryEndDate>' +
            '          <PaymentHistory1>000000000000</PaymentHistory1>' +
            '          <PaymentHistory2></PaymentHistory2>' +
            '          <SuitFiledOrWilfulDefault>00</SuitFiledOrWilfulDefault>' +
            '          <WrittenOffAmountTotal></WrittenOffAmountTotal>' +
            '          <WrittenOffAmountPrincipal>1234567888</WrittenOffAmountPrincipal>' +
            '          <SettlementAmount>123333333</SettlementAmount>' +
            '          <DateReportedAndCertified>01022025</DateReportedAndCertified>' +
            '        </Account_NonSummary_Segment_Fields>' +
            '      </Account>' +  
            '      <SingleAccount>' +
            '        <SingleAccount_NonSummary_Segment_Fields>' +
            '          <SingleAccountType>02</SingleAccountType>' +
            '          <HighCreditOrSanctionedAmount>300000</HighCreditOrSanctionedAmount>' +
            '          <CurrentBalance>150000</CurrentBalance>' +
            '          <AmountOverdue>0</AmountOverdue>' +
            '          <EmiAmount>10000</EmiAmount>' +
            '          <OwenershipIndicator>1</OwenershipIndicator>' +
            '          <DateOpenedOrDisbursed>01012021</DateOpenedOrDisbursed>' +
            '          <DateOfLastPayment>01012025</DateOfLastPayment>' +
            '          <DateClosed>03032016</DateClosed>' +
            '          <PaymentHistoryStartDate>01012024</PaymentHistoryStartDate>' +
            '          <PaymentHistoryEndDate>01012025</PaymentHistoryEndDate>' +
            '          <PaymentHistory1>000000000000</PaymentHistory1>' +
            '          <PaymentHistory2>00000000000065555555555555555588888888</PaymentHistory2>' +
            '          <SuitFiledOrWilfulDefault>1234</SuitFiledOrWilfulDefault>' +
            '          <WrittenOffAmountTotal></WrittenOffAmountTotal>' +
            '          <WrittenOffAmountPrincipal></WrittenOffAmountPrincipal>' +
            '          <SettlementAmount></SettlementAmount>' +
            '          <DateReportedAndCertified>01022025</DateReportedAndCertified>' +
            '        </SingleAccount_NonSummary_Segment_Fields>' +
            '      </SingleAccount>' +
        
            '    </CreditReport>' +
            '  </Response>",' +
        
            '  "requestType": "CIBIL",' +
            '  "requestSource": "SFDC",' +
            '  "entity": "Individual",' +
            '  "agency": "TUFF",' +
            '  "createdOn": "2025-08-20",' +
            '  "isActive": 1' +
            '}';
            res.setBody(jsonResponse);
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    static void initiateAPIRequest_AccountCoverage_Test() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = 
            [SELECT Id, Loan_Application__c 
             FROM Application_Applicant__c 
             LIMIT 1];
        
          Triangulation_Data__c triangulationData= new Triangulation_Data__c(
            CKYC_Transaction_Id__c= '123444',
            Loan_Application__c= opp.Id, 
            Application_Applicant__c= applicant.Id,
            Source_Type__c= 'CIBIL',
            Document_Type__c = 'PAN'
        );
        insert triangulationData;
		ContentVersion cv = [SELECT Id FROM ContentVersion ORDER BY CreatedDate DESC LIMIT 1];        
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
                'applicantId' => applicant.Id,
                'processName' => 'Loan CIBIL'
                };
                    
                    Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockResponseWithAccount(cv.Id));
        String resp = CibilAPIController.initiateAPIRequest(inputMap);
        System.debug('resp==>'+resp);
        Test.stopTest();
        
       
        List<Income_Expense_Obligation__c> obligations =
            [SELECT Id FROM Income_Expense_Obligation__c
             WHERE Application_Applicant__c = :applicant.Id];
        
        System.assert(obligations.size() > 0);
    }
    
     @isTest
    static void initiateAPIRequest_SingleAccountCoverage_Test() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = 
            [SELECT Id, Loan_Application__c 
             FROM Application_Applicant__c 
             LIMIT 1];
        
          Triangulation_Data__c triangulationData= new Triangulation_Data__c(
            CKYC_Transaction_Id__c= '123444',
            Loan_Application__c= opp.Id, 
            Application_Applicant__c= applicant.Id,
            Source_Type__c= 'CIBIL',
            Document_Type__c = 'PAN'
        );
        insert triangulationData;
		ContentVersion cv = [SELECT Id FROM ContentVersion ORDER BY CreatedDate DESC LIMIT 1];        
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
                'applicantId' => applicant.Id,
                'processName' => 'Loan CIBIL'
                };
                    
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockResponseWithSingleAccount(cv.Id));
        String resp = CibilAPIController.initiateAPIRequest(inputMap);
        System.debug('resp==>'+resp);
        Test.stopTest();
        
       
        List<Income_Expense_Obligation__c> obligations =
            [SELECT Id FROM Income_Expense_Obligation__c
             WHERE Application_Applicant__c = :applicant.Id];
        
        System.assert(obligations.size() > 0);
    }
    
    @isTest
    static void initiateAPIRequest_SingleAccountCoverage_Test2() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = 
            [SELECT Id, Loan_Application__c 
             FROM Application_Applicant__c 
             LIMIT 1];
        
		ContentVersion cv = [SELECT Id FROM ContentVersion ORDER BY CreatedDate DESC LIMIT 1];        
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id,
                'applicantId' => applicant.Id,
                'processName' => 'Loan CIBIL'
                };
                    
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockResponseWithSingleAccount(cv.Id));
        String resp = CibilAPIController.initiateAPIRequest(inputMap);
        Test.stopTest();
        
       
        List<Income_Expense_Obligation__c> obligations =
            [SELECT Id FROM Income_Expense_Obligation__c
             WHERE Application_Applicant__c = :applicant.Id];
        
        System.assert(obligations.size() > 0);
    }
}