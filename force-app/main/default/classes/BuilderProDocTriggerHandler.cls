public class BuilderProDocTriggerHandler {
    public static void handleAfterUpdate(List<Builder_Project_Document__c> newList) {
        List<Id> projectIds = new List<Id>();
        for (Builder_Project_Document__c p : newList) {
            projectIds.add(p.Project__c);
        }
        if(projectIds.size()>0){
        GenerateAPFNumberUtility.generateAPFNumber(projectIds);
        }
    }
}