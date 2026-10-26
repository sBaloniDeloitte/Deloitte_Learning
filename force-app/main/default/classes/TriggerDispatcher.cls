/*
* Created By : Romesh Somani
* Created Date : 06/11/2024
* Purpose : Class primarily responsible in handling trigger execution per object.
*/

public with sharing class TriggerDispatcher {

    //Disables all triggers using dispatcher framework, useful to be used if managed packaged code updates too many records
    //resulting in many unnecessary trigger invocaton. Make sure to enable it in the same transaction again to continue with normal execution
    public static Boolean isAllTriggersDisabled = false;
    public static Boolean isFirstTime = true;

    //Call this method from your trigger, passing in an instance of a trigger handler which implements ITriggerHandler.
    //This method will fire the appropriate methods on the handler depending on the trigger context.
    public static void run(ITriggerHandler handler) {

        // Check to see if the trigger has been disabled. If it has, return
        if(isAllTriggersDisabled || handler.isDisabled()){
             return;
        }
            

        if(Trigger.IsBefore && isFirstTime) {
            isFirstTime = false;

            if(Trigger.IsInsert) {
                
                //System.debug('--- onBeforeInsert start ---');

                handler.beforeInsert(Trigger.new);
                
                //System.debug('--- onBeforeInsert end ---');
            }
            else if(Trigger.IsUpdate) {

                //System.debug('--- onBeforeUpdate start ---');

                handler.beforeUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
                
                //System.debug('--- onBeforeUpdate end ---');
            }
            else if(Trigger.IsDelete) {

                //System.debug('--- onBeforeDelete start ---');

                handler.beforeDelete(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
                
                //System.debug('--- onBeforeDelete end ---');
            }

            isFirstTime = true;
        }
        else if(Trigger.IsAfter && isFirstTime) {
            isFirstTime = false;

            if(Trigger.IsInsert) {
                
                //System.debug('--- onAfterInsert start ---');

                handler.afterInsert(Trigger.new, Trigger.newMap);
                
                //System.debug('--- onAfterInsert end ---');
            }
            else if(Trigger.IsUpdate) {
                
                //System.debug('--- onAfterUpdate start ---');

                handler.afterUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
                
                //System.debug('--- onAfterUpdate end ---');
            }
            else if(Trigger.IsDelete) {

                //System.debug('--- onAfterDelete start ---');

                handler.afterDelete(Trigger.old, Trigger.oldMap);
                
                //System.debug('--- onAfterDelete end ---');
            }
            else if(Trigger.IsUndelete) {
                
                //System.debug('--- onAfterInsert start ---');

                handler.afterUndelete(Trigger.new, Trigger.newMap);
                
                //System.debug('--- onAfterInsert end ---');
            }

            isFirstTime = true;
        }
    }

    public static void disableAllTriggers() {
        isAllTriggersDisabled = true;
    }

    public static void enableAllTriggers() {
        isAllTriggersDisabled = false;
    }

    public static Boolean isAllTriggersDisabled() {
        return isAllTriggersDisabled;
    }
    
    public static void updateRecordWithoutTrigger(SObject[] records) {
        updateRecordWithoutTrigger(records, true);
    }

    public static Database.SaveResult[] updateRecordWithoutTrigger(SObject[] records, Boolean allorNone) {
        Boolean currentTriggerFlag = isAllTriggersDisabled;
        isAllTriggersDisabled = true;
        
        Database.SaveResult[] results = Database.update(records, allorNone);
        
        isAllTriggersDisabled = currentTriggerFlag;
        return results;
    }
}