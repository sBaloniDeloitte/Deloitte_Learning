/**
* @description       : Supplies the Process Journey side-panel (stage timeline,
*                       applicant summary) for the loan login screens.
* @author            : Codify
**/
public without sharing class ProcessJourneyController {

    /**
     * @description Builds the numbered stage timeline (Applicant Information,
     * Application Information, Eligibility, Document Details, Collateral,
     * Other Information ...) with a Completed / In Progress / Pending status
     * for each stage, reusing the existing master-stage completion logic in
     * COMM_SalesLoanActionsController.getActionList so the two stepper UIs
     * never disagree on the "current" stage.
     * @param loanId Loan Application (Opportunity) Id
     * @return List<JourneyStageWrapper> ordered by master screen sequence
     */
    @AuraEnabled
    public static List<JourneyStageWrapper> getProcessJourney(Id loanId) {
        List<JourneyStageWrapper> journey = new List<JourneyStageWrapper>();
        try {
            List<COMM_SalesLoanActionsController.ActionListWrapper> stages =
                COMM_SalesLoanActionsController.getActionList(loanId);

            Boolean inProgressAssigned = false;
            Integer sequence = 1;
            for (COMM_SalesLoanActionsController.ActionListWrapper stage : stages) {
                JourneyStageWrapper jw = new JourneyStageWrapper();
                jw.sequence = sequence;
                jw.name = stage.name;
                if (stage.completed == true) {
                    jw.status = 'Completed';
                } else if (!inProgressAssigned) {
                    jw.status = 'In Progress';
                    inProgressAssigned = true;
                } else {
                    jw.status = 'Pending';
                }
                journey.add(jw);
                sequence++;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return journey;
    }

    /**
     * @description Fetches the Lead Number / Customer Name summary shown at
     * the top of the Process Journey panel. Falls back to the loan
     * application's own number/name when the record has no related Lead.
     * @param loanId Loan Application (Opportunity) Id
     */
    @AuraEnabled(cacheable=true)
    public static ApplicantSummaryWrapper getApplicantSummary(Id loanId) {
        ApplicantSummaryWrapper wrap = new ApplicantSummaryWrapper();
        try {
            List<Opportunity> loanList = [
                SELECT Id, Name, Lead__c, Lead__r.Lead_Number__c, Lead__r.Full_Name_As_Per_Pan__c
                FROM Opportunity
                WHERE Id = :loanId
                LIMIT 1
            ];
            if (!loanList.isEmpty()) {
                Opportunity opp = loanList[0];
                Boolean hasLead = (opp.Lead__c != null && opp.Lead__r != null);
                // Lead Number - use the related Lead's number when available,
                // otherwise fall back to the Loan Application's own name
                // (e.g. "LA-000000013") so the field is never blank.
                wrap.leadNumber = (hasLead && String.isNotBlank(opp.Lead__r.Lead_Number__c))
                    ? opp.Lead__r.Lead_Number__c
                    : opp.Name;
                // Customer Name - the Lead's PAN-based full name is the source
                // of truth used across the login flow (see leadName usage in
                // COMM_SalesLoanLoginController / COMM_SalesLoanActionsController).
                wrap.customerName = (hasLead && String.isNotBlank(opp.Lead__r.Full_Name_As_Per_Pan__c))
                    ? opp.Lead__r.Full_Name_As_Per_Pan__c
                    : null;
            }

            // Fall back to the Primary Applicant's own name when the Loan
            // Application has no related Lead (or the Lead has no PAN name
            // captured yet) so the panel still shows a real customer name.
            if (String.isBlank(wrap.customerName)) {
                List<Application_Applicant__c> primaryApplicants = [
                    SELECT Id, Pan_Name__c, Name_of_Organization__c
                    FROM Application_Applicant__c
                    WHERE Loan_Application__c = :loanId AND Applicant_Type__c = 'Primary Applicant'
                    LIMIT 1
                ];
                if (!primaryApplicants.isEmpty()) {
                    Application_Applicant__c primary = primaryApplicants[0];
                    wrap.customerName = String.isNotBlank(primary.Name_of_Organization__c)
                        ? primary.Name_of_Organization__c
                        : primary.Pan_Name__c;
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return wrap;
    }

    public class JourneyStageWrapper {
        @AuraEnabled public Integer sequence;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
    }

    public class ApplicantSummaryWrapper {
        @AuraEnabled public String leadNumber;
        @AuraEnabled public String customerName;
    }
}