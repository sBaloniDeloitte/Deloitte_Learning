@isTest
public class AHL_LoanTransactionController_Test {
    @TestSetup
    static void makeData(){
        Account branch = FITestDataFactory.createAccount('Test Branch', 'Branch');
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,branch);
        
        FITestDataFactory.CreateLoanTransactiondata(loanApplication);
        FITestDataFactory.createInsurance(true,loanApplication.Id);
        Screen_Field__c parentScreenField = new Screen_Field__c(
            Form_Name__c = 'Payment Details Accordian',
            Master_Screen_Name__c = 'Payment Details Accordian',
            Is_Active__c = true,
            Is_Screen_Active__c = true,
            Field_Label__c = 'Test Label',
            Read_Field_Name__c = 'Mobile Number',
            Storage_Field__c = 'Mobile_Number__c',
            Storage_Object__c = 'Loan_Transaction__c',
            is_Lookup__c = true
        );
        insert parentScreenField;
        
        Screen_Field__c parentScreenField2 = new Screen_Field__c(
            Form_Name__c = 'Test Parent',
            Master_Screen_Name__c = 'Test Parent',
            Is_Active__c = true,
            Is_Screen_Active__c = true,
            Field_Label__c = 'Test Label',
            Read_Field_Name__c = 'Mobile Number',
            Storage_Field__c = 'Customer_Name__c',
            Storage_Object__c = 'Loan_Transaction__c',
            is_Lookup__c = true
        );
        insert parentScreenField2; 
        
        Screen_Field__c parentScreenField3 = new Screen_Field__c(
            Form_Name__c = 'Test Parent 3',
            Master_Screen_Name__c = 'Test Parent 3',
            Is_Active__c = true,
            Is_Screen_Active__c = true,
            Field_Label__c = 'Test Label',
            Read_Field_Name__c = 'Address',
            Storage_Field__c = 'Account_Number__c',
            Storage_Object__c = 'Loan_Transaction__c',
            is_Lookup__c = true
        );
        insert parentScreenField3;   
        
        Screen_Field__c screenField = new Screen_Field__c(
            Screen_Name__c = 'Payment-Beneficiary Details',
            Form_Name__c = 'Payment-Beneficiary Details',
            Is_Active__c = true,
            Is_Screen_Active__c = true,
            Parent_Screen__c = parentScreenField.Id,
            Field_Label__c = 'Test Label',
            Read_Field_Name__c = 'Mobile Number',
            Storage_Field__c = 'Account_Type__c',
            Storage_Object__c = 'Loan_Transaction__c',
            is_Lookup__c = true
        );
        insert screenField;
        
        Screen_Field__c screenField2 = new Screen_Field__c(
            Screen_Name__c = 'Test',
            Form_Name__c = 'Test',
            Is_Active__c = true,
            Is_Screen_Active__c = true,
            Parent_Screen__c = parentScreenField2.Id,
            Field_Label__c = 'Test Label',
            Read_Field_Name__c = 'Branch',
            Storage_Field__c = 'Account_Type__c',
            Storage_Object__c = 'Loan_Transaction__c',
            is_Lookup__c = true
        );
        insert screenField2;
        
        Screen_Field__c screenField3 = new Screen_Field__c(
            Screen_Name__c = 'Test2',
            Form_Name__c = 'Test2',
            Is_Active__c = true,
            Is_Screen_Active__c = true,
            Parent_Screen__c = parentScreenField3.Id,
            Field_Label__c = 'Test Label',
            Read_Field_Name__c = 'Address',
            Storage_Field__c = 'Account_Type__c',
            Storage_Object__c = 'Loan_Transaction__c',
            is_Lookup__c = true
        );
        insert screenField3;
        
        Charges_Insurance__c charges = new Charges_Insurance__c(
            Loan_Application__c = loanApplication.Id,
            Fee_Method__c = 'POSP',
            Final_Amount_INR__c = 4000,
            Insurance_Premium__c = 1000,
            Self_Funded__c = true,
            RecordTypeId = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName().get('Charges').getRecordTypeId()
        );
        insert charges;
        
        ContentVersion contentVersion_1 = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion_1;
        
