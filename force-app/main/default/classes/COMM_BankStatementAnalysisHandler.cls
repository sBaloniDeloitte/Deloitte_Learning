public with sharing class COMM_BankStatementAnalysisHandler implements IntegrationInterface {

    static string conLabels = 'BSACallBackURL';
                         
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
    //method to create a sing
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String loanApplicationId = wrapper.loanApplicationId;
        Id totalTenureRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Total Tenure').getRecordTypeId();
      
        List<String> contentVersionIdList = wrapper.contentVersionIdList;
        String applicantId = wrapper.recordId;
        Opportunity opp = [SELECT Id,Account_Type__c,Is_Scanned_File__c,Tenor_Months__c,Requested_Amount__c from Opportunity where id = :loanApplicationId];
        List<Product2> product2List = [SELECT Id,Name from Product2 where Loan_Application__c = :loanApplicationId AND RecordTypeId =:totalTenureRecordTypeId];
        Application_Applicant__c applicant = [SELECT Id, First_Name__c, Last_Name__c, Employment_Type__c,PAN_Number__c from Application_Applicant__c where id =: applicantId];
        Map<String,String> versionToFileName = new Map<String,String>();
        Map<String,String> VersionToDocId = new Map<String,String>();
            List<ContentVersion> cvRecVersionIdList = [Select Id,Title,ContentDocumentId from ContentVersion where Id IN : contentVersionIdList];
            for(ContentVersion cvId : cvRecVersionIdList) {
                versionToFileName.put(cvId.Id,cvId.Title);
                VersionToDocId.put(cvId.Id,cvId.ContentDocumentId);
            }
            List<Document_Details__c> docDetailsList = [SELECT Id, Name, Content_Document_Id__c,Year_Month_From__c,Year_month_to__c,Bank_Branch_Master__c,
                Bank_Branch_Master__r.Bank__r.Perfios_Bank_Name__c, is_internal_bsa__c, aa_json_contentid__c 
                FROM Document_Details__c 
                WHERE Content_Document_Id__c IN :VersionToDocId.values() 
            ];
        if(String.isBlank(applicantId) || String.isBlank(loanApplicationId)){
            errorMessages.add('Error: Applicant Id is missing');
        }
       
        if(product2List.isEmpty()) {
            errorMessages.add('Error: Loan Tenor is Missing');
        }
        if(opp.Requested_Amount__c==null){
            errorMessages.add('Error: Requested Amount is Missing');
        }
        if(applicant.Employment_Type__c==null){
            errorMessages.add('Error: Employement Type is Missing');
        }
        if(docDetailsList[0].Year_Month_From__c==null || docDetailsList[0].Year_Month_To__c==null){
            errorMessages.add('Error: To or From Years are missing');
        }
        return errorMessages;
    }
    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        try {
            List<String> errorMessages = new List<String>();
            String loanApplicationId = wrapper.loanApplicationId;
            List<String> contentVersionIdList = wrapper.contentVersionIdList;
            String applicantId = wrapper.recordId;
            Map<String,String> versionToFileName = new Map<String,String>();
            Map<String,String> versiontoExtension = new Map<String,String>();
            Map<id, Document_Details__c> idToDocMap = new Map<id, Document_Details__c>();
             Map<String, Document_Details__c> versionToDocumentMap = new Map<String, Document_Details__c>();
            Map<String,String> VersionToDocId = new Map<String,String>();
            String derivedRecordId =  Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis');
            String xnsRecordId =  Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','XNS');
            
            String selectedTenure;
            Id totalTenureRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Total Tenure').getRecordTypeId();
            List<Product2> product2List = [SELECT Id,Name from Product2 where Loan_Application__c = :loanApplicationId AND RecordTypeId =:totalTenureRecordTypeId];

            if (!product2List.isEmpty()) {
                if (product2List.size() == 1) {
                    selectedTenure = product2List[0].Name;
                } else {
                    Integer maxValue = -1;
                    for (Product2 p : product2List) {
                        Integer numVal = Integer.valueOf(p.Name); 
                        if (numVal > maxValue) {
                            maxValue = numVal;
                            selectedTenure = p.Name;
                        }
                    }
                }
            }
            List<ContentVersion> cvRecVersionIdList = [Select Id,Title,FileExtension,ContentDocumentId,PathOnClient from ContentVersion where Id IN : contentVersionIdList];
            for(ContentVersion cv : cvRecVersionIdList) {
                VersionToDocId.put(cv.Id, cv.ContentDocumentId);
            }
            //   List<ContentVersion> cvRecVersionIdList = [Select Id,Title,ContentDocumentId from ContentVersion where Id ='068Bi000003J0fKIAS'];
           
            List<Id> docIdSet = new List<Id>();
            String accountType = '';
            String manuallAA;
            Boolean internalBSA = false;
            List<Document_Details__c> docDetailsList = [SELECT Id,Manual_AA__c, Name,Account_Type__c, Sanction_Amount__c,Password__c,Content_Document_Id__c,Year_Month_From__c,Year_month_to__c,Institution_Id__c,Bank_Details__c,Drawing_Power_Amount__c,Bank_Details__r.Account_Number__c,
                Bank_Branch_Master__r.Bank__r.Perfios_Bank_Name__c,Bank_Branch_Master__c, is_internal_bsa__c, AA_JSON_ContentId__c 
                FROM Document_Details__c 
                WHERE Content_Document_Id__c IN :VersionToDocId.values() Order By Sanction_Amount__c DESC
            ];
            List<ContentVersion> finalContentVersionList = new  List<ContentVersion>();
            for(Document_Details__c d :docDetailsList){
                accountType = d.Account_Type__c;
                manuallAA = d.Manual_AA__c;
                internalBSA=d.is_internal_bsa__c=='yes'?true:false;
                docIdSet.add(d.id);
            }
            if(internalBSA && manuallAA == 'AA'){
                for(Document_Details__c d :docDetailsList){
                    if(d.aa_json_contentid__c!=null){
list<contentVersion> cvListAA=[Select Id,Title,FileExtension,ContentDocumentId,PathOnClient from ContentVersion where contentDocumentId = :d.aa_JSON_ContentId__c];
for(ContentVersion cv:cvListAA){
    finalContentVersionList.add(cv);
    versiontoExtension.put(cv.Id,cv.FileExtension);
    versionToFileName.put(cv.Id,cv.PathOnClient);
    versionToDocumentMap.put(cv.Id,d);

}
                    }
            }
        }
        else{
            List<String> contentDocumentIdList = new List<String>();
            List<ContentDocumentLink> contentDocLinkList = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink where LinkedEntityId IN :docIdSet];
            for (ContentDocumentLink cont : contentDocLinkList) {
        contentDocumentIdList.add(cont.ContentDocumentId);
}
Map<String,List<ContentVersion>> versionToContDocLink = new  Map<String,List<ContentVersion>>();
             List<ContentVersion> cvRecVersionIdListNew = [Select Id,Title,FileExtension,ContentDocumentId,PathOnClient from ContentVersion where ContentDocumentId IN : contentDocumentIdList];
            for(ContentVersion cvId : cvRecVersionIdListNew) {
               for(ContentDocumentLink contNew : contentDocLinkList){
                    if(contNew.ContentDocumentId == cvId.ContentDocumentId){
                        if(versionToContDocLink.containskey(contNew.LinkedEntityId)){
                            versionToContDocLink.get(contNew.LinkedEntityId).add(cvId);
                        }
                        else{
                             versionToContDocLink.put(contNew.LinkedEntityId, new List<ContentVersion>{cvId});
                        }
                        
                    }
                }
            }
            for(List<ContentVersion> cvList : versionToContDocLink.values()){
                finalContentVersionList.addAll(cvList);
            }
             for(Document_Details__c doc: docDetailsList){
                idToDocMap.put(doc.id,doc);
            }
             
            for(ContentVersion cvId :finalContentVersionList) {
                versionToFileName.put(cvId.Id,cvId.PathOnClient);
                VersionToDocId.put(cvId.Id,cvId.ContentDocumentId);
                versiontoExtension.put(cvId.Id,cvId.FileExtension);
            }
            
            for(String  linkedEntity :versionToContDocLink.keySet()) {
               List<ContentVersion> cvRecVersionIdListDoc = versionToContDocLink.get(linkedEntity);
               for(ContentVersion cv :cvRecVersionIdListDoc){
                    versionToDocumentMap.put(cv.id,idToDocMap.get(linkedEntity));
               }
            }
            
            // Map<String, Document_Details__c> versionToDocumentMap = new Map<String, Document_Details__c>();
           
        }
           String documentDetailsExcel = wrapper.documentDetailsExcel;
           String documentDetailsResponse = wrapper.documentDetailsResponse;
             List<Document_Master__c> docMaster = [Select Id, Name, Requirement_Level__c 
                FROM Document_Master__c where Name = 'Work Experience Proof'];

            //   List<Document_Details__c> docDetailsList = [SELECT Id, Name, Content_Document_Id__c,Year_Month_From__c,Year_month_to__c 
            //     FROM Document_Details__c 
            //     WHERE Content_Document_Id__c ='069Bi000003H2yAIAS'
            // ];
            Opportunity opp = [SELECT Id,Is_Scanned_File__c,Product__c,Account_Type__c,Name,Tenor_Months__c,Sanction_Limit__c,Drawing_Power_Amount__c,Requested_Amount__c from Opportunity where id = :loanApplicationId];
            Application_Applicant__c applicant = [SELECT Id, First_Name__c, Last_Name__c, Employment_Type__c,PAN_Number__c,Customer__c from Application_Applicant__c where id =: applicantId];
            String requestJSON;
            System.debug('opp.Account_Type__c =----'+opp.Account_Type__c);
            String accType;
            if((manuallAA == 'AA' && accountType == 'CURRENT') || (opp.Account_Type__c== 'NONE' && manuallAA != 'AA')){
                accType='Current';
            }
            else if((manuallAA == 'AA' && accountType == 'SAVINGS') || (opp.Account_Type__c== 'Saving Account' && manuallAA != 'AA')){
                accType='Saving';
            }
            else if(opp.Account_Type__c=='OD' && manuallAA != 'AA'){
                accType ='Overdraft Account';
            }
            else if(opp.Account_Type__c=='CC' && manuallAA != 'AA'){
                    accType ='CC';                
            }

            if(accType == 'Current' || accType == 'Saving'){
                System.debug('opp.Account_Type__c =----'+opp.Account_Type__c);
                BankStatementAnalysisRequestWrapperNone bankWrapper = new BankStatementAnalysisRequestWrapperNone();
                bankWrapper.sendToInternalApiFromAA= (internalBSA && manuallAA == 'AA'); 
                bankWrapper.sendToInternalApi=internalBSA;
                bankWrapper.data = new cls_dataNone();
                bankWrapper.data.loanDuration = selectedTenure;
               
                bankWrapper.data.loanType = opp.Product__c;
                bankWrapper.data.employmentType = applicant.Employment_Type__c;
    
                if(applicant.Employment_Type__c == 'Salaried'){
                    bankWrapper.data.employmentType  = applicant.Employment_Type__c;
                }
                else if(applicant.Employment_Type__c == 'SEP' || applicant.Employment_Type__c == 'SENP'){
                    bankWrapper.data.employmentType =  'SelfEmployed';
                }
                bankWrapper.data.processingType  = 'STATEMENT';
                bankWrapper.data.transactionCompleteCallbackUrl = constants.get('BSACallBackURL');
                bankWrapper.data.loanAmount = String.valueof(opp.Requested_Amount__c);
                bankWrapper.data.txnId=null;
                bankWrapper.data.institutionId=null;
                bankWrapper.data.acceptancePolicy = 'atLeastOneTransactionInRange';
                bankWrapper.data.uploadingScannedStatements = String.valueof(wrapper.scannedCopy);
              
    
                // bankWrapper.data.yearMonthFrom = String.valueof(docDetailsList[0].Year_Month_From__c);
                // bankWrapper.data.yearMonthTo = String.valueof(docDetailsList[0].Year_month_to__c);
                bankWrapper.data.facility = 'NONE';
    
                // Date maxFromDate;
                // Date maxToDate;
                // Integer maxMonthDiff = -1;
                bankWrapper.data.lan = opp.Name;
                bankWrapper.data.triggerBy = 'cba';
                bankWrapper.data.fileData = new List<cls_fileData>();
                Date minFromDate = null;
                Date maxToDate = null;

                for (ContentVersion cvIdDate : finalContentVersionList) {
                     Document_Details__c doc = versionToDocumentMap.get(cvIdDate.Id);
                    
                    Date fromDate = doc.Year_Month_From__c;
                    Date toDate = doc.Year_Month_To__c;
                    
                    if (fromDate != null) {
                        if (minFromDate == null || fromDate < minFromDate) {
                            minFromDate = fromDate;
                        }
                    }
                    if (toDate != null) {
                        if (maxToDate == null || toDate > maxToDate) {
                            maxToDate = toDate;
                        }
                    }
                }

                for(ContentVersion cvId : finalContentVersionList) {
                    cls_fileData cs = new cls_fileData();
                    cs.fileName = versionToFileName.get(cvId.Id);
                    cs.password = versionToDocumentMap.get(cvId.Id).Password__c;//docDetailsList[0].Password__c;
                    cs.institutionId = Integer.valueof(versionToDocumentMap.get(cvId.Id).Institution_Id__c);//Integer.valueof(docDetailsList[0].Institution_Id__c);
                    if (minFromDate != null && maxToDate != null) {
                        bankWrapper.data.yearMonthFrom = String.valueOf(minFromDate).substring(0, 7);
                        bankWrapper.data.yearMonthTo = String.valueOf(maxToDate).substring(0, 7);
                    } else {
                        bankWrapper.data.yearMonthFrom = '2024-10';
                        bankWrapper.data.yearMonthTo = '2025-03';
                    }
                    
                    // if ((versionToDocumentMap.get(cvId.ContentDocumentId).Year_Month_From__c != null) && (versionToDocumentMap.get(cvId.ContentDocumentId).Year_Month_To__c != null) ) {
                    //     System.debug('(versionToDocumentMap.get(cvId.ContentDocumentId).Year_Month_From__c---'  + (versionToDocumentMap.get(cvId.ContentDocumentId).Year_Month_From__c));
                    //       System.debug('(versionToDocumentMap.get(cvId.ContentDocumentId).Year_Month_To__c---'  + (versionToDocumentMap.get(cvId.ContentDocumentId).Year_Month_To__c));
                    //     bankWrapper.data.yearMonthFrom = String.valueOf(versionToDocumentMap.get(cvId.ContentDocumentId).Year_Month_From__c).substring(0, 7);
                    //     bankWrapper.data.yearMonthTo = String.valueOf(versionToDocumentMap.get(cvId.ContentDocumentId).Year_Month_To__c).substring(0, 7);
                    // }
                    // else{
                    //     bankWrapper.data.yearMonthFrom ='2024-10';
                    //     bankWrapper.data.yearMonthTo ='2025-03';
                    // }
                  
                    bankWrapper.data.fileData.add(cs);
                }
                bankWrapper.accountDocuments = new List<cls_accountDocuments>();
                for(ContentVersion cvId :finalContentVersionList) {
                    cls_accountDocuments cs = new cls_accountDocuments();
                    cs.fileName = versionToFileName.get(cvId.Id);
                    cs.fileId = cvId.id;
                    // cs.documentChecklistId = versionToDocumentMap.get(cvId.ContentDocumentId).id;
                    // cs.bankName = versionToDocumentMap.get(cvId.ContentDocumentId).Bank_Branch_Master__r.Bank__r.Perfios_Bank_Name__c;
                    // cs.accountType =accType;
                    bankWrapper.accountDocuments.add(cs);
                }
                System.debug('bankWrapper'+ JSON.serialize(bankWrapper));
                bankWrapper.derivedAnalysisRecordTypeId = derivedRecordId;
                bankWrapper.documentDetailIdForIntegrationDetails = documentDetailsResponse;
                bankWrapper.documentDetailIdForExcel = documentDetailsExcel;
                bankWrapper.documentMasterId = docMaster[0].id;
                bankWrapper.applicantId = applicantId;
                bankWrapper.customerId = applicant.Customer__c;
                bankWrapper.xnsRecordTypeId = xnsRecordId;
                System.debug('bankWrapper'+bankWrapper);
                requestJSON = JSON.serialize(bankWrapper);
            }
            else if(accType == 'Overdraft Account'){
                BankStatementAnalysisRequestWrapperOD bankWrapper = new BankStatementAnalysisRequestWrapperOD();
                bankWrapper.sendToInternalApi=internalBSA;
                bankWrapper.sendToInternalApiFromAA= (internalBSA && manuallAA == 'AA'); 
                bankWrapper.data = new cls_dataOD();
                bankWrapper.data.loanDuration = selectedTenure;
                bankWrapper.data.loanType = opp.Product__c;
                bankWrapper.data.employmentType = applicant.Employment_Type__c;
                bankWrapper.data.txnId=null;
                bankWrapper.data.institutionId=null;
                if(applicant.Employment_Type__c == 'Salaried'){
                    bankWrapper.data.employmentType  = applicant.Employment_Type__c;
                }
                else if(applicant.Employment_Type__c == 'SEP' || applicant.Employment_Type__c == 'SENP'){
                    bankWrapper.data.employmentType =  'SelfEmployed';
                }
                bankWrapper.data.processingType  = 'STATEMENT';
                bankWrapper.data.transactionCompleteCallbackUrl = constants.get('BSACallBackURL');
                bankWrapper.data.loanAmount = String.valueof(opp.Requested_Amount__c);
               
                bankWrapper.data.acceptancePolicy = 'atLeastOneTransactionInRange';
                bankWrapper.data.uploadingScannedStatements =String.valueof(wrapper.scannedCopy);
                bankWrapper.data.institutionId  =null;
                // if ((versionToDocumentMap.get(cvId.ContentDocumentId).Year_Month_From__c != null) && (versionToDocumentMap.get(cvId.ContentDocumentId).Year_Month_To__c != null) ) {
                //     bankWrapper.data.yearMonthFrom = String.valueOf(versionToDocumentMap.get(cvId.ContentDocumentId).Year_Month_From__c).substring(0, 7);
                //     bankWrapper.data.yearMonthTo = String.valueOf(versionToDocumentMap.get(cvId.ContentDocumentId).Year_Month_To__c != null).substring(0, 7);
                // }
                // else{
                //     bankWrapper.data.yearMonthFrom ='2024-10';
                //     bankWrapper.data.yearMonthTo ='2025-03';
                // }
    
                // bankWrapper.data.yearMonthFrom = String.valueof(docDetailsList[0].Year_Month_From__c);
                // bankWrapper.data.yearMonthTo = String.valueof(docDetailsList[0].Year_month_to__c);
                bankWrapper.data.facility = 'OD';

                bankWrapper.data.sanctionLimitFixed = true;
                Decimal totalSanctionLimit = 0;
                 Set<Id> processedBankIds = new Set<Id>();

                // bankWrapper.data.sanctionLimitFixedAmount = Integer.valueOf(opp.Sanction_Limit__c);

                
                bankWrapper.data.lan = opp.Name;
                bankWrapper.data.triggerBy = 'cba';
                bankWrapper.data.fileData = new List<cls_fileData>();
                  Date minFromDate = null;
                Date maxToDate = null;

                for (ContentVersion cvIdDate : finalContentVersionList) {
                    Document_Details__c doc = versionToDocumentMap.get(cvIdDate.id);
                    
                    Date fromDate = doc.Year_Month_From__c;
                    Date toDate = doc.Year_Month_To__c;
                     if (!processedBankIds.contains(doc.Bank_Branch_Master__c)) {
                        processedBankIds.add(doc.Bank_Branch_Master__c);
                        if (doc.Sanction_Amount__c != null)
                            totalSanctionLimit += Decimal.valueof(doc.Sanction_Amount__c);
                    }
                    
                    if (fromDate != null) {
                        if (minFromDate == null || fromDate < minFromDate) {
                            minFromDate = fromDate;
                        }
                    }
                    if (toDate != null) {
                        if (maxToDate == null || toDate > maxToDate) {
                            maxToDate = toDate;
                        }
                    }
                }
                bankWrapper.data.sanctionLimitFixedAmount = Integer.valueOf(totalSanctionLimit);
                for(ContentVersion cvId : finalContentVersionList) {
                    cls_fileData cs = new cls_fileData();
                    cs.fileName = versionToFileName.get(cvId.Id);
                    cs.password = versionToDocumentMap.get(cvId.Id).Password__c;//docDetailsList[0].Password__c;
                    cs.institutionId = Integer.valueof(versionToDocumentMap.get(cvId.Id).Institution_Id__c);//Integer.valueof(docDetailsList[0].Institution_Id__c);
                        if (minFromDate != null && maxToDate != null) {
                        bankWrapper.data.yearMonthFrom = String.valueOf(minFromDate).substring(0, 7);
                        bankWrapper.data.yearMonthTo = String.valueOf(maxToDate).substring(0, 7);
                    } else {
                        bankWrapper.data.yearMonthFrom = '2024-10';
                        bankWrapper.data.yearMonthTo = '2025-03';
                    }
                    
        
                    bankWrapper.data.fileData.add(cs);
                }
                bankWrapper.accountDocuments = new List<cls_accountDocuments>();
                for(ContentVersion cvId : finalContentVersionList) {
                       cls_accountDocuments cs = new cls_accountDocuments();
                    cs.fileName = versionToFileName.get(cvId.Id);
                    cs.fileId = cvId.id;
                    // cs.documentChecklistId = versionToDocumentMap.get(cvId.ContentDocumentId).id;
                    // cs.bankName = versionToDocumentMap.get(cvId.ContentDocumentId).Bank_Branch_Master__r.Bank__r.Perfios_Bank_Name__c;
                    // cs.accountType =accType;
                    bankWrapper.accountDocuments.add(cs);
                }
                bankWrapper.derivedAnalysisRecordTypeId = derivedRecordId;
                bankWrapper.documentDetailIdForIntegrationDetails = documentDetailsResponse;
                bankWrapper.documentDetailIdForExcel = documentDetailsExcel;
                bankWrapper.documentMasterId = docMaster[0].id;
                bankWrapper.applicantId = applicantId;
                bankWrapper.customerId = applicant.Customer__c;
                bankWrapper.xnsRecordTypeId = xnsRecordId;
                System.debug('bankWrapper'+bankWrapper);
                requestJSON = JSON.serialize(bankWrapper);
            }
            else if (accType == 'CC') {
                BankStatementAnalysisRequestWrapperCC bankWrapper = new BankStatementAnalysisRequestWrapperCC();
                bankWrapper.sendToInternalApi=internalBSA;
                bankWrapper.sendToInternalApiFromAA= (internalBSA && manuallAA == 'AA'); 
                bankWrapper.data = new cls_dataCC();
                bankWrapper.data.loanDuration = selectedTenure;
                bankWrapper.data.loanType = opp.Product__c;
                bankWrapper.data.employmentType = (applicant.Employment_Type__c == 'Salaried') ? 'Salaried' : 'SelfEmployed';
                bankWrapper.data.processingType = 'STATEMENT';
                bankWrapper.data.transactionCompleteCallbackUrl = constants.get('BSACallBackURL');
                bankWrapper.data.loanAmount = String.valueOf(opp.Requested_Amount__c);
                bankWrapper.data.txnId = null;
                bankWrapper.data.institutionId = null;
                bankWrapper.data.acceptancePolicy = 'atLeastOneTransactionInRange';
                bankWrapper.data.uploadingScannedStatements = String.valueof(wrapper.scannedCopy);
                bankWrapper.data.facility = 'CC';
                bankWrapper.data.sanctionLimitFixed = true;
                bankWrapper.data.lan = opp.Name;
                bankWrapper.data.triggerBy = 'cba';
                bankWrapper.data.drawingPowerVariableAmounts = new List<cls_drawingPowerVariableAmounts>();
                bankWrapper.data.fileData = new List<cls_fileData>();

                Decimal totalSanctionLimit = 0;
                Set<Id> processedBankIds = new Set<Id>();

                Date minFromDate = null;
                Date maxToDate = null;

                for (ContentVersion cv : finalContentVersionList) {
                    Document_Details__c doc = versionToDocumentMap.get(cv.Id);
                    cls_fileData fd = new cls_fileData();
                    fd.fileName = versionToFileName.get(cv.Id);
                    fd.password = doc.Password__c;
                    fd.institutionId = Integer.valueOf(doc.Institution_Id__c);
                    bankWrapper.data.fileData.add(fd);
                    if (!processedBankIds.contains(doc.Bank_Branch_Master__c)) {
                        processedBankIds.add(doc.Bank_Branch_Master__c);
                        if (doc.Sanction_Amount__c != null)
                            totalSanctionLimit += Decimal.valueof(doc.Sanction_Amount__c);
                    }
                    if (doc.Year_Month_From__c != null && (minFromDate == null || doc.Year_Month_From__c < minFromDate)) {
                        minFromDate = doc.Year_Month_From__c;
                    }
                    if (doc.Year_Month_To__c != null && (maxToDate == null || doc.Year_Month_To__c > maxToDate)) {
                        maxToDate = doc.Year_Month_To__c;
                    }
                }

                bankWrapper.data.sanctionLimitFixedAmount = Integer.valueOf(totalSanctionLimit);

                // 2. Group by period (from-to) and sum Drawing_Power_Amount__c month-wise across different banks
                Map<String, Map<Id, Document_Details__c>> groupedByPeriod = new Map<String, Map<Id, Document_Details__c>>();

                for (Document_Details__c doc : docDetailsList) {
                   

                    String periodKey = String.valueOf(String.valueOf(doc.Year_Month_From__c).substring(0, 7)) + '_' + String.valueOf(String.valueOf(doc.Year_Month_To__c).substring(0, 7));

                    if (!groupedByPeriod.containsKey(periodKey)) {
                        groupedByPeriod.put(periodKey, new Map<Id, Document_Details__c>());
                    }

                    // Add only one doc per bank per period
                    if (!groupedByPeriod.get(periodKey).containsKey(doc.Bank_Branch_Master__c)) {
                        groupedByPeriod.get(periodKey).put(doc.Bank_Branch_Master__c, doc);
                    }
                }

                for (String periodKey : groupedByPeriod.keySet()) {
                    Map<Id, Document_Details__c> docsByBank = groupedByPeriod.get(periodKey);
                    List<Integer> monthlySums = new List<Integer>();

                    for (Document_Details__c doc : docsByBank.values()) {
                        List<String> powerValues = doc.Drawing_Power_Amount__c.split(',');
                        for (Integer i = 0; i < powerValues.size(); i++) {
                            if (monthlySums.size() <= i) monthlySums.add(0);
                            monthlySums[i] += Integer.valueOf(powerValues[i].trim());
                        }
                    }

                    for (Integer val : monthlySums) {
                        cls_drawingPowerVariableAmounts dpva = new cls_drawingPowerVariableAmounts();
                        dpva.variableAmount = new cls_variableAmount();
                        dpva.variableAmount.amount = val;
                        bankWrapper.data.drawingPowerVariableAmounts.add(dpva);
                    }
                }

                // 3. Period coverage
                bankWrapper.data.yearMonthFrom = (minFromDate != null) ? String.valueOf(minFromDate).substring(0, 7) : '2024-10';
                bankWrapper.data.yearMonthTo = (maxToDate != null) ? String.valueOf(maxToDate).substring(0, 7) : '2025-03';

                // 4. Account docs
                bankWrapper.accountDocuments = new List<cls_accountDocuments>();
                for (ContentVersion cvId : finalContentVersionList) {
                    cls_accountDocuments accDoc = new cls_accountDocuments();
                    accDoc.fileName = versionToFileName.get(cvId.Id);
                    accDoc.fileId = cvId.Id;
                    bankWrapper.accountDocuments.add(accDoc);
                }

                bankWrapper.derivedAnalysisRecordTypeId = derivedRecordId;
                bankWrapper.documentDetailIdForIntegrationDetails = wrapper.documentDetailsResponse;
                bankWrapper.documentDetailIdForExcel = wrapper.documentDetailsExcel;
                bankWrapper.documentMasterId = docMaster[0].Id;
                bankWrapper.applicantId = applicantId;
                bankWrapper.customerId = applicant.Customer__c;
                bankWrapper.xnsRecordTypeId = xnsRecordId;

                System.debug('Final CC Wrapper JSON: ' + JSON.serialize(bankWrapper));
                requestJSON = JSON.serialize(bankWrapper);
            }

                       
            return requestJSON;


        }
        catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage()+exp.getlinenumber());
      
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'Createhunterpayload', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage()+exp.getlinenumber());
        }

    }
    public class BankStatementAnalysisRequestWrapperNone {
        public boolean sendToInternalApi;
        public boolean sendToInternalApiFromAA;
        public cls_dataNone data;
        public cls_accountDocuments[] accountDocuments;
        public String derivedAnalysisRecordTypeId;	//012Bi000000GxqZIAS
        public String documentDetailIdForIntegrationDetails;	//a0MBi000003z60LMAQ
        public String documentDetailIdForExcel;	//a0MBi0000041L3JMAU
        public String documentMasterId;	//a0LBi000001LvifMAC
        public String applicantId;	//a0TBi000003lkiTMAQ
        public String customerId;	//001Bi00000LjEkNIAV
        public String xnsRecordTypeId;	//012Bi000000GxqaIAC
    }
	public class cls_dataNone {
		public String loanAmount;	//100000
		public String loanDuration;	//24
		public String employmentType;	//SelfEmployed
		public String loanType;	//Business Loan
		public String processingType;	//STATEMENT
        public String txnId;
        public String institutionId;
		public String transactionCompleteCallbackUrl;	//https://apiscustomerportal.godrejhf.com/perfiosService/senp/bsa/perfiosUpdate
		public String acceptancePolicy;	//atLeastOneTransactionInRange
		public String uploadingScannedStatements;	//false
		public String yearMonthFrom;	//2023-04
		public String yearMonthTo;	//2023-08
		public String facility;	//NONE
		public cls_fileData[] fileData;
		public String lan;	//abc
		public String triggerBy;	//cba
	}
    public class BankStatementAnalysisRequestWrapperOD {
        public boolean sendToInternalApi;
        public boolean sendToInternalApiFromAA;
        public cls_dataOD data;
        public cls_accountDocuments[] accountDocuments;
        public String derivedAnalysisRecordTypeId;	//012Bi000000GxqZIAS
        public String documentDetailIdForIntegrationDetails;	//a0MBi000003z60LMAQ
        public String documentDetailIdForExcel;	//a0MBi0000041L3JMAU
        public String documentMasterId;	//a0LBi000001LvifMAC
        public String applicantId;	//a0TBi000003lkiTMAQ
        public String customerId;	//001Bi00000LjEkNIAV
        public String xnsRecordTypeId;	//012Bi000000GxqaIAC
    }
	public class cls_dataOD {
		public String loanAmount;	//100000
		public String loanDuration;	//24
		public String employmentType;	//SelfEmployed
        public String txnId;
        public String institutionId;
		public String loanType;	//Business Loan
		public String processingType;	//STATEMENT
		public String transactionCompleteCallbackUrl;	//https://apiscustomerportal.godrejhf.com/perfiosService/senp/bsa/perfiosUpdate
		public String acceptancePolicy;	//atLeastOneTransactionInRange
		public String uploadingScannedStatements;	//false
		public String yearMonthFrom;	//2023-04
		public String yearMonthTo;	//2023-08
		public String facility;	//NONE
		public cls_fileData[] fileData;
        public boolean sanctionLimitFixed;
        public Integer sanctionLimitFixedAmount;
		public String lan;	//abc
		public String triggerBy;	//cba
	}
    public class BankStatementAnalysisRequestWrapperCC {
        public boolean sendToInternalApi;
        public boolean sendToInternalApiFromAA;
        public cls_dataCC data;
        public cls_accountDocuments[] accountDocuments;
        public String derivedAnalysisRecordTypeId;	//012Bi000000GxqZIAS
        public String documentDetailIdForIntegrationDetails;	//a0MBi000003z60LMAQ
        public String documentDetailIdForExcel;	//a0MBi0000041L3JMAU
        public String documentMasterId;	//a0LBi000001LvifMAC
        public String applicantId;	//a0TBi000003lkiTMAQ
        public String customerId;	//001Bi00000LjEkNIAV
        public String xnsRecordTypeId;	//012Bi000000GxqaIAC
    }
	public class cls_dataCC {
		public String loanAmount;	//100000
		public String loanDuration;	//24
		public String employmentType;	//SelfEmployed
        public String txnId;
        public String institutionId;
		public String loanType;	//Business Loan
		public String processingType;	//STATEMENT
		public String transactionCompleteCallbackUrl;	//https://apiscustomerportal.godrejhf.com/perfiosService/senp/bsa/perfiosUpdate
		public String acceptancePolicy;	//atLeastOneTransactionInRange
		public String uploadingScannedStatements;	//false
		public String yearMonthFrom;	//2023-04
		public String yearMonthTo;	//2023-08
		public String facility;	//NONE
		public cls_fileData[] fileData;
        public cls_drawingPowerVariableAmounts[] drawingPowerVariableAmounts;
        public boolean sanctionLimitFixed;
        public Integer sanctionLimitFixedAmount;
		public String lan;	//abc
		public String triggerBy;	//cba
	}
	public class cls_fileData {
		public String fileName;	//HDFC_Bank_01.04.2023_To_31.08.2023.pdf
		public String password;	//
		public Integer institutionId;	//20
	}
	public class cls_accountDocuments {
		public String fileName;	//HDFC_Bank_01.04.2023_To_31.08.2023.pdf
		public String fileId;	//068Bi0000036mbJIAQ
        // public String bankName;	//HDFC Bank, India
		// public String accountType;	//Savings Account
		// public String documentChecklistId;	//a0MBi0000042AtpMAE
        // public String bankId;	//a0VBi0000022QWjMAM
		// public String accountNumber;	//50100457276182
	}
    public class cls_drawingPowerVariableAmounts {
		public cls_variableAmount variableAmount;
	}
	public class cls_variableAmount {
		public Integer amount;	//100000
	}
	
}