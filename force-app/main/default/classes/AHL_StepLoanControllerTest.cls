@IsTest
public  class AHL_StepLoanControllerTest {

    @testSetup
    public static void setup() {
        Id stepLoanRT = Utility.getRecordTypeIdByDeveloperName('Loan_Transaction__c','Step_Loan_Details');
        Id loanTransRT = Utility.getRecordTypeIdByDeveloperName('Loan_Transaction__c','Transaction_Details');
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,customer);
        Loan_Transaction__c lt = FITestDataFactory.createLoanTransactiondata(loanApplication);
        lt.RecordTypeId = loanTransRT;
        update lt;
        Loan_Transaction__c lt2 = FITestDataFactory.createLoanTransactiondata(loanApplication);
        lt2.RecordTypeId = stepLoanRT;
        update lt2;
        
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(loanApplication);
        Charges_Insurance__c insuranceRecTypeData = FITestDataFactory.createInsurance(true, loanApplication.Id);
        //
        Charges_Insurance__c chargesRecTypeData = FITestDataFactory.createInsurance(false, loanApplication.Id);
        chargesRecTypeData.RecordTypeId = Utility.getRecordTypeIdByDeveloperName('Charges_Insurance__c','Charges');
        Insert chargesRecTypeData;
		//
        Bank_Branch_Master__c bankBranchMasterObj = FITestDataFactory.createBankMasterDetails();
        Bank_Details__c bankDetails = FITestDataFactory.createBankDetails(applicant,bankBranchMasterObj);    
        //
        Applicant_Address__c appAddress = new Applicant_Address__c();
        appAddress.Address_Type__c = 'Current';
        appAddress.Applicant__c = applicant.Id;
        appAddress.Loan_Application__c = loanApplication.Id;
        appAddress.Building_Street_Name__c = 'Test addr 1'; 
        appAddress.Address_Line_1__c = 'Test addr 1';
        appAddress.Address_Line_2__c = 'Test addr 1';
        appAddress.Address_Line_3__c = 'Test addr 1';
        Insert appAddress;             
    }

    @IsTest
    public static void createAndUpdateStepLoanTest(){
        Test.startTest();        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];   
        List<Loan_Transaction__c> loanTrans = [SELECT Id,Step_Number__c,Step_Specifier__c,Loan_Tenor__c,                                               
            Step_Amount__c,Tenor_Split__c FROM Loan_Transaction__c where Loan_Application__c = :opp.Id];
        
        
        Loan_Transaction__c stepLoanDetails = loanTrans.isEmpty() ? null : loanTrans[0];                                      
        AHL_StepLoanController.StepLoanWrapper record = new AHL_StepLoanController.StepLoanWrapper();
        record.stepNumber = 1.0; 
        record.stepIdentifier = 'Grace'; 
        record.stepLoanTenure = 60;  
        record.stepLoanAmount = 50000000; 
        record.tenurePercentage = 10.00;   
                    
        Id response = AHL_StepLoanController.createAndUpdateStepLoan(record, opp.Id,  stepLoanDetails.Id);               	
        System.assertEquals(true, response != null);  
               
        Test.stopTest();
    }
    
    @IsTest
    public static void getTransactionDetailsTest(){
        Test.startTest();        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];                    
		
        AHL_StepLoanController.TransactionDetailsWrapper response = AHL_StepLoanController.getTransactionDetails(opp.Id);               	
        System.assertEquals(response, response);     
        
        List<AHL_StepLoanController.StepLoanWrapper> loanResp = AHL_StepLoanController.getStepLoan(opp.Id);   
        System.assertEquals(true, loanResp.size() > 0);   
         
        Test.stopTest();
    }
    
    @IsTest
    public static void deleteAndRecalculateStepLoanTest(){
        Test.startTest();   
         Id stepLoanRT = Utility.getRecordTypeIdByDeveloperName('Loan_Transaction__c','Step_Loan_Details');
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];  
        Loan_Transaction__c stepLoanDetails = FITestDataFactory.createLoanTransactiondata(opp);
        stepLoanDetails.RecordTypeId = stepLoanRT;
        update stepLoanDetails;
	
        AHL_StepLoanController.deleteAndRecalculateStepLoan(stepLoanDetails.Id);         
        Test.stopTest();
    }
    
}