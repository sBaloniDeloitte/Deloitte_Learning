public with sharing class InitiateScreenController {
    
    @AuraEnabled
    public static List<DocCheckWrapper> setDocument(Id recordId,String name){
        try {
            List<DocCheckWrapper> wrapper = new List<DocCheckWrapper>();
            List<Document_Details__c> documents = [SELECT Id,Name,Content_Document_Id__c  FROM Document_Details__c WHERE Loan_Application__c =:recordId];

            if(documents.isEmpty()){
                // Document_Details__c checkList =  new Document_Details__c(
                //     Name = name,
                //     Loan_Application__c = recordId,
                //     Is_Doc_Required__c = true,
                //     Document_Uploaded__c = false,
                //     Content_Document_Id__c = null
                // );
                // documents.add(checkList);
                return wrapper;
            }

            for(Integer index = 0;index<documents.size();index++){
                wrapper.add(new DocCheckWrapper(documents[index],index+1));
            }
            return wrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void deleteContent(Id contentId,Id recordId){
        List<Id> deleteIds = new List<Id>();
        List<Document_Details__c> doc = [SELECT Id,Name,Content_Document_Id__c  FROM Document_Details__c WHERE Loan_Application__c =:recordId and Content_Document_Id__c =:contentId];
        for(Document_Details__c updateDoc : doc){
            deleteIds.add(updateDoc.Content_Document_Id__c);
            updateDoc.Content_Document_Id__c = null;
        }
        update doc;
        Database.delete(deleteIds);
    }

    @AuraEnabled
    public static void insertDocumentCheckList(Id recordId,List<String> docNames,String type){
        try {
            Document_Master__c doc=[Select id,Document_Name__c from Document_Master__c where Document_Name__c=:type];
            List<Document_Details__c> docCheckList = new List<Document_Details__c>();
            for(String docName : docNames){
                docCheckList.add(
                    new Document_Details__c(
                        Name = docName,
                        Document_Master__c = doc.id,
                        Loan_Application__c = recordId
                        
                    )
                );
            }
            insert docCheckList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteDocumentCheckList(Id recordId){
        try {
            delete [SELECT Id FROM Document_Details__c WHERE Id =:recordId];
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<CheckBoxWrapper> getDocumentNames(String docName){
        try {
            List<CheckBoxWrapper> wrapper = new List<CheckBoxWrapper>();
            String formattedDocName = '%'+docName+'%';
            List<Document_Master__c> docMaster = [SELECT Id,Document_Name__c FROM Document_Master__c WHERE Document_Name__c LIKE :formattedDocName];
            for(Document_Master__c doc : docMaster){
                wrapper.add(new CheckBoxWrapper(doc.Document_Name__c ,doc.Id));
            }
            return wrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class CheckBoxWrapper{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public CheckBoxWrapper(String label,String value){
            this.label = label;
            this.value = value;
        }
    }

    public class DocCheckWrapper{
        @AuraEnabled public Integer srno;
        @AuraEnabled public String docId;
        @AuraEnabled public String contentId;
        @AuraEnabled public String docName;
        @AuraEnabled public Boolean isReqired;
        @AuraEnabled public Boolean isUploaded;
        @AuraEnabled public Boolean isUploadNeeded;
        public DocCheckWrapper(Document_Details__c doc,Integer srno){
            this.srno = srno;
            this.docId = doc.Id;
            this.contentId = doc.Content_Document_Id__c;
            this.docName = doc.name;
            //this.isReqired = !doc.Is_Doc_Required__c;
            this.isUploaded = this.contentId == null ? true : false;
            this.isUploadNeeded = !this.isUploaded;
        }
    }
    
    @AuraEnabled
    public static List<String> getCurrentLoanActions(String recordId) {
        List<String> showActions = new List<String>();
        try{
            List<Opportunity> loanDetails = [SELECT Id, StageName FROM Opportunity WHERE Id =: recordId LIMIT 1];
            
            String profileName = getCurrentUserProfileName();
            
            Map<String, Integer> sequenceMap = new Map<String, Integer>();
            Map<String, Activity_Panel_Action_Visibility_Master__mdt> sequenceList = Activity_Panel_Action_Visibility_Master__mdt.getAll();
            for(Activity_Panel_Action_Visibility_Master__mdt iterSeq : sequenceList.values()){
                if(iterSeq.Stage__c == loanDetails[0].StageName && profileName == iterSeq.Persona__c) {
                    showActions.add(iterSeq.Action_Name__c);
                }
            }
            
            
        }catch(Exception exp){
            Utility.generateException(exp,'Opportunity', 'InitiateScreenController');
        }
        System.debug('showActions -->'+showActions);
        
        return showActions;
    }
    @AuraEnabled
    public static String getCurrentUserProfileName(){
        String profileName = '';
        Id profileId=userinfo.getProfileId();
        String profileNameStr=[Select Id,Name from Profile where Id=:profileId].Name;
        if(profileNameStr == 'System Administrator'||profileNameStr=='Credit Manager') {
            profileName = 'Admin';
            return 'Admin';
        }
        for(PermissionSetAssignment iter :[SELECT Id, PermissionSet.Name, PermissionSet.ProfileId, PermissionSet.Profile.Name, AssigneeId, Assignee.Name FROM PermissionSetAssignment WHERE Assignee.id=: UserInfo.getUserId()]){
            if(iter.PermissionSet.Name == 'PS_FCU_Sampler') {
                profileName = 'Sampler';
                return 'Sampler';
            }
            if(iter.PermissionSet.Name == 'PS_FCU_Admin') {
                profileName = 'FCU Admin';
                return 'FCU Admin';
            }
            if(iter.PermissionSet.Name == 'PS_FCU_Executive') {
                profileName = 'FCU Executive';
                return 'FCU Executive';
            }
            if(iter.PermissionSet.Name == 'PS_Credit_Manager') {
                profileName = 'Credit Manager';
                return 'Credit';
            }
            if(iter.PermissionSet.Name == 'PS_FCU_Head') {
                profileName = 'FCU Head';
                return 'FCU Head';
            }
        }
        return profileName;
    }
    @AuraEnabled
    public static Boolean isHunterInitiated(String recordId) {
        Boolean isHit = false;
        string recordtypeid = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' AND Name = 'Hunter Verification' LIMIT 1].id;
        List<Application_Verification__c> applic = [SELECT id ,name, Hunter_Decision__c, Hunter_Match__c From Application_Verification__c where Loan_Application__c = :recordId and RecordTypeId = :recordtypeid  LIMIT 1];
       // List<Opportunity> loanDetails = [SELECT Id, Hunter_Match__c, Hunter_Decision__c FROM Opportunity WHERE Id =: recordId LIMIT 1];
        if(applic.size() > 0 && applic[0].Hunter_Match__c != null && applic[0].Hunter_Decision__c != null) {
            isHit = true;
        }
        return isHit;
    }
    @AuraEnabled
    public static Boolean isFCUInitiated(String recordId) {
        Boolean isHit = false;
        string recordtypeid = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' AND Name = 'FCU' LIMIT 1].id;
        List<Application_Verification__c> applic = [SELECT id ,name From Application_Verification__c where Loan_Application__c = :recordId and RecordTypeId = :recordtypeid  LIMIT 1];
       // List<Opportunity> loanDetails = [SELECT Id, Hunter_Match__c, Hunter_Decision__c FROM Opportunity WHERE Id =: recordId LIMIT 1];
        if(applic.size() > 0 ) {
            isHit = true;
        }
        return isHit;
    }
}