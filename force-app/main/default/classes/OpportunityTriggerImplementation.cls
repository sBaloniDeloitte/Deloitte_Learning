/**
 * @description       :  
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-20-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class OpportunityTriggerImplementation {

        public static void verifyCIBIL(Set<Id> stageChangedOppIds, List<Opportunity> newRecords, Map<Id, Opportunity> oldRecords) {
    // Query applicants where CIBIL/CRIF score is null or 0
    List<Application_Applicant__c> applicantsWithoutCIBIL = [
        SELECT Id, Loan_Application__c, Applicant_Type__c, Customer_Type__c, CIBIL_Score__c
        FROM Application_Applicant__c
        WHERE Loan_Application__c IN :stageChangedOppIds
          AND Applicant_Type__c IN ('Primary Applicant', 'Co Applicant')
          AND Customer_Type__c = 'Individual'
          AND CIBIL_Score__c = null
    ];

    // Map oppId -> count of applicants missing CIBIL
    Map<Id, Integer> oppIdVsMissingCIBILCount = new Map<Id, Integer>();
    for (Application_Applicant__c applicant : applicantsWithoutCIBIL) {
        if (!oppIdVsMissingCIBILCount.containsKey(applicant.Loan_Application__c)) {
            oppIdVsMissingCIBILCount.put(applicant.Loan_Application__c, 0);
        }
        oppIdVsMissingCIBILCount.put(
            applicant.Loan_Application__c,
            oppIdVsMissingCIBILCount.get(applicant.Loan_Application__c) + 1
        );
    }

    // Throw error on opportunities with missing CIBIL scores
    for (Opportunity opp : newRecords) {
        Opportunity oldOpp = oldRecords.get(opp.Id);
        if (oldOpp.StageName != opp.StageName && oppIdVsMissingCIBILCount.containsKey(opp.Id) && oppIdVsMissingCIBILCount.get(opp.Id) > 0) {
            opp.addError('Please fetch CRIF or CIBIL for all the applicants before moving forward!');
        }
    }
}

     public static void handleVerifiedByCOFlag(Set<Id> loanIds) {
        if (loanIds == null || loanIds.isEmpty()) {
            return;
        }
        
        List<Opportunity> loans = [SELECT Id, Name, Documents_Verified_By_CO__c,
                                          (SELECT Id, Customer_Profile__c, Applicant_Type__c
                                           FROM Application_Applicant__r
                                           WHERE (Customer_Profile__c = 'Salaried NRI'
                                                  OR Customer_Profile__c = 'Salaried Indian')
                                           AND Applicant_Type__c = 'Primary Applicant')
                                   FROM Opportunity
                                   WHERE Id IN :loanIds
                                   AND Product__c = 'Home Loan'];
        
        List<Opportunity> toUpdate = new List<Opportunity>();
        for (Opportunity o : loans) {
            List<Application_Applicant__c> applicants = o.Application_Applicant__r;
            Boolean hasPrimaryMatchingApplicant = (applicants != null && !applicants.isEmpty());
            if (hasPrimaryMatchingApplicant) {
                o.Documents_Verified_By_CO__c = hasPrimaryMatchingApplicant;
                toUpdate.add(o);
            }
        }
        
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
    //Sanwar added
    public static void callCalculateGSTForApprovedOpportunities(Set<Id> oppIds, Boolean isApproved) {
        List<Login_Fees__mdt> loginFeesMdt = [SELECT DeveloperName, Charge_Name__c, Is_GST_Applicable__c, Is_Waiver__c FROM Login_Fees__mdt WHERE Is_Waiver__c = true LIMIT 100];
        Set<String> proNameWithGST = new Set<String>();
        Set<String> proNameWithOutGST = new Set<String>();
        if(!loginFeesMdt.isEmpty()){
            for (Login_Fees__mdt loginFeeObj : loginFeesMdt) {
                if(loginFeeObj.Is_GST_Applicable__c){
                    proNameWithGST.add(loginFeeObj.Charge_Name__c);
                }
                else{
                    proNameWithOutGST.add(loginFeeObj.Charge_Name__c);
                }
            }
        }
        if(!proNameWithOutGST.isEmpty()){
            List<Charges_Insurance__c> chargesInsuranceListWithoutGST = [SELECT Id, Name, Loan_Application__c, Final_Amount_INR__c, Is_Charges_waived__c, Product__c, Tax_INR__c, Waived_Charge_Amount__c, Balance_Fees__c, Category__c, Requested_Percentage__c FROM Charges_Insurance__c WHERE Loan_Application__c IN :oppIds AND Name IN :proNameWithOutGST AND Is_Charges_waived__c = true LIMIT 100];

            List<Charges_Insurance__c> updatedCI = new List<Charges_Insurance__c>();
            for(Charges_Insurance__c rec: chargesInsuranceListWithoutGST){
                if(isApproved){
                    if(rec.Category__c == 'LOS'){
                        rec.Final_Amount_INR__c = rec.Balance_Fees__c - rec.Waived_Charge_Amount__c;
                    }
                    else if(rec.Category__c == 'LMS'){
                        rec.Final_Amount_INR__c = rec.Requested_Percentage__c - rec.Waived_Charge_Amount__c;
                    }
                } else {
                    rec.Waived_Charge_Amount__c = null;
                }
                rec.Is_Charges_waived__c = false;
                updatedCI.add(rec);
            }
            if(!updatedCI.isEmpty()){
                update updatedCI;
            }
        }

        if(!proNameWithGST.isEmpty()){
            List<Charges_Insurance__c> chargesInsuranceList = [SELECT Id, Name, Loan_Application__c, Is_Charges_waived__c, Product__c, Tax_INR__c, Waived_Charge_Amount__c, Balance_Fees__c FROM Charges_Insurance__c WHERE Loan_Application__c IN :oppIds AND Name IN :proNameWithGST AND Is_Charges_waived__c = true LIMIT 100];//sanwar
            if(!chargesInsuranceList.isEmpty()){
                OpportunityTriggerImplementation.processChargesInsurance(oppIds, proNameWithGST, isApproved);
            }
        }
    }

    @future(callout=true)
    public static void processChargesInsurance(Set<Id> oppIds, Set<String> proName, Boolean isApproved) {
        try {
            List<Charges_Insurance__c> chargesInsuranceList = [
                SELECT Id, Name, Loan_Application__c, Product__c, Tax_INR__c, 
                       Waived_Charge_Amount__c, Balance_Fees__c, Is_Charges_waived__c
                FROM Charges_Insurance__c 
                WHERE Loan_Application__c IN :oppIds 
                AND Name IN :proName 
                LIMIT 100
            ];

            if(!chargesInsuranceList.isEmpty()){
                List<Charges_Insurance__c> chargesInsuranceToUpdate = new List<Charges_Insurance__c>();//sanwar
                for (Charges_Insurance__c chargesInsurance : chargesInsuranceList) {
                    if(chargesInsurance.Is_Charges_waived__c)//sanwar
                    {
                        try {
                            Map<String, String> inputMap = new Map<String, String>();
                            inputMap.put('loanId', chargesInsurance.Loan_Application__c);
                            inputMap.put('processName', 'CalculateGST');
                            inputMap.put('productName', chargesInsurance.Product__c);
                            inputMap.put('feeType', chargesInsurance.Name);
                            inputMap.put('isWaiverAmountCalc', 'false');

                            String response = AHL_CalculateGstController.initiateAPIRequest(inputMap);
                            System.debug('Response :: ' + response);
                            if(!isApproved){
                                chargesInsurance.Waived_Charge_Amount__c = null;
                            }
                            chargesInsurance.Is_Charges_waived__c = false;//sanwar
                            chargesInsuranceToUpdate.add(chargesInsurance);//sanwar
                        } catch (Exception e) {
                            System.debug('GST API failed | Error: ' + e.getMessage());
                        }
                    }
                }
                if(!chargesInsuranceToUpdate.isEmpty()){//sanwar
                    update chargesInsuranceToUpdate;
                }
            }
        } catch (Exception e) {
            System.debug('Error in processChargesInsurance Future Method: ' + e.getMessage());
        }
    }
    
    public static void makeLoansUnassigned(Set<Id> loanIds){
        try{
            List<Opportunity> updatedLoans = new List<Opportunity>();
        for(Id oppId : loanIds){
            Opportunity opp = new Opportunity();
            opp.Id = oppId;
            opp.Is_Loan_Unassigned__c = true;
            opp.Loan_Unassigned_DateTime__c = Datetime.now();
            updatedLoans.add(opp);

        }
        if(!updatedLoans.isEmpty()){
            update updatedLoans;
        }

        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static void createOpportunityTeamMembers(List<Opportunity> oppList){
        try{
            Id userId = UserInfo.getUserId();
            User currentUser = [SELECT Profile.Name FROM User WHERE Id = :userId];
            String profileName = currentUser.Profile.Name;
            System.debug('profileName>>>>'+profileName);
            Map<string, OpportunityTeamMember> salesOppTeamMemberList = new Map<string, OpportunityTeamMember>();
            if(profileName == 'D2C') {
                Map<Id, Id> oppToLeadMap = new Map<Id, Id>();
                Map<Id, Id> oppIdToD2cUser = new Map<Id, Id>();

                for(Opportunity opp : [
                    SELECT Id, Lead__c, Lead__r.Assigned_D2C_User__c 
                    FROM Opportunity 
                    WHERE Id IN : oppList
                ]) {
                    oppIdToD2cUser.put(opp.Id, opp.Lead__r?.Assigned_D2C_User__c);
                    oppToLeadMap.put(opp.Id, opp.Lead__c);
                }

                System.debug('oppIdToD2cUser>>>'+oppIdToD2cUser);

                Map<Id, User> userMap = new Map<Id, User>([
                    SELECT Id, ManagerId 
                    FROM User 
                    WHERE Profile.Name IN ('Sales','D2C') And IsActive = true
                ]);

                for(Id oppId : oppIdToD2cUser.keySet()) {
                    Id assignedD2cUser = oppIdToD2cUser.get(oppId);
                    System.debug('assignedD2cUser>>>'+assignedD2cUser);
                    while(assignedD2cUser != null) {
                        System.debug('assignedD2cUser>>>'+assignedD2cUser);
                        
                        if(!salesOppTeamMemberList.containsKey((assignedD2cUser +'-'+ oppId))){
                            OpportunityTeamMember otm = new OpportunityTeamMember();
                            otm.OpportunityId = oppId;
                            otm.TeamMemberRole = (assignedD2cUser == oppIdToD2cUser.get(oppId))?'D2C':'Sales';
                            otm.Associated_With_Loan_Application__c = (assignedD2cUser == oppIdToD2cUser.get(oppId));
                            otm.UserId = assignedD2cUser;
                            otm.OpportunityAccessLevel = (assignedD2cUser == oppIdToD2cUser.get(oppId))?'Edit':'Read';
                            salesOppTeamMemberList.put((assignedD2cUser +'-'+ oppId), otm);
                        }

                        assignedD2cUser = userMap.get(assignedD2cUser).ManagerId;
                    }
                }
            } else {
                Map<Id,Id> branchIdsToOppIds = new Map<Id,Id>();
                Map<Id,ID> oppOwnerIds = new Map<Id,Id>();
                Map<Id,Id> oppIdToDsaAreaManager = new Map<Id,Id>();

                for(Opportunity opp : [Select Id,OwnerId from Opportunity where Id IN : oppList]){
                    oppOwnerIds.put(opp.OwnerId,opp.Id);
                }

                for(Opportunity opp :[SELECT Id,Lead__r.Dsa_Area_Manager__c,Owner.ManagerId,Lead__r.Channel__c FROM Opportunity WHERE Id IN :oppOwnerIds.values()]){
                    if(opp.Lead__r.Channel__c == 'Direct'){
                        oppIdToDsaAreaManager.put(opp.Id, opp.Owner?.ManagerId);
                    }else{
                        oppIdToDsaAreaManager.put(opp.Id, opp.Lead__r?.Dsa_Area_Manager__c);
                    }
                }
                System.debug('oppIdToDsaAreaManager>>'+oppIdToDsaAreaManager);
                
                List<AccountTeamMember> currentAtmList = [SELECT Id,UserId,AccountId
                                                            FROM AccountTeamMember
                                                            WHERE UserId IN :oppOwnerIds.keySet() And User.IsActive = true
                                                            AND (Level__c = 'L0' OR Level__c = 'L1')];
                
                for(AccountTeamMember atm : currentAtmList){
                    branchIdsToOppIds.put(atm.AccountId, oppOwnerIds.get(atm.UserId));
                }
            
                System.debug('UserInfo.getUserId()>>'+userId);

                for(AccountTeamMember atm : [SELECT Id,TeamMemberRole,AccountId,UserId,User.Position_Title__c 
                                            FROM AccountTeamMember
                                            WHERE AccountId IN :branchIdsToOppIds.keySet()
                                            AND TeamMemberRole = 'Sales' And User.IsActive = true]){
                    Id oppId = branchIdsToOppIds.get(atm.AccountId);
                    System.debug('oppId>'+oppId);
                    
                    if(oppId != null) {
                        System.debug('atm.User.Position_Title__c>>'+atm.User.Position_Title__c);
                        System.debug('atm.UserId>>'+atm.UserId);
                        System.debug('oppIdToDsaAreaManager.get(oppId)>>'+oppIdToDsaAreaManager.get(oppId));

                        Id dsaManagerId = oppIdToDsaAreaManager.get(oppId);

                        if(atm.User.Position_Title__c == 'Area Manager'){ 
                            if(atm.UserId != dsaManagerId && atm.UserId != userId) {
                                continue;
                            }
                        }

                        if(!salesOppTeamMemberList.containsKey((atm.UserId +'-'+ oppId))){
                            OpportunityTeamMember otmRecord = new OpportunityTeamMember();
                            otmRecord.OpportunityId = oppId;
                            otmRecord.OpportunityAccessLevel = 'Read';
                            otmRecord.Associated_With_Loan_Application__c = false;

                            if(atm.UserId == userId){
                                System.debug('55>> matched');
                                otmRecord.OpportunityAccessLevel = 'Edit';
                                otmRecord.Associated_With_Loan_Application__c = true;
                            } else if(atm.User.Position_Title__c == 'Area Manager' && atm.UserId == dsaManagerId){
                                System.debug('55>>area manager matched');
                                otmRecord.OpportunityAccessLevel = 'Edit';
                                otmRecord.Associated_With_Loan_Application__c = false;
                            }

                            otmRecord.TeamMemberRole = atm.TeamMemberRole;
                            otmRecord.UserId = atm.UserId;
                            salesOppTeamMemberList.put((atm.UserId +'-'+ oppId), otmRecord);
                        }
                    }
                }
            }
            System.debug('salesOppTeamMemberList>>'+JSON.serialize(salesOppTeamMemberList));
            if(!salesOppTeamMemberList.isEmpty()){
                insert salesOppTeamMemberList.values();
            }
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
   
    public static void updateProductsBasedOnStatus(Set<Id> oppIds, Boolean isApproved) {
        if (oppIds == null || oppIds.isEmpty()) {
            System.debug('No Opportunity IDs provided for product update.');
            return;
        }

        try {
            List<Product2> productsToUpdate = [
                SELECT Id, Negotiated_ROI__c, Final_ROI__c, Sanctioned_ROI__c
                FROM Product2
                WHERE Loan_Application__c IN :oppIds
            ];

            if (productsToUpdate.isEmpty()) {
                System.debug('No Product2 records found for the given Opportunity IDs.');
                return;
            }

            for (Product2 product : productsToUpdate) {
                if (isApproved) {
                    product.Final_ROI__c = product.Negotiated_ROI__c;
                } else {
                    product.Final_ROI__c = product.Sanctioned_ROI__c;
                    product.Negotiated_ROI__c = product.Sanctioned_ROI__c;
                }
            }

            update productsToUpdate;
            System.debug('Successfully updated ' + productsToUpdate.size() + ' Product2 records.');

        } catch (Exception ex) {
            System.debug('Error while updating Product2 records: ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public static void setOpportunityName(List<Opportunity> newRecordIds){

        List<Opportunity> newRecords = [Select Id, Name, Loan_Application_Number__c From Opportunity Where Id In : newRecordIds];
        List<Opportunity> updateList = new List<Opportunity>();
        List<Lead> updateLead = new List<Lead>();
        for(Opportunity itr : newRecords){
            itr.Name = itr.Loan_Application_Number__c;
            updateList.add(itr);
        }

        OpportunityTriggerHandler.isTriggerDisabled = true;
        update updateList;
        OpportunityTriggerHandler.isTriggerDisabled = false;
    }
    public static void shareDocumentsWithOpportunityTeam(Set<Id> loanApplicationIds) {
        // Query Document_Details__c records where Loan_Application__c is in the provided set of IDs
        List<Document_Details__c> docDetails = [SELECT Id, Content_Document_Id__c, Loan_Application__c 
                                                FROM Document_Details__c 
                                                WHERE Loan_Application__c IN :loanApplicationIds];
        
        // Query OpportunityTeamMember records associated with the provided Loan_Application__c IDs
        List<OpportunityTeamMember> teamMembers = [SELECT Id, UserId, OpportunityId 
                                                   FROM OpportunityTeamMember 
                                                   WHERE OpportunityId IN :loanApplicationIds];
        // Extract User IDs from OpportunityTeamMember records
        Map<Id, Set<Id>> loanWithContentIds = new Map<Id, Set<Id>>();
        Set<Id> userIds = new Set<Id>();
        for (OpportunityTeamMember teamMember : teamMembers) {
            userIds.add(teamMember.UserId);
        }
        // Create a map to hold existing shares
        Map<Id, Set<Id>> existingSharesMap = new Map<Id, Set<Id>>();
        // Query existing Document_Details__Share records
        List<Document_Details__Share> existingShares = [SELECT ParentId, UserOrGroupId 
                                                        FROM Document_Details__Share 
                                                        WHERE ParentId IN :docDetails 
                                                          AND UserOrGroupId IN :userIds];
        // Populate the existing shares map
        for (Document_Details__Share share : existingShares) {
            if (!existingSharesMap.containsKey(share.ParentId)) {
                existingSharesMap.put(share.ParentId, new Set<Id>());
            }
            existingSharesMap.get(share.ParentId).add(share.UserOrGroupId);
        }
        // Create a list to hold new Document_Details__Share records
        List<Document_Details__Share> newShares = new List<Document_Details__Share>();
        // Iterate over the Document_Details__c records and create new share records if not already shared
        for (Document_Details__c doc : docDetails) {
            for (OpportunityTeamMember teamMember : teamMembers) {
                if (!existingSharesMap.containsKey(doc.Id) || !existingSharesMap.get(doc.Id).contains(teamMember.UserId)) {
                    Document_Details__Share newShare = new Document_Details__Share();
                    newShare.ParentId = doc.Id;
                    newShare.UserOrGroupId = teamMember.UserId;
                    newShare.AccessLevel = 'Edit'; // Set the desired access level
                    newShares.add(newShare);
                }
            }
        }
        // Insert the new share records
        if (!newShares.isEmpty()) {
            // insert newShares;
        }
        Set<Id> contentDocIds = new Set<Id>();
        Set<Id> loanAppIds = new Set<Id>();
        for (Document_Details__c docDetail : docDetails) {
            if (docDetail.Content_Document_Id__c != null) {
                if (!loanWithContentIds.containsKey(docDetail.Loan_Application__c)) {
                loanWithContentIds.put(docDetail.Loan_Application__c, new Set<Id>());
                }
                loanWithContentIds.get(docDetail.Loan_Application__c).add(docDetail.Content_Document_Id__c);
                }
            }
            for (Id loanAppId : loanWithContentIds.keySet()) {
                loanAppIds.add(loanAppId);
                contentDocIds.addAll(loanWithContentIds.get(loanAppId));
            }
        List<ContentDocumentLink> existingLinks = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :contentDocIds 
        AND LinkedEntityId IN :loanApplicationIds];
        Map<Id, Set<Id>> existingLinksMap = new Map<Id, Set<Id>>();
        for (ContentDocumentLink link : existingLinks) {
        if (!existingLinksMap.containsKey(link.ContentDocumentId)) {
        existingLinksMap.put(link.ContentDocumentId, new Set<Id>());
        }
        existingLinksMap.get(link.ContentDocumentId).add(link.LinkedEntityId);
        }

        List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();
        for (Id loanAppId : loanWithContentIds.keySet()) {
        Set<Id> contentDocIdsForLoan = loanWithContentIds.get(loanAppId);
        for (Id contentDocId : contentDocIdsForLoan) {
        if (!existingLinksMap.containsKey(contentDocId) || !existingLinksMap.get(contentDocId).contains(loanAppId)) {
        ContentDocumentLink newLink = new ContentDocumentLink();
        newLink.ContentDocumentId = contentDocId;
        newLink.LinkedEntityId = loanAppId;
        newLink.ShareType = 'V'; // Viewer access
        newLinks.add(newLink);
        }
        }
}
        if (!newLinks.isEmpty()) {
            // insert newLinks;
        }
    }
    public static void insertDocumentDetailsAndLinks(Set<Id> loanApplicationIds) {
        System.debug('loanApplicationIds ' + loanApplicationIds);
        Map<String, String> contentIdandMaster = new Map<String, String>();
        Map<String, String> nameandMasterId = new Map<String, String>();
        Map<String, String> contentcheckIdandMaster = new Map<String, String>();
        Map<String, String> namecheckandMasterId = new Map<String, String>();
        Map<String, String> SubproductandLoan = new Map<String, String>();
        Map<String, String> docIdandsubproduct = new Map<String, String>();
        Map<String, Id> existingDoc = new Map<String, Id>();
        Set<Id> docMasterIds = new Set<Id>();
        Set<Id> doccheckMasterIds = new Set<Id>();
        Set<Id> docDetailLinkedDocs = new Set<Id>();
        List<String> compKey = new List<String>();
        Integer docseq = 2;
        // Query Document_Master__c records where Esign_Document__c = true
        List<Document_Details__c> ddc = [Select Id,Loan_Application__c,Document_Master__c from Document_Details__c where Loan_Application__c IN:loanApplicationIds and Esign_Document__c = true ];
        if(!ddc.isEmpty()){
           for(Document_Details__c fd : ddc){
            compKey.add(fd.Loan_Application__c+'-'+fd.Document_Master__c);
           }
        }
        System.debug('existingDoc : '+existingDoc);

        List<Application_Applicant__c> primaryApplicant = new List<Application_Applicant__c>();
        Set<String> preferredLanguage = new Set<String>();
        String BASE_FORM = 'AGREEMENT_FORM';
        preferredLanguage.add(BASE_FORM);

        primaryApplicant = [SELECT Id, Preferred_Language__c FROM Application_Applicant__c WHERE Applicant_Type__c = 'Primary Applicant' AND Loan_Application__c IN:loanApplicationIds];

        for (Application_Applicant__c primaryApp : primaryApplicant) {
            if (primaryApp.Preferred_Language__c != null && primaryApp.Preferred_Language__c != 'English') {
                String lang = primaryApp.Preferred_Language__c.trim().toUpperCase().replace(' ', '_');
                preferredLanguage.add(BASE_FORM + '_' + lang);
            }
        }
        
        Map<Id, String> loanToBaseRateCode = new Map<Id, String>();
        List<Loan_Transaction__c> txnList = [SELECT Loan_Application__c, PLR_Code__c FROM Loan_Transaction__c WHERE Loan_Application__c IN :loanApplicationIds AND RecordType.DeveloperName = 'Transaction_Details'
        ];

        for (Loan_Transaction__c txn : txnList) {
            if (txn.PLR_Code__c != null) {
                loanToBaseRateCode.put(txn.Loan_Application__c, txn.PLR_Code__c);
            }
        }
        String RATE_BASE = 'AGREEMENT_FORM';

        for (String rateCode : loanToBaseRateCode.values()) {
            if (rateCode == 'REPOIPLR' || rateCode == 'REPOSPLR') {
                preferredLanguage.add(RATE_BASE + '_' + rateCode);
                // Remove base form if co lending form exists
                preferredLanguage.remove(BASE_FORM);
            }
        }

		system.debug('preferredLanguage>>' + preferredLanguage);
        //currently I see that no vernacular form exists in production >> in order to maintain it this query will need separate the PLR and form logic. For now this woeks.
        List<Document_Master__c> docMasterList = [
            SELECT Id, Name, Is_Required__c, Document_Name__c,Mandatory_Esign_Document__c, Esign_Document__c, Sub_Product__c ,Sub_Product__r.Name
            FROM Document_Master__c 
            WHERE Document_Category__c = 'Esign Template' AND Document_Type__c = 'Form Template' AND Form_Common_Identifier__c IN: preferredLanguage
        ];
        for (Document_Master__c docMaster : docMasterList) {
            if (!docMaster.Mandatory_Esign_Document__c) {
                docMasterIds.add(docMaster.Id);
                nameandMasterId.put(docMaster.Id, docMaster.Document_Name__c);
            } else {
                doccheckMasterIds.add(docMaster.Id);
                namecheckandMasterId.put(docMaster.Id, docMaster.Document_Name__c);
                docIdandsubproduct.put(docMaster.Id, docMaster.Sub_Product__r.Name);
            }
        }
        System.debug('nameandMasterId ' + nameandMasterId);
        System.debug('namecheckandMasterId ' + namecheckandMasterId);
        System.debug('doccheckMasterIds ' + doccheckMasterIds);
    
        if (!docMasterList.isEmpty() && !docMasterIds.isEmpty()) {
            List<ContentDocumentLink> cdl = [
                SELECT ContentDocumentId, LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :docMasterIds
            ];
            system.debug('cdl  '+cdl);
            // Populate the map with ContentDocumentId -> LinkedEntityId (Document Master ID)
            if (!cdl.isEmpty()) {
                for (ContentDocumentLink cd : cdl) {
                    contentIdandMaster.put(cd.ContentDocumentId, cd.LinkedEntityId);
                }
            }
            system.debug('contentIdandMaster  '+contentIdandMaster);
        }
        if (!docMasterList.isEmpty() && !doccheckMasterIds.isEmpty()) {
            List<ContentDocumentLink> cd2 = [
                SELECT ContentDocumentId, LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :doccheckMasterIds
            ];
            if (!cd2.isEmpty()) {
                for (ContentDocumentLink cd : cd2) {
                    contentcheckIdandMaster.put(cd.LinkedEntityId, cd.ContentDocumentId);
                }
            }
        }
    
        // Create Document_Details__c records for each Loan_Application__c
        List<Document_Details__c> docDetailsToInsert = new List<Document_Details__c>();
    
        for (Id loanAppId : loanApplicationIds) {
            for (String contentDocId : contentIdandMaster.keySet()) {
                String docMasterId = contentIdandMaster.get(contentDocId);
                System.debug('docMasterId ' + docMasterId);
                String searchkey = loanAppId+'-'+docMasterId;
                if (compKey.contains(searchkey)) {
                    System.debug('Doc Present');
                }
                else{
                String docMasterName = nameandMasterId.get(contentIdandMaster.get(contentDocId));
                System.debug('docMasterName ' + docMasterName);
                Document_Details__c newDocDetail = new Document_Details__c(
                    Name = docMasterName,
                    Loan_Application__c = loanAppId, // Link to Loan Application
                    Document_Master__c = docMasterId, // Link to Document Master
                    Active__c = true, // Set to active by default
                    Status__c = 'Uploaded',
                    Esign_Document__c = true,
                    Is_Required__c = false,
                    Content_Document_Id__c = contentDocId, // Store the ContentDocumentId
                    Document_Type__c = 'Template Document',
                    DocGen_Sequence__c = docseq
                );
                docseq++;
                docDetailsToInsert.add(newDocDetail);
                }
            }
        }
        List<Product2> checksubproduct = [
            SELECT Id, Name,Product_Master__c,Product_Master__r.Name, Loan_Application__c 
            FROM Product2 
            WHERE Loan_Application__c IN :loanApplicationIds 
            AND RecordType.Name = 'Product' ORDER BY CreatedDate ASC LIMIT 1 //AND Product_Type__c = 'Parent'
        ];
        for (Product2 product : checksubproduct) {
            SubproductandLoan.put(product.Product_Master__r.Name, product.Loan_Application__c);
        }
    
        for (Id loanAppId : loanApplicationIds) {
            for (String docMasterId : doccheckMasterIds) {
                String subProductId = docIdandsubproduct.get(docMasterId);
                if (SubproductandLoan.containsKey(subProductId) && SubproductandLoan.get(subProductId) == loanAppId) {
                    String docMasterName = namecheckandMasterId.get(docMasterId);
                    String searchkey = loanAppId+'-'+docMasterId;
                if (compKey.contains(searchkey)) {
                    System.debug('Doc Present 223');
                }
                else{
                    String contentDocId = contentcheckIdandMaster.get(docMasterId);
                    Document_Details__c newDocDetail = new Document_Details__c(
                        Name = docMasterName,
                        Loan_Application__c = loanAppId, // Link to Loan Application
                        Document_Master__c = docMasterId, // Link to Document Master
                        Active__c = true, // Set to active by default
                        Status__c = 'Uploaded',
                        Esign_Document__c = true,
                        Is_Required__c = true,
                        Content_Document_Id__c = contentDocId,
                        Document_Type__c = 'Template Document',
                        Mandatory_Esign_Document__c = true,
                        DocGen_Sequence__c = 1
                    );
                    docDetailsToInsert.add(newDocDetail);
                }
            }
            }
        }

        //VAS Insurance
        List<Charges_Insurance__c> chargesInsuranceList = [
            SELECT Id, VAS_Code__c, Loan_Application__c
            FROM Charges_Insurance__c
            WHERE Loan_Application__c IN :loanApplicationIds
            AND RecordType.Name = 'Insurance'
        ];

        Set<String> vasCodes = new Set<String>();
        for (Charges_Insurance__c ci : chargesInsuranceList) {
            if (String.isNotBlank(ci.VAS_Code__c)) {
                vasCodes.add(ci.VAS_Code__c);
            }
        }

        Map<String, String> vasCodeToDealerIdMap = new Map<String, String>();

        if (!vasCodes.isEmpty()) {
            List<Charges_Insurance_Master__c> cimList = [
                SELECT VAS_Code__c, VAS_Provider__r.Dealer_ID__c
                FROM Charges_Insurance_Master__c
                WHERE VAS_Code__c IN :vasCodes
            ];

            for (Charges_Insurance_Master__c cim : cimList) {
                vasCodeToDealerIdMap.put(cim.VAS_Code__c, cim.VAS_Provider__r.Dealer_ID__c);
            }
        }

        Set<Id> matchedDocMasterIds = new Set<Id>();

        List<Document_Master__c> docMasterListVAS = [
            SELECT Id, Name, Is_Required__c, Document_Name__c,Mandatory_Esign_Document__c, Esign_Document__c, Sub_Product__c ,Sub_Product__r.Name, Form_Common_Identifier__c
            FROM Document_Master__c 
            WHERE Document_Category__c = 'Esign Template' AND Document_Type__c = 'VAS Insurance'
        ];

        Map<String, String> docnameandMasterId = new Map<String, String>();

        for (Document_Master__c docMaster : docMasterListVAS) {
            for (String dealerId : vasCodeToDealerIdMap.values()) {
                if (docMaster.Form_Common_Identifier__c != null && docMaster.Document_Name__c != null && 
                    dealerId != null &&
                    docMaster.Form_Common_Identifier__c.contains(dealerId)) {
                    // docMaster.Document_Name__c.endsWith(dealerId)) {
                    matchedDocMasterIds.add(docMaster.Id);
                    docnameandMasterId.put(docMaster.Id, docMaster.Document_Name__c);
                }
            }
        }

        Map<String, String> vascontentIdandMaster = new Map<String, String>();

        if (!docMasterListVAS.isEmpty() && !matchedDocMasterIds.isEmpty()) {
            List<ContentDocumentLink> cd3 = [
                SELECT ContentDocumentId, LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :matchedDocMasterIds
            ];
            system.debug('cd3  '+cd3);
            // Populate the map with ContentDocumentId -> LinkedEntityId (Document Master ID)
            if (!cd3.isEmpty()) {
                for (ContentDocumentLink cd : cd3) {
                    vascontentIdandMaster.put(cd.ContentDocumentId, cd.LinkedEntityId);
                }
            }
            system.debug('vascontentIdandMaster  '+vascontentIdandMaster);
        }

        Map<Id, Id> masterToContentId = new Map<Id, Id>();
        for (Id contentDocId : vascontentIdandMaster.keySet()) {
            Id masterId = vascontentIdandMaster.get(contentDocId);
            if (masterId != null) {
                masterToContentId.put(masterId, contentDocId);
            }
        }

        for (Id loanAppId : loanApplicationIds) {
            system.debug('VAS Code related document insertion');
            for (Id docMasterId : matchedDocMasterIds) {
                String searchkey = loanAppId+'-'+docMasterId;
                if (compKey.contains(searchkey)) {
                    System.debug('Doc Present');
                } else{
                    String contentDocId = masterToContentId.get(docMasterId);
                    String docMasterName = docnameandMasterId.get(docMasterId);
                    system.debug('docMasterName  '+docMasterName);
                    system.debug('contentDocId  '+contentDocId);
                    Document_Details__c newDocDetail = new Document_Details__c(
                        Name = docMasterName,
                        Loan_Application__c = loanAppId,
                        Document_Master__c = docMasterId,
                        Active__c = true,
                        Status__c = 'Uploaded',
                        Esign_Document__c = true,
                        Is_Required__c = true,
                        Content_Document_Id__c = contentDocId,
                        Document_Type__c = 'Template Document',
                        DocGen_Sequence__c = docseq,
                        Description__c = 'Non Mandatory Template Document'
                    );
                    docseq++;
                    docDetailsToInsert.add(newDocDetail);
                }
            }
        }

        //MODT MOE TPA
        // List<Application_Applicant__c> appList = [
        //     SELECT Id, Pincode__r.State__c, Pincode__r.City__r.State__c
        //     FROM Application_Applicant__c
        //     WHERE Loan_Application__c IN :loanApplicationIds AND Applicant_Type__c = 'Primary Applicant' LIMIT 1
        // ];

        // Set<String> applicantState = new Set<String>();
        // for (Application_Applicant__c appL : appList) {
        //     if (String.isNotBlank(appL.Pincode__r.City__r.State__c)) {
        //         applicantState.add(appL.Pincode__r.City__r.State__c);
        //     }
        // }

        List<Applicant_Address__c> appList = [SELECT Address_Type__c, Address_Priority__c,   Id, Pincode__r.State__c, Pincode__r.City__r.State__c
                        FROM Applicant_Address__c 
                        WHERE Applicant__r.Loan_Application__c IN :loanApplicationIds AND 
                            Applicant__r.Applicant_Type__c = 'Primary Applicant' AND 
                            Address_Type__c = 'Current' AND 
                            Address_Priority__c = '5' 
                        LIMIT 1];

        Set<String> applicantState = new Set<String>();
        if (!appList.isEmpty()) {
            for (Applicant_Address__c appL : appList) {
                if (String.isNotBlank(appL.Pincode__r.City__r.State__c)) {
                    applicantState.add(appL.Pincode__r.City__r.State__c);
                }
            }
        }
        system.debug('applicantState   '+applicantState);

        List<Document_Master__c> stateDocMasters = new List<Document_Master__c>();
        List<Document_Master__c> nonStateDocMasters = new List<Document_Master__c>();

        if (!applicantState.isEmpty()) {
            stateDocMasters = [
                SELECT Id, Name, Document_Name__c, Form_Common_Identifier__c, Document_Type__c
                FROM Document_Master__c
                WHERE Document_Category__c = 'Esign Template'
                AND Document_Type__c = 'MOE/MODT/TPA'
                AND Form_Common_Identifier__c IN :applicantState //(Form_Common_Identifier__c IN :applicantState OR Form_Common_Identifier__c = 'TPA')
            ];
        }

        system.debug('stateDocMasters   '+stateDocMasters);

        Set<Id> stateDocMasterIds = new Set<Id>();
        for (Document_Master__c dm : stateDocMasters) {
            stateDocMasterIds.add(dm.Id);
        }

        system.debug('stateDocMasterIds   '+stateDocMasterIds);

        if(stateDocMasters.isEmpty()){
            nonStateDocMasters = [
                SELECT Id, Name, Document_Name__c, Form_Common_Identifier__c, Document_Type__c
                FROM Document_Master__c
                WHERE Document_Category__c = 'Esign Template'
                AND Document_Type__c = 'MOE/MODT/TPA'
                AND (Form_Common_Identifier__c IN :applicantState OR Form_Common_Identifier__c  = 'Common MODT')
            ];

            for (Document_Master__c dm : nonStateDocMasters) {
                stateDocMasterIds.add(dm.Id);
            }
        }

        Map<Id, Id> masToConId = new Map<Id, Id>();

        if (!stateDocMasters.isEmpty() && !stateDocMasterIds.isEmpty()) {
            List<ContentDocumentLink> docLinks = [
                SELECT ContentDocumentId, LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :stateDocMasterIds
            ];

            for (ContentDocumentLink link : docLinks) {
                masToConId.put(link.LinkedEntityId, link.ContentDocumentId);
            }
        } else if (stateDocMasters.isEmpty() && !nonStateDocMasters.isEmpty() && !stateDocMasterIds.isEmpty()) {
            List<ContentDocumentLink> docLinks = [
                SELECT ContentDocumentId, LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :stateDocMasterIds
            ];

            for (ContentDocumentLink link : docLinks) {
                masToConId.put(link.LinkedEntityId, link.ContentDocumentId);
            }
        }

        


        for (Id loanAppId : loanApplicationIds) {
            for (Document_Master__c docMaster : stateDocMasters) {
                String searchkey = loanAppId+'-'+docMaster.Id;
                system.debug('searchkey for modt  '+searchkey);
                if (compKey.contains(searchkey)) {
                    System.debug('Doc Present');
                } else {
                    Id contentDocId = masToConId.get(docMaster.Id);
                    if (contentDocId == null) continue; 

                    Document_Details__c newDocDetail = new Document_Details__c(
                        Name = docMaster.Name,
                        Loan_Application__c = loanAppId,
                        Document_Master__c = docMaster.Id,
                        Active__c = true,
                        Status__c = 'Uploaded',
                        Esign_Document__c = true,
                        Is_Required__c = true,
                        Content_Document_Id__c = contentDocId,
                        Document_Type__c = 'Template Document',
                        DocGen_Sequence__c = docseq
                    );
                    docseq++;
                    docDetailsToInsert.add(newDocDetail);
                }
            }

            for (Document_Master__c docMaster : nonStateDocMasters) {
                String searchkey = loanAppId+'-'+docMaster.Id;
                system.debug('searchkey for modt  '+searchkey);
                if (compKey.contains(searchkey)) {
                    System.debug('Doc Present');
                } else {
                    Id contentDocId = masToConId.get(docMaster.Id);
                    if (contentDocId == null) continue; 

                    Document_Details__c newDocDetail = new Document_Details__c(
                        Name = docMaster.Name,
                        Loan_Application__c = loanAppId,
                        Document_Master__c = docMaster.Id,
                        Active__c = true,
                        Status__c = 'Uploaded',
                        Esign_Document__c = true,
                        Is_Required__c = true,
                        Content_Document_Id__c = contentDocId,
                        Document_Type__c = 'Template Document',
                        DocGen_Sequence__c = docseq
                    );
                    docseq++;
                    docDetailsToInsert.add(newDocDetail);
                }
            }
        }


        // Insert the new Document_Details__c records
        if (!docDetailsToInsert.isEmpty()) {
            insert docDetailsToInsert;
        }
        System.debug('docDetailsToInsert 219 : '+docDetailsToInsert);
        // Create ContentDocumentLink records linking the documents to Loan_Application__c
        List<ContentDocumentLink> newCDLList = new List<ContentDocumentLink>();
        for (Document_Details__c docDetail : docDetailsToInsert) {
            System.debug('docDetail.Content_Document_Id__c : '+docDetail.Content_Document_Id__c);
            System.debug('docDetail.Id : ' +docDetail.Id);
            ContentDocumentLink newCDL = new ContentDocumentLink(
                ContentDocumentId = docDetail.Content_Document_Id__c,
                LinkedEntityId = docDetail.Id, // Linking to Loan Application
                ShareType = 'V', // Viewer access
                Visibility = 'AllUsers' // Making it accessible to all users
            );
            newCDLList.add(newCDL);
            docDetailLinkedDocs.add(docDetail.Content_Document_Id__c);
        }
        // Insert the new ContentDocumentLink records
        if (!newCDLList.isEmpty()) {
            //insert newCDLList;
        }
        // 2. Create ContentDocumentLinks for each user and each document
        //Share with "Minimum Access - API Only Integrations" users
        List<User> apiOnlyUsers = [
            SELECT Id 
            FROM User 
            WHERE Profile.Name = 'Minimum Access - API Only Integrations' 
            AND IsActive = TRUE
        ];

        Set<Id> userIds = new Set<Id>();
        for (User u : apiOnlyUsers) {
            userIds.add(u.Id);
        }

        // Query existing shares to avoid duplicates
        Set<String> existingLinks = new Set<String>();
        if (!userIds.isEmpty() && !docDetailLinkedDocs.isEmpty()) {
            for (ContentDocumentLink existing : [
                SELECT ContentDocumentId, LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :userIds 
                AND ContentDocumentId IN :docDetailLinkedDocs
            ]) {
                existingLinks.add(existing.ContentDocumentId + '-' + existing.LinkedEntityId);
            }
        }

        // Add only new shares
        List<ContentDocumentLink> userCDLs = new List<ContentDocumentLink>();
        for (User u : apiOnlyUsers) {
            for (Document_Details__c docDetail : docDetailsToInsert) {
                String contentDocId = docDetail.Content_Document_Id__c;
                if (contentDocId != null) {
                    String uniqueKey = contentDocId + '-' + u.Id;
                    if (!existingLinks.contains(uniqueKey)) {
                        ContentDocumentLink cdl = new ContentDocumentLink(
                            ContentDocumentId = contentDocId,
                            LinkedEntityId = u.Id,
                            ShareType = 'V',
                            Visibility = 'AllUsers'
                        );
                        userCDLs.add(cdl);
                    }
                }
            }
        }

        if (!userCDLs.isEmpty()) {
            insert userCDLs;
        }

        System.debug('Shared with API Only users: ' + userCDLs);
        // Debug output to verify inserted records
        System.debug('Inserted Document_Details__c records: ' + docDetailsToInsert);
        System.debug('Inserted ContentDocumentLink records: ' + newCDLList);
    }
    

    /*public static void handleStageChange(List<Opportunity> newRecords, Map<Id, Opportunity> oldRecords) { 
        List<Opportunity> oppListForAPI = new List<Opportunity>();
        List<Charges_Insurance__c> chargeList = new List<Charges_Insurance__c>();
        Map<Id, Charges_Insurance__c> oppIdVsChargeInsuranceMap = new Map<Id, Charges_Insurance__c>();
    
        // Step 1: Identify Opportunities transitioning from Credit Underwriting → PSV
        for (Opportunity opp : newRecords) {
            Opportunity oldOpp = oldRecords.get(opp.Id);
            if (oldOpp != null && oldOpp.StageName == 'Credit Underwriting' && opp.StageName == 'PSV') {
                oppListForAPI.add(opp);
            }
        }
    
        if (!oppListForAPI.isEmpty()) {
            System.debug('Processing Opportunities for LMS charges: ' + oppListForAPI);
            
            // Step 2: Fetch Existing LMS Charges for the Opportunities
            Set<Id> oppIds = new Set<Id>();
            for (Opportunity opp : oppListForAPI) {
                oppIds.add(opp.Id);
            }
    
            Map<String, Set<Id>> existingChargeTypeVsOppIds = new Map<String, Set<Id>>();
            List<Charges_Insurance__c> existingCharges = [
                SELECT Id, Charges_Fee_Type__c, Loan_Application__c
                FROM Charges_Insurance__c
                WHERE Loan_Application__c IN :oppIds AND Category__c = 'LMS'
            ];
    
            for (Charges_Insurance__c charge : existingCharges) {
                if (!existingChargeTypeVsOppIds.containsKey(charge.Charges_Fee_Type__c)) {
                    existingChargeTypeVsOppIds.put(charge.Charges_Fee_Type__c, new Set<Id>());
                }
                existingChargeTypeVsOppIds.get(charge.Charges_Fee_Type__c).add(charge.Loan_Application__c);
            }
            
            System.debug('Existing Charges Found: ' + existingChargeTypeVsOppIds);
            
            // Step 3: Fetch LMS Charge Types
            List<Charges_Insurance_Master__c> chargesInsuranceMasterRecords = [
                SELECT Id, Charges_Fee_Type__c, Default_Value__c, Category__c, 
                Sub_Product__c, Sub_Product__r.Product__c, Sub_Product__r.Product__r.Name,
                Sub_Product__r.Name
                FROM Charges_Insurance_Master__c
                WHERE Category__c = 'LMS'
            ];
    
            // Step 4: Create LMS Charges if not already created
            for (Opportunity opp : oppListForAPI) {
                for (Charges_Insurance_Master__c chargeInsuranceMaster : chargesInsuranceMasterRecords) {
                    
                    if (opp.Product__c == chargeInsuranceMaster.Sub_Product__r.Product__r.Name && 
                        opp.Sub_Product__c == chargeInsuranceMaster.Sub_Product__r.Name) {
                        
                        // Check if the charge already exists for the current opportunity
                        Boolean chargeAlreadyExists = existingChargeTypeVsOppIds.containsKey(chargeInsuranceMaster.Charges_Fee_Type__c) &&
                                                      existingChargeTypeVsOppIds.get(chargeInsuranceMaster.Charges_Fee_Type__c).contains(opp.Id);
                        
                        if (!chargeAlreadyExists) {  // Only create if it doesn't exist
                            Charges_Insurance__c newLMSCharge = new Charges_Insurance__c();
                            newLMSCharge.Name = chargeInsuranceMaster.Charges_Fee_Type__c;
                            newLMSCharge.Charges_Fee_Type__c = chargeInsuranceMaster.Charges_Fee_Type__c;
                            newLMSCharge.Default_Percentage__c = chargeInsuranceMaster.Default_Value__c;
                            newLMSCharge.Loan_Application__c = opp.Id;
                            newLMSCharge.Category__c = chargeInsuranceMaster.Category__c;
                            chargeList.add(newLMSCharge);
                        }
                    }
                }
            }
    
            // Step 5: Insert LMS Charges
            if (!chargeList.isEmpty()) {
                System.debug('Inserting New LMS Charges: ' + chargeList);
                insert chargeList;
            }
        }
    }
    
    
    public static void handlePricingApprovalChange(List<Opportunity> newRecords, Map<Id, Opportunity> oldMap) {
        List<Document_Details__c> documentsToUpdate = new List<Document_Details__c>();
        
        // Iterate through updated Opportunities
        for (Opportunity newOpp : newRecords) {
            Opportunity oldOpp = oldMap.get(newOpp.Id);
            
            // Check if Is_Pricing_Approval_Required__c changed from false to true
            if (newOpp.Is_Pricing_Approval_Required__c && !oldOpp.Is_Pricing_Approval_Required__c) {
                // Query Document_Details__c records for this Opportunity
                List<Document_Details__c> existingDocs = [
                    SELECT Id, Content_Document_Id__c, Active__c
                    FROM Document_Details__c 
                    WHERE Loan_Application__c = :newOpp.Id 
                    AND Name = 'Sanction Letter' 
                    AND Active__c = true 
                    ORDER BY CreatedDate DESC
                ];
                
                // If any documents found, mark them as inactive
                if (!existingDocs.isEmpty()) {
                    for (Document_Details__c doc : existingDocs) {
                        doc.Active__c = false;
                        documentsToUpdate.add(doc);
                    }
                }
            }
        }
        
        // Perform DML update if there are records to update
        if (!documentsToUpdate.isEmpty()) {
            try {
                update documentsToUpdate;
                System.debug('Updated ' + documentsToUpdate.size() + ' Sanction Letter documents to inactive');
            } catch (DmlException e) {
                System.debug('Error updating Document_Details__c records: ' + e.getMessage());
                // Consider logging to a custom object or throwing an exception based on your requirements
            }
        }
    }*/

    public static void createDefaultsanctioncondtition( Set<Id> loanIds){
        List<Sanction_Condition__c> sanctionConditions = [SELECT Id, Loan_Application__c FROM Sanction_Condition__c WHERE Loan_Application__c IN :loanIds];
        Map<String, List<String>> sanctionConditionsMap = new Map<String, List<String>>();
        for(Sanction_Condition__c sc : sanctionConditions){
            if(sanctionConditionsMap.containsKey(sc.Loan_Application__c)){
                loanIds.remove(sc.Loan_Application__c);
            }
        }
        List<OpportunityTeamMember> teamMembers = [SELECT Id, Name, UserId, TeamMemberRole,OpportunityId
                                                    FROM OpportunityTeamMember 
                                                    WHERE OpportunityId IN :loanIds AND TeamMemberRole = 'Credit'];
        Map<String,String> oppTeamCreditUser = new Map<String,String>();
        if(teamMembers.size() > 0) {
            for(OpportunityTeamMember iterOppTemMem : teamMembers) {
                if(!oppTeamCreditUser.containsKey(iterOppTemMem.OpportunityId)) {
                    oppTeamCreditUser.put(iterOppTemMem.OpportunityId,iterOppTemMem.UserId);
                }
                
            }
        }
         
        List<Sanction_Condition__c> sanctionConditionsList = new List<Sanction_Condition__c>();
        if(loanIds.size()>0){
            List<Deviation_Mitigant_Master__c> masterList = [SELECT Id, Name FROM Deviation_Mitigant_Master__c WHERE Is_Default_Sanction__c = true];
            

            for( String loanId: loanIds){
                for(Deviation_Mitigant_Master__c master : masterList){
                    Sanction_Condition__c sanctionCondition = new Sanction_Condition__c();
                    sanctionCondition.Condition_Name__c = master.Name;
                    sanctionCondition.Loan_Application__c = loanId;
                    sanctionCondition.Condition_Approval__c = 'Pending';
                    if(oppTeamCreditUser.containsKey(loanId)) {
                        sanctionCondition.OwnerId = oppTeamCreditUser.get(loanId);
                    }
                    sanctionConditionsList.add(sanctionCondition);
                }
            }
        }

        if(sanctionConditionsList.size()>0){
            insert sanctionConditionsList;
        }
    }


    public static void updateExistingCustomer(Set<Id> loanIds){    
        Set<Id> accountIds = new Set<Id>();
        Map<String, Application_Applicant__c> applicantList = new Map<String, Application_Applicant__c>([
            SELECT Id, Customer__c FROM Application_Applicant__c  WHERE Loan_Application__c IN :loanIds
        ]);
            
        for(String applicantId : applicantList.keySet()){
            accountIds.add(applicantList.get(applicantId).Customer__c);
        }
    
        List<Account> accountList = [SELECT Id,Exisiting_Customer__c, Customer_LMS_Id__c FROM Account WHERE Customer_LMS_Id__c != null AND Id IN :accountIds];
    
        for(Account acc: accountList){
            if(String.isNotBlank(acc.Customer_LMS_Id__c)){
                acc.Exisiting_Customer__c = true;
            }
        }
    
        if(accountList.size() > 0){
            update accountList;
        }
        
    }
    
    
    public static void createdocusignsForCreditFromSalesLogin(Set<Id> loanApplicationIds) {
        System.debug('loanApplicationIds ' + loanApplicationIds);
        Map<String, String> contentIdandMaster = new Map<String, String>();
        Map<String, String> nameandMasterId = new Map<String, String>();
        Map<String, String> contentcheckIdandMaster = new Map<String, String>();
        Map<String, String> namecheckandMasterId = new Map<String, String>();
        Map<String, String> SubproductandLoan = new Map<String, String>();
        Map<String, String> docIdandsubproduct = new Map<String, String>();
        Map<String, Id> existingDoc = new Map<String, Id>();
        Set<Id> docMasterIds = new Set<Id>();
        Set<Id> doccheckMasterIds = new Set<Id>();
        Set<Id> docDetailLinkedDocs = new Set<Id>();
        List<String> compKey = new List<String>();
        List<id> docDetailsIDs = new List<id>();
        Integer docseq = 2;
        // Query Document_Master__c records where Esign_Document__c = true
        List<Document_Details__c> ddc = [SELECT Id,Loan_Application__c,Document_Master__c FROM Document_Details__c WHERE Loan_Application__c IN:loanApplicationIds AND Esign_Document__c = true AND Document_Type__c = 'Template Document' ];
        if(!ddc.isEmpty()){
           for(Document_Details__c fd : ddc){
            compKey.add(fd.Loan_Application__c+'-'+fd.Document_Master__c);
            existingDoc.put(fd.Document_Master__c, fd.Id);
           }
        }
        System.debug('existingDoc : '+existingDoc);
         //Kalpesh start
        map<String,List<Id>> docLoanMap=new map<String,List<id>>();
        Map<String, Id> coAppMap = new Map<String, Id>();
        List<Application_Applicant__c> coApplivantList=[SELECT Name, Id,Customer_Type__c,Contract_Type__c,Applicant_Type__c,Loan_Application__c FROM Application_Applicant__c WHERE Loan_Application__c IN:loanApplicationIds AND Applicant_Type__c ='Co Applicant'];
                Map<Id, Integer> loanIdToCoAppCount = new Map<Id, Integer>();
                for (Application_Applicant__c coApp : coApplivantList) {
                    if (!loanIdToCoAppCount.containsKey(coApp.Loan_Application__c)) {
                        loanIdToCoAppCount.put(coApp.Loan_Application__c, 0);
                    }
                    loanIdToCoAppCount.put(coApp.Loan_Application__c,loanIdToCoAppCount.get(coApp.Loan_Application__c) + 1);
                }
            Map<Id, List<String>> loanIdToFormIdentifiers = new Map<Id, List<String>>();
            for (Id loanAppId : loanApplicationIds) {
                Integer coAppCount = loanIdToCoAppCount.containsKey(loanAppId)? loanIdToCoAppCount.get(loanAppId): 0;
                List<String> formIdentifierList = new List<String>{ 'APP_FORM' };
                if (coAppCount == 2 || coAppCount == 3) {
                    formIdentifierList.add('APP_FORM_CO_APP_2');
                }
                else if (coAppCount > 3) {
                    formIdentifierList.add('APP_FORM_CO_APP_2');
                    formIdentifierList.add('APP_FORM_CO_APP_4');
                }
                loanIdToFormIdentifiers.put(loanAppId, formIdentifierList);
            }
            List<String> allFormIdentifiers = new List<String>{ 'APP_FORM','APP_FORM_CO_APP_2','APP_FORM_CO_APP_4' };
 
        List<Document_Master__c> docMasterList = [
            SELECT Id, Name, Is_Required__c, Document_Name__c,Mandatory_Esign_Document__c, Esign_Document__c, Sub_Product__c ,Sub_Product__r.Name,Form_Common_Identifier__c
            FROM Document_Master__c
            WHERE Document_Category__c = 'Esign Template' AND Form_Common_Identifier__c IN:allFormIdentifiers
        ];
        for (Id loanAppId : loanApplicationIds) {
            System.debug('loanAppId ' + loanAppId);
            List<String> formsForLoan = loanIdToFormIdentifiers.get(loanAppId);
             System.debug('formsForLoan ' + formsForLoan);
            for (Document_Master__c docMaster : docMasterList) {
                 System.debug('formsForLoan.contain ' + formsForLoan.contains(docMaster.Form_Common_Identifier__c));
                if (formsForLoan.contains(docMaster.Form_Common_Identifier__c)) {
                    if (!docMaster.Mandatory_Esign_Document__c) {
                        docMasterIds.add(docMaster.Id);
                        nameandMasterId.put(docMaster.Id, docMaster.Document_Name__c);
                    } else {
                        doccheckMasterIds.add(docMaster.Id);
                        namecheckandMasterId.put(docMaster.Id, docMaster.Document_Name__c);
                        docIdandsubproduct.put(docMaster.Id, docMaster.Sub_Product__r.Name);
                    }
                }
            }
        }
        System.debug('nameandMasterId ' + nameandMasterId);
        System.debug('namecheckandMasterId ' + namecheckandMasterId);
        System.debug('doccheckMasterIds ' + doccheckMasterIds);
    
        if (!docMasterList.isEmpty() && !docMasterIds.isEmpty()) {
            List<ContentDocumentLink> cdl = [
                SELECT ContentDocumentId, LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :docMasterIds
            ];
            system.debug('cdl  '+cdl);
            // Populate the map with ContentDocumentId -> LinkedEntityId (Document Master ID)
            if (!cdl.isEmpty()) {
                for (ContentDocumentLink cd : cdl) {
                    contentIdandMaster.put(cd.ContentDocumentId, cd.LinkedEntityId);
                }
            }
            system.debug('contentIdandMaster  '+contentIdandMaster);
        }
        if (!docMasterList.isEmpty() && !doccheckMasterIds.isEmpty()) {
            List<ContentDocumentLink> cd2 = [
                SELECT ContentDocumentId, LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :doccheckMasterIds
            ];
            if (!cd2.isEmpty()) {
                for (ContentDocumentLink cd : cd2) {
                    contentcheckIdandMaster.put(cd.LinkedEntityId, cd.ContentDocumentId);
                }
            }
        }
    
        // Create Document_Details__c records for each Loan_Application__c
        List<Document_Details__c> docDetailsToInsert = new List<Document_Details__c>();
    
        for (Id loanAppId : loanApplicationIds) {
            for (String contentDocId : contentIdandMaster.keySet()) {
                String docMasterId = contentIdandMaster.get(contentDocId);
                System.debug('docMasterId ' + docMasterId);
                String searchkey = loanAppId+'-'+docMasterId;
                if (compKey.contains(searchkey)) {
                    System.debug('Doc Present');
                    Id docDetId = existingDoc.get(docMasterId);
                    docDetailsIDs.add(docDetId);
                }
                else{
                String docMasterName = nameandMasterId.get(contentIdandMaster.get(contentDocId));
                System.debug('docMasterName ' + docMasterName);
                Document_Details__c newDocDetail = new Document_Details__c(
                    Name = docMasterName,
                    Loan_Application__c = loanAppId, // Link to Loan Application
                    Document_Master__c = docMasterId, // Link to Document Master
                    Active__c = true, // Set to active by default
                    Status__c = 'Uploaded',
                    Esign_Document__c = true,
                    Is_Required__c = false,
                    Content_Document_Id__c = contentDocId, // Store the ContentDocumentId
                    Document_Type__c = 'Template Document',
                    DocGen_Sequence__c = docseq
                );
                docseq++;
                docDetailsToInsert.add(newDocDetail);
                }
            }
        }
        List<Product2> checksubproduct = [
            SELECT Id, Name,Product_Master__c,Product_Master__r.Name, Loan_Application__c 
            FROM Product2 
            WHERE Loan_Application__c IN :loanApplicationIds 
            AND RecordType.Name = 'Product'
        ];
        for (Product2 product : checksubproduct) {
            SubproductandLoan.put(product.Product_Master__r.Name, product.Loan_Application__c);
        }
    
        for (Id loanAppId : loanApplicationIds) {
            for (String docMasterId : doccheckMasterIds) {
                String subProductId = docIdandsubproduct.get(docMasterId);
                if (SubproductandLoan.containsKey(subProductId) && SubproductandLoan.get(subProductId) == loanAppId) {
                    String docMasterName = namecheckandMasterId.get(docMasterId);
                    String searchkey = loanAppId+'-'+docMasterId;
                    if (compKey.contains(searchkey)) {
                        Id docDetId = existingDoc.get(docMasterId);
                         if(!docLoanMap.containsKey(loanAppId)){
                             docLoanMap.put(loanAppId,new List<Id>());
                            }
                            docLoanMap.get(loanAppId).add(docDetId);
                        System.debug('Doc Present 223');
                        
                       // DocGenerationAPICallout.postDocGenAPISales(docDetId,loanAppId);
                        // System.enqueueJob(new QueueableLogicForSendEmail(loanAppId, docDetId));
                        docDetailsIDs.add(docDetId);
                    }
                    else{
                        String contentDocId = contentcheckIdandMaster.get(docMasterId);
                        Document_Details__c newDocDetail = new Document_Details__c(
                            Name = docMasterName,
                            Loan_Application__c = loanAppId, // Link to Loan Application
                            Document_Master__c = docMasterId, // Link to Document Master
                            Active__c = true, // Set to active by default
                            Status__c = 'Uploaded',
                            Esign_Document__c = true,
                            Is_Required__c = true,
                            Content_Document_Id__c = contentDocId,
                            Document_Type__c = 'Template Document',
                            Mandatory_Esign_Document__c = true,
                            DocGen_Sequence__c = 1
                        );
                        docDetailsToInsert.add(newDocDetail);
                    }
                }
            }
        }
		if (!docDetailsToInsert.isEmpty()) {
            insert docDetailsToInsert;
        }
       
        for (Document_Details__c docDetail : docDetailsToInsert) {
            // List<id> docDetailsIDs = new List<id>();
            docDetailsIDs.add(docDetail.Id);
            if(!docLoanMap.containsKey(docDetail.Loan_Application__c)){
             docLoanMap.put(docDetail.Loan_Application__c,new List<Id>());
            }
            docLoanMap.get(docDetail.Loan_Application__c).add(docDetail.Id);

            // DocGenerationAPICallout.postDocGenAPISales(docDetailsIDs,docDetail.Loan_Application__c);
           // DocGenerationAPICallout.postDocGenAPISales(docDetail.Id,docDetail.Loan_Application__c);
            // System.enqueueJob(new QueueableLogicForSendEmail(docDetail.Loan_Application__c, docDetail.Id));
		}
        for(String loanId:docLoanMap.keySet()){
            List<Id> tempDocDetailsIDs= docLoanMap.get(loanId);
            DocGenPreviewRequestWrapper.syncContentDocumentIds(tempDocDetailsIDs);
            DocGenerationAPICallout.postDocGenAPISales(tempDocDetailsIDs,loanId);
        }
    }  
    
    public static void domainCheckConditions(Set<Id> loanApplicationIds) {
        List<Application_Applicant__c> loanAppList = [
            SELECT Id, Official_Mail_ID__c, Loan_Application__c 
            FROM Application_Applicant__c   
            WHERE Loan_Application__c IN :loanApplicationIds AND Official_Mail_ID__c != null and Official_Mail_Validity__c!='Valid'
        ];

        // if (!loanAppList.isEmpty()) {
        //     System.enqueueJob(new DomainCheckQueueable(loanAppList));
        // }
    }
    
    public static void giveCOMangerAccess(Set<Id> loanIds) {
        List<Opportunity> newRecords = [Select Id, Name, OwnerId,Owner.ManagerId,Owner.Profile.Name From Opportunity Where Id In : loanIds];
        Set<Id> ownerIds = new Set<Id>();
        Map<Id, Id> recordToManager = new Map<Id, Id>();
        for (Opportunity rec : newRecords) {
            if (rec.Owner.Profile.Name == 'Credit Officer' && rec.owner.ManagerId != null) {
                recordToManager.put(rec.Id, rec.Owner.ManagerId);
            }
        }
        if(recordToManager.size() > 0) {
            List<OpportunityShare> oppShareLst = [SELECT  id,OpportunityAccessLevel,OpportunityId,UserOrGroupId FROM OpportunityShare
                                                  WHERE OpportunityId IN : recordToManager.keySet() AND UserOrGroupId IN : recordToManager.values()
                                                  ANd OpportunityAccessLevel = 'Edit'];
            Set<String> existingAccess = new Set<String>();
            for (OpportunityShare ura : oppShareLst) {
                existingAccess.add(ura.OpportunityId + '_' + ura.UserOrGroupId);
            }
            
            List<OpportunityShare> sharesToInsert = new List<OpportunityShare>();
            for (Id recId : recordToManager.keySet()) {
                Id managerId = recordToManager.get(recId);
                String key = recId + '_' + managerId;
                if (!existingAccess.contains(key)) {
                    OpportunityShare share = new OpportunityShare();
                    share.OpportunityId = recId;
                    share.UserOrGroupId = managerId;
                    share.OpportunityAccessLevel = 'Edit';
                    share.RowCause = 'Manual';
                    sharesToInsert.add(share);
                }
            }
            if (!sharesToInsert.isEmpty()) {
                insert sharesToInsert;
            }
        }
    }

      public static void addAndUpdateStageTATRecords( List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        List<TAT__c> existingTATRecords= [SELECT Id, Activity__c, Sub_Activity__c, Loan_Application__c FROM TAT__c WHERE Loan_Application__c IN :newList AND Activity__c= 'Stage Change' AND End_Timestamp__c = NULL];
        List<TAT_Master__mdt> tatMasterList= [SELECT Id, Activity__c, Stage__c, Sub_Activity__c FROM TAT_Master__mdt WHERE Activity__c= 'Stage Change' AND Is_Active__c= true];
        Map<String, TAT_Master__mdt> tatMasterMap = new Map<String, TAT_Master__mdt>();
        Map<String, List<TAT__c>> loanToTat = new Map<String, List<TAT__c>>();

        for(TAT__c tat : existingTATRecords){
            if(loanToTat.containsKey(tat.Loan_Application__c)){
                loanToTat.get(tat.Loan_Application__c).add(tat);
            }else {
                loanToTat.put(tat.Loan_Application__c, new List<TAT__c>{tat});
            }
        }

        for(TAT_Master__mdt master: tatMasterList){
            tatMasterMap.put(master.Stage__c+'-'+master.Sub_Activity__c, master);
        }
        List<TAT__c> tatListToUpsert= new List<TAT__c>();
        if(oldMap!= null){
            for(Opportunity opp : newList){
                Opportunity oldOpp = oldMap.get(opp.Id);
                String oldStage = oldOpp.StageName == 'Sales login'? 'Sales Login': oldOpp.StageName;
                String newStage = opp.StageName== 'Sales login'? 'Sales Login': opp.StageName;
                String key = oldOpp.StageName+'-'+oldStage+' to '+newStage;
                if(tatMasterMap.containsKey(key) || (tatMasterMap.containsKey('Sales Login-Lead to Loan') && newStage == 'Credit Underwriting')){
                    if(loanToTat.containsKey(opp.Id)){
                        List<TAT__c> tatRecs = loanToTat.get(opp.Id);
                        for (TAT__c tat : tatRecs) {
                            tat.End_Timestamp__c = System.now();
                            tatListToUpsert.add(tat);
                        }
                    }
                    TAT_Master__mdt master= tatMasterMap.get(key);
                    TAT__c tatRecord = new TAT__c();
                    tatRecord.Stage__c = master.Stage__c;
                    tatRecord.Activity__c = master.Activity__c;
                    tatRecord.Sub_Activity__c = master.Sub_Activity__c;
                    tatRecord.User_Name__c = UserInfo.getUserId();
                    tatRecord.Timestamp__c = System.now();
                    tatRecord.Loan_Application__c = opp.Id;
                    tatListToUpsert.add(tatRecord);
                }
            }
        }else {
            for(Opportunity opp : newList){
                TAT__c tatRecord = new TAT__c();
                tatRecord.Stage__c = 'Sales login';
                tatRecord.Activity__c = 'Stage Change';
                tatRecord.Sub_Activity__c = 'Lead to Loan';
                tatRecord.User_Name__c = UserInfo.getUserId();
                tatRecord.Timestamp__c = System.now();
                tatRecord.Loan_Application__c = opp.Id;
                tatListToUpsert.add(tatRecord);
            }
        }
        

        if(!tatListToUpsert.isEmpty()){
            upsert tatListToUpsert;
        }

    }

     public static void addAndUpdateSubStageTATRecords( List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        List<TAT_Master__mdt> tatMasterList= [SELECT Id,Code__c, Activity__c, Stage__c, Sub_Activity__c FROM TAT_Master__mdt WHERE Activity__c IN ('Sub Stage Change', 'Income Sanction') AND Is_Active__c= true];
        List<TAT__c> existingTATRecords= [SELECT Id, Activity__c, Sub_Activity__c, Loan_Application__c FROM TAT__c WHERE Loan_Application__c IN :newList AND Activity__c IN ('Sub Stage Change', 'Income Sanction') AND End_Timestamp__c = NULL];

        Map<String, TAT_Master__mdt> tatMasterMap = new Map<String, TAT_Master__mdt>();
        Map<String, List<TAT__c>> loanToTat = new Map<String, List<TAT__c>>();

        if(!existingTATRecords.isEmpty()){
            for(TAT__c tat : existingTATRecords){
                if(loanToTat.containsKey(tat.Loan_Application__c)){
                    loanToTat.get(tat.Loan_Application__c).add(tat);
                }else {
                    loanToTat.put(tat.Loan_Application__c, new List<TAT__c>{tat});
                }
            }
        }

        for(TAT_Master__mdt master: tatMasterList){
            tatMasterMap.put(master.Stage__c+'-'+master.Sub_Activity__c, master);
        }
        List<TAT__c> tatListToUpsert= new List<TAT__c>();
        for(Opportunity opp : newList){
            Opportunity oldOpp = oldMap.get(opp.Id);
            String oldStage = oldOpp.Sub_Stage__c;
            String newStage = opp.Sub_Stage__c;
            String key = oldOpp.StageName+'-'+oldStage+' to '+newStage;
            if(tatMasterMap.containsKey(key)){
                if(loanToTat.containsKey(opp.Id)){
                    List<TAT__c> tatRecs = loanToTat.get(opp.Id);
                    for (TAT__c tat : tatRecs) {
                        tat.End_Timestamp__c = System.now();
                        tatListToUpsert.add(tat);
                    }
                }
                if( newStage!= 'Disbursed'){
                    TAT_Master__mdt masters= tatMasterMap.get(key);
                    TAT__c tatRecord = new TAT__c();
                    tatRecord.Stage__c = masters.Stage__c;
                    tatRecord.Activity__c = masters.Activity__c;
                    tatRecord.Sub_Activity__c = masters.Sub_Activity__c;
                    tatRecord.User_Name__c = UserInfo.getUserId();
                    tatRecord.Timestamp__c = System.now();
                    tatRecord.Loan_Application__c = opp.Id;
                    tatListToUpsert.add(tatRecord);
                }
                
            }
        }

        if(!tatListToUpsert.isEmpty()){
            upsert tatListToUpsert;
        }
    }

    public static void loanBookingTAT(List<String> loanIds){
        List<TAT__c> existingTatRecords= [SELECT Id, End_Timestamp__c, Activity__c FROM TAT__c WHERE Loan_Application__c IN :loanIds AND End_Timestamp__c = null AND Activity__c= 'Stage Change'];
        List<TAT__c> tatListToUpsert= new List<TAT__c>();
        for (TAT__c tat : existingTatRecords) {
            tat.End_Timestamp__c = System.now();
            tatListToUpsert.add(tat);
        }

        //check QDP logic
        Map<String, Boolean> mapLoanToQdpStatus = new Map<String, Boolean>();
        for (Loan_Transaction__c loanTrans : [SELECT Id,Quick_Disbursement__c,Loan_Application__c FROM Loan_Transaction__c WHERE Loan_Application__c IN :loanIds AND RecordType.DeveloperName = 'Transaction_Details']){
          mapLoanToQdpStatus.put(loanTrans.Loan_Application__c, loanTrans.Quick_Disbursement__c);
        }

        // for(String loanId: loanIds){
        //     if(mapLoanToQdpStatus.get(loanId) == false){
        //         List<TAT__c> tatRecList = Utility.insertTATRecords('C-018', loanId, ''); //	Loan Pushed to LMS
        //         tatListToUpsert.addAll(tatRecList);
        //     }
        // }
        if(!tatListToUpsert.isEmpty()){
            upsert tatListToUpsert;
        }
    }

    public static void loanRejectionTAT(List<String> loanIds){

        // List<TAT__c> existingTatRecords= [SELECT Id, End_Timestamp__c, Activity__c FROM TAT__c WHERE Loan_Application__c IN :loanIds AND End_Timestamp__c = null AND Activity__c LIKE '%Rejection%'];
        // for (TAT__c tat : existingTatRecords) {
        //     tat.End_Timestamp__c = System.now();
        //     tatListToUpsert.add(tat);
        // }

        List<TAT__c> existingTatRecords= [SELECT Id, End_Timestamp__c, Activity__c FROM TAT__c WHERE Loan_Application__c IN :loanIds AND End_Timestamp__c = null AND (Activity__c= 'Stage Change' OR Activity__c = 'Sub Stage Change')];

        

        List<TAT__c> tatListToUpsert = new List<TAT__c>();
        for(TAT__c tat: existingTatRecords){
            tat.End_Timestamp__c = System.now();
            tatListToUpsert.add(tat);
        }

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [SELECT Id, Approval_Status__c FROM Opportunity WHERE Id IN :loanIds]
        );

        List<TAT_Master__mdt> metadataList = [
            SELECT Stage__c, Activity__c, Sub_Activity__c, Code__c
            FROM TAT_Master__mdt
            WHERE Activity__c LIKE '%Rejection%'
            AND Is_Active__c = true
        ];

        Map<String, String> rejectionCodeMap = new Map<String, String>();
        for (TAT_Master__mdt mdt : metadataList) {
            rejectionCodeMap.put(mdt.Activity__c, mdt.Code__c);
        }

        for (String loanId : loanIds) {
            Opportunity opp = oppMap.get(loanId);
            if (opp == null || opp.Approval_Status__c == null) continue;

            String approvalStatus = opp.Approval_Status__c;
            String codeToSend;

            if (approvalStatus == 'Hard Rejected') {
                codeToSend = rejectionCodeMap.get('Hard Rejection');

            } else if (approvalStatus == 'Soft Rejected 1' || approvalStatus == 'Soft Rejected 2') {
                codeToSend = rejectionCodeMap.get('Soft Rejection');
            }

            if (codeToSend == null) continue;

            // List<TAT__c> tatRecList = Utility.insertTATRecords(codeToSend, loanId, '');
            // tatListToUpsert.addAll(tatRecList);
        }

        if (!tatListToUpsert.isEmpty()) {
            upsert tatListToUpsert;
        }
    }

    
    public static void grantDocumentAccess(Map<Id, Opportunity> oppMap) {

    // Step 1: Query related Document_Details__c records
    List<Document_Details__c> docDetails = [
        SELECT Id, Content_Document_Id__c, Loan_Application__c
        FROM Document_Details__c
        WHERE Loan_Application__c IN :oppMap.keySet()
        AND Content_Document_Id__c != null AND Eligible_For_FCU__c = true
    ];

    if (docDetails.isEmpty()) return;

    // Step 2: Query Sampler role team members
    Map<Id, Set<Id>> oppToSamplerUsers = new Map<Id, Set<Id>>();

    for (OpportunityTeamMember otm : [
        SELECT OpportunityId, UserId
        FROM OpportunityTeamMember
        WHERE OpportunityId IN :oppMap.keySet()
        AND TeamMemberRole = 'Sampler'
    ]) {
        if (!oppToSamplerUsers.containsKey(otm.OpportunityId)) {
            oppToSamplerUsers.put(otm.OpportunityId, new Set<Id>());
        }
        oppToSamplerUsers.get(otm.OpportunityId).add(otm.UserId);
    }

    List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
    Set<String> uniqueLinks = new Set<String>(); // prevent duplicates

    // Step 3: Create document links
    for (Document_Details__c detail : docDetails) {

        Opportunity opp = oppMap.get(detail.Loan_Application__c);
        if (opp == null) continue;

        // 🔹 Owner access
        if (opp.OwnerId != null) {
            String ownerKey = detail.Content_Document_Id__c + opp.OwnerId;
            if (!uniqueLinks.contains(ownerKey)) {
                uniqueLinks.add(ownerKey);
                linksToInsert.add(new ContentDocumentLink(
                    ContentDocumentId = detail.Content_Document_Id__c,
                    LinkedEntityId    = opp.OwnerId,
                    ShareType         = 'V',
                    Visibility        = 'AllUsers'
                ));
            }
        }

        // 🔹 Sampler role users access
        if (oppToSamplerUsers.containsKey(detail.Loan_Application__c)) {
            for (Id samplerUserId : oppToSamplerUsers.get(detail.Loan_Application__c)) {

                String samplerKey = detail.Content_Document_Id__c + samplerUserId;
                if (uniqueLinks.contains(samplerKey)) continue;

                uniqueLinks.add(samplerKey);
                linksToInsert.add(new ContentDocumentLink(
                    ContentDocumentId = detail.Content_Document_Id__c,
                    LinkedEntityId    = samplerUserId,
                    ShareType         = 'V',
                    Visibility        = 'AllUsers'
                ));
            }
        }
    }

    // Step 4: Insert links
    if (!linksToInsert.isEmpty()) {
        try {
            insert linksToInsert;
        } catch (Exception ex) {
            System.debug('Error creating ContentDocumentLink: ' + ex.getMessage());
        }
    }
}

    public static void createPayoutRecord(List<Opportunity> loanRec, Set<Id> loanLeadIds){ 
        // Build maps from Sub Product (Product2) by Opportunity:
        // - Opportunity(Id) -> Sanctioned_ROI__c
        // - Opportunity(Id) -> Sanction_Loan_Amount__c
        // - Opportunity(Id) -> Sub Product Name
        Map<Id, Decimal> oppIdToSanctionedRoi = new Map<Id, Decimal>();
        Map<Id, Decimal> oppIdToSanctionLoanAmt = new Map<Id, Decimal>();
        Map<Id, String>  oppIdToSubProductName = new Map<Id, String>();
        // Map for Product (parent level) name per Opportunity
        Map<Id, String>  oppIdToProductName = new Map<Id, String>();
        if (loanRec != null && !loanRec.isEmpty()) {
            // Query Sub Product records ordered by CreatedDate ASC; take the first per Opportunity
            List<Product2> subProductsForRoi = [
                SELECT Id, Loan_Application__c, Sanctioned_ROI__c, Sanctioned_Loan_Amount__c, Name
                FROM Product2
                WHERE Loan_Application__c IN :loanRec
                AND RecordType.Name = 'Sub Product'
                ORDER BY CreatedDate ASC
            ];
            for (Product2 p : subProductsForRoi) {
                Id oppId = p.Loan_Application__c;
                if (oppId == null) continue;
                if (!oppIdToSanctionedRoi.containsKey(oppId)) {
                    oppIdToSanctionedRoi.put(oppId, p.Sanctioned_ROI__c);
                }
                if (!oppIdToSanctionLoanAmt.containsKey(oppId)) {
                    oppIdToSanctionLoanAmt.put(oppId, p.Sanctioned_Loan_Amount__c);
                }
                if (!oppIdToSubProductName.containsKey(oppId)) {
                    oppIdToSubProductName.put(oppId, p.Name);
                }
            }
            // Query parent Product records and map Opportunity -> Product Name
            List<Product2> parentProducts = [
                SELECT Id, Loan_Application__c, Name
                FROM Product2
                WHERE Loan_Application__c IN :loanRec
                AND RecordType.Name = 'Product'
                ORDER BY CreatedDate ASC
            ];
            for (Product2 p : parentProducts) {
                if (p.Loan_Application__c != null && !oppIdToProductName.containsKey(p.Loan_Application__c)) {
                    oppIdToProductName.put(p.Loan_Application__c, p.Name);
                }
            }
        }
        
        Map<Id, Lead> leadMap = new Map<Id, Lead>([Select Id, Referred_By_DSA__c, Dsa_Area_Manager__r.Name, 
                                                    Referred_By_DSA__r.Vendor_Code__c, Dsa_Area_Manager__r.Manager.Name
                                                    From Lead Where Id In : loanLeadIds And Channel__c = 'DSA']); // Referred_By_DSA__r.Slab__c,

        
        if(!leadMap.isEmpty()){

            Set<string> branchIds = new Set<string>();
            Set<String> productNames = new Set<String>();

            for(Opportunity rec : loanRec) {
                if(rec.Product__c != null) {
                    productNames.add(rec.Product__c);
                }
                

                if(rec.Branch_Master__c != null){
                    branchIds.add(rec.Branch_Master__c);
                }
            }

            Map<String, string> subProductMap = new Map<String, string>();
            Map<String, string> variantMap = new Map<String, string>();
            System.debug('productNames : '+productNames);
            
            List<Product2> subProducts = [SELECT Id, Name, Product__r.Name, Loan_Application__c FROM Product2 WHERE RecordType.Name = 'Sub Product' 
                                            AND Loan_Application__c IN : loanRec AND Product__r.Name IN : productNames];

            if(!subProducts.isEmpty()) {
                for(Product2 p : subProducts) {
                    string key = (p.Loan_Application__c +'_'+ p.Product__r.Name).toLowerCase();
                    subProductMap.put(key, p.Name);
                }

                List<Product2> variantProducts = [SELECT Id, Name, Product__r.Name, Loan_Application__c FROM Product2 WHERE RecordType.Name = 'Scheme' 
                                                    AND Loan_Application__c IN : loanRec AND Product__c In : subProducts];

                if(!variantProducts.isEmpty()) {
                    for(Product2 v : variantProducts) {
                        string key = (v.Loan_Application__c +'_'+ v.Product__r.Name).toLowerCase();
                        variantMap.put(key, v.Name);
                    }
                }
            }

            //get branch master
            Map<Id, Account> accMap = new Map<Id, Account>();
            Map<Id, String> branchMap = new Map<Id, String>();
            for(Account acc : [Select Id, Name From Account Where Id In : branchIds]){
                branchMap.put(acc.Id, acc.Name);
                accMap.put(acc.Id, acc);
            }

            string recordTypeId = Schema.SObjectType.Vendor_Invoice__c.getRecordTypeInfosByName().get('Payout').getRecordTypeId();
            integer seqNo = Utility.getVendorInvoiceNextNumber('Payout');
            integer charSize = String.valueOf(seqNo).length();
            string seqName = 'P-';
            while (charSize <9) {
                seqName += '0';
                charSize++;
            }
            
            Map<Id, Decimal> pfAmountMap = new Map<Id, Decimal>();
            Map<Id, Decimal> netPremiumMap = new Map<Id, Decimal>();

            for(Charges_Insurance__c rec : [SELECT Loan_Application__c, RecordType.Name, Name, Final_Amount_INR__c, Sum_Insured_Customer_Details__c 
                                            FROM Charges_Insurance__c WHERE Loan_Application__c In : loanRec And RecordType.Name In ('Charges', 'Insurance') 
                                            Order By Loan_Application__r.Name, Name]){

                if(rec.RecordType.Name == 'Insurance'){
                    decimal premium = (rec.Sum_Insured_Customer_Details__c != null ? rec.Sum_Insured_Customer_Details__c : 0);

                    if(netPremiumMap.containsKey(rec.Loan_Application__c)){
                        premium += netPremiumMap.get(rec.Loan_Application__c);
                    }

                    netPremiumMap.put(rec.Loan_Application__c, premium);
                }
                else {
                    if(rec.Name == 'PROCFEE'){
                        decimal procFee = (rec.Final_Amount_INR__c != null ? rec.Final_Amount_INR__c : 0);

                        if(pfAmountMap.containsKey(rec.Loan_Application__c)){
                            procFee += pfAmountMap.get(rec.Loan_Application__c);
                        }

                        pfAmountMap.put(rec.Loan_Application__c, procFee);
                    }
                }
            }
            
            //get loan disbursed amount
            Map<string, Decimal> loanDisbursedAmtMap = new Map<string, Decimal>();
            for(Loan_Transaction__c ltRec : [Select Id, Loan_Application__c, Total_Disbursed_Amount__c From Loan_Transaction__c 
                                            Where Loan_Application__c In : loanRec And RecordType.Name = 'Transaction Details']) {

                loanDisbursedAmtMap.put(ltRec.Loan_Application__c, ltRec.Total_Disbursed_Amount__c);
            }

            //get memo created on loan
            Map<Id, Id> loanToMemoMap = new Map<Id, Id>();
            for(Vendor_Invoice__c memo : [SELECT Id, Loan_Application__c FROM Vendor_Invoice__c WHERE RecordType.Name = 'Memo' And Loan_Application__c In : loanRec]) {
                if(!loanToMemoMap.containsKey(memo.Loan_Application__c)) {
                    loanToMemoMap.put(memo.Loan_Application__c, memo.Id);
                }
            }
            
            Map<string, string> loanToSourcingOffMap = new Map<string, string>();
            List<Vendor_Invoice__c> payoutToCreate = new List<Vendor_Invoice__c>();

            for(Opportunity rec : loanRec){
    
                if(leadMap.containsKey(rec.Lead__c)){

                    Vendor_Invoice__c inv = new Vendor_Invoice__c();
                    inv.FIN_Refrence_No__c = rec.LMS_Loan_Reference__c;
                    inv.Loan_Application__c = rec.Id;
                    inv.RecordTypeId = recordTypeId;
                    inv.Status__c = 'Draft';
                    inv.Name = seqName + seqNo;
                    // Prefer Product2 (parent 'Product' record) Name for Product__c on invoice
                    if (oppIdToProductName.containsKey(rec.Id)) {
                        inv.Product__c = oppIdToProductName.get(rec.Id);
                    }
                    //inv.Product__c = rec.Product__c; old mapping
                    inv.Customer_Name__c = rec.Product__c == 'Business Loan' ? 'Godrej Finance Limited' : 'Godrej Housing Finance Limited';
                    // Map fields from Sub Product (Product2) when available
                    if (oppIdToSubProductName.containsKey(rec.Id)) {
                        inv.Sub_Product__c = oppIdToSubProductName.get(rec.Id);
                    }
                    if (oppIdToSanctionLoanAmt.containsKey(rec.Id)) {
                        inv.Sanction_Loan_Amount__c = oppIdToSanctionLoanAmt.get(rec.Id);
                    }
                    if (oppIdToSanctionedRoi.containsKey(rec.Id)) {
                        inv.ROI__c = oppIdToSanctionedRoi.get(rec.Id);
                    }
                    // inv.ROI__c = rec.Sanction_ROI__c; old mapping
                    inv.Type_Of_Channel__c = rec.Channel_Type__c;
                    inv.PF_Amount__c = pfAmountMap.containsKey(rec.Id) ? pfAmountMap.get(rec.Id) : 0;
                    inv.PF_Percentage__c = (inv.PF_Amount__c / rec.Sanction_Loan_Amount__c).setScale(2);
                    inv.Net_Premium__c = netPremiumMap.containsKey(rec.Id) ? netPremiumMap.get(rec.Id) : 0;
                    inv.Value_Penetration__c = (inv.Net_Premium__c / rec.Sanction_Loan_Amount__c).setScale(2);
                    inv.Disbursed_Amount__c = loanDisbursedAmtMap.containsKey(rec.Id) ? loanDisbursedAmtMap.get(rec.Id) : 0;
                    inv.Login_Date__c = rec.CreatedDate.date();
                    inv.Booking_Date__c = Date.today();
                    inv.Memo__c = loanToMemoMap.containsKey(rec.Id) ? loanToMemoMap.get(rec.Id) : null;
                    inv.Branch__c = branchMap.containsKey(rec.Branch_Master__c) ? branchMap.get(rec.Branch_Master__c) : null;
                    inv.Branch_Master__c = accMap.containsKey(rec.Branch_Master__c) ? accMap.get(rec.Branch_Master__c).Id : null;
                    System.debug('Print Branch master :'+ branchMap.get(rec.Branch_Master__c) );

                    Lead leadRec = leadMap.get(rec.Lead__c);
                    inv.DSA__c = leadRec.Referred_By_DSA__c;
                    inv.Manager_Name__c = rec.Sourcing_Manager__r.Name;
                    inv.Cluster_Manager_Name__c = rec.Sourcing_Manager__r?.Manager?.Name;
                    // inv.Slab__c = leadRec.Referred_By_DSA__r.Slab__c;
                    inv.Channel_Code__c = leadRec.Referred_By_DSA__r.Vendor_Code__c;
        
                    string subProdKey = (rec.Id +'_'+ rec.Product__c).toLowerCase();
                    /* old mapping - need to confirm with sarthak
                    if(subProductMap.containsKey(subProdKey)){
                        inv.Sub_Product__c = subProductMap.get(subProdKey);
                        string varKey = (rec.Id +'_'+ inv.Sub_Product__c).toLowerCase();
                        inv.Loan_Type__c = variantMap.containsKey(varKey) ? variantMap.get(varKey) : null;
                    }
                    */
        
                    payoutToCreate.add(inv);
                    seqNo++;

                    if(rec.Sourcing_Manager__c != null){
                        loanToSourcingOffMap.put(rec.Id, rec.Sourcing_Manager__c);
                    }
                }
            }
            
            if(!payoutToCreate.isEmpty()){
                insert payoutToCreate;

                //share with sourcing manager
                List<Vendor_Invoice__Share> shareList = new List<Vendor_Invoice__Share>();
                List<Id> insertedRecIds = new List<Id>();
                for(Vendor_Invoice__c rec : payoutToCreate){
                    if(loanToSourcingOffMap.containsKey(rec.Loan_Application__c)){
                        Vendor_Invoice__Share rcdShr = new  Vendor_Invoice__Share();
                        rcdShr.parentId = rec.Id;
                        rcdShr.UserOrGroupId = loanToSourcingOffMap.get(rec.Loan_Application__c);
                        rcdShr.AccessLevel = 'Read';
                        
                        shareList.add(rcdShr);
                    }
                    insertedRecIds.add(rec.Id);
                }

                if(!shareList.isEmpty()){
                    insert shareList;
                }
                for (Id recId : insertedRecIds) {
                    PayoutManagementController.sendNotificationToUsers(recId, 'created', 'Payout Created', 'All Product Users');
                }
            }
        }
    }
    public static void validateManualOwnerChange(List<Opportunity> newRecords, Map<Id, Opportunity> oldRecords) {
        // if (!Utility.isOwnershipRestrictionEnabled()) {
        //     return;
        // }
        // if (Utility.byPassOwnershipUpdate) {
        //     return;
        // }
        Id currentProfileId = UserInfo.getProfileId();
        Id sysAdminProfileId = [ SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;

        for (Opportunity newOpp : newRecords) {
            Opportunity oldOpp = oldRecords.get(newOpp.Id);
            if (oldOpp == null) continue;
            if (newOpp.OwnerId != oldOpp.OwnerId) {
                if (currentProfileId != sysAdminProfileId) {
                    newOpp.addError('You are not authorized to change the owner of this record.');
                }
            }
        }
    }

}