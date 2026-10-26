/*_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________*/
/**
 * Controller for the applicantsListCmp LWC.
 * Returns the Application_Applicant__c records related to a Loan Application (Opportunity).
 */
public with sharing class ApplicantsListController {

    @AuraEnabled(cacheable=true)
    public static List<Application_Applicant__c> getApplicants(Id loanApplicationId) {
        if (loanApplicationId == null) {
            return new List<Application_Applicant__c>();
        }

        return [
            SELECT Id,
                   Name,
                   Applicant_Type__c,
                   Mobile_Number__c,
                   Customer_Profile__c,
                   CIBIL_Score__c,
                   Is_Key_Applicant__c
            FROM Application_Applicant__c
            WHERE Loan_Application__c = :loanApplicationId
            WITH USER_MODE
            ORDER BY CreatedDate ASC
        ];
    }
}
/*__________________________GenAI: Generated code ends here______________________________*/