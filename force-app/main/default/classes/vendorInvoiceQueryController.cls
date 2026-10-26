public without sharing class vendorInvoiceQueryController {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getQueryType(){
        try {
            Id currentUserId = UserInfo.getUserId();
            String profileName = [SELECT Profile.Name FROM User WHERE Id = :currentUserId].Profile.Name;
            List<Vendor_Invoice_Query_Data__mdt> queryData = [SELECT Query_Type__c FROM Vendor_Invoice_Query_Data__mdt WHERE User_Profile__c =: profileName];
            List<Map<String, String>> options = new List<Map<String, String>>();

            if (!queryData.isEmpty()) {
                for (Vendor_Invoice_Query_Data__mdt mdt : queryData) {
                    if (String.isNotBlank(mdt.Query_Type__c)) {
                        options.add(new Map<String, String>{
                            'label' => mdt.Query_Type__c,
                            'value' => mdt.Query_Type__c
                        });
                    }
                }
            }
            return options;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getQueryAsignee() {
        try {
            Id currentUserId = UserInfo.getUserId();
            String profileName = [SELECT Profile.Name FROM User WHERE Id = :currentUserId].Profile.Name;
            List<Vendor_Invoice_Query_Data__mdt> queryData = [SELECT Asignee_Profile__c FROM Vendor_Invoice_Query_Data__mdt WHERE User_Profile__c = :profileName];
            Set<String> uniqueAsigneeProfiles = new Set<String>();
            if (!queryData.isEmpty()) {
                for (Vendor_Invoice_Query_Data__mdt mdt : queryData) {
                    if (String.isNotBlank(mdt.Asignee_Profile__c)) {
                        uniqueAsigneeProfiles.add(mdt.Asignee_Profile__c);
                    }
                }
            }
            List<Map<String, String>> options = new List<Map<String, String>>();
            if (!uniqueAsigneeProfiles.isEmpty()) {
                for (String profile : uniqueAsigneeProfiles) {
                    options.add(new Map<String, String>{
                        'label' => profile,
                        'value' => profile
                    });
                }
            }
            return options;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getCurrentUserDetails(){
        List<string> result = new List<string>();
        result.add([Select Name From Profile Where Id =: UserInfo.getProfileId()].Name);
        result.add(UserInfo.getName());
        return result;
    }

    @AuraEnabled
    public static void saveQueries(String payoutRecordsJson) {
        List<String> usrDetails = getCurrentUserDetails();
        Object raw = JSON.deserializeUntyped(payoutRecordsJson);
        if (!(raw instanceof List<Object>)) {
            throw new AuraHandledException('Invalid JSON payload');
        }

        String remarksHeader = usrDetails[1] + ' (' + usrDetails[0] + ') - ' + Datetime.NOW().format('dd/MM/YYYY, hh:mm a') + ':';
        List<Object> rawList = (List<Object>) raw;
        System.debug('remarksHeader :'+remarksHeader);
        Set<String> loanNumbers = new Set<String>();
        Set<Id> vendorInvoiceIds = new Set<Id>();

        for (Object obj : rawList) {
            Map<String, Object> r = (Map<String, Object>) obj;
            loanNumbers.add((String) r.get('loanApplicationNo'));
            vendorInvoiceIds.add((String) r.get('recordId'));
        }

        Map<String, Opportunity> loanAppMap = new Map<String, Opportunity>();
        for (Opportunity la : [SELECT Id, Name, Lead__r.Dsa_Area_Manager__c FROM Opportunity WHERE Name IN :loanNumbers]) {
            loanAppMap.put(la.Name, la);
        }

        Map<Id, Vendor_Invoice__c> vendorInvoiceMap = new Map<Id, Vendor_Invoice__c>();
        for (Vendor_Invoice__c vi : [SELECT Id, DSA__c, Payout_Manager__c FROM Vendor_Invoice__c WHERE Id IN :vendorInvoiceIds]) {
            vendorInvoiceMap.put(vi.Id, vi);
        }

        Map<String, String> viToContentVersionMap = new Map<String, String>();

        List<Query__c> queries = new List<Query__c>();

        for (Object obj : rawList) {
            Map<String, Object> r = (Map<String, Object>) obj;

            Query__c q = new Query__c();
            q.Vendor_Invoice_Id__c = (String) r.get('recordId');

            String loanNo = (String) r.get('loanApplicationNo');
            String assignee = (String) r.get('assigneeValue');
            Opportunity loanApp = loanAppMap.get(loanNo);

            if (loanApp != null) {
                q.Loan_Application__c = loanApp.Id;
                q.Loan_No__c = loanApp.Name;
            }
            Vendor_Invoice__c vi = vendorInvoiceMap.get((Id) r.get('recordId'));
            System.debug('assignee : '+assignee);
            System.debug('vi.Payout_Manager__c : '+vi.Payout_Manager__c);
            System.debug('vi.DSA__c : '+vi.DSA__c);
            if (assignee == 'Sales') { // && loanApp?.Lead__r?.Dsa_Area_Manager__c != null            
                q.Responder__c = vi.Payout_Manager__c;
            } else if (assignee == 'Partner Community User') {
                if (vi != null && vi.DSA__c != null) {
                    // q.Responder__c = vi.DSA__c;
                    System.debug('vi.DSA__c : '+vi.DSA__c);
                    List<User> userList = [SELECT Id, Name FROM User WHERE AccountId =:vi.DSA__c 
                                            AND Profile.Name = 'Partner Community User' LIMIT 1];
                    System.debug('userList : '+userList);
                    // System.debug('userList[0].Id : '+userList[0].Id);')
                    if(!userList.isEmpty()){
                        q.Responder__c = userList[0].Id;
                    }
                }
            }

            List<Object> queryTypesRaw = (List<Object>) r.get('queryTypeValues');
            List<String> queryTypes = new List<String>();
            for (Object qt : queryTypesRaw) {
                queryTypes.add((String) qt);
            }

            q.Vendor_Invoice_Query_Type__c = String.join(queryTypes, '; ');
            q.Requestor__c = UserInfo.getUserId();
            q.Assigned_To_Profile__c = assignee;
            q.Remarks__c = 'Assigned - ' + remarksHeader + (String) r.get('queryRemarks');
            q.Status__c = 'Assigned';

            if (r.containsKey('contentVersion')) {
                viToContentVersionMap.put(q.Vendor_Invoice_Id__c, (String) r.get('contentVersion'));
            }

            queries.add(q);
        }

        insert queries;

        List<Document_Details__c> docsToInsert = new List<Document_Details__c>();
        Map<Id, Id> queryToDocDetailsMap = new Map<Id, Id>();

        for (Query__c q : queries) {
            String contentVersionId = viToContentVersionMap.get(q.Vendor_Invoice_Id__c);
            System.debug('contentVersionId : ' + contentVersionId);
            if (contentVersionId != null && !String.isBlank(contentVersionId)) {
                List<ContentVersion> cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];
                if(!cv.isEmpty()) {
                    Document_Details__c doc = new Document_Details__c();
                    doc.Name = 'Query ' + q.Name;
                    doc.Query__c = q.Id;
                    doc.Content_Document_Id__c = cv[0].ContentDocumentId;
                    docsToInsert.add(doc);
                }
            }
        }

        if (!docsToInsert.isEmpty()) {
            insert docsToInsert;

            Integer idx = 0;
            for (Query__c q : queries) {
                if (idx < docsToInsert.size()) {
                    q.Document_Details__c = docsToInsert[idx].Id;
                    idx++;
                }
            }
            update queries;

            List<ContentDocumentLink> docLinks = new List<ContentDocumentLink>();

            for (Document_Details__c doc : docsToInsert) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = doc.Content_Document_Id__c;
                cdl.LinkedEntityId = doc.Id; 
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                docLinks.add(cdl);
            }
            insert docLinks;
        }
    }


    @AuraEnabled
    public static List<QueryWrapper> getQueryRecords(String fromDate, String toDate, String status, String payout, String queryRec) {
        System.debug('fromDate: ' + fromDate);
        System.debug('toDate: ' + toDate);
        System.debug('status: ' + status);
        System.debug('queryRec: ' + queryRec);
        System.debug('payout: ' + payout);

        Id uid = UserInfo.getUserId();
        String profileName = [SELECT Profile.Name FROM User WHERE Id = :uid].Profile.Name;
        System.debug('uid : '+uid);
        Map<String, Object> bindVars = new Map<String, Object>();
        bindVars.put('uid', uid);
        bindVars.put('profileName', profileName);
        String query;
        if (profileName != 'GC Product Team' && profileName != 'GC Finance Team') {
            query = 
            'SELECT Id, Name, Loan_No__c, Requestor__c, Requestor__r.Name, Remarks__c, Status__c, Vendor_Invoice_Id__c, ' +
            'Vendor_Invoice_Id__r.Name, Responder__c, Document_Details__c, Document_Details__r.Content_Document_Id__c, Document_Details__r.Name, CreatedById ' +
            'FROM Query__c WHERE (Responder__c = :uid OR CreatedById = :uid) AND Vendor_Invoice_Id__c != null ';
        } else {
            query = 
            'SELECT Id, Name, Loan_No__c, Requestor__c, Requestor__r.Name, Remarks__c, Status__c, Vendor_Invoice_Id__c, ' +
            'Vendor_Invoice_Id__r.Name, Responder__c, Document_Details__c, Document_Details__r.Content_Document_Id__c, Document_Details__r.Name, CreatedById ' +
            'FROM Query__c WHERE Assigned_To_Profile__c =: profileName AND Vendor_Invoice_Id__c != null ';
        }
        

        query += buildFilterQuery(fromDate, toDate, status, payout, queryRec, bindVars);

        System.debug('Final Query: ' + query);

        List<QueryWrapper> result = new List<QueryWrapper>();

        for (SObject rec : Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE)) {
            System.debug('rec in for: '+rec);
            QueryWrapper wrapper = new QueryWrapper();
            wrapper.recordId = (String) rec.get('Id');
            wrapper.name = (String) rec.get('Name');
            wrapper.loanApplicationNo = (String) rec.get('Loan_No__c');
            wrapper.requestor = (String) rec.getSObject('Requestor__r').get('Name');
            String recStatus = (String) rec.get('Status__c');
            wrapper.status = recStatus;
            if (recStatus == 'Closed') {
                wrapper.isClosed = true;
            } else {
                wrapper.isClosed = false;
            }
            String fullRemarks = (String) rec.get('Remarks__c');
            wrapper.remarks = fullRemarks;
            if (String.isNotBlank(fullRemarks)) {
                List<String> parts = fullRemarks.split('<br>');
                String lastPart = parts.isEmpty() ? '' : parts[parts.size() - 1];
                Integer colonIdx = lastPart.lastIndexOf(':');
                if (colonIdx >= 0 && colonIdx < lastPart.length() - 1) {
                    wrapper.latestRemarks = lastPart.substring(colonIdx + 1).trim();
                } else {
                    wrapper.latestRemarks = '';
                }
            } else {
                wrapper.latestRemarks = '';
            }
            String requestorId = (String) rec.get('Requestor__c');
            String responderId = (String) rec.get('Responder__c');
            // wrapper.isSameUser = (requestorId == responderId);
            wrapper.isSameUser = (requestorId == uid);
            wrapper.isSentResponse = (recStatus == 'Response Sent');
            wrapper.payoutId = (String) rec.get('Vendor_Invoice_Id__c');
            wrapper.isAssigned = (recStatus == 'Assigned');
            wrapper.payout = (String) rec.getSObject('Vendor_Invoice_Id__r').get('Name');
            wrapper.docId = (String) rec.get('Document_Details__c');
            String documentContent = '';
            if((String) rec.get('Document_Details__c') != null) {
                documentContent = (String) rec.getSObject('Document_Details__r').get('Content_Document_Id__c');
                if (documentContent != null && documentContent != '') {
                    wrapper.docContent = documentContent;
                    wrapper.isDocUpload = false;
                    wrapper.isDocPresent = true;
                    wrapper.docName = (String) rec.getSObject('Document_Details__r').get('Name');
                    List<ContentDocument> contDoc = [SELECT Id, CreatedBy.Name, FileType, CreatedDate FROM ContentDocument WHERE Id = :documentContent LIMIT 1];
                    wrapper.fileType = contDoc[0].FileType;
                } else {
                    wrapper.isDocUpload = true;
                    wrapper.isDocPresent = false;
                    wrapper.fileType = '';
                }
            } else {
                wrapper.isDocUpload = true;
                wrapper.isDocPresent = false;
                wrapper.fileType = '';
            }
            result.add(wrapper);
        }

        return result;
    }

    private static String buildFilterQuery(String fromDate, String toDate, String status, String payout, String queryRec, Map<String, Object> bindVars) {
        String query = '';

        if (String.isNotBlank(payout)) {
            query += 'AND Vendor_Invoice_Id__c = :payout ';
            bindVars.put('payout', payout);
        }

        if(fromDate != null && toDate != null){
            query += 'AND CreatedDate >= ' + (date.valueOf(fromDate).toString().replace(' 00:00:00', 'T00:00:00.001+0000')) +' AND CreatedDate <= ' + (date.valueOf(toDate).toString().replace(' 00:00:00', 'T23:59:59.999+0000')) + ' ';
        }

        if(String.isNotBlank(queryRec)) {
            query += 'AND Id = :queryRec ';
            bindVars.put('payout', queryRec);
        }

        if (String.isNotBlank(status) && status != 'All') {
            query += ' AND Status__c = :status ';
            bindVars.put('status', status);
        }

        query += ' ORDER BY Name ASC LIMIT 3000 ';

        return query;
    }

    public class QueryWrapper {
        @AuraEnabled public String recordId;
        @AuraEnabled public String name;
        @AuraEnabled public String loanApplicationNo;
        @AuraEnabled public String status;
        @AuraEnabled public String requestor;
        @AuraEnabled public String remarks;
        @AuraEnabled public String payoutId;
        @AuraEnabled public String payout;
        @AuraEnabled public Boolean isSameUser;
        @AuraEnabled public Boolean isSentResponse;
        @AuraEnabled public Boolean isAssigned;
        @AuraEnabled public Boolean isClosed;
        @AuraEnabled public String latestRemarks;
        @AuraEnabled public Boolean isDocUpload;
        @AuraEnabled public Boolean isDocPresent;
        @AuraEnabled public String docId;
        @AuraEnabled public String docContent;
        @AuraEnabled public String docName;
        @AuraEnabled public String fileType;
    }

    @AuraEnabled
    public static void updateQuery(String queryRec, String method, String remarks, String newAsignee) {
        List<string> usrDetails = getCurrentUserDetails();
        String remarksHeader = usrDetails[1] +' ('+ usrDetails[0] +') - '+ Datetime.NOW().format('dd/MM/YYYY, hh:mm a') +':';
        List<Query__c> queryList = [SELECT Id, Remarks__c, Status__c, Requestor__c, Responder__c, LastModifiedById FROM Query__c WHERE Id =: queryRec LIMIT 1]; 
        if (!queryList.isEmpty()) {
            Query__c query = queryList[0];
            query.Status__c = method;
            if (method == 'Response Sent') {
                query.Responder__c = query.Requestor__c;
            } else if (newAsignee != null && method == 'Re-assigned') {
                List<User> newAsigneeProfile = [SELECT Name, Profile.Name FROM User WHERE Id =: newAsignee LIMIT 1];
                query.Assigned_To_Profile__c = newAsigneeProfile[0].Profile.Name;
                query.Responder__c = newAsignee;
            } else if (method == 'Sent Back') {
                query.Responder__c = query.LastModifiedById;
            }
            if (!String.isBlank(query.Remarks__c)) {
                query.Remarks__c += '<br>' + method + ' - ' + remarksHeader + remarks;
            } else {
                query.Remarks__c = method + ' - ' + remarksHeader + remarks;
            }
            update query;
        }
    }

    @AuraEnabled
    public static String checkFileType(String contentVersionId) {
        List<ContentVersion> cv = [SELECT FileType FROM ContentVersion Where ContentDocumentId =: contentVersionId Limit 1];
        return cv[0].FileType;
    }

    @AuraEnabled
    public static Map<String, Boolean> checkExistingQueries(List<String> vendorInvoiceIds){
        try {
            Map<String, Boolean> resultMap = new Map<String, Boolean>();
            for(String invId : vendorInvoiceIds){
                resultMap.put(invId, false);
            }

            if(vendorInvoiceIds.isEmpty()){
                return resultMap;
            }

            List<Query__c> existingQueries = [SELECT Vendor_Invoice_Id__c FROM Query__c WHERE Vendor_Invoice_Id__c IN :vendorInvoiceIds];
            for(Query__c q : existingQueries){
                resultMap.put(q.Vendor_Invoice_Id__c, true);
            }

            return resultMap;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}