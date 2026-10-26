public without sharing class COMM_CRIFAPIController {
    static string conLabels = 'CRIF_API';
                            
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
                                                        Process_Name__c,Product_Type__c,Product_Version__c,
                                                        Handler_Class__c,
                                                        Endpoint__c,
                                                        Request_Method__c,
                                                        Client_Id__c,
                                                        Client_Secret__c,
                                                        Allowed_Retry__c,
                                                        Gestation_Period__c,
                                                        Refresh_Allowed__c,
                                                        Activity_Name__c,CustomerId__c,UserId__c,Password__c
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
                System.debug('recordId'+applicantId);
                system.debug('respWrapper----'+respWrapper);
                Integration_Details__c integrationDetail = new Integration_Details__c();
                List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                FROM Integration_Settings__c WHERE Name = 'Loan Applicant CRIF' LIMIT 1];
                Integration_Settings__c intSetting = intSettingList[0];
                System.debug('respWrapper.prerequisiteError----- '+respWrapper.prerequisiteError);
                if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                    integrationDetail.Status__c = String.valueof('412');
                    integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                    integrationDetail.Name =processName ;
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Loan_Application__c = loanId;
                    integrationDetail.Related_Record_Id__c = applicantId;
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                    integrationDetail.Request_JSON__c = respWrapper.payload; 
                    integrationDetail.Method_Type__c = metadata.Request_Method__c;
                    resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                    System.debug('resultMessage: '+resultMessage);
                    returnResp = resultMessage;
                }
                else {
                    Map<String, String> integrationRequestMap = new Map<String, String>();
                    String bearer = Utility.getAccessToken();
                System.debug('bearer----' + bearer);
                integrationRequestMap.put('bearer', bearer);
                    integrationRequestMap.put('intSettingName', 'Loan Applicant CRIF');
                    integrationRequestMap.put('requestJSON', respWrapper.payload);
                    system.debug('respWrapper.payload----'+respWrapper.payload);
                    //integrationRequestMap.put('userId', metadata.UserId__c);
                   // integrationRequestMap.put('password', metadata.Password__c);
                  //  integrationRequestMap.put('customerId', metadata.CustomerId__c);   
                  //  integrationRequestMap.put('productType', metadata.Product_Type__c);
                   // integrationRequestMap.put('productVersion', metadata.Product_Version__c);          
                  
                    System.debug('integrationRequestMap ' + integrationRequestMap);
                    // Hardcoded JSON Response
                    HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                    System.debug('83 resp: '+resp);
                    System.debug('Resp resp getStatusCode '+resp.getStatusCode());
                    String jsonResponse = resp.getBody();
                    System.debug('API Response: ' + jsonResponse);
                    // Deserialize the hardcoded JSON
                    System.debug('ckycResp resp getStatusCode '+resp.getStatusCode());
                    if (resp.getStatusCode() == 200) {

                      String jsonResponseCleaned = replaceHyphensBetweenLetters(jsonResponse);
                            CRIFResponseWrapper objRecords = (CRIFResponseWrapper) JSON.deserialize(jsonResponseCleaned, CRIFResponseWrapper.class);
                            System.debug('crifResp: ' + objRecords);

                            if(objRecords!=null && objRecords.CIR_REPORT_FILE.SalesforceDetails != null){
                                 storeCrifFullResponseAsFile(jsonResponse, applicantList[0].Id,loanId);
                                if (objRecords.CIR_REPORT_FILE != null && objRecords.CIR_REPORT_FILE.SalesforceDetails  != null){
                                String contentId = objRecords.CIR_REPORT_FILE.SalesforceDetails.Response.id;
                                system.debug('contentId99--'+contentId);
                                if(contentId != null && contentId != ''){
                                storeCrifHtmlReport(contentId,applicantList[0].Id,loanId);
                                }
                            }
                            System.debug('objRecords '+objRecords);
                            Id obligationRecordTypeId = Schema.SObjectType.Income_Expense_Obligation__c.getRecordTypeInfosByName().get('Income Expense & Obligation').getRecordTypeId();
                            List<Income_Expense_Obligation__c> parent = [SELECT id from Income_Expense_Obligation__c where Loan_Application__c =:loanId AND Type__c='Obligation' AND IsParent__c = true];
                            if(parent.size() > 0) {
                    
                            }else {
                                System.debug('95 ');
                                Income_Expense_Obligation__c parentObj = new Income_Expense_Obligation__c();
                                parentObj.IsParent__c = true;
                                parentObj.Loan_Application__c = loanId;
                                parentObj.Type__c = 'Obligation';
                                parentObj.RecordTypeId = obligationRecordTypeId; 
                             insert parentObj;

                            }
                            List<Income_Expense_Obligation__c> bureauLstToInsert = new List<Income_Expense_Obligation__c>();
                            List<Income_Expense_Obligation__c> lstToBeRemoved = [SELECT id FROM Income_Expense_Obligation__c WHERE Loan_Application__c =:applicantList[0].Loan_Application__c AND Application_Applicant__c=:applicantList[0].id AND RecordTypeId=:obligationRecordTypeId AND Bureau_Type__c = 'CRIF'];

                            if(objRecords != null && objRecords.CIR_REPORT_FILE != null && objRecords.CIR_REPORT_FILE.REPORT_DATA != null
                                && objRecords.CIR_REPORT_FILE.REPORT_DATA.STANDARD_DATA != null && objRecords.CIR_REPORT_FILE.REPORT_DATA.STANDARD_DATA.TRADELINES != null) {

                                cls_TRADELINES[] tradeLinesArray = objRecords.CIR_REPORT_FILE.REPORT_DATA.STANDARD_DATA.TRADELINES;
                               Map<String, Account_Type_Mapping__mdt> acctTypeToMetaMap = new Map<String, Account_Type_Mapping__mdt>();

                                    for (Account_Type_Mapping__mdt meta : [
                                        SELECT Id, Account_Type__c, CC_NON_CC__c, Secured_Unsecured__c 
                                        FROM Account_Type_Mapping__mdt
                                    ]) {
                                        if (meta.Account_Type__c != null) {
                                            acctTypeToMetaMap.put(meta.Account_Type__c.toLowerCase(), meta);
                                        }
                                    }


                                for(cls_TRADELINES iterAccount : tradeLinesArray) {
                                        Income_Expense_Obligation__c iterObl = new Income_Expense_Obligation__c();
                                        iterObl.RecordTypeId = obligationRecordTypeId;
                                        iterObl.Bureau_Type__c = 'CRIF';
                                        iterObl.Application_Applicant__c = applicantList[0].id;
                                        iterObl.Loan_Application__c = applicantList[0].Loan_Application__c;
                                        System.debug('Account Tpyr '+iterAccount.ACCT_TYPE);
                                         //System.debug('Account Tpyr137 '+acctTypeToMetaMap.get(iterAccount.ACCT_TYPE).Account_Type__c);
                                        String acctTypeKey = iterAccount.ACCT_TYPE != null ? iterAccount.ACCT_TYPE.toLowerCase() : null;
                                         System.debug('Account Tpyr '+acctTypeKey);

                                        iterObl.Account_Type__c = acctTypeKey != null && acctTypeToMetaMap.containsKey(acctTypeKey) ? acctTypeToMetaMap.get(acctTypeKey).Account_Type__c: null;                                       
                                        String ccNonCcValue = acctTypeToMetaMap.containsKey(acctTypeKey) ? acctTypeToMetaMap.get(acctTypeKey).CC_NON_CC__c : 'NON CC';
                                        if(ccNonCcValue == 'NON CC' || ccNonCcValue == 'CC') {
                                            iterObl.Loan_Amount__c = (iterAccount.DISBURSED_AMT != null && iterAccount.DISBURSED_AMT.trim() != '') ? Double.valueOf(iterAccount.DISBURSED_AMT.replace(',', '')):0;
                                        }else {
                                            iterObl.Loan_Amount__c = 0;
                                        }
                                        
                                        iterObl.Current_Balance__c = (iterAccount.CURRENT_BAL != null && iterAccount.CURRENT_BAL.trim() != '') ? Double.valueOf(iterAccount.CURRENT_BAL.replace(',', '')) : 0;
                                        iterObl.Overdue__c = (iterAccount.OVERDUE_AMT != null && iterAccount.OVERDUE_AMT.trim() != '') ? Double.valueOf(iterAccount.OVERDUE_AMT.replace(',', '')):0;
                                        iterObl.Imputed_EMI__c =(iterAccount.INSTALLMENT_AMT != null && String.isNotBlank(iterAccount.INSTALLMENT_AMT)) ? Double.valueOf(iterAccount.INSTALLMENT_AMT.replaceAll('[^0-9.]', '')) : 0;
                                        iterObl.Ownership__c = iterAccount.OWNERSHIP_TYPE;
                                        
                                     String dateStr = iterAccount.DISBURSED_DT;

                                            if (String.isNotBlank(dateStr)) {  
                                                List<String> parts = dateStr.split('-');
                                                if (parts.size() == 3) {
                                                    String day = parts[0];
                                                    String mon = parts[1];
                                                    String year = parts[2];
                                                    iterObl.Start_Date__c = Date.valueOf(year + '-' + mon + '-' + day);
                                                }
                                            }

                                        String dateLastStr = iterAccount.LAST_PAYMENT_DT;

                                            if (String.isNotBlank(dateLastStr)) {
                                                List<String> parts = dateLastStr.split('-');
                                                if (parts.size() == 3) {
                                                    String day = parts[0];
                                                    String mon = parts[1];
                                                    String year = parts[2];
                                                    iterObl.Last_Payment_Date__c = Date.valueOf(year + '-' + mon + '-' + day);
                                                }
                                            }

                                        system.debug('iterAccount.CLOSED_DT167--'+iterAccount.CLOSED_DT);
                                        String dateClosStr = String.isNotBlank(iterAccount.CLOSED_DT)?iterAccount.CLOSED_DT:'';
                                        if(String.isNotBlank(dateClosStr)) {
                                            iterObl.Type__c = 'Closed Loan';
                                        }else {
                                            iterObl.Type__c = 'Live Loan';
                                        }

                                        if (String.isNotBlank(dateClosStr)) {
                                            List<String> parts = dateClosStr.split('-');
                                            if (parts.size() == 3) {
                                                String day = parts[0];
                                                String mon = parts[1];
                                                String year = parts[2];
                                                iterObl.Closed_Date__c = Date.valueOf(year + '-' + mon + '-' + day);
                                            }
                                        }
                                                                         

                                       String paymentHistoryStartDate = '';
                                        String dpdReason='';
                                        // List of non-delinque
                                        String paymentHistoryEndDate = '';
                                        String dpdStr = '';
                                        Boolean dpdTradeline = false;
                                        Set<String> dpdList = new Set<String>{'000', 'XXX', 'STD'};

                                        for (cls_HISTORY hist : iterAccount.HISTORY) {

                                            if (hist.NAME == 'COMBINED_PAYMENT_HISTORY') {

                                                // Extract and reverse DATES using CRIF month-year strings
                                                if (String.isNotBlank(hist.DATES)) {
                                                    String cleanDates = hist.DATES.replaceAll('&#124;', '|'); // handle HTML pipe
                                                    List<String> dateList = cleanDates.split('\\|');
                                                    if (!dateList.isEmpty()) {
                                                        paymentHistoryStartDate = dateList[dateList.size() - 1]; // oldest
                                                        paymentHistoryEndDate = dateList[0]; // most recent
                                                    }
                                                }

                                                // Extract VALUES and parse DPDs
                                                if (String.isNotBlank(hist.VALUES)) {
                                                    String cleanValues = hist.VALUES.replaceAll('&#124;', '|'); // handle HTML pipe
                                                    List<String> valueList = cleanValues.split('\\|');
                                                    for (String value : valueList) {
                                                        if (String.isNotBlank(value)) {
                                                            List<String> parts = value.split('/');
                                                            if (!parts.isEmpty()) {
                                                                String dpd = parts[0].trim();
                                                                dpdStr += dpd + ' ';
                                                                if (!dpdList.contains(dpd)) {
                                                                    dpdTradeline = true;
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                break; // exit loop once COMBINED_PAYMENT_HISTORY is found
                                            }
                                        }

                                        // Populate the DPD__c field directly with month-year strings and DPDs
                                        dpdStr = dpdStr.trim();
                                        iterObl.DPD__c = paymentHistoryStartDate + ' ' + dpdStr + ' ' + paymentHistoryEndDate;

                                        if(dpdTradeline){
                                            iterObl.DPD_in_Tradeline__c = 'Yes';
                                        }
                                        else{
                                    if(String.isNotBlank(iterAccount.SUIT_FILED_WILFUL_DEFAULT_STATUS) && iterAccount.SUIT_FILED_WILFUL_DEFAULT_STATUS != '00'){
                                        iterObl.DPD_in_Tradeline__c = 'Yes';
                                        if(dpdReason!= null && dpdReason!= ''){
                                            dpdReason = dpdReason + ', Suit Filed Or Wilful Default - '+iterAccount.SUIT_FILED_WILFUL_DEFAULT_STATUS;
                                        }else{
                                            dpdReason = 'Suit Filed Or Wilful Default - '+iterAccount.SUIT_FILED_WILFUL_DEFAULT_STATUS;
                                        }
                                    }
                                    else if(String.isNotBlank(iterAccount.WRITE_OFF_AMT)){
                                        iterObl.DPD_in_Tradeline__c = 'Yes';
                                        if(dpdReason!= null && dpdReason!= ''){
                                            dpdReason =dpdReason +  ', Written Off Total Amount - '+iterAccount.WRITE_OFF_AMT;
                                        }else {
                                            dpdReason = 'Written Off Total Amount - '+iterAccount.WRITE_OFF_AMT;   
                                        }                                    
                                    }else if(String.isNotBlank(iterAccount.PRINCIPAL_WRITE_OFF_AMT)){
                                        iterObl.DPD_in_Tradeline__c = 'Yes';
                                        if(dpdReason!= null && dpdReason!= ''){
                                            dpdReason = dpdReason + ', Written Off Principal Amount - '+iterAccount.PRINCIPAL_WRITE_OFF_AMT;
                                        }else {
                                            dpdReason = 'Written Off Principal Amount - '+iterAccount.PRINCIPAL_WRITE_OFF_AMT;
                                        }                                    
                                    }else if(String.isNotBlank(iterAccount.SETTLEMENT_AMT)){
                                        iterObl.DPD_in_Tradeline__c = 'Yes';
                                        if(dpdReason!= null && dpdReason!= ''){
                                            dpdReason = dpdReason + ', Settlement Amount - '+iterAccount.SETTLEMENT_AMT;
                                        }else {
                                            dpdReason = 'Settlement Amount - '+iterAccount.SETTLEMENT_AMT;
                                        }                                    
                                    }else{
                                        iterObl.DPD_in_Tradeline__c = 'No';
                                    }
                                    }
                                    iterObl.DPD_Reason__c = dpdReason;
                                    iterObl.Secured_Unsecured__c = acctTypeToMetaMap.containsKey(acctTypeKey) ? acctTypeToMetaMap.get(acctTypeKey).Secured_Unsecured__c : null;

                                    String dateReportedStr = String.isNotBlank(iterAccount.REPORTED_DT) ? iterAccount.REPORTED_DT : '';
                                        if (String.isNotBlank(dateReportedStr)) {
                                            List<String> parts = dateReportedStr.split('-');
                                            if (parts.size() == 3) {
                                                String day = parts[0];
                                                String mon = parts[1];
                                                String year = parts[2];
                                                iterObl.Reported_Date__c = Date.valueOf(year + '-' + mon + '-' + day);
                                            }
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
                            if(lstToBeRemoved.size() > 0) {
                                delete lstToBeRemoved;
                            }
                            if(bureauLstToInsert.size() > 0) {
                              insert bureauLstToInsert;
                            }

                            system.debug('loanId322--'+loanId);
                            system.debug('lapplicantId322--'+applicantId);
                            system.debug('type--'+ objRecords.CIR_REPORT_FILE.REQUEST_DATA.APPLICANT_SEGMENT.IDS[0].TYPE);

                             List<Triangulation_Data__c> crifTriangulDataLst = [SELECT Id, PAN__c, Mobile_Number__c, Date_Of_Birth__c FROM Triangulation_Data__c 
                                                                        WHERE Loan_Application__c =: loanId AND Application_Applicant__c =: applicantId 
                                                                        AND Document_Type__c = 'PAN' AND Source_Type__c = 'CRIF'];
                        

                            String idType = objRecords.CIR_REPORT_FILE.REQUEST_DATA.APPLICANT_SEGMENT.IDS[0].TYPE;
                            String idValue = objRecords.CIR_REPORT_FILE.REQUEST_DATA.APPLICANT_SEGMENT.IDS[0].VALUE;
                            String documentType = (idType == 'ID07') ? 'PAN' : (idType == 'ID04') ? 'AADHAAR' : 'OTHER';

                            if (!crifTriangulDataLst.isEmpty()) {
                                Triangulation_Data__c triangulationData = crifTriangulDataLst[0];
                                if (idType == 'ID07') {
                                    triangulationData.PAN__c = idValue;
                                } else if (idType == 'ID04') {
                                    triangulationData.Aadhar__c = idValue;
                                }
                                triangulationData.Mobile_Number__c = objRecords.CIR_REPORT_FILE.REQUEST_DATA.APPLICANT_SEGMENT.PHONES[0].VALUE;
                               String dobStr = objRecords.CIR_REPORT_FILE.REQUEST_DATA.APPLICANT_SEGMENT.DOB.DOB_DT;
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
                                if (idType == 'ID07') {
                                    triangulationData.PAN__c = idValue;
                                } else if (idType == 'ID04') {
                                    triangulationData.Aadhar__c = idValue;
                                }
                                triangulationData.Mobile_Number__c = objRecords.CIR_REPORT_FILE.REQUEST_DATA.APPLICANT_SEGMENT.PHONES[0].VALUE;
                                String dobStr = String.valueOf(objRecords.CIR_REPORT_FILE.REQUEST_DATA.APPLICANT_SEGMENT.DOB.DOB_DT);
                                if(dobStr != null && dobStr.length() == 8){
                                    String day = dobStr.substring(0,2);
                                    String mon = dobStr.substring(2,4);
                                    String year = dobStr.substring(4,8);
                                    dobStr = year+'-'+mon+'-'+day;
                                    triangulationData.Date_of_Birth__c = dobStr;
                                }
                                triangulationData.Document_Type__c = documentType;
                                triangulationData.Source_Type__c = 'CRIF';
                                triangulationData.Loan_Application__c = loanId;
                                triangulationData.Application_Applicant__c = applicantId;
                                insert triangulationData;
                            }

                            Application_Applicant__c appdet = new Application_Applicant__c();
                            Decimal crfiScore = 0;
                            if (objRecords != null && objRecords.CIR_REPORT_FILE != null && objRecords.CIR_REPORT_FILE.REPORT_DATA != null && objRecords.CIR_REPORT_FILE.REPORT_DATA.STANDARD_DATA != null
                                && objRecords.CIR_REPORT_FILE.REPORT_DATA.STANDARD_DATA.SCORE != null && !objRecords.CIR_REPORT_FILE.REPORT_DATA.STANDARD_DATA.SCORE.isEmpty() && objRecords.CIR_REPORT_FILE.REPORT_DATA.STANDARD_DATA.SCORE[0].VALUE != null) {
                                    
                                    String cibilScoreValue = objRecords.CIR_REPORT_FILE.REPORT_DATA.STANDARD_DATA.SCORE[0].VALUE;
                                        System.debug('CIBIL Score Value: ' + cibilScoreValue);

                                    crfiScore = (cibilScoreValue != null && cibilScoreValue != '') ? Decimal.valueOf(cibilScoreValue) : null;
                                }
                             appdet.Cibil_Score__c = crfiScore;
                             appDet.id = applicantId;
                                    update appdet;
                                    integrationDetail.Status__c =  String.valueof(resp.getStatusCode());
                        integrationDetail.Name =processName ;
                        integrationDetail.Object_Name__c = 'Application_Applicant__c';
                        integrationDetail.Loan_Application__c = loanId;
                        integrationDetail.Related_Record_Id__c = applicantId;
                        integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                        integrationDetail.Request_JSON__c = respWrapper.payload; 
                        returnResp = JSON.serialize(objRecords);
                    }else{
                        integrationDetail.Status__c = String.valueof(resp.getStatusCode());
                        integrationDetail.Name ='Loan Crif Error' ;
                        integrationDetail.Object_Name__c = 'Application_Applicant__c';
                        integrationDetail.Loan_Application__c = loanId;
                        integrationDetail.Related_Record_Id__c = applicantId;
                        integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                        integrationDetail.Request_JSON__c = respWrapper.payload; 
                        integrationDetail.Response_JSON__c = resp.getBody();
                        
                       returnResp = 'Error:';
                    }
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
                       
                        integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                        integrationDetail.Name =processName ;
                        integrationDetail.Object_Name__c = 'Application_Applicant__c';
                        integrationDetail.Loan_Application__c = loanId;
                        integrationDetail.Related_Record_Id__c = applicantId;
                        integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                        integrationDetail.Request_JSON__c = respWrapper.payload; 
                        integrationDetail.Response_JSON__c = resp.getBody(); 
                        returnResp = 'Error:';
                    }
            
                insert integrationDetail;
                return returnResp; 
            }
            }
            catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
            return null;
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

    public static String replaceHyphensBetweenLetters(String input) {
        Integer chunkSize = 5000;  // Tune this size based on your testing and limits
        Integer len = input.length();
        List<String> updatedChunks = new List<String>();

        for (Integer i = 0; i < len; i += chunkSize) {
            Integer endString = Math.min(i + chunkSize, len);
            String chunk = input.substring(i, endString);

            // Replace only hyphens between letters with underscore
            String updatedChunk = chunk.replaceAll('([A-Za-z])\\-([A-Za-z])', '$1_$2');

            updatedChunks.add(updatedChunk);
        }

        return String.join(updatedChunks, '');
    }

    public static void storeCrifHtmlReport(String contentId, Id applicantId, Id loanId) {
        Document_Master__c docMaster = [SELECT Id FROM Document_Master__c WHERE Name = 'CRIF' LIMIT 1];

        if (docMaster != null) {

            ContentVersion insertedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentId LIMIT 1];

            Document_Details__c crifDoc = new Document_Details__c();
            crifDoc.Applicant__c = applicantId;
            crifDoc.Document_Master__c = docMaster.Id;
            crifDoc.Content_Document_Id__c = insertedVersion.ContentDocumentId;
            crifDoc.Loan_Application__c = loanId;
            crifDoc.Remarks__c = 'This document is created at draft stage when we hit the CRIF.';
            crifDoc.Name = 'CRIF';
            crifDoc.Status__c = 'Uploaded';
            insert crifDoc;

            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = crifDoc.Id;
            cdl.ContentDocumentId = insertedVersion.ContentDocumentId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;

            System.debug('CRIF Response stored successfully.');
        } else {
            System.debug('Document Master record not found for CRIF.');
        }
    }

    public static void storeCrifFullResponseAsFile(String fullResponse, Id applicantId, Id loanId) {
        Document_Master__c docMaster = [SELECT Id FROM Document_Master__c WHERE Name = 'CRIF' LIMIT 1];

        if (docMaster != null) {
            // Create ContentVersion (File)
            ContentVersion content = new ContentVersion();
            content.Title = 'CRIF_Full_Response.txt';
            content.PathOnClient = 'CRIF_Full_Response.txt';
            content.VersionData = Blob.valueOf(fullResponse);
            content.IsMajorVersion = true;
            insert content;

            // Fetch ContentDocumentId
            ContentVersion insertedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id LIMIT 1];

            // Create Document Details record
            Document_Details__c checklist = new Document_Details__c();
            checklist.Applicant__c = applicantId;
            checklist.Document_Master__c = docMaster.Id;
            checklist.Content_Document_Id__c = insertedVersion.ContentDocumentId;
            checklist.Loan_Application__c = loanId;
            checklist.Name = 'CRIF Response';
            checklist.Status__c = 'Uploaded'; 
            insert checklist;

            // Link the document to the checklist record
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = checklist.Id;
            cdl.ContentDocumentId = insertedVersion.ContentDocumentId;
            cdl.ShareType = 'V'; 
            cdl.Visibility = 'AllUsers';
            insert cdl;

            System.debug('CRIF full response stored successfully.');
        } else {
            System.debug('Document Master record not found for CRIF.');
            }
    }

     @AuraEnabled
    public static Boolean checkApplicantAddress( String applicantId){
        Boolean res= false;
        try {
            List<Application_Applicant__c> applicantList= [SELECT Id, Pincode__c, Applicant_Type__c, Loan_Application__c FROM Application_Applicant__c WHERE Id = :applicantId];
            List<Applicant_Address__c> applicantAddress = [SELECT Id, Pincode__c
                                                           FROM Applicant_Address__c 
                                                           WHERE Applicant__c = :applicantId
                                                           AND Address_Type__c != 'BSA'];
            if(applicantList.size()>0){
                if(applicantList[0].Applicant_Type__c == 'Primary Applicant'){
                    return true;
                }else {
                    if(applicantAddress.size()>0){
                        system.debug('519---');
                        if(applicantAddress[0].Pincode__c!= null ){
                            system.debug('521---');
                            res= true;
                        }else {
                            system.debug('524---');
                            res= false;
                        }
                    }else {
                        system.debug('528---');
                        if(applicantList[0].Pincode__c!= null){
                            system.debug('530---');
                            Applicant_Address__c appAdd = new Applicant_Address__c();
                            appAdd.Applicant__c = applicantId;
                            appAdd.Loan_Application__c = applicantList[0].Loan_Application__c;
                            appAdd.Pincode__c = applicantList[0].Pincode__c;
                            appAdd.Address_Type__c = 'Current';
                            insert appAdd;
                            res= true;
                        }
                    }
                    system.debug('540---'+res);
                     system.debug('540---'+applicantList[0].Pincode__c);
                   /* if(res){
                        if(applicantList[0].Pincode__c!= null ){
                            res= true;
                        }else {
                            res = false;
                        }
                    }*/
                    system.debug('548---'+res);
                    
                }
                
            }
        } catch (Exception e) {
            // throw new AuraHandledException(e.getMessage());
        }

        return res;
    }


   public class CRIFResponseWrapper {
        public cls_CIR_REPORT_FILE CIR_REPORT_FILE;
    }

    public class cls_CIR_REPORT_FILE {
        public cls_HEADER_SEGMENT HEADER_SEGMENT;
        public cls_REQUEST_DATA REQUEST_DATA;
        public cls_REQUEST_STATUS[] REQUEST_STATUS;
        public cls_REPORT_DATA REPORT_DATA;
       public cls_SalesforceDetails SalesforceDetails;
    }

    public class cls_HEADER_SEGMENT {
        public String DATE_OF_REQUEST;
        public String PREPARED_FOR;
        public String PREPARED_FOR_ID;
        public String DATE_OF_ISSUE;
        public String REPORT_ID;
        public String BATCH_ID;
        public String STATUS;
        public String PRODUCT_TYPE;
        public String PRODUCT_VER;
    }

    public class cls_REQUEST_DATA {
        public cls_APPLICANT_SEGMENT APPLICANT_SEGMENT;
        public cls_APPLICATION_SEGMENT APPLICATION_SEGMENT;
    }

    public class cls_APPLICANT_SEGMENT {
        public String FIRST_NAME;
        public String MIDDLE_NAME;
        public String LAST_NAME;
        public String FATHER;
        public String HUSBAND;
        public String MOTHER;
        public String SON;
        public String DAUGHTER;
        public String WIFE;
        public String BROTHER;
        public String MOTHER_IN_LAW;
        public String FATHER_IN_LAW;
        public String DAUGHTER_IN_LAW;
        public String SISTER_IN_LAW;
        public String SON_IN_LAW;
        public String BROTHER_IN_LAW;
        public String GENDER;
        public String APPLICANT_ID;
        public cls_DOB DOB;
        public cls_IDS[] IDS;
        public cls_ADDRESSES[] ADDRESSES;
        public cls_PHONES[] PHONES;
        public cls_EMAILS[] EMAILS;
        public String ACCOUNT_NUMBER;
    }

    public class cls_DOB {
        public String DOB_DT;
        public String AGE;
        public String AGE_AS_ON;
    }

    public class cls_IDS {
        public String TYPE;
        public String VALUE;
    }

    public class cls_ADDRESSES {
        public String TYPE;
        public String ADDRESSTEXT;
        public String CITY;
        public String LOCALITY;
        public String STATE;
        public String PIN;
        public String COUNTRY;
    }

    public class cls_PHONES {
        public String TYPE;
        public String VALUE;
    }

    public class cls_EMAILS {
        public String EMAIL;
    }

    public class cls_APPLICATION_SEGMENT {
        public String INQUIRY_UNIQUE_REF_NO;
        public String CREDIT_RPT_ID;
        public String CREDIT_RPT_TRN_DT_TM;
        public String CREDIT_INQ_PURPS_TYPE;
        public String CREDIT_INQUIRY_STAGE;
        public String CLIENT_CONTRIBUTOR_ID;
        public String BRANCH_ID;
        public String APPLICATION_ID;
        public String ACNT_OPEN_DT;
        public String LOAN_AMT;
        public String LTV;
        public String TERM;
        public String LOAN_TYPE;
    }

    public class cls_REQUEST_STATUS {
        public String TYPE;
        public String STATUS;
        public cls_ERRORS[] ERRORS;
    }

    public class cls_ERRORS {
    }

    public class cls_REPORT_DATA {
        public cls_STANDARD_DATA STANDARD_DATA;
        public cls_REQUESTED_SERVICES[] REQUESTED_SERVICES;
        public cls_ACCOUNTS_SUMMARY ACCOUNTS_SUMMARY;
    }

    public class cls_STANDARD_DATA {
        public cls_DEMOGS DEMOGS;
        public cls_TRADELINES[] TRADELINES;
        public cls_INQUIRY_HISTORY[] INQUIRY_HISTORY;
        public cls_SCORE[] SCORE;
    }

    public class cls_DEMOGS {
        public cls_VARIATIONS[] VARIATIONS;
    }

    public class cls_VARIATIONS {
        public String TYPE;
        public cls_VARIATION[] VARIATION;
    }

    public class cls_VARIATION {
        public String VALUE;
        public String REPORTED_DT;
        public String FIRST_REPORTED_DT;
        public String LOAN_TYPE_ASSOC;
        public String SOURCE_INDICATOR;
    }

    public class cls_TRADELINES {
        public String ACCT_NUMBER;
        public String CREDIT_GRANTOR;
        public String CREDIT_GRANTOR_GROUP;
        public String CREDIT_GRANTOR_TYPE;
        public String ACCT_TYPE;
        public String REPORTED_DT;
        public String OWNERSHIP_TYPE;
        public String ACCOUNT_STATUS;
        public String CLOSED_DT;
        public String DISBURSED_AMT;
        public String DISBURSED_DT;
        public String INSTALLMENT_AMT;
        public String CREDIT_LIMIT;
        public String CASH_LIMIT;
        public String CURRENT_BAL;
        public String INSTALLMENT_FREQUENCY;
        public Integer ORIGINAL_TERM;
        public Integer TERM_TO_MATURITY;
        public String REPAYMENT_TENURE;
        public String INTEREST_RATE;
        public String ACTUAL_PAYMENT;
        public String LAST_PAYMENT_DT;
        public String OVERDUE_AMT;
        public String WRITE_OFF_AMT;
        public String PRINCIPAL_WRITE_OFF_AMT;
        public String SETTLEMENT_AMT;
        public String OBLIGATION;
        public cls_HISTORY[] HISTORY;
        public String ACCOUNT_REMARKS;
        public String SECURITY_STATUS;
        public String ACCT_IN_DISPUTE;
        public String SUIT_FILED_WILFUL_DEFAULT_STATUS;
        public String WRITTEN_OFF_SETTLED_STATUS;
        public cls_SECURITY_DETAILS[] SECURITY_DETAILS;
        public cls_LINKED_ACCOUNTS[] LINKED_ACCOUNTS;
        public String SUIT_FILED_DT;
        public String LAST_PAID_AMOUNT;
    }

    public class cls_HISTORY {
        public String NAME;
        public String DATES;
        public String VALUES;
    }

    public class cls_SECURITY_DETAILS {
        public String SECURITY_TYPE;
        public String OWNER_NAME;
        public String SECURITY_VALUATION;
        public String DATE_OF_VALUATION;
        public String SECURITY_CHARGE;
        public String PROPERTY_ADDRESS;
        public String AUTOMOBILE_TYPE;
        public String YEAR_OF_MANUFACTURING;
        public String REGISTRATION_NUMBER;
        public String ENGINE_NUMBER;
        public String CHASSIE_NUMBER;
    }

    public class cls_LINKED_ACCOUNTS {
    }

    public class cls_INQUIRY_HISTORY {
        public String LENDER_NAME;
        public String LENDER_TYPE;
        public String INQUIRY_DT;
        public String OWNERSHIP_TYPE;
        public String CREDIT_INQ_PURPS_TYPE;
        public String CREDIT_INQUIRY_STAGE;
        public String AMOUNT;
        public String LOAN_TYPE;
    }

    public class cls_SCORE {
        public String NAME;
        public String VERSION;
        public String VALUE;
        public String DESCRIPTION;
    }

    public class cls_FACTORS {
    }

    public class cls_REQUESTED_SERVICES {
        public String REQUEST_SERVICES_TYPE;
        public String STATUS;
        public String DESCRIPTION;
        public cls_SCORE SCORE;
        public cls_REMARKS REMARKS;
    }

    public class cls_REMARKS {
        public cls_REMARK[] REMARK;
    }

    public class cls_REMARK {
    }

    public class cls_ACCOUNTS_SUMMARY {
        public cls_PRIMARY_ACCOUNTS_SUMMARY PRIMARY_ACCOUNTS_SUMMARY;
        public cls_SECONDARY_ACCOUNTS_SUMMARY SECONDARY_ACCOUNTS_SUMMARY;
        public cls_MFI_GROUP_ACCOUNTS_SUMMARY MFI_GROUP_ACCOUNTS_SUMMARY;
        public cls_ADDITIONAL_SUMMARY[] ADDITIONAL_SUMMARY;
    }

    public class cls_PRIMARY_ACCOUNTS_SUMMARY {
        public String NUMBER_OF_ACCOUNTS;
        public String ACTIVE_ACCOUNTS;
        public String OVERDUE_ACCOUNTS;
        public String SECURED_ACCOUNTS;
        public String UNSECURED_ACCOUNTS;
        public String UNTAGGED_ACCOUNTS;
        public String TOTAL_CURRENT_BALANCE;
        public String TOTAL_SANCTIONED_AMT;
        public String TOTAL_DISBURSED_AMT;
        public String TOTAL_AMT_OVERDUE;
    }

    public class cls_SECONDARY_ACCOUNTS_SUMMARY {
        public String NUMBER_OF_ACCOUNTS;
        public String ACTIVE_ACCOUNTS;
        public String OVERDUE_ACCOUNTS;
        public String SECURED_ACCOUNTS;
        public String UNSECURED_ACCOUNTS;
        public String UNTAGGED_ACCOUNTS;
        public String TOTAL_CURRENT_BALANCE;
        public String TOTAL_SANCTIONED_AMT;
        public String TOTAL_DISBURSED_AMT;
        public String TOTAL_AMT_OVERDUE;
    }

    public class cls_MFI_GROUP_ACCOUNTS_SUMMARY {
        public String NUMBER_OF_ACCOUNTS;
        public String ACTIVE_ACCOUNTS;
        public String OVERDUE_ACCOUNTS;
        public String CLOSED_ACCOUNTS;
        public String NO_OF_OTHER_MFIS;
        public String NO_OF_OWN_MFIS;
        public String TOTAL_OWN_CURRENT_BALANCE;
        public String TOTAL_OWN_INSTALLMENT_AMT;
        public String TOTAL_OWN_DISBURSED_AMT;
        public String TOTAL_OWN_OVERDUE_AMT;
        public String TOTAL_OTHER_CURRENT_BALANCE;
        public String TOTAL_OTHER_INSTALLMENT_AMT;
        public String TOTAL_OTHER_DISBURSED_AMT;
        public String TOTAL_OTHER_OVERDUE_AMT;
        public String MAX_WORST_DELINQUENCY;
    }

    public class cls_ADDITIONAL_SUMMARY {
        public String ATTR_NAME;
        public String ATTR_VALUE;
    }

    public class cls_SalesforceDetails {
        public cls_Response Response;
    }

    public class cls_Response {
        public String id; 
    }
}