        Loan_Transaction__c loanTxn = new Loan_Transaction__c(
            Loan_Application__c = loanApplication.Id,
            RecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByName().get('Payment').getRecordTypeId(),
            Net_Amount__c = 98500
        );
        
        insert loanTxn;
        
        
        // Create Builder
        Builder__c builder = new Builder__c(Name = 'Test Builder');
        insert builder;

        // Create Project
        Project__c project = new Project__c(Name = 'Test Project'
                                           ,RecordTypeId = Schema.SObjectType.Project__C.getRecordTypeInfosByName().get('Project').getRecordTypeId());
        insert project;

        // Create Collateral
        Collateral__c collateral = new Collateral__c(
            Builder__c = builder.Id,
            Project__c = project.Id
        );
        insert collateral;

        // Create Application Collateral
        Application_Collateral__c appCollateral = new Application_Collateral__c(
            HL_Loan_Application__c = loanApplication.Id,
            Collateral__c = collateral.Id
        );
        insert appCollateral;

        // Create Application Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            Loan_Application__c = loanApplication.Id,
            Mobile_Number__c = '9876543210'
        );
        insert applicant;

        // Create Bank Master
        Bank_Branch_Master__c bankMaster = new Bank_Branch_Master__c(
            Name = 'Test Bank',
            IFSC__c = 'TEST0001234',
            MICR__c = '123456789',
            Branch_Name__c = 'Test Branch',
            Branch_Location__c = 'Test City',
            Bank_Name__c  = 'AXIS Bank'
        );
        insert bankMaster;

        // Create Bank Details
        Bank_Details__c bankDetail = new Bank_Details__c(
            Name = 'Test Bank Detail',
            Account_Holder_Name__c = 'John Doe',
            Project_Name__c = project.Id,
            Application_Applicant__c = applicant.Id,
            Bank_Master__c = bankMaster.Id,
            Is_Repayment_Account__c = true
        );
        insert bankDetail;
    
    }
    
    @isTest
    public static void getScreenDetails_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Screen_Field__c screenField = [SELECT Id FROM Screen_Field__c WHERE Form_Name__c = 'Payment Details Accordian' LIMIT 1];
        Test.startTest();
        List<Screen_Field__c> result = AHL_LoanTransactionController.getScreenDetails('Payment Details Accordian',loanApplication.Id);
        Boolean res = AHL_LoanTransactionController.getDisburmentPartyRecord('Builder',loanApplication.Id);
        Boolean res2 = AHL_LoanTransactionController.getDisburmentPartyRecord('Primary Applicant',loanApplication.Id);
        Test.stopTest();
    }
    
    @isTest
    public static void getDetailsForDisbursement_test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Screen_Field__c screenField = [SELECT Id FROM Screen_Field__c WHERE Screen_Name__c = 'Payment-Beneficiary Details' LIMIT 1];
        Loan_Transaction__c loanTransaction = [SELECT Id,Loan_Application__c FROM Loan_Transaction__c LIMIT 1];

        try{
            Test.startTest();
            AHL_LoanTransactionController.getDetailsForDisbursement('Payment-Beneficiary Details',loanApplication.Id,'Payment Details Accordian');
            AHL_LoanTransactionController.getDetailsForPayment('Payment-Beneficiary Details',loanApplication.Id,'Payment Details Accordian');
            AHL_LoanTransactionController.getDetailsForBank(loanApplication.Id,'Payment Details Accordian');
            AHL_LoanTransactionController.getPaymentRecord('Payment-Beneficiary Details',loanApplication.Id,'Payment Details Accordian',loanTransaction.Id);
            AHL_LoanTransactionController.getPaymentRecord('Test',loanApplication.Id,'Test Parent',loanTransaction.Id);
            Test.stopTest();
        }catch(exception ex){
 
        }        
        
    }
    
    @isTest
    public static void getDetailsForDisbursement_test2(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Screen_Field__c screenField = [SELECT Id FROM Screen_Field__c WHERE Screen_Name__c = 'Test2' LIMIT 1];
        try{
            Test.startTest();
            AHL_LoanTransactionController.getDetailsForDisbursement('Test2',loanApplication.Id,'Test Parent 3');
            Test.stopTest();
        }catch(exception ex){
 
        }        
        
    }
    
    @isTest
    public static void getDetailsForDisbursement_test3(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Screen_Field__c screenField = [SELECT Id FROM Screen_Field__c WHERE Screen_Name__c = 'Test' LIMIT 1];
        try{
            Test.startTest();
            AHL_LoanTransactionController.getDetailsForDisbursement('Test',loanApplication.Id,'Test Parent');
            Test.stopTest();
        }catch(exception ex){
 
        }        
        
    }
    
    @isTest
    public static void getNextPaymentSequence_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        Decimal result = AHL_LoanTransactionController.getNextPaymentSequence(loanApplication.Id);
        System.assertEquals(1 ,result,'Payment Sequence is not matching');
        Test.stopTest();
    }
    
    @isTest
    public static void getPaymentTableRecords_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        AHL_LoanTransactionController.getPaymentTableRecords(loanApplication.Id);
        AHL_LoanTransactionController.updateFirstDisbursementAmount(loanApplication.Id,1000.00,1000.00);
        Test.stopTest();
    }
    
    @isTest
    public static void getApplicantsForLoan_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        List<String> applicantTypes = new List<String>{'Primary','Co-Applicant'};
        Test.startTest();
        AHL_LoanTransactionController.getApplicantsForLoan(loanApplication.Id, applicantTypes); //20- Aug
        Test.stopTest();
    }
    
    @isTest
    public static void getApplicantsForBuilderApf_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        AHL_LoanTransactionController.getApplicantsForBuilderApf(loanApplication.Id); //20- Aug
        Test.stopTest();
    }
    
    @isTest
    public static void getBankDetailsForBuilderApf_Test(){
        Application_Collateral__c appCollateral = [SELECT Id FROM Application_Collateral__c LIMIT 1];
        Test.startTest();
        AHL_LoanTransactionController.getBankDetailsForBuilderApf(appCollateral.Id); //20- Aug
        Test.stopTest();
    }
    
    @isTest
    public static void savePaymentTransaction_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Bank_Details__c bank= [SELECT Id FROM Bank_Details__c LIMIT 1];
        Map<String, Object> paymentRecordData = new Map<String, Object>();
        String loanId= loanApplication.Id;
        //{"Payment_Sequence__c":3,"Disbursement_Party__c":"Customer","Scheduled_Disbursement_Date__c":"2025-04-16","Disbursement_Date__c":"","Disbursement_Amount__c":"900","Partner_bank__c":"154","Net_Amount__c":900,"Total_Fee__c":0,"Remark__c":"","Disbursement_Type__c":"RTGS"}
        paymentRecordData.put('Payment_Sequence__c','3');
        paymentRecordData.put('Disbursement_Party__c','Customer');
        paymentRecordData.put('Scheduled_Disbursement_Date__c','2025-04-16');
        paymentRecordData.put('Disbursement_Type__c','RTGS');
        paymentRecordData.put('Disbursement_Amount__c','900');
        paymentRecordData.put('Partner_bank__c','154');
        paymentRecordData.put('Net_Amount__c','900');
        paymentRecordData.put('Total_Fee__c','0');
        
        Map<String, Object> beneficiaryData = new Map<String, Object>();
        beneficiaryData.put('Customer_Type__c','Primary Applicant');
        beneficiaryData.put('Application_Applicant__c',loanApplication.Id);
        beneficiaryData.put('Customer_Name__c','');
        beneficiaryData.put('IFSC__c','Axis Bank Hyderabad');
        beneficiaryData.put('Bank__c','AXIS Bank');
        beneficiaryData.put('Bank_Branch__c','Hyderabad');
        beneficiaryData.put('Account_Number__c','900');
        beneficiaryData.put('Account_Holder_Name__c','ASCER');
        
        Map<String, Object> chequeDDData = new Map<String, Object>();
        chequeDDData.put('Issuing_Bank_Location__c','GODREJ FINANCE LTD');
        chequeDDData.put('Application_Applicant__c','');
        chequeDDData.put('Payable_Location__c','GODREJ FINANCE LTD');
        chequeDDData.put('Printing_Location__c','Kolkata');
        chequeDDData.put('Value_Date__c','2025-04-15');
        chequeDDData.put('Cheque_DD_Number__c','1000');
        
        Test.startTest();
        AHL_LoanTransactionController.savePaymentTransaction(paymentRecordData,beneficiaryData,chequeDDData,loanId, bank.Id);
        Test.stopTest();
    }
    
    
    @isTest
    public static void savePaymentTrans_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        String loanId= loanApplication.Id;
        Bank_Details__c bank= [SELECT Id FROM Bank_Details__c LIMIT 1];
        Map<String, Object> paymentRecordData = new Map<String, Object>();
        //{"Payment_Sequence__c":3,"Disbursement_Party__c":"Customer","Scheduled_Disbursement_Date__c":"2025-04-16","Disbursement_Date__c":"","Disbursement_Amount__c":"900","Partner_bank__c":"154","Net_Amount__c":900,"Total_Fee__c":0,"Remark__c":"","Disbursement_Type__c":"RTGS"}
        paymentRecordData.put('Payment_Sequence__c','3');
        paymentRecordData.put('Disbursement_Party__c','Third Party');
        paymentRecordData.put('Scheduled_Disbursement_Date__c','2025-04-16');
        paymentRecordData.put('Disbursement_Type__c','RTGS');
        paymentRecordData.put('Disbursement_Amount__c','900');
        paymentRecordData.put('Partner_bank__c','154');
        paymentRecordData.put('Net_Amount__c','900');
        paymentRecordData.put('Total_Fee__c','0');
        
        Map<String, Object> beneficiaryData = new Map<String, Object>();
        beneficiaryData.put('Customer_Type__c','Primary Applicant');
        beneficiaryData.put('Application_Applicant__c',loanApplication.Id);
        beneficiaryData.put('Customer_Name__c','');
        beneficiaryData.put('IFSC__c','Axis Bank Hyderabad');
        beneficiaryData.put('Bank__c','AXIS Bank');
        beneficiaryData.put('Bank_Branch__c','Hyderabad');
        beneficiaryData.put('Account_Number__c','900');
        beneficiaryData.put('Account_Holder_Name__c','ASCER');
        
        Map<String, Object> chequeDDData = new Map<String, Object>();
        chequeDDData.put('Issuing_Bank_Location__c','GODREJ FINANCE LTD');
        chequeDDData.put('Application_Applicant__c','');
        chequeDDData.put('Payable_Location__c','GODREJ FINANCE LTD');
        chequeDDData.put('Printing_Location__c','Kolkata');
        chequeDDData.put('Value_Date__c','2025-04-15');
        chequeDDData.put('Cheque_DD_Number__c','1000');
        
        Test.startTest();
        AHL_LoanTransactionController.savePaymentTransaction(paymentRecordData,beneficiaryData,chequeDDData,loanId, bank.Id);
        Test.stopTest();
    }
    
    @isTest
    public static void getInsuranceAmount_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Loan_Transaction__c lt = [SELECT ID from Loan_Transaction__c WHERE Loan_Application__c =:loanApplication.Id LIMIT 1];
        Test.startTest();
        Decimal result = AHL_LoanTransactionController.getInsuranceAmount(loanApplication.Id);
        AHL_LoanTransactionController.getLoanStartDate(loanApplication.Id);
        System.assertEquals(9,result,'Insurance Amount is not matching');
        Test.stopTest();
    }
    
    @isTest
    public static void getDisbursalDetails_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        AHL_LoanTransactionController.getDisbursalDetails(loanApplication.Id);
        Test.stopTest();
    }
    
    @isTest
    public static void getTotalFee_Test(){
        
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        
         Charges_Insurance__c charges = new Charges_Insurance__c(
            Loan_Application__c = loanApplication.Id,
            Fee_Method__c = 'POSP',
            Final_Amount_INR__c = 4000,
            Insurance_Premium__c = 1000,
            Self_Funded__c = false,
            Name = 'Total Charges',
            RecordTypeId = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName().get('Charges').getRecordTypeId()
        );
        insert charges;
        try{
        	Test.startTest();
        	AHL_LoanTransactionController.getTotalFee(loanApplication.Id);
        	Test.stopTest();
        }catch(Exception e){}
    }
    
    @isTest
    public static void uploadFile_Test(){
        Opportunity loanApplication = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        AHL_LoanTransactionController.uploadFile('Test','Test','Doc',loanApplication.Id,'123');
        Test.stopTest();
    }
    
    
    @isTest
    public static void deletePaymentRecord_Test(){
        Loan_Transaction__c loanTransaction = [SELECT Id,Loan_Application__c FROM Loan_Transaction__c LIMIT 1];
        Test.startTest();
        String result = AHL_LoanTransactionController.deletePaymentRecord(loanTransaction.Id);
        System.assertEquals('SUCCESS',result,'Delete did not happen successfully!');
        Test.stopTest();
        
    }
    
    @isTest
    public static void deletePaymentRecordError_Test(){
        Test.startTest();
        String result = AHL_LoanTransactionController.deletePaymentRecord('');
        System.assertEquals('ERROR: Invalid Payment Record ID.',result,'Payment record was found');
        Test.stopTest();
    }
    
    @isTest
    public static void getPicklistValues_test(){
        Test.startTest();
        AHL_LoanTransactionController.getPicklistValues('Loan_Transaction__c','Disbursement_Type__c');
        Test.stopTest();
    }
    @isTest static void getPicklistValuesNegativeTest(){
        Test.startTest();
        try{
            AHL_LoanTransactionController.getPicklistValues('Loan_Transacon__c','Disbursement_Type__c');
        }catch(Exception ex){}
         try{
            AHL_LoanTransactionController.getPicklistValues('Loan_Transacon__c','Disbut_Type__c');
         }catch(Exception ex){}
        Test.stopTest();
    }
    @isTest static void getPicklistValuesNegative1Test(){
        Test.startTest();
         try{
            AHL_LoanTransactionController.getPicklistValues('Loan_Transacon__c','Disbut_Type__c');
         }catch(Exception ex){}
        Test.stopTest();
    }
    @isTest
    public static void getUploadedDocument_test(){
        ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion LIMIT 1]; 
        
        Test.startTest();
        AHL_LoanTransactionController.getUploadedDocument(contentVersion_2.ContentDocumentId);
        Test.stopTest();
    }
    
     @isTest
    public static void updateDisbursementDate_test(){
        Loan_Transaction__c loanTransaction = [SELECT Id,Loan_Application__c FROM Loan_Transaction__c LIMIT 1];
        String loanTransId = loanTransaction.Id;
        Test.startTest();
        Boolean result = AHL_LoanTransactionController.updateDisbursementDate(loanTransId);
        AHL_LoanTransactionController.getUploadedDocumentPerLT(loanTransId);
        System.assertEquals(true,result);
        Test.stopTest();
    }
    @isTest static void saveBankDetailRecordTest(){
        Bank_Branch_Master__c  bankMaster = [SELECT Id FROM Bank_Branch_Master__c LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Application_Collateral__c appCollateral = [SELECT Id FROM Application_Collateral__c LIMIT 1];
        List<Bank_Details__c> bankDetails = TestDataFactory.getTestBankDetailsData(1, applicant.Id, bankMaster.Id, false);
        Test.startTest();
        AHL_LoanTransactionController.saveBankDetailRecord(bankDetails[0], applicant.Id);
         AHL_LoanTransactionController.saveBankDetailRecord(null, applicant.Id);
        Test.stopTest();
    }
    @isTest static void saveBankDetailRecord2Test(){
        Bank_Branch_Master__c  bankMaster = [SELECT Id FROM Bank_Branch_Master__c LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Application_Collateral__c appCollateral = [SELECT Id FROM Application_Collateral__c LIMIT 1];
        List<Bank_Details__c> bankDetails = TestDataFactory.getTestBankDetailsData(1, applicant.Id, bankMaster.Id, false);
        Test.startTest();
        AHL_LoanTransactionController.saveBankDetailRecord(bankDetails[0], appCollateral.Id);
        Test.stopTest();
    }
}