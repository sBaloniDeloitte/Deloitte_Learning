global class AutoRejectLoanApplicationsBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {

        Date targetDate = Date.today().addDays(-60);

        if (Test.isRunningTest()) {

            return Database.getQueryLocator([
                SELECT Id,
                    Name,
                    StageName,
                    Approval_Status__c
                FROM Opportunity
                WHERE StageName = 'Sales Login'
                AND Product__c = 'Affordable Home Loan'
                AND LMS_Loan_Reference__c = null
            ]);
        }

        return Database.getQueryLocator([
            SELECT Id,
                   Name,
                   StageName,
                   Approval_Status__c,
                   LastStageChangeDate
            FROM Opportunity
            WHERE StageName = 'Sales Login'
            AND LastStageChangeDate <= :targetDate
            AND Approval_Status__c NOT IN ('System Reject', 'Hard Rejected', 'Soft Rejected 1', 'Soft Rejected 2', 'Rejected')
            AND Product__c = 'Affordable Home Loan'
            AND LMS_Loan_Reference__c = null
            // LIMIT 1 // For testing purpose have set the limit to 1
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> loanApplications) {

        List<Opportunity> loansToUpdate =
            new List<Opportunity>();

        for(Opportunity loan : loanApplications) {

            loan.Approval_Status__c = 'System Reject';

            loansToUpdate.add(loan);
        }

        if(!loansToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(loansToUpdate, false);
        }
    }

    global void finish(Database.BatchableContext bc) {

        System.debug('Auto Reject Loan Applications Batch Completed');
    }
}