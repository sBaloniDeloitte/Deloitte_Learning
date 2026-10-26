public with sharing class AHL_LoanTransactionTriggerImplementation {
    
    public static void preventUpdateIfPricingApprovedOrPending(List<Loan_Transaction__c> newRecords, Map<Id, Loan_Transaction__c> oldRecordsMap) {
        Set<Id> loanApplicationIds = new Set<Id>();
        
        // Step 1: Fetch the current user's profile name
        String currentUserProfileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        System.debug('Current User Profile Name: ' + currentUserProfileName);
        
        // Step 2: Apply restriction only if profile name is 'Sales'
        if (!currentUserProfileName.equalsIgnoreCase('Sales')) {
            System.debug('Profile is not Sales, skipping validation.');
            return; // Exit the method if the user is not from Sales profile
        }
        
        // Collect all related Loan Application IDs from Loan Transactions
        for (Loan_Transaction__c transactionRec : newRecords) {
            if (transactionRec.Loan_Application__c != null) {
                loanApplicationIds.add(transactionRec.Loan_Application__c);
            }
        }
        
        if (loanApplicationIds.isEmpty()) {
            return;
        }
        
        // Fetch the related Loan Applications with the required fields
        Map<Id, Opportunity> loanApplicationMap = new Map<Id, Opportunity>(
            [SELECT Id, Pricing_Approval_Status__c 
             FROM Opportunity 
             WHERE Id IN :loanApplicationIds]
            );
        
        // Check each Loan Transaction's related Loan Application
        for (Loan_Transaction__c transactionRec : newRecords) {
            Opportunity relatedApplication = loanApplicationMap.get(transactionRec.Loan_Application__c);
            
            if (relatedApplication != null &&
                (relatedApplication.Pricing_Approval_Status__c == 'Submitted For Approval' ||
            relatedApplication.Pricing_Approval_Status__c == 'Approved')) {
                
                // Compare with old value to see if a change is attempted
                Loan_Transaction__c oldTransaction = oldRecordsMap.get(transactionRec.Id);
                
                if (oldTransaction != null && !transactionRec.equals(oldTransaction)) { // Check if any changes are made
                    System.debug('inside If::' + transactionRec);
                    
                    // Prevent update and show error for Sales Profile only
                    transactionRec.addError('You cannot update this record as the related Loan Application\'s Pricing Approval Status is either "Submitted For Approval" or "Approved".');
                }
            }
        }
    }
    
    public static void updateLoanTransactionFields(List<Loan_Transaction__c> newRecords, Map<Id, Loan_Transaction__c> oldRecordsMap) {
        System.debug('newRecords: ' + newRecords);
        
        List<Loan_Transaction__c> recordsToUpdate = new List<Loan_Transaction__c>();
        
        for (Loan_Transaction__c transactionRec : newRecords) {
            
            if (transactionRec.Loan_Tenor__c != null && transactionRec.Interest_Frequency__c != null) {
                
                if (transactionRec.Interest_Frequency__c == 'M') {
                    transactionRec.Number_of_Instruments__c = transactionRec.Loan_Tenor__c;
                } else if (transactionRec.Interest_Frequency__c == 'Every Two Months') {
                    transactionRec.Number_of_Instruments__c = transactionRec.Loan_Tenor__c / 2;
                } else if (transactionRec.Interest_Frequency__c == 'Q') {
                    transactionRec.Number_of_Instruments__c = transactionRec.Loan_Tenor__c / 3;
                } else if (transactionRec.Interest_Frequency__c == 'H') {
                    transactionRec.Number_of_Instruments__c = transactionRec.Loan_Tenor__c / 6;
                } else if (transactionRec.Interest_Frequency__c == 'Y') {
                    transactionRec.Number_of_Instruments__c = transactionRec.Loan_Tenor__c / 12;
                }
                
                Integer monthsToAdd = 0;
                if (transactionRec.Interest_Frequency__c == 'M') {
                    monthsToAdd = 1;
                } else if (transactionRec.Interest_Frequency__c == 'Every Two Months') {
                    monthsToAdd = 2;
                } else if (transactionRec.Interest_Frequency__c == 'Q') {
                    monthsToAdd = 3;
                } else if (transactionRec.Interest_Frequency__c == 'H') {
                    monthsToAdd = 6;
                } else if (transactionRec.Interest_Frequency__c == 'Y') {
                    monthsToAdd = 12;
                }
                
                if (transactionRec.Interest_Due_date__c != null && monthsToAdd > 0) {
                    Date today = Date.today();
                    Date nextDueDate = today.addMonths(monthsToAdd);
                    
                    Integer dueDay;
                    if (transactionRec.Interest_Due_date__c == '03') {
                        dueDay = 3;
                    } else if (transactionRec.Interest_Due_date__c == '05') {
                        dueDay = 5;
                    } else if (transactionRec.Interest_Due_date__c == '06') {
                        dueDay = 6;
                    } else if (transactionRec.Interest_Due_date__c == '31') {
                        dueDay = 31;
                    } else {
                        dueDay = nextDueDate.day();
                    }
                    
                    Integer nextYear = nextDueDate.year();
                    Integer nextMonth = nextDueDate.month();
                    
                    try {
                        transactionRec.Next_Repayment_Date__c = Date.newInstance(nextYear, nextMonth, dueDay);
                    } catch (Exception e) {
                        transactionRec.Next_Repayment_Date__c = Date.newInstance(nextYear, nextMonth, 1).addDays(-1);
                    }
                }
            }
        }
    }
    
    public static void handleQDPProcess(List<Loan_Transaction__c> newRecords) {
        
        Set<Id> loanApplicationIds = new Set<Id>();
        Set<Id> loanIdsForStageChange = new Set<Id>();
        
        // Collect all related Loan Application IDs from Loan Transactions
        for (Loan_Transaction__c transactionRec : newRecords) {
            if (transactionRec.Loan_Application__c != null) {
                loanApplicationIds.add(transactionRec.Loan_Application__c);
            }
        }
        
        // Fetch the related Loan Applications with the required fields
        Map<Id, Opportunity> loanApplicationMap = new Map<Id, Opportunity>(
            [SELECT Id, Name, Owner.Email, Owner.Name 
            FROM Opportunity
            WHERE Id IN :loanApplicationIds]
            );
        
        EmailTemplate emailTemplate =[SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'QDP_For_Loan_Application' LIMIT 1];
        List<TAT__c> tatRecordsToInsert = new List<TAT__c>();
        TAT_Master__mdt tatMasters = [SELECT Id,Code__c, Activity__c, Stage__c, Sub_Activity__c FROM TAT_Master__mdt WHERE Activity__c= 'Sub Stage Change' AND Is_Active__c = true AND code__C = 'C-040' LIMIT 1];
        
        for (Loan_Transaction__c transactionRec : newRecords) {
            Opportunity relatedApplication = loanApplicationMap.get(transactionRec.Loan_Application__c);
            if(transactionRec.QDP_Status__c == 'Print'){
                //TAT record creation
                TAT__c tatRecord = new TAT__c();
                tatRecord.Stage__c = tatMasters.Stage__c;
                tatRecord.Activity__c = tatMasters.Activity__c;
                tatRecord.Sub_Activity__c = tatMasters.Sub_Activity__c;
                tatRecord.User_Name__c = UserInfo.getUserId();
                tatRecord.Code__c = tatMasters.Code__c;
                tatRecord.Timestamp__c = System.now();
                tatRecord.Loan_Application__c = relatedApplication.Id;
                tatRecord.End_Timestamp__c = System.now();
                tatRecordsToInsert.add(tatRecord);
                
                //send email notification
                //Map<String,String> inputMap = new Map<String,String>();
                String emailBody =  emailTemplate.HtmlValue;
                emailBody = emailBody.replace('{receiverName}', relatedApplication.Owner.Name);
                emailBody = emailBody.replace('{loanNumber}', relatedApplication.Name);
                emailBody = emailBody.replace('{status}', 'completed successfully.');
                // inputMap.put('content',emailBody) ;
                // inputMap.put('subject','QDP for Loan application successfully completed') ;
                // inputMap.put('email', relatedApplication.Owner.Email) ;
                // inputMap.put('loanId', relatedApplication.Id) ;
                // inputMap.put('processName','Email');
                //EmailController.initiateAPIRequest(inputMap);
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[] {relatedApplication.Owner.Email});
                email.setSubject('QDP for Loan application successfully completed');
                email.setHtmlBody(emailBody);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            }
            else{ //QDP-FAILURE
                //send email notification
                String emailBody =  emailTemplate.HtmlValue;
                emailBody = emailBody.replace('{receiverName}', relatedApplication.Owner.Name);
                emailBody = emailBody.replace('{loanNumber}', relatedApplication.Name);
                emailBody = emailBody.replace('{status}', 'failed.');
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[] {relatedApplication.Owner.Email});
                email.setSubject('QDP for Loan application failed');
                email.setHtmlBody(emailBody);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
                
                //Stage will be reversed to Ops Maker
                loanIdsForStageChange.add(transactionRec.Loan_Application__c);
            }
        }
        
        if (!tatRecordsToInsert.isEmpty()){
            insert tatRecordsToInsert;
        }
        
        if (!loanIdsForStageChange.isEmpty()) {
            List<Opportunity> oppList = new List<Opportunity>();
            for (Id oppId : loanIdsForStageChange) {
                oppList.add(new Opportunity(Id = oppId, Sub_stage__c = 'Ops Maker'));
            }
            update oppList;
        }
    }
    
    public static void handleCreateDisbursement(List<Loan_Transaction__c> loanTransactionList) {
        System.debug('loanTransactionList' + loanTransactionList);
        Set<Id> loanIdsToCall = new Set<Id>();
        Set<Id> loanApplicationIds = new Set<Id>();
        List<Loan_Transaction__c> paymentTxtList = [SELECT Id, RecordType.DeveloperName,Loan_Application__c FROM Loan_Transaction__c WHERE Id IN:loanTransactionList];
        
        for (Loan_Transaction__c transactionRec : paymentTxtList) {
            if (transactionRec.RecordType.DeveloperName == 'Payment' && transactionRec.Loan_Application__c != null) {
                loanApplicationIds.add(transactionRec.Loan_Application__c);
            }
        }
        
        List<Loan_Transaction__c> loanTxn = [SELECT Id,Quick_Disbursement__c,QDP_Status__c,Loan_Application__r.LMS_Loan_Reference__c,Loan_Application__c
                                                FROM   Loan_Transaction__c
                                                WHERE  Loan_Application__c IN :loanApplicationIds
                                                AND    RecordType.DeveloperName = 'Transaction_Details'];
        
        for (Loan_Transaction__c transactionRec : loanTxn) {
            if(transactionRec.Quick_Disbursement__c == true && transactionRec.QDP_Status__c == 'Awaiting for confirmation' && transactionRec.Loan_Application__r.LMS_Loan_Reference__c != null){
                loanIdsToCall.add(transactionRec.Loan_Application__c);
            }
        }
        
        System.debug('loanIdsToCall' + loanIdsToCall);
        
        if (!loanIdsToCall.isEmpty()) {
            AHL_CreateDisbursementService.callCreateDisbursement(loanIdsToCall);
        }
    }
    
    public static void handleAfterInsertPennyDrop(List<Loan_Transaction__c> loanTransactionList) {
        Set<Id> txnIdsToCall = new Set<Id>();
        System.debug('loanTransactionList' + loanTransactionList);
        
        List<Loan_Transaction__c> ltList = [SELECT Id, RecordType.DeveloperName FROM Loan_Transaction__c WHERE Id IN:loanTransactionList];
        
        for (Loan_Transaction__c txn : ltList) {
            if (txn.RecordType.DeveloperName == 'Payment') {
                txnIdsToCall.add(txn.Id);
            }
        }
        
        System.debug('txnIdsToCall' + txnIdsToCall);
        
        if (!txnIdsToCall.isEmpty()) {
            PennyDropService.callPennyDrop(txnIdsToCall);
        }
    }
    
    public static void handleAfterUpdatePennyDrop(List<Loan_Transaction__c> loanTransactionList, Map<Id, Loan_Transaction__c> oldRecordsMap){
        Set<Id> txnIdsToCall = new Set<Id>();
        
        Set<Id> txnIds = new Map<Id, Loan_Transaction__c>(loanTransactionList).keySet();
        
        List<Loan_Transaction__c> txnsWithRecordType = [
            SELECT Id, Bank__c, RecordType.DeveloperName
            FROM Loan_Transaction__c
            WHERE Id IN :txnIds
        ];
        
        for (Loan_Transaction__c txn : txnsWithRecordType) {
            Loan_Transaction__c oldTxn = oldRecordsMap.get(txn.Id);
            
            if (
                txn.RecordType.DeveloperName == 'Payment' &&
                oldTxn != null &&
                txn.Bank__c != oldTxn.Bank__c
            ) {
                txnIdsToCall.add(txn.Id);
            }
        }
        
        if (!txnIdsToCall.isEmpty()) {
            PennyDropService.callPennyDrop(txnIdsToCall);
        }
    }
    public static void syncLoanStartDateToVasValueDate(List<Loan_Transaction__c> newRecords, Map<Id, Loan_Transaction__c> oldRecordsMap) {
        try {
            Boolean isInsert = (oldRecordsMap == null);
            
            Set<Id> candidateTxnIds = new Set<Id>();
            for (Loan_Transaction__c txn : newRecords) {
                if (isInsert) {
                    if (txn.Loan_Start_Date__c != null) {
                        candidateTxnIds.add(txn.Id);
                    }
                } else {
                    Loan_Transaction__c oldTxn = oldRecordsMap.get(txn.Id);
                    if (oldTxn != null && txn.Loan_Start_Date__c != oldTxn.Loan_Start_Date__c) {
                        candidateTxnIds.add(txn.Id);
                    }
                }
            }
            
            if (candidateTxnIds.isEmpty()) {
                return;
            }
            
            List<Loan_Transaction__c> txnDetails = [
            SELECT Id,
                   Loan_Application__c,
                   Loan_Start_Date__c,
                   Loan_Application__r.Product__c,
                   Loan_Application__r.Loan_Hierarchy__c,
                   Loan_Application__r.Split_Parent_Loan_Application__c
            FROM Loan_Transaction__c
            WHERE Id IN :candidateTxnIds
            AND RecordType.DeveloperName = 'Transaction_Details'
        ];
            
            if (txnDetails.isEmpty()) {
                return;
            }
            
            Map<String, Date> keyToStartDate = new Map<String, Date>();
            Set<Id> effectiveLoanAppIds = new Set<Id>();
            Set<String> productNames = new Set<String>();
            
            for (Loan_Transaction__c txn : txnDetails) {
                if (txn.Loan_Application__c == null || txn.Loan_Application__r == null) {
                    continue;
                }
                
                String currentProductName = txn.Loan_Application__r.Product__c;
                if (String.isBlank(currentProductName)) {
                    continue;
                }
                
                Id effectiveLoanAppId;
                String productType;
                
                if (txn.Loan_Application__r.Loan_Hierarchy__c == 'Child'
                && txn.Loan_Application__r.Split_Parent_Loan_Application__c != null) {
                    effectiveLoanAppId = txn.Loan_Application__r.Split_Parent_Loan_Application__c;
                    productType = 'Child';
                } else {
                    effectiveLoanAppId = txn.Loan_Application__c;
                    productType = 'Parent';
                }
                
                Date newStartDate = null;
                if (txn.Loan_Start_Date__c != null) {
                    newStartDate = Date.newInstance(
                        txn.Loan_Start_Date__c.year(),
                    txn.Loan_Start_Date__c.month(),
                    txn.Loan_Start_Date__c.day()
                        );
                }
                
                String key = String.valueOf(effectiveLoanAppId) + '|' + productType + '|' + currentProductName;
                keyToStartDate.put(key, newStartDate);
                effectiveLoanAppIds.add(effectiveLoanAppId);
                productNames.add(currentProductName);
            }
            
            if (keyToStartDate.isEmpty() || effectiveLoanAppIds.isEmpty() || productNames.isEmpty()) {
                return;
            }
            
            List<Charges_Insurance__c> vasRecords = [
            SELECT Id, Loan_Application__c, Value_Date__c, Category__c,
                   Product__c, Product__r.Product_Type__c, Product_Name__c
            FROM Charges_Insurance__c
            WHERE Loan_Application__c IN :effectiveLoanAppIds
            AND Category__c = 'Insurance'
            AND Product_Name__c IN :productNames
        ];
            
            if (vasRecords.isEmpty()) {
                return;
            }
            
            List<Charges_Insurance__c> vasToUpdate = new List<Charges_Insurance__c>();
            for (Charges_Insurance__c vas : vasRecords) {
                String vasProductType = (vas.Product__c != null && vas.Product__r != null)
                    ? vas.Product__r.Product_Type__c
                    : null;
                if (String.isBlank(vasProductType) || String.isBlank(vas.Product_Name__c)) {
                    continue;
                }
                
                String lookupKey = String.valueOf(vas.Loan_Application__c) + '|' + vasProductType + '|' + vas.Product_Name__c;
                if (!keyToStartDate.containsKey(lookupKey)) {
                    continue;
                }
                
                Date newStartDate = keyToStartDate.get(lookupKey);
                if (vas.Value_Date__c != newStartDate) {
                    vas.Value_Date__c = newStartDate;
                    vasToUpdate.add(vas);
                }
            }
            
            if (!vasToUpdate.isEmpty()) {
                update vasToUpdate;
                System.debug('CH07 : VAS Value_Date__c synced for records count = ' + vasToUpdate.size()
                    + ' | context = ' + (isInsert ? 'INSERT' : 'UPDATE'));
            }
        } catch (Exception e) {
            System.debug('CH07 : syncLoanStartDateToVasValueDate error :: ' + e.getMessage()
                + ' AT ' + e.getLineNumber()
                + ' STACKTRACE ' + e.getStackTraceString());
        }
    }
    
}