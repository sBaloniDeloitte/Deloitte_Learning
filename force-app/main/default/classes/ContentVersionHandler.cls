public class ContentVersionHandler {

    public static void checkFirstPublishLocation(List<ContentVersion> contentVersions) {
        Set<Id> locationIds = new Set<Id>();
        
        for (ContentVersion cv : contentVersions) {
            if (cv.FirstPublishLocationId != null) {
                locationIds.add(cv.FirstPublishLocationId);
            }
        }

        if (!locationIds.isEmpty()) {
            List<Technical_Evaluation__c> techList = [
                SELECT Id
                FROM Technical_Evaluation__c
                WHERE Id IN :locationIds
            ];
            
            List<Legal__c> legalList = [
                SELECT Id
                FROM Legal__c
                WHERE Id IN :locationIds
            ];

            Set<Id> matchingLocationIds = new Set<Id>();

            for (Technical_Evaluation__c tech : techList) {
                matchingLocationIds.add(tech.Id);
            }

            for (Legal__c legal : legalList) {
                matchingLocationIds.add(legal.Id);
            }

            for (ContentVersion cv : contentVersions) {
                if (cv.FirstPublishLocationId != null && matchingLocationIds.contains(cv.FirstPublishLocationId)) {
                    // cv.addError('File uploads via Notes & Attachments are not allowed.');
                }
            }
        }
    }

    public static void afterInsert (List<ContentVersion> newList) {
        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
        List<Document_Details__c> docDetailsToInsert = new List<Document_Details__c>();
        Set<String> contentDocIds = new Set<String>();
        List<Id> cvIds = new List<Id>();
        for(ContentVersion conVerIter : newList) {
            contentDocIds.add(conVerIter.ContentDocumentId);
        }
        
        if(contentDocIds.size() > 0) {
            List<ContentDocumentLink> cdlForProject = [SELECT Id, ContentDocumentId, LinkedEntityId,ContentDocument.Title,LinkedEntity.Name FROM ContentDocumentLink 
		                                               WHERE ContentDocumentId IN :contentDocIds
                                                       AND LinkedEntityId IN (SELECT Id FROM Builder_Project_Document__c)];
            Map<String,ContentVersion> docIdToVersionMap = new Map<String,ContentVersion>();
            for(ContentVersion cv : newList){
                docIdToVersionMap.put(cv.ContentDocumentId,cv);
            }
            List<ContentDocumentLink> cdlList = [Select Id, LinkedEntityId,ContentDocument.Title,ContentDocumentId, LinkedEntity.Name from ContentDocumentLink where ContentDocumentId in: contentDocIds];
            for(ContentDocumentLink cdl: cdlList){
                if(cdl.LinkedEntity.Name == '12 months bank statement'){
                    if(docIdToVersionMap.containsKey(cdl.ContentDocumentId)){
                        ContentVersion cv = docIdToVersionMap.get(cdl.ContentDocumentId);
                        System.debug('cv.FileType=:'+cv.FileType);
                        if(cv.FileType != 'PDF'){
                            cv.addError('Cannot change file type of 12 months bank statement. It must be pdf only');
                        }
                    }
                }
            }
            for(ContentDocumentLink cdl: cdlForProject){
                System.debug('cdl.LinkedEntityId.getSObjectType():>> ' + cdl.LinkedEntityId.getSObjectType());
                if (cdl.LinkedEntityId.getSObjectType() == Builder_Project_Document__c.SObjectType) {
                    System.debug('File linked to Builder_Project_Document__c: ' + cdl.LinkedEntityId);
                     if(docIdToVersionMap.containsKey(cdl.ContentDocumentId)){
                        cvIds.add(docIdToVersionMap.get(cdl.ContentDocumentId).Id);
                    }
                }
            }
            if (!cvIds.isEmpty()) {
                System.enqueueJob(new HL_UploadFileGenericHandler(cvIds,cdlForProject));
            }
        }
        for (ContentVersion cv : newList) {
            system.debug('cv.Merged_Document__c   '+cv.Merged_Document__c);
            system.debug('cv.Loan_Application__c   '+cv.Loan_Application__c);
            system.debug('cv.Merged_Document_Detail__c   '+cv.Merged_Document_Detail__c);
            if ((cv.Merged_Document__c != null && (cv.Merged_Document__c == 'Mandatory' || cv.Merged_Document__c == 'Non-Mandatory')) && cv.Loan_Application__c != null && cv.Merged_Document_Detail__c != null) {
            //(cv.Merged_Document__c == 'Mandatory' || cv.Merged_Document__c == 'Non-Mandatory')
                linksToInsert.add(new ContentDocumentLink(
                    ContentDocumentId = cv.ContentDocumentId,
                    LinkedEntityId    = cv.Loan_Application__c,
                    ShareType         = 'V',         
                    Visibility        = 'AllUsers'   
                ));

                docDetailsToInsert.add(new Document_Details__c(
                    Content_Document_Id__c   = cv.ContentDocumentId,
                    Merged_Document_Detail__c = cv.Merged_Document_Detail__c,
                    Esign_Document__c        = true, 
                    Status__c                = 'Uploaded',
                    Name                     = cv.Title,
                    Document_Type__c         = 'Merged Document',
                    Loan_Application__c      = cv.Loan_Application__c,
                    Uploaded_Date_Time__c    = System.now(),
                    Description__c           = cv.Merged_Document__c
                ));
            }
        }

        if (!linksToInsert.isEmpty()) {
            insert linksToInsert;
        }

        if (!docDetailsToInsert.isEmpty()) {
            insert docDetailsToInsert;
        }
    }
}