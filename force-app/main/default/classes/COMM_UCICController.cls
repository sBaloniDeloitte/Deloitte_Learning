public with sharing class COMM_UCICController {
    @AuraEnabled
    public static String initiateAPIRequest(Map<String, String> inputMap){
        try {
            UCICDeduplicationInfo dedupeInfo = new UCICDeduplicationInfo();
            List<string> validatemandate = new List<string>();
            List<string> constructpayload = new List<string>();
            String resultMessage;
            
            String loanId = inputMap.get('loanId');
            String applicantId = inputMap.get('applicantId');
            String processName = inputMap.get('processName');
            String panNumber  = inputMap.get('panNumber');
            String panName  = inputMap.get('panName');
            String aadharNumber = inputMap.get('aadharNumber');
            String voterNumber = inputMap.get('voterNumber');
            String dlNumber = inputMap.get('dlNumber');
            String passportNumber = inputMap.get('passportNumber');
            Date dob= Date.valueof(inputMap.get('dob'));
            String gender = inputMap.get('gender');
            Boolean isFromLead;
            if(inputMap.get('isFromLead')!=null){
                isFromLead = Boolean.valueof(inputMap.get('isFromLead'));
            }
            else{
                isFromLead=false;
            }
           
            // Application_Applicant__c app = [Select id, Pan_Name__c, PAN_Number__c,DOB__c,DOI__c from Application_Applicant__c where id = :applicantId];
            //  String panNumber = app.PAN_Number__c!=null ?app.PAN_Number__c:'';
            //  String panName = app.Pan_Name__c!=null ?app.Pan_Name__c:'';
            //  Date dob = app.DOB__c!=null ?app.DOB__c:app.DOI__c;
            // String dob = inputMap.get('dob');
            // String panName = inputMap.get('panName');
             String retunrResp;
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
            wrapper.panNumber = panNumber ;
            wrapper.aadharNumber = aadharNumber;
            wrapper.voterNumber = voterNumber;
            wrapper.dlNumber = dlNumber ;
            wrapper.passportNumber = passportNumber;
            wrapper.customerDOB = dob;
            wrapper.customerFirstName = panName.split(' ')[0];
            wrapper.isforFL=isFromLead;
            if(panName.contains(' ')){
                 wrapper.customerLastName = panName.split(' ')[1];
            }
                      
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Integration_Settings__c> intSettingList = [SELECT Name,Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
            FROM Integration_Settings__c WHERE Name = 'UCIC De Dupe Check' LIMIT 1];
            Integration_Settings__c intSetting = intSettingList[0];
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name =processName ;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                retunrResp = resultMessage;
            }
            else{
                Map<String,String> integrationRequestMap = new Map<String,String>();
                integrationRequestMap.put('intSettingName','UCIC De Dupe Check');
                integrationRequestMap.put('requestJSON',respWrapper.payload);
                String bearer = Utility.getAccessToken();
                System.debug('bearer----'+bearer);
                integrationRequestMap.put('bearer',bearer);
                dedupeInfo.freshCustomer = false;
                dedupeInfo.duplicateCustomers = new List<CustomerMatch>();
                dedupeInfo.integrationDetails = new IntegrationDetailsWrapper();
                dedupeInfo.integrationDetails.requestStr = respWrapper.payload;
                //Create a simulated duplicate customer
                 CustomerMatch simulatedMatch = new CustomerMatch();
                System.debug('integrationRequestMap: ' + integrationRequestMap);
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                System.debug('Response: ' + resp);
                System.debug('Response Body: ' + resp.getBody());
                dedupeInfo.integrationDetails.responseBody = resp.getBody();
                dedupeInfo.integrationDetails.methodType = intSetting.Request_Method__c;
                dedupeInfo.integrationDetails.endpoint = intSetting.Request_Method__c;
                dedupeInfo.integrationDetails.statusCode = String.valueOf(resp.getStatusCode());
                dedupeInfo.integrationDetails.name = intSetting.Name+' API';
                if(resp.getStatusCode() ==200){
                    dedupeInfo.isAPISuccess = true;
                    ResponseWrapper responseWrap = (ResponseWrapper) JSON.deserialize(resp.getBody(), ResponseWrapper.class);
                    // if (!String.isBlank(jsonResp)) {
                    //     ResponseWrapper responseWrap = (ResponseWrapper) JSON.deserialize(jsonResp, ResponseWrapper.class);
                        System.debug('responseWrap----'+ responseWrap);
                        if (responseWrap != null ) {
                            Boolean isDup = false;
                                dedupeInfo.ucicid = responseWrap.Response.StatusInfo.UCIC;
                                dedupeInfo.ucictype = responseWrap.Response.StatusInfo.UCIC_Type;
                                System.debug('dedupeInfo.commonId-->'+dedupeInfo.commonId);
                                System.debug('dedupeInfo.ucicid-->'+dedupeInfo.ucicid);
                                System.debug('dedupeInfo.ucictype-->'+dedupeInfo.ucictype);{
                            if(responseWrap.Response.CustomerMatchResponse != null && !responseWrap.Response.CustomerMatchResponse.isEmpty())
                            for (CustomerMatchResponseWrapper matchResp : responseWrap.Response.CustomerMatchResponse) {
                                System.debug('matchResp SourceSystem-->'+matchResp.Demographics.SourceSystem);
                                 
                                if( matchResp.Demographics.SourceSystem !='Salesforce' && matchResp.Demographics.SourceSystem !='GFL'&& matchResp.Demographics.CustUnqId!=null && !matchResp.Demographics.CustUnqId.containsIgnoreCase('SF') &&  (responseWrap.Response.StatusInfo.UCIC_Type=='E'||responseWrap.Response.StatusInfo.UCIC_Type=='T')){
                                    isDup= true;
                                     break;
                                 } 
                                 
                            }
                            if(isDup){
                                 dedupeInfo.freshCustomer = false;
                                dedupeInfo.duplicateCustomers = new List<CustomerMatch>();
                                dedupeInfo.commonId = responseWrap.Response.StatusInfo.CUSTUNQID;
                               
                                
                            for (CustomerMatchResponseWrapper matchResp : responseWrap.Response.CustomerMatchResponse) {
                                  if( matchResp.Demographics.SourceSystem !='Salesforce' && matchResp.Demographics.SourceSystem !='GFL'&& matchResp.Demographics.CustUnqId!=null && !matchResp.Demographics.CustUnqId.containsIgnoreCase('SF') &&  (responseWrap.Response.StatusInfo.UCIC_Type=='E'||responseWrap.Response.StatusInfo.UCIC_Type=='T')){
                                     CustomerMatch customerMatch = new CustomerMatch();
                                    customerMatch.customerId = matchResp.Demographics.CustUnqId;
                                    customerMatch.name = matchResp.Demographics.Name;
                                    if( matchResp.Demographics.PanNo!='NOT AVAILABLE'){
                                        customerMatch.panNumber = matchResp.Demographics.PanNo;
                                    }
                                    else{
                                         customerMatch.panNumber ='';
                                    }
                                   customerMatch.gender= matchResp.Demographics.Gender;
                                    customerMatch.dlNumber= matchResp.Demographics.Driving_License;
                                    customerMatch.aadhar= matchResp.Demographics.Aadhar;
                                    customerMatch.passport= matchResp.Demographics.PassportNo;
                                    customerMatch.voterId= matchResp.Demographics.VoterID;
                                    customerMatch.UCIC= matchResp.Demographics.UCIC;
                                    customerMatch.customerType= matchResp.Demographics.CustomerCategory== 'Retail' ? 'Individual' : (matchResp.Demographics.CustomerCategory== 'Corporate' ? 'Non Individual' : '');
                                    if (matchResp.Demographics.Dob_doi != null) {
                                        List<String> dateParts = matchResp.Demographics.Dob_doi.split('-');
                                        String formattedDate = dateParts[2] + '-' + dateParts[1] + '-' + dateParts[0];
                                        customerMatch.dob = Date.valueOf(formattedDate);
                                    } else {
                                        customerMatch.dob = null;
                                    }
                                
                                    customerMatch.matchReason = matchResp.Demographics.MatchReason;
                                
                                    // Extract mobile number
                                    if (matchResp.ACE != null && !matchResp.ACE.isEmpty()) {
                                        for (ACEWrapper ace : matchResp.ACE) {
                                            if (ace.PhoneType != null && ace.PhoneType.toLowerCase() == 'mobile') {
                                                customerMatch.mobileNumber = ace.Phone;
                                                break;
                                            }
                                        }
                                    }
                                
                                    dedupeInfo.duplicateCustomers.add(customerMatch);
                                    retunrResp = JSON.serialize(dedupeInfo);
                                }
                            }
                        }
                        else{
                            dedupeInfo.freshCustomer = true;
                            retunrResp = JSON.serialize(dedupeInfo);
                        }
                    }
                    } 
                    else{
                        dedupeInfo.freshCustomer = true;
                            retunrResp = JSON.serialize(dedupeInfo);
                    }
                }
                else{
                    dedupeInfo.isAPISuccess = false;
                    dedupeInfo.freshCustomer = true;
                    retunrResp = JSON.serialize(dedupeInfo);
                }
            }
            system.debug('result-->'+retunrResp);
            return retunrResp;
        }
        catch (Exception e) {
            System.debug('error in '+e.getLinenumber());
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    public class ResponseWrapper {
        public cls_Response Response;
        // public List<CustomerMatchResponseWrapper> CustomerMatchResponse;
    }
    public class cls_Response{
        public StatusInfoWrapper StatusInfo;
        public List<CustomerMatchResponseWrapper> CustomerMatchResponse;
    }

    public class StatusInfoWrapper {
        public String RequestId;           // Request ID
        public String CUSTUNQID;           // Customer Unique ID
        public String Status;              // Status Code (e.g., "C")
        public String StatusMessage;       // Status message (e.g., "Success")
        public String ResponseCode;        // HTTP Response Code (e.g., "200")
        public String Description;         // Description of the Response
        public String MatchCount;          // Number of Matches Found
        public String UCIC;                // Unique Customer Identifier Code
        public String UCIC_Type;           // Unique Customer Identifier Code Type
    }

    public class CustomerMatchResponseWrapper {
        public DemographicsWrapper Demographics;
        public List<ACEWrapper> ACE;
    }

    public class DemographicsWrapper {
        public String SourceSystem;        // Source System (e.g., "Salesforce")
        public String CustUnqId;           // Customer Unique ID
        public String MatchReason;         // Reason for the Match (e.g., "Pan|Rule0")
        public String MatchCategory;       // Match Category (e.g., "GODREJ_GOOD")
        public String RecordType;          // Record Type (e.g., "ONLINE")
        public String Name;                // Customer Name
        public String Gender;              // Gender (nullable)
        public String PanNo;               // PAN Number
        public String VoterID;             // Voter ID (nullable)
        public String PassportNo;          // Passport Number (nullable)
        public String Aadhar;              // Aadhaar Number (nullable)
        public String CombinedStrength;    // Combined Strength (e.g., "0")
        public String CustomerCategory;  //New tag added
        public String Dob_doi;             // Date of Birth or Date of Issue (e.g., "06-12-2024")
        public String Driving_License;     // Driving License (nullable)
        public String UCIC;
    }

    public class ACEWrapper {
        public String AddressType;            // Address type (e.g., 'OFFADD')
        public String Address;                // Address
        public String City;                   // City
        public String State;                  // State
        public String Country;                // Country
        public String Pincode;                // Pincode
        public String Phone;                  // Phone number
        public String PhoneType;              // Phone type
        public String Email;                  // Email
        public String EmailType;              // Email type
    }
    public class UCICDeduplicationInfo {
        @AuraEnabled public Boolean freshCustomer;
        @AuraEnabled public String commonId;
        @AuraEnabled public String ucicid;
        @AuraEnabled public String ucictype;
        @AuraEnabled public List<CustomerMatch> duplicateCustomers = new List<CustomerMatch>();
        @AuraEnabled public IntegrationDetailsWrapper integrationDetails;
        @AuraEnabled public Boolean isAPISuccess;
    }
    /**
     * Customer Match Info Class
     */
    public class CustomerMatch {
        @AuraEnabled public String customerId;
        @AuraEnabled public String name;
        @AuraEnabled public String panNumber;
        @AuraEnabled public String aadhar;
        @AuraEnabled public String dlNumber;
        @AuraEnabled public String voterId;
        @AuraEnabled public String passport;
        @AuraEnabled public Date dob;
        @AuraEnabled public String matchReason;
        @AuraEnabled public String mobileNumber;
        @AuraEnabled public String gender;
        @AuraEnabled public String  UCIC;
        @AuraEnabled public String customerType;
        
    }
    public class IntegrationDetailsWrapper{
        @AuraEnabled public String requestStr;
        @AuraEnabled public String responseBody;
        @AuraEnabled public String name;
        @AuraEnabled public String methodType;
        @AuraEnabled public String statusCode;
        @AuraEnabled public String endpoint;
    }
    
}