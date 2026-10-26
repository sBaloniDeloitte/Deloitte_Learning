@IsTest
public class LoanLoginChangeApplicantTypeTest {
    
    // Stub utility class
    
    
    @TestSetup
    static void setupData() {
        // Create a dummy Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            Product__c = 'Home Loan',
            Exception_Approval_Status__c = 'Submitted For Approval'
        );
        insert opp;
        
         Id subProductRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Product').getRecordTypeId();   
        Id variantRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Variant').getRecordTypeId();       
        Id productRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Id SubVariantRT = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Variant').getRecordTypeId();
        
          Product2 prod = new Product2(Name = 'Home Loan', IsActive = true,Is_loan_VAS_only__c = true,Loan_Application__c = opp.Id,RecordTypeId = productRecordTypeId);
        insert prod;
        Product2 subprod = new Product2(Name = 'Home Loan', IsActive = true,Is_loan_VAS_only__c = true,Loan_Application__c = opp.Id,RecordTypeId = subProductRT,Product__c=prod.Id);
        insert   subprod;
        Product2 varient = new Product2(Name = 'Home Loan', IsActive = true,Is_loan_VAS_only__c = true,Loan_Application__c = opp.Id,RecordTypeId = variantRT,Product__c=subprod.Id);
        insert   varient;
        Product2 subvarient = new Product2(Name = 'Home Loan', IsActive = true,Is_loan_VAS_only__c = true,Loan_Application__c = opp.Id,RecordTypeId = SubVariantRT,Variant__c=varient.Id);
        insert   subvarient;
        
