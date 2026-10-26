public with sharing class RecordActionButtonController {
    static string conLabels = 'GROUP_ID';
    public static Map<string, string> constants1 = Utility.getConstants(conLabels);

    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants1;
    }
    
    @AuraEnabled
    public static void sendNotificationFI(Id recordId,String status, String comment){
        try {
            //HL-Ishi-17/09
            String sObjName = recordId.getSObjectType().getDescribe().getName();
            //HL-Ishi-17/09
            String curentDtTime = System.now().format();
            String currentUserName = UserInfo.getFirstName() +' '+ UserInfo.getLastName();
            String newEntry;
            system.debug('comment:: '+comment);
            //HL-Ishi-17/09
            Application_Verification__c investigation = new Application_Verification__c();
            Legal__c legalRecord = new Legal__c ();
            User assignedUser = new User();
            if(sObjName!='Legal__c'){
                investigation = [SELECT Id,Name,Assigned_To_User__c,Stantard_Remark__c,Vendor_Admin__c,Loan_Application__r.OwnerId,OwnerId,RecordType.Name,Any_Remarks_Reasons__c FROM Application_Verification__c WHERE Id =:recordId LIMIT 1];
                assignedUser = [SELECT Id,Name FROM User WHERE Id=:investigation.Assigned_To_User__c LIMIT 1];
            }
            else{
                legalRecord = [Select id, OwnerId, Stage__c,HL_Assigned_to_Admin__c,HL_Assigned_to_Executive__c,Assigned_to_Admin__c,Assigned_to_Executive__c,Owner.Name, Owner.Email from Legal__c where id =: recordId];//updated-Ayushi
            }
             Set<String> recipientsId = new Set<String>();
           
            //HL-Ishi-17/09
            if(sObjName =='Legal__c' && (status.trim() == 'Submitted by Admin')){
                 recipientsId.add(legalRecord.OwnerId);
                 Utility.sendInAppNotification(recordId, 'Legal Record Submitted for Approval', 'The legal record has been submitted for approval. Please take the necessary action.', recipientsId, 'Duplicate_Lead');
            }
            // if(sObjName=='Legal__c' && status.trim() == 'Submitted by Executive'){
            //      recipientsId.add(legalRecord.Assigned_to_Admin__c);
            //      Utility.sendInAppNotification(recordId, 'Legal Record Submitted for Approval', 'The legal record has been submitted for approval. Please take the necessary action.', recipientsId, 'Duplicate_Lead');
            // }
            System.debug('status----'+status);
            System.debug('status----'+status.trim());
            String trimmedStatus = status.trim();
             if(sObjName =='Legal__c' && (trimmedStatus == 'Assigned to Admin')){
                System.debug('status----'+status.trim());
                 recipientsId.add(legalRecord.Assigned_to_Admin__c);
                 Utility.sendInAppNotification(recordId, 'Legal Record Sent back', 'The legal record has been sent back for approval.Kindly check the comments and take necessary actions.', recipientsId, 'Duplicate_Lead');
            }
            if(sObjName =='Legal__c' && (trimmedStatus == 'Hold')){
                System.debug('status----'+status.trim());
                if(legalRecord.Assigned_to_Executive__c!=null){
                     recipientsId.add(legalRecord.Assigned_to_Executive__c);
                }
                if(legalRecord.OwnerId!=null){
                     recipientsId.add(legalRecord.OwnerId);
                }
                
                 Utility.sendInAppNotification(recordId, 'Legal Record Kept On Hold', 'The legal record has been kept on hold by vendor admin.', recipientsId, 'Duplicate_Lead');
                 //updated-Ayushi
                 // --- 2. Email Notification for Credit Manager (Legal Owner) ---
    System.debug('Legal record put on hold. Sending email notification to Credit Manager (Legal Owner).');

    // Check for the Legal Record's Owner Email
    if (legalRecord.OwnerId != null && String.isNotBlank(legalRecord.Owner.Email)) {

        // Get all the details for the email
        String creditManagerEmail = legalRecord.Owner.Email;
        String creditManagerName = legalRecord.Owner.Name;
        String legalRecordName = legalRecord.Name;
        
        // Create a personalized greeting
        String emailGreeting = 'Dear ' + (String.isNotBlank(creditManagerName) ? creditManagerName : 'Credit Manager') + ',\n\n';

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        mail.setToAddresses(new List<String>{ creditManagerEmail });
        mail.setSenderDisplayName('Salesforce Notifications');
        mail.setSubject('Legal Record On Hold: ' + legalRecordName);
        
        // Build the email body
        String body = emailGreeting +
                      'The legal record "' + legalRecordName + '"' +
                      ' has been put on hold by the Legal Admin.\n\n' +
                      'Comment provided:\n' +
                      comment + '\n\n' +
                      'Thank you.';
        mail.setPlainTextBody(body);
        
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            System.debug('Hold email sent successfully to ' + creditManagerEmail);
        } catch (Exception e) {
            System.debug('Error sending hold email: ' + e.getMessage());
            Error_Logs__c log = Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'RecordActionButtonController.sendNotificationFI', 'Legal__c', recordId);
            Utility.createErrorLogRecord(new List<Error_Logs__c>{log});
        }

    } else {
        System.debug('Could not send Legal Hold email: Legal Record Owner or Email is missing.');
        Error_Logs__c log = Utility.fillErrorRecord('Could not send Legal Hold email: Legal Record Owner or Email is missing.', '', 'RecordActionButtonController.sendNotificationFI', 'Legal__c', recordId);
        Utility.createErrorLogRecord(new List<Error_Logs__c>{log});
    }
    } else if(sObjName =='Legal__c' && (trimmedStatus == 'Un-Hold')){//updated-Ayushi
    System.debug('Legal record Un-Hold. Sending in-app notification to Executive and Credit Manager.');

    // Add Legal Executive
    if(legalRecord.Assigned_to_Executive__c != null){
         recipientsId.add(legalRecord.Assigned_to_Executive__c);
    }
    if(legalRecord.OwnerId != null){
         recipientsId.add(legalRecord.OwnerId);
    }

    // Send the in-app notification to both
    if(!recipientsId.isEmpty()){
        Utility.sendInAppNotification(
            recordId, 
            'Legal Record Off Hold', 
            'The legal record "' + legalRecord.Name + '" has been taken off hold and is active again.', 
            recipientsId, 
            'Duplicate_Lead'
        );
    }
}
// end updated
            System.debug('assignedUser.id----'+assignedUser.id);
            System.debug('status---'+status);
            if(status=='Sent Back By Admin'){
                recipientsId.add(investigation.Assigned_To_User__c);
                if(investigation.RecordType.name == 'FCU'){
                    Utility.sendInAppNotification(recordId, 'FCU Record Sent Back', Constants__mdt.getInstance('Verification_Notification').value__c, recipientsId, 'Duplicate_Lead');
                }else if(investigation.RecordType.name == 'Personal Discussion'){
                    Utility.sendInAppNotification(recordId, 'PD Record Sent Back', 'A PD has been assigned to you. Please click to view the reference details.', recipientsId, 'Duplicate_Lead');
                }else {
                    Utility.sendInAppNotification(recordId, 'FI Record Sent Back', Constants__mdt.getInstance('Visit_Notification').value__c, recipientsId, 'Duplicate_Lead');
                }
                
            }
            if(status=='Approved 1'){
                recipientsId.add(investigation.Loan_Application__r.OwnerId);
                recipientsId.add(investigation.OwnerId);
                if(investigation.RecordType.name == 'Personal Discussion'){
                    Utility.sendInAppNotification(recordId, 'PD Record Approved', 'A PD has been approved. Please click to view the reference details.', recipientsId, 'Duplicate_Lead');
                }
                else {
                    Utility.sendInAppNotification(recordId, 'FI Record Approved', Constants__mdt.getInstance('Visit_Approved').Value__c, recipientsId, 'Duplicate_Lead');
                }
            }
                
            if(status=='Sent for Approval'){
                system.debug('inside sent for approval::');
                recipientsId.add(investigation.Vendor_Admin__c);
                if(investigation.RecordType.name == 'Personal Discussion'){
                    Utility.sendInAppNotification(recordId, 'PD Record Sent For Approval', 'A PD has been sent for approval by '+currentUserName+' . Please click to view the reference details.', recipientsId, 'Duplicate_Lead');
                }else {
                    Utility.sendInAppNotification(recordId, 'FI Record Sent For Approval', Constants__mdt.getInstance('Visit_Approval').value__c, recipientsId, 'Duplicate_Lead');
                }
                
                /*if(investigation.RecordType.name == 'Residence Verification'||investigation.RecordType.name == 'Business Verification'){
                    newEntry = currentUserName +' - '+ curentDtTime +' - '+ investigation.Any_Remarks_Reasons__c;
                    if(String.isNotBlank(investigation.Any_Remarks_Reasons__c) ) {
                        // If not empty, append the new entry at the end
                        investigation.Any_Remarks_Reasons__c = newEntry + '\n' + investigation.Any_Remarks_Reasons__c;
                    }
                    else {
                        // If empty, set the new entry as the initial content
                        investigation.Any_Remarks_Reasons__c = newEntry;
                    }
                }*/ //commeting for debugging purpose.
            }
            if(status=='Re Assigned to Admin'){
                recipientsId.add(investigation.Vendor_Admin__c);
                if(investigation.RecordType.name == 'Personal Discussion'){
                    Utility.sendInAppNotification(recordId, 'PD Record Assignment', 'A PD has been re-assigned to you. Please click to view the reference details.', recipientsId, 'Duplicate_Lead');
                }else{
                    Utility.sendInAppNotification(recordId, 'FI Record Assignment', Constants__mdt.getInstance('Visit_Reassigned').value__c, recipientsId, 'Duplicate_Lead');
                }
                
            }
            if(status=='Sent for Approval by FI Admin'){
                system.debug('Sent for Approval by FI Admin');
                recipientsId.add(investigation.OwnerId);
                Utility.sendInAppNotification(recordId, 'FI Record Sent For Approval',Constants__mdt.getInstance('Visit_Approval').value__c , recipientsId, 'Duplicate_Lead');
                if(investigation.RecordType.name == 'Residence Verification'||investigation.RecordType.name == 'Business Verification'){
                    system.debug('investigation.Any_Remarks_Reasons__c:: '+investigation.Any_Remarks_Reasons__c);
                    newEntry = currentUserName +' - '+ curentDtTime +': '+ comment;
                    if(String.isNotBlank(investigation.Any_Remarks_Reasons__c) ) {
                        // If not empty, append the new entry at the end
                        investigation.Any_Remarks_Reasons__c = newEntry + '\n' + investigation.Any_Remarks_Reasons__c;
                    }
                    else {
                        // If empty, set the new entry as the initial content
                        investigation.Any_Remarks_Reasons__c = newEntry;
                    }
                    system.debug('investigation.Any_Remarks_Reasons__c2:: '+investigation.Any_Remarks_Reasons__c);
                }
            }
            if(status=='Sent for Approval by PD Admin'){
                system.debug('Sent for Approval by PD Admin');
                recipientsId.add(investigation.OwnerId);
                Utility.sendInAppNotification(recordId, 'PD Record Sent For Approval', 'A PD has been sent for approval by '+currentUserName+' . Please click to view the reference details.', recipientsId, 'Duplicate_Lead');
                if(investigation.RecordType.name == 'Personal Discussion'){
                    system.debug('investigation.Any_Remarks_Reasons__c:: '+investigation.Any_Remarks_Reasons__c);
                    newEntry = currentUserName +' - '+ curentDtTime +': '+ comment;
                    if(String.isNotBlank(investigation.Any_Remarks_Reasons__c) ) {
                        // If not empty, append the new entry at the end
                        investigation.Any_Remarks_Reasons__c = newEntry + '\n' + investigation.Any_Remarks_Reasons__c;
                    }
                    else {
                        // If empty, set the new entry as the initial content
                        investigation.Any_Remarks_Reasons__c = newEntry;
                    }
                    system.debug('investigation.Any_Remarks_Reasons__c2:: '+investigation.Any_Remarks_Reasons__c);
                }
            }
            if(sObjName=='Application_Verification__c' && status=='Sent Back By Credit'){
                recipientsId.add(investigation.Vendor_Admin__c);
                System.debug('recipientsId---'+recipientsId);
                
                if(investigation.RecordType.name == 'Residence Verification'||investigation.RecordType.name == 'Business Verification'){
                    newEntry = currentUserName +' - '+ curentDtTime +' - '+ investigation.Stantard_Remark__c;
                    if(String.isNotBlank(investigation.Stantard_Remark__c) ) {
                        // If not empty, append the new entry at the end
                        investigation.Stantard_Remark__c = newEntry + '\n' + investigation.Stantard_Remark__c;
                    }
                    else {
                        // If empty, set the new entry as the initial content
                        investigation.Stantard_Remark__c = newEntry;
                    }
                    Utility.sendInAppNotification(recordId, 'FI Record Sent Back by Credit Manager', Constants__mdt.getInstance('Visit_sent_back').value__c, recipientsId, 'Duplicate_Lead');
                }else if(investigation.RecordType.name == 'Personal Discussion'){
                    newEntry = currentUserName +' - '+ curentDtTime +' - '+ investigation.Stantard_Remark__c;
                    if(String.isNotBlank(investigation.Stantard_Remark__c) ) {
                        // If not empty, append the new entry at the end
                        investigation.Stantard_Remark__c = newEntry + '\n' + investigation.Stantard_Remark__c;
                    }
                    else {
                        // If empty, set the new entry as the initial content
                        investigation.Stantard_Remark__c = newEntry;
                    }
                    Utility.sendInAppNotification(recordId, 'PD Record Sent Back by Credit Manager', 'A PD has been sent back to you. Please click to view the reference details.', recipientsId, 'Duplicate_Lead');
                }
            }
           
            //HL-Ishi-17/09
            if((status=='Sent for Approval'|| status=='Sent for Approval by FI Admin' || status=='Sent for Approval by PD Admin' ) && (investigation.RecordType.name == 'Residence Verification'||investigation.RecordType.name == 'Business Verification'||investigation.RecordType.name == 'Personal Discussion')){
                // update investigation;
            }
            

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
   
   
   @AuraEnabled
