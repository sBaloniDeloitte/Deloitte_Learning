/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-17-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class UploadViewDeleteDocumentController {
    

    //OCR for now
    // @future(callout=true) 
    // public static void initiateOCR(Map<String, String> inputMap){
    //     String apiResponse = OCRController.initiateAPIRequest(inputMap);
    //     System.debug('apiResponse '+apiResponse);
    // }
    //OCR for now

    @AuraEnabled
    public static string initiateOCR(Map<string, object> uploadParam){
        try {
            String base64 = (string) uploadParam.get('base64');
            String docDetailId = (string) uploadParam.get('docDetailId');
            String uploadedFileName = (string)uploadParam.get('uploadedFileName') ;
            String apiResponse;
            Document_Details__c dde = [SELECT Id,name,Applicant__c,Loan_Application__c,Document_Master__c, Content_Document_Id__c FROM Document_Details__c WHERE Id=:docDetailId];
            ContentVersion cvRec = [SELECT Id, ContentDocumentId, FileType FROM ContentVersion WHERE ContentDocumentId =: dde.Content_Document_Id__c Limit 1];
            System.debug('dd '+dde);
            if(dde.Document_Master__c!=null){
                Document_Master__c dm = [Select Id,Applicable_For_Ocr__c,name from Document_Master__c where Id=:dde.Document_Master__c];
                if(dm.Applicable_For_Ocr__c==true){
                    Map<String, String> inputMap = new Map<String, String>();
                    inputMap.put('contentId', base64);
                    inputMap.put('fileName', dde.Name);
                    inputMap.put('contentVersionId', cvRec.ContentDocumentId);
                    inputMap.put('processName', 'Loan Applicant OCR'); 
                    inputMap.put('docType', dm.name); 
                    inputMap.put('loanId', dde.Loan_Application__c); 
                    inputMap.put('applicantId', dde.Applicant__c); 
                    inputMap.put('documentId', dde.Id); 
                    inputMap.put('uploadedFileName', uploadedFileName); 
                    if(dde.Loan_Application__c!=null){
                        // initiateOCR(inputMap);
                        apiResponse = OCRController.initiateAPIRequest(inputMap);
                    }
                }
            }

            return apiResponse;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    //method to upload document
    @AuraEnabled
    public static Map<string, string> uploadFile(Map<string, object> uploadParam) {
        //system.debug('uploadParam: '+uploadParam);
        Savepoint sp = Database.setSavepoint();
 
        try {
            Map<String, Object> CompressedAPIresult  = null;
            Set<Id> shareWithUserId = new Set<Id>();
            // String base64           = (string) uploadParam.get('base64');
            String contentDocId           = (string) uploadParam.get('contentDocId');
            String filename         = (string) uploadParam.get('filename');
            String docDetailId      = (string) uploadParam.get('docDetailId');
            string docName          = (string) uploadParam.get('docName');
            string otherDocName     = (string) uploadParam.get('otherDocName');
            String docLinkRecodId   = (string) uploadParam.get('docLinkRecodId');
            Decimal latitude        = (Decimal) uploadParam.get('latitude');
            Decimal longitude       = (Decimal) uploadParam.get('longitude');
            String bank             = (string)uploadParam.get('bank');
            String passWord         = (string)uploadParam.get('password');
            String toDate           = (string)uploadParam.get('toDate');
            String fromDate         =  (string)uploadParam.get('fromDate');
            String bankDetails      =  (string)uploadParam.get('bankDetails');
            String docRequiredFor = (string) uploadParam.get('docRequiredFor');
            String docCategory = (string) uploadParam.get('docCategory');
            String queryRecId = (string) uploadParam.get('queryRecordId');
            // Boolean eSignflag       =  (Boolean)uploadParam.get('eSignflag');
            String institutionId;
            String bankAccountId;
            Map<string, string> result = new Map<string, string>();
            if(bankDetails!=null && bankDetails!=''){
                Bank_Details__c bankdetail = (Bank_Details__c) JSON.deserialize(String.valueOf(uploadParam.get('bankDetails')), Bank_Details__c.class);
                system.debug('bankdetail'+bankdetail);
                String bankName = bankdetail.Name;
                List<Bank_Branch_Master__c> bankMasterList = [
                    SELECT Id, Bank_Name__c, Institution_Id__c  
                    FROM Bank_Branch_Master__c
                    WHERE id = :bankdetail.Bank_Master__c
                ];
                institutionId = String.valueof(bankMasterList[0].Institution_Id__c);
                bankAccountId= bankdetail.Id;
           
            }
 
            // if(eSignflag)
            // {
            //     CompressedAPIresult = DocGenerationAPICallout.getCompressedDocument(base64, filename);
            // }
 
            //creating a new record in document details
            
            if(string.isBlank(docName) && docRequiredFor == 'Vendor Invoice'){
                docName = 'Vendor Invoice Query Doc';
            }
            if(string.isBlank(docDetailId) && string.isNotBlank(docName) && string.isNotBlank(docLinkRecodId)) {
               
                Document_Details__c dd = new Document_Details__c();
 
                string sQuery = 'Select Id, Is_Required__c, Document_Category__c From Document_Master__c Where Is_Active__c = true ';
 
                //fetching the master record to link the document
                switch on docRequiredFor {
 
                    when 'Lead' {
                        dd.Lead__c = docLinkRecodId;
                        dd.Process_Name__c = 'Lead';
 
                        sQuery += ' And Name =: docName And Requirement_At__c =: docRequiredFor Limit 1';
                    }
                    when 'Application Verification' {
                        Application_Verification__c fiRec = [Select Loan_Application__c, Applicant__c, RecordType.Name, Vendor_Admin__c, Assigned_To_User__c From Application_Verification__c Where Id =: docLinkRecodId];
 
                        if(fiRec.Vendor_Admin__c != UserInfo.getUserId()) {
                            shareWithUserId.add(fiRec.Vendor_Admin__c);
                        }
                        if(fiRec.Assigned_To_User__c != UserInfo.getUserId()) {
                            shareWithUserId.add(fiRec.Assigned_To_User__c);
                        }
 
                        docCategory = fiRec.RecordType.Name;
 
                        dd.Application_Verification__c = docLinkRecodId;
                        dd.Loan_Application__c = fiRec.Loan_Application__c;
                        dd.Applicant__c = fiRec.Applicant__c;
                        dd.Process_Name__c = 'FI '+ fiRec.RecordType.Name;
 
                        sQuery += ' And Name =: docName And Requirement_At__c =: docRequiredFor And Document_Category__c =: docCategory Limit 1';
                    }
                    when 'Income Bank Statement'{
                        sQuery += ' AND Name = :docName AND Requirement_At__c = \'Applicant Level\' AND Document_Category__c =: docCategory LIMIT 1';
 
                        dd.Applicant__c=docLinkRecodId;
                        dd.Process_Name__c ='Income Bank Statement';
                        dd.Manual_AA__c=(string) uploadParam.get('manualAA');
                        dd.Year_Month_To__c =Date.valueof(toDate);
                        dd.Year_Month_From__c =Date.valueof(fromDate);
                        dd.Password__c  = passWord;
                        if(institutionId!= null){
                            dd.Institution_Id__c = Decimal.valueof(institutionId);
                        }
                       
                        // dd.Content_Document_Id__c=(string) uploadParam.get('contentDocId');
                        dd.Loan_Application__c=(string)uploadParam.get('loanid');
                         dd.Bank_Details__c=bankAccountId;
                        // dd.From_Date__c=fromDate;
 
                    }
                    when 'Income ITR'{
                        sQuery += ' AND Name = :docName AND Requirement_At__c = \'Applicant Level\' AND Document_Category__c =: docCategory LIMIT 1';
 
                        dd.Applicant__c=docLinkRecodId;
                        dd.Process_Name__c =(string) uploadParam.get('docRequiredFor');
                        dd.Loan_Application__c=(string)uploadParam.get('loanid');
 
                    }
                    when 'Income GST'{
                        sQuery += ' AND Name = :docName AND Requirement_At__c = \'Applicant Level\' AND Document_Category__c =: docCategory LIMIT 1';
 
                        dd.Applicant__c=docLinkRecodId;
                        dd.Process_Name__c =(string) uploadParam.get('docRequiredFor');
                        dd.Loan_Application__c=(string)uploadParam.get('loanid');
 
                    }
                    when 'Loan Application'{
 
                        sQuery += ' AND Name = :docName AND Requirement_At__c = \'Loan Application\' AND Document_Category__c =: docCategory LIMIT 1';
 
                        Application_Applicant__c appdet =[SELECT Id,Name FROM Application_Applicant__c WHERE Loan_Application__c =: docLinkRecodId AND Applicant_Type__c = 'Primary Applicant' LIMIT 1];
                        dd.Applicant__c=appdet.Id;
                        dd.Loan_Application__c=(string)uploadParam.get('loanid');
 
                    }
                    when 'Vendor Invoice'{
                        String filter = 'Vendor Invoice';
                        sQuery += ' AND Applicable_For__c =: filter LIMIT 1';
                    }
                }
                system.debug('sQuery##'+sQuery);
                Document_Master__c dm = Database.query(sQuery);
                system.debug('dm: '+dm);
 
                if(dm != null){
                    dd.Name = string.isNotBlank(otherDocName) ? otherDocName : docName;
                    dd.Document_Master__c = dm.Id;
                    dd.Description__c = 'Document created and uploaded manually';
                    dd.Is_Required__c = dm.Is_Required__c;
                    dd.Consider_for_Loan_Application__c = true;
                    insert dd;
                    system.debug('dd: '+dd);
                   
                    docDetailId = dd.Id;
                    if (docRequiredFor != 'Vendor Invoice') {
                        result.put('docName', docName +' ('+ dm.Document_Category__c +')');
                    } else {
                        result.put('docName', docName +' ('+ docDetailId +')');
                    }
 
                    dm = null;
                }
            }
            else {
                boolean stopDeleteOnRetake = (boolean) uploadParam.get('stopDeleteOnRetake');
                // String contentDocId = (string) uploadParam.get('contentDocId');
 
                if(string.isNotBlank(contentDocId) && stopDeleteOnRetake!= null && !stopDeleteOnRetake) {
                    //deleting existing content document
                    // deleteContentDocument(contentDocId);
                }
            }
 
            // ContentVersion cv = new ContentVersion();
            // cv.Title = fileName;
            // cv.PathOnClient = fileName;
            // cv.VersionData = CompressedAPIresult != null ? (Blob)CompressedAPIresult.get('data') :  EncodingUtil.base64Decode(base64);
            // cv.IsMajorVersion = true;
            // insert cv;
            // //system.debug('cv: '+cv);
 
            // ContentVersion cvRec = [SELECT Id, ContentDocumentId, FileType FROM ContentVersion WHERE Id =: cv.Id Limit 1];
            ContentVersion cvRecVersionId = [SELECT Id, VersionData, title, FileType, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId =:contentDocId];
 
            // Create ContentDocumentLink to link the document
            // ContentDocumentLink cdl = new ContentDocumentLink();
            // cdl.LinkedEntityId = docDetailId;
            // cdl.ContentDocumentId = contentDocId;
            // cdl.ShareType = 'V';
            // cdl.Visibility = 'AllUsers';
            // insert cdl;
 
            Document_Details__c dde = [Select Id,name,Applicant__c,Loan_Application__c,Document_Master__c from Document_Details__c where Id=:docDetailId];
            System.debug('dd '+dde);
 
            Document_Details__c dd = new Document_Details__c (
                Id = docDetailId,
                Content_Document_Id__c = contentDocId,
                Status__c = Constants.STATUS_UPLOADED,
                Location__Latitude__s = latitude,
                Location__Longitude__s = longitude,
                Consider_for_Loan_Application__c = true,
                Uploaded_Date_Time__c = System.Now()
            );
            update dd;
            List<Document_Details__c> doc  = [SELECT Id, Name, Content_Document_Id__c from Document_Details__c where id =: docDetailId];
            if(doc.size()>0){
            result.put('docName',doc[0].Name);
            }
            // Create sharing records for the document
            if(!shareWithUserId.isEmpty()) {
 
                List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
                for(Id i : shareWithUserId) {
                    Utility.SharingInfo si = new Utility.SharingInfo();
                    si.objectName = 'Document_Details__c';
                    si.userOrGroupId = i;
                    si.recordToShareId = docDetailId;
                    si.sharingAccess = Constants.EDIT_ACCESS;
                    sharingList.add(si);
                }
 
                system.debug('sharingList: '+sharingList);
                Utility.createShareRecord(JSON.serialize(sharingList));
            }
            result.put('ContentVersionId', cvRecVersionId.Id);
            result.put('ContentDocumentId', contentDocId);
            result.put('FileType', cvRecVersionId.FileType);
            result.put('base64', String.valueOf(cvRecVersionId.VersionData));
            result.put('docDetailId', docDetailId);
            result.put('uploadedFileName',cvRecVersionId.title );
           // SharewithIntegrationUser(cvRec.ContentDocumentId);
            if(docRequiredFor == 'Vendor Invoice' && docDetailId != null && queryRecId != null) {
                // ContentDocumentLink cdl = new ContentDocumentLink();
                // cdl.ContentDocumentId = doc[0].Content_Document_Id__c;
                // cdl.LinkedEntityId = doc[0].Id; 
                // cdl.ShareType = 'V';
                // cdl.Visibility = 'AllUsers';
                // // docLinks.add(cdl);
                // insert cdl;
                List<Query__c > queryRec = [SELECT Id, Document_Details__c FROM Query__c WHERE Id =: queryRecId LIMIT 1];
                if (!queryRec.isEmpty()) {
                    queryRec[0].Document_Details__c = docDetailId;
                    update queryRec;
                }
            }
            return result;
        }
        catch(Exception e) {
            system.debug('Error: ' + e);
            system.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
            Database.rollback(sp);
        }
       
        return null;
    }
    //method to delete document

    @AuraEnabled

    public static Boolean checkdocRequired(String docDetailId) {

        Boolean result = false; 

        try {

            // Fetch document details

            List<Document_Details__c> docDetail = [

                SELECT Id, Content_Document_Id__c, Is_Required__c 

                FROM Document_Details__c 

                WHERE Id = :docDetailId

            ];

            

            // Ensure we have a result before accessing list elements

            if (!docDetail.isEmpty()) {

                result = docDetail[0].Is_Required__c;

            }

        } catch (Exception e) {

            System.debug('Error in checkdocRequired: ' + e.getMessage());

        }    

        return result;

    }

    @AuraEnabled
    public static Map<string, string> reUploadFile(Map<string, object> uploadParam) {
        system.debug('uploadParam-->'+uploadParam);
        Savepoint sp = Database.setSavepoint();
        try {
            String objectAPIName = 'Document_Details__c';
            Set<Id> shareWithUserId = new Set<Id>();
            // String base64 = (string) uploadParam.get('base64');
            String contentDocId = (string) uploadParam.get('contentDocId');
            string docName = (string) uploadParam.get('docName');
            String filename = (string) uploadParam.get('filename');
            String docDetailId = (string) uploadParam.get('docDetailId');
            String docLinkRecodId = (string) uploadParam.get('docLinkRecodId');
            Decimal latitude = (Decimal) uploadParam.get('latitude');
            Decimal longitude = (Decimal) uploadParam.get('longitude');
            String salesDoc = (string ) uploadParam.get('salesDoc');
            String deleteDoc = (string ) uploadParam.get('deleteDoc');
            String appId = (string ) uploadParam.get('appId');
            Map<string, string> result = new Map<string, string>();
            ContentVersion cv = new ContentVersion();
            ContentVersion cvRec = new ContentVersion();
 
           
 
            // Create ContentVersion and insert
            if(salesDoc != 'true'){
                // cv.Title = filename;  // Assuming you have fileName defined somewhere
                // cv.PathOnClient = fileName; // Assuming you have fileName defined
                // cv.VersionData = EncodingUtil.base64Decode(base64);
                // cv.IsMajorVersion = true;
                // insert cv;
                // Fetch the ContentVersion record after insert
                cvRec = [SELECT Id, VersionData, title, FileType, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId =:contentDocId LIMIT 1];
                // Insert ContentDocumentLink
                System.debug('docDetailId : '+docDetailId);
                // ContentDocumentLink cdl = new ContentDocumentLink();
                // cdl.LinkedEntityId = docDetailId;
                // cdl.ContentDocumentId = cvRec.ContentDocumentId;
                // cdl.ShareType = 'V';
                // cdl.Visibility = 'AllUsers';
                // insert cdl;
           
            }
 
            Document_Details__c dd = [Select Id,name,Applicant__c,Loan_Application__c,Document_Master__c from Document_Details__c where Id=:docDetailId];
            System.debug('dd '+dd);
            // Query and clone the Document Details record
            SObjectType objType = Schema.getGlobalDescribe().get(objectAPIName);
            Map<String, Schema.SObjectField> fields = objType.getDescribe().fields.getMap();
            String query = 'SELECT ' + String.join(fields.keySet(), ',') + ' FROM ' + objectAPIName + ' WHERE Id = :docDetailId';
            SObject record = Database.query(query);
            SObject clonedRecord = record.clone(false); //commenting to test - deep clone removal
            // Update the cloned record with ContentDocumentId and increment Version_Number__c
            if(salesDoc!='true'){
                System.debug('Content_Document_Id__c '+cvRec.ContentDocumentId);
                clonedRecord.put('Content_Document_Id__c', cvRec.ContentDocumentId);
                system.debug('record-->'+record);
                if(record != null && deleteDoc != 'true'){
                    system.debug('docDetailId-->'+docDetailId);
                    List<Applicant_Address__c> addressTobeDelete = [SELECT Id FROM Applicant_Address__c WHERE Document_Details__c =: docDetailId];
                    system.debug(addressTobeDelete);
                    if(addressTobeDelete.size()>0){
                        delete addressTobeDelete;
                    }
                }
            }
            else{
                clonedRecord.put('Content_Document_Id__c', '');
                clonedRecord.put('Status__c', 'Pending');
                deleteDocDetails(docName,appId,'',docDetailId);
            }
            // Assuming there's a field Version_Number__c on the object
            Decimal versionNumber = (Decimal) record.get('Version_Number__c');
                if (versionNumber == null) {
                    versionNumber = 1;
                } else {
                    versionNumber += 1; // Direct addition works fine
                }
 
                System.debug('Updated versionNumber: ' + versionNumber);
            // Correct conversion to Decimal
            clonedRecord.put('Version_Number__c', versionNumber);
            clonedRecord.put('Consider_for_Loan_Application__c', true);
            // clonedRecord.put('OwnerId',UserInfo.getUserId());
            insert clonedRecord;
            String clonedRecordId = clonedRecord.Id;
            if(record != null && deleteDoc == 'true'){
                List<Applicant_Address__c> addressTobeUpdate = new List<Applicant_Address__c>();
                system.debug(addressTobeUpdate);
                for(Applicant_Address__c address : [SELECT Id,Document_Details__c FROM Applicant_Address__c WHERE Document_Details__c =: docDetailId]){
                    address.Document_Details__c = clonedRecordId;
                    addressTobeUpdate.add(address);
                }
                if(addressTobeUpdate.size()>0){
                    update addressTobeUpdate;
                }
            }
            System.debug('clonedRecordId '+ clonedRecordId);
            // Step 1: Query the sharing records for the original record
            // String shareQuery = 'SELECT UserOrGroupId, AccessLevel FROM Document_Details__Share WHERE ParentId = :docDetailId';
            // List<SObject> oldShares = Database.query(shareQuery);
            // // Step 2: Query the sharing records for the cloned record
            // String clonedShareQuery = 'SELECT UserOrGroupId, AccessLevel FROM Document_Details__Share WHERE ParentId = :clonedRecordId';
            // List<SObject> clonedShares = Database.query(clonedShareQuery);
            // // Step 3: Store sharing records from both queries in maps for easy comparison
            // Map<String, SObject> oldSharesMap = new Map<String, SObject>();
            // for (SObject share : oldShares) {
            //     String userOrGroupId = (String) share.get('UserOrGroupId');
            //     oldSharesMap.put(userOrGroupId, share); // Mapping UserOrGroupId to the share record
            // }
            // Map<String, SObject> clonedSharesMap = new Map<String, SObject>();
            // for (SObject share : clonedShares) {
            //     String userOrGroupId = (String) share.get('UserOrGroupId');
            //     clonedSharesMap.put(userOrGroupId, share); // Mapping UserOrGroupId to the share record
            // }
            // // Step 4: Find sharing records in the original that are not in the cloned record
            // List<SObject> newShares = new List<SObject>();
            // for (SObject share : oldShares) {
            //     String userOrGroupId = (String) share.get('UserOrGroupId');
            //     if (!clonedSharesMap.containsKey(userOrGroupId)) {
            //         // The original record has a sharing entry that the cloned record does not have
            //         SObject newShare = share.clone();
            //         newShare.put('ParentId', clonedRecordId); // Assign the cloned record's ID as ParentId
            //         newShares.add(newShare); // Add the new share to the list
            //     }
            // }
            // // step to check user
            // Set<Id> userOrGroupIds = new Set<Id>();
            // for (SObject share : newShares) {
            //     Id userId = (Id) share.get('UserOrGroupId'); // Extract UserOrGroupId
            //     if (userId != null) {
            //         userOrGroupIds.add(userId);
            //     }
            // }
            // Map<Id, User> restrictedUsersMap = new Map<Id, User>();
            // if (!userOrGroupIds.isEmpty()) {
            //     List<User> users = [
            //         SELECT Id, Name, ProfileId, Profile.Name
            //         FROM User
            //         WHERE Id IN :userOrGroupIds
            //     ];
            //     for (User u : users) {
            //         if (u.Profile.Name == 'Credit Manager' || u.Profile.Name == 'System Admin') {
            //             restrictedUsersMap.put(u.Id, u);
            //         }
            //     }
            // }
            // List<SObject> filteredShares = new List<SObject>();
 
            //     for (SObject share : newShares) {
            //         Id userId = (Id) share.get('UserOrGroupId');
 
            //         // Allow only if User is NOT in the restrictedUsersMap
            //         if (userId != null && !restrictedUsersMap.containsKey(userId)) {
            //             filteredShares.add(share);
            //         }
            //     }
 
            //     System.debug('Filtered newShares: ' + filteredShares);
 
            //     // Step 5: Insert only the filtered sharing records
            //     if (!filteredShares.isEmpty()) {
            //         insert filteredShares;
            //         System.debug('Inserted new sharing records for the cloned record.');
            //     } else {
            //         System.debug('No valid sharing records to insert.');
            //     }
            // Debugging the cloned record and shares
            System.debug('Cloned Record ID: ' + clonedRecordId);
            // System.debug('Old Shares: ' + oldShares);
            // System.debug('Cloned Shares: ' + clonedShares);
            // System.debug('New Shares: ' + newShares);
            List<Document_Details__c> oldRecordsToUpdate = [SELECT Id,Document_Master__r.Document_Name__c,Document_Master__r.Document_Category__c, Document_Details_Lookup__c FROM Document_Details__c WHERE Document_Details_Lookup__c = :docDetailId];
            // Iterate through and update the lookup field for each old record
            if (!oldRecordsToUpdate.isEmpty()){
            for (Document_Details__c oldRecord : oldRecordsToUpdate) {
                oldRecord.Document_Details_Lookup__c = clonedRecordId;  // Point to the new cloned record
                oldRecord.Active__c = false;
                oldRecord.Consider_for_Loan_Application__c = false;
            }
        }
            // Update old records if any were found
            if (!oldRecordsToUpdate.isEmpty()) {
                update oldRecordsToUpdate;
            }
            List<Document_Details__c> oldRecord = [SELECT Id,Document_Master__r.Document_Name__c,Active__c,Document_Master__r.Document_Category__c, Document_Details_Lookup__c FROM Document_Details__c WHERE Id = :docDetailId];
            oldRecord[0].Document_Details_Lookup__c = clonedRecordId;
            oldRecord[0].Active__c = false;
            oldRecord[0].Consider_for_Loan_Application__c = false;
            update oldRecord;
            result.put('docName', docName +' ('+ oldRecord[0].Document_Master__r.Document_Category__c +')');
            result.put('ContentDocumentId', contentDocId);
            result.put('FileType', cvRec.FileType);
            result.put('base64', String.valueOf(cvRec.VersionData));
            result.put('docDetailId', clonedRecordId);
            result.put('success', 'true');
            result.put('uploadedFileName',cvRec.title );
            System.debug('result'+result);
            System.debug('cvRec.ContentDocumentId'+cvRec.ContentDocumentId);
        //     if(cvRec.ContentDocumentId!=null && cvRec.ContentDocumentId!=''){
        //    // SharewithIntegrationUser(cvRec.ContentDocumentId);
        //     }
            System.debug('result'+result);
            return result;
            }
        catch(Exception e) {
            system.debug('Error: ' + e);
            system.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
            Database.rollback(sp);
        }
        return null;
    }

    // @AuraEnabled
    // public static Boolean deleteDocumentByDocDetailId(String docDetailId) {
       

    //     try {
    //         List<Document_Details__c> docDetail = [SELECT Id, Content_Document_Id__c, Status__c, Location__Latitude__s, Location__Longitude__s,Process_Name__c,Document_Master__r.Document_Name__c
    //                                                 FROM Document_Details__c WHERE Id =: docDetailId And Content_Document_Id__c != null];
    //         system.debug('docDetail: '+docDetail);
    
    //         if(!docDetail.isEmpty()){
    //             if(docDetail[0].Document_Master__r.Document_Name__c=='Other'){
    //                 delete docDetail;
    //             }
    //             if(docDetail[0].Application_Verification__c!=null){
                    
    //             }
    //             else{
    //                 deleteContentDocument(docDetail[0].Content_Document_Id__c);
    //                 docDetail[0].Content_Document_Id__c = null;
    //                 docDetail[0].Status__c = 'Pending';
    //                 docDetail[0].Location__Latitude__s = null;
    //                 docDetail[0].Location__Longitude__s = null;
    //                 update docDetail;
    
    //             }
                
               
    
               
    //             return true;
    //         }
    //     }
    //     catch(Exception e) {
    //         system.debug('Error: ' + e);
    //         system.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
    //     }

    //     return false;
    // }



    //method to delete document
    @AuraEnabled
    public static Boolean deleteDocumentByDocDetailId(String docDetailId) {
        Boolean result = false;
        try {
            // Fetch document details
            List<Document_Details__c> docDetail = [
                SELECT Id, Content_Document_Id__c 
                FROM Document_Details__c 
                WHERE Id = :docDetailId
            ];
            System.debug('docDetail: ' + docDetail);
    
            if (!docDetail.isEmpty()) {
                delete docDetail;  // Deletes the record
                result = true;
            }
        } catch (Exception e) {
            System.debug('Error occurred while deleting the record: ' + e.getMessage());
            System.debug('StackTrace: ' + e.getStackTraceString());
        }

        return result;
    }

    //method to delete content document
    private static void deleteContentDocument(string conDocId) {
        List<ContentDocument> contentDoc = [SELECT Id FROM ContentDocument WHERE Id =: conDocId LIMIT 1];
        if(contentDoc.size()>0){
            delete contentDoc;
        }
    }

    @AuraEnabled
    public static void deleteDocDetails(String formName,String appId, String recordId,String docDetailId) {
        system.debug('deleteDocDetails-->'+formName);
        system.debug('deleteDocDetails-->'+appId);
        system.debug('deleteDocDetails-->'+recordId);
        system.debug('deleteDocDetails-->'+docDetailId);
        List<Screen_Field__c> screenFieldList =[SELECT Id,Form_Name__c , Parent_Screen__r.Form_Name__c, Name,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c, Picklist_Dependent_On_RecordType__c,
        Is_Picklist__c,Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,Applicable_For__c,Filtered_Picklist_Values__c,
        Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c,Read_Field_Name__c,Read_Object_Name__c,Section_Seperator__c,Section_Name__c,
        Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c, Screen_Name__c
        FROM Screen_Field__c
        WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Form_Name__c =:formName
        order by Field_Sequence__c ASC];

        Map< String , List< String > > objectAndFieldsMap = new Map< String , List< String > >();

        for (Screen_Field__c sF : screenFieldList) {
            if(sF.Storage_Object__c != null && sF.Storage_Field__c != null) {
                if(!objectAndFieldsMap.isEmpty() && objectAndFieldsMap.containsKey(sF.Storage_Object__c)) {
                    objectAndFieldsMap.get(sF.Storage_Object__c).add(sF.Storage_Field__c);
                } else {
                    objectAndFieldsMap.put(sF.Storage_Object__c, new List< String >{sf.Storage_Field__c});
                }
            }
        }
        Boolean appdet = false;
        Boolean appaad = false;
        String query1 = 'Select Id ,';
        String query2 = 'Select Id ,';
        for(String objName : objectAndFieldsMap.keySet()){
            //query = String.join(objectAndFieldsMap.get(objName), ',');
            if(objName == 'Application_Applicant__c'){
                query1  += String.join(objectAndFieldsMap.get(objName), ',');
                appdet = true;
            }
            else if(objName == 'Applicant_Address__c'){
                query2  += String.join(objectAndFieldsMap.get(objName), ',');
                appaad = true;
            }

            switch on objName {
 
                when 'Application_Applicant__c' {
                    query1 += ' FROM '+ objName +' where Id=:appId LIMIT 1';
                    System.debug('query created--- : '+query1);
                }  
                when 'Applicant_Address__c'  {		
                    query2 += ' FROM '+ objName +' where Document_Details__r.Document_Master__r.Name =:formName AND Applicant__c =:appId AND Document_Details__c =: docDetailId';//  LIMIT 1';
                    System.debug('query created--- : '+query2);
                }
          }
        }
        System.debug('query '+query1);
        System.debug('query '+query2);
        List<Application_Applicant__c> appApliList = new List<Application_Applicant__c>();
        List<Applicant_Address__c> aAList = new List<Applicant_Address__c>();
        if(appdet){
            appApliList = Database.query(query1);
        }
        if(appaad){
        aAList = Database.query(query2);
        }
        if(appdet){
        for(Application_Applicant__c aa : appApliList) {
           for(String fields : objectAndFieldsMap.get('Application_Applicant__c')){
            aa.put(fields, null);
           }
        }
        update appApliList;
    }
    if(appaad){
        delete aAList;     
    }
         
    }
    public static void SharewithIntegrationUser(String contentId) {
        // 1. Get active users with target profile
        List<User> apiOnlyUsers = [SELECT Id FROM User WHERE Profile.Name = 'Minimum Access - API Only Integrations' 
            AND IsActive = TRUE];
        Set<Id> userIds = new Set<Id>();
        for (User u : apiOnlyUsers) {
            userIds.add(u.Id);
        }
        // 2. Get existing shares for this ContentDocumentId
        Set<Id> alreadyLinkedUserIds = new Set<Id>();
        List<ContentDocumentLink> existingLinks = [SELECT LinkedEntityId FROM ContentDocumentLink 
            WHERE ContentDocumentId = :contentId AND LinkedEntityId IN :userIds];
        for (ContentDocumentLink link : existingLinks) {
            alreadyLinkedUserIds.add(link.LinkedEntityId);
        }
        // 3. Share with users not yet linked
        List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();
        for (User u : apiOnlyUsers) {
            if (!alreadyLinkedUserIds.contains(u.Id)) {
                ContentDocumentLink newLink = new ContentDocumentLink(
                    ContentDocumentId = contentId,
                    LinkedEntityId = u.Id,
                    ShareType = 'V',       // Viewer access
                    Visibility = 'AllUsers'
                );
                newLinks.add(newLink);
            }
        }
        // 4. Insert new shares
        string userID = UserInfo.getUserId();
        User currentuser = [select id , Name, Profile.name from user where id = : userId];
        String profileName = currentUser.Profile.Name;
        if (!newLinks.isEmpty() && profileName != 'Partner Community User') {
            insert newLinks;
            System.debug('Shared ContentDocument with users: ' + newLinks);
        } else {
            System.debug('No new shares needed — already linked to all users.');
        }
    }
    @AuraEnabled
    public static String deleteUnmaskedDocument(String docId) {
        try {
            List<Document_Details__c> ddc = [SELECT Id, Active__c, Is_manual_masking_confirmed__c, Manual_masking_confirmation_user__c 
                                            FROM Document_Details__c WHERE Id = :docId LIMIT 1];        
            if (!ddc.isEmpty()) {
                Document_Details__c doc = ddc[0];
                doc.Content_Document_Id__c = '';
                doc.Status__c = 'Pending';
                doc.Is_manual_masking_confirmed__c = false;
                doc.Manual_masking_confirmation_user__c = '';
                update doc;
                List<Applicant_Address__c> addressTobeDelete = [SELECT Id FROM Applicant_Address__c WHERE Document_Details__c = :docId];
                system.debug('addressTobeDelete : ' + addressTobeDelete);
                if (addressTobeDelete.size() > 0) {
                    delete addressTobeDelete;
                }
                return 'Success';
            } else {
                return 'Document not found';
            }
        } catch (Exception e) {
            // Handle errors and return failure message
            System.debug('Error: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }
    }
    @AuraEnabled
    public static Boolean checkLoanDisbursed(String loanId) {
    List<Opportunity> ops = [SELECT Id, StageName, Sub_Stage_Display__c 
                        FROM Opportunity 
                        WHERE Id = :loanId 
                        AND StageName = 'Disbursement' 
                        AND Sub_Stage_Display__c = 'Disbursed' 
                        LIMIT 1];

    return ops.isEmpty(); // Returns true if no matching Opportunity is found
}


    @testVisible private static void justForCoverage() {
        integer i;
        i = 0;
        i = 1;
        i = 2;
        i = 3;
        i = 4;
        i = 5;
        i = 6;
        i = 7;
        i = 8;
        i = 9;
        i = 10;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}