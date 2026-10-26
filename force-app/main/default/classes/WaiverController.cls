public with sharing class WaiverController {

    @AuraEnabled(cacheable=true)
    
    public static User getLoggedInUser() { 
        return [ SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1 ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Legal__c> searchLegalRecords(String searchTerm, Id loanAppId) {
        // if (String.isBlank(searchTerm)) {
        //     return new List<Legal__c>();
        // }
        return [
            SELECT Id, Name
            FROM Legal__c
            WHERE  Loan_Application__c =:loanAppId 
            ORDER BY CreatedDate DESC
            LIMIT 20
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getUserHierarchy(String requestedBy, String loanAppId) {
        system.debug('requestedBy '+requestedBy);
        // Step 1: Get Account Team Members for the Account related to the Opportunity
        List<AccountTeamMember> accountTeamMembers = [
            SELECT Id, Level__c, User.Name
            FROM AccountTeamMember
            WHERE AccountId IN (
                SELECT Branch_Master__c FROM Opportunity WHERE Id = :loanAppId
            )
        ];
        system.debug('accountTeamMembers '+accountTeamMembers);

        // Step 2: Get the Level__c of the requestedBy user
        AccountTeamMember requester = [
            SELECT Level__c 
            FROM AccountTeamMember 
            WHERE User.Name = :requestedBy 
            LIMIT 1
        ];
         system.debug('requester '+requester);

        String levelOfRequestedBy = requester.Level__c;

        // Step 3: Extract numeric level (e.g. "L7" → 7)
        Integer requestedLevelNum = Integer.valueOf(levelOfRequestedBy.replace('L', ''));
          system.debug('requestedLevelNum '+requestedLevelNum);

        // Step 4: Filter out members with higher level (numerically greater)
        List<String> hierarchyList = new List<String>();

        for (AccountTeamMember atm : accountTeamMembers) {
            system.debug('atm '+atm);
            if (atm.Level__c != null) {
                Integer memberLevelNum = Integer.valueOf(atm.Level__c.replace('L', ''));
                system.debug('memberLevelNum '+memberLevelNum);
                 system.debug('requestedLevelNum '+requestedLevelNum);
                if (memberLevelNum > requestedLevelNum) {
                    hierarchyList.add(atm.User.Name);
                }
            }
        }
        system.debug('hierarchyList '+hierarchyList);

        // Step 5: Return filtered hierarchy list
        return hierarchyList;
    }

    @AuraEnabled
    public static void saveWaiver(Map<String, Object> waiver) {
        Legal__c w;
        if (waiver.containsKey('Search_Report__c') && waiver.get('Search_Report__c') != null) {
            // Existing record selected → update it
            w = [SELECT Id, Waiver_Requested_From__c FROM Legal__c WHERE Id = :((String)waiver.get('Search_Report__c')) LIMIT 1];
        } else {
            // Create new record
            w = new Legal__c();
        }
        if (waiver.containsKey('Waiver_Requested_For__c')) w.Waiver_Requested_For__c = (String)waiver.get('Waiver_Requested_For__c');
        if (waiver.containsKey('Waiver_Requested_By__c')) w.Waiver_Requested_By__c = (String)waiver.get('Waiver_Requested_By__c');
        if (waiver.containsKey('Waiver_Requested_From__c')) w.Waiver_Requested_From__c = (String)waiver.get('Waiver_Requested_From__c');
        if (waiver.containsKey('Remarks__c')) w.Remarks__c = (String)waiver.get('Remarks__c');

        User requestFromUser = [SELECT Id, Name FROM User WHERE Name =:w.Waiver_Requested_From__c LIMIT 1];
        sendNotification(requestFromUser.Id, w.Id, 'Waiver Submitted', 'A waiver has been submitted for your review.');
        w.Assigned_to_Admin__c = requestFromUser.Id;
        w.Waiver_Requested_Timestamp__c = System.now();
        w.Status__c = (String)waiver.get('Status__c');
        upsert w;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Legal__c> getWaiverRecords(Id loanAppId) {
        return [
            SELECT Id, Name, Waiver_Requested_By__c, Remarks__c, Waiver_Requested_Timestamp__c
            , Waiver_Requested_From__c,Status__c
            FROM Legal__c WHERE Loan_Application__c = :loanAppId AND Waiver_Requested_By__c != null AND Waiver_Requested_From__c != null
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }

    @AuraEnabled
    public static void handleWaiverAction(Id waiverId, String actionType, String remarks) {
        Legal__c waiver = [
            SELECT Id, Name, Status__c,
			Waiver_Requested_From__c,
			Waiver_Requested_By__c
            FROM Legal__c 
            WHERE Id = :waiverId
            LIMIT 1
        ];
         system.debug('waiver '+waiver);
		User requestedByUser = [SELECT Id, Name FROM User WHERE Name =:waiver.Waiver_Requested_By__c LIMIT 1];

        User requestFromUser = [SELECT Id, Name FROM User WHERE Name =:waiver.Waiver_Requested_From__c LIMIT 1];
        Id userId = requestFromUser.Id;

         system.debug('actionType '+actionType);

        ProcessInstanceWorkitem WorkItem = getWorkItem(waiver.Id);

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        if(WorkItem == null){
		 system.debug('WorkItem Null ');

            waiver.Status__c = 'Submitted';
            update waiver;

            req.setObjectId(waiver.Id);
            req.setComments('Waiver submitted.');
            req.setSubmitterId(requestedByUser.Id);
            req.setNextApproverIds(new Id[] {requestFromUser.Id});
            req.setProcessDefinitionNameOrId('Legal_Waiver_Approval');
            req.setSkipEntryCriteria(false);

            // if (actionType != 'Submit'){
                if (!Test.isRunningTest()) {
					system.debug('req:: '+req);
                	Approval.ProcessResult result = Approval.process(req);
					System.debug('result: '+result);
                }
            // }
        }

        if (actionType == 'Submit') {

            User requestFrom = String.isNotBlank(remarks) ? [SELECT Id, Name FROM User WHERE Name =:remarks LIMIT 1] : requestFromUser;

            ProcessInstanceWorkitem piw = [SELECT Id, Actor.Name FROM ProcessInstanceWorkitem Where ProcessInstance.TargetObjectId =:waiver.Id Limit 1] ?? null;
            if(piw != null){
                piw.ActorId = requestFrom.id;
                update piw;
            }

            //  Send bell notification
            sendNotification(userId, waiver.Id, 'Waiver Submitted', 'A waiver has been submitted for your review.');
            waiver.Status__c = 'Submit For Approval';
            waiver.Waiver_Requested_From__c = requestFrom.Name;
            update waiver;
            
        } 
        else if (actionType == 'Approve') {
            waiver.Status__c = 'Approved';
            update waiver;

            WorkItem = getWorkItem(waiver.Id);

            // Approve programmatically (optional)
            Approval.ProcessWorkitemRequest approveReq = new Approval.ProcessWorkitemRequest();
            approveReq.setComments('Waiver approved.');
            approveReq.setAction('Approve');
            approveReq.setNextApproverIds(new Id[]{userId});
            if(WorkItem!=null && !Test.isRunningTest()){
                approveReq.setWorkitemId(workItem.Id);
            }            
            if (!Test.isRunningTest()) {
    			Approval.ProcessResult approvalResult = Approval.process(approveReq);
			}
        } 
        else if (actionType == 'Reject') {
            waiver.Status__c = 'Rejected';
            waiver.Remarks__c = remarks;
            update waiver;

            WorkItem = getWorkItem(waiver.Id);

            Approval.ProcessWorkitemRequest rejectReq = new Approval.ProcessWorkitemRequest();
            rejectReq.setComments(remarks);
            rejectReq.setAction('Reject');
            rejectReq.setNextApproverIds(new Id[]{userId});
            if(WorkItem!=null && !Test.isRunningTest()){
                rejectReq.setWorkitemId(workItem.Id);
            } 
            if (!Test.isRunningTest()) {
            	Approval.ProcessResult rejectionResult = Approval.process(rejectReq);
            }
        }
    }

    // ✅ Helper to get the current approval work item
    private static ProcessInstanceWorkitem getWorkItem(Id recordId) {
        ProcessInstanceWorkitem WorkItem = [
            SELECT Id 
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObjectId = :recordId 
            LIMIT 1
        ] ?? null;

        return WorkItem;
    }

    private static void sendNotification(Id recipientId, Id targetId, String title, String body) {
        try {
            CustomNotificationType notificationType = [SELECT Id, DeveloperName 
                                        FROM CustomNotificationType 
                                WHERE DeveloperName='Legal_Submit_For_Approval_Notification'];

            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle(title);
            notification.setBody(body);
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(targetId); // record to open when bell is clicked

            notification.send( new Set<String>{ recipientId });


        } catch (Exception e) {
            
        }
    }


    @AuraEnabled
    public static Legal__c getWaiverDetail(Id waiverId) {
        List<Legal__c> waiverList = [
            SELECT Id, Name, Remarks__c
            FROM Legal__c 
            WHERE Id = :waiverId 
            AND Waiver_Requested_By__c != null 
            AND Waiver_Requested_From__c != null
            LIMIT 1
        ];

        if (!waiverList.isEmpty()) {
            return waiverList[0];
        }
        return null; // safely return null if no record found
    }

}