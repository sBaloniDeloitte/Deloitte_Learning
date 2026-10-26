public with sharing class HunterController {


    @AuraEnabled
    public static String initiateHunter(Map<String, String> inputMap) {
        try {
            String resultMessage;
            String loanId = inputMap.get('recordId');
            String processName = inputMap.get('processName');  
            
            //
            Integration_Details__c integrationDetail = new Integration_Details__c();
            integrationDetail.Calling_Source__c = processName; 
            integrationDetail.Request_JSON__c = 'tst resquest';
            integrationDetail.Response_JSON__c = 'test response';
            integrationDetail.Status__c = String.valueof('200'); 
            integrationDetail.Method_Type__c = 'POST';
            integrationDetail.EndPoint__c = 'NA';
            integrationDetail.Object_Name__c = 'Application_Applicant__c';
            integrationDetail.Name = 'Loan Applicant Hunter'; 
            integrationDetail.Loan_Application__c = loanId;
            resultMessage = 'Success';
            insert integrationDetail;
            
            String overallDecision = 'ACCEPT'; 
            String match = 'YES';
            String responseMessage = 'Decision: ' + overallDecision;
            
            List<Application_Applicant__c> appApplicantsOnLoan = [SELECT Id, First_Name__c, Last_Name__c, Applicant_Type__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId AND Applicant_Type__c != 'Guarantor'];
            
            String primaryApplicant = '';
            String secondaryApplicant = '';
            Id applicant;
            
            for (Application_Applicant__c iterApplicant : appApplicantsOnLoan) {
                if (iterApplicant.Applicant_Type__c == 'Primary Applicant') {
                    primaryApplicant = iterApplicant.First_Name__c + ' ' + (iterApplicant.Last_Name__c != null ? iterApplicant.Last_Name__c : '');
                    applicant = iterApplicant.Id;
                }
                
                if (iterApplicant.Applicant_Type__c == 'Co Applicant' && (secondaryApplicant == null || secondaryApplicant == '')) {
                    secondaryApplicant = iterApplicant.First_Name__c + ' ' + (iterApplicant.Last_Name__c != null ? iterApplicant.Last_Name__c : '');
                } else if (iterApplicant.Applicant_Type__c == 'Co Applicant' && (secondaryApplicant != null || secondaryApplicant != '')) {
                    secondaryApplicant = secondaryApplicant + ',' + iterApplicant.First_Name__c + ' ' + (iterApplicant.Last_Name__c != null ? iterApplicant.Last_Name__c : '');
                }
            }
            
            String hunterRecordType = Constants__mdt.getInstance('Hunter_Record').Value__c;
            List<Application_Verification__c> existingVerification = [SELECT id, Hunter_Decision__c, Hunter_Match__c FROM Application_Verification__c WHERE Loan_Application__c = :loanId AND RecordTypeId = :hunterRecordType LIMIT 1];
            
            if (existingVerification.isEmpty()) {
                Application_Verification__c verificationRecord = new Application_Verification__c();
                verificationRecord.RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' AND Name = 'Hunter Verification' LIMIT 1].Id;
                verificationRecord.Loan_Application__c =loanId;
                verificationRecord.Primary_Applicant__c = primaryApplicant;
                verificationRecord.Co_Applicant_s__c = secondaryApplicant;
                verificationRecord.Hunter_Decision__c = overallDecision;
                verificationRecord.Hunter_Match__c = match; 
                verificationRecord.Applicant__c = applicant;
                verificationRecord.Hunter_Initiated_By__c = UserInfo.getUserId();
                
                insert verificationRecord;
            } else {
                Application_Verification__c verificationRecord = existingVerification[0];
                verificationRecord.Hunter_Decision__c = overallDecision;
                verificationRecord.Hunter_Match__c = match;
                update verificationRecord;
            }
            
            if (overallDecision == 'ACCEPT' && match == 'YES') {
                List<Application_Applicant__c> appList = [SELECT Id, Is_Hunter_Executed__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId];
                for (Application_Applicant__c app : appList) {
                    app.Is_Hunter_Executed__c = true;
                    update app;
                }
            }
            Application_Verification__c verificationRecord = new Application_Verification__c();
            verificationRecord.RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' AND Name = 'Hunter Verification' LIMIT 1].Id;
            verificationRecord.Loan_Application__c =loanId;
            verificationRecord.Primary_Applicant__c = primaryApplicant;
            verificationRecord.Co_Applicant_s__c = secondaryApplicant;
            verificationRecord.Hunter_Decision__c = overallDecision;
            verificationRecord.Hunter_Match__c = match; 
            verificationRecord.Applicant__c = applicant;
            verificationRecord.Hunter_Initiated_By__c = UserInfo.getUserId();
            
            insert verificationRecord;
            
            
            //
            /*
            intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
            wrapper.recordId = loanId;
            wrapper.loanApplicationId = loanId;  
            wrapper.type = processName;
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Integration_Settings__c> intSettingList = [
                SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c 
                FROM Integration_Settings__c 
                WHERE Name = 'Loan Applicant Hunter' LIMIT 1
            ];
            
            Integration_Settings__c intSetting = intSettingList[0];   
            
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                // Collect all validation errors and send back to JS
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = 'HunterInitiation';
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                resultMessage = String.join(respWrapper.prerequisiteError, ', '); 
            } else {
                string reqStr = respWrapper.payload.replaceAll('"numberval"','"number"');
                system.debug('check-->'+reqStr);
                Map<String, String> integrationRequestMap = new Map<String, String>();
                integrationRequestMap.put('intSettingName', 'Loan Applicant Hunter');
                integrationRequestMap.put('requestJSON', reqStr);
                String bearer = Utility.getAccessToken();
                System.debug('bearer----' + bearer);
                integrationRequestMap.put('bearer', bearer);
                
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                
                if (resp.getStatusCode() == 200) {
                    HunterResponseWrapper response = (HunterResponseWrapper)JSON.deserialize(resp.getBody(), HunterResponseWrapper.class);
                    if (response.responseHeader.responseCode == 'R0201') {
                        integrationDetail.Calling_Source__c = processName; 
                        integrationDetail.Request_JSON__c = reqStr;//respWrapper.payload; 
                        integrationDetail.Response_JSON__c = JSON.serialize(response); 
                         integrationDetail.Status__c = String.valueof('200'); 
                        integrationDetail.Method_Type__c = intSetting.Request_Method__c; 
                        integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                        integrationDetail.Object_Name__c = 'Application_Applicant__c';
                        integrationDetail.Name = 'Loan Applicant Hunter'; 
                        integrationDetail.Loan_Application__c = loanId;
                        resultMessage = 'Success';
                    } else if (response.responseHeader.responseCode != 'RO201') {
                        integrationDetail.Status__c = '412';
                        integrationDetail.Response_JSON__c = resp.getBody();
                        integrationDetail.Name = 'Loan Applicant Hunter';
                        integrationDetail.Object_Name__c = 'Application_Applicant__c';
                        integrationDetail.Prerequisite__c = response.responseHeader.responseMessage;
                        resultMessage = response.responseHeader.responseMessage;
                    }
                    
                    String overallDecision = response.responseHeader.overallResponse.decision;  
                    String match = response.responseHeader.overallResponse.match;   
                    String responseMessage = 'Decision: ' + overallDecision;
                    
                    List<Application_Applicant__c> appApplicantsOnLoan = [SELECT Id, First_Name__c, Last_Name__c, Applicant_Type__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId AND Applicant_Type__c != 'Guarantor'];
                    
                    String primaryApplicant = '';
                    String secondaryApplicant = '';
                    Id applicant;
                    
                    for (Application_Applicant__c iterApplicant : appApplicantsOnLoan) {
                        if (iterApplicant.Applicant_Type__c == 'Primary Applicant') {
                            primaryApplicant = iterApplicant.First_Name__c + ' ' + (iterApplicant.Last_Name__c != null ? iterApplicant.Last_Name__c : '');
                            applicant = iterApplicant.Id;
                        }
    
                        if (iterApplicant.Applicant_Type__c == 'Co Applicant' && (secondaryApplicant == null || secondaryApplicant == '')) {
                            secondaryApplicant = iterApplicant.First_Name__c + ' ' + (iterApplicant.Last_Name__c != null ? iterApplicant.Last_Name__c : '');
                        } else if (iterApplicant.Applicant_Type__c == 'Co Applicant' && (secondaryApplicant != null || secondaryApplicant != '')) {
                            secondaryApplicant = secondaryApplicant + ',' + iterApplicant.First_Name__c + ' ' + (iterApplicant.Last_Name__c != null ? iterApplicant.Last_Name__c : '');
                        }
                    }
    
                    String hunterRecordType = Constants__mdt.getInstance('Hunter_Record').Value__c;
                    List<Application_Verification__c> existingVerification = [SELECT id, Hunter_Decision__c, Hunter_Match__c FROM Application_Verification__c WHERE Loan_Application__c = :loanId AND RecordTypeId = :hunterRecordType LIMIT 1];
                    
                    if (existingVerification.isEmpty()) {
                        Application_Verification__c verificationRecord = new Application_Verification__c();
                        verificationRecord.RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' AND Name = 'Hunter Verification' LIMIT 1].Id;
                        verificationRecord.Loan_Application__c =loanId;
                        verificationRecord.Primary_Applicant__c = primaryApplicant;
                        verificationRecord.Co_Applicant_s__c = secondaryApplicant;
                        verificationRecord.Hunter_Decision__c = overallDecision;
                        verificationRecord.Hunter_Match__c = match; 
                        verificationRecord.Applicant__c = applicant;
                        verificationRecord.Hunter_Initiated_By__c = UserInfo.getUserId();
    
                        insert verificationRecord;
                    } else {
                        Application_Verification__c verificationRecord = existingVerification[0];
                        verificationRecord.Hunter_Decision__c = overallDecision;
                        verificationRecord.Hunter_Match__c = match;
                        update verificationRecord;
                    }
    
                    if (overallDecision == 'ACCEPT' && match == 'YES') {
                        List<Application_Applicant__c> appList = [SELECT Id, Is_Hunter_Executed__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId];
                        for (Application_Applicant__c app : appList) {
                            app.Is_Hunter_Executed__c = true;
                            update app;
                        }
                    }
                } else {
                    integrationDetail.Calling_Source__c = processName; 
                    integrationDetail.Request_JSON__c = respWrapper.payload; 
                    //integrationDetail.Response_JSON__c = JSON.serialize(resp); 
                    integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
                    integrationDetail.Method_Type__c = intSetting.Request_Method__c; 
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Name = 'Loan Applicant Hunter'; 
                    integrationDetail.Loan_Application__c = loanId;
                    resultMessage = 'Error: ' + resp.getStatus() ;
                }
                
                insert integrationDetail;
            }
    		*/
            return resultMessage;
    
        } catch (Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'HunterInititation', '', '') });
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    

    public class HunterResponseWrapper {
        public ResponseHeader responseHeader { get; set; }
        public ClientResponsePayload clientResponsePayload { get; set; }
    }
    
        public class ResponseHeader {
            public String requestType { get; set; }
            public String clientReferenceId { get; set; }
            public String expRequestId { get; set; }
            public String messageTime { get; set; }
            public OverallResponse overallResponse { get; set; }
            public String responseCode { get; set; }
            public String responseType { get; set; }
            public String responseMessage { get; set; }
            public String tenantID { get; set; }
        }
    
        public class OverallResponse {
            public String decision { get; set; }
            public Integer score { get; set; }
            public String decisionText { get; set; }
            public List<String> decisionReasons { get; set; }
            public List<String> recommendedNextActions { get; set; }
            public List<String> spareObjects { get; set; }
            public String match { get; set; }
        }
    
        public class ClientResponsePayload {
            public List<OrchestrationDecision> orchestrationDecisions { get; set; }
            public List<DecisionElement> decisionElements { get; set; }
        }
    
        public class OrchestrationDecision {
            public String sequenceId { get; set; }
            public String decisionSource { get; set; }
            public String decision { get; set; }
            public Integer score { get; set; }
            public String decisionText { get; set; }
            public String nextAction { get; set; }
            public String appReference { get; set; }
        }
    
        public class DecisionElement {
            public String serviceName { get; set; }
            public Integer score { get; set; }
            public String appReference { get; set; }
            public List<Rule> rules { get; set; }
            public List<WarningError> warningsErrors { get; set; }
            public OtherData otherData { get; set; }
        }
    
        public class Rule {
            public String ruleId { get; set; }
            public String ruleName { get; set; }
            public Integer ruleScore { get; set; }
            public String ruleText { get; set; }
        }
    
        public class WarningError {
            public String responseType { get; set; }
            public String responseCode { get; set; }
            public String responseMessage { get; set; }
        }
    
        public class OtherData {
            public MatchSummary matchSummary { get; set; }
        }
    
        public class MatchSummary {
            public String totalMatchScore { get; set; }
            public List<RuleData> rules { get; set; }
            public MatchSchemes matchSchemes { get; set; }
            public Integer matches { get; set; }
        }
    
        public class RuleData {
            public String ruleID { get; set; }
            public Integer score { get; set; }
            public Integer ruleCount { get; set; }
            public Integer isGlobal { get; set; }
        }
    
        public class MatchSchemes {
            public List<Scheme> scheme { get; set; }
        }
    
        public class Scheme {
            public String schemeID { get; set; }
            public Integer score { get; set; }
        }
        @AuraEnabled
        public static void createdocument(Map<String, String> documentMap){
            try {          
                        string loanid ; 
                        List<RecordType> recordtypeid;
                        if (!documentMap.isEmpty()) {
                            loanId = documentMap.keySet().iterator().next();
                            system.debug('loanid--'+loanId);
                        }
                        recordtypeid = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' AND Name = 'Hunter Verification' Limit 1];
                        system.debug('record type id--'+recordtypeid);
                        List<Application_Verification__c> hunterverification = [SELECT Id, Document_Detail__c, Document_Detail__r.Content_Document_Id__c,Hunter_Document__c,Sampler_Name__c,Integration_Report__c  FROM Application_Verification__c WHERE  Loan_Application__c =: loanId and RecordTypeId =: recordtypeid];
                        system.debug('app records-->'+hunterverification);
                        List<Document_Details__c> newDocumentDetails = new List<Document_Details__c>();
                        for (Application_Verification__c hunterverificationlist : hunterverification) {
                        Document_Details__c newDocDetail = new Document_Details__c();
                        newDocDetail.Content_Document_Id__c = documentMap.get(loanid);
                        newDocDetail.Application_Verification__c = hunterverificationlist.Id; 
                        newDocDetail.name = 'Hunter Attachment';
                        newDocumentDetails.add(newDocDetail);
    
            if (!newDocumentDetails.isEmpty()) {
                insert newDocumentDetails;
                
                // After inserting, link the ContentVersion to ContentDocumentLink and associate it with Document_Details__c
                    ContentDocumentLink contentDocLink = new ContentDocumentLink();
                    contentDocLink.ContentDocumentId = documentMap.get(loanid);
                    contentDocLink.LinkedEntityId = newDocumentDetails[0].id;
                    contentDocLink.ShareType = 'V'; // V for Viewer access
                    contentDocLink.Visibility = 'AllUsers'; // Making it visible to all users
                    insert contentDocLink;
                    system.debug('The id is-->'+hunterverification);
                for (Integer i = 0; i < hunterVerification.size(); i++) {
                    hunterVerification[i].Hunter_Document__c = newDocumentDetails[i].Id;
                    hunterVerification[i].Sampler_Name__c = UserInfo.getUserId();
                }
    
                update hunterVerification;
            }
    
            }
            } catch (Exception e) {
                Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'HunterDocument', '', '') });
                throw new AuraHandledException(e.getMessage());
            }
        }
}