public with sharing class COMM_DocumentDetailsScreenController {
    @AuraEnabled
    public static Boolean isForm60Uploaded(Id applicantId) {
        Application_Applicant__c applicant = [
            SELECT IsForm60Uploaded__c 
            FROM Application_Applicant__c 
            WHERE Id = :applicantId 
            LIMIT 1
        ];
        
        return applicant.IsForm60Uploaded__c == 'Yes';
    }
    @AuraEnabled
    public static Boolean checkIfAllDocumentsVerified(String loanId){
        try {
            List<Document_Details__c> unverifiedDocuments = [SELECT Id 
                                                             FROM Document_Details__c
                                                             WHERE Is_Verified__c = false
                                                             AND Loan_Application__c = :loanId
                                                             AND Consider_for_Loan_Application__c = true
                                                             AND Active__c = true];
            return unverifiedDocuments.isEmpty();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<DocumentDetailsWrapper> getDocumentsList(String recordId, String processName) {
        
        String sQuery = 'SELECT Id, Name,Bank_Name__c,AA_PDF_ContentId__c, Content_Document_Id__c,Year__c,Transaction_Id__c,Linked_Reference__c ,CreatedBy.Name, Is_BSA_Initated__c, is_internal_bsa__c, Is_Uploaded__c, Is_Required__c, Bsa_Id__c, Document_Master__r.Document_Category__c,Document_Master__r.Document_Type__c, Applicant__c, Masked_Account_Number__c, '+
            'Location__Latitude__s, Location__Longitude__s,Applicant__r.Applicant_Name__c,Applicant__r.Applicant_Type__c,Applicant__r.Mobile_Number__c,Manual_AA__c,Year_Month_From__c,Password__c,Year_month_to__c,Account_Aggregator_Status__c,Login_Fee_Status__c, '+
            'Uploaded_Date_Time__c, Loan_Application__r.Loan_Application_Number__c, File_Name__c,Mode_of_Trigger__c'+
            ' FROM Document_Details__c ';
        
        switch on processName {
            when 'Lead' {
                sQuery += ' WHERE Lead__c =: recordId Order By Is_Required__c Desc, CreatedDate Asc';
            }
            when 'Application Verification' {
                if(Schema.sObjectType.Application_Verification__c.isAccessible()){
                    Application_Verification__c fiRec = [SELECT Id, Name FROM Application_Verification__c WHERE Id =: recordId];
                    string fiReport = '%'+ fiRec.Name + ' Report%';
                    sQuery += ' WHERE Application_Verification__c =: recordId And ((NOT (Name LIKE \''+ fiReport +'\')) And Name != \'FI Waived Document\') And Active__c = true  ORDER BY Is_Required__c DESC, CreatedDate ASC';
                }
            }
            when 'Non Individual Draft'{
                sQuery += ' WHERE Loan_Application__c =: recordId AND Applicant__c != null ORDER BY Is_Required__c DESC, CreatedDate ASC';
            }
            when 'Bank Statement'{
                sQuery += ' WHERE Loan_Application__c =: recordId AND Process_Name__c=\'Income Bank Statement\' AND Applicant__c != null ORDER BY Is_Required__c DESC, CreatedDate ASC';
            }
            when 'ITR'{
                sQuery += ' WHERE Loan_Application__c =: recordId AND Process_Name__c=\'Income ITR\'  AND Applicant__c != null ORDER BY Is_Required__c DESC, CreatedDate ASC';
            }
            when 'GST'{
                sQuery += ' WHERE Loan_Application__c =: recordId AND Process_Name__c=\'Income GST\'  AND Applicant__c != null ORDER BY Is_Required__c DESC, CreatedDate ASC';
            }
            when 'Login Fee'{
                sQuery += ' WHERE Loan_Application__c =: recordId AND Process_Name__c=\'Login Fee\' ORDER BY Is_Required__c DESC, CreatedDate ASC';
            }
            when 'Upfront Charges Login Fee'{
                sQuery += ' WHERE Loan_Application__c =: recordId AND Process_Name__c=\'Upfront Charges Login Fee\' ORDER BY Is_Required__c DESC, CreatedDate ASC';
            }
            when 'Sanction Condition'{
                sQuery += ' WHERE Id =: recordId';
            }
            when 'Esign' {
                sQuery += ' WHERE Loan_Application__c =: recordId AND Esign_Document__c=true';
            }
            when 'Customer Document' {
                sQuery += ' WHERE Applicant__r.Customer__c =: recordId ORDER BY Loan_Application__r.Loan_Application_Number__c, Uploaded_Date_Time__c';
            }
            when 'GeneratedDoc'{
                sQuery += ' WHERE Loan_Application__c =: recordId AND Document_Type__c = \'Merged Document\' AND Description__c = \'Mandatory\' ORDER BY CreatedDate DESC LIMIT 1';
            }
            when 'GeneratedDocNonMand'{
                sQuery += ' WHERE Loan_Application__c =: recordId AND Document_Type__c = \'Merged Document\' AND Description__c = \'Non-Mandatory\' ORDER BY CreatedDate DESC LIMIT 1';
            }
            when 'EsignedDoc'{
                sQuery += ' WHERE Loan_Application__c =: recordId AND Esign_Document__c=true';
            }
        }
        System.debug('sQuery: '+sQuery);
        
        List<Document_Details__c> ddList = Database.query(sQuery);
        system.debug('ddList: '+ddList);
        
        //fetching all the content document ids
        Set<String> contDocSet = new Set<String>();
        Set<String> txnIdSet = new Set<String>();
        Set<String> aaTxnIds = new Set<String>();
        
        
        for(Document_Details__c dd : ddList) {
            if(string.isNotBlank(dd.Content_Document_Id__c)) {
                contDocSet.add(dd.Content_Document_Id__c);
            }
            if(processName == 'Bank Statement' && String.isNotBlank(dd.Bsa_Id__c)){
                txnIdSet.add(dd.Bsa_Id__c);
            }
            if(dd.Manual_AA__c == 'AA' && String.isNotBlank(dd.Transaction_Id__c)){
                aaTxnIds.add(dd.Transaction_Id__c);
            }
        }
        
        Map<String,String> versionToDocMap = new Map<String,String>();
        Map<String,String> versionToFileName = new Map<String,String>();
        
        if(contDocSet.size()>0){
            List<ContentVersion> cvRecVersionIdList = [Select Id,Title,ContentDocumentId, FileType from ContentVersion where ContentDocumentId IN : contDocSet];
            
            for(ContentVersion cvId : cvRecVersionIdList) {
                if(processName == 'Bank Statement' && (cvId.FileType == 'TEXT')){
                    //continue;
                }else{
                    versionToDocMap.put(cvId.ContentDocumentId,cvId.Id);
                    versionToFileName.put(cvId.ContentDocumentId,cvId.Title);
                }
            }
        }
        
        
        Map<Id, ContentDocument> cdRecMap = new Map<Id, ContentDocument>([Select Id, FileType From ContentDocument Where Id =: contDocSet]);
        
        List<DocumentDetailsWrapper> ddWrapperList = new List<DocumentDetailsWrapper>();
        List<Id> docIds = new List<Id>();
        for(Document_Details__c doc : ddList){
            docIds.add(doc.Id);
        }
        Map<String,List<ContentDocumentLink>> docToContentLinkMap = new Map<String,List<ContentDocumentLink>>();
        
        if(docIds.size()>0){
            List<ContentDocumentLink> contentLinkList = [Select ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension, Id, IsDeleted, LinkedEntityId, ShareType, SystemModstamp, Visibility from ContentDocumentLink where LinkedEntityId in: docIds];
            
            for(ContentDocumentLink iterLink : contentLinkList){
                if(docToContentLinkMap.containsKey(iterLink.LinkedEntityId)){
                    docToContentLinkMap.get(iterLink.LinkedEntityId).add(iterLink);
                }
                else{
                    docToContentLinkMap.put(iterLink.LinkedEntityId,new List<ContentDocumentLink>{iterLink});
                }
            }
        }
        
        
        // ✅ Query Bank_Details__c once for all txn IDs
        Map<String, Bank_Details__c> bankDetailsMap = new Map<String, Bank_Details__c>();
        if(!txnIdSet.isEmpty()){
            for(Bank_Details__c bd : [
                SELECT Id, Perfios_Transaction_ID__c 
                FROM Bank_Details__c 
                WHERE Perfios_Transaction_ID__c IN :txnIdSet
            ]){
                bankDetailsMap.put(bd.Perfios_Transaction_ID__c, bd);
            }
        }
        Map<String,String> consentHandleToMobileMap = new Map<String,String>();
        Map<String,String> consentHandleToDateMap = new Map<String,String>();
        if(!aaTxnIds.isEmpty()){
            List<Integration_Details__c> intDetList = [
                SELECT Id, Name, Loan_Application__c, Response_JSON__c, CreatedDate
                FROM Integration_Details__c
                WHERE Name LIKE 'Account Aggregator'
                AND Loan_Application__c = :recordId
                ORDER BY CreatedDate ASC
            ];
            
            for(Integration_Details__c intDet : intDetList){
                if(String.isNotBlank(intDet.Response_JSON__c)){
                    try {
                        Object tmp = JSON.deserializeUntyped(intDet.Response_JSON__c);
                        String unescapedJson = (String) tmp;
                        
                        COMM_AccountAggregatorController.AccountAggregatorResponseServiceWrapper aaResp =
                            (COMM_AccountAggregatorController.AccountAggregatorResponseServiceWrapper)
                            JSON.deserialize(
                                unescapedJson,
                                COMM_AccountAggregatorController.AccountAggregatorResponseServiceWrapper.class
                            );
                        
                        if(aaResp.data != null
                           && aaResp.data.consentHandle != null
                           && aaResp.data.consentHandle.data != null){
                            String consentHandle = aaResp.data.consentHandle.data.consent_handle;
                            String mobile = aaResp.data.partyIdentifierValue;
                            if(aaTxnIds.contains(consentHandle)){
                                consentHandleToMobileMap.put(consentHandle, mobile);
                                consentHandleToDateMap.put(
                                    consentHandle,
                                    String.valueOf(intDet.CreatedDate)
                                );
                            }
                        }
                    } catch(Exception ex) {
                        throw new AuraHandledException(ex.getMessage());
                    }
                }
            }
        }
        
        Map<String,List<DocumentDetailsWrapper>> integrationKeyToDocWrapMap = new Map<String,List<DocumentDetailsWrapper>>();
        
        for(Document_Details__c dd : ddList){
            
            DocumentDetailsWrapper ddw = new DocumentDetailsWrapper();
            ddw.id = dd.Id;
            ddw.name = dd.Name;
            ddw.fileName = dd.File_Name__c;
            ddw.contentId = dd.Content_Document_Id__c;
            ddw.MaskedAccountNumber = dd.Masked_Account_Number__c;
            ddw.isRequired = dd.Is_Required__c;
            ddw.showUpload = !dd.Is_Uploaded__c || dd.Content_Document_Id__c== null;
            ddw.showview = dd.Is_Uploaded__c && dd.Content_Document_Id__c!= null;
            ddw.showRetake = true;
            ddw.year = dd.Year__c;
            ddw.internalBSA=dd.is_internal_bsa__c;
            if(dd.Content_Document_Id__c!= null && versionToDocMap.containsKey(dd.Content_Document_Id__c)){
                ddw.contentVersionId = versionToDocMap.get(dd.Content_Document_Id__c);
                ddw.fileName = versionToFileName.get(dd.Content_Document_Id__c);
            }
            
            ddw.showLocation = dd.Location__Latitude__s != null;
            ddw.lattitude = dd.Location__Latitude__s;
            ddw.longitude = dd.Location__Longitude__s;
            ddw.category = dd.Document_Master__r.Document_Category__c;
            ddw.docCategory  = dd.Document_Master__r.Document_Type__c;
            ddw.docName = dd.Name +' ('+ dd.Document_Master__r.Document_Type__c +')';
            ddw.fileType = cdRecMap.containsKey(dd.Content_Document_Id__c) ? cdRecMap.get(dd.Content_Document_Id__c).FileType : '';
            ddw.applicantName=dd.Applicant__r.Applicant_Name__c +' ('+ dd.Applicant__r.Applicant_Type__c +')';
            ddw.manualAA=dd.Manual_AA__c;
            ddw.isAARelated=dd.Manual_AA__c=='AA'?true:false;
            ddw.applicantId = dd.Applicant__c;
            ddw.fromDate= dd.Year_Month_From__c;
            ddw.toDate= dd.Year_month_to__c;
            ddw.uploadedDate = string.valueOf(dd.Uploaded_Date_Time__c);
            ddw.loanApplicationNo = dd.Loan_Application__r.Loan_Application_Number__c;
            ddw.generatedBy = dd.CreatedBy.Name;
            ddw.applicantMobile = dd.Applicant__r.Mobile_Number__c;
            ddw.linkedReference = dd.Linked_Reference__c;
            ddw.bankName = dd.Bank_Name__c;
            if(dd.Manual_AA__c == 'AA' && String.isNotBlank(dd.Transaction_Id__c)){
                ddw.aaMobileNumber = consentHandleToMobileMap.get(dd.Transaction_Id__c);
                ddw.aaInitiatedDate = consentHandleToDateMap.get(dd.Transaction_Id__c);
            }
            ddw.triggerMode = dd.Mode_of_Trigger__c;
            
            if(dd.Content_Document_Id__c !=null || dd.Bank_Name__c != null){
                ddw.showViewAA=true;
            }
            
            switch on processName {
                when 'Lead' {
                    ddw.showDelete = dd.Is_Uploaded__c;
                    ddw.showLatLong = false;
                }
                when 'Application Verification' {
                    ddw.showDelete = false;//!dd.Is_Uploaded__c;
                    ddw.showLatLong = true;//dd.Is_Uploaded__c;
                }
                when 'Non Individual Draft' {
                    ddw.showDelete = dd.Is_Uploaded__c;
                    ddw.showLatLong = false;
                }
                when 'Bank Statement'{
                    ddw.showLatLong = false;
                    ddw.errorList = new List<String>();
                    ddw.bsaStatus = dd.Is_BSA_Initated__c==true? 'Initiated' : 'Pending';
                    ddw.bsaInitated = dd.Content_Document_Id__c != null ? dd.Is_BSA_Initated__c : true;
                    ddw.acagregatorStatus =dd.Account_Aggregator_Status__c!=null? dd.Account_Aggregator_Status__c: ddw.bsaInitated ? 'BSA Initiated' : 'Statement Received';
                    ddw.showDelete = ddw.bsaInitated ? false : true;
                    ddw.perfiosTransactionId = dd.Transaction_Id__c;
                    ddw.aaContentDoc = dd.AA_PDF_ContentId__c ;
                    ddw.passwordBSA= dd.Password__c!=null?dd.Password__c:'';
                    
                    // ✅ Bulkified Bank_Details__c check
                    if(String.isNotBlank(dd.Bsa_Id__c) && bankDetailsMap.containsKey(dd.Bsa_Id__c)){
                        ddw.bsaStatus = 'Success';
                    }
                    
                    ddw.uploadedFiles =  new List<ContentDocWrapper>();
                    if(docToContentLinkMap.containsKey(dd.Id) && !docToContentLinkMap.get(dd.Id).isEmpty()){
                        List<ContentDocumentLink> linkedList = docToContentLinkMap.get(dd.Id);
                        for(ContentDocumentLink cdl : linkedList){
                            ContentDocWrapper cdlWrap = new ContentDocWrapper();
                            cdlWrap.contentDocId = cdl.ContentDocumentId;
                            cdlWrap.contentDocLinkId = cdl.Id;
                            cdlWrap.linkedEntityId = cdl.LinkedEntityId;
                            cdlWrap.fileName = cdl.ContentDocument.Title+'.'+cdl.ContentDocument.FileExtension;
                            ddw.uploadedFiles.add(cdlWrap);
                        }
                    }
                    System.debug('ddw---'+ddw);
                }
                when 'ITR'{
                    ddw.showDelete = true;
                    ddw.showLatLong = false;
                }
                when 'GST'{
                    ddw.showDelete = true;
                    ddw.showLatLong = false;
                }
                when 'Login Fee'{
                    ddw.showDelete = true;
                    ddw.showLatLong = false;
                    ddw.loginFeeStatus=dd.Login_Fee_Status__c;
                }
            }
            
            ddWrapperList.add(ddw);
        }
        system.debug('ddWrapperList250--'+ddWrapperList);
        
        if(processName == 'Bank Statement'){
            for(DocumentDetailsWrapper ddw : ddWrapperList){
                for(ContentDocWrapper iterVar : ddw.uploadedFiles){
                    if(integrationKeyToDocWrapMap.containsKey(ddw.perfiosTransactionId+'-'+iterVar.fileName)){
                        integrationKeyToDocWrapMap.get(ddw.perfiosTransactionId+'-'+iterVar.fileName).add(ddw);
                    }
                    else{
                        integrationKeyToDocWrapMap.put(ddw.perfiosTransactionId+'-'+iterVar.fileName, new List<DocumentDetailsWrapper>{ddw});
                    }
                }
            }
            System.debug('integrationKeyToDocWrapMap=:'+integrationKeyToDocWrapMap);
            List<Integration_Details__c> intDetList = [SELECT Id, Name, Loan_Application__c,Response_JSON__c from Integration_Details__c where Name Like 'BSACallBack %' and Loan_Application__c =:recordId Order by CreatedDate];
            List<Perfios_Errors__c> matchedErrors = [SELECT Perfios_Error__c FROM Perfios_Errors__c];
            Opportunity opp = [SELECT Id, Login_Completion_Stage__c FROM Opportunity WHERE Id = :recordId LIMIT 1];
            List<String> perfiosErrorList = new List<String>();
            for(Perfios_Errors__c pe : matchedErrors){
                perfiosErrorList.add(pe.Perfios_Error__c);
            }
            Map<String,List<String>> intToErrorMap = new Map<String,List<String>>();
            for(Integration_Details__c iterInt : intDetList){
                if(iterInt.Name == 'BSACallBack -1'){
                    BSAResponseWrapper callbackResp = (BSAResponseWrapper) JSON.deserialize(iterInt.Response_JSON__c, BSAResponseWrapper.class);
                    if (callbackResp.data != null && callbackResp.data.files != null && !callbackResp.data.files.isEmpty()) {
                        
                        for(cls_files cs : callbackResp.data.files) {
                            // Case 1: details exist
                            if(cs.Message != null && cs.Message.error != null && cs.Message.error.details != null && !cs.Message.error.details.isEmpty()) {
                                for(cls_details cd : cs.Message.error.details) {
                                    String errMsg = cs.filename + '-' + cd.message;
                                    
                                    if(perfiosErrorList.contains(cd.message) &&
                                    (opp.Login_Completion_Stage__c == null || !opp.Login_Completion_Stage__c.containsIgnoreCase('Income eligibility'))) {
                                        ddWrapperList[0].perfiosError = cd.message;
                                        ddWrapperList[0].showPerfiosError = true;
                                    }
                                    
                                    String mapKey = callbackResp.data.perfiosTransactionId + '-' + cs.filename;
                                    if(intToErrorMap.containsKey(mapKey)) {
                                        intToErrorMap.get(mapKey).add(errMsg);
                                    } else {
                                        intToErrorMap.put(mapKey, new List<String>{errMsg});
                                    }
                                }
                            }
                            // Case 2: files exist but no details → use top-level error message of file
                            else if(cs.Message != null && cs.Message.error != null && String.isNotBlank(cs.Message.error.message)) {
                                String errMsg = cs.filename + '-' + cs.Message.error.message;
                                
                                if(perfiosErrorList.contains(cs.Message.error.message) &&
                                (opp.Login_Completion_Stage__c == null || !opp.Login_Completion_Stage__c.containsIgnoreCase('Income eligibility'))) {
                                    ddWrapperList[0].perfiosError = cs.Message.error.message;
                                    ddWrapperList[0].showPerfiosError = true;
                                }
                                
                                String mapKey = callbackResp.data.perfiosTransactionId + '-' + cs.filename;
                                if(intToErrorMap.containsKey(mapKey)) {
                                    intToErrorMap.get(mapKey).add(errMsg);
                                } else {
                                    intToErrorMap.put(mapKey, new List<String>{errMsg});
                                }
                            }
                        }
                        
                    } else {
                        // Case 3: no files at all → fallback to top-level transaction message
                        String apiMsg = callbackResp.message != null ? callbackResp.message : 'Unknown error';
                        String mapKey = callbackResp.perfiosTransactionId != null ? callbackResp.perfiosTransactionId : 'UNKNOWN_TXN';
                        
                        if(intToErrorMap.containsKey(mapKey)) {
                            intToErrorMap.get(mapKey).add(apiMsg);
                        } else {
                            intToErrorMap.put(mapKey, new List<String>{apiMsg});
                        }
                        
                        if(perfiosErrorList.contains(apiMsg) &&
                        (opp.Login_Completion_Stage__c == null || !opp.Login_Completion_Stage__c.containsIgnoreCase('Income eligibility'))) {
                            ddWrapperList[0].perfiosError = apiMsg;
                            ddWrapperList[0].showPerfiosError = true;
                        }
                    }
                }
                else if(iterInt.Name == 'BSACallBack -2'){
                    COMM_BSAResponseService respWrap = (COMM_BSAResponseService)JSON.deserialize(iterInt.Response_JSON__c, COMM_BSAResponseService.class);
                    if(perfiosErrorList.contains(respWrap.data.errorMessage)){
                        if (opp.Login_Completion_Stage__c == null || !opp.Login_Completion_Stage__c.containsIgnoreCase('Income eligibility')) {
                            ddWrapperList[0].perfiosError =  matchedErrors[0].Perfios_Error__c;
                            ddWrapperList[0].showPerfiosError=true;
                            
                        }
                    }
                    if(intToErrorMap.containsKey(respWrap.data.perfiosTransactionId)){
                        intToErrorMap.get(respWrap.data.perfiosTransactionId).add(respWrap.data.errorMessage);
                    }
                    else{
                        intToErrorMap.put(respWrap.data.perfiosTransactionId,new List<String>{respWrap.data.errorMessage});
                    }
                }
            }
            List<DocumentDetailsWrapper> finalDdwList = new List<DocumentDetailsWrapper>();
            
            for(String str: integrationKeyToDocWrapMap.keySet()) {
                // Case 1: exact match in intToErrorMap
                if(intToErrorMap.containsKey(str)) {
                    if(intToErrorMap.get(str) != null && !intToErrorMap.get(str).isEmpty()) {
                        integrationKeyToDocWrapMap.get(str)[0].errorList.addAll(intToErrorMap.get(str));
                    }
                }
                // Case 2: key contains '-' → try matching by transactionId
                else if(str.contains('-')) {
                    String perfTranId = str.split('-')[0];
                    
                    // Loop over intToErrorMap keys to find matches
                    for(String errKey : intToErrorMap.keySet()) {
                        // Match exact transactionId or keys starting with transactionId + '-'
                        if(errKey == perfTranId || errKey.startsWith(perfTranId + '-')) {
                            if(intToErrorMap.get(errKey) != null && !intToErrorMap.get(errKey).isEmpty()) {
                                integrationKeyToDocWrapMap.get(str)[0].errorList.addAll(intToErrorMap.get(errKey));
                            }
                        }
                    }
                }
            }

            Map<String,List<DocumentDetailsWrapper>> handleToWraps = new Map<String,List<DocumentDetailsWrapper>>();
            for(DocumentDetailsWrapper w : ddWrapperList){
                if(w.manualAA != null
                   && w.manualAA.equalsIgnoreCase('AA')
                   && String.isNotBlank(w.perfiosTransactionId)){
                    if(!handleToWraps.containsKey(w.perfiosTransactionId)){
                        handleToWraps.put(w.perfiosTransactionId, new List<DocumentDetailsWrapper>());
                    }
                    handleToWraps.get(w.perfiosTransactionId).add(w);
                }
            }
            for(String handle : handleToWraps.keySet()){
                String overall = computeOverallAAStatus(handleToWraps.get(handle));
                for(DocumentDetailsWrapper w : handleToWraps.get(handle)){
                    w.overallTriggerStatus = overall;
                }
            }
        }
        System.debug('integrationKeyToDocWrapMap=:'+integrationKeyToDocWrapMap);
        system.debug('ddWrapperList377--'+ddWrapperList);
        return ddWrapperList;
    }

    private static String computeOverallAAStatus(List<DocumentDetailsWrapper> items){
        if(items == null || items.isEmpty()){
            return 'Pending';
        }

        Integer total = items.size();
        Integer delivered = 0;
        Integer dataReady = 0;
        Integer approved = 0;
        Integer rejected = 0;

        for(DocumentDetailsWrapper w : items){
            String aaStatus = w.acagregatorStatus != null
                ? w.acagregatorStatus.toLowerCase()
                : '';
            Boolean hasFiles = w.uploadedFiles != null && !w.uploadedFiles.isEmpty();

            if(hasFiles){
                delivered++;
            }
            if(w.bsaStatus != null && w.bsaStatus.equalsIgnoreCase('Success')){
                dataReady++;
            }
            if(aaStatus.contains('consent_approved') || aaStatus.contains('consent approved')){
                approved++;
            }
            if(aaStatus.contains('consent_rejected') || aaStatus.contains('consent rejected')){
                rejected++;
            }
        }

        if(delivered == total){
            return 'Delivered';
        }
        if(delivered > 0){
            return 'Partial Data Received';
        }
        if(dataReady == total){
            return 'Data Ready';
        }
        if(dataReady > 0){
            return 'Partial Ready';
        }
        if(approved == total){
            return 'Consent Approved';
        }
        if(rejected == total){
            return 'Consent Rejected';
        }
        return 'Pending';
    }
    
    @AuraEnabled
    public static List<String> getNonInitiatedFiles(String loanId){
        List<String> uploadedFileNames = new List<String>();
        List<Document_Details__c> docList = [Select id, Content_Document_Id__c, Is_BSA_Initated__c from Document_Details__c
                                                    where Loan_Application__c =: loanId AND Name = '12 Months Bank Statement'  
                                                    AND Applicant__c != null AND Is_BSA_Initated__c = false ORDER BY Is_Required__c DESC, CreatedDate ASC];
        List<Id> docIds = new List<Id>();
        for(Document_Details__c doc : docList){
            docIds.add(doc.Id);
        }
        List<ContentDocumentLink> contentLinkList = [Select ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension, Id, IsDeleted, LinkedEntityId, ShareType, SystemModstamp, Visibility from ContentDocumentLink where LinkedEntityId IN: docIds];
        Map<String,List<ContentDocumentLink>> docToContentLinkMap = new Map<String,List<ContentDocumentLink>>();
        for(ContentDocumentLink iterLink : contentLinkList){
            uploadedFileNames.add(iterLink.ContentDocument.Title+'.'+iterLink.ContentDocument.FileExtension);
        }
        return uploadedFileNames;
    }
    
    @AuraEnabled
    public static List<Document_Master__c> getDocList(String recordId, string processObject){
        try {
            string requiredFor ='';
            string sQuery = 'Select Id,Name, Document_Name__c From Document_Master__c Where Is_Active__c = true ';
            
            switch on processObject {
                when 'Lead' {
                    sQuery += ' And Requirement_At__c =: processObject Order By Document_Name__c';
                }
                when 'Application Verification' {
                    Application_Verification__c fiRec = [Select RecordType.Name From Application_Verification__c Where Id =: recordId];
                    requiredFor = fiRec.RecordType.Name;
                    
                    sQuery += ' And Requirement_At__c =: processObject And Document_Category__c =: requiredFor AND  Document_Name__c != \'FI Waived Document\' Order By Document_Name__c';
                }
                when 'Loan Application'{
                    sQuery += ' And Requirement_At__c =:processObject AND Sub_Category__c= \'OVD\' Order By Document_Name__c';
                }
                
            }
            
            //system.debug('sQuery: '+sQuery);
            return Database.query(sQuery);
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class DocumentDetailsWrapper {
        @AuraEnabled public String MaskedAccountNumber;
        @AuraEnabled public String internalBSA;
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String aaContentDoc;
        @AuraEnabled public Boolean showButton;
        @AuraEnabled public String contentId;
        @AuraEnabled public String fileType;
        @AuraEnabled public String docName;
        @AuraEnabled public boolean isRequired;
        @AuraEnabled public String category;
        @AuraEnabled public String docCategory;
        @AuraEnabled public boolean showUpload;
        @AuraEnabled public boolean showView;
        @AuraEnabled public boolean showDelete;
        @AuraEnabled public boolean showRetake;
        @AuraEnabled public boolean showLocation;
        @AuraEnabled public decimal lattitude;
        @AuraEnabled public decimal longitude;
        @AuraEnabled public boolean showLatLong;
        @AuraEnabled public String applicantName;
        @AuraEnabled public String year;
        @AuraEnabled public String manualAA;
        @AuraEnabled public Boolean isAARelated;
        @AuraEnabled public Boolean showViewAA;
        @AuraEnabled public String applicantId;
        @AuraEnabled public String contentVersionId;
        @AuraEnabled public String fileName;
        @AuraEnabled public Boolean bsaInitated;
        @AuraEnabled public Date fromDate;
        @AuraEnabled public Date toDate;
        @AuraEnabled public string uploadedDate;
        @AuraEnabled public string loanApplicationNo;
        @AuraEnabled public string acagregatorStatus;
        @AuraEnabled public string generatedBy;
        @AuraEnabled public String bsaStatus;
        @AuraEnabled public String perfiosTransactionId;
        @AuraEnabled public String aaMobileNumber;
        @AuraEnabled public String aaInitiatedDate;
        @AuraEnabled public List<ContentDocWrapper> uploadedFiles;
        @AuraEnabled public List<String> errorList;
        @AuraEnabled public String perfiosError;
        @AuraEnabled public boolean showPerfiosError;
        @AuraEnabled public String loginFeeStatus;
        @AuraEnabled public String passwordBSA;
        @AuraEnabled public String triggerMode;
        @AuraEnabled public String applicantMobile;
        @AuraEnabled public String linkedReference;
        @AuraEnabled public String overallTriggerStatus;
        @AuraEnabled public String bankName;
        
    }
    
    public class ContentDocWrapper{
        @AuraEnabled public String contentDocId;
        @AuraEnabled public String contentDocLinkId;
        @AuraEnabled public String fileName;
        @AuraEnabled public String fileType;
        @AuraEnabled public String linkedEntityId;
    }
    
    public class BSAResponseWrapper{
        public boolean status;
        public cls_data data;
        public String message;	//Transaction Cancel
        public String statusCode;	//bsa-200
        public String traceId;	//98dc312d-1bdd-4cbb-90db-d4f6acc8fa55
        public String perfiosTransactionId;	//399Y1749128684898
    }
    public class cls_data {
        public String perfiosTransactionId;	//399Y1749128684898
        public cls_files[] files;
        public String cancelTransactionResult;	//successfully cancel treansaction
    }
    public class cls_files {
        public String filename;	//bank 1.pdf
        public String fileID;	//f82dcc351a18b4abae5c6b57309e0a469ba9d3b5
        public String StatusCode;	//bsa-400
        public cls_Message Message;
    }
    public class cls_Message {
        public cls_error error;
    }
    public class cls_error {
        public String code;	//CannotProcessFile
        public String message;	//We could not process the statement file uploaded by the Client
        public cls_details[] details;
    }
    public class cls_details {
        public String code;	//E_STATEMENT_WRONG_INSTITUTION
        public cls_field field;
        public String message;	//Uploaded statement does not seem to be from the selected institution
        public cls_value value;
    }
    public class cls_field {
    }
    public class cls_value {
    }
    
    @AuraEnabled
    public static Map<string, string> checkValidationBeforeGenerateEsignDoc(string param) {
        
        Map<string, string> result = new Map<string, string>();
        
        try{
            Map<string, string> paramMap = (Map<String, String>) JSON.deserialize(param, Map<String, String>.class);
            
            string loanId = paramMap.get('loanId');
            List<Loan_Transaction__c> transactionList = [Select id,Loan_Start_Date__c,Scheduled_Disbursement_Date__c,RecordType.Name from Loan_Transaction__c WHERE RecordType.Name = 'Transaction Details' AND Loan_Application__c =:loanId LIMIT 1];
            Date loanStartDate = transactionList.size()>0 && transactionList[0].Loan_Start_Date__c!=null ? transactionList[0].Loan_Start_Date__c : null;
            
            //Payment
            List<Loan_Transaction__c> paymentList = [select Id,Name,Scheduled_Disbursement_Date__c from Loan_Transaction__c where RecordType.Name = 'Payment' and Loan_Application__c =: loanId And Disbursement_Party__c = 'Customer'];
            if(paymentList.isEmpty()){
                result.put('Payment', 'Customer Payment records not found, please create any payment record to proceed.');
            }
            
            if(paymentList.size()>0){
                for(Loan_Transaction__c itrPay : paymentList){
                    if(loanStartDate!=null && itrPay.Scheduled_Disbursement_Date__c!=null && (itrPay.Scheduled_Disbursement_Date__c < loanStartDate)){
                        result.put('Payment', 'Loan Start Date for '+ itrPay.Name + ' cannot be later than Scheduled Disbursement date');
                    }
                }
            }
            
            //     //check VAS field validation --------------
            //     set<string> vASCodeSet = new set<string>();
            //     string rTName = Constants__mdt.getInstance('CHARGES_INSURANCE_RECORD_TYPE').value__c;
            //     Map<string, Map<string, List<string>>> chargesFieldsBySectionMap = new Map<string, Map<string, List<string>>>();
            //     List<string> vASFields = new List<string>{'description__c', 'fee_method__c', 'fee_accural_date__c', 'value_date__c', 'self_funded__c'};
            //     if(Schema.sObjectType.Charges_Insurance__c.isAccessible()){
                //     for(Charges_Insurance__c rec : [Select Id, VAS_Code__c FROM Charges_Insurance__c WHERE Loan_Application__c =: loanId 
            //                                     AND RecordType.Name =: RTName]){
                    
                    //         VASCodeSet.add(rec.VAS_Code__c);
                    
                    //         if(chargesFieldsBySectionMap.containsKey(rec.VAS_Code__c)){
                        //             chargesFieldsBySectionMap.get(rec.VAS_Code__c).put('VAS Details', VASFields);
                    //         }
                    //         else{
                        //             Map<string, List<string>> sectionMap = new Map<string, List<string>>();
                        //             sectionMap.put('VAS Details', VASFields);
                        
                        //             chargesFieldsBySectionMap.put(rec.VAS_Code__c, sectionMap);
                    //         }
                //     }
                //     //system.debug('chargesFieldsBySectionMap: '+ JSON.serialize(chargesFieldsBySectionMap));
            // }
            //     if(!VASCodeSet.isEmpty()){
                
                //         set<string> allFieldNameSet = new set<string>();
                //         allFieldNameSet.addAll(VASFields);
                //         if(Schema.sObjectType.Charges_Insurance_Master__c.isAccessible()){
                    //         for(Charges_Insurance_Master__c vasMaster : [SELECT Id, Section_Fields__c, Section_Name__c, VAS_Code__c 
            //                                                         FROM Charges_Insurance_Master__c WHERE VAS_Code__c IN: VASCodeSet ORDER BY VAS_Code__c]){
                        
                        //             List<string> fieldNameList = vasMaster.Section_Fields__c.toLowerCase().split(',');
                        //             allFieldNameSet.addAll(fieldNameList);
                        //             chargesFieldsBySectionMap.get(vasMaster.VAS_Code__c).put(vasMaster.Section_Name__c, fieldNameList);
                    //         }
                //     }
                //         //system.debug('chargesFieldsBySectionMap: '+ JSON.serialize(chargesFieldsBySectionMap));
                
                //         if(!allFieldNameSet.isEmpty()){
                    //             String fields = 'Id, Name, VAS_Code__c, Charge_or_Insurance_Number__c, ';
                    //             String whereClause = ' Loan_Application__c =: loanId AND RecordType.Name =: RTName';
                    //             string sQuery = 'Select ' + fields + string.join(allFieldNameSet, ', ') +
                    //                             ' From Charges_Insurance__c ' + 'WHERE' +  whereClause;
                    
                    //             system.debug('sQuery: '+sQuery);
                    
                    //             List<Charges_Insurance__c> vASRecs = Database.query(sQuery);
                    //             //system.debug('VASRecs: '+VASRecs);
                    
                    //             if(!VASRecs.isEmpty() && Schema.sObjectType.Document_Details__c.isAccessible()){
                        
                        //                 Map<string, string> vASToDocumentMap = new Map<string, string>();
                        //                 Map<String,Schema.SObjectField> mfields = Schema.Charges_Insurance__c.SObjectType.getDescribe().fields.getMap();
                        //                 for(Document_Details__c rec : [SELECT Id, Charges_Insurance__r.Charge_or_Insurance_Number__c FROM Document_Details__c 
            //                                                 WHERE Name = 'Insurance Related Document' and Loan_App                Map<String,Schema.SObjectField> mfields = Schema.Charges_Insurance__c.SObjectType.getDescribe().fields.getMap();
                        //                 for(Document_Details__c rec : [SELECT Id, Charges_Insurance__r.Charge_or_Insurance_Number__c FROM Document_Details__c 
            //                                                 WHERE Name = 'Insurance Related Document' and Loan_Application__c =: loanId And Is_Uploaded__c = true])
                        //                 {
                            //                     VASToDocumentMap.put(rec.Charges_Insurance__r?.Charge_or_Insurance_Number__c, rec.Id);
                        //                 }
                        
                        //                 for(Charges_Insurance__c rec : VASRecs){
                            
                            //                     Map<String, object> recordFieldsMap = (Map<String, object>) JSON.deserializeUntyped(JSON.serialize(rec).toLowerCase());
                            //                     //system.debug('recordFieldsMap: '+ JSON.serialize(recordFieldsMap));
                            
                            //                     for(string sectionName : chargesFieldsBySectionMap.get(rec.VAS_Code__c).keySet()){
                                
                                //                         system.debug('sectionName: '+sectionName);
                                //                         string missingFields = '';
                                
                                //                         switch on sectionName {
                                    //                             when 'Self Funded Detail' {
                                        
                                        //                                 if(rec.self_funded__c != null && rec.self_funded__c){
                                            
                                            //                                     system.debug('---sectionName: '+sectionName);
                                            
                                            //                                     for(string field : chargesFieldsBySectionMap.get(rec.VAS_Code__c).get(sectionName)){
                                                
                                                //                                         string recValue = recordFieldsMap.containsKey(field) ? string.valueOf(recordFieldsMap.get(field)) : '';
                                                //                                         system.debug(field + ': '+recValue);
                                                
                                                //                                         if(recValue == null || string.isBlank(recValue)){
                                                    //                                             missingFields += mfields.get(field).getDescribe().getLabel() +', ';
                                                //                                         }
                                            //                                     }
                                        //                                 }
                                    //                             }
                                    //                             when 'Appointee Details' {
                                        
                                        //                                 if(rec.Nominee_DOB__c != null && rec.Nominee_DOB__c.addYears(18) > Date.today()) {
                                            
                                            //                                     system.debug('---sectionName: '+sectionName);
                                            
                                            //                                     for(string field : chargesFieldsBySectionMap.get(rec.VAS_Code__c).get(sectionName)){
                                                
                                                //                                         string recValue = recordFieldsMap.containsKey(field) ? string.valueOf(recordFieldsMap.get(field)) : '';
                                                //                                         system.debug(field + ': '+recValue);
                                                
                                                //                                         if(recValue == null || string.isBlank(recValue)){
                                                    //                                             missingFields += mfields.get(field).getDescribe().getLabel() +', ';
                                                //                                         }
                                            //                                     }
                                        //                                 }
                                    //                             }
                                    //                             when else {
                                        
                                        //                                 system.debug('---sectionName: '+sectionName);
                                        
                                        //                                 for(string field : chargesFieldsBySectionMap.get(rec.VAS_Code__c).get(sectionName)){
                                            
                                            //                                     string recValue = recordFieldsMap.containsKey(field) ? string.valueOf(recordFieldsMap.get(field)) : '';
                                            //                                     system.debug(field + ': '+recValue);
                                            
                                            //                                     if(recValue == null || string.isBlank(recValue)){
                                                //                                         missingFields += mfields.get(field).getDescribe().getLabel() +', ';
                                            //                                     }
                                        //                                 }
                                    //                             }
                                //                         }
                                
                                //                         if(string.isNotBlank(missingFields)){
                                    //                             result.put(('VAS_'+ rec.Name +'_'+ sectionName), missingFields.removeEnd(', ') +' field values are missing!');
                                //                         }
                            //                     }
                            
                            //                     if(!VASToDocumentMap.containsKey(rec.Charge_or_Insurance_Number__c)){
                                //                         result.put(('VAS_'+ rec.Name +'_Proposal Form'), 'Proposal form is not uploaded!');
                            //                     }
                        //                 }
                    //             }
                //         }
            //     }
            //     else{
                //         result.put('VAS', 'At least one VAS record is required!');
            //     }
            
            //     chargesFieldsBySectionMap.clear();
            //     //---------------------
            //     List<Screen_Field__c> screenFieldList = new List<Screen_Field__c>();
            //     List<Opportunity> loanApp = new List<Opportunity>();
            //     if(Schema.sObjectType.Opportunity.isAccessible() && Schema.sObjectType.Screen_Field__c.isAccessible() ){
                //     loanApp = [Select Sub_Product__c From Opportunity Where Id =: loanId];
                
                //     //check Loan Details field validation ------------
                //     screenFieldList = [Select Id, Section_Name__c, Field_Label__c, Read_Field_Name__c, Read_Object_Name__c, is_Lookup__c 
            //                                             From Screen_Field__c 
            //                                             where Is_Active__c = true and Is_Mandatory__c = true and Parent_Screen__r.Is_Screen_Active__c = true 
            //                                             and Parent_Screen__r.Master_Screen_Name__c = 'Loan Details' and Parent_Screen__r.Form_Name__c =: loanApp[0].Sub_Product__c
                //                                             order by Read_Object_Name__c];
            //     }
            
            //     if(!screenFieldList.isEmpty()){
                //         Map<String, Set<String>> objectToFieldsMap = new Map<String, Set<String>>();
                
                //         for(Screen_Field__c sc : screenFieldList){
                    
                    //             if(objectToFieldsMap.containsKey(sc.Read_Object_Name__c)){
                        //                 objectToFieldsMap.get(sc.Read_Object_Name__c).add(sc.Read_Field_Name__c);
                    //             }
                    //             else{
                        //                 objectToFieldsMap.put(sc.Read_Object_Name__c, new Set<String>{sc.Read_Field_Name__c});
                    //             }
                //         }
                
                //         Map<String, List<SObject>> objectValuesMap = new Map<String, List<SObject>>();
                //         String query;
                //         for(String objectName : objectToFieldsMap.keySet()){
                    //             //system.debug('objectName: '+objectName);
                    
                    //             Set<String> fieldApiNames = objectToFieldsMap.get(objectName);
                    //             //system.debug('fieldApiNames: '+fieldApiNames);
                    
                    //             query = 'Select Id, '+ string.join(fieldApiNames, ', ');
                    
                    //             switch on objectName {
                        
                        //                 when 'Opportunity' {
                            //                     query += ' FROM '+ objectName +' where Id = \'' + loanId + '\'';
                        //                 }
                        //                 when 'Application_Applicant__c' {
                            //                     query += ' FROM '+ objectName +' where Loan_Application__c = \'' + loanId + '\'' + ' AND Applicant_Type__c = \'Primary Applicant\' LIMIT 1';
                        //                 }
                        //                 when 'OpportunityTeamMember' {
                            //                     query += ' FROM '+ objectName +' where OpportunityId = \'' + loanId + '\'';
                        //                 }
                        //                 when else {
                            //                     query += ' FROM '+ objectName +' where Loan_Application__c = \'' + loanId + '\'';
                        //                 }
                    //             }
                    //             System.debug('query: '+query);
                //             }
                
                //             List<SObject> sObjectList = Database.query(query);
                //             for(String objectName : objectToFieldsMap.keySet()){
                    //             if(!sObjectList.isEmpty()){
                        //                 if(objectValuesMap.containsKey(objectName)){
                            //                     objectValuesMap.get(objectName).add(sObjectList[0]);
                        //                 }
                        //                 else{
                            //                     objectValuesMap.put(objectName, new List<SObject>{sObjectList[0]});
                        //                 }
                    //                 }
                //             }
                
                //         Map<string, string> missingFieldBySectionMap = new Map<string, string>();
                
                //         for(Screen_Field__c sc : screenFieldList){
                    //             List<SObject> sObjList = objectValuesMap.get(sc.Read_Object_Name__c);
                    
                    //             for(SObject sObj : sObjList){
                        //                 system.debug('sObj: '+sObj);
                        //                 //system.debug('sc.Read_Field_Name__c: '+sc.Read_Field_Name__c);
                        
                        //                 string recValue = '';
                        
                        //                 if(sc.is_Lookup__c) {
                            //                     List<string> lookupField = String.valueOf(sc.Read_Field_Name__c).split('\\.');
                            
                            //                     SObject parenObj = sObj.getSobject(lookupField[0]);
                            //                     recValue = string.valueOf(parenObj.get(lookupField[1]));
                        //                 }
                        //                 else {
                            //                     recValue = string.valueOf(sObj.get(sc.Read_Field_Name__c));
                        //                 }
                        //                 system.debug(sc.Read_Field_Name__c +': '+ recValue);
                        
                        //                 if(recValue == null || string.isBlank(recValue)){
                            
                            //                     if(missingFieldBySectionMap.containsKey(sc.Section_Name__c)){
                                //                         missingFieldBySectionMap.put(sc.Section_Name__c, missingFieldBySectionMap.get(sc.Section_Name__c) + sc.Field_Label__c +', ');
                            //                     }
                            //                     else{
                                //                         missingFieldBySectionMap.put(sc.Section_Name__c, sc.Field_Label__c +', ');
                            //                     }
                        //                 }
                    //             }
                    
                    //             if(!missingFieldBySectionMap.isEmpty()){
                        //                 result.put(('Loan Details_'+ sc.Section_Name__c), missingFieldBySectionMap.get(sc.Section_Name__c).removeEnd(', ') +' field values are missing!');
                    //             }
                //         }
                
                //         screenFieldList.clear();
            //     }
            //     //---------------------
            
            //     Integer mandateCount = 0;
            //     Integer pdcCount = 0;
            //     List<Loan_Transaction__c> loanTransactionList = new List<Loan_Transaction__c>();
            //     List<Instrument_Mandate__c> instumentMandateList = new List<Instrument_Mandate__c>();
            //     if(Schema.sObjectType.Loan_Transaction__c.isAccessible() && Schema.sObjectType.Instrument_Mandate__c.isAccessible()){
                //     loanTransactionList = [Select Id, Payment_Method__c, Number_of_Instruments__c, First_Disbursement_Amount__c, Disbursement_Amount__c, RecordType.Name 
            //                                                         From Loan_Transaction__c 
            //                                                         Where Loan_Application__c =: loanId And RecordType.Name In ('Transaction Details', 'Payment')];
                
                //     instumentMandateList = [Select Id, Mandate_Type__c, Purpose__c From Instrument_Mandate__c 
            //                                                         Where Loan_Application__c =: loanId And (Mandate_Type__c = 'Repayment Mandate' Or Purpose__c In ('Installment', 'Security'))];
            //     }
            
            //     if(!instumentMandateList.isEmpty()){
                
                //         Integer spdcCount = 0;
                
                //         for(Instrument_Mandate__c rec : instumentMandateList){
                    
                    //             switch on rec.Mandate_Type__c {
                        //                 when 'Repayment Mandate' {
                            //                     mandateCount++;
                        //                 }
                    //             }
                    
                    //             switch on rec.Purpose__c {
                        //                 when 'Installment' {
                            //                     pdcCount++;
                        //                 }
                        //                 when 'Security' {
                            //                     spdcCount++;
                        //                 }
                    //             }
                //         }
                
                //         if(spdcCount == 0){
                    //             result.put('Instrument_SPDC', 'At least one SPDC is required!');
                //         }
            //     }
            
            //     Decimal totalPaymentAmount = 0;
            //     Decimal firstDisbursementAmount = 0;
            
            //     for(Loan_Transaction__c rec : loanTransactionList){
                
                //         if(rec.RecordType.Name == 'Transaction Details'){
                    
                    //             firstDisbursementAmount = rec.First_Disbursement_Amount__c != null ? rec.First_Disbursement_Amount__c : 0;
                    
                    //             switch on rec.Payment_Method__c {
                        
                        //                 //check Mandate validations --------
                        //                 when 'DDM', 'ECS', 'NACH' {
                            //                     if(mandateCount == 0){
                                //                         result.put('Mandate', 'At least one Repayment Mandate is required!');
                            //                     }
                        //                 }
                        
                        //                 //check Instrument validations --------
                        //                 when 'PDC' {
                            //                     if((rec.Number_of_Instruments__c != null ? rec.Number_of_Instruments__c : 0) != pdcCount){
                                //                         result.put('Instrument_PDC', 'PDC should be equal to Number of Terms(Tenure)!');
                            //                     }
                        //                 }
                    //             }
                //         }
                //         else{
                    //             totalPaymentAmount += rec.Disbursement_Amount__c != null ? rec.Disbursement_Amount__c : 0;
                //         }
            //     }
            
            //     //check disbursement amount validation -------
            //     //system.debug('firstDisbursementAmount: '+firstDisbursementAmount +' --- totalPaymentAmount: '+totalPaymentAmount);
            //     if(firstDisbursementAmount != totalPaymentAmount){
                //         result.put('Disbursement', 'Sum of Total payment created should be equal to First disbursement amount!');
            //     }
            //     //------------------------
        }
        catch(Exception e){
            result.put('Error', e.getMessage());
        }
        
        system.debug('resut: '+ JSON.serialize(result));
        return result;
    }
    @AuraEnabled
    public static List<docWrapper> getRelatedDocumentCategory(String identifier,String recordId, String applicantId, String applicantType) {
        Map<String,List<Document_Master__c>> docTypeMap = new Map<String,List<Document_Master__c>>();
        List<docWrapper> docWrapperTypeList = new List<docWrapper>();
        List<Document_Master_Field_Mapping__mdt> allMetaData = [Select DeveloperName, Document_Master_Field__c, Field_Name__c, Id, Identifier__c, Is_Active__c, Label, Language, Master_Object_Name__c, MasterLabel, NamespacePrefix, Object_Name__c, QualifiedApiName, SystemModstamp from Document_Master_Field_Mapping__mdt where Is_Active__c = true];//Document_Master_Field_Mapping__mdt.getAll();
        Map<String, List<String>> masterFieldMap = new Map<String, List<String>>();
        Map<String, List<String>> objectToFieldsMap = new Map<String, List<String>>();
        Map<String, Map<String, String>> masterToObj = new Map<String, Map<String, String>>();
        Map<String, String> objectRecToQuery = new Map<String, String>();
        for (Document_Master_Field_Mapping__mdt mapping : allMetaData) {
            if (mapping.Master_Object_Name__c != null) {
                String docMasterName = mapping.Master_Object_Name__c;
                String documentField = mapping.Document_Master_Field__c;
                String objectName = mapping.Object_Name__c;
                String fieldName = mapping.Field_Name__c;
                // Populate masterFieldMap
                if (!masterFieldMap.containsKey(docMasterName)) {
                    masterFieldMap.put(docMasterName, new List<String>{documentField});
                }
                else{
                    masterFieldMap.get(docMasterName).add(documentField);
                }
                // Populate objectToFieldsMap
                if (!objectToFieldsMap.containsKey(objectName)) {
                    objectToFieldsMap.put(objectName, new List<String>{fieldName});
                }
                else{
                    objectToFieldsMap.get(objectName).add(fieldName);
                }
                // Populate masterToObj Map
                if (documentField != null && objectName != null && fieldName != null) {
                    if (!masterToObj.containsKey(documentField)) {
                        Map<String,String> tempMap= new Map<String,String>();
                        tempMap.put(objectName, fieldName);
                        masterToObj.put(documentField,tempMap);
                    }else{
                        masterToObj.get(documentField).put(objectName, fieldName);
                    }
                }
            }
        }
        
        String whereClause = '';
        if (identifier == 'fromLoan') {
            whereClause = ' Is_Active__c= true AND Stage__c =\'Sales login\' AND ( Requirement_At__c = \'Loan Application\' OR  Requirement_At__c = \'Applicant Level\' OR  Requirement_At__c = \'Application Level\') ORDER BY Sequence__c,Document_Type__c,Name';
        }
        for (String objectName : masterFieldMap.keySet()) {
            // Retrieve fields for the current object
            List<String> fieldList = masterFieldMap.get(objectName);
            Set<String> fieldsToQuery = new Set<String> {
                'Id','Name', 'Document_Category__c', 'Is_Required__c', 'Document_Name__c', 'Requirement_At__c','Document_Type__c','Form_Common_Identifier__c','Applicable_Product__c'
            };
            // Add dynamic fields from the fieldList
            if (fieldList != null) {
                fieldsToQuery.addAll(fieldList);
            }
            // Construct the SELECT clause
            String query = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ') +
                ' FROM ' + objectName +
                ' WHERE ' + whereClause;
            // Add the query to the map
            objectRecToQuery.put(objectName, query);
        }
        List<Document_Master__c> sobjMasterList = new List<Document_Master__c>();
        for (String obj : objectRecToQuery.keySet()) {
            List<Document_Master__c> results = Database.query(objectRecToQuery.get(obj));
            sobjMasterList.addAll(results);
        }
        List<Opportunity> oppList = [Select Id, Product__c from Opportunity where Id =: recordId];
        List<Document_Master__c> filteredDmlist = new List<Document_Master__c>();
        for (Document_Master__c dm : sobjMasterList) {
            if(dm.Applicable_Product__c !=null){
                List<String> prodList = dm.Applicable_Product__c.split(';');
                if(prodList.contains(oppList[0].Product__c)){
                    filteredDmlist.add(dm);
                }
            }
        }
        System.debug('filteredDmlist=:'+filteredDmlist.size());
        Map<String, String> objQueryMap = new Map<String, String>();
        for (String cmpObjName : objectToFieldsMap.keySet()) {
            String query = 'SELECT Id';
            List<String> fields = objectToFieldsMap.get(cmpObjName);
            for (String f : fields) {
                if (f != null) {
                    query += ', ' + f; // Append each field to the query
                }
            }
            if (cmpObjName == 'Opportunity') {
                query += ' FROM Opportunity WHERE Id = :recordId';
            }
            else if (cmpObjName == 'Application_Applicant__c') {
                if(identifier=='fromLoan'){
                    if(String.isBlank(applicantId)){
                        query += ' FROM Application_Applicant__c WHERE Loan_Application__c = :recordId and Applicant_Type__c= \'Applicant\'';
                    }else{
                        query += ' FROM Application_Applicant__c WHERE id = :applicantId and Applicant_Type__c != \'Seller\' and  Applicant_Type__c!= \'Builder\'';
                    }
                }
            }
            else if(cmpObjName=='Applicant_Address__c'){
                query += ' FROM Applicant_Address__c WHERE Application_Applicant__r.Loan_Application__c = :recordId LIMIT 1';
            }
            objQueryMap.put(cmpObjName, query);
        }
        String primaryApplicantId;
        if(String.isBlank(applicantId)){
            primaryApplicantId= [Select id, Loan_Application__c from Application_Applicant__c where Loan_Application__c=:recordId and Applicant_Type__c='Primary Applicant'].id;
        }
        Map<String, List<SObject>> objectValMap = new Map<String, List<SObject>>();
        for (String str : objQueryMap.keySet()) {
            system.debug(objQueryMap.get(str));
            List<SObject> sobjList = Database.query(objQueryMap.get(str));
            objectValMap.put(str, sobjList);
        }
        if (identifier == 'fromLoan' && objectValMap.containsKey('Opportunity')) {
            List<SObject> opps = objectValMap.get('Opportunity');
            if (opps != null && !opps.isEmpty()) {
                SObject opp = opps[0];
                String stg = (String) opp.get('StageName');
                if (stg != null && stg.equalsIgnoreCase('Credit Underwriting')) {
                    opp.put('StageName', 'Sales login');
                }
            }
        }
        List<Document_Master__c> finalDMList = new List<Document_Master__c>();
        for (Document_Master__c dm : filteredDmlist) {
            Boolean isValid = true;
            for (String s : masterToObj.keySet()) {
                Object masterVal;
                Map<String, String> tempMap = masterToObj.get(s);
                Boolean isMultiSelect = isFieldMultiSelectPicklist('Document_Master__c', s);
                if (isMultiSelect) {
                    // For multi-select picklist fields
                    masterVal = dm.get(s);
                    List<String> splittedValues = new List<String>();
                    if (masterVal != null) {
                        // Split the multi-select picklist values
                        splittedValues = (((String)masterVal).replace('\u200b','')).split(';');
                        // if(!splittedValues.isEmpty()){
                            //     for(Integer i=0; i<splittedValues.size();i++){
                                //         splittedValues[i] = splittedValues[i];
                            //     }
                        // }
                        
                    }
                    // Add logic to check if the final values are in the list of splitted values
                    List<SObject> sObjList = objectValMap.get(tempMap.keySet().iterator().next());
                    if (sObjList != null && !sObjList.isEmpty()) {
                        String finalVal;
                        if(tempMap.values().iterator().next().contains('__r.')){
                            SObject parenObj = sObjList[0].getSobject(String.valueOf(tempMap.values().iterator().next()).split('\\.')[0]);
                            finalVal = String.valueOf(parenObj.get(String.valueOf(tempMap.values().iterator().next()).split('\\.')[1]));
                        }
                        else{
                            finalVal = String.valueOf(sObjList[0].get(tempMap.values().iterator().next())).replace('\u200b','');
                        }
                        if (!splittedValues.contains(finalVal) && String.isNotBlank(finalVal) ) {
                            isValid = false;
                            break;
                        }
                    } else {
                        isValid = false;
                        break;
                    }
                } else {
                    // For non-multi-select picklist fields
                    masterVal = dm.get(s);
                    List<SObject> sObjList = objectValMap.get(tempMap.keySet().iterator().next());
                    if (sObjList != null && !sObjList.isEmpty()) {
                        String finalVal;
                        if(tempMap.values().iterator().next().contains('__r.')){
                            SObject parenObj = sObjList[0].getSobject(String.valueOf(tempMap.values().iterator().next()).split('\\.')[0]);
                            finalVal = String.valueOf(parenObj.get(String.valueOf(tempMap.values().iterator().next()).split('\\.')[1]));
                        }
                        else{
                            finalVal = String.valueOf(sObjList[0].get(tempMap.values().iterator().next())).replace('\u200b','');
                        }
                        if (finalVal != null && !finalVal.equals(masterVal)) {
                            isValid = false;
                            break;
                        }
                    } else {
                        isValid = false; // If related records do not exist
                        break;
                    }
                }
            }
            if (isValid) {
                finalDMList.add(dm);
            }
            
        }
        Map<String,Document_Details__c> keyToChecklistMap = new Map<String,Document_Details__c>();
        Map<String,List<String>> keyToCategoriesMap = new Map<String,List<String>>();
        for (Document_Master__c docMasterIter : finalDMList) {
            if(!docTypeMap.containsKey(docMasterIter.Document_Type__c)){
                docTypeMap.put(docMasterIter.Document_Type__c,new List<Document_Master__c>());
            }
            docTypeMap.get(docMasterIter.Document_Type__c).add(docMasterIter);
        }
        List<Document_Details__c> documentDetails = [SELECT ID,Is_Required__c,Document_Master__c, Consider_for_Loan_Application__c FROM Document_Details__c WHERE Applicant__c =: applicantId AND Consider_for_Loan_Application__c = true ];
        for(String str : docTypeMap.KeySet()){
            docWrapper wrap = new docWrapper();
            wrap.docType = str;
            wrap.docList = docTypeMap.get(str);
            wrap.docDetList = documentDetails;
            docWrapperTypeList.add(wrap);
        }
        // System.debug('docWrapperTypeList-----'+docWrapperTypeList);
        return docWrapperTypeList;
    }
    public class docWrapper{
        @AuraEnabled public string docType;
        @AuraEnabled public List<Document_Master__c> docList;
        @AuraEnabled public List<Document_Details__c> docDetList;
        @AuraEnabled public List<Document_Details__c> docChecklistToBeCreated;
    }
    
    @AuraEnabled
    public static void executeMapping(String identifier, String recordId, String applicantId, String applicantType) {
        Map<String, Document_Master_Field_Mapping__mdt> allMetaData = Document_Master_Field_Mapping__mdt.getAll();
        Map<String, List<String>> masterFieldMap = new Map<String, List<String>>();
        Map<String, List<String>> objectToFieldsMap = new Map<String, List<String>>();
        Map<String, Map<String, String>> masterToObj = new Map<String, Map<String, String>>();
        Map<String, String> objectRecToQuery = new Map<String, String>();
        
        for (Document_Master_Field_Mapping__mdt mapping : allMetaData.values()) {
            if (mapping.Master_Object_Name__c != null) {
                String docMasterName = mapping.Master_Object_Name__c;
                String documentField = mapping.Document_Master_Field__c;
                String objectName    = mapping.Object_Name__c;
                String fieldName     = mapping.Field_Name__c;
                
                if (!masterFieldMap.containsKey(docMasterName)) {
                    masterFieldMap.put(docMasterName, new List<String>{ documentField });
                } else {
                    masterFieldMap.get(docMasterName).add(documentField);
                }
                
                if (!objectToFieldsMap.containsKey(objectName)) {
                    objectToFieldsMap.put(objectName, new List<String>{ fieldName });
                } else {
                    objectToFieldsMap.get(objectName).add(fieldName);
                }
                
                if (documentField != null && objectName != null && fieldName != null) {
                    if (!masterToObj.containsKey(documentField)) {
                        Map<String, String> tempMap = new Map<String, String>();
                        tempMap.put(objectName, fieldName);
                        masterToObj.put(documentField, tempMap);
                    } else {
                        masterToObj.get(documentField).put(objectName, fieldName);
                    }
                }
            }
        }
        
        String whereClause = '';
        if (identifier == 'fromLoan') {
            whereClause = ' Is_Active__c = true AND Stage__c = \'Sales login\' AND ( Requirement_At__c = \'Loan Application\' OR Requirement_At__c = \'Applicant Level\' OR Requirement_At__c = \'Application Level\')';
        }
        
        for (String objectName : masterFieldMap.keySet()) {
            List<String> fieldList = masterFieldMap.get(objectName);
            Set<String> fieldsToQuery = new Set<String>{
                'Id', 'Document_Category__c', 'Is_Required__c', 'Document_Name__c',
                'Requirement_At__c', 'Document_Type__c', 'Visibility_Controller__c', 'Applicable_Product__c'
            };
            if (fieldList != null) {
                fieldsToQuery.addAll(fieldList);
            }
            String query = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ')
                + ' FROM ' + objectName
                + ' WHERE ' + whereClause;
            objectRecToQuery.put(objectName, query);
        }
        
        List<Document_Master__c> sobjMasterList = new List<Document_Master__c>();
        for (String obj : objectRecToQuery.keySet()) {
            List<Document_Master__c> results = Database.query(objectRecToQuery.get(obj));
            sobjMasterList.addAll(results);
        }
        
        // Filter by Opportunity Product
        List<Opportunity> oppList = [SELECT Id, Product__c FROM Opportunity WHERE Id = :recordId];
        List<Document_Master__c> filteredDmlist = new List<Document_Master__c>();
        for (Document_Master__c dm : sobjMasterList) {
            if (dm.Applicable_Product__c != null) {
                List<String> prodList = dm.Applicable_Product__c.split(';');
                if (prodList.contains(oppList[0].Product__c)) {
                    filteredDmlist.add(dm);
                }
            }
        }
        
        // Build object value map for dynamic field matching
        Map<String, String> objQueryMap = new Map<String, String>();
        for (String cmpObjName : objectToFieldsMap.keySet()) {
            String query = 'SELECT Id';
            List<String> fields = objectToFieldsMap.get(cmpObjName);
            for (String f : fields) {
                if (f != null) {
                    query += ', ' + f;
                }
            }
            if (cmpObjName == 'Opportunity') {
                query += ' FROM Opportunity WHERE Id = :recordId';
            } else if (cmpObjName == 'Application_Applicant__c') {
                if (identifier == 'fromLoan') {
                    if (String.isBlank(applicantId)) {
                        query += ' FROM Application_Applicant__c WHERE Loan_Application__c = :recordId AND Applicant_Type__c = \'Applicant\'';
                    } else {
                        query += ' FROM Application_Applicant__c WHERE id = :applicantId AND Applicant_Type__c != \'Seller\' AND Applicant_Type__c != \'Builder\'';
                    }
                }
            } else if (cmpObjName == 'Applicant_Address__c') {
                query += ' FROM Applicant_Address__c WHERE Application_Applicant__r.Loan_Application__c = :recordId LIMIT 1';
            }
            objQueryMap.put(cmpObjName, query);
        }
        
        // Resolve primary applicant if applicantId is blank
        String primaryApplicantId;
        if (String.isBlank(applicantId)) {
            primaryApplicantId = [
            SELECT Id FROM Application_Applicant__c
            WHERE Loan_Application__c = :recordId
            AND Applicant_Type__c = 'Primary Applicant'
        ].Id;
        }
        
        Map<String, List<SObject>> objectValMap = new Map<String, List<SObject>>();
        for (String str : objQueryMap.keySet()) {
            List<SObject> sobjList = Database.query(objQueryMap.get(str));
            objectValMap.put(str, sobjList);
        }
        
        // Treat Credit Underwriting as Sales login for document matching
        if (identifier == 'fromLoan' && objectValMap.containsKey('Opportunity')) {
            List<SObject> opps = objectValMap.get('Opportunity');
            if (opps != null && !opps.isEmpty()) {
                SObject opp = opps[0];
                String stg = (String) opp.get('StageName');
                if (stg != null && stg.equalsIgnoreCase('Credit Underwriting')) {
                    opp.put('StageName', 'Sales login');
                }
            }
        }
        
        // Run dynamic field matching against Document Masters
        List<Document_Master__c> finalDMList = new List<Document_Master__c>();
        System.debug('filteredDmlist---' + filteredDmlist.size());
        
        for (Document_Master__c dm : filteredDmlist) {
            Boolean isValid = true;
            for (String s : masterToObj.keySet()) {
                Object masterVal;
                Map<String, String> tempMap = masterToObj.get(s);
                Boolean isMultiSelect = isFieldMultiSelectPicklist('Document_Master__c', s);
                
                if (isMultiSelect) {
                    masterVal = dm.get(s);
                    List<String> splittedValues = new List<String>();
                    if (masterVal != null) {
                        splittedValues = (((String) masterVal).replace('\u200b', '')).split(';');
                    }
                    List<SObject> sObjList = objectValMap.get(tempMap.keySet().iterator().next());
                    if (sObjList != null && !sObjList.isEmpty()) {
                        String finalVal;
                        if (tempMap.values().iterator().next().contains('__r.')) {
                            SObject parenObj = sObjList[0].getSobject(
                                String.valueOf(tempMap.values().iterator().next()).split('\\.')[0]
                                );
                            finalVal = String.valueOf(
                                parenObj.get(String.valueOf(tempMap.values().iterator().next()).split('\\.')[1])
                                );
                        } else {
                            if (String.isNotBlank(String.valueOf(sObjList[0].get(tempMap.values().iterator().next())))) {
                                finalVal = String.valueOf(
                                    sObjList[0].get(tempMap.values().iterator().next())
                                    ).replace('\u200b', '');
                            }
                        }
                        if (!splittedValues.contains(finalVal) && String.isNotBlank(finalVal)) {
                            isValid = false;
                            break;
                        }
                    } else {
                        isValid = false;
                        break;
                    }
                } else {
                    masterVal = dm.get(s);
                    List<SObject> sObjList = objectValMap.get(tempMap.keySet().iterator().next());
                    if (sObjList != null && !sObjList.isEmpty()) {
                        String finalVal;
                        if (tempMap.values().iterator().next().contains('__r.')) {
                            SObject parenObj = sObjList[0].getSobject(
                                String.valueOf(tempMap.values().iterator().next()).split('\\.')[0]
                                );
                            finalVal = String.valueOf(
                                parenObj.get(String.valueOf(tempMap.values().iterator().next()).split('\\.')[1])
                                );
                        } else {
                            finalVal = String.valueOf(
                                sObjList[0].get(tempMap.values().iterator().next())
                                ).replace('\u200b', '');
                        }
                        if (finalVal != null && !finalVal.equals(masterVal)) {
                            isValid = false;
                            break;
                        }
                    } else {
                        isValid = false;
                        break;
                    }
                }
            }
            if (isValid) {
                finalDMList.add(dm);
            }
        }
        
        System.debug('finalDMList---' + finalDMList);
        
        // ─────────────────────────────────────────────────────────────────
        // Fetch existing checklists for deduplication and Form 60 detection
        // ─────────────────────────────────────────────────────────────────
        Set<String> existingChecklistSet = new Set<String>();
        List<Document_Details__c> existingChecklists = [
        SELECT Id, Name, Document_Details__c, Requirement_Level__c,
               Applicant__c, Loan_Application__c,
               Document_Master__r.Document_Type__c,
               Document_Master__r.Name,
               Content_Document_Id__c, Active__c,
               Consider_for_Loan_Application__c
        FROM Document_Details__c
        WHERE Loan_Application__c = :recordId
        AND Requirement_Level__c != null
        AND Name != null
    ];
        
        for (Document_Details__c checklist : existingChecklists) {
            String key;
            if (identifier == 'fromLoan') {
                if (checklist.Requirement_Level__c == 'Applicant Level') {
                    key = checklist.Name + '_'
                        + checklist.Document_Master__r.Document_Type__c + '_'
                        + checklist.Requirement_Level__c + '_'
                        + checklist.Applicant__c;
                } else if (checklist.Requirement_Level__c == 'Loan Application'
                || checklist.Requirement_Level__c == 'Application Level') {
                    key = checklist.Name + '_'
                        + checklist.Document_Master__r.Document_Type__c + '_'
                        + checklist.Requirement_Level__c + '_'
                        + checklist.Loan_Application__c;
                }
            } else {
                key = checklist.Name + '_'
                    + checklist.Document_Master__r.Document_Type__c + '_'
                    + checklist.Requirement_Level__c + '_'
                    + checklist.Applicant__c;
            }
            existingChecklistSet.add(key);
        }
        
        // ─────────────────────────────────────────────────────────────────
        // FIX: Detect Form 60 uploaded applicants
        // - Case-insensitive check
        // - Handles "Form 60" (space) not just "Form-60" (hyphen)
        // - Checks BOTH the Document_Details Name AND Document_Master Name
        // ─────────────────────────────────────────────────────────────────
        Set<Id> applicantsWithForm60Uploaded = new Set<Id>();
        for (Document_Details__c c : existingChecklists) {
            if (c.Requirement_Level__c == 'Applicant Level'
                && c.Applicant__c != null
                && c.Active__c == true
                && c.Consider_for_Loan_Application__c == true
                && String.isNotBlank(c.Content_Document_Id__c)
                && (
                (c.Name != null && c.Name.trim().equalsIgnoreCase('Form 60'))
                || (c.Document_Master__r != null
                && c.Document_Master__r.Name != null
                && c.Document_Master__r.Name.trim().equalsIgnoreCase('Form 60'))
                )
            ) {
                applicantsWithForm60Uploaded.add(c.Applicant__c);
                System.debug('Form 60 already uploaded for applicant: ' + c.Applicant__c);
            }
        }
        
        // Also check IsForm60Uploaded__c field on the applicant record as a fallback
        // This covers the case where Form 60 was selected but not yet a Document_Details record
        List<Application_Applicant__c> applicantsToCheck = [
        SELECT Id, IsForm60Uploaded__c
        FROM Application_Applicant__c
        WHERE Loan_Application__c = :recordId
    ];
        for (Application_Applicant__c app : applicantsToCheck) {
            if (app.IsForm60Uploaded__c == 'Yes') {
                applicantsWithForm60Uploaded.add(app.Id);
                System.debug('Form 60 flagged on applicant record: ' + app.Id);
            }
        }
        
        System.debug('applicantsWithForm60Uploaded: ' + applicantsWithForm60Uploaded);
        
        // Fetch applicant details for Visibility_Controller__c checks
        Application_Applicant__c applicant = [
        SELECT Id, Customer_Type__c, Customer_Profile__c,
               Sub_Employment_Type_Non_Individual__c, PAN_Number__c
        FROM Application_Applicant__c
        WHERE Id = :applicantId
    ];
        
        Boolean hasManualPAN = false;
        try {
            hasManualPAN = (String.valueOf(applicant.get('PAN_Number__c')) != null
                && String.valueOf(applicant.get('PAN_Number__c')).trim() != '');
        } catch (Exception e) {
            System.debug('PAN check error: ' + e.getMessage());
        }
        
        // ─────────────────────────────────────────────────────────────────
        // Main loop: create Document_Details__c records
        // ─────────────────────────────────────────────────────────────────
        List<Document_Details__c> documentListToInsert = new List<Document_Details__c>();
        Map<String, Document_Details__c> keyToChecklistMap = new Map<String, Document_Details__c>();
        Map<String, List<String>> keyToCategoriesMap = new Map<String, List<String>>();
        
        for (Document_Master__c docMasterIter : finalDMList) {
            
            if (!String.isBlank(applicantId) && docMasterIter.Requirement_At__c == 'Applicant Level') {
                // applicantId is already set — use it directly
            } else if (!String.isBlank(primaryApplicantId) && docMasterIter.Requirement_At__c == 'Applicant Level') {
                applicantId = primaryApplicantId;
            }
            
            String key    = docMasterIter.Document_name__c + '_'
                + docMasterIter.Document_Type__c + '_'
                + docMasterIter.Requirement_At__c + '_'
                + applicantId;
            String loanKey = docMasterIter.Document_name__c + '_'
                + docMasterIter.Document_Type__c + '_'
                + docMasterIter.Requirement_At__c + '_'
                + recordId;
            
            if (!existingChecklistSet.contains(key) && !existingChecklistSet.contains(loanKey)) {
                existingChecklistSet.add(key);
                
                Document_Details__c documentObj = new Document_Details__c();
                documentObj.Document_Details__c = docMasterIter.Document_Type__c;
                
                // ─────────────────────────────────────────────────────
                // PAN BLOCK
                // FIX: Skip PAN creation entirely if Form 60 is uploaded
                // ─────────────────────────────────────────────────────
                if (docMasterIter.Document_name__c != null
                && docMasterIter.Document_name__c.trim().equalsIgnoreCase('PAN')) {
                    
                    Id targetApplicantForThisDoc =
                        (docMasterIter.Requirement_At__c == 'Applicant Level')
                        ? (String.isBlank(applicantId) ? primaryApplicantId : applicantId)
                        : null;
                    
                    Boolean form60UploadedForApplicant =
                        (targetApplicantForThisDoc != null)
                        && applicantsWithForm60Uploaded.contains(targetApplicantForThisDoc);
                    
                    if (form60UploadedForApplicant) {
                        // FIX: Skip creating PAN record entirely — do not insert
                        System.debug('Skipping PAN creation for applicant '
                            + targetApplicantForThisDoc + ' because Form 60 is uploaded.');
                        continue; // ← Skip to next Document Master
                    }
                    
                    // Form 60 not uploaded — create PAN record as required
                    documentObj.Document_Details__c             = 'POI';
                    documentObj.Consider_for_Loan_Application__c = true;
                    documentObj.Is_Required__c                   = true;
                    
                    // ─────────────────────────────────────────────────────
                    // PHOTOGRAPH BLOCK (unchanged)
                    // ─────────────────────────────────────────────────────
                } else if (docMasterIter.Document_name__c != null
                && docMasterIter.Document_name__c.trim().equalsIgnoreCase('Photograph')) {
                    
                    documentObj.Document_Details__c             = 'POI';
                    documentObj.Consider_for_Loan_Application__c = true;
                    documentObj.Is_Required__c                   = true;
                    
                    // ─────────────────────────────────────────────────────
                    // VISIBILITY CONTROLLER — single level (Type -: Profile)
                    // ─────────────────────────────────────────────────────
                } else if (docMasterIter.Visibility_Controller__c != null
                && docMasterIter.Visibility_Controller__c.countMatches('-:') == 1) {
                    
                    String visibilityControllerValue = docMasterIter.Visibility_Controller__c;
                    String[] visibilityControllerParts = visibilityControllerValue.split('-:');
                    
                    if (visibilityControllerParts.size() == 2) {
                        String firstPart  = visibilityControllerParts[0];
                        String secondPart = visibilityControllerParts[1];
                        List<String> secondPartList = secondPart.contains(';')
                            ? secondPart.split(';')
                        : new List<String>{ secondPart };
                        
                        if (secondPartList.contains(applicant.Customer_Profile__c)
                        && applicant.Customer_Type__c == firstPart) {
                            documentObj.Consider_for_Loan_Application__c = true;
                            documentObj.Is_Required__c                   = true;
                        }
                    }
                    
                    // ─────────────────────────────────────────────────────
                    // VISIBILITY CONTROLLER — two levels (Type -: Profile -: SubType)
                    // ─────────────────────────────────────────────────────
                } else if (docMasterIter.Visibility_Controller__c != null
                && docMasterIter.Visibility_Controller__c.countMatches('-:') == 2) {
                    
                    String visibilityControllerValue = docMasterIter.Visibility_Controller__c;
                    String[] visibilityControllerParts = visibilityControllerValue.split('-:');
                    
                    if (visibilityControllerParts.size() == 3) {
                        String firstPart  = visibilityControllerParts[0];
                        String secondPart = visibilityControllerParts[1];
                        String thirdPart  = visibilityControllerParts[2];
                        
                        List<String> secondPartList = secondPart.contains(';')
                            ? secondPart.split(';')
                        : new List<String>{ secondPart };
                        List<String> thirdPartList = thirdPart.contains(';')
                            ? thirdPart.split(';')
                        : new List<String>{ thirdPart };
                        
                        if (secondPartList.contains(applicant.Customer_Profile__c)
                            && applicant.Customer_Type__c == firstPart
                        && thirdPartList.contains(applicant.Sub_Employment_Type_Non_Individual__c)) {
                            documentObj.Consider_for_Loan_Application__c = true;
                            documentObj.Is_Required__c                   = true;
                        }
                    }
                    
                    // ─────────────────────────────────────────────────────
                    // DEFAULT — no visibility controller
                    // ─────────────────────────────────────────────────────
                } else {
                    documentObj.Consider_for_Loan_Application__c = false;
                }
                
                documentObj.Document_Required__c = documentObj.Is_Required__c ? 'Required' : 'Optional';
                
                if (identifier == 'fromLoan') {
                    documentObj.Loan_Application__c      = recordId;
                    documentObj.Is_Sales_Manual_Document__c = true;
                    if (!String.isBlank(applicantId)
                    && docMasterIter.Requirement_At__c == 'Applicant Level') {
                        documentObj.Applicant__c = applicantId;
                    }
                }
                
                documentObj.Status__c        = 'Pending';
                documentObj.Name             = docMasterIter.Document_name__c;
                documentObj.Document_Master__c = docMasterIter.Id;
                documentObj.Active__c        = true;
                
                if (identifier == 'fromLoan') {
                    documentObj.Requirement_Level__c = docMasterIter.Requirement_At__c;
                    documentListToInsert.add(documentObj);
                    
                    keyToChecklistMap.put(key, documentObj);
                    
                    if (keyToCategoriesMap.containsKey(key)) {
                        keyToCategoriesMap.get(key).add(docMasterIter.Document_Category__c);
                    } else {
                        keyToCategoriesMap.put(key, new List<String>{ docMasterIter.Document_Category__c });
                    }
                } else {
                    if (keyToCategoriesMap.containsKey(key)) {
                        keyToCategoriesMap.get(key).add(docMasterIter.Document_Category__c);
                    } else {
                        keyToCategoriesMap.put(key, new List<String>{ docMasterIter.Document_Category__c });
                    }
                }
            }
            
            // Update category on already-mapped checklist records
            for (String keyVal : keyToChecklistMap.keySet()) {
                if (keyToCategoriesMap.containsKey(keyVal)) {
                    Document_Details__c docList = keyToChecklistMap.get(keyVal);
                    // docList.Document_Categorization__c = String.join(keyToCategoriesMap.get(keyVal), ';');
                }
            }
        }
        
        if (!documentListToInsert.isEmpty()) {
            insert documentListToInsert;
            System.debug('documentListToInsert----' + documentListToInsert);
        }
    }
    public static Boolean isFieldMultiSelectPicklist(String objectName, String fieldName) {
        // Get the global describe for the specified object
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType != null) {
            Schema.SObjectField fieldToken = objectType.getDescribe().fields.getMap().get(fieldName);
            if (fieldToken != null) {
                Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
                if (fieldDescribe.getType() == Schema.DisplayType.MultiPicklist) {
                    return true;
                }
            }
            else {
                System.debug('Field not found: ' + fieldName);
            }
        }else{
            System.debug('Object not found: ' + objectName);
        }
        return false;
    }
    public static List<String> getFieldsToMonitor(String objectName) {
        // Retrieve Document Master Field Mappings
        List<Document_Master_Field_Mapping__mdt> mappings = new List<Document_Master_Field_Mapping__mdt>();
        if(Schema.sObjectType.Document_Master_Field_Mapping__mdt.isAccessible()){
            
            mappings = [
                SELECT Master_Object_Name__c, Field_Name__c 
                FROM Document_Master_Field_Mapping__mdt 
                WHERE Is_Active__c = true AND Object_Name__c = :objectName
            ];
        }
        // Collect fields to monitor
        List<String> fieldsToMonitor = new List<String>();
        for (Document_Master_Field_Mapping__mdt mapping : mappings) {
            if (mapping.Field_Name__c != null) {
                fieldsToMonitor.add(mapping.Field_Name__c);
            }
        }
        
        return fieldsToMonitor;
    }
    public class DocumentDetails{
        @AuraEnabled public String documentCategoryName;
        @AuraEnabled public List<DocBundleWrapper> docDetails;
    }
    
    @AuraEnabled
    public static List<DocumentDetails> getDocumentChecklistRecords(String recId, String processObject, List<Id> masterIds){
        List<DocumentDetails> docDetailsList = new List<DocumentDetails>();
        String profileName = Utility.getCurrentUserProfileName();
        Utility_V1.ProductWrapper prodWrapper = Utility_V1.getProductDetails(new Map<String,String>{'oppId' => recId}); //for HL case
        
        try {
            Map<String,List<DocBundleWrapper>> categoryWiseDocMap = new Map<String,List<DocBundleWrapper>>();
            
            List<Document_Details__c> documentList = new List<Document_Details__c>();
            if(processObject == 'Loan Application'){
                if (masterIds != null && !masterIds.isEmpty()) {
                    
                    documentList = [
                                        SELECT Id, Name, Content_Document_Id__c, Is_Uploaded__c, Is_Required__c,Mandatory_Esign_Document__c, Document_Master__r.Document_Category__c, Document_Master__r.Applicable_For_OCR__c, Password__c, Document_URI__c ,Document_Master__c,Process_Name__c,
                                    Location__Latitude__s, Location__Longitude__s,Is_manual_masking_confirmed__c,Document_Details__c,Applicant__r.Applicant_Name__c,Applicant__r.Is_Financial_applicant__c,Requirement_Level__c,Applicant__c,File_Name__c,
                                    Applicant__r.Applicant_Type__c,Applicant__r.Customer_Type__c,CreatedDate, CreatedBy.Name,LastModifiedBy.Name,LastModifiedDate, Loan_Application__r.StageName, (SELECT Id FROM Applicant_Address__r LIMIT 1), Uploaded_Date_Time__c,Is_Verified__c  
                                    FROM Document_Details__c
                                        WHERE Loan_Application__c =:recId AND Active__c = true AND Consider_for_Loan_Application__c = true AND Document_Master__c IN :masterIds ORDER BY Name ASC
                                        ]; /* and Document_Details__c!=null */
                }
                else{
                    documentList = [
                            SELECT Id, Name, Content_Document_Id__c, Is_Uploaded__c,Process_Name__c, Is_Required__c, Mandatory_Esign_Document__c, Document_Master__c, Password__c,
                            Document_Master__r.Document_Category__c, Is_manual_masking_confirmed__c,Document_Master__r.Applicable_For_OCR__c, Document_URI__c,File_Name__c,
                            Location__Latitude__s, Location__Longitude__s, Applicant__r.Is_Financial_applicant__c, Document_Details__c, Applicant__r.Applicant_Name__c,
                            Requirement_Level__c, Applicant__c, Applicant__r.Applicant_Type__c,Applicant__r.Customer_Type__c,CreatedDate, CreatedBy.Name,LastModifiedBy.Name,LastModifiedDate,
                            Loan_Application__r.StageName, (SELECT Id FROM Applicant_Address__r LIMIT 1), Uploaded_Date_Time__c, Is_Verified__c
                            FROM Document_Details__c WHERE Loan_Application__c = :recId AND Active__c = true AND Consider_for_Loan_Application__c = true ORDER BY Name ASC
                        ];
                }
            }
            else if(processObject == 'E-sign' || processObject == 'E-signed'){
                documentList = [SELECT Id, Name,Process_Name__c, Content_Document_Id__c, Is_Uploaded__c, Is_Required__c, CreatedBy.Name,LastModifiedBy.Name ,CreatedDate,
                    Document_Master__r.Document_Category__c, Status__c, Remarks__c, Uploaded_Date_Time__c, Document_URI__c , Applicant__r.Is_Financial_applicant__c,File_Name__c,
                    Location__Latitude__s,Esign_Document__c, Applicant__r.Applicant_Type__c, Applicant__r.Customer_Type__c,Location__Longitude__s, 
                    Document_Details__c,Applicant__c, Applicant__r.Name, Requirement_Level__c, Password__c,Mandatory_Esign_Document__c, Loan_Application__r.StageName, Document_Master__r.Applicable_For_OCR__c, Is_Verified__c, Is_manual_masking_confirmed__c,Applicant__r.Applicant_Name__c 
                    FROM Document_Details__c
                    WHERE Loan_Application__c = :recId and Active__c=true and Esign_Document__c = true and Document_Type__c != 'Merged Document' and Document_Type__c != 'ESigned Document' and Description__c != 'Non Mandatory Template Document'  Order By Mandatory_Esign_Document__c Desc];
            }
            else if(processObject == 'E-signed'){
                documentList = [SELECT Id, Name,Process_Name__c, Content_Document_Id__c, Is_Uploaded__c, Is_Required__c, LastModifiedBy.Name, CreatedBy.Name,CreatedDate,
                    Document_Master__r.Document_Category__c, Status__c, Remarks__c, Uploaded_Date_Time__c, Document_URI__c ,File_Name__c,
                    Location__Latitude__s,Esign_Document__c, Applicant__r.Applicant_Type__c, Location__Longitude__s,  Applicant__r.Is_Financial_applicant__c,
                    Document_Details__c,Applicant__c, Applicant__r.Name, Requirement_Level__c, Password__c,Mandatory_Esign_Document__c, Loan_Application__r.StageName, Is_Verified__c, Is_manual_masking_confirmed__c,Applicant__r.Applicant_Name__c 
                    FROM Document_Details__c
                    WHERE Loan_Application__c = :recId and Active__c=true and Esign_Document__c = true and Description__c != 'Non Mandatory Template Document'];
            }
            else if(processObject == 'Non-Mand E-sign'){
                documentList = [SELECT Id, Name,Document_Category__c,Process_Name__c, Content_Document_Id__c, Is_Uploaded__c, Is_Required__c, CreatedBy.Name,LastModifiedBy.Name, CreatedDate,
                    Document_Master__r.Document_Category__c, Status__c, Remarks__c, Uploaded_Date_Time__c, Document_URI__c ,File_Name__c,
                    Location__Latitude__s,Esign_Document__c, Applicant__r.Applicant_Type__c, Applicant__r.Customer_Type__c,Location__Longitude__s, 
                    Document_Details__c,Applicant__c, Applicant__r.Name, Requirement_Level__c, Password__c,Mandatory_Esign_Document__c, Loan_Application__r.StageName, Document_Master__r.Applicable_For_OCR__c,Applicant__r.Is_Financial_applicant__c, Is_Verified__c, Is_manual_masking_confirmed__c,Applicant__r.Applicant_Name__c 
                    FROM Document_Details__c
                    WHERE Loan_Application__c = :recId and Active__c=true and  Document_Type__c = 'Template Document' and Description__c = 'Non Mandatory Template Document'  Order By Mandatory_Esign_Document__c Desc];
            }
            else if(processObject == 'UpdatedEsign'){
                documentList = [SELECT Id, Name, Content_Document_Id__c,Process_Name__c, Is_Uploaded__c, Is_Required__c, LastModifiedBy.Name, CreatedBy.Name,CreatedDate, 
                    Document_Master__r.Document_Category__c, Status__c, Remarks__c, Uploaded_Date_Time__c, Document_URI__c ,File_Name__c,
                    Location__Latitude__s,Esign_Document__c, Applicant__r.Applicant_Type__c, Location__Longitude__s, Applicant__r.Is_Financial_applicant__c,
                    Document_Details__c,Applicant__c, Applicant__r.Name, Requirement_Level__c, Password__c,Mandatory_Esign_Document__c, Loan_Application__r.StageName, Is_Verified__c, Is_manual_masking_confirmed__c,Applicant__r.Applicant_Name__c 
                    FROM Document_Details__c
                    WHERE Loan_Application__c = :recId and Document_Details_Lookup__c=null and Active__c=false and Esign_Document__c = true and Esign_Status__c!=null];
            }
            
            Set<string> contDocSet = new Set<string>();
            List<ContentDocument> contDoc = new List<ContentDocument>();
            for(Document_Details__c dd : documentList) {
                if(string.isNotBlank(dd.Content_Document_Id__c)) {
                    contDocSet.add(dd.Content_Document_Id__c);
                }
            }
            if(Schema.sObjectType.ContentDocument.isAccessible()){
                contDoc = [SELECT Id,  LastModifiedBy.Name,CreatedBy.Name ,CreatedDate From ContentDocument WHERE Id IN: contDocSet];
            }
            Set<Id> docListIds = new Set<Id>();
            for(Document_Details__c dd : documentList){
                docListIds.add(dd.Content_Document_Id__c);
            }
            Set<Id> newdocIds = new Set<Id>();
            Set<Id> bsadocIds = new Set<Id>();
            Map<String,String> versionToDocMap = new Map<String,String>();
            Map<String,String> versionToFileName = new Map<String,String>();
            Map<Id, List<ContentDocumentLink>> docIdToCDLMap = new Map<Id, List<ContentDocumentLink>>();
            Boolean bsaUploaded = false;
            List<ContentDocumentLink> contentLinkList = new List<ContentDocumentLink>();
            for (Document_Details__c doc : documentList) {
                newdocIds.add(doc.Id);
            }
            Map<Id, List<Id>> creatorToDocMap = new Map<Id, List<Id>>();
            List<Document_Details__c> bsadoc = [Select Id,Content_Document_Id__c,name from Document_Details__c where Process_Name__c='Income Bank Statement' and Id IN:newdocIds];
            if(!bsadoc.isEmpty()){
                for(Document_Details__c ddc : bsadoc){
                    bsadocIds.add(ddc.Id);
                }
                if(!bsadocIds.isEmpty()){
                    bsaUploaded = true;
                    System.debug('bsadocIds '+bsadocIds);
                    // List<ContentVersion> cvRecVersionIdList = [Select Id,Title,ContentDocumentId from ContentVersion where ContentDocumentId IN : bsadocIds];
                    // if(!cvRecVersionIdList.isEmpty()){
                        // versionToDocMap.put(cvId.ContentDocumentId,cvId.Id);
                        // versionToFileName.put(cvId.ContentDocumentId,cvId.Title);
                        contentLinkList = [Select ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension, Id, IsDeleted, LinkedEntityId, ShareType, SystemModstamp, Visibility from ContentDocumentLink where LinkedEntityId in: bsadocIds];
                        for (ContentDocumentLink link : contentLinkList) {
                            if (!docIdToCDLMap.containsKey(link.LinkedEntityId)) {
                                docIdToCDLMap.put(link.LinkedEntityId, new List<ContentDocumentLink>());
                            }
                            docIdToCDLMap.get(link.LinkedEntityId).add(link);
                        }
                    }
                }
                System.debug('docIdToCDLMap : '+docIdToCDLMap);
                Map<Id, ContentDocument> cdRecMap = new Map<Id, ContentDocument>([Select Id, FileType, CreatedBy.Name, CreatedDate From ContentDocument Where Id =: contDocSet]);
                
                for(Document_Details__c dd : documentList){
                    DocBundleWrapper ddw = new DocBundleWrapper();
                    if(dd.Process_Name__c != 'Income Bank Statement'){
                        ddw.id = dd.Id;
                        ddw.name = dd.Name;
                        ddw.fileName = dd.File_Name__c;
                        ddw.bsa = false;
                        ddw.contentId = dd.Content_Document_Id__c;
                        ddw.masterId  = dd.Document_Master__c;
                        ddw.isRequired = dd.Is_Required__c;
                        ddw.retainDocDetailsRec = false;
                        ddw.showUpload = !dd.Is_Uploaded__c || dd.Content_Document_Id__c== null;
                        
                        if(profileName == 'Sales' && dd.Loan_Application__r.StageName == 'Credit Underwriting') {
                            ddw.showUpload = false;
                        }
                        else if(prodWrapper.isHLRelated && profileName == 'Credit Manager' && dd.Loan_Application__r.StageName == 'Credit Underwriting'){
                            ddw.showDelete = dd.Is_Uploaded__c;
                            ddw.retainDocDetailsRec = true;
                            ddw.autoShowDelete = true;
                        }
                        
                        ddw.showview = dd.Is_Uploaded__c && dd.Content_Document_Id__c!= null;
                        ddw.showRetake = true;
                        ddw.password = dd.Password__c;
                        ddw.showLocation = dd.Location__Latitude__s != null;
                        ddw.lattitude = dd.Location__Latitude__s;
                        ddw.longitude = dd.Location__Longitude__s;
                        ddw.category = dd.Document_Details__c;
                        ddw.docName = dd.Name +' ('+ dd.Document_Master__r.Document_Category__c +')';
                        ddw.docCategory = dd.Document_Master__r.Document_Category__c;
                        ddw.ocrApplicable = dd.Document_Master__r.Applicable_For_OCR__c;
                        ddw.custName = dd.Applicant__r.Applicant_Name__c;
                        ddw.isFinancialApplicant = dd.Applicant__r.Is_Financial_applicant__c;
                        ddw.applicantId = dd.Applicant__c;
                        ddw.isManualMasked = dd.Is_manual_masking_confirmed__c;
                        ddw.applicantType = dd.Applicant__r.Applicant_Type__c;
                        ddw.customerType = dd.Applicant__r.Customer_Type__c;
                        ddw.reqLevel = dd.Requirement_Level__c;
                        ddw.mntEsign = dd.Mandatory_Esign_Document__c;
                        ddw.fileType = cdRecMap.containsKey(dd.Content_Document_Id__c) ? cdRecMap.get(dd.Content_Document_Id__c).FileType : '';
                        if(categoryWiseDocMap.containsKey(dd.Document_Details__c)){
                            categoryWiseDocMap.get(dd.Document_Details__c).add(ddw);
                        }
                        else{
                            categoryWiseDocMap.put(dd.Document_Details__c,new List<DocBundleWrapper>{ddw});
                        }
                        if(dd.Content_Document_Id__c != null ) {
                            
                            if (!contDoc.isEmpty()) {
                                String name = contDoc[0].LastModifiedBy.Name;
                                DateTime createdDateTime = contDoc[0].CreatedDate;
                                String formattedDate = createdDateTime.format('dd-MM-yyyy');
                                String timestamp = String.valueOf(createdDateTime);
                                String combinedValue = name + ' ' + timestamp;
                                ddw.uploadDetails = combinedValue;
                                ddw.Uploadedby = name;
                                ddw.Timestamp = timestamp;
                            }
                            else {
                                ddw.uploadDetails = 'Content Document Not Found';
                            }
                        } else {
                            ddw.uploadDetails = 'Content Id Not Found';
                        }
                        ddw.docURI = dd.Document_URI__c;
                        // ddw.uploadedby = dd.LastModifiedBy.Name;
                        ddw.timestamp  = dd.CreatedDate.format('dd-MM-yyyy hh:mm a');
                        ddw.CreatedDate = dd.CreatedDate;
                        ddw.uploadedDateTime = dd.Uploaded_Date_Time__c;
                        ddw.isVerified = dd.Is_Verified__c;
                        // ddw.ckycSync = dd.Document_Master__r.CKYC_Sync__c;
                        ddw.addressRecordId = (dd.Applicant_Address__r != null && !dd.Applicant_Address__r.isEmpty()) ? dd.Applicant_Address__r[0].Id : null;
                    }
                    else{
                        ddw.id = dd.Id;
                        ddw.bsa = true;
                        ddw.name = dd.Name;
                        ddw.fileName = dd.File_Name__c;
                        ddw.contentId = dd.Content_Document_Id__c;
                        ddw.masterId  = dd.Document_Master__c;
                        ddw.isRequired = dd.Is_Required__c;
                        ddw.retainDocDetailsRec = false;
                        ddw.showUpload = !dd.Is_Uploaded__c || dd.Content_Document_Id__c== null;
                        
                        if(profileName == 'Sales' && dd.Loan_Application__r.StageName == 'Credit Underwriting') {
                            ddw.showUpload = false;
                        }
                        else if(prodWrapper.isHLRelated && profileName == 'Credit Manager' && dd.Loan_Application__r.StageName == 'Credit Underwriting'){
                            ddw.showDelete = dd.Is_Uploaded__c;
                            ddw.retainDocDetailsRec = true;
                            ddw.autoShowDelete = true;
                        }
                        
                        ddw.showview = dd.Is_Uploaded__c && dd.Content_Document_Id__c!= null;
                        ddw.showRetake = true;
                        ddw.showLocation = dd.Location__Latitude__s != null;
                        ddw.lattitude = dd.Location__Latitude__s;
                        ddw.longitude = dd.Location__Longitude__s;
                        ddw.category = dd.Document_Details__c;
                        ddw.password = dd.Password__c;
                        ddw.docName = dd.Name +' ('+ dd.Document_Master__r.Document_Category__c +')';
                        ddw.docCategory = dd.Document_Master__r.Document_Category__c;
                        ddw.ocrApplicable = dd.Document_Master__r.Applicable_For_OCR__c;
                        ddw.custName = dd.Applicant__r.Applicant_Name__c;
                        ddw.isFinancialApplicant = dd.Applicant__r.Is_Financial_applicant__c;
                        ddw.applicantId = dd.Applicant__c;
                        ddw.isManualMasked = dd.Is_manual_masking_confirmed__c;
                        ddw.applicantType = dd.Applicant__r.Applicant_Type__c;
                        ddw.customerType = dd.Applicant__r.Customer_Type__c;
                        ddw.reqLevel = dd.Requirement_Level__c;
                        ddw.mntEsign = dd.Mandatory_Esign_Document__c;
                        ddw.fileType = cdRecMap.containsKey(dd.Content_Document_Id__c) ? cdRecMap.get(dd.Content_Document_Id__c).FileType : '';
                        if(bsaUploaded){
                            ddw.bsaDocs = new List<ContentDocWrapper>();
                            for(ContentDocumentLink cl : contentLinkList){
                                ContentDocWrapper cdlWrap = new ContentDocWrapper();
                                cdlWrap.contentDocId = cl.ContentDocumentId;
                                cdlWrap.contentDocLinkId = cl.Id;
                                cdlWrap.linkedEntityId = cl.LinkedEntityId;
                                cdlWrap.fileName = cl.ContentDocument.Title+'.'+cl.ContentDocument.FileExtension;
                                cdlWrap.fileType = cl.ContentDocument.FileExtension != null ? cl.ContentDocument.FileExtension.toUpperCase() : '';
                                ddw.bsaDocs.add(cdlWrap);
                            }
                        }
                        if(categoryWiseDocMap.containsKey(dd.Document_Details__c)){
                            categoryWiseDocMap.get(dd.Document_Details__c).add(ddw);
                        }
                        else{
                            categoryWiseDocMap.put(dd.Document_Details__c,new List<DocBundleWrapper>{ddw});
                        }
                        if(dd.Content_Document_Id__c != null ) {
                            
                            if (!contDoc.isEmpty()) {
                                String name = contDoc[0].CreatedBy.Name;
                                DateTime createdDateTime = contDoc[0].CreatedDate;
                                String formattedDate = createdDateTime.format('dd-MM-yyyy');
                                String timestamp = String.valueOf(createdDateTime);
                                String combinedValue = name + ' ' + timestamp;
                                ddw.uploadDetails = combinedValue;
                                ddw.Uploadedby = name;
                                ddw.Timestamp = timestamp;
                            }
                            else {
                                ddw.uploadDetails = 'Content Document Not Found';
                            }
                        } else {
                            ddw.uploadDetails = 'Content Id Not Found';
                        }
                        ddw.docURI = dd.Document_URI__c;
                        // ddw.uploadedby = dd.CreatedBy.Name;
                        ddw.timestamp  = dd.CreatedDate.format('dd-MM-yyyy hh:mm a');
                        ddw.CreatedDate = dd.CreatedDate;
                        ddw.uploadedDateTime = dd.Uploaded_Date_Time__c;
                        ddw.isVerified = dd.Is_Verified__c;
                        // ddw.ckycSync = dd.Document_Master__r.CKYC_Sync__c;
                        ddw.addressRecordId = (dd.Applicant_Address__r != null && !dd.Applicant_Address__r.isEmpty()) ? dd.Applicant_Address__r[0].Id : null;
                    }
                }
                
                System.debug('categoryWiseDocMap=:'+categoryWiseDocMap);
                for(String key : categoryWiseDocMap.keySet()){
                    List<DocBundleWrapper> docBundleList = categoryWiseDocMap.get(key);
                    Integer seq=1;
                    for(DocBundleWrapper doc : docBundleList){
                        doc.seq = seq;
                        seq=seq+1;
                    }
                    DocumentDetails docVar = new DocumentDetails();
                    docVar.documentCategoryName = key;
                    docVar.docDetails = docBundleList;
                    docDetailsList.add(docVar);
                }
                System.debug('docDetailsList=:'+docDetailsList);
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
            System.debug('docDetailsList----'+docDetailsList);
            return docDetailsList;
        }
        
        public class DocBundleWrapper {
            @AuraEnabled public String id;
            @AuraEnabled public String name;
            @AuraEnabled public String fileName;
            @AuraEnabled public String contentId;
            @AuraEnabled public String fileType;
            @AuraEnabled public Id masterId;
            @AuraEnabled public String docName;
            @AuraEnabled public Boolean isRequired;
            @AuraEnabled public String category;
            @AuraEnabled public Boolean showUpload;
            @AuraEnabled public Boolean showView;
            @AuraEnabled public Boolean showDelete;
            @AuraEnabled public Boolean autoShowDelete;
            @AuraEnabled public Boolean showRetake;
            @AuraEnabled public Boolean showLocation;
            @AuraEnabled public Decimal lattitude;
            @AuraEnabled public Decimal longitude;
            @AuraEnabled public Boolean showLatLong;
            @AuraEnabled public Boolean retainDocDetailsRec;
            @AuraEnabled public Integer seq;
            @AuraEnabled public String docCategory;
            @AuraEnabled public String uploadDetails;
            @AuraEnabled public String custName;
            @AuraEnabled public String customerType;
            @AuraEnabled public String reqLevel;
            @AuraEnabled public String status;
            @AuraEnabled public String applicantType;
            @AuraEnabled public DateTime CreatedDate;
            @AuraEnabled public String CreatedByName;
            @AuraEnabled public String timestamp;
            @AuraEnabled public String uploadedby;
            @AuraEnabled public String remarks;
            @AuraEnabled public String password;
            @AuraEnabled public Boolean showPdf = false;
            @AuraEnabled public Boolean showImage = false;
            @AuraEnabled public String pdfUrl;
            @AuraEnabled public String imageUrl;
            @AuraEnabled public Integer versionNumber;
            @AuraEnabled public String applicantId;
            @AuraEnabled public Integer no;
            @AuraEnabled public String docURI;
            @AuraEnabled public Boolean mntEsign = false;
            @AuraEnabled public String addressRecordId;
            @AuraEnabled public DateTime uploadedDateTime;
            @AuraEnabled public Boolean ocrApplicable;
            @AuraEnabled public String contentVersionId;
            @AuraEnabled public Long timestampEpochMs;
            @AuraEnabled public String isFinancialApplicant;
            @AuraEnabled public Boolean isVerified;
            @AuraEnabled public Boolean isManualMasked;
            @AuraEnabled public Boolean ckycSync;
            @AuraEnabled public Boolean bsa;
            @AuraEnabled public List<ContentDocWrapper> bsaDocs;
        }
        
        @AuraEnabled
        public static List<pickListValueSet> getCustomerList(String loanId) {
            if (String.isBlank(loanId)) {
                throw new AuraHandledException('Loan ID cannot be null or blank.');
            }
            List<Application_Applicant__c> applicants = new List<Application_Applicant__c>();
            if(Schema.sObjectType.Application_Applicant__c.isAccessible()){
                applicants = [SELECT Id,Applicant_Name__c, Name,Customer_Type__c,Applicant_Type__c, Customer_Profile__c, Sector__c, Sub_Employment_Type_Non_Individual__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId and Applicant_Type__c!='Builder' ORDER BY CreatedDate];
                List<Application_Applicant__c> applicantToUpdateList = new List<Application_Applicant__c>();
                String sector;
                for(Application_Applicant__c applicant: applicants){
                    if( applicant.Applicant_Type__c == 'Primary Applicant' && applicant.Sector__c!= null){
                        sector = applicant.Sector__c;
                    }
                }
                for(Application_Applicant__c applicant: applicants){
                    if( applicant.Applicant_Type__c != 'Primary Applicant' && applicant.Customer_Profile__c == 'Non Working' && applicant.Sector__c== null){
                        Application_Applicant__c applicantToUpdate= new Application_Applicant__c();
                        applicantToUpdate.Id= applicant.Id;
                        applicantToUpdate.Sector__c = sector;
                        applicantToUpdateList.add(applicantToUpdate);
                    }
                }
                if(applicantToUpdateList.size()>0){
                    update applicantToUpdateList;
                }
            }
            List<pickListValueSet> assigneeList = new List<pickListValueSet>();
            pickListValueSet defaultPickListValue = new pickListValueSet();
            defaultPickListValue.label = 'All';
            defaultPickListValue.value = 'All';
            assigneeList.add(defaultPickListValue);
            if(!applicants.isEmpty()) {
                for (Application_Applicant__c applicant : applicants) {
                    pickListValueSet pickListValue = new pickListValueSet();
                    pickListValue.label = applicant.Applicant_Name__c;
                    pickListValue.value = applicant.Id;
                    assigneeList.add(pickListValue);
                }
            }
            System.debug('Assignee List: ' + assigneeList);
            return assigneeList;
        }
        
        public class PickListValueSet {
            @AuraEnabled public String label { get; set; }
            @AuraEnabled public String value { get; set; }
        }
        
        @AuraEnabled
        public static List<pickListValueSet> getDocumentCategoryList() {
            List<Document_Master__c> docCategoryList = new List<Document_Master__c>();
            if(Schema.sObjectType.Document_Master__c.isAccessible()){
                docCategoryList = [SELECT Id, Document_Category__c FROM Document_Master__c];
            }
            Set<String> uniqueCategories = new Set<String>();
            List<pickListValueSet> docCategories = new List<pickListValueSet>();
            pickListValueSet defaultPickListValue = new pickListValueSet();
            defaultPickListValue.label = 'All';
            defaultPickListValue.value = 'All';
            docCategories.add(defaultPickListValue);
            if (!docCategoryList.isEmpty()) {
                for (Document_Master__c docCategory : docCategoryList) {
                    if (docCategory.Document_Category__c != null && !uniqueCategories.contains(docCategory.Document_Category__c)) {
                        uniqueCategories.add(docCategory.Document_Category__c);
                        pickListValueSet pickListValue = new pickListValueSet();
                        pickListValue.label = docCategory.Document_Category__c;
                        pickListValue.value = docCategory.Document_Category__c;
                        docCategories.add(pickListValue);
                    }
                }
            }
            System.debug('Unique Doc Category List: ' + docCategories);
            return docCategories;
        }
        @AuraEnabled
        public static List<DocBundleWrapper> getAllVersionDocument(String recordId) {
            List<DocBundleWrapper> docBundleList = new List<DocBundleWrapper>();
            // Integer srno = 1;
            List<Document_Details__c> docMasterList = [SELECT Id, Name, Content_Document_Id__c, Is_Uploaded__c, Is_Required__c,Version_Number__c, 
                                                    Document_Master__r.Document_Category__c, Status__c, Remarks__c, Uploaded_Date_Time__c, 
                                                    Location__Latitude__s, Applicant__r.Applicant_Type__c, Location__Longitude__s, 
                                                    Document_Details__c, Applicant__r.Name, Requirement_Level__c, Password__c 
                                                    FROM Document_Details__c 
                                                    WHERE Document_Details_Lookup__c = :recordId];
            
            Set<Id> contDocIds = new Set<Id>();
            List<ContentDocument> contDoc = new List<ContentDocument>();
            for(Document_Details__c dd : docMasterList) {
                if (dd.Content_Document_Id__c != null){
                    contDocIds.add(dd.Content_Document_Id__c);
                }
            }
            if(Schema.sObjectType.ContentDocument.isAccessible()){
                contDoc = [SELECT Id, CreatedBy.Name, LastModifiedBy.Name, FileType, CreatedDate 
                                                    FROM ContentDocument 
                                                    WHERE Id IN :contDocIds LIMIT 1];
            }
            for (Document_Details__c dd : docMasterList) {
                DocBundleWrapper ddw = new DocBundleWrapper();
                ddw.id = dd.Id;
                ddw.name = dd.Name;
                ddw.contentId = dd.Content_Document_Id__c;
                ddw.isRequired = dd.Is_Required__c;
                ddw.showUpload = !dd.Is_Uploaded__c;
                ddw.showview = dd.Is_Uploaded__c;
                ddw.versionNumber = (Integer) dd.Version_Number__c;
                System.debug('dd.Content_Document_Id__c: '+dd.Content_Document_Id__c);
                if (dd.Content_Document_Id__c != null ) {
                    
                    if (!contDoc.isEmpty()) {
                        System.debug('contDoc: '+contDoc);
                        ContentDocument doc = contDoc[0];
                        String name = doc.LastModifiedBy.Name; // getValueOrNA(doc.CreatedBy.Name);
                        String timestamp = String.valueOf(doc.CreatedDate);
                        ddw.Timestamp = timestamp;// getValueOrNA(timestamp);
                        ddw.uploadDetails = name + ' ' + timestamp;
                        ddw.Uploadedby = name;// getValueOrNA(name);
                        ddw.fileType = doc.FileType;
                        if (doc.FileType == 'PDF') {
                            ddw.showPdf = true;
                            ddw.pdfUrl = setFileUrl(doc.Id);
                        } else {
                            ddw.imageUrl = setFileUrl(doc.Id);
                            ddw.showImage = true;
                        }
                    } else {
                        ddw.uploadDetails = 'Content Document Not Found.';
                    }
                } else {
                    ddw.uploadDetails = 'Document not yet uploaded.';
                }
                docBundleList.add(ddw);
                // srno++;
            }
            System.debug('docBundleList: '+docBundleList);
            return docBundleList;
        }
        @TestVisible
        private static String getValueOrNA(String value) {
            return String.isNotBlank(value) ? value : 'NA';
        }
        public static String setFileUrl(String contentDocId) {
            String baseUrl = System.Url.getOrgDomainUrl().toExternalForm();
            String fileUrl;
            
            if (baseUrl.contains('my.site.com')) {
                fileUrl = baseUrl + '/losportal/sfc/servlet.shepherd/document/download/' + contentDocId;
            } else {
                fileUrl = baseUrl + '/sfc/servlet.shepherd/document/download/' + contentDocId;
            }
            
            System.debug('File URL: ' + fileUrl);
            return fileUrl;
        }
        @AuraEnabled
        public static Boolean checkDocumentChecklistCreated(String docMasterId, String loanId) {
            // Query to check if a record exists
            List<Document_Details__c> ddList = [SELECT Id  FROM Document_Details__c  WHERE Document_Master__c = :docMasterId 
            AND Loan_Application__c = :loanId LIMIT 1];
            // Return true if a record is found, else false
            return !ddList.isEmpty();
        }
        @AuraEnabled
        public static List<DocBundleWrapper> createChecklist(String docMasterId, List<String> userIds, String loanId, String processName) {
            List<Document_Details__c> checkListForSanction = new List<Document_Details__c>();
            // Fetch Document Master record
            Document_Master__c docMaster;
            if (String.isNotBlank(docMasterId) && Schema.sObjectType.Document_Master__c.isAccessible()) {
                docMaster = [SELECT Id, Name, Applicable_For__c, Requirement_Level__c FROM Document_Master__c WHERE Id = :docMasterId LIMIT 1];
            } else if(Schema.sObjectType.Document_Master__c.isAccessible()) {
                String name = Constants__mdt.getInstance('Other').value__c;
                docMaster = [SELECT Id, Name, Applicable_For__c, Requirement_Level__c FROM Document_Master__c WHERE Name =: name LIMIT 1];
            }
            if (userIds != null && !userIds.isEmpty()) {
                for (String userId : userIds) {
                    checkListForSanction.add(new Document_Details__c(
                        Name = docMaster.Name,
                    Applicant__c = userId,
                    Loan_Application__c = loanId,
                    Document_Master__c = docMaster.Id,
                    Esign_Document__c = (processName == 'E-sign'),
                    //Requirement_Level__c = docMaster.Requirement_Level__c,
                    Is_Sales_Manual_Document__c = (processName == 'Sales')
                        ));
                }
            } else {
                checkListForSanction.add(new Document_Details__c(
                    Name = docMaster.Name,
                Loan_Application__c = loanId,
                Document_Master__c = docMaster.Id,
                Esign_Document__c = (processName == 'E-sign'),
                //Requirement_Level__c = docMaster.Requirement_Level__c,
                Is_Sales_Manual_Document__c = (processName == 'Sales')
                    ));
            }
            // Insert records
            if (!checkListForSanction.isEmpty() && Schema.sObjectType.Document_Details__c.isCreateable()) {
                insert checkListForSanction;
            }
            
            System.debug('checkListForSanction: ' + checkListForSanction);
            
            // Fetch inserted records
            List<Document_Details__c> docMasterList = [SELECT Id, Name, Content_Document_Id__c, Is_Uploaded__c, 
                                               Is_Required__c, Version_Number__c, Document_Master__r.Document_Category__c, 
                                               Status__c, Remarks__c, Uploaded_Date_Time__c, Location__Latitude__s, 
                                               Applicant__r.Applicant_Type__c, Location__Longitude__s, Document_Details__c, 
                                               Applicant__r.Name, Requirement_Level__c, Password__c 
                                               FROM Document_Details__c WHERE Id IN :checkListForSanction];
            
            // Prepare response: Convert fetched records into DocBundleWrapper list
            List<DocBundleWrapper> docBundleList = new List<DocBundleWrapper>();
            Integer srno = 1;
            
            // Fetch content document records
            Map<String, ContentDocument> cdRecMap = new Map<String, ContentDocument>();
            Set<String> contentDocIds = new Set<String>();
            
            for (Document_Details__c doc : docMasterList) {
                if (doc.Content_Document_Id__c != null) {
                    contentDocIds.add(doc.Content_Document_Id__c);
                }
            }
            
            if (!contentDocIds.isEmpty() && Schema.sObjectType.ContentDocument.isAccessible()) {
                for (ContentDocument contDoc : [SELECT Id, FileType, CreatedDate,CreatedBy.Name,  LastModifiedBy.Name FROM ContentDocument WHERE Id IN :contentDocIds]) {
                    cdRecMap.put(contDoc.Id, contDoc);
                }
            }
            
            for (Document_Details__c dd : docMasterList) {
                DocBundleWrapper ddw = new DocBundleWrapper();
                ddw.id = dd.Id;
                ddw.no = srno;
                ddw.name = getValueOrNA(dd.Name);
                ddw.contentId = getValueOrNA(dd.Content_Document_Id__c);
                ddw.isRequired = dd.Is_Required__c;
                ddw.showUpload = !dd.Is_Uploaded__c;
                ddw.showView = dd.Is_Uploaded__c;
                ddw.applicantType = getValueOrNA(dd.Applicant__r.Applicant_Type__c);
                ddw.showRetake = true;
                ddw.showLocation = (dd.Location__Latitude__s != null);
                ddw.lattitude = dd.Location__Latitude__s;
                ddw.longitude = dd.Location__Longitude__s;
                ddw.category = getValueOrNA(dd.Document_Details__c);
                ddw.docName = getValueOrNA(dd.Name) + ' (' + getValueOrNA(dd.Document_Master__r.Document_Category__c) + ')';
                ddw.docCategory = getValueOrNA(dd.Document_Master__r.Document_Category__c);
                ddw.custName = getValueOrNA(dd.Applicant__r.Name);
                ddw.reqLevel = getValueOrNA(dd.Requirement_Level__c);
                ddw.showDelete = !dd.Is_Uploaded__c;
                ddw.status = getValueOrNA(dd.Status__c);
                ddw.Remarks = getValueOrNA(dd.Remarks__c);
                ddw.password = getValueOrNA(dd.Password__c);
                ddw.applicantId = getValueOrNA(dd.Applicant__c);
                
                if (cdRecMap.containsKey(dd.Content_Document_Id__c)) {
                    ContentDocument contDoc = cdRecMap.get(dd.Content_Document_Id__c);
                    ddw.fileType = contDoc.FileType;
                    ddw.Timestamp = String.valueOf(contDoc.CreatedDate);
                    ddw.uploadDetails = contDoc.CreatedBy.Name + ' ' + ddw.Timestamp;
                    ddw.Uploadedby = contDoc.LastModifiedBy.Name;
                } else {
                    ddw.uploadDetails = 'Document not yet uploaded.';
                }
                
                docBundleList.add(ddw);
                srno++;
            }
            
            return docBundleList;
        }
        
        
        @AuraEnabled
        public static List<userChecklist> staticgetAllApplicants(String docMasterId, String loanId) {
            // Fetch the Document Master record
            System.debug('docMasterId: ' + docMasterId);
            System.debug('loanId '+loanId);
            // Get the applicants linked to the loan
            List<userChecklist> finalUserChecklist = new List<userChecklist>();
            List<Application_Applicant__c> applicants = new List<Application_Applicant__c>();
            if(Schema.sObjectType.Application_Applicant__c.isAccessible()){
                applicants = [SELECT Id, Name, Applicant_Type__c FROM Application_Applicant__c 
                                                        WHERE Loan_Application__c = :loanId];
            }
            if (docMasterId != null && docMasterId != '' && Schema.sObjectType.Document_Master__c.isAccessible()){
                Document_Master__c docMaster = [SELECT Id, Name, Applicable_For__c FROM Document_Master__c 
                                            WHERE Id = :docMasterId LIMIT 1];
                List<Application_Applicant__c> eligibleApplicants = new List<Application_Applicant__c>();
                // Convert the Applicable_For__c multipicklist field into a Set
                Set<String> applicableForSet = new Set<String>();
                if (docMaster.Applicable_For__c != null) {
                    applicableForSet.addAll(docMaster.Applicable_For__c.split(';'));  // Handle multipicklist properly
                    System.debug('applicableForSet '+applicableForSet);
                }
                // Identify eligible applicants based on the Applicable_For__c field
                Set<Id> eligibleApplicantIds = new Set<Id>();
                for (Application_Applicant__c applicant : applicants) {
                    if (applicant.Applicant_Type__c != null && applicableForSet.contains(applicant.Applicant_Type__c)) {
                        System.debug('eligibleApplicants '+eligibleApplicants);
                        System.debug('eligibleApplicantIds '+eligibleApplicantIds);
                        eligibleApplicants.add(applicant);
                        eligibleApplicantIds.add(applicant.Id);  // Store for checking existing docs
                    }
                }
                System.debug('Eligible Applicants Before Filtering: ' + eligibleApplicants);
                // Fetch existing document details where the applicant is already linked
                List<Document_Details__c> existingDocs = [SELECT Applicant__c FROM Document_Details__c WHERE Loan_Application__c = :loanId 
                                                        AND Document_Master__c = :docMasterId AND Active__c = true AND Applicant__c IN :eligibleApplicantIds];
                System.debug('Existing Documents: ' + existingDocs);
                // Store IDs of applicants who already have this document uploaded
                Set<Id> existingApplicantIds = new Set<Id>();
                for (Document_Details__c doc : existingDocs) {
                    existingApplicantIds.add(doc.Applicant__c);
                }
                // Convert final applicants to userChecklist format
                // List<userChecklist> finalUserChecklist = new List<userChecklist>();
                for (Application_Applicant__c applicant : eligibleApplicants) {
                    if (!existingApplicantIds.contains(applicant.Id)) {
                        userChecklist checklistItem = new userChecklist();
                        checklistItem.id = applicant.Id;
                        checklistItem.name = applicant.Name;
                        finalUserChecklist.add(checklistItem);
                    }
                }
            }
            // List<userChecklist> finalUserChecklist = new List<userChecklist>();
            // System.debug('717 '+applicants);
            // for (Application_Applicant__c applicant : applicants) {
                //         userChecklist checklistItem = new userChecklist();
                //         checklistItem.id = applicant.Id;
                //         checklistItem.name = applicant.Name;
                //         finalUserChecklist.add(checklistItem);
            // }
            System.debug('Final User Checklist: ' + finalUserChecklist);
            return finalUserChecklist;
        }
        public class UserChecklist {
            @AuraEnabled public String id;
            @AuraEnabled public String name;
        }
        
        @AuraEnabled
        public static List<Id> getfileIds(List<String> docIds) {
            List<Id> contentId = new List<Id>();
            List<Id> contentVersionIds = new List<Id>();
            // Query Document_Details__c to get Content_Document_Id__c
            List<Document_Details__c> docMasterList = [SELECT Id, Name, Content_Document_Id__c FROM Document_Details__c 
            WHERE Id IN :docIds AND Is_Uploaded__c = true];
            // Collect ContentDocument IDs
            for (Document_Details__c dd : docMasterList) {
                if (dd.Content_Document_Id__c != null) {
                    contentId.add(dd.Content_Document_Id__c);
                }
            }
            // Query ContentVersion for the latest versions
            if (!contentId.isEmpty()) {
                for (ContentVersion cv : [SELECT Id FROM ContentVersion WHERE IsLatest = true AND ContentDocumentId IN :contentId]) {
                    contentVersionIds.add(cv.Id);
                }
            }
            
            return contentVersionIds;
        }
        
        @AuraEnabled
        public static Boolean checkApplicableFor(String docMasterId){
            Boolean isApplicable = false;
            if (String.isNotBlank(docMasterId) && Schema.sObjectType.Document_Master__c.isAccessible()) {
                Document_Master__c docMaster = [SELECT Requirement_Level__c FROM Document_Master__c WHERE Id = :docMasterId LIMIT 1];
                if (docMaster.Requirement_Level__c != null && docMaster.Requirement_Level__c == 'Loan Application Level') {
                    isApplicable = false;
                }
                else if(docMaster.Requirement_Level__c == 'Applicant Level'){
                    isApplicable = true;
                }
                else{
                    isApplicable = false;
                }
            }
            return isApplicable;
        }
        @AuraEnabled
        public static Map<String, Object> parseEsignResponse(String loanId) {
            List<ApplicantWrapper> result = new List<ApplicantWrapper>();
            String jsonString;
            String finalStatus = null;
            String documentName = null;
            
            try {
                System.debug('Loan ID: ' + loanId);
                String name = 'Digio_getESignedDocument';
                Document_Details__c docDet;
                List<Integration_Details__c> iDD;
                if(Schema.sObjectType.Integration_Details__c.isAccessible() && Schema.sObjectType.Document_Details__c.isAccessible() ){
                    iDD = [SELECT Id, Name, Response_JSON__c 
                                               FROM Integration_Details__c 
                                               WHERE Loan_Application__c = :loanId AND Endpoint__c = :name 
                                               ORDER BY CreatedDate DESC
                                               LIMIT 1];
                    
                    docDet = [SELECT Id, Name 
                                         FROM Document_Details__c
                                         WHERE loan_Application__c = :loanId AND Document_Type__c =: 'Merged Document' AND Esign_Document__c=true
                                         ORDER BY CreatedDate DESC
                                         LIMIT 1];
                }
                
                if (!Idd.isEmpty()) {
                    jsonString = Idd[0].Response_JSON__c;
                    System.debug('JSON String: ' + jsonString);
                    // Parse JSON into Apex class
                    EsignResponse response = (EsignResponse) JSON.deserialize(jsonString, EsignResponse.class);
                    
                    if (response != null && response.data != null && response.data.signerDetailsList != null) {
                        finalStatus = response.data.status;
                        documentName = docDet.Name;
                        System.debug('documentName   '+documentName);
                        for (SignerDetail signer : response.data.signerDetailsList) {
                            String individualStatus = signer.signedStatus == 'requested' ? 'Pending' : signer.signedStatus;
                            ApplicantWrapper wrapper = new ApplicantWrapper(signer.signerDetails, individualStatus, signer.emailorPhonenumber, signer.sigendlink);
                            System.debug('Adding to result: ' + wrapper);
                            result.add(wrapper);
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Error parsing JSON: ' + e.getMessage());
            }
            
            System.debug('Final Status: ' + finalStatus);
            System.debug('Final Result: ' + JSON.serialize(result));
            return new Map<String, Object>{
                'finalStatus' => finalStatus,
                'documentName' => documentName,
                'applicants' => result
            };
        }
        
        public class ApplicantWrapper {
            @AuraEnabled public String applicantName;
            @AuraEnabled public String individualStatus;
            @AuraEnabled public String emailorPhonenumber;
            @AuraEnabled public String signedLink;
            
            public ApplicantWrapper(String applicantName, String individualStatus, String emailorPhonenumber, String signedLink) {
                this.applicantName = applicantName;
                this.individualStatus = individualStatus;
                this.emailorPhonenumber = emailorPhonenumber;
                this.signedLink = signedLink;
            }
        }
        
        public class SignerDetail {
            public String sigendlink;
            public String signedStatus;
            public String emailorPhonenumber;
            public String signerDetails;
        }
        
        public class EsignResponse {
            public Boolean status;
            public EsignData data;
        }
        
        public class EsignData {
            public List<SignerDetail> signerDetailsList;
            public String status;
        }
        
        @AuraEnabled
        public static List<Stamp_List__mdt> getAllStamps() {
            List<Stamp_List__mdt> stampList = new List<Stamp_List__mdt>();
            if(Schema.sObjectType.Stamp_List__mdt.isAccessible()){
                return [SELECT  MasterLabel, Stamp_Charge__c FROM Stamp_List__mdt];
            }
            return stampList;
        }
        
        @AuraEnabled
        public static List<Map<String, String>> getAuthorizedSignatories(String loanId){
            List<Map<String, String>> options = new List<Map<String, String>>();
            try {
                Opportunity op = [SELECT Branch_Master__c FROM Opportunity WHERE Id = :loanId LIMIT 1];
                if(op.Branch_Master__c != null && Schema.sObjectType.AccountTeamMember.isAccessible()){
                    List<AccountTeamMember> atmList = [
                SELECT Id, UserId, User.Name 
                FROM AccountTeamMember 
                WHERE AccountId = :op.Branch_Master__c AND Authorized_Signatory__c='Yes'
            ];
                    for(AccountTeamMember atm : atmList){
                        Map<String, String> option = new Map<String, String>{
                            'label' => atm.User.Name,
                            'value' => atm.UserId
                        };
                        options.add(option);
                    }
                }
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
            
            return options;
        }
        @AuraEnabled
        public static Boolean updateStatus(String loanId, String status) {
            Boolean flag = false;
            try {
                if(Schema.sObjectType.Opportunity.isAccessible() &&
                Schema.sObjectType.Opportunity.isUpdateable()){
                    Opportunity op = [SELECT Id, DocGen_Status__c, DocGen_Initiated_Time__c FROM Opportunity WHERE Id = :loanId LIMIT 1];
                    op.DocGen_Status__c = status;
                    if (status == 'DocGen Initiated') {
                        op.DocGen_Initiated_Time__c = System.now();
                    }
                update op;}
                flag = true;
            } catch (Exception e) {
                System.debug('Exception: ' + e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
            return flag;
        }
        
        @AuraEnabled
        public static Boolean updateStatusNonMand(String loanId, String status) {
            Boolean flag = false;
            try {
                if(Schema.sObjectType.Opportunity.isAccessible() &&
                Schema.sObjectType.Opportunity.isUpdateable()){
                    Opportunity op = [SELECT Id, Non_Mandatory_DocGen_Status__c, DocGen_Initiated_Time__c FROM Opportunity WHERE Id = :loanId LIMIT 1];
                    op.Non_Mandatory_DocGen_Status__c = status;
                    if (status == 'DocGen Initiated') {
                        op.DocGen_Initiated_Time__c = System.now();
                    }
                update op;}
                flag = true;
            } catch (Exception e) {
                System.debug('Exception: ' + e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
            return flag;
        }
        
        @AuraEnabled
        public static String returnStatus(String loanId) {
            String flag = '';
            try {
                Opportunity op = [SELECT Id, DocGen_Status__c FROM Opportunity WHERE Id = :loanId LIMIT 1];
                flag = op.DocGen_Status__c;
            } catch (Exception e) {
                System.debug('Exception: ' + e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
            return flag;
        }
        
        //
        @AuraEnabled
        public static String returnStatusNonMand(String loanId) {
            String flag = '';
            try {
                Opportunity op = [SELECT Id, Non_Mandatory_DocGen_Status__c FROM Opportunity WHERE Id = :loanId LIMIT 1];
                flag = op.Non_Mandatory_DocGen_Status__c;
            } catch (Exception e) {
                System.debug('Exception: ' + e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
            return flag;
        }
        
        @AuraEnabled
        public static String checkSignatureType(String loanId) {
            String flag = '';
            try {
                Opportunity op = [SELECT Id, Type_of_Signature__c FROM Opportunity WHERE Id = :loanId LIMIT 1];
                flag = op.Type_of_Signature__c;
            } catch (Exception e) {
                System.debug('Exception: ' + e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
            return flag;
        }
        
        @AuraEnabled
        public static String getDocumentUrl(String contentId) {
            try {
                ContentVersion contentVersion = [SELECT Id, VersionData FROM ContentVersion WHERE ContentDocumentId = :contentId LIMIT 1];
                return '/sfc/servlet.shepherd/version/download/' + contentVersion.Id;
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
        
        @AuraEnabled
        public static Boolean saveStampData(String loanId, String stampCharges, Integer totalCharges) {
            Boolean flag = false;
            try {
                if(Schema.sObjectType.Opportunity.isAccessible() &&
                Schema.sObjectType.Opportunity.isUpdateable()){
                    Opportunity op = [SELECT Id, Stamp_Paper__c, Total_Stamp_Duty__c FROM Opportunity WHERE Id = :loanId LIMIT 1];
                    op.Stamp_Paper__c = stampCharges;
                    op.Total_Stamp_Duty__c = totalCharges;
                    update op;
                }
                flag = true;
            } catch (Exception e) {
                System.debug('Exception: ' + e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
            return flag;
        }
        
        @AuraEnabled
        public static void createChecklistRecord(List<Id> docMasterIds, String recordId, String applicantId, List<Id> docIds){
            List<Document_Master__c> docMasterList = [select Id,Name,Document_Category__c, Is_Required__c, Document_Name__c, Requirement_At__c, Document_Type__c from Document_Master__c where id IN: docMasterIds];
            List<Document_Details__c> docList = new List<Document_Details__c>();
            List<Document_Details__c> docListTemp = new List<Document_Details__c>();
            Set<Id> docIdSet = new Set<Id>();
            for(Document_Details__c dd : [SELECT ID,Document_Master__r.Document_Type__c,Document_Details__c,Consider_for_Loan_Application__c FROM Document_Details__c WHERE Applicant__c =: applicantId AND Document_Master__c In: docMasterIds]){
                docIdSet.add(dd.Document_Master__c);
                if(dd.Consider_for_Loan_Application__c == false && dd.Document_Master__r.Document_Type__c == dd.Document_Details__c){
                    dd.Consider_for_Loan_Application__c = true;
                    docListTemp.add(dd);
                }
            }
            system.debug(docListTemp);
            if(docListTemp.size()>0 && Schema.sObjectType.Document_Details__c.isUpdateable()){
                update docListTemp;
            }
            if(docMasterList.size()>0){
                for(Document_Master__c doc : docMasterList){
                    Document_Details__c documentObj = new Document_Details__c();
                    documentObj.Document_Details__c = doc.Document_Type__c;
                    documentObj.Document_Required__c = doc.Is_Required__c==true?'Mandatory':'Optional';
                    //documentObj.Document_Master__r.Document_Type__c = docMasterIter.Document_Type__c;
                    documentObj.Loan_Application__c = recordId;
                    documentObj.Is_Sales_Manual_Document__c= true;
                    documentObj.Consider_for_Loan_Application__c = true;
                    if(!String.isBlank(applicantId) && doc.Requirement_At__c == 'Applicant Level'){
                        documentObj.Applicant__c = applicantId;
                    }
                    documentObj.Status__c = 'Pending';
                    documentObj.Name = doc.Document_name__c;
                    documentObj.Document_Master__c = doc.Id;
                    documentObj.Requirement_Level__c = doc.Requirement_At__c;
                    system.debug(doc.Id);
                    system.debug(docIdSet);
                    if(!docIdSet.contains(doc.Id)){
                        docList.add(documentObj);
                    }
                }
                if(docList.size()>0){
                    insert docList;
                }
            }
            if(docIds.size()>0){
                deleteDocumentCheckList(docIds,recordId, applicantId);
            }
        }
        
        public static void deleteDocumentCheckList(List<Id> docIds, String recordId, String applicantId){
            system.debug('In Delete');
            List<Document_Details__c> docList = [SELECT Id,Document_Master__r.Document_Type__c,Document_Details__c FROM Document_Details__c WHERE Applicant__c =: applicantId AND Document_Master__c IN:docIds];
            List<Document_Details__c> docListToUpdate = new List<Document_Details__c>();
            for(Document_Details__c docDel : docList){
                if(docDel.Document_Master__r.Document_Type__c == docDel.Document_Details__c){
                    Document_Details__c doc =  new Document_Details__c();
                    doc.Id = docDel.Id;
                    doc.Consider_for_Loan_Application__c = false;
                    docListToUpdate.add(doc);
                }
            }
            if(Schema.sObjectType.Document_Details__c.isUpdateable()){
                update docListToUpdate;
            }
            List<Applicant_Address__c> addList = new List<Applicant_Address__c>();
            if(Schema.sObjectType.Applicant_Address__c.isAccessible()){
            addList = [SELECT Id FROM Applicant_Address__c WHERE Document_Details__c = :docList];}
            if(addList.size()>0
                // && Schema.sObjectType.Applicant_Address__c.isDeletable()
            ){
                delete addList;
            }
        }
        
        @AuraEnabled
        public static List<Id> getChecklistMasterIds(Id loanAppId, Id applicantId) {
            Set<Id> masters = new Set<Id>();
            
            // 1) Applicant-level considered rows
            if (applicantId != null) {
                for (Document_Details__c d : [
            SELECT Document_Master__c
            FROM Document_Details__c
            WHERE Loan_Application__c                = :loanAppId
              AND Applicant__c                       = :applicantId
              AND Active__c                          = true
              AND Consider_for_Loan_Application__c   = true
        ]) {
                    if (d.Document_Master__c != null) masters.add(d.Document_Master__c);
                }
            }
            
            // 2) Loan-level considered rows (Applicant__c = null)
            for (Document_Details__c d : [
        SELECT Document_Master__c
        FROM Document_Details__c
        WHERE Loan_Application__c                = :loanAppId
          AND Applicant__c                       = null
          AND Active__c                          = true
          AND Consider_for_Loan_Application__c   = true
    ]) {
                if (d.Document_Master__c != null) masters.add(d.Document_Master__c);
            }
            
            return new List<Id>(masters);
        }
        
        public class ApplicantInfo {
            @AuraEnabled public Id    id;
            @AuraEnabled public String name;
            @AuraEnabled public String type;
            @AuraEnabled public String customerType;
            public ApplicantInfo(Id id, String name, String type,String customerType) {
                this.id   = id;
                this.name = name;
                this.type = type;
                this.customerType = customerType;
            }
        }
        
        @AuraEnabled(cacheable=true)
        public static List<ApplicantInfo> getApplicantsWithType(Id loanId) {
            if (loanId == null) {
                throw new AuraHandledException('Loan ID is required');
            }
            List<Application_Applicant__c> apps = [
      SELECT Id, Applicant_Name__c, Applicant_Type__c,Customer_Type__c
      FROM Application_Applicant__c
      WHERE Loan_Application__c = :loanId AND Applicant_Type__c!= 'Builder'
      ORDER BY CreatedDate
    ];
            List<ApplicantInfo> out = new List<ApplicantInfo>();
            for (Application_Applicant__c a : apps) {
                out.add(new ApplicantInfo(a.Id, a.Applicant_Name__c, a.Applicant_Type__c,a.Customer_Type__c));
            }
            return out;
        }
        @AuraEnabled(cacheable=true)
        public static List<DocBundleWrapper> getAllVersionDocumentHistory(Id recordId) {
            
            List<Document_Details__c> ddList = [
            SELECT Id, Name, Content_Document_Id__c, Content_Version_Id__c,
                Version_Number__c, Is_Uploaded__c
            FROM Document_Details__c
            WHERE Document_Details_Lookup__c = :recordId
            ORDER BY Version_Number__c ASC
        ];
            
            Set<Id> versionIds = new Set<Id>();
            Set<Id> docIds     = new Set<Id>();
            for (Document_Details__c dd : ddList) {
                if (dd.Is_Uploaded__c) {
                    if (!String.isBlank(dd.Content_Version_Id__c)) versionIds.add((Id)dd.Content_Version_Id__c);
                    if (dd.Content_Document_Id__c != null) docIds.add(dd.Content_Document_Id__c);
                }
            }
            
            Map<Id, ContentVersion> cvById = new Map<Id, ContentVersion>();
            if (!versionIds.isEmpty() && Schema.sObjectType.ContentVersion.isAccessible()) {
                cvById = new Map<Id, ContentVersion>([
                SELECT Id, ContentDocumentId, VersionNumber, CreatedDate, CreatedBy.Name,  LastModifiedBy.Name, FileType, Title
                FROM ContentVersion
                WHERE Id IN :versionIds
            ]);
            }
            Map<String, ContentVersion> cvByDocAndVer = new Map<String, ContentVersion>();
            if (!docIds.isEmpty() && Schema.sObjectType.ContentVersion.isAccessible()) {
                for (ContentVersion cv : [
                SELECT Id, ContentDocumentId, VersionNumber, CreatedDate, CreatedBy.Name,  LastModifiedBy.Name, FileType, Title
                FROM ContentVersion
                WHERE ContentDocumentId IN :docIds
            ]) {
                    cvByDocAndVer.put(cv.ContentDocumentId + '-' + String.valueOf(cv.VersionNumber), cv);
                }
            }
            
            List<DocBundleWrapper> outList = new List<DocBundleWrapper>();
            for (Document_Details__c dd : ddList) {
                DocBundleWrapper w = new DocBundleWrapper();
                w.id = dd.Id;
                w.name = dd.Name;
                w.contentId = dd.Content_Document_Id__c;
                w.versionNumber = (Integer)dd.Version_Number__c;
                
                ContentVersion cv;
                if (!String.isBlank(dd.Content_Version_Id__c)) {
                    cv = cvById.get((Id)dd.Content_Version_Id__c);
                } else if (dd.Content_Document_Id__c != null && dd.Version_Number__c != null) {
                    Integer ver = Integer.valueOf(dd.Version_Number__c.intValue());
                    if (ver == 0) ver = 1; // guard if you ever stored 0
                    cv = cvByDocAndVer.get(dd.Content_Document_Id__c + '-' + String.valueOf(ver));
                }
                
                if (cv != null) {
                    w.Uploadedby       = (cv.LastModifiedBy != null) ? cv.LastModifiedBy.Name : null;
                    w.Timestamp        = String.valueOf(cv.CreatedDate);
                    w.timestampEpochMs = cv.CreatedDate.getTime();
                    w.fileType         = cv.FileType;
                    w.contentVersionId = String.valueOf(cv.Id);
                    
                    String verUrl = '/sfc/servlet.shepherd/version/download/' + cv.Id;
                    if (cv.FileType == 'PDF') { w.showPdf = true;  w.pdfUrl  = verUrl; }
                    else                      { w.showImage = true; w.imageUrl = verUrl; }
                } else {
                    w.uploadDetails = 'Version not found for this row.';
                }
                outList.add(w);
            }
            return outList;
        }
        
        
        @AuraEnabled(cacheable=false)
        public static mergedDocWrapper fetchMergedAppFormDocSales(Id loanId) {
            List<Document_Details__c> docs = [
            SELECT Id, Name, Content_Document_Id__c 
            FROM Document_Details__c 
    //WHERE Loan_Application__c = :loanId
    WHERE Id = 'a0edN000008bmErQAI'
    AND Esign_Document__c = false
    AND Document_Type__c = 'Merged Document-Sales'
            ORDER BY CreatedDate DESC 
];
            
            if (docs.isEmpty()) {
                Set<Id> loanIds = new Set<Id>{loanId};
                //OpportunityTriggerImplementation.createdocusignsForCreditFromSalesLogin(loanIds);
                
                docs = [
        SELECT Id, Name, Content_Document_Id__c
        FROM Document_Details__c
        //WHERE Loan_Application__c = :loanId
        WHERE Id = 'a0edN000008bmErQAI'
        AND Esign_Document__c = false
        AND Document_Type__c = 'Merged Document-Sales'
        ORDER BY CreatedDate DESC
    ];
            }
            
            Document_Details__c mergedDocument;
            if (!docs.isEmpty()) {
                mergedDocument = docs[0];
            }
            
            if (mergedDocument == null || mergedDocument.Content_Document_Id__c == null) {
                return null;
            }
            
            // Fetch the latest ContentVersion for that ContentDocument
            ContentVersion cv = [
            SELECT Id, ContentDocumentId, VersionData, FileExtension 
            FROM ContentVersion 
            WHERE ContentDocumentId = :mergedDocument.Content_Document_Id__c 
            ORDER BY VersionNumber DESC 
            LIMIT 1
        ];
            
            if (cv == null) {
                return null;
            }
            
            mergedDocWrapper wrapper = new mergedDocWrapper();
            wrapper.contentDocumentId = cv.ContentDocumentId;
            wrapper.contentVersionId  = cv.Id;
            wrapper.fileType          = cv.FileExtension;
            wrapper.docName           = mergedDocument.Name;
            //wrapper.fileData          = EncodingUtil.base64Encode(cv.VersionData);
            return wrapper;
        }
        
        public class mergedDocWrapper {
            @AuraEnabled public Id    contentDocumentId;
            @AuraEnabled public Id    contentVersionId;
            @AuraEnabled public String fileType;
            @AuraEnabled public String docName;
            @AuraEnabled public String fileData;
        }
        
        
        
        @AuraEnabled
        public static List<Id> fetchAppFormDocDetSales (Id loanId){
            Product2 loanProduct = [SELECT Name, Id FROM Product2 WHERE Loan_Application__c =: loanId AND RecordType.DeveloperName = 'Product' LIMIT 1];
            if (loanProduct == null || loanProduct.Name == null) {
                return null;
            }
            List<Application_Applicant__c> coApplivantList=[SELECT Name, Id,Customer_Type__c,Contract_Type__c,Applicant_Type__c FROM Application_Applicant__c WHERE Loan_Application__c =:loanId AND Applicant_Type__c ='Co Applicant'];
            Integer coApps = coApplivantList.size();
            List<String> formIdentifierList = new list<String>{'APP_FORM'};
            integer countAppForm=1;
            if (coApps == 2 || coApps == 3) {
                formIdentifierList.add('APP_FORM_CO_APP_2');
                countAppForm=countAppForm+1;
            } else if (coApps >3) {
                formIdentifierList.add('APP_FORM_CO_APP_2');
                formIdentifierList.add('APP_FORM_CO_APP_4');
                countAppForm=countAppForm+2;
            }
            system.debug('formIdentifierList  '+formIdentifierList);
            system.debug('coApps  '+coApps);
            system.debug('countAppForm  '+countAppForm);
            
            List<Document_Details__c> docDetail = [
            SELECT Id 
            FROM Document_Details__c 
            WHERE Loan_Application__c =: loanId AND Esign_Document__c = true 
                AND Document_Master__r.Form_Common_Identifier__c IN:formIdentifierList 
                AND Document_Master__r.Sub_Product__r.Name =: loanProduct.Name 
        ];
            List<Id> returnIdList=new List<Id>();
            for(Document_Details__c docObj:docDetail){
                returnIdList.add(docObj.Id);
            }
            
            if(returnIdList.size() > 0 && countAppForm==returnIdList.size()){
                return returnIdList;
            }else{
                return insertDocDetail(loanId, loanProduct.Name);
            }
        }
        
        public static List<Id> insertDocDetail(Id loanId, String loanProduct){
            List<Document_Details__c> docDetailsToInsert = new List<Document_Details__c>();
            Set<Id> docMasterIds = new Set<Id>();
            Map<String, String> contentIdandMaster = new Map<String, String>();
            Map<String, String> nameandMasterId = new Map<String, String>();
            Integer docseq = 2;
            //Kalpesh start
            List<Application_Applicant__c> coApplivantList=[SELECT Name, Id,Customer_Type__c,Contract_Type__c,Applicant_Type__c FROM Application_Applicant__c WHERE Loan_Application__c =:loanId AND Applicant_Type__c ='Co Applicant'];
            Integer coApps = coApplivantList.size();
            system.debug('coApps insert '+coApps);
            List<String> formIdentifierList = new list<String>{'APP_FORM'};
            
            if (coApps == 2 || coApps == 3) {
                formIdentifierList.add('APP_FORM_CO_APP_2');
            } else if (coApps >3) {
                formIdentifierList.add('APP_FORM_CO_APP_2');
                formIdentifierList.add('APP_FORM_CO_APP_4');
            }
            
            system.debug('formIdentifierList insert '+formIdentifierList);
            //Kalpesh end
            List<Document_Master__c> docMasterList =new  List<Document_Master__c>();
            docMasterList = [SELECT Id, Name, Is_Required__c, Document_Name__c,Mandatory_Esign_Document__c, Esign_Document__c, Sub_Product__c ,Sub_Product__r.Name
            FROM Document_Master__c 
            WHERE Document_Category__c = 'Esign Template' //AND Document_Type__c = 'Form Template' 
                AND Form_Common_Identifier__c IN: formIdentifierList AND Sub_Product__r.Name =: loanProduct 
        ];
            
            system.debug('docMasterList  '+docMasterList);
            for (Document_Master__c docMaster : docMasterList) {
                docMasterIds.add(docMaster.Id);
                nameandMasterId.put(docMaster.Id, docMaster.Document_Name__c);
            }
            system.debug('nameandMasterId  '+nameandMasterId);
            if (!docMasterList.isEmpty() && !docMasterIds.isEmpty()) {
                List<ContentDocumentLink> cdl = [
                SELECT ContentDocumentId, LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :docMasterIds
            ];
                system.debug('cdl  '+cdl);
                // Populate the map with ContentDocumentId -> LinkedEntityId (Document Master ID)
                if (!cdl.isEmpty()) {
                    for (ContentDocumentLink cd : cdl) {
                        contentIdandMaster.put(cd.ContentDocumentId, cd.LinkedEntityId);
                    }
                }
                system.debug('contentIdandMaster  '+contentIdandMaster);
            }
            for (String contentDocId : contentIdandMaster.keySet()) {
                String docMasterId = contentIdandMaster.get(contentDocId);
                System.debug('docMasterId ' + docMasterId);
                String docMasterName = nameandMasterId.get(contentIdandMaster.get(contentDocId));
                System.debug('docMasterName ' + docMasterName);
                Document_Details__c newDocDetail = new Document_Details__c(
                    Name = docMasterName,
                Loan_Application__c = loanId, // Link to Loan Application
                Document_Master__c = docMasterId, // Link to Document Master
                Active__c = true, // Set to active by default
                Status__c = 'Uploaded',
                Esign_Document__c = true,
                Is_Required__c = false,
                Content_Document_Id__c = contentDocId, // Store the ContentDocumentId
                Document_Type__c = 'Template Document',
                DocGen_Sequence__c = docseq
                    );
                docseq++;
                
                docDetailsToInsert.add(newDocDetail);
            }
            insert docDetailsToInsert;
            List<Id> returnIdList=new List<Id>();
            List<Document_Details__c> docDetail = [
                SELECT Id 
                FROM Document_Details__c 
                WHERE Loan_Application__c =: loanId AND Esign_Document__c = true 
                    AND Document_Master__r.Form_Common_Identifier__c IN:formIdentifierList 
                    AND Document_Master__r.Sub_Product__r.Name =: loanProduct 
            ];
            for(Document_Details__c docObj:docDetail){
                returnIdList.add(docObj.Id);
            }
            return returnIdList;
        }
        
        @AuraEnabled
        public static PhysicalESignData createOrGetDocumentDetail(String recId, String docType) {
            String documentType = 'Updated Esign '+docType;
            
            List<Document_Details__c> existingDoc = [
            SELECT Id, Name, Description__c, Content_Document_Id__c, Is_Uploaded__c, Is_Required__c, Process_Name__c,
                Document_Master__r.Document_Category__c, Status__c, Document_Master__r.DMS_Category__c, Remarks__c,
                Uploaded_Date_Time__c, Document_URI__c, Location__Latitude__s, Esign_Document__c, DocGen_Sequence__c,
                Applicant__r.Applicant_Type__c, Location__Longitude__s, DID_Number__c, Document_Details__c,
                Applicant__c, Applicant__r.Name, Requirement_Level__c, Password__c, Mandatory_Esign_Document__c,
                Loan_Application__r.StageName
            FROM Document_Details__c
            WHERE Loan_Application__c = :recId
            AND Document_Details_Lookup__c = null
            AND Active__c = true
            AND Description__c =: documentType
            LIMIT 1
        ];
            
            System.debug('existingDoc>>>>'+existingDoc);
            System.debug('!existingDoc.isEmpty()>>>'+!existingDoc.isEmpty());
            
            if (!existingDoc.isEmpty()) {
                PhysicalESignData existingDocData = new PhysicalESignData(existingDoc[0]);
                if(existingDoc[0].Content_Document_Id__c != NULL){
                    List<ContentDocument> contentDocumentList = [Select Id, FileType, CreatedBy.Name, CreatedDate 
                                                            From ContentDocument 
                                                            Where Id = :existingDoc[0].Content_Document_Id__c];
                    existingDocData.Uploadedby = contentDocumentList[0]?.CreatedBy.Name;
                    existingDocData.fileType = contentDocumentList[0]?.FileType;
                }
                return existingDocData;
            }
            
            Document_Details__c newDoc = new Document_Details__c(
                Name = 'Physical Esign Document',
            Loan_Application__c = recId,
            Description__c = documentType,
            Active__c = true
                );
            insert newDoc;
            
            PhysicalESignData existingDocData = new PhysicalESignData(newDoc);
            return existingDocData;
            
            //return newDoc;
        }
        @AuraEnabled   //kalpesh start
        public static String uploadMandAndNonMandFile(string loanAppId,string contentDocumentId,string fileDescription){
            try{
                List<Document_Details__c> details = [
            SELECT Id, Content_Document_Id__c,Name,Merged_Document_Detail__c FROM Document_Details__c 
            WHERE Loan_Application__c = :loanAppId AND Document_Type__c = 'Merged Document' AND Description__c = :fileDescription ORDER BY CreatedDate DESC LIMIT 1];
                if (details.isEmpty()) {
                    throw new AuraHandledException('No matching Document_Details__c found.');
                }
                Document_Details__c docDetail = new Document_Details__c();
                docDetail.Name=details[0]?.Name;
                docDetail.Content_Document_Id__c = contentDocumentId;
                docDetail.Document_Type__c = 'Merged Document';
                docDetail.Description__c = fileDescription;
                docDetail.Merged_Document_Detail__c=details[0]?.Merged_Document_Detail__c;
                docDetail.Loan_Application__c =loanAppId;
                docDetail.Status__c='Uploaded';
                //added by kalpesh
                docDetail.Active__c = true;
                docDetail.Esign_Document__c = true;
                docDetail.Uploaded_Date_Time__c=system.now();
                insert docDetail;
                return 'success';
            }catch(exception e){
                System.debug('error>>>>'+e.getLineNumber());
                System.debug('error>>>>'+e);
                return 'failed';
            }
        }
        public class PhysicalESignData{
            @AuraEnabled public String  id;
            @AuraEnabled public String documentName;
            @AuraEnabled public String Uploadedby;
            @AuraEnabled public DateTime Timestamp;
            @AuraEnabled public String finalStatus;
            @AuraEnabled public String contentId;
            @AuraEnabled public Boolean showUpload;
            @AuraEnabled public Boolean showView;
            @AuraEnabled public Boolean showDelete;
            @AuraEnabled public Boolean showRetake;
            @AuraEnabled public String fileType;
            @AuraEnabled public String docName;
            public PhysicalESignData(Document_Details__c data){
                this.id= data.Id;
                this.documentName = data.Name;
                this.Uploadedby =  '';
                this.Timestamp = data.Uploaded_Date_Time__c;
                this.finalStatus = '';
                this.contentId =  data.Content_Document_Id__c;
                this.showUpload = data.Content_Document_Id__c == null;
                this.showView = data.Content_Document_Id__c != null;
                this.showDelete = false;
                this.showRetake = true;
                this.fileType = '';
                this.docName = data.Name;
            }
            public PhysicalESignData(){
                
            }
        }
        @AuraEnabled
        public static Long getFileSize(String contentDocumentId) {
            ContentVersion cv = [
            SELECT ContentSize
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
            return cv.ContentSize;
        }
        @AuraEnabled
        public static Boolean getDocumentName(Id docId){
            Boolean sendforFCU = false;
            try {
                List<Document_Details__c> docudetails = [SELECT Id,Name,Loan_Application__c FROM Document_Details__c WHERE ID = :docId AND Name LIKE '%Additional%'];
                if(!docudetails.isEmpty()){
                    sendforFCU = true;
                }
                return sendforFCU;
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }

    @AuraEnabled
    public static List<Document_Details__c> getLoanDocuments(Id loanApplicationId) {
        Sales_LoanLoginController.generateLoanApplicationForm(loanApplicationId);
        return [
            SELECT Id,
                Name,
                Content_Document_Id__c,
                Document_Type__c,
                Document_Category__c
            FROM Document_Details__c
            WHERE Id = 'a0edN000008cecXQAQ' AND Name = 'Loan Application Form'
            ORDER BY CreatedDate DESC LIMIT 1
        ];
    }
    }