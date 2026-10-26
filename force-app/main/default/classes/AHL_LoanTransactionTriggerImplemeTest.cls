// @isTest class AHL_LoanTransactionTriggerImplemeTest {
    
//     @testSetup static void dataSetup(){
//         Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
//         List<Application_Applicant__c> applicants = AHL_LoanApplicationActionController.getApplicantsByLoanApplication(loanApp.Id);
//         AHL_LoanApplicationActionController.sanctionLetterGeneratedValidation(loanApp.Id);
//         Document_Details__c dd= TestDataFactory.getTestDocumentDetailsData(1, loanApp.Id, false)[0];
//         dd.Name = 'Sanction Letter';
//         dd.Active__c = true;
//         insert dd;
//         RecordType rt = [
//             SELECT Id 
//             FROM RecordType 
//             WHERE SObjectType = 'Loan_Transaction__c' 
//             AND DeveloperName = 'Transaction_Details' 
//             LIMIT 1
//         ];
//         Loan_Transaction__c loanTxn = new Loan_Transaction__c(
//             Loan_Application__c = loanApp.Id,
//             RecordTypeId = rt.Id,
//             Disbursement_Amount__c = 100000,
//             Allow_Payment_in_Grace_Period__c = true,
//             Allow_Grace__c = true,
//             TDS_Applicable__c = true,
//             Step_Loan__c = false,
//             Grace_Period_Frequency__c = 1, 
//             Interest_Frequency__c = 'Q',     
//             Allow_BPI__c = true,
//             Allow_Planned_EMI_Holiday__c = true,
//             Allow_Planned_EMI_Holiday_in_Grace__c = false,
//             Capitalize__c = true,
//             Loan_Start_Date__c = Date.today(),
//             Schedule_Method__c = 'PFT',         
//             Rate_Type__c = 'R',        
//             BPI_Treatment__c = 'N',         
//             Lock_Period_Months__c = 6
//         );
//         insert loanTxn;
//         new UpfrontFeeRequestWrapper();
//     }
//     @isTest static void test1(){
//         Loan_Transaction__c lt= [SELECT id,Loan_Application__c FROM Loan_Transaction__c];
//         AHL_LoanTransactionTriggerImplementation.preventUpdateIfPricingApprovedOrPending(new List<Loan_Transaction__c>{lt}, new Map<Id,Loan_Transaction__c>{lt.id=>lt});
        
//         User u = [select id ,Profile.Name,IsActive from user where Profile.Name = 'Sales' AND IsActive = true limit 1];
//         System.runAs(u){
//             AHL_LoanTransactionTriggerImplementation.preventUpdateIfPricingApprovedOrPending(new List<Loan_Transaction__c>{lt}, new Map<Id,Loan_Transaction__c>{lt.id=>lt});
//         }
//      }
    
//       
    
//    

@IsTest
public class AHL_LoanTransactionTriggerImplemeTest {

    @testSetup
    static void setupData() {

        TestDataFactory.setupIntegrationSettings('Create Disbursement');
        TestDataFactory.setupIntegrationSettings('Get Token');

        // User (assumes Sales profile exists)
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name = 'Sales' LIMIT 1];
        User salesUser = new User(
            Alias = 'salesu',
            Email = 'sales@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Sales',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = salesProfile.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            IsActive=true,
            UserName = 'salesuser_' + System.currentTimeMillis() + '@test.com'
        );
        insert salesUser;

