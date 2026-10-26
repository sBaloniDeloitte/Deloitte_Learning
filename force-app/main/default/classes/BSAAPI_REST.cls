/*
* Created By : Ishi Jain
* Created Date : 24/01/2024
* Purpose : Exposing this class as a REST API to manage call back from BSA.
*/

@RestResource(urlMapping='/api/BSACallBack')
global with sharing class BSAAPI_REST {
    @HttpPost
    global static void getBSADetails() {
        try{
            Integration_Details__c integrationDetail = new Integration_Details__c();
            RestRequest restReq = RestContext.request;
            String requestBody = restReq.requestBody.toString();
            System.debug('requestBody--'+requestBody);
            List<Document_Details__c> ddListPerfios = new List<Document_Details__c> ();
            BSAResponseWrapper callbackResp = (BSAResponseWrapper) JSON.deserialize(requestBody, BSAResponseWrapper.class);
            // Map<String, Object> baseMap  =(Map<String, Object>) JSON.deserializeUntyped(requestBody);
            // if (baseMap.containsKey('traceId') && (Boolean)baseMap.get('status') == false) {
            //     System.debug('❌ BSA callback failed: ' + requestBody);
               
            //     if(baseMap.containsKey('perfiosTransactionId') && baseMap.get('perfiosTransactionId')!=null ){
            //         String perfiosId ;
            //         perfiosId = String.valueof(baseMap.get('perfiosTransactionId'));
            //         ddListPerfios  = [Select Id, Transaction_ID__c, Loan_Application__c,Applicant__c,Manual_AA__c from Document_Details__c where Transaction_ID__c =:perfiosId];
            //     }

            //     integrationDetail.Calling_Source__c = 'BSA_CallBack1';
            //     integrationDetail.Endpoint__c = 'https://api.bsa.com/callback';
            //     integrationDetail.Response_JSON__c =requestBody;
            
               
            
            //     integrationDetail.Object_Name__c = 'Document_Details__c';
            //     integrationDetail.Name = 'BSACallBack -1';
            //     integrationDetail.Related_Record_Id__c =ddListPerfios[0].id ;
            //     insert integrationDetail;
            //     System.debug('❌integrationDetail ' + integrationDetail);
               
               
            // }

            if (callbackResp != null && callbackResp.status == false && callbackResp.traceId!= null  ) {
                System.debug('❌ BSA callback failed: ' + callbackResp.message);
                
                String perfiosId = callbackResp.perfiosTransactionId;
                if (String.isNotBlank(perfiosId)) {
                    ddListPerfios = [
                        SELECT Id,Loan_Application__c FROM Document_Details__c WHERE Transaction_ID__c = :perfiosId LIMIT 1
                    ];
                    if (!ddListPerfios.isEmpty()) {
                        integrationDetail.Related_Record_Id__c = ddListPerfios[0].Id;
                    }
                }
                    integrationDetail.Calling_Source__c = 'BSA_CallBack1';
                    integrationDetail.Endpoint__c = 'https://api.bsa.com/callback';
                    integrationDetail.Response_JSON__c =requestBody;
                
                   
                
                    integrationDetail.Object_Name__c = 'Document_Details__c';
                    integrationDetail.Name = 'BSACallBack -1';
                    integrationDetail.Related_Record_Id__c =ddListPerfios[0].id ;
                    integrationDetail.Loan_Application__c  =ddListPerfios[0].Loan_Application__c ;
                    insert integrationDetail;
                    System.debug('❌integrationDetail ' + integrationDetail);
                      Refresh_Event__e event = new Refresh_Event__e(
                        Loan_Application_Id__c = ddListPerfios[0].Loan_Application__c
                    );
                    EventBus.publish(event);
            }
            
            else{
                // List<Document_Master__c> docMaster = [Select Id, Name, Requirement_Level__c 
                // FROM Document_Master__c where Name = :'Bank Statement Analysis Response'];
                // ContentVersion contentVersion = new ContentVersion();
                // contentVersion.Title = 'CallbackResponse';
                // contentVersion.PathOnClient = 'CallbackResponse.txt';
                // contentVersion.VersionData = Blob.valueOf(requestBody);//Blob.valueOf(restReq.requestBody.toString());
                // insert contentVersion;
                // Set<String> cvIds = new Set<String>();
                // cvIds.add(contentVersion.Id);

                String resp = restReq.requestBody.toString();
                // List<String> result = new List<String>();
                // Integer stringLength = resp.length();
                // Integer chunkSize = 20000;

                // for (Integer i = 0; i < stringLength; i += chunkSize) {
                // // Get a substring of the desired chunk size or the remaining portion
                // String chunk = resp.substring(i, Math.min(i + chunkSize, stringLength));
                // chunk = chunk.replaceAll('date','dateVal');
                // result.add(chunk);
                // }
                // resp = string.join(result,'');
                COMM_BSAResponseService respWrap = (COMM_BSAResponseService)JSON.deserialize(resp, COMM_BSAResponseService.class);
                if(respWrap.status==false && respWrap.data.status=='REJECTED'){

                      String perfiosId = respWrap.data.perfiosTransactionId;
                        if (String.isNotBlank(perfiosId)) {
                            ddListPerfios = [
                                SELECT Id,Loan_Application__c FROM Document_Details__c WHERE Transaction_ID__c = :perfiosId LIMIT 1
                            ];
                            if (!ddListPerfios.isEmpty()) {
                                integrationDetail.Related_Record_Id__c = ddListPerfios[0].Id;
                            }
                        }
                    integrationDetail.Calling_Source__c = 'BSA_CallBack2';
                    integrationDetail.Endpoint__c = 'https://api.bsa.com/callback';
                    integrationDetail.Response_JSON__c =requestBody;
                
                   integrationDetail.Loan_Application__c  =ddListPerfios[0].Loan_Application__c ;
                
                    integrationDetail.Object_Name__c = 'Document_Details__c';
                    integrationDetail.Name = 'BSACallBack -2';
                    integrationDetail.Related_Record_Id__c =ddListPerfios[0].id ;
                    insert integrationDetail;
                    System.debug('❌integrationDetail ' + integrationDetail);
                      Refresh_Event__e event = new Refresh_Event__e(
                        Loan_Application_Id__c = ddListPerfios[0].Loan_Application__c
                    );
                    EventBus.publish(event);

                }
                // else{

                //       Applicant_Address__c appAddress = new Applicant_Address__c();
                // ContentVersion contVer = new ContentVersion();
                // contVer.Title = 'BSAExcel';
                // contVer.PathOnClient = 'BSAExcel.xlsx';
                // contVer.VersionData = EncodingUtil.base64Decode(respWrap.data.bsaByteReport);//Blob.valueOf(restReq.requestBody.toString());
                // insert contVer;
                // cvIds.add(contVer.Id);


                // //BSAResponseService respWrap = (BSAResponseService)JSON.deserialize(requestBody.replaceAll('date','dateVal'), BSAResponseService.class);
                // // BSAResponseService respWrap = (BSAResponseService)JSON.deserialize(restReq.requestBody.toString().replaceAll('date','dateVal'), BSAResponseService.class);
                // String bankName = respWrap.data.bsaReport.customerInfo.bank;
                // List<Document_Details__c> ddList = [Select Id, Transaction_ID__c, Applicant__c,Manual_AA__c from Document_Details__c where Transaction_ID__c =: respWrap.data.perfiosTransactionId];
                // List<Id> appIds = new List<Id>();
                // for(Document_Details__c ddl:ddList){
                // appIds.add(ddl.Applicant__c);
                // }
                // List<Application_Applicant__c> appList = [Select Id,Customer__c from Application_Applicant__c where id IN : appIds];

                // List<ContentVersion> contentVersionId = [SELECT Id,ContentDocumentId FROM ContentVersion WHERE Id IN :cvIds];
                // Map<Id, ContentVersion> conVerMap = new Map<Id, ContentVersion>(contentVersionId);
                // ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                // Document_Details__c dd = new Document_Details__c();
                // dd.Content_Document_Id__c = conVerMap.get(contentVersion.Id).ContentDocumentId;
                // dd.Name='CallbackResponse';
                // dd.Document_Master__c =docMaster[0].id;
                // dd.Applicant__c=appList[0].Id;

                // Document_Details__c ddExcel = new Document_Details__c();
                // ddExcel.Content_Document_Id__c = conVerMap.get(contVer.Id).ContentDocumentId;
                // ddExcel.Name='BSAExcel';
                // ddExcel.Applicant__c=appList[0].Id;
                // ddExcel.Status__c = 'Uploaded';

                // insert new List<Document_Details__c>{dd,ddExcel};
                // Document_Details__c bsaExcel = [SELECT id,Content_Document_Id__c FROM Document_Details__c WHERE Applicant__c =:appList[0].Id AND Name = 'BSAExcel' ORDER BY CreatedDate DESC LIMIT 1];
                // ContentDocumentLink cdl = new ContentDocumentLink();
                // cdl.LinkedEntityId = bsaExcel.id; 
                // cdl.ContentDocumentId = bsaExcel.Content_Document_Id__c;
                // cdl.ShareType = 'V';
                // cdl.Visibility = 'AllUsers'; 
                // insert cdl;


                // List<Bank_Details__c> existingBankList = [Select Id,Account_Number__c, Application_Applicant__c from Bank_Details__c where Application_Applicant__c in: appIds];
                // Map<String,Bank_Details__c> acctToBankMap = new Map<String,Bank_Details__c>();
                // for(Bank_Details__c b : existingBankList){
                // acctToBankMap.put(b.Account_Number__c,b);
                // }
                // List<Bank_Details__c> bankDetalList = new List<Bank_Details__c>();
                // for(BSAResponseService.cls_accountXns iterResp:respWrap.data.bsaReport.accountXns){
                // Bank_Details__c bank = new Bank_Details__c();
                // if(acctToBankMap.containsKey(iterResp.accountNo) && acctToBankMap.get(iterResp.accountNo) != null){
                // bank.Id=acctToBankMap.get(iterResp.accountNo).Id;
                // }

                // bank.Account_Number__c = iterResp.accountNo;
                // if(ddList[0].Manual_AA__c =='AA'){
                // bank.Name = bankName;

                // }
                // bank.Application_Applicant__c=appList[0].id;
                // if(String.isNotBlank(iterResp.accountType)) {
                // if(iterResp.accountType.contains('Current')) {
                // bank.Account_Type__c = 'Current';
                // }else if (iterResp.accountType.contains('Saving')){
                // bank.Account_Type__c = 'Saving';
                // }
                // else if(iterResp.accountType.contains('Overdraft Account')){
                //     bank.Account_Type__c = 'Overdraft';
                // }
                // else{
                //     bank.Account_Type__c = 'CC';
                // }

                // }else {
                // bank.Account_Type__c = 'Saving';
                // }
                // bank.Account_Holder_Name__c =respWrap.data.bsaReport.customerInfo.name;
                // //bank.Account_Type__c = String.isNotBlank(iterResp.accountType)?iterResp.accountType:'Saving';
                // bank.Account_Holder_Name__c =respWrap.data.bsaReport.customerInfo.name;
                // bank.Customer__c = appList[0].Customer__c;
                // bankDetalList.add(bank);
                // }
                // Map<String,Bank_Details__c> accNumToBankMap = new Map<String,Bank_Details__c>();
                // if(bankDetalList.size()>0){
                // Upsert bankDetalList;
                // List<Bank_Details__c> bankList = [Select Id, Account_Number__c from Bank_Details__c where Id in: bankDetalList];
                // for(Bank_Details__c b : bankList){
                // accNumToBankMap.put(b.Account_Number__c,b);
                // }
                // }
                // List<Bank_Statement_Analysis__c> bankStatementList = new List<Bank_Statement_Analysis__c>();
                // List<Bank_Statement_Analysis__c> parentBankStatementList = new List<Bank_Statement_Analysis__c>();
                // for(BSAResponseService.cls_accountAnalysis iterResp:respWrap.data.bsaReport.accountAnalysis){
                // Bank_Statement_Analysis__c parentBsa = new Bank_Statement_Analysis__c();
                // parentBsa.RecordTypeId =  Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis');
                // parentBsa.Bank_Details__c = accNumToBankMap.get(iterResp.accountNo).Id;
                // parentBsa.Full_Month_Count__c = iterResp.summaryInfo.fullMonthCount;
                // parentBankStatementList.add(parentBsa);
                // //BSA_EMI_LOAN_TRACK.storeEmiRecords(parentBsa,iterResp.loanTrackDetails);
                // }
                // Map<String, Bank_Statement_Analysis__c> accountToBSAMap = new Map<String, Bank_Statement_Analysis__c>();
                // if(parentBankStatementList.size()>0){
                // Insert parentBankStatementList;
                // List<Bank_Statement_Analysis__c> parentList = [Select Id, Bank_Details__r.Account_Number__c from Bank_Statement_Analysis__c where Id in: parentBankStatementList];
                // for(Bank_Statement_Analysis__c b : parentList){
                // accountToBSAMap.put(b.Bank_Details__r.Account_Number__c,b);
                // }
                // }
                // Map<String,List<Bank_Statement_Analysis__c>> accountNumToChildBsas = new Map<String,List<Bank_Statement_Analysis__c>>();
                // Map<String,Bank_Statement_Analysis__c> accountNumToChildBsa = new Map<String,Bank_Statement_Analysis__c>();
                // Map<String,Bank_Statement_Analysis__c> monthToChildBsa = new Map<String,Bank_Statement_Analysis__c>();
                // for(BSAResponseService.cls_accountAnalysis iterResp:respWrap.data.bsaReport.accountAnalysis){
                // for(BSAResponseService.cls_monthlyDetails iterMonth: iterResp.monthlyDetails){
                // if(monthToChildBsa.containsKey(iterResp.accountNo+'-'+iterMonth.monthName)){

                // Bank_Statement_Analysis__c bsa = monthToChildBsa.get(iterResp.accountNo+'-'+iterMonth.monthName);

                // bsa.Total_number_of_inward_Cheque_return__c += iterMonth.inwChqBounces;
                // bsa.Total_number_of_inward_ECS_return__c += iterMonth.inwECSBounces;
                // bsa.Value_of_loan_disbursal__c += iterMonth.totalLoanDisbursal;
                // bsa.Total_number_of_out_bounce__c += iterMonth.outwBounces;
                // bsa.Total_Number_of_circular_transactions__c += iterMonth.samePartyAmountCreditDebits;
                // bsa.Sanction_Limit__c += iterMonth.snLimit;
                // bsa.Total_Amount_of_EMI__c += iterMonth.totalEmiEcsLoanIssue;
                // bsa.Total_Amount_of_Intrest_Charged__c += iterMonth.totalInterestCharged;
                // bsa.Count_of_loan_disbursal__c += iterMonth.loanDisbursals;
                // bsa.Total_Amount_of_Circular_Transactions__c += iterMonth.totalSamePartyAmountCreditDebit;
                // bsa.Total_Cash_Deposit__c += iterMonth.totalCashDeposit;
                // bsa.Total_Credit__c += iterMonth.totalCredit;
                // bsa.Total_Debit__c += iterMonth.totalDebit;
                // bsa.Total_Cash_Withdrawal__c += iterMonth.totalCashWithdrawal;
                // bsa.Total_number_of_credits__c += iterMonth.credits;
                // bsa.Total_number_of_debits__c += iterMonth.debits;
                // bsa.Average_EOD_Balance__c += iterMonth.balAvg;
                // monthToChildBsa.put(iterResp.accountNo+'-'+iterMonth.monthName, bsa);
                // accountNumToChildBsa.put(iterResp.accountNo,bsa);
                // }
                // else{
                // Bank_Statement_Analysis__c bsa = new Bank_Statement_Analysis__c();
                // bsa.RecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','Derived_Analysis');
                // bsa.Account_Number__c = iterResp.accountNo;
                // bsa.Bank_Details__c = accNumToBankMap.get(iterResp.accountNo).Id;
                // bsa.Parent_Bant_Statement__c = accountToBSAMap.get(iterResp.accountNo).Id;
                // bsa.Total_number_of_inward_Cheque_return__c = iterMonth.inwChqBounces != null? iterMonth.inwChqBounces:0;
                // bsa.Total_number_of_inward_ECS_return__c = iterMonth.inwECSBounces != null ? iterMonth.inwECSBounces:0;
                // bsa.Value_of_loan_disbursal__c = iterMonth.totalLoanDisbursal != null ? iterMonth.totalLoanDisbursal:0;
                // bsa.Total_Number_of_circular_transactions__c = iterMonth.samePartyAmountCreditDebits != null?iterMonth.samePartyAmountCreditDebits:0;
                // bsa.Total_Amount_of_EMI__c = iterMonth.totalEmiEcsLoanIssue != null ? iterMonth.totalEmiEcsLoanIssue:0;
                // bsa.Total_Amount_of_Intrest_Charged__c = iterMonth.totalInterestCharged != null ? iterMonth.totalInterestCharged:0;
                // bsa.Count_of_loan_disbursal__c = iterMonth.loanDisbursals != null ? iterMonth.loanDisbursals:0;
                // bsa.Total_number_of_out_bounce__c = iterMonth.outwBounces != null ? iterMonth.outwBounces : 0;
                // bsa.Total_Cash_Deposit__c = iterMonth.totalCashDeposit != null ? iterMonth.totalCashDeposit : 0;
                // bsa.Total_Credit__c = iterMonth.totalCredit != null ? iterMonth.totalCredit : 0;
                // bsa.Total_Debit__c = iterMonth.totalDebit != null ? iterMonth.totalDebit : 0;
                // bsa.Total_Cash_Withdrawal__c = iterMonth.totalCashWithdrawal != null ? iterMonth.totalCashWithdrawal : 0;
                // bsa.Total_number_of_credits__c = iterMonth.credits != null ? iterMonth.credits : 0;
                // bsa.Total_number_of_debits__c = iterMonth.debits != null ? iterMonth.debits : 0;

                // bsa.Month__c = iterMonth.monthName;
                // bsa.Average_EOD_Balance__c = iterMonth.balAvg != null ? iterMonth.balAvg : 0;
                // bsa.Sanction_Limit__c = iterMonth.snLimit;
                // bsa.Total_Amount_of_Circular_Transactions__c = iterMonth.totalSamePartyAmountCreditDebit;
                // monthToChildBsa.put(iterResp.accountNo+'-'+iterMonth.monthName, bsa);

                // if(accountNumToChildBsas.containsKey(iterResp.accountNo)){
                // accountNumToChildBsas.get(iterResp.accountNo).add(bsa);
                // }
                // else{
                // accountNumToChildBsas.put(iterResp.accountNo, new List<Bank_Statement_Analysis__c>{bsa});
                // }
                // accountNumToChildBsa.put(iterResp.accountNo,bsa);
                // }

                // }
                // }
                // Integer i = 1;
                // for(String accountNumber : accountNumToChildBsas.keySet()) {
                // if(i == 1){
                // for(BSAResponseService.cls_MonthlyData1 iterAdditional : respWrap.data.bsaReport.AdditionalMonthlyDetails.MonthlyData1){
                // List<Bank_Statement_Analysis__c> childList = accountNumToChildBsas.get(accountNumber);
                // for(Bank_Statement_Analysis__c bsa : childList){
                // if(bsa.Month__c == iterAdditional.monthName){
                // bsa.Total_Self_and_Related_Party_Credit__c = iterAdditional.numberOfSelfAndRelatedPartyCreditTxns;
                // bsa.Amount_of_Self_and_Related_Party_Credit__c = iterAdditional.totalOfSelfAndRelatedPartyCreditTxns;
                // bsa.Total_Number_of_Business_Credits__c = iterAdditional.numberOfBusinessCreditTxns;
                // bsa.Total_Amount_of_Business_Credits__c = iterAdditional.totalBusinessCreditTxns;
                // bsa.Total_Self_and_Related_Party_Debit__c = iterAdditional.numberOfSelfAndRelatedPartyDebitTxns;
                // bsa.Amount_of_Self_and_Related_Party_Debit__c = iterAdditional.totalOfSelfAndRelatedPartyDebitTxns;
                // bsa.Total_Number_of_Business_Debits__c = iterAdditional.numberOfBusinessDebitTxns;
                // bsa.Total_Amount_of_Business_Debits__c = iterAdditional.totalBusinessDebitTxns;
                // bsa.Cash_Deposit_to_total_Credit__c = iterAdditional.cashDepositToTotalCreditPercent;
                // bsa.Cash_withdrwal_to_total_Debit__c = iterAdditional.cashWithdrawalToTotalDebitPercent;
                // bsa.Total_number_of_inward_return__c = iterAdditional.totalNumberOfInwardReturnsToTotalDebitPercent;
                // bsa.I_w_retruns_as_of_total_debits__c = iterAdditional.totalAmountOfInwardReturnsToTotalDebitPercent;
                // bsa.Total_number_of_outward_return__c = iterAdditional.totalNumberOfOutwardReturnsToTotalCreditPercent;
                // bsa.O_w_retruns_as_of_total_credits__c = iterAdditional.totalAmountOfOutwardReturnsToTotalCreditPercent;
                // bsa.Average_Limit_Utilisation__c = iterAdditional.averageLimitUtilization;
                // bsa.ABB__c = iterAdditional.aBBBal5Bal15Bal25Bal30;
                // bankStatementList.add(bsa);
                // }
                // }
                // }
                // }
                // if(i == 2) {
                // for(BSAResponseService.cls_MonthlyData1 iterAdditional : respWrap.data.bsaReport.AdditionalMonthlyDetails.MonthlyData2){
                // List<Bank_Statement_Analysis__c> childList = accountNumToChildBsas.get(accountNumber);
                // for(Bank_Statement_Analysis__c bsa : childList){
                // if(bsa.Month__c == iterAdditional.monthName){
                // bsa.Total_Self_and_Related_Party_Credit__c = iterAdditional.numberOfSelfAndRelatedPartyCreditTxns;
                // bsa.Amount_of_Self_and_Related_Party_Credit__c = iterAdditional.totalOfSelfAndRelatedPartyCreditTxns;
                // bsa.Total_Number_of_Business_Credits__c = iterAdditional.numberOfBusinessCreditTxns;
                // bsa.Total_Amount_of_Business_Credits__c = iterAdditional.totalBusinessCreditTxns;
                // bsa.Total_Self_and_Related_Party_Debit__c = iterAdditional.numberOfSelfAndRelatedPartyDebitTxns;
                // bsa.Amount_of_Self_and_Related_Party_Debit__c = iterAdditional.totalOfSelfAndRelatedPartyDebitTxns;
                // bsa.Total_Number_of_Business_Debits__c = iterAdditional.numberOfBusinessDebitTxns;
                // bsa.Total_Amount_of_Business_Debits__c = iterAdditional.totalBusinessDebitTxns;
                // bsa.Cash_Deposit_to_total_Credit__c = iterAdditional.cashDepositToTotalCreditPercent;
                // bsa.Cash_withdrwal_to_total_Debit__c = iterAdditional.cashWithdrawalToTotalDebitPercent;
                // bsa.Total_number_of_inward_return__c = iterAdditional.totalNumberOfInwardReturnsToTotalDebitPercent;
                // bsa.I_w_retruns_as_of_total_debits__c = iterAdditional.totalAmountOfInwardReturnsToTotalDebitPercent;
                // bsa.Total_number_of_outward_return__c = iterAdditional.totalNumberOfOutwardReturnsToTotalCreditPercent;
                // bsa.O_w_retruns_as_of_total_credits__c = iterAdditional.totalAmountOfOutwardReturnsToTotalCreditPercent;
                // bsa.Average_Limit_Utilisation__c = iterAdditional.averageLimitUtilization;
                // bsa.ABB__c = iterAdditional.aBBBal5Bal15Bal25Bal30;
                // bankStatementList.add(bsa);
                // }
                // }
                // }
                // }
                // if(i == 3){
                // for(BSAResponseService.cls_MonthlyData1 iterAdditional : respWrap.data.bsaReport.AdditionalMonthlyDetails.MonthlyData3){
                // List<Bank_Statement_Analysis__c> childList = accountNumToChildBsas.get(accountNumber);
                // for(Bank_Statement_Analysis__c bsa : childList){
                // if(bsa.Month__c == iterAdditional.monthName){
                // bsa.Total_Self_and_Related_Party_Credit__c = iterAdditional.numberOfSelfAndRelatedPartyCreditTxns;
                // bsa.Amount_of_Self_and_Related_Party_Credit__c = iterAdditional.totalOfSelfAndRelatedPartyCreditTxns;
                // bsa.Total_Number_of_Business_Credits__c = iterAdditional.numberOfBusinessCreditTxns;
                // bsa.Total_Amount_of_Business_Credits__c = iterAdditional.totalBusinessCreditTxns;
                // bsa.Total_Self_and_Related_Party_Debit__c = iterAdditional.numberOfSelfAndRelatedPartyDebitTxns;
                // bsa.Amount_of_Self_and_Related_Party_Debit__c = iterAdditional.totalOfSelfAndRelatedPartyDebitTxns;
                // bsa.Total_Number_of_Business_Debits__c = iterAdditional.numberOfBusinessDebitTxns;
                // bsa.Total_Amount_of_Business_Debits__c = iterAdditional.totalBusinessDebitTxns;
                // bsa.Cash_Deposit_to_total_Credit__c = iterAdditional.cashDepositToTotalCreditPercent;
                // bsa.Cash_withdrwal_to_total_Debit__c = iterAdditional.cashWithdrawalToTotalDebitPercent;
                // bsa.Total_number_of_inward_return__c = iterAdditional.totalNumberOfInwardReturnsToTotalDebitPercent;
                // bsa.I_w_retruns_as_of_total_debits__c = iterAdditional.totalAmountOfInwardReturnsToTotalDebitPercent;
                // bsa.Total_number_of_outward_return__c = iterAdditional.totalNumberOfOutwardReturnsToTotalCreditPercent;
                // bsa.O_w_retruns_as_of_total_credits__c = iterAdditional.totalAmountOfOutwardReturnsToTotalCreditPercent;
                // bsa.Average_Limit_Utilisation__c = iterAdditional.averageLimitUtilization;
                // bsa.ABB__c = iterAdditional.aBBBal5Bal15Bal25Bal30;
                // bankStatementList.add(bsa);
                // }
                // }
                // }
                // }
                // if(i == 4){
                // for(BSAResponseService.cls_MonthlyData1 iterAdditional : respWrap.data.bsaReport.AdditionalMonthlyDetails.MonthlyData4){
                // List<Bank_Statement_Analysis__c> childList = accountNumToChildBsas.get(accountNumber);
                // for(Bank_Statement_Analysis__c bsa : childList){
                // if(bsa.Month__c == iterAdditional.monthName){
                // bsa.Total_Self_and_Related_Party_Credit__c = iterAdditional.numberOfSelfAndRelatedPartyCreditTxns;
                // bsa.Amount_of_Self_and_Related_Party_Credit__c = iterAdditional.totalOfSelfAndRelatedPartyCreditTxns;
                // bsa.Total_Number_of_Business_Credits__c = iterAdditional.numberOfBusinessCreditTxns;
                // bsa.Total_Amount_of_Business_Credits__c = iterAdditional.totalBusinessCreditTxns;
                // bsa.Total_Self_and_Related_Party_Debit__c = iterAdditional.numberOfSelfAndRelatedPartyDebitTxns;
                // bsa.Amount_of_Self_and_Related_Party_Debit__c = iterAdditional.totalOfSelfAndRelatedPartyDebitTxns;
                // bsa.Total_Number_of_Business_Debits__c = iterAdditional.numberOfBusinessDebitTxns;
                // bsa.Total_Amount_of_Business_Debits__c = iterAdditional.totalBusinessDebitTxns;
                // bsa.Cash_Deposit_to_total_Credit__c = iterAdditional.cashDepositToTotalCreditPercent;
                // bsa.Cash_withdrwal_to_total_Debit__c = iterAdditional.cashWithdrawalToTotalDebitPercent;
                // bsa.Total_number_of_inward_return__c = iterAdditional.totalNumberOfInwardReturnsToTotalDebitPercent;
                // bsa.I_w_retruns_as_of_total_debits__c = iterAdditional.totalAmountOfInwardReturnsToTotalDebitPercent;
                // bsa.Total_number_of_outward_return__c = iterAdditional.totalNumberOfOutwardReturnsToTotalCreditPercent;
                // bsa.O_w_retruns_as_of_total_credits__c = iterAdditional.totalAmountOfOutwardReturnsToTotalCreditPercent;
                // bsa.Average_Limit_Utilisation__c = iterAdditional.averageLimitUtilization;
                // bsa.ABB__c = iterAdditional.aBBBal5Bal15Bal25Bal30;
                // bankStatementList.add(bsa);
                // }
                // }
                // }
                // }
                // if(i == 5){
                // for(BSAResponseService.cls_MonthlyData1 iterAdditional : respWrap.data.bsaReport.AdditionalMonthlyDetails.MonthlyData5){
                // List<Bank_Statement_Analysis__c> childList = accountNumToChildBsas.get(accountNumber);
                // for(Bank_Statement_Analysis__c bsa : childList){
                // if(bsa.Month__c == iterAdditional.monthName){
                // bsa.Total_Self_and_Related_Party_Credit__c = iterAdditional.numberOfSelfAndRelatedPartyCreditTxns;
                // bsa.Amount_of_Self_and_Related_Party_Credit__c = iterAdditional.totalOfSelfAndRelatedPartyCreditTxns;
                // bsa.Total_Number_of_Business_Credits__c = iterAdditional.numberOfBusinessCreditTxns;
                // bsa.Total_Amount_of_Business_Credits__c = iterAdditional.totalBusinessCreditTxns;
                // bsa.Total_Self_and_Related_Party_Debit__c = iterAdditional.numberOfSelfAndRelatedPartyDebitTxns;
                // bsa.Amount_of_Self_and_Related_Party_Debit__c = iterAdditional.totalOfSelfAndRelatedPartyDebitTxns;
                // bsa.Total_Number_of_Business_Debits__c = iterAdditional.numberOfBusinessDebitTxns;
                // bsa.Total_Amount_of_Business_Debits__c = iterAdditional.totalBusinessDebitTxns;
                // bsa.Cash_Deposit_to_total_Credit__c = iterAdditional.cashDepositToTotalCreditPercent;
                // bsa.Cash_withdrwal_to_total_Debit__c = iterAdditional.cashWithdrawalToTotalDebitPercent;
                // bsa.Total_number_of_inward_return__c = iterAdditional.totalNumberOfInwardReturnsToTotalDebitPercent;
                // bsa.I_w_retruns_as_of_total_debits__c = iterAdditional.totalAmountOfInwardReturnsToTotalDebitPercent;
                // bsa.Total_number_of_outward_return__c = iterAdditional.totalNumberOfOutwardReturnsToTotalCreditPercent;
                // bsa.O_w_retruns_as_of_total_credits__c = iterAdditional.totalAmountOfOutwardReturnsToTotalCreditPercent;
                // bsa.Average_Limit_Utilisation__c = iterAdditional.averageLimitUtilization;
                // bsa.ABB__c = iterAdditional.aBBBal5Bal15Bal25Bal30;
                // bankStatementList.add(bsa);
                // }
                // }
                // }
                // }
                // i = i + 1;
                // }

                // List<BSA_DA_Mapping__mdt> metadataRecords = [SELECT MasterLabel, Perfios_Category__c, Salesforce_Category__c 
                //         FROM BSA_DA_Mapping__mdt];
                // for(BSAResponseService.cls_accountXns iterResp:respWrap.data.bsaReport.accountXns){
                // for(BSAResponseService.cls_xns iterXns:iterResp.xns){
                // Bank_Statement_Analysis__c bsa = new Bank_Statement_Analysis__c();
                // bsa.Narration__c = iterXns.narration;
                // bsa.Amount__c = iterXns.amount != null ?iterXns.amount : null; 
                // bsa.Balance__c = iterXns.balance!=null?iterXns.balance : null;
                // bsa.RecordTypeId = Utility.getRecordTypeIdByDeveloperName('Bank_Statement_Analysis__c','XNS');
                // bsa.Bank_Details__c = accNumToBankMap.get(iterResp.accountNo).Id;
                // bsa.Parent_Bant_Statement__c = accountToBSAMap.get(iterResp.accountNo).Id;
                // bsa.Category__c = iterXns.category;

                // if(String.isNotBlank(iterXns.dateVal)){
                // String[] dateParts = iterXns.dateVal.split('-');
                // Integer day = Integer.valueOf(dateParts[2]);
                // Integer month = Integer.valueOf(dateParts[1]);
                // Integer year = Integer.valueOf(dateParts[0]);
                // bsa.XNS_Date__c = Date.newInstance(year, month, day);
                // }


                // Boolean categoryMatched = false;

                // if (iterXns.category != null) {
                // String txnCategoryLower = iterXns.category.toLowerCase();
                // System.debug('iterXns.category-------'  + iterXns.category);

                // /* if (txnCategoryLower.startsWith('transfer to') && !txnCategoryLower.contains('transfer to self')) {

                // for (BSA_DA_Mapping__mdt metadata : metadataRecords) {
                // if ('transfer to'.equalsIgnoreCase(metadata.Perfios_Category__c)) {
                // bsa.Salesforce_Category__c = metadata.Salesforce_Category__c;
                // categoryMatched = true;
                // break;
                // }
                // }
                // }

                // else if (txnCategoryLower.startsWith('transfer from') && !txnCategoryLower.contains('transfer from self')) {

                // for (BSA_DA_Mapping__mdt metadata : metadataRecords) {
                // if ('transfer from'.equalsIgnoreCase(metadata.Perfios_Category__c)) {
                // if (txnCategoryLower.startsWith(metadata.Perfios_Category__c.toLowerCase())) {
                // bsa.Salesforce_Category__c = metadata.Salesforce_Category__c;
                // categoryMatched = true;
                // break;
                // }
                // }
                // }
                // } */

                // if (iterXns.category.startsWith('Transfer to') && !iterXns.category.contains('Transfer to self')) {
                // //bsa.Salesforce_Category__c = 'Business Debit';

                // for (BSA_DA_Mapping__mdt metadata : metadataRecords) {
                // String metadataVal =metadata.Perfios_Category__c;
                // if(metadata.Perfios_Category__c!= null  && metadataVal.contains(' ')){
                // List<String> splittedVal =metadataVal.split(' ');
                // if(splittedVal.size()>=2){
                // metadataVal=splittedVal[0]+' '+splittedVal[1];
                // }
                // else{
                //     metadataVal=splittedVal[0];
                // }
                // }
                // System.debug('metadataVal'  + metadataVal);
                // System.debug('iterXns.category-------'  + iterXns.category);
                // if (metadataVal!=null && 'Transfer to'.contains(metadataVal)) {
                // System.debug('iterXns.category-------'  + iterXns.category);
                // if (iterXns.category.startsWith(metadataVal)){
                //     System.debug('metadataVal'  + metadataVal);
                // bsa.Salesforce_Category__c = metadata.Salesforce_Category__c;
                //     System.debug('iterXns.category-------'  + iterXns.category);
                // categoryMatched = true;
                // break;
                // }                                       
                // }
                // } 
                // }

                // else if (iterXns.category.startsWith('Transfer from') && !iterXns.category.contains('Transfer from self')) {
                // for (BSA_DA_Mapping__mdt metadata : metadataRecords) {
                // String metadataVal =metadata.Perfios_Category__c;
                // if(metadata.Perfios_Category__c!= null  && metadataVal.contains(' ')){
                // List<String> splittedVal =metadataVal.split(' ');
                // if(splittedVal.size()>=2){
                // metadataVal=splittedVal[0]+' '+splittedVal[1];
                // }
                // else{
                //     metadataVal=splittedVal[0];
                // }
                // }
                // System.debug('metadataVal'  + metadataVal);
                // System.debug('iterXns.category-------'  + iterXns.category);
                // if (metadataVal!=null && 'Transfer from'.contains(metadataVal)) {
                // System.debug('iterXns.category-------'  + iterXns.category);
                // if (iterXns.category.startsWith(metadataVal)){
                //     System.debug('metadataVal'  + metadataVal);
                // bsa.Salesforce_Category__c = metadata.Salesforce_Category__c;
                //     System.debug('iterXns.category-------'  + iterXns.category);
                // categoryMatched = true;
                // break;
                // }                                       
                // }
                // } 


                // /*for (BSA_DA_Mapping__mdt metadata : metadataRecords) {
                // if ('Transfer from XYZ'.equals(metadata.Perfios_Category__c)) {

                // if (iterXns.category.startsWith(metadata.Perfios_Category__c)) {
                // bsa.Salesforce_Category__c = metadata.Salesforce_Category__c;
                // categoryMatched = true;
                //     break;
                // }
                // }
                // } */
                // }

                // else {
                // for (BSA_DA_Mapping__mdt metadata : metadataRecords) {
                // if (txnCategoryLower.equalsIgnoreCase(metadata.Perfios_Category__c != null ? metadata.Perfios_Category__c.toLowerCase() : null)) {
                // bsa.Salesforce_Category__c = metadata.Salesforce_Category__c;
                // categoryMatched = true;
                // break;
                // }
                // }
                // }
                // }



                // // if (iterXns.category != null) {

                // //     if (iterXns.category.startsWith('Transfer to') && !iterXns.category.contains('Transfer to self')) {

                // //         for (BSA_DA_Mapping__mdt metadata : metadataRecords) {
                // //             if ('Transfer to'.equals(metadata.Perfios_Category__c)) {

                // //                     bsa.Salesforce_Category__c = metadata.Salesforce_Category__c;
                // //                     categoryMatched = true;
                // //                     break;

                // //             }
                // //         }
                // //     }

                // //     else if (iterXns.category.startsWith('Transfer from') && !iterXns.category.contains('Transfer from self')) {

                // //         for (BSA_DA_Mapping__mdt metadata : metadataRecords) {
                // //             if ('Transfer from'.equals(metadata.Perfios_Category__c)) {

                // //                 if (iterXns.category.startsWith(metadata.Perfios_Category__c)) {
                // //                     bsa.Salesforce_Category__c = metadata.Salesforce_Category__c;
                // //                     categoryMatched = true;
                // //                     break;
                // //                 }
                // //             }
                // //         }
                // //     }


                // //    else{
                // //     for (BSA_DA_Mapping__mdt metadata : metadataRecords) {
                // //         if (iterXns.category.equals(metadata.Perfios_Category__c)) {
                // //             bsa.Salesforce_Category__c = metadata.Salesforce_Category__c;
                // //             categoryMatched = true;
                // //             break;
                // //         }
                // //     }
                // //     }
                // // }


                // if (!categoryMatched) {
                // bsa.Salesforce_Category__c = 'Default Category';    
                // }
                // bankStatementList.add(bsa);



                // }
                // }
                // if(bankStatementList.size()>0){
                // BSAInsertionBatch batchJob = new BSAInsertionBatch(bankStatementList);
                // Database.executeBatch(batchJob, 200);
                // }

                // Customer_Address__c newCustomerAddressPermanent = new Customer_Address__c();
                // newCustomerAddressPermanent.Customer__c = appList[0].Customer__c;
                // newCustomerAddressPermanent.Address_Type__c='BSA';
                // insert newCustomerAddressPermanent; 
                // // Extract and split the address based on commas
                // String fullAddress = respWrap.data.bsaReport.customerInfo.address;
                // List<String> addressParts = fullAddress != null ? fullAddress.split(',') : new List<String>();

                // // Assign values logically
                // if (addressParts.size() > 0) {
                // appAddress.Address_Line_1__c = addressParts[0].trim();
                // }
                // if (addressParts.size() > 1) {
                // appAddress.Address_Line_2__c = addressParts[1].trim();
                // }
                // if (addressParts.size() > 2) {
                // appAddress.Address_Line_3__c = addressParts[2].trim();
                // }
                // appAddress.Applicant__c = appList[0].Id;
                // appAddress.Address_Type__c = 'BSA';
                // insert appAddress;
                

                // }
              

            }
        }
           
        catch (Exception e) {
      
        }
    }

    public class BSAResponseWrapper {
        public Boolean status;
        public String message;
        public String statusCode;
        public String traceId;
        public String perfiosTransactionId;
    }
}