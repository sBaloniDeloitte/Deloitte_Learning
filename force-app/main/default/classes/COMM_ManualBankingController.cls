public class COMM_ManualBankingController {
    
    
    @AuraEnabled
    public static void updateInternalBSAToggle(Id documentId, String toggleValue) {
        if (documentId == null || String.isBlank(toggleValue)) {
            throw new AuraHandledException('Invalid input parameters');
        }
        
        // Get the linked_reference__c of the current document
        Document_Details__c currentDoc = [
        SELECT Id, Linked_Reference__c 
        FROM Document_Details__c 
        WHERE Id = :documentId 
        LIMIT 1
    ];
        
        if (currentDoc.Linked_Reference__c == null) {
            throw new AuraHandledException('Linked Reference is missing on the current document');
        }
        
        List<Document_Details__c> relatedDocs = [
        SELECT Id, Is_Internal_BSA__c, Linked_Reference__c 
        FROM Document_Details__c 
        WHERE Linked_Reference__c = :currentDoc.Linked_Reference__c
    ];
        
        if (relatedDocs.isEmpty()) {
            return;
        }
        
        for (Document_Details__c doc : relatedDocs) {
            doc.Is_Internal_BSA__c = toggleValue;
        }
        
        update relatedDocs;
    }
    @AuraEnabled(cacheable=true)
    public static List<Application_Applicant__c> getApplicationApplicants(Id oppId) {
        // Query the Application_Applicant__c records related to the given Opportunity Id
        //multiple seller builder part
        return [
            SELECT Id, Name, Applicant_Type__c 
            FROM Application_Applicant__c 
            WHERE Loan_Application__c  = :oppId
            ORDER BY Name
        ];
    }
    
    
    
    @AuraEnabled
    public static List<Bank_Branch_Master__c> getBankList(String recordId) {
        // Query the Application_Applicant__c records related to the given Opportunity Id
        // return [
        //     SELECT id,name FROM Bank_Branch_Master__c WHERE Record_Type_Name__c = 'Branch'
        //     ORDER BY Name
        // ];
        //sanwar (28/11/2025)
        List<Bank_Details__c> bankDetails = [
            SELECT Id,
                Bank_Master__c
            FROM Bank_Details__c
            WHERE Application_Applicant__r.Loan_Application__c = :recordId
            AND Source__c = 'Manual'
        ];
        
        Set<Id> bankMasterIds = new Set<Id>();
        for (Bank_Details__c bd : bankDetails) {
            if (bd.Bank_Master__c != null) {
                bankMasterIds.add(bd.Bank_Master__c);
            }
        }
        
        List<Bank_Branch_Master__c> bankMasterList = new List<Bank_Branch_Master__c>();
        
        if (!bankMasterIds.isEmpty()) {
            bankMasterList = [
                SELECT Id, Name
                FROM Bank_Branch_Master__c
                WHERE Id IN :bankMasterIds
            ORDER BY Name
        ];
        }
        
        return bankMasterList;
    }
    @AuraEnabled
    public static void createBankDetail(Id applicant,String accountHolderName,String accountType,String accountNo,Id bank,String recordId,String month,String year)
    {
        Bank_Details__c record = new Bank_Details__c();
        record.Application_Applicant__c  = applicant;
        record.Account_Holder_Name__c = accountHolderName ;
        record.Account_Type__c  = accountType;
        record.Account_Number__c = accountNo;
        record.Bank_Master__c = bank;
        record.Month__c = month;
        record.Year__c = year;
        // record.Loan_Application__c  = recordId;
        insert record;
        system.debug(record.Id) ;
        
        
    }
    
    public class BankDetailWrapper {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String applicantId { get; set; }
        @AuraEnabled public String accountType { get; set; }
        @AuraEnabled public String accountNo { get; set; }
        @AuraEnabled public Id bank { get; set; }
        @AuraEnabled public String bankName {get; set; } //Sanwar(29/11/2025)
        @AuraEnabled public String month { get; set; }
        @AuraEnabled public String year { get; set; }
        @AuraEnabled public boolean isEditable { get; set; }
        @AuraEnabled public boolean isPreview { get; set; }
        @AuraEnabled public boolean isReUpload { get; set; }
        @AuraEnabled public String contentId { get; set; }
        @AuraEnabled public String docId { get; set; }
        @AuraEnabled public String analyticContentId { get; set; }
        @AuraEnabled public boolean isAnalyticUploaded { get; set; }
        // multiple builder seller part
        @AuraEnabled public String appType { get; set; }
    }
    
    @AuraEnabled
    public static void createDocumentDetailBankAnalytic(String recordId,String docId, String bankId){
        
        Document_Details__c docObj = new Document_Details__c();
        docObj.Name = 'Bank Analytics Doc';
        docObj.Content_Document_Id__c = docId;
        docObj.Loan_Application__c = recordId;
        docObj.Bank_Details__c = bankId;
        docObj.Uploaded_Date_Time__c = System.now();
        docObj.Status__c = 'Uploaded';
        insert docObj;
    }
    @AuraEnabled
    public static void checkInternalBsa(Id docId) {
        /*internal_bsa__mdt rule = [
            SELECT where__c 
            FROM internal_bsa__mdt 
            LIMIT 1
        ];
        
        String baseQuery = 'SELECT Id FROM document_details__c WHERE Id = :docId';
        
        if (rule.where__c != null && rule.where__c.trim().length() > 0) {
            baseQuery += ' AND ' + rule.where__c;
        }
        
        List<document_details__c> docs = Database.query(baseQuery);
        
        if (docs.size() == 1) {
            document_details__c docRecord = docs[0];
            docRecord.is_internal_bsa__c = 'yes';
            update docRecord;
        }*/
    }
    @AuraEnabled
    public static  List<BankDetailWrapper> fetchBankDetails( String recordId){
        try {
            List<BankDetailWrapper>  bankListWrapper = new List<BankDetailWrapper>();
            Map<String, Document_Details__c> docMap = new Map<String, Document_Details__c>();
            Map<String, Document_Details__c> docAnalyticMap = new Map<String, Document_Details__c>();
            List<Bank_Details__c> bankDetails = new List<Bank_Details__c>();
            
            List<Application_Collateral__c> appCol = [Select Collateral__r.Project__c, Collateral__r.APF__c From Application_Collateral__c Where HL_Loan_Application__c =: recordId And Collateral__r.Primary_Secondary__c = 'Primary'];
            Utility_V1.ProductWrapper prodWrapper = Utility_V1.getProductDetails(new Map<String,String>{'oppId' => recordId}); //for HL case
            if(prodWrapper.isHLRelated && !appCol.isEmpty() && appCol[0].Collateral__r.APF__c == 'Yes'){
                System.debug('inside 150');
                bankDetails = [SELECT id,Application_Applicant__c,Application_Applicant__r.Applicant_name__c, Application_Applicant__r.Applicant_Type__c, Account_Holder_Name__c,Account_Type__c,Account_Number__c,Bank_Master__c, Bank_Master__r.Name ,Month__c,Year__c FROM bank_details__c WHERE Application_Applicant__r.Loan_Application__c =:recordId]; // Project_Name__c =: appCol[0].Collateral__r.Project__c
            }
            else {
                bankDetails = [SELECT id,Application_Applicant__c,Application_Applicant__r.Applicant_name__c, Application_Applicant__r.Applicant_Type__c, Account_Holder_Name__c,Account_Type__c,Account_Number__c,Bank_Master__c, Bank_Master__r.Name ,Month__c,Year__c FROM bank_details__c WHERE Application_Applicant__r.Loan_Application__c =:recordId AND Source__c= 'Manual'] ; //Sanwar(29/11/2025)(add name)
            }
            System.debug('bankDetails: '+bankDetails);
            // List<Bank_Details__c> bankDetails = [SELECT id,Application_Applicant__c,Application_Applicant__r.Applicant_name__c,Account_Holder_Name__c,Account_Type__c,Account_Number__c,Bank_Master__c, Bank_Master__r.Name ,Month__c,Year__c FROM bank_details__c WHERE Application_Applicant__r.Loan_Application__c =:recordId AND Source__c= 'Manual'] ; //Sanwar(29/11/2025)(add name)
            List<Document_Details__c> docDetails = [SELECT Id,Name, Content_Document_Id__c, Month__c, Year__c, Bank_Details__c FROM Document_Details__c WHERE Bank_Details__c IN : bankDetails ORDER BY CreatedDate DESC];
            for(Document_Details__c doc: docDetails){
                if(!docMap.containsKey(doc.Bank_Details__c) && doc.Name != 'Bank Analytics Doc'){
                    docMap.put(doc.Bank_Details__c, doc);
                }
                if(!docAnalyticMap.containsKey(doc.Bank_Details__c) && doc.Name == 'Bank Analytics Doc') {
                    docAnalyticMap.put(doc.Bank_Details__c, doc);
                }
            }
            System.debug('docMap '+docMap);
            System.debug('docAnalyticMap '+docAnalyticMap);
            for(Bank_Details__c bank :bankDetails){
                BankDetailWrapper wrapper = new BankDetailWrapper();
                if(docMap.containsKey(bank.Id)){
                    System.debug('Inside trueee');
                    Document_Details__c doc = docMap.get(bank.Id);
                    wrapper.month = doc.Month__c != null ? doc.Month__c: '';
                    wrapper.year = doc.Year__c != null ? doc.Year__c : '' ;
                    System.debug('doc.Year__c--'+doc.Year__c);
                    System.debug('year---'+ wrapper.year );
                    wrapper.contentId= doc.Content_Document_Id__c;
                    wrapper.docId= doc.Id;
                }else {
                    wrapper.month = '' ;
                    wrapper.year = '' ;
                    wrapper.contentId= '';
                    wrapper.docId= '';
                }
                if(docAnalyticMap.containsKey(bank.Id)) {
                    Document_Details__c doc1 = docAnalyticMap.get(bank.Id);
                    wrapper.analyticContentId= doc1.Content_Document_Id__c;
                    wrapper.isAnalyticUploaded = true;
                }else {
                    wrapper.isAnalyticUploaded = false;
                }
                wrapper.id = bank.Id;
                wrapper.applicantId = bank.Application_Applicant__c;
                wrapper.accountType = bank.Account_Type__c;
                wrapper.accountNo = bank.Account_Number__c;
                wrapper.bank = bank.Bank_Master__c;
                wrapper.bankName = bank.Bank_Master__r.Name; //Sanwar(29/11/2025)
                //multiple builder seller part
                wrapper.AppType=bank.Application_Applicant__r.Applicant_Type__c;
                wrapper.isEditable = true ;
                wrapper.isPreview = true ;
                wrapper.isReUpload = false ;
                System.debug('wrapper---'+wrapper);
                bankListWrapper.add(wrapper);
            }
            
            return bankListWrapper ;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void updateBankDetails(Id recordId,String fieldName,String newValue) {
        Bank_Details__c recordtoUpdate = new Bank_Details__c() ;
        Document_Details__c docToUpdate= new Document_Details__c();
        
        system.debug(recordtoUpdate) ;
        if(fieldName =='applicantCombobox' || fieldName =='accountTypeCombobox' || fieldName =='accountNoInput' || fieldName =='bankCombobox'){
            recordtoUpdate = [select id from Bank_Details__c where id = :recordId] ;
            if(fieldName =='applicantCombobox')
            {
                recordtoUpdate.Application_Applicant__c = (Id)newValue ;
            }
            else if(fieldName =='accountTypeCombobox'){
                recordtoUpdate.Account_type__c = newValue ;
            }
            else if(fieldName =='accountNoInput'){
                recordtoUpdate.Account_Number__c = newValue ;
            }
            else if(fieldName =='bankCombobox'){
                recordtoUpdate.Bank_Master__c = (Id)newValue ;
                if(newValue != null){
                    List<Bank_Branch_Master__c> bankMasterRec = [select id, IFSC__c from Bank_Branch_Master__c where Id = :newValue LIMIT 1];
                    if(!bankMasterRec.isEmpty() && bankMasterRec[0].IFSC__c != null) {
                        recordtoUpdate.IFSC__c = bankMasterRec[0].IFSC__c;
                    }
                }
            }
            update recordtoUpdate;
        }
        
        else if(fieldName =='monthInput' || fieldName =='yearInput'){
            docToUpdate.Id= recordId ;
            if(fieldName =='monthCombobox'){
                docToUpdate.Month__c = newValue ;
            }
            else if(fieldName =='yearCombobox'){
                docToUpdate.year__c = newValue ;
            }
            update docToUpdate;
        }
        
    }
    
    @AuraEnabled
    public static boolean createBSArecord(Id bdRecordId) {
        Bank_Details__c bdRecord = [SELECT Month__c,Year__c FROM Bank_Details__c where id =:bdRecordId] ;
        List<Document_Details__c> docDetails= [SELECT Id, Month__c, Year__c  FROM Document_Details__c WHERE Bank_Details__c = :bdRecordId];
        List<Bank_Statement_Analysis__c> existingRecord = new List<Bank_Statement_Analysis__c>() ;
        existingRecord = [SELECT id from Bank_Statement_Analysis__c where Bank_Details__c =:bdRecordId] ;
        if(existingRecord.size()>0){
            return false ;
        }
        if(docDetails.size()>0){
            String month = docDetails[0].Month__c ;
            String year = docDetails[0].Year__c ;
            Integer storedYear= Integer.valueOf(year.substring(year.length() - 2));
            String daRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis');
            Bank_Statement_Analysis__c newObj = new Bank_Statement_Analysis__c();
            List<Bank_Statement_Analysis__c> bsaList = new List<Bank_Statement_Analysis__c>() ;
            Map<String,Integer> monthToNumberMap = new Map<String,Integer>();
            monthToNumberMap.put('January',0);
            monthToNumberMap.put('February',1);
            monthToNumberMap.put('March',2);
            monthToNumberMap.put('April',3);
            monthToNumberMap.put('May',4);
            monthToNumberMap.put('June',5);
            monthToNumberMap.put('July',6);
            monthToNumberMap.put('August',7);
            monthToNumberMap.put('September',8);
            monthToNumberMap.put('October',9);
            monthToNumberMap.put('November',10);
            monthToNumberMap.put('December',11);
            Map<Integer, String> numberToMonthMap = new Map<Integer, String>();
            numberToMonthMap.put(0, 'Jan');
            numberToMonthMap.put(1, 'Feb');
            numberToMonthMap.put(2, 'Mar');
            numberToMonthMap.put(3, 'Apr');
            numberToMonthMap.put(4, 'May');
            numberToMonthMap.put(5, 'Jun');
            numberToMonthMap.put(6, 'Jul');
            numberToMonthMap.put(7, 'Aug');
            numberToMonthMap.put(8, 'Sept');
            numberToMonthMap.put(9, 'Oct');
            numberToMonthMap.put(10, 'Nov');
            numberToMonthMap.put(11, 'Dec');
            if(String.isNotBlank(month) && String.isNotBlank(year)){
                //Integer monthIndex= monthToNumberMap.get(month);
                Bank_Statement_Analysis__c parentDA = new Bank_Statement_Analysis__c() ;
                parentDA.RecordTypeId = daRecordTypeId;
                parentDA.Bank_Details__c = bdRecordId;
                parentDA.Source__c = 'Manual';
                insert parentDA;
                Integer monthIndex= Integer.valueOf(month);
                for(Integer i= 0; i< 6; i++){
                    Bank_Statement_Analysis__c bsa = new Bank_Statement_Analysis__c() ;
                    String temp = numberToMonthMap.get(monthIndex) +'-'+ storedYear ;
                    bsa.Month__c = temp;
                    bsa.Source__c = 'Manual';
                    bsa.RecordTypeId = daRecordTypeId;
                    bsa.Bank_Details__c = bdRecordId;
                    bsa.Parent_Bant_Statement__c = parentDA.id;
                    bsaList.add(bsa) ;
                    
                    monthIndex++;
                    if (monthIndex == 12) { // If December, reset to January and increment year
                        monthIndex = 0;
                        storedYear++;
                    }
                    
                }
                
                insert bsaList ;
                system.debug('bsa record created' +bsaList) ;
                return true ;
            }
        }
        
        return false;
    }
    @AuraEnabled
    // (cacheable=true)// why is it here if we are updating the record??
    public static FinalWrapper fetchBSARecords(Id bdRecordId){
        FinalWrapper fw = new FinalWrapper();
        Map<String,String> labelToFieldApiName = new Map<String,String>();
        // labelToFieldApiName.put('5th','Total_Self_and_Related_Party_Credit__c');
        // labelToFieldApiName.put('15th','Amount_of_Self_and_Related_Party_Credit__c');
        // labelToFieldApiName.put('25th','Total_Number_of_Business_Credits__c');
        // labelToFieldApiName.put('30th','Total_Amount_of_Business_Credits__c');
        // labelToFieldApiName.put('Monthly ABB','ABB__c');
        // labelToFieldApiName.put('Total debit count','Total_Number_of_Business_Debits__c');
        // labelToFieldApiName.put('Total debit value','Total_Amount_of_Business_Debits__c');
        // labelToFieldApiName.put('Total credit count','Total_Number_of_Business_Credits__c');
        // labelToFieldApiName.put('Total credit value','Total_Amount_of_Business_Credits__c');
        // labelToFieldApiName.put('Inward return count','Total_number_of_inward_return__c');
        // labelToFieldApiName.put('Outward return count','Total_number_of_outward_return__c');
        // labelToFieldApiName.put('EMI return','Total_Amount_of_EMI__c');
        
        labelToFieldApiName.put('Total No. of Self & Related Party Credit Transactions','Total_Self_and_Related_Party_Credit__c');
        labelToFieldApiName.put('Total Amount of Self & Related Party Credit Transactions','Amount_of_Self_and_Related_Party_Credit__c');
        labelToFieldApiName.put('Total No of Business Credits','Total_Number_of_Business_Credits__c');
        labelToFieldApiName.put('Total Amount of Business Credits','Total_Amount_of_Business_Credits__c');
        labelToFieldApiName.put('Total No. of Self & Related Party Debit Transactions','Number_of_Self_and_Related_Party_Debit__c');
        labelToFieldApiName.put('Total Amount of Self & Related Party Debit Transactions','Total_Self_and_Related_Party_Debit__c');
        labelToFieldApiName.put('Total No of Business Debits','Total_Number_of_Business_Debits__c');
        labelToFieldApiName.put('Total Amount of Business Debits','Total_Amount_of_Business_Debits__c');
        labelToFieldApiName.put('Cash Deposit to Total Credit','Cash_Deposit_to_total_Credit__c');
        labelToFieldApiName.put('Cash Withdrawal to Total Debit','Cash_withdrwal_to_total_Debit__c');
        labelToFieldApiName.put('Total No of Inward Cheque Returns','Total_number_of_inward_return__c');
        labelToFieldApiName.put('Total No of Inward ECS Returns','Total_number_of_inward_ECS_return__c');
        //labelToFieldApiName.put('l/w Returns (Nos) as % of Total Debits','I_w_retruns_as_of_total_debits__c');
        labelToFieldApiName.put('Total No of Outward Returns','Total_number_of_outward_return__c');
        labelToFieldApiName.put('O/W Returns (Nos) as % of Total Credits','O_w_retruns_as_of_total_credits__c');
        labelToFieldApiName.put('Total Amount of Interest Charges','Total_Amount_of_Intrest_Charged__c');
        labelToFieldApiName.put('Total No. of Circular Transactions','Total_Number_of_circular_transactions__c');
        //labelToFieldApiName.put('Total Amount of Circular Transactions','Total_Amount_of_Circular_Transactions__c');
        labelToFieldApiName.put('Total Amount of EMI','Total_Amount_of_EMI__c');
        labelToFieldApiName.put('Average EOD Balance','Average_EOD_Balance__c');
        //labelToFieldApiName.put('Sanction Limit','Sanction_Limit__c');
        labelToFieldApiName.put('Average Limit Utilization','Average_Limit_Utilisation__c');
        labelToFieldApiName.put('ABB (5,15,25,30)','ABB__c');
        labelToFieldApiName.put('Count of Loan Disbursal','Count_of_loan_disbursal__c');
        labelToFieldApiName.put('Value of Loan Disbursal','Value_of_loan_disbursal__c');
        
        
        
        String daRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis');
        List<Bank_Statement_Analysis__c> xnsData = [SELECT id,Total_Self_and_Related_Party_Credit__c,Amount_of_Self_and_Related_Party_Credit__c,
                                                    Total_Number_of_Business_Credits__c,Total_Amount_of_Business_Credits__c,
                                                    Number_of_Self_and_Related_Party_Debit__c,Total_Self_and_Related_Party_Debit__c,
                                                    Total_Number_of_Business_Debits__c,Total_Amount_of_Business_Debits__c,
                                                    Cash_Deposit_to_total_Credit__c,Cash_withdrwal_to_total_Debit__c,
                                                    Total_number_of_inward_return__c,I_w_retruns_as_of_total_debits__c,
                                                    Total_number_of_outward_return__c,O_w_retruns_as_of_total_credits__c,
                                                    Average_Limit_Utilisation__c,ABB__c,Total_number_of_inward_Cheque_return__c,
                                                    Total_number_of_inward_ECS_return__c,Value_of_loan_disbursal__c,
                                                    Total_Number_of_circular_transactions__c,Total_Amount_of_EMI__c,
                                                    Total_Amount_of_Intrest_Charged__c,Count_of_loan_disbursal__c,
                                                    Month__c,Average_EOD_Balance__c
                                                    FROM Bank_Statement_Analysis__c 
                                                    WHERE Bank_Details__c = : bdRecordId AND Source__c = 'Manual' 
                                                    AND RecordTypeId =:daRecordTypeId AND Parent_Bant_Statement__c != null order by createddate];
        // if(xnsData.size() > 0) {
            
            fw.mainWrapList = new List<MainWrapper>();
            fw.headerList = new List<String>();
            for(Bank_Statement_Analysis__c iterBsaDa : xnsData) {
                fw.headerList.add(iterBsaDa.Month__c);
            }
            for(String keyItem : labelToFieldApiName.keySet()) {
                MainWrapper mw = new MainWrapper();
                mw.fieldName = keyItem;
                List<WrapperInner> lst = new List<WrapperInner>();
                //mw.valuesObj = new List<WrapperInner>();
                for(Bank_Statement_Analysis__c iterBsaDa : xnsData) {
                    WrapperInner obj = new WrapperInner();
                    Object val = iterBsaDa.get(String.valueOf(labelToFieldApiName.get(keyItem)));
                    String fieldVal = String.valueOf(val);
                    System.debug(fieldVal);
                    if(fieldVal != null){
                        obj.recId = iterBsaDa.id;
                        obj.recVal = fieldVal;
                        obj.recFieldName = labelToFieldApiName.get(keyItem);
                    }
                    else{
                        obj.recId = iterBsaDa.id;
                        obj.recVal = '0';
                        obj.recFieldName = labelToFieldApiName.get(keyItem);
                    }
                    lst.add(obj);
                    
                }
                mw.valuesObj = lst;
                fw.mainWrapList.add(mw);
            }
            System.debug('final '+fw);
        // }
        return fw;
    }
    @AuraEnabled
    public static String uploadFileNonDocument(String base64Data, String fileName, String fileType) {
        String contentId = 'Error in uploading documents';
        String docId = '';
        
        try {
            // Document_Details__c doc = new Document_Details__c();
            
            if (base64Data != null && fileName != null && fileType != null) {
                Blob fileBlob = EncodingUtil.base64Decode(base64Data);
                
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = fileName;
                contentVersion.PathOnClient = fileName;
                contentVersion.VersionData = fileBlob;
                contentVersion.ContentLocation = 'S'; // 'S' for Salesforce, 'E' for external
                insert contentVersion;
                
                contentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
                return contentId;
                // Fetching the document master
                // List<Document_Master__c> docMaster = [SELECT Id, Name FROM Document_Master__c WHERE Requirement_At__c = 'Loan Application' AND Name = 'Other' LIMIT 1];
                
                
                //     doc.Status__c = 'Uploaded';
                //     doc.Content_Document_Id__c = contentId;
                //     doc.Document_Master__c = docMaster.isEmpty() ? null : docMaster[0].Id;
                //     doc.Loan_Application__c = loanId;
                //     doc.Name = fileName;
                //     insert doc;
                //     docId = doc.Id;
                
            }
        } catch (Exception exp) {
            System.debug('Exception in uploadFileNonDocument: ' + exp.getMessage());
        }
        
        return contentId; // Ensure a value is returned
    }
    @AuraEnabled
    public static void createDocumentDetail(String applicationId,string bankDetailRecord,Id loanAppId,Id contentDocumentId){
        Document_Master__c dmObj = new Document_Master__c() ;
        dmObj = [SELECT id, Name, Document_Name__c, Document_Category__c, Document_Categories__c FROM Document_Master__c WHERE Document_Name__c = '12 months bank statement' Limit 1] ; //change
        List<Document_Details__c> tempObj =  new List<Document_Details__c>() ;
        tempObj = [SELECT id,Version_Number__c FROM Document_Details__c WHERE Bank_Details__c =:bankDetailRecord ORDER BY Version_Number__c DESC Limit 1] ; //change
        Integer version ;
        if(tempObj.size()>0){
            version = (Integer)(tempObj[0].Version_Number__c) ;
            version++ ;
        }
        else
        {
            version = 1 ;
        }
        DateTime dt= System.now().addMonths(-7);
        System.debug('lastMonths----'+dt);
        String selectedYear = String.valueOf(dt.year());
        String selectedMonth = String.valueOf(dt.month());
        Document_Details__c newObj =  new Document_Details__c() ;
        newObj.Name = 'Bank Statement' ;
        newObj.Applicant__c = applicationId ;
        newObj.Document_Master__c = dmObj.Id ;
        newObj.Bank_Details__c  = bankDetailRecord ;
        newObj.Loan_Application__c = loanAppId ;
        newObj.Content_Document_Id__c = contentDocumentId ;
        newObj.Active__c = true ;
        newObj.Month__c = selectedMonth;
        newObj.Year__c = selectedYear;
        newObj.Consider_for_Loan_Application__c=true;
        //logic for versionnumber update
        newObj.Version_Number__c = version ;
        
        insert newObj ;
        system.debug('created Document Detail Object') ;
    }
    @AuraEnabled
    public static void deleteDocumentDetails(Id bankDetailRecord,Boolean isAnalysis ){
        
        
        List<Document_Details__c> latestRecords = new  List<Document_Details__c>() ;
        if(isAnalysis) {
            latestRecords = [
            SELECT Id, Version_Number__c 
            FROM Document_Details__c 
			Where Bank_Details__c = :bankDetailRecord AND Name = 'Bank Analytics Doc'
            LIMIT 1
        ];
            if (!latestRecords.isEmpty()) {
                delete latestRecords;
            }
        }else {
            latestRecords = [
            SELECT Id, Version_Number__c 
            FROM Document_Details__c 
			Where Bank_Details__c = :bankDetailRecord AND Name != 'Bank Analytics Doc'
            ORDER BY Version_Number__c DESC 
            LIMIT 1
        ];
        }
        
        
        // If a record is found, delete it
        if (!latestRecords.isEmpty()) {
            try {
                latestRecords[0].Active__c = false ;
                System.debug('Updated record with Id: ' + latestRecords[0].Id);
            } catch (DmlException e) {
                System.debug('Error Updating record: ' + e.getMessage());
            }
        } else {
            System.debug('No records found to update.');
        }
    }
    @AuraEnabled
    public static Id fetchContentDocumentIdofBdRecord(Id bdRecordId){
        Document_Details__c newObj =  new Document_Details__c() ;
        newObj = [SELECT Content_Document_Id__c from Document_Details__c where Bank_Details__c=:bdRecordId] ;
        system.debug('newObj-' + newObj.Id + '--'+newObj.Content_Document_Id__c) ;
        return newObj.Content_Document_Id__c ;
        
    }
    
    public class FinalWrapper{
        @AuraEnabled public List<MainWrapper> mainWrapList;
        @AuraEnabled public List<String> headerList;
    }
    public class MainWrapper{
        @AuraEnabled public String fieldName;
        @AuraEnabled public List<String> values;
        @AuraEnabled public List<WrapperInner> valuesObj;
    }
    public class WrapperInner{
        @AuraEnabled public String recId;
        @AuraEnabled public String recVal;
        @AuraEnabled public String recFieldName;
        @AuraEnabled public Boolean isEditable;
    }
    @AuraEnabled
public static void initiateBSA(Id documentId) {
    try {
        Document_Details__c dd = [
            SELECT Id, Is_BSA_Initated__c
            FROM Document_Details__c
            WHERE Id = :documentId
            LIMIT 1
        ];

        dd.Is_BSA_Initated__c = true;

        update dd;

    } catch (Exception e) {
        throw new AuraHandledException(
            'Unable to initiate BSA: ' + e.getMessage()
        );
    }
}
    
}