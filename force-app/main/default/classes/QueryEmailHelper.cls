public with sharing class QueryEmailHelper {

    // Enqueue async processing entry
    public static void processEmail(List<Query__c> newList, Map<Id, Query__c> oldMap, Boolean isInsert) {
        System.debug('processEmail (async) called with newList size: ' + (newList != null ? newList.size() : 0) + ', isInsert: ' + isInsert);
        if (newList == null || newList.isEmpty()) return;

        List<Id> queryIds = new List<Id>();
        for (Query__c q : newList) {
            if (q != null && q.Id != null) queryIds.add(q.Id);
        }
        if (!queryIds.isEmpty()) {
            System.enqueueJob(new QueryEmailQueueable(queryIds, isInsert));
        }
    }

    // --- Internal per-record work container (so we only loop newList once) ---
    private class QueryWork {
        Id qId;
        Id loanId;
        String qName;
        Id requestorId;
        Id createdById;
        String requestedFromCsv;
        String status;       // current record's status
        String remarks;      // current record's remarks
        String reqName;      // requestor name (computed)

        Set<Id> responderIds = new Set<Id>();
        String responderEmails;     // consolidated (computed later)

        // Derived after reference queries:
        Query__c latestLoanQuery;   // latest Query for the same Loan
        String statusToUse;
        String remarksToUse;
        String loanName;
        String loanStage;
    }

    // Synchronous logic used by Queueable
    public static void processEmailSync(List<Query__c> newList, Boolean isInsert) {
        System.debug('processEmailSync called with newList size: ' + (newList != null ? newList.size() : 0) + ', isInsert: ' + isInsert);
        if (newList == null || newList.isEmpty()) return;

        // Filter newList to only those where Loan_Application__r.RecordType.Name IN ('Affordable Home Loan','Home_Loan') 
        Set<String> allowedRTs = new Set<String>{'Affordable Home Loan','Home Loan'}; // Omkar 10/06/26
        List<Query__c> filteredList = new List<Query__c>();
        for (Query__c q : newList) {
            if (q == null || q.Id == null) continue;
            // Defensive: check if Loan_Application__r and RecordType are loaded
            if (q.Loan_Application__r != null &&
                q.Loan_Application__r.RecordType != null &&
                allowedRTs.contains(q.Loan_Application__r.RecordType.Name) ) {
                filteredList.add(q);
            }
        }

        System.debug('Filtered Query__c count: ' + filteredList.size());    
        System.debug('Filtered Query__c records for Affordable Home Loan: ' + JSON.serialize(filteredList));
        
        if (filteredList.isEmpty()) return;

        // ---------- One pass over filteredList: collect & stage ----------
        Map<Id, QueryWork> workByQuery = new Map<Id, QueryWork>();
        Set<Id> allQueryIds    = new Set<Id>();
        Set<Id> loanAppIds     = new Set<Id>();
        Set<Id> userIdsToFetch = new Set<Id>();

        for (Query__c q : filteredList) {
            QueryWork w = new QueryWork();
            w.qId   = q.Id;
            w.loanId = q.Loan_Application__c;
            w.qName = q.Name;
            w.requestorId = q.Requestor__c;
            w.createdById = q.CreatedById;
            w.requestedFromCsv = q.Requested_from_Users__c;
            w.status = q.Status__c;
            w.remarks = q.Remarks__c;

            // Collect responder Ids from CSV once
            if (q.Requested_from_Users__c != null) {
                w.responderIds.addAll(parseUserIds(q.Requested_from_Users__c));
            }

            // Aggregate Ids for bulk queries
            allQueryIds.add(w.qId);
            if (w.loanId != null) loanAppIds.add(w.loanId);
            if (w.requestorId != null) userIdsToFetch.add(w.requestorId);
            if (w.createdById != null) userIdsToFetch.add(w.createdById);
            userIdsToFetch.addAll(w.responderIds);

            workByQuery.put(w.qId, w);
        }

        // ---------- Latest Note per Query (optional legacy Note) ----------
        Map<Id, String> latestNoteBodyByQueryId = new Map<Id, String>();
        if (!allQueryIds.isEmpty()) {
            List<Note> allNotes = [
                SELECT ParentId, Body, CreatedDate
                FROM Note
                WHERE ParentId IN :allQueryIds
                ORDER BY ParentId, CreatedDate DESC, Id DESC
            ];
            Map<Id, Note> latestNoteByQueryId = new Map<Id, Note>();
            for (Note n : allNotes) {
                if (!latestNoteByQueryId.containsKey(n.ParentId)) {
                    latestNoteByQueryId.put(n.ParentId, n);
                }
            }
            for (Id qid : latestNoteByQueryId.keySet()) {
                latestNoteBodyByQueryId.put(qid, String.valueOf(latestNoteByQueryId.get(qid).Body));
            }
        }

        // ---------- Users (single SOQL) ----------
        Map<Id, User> usersById = new Map<Id, User>();
        if (!userIdsToFetch.isEmpty()) {
            for (User u : [
                SELECT Id, Email, IsActive, FirstName, LastName
                FROM User
                WHERE Id IN :userIdsToFetch
            ]) {
                usersById.put(u.Id, u);
            }
        }

        // ---------- Latest Query__c per Loan (for status/merge fallbacks) ----------
        Map<Id, Query__c> latestQueryByLoanApp = new Map<Id, Query__c>();
        if (!loanAppIds.isEmpty()) {
            List<Query__c> allRelatedQueries = [
                SELECT Id,
                       Loan_Application__c,
                       Status__c,
                       Remarks__c,
                       CreatedDate,
                       Name,
                       Requestor__r.Name,
                       Loan_Application__r.Name,
                       Loan_Application__r.StageName
                FROM Query__c
                WHERE Loan_Application__c IN :loanAppIds
                ORDER BY Loan_Application__c, CreatedDate DESC, Id DESC
            ];
            Set<Id> seenLoan = new Set<Id>();
            for (Query__c qr : allRelatedQueries) {
                if (!seenLoan.contains(qr.Loan_Application__c)) {
                    latestQueryByLoanApp.put(qr.Loan_Application__c, qr);
                    seenLoan.add(qr.Loan_Application__c);
                }
            }
        }

        // ---------- Latest Child remark per Parent Query ----------
        Map<Id, Query__c> latestRemarkByParent = new Map<Id, Query__c>(); // key= Parent_Query__c
        if (!allQueryIds.isEmpty()) {
            List<Query__c> childRemarks = [
                SELECT Id, Parent_Query__c, Remarks__c, CreatedDate, Type_of_Record__c, RecordType.DeveloperName
                FROM Query__c
                WHERE Parent_Query__c IN :allQueryIds
                  AND Type_of_Record__c = 'Child'
                ORDER BY Parent_Query__c, CreatedDate DESC, Id DESC
            ];
            for (Query__c r : childRemarks) {
                if (r.Parent_Query__c == null) continue;
                if (!latestRemarkByParent.containsKey(r.Parent_Query__c)) {
                    latestRemarkByParent.put(r.Parent_Query__c, r);
                }
            }
        }

        // ---------- EmailTemplates (query once) ----------
        Map<Id, EmailTemplate> templateById = new Map<Id, EmailTemplate>();
        Set<Id> templateIds = new Set<Id>();
        // Labels are expected to store Template Ids (String). Cast defensively.
        try { templateIds.add((Id) Label.TEMPLATE_RESPONDER); } catch (Exception ignore) {}
        try { templateIds.add((Id) Label.TEMPLATE_REQUESTOR); } catch (Exception ignore) {}
        if (!templateIds.isEmpty()) {
            for (EmailTemplate t : [
                SELECT Id, Subject, HtmlValue
                FROM EmailTemplate
                WHERE Id IN :templateIds
            ]) {
                templateById.put(t.Id, t);
            }
        }
        EmailTemplate responderTemplate = templateById.get(safeId(Label.TEMPLATE_RESPONDER));
        EmailTemplate requestorTemplate = templateById.get(safeId(Label.TEMPLATE_REQUESTOR));

        // ---------- Precompute consolidated responder emails per Query ----------
        for (QueryWork w : workByQuery.values()) {
            if (w.responderIds == null || w.responderIds.isEmpty()) { w.responderEmails = ''; continue; }
            Set<String> emailSet = new Set<String>();
            for (Id uid : w.responderIds) {
                User u = usersById.get(uid);
                if (u != null && u.IsActive && !String.isBlank(u.Email)) {
                    emailSet.add(u.Email.trim());
                }
            }
            w.responderEmails = emailSet.isEmpty() ? '' : String.join(new List<String>(emailSet), ',');
        }

        // ---------- Compute derived fields & build jobs (no callouts yet) ----------
        List<Map<String, String>> jobs = new List<Map<String, String>>();
        Set<String> responderStatuses = new Set<String>{ 'Assigned', 'Sent Back', 'Re-assigned', 'Closed' };
        String requestorStatus = 'Response Sent';

        for (QueryWork w : workByQuery.values()) {
            // choose status (prefer latest loan-level status if present)
            Query__c latestLoan = (w.loanId != null) ? latestQueryByLoanApp.get(w.loanId) : null;
            w.latestLoanQuery = latestLoan;
            w.statusToUse = (latestLoan != null && String.isNotBlank(latestLoan.Status__c)) ? latestLoan.Status__c : w.status;

            // remarks fallback: latest Note -> latest Child remark -> latest loan-level -> current
            String noteBody = latestNoteBodyByQueryId.get(w.qId);
            String childRemark = (latestRemarkByParent.containsKey(w.qId)) ? latestRemarkByParent.get(w.qId).Remarks__c : null;
            String loanRemark = (latestLoan != null) ? latestLoan.Remarks__c : null;
            w.remarksToUse = !String.isBlank(noteBody)    ? noteBody :
                             (!String.isBlank(childRemark) ? childRemark :
                             (!String.isBlank(loanRemark)  ? loanRemark : w.remarks));

            // loan merge fields
            w.loanName  = (latestLoan != null && latestLoan.Loan_Application__r != null && latestLoan.Loan_Application__r.Name != null)
                            ? latestLoan.Loan_Application__r.Name : null;
            if (w.loanName == null && workByQuery.containsKey(w.qId)) {
                // fallback to relation on this record if caller passed it populated (Queueable query includes relations)
                // No-op here if not present; EmailController doesn't require it.
            }
            w.loanStage = (latestLoan != null && latestLoan.Loan_Application__r != null && latestLoan.Loan_Application__r.StageName != null)
                            ? latestLoan.Loan_Application__r.StageName : null;

            // requestor name merge field
            w.reqName = '';
            if (w.requestorId != null && usersById.containsKey(w.requestorId)) {
                User reqUser = usersById.get(w.requestorId);
                if (reqUser != null) {
                    String first = reqUser.FirstName != null ? reqUser.FirstName : '';
                    String last = reqUser.LastName != null ? reqUser.LastName : '';
                    w.reqName = (first + ' ' + last).trim();
                }
            }

            // --- 1) Responder mail (single consolidated email) ---
            if (responderTemplate != null && responderStatuses.contains(w.statusToUse) && !String.isBlank(w.responderEmails)) {
                String emailBody    = responderTemplate.HtmlValue;
                String emailSubject = responderTemplate.Subject;

                // Merges
                emailSubject = emailSubject.replace('{!Query__c.Name}', w.qName != null ? w.qName : '');
                emailBody    = emailBody.replace('{!Query__c.Loan_Application__r.Name}', nvl(w.loanName));
                emailBody    = emailBody.replace('{!Query__c.Loan_Application__r.StageName}', nvl(w.loanStage));
                emailBody    = emailBody.replace('{!Query__c.Name}', w.qName != null ? w.qName : '');
                emailBody    = emailBody.replace('{!Query__c.Status__c}', w.statusToUse != null ? w.statusToUse : '');
                emailBody    = emailBody.replace('{!Query__c.Requestor__r.Name}', w.reqName != null ? w.reqName : '');
                emailBody    = emailBody.replace('{!Query__c.Remarks__c}', w.remarksToUse != null ? w.remarksToUse : '');

                Map<String, String> inputMap = new Map<String, String>();
                inputMap.put('loanId',       w.loanId != null ? String.valueOf(w.loanId) : '');
                inputMap.put('applicantId',  String.valueOf(w.qId));
                inputMap.put('processName',  'Email');
                inputMap.put('content',      emailBody);
                inputMap.put('subject',      emailSubject);
                inputMap.put('email',        w.responderEmails); // comma-separated recipients
                inputMap.put('fileType',     '');
                inputMap.put('filename',     '');
                inputMap.put('base64String', '');
                jobs.add(inputMap);
            }

            // --- 2) Requestor mail (single) when Response Sent ---
            if ('Response Sent' == w.statusToUse && requestorTemplate != null) {
                Id reqId = (w.requestorId != null) ? w.requestorId : w.createdById;
                User req = (reqId != null) ? usersById.get(reqId) : null;
                if (req != null && req.IsActive && !String.isBlank(req.Email)) {
                    String emailBody    = requestorTemplate.HtmlValue;
                    String emailSubject = requestorTemplate.Subject;

                    // merges
                    emailSubject = emailSubject.replace('{!Query__c.Name}', w.qName != null ? w.qName : '');
                    emailBody    = emailBody.replace('{!Query__c.Loan_Application__r.Name}', nvl(w.loanName));
                    emailBody    = emailBody.replace('{!Query__c.Loan_Application__r.StageName}', nvl(w.loanStage));
                    emailBody    = emailBody.replace('{!Query__c.Name}', w.qName != null ? w.qName : '');
                    emailBody    = emailBody.replace('{!Query__c.Status__c}', w.statusToUse != null ? w.statusToUse : '');
                    emailBody    = emailBody.replace('{!Query__c.Remarks__c}', w.remarksToUse != null ? w.remarksToUse : '');
                    emailBody    = emailBody.replace('{!Query__c.Requestor__r.Name}', ''); // optional

                    Map<String, String> inputMap = new Map<String, String>();
                    inputMap.put('loanId',       w.loanId != null ? String.valueOf(w.loanId) : '');
                    inputMap.put('applicantId',  String.valueOf(w.qId));
                    inputMap.put('processName',  'Email');
                    inputMap.put('content',      emailBody);
                    inputMap.put('subject',      emailSubject);
                    inputMap.put('email',        req.Email);   // single recipient
                    inputMap.put('fileType',     '');
                    inputMap.put('filename',     '');
                    inputMap.put('base64String', '');
                    jobs.add(inputMap);
                }
            }
        }

        // ---------- Callouts AFTER all prep (no DML here) ----------
        for (Map<String, String> inputMap : jobs) {
            try {
                String resp = EmailController.initiateAPIRequestInternal(inputMap);
                System.debug('EmailController response: ' + resp);
            } catch (Exception e) {
                System.debug('Error sending email: ' + e.getMessage());
            }
        }
    }

    // Helper to parse user IDs from CSV-like strings
    private static Set<Id> parseUserIds(String raw) {
        Set<Id> out = new Set<Id>();
        if (String.isBlank(raw)) return out;

        String norm = raw.replace('\r', ',').replace('\n', ',').replace(';', ',');
        for (String token : norm.split(',')) {
            if (String.isBlank(token)) continue;
            String t = token.trim();
            if (!t.startsWith('005') || t.length() < 15) continue;
            try { out.add((Id) t); } catch (Exception ignore) {}
        }
        return out;
    }

    // Safe string fallback
    private static String nvl(String s) { return (s == null) ? '' : s; }

    // Cast Label to Id safely (labels hold String)
    private static Id safeId(String labelVal) {
        try { return (Id) labelVal; } catch (Exception e) { return null; }
    }

    // (Optional) simple struct kept for compatibility with previous logs
    private class SendResult {
        public Boolean success;
        public String message;
        public SendResult(Boolean success, String message) {
            this.success = success; this.message = message;
        }
    }
    private static SendResult makeResp(Boolean success, String message) {
        return new SendResult(success, message);
    }
}