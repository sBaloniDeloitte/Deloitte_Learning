/**
 * @description       : Returns the list of Query__c records tied to a Loan Application,
 *                       used by queryModuleAssignedQueriesCmp to let the user pick which
 *                       query to open when more than one exists for the same application.
 * @author            : Codify
**/
// This Code was generated using GenAI tool : Codify, Please check for accuracy
public without sharing class QueryModuleListController {

    public class QuerySummaryWrapper {
        @AuraEnabled public String queryId;
        @AuraEnabled public String queryNumber;
        @AuraEnabled public String queryType;
        @AuraEnabled public String queryCategory;
        @AuraEnabled public String status;
        @AuraEnabled public String requestorName;
        @AuraEnabled public String createdDate;
    }

    @AuraEnabled
    public static List<QuerySummaryWrapper> getAssignedQueriesForLoan(Id loanApplicationId) {
        try {
            List<QuerySummaryWrapper> result = new List<QuerySummaryWrapper>();
            List<Query__c> queries = [SELECT Id, Name, Query_Type__c, Query_Category__c, Status__c,
                                              Requestor__r.Name, CreatedDate
                                       FROM Query__c
                                       WHERE Loan_Application__c = :loanApplicationId
                                         AND Type_of_Record__c = 'Parent'
                                       ORDER BY CreatedDate DESC];
            for (Query__c q : queries) {
                QuerySummaryWrapper w = new QuerySummaryWrapper();
                w.queryId = q.Id;
                w.queryNumber = q.Name;
                w.queryType = q.Query_Type__c;
                w.queryCategory = q.Query_Category__c;
                w.status = q.Status__c;
                w.requestorName = q.Requestor__r != null ? q.Requestor__r.Name : '';
                w.createdDate = String.valueOf(q.CreatedDate);
                result.add(w);
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
// GenAI: Generated code ends here