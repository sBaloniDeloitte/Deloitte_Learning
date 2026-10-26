@isTest
public class HL_DirectorDetailsControllerTest {
    
    @TestSetup
    static void setupTestData() {
        Opportunity loanApp = new Opportunity(
            Name = 'Test Loan Application',
            StageName = 'Credit Underwriting',
			Product__c ='Home Loan',
            CloseDate = Date.today().addMonths(6)
        );
        insert loanApp;
        
        Application_Applicant__c primaryApplicant = new Application_Applicant__c(
            Loan_Application__c = loanApp.Id,
            Applicant_Type__c = Constants.PRIMARY_APPLICANT,
            Customer_Type__c = 'Non Individual'
        );
        insert primaryApplicant;
        
        List<Company_Director_Details__c> directorsList = new List<Company_Director_Details__c>();
        for (Integer i = 1; i <= 3; i++) {
            Company_Director_Details__c director = new Company_Director_Details__c(
                Loan_Application__c = loanApp.Id,
                Director_Name__c = 'Test Director ' + i,
                Director_DIN_Number__c = 'DIN000000' + i,
                Percentage_of_Shareholding__c = 25.50 + i,
                Director_Designation__c = 'MD',
                Date_of_Appointment__c = Date.today().addYears(-2),
                Address_Section__c = 'Test Address ' + i
            );
            directorsList.add(director);
        }
        insert directorsList;
    }
    
    @isTest
    static void testFetchDirectorDetails_Success() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<Company_Director_Details__c> result = HL_DirectorDetailsController.fetchDirectorDetails(loanApp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(3, result.size(), 'Should return 3 director records');
        System.assertNotEquals(null, result[0].Director_Name__c, 'Director name should not be null');
    }
    
