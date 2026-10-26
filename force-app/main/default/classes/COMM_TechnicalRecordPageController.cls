/**
* @File Name : COMM_TechnicalRecordPageController.cls
* @Description :
* @Author :
* @Last Modified By : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On : 12-16-2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 6, 2025 |   | Initial Version
**/


public without sharing class COMM_TechnicalRecordPageController {

     @AuraEnabled
    public static string delinkTechnical(string technicalId){
        try{
        Set<Id> loanIds = new Set<Id>();
        List<Technical_Evaluation__c> technicalList = [SELECT Id,HL_Loan_Application__c,HL_Loan_Application__r.Name FROM Technical_Evaluation__c WHERE Id =: technicalId];

        Technical_Evaluation__c updatedTe = new Technical_Evaluation__c();
        updatedTe.Id = technicalId;
        updatedTe.Delink_done_by__c = UserInfo.getUserId();
        updatedTe.Loan_Application_Delinked__c =technicalList[0].HL_Loan_Application__r.Name;
        updatedTe.HL_Loan_Application__c = null;

        update updatedTe;

    

        return 'success';
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

     @AuraEnabled
    public static Boolean checkTechnicalDelinkAccess(string loanId){
        try{
        // List<Opportunity> opp = [Select Id From Opportunity Where Id =: loanId And StageName = 'Credit Underwriting'];
        // if(!opp.isEmpty()){
            string profileName = Utility.fetchUserProfile(UserInfo.getProfileId());
            List<String> permissions = Utility_V1.getCurrentUserPermissionSets();
           if ((profileName != null && profileName == 'System Administrator') ||(permissions != null && (permissions.contains('PS_Technical_Manager_HL') ||permissions.contains('PS_Credit_Manager_HL')
                ))) {
                    return true;
                }

        // }

        return false;
    }catch(Exception e){
       throw new AuraHandledException(e.getMessage());
    }
    }


    @AuraEnabled
    public static Map<String, Object> getTechEvalId(String loanId) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            List<Technical_Evaluation__c> techEval = [SELECT Id, HL_Application_Collateral__c, HL_Loan_Amount__c,HL_Loan_Application__r.Sanction_Loan_Amount__c FROM Technical_Evaluation__c WHERE HL_Stage__c = 'Assigned to Technical Manager' AND HL_Assigned_to_Technical_Manager__c = :UserInfo.getUserId() AND HL_Loan_Application__c = :loanId ORDER BY CreatedDate DESC LIMIT 1];
            if(techEval.size()>0){
                system.debug('techEval>>>'+techEval);
                result.put('id', techEval[0].Id);
                result.put('loanAmount', techEval[0].HL_Loan_Application__r.Sanction_Loan_Amount__c);
                system.debug('techEval>>>'+result);
                return result;
            }else{
                Opportunity opp=[select id,Sanction_Loan_Amount__c from Opportunity where Id=:loanId];
                system.debug('techEval>>>'+opp);
                result.put('id', null);
                result.put('loanAmount', opp.Sanction_Loan_Amount__c);
                system.debug('techEval>>>'+result);
                return result;
            }
        } catch (QueryException e) {
            System.debug('Query failed in getTechEvalId: ' + e.getLineNumber());
            System.debug('Query failed in getTechEvalId: ' + e.getMessage());
            return null;
        }
    }

    @AuraEnabled
    public static Map<Id, String> getInternalTechnicalUsers(ID loanId){
        Map<Id, String> userMap = new Map<Id, String>();
        try{
            String sObjName = loanId.getSObjectType().getDescribe().getName();
            if(sObjName=='Opportunity'){
                List<Opportunity> loanList = [Select Id, Branch_Master__c from Opportunity where id =: loanId LIMIT 1];
                if(loanList.size() > 0){    
                    List<AccountTeamMember> accountTeamMembers = [ SELECT UserId, User.Employee_ID__c, User.Name, User.User_Type__c FROM AccountTeamMember WHERE AccountId =:loanList[0].Branch_Master__c AND TeamMemberRole = 'Technical Manager'  and User.User_Type__c = 'Internal'];
                    for (AccountTeamMember atm : accountTeamMembers) {
                        userMap.put(atm.UserId,atm.User.Employee_ID__c + '_' + atm.User.Name + '_' + atm.User.User_Type__c);
                    }
                }
            }
        }
        catch(Exception exp){
            throw new AuraHandledException('Error fetching user data: ' + exp.getStackTraceString());
        }
            return userMap;
        }

    //Fetches the Collateral related to a technical record for Technical Manager
    @AuraEnabled
    public static Map<Id, String> getCollateral(String loanId) {
        Map<Id, String> collateralMap = new Map<Id, String>();
        
        try {
            Technical_Evaluation__c techEval = [SELECT HL_Application_Collateral__c FROM Technical_Evaluation__c WHERE HL_Stage__c = 'Assigned to Technical Manager' AND HL_Assigned_to_Technical_Manager__c = :UserInfo.getUserId() AND HL_Loan_Application__c = :loanId ORDER BY CreatedDate DESC LIMIT 1];
            
            if (techEval == null || techEval.HL_Application_Collateral__c == null) {
                return collateralMap;
            }
            
            List<Application_Collateral__c> collaterals = [Select Id,Name_of_Collateral__c,State__c,Collateral__r.State__c, Collateral__c, 
                                                           Collateral__r.Plot_Number__c, Collateral__r.Floor_Number__c,Collateral__r.Landmark__c, 
                                                           Collateral__r.Building_Street_Name__c, Collateral__r.Pincode__c, Collateral__r.Pincode__r.Name, 
                                                           Collateral__r.Address_Line_1__c,Collateral__r.Address_Line_2__c,Collateral__r.Address_Line_3__c,
                                                           Asset_Type__c from Application_Collateral__c
                                                           WHERE Id = :techEval.HL_Application_Collateral__c];
            
            for (Application_Collateral__c col : collaterals) {
                List<String> parts = new List<String>();
                if (String.isNotBlank(col.Name_of_Collateral__c)) {
                    parts.add(col.Name_of_Collateral__c);
                }
                
                if (string.isNotBlank(col.Asset_Type__c)) {
                    parts.add(col.Asset_Type__c);
                }
                //updated Ayushi
                HLContext ctx = new HLContext(loanId);
                string address = resolveAddress(col.Collateral__r, ctx);
                //string address = buildAddress(col.Collateral__r);
                //end updated
                if (String.isNotBlank(address)) {
                    parts.add(address);
                }
                collateralMap.put(col.Id, String.join(parts, ' - '));
            }
            
        } catch (QueryException qe) {
            System.debug('QueryException in getCollateral: ' + qe.getMessage());
        } catch (Exception e) {
            System.debug('Unexpected exception in getCollateral: ' + e.getMessage());
        }
        
        return collateralMap;
    }
    

    //Main method to initiate the technical evaluation process
    @AuraEnabled
    public static Id initiateTechnical(String createTechWrapperString) {
        InitiateTechnicalWrapper techWrapperObj = (InitiateTechnicalWrapper) JSON.deserialize(createTechWrapperString, InitiateTechnicalWrapper.class);
        Map<String,String> inputMapUtility = new  Map<String,String>();
        System.debug('createTechWrapperString'+ createTechWrapperString);
        inputMapUtility.put('oppId', techWrapperObj.loanId);
        Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.getProductDetails(inputMapUtility);
        Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
        List<String> currentPermissions = Utility_V1.getCurrentUserPermissionSets();
        //InitiateTechnicalWrapper techWrapperObj = (InitiateTechnicalWrapper) JSON.deserialize(createTechWrapperString, InitiateTechnicalWrapper.class);
        Id hlRecordId;
        /*if(isHlRelated){
           hlRecordId = Schema.SObjectType.Technical_Evaluation__c
            .getRecordTypeInfosByName()
            .get('HL On Location').getRecordTypeId();
        }
        Id internalRecordTypeId = Schema.SObjectType.Technical_Evaluation__c.getRecordTypeInfosByName().get('Internal').getRecordTypeId();
        User assignedUser;
        if(!isHlRelated){
         if(techWrapperObj.Owner !=null){
         assignedUser = [SELECT Id, Name, AccountId FROM User WHERE Id = :techWrapperObj.Owner LIMIT 1];
        }
        }
        //User assignedUser;
        List<AccountTeamMember> teamMemberList= new List<AccountTeamMember>();

        if(!isHlRelated){
            if(Utility.getCurrentUserProfileName() == Constants.TECHNICAL_MANAGER_PROFILE){
                assignedUser = [SELECT Id, Name, AccountId FROM User WHERE Id = :techWrapperObj.Owner LIMIT 1];
            }else{
                teamMemberList = [SELECT Id, UserId FROM AccountTeamMember WHERE AccountId =:techWrapperObj.Owner AND TeamMemberRole= 'Technical Manager'];
            }
        }else{
            if(currentPermissions.contains('PS_Technical_Manager_HL')){
                assignedUser = [SELECT Id, Name, AccountId FROM User WHERE Id = :techWrapperObj.Owner LIMIT 1];
            }else{
                teamMemberList = [SELECT Id, UserId FROM AccountTeamMember WHERE AccountId =:techWrapperObj.Owner AND TeamMemberRole= 'Technical Manager'];
            }

        }
        
        // logic for Credit Manager while initiating TV
        // if (Utility.getCurrentUserProfileName() == 'Credit Manager') {
            List<Technical_Evaluation__c> existingTechRec = [SELECT Id FROM Technical_Evaluation__c  WHERE HL_Loan_Application__c = :techWrapperObj.loanId AND  HL_Application_Collateral__c = :techWrapperObj.aplicationcolatteral AND CreatedById = :UserInfo.getUserId() AND (HL_Stage__c != 'Rejected by Technical Manager' AND HL_Stage__c != 'Rejected by Admin') AND RecordType.Name = 'HL_Square_Yard' LIMIT 1];
            
            if (!existingTechRec.isEmpty()) {
                throw new AuraHandledException('You have already initiated a Technical Evaluation for this Collateral.');
            }
        // }

        String parentProdName = '';
        List<Product2> parentProd = [SELECT Id,Name,Product_Type__c from Product2 Where Product_Type__c = 'Parent' AND Loan_Application__c = :techWrapperObj.loanId LIMIT 1];
        //getting the parent prod andmapping it on Tech
        if(parentProd.size() > 0){
            parentProdName = parentProd[0].Name;
        }
            
        if (String.isNotBlank(techWrapperObj.techEvalId)){//(techWrapperObj.techEvalId != null) { >> changed by Arman on 5-11-2025 : Kindly put isNotBlank for Strings, isNull for Integers and size()>0 for lists

            System.debug('techWrapperObj.techEvalId>>'+techWrapperObj.techEvalId);
            Map<String,String> inputMap = new Map<String,String>();
            inputMap.put('oppId', techWrapperObj.loanId);

            Utility_V1.ProductWrapper prodDetails = Utility_V1.getProductDetails(inputMap);

            //if(prodDetails.loanProduct == 'Home Loan'){
                List<string> techIds = techWrapperObj.techEvalId.split(',');
                List<Technical_Evaluation__c> existingTech = [SELECT Id, HL_Assigned_To_Technical_Admin__c,HL_Loan_Application__c,HL_Loan_Application__r.Requested_Amount__c, HL_Stage__c,HL_Loan_Application__r.Sanction_Loan_Amount__c FROM Technical_Evaluation__c WHERE Id IN : techIds];
                for(Technical_Evaluation__c rec : existingTech){
                    rec.AHL_Product__c = parentProdName;
                    rec.Loan_Amount_Requested__c = rec.HL_Loan_Application__r.Requested_Amount__c!=null ? rec.HL_Loan_Application__r.Requested_Amount__c : null; //NEW
                    rec.HL_Stage__c = 'Assigned to Admin';
                    if(assignedUser!= null){
                        rec.HL_Assigned_to_Technical_Admin__c = assignedUser.Id;
                        if (assignedUser.AccountId != null) {
                            rec.HL_Vendor_Agency__c = assignedUser.AccountId;
                        }
                    }
                    rec.HL_Technical_assigned_to_Admin__c = Date.today();
                }
                
                update existingTech;
            Set<Id> loanIds = new Set<Id>();
            for (Technical_Evaluation__c techObj : existingTech) {
                if (techObj.HL_Loan_Application__r.Sanction_Loan_Amount__c >= 5000000 && existingTech.size()>1) {
                    loanIds.add(techObj.HL_Loan_Application__c);
                }else if(techObj.HL_Loan_Application__r.Sanction_Loan_Amount__c < 5000000 && existingTech.size()>0){
                    loanIds.add(techObj.HL_Loan_Application__c);
                }
            }
            List<TAT__c> existingTatRecList = [SELECT Id, Loan_Application__c FROM TAT__c WHERE Code__c = 'C-055' AND Loan_Application__c IN :loanIds];
            for (TAT__c tatRec : existingTatRecList) {
                system.debug('inside apex cont>>>>');
                tatRec.End_Timestamp__c = System.now();
            }
            if (!existingTatRecList.isEmpty()) {
                update existingTatRecList;
            }
            //}
            /*else {
                Technical_Evaluation__c existingTech = [SELECT Id, HL_Assigned_To_Technical_Admin__c, HL_Stage__c FROM Technical_Evaluation__c WHERE Id = :techWrapperObj.techEvalId LIMIT 1];
                existingTech.HL_Stage__c = 'Assigned to Admin';
                existingTech.HL_Assigned_to_Technical_Admin__c = assignedUser.Id;
                if (assignedUser.AccountId != null) {
                    existingTech.HL_Vendor_Agency__c = assignedUser.AccountId;
                }
                existingTech.HL_Technical_assigned_to_Admin__c = Date.today();
                update existingTech;    
            }
                                    OpportunityTeamMember newTeamMember = new OpportunityTeamMember(
                                    OpportunityId = techWrapperObj.loanId,
                                    UserId = assignedUser.Id,
                                    TeamMemberRole = 'Technical Admin',
                                    OpportunityAccessLevel = 'Edit',
                                    Associated_With_Loan_Application__c=true);
                                    insert newTeamMember;
            
            return null;
        }*/
        //else{
            Technical_Evaluation__c tech = new Technical_Evaluation__c();
            
            List<Application_Collateral__c> appCollateralList = [SELECT Id, Collateral__c,HL_Loan_Application__c,HL_Loan_Application__r.Requested_Amount__c FROM Application_Collateral__c WHERE Id = :techWrapperObj.aplicationcolatteral LIMIT 1];
            if (appCollateralList.isEmpty()) {
                throw new AuraHandledException('Application Collateral not found.');
            }
            
            String addressData = '';
            
            Application_Collateral__c appAddress = [Select Id,Name_of_Collateral__c,State__c,Collateral__r.State__c, 
                                                    Collateral__c, Collateral__r.Plot_Number__c, Collateral__r.Floor_Number__c,
                                                    Collateral__r.Landmark__c, Collateral__r.Building_Street_Name__c, 
                                                    Collateral__r.Address_Line_1__c,Collateral__r.Address_Line_2__c,Collateral__r.Address_Line_3__c,
                                                    Collateral__r.Pincode__c, Collateral__r.Pincode__r.Name, Asset_Type__c from Application_Collateral__c where ID =:appCollateralList[0].Id];
            if (appAddress != null) {
            //updated Ayushi
            HLContext ctx = new HLContext(techWrapperObj.loanId);
            addressData = resolveAddress(appAddress.Collateral__r, ctx);
            //addressData = buildAddress(appAddress.Collateral__r);
            //end updated
            }
                                                   
            String primaryApplicant = '';
            String primaryApplicantContact = '';
            Boolean isPrimaryNonIndividual = false;
            List<String> coApplicants = new List<String>();
            List<String> coApplicantMobiles = new List<String>();
            List<String> coApplicantPincodes = new List<String>();
            for (Application_Applicant__c app : [SELECT Applicant_Type__c, First_Name__c, Last_Name__c, Customer_Type__c, Mobile_Number__c, Pincode__c, Pincode__r.Name FROM Application_Applicant__c WHERE Loan_Application__c = :techWrapperObj.loanId ORDER BY Applicant_Type__c]) {
                String fullName = app.First_Name__c + ' ' + app.Last_Name__c;
                if (app.Applicant_Type__c == Constants.APPLICANT_TYPE_APPLICANT) {
                    primaryApplicant = fullName;
                    primaryApplicantContact = app.Mobile_Number__c;
                    isPrimaryNonIndividual = (app.Customer_Type__c == 'Non Individual');
                } else if (app.Applicant_Type__c == Constants.APPLICANT_TYPE_CO_APPLICANT) {
                    coApplicants.add(fullName);
                    if (String.isNotBlank(app.Mobile_Number__c)) {
                        coApplicantMobiles.add(app.Mobile_Number__c);
                    }
                    if (app.Pincode__r != null && String.isNotBlank(app.Pincode__r.Name)) {
                        coApplicantPincodes.add(app.Pincode__r.Name);
                    } 
                }

            }
            
            tech.HL_Loan_Application__c = techWrapperObj.loanId;
            tech.Loan_Amount_Requested__c = appCollateralList[0].HL_Loan_Application__r.Requested_Amount__c!=null ? appCollateralList[0].HL_Loan_Application__r.Requested_Amount__c : null; //NEW
            //tech.AHL_Product__c = parentProdName; //mapping the parent product
            tech.HL_Application_Collateral__c = appCollateralList[0].Id;
            tech.HL_Collateral_Address__c = addressData;
            tech.HL_Technical_Type__c = (techWrapperObj.reportType != null && techWrapperObj.reportType == 'Internal') ? techWrapperObj.reportType : 'External';
            tech.HL_Sent_Back_Count__c = 0;
            tech.HL_Report_Date__c = Date.today();
            tech.HL_Customer_Name__c = primaryApplicant;
            tech.Primary_Applicant_Contact_Details__c = primaryApplicantContact;
            /*if(techWrapperObj.reportType != null && techWrapperObj.reportType == 'Internal'){
                tech.RecordTypeId = internalRecordTypeId;
            }*/
            if(isHlRelated){
                tech.RecordTypeId =hlRecordId;
            }
            tech.HL_Name_of_Applicant__c = primaryApplicant + (coApplicants.isEmpty() ? '' : ', ' + String.join(coApplicants, ', '));
            List<String> coAppContactPairs = new List<String>();
            if (isPrimaryNonIndividual) {
                for (Integer i = 0; i < coApplicants.size(); i++) {
                    String name = coApplicants[i];
                    String mob = (i < coApplicantMobiles.size()) ? coApplicantMobiles[i] : '';
                    String pin = (i < coApplicantPincodes.size()) ? coApplicantPincodes[i] : '';
                    coAppContactPairs.add(name + ': ' + mob + (String.isNotBlank(pin) ? ' / ' + pin : ''));
                }
                system.debug('coAppContactPairs>>'+coAppContactPairs);
                tech.Co_Applicant_Contact_Details__c = String.join(coAppContactPairs, '; ');
            } else {
                tech.Co_Applicant_Contact_Details__c = '';
            }

            
            insert tech;
            //TAT update
           /* Set<Id> loanIds = new Set<Id>();
            List<Technical_Evaluation__c> checkTechForTat=[select id,HL_Loan_Application__c,HL_Loan_Application__r.Sanction_Loan_Amount__c from Technical_Evaluation__c where HL_Loan_Application__c=: techWrapperObj.loanId];
            for (Technical_Evaluation__c techObj : checkTechForTat) {
                if (techObj.HL_Loan_Application__r.Sanction_Loan_Amount__c >= 5000000 && checkTechForTat.size()>1) {
                    loanIds.add(techObj.HL_Loan_Application__c);
                }else if(techObj.HL_Loan_Application__r.Sanction_Loan_Amount__c < 5000000 && checkTechForTat.size()>0){
                    loanIds.add(techObj.HL_Loan_Application__c);
                }
            }
            List<TAT__c> existingTatRecList = [SELECT Id FROM TAT__c where Code__c = 'C-053'  AND Loan_Application__c IN:loanIds];
							if(existingTatRecList.size()>0){
								for(TAT__c tatRec : existingTatRecList){
									tatRec.End_Timestamp__c = System.now();
								}
								update existingTatRecList;
							}
                        
            //updated-Ayushi
            String newTechId = tech.Id; // Get the ID of the new report
            // Link the shared documents
            List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
            if (techWrapperObj.documentIds != null && !techWrapperObj.documentIds.isEmpty()) {
                List<Document_Details__c> docsFromTable = [
                    SELECT Id, Name, HL_Linked_Technical_Reports_IDs__c, Document_Category__c 
                    FROM Document_Details__c 
                    WHERE Id IN :techWrapperObj.documentIds
                ];
                List<Document_Details__c> sharedDocsToLink = new List<Document_Details__c>();
                
                for (Document_Details__c doc : docsFromTable) {
                    // Link ONLY the "shared" docs (where category is blank)
                    if (String.isBlank(doc.Document_Category__c)) { 
                        String linkedIds = doc.HL_Linked_Technical_Reports_IDs__c;
                        // Add the new technical ID to the new text field
                        if (String.isBlank(linkedIds)) {
                            doc.HL_Linked_Technical_Reports_IDs__c = newTechId;
                        } else if (!linkedIds.contains(newTechId)) {
                            doc.HL_Linked_Technical_Reports_IDs__c += ';' + newTechId;
                        }
                        sharedDocsToLink.add(doc);

                        if(isHLRelated && currentPermissions.contains('PS_Technical_Manager_HL')){
                            Utility.SharingInfo si1 = new Utility.SharingInfo();
                            si1.objectName = 'Document_Details__c';
                           // si1.userOrGroupId = assignedUser.Id;
                            si1.recordToShareId = doc.Id;
                            si1.sharingAccess = Constants.EDIT_ACCESS;
                            sharingList.add(si1);
                        }
                        
                    }
                }
                
                
                if (!sharedDocsToLink.isEmpty()) {
                    Database.update(sharedDocsToLink, false);
                }
            }//end updated

            List<Applicant_Address__c> appAdd = [SELECT Id,Application_Collateral__c,Address_Type__c,Applicant__c,Legal__c,HL_Address_Line_1__c,HL_Address_Line_2__c,HL_Address_Line_3__c,Pincode__c 
            FROM Applicant_Address__c where Application_Collateral__c =:  appCollateralList[0].Id limit 1];
            if(appAdd.size()>0){
                Applicant_Address__c newAppAddress = appAdd[0].clone(false, false, false, false);
                newAppAddress.Address_Type__c = appAdd[0].Address_Type__c;
                newAppAddress.Applicant__c = appAdd[0].Applicant__c;
                newAppAddress.Loan_Application__c =techWrapperObj.loanId;
                newAppAddress.Technical_Evaluation__c = tech.Id;
                insert newAppAddress;
            }
            

            List<Document_Details__c> reqDocList = new List<Document_Details__c>();

            //Check if already a Technical Report exists
            reqDocList = [SELECT Id, Name, Document_Required__c,Technical__r.HL_Stage__c,Technical__c, Content_Document_Id__c, Is_New_Created__c FROM Document_Details__c WHERE (Technical__c =:tech.Id OR Technical__c=null) AND Loan_Application__c = :techWrapperObj.loanId
                        AND Name =:Constants.TECHNICAL_DOCUMENT_NAME AND Document_Required__c =:Constants.DOCUMENT_CHECKLIST_REQUIRED ORDER BY CreatedDate DESC];
            
            //Ceate Technical Report records            
            if(reqDocList.isEmpty()){
                Document_Details__c docCheck = new Document_Details__c();
                docCheck.Requirement_At__c = 'Collateral Level';
                docCheck.Document_Category__c = Constants.DOCUEMNT_TYPE_TECHNICAL_TYPE;
                docCheck.Name = Constants.TECHNICAL_DOCUMENT_NAME;
                docCheck.Collateral_Master__c = appCollateralList[0].Collateral__c;
                docCheck.Application_Collateral__c = appCollateralList[0].Id;
                docCheck.Loan_Application__c = techWrapperObj.loanId;
                docCheck.Document_Required__c = Constants.DOCUMENT_CHECKLIST_REQUIRED;
                docCheck.HL_Show_Document_In_Table__c = false;//updated-Ayushi
                docCheck.Technical__c = tech.Id;
                insert docCheck;
                
                if(techWrapperObj.reportType == 'Internal') {
                    Document_Details__c docCheck1 = new Document_Details__c();
                    docCheck1.Requirement_At__c = 'Collateral Level';
                    docCheck1.Document_Category__c = Constants.DOCUEMNT_TYPE_TECHNICAL_TYPE;
                    docCheck1.Name = 'Google Earth Screen Shot';
                    docCheck1.Collateral_Master__c = appCollateralList[0].Collateral__c;
                    docCheck1.Application_Collateral__c = appCollateralList[0].Id;
                    docCheck1.Loan_Application__c = techWrapperObj.loanId;
                    docCheck1.Document_Required__c = 'Required';
                    docCheck1.HL_Show_Document_In_Table__c = false;//updated-Ayushi
                    docCheck1.Technical__c = tech.Id;
                    insert docCheck1;
                }

                if(isHLRelated && currentPermissions.contains('PS_Technical_Manager_HL')){
                    Utility.SharingInfo si1 = new Utility.SharingInfo();
                    si1.objectName = 'Document_Details__c';
                    //si1.userOrGroupId = assignedUser.Id;
                    si1.recordToShareId = docCheck.Id;
                    si1.sharingAccess = Constants.EDIT_ACCESS;
                    sharingList.add(si1);
                }
            }
            
            if(sharingList.size()>0){
                Utility.createShareRecord(JSON.serialize(sharingList));
            }
            List<Document_Details__c> unlinkedDocuments = new List<Document_Details__c>();
            for (Document_Details__c doc : [SELECT Id, Document_Category__c FROM Document_Details__c WHERE Loan_Application__c = :techWrapperObj.loanId AND Document_Category__c = :Constants.DOCUEMNT_TYPE_TECHNICAL_TYPE AND Technical__c = null]) {
                doc.Technical__c = tech.Id;
                unlinkedDocuments.add(doc);
            }
            if (!unlinkedDocuments.isEmpty()) {
                update unlinkedDocuments;
            }*/
            
            return tech.Id;
        
    }
    
    //Fetch all the created Technical records
    @AuraEnabled
    public static List<TechWrapper> getTechnicalRecords(Id recordId) {
        List<TechWrapper> wrapperList = new List<TechWrapper>();
        Integer srNo = 1;
        
        try {
            List<Technical_Evaluation__c> technicals = [
                SELECT Id, Name, HL_Owner__c, HL_Stage__c, CreatedDate, CreatedBy.Name,
                HL_Application_Collateral__c, HL_Application_Collateral__r.Name_of_Collateral__c,
                HL_Application_Collateral__r.Asset_Type__c,HL_Application_Collateral__r.Collateral__r.Document_Value__c,HL_Application_Collateral__r.Collateral__r.Market_Value__c,
                 HL_Application_Collateral__r.Collateral__r.Remarks__c,
                HL_Assigned_to_Technical_Manager__c, HL_Assigned_To_Technical_Manager__r.Name,HL_Assigned_to_Technical_Admin__c, HL_Assigned_to_Technical_Admin__r.Name, Loan_Amount_Requested__c,
                HL_Closed_Date__c, HL_Valuation__c,AHL_Recommended_Value__c, HL_Is_Final_Valuation__c,HL_Vendor_Agency__r.name,HL_Technical_Type__c
                FROM Technical_Evaluation__c 
                WHERE HL_Loan_Application__c = :recordId 
                ORDER BY Name DESC
            ];
            
            if (technicals.isEmpty()) {
                return wrapperList; // Nothing to process
            }
            
            Set<Id> collateralIds = new Set<Id>();
            for (Technical_Evaluation__c tech : technicals) {
                if (tech.HL_Application_Collateral__c != null) {
                    collateralIds.add(tech.HL_Application_Collateral__c);
                }
            }
            
            Map<Id, String> addressMap = new Map<Id, String>();
            if (!collateralIds.isEmpty()) {
                
                for (Application_Collateral__c addr : [Select Id,Name_of_Collateral__c,State__c,Collateral__r.State__c, Collateral__c, 
                                                       Collateral__r.Plot_Number__c, Collateral__r.Floor_Number__c,Collateral__r.Landmark__c, 
                                                       Collateral__r.Building_Street_Name__c, Collateral__r.Pincode__c, Collateral__r.Pincode__r.Name, 
                                                       Collateral__r.Address_Line_1__c,Collateral__r.Address_Line_2__c,Collateral__r.Address_Line_3__c,
                                                       Asset_Type__c from Application_Collateral__c where ID IN:collateralIds]){
                                                           String addressData = '';
                                                           //updated Ayushi
                                                           HLContext ctx = new HLContext(recordId);
                                                           addressMap.put(addr.Id,  resolveAddress(addr.Collateral__r, ctx));
                                                           //addressMap.put(addr.Id, buildAddress(addr.Collateral__r));
                                                           //end updated
                                                       }
            }
            
            for (Technical_Evaluation__c tech : technicals) {
                String address = addressMap.containsKey(tech.HL_Application_Collateral__c)
                    ? addressMap.get(tech.HL_Application_Collateral__c)
                    : '';
                wrapperList.add(new TechWrapper(tech, srNo++, address));
            }
            
            return wrapperList;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching technical records: ' + e.getMessage());
        }
    }
    // Address concatenation for Collateral
    /*blic static String buildAddress(Applicant_Address__c addr) {
        String addressData = '';
        
        if (addr.Plot_Number__c != null) {
            addressData += addr.Plot_Number__c;
        }
        if (addr.Building_Street_Name__c != null) {
            addressData = addressData != '' ? addressData + ', ' + addr.Building_Street_Name__c : addr.Building_Street_Name__c;
        }
        if (addr.Landmark__c != null) {
            addressData = addressData != '' ? addressData + ', ' + addr.Landmark__c : addr.Landmark__c;
        }
        if (addr.Post_Office_Name__c != null) {
            addressData = addressData != '' ? addressData + ', ' + addr.Post_Office_Name__c : addr.Post_Office_Name__c;
        }
        if (addr.Town__c != null) {
            addressData = addressData != '' ? addressData + ', ' + addr.Town__c : addr.Town__c;
        }
        if (addr.District__c != null) {
            addressData = addressData != '' ? addressData + ', ' + addr.District__c : addr.District__c;
        }
        if (addr.State__c != null) {
            addressData = addressData != '' ? addressData + ', ' + addr.State__c : addr.State__c;
        }
        if (addr.Pincode__c != null) {
            addressData = addressData != '' ? addressData + ' - ' + addr.Pincode__r.Name : addr.Pincode__c;
        }
        
        return addressData;
    }*/

    public static String buildAddress(Collateral__c collateral) {
        List<String> parts = new List<String>();
        
        if (collateral.Plot_Number__c != null) {
            parts.add(collateral.Plot_Number__c);
        }
        if (collateral.Building_Street_Name__c != null) {
            parts.add(collateral.Building_Street_Name__c);
        }
        if (collateral.Landmark__c != null) {
            parts.add(collateral.Landmark__c);
        }    
        if (collateral.State__c != null) {
            parts.add(collateral.State__c);
        }
        
        String addressData = String.join(parts, ', ');
        
        if (collateral.Pincode__r != null && collateral.Pincode__r.Name != null) {
            addressData += ' - ' + collateral.Pincode__r.Name;
        }
        
        return addressData;
    }
    //updated Ayushi
    public static String buildAddressAHL(Collateral__c collateral,boolean isTechnicalEval) {
        List<String> parts = new List<String>();
        
        if (collateral.Plot_Number__c != null && !isTechnicalEval) {
            parts.add(collateral.Plot_Number__c);
        }
        if (collateral.Building_Street_Name__c != null  && !isTechnicalEval) {
            parts.add(collateral.Building_Street_Name__c);
        }
        if (collateral.Landmark__c != null && !isTechnicalEval) {
            parts.add(collateral.Landmark__c);
        }
        if (collateral.Address_Line_1__c != null && isTechnicalEval) {
            parts.add(collateral.Address_Line_1__c);
        }
        if (collateral.Address_Line_2__c != null && isTechnicalEval) {
            parts.add(collateral.Address_Line_2__c);
        }
        if (collateral.Address_Line_3__c != null && isTechnicalEval) {
            parts.add(collateral.Address_Line_3__c);
        }
        if (collateral.State__c != null) {
            parts.add(collateral.State__c);
        }
        
        String addressData = String.join(parts, ', ');
        
        if (collateral.Pincode__r != null && collateral.Pincode__r.Name != null) {
            addressData += ' - ' + collateral.Pincode__r.Name;
        }
        
        return addressData;
    }
    //end updated
    //Group by Collaterals
    @AuraEnabled
    public static List<Technical_Evaluation__c> getTechnicalRecordsByCollateral(Id collateralId, Id loanId) {
        try {
            List<Technical_Evaluation__c> technicals = [
                SELECT Id, Name, HL_Owner__c, HL_Stage__c, CreatedDate, CreatedBy.Name,
                    HL_Application_Collateral__c, HL_Application_Collateral__r.Name_of_Collateral__c,
                    HL_Application_Collateral__r.Asset_Type__c,
                    HL_Assigned_to_Technical_Manager__c, HL_Assigned_To_Technical_Manager__r.Name,
                    HL_Closed_Date__c, HL_Valuation__c,AHL_Recommended_Value__c
                FROM Technical_Evaluation__c 
                WHERE HL_Application_Collateral__c = :collateralId AND HL_Loan_Application__c = :loanId
                ORDER BY Name DESC
            ];  
            return technicals;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching technical records: ' + e.getMessage());
        }
    }

    //Delete the documents details and linked files
    @AuraEnabled
    public static void deleteDocumentsWithFiles(List<Id> documentDetailIds) {
        try {
            List<Document_Details__c> docList = [SELECT Id, Legal__c, Technical__c FROM Document_Details__c WHERE Id IN :documentDetailIds AND (Technical__c = NULL OR Legal__c = NULL)];
            if (docList.isEmpty()) return;

            Set<Id> docDetailIds = new Set<Id>();
            for (Document_Details__c d : docList) {
                docDetailIds.add(d.Id);
            }

            List<ContentDocumentLink> links = [
                SELECT Id, ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :docDetailIds
            ];

            delete links;

            delete docList;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to delete document or file: ' + e.getMessage());
        }
    }
    public class InitiateTechnicalWrapper{       
        @AuraEnabled public String techEvalId;
        @AuraEnabled public String loanId;
        @AuraEnabled public Id aplicationcolatteral;
        @AuraEnabled public String Owner;
        @AuraEnabled public String recordTypeName;  
         @AuraEnabled public String reportType;  
         @AuraEnabled public List<String> documentIds;//updated-Ayushi    
    }
    public class TechWrapper{
        @AuraEnabled public Integer srno;
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public String finalStatus;
        @AuraEnabled public Decimal valuation;
        @AuraEnabled public Decimal recommededValue;
        @AuraEnabled public String initiatedBy;
        @AuraEnabled public Decimal finalValuation;
        @AuraEnabled public String initiatedOn;
        @AuraEnabled public String closedDate;
        @AuraEnabled public String collateralType;
        @AuraEnabled public String collateralAddress;
        @AuraEnabled public Boolean isValuationSelected;
        @AuraEnabled public String collId;
        @AuraEnabled public Decimal docVal;
        @AuraEnabled public Decimal marketVal;
        @AuraEnabled public String remarks;
        //updated Ayushi
        @AuraEnabled public String assignedToAdmin;
        @AuraEnabled public Decimal requestedLoanAmount;
        //end updated
        @AuraEnabled public String vendorAgencyName;
        @AuraEnabled public String technicalType;
        @AuraEnabled public Boolean shoButton;
        public TechWrapper(Technical_Evaluation__c tech,Integer srno, String collateralAddress){
            this.srno=srno;
            this.id=tech.Id;
            this.name=tech.Name;
            this.status=tech.HL_Stage__c;
            this.valuation = tech.HL_Valuation__c;
            this.recommededValue = tech.AHL_Recommended_Value__c;
            this.initiatedBy=tech.CreatedBy.Name;   
            this.initiatedOn=tech.CreatedDate.formatGMT('MM/dd/yyyy');
            //updated Ayushi
            this.assignedToAdmin=tech.HL_Assigned_to_Technical_Admin__r.Name;
            this.requestedLoanAmount = tech.Loan_Amount_Requested__c;
            //end updated
            this.closedDate = tech.HL_Closed_Date__c != null ? tech.HL_Closed_Date__c.format() : '';
            this.isValuationSelected = tech.HL_Is_Final_Valuation__c;
            if(tech.HL_Stage__c == 'Rejected by Technical Manager'){
                this.finalStatus = 'Rejected';
            }
            if(tech.HL_Stage__c == 'Accepted by Technical Manager'){
                this.finalStatus = 'Approved';
                this.finalValuation = tech.HL_Valuation__c;
            }
            if(tech.HL_Stage__c == 'Rejected By Admin'){
                this.finalStatus = 'Rejected';
            }
            if(tech.HL_Application_Collateral__r.Asset_Type__c != null && tech.HL_Application_Collateral__r.Asset_Type__c != '') {
                this.collateralType = tech.HL_Application_Collateral__r.Name_of_Collateral__c + ' (' + tech.HL_Application_Collateral__r.Asset_Type__c + ')';
            }else{ 
                this.collateralType = tech.HL_Application_Collateral__r.Name_of_Collateral__c;
            }
            this.collateralAddress = collateralAddress;
            this.collId = tech.HL_Application_Collateral__c;
            this.vendorAgencyName=tech.HL_Vendor_Agency__r.name;
            this.docVal = tech.HL_Application_Collateral__r.Collateral__r.Document_Value__c;
             this.marketVal = tech.HL_Application_Collateral__r.Collateral__r.Market_Value__c;
            
            this.remarks = tech.HL_Application_Collateral__r.Collateral__r.Remarks__c;
            this.technicalType = tech.HL_Technical_Type__c != null ? tech.HL_Technical_Type__c : '';
            this.shoButton = (tech.HL_Stage__c != 'Accepted by Technical Manager' && tech.HL_Stage__c != 'Accepted by CO/CM');
        }
    }
    @AuraEnabled
    public static List<TechnicalGridWrapper> getTechnicalEvluationStatusGrid(string loanId){
        List<TechnicalGridWrapper> result = new List<TechnicalGridWrapper>();
        List<Opportunity> opp = [Select Sanction_Loan_Amount__c From Opportunity Where Id =: loanId];
        Decimal sanctionLoanAmount = opp[0].Sanction_Loan_Amount__c != null ? opp[0].Sanction_Loan_Amount__c : 1;

        List<Technical_Evaluation_Master__mdt> techMaster = [Select Id, Required_Evaluation__c From Technical_Evaluation_Master__mdt Where 
                                                            Loan_Amount_From__c <=: sanctionLoanAmount And Loan_Amount_To__c >=: sanctionLoanAmount];
        
        system.debug('techMaster: '+techMaster);
        if(!techMaster.isEmpty()){
            TechnicalGridWrapper item = new TechnicalGridWrapper();
            item.recordId = techMaster[0].Id;
            item.requiredTechnical = techMaster[0].Required_Evaluation__c.toString();
            item.initiatedTechnical = '0';
            //item.completedTechnical = '0';

            List<Technical_Evaluation__c> techList = [Select Id, HL_Stage__c From Technical_Evaluation__c Where HL_Loan_Application__c =: loanId];
            if(!techList.isEmpty()){
                item.initiatedTechnical = techList.size().toString();
                //item.completedTechnical = '';
            }

            result.add(item);
        }
        system.debug('result: '+result);
        return result;
    }
    public class TechnicalGridWrapper {
        @AuraEnabled public String recordId;
        @AuraEnabled public String requiredTechnical;
        @AuraEnabled public String initiatedTechnical;
    }
    @AuraEnabled
    public static void updateCollateral(String collId, String val, String techId, Decimal valuation){
        try{
            List<Application_Collateral__c> appColl = [SELECT id,HL_Loan_Application__c,Collateral__c FROM Application_Collateral__c WHERE Id = :collId LIMIT 1];
            if(val == 'selected'){
                List<Technical_Evaluation__c> techVal = [SELECT id,Documented_Value__c, AHL_Recommended_Value__c FROM Technical_Evaluation__c WHERE Id = :techId LIMIT 1];
                Technical_Evaluation__c tech = new Technical_Evaluation__c();
                tech.Id = techId;
                tech.HL_Is_Final_Valuation__c = true;
                Update tech;
                Application_Collateral__c coll = new Application_Collateral__c();
                coll.Id = collId;
                coll.Total_Valuation__c = valuation;
                Update coll;
                List<Collateral__c> collDet =[Select id, Market_Value__c,Document_Value__c,Recommended_Value__c from Collateral__c where id=: appColl[0].Collateral__c];
                if(collDet.size()>0){
                    
                    
                    collDet[0].Market_Value__c =valuation; // String.isNotBlank(techVal[0].Documented_Value__c) ? Decimal.valueOf(techVal[0].Documented_Value__c): null;
                    if(String.isNotBlank(techVal[0].Documented_Value__c)) {
                        String cleanedValue = techVal[0].Documented_Value__c;
                        cleanedValue = cleanedValue.replace(',', '');
                        collDet[0].Document_Value__c =  Decimal.valueOf(cleanedValue);
                    }else {
                         collDet[0].Document_Value__c = null;
                    }
                    
                    collDet[0].Recommended_Value__c =techVal[0].AHL_Recommended_Value__c;
                    Update collDet;
                }
                List<Technical_Evaluation__c> techList = [Select Id from Technical_Evaluation__c where HL_Application_Collateral__c =: collId and Id !=: techId];
                if(!techList.isEmpty()){
                    for(Technical_Evaluation__c iterTech : techList){
                        iterTech.HL_Is_Final_Valuation__c = false;
                    }
                    Update techList;
                }
            }
            else{
                Application_Collateral__c coll = new Application_Collateral__c();
                coll.Id = collId;
                coll.Total_Valuation__c = valuation;
                Update coll;
                Technical_Evaluation__c tech = new Technical_Evaluation__c();
                tech.Id = techId;
                tech.HL_Is_Final_Valuation__c = false;
                Update tech;
            }
            if(appColl.size() > 0 && appColl[0].HL_Loan_Application__c != null) {
                Comm_LoanCollateralValuationController.updateValuationOnLoanAndProducnt(appColl[0].HL_Loan_Application__c);

            }
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

public class OptionWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public OptionWrapper(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled
    public static Map<String, List<OptionWrapper>> getTechnicalOptions(String loanId) {
        try {
            System.debug('loanId : '+loanId);
            Map<String, List<OptionWrapper>> result = new Map<String, List<OptionWrapper>>();
            Map<Id, String> collateralNameMap = new Map<Id, String>();
            // Step 1: Get Collaterals
            List<Application_Collateral__c> apc = [
                SELECT Id, Collateral__c, Collateral__r.Name, Collateral__r.Document_Value__c
                FROM Application_Collateral__c
                WHERE HL_Loan_Application__c = :loanId
            ];
            for (Application_Collateral__c ap : apc) {
                if (ap.Collateral__c != null) {
                    String collateralName = ap.Collateral__r.Name;
                    if (!result.containsKey(collateralName)) {
                        result.put(collateralName, new List<OptionWrapper>());
                    }
               // Add DV option
                if (ap.Collateral__r.Document_Value__c != null) {
                    Decimal dv = ap.Collateral__r.Document_Value__c.setScale(2);
                    String dvStr = String.valueOf(dv); // 🔥 NO commas

                    String dvLabel = 'DV-' + dvStr;
                    result.get(collateralName).add(
                        new OptionWrapper(dvLabel, dvStr)
                    );
                }
                collateralNameMap.put(ap.Collateral__c, ap.Collateral__r.Name);
                }
            }
            // Step 2: Get Technical Evaluations
            List<Technical_Evaluation__c> tevList = [
                SELECT Id, Name, HL_Stage__c, HL_Application_Collateral__r.Collateral__c,HL_Valuation__c
                FROM Technical_Evaluation__c
                WHERE HL_Stage__c = 'Accepted by Technical Manager'
                AND HL_Loan_Application__c = :loanId
            ];
            // Step 3: Group data
            for (Technical_Evaluation__c tev : tevList) {
                Id colId = tev.HL_Application_Collateral__r.Collateral__c;
                String collateralName = collateralNameMap.get(colId);
                if (!result.containsKey(collateralName)) {
                    result.put(collateralName, new List<OptionWrapper>());
                }
                result.get(collateralName).add(
                    new OptionWrapper(tev.Name, String.valueOf(tev.HL_Valuation__c))  // Label = name, Value = Id
                );
            }
            System.debug('651 result : '+result);
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void UpdateCol(String name,String value,String remarks){
        try {
            System.debug('name : '+name);
            System.debug('value : '+value);
            List<String> values = value.split(';');
            String loanId = values[1];
            value = values[0];
            System.debug('values : '+values);
            String cleanName = name.split('\\(')[0].trim();
            System.debug('cleanName : '+cleanName);
            List<Collateral__c> coList = [Select Id,name,Market_Value__c, Document_Value__c ,Remarks__c from Collateral__c where name=:cleanName Limit 1];
            System.debug('coList : '+coList);
            if(!coList.isEmpty()){
                coList[0].Market_Value__c = Decimal.valueOf(value);
                coList[0].Remarks__c = remarks;
                update coList;

                if(coList[0].Document_Value__c != Decimal.valueOf(value)){
                    List<Technical_Evaluation__c> tevList = [
                        SELECT Id, Name, HL_Stage__c,HL_Is_Final_Valuation__c, HL_Application_Collateral__r.Collateral__c,HL_Valuation__c
                        FROM Technical_Evaluation__c
                        WHERE HL_Loan_Application__c=:loanId
                    ];
                    List<Technical_Evaluation__c> tevListtoUpdate = new List<Technical_Evaluation__c>();
                    for(Technical_Evaluation__c tev : tevList){
                        if(tev.HL_Valuation__c == Decimal.valueOf(value)){
                            Technical_Evaluation__c technical = new Technical_Evaluation__c();
                            technical.Id = tev.Id;
                            technical.HL_Is_Final_Valuation__c = true;
                            tevListtoUpdate.add(technical);
                        }
                        else if(tev.HL_Valuation__c != Decimal.valueOf(value)){
                            Technical_Evaluation__c technical = new Technical_Evaluation__c();
                            technical.Id = tev.Id;
                            technical.HL_Is_Final_Valuation__c = false;
                            tevListtoUpdate.add(technical);
                        }
                    }
                    if(tevListtoUpdate.size()>0){
                        update tevListtoUpdate;
                    }
                }
            }
            
        } catch (Exception e) { 
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string updateTechnicalTeamMember( String recordId){
        String result = 'success';
        try {
            List<Technical_Evaluation__c> unAssignedRecords= [SELECT Id, HL_Stage__c, HL_Assigned_to_Technical_Manager__c FROM Technical_Evaluation__c WHERE HL_Stage__c != 'Accepted by Technical Manager' AND HL_Stage__c !='Report accepted by Admin' AND HL_Loan_Application__c= :recordId];
            if(unAssignedRecords.size()>0){
                for(Technical_Evaluation__c te: unAssignedRecords){
                    te.HL_Assigned_to_Technical_Manager__c = UserInfo.getUserId();
                }
                update unAssignedRecords;
                List<OpportunityTeamMember> otm= [SELECT Id, Associated_With_Loan_Application__c, UserId FROM OpportunityTeamMember WHERE TeamMemberRole= 'Technical Manager' AND OpportunityId= :recordId];
                List<OpportunityTeamMember> otmToUpdate= new List<OpportunityTeamMember>();
                if(otm.size()>0){
                    for(OpportunityTeamMember otm1: otm){
                        if(otm1.UserId == UserInfo.getUserId()){
                            OpportunityTeamMember member= new OpportunityTeamMember();
                            member.Id= otm1.Id;
                            member.OpportunityAccessLevel = 'Edit';
                            member.Associated_With_Loan_Application__c = true;
                            otmToUpdate.add(member);
                        }else{
                            OpportunityTeamMember member= new OpportunityTeamMember();
                            member.Id= otm1.Id;
                            member.Associated_With_Loan_Application__c = false;
                            otmToUpdate.add(member);
                        }
                    }
                }else {
                    OpportunityTeamMember member= new OpportunityTeamMember();
                    member.OpportunityId= recordId;
                    member.UserId= UserInfo.getUserId();
                    member.OpportunityAccessLevel = 'Edit';
                    member.Associated_With_Loan_Application__c = true;
                    member.TeamMemberRole= 'Technical Manager';
                    otmToUpdate.add(member);
                }
                upsert otmToUpdate;
            }else {
                result= 'No technical records found.';
            }
            
        } catch (Exception e) {
            result = e.getMessage();
            // throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

    @AuraEnabled
public static Boolean checkTechnicalManagerUser(Id recordId) {

     Map<String,String> inputMapUtility = new  Map<String,String>();
        inputMapUtility.put('oppId', recordId);
        Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.getProductDetails(inputMapUtility);
        Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
        List<String> currentPermissions = Utility_V1.getCurrentUserPermissionSets();

    //currentPermissions.contains('PS Technical Manager HL')

    if ((!isHLRelated && Utility.getCurrentUserProfileName() != Constants.TECHNICAL_MANAGER_PROFILE) || (isHLRelated && !currentPermissions.contains('PS_Technical_Manager_HL'))) {
        return true;
    }

    List<OpportunityTeamMember> otmList = [
        SELECT Id, Associated_With_Loan_Application__c
        FROM OpportunityTeamMember
        WHERE UserId = :UserInfo.getUserId()
        AND TeamMemberRole = 'Technical Manager'
        AND OpportunityId = :recordId
        AND Associated_With_Loan_Application__c = false
        LIMIT 1
    ];

   return false;
}

//updated Ayushi
private static String resolveAddress(
    Collateral__c collateral,
    HLContext ctx
) {
    if (ctx.isHLRelated) {
        return buildAddress(collateral);
    } else {
        return buildAddressAHL(collateral, true);
    }
}

public class HLContext {
    public Boolean isHLRelated;
    public Id loanId;

    public HLContext(Id loanId) {
        this.loanId = loanId;
        this.isHLRelated = resolveHL();
    }

    private Boolean resolveHL() {
        Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('oppId', loanId);

        Utility_V1.ProductWrapper pw = Utility_V1.getProductDetails(inputMap);
        return (pw != null && pw.isHLRelated);
    }
}
//end updated

    @AuraEnabled
    public static String submitLoanForApproval(String technicalId,String remarks){
        String res;
        try {
            List<Technical_Evaluation__c> technicalData= [SELECT Id,Name,HL_Stage__c,HL_Loan_Application__c FROM Technical_Evaluation__c WHERE Id = :technicalId LIMIT 1];
            if(technicalData.size()>0 && technicalData[0].HL_Stage__c != null){
                List<OpportunityTeamMember> approverMembers = new List<OpportunityTeamMember>();
                String loanId = technicalData[0].HL_Loan_Application__c;
                approverMembers = [SELECT Id, UserId FROM OpportunityTeamMember WHERE OpportunityId = :loanId AND TeamMemberRole = 'Technical Manager' AND User.User_Type__c = 'Internal'];
                if(approverMembers.size() > 0){
                    Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                    System.debug('HK Approval Process Created');
                    technicalData[0].HL_Stage__c = 'Submitted';
                    technicalData[0].HL_Remarks__c = remarks;
                    update technicalData;
                    request.setComments(remarks);
                    request.setObjectId(technicalId);
                    request.setNextApproverIds(new Id[] { approverMembers[0].UserId });
                    request.setProcessDefinitionNameOrId('Internal_Technical_Approval_Process');        
                    Approval.ProcessResult result = Approval.process(request);
                   
                    res= 'Succesfully Submitted For Approval';                                                          
                }else{
                    res = 'No approver found for this loan';
                }
            }  
        } catch (Exception e) {
            System.debug('error --> '+e);
            System.debug('error --> '+e.getLineNumber());
            res= 'Error: '+e.getMessage();        }

        return res;
    }

    @AuraEnabled
    public static List<String> performApprovalAction(String technicalId, String action,String remarks){
        List<String> validations= new List<String>();
        try {
            List<Technical_Evaluation__c> technicalData = [SELECT Id,Name,HL_Stage__c,HL_Loan_Application__c, Is_Report_Uploaded__c FROM Technical_Evaluation__c WHERE Id = :technicalId LIMIT 1];
            List<ProcessInstanceWorkitem> processsInstanceList = [SELECT Id, ProcessInstanceId,CreatedById FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: technicalId];
            if(processsInstanceList.size()>0){
                List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
                String actionStatus;
                String stage = '';
                if(action == 'Send Back'){
                    stage = 'Sent Back';
                }
                else if(action == 'Approv'){
                    stage = 'Accepted by Technical Manager';
                }
                else{
                    stage = 'Rejected';
                }
                for(ProcessInstanceWorkitem workItem : processsInstanceList){
                    Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                    req.setWorkitemId(workItem.Id);
                    if(action == 'Approv' && technicalData[0].Is_Report_Uploaded__c == true){
                        actionStatus= 'Approve';
                    }else if(action == 'Reject' || action == 'Send Back'){
                        actionStatus= 'Reject';
                    }
                    req.setAction(actionStatus); 
                    req.setComments(remarks);
                    requests.add(req);
                    System.debug(requests);
                }
                System.debug('HK Approval Before');
                Approval.ProcessResult[] processResults = Approval.process(requests);
                System.debug('HK Approval After');
                technicalData[0].HL_Stage__c = stage;
                technicalData[0].HL_Remarks__c = remarks;
                update technicalData;
                validations.add('success');
            }
            else{
                System.debug('ProcessInstanceWorkitem not present');
            }
           
        } catch (Exception e) {
            System.debug('Error during approving record---'+ e.getMessage());
            validations.add('fail');
        }
        return validations;
    }
    
    @AuraEnabled
    public static Id createDocDetailForTechnical(Id techId, String docName, Boolean isRequired) {
        if (techId == null || String.isBlank(docName)) {
            throw new AuraHandledException('Technical id and docName are required.');
        }
        Document_Details__c d = new Document_Details__c();
        d.Technical__c = techId;
        d.Name           = docName.trim();
        d.Is_Required__c              = (isRequired == null) ? false : isRequired;
        d.Status__c                   = 'Pending';
        d.Active__c                   = true;
        insert d;
        return d.Id;
    }
    
    public class PDDocumentRow {
        @AuraEnabled public Id    docDetailId;
        @AuraEnabled public String documentName;
        @AuraEnabled public Boolean required;
        @AuraEnabled public String status;
        @AuraEnabled public Id    contentDocumentId;
        @AuraEnabled public String fileType;
        @AuraEnabled public Id    latestVersionId;
        @AuraEnabled public Datetime createdDate;
    }

    @AuraEnabled
    public static List<PDDocumentRow> getDocs(Id techId) {
        if (techId == null) return new List<PDDocumentRow>();
        List<Document_Details__c> ddList = [
            SELECT Id, Name, Is_Required__c, Status__c, Content_Document_Id__c, Active__c,CreatedDate
            FROM Document_Details__c
            WHERE Technical__c = :techId
              AND Active__c = true
            ORDER BY Is_Required__c DESC, CreatedDate DESC
        ];
        Set<Id> contDocSet = new Set<Id>();
        for (Document_Details__c d : ddList) {
            if (d.Content_Document_Id__c != null) contDocSet.add(d.Content_Document_Id__c);
        }
        Map<Id, String> fileExtByDocId = new Map<Id, String>();
        Map<Id, String> fileTitleByDocId = new Map<Id, String>();
        Map<Id, Id>     latestVersionByDocId = new Map<Id, Id>();

        if (!contDocSet.isEmpty()) {
            List<ContentDocumentLink> cdlList = [
                SELECT ContentDocumentId,
                       ContentDocument.Title,
                       ContentDocument.FileExtension,
                       LinkedEntityId
                FROM ContentDocumentLink
                WHERE ContentDocumentId IN :contDocSet
                // no ORDER BY needed; we only need extension/title per ContentDocument
            ];
            for (ContentDocumentLink link : cdlList) {
                if (!fileExtByDocId.containsKey(link.ContentDocumentId)) {
                    fileExtByDocId.put(link.ContentDocumentId,
                        link.ContentDocument.FileExtension != null
                        ? link.ContentDocument.FileExtension.toLowerCase()
                        : null
                    );
                }
                if (!fileTitleByDocId.containsKey(link.ContentDocumentId)) {
                    fileTitleByDocId.put(link.ContentDocumentId, link.ContentDocument.Title);
                }
            }
            for (ContentVersion cv : [
                SELECT Id, ContentDocumentId, VersionNumber, FileExtension
                FROM ContentVersion
                WHERE ContentDocumentId IN :contDocSet
                ORDER BY ContentDocumentId, VersionNumber DESC
            ]) {
                if (!latestVersionByDocId.containsKey(cv.ContentDocumentId)) {
                    latestVersionByDocId.put(cv.ContentDocumentId, cv.Id);
                    // If extension was missing above, fall back to ContentVersion.FileExtension
                    if (fileExtByDocId.get(cv.ContentDocumentId) == null && cv.FileExtension != null) {
                        fileExtByDocId.put(cv.ContentDocumentId, cv.FileExtension.toLowerCase());
                    }
                }
            }
            if (fileExtByDocId.values().contains(null)) {
                Map<Id, ContentDocument> cdRecMap = new Map<Id, ContentDocument>([
                    SELECT Id, FileType
                    FROM ContentDocument
                    WHERE Id IN :contDocSet
                ]);
                for (Id docId : contDocSet) {
                    if (fileExtByDocId.get(docId) == null) {
                        String ft = cdRecMap.get(docId)?.FileType;
                        if (ft != null) fileExtByDocId.put(docId, ft.toLowerCase());
                    }
                }
            }
        }
        List<PDDocumentRow> outRows = new List<PDDocumentRow>();
        for (Document_Details__c d : ddList) {
            PDDocumentRow r = new PDDocumentRow();
            r.docDetailId       = d.Id;
            r.documentName      = d.Name;
            r.required          = d.Is_Required__c;
            r.status            = d.Status__c;
            r.contentDocumentId = d.Content_Document_Id__c;
            r.fileType          = (d.Content_Document_Id__c != null) ? fileExtByDocId.get(d.Content_Document_Id__c) : null;
            //r.fileTitle         = (d.Content_Document_Id__c != null) ? fileTitleByDocId.get(d.Content_Document_Id__c) : null;
            r.latestVersionId   = (d.Content_Document_Id__c != null) ? latestVersionByDocId.get(d.Content_Document_Id__c) : null;
            outRows.add(r);
        }
        System.debug(outRows);
        return outRows;
    }

    @AuraEnabled
    public static Boolean checkOTM(String loanId){
        Boolean result= false;
        List<OpportunityTeamMember> otmList = [SELECT Id FROM OpportunityTeamMember WHERE TeamMemberRole = 'Technical Manager' AND Associated_With_Loan_Application__c = true AND UserId = :UserInfo.getUserId() AND OpportunityId = :loanId ];
        if(otmList.size() > 0){
            result = true;
        }
        System.debug('result: ' + result);
        return result;
    }

    @AuraEnabled
    public static ApprovalWrapper getApprovalHistory( String technicalId){
        ApprovalWrapper approvalData= new ApprovalWrapper();
        try {
            List<StatusHistoryWrapper> historyRecords= new List<StatusHistoryWrapper>();
            List<ProcessInstanceStep> approvalComments = [SELECT Id, Comments, StepStatus, Actor.Name,Actor.Profile.Name, CreatedDate,CreatedBy.Name,OriginalActorId,OriginalActor.Name FROM ProcessInstanceStep WHERE ProcessInstance.TargetObjectId = :technicalId AND ProcessInstance.ProcessDefinition.DeveloperName= 'Internal_Technical_Approval_Process' ORDER BY CreatedDate DESC];
            if(approvalComments.size() > 0){
                for(ProcessInstanceStep approvalStep: approvalComments){
                    StatusHistoryWrapper historyWrp= new StatusHistoryWrapper();
                    historyWrp.isRequestor =  approvalStep.StepStatus == 'Started' ? true : false;
                    historyWrp.status = approvalStep.StepStatus;
                    historyWrp.remarks = (approvalStep.Comments == null ? '': approvalStep.Comments);    
                    historyWrp.timeStamp = approvalStep.CreatedDate;
                    historyWrp.requestor=approvalStep.CreatedBy.Name;
                    historyRecords.add(historyWrp);
                }
                approvalData.statusHistory = historyRecords;
                approvalData.showApprovalHistory = true;
            }else {
                approvalData.showApprovalHistory = false;
            }           
        } catch (Exception e) {
            System.debug('e.getline'+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }

        return approvalData;
    }

    public class ApprovalWrapper {
        @AuraEnabled public Boolean showApprovalHistory=false;
        @AuraEnabled public List<StatusHistoryWrapper> statusHistory;
    }

    public class StatusHistoryWrapper{
        @AuraEnabled public String status;
        @AuraEnabled public String remarks;
        @AuraEnabled public String requestor;
        @AuraEnabled public DateTime timeStamp;
        @AuraEnabled public Boolean isRequestor= false;
    }
}