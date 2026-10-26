global with sharing class COMM_BusinessdateScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        try {
            // Call your existing logic
            FetchApplicationDateController.initiateFetchDate();
        } catch (Exception e) {
            // Optional: Log the error in Inte	gration_Details__c for monitoring
            Integration_Details__c log = new Integration_Details__c(
                Name = 'Fetch Application Date - Scheduler Error',
                Response_JSON__c = 'Error: ' + e.getMessage(),
                Method_Type__c = 'Scheduled'
            );
            try {
                insert log;
            } catch (Exception innerEx) {
                System.debug('Failed to log scheduler error: ' + innerEx.getMessage());
            }
        }
    }
}