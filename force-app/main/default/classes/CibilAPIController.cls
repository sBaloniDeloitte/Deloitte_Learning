/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-20-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class CibilAPIController {
    static string conLabels = 'CIBIL_API';
                         
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
    /*@AuraEnabled
    public static String initiateAPIRequest(Map<String,String> inputMap){
        try {
			Integration_Details__c integrationDetails = new Integration_Details__c();
			String loanId = inputMap.get('loanId');
            String applicantId = inputMap.get('applicantId');
			String processName = inputMap.get('processName');
            String returnResp;
            String resultMessage;
            List<Application_Applicant__c> applicantList = new List<Application_Applicant__c>();
            applicantList = [Select Id,Applicant_Name__c,Cibil_Score__c,DOB__c,DOI__c,Email__c,Company__c,Loan_Application__c,PAN_Number__c,Customer_Type__c FROM Application_Applicant__c WHERE Id =: applicantId];
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
            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper(); 
            wrapper.recordId =applicantId ;
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
            
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
            FROM Integration_Settings__c WHERE Name = 'Loan Applicant CIBIL' LIMIT 1];
            Integration_Settings__c intSetting = intSettingList[0];
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name =processName ;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.Loan_Application__c = loanId;
                integrationDetail.Related_Record_Id__c = applicantId;
                integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                System.debug('resultMessage: '+resultMessage);
                returnResp = 'PreReqError:'+resultMessage;
                // returnResp = ;
            }
            else {
                Utility_V1.ProductWrapper prodWrapper = Utility_V1.getProductDetails(new Map<String,String>{'oppId' => loanId});
                Map<String, String> integrationRequestMap = new Map<String, String>();
                integrationRequestMap.put('intSettingName', 'Loan Applicant CIBIL');
                integrationRequestMap.put('requestJSON', respWrapper.payload);           
                String bearer = Utility.getAccessToken();
                System.debug('bearer----' + bearer);
                integrationRequestMap.put('bearer', bearer);
                System.debug('integrationRequestMap ' + integrationRequestMap);
                // Hardcoded JSON Response
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                System.debug('83 resp: '+resp);
				System.debug('ckycResp resp getStatusCode '+resp.getStatusCode());
                String jsonResponse = resp.getBody();
                System.debug('API Response: ' + jsonResponse);
                // Deserialize the hardcoded JSON
                System.debug('ckycResp resp getStatusCode '+resp.getStatusCode());
                if(resp.getStatusCode() == 200){
                CIBILResponseWrapper cibilResp = (CIBILResponseWrapper) JSON.deserialize(resp.getBody(), CIBILResponseWrapper.class);
                System.debug('cibilResp: ' + cibilResp);
                System.debug('cibilpdfdocumentbase64 '+cibilResp.cibilpdfdocumentbase64);
                if (cibilResp.cibilpdfdocumentbase64 != null) {
                    // Blob contentBlob = EncodingUtil.base64Decode(cibilResp.cibilpdfdocumentbase64);
                   // Check if contentBlob is null
                    // ContentVersion cv = new ContentVersion();
                    // cv.Title = 'CIBIL_' + cibilResp.cibildocumentid;
                    // cv.PathOnClient = 'CIBIL_' + cibilResp.cibildocumentid + '.pdf';
                    // cv.VersionData = contentBlob;
                    // cv.IsMajorVersion = true;
                    // insert cv;
                    ContentVersion cd = [SELECT Id,ContentDocumentId FROM ContentVersion WHERE Id = :cibilResp.cibilpdfdocumentbase64 LIMIT 1];
                    Document_Master__c dm = new Document_Master__c();
                    dm = [Select Id,name from Document_Master__c where name = 'CIBIL' AND Is_Active__c = true LIMIT 1];
                    if(dm == null){
                    dm = [Select Id,name from Document_Master__c where name = 'Other' AND Is_Active__c = true LIMIT 1];
                    }
                    Document_Details__c cibilDoc = new Document_Details__c();
                    cibilDoc.Name = 'CIBIL';
                    cibilDoc.Content_Document_Id__c = cd.ContentDocumentId;
                    cibilDoc.Loan_Application__c = loanId;
                    cibilDoc.Applicant__c = applicantList[0].Id;
                    cibilDoc.Remarks__c = 'This document is created at draft stage when we capture the CIBIL score.';
                    cibilDoc.Document_Master__c = dm.Id;
                    cibilDoc.Status__c = 'Uploaded';
                    cibilDoc.Consider_for_Loan_Application__c = true;
                    insert cibilDoc;
                    if(prodWrapper.isHLRelated){
                        List<Document_Details__c> docList = [SELECT Id, Consider_for_Loan_Application__c FROM Document_Details__c WHERE Loan_Application__c= :loanId AND Applicant__c = :applicantList[0].Id AND Name = 'CIBIL' AND Id != :cibilDoc.id];
                        if(docList.size()>0){
                            for(Document_Details__c doc: docList){
                                doc.Consider_for_Loan_Application__c = false;
                            }
                            update docList;
                        }
                    }
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.LinkedEntityId = cibilDoc.id;
                    cdl.ContentDocumentId = cd.ContentDocumentId;
                    cdl.ShareType = 'V';
                    cdl.Visibility = 'AllUsers';
                    insert cdl;
                }
                    system.debug('tuffResponse' + cibilResp.tuffResponse);
                if(cibilResp.tuffResponse!=null){
                    String xmlResponse = cibilResp.tuffResponse;
                    Integer startIndex = xmlResponse.indexOf('<CreditReport>');
                    Integer endIndex = xmlResponse.indexOf('</CreditReport>');
                    endIndex = endIndex + ('</CreditReport>'.length());
                    xmlResponse = xmlResponse.substring(startIndex,endIndex);
                    System.debug('xmlResponse '+xmlResponse);
                    Integer count = HL_EligibilityApiController.countTagOccurrences(xmlResponse,'Account');
                    System.debug('count'+count);
                    if(count <= 1) {
                    System.debug('count'+count);
                    xmlResponse = xmlResponse.replaceALL('Account','SingleAccount');
                    }
                    // xmlResponse = xmlResponse.replaceAll('\\\\', '/');
                    // xmlResponse = xmlResponse.replaceALL('&','');
                    // Initialize variables
                    Integer stringLength = xmlResponse.length();
                    Integer chunkSize = 20000;  // Define the chunk size
                    List<String> result = new List<String>();  // List to store processed chunks
                    // Loop to process the XML response in chunks
                    for (Integer i = 0; i < stringLength; i += chunkSize) {
                        // Get the substring for the current chunk, ensuring you don't exceed the string length
                        String chunk = xmlResponse.substring(i, Math.min(i + chunkSize, stringLength));
                        // Perform the replacement of '&' with an empty string in the current chunk
                        chunk = chunk.replace('&', '');  // Replace all occurrences of '&'
                        chunk = chunk.replace('\\', '/');  // Replace all occurrences of '&'
                        // Add the cleaned chunk to the result list
                        result.add(chunk);
                    }
                    // Join all processed chunks back into a single string
                    xmlResponse = String.join(result, '');
                    String JSONRes = XmlToJSONParser.XMLToJSON(xmlResponse);
                    System.debug('JSONRes ' + JSONRes);
                    CibilAPIController objRecords = (CibilAPIController)JSON.deserialize(JSONRes, CibilAPIController.class);
                    System.debug('objRecords '+objRecords);
                    storeCibilResponseAsFile(JSON.serialize(cibilResp), applicantList[0].id,loanId);
                    Id obligationRecordTypeId = Schema.SObjectType.Income_Expense_Obligation__c.getRecordTypeInfosByName().get('Income Expense & Obligation').getRecordTypeId();
                    List<Income_Expense_Obligation__c> parent = [SELECT id from Income_Expense_Obligation__c where Loan_Application__c =:loanId AND Type__c='Obligation' AND IsParent__c = true];
                    if(parent.size() > 0) {
            
                    }else {
                        Income_Expense_Obligation__c parentObj = new Income_Expense_Obligation__c();
                        parentObj.IsParent__c = true;
                        parentObj.Loan_Application__c = loanId;
                        parentObj.Type__c = 'Obligation';
                        parentObj.RecordTypeId = obligationRecordTypeId; 
                        insert parentObj;

                    }
                    List<Income_Expense_Obligation__c> bureauLstToInsert = new List<Income_Expense_Obligation__c>();
                    List<Income_Expense_Obligation__c> lstToBeRemoved = [SELECT id FROM Income_Expense_Obligation__c WHERE Loan_Application__c =:applicantList[0].Loan_Application__c AND Application_Applicant__c=:applicantList[0].id AND RecordTypeId=:obligationRecordTypeId AND Bureau_Type__c = 'CIBIL'];

                    if(objRecords.CreditReport.Account != null ) {
                        // Integer se = checkSize(objRecords.CreditReport.Account);
                        // System.debug('se : '+se);
                        // if(se!=-1){
                        for(CibilAPIController.ClsAccount iterAccount : objRecords.CreditReport.Account) {
                            Income_Expense_Obligation__c iterObl = new Income_Expense_Obligation__c();
                            iterObl.RecordTypeId = obligationRecordTypeId;
                            iterObl.Bureau_Type__c = 'CIBIL';
                            iterObl.Application_Applicant__c = applicantList[0].id;
                            iterObl.Loan_Application__c = applicantList[0].Loan_Application__c;
                            System.debug('Account Tpyr '+iterAccount.Account_NonSummary_Segment_Fields.AccountType);
                            Account_Type_Mapping__mdt metaDataRec = Account_Type_Mapping__mdt.getInstance('X'+iterAccount.Account_NonSummary_Segment_Fields.AccountType);
                            if(metaDataRec != null) {
                            iterObl.Account_Type__c = metaDataRec.Account_Type__c;
                            if(metaDataRec.CC_NON_CC__c == 'NON CC') {
                                iterObl.Loan_Amount__c = iterAccount.Account_NonSummary_Segment_Fields.HighCreditOrSanctionedAmount != null ? Double.valueOf(iterAccount.Account_NonSummary_Segment_Fields.HighCreditOrSanctionedAmount):0;
                            }else if(metaDataRec.CC_NON_CC__c == 'CC') {
                                iterObl.Loan_Amount__c = iterAccount.Account_NonSummary_Segment_Fields.HighCreditOrSanctionedAmount != null ? Double.valueOf(iterAccount.Account_NonSummary_Segment_Fields.HighCreditOrSanctionedAmount):0;
                                //credit limit tag is missing
                            }else {
                                iterObl.Loan_Amount__c = 0;
                            }
                                iterObl.Secured_Unsecured__c = metaDataRec.Secured_Unsecured__c;
                            }else {
                                iterObl.Loan_Amount__c = 0;
                                
                            }
                            
                            iterObl.Current_Balance__c = iterAccount.Account_NonSummary_Segment_Fields.CurrentBalance!=null?Double.valueOf(iterAccount.Account_NonSummary_Segment_Fields.CurrentBalance):0;
                            iterObl.Overdue__c = iterAccount.Account_NonSummary_Segment_Fields.AmountOverdue != null ? Double.valueOf(iterAccount.Account_NonSummary_Segment_Fields.AmountOverdue):0;
                            //Amoount Overdue tag is missing
                            iterObl.Imputed_EMI__c = iterAccount.Account_NonSummary_Segment_Fields.EmiAmount!=null ? Double.valueOf(iterAccount.Account_NonSummary_Segment_Fields.EmiAmount):0;
                            if(iterAccount.Account_NonSummary_Segment_Fields.OwenershipIndicator == '1') {
                                iterObl.Ownership__c = 'Individual';
                            }else if(iterAccount.Account_NonSummary_Segment_Fields.OwenershipIndicator == '2') {
                                iterObl.Ownership__c = 'Authorised User';
                            }else if(iterAccount.Account_NonSummary_Segment_Fields.OwenershipIndicator == '3') {
                                iterObl.Ownership__c = 'Guarantor';
                            }else if(iterAccount.Account_NonSummary_Segment_Fields.OwenershipIndicator == '4') {
                                iterObl.Ownership__c = 'Joint';
                            }
                            String dateStr = String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.DateOpenedOrDisbursed)?iterAccount.Account_NonSummary_Segment_Fields.DateOpenedOrDisbursed:'';
                            if(dateStr.length() == 8){
                                String day = dateStr.substring(0,2);
                                String mon = dateStr.substring(2,4);
                                String year = dateStr.substring(4,8);
                                dateStr = year+'-'+mon+'-'+day;
                                iterObl.Start_Date__c = Date.valueOf(dateStr);
                            }
                            String dateLastStr = String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.DateOfLastPayment)?iterAccount.Account_NonSummary_Segment_Fields.DateOfLastPayment:'';
                            if(dateLastStr.length() == 8){
                                String day = dateLastStr.substring(0,2);
                                String mon = dateLastStr.substring(2,4);
                                String year = dateLastStr.substring(4,8);
                                dateLastStr = year+'-'+mon+'-'+day;
                                iterObl.Last_Payment_Date__c = Date.valueOf(dateLastStr);
                            }
                            String dateClosStr = String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.DateClosed)?iterAccount.Account_NonSummary_Segment_Fields.DateClosed:'';
                            if(String.isNotBlank(dateClosStr)) {
                                iterObl.Type__c = 'Closed Loan';
                            }else {
                                iterObl.Type__c = 'Live Loan';
                            }
                            if(dateClosStr.length() == 8){
                                String day = dateClosStr.substring(0,2);
                                String mon = dateClosStr.substring(2,4);
                                String year = dateClosStr.substring(4,8);
                                dateClosStr = year+'-'+mon+'-'+day;
                                iterObl.Closed_Date__c = Date.valueOf(dateClosStr);
                            }
                            String datePaymentStartStr = String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.PaymentHistoryStartDate)?iterAccount.Account_NonSummary_Segment_Fields.PaymentHistoryStartDate:'';
                            if(datePaymentStartStr.length() == 8){
                                String day = datePaymentStartStr.substring(0,2);
                                String mon = datePaymentStartStr.substring(2,4);
                                String year = datePaymentStartStr.substring(4,8);
                                datePaymentStartStr = year+'-'+mon+'-'+day;
                            }
                            String datePaymentEndStr = String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.PaymentHistoryEndDate)?iterAccount.Account_NonSummary_Segment_Fields.PaymentHistoryEndDate:'';
                            if(datePaymentEndStr.length() == 8){
                                String day = datePaymentEndStr.substring(0,2);
                                String mon = datePaymentEndStr.substring(2,4);
                                String year = datePaymentEndStr.substring(4,8);
                                datePaymentEndStr = year+'-'+mon+'-'+day;
                            }
                            String dpdStr = '';
                            Boolean dpdTradeline = false;
                            String dpdReason='';
                            List<String> dpdList= new List<String>{'000', 'XXX', 'STD'};
                            if(String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.PaymentHistory1)) {
                                String paymentStr= iterAccount.Account_NonSummary_Segment_Fields.PaymentHistory1;
                                for (Integer i = 0; i < paymentStr.length(); i += 3) {
                                    Integer last = Math.min(i + 3, paymentStr.length());
                                    dpdStr += paymentStr.substring(i, last) + ' ';
                                    if(!dpdList.contains(paymentStr.substring(i, last))){
                                        dpdTradeline = true;
                                    }
                                }
                                // dpdStr = iterAccount.Account_NonSummary_Segment_Fields.PaymentHistory1;
                            }
                            if(String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.PaymentHistory2)) {
                                String paymentStr= iterAccount.Account_NonSummary_Segment_Fields.PaymentHistory2;
                                for (Integer i = 0; i < paymentStr.length(); i += 3) {
                                    Integer last = Math.min(i + 3, paymentStr.length());
                                    dpdStr += paymentStr.substring(i, last) + ' ';
                                    if(!dpdList.contains(paymentStr.substring(i, last))){
                                        dpdTradeline = true;
                                    }
                                }
                                dpdStr = dpdStr.trim();
                                // dpdStr = dpdStr + iterAccount.Account_NonSummary_Segment_Fields.PaymentHistory2;
                            }
                            iterObl.DPD__c = datePaymentStartStr+' '+dpdStr+' '+datePaymentEndStr;
                            if(dpdTradeline){
                                iterObl.DPD_in_Tradeline__c = 'Yes';
                            }else{
                                if(String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.SuitFiledOrWilfulDefault) && iterAccount.Account_NonSummary_Segment_Fields.SuitFiledOrWilfulDefault != '00'){
                                    iterObl.DPD_in_Tradeline__c = 'Yes';
                                    if(dpdReason!= null && dpdReason!= ''){
                                        dpdReason = dpdReason + ', Suit Filed Or Wilful Default - '+iterAccount.Account_NonSummary_Segment_Fields.SuitFiledOrWilfulDefault;
                                    }else{
                                        dpdReason = 'Suit Filed Or Wilful Default - '+iterAccount.Account_NonSummary_Segment_Fields.SuitFiledOrWilfulDefault;
                                    }
                                }
                                else if(String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.WrittenOffAmountTotal )){
                                    iterObl.DPD_in_Tradeline__c = 'Yes';
                                    if(dpdReason!= null && dpdReason!= ''){
                                        dpdReason =dpdReason +  ', Written Off Total Amount - '+iterAccount.Account_NonSummary_Segment_Fields.WrittenOffAmountTotal;
                                    }else {
                                        dpdReason = 'Written Off Total Amount - '+iterAccount.Account_NonSummary_Segment_Fields.WrittenOffAmountTotal;   
                                    }                                    
                                }else if(String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.WrittenOffAmountPrincipal )){
                                    iterObl.DPD_in_Tradeline__c = 'Yes';
                                    if(dpdReason!= null && dpdReason!= ''){
                                        dpdReason = dpdReason + ', Written Off Principal Amount - '+iterAccount.Account_NonSummary_Segment_Fields.WrittenOffAmountPrincipal;
                                    }else {
                                        dpdReason = 'Written Off Principal Amount - '+iterAccount.Account_NonSummary_Segment_Fields.WrittenOffAmountPrincipal;
                                    }                                    
                                }else if(String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.SettlementAmount )){
                                    iterObl.DPD_in_Tradeline__c = 'Yes';
                                    if(dpdReason!= null && dpdReason!= ''){
                                        dpdReason = dpdReason + ', Settlement Amount - '+iterAccount.Account_NonSummary_Segment_Fields.SettlementAmount;
                                    }else {
                                        dpdReason = 'Settlement Amount - '+iterAccount.Account_NonSummary_Segment_Fields.SettlementAmount;
                                    }                                    
                                }else{
                                    iterObl.DPD_in_Tradeline__c = 'No';
                                }
                            }
                            iterObl.DPD_Reason__c = dpdReason;
                            
                            String datereportedStr = String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.DateReportedAndCertified)?iterAccount.Account_NonSummary_Segment_Fields.DateReportedAndCertified:'';
                            if(datereportedStr.length() == 8){
                                String day = datereportedStr.substring(0,2);
                                String mon = datereportedStr.substring(2,4);
                                String year = datereportedStr.substring(4,8);
                                datereportedStr = year+'-'+mon+'-'+day;
                               iterObl.Reported_Date__c = safeDateParse(datereportedStr);
                            }
                            if(iterObl.Type__c == 'Live Loan') {
                                Income_Expense_Obligation__c iterObl1 = iterObl.clone(false,true,false,false);
                                iterObl1.Type__c = 'Obligation';
                                iterObl1.Is_Considered_Obligation__c = true;
                                bureauLstToInsert.add(iterObl1);
                            }
                            
                            bureauLstToInsert.add(iterObl);
                        }
                    }
                    else if(objRecords.CreditReport.SingleAccount != null){
                        CibilAPIController.ClsSingleAccount iterAccount = objRecords.CreditReport.SingleAccount;
                            Income_Expense_Obligation__c iterObl = new Income_Expense_Obligation__c();
                            iterObl.RecordTypeId = obligationRecordTypeId;
                            iterObl.Bureau_Type__c = 'CIBIL';
                            iterObl.Application_Applicant__c = applicantList[0].id;
                            iterObl.Loan_Application__c = applicantList[0].Loan_Application__c;
                            System.debug('Account Tpyr '+iterAccount.SingleAccount_NonSummary_Segment_Fields.SingleAccountType);
                            Account_Type_Mapping__mdt metaDataRec = Account_Type_Mapping__mdt.getInstance('X'+iterAccount.SingleAccount_NonSummary_Segment_Fields.SingleAccountType);
                            if(metaDataRec != null) {
                            iterObl.Account_Type__c = metaDataRec.Account_Type__c;
                            if(metaDataRec.CC_NON_CC__c == 'NON CC') {
                                    iterObl.Loan_Amount__c = iterAccount.SingleAccount_NonSummary_Segment_Fields.HighCreditOrSanctionedAmount != null ? Double.valueOf(iterAccount.SingleAccount_NonSummary_Segment_Fields.HighCreditOrSanctionedAmount):0;
                            }else if(metaDataRec.CC_NON_CC__c == 'CC') {
                                    iterObl.Loan_Amount__c = iterAccount.SingleAccount_NonSummary_Segment_Fields.HighCreditOrSanctionedAmount != null ? Double.valueOf(iterAccount.SingleAccount_NonSummary_Segment_Fields.HighCreditOrSanctionedAmount):0;
                                //credit limit tag is missing
                            }else {
                                iterObl.Loan_Amount__c = 0;
                            }
                                iterObl.Secured_Unsecured__c = metaDataRec.Secured_Unsecured__c;
                            }else {
                                iterObl.Loan_Amount__c = 0;
                            }
                            
                            iterObl.Current_Balance__c = iterAccount.SingleAccount_NonSummary_Segment_Fields.CurrentBalance!=null?Double.valueOf(iterAccount.SingleAccount_NonSummary_Segment_Fields.CurrentBalance):0;
                            iterObl.Overdue__c = iterAccount.SingleAccount_NonSummary_Segment_Fields.AmountOverdue != null ? Double.valueOf(iterAccount.SingleAccount_NonSummary_Segment_Fields.AmountOverdue):0;
                            //Amoount Overdue tag is missing
                            iterObl.Imputed_EMI__c = iterAccount.SingleAccount_NonSummary_Segment_Fields.EmiAmount!=null ? Double.valueOf(iterAccount.SingleAccount_NonSummary_Segment_Fields.EmiAmount):0;
                            if(iterAccount.SingleAccount_NonSummary_Segment_Fields.OwenershipIndicator == '1') {
                                iterObl.Ownership__c = 'Individual';
                            }else if(iterAccount.SingleAccount_NonSummary_Segment_Fields.OwenershipIndicator == '2') {
                                iterObl.Ownership__c = 'Authorised User';
                            }else if(iterAccount.SingleAccount_NonSummary_Segment_Fields.OwenershipIndicator == '3') {
                                iterObl.Ownership__c = 'Guarantor';
                            }else if(iterAccount.SingleAccount_NonSummary_Segment_Fields.OwenershipIndicator == '4') {
                                iterObl.Ownership__c = 'Joint';
                            }
                            String dateStr = String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.DateOpenedOrDisbursed)?iterAccount.SingleAccount_NonSummary_Segment_Fields.DateOpenedOrDisbursed:'';
                            if(dateStr.length() == 8){
                                String day = dateStr.substring(0,2);
                                String mon = dateStr.substring(2,4);
                                String year = dateStr.substring(4,8);
                                dateStr = year+'-'+mon+'-'+day;
                                iterObl.Start_Date__c = Date.valueOf(dateStr);
                            }
                            String dateLastStr = String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.DateOfLastPayment)?iterAccount.SingleAccount_NonSummary_Segment_Fields.DateOfLastPayment:'';
                            if(dateLastStr.length() == 8){
                                String day = dateLastStr.substring(0,2);
                                String mon = dateLastStr.substring(2,4);
                                String year = dateLastStr.substring(4,8);
                                dateLastStr = year+'-'+mon+'-'+day;
                                iterObl.Last_Payment_Date__c = Date.valueOf(dateLastStr);
                            }
                            String dateClosStr = String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.DateClosed)?iterAccount.SingleAccount_NonSummary_Segment_Fields.DateClosed:'';
                            if(String.isNotBlank(dateClosStr)) {
                                iterObl.Type__c = 'Closed Loan';
                            }else {
                                iterObl.Type__c = 'Live Loan';
                            }
                            if(dateClosStr.length() == 8){
                                String day = dateClosStr.substring(0,2);
                                String mon = dateClosStr.substring(2,4);
                                String year = dateClosStr.substring(4,8);
                                dateClosStr = year+'-'+mon+'-'+day;
                                iterObl.Closed_Date__c = Date.valueOf(dateClosStr);
                            }
                            String datePaymentStartStr = String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.PaymentHistoryStartDate)?iterAccount.SingleAccount_NonSummary_Segment_Fields.PaymentHistoryStartDate:'';
                            if(datePaymentStartStr.length() == 8){
                                String day = datePaymentStartStr.substring(0,2);
                                String mon = datePaymentStartStr.substring(2,4);
                                String year = datePaymentStartStr.substring(4,8);
                                datePaymentStartStr = year+'-'+mon+'-'+day;
                            }
                            String datePaymentEndStr = String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.PaymentHistoryEndDate)?iterAccount.SingleAccount_NonSummary_Segment_Fields.PaymentHistoryEndDate:'';
                            if(datePaymentEndStr.length() == 8){
                                String day = datePaymentEndStr.substring(0,2);
                                String mon = datePaymentEndStr.substring(2,4);
                                String year = datePaymentEndStr.substring(4,8);
                                datePaymentEndStr = year+'-'+mon+'-'+day;
                            }
                            String dpdStr = '';
                            Boolean dpdTradeline = false;
                            String dpdReason='';
                            List<String> dpdList= new List<String>{'000', 'XXX', 'STD'};
                            if(String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.PaymentHistory1)) {
                                String paymentStr= iterAccount.SingleAccount_NonSummary_Segment_Fields.PaymentHistory1;
                                for (Integer i = 0; i < paymentStr.length(); i += 3) {
                                    Integer last = Math.min(i + 3, paymentStr.length());
                                    dpdStr += paymentStr.substring(i, last) + ' ';
                                    if(!dpdList.contains(paymentStr.substring(i, last))){
                                        dpdTradeline = true;
                                    }
                                }
                                // dpdStr = iterAccount.Account_NonSummary_Segment_Fields.PaymentHistory1;
                            }
                            if(String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.PaymentHistory2)) {
                                String paymentStr= iterAccount.SingleAccount_NonSummary_Segment_Fields.PaymentHistory2;
                                for (Integer i = 0; i < paymentStr.length(); i += 3) {
                                    Integer last = Math.min(i + 3, paymentStr.length());
                                    dpdStr += paymentStr.substring(i, last) + ' ';
                                    if(!dpdList.contains(paymentStr.substring(i, last))){
                                        dpdTradeline = true;
                                    }
                                }
                                dpdStr = dpdStr.trim();
                                // dpdStr = dpdStr + iterAccount.Account_NonSummary_Segment_Fields.PaymentHistory2;
                            }
                            iterObl.DPD__c = datePaymentStartStr+' '+dpdStr+' '+datePaymentEndStr;
                            if(dpdTradeline){
                                iterObl.DPD_in_Tradeline__c = 'Yes';
                            }else{
                                if(String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.SuitFiledOrWilfulDefault) && iterAccount.SingleAccount_NonSummary_Segment_Fields.SuitFiledOrWilfulDefault != '00'){
                                    iterObl.DPD_in_Tradeline__c = 'Yes';
                                    if(dpdReason!= null && dpdReason!= ''){
                                        dpdReason = dpdReason + ', Suit Filed Or Wilful Default - '+iterAccount.SingleAccount_NonSummary_Segment_Fields.SuitFiledOrWilfulDefault;
                                    }else{
                                        dpdReason = 'Suit Filed Or Wilful Default - '+iterAccount.SingleAccount_NonSummary_Segment_Fields.SuitFiledOrWilfulDefault;
                                    }
                                }
                                else if(String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.WrittenOffAmountTotal )){
                                    iterObl.DPD_in_Tradeline__c = 'Yes';
                                    if(dpdReason!= null && dpdReason!= ''){
                                        dpdReason =dpdReason +  ', Written Off Total Amount - '+iterAccount.SingleAccount_NonSummary_Segment_Fields.WrittenOffAmountTotal;
                                    }else {
                                        dpdReason = 'Written Off Total Amount - '+iterAccount.SingleAccount_NonSummary_Segment_Fields.WrittenOffAmountTotal;   
                                    }                                    
                                }else if(String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.WrittenOffAmountPrincipal )){
                                    iterObl.DPD_in_Tradeline__c = 'Yes';
                                    if(dpdReason!= null && dpdReason!= ''){
                                        dpdReason = dpdReason + ', Written Off Principal Amount - '+iterAccount.SingleAccount_NonSummary_Segment_Fields.WrittenOffAmountPrincipal;
                                    }else {
                                        dpdReason = 'Written Off Principal Amount - '+iterAccount.SingleAccount_NonSummary_Segment_Fields.WrittenOffAmountPrincipal;
                                    }                                    
                                }else if(String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.SettlementAmount )){
                                    iterObl.DPD_in_Tradeline__c = 'Yes';
                                    if(dpdReason!= null && dpdReason!= ''){
                                        dpdReason = dpdReason + ', Settlement Amount - '+iterAccount.SingleAccount_NonSummary_Segment_Fields.SettlementAmount;
                                    }else {
                                        dpdReason = 'Settlement Amount - '+iterAccount.SingleAccount_NonSummary_Segment_Fields.SettlementAmount;
                                    }                                    
                                }else{
                                    iterObl.DPD_in_Tradeline__c = 'No';
                                }
                            }
                            iterObl.DPD_Reason__c = dpdReason;
                            
                            String datereportedStr = String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.DateReportedAndCertified)?iterAccount.SingleAccount_NonSummary_Segment_Fields.DateReportedAndCertified:'';
                            if(datereportedStr.length() == 8){
                                String day = datereportedStr.substring(0,2);
                                String mon = datereportedStr.substring(2,4);
                                String year = datereportedStr.substring(4,8);
                                datereportedStr = year+'-'+mon+'-'+day;
                                iterObl.Reported_Date__c = Date.valueOf(datereportedStr);
                            }
                            if(iterObl.Type__c == 'Live Loan') {
                                Income_Expense_Obligation__c iterObl1 = iterObl.clone(false,true,false,false);
                                iterObl1.Type__c = 'Obligation';
                                iterObl1.Is_Considered_Obligation__c = true;
                                bureauLstToInsert.add(iterObl1);
                            }
                            bureauLstToInsert.add(iterObl);
                    }
                    if(lstToBeRemoved.size() > 0) {
                        delete lstToBeRemoved;
                    }
                    if(objRecords.CreditReport.NameSegment!=null){
                        System.debug('objRecords.CreditReport.NameSegment --> '+objRecords.CreditReport.NameSegment);
                    }
                    if(bureauLstToInsert.size() > 0) {
                        insert bureauLstToInsert;
                    }
                    // triangulation
                    List<Triangulation_Data__c> cibilTriangulDataLst = [SELECT Id, PAN__c, Mobile_Number__c, Date_Of_Birth__c FROM Triangulation_Data__c 
                                                                        WHERE Loan_Application__c =: loanId AND Application_Applicant__c =: applicantId 
                                                                        AND Document_Type__c = 'PAN' AND Source_Type__c = 'CIBIL'];
                    if (!cibilTriangulDataLst.isEmpty()) {
                        Triangulation_Data__c triangulationData = cibilTriangulDataLst[0];
                        triangulationData.PAN__c = cibilResp.pan;
                        triangulationData.Mobile_Number__c = cibilResp.mobile;
                        String dobStr = String.valueOf(objRecords.CreditReport.NameSegment.DateOfBirth);
                        if(dobStr != null && dobStr.length() == 8){
                            String day = dobStr.substring(0,2);
                            String mon = dobStr.substring(2,4);
                            String year = dobStr.substring(4,8);
                            dobStr = year+'-'+mon+'-'+day;
                            triangulationData.Date_of_Birth__c = dobStr;
                        }
                        update triangulationData;
                    } else {
                        Triangulation_Data__c triangulationData = new Triangulation_Data__c();
                        triangulationData.PAN__c = cibilResp.pan;
                        triangulationData.Mobile_Number__c = cibilResp.mobile;
                        String dobStr = String.valueOf(objRecords.CreditReport.NameSegment.DateOfBirth);
                        if(dobStr != null && dobStr.length() == 8){
                            String day = dobStr.substring(0,2);
                            String mon = dobStr.substring(2,4);
                            String year = dobStr.substring(4,8);
                            dobStr = year+'-'+mon+'-'+day;
                            triangulationData.Date_of_Birth__c = dobStr;
                        }
                        triangulationData.Document_Type__c = 'PAN';
                        triangulationData.Source_Type__c = 'CIBIL';
                        triangulationData.Loan_Application__c = loanId;
                        triangulationData.Application_Applicant__c = applicantId;
                        insert triangulationData;
                    }
                }
                Application_Applicant__c appdet = new Application_Applicant__c();
                appdet.Cibil_Score__c =cibilResp.cibilScore!=null?cibilResp.cibilScore:0;
                
                appDet.id = applicantId;
                update appdet;
                integrationDetail.Status__c = String.valueof(resp.getStatusCode());
                integrationDetail.Name =processName ;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.Loan_Application__c = loanId;
                integrationDetail.Related_Record_Id__c = applicantId;
                integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                //integrationDetail.Request_JSON__c = respWrapper.payload; 
                returnResp = JSON.serialize(cibilResp);
            }
            else if(resp.getStatusCode()== 503){
                integrationDetail.Status__c = String.valueof(resp.getStatusCode());
                integrationDetail.Name =processName ;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.Loan_Application__c = loanId;
                integrationDetail.Related_Record_Id__c = applicantId;
                integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 
                integrationDetail.Response_JSON__c = resp.getBody();
                returnResp = 'Error:' + 'Service Temporarily Unavailable';
              }
            else{
                integrationDetail.Status__c = String.valueof(resp.getStatusCode());
                integrationDetail.Name =processName ;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.Loan_Application__c = loanId;
                integrationDetail.Related_Record_Id__c = applicantId;
                integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 
                integrationDetail.Response_JSON__c = resp.getBody();
                returnResp = 'Error:';
            }
        }
            insert integrationDetail;
            return returnResp; 
        } catch (Exception e) {
            throw new AuraHandledException('ERROR:' +e.getStackTraceString());
        }
    }*/
    @AuraEnabled
    public static String initiateAPIRequest(Map<String,String> inputMap){
        try {
			Integration_Details__c integrationDetails = new Integration_Details__c();
			String loanId = inputMap.get('loanId');
            String applicantId = inputMap.get('applicantId');
			String processName = inputMap.get('processName');
            
            
            // to mock fico cibil eligibility
            List<Integration_Details__c> intDetails  = [SELECT id,Related_Record_Id__c,Name from Integration_Details__c where Name ='FICO cibil' AND id='a0QdN00000FxPkwUAF'];
            Integration_Details__c ficoCibilDetail = intDetails[0];
            ficoCibilDetail.Related_Record_Id__c = applicantId;
            update ficoCibilDetail;
            
            // add loan cibil 
            List<Integration_Details__c> loanCibilDetails  = [SELECT id,Related_Record_Id__c,Name from Integration_Details__c where Name ='Loan cibil' AND id='a0QdN00000FxRRlUAN'];
            Integration_Details__c loanCibilDetail = loanCibilDetails[0];
            loanCibilDetail.Related_Record_Id__c = applicantId;
            loanCibilDetail.Loan_Application__c=loanId;
            update loanCibilDetail;
            
            // add Gen ai 
            List<Integration_Details__c> genAiIntDetails  = [SELECT id,Related_Record_Id__c,Name from Integration_Details__c where Name ='Gen AI' AND id='a0QdN00000FxRUzUAN'];
            Integration_Details__c genAIDetail = genAiIntDetails[0];
            genAIDetail.Related_Record_Id__c = applicantId;
            genAIDetail.Loan_Application__c=loanId;
            update genAIDetail;

            
            // mock cibil fetch
            List<Document_Details__c> docDetails = [SELECT id,Name  from Document_Details__c where Id in ('a0edN000008YyegQAC', 'a0edN000008YyefQAC')];
			Document_Details__c doc1 = docDetails[0];
			doc1.Applicant__c = applicantId;
            doc1.Loan_Application__c = loanId;
			update doc1;
			Document_Details__c doc2 = docDetails[1];
			doc2.Applicant__c = applicantId;
            doc2.Loan_Application__c = loanId;
			update doc2;

             // Mock- add loan Id to live and closed loans
            List<Income_Expense_Obligation__c> liveLoanAndClosed = [Select Id from Income_Expense_Obligation__c];
            for(Income_Expense_Obligation__c rec : liveLoanAndClosed)
            {
                rec.Loan_Application__c = loanId;
            }
            update liveLoanAndClosed;
            
            // hardcode cibil score for the applicant to 800
            List<Application_Applicant__c> applicants  = [SELECT id from Application_Applicant__c where id =: applicantId];
			Application_Applicant__c applicant = applicants[0];
			applicant.CIBIL_Score__c = 800;
			update applicant;



            
           /*
            String returnResp;
            String resultMessage;
            List<Application_Applicant__c> applicantList = new List<Application_Applicant__c>();
            applicantList = [Select Id,Applicant_Name__c,Cibil_Score__c,DOB__c,DOI__c,Email__c,Company__c,Loan_Application__c,PAN_Number__c,Customer_Type__c FROM Application_Applicant__c WHERE Id =: applicantId];
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
            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper(); 
            wrapper.recordId =applicantId ;
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
            
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
            FROM Integration_Settings__c WHERE Name = 'Loan Applicant CIBIL' LIMIT 1];
            Integration_Settings__c intSetting = intSettingList[0];
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name =processName ;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.Loan_Application__c = loanId;
                integrationDetail.Related_Record_Id__c = applicantId;
                integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                System.debug('resultMessage: '+resultMessage);
                returnResp = resultMessage;
            }
            else {
                Map<String, String> integrationRequestMap = new Map<String, String>();
                integrationRequestMap.put('intSettingName', 'Loan Applicant CIBIL');
                integrationRequestMap.put('requestJSON', respWrapper.payload);           
                String bearer = Utility.getAccessToken();
                System.debug('bearer----' + bearer);
                integrationRequestMap.put('bearer', bearer);
                String origin = Constants__mdt.getInstance('Org_Origin').Value__c;
                integrationRequestMap.put('Origin', origin);
                System.debug('integrationRequestMap ' + integrationRequestMap);
                // Hardcoded JSON Response
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                System.debug('83 resp: '+resp);
				System.debug('ckycResp resp getStatusCode '+resp.getStatusCode());
                String jsonResponse = resp.getBody();
                System.debug('API Response: ' + jsonResponse);
                // Deserialize the hardcoded JSON
                System.debug('ckycResp resp getStatusCode '+resp.getStatusCode());
                if(resp.getStatusCode() == 200){
                CIBILResponseWrapper cibilResp = (CIBILResponseWrapper) JSON.deserialize(resp.getBody(), CIBILResponseWrapper.class);
                System.debug('cibilResp: ' + cibilResp);
                System.debug('cibilpdfdocumentbase64 '+cibilResp.cibilpdfdocumentbase64);
                if (cibilResp.cibilpdfdocumentbase64 != null) {
                    // Blob contentBlob = EncodingUtil.base64Decode(cibilResp.cibilpdfdocumentbase64);
                   // Check if contentBlob is null
                    // ContentVersion cv = new ContentVersion();
                    // cv.Title = 'CIBIL_' + cibilResp.cibildocumentid;
                    // cv.PathOnClient = 'CIBIL_' + cibilResp.cibildocumentid + '.pdf';
                    // cv.VersionData = contentBlob;
                    // cv.IsMajorVersion = true;
                    // insert cv;
                    ContentVersion cd = [SELECT Id,ContentDocumentId FROM ContentVersion WHERE Id = :cibilResp.cibilpdfdocumentbase64 LIMIT 1];
                    Document_Master__c dm = new Document_Master__c();
                    dm = [Select Id,name from Document_Master__c where name = 'CIBIL' AND Is_Active__c = true LIMIT 1];
                    if(dm == null){
                    dm = [Select Id,name from Document_Master__c where name = 'Other' AND Is_Active__c = true LIMIT 1];
                    }
                    Document_Details__c cibilDoc = new Document_Details__c();
                    cibilDoc.Name = 'CIBIL';
                    cibilDoc.Content_Document_Id__c = cd.ContentDocumentId;
                    cibilDoc.Loan_Application__c = loanId;
                    cibilDoc.Applicant__c = applicantList[0].Id;
                    cibilDoc.Remarks__c = 'This document is created at draft stage when we capture the CIBIL score.';
                    cibilDoc.Document_Master__c = dm.Id;
                    cibilDoc.Status__c = 'Uploaded';
                    insert cibilDoc;
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.LinkedEntityId = cibilDoc.id;
                    cdl.ContentDocumentId = cd.ContentDocumentId;
                    cdl.ShareType = 'V';
                    cdl.Visibility = 'AllUsers';
                    insert cdl;
                }
                if(cibilResp.tuffResponse!=null){
                    ContentVersion tuffCv = [SELECT Id, VersionData FROM ContentVersion WHERE Id = :cibilResp.tuffResponse LIMIT 1];
                    String JSONRes = tuffCv.VersionData.toString();
                    System.debug('JSONRes ' + JSONRes);

                    Integer crKeyIdx = JSONRes.indexOf('"CreditReport"');
                    if (crKeyIdx >= 0) {
                        Integer valueStart = JSONRes.indexOf('{', JSONRes.indexOf(':', crKeyIdx));
                        Integer depth = 0;
                        Integer crEndIdx = valueStart;
                        for (Integer i = valueStart; i < JSONRes.length(); i++) {
                            Integer ch = JSONRes.charAt(i);
                            if (ch == 123) { depth++; }         // '{'
                            else if (ch == 125) {               // '}'
                                depth--;
                                if (depth == 0) { crEndIdx = i; break; }
                            }
                        }
                        JSONRes = '{"CreditReport":' + JSONRes.substring(valueStart, crEndIdx + 1) + '}';
                    }
                    System.debug('CreditReport extracted ' + JSONRes);

                    CibilAPIController objRecords = (CibilAPIController)JSON.deserialize(JSONRes, CibilAPIController.class);
                    System.debug('objRecords '+objRecords);
                    storeCibilResponseAsFile(JSON.serialize(cibilResp), applicantList[0].id,loanId);
                    Id obligationRecordTypeId = Schema.SObjectType.Income_Expense_Obligation__c.getRecordTypeInfosByName().get('Income Expense & Obligation').getRecordTypeId();
                    List<Income_Expense_Obligation__c> parent = [SELECT id from Income_Expense_Obligation__c where Loan_Application__c =:loanId AND Type__c='Obligation' AND IsParent__c = true];
                    if(parent.size() > 0) {
            
                    }else {
                        Income_Expense_Obligation__c parentObj = new Income_Expense_Obligation__c();
                        parentObj.IsParent__c = true;
                        parentObj.Loan_Application__c = loanId;
                        parentObj.Type__c = 'Obligation';
                        parentObj.RecordTypeId = obligationRecordTypeId; 
                        insert parentObj;

                    }
                    List<Income_Expense_Obligation__c> bureauLstToInsert = new List<Income_Expense_Obligation__c>();
                    List<Income_Expense_Obligation__c> lstToBeRemoved = [SELECT id FROM Income_Expense_Obligation__c WHERE Loan_Application__c =:applicantList[0].Loan_Application__c AND Application_Applicant__c=:applicantList[0].id AND RecordTypeId=:obligationRecordTypeId AND Bureau_Type__c = 'CIBIL' AND Source__c != 'Manual'];

                    if(objRecords.CreditReport.Account != null ) {
                        // Integer se = checkSize(objRecords.CreditReport.Account);
                        // System.debug('se : '+se);
                        // if(se!=-1){
                        for(CibilAPIController.ClsAccount iterAccount : objRecords.CreditReport.Account) {
                            Income_Expense_Obligation__c iterObl = new Income_Expense_Obligation__c();
                            iterObl.RecordTypeId = obligationRecordTypeId;
                            iterObl.Bureau_Type__c = 'CIBIL';
                            iterObl.Application_Applicant__c = applicantList[0].id;
                            iterObl.Loan_Application__c = applicantList[0].Loan_Application__c;
                            System.debug('Account Tpyr '+iterAccount.Account_NonSummary_Segment_Fields.AccountType);
                            Account_Type_Mapping__mdt metaDataRec = Account_Type_Mapping__mdt.getInstance('X'+iterAccount.Account_NonSummary_Segment_Fields.AccountType);
                            if(metaDataRec != null) {
                            iterObl.Account_Type__c = metaDataRec.Account_Type__c;
                            if(metaDataRec.CC_NON_CC__c == 'NON CC') {
                                iterObl.Loan_Amount__c = iterAccount.Account_NonSummary_Segment_Fields.HighCreditOrSanctionedAmount != null ? Double.valueOf(iterAccount.Account_NonSummary_Segment_Fields.HighCreditOrSanctionedAmount):0;
                            }else if(metaDataRec.CC_NON_CC__c == 'CC') {
                                iterObl.Loan_Amount__c = iterAccount.Account_NonSummary_Segment_Fields.HighCreditOrSanctionedAmount != null ? Double.valueOf(iterAccount.Account_NonSummary_Segment_Fields.HighCreditOrSanctionedAmount):0;
                                //credit limit tag is missing
                            }else {
                                iterObl.Loan_Amount__c = 0;
                            }
                                iterObl.Secured_Unsecured__c = metaDataRec.Secured_Unsecured__c;
                            }else {
                                iterObl.Loan_Amount__c = 0;
                                
                            }
                            
                            iterObl.Current_Balance__c = iterAccount.Account_NonSummary_Segment_Fields.CurrentBalance!=null?Double.valueOf(iterAccount.Account_NonSummary_Segment_Fields.CurrentBalance):0;
                            iterObl.Overdue__c = iterAccount.Account_NonSummary_Segment_Fields.AmountOverdue != null ? Double.valueOf(iterAccount.Account_NonSummary_Segment_Fields.AmountOverdue):0;
                            //Amoount Overdue tag is missing
                            iterObl.Imputed_EMI__c = iterAccount.Account_NonSummary_Segment_Fields.EmiAmount!=null ? Double.valueOf(iterAccount.Account_NonSummary_Segment_Fields.EmiAmount):0;
                            if(iterAccount.Account_NonSummary_Segment_Fields.OwenershipIndicator == '1') {
                                iterObl.Ownership__c = 'Individual';
                            }else if(iterAccount.Account_NonSummary_Segment_Fields.OwenershipIndicator == '2') {
                                iterObl.Ownership__c = 'Authorised User';
                            }else if(iterAccount.Account_NonSummary_Segment_Fields.OwenershipIndicator == '3') {
                                iterObl.Ownership__c = 'Guarantor';
                            }else if(iterAccount.Account_NonSummary_Segment_Fields.OwenershipIndicator == '4') {
                                iterObl.Ownership__c = 'Joint';
                            }
                            String dateStr = String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.DateOpenedOrDisbursed)?iterAccount.Account_NonSummary_Segment_Fields.DateOpenedOrDisbursed:'';
                            if(dateStr.length() == 8){
                                String day = dateStr.substring(0,2);
                                String mon = dateStr.substring(2,4);
                                String year = dateStr.substring(4,8);
                                dateStr = year+'-'+mon+'-'+day;
                                iterObl.Start_Date__c = Date.valueOf(dateStr);
                            }
                            String dateLastStr = String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.DateOfLastPayment)?iterAccount.Account_NonSummary_Segment_Fields.DateOfLastPayment:'';
                            if(dateLastStr.length() == 8){
                                String day = dateLastStr.substring(0,2);
                                String mon = dateLastStr.substring(2,4);
                                String year = dateLastStr.substring(4,8);
                                dateLastStr = year+'-'+mon+'-'+day;
                                iterObl.Last_Payment_Date__c = Date.valueOf(dateLastStr);
                            }
                            String dateClosStr = String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.DateClosed)?iterAccount.Account_NonSummary_Segment_Fields.DateClosed:'';
                            if(String.isNotBlank(dateClosStr)) {
                                iterObl.Type__c = 'Closed Loan';
                            }else {
                                iterObl.Type__c = 'Live Loan';
                            }
                            if(dateClosStr.length() == 8){
                                String day = dateClosStr.substring(0,2);
                                String mon = dateClosStr.substring(2,4);
                                String year = dateClosStr.substring(4,8);
                                dateClosStr = year+'-'+mon+'-'+day;
                                iterObl.Closed_Date__c = Date.valueOf(dateClosStr);
                            }
                            String datePaymentStartStr = String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.PaymentHistoryStartDate)?iterAccount.Account_NonSummary_Segment_Fields.PaymentHistoryStartDate:'';
                            if(datePaymentStartStr.length() == 8){
                                String day = datePaymentStartStr.substring(0,2);
                                String mon = datePaymentStartStr.substring(2,4);
                                String year = datePaymentStartStr.substring(4,8);
                                datePaymentStartStr = year+'-'+mon+'-'+day;
                            }
                            String datePaymentEndStr = String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.PaymentHistoryEndDate)?iterAccount.Account_NonSummary_Segment_Fields.PaymentHistoryEndDate:'';
                            if(datePaymentEndStr.length() == 8){
                                String day = datePaymentEndStr.substring(0,2);
                                String mon = datePaymentEndStr.substring(2,4);
                                String year = datePaymentEndStr.substring(4,8);
                                datePaymentEndStr = year+'-'+mon+'-'+day;
                            }
                            String dpdStr = '';
                            Boolean dpdTradeline = false;
                            String dpdReason='';
                            List<String> dpdList= new List<String>{'000', 'XXX', 'STD'};
                            if(String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.PaymentHistory1)) {
                                String paymentStr= iterAccount.Account_NonSummary_Segment_Fields.PaymentHistory1;
                                for (Integer i = 0; i < paymentStr.length(); i += 3) {
                                    Integer last = Math.min(i + 3, paymentStr.length());
                                    dpdStr += paymentStr.substring(i, last) + ' ';
                                    if(!dpdList.contains(paymentStr.substring(i, last))){
                                        dpdTradeline = true;
                                    }
                                }
                                // dpdStr = iterAccount.Account_NonSummary_Segment_Fields.PaymentHistory1;
                            }
                            if(String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.PaymentHistory2)) {
                                String paymentStr= iterAccount.Account_NonSummary_Segment_Fields.PaymentHistory2;
                                for (Integer i = 0; i < paymentStr.length(); i += 3) {
                                    Integer last = Math.min(i + 3, paymentStr.length());
                                    dpdStr += paymentStr.substring(i, last) + ' ';
                                    if(!dpdList.contains(paymentStr.substring(i, last))){
                                        dpdTradeline = true;
                                    }
                                }
                                dpdStr = dpdStr.trim();
                                // dpdStr = dpdStr + iterAccount.Account_NonSummary_Segment_Fields.PaymentHistory2;
                            }
                            iterObl.DPD__c = datePaymentStartStr+' '+dpdStr+' '+datePaymentEndStr;
                            if(dpdTradeline){
                                iterObl.DPD_in_Tradeline__c = 'Yes';
                            }else{
                                if(String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.SuitFiledOrWilfulDefault) && iterAccount.Account_NonSummary_Segment_Fields.SuitFiledOrWilfulDefault != '00'){
                                    iterObl.DPD_in_Tradeline__c = 'Yes';
                                    if(dpdReason!= null && dpdReason!= ''){
                                        dpdReason = dpdReason + ', Suit Filed Or Wilful Default - '+iterAccount.Account_NonSummary_Segment_Fields.SuitFiledOrWilfulDefault;
                                    }else{
                                        dpdReason = 'Suit Filed Or Wilful Default - '+iterAccount.Account_NonSummary_Segment_Fields.SuitFiledOrWilfulDefault;
                                    }
                                }
                                else if(String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.WrittenOffAmountTotal )){
                                    iterObl.DPD_in_Tradeline__c = 'Yes';
                                    if(dpdReason!= null && dpdReason!= ''){
                                        dpdReason =dpdReason +  ', Written Off Total Amount - '+iterAccount.Account_NonSummary_Segment_Fields.WrittenOffAmountTotal;
                                    }else {
                                        dpdReason = 'Written Off Total Amount - '+iterAccount.Account_NonSummary_Segment_Fields.WrittenOffAmountTotal;   
                                    }                                    
                                }else if(String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.WrittenOffAmountPrincipal )){
                                    iterObl.DPD_in_Tradeline__c = 'Yes';
                                    if(dpdReason!= null && dpdReason!= ''){
                                        dpdReason = dpdReason + ', Written Off Principal Amount - '+iterAccount.Account_NonSummary_Segment_Fields.WrittenOffAmountPrincipal;
                                    }else {
                                        dpdReason = 'Written Off Principal Amount - '+iterAccount.Account_NonSummary_Segment_Fields.WrittenOffAmountPrincipal;
                                    }                                    
                                }else if(String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.SettlementAmount )){
                                    iterObl.DPD_in_Tradeline__c = 'Yes';
                                    if(dpdReason!= null && dpdReason!= ''){
                                        dpdReason = dpdReason + ', Settlement Amount - '+iterAccount.Account_NonSummary_Segment_Fields.SettlementAmount;
                                    }else {
                                        dpdReason = 'Settlement Amount - '+iterAccount.Account_NonSummary_Segment_Fields.SettlementAmount;
                                    }                                    
                                }else{
                                    iterObl.DPD_in_Tradeline__c = 'No';
                                }
                            }
                            iterObl.DPD_Reason__c = dpdReason;
                            
                            String datereportedStr = String.isNotBlank(iterAccount.Account_NonSummary_Segment_Fields.DateReportedAndCertified)?iterAccount.Account_NonSummary_Segment_Fields.DateReportedAndCertified:'';
                            if(datereportedStr.length() == 8){
                                String day = datereportedStr.substring(0,2);
                                String mon = datereportedStr.substring(2,4);
                                String year = datereportedStr.substring(4,8);
                                datereportedStr = year+'-'+mon+'-'+day;
                                iterObl.Reported_Date__c = Date.valueOf(datereportedStr);
                            }
                            if(iterObl.Type__c == 'Live Loan') {
                                Income_Expense_Obligation__c iterObl1 = iterObl.clone(false,true,false,false);
                                iterObl1.Type__c = 'Obligation';
                                iterObl1.Is_Considered_Obligation__c = true;
                                bureauLstToInsert.add(iterObl1);
                            }
                            
                            bureauLstToInsert.add(iterObl);
                        }
                    }
                    else if(objRecords.CreditReport.SingleAccount != null){
                        CibilAPIController.ClsSingleAccount iterAccount = objRecords.CreditReport.SingleAccount;
                            Income_Expense_Obligation__c iterObl = new Income_Expense_Obligation__c();
                            iterObl.RecordTypeId = obligationRecordTypeId;
                            iterObl.Bureau_Type__c = 'CIBIL';
                            iterObl.Application_Applicant__c = applicantList[0].id;
                            iterObl.Loan_Application__c = applicantList[0].Loan_Application__c;
                            System.debug('Account Tpyr '+iterAccount.SingleAccount_NonSummary_Segment_Fields.SingleAccountType);
                            Account_Type_Mapping__mdt metaDataRec = Account_Type_Mapping__mdt.getInstance('X'+iterAccount.SingleAccount_NonSummary_Segment_Fields.SingleAccountType);
                            if(metaDataRec != null) {
                            iterObl.Account_Type__c = metaDataRec.Account_Type__c;
                            if(metaDataRec.CC_NON_CC__c == 'NON CC') {
                                    iterObl.Loan_Amount__c = iterAccount.SingleAccount_NonSummary_Segment_Fields.HighCreditOrSanctionedAmount != null ? Double.valueOf(iterAccount.SingleAccount_NonSummary_Segment_Fields.HighCreditOrSanctionedAmount):0;
                            }else if(metaDataRec.CC_NON_CC__c == 'CC') {
                                    iterObl.Loan_Amount__c = iterAccount.SingleAccount_NonSummary_Segment_Fields.HighCreditOrSanctionedAmount != null ? Double.valueOf(iterAccount.SingleAccount_NonSummary_Segment_Fields.HighCreditOrSanctionedAmount):0;
                                //credit limit tag is missing
                            }else {
                                iterObl.Loan_Amount__c = 0;
                            }
                                iterObl.Secured_Unsecured__c = metaDataRec.Secured_Unsecured__c;
                            }else {
                                iterObl.Loan_Amount__c = 0;
                            }
                            
                            iterObl.Current_Balance__c = iterAccount.SingleAccount_NonSummary_Segment_Fields.CurrentBalance!=null?Double.valueOf(iterAccount.SingleAccount_NonSummary_Segment_Fields.CurrentBalance):0;
                            iterObl.Overdue__c = iterAccount.SingleAccount_NonSummary_Segment_Fields.AmountOverdue != null ? Double.valueOf(iterAccount.SingleAccount_NonSummary_Segment_Fields.AmountOverdue):0;
                            //Amoount Overdue tag is missing
                            iterObl.Imputed_EMI__c = iterAccount.SingleAccount_NonSummary_Segment_Fields.EmiAmount!=null ? Double.valueOf(iterAccount.SingleAccount_NonSummary_Segment_Fields.EmiAmount):0;
                            if(iterAccount.SingleAccount_NonSummary_Segment_Fields.OwenershipIndicator == '1') {
                                iterObl.Ownership__c = 'Individual';
                            }else if(iterAccount.SingleAccount_NonSummary_Segment_Fields.OwenershipIndicator == '2') {
                                iterObl.Ownership__c = 'Authorised User';
                            }else if(iterAccount.SingleAccount_NonSummary_Segment_Fields.OwenershipIndicator == '3') {
                                iterObl.Ownership__c = 'Guarantor';
                            }else if(iterAccount.SingleAccount_NonSummary_Segment_Fields.OwenershipIndicator == '4') {
                                iterObl.Ownership__c = 'Joint';
                            }
                            String dateStr = String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.DateOpenedOrDisbursed)?iterAccount.SingleAccount_NonSummary_Segment_Fields.DateOpenedOrDisbursed:'';
                            if(dateStr.length() == 8){
                                String day = dateStr.substring(0,2);
                                String mon = dateStr.substring(2,4);
                                String year = dateStr.substring(4,8);
                                dateStr = year+'-'+mon+'-'+day;
                                iterObl.Start_Date__c = Date.valueOf(dateStr);
                            }
                            String dateLastStr = String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.DateOfLastPayment)?iterAccount.SingleAccount_NonSummary_Segment_Fields.DateOfLastPayment:'';
                            if(dateLastStr.length() == 8){
                                String day = dateLastStr.substring(0,2);
                                String mon = dateLastStr.substring(2,4);
                                String year = dateLastStr.substring(4,8);
                                dateLastStr = year+'-'+mon+'-'+day;
                                iterObl.Last_Payment_Date__c = Date.valueOf(dateLastStr);
                            }
                            String dateClosStr = String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.DateClosed)?iterAccount.SingleAccount_NonSummary_Segment_Fields.DateClosed:'';
                            if(String.isNotBlank(dateClosStr)) {
                                iterObl.Type__c = 'Closed Loan';
                            }else {
                                iterObl.Type__c = 'Live Loan';
                            }
                            if(dateClosStr.length() == 8){
                                String day = dateClosStr.substring(0,2);
                                String mon = dateClosStr.substring(2,4);
                                String year = dateClosStr.substring(4,8);
                                dateClosStr = year+'-'+mon+'-'+day;
                                iterObl.Closed_Date__c = Date.valueOf(dateClosStr);
                            }
                            String datePaymentStartStr = String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.PaymentHistoryStartDate)?iterAccount.SingleAccount_NonSummary_Segment_Fields.PaymentHistoryStartDate:'';
                            if(datePaymentStartStr.length() == 8){
                                String day = datePaymentStartStr.substring(0,2);
                                String mon = datePaymentStartStr.substring(2,4);
                                String year = datePaymentStartStr.substring(4,8);
                                datePaymentStartStr = year+'-'+mon+'-'+day;
                            }
                            String datePaymentEndStr = String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.PaymentHistoryEndDate)?iterAccount.SingleAccount_NonSummary_Segment_Fields.PaymentHistoryEndDate:'';
                            if(datePaymentEndStr.length() == 8){
                                String day = datePaymentEndStr.substring(0,2);
                                String mon = datePaymentEndStr.substring(2,4);
                                String year = datePaymentEndStr.substring(4,8);
                                datePaymentEndStr = year+'-'+mon+'-'+day;
                            }
                            String dpdStr = '';
                            Boolean dpdTradeline = false;
                            String dpdReason='';
                            List<String> dpdList= new List<String>{'000', 'XXX', 'STD'};
                            if(String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.PaymentHistory1)) {
                                String paymentStr= iterAccount.SingleAccount_NonSummary_Segment_Fields.PaymentHistory1;
                                for (Integer i = 0; i < paymentStr.length(); i += 3) {
                                    Integer last = Math.min(i + 3, paymentStr.length());
                                    dpdStr += paymentStr.substring(i, last) + ' ';
                                    if(!dpdList.contains(paymentStr.substring(i, last))){
                                        dpdTradeline = true;
                                    }
                                }
                                // dpdStr = iterAccount.Account_NonSummary_Segment_Fields.PaymentHistory1;
                            }
                            if(String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.PaymentHistory2)) {
                                String paymentStr= iterAccount.SingleAccount_NonSummary_Segment_Fields.PaymentHistory2;
                                for (Integer i = 0; i < paymentStr.length(); i += 3) {
                                    Integer last = Math.min(i + 3, paymentStr.length());
                                    dpdStr += paymentStr.substring(i, last) + ' ';
                                    if(!dpdList.contains(paymentStr.substring(i, last))){
                                        dpdTradeline = true;
                                    }
                                }
                                dpdStr = dpdStr.trim();
                                // dpdStr = dpdStr + iterAccount.Account_NonSummary_Segment_Fields.PaymentHistory2;
                            }
                            iterObl.DPD__c = datePaymentStartStr+' '+dpdStr+' '+datePaymentEndStr;
                            if(dpdTradeline){
                                iterObl.DPD_in_Tradeline__c = 'Yes';
                            }else{
                                if(String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.SuitFiledOrWilfulDefault) && iterAccount.SingleAccount_NonSummary_Segment_Fields.SuitFiledOrWilfulDefault != '00'){
                                    iterObl.DPD_in_Tradeline__c = 'Yes';
                                    if(dpdReason!= null && dpdReason!= ''){
                                        dpdReason = dpdReason + ', Suit Filed Or Wilful Default - '+iterAccount.SingleAccount_NonSummary_Segment_Fields.SuitFiledOrWilfulDefault;
                                    }else{
                                        dpdReason = 'Suit Filed Or Wilful Default - '+iterAccount.SingleAccount_NonSummary_Segment_Fields.SuitFiledOrWilfulDefault;
                                    }
                                }
                                else if(String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.WrittenOffAmountTotal )){
                                    iterObl.DPD_in_Tradeline__c = 'Yes';
                                    if(dpdReason!= null && dpdReason!= ''){
                                        dpdReason =dpdReason +  ', Written Off Total Amount - '+iterAccount.SingleAccount_NonSummary_Segment_Fields.WrittenOffAmountTotal;
                                    }else {
                                        dpdReason = 'Written Off Total Amount - '+iterAccount.SingleAccount_NonSummary_Segment_Fields.WrittenOffAmountTotal;   
                                    }                                    
                                }else if(String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.WrittenOffAmountPrincipal )){
                                    iterObl.DPD_in_Tradeline__c = 'Yes';
                                    if(dpdReason!= null && dpdReason!= ''){
                                        dpdReason = dpdReason + ', Written Off Principal Amount - '+iterAccount.SingleAccount_NonSummary_Segment_Fields.WrittenOffAmountPrincipal;
                                    }else {
                                        dpdReason = 'Written Off Principal Amount - '+iterAccount.SingleAccount_NonSummary_Segment_Fields.WrittenOffAmountPrincipal;
                                    }                                    
                                }else if(String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.SettlementAmount )){
                                    iterObl.DPD_in_Tradeline__c = 'Yes';
                                    if(dpdReason!= null && dpdReason!= ''){
                                        dpdReason = dpdReason + ', Settlement Amount - '+iterAccount.SingleAccount_NonSummary_Segment_Fields.SettlementAmount;
                                    }else {
                                        dpdReason = 'Settlement Amount - '+iterAccount.SingleAccount_NonSummary_Segment_Fields.SettlementAmount;
                                    }                                    
                                }else{
                                    iterObl.DPD_in_Tradeline__c = 'No';
                                }
                            }
                            iterObl.DPD_Reason__c = dpdReason;
                            
                            String datereportedStr = String.isNotBlank(iterAccount.SingleAccount_NonSummary_Segment_Fields.DateReportedAndCertified)?iterAccount.SingleAccount_NonSummary_Segment_Fields.DateReportedAndCertified:'';
                            if(datereportedStr.length() == 8){
                                String day = datereportedStr.substring(0,2);
                                String mon = datereportedStr.substring(2,4);
                                String year = datereportedStr.substring(4,8);
                                datereportedStr = year+'-'+mon+'-'+day;
                                iterObl.Reported_Date__c = Date.valueOf(datereportedStr);
                            }
                            if(iterObl.Type__c == 'Live Loan') {
                                Income_Expense_Obligation__c iterObl1 = iterObl.clone(false,true,false,false);
                                iterObl1.Type__c = 'Obligation';
                                iterObl1.Is_Considered_Obligation__c = true;
                                bureauLstToInsert.add(iterObl1);
                            }
                            bureauLstToInsert.add(iterObl);
                    }
                    if(lstToBeRemoved.size() > 0) {
                        delete lstToBeRemoved;
                    }
                    if(objRecords.CreditReport.NameSegment!=null){
                        System.debug('objRecords.CreditReport.NameSegment --> '+objRecords.CreditReport.NameSegment);
                    }
                    if(bureauLstToInsert.size() > 0) {
                        insert bureauLstToInsert;
                    }
                    // triangulation
                    List<Triangulation_Data__c> cibilTriangulDataLst = [SELECT Id, PAN__c, Mobile_Number__c, Date_Of_Birth__c FROM Triangulation_Data__c 
                                                                        WHERE Loan_Application__c =: loanId AND Application_Applicant__c =: applicantId 
                                                                        AND Document_Type__c = 'PAN' AND Source_Type__c = 'CIBIL'];
                    if (!cibilTriangulDataLst.isEmpty()) {
                        Triangulation_Data__c triangulationData = cibilTriangulDataLst[0];
                        triangulationData.PAN__c = cibilResp.pan;
                        triangulationData.Mobile_Number__c = cibilResp.mobile;
                        String dobStr = String.valueOf(objRecords.CreditReport.NameSegment.DateOfBirth);
                        if(dobStr != null && dobStr.length() == 8){
                            String day = dobStr.substring(0,2);
                            String mon = dobStr.substring(2,4);
                            String year = dobStr.substring(4,8);
                            dobStr = year+'-'+mon+'-'+day;
                            triangulationData.Date_of_Birth__c = dobStr;
                        }
                        update triangulationData;
                    } else {
                        Triangulation_Data__c triangulationData = new Triangulation_Data__c();
                        triangulationData.PAN__c = cibilResp.pan;
                        triangulationData.Mobile_Number__c = cibilResp.mobile;
                        String dobStr = String.valueOf(objRecords.CreditReport.NameSegment.DateOfBirth);
                        if(dobStr != null && dobStr.length() == 8){
                            String day = dobStr.substring(0,2);
                            String mon = dobStr.substring(2,4);
                            String year = dobStr.substring(4,8);
                            dobStr = year+'-'+mon+'-'+day;
                            triangulationData.Date_of_Birth__c = dobStr;
                        }
                        triangulationData.Document_Type__c = 'PAN';
                        triangulationData.Source_Type__c = 'CIBIL';
                        triangulationData.Loan_Application__c = loanId;
                        triangulationData.Application_Applicant__c = applicantId;
                        insert triangulationData;
                    }
                }
                Application_Applicant__c appdet = new Application_Applicant__c();
                appdet.Cibil_Score__c =cibilResp.cibilScore;
                
                appDet.id = applicantId;
                appDet.CIBIL_Rework_Fields__c = '';
                appDet.CIBIL_Retrigger_Required__c= false;
                update appdet;
                integrationDetail.Status__c = String.valueof(resp.getStatusCode());
                integrationDetail.Name =processName ;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.Loan_Application__c = loanId;
                integrationDetail.Related_Record_Id__c = applicantId;
                integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 
                returnResp = JSON.serialize(cibilResp);
            }
            else if(resp.getStatusCode()== 503){
                integrationDetail.Status__c = String.valueof(resp.getStatusCode());
                integrationDetail.Name =processName ;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.Loan_Application__c = loanId;
                integrationDetail.Related_Record_Id__c = applicantId;
                integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 
                integrationDetail.Response_JSON__c = resp.getBody();
                returnResp = 'Error:' + 'Service Temporarily Unavailable';
              }
            else{
                integrationDetail.Status__c = String.valueof(resp.getStatusCode());
                integrationDetail.Name =processName ;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.Loan_Application__c = loanId;
                integrationDetail.Related_Record_Id__c = applicantId;
                integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 
                integrationDetail.Response_JSON__c = resp.getBody();
                returnResp = 'Error:';
            }
        }
            insert integrationDetail;
*/
            return ''; 
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public static void storeCibilResponseAsFile(String xmlResponse, Id applicantId,Id loanId) {
        // Fetch Document_Master__c where Document_Name__c = 'Cibil'
        Document_Master__c docMaster = [SELECT Id FROM Document_Master__c WHERE Document_Name__c = 'Cibil' LIMIT 1];
    
        if (docMaster != null) {
            // Create ContentVersion (File)
            ContentVersion content = new ContentVersion();
            content.Title = 'Cibil_Response.txt';
            content.PathOnClient = 'Cibil_Response.txt';
            content.VersionData = Blob.valueOf(xmlResponse);
            content.IsMajorVersion = true;
            insert content;
    
            // Fetch ContentDocumentId
            List<ContentVersion> contentVersions = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id LIMIT 1];
          
            Document_Details__c checklist = new Document_Details__c();
            checklist.Applicant__c = applicantId;
            checklist.Document_Master__c = docMaster.Id;
            checklist.Content_Document_Id__c = contentVersions[0].ContentDocumentId;
            checklist.Loan_Application__c = loanId;
            //checklist.Consider_for_Loan_Application__c = true;
            checklist.Name = 'Cibil Response';
            insert checklist;
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = checklist.id;
            cdl.ContentDocumentId = contentVersions[0].ContentDocumentId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;
    
            System.debug('Cibil response stored successfully.');
        } else {
            System.debug('Document Master record not found for Cibil.');
        }
    }
    public static Integer checkSize(Object obj) {
        try {
            // Try casting to a list of generic objects
            List<Object> tempList = (List<Object>) obj;
            return tempList.size();
        } catch (Exception e) {
            // If casting fails (e.g., it's a single object), return -1
            return -1;
        }
    }

    @AuraEnabled
    public static Boolean checkApplicantAddress( String applicantId){
        Boolean res= false;
        try {
            List<Application_Applicant__c> applicantList= [SELECT Id, Pincode__c, Applicant_Type__c, Loan_Application__c FROM Application_Applicant__c WHERE Id = :applicantId];
            List<Applicant_Address__c> applicantAddress = [SELECT Id, Pincode__c FROM Applicant_Address__c WHERE Applicant__c = :applicantId];
            if(applicantList.size()>0){
                if(applicantList[0].Applicant_Type__c == 'Primary Applicant'){
                    return true;
                }else {
                        if(applicantAddress.size()>0){
                            if(applicantAddress[0].Pincode__c!= null ){
                                res= true;
                            }else if(applicantList[0].Pincode__c!= null){
                                Applicant_Address__c appAdd = new Applicant_Address__c();
                                appAdd.Id= applicantAddress[0].Id;
                                appAdd.Pincode__c = applicantList[0].Pincode__c;
                                update appAdd;
                                res= true;
                            }else {
                                res= false;
                            }
                    }else {
                        if(applicantList[0].Pincode__c!= null){
                            Applicant_Address__c appAdd = new Applicant_Address__c();
                            appAdd.Applicant__c = applicantId;
                            appAdd.Loan_Application__c = applicantList[0].Loan_Application__c;
                            appAdd.Pincode__c = applicantList[0].Pincode__c;
                            appAdd.Address_Type__c = 'Current';
                            insert appAdd;
                            res= true;
                        }
                    }
                    
                    if(res){
                        if(applicantList[0].Pincode__c!= null ){
                            res= true;
                        }else {
                            res = false;
                        }   
                    }
                    
                }
                
            }
        } catch (Exception e) {
            // throw new AuraHandledException(e.getMessage());
        }

        return res;
    }

    
    // public class CIBILResponse {
    //     public String cibilHeader;
    //     public PrimaryApplicant primaryApplicant;
    //     public List<SecondaryApplicant> secondaryApplicant;
    // }
    
    
    public class PrimaryApplicant {
        public String scoreCardName;
        public String lengthOfTransmission;
        public String scoreName;
        public List<AddressSegment> addressSegment;
        public String gender;
        public String consumerNameField1;
        public String scoreDate;
        public String score;
        public List<EnquirySegment> enquirySegment;
        public Integer noOfUnsecuredBLPLAcc;
        public String dateOfBirth;
        public List<IdDetail> id;
        public String scoreCardVersion;
    }
    
    public class AddressSegment {
        public String addressLine1;
        public String address;
        public String addressCategory;
        public String dateReported;
        public String addressLine5;
        public String stateCode;
        public String addressEnrichedThroughEnquiry;
        public String residenceCode;
        public String pinCode;
    }
    
    public class EnquirySegment {
        public String dateOfEnquiry;
        public String enquiryPurpose;
        public String enquiringMemberShortName;
        public String enquiryAmount;
        public String enqSno;
    }
    
    public class IdDetail {
        public String enrichedThroughEnquiry;
        public String idType;
        public String idNumber;
    }
    
    public class SecondaryApplicant {
        public String scoreCardName;
        public String lengthOfTransmission;
    }
    public ClsCreditReport CreditReport;
    
	public class ClsCreditReport {
		public ClsAccount[] Account;
        public ClsSingleAccount SingleAccount;
        public Newnamesegment NameSegment; 
	}
    public class ClsSingleAccount {
		public String Length;	//04
		public String SegmentTag;	//T001
        public String DateOfBirth;
		public ClsAccountSummarySegmentFields SingleAccount_Summary_Segment_Fields;
		public ClsAccountNonSummarySegmentFields SingleAccount_NonSummary_Segment_Fields;
    }
    
    public class Newnamesegment{
        public String Length; 
        public String SegmentTag; 
        public String ConsumerName1FieldLength; 
        public String ConsumerName1; 
        public String ConsumerName2FieldLength; 
        public String ConsumerName2;
        public String ConsumerName3FieldLength; 
        public String ConsumerName3; 
        public String DateOfBirthFieldLength;
        public String DateOfBirth; 
        public String GenderFieldLength; 
        public String Gender;
    }
	public class ClsAccount {
		public String Length;	//04
		public String SegmentTag;	//T001
        public String DateOfBirth;
		public ClsAccountSummarySegmentFields Account_Summary_Segment_Fields;
		public ClsAccountNonSummarySegmentFields Account_NonSummary_Segment_Fields;
	}
	public class ClsAccountSummarySegmentFields {
		public String ReportingMemberShortNameFieldLength;	//13
	}
	public class ClsAccountNonSummarySegmentFields {
		public String ReportingMemberShortNameFieldLength;	//13
		public String ReportingMemberShortName;	//NOTDISCLOSED
		public String AccountType;	//51
        public String SingleAccountType;
		public String OwenershipIndicator;	//4
		public String DateOpenedOrDisbursed;	//29052023
		public String DateReportedAndCertified;	//31032024
		public String HighCreditOrSanctionedAmountFieldLength;	//07
		public String HighCreditOrSanctionedAmount;	//1200000
		public String CurrentBalanceFieldLength;	//04
		public String CurrentBalance;	//800000
		public String PaymentHistory1FieldLength;	//03
		public String PaymentHistory1;	//000000000000000000000000000000000
		public String PaymentHistoryStartDate;	//01032024
		public String PaymentHistoryEndDate;	//01052023
        public String DateOfLastPayment;
        public String PaymentHistory2FieldLength;	//03
		public String PaymentHistory2;	//000000000000000000000000000000000
        public String DateClosed;
        public String EmiAmount;
        public String AmountOverdue;
        public String SuitFiledOrWilfulDefault;
        public String WrittenOffAmountTotal;
        public String WrittenOffAmountPrincipal;
        public String SettlementAmount;
	}
      
    public class CibilRetriggerWrapper{
        @AuraEnabled public String data;
        @AuraEnabled public Integer srno;
    }

    @AuraEnabled
    public static List<CibilRetriggerWrapper> fetchCibilData( Map<String, String> inputMap){
        String recordId= inputMap.get('recordId');
        String objectName= inputMap.get('objectName');

        List<CibilRetriggerWrapper> dataList = new List<CibilRetriggerWrapper>();
        try {
            if(objectName== 'Opportunity'){
                List<Application_Applicant__c> applicantList= [SELECT Id, Name, CIBIL_Retrigger_Required__c, CIBIL_Rework_Fields__c FROM Application_Applicant__c WHERE Loan_Application__c = :recordId AND CIBIL_Retrigger_Required__c = true];
                if(applicantList.size()>0){
                    Integer count = 1;
                    for(Application_Applicant__c applicant: applicantList){
                        CibilRetriggerWrapper wrapper = new CibilRetriggerWrapper();
                        wrapper.srno= count;
                        String applicantData = applicant.Name + ' - '+ applicant.CIBIL_Rework_Fields__c;
                        wrapper.data = applicantData;
                        dataList.add(wrapper);
                        count++;
                    }
                }
            }else if(objectName == 'Application_Applicant__c'){
                List<Application_Applicant__c> applicantList= [SELECT Id, Name, CIBIL_Retrigger_Required__c, CIBIL_Rework_Fields__c FROM Application_Applicant__c WHERE Id = :recordId AND CIBIL_Retrigger_Required__c = true];
                if(applicantList.size()>0){
                    Integer count = 1;
                    for(Application_Applicant__c applicant: applicantList){
                        CibilRetriggerWrapper wrapper = new CibilRetriggerWrapper();
                        wrapper.srno= count;
                        String applicantData = applicant.Name + ' - '+ applicant.CIBIL_Rework_Fields__c;
                        wrapper.data = applicantData;
                        dataList.add(wrapper);
                        count++;
                    }
                }
            }
        } catch (Exception e) {
            // throw new AuraHandledException(e.getMessage());
        }
        return dataList;
    }

    public static Date safeDateParse(String dateStr) {
    try {
        return Date.valueOf(dateStr);
    } catch (Exception e) {
        System.debug('Invalid date: ' + dateStr);
        return null; // or handle with default/fallback date
    }
    }
    
 public class CIBILResponseWrapper {
        public Integer leadCibilId;
        public Integer applicationKey;
        public Integer leadId;
        public Integer coApplicantId;
        public Decimal hlorLapLoanAmount;
        public Decimal creditCardOutstanding;
        public Decimal autoLoanAmount;
        public Decimal twoWheelerLoanAmount;
        public Decimal blLoanAmount;
        public Decimal plLoanAmount;
        public Decimal ccOverdueAmount;
        public Decimal secCcOverdueAmount;
        public Decimal eduLoanAmount;
        public Decimal consumerLoanAmount;
        public Decimal commVehicleLoanAmount;
        public Decimal usedCarLoanAmount;
        public Decimal secCreditCardOutstanding;
        public Decimal loanOnCreditCard;
        public Decimal creditCardOutstandingEmi;
        public Decimal hlorLapLoanAmountEmi;
        public Decimal autoLoanAmountEmi;
        public Decimal twoWheelerLoanAmountEmi;
        public Decimal blLoanAmountEmi;
        public Decimal plLoanAmountEmi;
        public Decimal eduLoanAmountEmi;
        public Decimal consumerLoanAmountEmi;
        public Decimal commVehicleLoanAmountEmi;
        public Decimal usedCarLoanAmountEmi;
        public Decimal secCreditCardOutstandingEmi;
        public Decimal loanOnCreditCardEmi;
        public Integer cibilScore;
        public String cibilApplicationId;
        public String cibilDocumentId;
        public String cibilDocumentBase64;
        public String cibilPdfDocumentBase64;
        public Integer noOfAccountsIn30DpdInL12M;
        public Integer noOfAccountsIn60DpdInL12M;
        //public String cibilResponse;
        public String lastMntOn;
        public String pan;
        public String mobile;
        public String tuffResponse;
        public String requestType;
        public String requestSource;
        public String entity;
        public String agency;
        public String createdOn;
        public Integer isActive;
    }  
}