        System.runAs(salesUser) {

            // Loan Application
            Opportunity loan = new Opportunity(
                Name = 'Test Loan',
                StageName = 'Credit',
                CloseDate = Date.today(),
                Pricing_Approval_Status__c = 'Approved',
                LMS_Loan_Reference__c = 'LMS123',
                Product__c= 'Home Loan'
            );
            insert loan;

            // Record Types
            Map<String, Id> rtMap = new Map<String, Id>();
            for (RecordType rt : [
                SELECT Id, DeveloperName
                FROM RecordType
                WHERE SobjectType = 'Loan_Transaction__c'
            ]) {
                rtMap.put(rt.DeveloperName, rt.Id);
            }

            // Loan Transaction (Payment)
            Loan_Transaction__c paymentTxn = new Loan_Transaction__c(
                Loan_Application__c = loan.Id,
                RecordTypeId = rtMap.get('Payment'),
                Loan_Tenor__c = 12,
                Interest_Frequency__c = 'M',
                Interest_Due_date__c = '06',
                QDP_Status__c = 'Print',
                Bank__c = 'Bank A'
            );
            insert paymentTxn;

            // Loan Transaction (Transaction_Details)
            Loan_Transaction__c detailTxn = new Loan_Transaction__c(
                Loan_Application__c = loan.Id,
                RecordTypeId = rtMap.get('Transaction_Details'),
                Quick_Disbursement__c = true,
                QDP_Status__c = 'Awaiting for confirmation'
            );
            insert detailTxn;
        }
    }

     public static  Loan_Transaction__c createlt(Id loanAppId,Id rtId){
        
        Loan_Transaction__c loanTxn = new Loan_Transaction__c(
            Loan_Application__c = loanAppId,
            RecordTypeId = rtId,
            Disbursement_Amount__c = 100000,
            Allow_Payment_in_Grace_Period__c = true,
            Allow_Grace__c = true,
            TDS_Applicable__c = true,
            Step_Loan__c = false,
            Grace_Period_Frequency__c = 1, 
            Interest_Frequency__c = 'Q',     
            Allow_BPI__c = true,
            Allow_Planned_EMI_Holiday__c = true,
            Allow_Planned_EMI_Holiday_in_Grace__c = false,
            Capitalize__c = true,
            Loan_Start_Date__c = Date.today(),
            Schedule_Method__c = 'PFT',         
            Rate_Type__c = 'R',        
            BPI_Treatment__c = 'N',         
            Lock_Period_Months__c = 6
        );
        return loanTxn;
    }

    @isTest static void test2(){
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        RecordType rt = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Loan_Transaction__c' 
            AND DeveloperName = 'Transaction_Details' 
            LIMIT 1
        ];
        List<String> fre= new List<String>{'M','Q','H','Y'};
            
            List<Loan_Transaction__c>  newRecords= new List<Loan_Transaction__c>();
        List<String> dueDate= new List<String>{'03','06','26'};
            Integer i =0;
        for(String str :fre){
            if(i>= dueDate.size()){
                i=0;
            }
            Loan_Transaction__c lt = createlt(loanApp.Id, rt.Id);
            lt.Interest_Frequency__c = str;
            lt.Interest_Due_date__c = dueDate[i++];
            lt.Loan_Tenor__c =67;
            newRecords.add(lt);
        }
        insert newRecords;
        Map<Id,Loan_Transaction__c> oldRecordsMap = new Map<Id,Loan_Transaction__c>();
        boolean isFirst = true;
        for(Loan_Transaction__c ltr : newRecords){
            oldRecordsMap.put(ltr.Id,ltr);
            if(isFirst){
                ltr.QDP_Status__c ='Print'; 
                isFirst = !isFirst;
            }

        }

        AHL_LoanTransactionTriggerImplementation.updateLoanTransactionFields(newRecords, oldRecordsMap);
    } 

    @IsTest
    static void testPreventUpdateForSalesProfile() {

        User salesUser = [SELECT Id FROM User WHERE Profile.Name = 'Sales' AND IsActive = true LIMIT 1];

        System.runAs(salesUser) {

           Loan_Transaction__c lt= [SELECT id,Loan_Application__c FROM Loan_Transaction__c LIMIT 1];

            lt.Loan_Tenor__c = 24;

            Test.startTest();
            AHL_LoanTransactionTriggerImplementation.preventUpdateIfPricingApprovedOrPending(new List<Loan_Transaction__c>{lt}, new Map<Id,Loan_Transaction__c>{lt.id=>lt});
            
            User u = [select id ,Profile.Name,IsActive from user where Profile.Name = 'Sales' AND IsActive = true limit 1];
            System.runAs(u){
                AHL_LoanTransactionTriggerImplementation.preventUpdateIfPricingApprovedOrPending(new List<Loan_Transaction__c>{lt}, new Map<Id,Loan_Transaction__c>{lt.id=>lt});
            }
            Test.stopTest();

            
           

        }
    }

    @IsTest
    static void testUpdateLoanTransactionFields() {

        Loan_Transaction__c txn = [
            SELECT Id, Loan_Tenor__c, Interest_Frequency__c
            FROM Loan_Transaction__c
            LIMIT 1
        ];

        txn.Interest_Frequency__c = 'Q';
        txn.Loan_Tenor__c = 12;

        Test.startTest();
        update txn;
        Test.stopTest();

    }

    @IsTest
    static void testHandleQDPProcessPrintAndFail() {

        List<Loan_Transaction__c> txns = [
            SELECT Id, Loan_Application__c
            FROM Loan_Transaction__c
        ];

        // One Print, one Failure
        txns[0].QDP_Status__c = 'Print';
        txns[1].QDP_Status__c = 'Rejected';

        Test.startTest();
        update txns;
        Test.stopTest();

    }

    @IsTest
    static void testHandleCreateDisbursement() {

        List<Loan_Transaction__c> txns = [
            SELECT Id
            FROM Loan_Transaction__c
        ];

        Test.startTest();
        AHL_LoanTransactionTriggerImplementation.handleCreateDisbursement(txns);
        Test.stopTest();

    }

    @IsTest
    static void testHandleAfterInsertPennyDrop() {

        List<Loan_Transaction__c> txns = [
            SELECT Id
            FROM Loan_Transaction__c
        ];

        Test.startTest();
        AHL_LoanTransactionTriggerImplementation.handleAfterInsertPennyDrop(txns);
        Test.stopTest();
    }

    @IsTest
    static void testHandleAfterUpdatePennyDrop() {

        Loan_Transaction__c txn = [
            SELECT Id, Bank__c
            FROM Loan_Transaction__c
            LIMIT 1
        ];

        Loan_Transaction__c oldTxn = txn.clone(false, true, false, false);
        txn.Bank__c = 'Bank B';

        Test.startTest();
        AHL_LoanTransactionTriggerImplementation.handleAfterUpdatePennyDrop(
            new List<Loan_Transaction__c>{ txn },
            new Map<Id, Loan_Transaction__c>{ txn.Id => oldTxn }
        );
        Test.stopTest();
    }
}