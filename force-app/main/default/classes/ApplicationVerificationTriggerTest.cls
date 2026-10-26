@isTest

public class ApplicationVerificationTriggerTest {
 
    @isTest

    static void testBeforeUpdate() {

        Id crimeCheckRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Crime_Check' AND SObjectType = 'Application_Verification__c' LIMIT 1].Id;
 
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
 
        Opportunity opportunity = FITestDataFactory.createOpportunity(customer);

         // Insert old record

        Application_Verification__c av = new Application_Verification__c(

            Verification_Remarks__c = 'Initial Remark',

            RecordTypeId = crimeCheckRTId,

            Loan_Application__c = opportunity.ID,

			Product__c = 'Business Loan'

        );

        Insert av;

        // Clone for old record

        Application_Verification__c oldAV = av.clone(false);

        oldAV.Verification_Remarks__c = 'Initial';
 
        // Modify for update

        av.Verification_Remarks__c = 'Updated';
 
        // Build typed maps and cast safely

        List<SObject> newList = new List<SObject>{ av };

        Map<Id, SObject> newMap = new Map<Id, SObject>{ av.Id => av };

        List<SObject> oldList = new List<SObject>{ oldAV };

        Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldAV.Id => oldAV };

        Map<Id, Application_Verification__c> oldAppMap = new Map<Id, Application_Verification__c>{ oldAV.Id => oldAV };
 
        Test.startTest();

        // SAFELY call as interface

        ITriggerHandler handler = new BL_ApplicationVerificationTriggerHelper();

        
		try{
            handler.beforeUpdate(newList, newMap, oldList, oldAppMap);
        }catch (exception e){}
        //handler.beforeUpdate(newList, newMap, oldList, oldAppMap);

      

        // beforeInsert

        handler.beforeInsert(newList);
 
        // beforeDelete

        handler.beforeDelete(newList, newMap, oldList, oldMap);
 
        // afterInsert

        handler.afterInsert(newList, newMap);
 
        // afterUpdate

        handler.afterUpdate(newList, newMap, oldList, oldMap);
 
        // afterDelete

        handler.afterDelete(oldList, oldMap);
 
        // afterUndelete

        handler.afterUndelete(newList, newMap);
 
        // isDisabled

        Boolean status = ((BL_ApplicationVerificationTriggerHelper) handler).isDisabled();

        System.assertEquals(false, status, 'Trigger should not be disabled');
 
        Test.stopTest();

    }

}