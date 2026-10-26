/**
* @File Name : SalesLoanLoginTopUpFlowController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 8, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 8, 2025 |   | Initial Version
**/

public without sharing class COMM_SalesLoanLoginTopUpFlowController {

    public class FinanceOpportunityWrapper {
        @AuraEnabled public Id opportunityId;         
        @AuraEnabled public String cif;                
        @AuraEnabled public String customerName;       
        @AuraEnabled public String finReference;      
        @AuraEnabled public String finType;           
        @AuraEnabled public String finStatus;         
        @AuraEnabled public Decimal finAmount;        
        @AuraEnabled public Decimal firstEmiAmount;    
        @AuraEnabled public String outstandingBal;   
        @AuraEnabled public String source;            
    }

    @AuraEnabled
    public static void updateOpportunity(Id oppId) {
        try{
            if (oppId == null) {
                throw new AuraHandledException('Opportunity Id cannot be null');
            }

            Opportunity oppToUpdate = [
                SELECT Id, Is_Top_Up__c FROM Opportunity WHERE Id = :oppId LIMIT 1];

            oppToUpdate.Is_Top_Up__c = 'No'; 

            update oppToUpdate;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to update Opportunity: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<FinanceOpportunityWrapper> getOpportunities(String cif, String ucic, String accId) {
        List<FinanceOpportunityWrapper> financeList = new List<FinanceOpportunityWrapper>();
        try {
            Account acc;
            
            // Priority: CIF → UCIC → Id
            if (!String.isBlank(cif)) {
                List<Account> accList = [SELECT Id, Name FROM Account WHERE Customer_LMS_Id__c = :cif LIMIT 1];
                if (!accList.isEmpty()) acc = accList[0];
            } 
            else if (!String.isBlank(ucic)) {
                List<Account> accList = [SELECT Id, Name FROM Account WHERE UCIC_Number__c = :ucic LIMIT 1];
                if (!accList.isEmpty()) acc = accList[0];
            } 
            else if (accId != null) {
                List<Account> accList = [SELECT Id, Name FROM Account WHERE Id = :accId LIMIT 1];
                if (!accList.isEmpty()) acc = accList[0];
            }

            if (acc == null) {
                // No matching account found
                return financeList;
            }

            // Fetch Opportunities for the account
            List<Opportunity> opps = [
                SELECT Id, Name, Requested_Amount__c, Emi_amount__c, Tenor_Months__c, Status__c, Product__c
                FROM Opportunity
                WHERE AccountId = :acc.Id
            ];

            if (!opps.isEmpty()) {
                for (Opportunity opp : opps) {
                    FinanceOpportunityWrapper fow = new FinanceOpportunityWrapper();
                    fow.opportunityId = opp.Id;
                    fow.cif = cif;
                    fow.customerName = acc.Name;
                    fow.finReference = opp.Name;
                    fow.finType = opp.Product__c;
                    fow.finStatus = opp.Status__c;
                    fow.finAmount = opp.Requested_Amount__c;
                    fow.firstEmiAmount = opp.Emi_amount__c;
                    fow.outstandingBal = '---';
                    fow.source = 'SF';
                    financeList.add(fow);
                }
            }

        } catch (Exception e) {
            System.debug('Error in getOpportunities: ' + e.getMessage());
            // return empty list in case of exception
        }

        return financeList;
    }

    @AuraEnabled(cacheable=true)
    public static List<FinanceOpportunityWrapper> checkLoanApplicationInSFDC(String loanAppNo, Boolean lmsNo) {
        List<FinanceOpportunityWrapper> financeList = new List<FinanceOpportunityWrapper>();
        try {
            String searchField = lmsNo ? 'LMS_Loan_Reference__c' : 'Name';
            String query = 'SELECT Id, Name, Requested_Amount__c, Emi_amount__c, Tenor_Months__c, Status__c, Product__c, Account.Name, Account.Customer_LMS_Id__c ' +
                           'FROM Opportunity WHERE ' + searchField + ' = :loanAppNo LIMIT 10';
            List<Opportunity> opps = Database.query(query);

            for (Opportunity opp : opps) {
                FinanceOpportunityWrapper fow = new FinanceOpportunityWrapper();
                fow.opportunityId = opp.Id;
                fow.cif = opp.Account.Customer_LMS_Id__c;
                fow.customerName = opp.Account.Name;
                fow.finReference = opp.Name;
                fow.finType = opp.Product__c;
                fow.finStatus = opp.Status__c;
                fow.finAmount = opp.Requested_Amount__c;
                fow.firstEmiAmount = opp.Emi_amount__c;
                fow.outstandingBal = '---';
                fow.source = 'SF';
                financeList.add(fow);
            }
        } catch (Exception e) {
            System.debug('Error in getOpportunitiesByLoanApp: ' + e.getMessage());
        }
        return financeList;
    }

    @AuraEnabled
    public static String cloneLoanApplication(String sourceOppId, String recordId) {
        try {
            if (sourceOppId == null || recordId == null) {
                return 'Source or Target Opportunity Id is missing';
            }

            // 1. Link target Opp to parent
            update new Opportunity(Id = recordId,Parent_Loan_Application__c = sourceOppId,Is_Top_Up__c = 'Yes');
             List<Application_Applicant__c> existingPrimaryApplicants = [SELECT Id  FROM Application_Applicant__c WHERE Loan_Application__c = :recordId AND Applicant_Type__c = 'Primary Applicant' ];
                if (!existingPrimaryApplicants.isEmpty()) {
                    delete existingPrimaryApplicants;
                }

            // === Clone Applicants ===
            Map<String, Schema.SObjectField> applicantFieldMap = Schema.SObjectType.Application_Applicant__c.fields.getMap();
            List<String> applicantFieldNames = new List<String>(applicantFieldMap.keySet());
            System.debug('Applicant Field Names: ' + applicantFieldNames);


           String applicantSOQL = 'SELECT ' + String.join(applicantFieldNames, ',') + 
                       ' FROM Application_Applicant__c WHERE Loan_Application__c = \'' + sourceOppId + '\'';

                                System.debug('Constructed SOQL query: ' + applicantSOQL);


            List<Application_Applicant__c> applicantsToClone = Database.query(applicantSOQL);

            Map<Id, Id> oldToNewApplicantIdMap = new Map<Id, Id>();
            if (!applicantsToClone.isEmpty()) {
                List<Application_Applicant__c> clonedApplicants = new List<Application_Applicant__c>();

                for (Application_Applicant__c oldApplicant : applicantsToClone) {
                    System.debug('Cloning applicant Customer_Profile__c: ' + oldApplicant.Customer_Profile__c);
                    if(oldApplicant.Customer_Profile__c == 'SENP'){
                        oldApplicant.Customer_Profile__c ='SEP';
                    }
                    Application_Applicant__c newApplicant = oldApplicant.clone(false, false, false, false);
                    newApplicant.Loan_Application__c = recordId;
                    newApplicant.Consent_Status__c = '';
                    newApplicant.Cibil_Score__c = null;
                    newApplicant.Pan_Status__c = '';
                    newApplicant.Is_Consent_Received__c = false;
                    clonedApplicants.add(newApplicant);
                }
                system.debug('clonedApplicants---'+clonedApplicants);

                insert clonedApplicants;

                for (Integer i = 0; i < applicantsToClone.size(); i++) {
                    oldToNewApplicantIdMap.put(applicantsToClone[i].Id, clonedApplicants[i].Id);
                }
            }

            // === Clone Address__c related to Applicants ===
            if (!oldToNewApplicantIdMap.isEmpty()) {
                Map<String, Schema.SObjectField> addressFieldMap = Schema.SObjectType.Applicant_Address__c.fields.getMap();
                List<String> addressFieldNames = new List<String>(addressFieldMap.keySet());
                Set<Id> oldApplicantIds = oldToNewApplicantIdMap.keySet();

                List<String> applicantIds = new List<String>();
                for (Id idVal : oldApplicantIds) {
                    applicantIds.add('\'' + String.escapeSingleQuotes(idVal) + '\'');
                }

                String idString = String.join(applicantIds, ',');

                String soql = 'SELECT ' + String.join(addressFieldNames, ',') + ' FROM Applicant_Address__c WHERE Applicant__c IN (' + idString + ')';

                List<Applicant_Address__c> addressesToClone = Database.query(soql);


                if (!addressesToClone.isEmpty()) {
                    List<Applicant_Address__c> clonedAddresses = new List<Applicant_Address__c>();

                    for (Applicant_Address__c oldAddress : addressesToClone) {
                        Applicant_Address__c newAddress = oldAddress.clone(false, false, false, false);
                        newAddress.Applicant__c = oldToNewApplicantIdMap.get(oldAddress.Applicant__c);
                         newAddress.Loan_Application__c = recordId;
                        clonedAddresses.add(newAddress);
                    }

                    insert clonedAddresses;
                }
            }

            // === Clone Application_Collateral__c ===
            List<Application_Collateral__c> existingCollaterals = [SELECT Id, Collateral__c FROM Application_Collateral__c WHERE HL_Loan_Application__c = :sourceOppId AND Collateral__r.IsActive__c =true];

            Map<Id, Id> oldToNewCollateralIdMap = new Map<Id, Id>();
            if (!existingCollaterals.isEmpty()) {
                List<Application_Collateral__c> clonedCollaterals = new List<Application_Collateral__c>();

                for (Application_Collateral__c ac : existingCollaterals) {
                    Application_Collateral__c newCollateral = new Application_Collateral__c(
                        HL_Loan_Application__c = recordId,
                        Collateral__c = ac.Collateral__c
                    );
                    clonedCollaterals.add(newCollateral);
                }

                insert clonedCollaterals;

                for (Integer i = 0; i < existingCollaterals.size(); i++) {
                    oldToNewCollateralIdMap.put(existingCollaterals[i].Id, clonedCollaterals[i].Id);
                }
            }

            // === Clone Collateral_Owner__c ===
            if (!oldToNewCollateralIdMap.isEmpty() && !oldToNewApplicantIdMap.isEmpty()) {
                List<Collateral_Owner__c> ownersToClone = [SELECT Id, Application_Applicant__c, Application_Collateral__c FROM Collateral_Owner__c WHERE Application_Collateral__c IN :existingCollaterals];

                if (!ownersToClone.isEmpty()) {
                    List<Collateral_Owner__c> clonedOwners = new List<Collateral_Owner__c>();

                    for (Collateral_Owner__c oldOwner : ownersToClone) {
                        Collateral_Owner__c newOwner = new Collateral_Owner__c();
                        newOwner.Application_Applicant__c = oldToNewApplicantIdMap.get(oldOwner.Application_Applicant__c);
                        newOwner.Application_Collateral__c = oldToNewCollateralIdMap.get(oldOwner.Application_Collateral__c);
                        clonedOwners.add(newOwner);
                    }

                    insert clonedOwners;
                }
            }

            return 'Success';

        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static void createRelatedRecords(String loanNumber, Id recordId) {
        if (String.isBlank(loanNumber)){
            throw new AuraHandledException('Loan Number is empty.');
        }

        try {
            String loanData = GetExistingLoanDetailsController.getExistingLoanDetails(loanNumber);
            List<Application_Applicant__c> appDet = [Select id, Applicant_Type__c,Is_Consent_Received__c from Application_Applicant__c where Loan_Application__c=:recordId and Applicant_Type__c='Primary Applicant'];
            GetExistingLoanDetailsController.GetExistingLoanDetailsWrapper wrapperData = 
                (GetExistingLoanDetailsController.GetExistingLoanDetailsWrapper) 
                JSON.deserialize(loanData, GetExistingLoanDetailsController.GetExistingLoanDetailsWrapper.class);

            if (wrapperData == null || wrapperData.returnStatus.returnCode != '0000' || wrapperData.customer == null || String.isBlank(wrapperData.customer.cif)) {
                throw new AuraHandledException('Loan data is empty.');
            }

            List<Account> accountsToInsert = new List<Account>();
            Map<String, Account> tempCifToAccountMap = new Map<String, Account>();
            List<Application_Applicant__c> applicantsToInsert = new List<Application_Applicant__c>();
            List<Applicant_Address__c> addressesToInsert = new List<Applicant_Address__c>();
            Map<String, Application_Applicant__c> tempCifToApplicantMap = new Map<String, Application_Applicant__c>();
            Map<String, List<Applicant_Address__c>> tempCifToAddressList = new Map<String, List<Applicant_Address__c>>();

            List<Collateral__c> collateralsToInsert = new List<Collateral__c>();
            List<Application_Collateral__c> appCollateralsToInsert = new List<Application_Collateral__c>();
            Map<String, Decimal> collateralMap = new Map<String, Decimal>();
            Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();

            // --- Collateral reference map from wrapper ---
            if (wrapperData.collaterals != null && !wrapperData.collaterals.isEmpty()) {
                for (GetExistingLoanDetailsController.cls_collaterals col : wrapperData.collaterals) {
                    if (col.collateralRef != null) {
                        collateralMap.put(col.collateralRef, col.assignPerc);
                    }
                }
            }

            String primaryCIF;
            List<String> coApplicantCIFs = new List<String>();
            List<String> guarantorCIFs = new List<String>();
            List<String> allCIFs = new List<String>();

            if(wrapperData.customer != null && String.isNotBlank(wrapperData.customer.cif)) {
                primaryCIF = wrapperData.customer.cif;
                allCIFs.add(primaryCIF);
            }
            if(wrapperData.coApplicants != null) {
                for(GetExistingLoanDetailsController.cls_coApplicants coApp : wrapperData.coApplicants) {
                    if(coApp.cif != null) {
                        coApplicantCIFs.add(coApp.cif);
                        allCIFs.add(coApp.cif);
                    }
                }
            }
            if(wrapperData.guarantors != null) {
                for(GetExistingLoanDetailsController.cls_guarantors gua : wrapperData.guarantors) {
                    if(gua.cif != null) {
                        guarantorCIFs.add(gua.cif);
                        allCIFs.add(gua.cif);
                    }
                }
            }

            Map<String, COMM_GetCustomerController.Response> cifToResponse = new Map<String, COMM_GetCustomerController.Response>();

            // --- Fetch customer details ---
            for(String cif : allCIFs) {
                try {
                   COMM_GetCustomerController.ResponseWrapper finalResp = COMM_GetCustomerController.getCustomerDetails(cif, 'Get Customer');
                    COMM_GetCustomerController.Response custResp = 
                        (COMM_GetCustomerController.Response) JSON.deserialize(finalResp.respBody, COMM_GetCustomerController.Response.class);
                    if (custResp == null || custResp.returnStatus == null || custResp.returnStatus.returnCode != '0000') {
                        throw new AuraHandledException('Failed to fetch customer details for CIF: ' + cif);
                    }
                    cifToResponse.put(cif, custResp);
                } catch(Exception e) {
                    System.debug('Error fetching customer details for CIF ' + cif + ': ' + e.getMessage());
                }
            }

            // --- Fetch master data ---
            Map<String, String> addressTypeMap = new Map<String, String>();
            Map<String, String> religionMap   = new Map<String, String>();
            Map<String, String> sectorMap     = new Map<String, String>();
            Map<String, String> industryMap   = new Map<String, String>();
            Map<String, String> genderMap     = new Map<String, String>();
            Map<String, String> casteMap      = new Map<String, String>();
            Map<String, String> natioanlityMap = new Map<String, String>();
            Map<String, String> salutationMap = new Map<String, String>();

            for (PLF_Master__c master : [
                SELECT Master_Type__c, Description__c, FICO_Code__c 
                FROM PLF_Master__c 
                WHERE Master_Type__c IN ('Address Type','Religion','Sector','Industry','Gender','Caste','Nationality','Salutation')
            ]) {
                if(master.Master_Type__c == 'Address Type') addressTypeMap.put(master.FICO_Code__c, master.Description__c);
                if(master.Master_Type__c == 'Religion') religionMap.put(master.FICO_Code__c, master.Description__c);
                if(master.Master_Type__c == 'Sector') sectorMap.put(master.FICO_Code__c, master.Description__c);
                if(master.Master_Type__c == 'Industry') industryMap.put(master.FICO_Code__c, master.Description__c);
                if(master.Master_Type__c == 'Gender') genderMap.put(master.FICO_Code__c, master.Description__c);
                if(master.Master_Type__c == 'Caste') casteMap.put(master.FICO_Code__c, master.Description__c);
                if(master.Master_Type__c == 'Nationality') natioanlityMap.put(master.FICO_Code__c, master.Description__c);
                if(master.Master_Type__c == 'Salutation') salutationMap.put(master.FICO_Code__c, master.Description__c);
            }

            Set<String> uniquePincodes = new Set<String>();
            Map<Applicant_Address__c, String> addressToRawPin = new Map<Applicant_Address__c, String>();
            List<Account> accList = [Select Id, Customer_LMS_ID__c, Applicant_Identifier__c from Account where Customer_LMS_ID__c in: allCIFs and Is_Active__c = true];
            Map<String,Account> lmsIdToAccMap = new Map<String,Account>();
            for(Account acc: accList){
                lmsIdToAccMap.put(acc.Customer_LMS_ID__c,acc);
            }
            List<Account> accToUpsert = new List<Account>();
            for(String cif : allCIFs) {

                if(appDet.size()>0 && appDet!=null && cif == primaryCIF) continue;
                
                COMM_GetCustomerController.Response custResp = cifToResponse.get(cif);
                if(custResp == null) continue;
				System.debug('custResp=:'+JSON.serialize(custResp));
                // Account
                Account acc = new Account(
                    Name = custResp.personalInfo.firstName + ' ' + custResp.personalInfo.middleName + ' ' + custResp.personalInfo.lastName,
                    First_Name__c = custResp.personalInfo.firstName,
                    Last_Name__c  = custResp.personalInfo.lastName,
                    Customer_LMS_Id__c = cif,
                    RecordTypeId = customerRecordTypeId,
                    Date_of_Birth__c = String.isNotBlank(custResp.personalInfo.dateofBirth) ? Date.valueOf(custResp.personalInfo.dateofBirth) : null,
                    PAN_Number__c = custResp.personalInfo.custCRCPR
                );
                if(lmsIdToAccMap.containsKey(cif)){
                    Account queriedAcc = lmsIdToAccMap.get(cif);
                    acc.Id = queriedAcc.Id;
                }
                if (custResp.categoryCode == 'RETAIL') {
                    if (custResp.extendedDetails != null && !custResp.extendedDetails.isEmpty()) {
                        for (COMM_GetCustomerController.cls_extendedDetails detail : custResp.extendedDetails) {
                            if (detail.extendedFields != null && !detail.extendedFields.isEmpty()) {
                                for (COMM_GetCustomerController.cls_extendedFields extField : detail.extendedFields) {
                                    if (extField.fieldName == 'IDNUMBER' && String.isNotBlank(extField.fieldValue)) {
                                        acc.Aadhar_Number__c = String.valueOf(extField.fieldValue);
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
                accToUpsert.add(acc);
            }
            Upsert accToUpsert;
            List<Account> upsertedAcc = [Select Id, Customer_LMS_ID__c, Applicant_Identifier__c from Account where Id in: accToUpsert];
            Map<String,Account> upsertedAccMap = new Map<String,Account>();
            for(Account acc : upsertedAcc){
                upsertedAccMap.put(acc.Customer_LMS_ID__c,acc);
            }
            Account primaryAccount;
            // --- Insert logic for co-applicants and guarantors only ---
            for(String cif : allCIFs) {
                if(appDet.size()>0 && appDet!=null && cif == primaryCIF) continue; // Skip primary for insert

                COMM_GetCustomerController.Response custResp = cifToResponse.get(cif);
                if(custResp == null) continue;
				System.debug('custResp=:'+JSON.serialize(custResp));
                // Account
                // Account acc = new Account(
                //     Name = custResp.personalInfo.firstName + ' ' + custResp.personalInfo.middleName + ' ' + custResp.personalInfo.lastName,
                //     First_Name__c = custResp.personalInfo.firstName,
                //     Last_Name__c  = custResp.personalInfo.lastName,
                //     Customer_LMS_Id__c = cif,
                //     RecordTypeId = customerRecordTypeId,
                //     Date_of_Birth__c = String.isNotBlank(custResp.personalInfo.dateofBirth) ? Date.valueOf(custResp.personalInfo.dateofBirth) : null,
                //     PAN_Number__c = custResp.personalInfo.custCRCPR
                // );
                // if (custResp.categoryCode == 'RETAIL') {
                //     if (custResp.extendedDetails != null && !custResp.extendedDetails.isEmpty()) {
                //         for (COMM_GetCustomerController.cls_extendedDetails detail : custResp.extendedDetails) {
                //             if (detail.extendedFields != null && !detail.extendedFields.isEmpty()) {
                //                 for (COMM_GetCustomerController.cls_extendedFields extField : detail.extendedFields) {
                //                     if (extField.fieldName == 'IDNUMBER' && String.isNotBlank(extField.fieldValue)) {
                //                         acc.Aadhar_Number__c = String.valueOf(extField.fieldValue);
                //                         break;
                //                     }
                //                 }
                //             }
                //         }
                //     }
                // }
                // accountsToInsert.add(acc);
                // tempCifToAccountMap.put(cif, acc);

                // Applicant
              Application_Applicant__c app = new Application_Applicant__c(
                    Salutation__c       = salutationMap.get(custResp.personalInfo.salutation),
                    Name                = custResp.personalInfo.firstName + ' ' + custResp.personalInfo.middleName + ' ' + custResp.personalInfo.lastName,
                    Pan_Name__c         = custResp.personalInfo.firstName + ' ' + custResp.personalInfo.middleName + ' ' + custResp.personalInfo.lastName,
                    First_Name__c       = custResp.personalInfo.firstName,
                    Middle_Name__c      = custResp.personalInfo.middleName,
                    Last_Name__c        = custResp.personalInfo.lastName,
                    Customer_Type__c    = custResp.categoryCode == 'RETAIL' ? 'Individual' : 'Non Individual',
                    Customer_Profile__c = custResp.personalInfo.subCategory=='SALARIED'?'Salaried Indian​':custResp.personalInfo.subCategory,
                    Email__c            = (custResp.emails != null && !custResp.emails.isEmpty()) ? custResp.emails[0].custEmail : null,
                    Mobile_Number__c    = (custResp.phones != null && !custResp.phones.isEmpty()) ? custResp.phones[0].phoneNumber : null,
                    Gender__c           = genderMap.get(custResp.personalInfo.gender)=='Others'?'Male':genderMap.get(custResp.personalInfo.gender),
                    Nationality__c      = natioanlityMap.get(String.valueOf(custResp.personalInfo.nationality)),
                    PAN_Number__c       = custResp.personalInfo.custCRCPR,
                    Cast_Category__c    = casteMap.get(String.valueOf(custResp.personalInfo.caste)),
                    Religion__c         = religionMap.get(String.valueOf(custResp.personalInfo.religion)),
                   // Industry__c         = industryMap.get(custResp.personalInfo.industry),
                   // Sector__c           = sectorMap.get(custResp.personalInfo.sector),
                    Loan_Application__c = recordId
                );
                if(upsertedAccMap.containsKey(cif)){
                    Account acc = upsertedAccMap.get(cif);
                    app.Customer__c = acc.Id;
                    if(cif == primaryCIF){
                        primaryAccount = acc;
                    }
                }
                // Now set DOB or DOI based on category
                if (custResp.categoryCode == 'RETAIL') {
                    app.DOB__c = String.isNotBlank(custResp.personalInfo.dateofBirth) ? Date.valueOf(custResp.personalInfo.dateofBirth.substring(0,10)) : null;
                    if (custResp.extendedDetails != null && !custResp.extendedDetails.isEmpty()) {
                        for (COMM_GetCustomerController.cls_extendedDetails detail : custResp.extendedDetails) {
                            if (detail.extendedFields != null && !detail.extendedFields.isEmpty()) {
                                for (COMM_GetCustomerController.cls_extendedFields extField : detail.extendedFields) {
                                    if (extField.fieldName == 'IDNUMBER' && String.isNotBlank(extField.fieldValue)) {
                                        app.Masked_Aadhar_Number__c = String.valueOf(extField.fieldValue);
                                        break;
                                    }
                                }
                            }
                        }
                    }
                } else if (custResp.categoryCode == 'CORP') {
                    app.DOI__c = String.isNotBlank(custResp.personalInfo.dateofBirth) ? Date.valueOf(custResp.personalInfo.dateofBirth.substring(0,10)) : null;
                }

                if(coApplicantCIFs.contains(cif)) app.Applicant_Type__c = 'Co Applicant';
                if(guarantorCIFs.contains(cif)) app.Applicant_Type__c = 'Guarantor';

                if (String.isNotBlank(custResp.personalInfo.fatherName)) {
                    app.Father_s_First_Name__c = custResp.personalInfo.fatherName.contains(' ') ? custResp.personalInfo.fatherName.substringBefore(' ') : custResp.personalInfo.fatherName;
                    app.Father_s_Last_Name__c  = custResp.personalInfo.fatherName.contains(' ') ? custResp.personalInfo.fatherName.substringAfter(' ') : null;
                }
                app.Is_Consent_Received__c=true;
                app.Consent_Status__c='Accepted';
                applicantsToInsert.add(app);
                tempCifToApplicantMap.put(cif, app);

                // Addresses
                if(custResp.addresses != null) {
                   // Integer addrCounter = 1;
                    for(COMM_GetCustomerController.cls_addresses addr : custResp.addresses) {
                        Applicant_Address__c ad = new Applicant_Address__c();
                        ad.Loan_Application__c = recordId;
                         ad.Address_Line_1__c = addr.addrLine1;
                       /*  if(String.isNotBlank(addr.addrLine1)) {
                ad.Address_Line_1__c = addr.addrLine1 + ' ' + addrCounter;
                } else {
                    ad.Address_Line_1__c = 'Address ' + addrCounter;
                }*/
                        ad.Address_Line_2__c = addr.addrLine2;
                        ad.Address_Line_3__c = addr.addrLine3;
                        ad.Address_Type__c ='Current';
                        //ad.Address_Type__c   = addressTypeMap.get(addr.addrType);
                        ad.Address_Priority__c = String.valueOf(addr.priority);

                        if(String.isNotBlank(addr.pinCode)) {
                            uniquePincodes.add(addr.pinCode);
                            addressToRawPin.put(ad, addr.pinCode);
                        }

                        if(!tempCifToAddressList.containsKey(cif)) tempCifToAddressList.put(cif, new List<Applicant_Address__c>());
                        tempCifToAddressList.get(cif).add(ad);
                        //addrCounter++;
                    }
                }
            }

            // --- Primary applicant update logic ---
            Application_Applicant__c primaryApplicant;
            if(primaryCIF != null) {
                List<Application_Applicant__c> primaryList = [
                    SELECT Id, Customer__c FROM Application_Applicant__c  WHERE Loan_Application__c = :recordId AND Applicant_Type__c = 'Primary Applicant'  LIMIT 1];
                if(!primaryList.isEmpty()){
                    primaryApplicant = primaryList[0];
                    primaryApplicant.Is_Consent_Received__c=true;
                    COMM_GetCustomerController.Response primResp = cifToResponse.get(primaryCIF);

                    if (primResp != null && primResp.personalInfo != null) {
                        primaryApplicant.Salutation__c = salutationMap.get(primResp.personalInfo.salutation);
                        primaryApplicant.Name = primResp.personalInfo.firstName + ' ' + primResp.personalInfo.middleName + ' ' + primResp.personalInfo.lastName;
                        primaryApplicant.First_Name__c  = primResp.personalInfo.firstName;
                        primaryApplicant.Middle_Name__c = primResp.personalInfo.middleName;
                        primaryApplicant.Last_Name__c   = primResp.personalInfo.lastName;
                        primaryApplicant.Customer_Type__c = primResp.categoryCode == 'RETAIL' ? 'Individual' : 'Non Individual';
                        //primaryApplicant.Customer_Profile__c = primResp.personalInfo.subCategory;
                        primaryApplicant.Pan_Name__c = primResp.personalInfo.firstName + ' ' + primResp.personalInfo.middleName + ' ' + primResp.personalInfo.lastName;
                        primaryApplicant.Gender__c      = genderMap.get(primResp.personalInfo.gender);
                        primaryApplicant.Email__c = (primResp.emails != null && !primResp.emails.isEmpty())  ? primResp.emails[0].custEmail : null;
                        primaryApplicant.Mobile_Number__c = (primResp.phones != null && !primResp.phones.isEmpty()) ? primResp.phones[0].phoneNumber : null;
                       if (primResp.categoryCode == 'RETAIL') {
                            primaryApplicant.DOB__c = String.isNotBlank(primResp.personalInfo.dateofBirth) ? Date.valueOf(primResp.personalInfo.dateofBirth.substring(0,10)) : null;
                            if (primResp.extendedDetails != null && !primResp.extendedDetails.isEmpty()) {
                                for (COMM_GetCustomerController.cls_extendedDetails detail : primResp.extendedDetails) {
                                    if (detail.extendedFields != null && !detail.extendedFields.isEmpty()) {
                                        for (COMM_GetCustomerController.cls_extendedFields extField : detail.extendedFields) {
                                            if (extField.fieldName == 'IDNUMBER' && String.isNotBlank(extField.fieldValue)) {
                                                primaryApplicant.Masked_Aadhar_Number__c = String.valueOf(extField.fieldValue);
                                                break;
                                            }
                                        }
                                    }
                                }
                            }    
                        }else if (primResp.categoryCode == 'CORP') {
                            primaryApplicant.DOI__c = String.isNotBlank(primResp.personalInfo.dateofBirth) ? Date.valueOf(primResp.personalInfo.dateofBirth.substring(0,10)) : null;
                        }

                        primaryApplicant.Cast_Category__c = casteMap.get(String.valueOf(primResp.personalInfo.caste));
                        primaryApplicant.Religion__c    = religionMap.get(String.valueOf(primResp.personalInfo.religion));
                        primaryApplicant.Nationality__c = natioanlityMap.get(String.valueOf(primResp.personalInfo.nationality));
                        //primaryApplicant.Industry__c = industryMap.get(primResp.personalInfo.industry);
                        //primaryApplicant.Sector__c = sectorMap.get(primResp.personalInfo.sector);

                        if (String.isNotBlank(primResp.personalInfo.fatherName)) {
                            primaryApplicant.Father_s_First_Name__c = primResp.personalInfo.fatherName.contains(' ') ? primResp.personalInfo.fatherName.substringBefore(' ') : primResp.personalInfo.fatherName;
                            primaryApplicant.Father_s_Last_Name__c  = primResp.personalInfo.fatherName.contains(' ') ? primResp.personalInfo.fatherName.substringAfter(' ') : null;
                        }

                        if(primaryApplicant.Customer__c != null) {
                            Account accToUpdate = new Account(
                                Id = primaryApplicant.Customer__c,
                                Customer_LMS_Id__c = primaryCIF,
                                Name = primaryApplicant.Name,
                                First_Name__c = primResp.personalInfo.firstName,
                                Last_Name__c  = primResp.personalInfo.lastName,
                                Date_of_Birth__c = String.isNotBlank(primResp.personalInfo.dateofBirth) ? Date.valueOf(primResp.personalInfo.dateofBirth.substring(0,10)) : null,
                                PAN_Number__c = primResp.personalInfo.custCRCPR
                            );
                            if (primResp.categoryCode == 'RETAIL') {
                                if (primResp.extendedDetails != null && !primResp.extendedDetails.isEmpty()) {
                                    for (COMM_GetCustomerController.cls_extendedDetails detail : primResp.extendedDetails) {
                                        if (detail.extendedFields != null && !detail.extendedFields.isEmpty()) {
                                            for (COMM_GetCustomerController.cls_extendedFields extField : detail.extendedFields) {
                                                if (extField.fieldName == 'IDNUMBER' && String.isNotBlank(extField.fieldValue)) {
                                                    accToUpdate.Aadhar_Number__c = String.valueOf(extField.fieldValue);
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            update accToUpdate;
                        }

                        // Addresses for primary
                        if(primResp.addresses != null) {
                            List<Applicant_Address__c> primaryAddrList = new List<Applicant_Address__c>();
                            for(COMM_GetCustomerController.cls_addresses addr : primResp.addresses) {
                                Applicant_Address__c ad = new Applicant_Address__c(
                                    Loan_Application__c = recordId,
                                    Address_Line_1__c = addr.addrLine1,
                                    Address_Line_2__c = addr.addrLine2,
                                    Address_Line_3__c = addr.addrLine3,
                                    Address_Type__c   = addressTypeMap.get(addr.addrType)
                                );

                                if(String.isNotBlank(addr.pinCode)) {
                                    uniquePincodes.add(addr.pinCode);
                                    addressToRawPin.put(ad, addr.pinCode);
                                }

                                primaryAddrList.add(ad);
                            }
                            tempCifToAddressList.put(primaryCIF, primaryAddrList);
                        }

                        tempCifToApplicantMap.put(primaryCIF, primaryApplicant);
                    }
                }
            }

            if(primaryApplicant != null) update primaryApplicant;  
            if(!accountsToInsert.isEmpty()) insert accountsToInsert;
            if(!applicantsToInsert.isEmpty()) insert applicantsToInsert;
            List<Application_Applicant__c> appList = [Select Id, Customer__c, Customer__r.Customer_LMS_Id__c from Application_Applicant__c where Id in: applicantsToInsert];
            List<String> custIds = new List<String>();
            for(Application_Applicant__c app : appList){
                if(app.Customer__r.Customer_LMS_Id__c != null){
                    custIds.add(app.Customer__r.Customer_LMS_Id__c);
                }
            }
            List<Account> queriedAccList = [Select Id, Applicant_Identifier__c, Customer_LMS_Id__c from Account where Customer_LMS_Id__c in: custIds];
            Map<String,List<Account>> lmsToAccMap = new Map<String,List<Account>>();
            for(Account acc : queriedAccList){
                if(lmsToAccMap.containsKey(acc.Customer_LMS_Id__c)){
                    lmsToAccMap.get(acc.Customer_LMS_Id__c).add(acc);
                }
                else{
                    lmsToAccMap.put(acc.Customer_LMS_Id__c, new List<Account>{acc});
                }
            }
            List<Account> accToUpdate = new List<Account>();
            for(Application_Applicant__c app : appList){
                if(app.Customer__r.Customer_LMS_Id__c != null){
                    if(lmsToAccMap.containskey(app.Customer__r.Customer_LMS_Id__c)){
                        List<Account> acc = lmsToAccMap.get(app.Customer__r.Customer_LMS_Id__c);
                        if(acc != null && !acc.isEmpty()){
                            for(Account a : acc){
                                if(a.Applicant_Identifier__c == null){
                                    a.Applicant_Identifier__c = app.Id;
                                }
                                else{
                                    if(!a.Applicant_Identifier__c.contains(app.Id)){
                                        if(a.Applicant_Identifier__c == null){
                                            a.Applicant_Identifier__c = app.Id;
                                            accToUpdate.add(a);
                                        }
                                        else{
                                            a.Applicant_Identifier__c = a.Applicant_Identifier__c+','+app.Id;
                                            accToUpdate.add(a);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if(!accToUpdate.isEmpty()){
                Update accToUpdate;
            }
            // --- Pincode mapping ---
            Map<String, Id> pincodeMap = new Map<String, Id>();
            if(!uniquePincodes.isEmpty()) {
                for(Pincode_Master__c pin : [
                    SELECT Id, Name 
                    FROM Pincode_Master__c 
                    WHERE Name IN :uniquePincodes
                ]) {
                    pincodeMap.put(pin.Name, pin.Id);
                }
            }
           

            // Assign Applicant and Pincode to all addresses
            for(String cif : tempCifToAddressList.keySet()) {
                Application_Applicant__c app = tempCifToApplicantMap.get(cif);
                system.debug('tempCifToAddressList---'+app);
                if(app != null) {
                    for(Applicant_Address__c ad : tempCifToAddressList.get(cif)) {
                        if(addressToRawPin.containsKey(ad)) {
                            String rawPin = addressToRawPin.get(ad);
                            if(pincodeMap.containsKey(rawPin)) ad.Pincode__c = pincodeMap.get(rawPin);
                        }
                        ad.Applicant__c = app.Id;
                        addressesToInsert.add(ad);
                    }
                }
            }

            if(!addressesToInsert.isEmpty()) insert addressesToInsert;

            // --- Collateral logic ---
            COMM_GetCollateraDetailsController.CollateralResponseWrapper collateralResp;
            if(!collateralMap.isEmpty() && primaryCIF != null) {
                try {
                    collateralResp = COMM_GetCollateraDetailsController.getCollateralDetails(primaryCIF, 'Get Collateral Details');
                } catch(Exception e) {
                    System.debug('Error fetching collateral details: ' + e.getMessage());
                }
            }

            if(collateralResp != null && collateralResp.collateral != null) {
                Set<String> collateralRefs = collateralMap.keySet();
                Map<String, Collateral__c> existingCollMap = new Map<String, Collateral__c>();
                for(Collateral__c c : [
                    SELECT Id, EXTERNAL_ID__c,PLF_ID__c, Assigned_Percentage__c 
                    FROM Collateral__c 
                    WHERE PLF_ID__c IN :collateralRefs AND IsActive__c = True
                ]) {
                    existingCollMap.put(c.PLF_ID__c, c);
                }

                Map<String, Collateral__c> newCollMap = new Map<String, Collateral__c>();
                for(COMM_GetCollateraDetailsController.Collateral colObj : collateralResp.collateral) {
                    String ref = colObj.collateralRef;
                    if(collateralMap.containsKey(ref)) {
                        Collateral__c col;
                        if(existingCollMap.containsKey(ref)) {
                            col = existingCollMap.get(ref);
                            col.Assigned_Percentage__c = collateralMap.get(ref);
                        } else {
                            col = new Collateral__c(
                                EXTERNAL_ID__c = ref,
                                PLF_ID__c = ref,
                                Assigned_Percentage__c = collateralMap.get(ref)
                            );
                            collateralsToInsert.add(col);
                            newCollMap.put(ref, col);
                        }
                        Application_Collateral__c appCol = new Application_Collateral__c(
                            HL_Loan_Application__c = recordId,
                            Collateral__c = col.Id
                        );
                        appCollateralsToInsert.add(appCol);
                    }
                }

                if(!collateralsToInsert.isEmpty()) insert collateralsToInsert;

                for(Application_Collateral__c appCol : appCollateralsToInsert) {
                    if(appCol.Collateral__c == null) {
                        for(String ref : newCollMap.keySet()) {
                            appCol.Collateral__c = newCollMap.get(ref).Id;
                        }
                    }
                }
                if(!appCollateralsToInsert.isEmpty()) insert appCollateralsToInsert;
            }

            // --- Update Opportunity ---
            Opportunity oppToUpdate = new Opportunity(Id = recordId, Parent_Loan_Number__c = loanNumber, Is_Top_Up__c = 'Yes',Login_Completion_Stage__c ='Applicant Information;Application Information');
            List<Opportunity> oppList = [Select Id, AccountId, Requested_Amount__c from Opportunity where Id =: recordId];
            if(oppList[0].AccountId == null){
                if(primaryAccount != null){
                    oppToUpdate.AccountId = primaryAccount.Id;
                }
            }
            update oppToUpdate;
            // appDet[0].Is_Consent_Received__c=true;
            // update appDet;


            List<Product_Master__c> prodMaster = [Select Id, Name, RecordType.Name from Product_Master__c];
            Map<String,Product_Master__c> nameToMasterMap = new Map<String,Product_Master__c>();
            for(Product_Master__c iterMstr : prodMaster){
                nameToMasterMap.put(iterMstr.Name, iterMstr);
            }
            Id recTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Product').getRecordTypeId();
            Id recTypeIdSubProduct = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Product').getRecordTypeId();
            Id recTypeIdVariant = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Variant').getRecordTypeId();
            Id recTypeIdSubVariant = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Variant').getRecordTypeId();
            Id recTypeIdTenure = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Hybrid_Tenure').getRecordTypeId();
            Id recTypeIdFullEmiTenure = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Full_EMI').getRecordTypeId();
            Id recTypeIdScheme = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Scheme').getRecordTypeId();
            Id recTypeIdTotalTnr = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Total_Tenure').getRecordTypeId();
            String loanProd = [Select id,Product__c from Opportunity where id=:oppToUpdate.Id].Product__c;
            List<Product2> prod= new List<Product2>();
            prod=[Select id from Product2 where RecordType.Name='Product' and Name=:loanProd Limit 1];
            if(loanProd !='Flexi Loan'){
             
                Product2 mainProd = new Product2();
                mainProd.Loan_Application__c = oppToUpdate.Id;
                mainProd.Name = 'Home Loan';
                mainProd.RecordTypeId = recTypeId;
                mainProd.Product_Master__c = nameToMasterMap.get('Home Loan').Id;
                if(prod.size()==0){
                    Insert mainProd;
                }
                else{
                    mainProd.Id =prod[0].id;
                    update mainProd;

                }
            
                Product2 subProd = new Product2();
                subProd.Loan_Application__c = oppToUpdate.Id;
                subProd.Name ='HL Top up';
                subProd.RecordTypeId = recTypeIdSubProduct;
                subProd.Product_Master__c = nameToMasterMap.get('HL Top up').Id;
                subProd.Product__c = mainProd.Id;
                Insert subProd;
                Product2 varProd = new Product2();
                varProd.Loan_Application__c = oppToUpdate.Id;
                varProd.Name = 'Term Loan';
                varProd.RecordTypeId = recTypeIdVariant;
                varProd.Product_Master__c = nameToMasterMap.get('Term Loan').Id;
                varProd.Product__c = subProd.Id;
                Insert varProd;
                Product2 subVar = new Product2();
                subVar.Loan_Application__c = oppToUpdate.Id;
                String subVariant;
                subVar.Name = 'Regular';
                subVariant = 'Regular';
                subVar.RecordTypeId = recTypeIdSubVariant;
                subVar.Product_Master__c = nameToMasterMap.get(subVariant).Id;
                subVar.Product__c = subProd.Id;
                subVar.Variant__c = varProd.Id;
                Insert subVar;
                Product2 schemeProd = new Product2();
                schemeProd.Loan_Application__c = oppToUpdate.Id;
                schemeProd.Name = 'Regular';
                schemeProd.RecordTypeId = recTypeIdScheme;
                schemeProd.Product_Master__c = nameToMasterMap.get('Regular').Id;
                schemeProd.Product__c = subProd.Id;
                schemeProd.Variant__c = varProd.Id;
                schemeProd.Sub_Variant__c = subVar.Id;
                Insert schemeProd;
            }
            else{
               List<Product_Master__c> prodMasterFL = [Select id from Product_Master__c where RecordType.Name='Product' and Name=:loanProd AND IsApplicableForHL__c = true Limit 1];
            Product2 prodMain = new Product2();
            prodMain.Name = loanProd;
            prodMain.Loan_Application__c =  oppToUpdate.Id;
            prodMain.Product_Master__c=prodMasterFL[0].id;
            prodMain.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
            prodMain.Product_Type__c='Parent';
            // if(opp[0].Product__c=='Home Loan'){
            //     prod.Product_Type__c='Parent';
            // }
            insert prodMain;
            System.debug('Product----'+prodMain.Product_Type__c);
            if(loanProd=='Flexi Loan'){
                
                List<Product_Master__c> prodMasterRec = [Select Id, Name, RecordType.Name from Product_Master__c  where IsApplicableForHL__c = true];
              
                for(Product_Master__c iterMstr : prodMasterRec){
                    nameToMasterMap.put(iterMstr.Name, iterMstr);
                }
                
                Map<String, Product_Master__c> subProductMasterMap = new Map<String, Product_Master__c>(); 
                Map<String, Product_Master__c> variantMasterMap = new Map<String, Product_Master__c>(); 
                Map<String, Product_Master__c> subVariantMasterMap = new Map<String, Product_Master__c>(); 
                Map<String, Product_Master__c> schemeMasterMap = new Map<String, Product_Master__c>(); 
                for(Product_Master__c master: prodMasterRec){
                    if(master.RecordType.Name=='Sub Product'){
                        subProductMasterMap.put(master.Name, master);
                    }
                    if(master.RecordType.Name=='Variant'){
                        variantMasterMap.put(master.Name, master);
                    }
                    if(master.RecordType.Name=='Sub Variant'){
                        subVariantMasterMap.put(master.Name, master);
                    }
                    if(master.RecordType.Name=='Scheme'){
                        schemeMasterMap.put(master.Name, master);
                    }
                }   
                
                Product2 subProd = new Product2();
                subProd.Loan_Application__c = oppToUpdate.Id;
                subProd.Name ='Flexi Loan';
                subProd.RecordTypeId = recTypeIdSubProduct;
                subProd.Product_Master__c = subProductMasterMap.get('Flexi Loan').Id;
                subProd.Product__c = prodMain.id;
                subProd.Requested_Loan_Amount__c = oppList[0].Requested_Amount__c;
                Insert subProd;
                Product2 varProd = new Product2();
                varProd.Loan_Application__c = oppToUpdate.Id;
                varProd.Name = 'Term Loan';
                varProd.RecordTypeId = recTypeIdVariant;
                varProd.Product_Master__c = variantMasterMap.get('Term Loan').Id;
                varProd.Product__c = subProd.Id;
                Insert varProd;
                Product2 subVar = new Product2();
                subVar.Loan_Application__c =oppToUpdate.Id;
                String subVariant;
                subVar.Name = 'Regular';
                subVariant = 'Regular';
                subVar.RecordTypeId = recTypeIdSubVariant;
                subVar.Product_Master__c = subVariantMasterMap.get(subVariant).Id;
                subVar.Product__c = subProd.Id;
                subVar.Variant__c = varProd.Id;
                Insert subVar;
                Product2 schemeProd = new Product2();
                schemeProd.Loan_Application__c =oppToUpdate.Id;
                schemeProd.Name = 'Regular';
                schemeProd.RecordTypeId = recTypeIdScheme;
                schemeProd.Product_Master__c = schemeMasterMap.get('Regular').Id;
                schemeProd.Product__c = subProd.Id;
                schemeProd.Variant__c = varProd.Id;
                schemeProd.Sub_Variant__c = subVar.Id;
                Insert schemeProd;
            }
            Comm_LeadToLoanConversionController.updateLoanBranchAndSubBranch(oppToUpdate.Id);
                    
        }
        
          
           
             
        } catch(Exception ex) {
            System.debug('Error in createRelatedRecords: ' + ex.getMessage());
            throw new AuraHandledException('Error processing loan data: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static List<DuplicateCustomerUIWrapper> checkDeduplicate(Map<String, String> inputMap) {
        System.debug('Input Map: ' + inputMap);
        Boolean isFromLead = Boolean.valueOf(inputMap.get('fromLead'));
        List<DuplicateCustomerUIWrapper> result = new List<DuplicateCustomerUIWrapper>();
        Date dob = inputMap.containsKey('dob') && String.isNotBlank(inputMap.get('dob')) 
            ? Date.valueOf(inputMap.get('dob')) 
            : null;

        try {
            // --- Step 1: Salesforce dedupe check ---
            List<Account> sfdcMatches = [
                SELECT Id, Customer_LMS_Id__c ,UCIC_Number__c, PAN_Number__c, Aadhar_Number__c, 
                    Voter_ID_Number__c, Passport_File_Number__c, Drivers_License_Number__c,
                    Mobile_Number__c, Date_of_Birth__c, Name, Customer_Type__c 
                FROM Account 
                WHERE Is_Active__c = true
                AND (
                    (PAN_Number__c != null AND PAN_Number__c = :inputMap.get('panNumber')) OR
                    (Aadhar_Number__c != null AND Aadhar_Number__c = :inputMap.get('aadharNumber')) OR
                    (Voter_ID_Number__c != null AND Voter_ID_Number__c = :inputMap.get('voterNumber')) OR
                    (Passport_File_Number__c != null AND Passport_File_Number__c = :inputMap.get('passportNumber')) OR
                    (Drivers_License_Number__c != null AND Drivers_License_Number__c = :inputMap.get('passportNumber')) OR
                    (Mobile_Number__c = :inputMap.get('mobileNumber') AND Date_of_Birth__c = :dob AND Name = :inputMap.get('panName'))
                )
            ];
            
            // Collect account ids
            Set<Id> sfdcAccountIds = new Set<Id>();
            for (Account a : sfdcMatches) {
                sfdcAccountIds.add(a.Id);
            }
            
            // Query if related loans exist
            Set<Id> accountsWithLoans = new Set<Id>();
            if (!sfdcAccountIds.isEmpty()) {
                for (AggregateResult ar : [
                    SELECT AccountId accId 
                    FROM Opportunity 
                    WHERE AccountId IN :sfdcAccountIds 
                    GROUP BY AccountId
                ]) {
                    accountsWithLoans.add((Id) ar.get('accId'));
                }
            }
            
            // Build wrappers for SFDC matches
            for (Account matchedAcc : sfdcMatches) {
                List<String> reasons = new List<String>();
                if (matchedAcc.PAN_Number__c == inputMap.get('panNumber') && matchedAcc.PAN_Number__c != null) reasons.add('PAN');
                if (matchedAcc.Aadhar_Number__c == inputMap.get('aadharNumber') && matchedAcc.Aadhar_Number__c != null) reasons.add('Aadhaar');
                if (matchedAcc.Voter_ID_Number__c == inputMap.get('voterNumber') && matchedAcc.Voter_ID_Number__c != null) reasons.add('Voter');
                if (matchedAcc.Passport_File_Number__c == inputMap.get('passportNumber') && matchedAcc.Passport_File_Number__c != null) reasons.add('Passport');
                if (matchedAcc.Mobile_Number__c == inputMap.get('mobileNumber') && matchedAcc.Date_of_Birth__c == dob && matchedAcc.Name == inputMap.get('panName')) {
                    reasons.add('Mobile + DOB + Name');
                }
                
                DuplicateCustomerUIWrapper wrap = new DuplicateCustomerUIWrapper();
                wrap.cif = matchedAcc.Customer_LMS_Id__c;
                wrap.ucic = matchedAcc.UCIC_Number__c;
                wrap.accId = matchedAcc.Id;
                wrap.name = matchedAcc.Name;
                wrap.mobileNumber = matchedAcc.Mobile_Number__c;
                wrap.pan = matchedAcc.PAN_Number__c;
                wrap.aadhar = matchedAcc.Aadhar_Number__c;
                wrap.voterId = matchedAcc.Voter_ID_Number__c;
                wrap.passport = matchedAcc.Passport_File_Number__c;
                wrap.drivingLicense = matchedAcc.Drivers_License_Number__c;
                wrap.customerType = matchedAcc.Customer_Type__c;
                wrap.sourceSystem = 'SF';
                wrap.matchReason = String.join(reasons, ', ');
                wrap.dob = matchedAcc.Date_of_Birth__c!=null?String.valueof(matchedAcc.Date_of_Birth__c):null;
                wrap.disable = accountsWithLoans.contains(matchedAcc.Id);

                // ✅ Always set unique key
                wrap.key = String.isNotBlank(matchedAcc.Customer_LMS_Id__c) ? matchedAcc.Customer_LMS_Id__c :
                        String.isNotBlank(matchedAcc.UCIC_Number__c)      ? matchedAcc.UCIC_Number__c :
                        matchedAcc.Id;

                result.add(wrap);
            }
            
            // --- Step 2: External API call (UCIC) ---
            Map<String, String> apiInputMap = new Map<String, String>{
                'loanId' => inputMap.get('loanId'),
                'applicantId' => null,
                'processName' => 'UCIC De Dupe Check',
                'panNumber' => inputMap.get('panNumber'),
                'panName' => inputMap.get('panName'),
                'dob' => inputMap.get('dob'),
                'mobileNumber' => inputMap.get('mobileNumber'),
                'dlNumber' => inputMap.get('dlNumber'),
                'voterNumber' => inputMap.get('voterNumber'),
                'aadharNumber' => inputMap.get('aadharNumber'),
                'passportNumber' => inputMap.get('passportNumber'),
                'gender' => null,
                'isFromLead'=>inputMap.get('fromLead')
            };
            
            String resp = COMM_UCICController.initiateAPIRequest(apiInputMap);
            if (resp.contains('error')) {
                throw new AuraHandledException('Error while Checking Dedupe: ' + resp);
            }

            COMM_UCICController.UCICDeduplicationInfo dedupeInfo = 
                (COMM_UCICController.UCICDeduplicationInfo) JSON.deserialize(resp, COMM_UCICController.UCICDeduplicationInfo.class);

            System.debug('Deserialized dedupeInfo: ' + JSON.serializePretty(dedupeInfo));

            if (dedupeInfo != null && dedupeInfo.duplicateCustomers != null) {
                for (COMM_UCICController.CustomerMatch match : dedupeInfo.duplicateCustomers) {
                    DuplicateCustomerUIWrapper wrap = new DuplicateCustomerUIWrapper();
                    wrap.cif = match.customerId;
                    wrap.ucic = match.UCIC;
                    wrap.accId = '';
                    wrap.name = match.name;
                    wrap.mobileNumber = match.mobileNumber;
                    wrap.pan = match.panNumber;
                    wrap.aadhar = match.aadhar;   
                    wrap.voterId = match.voterId;  
                    wrap.passport = match.passport; 
                    wrap.drivingLicense = match.dlNumber; 
                   wrap.customerType = match.customerType != null
                    ? (match.customerType == 'Retail'
                        ? 'Individual'
                        : (match.customerType == 'Corp' ? 'Non Individual' : ''))
                    : '';
                    wrap.sourceSystem = 'UCIC';
                    wrap.matchReason = match.matchReason;
                    wrap.dob = match.dob!=null?String.valueof(match.dob):null;
                    wrap.disable = String.isNotBlank(match.UCIC) || String.isNotBlank(match.customerId);

                    // ✅ Always set unique key
                    wrap.key = String.isNotBlank(match.customerId) ? match.customerId :
                            String.isNotBlank(match.UCIC)       ? match.UCIC :
                            String.valueOf(Crypto.getRandomInteger());

                    result.add(wrap);
                }
            }

        } catch (Exception ex) {
            throw new AuraHandledException('Exception in checkDeduplicate: ' + ex.getMessage());
        }
        
        return result;
    }

    public class DuplicateCustomerUIWrapper {
        @AuraEnabled public String key;
        @AuraEnabled public String cif;
        @AuraEnabled public String ucic;
        @AuraEnabled public String accId;
        @AuraEnabled public String name;
        @AuraEnabled public String mobileNumber;
        @AuraEnabled public String pan;
        @AuraEnabled public String aadhar;
        @AuraEnabled public String voterId;
        @AuraEnabled public String passport;
        @AuraEnabled public String drivingLicense;
        @AuraEnabled public String customerType;
        @AuraEnabled public String sourceSystem;
        @AuraEnabled public String matchReason;
        @AuraEnabled public Boolean disable;
        @AuraEnabled public String dob;
    }

}