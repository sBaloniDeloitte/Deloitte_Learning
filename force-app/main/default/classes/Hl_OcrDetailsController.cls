public class Hl_OcrDetailsController {

    @AuraEnabled(cacheable=true) // using this to get master ocr steps records
    public static List<Charges_Insurance_Master__c> getOcrRecordsByOcrId(String ocrId) {
        return [Select Id, Name,RecordType.Name, RecordTypeId, Is_Active__c, OCR_ID__c, Contributor__c, OCR_Description__c, OCR_Type__c, 
        Customer_Portion__c, Step_Sequence__c, Header_Id__c, Detail_Id__c, Customer_Contribution__c,
        Financer_Contribution__c from Charges_Insurance_Master__c where RecordType.Name = 'OCR Definition' AND OCR_ID__c =:ocrId AND Parent_OCR__c!=null
        ORDER BY Step_Sequence__c ASC];
    }

    private static String returnRecordIdMultiProd(String recordId){ //Armani : just to keep the logic separate in another method
        Opportunity loanApp = [SELECT Id,Split_Parent_Loan_Application__c,Loan_Hierarchy__c FROM Opportunity WHERE Id=:recordId ];
        String requiredLoanId = loanApp.Split_Parent_Loan_Application__c!=null && loanApp.Loan_Hierarchy__c == 'Child' ? loanApp.Split_Parent_Loan_Application__c : recordId; //for multiProd>> discussed with Gaurav
        return requiredLoanId;
    }

    @AuraEnabled //using this to get transactional ocr step records
    public static List<Loan_Transaction__c> getOcrRecordsTransactionalByOcrId(String ocrId, String recordId) {
        String requiredLoanId = returnRecordIdMultiProd(recordId);
        return [Select Id, Name,RecordType.Name, RecordTypeId, OCR_ID__c, Contributor__c, OCR_Description__c, OCR_Type__c, 
        Customer_Portion__c, Step_Sequence__c, Customer_Contribution__c,
        Financer_Contribution__c from Loan_Transaction__c where Loan_Application__c =:requiredLoanId AND isParent__c = false AND RecordType.Name = 'OCR Steps' AND OCR_ID__c =:ocrId AND OCR_Definition__c!=null
        ORDER BY Step_Sequence__c ASC];
    }

    @AuraEnabled(cacheable=true)
    public static Loan_Transaction__c getOcrLoanTransaction(Id recordId) {
        String recordTypeId = Utility.getRecordTypeIdByDeveloperName('Loan_Transaction__c', 'OCR');
        String requiredLoanId = returnRecordIdMultiProd(recordId);
        List<Loan_Transaction__c> transactions = [
            SELECT Id, OCR_Description__c, Customer_Portion__c, OCR_Type__c,
                Total_Demand__c, Total_OCR_Receivable__c,
                Total_Demand_Received__c, Total_OCR_Received__c, OCR_ID__c, OCR_Master__c
            FROM Loan_Transaction__c
            WHERE Loan_Application__c = :requiredLoanId AND RecordTypeId = :recordTypeId
            LIMIT 1
        ];
        
        return transactions.isEmpty() ? null : transactions[0];
    }

    @AuraEnabled
    public static List<Map<String, Object>> getOcrCaptureTransaction(Id recordId) {
        String recordTypeId = Utility.getRecordTypeIdByDeveloperName('Loan_Transaction__c', 'OCR_Capture_Transaction');
        String requiredLoanId = returnRecordIdMultiProd(recordId);
        List<Loan_Transaction__c> transactions = [
            SELECT Id,  OCR_ID__c, Customer_Contribution__c, Step_Sequence__c, Total_OCR_Receivable__c, OCR_Type__c,
            Total_Demand__c, OCR_Description__c, Customer_Portion__c, Financer_Contribution__c, Total_OCR_Received__c, Total_Demand_Received__c,
            OCR_Definition__c, Planned_Principal_Holiday_Month__c, Planned_EMI_Holiday_Month__c, Contributor__c, Total_Builder_Demand_Raised__c,
            Paid_Amount__c, Total_OCR_Paid__c, OCR_Receivable__c, Demand_Amount__c, Receipt_Date__c,Builder_Demand__c,Remark__c, 
            OCR_Definition__r.Total_OCR_Paid__c, OCR_Definition__r.Total_Builder_Demand_Raised__c, OCR_Definition__r.OCR_Receivable__c,
            (SELECT Id, Name, Content_Document_Id__c FROM Document_Details__r)
            FROM Loan_Transaction__c
            WHERE Loan_Application__c = :requiredLoanId AND RecordTypeId = :recordTypeId AND OCR_Definition__c!=null AND isParent__c=false ORDER BY Step_Sequence__c ASC
        ];

        Set<Id> contentDocIds = new Set<Id>();
        for (Loan_Transaction__c txn : transactions) {
            for (Document_Details__c doc : txn.Document_Details__r) {
                if (doc.Content_Document_Id__c != null) {
                    contentDocIds.add(doc.Content_Document_Id__c);
                }
            }
        }

        Map<Id, ContentDocument> contentDocMap = new Map<Id, ContentDocument>();
        if (!contentDocIds.isEmpty()) {
            for (ContentDocument cd : [
                SELECT Id, Title, LatestPublishedVersionId, FileType, ContentSize
                FROM ContentDocument
                WHERE Id IN :contentDocIds
            ]) {
                contentDocMap.put(cd.Id, cd);
            }
        }
        List<Map<String, Object>> resultList = new List<Map<String, Object>>();
        for (Loan_Transaction__c txn : transactions) {
            Map<String, Object> txnData = new Map<String, Object>();
            txnData.put('Id', txn.Id);
            txnData.put('Step_Sequence__c', txn.Step_Sequence__c);
            txnData.put('Paid_Amount__c', txn.Paid_Amount__c);
            txnData.put('Builder_Demand__c', txn.Builder_Demand__c);
            txnData.put('Receipt_Date__c', txn.Receipt_Date__c);
            txnData.put('Remark__c', txn.Remark__c);
            txnData.put('OCR_Definition__r.Total_OCR_Paid__c', txn.OCR_Definition__r.Total_OCR_Paid__c);

            List<Map<String, Object>> files = new List<Map<String, Object>>();
            for (Document_Details__c doc : txn.Document_Details__r) {
                Map<String, Object> fileData = new Map<String, Object>();
                fileData.put('Id', doc.Id);
                fileData.put('Name', doc.Name);
                fileData.put('Content_Document_Id__c', doc.Content_Document_Id__c);

                if (contentDocMap.containsKey(doc.Content_Document_Id__c)) {
                    ContentDocument cd = contentDocMap.get(doc.Content_Document_Id__c);
                    fileData.put('Title', cd.Title);
                    fileData.put('FileType', cd.FileType);
                    fileData.put('ContentSize', cd.ContentSize);
                    fileData.put('DownloadUrl', '/sfc/servlet.shepherd/version/download/' + cd.LatestPublishedVersionId);
                }

                files.add(fileData);
            }

            txnData.put('files', files);
            resultList.add(txnData);
        }

        return resultList;
    }
    //     return transactions.isEmpty() ? null : transactions;
    // }

    @AuraEnabled
    public static String upsertLoanTransaction(Map<String, Object> fieldValues, Id recordId, String recordTypeDevName) {
        system.debug('recordId>>>+'+recordId);
        String requiredLoanId = returnRecordIdMultiProd(recordId);
        Loan_Transaction__c transactionRec;
        try{
        String recordTypeId = Utility.getRecordTypeIdByDeveloperName('Loan_Transaction__c', recordTypeDevName);
        List<Loan_Transaction__c> existingRecordList = [
            SELECT Id FROM Loan_Transaction__c 
            WHERE Loan_Application__c = :requiredLoanId AND RecordTypeId = :recordTypeId AND OCR_Definition__c =null AND isParent__c=true LIMIT 1];
		system.debug('existingRecordList>>>+'+existingRecordList);
        if (existingRecordList.size() > 0) {
            transactionRec = existingRecordList[0];
        } else {
            transactionRec = new Loan_Transaction__c();
            transactionRec.Loan_Application__c = requiredLoanId;
            transactionRec.RecordTypeId = recordTypeId;
            transactionRec.isParent__c = true;
        }
        // Set fields from fieldValues
        for (String key : fieldValues.keySet()) {
            transactionRec.put(key, fieldValues.get(key));
        }
            system.debug('transactionRec>>>+'+transactionRec);
        upsert transactionRec;
        }catch(exception ex){
            system.debug('exception on line>>>>'+ex.getLineNumber());
            system.debug('exception on line>>>>'+ex);
        }
        return transactionRec.Id;
    }
    
    @AuraEnabled
    public static void createChildLoanTransactions(List<Loan_Transaction__c> transactions, String recordId) {
        //check for existing ocr steps.
        String recordTypeId = Utility.getRecordTypeIdByDeveloperName('Loan_Transaction__c', 'OCR_Steps');
        String requiredLoanId = returnRecordIdMultiProd(recordId);
        List<Loan_Transaction__c> existingOcrStep = [SELECT Id, OCR_Description__c, Customer_Portion__c, OCR_Type__c, Total_Demand__c, Total_OCR_Receivable__c,
            Total_Demand_Received__c, Total_OCR_Received__c, Contributor__c
            FROM Loan_Transaction__c WHERE Loan_Application__c = :requiredLoanId AND RecordTypeId = :recordTypeId];
        
        //the idea is to delete all the ocr steps if button is clicked again. How and when the button will be clicked will be handled in js.
        if(existingOcrStep.size()>0){
            delete existingOcrStep;
        }

        if(transactions.size()>0){
            List<Loan_Transaction__c> newOcrStepList = new List<Loan_Transaction__c>();
            
            for(Loan_Transaction__c itrLoanTrans : transactions){
                itrLoanTrans.RecordTypeId = recordTypeId;
                itrLoanTrans.Loan_Application__c = requiredLoanId; //added this
                newOcrStepList.add(itrLoanTrans);
            }
            insert newOcrStepList;
        }
    }

    @AuraEnabled
    public static List<Loan_Transaction__c> createOcrCapture(List<Map<String, Object>> steps, Map<String, Object> context) {
        system.debug('steps>>>'+steps);
        List<Loan_Transaction__c> transactions = new List<Loan_Transaction__c>();
        String recordTypeId = Utility.getRecordTypeIdByDeveloperName('Loan_Transaction__c', 'OCR_Capture_Transaction');
        Id recordId = (Id)context.get('recordId');
        String requiredLoanId = returnRecordIdMultiProd(recordId);
        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
        List<Document_Details__c> docsRecordToInsert = new List<Document_Details__c>();

        for (Map<String, Object> step : steps) {
            Loan_Transaction__c txn = new Loan_Transaction__c();
            if (step.containsKey('Id') && step.get('Id') != null) {
                txn.Id = (Id)step.get('Id');
            }
            txn.RecordTypeId = recordTypeId;
            txn.Loan_Application__c = requiredLoanId;
            if((String)step.get('OCR_Definition__c')!=null){
            txn.OCR_Definition__c = (String)step.get('OCR_Definition__c');
            }
            txn.Step_Sequence__c = (Decimal)step.get('Step_Sequence__c');
            String receiptDateStr = (String)step.get('receiptDate');
            if (String.isNotBlank(receiptDateStr)) {
                txn.Receipt_Date__c = Date.valueOf(receiptDateStr);
            }
            txn.Remark__c = (String)step.get('remarks');
            txn.Paid_Amount__c = (Decimal)step.get('paidAmount');
            txn.Builder_Demand__c = (Decimal)step.get('builderDemand');
            transactions.add(txn);
        }
        upsert transactions;

        Map<String, Document_Details__c> docIdToDocRecordMap = new Map<String, Document_Details__c>();
        Set<Id> docIds = new Set<Id>();
        Set<Id> txnIds = new Set<Id>();

        for (Integer i = 0; i < transactions.size(); i++) {
            Loan_Transaction__c txn = transactions[i];
            txnIds.add(txn.Id);
            List<Object> files = (List<Object>)steps[i].get('files');
            if (files != null) {
                for (Object fileObj : files) {
                    Map<Object, Object> fileMap = (Map<Object, Object>)fileObj;
                    Id contentDocumentId = (Id)(fileMap.get('contentDocId'));
                    String fileName = (String)(fileMap.get('fileName'));
                    docIds.add(contentDocumentId);
                }
            }
        }

        // Query existing Document_Details__c records
        Map<String, Set<Id>> existingDocMap = new Map<String, Set<Id>>();
        for (Document_Details__c existingDoc : [
            SELECT Content_Document_Id__c, Loan_Transaction__c
            FROM Document_Details__c
            WHERE Content_Document_Id__c IN :docIds AND Loan_Transaction__c IN :txnIds
        ]) {
            if (!existingDocMap.containsKey(existingDoc.Content_Document_Id__c)) {
                existingDocMap.put(existingDoc.Content_Document_Id__c, new Set<Id>());
            }
            existingDocMap.get(existingDoc.Content_Document_Id__c).add(existingDoc.Loan_Transaction__c);
        }

        // Create new Document_Details__c records only if not already existing
        for (Integer i = 0; i < transactions.size(); i++) {
            Loan_Transaction__c txn = transactions[i];
            List<Object> files = (List<Object>)steps[i].get('files');
            if (files != null) {
                for (Object fileObj : files) {
                    Map<Object, Object> fileMap = (Map<Object, Object>)fileObj;
                    Id contentDocumentId = (Id)(fileMap.get('contentDocId'));
                    String fileName = (String)(fileMap.get('fileName'));

                    if (!existingDocMap.containsKey(contentDocumentId) || 
                        !existingDocMap.get(contentDocumentId).contains(txn.Id)) {

                        Document_Details__c doc = new Document_Details__c();
                        doc.Content_Document_Id__c = contentDocumentId;
                        doc.Status__c = 'Uploaded';
                        doc.Name = String.isNotBlank(fileName) ? fileName : 'OCR Capture Document' + requiredLoanId;
                        doc.Loan_Application__c = requiredLoanId;
                        doc.Loan_Transaction__c = txn.Id;
                        docIdToDocRecordMap.put(doc.Content_Document_Id__c, doc);
                        docsRecordToInsert.add(doc);
                    }
                }
            }
        }

        if (!docsRecordToInsert.isEmpty()) {
            insert docsRecordToInsert;
        }

        // Create ContentDocumentLinks
        Set<Id> entityIds = new Set<Id>();
        for (Document_Details__c doc : docsRecordToInsert) {
            entityIds.add(doc.Id);
        }

        Map<String, ContentDocumentLink> existingLinksMap = new Map<String, ContentDocumentLink>();
        if(docIds.size()>0 && entityIds.size()>0){
        for (ContentDocumentLink link : [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :docIds AND LinkedEntityId IN :entityIds
        ]) {
            existingLinksMap.put(link.ContentDocumentId + '-' + link.LinkedEntityId, link);
        }
        

        for (Document_Details__c doc : docsRecordToInsert) {
            String key = doc.Content_Document_Id__c + '-' + doc.Id;
            if (!existingLinksMap.containsKey(key)) {
                ContentDocumentLink link = new ContentDocumentLink();
                link.ContentDocumentId = doc.Content_Document_Id__c;
                link.LinkedEntityId = doc.Id;
                link.ShareType = 'V';
                link.Visibility = 'AllUsers';
                linksToInsert.add(link);
            }
        }
        }

        if (!linksToInsert.isEmpty()) {
            insert linksToInsert;
        }
        return transactions;
    }
     @AuraEnabled
    public static string deleteLoanTransaction(String recordId) {
        try{
             system.debug('recordid???'+recordId);
             if (String.isNotBlank(recordId)) {
                String requiredLoanId = returnRecordIdMultiProd(recordId);
                
                Loan_Transaction__c recordToDelete = [SELECT Id FROM Loan_Transaction__c WHERE Id = :requiredLoanId LIMIT 1];
                delete recordToDelete;
            }
            return 'success'; 
        }
        catch(exception ex){
            system.debug('ex???'+ ex.getStackTraceString());
            return 'failed' +  ex.getStackTraceString();
        }  
    }
}