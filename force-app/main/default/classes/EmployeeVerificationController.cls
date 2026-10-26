public with sharing class EmployeeVerificationController {


    @AuraEnabled
    public static string initiateEmployeeCheck( String inputMap){
        System.debug('inputWrapper---'+inputMap);
        String res= 'fail';
        try {

            InputWrapper inputWrapper = (InputWrapper) JSON.deserialize(inputMap, InputWrapper.class);
            
            String resultMessage;
            String loanId = inputWrapper.loanId;
            String applicantId= inputWrapper.applicantId;
            String processName = inputWrapper.processName;



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
            wrapper.applicantName = inputWrapper.applicantName;
            wrapper.applicantMobile = inputWrapper.applicantMobile;
            wrapper.applicantEmail = inputWrapper.applicantEmail;

            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);

            Integration_Details__c integrationDetail = new Integration_Details__c();
            integrationDetail.Related_Record_Id__c = applicantId;
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                // Collect all validation errors and send back to JS
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                return resultMessage;
            }else{
                /*
                    HttpRequest req = new HttpRequest();
                    req.setHeader('Content-Type',customerTypeMD.get(iterAppA.Customer_Type__c).Content_Type__c );
                    
                    
                    req.setMethod(wrapper.requestMethod);
                    
                    string endpoint = wrapper.endpoint;
                    req.setEndpoint(endpoint);
                    req.setTimeout(60000);
                    req.setBody(respWrapper.payload);
                    System.debug('Request: '+ req);
                    
                    Http http = new Http();
                    HTTPResponse res = http.send(req);
                */

                String resp= '{' +
                                '"result": {' +
                                '"uan": [' +
                                '{' +
                                '"uan": "100078184954",' +
                                '"employer": [' +
                                '{' +
                                '"name": "PERFIOS SOFTWARE SOLUTIONS PRIVATE LIMITED",' +
                                '"memberId": "MHBAN17444100000010015",' +
                                '"settled": null,' +
                                '"isNameUnique": true,' +
                                '"matchName": "ALOK KUMAR",' +
                                '"lastMonth": "2204",' +
                                '"isRecent": true,' +
                                '"isNameExact": true,' +
                                '"isEmployed": true,' +
                                '"nameConfidence": 1,' +
                                '"emplrScore": 1,' +
                                '"uanNameMatch": true' +
                                '},' +
                                '{' +
                                '"name": "MORGAN STANLEY ADVANTAGE SERVICES PVT LTD",' +
                                '"memberId": "MHBAN00467750000003499",' +
                                '"settled": null,' +
                                '"isNameUnique": false,' +
                                '"matchName": "",' +
                                '"lastMonth": "",' +
                                '"isRecent": false,' +
                                '"isNameExact": false,' +
                                '"isEmployed": false,' +
                                '"nameConfidence": 0,' +
                                '"emplrScore": 0.39004101631932003,' +
                                '"uanNameMatch": true' +
                                '}' +
                                ']' +
                                '}' +
                                '],' +
                                '"email": {' +
                                '"data": {' +
                                '"disposable": false,' +
                                '"webmail": false,' +
                                '"result": true,' +
                                '"acceptAll": false,' +
                                '"smtpCheck": true,' +
                                '"regexp": true,' +
                                '"mxRecords": true,' +
                                '"email": "alok@perfios.com"' +
                                '},' +
                                '"whois": {' +
                                '"creationDate": "11-02-2015",' +
                                '"updateDate": "20-02-2022",' +
                                '"expirationDate": "11-02-2024",' +
                                '"registrant": {' +
                                '"name": "",' +
                                '"organization": "Perfios Software Solutions Private Limited",' +
                                '"street": "",' +
                                '"city": "",' +
                                '"postal": "",' +
                                '"country": "IN",' +
                                '"phone": "",' +
                                '"fax": "",' +
                                '"email": "",' +
                                '"stateprovince": ""' +
                                '}' +
                                '},' +
                                '"nameConfidence": 1' +
                                '},' +
                                '"nameLookup": {' +
                                '"organizationName": "Perfios Software Solutions Private Limited",' +
                                '"epfHistory": [' +
                                '{' +
                                '"totalAmount": 918610,' +
                                '"totalMembers": 219,' +
                                '"formatted_wage_month": "2204",' +
                                '"wageMonth": "APR-22"' +
                                '},' +
                                '{' +
                                '"totalAmount": 881085,' +
                                '"totalMembers": 208,' +
                                '"formatted_wage_month": "2203",' +
                                '"wageMonth": "MAR-22"' +
                                '}' +
                                '],' +
                                '"isNameExact": true,' +
                                '"isEmployed": true,' +
                                '"isRecent": true,' +
                                '"isNameUnique": true,' +
                                '"employeeName": "Alok Kumar"' +
                                '}' +
                                '},' +
                                '"request_id": "272ca55e-d332-4985-a127-f5fa24ed2652",' +
                                '"status-code": "101",' +
                                '"clientData": {' +
                                '"caseId": "123456"' +
                                '}' +
                                '}';

                EmployeeVerificationResponseWrapper response= (EmployeeVerificationResponseWrapper)JSON.deserialize(resp, EmployeeVerificationResponseWrapper.class);

                resultMessage = 'Sucess';
                integrationDetail.Calling_Source__c = wrapper.type; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 
                integrationDetail.Response_JSON__c = JSON.serialize(resp); 
                integrationDetail.Status__c = String.valueof('200'); 
                integrationDetail.Method_Type__c = 'POST'; 
                integrationDetail.EndPoint__c = wrapper.endpoint; 
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.Name = processName; 
                integrationDetail.Loan_Application__c = loanid;

                insert integrationDetail;
                res= 'success';
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return res;
    }


    @AuraEnabled
    public static List<EmployeeVerificationResponseWrapper> getEmployeeCheckData( String loanId){

        List<EmployeeVerificationResponseWrapper> employeecheckData= new List<EmployeeVerificationResponseWrapper>();
        try {
            Map<String, String> inteToApplicant= new Map<String, String>();
            List<Integration_Details__c> integrationDetails=  Utility.getIntegrationRecordsForCreditAPIs(loanId, 'Loan Employment Check');
            for(Integration_Details__c integration: integrationDetails){
                inteToApplicant.put(integration.Id, integration.Related_Record_Id__c);
            }
            Map<Id,Application_Applicant__c> applicantList= new Map<Id,Application_Applicant__c>([SELECT Id, Name, Applicant_Name__c FROM Application_Applicant__c WHERE Id IN :inteToApplicant.values()]);
            for(Integration_Details__c inte: integrationDetails){
                // Object jsonObj = JSON.deserializeUntyped(inte.Response_JSON__c);
                // Map<String, Object> jsonMap = (Map<String, Object>) jsonObj;
                String cleanedData= cleanResponse(inte.Response_JSON__c);
                EmployeeVerificationResponseWrapper respWrapper = (EmployeeVerificationResponseWrapper)JSON.deserialize(cleanedData, EmployeeVerificationResponseWrapper.Class);
                Application_Applicant__c applicant = applicantList.get(inte.Related_Record_Id__c);
                respWrapper.applicantName = applicant.Name;

                List<EPFHistoryWrapper> epfHistoryList = respWrapper.result.nameLookup.epfHistory;
                if(epfHistoryList.size()>0){
                    Integer count=1;
                    for(EPFHistoryWrapper epf: epfHistoryList){
                        epf.srno = count;
                        count = count+1;
                    }
                }

                List<UanWrapper> uanList=respWrapper.result.uan;
                if(uanList.size()>0){
                    respWrapper.result.uanNumber = uanList[0].uan;
                    if(uanList[0].employer.size()>0){
                        Integer count=1;
                        for(EmployerWrapper epf: uanList[0].employer){
                            epf.srno = count;
                            count = count+1;
                        }
                        respWrapper.result.employerList = uanList[0].employer;
                    }
                }

                employeecheckData.add(respWrapper);

            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return employeecheckData;
    }

    public class InputWrapper{
        @AuraEnabled public String loanId;
        @AuraEnabled public String applicantId;
        @AuraEnabled public String applicantName;
        @AuraEnabled public String applicantMobile;
        @AuraEnabled public String applicantEmail;
        @AuraEnabled public String processName;
    }

    public class EmployeeVerificationResponseWrapper{
        @AuraEnabled public String applicantName;
        @AuraEnabled public ResponseResultWrapper result { get; set; }
        @AuraEnabled public String request_id { get; set; }
        @AuraEnabled public String status_code { get; set; }
        @AuraEnabled public ClientDataResponseWrapper clientData { get; set; }
    }

    public class ResponseResultWrapper {
        @AuraEnabled public String uanNumber { get; set; }
        @AuraEnabled public List<UanWrapper> uan { get; set; }
        @AuraEnabled public List<EmployerWrapper> employerList { get; set; }
        @AuraEnabled public EmailWrapper email { get; set; }
        @AuraEnabled public NameLookupWrapper nameLookup { get; set; }
    }

    public class UanWrapper {
        @AuraEnabled public String uan { get; set; }
        @AuraEnabled public List<EmployerWrapper> employer { get; set; }
    }

    public class EmployerWrapper {
        @AuraEnabled public Integer srno { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String memberId { get; set; }
        @AuraEnabled public String settled { get; set; }
        @AuraEnabled public Boolean isNameUnique { get; set; }
        @AuraEnabled public String matchName { get; set; }
        @AuraEnabled public String lastMonth { get; set; }
        @AuraEnabled public Boolean isRecent { get; set; }
        @AuraEnabled public Boolean isNameExact { get; set; }
        @AuraEnabled public Boolean isEmployed { get; set; }
        @AuraEnabled public Decimal nameConfidence { get; set; }
        @AuraEnabled public Decimal emplrScore { get; set; }
        @AuraEnabled public Boolean uanNameMatch { get; set; }
    }

    public class EmailWrapper {
        @AuraEnabled public EmailDataWrapper data { get; set; }
        @AuraEnabled  public WhoisWrapper whois { get; set; }
        @AuraEnabled public Decimal nameConfidence { get; set; }
    }

    public class EmailDataWrapper {
        @AuraEnabled public Boolean disposable { get; set; }
        @AuraEnabled public Boolean webmail { get; set; }
        @AuraEnabled public Boolean result { get; set; }
        @AuraEnabled public Boolean acceptAll { get; set; }
        @AuraEnabled public Boolean smtpCheck { get; set; }
        @AuraEnabled public Boolean regexp { get; set; }
        @AuraEnabled public Boolean mxRecords { get; set; }
        @AuraEnabled public String email { get; set; }
    }

    public class WhoisWrapper {
        @AuraEnabled public String creationDate { get; set; }
        @AuraEnabled public String updateDate { get; set; }
        @AuraEnabled public String expirationDate { get; set; }
        @AuraEnabled public RegistrantWrapper registrant { get; set; }
    }

    public class RegistrantWrapper {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String organization { get; set; }
        @AuraEnabled public String street { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String postal { get; set; }
        @AuraEnabled public String country { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String fax { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String stateprovince { get; set; }
    }

    public class NameLookupWrapper {
        @AuraEnabled public String organizationName { get; set; }
        @AuraEnabled public List<EPFHistoryWrapper> epfHistory { get; set; }
        @AuraEnabled public List<EstInfoWrapper> estInfo { get; set; }
        @AuraEnabled public List<MatchesWrapper> matches { get; set; }
        @AuraEnabled public Boolean isNameExact { get; set; }
        @AuraEnabled public Boolean isEmployed { get; set; }
        @AuraEnabled public Boolean isRecent { get; set; }
        @AuraEnabled public Boolean isNameUnique { get; set; }
        @AuraEnabled public String employeeName { get; set; }
    }

    public class EPFHistoryWrapper {
        @AuraEnabled public Integer srno { get; set; }
        @AuraEnabled public Integer totalAmount { get; set; }
        @AuraEnabled public Integer totalMembers { get; set; }
        @AuraEnabled public String formatted_wage_month { get; set; }
        @AuraEnabled public String wageMonth { get; set; }
    }

    public class EstInfoWrapper {
        @AuraEnabled public String address { get; set; }
        @AuraEnabled public String contactNo { get; set; }
        @AuraEnabled public String emailId { get; set; }
        @AuraEnabled public String estId { get; set; }
    }

    public class MatchesWrapper {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Decimal confidence { get; set; }
        @AuraEnabled public String estId { get; set; }
        @AuraEnabled public Map<String, Boolean> epfHistory { get; set; }
    }

    public class ClientDataResponseWrapper {
        @AuraEnabled public String caseId { get; set; }
    }

    public static String cleanResponse(String response) {
        response = response.replace('\'', '');
        response = response.replace('\\', '');
        if (response.startsWith('"') && response.endsWith('"')) {
            response = response.substring(1, response.length() - 1);
        }
        return response;
    }
}