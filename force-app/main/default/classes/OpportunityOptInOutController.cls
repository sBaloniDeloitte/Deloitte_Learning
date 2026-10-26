public with sharing class OpportunityOptInOutController {

    /**
     * Unified setter for Opt-In state.
     * - When isOptIn == true: sets Opt_In__c = true, initializes/refreshes Owner_History__c (INITIAL + CURR) using OwnerId.
     * - When isOptIn == false: sets Opt_In__c = false (does NOT alter Owner_History__c).
     */
    @AuraEnabled
    public static void setOptIn(Id recordId, Boolean isOptIn) {
        if (recordId == null) {
            throw new AuraHandledException('recordId is required');
        }

        // Lock the row to prevent race conditions.
        Opportunity opp = [
            SELECT Id, OwnerId, StageName, Sub_stage__c, Opt_In__c, Owner_History__c
            FROM Opportunity
            WHERE Id = :recordId
            FOR UPDATE
        ];

        // Only allow opt-in/out if running user is current owner (with sales profile) or initial sales user
        Boolean isInitialSales = OwnerLogUtil.isRunningUserInitialSales(opp.Owner_History__c);
        Boolean isCurrentOwner = UserInfo.getUserId() == opp.OwnerId;
        Boolean isSalesProfile = false;
        if (isCurrentOwner) {
            User currUser = [SELECT Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            isSalesProfile = (currUser.Profile != null && currUser.Profile.Name != null && currUser.Profile.Name.toLowerCase().contains('sales'));
        }
        if (!isCurrentOwner && !isInitialSales) {
            throw new AuraHandledException('You do not have access to opt in/out for this Opportunity.');
        }
        if (isCurrentOwner && !isSalesProfile && !isInitialSales) {
            throw new AuraHandledException('Only Sales users or the initial sales user can opt in/out for this Opportunity.');
        }

        // No-op if no change.
        if (opp.Opt_In__c == isOptIn) {
            return;
        }

        opp.Opt_In__c = isOptIn;

        if (isOptIn == true) {
            // Use current OwnerId as the initial user.
            User initUser = [
                SELECT Id, Profile.Name
                FROM User
                WHERE Id = :opp.OwnerId
                LIMIT 1
            ];

            String nowIso   = Datetime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            String existing = (opp.Owner_History__c == null ? '' : opp.Owner_History__c);

            // Ensure INITIAL line exists (seed with OwnerId + Profile at time of Opt-In).
            if (!OwnerLogUtil.hasInitialLine(existing)) {
                existing = OwnerLogUtil.composeInitial(
                               initUser.Id,
                               (initUser.Profile != null ? initUser.Profile.Name : ''),
                               nowIso
                           ) + '\n' + existing;
            }

            // Always upsert CURR snapshot on opt-in.
            existing = OwnerLogUtil.upsertCurrent(
                existing,
                opp.StageName,
                (opp.Sub_stage__c == null ? '' : opp.Sub_stage__c),
                opp.OwnerId,
                (initUser.Profile != null ? initUser.Profile.Name : ''),
                nowIso
            );

            opp.Owner_History__c = existing;
        }
        // else: Opting OUT → only flip boolean; keep history intact.

        update opp;
    }

    /** Backward-compatible wrappers for your two buttons. */
    @AuraEnabled
    public static void optIn(Id recordId) {
        setOptIn(recordId, true);
    }

    @AuraEnabled
    public static void optOut(Id recordId) {
        setOptIn(recordId, false);
    }


    /**
     * Starts the email send chain for the given recipients.
     * Each recipient is processed in its own transaction.
     *
     * @param oppId     Opportunity Id (used as applicantId in EmailController)
     * @param loanId    Loan Application Id (stringifiable Id or null)
     * @param toEmails  List of recipient emails (order preserved)
     * @param subject   Subject line
     * @param bodyHtml  HTML body
     * @param stopOnFailure If true, the chain stops when one send fails.
     */
    @AuraEnabled
    public static void sendOwnerChangeNotifications(Id oppId,
                                                    Id loanId,
                                                    List<String> toEmails,
                                                    String subject,
                                                    String bodyHtml,
                                                    Boolean stopOnFailure) {
        if (oppId == null) {
            throw new AuraHandledException('oppId is required');
        }
        if (toEmails == null || toEmails.isEmpty()) {
            return;
        }

        List<OpportunityEmailQueueable.EmailTask> items = new List<OpportunityEmailQueueable.EmailTask>();
        for (String e : toEmails) {
            if (String.isBlank(e)) continue;
            items.add(new OpportunityEmailQueueable.EmailTask(
                oppId,
                loanId,
                e.trim(),
                subject,
                bodyHtml
            ));
        }
        if (!items.isEmpty()) {
            OpportunityEmailQueueable.start(items, (stopOnFailure == null ? true : stopOnFailure));
        }
    }
}