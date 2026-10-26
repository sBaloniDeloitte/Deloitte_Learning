/*_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________*/
/**
 * @description Backend support for the dark-themed "FCU" accordion section
 *              on the Loan Application (Opportunity) "Application Verification" tab.
 *              Supplies the Overall Status fields and the FCU Application Verification
 *              child records that were previously rendered via standard Field Section
 *              and Related List components (replaced to match Field Investigation theming).
 */
public with sharing class FCUAccordionController {

    /**
     * @description Returns the Overall Status fields (FCU_Status__c, Overall_FCU_Verification__c)
     *              for the given Loan Application (Opportunity) record.
     * @param recordId Opportunity (Loan Application) record Id
     * @return Opportunity with FCU_Status__c and Overall_FCU_Verification__c populated
     */
    @AuraEnabled(cacheable=true)
    public static Opportunity getOverallStatus(Id recordId) {
        return [
            SELECT Id, FCU_Status__c, Overall_FCU_Verification__c
            FROM Opportunity
            WHERE Id = :recordId
            LIMIT 1
        ];
    }

    /**
     * @description Returns the FCU Application Verification child records
     *              for the given Loan Application, mirroring the standard
     *              "Application Verifications" related list (RecordType = FCU).
     * @param recordId Opportunity (Loan Application) record Id
     * @return List of Application_Verification__c FCU records
     */
    @AuraEnabled(cacheable=true)
    public static List<Application_Verification__c> getFCUVerifications(Id recordId) {
        return [
            SELECT Id, Name, Applicant__r.Name, Stage__c
            FROM Application_Verification__c
            WHERE Loan_Application__c = :recordId
            AND RecordType.Name = 'FCU'
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}
/*__________________________GenAI: Generated code ends here______________________________*/