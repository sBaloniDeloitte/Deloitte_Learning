/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-29-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class SalesDocumentCmpController {
    @AuraEnabled
        public static String getContentDocumentId(String contentVersionId) {
        ContentVersion cv = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE (Id =: contentVersionId OR ContentDocumentId =: contentVersionId)
            LIMIT 1
        ];
        return cv.contentDocumentId;
    } 
 
  
    @AuraEnabled
    public static List<MainDocumentWrapper> getAllDocumentSales(Id recordId , String catg ,String appId ,Boolean loan){
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        List<Document_Details__c> documentLst = new List<Document_Details__c>();
        Map<String,Boolean> resultMap = new Map<String,Boolean>();
        Set<String> docMasterName = new Set<String>();
        System.debug('recordId : '+recordId);
        System.debug('catg : '+catg);
        System.debug('appId : '+appId);
        System.debug('sObjName : '+sObjName);
        System.debug('loan : '+loan);
        Id recId;
        if(sObjName == 'Opportunity' && recordId != null) {
            recId = recordId;   
            System.debug('recId '+recId);
        }
        List<MainDocumentWrapper> documentList = new List<MainDocumentWrapper>();
        if(loan!=null && loan == true){
                if(catg == 'Sales'){
                    documentLst = [SELECT id,Name,Applicant__c,Applicant__r.Customer_Profile__c,Bank_Details__c,Is_Uploaded__c,DDE_Status__c,Document_Master__r.Document_Name__c,Document_Master__r.Document_Type__c,Document_Master__r.Sequence__c,Aadhar_Masked_Source__c,Applicant__r.Applicant_Name__c,Is_manual_masking_confirmed__c,Content_Document_Id__c,Document_Master__c,Document_Master__r.Applicable_For_Ocr__c,
                    Verification_Status__c,Remarks__c,Screening_Status__c ,Owner.Name,Document_Master__r.Document_Category__c,Requirement_Level__c,FCU_Initiated__c FROM Document_Details__c WHERE Loan_Application__c =:recId AND
                    Applicant__c = NULL AND Active__c=true AND  (Is_Sales_Manual_Document__c=true OR Source__c = 'CKYC' )AND Consider_for_Loan_Application__c = true ORDER by Document_Master__r.Sequence__c ASC,Document_Master__r.Document_Name__c ASC];
                }else{
                    documentLst = [SELECT id,Name,Applicant__c,Applicant__r.Customer_Profile__c,Bank_Details__c,Is_Uploaded__c,DDE_Status__c,Document_Master__r.Document_Name__c,Document_Master__r.Document_Type__c,Document_Master__r.Sequence__c,Aadhar_Masked_Source__c,Applicant__r.Applicant_Name__c,Is_manual_masking_confirmed__c,Content_Document_Id__c,Document_Master__c,Document_Master__r.Applicable_For_Ocr__c,
                    Verification_Status__c,Remarks__c,Screening_Status__c ,Owner.Name,Document_Master__r.Document_Category__c,Requirement_Level__c,FCU_Initiated__c FROM Document_Details__c WHERE Loan_Application__c =:recId AND
                    Applicant__c = NULL AND Active__c=true ORDER by Document_Master__r.Sequence__c ASC,Document_Master__r.Document_Name__c ASC];
                }
            }
            else{
                if(appId!=null &&appId!='' ){
                    System.debug('appId-----'+appId);
                    System.debug('catg-----'+catg);
                    if(catg == 'Sales'){
                        documentLst = [SELECT Id, Name, Applicant__c,Applicant__r.Customer_Profile__c,Bank_Details__c,Is_Uploaded__c, DDE_Status__c, Applicant__r.Applicant_Name__c,Applicant__r.Employment_Type__c,Document_Master__r.Document_Name__c,Document_Master__r.Document_Type__c,Document_Master__r.Sequence__c,
                        Content_Document_Id__c, Document_Master__c, Verification_Status__c, Is_manual_masking_confirmed__c,Aadhar_Masked_Source__c,
                        Remarks__c, Screening_Status__c, Owner.Name, Document_Master__r.Document_Category__c ,Document_Master__r.Applicable_For_Ocr__c,
                        Requirement_Level__c, FCU_Initiated__c FROM Document_Details__c WHERE Loan_Application__c =: recId 
                        AND Applicant__c =: appId AND Active__c=true AND  (Is_Sales_Manual_Document__c=true OR Source__c = 'CKYC' ) AND Consider_for_Loan_Application__c = true ORDER by Document_Master__r.Sequence__c ASC,Document_Master__r.Document_Name__c ASC];
                    }else{
                        documentLst = [SELECT Id, Name, Applicant__c,Applicant__r.Customer_Profile__c,Bank_Details__c,Is_Uploaded__c, DDE_Status__c, Applicant__r.Applicant_Name__c,Applicant__r.Employment_Type__c,Document_Master__r.Document_Name__c,Document_Master__r.Document_Type__c,Document_Master__r.Sequence__c,
                        Content_Document_Id__c, Document_Master__c, Verification_Status__c, Is_manual_masking_confirmed__c,Aadhar_Masked_Source__c,
                        Remarks__c, Screening_Status__c, Owner.Name, Document_Master__r.Document_Category__c,Document_Master__r.Applicable_For_Ocr__c, 
                        Requirement_Level__c, FCU_Initiated__c FROM Document_Details__c WHERE Loan_Application__c =: recId 
                        AND Applicant__c =: appId AND Active__c=true ORDER by Document_Master__r.Sequence__c ASC,Document_Master__r.Document_Name__c ASC];
                    }
                }
                else{
                    if(catg!=null && catg!=''){
                        System.debug('recId 24'+recId);
                        System.debug('catg 25'+catg);
                        if(catg == 'Sales'){
                            documentLst = [SELECT Id, Name, Applicant__c,Applicant__r.Customer_Profile__c,Bank_Details__c,Is_Uploaded__c, DDE_Status__c, Applicant__r.Applicant_Name__c,Is_manual_masking_confirmed__c,Aadhar_Masked_Source__c,
                                Content_Document_Id__c, Document_Master__c,Document_Master__r.Document_Name__c, Verification_Status__c, Document_Master__r.Document_Type__c,Document_Master__r.Sequence__c,
                                Remarks__c, Screening_Status__c, Owner.Name,Document_Master__r.Document_Category__c, Requirement_Level__c,FCU_Initiated__c,Document_Master__r.Applicable_For_Ocr__c
                                FROM Document_Details__c WHERE Loan_Application__c =: recId AND Content_Document_Id__c != null AND  (Is_Sales_Manual_Document__c=true OR Source__c = 'CKYC' )AND Consider_for_Loan_Application__c = true AND Active__c=true ORDER by Document_Master__r.Sequence__c ASC,Document_Master__r.Document_Name__c ASC];
                        }
                    }
                    else{
                    documentLst = [SELECT id,Name,Applicant__c,Is_Uploaded__c,Applicant__r.Customer_Profile__c,Bank_Details__c,Document_Master__r.Document_Name__c,DDE_Status__c,Applicant__r.Applicant_Name__c,Document_Master__r.Document_Type__c,Content_Document_Id__c,Document_Master__c,Document_Master__r.Applicable_For_Ocr__c,Document_Master__r.Sequence__c,
                        Verification_Status__c,Remarks__c,Screening_Status__c,Is_manual_masking_confirmed__c ,Aadhar_Masked_Source__c,Owner.Name,Document_Master__r.Document_Category__c,Requirement_Level__c,FCU_Initiated__c FROM Document_Details__c WHERE Loan_Application__c =:recId AND
                        Content_Document_Id__c != null AND  Active__c=true ORDER by Document_Master__r.Sequence__c ASC,Document_Master__r.Document_Name__c ASC];
                    }
                }
            }
        Map<String,List<DocumentWrapper>> categoryToDocumentMap = new  Map<String,List<DocumentWrapper>> ();
        Set<String> conDocIds = new Set<String>();
        if(documentLst.size() > 0) {
            for(Document_Details__c iterDocs : documentLst) {
                if(iterDocs.Content_Document_Id__c!=null && iterDocs.Content_Document_Id__c!= ''){
                    conDocIds.add(iterDocs.Content_Document_Id__c);
                }
            }
        }
        System.debug('conDocIds '+conDocIds);
        List<ContentVersion> contentList = new List<ContentVersion>();
        Map<String, ContentVersion> contentDocIdToRecordMap = new Map<String, ContentVersion>();
        if(!conDocIds.isEmpty()) {
            for(ContentVersion iterConVer : [SELECT Id, ContentDocumentId, VersionData, FileExtension
                                             FROM ContentVersion
                                             WHERE ContentDocumentId IN :conDocIds
                                             AND FileExtension IN ('pdf','PDF','jpg','png','jpeg')
                                             ORDER BY CreatedDate DESC
                                            ]){
                                                if(!contentDocIdToRecordMap.containsKey(iterConVer.ContentDocumentId)) {
                                                    contentDocIdToRecordMap.put(iterConVer.ContentDocumentId,iterConVer); 
                                                }
                                            }
        }
        System.debug('contentDocIdToRecordMap '+contentDocIdToRecordMap);
            Integer count = 1;
            for(Document_Details__c iterDocs : documentLst) {
               
                DocumentWrapper iterDocWrap = new DocumentWrapper();
                iterDocWrap.docCount = count++;
                // iterDocWrap.docName = iterDocs.Name;
                if(iterDocs.Applicant__c != null) {
                    iterDocWrap.docName = iterDocs.Name +
                        ' ('+iterDocs.Applicant__r.Applicant_Name__c+')';
                }
               
                iterDocWrap.Status = iterDocs.Verification_Status__c;
                iterDocWrap.isVerified = iterDocs.Verification_Status__c == 'Verified' ? true : false;
                iterDocWrap.docContentId = iterDocs.Content_Document_Id__c;
                iterDocWrap.docChecklistId = iterDocs.id;
                iterDocWrap.uploaded = iterDocs.Is_Uploaded__c;
                iterDocWrap.docApplicantId = iterDocs.Applicant__c != null ? iterDocs.Applicant__c : null;
                System.debug('iterDocs.Name : '+iterDocs.Name);
                System.debug('iterDocWrap.docContentId : '+iterDocWrap.docContentId);
                System.debug('iterDocs.Content_Document_Id__c: '+iterDocs.Content_Document_Id__c);
                if(iterDocs.Content_Document_Id__c!=null && iterDocs.Content_Document_Id__c!='' && contentDocIdToRecordMap.containsKey(iterDocs.Content_Document_Id__c)){
                    System.debug ('contentDocIdToRecordMap.get(iterDocs.Content_Document_Id__c).VersionData '+contentDocIdToRecordMap.get(iterDocs.Content_Document_Id__c).VersionData);
                    Blob fileBlob = contentDocIdToRecordMap.get(iterDocs.Content_Document_Id__c).VersionData;
                    // iterDocWrap.docVerionData = EncodingUtil.base64Encode(fileBlob);   
                    iterDocWrap.docExtention = contentDocIdToRecordMap.get(iterDocs.Content_Document_Id__c).FileExtension;
                }
                iterDocWrap.remarks = iterDocs.Remarks__c;
                iterDocWrap.screeningstatus = iterDocs.Screening_Status__c;
                iterDocWrap.owner = iterDocs.Owner.Name;
                iterDocWrap.requirementLevel = iterDocs.Requirement_Level__c;
                iterDocWrap.appName = iterDocs.Applicant__r.Applicant_Name__c;
                iterDocWrap.docType = iterDocs.Document_Master__r.Document_Category__c;
                iterDocWrap.fcuinitiated = iterDocs.FCU_Initiated__c;
                iterDocWrap.appId =  iterDocs.Applicant__c;
                iterDocWrap.acDocName = iterDocs.Name;
                // if(contentDocIdToRecordMap.containsKey(iterDocs.Content_Document_Id__c)){
                //     iterDocWrap.contentVersion  = contentDocIdToRecordMap.get(iterDocs.Content_Document_Id__c).Id;
                // }
                iterDocWrap.docMasterName = iterDocs.Document_Master__r.Document_Name__c;
                if(iterDocs.Name.toLowerCase().contains('aadhar') || iterDocs.Name.toLowerCase().contains('aadhaar')){
                    // if(maskedSource == 'Api' || maskedSource == '' || maskedSource == null){
                    if(iterDocs.Aadhar_Masked_Source__c == 'API' || iterDocs.Aadhar_Masked_Source__c == '' || iterDocs.Aadhar_Masked_Source__c == null){
                        iterDocWrap.showMaskingCheck= false;
                    }else{
                        iterDocWrap.showMaskingCheck= true;
                    }
                    if(iterDocs.Is_manual_masking_confirmed__c){
                        iterDocWrap.isOcr = false;
                    }else{
                        iterDocWrap.isOcr =  iterDocs.Document_Master__r.Applicable_For_Ocr__c;
                    }
                }else{
                    iterDocWrap.isOcr = iterDocs.Document_Master__r.Applicable_For_Ocr__c;
                    iterDocWrap.showMaskingCheck= false;
                }
                
                iterDocWrap.isAcknowledged= iterDocs.Is_manual_masking_confirmed__c;
                iterDocWrap.docMasterApplicant = iterDocs.Document_Master__r.Document_Name__c  + ' ('+iterDocs.Applicant__r.Applicant_Name__c+')';
             
                iterDocWrap.bankrecordId = iterDocs.Bank_Details__c;
                if(iterDocs.Document_Master__r.Document_Type__c != null){
                    if(categoryToDocumentMap.containsKey(iterDocs.Document_Master__r.Document_Type__c)){
                        categoryToDocumentMap.get(iterDocs.Document_Master__r.Document_Type__c).add(iterDocWrap);
                    }
                    else{
                        categoryToDocumentMap.put(iterDocs.Document_Master__r.Document_Type__c, new List<DocumentWrapper>{iterDocWrap});
                    }
                }
                else{
                    if(categoryToDocumentMap.containsKey('Others')){
                        categoryToDocumentMap.get('Others').add(iterDocWrap);
                    }
                    else{
                        categoryToDocumentMap.put('Others', new List<DocumentWrapper>{iterDocWrap});
                    }
                }
                
               
            }
            // System.debug('categoryToDocumentMap=:'+categoryToDocumentMap);
            // System.debug('categoryToDocumentMap.keyset=:'+categoryToDocumentMap.keySet());
            for(String str : categoryToDocumentMap.keySet()){
               
                MainDocumentWrapper mw = new MainDocumentWrapper();
                mw.documentCategory  = str;
                mw.showMessage = false;
               
                
                    if(str =='POI'){
                        mw.message ='Please upload document from this category to proceed further';
                        mw.showMessage = true;
                    }
                    if(str =='POA'){
                        mw.message ='Please upload any one document from this category to proceed further';
                        mw.showMessage = true;
                    }
                    if(str =='Others'){
                        mw.message ='Please upload photograph from this category to proceed further';
                        mw.showMessage = true;
                    }
                    if(str =='Ownership proof'){
                        mw.message ='Please upload any one document from this category to proceed further';
                        mw.showMessage = true;
                    }
                    if(str=='Proof of practice' ){
                        mw.message ='Please upload any one document from this category to proceed further';
                        mw.showMessage = true;
                    }
                    if(str=='Qualification proof' ){
                        mw.message ='Please upload any one document from this category to proceed further';
                        mw.showMessage = true;
                    }
                    if(str=='Proof of office'){
                        mw.message ='Please upload any one document from this category to proceed further';    
                        
                        mw.showMessage = true;
                    }
                    if(str=='Proof of registration'){
                        mw.message = 'Please upload any 2 document from this category to proceed further';
                        mw.showMessage = true;
                    }

                
               
                mw.documentList = new List<DocumentWrapper>();
                mw.documentList.addAll(categoryToDocumentMap.get(str));
                documentList.add(mw);
            }
           System.debug('documentList-----'+documentList);
        return documentList;
    }

    @AuraEnabled
    public static Map<String, String> getAllCrifReports(String recordId, String applicantId) {
        System.debug('applicantId----'+applicantId);
        Map<String, String> mapOfCibilReport = new Map<String, String>();
        try {
            List<Application_Applicant__c> applicant= [SELECT Id, Name FROM Application_Applicant__c WHERE Id = :applicantId];
            String applicantName= '';
            if(applicant.size()>0){
                applicantName = applicant[0].Name;
            }

            List<Document_Details__c> dd = [
                SELECT Content_Document_Id__c, Name 
                FROM Document_Details__c 
                WHERE Loan_Application__c = :recordId AND Applicant__c = :applicantId AND Name = 'CRIF' 
                ORDER BY CreatedDate DESC 
            ];

            Integer versionCount = dd.size();

            for(Document_Details__c document: dd){
                if(document.Content_Document_Id__c != null && versionCount > 0) {
                    // Query latest ContentVersion Id for this ContentDocumentId
                    ContentVersion cv = [
                        SELECT Id
                        FROM ContentVersion
                        WHERE ContentDocumentId = :document.Content_Document_Id__c
                        ORDER BY VersionNumber DESC
                        LIMIT 1
                    ];
                    mapOfCibilReport.put(applicantName + ' - V' + versionCount, cv.Id);
                    versionCount = versionCount - 1;
                }
            }
        } catch (Exception e) {
            // Handle exception or throw AuraHandledException
        }
        return mapOfCibilReport;
    }

    
    @AuraEnabled
    public static List<DocumentWrapper> getAllDocument(Id recordId , String catg ,String appId ,Boolean loan){
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        List<Document_Details__c> documentLst = new List<Document_Details__c>();
        Map<String,Boolean> resultMap = new Map<String,Boolean>();
        Set<String> docMasterName = new Set<String>();
        System.debug('recordId : '+recordId);
        System.debug('catg : '+catg);
        System.debug('appId : '+appId);
        System.debug('sObjName : '+sObjName);
        System.debug('loan : '+loan);
        Id recId;
        if(sObjName == 'Opportunity' && recordId != null) {
            recId = recordId;   
            System.debug('recId '+recId);
        }else {
            // get loan id from other object and assign in recId
        }
        List<DocumentWrapper> documentList = new List<DocumentWrapper>();
        if(catg == 'DDE'){
            //1
            String doccat = constants.get('DDE_DOC');
            Set<String> docCategories = new Set<String>();
            if (doccat != null) {
                docCategories.addAll(doccat.split(','));
            }
            //2
            Set<String> documentMasterNames = new Set<String>();
            List<Document_Master__c> documentMasters = [SELECT Name FROM Document_Master__c 
                                                        WHERE Document_Category__c IN :docCategories];
            for (Document_Master__c docMaster : documentMasters) {
                documentMasterNames.add(docMaster.Name);
            }
            //3
            Set<String> formNames = new Set<String>();
            List<Screen_Field__c> screenFields = [SELECT Form_Name__c 
                                                  FROM Screen_Field__c 
                                                  WHERE Form_Name__c IN :documentMasterNames];
            for (Screen_Field__c screenField : screenFields) {
                formNames.add(screenField.Form_Name__c);
            }
            System.debug('Document Categories: ' + docCategories);
            System.debug('Document Master Names: ' + documentMasterNames);
            System.debug('Form Names: ' + formNames);
            documentLst = [SELECT id,Name,Applicant__c,Bank_Details__c,Is_manual_masking_confirmed__c,Aadhar_Masked_Source__c,Is_Uploaded__c,DDE_Status__c,Document_Master__r.Document_Name__c,Applicant__r.Applicant_Name__c,Content_Document_Id__c,Document_Master__c,Document_Master__r.Applicable_For_Ocr__c,
                Verification_Status__c,Remarks__c,Screening_Status__c ,Owner.Name,Document_Master__r.Document_Category__c,Requirement_Level__c,FCU_Initiated__c FROM Document_Details__c WHERE Loan_Application__c =:recId 
                AND Active__c=true AND Document_Master__r.Document_Name__c IN : formNames AND Applicant__c=:appId AND Is_Uploaded__c = true];
                for (Document_Details__c dd : documentLst) {
                    if (dd.Verification_Status__c != 'Verified') {
                        String applicantId = dd.Applicant__c;
                        String docName = dd.Document_Master__r.Document_Name__c;
                        docMasterName.add(docName);
                }
                System.debug('docMasterName '+docMasterName);
                resultMap = Utility.checkDataFilledOrNot(docMasterName,appId);
                System.debug('resultMap '+resultMap);
                //map<String,Boolean> =  getscreenfield(red);
            }
        }
        else if(catg == 'Income Related'){
                //1
                String doccat = constants.get('CO_DOC');
                Set<String> docCategories = new Set<String>();
                if (doccat != null) {
                    docCategories.addAll(doccat.split(','));
                }
                //2
                Set<String> documentMasterNames = new Set<String>();
                List<Document_Master__c> documentMasters = [SELECT Name FROM Document_Master__c 
                                                            WHERE Document_Category__c IN :docCategories];
                for (Document_Master__c docMaster : documentMasters) {
                    documentMasterNames.add(docMaster.Name);
                }
                //3
                Set<String> formNames = new Set<String>();
                List<Screen_Field__c> screenFields = [SELECT Form_Name__c 
                                                        FROM Screen_Field__c 
                                                        WHERE Form_Name__c IN :documentMasterNames];
                for (Screen_Field__c screenField : screenFields) {
                    formNames.add(screenField.Form_Name__c);
                }
                System.debug('Document Categories: ' + docCategories);
                System.debug('Document Master Names: ' + documentMasterNames);
                System.debug('Form Names: ' + formNames);
                documentLst = [SELECT id,Name,Applicant__c,Bank_Details__c,Is_manual_masking_confirmed__c,Aadhar_Masked_Source__c,Is_Uploaded__c,DDE_Status__c,Document_Master__r.Document_Name__c,Applicant__r.Applicant_Name__c,Content_Document_Id__c,Document_Master__c,Document_Master__r.Applicable_For_Ocr__c,
                Verification_Status__c,Remarks__c,Screening_Status__c ,Owner.Name,Document_Master__r.Document_Category__c,Requirement_Level__c,FCU_Initiated__c FROM Document_Details__c WHERE Loan_Application__c =:recId 
                AND Active__c=true AND Document_Master__r.Document_Name__c IN : formNames AND Applicant__c=:appId AND Is_Uploaded__c = true];
            for(Document_Details__c dd : documentLst){
                if(dd.Bank_Details__c !=null && dd.Document_Master__r.Document_Name__c == '12 months bank statement'){
                    if (dd.Verification_Status__c != 'Verified') {
                        String docName = dd.Document_Master__r.Document_Name__c;
                        docMasterName.add(docName);
                        resultMap = Utility.checkDataFilledOrNot(docMasterName,dd.Bank_Details__c);
                    }
                }
            }
        }
        else{
            if(loan!=null && loan == true){
                if(catg == 'Sales'){
                    documentLst = [SELECT id,Name,Applicant__c,Bank_Details__c,Is_Uploaded__c,DDE_Status__c,Document_Master__r.Document_Name__c,Aadhar_Masked_Source__c,Applicant__r.Applicant_Name__c,Is_manual_masking_confirmed__c,Content_Document_Id__c,Document_Master__c,Document_Master__r.Applicable_For_Ocr__c,
                    Verification_Status__c,Remarks__c,Screening_Status__c ,Owner.Name,Document_Master__r.Document_Category__c,Requirement_Level__c,FCU_Initiated__c FROM Document_Details__c WHERE Loan_Application__c =:recId AND
                    Applicant__c = NULL AND Active__c=true AND  (Is_Sales_Manual_Document__c=true OR Source__c = 'CKYC' )];
                }else{
                    documentLst = [SELECT id,Name,Applicant__c,Bank_Details__c,Is_Uploaded__c,DDE_Status__c,Document_Master__r.Document_Name__c,Aadhar_Masked_Source__c,Applicant__r.Applicant_Name__c,Is_manual_masking_confirmed__c,Content_Document_Id__c,Document_Master__c,Document_Master__r.Applicable_For_Ocr__c,
                    Verification_Status__c,Remarks__c,Screening_Status__c ,Owner.Name,Document_Master__r.Document_Category__c,Requirement_Level__c,FCU_Initiated__c FROM Document_Details__c WHERE Loan_Application__c =:recId AND
                    Applicant__c = NULL AND Active__c=true];
                }
            }
            else{
                if(appId!=null &&appId!='' ){
                    if(catg == 'Sales'){
                        documentLst = [SELECT Id, Name, Applicant__c,Bank_Details__c,Is_Uploaded__c,Document_Master__r.Document_Name__c, DDE_Status__c, Applicant__r.Applicant_Name__c, 
                        Content_Document_Id__c, Document_Master__c, Verification_Status__c, Is_manual_masking_confirmed__c,Aadhar_Masked_Source__c,
                        Remarks__c, Screening_Status__c, Owner.Name, Document_Master__r.Document_Category__c ,Document_Master__r.Applicable_For_Ocr__c,
                        Requirement_Level__c, FCU_Initiated__c FROM Document_Details__c WHERE Loan_Application__c =: recId 
                        AND Applicant__c =: appId AND Active__c=true AND  (Is_Sales_Manual_Document__c=true OR Source__c = 'CKYC' )];
                    }else{
                        documentLst = [SELECT Id, Name, Applicant__c,Bank_Details__c,Is_Uploaded__c,Document_Master__r.Document_Name__c, DDE_Status__c, Applicant__r.Applicant_Name__c, 
                        Content_Document_Id__c, Document_Master__c, Verification_Status__c, Is_manual_masking_confirmed__c,Aadhar_Masked_Source__c,
                        Remarks__c, Screening_Status__c, Owner.Name, Document_Master__r.Document_Category__c,Document_Master__r.Applicable_For_Ocr__c, 
                        Requirement_Level__c, FCU_Initiated__c FROM Document_Details__c WHERE Loan_Application__c =: recId 
                        AND Applicant__c =: appId AND Active__c=true];
                    }
                }
                else{
                    if(catg!=null && catg!=''){
                        System.debug('recId 24'+recId);
                        System.debug('catg 25'+catg);
                        if(catg == 'Sales'){
                            documentLst = [SELECT Id, Name, Applicant__c,Bank_Details__c,Is_Uploaded__c, DDE_Status__c, Applicant__r.Applicant_Name__c, Is_manual_masking_confirmed__c,Aadhar_Masked_Source__c,
                                Content_Document_Id__c, Document_Master__c,Document_Master__r.Document_Name__c, Verification_Status__c, 
                                Remarks__c, Screening_Status__c, Owner.Name,Document_Master__r.Document_Category__c, Requirement_Level__c,FCU_Initiated__c,Document_Master__r.Applicable_For_Ocr__c
                                FROM Document_Details__c WHERE Loan_Application__c =: recId AND Content_Document_Id__c != null AND  (Is_Sales_Manual_Document__c=true OR Source__c = 'CKYC' ) AND Active__c=true];
                        }else{
                            documentLst = [SELECT Id, Name, Applicant__c,Is_Uploaded__c, DDE_Status__c, Applicant__r.Applicant_Name__c, Is_manual_masking_confirmed__c,Aadhar_Masked_Source__c,
                                Content_Document_Id__c, Document_Master__c,Document_Master__r.Document_Name__c, Verification_Status__c, 
                                Remarks__c, Screening_Status__c, Owner.Name,Document_Master__r.Document_Category__c, Requirement_Level__c,FCU_Initiated__c,Document_Master__r.Applicable_For_Ocr__c
                                FROM Document_Details__c WHERE Loan_Application__c =: recId AND Content_Document_Id__c != null AND Document_Master__r.Document_Category__c =: catg AND Active__c=true];
                        }
                    }
                    else{
                    documentLst = [SELECT id,Name,Applicant__c,Is_Uploaded__c,Bank_Details__c,Document_Master__r.Document_Name__c,DDE_Status__c,Applicant__r.Applicant_Name__c,Content_Document_Id__c,Document_Master__c,Document_Master__r.Applicable_For_Ocr__c,
                        Verification_Status__c,Remarks__c,Screening_Status__c,Is_manual_masking_confirmed__c ,Aadhar_Masked_Source__c,Owner.Name,Document_Master__r.Document_Category__c,Requirement_Level__c,FCU_Initiated__c FROM Document_Details__c WHERE Loan_Application__c =:recId AND
                        Content_Document_Id__c != null AND  Active__c=true];
                    }
                }
            }
        }
        Set<String> conDocIds = new Set<String>();
        if(documentLst.size() > 0) {
            for(Document_Details__c iterDocs : documentLst) {
                if(iterDocs.Content_Document_Id__c!=null && iterDocs.Content_Document_Id__c!= ''){
                    conDocIds.add(iterDocs.Content_Document_Id__c);
                }
            }
        }
        System.debug('conDocIds '+conDocIds);
        List<ContentVersion> contentList = new List<ContentVersion>();
        Map<String, ContentVersion> contentDocIdToRecordMap = new Map<String, ContentVersion>();
        if(!conDocIds.isEmpty()) {
            for(ContentVersion iterConVer : [SELECT Id, ContentDocumentId, VersionData, FileExtension
                                             FROM ContentVersion
                                             WHERE ContentDocumentId IN :conDocIds
                                             AND FileExtension IN ('pdf','PDF','jpg','png','jpeg')
                                             ORDER BY CreatedDate DESC
                                            ]){
                                                if(!contentDocIdToRecordMap.containsKey(iterConVer.ContentDocumentId)) {
                                                    contentDocIdToRecordMap.put(iterConVer.ContentDocumentId,iterConVer); 
                                                }
                                            }
        }
        // List<Application_Applicant__c> applicantList= [SELECT Id, Aadhar_Masked_Source__c FROM Application_Applicant__c WHERE Id = :appId];
        // String maskedSource;
        // if(applicantList.size()>0){
        //     maskedSource= applicantList[0].Aadhar_Masked_Source__c;
        // }
        System.debug('contentDocIdToRecordMap '+contentDocIdToRecordMap);
            Integer count = 1;
            for(Document_Details__c iterDocs : documentLst) {
                DocumentWrapper iterDocWrap = new DocumentWrapper();
                iterDocWrap.docCount = count++;
                // iterDocWrap.docName = iterDocs.Name;
                if(iterDocs.Applicant__c != null) {
                    iterDocWrap.docName = iterDocs.Name +
                        ' ('+iterDocs.Applicant__r.Applicant_Name__c+')';
                }
                iterDocWrap.Status = iterDocs.Verification_Status__c;
                iterDocWrap.isVerified = iterDocs.Verification_Status__c == 'Verified' ? true : false;
                iterDocWrap.docContentId = iterDocs.Content_Document_Id__c;
                iterDocWrap.docChecklistId = iterDocs.id;
                iterDocWrap.uploaded = iterDocs.Is_Uploaded__c;
                iterDocWrap.docApplicantId = iterDocs.Applicant__c != null ? iterDocs.Applicant__c : null;
                System.debug('iterDocs.Name : '+iterDocs.Name);
                System.debug('iterDocWrap.docContentId : '+iterDocWrap.docContentId);
                System.debug('iterDocs.Content_Document_Id__c: '+iterDocs.Content_Document_Id__c);
                if(iterDocs.Content_Document_Id__c!=null && iterDocs.Content_Document_Id__c!='' && contentDocIdToRecordMap.containsKey(iterDocs.Content_Document_Id__c)){
                    System.debug ('contentDocIdToRecordMap.get(iterDocs.Content_Document_Id__c).VersionData '+contentDocIdToRecordMap.get(iterDocs.Content_Document_Id__c).VersionData);
                    Blob fileBlob = contentDocIdToRecordMap.get(iterDocs.Content_Document_Id__c).VersionData;
                    // iterDocWrap.docVerionData = EncodingUtil.base64Encode(fileBlob);   
                    iterDocWrap.docExtention = contentDocIdToRecordMap.get(iterDocs.Content_Document_Id__c).FileExtension;
                }
                iterDocWrap.remarks = iterDocs.Remarks__c;
                iterDocWrap.screeningstatus = iterDocs.Screening_Status__c;
                iterDocWrap.owner = iterDocs.Owner.Name;
                iterDocWrap.requirementLevel = iterDocs.Requirement_Level__c;
                iterDocWrap.appName = iterDocs.Applicant__r.Applicant_Name__c;
                iterDocWrap.docType = iterDocs.Document_Master__r.Document_Category__c;
                iterDocWrap.fcuinitiated = iterDocs.FCU_Initiated__c;
                iterDocWrap.appId =  iterDocs.Applicant__c;
                iterDocWrap.acDocName = iterDocs.Name;
                iterDocWrap.docMasterName = iterDocs.Document_Master__r.Document_Name__c;
                if(iterDocs.Name.toLowerCase().contains('aadhar') || iterDocs.Name.toLowerCase().contains('aadhaar')){
                    // if(maskedSource == 'Api' || maskedSource == '' || maskedSource == null){
                    if(iterDocs.Aadhar_Masked_Source__c == 'Api' || iterDocs.Aadhar_Masked_Source__c == '' || iterDocs.Aadhar_Masked_Source__c == null){
                        iterDocWrap.showMaskingCheck= false;
                    }else{
                        iterDocWrap.showMaskingCheck= true;
                    }
                    if(iterDocs.Is_manual_masking_confirmed__c){
                        iterDocWrap.isOcr = false;
                    }else{
                        iterDocWrap.isOcr =  iterDocs.Document_Master__r.Applicable_For_Ocr__c;
                    }
                }else{
                    iterDocWrap.isOcr = iterDocs.Document_Master__r.Applicable_For_Ocr__c;
                    iterDocWrap.showMaskingCheck= false;
                }
                
                iterDocWrap.isAcknowledged= iterDocs.Is_manual_masking_confirmed__c;
                iterDocWrap.docMasterApplicant = iterDocs.Document_Master__r.Document_Name__c  + ' ('+iterDocs.Applicant__r.Applicant_Name__c+')';
                if(catg == 'DDE'){
                    if(resultMap!=null){
                    if (resultMap.containsKey(iterDocs.Document_Master__r.Document_Name__c)){
                    iterDocWrap.detailsFilled = resultMap.get(iterDocs.Document_Master__r.Document_Name__c);
                        }
                    }
                }
                if(catg == 'Income Related'){
                    if(iterDocs.Document_Master__r.Document_Name__c == '12 months bank statement'){
                    if(resultMap!=null){
                        if (resultMap.containsKey(iterDocs.Document_Master__r.Document_Name__c)){
                        iterDocWrap.detailsFilled = resultMap.get(iterDocs.Document_Master__r.Document_Name__c);
                            }
                        }
                    }
                }
                iterDocWrap.bankrecordId = iterDocs.Bank_Details__c;
                documentList.add(iterDocWrap);
            }
        
        return documentList;
    }
    static string conLabels = 'CO_DOC,DDE_DOC';
    public static Map<string, string> constants = Utility.getConstants(conLabels);

    @AuraEnabled
    public static String sendBackDoc(Id docDetailId, String remarks){
        String res = 'fail';
        try{
            List<Document_Details__c> documentLst = [SELECT id, Verification_Status__c,Remarks__c FROM Document_Details__c WHERE id =:docDetailId];
            documentLst[0].Verification_Status__c = 'Sent Back';
            documentLst[0].Remarks__c = remarks;
            update documentLst;
            res = 'success';
        }
        catch(Exception exp){
            // Utility.generateException(exp, Constants.FRAUD_CONTROL_UNIT, Constants.FCU_CLASS_1);
            return res;
        }
        return res;
        //
        
    }
    

    @AuraEnabled
    public static Map<string, string> getConstants() {
        return constants;
    }
    
    @AuraEnabled
    public static String validateDoc(Id docDetailId){
        String res = 'fail';
        try{
            List<Document_Details__c> documentLst = [SELECT id, Verification_Status__c,Remarks__c FROM Document_Details__c WHERE id =:docDetailId];
            documentLst[0].Verification_Status__c = 'Verified';
            update documentLst;
            res = 'success';
        }
        catch(Exception exp){
            // Utility.generateException(exp, Constants.FRAUD_CONTROL_UNIT, Constants.FCU_CLASS_1);
            return res;
        }
        return res;
        //
        
    }
    @AuraEnabled
    public static String unValidateDoc(Id docDetailId){
        String res = 'fail';
        try{
            List<Document_Details__c> documentLst = [SELECT id, Verification_Status__c,Remarks__c FROM Document_Details__c WHERE id =:docDetailId];
            documentLst[0].Verification_Status__c = 'Pending';
            update documentLst;
            res = 'success';
        }
        catch(Exception exp){
            // Utility.generateException(exp, Constants.FRAUD_CONTROL_UNIT, Constants.FCU_CLASS_1);
            return res;
        }
        return res;
        //
        
    }
    public class MainDocumentWrapper{
        @AuraEnabled public List<DocumentWrapper> documentList;
        @AuraEnabled public String documentCategory;
        @AuraEnabled public String message; 
        @AuraEnabled public boolean showMessage;
    }
    public class DocumentWrapper{
        @AuraEnabled public Integer docCount;
        @AuraEnabled public String docName;
        @AuraEnabled public String Status;
        @AuraEnabled public String docExtention;
        @AuraEnabled public Boolean isVerified;
        @AuraEnabled public String docContentId;
        @AuraEnabled public String docChecklistId;
        @AuraEnabled public String docApplicantId;
        // @AuraEnabled public String docVerionData;
        @AuraEnabled public String remarks;
        @AuraEnabled public String screeningstatus;
        @AuraEnabled public String owner;
        @AuraEnabled public String requirementLevel;
        @AuraEnabled public String appName;
        @AuraEnabled public String docType;
        @AuraEnabled public Boolean fcuinitiated;
        @AuraEnabled public String appId;
        @AuraEnabled public String acDocName;
        @AuraEnabled public String docMasterName;
        @AuraEnabled public Boolean uploaded;
        @AuraEnabled public Boolean isOcr;
        @AuraEnabled public Boolean showMaskingCheck;
        @AuraEnabled public Boolean isAcknowledged;
        @AuraEnabled public Boolean detailsFilled = false;
        @AuraEnabled public String  docMasterApplicant;
        @AuraEnabled public String  bankrecordId;
        
    }
    @AuraEnabled
    public static List<ApplicantAddressWrapper> fetchApplicantsAddresses(String recordId, String appId) {
        Id objectId ;
        String objectName;
        if(String.isNotBlank(recordId)){
            objectId = Id.valueof(recordId);
            objectName =objectId.getsobjecttype().getDescribe().getName();
        }
      
     
        List<String> appIdList = new List<String> ();
        if(objectName =='Account'){
            List<Application_Applicant__c> applIst =[Select id,Customer__c from Application_Applicant__c where Customer__c=:recordId];
            for(Application_Applicant__c app : applIst){
                 appIdList.add(app.id);
            }
           
        }
        else{
            appIdList.add(appId);
        }
        List<Applicant_Address__c> aadList = [
            SELECT Id,Address_Type__c, Pincode__c,City__c,Pincode__r.Name, Applicant__r.Name,State__c, District__c, Town__c, Address_Source__c,Address_Priority__c,Applicant__r.Loan_Application__r.Name,
                   Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Remarks__c ,Document_Details__r.Document_Master__r.Name,Address_Ownership__c
            FROM Applicant_Address__c 
            /*WHERE Loan_Application__c = :recordId */
            WHERE Applicant__c IN :appIdList AND Address_Type__c != 'BSA' AND Application_Collateral__c=null
        ];

        List<ApplicantAddressWrapper> addressWrappers = new List<ApplicantAddressWrapper>();
        
        for (Applicant_Address__c aad : aadList) {
            ApplicantAddressWrapper adwrap = new ApplicantAddressWrapper();
            if(!(aad.Address_Type__c == 'Current' && aad.Document_Details__c==null)){
                adwrap.showApplicantDetails =false;
                adwrap.Id = aad.Id;
                adwrap.addressType = aad.Address_Type__c;
                adwrap.pincode = aad.Pincode__c;
                adwrap.city = aad.City__c;
                adwrap.pincodename = aad.Pincode__r.Name;
                adwrap.state = aad.State__c;
                adwrap.district = aad.District__c;
                adwrap.town = aad.Town__c;
                adwrap.addressLine1 = aad.Address_Line_1__c;
                adwrap.addressLine2 = aad.Address_Line_2__c;
                adwrap.addressLine3 = aad.Address_Line_3__c;
                adwrap.priority = aad.Address_Priority__c;
                adwrap.documentType = aad.Document_Details__r.Document_Master__r.Name;
                adwrap.address = aad.Address_Line_1__c + ' ' + aad.Address_Line_2__c + ' '+aad.Address_Line_3__c;
                adwrap.ownerShip = aad.Address_Ownership__c;
                if(objectName =='Account'){
                    adwrap.loanNumber = aad.Applicant__r.Loan_Application__r.Name;
                    adwrap.applicantName = aad.Applicant__r.Name;
                     adwrap.showApplicantDetails =true;
                }
                addressWrappers.add(adwrap);
            }
        }
        
        return addressWrappers;
    }
    
    public class ApplicantAddressWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String addressType;
        @AuraEnabled public String pincode;
        @AuraEnabled public String city;
        @AuraEnabled public String pincodename;
        @AuraEnabled public String state;
        @AuraEnabled public String district;
        @AuraEnabled public String town;
        @AuraEnabled public String addressLine1;
        @AuraEnabled public String addressLine2;
        @AuraEnabled public String addressLine3;
        @AuraEnabled public String documentType;
        @AuraEnabled public String priority;
        @AuraEnabled public String address;
        @AuraEnabled public String ownerShip;
        @AuraEnabled public String loanNumber;
        @AuraEnabled public String applicantName;
        @AuraEnabled public Boolean showApplicantDetails;
        @AuraEnabled public String docId;
        @AuraEnabled public String docContentId;
        @AuraEnabled public String docFileType;
        @AuraEnabled public Boolean showUploadDoc;
        @AuraEnabled public Boolean showDoc;
        // public ApplicantAddressWrapper(Applicant_Address__c aad) {
        //     this.Id = aad.Id;
        //     this.addressType = aad.Address_Type__c;
        //     this.pincode = aad.Pincode__c;
        //     this.city = aad.City__c;
        //     this.pincodename = aad.Pincode__r.Name;
        //     this.state = aad.State__c;
        //     this.district = aad.District__c;
        //     this.town = aad.Town__c;
        //     this.addressLine1 = aad.Address_Line_1__c;
        //     this.addressLine2 = aad.Address_Line_2__c;
        //     this.addressLine3 = aad.Address_Line_3__c;
        //     this.priority = aad.Address_Priority__c;
        //     this.documentType = aad.Document_Details__r.Document_Master__r.Name;
        //     this.address = aad.Address_Line_1__c + ' ' + aad.Address_Line_2__c + ' '+aad.Address_Line_3__c;
        //     this.ownerShip = aad.Address_Ownership__c;
        // }
    }
    @AuraEnabled
    public static ApplicantAddressNewWrapper fetchApplicantsAddress(String recordId, String appId, String adrType) {
        List<Applicant_Address__c> aadList = [
            SELECT Id, Address_Type__c, Pincode__c,City__c, Pincode__r.Name, State__c, District__c, Town__c, Address_Priority__c,Document_Details__r.Document_Master__r.Name,
                   Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Remarks__c,Address_Ownership__c
            FROM Applicant_Address__c 
            WHERE Loan_Application__c = :recordId 
            AND Applicant__c = :appId 
            AND Address_Type__c = :adrType
            LIMIT 1
        ];
    
        // Return wrapper only if a record is found
        if (!aadList.isEmpty()) {
            return new ApplicantAddressNewWrapper(aadList[0]);
        } else {
            return null; // No record found
        }
    }

     public class ApplicantAddressNewWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String addressType;
        @AuraEnabled public String pincode;
        @AuraEnabled public String city;
        @AuraEnabled public String pincodename;
        @AuraEnabled public String state;
        @AuraEnabled public String district;
        @AuraEnabled public String town;
        @AuraEnabled public String addressLine1;
        @AuraEnabled public String addressLine2;
        @AuraEnabled public String addressLine3;
        @AuraEnabled public String documentType;
        @AuraEnabled public String priority;
        @AuraEnabled public String address;
        @AuraEnabled public String ownerShip;
        @AuraEnabled public String loanNumber;
        @AuraEnabled public String applicantName;
        @AuraEnabled public Boolean showApplicantDetails;

        public ApplicantAddressNewWrapper(Applicant_Address__c aad) {
            this.Id = aad.Id;
            this.addressType = aad.Address_Type__c;
            this.pincode = aad.Pincode__c;
            this.city = aad.City__c;
            this.pincodename = aad.Pincode__r.Name;
            this.state = aad.State__c;
            this.district = aad.District__c;
            this.town = aad.Town__c;
            this.addressLine1 = aad.Address_Line_1__c;
            this.addressLine2 = aad.Address_Line_2__c;
            this.addressLine3 = aad.Address_Line_3__c;
            this.priority = aad.Address_Priority__c;
            this.documentType = aad.Document_Details__r.Document_Master__r.Name;
            this.address = aad.Address_Line_1__c + ' ' + aad.Address_Line_2__c + ' '+aad.Address_Line_3__c;
            this.ownerShip = aad.Address_Ownership__c;
        }
    }    
    @AuraEnabled
    public static Boolean insertApplicantAddress(String recordId, String appId, String adrType, String pincode, 
                                                String addressLine1, String addressLine2, String addressLine3) {
        Boolean returnbol = false;
        try {
            Applicant_Address__c newAddress = new Applicant_Address__c(
                Loan_Application__c = recordId,
                Applicant__c = appId,
                Address_Type__c = adrType,
                Pincode__c = pincode,
                Address_Line_1__c = addressLine1,
                Address_Line_2__c = addressLine2,
                Address_Line_3__c = addressLine3
            );
    
            insert newAddress;
            returnbol = true; 
            return returnbol;
        } catch (Exception e) {
            throw new AuraHandledException('Error inserting address: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean deleteApplicantAddress(String adrId) {
        try {
            // Query the record that matches the given Address Type
            Applicant_Address__c addressToDelete = [
                SELECT Id FROM Applicant_Address__c 
                WHERE Id = :adrId 
                LIMIT 1
            ];
            
            // Delete the record
            delete addressToDelete;
            return true; // Successfully deleted
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting address: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void saveAddressRecord(String addrId, String adrType, String addressLine1, String addressLine2, String addressLine3) {
        try {
            // Fetch the existing record
            Applicant_Address__c address = [SELECT Id, Address_Type__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c 
                                FROM Applicant_Address__c WHERE Id = :addrId LIMIT 1];

            // Assign new values
            address.Address_Type__c = adrType;
            address.Address_Line_1__c = addressLine1;
            address.Address_Line_2__c = addressLine2;
            address.Address_Line_3__c = addressLine3;

            // Update the record
            update address;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving record: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Pincode_Master__c getPincodeDetails(String pinId) {
        try {
            // Fetch the record
            Pincode_Master__c pm = [SELECT Id, Name, State__c, Town__c 
                                    FROM Pincode_Master__c 
                                    WHERE Id = :pinId 
                                    LIMIT 1];

            return pm;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching record: ' + e.getMessage());
        }
    }
    public class pickListValueSet {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        // ✅ Corrected Constructor
        public pickListValueSet(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled
    public static List<pickListValueSet> getAddedAddressTypes(String recordId, String appId) {
        List<pickListValueSet> addressTypeList = new List<pickListValueSet>();
        // Fetch existing address types from Applicant_Address__c
        List<Applicant_Address__c> aadList = [
            SELECT Address_Type__c 
            FROM Applicant_Address__c 
            WHERE Loan_Application__c = :recordId 
            AND Applicant__c = :appId
        ];
        // Convert the Address_Type__c (Multi-Picklist) into pickListValueSet format
        for (Applicant_Address__c aad : aadList) {
            if (aad.Address_Type__c != null) {
                List<String> addressTypes = aad.Address_Type__c.split(';'); // Multi-Picklist values are separated by ';'
                for (String addrType : addressTypes) {
                    addressTypeList.add(new pickListValueSet(addrType, addrType)); 
                }
            }
        }

        return addressTypeList;
    }

    @AuraEnabled
    public static Boolean checkApiHit(String recordId, String appId, String name) {
        Boolean fetchAgain = true;  // Default to true if no records found
        try {
            List<Integration_Details__c> IDTList = new List<Integration_Details__c>();

            if (name == 'Loan CRIF' || name == 'Loan CIBIL' || name == 'Loan Applicant CKYC' || name == 'Gen AI') {
                IDTList = [
                    SELECT Id, Status__c, Name
                    FROM Integration_Details__c
                    WHERE Name = :name
                        AND Loan_Application__c = :recordId
                        AND Related_Record_Id__c = :appId
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
            }

            if (!IDTList.isEmpty() && IDTList[0].Status__c == '200') {
                fetchAgain = false;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return fetchAgain;
    }

    public class PanDobWrapper {
        @AuraEnabled public Date dob;
        @AuraEnabled public String pan;
        
        public PanDobWrapper(Date dob, String pan) {
            this.dob = dob;
            this.pan = pan;
        }
    }

    @AuraEnabled
    public static PanDobWrapper getPanandDob(String appId) {
        try {
            Application_Applicant__c ap = [
                SELECT DOB__c, PAN_Number__c
                FROM Application_Applicant__c
                WHERE Id = :appId
            ];

            if (ap != null) {
                return new PanDobWrapper(ap.DOB__c, ap.PAN_Number__c);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return null;
    }

    @AuraEnabled
    public static String getConsumerInformationReport(String recordId, String appId) {
        try {
          /*  Map<String,String> inputMapUtility = new  Map<String,String>();
            Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
            Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
        
              Document_Details__c dd = new   Document_Details__c();
            if(!isHlRelated){
                 dd = [
                SELECT Content_Document_Id__c
                FROM Document_Details__c 
                WHERE Loan_Application__c = :recordId AND Applicant__c = :appId AND Name = 'CRIF' 
                ORDER BY CreatedDate DESC 
                LIMIT 1
                ];
            }
            else{
                dd = [
                SELECT Content_Document_Id__c
                FROM Document_Details__c 
                WHERE Loan_Application__c = :recordId AND Applicant__c = :appId AND Name = 'Cibil' 
                ORDER BY CreatedDate DESC 
                LIMIT 1
                ]; 
            }
          
            if(!isHlRelated){
                if (dd != null && dd.Content_Document_Id__c != null) {
                    // Query latest ContentVersion for this ContentDocumentId
                    ContentVersion cv = [
                        SELECT Id
                        FROM ContentVersion
                        WHERE ContentDocumentId = :dd.Content_Document_Id__c
                        ORDER BY VersionNumber DESC
                        LIMIT 1
                    ];
                    return cv.Id; // Return ContentVersion Id
                }
            }
            else{
                if (dd != null) {
                return dd.Content_Document_Id__c;
             }
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }*/
          /* Document_Details__c dd = [
                SELECT Id, Content_Document_Id__c, Name 
                FROM Document_Details__c 
                WHERE Loan_Application__c = :recordId AND Applicant__c = :appId AND Name = 'CIBIL' 
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];*/
            Document_Details__c dd = [
                SELECT Id, Content_Document_Id__c, Name 
                FROM Document_Details__c 
                WHERE Loan_Application__c = :recordId AND Name = 'CIBIL' 
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];
            if (dd != null) {
                return dd.Content_Document_Id__c;
            } else {
                return null;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getGenAiFile(String recordId, String appId) {
        try {
            // Document_Details__c dd = [
            //     SELECT Id, Content_Document_Id__c, Name 
            //     FROM Document_Details__c 
            //     WHERE Loan_Application__c = :recordId AND Applicant__c = :appId AND Name = 'GEN AI' 
            //     ORDER BY CreatedDate DESC 
            //     LIMIT 1
            // ];
            Document_Details__c dd = [
                SELECT Id, Content_Document_Id__c, Name 
                FROM Document_Details__c 
                WHERE  Content_Document_Id__c = '069dN000006hoF7QAI' AND Name = 'GEN AI' 
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];
            if (dd != null) {
                return dd.Content_Document_Id__c;
            } else {
                return null;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean checkaddrtype(String adrtype, String recordId) {
        Boolean addressAdded = false;
        try {
            // Fetch the address record
            Applicant_Address__c aad = [SELECT Id, Name, Applicant__c FROM Applicant_Address__c WHERE Id = :recordId];
            if (aad != null) {
                // Check if the address type exists for the given record
                List<Applicant_Address__c> dad = [SELECT Id FROM Applicant_Address__c WHERE Address_Type__c = :adrtype AND Applicant__c = :aad.Applicant__c and Id!=:recordId LIMIT 1];
                if (dad.isEmpty()) {
                    addressAdded = true;
                }
            }
            
            return addressAdded;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean checkAddressAdded(String appId) {
        Boolean adAdded = false;
        try {
            List<Applicant_Address__c> add = [SELECT Id, Name FROM Applicant_Address__c WHERE Applicant__c = :appId];
            adAdded = !add.isEmpty();
            return adAdded;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class DocCheckWrapper {
        @AuraEnabled public String appId;
        @AuraEnabled public String appName;
        @AuraEnabled public Boolean remaining;
        @AuraEnabled public List<String> docRemaining;
        @AuraEnabled public List<String> docUploaded;
    }

    @AuraEnabled
    public static List<DocCheckWrapper> checkUploadedDocuments( String loanId){
        List<DocCheckWrapper> mainWrapperList = new List<DocCheckWrapper>();
        try {
            List<Application_Applicant__c> applicantList= [SELECT Id, Name, Applicant_Name__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId];
            List<Document_Details__c> docDetailsList= [SELECT Id, Name, Applicant__c, Document_Master__r.Mandatory_Non_Mandatory__c, Document_Master__r.Stage__c, Status__c FROM Document_Details__c WHERE Loan_Application__c = :loanId AND Document_Master__r.Stage__c = 'Sales login' AND Document_Master__r.Mandatory_Non_Mandatory__c = 'Required'];
            Map<String, List<Document_Details__c>> docMap = new Map<String, List<Document_Details__c>>();
            for (Document_Details__c doc : docDetailsList) {
                if(doc.Applicant__c!= null){
                    if (!docMap.containsKey(doc.Applicant__c)) {
                        docMap.put(doc.Applicant__c, new List<Document_Details__c>{doc});
                    }else{
                        docMap.get(doc.Applicant__c).add(doc);
                    }
                }else{
                    if (!docMap.containsKey('Loan')) {
                        docMap.put('Loan', new List<Document_Details__c>{doc});
                    }else{
                        docMap.get('Loan').add(doc);
                    }
                }
            }

            DocCheckWrapper loanWrapper= new DocCheckWrapper();
            loanWrapper.appId = loanId;
            loanWrapper.appName = 'Loan Application';
            loanWrapper.remaining = false;
            List<String> remainingLoanList= new List<String>();
            List<String> uploadedLoanList = new List<String>();
            if(docMap.containsKey('Loan')){
                List<Document_Details__c> documents = docMap.get('Loan');
                for (Document_Details__c doc : documents) {
                    if(doc.Status__c == null){
                        loanWrapper.remaining = true;
                        remainingLoanList.add(doc.Name);
                    }else if(doc.Status__c == 'Uploaded'){
                        uploadedLoanList.add(doc.Name);
                    }
                }
            }
            loanWrapper.docRemaining = remainingLoanList;
            loanWrapper.docUploaded = uploadedLoanList;
            mainWrapperList.add(loanWrapper);

            for(Application_Applicant__c aap: applicantList){
                DocCheckWrapper wrapper = new DocCheckWrapper();
                wrapper.appId = aap.Id;
                wrapper.appName = aap.Name;
                wrapper.remaining = false;
                List<String> remaining= new List<String>();
                List<String> uploaded = new List<String>();
                if(docMap.containsKey(aap.Applicant_Name__c)){
                    List<Document_Details__c> documents = docMap.get(aap.Id);
                    for (Document_Details__c doc : documents) {
                        if(doc.Status__c == null){
                            wrapper.remaining = true;
                            remaining.add(doc.Name);
                        }else if(doc.Status__c == 'Uploaded'){
                            uploaded.add(doc.Name);
                        }
                    }
                }
                wrapper.docRemaining = remaining;
                wrapper.docUploaded = uploaded;
                mainWrapperList.add(wrapper);
            }

        } catch (Exception e) {
            // throw new AuraHandledException(e.getMessage());
            System.debug('Error inside checkUploadedDocuments: '+e.getMessage()+' - '+e.getStackTraceString());
        }

        return mainWrapperList;
    }
    @AuraEnabled
    public static String getBase64FromContentId(Id contentDocumentId) {
        try {
            // Query the ContentVersion that contains the ContentDocumentId
            ContentVersion contentVersion = [
                SELECT Id, VersionData
                FROM ContentVersion
                WHERE ContentDocumentId = :contentDocumentId
                ORDER BY LastModifiedDate DESC
                LIMIT 1
            ];

            // Convert the Blob content to Base64 string
            Blob fileBlob = contentVersion.VersionData;
            String base64String = EncodingUtil.base64Encode(fileBlob); 
            return base64String;

        } catch (Exception e) {
            System.debug('Error retrieving base64 content: ' + e.getMessage());
            return null;
        }
    }
    //HL-Ishi-15/09
    @AuraEnabled
    public static Boolean checkAadharChecklist(String loanId) {
        try {
            List<Document_Master__c> docMasterList = [
                SELECT Id, Name, Customer_Type__c
                FROM Document_Master__c
                WHERE Is_Active__c = true
                AND Name IN ('Aadhaar Front', 'Aadhaar Back')
            ];
            Map<String, List<Document_Master__c>> docMasterMap = new Map<String, List<Document_Master__c>>();
            for (Document_Master__c dm : docMasterList) {
                if(docMasterMap.containskey(dm.Name)){
                    docMasterMap.get(dm.Name).add(dm);
                }else{
                    docMasterMap.put(dm.Name, new List<Document_Master__c>{dm});
                }
                
            }

            List<Applicant_Address__c> aadhaarAddressList = [
                SELECT Id, Applicant__c, Document_Details__c
                FROM Applicant_Address__c
                WHERE Applicant__r.Loan_Application__c = :loanId
                AND (Address_Source__c = 'Aadhaar' OR Address_Source__c = null)
            ];

            Set<Id> applicantIds = new Set<Id>();
            for (Applicant_Address__c addr : aadhaarAddressList) {
                if (addr.Applicant__c != null) {
                    applicantIds.add(addr.Applicant__c);
                }
            }

            Map<Id, Application_Applicant__c> applicantMap = new Map<Id, Application_Applicant__c>(
                [SELECT Id, Customer_Type__c FROM Application_Applicant__c WHERE Id IN :applicantIds]
            );

            // Fetch existing Aadhaar Front and Back documents for applicants
            List<Document_Details__c> existingDocs = [
                SELECT Id, Applicant__c, Document_Master__r.Name, Consider_for_Loan_Application__c
                FROM Document_Details__c
                WHERE Applicant__c IN :applicantIds
                AND Document_Master__r.Name IN ('Aadhaar Front', 'Aadhaar Back')
            ];

            Map<Id, Set<String>> existingDocsByApplicant = new Map<Id, Set<String>>();
            Map<Id, Id> aadhaarBackDocByApplicant = new Map<Id, Id>();
            List<Document_Details__c> docsToUpdate = new List<Document_Details__c>();

            for (Document_Details__c doc : existingDocs) {
                if (!existingDocsByApplicant.containsKey(doc.Applicant__c)) {
                    existingDocsByApplicant.put(doc.Applicant__c, new Set<String>());
                }
                existingDocsByApplicant.get(doc.Applicant__c).add(doc.Document_Master__r.Name);

                // Update Consider_for_Loan_Application__c = true if not already
                if (doc.Consider_for_Loan_Application__c != true) {
                    doc.Consider_for_Loan_Application__c = true;
                    docsToUpdate.add(doc);
                }

                // Track Aadhaar Back docs for linking to address
                if (doc.Document_Master__r.Name == 'Aadhaar Back') {
                    aadhaarBackDocByApplicant.put(doc.Applicant__c, doc.Id);
                }
            }

            if (!docsToUpdate.isEmpty()) {
                update docsToUpdate;
            }

            // Link Aadhaar Back document to Applicant_Address__c where Document_Details__c is null
            List<Applicant_Address__c> addressesToUpdate = new List<Applicant_Address__c>();
            for (Applicant_Address__c addr : aadhaarAddressList) {
                if (addr.Document_Details__c == null && aadhaarBackDocByApplicant.containsKey(addr.Applicant__c)) {
                    addr.Document_Details__c = aadhaarBackDocByApplicant.get(addr.Applicant__c);
                    addressesToUpdate.add(addr);
                }
            }

            if (!addressesToUpdate.isEmpty()) {
                update addressesToUpdate;
            }

            // Prepare to create missing documents
            List<Document_Details__c> docsToInsert = new List<Document_Details__c>();
            Map<Id, Id> addressToBackDocMap = new Map<Id, Id>();

            for (Applicant_Address__c addr : aadhaarAddressList) {
                List<Document_Master__c> docMasterListToCheck = new List<Document_Master__c>();
                Application_Applicant__c applicant = applicantMap.get(addr.Applicant__c);
                if (applicant == null) continue;

                Set<String> existingDocsForApplicant = existingDocsByApplicant.containsKey(applicant.Id)
                    ? existingDocsByApplicant.get(applicant.Id)
                    : new Set<String>();

                for (String docName : new List<String>{'Aadhaar Front', 'Aadhaar Back'}) {
                    if (existingDocsForApplicant.contains(docName)) continue;

                    List<Document_Master__c> dmList = docMasterMap.get(docName);
                    for(Document_Master__c dm: dmList){
                        if (dm != null && dm.Customer_Type__c == applicant.Customer_Type__c) {
                            Document_Details__c newDoc = new Document_Details__c();
                            newDoc.Name = docName;
                            newDoc.Document_Name__c = docName;
                            newDoc.Loan_Application__c= loanId;
                            newDoc.Consider_for_Loan_Application__c=true;
                            newDoc.Document_Master__c = dm.Id;
                            newDoc.Applicant__c = applicant.Id;
                            docsToInsert.add(newDoc);

                            if (docName == 'Aadhaar Back' && addr.Document_Details__c == null) {
                                addressToBackDocMap.put(addr.Id, null);
                            }
                            docMasterListToCheck.add(dm);
                            existingDocsForApplicant.add(docName);
                        }
                    }
                  
                }
            }

            if (!docsToInsert.isEmpty()) {
                insert docsToInsert;
                List<Document_Details__c> documentList = [Select id,Document_Master__r.Name,Document_Master__c from Document_Details__c where id IN : docsToInsert ];
                for (Document_Details__c doc : documentList) {
                    
                    if (doc.Document_Master__c != null && doc.Document_Master__r.Name == 'Aadhaar Back') {
                        for (Id addrId : addressToBackDocMap.keySet()) {
                            if (addressToBackDocMap.get(addrId) == null) {
                                addressToBackDocMap.put(addrId, doc.Id);
                                break;
                            }
                        }
                    }
                }

                List<Applicant_Address__c> addressesToUpdateAfterInsert = new List<Applicant_Address__c>();
                for (Id addrId : addressToBackDocMap.keySet()) {
                    Id backDocId = addressToBackDocMap.get(addrId);
                    if (backDocId != null) {
                        addressesToUpdateAfterInsert.add(
                            new Applicant_Address__c(Id = addrId, Document_Details__c = backDocId)
                        );
                    }
                }

                if (!addressesToUpdateAfterInsert.isEmpty()) {
                    update addressesToUpdateAfterInsert;
                }
            }

            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
     @AuraEnabled
    public static List<ApplicantAddressWrapper> fetchAddressDetails(String addressId, String appId) {
        List<Applicant_Address__c> aadList = [SELECT Id,Address_Type__c, Pincode__c,City__c,Pincode__r.Name, Applicant__r.Name,State__c, District__c, Town__c, Address_Source__c,Address_Priority__c,
                                                Applicant__r.Loan_Application__r.Name, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Remarks__c ,Document_Details__r.Document_Master__r.Name,
                                                Address_Ownership__c, Document_Details__c, Document_Details__r.Content_Document_Id__c FROM Applicant_Address__c WHERE Id=: addressId]; // Applicant__c =:appId AND
        
        List<ApplicantAddressWrapper> addressWrappers = new List<ApplicantAddressWrapper>();
        
        for (Applicant_Address__c aad : aadList) {
            ApplicantAddressWrapper adwrap = new ApplicantAddressWrapper();
            if(!(aad.Address_Source__c == 'Manual' && aad.Address_Type__c == 'Current' && aad.Document_Details__c==null)){
                adwrap.showApplicantDetails =false;
                adwrap.Id = aad.Id;
                adwrap.addressType = aad.Address_Type__c;
                adwrap.pincode = aad.Pincode__c;
                adwrap.city = aad.City__c;
                adwrap.pincodename = aad.Pincode__r.Name;
                adwrap.state = aad.State__c;
                adwrap.district = aad.District__c;
                adwrap.town = aad.Town__c;
                adwrap.addressLine1 = aad.Address_Line_1__c;
                adwrap.addressLine2 = aad.Address_Line_2__c;
                adwrap.addressLine3 = aad.Address_Line_3__c;
                adwrap.priority = aad.Address_Priority__c;
                adwrap.documentType = aad.Document_Details__r.Document_Master__r.Name;
                adwrap.address = aad.Address_Line_1__c + ' ' + aad.Address_Line_2__c + ' '+aad.Address_Line_3__c;
                adwrap.ownerShip = aad.Address_Ownership__c;
                adwrap.docId = aad.Document_Details__c;
                adwrap.docContentId = aad.Document_Details__r.Content_Document_Id__c;
                if (aad.Document_Details__r.Content_Document_Id__c !=null) {
                    List<ContentDocument> contDoc = [SELECT Id, CreatedBy.Name, FileType, CreatedDate FROM ContentDocument WHERE Id = :aad.Document_Details__r.Content_Document_Id__c LIMIT 1];
                    if(!contDoc.isEmpty()) {
                        adwrap.docFileType = contDoc[0].FileType;
                    }          
                }
                addressWrappers.add(adwrap);
            }
        }
        
        return addressWrappers;
    }

    @AuraEnabled
    public static void updateAddressRecord(Map<String, Object> addressData) {
        String recordId = (String)addressData.get('Id');
        Applicant_Address__c addr = [SELECT Id, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, City__c, State__c, Pincode__c, Address_Type__c, Address_Ownership__c FROM Applicant_Address__c WHERE Id = :recordId LIMIT 1];

        addr.Address_Line_1__c = (String)addressData.get('addressLine1');
        addr.Address_Line_2__c = (String)addressData.get('addressLine2');
        addr.Address_Line_3__c = (String)addressData.get('addressLine3');
        // addr.City__c = (String)addressData.get('city');
        // addr.State__c = (String)addressData.get('state');
        // addr.Pincode__c = (String)addressData.get('pincodename'); // or actual Pincode Id
        addr.Pincode__c = (String)addressData.get('pincode');
        addr.Address_Type__c = (String)addressData.get('addressType');
        addr.Address_Ownership__c = (String)addressData.get('ownerShip');

        update addr;
    }
        @AuraEnabled
    public static Map<String, String> getAllCibilReports( String recordId, String applicantId){
        System.debug('applicantId----'+applicantId);
        Map<String, String> mapOfCibilReport = new Map<String, String>();
        try {
            List<Application_Applicant__c> applicant= [SELECT Id, Name FROM Application_Applicant__c WHERE Id = :applicantId];
            String applicantName= '';
            if(applicant.size()>0){
                applicantName = applicant[0].Name;
            }

            List<Document_Details__c> dd = [
                SELECT Id, Content_Document_Id__c, Name 
                FROM Document_Details__c 
                WHERE Loan_Application__c = :recordId AND Applicant__c = :applicantId AND Name = 'CIBIL' 
                ORDER BY CreatedDate DESC 
            ];

            Integer versionCount = dd.size();

            for(Document_Details__c document: dd){
                if(document.Content_Document_Id__c != null && versionCount>0){
                    mapOfCibilReport.put(applicantName + ' - V'+versionCount, document.Content_Document_Id__c);
                    versionCount= versionCount-1;
                }
            }
        } catch (Exception e) {
            // throw new AuraHandledException(e.getMessage());
        }
        return mapOfCibilReport;
    }
    


    //HL-Ishi-1509

    


}