public class APF_BuilderProjectHandler {
    
    public static void validateActiveField(List<SObject> newList,Map<Id, SObject> oldMap) {
        try{
            Set<String> allowedUsers = new Set<String>(Label.APF_Active_User.split(','));
            system.debug('allowedUsers>>>'+allowedUsers);
            if (!allowedUsers.contains(UserInfo.getUserName())) {
                for (SObject newRec : newList) {
                    Object oldVal=null;
                    if(oldMap!=null){
                        SObject oldRec = oldMap.get((Id)newRec.get('Id'));
                        oldVal = oldRec.get('Active__c');
                    }
                    Object newVal = newRec.get('Active__c');
                    if (newVal != oldVal) {
                        newRec.addError('You are not allowed to modify Active status.');
                    }
                }
            }
            Set<Id> builderIds = new Set<Id>();
            Set<Id> projectIds = new Set<Id>();
            
            for (SObject sobj : newList) {
                if (sobj.get('Project__c') != null) {
                    projectIds.add((Id)sobj.get('Project__c'));
                }
                Id bgId = (Id)sobj.get('Builder_Grp__c');
                if (bgId != null) {
                    builderIds.add(bgId);
                }
            }
            Map<Id, Builder__c> bgMap = new Map<Id, Builder__c>();
            if (!builderIds.isEmpty()) {
                bgMap = new Map<Id, Builder__c>(
                    [SELECT Id, Active__c FROM Builder__c WHERE Id IN :builderIds]
                );
            }
            
            Map<Id, Project__c> projMap = new Map<Id, Project__c>();
            if (!projectIds.isEmpty()) {
                projMap = new Map<Id, Project__c>(
                    [SELECT Id, Active__c FROM Project__c WHERE Id IN :projectIds]
                );
            }
            system.debug('projMap>>>'+projMap);
            system.debug('newList>>>'+newList);
            for (SObject sobj : newList) {
                if (sobj.get('Project__c') != null) {
                    Project__c prj = projMap.get((Id)sobj.get('Project__c'));
                    if (prj != null && prj.Active__c == 'No') {
                        sobj.addError('Unit cannot be created.The related Project is inactive.');
                    }
                }
                
                Id bgId = (Id)sobj.get('Builder_Group__c');
                Builder__c bg = bgMap.get(bgId);
                
                if (bg != null && bg.Active__c == 'No') {
                    sobj.addError('Cannot create APF. Builder Group is Inactive.');
                }
                
            }
            
        }catch(Exception e){
            system.debug('error>>>'+e);
            system.debug('error>>>'+e.getLineNumber());
        }
    }
    public static void validateProjectAndUnit(List<SObject> newList) {
        try{
            Set<Id> builderIds = new Set<Id>();
            Set<Id> projectIds = new Set<Id>();
            
            for (SObject sobj : newList) {
                if (sobj.get('Project__c') != null) {
                    projectIds.add((Id)sobj.get('Project__c'));
                }
                Id bgId = (Id)sobj.get('Builder_Grp__c');
                if (bgId != null) {
                    builderIds.add(bgId);
                }
            }
            Map<Id, Builder__c> bgMap = new Map<Id, Builder__c>();
            if (!builderIds.isEmpty()) {
                bgMap = new Map<Id, Builder__c>(
                    [SELECT Id, Active__c FROM Builder__c WHERE Id IN :builderIds]
                );
            }
            
            Map<Id, Project__c> projMap = new Map<Id, Project__c>();
            if (!projectIds.isEmpty()) {
                projMap = new Map<Id, Project__c>(
                    [SELECT Id, Active__c FROM Project__c WHERE Id IN :projectIds]
                );
            }
            system.debug('bgMap>>>'+bgMap);
            system.debug('projMap>>>'+projMap);
            system.debug('newList>>>'+newList);
            for (SObject sobj : newList) {
                if (sobj.get('Project__c') != null) {
                    Project__c prj = projMap.get((Id)sobj.get('Project__c'));
                    if (prj != null && prj.Active__c == 'No') {
                        sobj.addError('Unit cannot be created.The related Project is inactive.');
                    }
                }
                
                Id bgId = (Id)sobj.get('Builder_Grp__c');
                Builder__c bg = bgMap.get(bgId);
                system.debug('bg>>>'+bg);
                if (bg != null && bg.Active__c == 'No') {
                    sobj.addError('Project Cannot be created. Builder Group is Inactive.');
                }
                
            }
            
        }catch(Exception e){
            system.debug('error>>>'+e);
            system.debug('error>>>'+e.getLineNumber());
        }
    }

