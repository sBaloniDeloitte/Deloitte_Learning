/**
 * This class runs on a schedule time to find all Credit Managers
 * who checked the box and reset it to false for the next day.
 */
public class HL_ResetAvailabilitySchedulable implements Schedulable {

    public void execute(SchedulableContext sc) {
        
        // 1. Find all users with the 'Credit Manager' profile 
        //    who still have the box checked.
        List<User> usersToReset = [
            SELECT Id, I_am_available_today__c 
            FROM User 
            WHERE I_am_available_today__c = false
              AND Profile.Name = 'Credit Manager'
        ];

        // 2. If we found any, loop through them and set the flag to false
        if (!usersToReset.isEmpty()) {
            for (User u : usersToReset) {
                u.I_am_available_today__c = true;
            }
            
            // 3. Update all of them in a single DML call.
            // This is efficient and works as long as you have
            // fewer than 10,000 Credit Managers.
            try {
                update usersToReset;
            } catch (DmlException e) {
                System.debug('Error resetting availability flags: ' + e.getMessage());
            }
        }
    }
}