@isTest
public class Hl_EligibilityControllerTest {
    
    @testSetup
    static void setupData() {
        // Create Loan Application record
        Opportunity loanApp = TestDataFactory.getTestOpportunityData(1, true)[0];
        
         PLF_Master__c mas = new PLF_Master__c(
                Name = 'test',
                Master_Type__c = 'Program types',
                Description__c = 'Manufacturing',
                FICO_Code__c = 'Manu',
                Gender_Code__c = 'BD',
                Customer_Type__c = 'SENP',
                isActive__c = true,
                Applicant_Type__c = 'Individual'
            );
        insert mas;

        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = loanApp.Id,
            First_Name__C ='test',
            Middle_Name__c = '001',
            Last_Name__C ='Record',
            Customer_Type__c = 'Individual',
            Employment_Type__c = 'Salaried',
            Is_Key_Applicant__c = true,
            DOB__c = Date.newInstance(2000, 2, 2),
            Applicant_Type__c = 'Primary Applicant',
            PAN_Number__c = 'BYWPD1897T',
            Mobile_Number__c = '9823456781',
            Drivers_License_Number__c = 'YQ2243KKO',
            Passport_Number__c = 'PW872W',
            Aadhaar_Number__c = '910292039220',
            Voter_ID_Number__c = 'YIQIH28328A',
             IsForm60Uploaded__c = 'Yes',
              Is_Financial_applicant__c = 'Yes',
              Customer_Profile__c = 'SENP'
        );
        insert applicant;
                Application_Applicant__c applicant1 = new Application_Applicant__c(
            Loan_Application__c = loanApp.Id,
            First_Name__C ='test',
            Last_Name__C ='Record 1',
            DOB__c=Date.newInstance(2000, 2, 2),
            Customer_Type__c = 'Individual',
            Employment_Type__c = 'Salaried',
            Is_Key_Applicant__c = true,
            PAN_Number__c=null
        );
         insert applicant1;
        
    }
    
    @isTest
    static void testGetApplicants() {
        // Fetch the Loan Application created in setup
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<Hl_EligibilityController.ApplicationWrap> result = Hl_EligibilityController.getApplicants(loanApp.Id);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(0, result.size(), 'Result should not be empty');
        System.assertNotEquals(null, result[0].appName, 'Application name should be populated');
        System.assertNotEquals(null, result[0].options, 'Options should be available');
        
        // Optional: deeper assertions
        Boolean foundPrimary = false;
        for(Hl_EligibilityController.ApplicationWrap wrap : result) {
            if(wrap.appName.contains('Primary Applicant')) {
                foundPrimary = true;
                break;
            }
        }
        System.assert(foundPrimary, 'Primary Applicant should be present');
    }
}