    public static void checkAndCreateBuilders(Set<Id> collateralIds, Set<Id> opportunityIds) {
        if (collateralIds.isEmpty() || opportunityIds.isEmpty()) {
            System.debug('ERROR : collateralIds or opportunityIds is empty');
            return;
        }
        Map<Id, Collateral__c> collateralMap = new Map<Id, Collateral__c>([SELECT Id, APF__c, Builder__c, Builder__r.Name, Project__c FROM Collateral__c WHERE Id IN :collateralIds]);
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([SELECT Id, Product__c FROM Opportunity WHERE Id IN :opportunityIds]);
        Map<String, Application_Applicant__c> requiredApplicants = new Map<String, Application_Applicant__c>();
        Map<String, Id> applicantToProjectMap = new Map<String, Id>();
        List<Application_Collateral__c> appColl = [SELECT Id, Collateral__c, HL_Loan_Application__c FROM Application_Collateral__c WHERE Collateral__c IN :collateralIds
                                                    AND HL_Loan_Application__c IN :opportunityIds];
        for (Application_Collateral__c rec : appColl) {
            Collateral__c col = collateralMap.get(rec.Collateral__c);
            Opportunity opp = opportunityMap.get(rec.HL_Loan_Application__c);
            if (col != null && col.APF__c == 'Yes' && col.Builder__c != null && col.Builder__r.Name != null && opp != null && opp.Product__c == 'Home Loan') {
                String fullName = col.Builder__r.Name.trim();
                List<String> parts = fullName.split('\\s+', 2);
                String firstName = parts.size() > 0 ? parts[0] : '';
                String lastName  = parts.size() > 1 ? parts[1] : '';
                String key = opp.Id + '|' + firstName.toLowerCase() + '|' + lastName.toLowerCase();
                if (!requiredApplicants.containsKey(key)) {
                    Application_Applicant__c newApplicant = new Application_Applicant__c(
                        Loan_Application__c = opp.Id,
                        Applicant_Type__c = 'Builder',
                        First_Name__c = firstName,
                        Last_Name__c = lastName,
                        Name = fullName
                    );
                    requiredApplicants.put(key, newApplicant);
                    if (col.Project__c != null) {
                        applicantToProjectMap.put(key, col.Project__c);
                    }
                }
            }
        }

        if (requiredApplicants.isEmpty()) {
            return;
        }

        Set<String> existingKeys = new Set<String>();
        List<Application_Applicant__c> existingApps = [SELECT Id, Loan_Application__c, First_Name__c, Last_Name__c FROM Application_Applicant__c
                                                        WHERE Loan_Application__c IN :opportunityIds AND Applicant_Type__c = 'Builder'];
        for (Application_Applicant__c app : existingApps) {
            String key = app.Loan_Application__c + '|' + (app.First_Name__c != null ? app.First_Name__c.toLowerCase() : '') + '|' + (app.Last_Name__c != null ? app.Last_Name__c.toLowerCase() : '');
            existingKeys.add(key);
        }
        List<Application_Applicant__c> toInsert = new List<Application_Applicant__c>();
        Map<String, Application_Applicant__c> finalKeyToApplicant = new Map<String, Application_Applicant__c>();
        for (String key : requiredApplicants.keySet()) {
            if (!existingKeys.contains(key)) {
                toInsert.add(requiredApplicants.get(key));
                finalKeyToApplicant.put(key, requiredApplicants.get(key));
            }
        }

        if (toInsert.isEmpty()) {
            return;
        }
        insert toInsert;

        Map<Id, List<Application_Applicant__c>> projectToApplicantsMap = new Map<Id, List<Application_Applicant__c>>();
        for (String key : finalKeyToApplicant.keySet()) {
            Id projectId = applicantToProjectMap.get(key);
            if (projectId != null) {
                if (!projectToApplicantsMap.containsKey(projectId)) {
                    projectToApplicantsMap.put(projectId, new List<Application_Applicant__c>());
                }
                projectToApplicantsMap.get(projectId).add(finalKeyToApplicant.get(key));
            }
        }

        if (projectToApplicantsMap.isEmpty()) {
            return;
        }

        List<Bank_Details__c> bankRecords = [SELECT Id, Name, Account_Number__c, Bank_Name__c, Account_Holder_Name__c, Account_Type__c, Bank_Master__c,
                                             Month__c, Year__c, Project_Name__c FROM Bank_Details__c WHERE Project_Name__c IN :projectToApplicantsMap.keySet() AND Application_Applicant__c = null];

        List<Bank_Details__c> bankClonesToInsert = new List<Bank_Details__c>();
        for (Bank_Details__c originalBank : bankRecords) {
            List<Application_Applicant__c> relatedApplicants = projectToApplicantsMap.get(originalBank.Project_Name__c);
            if (relatedApplicants == null) continue;
            for (Application_Applicant__c applicant : relatedApplicants) {
                Bank_Details__c clonedBank = originalBank.clone(false, true, false, false);
                clonedBank.Application_Applicant__c = applicant.Id;
                // clonedBank.Project_Name__c = null;
                bankClonesToInsert.add(clonedBank);
            }
        }

        if (!bankClonesToInsert.isEmpty()) {
            insert bankClonesToInsert;
        }

        System.debug('Created Builder Applicants: ' + toInsert.size());
    }
    public static void createCovenantDocs(Set<Id> collateralIds, Set<Id> opportunityIds) {
        if (collateralIds == null || collateralIds.isEmpty()
            || opportunityIds == null || opportunityIds.isEmpty()) {
            return;
        }
        List<Application_Collateral__c> appColls = [SELECT Id, Collateral__c, HL_Loan_Application__c FROM Application_Collateral__c WHERE Collateral__c IN :collateralIds AND HL_Loan_Application__c IN :opportunityIds];
        if (appColls.isEmpty()) return;
        Map<Id, Collateral__c> colMap = new Map<Id, Collateral__c>([SELECT Id, APF__c, Project__c FROM Collateral__c WHERE Id IN :collateralIds]);
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, Product__c FROM Opportunity WHERE Id IN :opportunityIds]);
        Map<Id, Set<Id>> oppToProjectIds = new Map<Id, Set<Id>>();
        Set<Id> projectIds = new Set<Id>();
        for (Application_Collateral__c ac : appColls) {
            if (ac.Collateral__c == null || ac.HL_Loan_Application__c == null) continue;

            Collateral__c c = colMap.get(ac.Collateral__c);
            Opportunity  o = oppMap.get(ac.HL_Loan_Application__c);
            if (c == null || o == null) continue;
            if (c.APF__c == 'Yes' && c.Project__c != null && o.Product__c == 'Home Loan') {
                projectIds.add(c.Project__c);
                if (!oppToProjectIds.containsKey(o.Id)) {
                    oppToProjectIds.put(o.Id, new Set<Id>());
                }
                oppToProjectIds.get(o.Id).add(c.Project__c);
            }
        }

        if (projectIds.isEmpty() || oppToProjectIds.isEmpty()) return;

        //Query covenants by Project__c 
        List<Covenant_Master__c> covenants = [SELECT Id, Name, Project__c FROM Covenant_Master__c WHERE Project__c IN :projectIds];
        if (covenants.isEmpty()) return;
        Map<Id, List<Covenant_Master__c>> projectToCovs = new Map<Id, List<Covenant_Master__c>>();
        Set<Id> covenantIds = new Set<Id>();
        for (Covenant_Master__c cm : covenants) {
            covenantIds.add(cm.Id);

            if (cm.Project__c == null) continue;
            if (!projectToCovs.containsKey(cm.Project__c)) {
                projectToCovs.put(cm.Project__c, new List<Covenant_Master__c>());
            }
            projectToCovs.get(cm.Project__c).add(cm);
        }

        if (projectToCovs.isEmpty()) return;

         //Finding existing Document_Details__c already created
        Set<String> existingKeys = new Set<String>();
        for (Document_Details__c dd : [ SELECT Id, Loan_Application__c, Covenant_Master__c FROM Document_Details__c WHERE Loan_Application__c IN :opportunityIds AND Covenant_Master__c IN :covenantIds]) {
            if (dd.Loan_Application__c == null || dd.Covenant_Master__c == null) continue;
            existingKeys.add(dd.Loan_Application__c + '|' + dd.Covenant_Master__c);
        }
        List<Document_Details__c> docsToInsert = new List<Document_Details__c>();
        Id currentUserId = UserInfo.getUserId();

        for (Id oppId : oppToProjectIds.keySet()) {
            Set<Id> pIds = oppToProjectIds.get(oppId);
            if (pIds == null || pIds.isEmpty()) {
                continue;
            }

            for (Id projectId : pIds) {
                List<Covenant_Master__c> covList = projectToCovs.get(projectId);
                if (covList == null || covList.isEmpty()) {
                    continue;
                }

                for (Covenant_Master__c cm : covList) {
                    String key = oppId + '|' + cm.Id;
                    if (existingKeys.contains(key)) {
                        continue;
                    }

                    Document_Details__c dd = new Document_Details__c();
                    dd.Loan_Application__c = oppId;
                    dd.Covenant_Master__c = cm.Id;
                    dd.Name = cm.Name;
                    dd.Covenant_Request_by__c = currentUserId;
                    docsToInsert.add(dd);
                    existingKeys.add(key);
                }
            }
        }

        if (!docsToInsert.isEmpty()) {
            insert docsToInsert;
        }
    }
}