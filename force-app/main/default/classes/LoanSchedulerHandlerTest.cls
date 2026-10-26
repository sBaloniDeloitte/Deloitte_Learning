@isTest class LoanSchedulerHandlerTest {
    
    @testSetup static void dataSetup(){
        
        Opportunity opp= TestDataFactory.getTestOpportunityData(1, false)[0];
        opp.Name = 'Test Loan Opportunity';
        opp.StageName = 'Prospecting';
        opp.CloseDate = System.today().addDays(30);
        opp.Product__c='Home Loan';
        insert opp;
        
        TestDataFactory.setupIntegrationSettings('LoanProcess');
        
        // Create Charges_Insurance_Master__c
        Charges_Insurance_Master__c cim = new Charges_Insurance_Master__c(
            Tax__c = 5,
            Category__c = 'LMS',
            Min_Percent__c = 1,
            Max_Percent__c = 10
        );
        insert cim;
    }
    
    @isTest static void test1(){
        LoanSchedulerHandler.getConstants();
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        TestDataFactory.setupTriggerSettings();
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, false)[0];
        loanApp.Final_Amount__c= 196;
        loanApp.Sanction_Tenure__c =200;
        insert loanApp;
        
        City_Master__c city = TestDataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1,city.Id,true)[0];
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loanApp.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = loanApp.Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        applicant.Applicant_Type__c ='Primary Applicant';
        insert applicant;
        
        Map<String, String> inputMap = new Map<String, String>{
            'recordId' => loanApp.Id,
                'applicantId' => applicant.Id,
                'processName' => 'CalculateGST',
                'mobileNumber' => applicant.Mobile_Number__c,
                'isWaiverAmountCalc' => 'false'
                };
                    List<Integration_Master__mdt> metadataList = [
                        SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, 
                        Client_Id__c, Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, 
                        Refresh_Allowed__c, Activity_Name__c
                        FROM Integration_Master__mdt 
                        WHERE Activity_Name__c = 'CalculateGST' 
                        LIMIT 1
                    ];
        String loanId = inputMap.get('loanId');
        String processName = inputMap.get('processName');
        String feeType = inputMap.get('feeType');
        String waiverAmountCalcFlag = inputMap.get('isWaiverAmountCalc');
        Boolean isWaiverAmountCalc = Boolean.valueOf(waiverAmountCalcFlag);
        
        Integration_Master__mdt metadata = metadataList[0];
        // Prepare request wrapper
        wrapper.loanApplicationId = loanApp.Id;  
        wrapper.type = processName;
        wrapper.feeType = 'Insurance Record';
        wrapper.endpoint = metadata.Endpoint__c;
        wrapper.requestMethod = metadata.Request_Method__c;
        wrapper.handlerClass = metadata.Handler_Class__c;
        wrapper.clientId = metadata.Client_Id__c;
        wrapper.clientSecret = metadata.Client_Secret__c;
        wrapper.allowedRetry = metadata.Allowed_Retry__c;
        wrapper.gestationPeriod = metadata.Gestation_Period__c;
        wrapper.activityname = metadata.Activity_Name__c;
        wrapper.refreshallowed = metadata.Refresh_Allowed__c;
        wrapper.handlername = metadata.Handler_Class__c;
        wrapper.isWaiverAmountCalc = true;
        
        wrapper.loanSchedulerInvocationType ='RepaymentLWC';
        LoanSchedulerHandler.validatePayload(wrapper);
        Loan_Transaction__c loanTxn = new Loan_Transaction__c(
            Loan_Application__c = loanApp.Id,
            RecordTypeId = SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByDeveloperName()
            .get('Transaction_Details')
            .getRecordTypeId(),
            isActive__c = false,Step_Loan__c = true,Interest_Frequency__c= 'H',
            Allow_Grace__c = true,First_Disbursement_Amount__c= 45,
            Allow_BPI__c = true,Allow_Planned_EMI_Holiday__c = true,Allow_Planned_Principal_Holiday__c =true
        );
        insert loanTxn;
        LoanSchedulerHandler.validatePayload(wrapper);
        Integration_Details__c detail = new Integration_Details__c(
            Name = 'Loan Applicant Hunter',
            Loan_Application__c=loanApp.Id,
            Endpoint__c = 'https://test.salesforce.com/mock'
        );
        insert detail;
        
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Product2.getRecordTypeInfosByName();
        Id totalTenureRecordTypeId  = rtMap.get('Total Tenure').getRecordTypeId();
        Id hybridTenureRecordTypeId = rtMap.get('Hybrid Tenure').getRecordTypeId();
        Id schemeRecordTypeId       = rtMap.get('Scheme').getRecordTypeId();
        Id fullEMIRecordTypeId      = rtMap.get('Full EMI').getRecordTypeId();
        Id variantRecordTypeId      = rtMap.get('Variant').getRecordTypeId();
        Id subVariantRecordTypeId      = rtMap.get('Sub Variant').getRecordTypeId();
        Id productRT = rtMap.get('Product').getRecordTypeId();
        Id subProductRT = rtMap.get('Sub Product').getRecordTypeId();
        
        Product_Master__c prodM2 = new Product_Master__c(
            Name = 'Variant',
            PLF_Loan_Type__c ='FL',
            PLR_Value__c = 80.00,
            RecordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get('Variant').getRecordTypeId()
        );
        insert prodM2;
        
        Product2 mainProduct = TestDataFactory.createProductRecord(loanApp.Product__c, true);
        mainProduct.Product_Master__c = prodM2.Id;
        mainProduct.recordTypeId = productRT;
        mainProduct.Loan_Application__c = loanApp.Id;
        insert mainProduct;
        
        Product2 subProduct = new Product2(
            Name = 'Sub Product',
            isActive = true,
            Loan_Application__c = loanApp.Id,
            Product__c = mainProduct.Id,
            RecordTypeId =  subProductRT 
        );
        insert subProduct;
        
        
        
        List<Product2> productsToInsert = new List<Product2>();
        
        Product2 TotalTenure = new Product2(
            Name = 'Total Tenure',
            isActive = true,
            Loan_Application__c = loanApp.Id,
            Product__c = subProduct.Id,
            RecordTypeId = totalTenureRecordTypeId,
            Variant__c = mainProduct.Id,
            Sub_Variant__c = subProduct.Id
        );
        
        Product2 scRec=   new Product2(
            Name = 'Scheme Rec',
            isActive = true,
            Loan_Application__c = loanApp.Id,
            Product__c = subProduct.Id,
            RecordTypeId = schemeRecordTypeId,
            Variant__c = mainProduct.Id,
            Sub_Variant__c = subProduct.Id
        );
        Product2 varient=  new Product2(
            Name = 'Variant',
            isActive = true,
            Loan_Application__c = loanApp.Id,
            Product__c = subProduct.Id,
            RecordTypeId = variantRecordTypeId,
            EMI_Amount__c = 10000,
            Variant__c = mainProduct.Id,
            Sub_Variant__c = subProduct.Id
        );
        Product2 subVarient= new Product2(
            Name = 'Sub Variant',
            isActive = true,
            Loan_Application__c = loanApp.Id,
            Product__c = subProduct.Id,
            RecordTypeId = subVariantRecordTypeId,
            EMI_Amount__c = 10000,
            Variant__c = mainProduct.Id,
            Sub_Variant__c = subProduct.Id
        );
        Product2 fullemi =
            new Product2(
                Name = 'Full EMI',
                isActive = true,
                Loan_Application__c = loanApp.Id,
                Product__c = subProduct.Id,
                RecordTypeId = fullEMIRecordTypeId,
                EMI_Amount__c = 10000,
                Variant__c = mainProduct.Id,
                Sub_Variant__c = subProduct.Id
            );
        
        insert new list<Product2>{TotalTenure,scRec,subVarient,varient,fullemi};
            
            
            insert  new Product2(
                Name = '100',
                isActive = true,
                Loan_Application__c = loanApp.Id,
                Product__c = subProduct.Id,
                RecordTypeId = hybridTenureRecordTypeId,
                Variant__c = varient.Id,
                Sub_Variant__c = subVarient.Id
            );
        
        new LoanSchedulerHandler().constructPayload(wrapper, new List<Integration_Details__c>{detail});
        
        
    }
    
}