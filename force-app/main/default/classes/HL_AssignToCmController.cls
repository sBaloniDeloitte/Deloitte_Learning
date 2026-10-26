public without sharing class HL_AssignToCmController {
    
    @AuraEnabled
    public static Map<Id, String> getCreditATMs(Id opportunityId) {
        System.debug('getCreditATMs called with Opp Id = ' + opportunityId);

        if (opportunityId == null) {
            throw new AuraHandledException('No Opportunity Id provided.');
        }

        Opportunity opp = [
            SELECT Id, Branch_Master__c 
            FROM Opportunity 
            WHERE Id = :opportunityId 
            LIMIT 1
        ];

        if (opp.Branch_Master__c == null) {
            throw new AuraHandledException('Opportunity has no Branch_Master__c set.');
        }

        List<AccountTeamMember> creditATMs = [
            SELECT Id, UserId, TeamMemberRole, User.Name
            FROM AccountTeamMember
            WHERE AccountId = :opp.Branch_Master__c
              AND TeamMemberRole = 'Credit'
              AND UserId != null
              AND level__c = 'L1'
        ];

        if (creditATMs.isEmpty()) {
            throw new AuraHandledException('No Credit team members found on this Branch.');
        }

        Map<Id, String> assigneeMap = new Map<Id, String>();
        for (AccountTeamMember atm : creditATMs) {
            assigneeMap.put(atm.UserId, atm.User.Name);
        }

        return assigneeMap;
    }

    @AuraEnabled
    public static void updateOwnerToCM(Id opportunityId, String cmUserId) {
        Utility.byPassOwnershipUpdate = true;
        utility.ahlOpportunityOwnerChangeByPass=true;
        System.debug('updateOwnerToCM called with Opp Id = ' + opportunityId + ', User Id = ' + cmUserId);

        if (opportunityId == null || cmUserId == null) {
            throw new AuraHandledException('Opportunity Id and User Id are required.');
        }

        Opportunity opp = [
            SELECT Id, OwnerId, Sub_Stage__c
            FROM Opportunity 
            WHERE Id = :opportunityId 
            LIMIT 1
        ];

        try {
            List<OpportunityTeamMember> existing = [
                SELECT Id
                FROM OpportunityTeamMember
                WHERE OpportunityId = :opp.Id
                  AND UserId = :cmUserId
                LIMIT 1
            ];

            if (existing.isEmpty()) {
                insert new OpportunityTeamMember(
                    OpportunityId = opp.Id,
                    UserId = cmUserId,
                    TeamMemberRole = 'Credit',
                    OpportunityAccessLevel = 'Edit'
                );
            }

            opp.OwnerId = cmUserId;
            opp.Sub_Stage__c = 'Credit in-progress';
            update opp;
            Utility.byPassOwnershipUpdate = false;

        } catch (DmlException dmx) {
            throw new AuraHandledException('Failed to reassign owner: ' + dmx.getMessage());
        }
    }

        public class ValidationResult {
        @AuraEnabled public String status;
        @AuraEnabled public String message;
    }

    @AuraEnabled()
    public static ValidationResult validateAPFCollateral(Id recordId) {
        ValidationResult res = new ValidationResult();

        try {
            // 1. Fetch collateral
            List<Application_Collateral__c> collList = [
                SELECT Id, Collateral__r.APF__c, Collateral__r.RERA_End_Date__c,
                       Collateral__r.Primary_Secondary__c
                FROM Application_Collateral__c
                WHERE HL_Loan_Application__c = :recordId
                      AND Collateral__r.IsActive__c = true
            ];

            if (collList.isEmpty()) {
                res.status = 'Success';
                res.message = 'Ok';
                return res;
            }

            // 2. Filter APF = Yes
            List<Application_Collateral__c> apfYes = new List<Application_Collateral__c>();
            for (Application_Collateral__c ac : collList) {
                if (ac.Collateral__r.APF__c == 'Yes') {
                    apfYes.add(ac);
                }
            }

            if (apfYes.isEmpty()) {
                res.status = 'Success';
                res.message = 'Ok';
                return res;
            }

            // 3. Select Primary
            Application_Collateral__c selectedColl;

            if (apfYes.size() == 1) {
                selectedColl = apfYes[0];
            } else {
                for (Application_Collateral__c ac : apfYes) {
                    if (ac.Collateral__r.Primary_Secondary__c == 'Primary') {
                        selectedColl = ac;
                        break;
                    }
                }
                if (selectedColl == null) selectedColl = apfYes[0];
            }

            // 4. RERA End Date check
            Date reraDate = selectedColl.Collateral__r.RERA_End_Date__c;

            if (reraDate == null) {
                res.status = 'ERROR';
                res.message = 'RERA End Date is not present in the APF Collateral.Please add in order to proceed.';
                return res;
            }

            // LOWER OF (RERA-2 months) OR (Today+48 months)
            Date reraMinus2Months = reraDate.addMonths(-2);
            Date fortyEightMonths = Date.today().addMonths(48);
            Date lowerOfValue;

            if (reraMinus2Months < Date.today()) {
                lowerOfValue = fortyEightMonths;
            } else {
                lowerOfValue = (reraMinus2Months < fortyEightMonths) ? reraMinus2Months : fortyEightMonths;
            }
            // 5. Get Hybrid Tenure products
            Id hybridRT = Schema.SObjectType.Product2.getRecordTypeInfosByName()
                .get('Hybrid Tenure').getRecordTypeId();

            List<Product2> productList = [
                SELECT Id, Name
                FROM Product2
                WHERE RecordTypeId = :hybridRT
                      AND Loan_Application__c = :recordId
            ];

            // 6. Validate tenure
            for (Product2 p : productList) {
                Integer months = Integer.valueOf(p.Name);
                Date prodDate = Date.today().addMonths(months);

                if (prodDate > lowerOfValue) {
                    res.status = 'ERROR';
                    // res.message = 'The Interest Only Tenure should be less than or equals to 48 months';
                    return res;
                }
            }

            // SUCCESS
            res.status = 'SUCCESS';
            res.message = 'OK';
            return res;

        } catch (Exception ex) {
            res.status = 'ERROR';
            res.message = ex.getMessage();
            return res;
        }
    }
}