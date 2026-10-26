@IsTest
public class RepaymentScheduleControllerTest {
    /*
    private static String getFakeScheduleJson() {
        return '{ "schedules": [ ' +
            '{ "dueDate": "2025-10-01", "pftAmount": 123.456, "schdPft": 20.5, "schdPftPaid": 10, "schdPri": 50, "schdPriPaid": 25, ' +
            '"feeSchd": 5, "tDSAmount": 2, "totalAmount": 200, "endBal": 150, "limitDrop": 0, "dropLineLimit": 0, "availableLimit": 100, "bpiAmount": 12.34, "specifier": "Test" } ] }';
    }
    @TestSetup
    static void setupTestData() {
        // 1️⃣ Create Account
        Account acc = FITestDataFactory.createAccount('Test Customer', 'Customer');
        
        // 2️⃣ Create Opportunity (Loan Application)
        Opportunity opp = FITestDataFactory.createLoanApplication(true, acc);
        opp.Is_Pricing_Approval_Required__c=true;
        update opp;
        // 3️⃣ Create Application_Applicant__c
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        insert applicant;
        
        // 4️⃣ Create Integration_Details__c using factory
        List<Integration_Details__c> integrationDetails = TestDataFactory.getTestIntegrationDetails(1, opp.Id, false);
        integrationDetails[0].Calling_Source__c = 'Loan Scheduler Create Charges';
        integrationDetails[0].Object_Name__c = 'Document_Details__c';
        integrationDetails[0].Response_JSON__c = '{"schedules":[{"pftAmount":100,"schdPft":50,"schdPri":200,"totalAmount":350,"specifier":"Test"}]}';
        integrationDetails[0].Is_Success_Response__c = true;
        integrationDetails[0].Calling_Source__c = 'Loan Scheduler Create Charges';
        integrationDetails[0].Status__c = '200';
        integrationDetails[0].EndPoint__c = 'Callout:Create_Schedule_Simulation_API_LOS';
        integrationDetails[0].Comments__c='RepaymentLWC';
        insert integrationDetails;
        
        // 5️⃣ Document_Details__c + ContentVersion using factory
        ContentVersion cv = TestDataFactory.getTestContentVersionData(1, false)[0];
        cv.VersionData = Blob.valueOf(getFakeScheduleJson());
        insert cv;
        
        //Document_Details__c docDet = TestDataFactory.getTestDocumentDetailsData(1, opp.Id, false)[0];
        id cd = [SELECT ContentDocumentId FROM ContentVersion WHERE Id=:cv.Id].ContentDocumentId;
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Loan Scheduler Response';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        //  docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = cd;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        docDetail.Active__c = true;
        insert docDetail;
        
        integrationDetails[0].Related_Record_Id__c = docDetail.Id;
        update integrationDetails;
        
        
        
        
        // 7️⃣ OpportunityTeamMember for canUserEdit
        OpportunityTeamMember team = new OpportunityTeamMember(
            OpportunityId = opp.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'OPS Maker'
        );
        insert team;
    }
    
    @IsTest
    static void testFetchSchedule() {
        try{
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            Test.startTest();
            List<RepaymentScheduleWrapper.schedule> schedules = RepaymentScheduleController.fetchSchedule(opp.Id);
            Test.stopTest();
            System.assert(!schedules.isEmpty(), 'Schedules should be returned');
        }catch(exception e){}
    }
    
    @IsTest
    static void testSaveOppStageChange() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        Test.startTest();
        RepaymentScheduleController.saveOppStageChange(opp.Id, 'Disbursed');
        
        Opportunity updatedOpp = [SELECT StageName FROM Opportunity WHERE Id=:opp.Id];
        System.assertEquals('Disbursed', updatedOpp.StageName);
        
        Test.stopTest();
    }
    
    @IsTest
    static void testCheckRepaymentScheduleAPI() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        Map<String, Object> result = RepaymentScheduleController.checkRepaymentScheduleAPI(opp.Id);
        opp.Is_Pricing_Approval_Required__c=false;
        update opp;
        RepaymentScheduleController.checkRepaymentScheduleAPI(opp.Id);
        Test.stopTest();
        System.assert(result.containsKey('shouldHitAPI'));
        System.assert(result.containsKey('message'));
    }
    @IsTest
    static void testCatchBlock() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        try {
            RepaymentScheduleController.saveOppStageChange('006XXXXXXXXXXXX', 'Closed Won');
        } catch (exception e) {}
        Test.stopTest();
    }
    
    @IsTest
    static void testGetProductNameForLoan() {
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createOpportunity(customer);  
        opp.product__c='Affordable Home Loan';
        update opp;
        RecordType productRT = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Product' LIMIT 1];
        RecordType subProductRT = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Sub Product' LIMIT 1];
        RecordType variantRT = [SELECT Id FROM RecordType WHERE SObjectType='Product2' AND Name='Variant' LIMIT 1];
        
        
        // Create main Product2 (RecordType 'Product')
        Product2 mainProduct = new Product2(
            Name = 'Affordable Home Loan',
            RecordTypeId = productRT.Id,
            Loan_Application__c = opp.Id
        );
        insert mainProduct;
        
        // Create sub Product2 (RecordType 'Sub Product') under main Product
        Product2 subProduct = new Product2(
            Name = 'Test Sub Product',
            RecordTypeId = subProductRT.Id,
            Product__c = mainProduct.Id,
            Loan_Application__c = opp.Id
        );
        insert subProduct;
        
        // Create variant Product2 (RecordType 'Variant') under sub Product
        Product2 variant = new Product2(
            Name = 'Test Variant',
            RecordTypeId = variantRT.Id,
            Product__c = subProduct.Id,
            Loan_Application__c = opp.Id
        );
        insert variant;
        Test.startTest();
        String variantName = RepaymentScheduleController.getProductNameForLoan(opp.Id);
        Test.stopTest();
        System.assertEquals('Test Variant', variantName);
    }
    
    @IsTest
    static void testCanUserEdit() {
        Opportunity opp = [SELECT Id,StageName,Sub_stage__c FROM Opportunity LIMIT 1];
        Test.startTest();
        Boolean canEdit = RepaymentScheduleController.canUserEdit(opp.Id);
        opp.StageName='Disbursement';
        opp.Sub_stage__c='Ops Maker';
        update opp;
        RepaymentScheduleController.canUserEdit(opp.Id);
        Test.stopTest();
        System.assert(canEdit);
    }
    @isTest
    static void testWrapperUsage() {
        // Create wrapper
        RepaymentScheduleWrapper wrapper = new RepaymentScheduleWrapper();
        wrapper.finReference = 'FIN123';
        wrapper.outstandingPri = 1000;
        wrapper.isUpfrontAuto = true;
        wrapper.excessAmount = 200;
        wrapper.version = 1;
        wrapper.feeDues = new List<Object>{};
        wrapper.insurance = new List<Object>{};
        wrapper.planEMIHmonths= new List<Object>{};
        wrapper.planEMIHDates = new List<Object>{};
        wrapper.planPRIHDates = new List<Object>{};
        wrapper.planPRIHMonths= new List<Object>{};
        wrapper.overdueCharges= new List<Object>{};
        wrapper.vas = new List<Object>{};
        wrapper.intervalFee= new List<Object>{};
        wrapper.disbursements = new List<Object>{};                              
                                        // Fee
        RepaymentScheduleWrapper.Fee fee = new RepaymentScheduleWrapper.Fee();
        fee.feeCategory = 'Processing';
        fee.feeCode = 'PROC';
        fee.feeAmount = 100;
        fee.waiverAmount = 10;
        fee.paidAmount = 50;
        fee.feeMethod = 'Flat';
        fee.scheduleTerms = 12;
        fee.feeBalance = 40;
        fee.version = 1;
        fee.finFeeReceipts = new List<Object>();
        
        wrapper.fees = new List<RepaymentScheduleWrapper.Fee>{ fee };
            
            // Schedule
            RepaymentScheduleWrapper.Schedule sch = new RepaymentScheduleWrapper.Schedule();
        sch.schDate = '2025-10-03';
        sch.pftAmount = 12.34;
        sch.schdPft = 20;
        sch.schdPftPaid = 5;
        sch.schdPri = 100;
        sch.schdPriPaid = 50;
        sch.feeSchd = 10;
        sch.tDSAmount = 2;
        sch.totalAmount = 200;
        sch.endBal = 150;
        sch.limitDrop = 0;
        sch.dropLineLimit = 0;
        sch.availableLimit = 50;
        sch.dueDate = '2025-11-01';
        sch.version = 1;
        sch.instNumber = 1;
        sch.bpiAmount = 3.21;
        sch.specifier = 'Test';
        
        wrapper.schedules = new List<RepaymentScheduleWrapper.Schedule>{ sch };
            
            // Summary
            RepaymentScheduleWrapper.Summary sum = new RepaymentScheduleWrapper.Summary();
        sum.effectiveRateOfReturn = 5.5;
        sum.totalGracePft = 1;
        sum.totalGraceCpz = 2;
        sum.totalGrossGrcPft = 3;
        sum.totalCpz = 4;
        sum.totalProfit = 10;
        sum.totalRepayAmt = 500;
        sum.feeChargeAmount = 20;
        sum.numberOfTerms = 12;
        sum.loanTenor = 12;
        sum.maturityDate = '2026-10-03';
        sum.firstEmiAmount = 100;
        sum.nextSchDate = '2025-11-03';
        sum.nextRepayAmount = 120;
        sum.futureInst = 10;
        sum.futureTenor = 10;
        sum.firstInstDate = '2025-11-03';
        sum.paidTotal = 50;
        sum.paidPri = 30;
        sum.paidPft = 20;
        sum.lastRepayDate = '2025-12-03';
        sum.outstandingTotal = 450;
        sum.outstandingPri = 300;
        sum.outstandingPft = 150;
        sum.overdueTotal = 0;
        sum.overduePri = 0;
        sum.overduePft = 0;
        sum.overdueInst = 0;
        sum.overDueCharges1 = 0;
        sum.overdueTotalIncludeCharges = 0;
        sum.overdueCharges = new List<Object>();
        sum.advPaymentAmount = 0;
        sum.finActiveStatus = 'Active';
        sum.fullyDisb = true;
        sum.limitBalance = 1000;
        sum.billedAmount = 200;
        sum.unbilledAmount = 50;
        sum.DPDDays = 0;
        sum.dueDate = '2025-11-03';
        sum.dueAmount = 120;
        sum.limitDrop = 0;
        sum.currentDroplineLimit = 1000;
        sum.utilisation = 500;
        sum.availableLimit = 500;
        sum.graceInst = 0;
        sum.graceTenor = 0;
        sum.futureGraceInst = 0;
        sum.futureGraceTenor = 0;
        sum.totalRevisedTenure = 12;
        sum.revisedLastStepTerms = 12;
        
        wrapper.summary = sum;
        
        // ReturnStatus
        RepaymentScheduleWrapper.ReturnStatus status = new RepaymentScheduleWrapper.ReturnStatus();
        status.returnCode = '00';
        status.returnText = 'Success';
        wrapper.returnStatus = status;
        
        // Step
        RepaymentScheduleWrapper.Step step = new RepaymentScheduleWrapper.Step();
        step.stepNumber = 1;
        step.tenorSplitPerc = 50;
        step.emiSplitPerc = 50;
        step.installments = 12;
        step.steppedEMI = 100;
        step.stepSpecifier = 'Step1';
        step.autoCal = true;
        step.version = 1;
        
        wrapper.step = new List<RepaymentScheduleWrapper.Step>{ step };
            
            // Serialize and Deserialize to hit JSON path
            String jsonStr = JSON.serialize(wrapper);
        RepaymentScheduleWrapper deserialized = (RepaymentScheduleWrapper) JSON.deserialize(jsonStr, RepaymentScheduleWrapper.class);
        
        System.assertEquals('FIN123', deserialized.finReference);
        System.assertEquals(1, deserialized.fees.size());
        System.assertEquals(1, deserialized.schedules.size());
        System.assertEquals('00', deserialized.returnStatus.returnCode);
        System.assertEquals('Step1', deserialized.step[0].stepSpecifier);
    }
*/
}