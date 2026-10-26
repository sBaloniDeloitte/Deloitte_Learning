public with sharing class COMM_DocmtDetailsTriggerImplementation {

    public static void updateInstitutionIdAndInsertContDocLink(List<Document_Details__c> documentList) {

        Set<String> transactionIds    = new Set<String>();
        Set<String> linkedReferences  = new Set<String>();
        Map<Id, String> docToBankMap  = new Map<Id, String>();   // docId → Bank_Name__c (XML records)

        for(Document_Details__c doc : documentList){
            if(doc.Transaction_ID__c != null){
                transactionIds.add(doc.Transaction_ID__c);
            }
            if(doc.Linked_Reference__c != null){
                linkedReferences.add(doc.Linked_Reference__c);
            }
            if(doc.Bank_Name__c != null && doc.Name == '12 months bank statement'){
                docToBankMap.put(doc.Id, doc.Bank_Name__c);
            }
        }

        Set<String> bankNames = new Set<String>(docToBankMap.values());
        Map<String, Bank_Branch_Master__c> bankNameToBranchMap = new Map<String, Bank_Branch_Master__c>();
        if(!bankNames.isEmpty()){
            for(Bank_Branch_Master__c branch : [
                SELECT Id, Onemoney_Bank_Name__c, Institution_Id__c
                FROM Bank_Branch_Master__c
                WHERE Onemoney_Bank_Name__c IN :bankNames
            ]){
                bankNameToBranchMap.put(branch.Onemoney_Bank_Name__c, branch);
            }
        }
        System.debug('bankNameToBranchMap ===> ' + bankNameToBranchMap);


        Map<String, Document_Details__c> keyToPdfDocMap  = new Map<String, Document_Details__c>();
        Map<String, Document_Details__c> keyToJsonDocMap = new Map<String, Document_Details__c>();

        if(!transactionIds.isEmpty()){

            for(Document_Details__c pdfDoc : [
                SELECT Id, Name, Transaction_ID__c, Linked_Reference__c, Content_Document_Id__c
                FROM Document_Details__c
                WHERE Transaction_ID__c IN :transactionIds
                AND Name = '12 months bank statement-PDF'
            ]){
                String compositeKey = buildKey(pdfDoc.Transaction_ID__c, pdfDoc.Linked_Reference__c);
                keyToPdfDocMap.put(compositeKey, pdfDoc);
            }

            for(Document_Details__c jsonDoc : [
                SELECT Id, Name, Transaction_ID__c, Linked_Reference__c, Content_Document_Id__c
                FROM Document_Details__c
                WHERE Transaction_ID__c IN :transactionIds
                AND Name = '12 months bank statement - JSON'
            ]){
                String compositeKey = buildKey(jsonDoc.Transaction_ID__c, jsonDoc.Linked_Reference__c);
                keyToJsonDocMap.put(compositeKey, jsonDoc);
            }
        }

        System.debug('keyToPdfDocMap  ===> ' + keyToPdfDocMap);
        System.debug('keyToJsonDocMap ===> ' + keyToJsonDocMap);

        List<Document_Details__c> docsToUpdate = new List<Document_Details__c>();

        for(Document_Details__c doc : documentList){

            if(doc.Name == '12 months bank statement' || doc.Name == '12 months bank statement - JSON'){

                Bank_Branch_Master__c branch     = bankNameToBranchMap.get(doc.Bank_Name__c);
                Decimal  institutionId           = (branch != null) ? branch.Institution_Id__c : null;
                Id       branchId                = (branch != null) ? branch.Id : null;

                String compositeKey = buildKey(doc.Transaction_ID__c, doc.Linked_Reference__c);

                // for legacy records (only one account per consent handle back then).
                Document_Details__c matchedPdf  = keyToPdfDocMap.get(compositeKey);
                Document_Details__c matchedJson = keyToJsonDocMap.get(compositeKey);

                Id pdfContentId  = (matchedPdf  != null) ? matchedPdf.Content_Document_Id__c  : null;
                Id jsonContentId = (matchedJson != null) ? matchedJson.Content_Document_Id__c : null;

                docsToUpdate.add(new Document_Details__c(
                    Id                  = doc.Id,
                    Institution_Id__c   = institutionId,
                    Bank_Branch_Master__c = branchId,
                    AA_PDF_ContentId__c  = pdfContentId,
                    AA_JSON_ContentId__c = jsonContentId
                ));

            } else if(doc.Name == '12 months bank statement-PDF'){
                docsToUpdate.add(new Document_Details__c(
                    Id               = doc.Id,
                    Process_Name__c  = 'Income Bank Statement' 
                ));
            }
        }

        System.debug('docsToUpdate ===> ' + docsToUpdate);

        if(!docsToUpdate.isEmpty()){
            update docsToUpdate;
        }

        for(Document_Details__c dd : docsToUpdate){
            //utility.validateConditions((Id)dd.Id, 'internal bsa validation');
        }

        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
        for(Document_Details__c iterDocDetails : documentList){
            if(iterDocDetails.Content_Document_Id__c != null){
                ContentDocumentLink cdl    = new ContentDocumentLink();
                cdl.LinkedEntityId         = iterDocDetails.Id;
                cdl.ContentDocumentId      = iterDocDetails.Content_Document_Id__c;
                cdl.ShareType              = 'V';
                cdl.Visibility             = 'AllUsers';
                linksToInsert.add(cdl);
            }
        }

        System.debug('linksToInsert ===> ' + linksToInsert);

        if(!linksToInsert.isEmpty()){
            insert linksToInsert;
        }
    }

    private static String buildKey(String transactionId, String linkedReference){
        if(String.isBlank(transactionId)) return '';
        if(String.isBlank(linkedReference)) return transactionId;
        return transactionId + '||' + linkedReference;
    }


    public static void updateContentDocumentIdBasedOnInternalBSA(List<Document_Details__c> aaList){
        List<Document_Details__c> recordsToUpdate = new List<Document_Details__c>();

        for(Document_Details__c doc : aaList){
            if(doc.Is_Internal_BSA__c != null){
                String toggleValue = doc.Is_Internal_BSA__c.toLowerCase();
                Document_Details__c updatedDoc = new Document_Details__c(Id = doc.Id);

                if(toggleValue == 'yes'){
                    Id temp = doc.Content_Document_Id__c;
                    updatedDoc.Content_Document_Id__c = (doc.AA_JSON_ContentId__c != null)
                        ? doc.AA_JSON_ContentId__c
                        : doc.AA_XML_ContentId__c;
                    updatedDoc.AA_XML_ContentId__c = temp;
                    recordsToUpdate.add(updatedDoc);
                } else if(toggleValue == 'no'){
                    updatedDoc.Content_Document_Id__c = doc.AA_XML_ContentId__c;
                    recordsToUpdate.add(updatedDoc);
                }
            }
        }

        if(!recordsToUpdate.isEmpty()){
            update recordsToUpdate;
        }
    }

    public static void shareBSAExcel(List<Document_Details__c> documentDetailsList){
        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
        for(Document_Details__c iterDocDetails : documentDetailsList){
            ContentDocumentLink cdl    = new ContentDocumentLink();
            cdl.LinkedEntityId         = iterDocDetails.Id;
            cdl.ContentDocumentId      = iterDocDetails.Content_Document_Id__c;
            cdl.ShareType              = 'V';
            cdl.Visibility             = 'AllUsers';
            linksToInsert.add(cdl);
        }
        if(linksToInsert.size() > 0){
            insert linksToInsert;
        }
    }

    public static void shareBSACallback(List<Document_Details__c> documentDetailsList){
        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
        for(Document_Details__c iterDocDetails : documentDetailsList){
            ContentDocumentLink cdl    = new ContentDocumentLink();
            cdl.LinkedEntityId         = iterDocDetails.Id;
            cdl.ContentDocumentId      = iterDocDetails.Content_Document_Id__c;
            cdl.ShareType              = 'V';
            cdl.Visibility             = 'AllUsers';
            linksToInsert.add(cdl);
        }
        if(linksToInsert.size() > 0){
            insert linksToInsert;
        }
    }

    public static void updateContentDocumentId(List<Document_Details__c> documentDetailsList){
        Map<String, Id> nameToContentDocumentIdMap = new Map<String, Id>();
        Set<Id> appIds = new Set<Id>();
        for(Document_Details__c doc : documentDetailsList){
            nameToContentDocumentIdMap.put(doc.Name, doc.Content_Document_Id__c);
            appIds.add(doc.Applicant__c);
        }
        if(!nameToContentDocumentIdMap.isEmpty()){
            List<Document_Details__c> documentsToUpdate = [
                SELECT Id, Name, Content_Document_Id__c, Status__c, Document_Details__c
                FROM Document_Details__c
                WHERE Name IN :nameToContentDocumentIdMap.keySet()
                AND Applicant__c IN :appIds
                AND Document_Details__c != 'Additional Documents'
                AND Document_Master__r.Stage__c = 'Sales login'
                AND Document_Master__r.Document_Type__c != null
            ];
            for(Document_Details__c doc : documentsToUpdate){
                doc.Content_Document_Id__c = doc.Content_Document_Id__c == null
                    ? nameToContentDocumentIdMap.get(doc.Name)
                    : doc.Content_Document_Id__c;
                doc.Status__c = 'Uploaded';
            }
            update documentsToUpdate;
        }
    }

    public static void updateScreeningStatusForRelatedDocs(Set<String> contentDocIds, Set<Id> excludeIds){
        List<Document_Details__c> toUpdate = new List<Document_Details__c>();
        List<Document_Details__c> relatedDocs = [
            SELECT Id, Screening_Status__c, Content_Document_Id__c, Verification_Status__c
            FROM Document_Details__c
            WHERE Content_Document_Id__c IN :contentDocIds
            AND Id NOT IN :excludeIds
            AND Screening_Status__c != 'Screened'
        ];
        for(Document_Details__c doc : relatedDocs){
            doc.Screening_Status__c = 'Screened';
            doc.Verification_Status__c = 'Verified';
            toUpdate.add(doc);
        }
        if(!toUpdate.isEmpty()){
            update toUpdate;
        }
    }

    public static void updateAAStatus(Map<String, String> docToTransactionIdMap){
        List<Integration_Details__c> integrationList = [
            SELECT Id, Account_Aggregator_Consent_Status__c, Account_Aggregator_Consent_Handler__c
            FROM Integration_Details__c
            WHERE Account_Aggregator_Consent_Handler__c IN :docToTransactionIdMap.values()
        ];
        Map<String, String> transactionToStatus = new Map<String, String>();
        for(Integration_Details__c inte : integrationList){
            transactionToStatus.put(inte.Account_Aggregator_Consent_Handler__c, inte.Account_Aggregator_Consent_Status__c);
        }
        List<Document_Details__c> docListToUpdate = new List<Document_Details__c>();
        for(String docId : docToTransactionIdMap.keySet()){
            if(transactionToStatus.containsKey(docToTransactionIdMap.get(docId))){
                Document_Details__c docToUpdate = new Document_Details__c(
                    Id = docId,
                    Account_Aggregator_Status__c = transactionToStatus.get(docToTransactionIdMap.get(docId))
                );
                docListToUpdate.add(docToUpdate);
            }
        }
        if(docListToUpdate.size() > 0){
            update docListToUpdate;
        }
    }

    public static void deleteDocumentDetailsRecord(List<Document_Details__c> docList){
        Set<String> transactionIds = new Set<String>();
        for(Document_Details__c doc : docList){
            if(doc.Transaction_ID__c != null){
                transactionIds.add(doc.Transaction_ID__c);
            }
        }
        if(transactionIds.isEmpty()) return;

        List<Document_Details__c> recordsToDelete = [
            SELECT Id
            FROM Document_Details__c
            WHERE Transaction_ID__c IN :transactionIds
            AND Content_Document_Id__c = null
        ];
        if(!recordsToDelete.isEmpty()){
            delete recordsToDelete;
        }
    }

    public static void updateActualFileName(Set<String> updatedConDocIdSet){
        Map<Id, ContentVersion> conDocIdToCVMap = new Map<Id, ContentVersion>();
        for(ContentVersion cv : [
            SELECT Id, ContentDocumentId, PathOnClient
            FROM ContentVersion
            WHERE ContentDocumentId IN :updatedConDocIdSet
        ]){
            conDocIdToCVMap.put(cv.ContentDocumentId, cv);
        }
        System.debug('conDocIdToCVMap: ' + conDocIdToCVMap);
        if(!conDocIdToCVMap.isEmpty()){
            List<Document_Details__c> docList = [
                SELECT Id, File_Name__c, Content_Document_Id__c
                FROM Document_Details__c
                WHERE Content_Document_Id__c IN :updatedConDocIdSet
            ];
            for(Document_Details__c doc : docList){
                if(conDocIdToCVMap.containsKey(doc.Content_Document_Id__c)){
                    String path = conDocIdToCVMap.get(doc.Content_Document_Id__c).PathOnClient;
                    doc.File_Name__c = path.length() <= 100 ? path : '';
                }
            }
            update docList;
        }
    }
}