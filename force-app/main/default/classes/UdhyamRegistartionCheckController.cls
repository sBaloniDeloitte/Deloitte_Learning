public with sharing class UdhyamRegistartionCheckController implements DynamicInvoker  {
    static string conLabels = 'Udhyam_Check';
                         
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }

    @AuraEnabled
    public static String createInputMap(Id loanId, String processName, String appId) {
        System.debug('inside createInputMap');
        System.debug('loanId: ' + loanId);
        System.debug('processName: ' + processName);

        try {
            InputWrapper inputWrapper = new InputWrapper();
            inputWrapper.loanId = loanId;
            inputWrapper.processName = processName;

            if (loanId != null) {
                List<Application_Applicant__c> appLists = [SELECT Id FROM Application_Applicant__c WHERE Loan_Application__c = :loanId 
                                                            AND Applicant_Type__c = 'Primary Applicant' LIMIT 1];
                if (!appLists.isEmpty()) {
                    inputWrapper.applicantId = appLists[0].Id;
                }
            }

            return initiateUdhyamRegistrationcheck(inputWrapper);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string initiateUdhyamRegistrationcheck( InputWrapper inputWrapper){
        String res= 'fail';
        try {
            String resultMessage;
            String loanId = InputWrapper.loanId;
            String applicantId= InputWrapper.applicantId;
            String processName = InputWrapper.processName;
            // String processName = 'Loan Udhyam';

            List<Opportunity> loanDataList= [SELECT Id, Name,Udhyam_Registration_No__c FROM Opportunity WHERE Id = :loanId];
            List<String> customerType = new List<String>();
            customerType.add('Individual');
            List<Integration_Master__mdt> metadata = [SELECT 
                                                        Process_Name__c,
                                                        Handler_Class__c,
                                                        Endpoint__c,
                                                        Request_Method__c,
                                                        Client_Id__c,
                                                        Client_Secret__c,
                                                        Allowed_Retry__c,
                                                        Gestation_Period__c,
                                                        Refresh_Allowed__c,
                                                        Activity_Name__c,Customer_Type__c,Content_Type__c
                                                    FROM Integration_Master__mdt 
                                                    WHERE Activity_Name__c = :processName];


            Map<String,Integration_Master__mdt> customerTypeMD = new Map<String,Integration_Master__mdt>();
            for(Integration_Master__mdt iterMeta : metadata) {
                customerTypeMD.put(iterMeta.Customer_Type__c,iterMeta);
            }

            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
            
            wrapper.recordId = applicantId;
            wrapper.loanApplicationId = loanId;  
            wrapper.type = processName;
            wrapper.endpoint = metadata[0].Endpoint__c;
            wrapper.requestMethod = metadata[0].Request_Method__c;
            wrapper.clientId = metadata[0].Client_Id__c;
            wrapper.clientSecret = metadata[0].Client_Secret__c;
            wrapper.allowedRetry = metadata[0].Allowed_Retry__c;
            wrapper.gestationPeriod = metadata[0].Gestation_Period__c;
            wrapper.activityname = metadata[0].Activity_Name__c;
            wrapper.refreshallowed = metadata[0].Refresh_Allowed__c;
            wrapper.handlername =  metadata[0].Handler_Class__c;
            wrapper.registrationNo = loanDataList[0].Udhyam_Registration_No__c;

            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);

            Integration_Details__c integrationDetail = new Integration_Details__c();
            integrationDetail.Related_Record_Id__c = loanId;
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                // Collect all validation errors and send back to JS
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = 'Loan_Application__c';
                
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                return resultMessage;
            }else {
                Map<String,String> integrationRequestMap = new Map<String,String>();
                integrationRequestMap.put('intSettingName','Loan Udhyam Check');
                integrationRequestMap.put('requestJSON',respWrapper.payload);
                String bearer=Utility.getAccessToken();
                System.debug('bearer----'+bearer);
                integrationRequestMap.put('bearer',bearer);
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);


                UdhyamRegistartionCheckResponseWrapper response = (UdhyamRegistartionCheckResponseWrapper)JSON.deserialize(resp.getBody(), UdhyamRegistartionCheckResponseWrapper.Class);
				
                resultMessage = 'Sucess';
                integrationDetail.Calling_Source__c = wrapper.type; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 
                integrationDetail.Response_JSON__c = JSON.serialize(resp.getBody()); 
                integrationDetail.Status__c = String.valueof('200'); 
                integrationDetail.Method_Type__c = 'POST'; 
                integrationDetail.EndPoint__c = wrapper.endpoint; 
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.Name = processName; 
                integrationDetail.Loan_Application__c = loanid;
				integrationDetail.Is_Success_Response__c = true;
               /* Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint(response.result.pdfData);
                request.setMethod('GET');
                HttpResponse pdfresponse = http.send(request);*/

                //if (pdfresponse.getStatusCode() == 200){
                    Blob fileBlob = EncodingUtil.base64Decode(response.result.pdfData);
                   // Blob fileBlob = pdfresponse.getBodyAsBlob();
                    ContentVersion cv = new ContentVersion();
                    cv.Title = loanDataList[0].Name+'_UdhyamReport.pdf';
                    cv.PathOnClient = 'UdhyamReport.pdf';
                    cv.VersionData = fileBlob;
                    insert cv;

                    ContentVersion insertedVersion = [
                        SELECT ContentDocumentId
                        FROM ContentVersion
                        WHERE Id = :cv.Id
                    ];
                    String contentDocumentId = insertedVersion.ContentDocumentId;

                    Document_Details__c docDetails = new Document_Details__c();
                    docDetails.Loan_Application__c = loanId;
                    docDetails.Content_Document_Id__c = contentDocumentId;
                    docDetails.Status__c = 'Uploaded';
                    docDetails.Name = loanDataList[0].Name+'_Udhyam Report';
                    insert docDetails;

                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.LinkedEntityId = docDetails.Id; 
                    cdl.ContentDocumentId = contentDocumentId;
                    cdl.ShareType = 'V';
                    cdl.Visibility = 'AllUsers'; 
                    insert cdl;
                        
              //  }

                insert integrationDetail;
                
                res= 'success';
            }
        } catch (Exception e) {
            System.debug('message Udhyam fail>'+e.getMessage() + 'at ' +e.getLineNumber());
            System.debug('get line number in Udhyam>'+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }

        return res;
    }

    @AuraEnabled
    public static List<UdhyamRegistartionCheckResponseWrapper> getUdhyamCheckdata( String loanId){
        List<UdhyamRegistartionCheckResponseWrapper> caCheckWrapper= new List<UdhyamRegistartionCheckResponseWrapper>();
        try {
            Map<String, String> inteToApplicant= new Map<String, String>();
            List<Integration_Details__c> integrationDetails=  Utility.getIntegrationRecordsForCreditAPIs(loanId, 'Loan Udhyam');
            for(Integration_Details__c integration: integrationDetails){
                inteToApplicant.put(integration.Id, integration.Related_Record_Id__c);
            }
            Map<Id,Application_Applicant__c> applicantList= new Map<Id,Application_Applicant__c>([SELECT Id, Name, Applicant_Name__c FROM Application_Applicant__c WHERE Id IN :inteToApplicant.values()]);
            for(Integration_Details__c inte: integrationDetails){
                UdhyamRegistartionCheckResponseWrapper respWrapper = (UdhyamRegistartionCheckResponseWrapper)JSON.deserialize(inte.Response_JSON__c, UdhyamRegistartionCheckResponseWrapper.Class);
                Application_Applicant__c applicant = applicantList.get(inte.Related_Record_Id__c);
                respWrapper.applicantName = applicant.Name;

                List<Cls_Industry> industryList= respWrapper.result.industry;
                if(industryList.size()>0){
                    Integer count=1;
                    for(Cls_Industry qual: industryList){
                        qual.srno = count;
                        count = count+1;
                    }
                }

                caCheckWrapper.add(respWrapper);
                
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return caCheckWrapper;
    }
    
    public class InputWrapper{
        @AuraEnabled public String loanId;
        @AuraEnabled public String applicantId;
        @AuraEnabled public String registrationNo;
        @AuraEnabled public String processName;
    }

    public class UdhyamRegistartionCheckResponseWrapper{
        @AuraEnabled public String applicantName;
        @AuraEnabled public String requestId { get; set; }
        @AuraEnabled public Cls_Result result { get; set; }
        @AuraEnabled public Integer statusCode { get; set; }
        @AuraEnabled public Cls_ClientData clientData { get; set; }
    }

    public class Cls_Result {
        @AuraEnabled public String udyamRegistrationNo { get; set; }
        @AuraEnabled public String dateOfRegistration { get; set; }
        @AuraEnabled public String interestedInTreds { get; set; }
        @AuraEnabled public String interestedInGem { get; set; }
        @AuraEnabled public Cls_Profile profile { get; set; }
        @AuraEnabled public Cls_BankDetails bankDetails { get; set; }
        @AuraEnabled public Cls_EmploymentDetails employmentDetails { get; set; }
        @AuraEnabled public Cls_Financials financials { get; set; }
        @AuraEnabled public List<Cls_BranchDetails> branchDetails { get; set; }
        @AuraEnabled public Cls_OfficialAddress officialAddress { get; set; }
        @AuraEnabled public List<Cls_Industry> industry { get; set; }
        @AuraEnabled public String pdfData { get; set; }
    }

    public class Cls_Profile {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String enterpriseType { get; set; }
        @AuraEnabled public String majorActivity { get; set; }
        @AuraEnabled public String organizationType { get; set; }
        @AuraEnabled public String ownerName { get; set; }
        @AuraEnabled public String pan { get; set; }
        @AuraEnabled public String previousITRStatus { get; set; }
        @AuraEnabled public String itrType { get; set; }
        @AuraEnabled public String gstnStatus { get; set; }
        @AuraEnabled public String mobile { get; set; }
        @AuraEnabled public String emailId { get; set; }
        @AuraEnabled public String socialCategory { get; set; }
        @AuraEnabled public String gender { get; set; }
        @AuraEnabled public String speciallyAbled { get; set; }
        @AuraEnabled public String dateOfIncorporation { get; set; }
        @AuraEnabled public String dateOfCommencement { get; set; }
    }

    public class Cls_BankDetails {
        @AuraEnabled public String bank { get; set; }
        @AuraEnabled public String ifsc { get; set; }
        @AuraEnabled public String acNo { get; set; }
    }

    public class Cls_EmploymentDetails {
        @AuraEnabled public String male { get; set; }
        @AuraEnabled public String female { get; set; }
        @AuraEnabled public String others { get; set; }
        @AuraEnabled public String total { get; set; }
    }

    public class Cls_Financials {
        @AuraEnabled public String financialYear { get; set; }
        @AuraEnabled public Cls_FinancialDetails details { get; set; }
    }

    public class Cls_FinancialDetails {
        @AuraEnabled public String wdvPme { get; set; }
        @AuraEnabled public String exclusion { get; set; }
        @AuraEnabled public String netInvestmentInPme { get; set; }
        @AuraEnabled public String totalTurnover { get; set; }
        @AuraEnabled public String exportTurnover { get; set; }
        @AuraEnabled public String netTurnover { get; set; }
    }

    public class Cls_BranchDetails {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String flat { get; set; }
        @AuraEnabled public String premises { get; set; }
        @AuraEnabled public String village { get; set; }
        @AuraEnabled public String block { get; set; }
        @AuraEnabled public String road { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String pincode { get; set; }
        @AuraEnabled public String district { get; set; }
    }

    public class Cls_OfficialAddress {
        @AuraEnabled public String flat { get; set; }
        @AuraEnabled public String premises { get; set; }
        @AuraEnabled public String village { get; set; }
        @AuraEnabled public String block { get; set; }
        @AuraEnabled public String road { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String pincode { get; set; }
        @AuraEnabled public String district { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String mobile { get; set; }
    }

    public class Cls_Industry {
        @AuraEnabled public Integer srno { get; set; }
        @AuraEnabled public String industry { get; set; }
        @AuraEnabled public String subSector { get; set; }
        @AuraEnabled public String activityDescription { get; set; }
        @AuraEnabled public String industryCode { get; set; }
        @AuraEnabled public String subSectorCode { get; set; }
        @AuraEnabled public String nicCode { get; set; }
        @AuraEnabled public String activity { get; set; }
    }

    public class Cls_ClientData {
        @AuraEnabled public String caseId { get; set; }
    }

    public String invokeMethod(String loanId, String appId, String activityName) {
        return createInputMap(loanId, activityName, appId);
    }
}