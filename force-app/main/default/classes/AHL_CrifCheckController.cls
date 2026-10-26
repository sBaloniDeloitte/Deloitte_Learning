/**
* @File Name : AHL_CrifCheckController .cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 19, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 19, 2025 |   | Initial Version
**/

public class AHL_CrifCheckController  {
	public class GateResult {
        @AuraEnabled public Boolean okToFetch;
        @AuraEnabled public Datetime lastCreated;
    }

    @AuraEnabled(cacheable=false)
    public static GateResult canFetchCrif(Id loanAppId) {
        GateResult res = new GateResult();
        if (loanAppId == null) {
            res.okToFetch = false;
            return res;
        }
        List<Document_Details__c> recent = [
            SELECT Id, CreatedDate, Name, Document_Master__r.Name
            FROM Document_Details__c
            WHERE Loan_Application__c = :loanAppId
              AND (Name = 'CRIF' OR Document_Master__r.Name = 'CRIF')
              AND CreatedDate >= :Datetime.now().addDays(-60)
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (recent.isEmpty()) {
            res.okToFetch = true;
            res.lastCreated = null;
        } else {
            res.okToFetch = false;
            res.lastCreated = recent[0].CreatedDate;
        }
        return res;
    }
}