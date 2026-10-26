@isTest class AHL_CreateDisbursementServiceTest {
    //kalpesh added
    @testSetup 
    static void dataSetup(){
        Test.startTest();
        Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.getGlobalDescribe()
            .get('Charges_Insurance__c')
            .getDescribe()
            .getRecordTypeInfosByName();
        
        TestDataFactory.setupIntegrationSettings('Create Disbursement');
        TestDataFactory.setupIntegrationSettings('Get Token');
        List<Opportunity> opps= TestDataFactory.getTestOpportunityData(5, true);
        Id RecId=  [SELECT  Id FROM RecordType WHERE SobjectType = 'Loan_Transaction__c' AND DeveloperName ='Payment'].Id;
        Loan_Transaction__c loanTrans1 = new Loan_Transaction__c(Loan_Application__c = opps[0].Id, Loan_Tenor__c = 12, Interest_Frequency__c = 'M', RecordTypeId = RecId , QDP_Status__c = 'New',Scheduled_Disbursement_Date__c =SYSTEM.TODAY());
        Loan_Transaction__c loanTrans2 = new Loan_Transaction__c(Loan_Application__c = opps[1].Id, Loan_Tenor__c = 24, Interest_Frequency__c = 'Q',RecordTypeId = RecId, QDP_Status__c = 'New',Scheduled_Disbursement_Date__c =SYSTEM.TODAY().ADDdAYS(10) );
        insert new List<Loan_Transaction__c>{loanTrans1,loanTrans2};
            
            Application_Applicant__c applicant = new Application_Applicant__c(
                Name = 'John Doe',
                Loan_Application__c = opps[0].Id,
                Applicant_Type__c = 'Primary Applicant',
                Mobile_Number__c = '9876543210'
            );
        insert applicant;
        Map<String, Schema.RecordTypeInfo> masterRecordTypeMap = Schema.SObjectType.Charges_Insurance_Master__c.getRecordTypeInfosByName();
        Id vasProviderRecordTypeId = masterRecordTypeMap.get('VAS Provider').getRecordTypeId();
        Id insuranceMasterRecordTypeId = masterRecordTypeMap.get('Insurance').getRecordTypeId();

        Charges_Insurance_Master__c vasProviderMaster = new Charges_Insurance_Master__c(
            RecordTypeId = vasProviderRecordTypeId,
            Dealer_Telephone__c = '1234567890',
            Payment_Mode__c = 'NEFT',
            Account_Number__c = '9876543210',
            Partner_Bank_Id__c = 154 ,    
            VAS_Code__c ='VAS001'
        );
        insert vasProviderMaster;
        
        Charges_Insurance_Master__c insuranceMaster = new Charges_Insurance_Master__c(
            RecordTypeId = insuranceMasterRecordTypeId,
            VAS_Provider__c = vasProviderMaster.Id,
            VAS_Code__c ='VAS001'
        );
        insert insuranceMaster;
        
        Id insuranceRecordTypeId = recordTypeMap.get('Insurance').getRecordTypeId();
        Charges_Insurance__c insuranceRecord = new Charges_Insurance__c(
            Name = 'Insurance Record',
            RecordTypeId = insuranceRecordTypeId,
            Fee_Method__c = 'POSP',
            Loan_Amount__c = 1000000,
            Loan_tenure__c = 2,
            Policy_Tenure__c = 1,
            Charges_Insurance_Master__c = insuranceMaster.Id,
            Loan_Application__c = opps[0].Id,
            VAS_Code__c = 'VAS001',
            Charges_Fee_Type__c = 'PPMCHG',
            Insurance_Premium__c = 2000,
            Total_VAS_Amount__c = 2000,
            Application_Applicant__c = applicant.Id
        );
        insert insuranceRecord;
            
            PLF_Master__c mas = new PLF_Master__c(
                Name = 'test',
                Master_Type__c = 'Disbursement Party',
                Description__c = 'Manufacturing',
                FICO_Code__c = 'Manu',
                Gender_Code__c = 'BD'
            );
        insert mas;
        
        Test.stopTest();
        
    }
    @isTest static void callCreateDisbursementTest(){
        Set<Id> txnIds = new Set<Id>(); 
        for(Opportunity opp: [SELECT ID FROM Opportunity]){
            txnIds.add(opp.Id);
        }
        Test.startTest();
        try{
        Test.setMock(HttpCalloutMock.class, new CalloutMock());
        AHL_CreateDisbursementService.callCreateDisbursement(txnIds);
        }catch(Exception e){}
        Test.stopTest();   
        
    }
    
    
    class CalloutMock implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type','application/json');
            Map<String,Object> body = new Map<String,Object>();
            body.put('finReference','GHF1001HL0005309');
            body.put('returnStatus',new Map< String,String>{'returnCode'=>'009','returnText'=>'Success'});
            body.put('disbursements',new List<Object>());
            res.setBody(JSON.serialize(body));
            res.setStatusCode(200);
            return res;
        }
    }
    
}