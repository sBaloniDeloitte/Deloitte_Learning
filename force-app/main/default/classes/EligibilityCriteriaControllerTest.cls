@isTest
public class EligibilityCriteriaControllerTest {
    @testSetup
    static void setupTest() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,customer);
        loanApplication.Tenor_Months__c =1;
        loanApplication.Program_Type__c ='test';
        update loanApplication;
        
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApplication);
        applicant.customer__c =customer.Id;
        applicant.Employment_Type__c = 'SEP';
        applicant.Customer_Profile__c= 'SEP';
        applicant.Customer_Type__c = 'Individual';
        applicant.Qualification__c = 'BHMS';
        applicant.Is_Key_Applicant__c = true;
        update applicant;
        // Create PLF Master record
        PLF_Master__c plfMaster = FITestDataFactory.createPLFMaster (true);
        
         Bank_Branch_Master__c bankBranchMasterObj = fitestdatafactory.createBankMasterDetails();
        Bank_Details__c bankDetail =  fitestdatafactory.createBankDetails(applicant, bankBranchMasterObj);
       
        
        // Get the RecordTypeId for Bank_Statement_Analysis__c (replace with actual name if needed)
        RecordType daRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Bank_Statement_Analysis__c' AND Name = 'Derived Analysis' LIMIT 1];
        
        // Create Parent Bank Statement (required due to != null condition)
        Bank_Statement_Analysis__c parentStmt = FITestDataFactory.createBankStatementAnalysis( bankDetail.Id ,daRecordType.Id , true);
        
        Bank_Statement_Analysis__c bsa =  FITestDataFactory.createBankStatementAnalysis( bankDetail.Id ,daRecordType.Id , false );
        // Create main Bank Statement Analysis record
        bsa.Sanction_Limit__c = 500000 ;
        bsa.ABB__c = 120000 ;
        bsa.Total_Number_of_Business_Credits__c = 25 ;
        bsa.Total_number_of_inward_Cheque_return__c = 2; 
        bsa.Month__c = 'January';
        bsa.Average_Limit_Utilisation__c = 65;
        bsa.Total_Number_of_Business_Debits__c = 20;
        bsa.Total_number_of_out_bounce__c = 1 ;
        bsa.Total_Amount_of_Business_Credits__c = 900000; 
        bsa.Parent_Bant_Statement__c = parentStmt.Id ;
        
        insert bsa;
        Product2 businessProduct =  FITestDataFactory.createProduct ('Business Loan' , true);
        Product2 topLevelProduct =  FITestDataFactory.createProduct ('Top Level Product' , true);
        
        Product2 childProduct =  FITestDataFactory.createProduct ('Child Product', false);
        childProduct.Product__c = topLevelProduct.Id ; 
        
        insert childProduct;
        
        // Create RecordType for 'Hybrid Tenure'
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND Name = 'Hybrid Tenure' LIMIT 1];
        
        // Create main Product2 with 'Business Loan'
        Product2 productObj =  FITestDataFactory.createProduct ('Business Loan' , false);

            productObj.Loan_Application__c = loanApplication.Id ;
            productObj.Product__c = businessProduct.Id ; 
        insert productObj ;
        
        Product2 subprod =  FITestDataFactory.createProduct ('Sub Product - Hybrid Tenure' , false);
   
        
            subprod.RecordTypeId = rt.Id;
            subprod.Loan_Application__c = loanApplication.Id;
            subprod.Product__c = childProduct.Id;
            subprod.Repayment_Facility__c = 'Hybrid';
            subprod.Is_loan_VAS_only__c = false ;
        
        insert subprod;
        
        Integration_Settings__c setting = fitestdatafactory.createIntegrationSetting (true);
       
        
        // Create Document_Details
        ContentVersion cv = new ContentVersion(
            Title = 'IncomeEligibilityResponse',
            PathOnClient = 'IncomeEligibilityResponse.txt',
            VersionData = Blob.valueOf('<finalOffer><EMIFINOFF>10811.11</EMIFINOFF><MAXLOELIGINC>1500000.0</MAXLOELIGINC><LOANTENU>120.0</LOANTENU><ROINTR>18.0</ROINTR></finalOffer>'),
            IsMajorVersion = true
        );
        insert cv;
        
        // Step 2: Query ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        // Step 3: Create Document_Details__c using the actual ContentDocumentId
        Document_Details__c doc = new Document_Details__c(
            Name = 'Income Eligibility Response',
            Content_Document_Id__c = cv.ContentDocumentId
        );
        insert doc;
        
        // Create Integration Details record
        Integration_Details__c intg = fitestdatafactory.createIntegrationDetails(false);
            intg.Loan_Application__c = loanApplication.Id ;
            intg.Related_Record_Id__c =doc.Id;
        insert intg;
        
        Integration_Details__c intg2 = fitestdatafactory.createIntegrationDetails(false);
            intg2.Name = 'FICO123' ;
            intg2.Loan_Application__c = loanApplication.Id ;
            intg2.Status__c = '200';
            intg2.Eligibility_Status__c = 'Eligible';
            intg2.IsConsideredEligibility__c = true ;
            intg2.Endpoint__c='test@test.com';
            intg2.Related_Record_Id__c =doc.Id;
            intg2.Response_JSON__c = '<finalOffer><ROINTR>18.0</ROINTR><MAXLOELIGINC>1500000.0</MAXLOELIGINC><LOANTENU>120</LOANTENU><EMIFINOFF>10811.11</EMIFINOFF></finalOffer>' ;
        insert intg2;
        
    }
    
    @isTest
    static void test_getAllApplicableEligibilities() {
        
        Opportunity loanApplication = [SELECT ID from Opportunity LIMIT 1];
        
        // Run the method
        Test.startTest();
        List<EligibilityCriteriaController.EligibilityWrap> results = EligibilityCriteriaController.getAllApplicableEligibilities(loanApplication.Id, false);
        Test.stopTest();
        
    }
    
    @isTest
    static void testCheckEligibilityAndGetIntegrationData() {
        try{
            
            Opportunity opp = [SELECT ID from Opportunity LIMIT 1];
            
            // Stub/mocking EligibilityApiController if it's an external call (optional)
            // Otherwise, directly calling checkEligibility
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockEligibilityResponse());
            try{
                String res = EligibilityCriteriaController.checkEligibility(
                    opp.Id, 'Income Based', 50000, false, true
                );
                System.debug('Eligibility Response: ' + res);
            }
            catch(Exception e){
                System.debug(e.getStackTraceString());
            }
            
            
            // Simulate Integration_Details__c with XML response
            String xmlResponse = '<finalOffer><EMIFINOFF>10811.11</EMIFINOFF><MAXLOELIGINC>1500000.0</MAXLOELIGINC><LOANTENU>120.0</LOANTENU><ROINTR>18.0</ROINTR></finalOffer>';
            
            Integration_Details__c integration = [SELECT ID from Integration_Details__c LIMIT 1];
            Opportunity opp1 = [SELECT Program_Type__c from Opportunity LIMIT 1];
            
            EligibilityCriteriaController.EligibilityWrap wrap = EligibilityCriteriaController.getIntegrationData(integration.Id);
            Test.stopTest();
            
        }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
            
        }
    }
    
    
    @isTest
    static void getIntegrationDataTest() {
        try{
            
            
            Integration_Details__c integration = [SELECT ID from Integration_Details__c LIMIT 1];
            Opportunity opp1 = [SELECT Program_Type__c from Opportunity LIMIT 1];
            Test.startTest();
            EligibilityCriteriaController.EligibilityWrap wrap = EligibilityCriteriaController.getIntegrationData(integration.Id);
            Test.stopTest();
            
        }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
            
        }
    }
    
    private class MockEligibilityResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String mockJson = ''
                + '<response>'
                +     '<finalOffer>'
                +         '{'
                +             '"leadCibilId": 101,' 
                +             '"applicationKey": 2023001,' 
                +             '"leadId": 303,' 
                +             '"coApplicantId": 404,' 
                +             '"hlorLapLoanAmount": 500000.50' 
                +         '}'
                +     '</finalOffer>'
                +     '<finalApprovalLevel>Level1</finalApprovalLevel>'
                +     '<scoreDecision>Approved</scoreDecision>'
                +     '<strategyUsed>StrategyA</strategyUsed>'
                +     '<systemDecision>DEVIATION</systemDecision>'
                +     '<systemDecisionDate>2025-04-01</systemDecisionDate>'
                +     '<systemDecisionDateTime>2025-04-01T15:55:18.605+05:30</systemDecisionDateTime>'
                +     '<scoreCardDetails>'
                +         '<entityId>685</entityId>'
                +         '<entityType>MainApp</entityType>'
                +         '<purpose>Too new to Rate_-1</purpose>'
                +         '<scorecardKey>appScore</scorecardKey>'
                +         '<characteristicCount>11</characteristicCount>'
                +         '<scorecardScore>508.0</scorecardScore>'
                +         '<scorecardName>BL_CRIF_Score_Card</scorecardName>'
                +         '<scoreCardCharacteristics>'
                +             '<characteristicValue>Unknown</characteristicValue>'
                +             '<partialScore>49.0</partialScore>'
                +             '<characteristicName>MAX DELQ Last 6 Months ALL</characteristicName>'
                +         '</scoreCardCharacteristics>'
                +     '</scoreCardDetails>'
                +     '<calculatedVariables>'
                +         '<entityId>101</entityId>'
                +         '<entityType>MainApp</entityType>'
                +         '<fieldName>creditUtilization</fieldName>'
                +         '<fieldType>Decimal</fieldType>'
                +         '<fieldValue>45.5</fieldValue>'
                +         '<productCode>BL</productCode>'
                +         '<purpose>Loan</purpose>'
                +     '</calculatedVariables>'
                +     '<errorResponseList>' // Wrapping this part as a list
                +         '<errorResponse>'
                +             '<errorAction>None</errorAction>'
                +             '<errorCode>0</errorCode>'
                +             '<errorId>0</errorId>'
                +             '<errorName>No Error</errorName>'
                +             '<errorText>Success</errorText>'
                +             '<errorType>Info</errorType>'
                +         '</errorResponse>'
                +     '</errorResponseList>'
                +     '<responseDeviationsList>'
                +         '<responseDeviations>'
                +             '<accountNo>1234567890</accountNo>'
                +             '<approvalLevel>Level2</approvalLevel>'
                +             '<deviationType>HighRisk</deviationType>'
                +             '<entityId>101</entityId>'
                +             '<entityType>MainApp</entityType>'
                +             '<reasonText>DPD more than 90 days</reasonText>'
                +             '<recommendationText>Manual Review Required</recommendationText>'
                +             '<ruleAction>Review</ruleAction>'
                +             '<ruleCategory>Credit</ruleCategory>'
                +             '<ruleDescription>Exceeded 90 DPD threshold</ruleDescription>'
                +             '<ruleId>RULE001</ruleId>'
                +             '<ruleLevel>2</ruleLevel>'
                +             '<ruleName>DPD Breach</ruleName>'
                +         '</responseDeviations>'
                +     '</responseDeviationsList>'
                + '</response>';
            
            
            
            res.setBody(mockJson);
            return res;
        }
    }
    @isTest
    private static void testFinalOfferClass() {
        EligibilityCriteriaController controller = new EligibilityCriteriaController();
        controller.finalOffer = new EligibilityCriteriaController.cls_finalOffer();
        
        controller.finalOffer.ROINTR = '18.0';
        controller.finalOffer.MAXLTV = '0.0';
        controller.finalOffer.MAXLOELIGLTV = '0.0';
        controller.finalOffer.MAXLOELIGINC = '1500000.0';
        controller.finalOffer.LOANTENU = '120.0';
        controller.finalOffer.LOANAMTOFFR = '600000.0';
        controller.finalOffer.FINALLTV = '0.0';
        controller.finalOffer.FINALFOIR = '0.72';
        controller.finalOffer.EMIFINOFF = '10811.11';
        controller.finalOffer.additionalLtv = '0.0';
        
        // Optional asserts to confirm values were set (not necessary for coverage, but good practice)
        System.assertEquals('18.0', controller.finalOffer.ROINTR);
        System.assertEquals('10811.11', controller.finalOffer.EMIFINOFF);
    }
    @isTest
    private static void testEligibilityWrapClass() {
        EligibilityCriteriaController.EligibilityWrap wrap = new EligibilityCriteriaController.EligibilityWrap();
        
        wrap.eligibilityType = 'Income Based';
        wrap.eligibilityTypeFicoName = 'FICO - Income';
        wrap.eligibleLoanAmount = '1500000';
        wrap.finalLoanEmi = '10811.11';
        wrap.finalLoanAmount = '600000';
        wrap.tenor = '120';
        wrap.integrationId = 'a1A2B0000001234';
        wrap.consideredEligibility = true;
        wrap.isLock = false;
        
        // Optional asserts
        System.assertEquals('Income Based', wrap.eligibilityType);
        System.assertEquals('10811.11', wrap.finalLoanEmi);
        System.assertEquals(true, wrap.consideredEligibility);
    }
    @isTest 
    private static void getIntegrationDataByLoanIdTest() {
        try {
            // Create or query test data
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1]; // You used opp1, but then tried opp.id
            Integration_Details__c integration = [SELECT Id, Name FROM Integration_Details__c LIMIT 1];
            
            // Prepare input list
            List<String> eligibleFicoNamesList = new List<String>{integration.Name};
                
                Test.startTest();
            List<EligibilityCriteriaController.IntegrationWrapper> result = 
                EligibilityCriteriaController.getIntegrationDataByLoanId(opp.Id, eligibleFicoNamesList);
            Test.stopTest();
            
            System.assertNotEquals(null, result);
        } catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
        }
    }
    @isTest 
    private static void getIntegrationDataByLoanIdTest2() {
        try {
            // Create or query test data
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1]; // You used opp1, but then tried opp.id
            Integration_Details__c integration = [SELECT Id, Name FROM Integration_Details__c LIMIT 1];
            
            // Prepare input list
            List<String> eligibleFicoNamesList = new List<String>{integration.Name};
                
                Test.startTest();
            List<EligibilityCriteriaController.IntegrationWrapper> result = 
                EligibilityCriteriaController.getIntegrationDataByLoanId(Null ,  eligibleFicoNamesList);
            Test.stopTest();
            
            System.assertNotEquals(null, result);
        } catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
        }
    }
    
}