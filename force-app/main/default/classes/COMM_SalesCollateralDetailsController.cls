/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-15-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class COMM_SalesCollateralDetailsController {
        @AuraEnabled
        public static void deleteApplicant(Id applicantId) {
            try {
                // First delete Bank_Details__c records linked to the applicant
                List<Bank_Details__c> bankDetails = [
            SELECT Id 
            FROM Bank_Details__c 
            WHERE Application_Applicant__c = :applicantId 
        ];
                if (!bankDetails.isEmpty()) {
                    delete bankDetails;
                }
                
                // Next delete Applicant_Address__c records linked to the applicant
                List<Applicant_Address__c> applicantAddresses = [
            SELECT Id 
            FROM Applicant_Address__c 
            WHERE Applicant__c = :applicantId
        ];
                if (!applicantAddresses.isEmpty()) {
                    delete applicantAddresses;
                }
                
                // Finally delete the Application_Applicant__c record itself
                delete [SELECT Id FROM Application_Applicant__c WHERE Id = :applicantId];
                
            } catch (Exception ex) {
                System.debug('Error deleting applicant: ' + ex.getMessage());
                throw new AuraHandledException('Failed to delete applicant: ' + ex.getMessage());
            }
        }

    
    @AuraEnabled
    public static List<BuilderSellerWrapper> getBuilderSellerApplicants(Id loanAppId, String applicantType) {
      try {
        List<Application_Applicant__c> applicants = [Select Id,Name,PAN_Number__c,DOI__c,Contact_Person_Name__c,Contact_Person_Number__c,CKYC_Aadhar__c,DOB__c,Customer_Type__c,Applicant_Type__c,Mobile_Number__c FROM Application_Applicant__c
            WHERE Loan_Application__c = :loanAppId 
            AND Applicant_Type__c = :applicantType
            ORDER BY CreatedDate DESC];
             Set<Id> applicantIds = new Set<Id>();

        for(Application_Applicant__c a : applicants){
            applicantIds.add(a.Id);
        }
        List<BuilderSellerWrapper> wrappedApplicants = new List<BuilderSellerWrapper>();

        if (applicants != null && !applicants.isEmpty()) {
            for (Application_Applicant__c appApplicant : applicants) {
                BuilderSellerWrapper wrapper = new BuilderSellerWrapper();
                wrapper.Id = appApplicant.Id;
                wrapper.applicantType = appApplicant.Applicant_Type__c;
                wrapper.applicantName=appApplicant.Name;
                wrapper.panNumber = appApplicant.PAN_Number__c;
                wrapper.doi = appApplicant.DOI__c;
                wrapper.contactPersonName = appApplicant.Contact_Person_Name__c;
                wrapper.contactPersonNumber = appApplicant.Contact_Person_Number__c;
                wrapper.aadharNumber = appApplicant.CKYC_Aadhar__c;
                wrapper.dob = appApplicant.DOB__c;
                wrapper.customerType = appApplicant.Customer_Type__c;
                wrapper.mobileNumber = appApplicant.Mobile_Number__c;
                wrapper.isDisabled = true;
                wrapper.disableEdit = false;
                wrappedApplicants.add(wrapper);
            }
        }
        return wrappedApplicants;

    }
    catch (Exception ex) {
        System.debug('Error in getBuilderSellerApplicants: ' + ex.getMessage());
        throw new AuraHandledException('Failed to retrieve applicants: ' + ex.getMessage());
    }
}

    //Added
public static void addTechnicalManagers(Id opportunityId) {
    if (opportunityId == null) return;
    
    Opportunity opp = [
        SELECT Id, Branch_Master__r.Pincode__r.State__c
        FROM Opportunity
        WHERE Id = :opportunityId
        LIMIT 1
    ];
    
    if (opp.Branch_Master__r == null ||
        opp.Branch_Master__r.Pincode__r == null ||
        String.isBlank(opp.Branch_Master__r.Pincode__r.State__c)) {
        return;
    }
    
    String stateName = opp.Branch_Master__r.Pincode__r.State__c.trim();
    
    // Query all Technical Manager mappings
    List<TechnicalManagerStateMapping__c> allMappings = [
        SELECT UserName__c, State__c
        FROM TechnicalManagerStateMapping__c
        WHERE State__c != null
    ];
    
    if (allMappings.isEmpty()) {
        System.debug('No Technical Manager mappings found');
        return;
    }
    
    // Collect usernames from mappings where State__c contains stateName
    Set<String> usernames = new Set<String>();
    for (TechnicalManagerStateMapping__c tm : allMappings) {
        String normalizedStates = ',' + tm.State__c.replaceAll('\\s*,\\s*', ',').trim() + ',';
        if (normalizedStates.containsIgnoreCase(',' + stateName + ',') && !String.isBlank(tm.UserName__c)) {
            usernames.add(tm.UserName__c.trim().toLowerCase());
        }
    }
    
    if (usernames.isEmpty()) {
        System.debug('No Technical Manager mappings found for state: ' + stateName);
        return;
    }
    
    // Resolve User Ids
    Set<Id> userIds = new Set<Id>();
    for (User u : [SELECT Id FROM User WHERE Username IN :usernames]) {
        userIds.add(u.Id);
    }
    if (userIds.isEmpty()) return;
    
    // Find existing Opportunity Team Members
    Set<Id> existingUserIds = new Set<Id>();
    for (OpportunityTeamMember otm : [
        SELECT UserId FROM OpportunityTeamMember WHERE OpportunityId = :opportunityId
    ]) {
        existingUserIds.add(otm.UserId);
    }
    
    // Prepare new Opportunity Team Members
    List<OpportunityTeamMember> otmToInsert = new List<OpportunityTeamMember>();
    for (Id uid : userIds) {
        if (!existingUserIds.contains(uid)) {
            otmToInsert.add(new OpportunityTeamMember(
                OpportunityId = opportunityId,
                UserId = uid,
                TeamMemberRole = 'Technical Manager',
                OpportunityAccessLevel = 'Edit'
            ));
        }
    }
    
    if (!otmToInsert.isEmpty()) {
        insert otmToInsert;
    }
}

    @AuraEnabled
    public static String upsertCollateralAndApplicationCollateral(String recordId,List<Id> selectedApplicants,String collateralJson,String collateralId,String reason) {
        System.debug('==> Starting upsertCollateralAndApplicationCollateral');
        //try {
            Id loanAppId = String.isNotBlank(recordId) ? Id.valueOf(recordId) : null;
            Id existingCollateralId = String.isNotBlank(collateralId) ? Id.valueOf(collateralId) : null;
            CollateralWrapper wrapper = (CollateralWrapper) JSON.deserialize(collateralJson, CollateralWrapper.class);
            Id existingAppAddId = String.isNotBlank(wrapper.appAddId) ? Id.valueOf(wrapper.appAddId) : null;
            Utility_V1.ProductWrapper wrp = Utility_V1.getProductDetails(new Map<String,String>{'oppId' => recordId});
            Boolean isHLRelated = wrp.isHLRelated ? true : false;
            System.debug('recordId: ' + recordId);
            System.debug('recordId: ' + recordId);
            System.debug('selectedApplicants: ' + selectedApplicants);
            System.debug('collateralId: ' + collateralId);
            System.debug('loanAppId: ' + loanAppId);
            System.debug('collateralJson: ' + collateralJson);
            System.debug('existingAppAddId----' + existingAppAddId);
            //HL-Ishi-15/9
            wrapper.checkUPID=false;
            wrapper.matchFound = 'Yes';
            Applicant_Address__c appadd = new Applicant_Address__c();
            appadd.Id = existingAppAddId != null ? existingAppAddId : null;
            System.debug('Deserialized wrapper: ' + wrapper);

            String reasonForNewUPID =  (String.isNotBlank(collateralId) &&  String.isNotBlank(reason)) ||  String.isBlank(collateralId) ? reason : wrapper.reason;

            Collateral__c collateralToUse = null;
            Boolean useExisting = false;

            if (wrapper.matchFound == 'Yes') {
                List<Collateral__c> dupList = [
                    SELECT Id, UPID__c, IsActive__c, Assigned_Percentage__c , Completion_Timeline__c
                    FROM Collateral__c 
                    WHERE UPID__c = :wrapper.upid AND IsActive__c = true 
                    LIMIT 1
                ];
                
                if (existingCollateralId == null) {
                    // New record
                    if (!dupList.isEmpty()) {
                        collateralToUse = dupList[0];
                        useExisting = true; 
                    } else {
                        collateralToUse = new Collateral__c();
                        collateralToUse.UPID__c = wrapper.upid;
                    }
                } else {
                    // Updating existing
                    if (dupList.isEmpty()) {
                        // No duplicate found, update existing
                        String existingUPID;
                        if(existingCollateralId!=null)
                        existingUPID = [
                            SELECT Id, UPID__c, IsActive__c, Assigned_Percentage__c , Completion_Timeline__c
                            FROM Collateral__c 
                            WHERE id = :existingCollateralId AND IsActive__c = true 
                            LIMIT 1
                        ].UPID__c;
                        System.debug('existingUPID=='+existingUPID);
                        System.debug('wrapper.upid=='+wrapper.upid);
                        wrapper.checkUPID=true;
                        // matchFound is No, proceed with insert/update as usual
                        if(wrapper.upid!=existingUPID){
                            wrapper.oldColId=existingCollateralId;
                        }
                        if(wrapper.upid==existingUPID){
                        collateralToUse = new Collateral__c(Id = existingCollateralId);
                        }
                        else{
                           collateralToUse = new Collateral__c();
                        }
                    } else {
                         
                        // String existingUPID;
                        // if(existingCollateralId!=null)
                        // existingUPID = [
                        //     SELECT Id, UPID__c, IsActive__c, Assigned_Percentage__c , Completion_Timeline__c
                        //     FROM Collateral__c 
                        //     WHERE id = :existingCollateralId AND IsActive__c = true 
                        //     LIMIT 1
                        // ].UPID__c;
                        // Duplicate found
                        List<Application_Collateral__c> existingLinks = [
                            SELECT Id 
                            FROM Application_Collateral__c 
                            WHERE Collateral__c = :existingCollateralId 
                            AND HL_Loan_Application__c != :loanAppId 
                            LIMIT 1
                        ];
                        if (!existingLinks.isEmpty()) {
                            collateralToUse = dupList[0];
                            useExisting = true;
                        } else {
                            if(existingCollateralId !=  dupList[0].Id){
                                Collateral__c toDeactivate = new Collateral__c(Id = existingCollateralId);
                                toDeactivate.IsActive__c = false;
                                update toDeactivate;
                            }  
                            collateralToUse = dupList[0];
                            useExisting = true;
                        }

                        Application_Collateral__c appCollateral = [
                            SELECT Id, Completion_Timeline__c
                            FROM Application_Collateral__c 
                            WHERE HL_Loan_Application__c = :loanAppId 
                            AND Collateral__c = :existingCollateralId 
                            LIMIT 1
                        ];
                        // if(wrapper.upid!=existingUPID){
                         wrapper.oldColId=dupList[0].id;
                        // }
                        appCollateral.Collateral__c = dupList[0].Id;
                        update appCollateral;
                    }
                }
            } 
            else {
                String existingUPID;
                if(existingCollateralId!=null){
                    existingUPID = [
                    SELECT Id, UPID__c, IsActive__c, Assigned_Percentage__c , Completion_Timeline__c
                    FROM Collateral__c 
                    WHERE id = :existingCollateralId AND IsActive__c = true 
                    LIMIT 1
                ].UPID__c;
                System.debug('existingUPID=='+existingUPID);
                System.debug('wrapper.upid=='+wrapper.upid);
                // matchFound is No, proceed with insert/update as usual
                wrapper.checkUPID=true;
                    if(wrapper.upid!=existingUPID){
                        wrapper.oldColId=existingCollateralId;
                    }
                }
                collateralToUse = (existingCollateralId != null && wrapper.upid==existingUPID) ? new Collateral__c(Id = existingCollateralId) : new Collateral__c();
                collateralToUse.UPID__c ='123';
                
                
            }
            // else {
            //     // matchFound is No, proceed with insert/update as usual
            //     collateralToUse = (existingCollateralId != null) ? new Collateral__c(Id = existingCollateralId) : new Collateral__c();
            //     collateralToUse.UPID__c = wrapper.upid;
            // }
             //Moving this code outside if (!useExisting), to create applicant address record for new and existing collateral- Ayushi
            if(isHlRelated){
            appAdd.Address_Line_1__c = wrapper.address1;
            appAdd.Address_Line_2__c = wrapper.address2;
            appAdd.Address_Line_3__c = wrapper.address3;
            appAdd.Pincode__c = wrapper.addPincode;
            appAdd.Collateral_Address_Type__c = wrapper.addressType;
            appAdd.Loan_Application__c = recordId;
            }
            if (!useExisting) {
                system.debug('96--');
                //   if(!isHlRelated){
                    collateralToUse.Address_Line_1__c = wrapper.address1;
                    collateralToUse.Address_Line_2__c = wrapper.address2;
                    collateralToUse.Address_Line_3__c = wrapper.address3;
                    collateralToUse.Pincode__c = wrapper.addPincode;
                    collateralToUse.Address_Type__c = wrapper.addressType;
                    collateralToUse.Completion_Timeline__c = wrapper.complitionTime;
                    
                    
                // }
               if(isHlRelated){
                     system.debug('107--');
                    //appAdd.Address_Line_1__c  = wrapper.address1; (commented line 114-119- Ayushi)
                    //appAdd.Address_Line_2__c = wrapper.address2;
                    //appAdd.Address_Line_3__c  = wrapper.address3;
                    //appAdd.Pincode__c = wrapper.addPincode;
                    //appAdd.Collateral_Address_Type__c = wrapper.addressType;
                    //appAdd.Loan_Application__c =recordId;
                    //appAdd.Applicant__c = selectedApplicants[0];
                    collateralToUse.RERA_End_Date__c = wrapper.reraEndDate;
                    //appAdd.Ownership_Type__c= wrapper.ownershipType;
                }
                system.debug('wrapper-------'+wrapper);   
                
                collateralToUse.Block_Taluka__c = wrapper.block;
                collateralToUse.Ownership_Type__c = wrapper.ownershipType;
                collateralToUse.Property_Usage__c = wrapper.propertyUsage;
                collateralToUse.Current_Usage__c = wrapper.currentUsage;
                collateralToUse.Project__c = wrapper.projId;
                collateralToUse.Unit_Project__c = wrapper.unitId;
                collateralToUse.Builder__c = wrapper.devId;
                collateralToUse.Unit_Property_Type__c = wrapper.unitType;
                collateralToUse.Tower_Building_Name__c = wrapper.towerName;
                collateralToUse.Floor_Number__c = wrapper.floor;
                collateralToUse.Unit_Number__c = wrapper.unitNumber;
                collateralToUse.Construction_Stage__c = wrapper.constructionStage;
                collateralToUse.Occupancy_Since__c = wrapper.occupancySince;
                collateralToUse.Estimated_Value__c = wrapper.estimatedValue;
                collateralToUse.Market_Value__c = wrapper.marketValue;
                collateralToUse.Area_of_Plot_Area__c = wrapper.areaOfPlot;
                collateralToUse.Carpet_Area_of_Residential_Unit_sq_m__c = wrapper.carpetArea;
                collateralToUse.RERA_Registration_Number__c = wrapper.reraRegNumber;
                collateralToUse.GPL_Flag__c = wrapper.gplFlag;
                collateralToUse.Property_Insurance_Flag__c = wrapper.insuranceFlag;
                collateralToUse.APF__c = wrapper.apfValue;
                collateralToUse.UPID__c = wrapper.upid;
                collateralToUse.Collateral_Type__c = wrapper.collateralType;
                collateralToUse.Primary_Secondary__c = 'Primary';
                collateralToUse.Reason__c = reasonForNewUPID;
                collateralToUse.State__c = wrapper.state;
                collateralToUse.APF_Number__c = wrapper.apfNumber;
                collateralToUse.Cost_of_Plot__c = wrapper.costOfPlot;
                collateralToUse.Improvement_Cost__c = wrapper.improvmentCost;
                collateralToUse.Agreement_Value__c = wrapper.agreementValue;
                collateralToUse.Society_Charges_Insurance__c = wrapper.societyCharges;
                collateralToUse.Total_Property_Cost_Sum_of_all__c = wrapper.totalPropertyCost;
                collateralToUse.Others__c = wrapper.others;
                collateralToUse.Allow_Multi_Assignment__c = wrapper.allowMultiAssignment;
                collateralToUse.Allow_third_party_assignment__c = wrapper.allowThirdPartyAssignment;
                collateralToUse.Amenities_as_permitted_by_Policy__c = wrapper.amenitiesPermitPolicy;
                collateralToUse.Architects_Contractors_Estimate__c = wrapper.architectsEstimate;
                collateralToUse.Electricty_Board_Municiple_Charges__c = wrapper.electricityMunicipleCharges;
                collateralToUse.Plot_Number__c = wrapper.plotNumber;
                collateralToUse.House_Flat_Shop_Unit_No__c = wrapper.housePlotNo;
                collateralToUse.Building_Name__c = wrapper.buildingName;
                collateralToUse.Street_Name__c = wrapper.streetName;
                collateralToUse.Building_Street_Name__c = wrapper.buildingName;//updated
                collateralToUse.Pocket__c  = wrapper.pocket;
                collateralToUse.Mortgage_Type__c = wrapper.mortgageType;
                collateralToUse.Asset_Collateral__c = wrapper.assetType;
                collateralToUse.Survey_Number_Gat_No__c  = wrapper.surveyNumber;
                collateralToUse.Pincode__c = wrapper.addPincode;
               collateralToUse.Assigned_Percentage__c = (wrapper.assignPercentageMatch != null && wrapper.assignPercentageMatch != 0) ? wrapper.assignPercentageMatch : wrapper.assignPercentage;
                collateralToUse.Document_Value__c = wrapper.docVal;
                if (wrapper.externalId != null) {
                    collateralToUse.External_Id__c = wrapper.externalId;
                }
                collateralToUse.UPID__c ='123';
                upsert collateralToUse;
                System.debug('Upserted Collateral ID: ' + collateralToUse.Id);
            } else {
                System.debug('Using existing matched collateral ID: ' + collateralToUse.Id);

                // ✅ If reused collateral, update Assigned_Percentage__c = sum
              //  Decimal baseVal = (wrapper.assignPercentage != null) ? wrapper.assignPercentage : 0;
                Decimal matchVal = (wrapper.assignPercentageMatch != null) ? wrapper.assignPercentageMatch : 0;
                Collateral__c updateColl = new Collateral__c(Id = collateralToUse.Id);
                updateColl.Assigned_Percentage__c = matchVal;
                update updateColl;
            }
             if(!isHlRelated){
                String returnRes = linkCollateralToApplication(collateralToUse.Id, loanAppId, selectedApplicants,wrapper); 
                String apCollId = returnRes.split('---')[1];
                returnRes = returnRes.split('---')[0];
                linkDocumentCheckListRec(apCollId, loanAppId);
                addTechnicalManagers(loanAppId);
                return returnRes;//linkCollateralToApplication(collateralToUse.Id, loanAppId, selectedApplicants,wrapper); 
            }
            else{
                String appCollId= linkCollateralToApplication(collateralToUse.Id, loanAppId, selectedApplicants,wrapper);
                //appadd.Application_Collateral__c =appCollId;
                if(wrapper.apfValue == 'Yes'){
                   List<Application_Applicant__c> primaryApplicant= [Select Id,Name From Application_Applicant__c Where Loan_Application__c =:loanAppId AND Applicant_TYpe__c = 'Primary Applicant' Limit 1];
                   appAdd.Applicant__c= primaryApplicant[0].Id;
                   flowCovenantsonLoan(wrapper.projId, loanAppId);
                }else{
                    appAdd.Applicant__c=selectedApplicants[0];
                }
                system.debug('appadd 197--'+appadd);
                if(appadd.Address_Line_1__c!= null){
                upsert appadd;
                }                
                linkDocumentCheckListRec(appCollId, loanAppId);
                return appCollId;
            }

        //} 
    	//catch (Exception e) {
        //    System.debug('Exception in upsertCollateralAndApplicationCollateral: ' + e.getMessage());
        //    throw new AuraHandledException('Error saving collateral and linking records: ' + e.getMessage());
        //}
    }
    public static void linkDocumentCheckListRec(String apColId, String loanId){
        List<Document_Details__c> docList = [Select Id from Document_Details__c where Loan_Application__c =: loanId and Requirement_Level__c = 'Collateral Level' and Application_Collateral__c =: apColId];
        if(!docList.isEmpty()){   
        }
        else{
            List<Application_Collateral__c> appColl =[Select id,Collateral__c from Application_Collateral__c where id=:apColId LIMIT 1];
            List<Document_Details__c> collDocList = [Select Id,Application_Collateral__r.Collateral__c,Content_Document_Id__c from Document_Details__c where Loan_Application__c =: loanId and Requirement_Level__c = 'Collateral Level' and Application_Collateral__c = null];
             System.debug('collDocList-----'+collDocList);
            if(!collDocList.isEmpty()){
                List<Id> docIds = new List<Id>();
                for(Document_Details__c doc : collDocList){
                    doc.Application_Collateral__c = apColId;
                    doc.Collateral_Master__c=appColl[0].Collateral__c;
                    docIds.add(doc.Id);
                }
                List<ContentDocumentLink> existingCdlList = [Select Id, LinkedEntityId, ContentDocumentId from ContentDocumentLink where LinkedEntityId in: docIds];
                Map<String,String> contentToLinkMap = new Map<String,String>();
                for(ContentDocumentLink cdl :existingCdlList){
                    contentToLinkMap.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
                }
                List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
                for (Document_Details__c d : collDocList) {
                    if (d.Content_Document_Id__c != null) {
                        if(contentToLinkMap.containsKey(d.Content_Document_Id__c)){
                            if(contentToLinkMap.get(d.Content_Document_Id__c)== null || contentToLinkMap.get(d.Content_Document_Id__c) != d.Id){
                                cdlList.add(new ContentDocumentLink(
                                    ContentDocumentId = d.Content_Document_Id__c,
                                    LinkedEntityId = d.Id,
                                    ShareType = 'V', // View permission
                                    Visibility = 'AllUsers'
                                ));
                            }
                        }
                        else{
                            cdlList.add(new ContentDocumentLink(
                                ContentDocumentId = d.Content_Document_Id__c,
                                LinkedEntityId = d.Id,
                                ShareType = 'V', // View permission
                                Visibility = 'AllUsers'
                            ));
                        }
                        
                    }
                }

                if (!cdlList.isEmpty()) {
                    insert cdlList;
                }
                System.debug('collDocList-----'+collDocList);
                Update collDocList;
            }
        }
    }
    public static String linkCollateralToApplication(Id collateralId, Id loanAppId, List<Id> selectedApplicants, CollateralWrapper wrapper) {
        Map<String,String> inputMapUtility = new  Map<String,String>();
        Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
        Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
        if (collateralId == null || loanAppId == null) {
            throw new AuraHandledException('Collateral Id and Loan Application Id must not be null.');
        }

        try {
            List<Application_Collateral__c> existingAppColls = new  List<Application_Collateral__c> ();
             String existingUPID;
              if(wrapper.oldColId!=null){
                existingUPID = [
                    SELECT Id, UPID__c, IsActive__c, Assigned_Percentage__c , Completion_Timeline__c
                    FROM Collateral__c 
                    WHERE id = :wrapper.oldColId AND IsActive__c = true
                    LIMIT 1
                ].UPID__c;
              }
                

          

            Application_Collateral__c appColl;
            Boolean isExistingAppColl = false;
            if(wrapper.upid==existingUPID && wrapper.checkUPID==true){
                System.debug('wrapper.oldColId---'+wrapper.oldColId);
                if(wrapper.oldColId!=null){
                    existingAppColls = [
                    SELECT Id 
                    FROM Application_Collateral__c 
                    WHERE Collateral__c = :wrapper.oldColId AND HL_Loan_Application__c = :loanAppId
                    LIMIT 1
                ];
                appColl = existingAppColls[0];
                isExistingAppColl = true;
                System.debug('Found existing Application_Collateral__c: ' + appColl.Id);
                }
               
            }
            else{
                 existingAppColls = [
                    SELECT Id 
                    FROM Application_Collateral__c 
                    WHERE Collateral__c = :wrapper.oldColId AND HL_Loan_Application__c = :loanAppId
                    LIMIT 1
                ];
                System.debug('existingAppColls size: ' + existingAppColls.size());
                 if (!existingAppColls.isEmpty()) {
                    appColl = existingAppColls[0];
                    appColl.Collateral__c = collateralId;
                    appColl.Completion_Timeline__c = wrapper.complitionTime;
                    isExistingAppColl = true;
                    System.debug('Found existing Application_Collateral__c: ' + appColl.Id);
                } else {
                    appColl = new Application_Collateral__c();
                    appColl.Collateral__c = collateralId;
                    appColl.HL_Loan_Application__c = loanAppId;
                    appColl.Completion_Timeline__c = wrapper.complitionTime;
                    insert appColl;
                    System.debug('Inserted new Application_Collateral__c: ' + appColl.Id);
                }

            }
           
            // ✅ Always set Application_Collateral__c.Assigned_Percentage__c
            appColl.Assigned_Percentage__c = wrapper.assignPercentage;
            update appColl;

          // ✅ Update Opportunity.Assigned_Collateral_Value__c by adding to existing
           // Opportunity oppUpdate = [SELECT Id, Assigned_Collateral_Value__c,Requested_Amount__c,Pending_loan_to_cover_Under_Collateral__c  FROM Opportunity WHERE Id = :loanAppId LIMIT 1];

          //  Decimal existingValue = oppUpdate.Assigned_Collateral_Value__c != null ? oppUpdate.Assigned_Collateral_Value__c : 0;

          //  oppUpdate.Assigned_Collateral_Value__c = existingValue + (wrapper.assignedCollateralValue != null ? wrapper.assignedCollateralValue : 0);
          //  Decimal requestedAmt = oppUpdate.Requested_Amount__c != null ? oppUpdate.Requested_Amount__c : 0;
          //  Decimal pendingAmt = requestedAmt - oppUpdate.Assigned_Collateral_Value__c;

            // Ensure non-negative
           // oppUpdate.Pending_loan_to_cover_Under_Collateral__c = pendingAmt > 0 ? pendingAmt : 0;
           //             update oppUpdate;


            // Delete existing Collateral_Owner__c ONLY if appColl is existing record
            if (isExistingAppColl) {
                deleteExistingCollateralOwners(appColl.Id);
            }

            List<Application_Applicant__c> applicantList = [
                SELECT Id, Name
                FROM Application_Applicant__c
                WHERE Id IN :selectedApplicants
            ];
            System.debug('Queried applicantList size: ' + applicantList.size());

            
			String result = '';
            Boolean skipCreateOwner = isHlRelated && wrapper.apfValue == 'Yes';

            if (!skipCreateOwner) {
            result = CreateCollateralController.createCollateralOwner(applicantList, appColl.Id);
            }
            if(!isHlRelated){
                result = result +'---'+appColl.Id;
            }
            else{
                 result = appColl.Id;
            }
            // if(!isHlRelated){
            //     result = CreateCollateralController.createCollateralOwner(applicantList, appColl.Id);
            //     result = result +'---'+appColl.Id;
            // }
            // else{
            //       result = appColl.Id;
            // }
            System.debug('createCollateralOwner result: ' + result);
            return result;

        } catch (Exception e) {
            System.debug('Exception in linkCollateralToApplication: ' + e.getMessage());
            throw new AuraHandledException('Error linking collateral with application and applicants: ' + e.getMessage());
        }
    }

	private static void deleteExistingCollateralOwners(Id appCollId) {
		if (appCollId == null) {
			return;
		}

		List<Collateral_Owner__c> existingColOwner = [
			SELECT Id FROM Collateral_Owner__c WHERE Application_Collateral__c = :appCollId];

		if (!existingColOwner.isEmpty()) {
			delete existingColOwner;
			System.debug('Deleted existing Collateral_Owner__c records: ' + existingColOwner.size());
		} else {
			System.debug('No Collateral_Owner__c records found to delete.');
		}
	}
	
	@AuraEnabled(cacheable=true)
    public static List<Project__c> getBuilderProjects(String searchKey) {
        String key = '%' + searchKey + '%';

        Id projectRecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName().get('Project').getRecordTypeId();
        Id companyRecordTypeId = Schema.SObjectType.Builder__c.getRecordTypeInfosByName().get('Builder Company').getRecordTypeId();

        List<Project__c> projectList = [SELECT Id,Name,Builder_Master__c,APF_No__c,
        Address_Line_1__c,Address_Line_2__c,Address_Line_3__c,Builder_Master__r.Name, Pincode__r.Name, Pincode__c,Pincode__r.City__r.Name,RERA_validity__c,
         Pincode__r.City__r.State__c, Pincode__r.City__r.Country__c,RERA_End_Date__c  FROM Project__c
                                         WHERE Name LIKE :key AND RecordTypeId = :projectRecordTypeId AND Builder_Master__r.RecordTypeId = :companyRecordTypeId ORDER BY Name LIMIT 10 ];
        
        return projectList;
    }

   @AuraEnabled(cacheable=true)
    public static List<Project__c> getBuildingsByProjectId(Id projectId, String searchKey) {
        try {
            if (projectId == null) return new List<Project__c>();
            Id buildingRecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName().get('Tower').getRecordTypeId();
            List<Project__c> buildings;
            if (String.isBlank(searchKey)) {
                buildings = [SELECT Id, Name FROM Project__c WHERE RecordTypeId = :buildingRecordTypeId AND Project__c = :projectId ORDER BY Name LIMIT 20];
            } else {
                String key = '%' + searchKey + '%';
                buildings = [SELECT Id, Name FROM Project__c WHERE RecordTypeId = :buildingRecordTypeId AND Project__c = :projectId AND Name LIKE :key ORDER BY Name LIMIT 20];
            }
            return buildings;
        } catch (Exception ex) {
            System.debug('Error in getBuildingsByProjectId: ' + ex.getMessage());
            throw new AuraHandledException('Failed to retrieve buildings: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean hasBuildingsForProject(Id projectId) {
        if (projectId == null) return false;
        Id buildingRecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName().get('Tower').getRecordTypeId();

        // Query for existence of at least one building record
        Integer countBuildings = [SELECT COUNT() FROM Project__c WHERE RecordTypeId = :buildingRecordTypeId AND Project__c = :projectId];

        if (countBuildings > 0) {
            return true;
        } else {
            return false;
        }
    }

   @AuraEnabled
    public static List<CollateralWrapper> getCollateralRecordsByLoanAppId(Id loanAppId) {
        List<CollateralWrapper> wrappers = new List<CollateralWrapper>();

        try {
            Map<String,String> inputMapUtility = new  Map<String,String>();
            Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
            Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
            if (loanAppId == null) {
                return wrappers;
            }

            List<Application_Collateral__c> appCollList = [SELECT Id, Collateral__c, Completion_Timeline__c FROM Application_Collateral__c  WHERE HL_Loan_Application__c = :loanAppId];

            Set<Id> collateralIds = new Set<Id>();
            Map<Id, Id> collateralIdToAppCollId = new Map<Id, Id>();
            for (Application_Collateral__c ac : appCollList) {
                if (ac.Collateral__c != null) {
                    collateralIds.add(ac.Collateral__c);
                    collateralIdToAppCollId.put(ac.Collateral__c, ac.Id);
                }
            }

            if (collateralIds.isEmpty()) {
                return wrappers;
            }
            Map<Id, List<Applicant_Address__c>> appCollIdToAppAdd = new Map<Id, List<Applicant_Address__c>>();
            List<Collateral__c> collaterals = [
                SELECT Id, Name,RERA_End_Date__c,Mortgage_Type__c,Asset_Collateral__c,House_Flat_Shop_Unit_No__c,Pocket__c,Plot_Number__c,Survey_Number_Gat_No__c,Street_Name__c,Building_Name__c, Address_Type__c,Ownership_Type__c,Market_Value__c,Allow_Multi_Assignment__c,Allow_third_party_assignment__c,Property_Usage__c,Current_Usage__c,Architects_Contractors_Estimate__c,Amenities_as_permitted_by_Policy__c,Others__c,Improvement_Cost__c,Cost_of_Plot__c,Agreement_Value__c,Society_Charges_Insurance__c,Electricty_Board_Municiple_Charges__c,Total_Property_Cost_Sum_of_all__c,Assigned_Percentage__c,Reason__c,APF_Number__c, Address_Line_1__c,External_Id__c,UPID__c, Project__c, Project__r.Name,Unit_Project__c,Unit_Project__r.Name, Builder__c, Builder__r.Name,
                    Collateral_Type__c,Primary_Secondary__c, Address_Line_2__c, Address_Line_3__c, Country__c, Pincode__c, Pincode__r.Name, Block_Taluka__c,
                    Unit_Property_Type__c, Tower_Building_Name__c, Floor_Number__c, Unit_Number__c, Construction_Stage__c, Occupancy_Since__c,
                    Estimated_Value__c, Area_of_Plot_Area__c, Carpet_Area_of_Residential_Unit_sq_m__c, RERA_Registration_Number__c, GPL_Flag__c,
                    Property_Insurance_Flag__c, APF__c, City__c,State__c,Document_Value__c, Completion_Timeline__c,Unit_Project__r.Project_Building__r.Name
                FROM Collateral__c WHERE Id IN :collateralIds AND IsActive__c = True];

            List<Collateral_Owner__c> allOwners = [
                SELECT Id, Application_Applicant__c, Application_Collateral__c
                FROM Collateral_Owner__c
                WHERE Application_Collateral__c IN :collateralIdToAppCollId.values()
            ];

            List<Applicant_Address__c> addAdd= [Select Id, Address_Line_1__c,Address_Line_2__c,Address_Line_3__c,Pincode__c,Pincode__r.Name,Address_Type__c,Collateral_Address_Type__c,Pincode__r.City__r.Country__c,Application_Collateral__c from Applicant_Address__c where Application_Collateral__c IN :collateralIdToAppCollId.values() AND Legal__c = null AND Technical_Evaluation__c = null];

            Map<Id, List<Id>> appCollIdToApplicantIds = new Map<Id, List<Id>>();
            for (Collateral_Owner__c owner : allOwners) {
                if (!appCollIdToApplicantIds.containsKey(owner.Application_Collateral__c)) {
                    appCollIdToApplicantIds.put(owner.Application_Collateral__c, new List<Id>());
                }
                appCollIdToApplicantIds.get(owner.Application_Collateral__c).add(owner.Application_Applicant__c);
            }
           
            for(Applicant_Address__c add : addAdd){
                if(!appCollIdToAppAdd.containsKey(add.Application_Collateral__c)){
                    appCollIdToAppAdd.put(add.Application_Collateral__c, new List<Applicant_Address__c>());
                }
                appCollIdToAppAdd.get(add.Application_Collateral__c).add(add);
            }

            for (Collateral__c c : collaterals) {
                Id appCollId = collateralIdToAppCollId.get(c.Id);
                CollateralWrapper w = new CollateralWrapper();
                w.Id = c.Id;
                w.name = c.Name;
                w.plotNumber = c.Plot_Number__c;
                w.housePlotNo = c.House_Flat_Shop_Unit_No__c;
                w.buildingName = c.Building_Name__c;
                w.streetName = c.Street_Name__c;
                w.pocket = c.Pocket__c;
                w.mortgageType = c.Mortgage_Type__c;
                w.assetType = c.Asset_Collateral__c;
                w.surveyNumber = c.Survey_Number_Gat_No__c;
                w.unitName = c.Unit_Project__r.Name;
                if(isHlRelated){
                    if (appCollId != null && appCollIdToAppAdd.containsKey(appCollId)){
                        Applicant_Address__c addr = appCollIdToAppAdd.get(appCollId)[0];
                        w.addressType = addr.Collateral_Address_Type__c;
                        w.reraEndDate = c.RERA_End_Date__c;
                        w.appAddId = addr.Id;
                        w.address1 = addr.Address_Line_1__c;
                        w.address2 = addr.Address_Line_2__c;
                        w.address3 = addr.Address_Line_3__c;
                        w.country = addr.Pincode__r.City__r.Country__c;
                        w.pincode = addr.Pincode__r.Name;
                        w.addPincode = addr.Pincode__c;
                    }
                   
                }
                else{
                w.addressType = c.Address_Type__c;
                w.address1 = c.Address_Line_1__c;
                w.address2 = c.Address_Line_2__c;
                w.address3 = c.Address_Line_3__c;
               	w.complitionTime = c.Completion_Timeline__c;
                w.country = c.Country__c;
                w.addPincode = c.Pincode__c;
                w.pincode = c.Pincode__r != null ? c.Pincode__r.Name : null;
                w.addPincode = c.Pincode__c;
                }
                
                w.block = c.Block_Taluka__c;
                w.ownershipType = c.Ownership_Type__c;
                w.propertyUsage = c.Property_Usage__c;
                w.currentUsage = c.Current_Usage__c;
                w.projName = c.Project__r != null ? c.Project__r.Name : null;
                w.devName = c.Builder__r != null ? c.Builder__r.Name : null;
                w.unitType = c.Unit_Property_Type__c;
                w.projId = c.Project__c;
                w.devId = c.Builder__c;
                w.unitId = c.Unit_Project__c;
                w.towerName = c.Tower_Building_Name__c;
                w.floor = c.Floor_Number__c;
                w.unitNumber = c.Unit_Number__c;
                w.constructionStage = c.Construction_Stage__c;
                w.occupancySince = c.Occupancy_Since__c;
                w.estimatedValue = c.Estimated_Value__c;
                w.marketValue = c.Market_Value__c;
                w.areaOfPlot = c.Area_of_Plot_Area__c;
                w.carpetArea = c.Carpet_Area_of_Residential_Unit_sq_m__c;
                w.reraRegNumber = c.RERA_Registration_Number__c;
                w.gplFlag = c.GPL_Flag__c;
                w.insuranceFlag = c.Property_Insurance_Flag__c;
                w.apfValue = c.APF__c;
                w.city = c.City__c;
                w.docVal = c.Document_Value__c;
                w.collateralType = c.Collateral_Type__c;
                w.primarySecondary = c.Primary_Secondary__c;
                w.upid = c.UPID__c;
                w.state = c.State__c;
                w.externalId = c.External_Id__c;
                w.reason = c.Reason__c;
                w.apfNumber = c.APF_Number__c;
                w.allowMultiAssignment = c.Allow_Multi_Assignment__c;
                w.allowThirdPartyAssignment = c.Allow_third_party_assignment__c;
                w.assignPercentage = c.Assigned_Percentage__c;
                w.costOfPlot = c.Cost_of_Plot__c;
                w.improvmentCost = c.Improvement_Cost__c;
                w.agreementValue = c.Agreement_Value__c;
                w.societyCharges = c.Society_Charges_Insurance__c;
                w.totalPropertyCost = c.Total_Property_Cost_Sum_of_all__c;
                w.others = c.Others__c;
                w.amenitiesPermitPolicy = c.Amenities_as_permitted_by_Policy__c;
                w.architectsEstimate = c.Architects_Contractors_Estimate__c;
                w.electricityMunicipleCharges = c.Electricty_Board_Municiple_Charges__c;

                appCollId = collateralIdToAppCollId.get(c.Id);
                if (appCollId != null && appCollIdToApplicantIds.containsKey(appCollId)) {
                    w.ownerApplicantIds = appCollIdToApplicantIds.get(appCollId);
                } else {
                    w.ownerApplicantIds = new List<Id>();
                }

                wrappers.add(w);
            }
        } catch (Exception e) {
            System.debug('Error in getCollateralRecordsByLoanAppId: ' + e.getMessage());
            throw new AuraHandledException('Failed to load collateral data. ' + e.getMessage());
        }

        return wrappers;
    }

   @AuraEnabled(cacheable=true)
    public static List<Pincode_Master__c> getPincodeDetails(String pinCodeFragment) {
        try {
            if (String.isBlank(pinCodeFragment)) {
                return new List<Pincode_Master__c>(); 
            }

            String likePattern = pinCodeFragment + '%';

            return [
               SELECT Id,Name, City__c, City__r.Name, City__r.State__c, City__r.Country__c,City__r.State_Name__c
                FROM Pincode_Master__c
                WHERE Name LIKE :likePattern
                LIMIT 10
            ];
        } catch (Exception ex) {
            System.debug('Error in getMatchingPincodes: ' + ex.getMessage());
            throw new AuraHandledException('Failed to retrieve pincodes: ' + ex.getMessage());
        }
    }


    @AuraEnabled(cacheable=true)
    public static List<Project__c> getUnitsByProjectAndSearch(String projectId, String searchKey, Boolean useBuilding) {
        try {
           
            String likePattern = '%' + searchKey + '%';

            // Get RecordTypeId for 'Unit'
            Id unitRecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByDeveloperName().get('Unit').getRecordTypeId();

            String filterField = useBuilding ? 'Project_Building__c' : 'Project__c';
            System.debug('projectId: ' + projectId);
System.debug('searchKey: ' + searchKey);
System.debug('useBuilding: ' + useBuilding);
System.debug('unitRecordTypeId: ' + unitRecordTypeId);

            // Build dynamic query using WHERE clause
            String queryStr = 'SELECT Id, Name,RERA_End_Date__c, Carpet_Area__c, Unit_Type__c,Project_Building__r.Name, Tower__c, Floor_Number__c, Super_Builtup_Area__c, Building__r.Name ' +
                            'FROM Project__c ' +
                            'WHERE RecordTypeId = :unitRecordTypeId ' +
                            'AND ' + filterField + ' = :projectId ' +
                            'AND (Name LIKE :likePattern) ' +
                            'LIMIT 20';
            system.debug('382--'+queryStr);

            return Database.query(queryStr);

        } catch (Exception ex) {
            System.debug('Error in getUnitsByProjectAndSearch: ' + ex.getMessage());
            throw new AuraHandledException('Failed to retrieve units: ' + ex.getMessage());
        }
    }

    public class CollateralWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String name;
        @AuraEnabled public String addressType;
        @AuraEnabled public String address1;
        @AuraEnabled public String address2;
        @AuraEnabled public String address3;
        @AuraEnabled public String country;
        @AuraEnabled public String addPincode;  
        @AuraEnabled public String pincode;     
        @AuraEnabled public String block;
        @AuraEnabled public String projName;
        @AuraEnabled public String devName;
        @AuraEnabled public String unitType;
        @AuraEnabled public String towerName;
        @AuraEnabled public String floor;
        @AuraEnabled public Decimal complitionTime;
        @AuraEnabled public String unitNumber;
        @AuraEnabled public String constructionStage;
        @AuraEnabled public Boolean  allowMultiAssignment;
        @AuraEnabled public Boolean  allowThirdPartyAssignment;
        @AuraEnabled public String occupancySince;
        @AuraEnabled public Decimal estimatedValue;
        @AuraEnabled public Decimal marketValue;
        @AuraEnabled public Decimal costOfPlot;
        @AuraEnabled public Decimal improvmentCost;
        @AuraEnabled public Decimal agreementValue; 
        @AuraEnabled public Decimal electricityMunicipleCharges;
        @AuraEnabled public Decimal architectsEstimate;
        @AuraEnabled public Decimal amenitiesPermitPolicy;
        @AuraEnabled public Decimal others;
        @AuraEnabled public Decimal societyCharges;
        @AuraEnabled public Decimal totalPropertyCost;       
        @AuraEnabled public Decimal areaOfPlot;
        @AuraEnabled public Decimal carpetArea;
        @AuraEnabled public String reraRegNumber;
        @AuraEnabled public String gplFlag;
        @AuraEnabled public Id appAddId;
        @AuraEnabled public String insuranceFlag;
        @AuraEnabled public String apfValue;
        @AuraEnabled public String state;
        @AuraEnabled public String city;
        @AuraEnabled public String unitName;
		@AuraEnabled public String collateralType;
        @AuraEnabled public String primarySecondary;
		@AuraEnabled public Id projId;
		@AuraEnabled public Id devId;
        @AuraEnabled public Id unitId;
		@AuraEnabled public List<Id> ownerApplicantIds;
        @AuraEnabled public String loanId;
        @AuraEnabled public String upid;
        @AuraEnabled public String matchFound;
        @AuraEnabled public String plotNumber;
        @AuraEnabled public String housePlotNo;
        @AuraEnabled public String streetName;
        @AuraEnabled public String buildingName;
        @AuraEnabled public String pocket;
        @AuraEnabled public String mortgageType;
        @AuraEnabled public String assetType;
        @AuraEnabled public String surveyNumber;
        @AuraEnabled public String externalId;
        @AuraEnabled public String apfNumber;
        @AuraEnabled public String reason;
        @AuraEnabled public String ownershipType;
        @AuraEnabled public String propertyUsage;
        @AuraEnabled public String currentUsage;
        @AuraEnabled public Date reraEndDate;
        @AuraEnabled public Decimal assignPercentage;
        @AuraEnabled public Decimal assignPercentageMatch;
         @AuraEnabled public Decimal docVal;
        @AuraEnabled public String oldColId;
        @AuraEnabled public Boolean checkUPID;
       // @AuraEnabled public Decimal assignedCollateralValue;  
    }
    @AuraEnabled
    public static List<DocumentWrapper> createDocumentDetails(Map <String, String> inputMap){
        try {
            List<DocumentWrapper> docWrapList = new List<DocumentWrapper>();
            List<Document_Details__c> docList = new  List<Document_Details__c>();
            String loanId = inputMap.get('loanId');
            String projectId=inputMap.get('projectId');
            Boolean checkApf=Boolean.valueOf(String.valueOf(inputMap.get('isApf')));
            List<Document_Details__c> docDetails = new List<Document_Details__c>();
            List<Document_Master__c> docMaster =[Select id,Name,Requirement_Level__c,Requirement_At__c from Document_Master__c where Stage__c = 'Sales login' and Requirement_at__c = 'Collateral Level' ];
            List<Document_Details__c> docDetailsExisting = [Select id, Name, Applicant__c, Loan_Application__c,Uploaded_Date_Time__c,Description__c,Consider_for_Loan_Application__c,Content_Document_Id__c,Project__c
             from Document_Details__c where Project__C=:projectId and Application_Collateral__c=null and  Requirement_Level__c='Collateral level'];
               Map<String,String> inputMapUtility = new  Map<String,String>();
        Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
        Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
             if(isHlRelated && !checkApf){
                 docDetailsExisting = [Select id, Name, Applicant__c, Loan_Application__c,Consider_for_Loan_Application__c,Uploaded_Date_Time__c,Description__c,Content_Document_Id__c from Document_Details__c where Loan_Application__c =:loanId and Application_Collateral__c=null and  Requirement_Level__c='Collateral level'];
            if(docDetailsExisting.isEmpty()){
                for(Document_Master__c doc : docMaster){
                Document_Details__c documentCheck = new Document_Details__c();
                documentCheck.Name = doc.Name;
                documentCheck.Loan_Application__c = loanId;
                documentCheck.Document_Master__c = doc.Id;
                documentCheck.Requirement_Level__c = doc.Requirement_at__c;
                documentCheck.Document_Master__c= doc.id;
                docList.add(documentCheck);
                }
                insert docList;
                docDetails = [Select id, Name, Applicant__c, Loan_Application__c,Uploaded_Date_Time__c,Description__c,Consider_for_Loan_Application__c,Content_Document_Id__c from Document_Details__c where Loan_Application__c =:loanId and id IN :docList];
            }
            else{
                docDetails.addAll(docDetailsExisting);
            }
             }else{
            // if(docDetailsExisting.isEmpty()){
            //     for(Document_Master__c doc : docMaster){
            //     Document_Details__c documentCheck = new Document_Details__c();
            //     documentCheck.Name = doc.Name;
            //     documentCheck.Loan_Application__c = loanId;
            //     documentCheck.Document_Master__c = doc.Id;
            //     documentCheck.Requirement_Level__c = doc.Requirement_at__c;
            //     documentCheck.Document_Master__c= doc.id;
            //     docList.add(documentCheck);
            //     }
            //     insert docList;
            //     docDetails = [Select id, Name, Applicant__c, Loan_Application__c,Consider_for_Loan_Application__c,Content_Document_Id__c,Description__c,Project__c from Document_Details__c where Loan_Application__c =:loanId and id IN :docList];
            // }
            // else{
                docDetails.addAll(docDetailsExisting);
           //}
             }
            
           
            for(Document_Details__c doc : docDetails){
                DocumentWrapper docWrap = new DocumentWrapper();
                docWrap.isUploaded =false;
                docWrap.documentName = doc.Name;
                docWrap.status = 'Pending';
                docWrap.contentId = doc.Content_Document_Id__c;
                docWrap.documentId = doc.Id;
                docWrap.fileDescription=doc.Description__c;
                if (doc.Uploaded_Date_Time__c != null) {
                docWrap.fileUploadedDate=doc.Uploaded_Date_Time__c.format('dd-MM-yyyy');
                }
                if(doc.Content_Document_Id__c!=null){
                    docWrap.isUploaded =true;
                }
                docWrapList.add(docWrap);
            }
            return docWrapList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class DocumentWrapper{
        @AuraEnabled public String documentName;
        @AuraEnabled public String status;
        @AuraEnabled public String contentId;
        @AuraEnabled public String documentId;
        @AuraEnabled public Boolean isUploaded;
        @AuraEnabled public String fileDescription;
        @AuraEnabled public String fileUploadedDate;
    }


    @AuraEnabled
    public static ContentWrapper createContentVersion(Map<String,String> inputMap){
        try {
            String fileName = inputMap.get('fileName');
            String base64Data = inputMap.get('base64Data');
            String docId = inputMap.get('docId');
            String loanId = inputMap.get('loanId');
            ContentWrapper conWrap = new ContentWrapper();
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.IsMajorVersion = true;
            insert cv;
            conWrap.contentVerId = cv.Id;
            
            // Fetch ContentDocumentId from newly inserted ContentVersion
            ContentVersion cvRec = [
                SELECT ContentDocumentId, FileType 
                FROM ContentVersion 
                WHERE Id = :cv.Id 
                LIMIT 1
            ];
            String contentDocId = cvRec.ContentDocumentId;
            conWrap.contentDocId = contentDocId;
            List<Document_Details__c> doc = [Select id, Content_Document_Id__c, Status__c from Document_Details__c where id=:docId];
            if(doc.size()>0){
                doc[0].Content_Document_Id__c = contentDocId;
                doc[0].Status__c = 'Uploaded';
                update doc;
            }
            conWrap.documentId = docId;
            return conWrap;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
     public class ContentWrapper{
        @AuraEnabled public String contentDocId;
        @AuraEnabled public String contentVerId;
        @AuraEnabled public String documentId;
    }
    

    @AuraEnabled
    public static void flowCovenantsonLoan(String projectId, String loanId){
        try {
            List<Builder_Project_Document__c> bpdList = [SELECT Id, Name, Builder_Approval_Document_Name__c, Builder_Document__c, Builder__c, Covenant_Master__c, Date_of_Report__c, Document_Name__c, Project__c, Category__c, Code__c, Covenant_Type__c, Description__c, Doc_Type__c, Last_Modified_By__c, Remarks__c, Version__c, Last_Modified_On__c FROM Builder_Project_Document__c WHERE Project__c= :projectId];
            List<Document_Details__c> covenantToInsert = new List<Document_Details__c>();
            List<Document_Master__c> docMaster = [SELECT id, Name FROM Document_Master__c WHERE Name='Covenant Upload Approval' LIMIT 1];
            for(Builder_Project_Document__c doc:bpdList){
                Document_Details__c newDoc= new Document_Details__c();
                newDoc.Loan_Application__c= loanId;
                newDoc.Covenant_Request_by__c = UserInfo.getUserId();
                newDoc.Name= doc.Name;
                newDoc.Covenant_Master__c= doc.Covenant_Master__c;
                insert newDoc;

                Document_Details__c docUpload = new Document_Details__c();
                docUpload.Name = docMaster[0].Name;
                docUpload.Loan_Application__c = loanId;
                docUpload.Covenant_Request_by__c = userinfo.getUserId();
                docUpload.Document_Details_Lookup__c=newDoc.Id;
                docUpload.Document_Master__c=docMaster[0].Id;
                docUpload.Document_Category__c='Additional Documents';
                docUpload.Requirement_At__c='Covenant';
                docUpload.RecordTypeId=Schema.SObjectType.Document_Details__c.getRecordTypeInfosByName().get('Covenant Details').getRecordTypeId();
                insert docUpload;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string delinkCollateral(string collateralId){
        Set<Id> loanIds = new Set<Id>();
        List<Collateral__c> collateralList = [SELECT Id FROM Collateral__c WHERE Id =: collateralId];

        List<Application_collateral__c> appCollateralList = [SELECT Id, HL_Loan_Application__c FROM Application_collateral__c WHERE Collateral__c =: collateralList];

        if(!appCollateralList.isEmpty()){
            for(Application_collateral__c rec : appCollateralList){
                loanIds.add(rec.HL_Loan_Application__c);
                rec.HL_Loan_Application__c = null;
            }

            update appCollateralList;

            List<Technical_Evaluation__c> techList = [Select Id, HL_Loan_Application__c From Technical_Evaluation__c Where HL_Loan_Application__c IN : loanIds 
                                                        And HL_Application_Collateral__c =: appCollateralList];
            if(!techList.isEmpty()){
                for(Technical_Evaluation__c rec : techList){
                    rec.HL_Loan_Application__c = null;
                }

                update techList;
            }

            List<Legal__c> legalList = [Select Id, Loan_Application__c From Legal__c Where Loan_Application__c IN : loanIds 
                                        And Application_Collateral__c =: appCollateralList];
            if(!legalList.isEmpty()){
                for(Legal__c rec : legalList){
                    rec.Loan_Application__c = null;
                }

                update legalList;
            }
        }

        return 'success';
    }

    @AuraEnabled
    public static Boolean checkDelinkAccess(string loanId){
        List<Opportunity> opp = [Select Id From Opportunity Where Id =: loanId And StageName = 'Credit Underwriting'];
        if(!opp.isEmpty()){
             User currentUser = [
            SELECT Profile.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
          //  string profileName = Utility.fetchUserProfile(UserInfo.getProfileId());
           String profileName = currentUser.Profile.Name;

            if(profileName == 'Credit Manager' || profileName == 'System Administrator'){
                return true;
            }
        }

        return false;
    }
    @AuraEnabled
    public static String downloadDocumentDetails(Map<String,String> inputMap){
        String fileName = inputMap.get('fileName');
        String projectId = inputMap.get('projectId');
        String docId = inputMap.get('docId');
        String loanId=inputMap.get('loanId');
        List<DocumentWrapper> downloadFile=new List<DocumentWrapper>();
        String fileId=HL_DownloadFileGenericHandler.downloadFile(fileName);
        ContentVersion cv=[select id,ContentDocumentId from ContentVersion  where id =:fileId ];
        System.debug('fileId: ' + fileId);
         Document_Details__c doc = new Document_Details__c();
           // doc.Name = fileName;
            doc.Document_Uploaded__c = true;
            doc.Status__c = 'Uploaded';
            doc.is_APF_Doc__c = true;
            doc.Content_Document_Id__c = cv.ContentDocumentId;
            doc.Project__c = projectId;
            doc.Description__c=fileName;
            doc.Id=docId;
            doc.Requirement_Level__c='Collateral level';
            update doc;
           
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = projectId;
            cdl.Visibility = 'AllUsers';
            cdl.ShareType = 'V'; // Viewer
            insert cdl;
        return cv.ContentDocumentId;
    }

public class BuilderSellerWrapper {
    @AuraEnabled public Id Id;
    @AuraEnabled public String applicantType;
    @AuraEnabled public String applicantName;
    @AuraEnabled public String panNumber;
    @AuraEnabled public Date doi;
    @AuraEnabled public String contactPersonName;
    @AuraEnabled public String contactPersonNumber;
    @AuraEnabled public String aadharNumber;
    @AuraEnabled public Date dob;
    @AuraEnabled public String customerType;
    @AuraEnabled public String mobileNumber ;
    @AuraEnabled public boolean isDisabled;
    @AuraEnabled public Boolean disableEdit;
    public BuilderSellerWrapper() {}
}



}