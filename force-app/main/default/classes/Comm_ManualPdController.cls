public class Comm_ManualPdController {
    @AuraEnabled
    public static String saveManualPd(String recordId, List<String> docIds, String remarks, String disposition, String pdPerformedBy) {
        String res = 'fail';
        try{
            String pdRecordType = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Personal_Discussion');
            String parentRecId = Utility.getPDParentRecord(recordId);
        
            
            Application_Verification__c appVerificationq = new Application_Verification__c();
            appVerificationq.RecordTypeId = pdRecordType;
            //appVerificationq.Applicant__c = applicantId;
            appVerificationq.Loan_Application__c = recordId;
            appVerificationq.Disposition__c = disposition;
            appVerificationq.Any_Remarks_Reasons__c = remarks;
            appVerificationq.Personal_Discussion_Type__c = 'Manual';
            appVerificationq.Parent_FCU__c = parentRecId;
            appVerificationq.PD_Performed_By__c = pdPerformedBy;
            insert appVerificationq;
            List<Document_Details__c> insertDocs = new List<Document_Details__c>();
           

            for(String iterDocId : docIds) {
                Document_Details__c iterDoc = new Document_Details__c();
                iterDoc.Application_Verification__c = appVerificationq.id;
                iterDoc.Loan_Application__c = recordId;
                iterDoc.Content_Document_Id__c = iterDocId;
                iterDoc.Status__c = 'Uploaded';
                iterDoc.Name = 'Manual PD Image';
                insertDocs.add(iterDoc);
                            System.debug('Loan_Application__c value => ' + iterDoc.Loan_Application__c);

            }

            insert insertDocs;
            res = 'success';
        }
        catch(Exception e) {
             System.debug('saveManualPd failed: ' + e.getMessage());
    System.debug('Stacktrace: ' + e.getStackTraceString());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'Comm_ManualPdController', '', '') });
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
        return res;
    }
    
    @AuraEnabled
    public static List<DocumentWrapper> getDocuments(List<String> condocIds) {
        List<DocumentWrapper> lstWrap = new List<DocumentWrapper>();
        for(ContentVersion iterConVer : [SELECT Id, ContentDocumentId, VersionData, FileExtension , PathOnClient 
                                         FROM ContentVersion
                                         WHERE ContentDocumentId IN :condocIds
                                         ORDER BY CreatedDate DESC
                                        ]){
                                            DocumentWrapper iterDoc = new DocumentWrapper();
                                            iterDoc.docName = iterConVer.PathOnClient;
                                            iterDoc.docExt = iterConVer.FileExtension;
                                            iterDoc.docVersiondata = EncodingUtil.base64Encode(iterConVer.VersionData);
                                            iterDoc.docVersionId = iterConVer.Id;
                                            iterDoc.docContDocId = iterConVer.ContentDocumentId;
                                            lstWrap.add(iterDoc);
                                        }
        return lstWrap;
    }
    
    @AuraEnabled
    public static List<AVWrapper> getAllManualPds(String recordId,String applicantId) {
        List<AVWrapper> returnWrap = new List<AVWrapper>();
         String pdRecordType = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Personal_Discussion');
        List<Application_Verification__c> lstAV = [SELECT id,Disposition__c,Any_Remarks_Reasons__c,CreatedBy.name, PD_Performed_By__c, PD_Performed_By__r.Name,
                                                   Createddate,Applicant__r.Name,Applicant__r.Customer_Type__c,Applicant__r.Customer_Profile__c,Personal_Discussion_Type__c
                                                   FROM Application_Verification__c WHERE Loan_Application__c =:recordId AND
                                                   recordTypeId =: pdRecordType AND Personal_Discussion_Type__c = 'Manual' ORDER BY createddate DESC];
        if(lstAV.size() > 0) {
            for(Application_Verification__c iterObj : lstAV) {
                AVWrapper iter = new AVWrapper();
                iter.initiatedBy = iterObj.CreatedBy.name+' '+ iterObj.Createddate.format('yyyy/MM/dd hh:mm:ss');
                iter.notes = iterObj.Any_Remarks_Reasons__c;
                iter.disposition = iterObj.Disposition__c;
                iter.appVeriId = iterObj.Id;
                iter.pdPerformedBy = iterObj.PD_Performed_By__r.Name;
                iter.customerType = iterObj.Applicant__r.Customer_Type__c;
                iter.customerProfile = iterObj.Applicant__r.Customer_Profile__c;
                iter.pdType = iterObj.Personal_Discussion_Type__c;
                iter.name = iterObj.Applicant__r.Name;
                iter.initiatedAt = iterObj.Createddate.format('yyyy/MM/dd hh:mm:ss');
                returnWrap.add(iter);
            }
        }
        return returnWrap;
    }
    @AuraEnabled
    public static List<String> getAllDocConIds(String appVerId) {
        List<String> conDocsId = new List<String>();
        List<Document_Details__c> lstDocs = [SELECT id,Content_Document_Id__c FROM  Document_Details__c WHERE Application_Verification__c =:appVerId];
        if(lstDocs.size() > 0) {
            for(Document_Details__c iterDocs : lstDocs) {
                conDocsId.add(iterDocs.Content_Document_Id__c);
            }
        }
        return conDocsId;
    }
    @AuraEnabled
    public static String saveDocsOnAV(List<String> condocIds, String appVerId, String recordId) {
        String res = 'fail';
        try{
        List<Document_Details__c> insertDocs = new List<Document_Details__c>();
            for(String iterDocId : condocIds) {
                Document_Details__c iterDoc = new Document_Details__c();
                iterDoc.Application_Verification__c = appVerId;
                iterDoc.Loan_Application__c = recordId;
                iterDoc.Content_Document_Id__c = iterDocId;
                iterDoc.Status__c = 'Uploaded';
                iterDoc.Name = 'Manual PD Image';
                insertDocs.add(iterDoc);
            }
            insert insertDocs;
            res = 'success';
        }
        catch(Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'Comm_ManualPdController', '', '') });
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
        
        return res;
    }

    @AuraEnabled
    public static String deleteDocument(String contentDocId) {
        String res = 'fail';
        try{
            List<Document_Details__c> docId = [SELECT id FROM Document_Details__c WHERE Content_Document_Id__c =: contentDocId];
        if(docId.size() > 0) {
            delete docId;
            delete [SELECT Id from ContentDocument where Id =: contentDocId];
            res = 'success';
        }
        }
        catch(Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'Comm_ManualPdController', '', '') });
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
        return res;
    }
    @AuraEnabled
    public static Id saveApplicationVerificationPd(String loanAppId,String applicantId){
        String pdRecordType = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Personal_Discussion');
            //String parentRecId = Utility.getPDParentRecord(recordId);
            
            Application_Verification__c appVerificationq = new Application_Verification__c();
            appVerificationq.RecordTypeId = pdRecordType;
            //appVerificationq.Applicant__c = applicantId;
            appVerificationq.Loan_Application__c = loanAppId;
            //appVerificationq.Disposition__c = disposition;
           // appVerificationq.Any_Remarks_Reasons__c = remarks;
            appVerificationq.Personal_Discussion_Type__c = 'Manual';
            //appVerificationq.Parent_FCU__c = parentRecId;
           // appVerificationq.PD_Performed_By__c = pdPerformedBy;
           appVerificationq.Applicant__c = applicantId;
            insert appVerificationq;
            return appVerificationq.Id;
    }
    
    @AuraEnabled
    public static Boolean checkIfMobileNumber(String recordId,String appVeriId,String mobileNumer) {
        Boolean isMatch = false;
        List<Application_Applicant__c> lstApps = [SELECT id, Mobile_Number__c FROM Application_Applicant__c WHERE Loan_Application__c =:recordId];
        if(lstApps.size() > 0) {
            for(Application_Applicant__c iterApp : lstApps) {
                if(String.isNotBlank(iterApp.Mobile_Number__c) && iterApp.Mobile_Number__c == mobileNumer) {
                    return true;
                }
            }
        }
        List<Application_Verification__c> lstAppVeri = [SELECT id,Trade_Reference_Mobile_Number__c FROM Application_Verification__c 
                                                        WHERE Parent_FCU__c=:appVeriId AND RecordType.Name = 'Trade Reference'];
        if(lstAppVeri.size() > 0) {
            for(Application_Verification__c iterAppVe : lstAppVeri) {
                if(iterAppVe.Trade_Reference_Mobile_Number__c != null && String.valueOf(iterAppVe.Trade_Reference_Mobile_Number__c) == mobileNumer) {
                    return true;
                }
            }
        }
        return isMatch;
    }
    public class DocumentWrapper {
        @AuraEnabled public String docName;
        @AuraEnabled public String docExt;
        @AuraEnabled public String docVersiondata;
        @AuraEnabled public String docVersionId;
        @AuraEnabled public String docContDocId;
    }
    
    public class AVWrapper {
        @AuraEnabled public String initiatedBy;
        @AuraEnabled public String notes;
        @AuraEnabled public String disposition;
        @AuraEnabled public String appVeriId;
        @AuraEnabled public String pdPerformedBy;
        @AuraEnabled public String customerType;
        @AuraEnabled public String customerProfile;
        @AuraEnabled public String pdType;
        @AuraEnabled public String name;
        @AuraEnabled public String initiatedAt;
    }
    @AuraEnabled(cacheable=true)
    public static String getCurrentUserInfo() {
        Id currentUserId = UserInfo.getUserId();        
        User currentUser = [SELECT Name, CreatedDate FROM User WHERE Id = :currentUserId LIMIT 1];
        //String userInfo = currentUser.Name + ',' + currentUser.CreatedDate.format();
        String userInfo = currentUser.Name;
        return userInfo;
    }

    @AuraEnabled
    public static void updatePdPerformedBy(Id appVeriId, Id userId) {
        Application_Verification__c appVeri = [SELECT Id,PD_Performed_By__c FROM Application_Verification__c WHERE Id = :appVeriId LIMIT 1];
        appVeri.PD_Performed_By__c = userId;
        update appVeri;
    }
    
    @AuraEnabled
    public static Boolean checkIfAlreadyInitiatedPd(String loanId, String applicantId, String pdType) {
        Boolean isInitiated = false;
        String pdRecordType = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Personal_Discussion');
        List<Application_Verification__c> appVeri = [SELECT Id FROM Application_Verification__c WHERE RecordTypeId = :pdRecordType AND 
                                              Loan_Application__c =: loanId AND Applicant__c =: applicantId AND
                                                    Personal_Discussion_Type__c =:pdType];
        if(appVeri.size() > 0) {
            isInitiated = true;
        }
        return isInitiated;
    }
}