public static List<String> getUserRole(String userId, String BranchId) {
    List<String> buListofRole = new List<String>();
    try {
        for (AccountTeamMember bu : [SELECT Id, UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId = :BranchId AND UserId = :userId]) {
            buListofRole.add(bu.TeamMemberRole);
        }
                }

        catch (Exception e) {

            // throw new AuraHandledException(e.getMessage());
    }
    return buListofRole;
}
    
    @AuraEnabled
    public static String getRecordTypeName( Id recordId){
        String recordTypeName = '';
        Id recID= (Id)recordId;
        String objectName= recID.getsobjecttype().getDescribe().getName();
        
        if(objectName == 'Application_Verification__c'){
            Application_Verification__c fcuObj = [SELECT id,RecordType.Name FROM Application_Verification__c WHERE id=:recordId];
            recordTypeName = fcuObj.RecordType.Name;
        }
        return recordTypeName;
    }
    @AuraEnabled
    public static void updateAssignedUser(String recordId){
        try {
            Application_Verification__c fi=[Select id,Vendor_Admin__c, Assigned_To_User__c,Stage__c,OwnerId from Application_Verification__c where id=:recordId];
               if(fi.Assigned_To_User__c!=null && fi.Stage__c != 'Approved by CM'){
                fi.Assigned_To_User__c=fi.Vendor_Admin__c;
               }
               if(fi.Assigned_To_User__c!=null && fi.Stage__c == 'Approved by CM'){
                 fi.Assigned_To_User__c = fi.OwnerId;
               }
               update fi;     
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static void updateDocumentDetail(String recordId){
        try {
            Application_Verification__c docDetail=[SELECT Id,Document_Detail__c FROM Application_Verification__c WHERE Id =:recordId limit 1];
            Document_Details__c  docToUpdate=new Document_Details__c ();
            docToUpdate.Id=docDetail.Document_Detail__c;
            docToUpdate.Screening_Status__c='FCU Completed';
            update docToUpdate;
        } catch (Exception e) {
            System.debug('ERROR:'+ e.getStackTraceString());
            //throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static RecordWrapper setRecordButtons(Id recordId){
        String objectName,fieldAPIName = 'Stage__c',profileName,recordStatus,previousFieldValue;
        boolean recordParentFCU;
        boolean recordShowCancel;
        List<Button_Status_Handler__mdt> buttonStatus;
        SObject record;
        List<ButtonWrapper> wrapper = new List<ButtonWrapper>();
        
        // Boolean flag = checkDraftStatus(recordId);
        try {
            // if(flag){
            objectName  = recordId.getSObjectType().getDescribe().getName();
            profileName = [SELECT Id,Name FROM Profile WHERE Id=:UserInfo.getProfileId() LIMIT 1].Name;
            if(objectName == 'Application_Verification__c'){
                record = Database.query('SELECT Id,Stage__c, RecordType.Name,Loan_Application__r.Branch_Master__c,FCUalldocs__c,FCUShowCancel__c FROM '+objectName+' WHERE Id = \''+recordId+'\' LIMIT 1');
                recordStatus = (String)record.get('Stage__c') != null ? (String)record.get('Stage__c') : 'Draft';
            }
            else if (objectName == 'Legal__c'){
                record = Database.query('SELECT Id,Stage__c, RecordType.Name,Loan_Application__r.Branch_Master__c,Previous_Stage__c FROM '+objectName+' WHERE Id = \''+recordId+'\' LIMIT 1');
                previousFieldValue =(String)record.get('Previous_Stage__c') != null ? (String)record.get('Previous_Stage__c') :'';
                recordStatus = (String)record.get('Stage__c') != null ? (String)record.get('Stage__c') : 'Draft';
            }
            else if (objectName == 'Technical_Evaluation__c'){
                record = Database.query('SELECT Id,HL_Stage__c, RecordType.Name,HL_Loan_Application__r.Branch_Master__c FROM '+objectName+' WHERE Id = \''+recordId+'\' LIMIT 1');
                recordStatus = (String)record.get('HL_Stage__c') != null ? (String)record.get('HL_Stage__c') : 'Draft';
            }
            //recordStatus = (String)record.get('Stage__c') != null ? (String)record.get('Stage__c') : 'Draft'; // taking the recordStatus inside if statements since all the fields for each obj are different
            recordParentFCU = (objectName == 'Application_Verification__c') ? (Boolean)record.get('FCUalldocs__c') : false;
            recordShowCancel = (objectName == 'Application_Verification__c') ? (Boolean)record.get('FCUShowCancel__c') : false;
            String recordTypeName = (String) record.getSObject('RecordType').get('Name');
            
            if(recordTypeName == 'FCU' && objectName == 'Application_Verification__c') {
                String currProf = Utility.getCurrentUserProfileName1();
                if(currProf == 'FCU Admin') {
                    currProf = 'FCU Vendor Admin';
                }else if(currProf == 'FCU Executive') {
                    currProf = 'FCU Agent';
                }
                else if(currProf == 'Sampler')
                {
                    currProf = 'FCU Sampler';
                }
               buttonStatus = new List<Button_Status_Handler__mdt> ();
                system.debug('***objectName'+objectName);
                 system.debug('***currProf'+currProf);
                 system.debug('***recordStatus'+recordStatus);
                 system.debug('***recordParentFCU'+recordParentFCU);
                 system.debug('***recordShowCancel'+recordShowCancel);
                Map<String,Button_Status_Handler__mdt> buttonStatusMap = Button_Status_Handler__mdt.getAll();
                 buttonStatus = [
                    SELECT Id,Object_Name__c,Field_API_Name__c,Button_Label__c,Button_Status__c,FCUisparent__c,FCUShowCancel__c
                    FROM Button_Status_Handler__mdt 
                    WHERE Object_Name__c =:objectName 
                    AND Profile_Name__c =:currProf 
                    AND Stage__c =: recordStatus
                    AND FCUisparent__c =: recordParentFCU
                    AND FCUShowCancel__c  =: recordShowCancel
                    AND Module__c ='FCU'
                    LIMIT 1
                ];
                system.debug('isparent??-->'+recordParentFCU);
                for(Button_Status_Handler__mdt iterButton:buttonStatusMap.values()){
                    if(iterButton.Object_Name__c==objectName && iterButton.Stage__c == recordStatus && iterButton.Module__c == 'FCU' && iterButton.Record_Type_Name__c == recordTypeName){
                        buttonStatus.add(iterButton);
                        break;
                    }
                }

                if(buttonStatus.size()>0){
                    if(buttonStatus[0].Button_Status__c != null && buttonStatus[0].Button_Label__c != null){
                        List<String> status = buttonStatus[0].Button_Status__c.split(',');
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
            System.debug('record-----'+record);
            //Added logic to get the user role from the associated agency
            String currentRole;
            Id currentUserId = UserInfo.getUserId();
            // Query AccountTeamMember to find accounts where the current user is a team member
            List<AccountTeamMember> accountTeamMembers = [
                SELECT AccountId , TeamMemberRole 
                FROM AccountTeamMember 
                WHERE UserId = :currentUserId
            ];
            if(accountTeamMembers != null && accountTeamMembers.size() >0){
                    currentRole = accountTeamMembers[0].TeamMemberRole;
                 }
            

            if(objectName == 'Application_Verification__c'){
                System.debug('object name>'+objectName);
                System.debug('profile name>'+profileName);
                System.debug('record staus>'+recordStatus);
                System.debug('current role>'+currentRole);
                buttonStatus = [
                    SELECT Id,Object_Name__c,Field_API_Name__c,Button_Label__c,Button_Status__c,Record_Type_Name__c
                    FROM Button_Status_Handler__mdt 
                    WHERE Object_Name__c =:objectName 
                    AND Profile_Name__c =:profileName 
                    AND Stage__c =: recordStatus
                    AND Role__c =: currentRole
                    AND Record_Type_Name__c != null
                    LIMIT 1
                ];
                List<Button_Status_Handler__mdt> filteredButtonStatus = new List<Button_Status_Handler__mdt>();
                for (Button_Status_Handler__mdt status : buttonStatus) {
                    if (status.Record_Type_Name__c != null && status.Record_Type_Name__c.split(',').contains(recordTypeName)) {
                        filteredButtonStatus.add(status);
                    }
                }
                buttonStatus = filteredButtonStatus;
            }
            else if (objectName == 'Legal__c' || objectName == 'Technical_Evaluation__c'){  
                buttonStatus = [
                    SELECT Id,Object_Name__c,Field_API_Name__c,Button_Label__c,Button_Status__c 
                    FROM Button_Status_Handler__mdt 
                    WHERE Object_Name__c =:objectName 
                    AND Profile_Name__c =:profileName 
                    AND Stage__c =: recordStatus
                    AND Role__c =: currentRole
                    AND (Module__c ='Legal' OR Module__c = 'Technical')
                    LIMIT 1
                ];
                System.debug('317'+objectName+profileName+recordStatus+currentRole);
            }
            else{
                buttonStatus = [
                    SELECT Id,Object_Name__c,Field_API_Name__c,Button_Label__c,Button_Status__c 
                    FROM Button_Status_Handler__mdt 
                    WHERE Object_Name__c =:objectName 
                    AND Profile_Name__c =:profileName 
                    AND Stage__c =: recordStatus
                    LIMIT 1
                ];
            }
            System.debug('line 332-->>'+buttonStatus);
            
            if(buttonStatus.size()>0){
                if(buttonStatus[0].Button_Status__c != null && buttonStatus[0].Button_Label__c != null){
                    List<String> status = buttonStatus[0].Button_Status__c.split(',');
                    List<String> labels = buttonStatus[0].Button_Label__c.split(',');
                    
                    for(Integer index = 0;index< labels.size();index++){
                        wrapper.add(
                            new ButtonWrapper(labels[index],status[index])
                        );
                    }
                }
            }
            // }
            
        } catch (Exception exp) {
            System.debug('The Exception is : '+exp.getMessage()+' '+exp.getLineNumber());
            //Utility.generateException(exp, 'SObject', 'RecordStatusController');
            //throw new AuraHandledException(exp.getMessage());
        }
        return new RecordWrapper(objectName,fieldAPIName,previousFieldValue,recordStatus,wrapper);
    }
 
    
    @AuraEnabled
    public static String approvalAssignment(Id recordId , string buttonvalue){
        System.debug('record id -->' + recordId);
        system.debug('button value -->' + buttonvalue);  
        try {
            Id CM = null;  
            String cmMail = '';
            Id loanId = [SELECT Loan_Application__c FROM Application_Verification__c WHERE Id = :recordId].Loan_Application__c;
            List<OpportunityTeamMember> teamMembers = [SELECT Id, Name, UserId, User.Profile.Name,User.Email
                                                    FROM OpportunityTeamMember 
                                                    WHERE OpportunityId = :loanId];

            for (OpportunityTeamMember teamMember : teamMembers) {
                if (teamMember.User.Profile.Name == 'Credit Manager') {
                    CM = teamMember.UserId;
                    cmMail =  teamMember.User.Email;
                    break;  
                 } 
                }
            if(buttonvalue != 'Cancelled'){
            List<Application_Verification__c> FcuVerification = [SELECT id, Verification_Status__c,Report_Name__c, 
            // Loan_Application__r.FCU_Credit_User__r.User__r.Id	
            Loan_Application__r.Name, OwnerId ,RecordType.name,owner.name,owner.email,stage__c,CreatedById,Is_Submitted__c,Verification_Flag__c,createdby.name
                                                             FROM Application_Verification__c 
                                                             WHERE id = :recordId];
            Application_Verification__c fcu = FcuVerification[0];
            string currentuser = Utility.getCurrentUserProfileName1();
            system.debug('currentuser-->'+currentuser);
            if( currentuser == 'FCU Executive'){
                    if (String.isEmpty(fcu.Verification_Status__c)) {
                        return 'Error: Verification Status is required. Please ensure it is filled before proceeding.';
                    }
                    fcu.Assigned_To_User__c = fcu.OwnerId;
                    fcu.stage__c = 'Complete';
                    fcu.Is_Submitted__c = true;
            update fcu;
            CustomNotificationType approvalNotification = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName =: Constants__mdt.getInstance('FCU_NOTIFICATION').value__c LIMIT 1];
                String body_1 = Constants__mdt.getInstance('FCU_NOTIFICATION_BODY_temp').value__c;
                body_1 = body_1.replace('{#var1#}', fcu.Report_Name__c);
                body_1 = body_1.replace('{#var2#}', fcu.Loan_Application__r.Name);
                body_1 = body_1.replace('{#var3#}', UserInfo.getName());
                Utility.sendNotification(approvalNotification.Id, body_1, Constants__mdt.getInstance('FCU_NOTIFICATION_TITLE_3').value__c, fcu.Id, fcu.OwnerId);
                // Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                // String baseUrl = URL.getOrgDomainUrl().toExternalForm(); // Get the org domain URL dynamically
                // String recordUrl = baseUrl + '/lightning/r/Application_Verification__c/' + fcu.Id + '/view';  
                // email.setToAddresses(new String[] {fcu.Owner.Email});
                // email.setSubject('Approval Request for ' + fcu.Loan_Application__r.Name);
                // String emailBody = 'Dear ' + fcu.Owner.Name + ',\n\n';
                // emailBody += 'The report "' + fcu.Report_Name__c + '" for loan application "' + fcu.Loan_Application__r.Name + '" has been sent for approval.\n\n';
                // emailBody += 'Please review and take decision at your earliest convenience.\n\n';
                // emailBody += 'Best regards,\n' + UserInfo.getName();
                // email.setPlainTextBody(emailBody);
                // Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }
    
        else if(currentuser == 'FCU Admin' && buttonvalue == 'Approved')
            {
                fcu.Assigned_To_User__c = fcu.CreatedById;
                fcu.stage__c = 'Approved';
                if(fcu.Verification_Status__c != 'Negative/Not Recommended (NR)')
                {
                    fcu.Verification_Flag__c = 'Clear';
                }
                update fcu;
                Application_Verification__c parentfcuid = [select Parent_FCU__c  from Application_Verification__c where id = : recordId limit 1];
                system.debug('getting the parent id?'+parentfcuid.Parent_FCU__c);
                
                List<Application_Verification__c> FcuVerification2 = [select id , stage__c FROM Application_Verification__c WHERE Parent_FCU__c = :parentfcuid.Parent_FCU__c];
                system.debug('getting the parent id?'+FcuVerification2);
                Application_Verification__c parentRecord = [SELECT Id, FCUalldocs__c,FCUShowCancel__c FROM Application_Verification__c WHERE id = :parentfcuid.Parent_FCU__c LIMIT 1];
                parentRecord.FCUShowCancel__c = true;
                update parentRecord;
                Boolean allAccepted = true;
                for (Application_Verification__c fcuu : FcuVerification2) {
                    if (fcuu.stage__c != 'Approved' && fcuu.stage__c != 'Cancelled') {
                        allAccepted = false;
                        break; 
                    }
                }

                if (allAccepted) {
                    parentRecord.FCUalldocs__c = true;
                    update parentRecord;
                }
                CustomNotificationType approvalNotification = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName =: Constants__mdt.getInstance('FCU_NOTIFICATION').value__c LIMIT 1];
                    String body_1 = Constants__mdt.getInstance('FCU_NOTIFICATION_BODY_temp').value__c;
                    body_1 = body_1.replace('{#var1#}', fcu.Report_Name__c);
                    body_1 = body_1.replace('{#var2#}', fcu.Loan_Application__r.Name);
                    body_1 = body_1.replace('{#var3#}', UserInfo.getName());
                    Utility.sendNotification(approvalNotification.Id, body_1,Constants__mdt.getInstance('FCU_NOTIFICATION_TITLE_3').value__c, fcu.Id, fcu.CreatedById);
                    // Sending Email
                    // Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    // String baseUrl = URL.getOrgDomainUrl().toExternalForm(); // Get the org domain URL dynamically
                    // String recordUrl = baseUrl + '/lightning/r/Application_Verification__c/' + fcu.Id + '/view';  
                    // // Set the recipient email address
                    // email.setToAddresses(new String[] {cmMail}); // {fcu.CreatedBy.Email});
                    
                    // // Set the subject of the email
                    // email.setSubject('Application Verification Sent for Approval');
                    
                    // // Set the body of the email
                    // String emailBody = 'Dear ' + fcu.CreatedBy.Name + ',\n\n';
                    // emailBody += 'The FCU report "' + '" for loan application "' + fcu.Loan_Application__r.Name + '" has been sent for approval by FCU Admin.\n';
                    // emailBody += 'Please review and take the necessary actions.\n\n';
                    // emailBody += 'To view the application verification, click the following link:\n' + recordUrl + '\n\n';
                    // emailBody += 'Best regards,\n' + UserInfo.getName();
  
                    // email.setPlainTextBody(emailBody);
                    
                    // // Send the email
                    // Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
                }
            else if (currentuser == 'Sampler' && buttonvalue == 'Accepted')
            {
                system.debug('are we in for sampler?');
                List<Application_Verification__c> FcuVerification1 = [select id , Status__c, IsParent__c , CreatedById , OwnerId , Owner.name,Report_Name__c,Loan_Application__r.Name,Stage__c FROM Application_Verification__c WHERE id = :recordId];
                Application_Verification__c fcuu = FcuVerification1[0];
                system.debug('child fcu??--'+FcuVerification1[0].id);
                fcuu.stage__c = 'Accepted';
                update fcuu;
                Map<Id, String> verificationStatusMap = new Map<Id, String>();
                List<Application_Verification__c> childfcu = [select id,OwnerId,Stage__c,CreatedById,Parent_FCU__r.CreatedById,Parent_FCU__r.Stage__c,Document_Detail__c,Address__c,Verification_Status__c from Application_Verification__c where Parent_FCU__c =: FcuVerification1[0].id];
                system.debug('child fcu??--'+childfcu);
                List<Application_Verification__c> updateList = new List<Application_Verification__c>();
                set<id> docids = new set<id>();
                set<id> profileids = new set<id>();
                for ( Application_Verification__c fcu1 : childfcu){
                if(fcu1.stage__c != 'Cancelled')
                {   
                    fcu1.stage__c = 'Accepted';
                    docids.add(fcu1.Document_Detail__c);
                    profileids.add(fcu1.Address__c);
                    if (fcu1.Document_Detail__c != null) {
                        verificationStatusMap.put(fcu1.Document_Detail__c, fcu1.Verification_Status__c);
                    }
                    updateList.add(fcu1);

                }  
                }
                update updateList;
                List<Document_Details__c> docDetails = [SELECT Id, FCU_Initiated__c ,Screening_Status__c,Verification_Status__c FROM Document_Details__c WHERE id =: docids];
                List<Applicant_Address__c> addresslist = [SELECT Id, FCU_Initiated__c ,Screening_Status__c FROM Applicant_Address__c WHERE id =: profileIds];
                if (docDetails != null && !docDetails.isEmpty()) {
                    for (Document_Details__c docDetail : docDetails) {
                    docDetail.FCU_Initiated__c = false;
                    docDetail.Screening_Status__c = 'FCU Completed';
                    // docDetail.Verification_Status__c = verificationStatusMap.get(docDetail.Id);
                    docDetail.Verification_Status__c = 'Verified';
                    
                }
                update docDetails;
                }
                if (addresslist != null && !addresslist.isEmpty()) {
                    for (Applicant_Address__c add : addresslist) {
                        add.FCU_Initiated__c = false;
                        add.Screening_Status__c = 'FCU Completed';
                }
                update addresslist;
            }
                if(CM != null){
                CustomNotificationType approvalNotification = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName =: Constants__mdt.getInstance('FCU_NOTIFICATION').value__c LIMIT 1];
                    String body_1 = Constants__mdt.getInstance('FCU_NOTIFICATION_BODY_COMPLETE').value__c;
                    body_1 = body_1.replace('{#var1#}', fcu.Report_Name__c);
                    body_1 = body_1.replace('{#var2#}', fcu.Loan_Application__r.Name);
                    body_1 = body_1.replace('{#var3#}', UserInfo.getName());
                    Utility.sendNotification(approvalNotification.Id, body_1, Constants__mdt.getInstance('FCU_NOTIFICATION_TITLE_6').value__c, fcuu.Id, CM);
                    // Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    // String baseUrl = URL.getOrgDomainUrl().toExternalForm(); // Get the org domain URL dynamically
                    // String recordUrl = baseUrl + '/lightning/r/Application_Verification__c/' + fcu.Id + '/view';  
                    // // Set the recipient email address
                    // email.setToAddresses(new String[] {cmMail}); //{fcuu.Owner.Email});
                    
                    // // Set the subject of the email
                    // email.setSubject('Application Verification Accepted');
                    
                    // // Set the body of the email
                    // String emailBody = 'Dear ' + 'Credit Manager' + ',\n\n';
                    // emailBody += 'The FCU report "' + '" for loan application "' + fcu.Loan_Application__r.Name + '" has been marked as Accepted.\n';
                    // emailBody += 'The related verification tasks have been completed.\n\n';
                    // emailBody += 'To view the application verification, click the following link:\n' + recordUrl + '\n\n';
                    // emailBody += 'Best regards,\n' + UserInfo.getName();
                    // email.setPlainTextBody(emailBody);
                    
                    // // Send the email
                    // Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
                }
                }
            else if (currentuser == 'Sampler' && buttonvalue == 'Initiated')
            {
                system.debug('are we in for sampler?');
                Application_Verification__c FcuVerification1 = [
                SELECT Id, Status__c, Parent_FCU__c, Stage__c, OwnerId, Owner.Name, IsParent__c, Loan_Application__r.Name
                FROM Application_Verification__c
                WHERE Id = :recordId
                LIMIT 1
             ];
                if (FcuVerification1.IsParent__c == true) {
                    // If it's a parent record, update all its children
                    List<Application_Verification__c> childVerifications = [
                        SELECT Id, Stage__c
                        FROM Application_Verification__c
                        WHERE Parent_FCU__c = :FcuVerification1.Id
                    ];
            
                    for (Application_Verification__c child : childVerifications) {
                        child.Stage__c = 'Initiated';
                    }
            
                    update childVerifications;
            
                    // Set the parent's FCUalldocs__c to false
                    FcuVerification1.FCUalldocs__c = false;
                    update FcuVerification1;
            
                } else {
                    // It's a child record, update its parent and itself
                    String parentfcuid = FcuVerification1.Parent_FCU__c;
                    Application_Verification__c parentfcu = [
                        SELECT Id, FCUalldocs__c
                        FROM Application_Verification__c
                        WHERE Id = :parentfcuid
                    ];
            
                    parentfcu.FCUalldocs__c = false;
                    update parentfcu;
            
                FcuVerification1.Stage__c = 'Initiated';
                update FcuVerification1;
                }
                CustomNotificationType approvalNotification = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName =: Constants__mdt.getInstance('FCU_NOTIFICATION').value__c LIMIT 1];
                    String body_1 = Constants__mdt.getInstance('FCU_NOTIFICATION_BODY_temp').value__c;
                    body_1 = body_1.replace('{#var1#}', fcu.Report_Name__c);
                    body_1 = body_1.replace('{#var2#}', fcu.Loan_Application__r.Name);
                    body_1 = body_1.replace('{#var3#}', UserInfo.getName());
                    Utility.sendNotification(approvalNotification.Id, body_1, Constants__mdt.getInstance('FCU_NOTIFICATION_TITLE_3').value__c, FcuVerification1.Id, FcuVerification1.OwnerId);
                    // Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    // String baseUrl = URL.getOrgDomainUrl().toExternalForm(); // Get the org domain URL dynamically
                    // String recordUrl = baseUrl + '/lightning/r/Application_Verification__c/' + fcu.Id + '/view';  
                    // // Set the recipient email address
                    // email.setToAddresses(new String[] {FcuVerification1.Owner.Email}); //{fcuu.Owner.Email});
                    
                    // // Set the subject of the email
                    // email.setSubject('Application Verification Accepted');
                    
                    // // Set the body of the email
                    // String emailBody = 'Dear ' + 'FCU Admin' + ',\n\n';
                    // emailBody += 'The FCU report "' + '" for loan application "' + fcu.Loan_Application__r.Name + '" has been sent back\n';
                    // emailBody += 'To view the application verification, click the following link:\n' + recordUrl + '\n\n';
                    // emailBody += 'Best regards,\n' + UserInfo.getName();
                    // email.setPlainTextBody(emailBody);
                    
                    // // Send the email
                    // Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
                }
            
            return fcu.Owner.name; 
            }
        else
        {    

        List<Application_Verification__c> FcuVerification1 = [select id , Status__c, IsParent__c , CreatedById , OwnerId , Owner.name,Report_Name__c,Loan_Application__r.Name,Stage__c,Parent_FCU__c,CreatedBy.Name  FROM Application_Verification__c WHERE id = :recordId];
        system.debug('checking the record'+FcuVerification1);
        Application_Verification__c fcuu = FcuVerification1[0];
        if (fcuu.IsParent__c == true){
        fcuu.OwnerId = fcuu.CreatedById;
        fcuu.stage__c = 'Cancelled';
        update fcuu;
        List<Application_Verification__c> childfcu = [select id,OwnerId,Stage__c,CreatedById,Parent_FCU__r.CreatedById,Parent_FCU__r.Stage__c,Document_Detail__c,Address__c from Application_Verification__c where Parent_FCU__c =: FcuVerification1[0].id];
        List<Application_Verification__c> updateList = new List<Application_Verification__c>();
        set<id> docids = new set<id>();
        set<id> profileids = new set<id>();
        for ( Application_Verification__c fcu1 : childfcu)
        {   
            fcu1.OwnerId = fcu1.CreatedById;
            fcu1.stage__c = 'Cancelled';
            docids.add(fcu1.Document_Detail__c);
            profileids.add(fcu1.Address__c);
            updateList.add(fcu1);
        }
        update updateList;
        List<Document_Details__c> docDetails = [SELECT Id, FCU_Initiated__c ,Screening_Status__c FROM Document_Details__c WHERE id =: docids];
                List<Applicant_Address__c> addresslist = [SELECT Id, FCU_Initiated__c ,Screening_Status__c FROM Applicant_Address__c WHERE id =: profileIds];
                if (docDetails != null && !docDetails.isEmpty()) {
                    for (Document_Details__c docDetail : docDetails) {
                    docDetail.FCU_Initiated__c = false;
                    docDetail.Screening_Status__c = 'Cancelled';
                }
                update docDetails;
                }
                if (addresslist != null && !addresslist.isEmpty()) {
                    for (Applicant_Address__c add : addresslist) {
                        add.FCU_Initiated__c = false;
                        add.Screening_Status__c = 'Cancelled';
                }
                update addresslist;
                }
            }
            else{   
                fcuu.OwnerId = fcuu.CreatedById;
                fcuu.stage__c = 'Cancelled';
                update fcuu;
            List<Application_Verification__c> childfcu = [select id,OwnerId,Stage__c,CreatedById,Parent_FCU__r.CreatedById,Parent_FCU__r.Stage__c,Document_Detail__c,Address__c from Application_Verification__c where id =: FcuVerification1[0].id];
            List<Application_Verification__c> updateList = new List<Application_Verification__c>();
            set<id> docids = new set<id>();
            set<id> profileids = new set<id>();
            for ( Application_Verification__c fcu1 : childfcu)
            {   
                fcu1.OwnerId = fcu1.CreatedById;
                fcu1.stage__c = 'Cancelled';
                docids.add(fcu1.Document_Detail__c);
                profileids.add(fcu1.Address__c);
                updateList.add(fcu1);
            }
            update updateList;
            List<Document_Details__c> docDetails = [SELECT Id, FCU_Initiated__c ,Screening_Status__c FROM Document_Details__c WHERE id =: docids];
                    List<Applicant_Address__c> addresslist = [SELECT Id, FCU_Initiated__c ,Screening_Status__c FROM Applicant_Address__c WHERE id =: profileIds];
                    if (docDetails != null && !docDetails.isEmpty()) {
                        for (Document_Details__c docDetail : docDetails) {
                        docDetail.FCU_Initiated__c = false;
                        docDetail.Screening_Status__c = 'Cancelled';
                    }
                    update docDetails;
                    }
                    if (addresslist != null && !addresslist.isEmpty()) {
                        for (Applicant_Address__c add : addresslist) {
                            add.FCU_Initiated__c = false;
                            add.Screening_Status__c = 'Cancelled';
                    }
                    update addresslist;
                    }
                Application_Verification__c parentRecord = [select id , stage__c,FCUalldocs__c from Application_Verification__c where id =: FcuVerification1[0].Parent_FCU__c ];
                List<Application_Verification__c> allchild = [select id , stage__c from Application_Verification__c where Parent_FCU__c =: parentRecord.id] ;
                system.debug('list of all child-->'+allchild);
                Boolean allAccepted = true;
                if(allchild.size() > 1){
                for(Application_Verification__c app : allchild)
                    {
                        if(app.stage__c != 'Approved' && app.stage__c != 'Cancelled')
                        {
                        allAccepted = false;
                        break;
                    } 
                }
                if (allAccepted) {
                    parentRecord.FCUalldocs__c = true;
                    update parentRecord;
                }
            }
            else{
                parentRecord.stage__c = 'Cancelled';
                update parentRecord;
                }
                }
                CustomNotificationType approvalNotification = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName =: Constants__mdt.getInstance('FCU_NOTIFICATION').value__c LIMIT 1];
                String body_1 = Constants__mdt.getInstance('FCU_NOTIFICATION_BODY_Cancel').value__c;
                body_1 = body_1.replace('{#var1#}', fcuu.Report_Name__c);
                body_1 = body_1.replace('{#var2#}', fcuu.Loan_Application__r.Name);
                body_1 = body_1.replace('{#var3#}', fcuu.CreatedBy.Name);
                Utility.sendNotification(approvalNotification.Id, body_1, Constants__mdt.getInstance('FCU_NOTIFICATION_TITLE_3').value__c, fcuu.Id, fcuu.OwnerId);
                return  FcuVerification1[0].Owner.name;
        }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
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
    public static Boolean isReportPending(Id recordId) {
        Boolean flag = false;
        if (recordId == null) return null;
        List<Document_Details__c> docDetails = new List<Document_Details__c>();
        String objectType = recordId.getSObjectType().getDescribe().getName();
         SObject record = Database.query('SELECT RecordType.Name FROM ' + objectType + ' WHERE Id = :recordId LIMIT 1');
         System.debug('RecordType:'+ record );
        String recordTypeName =(String)record.getSObject('RecordType').get('Name');
        System.debug('RecordTypename'+ recordTypeName);
        if(recordTypeName == Constants.LEGAL_RECORD_TYPE_SCRUTINY || recordTypeName == Constants.LEGAL_RECORD_TYPE_SEARCH || recordTypeName == Constants.LEGAL_RECORD_TYPE_VETTING || recordTypeName == Constants.LEGAL_RECORD_TYPE_SCRUTINY_WITH_TITLE_SEARCH){
            docDetails = [Select id, Content_Document_Id__c,Name from Document_Details__c where Legal__c =:recordId and Document_Category__c = 'Legal Documents Master' and Content_Document_Id__c=null];//updated
            System.debug('DocDetails'+ docDetails);
            if(docDetails.size()>0){
                flag = true;
            }
        }
        return flag;
    }

}