/*
* Author    :   Deloitte India
* Purpose   :   Controller class for all components across FCU module
* @last modified on  : 
* @last modified by  : 
*/

public without sharing class FCUController {

    @AuraEnabled
    public static void  shareCdlRecords(Id recordId){
     
             try {
    List<Document_Details__c> docList = [
        SELECT Id, Content_Document_Id__c
        FROM Document_Details__c
        WHERE Loan_Application__c = :recordId AND Content_Document_Id__c != NULL AND Requirement_Level__c != Null AND Active__c = true AND Eligible_For_FCU__c = true AND Consider_for_Loan_Application__c = true
        AND Content_Document_Id__c != NULL
    ];
    System.debug('docList >>> ' + docList);

    if (docList.isEmpty()) {
        return;
    }

    Set<Id> ddIds = new Set<Id>();
    Set<Id> desiredContentDocIds = new Set<Id>();
    for (Document_Details__c dd : docList) {
        ddIds.add(dd.Id);
        desiredContentDocIds.add(dd.Content_Document_Id__c);
    }

    List<ContentDocumentLink> existingCdls = [
        SELECT Id, LinkedEntityId, ContentDocumentId
        FROM ContentDocumentLink
        WHERE LinkedEntityId IN :ddIds
          AND ContentDocumentId IN :desiredContentDocIds
    ];

    
    Map<Id, Set<Id>> existingByEntity = new Map<Id, Set<Id>>();
    for (ContentDocumentLink cdl : existingCdls) {
        Set<Id> docSet = existingByEntity.get(cdl.LinkedEntityId);
        if (docSet == null) {
            docSet = new Set<Id>();
            existingByEntity.put(cdl.LinkedEntityId, docSet);
        }
        docSet.add(cdl.ContentDocumentId);
    }


   
    List<ContentDocumentLink> toInsert = new List<ContentDocumentLink>();
  
    for (Document_Details__c dd : docList) {
        if (dd.Content_Document_Id__c == null) continue;

        Set<Id> alreadyLinkedDocs = existingByEntity.get(dd.Id);
        Boolean notLinkedYet = (alreadyLinkedDocs == null) || !alreadyLinkedDocs.contains(dd.Content_Document_Id__c);

        if (notLinkedYet) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId    = dd.Id;                           
            cdl.ContentDocumentId = dd.Content_Document_Id__c;      
            cdl.ShareType         = 'V';                             
            cdl.Visibility        = 'AllUsers';                      
            toInsert.add(cdl);
        }
    }


    System.debug('CDLs to insert >>> ' + toInsert);

    if (!toInsert.isEmpty()) {
        insert toInsert;
    }

            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
 
    /**
     * @description	    :	Method tha gets the document checklist and content ids.
     * @param           :   Loan Application recordId
     * @return          :   return the cotent details for document.
    **/
    @AuraEnabled(cacheable=true)
    public static List<ContentVersion> getDocumentsChecklist(Id recordId) {
        List<ContentVersion> contentList = new List<ContentVersion>();
        try{
            String sObjName = recordId.getSObjectType().getDescribe().getName();
            List<Document_Details__c> checklistRecords = new  List<Document_Details__c> ();
            if(recordId != null &&  sObjName=='Opportunity'){
                Map<String, String> inputMapUtility = new Map<String, String>();
                Utility_V1.ProductWrapper isHLRelatedFinal = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
                Boolean isHlRelated = isHLRelatedFinal.isHLRelated;
                if(isHlRelated){
                    checklistRecords = [
            SELECT Content_Document_Id__c 
            FROM Document_Details__c 
            WHERE Loan_Application__c = :recordId 
              AND Content_Document_Id__c != NULL 
              AND Requirement_Level__c != NULL 
              AND Active__c = true 
              AND (Eligible_For_FCU__c = true OR Send_For_FCU__c = true)
              AND Consider_for_Loan_Application__c = true
        ];
                } else {
                    checklistRecords = [
            SELECT Content_Document_Id__c 
            FROM Document_Details__c 
            WHERE Loan_Application__c = :recordId 
              AND Content_Document_Id__c != NULL 
              AND Requirement_Level__c != NULL 
              AND Active__c = true 
              AND (Eligible_For_FCU__c = true OR Send_For_FCU__c = true)
        ];
                }
            }

            // shareCdlRecords(recordId);

                if(checklistRecords.size()>0){
                    Set<String> contentIds = new Set<String>();
                    for (Document_Details__c record : checklistRecords) {
                        if (record.Content_Document_Id__c != null) {
                            contentIds.add(record.Content_Document_Id__c);
                        }
                    }

                    if (contentIds.size() > 0) {
                        contentList = [SELECT Id, ContentDocumentId, FileExtension
                                        FROM ContentVersion
                                        WHERE ContentDocumentId IN :contentIds
                                        AND FileExtension IN ('pdf','PDF','jpg','png','jpeg','zip')
                                        ORDER BY CreatedDate DESC
                                    ];
                    }
                }
        }
        catch(Exception exp){
         Utility.generateException(exp, Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, Constants__mdt.getInstance('FCU_CLASS_1').value__c);
        }
        return contentList;
    }

    /**
     * @description	    :	Fetch Query Records.
     * @param           :   Loan Application recordId
     * @return          :   return the query records related to Loan Applicantion.
    **/

    @AuraEnabled(cacheable=true)
    public static List<Query__c> getQueries(Id recordId) {
        List<Query__c> queryList = new List<Query__c>();
        try{
            if(recordId != null){
               queryList = [SELECT Id,Name FROM Query__c WHERE Loan_Application__c =: recordId AND Requestor__c =: UserInfo.getUserId()];
            }
        }catch(Exception exp){
         Utility.generateException(exp, Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, Constants__mdt.getInstance('FCU_CLASS_1').value__c);
        }
        return queryList;
    }


    /**
     * @description	    :	Method that fetch applicants data.
     * @param           :   Loan Application recordId
     * @return          :   returns all the applicant related to loan
    **/
   @AuraEnabled
    public static List<ApplicantDetailsValues> getApplicantsDetailsList(Id recordId) {
        List<ApplicantDetailsValues> applicantList = new List<ApplicantDetailsValues>();
        try{
            if(recordId != null){
                List<Applicant_Address__c> applicantAddressData = [SELECT Id, FCU_Initiated__c,FCU_Triggered__c, Floor_Number__c, Plot_Number__c, Building_Street_Name__c, Landmark__c, Pincode__c, Town__c, District__c, State__c, Post_Office__c, Name, Address_Type__c, Applicant__c, Applicant__r.Applicant_Type__c, Applicant__r.First_Name__c, Applicant__r.Last_Name__c,Applicant__r.Loan_Application__c, Loan_Application__c ,Remarks__c,Referred_By__r.Name,Referred_By_Role__c FROM Applicant_Address__c WHERE Applicant__r.Loan_Application__c =: recordId AND Applicant__c != NULL AND (Screening_Status__c = 'Added to sampling queue' or Screening_Status__c = 'Recommended For FCU' or Screening_Status__c ='FCU Completed')];
                if(applicantAddressData.size()>0){
                    for(Applicant_Address__c iter : applicantAddressData){
                        ApplicantDetailsValues applicantValues = new ApplicantDetailsValues();
                        applicantValues.id = iter.id;
                        applicantValues.fcuInitiatedStatus = iter.FCU_Initiated__c;
                        applicantValues.name = iter.Applicant__r.First_Name__c + ' ' + (iter.Applicant__r.Last_Name__c != null ? iter.Applicant__r.Last_Name__c : '');
                        applicantValues.type = iter.Applicant__r.Applicant_Type__c;
                        applicantValues.addrType = iter.Address_Type__c;
                        applicantValues.remarks = iter.Remarks__c;
                        applicantValues.referredBy=iter.Referred_By__r.Name;
                        applicantValues.referredByRole=iter.Referred_By_Role__c;
                        if(iter.FCU_Triggered__c){
                            applicantValues.fcuStatus = 'FCU Initiated';
                        }else{
                            applicantValues.fcuStatus = 'Pending';
                            //Send a mail to FCU sample user
                            /*OpportunityTeamMember targetUser = [SELECT User.Email FROM OpportunityTeamMember where TeamMemberRole = 'Sampler' and OpportunityId  =: iter.Loan_Application__c limit 1];
                            String userEmail = targetUser.User.Email;
                            String Subject = 'FCU pending';
                            String Body = 'The new document is added onto the Loan application'+ iter.Loan_Application__r.Name +'Please review the details and proceed with the evaluation at your earliest convenience.'; 
                            
                            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                            List<String> toAddresses = new List<String>();
                            toAddresses.add(userEmail);
                            mail.setToAddresses(toAddresses);
                            mail.setSubject(subject);
                            mail.setPlainTextBody(body);
                            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });*/
                            
                        }

                        applicantList.add(applicantValues);
                        system.debug('checking the list' +applicantList);
                    }
                }
            }
        }catch(Exception exp){
         Utility.generateException(exp, Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, Constants__mdt.getInstance('FCU_CLASS_1').value__c);
        }
        return applicantList;
    }
    public class ApplicantDetailsValues{
        @AuraEnabled public string id {get;set;}
        @AuraEnabled public string name {get;set;}
        @AuraEnabled public string type {get;set;}
        @AuraEnabled public Boolean fcuInitiatedStatus {get;set;}
        @AuraEnabled public String fcuStatus {get;set;}
        @AuraEnabled public String addrType {get;set;}
        @AuraEnabled public String remarks {get;set;}
        @AuraEnabled public String referredBy {get;set;}
        @AuraEnabled public String referredByRole {get;set;}
    }

    @AuraEnabled
    public static List<ProfileValuesFORSampling> getApplicantsDetailsListForSampling(Id recordId, Boolean fromCredit) {
        List<ProfileValuesFORSampling> profileWrapper = new List<ProfileValuesFORSampling>();
        Map<String, List<ApplicantDetailsValuesFORSampling>> proFileSamplingData = new Map<String, List<ApplicantDetailsValuesFORSampling>>();
        try{
            if(recordId != null){
                List<Applicant_Address__c> applicantAddressData = [SELECT Id, FCU_Initiated__c, FCU_Triggered__c,Screening_Status__c, Floor_Number__c, Plot_Number__c, Building_Street_Name__c, Landmark__c, Pincode__c, Town__c, District__c, State__c, Post_Office__c, Name, Address_Type__c, Applicant__c, Applicant__r.Applicant_Type__c, Applicant__r.First_Name__c, Applicant__r.Last_Name__c,Applicant__r.Loan_Application__c, Loan_Application__c, Remarks__c,Full_Address1__c,Pincode__r.Name FROM Applicant_Address__c WHERE Applicant__r.Loan_Application__c =: recordId AND Applicant__c != NULL AND Address_Type__c != 'BSA' AND Pincode__c != null AND Address_Line_1__c != null AND Full_Address1__c != null ORDER BY Applicant__r.Applicant_Type__c ASC];
                if(applicantAddressData.size()>0){
                    for(Applicant_Address__c iter : applicantAddressData){
                        ApplicantDetailsValuesFORSampling applicantValues = new ApplicantDetailsValuesFORSampling();
                        applicantValues.id = iter.id;
                        applicantValues.name = iter.Applicant__r.First_Name__c + ' ' + (iter.Applicant__r.Last_Name__c != null ? iter.Applicant__r.Last_Name__c : '');
                        applicantValues.type = iter.Applicant__r.Applicant_Type__c;
                        applicantValues.addrType = iter.Address_Type__c;
                        applicantValues.remarks = iter.Remarks__c;
                        applicantValues.fullAddr = iter.Full_Address1__c +', ' + + iter.State__c + ' - ' + + iter.Pincode__r.name;//iter.Plot_Number__c + ', ' + iter.Building_Street_Name__c + ', ' + iter.Landmark__c + ', '+ iter.Post_Office__c + ', ' + iter.Town__c + ', ' + + iter.District__c + ', ' + + iter.State__c + ' - ' + + iter.Pincode__c;
                        if(iter.Screening_Status__c != 'Added to sampling queue' && iter.Screening_Status__c != 'Recommended For FCU'){
                            applicantValues.screening = false;
                        }else{
                            applicantValues.screening = true;
                        }
                        if(iter.FCU_Initiated__c){
                            applicantValues.fcuInitiated = true;
                        }else{
                            applicantValues.fcuInitiated = false;
                        }
                        if(fromCredit){
                            if(iter.Screening_Status__c == 'Added to sampling queue'){
                                applicantValues.screeningstatus = 'Recommended For FCU';
                            }
                            else{
                                applicantValues.screeningstatus = iter.Screening_Status__c;
                            }
                        }
                        else{
                            applicantValues.screeningstatus = iter.Screening_Status__c;
                        }

                        List<ApplicantDetailsValuesFORSampling> tempWrap = new List<ApplicantDetailsValuesFORSampling>();
                        if(proFileSamplingData.get(applicantValues.name + ' ('+applicantValues.type+')')!=null){
                            tempWrap = proFileSamplingData.get(applicantValues.name + ' ('+applicantValues.type+')');
                        }
                        tempWrap.add(applicantValues);
                        proFileSamplingData.put(applicantValues.name + ' ('+applicantValues.type+')', tempWrap);
                    }
                }

                if(proFileSamplingData.size()>0){
                    for(String iter : proFileSamplingData.keySet()){
                        ProfileValuesFORSampling tempProfile = new ProfileValuesFORSampling();
                        tempProfile.name = iter;
                        tempProfile.applicantData = proFileSamplingData.get(iter);

                        profileWrapper.add(tempProfile);
                    }
                }
            }
        }catch(Exception exp){
            Utility.generateException(exp, Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, Constants__mdt.getInstance('FCU_CLASS_1').value__c);
        }
        System.debug('profileWrapper -->'+profileWrapper);
        return profileWrapper;
    }
    public class ProfileValuesFORSampling{
        @AuraEnabled public string name {get;set;}
        @AuraEnabled public List<ApplicantDetailsValuesFORSampling> applicantData {get;set;}
    }
    public class ApplicantDetailsValuesFORSampling{
        @AuraEnabled public string id {get;set;}
        @AuraEnabled public Boolean fcuInitiated {get;set;}
        @AuraEnabled public string name {get;set;}
        @AuraEnabled public string type {get;set;}
        @AuraEnabled public Boolean screening {get;set;}
        @AuraEnabled public String screeningstatus {get;set;}
        @AuraEnabled public String addrType {get;set;}
        @AuraEnabled public String fullAddr {get;set;}
        @AuraEnabled public String remarks {get;set;}
       
    }

    /**
     * @description	    :	Method that gets the child fcu data
     * @param           :   FCU Parent record Id
     * @return          :   
    **/
        @AuraEnabled
        public static List<FraudDocWrapper> getChildData(Id recordId) {
            List<FraudDocWrapper> fraudToDocList = new List<FraudDocWrapper>();

            if (recordId == null) return fraudToDocList;

            try {
                String sObjName = recordId.getSObjectType().getDescribe().getName();

                Id profileRecordTypeId = Utility.getRecordTypeIdByDeveloperName(
                    Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, 
                    Constants__mdt.getInstance('FCU_RECORD_TYPE_PROFILE').value__c
                );

                // Query parent record
                List<Application_Verification__c> parendFCU = [
                    SELECT Id, RecordTypeId, Parent_FCU__c, Cancellation_Remarks__c 
                    FROM Application_Verification__c 
                    WHERE Id = :recordId
                ];

                List<Application_Verification__c> fcuChildId = new List<Application_Verification__c>();
                String parentremarks;

                if(parendFCU[0].Parent_FCU__c == null){
                    fcuChildId = [
                        SELECT Id 
                        FROM Application_Verification__c 
                        WHERE Parent_FCU__c = :recordId 
                        AND Stage__c != 'Not Accepted By Admin'
                    ];
                    parentremarks = parendFCU[0].Cancellation_Remarks__c;
                } else {
                    fcuChildId = parendFCU;
                }

                String profile = Utility.getCurrentUserProfileName1();
                String urlImg = '';
                if(profile == 'FCU Admin' || profile == 'FCU Executive'){
                    Id communityId = Network.getNetworkId();
                    String base = Network.getLoginUrl(communityId);
                    urlImg = base.replace('/s/login', '');
                }

                Map<Id, List<DocWrapper>> fieldIdToDocListMap = new Map<Id, List<DocWrapper>>();

                if(fcuChildId.size() > 0){
                    // Query all Document_Details__c once
                    List<Document_Details__c> docList = [
                        SELECT Id, Is_New_Created__c, Name, Content_Document_Id__c, Application_Verification__c, 
                            Application_Verification__r.Approval_Status__c 
                        FROM Document_Details__c 
                        WHERE Application_Verification__c IN :fcuChildId 
                        ORDER BY Name
                    ];

                    for(Document_Details__c docListIter : docList){
                        List<DocWrapper> tempDocWrapper = new List<DocWrapper>();
                        DocWrapper docCheck = new DocWrapper();

                        if(docListIter.Content_Document_Id__c != null){
                            docCheck.isUploaded = true;
                            docCheck.imageUrl = urlImg + '/sfc/servlet.shepherd/document/download/' + docListIter.Content_Document_Id__c;
                        } else {
                            docCheck.isUploaded = false;
                        }

                        docCheck.isNewAdded = docListIter.Is_New_Created__c;
                        docCheck.name = docListIter.Name;
                        docCheck.docId = docListIter.Id;
                        docCheck.contentId = docListIter.Content_Document_Id__c;
                        docCheck.fcuId = docListIter.Application_Verification__c;

                        if(
                            docListIter.Application_Verification__r.Approval_Status__c == Constants__mdt.getInstance('FCU_APPROVAL_NOT_INITIATED').value__c ||
                            docListIter.Application_Verification__r.Approval_Status__c == Constants__mdt.getInstance('FCU_APPROVAL_SENT_BACK').value__c ||
                            (docListIter.Content_Document_Id__c != null && (
                                docListIter.Application_Verification__r.Approval_Status__c == Constants__mdt.getInstance('FCU_APPROVAL_APPROVED').value__c ||
                                docListIter.Application_Verification__r.Approval_Status__c == Constants__mdt.getInstance('FCU_APPROVAL_INITIATED').value__c
                            ))
                        ) {
                            if(fieldIdToDocListMap.get(docListIter.Application_Verification__c) != null){
                                tempDocWrapper = fieldIdToDocListMap.get(docListIter.Application_Verification__c);
                            }
                            tempDocWrapper.add(docCheck);
                            fieldIdToDocListMap.put(docListIter.Application_Verification__c, tempDocWrapper);
                        }
                    }
                }

                Map<Id, Application_Verification__c> childFraudMap = new Map<Id, Application_Verification__c>([
                    SELECT Id, Full_Address__c, RecordTypeId, Document_Detail__r.Content_Document_Id__c, Applicant__c, 
                        Report_Name__c, Approval_Status__c, Sent_Back_Remark__c, Verification_Remarks__c, Verification_Remarks_History__c, Name,
                        Verification_Status__c, Address_Type__c, Stage__c, Admin_s_Remarks__c, Area_Manager_s_Remarks__c, Owner.Name, Owner.Profile.Name, 
                        Cancellation_Remarks__c, Credit_Manager_s_Remarks__c, Verification_Flag__c, Broad_Reason__c, Short_Reason__c, Applicant_s_Number__c, OGL__c
                    FROM Application_Verification__c 
                    WHERE Id IN :fcuChildId
                ]);

                // Query Application_Verification__History once for all children
                List<Application_Verification__History> fraudHistories = [
                    SELECT ParentId, NewValue, OldValue, Createddate, Field, CreatedBy.Name 
                    FROM Application_Verification__History 
                    WHERE ParentId IN :childFraudMap.keySet() 
                    AND Field = 'Owner' 
                    ORDER BY CreatedDate DESC
                ];

                Map<Id, List<Application_Verification__History>> IdToHistoryListMap = new Map<Id, List<Application_Verification__History>>();
                for(Application_Verification__History fh : fraudHistories){
                    if(IdToHistoryListMap.containsKey(fh.ParentId)){
                        IdToHistoryListMap.get(fh.ParentId).add(fh);
                    }
                    else{
                        IdToHistoryListMap.put(fh.ParentId, new List<Application_Verification__History>{fh});
                    }
                }

                                
                Set<Id> contentDocIds = new Set<Id>();
                for (Application_Verification__c fraud : childFraudMap.values()) {
                    if (fraud.Document_Detail__r != null && fraud.Document_Detail__r.Content_Document_Id__c != null) {
                        contentDocIds.add(fraud.Document_Detail__r.Content_Document_Id__c);
                    }
                }

                
                Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>(
                    [SELECT ContentDocumentId, FileExtension
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :contentDocIds
                    AND IsLatest = true]
                );

                
                for (Id key : childFraudMap.keySet()) {
                    FraudDocWrapper tempFraudDocWrapper = new FraudDocWrapper();
                    Application_Verification__c tempChildFraud = childFraudMap.get(key);

                    tempFraudDocWrapper.fcuName = tempChildFraud.Report_Name__c;
                    tempFraudDocWrapper.docShonName = tempChildFraud.Name + ' - ' + tempChildFraud.Report_Name__c + ' - ' + tempChildFraud.Stage__c;
                    tempFraudDocWrapper.fcuId = tempChildFraud.Id;
                    tempFraudDocWrapper.approvalStatus = tempChildFraud.Stage__c;
                    tempFraudDocWrapper.addressType = tempChildFraud.Verification_Status__c;
                    tempFraudDocWrapper.remark = tempChildFraud.Verification_Remarks__c;
                    tempFraudDocWrapper.remarkHistory = tempChildFraud.Verification_Remarks_History__c;
                    tempFraudDocWrapper.sendBackRemark = tempChildFraud.Sent_Back_Remark__c;
                    tempFraudDocWrapper.fullAddress = tempChildFraud.Full_Address__c;
                    tempFraudDocWrapper.verificationflag = tempChildFraud.Verification_Flag__c;
                    tempFraudDocWrapper.cancellationremarks = String.isBlank(tempChildFraud.Cancellation_Remarks__c) ? parentremarks : tempChildFraud.Cancellation_Remarks__c;
                    tempFraudDocWrapper.shortreason = tempChildFraud.Short_Reason__c;
                    tempFraudDocWrapper.broadreason = tempChildFraud.Broad_Reason__c;
                    tempFraudDocWrapper.OGL = tempChildFraud.OGL__c;
                    tempFraudDocWrapper.applnumber = tempChildFraud.Applicant_s_Number__c;

                    if (tempChildFraud.RecordTypeId == profileRecordTypeId) {
                        tempFraudDocWrapper.profileFCU = true;
                    }

                    if (tempChildFraud.Document_Detail__r != null &&
                        tempChildFraud.Document_Detail__r.Content_Document_Id__c != null &&
                        tempChildFraud.Stage__c != 'Cancelled') {
                        
                        tempFraudDocWrapper.fcushowDoc = true;
                        tempFraudDocWrapper.fcushowApplicant = false;
                        Id docId = tempChildFraud.Document_Detail__r.Content_Document_Id__c;
                        tempFraudDocWrapper.fcuContentId = docId;

                        ContentVersion cv = contentVersionMap.get(docId);
                        String fileExtension = (cv != null && cv.FileExtension != null) ? cv.FileExtension.toLowerCase() : '';
                        tempFraudDocWrapper.isPdf = (fileExtension == 'pdf');

                        tempFraudDocWrapper.fcuDocURL = urlImg + '/sfc/servlet.shepherd/document/download/' + docId;

                    } else if (tempChildFraud.Applicant__c != null) {
                        tempFraudDocWrapper.fcushowDoc = false;
                        tempFraudDocWrapper.fcushowApplicant = true;
                        tempFraudDocWrapper.fcuapplicantId = tempChildFraud.Applicant__c;
                    }

                    tempFraudDocWrapper.isAreaManager = (profile == Constants__mdt.getInstance('FCU_PROFILE_AREA_MANAGER').value__c);

                    if (fieldIdToDocListMap.containsKey(key)) {
                        tempFraudDocWrapper.showCheckList = true;
                        tempFraudDocWrapper.docChecklist = fieldIdToDocListMap.get(key);
                    } else {
                        tempFraudDocWrapper.showCheckList = false;
                    }

                    if (profile == 'FCU Admin' || profile == 'Admin') {
                        if (tempChildFraud.Stage__c == 'Draft') {
                            tempFraudDocWrapper.showAcceptButton = true;
                        } else if (tempChildFraud.Stage__c == 'Accepted By Admin') {
                            tempFraudDocWrapper.showReassignButton = true;
                        }
                    }

                    if (tempChildFraud.Stage__c == 'Not Accepted By Admin') {
                        tempFraudDocWrapper.disableOnNotAccept = true;
                    }

                    tempFraudDocWrapper.adminRemarks = tempChildFraud.Admin_s_Remarks__c;
                    tempFraudDocWrapper.areaManagerRemarks = tempChildFraud.Area_Manager_s_Remarks__c;
                    tempFraudDocWrapper.creditMangerRemarks = tempChildFraud.Credit_Manager_s_Remarks__c;
                    tempFraudDocWrapper.agentName = tempChildFraud.Owner.Name;

                    tempFraudDocWrapper.isDraftRec = (tempChildFraud.Stage__c == 'Draft' || 
                                                    (tempChildFraud.Owner.Profile != null && tempChildFraud.Owner.Profile.Name == 'FCU Vendor Admin'));

                    tempFraudDocWrapper.ownerHistory = new List<OwnerDetailsWrapper>();
                    tempFraudDocWrapper.isHistoryAvail = false;

                    if (IdToHistoryListMap.containsKey(tempChildFraud.Id)) {
                        for (Application_Verification__History iterFH : IdToHistoryListMap.get(tempChildFraud.Id)) {
                            OwnerDetailsWrapper owWrap = new OwnerDetailsWrapper();
                            owWrap.name = String.valueOf(iterFH.NewValue);
                            owWrap.timeStamp = String.valueOf(iterFH.CreatedDate);
                            owWrap.changedBy = iterFH.CreatedBy.Name;
                            if (!owWrap.name.startsWith('005')) {
                                tempFraudDocWrapper.ownerHistory.add(owWrap);
                                tempFraudDocWrapper.isHistoryAvail = true;
                            }
                        }
                    }

                    fraudToDocList.add(tempFraudDocWrapper);
                }

            }
            catch(Exception e){
                System.debug('error getChildData  is ===> ' + e.getMessage());
            }
            return fraudToDocList;
        }

    public class FraudDocWrapper{
        @AuraEnabled public String fcuName;
        @AuraEnabled public String fcuId;
        @AuraEnabled public String addressType;
        @AuraEnabled public String fcuContentId;
        @AuraEnabled public String fcuDocURL;
        @AuraEnabled public Boolean fcushowDoc;
        @AuraEnabled public String fcuapplicantId;
        @AuraEnabled public Boolean fcushowApplicant;
        @AuraEnabled public String approvalStatus;
        @AuraEnabled public String verificationflag;
        @AuraEnabled public String docShonName;
        @AuraEnabled public String remark;
        @AuraEnabled public String remarkHistory;
        @AuraEnabled public String sendBackRemark;
        @AuraEnabled public Boolean isAreaManager;
        @AuraEnabled public Boolean showCheckList;
        @AuraEnabled public Boolean profileFCU;
        @AuraEnabled public Boolean collateralFCU;
        @AuraEnabled public Boolean showAcceptButton;
        @AuraEnabled public Boolean showReassignButton;
        @AuraEnabled public String fullAddress;
        @AuraEnabled public List<DocWrapper> docChecklist;
        @AuraEnabled public Boolean disableOnNotAccept;
        @AuraEnabled public String adminRemarks;
        @AuraEnabled public String areaManagerRemarks;
        @AuraEnabled public String creditMangerRemarks;
        @AuraEnabled public String agentName;
        @AuraEnabled public Boolean isDraftRec;
        @AuraEnabled public List<OwnerDetailsWrapper> ownerHistory;
        @AuraEnabled public Boolean isHistoryAvail;
        @AuraEnabled public Boolean isLocationType;
        @AuraEnabled public String cancellationremarks;
        @AuraEnabled public String shortreason;
        @AuraEnabled public String broadreason;
        @AuraEnabled public Boolean isPdf;
        @AuraEnabled public String applnumber;
        @AuraEnabled public String OGL;
    }
    public class OwnerDetailsWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public String timeStamp;
        @AuraEnabled public String changedBy;
    }
    public class DocWrapper{
        @AuraEnabled public Boolean isNewAdded;
        @AuraEnabled public String docId;
        @AuraEnabled public String name;
        @AuraEnabled public Boolean isUploaded;
        @AuraEnabled public String imageUrl;
        @AuraEnabled public String contentId;
        @AuraEnabled public String fcuId;
        @AuraEnabled public String fcuName;
    }    

    /**
     * @description	    :	Method that fetch the screening status of documents
     * @param           :   FCU Parent record Id
     * @return          :   return list of documents
    **/
   @AuraEnabled
    public static List<Document_Details__c> getDocumentScreeningStatus(Id recordId) {
        //Ishi-Vendor Onboarding
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        //Ishi-Vendor Onboarding
        List<Document_Details__c> docList= new  List<Document_Details__c>();
        if(sObjName=='Opportunity'){
            docList= [SELECT Id, Name ,FCU_Triggered__c,Content_Document_Id__c,Remarks__c,FCU_Initiated__c, Screening_Status__c, Owner.Name, Applicant__c, Applicant__r.Name, Applicant__r.First_Name__c, Applicant__r.Last_Name__c, Requirement_Level__c,Referred_By__r.Name,Referred_By__c,Referred_By_Role__c,Document_Details__c,
                Document_Master__r.Document_Category__c
                FROM Document_Details__c 
                WHERE Loan_Application__c = :recordId 
                AND Content_Document_Id__c != NULL
                AND Requirement_Level__c != Null
                AND Active__c = true
                AND (Eligible_For_FCU__c = true OR Send_For_FCU__c = true)
                ORDER BY CreatedDate DESC
            ];
                }
        return docList;
    }

    /**
     * @description	    :	Method that fetch applicants data.
     * @param           :   FCU Parent record Id
     * @return          :  
    **/
    @AuraEnabled
    public static Map<String, ParentFCUData> getDocumentApplicantCollateralFCU(Id recordId) {
        Map<String, ParentFCUData> docIdFCUMap = new Map<String, ParentFCUData>();
        try{
            if(recordId != null){
                List<Application_Verification__c> allChildFraud = [SELECT Id, Address_Type__c, Document_Detail__c, Address__c,Vendor__c, /*Application_Collateral__c,*/ Parent_FCU__c, Parent_FCU__r.Name, Loan_Application__c FROM Application_Verification__c WHERE (Parent_FCU__r.Loan_Application__c =: recordId or Parent_FCU__r.Vendor__c =: recordId)];
                if(allChildFraud.size()>0){
                    for(Application_Verification__c iterFraud : allChildFraud){
                        ParentFCUData tempWrap = new ParentFCUData();
                        tempWrap.fcuId = iterFraud.Parent_FCU__c;
                        tempWrap.name = iterFraud.Parent_FCU__r.Name;
                        tempWrap.addressValue = iterFraud.Address_Type__c;
                        if(iterFraud.Document_Detail__c != null){
                            docIdFCUMap.put(iterFraud.Document_Detail__c, tempWrap);
                        }
                        if(iterFraud.Vendor__c != null){
                            docIdFCUMap.put(iterFraud.Vendor__c, tempWrap);
                        }
                        if(iterFraud.Address__c != null){
                            docIdFCUMap.put(iterFraud.Address__c, tempWrap);
                        }
                    }
                }

            }
        }catch(Exception exp){
            Utility.generateException(exp, Constants__mdt.getInstance('DOCUMENTCHECKLISTS_OBJECT_NAME').value__c, Constants__mdt.getInstance('FCU_CLASS_1').value__c);
        }
        System.debug('docIdFCUMap=:'+docIdFCUMap);
        return docIdFCUMap;
    }
    public class ParentFCUData{
        @AuraEnabled public String fcuId;
        @AuraEnabled public String name;
        @AuraEnabled public String addressValue;
    }

    /**
     * @description	    :	Method that get fisebase64 of content documents
     * @param           :   contentdocumentid
     * @return          :   returns base64 content
    **/
    // @AuraEnabled(cacheable=true)
    // public static String getFileAsBase64(Id contentDocumentId) {
    //     List<ContentVersion> contentVersions = [
    //         SELECT VersionData 
    //         FROM ContentVersion 
    //         WHERE ContentDocumentId = :contentDocumentId 
    //         ORDER BY VersionNumber DESC 
    //         LIMIT 1
    //     ];
    //     if (contentVersions.isEmpty()) {
    //         throw new AuraHandledException('No ContentVersion found for the given ContentDocumentId: ' + contentDocumentId);
    //     }
        
    //     ContentVersion cv = contentVersions[0];

    //     Blob fileBlob = cv.VersionData;
        
    //     String base64FileContent = EncodingUtil.base64Encode(fileBlob);
    //     return base64FileContent;
    // }

    

    /**
     * @description	    :	Method that stores the content data.
     * @param           :   base64 data of file, File Name, File Type
     * @return          :   content id of the uploaded document
    **/
    @AuraEnabled
    public static String uploadFile(String base64Data, String fileName, String fileType) {
        String contentId = Constants__mdt.getInstance('DOCUMENT_NOT_SAVE_ERROR').value__c;
        try{
            if(base64Data !=null && fileName != null && fileType != null){
                Blob fileBlob = EncodingUtil.base64Decode(base64Data);
    
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = fileName;
                contentVersion.PathOnClient = fileName;
                contentVersion.VersionData = fileBlob;
                contentVersion.ContentLocation = 'S'; // S for Salesforce, 'E' for external
                //contentVersion.FileType = fileType;
                insert contentVersion;
        
                contentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
            }
        }catch(Exception exp){
            Utility.generateException(exp, Constants__mdt.getInstance('CONTENT_VERSION_OBJECT_NAME').value__c, Constants__mdt.getInstance('FCU_CLASS_1').value__c);
        }
        return contentId;
    }

    
    /**
     * @description	    :	Method that stores the content data.
     * @param           :   FCU record Id, uploaded doc content id, document id
     * @return          :   Boolean
    **/
    @AuraEnabled
    public static Boolean storeContent(String recordId, String contentId, String docId){
        Boolean allUploaded = false;
        try{
            if(recordId != null && contentId != null && docId != null){
                Document_Details__c doc = new Document_Details__c();
                if(docId != null){
                    doc.Id = docId;
                }
                doc.Content_Document_Id__c = contentId;
                // Database.Update(doc);
                upsert doc;

                String fcuChildIdToShare = [SELECT Id, Application_Verification__c FROM Document_Details__c WHERE Id =: docId LIMIT 1].Application_Verification__c;

                if(fcuChildIdToShare != null){
                    ContentDocumentLink cdl = New ContentDocumentLink();
                    cdl.LinkedEntityId = fcuChildIdToShare;
                    cdl.ContentDocumentId = contentId;
                    cdl.shareType = 'V';
                    insert cdl;
    
                    List<Application_Verification__c> fcuChildId = [SELECT Id from Application_Verification__c WHERE Parent_FCU__c =: recordId];
                    if(fcuChildId.size() > 0){
                        List<Document_Details__c> docListAll = [SELECT Id, Name, Content_Document_Id__c, Application_Verification__c, Application_Verification__r.Report_Name__c FROM Document_Details__c WHERE Application_Verification__c IN :fcuChildId];
                        List<Document_Details__c> docList = [SELECT Id, Name, Content_Document_Id__c, Application_Verification__c, Application_Verification__r.Report_Name__c FROM Document_Details__c WHERE Application_Verification__c IN :fcuChildId AND Content_Document_Id__c != null];
    
                        if(docListAll.size() == docList.size()){
                            allUploaded = true;
                        }
                    }
                }
            }
        }catch(Exception exp){
            System.debug('exveption698'+exp.getmessage());
            Utility.generateException(exp, Constants__mdt.getInstance('DOCUMENTCHECKLISTS_OBJECT_NAME').value__c, Constants__mdt.getInstance('FCU_CLASS_1').value__c);
        }

        return allUploaded;
    }

    /**
     * @description	    :	Method that checks if parent is present
     * @param           :   loan id
     * @return          :   Boolean
    **/
    @AuraEnabled
    public static Boolean checkIfParentPresent(Id loanId){
        String sObjName = loanId.getSObjectType().getDescribe().getName();
        Boolean flag = false;
        try{     
            List<Application_Verification__c> parentFraudId = new List<Application_Verification__c>();
            Id parentRecordTypeId = Utility.getRecordTypeIdByDeveloperName(Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, Constants__mdt.getInstance('FCU_RECORD_TYPE_PARENT').value__c);
            system.debug('parent id is??--'+parentRecordTypeId);
            if(sObjName=='Opportunity'){
                parentFraudId = [SELECT Id, Loan_Application__c FROM Application_Verification__c WHERE RecordTypeId =: parentRecordTypeId AND Loan_Application__c =: loanId LIMIT 1];
            }

            if(parentFraudId.size()>0){
                flag = true;
            }
        }catch(Exception exp){
            Utility.generateException(exp, Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, Constants__mdt.getInstance('FCU_CLASS_1').value__c);
        }
        return flag;
    }

    /**
     * @description	    :	Method that creates parent fcu
     * @param           :   sampler id ,loandid , remarks , parent record id , sobject
     * @return          :   parent fcu record
    **/
    public static Application_Verification__c createParentRecord(String loanId, String samplerId, String parentRecordTypeId, String remarks, Opportunity loanDetails){
        Application_Verification__c parentFCU = new Application_Verification__c();
        try{
            String primaryApplicant = '';
            String secondaryApplicant = '';
            List<Opportunity> loanList = [Select Id, Branch_Master__r.Branch_Region_Name__c from Opportunity where id =: loanId];
            String clusterName = loanList[0].Branch_Master__r.Branch_Region_Name__c;
            String productName ='';
            List<Application_Applicant__c> appApplicantsOnLoan = [SELECT Id , First_Name__c, Last_Name__c, Applicant_Type__c FROM Application_Applicant__c WHERE Loan_Application__c =: loanId AND Applicant_Type__c != 'Guarantor'];
            for(Application_Applicant__c iterApplicant : appApplicantsOnLoan){
                if(iterApplicant.Applicant_Type__c == 'Primary Applicant'){
                    primaryApplicant = iterApplicant.First_Name__c + ' ' + (iterApplicant.Last_Name__c != null ? iterApplicant.Last_Name__c : '');
                }

                if(iterApplicant.Applicant_Type__c == 'Co Applicant' && (secondaryApplicant == null || secondaryApplicant == '')){
                    secondaryApplicant = iterApplicant.First_Name__c + ' ' + (iterApplicant.Last_Name__c != null ? iterApplicant.Last_Name__c : '');
                }else if(iterApplicant.Applicant_Type__c == 'Co Applicant' && (secondaryApplicant != null || secondaryApplicant != '')){
                    secondaryApplicant = secondaryApplicant + ',' + iterApplicant.First_Name__c + ' ' + (iterApplicant.Last_Name__c != null ? iterApplicant.Last_Name__c : '');
                }
            }

            User vendorDetails = [SELECT Id,Name, Contact.Account.Id FROM User WHERE Id =: samplerId LIMIT 1];
            String statename = '';
            if (loanDetails.Branch_Master__r != null && 
                String.isNotBlank(loanDetails.Branch_Master__r.State__c)) {
                String state = loanDetails.Branch_Master__r.State__c.replace(' ', '_');
            Constants__mdt stateInstance = Constants__mdt.getInstance(state);
                statename = (stateInstance != null && stateInstance.value__c != null) 
                            ? stateInstance.value__c 
                            : '';
            }

            system.debug('state name-->'+statename);

                Application_Verification__c createParentFraud = new Application_Verification__c();
                createParentFraud.Loan_Application__c = loanId;
                createParentFraud.RecordTypeId = parentRecordTypeId;
                createParentFraud.IsParent__c = true;
                createParentFraud.Report_Name__c = loanDetails.Name;
                createParentFraud.Vendor__c = vendorDetails.contact.Account.Id;
                createParentFraud.OwnerId = samplerId;
                createParentFraud.Sample_Date__c = DateTime.now();
                createParentFraud.Approval_Status__c = Constants__mdt.getInstance('FCU_APPROVAL_NOT_INITIATED').value__c;
                createParentFraud.Branch__c = loanDetails.Branch_Master__c;
                createParentFraud.State__c = statename;
                createParentFraud.Primary_Applicant__c = primaryApplicant;
                createParentFraud.Co_Applicant_s__c = secondaryApplicant;
                createParentFraud.Agents_s_Branch__c = loanDetails.Branch_Master__c;
                createParentFraud.Applicant__c = appApplicantsOnLoan[0].id;
                createParentFraud.Cluster__c = clusterName;
                // createParentFraud.Sampler_Remarks__c = remarks;
                createParentFraud.Product__c = loanDetails.Product__c;
                // if(remarks != null){
                //     createParentFraud.Sampler_Remarks__c = remarks;
                // }
                insert createParentFraud;
                system.debug('created parent-->'+createParentFraud);
    
                parentFCU = [SELECT Id, Name, Agents_s_Branch__c, Loan_Application__r.Name, OwnerId, Vendor__c, Sampler_Remarks__c, Loan_Application__c, Primary_Applicant__c, Co_Applicant_s__c, Cluster__c, Product__c, State__c, Branch__c, External_Vendor__c,Applicant__c FROM Application_Verification__c WHERE RecordTypeId =: parentRecordTypeId AND Loan_Application__c =: loanId AND OwnerId =: samplerId ORDER BY CreatedDate desc LIMIT 1];
        }catch(Exception exp){
            System.debug('Exception803'+exp.getMessage());
            Utility.generateException(exp, Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, Constants__mdt.getInstance('FCU_CLASS_1').value__c);
        }

        return parentFCU;
    }

    /**
     * @description	    :	Method that initiates fcu.
     * @param           :   document ids map , profileids map , sampler id ,loandid , flag , document map
     * @return          :   Boolean
    **/
    @AuraEnabled
    public static String  initiateFCU(Map<String, String> docIds, Map<String, String> profileIds,Map<String,String> selectedRecordsVendorList,String samplerId, String remarks, Id loanId, Boolean flag, Map<String, String> newdocmap){
        
        try{  
            
            Id recordId=loanId;
            Opportunity  loan = [SELECT Status__c FROM Opportunity WHERE Id = :recordId LIMIT 1];

            if (loan.Status__c == 'Cancelled'|| loan.Status__c == 'Rejected' || loan.Status__c == 'Soft Rejected') {
                return 'LoanStatus Error'; 
            }
            String sObjName = recordId.getSObjectType().getDescribe().getName();       

            System.debug('docIds -->'+docIds);
            System.debug('samplerId -->'+samplerId);
            System.debug('remarks -->'+remarks);
            system.debug('new docs added -->'+newdocmap);
          
         List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
        Utility.SharingInfo si = new Utility.SharingInfo();
        si.objectName = 'Opportunity';
        si.userOrGroupId = Constants__mdt.getInstance('Partner_User').value__c;
        si.recordToShareId = loanId;
        si.sharingAccess = Constants.READ_ACCESS; // changing to read access
        sharingList.add(si);
        Utility.createShareRecord(JSON.serialize(sharingList));
            Id parentRecordTypeId = Utility.getRecordTypeIdByDeveloperName(Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, Constants__mdt.getInstance('FCU_RECORD_TYPE_PARENT').value__c);
            system.debug('recordtypr -->'+parentRecordTypeId);
            Boolean createdOrUpdated = false;
            Application_Verification__c parentFraudId = new Application_Verification__c();
            Opportunity loanDetails = new Opportunity();
            Account vendorDetails = new Account();
            String productName;
            String clusterName;
            Map<Id,Application_Verification__c> docToFCUMap = new Map<Id,Application_Verification__c>();
            Map<Id,Application_Verification__c> addressToFCUMap = new Map<Id,Application_Verification__c>();
            List<Application_Verification__c> existingFCUList = [Select Id, Document_Details__c, Address__c, FCU_Admin__c from Application_Verification__c where (Document_Details__c in: docIds.keySet() or Address__c in: profileIds.keySet()) and Parent_FCU__c != null];
            for(Application_Verification__c fcu : existingFCUList){
                if(fcu.Document_Details__c != null){
                    docToFCUMap.put(fcu.Document_Details__c,fcu);
                }
                else if(fcu.Address__c != null){
                    addressToFCUMap.put(fcu.Address__c,fcu);
                }
            }
            if(sObjName=='Opportunity'){
                loanDetails=[SELECT Id, Name, Branch_Master__c,Product__c,Branch_Master__r.State__c,Branch_Master__r.Branch_Region_Name__c FROM Opportunity WHERE Id =: loanId LIMIT 1];
                clusterName =  loanDetails.Branch_Master__r.Branch_Region_Name__c;//Branch__r.Region_Name__c;
                if(flag){
                    List<Application_Verification__c> parentFraudList = [SELECT Id, Name, Loan_Application__r.Name, Approval_Status__c, OwnerId, Agents_s_Branch__c, /*Vendor__c,*/ Sampler_Remarks__c, 
                                                                    Loan_Application__c, Primary_Applicant__c, Co_Applicant_s__c, Cluster__c, Product__c, State__c, Branch__c,External_Vendor__c,Applicant__c,IsParent__c
                                                                    FROM Application_Verification__c WHERE RecordTypeId =: parentRecordTypeId AND Loan_Application__c =: loanId AND IsParent__c = true  AND stage__c = 'In Progress'];
                    Map<Id, Application_Verification__c> parentFraudMap = new Map<Id, Application_Verification__c>();
                    for(Application_Verification__c parentIter : parentFraudList){
                        parentFraudMap.put(parentIter.OwnerId, parentIter);
                    }

                    if(parentFraudMap.get(samplerId)!=null){
                        system.debug('are we inside if?');
                        parentFraudId = parentFraudMap.get(samplerId);
                        if(remarks != parentFraudId.Sampler_Remarks__c && remarks != null && remarks != ''){
                            parentFraudId.Sampler_Remarks__c = remarks;
                        }
                        if(parentFraudId.Approval_Status__c == Constants__mdt.getInstance('FCU_APPROVAL_APPROVED').value__c){
                            parentFraudId.Approval_Status__c = Constants__mdt.getInstance('FCU_APPROVAL_INITIATED').value__c;
                        }
                        Database.Update(parentFraudId);
                        System.debug('parentFraudId--1--'+parentFraudId);
                    }else{
                        parentFraudId = createParentRecord(loanId, samplerId, parentRecordTypeId, remarks, loanDetails);
                        createdOrUpdated = true;
                    }
                }else if(samplerId != null && loanId != null){
                    parentFraudId = createParentRecord(loanId, samplerId, parentRecordTypeId, remarks, loanDetails);
                    createdOrUpdated = true;
                    System.debug('parentFraudId--2--'+parentFraudId);
                }
            }
            List<Application_Verification__c> createChildFraud = new List<Application_Verification__c>();
            List<Application_Verification__c> updateFCURecs = new List<Application_Verification__c>();
            System.debug('parentFraudId--3--'+parentFraudId);
            if(parentFraudId.Id != null){
                if(docIds.keySet().size()>0){
                    System.debug('docIds -->'+docIds);
                    if(sObjName=='Opportunity'){
                        List<Document_Details__c> docDetails = [SELECT Id, Name, Content_Document_Id__c, Screening_Status__c, Owner.Name, Applicant__c, Applicant__r.Name, Requirement_Level__c, Applicant__r.First_Name__c, Applicant__r.Last_Name__c,Remarks__c,FCU_Triggered__c
                                                                FROM Document_Details__c 
                                                                WHERE Loan_Application__c = :loanId
                                                                AND Content_Document_Id__c != NULL AND Id IN :docIds.keySet()
                                                                ORDER BY CreatedDate DESC];
    
                        if(docDetails.size()>0){
                            for(Document_Details__c iterDocId : docDetails){
                                if(iterDocId.Screening_Status__c == 'Sent Back' && docToFCUMap.containsKey(iterDocId.Id)){
                                    Application_Verification__c fcu = docToFCUMap.get(iterDocId.Id);
                                    fcu.Stage__c = 'Draft';
                                    fcu.OwnerId = fcu.FCU_Admin__c;
                                    updateFCURecs.add(fcu);
                                }
                                // else{
                                //     Application_Verification__c childDocFraud = new Application_Verification__c();
                                //     childDocFraud.RecordTypeId = parentRecordTypeId;
                                //     childDocFraud.FCU_Check_type__c = 'Document';
                                //     childDocFraud.Document_Detail__c = iterDocId.Id;
                                //     childDocFraud.Parent_FCU__c = parentFraudId.Id;
                                //     if(iterDocId.Applicant__r.First_Name__c != null && iterDocId.Applicant__r.Last_Name__c != null){
                                //         childDocFraud.Report_Name__c = iterDocId.Name + ' (' +  iterDocId.Applicant__r.First_Name__c + ' ' + iterDocId.Applicant__r.Last_Name__c + ')';
                                //     }else{
                                //         childDocFraud.Report_Name__c = iterDocId.Name;
                                //     }
                                //     childDocFraud.stage__c = Constants__mdt.getInstance('FCU_Accepted').value__c;
                                //     childDocFraud.OwnerId = samplerId;
                                //     childDocFraud.Branch__c = loanDetails.Branch_Master__c;
                                //     childDocFraud.Agents_s_Branch__c = parentFraudId.Agents_s_Branch__c;
                                //     childDocFraud.Address_Type__c = docIds.get(iterDocId.Id);
                                //     childDocFraud.Loan_Application__c = parentFraudId.Loan_Application__c;
                                //     childDocFraud.Primary_Applicant__c = parentFraudId.Primary_Applicant__c;
                                //     childDocFraud.Co_Applicant_s__c = parentFraudId.Co_Applicant_s__c;
                                //     childDocFraud.Cluster__c = parentFraudId.Cluster__c;
                                //     childDocFraud.Product__c = parentFraudId.Product__c;
                                //     childDocFraud.State__c = parentFraudId.State__c;
                                //     //childDocFraud.Branch__c = parentFraudId.Branch__c;
                                //     childDocFraud.Sample_Date__c = System.now();
                                //     childDocFraud.OwnerId = parentFraudId.OwnerId;
                                //     childDocFraud.Applicant__c =  parentFraudId.Applicant__c;
                                //     childDocFraud.Approval_Status__c = Constants__mdt.getInstance('FCU_APPROVAL_NOT_INITIATED').value__c;
                                //     if (iterDocId.Remarks__c != null) {
                                //         childDocFraud.Sampler_Remarks__c = iterDocId.Remarks__c;
                                //     }
                                //     createChildFraud.add(childDocFraud);
                                // }
                                else{
                                    Application_Verification__c childDocFraud = new Application_Verification__c();
                                    populateCommonChildFields(
                                        childDocFraud,
                                        parentRecordTypeId,
                                        'Document',
                                        parentFraudId.Id,
                                        loanDetails,
                                        parentFraudId
                                    );

                                    childDocFraud.Document_Detail__c = iterDocId.Id;
                                    childDocFraud.Address_Type__c = docIds.get(iterDocId.Id);

                                    if (iterDocId.Applicant__r.First_Name__c != null && iterDocId.Applicant__r.Last_Name__c != null) {
                                        childDocFraud.Report_Name__c = iterDocId.Name + ' (' + iterDocId.Applicant__r.First_Name__c + ' ' + iterDocId.Applicant__r.Last_Name__c + ')';
                                    } else {
                                        childDocFraud.Report_Name__c = iterDocId.Name;
                                    }

                                    if (iterDocId.Remarks__c != null) {
                                        childDocFraud.Sampler_Remarks__c = iterDocId.Remarks__c;
                                    }
                                createChildFraud.add(childDocFraud);                                  
                                }
                                iterDocId.FCU_Initiated__c = true;
                                iterDocId.FCU_Triggered__c = true;
                            }
                            System.debug('parentFraudId--4--'+docDetails);
                            Database.Update(docDetails);
                        }
                    }                   
                }
               
                    System.debug('parentFraudId---'+parentFraudId);
               
                if(sObjName!='Vendor__c'){
                    if(profileIds.keySet().size()>0){
                        System.debug('profileIds -->'+profileIds);
                        List<Applicant_Address__c> applicantAddressData = [SELECT Id, FCU_Initiated__c, FCU_Triggered__c,Screening_Status__c, Floor_Number__c, Plot_Number__c, Building_Street_Name__c, Landmark__c, Pincode__r.name, Town__c, District__c, State__c, Post_Office_Name__c, Name, Address_Type__c, Applicant__c, Applicant__r.Applicant_Type__c, Applicant__r.First_Name__c, Applicant__r.Last_Name__c,Applicant__r.Loan_Application__c, Loan_Application__c, Remarks__c,Full_Address1__c FROM Applicant_Address__c WHERE Applicant__r.Loan_Application__c =: loanId AND Id IN: profileIds.keySet()];
                        system.debug('The value for applicant address is  -->'+applicantAddressData);
                        if(applicantAddressData.size()>0){
                            for(Applicant_Address__c iterApplicant : applicantAddressData){
                                if(iterApplicant.Screening_Status__c == 'Sent Back' && addressToFCUMap.containsKey(iterApplicant.Id)){
                                    Application_Verification__c fcu = addressToFCUMap.get(iterApplicant.Id);
                                    fcu.OwnerId = fcu.FCU_Admin__c;
                                    fcu.Stage__c = 'Draft';
                                    updateFCURecs.add(fcu);
                                }
                                // else{
                                //     Application_Verification__c childProfileFraud = new Application_Verification__c();
                                //     childProfileFraud.RecordTypeId = parentRecordTypeId;
                                //     childProfileFraud.FCU_Check_type__c = 'Profile';
                                //     childProfileFraud.Applicant__c = iterApplicant.Applicant__c;
                                //     childProfileFraud.Address__c = iterApplicant.Id;
                                //     childProfileFraud.Parent_FCU__c = parentFraudId.Id;
                                //     childProfileFraud.Report_Name__c = iterApplicant.Applicant__r.First_Name__c + ' ' + iterApplicant.Applicant__r.Last_Name__c + ' (' +  iterApplicant.Applicant__r.Applicant_Type__c + ') - ' + iterApplicant.Address_Type__c;
                                //     childProfileFraud.OwnerId = samplerId;
                                //     childProfileFraud.stage__c = Constants__mdt.getInstance('FCU_Accepted').value__c;                                   
                                //     childProfileFraud.Branch__c = loanDetails.Branch_Master__c;
                                //     childProfileFraud.Address_Type__c = profileIds.get(iterApplicant.Id);
                                //     childProfileFraud.Agents_s_Branch__c = parentFraudId.Agents_s_Branch__c;
                                //     childProfileFraud.Full_Address__c = iterApplicant.Full_Address1__c + ', ' + + iterApplicant.State__c + ' - ' + + iterApplicant.Pincode__r.name; //iterApplicant.Plot_Number__c + ', ' + iterApplicant.Building_Street_Name__c + ', ' + iterApplicant.Landmark__c + ', '+ iterApplicant.Post_Office_Name__c + ', ' + iterApplicant.Town__c + ', ' + + iterApplicant.District__c + ', ' + + iterApplicant.State__c + ' - ' + + iterApplicant.Pincode__c;
                                //     childProfileFraud.Loan_Application__c = parentFraudId.Loan_Application__c;
                                //     childProfileFraud.Primary_Applicant__c = parentFraudId.Primary_Applicant__c;
                                //     childProfileFraud.Co_Applicant_s__c = parentFraudId.Co_Applicant_s__c;
                                //     childProfileFraud.Cluster__c = parentFraudId.Cluster__c;
                                //     childProfileFraud.Product__c = parentFraudId.Product__c;
                                //     childProfileFraud.State__c = parentFraudId.State__c;
                                //     childProfileFraud.Branch__c = parentFraudId.Branch__c;
                                //     childProfileFraud.Sample_Date__c = System.now();
                                //     childProfileFraud.OwnerId = parentFraudId.OwnerId;
                                //     childProfileFraud.Approval_Status__c = Constants__mdt.getInstance('FCU_APPROVAL_NOT_INITIATED').value__c;
                                //     if (iterApplicant.Remarks__c != null) {
                                //         childProfileFraud.Sampler_Remarks__c = iterApplicant.Remarks__c;
                                //     }
                                //     createChildFraud.add(childProfileFraud);
                                // }
                                else{
                                    Application_Verification__c childProfileFraud = new Application_Verification__c();
                                populateCommonChildFields(
                                    childProfileFraud,
                                    parentRecordTypeId,
                                    'Profile',
                                    parentFraudId.Id,
                                    loanDetails,
                                    parentFraudId
                                );

                                childProfileFraud.Address__c = iterApplicant.Id;
                                childProfileFraud.Applicant__c = iterApplicant.Applicant__c;
                                childProfileFraud.Address_Type__c = profileIds.get(iterApplicant.Id);
                                childProfileFraud.Full_Address__c = iterApplicant.Full_Address1__c + ', ' + iterApplicant.State__c + ' - ' + iterApplicant.Pincode__r.Name;

                                childProfileFraud.Report_Name__c =
                                    iterApplicant.Applicant__r.First_Name__c + ' ' +
                                    iterApplicant.Applicant__r.Last_Name__c + ' (' +
                                    iterApplicant.Applicant__r.Applicant_Type__c + ') - ' +
                                    iterApplicant.Address_Type__c;

                                if (iterApplicant.Remarks__c != null) {
                                    childProfileFraud.Sampler_Remarks__c = iterApplicant.Remarks__c;
                                }
                                createChildFraud.add(childProfileFraud);
                                }
                                iterApplicant.FCU_Initiated__c = true; 
                                iterApplicant.FCU_Triggered__c = true; 
                            }
                            
                            Database.Update(applicantAddressData);
                        }
                    }
                }
                if(updateFCURecs.size()>0){
                    Update updateFCURecs;
                }
                System.debug('createChildFraud--5--'+createChildFraud);

                if(createChildFraud.size()>0){                    
                    System.debug('createChildFraud.size()'+createChildFraud.size());
                    insert createChildFraud;
                    updateDocumentContentId(createChildFraud , newdocmap);
                    CustomNotificationType approvalNotification = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName =: Constants__mdt.getInstance('FCU_NOTIFICATION').value__c LIMIT 1];
                    if(createdOrUpdated){
                        String body_1 = Constants__mdt.getInstance('FCU_NOTIFICATION_BODY_2').value__c;
                        body_1 = body_1.replace('{#var1#}', parentFraudId.Name);
                        if(parentFraudId.External_Vendor__c != null){
                            body_1 = body_1.replace('{#var2#}', parentFraudId.External_Vendor__r.Name);
                        }else{
                            body_1 = body_1.replace('{#var2#}', parentFraudId.Loan_Application__r.Name);
                        }
                        body_1 = body_1.replace('{#var3#}', UserInfo.getName());
    
                        System.debug('samplerId-samplerId'+samplerId);
    
                        Utility.sendNotification(approvalNotification.Id, body_1, Constants__mdt.getInstance('FCU_NOTIFICATION_TITLE_2').value__c, parentFraudId.Id, samplerId);
                    }else{
                        String body_1 = Constants__mdt.getInstance('FCU_NOTIFICATION_BODY_5').value__c;
                        body_1 = body_1.replace('{#var1#}', parentFraudId.Name);
                        if(parentFraudId.External_Vendor__c != null){
                            body_1 = body_1.replace('{#var2#}', parentFraudId.External_Vendor__r.Name);
                        }else{
                            body_1 = body_1.replace('{#var2#}', parentFraudId.Loan_Application__r.Name);
                        }
                        body_1 = body_1.replace('{#var3#}', UserInfo.getName());
                        System.debug('samplerId-samplerId'+samplerId);
    
                        Utility.sendNotification(approvalNotification.Id, body_1, Constants__mdt.getInstance('FCU_NOTIFICATION_TITLE_5').value__c, parentFraudId.Id, samplerId);
                    }

                    List<Document_Master__c> fcuMasterList = [SELECT Id, Type__c, Requirement_At__c, Document_Category__c, Document_Name__c, Mandatory_Non_Mandatory__c FROM Document_Master__c WHERE Type__c = 'FCU' AND Requirement_At__c = 'Field Investigation' ORDER BY Document_Name__c];
                    Map<String, String> documentTypeMaster = new Map<String, String>();
                    Map<String, String> profileTypeMaster = new Map<String, String>();
                    Map<String, String> documentTypeMasterId = new Map<String, String>();
                    Map<String, String> profileTypeMasterId = new Map<String, String>();
                    System.debug('fcuMasterLists'+fcuMasterList.size());
                    System.debug('fcuMasterList'+fcuMasterList);
                    for(Document_Master__c iterMaster : fcuMasterList){
                        if(iterMaster.Document_Category__c == Constants__mdt.getInstance('FCU_RECORD_TYPE_DOCUMENT').value__c){
                            documentTypeMaster.put(iterMaster.Document_Name__c, iterMaster.Mandatory_Non_Mandatory__c);
                            documentTypeMasterId.put(iterMaster.Document_Name__c, iterMaster.Id);
                        }else if(iterMaster.Document_Category__c == Constants__mdt.getInstance('FCU_RECORD_TYPE_PROFILE').value__c){
                            profileTypeMaster.put(iterMaster.Document_Name__c, iterMaster.Mandatory_Non_Mandatory__c);
                            profileTypeMasterId.put(iterMaster.Document_Name__c, iterMaster.Id);
                        }
                    }
    
                    List<Document_Details__c> createUploadChildChecklist = new List<Document_Details__c>();
    
                    if(docIds.keySet().size()>0){
                        List<Application_Verification__c> fcuChildDocId = [SELECT Id from Application_Verification__c WHERE Parent_FCU__c =: parentFraudId.Id AND FCU_check_type__c = 'Document' AND Document_Detail__c IN :docIds.keySet()];
                        for(Application_Verification__c docChildId : fcuChildDocId){
                            for(String iterString : documentTypeMaster.keySet()){
                                Document_Details__c docCheckFraud = new Document_Details__c();
                                docCheckFraud.Name = iterString;
                                docCheckFraud.Application_Verification__c = docChildId.Id;
                                docCheckFraud.Document_Required__c = documentTypeMaster.get(iterString);
                                docCheckFraud.Document_Master__c = documentTypeMasterId.get(iterString);
    
                                createUploadChildChecklist.add(docCheckFraud);
                            }
                        }
                    }
                                   
                        List<Application_Verification__c> fcuChildProfileId = [SELECT Id from Application_Verification__c WHERE Parent_FCU__c =: parentFraudId.Id AND FCU_check_type__c = 'Profile' and Loan_Application__c != null];
                        for(Application_Verification__c docChildId : fcuChildProfileId){
                            for(String iterString : profileTypeMaster.keySet()){
                                Document_Details__c docCheckFraud = new Document_Details__c();
                                docCheckFraud.Name = iterString;
                                docCheckFraud.Application_Verification__c = docChildId.Id;
                                docCheckFraud.Document_Required__c = profileTypeMaster.get(iterString);
                                docCheckFraud.Document_Master__c = profileTypeMasterId.get(iterString);

                                createUploadChildChecklist.add(docCheckFraud);
                            }
                        }
                    

                   

                    System.debug('createUploadChildChecklist -->'+createUploadChildChecklist);
    
                    if(createUploadChildChecklist.size()>0){
                        insert createUploadChildChecklist;
                    }                   
                } 
            }
            //update opp field status
            getFcuStatusAndUpdateLoan(loanId);
            //addOpportunityTeamMemberToLoan(loanId);
            Application_Verification__c appVerification = [
                SELECT Id, OwnerId, IsParent__c, Loan_Application__c 
                FROM Application_Verification__c
                WHERE Loan_Application__c = :loanId
                AND IsParent__c = true
                LIMIT 1
            ];
            Id opportunityId = appVerification.Loan_Application__c;
            utility.addOppTeamMember(opportunityId , appVerification.ownerId,'FCU Admin','Edit');
            return 'Success';
        } catch(Exception exp){
            System.debug('Exception1087'+exp.getMessage());
            System.debug('Exception1088'+exp.getStackTraceString());
            Utility.generateException(exp, Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, Constants__mdt.getInstance('FCU_CLASS_1').value__c);
            return 'Error:Generic';
        }
    }

    /**
     * @description	    :	This updates remarks when sent back
     * @param           :  string , string id
     * @return          :   string
    **/
    @AuraEnabled
    public static String updateSendBackRemark(String data, String recordId){
        String remark = '';
        try{
            String curentDtTime = System.now().format();
            String currentUserName = UserInfo.getFirstName() + ' ' +UserInfo.getLastName();

            remark = currentUserName +' - '+ curentDtTime +' - '+ data;

            Application_Verification__c fraudUpdate = [SELECT Id, Is_Submitted__c, OwnerId, Report_Date__c, Report_Name__c, Parent_FCU__r.Loan_Application__r.Name, Sent_Back_Remark__c FROM Application_Verification__c WHERE Id =: recordId LIMIT 1];
            fraudUpdate.Sent_Back_Remark__c = remark;
            fraudUpdate.Is_Submitted__c = false;
            Database.update(fraudUpdate);

            Application_Verification__c parentFraud = [SELECT Id, Is_Submitted__c, Approval_Status__c FROM Application_Verification__c WHERE Id =: fraudUpdate.Parent_FCU__c LIMIT 1];
            parentFraud.Is_Submitted__c = false;
            parentFraud.Approval_Status__c = Constants__mdt.getInstance('FCU_APPROVAL_SENT_BACK').value__c;
            Database.Update(parentFraud);

            CustomNotificationType approvalNotification = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName =: Constants__mdt.getInstance('FCU_NOTIFICATION').value__c LIMIT 1];
            String body_1 = Constants__mdt.getInstance('FCU_NOTIFICATION_BODY_3').value__c;
            body_1 = body_1.replace('{#var1#}', fraudUpdate.Report_Name__c);
            body_1 = body_1.replace('{#var2#}', fraudUpdate.Parent_FCU__r.Loan_Application__r.Name);
            body_1 = body_1.replace('{#var3#}', UserInfo.getName());

            Utility.sendNotification(approvalNotification.Id, body_1, Constants__mdt.getInstance('FCU_NOTIFICATION_TITLE_3').value__c, parentFraud.Id, fraudUpdate.OwnerId);
        } catch(Exception exp){
            Utility.generateException(exp, Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, Constants__mdt.getInstance('FCU_CLASS_1').value__c);
        }
        return remark;
    }
    
    /**
     * @description	    :	This methods is used to check for disability control
     * @param           :   List of lead Ids.
     * @return          :   boolean
    **/
   @AuraEnabled
    public static Boolean checkVerificationStatusDisability(String recordId){
        Boolean flag = false;
        try{
            String profile = [SELECT Id,Name FROM Profile WHERE Id =: UserInfo.getProfileId() LIMIT 1].Name;
            Application_Verification__c parentFraudStatus = [SELECT Id, Approval_Status__c FROM Application_Verification__c WHERE Id =: recordId LIMIT 1];
            if((profile != Constants__mdt.getInstance('FCU_PROFILE_AGENT').value__c && profile != 'System Administrator') || parentFraudStatus.Approval_Status__c == Constants__mdt.getInstance('FCU_APPROVAL_APPROVED').value__c || parentFraudStatus.Approval_Status__c == Constants__mdt.getInstance('FCU_APPROVAL_INITIATED').value__c){
                flag = true;
            }
        } catch(Exception exp){
            Utility.generateException(exp, Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, Constants__mdt.getInstance('FCU_CLASS_1').value__c);
        }
        return flag;
    }

    /**
     * @description	    :	This method fetches parent details on child records
     * @param           :   List of application verification Ids.
     * @return          :   Wrapper Data
    **/
    @AuraEnabled
    public static ParentDetails fetchParentDetails(String recordId){
        ParentDetails parentWrapper = new ParentDetails();
        try{
            Application_Verification__c parentFraudStatus = [SELECT Id, Report_Name__c, Loan_Application__r.Name, Loan_Application__r.Status__c,Primary_Applicant__c, Co_Applicant_s__c, Sample_Date__c, Report_Date__c, Cluster__c, Product__c, State__c, Branch__r.Name, Stantard_Remark__c, Approval_Status__c, Agents_s_Branch__r.Name, Owner.Name, RecordType.Name,Sampler_Remarks__c FROM Application_Verification__c WHERE Id =: recordId LIMIT 1];
            
            Datetime sampleutcDatetime = Datetime.valueOf(parentFraudStatus.Sample_Date__c);

            if(parentFraudStatus.Report_Date__c != null){
                Datetime reportutcDatetime = Datetime.valueOf(parentFraudStatus.Sample_Date__c);
                parentWrapper.reportdate = reportutcDatetime.format('yyyy-MM-dd HH:mm:ss');
            }            

            if(parentFraudStatus.RecordType.Name == 'FCU'){
                parentWrapper.isProfileRecord = true;
            }
            else{
                parentWrapper.isProfileRecord = false;
            }
            parentWrapper.reportName = parentFraudStatus.Report_Name__c;
            parentWrapper.loanApplicationName = parentFraudStatus.Loan_Application__r.Name;
            parentWrapper.primaryApplicant = parentFraudStatus.Primary_Applicant__c;
            parentWrapper.secondaryApplicant = parentFraudStatus.Co_Applicant_s__c;
            parentWrapper.sampledate = sampleutcDatetime.format('yyyy-MM-dd HH:mm:ss');
            parentWrapper.cluster = parentFraudStatus.Cluster__c;
            parentWrapper.product = parentFraudStatus.Product__c;
            parentWrapper.state = parentFraudStatus.State__c;
            parentWrapper.branchname = parentFraudStatus.Branch__r.Name;
            parentWrapper.samplerremark = parentFraudStatus.Sampler_Remarks__c;
            parentWrapper.approvalremark = parentFraudStatus.Approval_Status__c;
            parentWrapper.agentBranchName = parentFraudStatus.Agents_s_Branch__r.Name;
            parentWrapper.agentName = parentFraudStatus.Owner.Name;
            parentWrapper.status = parentFraudStatus.Loan_Application__r.Status__c;
         
        } catch(Exception exp){
            Utility.generateException(exp, Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, Constants__mdt.getInstance('FCU_CLASS_1').value__c);
        }
        return parentWrapper;
    }
    public class ParentDetails{
        @AuraEnabled public String reportName;
        @AuraEnabled public String loanApplicationName;
        @AuraEnabled public String primaryApplicant;
        @AuraEnabled public String secondaryApplicant;
        @AuraEnabled public String sampledate;
        @AuraEnabled public String reportdate;
        @AuraEnabled public String cluster;
        @AuraEnabled public String product;
        @AuraEnabled public String state;
        @AuraEnabled public String branchname;
        @AuraEnabled public String samplerremark;
        @AuraEnabled public String approvalremark;
        @AuraEnabled public String agentBranchName;
        @AuraEnabled public String agentName;
        @AuraEnabled public Boolean isProfileRecord;
        @AuraEnabled public String status;
    }

    /**
     * @description	    :	Method that fetchs pending intiation status for documents and profile
     * @param           :   FCU Parent record Id
     * @return          :   Wrapper data
    **/
    @AuraEnabled
    public static InitiatedPending getPendingInitiatedStatus(Id recordId) {
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        InitiatedPending initiatedpendingWrapper = new InitiatedPending();

        Integer pendingProfile = 0;
        Integer initiatedProfile = 0;

        Integer pendingDoc = 0;
        Integer initiatedDoc = 0;

        try{
            List<Document_Details__c> allDoc =new  List <Document_Details__c>();
            List<Applicant_Address__c> allAddr= new List<Applicant_Address__c>();
            if(sObjName!='Vendor__c'){
                allDoc= [SELECT Id, Name, Content_Document_Id__c, FCU_Initiated__c, Screening_Status__c, Owner.Name, Applicant__c, Applicant__r.Name, Requirement_Level__c
                                                        FROM Document_Details__c 
                                                        WHERE Loan_Application__c = :recordId 
                                                        AND Content_Document_Id__c != NULL AND (Screening_Status__c = 'Added to sampling queue' or Screening_Status__c = 'Recommended For FCU' or Screening_Status__c = 'Sent Back') AND FCU_Initiated__c = false
                                                        ORDER BY CreatedDate DESC
                                                    ];

               allAddr= [SELECT Id, Screening_Status__c, FCU_Initiated__c , Applicant__r.Loan_Application__c FROM Applicant_Address__c WHERE (Screening_Status__c = 'Added to sampling queue' or Screening_Status__c = 'Recommended For FCU' or Screening_Status__c = 'Sent Back') AND Applicant__r.Loan_Application__c =: recordId AND FCU_Initiated__c = false];
            }
            
            initiatedpendingWrapper.initiated = allDoc.size() + allAddr.size() +0;
        }catch(Exception exp){
            Utility.generateException(exp, Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, Constants__mdt.getInstance('FCU_CLASS_1').value__c);
        }
        
        return initiatedpendingWrapper;
    }
    public class InitiatedPending{
        @AuraEnabled public Integer pending;
        @AuraEnabled public Integer initiated;
    }

    /**
     * @description	    :	Method that delets new added docs
     * @param           :   Applicatio Verification id
     * @return          :   boolean
    **/
    @AuraEnabled
    public static Boolean deleteNewChecklist(Id recordId){
    Boolean flag = false;
    try {
        // Query related ContentDocumentLinks linked to this record
        List<ContentDocumentLink> cdlList = [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :recordId
        ];

        // Collect ContentDocument Ids
        Set<Id> contentDocIds = new Set<Id>();
        for(ContentDocumentLink cdl : cdlList){
            contentDocIds.add(cdl.ContentDocumentId);
        }

        // Delete ContentDocuments (this deletes associated ContentVersions as well)
        if(!contentDocIds.isEmpty()){
            List<ContentDocument> docsToDelete = [
                SELECT Id 
                FROM ContentDocument 
                WHERE Id IN :contentDocIds
            ];
            delete docsToDelete;
        }

        // Now delete the parent Document_Details__c record
        delete [SELECT Id FROM Document_Details__c WHERE Id = :recordId LIMIT 1];

        flag = true;
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
    return flag;
}


    @AuraEnabled
    public static boolean getParentRecordRelatedObject(Id recordId){
        try {
            Boolean flag=false;
            List<Application_Verification__c> fcuList=[Select id from Application_Verification__c where   Loan_Application__c=null and id=:recordId];
            if(fcuList.size()>0){
                flag=true;
            }
            return flag;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * @description	    :	method that checks if document is recommended and not allowed to be removed from queue
     * @param           :   map , map , map
     * @return          :   boolean
    **/
    @AuraEnabled
    public static boolean removeFromSamplingQueue(Map<String, String> docIds, Map<String, String> profileIds, Map<String, String> applicationCollateralIds){
       try {
        system.debug('Checking profile ids-->'+profileIds);
        String profile = Utility.getCurrentUserProfileName1();
            boolean notAllowedToRemoveFromQueue=false;
            List<Document_Details__c> docList = [Select Id, Screening_Status__c from Document_Details__c where id in: docIds.keySet()];
            List<Applicant_Address__c> addrList = [Select Id, Screening_Status__c from Applicant_Address__c where (id in: profileIds.keySet() or id in: applicationCollateralIds.keySet())];
            if(docList.size()>0){
                for(Document_Details__c doc : docList){
                    if(doc.Screening_Status__c=='Recommended For FCU' && profile != 'Credit Manager'){
                        notAllowedToRemoveFromQueue=true;
                    }
                    doc.Screening_Status__c = 'Screened';
                    
                }
              
               
            }
            if(addrList.size()>0){
                for(Applicant_Address__c addr : addrList){
                    if(addr.Screening_Status__c=='Recommended For FCU'){
                    notAllowedToRemoveFromQueue=true;
                }
                    addr.Screening_Status__c = 'Screened';
                }
                // Update addrList;
            }

            if(!notAllowedToRemoveFromQueue && addrList.size()>0){
                Update addrList;
            }
            if(!notAllowedToRemoveFromQueue && docList.size()>0){
                Update docList;
            }
            return notAllowedToRemoveFromQueue;
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description	    :	Method that checks if current record is parent
     * @param           :   Application Verification record id
     * @return          :   boolean
    **/
    @AuraEnabled
    public static Boolean checkIfParentRec(String recId){
        system.debug('record id is-->'+recID);
        Boolean isParent = false;
        try {
            List<Application_Verification__c> fclist = [Select Id, Parent_FCU__c from Application_Verification__c where id =: recId and Parent_FCU__c = null];
            system.debug('the fcu list is-->'+fclist);
            if(fclist.size()>0){
                isParent = true;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return isParent;
    }
    
    @AuraEnabled
    public static void updateNotAcceptRec(String recId, String remarks){
        try {
            List<Application_Verification__c> fcuList = [Select id,Admin_s_Remarks__c, CreatedById, Document_Details__c, Address__c,External_Vendor__c, Name, Any_Remarks_Reasons__c from Application_Verification__c where id =: recId];
            fcuList[0].Stage__c = 'Not Accepted By Admin';
            if(fcuList[0].Any_Remarks_Reasons__c != null){
                fcuList[0].Any_Remarks_Reasons__c = fcuList[0].Any_Remarks_Reasons__c+'\n'+System.now()+'-'+UserInfo.getName()+'-'+remarks;
            }
            else{
                fcuList[0].Any_Remarks_Reasons__c = System.now()+'-'+UserInfo.getName()+'-'+remarks;
            }
            fcuList[0].Admin_s_Remarks__c = remarks +'\n'+System.now()+'-'+UserInfo.getName();
            Update fcuList;
            if(fcuList[0].Document_Details__c != null){
                List<Document_Details__c> docList =[Select Id, Remarks__c from Document_Details__c where id =: fcuList[0].Document_Details__c];
                Document_Details__c doc = new Document_Details__c();
                doc.Id = fcuList[0].Document_Details__c;
                doc.FCU_Initiated__c = false;
                if(docList[0].Remarks__c != null){
                    doc.Remarks__c = docList[0].Remarks__c+'\n'+System.now()+'-'+UserInfo.getName()+'-'+remarks;
                }
                else{
                    doc.Remarks__c = System.now()+'-'+UserInfo.getName()+'-'+remarks;
                }
                Update doc;
            }
            else if(fcuList[0].Address__c != null){
                List<Applicant_Address__c> addrList =[Select Id, Remarks__c from Applicant_Address__c where id =: fcuList[0].Address__c];
                Applicant_Address__c addr = new Applicant_Address__c();
                addr.Id = fcuList[0].Address__c;
                addr.FCU_Initiated__c = false;
                if(addrList[0].Remarks__c != null){
                    addr.Remarks__c = addrList[0].Remarks__c+'\n'+System.now()+'-'+UserInfo.getName()+'-'+remarks;
                }
                else{
                    addr.Remarks__c = System.now()+'-'+UserInfo.getName()+'-'+remarks;
                }
                Update addr;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean checkIfIsVendorRelated (Id fcuId) {
        Application_Verification__c fcu = [SELECT Loan_Application__c FROM Application_Verification__c WHERE Id = :fcuId LIMIT 1];
        return fcu.Loan_Application__c == null;
    }
    
    @AuraEnabled
    public static string getObjectName(Id recordId){
        try {
            String sObjName = recordId.getSObjectType().getDescribe().getName();
            return sObjName;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
public static List<UserWithAccount> getUsersByProfile(String recordId) {
    try {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        Map<Id, Id> userToAccountMap = new Map<Id, Id>();

        
        Map<Id, Account> accountsMap = new Map<Id, Account>();
        List<Account> accountsWithMatchingPincode = [
            SELECT Id, Name 
            FROM Account 
            WHERE Partner_Type__c = 'FCU'
        ];
        for (Account acc : accountsWithMatchingPincode) {
            accountIds.add(acc.Id);
            accountsMap.put(acc.Id, acc); 
        }

 
        List<AccountTeamMember> teamMembers = [
            SELECT UserId, AccountId 
            FROM AccountTeamMember 
            WHERE TeamMemberRole = 'FCU Admin' AND AccountId IN :accountIds
        ];
        for (AccountTeamMember atm : teamMembers) {
            userIds.add(atm.UserId);
            userToAccountMap.put(atm.UserId, atm.AccountId);
        }

      
        Map<Id, User> usersMap = new Map<Id, User>([
            SELECT Id, Name, Employee_ID__c 
            FROM User 
            WHERE Id IN :userIds
        ]);

        
        List<UserWithAccount> result = new List<UserWithAccount>();
        for (Id userId : userIds) {
            User user = usersMap.get(userId);
            Id accId = userToAccountMap.get(userId);
            Account acc = accountsMap.get(accId);

            UserWithAccount uwa = new UserWithAccount();
            uwa.userId = user.Id;
            uwa.name = user.Name;
            uwa.employeeId = user.Employee_ID__c;
            uwa.accountName = acc != null ? acc.Name : null;

            result.add(uwa);
        }

        return result;

    } catch (Exception e) {
        throw new AuraHandledException('Error fetching user data: ' + e.getMessage());
    }
}
public class UserWithAccount {
    @AuraEnabled public String userId;
    @AuraEnabled public String name;
    @AuraEnabled public String employeeId;
    @AuraEnabled public String accountName;
}

    
    /**
     * @description	    :	Method that creates docuemnt checklist records to be viewd based upon type
     * @param           :   loan id
     * @return          :   wrapper data
    **/
	@AuraEnabled
    public static List<CustomerDocumentWrapper> getDocChecklistRecords(String loanId){
        List<CustomerDocumentWrapper> custDetails = new List<CustomerDocumentWrapper>();
       try {
            
            Map<Id,CustomerDocumentWrapper> customerToWrapperMap = new Map<Id,CustomerDocumentWrapper>();
            List<Document_Details__c> docList = [Select Id, Content_Document_Id__c, Applicant__c, Applicant__r.First_Name__c, Applicant__r.Last_Name__c,Applicant__r.Applicant_Type__c, Document_Details__c 
                                                    from Document_Details__c where Loan_Application__c =: loanId and Content_Document_Id__c != null and Applicant__c != null];
            Set<Id> contentDocIds = new Set<Id> ();

            for(Document_Details__c doc : docList){
                contentDocIds.add(doc.Content_Document_Id__c);
            } 
            Map<Id,ContentDocument> idVsContentDocumentRecord = new Map<Id,ContentDocument>([Select Id,FileExtension From ContentDocument Where Id IN:contentDocIds]);                 
            for(Document_Details__c doc : docList){
                if(customerToWrapperMap.containsKey(doc.Applicant__c)){
                    CustomerDocumentWrapper custWrap = customerToWrapperMap.get(doc.Applicant__c);
                    custWrap.name = doc.Applicant__r.First_Name__c+' '+(doc.Applicant__r.Last_Name__c != null ? doc.Applicant__r.Last_Name__c : '' ) +' ( '+ doc.Applicant__r.Applicant_Type__c+' )';
                    DocumentWrapper docWrap = new DocumentWrapper();
                    docWrap.docId = doc.Id;
                    docWrap.docUrl = '/sfc/servlet.shepherd/document/download/'+doc.Content_Document_Id__c;
                    docWrap.fileType = idVsContentDocumentRecord!=null && idVsContentDocumentRecord.containsKey(doc.Content_Document_Id__c) ? idVsContentDocumentRecord.get(doc.Content_Document_Id__c).FileExtension :'';
                    if(docWrap.fileType=='pdf'){
                        docWrap.isPdf = true;
                        docWrap.isImg = false;
                    }else{
                        docWrap.isImg = true;
                        docWrap.isPdf = false;
                    }

                    if(doc.Document_Details__c == 'KYC'){
                        custWrap.kycDocList.add(docWrap);
                    }
                    else if(doc.Document_Details__c == 'Income Proof'){
                        custWrap.incomeDocList.add(docWrap);
                    }
                    else if(doc.Document_Details__c == 'Bank Statement'){
                        custWrap.financeDocList.add(docWrap);
                    }
                    else{
                        custWrap.otherDocList.add(docWrap);
                    }
                }
                else{
                    CustomerDocumentWrapper custWrap = new CustomerDocumentWrapper();
                    custWrap.incomeDocList = new List<DocumentWrapper>();
                    custWrap.kycDocList = new List<DocumentWrapper>();
                    custWrap.financeDocList = new List<DocumentWrapper>();
                    custWrap.otherDocList = new List<DocumentWrapper>();
                    custWrap.name = doc.Applicant__r.First_Name__c+' '+(doc.Applicant__r.Last_Name__c != null ? doc.Applicant__r.Last_Name__c : '' )+' ( '+ doc.Applicant__r.Applicant_Type__c+' )';
                    DocumentWrapper docWrap = new DocumentWrapper();
                    docWrap.docId = doc.Id;
                    docWrap.docUrl = '/sfc/servlet.shepherd/document/download/'+doc.Content_Document_Id__c;
                    docWrap.fileType = idVsContentDocumentRecord!=null && idVsContentDocumentRecord.containsKey(doc.Content_Document_Id__c) ? idVsContentDocumentRecord.get(doc.Content_Document_Id__c).FileExtension :'';
                    if(docWrap.fileType=='pdf'){
                        docWrap.isPdf = true;
                        docWrap.isImg = false;
                    }else{
                        docWrap.isImg = true;
                        docWrap.isPdf = false;
                    }
                    if(doc.Document_Details__c == 'KYC'){
                        custWrap.kycDocList.add(docWrap);
                    }
                    else if(doc.Document_Details__c == 'Income Proof'){
                        custWrap.incomeDocList.add(docWrap);
                    }
                    else if(doc.Document_Details__c == 'Bank Statement'){
                        custWrap.financeDocList.add(docWrap);
                    }
                    else{
                        custWrap.otherDocList.add(docWrap);
                    }
                    customerToWrapperMap.put(doc.Applicant__c,custWrap);
                }
            }
            System.debug('customerToWrapperMap=:'+customerToWrapperMap.values());
            custDetails.addAll(customerToWrapperMap.values());
            return custDetails;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }    
    public class CustomerDocumentWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public List<DocumentWrapper> incomeDocList;
        @AuraEnabled public List<DocumentWrapper> kycDocList;
        @AuraEnabled public List<DocumentWrapper> financeDocList;
        @AuraEnabled public List<DocumentWrapper> otherDocList;
    }

    public class CombinedCustomerDocumentWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public List<DocumentWrapper> docList;
    }

    public class DocumentWrapper{
        @AuraEnabled public String docId;
        @AuraEnabled public String docUrl;
        @AuraEnabled public String fileType;
        @AuraEnabled public Boolean isPdf;
        @AuraEnabled public Boolean isImg;


    }

    /**
     * @description	    :	Method that gets the user profile names based on PS.
     * @param           :   
     * @return          :   string
    **/
    // @AuraEnabled
    // public static String getCurrentUserProfileName(){
    //     String profileName = '';
    //     Id profileId=userinfo.getProfileId();
    //     String profileNameStr=[Select Id,Name from Profile where Id=:profileId].Name;
    //     if(profileNameStr == 'System Administrator') {
    //         profileName = 'admin';
    //         return 'Admin';
    //     }
    //     for(PermissionSetAssignment iter :[SELECT Id, PermissionSet.Name, PermissionSet.ProfileId, PermissionSet.Profile.Name, AssigneeId, Assignee.Name FROM PermissionSetAssignment WHERE Assignee.id=: UserInfo.getUserId()]){
    //         if(iter.PermissionSet.Name == 'PS_FCU_Sampler') {
    //             profileName = 'Sampler';
    //             return 'Sampler';
    //         }
    //         if(iter.PermissionSet.Name == 'PS_FCU_Admin') {
    //             profileName = 'FCU Admin';
    //             return 'FCU Admin';
    //         }
    //         if(iter.PermissionSet.Name == 'PS_FCU_Executive') {
    //             profileName = 'FCU Executive';
    //             return 'FCU Executive';
    //         }
    //         if(iter.PermissionSet.Name == 'PS_Credit_Manager') {
    //             profileName = 'Credit Manager';
    //             return 'Credit Manager';
    //         }
    //        if(iter.PermissionSet.Name == 'PS FI Executive') {
    //             profileName = 'FI';
    //             return 'FI';
    //         }
    //     }
    //     return profileName;
    // } 
    
/**
     * @description	    :	Method that creates a placeholder to upload extra images
     * @param           :   Application Verification id
     * @return          :   boolean
    **/
    @AuraEnabled
    public static Boolean createNewChecklist(Id recordId){
        system.debug('record id -->'+recordId);
        Boolean flag = false;
        try {
            List<Document_Details__c> presentFCU = [SELECT Id, Name , Document_Master__c,Application_Verification__r.FCU_Check_type__c FROM Document_Details__c WHERE Application_Verification__c =: recordId];
            if(presentFCU.size()>0){
                Integer lastNumber = presentFCU.size();
                
                Document_Details__c newDoc = new Document_Details__c();
                newDoc.Is_New_Created__c = true;
                newDoc.Name = 'Image ' + String.valueOf(lastNumber+1);
                newDoc.Application_Verification__c = recordId;

                insert newDoc;

                flag = true;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return flag;
    }
    @AuraEnabled
    public static ImageResposeWrap getContentVersion(Id recordId){
        String versiondata = '';
         ContentVersion objDoc = [SELECT id,VersionData,title, fileExtension 
                                 FROM ContentVersion 
                                 WHERE ContentDocumentId = :recordId];
        versiondata = EncodingUtil.base64Encode(objDoc.VersionData);
        ImageResposeWrap imgResObj = new ImageResposeWrap();
        imgResObj.versionData = EncodingUtil.base64Encode(objDoc.VersionData);
        imgResObj.ImageType = objDoc.FileExtension;
        //versiondata = objDoc.VersionData;
        return imgResObj;
    }
    public class ImageResposeWrap {
        @AuraEnabled public String versionData;
        @AuraEnabled public String ImageType;
    }
    /**
     * @description	    :	Method to control visibility of report generation
     * @param           :   Application Verification id
     * @return          :   boolean
    **/
    @AuraEnabled
    public static Boolean checkIfReportButtonVisible(Id recordId){
        Boolean shoeButton = false;
        for(Application_Verification__c iterRec :[SELECT id, Verification_Status__c, stage__c FROM Application_Verification__c 
                                                             WHERE Parent_FCU__c = :recordId] ) {
                                                               if (iterRec.Stage__c == 'Accepted') {
                                                                    shoeButton = true;  
                                                                    return shoeButton;
                                                                }
                                                            } 
         return shoeButton;
        
    }
  
   
    /**
     * @description	    :	Method that fetches the hunter details to display in sampler screen.
     * @param           :   loan id
     * @return          :   string
    **/
    @AuraEnabled
    public static string gethunterrecord(id recordId){
        system.debug('recordid'+recordId);
        string recordtypeid = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' AND Name = 'Hunter Verification' LIMIT 1].id;
        system.debug('recordtypei'+recordtypeid);
        try {
            List<Application_Verification__c> hunterlist = [SELECT id ,name, Hunter_Decision__c, Hunter_Match__c, Sampler_s_Decision__c,Sampler_Name__c, Hunter_Initiated_By__c From Application_Verification__c where Loan_Application__c = :recordId and RecordTypeId = :recordtypeid  LIMIT 1];
            system.debug('hunterlist'+hunterlist);
            if(hunterlist.size() == 0){
                return null;
            }
            Application_Verification__c record = hunterList[0];
            String result = record.Id + ',' + record.Hunter_Decision__c + ',' + record.Hunter_Match__c + ',' + (record.Sampler_s_Decision__c == null ? '' : record.Sampler_s_Decision__c);
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * @description	    :	Method to share the docs uploaded manually
     * @param           :   fcu list , mpa of docs
     * @return          :   
    **/
    @AuraEnabled
    public static void updateDocumentContentId(List<Application_Verification__c> fcuList, Map<String, String> documentMap) {
    try {
        system.debug('are we in the new mwthod?');
        List<Application_Verification__c> childfculist = [SELECT Id, Document_Detail__c, Document_Detail__r.Content_Document_Id__c
                                                    FROM Application_Verification__c
                                                    WHERE FCU_Check_type__c = 'Document' AND Id IN :fcuList];

        List<Document_Details__c> newDocumentDetails = new List<Document_Details__c>();

        for (Application_Verification__c childfcu : childfculist) {
            String documentDetailId = childfcu.Document_Detail__c;

            if (!documentMap.isEmpty() && documentMap.containsKey(documentDetailId)) {
                    String documentContentId = documentMap.get(documentDetailId);
                    Document_Details__c newDocDetail = new Document_Details__c();
                    newDocDetail.Content_Document_Id__c = documentContentId;
                    newDocDetail.Application_Verification__c = childfcu.Id; 
                    newDocDetail.name = 'Document Uploaded By Sampler';
                    newDocumentDetails.add(newDocDetail);
                } 
            }
        

        if (!newDocumentDetails.isEmpty()) {
            insert newDocumentDetails;
        }
        List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
        
        
        List<ContentDocumentLink> cdList= new List<ContentDocumentLink>();
        //List<Document_Details__c> doc=[Select id,Content_Document_Id__c,Application_Verification__c from Document_Details__c where id IN :newDocumentDetails and Content_Document_Id__c!=null]; // rather than query use same list
        for(Document_Details__c d: newDocumentDetails){
            Utility.SharingInfo si = new Utility.SharingInfo();
            si.objectName = 'Document_Details__c';
            si.userOrGroupId = Constants__mdt.getInstance('GROUP_ID').value__c;
            si.recordToShareId = d.Id;
            si.sharingAccess = Constants.EDIT_ACCESS;
            sharingList.add(si);
            Utility.SharingInfo si1 = new Utility.SharingInfo();
            si1.objectName = 'Document_Details__c';
            si1.userOrGroupId = Constants__mdt.getInstance('Partner_User').value__c;
            si1.recordToShareId = d.Id;
            si1.sharingAccess = Constants.EDIT_ACCESS;
            sharingList.add(si1);
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = d.Id;
            cdl.ContentDocumentId = d.Content_Document_Id__c;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            cdList.add(cdl);
        }
        Utility.createShareRecord(JSON.serialize(sharingList));
        insert cdList;

    } catch (Exception e) {
    	System.debug('ExceptionEx2330'+e.getMessage());
        throw new AuraHandledException(e.getMessage());
    }
} 

    @AuraEnabled
    public static List<FSC_Document_Category_Tabs__mdt> getMetaDataVales(){
        List<FSC_Document_Category_Tabs__mdt> documentCategoryMetadata = new List<FSC_Document_Category_Tabs__mdt>();
        documentCategoryMetadata = [SELECT Label, DeveloperName,Sequence__c, Object_API_Name__c, Field_API_Name__c, Field_Value__c FROM FSC_Document_Category_Tabs__mdt ORDER BY Sequence__c ASC NULLS LAST];
        return documentCategoryMetadata;
    }

    @AuraEnabled
    public static List<CombinedCustomerDocumentWrapper> getDataRecords(String loanId,String documentCategory){
        List<CombinedCustomerDocumentWrapper> custDetails = new List<CombinedCustomerDocumentWrapper>();
        Map<Id,CombinedCustomerDocumentWrapper> customerToWrapperMap = new Map<Id,CombinedCustomerDocumentWrapper>();
        List<Document_Details__c> docList = new List<Document_Details__c> ();
        Set<String> documentTypes = new Set<String>();
        List<FSC_Document_Category_Tabs__mdt> documentCategoryMetadata = new List<FSC_Document_Category_Tabs__mdt>();
        documentCategoryMetadata = [SELECT Label, DeveloperName,Sequence__c, Object_API_Name__c, Field_API_Name__c, Field_Value__c FROM FSC_Document_Category_Tabs__mdt];
        for(FSC_Document_Category_Tabs__mdt documentCategoryRecord: documentCategoryMetadata){
            if(documentCategoryRecord.Field_Value__c != null){
               documentTypes.add(documentCategoryRecord.Field_Value__c);
            }
        }
        if(documentCategory=='Other'){
            docList = [Select Id, Content_Document_Id__c, Applicant__c, Applicant__r.First_Name__c, Applicant__r.Last_Name__c,Applicant__r.Applicant_Type__c, Document_Details__c,Document_Master__r.Document_Category__c 
            from Document_Details__c where Loan_Application__c =: loanId and Content_Document_Id__c != null and Applicant__c != null AND Document_Master__r.Document_Category__c NOT IN: documentTypes ];
        }else{
            docList = [Select Id, Content_Document_Id__c, Applicant__c, Applicant__r.First_Name__c, Applicant__r.Last_Name__c,Applicant__r.Applicant_Type__c, Document_Details__c 
            from Document_Details__c where Loan_Application__c =: loanId and Content_Document_Id__c != null and Applicant__c != null AND Document_Master__r.Document_Category__c =:documentCategory];
        }
        
        
        Set<Id> contentDocIds = new Set<Id> ();
        for(Document_Details__c doc : docList){
            contentDocIds.add(doc.Content_Document_Id__c);
        }
        Map<Id,ContentDocument> idVsContentDocumentRecord = new Map<Id,ContentDocument>([Select Id,FileExtension From ContentDocument Where Id IN:contentDocIds]);
        for(Document_Details__c doc : docList){
               if(customerToWrapperMap.containsKey(doc.Applicant__c)){
                CombinedCustomerDocumentWrapper custWrap = customerToWrapperMap.get(doc.Applicant__c);
                custWrap.name = doc.Applicant__r.First_Name__c+' '+(doc.Applicant__r.Last_Name__c != null ? doc.Applicant__r.Last_Name__c : '' )+' ( '+ doc.Applicant__r.Applicant_Type__c+' )';
                DocumentWrapper docWrap = new DocumentWrapper();
                docWrap.docId = doc.Id;
                docWrap.docUrl = '/sfc/servlet.shepherd/document/download/'+doc.Content_Document_Id__c;
                docWrap.fileType = idVsContentDocumentRecord!=null && idVsContentDocumentRecord.containsKey(doc.Content_Document_Id__c) ? idVsContentDocumentRecord.get(doc.Content_Document_Id__c).FileExtension :'';
                if(docWrap.fileType=='pdf'){
                    docWrap.isPdf = true;
                    docWrap.isImg = false;
                }else{
                    docWrap.isImg = true;
                    docWrap.isPdf = false;
                }
                custWrap.docList.add(docWrap);

               }else{
                CombinedCustomerDocumentWrapper custWrap = new CombinedCustomerDocumentWrapper();
                custWrap.docList = new List<DocumentWrapper>();
                custWrap.name = doc.Applicant__r.First_Name__c+' '+(doc.Applicant__r.Last_Name__c != null ? doc.Applicant__r.Last_Name__c : '' )+' ( '+ doc.Applicant__r.Applicant_Type__c+' )';
                DocumentWrapper docWrap = new DocumentWrapper();
                docWrap.docId = doc.Id;
                docWrap.docUrl = '/sfc/servlet.shepherd/document/download/'+doc.Content_Document_Id__c;
                docWrap.fileType = idVsContentDocumentRecord!=null && idVsContentDocumentRecord.containsKey(doc.Content_Document_Id__c) ? idVsContentDocumentRecord.get(doc.Content_Document_Id__c).FileExtension :'';
                if(docWrap.fileType=='pdf'){
                    docWrap.isPdf = true;
                    docWrap.isImg = false;
                }else{
                    docWrap.isImg = true;
                    docWrap.isPdf = false;
                }
                custWrap.docList.add(docWrap);
                customerToWrapperMap.put(doc.Applicant__c,custWrap);
               }
        }
        custDetails.addAll(customerToWrapperMap.values());
        return custDetails;
    }

    @AuraEnabled(cacheable=true)
     public static ContentDocument getContentDocumentById(Id documentId) {
         return [SELECT FileType FROM ContentDocument WHERE Id = :documentId LIMIT 1];
        }
    @AuraEnabled
    public static Document_Details__c  insertDocumentDetail(String contentDocumentId, String dataId) {
        try {
            // Create the new Document Detail record
            Document_Details__c docDetail = new Document_Details__c();
            docDetail.Content_Document_Id__c = contentDocumentId;
            docDetail.Document_Details_Lookup__c = dataId;
            docDetail.name = 'Document Uploaded By Sampler';
            // Insert the record
            insert docDetail;

            ContentDocumentLink contentDocLink = new ContentDocumentLink();
            contentDocLink.ContentDocumentId = contentDocumentId;
            contentDocLink.LinkedEntityId = docDetail.id;
            contentDocLink.ShareType = 'V'; // V for Viewer access
            contentDocLink.Visibility = 'AllUsers'; // Making it visible to all users
            insert contentDocLink;
            
            return docDetail;
        } catch (Exception e) {
            throw new AuraHandledException('Error inserting Document Detail: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static List<Document_Details__c> getStoredDocuments(String recordId) {
        return [SELECT Id, Content_Document_Id__c, Document_Details_Lookup__c ,Name
                FROM Document_Details__c 
                WHERE Document_Details_Lookup__c = : recordId AND Name = 'Document Uploaded By Sampler' LIMIT 1];
    }
        public static void addOpportunityTeamMemberToLoan(Id loanId) {
            Application_Verification__c appVerification = [
                SELECT Id, OwnerId, IsParent__c, Loan_Application__c 
                FROM Application_Verification__c
                WHERE Loan_Application__c = :loanId
                AND IsParent__c = true
                LIMIT 1
            ];
            
            // Step 2: Get the Opportunity related to the Application Verification record
            Id opportunityId = appVerification.Loan_Application__c;
            if(opportunityId != null) {
                
                // Step 3: Add the OwnerId from Application Verification as an OpportunityTeamMember
                OpportunityTeamMember teamMember = new OpportunityTeamMember();
                teamMember.OpportunityId = opportunityId;
                teamMember.UserId = appVerification.OwnerId;
                teamMember.TeamMemberRole = 'FCU Admin'; 
    
        }  
    }
       @AuraEnabled
       public static Boolean areAllDocumentsFCUComplete(Id loanAppId) {
        if (loanAppId == null) return false;

        opportunity loan = [SELECT Id, FCU_Status__c,Overall_FCU_Verification__c, Product__c FROM opportunity WHERE Id = :loanAppId LIMIT 1];
        Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('oppId', loanAppId);
        Utility_V1.ProductWrapper productWrapper = Utility_V1.getProductDetails(inputMap);
        Boolean isHlRelated = (productWrapper.loanProduct == 'Home Loan');
        List<Document_Details__c> docs = new List<Document_Details__c>();
        if (isHlRelated){
            docs = [SELECT id,Name,Applicant__c,DDE_Status__c,Applicant__r.Applicant_Name__c,Content_Document_Id__c,Document_Master__c,
            Verification_Status__c,Remarks__c,Screening_Status__c ,Owner.Name,Document_Master__r.Document_Category__c,Requirement_Level__c,FCU_Initiated__c FROM Document_Details__c WHERE Loan_Application__c =:loanAppId AND
            Content_Document_Id__c != null AND Requirement_Level__c != null  AND Active__c = true AND Eligible_For_FCU__c = true AND Consider_for_Loan_Application__c = true];
        }else{
            docs = [SELECT id,Name,Applicant__c,DDE_Status__c,Applicant__r.Applicant_Name__c,Content_Document_Id__c,Document_Master__c,
            Verification_Status__c,Remarks__c,Screening_Status__c ,Owner.Name,Document_Master__r.Document_Category__c,Requirement_Level__c,FCU_Initiated__c FROM Document_Details__c WHERE Loan_Application__c =:loanAppId AND
            Content_Document_Id__c != null AND Requirement_Level__c != null  AND Active__c = true AND Eligible_For_FCU__c = true AND Consider_for_Loan_Application__c = true];
        }
        Set<String> conDocIds = new Set<String>();
            for (Document_Details__c iterDocs : docs) {
                conDocIds.add(iterDocs.Content_Document_Id__c);
            }
        Map<String, ContentVersion> contentDocIdToRecordMap = new Map<String, ContentVersion>();
            if (!conDocIds.isEmpty()) {
                for (ContentVersion iterConVer : [
                    SELECT Id, ContentDocumentId, FileExtension
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :conDocIds
                    AND FileExtension IN ('pdf', 'PDF', 'jpg', 'png', 'jpeg','zip')
                    ORDER BY CreatedDate DESC
                ]) {
                    if (!contentDocIdToRecordMap.containsKey(iterConVer.ContentDocumentId)) {
                        contentDocIdToRecordMap.put(iterConVer.ContentDocumentId, iterConVer);
                    }
                }
            }

        for (Document_Details__c doc : docs) {
               if(contentDocIdToRecordMap.containsKey(doc.Content_Document_Id__c)){
            if (doc.Screening_Status__c != 'FCU Completed' && doc.Screening_Status__c != 'Screened') {
                return false; // Found one that's not complete
                   }
            }
        }
        if (String.isBlank(loan.Overall_FCU_Verification__c)) {
            loan.Overall_FCU_Verification__c = 'Positive';
            update loan;
        }
        return true; // All are 'FCU Complete'
    }
    @AuraEnabled
    public static void getFcuStatusAndUpdateLoan(Id loanId) {      
        Opportunity loanRecord = [SELECT Id, FCU_Status__c,StageName, Product__c FROM Opportunity WHERE Id = :loanId LIMIT 1];
        
        List<Document_Details__c> documents = new List<Document_Details__c>();
        Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('oppId', loanId);
        Utility_V1.ProductWrapper productWrapper = Utility_V1.getProductDetails(inputMap);
        Boolean isHlRelated = (productWrapper.loanProduct == 'Home Loan');
        if (isHlRelated){
            documents = [SELECT id,Name,Applicant__c,DDE_Status__c,Applicant__r.Applicant_Name__c,Content_Document_Id__c,Document_Master__c,
            Verification_Status__c,Remarks__c,Screening_Status__c ,Owner.Name,Document_Master__r.Document_Category__c,Requirement_Level__c,FCU_Initiated__c FROM Document_Details__c WHERE Loan_Application__c =:loanId AND
            Content_Document_Id__c != null AND Requirement_Level__c != null  AND Active__c = true AND Eligible_For_FCU__c = true AND Consider_for_Loan_Application__c = true];
        }else{
            documents = [SELECT id,Name,Applicant__c,DDE_Status__c,Applicant__r.Applicant_Name__c,Content_Document_Id__c,Document_Master__c,
            Verification_Status__c,Remarks__c,Screening_Status__c ,Owner.Name,Document_Master__r.Document_Category__c,Requirement_Level__c,FCU_Initiated__c FROM Document_Details__c WHERE Loan_Application__c =:loanId AND
            Content_Document_Id__c != null AND Requirement_Level__c != null  AND Active__c = true AND Eligible_For_FCU__c = true ];
        }
        String finalStatus = null;
        Set<String> conDocIds = new Set<String>();
        for (Document_Details__c iterDocs : documents) {
            conDocIds.add(iterDocs.Content_Document_Id__c);
        }
        Map<String, ContentVersion> contentDocIdToRecordMap = new Map<String, ContentVersion>();
        if (!conDocIds.isEmpty()) {
            for (ContentVersion iterConVer : [SELECT Id, ContentDocumentId, FileExtension FROM ContentVersion WHERE ContentDocumentId IN :conDocIds AND FileExtension 
            IN ('pdf', 'PDF', 'jpg', 'png', 'jpeg','zip') ORDER BY CreatedDate DESC]) {
                if (!contentDocIdToRecordMap.containsKey(iterConVer.ContentDocumentId)) {
                    contentDocIdToRecordMap.put(iterConVer.ContentDocumentId, iterConVer);
                }
            }
        }
        // Priority 1 check
        for (Document_Details__c doc : documents) {
            if(contentDocIdToRecordMap.containsKey(doc.Content_Document_Id__c)){
                if (doc.Screening_Status__c == 'Added to sampling queue') {
                    finalStatus = 'Sampled';
                    break; // Highest priority found
                }
            }
        }
        // Priority 2 check - only if no priority 1 found
        if (finalStatus == null) {
            for (Document_Details__c doc : documents) {
                if(contentDocIdToRecordMap.containsKey(doc.Content_Document_Id__c)){
                    if (doc.Screening_Status__c == 'On Hold') {
                        finalStatus = 'On Hold';
                        break;
                    }
                }
            }
        }
        // Priority 3 check - only if no priority 1 or 2 found
        if (finalStatus == null) {
            for (Document_Details__c doc : documents) {
                if(contentDocIdToRecordMap.containsKey(doc.Content_Document_Id__c)){
                    if (doc.Screening_Status__c == 'Pending') {
                        finalStatus = 'Pending';
                        break;
                    }
                }
            }
        }
        // If none matched, default to 'FCU Completed'
        if (finalStatus == null) {
            finalStatus = 'FCU Completed';
        }
        // Update only if status changed
        if (loanRecord.FCU_Status__c != finalStatus) {
            loanRecord.FCU_Status__c = finalStatus;
            update loanRecord;
        }
    }

        private static void populateCommonChildFields(
                Application_Verification__c childRecord,
                Id recordTypeId,
                String checkType,
                Id parentId,
                Opportunity loanDetails,
                Application_Verification__c parentFraudId
            ) {
                childRecord.RecordTypeId = recordTypeId;
                childRecord.FCU_Check_type__c = checkType;
                childRecord.Parent_FCU__c = parentId;
                childRecord.Stage__c = Constants__mdt.getInstance('FCU_Accepted').value__c;
                childRecord.OwnerId = parentFraudId.OwnerId;
                childRecord.Branch__c = loanDetails.Branch_Master__c;
                childRecord.Agents_s_Branch__c = parentFraudId.Agents_s_Branch__c;
                childRecord.Loan_Application__c = parentFraudId.Loan_Application__c;
                childRecord.Primary_Applicant__c = parentFraudId.Primary_Applicant__c;
                childRecord.Co_Applicant_s__c = parentFraudId.Co_Applicant_s__c;
                childRecord.Cluster__c = parentFraudId.Cluster__c;
                childRecord.Product__c = parentFraudId.Product__c;
                childRecord.State__c = parentFraudId.State__c;
                childRecord.Sample_Date__c = System.now();
                childRecord.Applicant__c = parentFraudId.Applicant__c;
                childRecord.Approval_Status__c = Constants__mdt.getInstance('FCU_APPROVAL_NOT_INITIATED').value__c;
            }



    public class FileDataWrapper {
        @AuraEnabled public String fileName;
        @AuraEnabled public String fileContentDocumentId;
        @AuraEnabled public String loanApplicationId;
        @AuraEnabled public String documentId;
    }
    
    @AuraEnabled
    public static string saveFCUDocuments( String files){
        String res= 'success';
        try {
            List<FileDataWrapper> fileList = (List<FileDataWrapper>) JSON.deserialize(files, List<FileDataWrapper>.class);
            List<Document_Master__c> docMaster= [SELECT Id FROM Document_Master__c WHERE Name= 'Report'];
            for (FileDataWrapper fileData : fileList) {
                Document_Details__c document = new Document_Details__c();
                document.Name = fileData.fileName;
                document.Loan_Application__c = fileData.loanApplicationId;
                if(docMaster.size()> 0){
                    document.Document_Master__c =  docMaster[0].Id;
                }
                document.Content_Document_Id__c = fileData.fileContentDocumentId;
                document.Consider_for_Loan_Application__c = true;
                document.Status__c= 'Uploaded';
                insert document;
                
                ContentDocumentLink docLink = new ContentDocumentLink();
                docLink.ContentDocumentId = fileData.fileContentDocumentId;
                docLink.LinkedEntityId = document.Id; // Associate with the record
                docLink.ShareType = 'V'; // View permission
                docLink.Visibility = 'AllUsers'; // Set visibility to all users (adjust as necessary)
                insert docLink;
            }
            
        } catch (Exception e) {
            // throw new AuraHandledException(e.getMessage());
            res= 'fail';
        }

        return res;
    }

    @AuraEnabled
    public static List<FileDataWrapper> fetchFCUDocuments( String loanId){
        List<FileDataWrapper> fileDataList= new List<FileDataWrapper>();
        try {
            List<Document_Details__c> docList = [SELECT Id, Name, Content_Document_Id__c FROM Document_Details__c WHERE Loan_Application__c =: loanId AND Name LIKE 'FCU Document%'];
            for( Document_Details__c doc: docList){
                FileDataWrapper fileData= new FileDataWrapper();
                fileData.fileName= doc.Name;
                fileData.fileContentDocumentId= doc.Content_Document_Id__c;
                fileData.documentId= doc.Id;
                fileDataList.add(fileData);
            }
        } catch (Exception e) {
            // throw new AuraHandledException(e.getMessage());
        }
        return fileDataList;
    }
}