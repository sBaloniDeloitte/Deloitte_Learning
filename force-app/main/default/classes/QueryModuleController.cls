/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-02-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class QueryModuleController {

    static string conLabels = 'Edit,Read';
                         
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
    @AuraEnabled
    public static List<String> getQueryTypes(String moduleName){
        try {
            Map<String, Query_Module__mdt> allMetaData = Query_Module__mdt.getAll();
            List<String> queryTypes = new List<String>();
            for(Query_Module__mdt module : allMetaData.values()) {
              if (module.Module_Name__c == moduleName) {
                    String[] values = module.Value_to_be_shown__c.split(',');
                    queryTypes.addAll(values);
                    break;
                }
            }
    
            return queryTypes;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static List<String> getQueryCategory(String moduleName){
        try {
            Map<String, Query_Module__mdt> allMetaData = Query_Module__mdt.getAll();
            List<String> queryCategory = new List<String>();
            for(Query_Module__mdt module : allMetaData.values()) {
              if (module.Module_Name__c == moduleName) {
                    String[] values = module.Query_Category__c.split(',');
                    queryCategory.addAll(values);
                    break;
                }
            }
    
            return queryCategory;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static UserWrapper getCurrentUserName() {
        UserWrapper us =  new UserWrapper();
        User currentUser = [SELECT FirstName, LastName,UserRole.Name,UserRoleId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        us.userName  = currentUser.FirstName + ' ' + currentUser.LastName; 
        us.userId = currentUser.Id;
        us.userRole = currentUser.UserRoleId!=null ? currentUser.UserRole.Name : '';
        return us;
    }

    @AuraEnabled
    public static List<RequestedUsers> getRequestedFromUsers(String recordValue){
        try {
            List<RequestedUsers> requestedFromUsersList = new List<RequestedUsers>();
            List<OpportunityTeamMember> oppTeamList = new List<OpportunityTeamMember>();
            
            List<Legal__c> legalRec = [SELECT Id, Loan_Application__c FROM Legal__c WHERE Id =:recordValue LIMIT 1];
            List<Technical_Evaluation__c> technicalRec = [SELECT Id, HL_Loan_Application__c FROM Technical_Evaluation__c WHERE Id =:recordValue LIMIT 1];
            if(!legalRec.isEmpty()){
                oppTeamList = [Select  Id, OpportunityId, UserId, Name, TeamMemberRole from OpportunityTeamMember where OpportunityId =:legalRec[0].Loan_Application__c];
            }
            else if(!technicalRec.isEmpty()){
                oppTeamList = [Select  Id, OpportunityId, UserId, Name, TeamMemberRole from OpportunityTeamMember where OpportunityId =:technicalRec[0].HL_Loan_Application__c];
            }
            else{
                oppTeamList = [Select  Id, OpportunityId, UserId, Name, TeamMemberRole from OpportunityTeamMember where OpportunityId=:recordValue];
            }
            for(OpportunityTeamMember opp:oppTeamList ){
                RequestedUsers rs = new RequestedUsers();
                rs.userName = opp.Name+ '  -  ' + opp.TeamMemberRole;
                rs.userId = opp.UserId;
                requestedFromUsersList.add(rs);
            }
            User currentUser = [SELECT Id, Name FROM User  WHERE Id = :UserInfo.getUserId()];
            RequestedUsers rs1 = new RequestedUsers();
                rs1.userName = currentUser.Name+ '  -  Credit';
                rs1.userId = currentUser.Id;
                requestedFromUsersList.add(rs1);
            
           System.debug('requestedFromUsersList---'+requestedFromUsersList);
            return requestedFromUsersList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class RequestedUsers{
        @AuraEnabled public  String userName;
        @AuraEnabled  public String userId;
    }
    @AuraEnabled
    public static Boolean checktypeofDoc(Id recordId) {
        try {
            Query__c q = [SELECT Id, Requested_from_Users__c, Requestor__c, Previous_Responders__c, 
                                 Type_of_Record__c, Query_Type__c 
                          FROM Query__c WHERE Id = :recordId];
    
            return (q.Type_of_Record__c == 'Parent' && q.Query_Type__c == 'Document');
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static RecordWrapper setDocRecordButtons(Id recordId) {
        String objectName, fieldAPIName = 'Status__c', profileName, recordStatus, previousFieldValue;
        List<Query_Module_Buttons__mdt> buttonStatus;
        SObject record;
        List<ButtonWrapper> wrapper = new List<ButtonWrapper>();
        Set<String> uniqueButtonNames = new Set<String>(); // To ensure uniqueness
        try {
            Boolean singleRequestedByUser = false;
            Boolean previousResponder = false;
            Boolean isRequestor = false;
            List<String> requestedFromUsersList = new List<String>();
            List<String> previousRequestedFromUsersList = new List<String>();
            objectName = recordId.getSObjectType().getDescribe().getName();
            if (objectName == 'Query__c') {
                List<Query__c> childq = [SELECT Id, Status__c, Requested_from_Users__c, Type_of_Record__c, Query_Type__c, 
                                          Requestor__c, Previous_Responders__c 
                                          FROM Query__c WHERE Parent_Query__c = :recordId];
                
                for (Query__c q : childq) {
                    requestedFromUsersList = q.Requested_from_Users__c != null ? q.Requested_from_Users__c.split(',') : new List<String>();
                    previousRequestedFromUsersList = q.Previous_Responders__c != null ? q.Previous_Responders__c.split(',') : new List<String>();
                    singleRequestedByUser = requestedFromUsersList.contains(UserInfo.getUserId()) && requestedFromUsersList.size() == 1;
                    previousResponder = previousRequestedFromUsersList.contains(UserInfo.getUserId());
                    isRequestor = q.Requestor__c == UserInfo.getUserId();
                    System.debug('isRequestor: ' + isRequestor);
                    System.debug('requestedFromUsersList: ' + requestedFromUsersList);
                    System.debug('singleRequestedByUser: ' + singleRequestedByUser);
                    System.debug('previousResponder: ' + previousResponder);
                    buttonStatus = [
                        SELECT Id, Comparison_Object__c, Field_API_Name__c, Button_Label__c, Record_Status__c, 
                               Single_Requested_From_User__c, Requestor__c, Is_Previous_Responder__c
                        FROM Query_Module_Buttons__mdt 
                        WHERE Comparison_Object__c = :objectName
                        AND Profile_Name__c = :[SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1].Name
                        AND Stage__c = :q.Status__c 
                        AND Single_Requested_From_User__c = :singleRequestedByUser
                        AND Requestor__c = :isRequestor
                        AND Is_Previous_Responder__c = :previousResponder
                        LIMIT 1
                    ];
                    if (!buttonStatus.isEmpty() && buttonStatus[0].Button_Label__c != null && buttonStatus[0].Record_Status__c != null) {
                        List<String> labels = buttonStatus[0].Button_Label__c.split(',');
                        List<String> statuses = buttonStatus[0].Record_Status__c.split(',');  
                        System.debug('labels: ' + labels);
                        System.debug('statuses: ' + statuses);
                        for (Integer i = 0; i < labels.size(); i++) {
                            if (i < statuses.size()) { // Prevents index out-of-bounds
                                String label = labels[i];
                                String status = statuses[i];
                                if (!uniqueButtonNames.contains(label)) { // Ensure uniqueness
                                    uniqueButtonNames.add(label);
                                    System.debug('uniqueButtonNames: ' + uniqueButtonNames);
                                    wrapper.add(new ButtonWrapper(label, status)); // Correct mapping (Label → Status)
                                    System.debug('wrapper: ' + wrapper);
                                }
                            }
                        }
                    }
                }
            }
            
            return new RecordWrapper(objectName, fieldAPIName, previousFieldValue, 'Open', wrapper);
            
        } catch (Exception exp) {
            throw new AuraHandledException(exp.getMessage());
        }
    }
    
    

    @AuraEnabled
    public static RecordWrapper setRecordButtons(Id recordId){
        String objectName,fieldAPIName = 'Status__c',profileName,recordStatus,previousFieldValue;
        List<Query_Module_Buttons__mdt> buttonStatus;
        SObject record;
        List<ButtonWrapper> wrapper = new List<ButtonWrapper>();
        try {
            Boolean singleRequestedByUser = false;
            Boolean previousResponder = false;
            Boolean isRequestor = false;
            List<String > requestedFromUsersList = new List<String>();
            List<String > previousRequestedFromUsersList = new List<String>();
            Query__c q =  new Query__c ();
            objectName  = recordId.getSObjectType().getDescribe().getName();
            System.debug('objectName>>>'+ objectName);
            if(objectName  == 'Query__c'){
                q = [Select id, Requested_from_Users__c, Requestor__c,Previous_Responders__c from Query__c where id =:recordId];
                requestedFromUsersList = q.Requested_from_Users__c.split(',');
                if( q.Previous_Responders__c != null){
                previousRequestedFromUsersList = q.Previous_Responders__c.split(',');
                }
                if(requestedFromUsersList.contains(UserInfo.getUserId())){
                singleRequestedByUser = requestedFromUsersList.size() == 1 ? true: false;
                }
                else{
                    singleRequestedByUser = false;
                }
                if(previousRequestedFromUsersList.contains(UserInfo.getUserId())){
                    previousResponder = true;
                }
                else{
                    previousResponder = false;
                }
                
                isRequestor = q.Requestor__c == UserInfo.getUserId() ? true : false;
            }
            else if(objectName == 'Legal__c' || objectName == 'Technical_Evaluation__c') {
                isRequestor = true;
            }
            else if(objectName  == 'Opportunity'){
                isRequestor = true;
            }
           
            if(objectName == 'Opportunity' || objectName == 'Query__c'){
            record = Database.query('SELECT Id,Status__c FROM '+objectName+' WHERE Id = \''+recordId+'\' LIMIT 1');
            }
            
         
            if(objectName  != 'Query__c'){
            recordStatus = 'Open';
            }
            else{
             recordStatus = (String)record.get('Status__c') != null ? (String)record.get('Status__c') : 'Open';
            }
            system.debug('status '+ recordStatus);
            profileName = [SELECT Id,Name FROM Profile WHERE Id=:UserInfo.getProfileId() LIMIT 1].Name;
            String currentRole;
            List<OpportunityTeamMember> oppTeamList = new List<OpportunityTeamMember>();
            if(objectName == 'Query__c' || objectName == 'Opportunity'){
                oppTeamList = [Select  Id, OpportunityId, UserId, Name, TeamMemberRole from OpportunityTeamMember where OpportunityId=:recordId and UserId = :UserInfo.getUserId()];
            }
            else if(objectName == 'Legal__c'){
                List<Legal__c> legalRec = [SELECT Id, Loan_Application__c FROM Legal__c WHERE Id =:recordId];
                oppTeamList = [Select  Id, OpportunityId, UserId, Name, TeamMemberRole from OpportunityTeamMember where OpportunityId=:legalRec[0].Loan_Application__c and UserId = :UserInfo.getUserId()];
            }
            else if(objectName == 'Technical_Evaluation__c'){
                List<Technical_Evaluation__c> technicalRec = [SELECT Id, HL_Loan_Application__c FROM Technical_Evaluation__c WHERE Id =:recordId];
                oppTeamList = [Select  Id, OpportunityId, UserId, Name, TeamMemberRole from OpportunityTeamMember where OpportunityId=:technicalRec[0].HL_Loan_Application__c and UserId = :UserInfo.getUserId()];
            }            system.debug('OppoTeamList '+ oppTeamList);
            if(oppTeamList.size() > 0){
                currentRole = oppTeamList[0].TeamMemberRole;
            }
            if(objectName  != 'Query__c'){
                buttonStatus = [
                    SELECT Id,Comparison_Object__c,Field_API_Name__c,Button_Label__c,Record_Status__c
                    FROM Query_Module_Buttons__mdt 
                    WHERE Comparison_Object__c =:objectName 
                    AND Profile_Name__c =:profileName 
                    AND Stage__c =: recordStatus
                    LIMIT 1
                ];
            }
            else{
                buttonStatus = [
                    SELECT Id,Comparison_Object__c,Field_API_Name__c,Button_Label__c,Record_Status__c,Single_Requested_From_User__c,Requestor__c
                    FROM Query_Module_Buttons__mdt 
                    WHERE Comparison_Object__c =:objectName 
                    AND Profile_Name__c =:profileName 
                    AND Stage__c =: recordStatus
                    AND Single_Requested_From_User__c =:singleRequestedByUser
                    AND Requestor__c =:isRequestor
                    AND Is_Previous_Responder__c =:previousResponder
                    LIMIT 1
                ];
                System.debug('buttonStatus '+buttonStatus);
            }
            if(buttonStatus.size()>0){
                if(buttonStatus[0].Record_Status__c != null && buttonStatus[0].Button_Label__c != null){
                    List<String> status = buttonStatus[0].Record_Status__c.split(',');
                    List<String> labels = buttonStatus[0].Button_Label__c.split(',');
                    
                    for(Integer index = 0;index< labels.size();index++){
                        wrapper.add(
                            new ButtonWrapper(labels[index],status[index])
                        );
                    }
                }
               
            }
            return new RecordWrapper(objectName,fieldAPIName,previousFieldValue,recordStatus,wrapper);
           
        }
        catch (Exception exp) {
            throw new AuraHandledException(exp.getMessage());
        }
    }
    public class RecordWrapper{
        @AuraEnabled public String objectAPIName;
        @AuraEnabled public String fieldAPIName;
        @AuraEnabled public String previousFieldValue;
        @AuraEnabled public String fieldValue;
        @AuraEnabled public List<ButtonWrapper> buttons;
        public RecordWrapper(String objectAPIName,String fieldAPIName,String previousFieldValue,String fieldValue,List<ButtonWrapper> buttons){
            this.objectAPIName = objectAPIName;
            this.fieldAPIName = fieldAPIName;
            this.previousFieldValue = previousFieldValue;
            this.fieldValue = fieldValue;
            this.buttons = buttons;
        }
    }
    public class ButtonWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public String value;
        public ButtonWrapper(String name,String value){
            this.name = name;
            this.value = value;
        }
    }
    @AuraEnabled
    public static void sendNotification(String recordId,String status,List<String> assignedUserIds){
        try {
            String curentDtTime = System.now().format();
            String currentUserName = UserInfo.getFirstName() +' '+ UserInfo.getLastName();
            String newEntry;
            List<User> assignedUser = [SELECT Id,Name FROM User WHERE Id IN : assignedUserIds];
             
            
            Set<String> recipientsId = new Set<String>();
            for(User u : assignedUser){
                recipientsId.add(u.id);
            }
         
            System.debug('status---'+status);
            if(status=='Assigned'){
                Utility.sendInAppNotification(recordId, 'Query Assignment', 'A query has been assinged to you. Please click to view the reference details.', recipientsId, 'Duplicate_Lead');
                
            }
            if(status=='Sent Back'){
                Utility.sendInAppNotification(recordId, 'Query Sent Back', 'A query has been sent back to you. Please click to view the reference details.', recipientsId, 'Duplicate_Lead');
            }
            if(status=='Response Sent'){
                Utility.sendInAppNotification(recordId, 'Query Responsed', 'A query has been addressed and sent to you. Please click to view the reference details.', recipientsId, 'Duplicate_Lead');
            }
            if(status =='Re-assgined'){
                Utility.sendInAppNotification(recordId, 'Query Re-assgined', 'A query has been Re-assgined to you. Please click to view the reference details.', recipientsId, 'Duplicate_Lead');
            }
        }
        catch(Exception e){

        }
    }

    @AuraEnabled
    public static List<DocumentWrapper> getDocumentChecklist(Id recordId, String searchTerm, String requestedByUser) {
        String objectName = '';
        Schema.SObjectType objType = recordId.getSObjectType();
        objectName = objType.getDescribe().getName();
        List<String> requirementLevels = new List<String>();

        if(objectName == 'Legal__c' || objectName == 'Technical_Evaluation__c'){
          return getLegalTechDocumentChecklist(recordId, searchTerm, requestedByUser);  
        }
        else if (objectName == 'Opportunity') {
            requirementLevels.add('Loan Application');
            requirementLevels.add('Applicant Level');
        } else if (objectName == 'Lead') {
            requirementLevels.add('Lead');
        } else if (objectName == 'Application_Verification__c') {
            requirementLevels.add('Application Verification');
        }
    
        List<DocumentWrapper> documentList = new List<DocumentWrapper>();
        if (String.isEmpty(searchTerm)) {
            List<Document_Details__c> firstDocDetails = [
                SELECT Id, Name, Requirement_Level__c, Status__c, Loan_Application__r.Name, Applicant__r.Name, Loan_Application__c, Applicant__c, Description__c, Content_Document_Id__c
                FROM Document_Details__c
                WHERE Loan_Application__c = :recordId AND (Requirement_Level__c = 'Loan Application' OR Requirement_Level__c = 'Application Level' OR Requirement_Level__c = 'Applicant Level')
                LIMIT 1
            ];
    
            if (!firstDocDetails.isEmpty()) {
                Document_Details__c doc = firstDocDetails[0];
                DocumentWrapper docWrapper = new DocumentWrapper();
                if (doc.Requirement_Level__c == 'Loan Application' || doc.Requirement_Level__c == 'Application Level') {
                    docWrapper.documentName = doc.Name + ' -  ' + doc.Loan_Application__r.Name;
                } else if (doc.Requirement_Level__c == 'Applicant Level') {
                    docWrapper.documentName = doc.Name + '  - ' + doc.Applicant__r.Name;
                }
                docWrapper.documentContentId = doc.Content_Document_Id__c;
                system.debug('doc.Content_Document_Id__c ' + doc.Content_Document_Id__c);
                docWrapper.showPreview = doc.Content_Document_Id__c != null;
                docWrapper.showUploadIcon = requestedByUser != UserInfo.getUserId();
                system.debug('showUploadIcon ' +docWrapper.showUploadIcon);
                docWrapper.showDeleteButton = requestedByUser == UserInfo.getUserId();
                docWrapper.documentDescription = doc.Description__c;
                docWrapper.requirementLevel = doc.Requirement_Level__c;
                docWrapper.fromDocMaster = false;
                docWrapper.docId = doc.Id;
                documentList.add(docWrapper);
            }
    
            if (documentList.isEmpty() && !requirementLevels.isEmpty()) {
                List<Document_Master__c> masterDocs = [
                    SELECT Id, Name, Requirement_At__c, Document_Category__c, Sub_Category__c
                    FROM Document_Master__c
                    WHERE Requirement_At__c IN :requirementLevels
                    LIMIT 5
                ];
    
                for (Document_Master__c masterDoc : masterDocs) {
                    DocumentWrapper docWrapper = new DocumentWrapper();
                    docWrapper.documentName = masterDoc.Name;
                    docWrapper.showPreview = false;
                    docWrapper.showUploadIcon = requestedByUser != UserInfo.getUserId();
                    docWrapper.showDeleteButton = requestedByUser == UserInfo.getUserId();
                    docWrapper.documentDescription = '';
                    docWrapper.requirementLevel = masterDoc.Requirement_At__c;
                    docWrapper.docCategory = masterDoc.Document_Category__c;
                    docWrapper.docSubCategory = masterDoc.Sub_Category__c;
                    docWrapper.fromDocMaster = true;
                    docWrapper.docId = masterDoc.Id;
                    documentList.add(docWrapper);
                }
            }
        } else {
            for (Document_Details__c doc : [
                SELECT Id, Name, Requirement_Level__c, Status__c, Description__c, Content_Document_Id__c, Loan_Application__r.Name, Applicant__r.Name, Loan_Application__c, Applicant__c
                FROM Document_Details__c
                WHERE Loan_Application__c = :recordId AND (Requirement_Level__c = 'Loan Application' OR Requirement_Level__c = 'Application Level' OR Requirement_Level__c = 'Applicant Level')
                AND Name LIKE :('%' + searchTerm + '%')
                LIMIT 5
            ]) {
                DocumentWrapper docWrapper = new DocumentWrapper();
                if (doc.Requirement_Level__c == 'Loan Application' || doc.Requirement_Level__c == 'Application Level') {
                    docWrapper.documentName = doc.Name + ' -  ' + doc.Loan_Application__r.Name;
                } else if (doc.Requirement_Level__c == 'Applicant Level') {
                    docWrapper.documentName = doc.Name + '  - ' + doc.Applicant__r.Name;
                }
                docWrapper.documentContentId = doc.Content_Document_Id__c;
                docWrapper.showPreview = doc.Content_Document_Id__c != null;
                docWrapper.showUploadIcon = requestedByUser != UserInfo.getUserId();
                docWrapper.showDeleteButton = requestedByUser == UserInfo.getUserId();
                docWrapper.documentDescription = doc.Description__c;
                docWrapper.requirementLevel = doc.Requirement_Level__c;
                docWrapper.docId = doc.Id;
                docWrapper.fromDocMaster = false;
                documentList.add(docWrapper);
            }
    
            if (documentList.isEmpty()) {
                for (Document_Master__c masterDoc : [
                    SELECT Id, Name, Requirement_At__c, Document_Category__c, Sub_Category__c
                    FROM Document_Master__c
                    WHERE Name LIKE :('%' + searchTerm + '%') AND Requirement_At__c IN :requirementLevels
                    LIMIT 5
                ]) {
                    DocumentWrapper docWrapper = new DocumentWrapper();
                    docWrapper.documentName = masterDoc.Name;
                    docWrapper.showPreview = false;
                    docWrapper.showUploadIcon = requestedByUser != UserInfo.getUserId();
                    docWrapper.showDeleteButton = requestedByUser == UserInfo.getUserId();
                    docWrapper.documentDescription = '';
                    docWrapper.requirementLevel = masterDoc.Requirement_At__c;
                    docWrapper.docCategory = masterDoc.Document_Category__c;
                    docWrapper.docSubCategory = masterDoc.Sub_Category__c;
                    docWrapper.fromDocMaster = true;
                    docWrapper.docId = masterDoc.Id;
                    documentList.add(docWrapper);
                }
            }
        }
        return documentList;
    }

@AuraEnabled
public static List<DocumentWrapper> getLegalTechDocumentChecklist(Id recordId, String searchTerm, String requestedByUser) {
    List<DocumentWrapper> documentList = new List<DocumentWrapper>();

    // Determine the object type of the recordId
    String objectType = recordId.getSObjectType().getDescribe().getName();

    // Determine which field to use in the query (Legal__c or Technical__c)
    String lookupField = '';
    String relationshipName = '';

    if (objectType == 'Legal__c') {
        lookupField = 'Legal__c';
        relationshipName = 'Legal__r';
    } else if (objectType == 'Technical_Evaluation__c') {
        lookupField = 'Technical__c';
        relationshipName = 'Technical__r';
    } else {
        // Unsupported object type
        return documentList;
    }

    String baseQuery =
        'SELECT Id, Name, Requirement_Level__c, Status__c, Description__c, Content_Document_Id__c, ' +
        'Loan_Application__r.Name, Applicant__r.Name, Loan_Application__c, Applicant__c, ' + relationshipName + '.Name ' +
        'FROM Document_Details__c WHERE ' + lookupField + ' = :recordId ';

    // If searchTerm is empty, fetch one document
    if (String.isEmpty(searchTerm)) {
        baseQuery += 'LIMIT 1';
        List<Document_Details__c> docs = Database.query(baseQuery);
        if (!docs.isEmpty()) {
            Document_Details__c doc = docs[0];
            DocumentWrapper docWrapper = new DocumentWrapper();
            docWrapper.documentName = doc.Name + ' - ' + doc.getSObject(relationshipName).get('Name');
            docWrapper.documentContentId = doc.Content_Document_Id__c;
            docWrapper.showPreview = doc.Content_Document_Id__c != null;
            docWrapper.showUploadIcon = requestedByUser != UserInfo.getUserId();
            docWrapper.showDeleteButton = requestedByUser == UserInfo.getUserId();
            docWrapper.documentDescription = doc.Description__c;
            docWrapper.requirementLevel = doc.Requirement_Level__c;
            docWrapper.fromDocMaster = false;
            docWrapper.docId = doc.Id;
            documentList.add(docWrapper);
        }
    } else {
        // Add search filter and limit for search scenario
        String temp = '%' + searchTerm + '%';
        baseQuery += 'AND Name LIKE :temp LIMIT 5';
        List<Document_Details__c> docs = Database.query(baseQuery);
        for (Document_Details__c doc : docs) {
            DocumentWrapper docWrapper = new DocumentWrapper();
            docWrapper.documentName = doc.Name + ' - ' + doc.getSObject(relationshipName).get('Name');
            docWrapper.documentContentId = doc.Content_Document_Id__c;
            docWrapper.showPreview = doc.Content_Document_Id__c != null;
            docWrapper.showUploadIcon = requestedByUser != UserInfo.getUserId();
            docWrapper.showDeleteButton = requestedByUser == UserInfo.getUserId();
            docWrapper.documentDescription = doc.Description__c;
            docWrapper.requirementLevel = doc.Requirement_Level__c;
            docWrapper.docId = doc.Id;
            docWrapper.fromDocMaster = false;
            documentList.add(docWrapper);
        }
    }

    return documentList;
}

    @AuraEnabled
    public static List<RequirementWrapper> getRequirementLevelOptions(String requirementLevel, Id recordId){
        try {
            String objectName = '';
            String loanId;
            Schema.SObjectType objType = recordId.getSObjectType();
            objectName = objType.getDescribe().getName();
            String query ;
            if(objectName != 'Opportunity'){
             query = 'SELECT Id, Loan_Application__c FROM ';
            }
            List<RequirementWrapper> reqList  = new List<RequirementWrapper>();
          
           
            if(objectName == 'Opportunity'){
                loanId = recordId;
            }else{
                query +=  objectName + ' WHERE Id = :recordId';
            }
            List<Sobject> sobjList = new  List<Sobject>();
            System.debug('query----'+ query);
            if(query!=null){
                sobjList= Database.query(query);
            }
            if(sobjList != null && !sobjList.isEmpty()){
                loanId  = String.valueof(sobjList[0].get('Loan_Application__c'));
            }
            if(requirementLevel =='Applicant Level' ){
                List<Application_Applicant__c> applicantList = [Select id, Applicant_Name__c from Application_Applicant__c where Loan_Application__c=:loanId];
                for(Application_Applicant__c app : applicantList){
                    RequirementWrapper rw =  new RequirementWrapper();
                    rw.label = app.Applicant_Name__c;
                    rw.value = app.id;
                    reqList.add(rw);
                }
            }
            if(requirementLevel == 'Loan Application' ){
                Opportunity opp= [Select id, Name from Opportunity where id=:loanId];
                RequirementWrapper rw =  new RequirementWrapper();
                rw.label = opp.Name;
                rw.value = opp.id;
                reqList.add(rw);
            }
            return reqList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static String assignDocQueryRecord(String recordId, String buttonValue, String docWrapper, String queryTypeOptions, String queryCategoryOptions,
                                                Map<String, List<String>> requestedFromUsers, Map<String, List<String>> queue, Map<String, String> remarks) {
        // try {
            System.debug('queue----' + queue);
            User currentUser = [SELECT Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            List<Legal__c> legalRec = [SELECT Id, Loan_Application__c FROM Legal__c WHERE Id = :recordId];
            List<Technical_Evaluation__c> technicalRec = [SELECT Id, HL_Loan_Application__c FROM Technical_Evaluation__c WHERE Id = :recordId];
            List<DocumentWrapperDeserialized> docWrList = (List<DocumentWrapperDeserialized>) JSON.deserialize(docWrapper, List<DocumentWrapperDeserialized>.class);
            /* ------------------ Parent Query ------------------ */
            RecordType parentRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Query__c' AND Name = 'Document' LIMIT 1];
            Query__c parentQuery = new Query__c(
                Status__c = buttonValue,
                Requestor__c = UserInfo.getUserId(),
                Query_Category__c = queryCategoryOptions,
                Query_Type__c = queryTypeOptions,
                Type_of_Record__c = 'Parent',
                RecordTypeId = parentRT.Id
            );
            if (legalRec.isEmpty() && technicalRec.isEmpty()) {
                parentQuery.Loan_Application__c = recordId;
            } else if (!legalRec.isEmpty()) {
                parentQuery.Legal__c = recordId;
                parentQuery.Loan_Application__c = legalRec[0].Loan_Application__c;
            } else {
                parentQuery.Technical_Evaluation__c = recordId;
                parentQuery.Loan_Application__c = technicalRec[0].HL_Loan_Application__c;
            }
            insert parentQuery;
            /* ------------------ Document Handling ------------------ */
            List<Document_Details__c> toInsert = new List<Document_Details__c>();
            List<Document_Details__c> toUpdate = new List<Document_Details__c>();

            Map<Id, Document_Details__c> docKeyToDetail = new Map<Id, Document_Details__c>();
            Map<Id, Id> detailToContentMap = new Map<Id, Id>();

            for (DocumentWrapperDeserialized docWr : docWrList) {
                if (docWr.docId == null) continue; // || docWr.docContentId == null
                Id docId = (Id) docWr.docId;
                if (docId.getSObjectType() == Document_Master__c.SObjectType) {
                    Document_Details__c d = new Document_Details__c(
                        Name = 'Query Doc',
                        Document_Master__c = docId,
                        Content_Document_Id__c = docWr.docContentId,
                        Status__c = 'Uploaded',
                        Active__c = true
                    );

                    if (legalRec.isEmpty() && technicalRec.isEmpty()) {
                        d.Loan_Application__c = recordId;
                    } else if (!legalRec.isEmpty()) {
                        d.Loan_Application__c = legalRec[0].Loan_Application__c;
                    } else {
                        d.Loan_Application__c = technicalRec[0].HL_Loan_Application__c;
                    }
                    toInsert.add(d);
                    docKeyToDetail.put(docId, d);
                } else if (docId.getSObjectType() == Document_Details__c.SObjectType) {
                    detailToContentMap.put(docId, (Id) docWr.docContentId);
                }
            }

            if (!detailToContentMap.isEmpty()) {
                for (Document_Details__c d : [SELECT Id, Content_Document_Id__c FROM Document_Details__c WHERE Id IN :detailToContentMap.keySet()
                ]) {
                    d.Content_Document_Id__c = detailToContentMap.get(d.Id);
                    d.Status__c = 'Uploaded';
                    d.Active__c = true;
                    toUpdate.add(d);
                    docKeyToDetail.put(d.Id, d);
                }
            }

            if (!toInsert.isEmpty()) insert toInsert;
            if (!toUpdate.isEmpty()) update toUpdate;

            /* ------------------ ContentDocumentLink ------------------ */
            Set<String> cdlKeys = new Set<String>();
            List<ContentDocumentLink> toLink = new List<ContentDocumentLink>();
            Set<Id> docDetailIds = new Set<Id>();
            for (Document_Details__c d : docKeyToDetail.values()) {
                if (d.Id != null) {
                    docDetailIds.add(d.Id);
                }
            }

            if (!docDetailIds.isEmpty()) {
                for (ContentDocumentLink cdl : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :docDetailIds
                ]) {
                    cdlKeys.add(cdl.ContentDocumentId + '-' + cdl.LinkedEntityId);
                }
            }

            for (DocumentWrapperDeserialized docWr : docWrList) {
                if (!docKeyToDetail.containsKey((Id) docWr.docId)) continue;
                Document_Details__c d = docKeyToDetail.get((Id) docWr.docId);
                String key = docWr.docContentId + '-' + d.Id;
                if (!cdlKeys.contains(key)) {
                    if (docWr.docContentId != null) {
                        toLink.add(new ContentDocumentLink(
                            ContentDocumentId = docWr.docContentId,
                            LinkedEntityId = d.Id,
                            ShareType = 'V',
                            Visibility = 'AllUsers'
                        ));
                    }
                }
            }
            if (!toLink.isEmpty()) insert toLink;
            /* ------------------ Child Queries ------------------ */
            List<Query__c> childQueries = new List<Query__c>();
            Map<Id, Id> docDetailToQueryId = new Map<Id, Id>();
            Set<String> uniqueUserIds = new Set<String>();
            Set<String> uniqueQueueIds = new Set<String>();

            for (DocumentWrapperDeserialized docWr : docWrList) {
                if (!docKeyToDetail.containsKey((Id) docWr.docId)) continue;
                Query__c q = new Query__c();
                q.Status__c = buttonValue;
                q.Requestor__c = UserInfo.getUserId();
                q.Query_Category__c = queryCategoryOptions;
                q.Query_Type__c = queryTypeOptions;
                q.Type_of_Record__c = 'Child';
                q.Parent_Query__c = parentQuery.Id;
                if (legalRec.isEmpty() && technicalRec.isEmpty()) {
                    q.Loan_Application__c = recordId;
                } else if (!legalRec.isEmpty()) {
                    q.Legal__c = recordId;
                    q.Loan_Application__c = legalRec[0].Loan_Application__c;
                } else {
                    q.Technical_Evaluation__c = recordId;
                    q.Loan_Application__c = technicalRec[0].HL_Loan_Application__c;
                }
                q.Document_Details__c = docKeyToDetail.get((Id) docWr.docId).Id;
                if (requestedFromUsers.containsKey(docWr.docId)) {
                    q.Requested_from_Users__c = String.join(requestedFromUsers.get(docWr.docId), ',');
                    System.debug('Requested_from_Users__c '+q.Requested_from_Users__c);
                    uniqueUserIds.addAll(requestedFromUsers.get(docWr.docId));
                }
                if (queue.containsKey(docWr.docId)) {
                    q.CC_Queue__c = String.join(queue.get(docWr.docId), ',');
                    uniqueQueueIds.addAll(queue.get(docWr.docId));
                }
                childQueries.add(q);
            }
            insert childQueries;
            for (Query__c q : childQueries) {
                docDetailToQueryId.put(q.Document_Details__c, q.Id);
            }
            System.debug('docDetailToQueryId Map doc, query: ' + docDetailToQueryId);
            /* ------------------ Remarks ------------------ */
            List<Note> notes = new List<Note>();
            for (Id docDetailId : remarks.keySet()) {
                System.debug('docDetailId Inside remarks.keySet - '+docDetailId);
                if (docDetailToQueryId.containsKey(docDetailId)) {
                    notes.add(new Note(
                        ParentId = docDetailToQueryId.get(docDetailId),
                        Body = remarks.get(docDetailId),
                        Title = 'Open;Query Remark - ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss') + ' by ' + currentUser.Name
                    ));
                } else {
                    for (Id keyDocDetailId : docDetailToQueryId.keySet()) {
                        Id queryId = docDetailToQueryId.values().iterator().next();
                        notes.add(new Note(
                            ParentId = queryId,
                            Body = remarks.get(docDetailId),
                            Title = 'Open;Query Remark - ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss') + ' by ' + currentUser.Name
                        ));
                    }
                }
            }
            System.debug('notes: '+notes);
            if (!notes.isEmpty()) insert notes;

            List<ContentVersion> versionsToInsert = new List<ContentVersion>();
            Map<Id, Id> docDetailToContentVersionId = new Map<Id, Id>();
            for (Id docDetailId : remarks.keySet()) {
                if (!docDetailToQueryId.containsKey(docDetailId)) {
                    continue;
                }

                ContentVersion cv = new ContentVersion();
                cv.Title = 'Open;Query Remark - ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss') + ' by ' + currentUser.Name;
                cv.VersionData = Blob.valueOf(remarks.get(docDetailId));
                cv.PathOnClient = 'QueryRemark.snote';
                versionsToInsert.add(cv);
                docDetailToContentVersionId.put(docDetailId, null);
            }
            if (!versionsToInsert.isEmpty()) {
                insert versionsToInsert;
            }
            List<ContentDocumentLink> noteLinks = new List<ContentDocumentLink>();
            for (ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :versionsToInsert]) {
                for (Id docDetailId : docDetailToContentVersionId.keySet()) {
                    if (docDetailToContentVersionId.get(docDetailId) == null) {
                        docDetailToContentVersionId.put(docDetailId, cv.ContentDocumentId);

                        noteLinks.add(new ContentDocumentLink(
                            ContentDocumentId = cv.ContentDocumentId,
                            LinkedEntityId = docDetailToQueryId.get(docDetailId),
                            ShareType = 'V',
                            Visibility = 'AllUsers'
                        ));
                        break;
                    }
                }
            }

            if (!noteLinks.isEmpty()) {
                insert noteLinks;
            }
            /* ------------------ Update Parent Query ------------------ */
            parentQuery.Requested_from_Users__c = String.join(new List<String>(uniqueUserIds), ',');
            parentQuery.CC_Queue__c = String.join(new List<String>(uniqueQueueIds), ',');
            update parentQuery;
            String assignedToRoles;
            List<OpportunityTeamMember> teamMembers = [SELECT Id, OpportunityId, UserId, Name, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId= :recordId AND UserId IN :uniqueUserIds];
            Set<String> assignedRoles= new Set<String>();
            for(OpportunityTeamMember teamMember: teamMembers){
                assignedRoles.add(teamMember.TeamMemberRole);
            }
            List<GroupMember> queueMembers = [ SELECT GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN :uniqueQueueIds];
            Set<String> queueUserIds = new Set<String>();
            for (GroupMember gm : queueMembers) {
                queueUserIds.add(gm.UserOrGroupId);
            }
            uniqueUserIds.addAll(queueUserIds);
            List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
            for (DocumentWrapperDeserialized docWr : docWrList) {
                if (requestedFromUsers.containsKey(docWr.docId)) {
                    Id childQueryId = docDetailToQueryId.get(docWr.docId);
                    System.debug('requestedFromUsers '+requestedFromUsers.get(docWr.docId));
                    System.debug('requestedFromUsers '+requestedFromUsers.get(docWr.docId));
                    List<String> userList = requestedFromUsers.get(docWr.docId);
                    if (userList != null) {
                        System.debug('Size of userList: ' + userList.size());
                        if(userList.size() == 1){
                            for (String userId : requestedFromUsers.get(docWr.docId)) {
                                System.debug('userId '+userId);
                                System.debug('childQueryId '+childQueryId);
                                Utility.SharingInfo si = new Utility.SharingInfo();
                                si.recordToShareId = childQueryId;
                                si.userOrGroupId = userId;
                                si.objectName = 'Query__c';
                                si.sharingAccess = constants.get('Edit');
                                sharingList.add(si);
                            }
                        }
                        else{
                            for (String userId : requestedFromUsers.get(docWr.docId)) {
                                System.debug('userId '+userId);
                                System.debug('childQueryId '+childQueryId);
                                Utility.SharingInfo si = new Utility.SharingInfo();
                                si.recordToShareId = childQueryId;
                                si.userOrGroupId = userId;
                                si.objectName = 'Query__c';
                                si.sharingAccess = constants.get('Read');
                                sharingList.add(si);
                            }
                        }
                    } 
                }
            }
            for (String userId : uniqueUserIds) {
                Utility.SharingInfo si = new Utility.SharingInfo();
                si.recordToShareId = parentQuery.Id;
                si.userOrGroupId = userId;
                si.objectName = 'Query__c';
                si.sharingAccess = constants.get('Read');
                sharingList.add(si);
            }
            System.debug('uniqueUserIds '+uniqueUserIds);
            System.debug('sharingList '+sharingList);
            Utility.createShareRecord(JSON.serialize(sharingList));
            sendNotification(parentQuery.Id, 'Assigned', new List<String>(uniqueUserIds)); // notification
            /* ------------------ TAT Record Creation ------------------ */
            List<Opportunity> loanData= [SELECT Id, StageName FROM Opportunity WHERE Id = :recordId];
            if(loanData.size() >0){
                TAT__c tatRecord = new TAT__c();
                tatRecord.Activity__c = 'Query';
                tatRecord.Sub_Activity__c = 'Query Raised';
                tatRecord.User_Name__c = UserInfo.getUserId();
                tatRecord.Timestamp__c = System.now();
                tatRecord.Loan_Application__c = recordId;
                tatRecord.Stage__c =loanData[0].StageName;
                tatRecord.Associated_Query__c = parentQuery.Id;
                tatRecord.Query_Assigned_To_Users__c = String.join(new List<String>(assignedRoles), ',');
                insert tatRecord;
            }
            return parentQuery.Id;
        // } catch (Exception e) {
        //     throw new AuraHandledException(e.getMessage());
        // }
    }


    @AuraEnabled
    public static string assignQueryRecord(string recordId,String buttonValue,List<String> requestedFromUsers,String docWrapper,String remarks,String queryTypeOptions, String queryCategoryOptions,List<String> queue, Boolean IsPreAddedDocument){
        try {
            RecordType parentRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Query__c' AND Name = 'Non Document' LIMIT 1];
            System.debug('queue----'+queue);
            User currentUser = [SELECT Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            List<DocumentWrapperDeserialized> docWr = (List<DocumentWrapperDeserialized>)JSON.deserialize(docWrapper, List<DocumentWrapperDeserialized>.class);
            System.debug('docWr '+docWr);
            Query__c q  = new Query__c();
            for(String  userId : requestedFromUsers){
                if(q.Requested_from_Users__c == null){
                    q.Requested_from_Users__c = userId;
                }
                else{
                    q.Requested_from_Users__c +=','+userId;
                }
            }
            for(String queues: queue){
                if(q.CC_Queue__c == null){
                    q.CC_Queue__c = queues;
                    System.debug(' q.CC_Queue__c----'+ q.CC_Queue__c);
                }
                else{
                    q.CC_Queue__c +=','+queues;
                    System.debug(' q.CC_Queue__c----'+ q.CC_Queue__c);
                }
            }
            List<Legal__c> legalRec = [SELECT Id,Loan_Application__c FROM Legal__c WHERE Id =:recordId];
            List<Technical_Evaluation__c> technicalRec = [SELECT Id, HL_Loan_Application__c FROM Technical_Evaluation__c WHERE Id =:recordId];
            if (!legalRec.isEmpty() && legalRec[0].Loan_Application__c != null) {
                q.Legal__c = recordId;
                q.Loan_Application__c = legalRec[0].Loan_Application__c;
            } 
            else if(!technicalRec.isEmpty() && technicalRec[0].HL_Loan_Application__c != null) {
                q.Technical_Evaluation__c = recordId;
                q.Loan_Application__c = technicalRec[0].HL_Loan_Application__c;
            }    
            else {
                q.Loan_Application__c = recordId;
            }            
            q.Status__c = buttonValue;
            // q.Loan_Application__c = recordId;
            q.Requestor__c =UserInfo.getUserId();
            q.Query_Category__c =queryCategoryOptions;
            q.Query_Type__c=queryTypeOptions;
            q.RecordTypeId = parentRecordType.Id;
            q.Type_of_Record__c = 'Parent';
            q.Remarks__c = remarks;
            insert q;
            List<Document_Details__c> documentList = new List<Document_Details__c>();
            for(DocumentWrapperDeserialized docWrList :docWr ){
                if(docWrList.documentRecievedFrom == true){
                    Document_Details__c d  = new Document_Details__c();
                    d.Document_Master__c = docWrList.docId;
                    d.Name = docWrList.label;
                    d.Status__c = 'Uploaded';
                    d.Content_Document_Id__c = docWrList.docContentId;
                    d.Requirement_Level__c = docWrList.requirementLevel;
                    d.Query__c = q.id;
                    documentList.add(d);
                }
                else{
                    Document_Details__c d  = new Document_Details__c();
                    d.id = docWrList.docId;
                    d.Query__c = q.id;
                    d.Name = docWrList.label;
                    documentList.add(d);
                }
            }
            upsert documentList;
            List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
            for(Document_Details__c dd : documentList){
                for(String userId : requestedFromUsers){
                Utility.SharingInfo si = new Utility.SharingInfo();
                si.recordToShareId = dd.id;
                si.userOrGroupId = userId;
                si.objectName ='Document_Details__c';
                si.sharingAccess = constants.get('Edit');
                sharingList.add(si);
                }
            }
            for(String userId : requestedFromUsers){
                Utility.SharingInfo si = new Utility.SharingInfo();
                si.recordToShareId = q.id;
                si.userOrGroupId = userId;
                si.objectName ='Query__c';
                si.sharingAccess = constants.get('Edit');
                sharingList.add(si);
            }
                
            if (!queue.isEmpty()) {
                List<GroupMember> queueMembers = [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN :queue];
                Set<String> queueUserIds = new Set<String>();
                for (GroupMember gm : queueMembers) {
                    queueUserIds.add(gm.UserOrGroupId);
                }
                // Grant Read access to queue users
                for (Document_Details__c dd : documentList) {
                    for (String userId : queueUserIds) {
                        Utility.SharingInfo si = new Utility.SharingInfo();
                        si.recordToShareId = dd.id;
                        si.userOrGroupId = userId;
                        si.objectName = 'Document_Details__c';
                        si.sharingAccess = constants.get('Read');
                        sharingList.add(si);
                    }
                }
                for (String userId : queueUserIds) {
                    Utility.SharingInfo si = new Utility.SharingInfo();
                    si.recordToShareId = q.id;
                    si.userOrGroupId = userId;
                    si.objectName = 'Query__c';
                    si.sharingAccess = constants.get('Read');
                    sharingList.add(si);
                }
            }

            Note newNote = new Note();
            //newNote.Title = 'Open';
            newNote.Body = remarks;
            newNote.ParentId = q.id; 
            
            
            newNote.Title = 'Open;Query Remark - ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss') + ' by ' + currentUser.Name;
            insert newNote;

            // Query__c history = new Query__c();
            // history.Remarks__c = remarks;
            // history.Remarks_Status__c =buttonValue ;
            // history.Parent_Query__c = q.id;
            // history.RecordTypeId = queryRemarks;
            // insert history;

            // for(String userId : requestedFromUsers){
            //     Utility.SharingInfo si = new Utility.SharingInfo();
            //     si.recordToShareId = history.id;
            //     si.userOrGroupId = userId;
            //     si.objectName ='Query__c';
            //     si.sharingAccess = constants.get('Read');
            //     sharingList.add(si);
            // }
            
            Utility.createShareRecord(JSON.serialize(sharingList));
            sendNotification(q.id,'Assigned',requestedFromUsers);
            String assignedToRoles;
            List<OpportunityTeamMember> teamMembers = [SELECT Id, OpportunityId, UserId, Name, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId= :recordId AND UserId IN :requestedFromUsers];
            Set<String> assignedRoles= new Set<String>();
            for(OpportunityTeamMember teamMember: teamMembers){
                assignedRoles.add(teamMember.TeamMemberRole);
            }
            List<Opportunity> loanData= [SELECT Id, StageName FROM Opportunity WHERE Id = :recordId];
            if(loanData.size() >0){
                TAT__c tatRecord = new TAT__c();
                tatRecord.Activity__c = 'Query';
                tatRecord.Sub_Activity__c = 'Query Raised';
                tatRecord.User_Name__c = UserInfo.getUserId();
                tatRecord.Timestamp__c = System.now();
                tatRecord.Loan_Application__c = recordId;
                tatRecord.Stage__c =loanData[0].StageName;
                tatRecord.Associated_Query__c = q.Id;
                tatRecord.Query_Assigned_To_Users__c = String.join(new List<String>(assignedRoles), ',');
                insert tatRecord;
            }
            return q.id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Map<String, String>> sendQueryEmail(Id loanId, Id queryId, String event) {
        // Email sending logic removed as QueryEmailInvocable is discarded
        // This method is now a stub and returns an empty list
        return new List<Map<String, String>>();
    }

    @AuraEnabled
    public static boolean sendResponse(String parentId,string recordId, string buttonValue, String remarks,String docWrap){
        try {
            List<DocumentWrapperNonDoc> docWr = (List<DocumentWrapperNonDoc>)JSON.deserialize(docWrap, List<DocumentWrapperNonDoc>.class);
            User currentUser = [SELECT Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
            system.debug('sharing list is ' + sharingList);
            Query__c q = [SELECT Id, Status__c, Requestor__c,Query_Type__c,Document_Details__c FROM Query__c WHERE Id = :recordId LIMIT 1];
            String previousStatus = '';
            system.debug('Query is ' + q);
            if (q.Query_Type__c == 'Document') {
                if(q.Document_Details__c != null) {
                    Document_Details__c docObj = new Document_Details__c();
					docObj.id =	q.Document_Details__c;
                    docObj.Screening_Status__c = 'Pending';
                    docObj.Verification_Status__c = 'Pending';
                    update docObj;
                }
            }
            
            List<Query__History> historyRecords = [SELECT OldValue, NewValue FROM Query__History 
                                                   WHERE Field = 'Status__c' AND ParentId = :recordId 
                                                   ORDER BY CreatedDate DESC LIMIT 1];

            system.debug('HistoryRecords ' + historyRecords);
    
            if (!historyRecords.isEmpty() && historyRecords[0].NewValue != null) {
                previousStatus = String.valueOf(historyRecords[0].NewValue);
            }
    
            q.Status__c = buttonValue;
            q.Responder__c = currentUser.Id;
            update q;
            system.debug('updated q is ' + q);
            List<String> assignedUserIds = new List<String>();
            assignedUserIds.add(q.Requestor__c);
            List<Document_Master__c> docMaster = [SELECT Id, Name FROM Document_Master__c WHERE Requirement_At__c = 'Loan Application' AND Name = 'Other' LIMIT 1];
            system.debug('docmaster ' + docmaster);
            List<Document_Details__c> documentList = new List<Document_Details__c>();
            for(DocumentWrapperNonDoc docWrList :docWr ){
                    if(docWrList.documentId==null || docWrList.documentId == '' ){
                    Document_Details__c d  = new Document_Details__c();
                    d.Document_Master__c = docMaster[0].id;
                    d.Name = docWrList.documentName;
                    d.Status__c = 'Uploaded';
                    d.Content_Document_Id__c = docWrList.contentId;
                    if(docWrList.contactName!=null && docWrList.contactName!=''){
                    d.Applicant__c  = docWrList.contactName;
                    }
                    d.Requirement_Level__c = docWrList.reqLevel;
                    d.Query__c = q.id;
                    documentList.add(d);
                    }
            }
            insert documentList;
            system.debug('documentList ' + documentList);
           
            for(Document_Details__c dd : documentList){
                for(String userId : assignedUserIds){
                Utility.SharingInfo si = new Utility.SharingInfo();
                si.recordToShareId = dd.id;
                si.userOrGroupId = userId;
                si.objectName ='Document_Details__c';
                si.sharingAccess = constants.get('Edit');
                sharingList.add(si);
                }
            }

            system.debug('sharingList '+ sharingList);

            Note newNote = new Note();
            newNote.Title =previousStatus ;
            newNote.Body = remarks;
            newNote.ParentId = recordId; 
           
            
            newNote.Title = buttonValue+';'+'Query Remark - ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss') + ' by ' + currentUser.Name;
            insert newNote;
            // Utility.SharingInfo si = new Utility.SharingInfo();
            // si.recordToShareId = history.id;
            // si.userOrGroupId = q.Requestor__c;
            // si.objectName ='Query__c';
            // si.sharingAccess = constants.get('Read');
            // sharingList.add(si);
        
             Utility.createShareRecord(JSON.serialize(sharingList));
           if(parentId!=null && parentId!='' && parentId!='undefined'){
            sendNotification(parentId,buttonValue,assignedUserIds);
           }
           else{
            sendNotification(recordId,buttonValue,assignedUserIds);
           }
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
@AuraEnabled
public static boolean sendDocResponse(String parentId,List<String> queryIds, String buttonValue, Map<String, String> remarksMap){
    try {
        User currentUser = [SELECT Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
        List<Query__c> queriesToUpdate = [SELECT Id, Status__c, Requestor__c FROM Query__c WHERE Id IN :queryIds];
        Map<String, String> previousStatusMap = new Map<String, String>();
        List<Note> notesToInsert = new List<Note>();
        List<String> assignedUserIds = new List<String>();
        // Fetch previous status history for all queries
        Map<String, String> historyMap = new Map<String, String>();
        for (Query__History historyRecord : [
            SELECT ParentId, NewValue FROM Query__History 
            WHERE Field = 'Status__c' AND ParentId IN :queryIds 
            ORDER BY CreatedDate DESC
        ]) {
            if (!historyMap.containsKey(historyRecord.ParentId)) {
                historyMap.put(historyRecord.ParentId, String.valueOf(historyRecord.NewValue));
            }
        }
        // Update queries and prepare Notes
        for (Query__c q : queriesToUpdate) {
            String previousStatus = historyMap.containsKey(q.Id) ? historyMap.get(q.Id) : '';
            q.Status__c = buttonValue; 
            // Add requestor ID for sharing
            if (q.Requestor__c != null) {
                assignedUserIds.add(q.Requestor__c);
            }
            // Add Note for each query with its respective remark
            if (remarksMap.containsKey(q.Id)) {
                Note newNote = new Note();
                newNote.Title = buttonValue + '; Query Remark - ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss') + ' by ' + currentUser.Name;
                newNote.Body = remarksMap.get(q.Id);
                newNote.ParentId = q.Id;
                notesToInsert.add(newNote);
            } else {
                throw new AuraHandledException('Missing remark for Query ID: ' + q.Id);
            }
        }
        update queriesToUpdate; 
        insert notesToInsert;
        for (Query__c q : queriesToUpdate) {
            for (String userId : assignedUserIds) {
                Utility.SharingInfo si = new Utility.SharingInfo();
                si.recordToShareId = q.Id;
                si.userOrGroupId = userId;
                si.objectName = 'Query__c';
                si.sharingAccess = constants.get('Read');
                sharingList.add(si);
            }
        }
        Utility.createShareRecord(JSON.serialize(sharingList));
        // Send notifications
            sendNotification(parentId, buttonValue, assignedUserIds);
        return true;
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}

    @AuraEnabled
    public static string acceptRecord(String recordId, String buttonValue) {
        try {
            User currentUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
            List<Note> notesToInsert = new List<Note>();
            List<Query__c> queriesToUpdate = new List<Query__c>();
            List<Query__History> historyRecords = [SELECT OldValue, NewValue, ParentId 
                                                   FROM Query__History 
                                                   WHERE Field = 'Status__c' 
                                                   AND ParentId IN (SELECT Id FROM Query__c WHERE Parent_Query__c = :recordId) 
                                                   ORDER BY CreatedDate DESC];
    
            // Query main record
  Query__c mainQuery = [SELECT Id, OwnerId, Status__c, Query_Type__c,Requestor__c, Requested_From_Users__c,Parent_Query__c,
                                  Previous_Responders__c FROM Query__c WHERE Id = :recordId LIMIT 1];    
            List<Query__c> recordsToProcess = new List<Query__c>();
    
            // If Query_Type__c == 'Document', fetch child records
            /*if (mainQuery.Query_Type__c == 'Document') {
                recordsToProcess = [SELECT Id,OwnerId, Status__c, Query_Type__c, Requestor__c, Requested_From_Users__c, Previous_Responders__c 
                                    FROM Query__c WHERE Id = :recordId];
                
            } else {
                recordsToProcess.add(mainQuery); // Process only the single record if not a document type
            }*/
            if (mainQuery.Parent_Query__c != null) {
                 recordsToProcess.add(mainQuery);
            }
            else if (mainQuery.Query_Type__c == 'Document') {
                recordsToProcess = [SELECT Id, OwnerId, Status__c, Query_Type__c, Requestor__c, Requested_From_Users__c, Previous_Responders__c FROM Query__c  WHERE Parent_Query__c = :recordId ];
            }
            else {
                recordsToProcess.add(mainQuery);
            }
            if (recordsToProcess.isEmpty()) {
                return 'No Records Found';
            }
            for (Query__c q : recordsToProcess) {
                q.Previous_Responders__c = null;
                queriesToUpdate.add(q);
    
                String previousStatus = '';
                for (Query__History history : historyRecords) {
                    if (history.ParentId == q.Id && history.NewValue != null) {
                        previousStatus = String.valueOf(history.NewValue);
                        break;
                    }
                }
    
                List<String> previousResponders = new List<String>();
    
                if (q.Requested_From_Users__c != null) {
                    List<String> requestedUsers = q.Requested_From_Users__c.split(',');
                    List<String> remainingUsers = new List<String>();
                    for (String userId : requestedUsers) {
                        System.debug('939');
                        if (userId != currentUser.Id) {
                            System.debug('941');
                            previousResponders.add(userId);
                            Map<String, String> sharingParams = new Map<String, String>{
                                'objectName' => 'Query__Share',
                                'recordId' => q.Id,
                                'userId' => userId
                            };
                            if(q.OwnerId!=userId ){
                            Utility.deleteSharedRecord(sharingParams);
                            Utility.SharingInfo si = new Utility.SharingInfo();
                            si.recordToShareId = q.Id;
                            si.userOrGroupId = userId;
                            si.objectName = 'Query__c';
                            si.sharingAccess = constants.get('Edit');
                            sharingList.add(si);
                        }
                    }
                    else{
                        System.debug('960');
                            Map<String, String> sharingParams = new Map<String, String>{
                                'objectName' => 'Query__Share',
                                'recordId' => q.Id,
                                'userId' => userId
                            };
                            if(q.OwnerId!=userId ){
                            System.debug('967');
                            //Utility.deleteSharedRecord(sharingParams);
                            Utility.SharingInfo si = new Utility.SharingInfo();
                            si.recordToShareId = q.Id;
                            si.userOrGroupId = userId;
                            si.objectName = 'Query__c';
                            si.sharingAccess = constants.get('Edit');
                            sharingList.add(si);
                        }
                    }
                    }
                    q.Requested_From_Users__c = currentUser.Id;
                    q.Responder__c = currentUser.Id;
                    if (!previousResponders.isEmpty()) {
                        q.Previous_Responders__c = q.Previous_Responders__c != null 
                            ? q.Previous_Responders__c + ',' + String.join(previousResponders, ',') 
                            : String.join(previousResponders, ',');
                    }
                }
                q.Status__c = buttonValue;
                // Add note for each record
                Note newNote = new Note();
                newNote.Title = buttonValue + '; Query Accepted - ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss') + ' by ' + currentUser.Name;
                newNote.ParentId = q.Id;
                newNote.Body = 'Query accepted by ' + currentUser.Name + '. Status changed from "' + previousStatus + '" to "' + buttonValue + '".';
                notesToInsert.add(newNote);
            }
            // Perform bulk updates and inserts
            if (!sharingList.isEmpty()) {
                Utility.createShareRecord(JSON.serialize(sharingList));
            }
            if (!queriesToUpdate.isEmpty()) {
                update queriesToUpdate;
            }
            if (!notesToInsert.isEmpty()) {
                insert notesToInsert;
            }
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    

    @AuraEnabled
    public static string reassignRecord(String parentId,string recordId,String buttonValue,String remarks,List<String> requestedFromUsers){
        try {
            User currentUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    
            List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
    
            // Fetch the existing Query__c record
            Query__c q = [SELECT Id, Status__c, Requestor__c, Requested_From_Users__c, Previous_Responders__c
                          FROM Query__c WHERE Id = :recordId LIMIT 1];
    
            Set<String> uniqueUsers = new Set<String>();
            uniqueUsers.addAll(requestedFromUsers);

            q.Requested_from_Users__c = uniqueUsers.isEmpty() ? null : String.join(new List<String>(uniqueUsers), ',');
            q.Status__c = buttonValue;
            q.Previous_Responders__c = '';
            q.Responder__c = null;
            if(uniqueUsers.size() == 1 ){
                for(id i : requestedFromUsers){
                q.Responder__c =i;
                }
            }
            update q;
    
            // Fetch related Document_Details__c records
            List<Document_Details__c> docDetails = [SELECT Id, Query__c, Status__c FROM Document_Details__c WHERE Query__c = :recordId];
    
            for (Document_Details__c doc : docDetails) {
                for (String userId : uniqueUsers) {
                    Utility.SharingInfo si = new Utility.SharingInfo();
                    si.recordToShareId = doc.Id;
                    si.userOrGroupId = userId;
                    si.objectName = 'Document_Details__c';
                    si.sharingAccess = constants.get('Edit');
                    sharingList.add(si);
                }
            }
    
            // Add sharing for Query__c object
            for (String userId : uniqueUsers) {
                Utility.SharingInfo si = new Utility.SharingInfo();
                si.recordToShareId = q.Id;
                si.userOrGroupId = userId;
                si.objectName = 'Query__c';
                si.sharingAccess = constants.get('Edit');
                sharingList.add(si);
            }
    
            Note newNote = new Note();
            newNote.Body = remarks;
            newNote.ParentId = q.Id;
            newNote.Title = buttonValue + '; Query Reassigned - ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss') + ' by ' + currentUser.Name;
            insert newNote;
    
            Utility.createShareRecord(JSON.serialize(sharingList));
            if(parentId!=null && parentId!=''){
                sendNotification(parentId,'Re-assigned', new List<String>(uniqueUsers));
               }
               else{
                sendNotification(q.Id, 'Re-assigned', new List<String>(uniqueUsers));
               }
    
            return 'Success';
    
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string sendRecordBack(String parentId,String recordId, String buttonValue, String remarks) {
        try {
            User currentUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Query__c q = [SELECT Id, Status__c, Requested_From_Users__c 
                        FROM Query__c WHERE Id = :recordId LIMIT 1];
            if (String.isEmpty(q.Requested_From_Users__c)) {
                throw new AuraHandledException('No previous user found to reassign this record.');
            }   

            String requestedUserId = q.Requested_From_Users__c;
            q.Status__c = buttonValue;
            update q;

            Note newNote = new Note();
            
            newNote.ParentId = recordId;
            newNote.Body = remarks;
            newNote.Title =buttonValue+';'+'Query Returned - ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss')+ ' by ' + currentUser.Name;
            insert newNote;
            List<String> assignedUserIds = new List<String>{requestedUserId};
            if(parentId!=null && parentId!=''){
                sendNotification(parentId,buttonValue,assignedUserIds);
               }
               else{
                sendNotification(recordId,buttonValue,assignedUserIds);
               }

            return 'Success';

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string closedRevertRecord(String parentId,String recordId, String buttonValue, String remarks){
        try {
            User currentUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Query__c q = [SELECT Id, Status__c, Requested_From_Users__c ,Document_Details__c,Loan_Application__c
                        FROM Query__c WHERE Id = :recordId LIMIT 1];
                        if (q.Document_Details__c != null){
                            Document_Details__c doc = [
                                SELECT Id, Screening_Status__c ,Verification_Status__c
                                FROM Document_Details__c 
                                WHERE Id = :q.Document_Details__c 
                                LIMIT 1
                            ];
                                
                                doc.Screening_Status__c = 'Pending';
                            doc.Verification_Status__c = 'Pending';
                                update doc;
                            
                        }
            //  List<Document_Details__c> docList = [SELECT Id, Screening_Status__c from Document_Details__c where Query__c =:recordId and Screening_Status__c = 'On Hold'];
            // if(docList != null && docList.size() > 0){
            //     docList[0].Screening_Status__c = 'Pending';
            // }
            // update docList;
          
           

            String requestedUserId = q.Requested_From_Users__c;
            q.Status__c = buttonValue;
            update q;
            Note newNote = new Note();
          
            newNote.ParentId = recordId;
            newNote.Body = remarks;
            newNote.Title =buttonValue+';'+'Query Closed - ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss')+ ' by ' + currentUser.Name;
            insert newNote;
            List<String> assignedUserIds = new List<String>{requestedUserId};
            if(parentId!=null && parentId!=''){
                sendNotification(parentId,buttonValue,assignedUserIds);
               }
               else{
                sendNotification(recordId,buttonValue,assignedUserIds);
               }


            List<TAT__c> openTATRecords = [SELECT Id,End_Timestamp__c,Loan_Application__c  FROM TAT__c WHERE Loan_Application__c = :q.Loan_Application__c AND Activity__c = 'Query' AND End_Timestamp__c = null AND Associated_Query__c = :parentId];
            if(!openTATRecords.isEmpty()){
                for(TAT__c tatRecord: openTATRecords){
                    tatRecord.End_Timestamp__c = System.now();
                }
                if(openTATRecords.size()>0){
                    update openTATRecords;
                }
            }
            return 'Success';

            
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getLoanId(Id recordValue){
        try {
            String objectName;
            String loanId;
            objectName  = recordValue.getSObjectType().getDescribe().getName();
            if(objectName == 'Query__c'){
                  loanId = [SELECT Loan_Application__c FROM Query__c WHERE Id = :recordValue LIMIT 1].Loan_Application__c;
            }
            if(objectName == 'Application_Verification__c'){
                loanId = [SELECT Loan_Application__c FROM Application_Verification__c WHERE Id = :recordValue LIMIT 1].Loan_Application__c;
            }
            else if(objectName == 'Opportunity'){
                loanId = recordValue;
            }
            return loanId;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<QueueWrapper> getQueuesForOpportunity(String recordId) {
        try {
            List<QueueWrapper> queueList = new List<QueueWrapper>();
            Opportunity opp = new Opportunity();
            List<Legal__c> legalRec = [SELECT Id, Loan_Application__c FROM Legal__c WHERE Id =:recordId];
            List<Technical_Evaluation__c> technialRec = [SELECT Id, HL_Loan_Application__c FROM Technical_Evaluation__c WHERE Id =:recordId];
            if(!legalRec.isEmpty() || !technialRec.isEmpty()){
                return null;
            }
            else{
             opp = [
                SELECT Id, Branch_Master__r.Name 
                FROM Opportunity 
                WHERE Id = :recordId 
                LIMIT 1
            ];   
            }
            
            
            String branchName = opp.Branch_Master__r.Name.toUpperCase();
            List<Group> queues = [
                SELECT Id, Name 
                FROM Group 
                WHERE Type = 'Queue' 
                
            ];

            for (Group queue : queues) {
                QueueWrapper qw  = new QueueWrapper();
                qw.queueName = queue.Name;
                qw.queueId = queue.Id;
                qw.branchName = branchName;
                queueList.add(qw);
            }

            System.debug('Queue List: ' + queueList);
            return queueList;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<DocumentWrapperDeserialized> getPreCreatedDocumentChecklist(String documentChecklist, Id recordId, String loanId){
        try {
            String objectName;
            objectName  = recordId.getSObjectType().getDescribe().getName();
            List<DocumentWrapperDeserialized> documentList = new List<DocumentWrapperDeserialized>();
            List<Document_Details__c> docList = new  List<Document_Details__c> ();
            docList = [Select id,Name,Requirement_Level__c,Content_Document_Id__c from Document_Details__c where id = :documentChecklist and Loan_Application__c = :recordId];
            for(Document_Details__c doc : docList){
                DocumentWrapperDeserialized dw = new DocumentWrapperDeserialized();
                dw.label = doc.Name;
                dw.requirementLevel = doc.Requirement_Level__c;
                dw.value = doc.id;
                dw.docId = doc.id;
                dw.disabledDelete = true;
                if(doc.Content_Document_Id__c!=null){
                    dw.showPreview = true;
                }
                else{
                    dw.showPreview = false;
                }
                dw.docContentId =doc.Content_Document_Id__c;

                documentList.add(dw);
            }
            return documentList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static List<UserWrapper> getallApplicants(String loanId) {
        List<Application_Applicant__c> applicants = [SELECT Id, Name FROM Application_Applicant__c WHERE Loan_Application__c = :loanId];
        List<UserWrapper> userList = new List<UserWrapper>();
        for (Application_Applicant__c applicant : applicants) {
            UserWrapper uw = new UserWrapper();
            uw.userName = applicant.Name;
            uw.userId = applicant.Id;
            userList.add(uw);
        }
        return userList;
    }
    @AuraEnabled
    public static Boolean checkdocrequiredfor(String docId){
        Boolean applicant = false;
        try {
            Document_Master__c dm = [Select Id,name,Requirement_Level__c from Document_Master__c where Id=:docId];    
            if(dm.Requirement_Level__c == 'Applicant Level'){
                applicant = true;
            }
            else{
                applicant = false;
            }
            return applicant;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    
    public class DocumentWrapperDeserialized {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String requirementLevel;
        @AuraEnabled public Boolean showPreview;
        @AuraEnabled public String documentDescription;
        @AuraEnabled public Boolean documentRecievedFrom;
        @AuraEnabled public String docContentId;
        @AuraEnabled public String docId;
        @AuraEnabled public boolean disabledDelete;
     

    }

    public class DocumentWrapper {
        @AuraEnabled public String documentName;
        @AuraEnabled public String requirementLevel;
        @AuraEnabled public Boolean showPreview;
        @AuraEnabled public Boolean showUploadIcon;
        @AuraEnabled public Boolean showEditButton;
        @AuraEnabled public Boolean showDeleteButton;
        @AuraEnabled public String documentDescription;
        @AuraEnabled public String documentContentId;
        @AuraEnabled public Boolean fromDocMaster;
        @AuraEnabled public String docCategory;
        @AuraEnabled public String docSubCategory;
        @AuraEnabled public String docId; 
        @AuraEnabled  public string contentDocumentId;
        @AuraEnabled public String reqLevel;
       

    }

    public class UserWrapper{
        @AuraEnabled public String userName;
        @AuraEnabled public String userId;
        @AuraEnabled public String userRole;
    }

    public class RequirementWrapper{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        
    }

    public class DocumentWrapperNonDoc{
        @AuraEnabled public string documentId;
        @AuraEnabled  public string documentName;
        @AuraEnabled  public string contentId;
        @AuraEnabled  public boolean showUpload;
        @AuraEnabled public boolean showPreview;
        @AuraEnabled public string reqLevel;
        @AuraEnabled public string status;
        @AuraEnabled public string description ;
        @AuraEnabled  public string contactName;
        @AuraEnabled  public boolean disableCustomerName;
        
    }
    public class QueueWrapper {
        @AuraEnabled
        public String queueName;
        @AuraEnabled
        public String queueId;
        @AuraEnabled
        public String branchName;
    }

   @AuraEnabled
   public static List<DocumentWrapperDeserialized> createchecklistrecord(List<String> appIds, String loanId, String docMasterId) {
       try {
        Document_Master__c docMaster = [SELECT Id,Requirement_Level__c,Name from Document_Master__c where Id = :docMasterId];
           List<Document_Details__c> documentDetailsList = new List<Document_Details__c>();
           for (String appId : appIds) {
               Document_Details__c documentDetails = new Document_Details__c();
               documentDetails.Loan_Application__c = loanId;
               documentDetails.Document_Master__c = docMasterId;
               documentDetails.Applicant__c = appId;
               documentDetails.Name = docMaster.Name;
               documentDetails.Requirement_Level__c = docMaster.Requirement_Level__c;
               documentDetailsList.add(documentDetails);
           }
           // Insert the Document_Details__c records
           insert documentDetailsList;
           // Query the inserted records
List<Document_Details__c> insertedRecords = [SELECT Id, Name,Applicant__r.Applicant_Name__c, Requirement_Level__c, Content_Document_Id__c 
                                            FROM Document_Details__c WHERE Id IN :documentDetailsList];
           // Fill the DocumentWrapper list
           List<DocumentWrapperDeserialized> documentWrapperList = new List<DocumentWrapperDeserialized>();
           for(Document_Details__c doc : insertedRecords){
               DocumentWrapperDeserialized dw = new DocumentWrapperDeserialized();
               dw.label = doc.Name + ' - '+ doc.Applicant__r.Applicant_Name__c;
               dw.requirementLevel = doc.Requirement_Level__c;
               dw.docId = doc.id;
               dw.value = doc.id;
               if(doc.Content_Document_Id__c!=null){
                   dw.showPreview = true;
               }
               else{
                   dw.showPreview = false;
               }
               dw.docContentId =doc.Content_Document_Id__c;
               documentWrapperList.add(dw);
           }
           return documentWrapperList;
       } catch (Exception e) {
           throw new AuraHandledException(e.getMessage());
       }
    }

    @AuraEnabled
    public static void deleteNonDocumentChecklist(String recordId) {
      try {
         Document_Details__c recordToDelete = [SELECT Id FROM Document_Details__c WHERE Id = :recordId LIMIT 1];
         delete recordToDelete;
        } catch (Exception e) {
         throw new AuraHandledException('Failed to delete record: ' + e.getMessage());
        }
    }
    

    /* public static void script(){
        String loanId= '';
        List<Application_Applicant__c> appList = [
            SELECT Id, Name,Loan_Application__r.name,Applicant_Type__c,Name_of_Organization__c,Customer_Type__c,Customer_LMS_Id__c,Customer__r.SF_Customer_ID__c, Salutation__c,First_Name__c, Last_Name__c, Company__c, Loan_Application__r.Product__c, Email__c, Mobile_Number__c, Loan_Application__r.Owner.Name FROM Application_Applicant__c 
            WHERE Loan_Application__c = :loanId 
        ];
        
        
        List<Integration_Details__c> communicationList= [SELECT Id FROM Integration_Details__c WHERE Loan_Application__c = :loanId AND Endpoint__c = 'Acknowledge of login'];
        
        if (!appList.isEmpty()) {
            String loanProduct;
            String messageWrapper;
            List<String> avaliableProducts= new List<String>{'Affordable Home Loan', 'Affordable Non-Home Loan', 'Home Loan', 'Non Home Loan', 'Flexi Loan'};
            List<product2> productList= [SELECT Id, name, Description, Product__r.Product__r.name, Product__r.Name FROM product2 WHERE  Loan_Application__c = :loanId AND RecordType.name = 'Variant' AND Product__r.Product__r.name IN :avaliableProducts AND Product__r.Product__r.Product_Type__c = 'Parent'];
            List<CommunicationEventWrapper.LoginAcknowledgeWrapper> loginAcknowledgeList= new List<CommunicationEventWrapper.LoginAcknowledgeWrapper>();
            List<String> toAddresses = new List<String>();
            Map<String, Communication_Event_Product_Mapping__mdt> productMetaMapping = Communication_Event_Product_Mapping__mdt.getAll();
                Map<String, Communication_Event_Product_Mapping__mdt> productMapping= new Map<String, Communication_Event_Product_Mapping__mdt>();
                for (Communication_Event_Product_Mapping__mdt metadata : productMetaMapping.values()){
                    productMapping.put(metadata.Product_Name__c, metadata);
                }
            if(productList.size()>0){
                    if(productList[0].Product__r.Product__r.name == 'Affordable Home Loan'){
                        loanProduct= 'AH';
            }
                    else if (productList[0].Product__r.Product__r.name == 'Affordable Non-Home Loan'){
                    loanProduct = 'AL';
                    }
                    else{
                    loanProduct= productMapping.get(productList[0].Product__r.name).Product_Name_in_Wrapper__c;
                }
            }
            // Gather all email addresses
            for (Application_Applicant__c app : appList) {
                List<String> sfId= app.Customer__r.SF_Customer_ID__c.split('-');
                String cifNumber = sfId[1].trim();
                if (!String.isEmpty(app.Email__c)) {
                    toAddresses.add(app.Email__c);
                }
                
                if(app.Applicant_Type__c == 'Primary Applicant'){
                    // loanProduct = app.Loan_Application__r.Product__c;
                    CommunicationEventWrapper.LoginAcknowledgeWrapper loginWrapper = new CommunicationEventWrapper.LoginAcknowledgeWrapper();
                    loginWrapper.Salutation = app.Customer_Type__c == 'Individual' ? (String.isNotBlank(app.Salutation__c) ? app.Salutation__c: '') : 'M/s';
                    loginWrapper.FirstName = String.isNotBlank(app.First_Name__c)? app.First_Name__c :'';
                    loginWrapper.LastName = String.isNotBlank(app.Last_Name__c) ? app.Last_Name__c: '';
                    loginWrapper.CompanyName = app.Customer_Type__c == 'Individual' ? (String.isNotBlank(app.Company__c) ?  app.Company__c: '') :  (String.isNotBlank(app.Name_of_Organization__c) ?  app.Name_of_Organization__c: '');
                        loginWrapper.ProductName = String.isNotBlank(loanProduct) ? loanProduct: '';
                    loginWrapper.LANNumber = String.isNotBlank(app.Loan_Application__r.name) ? app.Loan_Application__r.name : '';
                    loginWrapper.CustomerCategory = app.Customer_Type__c == 'Individual' ? 'RETAIL': (app.Customer_Type__c == 'Non Individual' ? 'CORP' :'' );
                        loginWrapper.emailId = String.isNotBlank(app.Email__c) ? app.Email__c: '';
                    loginWrapper.NoofDays = constants.get('Days_to_process_loan');
                    loginWrapper.mobile_number = app.Mobile_Number__c != null ? String.valueOf(app.Mobile_Number__c): '';
                    loginWrapper.applicantType = String.isNotBlank(app.Applicant_Type__c) ? app.Applicant_Type__c: '';
                    loginWrapper.whatsaap_number = app.Mobile_Number__c != null ? String.valueOf(app.Mobile_Number__c): '';
                    loginWrapper.ProductDescription = productList.size()>0 ? (productList[0].Description != null? productList[0].Description : '') : '';
                    loginWrapper.cif = String.isNotBlank(app.Customer_LMS_Id__c) ? app.Customer_LMS_Id__c: cifNumber;
                    loginAcknowledgeList.add(loginWrapper);
                } 
            }
            if(communicationList.size()<=0){
                messageWrapper = JSON.serialize(loginAcknowledgeList);
                messageWrapper = messageWrapper.replace('NoofDays', 'No.ofDays');
                if(messageWrapper != null && messageWrapper!= '' && loanProduct!= null && loanProduct!= ''){
                    Integration_Details__c integration = new Integration_Details__c();
                    integration.name = 'Communication Event';
                    integration.Loan_Application__c = loanId;
                    integration.Endpoint__c = 'Acknowledge of login'; 
                    integration.Communication_Status__c = 'Published';
                    integration.Request_JSON__c = messageWrapper;
                    insert integration;
                    
                    System.debug('Message wrapper----'+messageWrapper);
                    String commProduct;
                    if(loanProduct != null && (productList[0].Product__r.Product__r.name == 'Affordable Home Loan' || productList[0].Product__r.Product__r.name == 'Affordable Non-Home Loan')){
                            commProduct= productList[0].name;
                        }else {
                            commProduct= productMapping.get(productList[0].Product__r.name).Product_Field__c;
                    }
                    
                    Communication__e event = new Communication__e(
                        Message__c = messageWrapper,
                        Record_Id__c = integration.Id,
                        Type__c = 'Acknowledge of login',
                        product__c = commProduct
                    );
                    
                    Database.SaveResult result = EventBus.publish(event);
                    if (result.isSuccess()) {
                        System.debug('Platform Event published successfully.'+result);
                    } else {
                        // Log errors if publishing failed
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error publishing event: ' + error.getMessage());
                        }
                    }
                }
            }
        }
    } */
  
    public static void scripttech(Set<Id> technicalIds){
        List<Technical_Evaluation__c> techList = new List<Technical_Evaluation__c>();
        if(technicalIds.size() > 0){
            techList = [select Id, HL_Assigned_to_Technical_Admin__c 
                        from Technical_Evaluation__c 
                        where HL_Loan_Application__r.Product__c = 'Home Loan' 
                        and HL_Stage__c != 'Accepted by Technical Manager' 
                        and HL_Assigned_to_Technical_Admin__c!= null
                        AND Id IN :technicalIds];
            

        }else{
            techList = [select Id, HL_Assigned_to_Technical_Admin__c 
                        from Technical_Evaluation__c 
                        where HL_Loan_Application__r.Product__c = 'Home Loan' 
                        and HL_Stage__c != 'Accepted by Technical Manager' 
                        and HL_Assigned_to_Technical_Admin__c!= null];

        }
        List<Document_Details__c> documentList = [select Id, Technical__c from Document_Details__c where Technical__c in :techList and name = 'Technical Report'];
        List<Document_Details__Share> shareList = [select Id, ParentId from Document_Details__Share where ParentId in :documentList];

        Map<String, String> documentToShareRec = new Map<String, String>();
        for(Document_Details__Share share: shareList){
            documentToShareRec.put(share.ParentId, share.Id);
        }

        Map<String, String> documentToTechnical = new Map<String, String>();
        for(Document_Details__c document: documentList){
            documentToTechnical.put(document.Technical__c, document.Id);
        }

        List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
        for(Technical_Evaluation__c tech:techList){
            if(!documentToShareRec.containskey(documentToTechnical.get(tech.Id))){
                Utility.SharingInfo si1 = new Utility.SharingInfo();
                si1.objectName = 'Document_Details__c';
                si1.userOrGroupId = tech.HL_Assigned_to_Technical_Admin__c;
                si1.recordToShareId = documentToTechnical.get(tech.Id);
                si1.sharingAccess = 'Edit';
                sharingList.add(si1);
            }
        }
        System.debug(sharingList);
        if(sharingList.size()>0){
                Utility.createShareRecord(JSON.serialize(sharingList));
            }
    }
}