@IsTest
public class DeviationRecordPageControllerTest {
    @TestSetup
    static void setupData() {
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createLoanApplication(true,customer); 
        
        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Applicant_Type__c = 'Primary Applicant',
            Customer_Type__c = 'Individual',
            Loan_Application__c = opp.Id
        );
        insert applicant;
        
        // Create Product
        Product2 prod = new Product2(
            Name = 'Home Loan',
            IsActive = true
        );
        insert prod;
        
        // Create Deviation Master
        Deviation_Mitigant_Master__c devMaster = new Deviation_Mitigant_Master__c(
            Name = 'Deviation Master 1',
            Description__c = 'Test Deviation',
            Deviation_Number__c = 'DEV-001',
            Approving_Authority__c = '1',
            Product_Name__c = 'Home Loan',
            Deviation_Generated_From__c='Manual',
            RecordTypeId = Schema.SObjectType.Deviation_Mitigant_Master__c.getRecordTypeInfosByName().get('Deviation').getRecordTypeId()
        );
        insert devMaster;
        
        // Create Application Deviation
        Application_Deviation__c deviation = new Application_Deviation__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            Deviation_Master__c = devMaster.Id,
            Deviation_Code__c = 'DEV-001',
            Deviation__c = 'Test Deviation',
            Deviation_Category__c = 'Manual',
            Approval_Status__c = 'Pending',
            Approving_Authority__c = '2',
            Mitigants__c = 'Mit1,Mit2',
            HL_Product__c = prod.Id
        );
        insert deviation;
        
        // Account Team Member (Approver)
        AccountTeamMember atm = new AccountTeamMember(
            AccountId = customer.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'Credit',
            Level__c = 'L3'
        );
        insert atm;
    }
    
    /* --------------------------
* getDevationsDetails
* --------------------------*/
    @IsTest
    static void testGetDeviationsDetails() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<DeviationRecordPageController.DeviationWrapper> result =
            DeviationRecordPageController.getDevationsDetails(opp.Id);
        Test.stopTest();
        
        System.assert(result.size() > 0);
        System.assertNotEquals(null, result[0].name);
    }
    
    /* --------------------------
* getDeviationMasterList
* --------------------------*/
    @IsTest
    static void testGetDeviationMasterList() {
        Test.startTest();
        List<Deviation_Mitigant_Master__c> listData =
            DeviationRecordPageController.getDeviationMasterList('DEV');
        Test.stopTest();
        
        System.assert(listData.size() > 0);
    }
    
    /* --------------------------
* deleteDeviation
* --------------------------*/
    @IsTest
    static void testDeleteDeviation() {
        Application_Deviation__c dev =
            [SELECT Id FROM Application_Deviation__c LIMIT 1];
        
        Test.startTest();
        DeviationRecordPageController.deleteDeviation(dev.Id);
        Test.stopTest();
        
        System.assertEquals(0,
                            [SELECT COUNT() FROM Application_Deviation__c WHERE Id = :dev.Id]);
    }
    
    /* --------------------------
* fetchCurrScreenDev
* --------------------------*/
    @IsTest
    static void testFetchCurrScreenDev() {
        Application_Deviation__c dev =
            [SELECT Id FROM Application_Deviation__c LIMIT 1];
        
        Test.startTest();
        List<DeviationRecordPageController.DeviationWrapper> res =
            DeviationRecordPageController.fetchCurrScreenDev(
                new List<String>{ dev.Id }
            );
        Test.stopTest();
        
        System.assertEquals(1, res.size());
    }
    
    /* --------------------------
* fetchsameCurrScreenDev
* --------------------------*/
    @IsTest
    static void testFetchSameCurrScreenDev() {
        Application_Deviation__c dev =
            [SELECT Id FROM Application_Deviation__c LIMIT 1];
        
        Test.startTest();
        List<DeviationRecordPageController.DeviationWrapper> res =
            DeviationRecordPageController.fetchsameCurrScreenDev(
                new List<String>{ dev.Id }
            );
        Test.stopTest();
        
        System.assertEquals(1, res.size());
    }
    
    /* --------------------------
* checkSameDeviationadded
* --------------------------*/
    @IsTest
    static void testCheckSameDeviationAdded() {
        Application_Deviation__c dev = [SELECT Loan_Application__c, Deviation_Master__c FROM Application_Deviation__c LIMIT 1];
        Product2 prod = [Select Id From Product2 Limit 1];
        
        Boolean result =
            DeviationRecordPageController.checkSameDeviationadded(
                dev.Loan_Application__c,
                dev.Deviation_Master__c,
                prod.Id
            );
        
        System.assertEquals(true, result);
    }
    
    /* --------------------------
* createDeviationRecord
* --------------------------*/
    @IsTest
    static void testCreateDeviationRecord() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Deviation_Mitigant_Master__c dm =
            [SELECT Id FROM Deviation_Mitigant_Master__c LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        Test.startTest();
        List<String> ids =
            DeviationRecordPageController.createDeviationRecord(
                dm.Id,
                opp.Id,
                'Test Remark',
                new List<String>{'Applicant'},
                'Mit1',
                prod.Id
            );
        Test.stopTest();
        
        System.assertEquals(1, ids.size());
    }
    
    /* --------------------------
* removeMitigants
* --------------------------*/
    @IsTest
    static void testRemoveMitigants() {
        Application_Deviation__c dev =
            [SELECT Id FROM Application_Deviation__c LIMIT 1];
        
        Test.startTest();
        String updated =
            DeviationRecordPageController.removeMitigants(
                dev.Id,
                new List<String>{'Mit1'}
            );
        Test.stopTest();
        
        System.assert(!updated.contains('Mit1'));
    }
    
    /* --------------------------
* getApplicantsByLoanId
* --------------------------*/
    @IsTest
    static void testGetApplicantsByLoanId() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Deviation_Mitigant_Master__c dm =
            [SELECT Id FROM Deviation_Mitigant_Master__c LIMIT 1];
        
        Map<String, String> result =
            DeviationRecordPageController.getApplicantsByLoanId(
                opp.Id, dm.Id
            );
        
        System.assert(result.size() > 0);
    }
    
    /* --------------------------
* fetchmitigants
* --------------------------*/
    @IsTest
    static void testFetchMitigants() {
        Deviation_Mitigant_Master__c dm =
            [SELECT Id FROM Deviation_Mitigant_Master__c LIMIT 1];
        
        List<String> mitigants =
            DeviationRecordPageController.fetchmitigants(dm.Id);
        
        System.assertNotEquals(null, mitigants);
    }
    
    /* --------------------------
* updateRemarksOnDeviation
* --------------------------*/
    @IsTest
    static void testUpdateRemarksOnDeviation() {
        Application_Deviation__c dev =
            [SELECT Id FROM Application_Deviation__c LIMIT 1];
        
        Test.startTest();
        DeviationRecordPageController.updateRemarksOnDeviation(
            dev.Id, 'Updated Remark', 'remarks'
        );
        Test.stopTest();
        
        Application_Deviation__c updated =
            [SELECT Remarks__c FROM Application_Deviation__c WHERE Id = :dev.Id];
        
        System.assertEquals('Updated Remark', updated.Remarks__c);
    }
    
    /* --------------------------
* changeApprovalStatus
* --------------------------*/
    @IsTest
    static void testChangeApprovalStatus() {
        Application_Deviation__c dev =
            [SELECT Id, Loan_Application__c FROM Application_Deviation__c LIMIT 1];
        
        String result =
            DeviationRecordPageController.changeApprovalStatus(
                dev.Loan_Application__c,
                'Approved',
                dev.Id
            );
        
        System.assertEquals('Success', result);
    }
    
    /* --------------------------
* getProduct
* --------------------------*/
    @IsTest
    static void testGetProduct() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Map<String, String> prodMap =
            DeviationRecordPageController.getProduct(opp.Id);
        
        System.assertNotEquals(null, prodMap);
    }
}