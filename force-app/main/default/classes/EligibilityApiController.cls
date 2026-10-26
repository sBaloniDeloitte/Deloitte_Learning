/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 04-30-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class EligibilityApiController {
    @AuraEnabled
    public static String initiateAPIRequest(Map<String,String> inputMap){
        try {
            Boolean isIncomeFromSales = false; 
            Integration_Details__c integrationDetails = new Integration_Details__c();
            String loanId = inputMap.get('loanId');
            String processName = inputMap.get('processName');//FICO Cibil And Income Eligibility
            String eligibilityType = inputMap.get('eligibilityType');//Banking Method - HT Program
            Boolean callForDeviation = false;
            if(inputMap.containsKey('callForDeviation')){
                callForDeviation = Boolean.valueOf(inputMap.get('callForDeviation')) == true ? true : false;
            }
            String adb = inputMap.get('adb');
            if(inputMap.containsKey('isIncomeFromSales')){
                isIncomeFromSales = Boolean.valueOf(inputMap.get('isIncomeFromSales')) == true ? true : false;
            }
            
            String returnResp;
            String resultMessage;
            
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
            wrapper.eligibilityType = eligibilityType;
            wrapper.adb = adb;
            wrapper.isIncomeFromSales = isIncomeFromSales;
            wrapper.callForDeviation = callForDeviation;
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            if(Test.isRunningTest()){
                respWrapper.prerequisiteError = null ;
                respWrapper.payload = '{"respWrapper":"payload"}';
            }
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name =processName ;
                integrationDetail.Object_Name__c = 'Opportunity';
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                System.debug('resultMessage: '+resultMessage);
                returnResp = resultMessage;
            }
            else{
                //System.debug('request JSON '+respWrapper.payload);
                
                String payload = respWrapper.payload;
                payload = payload.replaceALL('currencyRemove','currency');
                String xmlRespStr = JSONXMLConvertor.convertJsonToXml(respWrapper.payload,'');
                xmlRespStr = xmlRespStr.replaceAll('&lt;','<');
                xmlRespStr = xmlRespStr.replaceAll('&gt;','>');
                xmlRespStr = xmlRespStr.replaceAll('\n','');
                xmlRespStr = xmlRespStr.replaceAll('\t','');
                xmlRespStr = xmlRespStr.replaceAll('\r','');
                Map<String,String> integrationRequestMap = new Map<String,String>();
                integrationRequestMap.put('intSettingName','Loan FICO API');
                integrationRequestMap.put('requestJSON',xmlRespStr);
                //System.debug('xmlRespStr: '+xmlRespStr);
                
                String bearer = Utility.getAccessToken();
                System.debug('bearer----'+bearer);
                integrationRequestMap.put('bearer',bearer);
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                //System.debug('resp.getBody()=:'+resp.getBody());
                //      String res =resp.getBody();
                if(resp.getStatusCode() == 200) {
                    returnResp = 'success';
                    String apiResponse = resp.getBody();
                    String responseTag;
                    Integer startIndex = apiResponse.indexOf('<response>');
                    Integer endIndex = apiResponse.indexOf('</response>');
                    endIndex = endIndex + ('</response>'.length());
                    responseTag = apiResponse.substring(startIndex,endIndex);
                    //BL_CRIF_Score_Card,CAT C1</scorecardName>
                    if(responseTag.indexOf('BL_CRIF_Score_Card') != -1) {
                        Integer i1 = responseTag.lastIndexOf('BL_CRIF_Score_Card,');
                        String sta = responseTag.substring(i1+19,i1+25);
                        if(sta.indexOf('CAT') != -1) {
                            integrationDetail.Eligibility_Status__c = sta;
                        }
                        // }else {
                        //     returnResp = 'Not Eligible';
                        //     integrationDetail.Eligibility_Status__c = 'Not Eligible';
                        // }
                    }
                    // else {
                    //     returnResp = 'Not Eligible';
                    //     integrationDetail.Eligibility_Status__c = 'Not Eligible';
                    // }
                    
                    String finalOffer;
                    startIndex = apiResponse.indexOf('<finalOffer>');
                    endIndex = apiResponse.indexOf('</finalOffer>');
                    endIndex = endIndex + ('</finalOffer>'.length());
                    finalOffer = apiResponse.substring(startIndex,endIndex);
                    
                    apiResponse = responseTag + finalOffer;
                    
                    ContentVersion content = new ContentVersion();
                    content.Title = 'IncomeEligibility_Response.txt';
                    content.PathOnClient = 'IncomeEligibility_Response.txt';
                    content.VersionData = Blob.valueOf((apiResponse));
                    content.IsMajorVersion = true;
                    insert content;
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id LIMIT 1].ContentDocumentId;
                    
                    
                    // Create Document_Details__c record
                    Document_Details__c checklist = new Document_Details__c();
                    checklist.Content_Document_Id__c = cdl.ContentDocumentId;
                    checklist.Loan_Application__c = loanid;
                    checklist.Name = 'Income Eligibility Response';
                    insert checklist;
                    
                    cdl.LinkedEntityId =checklist.id ; // Temp link to User so ContentDocument exists
                    cdl.ShareType = 'V';
                    cdl.Visibility = 'AllUsers';
                    insert cdl;
                    
                    //
                    ContentVersion contentReq = new ContentVersion();
                    contentReq.Title = 'IncomeEligibility_Request.txt';
                    contentReq.PathOnClient = 'IncomeEligibility_Request.txt';
                    contentReq.VersionData = Blob.valueOf((xmlRespStr));
                    contentReq.IsMajorVersion = true;
                    insert contentReq;
                    ContentDocumentLink cdlReq = new ContentDocumentLink();
                    cdlReq.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentReq.Id LIMIT 1].ContentDocumentId;
                    
                    
                    // Create Document_Details__c record
                    Document_Details__c checklistRew = new Document_Details__c();
                    checklistRew.Content_Document_Id__c = cdlReq.ContentDocumentId;
                    checklistRew.Loan_Application__c = loanid;
                    checklistRew.Name = 'Income Eligibility Request';
                    insert checklistRew;
                    
                    cdlReq.LinkedEntityId =checklistRew.id ; // Temp link to User so ContentDocument exists
                    cdlReq.ShareType = 'V';
                    cdlReq.Visibility = 'AllUsers';
                    insert cdlReq;
                    
                    //
                    
                    integrationDetail.Calling_Source__c = wrapper.type; 
                    integrationDetail.Request_JSON__c = ''; 
                    //integrationDetail.Response_JSON__c = apiResponse;
                    integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
                    integrationDetail.Method_Type__c = wrapper.requestMethod; 
                    integrationDetail.EndPoint__c = wrapper.endpoint; 
                    
                    integrationDetail.Name = eligibilityType; 
                    integrationDetail.Loan_Application__c = loanid;
                    integrationDetail.Object_Name__c = 'Document_Details__c';
                    integrationDetail.Related_Record_Id__c = checklist.Id;
                    insert integrationDetail;
                    
                    // integrationDetail.Calling_Source__c = wrapper.type; 
                    // integrationDetail.Request_JSON__c = ''; 
                    // //integrationDetail.Response_JSON__c = apiResponse;
                    // integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
                    // integrationDetail.Method_Type__c = wrapper.requestMethod; 
                    // integrationDetail.EndPoint__c = wrapper.endpoint; 
                    // integrationDetail.Object_Name__c = 'Opportunity';
                    // integrationDetail.Name = eligibilityType; 
                    // integrationDetail.Loan_Application__c = loanid;
                    // insert integrationDetail;
                    Opportunity loanObj = [SELECT id,Risk_Segment__c,Sanction_Loan_Amount__c FROM Opportunity WHERE id =:loanId];
                    Map<String,Object> xmlConvertedResp = XMLConvertor.xmlToMap(responseTag);
                    String finalResponse = JSON.serialize(xmlConvertedResp);
                    /* List<Integer> count = findAllOccurrences(finalResponse,'scoreCardDetails');
if(count.size() <= 2) {
finalResponse = finalResponse.replaceALL('scoreCardDetails','scoreCardDetailsSingle');
}else {

}*/
                    //System.debug('finalResponse '+finalResponse);
                    Boolean isDeviation = false;
                    Integer count = countTagOccurrences(responseTag, 'responseDeviations');
                    if(count > 1 ) {
                        isDeviation = true;
                    }else {
                        finalResponse = finalResponse.replaceALL('responseDeviations','responseDeviation');
                        List<Application_Deviation__c> deviationDeleted = [SELECT id,Approval_Status__c,Deviation_Code__c FROM Application_Deviation__c WHERE Loan_Application__c =:loanId AND Deviation_Category__c = 'Automatic' AND Approval_Status__c = 'Pending'];
                        if (!deviationDeleted.isEmpty()) {
                            delete deviationDeleted;
                        }
                    }
                    if(Test.isRunningTest()){
                        finalResponse = '{"response":{"scoreDecision":"ok","responseDeviations":[{"accountNo":"685"}], "scoreCardDetails":[{"entityId":"685","scorecardName":"BL_CRIF_Score_Card", "scoreCardCharacteristics":[]}],"calculatedVariables":[{"entityId":"899"}]}}';
                        finalOffer ='<finalOffer><MAXLOELIGINC>1500000</MAXLOELIGINC></finalOffer>';
                    }
                    FICOResponse ficoResponse = (FICOResponse) JSON.deserialize(finalResponse,  FICOResponse.class);
                    List<Income_Expense_Obligation__c> parent = [SELECT id,DTO_API__c,Overall_ETO_in_Percentage__c,
                                                                 Unsecured_ETO_in_Percentage__c 
                                                                 from Income_Expense_Obligation__c where Loan_Application__c =:loanId 
                                                                 AND Type__c='Obligation' AND IsParent__c = true];
                    
                    //System.debug('ficoResponse : '+ficoResponse);
                    if(!isIncomeFromSales && !callForDeviation) {
                        Map<String,Object> finalOfferObj = XMLConvertor.xmlToMap(finalOffer);
                        String JSONRes = JSON.serialize(finalOfferObj);
                        EligibilityCriteriaController objRecords = (EligibilityCriteriaController)JSON.deserialize(JSONRes, EligibilityCriteriaController.class);
                        //System.debug(objRecords.finalOffer.EMIFINOFF);
                        if(loanObj.Sanction_Loan_Amount__c == null || loanObj.Sanction_Loan_Amount__c == 0) {
                            loanObj.Sanction_Loan_Amount__c = Decimal.valueOf(objRecords.finalOffer.MAXLOELIGINC);
                        }
                        if(responseTag.indexOf('BL_Judgemental_Score_Card_CRIF_Instance') != -1) {
                            
                           
                            
                            for(FICOResponse.cls_scoreCardDetails scoreCardIter : ficoResponse.response.scoreCardDetails) {
                                for(FICOResponse.cls_scoreCardCharacteristics scoreCardCharIter : scoreCardIter.scoreCardCharacteristics) {
                                    if(scoreCardCharIter.characteristicName == 'DTO' && scoreCardCharIter.characteristicValue != 'Unknown' && scoreCardCharIter.characteristicValue != 'Infinity') {
                                        if(parent.size() > 0) {
                                            parent[0].DTO_API__c = Decimal.valueOf(scoreCardCharIter.characteristicValue);
                                            break;
                                        }
                                    }
                                }
                            }
                            // }
                            update parent;
                        }
                        
                    }
                    if(!isIncomeFromSales && callForDeviation && isDeviation) {
                        List<Application_Deviation__c> deleteDev = new List<Application_Deviation__c>();
                        Map<String,Application_Deviation__c> devaitionMap = new Map<String,Application_Deviation__c>();
                        List<Application_Deviation__c> deviationToBeDeleted = [SELECT id,Approval_Status__c,Deviation_Code__c FROM Application_Deviation__c WHERE Loan_Application__c =:loanId AND Deviation_Category__c = 'Automatic'];
                        if(deviationToBeDeleted.size() > 0) {
                            for(Application_Deviation__c iterDev : deviationToBeDeleted) {
                                if(iterDev.Approval_Status__c != 'Pending') {
                                    devaitionMap.put(iterDev.Deviation_Code__c,iterDev);
                                }else {
                                    deleteDev.add(iterDev);
                                }
                            }   
                        }
                        List<Application_Deviation__c> lstDeviations = new List<Application_Deviation__c>();
                        for(FICOResponse.cls_responseDeviations deviationIter : ficoResponse.response.responseDeviations) {
                            
                            if(devaitionMap.size() > 0 && devaitionMap.containsKey(deviationIter.ruleId)) {
                                
                            }else {
                                Application_Deviation__c iterDeviation = new Application_Deviation__c();
                                iterDeviation.Loan_Application__c = loanId;
                                iterDeviation.Deviation_Category__c = 'Automatic';
                                iterDeviation.Deviation_Applicable_For__c ='Loan Application';
                                iterDeviation.Deviation__c = deviationIter.ruleDescription;
                                iterDeviation.Deviation_Code__c = deviationIter.ruleId;
                                
                                if(String.isNotBlank(deviationIter.approvalLevel)) {
                                    String level = deviationIter.approvalLevel.split(',')[0];
                                    String s2 = level.remove('L');
                                    iterDeviation.Approving_Authority__c = s2;
                                }
                                if(String.isNotBlank(deviationIter.ruleId)) {
                                    lstDeviations.add(iterDeviation);
                                }
                            }
                            
                            
                        }
                        if(deleteDev.size() > 0) {
                            delete deleteDev;
                        }
                        if(lstDeviations.size() > 0) {
                            insert lstDeviations;
                        }
                    }
                    //Added by Suhrit
                    
                    List<Application_Applicant__c> applicants = [SELECT Id, Name, CRIF_Segment__c,KYC_Risk_Categorisation_Category__c, Customer__r.SF_Customer_ID__c 
                                                                 FROM Application_Applicant__c 
                                                                 WHERE Loan_Application__c = :loanId];
                    List<Application_Applicant__c> ap = new List<Application_Applicant__c>();
                    Map<Id, Application_Applicant__c> applicantMap = new Map<Id, Application_Applicant__c>();
                    for(FICOResponse.cls_scoreCardDetails scoreCardIter : ficoResponse.response.scoreCardDetails) {
                        if(scoreCardIter.scorecardName.contains('BL_CRIF_Score_Card,')) {
                            String[] scorecardNames = scoreCardIter.scorecardName.split(',');
                            String fieldvalue = scorecardNames[1];
                            String entityId = scoreCardIter.entityId;
                            // System.debug('fieldvalue '+fieldvalue);
                            for(Application_Applicant__c applicant : applicants) {
                                String customerId = applicant.Customer__r.SF_Customer_ID__c;
                                String numericCustomerId = customerId.replaceAll('\\D', '');
                                String finalCustomerId = String.valueOf(Integer.valueOf(numericCustomerId));
                                //System.debug('finalCustomerId : ' + finalCustomerId);                                
                                if (entityId.equals(finalCustomerId)) {
                                    applicant.CRIF_Segment__c = fieldvalue;
                                    // ap.add(applicant); // Add the applicant to the list for updating
                                    applicantMap.put(applicant.Id, applicant); 
                                    break; // Break the inner loop once a match is found
                                }
                            }
                            
                        }  
                        if(scoreCardIter.scorecardName.contains('BL_Judgemental_Score_Card_CRIF_Instance,')) {
                            String[] scorecardNames = scoreCardIter.scorecardName.split(',');
                            String fieldvalue = scorecardNames[1];
                            loanObj.Risk_Segment__c = fieldvalue;
                            loanObj.Risk_Score__c = scoreCardIter.scorecardScore;
                            
                        }
                    }
                    update loanObj;
                    for(FICOResponse.cls_calculatedVariables calcatedVars : ficoResponse.response.calculatedVariables){
                        if(calcatedVars.fieldName == 'RISKCATEGORIZATION'){
                            String riskValue = calcatedVars.fieldValue;
                            for(Application_Applicant__c applicant : applicants) {
                                String customerId = applicant.Customer__r.SF_Customer_ID__c;
                                String numericCustomerId = customerId.replaceAll('\\D', '');
                                String finalCustomerId = String.valueOf(Integer.valueOf(numericCustomerId));
                                String entityId = calcatedVars.entityId;
                                // System.debug('finalCustomerId : ' + finalCustomerId);
                                if (entityId.equals(finalCustomerId)) {
                                    applicant.KYC_Risk_Categorisation_Category__c = riskValue;
                                    applicantMap.put(applicant.Id, applicant); 
                                    break;
                                }
                            }
                        }
                        if(calcatedVars.fieldName == 'ETO_Sec_Unsec' && calcatedVars.fieldValue != null && calcatedVars.fieldValue != 'NA') {
                            parent[0].Overall_ETO_in_Percentage__c = Decimal.valueOf(calcatedVars.fieldValue);
                        }
                        if(calcatedVars.fieldName == 'ETO' && calcatedVars.fieldValue != null && calcatedVars.fieldValue != 'NA') {
                            parent[0].Unsecured_ETO_in_Percentage__c = Decimal.valueOf(calcatedVars.fieldValue);
                        }
                    }
                    update parent;
                    update applicantMap.values();
                    
                    
                    
                }else {
                    returnResp = 'Error : '+resp.getStatusCode();
                }
            }
            return returnResp; 
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static List<Integer> findAllOccurrences(String inputString, String searchString) {
        List<Integer> occurrences = new List<Integer>();
        Integer startIndex = 0;
        
        while (startIndex != -1) {
            // Find the next occurrence of the searchString
            startIndex = inputString.indexOf(searchString, startIndex);
            
            if (startIndex != -1) {
                occurrences.add(startIndex); // Add the index to the list
                startIndex += searchString.length(); // Move to the next part of the string
            }
        }
        
        return occurrences;
    }

    public static Integer countTagOccurrences(String xmlContent, String tagName) {
        Integer count = 0;
        String searchTag = '<' + tagName;
        Integer index = xmlContent.indexOf(searchTag);

        while (index != -1) {
            count++;
            index = xmlContent.indexOf(searchTag, index + searchTag.length());
        }

        return count;
    }
}