public with sharing class OpportunityOwnerEmailService {

    // Guard (kept, although we no longer self-DML in this class)
    private static Boolean reentry = false;

    private static final String DEFAULT_SUBJECT =
        'Loan Application Update: {!Opportunity.Name} — Stage/Sub Stage/Owner changed';

    public static void handleAfterUpdate(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        if (reentry) return;
        if (newList == null || newList.isEmpty()) return;

        // Select candidates: Opted-in + any change in Stage/SubStage/Owner
        Set<Id> candidateIds = new Set<Id>();
        for (Opportunity n : newList) {
            Opportunity o = oldMap.get(n.Id);
            if (n.Opt_In__c == true &&
               (changed(o.StageName, n.StageName) ||
                changed((String)o.get('Sub_stage__c'), (String)n.get('Sub_stage__c')) ||
                changed(o.OwnerId, n.OwnerId))) {
                candidateIds.add(n.Id);
            }
        }
        if (candidateIds.isEmpty()) return;

        // Read only fetch (no FOR UPDATE), since Owner_History__c is updated in BEFORE
        Map<Id, Opportunity> opps = new Map<Id, Opportunity>([
            SELECT Id, Name, OwnerId, StageName, Sub_stage__c, Owner_History__c, Opt_In__c
            FROM Opportunity
            WHERE Id IN :candidateIds
        ]);

        // Load email template once
        TemplateInfo templateInfo = loadTemplateInfo();
        String templateHtml = templateInfo.html;
        String templateSubject = templateInfo.subject;

        // Preload all relevant users: current owner, previous owner, initial owner
        Set<Id> userIds = new Set<Id>();
        for (Opportunity o : opps.values()) {
            if (o.OwnerId != null) userIds.add(o.OwnerId);
            OwnerLogUtil.InitialInfo init = OwnerLogUtil.parseInitial(o.Owner_History__c);
            if (init != null && !String.isBlank(init.userId)) {
                try { userIds.add((Id)init.userId); } catch (Exception ignore) {}
            }
            Opportunity oldOpp = oldMap.get(o.Id);
            if (oldOpp != null && oldOpp.OwnerId != null) userIds.add(oldOpp.OwnerId);
        }
        Map<Id, User> users = userIds.isEmpty() ? new Map<Id, User>() :
            new Map<Id, User>([
                SELECT Id, Name, Email, IsActive, Profile.Name
                FROM User
                WHERE Id IN :userIds
            ]);

        List<OpportunityEmailQueueable.EmailTask> tasks = new List<OpportunityEmailQueueable.EmailTask>();

        for (Opportunity o : opps.values()) {
            Opportunity oldOpp = oldMap.get(o.Id);

            // Current owner + profile
            User currOwner = users.get(o.OwnerId);
            String currProfile = (currOwner != null && currOwner.Profile != null) ? currOwner.Profile.Name : '';

            // Initial owner (for recipients)
            OwnerLogUtil.InitialInfo init = OwnerLogUtil.parseInitial(o.Owner_History__c);
            Id initUserId = null;
            if (init != null) {
                try { initUserId = (Id)init.userId; } catch (Exception ignore) {}
            }

            // Previous owner (for template display)
            User oldOwner = (oldOpp != null ? users.get(oldOpp.OwnerId) : null);

            // Recipients: initial + current (dedup)
            Set<String> emails = new Set<String>();
            if (initUserId != null) {
                User iu = users.get(initUserId);
                if (iu != null && iu.IsActive && !String.isBlank(iu.Email)) emails.add(iu.Email);
            }
            if (currOwner != null && currOwner.IsActive && !String.isBlank(currOwner.Email)) emails.add(currOwner.Email);

            if (emails.isEmpty()) continue;

            // Subject + HTML body
            String oppName = safe(o.Name);
            String subject = (templateSubject != null ? templateSubject : DEFAULT_SUBJECT)
                .replace('{!Opportunity.Name}', oppName);

            String html = (templateHtml != null ? templateHtml : fallbackHtml());

            // Previous values
            String prevStage = (oldOpp != null ? safe(oldOpp.StageName) : '');
            String prevSub   = (oldOpp != null ? safe((String)oldOpp.get('Sub_stage__c')) : '');
            String prevOwner = (oldOwner != null ? safe(oldOwner.Name) : '');

            // Current values
            String stageNow  = safe(o.StageName);
            String subNow    = safe(o.Sub_stage__c);
            String ownerName = (currOwner != null ? safe(currOwner.Name) : '');

            // Replace tokens (cover both Owner and Owner.Name variants)
            html = html.replace('{!Opportunity.Name}', oppName);
            html = html.replace('{!Opportunity.StageName}', stageNow);
            html = html.replace('{!Opportunity.Sub_stage__c}', subNow);
            html = html.replace('{!Opportunity.Owner}', ownerName);
            html = html.replace('{!Opportunity.Owner.Name}', ownerName);

            html = html.replace('{!$Label.Previous_Stage}', prevStage);
            html = html.replace('{!$Label.Previous_Sub_Stage}', prevSub);
            html = html.replace('{!$Label.Previous_Owner}', prevOwner);

            Id loanId = o.Id; // adjust if Loan Id is a different field

            for (String toEmail : emails) {
                tasks.add(new OpportunityEmailQueueable.EmailTask(o.Id, loanId, toEmail, subject, html));
            }
        }

        // Enqueue queueables in chunks
        if (!tasks.isEmpty()) {
            Integer chunk = 40;
            for (Integer i = 0; i < tasks.size(); i += chunk) {
                Integer endIdx = Math.min(i + chunk, tasks.size());
                List<OpportunityEmailQueueable.EmailTask> slice = new List<OpportunityEmailQueueable.EmailTask>();
                for (Integer j = i; j < endIdx; j++) slice.add(tasks[j]);
                System.enqueueJob(new OpportunityEmailQueueable(slice));
            }
        }
    }

    // ---------- helpers ----------
    private static Boolean changed(Object oldVal, Object newVal) {
        if (oldVal == null && newVal == null) return false;
        if (oldVal == null || newVal == null) return true;
        return String.valueOf(oldVal) != String.valueOf(newVal);
    }

    private static String safe(String s) { return (s == null ? '' : s); }

    private class TemplateInfo {
        public String html;
        public String subject;
        public TemplateInfo(String html, String subject) { this.html = html; this.subject = subject; }
    }

    private static TemplateInfo loadTemplateInfo() {
        try {
            EmailTemplate t = [
                SELECT Id, HtmlValue, Subject
                FROM EmailTemplate
                WHERE Id = :Label.owner_stage_substage_change_notif
                LIMIT 1
            ];
            return new TemplateInfo(t.HtmlValue, t.Subject);
        } catch (Exception e) {
            System.debug('Email template not found ('+Label.owner_stage_substage_change_notif+'): ' + e.getMessage());
            return new TemplateInfo(null, null);
        }
    }

    private static String fallbackHtml() {
        return '<html><body style="font-family:Arial,Helvetica,sans-serif;">'
             + '<p><strong>Hello,</strong></p>'
             + '<p>The Opportunity has been updated.</p>'
             + '<ul>'
             + '<li><strong>Loan Application / Opportunity:</strong> {!Opportunity.Name}</li>'
             + '<li><strong>Stage:</strong> {!Opportunity.StageName}</li>'
             + '<li><strong>Sub Stage:</strong> {!Opportunity.Sub_stage__c}</li>'
             + '<li><strong>Owner:</strong> {!Opportunity.Owner.Name}</li>'
             + '</ul>'
             + '<p>Previous Stage: {!$Label.Previous_Stage}<br/>'
             + 'Previous Sub Stage: {!$Label.Previous_Sub_Stage}<br/>'
             + 'Previous Owner: {!$Label.Previous_Owner}</p>'
             + '<p>Regards,<br/>System</p>'
             + '</body></html>';
    }
}