//dummy 
/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 05-26-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
public with sharing class DocGenPreviewRequestWrapper {
    @AuraEnabled
    
    public static void syncContentDocumentIds(List<Id> documentIds) {
        if (documentIds == null || documentIds.isEmpty()) {
            return;
        }
        system.debug('documentIds'+ documentIds);
        List<Document_Details__c> mergedDocumentList = [
            SELECT Id, Document_Master__c, Content_Document_Id__c
            FROM Document_Details__c
            WHERE Id IN :documentIds order by CreatedDate
        ];
        system.debug('mergedDocumentList'+ mergedDocumentList);
        Set<Id> masterIds = new Set<Id>();
        for (Document_Details__c dd : mergedDocumentList) {
            if (dd.Document_Master__c != null) {
                masterIds.add(dd.Document_Master__c);
            }
        }
        
        if (masterIds.isEmpty()) {
            return;
        }
        
        List<ContentDocumentLink> cdlList = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :masterIds ];
        
        Map<Id, Id> masterToContentDocMap = new Map<Id, Id>();
        for (ContentDocumentLink cdl : cdlList) {
            if (!masterToContentDocMap.containsKey(cdl.LinkedEntityId)) {
                masterToContentDocMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
            }
        }
        
        List<Document_Details__c> recordsToUpdate = new List<Document_Details__c>();
        for (Document_Details__c dd : mergedDocumentList) {
            if (masterToContentDocMap.containsKey(dd.Document_Master__c)) {
                Id latestContentDocId = masterToContentDocMap.get(dd.Document_Master__c);
                if (dd.Content_Document_Id__c != latestContentDocId) {
                    dd.Content_Document_Id__c = latestContentDocId;
                    recordsToUpdate.add(dd);
                }
            }
        }
        system.debug('recordsToUpdate'+ recordsToUpdate);
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }
    public static DocGenPreviewJSONCreator createRequestPayload (List<Id> documentId, Id loanId, String docType){
        try{
            Map<string, string> contdocIdToDocType  =   new  Map<string, string>();
            Map<string, Decimal> contdocIdToSequence  =   new  Map<string, Decimal>();
            set<Id> contentDocId                    =   new  set<Id>();
            
            List<Document_Details__c> mergedDocumentList = [select Id, Name, Document_Type__c, 
                                                 Content_Document_Id__c, Loan_Application__r.Loan_Application_Number__c, DocGen_Sequence__c 
                                                 from Document_Details__c where Id IN:documentId];
            
            Decimal sequenceCounter = 1;
            
            for(Document_Details__c dd : mergedDocumentList)
            {
                if(!contdocIdToDocType.containsKey(dd.Content_Document_Id__c)){
                    contdocIdToDocType.put(dd.Content_Document_Id__c , dd.Document_Type__c);
                }
                contentDocId.add(dd.Content_Document_Id__c);
                if(!contdocIdToSequence.containsKey(dd.Content_Document_Id__c)){
                    if(dd.Name == 'Eseal'){
                        contdocIdToSequence.put(dd.Content_Document_Id__c , dd.DocGen_Sequence__c);
                    } else {
                        contdocIdToSequence.put(dd.Content_Document_Id__c , sequenceCounter);
                        sequenceCounter++;
                    }
                }
            }
            
            System.debug('contdocIdToDocType : '+contdocIdToDocType);
            System.debug('contdocIdToSequence : '+contdocIdToSequence);
            System.debug('contentDocId : '+contentDocId);
            System.debug('documentId : '+documentId);
            System.debug('mergedDocumentList : '+mergedDocumentList);
            List<ContentVersion> esignDocumentContentVersion = [select Id, ContentDocumentId, Title, FileType, PathOnClient from ContentVersion where ContentDocumentId IN: contentDocId ];
            System.debug('esignDocumentContentVersion : '+esignDocumentContentVersion);
            DocGenPreviewJSONCreator docGenPreviewRequestpayload = docuGenPreviewRequest(contdocIdToDocType,contdocIdToSequence, esignDocumentContentVersion, loanId, mergedDocumentList[0].Loan_Application__r.Loan_Application_Number__c, docType);
            return docGenPreviewRequestpayload;
        }
        catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage());
            return null;
        }
    }
    public static DocGenPreviewJSONCreator docuGenPreviewRequest(Map<string, string> contdocIdToDocType,Map<string, Decimal> contdocIdToSequence, List<ContentVersion> contVersion, Id loanAppId, string slan, String docType){
        system.debug('docType  '+docType);
        
        DocGenPreviewJSONCreator docGenPreviewRequest                           =   new DocGenPreviewJSONCreator();
        Map<string, List<Document_Template_New__mdt>> getTemplateTometadata         =   new  Map<string, List<Document_Template_New__mdt>>();
        List<DocGenPreviewJSONCreator.digiUploadDocuments> uploadDocList        =   new List<DocGenPreviewJSONCreator.digiUploadDocuments>();
        List<Document_Template_New__mdt> documentTemplateKeywords                   =   Document_Template_New__mdt.getAll().values();
        set<Id> apId = new set<Id>();
        Map<string, Map<string, List<Document_Template_New__mdt>>> getRecordsbyTemplate = new  Map<string, Map<string, List<Document_Template_New__mdt>>>();
        Map<string, List<Document_Template_New__mdt>> getObjRecords =   new  Map<string, List<Document_Template_New__mdt>>();
        
        //Multi product check
        Id loanId; //Parent or Individual loan Id
        Id childLoanId; //Child loan Id
        Boolean isMultiProduct = false;
        
        Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('oppId', loanAppId);
        Utility_V1.ProductWrapper productWrapper = Utility_V1.getProductDetails(inputMap);
        Boolean isHlRelated = productWrapper.isHLRelated;
        
        // Adding for the HL telangana MODT form document fields
        // HL DOCUMENT FETCH
        List<Document_Details__c> ApprovedDocs = new List<Document_Details__c>();
        
        if (isHlRelated) {
            // ApprovedDocs = [Select id,Name,Target_Date__c, Covenant_Master__r.covenanttype__c, Document_Type__c from Document_Details__c where Covenant_Master__c != null and Loan_Application__c= :loanAppId  AND Document_Type__c  ='PDD-Approved'];
            ApprovedDocs = [Select Id, Name, Document_Type__c, Document_Date_of_Receipt__c,Remarks__c,Nature_of_Document__c  FROM Document_Details__c where Covenant_Master__c != null and Loan_Application__c = :loanAppId AND Document_Type__c  IN ('CSD- Approved','Received - Checker','PDD-Approved' )]; //added by Surabhi for SFHL-1883
        }
        
        // Create index mapping
        /*Map<Integer, String> AppIndexNameMap = new Map<Integer, String>();
        Map<Integer, String> AppIndexDateMap = new Map<Integer, String>();
        
        Integer AppIndex = 0;
        for (Document_Details__c doc : ApprovedDocs) {
            AppIndexNameMap.put(AppIndex, doc.Name);
            AppIndexDateMap.put(AppIndex, String.valueOf(doc.Document_Date_of_Receipt__c));
            AppIndex++;
        } //commented by Surabhi for SFHL-1883*/
        
        //added by Surabhi for SFHL-1883 - start
        Map<Integer, Document_Details__c> docIndexMap = new Map<Integer, Document_Details__c>();
        
        Integer nume = 0;
        for (Document_Details__c doc : ApprovedDocs) {
            docIndexMap.put(nume, doc);
            nume++;
        }
        //added by Surabhi for SFHL-1883 - end
        
        Opportunity oppRec = [SELECT Loan_Hierarchy__c, Split_Parent_Loan_Application__c, Id FROM Opportunity WHERE Id =: loanAppId LIMIT 1];
        
        // if (oppRec != null && oppRec.Split_Parent_Loan_Application__c != null && oppRec.Loan_Hierarchy__c == 'Child') {
            //     isMultiProduct = true;
            //     loanId = oppRec.Split_Parent_Loan_Application__c;
            //     childLoanId = oppRec.Id;
        // } else {
            //     isMultiProduct = false;
            //     loanId = oppRec.Id;
        // }
        
        if (oppRec != null) {
            // Determine if it’s a child loan
            isMultiProduct = oppRec.Loan_Hierarchy__c == 'Child' && oppRec.Split_Parent_Loan_Application__c != null;
            
            // Assign loanId based on hierarchy
            loanId = isMultiProduct ? oppRec.Split_Parent_Loan_Application__c : oppRec.Id;
            
            // Assign childLoanId only if it’s a multi-product
            childLoanId = isMultiProduct ? oppRec.Id : null;
        }
        
        Decimal hlFinalTenure;
        Decimal hlMargin;
        if (isHlRelated) {
            List<Product2> hlTenureProducts = [SELECT Id, Final_Tenure__c,Sanctioned_ROI__c,PLR_Value__c FROM Product2 WHERE Loan_Application__c = :loanId AND Product__r.Name = 'Home Loan' LIMIT 1];
            if (!hlTenureProducts.isEmpty()) {
                Product2 hlProduct = hlTenureProducts[0];
                if (hlProduct.Final_Tenure__c != null) {
                    hlFinalTenure = hlProduct.Final_Tenure__c;
                }
                if (hlProduct.Sanctioned_ROI__c != null && hlProduct.PLR_Value__c != null) {
                    hlMargin = hlProduct.Sanctioned_ROI__c - hlProduct.PLR_Value__c;
                }
            }
        }
        List<Loan_Transaction__c> hlTransactions;
        
        if(isHlRelated){
            hlTransactions = [SELECT Id, Payment_Method__c, Favoring_Name__c, Account_Number__c, Bank__c, IFSC__c, Net_Amount__c FROM Loan_Transaction__c WHERE Loan_Application__c = :loanId AND RecordType.Name = 'Payment' AND Disbursement_Party__c != 'VAS' ORDER BY CreatedDate];
        }
        Map<Integer,String> bankIfscMap = new Map<Integer,String>();
        Map<Integer,String> accountMap = new Map<Integer,String>();
        
        if(isHlRelated && hlTransactions != null){
            Integer rowIndex = 1;
            for(Loan_Transaction__c txn : hlTransactions){
                String bankIfsc;
                if(txn.Bank__c != null && txn.IFSC__c != null){
                    bankIfsc = txn.Bank__c + ' - ' + txn.IFSC__c;
                }
                bankIfscMap.put(rowIndex, bankIfsc);
                accountMap.put(rowIndex, txn.Account_Number__c);
                rowIndex++;
            }
        }
        
        //RMName --Start
        List<OpportunityTeamMember> oppTeamMembers = [
                SELECT User.Email,User.Name,User.Employee_Id__c, User.Manager.Email,User.Manager.Name,User.Manager.Employee_Id__c,TeamMemberRole 
                FROM OpportunityTeamMember 
                WHERE OpportunityId = :loanAppId
            ];
        
        String rmname = '';
        if(!oppTeamMembers.isEmpty()){
            for (OpportunityTeamMember teamMember : oppTeamMembers) {
                if ((teamMember.TeamMemberRole == 'Sales Manager' || teamMember.TeamMemberRole == 'Relationship Manager') && String.isNotBlank(teamMember.User.Email)) {
                    rmname = String.isNotBlank(teamMember.User.Name) ? teamMember.User.Name : '';
                    break;
                }
            }
        }
        //RMName --Stop
        
        Boolean isMultiChildLoan = (isMultiProduct && childLoanId != null);
        
        Map<String, List<Applicant_Address__c>> addressMap = fetchApplicantAddresses(loanId);
        System.debug('addressMap => '+ addressMap);
        List<Applicant_Address__c> primaryIndv = addressMap.get('Primary_Individual');
        List<Applicant_Address__c> primaryIndvCurrentVeryHighPriority = addressMap.get('Primary_Individual_Very_High_Priority'); //added by Kunal Bisht for SFHL-1743
        List<Applicant_Address__c> primaryNonIndv = addressMap.get('Primary_NonIndividual');
        // List<Applicant_Address__c> coApplicantIndv = addressMap.get('Co_Individual');
        // List<Applicant_Address__c> coApplicantNonIndv = addressMap.get('Co_NonIndividual');
        List<Applicant_Address__c> coApplicantAddresses = addressMap.get('CoApp_Address');
        List<Applicant_Address__c> coApplicantAddressesVeryHighPriority = addressMap.get('CoApp_Address_Very_High_Priority'); //added by Kunal Bisht for SFHL-1743
        // Occupation address mapping
        List<Applicant_Address__c> primaryOccAddr = addressMap.get('Primary_SEP_SENP') != null
            ? addressMap.get('Primary_SEP_SENP')
            : addressMap.get('Primary_Salaried');
        
        // Move applicantList initialization here so it is available for all code below
        List<Application_Applicant__c> applicantList = [SELECT Applicant_Name__c, Applicant_Type__c, Customer_Profile__c, Employer_Name__c, Employer_Name__r.Employer_Name__c, Business_Entity_Name__c, Monthly_Salary__c, Other_Employer_Name__c,  Mother_s_First_Name__c, Mother_s_Middle_Name__c, Mother_s_Last_Name__c, Father_s_First_Name__c, Father_s_Middle_Name__c, Father_s_Last_Name__c, Id FROM Application_Applicant__c WHERE Loan_Application__c =: loanId ORDER BY CreatedDate ASC];
        
        List<Applicant_Address__c> coApplicantOccAddr = new List<Applicant_Address__c>();
        // Build a map from co-applicant Id to their occupation address
        Map<Id, Applicant_Address__c> coApplicantOccAddrMap = new Map<Id, Applicant_Address__c>();
        List<Applicant_Address__c> coSepSenpList = addressMap.containsKey('Co_SEP_SENP') && addressMap.get('Co_SEP_SENP') != null ? addressMap.get('Co_SEP_SENP') : new List<Applicant_Address__c>();
        List<Applicant_Address__c> coSalariedList = addressMap.containsKey('Co_Salaried') && addressMap.get('Co_Salaried') != null ? addressMap.get('Co_Salaried') : new List<Applicant_Address__c>();
        for (Applicant_Address__c addr : coSepSenpList) {
            if (addr.Applicant__c != null) {
                coApplicantOccAddrMap.put(addr.Applicant__c, addr);
            }
        }
        String hlPrimaryPermanentAddress;
        if (isHlRelated && primaryIndv != null && !primaryIndv.isEmpty()) {
            Applicant_Address__c addr = primaryIndv[0];
            if (addr.Address_Line_1__c != null) {
                hlPrimaryPermanentAddress = addr.Address_Line_1__c;
            }
        }
        for (Applicant_Address__c addr : coSalariedList) {
            if (addr.Applicant__c != null) {
                coApplicantOccAddrMap.put(addr.Applicant__c, addr);
            }
        }
        // Build a list of co-applicant Ids in the same order as applicantList
        List<Id> coApplicantIdsOrdered = new List<Id>();
        for (Application_Applicant__c app : applicantList) {
            if (app.Applicant_Type__c == 'Co Applicant') {
                coApplicantIdsOrdered.add(app.Id);
            }
        }
        
        List<Opportunity> opp = new List<Opportunity>();
        opp = [SELECT Final_Amount__c, Final_Rate_Of_Interest__c, Name, Loan_Purpose__c,Lead__c, Lead__r.Channel_code__c, Channel_code__c, Id FROM Opportunity WHERE Id =: loanId];
        Decimal loanAmount = opp[0].Final_Amount__c;
        Decimal finalRateOfInterest = opp[0].Final_Rate_Of_Interest__c;
        String loanPurpose = opp[0].Loan_Purpose__c;
        String channelCode = isHlRelated ? String.valueOf(opp[0].Lead__r?.Channel_code__c) : String.valueOf(opp[0].Channel_code__c);
        
        
        String loanAmountInWords =  Utility.getNumberTOWordConvertion(loanAmount);
        
        List<Income_Expense_Obligation__c> incomeObligationList = new List<Income_Expense_Obligation__c>();
        incomeObligationList = [SELECT  Secured_Unsecured__c ,  Loan_Amount__c , Imputed_EMI__c , Current_Balance__c,  Balance_Tenure__c FROM Income_Expense_Obligation__c WHERE Loan_Application__c =: loanId AND Secured_Unsecured__c = 'Secured'  AND Type__c ='Live Loan' ORDER BY Current_Balance__c DESC LIMIT 5];
        
        List<Product2> productList = new List<Product2>();
        productList = [SELECT RecordType.Name, Loan_Facility__c, Product__r.Name, Id, Sanctioned_Loan_Amount__c FROM Product2 WHERE RecordType.Name = 'Sub Product' AND Product__r.Product_Type__c = 'Parent' AND Loan_Application__c =: loanId]; //change by Surabhi for SFHL-1883
        
        String prodType = '';
        String sanctionedAmount = ''; //added by Surabhi for SFHL-1883
        if (!productList.isEmpty()) {
            prodType = productList[0].Product__r.Name;
            sanctionedAmount = String.valueOf(productList[0].Sanctioned_Loan_Amount__c); //added by Surabhi for SFHL-1883
        }
        
        
        List<String> applicantNames = new List<String>();
        List<String> sellerBuilderApplicantNames = new List<String>();
        List<String> employerBusinessName = new List<String>();
        List<String> mothersNames = new List<String>();
        List<String> fathersNames = new List<String>();
        
        String TotalIncomeOfPrimaryApp = '';
        // Separate primary and co-applicants
        Application_Applicant__c primaryApplicant;
        List<Application_Applicant__c> coApplicants = new List<Application_Applicant__c>();
        for (Application_Applicant__c app : applicantList) {
            if (app.Applicant_Type__c == 'Primary Applicant') {
                primaryApplicant = app;
            } else if (app.Applicant_Type__c == 'Co Applicant') {
                coApplicants.add(app);
            }
        }
        
        // Add primary applicant's mother/father name first
        if (primaryApplicant != null) {
            if (primaryApplicant.Monthly_Salary__c != null) {
                Decimal monthlySalary = primaryApplicant.Monthly_Salary__c;
                Integer annualIncome = (Integer)(monthlySalary * 12);
                TotalIncomeOfPrimaryApp = String.valueOf(annualIncome);
            }
            applicantNames.add(primaryApplicant.Applicant_Name__c);
            List<String> motherName = joinNameParts(new List<String>{
                primaryApplicant.Mother_s_First_Name__c,
                primaryApplicant.Mother_s_Middle_Name__c,
                primaryApplicant.Mother_s_Last_Name__c
            });
            List<String> fatherName = joinNameParts(new List<String>{
                primaryApplicant.Father_s_First_Name__c,
                primaryApplicant.Father_s_Middle_Name__c,
                primaryApplicant.Father_s_Last_Name__c
            });
            String motherFullName = String.join(motherName, ' ');
            String fatherFullName = String.join(fatherName, ' ');
            mothersNames.add(motherFullName);
            fathersNames.add(fatherFullName);
            System.debug('Primary Applicant: ' + primaryApplicant.Applicant_Name__c + ' | Mother: ' + motherFullName + ' | Father: ' + fatherFullName);
            // Employer name logic for primary
            String empName = '';
            if (primaryApplicant.Customer_Profile__c != null && primaryApplicant.Customer_Profile__c.contains('Salaried') && primaryApplicant.Employer_Name__r != null && primaryApplicant.Employer_Name__r.Employer_Name__c != null) {
                empName = primaryApplicant.Employer_Name__r.Employer_Name__c;
                if (empName == 'Others' && primaryApplicant.Business_Entity_Name__c != null && !isHlRelated) {
                    empName = primaryApplicant.Business_Entity_Name__c;
                }
                if (empName == 'Others' && primaryApplicant.Other_Employer_Name__c != null && isHlRelated) {
                    empName = primaryApplicant.Other_Employer_Name__c;
                }
            }
            if (primaryApplicant.Customer_Profile__c != null && (primaryApplicant.Customer_Profile__c == 'SEP' || primaryApplicant.Customer_Profile__c == 'SENP') && primaryApplicant.Business_Entity_Name__c != null ) {
                empName = primaryApplicant.Business_Entity_Name__c;
            }
            employerBusinessName.clear();
            employerBusinessName.add(empName);
            System.debug('Primary Applicant: ' + primaryApplicant.Applicant_Name__c + ' | Employer: ' + empName);
        }
        
        // Add co-applicants' names and parent names
        for (Application_Applicant__c app : coApplicants) {
            applicantNames.add(app.Applicant_Name__c);
            List<String> motherName = joinNameParts(new List<String>{
                app.Mother_s_First_Name__c,
                app.Mother_s_Middle_Name__c,
                app.Mother_s_Last_Name__c
            });
            List<String> fatherName = joinNameParts(new List<String>{
                app.Father_s_First_Name__c,
                app.Father_s_Middle_Name__c,
                app.Father_s_Last_Name__c
            });
            String motherFullName = String.join(motherName, ' ');
            String fatherFullName = String.join(fatherName, ' ');
            mothersNames.add(motherFullName);
            fathersNames.add(fatherFullName);
            // Employer name logic for co-applicants
            String empName = '';
            if (app.Customer_Profile__c != null && app.Customer_Profile__c.contains('Salaried') && app.Employer_Name__r != null && app.Employer_Name__r.Employer_Name__c != null) {
                empName = app.Employer_Name__r.Employer_Name__c;
                if (empName == 'Others' && app.Business_Entity_Name__c != null && !isHlRelated) {
                    empName = app.Business_Entity_Name__c;
                }
                if (empName == 'Others' && app.Other_Employer_Name__c != null && isHlRelated) {
                    empName = app.Other_Employer_Name__c;
                }
            }
            if (app.Customer_Profile__c != null && (app.Customer_Profile__c == 'SEP' || app.Customer_Profile__c == 'SENP') && app.Business_Entity_Name__c != null ) {
                empName = app.Business_Entity_Name__c;
            }
            employerBusinessName.add(empName);
        }
        
        for (Application_Applicant__c app : applicantList) {
            if (app.Applicant_Type__c == 'Seller' || app.Applicant_Type__c == 'Builder') {
                sellerBuilderApplicantNames.add(app.Applicant_Name__c);
            }
        }
        system.debug('applicantNames: '+applicantNames);
        System.debug('Final employerBusinessName list (for AF91/AF91_1...): ' + employerBusinessName);
        System.debug('Final mothersNames list (for AF21/AF21_B...): ' + mothersNames);
        System.debug('Final fathersNames list (for AF22/AF22_B...): ' + fathersNames);
        
        List<String> reversedNames = new List<String>();
        
        for (Integer i = applicantNames.size() - 1; i >= 0; i--) {
            reversedNames.add(applicantNames[i]);
        }
        
        String applicantNamesString = '';
        applicantNamesString = String.join(applicantNames, ', '); //reversedNames changed to applicantNames by Kunal Bisht for SFHL-1743
        
        String sellerBuilderApplicantNamesString = '';
        sellerBuilderApplicantNamesString = String.join(sellerBuilderApplicantNames, ', ');
        
        system.debug('applicantNamesString  '+applicantNamesString);
        system.debug('sellerBuilderApplicantNames   '+sellerBuilderApplicantNames);
        
        List<Loan_Transaction__c> loanTxnOCR = new List<Loan_Transaction__c>();
        loanTxnOCR = [SELECT Loan_Application__r.Name,  OCR_Receivable__c, Total_OCR_Paid__c,  Id FROM Loan_Transaction__c WHERE RecordType.Name = 'OCR Capture Transaction' AND OCR_Receivable__c != null AND Total_OCR_Paid__c != null AND Loan_Application__c =: loanId];
        Decimal OCRpending = 0;
        Decimal totalOCRpaid = 0;
        String totalOCRpaidInWords = '';
        
        if (!loanTxnOCR.isEmpty()) {
            Loan_Transaction__c txn = loanTxnOCR[0];
            totalOCRpaid = txn.Total_OCR_Paid__c != null ? txn.Total_OCR_Paid__c : 0;
            
            if (txn.OCR_Receivable__c != null && txn.Total_OCR_Paid__c != null) {
                OCRpending = txn.OCR_Receivable__c - txn.Total_OCR_Paid__c;
            }
            
            if (totalOCRpaid != 0) {
                totalOCRpaidInWords = Utility.getNumberTOWordConvertion(totalOCRpaid);
            }
        }
        
        List<Document_Details__c> docDetailsList = [SELECT Name, CreatedDate, Content_Document_Id__c,  Id FROM Document_Details__c WHERE Loan_Application__c =: loanId AND Name = 'Sanction Letter' ORDER BY CreatedDate DESC LIMIT 1];
        Datetime sanctionLetterDate = !docDetailsList.isEmpty() ? docDetailsList[0].CreatedDate : null;
        
        List<Document_Details__c> covenantDocDetailsList = [SELECT Target_Date__c, Status__c, Document_Date_of_Receipt__c, Nature_of_Document__c, Id FROM Document_Details__c WHERE Loan_Application__c =: loanId AND  Covenant_Master__c != null AND Document_Type__c IN ('Received - Maker', 'Received - Checker') /*AND Covenant_Master__r.category__c = 'LEGXT'*/ ORDER BY CreatedDate DESC /*LIMIT 1*/]; //change by Kunal Bisht for SFHL-1743
        Date covenantTimelineDate; // !docDetailsList.isEmpty() ? docDetailsList[0].CreatedDate : null;
        
        if (!covenantDocDetailsList.isEmpty()) {
            Document_Details__c doc = covenantDocDetailsList[0];
            covenantTimelineDate = (doc.Status__c == 'Pending') ? doc.Target_Date__c : ((doc.Status__c == 'Uploaded') ? doc.Document_Date_of_Receipt__c : null);
        }
        
        List<Loan_Transaction__c> loanTxnList = new List<Loan_Transaction__c>();
        //change by Kunal Bisht for SFHL-1743 - start
        List<Opportunity> applicationLst = new List<Opportunity>();
        Boolean isOCRAllowed = false;
        String loanAppProduct;
        Decimal totalLoanAmount;
        Decimal totalFeeToBeDeducted;
        Decimal totalCostOfProperty;
        Decimal paidAmount;
        applicationLst = [SELECT Id, Allow_OCR__c, Product__c FROM Opportunity where Id =: loanId];
        
        for (Opportunity app : applicationLst) {
            loanAppProduct = app.Product__c;
            if (app.Allow_OCR__c == true) {
                isOCRAllowed = true;
                break;
            }
        }
        
        List<Charges_Insurance__c> chargeInsurances = new List<Charges_Insurance__c>();
        List<Loan_Transaction__c> allLoanTxns = new List<Loan_Transaction__c>();
        List<Loan_Transaction__c> loanTxnPaymentList = new List<Loan_Transaction__c>();
        List<Loan_Transaction__c> lstOCRSteps = new List<Loan_Transaction__c>();
        Decimal totalPaymentAmount = 0;
        String loanFacility = '';
        String loanFacilityFL = ''; //added by Kunal Bisht for SFHL-1743 for FL
        Integer sNoCountForDetailsOfModeOfDisbursement = 0;
        Integer sNoCountForOCRSteps = 0;
        //change by Kunal Bisht for SFHL-1743 - end
        Date loanStartDate;
        Integer loanStartDay;
        Integer loanStartMonth;
        Integer loanStartYear;
        String loanStartYearLastTwoDigits;
        Decimal baseRate = 0;
        Decimal diffFinalROI = 0;
        //change by Kunal Bisht for SFHL-1743 - start
        chargeInsurances = [SELECT Product__r.Name, Total_Fee_to_be_deducted__c, Name, Product_Name__c, RecordType.Name FROM Charges_Insurance__c where Loan_Application__c =: loanId ];
        allLoanTxns = [SELECT Loan_Application__r.Name,Receipt_Date__c, Margin__c,PLR_Code__c, Net_Amount__c, PLR_Value__c, Loan_Start_Date__c, RecordType.Name, Disbursement_Party__c,
                        QDP_Status__c, Id, Total_Loan_Amount__c, Total_Demand__c, Step_Sequence__c, Customer_Contribution__c, Financer_Contribution__c, isParent__c, OCR_Definition__c, Paid_Amount__c
                       FROM Loan_Transaction__c WHERE Loan_Application__c =: loanId ORDER BY Step_Sequence__c ASC];
        
        for(Loan_Transaction__c loanTxn: allLoanTxns){
            if(loanTxn.RecordType.Name == 'Transaction Details'){
                loanTxnList.add(loanTxn);
                if(totalLoanAmount == null){
                    totalLoanAmount = loanTxn.Total_Loan_Amount__c;
                }
            }
            if(loanTxn.RecordType.Name == 'Payment' && loanTxn.Disbursement_Party__c != 'VAS'){
                if(loanTxn.QDP_Status__c == null || loanTxn.QDP_Status__c != 'Rejected'){
                    loanTxnPaymentList.add(loanTxn);
                }
                sNoCountForDetailsOfModeOfDisbursement++;
            }
            if(loanTxn.RecordType.name == 'OCR'){
                totalCostOfProperty = loanTxn.Total_Demand__c;
            }
            if(loanTxn.RecordType.name == 'OCR Capture Transaction' && loanTxn.OCR_Definition__c != null && loanTxn.isParent__c == false){
                if(loanTxn.Paid_Amount__c != null && loanTxn.Receipt_Date__c != null){
                    if(paidAmount == null){
                        paidAmount = 0;
                    }
                    if(paidAmount != null){
                        paidAmount += loanTxn.Paid_Amount__c;
                    }   
                }
            }
            if(loanTxn.isParent__c == false && loanTxn.RecordType.Name == 'OCR Steps' && loanTxn.OCR_Definition__c != null){
                sNoCountForOCRSteps++;
                lstOCRSteps.add(loanTxn);
            }
        }
        
        for(Charges_Insurance__c chargeObj: chargeInsurances){
            if(chargeObj.Name == 'Total Charges' && chargeObj.Product_Name__c == loanAppProduct){    
                totalFeeToBeDeducted = chargeObj.Total_Fee_to_be_deducted__c;
            }
        }
        
        for(Product2 prodObj : productList){
            if(prodObj.Loan_Facility__c != null && prodObj.Loan_Facility__c != '' && prodObj.product__r.name != 'Flexi Loan'){
                loanFacility = prodObj.Loan_Facility__c;
                break;
            }else{//else block added by Kunal Bisht for SFHL-1743 for FL
                loanFacilityFL = prodObj.Loan_Facility__c;
            }
        }
        
        Decimal marginForLoanAgreement;
        if(!loanTxnList.isEmpty() && loanTxnList[0].Margin__c != null && loanTxnList[0].PLR_Value__c != null){
            marginForLoanAgreement = (loanTxnList[0].Margin__c - loanTxnList[0].PLR_Value__c).setScale(2);
        }
        //change by Kunal Bisht for SFHL-1743 - end
        if (!loanTxnList.isEmpty() && loanTxnList[0].Loan_Start_Date__c != null) {
            loanStartDate = loanTxnList[0].Loan_Start_Date__c;
            loanStartDay = loanStartDate.day();
            loanStartMonth = loanStartDate.month();
            loanStartYear = loanStartDate.year();
            loanStartYearLastTwoDigits = String.valueOf(loanStartYear).substring(2);
            system.debug('loanStartDay  '+loanStartDay+' loanStartMonth '+loanStartMonth+ ' loanStartYear  '+loanStartYear+'  loanStartYearLastTwoDigits '+loanStartYearLastTwoDigits);
        }
        
        if (!loanTxnList.isEmpty() && loanTxnList[0].PLR_Value__c != null) {
            baseRate = loanTxnList[0].PLR_Value__c;
            if (finalRateOfInterest != null) {
                diffFinalROI = baseRate - finalRateOfInterest;
            }
        }
        
        String sanctionDetails = slan +', '+ String.valueOf(loanStartDate);
        
        Map<String, List<String>> fieldMap = getFieldMapping();
        List<String> specialFields = getSpecialFields();
        List<String> primaryAddressFields = getPrimaryAddressFields();
        List<String> incomeObligationFields = getIncomeObligationFields();
        List<String> ownContributionFields = getOwnContributionFields();
        Map<String, Integer> namesKeywordMapping = getNamesKeywordMapping();
        // Query once outside the conditions
        List<Collateral_Owner__c> owners = [
        SELECT Application_Applicant__r.Applicant_Name__c, Application_Applicant__r.Gender__c
        FROM Collateral_Owner__c
        WHERE Application_Applicant__r.Loan_Application__c = :loanId
        ];
        List<Collateral_Owner__c> collateralOwner = new List<Collateral_Owner__c>();
        collateralOwner = [SELECT  Application_Applicant__r.Name, Application_Applicant__r.Applicant_Type__c,  Id FROM Collateral_Owner__c WHERE /*Application_Applicant__r.Applicant_Type__c = 'Primary Applicant' AND*/ Application_Applicant__r.Loan_Application__c =: loanId /*LIMIT 1*/]; //change by Kunal Bisht for SFHL-1743
        String collateralOwnerName = '';
        List<Document_Details__c> coAppPhotos = [
        SELECT Name, Content_Document_Id__c, Applicant__r.Applicant_Type__c, Content_Version_Id__c, Id
        FROM Document_Details__c
        WHERE Loan_Application__c = :loanId
        AND Name = 'Photograph'
        AND Applicant__r.Applicant_Type__c = 'Co Applicant'
        AND Consider_for_Loan_Application__c = true
        ORDER BY Applicant__r.CreatedDate ASC];
        
        List<String> coAppPhotoBase64List = new List<String>();
        for (Document_Details__c photo : coAppPhotos) {
            if (photo.Content_Document_Id__c != null) {
                List<ContentVersion> photoCV = [
                SELECT VersionData, Id FROM ContentVersion WHERE ContentDocumentId = :photo.Content_Document_Id__c
                ];
                if (!photoCV.isEmpty()) {
                    coAppPhotoBase64List.add(EncodingUtil.base64Encode(photoCV[0].VersionData));
                }
            }
        }
        //change by Kunal Bisht for SFHL-1743 - start
        /*
        if (!collateralOwner.isEmpty() && collateralOwner[0].Application_Applicant__r.Name != null) {
            collateralOwnerName = collateralOwner[0].Application_Applicant__r.Name;
        }*/
        
        if(collateralOwner != null && collateralOwner.size()>0){
            for(Integer i = 0; i < collateralOwner.size(); i++){
                if(i<collateralOwner.size()-1){
                    collateralOwnerName += collateralOwner[i].Application_Applicant__r.Name +', ';
                }else{
                    collateralOwnerName += collateralOwner[i].Application_Applicant__r.Name;
                }
            }
            //change by Kunal Bisht for SFHL-1743 - end
        }
        
        // Date todayDate = Date.today();
        // // String loanAgreementDate = Date.today().format(); // 21-11-2025
        // String loanAgreementDate = todayDate.toStartOfDay().format('dd/MM/yyyy');
        
        Date todayDate = Date.today();
        Datetime dt = Datetime.newInstance(todayDate.year(), todayDate.month(), todayDate.day());
        String loanAgreementDate = dt.format('dd/MM/yyyy');
        
        List<Application_Collateral__c> appCollateralList = new List<Application_Collateral__c>();
        Boolean isCollateralUnderConstruction = false;
        appCollateralList = [SELECT Collateral__r.Construction_Stage__c,  Id FROM Application_Collateral__c WHERE HL_Loan_Application__c =: loanId];
        
        for (Application_Collateral__c appCol : appCollateralList) {
            if (appCol.Collateral__r != null && appCol.Collateral__r.Construction_Stage__c == 'UNDER CONSTRUCTION') {
                isCollateralUnderConstruction = true;
                break;
            }
        }
        
        /*---------------------------------- Mapping starts-----------------------------*/
        
        // Extract titles from content versions
        Set<String> templateDocNameSet = new Set<String>();
        
        // Final list of matching CMDT records
        List<Document_Template_New__mdt> matchedTemplateRecords = new List<Document_Template_New__mdt>();
        
        for (ContentVersion cv : contVersion) {
            if (cv.Title != null) {
                templateDocNameSet.add(cv.Title.trim());
            }
        }
        
        for (Document_Template_New__mdt tempMD : documentTemplateKeywords) {
            if (templateDocNameSet.contains(tempMD.Template_Name__c)) {
                matchedTemplateRecords.add(tempMD);
            }
        }
        
        for(Document_Template_New__mdt tempMD : matchedTemplateRecords){
            if(getTemplateTometadata.containsKey(tempMD.Template_Name__c)){
                getTemplateTometadata.get(tempMD.Template_Name__c).add(tempMD);
            }else{
                getTemplateTometadata.put(tempMD.Template_Name__c , new List<Document_Template_New__mdt>{tempMD});
            }
            
            if(tempMD.Object_Name__c != null){
                if(getObjRecords.containsKey(tempMD.Object_Name__c + '+' + (Integer)tempMD.Criteria_Number__c)){
                    getObjRecords.get(tempMD.Object_Name__c + '+' + (Integer)tempMD.Criteria_Number__c).add(tempMD);
                }else{
                    getObjRecords.put(tempMD.Object_Name__c + '+' + (Integer)tempMD.Criteria_Number__c , new List<Document_Template_New__mdt>{tempMD});
                }
            }
        }  // example - {'BLAB' : list of template metadata}
        
        Map<string, List<sObject>> sObjectMap = new Map<string, List<sObject>>();
        for(string objseqkey : getObjRecords.keySet()){
            System.debug('objseqkey => '+objseqkey);
            if(!sObjectMap.containsKey(objseqkey)){
                List<sObject> objRec= getSObjectRecords(objseqkey.split('\\+')[0], loanId, childLoanId, getObjRecords.get(objseqkey), Integer.ValueOf(objseqkey.split('\\+')[1]));
                sObjectMap.put(objseqkey, objRec);
            }
        } //{opportunity+1 , list of records}
        // System.debug('sObjectMap 78  : '+sObjectMap.get('Opportunity+1.0'));
        for(ContentVersion cv : contVersion){
            DocGenPreviewJSONCreator.digiUploadDocuments uploadDoc  =   new DocGenPreviewJSONCreator.digiUploadDocuments();
            List<DocGenPreviewJSONCreator.fieldData> fdList         =   new List<DocGenPreviewJSONCreator.fieldData>();
            if(contdocIdToDocType.get(cv.ContentDocumentId) != 'Template Document'){
                uploadDoc.fileId = cv.Id;
                uploadDoc.fileName = (cv.Title.contains('.')) ? cv.Title :cv.Title + '.' + cv.FileType.toLowerCase();
                Integer sequenceInteger = Integer.valueOf(contdocIdToSequence.get(cv.ContentDocumentId));
                String sequenceString = String.valueOf(sequenceInteger);
                uploadDoc.sequence = sequenceString;
                
                //uploadDoc.fileName = cv.Title;
            }
            system.debug('line 96 --->  '+contdocIdToDocType.get(cv.ContentDocumentId));
            system.debug('line 97 --->  '+cv.Title);
            system.debug('line 98 --->  '+getTemplateTometadata);
            String docPrefix = cv.Title.split('_')[0];
            Map<String, String> prefixMap = getPrefixMap();
            String cvTitle = prefixMap.containsKey(docPrefix) ? prefixMap.get(docPrefix) : cv.Title;
            system.debug('line 104 --->  '+cvTitle);
            if(contdocIdToDocType.get(cv.ContentDocumentId) == 'Template Document'){
                if(getTemplateTometadata.containsKey(cv.Title)){
                    // if(getTemplateTometadata.containsKey(cvTitle)){
                        uploadDoc.fileId    = cv.Id;
                        // uploadDoc.fileId    = '068Bl000005SZuPIAW';
                        uploadDoc.fileName  = (cv.Title.contains('.')) ? cv.Title :cv.Title + '.' + cv.FileType.toLowerCase();  //commented out 15-Aug
                        // uploadDoc.fileName = cv.Title.contains('.') ? cv.Title.substring(0, cv.Title.indexOf('.')) : cv.Title;
                        
                        Integer sequenceInteger = Integer.valueOf(contdocIdToSequence.get(cv.ContentDocumentId));
                        String sequenceString = String.valueOf(sequenceInteger);
                        uploadDoc.sequence = sequenceString;
                        //uploadDoc.fileName = cv.Title;
                        // for(Document_Template_New__mdt  docmdt : getTemplateTometadata.get(cv.Title)){
                            for(Document_Template_New__mdt  docmdt : getTemplateTometadata.get(cvTitle)){
                                DocGenPreviewJSONCreator.fieldData fd   =   new DocGenPreviewJSONCreator.fieldData();
                                fd.sfieldKeyword        =   docmdt.label;
                                fd.sfieldType           =   docmdt.Field_Type__c;
                                String objectType       =   docmdt.Object_Name__c != null ? docmdt.Object_Name__c : null;
                                SObject sObj            =   (objectType != null && objectType != 'NA')? (SObject) Type.forName('Schema.' + objectType).newInstance() : null;
                                Integer sIndex          =   (string.ValueOf(docmdt.Index__c) != null && string.ValueOf(docmdt.Index__c) != '') ? (Integer)docmdt.Index__c : 0;
                                fd.sfieldValue          =   'NA';
                                Integer criteriaNumber  =   (Integer)docmdt.Criteria_Number__c;
                                fd.sfieldValue          =   sObj == null && docmdt.Default_Value__c != null? docmdt.Default_Value__c : 'NA';
                                string slogic           =   docmdt.Logical_Operator__c;
                                string slogicalvalue    =   '';
                                if(sObj != null){
                                    System.debug('118 '+objectType + '+' + String.valueOf(criteriaNumber));
                                    List<sObject> objRec1   =   sObjectMap.get(objectType + '+' + String.valueOf(criteriaNumber));
                                    System.debug('objRec1 120'+objRec1);
                                    if(objRec1 != null && objRec1.size() > sIndex){
                                        System.debug('objRec1 123: '+objRec1);
                                        
                                        if(docmdt.Object_Field_Name__c != null && docmdt.Object_Field_Name__c.contains('.')){
                                            slogicalvalue   =  (slogic != null && slogic != '') ?  getLogicalValue(slogicalvalue, objRec1, slogic, docmdt) : null;
                                            fd.sfieldValue  =  (slogicalvalue != null && slogicalvalue != '') ? slogicalvalue :  string.ValueOf(getValueFromRelation(objRec1[sIndex], docmdt.Object_Field_Name__c));
                                        }
                                        else{
                                            slogicalvalue   =  (slogic != null && slogic != '') ?  getLogicalValue(slogicalvalue, objRec1, slogic, docmdt) : null;
                                            fd.sfieldValue  =  (slogicalvalue != null && slogicalvalue != '') ? slogicalvalue :   string.ValueOf(objRec1[sIndex].get(docmdt.Object_Field_Name__c));
                                        }
                                    }
                                    fd.sfieldValue  =   fd.sfieldValue == null ? 'NA' : fd.sfieldValue;
                                }
                                System.debug('Before HL override LAHLCL12 fd.sfieldValue => ' + fd.sfieldValue);
                                //change by Kunal Bisht for SFHL-1743 - start
                                if(fd.sfieldKeyword == 'LAFLCL122' || fd.sfieldKeyword == 'LAFLCL124'){
                                    if(fd.sfieldValue == 'true'){
                                        fd.sfieldValue = 'Yes';
                                    }
                                    if(fd.sfieldValue == 'false'){
                                        fd.sfieldValue = 'No';
                                    }
                                }
                                if (fd.sfieldKeyword == 'LAHLCL23') {
                                    fd.sfieldValue = (marginForLoanAgreement != null) ? String.valueOf(marginForLoanAgreement) : '';
                                }
                                
                                if(fd.sfieldKeyword == 'LAHLCL54' || fd.sfieldKeyword == 'LAHLCL98_39'){
                                    for(Loan_Transaction__c loanTxn: loanTxnPaymentList){
                                        if(loanTxn.Net_Amount__c != null ){
                                            totalPaymentAmount += loanTxn.Net_Amount__c;
                                        }
                                        else{
                                            totalPaymentAmount = 0;
                                        }
                                    }
                                    fd.sfieldValue = String.valueOf(totalPaymentAmount);
                                }
                                /*
                                if(fd.sfieldKeyword == 'LAHLCL57' || fd.sfieldKeyword == 'LAHLCL57_1' || fd.sfieldKeyword == 'LAHLCL57_2' || fd.sfieldKeyword == 'LAHLCL57_3'
                                    || fd.sfieldKeyword == 'LAHLCL58' || fd.sfieldKeyword == 'LAHLCL58_1' || fd.sfieldKeyword == 'LAHLCL58_2' || fd.sfieldKeyword == 'LAHLCL58_3'
                                    || fd.sfieldKeyword == 'LAHLCL59' || fd.sfieldKeyword == 'LAHLCL59_1' || fd.sfieldKeyword == 'LAHLCL59_2' || fd.sfieldKeyword == 'LAHLCL59_3'
                                ){
                                    for(Charges_Insurance__c chargeInsuranceObj: chargeInsurances){
                                        if(chargeInsuranceObj.Product__r.Name == 'Flexi Loan' && chargeInsuranceObj.RecordType.Name == 'Insurance'){
                                            fd.sfieldValue = '';
                                        }
                                    }
                                }*/
                                if(fd.sfieldKeyword == 'LAHLCL97' || fd.sfieldKeyword == 'LAHLCL91'){
                                    if(totalLoanAmount != null && totalFeeToBeDeducted != null){
                                        fd.sfieldValue = String.valueOf(totalLoanAmount - totalFeeToBeDeducted);
                                    }
                                }
                                if(fd.sfieldKeyword == 'LAHLCL98' || fd.sfieldKeyword == 'LAHLCL92'){
                                    if(totalCostOfProperty != null && totalLoanAmount != null && totalFeeToBeDeducted != null){
                                        fd.sfieldValue = String.valueOf(totalCostOfProperty - (totalLoanAmount - totalFeeToBeDeducted));
                                    }
                                }
                                if(fd.sfieldKeyword == 'LAHLCL48_1' || fd.sfieldKeyword == 'LAHLCL48_2' || fd.sfieldKeyword == 'LAHLCL48_3'
                                || fd.sfieldKeyword == 'LAHLCL48_4' || fd.sfieldKeyword == 'LAHLCL48_5'){
                                    for (Integer i = 1; i <= sNoCountForDetailsOfModeOfDisbursement; i++){
                                        String expectedKey = 'LAHLCL48_' + i;
                                        if (fd.sfieldKeyword == expectedKey){
                                            fd.sfieldValue = String.valueOf(i);
                                            break;
                                        }
                                    }
                                }
                                if(fd.sfieldKeyword == 'LAHLCL98_1' || fd.sfieldKeyword == 'LAHLCL98_2' || fd.sfieldKeyword == 'LAHLCL98_3' || fd.sfieldKeyword == 'LAHLCL98_4'
                                    || fd.sfieldKeyword == 'LAHLCL98_5' || fd.sfieldKeyword == 'LAHLCL98_6' || fd.sfieldKeyword == 'LAHLCL98_7' || fd.sfieldKeyword == 'LAHLCL98_8'
                                    || fd.sfieldKeyword == 'LAHLCL98_9' || fd.sfieldKeyword == 'LAHLCL98_10' || fd.sfieldKeyword == 'LAHLCL98_11' || fd.sfieldKeyword == 'LAHLCL98_12'
                                    || fd.sfieldKeyword == 'LAHLCL98_13' || fd.sfieldKeyword == 'LAHLCL98_14' || fd.sfieldKeyword == 'LAHLCL98_15' || fd.sfieldKeyword == 'LAHLCL98_16'
                                || fd.sfieldKeyword == 'LAHLCL98_17' || fd.sfieldKeyword == 'LAHLCL98_18' || fd.sfieldKeyword == 'LAHLCL98_19'){
                                    for (Integer i = 1; i <= sNoCountForOCRSteps; i++){
                                        String expectedKey = 'LAHLCL98_' + i;
                                        if (fd.sfieldKeyword == expectedKey){
                                            fd.sfieldValue = String.valueOf(i);
                                            break;
                                        }
                                    }
                                }
                                
                                if(fd.sfieldKeyword == 'LAHLCL98_20' || fd.sfieldKeyword == 'LAHLCL98_21' || fd.sfieldKeyword == 'LAHLCL98_22' || fd.sfieldKeyword == 'LAHLCL98_23'
                                    || fd.sfieldKeyword == 'LAHLCL98_24' || fd.sfieldKeyword == 'LAHLCL98_25' || fd.sfieldKeyword == 'LAHLCL98_26' || fd.sfieldKeyword == 'LAHLCL98_27'
                                    || fd.sfieldKeyword == 'LAHLCL98_28' || fd.sfieldKeyword == 'LAHLCL98_29' || fd.sfieldKeyword == 'LAHLCL98_30' || fd.sfieldKeyword == 'LAHLCL98_31'
                                    || fd.sfieldKeyword == 'LAHLCL98_32' || fd.sfieldKeyword == 'LAHLCL98_33' || fd.sfieldKeyword == 'LAHLCL98_34' || fd.sfieldKeyword == 'LAHLCL98_35'
                                || fd.sfieldKeyword == 'LAHLCL98_36' || fd.sfieldKeyword == 'LAHLCL98_37' || fd.sfieldKeyword == 'LAHLCL98_38'){
                                    
                                    Integer keyIndex = Integer.valueOf(fd.sfieldKeyword.split('_')[1]);
                                    Integer listIndex = keyIndex - 20;
                                    
                                    if (listIndex >= 0 && listIndex < lstOCRSteps.size()) {
                                        Loan_Transaction__c step = lstOCRSteps[listIndex];
                                        
                                        Decimal financer = step.Financer_Contribution__c;
                                        Decimal customer = step.Customer_Contribution__c;
                                        
                                        if (financer != null) {
                                            fd.sfieldValue = String.valueOf(financer);
                                        } else if (customer != null) {
                                            fd.sfieldValue = String.valueOf(customer);
                                        }
                                    }
                                }
                                
                                if(fd.sfieldKeyword == 'LAHLCL24' && fd.sfieldValue != null && fd.sfieldValue != '' && fd.sfieldValue != 'NA'){
                                    Decimal allocatedAmount = Decimal.valueOf(fd.sfieldValue);
                                    Decimal procFee = (allocatedAmount * 1.18).setScale(0);
                                    fd.sfieldValue = string.valueOf(procFee);
                                }

                                if(fd.sfieldKeyword == 'LAHLCL56_2' && fd.sfieldValue != null && fd.sfieldValue != '' && fd.sfieldValue != 'NA'){
                                    Decimal adjustedLoginFee = Decimal.valueOf(fd.sfieldValue);
                                    Decimal pfReceived = (adjustedLoginFee * 1.18).setScale(2);
                                    fd.sfieldValue = string.valueOf(pfReceived);
                                }
                                if(fd.sfieldKeyword == 'LAHLCL93'){
                                    fd.sfieldValue = string.valueOf(paidAmount);
                                }
                                //change by Kunal Bisht for SFHL-1743 - end
                                if (isHlRelated) {
                                    if (fd.sfieldKeyword == 'LAHLCL12' ||fd.sfieldKeyword == 'LAHLCL68' ||fd.sfieldKeyword == 'LAHLCL77') {
                                        fd.sfieldValue = (hlFinalTenure != null) ? String.valueOf(hlFinalTenure) : '';
                                    }
                                    /* commented by Kunal Bisht for SFHL-1743
                                    if (fd.sfieldKeyword == 'LAHLCL23') {
                                        fd.sfieldValue = (hlMargin != null) ? String.valueOf(hlMargin) : '';
                                    }*/
                                    //change by Kunal Bisht for SFHL-1743 - start
                                    if (fd.sfieldKeyword == 'LAHLCL29' && hlPrimaryPermanentAddress != null) {
                                        fd.sfieldValue = hlPrimaryPermanentAddress;
                                        //change by Kunal Bisht for SFHL-1743 - end
                                    }
                                    if(fd.sfieldKeyword.startsWith('LAHLCL51_')){
                                        
                                        Integer rowIndex = Integer.valueOf(fd.sfieldKeyword.split('_')[1]);
                                        
                                        if(bankIfscMap.containsKey(rowIndex)){
                                            fd.sfieldValue = bankIfscMap.get(rowIndex);
                                        }
                                    }
                                    if(fd.sfieldKeyword.startsWith('LAHLCL52_')){
                                        Integer rowIndex = Integer.valueOf(fd.sfieldKeyword.split('_')[1]);
                                        if(accountMap.containsKey(rowIndex)){
                                            fd.sfieldValue = accountMap.get(rowIndex);
                                        }
                                    }
                                }
                                
                                System.debug('After HL override ' + fd.sfieldKeyword + ' value => ' + fd.sfieldValue);
                                
                                if (fd.sfieldKeyword == 'AF1' || fd.sfieldKeyword == 'AF189' || fd.sfieldKeyword == 'AF171_2' || fd.sfieldKeyword == 'AF170' || fd.sfieldKeyword == 'AF24' || fd.sfieldKeyword == 'AF24_1' || fd.sfieldKeyword == 'AF24_2' || fd.sfieldKeyword == 'AF24_3' || fd.sfieldKeyword == 'AF24_4' || fd.sfieldKeyword == 'AF24_5' ||
                                    fd.sfieldKeyword == 'AF64' || fd.sfieldKeyword == 'AF64_1' || fd.sfieldKeyword == 'AF64_8' || fd.sfieldKeyword == 'AF64_9' || fd.sfieldKeyword == 'AF64_4' || fd.sfieldKeyword == 'AF64_5' ||
                                    fd.sfieldKeyword == 'AF70' || fd.sfieldKeyword == 'AF70_1' || fd.sfieldKeyword == 'AF70_2' || fd.sfieldKeyword == 'AF70_3' || fd.sfieldKeyword == 'AF70_4' || fd.sfieldKeyword == 'AF70_5' ||
                                    fd.sfieldKeyword == 'AFL1' || fd.sfieldKeyword == 'AFL18' || fd.sfieldKeyword == 'AFL18_1' ||
                                fd.sfieldKeyword == 'AF86' || fd.sfieldKeyword == 'AF86_1' || fd.sfieldKeyword == 'AF86_2' || fd.sfieldKeyword == 'AF86_3' || fd.sfieldKeyword == 'AF86_4' || fd.sfieldKeyword == 'AF86_5') { //|| fd.sfieldKeyword == 'LAHLCL30_3'
                                    if (String.isNotBlank(fd.sfieldValue) && fd.sfieldValue != 'NA') {
                                        System.debug(fd.sfieldKeyword+' earlier value is '+fd.sfieldValue);
                                        DateTime createdDt;
                                        try {
                                            createdDt = DateTime.valueOf(fd.sfieldValue);
                                            System.debug('Parsed DateTime: ' + createdDt);
                                            String formattedDate = createdDt.format('ddMMyy');
                                            fd.sfieldValue = formattedDate;
                                        } catch (Exception e) {
                                            System.debug('Failed to parse DateTime: ' + e.getMessage());
                                        }
                                        System.debug(fd.sfieldKeyword+' formatted value is '+fd.sfieldValue);
                                    }
                                }
                                
                                if (fd.sfieldKeyword == 'IF54' || fd.sfieldKeyword == 'IF58' || fd.sfieldKeyword == 'IF74' || fd.sfieldKeyword == 'IF76_1' ||
                                fd.sfieldKeyword == 'IF76_3' || fd.sfieldKeyword == 'IF76_5') {
                                    if (String.isNotBlank(fd.sfieldValue) && fd.sfieldValue != 'NA') {
                                        System.debug(fd.sfieldKeyword+' earlier value is '+fd.sfieldValue);
                                        DateTime createdDt;
                                        try {
                                            createdDt = DateTime.valueOf(fd.sfieldValue);
                                            System.debug('Parsed DateTime: ' + createdDt);
                                            String formattedDate = createdDt.format('ddMMyyyy');
                                            fd.sfieldValue = formattedDate;
                                        } catch (Exception e) {
                                            System.debug('Failed to parse DateTime: ' + e.getMessage());
                                        }
                                        System.debug(fd.sfieldKeyword+' formatted value is '+fd.sfieldValue);
                                    }
                                }
                                
                                if (fd.sfieldType == 'Boolean') {
                                    System.debug(fd.sfieldKeyword+' earlier boolean value is '+fd.sfieldValue);
                                    String originalValue = fd.sfieldValue;
                                    fd.sfieldValue = 'false';
                                    
                                    if (fieldMap.containsKey(originalValue) && fieldMap.get(originalValue).contains(fd.sfieldKeyword)) {
                                        fd.sfieldValue = 'true';
                                    }
                                    
                                    if (specialFields.contains(fd.sfieldKeyword)) {
                                        if (!fieldMap.containsKey(originalValue)) {
                                            fd.sfieldValue = 'true';
                                        }
                                    }
                                    
                                    System.debug(fd.sfieldKeyword+' formatted boolean value is '+fd.sfieldValue);
                                }

                                //change by Kunal Bisht for SFHL-1743 - start
                                if (fd.sfieldKeyword != null && fd.sfieldKeyword.startsWith('LAHLCL37_')) {
                                    fd.sfieldType = 'Boolean';
                                    String suffix = fd.sfieldKeyword.substringAfter('_');
                                    Integer keyNum = Integer.valueOf(suffix);

                                    Integer index;
                                    if (Math.mod(keyNum, 2) == 1) {
                                        index = (keyNum - 1) / 2;
                                        if (index >= 0 && index < covenantDocDetailsList.size()) {
                                            if (fd.sfieldValue == 'Original') {
                                                fd.sfieldValue = 'true';
                                            }
                                        }
                                    }
                                    else {
                                        index = (keyNum / 2) - 1;
                                        if (index >= 0 && index < covenantDocDetailsList.size()) {
                                            if (fd.sfieldValue != null && fd.sfieldValue != '' && fd.sfieldValue != 'Original') {
                                                fd.sfieldValue = 'true';
                                            }
                                        }
                                    }
                                }
                                //change by Kunal Bisht for SFHL-1743 - end
                                
                                if (primaryAddressFields.contains(fd.sfieldKeyword)) {
                                    if (fd.sfieldKeyword == 'AF38'){
                                        fd.sfieldValue = (primaryIndv != null && primaryIndv[0] != null && primaryIndv[0].Address_Line_1__c != null) ? primaryIndv[0].Address_Line_1__c : (primaryNonIndv != null && primaryNonIndv[0] != null && primaryNonIndv[0].Address_Line_1__c != null) ? primaryNonIndv[0].Address_Line_1__c : '';
                                    }
                                    // if (fd.sfieldKeyword == 'AF38_1'){
                                        //     fd.sfieldValue = (coApplicantIndv != null && coApplicantIndv.Address_Line_1__c != null) ? coApplicantIndv.Address_Line_1__c : (coApplicantNonIndv != null && coApplicantNonIndv.Address_Line_1__c != null) ? coApplicantNonIndv.Address_Line_1__c : '';
                                    // }
                                    
                                    if (fd.sfieldKeyword == 'LAHLCL6' || fd.sfieldKeyword == 'LAFLCL109') { //change by Kunal Bisht for SFHL-1743
                                        fd.sfieldValue = (primaryIndvCurrentVeryHighPriority != null && primaryIndvCurrentVeryHighPriority[0] != null && primaryIndvCurrentVeryHighPriority[0].Full_Address1__c != null) ? primaryIndvCurrentVeryHighPriority[0].Full_Address1__c : (primaryNonIndv != null && primaryNonIndv[0] != null && primaryNonIndv[0].Full_Address1__c != null) ? primaryNonIndv[0].Full_Address1__c : ''; //change by Kunal Bisht for SFHL-1743
                                    }
                                    
                                    if (fd.sfieldKeyword == 'AF39'){
                                        fd.sfieldValue = (primaryIndv != null && primaryIndv[0] != null && primaryIndv[0].Address_Line_2__c != null) ? primaryIndv[0].Address_Line_2__c : (primaryNonIndv != null && primaryNonIndv[0] != null && primaryNonIndv[0].Address_Line_2__c != null) ? primaryNonIndv[0].Address_Line_2__c : '';
                                    }
                                    // if (fd.sfieldKeyword == 'AF39_1'){
                                        //     fd.sfieldValue = (coApplicantIndv != null && coApplicantIndv.Address_Line_2__c != null) ? coApplicantIndv.Address_Line_2__c : (coApplicantNonIndv != null && coApplicantNonIndv.Address_Line_2__c != null) ? coApplicantNonIndv.Address_Line_2__c : '';
                                    // }
                                    
                                    if (fd.sfieldKeyword == 'AF40'){
                                        fd.sfieldValue = (primaryIndv != null && primaryIndv[0] != null && primaryIndv[0].Address_Line_3__c != null) ? primaryIndv[0].Address_Line_3__c : (primaryNonIndv != null && primaryNonIndv[0] != null && primaryNonIndv[0].Address_Line_3__c != null) ? primaryNonIndv[0].Address_Line_3__c : '';
                                    }
                                    // if (fd.sfieldKeyword == 'AF40_1'){
                                        //     fd.sfieldValue = (coApplicantIndv != null && coApplicantIndv.Address_Line_3__c != null) ? coApplicantIndv.Address_Line_3__c : (coApplicantNonIndv != null && coApplicantNonIndv.Address_Line_3__c != null) ? coApplicantNonIndv.Address_Line_3__c : '';
                                    // }
                                    
                                    if (fd.sfieldKeyword == 'AF41'){
                                        // fd.sfieldValue = primaryIndv[0] != null ? primaryIndv[0].Landmark__c : (primaryNonIndv[0] != null ? primaryNonIndv[0].Landmark__c : '');
                                        fd.sfieldValue = (primaryIndv != null && primaryIndv[0] != null && primaryIndv[0].Landmark__c != null) ? primaryIndv[0].Landmark__c : (primaryNonIndv != null && primaryNonIndv[0] != null && primaryNonIndv[0].Landmark__c != null) ? primaryNonIndv[0].Landmark__c : '';
                                    }
                                    // if (fd.sfieldKeyword == 'AF41_1'){
                                        //     // fd.sfieldValue = coApplicantIndv != null ? coApplicantIndv.Landmark__c : (coApplicantNonIndv != null ? coApplicantNonIndv.Landmark__c : '');
                                        //     fd.sfieldValue = (coApplicantIndv != null && coApplicantIndv.Landmark__c != null) ? coApplicantIndv.Landmark__c : (coApplicantNonIndv != null && coApplicantNonIndv.Landmark__c != null) ? coApplicantNonIndv.Landmark__c : '';
                                    // }
                                    
                                    if (fd.sfieldKeyword == 'AF42'){
                                        fd.sfieldValue = (primaryIndv != null && primaryIndv[0] != null && primaryIndv[0].City__c != null) ? primaryIndv[0].City__c : (primaryNonIndv != null && primaryNonIndv[0] != null && primaryNonIndv[0].City__c != null) ? primaryNonIndv[0].City__c : '';
                                    }
                                    // if (fd.sfieldKeyword == 'AF42_1'){
                                        //     fd.sfieldValue = (coApplicantIndv != null && coApplicantIndv.City__c != null) ? coApplicantIndv.City__c : (coApplicantNonIndv != null && coApplicantNonIndv.City__c != null) ? coApplicantNonIndv.City__c : '';
                                    // }
                                    
                                    if (fd.sfieldKeyword == 'AF43'){
                                        // fd.sfieldValue = primaryIndv[0] != null ? primaryIndv[0].Address_Line_1__c : (primaryNonIndv[0] != null ? primaryNonIndv[0].Address_Line_1__c : '');
                                        fd.sfieldValue = '';
                                    }
                                    if (fd.sfieldKeyword == 'AF43_1'){
                                        // fd.sfieldValue = coApplicantIndv != null ? coApplicantIndv.Address_Line_1__c : (coApplicantNonIndv != null ? coApplicantNonIndv.Address_Line_1__c : nu'l);
                                        fd.sfieldValue = '';
                                    }
                                    
                                    if (fd.sfieldKeyword == 'AF44'){
                                        fd.sfieldValue = (primaryIndv != null && primaryIndv[0] != null && primaryIndv[0].State__c != null) ? primaryIndv[0].State__c : (primaryNonIndv != null && primaryNonIndv[0] != null && primaryNonIndv[0].State__c != null) ? primaryNonIndv[0].State__c : '';
                                    }
                                    // if (fd.sfieldKeyword == 'AF44_1'){
                                        //     fd.sfieldValue = (coApplicantIndv != null && coApplicantIndv.State__c != null) ? coApplicantIndv.State__c : (coApplicantNonIndv != null && coApplicantNonIndv.State__c != null) ? coApplicantNonIndv.State__c : '';
                                    // }
                                    
                                    if (fd.sfieldKeyword == 'AF45'){
                                        fd.sfieldValue = (primaryIndv != null && primaryIndv[0] != null && primaryIndv[0].Pincode__r?.Name != null) ? primaryIndv[0].Pincode__r.Name : (primaryNonIndv != null && primaryNonIndv[0] != null && primaryNonIndv[0].Pincode__r?.Name != null) ? primaryNonIndv[0].Pincode__r.Name : '';
                                    }
                                    // if (fd.sfieldKeyword == 'AF45_1'){
                                        //     fd.sfieldValue = (coApplicantIndv != null && coApplicantIndv.Pincode__r?.Name != null) ? coApplicantIndv.Pincode__r.Name : (coApplicantNonIndv != null && coApplicantNonIndv.Pincode__r?.Name != null) ? coApplicantNonIndv.Pincode__r.Name : '';
                                    // }
                                    
                                    if (fd.sfieldKeyword == 'AF68') {
                                        if (primaryIndv != null && primaryIndv[0] != null && primaryIndv[0].Document_Details__r?.Name != null && prefixMap.containsKey(primaryIndv[0].Document_Details__r.Name)) {
                                            fd.sfieldValue = prefixMap.get(primaryIndv[0].Document_Details__r.Name);
                                        }
                                        
                                        if (primaryNonIndv != null && primaryNonIndv[0] != null && primaryNonIndv[0].Document_Details__r?.Name != null && prefixMap.containsKey(primaryNonIndv[0].Document_Details__r.Name)) {
                                            fd.sfieldValue = prefixMap.get(primaryNonIndv[0].Document_Details__r.Name);
                                        }
                                    }
                                    
                                    // if (fd.sfieldKeyword == 'AF68_1') {
                                        //     if (coApplicantIndv != null && coApplicantIndv.Document_Details__r?.Name != null && prefixMap.containsKey(coApplicantIndv.Document_Details__r.Name)) {
                                            //         fd.sfieldValue = prefixMap.get(coApplicantIndv.Document_Details__r.Name);
                                        //     }
                                        
                                        //     if (coApplicantNonIndv != null && coApplicantNonIndv.Document_Details__r?.Name != null && prefixMap.containsKey(coApplicantNonIndv.Document_Details__r.Name)) {
                                            //         fd.sfieldValue = prefixMap.get(coApplicantNonIndv.Document_Details__r.Name);
                                        //     }
                                    // }
                                    
                                    if (fd.sfieldKeyword == 'AF69') {
                                        if (primaryIndv != null && primaryIndv[0] != null && primaryIndv[0].Document_Details__r?.Name != null && prefixMap.containsKey(primaryIndv[0].Document_Details__r.Name)) {
                                            if (prefixMap.get(primaryIndv[0].Document_Details__r.Name) == 'Aadhaar') {
                                                fd.sfieldValue = primaryIndv[0].Applicant__r.Masked_Aadhar_Number__c;
                                            }
                                            
                                            if (prefixMap.get(primaryIndv[0].Document_Details__r.Name) == 'Passport') {
                                                fd.sfieldValue = primaryIndv[0].Applicant__r.Passport_Number__c;
                                            }
                                            
                                            if (prefixMap.get(primaryIndv[0].Document_Details__r.Name) == 'Voter ID') {
                                                fd.sfieldValue = primaryIndv[0].Applicant__r.Voter_ID_Number__c;
                                            }
                                            
                                            if (prefixMap.get(primaryIndv[0].Document_Details__r.Name) == 'DL') {
                                                fd.sfieldValue = primaryIndv[0].Applicant__r.Drivers_License_Number__c;
                                            }
                                        }
                                        
                                        if (primaryNonIndv != null && primaryNonIndv[0] != null && primaryNonIndv[0].Document_Details__r?.Name != null && prefixMap.containsKey(primaryNonIndv[0].Document_Details__r.Name)) {
                                            if (prefixMap.get(primaryNonIndv[0].Document_Details__r.Name) == 'Aadhaar') {
                                                fd.sfieldValue = primaryNonIndv[0].Applicant__r.Masked_Aadhar_Number__c;
                                            }
                                            
                                            if (prefixMap.get(primaryNonIndv[0].Document_Details__r.Name) == 'Passport') {
                                                fd.sfieldValue = primaryNonIndv[0].Applicant__r.Passport_Number__c;
                                            }
                                            
                                            if (prefixMap.get(primaryNonIndv[0].Document_Details__r.Name) == 'Voter ID') {
                                                fd.sfieldValue = primaryNonIndv[0].Applicant__r.Voter_ID_Number__c;
                                            }
                                            
                                            if (prefixMap.get(primaryNonIndv[0].Document_Details__r.Name) == 'DL') {
                                                fd.sfieldValue = primaryNonIndv[0].Applicant__r.Drivers_License_Number__c;
                                            }
                                        }
                                    }
                                    
                                    // if (fd.sfieldKeyword == 'AF69_1') {
                                        //     if (coApplicantIndv != null && coApplicantIndv.Document_Details__r?.Name != null && prefixMap.containsKey(coApplicantIndv.Document_Details__r.Name)) {
                                            //         if (prefixMap.get(coApplicantIndv.Document_Details__r.Name) == 'Aadhaar') {
                                                //             fd.sfieldValue = coApplicantIndv.Applicant__r.Masked_Aadhar_Number__c;
                                            //         }
                                            
                                            //         if (prefixMap.get(coApplicantIndv.Document_Details__r.Name) == 'Passport') {
                                                //             fd.sfieldValue = coApplicantIndv.Applicant__r.Passport_Number__c;
                                            //         }
                                            
                                            //         if (prefixMap.get(coApplicantIndv.Document_Details__r.Name) == 'Voter ID') {
                                                //             fd.sfieldValue = coApplicantIndv.Applicant__r.Voter_ID_Number__c;
                                            //         }
                                            
                                            //         if (prefixMap.get(coApplicantIndv.Document_Details__r.Name) == 'DL') {
                                                //             fd.sfieldValue = coApplicantIndv.Applicant__r.Drivers_License_Number__c;
                                            //         }
                                        //     }
                                        
                                        //     if (coApplicantNonIndv != null && coApplicantNonIndv.Document_Details__r?.Name != null && prefixMap.containsKey(coApplicantNonIndv.Document_Details__r.Name)) {
                                            //         if (prefixMap.get(coApplicantNonIndv.Document_Details__r.Name) == 'Aadhaar') {
                                                //             fd.sfieldValue = coApplicantNonIndv.Applicant__r.Aadhaar_Number__c;
                                            //         }
                                            
                                            //         if (prefixMap.get(coApplicantNonIndv.Document_Details__r.Name) == 'Passport') {
                                                //             fd.sfieldValue = coApplicantNonIndv.Applicant__r.Passport_Number__c;
                                            //         }
                                            
                                            //         if (prefixMap.get(coApplicantNonIndv.Document_Details__r.Name) == 'Voter ID') {
                                                //             fd.sfieldValue = coApplicantNonIndv.Applicant__r.Voter_ID_Number__c;
                                            //         }
                                            
                                            //         if (prefixMap.get(coApplicantNonIndv.Document_Details__r.Name) == 'DL') {
                                                //             fd.sfieldValue = coApplicantNonIndv.Applicant__r.Drivers_License_Number__c;
                                            //         }
                                        //     }
                                    // }
                                    
                                    if (coApplicantAddresses != null) {
                                        for (Integer i = 0; i < coApplicantAddresses.size(); i++) {
                                            Applicant_Address__c addr = coApplicantAddresses[i];
                                            Integer index = i + 1;
                                            
                                            if (fd.sfieldKeyword == 'AF38_' + index) {
                                                fd.sfieldValue = (addr.Address_Line_1__c != null) ? addr.Address_Line_1__c : '';
                                            } else if (fd.sfieldKeyword == 'AF39_' + index) {
                                                fd.sfieldValue = (addr.Address_Line_2__c != null) ? addr.Address_Line_2__c : '';
                                            } else if (fd.sfieldKeyword == 'AF40_' + index) {
                                                fd.sfieldValue = (addr.Address_Line_3__c != null) ? addr.Address_Line_3__c : '';
                                            } else if (fd.sfieldKeyword == 'AF41_' + index) {
                                                fd.sfieldValue = (addr.Landmark__c != null) ? addr.Landmark__c : '';
                                            } else if (fd.sfieldKeyword == 'AF42_' + index) {
                                                fd.sfieldValue = (addr.City__c != null) ? addr.City__c : '';
                                            } else if (fd.sfieldKeyword == 'AF44_' + index) {
                                                fd.sfieldValue = (addr.State__c != null) ? addr.State__c : '';
                                            } else if (fd.sfieldKeyword == 'AF45_' + index) {
                                                fd.sfieldValue = (addr.Pincode__r?.Name != null) ? addr.Pincode__r.Name : '';
                                            } else if (fd.sfieldKeyword == 'AF68_' + index) {
                                                if (addr.Document_Details__r != null && addr.Document_Details__r.Name != null && prefixMap.containsKey(addr.Document_Details__r.Name)){
                                                    fd.sfieldValue = prefixMap.get(addr.Document_Details__r.Name);
                                                } else {
                                                    fd.sfieldValue = '';
                                                }
                                            } else if (fd.sfieldKeyword == 'AF69_' + index) {
                                                if (addr.Document_Details__r != null && addr.Document_Details__r.Name != null && prefixMap.containsKey(addr.Document_Details__r.Name)){
                                                    String documentType = prefixMap.get(addr.Document_Details__r.Name);
                                                    
                                                    if (documentType == 'Aadhaar' && addr.Applicant__r?.Masked_Aadhar_Number__c != null) {
                                                        fd.sfieldValue = addr.Applicant__r.Masked_Aadhar_Number__c;
                                                    }
                                                    else if (documentType == 'Passport' && addr.Applicant__r?.Passport_Number__c != null) {
                                                        fd.sfieldValue = addr.Applicant__r.Passport_Number__c;
                                                    }
                                                    else if (documentType == 'Voter ID' && addr.Applicant__r?.Voter_ID_Number__c != null) {
                                                        fd.sfieldValue = addr.Applicant__r.Voter_ID_Number__c;
                                                    }
                                                    else if (documentType == 'DL' && addr.Applicant__r?.Drivers_License_Number__c != null) {
                                                        fd.sfieldValue = addr.Applicant__r.Drivers_License_Number__c;
                                                    }
                                                    else {
                                                        fd.sfieldValue = '';
                                                    }
                                                } else {
                                                    fd.sfieldValue = '';
                                                }
                                            }
                                            if(coApplicantAddressesVeryHighPriority== null || coApplicantAddressesVeryHighPriority.size()==0){ //added by Kunal Bisht for SFHL-1743
                                                if((fd.sfieldKeyword == 'LAHLCL8' || fd.sfieldKeyword == 'LAFLCL111') && i == 0){ //change by Kunal Bisht for SFHL-1743
                                                fd.sfieldValue = (addr.Full_Address1__c != null) ? addr.Full_Address1__c : '';
                                                } else if((fd.sfieldKeyword == 'LAHLCL8_2' || fd.sfieldKeyword == 'LAFLCL111_1') && i == 1){ //change by Kunal Bisht for SFHL-1743
                                                fd.sfieldValue = (addr.Full_Address1__c != null) ? addr.Full_Address1__c : '';
                                                } else if((fd.sfieldKeyword == 'LAHLCL8_4' || fd.sfieldKeyword == 'LAFLCL111_2') && i == 2){ //change by Kunal Bisht for SFHL-1743
                                                fd.sfieldValue = (addr.Full_Address1__c != null) ? addr.Full_Address1__c : '';
                                            }
                                        }
                                    }
                                    }
                                    //change by Kunal Bisht for SFHL-1743 - start
                                    if (coApplicantAddressesVeryHighPriority != null) {
                                        for (Integer i = 0; i < coApplicantAddressesVeryHighPriority.size(); i++) {
                                            Applicant_Address__c addr = coApplicantAddressesVeryHighPriority[i];
                                            Integer index = i + 1;
                                            
                                            if((fd.sfieldKeyword == 'LAHLCL8' || fd.sfieldKeyword == 'LAFLCL111') && i == 0){
                                                fd.sfieldValue = (addr.Full_Address1__c != null) ? addr.Full_Address1__c : '';
                                            } else if((fd.sfieldKeyword == 'LAHLCL8_2' || fd.sfieldKeyword == 'LAFLCL111_1') && i == 1){
                                                fd.sfieldValue = (addr.Full_Address1__c != null) ? addr.Full_Address1__c : '';
                                            } else if((fd.sfieldKeyword == 'LAHLCL8_4' || fd.sfieldKeyword == 'LAFLCL111_2') && i == 2){
                                                fd.sfieldValue = (addr.Full_Address1__c != null) ? addr.Full_Address1__c : '';
                                            }
                                        }
                                    }
                                    //change by Kunal Bisht for SFHL-1743 - end
                                }
                                if (fd.sfieldKeyword == 'AF93') {
                                    fd.sfieldValue = (primaryOccAddr != null && primaryOccAddr[0] != null && primaryOccAddr[0].Address_Line_1__c != null) ? primaryOccAddr[0].Address_Line_1__c : '';
                                    system.debug('AF93: ' + fd.sfieldValue);
                                }
                                
                                if (fd.sfieldKeyword == 'AF94') {
                                    fd.sfieldValue = (primaryOccAddr != null && primaryOccAddr[0] != null && primaryOccAddr[0].Address_Line_2__c != null) ? primaryOccAddr[0].Address_Line_2__c : '';
                                    system.debug('AF94: ' + fd.sfieldValue);
                                }
                                if (fd.sfieldKeyword == 'AF95') {
                                    fd.sfieldValue = (primaryOccAddr != null && primaryOccAddr[0] != null && primaryOccAddr[0].Address_Line_3__c != null) ? primaryOccAddr[0].Address_Line_3__c : '';
                                    system.debug('AF95: ' + fd.sfieldValue);
                                }
                                if (fd.sfieldKeyword == 'AF96') {
                                    fd.sfieldValue = (primaryOccAddr != null && primaryOccAddr[0] != null && primaryOccAddr[0].Landmark__c != null) ? primaryOccAddr[0].Landmark__c : '';
                                    system.debug('AF96: ' + fd.sfieldValue);
                                }
                                if (fd.sfieldKeyword == 'AF97') {
                                    fd.sfieldValue = (primaryOccAddr != null && primaryOccAddr[0] != null && primaryOccAddr[0].City__c != null) ? primaryOccAddr[0].City__c : '';
                                    system.debug('AF97: ' + fd.sfieldValue);
                                }
                                if (fd.sfieldKeyword == 'AF98') {
                                    fd.sfieldValue = (primaryOccAddr != null && primaryOccAddr[0] != null && primaryOccAddr[0].State__c != null) ? primaryOccAddr[0].State__c : '';
                                    system.debug('AF98: ' + fd.sfieldValue);
                                }
                                if (fd.sfieldKeyword == 'AF99') {
                                    fd.sfieldValue = (primaryOccAddr != null && primaryOccAddr[0] != null && primaryOccAddr[0].Pincode__r.Name != null) ? primaryOccAddr[0].Pincode__r.Name : '';
                                    system.debug('AF99: ' + fd.sfieldValue);
                                }
                                
                                // Handle up to 5 co-applicants (index 1 to 4)
                                if ( coApplicantOccAddr != null) {
                                    for (Integer idx = 0; idx < coApplicantIdsOrdered.size(); idx++) {
                                        Id coAppId = coApplicantIdsOrdered[idx];
                                        Applicant_Address__c occAddr = coApplicantOccAddrMap.containsKey(coAppId) ? coApplicantOccAddrMap.get(coAppId) : null;
                                        if (fd.sfieldKeyword == 'AF93_' + (idx+1)) {
                                            fd.sfieldValue = (occAddr != null && occAddr.Address_Line_1__c != null) ? occAddr.Address_Line_1__c : '';
                                            system.debug('AF93_' + (idx+1) + ': ' + fd.sfieldValue);
                                        }
                                        if (fd.sfieldKeyword == 'AF94_' + (idx+1)) {
                                            fd.sfieldValue = (occAddr != null && occAddr.Address_Line_2__c != null) ? occAddr.Address_Line_2__c : '';
                                            system.debug('AF94_' + (idx+1) + ': ' + fd.sfieldValue);
                                        }
                                        if (fd.sfieldKeyword == 'AF95_' + (idx+1)) {
                                            fd.sfieldValue = (occAddr != null && occAddr.Address_Line_3__c != null) ? occAddr.Address_Line_3__c : '';
                                            system.debug('AF95_' + (idx+1) + ': ' + fd.sfieldValue);
                                        }
                                        if (fd.sfieldKeyword == 'AF96_' + (idx+1)) {
                                            fd.sfieldValue = (occAddr != null && occAddr.Landmark__c != null) ? occAddr.Landmark__c : '';
                                            system.debug('AF96_' + (idx+1) + ': ' + fd.sfieldValue);
                                        }
                                        if (fd.sfieldKeyword == 'AF97_' + (idx+1)) {
                                            fd.sfieldValue = (occAddr != null && occAddr.City__c != null) ? occAddr.City__c : '';
                                            system.debug('AF97_' + (idx+1) + ': ' + fd.sfieldValue);
                                        }
                                        if (fd.sfieldKeyword == 'AF98_' + (idx+1)) {
                                            fd.sfieldValue = (occAddr != null && occAddr.State__c != null) ? occAddr.State__c : '';
                                            system.debug('AF98_' + (idx+1) + ': ' + fd.sfieldValue);
                                        }
                                        if (fd.sfieldKeyword == 'AF99_' + (idx+1)) {
                                            fd.sfieldValue = (occAddr != null && occAddr.Pincode__r != null && occAddr.Pincode__r.Name != null) ? occAddr.Pincode__r.Name : '';
                                            system.debug('AF99_' + (idx+1) + ': ' + fd.sfieldValue);
                                        }
                                    }
                                }
                                
                                if (fd.sfieldKeyword == 'LAHLCL14_1') {
                                    fd.sfieldValue = 'true';
                                }
                                
                                if (incomeObligationFields.contains(fd.sfieldKeyword)) {
                                    for (Integer i = 0; i < incomeObligationList.size(); i++) {
                                        Income_Expense_Obligation__c incomeObligation = incomeObligationList[i];
                                        
                                        // Build suffix (_1, _2, etc.) dynamically
                                        String suffix = (i == 0) ? '' : '_' + i;
                                        
                                        // Match field keyword + suffix (e.g., AF148_1)
                                        String keyword = fd.sfieldKeyword;
                                        
                                        if (keyword == 'AF148' + suffix) {
                                            fd.sfieldValue = incomeObligation.Secured_Unsecured__c;
                                        } else if (keyword == 'AF149' + suffix) {
                                            fd.sfieldValue = String.valueOf(incomeObligation.Loan_Amount__c);
                                        } else if (keyword == 'AF150' + suffix) {
                                            fd.sfieldValue = String.valueOf(incomeObligation.Imputed_EMI__c);
                                        } else if (keyword == 'AF151' + suffix) {
                                            fd.sfieldValue = String.valueOf(incomeObligation.Current_Balance__c);
                                        }
                                    }
                                }
                                
                                /*commented by Kunal Bisht for SFHL-1743
                                if (ownContributionFields.contains(fd.sfieldKeyword) && !isOCRAllowed) { //change by Kunal Bisht for SFHL-1743
                                    fd.sfieldValue = '';
                                }*/
                                
                                if (fd.sfieldKeyword == 'LAHLCL19_1' || fd.sfieldKeyword == 'LAHLCL19_2' || fd.sfieldKeyword == 'LAHLCL21_1' || fd.sfieldKeyword == 'LAHLCL21_2' ||
                                fd.sfieldKeyword == 'LAHLCL67_7' || fd.sfieldKeyword == 'LAHLCL65' || fd.sfieldKeyword == 'LAHLCL67') {
                                    fd.sfieldValue = 'false';
                                    for (Product2 product : productList) {
                                        if (product.RecordType.Name == 'Sub Product' && product.Loan_Facility__c == 'Fixed' && (fd.sfieldKeyword == 'LAHLCL19_1' || fd.sfieldKeyword == 'LAHLCL67_7')) {
                                            fd.sfieldValue = 'true';
                                        }
                                        
                                        if (product.RecordType.Name == 'Sub Product' && product.Loan_Facility__c != 'Fixed'  && fd.sfieldKeyword == 'LAHLCL19_2') {
                                            fd.sfieldValue = 'true';
                                        }
                                        
                                        if (product.RecordType.Name == 'Sub Product' && product.Loan_Facility__c == 'Floating' && (fd.sfieldKeyword == 'LAHLCL21_1' || fd.sfieldKeyword == 'LAHLCL65')) {
                                            fd.sfieldValue = 'true';
                                        }
                                        
                                        if (product.RecordType.Name == 'Sub Product' && product.Loan_Facility__c != 'Floating' && fd.sfieldKeyword == 'LAHLCL21_2') {
                                            fd.sfieldValue = 'true';
                                        }
                                        
                                        if (product.RecordType.Name == 'Sub Product' && product.Loan_Facility__c == 'Semi-fixed' && fd.sfieldKeyword == 'LAHLCL67') {
                                            fd.sfieldValue = 'true';
                                        }
                                    }
                                }
                                //Final_Rate_Of_Interest__c
                                if (fd.sfieldKeyword == 'LAHLCL67_8' || fd.sfieldKeyword == 'LAHLCL19_2' || fd.sfieldKeyword == 'LAHLCL21_1' || fd.sfieldKeyword == 'LAHLCL21_2') {
                                    for (Product2 product : productList) {
                                        if (product.RecordType.Name == 'Sub Product' && product.Loan_Facility__c == 'Fixed' && fd.sfieldKeyword == 'LAHLCL67_8') {
                                            fd.sfieldValue = String.valueOf(opp[0].Final_Rate_Of_Interest__c);
                                        }
                                        
                                        if (product.RecordType.Name == 'Sub Product' && product.Loan_Facility__c == 'Floating' && (fd.sfieldKeyword == 'LAHLCL66' || fd.sfieldKeyword == 'LAFLCL156')) { //change by Kunal Bisht for SFHL-1743
                                            fd.sfieldValue = String.valueOf(opp[0].Final_Rate_Of_Interest__c);
                                        }
                                        
                                        if (product.RecordType.Name == 'Sub Product' && product.Loan_Facility__c == 'Semi-fixed' && fd.sfieldKeyword == 'LAHLCL67_1') {
                                            fd.sfieldValue = String.valueOf(opp[0].Final_Rate_Of_Interest__c);
                                        }
                                        //LAHLCL67
                                    }
                                }
                                
                                //Interest Due Date
                                if(fd.sfieldKeyword == 'LAHLCL17_4' || fd.sfieldKeyword == 'LAHLCL16' || fd.sfieldKeyword == 'LAHLCL15'){
                                    if (fd.sfieldValue == '03' || fd.sfieldValue == '06') {
                                        fd.sfieldValue = fd.sfieldValue + ' of month';
                                    }
                                }
                                
                                
                                //GHFPLR, ROI, Spread
                                if (fd.sfieldKeyword == 'LAHLCL66' || fd.sfieldKeyword == 'LAFLCL156') { //change by Kunal Bisht for SFHL-1743
                                    fd.sfieldValue = baseRate != null ? String.valueOf(baseRate) : 'NA';
                                }
                                
                                if (fd.sfieldKeyword == 'LAHLCL66_1' || fd.sfieldKeyword == 'LAFLCL156_1') { //change by Kunal Bisht for SFHL-1743
                                    fd.sfieldValue = diffFinalROI != null ? String.valueOf(diffFinalROI) : 'NA';
                                }
                                
                                if (fd.sfieldKeyword == 'LAHLCL66_2' || fd.sfieldKeyword == 'LAFLCL156_2' || fd.sfieldKeyword == 'MODTT8_1' || fd.sfieldKeyword == 'MODTT8_2' || fd.sfieldKeyword == 'MODTT8_3') { //added by Surabhi for SFHL-1883
                                    fd.sfieldValue = finalRateOfInterest != null ? String.valueOf(finalRateOfInterest) : 'NA';
                                }
                                
                                if (fd.sfieldKeyword == 'AF112' || fd.sfieldKeyword == 'LAHLCL31' || fd.sfieldKeyword == 'EDEmp6' || fd.sfieldKeyword == 'LAHLCL27' || fd.sfieldKeyword == 'LAHLCL72'  ||
                                    fd.sfieldKeyword == 'IDLTD9' || fd.sfieldKeyword == 'BRD17' || fd.sfieldKeyword == 'MOEK3_1' || fd.sfieldKeyword == 'MODTT3_1' || fd.sfieldKeyword == 'MODTT9' ||
                                    fd.sfieldKeyword == 'DOIUD10' || fd.sfieldKeyword == 'DOIUD14' || fd.sfieldKeyword == 'DSD11' || fd.sfieldKeyword == 'DSD13' || fd.sfieldKeyword == 'TPAAS28_5' ||
                                    fd.sfieldKeyword == 'TPAAS29_8' || fd.sfieldKeyword == 'SBK36' || fd.sfieldKeyword == 'SBK36_1' || fd.sfieldKeyword == 'SBK20' || fd.sfieldKeyword == 'SBK21' ||
                                    fd.sfieldKeyword == 'MODTT3' || fd.sfieldKeyword == 'SBK1_8' || fd.sfieldKeyword == 'DLH2' || fd.sfieldKeyword == 'MOED19_4' || fd.sfieldKeyword == 'TPAAS10' ||
                                    fd.sfieldKeyword == 'LAHLCL103' || fd.sfieldKeyword == 'MODTK3_1' || fd.sfieldKeyword == 'MODTK9') { //change by Surabhi for SFHL-1883
                                    List<Application_Collateral__c> appCol = [Select Id, Collateral__r.Unit_Property_Type__c,Collateral__r.Unit_Number__c,Collateral__r.Floor_Number__c, Collateral__r.Tower_Building_Name__c, Collateral__r.Address_Line_1__c, Collateral__r.Address_Line_2__c, Collateral__r.Address_Line_3__c, Collateral__r.City__c,Collateral__r.State__c,Collateral__r.Pincode__r.Name, Collateral__r.Country__c,Collateral__r.Agreement_Value__c from Application_Collateral__c where HL_Loan_Application__c =:loanAppId  LIMIT 1]; //change by Kunal Bisht for SFHL-1743 //change by Surabhi for SFHL-1883
                                    if(!appCol.isEmpty()){
                                        String collateralAddress = appCol[0].Collateral__r.Unit_Property_Type__c + ', ' + appCol[0].Collateral__r.Unit_Number__c + ', Floor Number:' + appCol[0].Collateral__r.Floor_Number__c+ ', ' + appCol[0].Collateral__r.Tower_Building_Name__c + ', ' + appCol[0].Collateral__r.Address_Line_1__c + ', ' + appCol[0].Collateral__r.Address_Line_2__c + ', ' + appCol[0].Collateral__r.Address_Line_3__c + ', ' + appCol[0].Collateral__r.City__c + ', ' + appCol[0].Collateral__r.State__c + ', ' + appCol[0].Collateral__r.Pincode__r.Name; //change by Kunal Bisht for SFHL-1743
                                        fd.sfieldValue = collateralAddress;
                                        
                                        if (fd.sfieldKeyword == 'TPAAS10') {
                                            fd.sfieldValue = Utility.getNumberTOWordConvertion(appCol[0].Collateral__r.Agreement_Value__c);
                                        }
                                        //change by Surabhi for SFHL-1883 - start
                                        String collateralFullAddress = appCol[0].Collateral__r.Unit_Property_Type__c + ', ' + appCol[0].Collateral__r.Unit_Number__c + ', ' + appCol[0].Collateral__r.Floor_Number__c+ ', ' + appCol[0].Collateral__r.Tower_Building_Name__c + ', ' + appCol[0].Collateral__r.Address_Line_1__c + ', ' + appCol[0].Collateral__r.Address_Line_2__c + ', ' + appCol[0].Collateral__r.Address_Line_3__c + ', ' + appCol[0].Collateral__r.City__c + ', ' + appCol[0].Collateral__r.State__c + ', ' + appCol[0].Collateral__r.Pincode__r.Name + ', ' + appCol[0].Collateral__r.Country__c; //SFHL-1883
                                        if (fd.sfieldKeyword == 'MODTK3_1' || fd.sfieldKeyword == 'MODTK9') {
                                            fd.sfieldValue =  collateralFullAddress;
                                        }
                                        //change by Surabhi for SFHL-1883 - end
                                    }
                                    else{
                                        fd.sfieldValue = 'NA';
                                    }
                                }
                                //change by Surabhi for SFHL-1883 - start
                                if (fd.sfieldKeyword == 'MODTK4' || fd.sfieldKeyword == 'MODTK7'){
                                    List <Opportunity> loanlst = [SELECT Id,Product__c,EMI_Amount_Repayment_Schedule__c from Opportunity WHERE Id = :loanAppId];
                                    if(!loanlst.isEmpty()){
                                        if(fd.sfieldKeyword == 'MODTK4'){
                                            fd.sfieldValue = loanlst[0].Product__c;
                                        }
                                        
                                        if(fd.sfieldKeyword == 'MODTK7'){
                                            fd.sfieldValue = String.valueOf(loanlst[0].EMI_Amount_Repayment_Schedule__c);
                                        }
                                        
                                    }
                                }
                                //change by Surabhi for SFHL-1883 - end
                                if (fd.sfieldKeyword == 'AF171_1' || fd.sfieldKeyword == 'NLH14') {
                                    List<Document_Details__c> appPhoto = [
                                SELECT Name, Content_Document_Id__c, Applicant__r.Applicant_Type__c,  Content_Version_Id__c,   Id 
                                FROM Document_Details__c 
                                WHERE Loan_Application__c =: loanId AND Name = 'Photograph' AND Applicant__r.Applicant_Type__c = 'Primary Applicant' AND Consider_for_Loan_Application__c = true ORDER BY Applicant__r.CreatedDate ASC LIMIT 1
                            ];
                                    System.debug('AF171_1:' +appPhoto);
                                    
                                    String contentDocId;
                                    if (!appPhoto.isEmpty()) {
                                        contentDocId = appPhoto[0].Content_Document_Id__c;
                                    }
                                    List<ContentVersion> photoCV = new List<ContentVersion>();
                                    if (contentDocId != null) {
                                        photoCV = [SELECT VersionData,  Id FROM ContentVersion WHERE ContentDocumentId =: contentDocId];
                                        fd.sfieldValue = EncodingUtil.base64Encode(photoCV[0].VersionData);
                                    }
                                }
                                
                                if (fd.sfieldKeyword == 'AF171_5' && coAppPhotoBase64List.size() > 0) {
                                    fd.sfieldValue = coAppPhotoBase64List[0];
                                }
                                if (fd.sfieldKeyword == 'AF171_123' && coAppPhotoBase64List.size() > 1) {
                                    fd.sfieldValue = coAppPhotoBase64List[1];
                                }
                                if (fd.sfieldKeyword == 'AF171_124' && coAppPhotoBase64List.size() > 2) {
                                    fd.sfieldValue = coAppPhotoBase64List[2];
                                }
                                if (fd.sfieldKeyword == 'AF171_125' && coAppPhotoBase64List.size() > 3) {
                                    fd.sfieldValue = coAppPhotoBase64List[3];
                                }
                                if (fd.sfieldKeyword == 'AF171_126' && coAppPhotoBase64List.size() > 4) {
                                    fd.sfieldValue = coAppPhotoBase64List[4];
                                }
                                
                                if (fd.sfieldKeyword == 'AF47' || fd.sfieldKeyword == 'AF47_2') {
                                    fd.sfieldValue = '+91';
                                }
                                
                                if (fd.sfieldKeyword == 'AF89') {
                                    if (String.isNotBlank(TotalIncomeOfPrimaryApp)) {
                                        fd.sfieldValue = TotalIncomeOfPrimaryApp;
                                    } else {
                                        fd.sfieldValue = ' ';
                                    }
                                }
                                
                                if (fd.sfieldKeyword == 'AF147' || fd.sfieldKeyword == 'AF147_1' || fd.sfieldKeyword == 'AF147_2' || fd.sfieldKeyword == 'AF147_3' || fd.sfieldKeyword == 'AF147_4') {
                                    fd.sfieldValue = '-';
                                }
                                
                                if (fd.sfieldKeyword == 'LAHLCL23_2') {
                                    fd.sfieldValue = '2% of the total EMI outstanding (Principal + Interest)'; //change by Kunal Bisht for SFHL-1743
                                }
                                
                                if (fd.sfieldKeyword == 'LAHLCL45' || fd.sfieldKeyword == 'LAHLCL1' || fd.sfieldKeyword == 'LAHLCL27_4_7' || fd.sfieldKeyword == 'LAHLCL42' || fd.sfieldKeyword == 'LAHLCL61' ||
                                    fd.sfieldKeyword == 'MOED8' || fd.sfieldKeyword == 'MOED9' || fd.sfieldKeyword == 'LAHLCL99' || fd.sfieldKeyword == 'MODTM4' || fd.sfieldKeyword == 'LAFLCL135' || fd.sfieldKeyword == 'LAHLCL28' || //change by Kunal Bisht for SFHL-1743
                                fd.sfieldKeyword == 'LAHLCL86' || fd.sfieldKeyword == 'LAFLCL105' || fd.sfieldKeyword == 'LAFLCL130' || fd.sfieldKeyword == 'LAFLCL134_1' || fd.sfieldKeyword == 'LAFLCL151' || fd.sfieldKeyword == 'MODTK2' || fd.sfieldKeyword == 'MODTT12') { //change by Kunal Bisht for SFHL-1743 //change by Surabhi for SFHL-1883
                                    fd.sfieldValue = applicantNamesString;
                                }
                                
                                if (fd.sfieldKeyword == 'LAHLCL26') {
                                    fd.sfieldValue = sellerBuilderApplicantNamesString + ' / '+collateralOwnerName;
                                }
                                
                                if (fd.sfieldKeyword == 'LAHLCL30_2' || fd.sfieldKeyword == 'LAHLCL43_1' || fd.sfieldKeyword == 'NLH9_1' || fd.sfieldKeyword == 'BRD15' || fd.sfieldKeyword == 'IDLTD7' ||
                                    fd.sfieldKeyword == 'MOEK5_1' || fd.sfieldKeyword == 'MOEK6_1' || fd.sfieldKeyword == 'MOEK7_1' || fd.sfieldKeyword == 'LAFLCL134_4' || fd.sfieldKeyword == 'NBK31_1' ||
                                    fd.sfieldKeyword == 'NBK3_1' || fd.sfieldKeyword == 'DOIUD8' || fd.sfieldKeyword == 'VLN5_1' || fd.sfieldKeyword == 'TPAAS15' ||
                                    fd.sfieldKeyword == 'TPAAS29_12' || fd.sfieldKeyword == 'SBK29_1' || fd.sfieldKeyword == 'SBK8_1' || fd.sfieldKeyword == 'NBK13_3' || fd.sfieldKeyword == 'SBK3_1' ||
                                fd.sfieldKeyword == 'MODTT5_2' || fd.sfieldKeyword == 'MODTT6_1' || fd.sfieldKeyword == 'MODTT7_1') {
                                    fd.sfieldValue = loanAmountInWords;
                                }
                                
                                if (fd.sfieldKeyword == 'TPAAS12_3') {
                                    fd.sfieldValue = totalOCRpaidInWords;
                                }
                                
                                if(fd.sfieldKeyword == 'LAHLCL30' ||
                                    // fd.sfieldKeyword == 'LAHLCL49_2' || fd.sfieldKeyword == 'LAHLCL49_3' || fd.sfieldKeyword == 'LAHLCL49_4' || fd.sfieldKeyword == 'LAHLCL49_5' ||
                                // fd.sfieldKeyword == 'LAHLCL50_2' || fd.sfieldKeyword == 'LAHLCL50_3' || fd.sfieldKeyword == 'LAHLCL50_4' || fd.sfieldKeyword == 'LAHLCL50_5' ||
                                // fd.sfieldKeyword == 'LAHLCL51_2' || fd.sfieldKeyword == 'LAHLCL51_3' || fd.sfieldKeyword == 'LAHLCL51_4' || fd.sfieldKeyword == 'LAHLCL51_5' ||
                                // fd.sfieldKeyword == 'LAHLCL52_2' || fd.sfieldKeyword == 'LAHLCL52_3' || fd.sfieldKeyword == 'LAHLCL52_4' || fd.sfieldKeyword == 'LAHLCL52_5' ||
                                // fd.sfieldKeyword == 'LAHLCL53_2' || fd.sfieldKeyword == 'LAHLCL53_3' || fd.sfieldKeyword == 'LAHLCL53_4' || fd.sfieldKeyword == 'LAHLCL53_5' ||
                                fd.sfieldKeyword == 'IDLTD9_1' || fd.sfieldKeyword == 'MODTT3_2' || fd.sfieldKeyword == 'DSD16' || fd.sfieldKeyword == 'LAHLCL78_20' ||
                                    fd.sfieldKeyword == 'MODTT5_1' || fd.sfieldKeyword == 'NBK24_1' || fd.sfieldKeyword == 'LAHLCL23_1' || fd.sfieldKeyword == 'LAHLCL27_1' /*||
                                    fd.sfieldKeyword == 'LAHLCL99' || fd.sfieldKeyword == 'LAHLCL100' || fd.sfieldKeyword == 'LAHLCL101' || fd.sfieldKeyword == 'LAHLCL102' || fd.sfieldKeyword == 'LAHLCL103'*/  /*Page 78 related fields*/  )//change by Kunal Bisht for SFHL-1743
                                {
                                    fd.sfieldValue = '';
                                }
                                //change by Kunal Bisht for SFHL-1743 - start
                                if (fd.sfieldKeyword == 'LAHLCL94' && isOCRAllowed) {
                                    /*if (OCRpending != null) {
                                        fd.sfieldValue = String.valueOf(OCRpending);
                                    } else {
                                        fd.sfieldValue = '';
                                    }*/
                                    if(totalCostOfProperty != null && totalLoanAmount != null && totalFeeToBeDeducted != null && paidAmount != null){
                                    fd.sfieldValue = String.valueOf((totalCostOfProperty - (totalLoanAmount - totalFeeToBeDeducted))-paidAmount);
                                    }else{
                                        fd.sfieldValue = '';
                                    }
                                    //change by Kunal Bisht for SFHL-1743 - end
                                }
                                
                                if (fd.sfieldKeyword == 'VLN7') {
                                    fd.sfieldValue = 'English';
                                }
                                
                                if (fd.sfieldKeyword == 'LAHLCL110') {
                                    fd.sfieldValue = 'true';
                                }
                                
                                if (fd.sfieldKeyword == 'EDEmp1' || fd.sfieldKeyword == 'BRD2' || fd.sfieldKeyword == 'DSDOB17' || fd.sfieldKeyword == 'DOIUD1' || fd.sfieldKeyword == 'DOIUD20' || fd.sfieldKeyword == 'MODTM20' ||
                                    fd.sfieldKeyword == 'IDLTD2' || fd.sfieldKeyword == 'MODTT1' || fd.sfieldKeyword == 'MOED1_1' || fd.sfieldKeyword == 'NBK28' || fd.sfieldKeyword == 'NBK18' || fd.sfieldKeyword == 'SBK27' ||
                                    fd.sfieldKeyword == 'NLH11' || fd.sfieldKeyword == 'LAHLCL31_5' || fd.sfieldKeyword == 'LAHLCL78_13' || fd.sfieldKeyword == 'MOED20_18' || fd.sfieldKeyword == 'MODTT12_4' || fd.sfieldKeyword == 'MOEM20' ||
                                fd.sfieldKeyword == 'LAHLCL80' || fd.sfieldKeyword == 'POANRI9_1' ) { //|| fd.sfieldKeyword == 'MODTT1_2' //change by Surabhi for SFHL-1883
                                    fd.sfieldValue = String.valueOf(loanStartDay);
                                }
                                
                                if (fd.sfieldKeyword == 'EDEmp1_1' || fd.sfieldKeyword == 'BRD2_1' || fd.sfieldKeyword == 'DSDOB18' || fd.sfieldKeyword == 'DOIUD2' || fd.sfieldKeyword == 'DSD1'  || fd.sfieldKeyword == 'MODTM21' ||
                                    fd.sfieldKeyword == 'IDLTD3' || fd.sfieldKeyword == 'MODTT1_1' || fd.sfieldKeyword == 'MOED1_2' || fd.sfieldKeyword == 'NBK28_1' || fd.sfieldKeyword == 'NBK19' || fd.sfieldKeyword == 'SBK27_1' ||
                                    fd.sfieldKeyword == 'SBK15' || fd.sfieldKeyword == 'NLH12' || fd.sfieldKeyword == 'LAHLCL31_6' || fd.sfieldKeyword == 'LAHLCL78_14' || fd.sfieldKeyword == 'MOED20_19' || fd.sfieldKeyword == 'MOEM20_1' ||
                                fd.sfieldKeyword == 'MODTT12_5' || fd.sfieldKeyword == 'LAHLCL80_1' || fd.sfieldKeyword == 'POANRI9_2' ) { //|| fd.sfieldKeyword == 'MODTT1_1' //change by Surabhi for SFHL-1883
                                    fd.sfieldValue = String.valueOf(loanStartMonth);
                                }
                                
                                if (fd.sfieldKeyword == 'EDEmp1_2' || fd.sfieldKeyword == 'DOIUD3' || fd.sfieldKeyword == 'MODTT1_2' || fd.sfieldKeyword == 'MODTM22' || fd.sfieldKeyword == 'NBK28_2' || fd.sfieldKeyword == 'NBK19_1' ||
                                    fd.sfieldKeyword == 'NLH13' || fd.sfieldKeyword == 'LAHLCL31_7' || fd.sfieldKeyword == 'LAHLCL78_15' || fd.sfieldKeyword == 'MOED20_20' || fd.sfieldKeyword == 'MODTT12_6' || fd.sfieldKeyword == 'SBK16' ||
                                fd.sfieldKeyword == 'MOEM20_2' || fd.sfieldKeyword == 'LAHLCL80_2' || fd.sfieldKeyword == 'POANRI9_3' || fd.sfieldKeyword == 'MODTT12_7' ) { //|| fd.sfieldKeyword == 'MODTT12_3' //change by Surabhi for SFHL-1883
                                    fd.sfieldValue = String.valueOf(loanStartYearLastTwoDigits);
                                }
                                
                                if (fd.sfieldKeyword == 'BRD2_2' || fd.sfieldKeyword == 'DSDOB19' || fd.sfieldKeyword == 'DOIUD21' || fd.sfieldKeyword == 'DSD2') {
                                    fd.sfieldValue = String.valueOf(loanStartYear);
                                }
                                
                                if (fd.sfieldKeyword == 'MODTM10' || fd.sfieldKeyword == 'MOEM12') {
                                    fd.sfieldValue = sanctionDetails != null ? sanctionDetails : 'NA';
                                }
                                
                                if (fd.sfieldKeyword == 'LAHLCL27_2' || fd.sfieldKeyword == 'MODTM12' || fd.sfieldKeyword == 'MOED18' || fd.sfieldKeyword == 'MOEM14') {
                                    if (covenantTimelineDate != null) {
                                        fd.sfieldValue = String.valueOf(covenantTimelineDate);
                                    }
                                }
                                
                                if(fd.sfieldKeyword == 'DSD15' ||fd.sfieldKeyword == 'LAHLCL78_19' ||fd.sfieldKeyword == 'MOEK12_1' || fd.sfieldKeyword == 'POANRI14' || fd.sfieldKeyword == 'POANRI14_1' || fd.sfieldKeyword == 'MODTT12_1' ||
                                fd.sfieldKeyword == 'EDEmp15_1' || fd.sfieldKeyword == 'EDEmp15_2' || fd.sfieldKeyword == 'EDEmp15'){
                                    fd.sfieldValue = rmname;
                                    // fd.sfieldValue = 'Rupesh';
                                }
                                
                                if (fd.sfieldKeyword == 'AF91' && employerBusinessName.size() > 0) {
                                    fd.sfieldValue = employerBusinessName[0];
                                }
                                
                                if (fd.sfieldKeyword == 'AF91_1' && employerBusinessName.size() > 1) {
                                    fd.sfieldValue = employerBusinessName[1];
                                }
                                
                                if (fd.sfieldKeyword == 'LAHLCL18') { //change by Kunal Bisht for SFHL-1743
                                    fd.sfieldValue = fd.sfieldValue + '%';
                                }
                                
                                //change by Kunal Bisht for SFHL-1743 - start
                                if(fd.sfieldKeyword == 'LAHLCL78') {
                                    fd.sfieldValue = fd.sfieldValue + '% and ' +loanFacility;
                                }
                                if(fd.sfieldKeyword == 'LAFLCL166') { //if block added by Kunal Bisht for SFHL-1743 for FL
                                    fd.sfieldValue = fd.sfieldValue + '% and ' +loanFacilityFL;
                                }
                                //change by Kunal Bisht for SFHL-1743 - end
                                
                                if (fd.sfieldKeyword == 'LAHLCL30_3') {
                                    fd.sfieldValue = loanAgreementDate;
                                }
                                
                                /*if(fd.sfieldKeyword == 'LAHLCL56'){
                                    Decimal basePFAmount = String.isBlank(fd.sfieldValue) ? 0 : Decimal.valueOf(fd.sfieldValue);
                                    Decimal finalPFAmount = (basePFAmount * 1.18).setScale(2, RoundingMode.HALF_UP);
                                    fd.sfieldValue = String.valueOf(finalPFAmount);
                                } commented by Kunal Bisht for SFHL-1743*/
                                
                                if(fd.sfieldKeyword == 'AF185' && String.isNotBlank(channelCode)){
                                    fd.sfieldValue = channelCode;
                                } else if(fd.sfieldKeyword == 'AF185' && String.isBlank(channelCode)){
                                    fd.sfieldValue = '';
                                }
                                
                                if (namesKeywordMapping.containsKey(fd.sfieldKeyword)) {
                                    Integer idix = namesKeywordMapping.get(fd.sfieldKeyword); //change by Surabhi for SFHL-1883
                                    
                                    // Mother Name keywords
                                    if (fd.sfieldKeyword.startsWith('AF21')) {
                                        if (idix < mothersNames.size()) { //change by Surabhi for SFHL-1883
                                            fd.sfieldValue = mothersNames[idix]; //change by Surabhi for SFHL-1883
                                        }
                                    }
                                    
                                    // Father Name keywords
                                    else if (fd.sfieldKeyword.startsWith('AF22')) {
                                        if (idix < fathersNames.size()) { //change by Surabhi for SFHL-1883
                                            fd.sfieldValue = fathersNames[idix]; //change by Surabhi for SFHL-1883
                                        }
                                    }
                                }
                                
                                //Testing
                                // if (fd.sfieldKeyword == 'IF63') {
                                    //     fd.sfieldValue = 'true';
                                // }
                                
                                //change by Surabhi for SFHL-1883 - start
                                // HL LEGXT FIELD OVERRIDE (MODTT10 series) - SFHL-1883
                                if (isHlRelated && fd.sfieldKeyword != null && fd.sfieldKeyword.startsWith('MODTT10')) {
                                    
                                    // Ignore sub-sections (_1, _2)
                                    if (!fd.sfieldKeyword.startsWith('MODTT10_1') &&
                                    !fd.sfieldKeyword.startsWith('MODTT10_2')) {
                                        
                                        Integer idxx = extractIndex(fd.sfieldKeyword);
                                        
                                        if (docIndexMap.containsKey(idxx)) {
                                            fd.sfieldValue = String.valueOf(idxx + 1); // Sr No
                                        } else {
                                            fd.sfieldValue = '';
                                        }
                                    }
                                }
                                
                                // HL LEGXT FIELD OVERRIDE (MODTT10_2 series) - SFHL-1883
                                if (isHlRelated && fd.sfieldKeyword != null && fd.sfieldKeyword.startsWith('MODTT10_1')) {
                                    
                                  Integer indx = extractIndex(fd.sfieldKeyword);
                                    
                                    if (docIndexMap.containsKey(indx)) {
                                        fd.sfieldValue = String.valueOf(
                                            docIndexMap.get(indx).Document_Date_of_Receipt__c
                                            );
                                    } else {
                                        fd.sfieldValue = '';
                                    }
                                    
                                    System.debug('Approved name Mapping → ' + fd.sfieldKeyword + ' → ' + fd.sfieldValue);
                                }
                                if (isHlRelated && fd.sfieldKeyword != null && fd.sfieldKeyword.startsWith('MODTT10_2')) {
                                    
                                   Integer idex = extractIndex(fd.sfieldKeyword);
                                    
                                    if (docIndexMap.containsKey(idex)) {
                                        fd.sfieldValue = docIndexMap.get(idex).Remarks__c;
                                    } else {
                                        fd.sfieldValue = '';
                                    }
                                    
                                    System.debug('DESC → ' + fd.sfieldKeyword + ' → ' + fd.sfieldValue);
                                }
                                
                                if (isHlRelated && fd.sfieldKeyword != null && fd.sfieldKeyword.startsWith('MODTT11')) {
                                    
                                    Integer idxe = extractIndex(fd.sfieldKeyword);
                                    
                                    if (docIndexMap.containsKey(idxe)) {
                                        fd.sfieldValue = docIndexMap.get(idxe).Nature_of_Document__c;
                                    } else {
                                        fd.sfieldValue = '';
                                    }
                                    
                                    System.debug('Approved date Mapping → ' + fd.sfieldKeyword + ' → ' + fd.sfieldValue);
                                }
                                //change by Surabhi for SFHL-1883 - end
                                //change by Kunal Bisht for SFHL-1743 - start
                                if (ownContributionFields.contains(fd.sfieldKeyword) && !isOCRAllowed) {
                                    fd.sfieldValue = '';
                                }
                                //change by Kunal Bisht for SFHL-1743 - end
                                //change by Surabhi for SFHL-1883 - start
                                if((fd.sfieldKeyword == 'MODTK5' || fd.sfieldKeyword == 'MODTK6') && String.isNotBlank(sanctionedAmount)){
                                    fd.sfieldValue = sanctionedAmount;
                                }
                                
                                if(fd.sfieldKeyword == 'MODTK8'){
                                    List<Loan_Transaction__c> ltlist = [SELECT Loan_Application__r.Name, Interest_Due_date__c FROM Loan_Transaction__c WHERE Loan_Application__c =: loanAppId AND RecordType.Name = 'Transaction Details'];
                                    if(!ltlist.isEmpty()){
                                        fd.sfieldValue = ltlist[0].Interest_Due_date__c;
                                    }
                                }
                                //change by Surabhi for SFHL-1883 - end
                                fdList.add(fd);
                            }
                            uploadDoc.fieldData = fdList;
                        }
                    }
                    uploadDoc.fieldData = fdList;
                    uploadDocList.add(uploadDoc);
                }
                docGenPreviewRequest.digiUploadDocumentsDto = uploadDocList;
                docGenPreviewRequest.lan =  slan;                //'LA-000000384';
                if (isMultiProduct) {
                    docGenPreviewRequest.loanId = childLoanId;
                } else {
                    docGenPreviewRequest.loanId = loanId;
                }
                
                docGenPreviewRequest.docType = docType;
                //Dont deploy  to prod
                //docGenPreviewRequest.productType = 'AHLHL';
                
                return docGenPreviewRequest;
            }
            
            public static string getLogicalValue(string slogicalvalue, List<sObject> objRecord, string logicalOperator, Document_Template_New__mdt dmdt)
            {
                for(sObject so : objRecord)
                {
                    switch on logicalOperator{
                        when 'Comma'{
                            slogicalvalue = (dmdt.Object_Field_Name__c != null && dmdt.Object_Field_Name__c.contains('.')) ? string.ValueOf(getValueFromRelation(so, dmdt.Object_Field_Name__c)) +  ',' + slogicalvalue : so.get(dmdt.Object_Field_Name__c) +  ',' + slogicalvalue;
                        }
                        when 'Addition'{
                            string val      = (dmdt.Object_Field_Name__c != null && dmdt.Object_Field_Name__c.contains('.')) ? string.ValueOf(getValueFromRelation(so, dmdt.Object_Field_Name__c)) : string.valueOf(so.get(dmdt.Object_Field_Name__c));
                            slogicalvalue   = (slogicalvalue != null && slogicalvalue !='') ? String.valueOf(Decimal.valueOf(slogicalvalue) + Decimal.valueOf(val)) :  String.valueOf(Decimal.valueOf(val));
                        }
                    }
                }
                if (slogicalvalue.endsWith(',')) {
                    slogicalvalue = slogicalvalue.substring(0, slogicalvalue.length() - 1);
                }
                return  slogicalvalue;
            }
            
            public static List<sObject> getSObjectRecords(string objName, Id loanId, Id childLoanId, List<Document_Template_New__mdt> documentTemplateKeywords, Integer criteriaNumber)
            {
                String soql                =    '';
                set<string> fields         =    new set<string>();
                string filtercond          =    '';
                filtercond                 =    getFieldNames(objName, filtercond, fields, documentTemplateKeywords, criteriaNumber);
                
                if (getChildSpecificObjects().contains(objName) && childLoanId != null) {
                    soql   =    'SELECT ' +  String.join(fields, ',') + ' FROM '+objName+' Where '+ filtercond+' =   \'' +String.escapeSingleQuotes(childLoanId)+ '\'';
                } else if (objName.toLowerCase() == 'application_applicant__c') {
                    soql   =    'SELECT ' +  String.join(fields, ',') + ' FROM '+objName+' Where '+ filtercond+' =   \'' +String.escapeSingleQuotes(loanId)+ '\'' +' ORDER BY CreatedDate ASC';
                } else {
                    soql   =    'SELECT ' +  String.join(fields, ',') + ' FROM '+objName+' Where '+ filtercond+' =   \'' +String.escapeSingleQuotes(loanId)+ '\'';
                }
                
                
                system.debug('soql line 318 -->  '+soql);
                return Database.query(soql);
            }
            
            public static string getFieldNames (string objName, string filtercond, set<string> fields,  List<Document_Template_New__mdt> documentTemplateKeywords, Integer criteriaNumber)
            {
                for(Document_Template_New__mdt tempMD : documentTemplateKeywords){
                    if(tempMD.Object_Name__c == objName && tempMD.Criteria_Number__c == criteriaNumber)
                    {
                        fields.add(tempMD.Object_Field_Name__c);
                        filtercond  =  tempMD.criteria__c;
                    }
                }
                return filtercond;
            }
            
            public static Object getValueFromRelation(sObject record, String path) {
                List<String> pathParts = path.split('\\.');
                while(pathParts.size() > 1 && record != null) {
                    record = record.getSObject(pathParts.remove(0));
                }
                Object result = record?.get(pathParts[0]);
                if(result == null) {
                    result = '';
                }
                return result;
            }
            
            public static Map<String, String> getPrefixMap() {
                return new Map<String, String>{
                    'HDFC' => 'Insurance Form',
                    // 'DECL' => 'Declaration',
                    'CERT' => 'Certificate',
                    'Aadhaar Front' => 'Aadhaar',
                    'Aadhaar Back' => 'Aadhaar',
                    // 'CUSTOMERDETAILS' => 'Customer Details',
                    'Passport Front' => 'Passport',
                    'Passport Back' => 'Passport',
                    'Voter Front' => 'Voter ID',
                    'Voter Back' => 'Voter ID',
                    'Driving licence' => 'Driving licence',
                    'Letter issued by the National Population Register' => 'Population Reg',
                    'Utility bill less than 2 months old' => 'Utility Bill',
                    'Bank Statement' => 'Bank Statement',
                    'Notarised Rent Agreement' => 'Rent Agreement',
                    'Certificate of Incorporation' => 'Incorporation Cert',
                    'AOA' => 'AOA',
                    'Resolution from board of directors' => 'Resolution directors',
                    'Name and designation of the relevant person holding senior management position' => 'Senior',
                    'MOA' => 'MOA',
                    'Power of Attorney' => 'Power of Attorney',
                    'Job card issued by NREGA' => 'NREGA JOB CARD',
                    'Pension or Pension payment order' => 'Pension',
                    'Letter of allotment of accomodation' => 'Accomodation Letter',
                    'Registered Rent Agreement' => 'Reg. Rent Agreement'
                };
            }
            
            public static Map<String, List<String>> getFieldMapping() {
                return new Map<String, List<String>>{
                    //Type of loan
                    'Affordable Home Loan' => new List<String>{'AF2', 'IF63'},
                    'Home Loan'            => new List<String>{'AF2', 'IF63'},
                    'Affordable Non-Home Loan' => new List<String>{'AF2_1'},
                    //remaining checkbox values not present in SF
                    
                    //Type of interest
                    'Floating'   => new List<String>{'AF3_2'},
                    'Semi-fixed' => new List<String>{'AF3'},
                    //remaining checkbox values not present in SF
                    
                    //Purpose of Loan
                    'Home Loan Builder Purchase' => new List<String>{'AF4'},
                    'Home Loan Resale' => new List<String>{'AF4_1'},
                    'Plot purchase only' => new List<String>{'AF4_2'},
                    'Plot plus construction loan' => new List<String>{'AF4_3'},
                    'Loan Enhancement under HL' => new List<String>{'AF4_4'},
                    'Flexi Loan Family Expenses' => new List<String>{'AFL2'},
                    'Flexi Loan Personal Expenses' => new List<String>{'AFL2_1'},
                    'Flexi Loan Consumer Durable' => new List<String>{'AFL2_2'},
                    'Balance Transfer & Top-up' => new List<String>{'LAHLCL12_6'},
                    'Balance Transfer' => new List<String>{'LAHLCL12_6'},
                    'Balance Transfer + Top up' => new List<String>{'LAHLCL12_6'},
                    'Home Construction on plot' => new List<String>{'LAHLCL12_4'},
                    'Renovation/ Expansion of Existing Dwelling Units' => new List<String>{'LAHLCL12_5'},
                    'Plot plus construction loan' => new List<String>{'LAHLCL12_3'},
                    'Plot purchase for construction of home' => new List<String>{'LAHLCL12_3'},
                    'Home Construction-Loan' => new List<String>{'LAHLCL12_2'},
                    'Home Loan- Builder Purchase' => new List<String>{'LAHLCL12_3'},
                    'NACH' => new List<String>{'AF3'},
                    'DDM' => new List<String>{'AF3'},
                    'ECS' => new List<String>{'AF3'},
                    'Manual' => new List<String>{'AF3'},
                    'Semi-fixed' => new List<String>{'AF3'},
                    
                    //Loan facility type
                    'Regular'   => new List<String>{'AF5'},
                    'Morat'   => new List<String>{'AF5_1'},
                    //Sub product
                    
                    //Applicant Details
                    'Primary Applicant'    => new List<String>{'AF7', 'AFL3', 'IF72'},
                    'Co Applicant'         => new List<String>{'AF8_B', 'AF8_C', 'AF8_D', 'AF8_E', 'AF8_F', 'AFL4', 'IF72_1'},
                    'Individual'           => new List<String>{'AF9', 'AF9_B', 'AF9_C', 'AF9_D', 'AF9_E', 'AF9_F', 'AFL5', 'AFL5_1'},
                    'Non Individual'       => new List<String>{'AF10', 'AF10_B', 'AF10_C', 'AF10_D', 'AF10_E', 'AF10_F', 'AFL6', 'AFL6_1'},
                    
                    //Salutation map
                    'Mr.'    => new List<String>{'AF15', 'AF15_4', 'AF15_8', 'AF15_12', 'AF15_16', 'AF15_20', 'AFL9', 'AFL9_4'},
                    'Ms.'    => new List<String>{'AF15_1', 'AF15_5', 'AF15_9', 'AF15_13', 'AF15_17', 'AF15_21', 'AFL9_1', 'AFL9_5'},
                    'Mrs.'   => new List<String>{'AF15_2', 'AF15_6', 'AF15_10', 'AF15_14', 'AF15_18', 'AF15_22', 'AFL9_2', 'AFL9_6'},
                    'M/s.'   => new List<String>{'AF15_3', 'AF15_7', 'AF15_11', 'AF15_15', 'AF15_19', 'AF15_23', 'AFL9_3', 'AFL9_7'},
                    
                    // Gender map
                    'Male'   => new List<String>{'AF23', 'AF23_3','AF23_6','AF23_9','AF23_12','AF23_15', 'IF55_1'},
                    'Female' => new List<String>{'AF23_1', 'AF23_4','AF23_7','AF23_10','AF23_13','AF23_16', 'IF55_2'},
                    'Others' => new List<String>{'AF23_2', 'AF23_5','AF23_8','AF23_11','AF23_14','AF23_17'},
                    'Transgender' => new List<String>{'IF55_3'},
                    'Others' => new List<String>{'AF23_2', 'AF23_5'},
                    
                    //Occupation Category
                    'Salaried' => new List<String>{'AF28', 'AF28_8', 'AF28_16', 'AF28_24', 'AF28_33', 'AF28_40', 'IF60'},
                    'SEP' => new List<String>{'AF28_1', 'AF28_9', 'AF28_17', 'AF28_25', 'AF28_32', 'AF28_41', 'IF60_1'},
                    'SENP' => new List<String>{'AF28_2', 'AF28_10', 'AF28_18', 'AF28_26', 'AF28_34', 'AF28_42'},
                    'Salaried Indian' => new List<String>{'AF28', 'AF28_8', 'AF28_16', 'AF28_24', 'AF28_33', 'AF28_40', 'IF60'},
                    
                    //Nationality
                    'Indian' => new List<String>{'IF56'},
                    
                    //Ex-service man map/
                    'Yes'    => new List<String>{'AF29','AF29_2','AF29_4','AF29_6','AF29_8','AF29_10', 'AF61_1', 'AF61_3'},
                    'No'  => new List<String>{'AF29_1', 'AF29_3','AF29_5','AF29_7','AF29_9','AF29_11'},
                    
                    //Marital Status
                    'Single' => new List<String>{'AF30', 'AF30_4', 'AF30_8', 'AF30_12', 'AF30_16', 'AF30_20'},
                    'Married' => new List<String>{'AF30_1', 'AF30_5', 'AF30_9', 'AF30_13', 'AF30_17', 'AF30_21'},
                    'Widowed' => new List<String>{'AF30_2', 'AF30_6', 'AF30_10', 'AF30_14', 'AF30_18', 'AF30_22'},
                    'Divorced' => new List<String>{'AF30_3', 'AF30_7', 'AF30_11', 'AF30_15', 'AF30_19', 'AF30_23'},
                    'Original' => new List<String>{
                        'LAHLCL37_1','LAHLCL37_3','LAHLCL37_5','LAHLCL37_7','LAHLCL37_9',
                        'LAHLCL37_11','LAHLCL37_13','LAHLCL37_15','LAHLCL37_17','LAHLCL37_19',
                        'LAHLCL37_21','LAHLCL37_23','LAHLCL37_25','LAHLCL37_27','LAHLCL37_29',
                        'LAHLCL37_31','LAHLCL37_33','LAHLCL37_35','LAHLCL37_37','LAHLCL37_39',
                        'LAHLCL37_41','LAHLCL37_43','LAHLCL37_45','LAHLCL37_47','LAHLCL37_49',
                        'LAHLCL37_51','LAHLCL37_53','LAHLCL37_55'
                    },
                    'Photocopy' => new List<String>{
                        'LAHLCL37_2','LAHLCL37_4','LAHLCL37_6','LAHLCL37_8','LAHLCL37_10',
                        'LAHLCL37_12','LAHLCL37_14','LAHLCL37_16','LAHLCL37_18','LAHLCL37_20',
                        'LAHLCL37_22','LAHLCL37_24','LAHLCL37_26','LAHLCL37_28','LAHLCL37_30',
                        'LAHLCL37_32','LAHLCL37_34','LAHLCL37_36','LAHLCL37_38','LAHLCL37_40',
                        'LAHLCL37_42','LAHLCL37_44','LAHLCL37_46','LAHLCL37_48','LAHLCL37_50',
                        'LAHLCL37_52','LAHLCL37_54','LAHLCL37_56'
                    },
                    
                    //Disability
                    'Physically Challenged' => new List<String>{'AF32', 'AF32_2', 'AF32_4', 'AF32_6', 'AF32_8', 'AF32_10'},
                    'Visually Challenged' => new List<String>{'AF32_1', 'AF32_3', 'AF32_5', 'AF32_7', 'AF32_9', 'AF32_11'},
                    
                    //Education/Qualification
                    //12th
                    'Under Graduate' => new List<String>{'AF33_1', 'AF33_6', 'AF33_11', 'AF33_16', 'AF33_21', 'AF33_26'},
                    //Graduation
                    'Graduate' => new List<String>{'AF33_7', 'AF33_2'},
                    'CA' => new List<String>{'AF33_7', 'AF33_2', 'AF33_12', 'AF33_17', 'AF33_22', 'AF33_27'},
                    'BDS' => new List<String>{'AF33_7', 'AF33_2', 'AF33_12', 'AF33_17', 'AF33_22', 'AF33_27'},
                    'BHMS' => new List<String>{'AF33_7', 'AF33_2', 'AF33_12', 'AF33_17', 'AF33_22', 'AF33_27'},
                    'BAMS' => new List<String>{'AF33_7', 'AF33_2', 'AF33_12', 'AF33_17', 'AF33_22', 'AF33_27'},
                    //Post Graduate and above
                    'Post Graduate' => new List<String>{'AF33_3', 'AF33_8', 'AF33_13', 'AF33_18', 'AF33_23', 'AF33_28'},
                    'MBBS' => new List<String>{'AF33_3', 'AF33_8', 'AF33_13', 'AF33_18', 'AF33_23', 'AF33_28'},
                    'MD' => new List<String>{'AF33_3', 'AF33_8', 'AF33_13', 'AF33_18', 'AF33_23', 'AF33_28'},
                    'MS' => new List<String>{'AF33_3', 'AF33_8', 'AF33_13', 'AF33_18', 'AF33_23', 'AF33_28'},
                    'MDS' => new List<String>{'AF33_3', 'AF33_8', 'AF33_13', 'AF33_18', 'AF33_23', 'AF33_28'},
                    'Doctor of Medicine (DM)' => new List<String>{'AF33_3', 'AF33_8', 'AF33_13', 'AF33_18', 'AF33_23', 'AF33_28'},
                    'Master of Chirurgiae (M.Ch)' => new List<String>{'AF33_3', 'AF33_8', 'AF33_13', 'AF33_18', 'AF33_23', 'AF33_28'},
                    //diploma or professional qualification
                    'Diploma' => new List<String>{'AF33_4', 'AF33_9','AF33_14', 'AF33_19','AF33_24', 'AF33_29'},
                    'Diplomate National Board (DNB)' => new List<String>{'AF33_4', 'AF33_9','AF33_14', 'AF33_19','AF33_24', 'AF33_29'},
                    'Doctor of Medicine (DM)' => new List<String>{'AF33_4', 'AF33_9','AF33_14', 'AF33_19','AF33_24', 'AF33_29'},
                    'Others' => new List<String>{'AF33_4', 'AF33_9','AF33_14', 'AF33_19','AF33_24', 'AF33_29'},
                    
                    //Cast category
                    'SC'   => new List<String>{'AF35', 'AF36', 'AF36_5', 'AF36_10', 'AF36_15', 'AF36_20', 'AFL29', 'AFL29_5'},
                    'ST'   => new List<String>{'AF35_1', 'AF36_1', 'AF36_6', 'AF36_11', 'AF36_16', 'AF36_21', 'AFL29_1', 'AFL29_6'},
                    'General' => new List<String>{'AF35_2', 'AF36_2', 'AF36_7', 'AF36_12', 'AF36_17', 'AF36_22', 'AFL29_2', 'AFL29_7'},
                    'Others' => new List<String>{'AF35_3', 'AF36_3', 'AF36_8', 'AF36_13', 'AF36_18', 'AF36_23', 'AFL29_3', 'AFL29_8'},
                    
                    //Ownership/Current Residence
                    'Self Owned' => new List<String>{'AF50', 'AF50_4', 'AF50_8', 'AF50_12', 'AF50_16', 'AF50_20'},
                    'Rented' => new List<String>{'AF50_2', 'AF50_6', 'AF50_10', 'AF50_14', 'AF50_18', 'AF50_22'},
                    
                    //Employment Details
                    //If Salaried or SEP
                    'Permanent' => new List<String>{'AF72','AF72_5','AF72_10','AF72_15','AF72_20','AF72_25'},
                    'Contractual' => new List<String>{'AF72_2','AF72_7','AF72_12','AF72_17','AF72_22','AF72_27', 'AF80_1', 'AF80_3'},
                    
                    //Entity Type
                    'Proprietorship' => new List<String>{'AF90', 'AF90_7', 'AF90_14', 'AF90_21', 'AF90_28', 'AF90_35'},
                    'Partnership' => new List<String>{'AF90_1', 'AF90_8', 'AF90_15', 'AF90_22', 'AF90_29', 'AF90_36'},
                    'LLP' => new List<String>{'AF90_2', 'AF90_9', 'AF90_16', 'AF90_23', 'AF90_30', 'AF90_37'},
                    'Private Limited' => new List<String>{'AF90_3', 'AF90_10', 'AF90_17', 'AF90_24', 'AF90_31', 'AF90_38'},
                    'HUF' => new List<String>{'AF90_4', 'AF90_11', 'AF90_18', 'AF90_25', 'AF90_32', 'AF90_39'},
                    
                    //Form 60
                    'Yes'    => new List<String>{'AF61_1', 'AF61_3', 'AF61_5', 'AF61_7', 'AF61_9', 'AF61_11'},
                    
                    //Property Details
                    'UNDER CONSTRUCTION' => new List<String>{'AF109'}, //Status of Property
                    'VACANT' => new List<String>{'AF109_1'}, //Status of Property
                    'RENTED' => new List<String>{'AF109_2'}, //Status of Property
                    'SELF OCCUPIED' => new List<String>{'AF109_3'}, //Status of Property
                    'RESIDENTIAL' => new List<String>{'AF108'}, //Property Type
                    'COMMERCIAL' => new List<String>{'AF108_1'}, //Property Type
                    'PLOT' => new List<String>{'AF108_2'}, //Property Type
                    
                    //Account Type'
                    'Saving' => new List<String>{'AF154', 'AF154_5', 'AF154_15', 'AF154_20', 'AF154_25', 'AF154_30'},
                    'Current' => new List<String>{'AF154_1', 'AF154_6', 'AF154_16', 'AF154_21', 'AF154_26', 'AF154_31'},
                    'Overdraft' => new List<String>{'AF154_2', 'AF154_7', 'AF154_17', 'AF154_22', 'AF154_27', 'AF154_32'},
                    'CC' => new List<String>{'AF154_2', 'AF154_7', 'AF154_18', 'AF154_23', 'AF154_28', 'AF154_33'},
                    
                    //Interest Due Date
                    '03' => new List<String>{'LAHLCL70'},
                    '06' => new List<String>{'LAHLCL70_1'}
                };
            }
            
            public static List<String> getSpecialFields() {
                return new List<String>{
                    //AHL APP FORM
                    'AF4_5', 'AF74', 'AF74_2', 'AF74_4', 'AF74_6', 'AF74_8', 'AF74_10',
                    'AF108_3', 'AF109_4', 'AF90_5', 'AF90_12', 'AF90_19', 'AF90_26', 'AF90_33', 'AF90_40', 'AF5_2',
                    //FL APP FORM
                    'AFL2_3',
                    //ABIF
                    'IF60_4'
                };
            }
            
            public static List<String> getPrimaryAddressFields(){
                List<String> fields = new List<String>{
                    'AF38', 'AF39', 'AF40', 'AF41', 'AF42', 'AF43', 'AF44', 'AF45',
                    'AF68',  'AF69', 'LAHLCL6', 'LAHLCL8', 'LAHLCL8_2', 'LAHLCL8_4',
                    'LAFLCL109', 'LAFLCL111', 'LAFLCL111_1', 'LAFLCL111_2' //change by Kunal Bisht for SFHL-1743
                };
                
                // Add _1 through _5 for AF38 – AF45
                for (Integer i = 1; i <= 5; i++) {
                    fields.add('AF38_' + i);
                    fields.add('AF39_' + i);
                    fields.add('AF40_' + i);
                    fields.add('AF41_' + i);
                    fields.add('AF42_' + i);
                    fields.add('AF43_' + i);
                    fields.add('AF44_' + i);
                    fields.add('AF45_' + i);
                    fields.add('AF68_' + i);
                    fields.add('AF69_' + i);
                }
                
                return fields;
            }
            
            public static List<String> getIncomeObligationFields(){
                return new List<String>{
                    'AF148', 'AF148_1', 'AF148_2', 'AF148_3', 'AF148_4',
                    'AF149', 'AF149_1', 'AF149_2', 'AF149_3', 'AF149_4',
                    'AF150', 'AF150_1', 'AF150_2', 'AF150_3', 'AF150_4',
                    'AF151', 'AF151_1', 'AF151_2', 'AF151_3', 'AF151_4'
                };
            }
            
            public static List<String> getOwnContributionFields() {
                return new List<String>{
                    'LAHLCL85', 'LAHLCL86', 'LAHLCL87', 'LAHLCL88', 'LAHLCL89', 'LAHLCL89_1',
                    'LAHLCL90', 'LAHLCL91', 'LAHLCL92', 'LAHLCL92_1', 'LAHLCL92_2', 'LAHLCL92_3',
                    'LAHLCL92_4', 'LAHLCL92_5', 'LAHLCL92_6', 'LAHLCL92_7', 'LAHLCL92_8', 'LAHLCL92_9',
                    'LAHLCL92_10', 'LAHLCL92_11', 'LAHLCL92_12', 'LAHLCL92_13', 'LAHLCL92_14', 'LAHLCL92_15',
                    'LAHLCL93', 'LAHLCL94', 'LAHLCL94_1', 'LAHLCL95', 'LAHLCL96', 'LAHLCL97',
                    'LAHLCL98'
                };
            }
            
            public static Map<String, Integer> getNamesKeywordMapping() {
                return new Map<String, Integer>{
                    'AF21'   => 0,
                    'AF21_B' => 1,
                    'AF21_C' => 2,
                    'AF21_D' => 3,
                    'AF21_E' => 4,
                    'AF21_F' => 5,
                    'AF22'   => 0,
                    'AF22_B' => 1,
                    'AF22_C' => 2,
                    'AF22_D' => 3,
                    'AF22_E' => 4,
                    'AF22_F' => 5
                };
            }
            
            public static Map<String, List<Applicant_Address__c>> fetchApplicantAddresses(Id loanId) {
                // Map<String, Applicant_Address__c> selectedAddresses = new Map<String, Applicant_Address__c>();
                Map<String, List<Applicant_Address__c>> selectedAddresses = new Map<String, List<Applicant_Address__c>>();

                Map<Id,Application_Applicant__c> mapOfApplicants = new Map<Id,Application_Applicant__c>([select id, name from Application_Applicant__c where Loan_Application__c =: loanId]); //added by Kunal Bisht for SFHL-1743
                
                List<Applicant_Address__c> addressList = [
            SELECT Id, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Full_Address1__c, Landmark__c, City__c, State__c, Pincode__r.Name, Applicant__r.Applicant_Type__c,
                Applicant__r.Aadhaar_Number__c, Applicant__r.Masked_Aadhar_Number__c, Applicant__r.Passport_Number__c, Applicant__r.Voter_ID_Number__c, Applicant__r.Drivers_License_Number__c, 
                Address_Type__c, Address_Priority__c, Flag_Current_Registred_as_Very_High__c, Flag_PO_as_High__c, Document_Details__r.Name,  Applicant__r.Customer_Type__c, Applicant__r.Customer_Profile__c
            FROM Applicant_Address__c
            WHERE Applicant__c IN : mapOfApplicants.keyset() ORDER BY Applicant__r.CreatedDate ASC //change by Kunal Bisht for SFHL-1743
        ];
                
                Map<String, String> inputMap = new Map<String, String>();
                inputMap.put('oppId', loanId);
                Utility_V1.ProductWrapper productWrapper = Utility_V1.getProductDetails(inputMap);
                Boolean isHlRelated = (productWrapper.loanProduct == 'Home Loan');
                
                for (Applicant_Address__c addr : addressList) {
                    String applicantType = addr.Applicant__r.Applicant_Type__c;
                    String customerType = addr.Applicant__r.Customer_Type__c;
                    String addressType = addr.Address_Type__c;
                    String empType = addr.Applicant__r.Customer_Profile__c;
                    system.debug('empType'+ empType);
                    system.debug('addressType'+ addressType);
                    if (addr.Address_Priority__c == '5' && addr.Flag_Current_Registred_as_Very_High__c == true) {
                        if (applicantType == 'Primary Applicant') {
                            if (customerType == 'Non Individual' && addressType == 'Registered Office') {
                                if (!selectedAddresses.containsKey('Primary_NonIndividual')) {
                                    selectedAddresses.put('Primary_NonIndividual', new List<Applicant_Address__c>());
                                }
                                selectedAddresses.get('Primary_NonIndividual').add(addr);
                            }
                        } else if (applicantType == 'Co Applicant') {
                            if (customerType == 'Non Individual' && addressType == 'Registered Office') {
                                if (!selectedAddresses.containsKey('CoApp_Address')) {
                                    selectedAddresses.put('CoApp_Address', new List<Applicant_Address__c>());
                                }
                                selectedAddresses.get('CoApp_Address').add(addr);
                            }
                        }
                    }
                    
                    if ((!isHlRelated && addr.Address_Priority__c == '4') || (isHlRelated && addr.Address_Priority__c == '5')/*&& addr.Flag_PO_as_High__c == true*/) {//change by Kunal Bisht for SFHL-1743
                        if (applicantType == 'Primary Applicant') {
                            if (customerType == 'Individual' && ((addressType == 'Permanent' && !isHlRelated) || (addressType == 'Current' && isHlRelated))) {
                                if (!selectedAddresses.containsKey('Primary_Individual')) {
                                    selectedAddresses.put('Primary_Individual', new List<Applicant_Address__c>());
                                }
                                selectedAddresses.get('Primary_Individual').add(addr);
                            }
                            //change by Kunal Bisht for SFHL-1743 - start
                            if (customerType == 'Individual') {
                                if (!selectedAddresses.containsKey('Primary_Individual_Very_High_Priority')) {
                                    selectedAddresses.put('Primary_Individual_Very_High_Priority', new List<Applicant_Address__c>());
                                }
                                selectedAddresses.get('Primary_Individual_Very_High_Priority').add(addr);
                            }
                            //change by Kunal Bisht for SFHL-1743 - end
                        }else if (applicantType == 'Co Applicant') {
                            if (customerType == 'Individual' && ((addressType == 'Permanent' && !isHlRelated) || (addressType == 'Current' && isHlRelated))) {
                                if (!selectedAddresses.containsKey('CoApp_Address')) {
                                    selectedAddresses.put('CoApp_Address', new List<Applicant_Address__c>());
                                }
                                selectedAddresses.get('CoApp_Address').add(addr);
                            }
                            //change by Kunal Bisht for SFHL-1743 - start
                            if (customerType == 'Individual') {
                                if (!selectedAddresses.containsKey('CoApp_Address_Very_High_Priority')) {
                                    selectedAddresses.put('CoApp_Address_Very_High_Priority', new List<Applicant_Address__c>());
                                }
                                selectedAddresses.get('CoApp_Address_Very_High_Priority').add(addr);
                            }
                            //change by Kunal Bisht for SFHL-1743 - end
                        }
                    }
                    
                    // String keyName;
                    
                    // if (addr.Address_Priority__c == '5' && addr.Flag_Current_Registred_as_Very_High__c) {
                        //     if (customerType == 'Non Individual' && addressType == 'Registered Office') {
                            //         keyName = (applicantType == 'Primary Applicant') ? 'Primary_NonIndividual' : 'CoApp_Address';
                        //     }
                    // }
                    // else if (addr.Address_Priority__c == '4' && addr.Flag_PO_as_High__c) {
                        //     if (customerType == 'Individual' && addressType == 'Permanent') {
                            //         keyName = (applicantType == 'Primary Applicant') ? 'Primary_Individual' : 'CoApp_Address';
                        //     }
                    // }
                    
                    // if (keyName != null) {
                        //     if (!selectedAddresses.containsKey(keyName)) {
                            //         selectedAddresses.put(keyName, new List<Applicant_Address__c>());
                        //     }
                        //     selectedAddresses.get(keyName).add(addr);
                    // }
                    
                    
                    if (((empType == 'SEP' || empType == 'SENP') && addressType == 'Office' && !isHlRelated) ||
                    ((empType == 'SEP' || empType == 'SENP') && addressType == 'Registered Office' && isHlRelated)) {
                        if (applicantType == 'Primary Applicant') {
                            if (!selectedAddresses.containsKey('Primary_SEP_SENP')) {
                                selectedAddresses.put('Primary_SEP_SENP', new List<Applicant_Address__c>());
                            }
                            selectedAddresses.get('Primary_SEP_SENP').add(addr);
                            // selectedAddresses.put('Primary_SEP_SENP', addr);
                        } else if (applicantType == 'Co Applicant') {
                            if (!selectedAddresses.containsKey('Co_SEP_SENP')) {
                                selectedAddresses.put('Co_SEP_SENP', new List<Applicant_Address__c>());
                            }
                            selectedAddresses.get('Co_SEP_SENP').add(addr);
                            // selectedAddresses.put('Co_SEP_SENP', addr);
                        }
                    }
                    else if (((empType == 'Salaried Indian' || empType == 'Salaried NRI') && addressType == 'Employee Address' && !isHlRelated) ||
                    ((empType == 'Salaried Indian' || empType == 'Salaried NRI') && addressType == 'Registered Office' && isHlRelated)) {
                        if (applicantType == 'Primary Applicant') {
                            if (!selectedAddresses.containsKey('Primary_Salaried')) {
                                selectedAddresses.put('Primary_Salaried', new List<Applicant_Address__c>());
                            }
                            selectedAddresses.get('Primary_Salaried').add(addr);
                            // selectedAddresses.put('Primary_Salaried', addr);
                        } else if (applicantType == 'Co Applicant') {
                            if (!selectedAddresses.containsKey('Co_Salaried')) {
                                selectedAddresses.put('Co_Salaried', new List<Applicant_Address__c>());
                            }
                            selectedAddresses.get('Co_Salaried').add(addr);
                            // selectedAddresses.put('Co_Salaried', addr);
                        }
                    }
                }
                
                return selectedAddresses;
            }
            
            public static Set<String> getChildSpecificObjects() {
                return new Set<String>{'Bank_Details__c', 'Loan_Transaction__c', 'Product2', 'Opportunity'};
            }
            
            private static List<String> joinNameParts(List<String> parts) {
                List<String> joinedName = new List<String>();
                for (String p : parts) {
                    if (String.isNotBlank(p)) {
                        joinedName.add(p);
                    }
                }
                return joinedName;
            }
            
            //below method added by Surabhi for SFHL-1883
            private static Integer extractIndex(String key) {
                Integer num = 0;
                
                if (key != null && key.contains('_')) {
                    List<String> parts = key.split('_');
                    
                    if (parts.size() == 2) {
                        num = 0; // e.g., MODTT10_1 → 0
                    }
                    else if (parts.size() >= 3) {
                        num = Integer.valueOf(parts[parts.size() - 1]);
                    }
                }
                return num;
            }

            
        }