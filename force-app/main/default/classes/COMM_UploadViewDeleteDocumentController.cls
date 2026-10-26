/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-12-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class COMM_UploadViewDeleteDocumentController {
    

    @AuraEnabled
    public static string initiateOCR(Map<string, object> uploadParam){
        try {
            System.debug('>>> initiateOCR called with uploadParam: ' + uploadParam);

            // Validate inputs
            if (uploadParam == null || uploadParam.isEmpty()) {
                throw new AuraHandledException('Upload parameters are required');
            }
    
            String base64 = (string) uploadParam.get('base64');
            String docDetailId = (string) uploadParam.get('docDetailId');
            String uploadedFileName = (string) uploadParam.get('uploadedFileName');
    
            if (String.isBlank(base64)) {
                throw new AuraHandledException('Base64 data is required for OCR processing');
            }
    
            if (String.isBlank(docDetailId)) {
                throw new AuraHandledException('Document Detail ID is required');
            }
    
            System.debug('>>> Base64 length: ' + base64.length());
            System.debug('>>> DocDetailId: ' + docDetailId);
            System.debug('>>> UploadedFileName: ' + uploadedFileName);
    
            String apiResponse;
    
            // Query Document_Details__c with error handling
            List<Document_Details__c> ddeList = [
                SELECT Id, name, Applicant__c, Loan_Application__c, Document_Master__c, Content_Document_Id__c 
                FROM Document_Details__c 
                WHERE Id = :docDetailId 
                LIMIT 1
            ];
            
            if (ddeList.isEmpty()) {
                throw new AuraHandledException('Document Detail not found for ID: ' + docDetailId);
            }
            
            Document_Details__c dde = ddeList[0];
            System.debug('>>> Document Detail found: ' + dde);
            System.debug('>>> Content_Document_Id__c: ' + dde.Content_Document_Id__c);
            System.debug('>>> Loan_Application__c: ' + dde.Loan_Application__c);
            
            // Query ContentVersion with error handling
            List<ContentVersion> cvList = [
                SELECT Id, ContentDocumentId, FileType 
                FROM ContentVersion 
                WHERE ContentDocumentId = :dde.Content_Document_Id__c 
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            
            if (cvList.isEmpty()) {
                throw new AuraHandledException('ContentVersion not found for ContentDocumentId: ' + dde.Content_Document_Id__c);
            }
            
            ContentVersion cvRec = cvList[0];
            System.debug('>>> ContentVersion found: ' + cvRec);
            
            if (dde.Document_Master__c != null) {
                List<Document_Master__c> dmList = [
                    SELECT Id, Applicable_For_Ocr__c, name 
                    FROM Document_Master__c 
                    WHERE Id = :dde.Document_Master__c 
                    LIMIT 1
                ];
                
                if (!dmList.isEmpty()) {
                    Document_Master__c dm = dmList[0];
                    System.debug('>>> Document Master found: ' + dm);
                    System.debug('>>> Applicable_For_Ocr__c: ' + dm.Applicable_For_Ocr__c);
                    
                    if (dm.Applicable_For_Ocr__c == true) {
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
                        
                        if (dde.Loan_Application__c != null) {
                            System.debug('About to call external API for OCR…');
                            System.debug('Input map: ' + inputMap);
                            
                            apiResponse = COMM_OCRController.initiateAPIRequest(inputMap);
                            System.debug('API Response: ' + apiResponse);
                            
                            if (String.isBlank(apiResponse)) {
                                System.debug('API returned empty response');
                                return 'Warning: OCR API returned no data';
                            }
                        } else {
                            throw new AuraHandledException('Loan Application ID is required for OCR processing');
                        }
                    } else {
                        System.debug('>>> Document not applicable for OCR');
                        return 'Document type not configured for OCR processing';
                    }
                } else {
                    throw new AuraHandledException('Document Master not found for ID: ' + dde.Document_Master__c);
                }
            } else {
                throw new AuraHandledException('Document Master is required for OCR processing');
            }
            return apiResponse;
            
        } catch (Exception e) {
            System.debug('Error in initiateOCR: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('OCR processing failed: ' + e.getMessage());
        }


    }

    @AuraEnabled
    public static Map<string, string> uploadFile(Map<string, object> uploadParam) {
        Savepoint sp = Database.setSavepoint();
        try {
        System.debug('>>> uploadFile called with params: '+ uploadParam);

        Map<String, Object> CompressedAPIresult = null;
            Set<Id> shareWithUserId = new Set<Id>();
            String contentDocId = (string) uploadParam.get('contentDocId');
            String filename = (string) uploadParam.get('filename');
            String docDetailId = (string) uploadParam.get('docDetailId');
            string docName = (string) uploadParam.get('docName');
            string otherDocName = (string) uploadParam.get('otherDocName');
            String docLinkRecodId = (string) uploadParam.get('docLinkRecodId');
          //  Decimal latitude = (Decimal) uploadParam.get('latitude');
          //  Decimal longitude = (Decimal) uploadParam.get('longitude');
            String bank = (string)uploadParam.get('bank');
            String passWord = (string)uploadParam.get('password');
            String toDate = (string)uploadParam.get('toDate');
            String fromDate = (string)uploadParam.get('fromDate');
            String bankDetails = (string)uploadParam.get('bankDetails');
            
            System.debug('>>> Input parameters:');
            System.debug('>>> contentDocId: ' + contentDocId);
            System.debug('>>> docDetailId: ' + docDetailId);
            System.debug('>>> filename: ' + filename);
            System.debug('>>> docName: ' + docName);
            
            // Validate required parameters
            if (String.isBlank(contentDocId)) {
                throw new AuraHandledException('Content Document ID is required');
            }
            
            String institutionId;
            String bankAccountId;
            Map<string, string> result = new Map<string, string>();
            
            if(bankDetails != null && bankDetails != ''){
                Bank_Details__c bankdetail = (Bank_Details__c) JSON.deserialize(String.valueOf(uploadParam.get('bankDetails')), Bank_Details__c.class);
                system.debug('bankdetail'+bankdetail);
                String bankName = bankdetail.Name;
                List<Bank_Branch_Master__c> bankMasterList = [
                    SELECT Id, Bank_Name__c, Institution_Id__c  
                    FROM Bank_Branch_Master__c 
                    WHERE id = :bankdetail.Bank_Master__c
                ];
                institutionId = String.valueof(bankMasterList[0].Institution_Id__c);
                bankAccountId = bankdetail.Id;
            }

            //creating a new record in document details
            if(string.isBlank(docDetailId) && string.isNotBlank(docName) && string.isNotBlank(docLinkRecodId)) {
                
                Document_Details__c dd = new Document_Details__c();
                String docRequiredFor = (string) uploadParam.get('docRequiredFor');
                string docCategory = (string) uploadParam.get('docCategory');

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
                        dd.Applicant__c = docLinkRecodId;
                        dd.Process_Name__c = 'Income Bank Statement';
                        dd.Manual_AA__c = (string) uploadParam.get('manualAA');
                        dd.Year_Month_To__c = Date.valueof(toDate);
                        dd.Year_Month_From__c = Date.valueof(fromDate);
                        dd.Password__c = passWord;
                        if(institutionId != null){
                            dd.Institution_Id__c = Decimal.valueof(institutionId);
                        }
                        dd.Loan_Application__c = (string)uploadParam.get('loanid');
                        dd.Bank_Details__c = bankAccountId;
                    }
                    when 'Income ITR'{
                        sQuery += ' AND Name = :docName AND Requirement_At__c = \'Applicant Level\' AND Document_Category__c =: docCategory LIMIT 1';
                        dd.Applicant__c = docLinkRecodId;
                        dd.Process_Name__c = (string) uploadParam.get('docRequiredFor');
                        dd.Loan_Application__c = (string)uploadParam.get('loanid');
                    }
                    when 'Income GST'{
                        sQuery += ' AND Name = :docName AND Requirement_At__c = \'Applicant Level\' AND Document_Category__c =: docCategory LIMIT 1';
                        dd.Applicant__c = docLinkRecodId;
                        dd.Process_Name__c = (string) uploadParam.get('docRequiredFor');
                        dd.Loan_Application__c = (string)uploadParam.get('loanid');
                    }
                    when 'Loan Application'{
                        sQuery += ' AND Name = :docName AND Requirement_At__c = \'Loan Application\' AND Document_Category__c =: docCategory LIMIT 1';
                        Application_Applicant__c appdet = [SELECT Id,Name FROM Application_Applicant__c WHERE Loan_Application__c =: docLinkRecodId AND Applicant_Type__c = 'Primary Applicant' LIMIT 1];
                        dd.Applicant__c = appdet.Id;
                        dd.Loan_Application__c = (string)uploadParam.get('loanid');
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
                    result.put('docName', docName +' ('+ dm.Document_Category__c +')');
                    dm = null;
                }
            } else {
                boolean stopDeleteOnRetake = (boolean) uploadParam.get('stopDeleteOnRetake');
                if(string.isNotBlank(contentDocId) && stopDeleteOnRetake != null && !stopDeleteOnRetake) {
                    // Handle existing content document if needed
                }
            }

            // Get ContentVersion details - add error handling
            List<ContentVersion> cvList = [
                SELECT Id, /*VersionData,*/ title, FileType, ContentDocumentId 
                FROM ContentVersion 
                WHERE ContentDocumentId = :contentDocId 
                AND IsLatest = true
                LIMIT 1
            ];
            
            if (cvList.isEmpty()) {
                throw new AuraHandledException('ContentVersion not found for ContentDocumentId: ' + contentDocId);
            }
            
            ContentVersion cvRecVersionId = cvList[0];
            System.debug('>>> ContentVersion found: ' + cvRecVersionId.Id);

            // Create ContentDocumentLink if it doesn't exist
            List<ContentDocumentLink> existingLinks = [
                SELECT Id 
                FROM ContentDocumentLink 
                WHERE ContentDocumentId = :contentDocId 
                AND LinkedEntityId = :docDetailId
            ];
            
            if (existingLinks.isEmpty()) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.LinkedEntityId = docDetailId;
                cdl.ContentDocumentId = contentDocId;
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                insert cdl;
                System.debug('>>> ContentDocumentLink created');
            }

            // Update Document_Details__c record
            Document_Details__c dd = new Document_Details__c (
                Id = docDetailId,
                Content_Document_Id__c = contentDocId,
                Status__c = Constants.STATUS_UPLOADED,
                Consider_for_Loan_Application__c = true,
                Uploaded_Date_Time__c = System.Now()
            );
            update dd;
            System.debug('>>> Document_Details__c updated');

            // Get document name if not already set
            if (!result.containsKey('docName')) {
                List<Document_Details__c> doc = [SELECT Id, Name from Document_Details__c where id = :docDetailId];
                if(doc.size() > 0){
                    result.put('docName', doc[0].Name);
                }
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

            // *** CRITICAL: Add ContentVersionId for OCR processing ***
            result.put('ContentVersionId', cvRecVersionId.Id);
            result.put('ContentDocumentId', contentDocId);
            result.put('FileType', cvRecVersionId.FileType);
            // result.put('base64', String.valueOf(cvRecVersionId.VersionData));
            result.put('docDetailId', docDetailId);
            result.put('success', 'true');
            result.put('uploadedFileName', cvRecVersionId.title);
            
            System.debug('>>> Upload completed successfully: ' + result);
            return result;
            
        } catch(Exception e) {
            System.debug('Error in uploadFile: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            Database.rollback(sp);
            
            // Return error in result format expected by frontend
            Map<string, string> errorResult = new Map<string, string>();
            errorResult.put('success', 'false');
            errorResult.put('error', e.getMessage());
            return errorResult;
        }
    }

    @AuraEnabled
    public static void persistDocLink(Id docDetailId, String contentDocId) {
        update new Document_Details__c(
            Id                    = docDetailId,
            Content_Document_Id__c= contentDocId,
            Uploaded_Date_Time__c = System.now()
        );
    }

    public static void resetKycForDocumentType(Id documentMasterId, Id applicantId, Id loanId) {
        if(documentMasterId == null) return;
        Document_Master__c dm = [SELECT Name FROM Document_Master__c WHERE Id = :documentMasterId LIMIT 1];
        String keyword;
        String dmName = dm.Name != null ? dm.Name.toLowerCase() : '';
        String drivingKeyword = Constants__mdt.getInstance('KYC_Doc_Keyword_Driving')?.Value__c;
        String voterKeyword   = Constants__mdt.getInstance('KYC_Doc_Keyword_Voter')?.Value__c;
        String passportKeyword= Constants__mdt.getInstance('KYC_Doc_Keyword_Passport')?.Value__c;
        if(String.isNotBlank(voterKeyword) && dmName.contains(voterKeyword.toLowerCase())){
            keyword = voterKeyword.toLowerCase();
        } 
        else if(String.isNotBlank(passportKeyword) && dmName.contains(passportKeyword.toLowerCase())){
            keyword = passportKeyword.toLowerCase();
        } 
        else if(String.isNotBlank(drivingKeyword) && dmName.contains(drivingKeyword.toLowerCase())){
            keyword = drivingKeyword.toLowerCase();
        } 
        else {
            System.debug('No matching keyword for: ' + dmName);
            return;
        }
        System.debug('Reset keyword resolved: ' + keyword);
        List<Document_Details__c> docsToReset = [SELECT Id, Document_Master__r.Name FROM Document_Details__c WHERE Loan_Application__c = :loanId AND Applicant__c = :applicantId AND Active__c =true AND Consider_for_Loan_Application__c =true];

        List<Document_Details__c> updateList = new List<Document_Details__c>();

        for(Document_Details__c d : docsToReset){
            String name = d.Document_Master__r.Name != null  ? d.Document_Master__r.Name.toLowerCase()  : '';

            if(name.contains(keyword)){
                System.debug('Resetting → ' + name);
                d.KYC_Status__c = null;
                d.KYC_Verification_Status__c = null;
                updateList.add(d);
            }
        }

        if(!updateList.isEmpty()){
            update updateList;
        } else {
            System.debug('No documents matched for reset');
        }
    }


    @AuraEnabled
    public static Map<string, string> reUploadFile(Map<string, object> uploadParam) {
        Savepoint sp = Database.setSavepoint();
        try {
        System.debug('>>> reUploadFile called with params: ' + uploadParam);
        String objectAPIName = 'Document_Details__c';
            Set<Id> shareWithUserId = new Set<Id>();
            String contentDocId = (string) uploadParam.get('contentDocId');
            string docName = (string) uploadParam.get('docName');
            String filename = (string) uploadParam.get('filename');
            String docDetailId = (string) uploadParam.get('docDetailId');
            String docLinkRecodId = (string) uploadParam.get('docLinkRecodId');
            //Decimal latitude = (Decimal) uploadParam.get('latitude');
           // Decimal latitude = Decimal.valueOf( (String) uploadParam.get('latitude') );
           // Decimal longitude = (Decimal) uploadParam.get('longitude');
           // Decimal longitude = Decimal.valueOf( (String) uploadParam.get('longitude') );
            String salesDoc = (string ) uploadParam.get('salesDoc');
            String appId = (string ) uploadParam.get('appId');
            
            System.debug('>>> Input parameters:');
            System.debug('>>> contentDocId: ' + contentDocId);
            System.debug('>>> docDetailId: ' + docDetailId);
            System.debug('>>> filename: ' + filename);
            System.debug('>>> salesDoc: ' + salesDoc);
            
            // Validate required parameters
            if (String.isBlank(contentDocId)) {
                throw new AuraHandledException('Content Document ID is required');
            }
            
            if (String.isBlank(docDetailId)) {
                throw new AuraHandledException('Document Detail ID is required');
            }
            
            Map<string, string> result = new Map<string, string>();
            ContentVersion cv = new ContentVersion();
            ContentVersion cvRec = new ContentVersion();

            // Create ContentVersion and insert
            if(salesDoc != 'true'){
                // Query the ContentVersion record - add error handling
                List<ContentVersion> cvList = [
                    SELECT Id, /*VersionData,*/ title, FileType, ContentDocumentId 
                    FROM ContentVersion 
                    WHERE ContentDocumentId = :contentDocId 
                    AND IsLatest = true
                    LIMIT 1
                ];
                
                if (cvList.isEmpty()) {
                    throw new AuraHandledException('ContentVersion not found for ContentDocumentId: ' + contentDocId);
                }
                
                cvRec = cvList[0];
                System.debug('>>> ContentVersion found: ' + cvRec.Id);
                System.debug('>>> FileType: ' + cvRec.FileType);
            }

            // Query Document_Details__c with error handling
            List<Document_Details__c> ddList = [
                SELECT Id, name, Applicant__c, Loan_Application__c, Document_Master__c, RecordTypeId 
                FROM Document_Details__c 
                WHERE Id = :docDetailId 
                LIMIT 1
            ];
            
            if (ddList.isEmpty()) {
                throw new AuraHandledException('Document_Details__c not found for ID: ' + docDetailId);
            }
            
            Document_Details__c dd = ddList[0];
            System.debug('>>> Document_Details__c found: ' + dd);

            // Query and clone the Document Details record
            SObjectType objType = Schema.getGlobalDescribe().get(objectAPIName);
            Map<String, Schema.SObjectField> fields = objType.getDescribe().fields.getMap();
            String query = 'SELECT ' + String.join(fields.keySet(), ',') + ' FROM ' + objectAPIName + ' WHERE Id = :docDetailId';
            SObject record = Database.query(query);
            SObject clonedRecord = record.clone(false);
            
            // Update the cloned record with ContentDocumentId and increment Version_Number__c
            if(salesDoc != 'true'){
                System.debug('>>> Setting Content_Document_Id__c: ' + cvRec.ContentDocumentId);
                clonedRecord.put('Content_Document_Id__c', cvRec.ContentDocumentId);
                clonedRecord.put('Content_Version_Id__c', cvRec.Id);
                
                if(record != null){
                    System.debug('>>> Deleting existing addresses for docDetailId: ' + docDetailId);
                    List<Applicant_Address__c> addressTobeDelete = [
                        SELECT Id 
                        FROM Applicant_Address__c 
                        WHERE Document_Details__c = :docDetailId
                    ];
                    if(addressTobeDelete.size() > 0){
                        delete addressTobeDelete;
                    }
                }
            } else {
                clonedRecord.put('Content_Document_Id__c', '');
                clonedRecord.put('Status__c', 'Pending');
                deleteDocDetails(docName, appId, '', docDetailId);
            }
            
            // Handle Version_Number__c
            Decimal versionNumber = (Decimal) record.get('Version_Number__c');
            if (versionNumber == null) {
                versionNumber = 1;
            } else {
                versionNumber += 1;
            }
            System.debug('>>> Updated versionNumber: ' + versionNumber);
            clonedRecord.put('Version_Number__c', versionNumber);
            clonedRecord.put('Consider_for_Loan_Application__c', true);
            
            insert clonedRecord;
            String clonedRecordId = clonedRecord.Id;
            System.debug('>>> Cloned record created with ID: ' + clonedRecordId);

            // Update lookup relationships
            List<Document_Details__c> oldRecordsToUpdate = [
                SELECT Id, Document_Master__r.Document_Name__c, Document_Master__r.Document_Category__c, Document_Details_Lookup__c 
                FROM Document_Details__c 
                WHERE Document_Details_Lookup__c = :docDetailId
            ];
            
            if (!oldRecordsToUpdate.isEmpty()){
                for (Document_Details__c oldRecord : oldRecordsToUpdate) {
                    oldRecord.Document_Details_Lookup__c = clonedRecordId;
                    oldRecord.Active__c = false; 
                    oldRecord.Consider_for_Loan_Application__c = false;
                }
                update oldRecordsToUpdate;
            }
            
            List<Document_Details__c> oldRecord = [
                SELECT Id, Document_Master__r.Document_Name__c, Active__c, Document_Master__r.Document_Category__c, Document_Details_Lookup__c 
                FROM Document_Details__c 
                WHERE Id = :docDetailId
            ];
            
            oldRecord[0].Document_Details_Lookup__c = clonedRecordId;
            oldRecord[0].Active__c = false;
            oldRecord[0].Consider_for_Loan_Application__c = false;
            update oldRecord;
            resetKycForDocumentType(dd.Document_Master__c, dd.Applicant__c, dd.Loan_Application__c);
            
            // Build result map - IMPORTANT: Add ContentVersionId for OCR processing
            result.put('docName', docName + ' (' + oldRecord[0].Document_Master__r.Document_Category__c + ')');
            result.put('ContentDocumentId', contentDocId);
            result.put('FileType', cvRec.FileType);
            // result.put('base64', String.valueOf(cvRec.VersionData));
            result.put('docDetailId', clonedRecordId);
            result.put('success', 'true');
            result.put('uploadedFileName', cvRec.title);
            
            // *** CRITICAL FIX: Add ContentVersionId for OCR processing ***
            result.put('ContentVersionId', cvRec.Id);
            
            System.debug('>>> Final result: ' + result);
            System.debug('>>> ContentVersionId included: ' + cvRec.Id);
            
            return result;
            
        } catch(Exception e) {
            System.debug('Error in reUploadFile: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            Database.rollback(sp);
            
            // Return error in result format expected by frontend
            Map<string, string> errorResult = new Map<string, string>();
            errorResult.put('success', 'false');
            errorResult.put('error', e.getMessage());
            return errorResult;
        }


    }

    //method to delete document
    @AuraEnabled
    public static Boolean checkdocRequired(String docDetailId) {
        Boolean result = false; 
        try {
            // Fetch document details
            List<Document_Details__c> docDetail = [SELECT Id, Content_Document_Id__c, Is_Required__c  FROM Document_Details__c WHERE Id = :docDetailId];
            // Ensure we have a result before accessing list elements
            if (!docDetail.isEmpty()) {
                result = docDetail[0].Is_Required__c;
            }
        } catch (Exception e) {
            System.debug('Error in checkdocRequired: ' + e.getMessage());
        }    
        return result;
    }

    //method to delete document
    @AuraEnabled
    public static Boolean deleteDocumentByDocDetailId(String docDetailId, Boolean retainDocDetailsRec) {
        Boolean result = false;
        try {
            // Fetch document details
            List<Document_Details__c> docDetail = [
                SELECT Id, Content_Document_Id__c, Screening_Status__c, Verification_Status__c 
                FROM Document_Details__c 
                WHERE Id = :docDetailId
            ];
            if(docDetail[0].Content_Document_Id__c != null){
                docDetail[0].Content_Document_Id__c = null;
                docDetail[0].Screening_Status__c = 'Pending';
                docDetail[0].Verification_Status__c = 'Pending';
                update docDetail;
                DELETE [SELECT Id FROM ContentDocument WHERE Id =:docDetail[0].Content_Document_Id__c];
            }
            System.debug('docDetail: ' + docDetail);
    
            if(!retainDocDetailsRec){
                if (!docDetail.isEmpty()) {
                    delete docDetail;  // Deletes the record
                    result = true;
                }
            }
            else{result = true;}
            
        } catch (Exception e) {
            System.debug('Error occurred while deleting the record: ' + e.getMessage());
            System.debug('StackTrace: ' + e.getStackTraceString());
        }

        return result;
    }

    //method to delete content document
@TestVisible
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
    public static DocumentDetailsWrapper getLatestDocumentDetails(String docDetailId) {
        if (String.isBlank(docDetailId)) {
            return null;
        }
        
        // 1) Fetch the Document_Details__c record to get the ContentDocumentId
        Document_Details__c dde = [
            SELECT Id, Name, Content_Document_Id__c,Is_manual_masking_confirmed__c
            FROM Document_Details__c
            WHERE Id = :docDetailId
            LIMIT 1
        ];
        if (dde.Content_Document_Id__c == null) {
            return null;
        }
        
        // 2) Find the most recent ContentVersion for that ContentDocument
        ContentVersion cv = [
            SELECT Id
                 , ContentDocumentId
                 , FileExtension
                 , Title
            FROM ContentVersion
            WHERE ContentDocumentId = :dde.Content_Document_Id__c
            ORDER BY VersionNumber DESC
            LIMIT 1
        ];
        
        // 3) Populate and return our serializable wrapper
        DocumentDetailsWrapper wrapper = new DocumentDetailsWrapper();
        wrapper.contentDocumentId = cv.ContentDocumentId;
        wrapper.contentVersionId  = cv.Id;
        wrapper.fileType          = cv.FileExtension;
        wrapper.docName           = dde.Name;
        wrapper.isManualMasked    = dde.Is_manual_masking_confirmed__c; // Placeholder; set based on your logic
        return wrapper;
    }

    @AuraEnabled
    public static Id getCompressedDocId( String contentVersionId,String contentDocId,String docCategory) {
        try {

            ContentVersion cv = [SELECT Id,  title, FileType, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];
            //return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1].ContentDocumentId;
            List<ContentDocument> cDList = new List<ContentDocument>();
             cDList = [SELECT Id,OwnerId FROM ContentDocument WHERE Id =:cv.ContentDocumentId LIMIT 1];
            System.debug('contentVersionId'+cv);
            System.debug('title'+cv.ContentDocumentId);
            System.debug('doc category'+docCategory);
            System.debug('contentDocId'+contentDocId);
            if(!cDList.isEmpty()){
               cDList[0].OwnerId = UserInfo.getUserId();
            }
            UPDATE cDList;
            List<Document_Details__c> docDetails = [SELECT Id, Content_Document_Id__c FROM Document_Details__c WHERE Content_Document_Id__c = :contentDocId AND Document_Details__c =:docCategory LIMIT 1];
            if(!docDetails.isEmpty()){

            List<ContentDocumentLink> cdlDelete = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :contentDocId AND LinkedEntityId =:docDetails[0].Id LIMIT 1];
            if(!cdlDelete.isEmpty())
            {
                delete cdlDelete;
            }
            docDetails[0].Content_Document_Id__c = cv.ContentDocumentId;
            System.debug(' doc detail id>'+docDetails[0].Id);
            UPDATE docDetails;
             ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.LinkedEntityId = docDetails[0].Id;
                cdl.ContentDocumentId = cv.ContentDocumentId;
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                insert cdl;
               // System.debug('>>> C
            }
            return cv.ContentDocumentId;
        } catch (Exception e) {
            System.debug('Error in getCompressedDocId: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /** Simple DTO for LWC consumption */
    public class DocumentDetailsWrapper {
        @AuraEnabled public Id    contentDocumentId;
        @AuraEnabled public Id    contentVersionId;
        @AuraEnabled public String fileType;
        @AuraEnabled public String docName;
        @AuraEnabled public Boolean isManualMasked;
    }

}