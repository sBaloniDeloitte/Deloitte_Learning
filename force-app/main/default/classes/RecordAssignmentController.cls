/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-11-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class RecordAssignmentController {

    // Inner class runs without sharing so fetchLeadDetails can always read
    // the Lead even after OwnerId changes (e.g. Online lead assigned to sales user).
    private without sharing class ElevatedReader {
        public List<Lead> getLeadById(String leadId) {
            return [SELECT Id, Status, Branch__c, Pincode__c, Pincode__r.Name,
                           Assigned_Sales_User__r.Name, Branch__r.Name
                    FROM Lead WHERE Id = :leadId];
        }
    }

    // Inserts LeadShare records in system mode (without sharing) using partial-success DML.
    // Keeps the Telecaller Read share insert fully independent of any other share in the batch,
    // so a duplicate on the Sales User Edit share cannot silently kill this one.
    private without sharing class SystemSharing {
        public void grantLeadRead(Id leadId, Id userId) {
            LeadShare ls = new LeadShare();
            ls.LeadId    = leadId;
            ls.UserOrGroupId = userId;
            ls.LeadAccessLevel = 'Read';
            ls.RowCause  = Schema.LeadShare.RowCause.Manual;
            Database.SaveResult sr = Database.insert(ls, false);
            if (sr.isSuccess()) {
                System.debug('### [RecordAssignmentController] LeadShare INSERTED ✓ — Lead: ' + leadId + ' | User: ' + userId + ' | Access: Read | RowCause: Manual');
            } else {
                System.debug('### [RecordAssignmentController] LeadShare INSERT FAILED ✗ — Lead: ' + leadId + ' | User: ' + userId + ' | Errors: ' + sr.getErrors());
            }
        }
    }

    //getting lead records on basis of assigned user
    @AuraEnabled
    public static Map<string, string> fetchLeadDetails(String leadId, string processName) {
        Map<string, string> result = new Map<string, string>();

        switch on processName {

            when 'Assign Lead' {
                List<Lead> leadList = new ElevatedReader().getLeadById(leadId);
                if(!leadList.isEmpty()) {
                    result.put('status', leadList[0].Status);
                    result.put('branchId', leadList[0].Branch__c);
                    result.put('branchName', leadList[0].Branch__r.Name);
                    result.put('nearestBranch', 'No pincode assigned on Lead');
                    result.put('assignedUserName', '');

                    if(string.isNotBlank(leadList[0].Pincode__c)){
                        Account branch = Utility.getNearestBranchByPincode(leadList[0].Pincode__r.Name);
                        //System.debug('branch--- '+branch);
    
                        if(branch != null && string.isNotBlank(branch.Name)) {
                            result.put('nearestBranch', 'The '+ branch.Name +' branch is the nearest location for the selected pincode '+ leadList[0].Pincode__r.Name +' on Lead.');
                        }
                    }
                    
                    if(leadList[0].Assigned_Sales_User__r.Name != null && leadList[0].Branch__r.Name != null){
                        result.put('assignedUserName', leadList[0].Assigned_Sales_User__r.Name + ' ('+ leadList[0].Branch__r.Name +')');
                    }
                }
            }
        }
        //system.debug('result: '+result);

        return result;
    }
    //method assign and share lead record to targetted user 
    @AuraEnabled
    public static string assignLead(String userId, String recordId, String branchId){
        //System.debug('userId '+userId);
        //System.debug('recordId '+recordId);
        String result = 'Failure';
        if(string.isNotBlank(userId)){
            //Lead updateLead = [SELECT Id,Lead_Number__c, Assigned_Sales_User__c, Branch__c FROM Lead WHERE Id =: recordId LIMIT 1];
            Lead updateLead = new Lead();
            updateLead.Id = recordId;
            updateLead.Assigned_Sales_User__c = userId;
            updateLead.Branch__c = branchId;

            // For Online channel leads, sync OwnerId with the assigned Sales User
            Lead existingLead = [SELECT Id, Channel__c, OwnerId FROM Lead WHERE Id = :recordId LIMIT 1];
            String channel = existingLead.Channel__c != null ? existingLead.Channel__c.trim() : '';
            Id previousOwnerId = existingLead.OwnerId;
            if (channel == 'Online') {
                updateLead.OwnerId = userId;
            }

            LeadTriggerHandler.isTriggerDisabled = true;
            update updateLead;
            LeadTriggerHandler.isTriggerDisabled = false;

            List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();

            // Share with the newly assigned Sales User (Edit)
            Utility.SharingInfo si = new Utility.SharingInfo();
            si.objectName = 'Lead';
            si.userOrGroupId = userId;
            si.recordToShareId = updateLead.Id;
            si.sharingAccess = Constants.EDIT_ACCESS;
            sharingList.add(si);

            // If previous owner was a Telecaller (GC Tele Sales User), retain their Read access
            // Previous owner must be a User (not a Queue — Queues start with '00G')
            if (previousOwnerId != null && !String.valueOf(previousOwnerId).startsWith('00G') && previousOwnerId != userId) {
                System.debug('### [RecordAssignmentController] Previous ownerId: ' + previousOwnerId + ' | New ownerId: ' + userId);
                List<User> telecallerCheck = [SELECT Id FROM User
                                              WHERE Id = :previousOwnerId
                                              AND Profile.Name = :Label.Profile_GC_Tele_Sales_User
                                              LIMIT 1];
                if (!telecallerCheck.isEmpty()) {
                    System.debug('### [RecordAssignmentController] Telecaller detected → inserting Read share for: ' + previousOwnerId + ' on Lead: ' + updateLead.Id);
                    // Insert directly via without-sharing + allOrNone=false so it
                    // cannot be killed by a duplicate error on the Sales User Edit share.
                    new SystemSharing().grantLeadRead(updateLead.Id, previousOwnerId);
                }
            }

            System.debug('### [RecordAssignmentController] Inserting Sales User Edit share for Lead: ' + updateLead.Id + ' | userId: ' + userId);
            Utility.createShareRecord(JSON.serialize(sharingList));

            Set<String> recipientsId = new Set<String>();
            recipientsId.add(userId);
            String notifBody = updateLead.Lead_Number__c + ''+ Constants__mdt.getInstance('Lead_Assigned_to_sales').Value__c;
            Utility.sendInAppNotification(updateLead.Id, Constants__mdt.getInstance('Lead_assigned').Value__c, notifBody, recipientsId, 'Duplicate_Lead');

            result = 'Success';
        }

        return result;
    }
    
    @AuraEnabled
    public static List<Id> fetchAccountTeamRecords(String userId){
        List<Id> accId = new List<Id>();
        List<AccountTeamMember> accounTeamMemberList = [SELECT Id,UserId,AccountId,TeamMemberRole  from AccountTeamMember where UserId=: userId and TeamMemberRole = 'Sales' AND Level__c = 'L1'];
        for(AccountTeamMember accmember : accounTeamMemberList){
         accId.add(accmember.AccountId);
        }
        return accId;
    }
}