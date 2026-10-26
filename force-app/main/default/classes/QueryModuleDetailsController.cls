/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-31-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class QueryModuleDetailsController {
   
    // @AuraEnabled
    // public static QueryWrapper getQueryDetails(String recordId){
    //     try {
    //         QueryWrapper queryWrapper = new QueryWrapper();
    //         Query__c q = [Select id,Type_of_Record__c,Query_Category__c,CC_Queue__c,Query_Type__c,Requestor__c,Requestor__r.Name,Loan_Application__c,Loan_Application__r.Name,Requested_from_Users__c,Status__c,CreatedDate from Query__c where id = :recordId];
    //         If(q.Type_of_Record__c == 'Parent'){
    //             if(q.Query_Type__c == 'Document'){
    //         List<Query__c> childQueryList = [Select id,Type_of_Record__c,Query_Category__c,CC_Queue__c,Query_Type__c,Requestor__c,Requestor__r.Name,Loan_Application__c,Loan_Application__r.Name,Requested_from_Users__c,Status__c,CreatedDate from Query__c where Parent_Query__c =:recordId];
    //             }
    //             else{
    //         List<String> requestedUsers = q.Requested_from_Users__c.split(',');
    //         List<String> queueName = (q.CC_Queue__c != null && q.CC_Queue__c != '') ? q.CC_Queue__c.split(',') : new List<String>();
    //         Integer size = requestedUsers.size();
    //         String status = q.status__c;
    //         Boolean currentLoggedInUserIsRequestor = q.Requestor__c != UserInfo.getUserId()?false:true ; 
    //         Boolean currentLoggedInUserIsRequestedFromuser = false;
    //         if(size == 1){
    //             currentLoggedInUserIsRequestedFromuser = requestedUsers[0] == UserInfo.getUserId()?true:false;
    //         }
    //         else{
    //             currentLoggedInUserIsRequestedFromuser = false;
    //         }
    //         Map<String, Query_Record_Editibality__mdt> allMetaData = Query_Record_Editibality__mdt.getAll();
            
    //         List<User> userList =[Select id, Name from User where id In : requestedUsers];
    //         for(User iteru : userList){
    //             if( queryWrapper.requestByUsersName==null){
    //                 queryWrapper.requestByUsersName=iteru.Name;
    //             }else{
    //                  queryWrapper.requestByUsersName =queryWrapper.requestByUsersName+','+iteru.Name;
    //             }
    //         }
    //         List<Group> quelist = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Id IN :queueName];

    //         for(Group iterq : quelist){
    //              if( queryWrapper.selectedQueueName==null){
    //                 queryWrapper.selectedQueueName=iterq.Name;
    //             }else{
    //                 queryWrapper.selectedQueueName =queryWrapper.selectedQueueName+','+iterq.Name;
    //             }
    //         }
    //         queryWrapper.queryId = q.id;
    //         queryWrapper.queryName = q.Query_Type__c;
    //         queryWrapper.relatedRecordName = q.Loan_Application__r.Name;
    //         queryWrapper.queryCategory = q.Query_Category__c;
    //         queryWrapper.queryType = q.Query_Type__c;
    //         queryWrapper.requestorName=q.Requestor__r.Name;
    //         queryWrapper.status =q.Status__c;
    //         queryWrapper.docWrapp = new List<DocumentWrapper>();
    //         List<Document_Details__c> docList = [Select id, Name, Requirement_Level__c, Status__c, Description__c, Content_Document_Id__c,
    //         Loan_Application__c from Document_Details__c where Id = :recordId];
            
    //         for(Document_Details__c doc : docList){
    //             DocumentWrapper dw = new DocumentWrapper();
    //             dw.documentId = doc.id;
    //             dw.documentName = doc.Name;
    //             dw.requirementLevel = doc.Requirement_Level__c;
    //             dw.status = doc.Status__c;
    //             dw.showPreview = doc.Content_Document_Id__c !=null?true:false;
    //             dw.description = doc.Description__c;
    //             dw.contentDocumentId = doc.Content_Document_Id__c;
    //             for(Query_Record_Editibality__mdt module : allMetaData.values()) {
    //                 if(module.Current_logged_in_user_Requestor__c == currentLoggedInUserIsRequestor && module.Logged_in_user_single_requested_from__c == currentLoggedInUserIsRequestedFromuser && module.Status__c == status){
    //                     dw.showUpload = module.Upload_editable__c;
    //                     queryWrapper.isRecordEditable = module.Record_Editable__c;
    //                 }
    //             }
    //             queryWrapper.docWrapp.add(dw);
    //          }
    //          return queryWrapper;
    //         } 

    //     }
    // }catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }
    @AuraEnabled
    public static QueryWrapper getQueryDetails(String recordId) {
        QueryWrapper queryWrapper = new QueryWrapper();
        queryWrapper.docWrapp = new List<DocumentWrapper>(); 
        String currentUserId = UserInfo.getUserId();
        Integer newsequence = 1;
        try {
            //Added by kalpesh
            Set<Id> samplerOppIds = new Set<Id>();
            for(OpportunityTeamMember otm : [SELECT OpportunityId FROM OpportunityTeamMember
                                             WHERE UserId = :currentUserId AND TeamMemberRole = 'Sampler'])
                                            {
                                                samplerOppIds.add(otm.OpportunityId);
                                            }
            // Fetch the main Query record
            Query__c q = [SELECT Id, Type_of_Record__c, Query_Category__c, CC_Queue__c, Query_Type__c, Requestor__c, 
                                  Requestor__r.Name, Loan_Application__c, Loan_Application__r.Name, Requested_from_Users__c, 
                                  Status__c, CreatedDate, Remarks__c
                           FROM Query__c 
                           WHERE Id = :recordId LIMIT 1];
    
            queryWrapper.queryId = q.Id;
            queryWrapper.isActionAllowed = true;
            queryWrapper.queryName = q.Query_Type__c;
            queryWrapper.relatedRecordName = q.Loan_Application__r != null ? q.Loan_Application__r.Name : null;
            queryWrapper.queryCategory = q.Query_Category__c;
            queryWrapper.queryType = q.Query_Type__c;
            queryWrapper.requestorName = q.Requestor__r != null ? q.Requestor__r.Name : null;
            queryWrapper.requestorId = q.Requestor__c != null ? q.Requestor__c : null;//Added by kalpesh
            queryWrapper.status = q.Status__c;
            queryWrapper.remark=q.Remarks__c;
            Boolean isParent = q.Type_of_Record__c == 'Parent';
            Boolean isDocumentType = q.Query_Type__c == 'Document';
    
            // Fetch Metadata for Editability Check
            Map<String, Query_Record_Editibality__mdt> allMetaData = Query_Record_Editibality__mdt.getAll();
            Map<String, List<String>> childQueryWithUsers = new Map<String, List<String>>();
            // Fetch related users and queue names
            List<String> requestedUsers = q.Requested_from_Users__c != null ? q.Requested_from_Users__c.split(',') : new List<String>();
            List<String> queueIds = q.CC_Queue__c != null ? q.CC_Queue__c.split(',') : new List<String>();
    
            // Fetch Users
            if (!requestedUsers.isEmpty()) {
                if (!requestedUsers.contains(UserInfo.getUserId())) {
                   // queryWrapper.isActionAllowed = false;
                } 
                List<User> userList = [SELECT Id, Name FROM User WHERE Id IN :requestedUsers];
                List<String> userNames = new List<String>();
                for (User iteru : userList) {
                    userNames.add(iteru.Name);
                }
                queryWrapper.requestByUsersName = String.join(userNames, ',');
            } else {
                queryWrapper.isActionAllowed = false;
            }
    
            // Fetch Queues
            if (!queueIds.isEmpty()) {
                List<Group> queueList = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Id IN :queueIds];
                List<String> queueNames = new List<String>();
                for (Group iterq : queueList) {
                    queueNames.add(iterq.Name);
                }
                queryWrapper.selectedQueueName = String.join(queueNames, ',');
            }
    System.debug('isParent '+isParent+' isDocumentType'+isDocumentType);
            List<Query__c> childQueryList = new List<Query__c>();
            if (isParent) {
                childQueryList = [SELECT Id, Type_of_Record__c,Responder__c, Document_Details__c, Query_Category__c, 
                                                             CC_Queue__c, Query_Type__c, Requestor__c, Requestor__r.Name, 
                                                             Loan_Application__c, Loan_Application__r.Name, Requested_from_Users__c, 
                                                             Status__c, CreatedDate 
                                                      FROM Query__c 
                                                      WHERE Parent_Query__c = :recordId];
            } else {
                childQueryList = [SELECT Id, Type_of_Record__c,Responder__c, Document_Details__c, Query_Category__c, 
                                                             CC_Queue__c, Query_Type__c, Requestor__c, Requestor__r.Name, 
                                                             Loan_Application__c, Loan_Application__r.Name, Requested_from_Users__c, 
                                                             Status__c, CreatedDate 
                                                      FROM Query__c 
                                                      WHERE Id = :recordId];
            }
          //  if(!childQueryList.isEmpty() || isHlRelated) {
                if (isDocumentType) {
                    // Extract Document IDs from Child Queries
                    if(!childQueryList.isEmpty()){
                    Set<Id> documentIds = new Set<Id>();
                    for (Query__c childQuery : childQueryList) {
                        // if ((childQuery.Requested_from_Users__c != null && childQuery.Requested_from_Users__c.contains(currentUserId)) || childQuery.Requestor__c == currentUserId) {
                        if (childQuery.Document_Details__c != null) {
                            documentIds.add(childQuery.Document_Details__c);
                        }
                        childQueryWithUsers.put(childQuery.Id, childQuery.Requested_from_Users__c.split(','));
                    // }
                    }
                    // Step 3: Use another map to get the names of users
                        Map<String, List<String>> childQueryWithUserNames = new Map<String, List<String>>();
                        for (String childQueryId : childQueryWithUsers.keySet()) {
                            List<String> requestedchildUsers = childQueryWithUsers.get(childQueryId);
                            if (!requestedchildUsers.isEmpty()) {
                                List<User> userList = [SELECT Id, Name FROM User WHERE Id IN :requestedUsers];
                                List<String> userNames = new List<String>();
                                for (User iteru : userList) {
                                    userNames.add(iteru.Name);
                                }
                                childQueryWithUserNames.put(childQueryId, userNames);
                            }
                        }
                
    
                    // Fetch Documents in Bulk
                    if (!documentIds.isEmpty()) {
                        Map<Id, Document_Details__c> docMap = new Map<Id, Document_Details__c>(
                            [SELECT Id, Name, Requirement_Level__c, Status__c, Description__c, Content_Document_Id__c 
                             FROM Document_Details__c WHERE Id IN :documentIds]);
    
                        for (Query__c childQuery : childQueryList) {
                            if (docMap.containsKey(childQuery.Document_Details__c)) {
                                Document_Details__c doc = docMap.get(childQuery.Document_Details__c);
                                DocumentWrapper dw = new DocumentWrapper();
                                dw.queryId = childQuery.Id;
                                dw.documentId = doc.Id;
                                dw.documentName = doc.Name;
                                dw.requirementLevel = doc.Requirement_Level__c;
                                dw.status = doc.Status__c;
                                dw.showPreview = doc.Content_Document_Id__c != null;
                                dw.description = doc.Description__c;
                                dw.contentDocumentId = doc.Content_Document_Id__c;
                                dw.contentDocLink = '/sfc/servlet.shepherd/document/filePreview/'+doc.Content_Document_Id__c;
                                dw.Stage = childQuery.Status__c;
                                RecordEditibalityWrapper editabilityWrapper = checkRecordEditability(childQuery.Id);
                                dw.recordEditable = editabilityWrapper.recordEditable;
                                dw.uploadEditable = editabilityWrapper.uploadEditable;
                                List<String> userchildNames = childQueryWithUserNames.get(childQuery.Id);
                                String userNamesString = String.join(userchildNames, ',');
                                // Assign the concatenated string to dw.childQueryWithUserNames
                                dw.childQueryWithUserNames = userNamesString;
                                // Initialize buttonWrapp for each DocumentWrapper
                                dw.buttonWrapp = new List<ButtonWrapper>();
                                for (Query_Record_Editibality__mdt module : allMetaData.values()) {
                                    if (module.Current_logged_in_user_Requestor__c == (q.Requestor__c == UserInfo.getUserId()) &&
                                        module.Logged_in_user_single_requested_from__c == (requestedUsers.contains(UserInfo.getUserId())) &&
                                        module.Status__c == q.Status__c) {
                                        dw.showUpload = module.Upload_editable__c;
                                        dw.showUploadNew = childQuery.Responder__c == UserInfo.getUserId();
                                        queryWrapper.isRecordEditable = module.Record_Editable__c;
                                    }
                                }
    
                                // Fetch buttons and add them to the document wrapper
                                if ((childQuery.Requested_from_Users__c != null && childQuery.Requested_from_Users__c.contains(currentUserId)) || (childQuery.Requestor__c == currentUserId && samplerOppIds.contains(childQuery.Loan_Application__c))) {
                                RecordWrapper recordWrapper = setRecordButtons(childQuery.Id);
                                if (recordWrapper != null && recordWrapper.buttons != null) {
                                    dw.buttonWrapp.addAll(recordWrapper.buttons);
                                }
                            }
    
                                queryWrapper.docWrapp.add(dw);
                            }
                        }
                    }
                }
                } else {
                    System.debug('223');
                    // Fetch related documents for non-document queries
                    List<Document_Details__c> docList = [SELECT Id, Name, Requirement_Level__c, Status__c, Description__c, Applicant__c,Applicant__r.Applicant_Name__c,
                                                                 Content_Document_Id__c 
                                                          FROM Document_Details__c 
                                                          WHERE Query__c = :q.Id];
    
                    for (Document_Details__c doc : docList) {
                        DocumentWrapper dw = new DocumentWrapper();
                        dw.documentId = doc.Id;
                        dw.documentName = doc.Name;
                        dw.requirementLevel = doc.Requirement_Level__c;
                        dw.status = doc.Status__c;
                        dw.showPreview = doc.Content_Document_Id__c != null;
                        dw.description = doc.Description__c;
                        dw.contentDocumentId = doc.Content_Document_Id__c;
                        dw.applicant = doc.Applicant__c;
                        dw.applicantName= doc.Applicant__r.Applicant_Name__c;
                        dw.editnotdisabled = false;
                        dw.sequence = newsequence;
                        RecordEditibalityWrapper editabilityWrapper = checkRecordEditability(q.Id);
                        dw.recordEditable = editabilityWrapper.recordEditable;
                        // dw.uploadEditable = editabilityWrapper.uploadEditable;
                        // Initialize buttonWrapp for each DocumentWrapper
                        dw.buttonWrapp = new List<ButtonWrapper>();
    
                        for (Query_Record_Editibality__mdt module : allMetaData.values()) {
                            if (module.Current_logged_in_user_Requestor__c == (q.Requestor__c == UserInfo.getUserId()) &&
                                module.Logged_in_user_single_requested_from__c == (requestedUsers.contains(UserInfo.getUserId())) &&
                                module.Status__c == q.Status__c) {
                                dw.showUpload = module.Upload_editable__c;
                                // queryWrapper.isRecordEditable = module.Record_Editable__c;
                            }
                        }
    
                        queryWrapper.docWrapp.add(dw);
                        newsequence++;
                    }
                }
           // }
            return queryWrapper;
    
        } catch (Exception e) {
            System.debug('Error: ' + e);
            System.debug('Error message: ' + e.getMessage() + ' \n StackTrace: ' + e.getStackTraceString());
            return new QueryWrapper();  // Return a default instance to handle errors gracefully
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
                System.debug('singleRequestedByUser '+singleRequestedByUser);
                if(previousRequestedFromUsersList.contains(UserInfo.getUserId())){
                    previousResponder = true;
                }
                else{
                    previousResponder = false;
                }
                
                isRequestor = q.Requestor__c == UserInfo.getUserId() ? true : false;
            }
            else if(objectName  == 'Opportunity'){
                isRequestor = true;
            }
           
            record = Database.query('SELECT Id,Status__c FROM '+objectName+' WHERE Id = \''+recordId+'\' LIMIT 1');
            
         
            if(objectName  != 'Query__c'){
            recordStatus = 'Open';
            }
            else{
             recordStatus = (String)record.get('Status__c') != null ? (String)record.get('Status__c') : 'Open';
            }
            profileName = [SELECT Id,Name FROM Profile WHERE Id=:UserInfo.getProfileId() LIMIT 1].Name;
            String currentRole;
            List<OpportunityTeamMember> oppTeamList = [Select  Id, OpportunityId, UserId, Name, TeamMemberRole from OpportunityTeamMember where OpportunityId=:recordId and UserId = :UserInfo.getUserId()];
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
                System.debug('previousResponder>>>'+previousResponder);
                System.debug('singleRequestedByUser>>>'+singleRequestedByUser);
                System.debug('profileName>>>'+profileName);
                System.debug('recordStatus>>>'+recordStatus);
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
    
    public class QueryWrapper{
        @AuraEnabled public string queryId;
        @AuraEnabled public string queryName;
        @AuraEnabled public String relatedRecordName;
        @AuraEnabled public String queryType;
        @AuraEnabled public String queryCategory;
        @AuraEnabled public String requestorName;
        @AuraEnabled public String requestorId;//Added By kalpesh
        @AuraEnabled public String status;
        @AuraEnabled public DateTime requestedDate;
        @AuraEnabled public String requestByUsersName;
        @AuraEnabled public boolean isRecordEditable;
        @AuraEnabled public String selectedQueueName;
        @AuraEnabled public String remark;
        @AuraEnabled public boolean isActionAllowed;
        @AuraEnabled public List<DocumentWrapper> docWrapp;
    }
    public class ButtonWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public String value;
        public ButtonWrapper(String name,String value){
            this.name = name;
            this.value = value;
        }
    }
    public class DocumentWrapper{
        @AuraEnabled public string queryId;
        @AuraEnabled public string documentId;
        @AuraEnabled public string Stage;
        @AuraEnabled  public string documentName;
        @AuraEnabled  public string contentDocumentId;
        @AuraEnabled  public boolean showUpload;
        @AuraEnabled  public boolean showUploadNew;
        @AuraEnabled public boolean showPreview;
        @AuraEnabled public string requirementLevel;
        @AuraEnabled public string status;
        @AuraEnabled public string description ; 
        @AuraEnabled public Boolean recordEditable; 
        @AuraEnabled public Boolean uploadEditable; 
        @AuraEnabled public string childQueryWithUserNames;
        @AuraEnabled public string applicantName;
        @AuraEnabled public string applicant;
        @AuraEnabled public Boolean editnotdisabled = false;
        @AuraEnabled public Integer sequence = 0;
        @AuraEnabled public List<ButtonWrapper> buttonWrapp;
        @AuraEnabled public string contentDocLink;
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

    @AuraEnabled
    public static void uploadFile(String base64Data, String fileName, String fileType, String recordId, String selecteddocCheckId,string requestorId) {
       
        String contentId = 'Error in uploading documents';
        System.debug('base64Data '+base64Data);
        System.debug('fileName '+fileName);
        System.debug('fileType '+fileType);
        System.debug('requestorId '+requestorId);
        try{
            if(base64Data !=null && fileName != null && fileType != null){
                Blob fileBlob = EncodingUtil.base64Decode(base64Data);
    
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = fileName;
                contentVersion.PathOnClient = fileName;
                contentVersion.VersionData = fileBlob;
                contentVersion.ContentLocation = 'S'; // S for Salesforce, 'E' for external
                insert contentVersion;
        
                contentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;

                    List<Document_Details__c> docList = [SELECT Id FROM Document_Details__c WHERE id =: selecteddocCheckId];
                    Document_Details__c documentObj = new Document_Details__c();
                    if(docList.size()>0){
                        documentObj.Id = docList[0].Id;
                    }
                    documentObj.Status__c = 'Uploaded';
                    documentObj.Content_Document_Id__c = contentId;
                	documentObj.Consider_for_Loan_Application__c = true;
                    update documentObj;
                    //kalpesh start
                    if(requestorId!='' && requestorId!=null){
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.ContentDocumentId = contentId;
                        cdl.LinkedEntityId = requestorId; // Share with user
                        cdl.ShareType = 'V'; // Viewer access (options: V=View, C=Collaborate)
                        cdl.Visibility = 'AllUsers';
                        insert cdl;
                    }
                    //kalpesh start
                List<ContentDocumentLink> cdl = [SELECT id FROM ContentDocumentLink WHERE LinkedEntityId =:documentObj.id AND ShareType = 'V'];
                if(cdl.size() > 0) {
                    
                }else {
                    ContentDocumentLink cd = new ContentDocumentLink();
                    cd.LinkedEntityId =documentObj.id;
                    cd.ContentDocumentId = contentId;
                    cd.ShareType = 'V';
                    cd.Visibility = 'AllUsers';
                    insert cd;
                }
                    
                    
            }
        }catch(Exception exp){
           // Utility.generateException(exp, Constants.CONTENT_VERSION_OBJECT_NAME, Constants.FCU_CLASS_1);
        }
       
    }


    @AuraEnabled
    public static String uploadFileNonDocument(String base64Data, String fileName, String fileType,String  requestorId) {
        String contentId = 'Error in uploading documents';
        String docId = '';
    
        try {
            // Document_Details__c doc = new Document_Details__c();
    
            if (base64Data != null && fileName != null && fileType != null) {
                Blob fileBlob = EncodingUtil.base64Decode(base64Data);
    
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = fileName;
                contentVersion.PathOnClient = fileName;
                contentVersion.VersionData = fileBlob;
                contentVersion.ContentLocation = 'S'; // 'S' for Salesforce, 'E' for external
                insert contentVersion;
    
                contentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
                    //kalpesh start
                    if(requestorId!='' && requestorId!=null){
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.ContentDocumentId = contentId;
                        cdl.LinkedEntityId = requestorId; // Share with user
                        cdl.ShareType = 'V'; // Viewer access (options: V=View, C=Collaborate)
                        cdl.Visibility = 'AllUsers';
                        insert cdl;
                    }
                    //kalpesh start
                return contentId;
                // Fetching the document master
                // List<Document_Master__c> docMaster = [SELECT Id, Name FROM Document_Master__c WHERE Requirement_At__c = 'Loan Application' AND Name = 'Other' LIMIT 1];
    
              
                //     doc.Status__c = 'Uploaded';
                //     doc.Content_Document_Id__c = contentId;
                //     doc.Document_Master__c = docMaster.isEmpty() ? null : docMaster[0].Id;
                //     doc.Loan_Application__c = loanId;
                //     doc.Name = fileName;
                //     insert doc;
                //     docId = doc.Id;
                
            }
        } catch (Exception exp) {
            System.debug('Exception in uploadFileNonDocument: ' + exp.getMessage());
        }
    
        return contentId; // Ensure a value is returned
    }
    
    @AuraEnabled
    public static String uploadFileNonDocumentNew(String conDocId,String  requestorId) {
        String contentId = 'Error in uploading documents';
        String docId = '';
    
        try {
            // Document_Details__c doc = new Document_Details__c();
    
            if (conDocId != null && requestorId != null) {
                
                    //kalpesh start
                    if(requestorId!='' && requestorId!=null){
                        contentId = conDocId;
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.ContentDocumentId = conDocId;
                        cdl.LinkedEntityId = requestorId; // Share with user
                        cdl.ShareType = 'V'; // Viewer access (options: V=View, C=Collaborate)
                        cdl.Visibility = 'AllUsers';
                        insert cdl;
                    }
                    //kalpesh start
                return contentId;
                // Fetching the document master
                // List<Document_Master__c> docMaster = [SELECT Id, Name FROM Document_Master__c WHERE Requirement_At__c = 'Loan Application' AND Name = 'Other' LIMIT 1];
    
              
                //     doc.Status__c = 'Uploaded';
                //     doc.Content_Document_Id__c = contentId;
                //     doc.Document_Master__c = docMaster.isEmpty() ? null : docMaster[0].Id;
                //     doc.Loan_Application__c = loanId;
                //     doc.Name = fileName;
                //     insert doc;
                //     docId = doc.Id;
                
            }
        } catch (Exception exp) {
            contentId = 'Error in uploading documents';
            System.debug('Exception in uploadFileNonDocument: ' + exp.getMessage());
        }
    
        return contentId; // Ensure a value is returned
    }
    

    @AuraEnabled(cacheable=true)
    public static List<NoteWrapper> getNotes(String recordId) {
        List<NoteWrapper> notesList = new List<NoteWrapper>();
    
        List<Note> notes = [SELECT Id, Title, Body FROM Note WHERE ParentId = :recordId ORDER BY CreatedDate ASC];
        Query__c q  = [SELECT Id, Name FROM Query__c WHERE Id = :recordId];

        // List<Note> notes = [SELECT Id, Title, Body FROM Note WHERE ParentId = :recordId ORDER BY CreatedDate ASC];  
        for (Note n : notes) {
            NoteWrapper nw = new NoteWrapper();
            nw.queryNumber = q.Name;
            
            if (n.Title.contains(';')) {
                List<String> titleParts = n.Title.split(';', 2);
                nw.status = titleParts[0];
    
                if (titleParts[1].contains('-')) {
                    Integer dashIndex = titleParts[1].indexOf('-');
                    String dateTimePart = titleParts[1].substring(dashIndex + 1).trim();
                    
                    // Extracting RemarksAddedBy
                    if (dateTimePart.contains('by')) {
                        Integer byIndex = dateTimePart.indexOf('by');
                        nw.remarkDateTime = dateTimePart.substring(0, byIndex).trim();
                        nw.remarksAddedBy = dateTimePart.substring(byIndex + 3).trim();
                    } else {
                        nw.remarkDateTime = dateTimePart;
                    }
                }
            }
            
            nw.remarks = n.Body;
            notesList.add(nw);
        }
            
        // 1. Get all ContentDocumentIds linked to this Query record
        Set<Id> contentDocIds = new Set<Id>();
        for (ContentDocumentLink cdl : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId]) {
            contentDocIds.add(cdl.ContentDocumentId);
        }
        System.debug('contentDocIds: '+contentDocIds);
        if (contentDocIds.isEmpty()) {
            System.debug('notesList contentDocIds.isEmpty: '+notesList);
            return notesList;
        }
        // 2. Get all ContentVersions that are Enhanced Notes (SNOTE)
        // and are linked to this Query, in ascending order.
        List<ContentVersion> notess = [SELECT Id, Title, VersionData, ContentDocumentId, CreatedDate FROM ContentVersion 
                                        WHERE ContentDocumentId IN :contentDocIds AND FileType = 'SNOTE' ORDER BY CreatedDate ASC];
        // 3. Process the ContentVersions into the NoteWrapper
        for (ContentVersion n : notess) {
            NoteWrapper nw = new NoteWrapper();
            nw.queryNumber = q.Name;    
        // Use the same title-parsing logic as before
            if (n.Title != null && n.Title.contains(';')) {
                List<String> titleParts = n.Title.split(';', 2);
                nw.status = titleParts[0];
                if (titleParts[1].contains('-')) {
                    Integer dashIndex = titleParts[1].indexOf('-');
                    String dateTimePart = titleParts[1].substring(dashIndex + 1).trim();
                    // Extracting RemarksAddedBy
                    if (dateTimePart.contains('by')) {
                        Integer byIndex = dateTimePart.indexOf('by');
                        nw.remarkDateTime = dateTimePart.substring(0, byIndex).trim();
                        nw.remarksAddedBy = dateTimePart.substring(byIndex + 3).trim();
                    } else {
                        nw.remarkDateTime = dateTimePart;
                    }
                }
            }
            // The remark body is now Blob data, which needs to be converted to a String
            if (n.VersionData != null) {
                nw.remarks = n.VersionData.toString(); // This replaces the old "n.Body"
            } 
            notesList.add(nw);
        }
        
        System.debug('notesList Final:-- ' + notesList);
        return notesList;
    }
    
    public class NoteWrapper {
        @AuraEnabled public String queryNumber;
        @AuraEnabled public String status;
        @AuraEnabled public String remarks;
        @AuraEnabled public String remarkDateTime;
        @AuraEnabled public String remarksAddedBy;
    }
 
    @AuraEnabled
    public static RecordEditibalityWrapper checkRecordEditability(Id recordId) {
        Boolean singleRequestedByUser = false;
        Boolean previousResponder = false;
        Boolean isRequestor = false;
        
        List<String> requestedFromUsersList = new List<String>();
        List<String> previousRequestedFromUsersList = new List<String>();

        Query__c q = [SELECT Id, Requested_from_Users__c, Requestor__c, Previous_Responders__c, Status__c 
                      FROM Query__c 
                      WHERE Id = :recordId];

        if (q.Requested_from_Users__c != null) {
            requestedFromUsersList = q.Requested_from_Users__c.split(',');
        }
        if (q.Previous_Responders__c != null) {
            previousRequestedFromUsersList = q.Previous_Responders__c.split(',');
        }

        String currentUserId = UserInfo.getUserId();

        if (requestedFromUsersList.contains(currentUserId)) {
            singleRequestedByUser = requestedFromUsersList.size() == 1;
        }

        if (previousRequestedFromUsersList.contains(currentUserId)) {
            previousResponder = true;
        }

        isRequestor = q.Requestor__c == currentUserId;

        Boolean recordEditable = false;
        Boolean uploadEditable = false;
        RecordEditibalityWrapper re = new RecordEditibalityWrapper();
        if (isRequestor) {
            // Case: Logged-in user is the Requestor
            if (q.Status__c == 'Response Sent') {
                re.recordEditable = true;
                re.uploadEditable = false;
            }
            else{
                re.recordEditable = false;
                re.uploadEditable = false;
            }
        } else  { //if (requestedFromUsersList.contains(currentUserId))
            // Case: Logged-in user is the only requested from user
            if (q.Status__c == 'Assigned' || q.Status__c == 'Accepted'|| q.Status__c == 'Re-assigned'|| q.Status__c == 'Sent Back' || q.Status__c == 'Response Sent') {
                re.recordEditable = true;
                re.uploadEditable = true;
            }
            else{
                re.recordEditable = false;
                re.uploadEditable = false;
            }
        }

        // Default case: Non-editable
        System.debug('Record Editable: ' + recordEditable);
        System.debug('Upload Editable: ' + uploadEditable);
        return re;
    }

    public class RecordEditibalityWrapper{
        @AuraEnabled public Boolean recordEditable, uploadEditable;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getRequirementLevels() {
        List<Document_Master__c> docMasters = [SELECT Requirement_At__c FROM Document_Master__c];
        Set<String> requirementLevels = new Set<String>();
        for (Document_Master__c doc : docMasters) {
            requirementLevels.add(doc.Requirement_At__c);
        }
        return new List<String>(requirementLevels);
    }
    @AuraEnabled(cacheable=true)
    public static List<Application_Applicant__c> getCustomers(String loanId) {
        return [SELECT Id, Applicant_Name__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId];
    }

    @AuraEnabled
    public static void updateDocumentChecklist(String contentDocIds,String loanId, string recordId, String name, String requirementLevel, String customerId) {
        Document_Details__c doc = new Document_Details__c();
        doc.Name = name;
        doc.Requirement_Level__c = requirementLevel;
        doc.Applicant__c = customerId;
        doc.Content_Document_Id__c = contentDocIds;
        doc.Loan_Application__c   = loanId;
        doc.Query__c   = recordId;
        insert doc;
    }

@AuraEnabled
public static Boolean uploadreupload(String contentId, String parentId) {
    try {
        String objectAPIName;
        String documentId = null; // Initialize it to avoid potential null reference
        // Query ContentDocumentLink for the specified ContentDocumentId
        List<ContentDocumentLink> docLinks = [SELECT Id, ContentDocumentId, LinkedEntityId, Visibility
                                              FROM ContentDocumentLink
                                              WHERE ContentDocumentId =: contentId];
        
        if (!docLinks.isEmpty()) {
            for (ContentDocumentLink docLink : docLinks) {
                Id linkedEntityId = docLink.LinkedEntityId;
                // Dynamically get the object name from the LinkedEntityId
                objectAPIName = linkedEntityId.getSObjectType().getDescribe().getName();
                if (objectAPIName == 'Document_Details__c') {
                    documentId = docLink.LinkedEntityId;
                    break;
                }
            }
        }

        // If no matching Document_Details record is found, return false
        if (documentId == null) {
            return false; // No matching record found
        }

        // Dynamically get the object type and its fields
        SObjectType objType = Schema.getGlobalDescribe().get(objectAPIName);
        Map<String, Schema.SObjectField> fields = objType.getDescribe().fields.getMap();
        // Construct the dynamic query to fetch all fields
        String query = 'SELECT ' + String.join(fields.keySet(), ',') + ' FROM ' + objectAPIName + ' WHERE Id = :documentId';
        SObject record = Database.query(query);

        // Clone the record
        SObject clonedRecord = record.clone(false); // Deep clone removed for testing
        clonedRecord.put('Content_Document_Id__c', contentId);
          clonedRecord.put('Active__c', true);
        
        // Handling Version Number Logic
        Decimal versionNumber = (Decimal) record.get('Version_Number__c');
        if (versionNumber == null) {
            versionNumber = 1;
        } else {
            versionNumber += 1;
        }
        clonedRecord.put('Version_Number__c', versionNumber);

        // Insert the cloned record
        insert clonedRecord;

        // Fetch the related old record (Document_Details__c) based on documentId
 List<Document_Details__c> oldRecord = [SELECT Id, Document_Master__r.Document_Name__c, Active__c, 
                                                Document_Master__r.Document_Category__c, Document_Details_Lookup__c 
                                                FROM Document_Details__c 
                                                WHERE (Id = :documentId OR Document_Details_Lookup__c = :documentId)];
        
        if (!oldRecord.isEmpty()) {
            for(Document_Details__c dd : oldRecord){
            dd.Document_Details_Lookup__c = clonedRecord.Id;
            dd.Active__c = false;
            update oldRecord;
            }
        }

        // Query Query__c records and update with cloned record ID
        List<Query__c> qr = [SELECT Id, Document_Details__c FROM Query__c WHERE Parent_Query__c = :parentId AND Document_Details__c = :documentId];
        if (!qr.isEmpty()) {
            qr[0].Document_Details__c = clonedRecord.Id;
            update qr;  // Don't forget to perform the update on Query__c
        }

        // Create a ContentDocumentLink for the cloned document
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = clonedRecord.Id;
        cdl.ContentDocumentId = contentId;
        cdl.ShareType = 'V'; // Viewer permission
        cdl.Visibility = 'AllUsers'; // Visibility for all users
        insert cdl;

        return true;

    } catch (Exception e) {
        // Handling errors by throwing a meaningful exception
        throw new AuraHandledException('Error in upload/re-upload process: ' + e.getMessage());
    }
}



            
    
}