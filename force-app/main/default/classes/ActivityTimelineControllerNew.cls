public with sharing class ActivityTimelineControllerNew {

    @AuraEnabled(cacheable=true)
    public static List<ActivityWrapper> getActivities(Id recordId) {

        List<ActivityWrapper> activities = new List<ActivityWrapper>();

        for(Task taskRec : [
            SELECT Id,
                   Subject,
                   CreatedDate,
                   whoid,
                   Status,
                   Description,
                   TaskSubtype
            FROM Task
            WHERE CreatedDate = TODAY
            AND whoid = :recordId
            ORDER BY CreatedDate DESC
        ]) {

            ActivityWrapper wrapper = new ActivityWrapper();

            wrapper.id = taskRec.Id;
            wrapper.subject = taskRec.Subject;
            wrapper.description = String.isBlank(taskRec.Description)
                ? 'No Description Available'
                : taskRec.Description;
            wrapper.status = taskRec.Status;
            wrapper.activityDate = taskRec.CreatedDate;

            if(taskRec.TaskSubtype == 'Call'){
                wrapper.type = 'Call';
                wrapper.iconName = 'standard:log_a_call';
                wrapper.iconClass = 'icon call';
            }
            else if(taskRec.TaskSubtype == 'Email'){
                wrapper.type = 'Email';
                wrapper.iconName = 'standard:email';
                wrapper.iconClass = 'icon email';
            }
            else{
                wrapper.type = 'Task';
                wrapper.iconName = 'standard:task';
                wrapper.iconClass = 'icon task';
            }

            activities.add(wrapper);
        }

        return activities;
    }

    public class ActivityWrapper {

        @AuraEnabled
        public String id;

        @AuraEnabled
        public String subject;

        @AuraEnabled
        public String description;

        @AuraEnabled
        public String type;

        @AuraEnabled
        public String status;

        @AuraEnabled
        public Datetime activityDate;

        @AuraEnabled
        public String iconName;

        @AuraEnabled
        public String iconClass;
    }
}