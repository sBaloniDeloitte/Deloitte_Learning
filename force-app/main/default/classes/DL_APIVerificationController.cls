public with sharing class DL_APIVerificationController implements DynamicInvoker {
    @AuraEnabled
    public static String createInputMap(Id loanId, String processName, String appId) {
        System.debug('inside createInputMap');
        System.debug('loanId: '+loanId);
        System.debug('processName: '+processName);
        System.debug('appId: '+appId);
        // try {
            Map<String, String> inputMap = new Map<String, String>();
            inputMap.put('recordId', loanId); 
            inputMap.put('processName', processName); 
            inputMap.put('applicantId', appId);

            return initiateDLValidation(inputMap);
        // } catch (Exception e) {
        //     throw new AuraHandledException(e.getMessage());
        // }
    }
    @AuraEnabled
    public static String initiateDLValidation(Map<String, String> inputMap) {
        String resultMessage = 'Building in progress'; // for bypass
        String loanId = inputMap.get('recordId');
        String processName = inputMap.get('processName');
        String appId = inputMap.get('applicantId');
        Map<String,API_Exceptions__mdt> allMetaData = API_Exceptions__mdt.getAll();
        List<Application_Applicant__c> applicantDetails = [SELECT Id, Name, Voter_ID_Number__c FROM Application_Applicant__c WHERE Id = :appId AND Loan_Application__c = :loanId];
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

        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.recordId = appId;
        wrapper.loanApplicationId = loanId;
        wrapper.type = processName;
        wrapper.endpoint = metadata.Endpoint__c;
        wrapper.requestMethod = metadata.Request_Method__c;
        wrapper.clientId = metadata.Client_Id__c;
        wrapper.clientSecret = metadata.Client_Secret__c;
        wrapper.allowedRetry = metadata.Allowed_Retry__c;
        wrapper.gestationPeriod = metadata.Gestation_Period__c;
        wrapper.activityname = metadata.Activity_Name__c;
        wrapper.refreshallowed = metadata.Refresh_Allowed__c;
        wrapper.handlername =  metadata.Handler_Class__c;
        // wrapper.voterId = applicantDetails[0].Voter_ID_Number__c;
        System.debug('wrapper --> '+wrapper);
        intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
        System.debug('respWrapper -->' + respWrapper);
        List<Integration_Settings__c> intSettingList = [
                SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c 
                FROM Integration_Settings__c 
                WHERE Name = 'Loan DL Verification' LIMIT 1
            ];
            Integration_Settings__c intSetting = intSettingList[0];
            System.debug('respWrapper.prerequisiteError --> '+respWrapper.prerequisiteError);
            System.debug('respWrapper.prerequisiteError '+respWrapper.prerequisiteError);

        Map<String,String> integrationRequestMap = new Map<String,String>();
        integrationRequestMap.put('intSettingName','Loan DL Verification');
        integrationRequestMap.put('requestJSON',respWrapper.payload);
        String bearer=Utility.getAccessToken();
        System.debug('bearer----'+bearer);
        integrationRequestMap.put('bearer',bearer);
        System.debug('integrationRequestMap --> '+integrationRequestMap);
        HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
        System.debug('resp Int'+resp);
        /*
        if(Test.isRunningTest()){
            resp = new HTTPResponse();
             resp.setBody('{"test": "body"}');
            resp.setStatusCode(200);
        }*/
        // System.debug('resp '+resp.getBody());');
        Integration_Details__c inteDetails = new Integration_Details__c();
        if(resp != null) {
            System.debug('resp '+resp);
            System.debug('resp Status '+resp.getStatusCode());
            System.debug('resp Body '+resp.getBody());
            
            if(resp.getStatusCode() == 200 || resp.getStatusCode() == 202) {
                String jsonResp = resp.getBody();
                DLRespWrapper dlResp = (DLRespWrapper) JSON.deserialize(jsonResp.replace('"from":', '"fromDate":').replace('"to":', '"toDate":'), DLRespWrapper.class);
                System.debug('dlResp.statusCode'+dlResp.statusCode);
                if (dlResp.statusCode == 101) {
                    System.debug('At 88 ');
                    List<Triangulation_Data__c> triangulationDatas = [SELECT Id, Loan_Application__c, Application_Applicant__c, Pan__c, Name__c, Father__c, Date_Of_Birth__c, 
                                                                        Date_Of_Issue__c, Address__c, DL_Number__c, Blood_Group__c, Validity_Non_Transport__c, 
                                                                        Validity_Transport__c, Initial_Issuing_Office__c FROM Triangulation_Data__c WHERE Loan_Application__c =: loanId 
                                                                        AND Application_Applicant__c =: appId AND Source_Type__c = 'Validation API' AND Document_Type__c = 'Driving License'];

                    if (dlResp != null && dlResp.result != null) {
                        String name = dlResp.result.name;
                        String fatherHusband = dlResp.result.father_husband;
                        String dob = dlResp.result.dob;
                        String issueDate = dlResp.result.issueDate;
                        String dlNumber = dlResp.result.dlNumber;
                        String bloodGroup = dlResp.result.bloodGroup;
                        String validityNonTransport = dlResp.result.validity != null ? dlResp.result.validity.nonTransport : null;
                        String validityTransport = dlResp.result.validity != null ? dlResp.result.validity.transport : null;
                        String issuingOffice = dlResp.result.endorsementAndHazardousDetails != null ? dlResp.result.endorsementAndHazardousDetails.initialIssuingOffice : null;
                        String completeAddress = (dlResp.result.address != null && !dlResp.result.address.isEmpty()) ? dlResp.result.address[0].completeAddress : null;

                        if (!triangulationDatas.isEmpty()) {
                            Triangulation_Data__c data = triangulationDatas[0];
                            if (name != null) data.Name__c = name;
                            if (fatherHusband != null) data.Father__c = fatherHusband;
                            if (dob != null) data.Date_Of_Birth__c = dob;
                            if (issueDate != null) data.Date_Of_Issue__c = issueDate;
                            if (dlNumber != null) data.DL_Number__c = dlNumber;
                            if (bloodGroup != null) data.Blood_Group__c = bloodGroup;
                            if (validityNonTransport != null) data.Validity_Non_Transport__c = validityNonTransport;
                            if (validityTransport != null) data.Validity_Transport__c = validityTransport;
                            if (issuingOffice != null) data.Initial_Issuing_Office__c = issuingOffice;
                            if (completeAddress != null) data.Address__c = completeAddress;
                            
                            update data;
                        } else {
                            Triangulation_Data__c triangulationData = new Triangulation_Data__c();
                            triangulationData.Application_Applicant__c = appId;
                            triangulationData.Loan_Application__c = loanId; 
                            triangulationData.Source_Type__c = 'Validation API';
                            triangulationData.Document_Type__c = 'Driving License';

                            if (name != null) triangulationData.Name__c = name;
                            if (fatherHusband != null) triangulationData.Father__c = fatherHusband;
                            if (dob != null) triangulationData.Date_Of_Birth__c = dob;
                            if (issueDate != null) triangulationData.Date_Of_Issue__c = issueDate;
                            if (dlNumber != null) triangulationData.DL_Number__c = dlNumber;
                            if (bloodGroup != null) triangulationData.Blood_Group__c = bloodGroup;
                            if (validityNonTransport != null) triangulationData.Validity_Non_Transport__c = validityNonTransport;
                            if (validityTransport != null) triangulationData.Validity_Transport__c = validityTransport;
                            if (issuingOffice != null) triangulationData.Initial_Issuing_Office__c = issuingOffice;
                            if (completeAddress != null) triangulationData.Address__c = completeAddress;

                            insert triangulationData;
                        }
                    }
                    inteDetails.Is_Success_Response__c = true; 
                } else {
                    for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                        if(execeptionMeta.Error_Code__c == String.valueOf(dlResp.statusCode)){
                            resultMessage = 'Error : ' + execeptionMeta.Error_Message__c;
                        }
                    }
                }
            } else {
                resultMessage = 'Error: Api Call ';
            }
        } 
        else {
            resultMessage = 'Error: Internal Server Error, no response found. Kindly contact system admin.';
        }

        inteDetails.Name = processName;
        inteDetails.Request_JSON__c = respWrapper.payload; 
        inteDetails.Response_JSON__c = JSON.serialize(resp.getBody()); 
        inteDetails.Loan_Application__c = loanId;
        inteDetails.Related_Record_Id__c = appId;
        inteDetails.Object_Name__c = 'Application_Applicant__c';
        inteDetails.Is_Success_Response__c = true;
        inteDetails.Endpoint__c = 'https://uat-ss-sf.godrejcapital.com/karza/v3/dl';
        insert inteDetails;
		resultMessage = 'Success';
        return resultMessage;
    }

    public String invokeMethod(String loanId, String appId, String activityName) {
        return createInputMap(loanId, activityName, appId);
    }

    public class DLRespWrapper {
        @AuraEnabled public String requestId;
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public cls_result result;
        @AuraEnabled public cls_clientData clientData;
    }
    
        public class cls_result {
            @AuraEnabled public String issueDate;
            @AuraEnabled public String father_husband;
            @AuraEnabled public String name;
            @AuraEnabled public String img;
            @AuraEnabled public String bloodGroup;
            @AuraEnabled public String dob;
            @AuraEnabled public String dlNumber;
            @AuraEnabled public cls_validity validity;
            @AuraEnabled public List<cls_covDetails> covDetails;
            @AuraEnabled public List<cls_address> address;
            @AuraEnabled public String status;
            @AuraEnabled public cls_statusDetails statusDetails;
            @AuraEnabled public cls_endorsement endorsementAndHazardousDetails;
        }
    
        public class cls_validity {
            @AuraEnabled public String nonTransport;
            @AuraEnabled public String transport;
        }
    
        public class cls_covDetails {
            @AuraEnabled public String cov;
            @AuraEnabled public String issueDate;
        }
    
        public class cls_address {
            @AuraEnabled public String addressLine1;
            @AuraEnabled public String state;
            @AuraEnabled public String district;
            @AuraEnabled public String pin;
            @AuraEnabled public String completeAddress;
            @AuraEnabled public String country;
            @AuraEnabled public String type;
        }
    
        public class cls_statusDetails {
            @AuraEnabled public String fromDate;  // Renamed 'from'
            @AuraEnabled public String toDate;    // Renamed 'to'
            @AuraEnabled public String remarks;
        }
    
        public class cls_endorsement {
            @AuraEnabled public String initialIssuingOffice;
            @AuraEnabled public String lastEndorsementDate;
            @AuraEnabled public String lastEndorsedOffice;
            @AuraEnabled public String endorsementReason;
            @AuraEnabled public String hazardousValidTill;
            @AuraEnabled public String hillValidTill;
        }
    
        public class cls_clientData {
            @AuraEnabled public String caseId;
        }
    
}