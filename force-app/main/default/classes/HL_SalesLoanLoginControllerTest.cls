@isTest
Private class HL_SalesLoanLoginControllerTest {
 @testSetup
    static void setupTestData() {
        
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Corp',
            Status = 'Open - Not Contacted',
            Product__c = 'Home Loan',
            MobilePhone = '9876543210',
            Customer_Type__c = 'Individual'
        );
        insert lead;

        // Create Opportunity (Loan Application)
        Opportunity opp = new Opportunity(
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Lead__c = lead.Id,
            Product__c='Home Loan'
        );
        insert opp;

        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Mobile_Number__c = '9876543210',
            PAN_Number__c = 'ABCDE1234F',
            DOB__c = Date.newInstance(1990, 1, 1),
            Gender__c = 'Male',
            Loan_Application__c = opp.Id
        );
        insert applicant;
        Trigger_Settings__c ts = new Trigger_Settings__c();
        ts.City_Master_Trigger__c=true;
        ts.Name='Trigger Settings';
        insert ts;
        

        City_Master__c city= new City_Master__c(
            City_Code__c= 'MMB',
            Country__c= 'IN',
            State__c='MH' ,
            Name = 'Mumbai'  
        );
        insert city;

        Pincode_Master__c pincode= new Pincode_Master__c(
            Name = '400066',
            City__c = city.Id
        );
        insert pincode;
        // Create Address
        Applicant_Address__c address = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Landmark__c = 'Near Park',
            Building_Street_Name__c = 'Main Street',
            Pincode__c = pincode.Id
        );
        insert address;

        // Create Integration_Details__c with required field
        Integration_Details__c intDetail = new Integration_Details__c(
            Name = 'Test Detail',
            Endpoint__c = 'https://test.endpoint.com'
        );
        insert intDetail;
    }

    @isTest
     static void deletePanDetails() {
         
          Application_Applicant__c applicant = [SELECT Id, Loan_Application__c FROM Application_Applicant__c  LIMIT 1];
          Test.startTest();
          Map<String,String> inputMap = new Map<String,String>();
             inputMap.put('applicantId',applicant.id);
             HL_SalesLoanLoginController.deletePanDetails(inputMap);
          Test.stopTest();
         
     }
}