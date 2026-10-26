public with sharing class AssignmentScreenController {

    // Constants used across methods
    static String conLabels = 'Edit,Read,SYSTEM_ADMINISTRATOR,Manual';
    public static Map<String, String> constants = Utility.getConstants(conLabels);

    /** 
     * Returns system-wide constants map 
     */
    @AuraEnabled
    public static Map<String, String> getConstants() {
        return constants;
    }

    /** 
     * Returns display name and API object name for given record Id
     */
    @AuraEnabled
    public static List<String> getObjectName(Id recordId) {
        List<String> result = new List<String>();
        try {
            String objectName = recordId.getSObjectType().getDescribe().getName();
            if (objectName == 'Opportunity') result.add('Loan Application');
            else if (objectName == 'Application_Verification__c') result.add('Field Investigation');
            else result.add('Invalid Object');
            result.add(objectName);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

    /** 
     * Returns current assignee's User Name for given record Id
     */
    @AuraEnabled
    public static String getCurrentAssignee(Id recordId) {
        try {
            String objectName = recordId.getSObjectType().getDescribe().getName();
            String query = 'SELECT Id, OwnerId' +
                           (objectName == 'Application_Verification__c' ? ', Assigned_to_User__c, RecordType.Name' : '') +
                           ' FROM ' + objectName +
                           ' WHERE Id = \'' + String.escapeSingleQuotes(recordId) + '\'';
            SObject rec = Database.query(query);
            String userId;
            if (objectName == 'Application_Verification__c') {
                String recType = (String)rec.getSObject('RecordType').get('Name');
                userId = recType == 'FCU' ? (String)rec.get('OwnerId') : (String)rec.get('Assigned_to_User__c');
            }else if (objectName == 'Legal__c') {
    // --- FIX FOR LEGAL ---
    // Query the assignment fields specifically
    Legal__c legalRec = [SELECT Stage__c, Assigned_to_Admin__c, Assigned_to_Executive__c, OwnerId
                         FROM Legal__c WHERE Id = :recordId LIMIT 1];

    // Determine current assignee based on stage or which field is filled
    // (This logic might need refinement based on your exact process)
    if (legalRec.Stage__c == 'Assigned to Admin' && legalRec.Assigned_to_Admin__c != null) {
        userId = legalRec.Assigned_to_Admin__c;
    } else if (legalRec.Stage__c == 'Assigned To Executive' && legalRec.Assigned_to_Executive__c != null) {
        userId = legalRec.Assigned_to_Executive__c;
    } else if (legalRec.Assigned_to_Admin__c != null) { // Fallback if stage isn't clear
         userId = legalRec.Assigned_to_Admin__c;
    } else if (legalRec.Assigned_to_Executive__c != null) { // Fallback
         userId = legalRec.Assigned_to_Executive__c;
    }
    else {
        userId = legalRec.OwnerId; // Final fallback to Owner
    }
    // --- END FIX ---
} else {
                userId = (String)rec.get('OwnerId');
            }
            return [SELECT Name FROM User WHERE Id = :userId LIMIT 1].Name;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /** 
     * Returns map of possible new assignees for the record based on user roles, branches, and vendor
     */
    @AuraEnabled
    public static Map<Id, String> getNewAssignee(String recordId) {
        Map<Id, String> assigneeMap = new Map<Id, String>();
        try {
            Id recID = (Id)recordId;
            String objectName = recID.getSObjectType().getDescribe().getName();
            String currentUserProfileName;
            String currentOwner;
            String branchId;
            String vendorId;
            String stage;

            if (objectName != 'Application_Verification__c' && objectName != 'Legal__c') return assigneeMap;

            if(objectName == 'Application_Verification__c'){
            Application_Verification__c av = [
                SELECT Id, Loan_Application__r.Branch_Master__c, Assigned_To_User__c, OwnerId, Stage__c, Vendor__c, RecordType.Name
                FROM Application_Verification__c WHERE Id = :recordId LIMIT 1
            ];

            if (av.RecordType.Name == 'FCU') {
                return getNewAssigneeForFCU(av);
            }

             currentUserProfileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
           currentOwner = av.Assigned_To_User__c;
             branchId = av.Loan_Application__r.Branch_Master__c;
             vendorId = av.Vendor__c;
             stage = av.Stage__c;
            }
            else if(objectName == 'Legal__c'){
                 Legal__c av = [
                SELECT Id, Loan_Application__r.Branch_Master__c, Assigned_to_Admin__c, OwnerId, Stage__c, Vendor_Agency__c, RecordType.Name
                FROM Legal__c WHERE Id = :recordId LIMIT 1
            ];
             currentUserProfileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
           currentOwner = av.Assigned_to_Admin__c;
             branchId = av.Loan_Application__r.Branch_Master__c;
             vendorId = av.Vendor_Agency__c;
             stage = av.Stage__c;

            }

            

            List<String> reportTypes = new List<String>{'Internal','External'};
            System.debug('Object name>'+objectName);
            System.debug('reportTypes>'+reportTypes);
            System.debug('stage>'+stage);
            Map<String, String> userRoles = getUserRoles(objectName, reportTypes, stage);
            System.debug('user roles map>'+userRoles);
            List<AccountTeamMember> teamMembers;
            if (currentUserProfileName == 'Partner Community User') {
                // For Partner Community Users, filter differently
                List<AccountTeamMember> branchUserIds = [SELECT Id, UserId FROM AccountTeamMember WHERE AccountId = :branchId AND TeamMemberRole IN :userRoles.keySet() AND UserId != :currentOwner];
                Set<Id> userIds = new Set<Id>();
                for (AccountTeamMember atm : branchUserIds) userIds.add(atm.UserId);
                System.debug('user roles>'+userRoles.keySet());
                System.debug('vendor id>'+vendorId);
                System.debug('current owner>'+currentOwner);
                teamMembers = [SELECT Id, UserId, User.Name FROM AccountTeamMember WHERE TeamMemberRole IN :userRoles.keySet() AND AccountId = :vendorId AND UserId != :currentOwner];
            } else {
                teamMembers = [SELECT Id, UserId, User.Name FROM AccountTeamMember WHERE AccountId = :branchId AND TeamMemberRole IN :userRoles.keySet() AND UserId != :currentOwner];
            }

            for (AccountTeamMember atm : teamMembers) {
                assigneeMap.put(atm.UserId, atm.User.Name);
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return assigneeMap;
    }

    /** 
     * Returns map of new assignees specific to FCU record types 
     */
    @AuraEnabled
    public static Map<Id, String> getNewAssigneeForFCU(Application_Verification__c fcuRec) {
        Map<Id, String> assigneeMap = new Map<Id, String>();

        if (fcuRec == null || fcuRec.OwnerId == null) return assigneeMap;

        AccountTeamMember acct = [
            SELECT AccountId 
            FROM AccountTeamMember 
            WHERE UserId = :fcuRec.OwnerId 
              AND Account.Type = 'Partner' 
              AND Account.Partner_Type__c = 'FCU' 
            LIMIT 1
        ];

        if (acct == null || acct.AccountId == null) return assigneeMap;

        List<AccountTeamMember> fcUsers = [
            SELECT UserId, User.Name 
            FROM AccountTeamMember 
            WHERE TeamMemberRole = 'FCU Executive' 
              AND AccountId = :acct.AccountId
        ];

        for (AccountTeamMember atm : fcUsers) {
            assigneeMap.put(atm.UserId, atm.User.Name);
        }

        return assigneeMap;
    }

    /**
     * Reassigns record ownership or assigned user, updates sharing, sends notifications, and handles related records
     */
    @AuraEnabled
    public static void reAssignRecord(Id recordId, String newOwner) {
        try {
            String objectName = recordId.getSObjectType().getDescribe().getName();
            String currentUserProfileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;

            // Query related AccountTeamMember for vendor account
            List<AccountTeamMember> buList = [SELECT Id, AccountId FROM AccountTeamMember WHERE UserId = :newOwner AND Account.RecordType.Name = 'Partner'];

            // Query document details linked to this Application Verification record
            List<Document_Details__c> docChecklistToCreate = [SELECT Id FROM Document_Details__c WHERE Application_Verification__c = :recordId];

            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectName);
            SObject obj = targetType.newSObject();
            obj.put('Id', recordId);

            if (objectName == 'Application_Verification__c') {
                Application_Verification__c av = [SELECT Id, Vendor_Admin__c, Loan_Application__r.Name, Assigned_To_User__c, Applicant__c, Loan_Application__c, RecordType.Name, OwnerId FROM Application_Verification__c WHERE Id = :recordId];

                // Delete sharing if reassigned to different user
                if (UserInfo.getUserId() != av.Assigned_To_User__c && (av.RecordType.Name == 'Business Verification' || av.RecordType.Name == 'Residence Verification')) {
                    Map<String, String> sharingParams = new Map<String, String>{
                        'objectName' => 'Application_Verification__Share',
                        'recordId' => av.Id,
                        'userId' => av.Assigned_To_User__c
                    };
                    Utility.deleteSharedRecord(sharingParams);
                }

                if (av.RecordType.Name == 'FCU') {
                    obj.put('Assigned_To_User__c', newOwner);
                    obj.put('FCU_Admin__c', av.OwnerId);
                } else {
                    obj.put('Assigned_To_User__c', newOwner);
                    if (!buList.isEmpty()) obj.put('Vendor__c', buList[0].AccountId);
                }

                // Stage logic based on profile
                if (currentUserProfileName != constants.get('SYSTEM_ADMINISTRATOR') && currentUserProfileName != 'Credit Manager') {
                    obj.put('Stage__c', 'Assigned To Executive');
                } else {
                    obj.put('Stage__c', 'Re Assigned to Admin');
                    obj.put('Vendor_Admin__c', newOwner);
                }

                // Create sharing record for new owner
                List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
                Utility.SharingInfo si = new Utility.SharingInfo();
                si.objectName = 'Application_Verification__c';
                si.userOrGroupId = newOwner;
                si.recordToShareId = recordId;
                si.sharingAccess = constants.get('Edit');
                sharingList.add(si);

                Utility.createShareRecord(JSON.serialize(sharingList));
                // Send in-app notification
                Set<String> recipientsId = new Set<String>{newOwner};
                String notifTitle = av.RecordType.Name == 'FCU' ? 'FCU Record Assigned' : av.RecordType.Name=='Personal Discussion AHL'?'PD Record Assigned': 'FI Record Assigned';
                String notifBody = av.RecordType.Name == 'FCU' ? 'A verification has been assigned to you. Please click to see the reference' : av.RecordType.Name=='Personal Discussion AHL'?  'A PD has been assigned to you.' :'A visit has been assigned to you. Please click to see the reference.';
                
                Utility.sendInAppNotification(recordId, notifTitle, notifBody, recipientsId, 'Duplicate_Lead');

                // Share Opportunity if owner changed
                if (av.RecordType.Name == 'Business Verification' || av.RecordType.Name == 'Residence Verification' || av.RecordType.Name == 'FCU') {
                    Opportunity opp = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :av.Loan_Application__c LIMIT 1];
                    if (opp.OwnerId != newOwner) {
                        Utility.SharingInfo sOpp = new Utility.SharingInfo();
                        sOpp.objectName = 'Opportunity';
                        sOpp.userOrGroupId = newOwner;
                        sOpp.recordToShareId = av.Loan_Application__c;
                        sOpp.sharingAccess = constants.get('Read');

                        Utility.createShareRecord(JSON.serialize(new List<Utility.SharingInfo>{ sOpp }));
                    }
                }

                // Share related Document Details records
                List<Utility.SharingInfo> docSharingList = new List<Utility.SharingInfo>();
                for (Document_Details__c doc : docChecklistToCreate) {
                    Utility.SharingInfo siDoc = new Utility.SharingInfo();
                    siDoc.objectName = 'Document_Details__c';
                    siDoc.userOrGroupId = newOwner;
                    siDoc.recordToShareId = doc.Id;
                    siDoc.sharingAccess = constants.get('Edit');
                    docSharingList.add(siDoc);
                }
                Utility.createShareRecord(JSON.serialize(docSharingList));

                // Share Application Applicant record if needed
                // List<Application_Applicant__Share> apShareList = [SELECT Id FROM Application_Applicant__Share WHERE UserOrGroupId = :newOwner AND ParentId = :av.Applicant__c];
                // if (apShareList.isEmpty() && av.Applicant__c != null) {
                //     Application_Applicant__Share aShare = new Application_Applicant__Share(
                //         ParentId = av.Applicant__c,
                //         UserOrGroupId = newOwner,
                //         AccessLevel = constants.get('Read'),
                //         RowCause = constants.get('Manual')
                //     );
                //     insert aShare;
                // }
            }
            if(objectName == 'Legal__c'){
                Legal__c av = [SELECT Id, Vendor_Agency__c, Loan_Application__r.Name, 
                               Assigned_to_Executive__c, RecordType.Name, OwnerId 
                               FROM Legal__c WHERE Id = :recordId];

                
                if (UserInfo.getUserId() != av.Assigned_to_Executive__c) {
                    Map<String, String> sharingParams = new Map<String, String>{
                        'objectName' => 'Legal__Share',
                        'recordId' => av.Id,
                        'userId' => av.Assigned_to_Executive__c
                    };
                    Utility.deleteSharedRecord(sharingParams);
                }

                
                    obj.put('Assigned_to_Executive__c', newOwner);
                    if (!buList.isEmpty()) obj.put('Vendor_Agency__c', buList[0].AccountId);
                

                // Stage logic based on profile
                if (currentUserProfileName != constants.get('SYSTEM_ADMINISTRATOR') && currentUserProfileName != 'Credit Manager') {
                    obj.put('Stage__c', 'Assigned To Executive');
                } else {
                    obj.put('Stage__c', 'Re Assigned to Admin');
                    obj.put('Vendor_Admin__c', newOwner);
                }

                // Create sharing record for new owner
                List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
                Utility.SharingInfo si = new Utility.SharingInfo();
                si.objectName = 'Legal__c';
                si.userOrGroupId = newOwner;
                si.recordToShareId = recordId;
                si.sharingAccess = constants.get('Edit');
                sharingList.add(si);

                Utility.createShareRecord(JSON.serialize(sharingList));
                // Send in-app notification
                /*Set<String> recipientsId = new Set<String>{newOwner};
                String notifTitle = av.RecordType.Name == 'FCU' ? 'FCU Record Assigned' : av.RecordType.Name=='Personal Discussion AHL'?'PD Record Assigned': 'FI Record Assigned';
                String notifBody = av.RecordType.Name == 'FCU' ? 
                    'A verification has been assigned to you. Please click to see the reference' :
                    av.RecordType.Name=='Personal Discussion AHL'?  'A PD has been assigned to you.' :
                    'A visit has been assigned to you. Please click to see the reference.';
                Utility.sendInAppNotification(recordId, notifTitle, notifBody, recipientsId, 'Duplicate_Lead');*/

                // Share Opportunity if owner changed
                  
                   /* Opportunity opp = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :av.Loan_Application__c LIMIT 1];
                    if (opp.OwnerId != newOwner) {
                        Utility.SharingInfo sOpp = new Utility.SharingInfo();
                        sOpp.objectName = 'Opportunity';
                        sOpp.userOrGroupId = newOwner;
                        sOpp.recordToShareId = av.Loan_Application__c;
                        sOpp.sharingAccess = constants.get('Read');

                        Utility.createShareRecord(JSON.serialize(new List<Utility.SharingInfo>{ sOpp }));
                    }*/
            

                // Share related Document Details records
                List<Utility.SharingInfo> docSharingList = new List<Utility.SharingInfo>();
                for (Document_Details__c doc : docChecklistToCreate) {
                    Utility.SharingInfo siDoc = new Utility.SharingInfo();
                    siDoc.objectName = 'Document_Details__c';
                    siDoc.userOrGroupId = newOwner;
                    siDoc.recordToShareId = doc.Id;
                    siDoc.sharingAccess = constants.get('Edit');
                    docSharingList.add(siDoc);
                }
                Utility.createShareRecord(JSON.serialize(docSharingList));

                
            }

            update obj;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /** 
     * Returns map of user roles allowed for given object, report types, and current stage 
     */
    public static Map<String, String> getUserRoles(String objectName, List<String> reportTypes, String currentStage) {
        Map<String, String> resultMap = new Map<String, String>();
        String currentUserProfile = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;

        for (Record_Allocation_Matrix__mdt record : Record_Allocation_Matrix__mdt.getAll().values()) {
            if (record.Object_Name__c == objectName &&
                reportTypes.contains(record.Report_Type__c) &&
                record.Stage__c == currentStage &&
                record.Profile__c != null) {
                if (record.Profile__c.split(';').contains(currentUserProfile)) {
                    resultMap.put(record.User_Role__c, record.Report_Type__c);
                }
            }
        }
        return resultMap;
    }
}