    @isTest
    static void testFetchDirectorDetails_BlankLoanId() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            HL_DirectorDetailsController.fetchDirectorDetails('');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown an AuraHandledException');
    }

    @isTest
    static void testFetchDirectorDetails_NullLoanId() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            HL_DirectorDetailsController.fetchDirectorDetails(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown an AuraHandledException');
    }
    
    @isTest
    static void testFetchDirectorDetails_InvalidLoanId() {
        Test.startTest();
        List<Company_Director_Details__c> result = HL_DirectorDetailsController.fetchDirectorDetails('001000000000000');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list for invalid loan id');
    }
    
    @isTest
    static void testSaveDirectorDetails_Success() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];

        Map<String, String> inputMap = new Map<String, String>{
            'Director_Name__c' => 'New Director',
            'Director_DIN_Number__c' => 'DIN999999',
            'Percentage_of_Shareholding__c' => '30.75',
            'Director_Designation__c' => 'MD',
            'Date_of_Appointment__c' => String.valueOf(Date.today()),
            'Address_Section__c' => 'New Address'
        };

        Test.startTest();
        String result = HL_DirectorDetailsController.saveDirectorDetails(inputMap, loanApp.Id);
        Test.stopTest();

        System.assertEquals('success', result, 'Save should return success');

        List<Company_Director_Details__c> savedDirectors = [
            SELECT Id, Director_Name__c, Percentage_of_Shareholding__c
            FROM Company_Director_Details__c
            WHERE Loan_Application__c = :loanApp.Id
            AND Director_Name__c = 'New Director'
        ];
        System.assertEquals(1, savedDirectors.size(), 'Should create one new director record');
        System.assertEquals(30.75, savedDirectors[0].Percentage_of_Shareholding__c, 'Should save decimal correctly');
    }

    @isTest
    static void testSaveDirectorDetails_WithMinimalValues() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];

        Map<String, String> inputMap = new Map<String, String>{
            'Director_Name__c' => 'Minimal Director',
            'Director_DIN_Number__c' => 'DIN888888',
            'Percentage_of_Shareholding__c' => '45',
            'Director_Designation__c' => 'MD',
            'Date_of_Appointment__c' => String.valueOf(Date.today()),
            'Address_Section__c' => 'Address Only'
        };

        Test.startTest();
        String result = HL_DirectorDetailsController.saveDirectorDetails(inputMap, loanApp.Id);
        Test.stopTest();

        System.assertEquals('success', result, 'Save should return success');

        Company_Director_Details__c savedDirector = [
            SELECT Id, Director_Name__c, Director_DIN_Number__c
            FROM Company_Director_Details__c
            WHERE Loan_Application__c = :loanApp.Id
            AND Director_Name__c = 'Minimal Director'
            LIMIT 1
        ];
        System.assertEquals('Minimal Director', savedDirector.Director_Name__c, 'Should save name');
        System.assertEquals('DIN888888', savedDirector.Director_DIN_Number__c, 'Should save DIN');
    }
    
    @isTest
    static void testSaveDirectorDetails_Exception() {
        Map<String, String> inputMap = new Map<String, String>{
            'Director_Name__c' => 'Test Director'
        };

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            HL_DirectorDetailsController.saveDirectorDetails(inputMap, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown an AuraHandledException');
    }
    
    @isTest
    static void testDeleteDirectorDetails_Success() {
        Company_Director_Details__c director = [SELECT Id FROM Company_Director_Details__c LIMIT 1];
        
        Test.startTest();
        String result = HL_DirectorDetailsController.deleteDirectorDetails(director.Id);
        Test.stopTest();
        
        System.assertEquals('success', result, 'Delete should return success');
        
        List<Company_Director_Details__c> deletedDirectors = [
            SELECT Id FROM Company_Director_Details__c WHERE Id = :director.Id
        ];
        System.assertEquals(0, deletedDirectors.size(), 'Record should be deleted');
    }
    
    @isTest
    static void testDeleteDirectorDetails_InvalidId() {
        Test.startTest();
        String result = HL_DirectorDetailsController.deleteDirectorDetails('001000000000000');
        Test.stopTest();
        
        System.assertEquals('success', result, 'Should return success even if record not found');
    }
    
    @isTest
    static void testIsDirectorDetailsApplicable_True() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Boolean result = HL_DirectorDetailsController.isDirectorDetailsApplicable(loanApp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    @isTest
    static void testIsDirectorDetailsApplicable_NoPrimaryApplicant() {
        Opportunity newLoan = new Opportunity(
            Name = 'Loan Without Primary Applicant',
			 StageName = 'Credit Underwriting',
			Product__c ='Home Loan',
            CloseDate = Date.today().addMonths(6)
        );
        insert newLoan;
        
        Test.startTest();
        Boolean result = HL_DirectorDetailsController.isDirectorDetailsApplicable(newLoan.Id);
        Test.stopTest();
        
        System.assertEquals(false, result, 'Should return false when no primary applicant exists');
    }
    
    @isTest
    static void testIsDirectorDetailsPresent_True() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Boolean result = HL_DirectorDetailsController.isDirectorDetailsPresent(loanApp.Id);
        Test.stopTest();
        
        System.assertEquals(true, result, 'Should return true when director details exist');
    }
    
    @isTest
    static void testIsDirectorDetailsPresent_False() {
        Opportunity newLoan = new Opportunity(
            Name = 'Loan Without Directors',
			 StageName = 'Credit Underwriting',
			Product__c ='Home Loan',
            CloseDate = Date.today().addMonths(6)
        );
        insert newLoan;
        
        Test.startTest();
        Boolean result = HL_DirectorDetailsController.isDirectorDetailsPresent(newLoan.Id);
        Test.stopTest();
        
        System.assertEquals(false, result, 'Should return false when no director details exist');
    }
    
    @isTest
    static void testUpdateDirectorDetails_Success() {
        Company_Director_Details__c director = [
            SELECT Id, Director_Name__c, Percentage_of_Shareholding__c 
            FROM Company_Director_Details__c 
            LIMIT 1
        ];
        
        director.Director_Name__c = 'Updated Director Name';
        director.Percentage_of_Shareholding__c = 50.25;
        
        Test.startTest();
        Boolean result = HL_DirectorDetailsController.updateDirectorDetails(director);
        Test.stopTest();
        
        System.assertEquals(true, result, 'Update should return true');
        
        Company_Director_Details__c updatedDirector = [
            SELECT Id, Director_Name__c, Percentage_of_Shareholding__c 
            FROM Company_Director_Details__c 
            WHERE Id = :director.Id
        ];
        System.assertEquals('Updated Director Name', updatedDirector.Director_Name__c, 
                          'Director name should be updated');
        System.assertEquals(50.25, updatedDirector.Percentage_of_Shareholding__c, 
                          'Percentage should be updated');
    }
    
    @isTest
    static void testUpdateDirectorDetails_NullRecord() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            HL_DirectorDetailsController.updateDirectorDetails(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown an AuraHandledException');
    }

    @isTest
    static void testUpdateDirectorDetails_NoId() {
        Company_Director_Details__c director = new Company_Director_Details__c(
            Director_Name__c = 'Test Director'
        );

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            HL_DirectorDetailsController.updateDirectorDetails(director);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown an AuraHandledException');
    }

    @isTest
    static void testValidateDirectorDetailsForStage_NonMatchingStage() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        HL_DirectorDetailsController.DirectorValidationResult result =
           HL_DirectorDetailsController.validateDirectorDetailsForStage(loanApp.Id, 'Lead');
        Test.stopTest();

        System.assertEquals(true, result.isValid, 'Should return valid for non-matching stage');
        System.assertEquals('', result.errorMessage, 'Error message should be empty');
    }

    @isTest
    static void testValidateDirectorDetailsForStage_CreditUnderwriting_WithDirectorDetails() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];

        Map<String, String> constants = Utility.getConstantsBasisNonStaticLabels('CreditStage');
        String creditUnderwriting = constants.get('CreditStage');

        Test.startTest();
        HL_DirectorDetailsController.DirectorValidationResult result =
            HL_DirectorDetailsController.validateDirectorDetailsForStage(loanApp.Id, creditUnderwriting);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.isValid, 'isValid should not be null');
    }

    @isTest
    static void testValidateDirectorDetailsForStage_CreditInProgress_WithDirectorDetails() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];

        Map<String, String> constants = Utility.getConstantsBasisNonStaticLabels('Credit_In_Progress_Stage_Value');
        String creditInProgress = constants.get('Credit_In_Progress_Stage_Value');

        Test.startTest();
        HL_DirectorDetailsController.DirectorValidationResult result =
            HL_DirectorDetailsController.validateDirectorDetailsForStage(loanApp.Id, creditInProgress);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.isValid, 'isValid should not be null');
    }

    @isTest
    static void testValidateDirectorDetailsForStage_MissingDirectorDetails() {
        Opportunity newLoan = new Opportunity(
            Name = 'Loan Without Director Details',
			Product__c ='Home Loan',
            StageName = 'Credit Underwriting',
            CloseDate = Date.today().addMonths(6)
        );
        insert newLoan;

        List<String> applicableSectors = System.Label.Director_Details_Dependent_Sector_Values.split(',');
        String applicableSector = applicableSectors.isEmpty() ? 'Private Limited' : applicableSectors[0].trim();

        Application_Applicant__c primaryApplicant = new Application_Applicant__c(
            Loan_Application__c = newLoan.Id,
            Applicant_Type__c = Constants.PRIMARY_APPLICANT,
            Customer_Type__c = 'Non Individual',
            Customer_Profile__c = 'SENP',
            Sector__c = applicableSector
        );
        insert primaryApplicant;

        Map<String, String> constants = Utility.getConstantsBasisNonStaticLabels('CreditStage');
        String creditUnderwriting = constants.get('CreditStage');

        Test.startTest();
        HL_DirectorDetailsController.DirectorValidationResult result =
            HL_DirectorDetailsController.validateDirectorDetailsForStage(newLoan.Id, creditUnderwriting);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }
	/*
    @isTest
    static void testValidateDirectorDetailsForStage_NotApplicableSector() {
        Opportunity newLoan = new Opportunity(
            Name = 'Loan With Non-Applicable Sector',
			Product__c ='Home Loan',
            StageName = 'Credit Underwriting',
            CloseDate = Date.today().addMonths(6)
        );
        insert newLoan;

        Application_Applicant__c primaryApplicant = new Application_Applicant__c(
            Loan_Application__c = newLoan.Id,
            Applicant_Type__c = Constants.PRIMARY_APPLICANT,
            Customer_Type__c = 'Non Individual',
            Customer_Profile__c = 'SEP'
        );
        insert primaryApplicant;

        Map<String, String> constants = Utility.getConstantsBasisNonStaticLabels('CreditStage');
        String creditUnderwriting = constants.get('CreditStage');

        Test.startTest();
        HL_DirectorDetailsController.DirectorValidationResult result =
            HL_DirectorDetailsController.validateDirectorDetailsForStage(newLoan.Id, creditUnderwriting);
        Test.stopTest();

        System.assertEquals(true, result.isValid, 'Should return valid when sector is not applicable');
        System.assertEquals('', result.errorMessage, 'Error message should be empty');
    }
	*/

    @isTest
    static void testValidateDirectorDetailsForStage_NullLoanId() {
        Test.startTest();
        HL_DirectorDetailsController.DirectorValidationResult result =
            HL_DirectorDetailsController.validateDirectorDetailsForStage(null, 'Credit Underwriting');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testValidateDirectorDetailsForStage_NullStage() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        HL_DirectorDetailsController.DirectorValidationResult result =
            HL_DirectorDetailsController.validateDirectorDetailsForStage(loanApp.Id, null);
        Test.stopTest();

        System.assertEquals(true, result.isValid, 'Should return valid for null stage');
        System.assertEquals('', result.errorMessage, 'Error message should be empty');
    }

    @isTest
    static void testValidateDirectorDetailsForStage_ApplicableWithDirectorDetailsPresent() {
        Opportunity newLoan = new Opportunity(
            Name = 'Loan With Applicable Sector And Directors',
			Product__c ='Home Loan',
            StageName = 'Credit Underwriting',
            CloseDate = Date.today().addMonths(6)
        );
        insert newLoan;

        List<String> applicableSectors = System.Label.Director_Details_Dependent_Sector_Values.split(',');
        String applicableSector = applicableSectors.isEmpty() ? 'Private Limited' : applicableSectors[0].trim();

        Application_Applicant__c primaryApplicant = new Application_Applicant__c(
            Loan_Application__c = newLoan.Id,
            Applicant_Type__c = Constants.PRIMARY_APPLICANT,
            Customer_Type__c = 'Non Individual',
            Customer_Profile__c = 'SENP',
            Sector__c = applicableSector
        );
        insert primaryApplicant;

        Company_Director_Details__c director = new Company_Director_Details__c(
            Loan_Application__c = newLoan.Id,
            Director_Name__c = 'Test Director',
            Director_DIN_Number__c = 'DIN123456',
            Percentage_of_Shareholding__c = 50,
            Director_Designation__c = 'MD',
            Date_of_Appointment__c = Date.today().addYears(-1),
            Address_Section__c = 'Test Address'
        );
        insert director;

        Map<String, String> constants = Utility.getConstantsBasisNonStaticLabels('CreditStage');
        String creditUnderwriting = constants.get('CreditStage');

        Test.startTest();
        HL_DirectorDetailsController.DirectorValidationResult result =
            HL_DirectorDetailsController.validateDirectorDetailsForStage(newLoan.Id, creditUnderwriting);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testGetLoanIdsWithDirectorDetails_WithRecords() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        Set<Id> result = HL_DirectorDetailsController.getLoanIdsWithDirectorDetails(new Set<Id>{ loanApp.Id });
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return 1 loan Id with director details');
        System.assert(result.contains(loanApp.Id), 'Should contain the loan Id');
    }

    @isTest
    static void testGetLoanIdsWithDirectorDetails_NoRecords() {
        Opportunity newLoan = new Opportunity(
            Name = 'Loan Without Directors For Bulk',
			Product__c ='Home Loan',
            StageName = 'Credit Underwriting',
            CloseDate = Date.today().addMonths(6)
        );
        insert newLoan;

        Test.startTest();
        Set<Id> result = HL_DirectorDetailsController.getLoanIdsWithDirectorDetails(new Set<Id>{ newLoan.Id });
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty set');
    }

    @isTest
    static void testGetLoanIdsWithDirectorDetails_EmptySet() {
        Test.startTest();
        Set<Id> result = HL_DirectorDetailsController.getLoanIdsWithDirectorDetails(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty set for empty input');
    }

    @isTest
    static void testGetLoanIdsWithDirectorDetails_NullSet() {
        Test.startTest();
        Set<Id> result = HL_DirectorDetailsController.getLoanIdsWithDirectorDetails(null);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty set for null input');
    }

    @isTest
    static void testIsDirectorDetailsApplicableBulkified_WithApplicableSector() {
        Opportunity newLoan = new Opportunity(
            Name = 'Loan For Bulk Applicable',
			Product__c ='Home Loan',
            StageName = 'Credit Underwriting',
            CloseDate = Date.today().addMonths(6)
        );
        insert newLoan;

        List<String> applicableSectors = System.Label.Director_Details_Dependent_Sector_Values.split(',');
        String applicableSector = applicableSectors.isEmpty() ? 'Private Limited' : applicableSectors[0].trim();

        Application_Applicant__c primaryApplicant = new Application_Applicant__c(
            Loan_Application__c = newLoan.Id,
            Applicant_Type__c = Constants.PRIMARY_APPLICANT,
            Customer_Type__c = 'Non Individual',
            Customer_Profile__c = 'SENP',
            Sector__c = applicableSector
        );
        insert primaryApplicant;

        Test.startTest();
        Set<Id> result = HL_DirectorDetailsController.isDirectorDetailsApplicableBulkified(new Set<Id>{ newLoan.Id });
        Test.stopTest();

        System.assert(result.contains(newLoan.Id), 'Should contain the loan Id with applicable sector');
    }

    @isTest
    static void testIsDirectorDetailsApplicableBulkified_EmptySet() {
        Test.startTest();
        Set<Id> result = HL_DirectorDetailsController.isDirectorDetailsApplicableBulkified(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty set for empty input');
    }

    @isTest
    static void testIsDirectorDetailsApplicable_WithApplicableSector() {
        Opportunity newLoan = new Opportunity(
            Name = 'Loan For Applicable Sector',
			Product__c ='Home Loan',
            StageName = 'Credit Underwriting',
            CloseDate = Date.today().addMonths(6)
        );
        insert newLoan;

        List<String> applicableSectors = System.Label.Director_Details_Dependent_Sector_Values.split(',');
        String applicableSector = applicableSectors.isEmpty() ? 'Private Limited' : applicableSectors[0].trim();

        Application_Applicant__c primaryApplicant = new Application_Applicant__c(
            Loan_Application__c = newLoan.Id,
            Applicant_Type__c = Constants.PRIMARY_APPLICANT,
            Customer_Type__c = 'Non Individual',
            Customer_Profile__c = 'SENP',
            Sector__c = applicableSector
        );
        insert primaryApplicant;

        Test.startTest();
        Boolean result = HL_DirectorDetailsController.isDirectorDetailsApplicable(newLoan.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'Should return true when sector is applicable');
    }
}