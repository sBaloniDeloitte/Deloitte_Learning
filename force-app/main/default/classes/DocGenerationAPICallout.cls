/**
 * @description       : 
 * @author            : Archana Giliyar
 * @group             : 
 * @last modified on  : 05-26-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class DocGenerationAPICallout {
    public static List<Document_Details__c> mergedDocument     =   new List<Document_Details__c>();
    public static List<Document_Details__c> templateDocument   =   new List<Document_Details__c>();
    public static List<Document_Details__c> eSignedDocument    =   new List<Document_Details__c>();
      //added
    //1. getCompressed Document
    @AuraEnabled
    public static String getCompressedDocument(String fileName, Id loanId, String contentDocId, String docDetailId) {
        try {
            // Query the latest ContentVersion for the given ContentDocumentId
            ContentVersion cv = [SELECT Id, VersionData FROM ContentVersion WHERE ContentDocumentId = :contentDocId ORDER BY CreatedDate DESC LIMIT 1];

            // String conVersionId = '068Bl000005TwH3IAK';
            DocGenComJSONCreator docGenReq = new DocGenComJSONCreator(cv.Id, fileName, 2);
            // DocGenComJSONCreator docGenReq = new DocGenComJSONCreator(conVersionId, fileName, 2);
            String jsonstring = JSON.serialize(docGenReq);
            System.debug('jsonstring : ' + jsonstring);

            HttpResponse res = DocGenerationRestUtility.getCompressedDocument(jsonstring);
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            System.debug('Response body: ' + res.getBody());
            LogAPIUtilityClass.logAPIcallouts(loanId,
                jsonstring.length() > 32100 ? jsonstring.substring(0, 32100) : jsonstring,
                '', 'Digio_CompressedAPI', res.getStatusCode());
            if (res.getStatusCode() != 200) {
                return null;
            } else {
                String contentVersionId = (String) result.get('data');
                System.debug('contentVersionId: ' + contentVersionId);

                List<ContentVersion> cvRec = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];

                if (!cvRec.isEmpty()) {
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.LinkedEntityId = docDetailId;
                    cdl.ContentDocumentId = cvRec[0].ContentDocumentId;
                    cdl.ShareType = 'V';
                    cdl.Visibility = 'AllUsers';
                    insert cdl;

                    if (docDetailId != null) {
                        Document_Details__c document = new Document_Details__c();
                        document.Content_Document_Id__c = cvRec[0].ContentDocumentId;
                        document.Id = docDetailId;
                        document.Status__c = Constants.STATUS_UPLOADED;
                        update document;
                    }
                    return cvRec[0].ContentDocumentId;
                } else {
                    // No ContentVersion found for returned Id
                    return null;
                }
            }
        } catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
            LogAPIUtilityClass.logAPIcallouts(loanId, '', e.getMessage(), 'Digio_CompressedAPI', null);
            return null;
        }
    }

    @AuraEnabled
    public static string postDocGenAPI (List<Id> documentId, Id loanId, String docType){
        try{
            eSealDocDetails eseal = fetchNewEseal(loanId);
        // Step 2: If docId is not null, add it to the list if not already present
        if (eseal != null && eseal.docId != null && !documentId.contains(eseal.docId)) {
            documentId.add(eseal.docId);
        }
            DocGenPreviewJSONCreator docGenPreviewRequestpayload  = DocGenPreviewRequestWrapper.createRequestPayload(documentId, loanId, docType);
            string returnresp;
            System.debug('docGenPreviewRequestpayload '+JSON.serialize(docGenPreviewRequestpayload));
            HttpResponse res 				= 	DocGenerationRestUtility.generateDocumentAPIAsync(JSON.serialize(docGenPreviewRequestpayload));
            string jsonstring               =   JSON.serialize(docGenPreviewRequestpayload);
            system.debug(JSON.serialize(docGenPreviewRequestpayload));
            System.debug('Serialized JSON => ' + jsonString);
            System.debug('res => ' + res);
            System.debug('Response body: ' + res.getBody());
            Map<String, Object> result 		= 	res.getStatusCode() != 502 ? (Map<String, Object>) JSON.deserializeUntyped(res.getBody()) : null;
            DocGenPreviewResponseCreator.asyncResponse docGenResponse = (DocGenPreviewResponseCreator.asyncResponse)JSON.deserialize( JSON.serialize(result), DocGenPreviewResponseCreator.asyncResponse.class);
            system.debug('docGenResponse  =>  '+docGenResponse);
            if(res.getStatusCode()  ==  200){
                // updateMergedDocument(loanId, docGenResponse.data.Id, JSON.serialize(result.get('data'))); //Commented out because no ID is returned in Async API call
                returnresp = 'Success'; 
            }
            else{
                returnresp = returnErrorMessage(res.getStatusCode());
            }
            Integration_Details__c rec = new Integration_Details__c();
            // rec = Utility.fillIntegrationRecord('Digio_docGenAPI', jsonstring.length() > 32100 ? jsonstring.substring(0, 32100):jsonstring, json.serialize(docGenResponse), string.ValueOf(res.getStatusCode()), 'POST', 'Callout:LOS_Digi_Doc_API', '', loanId, 'Digio_docGenAPI', '' ); 
            // insert rec;
            return returnresp; 
        } 
        catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage());
            LogAPIUtilityClass.logAPIcallouts(loanId, '', e.getMessage(), 'Digio_docGenAPI', null);
            return 'Failure';
        } 
    }
    
    @future(callout=true)
    public static void postDocGenAPISales (List<Id> docDetailsIDs, Id loanId){
        try{
            //List<Document_Details__c> ddc = [Select Id,Loan_Application__c,Document_Master__c from Document_Details__c where id IN:documentId];
           // List<id> docDetailsIDs = new List<id>();
           // docDetailsIDs.add(documentId);
            String docType = '';
            DocGenPreviewJSONCreator docGenPreviewRequestpayload  = DocGenPreviewRequestWrapper.createRequestPayload(docDetailsIDs, loanId, docType);
            string returnresp;
            HttpResponse res 				= 	DocGenerationRestUtility.generateDocumentAPI(JSON.serialize(docGenPreviewRequestpayload));
            
            string jsonstring               =   JSON.serialize(docGenPreviewRequestpayload);
            system.debug(JSON.serialize(docGenPreviewRequestpayload));
            System.debug('Serialized JSON => ' + jsonString);
            System.debug('res => ' + res);
            System.debug('Response body9866: ' + res.getBody());
            Map<String, Object> result 		= 	res.getStatusCode() != 502 ? (Map<String, Object>) JSON.deserializeUntyped(res.getBody()) : null;
            DocGenPreviewResponseCreator.syncResponse docGenResponse = (DocGenPreviewResponseCreator.syncResponse)JSON.deserialize( JSON.serialize(result), DocGenPreviewResponseCreator.syncResponse.class);
            if(res.getStatusCode()  ==  200){
                updateMergedDocumentSales(loanId, docGenResponse.data.Id, JSON.serialize(result.get('data')), true, true);
                returnresp = 'Success'; 
            }
            else{
                returnresp = returnErrorMessage(res.getStatusCode());
            }
            Integration_Details__c rec = new Integration_Details__c();
            //return returnresp; 
        
        } 
        catch(Exception e)
        {
            LogAPIUtilityClass.logAPIcallouts(loanId, '', e.getMessage(), 'Digio_docGenAPI', null);
            //return 'Failure';
        } 
    }

    @AuraEnabled
    public static string generateAppForm (List<Id> documentId, Id loanId){
        try{
            String docType = '';
            DocGenPreviewJSONCreator docGenPreviewRequestpayload  = DocGenPreviewRequestWrapper.createRequestPayload(documentId, loanId, docType);
            string returnresp;
            HttpResponse res 				= 	DocGenerationRestUtility.generateDocumentAPI(JSON.serialize(docGenPreviewRequestpayload));
            
            string jsonstring               =   JSON.serialize(docGenPreviewRequestpayload);
            // system.debug(JSON.serialize(docGenPreviewRequestpayload));
            System.debug('Serialized JSON => ' + jsonString);
            System.debug('res => ' + res);
            System.debug('Response body: ' + res.getBody());
            Map<String, Object> result 		= 	res.getStatusCode() != 502 ? (Map<String, Object>) JSON.deserializeUntyped(res.getBody()) : null;
            DocGenPreviewResponseCreator.syncResponse docGenResponse = (DocGenPreviewResponseCreator.syncResponse)JSON.deserialize( JSON.serialize(result), DocGenPreviewResponseCreator.syncResponse.class);
            if(res.getStatusCode()  ==  200){
                updateMergedDocumentSales(loanId, docGenResponse.data.Id, JSON.serialize(result.get('data')), true, false);
                returnresp = 'Success'; 
            }
            else{
                returnresp = returnErrorMessage(res.getStatusCode());
            }
            Integration_Details__c rec = new Integration_Details__c();
            return returnresp; 
        } 
        catch(Exception e)
        {
            LogAPIUtilityClass.logAPIcallouts(loanId, '', e.getMessage(), 'Digio_docGenAPI', null);
            return 'Failure';
        } 
    }
    
    public static void updateMergedDocumentSales(Id loanId, string responseId, string resultdata, Boolean isSales, Boolean sendEmail){
        getdocumentRecords(mergedDocument, templateDocument, eSignedDocument, loanId);
        if(mergedDocument.size() > 0){
            for(Document_Details__c dd : mergedDocument){
                dd.Active__c = false;
            }
            update mergedDocument;
        }
        createDocumentDetail(responseId, loanId, resultdata, 'Merged Document-Sales', isSales, sendEmail);
    }

    //3. initiateESign
    @AuraEnabled
    public static string initiateESignAPI (Id loanId){
        try{
        List<string> signedCo   = new List<string>();
        set<string> tmplateName = new set<string>();
        Map<string, string> contdocTypeToDocId          =   new  Map<string, string>();    
        Map<String, String> replacementMap = getTemplateReplacementMap();

        List<String> mergedTemplateName = new List<String>();
        List<String> updatedMergedTemplateName = new List<String>();

        getdocumentRecords(mergedDocument, templateDocument, eSignedDocument, loanId);
      
        for(Document_Details__c doc : templateDocument){
            if(doc.Name.contains('.')){
                tmplateName.add(doc.Name.split('\\.')[0]);
            }else{
                tmplateName.add(doc.Name);
            }
        }    

        system.debug('mergedDocument[0]   '+mergedDocument[0]);
        DocumentWrapper merDocdetails = (DocumentWrapper) JSON.deserialize(mergedDocument[0].Merged_Document_Detail__c, DocumentWrapper.class);
        system.debug('merDocdetails   '+merDocdetails);

        for(DocumentAndPageNumber item : merDocdetails.documentAndPageNumbers) { 
            system.debug('item.documentName  '+item.documentName);
            mergedTemplateName.add(item.documentName);        
        } 

        for (String templateName : mergedTemplateName) {
            system.debug('mergedTemplateName  templateName   '+templateName);
            Boolean replaced = false;

            for (String key : replacementMap.keySet()) {
                if (templateName.contains(key)) {
                    updatedMergedTemplateName.add(replacementMap.get(key));
                    replaced = true;
                    break;
                }
            }

            if (!replaced) {
                updatedMergedTemplateName.add(templateName);
            }
        }

        mergedTemplateName = updatedMergedTemplateName;
        
        system.debug('mergedTemplateName  '+mergedTemplateName);
        System.debug('tmplateName  '+tmplateName);
                                                               
        List<Signed_Coordinate__mdt> documentCoordinates    =   [SELECT Signed_Coordinates__c, DeveloperName
                                                                 FROM Signed_Coordinate__mdt 
                                                                 WHERE DeveloperName IN:mergedTemplateName];            //tmplateName                                        
        
        Map<String, Signed_Coordinate__mdt> metadataMap = new Map<String, Signed_Coordinate__mdt>();
        system.debug('documentCoordinates  '+documentCoordinates);

        for (Signed_Coordinate__mdt m : documentCoordinates) {
            system.debug('documentCoordinates template name '+m.DeveloperName);
            metadataMap.put(m.DeveloperName, m);
        }
        system.debug('metadataMap  '+metadataMap);

        List<Signed_Coordinate__mdt> signedCoordinateMetadata = new List<Signed_Coordinate__mdt>();

        for (String templateName : mergedTemplateName) {
            if (metadataMap.containsKey(templateName)) {
                signedCoordinateMetadata.add(metadataMap.get(templateName));
            }
        }
        DocGenESignJSONCreator docusignReq                  = 	DocGenEsignRequestWrapper.docusignRequest(loanId, mergedDocument);
        string docusignstring                               =   JSON.serialize(docusignReq);
        System.debug('docusignReq : '+docusignReq);                                           
        Map<String, Object> docusignstringmap               =   (Map<String, Object>) JSON.deserializeUntyped(docusignstring);
        string param = null;
        
        system.debug('signedCoordinateMetadata  '+signedCoordinateMetadata);
        /*********Append SignedCoordinates to the JSON start *************/
        List<String> jsonElements = new List<String>();

        /********* existing code comment start *************/

        // for(Signed_Coordinate__mdt signedCoordinate : signedCoordinateMetadata){
        //     system.debug('param  '+param);
        //     system.debug('signedCoordinate  '+signedCoordinate);
        //     param = param != null ? param +','+ signedCoordinate.Signed_Coordinates__c : signedCoordinate.Signed_Coordinates__c;
        //     jsonElements.add(signedCoordinate.Signed_Coordinates__c);
        //     system.debug('param after '+param);
        // }
        
        // String paramNew = '[' + String.join(jsonElements, ',') + ']';
        // System.debug('Final param: ' + paramNew);
        // // Map<String, Object> sCOMap = new Map<String, Object>();

        // List<Map<String, Object>> sCOListMaps = new List<Map<String, Object>>();
        // // Map<String, Object> sCOListMaps = new Map<String, Object>();
        // List<Object> sCOList = (List<Object>) JSON.deserializeUntyped(paramNew);

        // system.debug('param outside loop  '+param);
        // system.debug('sCOList  '+sCOList);

        // if (!String.isBlank(param)) {
        //     try {
        //         for (Object item : sCOList) {
        //             Map<String, Object> sCOMap = (Map<String, Object>) item;
        //             sCOListMaps.add(sCOMap);
        //             // for (String key : sCOMap.keySet()) {
        //             //     system.debug('sCOList key '+key);
        //             //     sCOListMaps.put(key, sCOMap.get(key));
        //             // }
        //         }
        //         System.debug('sCOListMaps : ' + JSON.serialize(sCOListMaps));
        //     } catch (Exception e) {
        //         System.debug('Error during JSON deserialization: ' + e.getMessage());
        //     }
        // } else {
        //     System.debug('No signed coordinates found');
        // }
        
        // docusignstringmap.put('signCoordinates', sCOListMaps);
        /********* existing code comment end *************/
        /*********Append SignedCoordinates to the JSON End *************/

        Map<String, Object> signCoordinates = new Map<String, Object>();
        Map<String, Integer> keyCounter = new Map<String, Integer>();

        for (Signed_Coordinate__mdt signedCoordinate : signedCoordinateMetadata) {

            System.debug('signedCoordinate ' + signedCoordinate);

            // Each Signed_Coordinates__c is a JSON object with 1 root key
            Map<String, Object> parsed =
                (Map<String, Object>) JSON.deserializeUntyped(
                    signedCoordinate.Signed_Coordinates__c
                );

            for (String originalKey : parsed.keySet()) {

                String finalKey = originalKey;

                if (signCoordinates.containsKey(originalKey)) {
                    Integer count = keyCounter.containsKey(originalKey)
                        ? keyCounter.get(originalKey) + 1
                        : 1;

                    keyCounter.put(originalKey, count);
                    finalKey = originalKey + '_' + count;
                } else {
                    keyCounter.put(originalKey, 0);
                }

                signCoordinates.put(finalKey, parsed.get(originalKey));
            }
        }

        System.debug('Final signCoordinates ' + JSON.serialize(signCoordinates));

        docusignstringmap.put('signCoordinates', signCoordinates);

        System.debug('JSON.serialize(docusignstringmap) : '+JSON.serialize(docusignstringmap));
        HttpResponse res                = 	DocGenerationRestUtility.generateESignDocumentAPI(JSON.serialize(docusignstringmap));
        System.debug('result 104 : '+res.getBody());
        Map<String, Object> result 		= 	res.getStatusCode() != 502 ? (Map<String, Object>) JSON.deserializeUntyped(res.getBody()) : null;
        LogAPIUtilityClass.logAPIcallouts(loanId, JSON.serialize(docusignstringmap), json.serialize(result), 'Digio_initiateEsign', res.getStatusCode()); 
        if(res.getStatusCode()  ==  200)
        {
            for(Document_Details__c dd : mergedDocument){
                dd.DID_Number__c = string.Valueof(result.get('data'));
            }
            update mergedDocument;
            return 'Success';
        }
        else{
            return result.get('message') != null ? string.Valueof(result.get('message')) : 'Invalid Response';  
        }
    }
        catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
            LogAPIUtilityClass.logAPIcallouts(loanId, '', e.getMessage(), 'Digio_initiateEsign', null);
            return 'Failure';
        } 
    }

    //4. CancelESign working
    @AuraEnabled
    public static string cancelESignedDocument (Id loanId){
        try{ 
        getdocumentRecords(mergedDocument, templateDocument, eSignedDocument, loanId);
        HttpResponse res 		        = 	DocGenerationRestUtility.cancelEsignAPI(mergedDocument[0].DID_Number__c);
        System.debug('res : 134 :'+res);
        System.debug('Response body: '+res.getBody());
        //HttpResponse res 		        = 	DocGenerationRestUtility.cancelEsignAPI('DID250203122639370ZU6IREYJAEZ71L');
        Map<String, Object> result 		= 	res.getStatusCode() != 502 ? (Map<String, Object>) JSON.deserializeUntyped(res.getBody()) : null;
        LogAPIUtilityClass.logAPIcallouts(loanId, mergedDocument[0].DID_Number__c, json.serialize(result), 'Digio_CancelESign', res.getStatusCode());   
        if(res.getStatusCode()  ==  200){
            return 'Success';
        }
        return 'Failure';
        }
        catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage());
            LogAPIUtilityClass.logAPIcallouts(loanId, '', e.getMessage(), 'Digio_CancelESign', null);
            return 'Failure';
        } 
    }

    //5. ESignStatuscheckAPI
    @AuraEnabled
    public static string getESignedDocumentStatus (Id loanId){
        try{
            getdocumentRecords(mergedDocument, templateDocument, eSignedDocument, loanId);
            DocGenESignStatusCheckJSONCreator docGenReq     = 	new DocGenESignStatusCheckJSONCreator(mergedDocument[0].DID_Number__c, mergedDocument[0].Loan_Application__r.Loan_Application_Number__c, true);
            HttpResponse res 		        = 	DocGenerationRestUtility.checkESignStatusAPI(JSON.serialize(docGenReq));
            Map<String, Object> result 		= 	res.getStatusCode() != 502 ? (Map<String, Object>) JSON.deserializeUntyped(res.getBody()) : null;
            LogAPIUtilityClass.logAPIcallouts(loanId, JSON.serialize(docGenReq), json.serialize(result), 'Digio_getESignedDocument', res.getStatusCode());
            if(res.getStatusCode()  ==  200){
                DocESignStatusCheckResponse merDocdetails = (DocESignStatusCheckResponse) JSON.deserialize(JSON.serialize(result), DocESignStatusCheckResponse.class);
                return merDocdetails.data.status;
            }
                return 'Failure';
        }
        catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage());
            LogAPIUtilityClass.logAPIcallouts(loanId, '', e.getMessage(), 'Digio_getESignedDocument', null);
            return 'Failure';
        }  
    }

     //6.DownloadEsignedDocAPI
    @Auraenabled
    public static string downLoadESignedDocument (Id loanId){
        try{
            getdocumentRecords(mergedDocument, templateDocument, eSignedDocument, loanId);
            system.debug('mergedDocument[0].DID_Number__c : '+mergedDocument[0].DID_Number__c);
            HttpResponse res 		        = 	DocGenerationRestUtility.downLoadDigiDocAPI(mergedDocument[0].DID_Number__c);
            Map<String, Object> result 		= 	res.getStatusCode() != 502 ? (Map<String, Object>) JSON.deserializeUntyped(res.getBody()) : null;
            LogAPIUtilityClass.logAPIcallouts(loanId, mergedDocument[0].DID_Number__c, json.serialize(result), 'Digio_DownloadESignedDoc', res.getStatusCode());
            if(res.getStatusCode()  ==  200){
                createDocumentDetail(string.ValueOf(result.get('data')), loanId, '', 'ESigned Document', false, false);
                return string.ValueOf(result.get('data'));
            }
            system.debug('res : 134 :'+res);
            system.debug('Response body: '+res.getBody());
             return 'Failure';
            
        }
        catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage());
            LogAPIUtilityClass.logAPIcallouts(loanId, '', e.getMessage(), 'Digio_DownloadESignedDoc', null);
            return 'Failure';
        }  
    }

    public static void updateMergedDocument(Id loanId, string responseId, string resultdata){
        getdocumentRecords(mergedDocument, templateDocument, eSignedDocument, loanId);
        if(mergedDocument.size() > 0){
            for(Document_Details__c dd : mergedDocument){
                dd.Active__c = false;
            }
            update mergedDocument;
        }
        createDocumentDetail(responseId, loanId, resultdata, 'Merged Document', false, false);
    }
    
    /*@future(callout=true)
    public static void Emailcallout(Id loanId){
        sendEmailToUsers.sendEmailToUsers(loanId);
    }*/
    

    public static void createDocumentDetail(String contentVerId, Id loanId, String mergedDocDetail, String documentType, Boolean isSales, Boolean sendEmail) {
        try {

            

            // Step 1: Get the ContentDocumentId
            ContentVersion cv1 = [SELECT ContentDocumentId, Title, FileType FROM ContentVersion WHERE Id = :contentVerId];
    
            // Step 2: Create ContentDocumentLink to share the document with the loanId record
            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = cv1.ContentDocumentId,
                LinkedEntityId = loanId,         // Assuming loanId is a valid SObject Id (Loan Application custom object)
                ShareType = 'V',                 // Viewer access (use 'C' for Collaborator, 'I' for Inferred)
                Visibility = 'AllUsers'          // Or 'InternalUsers', depending on visibility needs
            );
            insert cdl;
    
            // Step 3: Insert Document_Details__c custom object
            Document_Details__c docToInsert= new Document_Details__c(
                Content_Document_Id__c = cv1.ContentDocumentId,
                Merged_Document_Detail__c = mergedDocDetail,
                Esign_Document__c = !isSales,
                Status__c = 'Uploaded',
                Name = cv1.Title,
                Document_Type__c = documentType,
                Loan_Application__c = loanId,
                Uploaded_Date_Time__c = System.Now(),
                Consider_for_Loan_Application__c = true
            );
            insert docToInsert;

            Utility_V1.ProductWrapper prodWrapper = Utility_V1.getProductDetails(new Map<String,String>{'oppId' => loanId});
            if(prodWrapper.isHLRelated){
                List<Document_Details__c> docList = [SELECT Id, Consider_for_Loan_Application__c FROM Document_Details__c WHERE Loan_Application__c= :loanId AND Document_Type__c = :documentType AND Id != :docToInsert.id];
                if(docList.size()>0){
                    for(Document_Details__c doc: docList){
                        doc.Consider_for_Loan_Application__c = false;
                    }
                    update docList;
                }
            }
            
            if(sendEmail){
                System.enqueueJob(new QueueableLogicForSendEmail(loanId));
                // sendEmailToUsers.sendEmailToUsers(loanId);
            }

            
        } catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }
    

    public static string returnErrorMessage(Integer errorCode)
    {
        for(API_Exceptions__mdt exceptionCode: API_Exceptions__mdt.getAll().values()){
            if(exceptionCode.Error_Code__c == string.ValueOf(errorCode)){
                return ('Error:' + exceptionCode.Error_Message__c);
             }
        }
        return null;
    }

    public static void getdocumentRecords(List<Document_Details__c> mergedDocument, List<Document_Details__c> templateDocument, List<Document_Details__c> eSignedDocument, Id loanId)
    {
        List<Document_Details__c> doc = [select Id, Active__c, DID_Number__c, Document_Type__c,Name, 
                                        Content_Document_Id__c, Loan_Application__r.Loan_Application_Number__c, 
                                        Merged_Document_Detail__c
                                        from Document_Details__c 
                                        where Loan_Application__c =: loanId and Active__c = true and Esign_Document__c = true ORDER BY CreatedDate DESC];
                                
        for(Document_Details__c docDetail : doc){
            
            switch on docDetail.Document_Type__c {
                when 'Merged Document' {
                    mergedDocument.add(docDetail);
                }
                when 'Template Document' {
                    templateDocument.add(docDetail);
                }
                when 'ESigned Document' {
                    eSignedDocument.add(docDetail);
                }
            }
        }
    }
    @AuraEnabled
    public static Boolean checkOpportunity(String loanId) {
        // Query for OpportunityTeamMember with matching User and Role
        List<OpportunityTeamMember> otm = [
            SELECT Id, Name, User.Name, UserId, Opportunity.Id 
            FROM OpportunityTeamMember 
            WHERE UserId = :UserInfo.getUserId() 
            AND (TeamMemberRole = 'OPS Maker' OR (TeamMemberRole = 'Credit Officer' AND User.Is_OPS_Also__c = true))
            AND Opportunity.Id = :loanId AND Associated_With_Loan_Application__c = true
        ];

        if (!otm.isEmpty()) {
            return true;
        } else {
            // Check if current user's profile is 'System Administrator'
            User currentUser = [
                SELECT Id, Name, Profile.Name 
                FROM User 
                WHERE Id = :UserInfo.getUserId() 
                LIMIT 1
            ];

            return currentUser.Profile.Name == 'System Administrator';
            // return false;
        }
    }
    @AuraEnabled
    public static Decimal getselectedDocId(String docId) {
        Document_Details__c dd = [Select DocGen_Sequence__c from Document_Details__c where Id =: docId];
        return dd.DocGen_Sequence__c;
    }   
    @AuraEnabled
    public static void  saveEsignSequence(String recordId,Decimal sequence){
        try {
            Document_Details__c docDetails = new Document_Details__c();
            docDetails.Id = recordId;
            docDetails.DocGen_Sequence__c = sequence;
            Update docDetails;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static Boolean checkOtherDoc(String recordId,Decimal sequence){
        try {
            List<Document_Details__c> dd = [Select Id,name from Document_Details__c where  Esign_Document__c = true and Document_Type__c != 'Merged Document' and Document_Type__c != 'ESigned Document' and DocGen_Sequence__c=:sequence and Loan_Application__c =:recordId];
            if(dd.isEmpty()){
                return true;
            }
            else{
                return false;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static string fetchAuthorizedSignatory(String loanId){
        try {
            Opportunity op = [Select Id,Authorized_Signatory__c from Opportunity where Id=:loanId];
            return op.Authorized_Signatory__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static OppurtunityDetailWrapper opportunityDetails(String loanId){
        try {
        List<Opportunity> op = [Select Id,name,Authorized_Signatory__c,E_seal_Colour__c, 
        E_seal_Generated__c,E_seal_Inner_Name__c,E_Seal_Outer_Name__c,E_seal_Shape__c from Opportunity where Id=:loanId];
            OppurtunityDetailWrapper opw = new OppurtunityDetailWrapper();
            if(!op.isEmpty()){
            opw.esealgenerated = op[0].E_seal_Generated__c;
            opw.selectedColour = op[0].E_seal_Colour__c;
            opw.selectedShape = op[0].E_seal_Shape__c;
            opw.innerName = op[0].E_seal_Inner_Name__c;
            opw.outerName = op[0].E_Seal_Outer_Name__c;
            opw.authsign = op[0].Authorized_Signatory__c;
            List<Application_Applicant__c> ap = [Select Id,Customer_Type__c from Application_Applicant__c where Loan_Application__c = :loanId AND Applicant_Type__c = 'Primary Applicant' and Customer_Type__c='Non Individual' LIMIT 1];
            if(!ap.isEmpty()){
                opw.isRequired = true;
            }
            else{
                opw.isRequired = false;
            }
            }
            return opw;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static esealDocDetails fetchNewEseal(String loanId){
        try {
        String contentDocId;
        List<Document_Details__c> dd = [SELECT Id,Content_Document_Id__c FROM Document_Details__c WHERE Name = 'Eseal' AND Loan_Application__c = :loanId AND Active__c = true ORDER BY CreatedDate DESC LIMIT 1];
        esealDocDetails es = new esealDocDetails();
            if (!dd.isEmpty()) {
                es.contentDocId = dd[0].Content_Document_Id__c;
                es.docId = dd[0].Id;
            } else {
                es.contentDocId = null; // or handle no record found case
                es.docId = null;
            }
            return es;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class esealDocDetails{
        @AuraEnabled public String contentDocId;
        @AuraEnabled public String docId;
    }
    public class OppurtunityDetailWrapper{
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public Boolean esealgenerated;
        @AuraEnabled public String selectedColour;
        @AuraEnabled public String selectedShape;
        @AuraEnabled public String innerName;
        @AuraEnabled public String outerName;
        @AuraEnabled public String authsign;
    }

    @AuraEnabled(cacheable=true)
    public static List<Document_Master__c> getNonManDocuments(String filterValue) {
        return [
            SELECT Id, Name
            FROM Document_Master__c
            WHERE Document_Type__c = :filterValue
        ];
    }

    @AuraEnabled
    public static void createNonManDocumentDetails(List<Id> selectedDocMasterIds, Id loanId) {
        List<Document_Master__c> masters = [
            SELECT Id, Name, Document_Name__c
            FROM Document_Master__c
            WHERE Id IN :selectedDocMasterIds
        ];

        Map<String, String> nameandMasterId = new Map<String, String>();

        for (Document_Master__c docMaster : masters) {
            nameandMasterId.put(docMaster.Id, docMaster.Document_Name__c);
        }

        Map<String, String> contentIdandMaster = new Map<String, String>();

        if (!selectedDocMasterIds.isEmpty()) {
            List<ContentDocumentLink> cdl = [
                SELECT ContentDocumentId, LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :selectedDocMasterIds
            ];
            system.debug('cdl  '+cdl);
            if (!cdl.isEmpty()) {
                for (ContentDocumentLink cd : cdl) {
                    contentIdandMaster.put(cd.ContentDocumentId, cd.LinkedEntityId);
                }
            }
            system.debug('contentIdandMaster  '+contentIdandMaster);
        }

        List<String> compKey = new List<String>();

        List<Document_Details__c> ddc = [Select Id,Loan_Application__c,Document_Master__c from Document_Details__c where Loan_Application__c =: loanId and Esign_Document__c = true ];
        if(!ddc.isEmpty()){
           for(Document_Details__c fd : ddc){
            compKey.add(fd.Loan_Application__c+'-'+fd.Document_Master__c);
           }
        }

        List<Document_Details__c> docDetailsToInsert = new List<Document_Details__c>();

        for (String contentDocId : contentIdandMaster.keySet()) {
            String docMasterId = contentIdandMaster.get(contentDocId);
            System.debug('docMasterId ' + docMasterId);
            String searchkey = loanId+'-'+docMasterId;
            if (compKey.contains(searchkey)) {
                System.debug('Doc Present');
            }
            else{
                String docMasterName = nameandMasterId.get(contentIdandMaster.get(contentDocId));
                System.debug('docMasterName ' + docMasterName);
                Document_Details__c newDocDetail = new Document_Details__c(
                    Name = docMasterName,
                    Loan_Application__c = loanId, 
                    Document_Master__c = docMasterId, 
                    Active__c = true, 
                    Status__c = 'Uploaded',
                    Esign_Document__c = true,
                    Is_Required__c = false,
                    Content_Document_Id__c = contentDocId, 
                    Document_Type__c = 'Template Document',
                    Description__c = 'Non Mandatory Template Document'
                );
                docDetailsToInsert.add(newDocDetail);
            }
        }

        if (!docDetailsToInsert.isEmpty()) {
            insert docDetailsToInsert;
        }
    }

    @AuraEnabled
    public static Boolean checkLatestDoc(Id loanId) {
        Boolean isLatestDoc = false;
        if (loanId == null) {
            return false;
        }

        Opportunity opp = [
            SELECT Id, DocGen_Initiated_Time__c
            FROM Opportunity
            WHERE Id = :loanId
            LIMIT 1
        ];

        if (opp.DocGen_Initiated_Time__c == null) {
            return false; 
        }

        Document_Details__c latestDoc = [
            SELECT Id, Uploaded_Date_Time__c, CreatedDate
            FROM Document_Details__c
            WHERE Loan_Application__c = :loanId AND Document_Type__c = 'Merged Document'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (latestDoc.Uploaded_Date_Time__c != null && latestDoc.Uploaded_Date_Time__c > opp.DocGen_Initiated_Time__c) {
            isLatestDoc = true;
        }
        system.debug('isLatestDoc  '+isLatestDoc);
        return isLatestDoc;
    }

    public class DocumentWrapper {
        public List<DocumentAndPageNumber> documentAndPageNumbers;
        public String id;
    }

    public class DocumentAndPageNumber {
        public String pageNumbers;
        public String documentName;
    }

    private static Map<String, String> getTemplateReplacementMap() {
        return new Map<String, String>{
            'APP_FORM_GHF_MORTGAGE'       => 'APP_FORM_GHF_MORTGAGE_APP_FORM_APR25'
        };
    }
    
}