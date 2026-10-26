/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-31-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class InvoiceManagementController {
    
    public InvoiceManagementController(ApexPages.StandardController controller){
        this();
    }

    public InvoiceManagementController() {

        string portalUrl = ApexPages.currentPage().getUrl().contains('my.site.com') ? '/losportal' : '';
        this.recordId = ApexPages.currentPage().getParameters().get('Id');
        System.debug('recordId: '+this.recordId);
        BranchDetailWrapper branchDetail = getBranchDetails(this.recordId);
        // cheking existing payout record 
        List<Vendor_Invoice__c> existingPayoutRec = [SELECT Customer_Name__c,CustomerName__c, FIN_Refrence_No__c, Loan_Number__c, Disbursed_Amount__c, Amount__c, Booking_Month__c, Sanction_Loan_Amount__c, Payout_Percentage__c, HSN_HAC_Code__c,
                                                      Branch_Master__c FROM Vendor_Invoice__c WHERE RecordType.Name = 'Payout' And Invoice__c =: recordId ORDER BY Name LIMIT 1];
        List<Vendor_Invoice__c> invList = [Select Id, Name, CreatedDate, IGST__c, SGST__c, CGST__c, UGST__c, Amount__c, GST_Type__c, Customer_Name__c, CGST_Type__c, DSA_Address__c, DSA__c,
                                    GST_Applicable__c, DSA_Address__r.GST_Number__c, GST_Recipient__c, DSA_Address__r.Place_of_Supply_State__c, CIN_Number__c, DSA__r.Name, 
                                    DSA_Address__r.Full_Address1__c, DSA__r.PAN_Number__c, DSA__r.HSN_HAC_Code__c, DSA_Address__r.Pincode__r.City__r.State_Code__c,
                                    DSA_Bank__r.Account_Number__c, DSA_Bank__r.Name, Branch_Master__r.Pincode__r.State__c, Branch_Master__c, Loan_Number__c, HSN_HAC_Code__c, Branch_Master__r.Pincode__r.City__r.State_Code__c
                                    From Vendor_Invoice__c Where RecordType.Name = 'Invoice' And Id =: recordId Limit 1];
        if (!invList.isEmpty()){
            for(Vendor_Invoice__c rec : invList)
            {
                this.invoiceNo = rec.Name;
                this.invoiceDate = rec.CreatedDate.format('dd/MM/YYYY');
                this.panNo = rec.DSA__c != null ? rec.DSA__r?.PAN_Number__c:null; // rec.DSA__r?.PAN_Number__c;
                this.supplierName = rec.DSA__c != null ? rec.DSA__r?.Name:null; // rec.DSA__r?.Name;
                this.gstNo = rec.DSA_Address__c != null ? rec.DSA_Address__r?.GST_Number__c: null; // rec.DSA_Address__r?.GST_Number__c;
                this.gstRecNo = branchDetail.gstNo;//rec.GST_Recipient__C;
                // this.placeOfSupply = rec.DSA_Address__r?.Place_of_Supply_State__c;
                
                // this.placeOfSupply =rec.Branch_Master__r.Pincode__r.State__c;
                // this.stateCode = rec.Branch_Master__r.Pincode__r.City__r.State_Code__c;

                this.placeOfSupply = branchDetail.state;
                this.stateCode = branchDetail.stateCode;

                this.supplierAddress = rec.DSA_Address__c != null ? rec.DSA_Address__r?.Full_Address1__c: null; // rec.DSA_Address__r?.Full_Address1__c;
                this.totalTaxFreeSupply = rec.Amount__c;
                this.totalTaxableSupply = rec.Amount__c;
                this.amountPayable = rec.Amount__c;
                this.recipientName = rec.Customer_Name__c;
                // this.recipientAddress = 'XXXXX XXXXXXXXX XXXXXXXXX XXXXX XXXXXXX';
                this.cinNumber = rec.CIN_Number__c;
                this.isReverseCharge = 'Y';
                this.bankDetails = rec.DSA_Bank__r.Account_Number__c +' ['+ rec.DSA_Bank__r.Name +']';
                if(rec.Branch_Master__c != null) {
                    String branchId = rec.Branch_Master__c;
                    System.debug('branchId from invoice rec : '+branchId);
                    List<Customer_Address__c> custAdd = [SELECT Full_Address1__c FROM Customer_Address__c WHERE Customer__c =: branchId LIMIT 1];
                    if (!custAdd.isEmpty()) {
                        this.recipientAddress = custAdd[0].Full_Address1__c;
                    }
                } else if (!existingPayoutRec.isEmpty() && existingPayoutRec[0].Branch_Master__c != null){
                    String branchId = existingPayoutRec[0].Branch_Master__c;
                    System.debug('branchId from payout rec : '+branchId);
                    List<Customer_Address__c> custAdd = [SELECT Full_Address1__c FROM Customer_Address__c WHERE Customer__c =: branchId LIMIT 1];
                    if (!custAdd.isEmpty()) {
                        this.recipientAddress = custAdd[0].Full_Address1__c;
                    }
                }
                if(rec.GST_Applicable__c == 'Yes'){
                    this.showTax = true;

                    if(rec.GST_Type__c == 'CGST'){
                        this.showCGST = true;
                        this.cgst = rec.CGST__c;

                        if(rec.CGST_Type__c == 'SGST'){
                            this.showSGST = true;
                            this.sgst = rec.SGST__c;
                        }
                        else {
                            this.showUGST = true;
                            this.ugst = rec.UGST__c;
                        }
                    }
                    else if(rec.GST_Type__c == 'IGST'){
                        this.showIGST = true;
                        this.igst = rec.IGST__c;
                    }

                    this.isReverseCharge = 'N';
                    this.amountPayable += (rec.CGST__c != null ? rec.CGST__c : 0) + (rec.IGST__c != null ? rec.IGST__c : 0) + (rec.SGST__c != null ? rec.SGST__c : 0) + (rec.UGST__c != null ? rec.UGST__c : 0);
                }

                this.amountPayableInWords = Utility.getNumberTOWordConvertion(this.amountPayable);
                this.payoutData = new List<PayoutData>();

                Integer payoutRow = 0;
                for(Vendor_Invoice__c pay : [Select Customer_Name__c,CustomerName__c, FIN_Refrence_No__c, Loan_Number__c, Disbursed_Amount__c, Amount__c, Booking_Month__c, Sanction_Loan_Amount__c, 
                                            Payout_Percentage__c, HSN_HAC_Code__c
                                            From Vendor_Invoice__c Where RecordType.Name = 'Payout' And Invoice__c =: recordId Order By Name]){

                    PayoutData payout = new PayoutData(pay.CustomerName__c, pay.Loan_Number__c, pay.Booking_Month__c, pay.Disbursed_Amount__c, pay.Payout_Percentage__c, rec.HSN_HAC_Code__c, pay.Amount__c);
                    // PayoutData payout = new PayoutData(pay.Customer_Name__c, pay.Loan_Number__c, pay.Booking_Month__c, pay.Disbursed_Amount__c, pay.Payout_Percentage__c, rec.HSN_HAC_Code__c, pay.Amount__c);
                    this.payoutData.add(payout);
                    payoutRow++;
                }

                List<Document_Details__c> existingDocs = [
                    SELECT Content_Document_Id__c FROM Document_Details__c
                    WHERE EntityReferenceId__c =: recordId And EntityReferenceName__c = 'Vendor_Invoice__c' AND Name =: 'Logo_'+ rec.Id And Active__c = true LIMIT 1
                ];

                if(!existingDocs.isEmpty()){
                    this.logoUrl = portalUrl +'/sfc/servlet.shepherd/document/download/'+ existingDocs[0].Content_Document_Id__c;
                    this.showLogo = true;
                }

                //this is used to fill the blank space shown on invoice
                this.rowStyle = 'text-align: left; vertical-align: top; min-height: '+ (435 - (payoutRow * 24)) +'px;';
            }
        }
    }

    private Id recordId;
    public String invoiceNo{get;set;}
    public String invoiceDate{get;set;}
    public String panNo{get;set;}
    public String gstNo{get;set;}
    public String gstRecNo{get;set;}
    public String placeOfSupply{get;set;}
    public String stateCode{get;set;}
    public Decimal igst{get;set;}
    public Decimal cgst{get;set;}
    public Decimal sgst{get;set;}
    public Decimal ugst{get;set;}
    public Decimal totalTaxableSupply{get;set;}
    public Decimal totalTaxFreeSupply{get;set;}
    public Decimal amountPayable{get;set;}
    public string amountPayableInWords{get;set;}
    public string supplierName{get;set;}
    public string supplierAddress{get;set;}
    public string recipientName{get;set;}
    public string recipientAddress{get;set;}
    public String logoUrl{get;set;}
    public Boolean showLogo{get;set;}
    public string rowStyle{get;set;}
    public Boolean showCGST{get;set;}
    public Boolean showSGST{get;set;}
    public Boolean showIGST{get;set;}
    public Boolean showUGST{get;set;}
    public Boolean showTax{get;set;}
    public String cinNumber{get;set;}
    public string isReverseCharge{get;set;}
    public string bankDetails{get;set;}
    public List<PayoutData> payoutData{get;set;}

    public class PayoutData {
        public String customerName{get;set;}
        public String finRefrenceNo{get;set;}
        public string disbursedMonth{get;set;}
        public Integer disbursedAmount{get;set;}
        public Decimal payoutPer{get;set;}
        public String hsn_hacCode{get;set;}
        public Decimal amount{get;set;}

        public PayoutData(string customerName, string finRefrenceNo, string disbursedMonth, Decimal disbursedAmount, Decimal payoutPer, string hsn_hacCode, Decimal amount){
            this.customerName = customerName;
            this.finRefrenceNo = finRefrenceNo;
            this.disbursedMonth = disbursedMonth;
            this.disbursedAmount = Integer.valueOf(disbursedAmount);
            this.payoutPer = payoutPer;
            this.hsn_hacCode = hsn_hacCode;
            this.amount = amount;
        }
    }

    @AuraEnabled
    public static List<InvoiceWrapper> getInvoiceRecords(string fromDate, string toDate, string invoiceId, string dsaId, string status, string processName, string profile){

        System.debug('fromDate: '+fromDate);
        System.debug('toDate: '+toDate);
        System.debug('invoiceId: '+invoiceId);
        System.debug('dsaId: '+dsaId);
        System.debug('status: '+status);
        System.debug('processName: '+processName);

        Map<string, Object> bindVars = new Map<string, Object>();

        string query = 'Select Id, Name, Amount__c, Disbursed_Amount__c, Remarks__c, Status__c, Is_Existing_Invoice_Uploaded__c, DSA__r.Name, DSA_Address__r.Full_Address1__c, '+
                        'DSA_Bank__r.Account_Number__c, DSA_Bank__r.Name, CreatedDate, URN_No__c '+
                        'From Vendor_Invoice__c Where RecordType.Name = \'Invoice\' ';

        query += buildFilterQuery(fromDate, toDate, invoiceId, dsaId, status, processName, profile, bindVars);
        
        System.debug('query: '+query);

        List<InvoiceWrapper> result = new List<InvoiceWrapper>();
        for(SObject rec : Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE)){

            InvoiceWrapper invoice = new InvoiceWrapper();
            invoice.recordId = (string) rec.get('Id');
            invoice.name = (string) rec.get('Name');
            invoice.status = (string) rec.get('Status__c');
            invoice.disbursedAmount = (decimal) rec.get('Disbursed_Amount__c');
            invoice.amount = (decimal) rec.get('Amount__c');
            invoice.remarks = (string) rec.get('Remarks__c');
            invoice.existingInvoiceUploaded = (Boolean) rec.get('Is_Existing_Invoice_Uploaded__c');
            invoice.nameOfAgency = (string) rec.getSObject('DSA__r')?.get('Name');
            invoice.agencyAddress = (string) rec.getSObject('DSA_Address__r')?.get('Full_Address1__c');
            invoice.agencyBank = (string) rec.getSObject('DSA_Bank__r')?.get('Account_Number__c') +' ['+ rec.getSObject('DSA_Bank__r')?.get('Name') +']';
            invoice.invoiceDate = (string) Datetime.valueOf(rec.get('CreatedDate')).format('dd-MM-yyyy');
            invoice.urnNo = (string) rec.get('URN_No__c');

            result.add(invoice);
        }

        return result;
    }

    public static string buildFilterQuery(string fromDate, string toDate, string invoiceId, string dsaId, string status, string processName, string profile, Map<string, Object> bindVars){

        string query = '';
        
        if(fromDate != null && toDate != null){
            query += 'And CreatedDate >= ' + (date.valueOf(fromDate).toString().replace(' 00:00:00', 'T00:00:00.001+0000')) +' And CreatedDate <= ' + (date.valueOf(toDate).toString().replace(' 00:00:00', 'T23:59:59.999+0000')) + ' ';
        }

        if(String.isNotBlank(invoiceId)){
            bindVars.put('invoiceId', invoiceId);
            query += 'And Id =: invoiceId ';
        }
        else if(String.isNotBlank(dsaId)){
            Set<Id> invoiceIdSet = new Set<Id>();
            for(Vendor_Invoice__c rec : [Select Invoice__c From Vendor_Invoice__c Where RecordType.Name = 'Payout' And Invoice__c != '' And DSA__c =: dsaId]){
                invoiceIdSet.add(rec.Invoice__c);
            }

            bindVars.put('dsaId', invoiceIdSet);
            query += 'And Id =: dsaId ';
        }

        string statusQuery = ' ';

        if(string.isNotBlank(status)){
            bindVars.put('status', status);
            statusQuery = 'And Status__c =: status ';
        }
        else {
            System.debug('profile: '+profile);
            statusQuery = 'And Status__c = \'\' ';

            List<Vendor_Invoice_Record_Display_Master__mdt> recstatusList = [Select Id, Status_to_Include__c From Vendor_Invoice_Record_Display_Master__mdt 
                                                                            Where Profile__c =: profile And Screen_Type__c =: processName 
                                                                            And Process_Name__c = 'Invoice' And Status_to_Include__c != '' Limit 1];
            if(!recstatusList.isEmpty()){
                bindVars.put('statusIn', recstatusList[0].Status_to_Include__c.split(','));
                statusQuery = 'And Status__c IN : statusIn ';
            }
        }

        query += statusQuery + 'Order By Name ASC Limit 3000';

        return query;
    }

    @AuraEnabled
    public static Map<string, object> getInvoiceDetails(string recordId){
        
        Map<string, object> result = new Map<string, object>();
        try {
            List<Vendor_Invoice__c> invoiceRec = [SELECT Id, Amount__c, CGST__c, FIN_Refrence_No__c, IGST__c, SGST__c, Disbursed_Amount__c, CIN_Number__c, GST_Applicable__c, 
                                                Customer_Name__c, DSA__c, Is_Existing_Invoice_Uploaded__c, Existing_Invoice_No__c, Is_Supplier_Logo_Uploaded__c, 
                                                UGST__c, GST_Type__c, CGST_Type__c, DSA_Address__c, DSA_Bank__c, DSA__r.HSN_HAC_Code__c, DSA__r.Name, DSA__r.PAN_Number__c, Branch_Master__c, HSN_HAC_Code__c,
                                                DSA_Address__r.GST_Number__c,GST_Recipient__c, DSA_Address__r.Place_of_Supply_State__c, Invoice_Type__c, Branch_Master__r.Pincode__r.City__r.State_Code__c, Branch_Master__r.Pincode__r.State__c
                                                FROM Vendor_Invoice__c Where Id =: recordId];
            if(!invoiceRec.isEmpty()) {
                result.put('invoiceDetails', invoiceRec[0]);
            }

            List<Vendor_Invoice__c> existingPayout = [SELECT Id, Name, Loan_Number__c, Amount__c, Status__c, Disbursed_Amount__c, Branch_Master__c, Branch_Master__r.Pincode__r.State__c, Product__c,
                                                     Branch_Master__r.Pincode__r.City__r.State_Code__c FROM Vendor_Invoice__c Where Invoice__c =: recordId];
            if (!existingPayout.isEmpty()) {
                result.put('existingPayout', existingPayout);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
        }

        return result;
    }

    public class BranchDetailWrapper {
        @AuraEnabled public String state;
        @AuraEnabled public String stateCode;
        @AuraEnabled public String errorCode;
        @AuraEnabled public String gstNo;
    }

    @AuraEnabled
    public static BranchDetailWrapper getBranchDetails(String recordId){
        BranchDetailWrapper branchWarp = new BranchDetailWrapper();
        List<Vendor_Invoice__c> vendorInvoice = [SELECT Id, Branch_Master__c FROM Vendor_Invoice__c WHERE Invoice__c =: recordId ORDER BY Name LIMIT 1];
        if(!vendorInvoice.isEmpty() && vendorInvoice[0].Branch_Master__c != null){
            List<Account> accs = [SELECT Id, Pincode__c, GST_Number__c FROM Account WHERE Id =: vendorInvoice[0].Branch_Master__c];
            if(!accs.isEmpty() && accs[0].Pincode__c != null){
                branchWarp.gstNo = accs[0].GST_Number__c;
                List<Pincode_Master__c> pincodes = [SELECT Id, State__c, City__c FROM Pincode_Master__c WHERE Id =: accs[0].Pincode__c LIMIT 1];
                if (!pincodes.isEmpty() && pincodes[0].City__c != null && pincodes[0].State__c != null) {
                    branchWarp.state = pincodes[0].State__c;
                    List<City_Master__c> cities = [SELECT Id, State_Code__c FROM City_Master__c WHERE Id =: pincodes[0].City__c LIMIT 1];
                    if (!cities.isEmpty() && cities[0].State_Code__c != null) {
                        branchWarp.stateCode = cities[0].State_Code__c;
                    } else {
                        branchWarp.errorCode = 'City Master has state code empty or no city master found.';
                    }
                } else {
                    branchWarp.errorCode = 'Pincode Master has Pincode Master, City or State is empty.';
                }
            } else {
                branchWarp.errorCode = 'Account list is empty or has no pincode.';
            }
        }
        return branchWarp;
    }

    @AuraEnabled
    public static List<String> updateInvoiceRecords(string records, string profile, string action){
        system.debug('profile: '+profile);

        List<string> result = new List<string>();

        try {
            List<Vendor_Invoice_Action_Master__mdt> actionList = [SELECT Id, Next_Status__c, Success_Meaage__c FROM Vendor_Invoice_Action_Master__mdt WHERE Profile__c =: profile 
                                                                    AND Action__c =: action And Next_Status__c != '' LIMIT 1]; 
            system.debug('actionList: '+actionList);

            if(!actionList.isEmpty()){
                List<Object> recordList = (List<Object>)JSON.deserializeUntyped(records);
                system.debug('recordList: '+recordList);
                String nextStatus = actionList[0].Next_Status__c;
                List<Vendor_Invoice__c> recToUpdate = new List<Vendor_Invoice__c>();
    
                for(Object item : recordList){
                    Vendor_Invoice__c rec = (Vendor_Invoice__c)JSON.deserialize(JSON.serialize(item), Vendor_Invoice__c.class);
                    rec.Remarks__c = '['+ nextStatus +'] - '+ rec.Remarks__c;
                    rec.Status__c = nextStatus;
                    recToUpdate.add(rec);
                }
    
                System.debug('recToUpdate: '+recToUpdate);
                update recToUpdate;

                //update related payouts status
                List<Vendor_Invoice__c> payoutToUpdate = new List<Vendor_Invoice__c>();
                Set<Id> vendorInvoiceRecId = new Set<Id>();
                for(Vendor_Invoice__c rec : [SELECT Id, Status__c FROM Vendor_Invoice__c Where Invoice__c =: recToUpdate]){
                    rec.Status__c = actionList[0].Next_Status__c;
                    payoutToUpdate.add(rec);
                    vendorInvoiceRecId.add(rec.Id);
                }
                
                update payoutToUpdate;
    
                String userGroup = '';
                String title = 'Payout Assigned';
                if (action == 'Submit Invoice') {
                    userGroup = 'All Finance Users';
                } else if (action == 'Approve') {
                    userGroup = 'DSA';
                }
                if (!vendorInvoiceRecId.isEmpty()) {
                    for(Id record : vendorInvoiceRecId) {
                        PayoutManagementController.sendNotificationToUsers(record, 'assigned to you', title, userGroup);
                    }
                }
                result.add('Success');
                result.add(actionList[0].Success_Meaage__c);
            }
            else{
                result.add('Master data not found, please contact to System Admin.');
            }
        } 
        catch (Exception e) {
            system.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
            result.add(e.getMessage());
        }

        return result;
    }

    @AuraEnabled
    public static List<string> getInvoice(string recordId, string fileName, string conDocId){

        Savepoint sp = Database.setSavepoint();
        List<string> result = new List<string>();

        try{
            result.addAll(createOrUpdateInvoiceDoc(recordId, fileName, conDocId));
        }
        catch (Exception e) {
            Database.rollback(sp);
            result.add(e.getMessage());
        }

        return result;
    }

    private static List<string> createOrUpdateInvoiceDoc(string recordId, string fileName, String conDocId){
        system.debug('recordId: '+recordId);
        system.debug('fileName: '+fileName);
        system.debug('conDocId: '+conDocId);

        List<string> result = new List<string>();

        List<Document_Details__c> existingDocs = [
            SELECT Id, Name, Content_Document_Id__c, Description__c, File_Type__c FROM Document_Details__c
            WHERE EntityReferenceId__c =: recordId And EntityReferenceName__c = 'Vendor_Invoice__c' AND Name =: fileName And Active__c = true LIMIT 1
        ];
        
        Document_Details__c dd;
        if(!existingDocs.isEmpty()) {
            //if new document uploaded then update the existing doc detail record
            if(String.isNotBlank(conDocId) && existingDocs[0].Content_Document_Id__c != conDocId){
                system.debug('inside update');
                existingDocs[0].Content_Document_Id__c = conDocId;
                existingDocs[0].Description__c = 'New file uploaded at: '+ System.now();
                update existingDocs[0];
            }

            result.add('Success');
            if(String.isNotBlank(conDocId)) {
                result.add(conDocId);
            } else {
                result.add(existingDocs[0].Content_Document_Id__c);
            }
            result.add(existingDocs[0].File_Type__c);
        }
        else {
            List<Document_Master__c> docMaster = [Select Id, Document_Name__c, Is_Required__c From Document_Master__c Where Document_Category__c = 'Invoice' 
                                                    And Document_Name__c = 'Invoice' And Is_Active__c = true Limit 1];

            if(!docMaster.isEmpty()){
                dd = new Document_Details__c();
                dd.Process_Name__c = fileName.contains('Inv_') ? 'Invoice Creation' : 'Supplier Logo Upload';
                dd.Name = fileName;
                dd.Document_Master__c = docMaster[0].Id;
                dd.Description__c = 'File uploaded '+ fileName;
                dd.Is_Required__c = docMaster[0].Is_Required__c;
                dd.EntityReferenceId__c = recordId;
                dd.EntityReferenceName__c = 'Vendor_Invoice__c';
                dd.File_Type__c = fileName.contains('Inv_') ? 'pdf' : 'image';
                insert dd;

                string fileType = '';
                if(String.isBlank(conDocId)){
                    conDocId = generateInvoicePdf(recordId, fileName);
                    fileType = 'pdf';
                }
                else{
                    List<ContentDocumentLink> cdlList = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId =: recordId LIMIT 1];
                    if (cdlList.isEmpty()) {
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.ContentDocumentId = conDocId;
                        cdl.LinkedEntityId = recordId;
                        cdl.ShareType = 'V';
                        cdl.Visibility = 'AllUsers';
                        insert cdl;
                    }
                }

                dd.Content_Document_Id__c = conDocId;
                dd.Status__c = 'Uploaded';
                update dd;

                result.add('Success');
                result.add(conDocId);
                result.add(dd.File_Type__c);
            }
            else {
                result.add('Master data not found, please contact to System Admin.');
            }
        }

        return result;
    }

    private static string generateInvoicePdf(string recordId, string fileName){
        system.debug('recordId: '+recordId);
        system.debug('fileName: '+fileName);
		  Blob pdfBlob;

        if(Test.isRunningTest()){
            // Fake PDF content for test context
            pdfBlob = Blob.valueOf('Test PDF Content');
        }
        else{
                //Generate PDF from VF page
        PageReference pdfPage = Page.InvoicePage;
        pdfPage.getParameters().put('Id', recordId);
        pdfPage.setRedirect(true);
        pdfBlob = pdfPage.getContentAsPDF();
        }
    
        //Create ContentVersion (upload PDF)
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = fileName +'.pdf';
        contentVersion.PathOnClient = fileName +'.pdf';
        contentVersion.VersionData = pdfBlob;
        contentVersion.FirstPublishLocationId = recordId;
        insert contentVersion;

        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: contentVersion.Id LIMIT 1];
        return insertedCV.ContentDocumentId;
    }

    @AuraEnabled
    public static List<string> reGenerateInvoiceFile(string recordId, string fileName){
        List<String> result = new List<String>();

        result.add('Success');
        result.add(generateInvoicePdf(recordId, fileName));

        List<Document_Details__c> existingDocs = [
            SELECT Id, Content_Document_Id__c, Description__c FROM Document_Details__c
            WHERE EntityReferenceId__c =: recordId And EntityReferenceName__c = 'Vendor_Invoice__c' AND Name =: fileName And Active__c = true LIMIT 1
        ];

        existingDocs[0].Content_Document_Id__c = result[1];
        existingDocs[0].Description__c = 'Invoice regenerated at: '+ System.now();
        update existingDocs;

        return result;
    }

    @AuraEnabled
    public static List<string> deleteInvoiceRecord(string recordId, string profile, string action){
        
        Savepoint sp = Database.setSavepoint();
        List<string> result = new List<string>();

        try{
            List<Vendor_Invoice_Action_Master__mdt> actionList = [SELECT Id, Next_Status__c, Success_Meaage__c FROM Vendor_Invoice_Action_Master__mdt 
                                                                    WHERE Profile__c =: profile AND Action__c =: action And Next_Status__c != '' LIMIT 1]; 
            system.debug('actionList: '+actionList);

            if(!actionList.isEmpty()){
                List<Vendor_Invoice__c> existingPayout = [SELECT Id, Status__c FROM Vendor_Invoice__c Where Invoice__c =: recordId];
                if(!existingPayout.isEmpty()){
                    for(Vendor_Invoice__c rec : existingPayout){
                        rec.Invoice__c = null;
                        rec.Status__c = actionList[0].Next_Status__c;
                    }

                    update existingPayout;
                }

                //deleteDocument(recordId, '');
                
                List<Vendor_Invoice__c> invRec = [SELECT Id FROM Vendor_Invoice__c Where Id =: recordId];
                delete invRec;

                result.add('Success');
                result.add(actionList[0].Success_Meaage__c);
            }
            else{
                result.add('Master data not found, please contact to System Admin.');
            }
        }
        catch(Exception e) {
            system.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
            Database.rollback(sp);
            result.add(e.getMessage());
        }

        return result;
    }

    private static void deleteDocument(string recordId, string name){
        List<Document_Details__c> docs = new List<Document_Details__c>();

        if(String.isNotBlank(name)){
            //deleting a specific document
            docs = [Select Id, Active__c From Document_Details__c Where EntityReferenceId__c =: recordId And Name =: name And Active__c = true];
        }
        else {
            //deleting all document
            docs = [Select Id, Active__c From Document_Details__c Where EntityReferenceId__c =: recordId And Active__c = true];
        }

        if(!docs.isEmpty()){
            for(Document_Details__c rec : docs){
                rec.Active__c = false;
            }

            update docs;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Account getAgencyDetails() {
        return [Select Id, Name, PAN_Number__c, HSN_HAC_Code__c From Account Where Id In (Select AccountId From User Where Id =: UserInfo.getUserId())];
    }

    @AuraEnabled
    public static PayoutRecWrapper getPayoutRecMaster(String payoutId){
        PayoutRecWrapper payoutRec = new PayoutRecWrapper();
        List<Vendor_Invoice__c> vendorInvoiceRec = [SELECT Id, Branch_Master__c, Branch_Master__r.Pincode__r.State__c, Branch_Master__r.Pincode__r.City__r.State_Code__c FROM Vendor_Invoice__c WHERE Id =:payoutId LIMIT 1];
        if (!vendorInvoiceRec.isEmpty()) {
            payoutRec.branchMaster = vendorInvoiceRec[0].Branch_Master__c;
            payoutRec.state = vendorInvoiceRec[0].Branch_Master__r.Pincode__r.State__c;
            payoutRec.stateCode = vendorInvoiceRec[0]. Branch_Master__r.Pincode__r.City__r.State_Code__c;
        }
        return payoutRec;
    }

    public class PayoutRecWrapper {
        @AuraEnabled
        public String branchMaster;
        @AuraEnabled
        public String state;
        @AuraEnabled
        public String stateCode;
    }
    
    @AuraEnabled
    public static List<String> saveInvoiceRecord(string param, string profile, string action){
        system.debug('profile: '+profile);
        system.debug('param: '+ param);
        Savepoint sp = Database.setSavepoint();
        List<string> result = new List<string>();

        try {
            List<Vendor_Invoice_Action_Master__mdt> actionList = [SELECT Id, Next_Status__c, Previous_Status__c, Success_Meaage__c FROM Vendor_Invoice_Action_Master__mdt 
                                                                    WHERE Profile__c =: profile AND Action__c =: action And Next_Status__c != '' LIMIT 1]; 
            system.debug('actionList: '+actionList);

            if(!actionList.isEmpty()){

                if(action == 'Update Invoice' && String.isBlank(actionList[0].Previous_Status__c)){
                    result.add('Master data not found, please contact to System Admin.');
                    return result;
                }

                Vendor_Invoice__c invRec = new Vendor_Invoice__c();
                Map<string, string> paramMap = (Map<String, String>) JSON.deserialize(param, Map<String, String>.class);
                Map<Id, Vendor_Invoice__c> existingPayoutMap;
                
                if(paramMap.containsKey('recordId')){
                    invRec.Id = paramMap.get('recordId');
                    System.debug('inside paramMap.containsKey RecId');
                    existingPayoutMap = new Map<Id, Vendor_Invoice__c>([SELECT Id, Status__c, Invoice__r.Existing_Invoice_No__c FROM Vendor_Invoice__c Where Invoice__c =: invRec.Id]);
                }
                else {
                    invRec.RecordTypeId = Schema.SObjectType.Vendor_Invoice__c.getRecordTypeInfosByName().get('Invoice').getRecordTypeId();
                    invRec.Status__c = 'Invoice Generated';
                    invRec.Customer_Name__c = paramMap.get('customerName');

                    existingPayoutMap = new Map<Id, Vendor_Invoice__c>();
                }
                System.debug('existingPayoutMap : '+existingPayoutMap);
                invRec.CIN_Number__c = paramMap.get('cinNumber');
                invRec.Amount__c = Decimal.valueOf(paramMap.get('totalAmount'));
                invRec.CGST__c = paramMap.get('cgstAmount') != null ? Decimal.valueOf(paramMap.get('cgstAmount')) : null;
                invRec.IGST__c = paramMap.get('igstAmount') != null ? Decimal.valueOf(paramMap.get('igstAmount')) : null;
                invRec.SGST__c = paramMap.get('sgstAmount') != null ? Decimal.valueOf(paramMap.get('sgstAmount')) : null;
                invRec.UGST__c = paramMap.get('ugstAmount') != null ? Decimal.valueOf(paramMap.get('ugstAmount')) : null;
                invRec.GST_Applicable__c = paramMap.get('selectedGSTApplicable');
                invRec.Disbursed_Amount__c = Decimal.valueOf(paramMap.get('totalDisbursedAmount'));
                invRec.Existing_Invoice_No__c = paramMap.get('existingInvNo');
                invRec.Is_Supplier_Logo_Uploaded__c = Boolean.valueOf(paramMap.get('supplierLogoUploaded'));
                invRec.GST_Type__c = paramMap.get('selectedGSTType');
                invRec.CGST_Type__c = paramMap.get('selectedCGSTType');
                invRec.DSA__c = paramMap.get('dsaId');
                invRec.DSA_Bank__c = paramMap.get('selectedBank');
                invRec.DSA_Address__c = paramMap.get('selectedAddress');
                invRec.Branch_Master__c = paramMap.get('branchMaster');
                invRec.Invoice_Type__c = paramMap.get('selectedInvoiceType');
                invRec.HSN_HAC_Code__c = paramMap.get('hsnhacCode');
                if(String.isNotBlank(paramMap.get('existingInvNo'))) {
                    invRec.Name = paramMap.get('existingInvNo');
                    invRec.Is_Existing_Invoice_Uploaded__c = Boolean.valueOf(paramMap.get('existingInvoiceUploaded'));
                }
                else {
                    integer seqNo = Utility.getVendorInvoiceNextNumber('Invoice');
                    integer charSize = String.valueOf(seqNo).length();
                    string seqName = 'I-';
                    while (charSize <9) {
                        seqName += '0';
                        charSize++;
                    }
                    if(!paramMap.containsKey('recordId')) {
                        invRec.Name = seqName + seqNo;
                    }
                    invRec.Is_Existing_Invoice_Uploaded__c = false;
                }
                System.debug('upsert invRec: '+invRec);
                upsert invRec;

                string oldExistingInvNo = '';
                List<Vendor_Invoice__c> recToUpdate = new List<Vendor_Invoice__c>();
                List<string> selectedIdList = paramMap.get('selectedPayoutId').split(',');
                System.debug('selectedIdList: '+selectedIdList);
                for(string recId : selectedIdList){
                    if(!existingPayoutMap.containsKey(recId)){
                        Vendor_Invoice__c rec = new Vendor_Invoice__c( Id = recId, Invoice__c = invRec.Id, Status__c = actionList[0].Next_Status__c );
                        recToUpdate.add(rec);
                    }
                }

                //delink the existing payout which is removed from invoice
                for(Vendor_Invoice__c rec : existingPayoutMap.values()){
                    if(!selectedIdList.contains(rec.Id)){
                        rec.Invoice__c = null;
                        rec.Status__c = actionList[0].Previous_Status__c;
                        recToUpdate.add(rec);
                    }

                    oldExistingInvNo = rec.Invoice__r.Existing_Invoice_No__c;
                }

                System.debug('payout recToUpdate: '+recToUpdate);
                update recToUpdate;

                result.add('Success');
                result.add(actionList[0].Success_Meaage__c);

                //creating doc detail record for existing invoice
                if(String.isNotBlank(paramMap.get('invoiceFileId'))){
                    List<string> docRes = createOrUpdateInvoiceDoc(invRec.Id, ('Inv_'+ invRec.Id), (string) paramMap.get('invoiceFileId'));
                    if(docRes[0] != 'Success'){
                        result = docRes;
                    }
                }
                else {
                    //delete document when removed from screen
                    string crInvoiceNo = (string) paramMap.get('existingInvNo');
                    if(String.isNotBlank(oldExistingInvNo) && String.isBlank(crInvoiceNo)){
                        deleteDocument(invRec.Id, ('Inv_'+ invRec.Id));
                    }
                }

                string logoFileName = 'Logo_'+ invRec.Id;

                //creating doc detail record for supplier logo 
                if(String.isNotBlank(paramMap.get('supLogoFileId'))){
                    List<string> docRes = createOrUpdateInvoiceDoc(invRec.Id, logoFileName, (string) paramMap.get('supLogoFileId'));
                    if(docRes[0] != 'Success'){
                        result = docRes;
                    }
                }
                else{
                    //delete uploaded logo
                    List<Document_Details__c> existingDocs = [
                        SELECT Id, Content_Document_Id__c FROM Document_Details__c
                        WHERE EntityReferenceId__c =: invRec.Id And EntityReferenceName__c = 'Vendor_Invoice__c' AND Name =: logoFileName And Active__c = true LIMIT 1
                    ];

                    if(!existingDocs.isEmpty()){
                        existingDocs[0].Content_Document_Id__c = null;
                        update existingDocs;
                        
                        delete existingDocs;
                    }
                }
            }
            else{
                result.add('Master data not found, please contact to System Admin.');
            }
        } 
        catch (Exception e) {
            system.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
            Database.rollback(sp);
            result.clear();
            result.add(e.getMessage());
        }

        return result;
    }

    @AuraEnabled
    public static List<string> getContentVersionIds(string recordIds){
        
        List<string> result = new List<string>();
        Set<Id> conDocIdSet = new Set<Id>();
        string conIds = '';
        List<string> recordIdList = recordIds.removeEnd(',').split(',');
        
        system.debug('recordIdList: '+recordIdList);

        for(Document_Details__c rec : [SELECT Id, Content_Document_Id__c FROM Document_Details__c
                                        WHERE EntityReferenceId__c In : recordIdList And EntityReferenceName__c = 'Vendor_Invoice__c' 
                                        AND Process_Name__c = 'Invoice Creation' And Active__c = true]){

            conDocIdSet.add(rec.Content_Document_Id__c);
        }

        for(ContentVersion rec : [SELECT Id FROM ContentVersion Where ContentDocumentId In : conDocIdSet]){
            conIds += rec.Id +'/';
        }

        result.add('Success');

        if(String.isNotBlank(conIds)){
            result.add(conIds.removeEnd('/') +'?');
        }
        else {
            result.add('No files found.');
        }

        return result;
    }

    @AuraEnabled
    public static Boolean validateInvoiceNumber(string recordId, string invoiceNo){
        List<Vendor_Invoice__c> exisInv = [Select Id From Vendor_Invoice__c Where Id !=: recordId And Existing_Invoice_No__c =: invoiceNo];
        return exisInv.size() >0;
    }

    @AuraEnabled
    public static Customer_Address__c getAddressDetails(string recordId){
        return [Select Id, GST_Number__c, State_Code__c, Place_of_Supply_State__c, Pincode__r.City__r.State_Code__c From Customer_Address__c Where Id =: recordId];
    }

    @AuraEnabled
    public static Map<string, string> getAddressToShow(){

        Map<string, string> result = new Map<string, string>();
        for(Customer_Address__c add : [Select Id, Full_Address1__c From Customer_Address__c Where Customer__c In (Select AccountId From User Where Id =: UserInfo.getUserId()) 
                                        And Address_Related_To__c = 'DSA' Order By CreatedDate Desc]){

            result.put(add.Id, add.Full_Address1__c);
        }

        return result;
    }

    @AuraEnabled
    public static Map<string, string> getBanksToShow(){

        Map<string, string> result = new Map<string, string>();
        for(Bank_Details__c bnk : [Select Id, Account_Number__c, Name From Bank_Details__c Where Customer__c In (Select AccountId From User Where Id =: UserInfo.getUserId()) 
                                    And Bank_Related_To__c = 'DSA' Order By CreatedDate Desc]){

            result.put(bnk.Id, (bnk.Account_Number__c +' ['+ bnk.Name +']'));
        }

        return result;
    }

    public class InvoiceWrapper {
        @AuraEnabled public string recordId;
        @AuraEnabled public string name;
        @AuraEnabled public decimal amount;
        @AuraEnabled public decimal disbursedAmount;
        @AuraEnabled public string remarks;
        @AuraEnabled public string status;
        @AuraEnabled public Boolean existingInvoiceUploaded;
        @AuraEnabled public string nameOfAgency;
        @AuraEnabled public string agencyAddress;
        @AuraEnabled public string agencyBank;
        @AuraEnabled public string invoiceDate;
        @AuraEnabled public string urnNo;
    }

    @AuraEnabled
    public static List<Vendor_Invoice__c> getPayoutRecsFromInvoice(String recordId){
        try {
            List<Vendor_Invoice__c> pay = [SELECT Customer_Name__c,CustomerName__c, FIN_Refrence_No__c, Loan_Number__c, Disbursed_Amount__c, Amount__c, Booking_Month__c, Sanction_Loan_Amount__c, 
                                        Payout_Percentage__c, HSN_HAC_Code__c, Branch_Master__c
                                        FROM Vendor_Invoice__c WHERE RecordType.Name = 'Payout' AND Invoice__c =: recordId Order By Name];
            return pay;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}