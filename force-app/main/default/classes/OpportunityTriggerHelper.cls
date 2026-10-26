/*
* Created By : Romesh Somani
* Created Date : 03/12/2024
* Purpose : Used to write all the logic for Opportunity. 
*/

public with sharing class OpportunityTriggerHelper implements ITriggerHandler{
    Boolean isTriggerDisabled = false;

    public static void beforeInsert(List<SObject> newList){
        List<Opportunity> newRecords = (List<Opportunity>)newList;
        Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(new Map<String,String>{});
        Boolean isHlRelated = isHLRelatedFinal.isHLRelated;
        String nowIso = Datetime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String userProfile = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1].Name;
        for(Opportunity itr : newRecords) {
            itr.Name = 'NA'; 
            itr.StageName = 'Sales Login';
            itr.CloseDate = Date.today();
            if(isHlRelated){
                itr.Loan_Eligible_for_PSL__c = 'No';
                itr.CRE_Tagging__c = 'No';
            }
            if(itr.StageName == 'Sales Login' && String.isBlank(itr.Owner_History__c)) {
                itr.Owner_History__c = OwnerLogUtil.composeInitial(itr.OwnerId, userProfile, nowIso);
            }
        }
    }

  public static void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems) {

        List<Opportunity> lmsRefRec = new List<Opportunity>();
        List<Opportunity> newRecords = (List<Opportunity>)newList;
        Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(new Map<String,String>{});
        Boolean isHlRelated = isHLRelatedFinal.isHLRelated;
        Set<Id> loanLeadIds = new Set<Id>();
        Map<Id,Opportunity> oldRecords = (Map<Id,Opportunity>)oldItems;
                        // CIBIL/CRIF Verification Check on Stage Change
Set<Id> stageChangedOppIds = new Set<Id>();

        OpportunityTriggerImplementation.validateManualOwnerChange(newRecords, oldRecords);
        String stageCreditUnderWriting = Constants__mdt.getInstance('STAGE_CREDITUNDERWRITING').value__c;
        String stagePSV = Constants__mdt.getInstance('STAGE_PSV').value__c;
        Profile currentProfile = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
        Set<Id> loanApplicationIds = new Set<Id>();
        Set<Id> fcuLoanIDs = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Map<Id, Product2> oppVsProductMap = new Map<Id, Product2>();
        String profileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
        ownerChangeSetting__c cs = ownerChangeSetting__c.getInstance();
        try {
            Set<Id> historyIds = new Set<Id>();
            for (Opportunity n : newRecords) {
                Opportunity o = oldRecords.get(n.Id);
                    if (o.StageName != n.StageName) {
        stageChangedOppIds.add(n.Id);
    }

                if (n.Opt_In__c == true &&
                   ( (o.StageName != n.StageName) ||
                     (String.valueOf(o.get('Sub_stage__c')) != String.valueOf(n.get('Sub_stage__c'))) ||
                     (o.OwnerId != n.OwnerId) )) {
                    historyIds.add(n.Id);
                }
            }

if (!stageChangedOppIds.isEmpty()) {
    OpportunityTriggerImplementation.verifyCIBIL(stageChangedOppIds, newRecords, oldRecords);
}

            if (!historyIds.isEmpty()) {
                Set<Id> ownerIds = new Set<Id>();
                for (Opportunity n : newRecords) {
                    if (historyIds.contains(n.Id) && n.OwnerId != null) ownerIds.add(n.OwnerId);
                }
                Map<Id, User> usersById = ownerIds.isEmpty() ? new Map<Id, User>() : new Map<Id, User>([SELECT Id, Profile.Name FROM User WHERE Id IN :ownerIds]);
                String nowIso = Datetime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                for (Opportunity n : newRecords) {
                    if (!historyIds.contains(n.Id)) continue;
                    User currOwner = (n.OwnerId != null ? usersById.get(n.OwnerId) : null);
                    String currProfile = (currOwner != null && currOwner.Profile != null) ? currOwner.Profile.Name : '';
                    String existing = n.Owner_History__c;
                    OwnerLogUtil.InitialInfo init = OwnerLogUtil.parseInitial(existing);
                    if (init == null) {n.Owner_History__c = OwnerLogUtil.composeInitial(n.OwnerId, currProfile, nowIso) + '\n' + (String.isBlank(existing) ? '' : existing); existing = n.Owner_History__c;
                    } 
                    else {
                        Boolean isSales = (!String.isBlank(currProfile) && currProfile.toLowerCase().contains('sales'));
                        if (isSales && (init.userId != String.valueOf(n.OwnerId))) {
                            n.Owner_History__c = OwnerLogUtil.replaceInitial(existing, n.OwnerId, currProfile, nowIso);
                            existing = n.Owner_History__c;
                        }
                    }
                    n.Owner_History__c = OwnerLogUtil.upsertCurrent(existing,n.StageName, (String)n.get('Sub_stage__c'), n.OwnerId, currProfile, nowIso);
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'beforeUpdate owner history build failed: ' + e.getMessage());
        }
        for (Opportunity opp : newRecords) {
            Opportunity oldOpp = oldRecords.get(opp.Id);
            if(opp.FCU_Status__c != oldOpp.FCU_Status__c ){
				if(opp.FCU_Status__c == 'FCU Completed'){
                    opp.FCU_Completion_Date__c = System.now();
                }
            }
            if ((currentProfile.Name != 'System Administrator') && opp.Sub_stage__c == 'Disbursed' && opp.Sub_stage__c == oldOpp.Sub_stage__c) {
                opp.addError('You are not allowed to edit this record at Disbursed substage.');
            }
            if ((oldOpp.StageName != opp.StageName && opp.StageName == 'Disbursement' && oldOpp.StageName == 'PSV') ||
                (oldOpp.Sub_stage__c != opp.Sub_stage__c && opp.Sub_stage__c == 'PSV Credit' && oldOpp.Sub_stage__c == 'PSV Sales')) {
                loanApplicationIds.add(opp.Id);
            }
            if (oldOpp.StageName == stageCreditUnderWriting && opp.StageName == stagePSV && oldRecords.containsKey(opp.Id) && oldOpp.StageName != opp.StageName) {
                oppIds.add(opp.Id);
                opp.Negotiated_Loan_Amount__c = opp.Sanction_Loan_Amount__c;
                opp.Negotiated_Tenure__c = opp.Sanction_Tenure__c;
                if(opp.Pricing_Approval_Status__c != 'Approved'){
                opp.Negotiated_Rate_Of_Interest__c = opp.Sanction_Rate_Of_Interest__c;
                }
                System.debug('Updated Negotiated Loan Amount: ' + opp.Negotiated_Loan_Amount__c);
            }
            if (String.isBlank(oldOpp.LMS_Loan_Reference__c) && String.isNotBlank(opp.LMS_Loan_Reference__c) && String.isNotBlank(opp.Lead__c)) {
                lmsRefRec.add(opp);
                loanLeadIds.add(opp.Lead__c);
            }
           
            // Sanwar - Start (allowed fields at PSV/Disbursement)
            if ((opp.StageName == 'PSV' || opp.StageName == 'Disbursement') && (currentProfile.Name != 'System Administrator')) {
                Boolean stageUnchanged = opp.StageName == oldOpp.StageName;
                Boolean allowedFieldChanged = 
                        opp.Final_Amount__c != oldOpp.Final_Amount__c ||
                        opp.Final_Tenure__c != oldOpp.Final_Tenure__c || 
                        opp.Final_Rate_Of_Interest__c != oldOpp.Final_Rate_Of_Interest__c || 
                        opp.Negotiated_Loan_Amount__c != oldOpp.Negotiated_Loan_Amount__c || 
                        opp.Negotiated_Tenure__c != oldOpp.Negotiated_Tenure__c || 
                        opp.Negotiated_Rate_Of_Interest__c != oldOpp.Negotiated_Rate_Of_Interest__c || 
                        opp.Eligible_for_Resanction__c != oldOpp.Eligible_for_Resanction__c || 
                        opp.Is_Pricing_Approval_Required__c != oldOpp.Is_Pricing_Approval_Required__c || 
                        opp.Pricing_Approval_Status__c != oldOpp.Pricing_Approval_Status__c || 
                        opp.APR__c != oldOpp.APR__c || 
                        opp.Sub_stage__c != oldOpp.Sub_stage__c ||
                        opp.EMI_Amount_Repayment_Schedule__c != oldOpp.EMI_Amount_Repayment_Schedule__c ||
                        opp.Allow_OCR__c != oldOpp.Allow_OCR__c ||
                        opp.Stamp_Paper__c != oldOpp.Stamp_Paper__c || 
                        opp.Total_Stamp_Duty__c != oldOpp.Total_Stamp_Duty__c ||
                        opp.E_seal_Colour__c != oldOpp.E_seal_Colour__c ||
                        opp.E_seal_Generated__c != oldOpp.E_seal_Generated__c ||
                        opp.E_seal_Inner_Name__c != oldOpp.E_seal_Inner_Name__c ||
                        opp.E_Seal_Outer_Name__c != oldOpp.E_Seal_Outer_Name__c ||
                        opp.E_seal_Shape__c != oldOpp.E_seal_Shape__c ||
                        opp.Authorized_Signatory__c != oldOpp.Authorized_Signatory__c ||                        
                        opp.LMS_Effective_Rate_of_Return__c != oldOpp.LMS_Effective_Rate_of_Return__c ||
                        opp.LMS_Loan_Reference__c != oldOpp.LMS_Loan_Reference__c ||
                        opp.DocGen_Status__c != oldOpp.DocGen_Status__c ||
                        opp.Non_Mandatory_DocGen_Status__c != oldOpp.Non_Mandatory_DocGen_Status__c ||
                        opp.DocGen_Initiated_Time__c != oldOpp.DocGen_Initiated_Time__c ||
                        opp.Type_of_Signature__c != oldOpp.Type_of_Signature__c ||
                        opp.Resanctioned_Loan__c != oldOpp.Resanctioned_Loan__c ||
                        opp.Resanction_Remarks__c != oldOpp.Resanction_Remarks__c ||
                        opp.Recredit_Multiproduct__c != oldOpp.Recredit_Multiproduct__c ||
                        opp.Sanction_Loan_Amount__c != oldOpp.Sanction_Loan_Amount__c ||
                        opp.Sanction_Rate_Of_Interest__c != oldOpp.Sanction_Rate_Of_Interest__c ||
                        opp.Sanction_Tenure__c != oldOpp.Sanction_Tenure__c ||
                        opp.Emi_amount__c != oldOpp.Emi_amount__c || 
                        opp.OwnerId != oldOpp.OwnerId ||
                        opp.Overall_FCU_Verification__c != oldOpp.Overall_FCU_Verification__c ||
                        opp.FCU_Status__c != oldOpp.FCU_Status__c || 
                        opp.HL_Area_Manager__c != oldOpp.HL_Area_Manager__c || 
                        opp.HL_Relationship_Manager__c != oldOpp.HL_Relationship_Manager__c ||
                        opp.HL_DST__c != oldOpp.HL_DST__c || 
                        opp.Child_Ext_Reference__c!= oldOpp.Child_Ext_Reference__c||
                        opp.Verified_By_Credit_Manager__c!=oldOpp.Verified_By_Credit_Manager__c;

                if (stageUnchanged && !allowedFieldChanged) {
                    Boolean otherFieldsChanged = false;
                    for (String fieldName : opp.getSObjectType().getDescribe().fields.getMap().keySet()) {
                        if (opp.get(fieldName) != oldOpp.get(fieldName) &&
                            fieldName != 'StageName' &&
                            !new Set<String>{
                                'EMI_Amount_Repayment_Schedule__c','HL_Area_Manager__c','HL_Relationship_Manager__c','HL_DST__c','Eligible_for_Resanction__c','Is_Pricing_Approval_Required__c','APR__c',
                                'Final_Rate_Of_Interest__c','Final_Tenure__c','Negotiated_Tenure__c',
                                'Final_Amount__c','Negotiated_Loan_Amount__c','Negotiated_Rate_Of_Interest__c','Pricing_Approval_Status__c','Sub_stage__c','Allow_OCR__c',
                                'Total_Stamp_Duty__c','Stamp_Paper__c','E_seal_Colour__c','E_seal_Generated__c','E_seal_Inner_Name__c','E_Seal_Outer_Name__c',
                                'E_seal_Shape__c','Authorized_Signatory__c', 'DocGen_Status__c', 'Non_Mandatory_DocGen_Status__c',
                                'LMS_Effective_Rate_of_Return__c','LMS_Loan_Reference__c', 'DocGen_Initiated_Time__c','Type_of_Signature__c',
                                'Resanctioned_Loan__c','Resanction_Remarks__c','Recredit_Multiproduct__c','Sanction_Loan_Amount__c',
                                'Sanction_Rate_Of_Interest__c','Sanction_Tenure__c','Emi_amount__c','OwnerId','Disposition__c','Overall_FCU_Verification__c','FCU_Status__c', 'Child_Ext_Reference__c', 'Verified_By_Credit_Manager__c'
                            }.contains(fieldName)) {
                            otherFieldsChanged = true;
                            break;
                        }
                    }
                    if (otherFieldsChanged) {
                        opp.addError(profileName + ' users are not allowed to edit Loan Application when stage is ' + opp.StageName);
                    }
                }
            }
            // Sanwar - End

            system.debug('inside fcu oldOpp.Overall_FCU_Verification__c  '+oldOpp.Overall_FCU_Verification__c);
            system.debug('inside fcu opp.Overall_FCU_Verification__c  '+opp.Overall_FCU_Verification__c);
            system.debug('inside fcu oldOpp.FCU_Status__c  '+oldOpp.FCU_Status__c);
            system.debug('inside fcu opp.FCU_Status__c  '+opp.FCU_Status__c);

            if ((oldOpp.Overall_FCU_Verification__c != opp.Overall_FCU_Verification__c && opp.Overall_FCU_Verification__c == 'Positive') ||
                (oldOpp.FCU_Status__c != opp.FCU_Status__c && opp.FCU_Status__c == 'FCU Completed')) {
                system.debug('inside fcu if');
                fcuLoanIDs.add(opp.Id);
            } else{
                system.debug('inside fcu else');
            }
        }

        if (!lmsRefRec.isEmpty()) {
            OpportunityTriggerImplementation.createPayoutRecord(lmsRefRec, loanLeadIds);
        }

        if (!loanApplicationIds.isEmpty()) {
            List<Product2> parentSubproducts = [
                SELECT Product__r.Loan_Application__c, Product__r.Loan_Application__r.Loan_Hierarchy__c, Name
                FROM Product2 WHERE RecordType.Name = 'Sub Product' AND Product__r.Loan_Application__c IN :loanApplicationIds AND Product__r.Product_Type__c = 'Child'
            ];
            List<Document_Details__c> sanctionLetters = [
                SELECT Id, Loan_Application__c FROM Document_Details__c WHERE Loan_Application__c IN :loanApplicationIds AND Name = 'Sanction Letter' AND Active__c = true ORDER BY CreatedDate DESC
            ];

            Map<Id, Boolean> loanIdVsDocumentDetailMap = new Map<Id, Boolean>();
            Map<Id, String>  loanIdVsLoanHierarchyMap = new Map<Id, String>();

            for (Document_Details__c record : sanctionLetters) {
                loanIdVsDocumentDetailMap.put(record.Loan_Application__c, true);
            }
            for (Product2 parentSubProd : parentSubproducts) {
               loanIdVsLoanHierarchyMap.put(parentSubProd.Product__r.Loan_Application__c, parentSubProd.Product__r.Loan_Application__r.Loan_Hierarchy__c);
            }
            for (Opportunity opp : newRecords) {
                if (!loanIdVsDocumentDetailMap.containsKey(opp.Id)) {
                    opp.addError('Sanction Letter is not yet generated for the application to move to Disbursement.');
                }
                if (opp.Loan_Hierarchy__c != 'Child' && loanIdVsLoanHierarchyMap.containsKey(opp.Id) && loanIdVsLoanHierarchyMap.get(opp.Id) != 'Parent') {
                    opp.addError('Please split the loan application before moving to next stage.');
                }
            }
        }

        if (!oppIds.isEmpty()) {
            List<Product2> products = [
                SELECT Product__r.Loan_Application__c, Name, Sanctioned_Loan_Amount__c, Sanctioned_Tenor__c, Sanctioned_ROI__c, EMI_Amount__c, Valuation__c, FOIR__c, LTV__c, Total_ProposedExposure__c, Product__r.Name
                FROM Product2 WHERE RecordType.Name = 'Sub Product' AND Product__r.Loan_Application__c IN :oppIds AND Product__r.Product_Type__c = 'Parent'
            ];

            if (products != null && !products.isEmpty()) {
                for (Product2 prod : products) {
                    if(!isHlRelated){
                        if(prod.Product__r.Name != 'Flexi Loan'){
                            oppVsProductMap.put(prod.Product__r.Loan_Application__c, prod);
                        } 
                    }
                    else{
                        oppVsProductMap.put(prod.Product__r.Loan_Application__c, prod);
                    }
                }
            }
            for (Opportunity opp : newRecords) {
                Opportunity oldOpp = oldRecords.get(opp.Id);
                if (opp.Pricing_Approval_Status__c != 'Approved' && opp.StageName == stagePSV && oldOpp.StageName == stageCreditUnderWriting && oldRecords.containsKey(opp.Id) &&
                oldOpp.StageName != opp.StageName && oppVsProductMap != null && !oppVsProductMap.isEmpty() && oppVsProductMap.containsKey(opp.Id)) {
                    opp.Sanction_Rate_Of_Interest__c = oppVsProductMap.get(opp.Id)?.Sanctioned_ROI__c;
                    opp.Sanction_Loan_Amount__c = oppVsProductMap.get(opp.Id)?.Sanctioned_Loan_Amount__c;
                    opp.Sanction_Tenure__c = oppVsProductMap.get(opp.Id)?.Sanctioned_Tenor__c;
                    opp.Emi_amount__c = oppVsProductMap.get(opp.Id)?.EMI_Amount__c;
                }
            }
        }

        if (!fcuLoanIDs.isEmpty()) {
            List<Document_Details__c> fcuDocuments = [
                SELECT Id, Name, Screening_Status__c, Content_Document_Id__c, Loan_Application__c FROM Document_Details__c
                WHERE Loan_Application__c IN :fcuLoanIDs
                AND Active__c = true 
                AND Content_Document_Id__c != null
                AND Requirement_Level__c != null
                AND Active__c = true
                AND Eligible_For_FCU__c = true ORDER BY CreatedDate DESC
            ];

            Map<Id, Boolean> loanIdVsDocumentDetailMapFCU = new Map<Id, Boolean>();

            for (Document_Details__c record : fcuDocuments) {
                if (record.Screening_Status__c == 'Recommended For FCU') {
                    loanIdVsDocumentDetailMapFCU.put(record.Loan_Application__c, true);
                }
            }

            for (Opportunity opp : newRecords) {
                if (loanIdVsDocumentDetailMapFCU.containsKey(opp.Id)) {
                    opp.addError('Please take an action on all the documents available for screening');
                }
            }
        }

    }


    public static void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){

    } 
 
    public static void afterInsert(List<SObject> newList, Map<Id, SObject> newMap){
        List<Opportunity> newRecords = (List<Opportunity>)newList;
        OpportunityTriggerImplementation.setOpportunityName(newRecords);
        Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(new Map<String,String>{});
        Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
        if(isHLRelated){
		    OpportunityTriggerImplementation.createOpportunityTeamMembers(newRecords);
        }
        List<Opportunity> stageChangeOps = new List<Opportunity>();
        for(Opportunity newOp : newRecords){
            if(newOp.StageName != null && newOp.StageName != ''){
                stageChangeOps.add(newOp);
            }
        }
        if(stageChangeOps.size()>0){
            OpportunityTriggerImplementation.addAndUpdateStageTATRecords(stageChangeOps, null);
        }
    }

    public static void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){        
        List<Opportunity> newRecords = (List<Opportunity>)newList;
        Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>)oldItems;
        Map<Id,Opportunity> oldRecords = (Map<Id,Opportunity>)oldItems;
        Set<Id> passVal = new Set<Id>(); 
        Set<Id> esignIds = new Set<Id>(); 
        Set<Id> loginToCredit= new Set<Id>();
        Set<Id> subStageIds = new Set<Id>();
        Set<Id> psvToOPSMakerIds = new Set<Id>();
        Set<Id> opsMakerToOpsAuthorIds = new Set<Id>();
        Set<Id> loanApplicationsFromSalesToCredit = new Set<Id>();
        Set<Id> pricingApprovedOps = new Set<Id>();
        Set<Id> pricingRejectedOps = new Set<Id>();
        List<Opportunity> stageChangeOps = new List<Opportunity>();
        Map<Id, Opportunity> stageChangeOldOps= new Map<Id, Opportunity>();
        Map<Id, Opportunity> stageChangeSalesToCred= new Map<Id, Opportunity>();
 
        List<Opportunity> subStageChangeOps = new List<Opportunity>();
        Map<Id, Opportunity> subStageChangeOldOps= new Map<Id, Opportunity>();
        List<String> loanBookedIds= new List<String>();
        Set<Id> loansToRemainUnassigned = new Set<Id>();
        List<String> loanRejectedIds= new List<String>();
       	Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(new Map<String,String>{});
        Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
        if(isHlRelated) {
            List<Opportunity> allocationRequiredOpportunities = LoanApplicationAllocation.isAllocationRequired(newRecords,oldMap);
            if(!allocationRequiredOpportunities.isEmpty()){
                LoanApplicationAllocation.runAllocationLogic(allocationRequiredOpportunities, oldMap);
            }
        }
        else {
        List<Opportunity> needAllocationOpps = LoanApplicationAllocation.checkIfSandBackCase(newRecords, oldMap);
        system.debug('needAllocationOpps>>>>'+needAllocationOpps);
        if(needAllocationOpps.size() > 0) {
            LoanApplicationAllocation.runAllocationLogic(needAllocationOpps, oldMap);
        }
        }
        for(Opportunity opp : newRecords){
            Opportunity oldOpp = oldRecords.get(opp.Id);
            if(opp.StageName!=oldOpp.StageName || opp.Sub_stage__c!=oldOpp.Sub_stage__c){
                passVal.add(opp.Id);
            }
            if(opp.StageName!=oldOpp.StageName && opp.StageName == 'Disbursement'){
                esignIds.add(opp.Id);
            }
            if(opp.Sub_stage__c != oldOpp.Sub_stage__c && opp.Sub_stage__c == 'Ops Maker'){
                subStageIds.add(opp.Id);
            }
            if(opp.StageName!=oldOpp.StageName && opp.StageName == 'Credit Underwriting' && oldOpp.StageName == 'Sales login'){
                loginToCredit.add(opp.Id);
                loanApplicationsFromSalesToCredit.add(opp.Id);
                stageChangeSalesToCred.put(opp.Id,opp);
            }
            if(opp.Sub_stage__c != oldOpp.Sub_stage__c && opp.Sub_stage__c == 'Ops Maker' && oldOpp.Sub_stage__c == 'PSV Sales'){//Sanwar -Start
                psvToOPSMakerIds.add(opp.Id);
            }
            if(opp.Sub_stage__c != oldOpp.Sub_stage__c && opp.Sub_stage__c == 'Ops Author' && oldOpp.Sub_stage__c == 'Ops Maker'){
                COMM_SanctionLetterController.initiateAPIRequestForColending(opp.Id);
                loanApplicationCallout.sendLoanApplicationfuture(opp.Id, 'bajaj finance ltd'); 
                opsMakerToOpsAuthorIds.add(opp.Id);
            }

            if(oldOpp.Pricing_Approval_Status__c != opp.Pricing_Approval_Status__c){
                if(opp.Pricing_Approval_Status__c == 'Approved'){
                    pricingApprovedOps.add(opp.Id);
                }
                if(opp.Pricing_Approval_Status__c == 'Rejected'){
                    pricingRejectedOps.add(opp.Id);
                }
           
        }

        
            if(opp.StageName != oldMap.get(opp.Id).StageName && opp.StageName != '' && opp.StageName != null){
                stageChangeOps.add(opp);
                stageChangeOldOps.put(opp.Id, oldMap.get(opp.Id));
            }
            if(opp.Sub_Stage__c != oldMap.get(opp.Id).Sub_Stage__c && opp.Sub_Stage__c!= '' && opp.StageName != null){
                subStageChangeOps.add(opp);
                subStageChangeOldOps.put(opp.Id, oldMap.get(opp.Id));
            }
            if(opp.LMS_Loan_Reference__c!= oldMap.get(opp.Id).LMS_Loan_Reference__c && opp.LMS_Loan_Reference__c!= null && opp.LMS_Loan_Reference__c!= ''){
                loanBookedIds.add(opp.Id);
            }

            if (opp.Approval_Status__c != oldMap.get(opp.Id).Approval_Status__c && opp.Approval_Status__c != null && opp.Approval_Status__c != '') {
                if (opp.Approval_Status__c == 'Hard Rejected' || opp.Approval_Status__c == 'Soft Rejected 1' || opp.Approval_Status__c == 'Soft Rejected 2') {
                    loanRejectedIds.add(opp.Id);
                }
                
            }
        }
 
        if(stageChangeOps.size()>0){
            OpportunityTriggerImplementation.addAndUpdateStageTATRecords(stageChangeOps, stageChangeOldOps);
        }
 
        if(subStageChangeOps.size()>0){
            OpportunityTriggerImplementation.addAndUpdateSubStageTATRecords(subStageChangeOps, subStageChangeOldOps);
        }
        if(loanBookedIds.size()>0){
            OpportunityTriggerImplementation.loanBookingTAT(loanBookedIds);
        }

        if (loanRejectedIds.size() > 0) {
            OpportunityTriggerImplementation.loanRejectionTAT(loanRejectedIds);
        }
        if(!loansToRemainUnassigned.isEmpty()){
            OpportunityTriggerImplementation.makeLoansUnassigned(loansToRemainUnassigned);
        }

        if(!pricingApprovedOps.isEmpty()){
            OpportunityTriggerImplementation.updateProductsBasedOnStatus(pricingApprovedOps,true);

        }
        if(!pricingRejectedOps.isEmpty()){
            OpportunityTriggerImplementation.updateProductsBasedOnStatus(pricingRejectedOps,false);
        }
        if(!pricingApprovedOps.isEmpty()){
            OpportunityTriggerImplementation.callCalculateGSTForApprovedOpportunities(pricingApprovedOps,true);//Sanwar
        
        }
        if(!pricingRejectedOps.isEmpty()){
            OpportunityTriggerImplementation.callCalculateGSTForApprovedOpportunities(pricingRejectedOps,false);//Sanwar
        }
       
        if(!psvToOPSMakerIds.isEmpty()){
            OpportunityUtility.createSantionLetterEventRecord(psvToOPSMakerIds, false);
        }
        if(!opsMakerToOpsAuthorIds.isEmpty()){
            OpportunityUtility.createSantionLetterEventRecord(opsMakerToOpsAuthorIds, true);
        }

        if(!passVal.isEmpty()){
            OpportunityTriggerImplementation.shareDocumentsWithOpportunityTeam(passVal);
        }
        if(!esignIds.isEmpty()){
            OpportunityTriggerImplementation.insertDocumentDetailsAndLinks(esignIds);
        }
        if(!subStageIds.isEmpty()){
            OpportunityTriggerImplementation.updateExistingCustomer(subStageIds);
        }
        if(!loginToCredit.isEmpty()){
                        OpportunityTriggerImplementation.handleVerifiedByCOFlag(loginToCredit);

            OpportunityTriggerImplementation.createDefaultsanctioncondtition(loginToCredit);
        }
        if(!loanApplicationsFromSalesToCredit.isEmpty()){ //Pavan
            OpportunityTriggerImplementation.createdocusignsForCreditFromSalesLogin(loginToCredit);
        }
        if(stageChangeSalesToCred.size() > 0) {
             OpportunityTriggerImplementation.grantDocumentAccess(stageChangeSalesToCred);
        } 
        
    }
    public static void afterDelete( List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public static void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap){}
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }

    
}