        // Create application applicants (2 sample)
        Application_Applicant__c app1 = new Application_Applicant__c(
            First_Name__c = 'John Primary',
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual',
            CIBIL_Score__c = 650,
            Loan_Application__c = opp.Id,
            Is_Key_Applicant__c = false,
            Is_Financial_applicant__c = 'Yes',
            Basic_Details_Filled__c = 'Yes',
            Customer_Profile__c = 'SEP',
            //Employer_Name__c = 'ABC Corp',
            Pan_Status__c = 'Valid',
            IsForm60Uploaded__c = 'No'
        );
        Application_Applicant__c app2 = new Application_Applicant__c(
            First_Name__c = 'Jane CoApp',
            Applicant_Type__c = 'Co Applicant',
            Customer_Type__c = 'Non Individual',
            CIBIL_Score__c = 750,
            Loan_Application__c = opp.Id,
            Is_Key_Applicant__c = true,
            Is_Financial_applicant__c = 'No',
            Basic_Details_Filled__c = 'Yes',
            Customer_Profile__c = 'SENP',
            Sector__c = 'Private Limited',
            Sub_Employment_Type_Non_Individual__c = 'Salaried',
            //Employer_Name__c = 'XYZ Ltd',
            Pan_Status__c = 'Valid',
            IsForm60Uploaded__c = 'Yes'
        );
        insert new List<Application_Applicant__c>{app1, app2};
            }
    
    
    
    @IsTest
    static void testGetConstants() {
        Test.startTest();
        Map<String, String> result = LoanLoginChangeApplicantTypeController.getConstants();
        Test.stopTest();
        System.assertNotEquals(null, result, 'Constants map should not be null');
    }
    
    @IsTest
    static void testApplicantDetails() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<LoanLoginChangeApplicantTypeController.ApplicantDetailsWrapper> wraps =
            LoanLoginChangeApplicantTypeController.applicantDetails(opp.Id);
        Test.stopTest();
        
        System.assert(!wraps.isEmpty(), 'Applicant details should be returned');
        System.assertNotEquals(null, wraps[0].applicantName);
    }
    
    @IsTest
    static void testSaveApplicantDetails() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app = [SELECT Id, Applicant_Type__c, Is_Key_Applicant__c FROM Application_Applicant__c LIMIT 1];
        
        // Prepare wrapper JSON
        List<LoanLoginChangeApplicantTypeController.ApplicantDetailsWrapper> wrapperList = new List<LoanLoginChangeApplicantTypeController.ApplicantDetailsWrapper>();
        LoanLoginChangeApplicantTypeController.ApplicantDetailsWrapper wrap = new LoanLoginChangeApplicantTypeController.ApplicantDetailsWrapper();
        wrap.applicantId = app.Id;
        wrap.applicantType = 'Primary Applicant';
        wrap.isKeyApplicant = true;
        wrapperList.add(wrap);
        
        String jsonStr = JSON.serialize(wrapperList);
        
        Test.startTest();
        LoanLoginChangeApplicantTypeController.saveApplicantDetails(jsonStr, true, opp.Id);
        LoanLoginChangeApplicantTypeController.saveApplicantDetails(jsonStr, false, opp.Id);
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT Exception_Approval_Status__c, Reasons_For_Execption_Approval__c FROM Opportunity WHERE Id = :opp.Id];
      //  System.assertEquals('Not started', updatedOpp.Exception_Approval_Status__c);
    }
    
    @IsTest
    static void testUpdateCibilException() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        LoanLoginChangeApplicantTypeController.updateCibilException(opp.Id);
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT Exception_Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
       // System.assertEquals('Not started', updatedOpp.Exception_Approval_Status__c);
    }
    
    @IsTest
    static void testCheckIfBureauIsFetched_Positive() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Customer_Type__c = 'Individual' LIMIT 1];
        Test.startTest();
        String message = LoanLoginChangeApplicantTypeController.checkifbureauisfetched(app.Id);
        Test.stopTest();
        System.assertEquals('', message, 'Should return empty message for valid applicant');
    }

     @IsTest
    static void testCheckIfBureauIsFetched_Positive2() {
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c WHERE Customer_Type__c = 'Non Individual' LIMIT 1];
        Test.startTest();
        String message = LoanLoginChangeApplicantTypeController.checkifbureauisfetched(app.Id);
        Test.stopTest();
        System.assertEquals('', message, 'Should return empty message for valid applicant');
    }
    
    @IsTest
    static void testCheckIfBureauIsFetched_MissingDetails() {
         Opportunity opp1 = [select id from opportunity limit 1];
           
        Application_Applicant__c app = new Application_Applicant__c(
            First_Name__c = 'Missing PAN',
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual',
            Loan_Application__c = opp1.Id,
             Customer_Profile__c = 'SENP',
            Sector__c = 'Private Limited',
            Sub_Employment_Type_Non_Individual__c = 'Salaried',
            Basic_Details_Filled__c = 'Yes'
        );
        insert app;
         
          Application_Applicant__c app1 = new Application_Applicant__c(
            First_Name__c = 'Jane CoApp',
            Applicant_Type__c = 'Co Applicant',
            Customer_Type__c = 'Non Individual',
            CIBIL_Score__c = 750,
            Loan_Application__c = opp1.Id,
            Is_Key_Applicant__c = true,
            Is_Financial_applicant__c = 'No',
            Basic_Details_Filled__c = 'Yes',
            
            
            Customer_Profile__c = 'SENP',
            Sector__c = 'Private Limited',
            Sub_Employment_Type_Non_Individual__c = 'Salaried',
            //Employer_Name__c = 'XYZ Ltd',
            Pan_Status__c = 'Valid',
            IsForm60Uploaded__c = 'Yes'
        );
        insert app1;
         Applicant_Address__c testPermanentAddress = new Applicant_Address__c(
            Applicant__c = app1.Id,
            Address_Type__c = 'Permanent',
            Address_Source__c = 'Aadhaar',
            Floor_Number__c = '1',
            Building_Street_Name__c = 'Street 1',
            Plot_Number__c = 'Plot 1',
           // Pincode__c = pinCodeRec.Id,
            Landmark__c = 'Landmark 1',
              Address_Priority__c='5'
          
        );
        insert testPermanentAddress;
        Test.startTest();
        String message = LoanLoginChangeApplicantTypeController.checkifbureauisfetched(app.Id);
       // LoanLoginChangeApplicantTypeController.checkAddressForGaurantor(opp1.id,app1.id);
        Test.stopTest();
        
        System.assert(message.contains('Please fill the basic details') || message.contains('bureau information'), 
                      'Should return error message for missing data');
    }
    
    public class Utility {
        public Map<String, String> getConstants(String labelName) {
            Map<String, String> constants = new Map<String, String>();
            constants.put('CIBIL_Score_Threshold', '700');
            return constants;
        }
    }
}