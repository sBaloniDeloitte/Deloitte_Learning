@RestResource(urlMapping='/api/AccountAggregatorCallback')
global with sharing class AccountAggregatorAPI_REST {
    static String conLabels = 'Account_Aggregator_Response';
    public static Map<String, String> constants = Utility.getConstants(conLabels);

    @AuraEnabled
    public static Map<String, String> getConstants() {
        return constants;
    }

    @HttpPost
    global static void getAccountAggregatorStatus() {
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            RestRequest restReq = RestContext.request;
            String requestBody  = restReq.requestBody.toString();
            System.debug('requestBody16--' + requestBody);

            Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            String eventType = (String) parsedJson.get('eventType');

            if (eventType == 'CONSENT') {
                AccountAggregtorConsentCallbackWrapper consentResponse =
                    (AccountAggregtorConsentCallbackWrapper) JSON.deserialize(requestBody, AccountAggregtorConsentCallbackWrapper.class);
                handleConsentEvent(consentResponse);

            } else if (eventType == 'FI_DATA' || eventType == 'DATA') {
                AccountAggregatorResponseServiceWrapper accResp =
                    (AccountAggregatorResponseServiceWrapper) JSON.deserialize(requestBody, AccountAggregatorResponseServiceWrapper.class);
                handleFiDataEvent(accResp);

            } else if (eventType == 'FI_STATUS') {
                AccountAggregatorFiStatusWrapper fiStatusResp =
                    (AccountAggregatorFiStatusWrapper) JSON.deserialize(requestBody, AccountAggregatorFiStatusWrapper.class);
                handleFiStatusEvent(fiStatusResp);

            } else {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                    'success' => false,
                    'error'   => 'Unknown eventType: ' + eventType
                }));
                return;
            }

            res.statusCode   = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'success' => true,
                'message' => 'Event processed successfully'
            }));

        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' | Line: ' + e.getLineNumber() + ' | Stack: ' + e.getStackTraceString());
            res.statusCode   = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'success'    => false,
                'error'      => e.getMessage(),
                'lineNumber' => e.getLineNumber(),
                'stackTrace' => e.getStackTraceString()
            }));
        }
    }

    private static void handleFiStatusEvent(AccountAggregatorFiStatusWrapper fiStatusResp) {
        System.debug('Processing FI_STATUS event: ' + JSON.serialize(fiStatusResp));

        if (fiStatusResp.data == null) {
            throw new AuraHandledException('FI_STATUS: data is null in payload.');
        }

        String consentHandle = fiStatusResp.consentHandle;
        if (String.isBlank(consentHandle)) {
            throw new AuraHandledException('FI_STATUS: consentHandle is blank in payload.');
        }

        System.debug('linkRefNumber: '  + fiStatusResp.data.linkRefNumber);
        System.debug('fiStatus: '       + fiStatusResp.data.fiStatus);
        System.debug('maskedAccount: '  + fiStatusResp.data.maskedAccountNumber);
        System.debug('fipName: '        + fiStatusResp.data.fipName);

        List<Document_Details__c> existingList = [
            SELECT Id, Account_Aggregator_Status__c, Linked_Reference__c,
                   Bank_Name__c, Masked_Account_Number__c, Transaction_ID__c,
                   Loan_Application__c, Applicant__c
            FROM Document_Details__c
            WHERE Transaction_ID__c = :consentHandle
        ];

        Map<String, Document_Details__c> linkRefToExistingMap = new Map<String, Document_Details__c>();
        Id sourceLoanApplicationId = null;
        Id sourceApplicantId       = null;

        for (Document_Details__c rec : existingList) {
            if (String.isNotBlank(rec.Linked_Reference__c)) {
                linkRefToExistingMap.put(rec.Linked_Reference__c.toLowerCase(), rec);
            }
            if (sourceLoanApplicationId == null && rec.Loan_Application__c != null) {
                sourceLoanApplicationId = rec.Loan_Application__c;
            }
            if (sourceApplicantId == null && rec.Applicant__c != null) {
                sourceApplicantId = rec.Applicant__c;
            }
        }

        String normalisedStatus = normaliseStatus(fiStatusResp.data.fiStatus);
        String linkRefKey = String.isNotBlank(fiStatusResp.data.linkRefNumber)
            ? fiStatusResp.data.linkRefNumber.toLowerCase()
            : null;

        if (linkRefKey != null && linkRefToExistingMap.containsKey(linkRefKey)) {
            Document_Details__c existing = linkRefToExistingMap.get(linkRefKey);
            existing.Account_Aggregator_Status__c = normalisedStatus;
            update existing;
            System.debug('FI_STATUS: updated record ' + existing.Id + ' with status: ' + normalisedStatus);

        } else {
            Document_Details__c newDoc          = new Document_Details__c();
            newDoc.Transaction_ID__c            = consentHandle;
            newDoc.Linked_Reference__c          = fiStatusResp.data.linkRefNumber;
            newDoc.Masked_Account_Number__c     = fiStatusResp.data.maskedAccountNumber;
            newDoc.Bank_Name__c                 = fiStatusResp.data.fipName;
            newDoc.Account_Aggregator_Status__c = normalisedStatus;
            newDoc.Manual_AA__c                 = 'AA';
            newDoc.Process_Name__c              = 'Income Bank Statement';
            newDoc.Name                         = '12 months bank statement';
            newDoc.Loan_Application__c          = sourceLoanApplicationId;
            newDoc.Applicant__c                 = sourceApplicantId;
            insert newDoc;
            System.debug('FI_STATUS: inserted new record ' + newDoc.Id + ' for linkRef: ' + fiStatusResp.data.linkRefNumber);
        }
    }

    private static void handleConsentEvent(AccountAggregtorConsentCallbackWrapper consentResp) {
        System.debug('Processing CONSENT event: ' + JSON.serialize(consentResp));

        if (consentResp.data == null) {
            throw new AuraHandledException('CONSENT: data payload is null.');
        }

        String eventStatus   = consentResp.data.eventStatus;
        String consentHandle = consentResp.data.consentHandle;

        System.debug('consentResp.data.eventStatus: ' + eventStatus);

        if (String.isBlank(eventStatus)) {
            throw new AuraHandledException('CONSENT: eventStatus is blank in payload.');
        }
        if (String.isBlank(consentHandle)) {
            throw new AuraHandledException('CONSENT: consentHandle is blank in payload.');
        }

        List<Document_Details__c> ddList = [
            SELECT Id, Account_Aggregator_Status__c, Transaction_ID__c,
                   Loan_Application__c, Applicant__c
            FROM Document_Details__c
            WHERE Transaction_ID__c = :consentHandle
        ];

        if (!ddList.isEmpty()) {
            List<Document_Details__c> toUpdate = new List<Document_Details__c>();
            for (Document_Details__c rec : ddList) {
                rec.Account_Aggregator_Status__c = eventStatus;
                toUpdate.add(rec);
            }
            update toUpdate;
            System.debug('CONSENT: updated ' + toUpdate.size() + ' record(s) with status: ' + eventStatus);

        } else {
            Id sourceLoanApplicationId = null;
            Id sourceApplicantId       = null;

            List<Document_Details__c> sourceList = [
                SELECT Loan_Application__c, Applicant__c
                FROM Document_Details__c
                WHERE Transaction_ID__c = :consentHandle
                AND Loan_Application__c != null
                LIMIT 1
            ];

            if (!sourceList.isEmpty()) {
                sourceLoanApplicationId = sourceList[0].Loan_Application__c;
                sourceApplicantId       = sourceList[0].Applicant__c;
            }

            Document_Details__c newDoc         = new Document_Details__c();
            newDoc.Transaction_ID__c            = consentHandle;
            newDoc.Account_Aggregator_Status__c = eventStatus;
            newDoc.Manual_AA__c                 = 'AA';
            newDoc.Process_Name__c              = 'Income Bank Statement';
            newDoc.Name                         = '12 months bank statement';
            newDoc.Loan_Application__c          = sourceLoanApplicationId;
            newDoc.Applicant__c                 = sourceApplicantId;
            insert newDoc;
            System.debug('CONSENT: inserted new placeholder record for consentHandle: ' + consentHandle);
        }
    }

    private static void handleFiDataEvent(AccountAggregatorResponseServiceWrapper accResp) {
        List<Document_Master__c> docMasterList = [
            SELECT Id, Name, Document_Name__c
            FROM Document_Master__c
            WHERE Document_Name__c = :constants.get('Account_Aggregator_Response')
        ];

        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title         = 'AccountAggregatorResponse';
        contentVersion.PathOnClient  = 'AccountAggregatorResponse.txt';
        contentVersion.VersionData   = Blob.valueOf(JSON.serialize(accResp));
        insert contentVersion;

        ContentVersion contentVersionId = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :contentVersion.Id
            LIMIT 1
        ];

        Document_Details__c dd = new Document_Details__c();
        dd.Content_Document_Id__c = contentVersionId.ContentDocumentId;
        dd.Name                   = 'AccountAggregatorResponse';
        dd.Document_Master__c     = docMasterList[0].Id;
        // insert dd;

        ContentVersion cv = new ContentVersion();
        cv.Title          = '12 months bank statement';
        cv.PathOnClient   = '12monthsbankstatement.pdf';
        cv.VersionData    = EncodingUtil.base64Decode(accResp.data.fiPdfByteData);
        cv.IsMajorVersion = true;
        insert cv;

        Date startDate;
        Date endDate;

        ContentVersion xmlContent = new ContentVersion();
        xmlContent.Title          = 'AccountAggregatorXML';
        xmlContent.PathOnClient   = 'AccountAggregatorData.xml';
        xmlContent.VersionData    = Blob.valueOf(accResp.data.fiXmlData[0].xmlData);
        xmlContent.IsMajorVersion = true;
        // insert xmlContent;

        System.debug('accResp.consentHandle--' + accResp.consentHandle);

        ContentVersion cvRec = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];

        List<Document_Details__c> ddList = [
            SELECT Id, Applicant__c, Linked_Reference__c, Loan_Application__c
            FROM Document_Details__c
            WHERE Transaction_ID__c = :accResp.consentHandle
        ];

        Map<String, Document_Details__c> linkRefToDocMap = new Map<String, Document_Details__c>();
        for (Document_Details__c rec : ddList) {
            if (String.isNotBlank(rec.Linked_Reference__c)) {
                linkRefToDocMap.put(rec.Linked_Reference__c.toLowerCase(), rec);
            }
        }

        String jsonData  = XmlToJSONParser.XMLToJSON(accResp.data.fiXmlData[0].xmlData);
        String bankName  = accResp.data.fiXmlData[0].fipName.toLowerCase();

        List<Bank_Branch_Master__c> bankMasterList = [
            SELECT Id, Bank_Name__c, Institution_Id__c
            FROM Bank_Branch_Master__c
            WHERE Bank_Name__c LIKE :('%' + bankName + '%')
        ];

        System.debug('jsonData: ' + jsonData);
        System.debug('bankName: ' + bankName);

        jsonData = jsonData.replaceAll('[\\x00-\\x1F]', ' ');
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonData);

        if (jsonMap.containsKey('Account')) {
            Map<String, Object> accountMap = (Map<String, Object>) jsonMap.get('Account');
            System.debug('accountMap: ' + accountMap);

            if (accountMap.containsKey('startDate') && accountMap.containsKey('endDate')) {
                System.debug('Found startDate and endDate directly in accountMap');
                String startDateStr = (String) accountMap.get('startDate');
                String endDateStr   = (String) accountMap.get('endDate');
                startDate = Date.valueOf(startDateStr);
                endDate   = Date.valueOf(endDateStr);
            } else {
                System.debug('startDate and/or endDate not found directly in accountMap');
            }
        }

        System.debug('100:');

        String incomingLinkRef = accResp.data.fiXmlData[0].linkRefNumber;
        Document_Details__c documentChecklist = null;

        if (String.isNotBlank(incomingLinkRef) && linkRefToDocMap.containsKey(incomingLinkRef.toLowerCase())) {
            documentChecklist = linkRefToDocMap.get(incomingLinkRef.toLowerCase());
        } else if (!ddList.isEmpty()) {
            documentChecklist = ddList[0];
        }

        if (documentChecklist != null) {
            System.debug('105--');
            documentChecklist.Account_Aggregator_Status__c = 'Successful';
            documentChecklist.Content_Document_Id__c       = cvRec.ContentDocumentId;
            documentChecklist.Status__c                    = 'Uploaded';
            documentChecklist.Manual_AA__c                 = 'AA';
            documentChecklist.Institution_Id__c            = !bankMasterList.isEmpty() ? bankMasterList[0].Institution_Id__c : null;
            documentChecklist.Year_Month_From__c           = startDate;
            documentChecklist.Year_Month_To__c             = endDate;
            documentChecklist.Process_Name__c              = 'Income Bank Statement';
            // update documentChecklist;

            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId    = documentChecklist.Id;
            cdl.ContentDocumentId = cvRec.ContentDocumentId;
            cdl.ShareType         = 'V';
            cdl.Visibility        = 'AllUsers';
            // insert cdl;
        }
    }

    private static String normaliseStatus(String rawStatus) {
        if (String.isBlank(rawStatus)) return rawStatus;
        String s = rawStatus.toUpperCase().trim();
        if (s == 'TIMEOUT')   return 'Timeout';
        if (s == 'READY')     return 'Ready';
        if (s == 'FAILED')    return 'Failed';
        if (s == 'DELIVERED') return 'Delivered';
        if (s == 'PENDING')   return 'Pending';
        return rawStatus;
    }

    // ─── Wrapper: FI_STATUS ───────────────────────────────────────────────────────
    public class AccountAggregatorFiStatusWrapper {
        public String           status;
        public String           consentHandle;
        public String           traceId;
        public String           eventType;
        public cls_fiStatusData data;
    }

    public class cls_fiStatusData {
        public String linkRefNumber;
        public String fiStatus;
        public String maskedAccountNumber;
        public String fipName;
    }

    // ─── Wrapper: FI_DATA ─────────────────────────────────────────────────────────
    public class AccountAggregatorResponseServiceWrapper {
        public String   status;
        public String   consentHandle;
        public String   eventType;
        public cls_data data;
    }

    public class cls_data {
        public cls_fiXmlData[] fiXmlData;
        public String          fiPdfByteData;
    }

    public class cls_fiXmlData {
        public String linkRefNumber;
        public String maskedAccNumber;
        public String xmlData;
        public String fipId;
        public String fipName;
    }

    // ─── Wrapper: CONSENT ─────────────────────────────────────────────────────────
    public class AccountAggregtorConsentCallbackWrapper {
        public String          status;
        public String          consentHandle;
        public String          eventType;
        public cls_consentData data;
    }

    public class cls_consentData {
        public String             timestamp;
        public String             consentHandle;
        public String             eventType;
        public String             eventStatus;
        public String             consentId;
        public String             eventMessage;
        public cls_linkRefNumbers linkRefNumbers;
    }

    public class cls_linkRefNumbers {
    }
}