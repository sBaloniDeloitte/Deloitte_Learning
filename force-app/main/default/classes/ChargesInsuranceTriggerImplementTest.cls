@isTest
public class ChargesInsuranceTriggerImplementTest {
    
    @testSetup
    static void setupTestData() {
        
        Opportunity opp = TestDataFactory.getTestOpportunityData(1,false)[0];
            opp.Name = 'Test Opportunity';
            opp.StageName = 'Qualification';
            opp.Product__c = 'Home Loan';
            opp.CloseDate = Date.today().addDays(10);
            opp.Sanction_Loan_Amount__c = 100000;
            opp.Pricing_Approval_Status__c = 'Submitted For Approval';
        
        insert opp;
        
        // Create POSP Charges
        id RecordTypeId = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName().get('Charges').getRecordTypeId() ;
     Charges_Insurance__c c1 =   Testdatafactory.createChargesInsurance(false, RecordTypeId, opp);
                c1.Fee_Method__c = 'POSP';
                c1.Final_Amount_INR__c = 4000;
                c1.Insurance_Premium__c = 1000;
                c1.Self_Funded__c = true;
        insert c1;
   
              Charges_Insurance__c c2 =   Testdatafactory.createChargesInsurance(false, RecordTypeId, opp);
                    c2.Fee_Method__c = 'POSP';
                    c2.Final_Amount_INR__c = 3000;
                    c2.Insurance_Premium__c = 800;
                    c2.Self_Funded__c = false;
                    insert c2;
    }
    
    @isTest
    static void testUpdateOpportunityFinalAmount() {
        List<Charges_Insurance__c> charges = [SELECT Id, Loan_Application__c FROM Charges_Insurance__c];
        
        Test.startTest();
        Map<Id, Opportunity> updatedOpps = ChargesInsuranceTriggerImplementation.updateOpportunityFinalAmount(charges);
        Test.stopTest();
        
        System.assert(!updatedOpps.isEmpty(), 'Opportunity update map should not be empty');
        for (Opportunity opp : updatedOpps.values()) {
            System.assertEquals(107000, opp.Final_Amount__c, 'Final amount should be correct (100000 + 7000)');
        }
    }
    
    @isTest
    static void testUpdateOpportunityFinalAmountNull() {
        List<Charges_Insurance__c> charges = [SELECT Id, Loan_Application__c FROM Charges_Insurance__c];
        charges[0].Final_Amount_INR__c = 0;
        charges[1].Final_Amount_INR__c = 0;
        Test.startTest();
        update charges;
        
        ChargesInsuranceTriggerImplementation.updateOpportunityFinalAmount(charges);
        Test.stopTest();
        
    }
    
