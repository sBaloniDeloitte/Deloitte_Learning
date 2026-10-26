public class GenerateAPFNumberUtility {
    public static void generateAPFNumber(List<Id> projectIds) {
        system.debug('projectIds>>>> '+projectIds);
        try{
            if (projectIds.isEmpty()) return;
            Map<Id, Bank_Details__c> projectToBankMap = new Map<Id, Bank_Details__c>();
            for (Bank_Details__c bank : [SELECT Id, Project_Name__c FROM Bank_Details__c WHERE Project_Name__c IN :projectIds AND Type__c = 'Primary']) {
                projectToBankMap.put(bank.Project_Name__c, bank);
            }
            Set<Id> projectWithDocs = new Set<Id>();
            Set<String> docKeywords = new Set<String>(Label.APF_Document_Keywords.split(','));
            system.debug('docKeywords '+docKeywords);
            for (Builder_Project_Document__c doc : [SELECT Id, Project__c, Document_Name__c FROM Builder_Project_Document__c WHERE Project__c IN :projectIds]) {
                for (String key : docKeywords) {
                    if (doc.Document_Name__c != null && doc.Document_Name__c.contains(key)) {
                        projectWithDocs.add(doc.Project__c);
                        break;
                    }
                }
            }
            Integer nextAPFId=0;
            AggregateResult ar = [SELECT MAX(Project_APF_Id__c) maxVal FROM Project__c WHERE Project_APF_Id__c != NULL AND recordtype.Name='Project'];
            if (ar.get('maxVal') != null) {
                nextAPFId=Integer.valueOf(String.valueOf(ar.get('maxVal'))) + 1;
            }      
             system.debug('nextAPFId '+nextAPFId);
            
            List<Project__c> projectsToUpdate = new List<Project__c>();
            List<Project__c> queriedProjects =[select id,Name,Project_APF_Id__c from Project__c Where Id IN:projectIds and recordtype.Name='Project'];
            for (Project__c proj : queriedProjects ) {
                if (projectToBankMap.containsKey(proj.Id) &&projectWithDocs.contains(proj.Id)) {
                    if(proj.Project_APF_Id__c ==null){
                    projectsToUpdate.add(new Project__c(Id = proj.Id,Is_APF_Generated__c = true,Project_APF_Id__c = String.ValueOf(nextAPFId)));
                    nextAPFId++;
                    }
                }
            }
            
            if (!projectsToUpdate.isEmpty()) {
                system.debug('projectsToUpdate '+projectsToUpdate);
                update projectsToUpdate;
            }
        }catch(exception e){
            system.debug('exception '+e);
            system.debug('exception '+e.getLineNumber());
        }
    }
}