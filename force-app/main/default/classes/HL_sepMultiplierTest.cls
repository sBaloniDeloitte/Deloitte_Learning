@isTest
public class HL_sepMultiplierTest {

    @testSetup
    static void setupData() {

        Trigger_Settings__c triggerSettings = new Trigger_Settings__c(
            Name='Trigger Settings',
            Application_Applicant_Trigger__c = true,
            City_Master_Trigger__c = true,
            Lead_Trigger__c = true,
            Opportunity_Trigger__c = true,
            Application_Verification_Trigger__c = true
        );
        insert triggerSettings;

        Id branchRectypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Branch')
            .getRecordTypeId();

        Account branch = new Account(
            Branch_Code__c = '110',
            RecordTypeId = branchRectypeId,
            Name = 'Udaipur'
        );
        insert branch;

        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');

        List<Opportunity> oppRecList = TestDataFactory.getTestOpportunityData(1, false);
        oppRecList[0].Product__c = 'Flexi Loan';
        oppRecList[0].Branch_Master__c = branch.Id;
        insert oppRecList;

        Application_Applicant__c appApplicant =
            TestDataFactory.createApplicationApplicant(
                'Primary Applicant',
                oppRecList[0].Id,
                'John Doe',
                'ABCCE1234F',
                Date.newInstance(1990, 1, 1)
            );
        insert appApplicant;

        Id sepRT = Schema.SObjectType.Income_Assessment__c
            .getRecordTypeInfosByDeveloperName()
            .get('Sep_Multiplier')
            .getRecordTypeId();

        Income_Assessment__c parent = new Income_Assessment__c(
            Loan_Application__c = oppRecList[0].Id,
            Applicant__c = appApplicant.Id,
            RecordTypeId = sepRT
        );
        insert parent;

        // Child particular
        Income_Assessment__c child = new Income_Assessment__c(
            Loan_Application__c = oppRecList[0].Id,
            Applicant__c = appApplicant.Id,
            Parent__c = parent.Id,
            SepMultiplierParticulars__c = 'Average',
            RecordTypeId = sepRT
        );
        insert child;

        // Grandchildren (years)
        Integer years = Integer.valueOf(System.Label.Sep_Multiplier_Years);
        List<Income_Assessment__c> grandChildren = new List<Income_Assessment__c>();

        for(Integer i=0;i<years;i++){
            grandChildren.add(new Income_Assessment__c(
                Loan_Application__c = oppRecList[0].Id,
                Applicant__c = appApplicant.Id,
                Parent__c = child.Id,
                Year_Name__c = String.valueOf(2026 - i),
                Yearly_Amount__c = 1000 + (i * 100),
                RecordTypeId = sepRT
            ));
        }
        insert grandChildren;

        // Rental child
        Id rentalRT = Schema.SObjectType.Income_Assessment__c
            .getRecordTypeInfosByDeveloperName()
            .get('Child_Rental_Income')
            .getRecordTypeId();

        Income_Assessment__c rental = new Income_Assessment__c(
            Loan_Application__c = oppRecList[0].Id,
            Applicant__c = appApplicant.Id,
            Parent__c = parent.Id,
            RecordTypeId = rentalRT,
            Yearly_Amount__c = 2000
        );
        insert rental;
    }

    @isTest
    static void passTests(){

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c appApplicant =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];

        Income_Assessment__c sepParent =
            [SELECT Id FROM Income_Assessment__c
             WHERE RecordType.DeveloperName='Sep_Multiplier'
             AND Parent__c = null LIMIT 1];

        Income_Assessment__c rental =
            [SELECT Id FROM Income_Assessment__c
             WHERE RecordType.DeveloperName='Child_Rental_Income'
             LIMIT 1];

        Test.startTest();

        HL_sepMultiplier.createCamRecordsOnLoad(opp.Id, appApplicant.Id);
        HL_sepMultiplier.getPicklistValues('Income_Assessment__c','Eligibility_Consideration__c');

        HL_sepMultiplier.MainWrapper wrap =
            HL_sepMultiplier.getScreenData(opp.Id, appApplicant.Id);
        System.assertNotEquals(null, wrap);

