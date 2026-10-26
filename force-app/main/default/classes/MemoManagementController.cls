public with sharing class MemoManagementController {
    
    @AuraEnabled
    public static List<Opportunity> getLoanApplicationDetails(Id loanId){
        try {
            List<Opportunity> loanList = [SELECT Id, Loan_Application_Number__c, Lead__r.Lead_Number__c, Status__c, StageName, Lead__r.Channel__c,
                                           Sanction_Loan_Amount__c, Lead__r.Referred_By_DSA__r.Name FROM Opportunity WHERE Id = :loanId LIMIT 1];
            return loanList;
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getCurrentUserDetails(){
        List<string> result = new List<string>();
        result.add([Select Name From Profile Where Id =: UserInfo.getProfileId()].Name);
        result.add(UserInfo.getName());
        return result;
    }

    @AuraEnabled
    public static List<MemoWrapper> getMemoRecords(string fromDate, string toDate, string memoId, string status, string processName, string profile){

        System.debug('fromDate: '+fromDate);
        System.debug('toDate: '+toDate);
        System.debug('memoId: '+memoId);
        System.debug('status: '+status);
        System.debug('processName: '+processName);

        Map<string, Object> bindVars = new Map<string, Object>();

        string query = 'Select Id, Name, Remarks__c, Status__c '+
                        'From Vendor_Invoice__c Where RecordType.Name = \'Memo\' ';

        query += buildFilterQuery(fromDate, toDate, memoId, status, processName, profile, bindVars);
        
        System.debug('query: '+query);

        List<MemoWrapper> result = new List<MemoWrapper>();
        for(SObject rec : Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE)){

            MemoWrapper invoice = new MemoWrapper();
            invoice.recordId = (string) rec.get('Id');
            invoice.name = (string) rec.get('Name');
            invoice.status = (string) rec.get('Status__c');
            invoice.remarks = (string) rec.get('Remarks__c');

            result.add(invoice);
        }

        return result;
    }

    public static string buildFilterQuery(string fromDate, string toDate, string memoId, string status, string processName, string profile, Map<string, Object> bindVars){

        string query = '';
        
        if(fromDate != null && toDate != null){
            query += 'And CreatedDate >= ' + (date.valueOf(fromDate).toString().replace(' 00:00:00', 'T00:00:00.001+0000')) +' And CreatedDate <= ' + (date.valueOf(toDate).toString().replace(' 00:00:00', 'T23:59:59.999+0000')) + ' ';
        }

        if(String.isNotBlank(memoId)){
            bindVars.put('memoId', memoId);
            query += 'And Id =: memoId ';
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
                                                                            And Process_Name__c = 'Memo' And Status_to_Include__c != '' Limit 1];

            if(!recstatusList.isEmpty()){
                bindVars.put('statusIn', recstatusList[0].Status_to_Include__c.split(','));
                statusQuery = 'And Status__c IN : statusIn ';
            }
        }

        query += statusQuery + 'Order By Name ASC Limit 3000';

        return query;
    }

    public class MemoWrapper {
        @AuraEnabled public string recordId;
        @AuraEnabled public string name;
        @AuraEnabled public string remarks;
        @AuraEnabled public string remarksDet;
        @AuraEnabled public string status;
        @AuraEnabled public decimal amount;
        @AuraEnabled public string laNumber;
        @AuraEnabled public decimal originalRate;
        @AuraEnabled public decimal newRate;
        @AuraEnabled public string dsa;
        @AuraEnabled public string createdBy;
        @AuraEnabled public string createdDate;
        @AuraEnabled public string documentDetailId;
        @AuraEnabled public string documentDetailContent;
        @AuraEnabled public Boolean contentPresent;
        @AuraEnabled public Boolean isLocked;
        @AuraEnabled public Boolean isApproval;
    }
    
    @AuraEnabled
    public static String createMemoRecord(Map<String,String> inputMap){
        List<string> usrDetails = getCurrentUserDetails();
        String loanId = inputMap.get('loanId');
        String memoNo = inputMap.get('memoNo');
        String dsaName = inputMap.get('dsaName');
        String laNumber = inputMap.get('laNumber');
        String leadNumber = inputMap.get('leadNumber');
        String sanctionAmount = inputMap.get('sanctionAmount');
        String originalRate = inputMap.get('originalRate');
        String status = inputMap.get('status');
        String newRate = inputMap.get('newRate');
        String remarks = inputMap.get('remarks');
        String contentDocId = inputMap.get('uploadedContentId');
        String remarksHeader = usrDetails[1] +' ('+ usrDetails[0] +') - '+ Datetime.NOW().format('dd/MM/YYYY, hh:mm a') +':';
        String memoRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Vendor_Invoice__c','Memo');
        Vendor_Invoice__c vendorInvoice = new Vendor_Invoice__c();
        vendorInvoice.Name = memoNo;
        if(String.isNotBlank(sanctionAmount)){
            vendorInvoice.Amount__c = Decimal.valueOf(sanctionAmount);
        }
        vendorInvoice.Status__c = status;
        vendorInvoice.Old_Rate__c = Decimal.valueOf(originalRate);
        vendorInvoice.New_Rate__c = Decimal.valueOf(newRate);
        vendorInvoice.Remarks__c = 'Created - ' + remarksHeader + remarks;
        vendorInvoice.Loan_Application__c = loanId;
        vendorInvoice.RecordTypeId = memoRecordTypeId;
        insert vendorInvoice;
        if(contentDocId != null && contentDocId != '') {
        	saveDocumentDetails(contentDocId, vendorInvoice.Id, loanId, memoNo);
        }
        return vendorInvoice.Id;
    }
    
    public class MemoRemarkWrapper {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String remarksChanged;
    }
    
    @AuraEnabled
    public static void updateRemark(String vendorInvoiceRec, String method, String source, String remark, List<MemoRemarkWrapper> memoWrappers) {
        List<string> usrDetails = getCurrentUserDetails();
        String memoRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Vendor_Invoice__c', 'Memo');
        String remarksHeader = usrDetails[1] +' ('+ usrDetails[0] +') - '+ Datetime.NOW().format('dd/MM/YYYY, hh:mm a') +':';
        List<Vendor_Invoice__c> vendorInvoices = new List<Vendor_Invoice__c>(); 
        Set<Id> recIds = new Set<Id>();
        System.debug('source : '+source);
        if (source == 'Memo Generation') {
        	vendorInvoices = [SELECT Remarks__c FROM Vendor_Invoice__c WHERE Id = : vendorInvoiceRec AND 
                              RecordTypeId = :memoRecordTypeId LIMIT 1];
        } else if (source == 'Memo Management') {
            for (MemoRemarkWrapper wrap : memoWrappers) {
                recIds.add(wrap.recordId);
            }
            System.debug('recIds : '+recIds);
            vendorInvoices = [SELECT Remarks__c FROM Vendor_Invoice__c WHERE RecordTypeId = :memoRecordTypeId AND Id IN: recIds AND Manager_Name__c =: UserInfo.getUserId() 
                              AND Status__c IN ('Submitted for Approval', 'Memo Rejected Sales Head', 'Memo Approved Sales Head') ORDER BY CreatedDate ASC];
        }
        System.debug('vendorInvoices : '+vendorInvoices);
        if (!vendorInvoices.isEmpty()) {
            System.debug('source : '+source);
            if (source == 'Memo Generation') {
                Vendor_Invoice__c invoice = vendorInvoices[0];
                if (!String.isBlank(invoice.Remarks__c)) {
                    invoice.Remarks__c += '<br>' + method + ' - ' + remarksHeader + remark;
                } else {
                    invoice.Remarks__c = method + ' - ' + remarksHeader + remark;
                }
                update invoice;
            } else if (source == 'Memo Management') {
                System.debug('inside Memo Management');
                Map<Id, String> recordToRemark = new Map<Id, String>();
                for (MemoRemarkWrapper wrap : memoWrappers) {
                    recordToRemark.put(wrap.recordId, wrap.remarksChanged);
                }
                List<Vendor_Invoice__c> toUpdate = new List<Vendor_Invoice__c>();
                for (Vendor_Invoice__c invoice : vendorInvoices) {
                    String newRemark = recordToRemark.get(invoice.Id);
                    System.debug('newRemark : '+newRemark);
                    if (String.isNotBlank(newRemark)) {
                        if (!String.isBlank(invoice.Remarks__c)) {
                            invoice.Remarks__c += '<br>' + method + ' - ' + remarksHeader + newRemark;
                        } else {
                            invoice.Remarks__c = method + ' - ' + remarksHeader + newRemark;
                        }
                        toUpdate.add(invoice);
                    }
                }
                if (!toUpdate.isEmpty()) {
                    update toUpdate;
                }
            }
        }
    }
    
    @AuraEnabled
    public static void saveDocumentDetails(String contentDocumentId, String parentId, String loan, String memoNo) {
        try {
            Document_Details__c doc = new Document_Details__c();
            doc.Name = 'Memo: '+ memoNo;
            doc.Content_Document_Id__c  = contentDocumentId;
            doc.Reference_Id__c = parentId;
            doc.Status__c = 'Uploaded';
            doc.Loan_Application__c = loan;
            insert doc;
            
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocumentId;
            cdl.LinkedEntityId = parentId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<MemoWrapper> getFilteredVendorInvoiceMemoRecords(string fromDate, string toDate, string loanPayoutId, string status, string processName) {
        List<MemoWrapper> memoList = new List<MemoWrapper>();
		set<Id> vendorInvoiceIds = new set<Id>();
        Map<string, Object> bindVars = new Map<string, Object>();
        Map<Id, Document_Details__c> docDetailsMap = new Map<Id, Document_Details__c>();
        string query = 'SELECT Id, Name, Amount__c, Old_Rate__c, New_Rate__c, Status__c, Remarks__c, '+
                              'Loan_Application__r.Loan_Application_Number__c, CreatedBy.Name, '+
                              'Loan_Application__r.Lead__r.Referred_By_DSA__r.Name, CreatedDate '+
                              'FROM Vendor_Invoice__c WHERE RecordType.Name = \'Memo\' ';
        
        query += PayoutManagementController.buildFilterQuery(fromDate, toDate, loanPayoutId, '', '', status, processName, '', bindVars);
        System.debug('query '+query);
        List<Vendor_Invoice__c> vendorInvoices = Database.query(query);
        for (Vendor_Invoice__c vendorInvoice : vendorInvoices) {
            MemoWrapper wrapper = new MemoWrapper();
            wrapper.recordId = vendorInvoice.Id;
            vendorInvoiceIds.add(vendorInvoice.Id);
            wrapper.name = vendorInvoice.Name;
            wrapper.amount = vendorInvoice.Amount__c;
            wrapper.remarks = vendorInvoice.Remarks__c;
            wrapper.status = vendorInvoice.Status__c;
            if (vendorInvoice.Status__c == 'Memo Approved Sales Head') {
                wrapper.isLocked = true;
            } else {
                wrapper.isLocked = false;
            }
            wrapper.laNumber = vendorInvoice.Loan_Application__r.Loan_Application_Number__c;
            wrapper.originalRate = vendorInvoice.Old_Rate__c;
            wrapper.newRate = vendorInvoice.New_Rate__c;
            wrapper.dsa = vendorInvoice.Loan_Application__r.Lead__r.Referred_By_DSA__r.Name;
            wrapper.createdBy = vendorInvoice.CreatedBy.Name;
            wrapper.createdDate = vendorInvoice.CreatedDate.format();
            memoList.add(wrapper);
        }
        
        if (!vendorInvoiceIds.isEmpty()) {
            List<Document_Details__c> docList = [SELECT Id, Reference_Id__c, Content_Document_Id__c FROM Document_Details__c WHERE Reference_Id__c IN : vendorInvoiceIds];
            if (!docList.isEmpty()) {
                for (Document_Details__c doc : docList) {
                    docDetailsMap.put(doc.Reference_Id__c, doc);
                }
            }
        }
        
        for (MemoWrapper wrapper : memoList) {
            if (docDetailsMap.containsKey(wrapper.recordId)) {
                Document_Details__c doc = docDetailsMap.get(wrapper.recordId);
                wrapper.documentDetailId = doc.Id;
                if (doc.Content_Document_Id__c != null) {
                    wrapper.contentPresent = true;
                    wrapper.documentDetailContent = doc.Content_Document_Id__c;
                } else {
                    wrapper.contentPresent = false;
                }
            }
        }

        return memoList;
    }
    
    @AuraEnabled
	public static List<MemoWrapper> getVendorInvoiceMemoRecords(Id loanId, String process) {
        try {
            List<MemoWrapper> memoList = new List<MemoWrapper>();
            set<Id> vendorInvoiceIds = new set<Id>();
            String memoRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Vendor_Invoice__c', 'Memo');
            Map<Id, Document_Details__c> docDetailsMap = new Map<Id, Document_Details__c>();
            List<Vendor_Invoice__c> vendorInvoices = new List<Vendor_Invoice__c>(); 
            if (process == 'Manage') {
                vendorInvoices = [SELECT Id, Name, Amount__c, Old_Rate__c, New_Rate__c, Status__c, Remarks__c,
                                  Loan_Application__r.Loan_Application_Number__c, CreatedBy.Name,
                                  Loan_Application__r.Lead__r.Referred_By_DSA__r.Name, CreatedDate
                                  FROM Vendor_Invoice__c WHERE RecordTypeId = :memoRecordTypeId AND Manager_Name__c =: UserInfo.getUserId() AND Status__c IN ('Submitted for Approval', 'Memo Rejected Sales Head', 'Memo Approved Sales Head') ORDER BY CreatedDate ASC];            
            } else {
                vendorInvoices = [SELECT Id, Name, Amount__c, Old_Rate__c, New_Rate__c, Status__c, Remarks__c,
                                  Loan_Application__r.Loan_Application_Number__c, CreatedBy.Name,
                                  Loan_Application__r.Lead__r.Referred_By_DSA__r.Name, CreatedDate
                                  FROM Vendor_Invoice__c WHERE Loan_Application__c = :loanId AND 
                                  RecordTypeId = :memoRecordTypeId ORDER BY CreatedDate ASC];
            }
            for (Vendor_Invoice__c vendorInvoice : vendorInvoices) {
                MemoWrapper wrapper = new MemoWrapper();
                wrapper.recordId = vendorInvoice.Id;
                vendorInvoiceIds.add(vendorInvoice.Id);
                wrapper.name = vendorInvoice.Name;
                wrapper.amount = vendorInvoice.Amount__c;
                // wrapper.remarks = vendorInvoice.Remarks__c;
                wrapper.remarksDet = vendorInvoice.Remarks__c;
                if (String.isNotBlank(vendorInvoice.Remarks__c)) {
                    Integer lastColonIndex = vendorInvoice.Remarks__c.lastIndexOf(':');
                    if (lastColonIndex != -1 && lastColonIndex + 1 < vendorInvoice.Remarks__c.length()) {
                        wrapper.remarks = vendorInvoice.Remarks__c.substring(lastColonIndex + 1).trim();
                    } else {
                        wrapper.remarks = vendorInvoice.Remarks__c.trim();
                    }
                } else {
                    wrapper.remarks = '';
                }
                wrapper.status = vendorInvoice.Status__c;
                if (vendorInvoice.Status__c == 'Memo Approved Sales Head') {
                    wrapper.isLocked = true;
                    wrapper.isApproval = true;
                } else {
                    wrapper.isLocked = false;
                    if (vendorInvoice.Status__c == 'Submitted for Approval' || vendorInvoice.Status__c == 'Memo Approved Sales Head') {
                        wrapper.isApproval = true;
                    } else {
                        wrapper.isApproval = false;
                    }
                }
                wrapper.laNumber = vendorInvoice.Loan_Application__r.Loan_Application_Number__c;
                wrapper.originalRate = vendorInvoice.Old_Rate__c;
                wrapper.newRate = vendorInvoice.New_Rate__c;
                wrapper.dsa = vendorInvoice.Loan_Application__r.Lead__r.Referred_By_DSA__r.Name;
                wrapper.createdBy = vendorInvoice.CreatedBy.Name;
                wrapper.createdDate = vendorInvoice.CreatedDate.format();
                memoList.add(wrapper);
            }
            
            if (!vendorInvoiceIds.isEmpty()) {
                List<Document_Details__c> docList = [SELECT Id, Reference_Id__c, Content_Document_Id__c FROM Document_Details__c WHERE Reference_Id__c IN : vendorInvoiceIds AND Active__c = true];
                if (!docList.isEmpty()) {
                    for (Document_Details__c doc : docList) {
                        docDetailsMap.put(doc.Reference_Id__c, doc);
                    }
                }
            }
            
            for (MemoWrapper wrapper : memoList) {
                if (docDetailsMap.containsKey(wrapper.recordId)) {
                    Document_Details__c doc = docDetailsMap.get(wrapper.recordId);
                    wrapper.documentDetailId = doc.Id;
                    if (doc.Content_Document_Id__c != null) {
                        wrapper.contentPresent = true;
                        wrapper.documentDetailContent = doc.Content_Document_Id__c;
                    } else {
                        wrapper.contentPresent = false;
                    }
                }
            }
    
            return memoList;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching memo records: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void updateDocumentDetails(String contentDocumentId, String parentId, String loan) {
        try {
            String memoRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Vendor_Invoice__c', 'Memo');
            List<Vendor_Invoice__c> memoList = [SELECT Id, Name FROM Vendor_Invoice__c WHERE Id = :parentId AND Loan_Application__c = :loan 
                                               AND RecordTypeId = :memoRecordTypeId];
            String memoNo = '';
            if (!memoList.isEmpty()) {
                memoNo = memoList[0].Name;
                List<Document_Details__c> docDets = [SELECT Id, Name, Content_Document_Id__c FROM Document_Details__c WHERE Reference_Id__c =: parentId AND Loan_Application__c = :loan AND Active__c = true LIMIT 1];
                if (!docDets.isEmpty()) {
                    docDets[0].Active__c = false;
                    update docDets[0];
                }
                Document_Details__c doc = new Document_Details__c();
                doc.Name = 'Memo: '+ memoNo;
                doc.Content_Document_Id__c  = contentDocumentId;
                doc.Reference_Id__c = parentId;
                doc.Status__c = 'Uploaded';
                doc.Loan_Application__c = loan;
                insert doc;
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = contentDocumentId;
                cdl.LinkedEntityId = parentId;
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                insert cdl;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string getUserToAssign(String loanId){
        try {
            String userId;
            List<Opportunity> loanRec = [SELECT Id, Name, Lead__r.Dsa_Area_Manager__c, Branch_Master__c FROM Opportunity WHERE Id =: loanId LIMIT 1];
            if (!loanRec.isEmpty() && String.isNotBlank(loanRec[0].Lead__r.Dsa_Area_Manager__c)) {
                System.debug('loanRec[0].Lead__r.Dsa_Area_Manager__c : '+loanRec[0].Lead__r.Dsa_Area_Manager__c);
                List<User> usrList = [SELECT Id, Name, ManagerId, Manager.Name, Manager.ManagerId, Manager.Manager.Name, Manager.Manager.ManagerId, 
                                      Manager.Manager.Manager.Name FROM User WHERE Profile.Name = 'Sales' AND Position_Title__c = 'Area Manager' 
                                      AND Id =: loanRec[0].Lead__r.Dsa_Area_Manager__c];
                if(!usrList.isEmpty()) {
                    User areaMgr = usrList[0];
                    List<Map<String, String>> managerList = new List<Map<String, String>>();
                    if (areaMgr != null) {
                        managerList.add(new Map<String, String>{ 'Id' => areaMgr.Id, 'Name' => areaMgr.Name });
                        if (areaMgr.ManagerId != null) {
                            managerList.add(new Map<String, String>{ 'Id' => areaMgr.ManagerId, 'Name' => areaMgr.Manager.Name });
                        }
                        if (areaMgr.Manager != null && areaMgr.Manager.ManagerId != null) {
                            managerList.add(new Map<String, String>{ 'Id' => areaMgr.Manager.ManagerId, 'Name' => areaMgr.Manager.Manager.Name });
                        }
                        if (areaMgr.Manager != null && areaMgr.Manager.Manager != null && areaMgr.Manager.Manager.ManagerId != null) {
                            managerList.add(new Map<String, String>{ 'Id' => areaMgr.Manager.Manager.ManagerId, 'Name' => areaMgr.Manager.Manager.Manager.Name });
                        }
                    }
                    System.debug('managerList : '+managerList);
                    Set<Id> managerIds = new Set<Id>();
                    for (Map<String, String> mgr : managerList) {
                        if (mgr.containsKey('Id')) {
                            managerIds.add(mgr.get('Id'));
                        }
                    }
                    if (!managerIds.isEmpty() && loanRec[0].Branch_Master__c != null) {
                        List<AccountTeamMember> atmList = [SELECT Id, UserId, Level__c, TeamMemberRole FROM AccountTeamMember
                            								WHERE AccountId = :loanRec[0].Branch_Master__c AND UserId IN :managerIds];
                        Map<String, String> priorityMap = new Map<String, String>{
                            'L3' => null,
                            'L4' => null,
                            'L5' => null
                        };
                        for (AccountTeamMember atm : atmList) {
                            if (atm.Level__c == 'L3' && priorityMap.get('L3') == null) {
                                priorityMap.put('L3', atm.UserId);
                            } else if (atm.Level__c == 'L4' && priorityMap.get('L4') == null) {
                                priorityMap.put('L4', atm.UserId);
                            } else if (atm.Level__c == 'L5' && priorityMap.get('L5') == null) {
                                priorityMap.put('L5', atm.UserId);
                            }
                        }
                        System.debug('priorityMap : '+priorityMap);
                        if (priorityMap.get('L3') != null) {
                            userId = priorityMap.get('L3');
                        } else if (priorityMap.get('L4') != null) {
                            userId = priorityMap.get('L4');
                        } else if (priorityMap.get('L5') != null) {
                            userId = priorityMap.get('L5');
                        }
                    }

                }
            }
            System.debug('Final userId : '+userId);
            return userId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void sendApprovalEmail(Id userId, Id opportunityId) {
        String approverMail;
        String approverName;
        List<User> users = [SELECT Id, Name, Email FROM User WHERE Id = :userId LIMIT 1];
        if (!users.isEmpty() && users[0].Email != null && users[0].Name != null) {
            approverMail = users[0].Email;
            approverName = users[0].Name;
            List<Vendor_Invoice__c> memoRecs = [SELECT Id, Name, Manager_Name__c, Loan_Application__r.Name FROM Vendor_Invoice__c WHERE Loan_Application__c =: opportunityId];
            if (!memoRecs.isEmpty() && userId == memoRecs[0].Manager_Name__c) {
                List<String> ccList= new List<String>();
                ccList.add('memo_approval_email_service@1j7luojkwr16ghv70grxhlyfv86l83fb71sh6zm9ql5i9qkgmm.bl-1o3jhmaa.ind8s.apex.sandbox.salesforce.com');
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[] { approverMail });
                email.setSubject('Memo Approval Request: ' + memoRecs[0].Name);
                email.setCcAddresses(ccList);
                email.setPlainTextBody(
                    'Dear ' + approverName + ',\n\n' +
                    'Please review the memo for Opportunity: ' + memoRecs[0].Loan_Application__r.Name + ' (Memo No: ' + memoRecs[0].Name + ').\n\n' +
                    'Reply with one of the following at the very top of your email:\n' +
                    'APPROVE\n' +
                    'REJECT\n\n' +
                    'Memo Number: ' + memoRecs[0].Name + '\n\n' +
                    'Thank you.'
                );
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            }
        }
    }
}