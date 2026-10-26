public with sharing class HL_ApplicableOffersController {

    private static List<Campaign> fetchCampaigns(Id opportunityId) {
        Opportunity opp = [SELECT Id, Branch_Master__c, CreatedDate FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        if (opp.Branch_Master__c == null) {
            return new List<Campaign>();
        }
        String branchId = opp.Branch_Master__c;
        String searchKey = '%' + branchId + '%';
        DateTime oppCreatedDate = opp.CreatedDate;
        DateTime today = System.now();
        List<Campaign> potentialCampaigns = [SELECT Id, Name, Description, HL_Campaign_Start_Date_Time__c,HL_Campaign_End_Date_Time__c, HL_Impact_on_ROI__c,
                   HL_Impact_on_Processing_Fee__c, HL_Applicable_Branches__c FROM Campaign WHERE IsActive = true AND HL_Applicable_Branches__c LIKE :searchKey
            AND (HL_Campaign_Start_Date_Time__c = null OR HL_Campaign_Start_Date_Time__c <= :oppCreatedDate)
            AND (HL_Campaign_End_Date_Time__c = null OR HL_Campaign_End_Date_Time__c >= :oppCreatedDate)
            AND (HL_Campaign_End_Date_Time__c = null OR HL_Campaign_End_Date_Time__c >= :today)
            ORDER BY StartDate DESC];

        List<Campaign> filtered = new List<Campaign>();
        for (Campaign c : potentialCampaigns) {
            if (c.HL_Applicable_Branches__c != null) {
                Set<String> branchIdSet = new Set<String>(c.HL_Applicable_Branches__c.split(','));
                if (branchIdSet.contains(branchId)) {
                    filtered.add(c);
                }
            }
        }

        return filtered;
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean checkApplicableCampaigns(Id opportunityId) {
        return !fetchCampaigns(opportunityId).isEmpty();
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Campaign> getCampaignOffers(Id opportunityId) {
        return fetchCampaigns(opportunityId);
    }
    
    @AuraEnabled
    public static void saveSelectedOffer(Id opportunityId, Id campaignId, Decimal roiImpact, Decimal feeImpact) {
        try {
            Opportunity opp = new Opportunity(
                Id = opportunityId,
                HL_Selected_Campaign__c = campaignId,
                HL_Saved_Offer_ROI_Impact_Percent__c = roiImpact,
                HL_Is_Offer_Applied__c = true
            );
            update opp;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void removeSelectedOffer(Id opportunityId) {
        try {
            Opportunity opp = new Opportunity(
                Id = opportunityId,
                HL_Selected_Campaign__c = null,
                HL_Saved_Offer_ROI_Impact_Percent__c = null,
                HL_Is_Offer_Applied__c = false
            );
            update opp;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}