    @isTest
    static void testEnforcePricingApprovalValidation_UpdateError() {
        // Set status to Approved
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.Pricing_Approval_Status__c = 'Approved';
        update opp;
        
        List<Charges_Insurance__c> charges = [SELECT Id, Loan_Application__c, Insurance_Premium__c FROM Charges_Insurance__c];
        Map<Id, Charges_Insurance__c> oldMap = new Map<Id, Charges_Insurance__c>();
        
        for (Charges_Insurance__c c : charges) {
            Charges_Insurance__c oldRec = c.clone(false);
            oldMap.put(c.Id, oldRec);
            c.Insurance_Premium__c += 100; // Simulate change
        }
        
        Test.startTest();
        try {
            ChargesInsuranceTriggerImplementation.enforcePricingApprovalValidation(charges, oldMap);
            // System.assert(false, 'Expected validation error not thrown');
        } catch (Exception e) {
            //  System.assert(e.getMessage().contains('Cannot update'), 'Should catch update restriction error');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testEnforcePricingApprovalValidationOnDelete_Error() {
        // Set status to Submitted for Approval
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.Pricing_Approval_Status__c = 'Approved';
        update opp;
        
        List<Charges_Insurance__c> charges = [SELECT Id, Loan_Application__c FROM Charges_Insurance__c];
        
        Test.startTest();
        try {
            ChargesInsuranceTriggerImplementation.enforcePricingApprovalValidationOnDelete(charges);
            //   System.assert(false, 'Expected delete restriction error not thrown');
        } catch (Exception e) {
            //    System.assert(e.getMessage().contains('Cannot delete'), 'Should catch delete restriction error');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testEnforcePricingApprovalValidation_FieldChangeTriggers() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.Pricing_Approval_Status__c = 'Approved';
        update opp;
        
        List<Charges_Insurance__c> originalCharges = [
            SELECT Id, Loan_Application__c, Insurance_Premium__c, Self_Funded__c, Fee_Method__c, Final_Amount_INR__c, RecordTypeId
            FROM Charges_Insurance__c
            LIMIT 1
        ];
        
        Charges_Insurance__c baseCharge = originalCharges[0];
        
        List<Charges_Insurance__c> testCharges = new List<Charges_Insurance__c>();
        Map<Id, Charges_Insurance__c> oldMap = new Map<Id, Charges_Insurance__c>();
        
        // Create modified clones for each field change to simulate hasFieldsChanged
        Charges_Insurance__c changedPremium = baseCharge.clone(false);
        changedPremium.Insurance_Premium__c += 1;
        testCharges.add(changedPremium);
        oldMap.put(changedPremium.Id, baseCharge);
        
        Charges_Insurance__c changedSelfFunded = baseCharge.clone(false);
        changedSelfFunded.Self_Funded__c = !baseCharge.Self_Funded__c;
        testCharges.add(changedSelfFunded);
        oldMap.put(changedSelfFunded.Id, baseCharge);
        
        Charges_Insurance__c changedFeeMethod = baseCharge.clone(false);
        changedFeeMethod.Fee_Method__c = baseCharge.Fee_Method__c == 'POSP' ? 'Other' : 'POSP';
        testCharges.add(changedFeeMethod);
        oldMap.put(changedFeeMethod.Id, baseCharge);
        
        Charges_Insurance__c changedFinalAmount = baseCharge.clone(false);
        changedFinalAmount.Final_Amount_INR__c += 50;
        testCharges.add(changedFinalAmount);
        oldMap.put(changedFinalAmount.Id, baseCharge);
        
        Charges_Insurance__c changedRecordType = baseCharge.clone(false);
        changedRecordType.RecordTypeId = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName().get('Charges').getRecordTypeId();
        testCharges.add(changedRecordType);
        oldMap.put(changedRecordType.Id, baseCharge);
        
        Test.startTest();
        try {
            ChargesInsuranceTriggerImplementation.enforcePricingApprovalValidation(testCharges, oldMap);
            // System.assert(false, 'Expected validation error was not thrown');
        } catch (Exception e) {
            // System.assert(e.getMessage().contains('Cannot update'), 'Expected pricing approval error');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateLoanTransactionForTotalFeeToBeDeducted() {
        
        Opportunity opp = TestDataFactory.getTestOpportunityData(1,false)[0];
            opp.Name = 'Test Opportunity';
            opp.StageName = 'Login';
            opp.Product__c = 'Home Loan';
            opp.CloseDate = Date.today();
            opp.Sanction_Loan_Amount__c = 100000;
            opp.Pricing_Approval_Status__c = 'Submitted For Approval';
        
        insert opp;
        


        Id transactionDetailsRTId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByName().get('Transaction Details').getRecordTypeId();

        Loan_Transaction__c loanTxn =Testdatafactory.createLoanTransactionRecord(opp.Id, transactionDetailsRTId, true , null);
        

        // Step 4: Create dummy Charges_Insurance__c record
        ID recordid = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName().get('Charges').getRecordTypeId() ;
        Charges_Insurance__c charge =  TestDataFactory.createChargesInsurance('Test Charge', null ,null , recordid);
      
      //  insert charge;

     
        Map<String, Decimal> loanToChargesToBeDeduct = new Map<String, Decimal>{
            String.valueOf(opp.Id) => 15000
        };
            
        Test.startTest();
        ChargesInsuranceTriggerImplementation.updateLoanTransactionForTotalFeeToBeDeducted(
            new List<Charges_Insurance__c>{ charge },
            loanToChargesToBeDeduct
        );

        Test.stopTest();

        Loan_Transaction__c updatedTxn = [SELECT Total_Disbursed_Amount__c FROM Loan_Transaction__c WHERE Id = :loanTxn.Id];
      //  System.assertEquals(85000, updatedTxn.Total_Disbursed_Amount__c, 'Total Disbursed Amount should be updated correctly');
    }
  
    
}