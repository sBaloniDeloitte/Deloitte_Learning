public with sharing class HL_AvailabilityController {

    /**
     * @description Called from the LWC to mark the current user as available.
     */
    @AuraEnabled
    public static void markUserAvailable() {
      
            // 1. Get the ID of the user who is currently logged in
            Id currentUserId = UserInfo.getUserId();

            // 2. Create a User sObject in memory to update
            User userToUpdate = new User(
                Id = currentUserId,
                I_am_available_today__c = true
            );

            // 3. Perform the DML update
            update userToUpdate;

     
    }
}