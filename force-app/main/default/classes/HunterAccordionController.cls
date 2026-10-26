/*_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________*/
/**
 * @description Backend support for the dark-themed "Hunter Check" accordion section
 *              on the Loan Application (Opportunity) "Application Verification" tab.
 *              Supplies the Hunter Verification child records that were previously
 *              rendered via the standard Dynamic Related List component (replaced to
 *              match the Field Investigation Initiation dark theme), mirroring the
 *              pattern already used by FCUAccordionController for the FCU accordion.
 */
public with sharing class HunterAccordionController {

    /**
     * @description Returns the Hunter Verification child records for the given
     *              Loan Application, mirroring the standard "Application Verifications"
     *              related list (RecordType = 'Hunter Verification') that used to sit
     *              inside the Hunter Check accordion section.
     * @param recordId Opportunity (Loan Application) record Id
     * @return List of Application_Verification__c Hunter Verification records
     */
    @AuraEnabled(cacheable=true)
    public static List<Application_Verification__c> getHunterVerifications(Id recordId) {
        return [
            SELECT Id, Name, Applicant__r.Name, Hunter_Decision__c, Hunter_Match__c
            FROM Application_Verification__c
            WHERE Loan_Application__c = :recordId
            AND RecordType.Name = 'Hunter Verification'
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}
/*__________________________GenAI: Generated code ends here______________________________*/