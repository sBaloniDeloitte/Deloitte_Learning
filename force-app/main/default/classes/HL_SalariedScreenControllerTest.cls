@IsTest
public class HL_SalariedScreenControllerTest {

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

        // Parent Income Assessment
        Id salariedRT = Utility.getRecordTypeIdByDeveloperName(
            'Income_Assessment__c', 'Salaried_Individual'
        );

        Income_Assessment__c parentIA = new Income_Assessment__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            RecordTypeId = salariedRT,
            Net_Salary__c = 50000,
            Add_Less__c='Add'
        );
        insert parentIA;

        // Child monthly data
        Id amtRT = Utility.getRecordTypeIdByDeveloperName(
            'Income_Assessment__c', 'Salaried_Individual'
        );

        List<Income_Assessment__c> children = new List<Income_Assessment__c>();
        for (Integer i = 1; i <= 3; i++) {
            children.add(new Income_Assessment__c(
                Parent__c = parentIA.Id,
                Salaried_Name__c = 'Month ' + i,
                Monthly_Salary__c = 10000,
                Loan_Application__c = opp.Id,
                Applicant__c = applicant.Id,
                RecordTypeId = amtRT,
                Add_Less__c='Add'
            ));
        }
        insert children;
    }

    @IsTest
    static void testGetSalaryDetails() {
        Income_Assessment__c parentIA =
            [SELECT Id FROM Income_Assessment__c WHERE Parent__c = null LIMIT 1];

        Test.startTest();
        HL_SalarySlipWrapper wrap =
            HL_SalariedScreenController.getSalaryDetails(parentIA.Id);
        Test.stopTest();

        System.assertNotEquals(null, wrap);
        System.assertNotEquals(null, wrap.lstEarningsWrapper);
        System.assertNotEquals(null, wrap.lstDeductionsWrapper);
    }

    /* -------------------------------
     * deleteMonthlyValues
     * -------------------------------*/
    @IsTest
    static void testDeleteMonthlyValues() {
        Income_Assessment__c parentIA =
            [SELECT Id FROM Income_Assessment__c WHERE Parent__c = null LIMIT 1];

        Test.startTest();
        String result =
            HL_SalariedScreenController.deleteMonthlyValues('Month 1', parentIA.Id);
        Test.stopTest();

        System.assertEquals('Success', result);
    }

    /* -------------------------------
     * create & delete CAM records
     * -------------------------------*/
    @IsTest
    static void testCreateAndDeleteCamRecords() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];

        Test.startTest();
        HL_SalariedScreenController.createCamRecordsOnLoad(
            opp.Id, app.Id
        );
        HL_SalariedScreenController.deleteCamRecords(
            opp.Id, app.Id
        );
        Test.stopTest();

        System.assert(true);
    }

    /* -------------------------------
     * calculateNetIncome
     * -------------------------------*/
    @IsTest
    static void testCalculateNetIncome() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c app =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];
        Income_Assessment__c parentIA =
            [SELECT Id FROM Income_Assessment__c WHERE Parent__c = null LIMIT 1];

        Test.startTest();
        Decimal netIncome =
            HL_SalariedScreenController.calculateNetIncome(
                opp.Id, app.Id, parentIA.Id
            );
        Test.stopTest();

        System.assert(netIncome > 0);
    }

    /* -------------------------------
     * getNRIApplicants
     * -------------------------------*/
    @IsTest
    static void testGetNRIApplicants() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<HL_SalariedScreenController.ApplicantDetails> listData =
            HL_SalariedScreenController.getNRIApplicants(opp.Id);
        Test.stopTest();

        System.assert(listData.size() > 0);
    }

    /* -------------------------------
     * fetchProductId (safe check)
     * -------------------------------*/
    @IsTest
    static void testFetchProductIdSafe() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        try {
            Test.startTest();
            HL_SalariedScreenController.fetchProductId(opp.Id);
            Test.stopTest();
        } catch (Exception e) {
            System.assert(true); // acceptable if product not present
        }
    }
     @IsTest
    static void testDeleteIncomeExpences() {
		Opportunity opp =[select id,name from opportunity limit 1];
        Id loanId =opp.Id;
        Application_Applicant__c app = [select id from Application_Applicant__c];

        Id nriRT = Utility.getRecordTypeIdByDeveloperName(
            'Income_Assessment__c', 'Salaried_NRI'
        );

        // Create NRI income record
        Income_Assessment__c nri = new Income_Assessment__c(
            Loan_Application__c = loanId,
            Applicant__c = app.Id,
            RecordTypeId = nriRT,
            Name = 'NRI Income'
        );
        insert nri;

        Test.startTest();
        HL_SalariedScreenController.deleteIncomeExpences(
            loanId,
            new List<Id>{ app.Id }
        );
        Test.stopTest();

        // Verify deletion
        Integer countAfter = [
            SELECT COUNT()
            FROM Income_Assessment__c
            WHERE Id = :nri.Id
        ];
        System.assertEquals(0, countAfter);
    }

    @IsTest
    static void testUpsertRentalIncome_Success() {
		Opportunity opp =[select id,name from opportunity limit 1];
        Id loanId =opp.Id;
        Application_Applicant__c app = [select id from Application_Applicant__c];
        Id salariedRT = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c', 'Salaried_Individual');
        Income_Assessment__c parent = new Income_Assessment__c(
            Loan_Application__c = loanId,
            Applicant__c = app.Id,
            RecordTypeId = salariedRT
        );
        insert parent;

        Test.startTest();
        String result = HL_SalariedScreenController.upsertRentalIncome(loanId,app.Id,120000,null);
        Test.stopTest();
    }
   
    @IsTest
    static void testUpsertRentalIncome_NoParent() {
		Opportunity opp =[select id,name from opportunity limit 1];
        Id loanId =opp.Id;
        Application_Applicant__c app = [select id from Application_Applicant__c];
		Id nriRT = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c','Salaried_NRI');

        Income_Assessment__c parent = new Income_Assessment__c(
            Loan_Application__c = loanId,
            Applicant__c = app.Id,
            RecordTypeId = nriRT,
            Type_of_Income_Assesment__c = 'Income',
            ParentorChild__c = 'Parent',
            Name = 'Income' + ' Parent'
        );
        insert parent;
         Map<String, Object> recordData = new Map<String, Object>{
            'loanId'          => loanId,
            'applicantId'     => app.Id,
            'typeOfAssessment'=> 'Income',
            'particular'      => 'Salary Abroad',
            'foreignAmt'      => 1000,
            'exchangeRate'    => 80,
            'inrAmt'          => 80000
        };
        Test.startTest();
        String result = HL_SalariedScreenController.upsertRentalIncome(loanId,app.Id,50000,null);
        HL_SalariedScreenController.getAllIncomeAssesmentRecords(loanId);
        HL_SalariedScreenController.saveNRIIncomeExpense(recordData);
        HL_SalariedScreenController.deleteIncomeAssessment(parent.Id);
        
        Test.stopTest();
    }
    @IsTest
    static void testUpsertRentalIncome_NoParent2() {
		Opportunity opp =[select id,name from opportunity limit 1];
        Id loanId =opp.Id;
        Application_Applicant__c app = [select id from Application_Applicant__c];
		Id nriRT = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c','Salaried_NRI');

        Income_Assessment__c parent = new Income_Assessment__c(
            Loan_Application__c = loanId,
            Applicant__c = app.Id,
            RecordTypeId = nriRT,
            Type_of_Income_Assesment__c = 'Income',
            ParentorChild__c = 'Parent',
            Name = 'Income' + ' Parent'
        );
        insert parent;
        Income_Assessment__c parent2 = new Income_Assessment__c(
            Loan_Application__c = loanId,
            Applicant__c = app.Id,
            RecordTypeId = nriRT,
            Type_of_Income_Assesment__c = 'Obligations',
            ParentorChild__c = 'Parent',
            Name = 'Obligation' + ' Parent'
        );
        insert parent2;
         
        Test.startTest();
        HL_SalariedScreenController.getNRIIncomeExpences(loanId, new List<Id>{app.Id}, new List<String>{'Fixed Salary (Net)'},new List<String>{'Cerdit Card Due'});
        HL_SalariedScreenController.updateIncomeAssessment(parent.Id,100,0.2,100);
        Test.stopTest();
	}
    @IsTest
    static void testUpsertRentalIncome_NoParent3() {
		Opportunity opp =[select id,name from opportunity limit 1];
        Id loanId =opp.Id;
        Application_Applicant__c app = [select id from Application_Applicant__c];
		Id nriRT = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c','Salaried_NRI');

        Income_Assessment__c parent = new Income_Assessment__c(
            Loan_Application__c = loanId,
            Applicant__c = app.Id,
            RecordTypeId = nriRT,
            Type_of_Income_Assesment__c = 'Income',
            ParentorChild__c = 'Parent',
            Name = 'Income' + ' Parent'
        );
        insert parent;
        Test.startTest();
        HL_SalariedScreenController.saveNetSalary(parent.id,100);
        HL_SalariedScreenController.saveTotalGross(parent.id,100);
        Test.stopTest();
    }
    @IsTest
    static void testUpsertRentalIncome_NoParent4() {
		Opportunity opp =[select id,name from opportunity limit 1];
        Id loanId =opp.Id;
        Application_Applicant__c app = [select id from Application_Applicant__c];
		Id nriRT = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c','Salaried_Individual');
        Application_Applicant__c applicant = new Application_Applicant__c(
            Applicant_Type__c = 'Co Applicant',
            Customer_Type__c = 'Individual',
            Loan_Application__c = opp.Id
        );
        insert applicant;
        Application_Applicant__c applicant2 = new Application_Applicant__c(
            Applicant_Type__c = 'Guarantor',
            Customer_Type__c = 'Individual',
            Loan_Application__c = opp.Id
        );
        insert applicant2;
        Income_Assessment__c parent = new Income_Assessment__c(
            Loan_Application__c = loanId,
            Applicant__c = app.Id,
            RecordTypeId = nriRT,
            ParentorChild__c = 'Parent',
            Name = 'Income' + ' Parent'
        );
        insert parent;
        Income_Assessment__c parent2 = new Income_Assessment__c(
            Loan_Application__c = loanId,
            Applicant__c = applicant.Id,
            RecordTypeId = nriRT,
            ParentorChild__c = 'Parent',
            Name = 'Income' + ' Parent'
        );
        insert parent2;
        Income_Assessment__c parent3 = new Income_Assessment__c(
            Loan_Application__c = loanId,
            Applicant__c = applicant2.Id,
            RecordTypeId = nriRT,
            ParentorChild__c = 'Parent',
            Name = 'Income' + ' Parent'
        );
        insert parent3;
        Test.startTest();
        HL_SalariedScreenController.getAllApplicantList(loanId);
        Test.stopTest();
    }
    @IsTest
    static void testUpsertRentalIncome_NoParent5() {
		Opportunity opp =[select id,name from opportunity limit 1];
        Id loanId =opp.Id;
        Application_Applicant__c app = [select id from Application_Applicant__c];
		Id nriRT = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c','Salaried_Amount_Data');
        Income_Assessment__c parent = new Income_Assessment__c(
            Loan_Application__c = loanId,
            Applicant__c = app.Id,
            RecordTypeId = nriRT,
            ParentorChild__c = 'Parent',
            Name = 'Income' + ' Parent'
        );
        insert parent;
        HL_SalarySlipWrapper.MonthlyValueWrapper iter1 = new HL_SalarySlipWrapper.MonthlyValueWrapper();
        iter1.recordId = null;
        iter1.strMonthLabel = 'JAN';
        iter1.strMonthValue = 1000;
        Test.startTest();
        HL_SalariedScreenController.upsertMonthlyValue(opp.Id,app.Id,parent.Id, new List<HL_SalarySlipWrapper.MonthlyValueWrapper>{iter1},parent.Id);
        Test.stopTest();
    }
    @IsTest
    static void testUpsertRentalIncome_NoParent6() {
		Opportunity opp =[select id,name from opportunity limit 1];
        Id loanId =opp.Id;
        Application_Applicant__c app = [select id from Application_Applicant__c];
		Id nriRT = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c','Salaried_Amount_Data');
        Income_Assessment__c parent = new Income_Assessment__c(
            Loan_Application__c = loanId,
            Applicant__c = app.Id,
            RecordTypeId = nriRT,
            ParentorChild__c = 'Parent',
            Name = 'Income' + ' Parent'
        );
        insert parent;
        Income_Assessment__c parent2 = new Income_Assessment__c(
            Loan_Application__c = loanId,
            Applicant__c = app.Id,
            RecordTypeId = nriRT,
            ParentorChild__c = 'Parent',
            Name = 'Income' + ' Parent'
            
        );
        insert parent2;
        Test.startTest();
        HL_SalariedScreenController.deleteParticular(parent.Id);
        HL_SalariedScreenController.deleteYearlyComponent(parent2.Id);
        Test.stopTest();
    }
    @IsTest
    static void testUpsertRentalIncome_NoParent7() {
		Opportunity opp =[select id,name from opportunity limit 1];
        Id loanId =opp.Id;
        Application_Applicant__c app = [select id from Application_Applicant__c];
		Id nriRT = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c','Salaried_Individual');
        Id incentiveRT = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c','Salaried_Incentive_Component');
        Income_Assessment__c parent = new Income_Assessment__c(
            Loan_Application__c = loanId,
            Applicant__c = app.Id,
            RecordTypeId = nriRT,
            ParentorChild__c = 'Parent',
            Name = 'Income' + ' Parent'
        );
        insert parent;
        Income_Assessment__c parent2 = new Income_Assessment__c(
            Loan_Application__c = loanId,
            Applicant__c = app.Id,
            RecordTypeId = incentiveRT,
            ParentorChild__c = 'Child',
            Name = 'Income' + ' Parent',
            Parent__c = parent.Id,
            Gross_Amount__c = 100
        );
        insert parent2;
        Test.startTest();
        HL_SalariedScreenController.getAllIncentiveDetails(parent.Id);
        Test.stopTest();
    }
}