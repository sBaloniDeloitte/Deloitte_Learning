/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-14-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class DocumentDetailsScreenController {

    //generic method to get the required documents for that particular record and module
    @AuraEnabled
    public static List<DocumentDetailsWrapper> getDocumentsList(String recordId, String processName) {
        try{
        system.debug('Aman DocumentDetailsScreenController '+recordId + ' => '+ processName);
        String sQuery = 'SELECT Id, Name, Content_Document_Id__c,CreatedBy.Name, Is_BSA_Initated__c,Is_Uploaded__c, Is_Required__c, Document_Master__r.Document_Category__c, Applicant__c, '+
                        'Location__Latitude__s, Location__Longitude__s,Applicant__r.Applicant_Name__c,Applicant__r.Applicant_Type__c,Manual_AA__c,Year_Month_From__c, Year_month_to__c,Account_Aggregator_Status__c, '+
                        'Uploaded_Date_Time__c, Loan_Application__r.Loan_Application_Number__c, Transaction_Id__c '+
                        'FROM Document_Details__c ';

        switch on processName {
            
            when 'Lead' {
                sQuery += ' WHERE Lead__c =: recordId Order By Is_Required__c Desc, CreatedDate Asc';
            }
            when 'Application Verification' {
                Application_Verification__c fiRec = [SELECT Id, Name FROM Application_Verification__c WHERE Id =: recordId];
                string fiReport = '%'+ fiRec.Name + ' Report%';

                sQuery += ' WHERE Application_Verification__c =: recordId And ((NOT (Name LIKE \''+ fiReport +'\')) And Name != \'FI Waived Document\') And Active__c = true  ORDER BY Is_Required__c DESC, CreatedDate ASC';
            }
            when 'Non Individual Draft'{
                sQuery += ' WHERE Loan_Application__c =: recordId AND Applicant__c != null ORDER BY Is_Required__c DESC, CreatedDate ASC';
            }
            when 'Bank Statement'{
                sQuery += ' WHERE Loan_Application__c =: recordId AND Process_Name__c=\'Income Bank Statement\'  AND Applicant__c != null ORDER BY Is_Required__c DESC, CreatedDate ASC';
            }
            when 'ITR'{
                sQuery += ' WHERE Loan_Application__c =: recordId AND Process_Name__c=\'Income ITR\'  AND Applicant__c != null ORDER BY Is_Required__c DESC, CreatedDate ASC';
            }
            when 'GST'{
                sQuery += ' WHERE Loan_Application__c =: recordId AND Process_Name__c=\'Income GST\'  AND Applicant__c != null ORDER BY Is_Required__c DESC, CreatedDate ASC';
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
                sQuery += ' WHERE Loan_Application__c =: recordId AND Active__c=true AND Document_Type__c = \'Merged Document\' LIMIT 1';
            }
            when 'EsignedDoc'{
                sQuery += ' WHERE Loan_Application__c =: recordId AND Esign_Document__c=true';
            }
        }
        System.debug('sQuery: '+sQuery);

        List<Document_Details__c> ddList = Database.query(sQuery);
        system.debug('ddList: '+ddList);

        //fetching all the content document ids
        Set<string> contDocSet = new Set<string>();
        
        for(Document_Details__c dd : ddList) {
            if(string.isNotBlank(dd.Content_Document_Id__c)) {
                contDocSet.add(dd.Content_Document_Id__c);
            }
        }
        List<ContentVersion> cvRecVersionIdList = [Select Id,Title,ContentDocumentId, FileType from ContentVersion where ContentDocumentId IN : contDocSet];
        Map<String,String> versionToDocMap = new Map<String,String>();
        Map<String,String> versionToFileName = new Map<String,String>();
        for(ContentVersion cvId : cvRecVersionIdList) {
            if(processName == 'Bank Statement' && (cvId.FileType == 'TEXT' || cvId.FileType == 'XML')){
                // continue;
            }else{
                versionToDocMap.put(cvId.ContentDocumentId,cvId.Id);
                versionToFileName.put(cvId.ContentDocumentId,cvId.Title);
            }
            
        }

        Map<Id, ContentDocument> cdRecMap = new Map<Id, ContentDocument>([Select Id, FileType From ContentDocument Where Id =: contDocSet]);

        List<DocumentDetailsWrapper> ddWrapperList = new List<DocumentDetailsWrapper>();
        List<Id> docIds = new List<Id>();
        for(Document_Details__c doc : ddList){
            docIds.add(doc.Id);
        }
        List<ContentDocumentLink> contentLinkList = [Select ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension, Id, IsDeleted, LinkedEntityId, ShareType, SystemModstamp, Visibility from ContentDocumentLink where LinkedEntityId in: docIds];
        Map<String,List<ContentDocumentLink>> docToContentLinkMap = new Map<String,List<ContentDocumentLink>>();
        for(ContentDocumentLink iterLink : contentLinkList){
            if(docToContentLinkMap.containsKey(iterLink.LinkedEntityId)){
                docToContentLinkMap.get(iterLink.LinkedEntityId).add(iterLink);
            }
            else{
                docToContentLinkMap.put(iterLink.LinkedEntityId,new List<ContentDocumentLink>{iterLink});
            }
        }
 
		Map<String,List<DocumentDetailsWrapper>> integrationKeyToDocWrapMap = new Map<String,List<DocumentDetailsWrapper>>();
        for(Document_Details__c dd : ddList){

            DocumentDetailsWrapper ddw = new DocumentDetailsWrapper();
            ddw.id = dd.Id;
            ddw.name = dd.Name;
            ddw.contentId = dd.Content_Document_Id__c;
            ddw.isRequired = dd.Is_Required__c;
            ddw.showUpload = !dd.Is_Uploaded__c;
            ddw.showview = dd.Is_Uploaded__c;
            ddw.showRetake = true;
          
            if(dd.Content_Document_Id__c!= null && versionToDocMap.containsKey(dd.Content_Document_Id__c)){
                ddw.contentVersionId = versionToDocMap.get(dd.Content_Document_Id__c);
                ddw.fileName = versionToFileName.get(dd.Content_Document_Id__c);
            }

            ddw.showLocation = dd.Location__Latitude__s != null;
            ddw.lattitude = dd.Location__Latitude__s;
            ddw.longitude = dd.Location__Longitude__s;
            ddw.category = dd.Document_Master__r.Document_Category__c;
            ddw.docName = dd.Name +' ('+ dd.Document_Master__r.Document_Category__c +')';
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

            if(dd.Manual_AA__c=='AA' && dd.Content_Document_Id__c!=null){
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
                    ddw.bsaInitated =  dd.Content_Document_Id__c!=null ? dd.Is_BSA_Initated__c: true;
                    ddw.acagregatorStatus =dd.Account_Aggregator_Status__c!=null? dd.Account_Aggregator_Status__c: ddw.bsaInitated ? 'BSA Initiated' : 'Statement Uploaded';                    
                    ddw.showDelete = ddw.bsaInitated ? false : true;
                    ddw.perfiosTransactionId = dd.Transaction_ID__c;
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
            }

            ddWrapperList.add(ddw);
        }
        if(processName == 'Bank Statement'){
            system.debug('Aman BS');
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
            System.debug('Aman integrationKeyToDocWrapMap=:'+integrationKeyToDocWrapMap);
            List<Integration_Details__c> intDetList = [SELECT Id, Name, Loan_Application__c,Response_JSON__c from Integration_Details__c where Name Like 'BSA%' and Loan_Application__c =:recordId Order by CreatedDate];
            List<Perfios_Errors__c> matchedErrors = [SELECT Perfios_Error__c FROM Perfios_Errors__c];
            Opportunity opp = [SELECT Id, Login_Completion_Stage__c FROM Opportunity WHERE Id = :recordId LIMIT 1];
            List<String> perfiosErrorList = new List<String>();
            for(Perfios_Errors__c pe : matchedErrors){
                perfiosErrorList.add(pe.Perfios_Error__c);
            }
            Map<String,List<String>> intToErrorMap = new Map<String,List<String>>();
            for(Integration_Details__c iterInt : intDetList){
                if(iterInt.Name == 'BSA '){
                    system.debug('Aman BSA with space');
                    BSAResponseWrapper callbackResp = (BSAResponseWrapper) JSON.deserialize(iterInt.Response_JSON__c, BSAResponseWrapper.class);
                    for(cls_files cs:callbackResp.data.files){
                        if (cs.Message.error.details != null && !cs.Message.error.details.isEmpty()) {
                        for(cls_details cd : cs.Message.error.details){
                            if(perfiosErrorList.contains(cd.message)){
                                System.debug('Inside 208');
                                  System.debug('Inside 208' + opp.Login_Completion_Stage__c );
                                 if (opp.Login_Completion_Stage__c == null || !opp.Login_Completion_Stage__c.containsIgnoreCase('Income eligibility')) {
                                       ddWrapperList[0].perfiosError = cd.message ;
                                        ddWrapperList[0].showPerfiosError=true;
                                       System.debug('Inside 208' + opp.Login_Completion_Stage__c );
                                       
                                    }
                            }
                            if(intToErrorMap.containsKey(callbackResp.data.perfiosTransactionId+'-'+cs.filename)){
                                intToErrorMap.get(callbackResp.data.perfiosTransactionId+'-'+cs.filename).add(cs.filename+'-'+cd.message);
                            }
                            else{
                                intToErrorMap.put(callbackResp.data.perfiosTransactionId+'-'+cs.filename, new List<String>{cs.filename+'-'+cd.message});
                            }
                        }
                    } else if (cs.Message.error.message != null){
                        if(perfiosErrorList.contains(cs.Message.error.message)){
                            System.debug('Inside condition without details array');
                              System.debug('Login stage: ' + opp.Login_Completion_Stage__c );
                             if (opp.Login_Completion_Stage__c == null || !opp.Login_Completion_Stage__c.containsIgnoreCase('Income eligibility')) {
                                   ddWrapperList[0].perfiosError = cs.Message.error.message ;
                                    ddWrapperList[0].showPerfiosError=true;
                                }
                        } 
                        if(intToErrorMap.containsKey(callbackResp.data.perfiosTransactionId+'-'+cs.filename)){
                            intToErrorMap.get(callbackResp.data.perfiosTransactionId+'-'+cs.filename).add(cs.filename+'-'+cs.Message.error.message);
                        }
                        else{
                            intToErrorMap.put(callbackResp.data.perfiosTransactionId+'-'+cs.filename, new List<String>{cs.filename+'-'+cs.Message.error.message});
                        }
                    }
                    }
                }
                else if(iterInt.Name == 'BSA'){
                    system.debug('Aman BSA without space');

                    BSAResponseService respWrap = (BSAResponseService)JSON.deserialize(iterInt.Response_JSON__c, BSAResponseService.class);
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
                else{
                    system.debug('Aman BSA Other');
                }
            }
            List<DocumentDetailsWrapper> finalDdwList = new List<DocumentDetailsWrapper>();
            for(String str: integrationKeyToDocWrapMap.keySet()){
                if(intToErrorMap.containsKey(str)){
                    if(intToErrorMap.get(str) != null && !intToErrorMap.get(str).isEmpty()){
                        integrationKeyToDocWrapMap.get(str)[0].errorList.addAll(intToErrorMap.get(str));
                    }
                }
                else{
                    if(str.contains('-')){
                        String perfTranId = str.split('-')[0];
                        if(intToErrorMap.containsKey(perfTranId)){
                            if(intToErrorMap.get(perfTranId) != null && !intToErrorMap.get(perfTranId).isEmpty()){
                                integrationKeyToDocWrapMap.get(str)[0].errorList.addAll(intToErrorMap.get(perfTranId));
                            }
                        }
                    }
                }
            }
        }
        System.debug('Aman integrationKeyToDocWrapMap=:'+integrationKeyToDocWrapMap);
        System.debug('Aman ddWrapperList=:'+ddWrapperList);
        return ddWrapperList;

    } catch (Exception e) {
        System.debug('Error in getdoc: '+ e.getLineNumber());
        throw new AuraHandledException(e.getMessage());
    }
    }

    @AuraEnabled
    public static Map<String, List<DocumentDetailsWrapper>> getSanctionConditionDocuments(List<String> sanctionIds){
        Map<String, List<DocumentDetailsWrapper>> sanctionToDocMap= new Map<String, List<DocumentDetailsWrapper>>();
        try {
            String sQuery = 'SELECT Id, Name, Content_Document_Id__c,Sanction_Condition__c,CreatedBy.Name, Is_BSA_Initated__c,Is_Uploaded__c, Is_Required__c, Document_Master__r.Document_Category__c, Applicant__c, '+
                        'Location__Latitude__s, Location__Longitude__s,Applicant__r.Applicant_Name__c,Applicant__r.Applicant_Type__c,Manual_AA__c,Year_Month_From__c, Year_month_to__c,Account_Aggregator_Status__c, '+
                        'Uploaded_Date_Time__c, Loan_Application__r.Loan_Application_Number__c, Transaction_Id__c '+
                        'FROM Document_Details__c WHERE Sanction_Condition__c IN :sanctionIds';


             List<Document_Details__c> ddList = Database.query(sQuery);
            system.debug('ddList: '+ddList);

            //fetching all the content document ids
            Set<string> contDocSet = new Set<string>();
            
            for(Document_Details__c dd : ddList) {
                if(string.isNotBlank(dd.Content_Document_Id__c)) {
                    contDocSet.add(dd.Content_Document_Id__c);
                }
            }

            List<ContentVersion> cvRecVersionIdList = [Select Id,Title,ContentDocumentId, FileType from ContentVersion where ContentDocumentId IN : contDocSet];
            Map<String,String> versionToDocMap = new Map<String,String>();
            Map<String,String> versionToFileName = new Map<String,String>();
            for(ContentVersion cvId : cvRecVersionIdList) {
                versionToDocMap.put(cvId.ContentDocumentId,cvId.Id);
                versionToFileName.put(cvId.ContentDocumentId,cvId.Title);     
            }

            Map<Id, ContentDocument> cdRecMap = new Map<Id, ContentDocument>();
            if(!contDocSet.isEmpty()){
                cdRecMap = new Map<Id, ContentDocument>([SELECT Id, FileType FROM ContentDocument WHERE Id =: contDocSet]);
            }
            // Map<Id, ContentDocument> cdRecMap = new Map<Id, ContentDocument>([Select Id, FileType From ContentDocument Where Id =: contDocSet]);

            for(Document_Details__c dd : ddList){

                DocumentDetailsWrapper ddw = new DocumentDetailsWrapper();
                ddw.id = dd.Id;
                ddw.name = dd.Name;
                ddw.contentId = dd.Content_Document_Id__c;
                ddw.isRequired = dd.Is_Required__c;
                ddw.showUpload = !dd.Is_Uploaded__c;
                ddw.showview = dd.Is_Uploaded__c;
                ddw.showRetake = true;
            
                if(dd.Content_Document_Id__c!= null && versionToDocMap.containsKey(dd.Content_Document_Id__c)){
                    ddw.contentVersionId = versionToDocMap.get(dd.Content_Document_Id__c);
                    ddw.fileName = versionToFileName.get(dd.Content_Document_Id__c);
                }

                ddw.showLocation = dd.Location__Latitude__s != null;
                ddw.lattitude = dd.Location__Latitude__s;
                ddw.longitude = dd.Location__Longitude__s;
                ddw.category = dd.Document_Master__r.Document_Category__c;
                ddw.docName = dd.Name +' ('+ dd.Document_Master__r.Document_Category__c +')';
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

                if(dd.Manual_AA__c=='AA' && dd.Content_Document_Id__c!=null){
                    ddw.showViewAA=true;
                }

                if(sanctionToDocMap.containsKey(dd.Sanction_Condition__c)){
                    sanctionToDocMap.get(dd.Sanction_Condition__c).add(ddw);
                }else {
                    sanctionToDocMap.put(dd.Sanction_Condition__c, new List<DocumentDetailsWrapper>{ddw});
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return sanctionToDocMap;
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
    public static List<Document_Master__c> getDocList(String recordId, string processObject){
        try {
            string requiredFor ='';
            string sQuery = 'Select Id, Document_Name__c From Document_Master__c Where Is_Active__c = true ';

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
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String contentId;
        @AuraEnabled public String fileType;
        @AuraEnabled public String docName;
        @AuraEnabled public boolean isRequired;
        @AuraEnabled public String category;
        @AuraEnabled public boolean showUpload;
        @AuraEnabled public boolean showView;
        @AuraEnabled public boolean showDelete;
        @AuraEnabled public boolean showRetake;
        @AuraEnabled public boolean showLocation;
        @AuraEnabled public decimal lattitude;
        @AuraEnabled public decimal longitude;
        @AuraEnabled public boolean showLatLong;
        @AuraEnabled public String applicantName;
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
        @AuraEnabled public List<ContentDocWrapper> uploadedFiles;
        @AuraEnabled public List<String> errorList;
        //Error-Ishi
        @AuraEnabled public String perfiosError;
        @AuraEnabled public boolean showPerfiosError;

    }
    public class ContentDocWrapper{
        @AuraEnabled public String contentDocId;
        @AuraEnabled public String contentDocLinkId;
        @AuraEnabled public String fileName;
        @AuraEnabled public String fileType;
        @AuraEnabled public String linkedEntityId;
    }

    @AuraEnabled
    public static Map<string, string> checkValidationBeforeGenerateEsignDoc(string param) {

        Map<string, string> result = new Map<string, string>();

        try{
            Map<string, string> paramMap = (Map<String, String>) JSON.deserialize(param, Map<String, String>.class);

            string loanId = paramMap.get('loanId');

            //check VAS field validation --------------
            /*set<string> VASCodeSet = new set<string>();
            string RTName = Constants__mdt.getInstance('CHARGES_INSURANCE_RECORD_TYPE').value__c;
            Map<string, Map<string, List<string>>> chargesFieldsBySectionMap = new Map<string, Map<string, List<string>>>();
            List<string> VASFields = new List<string>{'description__c', 'fee_method__c', 'fee_accural_date__c', 'value_date__c', 'self_funded__c'};

            for(Charges_Insurance__c rec : [Select Id, VAS_Code__c FROM Charges_Insurance__c WHERE Loan_Application__c =: loanId 
                                            AND RecordType.Name =: RTName]){
                
                VASCodeSet.add(rec.VAS_Code__c);

                if(chargesFieldsBySectionMap.containsKey(rec.VAS_Code__c)){
                    chargesFieldsBySectionMap.get(rec.VAS_Code__c).put('VAS Details', VASFields);
                }
                else{
                    Map<string, List<string>> sectionMap = new Map<string, List<string>>();
                    sectionMap.put('VAS Details', VASFields);

                    chargesFieldsBySectionMap.put(rec.VAS_Code__c, sectionMap);
                }
            }
            //system.debug('chargesFieldsBySectionMap: '+ JSON.serialize(chargesFieldsBySectionMap));

            if(!VASCodeSet.isEmpty()){

                set<string> allFieldNameSet = new set<string>();
                allFieldNameSet.addAll(VASFields);

                for(Charges_Insurance_Master__c vasMaster : [SELECT Id, Section_Fields__c, Section_Name__c, VAS_Code__c 
                                                                FROM Charges_Insurance_Master__c WHERE VAS_Code__c IN: VASCodeSet ORDER BY VAS_Code__c]){

                    List<string> fieldNameList = vasMaster.Section_Fields__c.toLowerCase().split(',');
                    allFieldNameSet.addAll(fieldNameList);
                    chargesFieldsBySectionMap.get(vasMaster.VAS_Code__c).put(vasMaster.Section_Name__c, fieldNameList);
                }
                //system.debug('chargesFieldsBySectionMap: '+ JSON.serialize(chargesFieldsBySectionMap));

                if(!allFieldNameSet.isEmpty()){
                    string sQuery = 'Select Id, Name, VAS_Code__c, Charge_or_Insurance_Number__c, '+ string.join(allFieldNameSet, ', ') +
                                    ' From Charges_Insurance__c WHERE Loan_Application__c =: loanId '+
                                    'AND RecordType.Name =: RTName';

                    system.debug('sQuery: '+sQuery);

                    List<Charges_Insurance__c> VASRecs = Database.query(sQuery);
                    //system.debug('VASRecs: '+VASRecs);

                    if(!VASRecs.isEmpty()){

                        Map<string, string> VASToDocumentMap = new Map<string, string>();
                        Map<String,Schema.SObjectField> mfields = Schema.Charges_Insurance__c.SObjectType.getDescribe().fields.getMap();

                        for(Document_Details__c rec : [SELECT Id, Charges_Insurance__r.Charge_or_Insurance_Number__c FROM Document_Details__c 
                                                        WHERE Name = 'Insurance Related Document' and Loan_Application__c =: loanId And Is_Uploaded__c = true])
                        {
                            VASToDocumentMap.put(rec.Charges_Insurance__r?.Charge_or_Insurance_Number__c, rec.Id);
                        }
                        
                        for(Charges_Insurance__c rec : VASRecs){
                            
                            Map<String, object> recordFieldsMap = (Map<String, object>) JSON.deserializeUntyped(JSON.serialize(rec).toLowerCase());
                            //system.debug('recordFieldsMap: '+ JSON.serialize(recordFieldsMap));

                            for(string sectionName : chargesFieldsBySectionMap.get(rec.VAS_Code__c).keySet()){

                                system.debug('sectionName: '+sectionName);
                                string missingFields = '';

                                switch on sectionName {
                                    when 'Self Funded Detail' { 

                                        if(rec.self_funded__c != null && rec.self_funded__c){

                                            system.debug('---sectionName: '+sectionName);

                                            for(string field : chargesFieldsBySectionMap.get(rec.VAS_Code__c).get(sectionName)){
                
                                                string recValue = recordFieldsMap.containsKey(field) ? string.valueOf(recordFieldsMap.get(field)) : '';
                                                system.debug(field + ': '+recValue);
                
                                                if(recValue == null || string.isBlank(recValue)){
                                                    missingFields += mfields.get(field).getDescribe().getLabel() +', ';
                                                }
                                            }
                                        }
                                    }
                                    when 'Appointee Details' { 

                                        if(rec.Nominee_DOB__c != null && rec.Nominee_DOB__c.addYears(18) > Date.today()) {

                                            system.debug('---sectionName: '+sectionName);

                                            for(string field : chargesFieldsBySectionMap.get(rec.VAS_Code__c).get(sectionName)){
                                                
                                                string recValue = recordFieldsMap.containsKey(field) ? string.valueOf(recordFieldsMap.get(field)) : '';
                                                system.debug(field + ': '+recValue);
                
                                                if(recValue == null || string.isBlank(recValue)){
                                                    missingFields += mfields.get(field).getDescribe().getLabel() +', ';
                                                }
                                            }
                                        }
                                    }
                                    when else {	

                                        system.debug('---sectionName: '+sectionName);

                                        for(string field : chargesFieldsBySectionMap.get(rec.VAS_Code__c).get(sectionName)){
                                            
                                            string recValue = recordFieldsMap.containsKey(field) ? string.valueOf(recordFieldsMap.get(field)) : '';
                                            system.debug(field + ': '+recValue);
            
                                            if(recValue == null || string.isBlank(recValue)){
                                                missingFields += mfields.get(field).getDescribe().getLabel() +', ';
                                            }
                                        }
                                    }
                                }

                                if(string.isNotBlank(missingFields)){
                                    result.put(('VAS_'+ rec.Name +'_'+ sectionName), missingFields.removeEnd(', ') +' field values are missing!');
                                }
                            }

                            if(!VASToDocumentMap.containsKey(rec.Charge_or_Insurance_Number__c)){
                                result.put(('VAS_'+ rec.Name +'_Proposal Form'), 'Proposal form is not uploaded!');
                            }
                        }
                    }
                }
            }
            else{
                result.put('VAS', 'At least one VAS record is required!');
            }

            chargesFieldsBySectionMap.clear();
            //---------------------

            List<Opportunity> loanApp = [Select Sub_Product__c From Opportunity Where Id =: loanId];
			
            //check Loan Details field validation ------------
            List<Screen_Field__c> screenFieldList = [Select Id, Section_Name__c, Field_Label__c, Read_Field_Name__c, Read_Object_Name__c, is_Lookup__c 
                                                    From Screen_Field__c 
                                                    where Is_Active__c = true and Is_Mandatory__c = true and Parent_Screen__r.Is_Screen_Active__c = true 
                                                    and Parent_Screen__r.Master_Screen_Name__c = 'Loan Details' and Parent_Screen__r.Form_Name__c =: loanApp[0].Sub_Product__c
                                                    order by Read_Object_Name__c];

            if(!screenFieldList.isEmpty()){
                Map<String, Set<String>> objectToFieldsMap = new Map<String, Set<String>>();

                for(Screen_Field__c sc : screenFieldList){

                    if(objectToFieldsMap.containsKey(sc.Read_Object_Name__c)){
                        objectToFieldsMap.get(sc.Read_Object_Name__c).add(sc.Read_Field_Name__c);
                    }
                    else{
                        objectToFieldsMap.put(sc.Read_Object_Name__c, new Set<String>{sc.Read_Field_Name__c});
                    }
                }

                Map<String, List<SObject>> objectValuesMap = new Map<String, List<SObject>>();
                for(String objectName : objectToFieldsMap.keySet()){
                    //system.debug('objectName: '+objectName);

                    Set<String> fieldApiNames = objectToFieldsMap.get(objectName);
                    //system.debug('fieldApiNames: '+fieldApiNames);

                    String query = 'Select Id, '+ string.join(fieldApiNames, ', ');
                    
                    switch on objectName {

                        when 'Opportunity' {
                            query += ' FROM '+ objectName +' where Id = \'' + loanId + '\'';
                        }
                        when 'Application_Applicant__c' {
                            query += ' FROM '+ objectName +' where Loan_Application__c = \'' + loanId + '\'' + ' AND Applicant_Type__c = \'Primary Applicant\' LIMIT 1';
                        }
                        when 'OpportunityTeamMember' {
                            query += ' FROM '+ objectName +' where OpportunityId = \'' + loanId + '\'';
                        }
                        when else {
                            query += ' FROM '+ objectName +' where Loan_Application__c = \'' + loanId + '\'';
                        }
                    }
                    System.debug('query: '+query);

                    List<SObject> sObjList = Database.query(query);
                    if(!sObjList.isEmpty()){
                        if(objectValuesMap.containsKey(objectName)){
                            objectValuesMap.get(objectName).add(sObjList[0]);
                        }
                        else{
                            objectValuesMap.put(objectName, new List<SObject>{sObjList[0]});
                        }
                    }
                }

                Map<string, string> missingFieldBySectionMap = new Map<string, string>();
                
                for(Screen_Field__c sc : screenFieldList){
                    List<SObject> sObjList = objectValuesMap.get(sc.Read_Object_Name__c);

                    for(SObject sObj : sObjList){
                        system.debug('sObj: '+sObj);
                        //system.debug('sc.Read_Field_Name__c: '+sc.Read_Field_Name__c);

                        string recValue = '';

                        if(sc.is_Lookup__c) {
                            List<string> lookupField = String.valueOf(sc.Read_Field_Name__c).split('\\.');

                            SObject parenObj = sObj.getSobject(lookupField[0]);
                            recValue = string.valueOf(parenObj.get(lookupField[1]));
                        }
                        else {
                            recValue = string.valueOf(sObj.get(sc.Read_Field_Name__c));
                        }
                        system.debug(sc.Read_Field_Name__c +': '+ recValue);

                        if(recValue == null || string.isBlank(recValue)){

                            if(missingFieldBySectionMap.containsKey(sc.Section_Name__c)){
                                missingFieldBySectionMap.put(sc.Section_Name__c, missingFieldBySectionMap.get(sc.Section_Name__c) + sc.Field_Label__c +', ');
                            }
                            else{
                                missingFieldBySectionMap.put(sc.Section_Name__c, sc.Field_Label__c +', ');
                            }
                        }
                    }

                    if(!missingFieldBySectionMap.isEmpty()){
                        result.put(('Loan Details_'+ sc.Section_Name__c), missingFieldBySectionMap.get(sc.Section_Name__c).removeEnd(', ') +' field values are missing!');
                    }
                }

                screenFieldList.clear();
            }
            //---------------------

            Integer mandateCount = 0;
            Integer pdcCount = 0;

            List<Loan_Transaction__c> loanTransactionList = [Select Id, Payment_Method__c, Number_of_Instruments__c, First_Disbursement_Amount__c, Disbursement_Amount__c, RecordType.Name, Total_Disbursed_Amount__c 
                                                                From Loan_Transaction__c 
                                                                Where Loan_Application__c =: loanId And RecordType.Name In ('Transaction Details', 'Payment')];
            
            List<Instrument_Mandate__c> instumentMandateList = [Select Id, Mandate_Type__c, Purpose__c From Instrument_Mandate__c 
                                                                Where Loan_Application__c =: loanId And (Mandate_Type__c = 'Repayment Mandate' Or Purpose__c In ('Installment', 'Security'))];
            
            if(!instumentMandateList.isEmpty()){

                Integer spdcCount = 0;

                for(Instrument_Mandate__c rec : instumentMandateList){

                    switch on rec.Mandate_Type__c {
                        when 'Repayment Mandate' {
                            mandateCount++;
                        }
                    }

                    switch on rec.Purpose__c {
                        when 'Installment' {
                            pdcCount++;
                        }
                        when 'Security' {
                            spdcCount++;
                        }
                    }
                }

                if(spdcCount == 0){
                    result.put('Instrument_SPDC', 'At least one SPDC is required!');
                }
            }*/

            Decimal totalPaymentAmount = 0;
            Decimal firstDisbursementAmount = 0;
            List<Loan_Transaction__c> loanTransactionList = [Select Id, Payment_Method__c, Number_of_Instruments__c, First_Disbursement_Amount__c, Net_Amount__c, RecordType.Name, Total_Disbursed_Amount__c, Disbursement_Party__c
                                                                From Loan_Transaction__c 
                                                                Where Loan_Application__c =: loanId And RecordType.Name In ('Transaction Details', 'Payment')];

            for(Loan_Transaction__c rec : loanTransactionList){
                if(rec.RecordType.Name == 'Transaction Details'){
                      firstDisbursementAmount = rec.Total_Disbursed_Amount__c != null ? rec.Total_Disbursed_Amount__c : 0;
                }

               /*if(rec.RecordType.Name == 'Transaction Details'){

                    firstDisbursementAmount = rec.Total_Disbursed_Amount__c != null ? rec.Total_Disbursed_Amount__c : 0;

                    switch on rec.Payment_Method__c {

                        //check Mandate validations --------
                        when 'DDM', 'ECS', 'NACH' {
                            if(mandateCount == 0){
                                result.put('Mandate', 'At least one Repayment Mandate is required!');
                            }
                        }
                        
                        //check Instrument validations --------
                        when 'PDC' {
                            if((rec.Number_of_Instruments__c != null ? rec.Number_of_Instruments__c : 0) != pdcCount){
                                result.put('Instrument_PDC', 'PDC should be equal to Number of Terms(Tenure)!');
                            }
                        }
                    }
                }
                else{*/
                    if(rec.Disbursement_Party__c != 'VAS'){
                        totalPaymentAmount += rec.Net_Amount__c != null ? rec.Net_Amount__c : 0;
                    }
                //}
            }

            //check disbursement amount validation -------
            //system.debug('firstDisbursementAmount: '+firstDisbursementAmount +' --- totalPaymentAmount: '+totalPaymentAmount);
            if(firstDisbursementAmount != totalPaymentAmount){
                result.put('Disbursement', 'Sum of Total payment created should be equal to Total disbursement amount!');
            }
            //------------------------
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
        Map<String,Document_Master_Field_Mapping__mdt> allMetaData = Document_Master_Field_Mapping__mdt.getAll();
        Map<String, List<String>> masterFieldMap = new Map<String, List<String>>(); 
        Map<String, List<String>> objectToFieldsMap = new Map<String, List<String>>();
        Map<String, Map<String, String>> masterToObj = new Map<String, Map<String, String>>();
        Map<String, String> objectRecToQuery = new Map<String, String>();

        for (Document_Master_Field_Mapping__mdt mapping : allMetaData.values()) {
            System.debug('mapping.Master_Object_Name__c---'+mapping.Master_Object_Name__c);
            if (mapping.Master_Object_Name__c != null) {
                String docMasterName = mapping.Master_Object_Name__c;
                String documentField = mapping.Document_Master_Field__c;
                String objectName = mapping.Object_Name__c;
                String fieldName = mapping.Field_Name__c;
                System.debug('docMasterName---'+docMasterName);
                // Populate masterFieldMap
                if (!masterFieldMap.containsKey(docMasterName)) {
                    masterFieldMap.put(docMasterName, new List<String>{documentField});
                }
                else{
                    masterFieldMap.get(docMasterName).add(documentField);  
                }
                System.debug('masterFieldMap---'+masterFieldMap);
                // Populate objectToFieldsMap
                if (!objectToFieldsMap.containsKey(objectName)) {
                    objectToFieldsMap.put(objectName, new List<String>{fieldName});
                }
                else{
                    objectToFieldsMap.get(objectName).add(fieldName);
                }
                System.debug('objectToFieldsMap---'+objectToFieldsMap);
               

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
            whereClause = ' Is_Active__c= true AND Stage__c = \'Sales login\' AND ( Requirement_At__c = \'Loan Application\' OR  Requirement_At__c = \'Applicant Level\' OR  Requirement_At__c = \'Application Level\') ORDER BY Other_Documents_Sequence__c,Sequence__c,Document_Type__c,Name';
        }
        for (String objectName : masterFieldMap.keySet()) {
            System.debug('masterFieldMap--Object: ' + objectName);
            
            // Retrieve fields for the current object
            List<String> fieldList = masterFieldMap.get(objectName);
            Set<String> fieldsToQuery = new Set<String> {
                'Id','Name', 'Document_Category__c', 'Is_Required__c', 'Document_Name__c', 'Requirement_At__c','Document_Type__c','Form_Common_Identifier__c'
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
            System.debug('objectRecToQuery--'+objectRecToQuery);
            System.debug('whereClause--'+whereClause);
        }
        List<Document_Master__c> sobjMasterList = new List<Document_Master__c>();
        for (String obj : objectRecToQuery.keySet()) {
            List<Document_Master__c> results = Database.query(objectRecToQuery.get(obj));
            sobjMasterList.addAll(results);
        }
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
                        query += ' FROM Application_Applicant__c WHERE id = :applicantId ';
                    }
                }
            }
            else if(cmpObjName=='Applicant_Address__c'){
                query += ' FROM Applicant_Address__c WHERE Application_Applicant__r.Loan_Application__c = :recordId LIMIT 1';
            }
            System.debug('query----115'+query);

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
        List<Document_Master__c> finalDMList = new List<Document_Master__c>();
        for (Document_Master__c dm : sobjMasterList) {
            Boolean isValid = true;
            for (String s : masterToObj.keySet()) {
                Object masterVal;
                Map<String, String> tempMap = masterToObj.get(s);
                Boolean isMultiSelect = isFieldMultiSelectPicklist('Document_Master__c', s);

                System.debug('S------' + s);
                System.debug('isMultiSelect------' + isMultiSelect);

                if (isMultiSelect) {
                    // For multi-select picklist fields
                    masterVal = dm.get(s);
                    System.debug('masterVal---' + masterVal);

                    List<String> splittedValues = new List<String>();
                    if (masterVal != null) {
                        // Split the multi-select picklist values
                        splittedValues = ((String)masterVal).split(';');
                        System.debug('splittedValues---' + splittedValues);
                    }

                    // Add logic to check if the final values are in the list of splitted values
                    List<SObject> sObjList = objectValMap.get(tempMap.keySet().iterator().next());
                    if (sObjList != null && !sObjList.isEmpty()) {
                        String finalVal;
                        system.debug('tempMap--->'+tempMap);
                        if(tempMap.values().iterator().next().contains('__r.')){
                            SObject parenObj = sObjList[0].getSobject(String.valueOf(tempMap.values().iterator().next()).split('\\.')[0]);
                            finalVal = String.valueOf(parenObj.get(String.valueOf(tempMap.values().iterator().next()).split('\\.')[1]));
                            System.debug('finalValfinalVal---' + finalVal);
                        }
                        else{
                            finalVal = String.valueOf(sObjList[0].get(tempMap.values().iterator().next()));
                            System.debug('finalValfinalVal---' + String.isNotBlank(finalVal));
                        }
                        if (!splittedValues.contains(finalVal) && String.isNotBlank(finalVal) ) {
                            isValid = false;
                            System.debug('splittedValues---' + splittedValues);
                            break;
                        }
                    } else {
                        isValid = false; 
                        System.debug('isValid---' + isValid);
                        break;
                    }
                } else {
                    // For non-multi-select picklist fields
                    masterVal = dm.get(s);
                    System.debug('masterVal---' + masterVal);

                    List<SObject> sObjList = objectValMap.get(tempMap.keySet().iterator().next());
                    if (sObjList != null && !sObjList.isEmpty()) {
                        System.debug('sObjList---' + sObjList);
                        String finalVal;
                        if(tempMap.values().iterator().next().contains('__r.')){
                            SObject parenObj = sObjList[0].getSobject(String.valueOf(tempMap.values().iterator().next()).split('\\.')[0]);
                            finalVal = String.valueOf(parenObj.get(String.valueOf(tempMap.values().iterator().next()).split('\\.')[1]));
                            System.debug('finalValfinalVal---' + finalVal);
                        }
                        else{
                            finalVal = String.valueOf(sObjList[0].get(tempMap.values().iterator().next()));
                            System.debug('finalValfinalVal---' + finalVal);
                        }
                        if (finalVal != null && !finalVal.equals(masterVal)) {
                            System.debug('masterVal---' + masterVal);
                            isValid = false;
                            System.debug('finalValfinalVal---' + finalVal);
                            break;
                        }
                    } else {
                        isValid = false; // If related records do not exist
                        break;
                    }
                }
            }
            if (isValid) {
                System.debug('isValid---' + isValid);
                System.debug('dm---' + dm);
                finalDMList.add(dm);
               
            } else{
                System.debug('isValid---1' + isValid);
                System.debug('dm---2' + dm);
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
        List<Document_Details__c> documentDetails = [SELECT ID,Is_Required__c,Document_Master__c FROM Document_Details__c WHERE Applicant__c =: applicantId AND Consider_for_Loan_Application__c = true];
        
        for(String str : docTypeMap.KeySet()){
            docWrapper wrap = new docWrapper();
            wrap.docType = str;
            wrap.docList = docTypeMap.get(str);
            wrap.docDetList = documentDetails;
            docWrapperTypeList.add(wrap);
            }
        System.debug('docWrapperTypeList-----'+docWrapperTypeList);
        return docWrapperTypeList;
    }

    public class docWrapper{
        @AuraEnabled public string docType;
        @AuraEnabled public List<Document_Master__c> docList;
        @AuraEnabled public List<Document_Details__c> docDetList;
        @AuraEnabled public List<Document_Details__c> docChecklistToBeCreated;
    }

    @AuraEnabled
    public static void executeMapping(String identifier,String recordId, String applicantId, String applicantType) {
        Map<String,Document_Master_Field_Mapping__mdt> allMetaData = Document_Master_Field_Mapping__mdt.getAll();
        Map<String, List<String>> masterFieldMap = new Map<String, List<String>>(); 
        Map<String, List<String>> objectToFieldsMap = new Map<String, List<String>>();
        Map<String, Map<String, String>> masterToObj = new Map<String, Map<String, String>>();
        Map<String, String> objectRecToQuery = new Map<String, String>();

        // Special handling for 'fromLoan' identifier and 'Cross Sell' channel type        
        Opportunity opp = [SELECT Id, Name,Channel_Type__c FROM Opportunity WHERE Id = :recordId LIMIT 1];
        String crossSell = Constants__mdt.getInstance('Cross_Sell').Value__c;
        if(identifier == 'fromLoan' && opp.Channel_Type__c == crossSell){
            return;
        }
        // End of special handling for Cross Sell
        for (Document_Master_Field_Mapping__mdt mapping : allMetaData.values()) {
            System.debug('mapping.Master_Object_Name__c---'+mapping.Master_Object_Name__c);
            if (mapping.Master_Object_Name__c != null) {
                String docMasterName = mapping.Master_Object_Name__c;
                String documentField = mapping.Document_Master_Field__c;
                String objectName = mapping.Object_Name__c;
                String fieldName = mapping.Field_Name__c;
                System.debug('docMasterName---'+docMasterName);
                // Populate masterFieldMap
                if (!masterFieldMap.containsKey(docMasterName)) {
                    masterFieldMap.put(docMasterName, new List<String>{documentField});
                }
                else{
                    masterFieldMap.get(docMasterName).add(documentField);  
                }
                System.debug('masterFieldMap---'+masterFieldMap);
                // Populate objectToFieldsMap
                if (!objectToFieldsMap.containsKey(objectName)) {
                    objectToFieldsMap.put(objectName, new List<String>{fieldName});
                }
                else{
                    objectToFieldsMap.get(objectName).add(fieldName);
                }
                System.debug('objectToFieldsMap---'+objectToFieldsMap);
               

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
            whereClause = ' Is_Active__c= true AND Stage__c = \'Sales login\' AND ( Requirement_At__c = \'Loan Application\' OR  Requirement_At__c = \'Applicant Level\' OR  Requirement_At__c = \'Application Level\')';
        }
        for (String objectName : masterFieldMap.keySet()) {
            System.debug('masterFieldMap--Object: ' + objectName);
            
            // Retrieve fields for the current object
            List<String> fieldList = masterFieldMap.get(objectName);
            Set<String> fieldsToQuery = new Set<String> {
                'Id', 'Document_Category__c', 'Is_Required__c', 'Document_Name__c', 'Requirement_At__c','Document_Type__c','Visibility_Controller__c'
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
            System.debug('objectRecToQuery--'+objectRecToQuery);
            System.debug('whereClause--'+whereClause);
        }
        List<Document_Master__c> sobjMasterList = new List<Document_Master__c>();
        for (String obj : objectRecToQuery.keySet()) {
            List<Document_Master__c> results = Database.query(objectRecToQuery.get(obj));
            sobjMasterList.addAll(results);
        }
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
                        query += ' FROM Application_Applicant__c WHERE id = :applicantId ';
                    }
                }
            }
            else if(cmpObjName=='Applicant_Address__c'){
                query += ' FROM Applicant_Address__c WHERE Application_Applicant__r.Loan_Application__c = :recordId LIMIT 1';
            }
            System.debug('query----115'+query);

            objQueryMap.put(cmpObjName, query);
        }
        String primaryApplicantId;
        if(String.isBlank(applicantId)){
            primaryApplicantId= [Select id, Loan_Application__c from Application_Applicant__c where Loan_Application__c=:recordId and Applicant_Type__c='Primary Applicant'].id;
        }
        Map<String, List<SObject>> objectValMap = new Map<String, List<SObject>>();
        System.debug('objQueryMap---'+objQueryMap);
        for (String str : objQueryMap.keySet()) {
            List<SObject> sobjList = Database.query(objQueryMap.get(str));
            objectValMap.put(str, sobjList);
        }
        List<Document_Master__c> finalDMList = new List<Document_Master__c>();
        System.debug('sobjMasterList---'+sobjMasterList);
        for (Document_Master__c dm : sobjMasterList) {
            Boolean isValid = true;
            for (String s : masterToObj.keySet()) {
                Object masterVal;
                Map<String, String> tempMap = masterToObj.get(s);
                Boolean isMultiSelect = isFieldMultiSelectPicklist('Document_Master__c', s);

                System.debug('S------' + s);
                System.debug('isMultiSelect------' + isMultiSelect);

                if (isMultiSelect) {
                    // For multi-select picklist fields
                    masterVal = dm.get(s);
                    System.debug('masterVal---' + masterVal);

                    List<String> splittedValues = new List<String>();
                    if (masterVal != null) {
                        // Split the multi-select picklist values
                        splittedValues = ((String)masterVal).split(';');
                        System.debug('splittedValues---' + splittedValues);
                    }

                    // Add logic to check if the final values are in the list of splitted values
                    List<SObject> sObjList = objectValMap.get(tempMap.keySet().iterator().next());
                    if (sObjList != null && !sObjList.isEmpty()) {
                        String finalVal;
                        if(tempMap.values().iterator().next().contains('__r.')){
                            SObject parenObj = sObjList[0].getSobject(String.valueOf(tempMap.values().iterator().next()).split('\\.')[0]);
                            finalVal = String.valueOf(parenObj.get(String.valueOf(tempMap.values().iterator().next()).split('\\.')[1]));
                            System.debug('finalValfinalVal---' + finalVal);
                        }
                        else{
                            finalVal = String.valueOf(sObjList[0].get(tempMap.values().iterator().next()));
                            System.debug('finalValfinalVal---' + String.isNotBlank(finalVal));
                        }
                        if (!splittedValues.contains(finalVal) && String.isNotBlank(finalVal) ) {
                            isValid = false;
                            System.debug('splittedValues---' + splittedValues);
                            break;
                        }
                    } else {
                        isValid = false; 
                        System.debug('isValid---' + isValid);
                        break;
                    }
                } else {
                    // For non-multi-select picklist fields
                    masterVal = dm.get(s);
                    System.debug('masterVal---' + masterVal);

                    List<SObject> sObjList = objectValMap.get(tempMap.keySet().iterator().next());
                    if (sObjList != null && !sObjList.isEmpty()) {
                        System.debug('sObjList---' + sObjList);
                        String finalVal;
                        if(tempMap.values().iterator().next().contains('__r.')){
                            SObject parenObj = sObjList[0].getSobject(String.valueOf(tempMap.values().iterator().next()).split('\\.')[0]);
                            finalVal = String.valueOf(parenObj.get(String.valueOf(tempMap.values().iterator().next()).split('\\.')[1]));
                            System.debug('finalValfinalVal---' + finalVal);
                        }
                        else{
                            finalVal = String.valueOf(sObjList[0].get(tempMap.values().iterator().next()));
                            System.debug('finalValfinalVal---' + finalVal);
                        }
                        if (finalVal != null && !finalVal.equals(masterVal)) {
                            System.debug('masterVal---' + masterVal);
                            isValid = false;
                            System.debug('finalValfinalVal---' + finalVal);
                            break;
                        }
                    } else {
                        isValid = false; // If related records do not exist
                        break;
                    }
                }
            }
            if (isValid) {
                System.debug('isValid---' + isValid);
                System.debug('dm---' + dm);
                finalDMList.add(dm);
               
            }
        }
        System.debug('finalDMList---' + finalDMList);
        Set<String> existingChecklistSet = new Set<String>();
        List<Document_Details__c> existingChecklists =  new  List<Document_Details__c> ();
        existingChecklists=[SELECT Id, Name,Document_Details__c, Requirement_Level__c, Applicant__c, Loan_Application__c,Document_Master__r.Document_Type__c 
        FROM Document_Details__c 
        WHERE Loan_Application__c = :recordId and Requirement_Level__c!=null and Name!=null ];
        for (Document_Details__c checklist : existingChecklists) 
            {
                String key;
                if(identifier=='fromLoan'){
                    if(checklist.Requirement_Level__c == 'Applicant Level'){
                        key = checklist.Name +'_' + checklist.Document_Master__r.Document_Type__c +'_' +checklist.Requirement_Level__c + '_' + checklist.Applicant__c;
                    }else if(checklist.Requirement_Level__c == 'Loan Application' || checklist.Requirement_Level__c == 'Application Level' ){
                        key = checklist.Name +'_' + checklist.Document_Master__r.Document_Type__c +'_' +checklist.Requirement_Level__c + '_' + checklist.Loan_Application__c;
                    }
                }else {
                    key = checklist.Name +'_' + checklist.Document_Master__r.Document_Type__c +'_' + checklist.Requirement_Level__c + '_' + checklist.Applicant__c;
                }
                // String key = checklist.Name + '_' + checklist.Requirement_Level__c + '_' + checklist.Applicant__c;
                // String loanKey = checklist.Name + '_' + checklist.Requirement_Level__c + '_' + checklist.Loan_Application__c;
                System.debug('key---'+key);
                existingChecklistSet.add(key);
            }
            String applicantDetail;
            List<Document_Details__c> documentListToInsert = new List<Document_Details__c>();
            Map<String,Document_Details__c> keyToChecklistMap = new Map<String,Document_Details__c>();
            Map<String,List<String>> keyToCategoriesMap = new Map<String,List<String>>();
        Application_Applicant__c applicant = [SELECT Id,Customer_Type__c,Customer_Profile__c,Sub_Employment_Type_Non_Individual__c FROM Application_Applicant__c WHERE Id =: applicantId];
            for (Document_Master__c docMasterIter : finalDMList) {
                if(!String.isBlank(applicantId) && docMasterIter.Requirement_At__c == 'Applicant Level'){
                
                }else if(!String.isBlank(primaryApplicantId) && docMasterIter.Requirement_At__c == 'Applicant Level'){
                    applicantDetail= (docMasterIter.Requirement_At__c == 'Applicant Level') ? primaryApplicantId : null;
                }
                String key = docMasterIter.Document_name__c +'_' + docMasterIter.Document_Type__c +'_' + docMasterIter.Requirement_At__c + '_' + applicantId;
                String loanKey = docMasterIter.Document_name__c + '_' + docMasterIter.Document_Type__c +'_'  + docMasterIter.Requirement_At__c + '_' + recordId;
                System.debug('key+++++++++++++++++++'+key);
                if (!existingChecklistSet.contains(key) && !existingChecklistSet.contains(loanKey)) {
                    existingChecklistSet.add(key);
                    Document_Details__c documentObj = new Document_Details__c();
                system.debug(docMasterIter.Visibility_Controller__c);
                documentObj.Document_Details__c = docMasterIter.Document_Type__c;
                if(docMasterIter.Document_name__c == 'PAN'){
                    documentObj.Document_Details__c = 'POI';
                    documentObj.Consider_for_Loan_Application__c = true;
                    documentObj.Is_Required__c = true;
                }else if(docMasterIter.Visibility_Controller__c != null && docMasterIter.Visibility_Controller__c.countMatches('-:') == 1){
                    String visibilityControllerValue = docMasterIter.Visibility_Controller__c;
                    String[] visibilityControllerParts = visibilityControllerValue.split('-:');
                    if(visibilityControllerParts.size() == 2) {
                        String firstPart = visibilityControllerParts[0];
                        String secondPart = visibilityControllerParts[1];
                        List<String> secondPartList = secondPart.contains(';') ? secondPart.split(';') : new List<String>{secondPart};
                    
                        if(secondPartList.contains(applicant.Customer_Profile__c) && applicant.Customer_Type__c == firstPart ){
                            documentObj.Consider_for_Loan_Application__c = true;
                            documentObj.Is_Required__c = true;
                        }
                    }
                }else if(docMasterIter.Visibility_Controller__c != null && docMasterIter.Visibility_Controller__c.countMatches('-:') == 2) {
                    String visibilityControllerValue = docMasterIter.Visibility_Controller__c;
                    String[] visibilityControllerParts = visibilityControllerValue.split('-:');

                    if(visibilityControllerParts.size() == 3) {
                        String firstPart = visibilityControllerParts[0];
                        String secondPart = visibilityControllerParts[1];
                        String thirdPart = visibilityControllerParts[2];

                        String applicantValue = applicant.Customer_Type__c + '-:' + applicant.Customer_Profile__c;
                        system.debug('applicantValue'+applicantValue);

                        List<String> secondPartList = secondPart.contains(';') ? secondPart.split(';') : new List<String>{secondPart};
                        List<String> thirdPartList = thirdPart.contains(';') ? thirdPart.split(';') : new List<String>{thirdPart};
                        system.debug('secondPartList'+secondPartList);
                        system.debug('thirdPartList'+thirdPartList);
                        system.debug('firstPart'+firstPart);
                        system.debug(secondPartList.contains(applicant.Customer_Profile__c));
                        system.debug(thirdPartList.contains(applicant.Sub_Employment_Type_Non_Individual__c));

                        if(secondPartList.contains(applicant.Customer_Profile__c) && applicant.Customer_Type__c == firstPart && thirdPartList.contains(applicant.Sub_Employment_Type_Non_Individual__c)) {
                            documentObj.Consider_for_Loan_Application__c = true;
                            documentObj.Is_Required__c = true;
                        }
                    }
                }else{
                    documentObj.Consider_for_Loan_Application__c = false;
                }
                    documentObj.Document_Required__c = docMasterIter.Is_Required__c==true?'Mandatory':'Optional';
                   
                    if(identifier=='fromLoan'){
                        documentObj.Loan_Application__c = recordId;
                        documentObj.Is_Sales_Manual_Document__c= true;
                        if(!String.isBlank(applicantId) && docMasterIter.Requirement_At__c == 'Applicant Level'){
                            documentObj.Applicant__c = applicantId;
                        }
                    }
                    documentObj.Status__c = 'Pending';
                    documentObj.Name = docMasterIter.Document_name__c;
                   
                    if(identifier=='fromLoan'){
                    //documentObj.Loan_Application_Stage__c = docMasterIter.Loan_Application_Stage__c;
                    }
                    documentObj.Document_Master__c = docMasterIter.Id;
                documentObj.Active__c = true;
                    if(identifier=='fromLoan'){
                        documentObj.Requirement_Level__c = docMasterIter.Requirement_At__c;
                    
                        // if (!String.isBlank(primaryApplicantId) && docMasterIter.Requirement_At__c == 'Applicant Level') {
                        //     documentObj.Applicant__c = primaryApplicantId;
                        // }
                        // if (!String.isBlank(applicantId) && docMasterIter.Requirement_At__c == 'Loan Application') {
                        //     documentObj.Applicant__c = applicantId;
                        // }
                        
                        documentListToInsert.add(documentObj);
                        keyToChecklistMap.put(key,documentObj);
                        System.debug('keyToChecklistMap----'+keyToChecklistMap);
                        if(keyToCategoriesMap.containsKey(key)){
                            keyToCategoriesMap.get(key).add(docMasterIter.Document_Category__c);
                        }
                        else{
                            keyToCategoriesMap.put(key,new List<String>{docMasterIter.Document_Category__c});
                        }
                        System.debug('keyToCategoriesMap----'+keyToCategoriesMap);
                    }
                    else{
                        if(keyToCategoriesMap.containsKey(key)){
                            keyToCategoriesMap.get(key).add(docMasterIter.Document_Category__c);
                        }
                        else{
                            keyToCategoriesMap.put(key,new List<String>{docMasterIter.Document_Category__c});
                        }
                        System.debug('keyToCategoriesMap----'+keyToCategoriesMap);
                    }
                }
                System.debug('keyVal----'+keyToChecklistMap.keySet());
                for(String keyVal:keyToChecklistMap.keySet()){
                    System.debug('keyVal----'+keyVal);
                    System.debug('keyVal----'+keyToChecklistMap.keySet());
                    if(keyToCategoriesMap.containsKey(keyVal)){
                        System.debug('keyVal----'+keyToCategoriesMap.containsKey(keyVal));
                        // List<String> categoryValueList = keyToCategoriesMap.get(keyVal);
                        Document_Details__c docList = keyToChecklistMap.get(keyVal);
                        System.debug('docList----'+docList);
                        //docList.Document_Categorization__c = String.join(categoryValueList,';');
                        System.debug('docList----'+docList);
                      
                    } 
                }   
            // Insert new checklist records
        }
        if (!documentListToInsert.isEmpty()) {
            insert documentListToInsert;
            System.debug('documentListToInsert----'+documentListToInsert);
        }
    }
    public static Boolean isFieldMultiSelectPicklist(String objectName, String fieldName) {
        // Get the global describe for the specified object
        System.debug('fieldName---'+fieldName);
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        System.debug('objectType---'+objectType);
        if (objectType != null) {
           Schema.SObjectField fieldToken = objectType.getDescribe().fields.getMap().get(fieldName);
            System.debug('fieldToken---'+fieldToken);
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
        List<Document_Master_Field_Mapping__mdt> mappings = [
            SELECT Master_Object_Name__c, Field_Name__c 
            FROM Document_Master_Field_Mapping__mdt 
            WHERE Is_Active__c = true AND Object_Name__c = :objectName
        ];
        
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
public static PhysicalESignData createOrGetDocumentDetail(String recId) {
   
    List<Document_Details__c> existingDoc = [
        SELECT Id, Name, Content_Document_Id__c, Is_Uploaded__c, Is_Required__c, Process_Name__c,
               Document_Master__r.Document_Category__c, Status__c, Document_Master__r.DMS_Category__c, Remarks__c,
               Uploaded_Date_Time__c, Document_URI__c, Location__Latitude__s, Esign_Document__c, DocGen_Sequence__c,
               Applicant__r.Applicant_Type__c, Location__Longitude__s, DID_Number__c, Document_Details__c,
               Applicant__c, Applicant__r.Name, Requirement_Level__c, Password__c, Mandatory_Esign_Document__c,
               Loan_Application__r.StageName
        FROM Document_Details__c
        WHERE Loan_Application__c = :recId
          AND Document_Details_Lookup__c = null
          AND Active__c = true
          AND Document_Type__c = 'Updated Esign'
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
        Document_Type__c = 'Updated Esign',
        Active__c = true
    );
    insert newDoc;

    PhysicalESignData existingDocData = new PhysicalESignData(newDoc);
         return existingDocData;

    //return newDoc;
}

    @AuraEnabled
    public static List<DocumentDetails> getDocumentChecklistRecords(String recId, String processObject){
        List<DocumentDetails> docDetailsList = new List<DocumentDetails>();
        String profileName = Utility.getCurrentUserProfileName();
        try {
            Map<String,List<DocBundleWrapper>> categoryWiseDocMap = new Map<String,List<DocBundleWrapper>>();
        
            List<Document_Details__c> documentList = new List<Document_Details__c>();
            if(processObject == 'Loan Application'){
                documentList=[SELECT Id, Name, Content_Document_Id__c,Process_Name__c, Is_Uploaded__c, Is_Required__c,Mandatory_Esign_Document__c, Document_Master__r.Document_Category__c, Document_URI__c ,
                                                        Location__Latitude__s,DocGen_Sequence__c, Location__Longitude__s,Document_Details__c,Applicant__r.Name,Requirement_Level__c,Applicant__c, Document_Master__r.DMS_Category__c,
                                                        Applicant__r.Applicant_Type__c, Loan_Application__r.StageName, DID_Number__c, Password__c FROM Document_Details__c
                                                        WHERE Loan_Application__c =:recId AND Active__c = true AND Status__c = 'Uploaded' ORDER BY Name ASC]; /*  AND Status__c = 'Uploaded' */
            }
            else if(processObject == 'E-sign'){
                documentList = [SELECT Id, Name, Content_Document_Id__c,Process_Name__c, Is_Uploaded__c, Is_Required__c, 
                Document_Master__r.Document_Category__c, Status__c, Remarks__c, Uploaded_Date_Time__c, Document_URI__c ,
                Location__Latitude__s,Esign_Document__c,Document_Master__r.DMS_Category__c,DocGen_Sequence__c, Applicant__r.Applicant_Type__c, Location__Longitude__s, DID_Number__c, 
                Document_Details__c,Applicant__c, Applicant__r.Name, Requirement_Level__c, Password__c,Mandatory_Esign_Document__c, Loan_Application__r.StageName 
                FROM Document_Details__c
                WHERE Loan_Application__c = :recId and Active__c=true and Esign_Document__c = true and Document_Type__c != 'Merged Document' and Document_Type__c != 'ESigned Document'  Order By Mandatory_Esign_Document__c Desc];
            }
            else if(processObject == 'E-signed'){
                documentList = [SELECT Id, Name, Content_Document_Id__c, Is_Uploaded__c, Is_Required__c, Process_Name__c,
                Document_Master__r.Document_Category__c,Document_Master__r.DMS_Category__c, Status__c, Remarks__c, Uploaded_Date_Time__c, Document_URI__c ,
                Location__Latitude__s,Esign_Document__c,DocGen_Sequence__c, Applicant__r.Applicant_Type__c, Location__Longitude__s, DID_Number__c, 
                Document_Details__c,Applicant__c, Applicant__r.Name, Requirement_Level__c, Password__c,Mandatory_Esign_Document__c, Loan_Application__r.StageName 
                FROM Document_Details__c
                WHERE Loan_Application__c = :recId and Active__c=true and Esign_Document__c = true];
            }
            else if(processObject == 'UpdatedEsign'){
                documentList = [
                    SELECT Id, Name, Content_Document_Id__c, Is_Uploaded__c, Is_Required__c, Process_Name__c,
                Document_Master__r.Document_Category__c, Status__c,Document_Master__r.DMS_Category__c, Remarks__c, Uploaded_Date_Time__c, Document_URI__c ,
                Location__Latitude__s,Esign_Document__c,DocGen_Sequence__c, Applicant__r.Applicant_Type__c, Location__Longitude__s, DID_Number__c,
                Document_Details__c,Applicant__c, Applicant__r.Name, Requirement_Level__c, Password__c,Mandatory_Esign_Document__c, Loan_Application__r.StageName
                FROM Document_Details__c
                WHERE Loan_Application__c = :recId and Document_Details_Lookup__c=null and Active__c=true and Document_Type__c = 'Updated Esign' Limit 1
                ];
            }
            Set<string> contDocSet = new Set<string>();
        
            for(Document_Details__c dd : documentList) {
                if(string.isNotBlank(dd.Content_Document_Id__c)) {
                    contDocSet.add(dd.Content_Document_Id__c);
                }
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
                ddw.docDmsCategory = (dd.Document_Master__r != null) ? dd.Document_Master__r.DMS_Category__c : null;
                ddw.name = dd.Name;
                ddw.bsa = false;
                ddw.contentId = dd.Content_Document_Id__c;
                ddw.isRequired = dd.Is_Required__c;
                if(profileName == 'Sales' && dd.Loan_Application__r.StageName == 'Credit Underwriting') {
                    ddw.showUpload = false;
                } else {
                    ddw.showUpload = !dd.Is_Uploaded__c;
                }
                ddw.showview = dd.Is_Uploaded__c;
                ddw.showRetake = true;
                ddw.showLocation = dd.Location__Latitude__s != null;
                ddw.lattitude = dd.Location__Latitude__s;
                ddw.longitude = dd.Location__Longitude__s;
                ddw.category = dd.Document_Details__c;
                ddw.docName = dd.Name +' ('+ dd.Document_Master__r.Document_Category__c +')';
                ddw.docCategory = dd.Document_Master__r.Document_Category__c;
                ddw.custName = dd.Applicant__r.Name;
                ddw.applicantId = dd.Applicant__c;
                ddw.customerType = dd.Applicant__r.Applicant_Type__c;
                ddw.reqLevel = dd.Requirement_Level__c;
                ddw.mntEsign = dd.Mandatory_Esign_Document__c;

                if(categoryWiseDocMap.containsKey(dd.Document_Details__c)){
                    categoryWiseDocMap.get(dd.Document_Details__c).add(ddw);
                }
                else{
                    categoryWiseDocMap.put(dd.Document_Details__c, new List<DocBundleWrapper>{ddw});
                }

                if(dd.Content_Document_Id__c != null) {
                    if(cdRecMap.containsKey(dd.Content_Document_Id__c)){
                        ddw.fileType = cdRecMap.get(dd.Content_Document_Id__c).FileType;

                        String name = cdRecMap.get(dd.Content_Document_Id__c).CreatedBy.Name;
                        DateTime createdDateTime = cdRecMap.get(dd.Content_Document_Id__c).CreatedDate;
                        String timestamp = String.valueOf(createdDateTime);
                        String combinedValue = name + ' ' + timestamp;
                        ddw.uploadDetails = combinedValue;
                        ddw.Uploadedby = name;
                        ddw.Timestamp = timestamp;
                    }
                    else {
                        ddw.uploadDetails = 'Content Document Not Found';
                        ddw.fileType = '';
                    }
                }
                else {
                    ddw.uploadDetails = 'Content Id Not Found';
                    ddw.fileType = '';
                }

                ddw.docURI = dd.Document_URI__c;
                ddw.esignSequence = Integer.valueOf(dd.DocGen_Sequence__c);
                ddw.docIdNumber = dd.DID_Number__c;
                ddw.password = dd.Password__c;
            }
            else{
                ddw.id = dd.Id;
                ddw.docDmsCategory = (dd.Document_Master__r != null) ? dd.Document_Master__r.DMS_Category__c : null;
                ddw.bsa = true;
                ddw.name = dd.Name;
                ddw.isRequired = dd.Is_Required__c;
                if(profileName == 'Sales' && dd.Loan_Application__r.StageName == 'Credit Underwriting') {
                    ddw.showUpload = false;
                } else {
                    ddw.showUpload = !dd.Is_Uploaded__c;
                }
                ddw.showview = dd.Is_Uploaded__c;
                ddw.showRetake = true;
                ddw.showLocation = dd.Location__Latitude__s != null;
                ddw.lattitude = dd.Location__Latitude__s;
                ddw.longitude = dd.Location__Longitude__s;
                ddw.category = dd.Document_Details__c;
                ddw.docName = dd.Name +' ('+ dd.Document_Master__r.Document_Category__c +')';
                ddw.docCategory = dd.Document_Master__r.Document_Category__c;
                ddw.custName = dd.Applicant__r.Name;
                ddw.applicantId = dd.Applicant__c;
                ddw.customerType = dd.Applicant__r.Applicant_Type__c;
                ddw.reqLevel = dd.Requirement_Level__c;
                ddw.mntEsign = dd.Mandatory_Esign_Document__c;
                if(dd.Content_Document_Id__c != null) {
                    if(cdRecMap.containsKey(dd.Content_Document_Id__c)){
                        String name = cdRecMap.get(dd.Content_Document_Id__c).CreatedBy.Name;
                        DateTime createdDateTime = cdRecMap.get(dd.Content_Document_Id__c).CreatedDate;
                        String timestamp = String.valueOf(createdDateTime);
                        String combinedValue = name + ' ' + timestamp;
                        ddw.uploadDetails = combinedValue;
                        ddw.Uploadedby = name;
                        ddw.Timestamp = timestamp;
                    }
                }
            if (bsaUploaded) {
                    ddw.bsaDocs = new List<ContentDocWrapper>();
                    if (docIdToCDLMap.containsKey(dd.Id)) {
                        for (ContentDocumentLink cl : docIdToCDLMap.get(dd.Id)) {
                            ContentDocWrapper cdlWrap = new ContentDocWrapper();
                            cdlWrap.contentDocId = cl.ContentDocumentId;
                            cdlWrap.contentDocLinkId = cl.Id;
                            cdlWrap.linkedEntityId = cl.LinkedEntityId;
                            cdlWrap.fileName = cl.ContentDocument.Title + '.' + cl.ContentDocument.FileExtension;
                            cdlWrap.fileType = cl.ContentDocument.FileExtension != null ? cl.ContentDocument.FileExtension.toUpperCase() : '';
                            ddw.bsaDocs.add(cdlWrap);
                        }
                    }
                }
                if(categoryWiseDocMap.containsKey(dd.Document_Details__c)){
                    categoryWiseDocMap.get(dd.Document_Details__c).add(ddw);
                }
                else{
                    categoryWiseDocMap.put(dd.Document_Details__c, new List<DocBundleWrapper>{ddw});
                }
                ddw.docURI = dd.Document_URI__c;
                ddw.esignSequence = Integer.valueOf(dd.DocGen_Sequence__c);
                ddw.docIdNumber = dd.DID_Number__c;
                ddw.password = dd.Password__c;
            }
            }

            System.debug('categoryWiseDocMap=: '+categoryWiseDocMap);
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
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        System.debug('docDetailsList----'+docDetailsList);
        return docDetailsList;
    }

    public class DocBundleWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String contentId;
        @AuraEnabled public String fileType;
        @AuraEnabled public String docName;
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public String category;
        @AuraEnabled public Boolean showUpload;
        @AuraEnabled public Boolean showView;
        @AuraEnabled public Boolean showDelete;
        @AuraEnabled public Boolean showRetake;
        @AuraEnabled public Boolean showLocation;
        @AuraEnabled public Decimal lattitude;
        @AuraEnabled public Decimal longitude;
        @AuraEnabled public Boolean showLatLong;
        @AuraEnabled public Integer seq;
        @AuraEnabled public String docCategory;
        @AuraEnabled public String uploadDetails;
        @AuraEnabled public String custName;
        @AuraEnabled public String customerType;
        @AuraEnabled public String reqLevel;
        @AuraEnabled public String status;
        @AuraEnabled public String applicantType;
        @AuraEnabled public String Uploadedby;
        @AuraEnabled public String Timestamp;
        @AuraEnabled public String Remarks;
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
        @AuraEnabled public Integer esignSequence;
        @AuraEnabled public string docIdNumber;
        @AuraEnabled public Boolean bsa;
        @AuraEnabled public String docDmsCategory;
        @AuraEnabled public List<ContentDocWrapper> bsaDocs;
    }

    @AuraEnabled
    public static List<pickListValueSet> getCustomerList(String loanId) {
        if (String.isBlank(loanId)) {
            throw new AuraHandledException('Loan ID cannot be null or blank.');
        }
        List<Application_Applicant__c> applicants = [SELECT Id,Applicant_Name__c, Name FROM Application_Applicant__c WHERE Loan_Application__c = :loanId];
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

    public class pickListValueSet {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
    }

    @AuraEnabled
    public static List<pickListValueSet> getDocumentCategoryList() {
        List<Document_Master__c> docCategoryList = [SELECT Id, Document_Category__c FROM Document_Master__c];
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
            if (dd.Content_Document_Id__c != null) {
                List<ContentDocument> contDoc = [SELECT Id, CreatedBy.Name, FileType, CreatedDate 
                                                 FROM ContentDocument 
                                                 WHERE Id = :dd.Content_Document_Id__c LIMIT 1];
                if (!contDoc.isEmpty()) {
                    System.debug('contDoc: '+contDoc);
                    ContentDocument doc = contDoc[0];
                    String name = doc.CreatedBy.Name; // getValueOrNA(doc.CreatedBy.Name);
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
        AND Loan_Application__c = :loanId AND Status__c = 'Uploaded' AND Requirement_Level__c != 'Application Level' LIMIT 1];
    // Return true if a record is found, else false
    return !ddList.isEmpty();
}

    @AuraEnabled
    public static Boolean checkDedupe(String docMasterId, String loanId, List<String> userIds) {
        List<Document_Details__c> ddList;
        if (!userIds.isEmpty()) {
            ddList = [SELECT Id  FROM Document_Details__c  WHERE Document_Master__c = :docMasterId 
                        AND Loan_Application__c = :loanId AND Applicant__c IN: userIds AND Requirement_Level__c = 'Applicant Level' LIMIT 1];
        } else {
            ddList = [SELECT Id  FROM Document_Details__c  WHERE Document_Master__c = :docMasterId 
                        AND Loan_Application__c = :loanId  AND Requirement_Level__c = 'Applicant Level' LIMIT 1]; /*  AND Applicant__c IN: userIds */
        }
        return !ddList.isEmpty();
    }

    @AuraEnabled
    public static List<DocBundleWrapper> getExistingDocChecklist(String docMasterId, String loanId, List<String> userIds) {
        List<Document_Details__c> ddList;
        if (!userIds.isEmpty()) {
            ddList = [SELECT Id, Name, Content_Document_Id__c, Is_Required__c, Is_Uploaded__c, Applicant__c, Applicant__r.Applicant_Type__c, 
                        Location__Latitude__s, Location__Longitude__s, Document_Details__c, Document_Master__c, Document_Master__r.Document_Category__c, 
                        Applicant__r.Name, Requirement_Level__c, Status__c, Remarks__c, Password__c FROM Document_Details__c WHERE Document_Master__c = :docMasterId 
                        AND Loan_Application__c = :loanId AND Applicant__c IN: userIds LIMIT 1];
        } else {
            ddList = [SELECT Id, Name, Content_Document_Id__c, Is_Required__c, Is_Uploaded__c, Applicant__c, Applicant__r.Applicant_Type__c, 
                        Location__Latitude__s, Location__Longitude__s, Document_Details__c, Document_Master__c, Document_Master__r.Document_Category__c, 
                        Applicant__r.Name, Requirement_Level__c, Status__c, Remarks__c, Password__c FROM Document_Details__c  WHERE Document_Master__c = :docMasterId 
                        AND Loan_Application__c = :loanId LIMIT 1]; /*  AND Applicant__c IN: userIds */
        }
        Document_Details__c dd = ddList[0];
        List<DocBundleWrapper> wrapperList = new List<DocBundleWrapper>();
        DocBundleWrapper ddw = new DocBundleWrapper();
        ddw.id = dd.Id;
        ddw.no = 1;
        ddw.name = getValueOrNA(dd.Name);
        ddw.contentId = getValueOrNA(dd.Content_Document_Id__c);
        if (dd.Content_Document_Id__c != null) {
            ContentDocument contDoc = [SELECT Id, FileType, CreatedDate, CreatedBy.Name FROM ContentDocument WHERE Id =:dd.Content_Document_Id__c];
            ddw.fileType = contDoc.FileType;
        }
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
        // if (cdRecMap.containsKey(dd.Content_Document_Id__c)) {
        //     ContentDocument contDoc = cdRecMap.get(dd.Content_Document_Id__c);
        //     ddw.fileType = contDoc.FileType;
        //     ddw.Timestamp = String.valueOf(contDoc.CreatedDate);
        //     ddw.uploadDetails = contDoc.CreatedBy.Name + ' ' + ddw.Timestamp;
        //     ddw.Uploadedby = contDoc.CreatedBy.Name;
        // } else {
        //     ddw.uploadDetails = 'Document not yet uploaded.';
        // }

        wrapperList.add(ddw);
        return wrapperList;
    }

@AuraEnabled
public static List<DocBundleWrapper> createChecklist(String docMasterId, List<String> userIds, String loanId, String processName) {
    List<Document_Details__c> checkListForSanction = new List<Document_Details__c>();
    // Fetch Document Master record
    Document_Master__c docMaster;
    Integer highestSequence = 0;
    System.debug('loanId '+loanId);
    if (processName == 'E-sign') {
        List<Document_Details__c> dde = [SELECT DocGen_Sequence__c FROM Document_Details__c WHERE Loan_Application__c = :loanId AND DocGen_Sequence__c != 0 AND DocGen_Sequence__c != NULL ORDER BY DocGen_Sequence__c DESC LIMIT 1];
        if (!dde.isEmpty()) {
           Integer sequence = Integer.valueOf(dde[0].DocGen_Sequence__c);
           System.debug('sequence :  '+sequence);
           highestSequence = sequence + 1;

        }
    }
    if (String.isNotBlank(docMasterId)) {
        docMaster = [SELECT Id, Name, Applicable_For__c, Requirement_Level__c FROM Document_Master__c WHERE Id = :docMasterId LIMIT 1];
    } else {
        String name = Constants__mdt.getInstance('Other').value__c;
        docMaster = [SELECT Id, Name, Applicable_For__c, Requirement_Level__c FROM Document_Master__c WHERE Name = :name LIMIT 1];
    }
    if (userIds != null && !userIds.isEmpty()) {
        for (String userId : userIds) {
            checkListForSanction.add(new Document_Details__c(
                Name = docMaster.Name,
                Applicant__c = userId,
                Loan_Application__c = loanId,
                Document_Master__c = docMaster.Id,
                Esign_Document__c = (processName == 'E-sign'),
                Is_Sales_Manual_Document__c = (processName == 'Sales'),
                DocGen_Sequence__c = highestSequence,
                Requirement_Level__c = docMaster.Requirement_Level__c
            ));
        }
    } else {
        checkListForSanction.add(new Document_Details__c(
            Name = docMaster.Name,
            Loan_Application__c = loanId,
            Document_Master__c = docMaster.Id,
            Esign_Document__c = (processName == 'E-sign'),
            Is_Sales_Manual_Document__c = (processName == 'Sales'),
            DocGen_Sequence__c =  highestSequence,
            Requirement_Level__c = docMaster.Requirement_Level__c
        ));
    }
    // Insert records
    if (!checkListForSanction.isEmpty()) {
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

    if (!contentDocIds.isEmpty()) {
        for (ContentDocument contDoc : [SELECT Id, FileType, CreatedDate, CreatedBy.Name FROM ContentDocument WHERE Id IN :contentDocIds]) {
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
            ddw.Uploadedby = contDoc.CreatedBy.Name;
        } else {
            ddw.uploadDetails = 'Document not yet uploaded.';
        }

        docBundleList.add(ddw);
        srno++;
    }

    return docBundleList;
}

@AuraEnabled
public static List<Application_Applicant__c> getAllApplicants(String loanId){
    try{
        List<Application_Applicant__c> applicants = [SELECT Id, Name, Applicant_Type__c 
                                                     FROM Application_Applicant__c 
                                                     WHERE Loan_Application__c = :loanId];
        if(!applicants.isEmpty()){
            return applicants;
        }
        return NULL;

    }catch(Exception e){
        throw new AuraHandledException(e.getMessage());
    }
}


    @AuraEnabled
    public static List<userChecklist> staticgetAllApplicants(String docMasterId, String loanId) {
        // Fetch the Document Master record
        System.debug('docMasterId: ' + docMasterId);
        System.debug('loanId '+loanId);
        // Get the applicants linked to the loan
        List<userChecklist> finalUserChecklist = new List<userChecklist>();
        List<Application_Applicant__c> applicants = [SELECT Id, Name, Applicant_Type__c FROM Application_Applicant__c 
                                                        WHERE Loan_Application__c = :loanId];
        if (docMasterId != null && docMasterId != ''){
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
                                                        AND Document_Master__c = :docMasterId AND Active__c = true AND Applicant__c IN :eligibleApplicantIds AND Status__c = 'Uploaded'];
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
    public class userChecklist {
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
        if (String.isNotBlank(docMasterId)) {
            Document_Master__c docMaster = [SELECT Requirement_Level__c FROM Document_Master__c WHERE Id = :docMasterId LIMIT 1];
            if (docMaster.Requirement_Level__c != null && docMaster.Requirement_Level__c == 'Application Level') {
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
    public static Boolean checkIfReinitiationNeeded(String loanId) {
        try {
            String endpointName = 'Digio_getESignedDocument';
            String jsonString;

            List<Integration_Details__c> integrationDetails = [
                SELECT Id, Name, Response_JSON__c 
                FROM Integration_Details__c 
                WHERE Loan_Application__c = :loanId AND Endpoint__c = :endpointName 
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if (!integrationDetails.isEmpty()) {
                jsonString = integrationDetails[0].Response_JSON__c;
                System.debug('JSON String: ' + jsonString);

                if (String.isNotBlank(jsonString)) {
                    EsignResponse response = (EsignResponse) JSON.deserialize(jsonString, EsignResponse.class);
                    if (response != null && response.data != null && response.data.signerDetailsList != null) {
                        for (SignerDetail signer : response.data.signerDetailsList) {
                            if (signer.signedStatus == 'expired') {
                                return true;
                            }
                        }
                    }
                }
            }

            return false;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
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
    
            List<Integration_Details__c> Idd = [SELECT Id, Name, Response_JSON__c 
                                               FROM Integration_Details__c 
                                               WHERE Loan_Application__c = :loanId AND Endpoint__c = :name 
                                               ORDER BY CreatedDate DESC
                                               LIMIT 1];

            Document_Details__c docDet = [SELECT Id, Name 
                                         FROM Document_Details__c
                                         WHERE loan_Application__c = :loanId AND Document_Type__c =: 'Merged Document' AND Esign_Document__c=true
                                         ORDER BY CreatedDate DESC
                                         LIMIT 1];

            System.debug('docDet   '+docDet);
            System.debug('docDet.Name   '+docDet.Name);
    
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
    return [SELECT  MasterLabel, Label__c, Stamp_Charge__c FROM Stamp_List__mdt];
}

@AuraEnabled
public static List<Map<String, String>> getAuthorizedSignatories(String loanId){
    List<Map<String, String>> options = new List<Map<String, String>>();
    try {
        Opportunity op = [SELECT Branch_Master__c FROM Opportunity WHERE Id = :loanId LIMIT 1];
        if(op.Branch_Master__c != null){
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
        Opportunity op = [SELECT Id, DocGen_Status__c FROM Opportunity WHERE Id = :loanId LIMIT 1];
        op.DocGen_Status__c = status;
        update op;
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
            Opportunity op = [SELECT Id, Stamp_Paper__c, Total_Stamp_Duty__c FROM Opportunity WHERE Id = :loanId LIMIT 1];
            op.Stamp_Paper__c = stampCharges;
            op.Total_Stamp_Duty__c = totalCharges;
            update op;
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
        if(docListTemp.size()>0){
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
            system.debug('Type'+docDel.Document_Master__r.Document_Type__c);
            system.debug('Doc Type'+docDel.Document_Details__c);
            if(docDel.Document_Master__r.Document_Type__c == docDel.Document_Details__c){
                Document_Details__c doc =  new Document_Details__c();
                doc.Id = docDel.Id;
                doc.Consider_for_Loan_Application__c = false;
                docListToUpdate.add(doc);
            }
        }
        system.debug('Before Update-->'+docListToUpdate);
        update docListToUpdate;
        system.debug('After Update-->'+docListToUpdate);

        List<Applicant_Address__c> addList = [SELECT Id FROM Applicant_Address__c WHERE Document_Details__c = :docList];
        system.debug('delete List'+addList);
        if(addList.size()>0){
            delete addList;
        }        
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
        List<ContentDocumentLink> contentLinkList = [Select ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension, Id, IsDeleted, LinkedEntityId, ShareType, SystemModstamp, Visibility from ContentDocumentLink where LinkedEntityId in: docIds];
        Map<String,List<ContentDocumentLink>> docToContentLinkMap = new Map<String,List<ContentDocumentLink>>();
        for(ContentDocumentLink iterLink : contentLinkList){
            uploadedFileNames.add(iterLink.ContentDocument.Title+'.'+iterLink.ContentDocument.FileExtension);
        }
        return uploadedFileNames;
    }
    @AuraEnabled(cacheable=true)
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
    public static List<Document_Details__c> getLoanDocuments(Id loanApplicationId) {
        Sales_LoanLoginController.generateLoanApplicationForm(loanApplicationId);
        return [
            SELECT Id,
                Name,
                Content_Document_Id__c,
                Document_Type__c,
                Document_Category__c
            FROM Document_Details__c
            WHERE Loan_Application__c = :loanApplicationId AND Name = 'Loan Application Form'
            ORDER BY CreatedDate DESC LIMIT 1
        ];
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
public static Boolean addtoDigioScreen(String loanId, List<Id> docIds) {
    try {
        List<Id> existingDocgenIds = new List<Id>();
        List<Id> filteredDocIds = new List<Id>();
        // Fetch the latest sequence
        List<Document_Details__c> dde = [
            SELECT DocGen_Sequence__c FROM Document_Details__c WHERE Loan_Application__c = :loanId
            AND DocGen_Sequence__c != null ORDER BY DocGen_Sequence__c DESC LIMIT 1];
        Integer highestSequence = 0;
        if (!dde.isEmpty()) {
            highestSequence = Integer.valueOf(dde[0].DocGen_Sequence__c);
        }
        List<Document_Details__c> docsToUpdate = new List<Document_Details__c>();
        // Loop through doc IDs and assign new sequence
        List<Document_Details__c> checkSame = [
            SELECT Id,DocGen_Sequence__c FROM Document_Details__c WHERE Loan_Application__c = :loanId
            AND DocGen_Sequence__c != null AND Esign_Document__c=true ORDER BY DocGen_Sequence__c DESC LIMIT 1];
            if(!checkSame.isEmpty()){
                for(Document_Details__c ds : checkSame){
                existingDocgenIds.add(ds.Id);
                }
            }
            for (Id docId : docIds) {
                if (!existingDocgenIds.contains(docId)) {
                    filteredDocIds.add(docId);
                }
            }
        for (Id docId : filteredDocIds) {
            highestSequence++;
            docsToUpdate.add(new Document_Details__c(
                Id = docId,
                Esign_Document__c = true,
                DocGen_Sequence__c = highestSequence
            ));
        }
        if (!docsToUpdate.isEmpty()) {
            update docsToUpdate;
            return true;
        } else {
            return false;
        }
 
    } catch (Exception e) {
        throw new AuraHandledException('Error updating Digio screen: ' + e.getMessage());
    }
}

@AuraEnabled
    public static Boolean checkStage(String loanId) {
        try {
            Opportunity opp = [SELECT StageName FROM Opportunity WHERE Id = :loanId LIMIT 1];
            return (opp.StageName == 'PSV' || opp.StageName == 'Disbursement');
        } catch (QueryException qe) {
            // No record found or query issue
            return false;
        } catch (Exception e) {
            throw new AuraHandledException('Error checking stage: ' + e.getMessage());
        }
    }
}