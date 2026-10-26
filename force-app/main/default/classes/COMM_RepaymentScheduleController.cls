public with sharing class COMM_RepaymentScheduleController {
    

    @AuraEnabled
    public static List<RepaymentScheduleWrapper.schedule> fetchSchedule(String recordId){
        try {
            Utility_V1.ProductWrapper wrp = Utility_V1.getProductDetails(new Map<String,String>{'oppId' => recordId});
            Boolean isHLRelated = wrp.isHLRelated;
            List<Loan_Transaction__c> loanTransaction = new List<Loan_Transaction__c>();
            Boolean stepLoan = false;
            system.debug('recordId:: '+recordId);
            //Integration_Details__c scheduleRecord = [Select id,Response_JSON__c from Integration_Details__c where Loan_Application__c =: recordId and Calling_Source__c = 'Loan Scheduler Create Charges' order by CreatedDate desc LIMIT 1 ];
            List<Integration_Details__c> scheduleRecord = [
                SELECT Id, Response_JSON__c, Eligibility_Status__c,Related_Record_Id__c,Object_Name__c 
                FROM Integration_Details__c 
                WHERE Loan_Application__c = :recordId AND Calling_Source__c = 'Loan Scheduler Create Charges' AND Object_Name__c ='Document_Details__c'
                order by CreatedDate desc LIMIT 1
            ];
            if(isHLRelated){
                loanTransaction = [Select Id,Step_Loan__c, Loan_Start_Date__c, Product__r.Product_Type__c, Product__c From Loan_Transaction__c Where Loan_Application__c =: recordId And RecordType.Name = 'Transaction Details' AND Product__c!=null AND Product__r.Product_Type__c = 'Parent' LIMIT 1];
            }
            else{
                loanTransaction = [Select Id,Step_Loan__c, Loan_Start_Date__c, Product__r.Product_Type__c, Product__c From Loan_Transaction__c Where Loan_Application__c =: recordId And RecordType.Name = 'Transaction Details' LIMIT 1];
            }
            if(!loanTransaction.isEmpty()){
                if(loanTransaction[0].Step_Loan__c == true){
                    stepLoan = true;
                }
            }

            //if(!scheduleRecord.isEmpty()){
                List<Document_Details__c> docLst= [SELECT id,createddate,Content_Document_Id__c,Applicant__c from Document_Details__c  where name = 'Loan Scheduler Response' AND Loan_Application__c = :recordId ORDER BY CreatedDate DESC LIMIT 1];
                List<ContentVersion> conversionLst = [SELECT id,VersionData,ContentDocumentId  FROM ContentVersion WHERE ContentDocumentId=:docLst[0].Content_Document_Id__c];
                
                String incomeResponse =conversionLst[0].VersionData.toString();
                system.debug('scheduleRecord:: '+scheduleRecord);
                if(incomeResponse.contains('overDueCharges')){                
                    String replaceOverDue = incomeResponse.replace('overDueCharges','overDueCharges1');
                    RepaymentScheduleWrapper repaymentDetails = (RepaymentScheduleWrapper) JSON.deserialize(replaceOverDue, RepaymentScheduleWrapper.class);
                    // Loop through each schedule and apply truncation where value > 0
                    for (Integer i = 0; i < repaymentDetails.schedules.size(); i++) {
                        RepaymentScheduleWrapper.schedule sch = repaymentDetails.schedules[i];
                        if (i == 0) {
                            sch.dueDate = null; // Make the first record's due date blank
                        }
                        if (sch.pftAmount > 0) sch.pftAmount = utility.truncateTwoZeros(sch.pftAmount);
                        if (sch.schdPft > 0) sch.schdPft = stepLoan ==true ? (sch.pftAmount) : (sch.schdPft == 0 ? utility.truncateTwoZeros(sch.profitBalance) : utility.truncateTwoZeros(sch.schdPft)); //condition changed as per discussion with Snigdha and Yash on Step loan case on 12th Feb 2025
                        if (sch.schdPftPaid > 0) sch.schdPftPaid = utility.truncateTwoZeros(sch.schdPftPaid);
                        if (sch.schdPri > 0) sch.schdPri = utility.truncateTwoZeros(sch.schdPri);
                        if (sch.schdPriPaid > 0) sch.schdPriPaid = utility.truncateTwoZeros(sch.schdPriPaid);
                        if (sch.feeSchd > 0) sch.feeSchd = utility.truncateTwoZeros(sch.feeSchd);
                        if (sch.tDSAmount > 0) sch.tDSAmount = utility.truncateTwoZeros(sch.tDSAmount);
                        if (sch.totalAmount > 0) sch.totalAmount = utility.truncateTwoZeros(sch.totalAmount);
                        if (sch.endBal > 0) sch.endBal = utility.truncateTwoZeros(sch.endBal);
                        if (sch.limitDrop > 0) sch.limitDrop = utility.truncateTwoZeros(sch.limitDrop);
                        if (sch.dropLineLimit > 0) sch.dropLineLimit = utility.truncateTwoZeros(sch.dropLineLimit);
                        if (sch.availableLimit > 0) sch.availableLimit = utility.truncateTwoZeros(sch.availableLimit);
                        if (sch.bpiAmount >0) sch.bpiAmount = utility.truncateTwoZeros(sch.bpiAmount);
                        sch.specifier = sch.specifier;
                    }
                    return repaymentDetails.schedules;
                }
            //}
            return null;
        } catch (Exception e) {
            System.debug('error message==>'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

     @AuraEnabled
    public static void saveOppStageChange(Id recordId, String loanStage) {
       
        try {
           Opportunity opp = [ SELECT Id, StageName FROM Opportunity WHERE Id=: recordId];
            opp.StageName = loanStage;
            update opp;

        } catch (Exception e) {
            System.debug('Error saving checklist records: ' + e.getMessage());
            throw new AuraHandledException('Error while saving records: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> checkRepaymentScheduleAPI(Id recordId) {
        try {
                Boolean shouldHitAPI = false;
                String message = null;
                Opportunity loanApp = [SELECT Is_Pricing_Approval_Required__c, Pricing_Approval_Status__c 
                                FROM Opportunity 
                                WHERE Id = :recordId 
                                LIMIT 1];

            // Scenario 1: Pricing approval is required
            if (loanApp.Is_Pricing_Approval_Required__c) { 
                // Check for pending approval process
                List<ProcessInstanceWorkitem> pendingApprovals = [
                    SELECT ActorId, Actor.Name, ProcessInstance.TargetObjectId 
                    FROM ProcessInstanceWorkitem 
                    WHERE ProcessInstance.TargetObjectId = :recordId 
                    AND ProcessInstance.Status = 'Pending' 
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
                // If no pending approvals and status is Approved, we should hit the API
                if (pendingApprovals.isEmpty() && loanApp.Pricing_Approval_Status__c == 'Approved') {
                    shouldHitAPI = true;
                }else{
                    shouldHitAPI = false;// If there are pending approvals or status is not Approved, we'll return without hitting API
                    // Set message when approval is pending or not yet approved
                    message = 'Pricing approval is still in progress. Repayment Schedule can be generated only once it is approved.';
                }
            }else {
                // Query Integration_Details__c based on specified criteria except Comments__c
                List<Integration_Details__c> integrationDetails = [
                    SELECT Id, Comments__c FROM Integration_Details__c 
                    WHERE EndPoint__c = 'Callout:Create_Schedule_Simulation_API_LOS' 
                    AND Loan_Application__c = :recordId 
                    AND Is_Success_Response__c = true 
                    AND Calling_Source__c = 'Loan Scheduler Create Charges'
                    AND Status__c = '200'
                ];

                // Filter records by Comments__c in Apex code
                Boolean hasValidIntegrationDetail = false;
                for (Integration_Details__c detail : integrationDetails) {
                    if (detail.Comments__c == 'RepaymentLWC') {
                        hasValidIntegrationDetail = true;
                        break;
                    }
                }
                if (hasValidIntegrationDetail) {
                    //return true;
                    shouldHitAPI = false;
                }else{
                    //return false;
                    shouldHitAPI = true;
                }
            }
            // Return a map containing both the decision to hit API and any existing document
            return new Map<String, Object>{
                'shouldHitAPI' => shouldHitAPI,
                'message' => message // Will be null unless the specific condition is met
            };                
        } catch (Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'RepaymentSchedule', '', '') });
            throw new AuraHandledException('Error: ' + e.getMessage());
        }   
    }

    /*@AuraEnabled(cacheable=true)
    public static String getProductNameForLoan(Id oppId) {
        List<Product2> products = [
            SELECT Name 
            FROM Product2 
            WHERE Loan_Application__c = :oppId 
            AND RecordType.Name = 'Sub Product' 
            LIMIT 1
        ];
        
        if (!products.isEmpty()) {
            return products[0].Name;
        }
        return null;
    }*/

    @AuraEnabled(cacheable=true)
    public static Product2 getProductNameForLoan(Id oppId) {

        Opportunity loanApplication = [ 
            SELECT Id, Product__c
            FROM Opportunity 
            WHERE Id = :oppId
            LIMIT 1
        ];
        // Step 1: Get Product2 with RecordType = 'Product' and Name = Product__c (picklist value)
        Product2 mainProduct = [
            SELECT Id,Name,Sanctioned_Loan_Amount__c
            FROM Product2
            WHERE RecordType.Name = 'Product' AND Name = :loanApplication.Product__c AND Loan_Application__c = :oppId
            LIMIT 1
        ];

        // Step 2: Get Sub Product (RecordType = 'Sub Product') under Product
        Product2 subProduct = [
            SELECT Id,Name,Sanctioned_Loan_Amount__c,Product__c
            FROM Product2
            WHERE RecordType.Name = 'Sub Product' AND Product__c = :mainProduct.Id AND Loan_Application__c = :oppId
            LIMIT 1
        ];

        // Step 3: Get Variant (RecordType = 'Variant') under Sub Product
        Product2 variant = [
            SELECT Id, Name,Sanctioned_Loan_Amount__c,Product__c,Product__r.Sanctioned_Loan_Amount__c
            FROM Product2
            WHERE RecordType.Name = 'Variant' AND Product__c = :subProduct.Id AND Loan_Application__c = :oppId
            LIMIT 1
        ];

        return variant;
    }

    @AuraEnabled
	public static Boolean canUserEdit(String opportunityId) {
		// Step 1: Fetch opportunity with sub-stage and stage
		Opportunity opp = [
			SELECT Id, StageName, Sub_stage__c
			FROM Opportunity
			WHERE Id = :opportunityId
			LIMIT 1
		];

        List<Loan_Transaction__c> loanTxn =
            [SELECT Id,
                    Quick_Disbursement__c,
                    QDP_Status__c,
                    STP__c,
                    RecordType.DeveloperName,
                    Loan_Application__c
             FROM   Loan_Transaction__c
             WHERE  Loan_Application__c = :opportunityId
             AND    RecordType.DeveloperName = 'Transaction_Details'
             LIMIT  1];

		final Boolean isQDP = !loanTxn.isEmpty() && loanTxn[0].Quick_Disbursement__c && loanTxn[0].QDP_Status__c == 'QDP-ONHOLD';

        if(opp.Sub_stage__c == 'Disbursed' || isQDP){
            return false;
        }

		// If not Disbursement stage or not Ops Maker sub-stage, return true (allow editing)
        if (opp.StageName != 'Disbursement' || (opp.Sub_stage__c != 'Ops Maker' && opp.Sub_stage__c != 'Ops Author')) {
			return true;
		}

		// Step 2: Fetch current user’s Opportunity Team Member record
		List<OpportunityTeamMember> teamMembers = [
			SELECT Id, UserId, TeamMemberRole, User.Is_OPS_Also__c
			FROM OpportunityTeamMember
			WHERE OpportunityId = :opp.Id AND UserId = :UserInfo.getUserId()
			LIMIT 1
		];

		// Step 3: Check if role is Ops Maker
		if (!teamMembers.isEmpty() && opp.Sub_stage__c == 'OPS Maker' && (teamMembers[0].TeamMemberRole == 'OPS Maker' || (teamMembers[0].TeamMemberRole == 'Credit Officer' && teamMembers[0].User.Is_OPS_Also__c))) {
			return true; // User can edit
		}

		return false; // Others can only preview
	}
}