public with sharing class COMM_BankStatementAnalysisController {
    @AuraEnabled
   public static String initiateBSA(Map<String,String> inputMap){
        try{
            List<string> validatemandate = new List<string>();
            List<string> constructpayload = new List<string>();
            String resultMessage;
            String loanId = inputMap.get('recordId');
            String applicantId = inputMap.get('applicantId');
            String processName = inputMap.get('processName');
            String docIds = inputMap.get('selectedDocList');
            Boolean isScannedCopy = Boolean.valueof(inputMap.get('scannedCopy'));
            //Boolean sendToInternalApi = Boolean.valueof(inputMap.get('sendToInternalApi'));
            system.debug('line 12 error '+ loanId);
            system.debug('line 95 error '+ applicantId);
            system.debug('line 95 error '+ processName);
            system.debug('line 95 error '+ docIds);

            Bank_Details__c bankdetails = [Select Id, OwnerId, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, ABB__c, Account_Holder_Name__c, Account_Number__c, Account_Type__c, Application_Applicant__c, Bank_Master__c, Bank_Related_To__c, Beneficiary_ID__c, CC_Limit_Utilization__c, Customer__c, Debit_Card_Status__c, IFSC__c, Is_Consider_for_Eligibility__c, Is_Disbursal_Account__c, Is_Repayment_Account__c, Is_Your_Net_Banking_Status_Active__c, Month__c, OD_CC_Limit__c, Perfios_Bank_Account_Type__c, Perfios_transaction_ID__c, Project_Name__c, RecordSync__c, Source__c, Type__c, Year_Month_From__c, Year_Month_To__c, Year__c, isActive__c from Bank_Details__c where Id = 'a0BdN00000LTaK9UAL'];
            Bank_Details__c bdclone = bankdetails.clone(false, true, false, false);
            bdclone.Is_Repayment_Account__c = true;
            bdclone.Application_Applicant__c = applicantId;
            insert bdclone;

            List<Bank_Statement_Analysis__c>  bsanalysis = [Select  Id, OwnerId, IsDeleted, Name, RecordTypeId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastActivityDate, ABB__c, ADB_last_6_months__c, ADB_last_6_months_manual__c, Account_Number__c, Amount__c, Amount_of_Self_and_Related_Party_Credit__c, Amount_of_Self_and_Related_Party_Debit__c, Average_EOD_Balance__c, Average_Limit_Utilisation__c, Average_limit_utilization_6_month_manual__c, Average_limit_utilization_6_months__c, Balance__c, Bank_Details__c, Cash_Deposit_to_total_Credit__c, Cash_withdrwal_to_total_Debit__c, Category_Manual__c, Category__c, Cheque_Number__c, Count_of_loan_disbursal__c, Emi_Date__c, Full_Month_Count__c, I_w_retruns_as_of_total_debits__c, I_w_returns_as_of_total_debits_Manual__c, I_w_returns_as_of_total_debits__c, Inward_Outward_Ratio_Manual__c, Inward_Outward_Ratio__c, Loan_Application__c, Minimum_ABB_6_months_manual__c, Minimum_ABB_last_6_months__c, Minimum_Credit_Count__c, Minimum_credit_amount_6_months__c, Minimum_credit_amount_6_months_manual__c, Minimum_credit_count_6_months_manual__c, Month__c, Narration__c, Number_of_Self_and_Related_Party_Debit__c, O_w_retruns_as_of_total_credits__c, O_w_returns_as_of_total_credits__c, O_w_returns_as_of_total_credits_manual__c, Parent_Bant_Statement__c, Salesforce_Category__c, Sanction_Limit__c, Source__c, Sum_of_business_credits_6_months_manual__c, Sum_of_business_credits_last_6_months__c, Total_Amount_Balance__c, Total_Amount_of_Business_Credits__c, Total_Amount_of_Business_Debits__c, Total_Amount_of_Circular_Transactions__c, Total_Amount_of_EMI__c, Total_Amount_of_Intrest_Charged__c, Total_Cash_Deposit__c, Total_Cash_Withdrawal__c, Total_Credit__c, Total_Debit__c, Total_Number_of_Business_Credits__c, Total_Number_of_Business_Debits__c, Total_Number_of_circular_transactions__c, Total_Self_and_Related_Party_Credit__c, Total_Self_and_Related_Party_Debit__c, Total_no_of_inward_cheque_returns__c, Total_no_of_inward_cheque_returns_manual__c, Total_number_of_credits__c, Total_number_of_debits__c, Total_number_of_inward_Cheque_return__c, Total_number_of_inward_ECS_return__c, Total_number_of_inward_return__c, Total_number_of_out_bounce__c, Total_number_of_outward_return__c, Value_of_loan_disbursal__c, XNS_Date__c from Bank_Statement_Analysis__c Where Bank_Details__c = '' ];
            List<Bank_Statement_Analysis__c> clonedBsAnalysisList = new List<Bank_Statement_Analysis__c>();            
            for (Bank_Statement_Analysis__c bsa : bsanalysis) {
                Bank_Statement_Analysis__c clonedBsa = bsa.clone(false, false, false, false);
                clonedBsa.Bank_Details__c = bdClone.Id;
                clonedBsAnalysisList.add(clonedBsa);
            }
            if (!clonedBsAnalysisList.isEmpty()) {
                upsert clonedBsAnalysisList;
            }

            Map <String,COMM_SalesLoanActionsController.DocumentCheckListWrappper> applicantDocWrapper = new Map <String,COMM_SalesLoanActionsController.DocumentCheckListWrappper>();
            Map<String,API_Exceptions__mdt> allMetaData = API_Exceptions__mdt.getAll();
            List<String> contentVersionIds =(List<String>) JSON.deserialize(inputMap.get('selectedDocList'),List<String>.class);
            List<COMM_SalesLoanActionsController.DocumentCheckListWrappper> newDocumentList =(List<COMM_SalesLoanActionsController.DocumentCheckListWrappper>) JSON.deserialize(inputMap.get('newDocumentDetails'),List<COMM_SalesLoanActionsController.DocumentCheckListWrappper>.class);
            Map<String,String> versionToFileName = new Map<String,String>();
            Map<String,String> VersionToDocId = new Map<String,String>();
            Map<String, String> contentToVersionMap = new Map<String,String>();
            List<ContentVersion> cvRecVersionIdList = [Select Id,Title,ContentDocumentId from ContentVersion where Id IN :contentVersionIds ];
            for(ContentVersion cvId : cvRecVersionIdList) {
                versionToFileName.put(cvId.Id,cvId.Title);
                VersionToDocId.put(cvId.Id,cvId.ContentDocumentId);
                contentToVersionMap.put(cvId.ContentDocumentId,cvId.Id);
            }
            List<Document_Details__c> docDetailsList = [SELECT Id, Name, Loan_Application__c,Content_Document_Id__c,Year_Month_From__c,Year_month_to__c,Transaction_ID__c, BSA_id__c, Applicant__c, is_internal_bsa__c, AA_JSON_ContentId__c
                FROM Document_Details__c 
                WHERE Content_Document_Id__c IN :VersionToDocId.values()
            ];
            Map<Id, List<Document_Details__c>> appToDocMap = new Map<Id, List<Document_Details__c>>();
            Map<Id, List<String>> appToDocIdsMap = new Map<Id, List<String>>();
            for(Document_Details__c doc : docDetailsList){
                if(appToDocMap.containsKey(doc.Applicant__c)){
                    appToDocMap.get(doc.Applicant__c).add(doc);
                } else {
                    appToDocMap.put(doc.Applicant__c, new List<Document_Details__c>{doc});
                }
                if(appToDocIdsMap.containsKey(doc.Applicant__c)){
                    appToDocIdsMap.get(doc.Applicant__c).add(doc.Content_Document_Id__c);
                }
                else{
                    appToDocIdsMap.put(doc.Applicant__c, new List<String>{doc.Content_Document_Id__c});
                }
            }
            for(COMM_SalesLoanActionsController.DocumentCheckListWrappper docWrap :newDocumentList){
                applicantDocWrapper.put(docWrap.appId,docWrap);
            }
            
            
            
            Application_Applicant__c app = [Select id, Name,Gender__c,Pan_Name__c, Loan_Application__r.Product__c,PAN_Number__c,DOB__c,DOI__c ,Applicant_Name__c from Application_Applicant__c where id = :applicantId];                           
            
            String returnResp;
            Integration_Master__mdt metadata = [SELECT 
                                                    Process_Name__c,
                                                    Handler_Class__c,
                                                    Endpoint__c,
                                                    Request_Method__c,
                                                    Client_Id__c,
                                                    Client_Secret__c,
                                                    Allowed_Retry__c,
                                                    Gestation_Period__c,
                                                    Refresh_Allowed__c,
                                                    Activity_Name__c
                                                FROM Integration_Master__mdt 
                                                WHERE Activity_Name__c = :processName LIMIT 1];
            
            
            List<Integration_Details__c> intDetList = new List<Integration_Details__c>();
            List<Document_Details__c> docListToUpdate = new List<Document_Details__c>();
            List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                FROM Integration_Settings__c WHERE Name = 'Bank Statement Analysis' LIMIT 1];
            for(String appId : appToDocMap.keySet()){
                List<Document_Details__c> docList = appToDocMap.get(appId);
                List<String> contentIds = new List<String>();
                List<String> contentVersionIdList = new List<String>();
                for(Document_Details__c doc : docList){
                    if(contentToVersionMap.containsKey(doc.Content_Document_Id__c)){
                            contentVersionIdList.add(contentToVersionMap.get(doc.Content_Document_Id__c));
                    }
                }
                System.debug('At 84 '+contentVersionIdList);
                IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
                
                wrapper.recordId =appId ;
                wrapper.loanApplicationId = loanId;
                wrapper.type = processName;
                wrapper.endpoint = metadata.Endpoint__c;
                wrapper.requestMethod = metadata.Request_Method__c;
                wrapper.handlerClass = metadata.Handler_Class__c;
                wrapper.clientId = metadata.Client_Id__c;
                wrapper.clientSecret = metadata.Client_Secret__c;
                wrapper.allowedRetry = metadata.Allowed_Retry__c;
                wrapper.gestationPeriod = metadata.Gestation_Period__c;
                wrapper.activityname = metadata.Activity_Name__c;
                wrapper.refreshallowed = metadata.Refresh_Allowed__c;
                wrapper.handlername =  metadata.Handler_Class__c;
                wrapper.contentVersionIdList = contentVersionIdList;
                wrapper.scannedCopy =isScannedCopy;
                wrapper.documentDetailsResponse = applicantDocWrapper.get(appId).docListResponse[0].id;
                wrapper.documentDetailsExcel = applicantDocWrapper.get(appId).docListExcel[0].id;
                //wrapper.sendToInternalApi = sendToInternalApi;
                intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
                System.debug('respWrapper '+respWrapper);
                Integration_Details__c integrationDetail = new Integration_Details__c();

                Integration_Settings__c intSetting = intSettingList[0];                
                system.debug('line 95 error '+ respWrapper.prerequisiteError);
                if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                    integrationDetail.Status__c = String.valueof('412');
                    integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                    integrationDetail.Name =processName ;
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                    returnResp = resultMessage;
                }
                
                else{
                    Map<String,String> integrationRequestMap = new Map<String,String>();
                    integrationRequestMap.put('intSettingName','Bank Statement Analysis');
                    integrationRequestMap.put('requestJSON',respWrapper.payload);
                    System.debug('Zt 128');
                    //String bearer=Utility.getAccessToken();
                    //System.debug('bearer '+bearer);
                    //IntegrationRequestMap.put('bearer',bearer);
                    system.debug('AMAN RESPONSE');
                    HTTPResponse resp = Deloitte_BankSatamentAnalysisMockResp.getHttpBankSatamentAnalysisMockResponse(); // status = true;
                    /*if(!Test.isRunningTest()) {
                        resp = Utility.executeAPIRequest(integrationRequestMap);
                    } else {
                        HttpRequest req = new HttpRequest();
                        req.setEndpoint(System.label.GodrejUrl); // dummy
                            req.setMethod('POST');
                        resp = new Http().send(req);
                    }*/
                    System.debug('resp----'+resp.getBody());
                    System.debug('status code '+resp.getStatusCode());
                    if(resp.getStatusCode()== 200){
                        BankStatementAnalysisResponseServiceWrapper  responseJSON = (BankStatementAnalysisResponseServiceWrapper) JSON.deserialize(resp.getBody(), BankStatementAnalysisResponseServiceWrapper.class);
                        System.debug('at 136');
                        System.debug('stats'+responseJSON.status);
                        if(responseJSON.status!=true){
                            System.debug('At 138');
                            for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                                if(execeptionMeta.Error_Code__c ==responseJSON.data.files[0].Message.error.details[0].code){
                                    returnResp = 'Error:' + execeptionMeta.Error_Message__c;
                                }
                            }
                            /*System.debug('at 144');
                            System.debug('>>>>>'+ respWrapper.payload);
                            System.debug('>>>>'+resp.getBody());
                            System.debug('>>>'+intSetting.Request_Method__c);
                            System.debug('>>>'+intSetting.EndPoint__c);
                            System.debug('>>>'+appId);
                            System.debug('>>>'+loanid);*/
                            integrationDetail.Calling_Source__c = wrapper.type;
                            integrationDetail.Request_JSON__c = respWrapper.payload;
                            integrationDetail.Response_JSON__c = resp.getBody();
                            integrationDetail.Status__c =String.valueof(resp.getStatusCode());
                            integrationDetail.Method_Type__c = intSetting.Request_Method__c;
                            integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                            integrationDetail.Object_Name__c = 'Application_Applicant__c';
                            integrationDetail.Name = 'BSA ';
                            integrationDetail.Related_Record_Id__c = appId;
                            integrationDetail.Loan_Application__c = loanid;
                        }
                        else{
                            
                            integrationDetail.Calling_Source__c = wrapper.type;
                            integrationDetail.Request_JSON__c = respWrapper.payload;
                            integrationDetail.Response_JSON__c = resp.getBody();
                            integrationDetail.Status__c =String.valueof(resp.getStatusCode());
                            integrationDetail.Method_Type__c = intSetting.Request_Method__c;
                            integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                            integrationDetail.Object_Name__c = 'Application_Applicant__c';
                            integrationDetail.Name = 'BSA ';
                            integrationDetail.Related_Record_Id__c = appId;
                            integrationDetail.Loan_Application__c = loanid;
                            System.debug('At 191');
                            System.debug('responseJSON '+responseJSON);
                            System.debug('perfiosTransactionId>>'+responseJSON.perfiosTransactionId);
                            docList[0].bsa_id__c= responseJSON.perfiosTransactionId;
                            returnResp=JSON.serialize(responseJSON);
                            for(Document_Details__c doc : docList){
                                doc.bsa_id__c= responseJSON.perfiosTransactionId;
                                doc.Is_BSA_Initated__c = true;
                                docListToUpdate.add(doc);
                            }
                        }
                        intDetList.add(integrationDetail);
                        
                    }else if(resp.getStatusCode()== 202){
                        System.debug('At 202 status code');
                        BankStatementAnalysisResponseServiceWrapper  responseJSON = (BankStatementAnalysisResponseServiceWrapper) JSON.deserialize(resp.getBody(), BankStatementAnalysisResponseServiceWrapper.class);
                        
                        if(responseJSON.status!=true){
                            integrationDetail.Calling_Source__c = wrapper.type;
                            integrationDetail.Request_JSON__c = respWrapper.payload;
                            integrationDetail.Response_JSON__c = resp.getBody();
                            integrationDetail.Status__c =String.valueof(resp.getStatusCode());
                            integrationDetail.Method_Type__c = intSetting.Request_Method__c;
                            integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                            integrationDetail.Object_Name__c = 'Application_Applicant__c';
                            integrationDetail.Name = 'BSA ';
                            integrationDetail.Related_Record_Id__c = appId;
                            integrationDetail.Loan_Application__c = loanid;
                        }
                        else{
                            
                            integrationDetail.Calling_Source__c = wrapper.type;
                            integrationDetail.Request_JSON__c = respWrapper.payload;
                            integrationDetail.Response_JSON__c = resp.getBody();
                            integrationDetail.Status__c =String.valueof(resp.getStatusCode());
                            integrationDetail.Method_Type__c = intSetting.Request_Method__c;
                            integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                            integrationDetail.Object_Name__c = 'Application_Applicant__c';
                            integrationDetail.Name = 'BSA ';
                            integrationDetail.Related_Record_Id__c = appId;
                            integrationDetail.Loan_Application__c = loanid;
                            
                            docList[0].bsa_id__c= responseJSON.perfiosTransactionId;
                            returnResp=JSON.serialize(responseJSON);
                            for(Document_Details__c doc : docList){
                                doc.bsa_id__c= responseJSON.perfiosTransactionId;
                                doc.Is_BSA_Initated__c = true;
                                doc.Loan_Application__c= loanId;
                                docListToUpdate.add(doc);
                            }
                        }
                        intDetList.add(integrationDetail);
                        
                    }
                    else{
                       /* System.debug('At 217');
                        integrationDetail.Calling_Source__c = wrapper.type;
                        integrationDetail.Request_JSON__c = respWrapper.payload;
                        integrationDetail.Response_JSON__c = JSON.serialize(resp.getBody());
                        integrationDetail.Status__c =String.valueof(resp.getStatusCode());
                        integrationDetail.Method_Type__c = intSetting.Request_Method__c;
                        integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                        integrationDetail.Object_Name__c = 'Application_Applicant__c';
                        integrationDetail.Name = 'BSA Error';
                        integrationDetail.Related_Record_Id__c = appId;
                        integrationDetail.Loan_Application__c = loanid;
                        
                        returnResp = 'Error:' + 'We are currently unable to analyse bank statements you have uploaded.';
                        intDetList.add(integrationDetail);*/
                        BankStatementAnalysisResponseServiceWrapper  responseJSON = (BankStatementAnalysisResponseServiceWrapper) JSON.deserialize(resp.getBody(), BankStatementAnalysisResponseServiceWrapper.class);
                        if(responseJSON.status  == false ){
                            if(resp.getBody().contains('details')){
                                if(responseJSON.data.error.details != null && !responseJSON.data.error.details.isEmpty()){
                                    List<Perfios_Errors__c> matchedErrors = [
                                            SELECT Perfios_Error__c 
                                            FROM Perfios_Errors__c 
                                            WHERE Perfios_Error__c = :responseJSON.data.error.details[0].message
                                        LIMIT 1
                                        ];
                                    
                                    if (!matchedErrors.isEmpty()) {
                                        Opportunity opp = [SELECT Id, Login_Completion_Stage__c FROM Opportunity WHERE Id = :loanId LIMIT 1];
                                        
                                        if (opp.Login_Completion_Stage__c == null || !opp.Login_Completion_Stage__c.containsIgnoreCase('Income eligibility')) {
                                            returnResp = 'Perfios Error: ' + matchedErrors[0].Perfios_Error__c;
                                            return returnResp;
                                        }
                                    }
                                    else{
                                        returnResp = 'Error:' + 'We are currently unable to analyse bank statements you have uploaded.'+' '+responseJSON.data.error.details[0].message;
                                    }
                                    
                                    
                                }
                                
                                else{
                                    for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                                        if(execeptionMeta.Error_Code__c ==String.valueof(resp.getStatusCode())){
                                            returnResp = 'Error:' + execeptionMeta.Error_Message__c;
                                        }
                                        else{
                                            if(execeptionMeta.Error_Code__c =='BSA Error'){
                                                returnResp = 'Error:' + execeptionMeta.Error_Message__c;
                                            }
                                            
                                        }
                                    }
                                }
                            }
                            else{
                                if(responseJSON.data.error.message != null && responseJSON.data.error.message != ''){
                                    List<Perfios_Errors__c> matchedErrors = [
                                            SELECT Perfios_Error__c 
                                            FROM Perfios_Errors__c 
                                            WHERE Perfios_Error__c = :responseJSON.data.error.message
                                            LIMIT 1
                                        ];
                                    
                                    if (!matchedErrors.isEmpty()) {
                                        Opportunity opp = [SELECT Id, Login_Completion_Stage__c FROM Opportunity WHERE Id = :loanId LIMIT 1];
                                        
                                        if (opp.Login_Completion_Stage__c == null || !opp.Login_Completion_Stage__c.containsIgnoreCase('Income eligibility')) {
                                            returnResp = 'Perfios Error: ' + matchedErrors[0].Perfios_Error__c;
                                            return returnResp;
                                        }
                                    }
                                    else{
                                        returnResp = 'Error:' + 'We are currently unable to analyse bank statements you have uploaded.'+' '+responseJSON.data.error.message;
                                    }
                                    
                                }
                                else{
                                    for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                                        if(execeptionMeta.Error_Code__c ==String.valueof(resp.getStatusCode())){
                                            returnResp = 'Error:' + execeptionMeta.Error_Message__c;
                                        }
                                        else{
                                            if(execeptionMeta.Error_Code__c =='BSA Error'){
                                                returnResp = 'Error:' + execeptionMeta.Error_Message__c;
                                            }
                                            
                                        }
                                    }
                                }
                            }
                            // returnResp = 'Error:' + 'We are currently unable to analyse bank statements you have uploaded.'+' '+responseJSON.data.error.details[0].message;
                        }
                        
                        // for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                            //     if(execeptionMeta.Error_Code__c ==String.valueof(resp.getStatusCode())){
                                //         returnResp = 'Error:' + execeptionMeta.Error_Message__c;
                            //      }
                            //      else{
                                //         if(execeptionMeta.Error_Code__c =='BSA Error'){
                                    //             returnResp = 'Error:' + execeptionMeta.Error_Message__c;
                                //         }
                                
                            //      }
                        // }
                    }   
                }
            }
            
            update docListToUpdate;
            insert intDetList;
            return returnResp;
            
            
            
        }
        catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage() + e.getlinenumber());
        }
    }
    
    @AuraEnabled
    public static Boolean isInitiatedBSA(String recordId) {
        List<Document_Details__c> lstDoc = [SELECT id,name,Content_Document_Id__c from Document_Details__c where 
                                            Loan_Application__c =: recordId and Content_Document_Id__c !=null and 
                                            name = '12 months bank statement'];
        if(lstDoc.size() > 0) {
            return true;
        }
        return false;
    }
    
    public class BankStatementAnalysisResponseServiceWrapper{
        public boolean status;
        public cls_data data;
        public String message;	//Transaction Cancel
        public String statusCode;	//bsa-200
        public String traceId;	//3ec94af3-81bf-4b41-9074-c0d2dd5c11ed
        public String perfiosTransactionId;	//L2PA1739172727009
    }
    public class cls_data {
        public String perfiosTransactionId;	//L2PA1739172727009
        public cls_files[] files;
        public String canceltransactionResult;	//successfully cancel transaction
        public cls_error error;
    }
    public class cls_files {
        public String filename;	//Financial-Examples-for-I20.pdf
        public String fileID;	//cc40d8afe6e60f7dd5187106f124aad0377bd9a4
        public String StatusCode;	//bsa-400
        public cls_Message Message;
    }
    public class cls_Message {
        public cls_error error;
        public String message;
    }
    public class cls_error {
        public String code;	//CannotProcessFile
        public String message;	//We could not process the statement file uploaded by the Client
        public cls_details[] details;
    }
    public class cls_details {
        public String code;	//E_STATEMENT_WRONG_FORMAT
        public String field;
        public String message;	//This statement contains images. Please upload again and select scanned images option.
        public cls_value value;
    }
    public class cls_value {
    }
    
    
    
}