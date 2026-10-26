@isTest
public class HL_DeviationRecordPageControllerTest {
    
    
    @testSetup
    static void setupData() {
        Opportunity loanApp = new Opportunity(
            Name = 'TestOpp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Requested_Amount__c = 100000,
            Final_Tenure__c = 12,
            Final_Rate_Of_Interest__c = 9.5,
            Program__c = 'Banking LTS Program',
            Registration_Number__c = 12345,
            Product__c = 'Home Loan'
        );
        insert loanApp;

        Deviation_Mitigant_Master__c devMaster = new Deviation_Mitigant_Master__c(
            Name = 'Dev Master 1',
            Description__c = 'Test Deviation Description',
            Deviation_Number__c = 'DEV001',
            RecordTypeId =[select Id,SobjectType,DeveloperName from RecordType  where SobjectType ='Deviation_Mitigant_Master__c' and DeveloperName ='Deviation'].Id,
            Approving_Authority__c = 'L3',
            Deviation_Generated_From__c = 'Master'
        );
        insert devMaster;

        Application_Deviation__c deviation = new Application_Deviation__c(
            Loan_Application__c = loanApp.Id,
            Deviation_Master__c = devMaster.Id,
            Deviation_Code__c = 'DEV001',
            Mitigants__c = 'Sample Mitigant',
            Deviation_Category__c = 'Manual',
            Deviation__c = 'Sample Deviation',
            Approving_Authority__c = 'L3',
            Approval_Status__c = 'Pending',
            Remarks__c = 'Initial Remarks'
        );
        insert deviation;
    }
    @isTest
    static void testCreateDeviationRecord() {
        
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Deviation_Mitigant_Master__c devMaster = [SELECT Id FROM Deviation_Mitigant_Master__c LIMIT 1];
        
        Test.startTest();
        String result = HL_DeviationRecordPageController.createDeviationRecord(
            loanApp.Id,
            devMaster.Id,
            'Mitigant Testing'
        );
        Test.stopTest();
        
    }
     @isTest
    static void testGetAllDeviations() {
        Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<HL_DeviationRecordPageController.DeviationWrapper> devList =
            HL_DeviationRecordPageController.getAllDeviations(loanApp.Id);
        Test.stopTest();
    }

    @isTest
    static void testUpdateRemarksOnDeviation() {
        // Arrange
        List<Opportunity> loanApplication = TestDataFactory.getTestOpportunityData(1, false);
        Application_Deviation__c deviation = new Application_Deviation__c(
            Loan_Application__c = loanApplication[0].Id,
            Approving_Authority__c = '1'
        );
        insert deviation;
        String deviationId = deviation.Id; 
        String remarks = 'Updated Remarks';

        // Act
        Test.startTest();
        HL_DeviationRecordPageController.updateRemarksOnDeviation(deviationId, remarks, 'Test User');
		HL_DeviationRecordPageController.deleteDeviation(deviationId);
        Test.stopTest();
    }

    @isTest
    static void testCheckDupDeviationRecord() {
        // Arrange
        String name = 'Duplicate Deviation';
        String applicableFor = 'Test Applicable For';
        Boolean isDuplicate = HL_DeviationRecordPageController.checkDupDeviationRecord(name, applicableFor);

        // Assert
        //System.assertEquals(true, isDuplicate, 'Should return true for duplicate deviation.');
    }
}