        HL_sepMultiplier.updateYearName(opp.Id, appApplicant.Id, 2026);

        // ✅ Growth calculation
        HL_sepMultiplier.calculateGrowth(sepParent.Id, opp.Id, appApplicant.Id);

        HL_sepMultiplier.updateEligibilityConsideration(
            opp.Id,
            appApplicant.Id,
            'Average Cash Profit'
        );

        List<HL_sepMultiplier.ApplicantWrapper> apps =
            HL_sepMultiplier.getApplicants(opp.Id, 'Sep Multiplier');
        System.assert(!apps.isEmpty());

        System.assertEquals(
            'Success',
            HL_sepMultiplier.upsertRentalIncome(
                opp.Id, appApplicant.Id, 2500, rental.Id
            )
        );

        System.assertEquals(
            'Success',
            HL_sepMultiplier.upsertAdditionalMultiplier(
                opp.Id, appApplicant.Id, 1.5, rental.Id
            )
        );

        List<String> rentalDetails =
            HL_sepMultiplier.getRentalDetails(opp.Id, appApplicant.Id);
        System.assertEquals(2, rentalDetails.size());

        HL_sepMultiplier.deleteCamRecords(opp.Id, appApplicant.Id);

        Test.stopTest();
    }

    @isTest
    static void exceptionCoverageTest(){
        Test.startTest();
        try{
            HL_sepMultiplier.getPicklistValues('Invalid_Object','Invalid_Field');
            System.assert(false,'Exception should have occurred');
        }
        catch(Exception e){
           // System.assert(e.getMessage().contains('Invalid'));
        }
        Test.stopTest();
    }
    
    @isTest
    static void coverageBoosterTest(){
    
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Application_Applicant__c appApplicant =
            [SELECT Id FROM Application_Applicant__c LIMIT 1];
    
        Id sepRT = Schema.SObjectType.Income_Assessment__c
            .getRecordTypeInfosByDeveloperName()
            .get('Sep_Multiplier')
            .getRecordTypeId();
    
        // ---- Case 1: HeaderValues size == 1 (getScreenData ELSE coverage)
        Income_Assessment__c parentOnly = new Income_Assessment__c(
            Loan_Application__c = opp.Id,
            Applicant__c = appApplicant.Id,
            RecordTypeId = sepRT
        );
        insert parentOnly;
    
        Test.startTest();
        HL_sepMultiplier.getScreenData(opp.Id, appApplicant.Id);
        Test.stopTest();
    
        // ---- Case 2: calculateGrowth() null yearly amounts path
        Income_Assessment__c child = new Income_Assessment__c(
            Loan_Application__c = opp.Id,
            Applicant__c = appApplicant.Id,
            Parent__c = parentOnly.Id,
            SepMultiplierParticulars__c = 'Average',
            RecordTypeId = sepRT
        );
        insert child;
    
        List<Income_Assessment__c> nullYears = new List<Income_Assessment__c>();
        Integer yrs = Integer.valueOf(System.Label.Sep_Multiplier_Years);
    
        for(Integer i=0;i<yrs;i++){
            nullYears.add(new Income_Assessment__c(
                Loan_Application__c = opp.Id,
                Applicant__c = appApplicant.Id,
                Parent__c = child.Id,
                Year_Name__c = String.valueOf(2025 - i),
                RecordTypeId = sepRT
            ));
        }
        insert nullYears;
    
        HL_sepMultiplier.calculateGrowth(child.Id, opp.Id, appApplicant.Id);
    
        // ---- Case 3: upsertRentalIncome() parent missing path
        String msg1 =
            HL_sepMultiplier.upsertRentalIncome(
                opp.Id, '001000000000000AAA', 10, null
            );
        System.assertEquals('Please create parent record first.', msg1);
    
        // ---- Case 4: upsertAdditionalMultiplier() exception-safe execution
        String msg2 =
            HL_sepMultiplier.upsertAdditionalMultiplier(
                opp.Id, '001000000000000AAA', 1.2, null
            );
        System.assertEquals('Please create parent record first.', msg2);
    }

}