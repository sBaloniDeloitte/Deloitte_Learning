public with sharing class VoterId_ApiVerificationController implements DynamicInvoker {
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

            return initiateVoterVerification(inputMap);
        // } catch (Exception e) {
        //     throw new AuraHandledException(e.getMessage());
        // }
    }

    @AuraEnabled
    public static String initiateVoterVerification(Map<String, String> inputMap) {
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
        Map<String,String> integrationRequestMap = new Map<String,String>();
        integrationRequestMap.put('intSettingName','Loan Voter ID Authentication');
        integrationRequestMap.put('requestJSON',respWrapper.payload);
        String bearer=Utility.getAccessToken();
        System.debug('bearer----'+bearer);
        integrationRequestMap.put('bearer',bearer);
        System.debug('integrationRequestMap --> '+integrationRequestMap);
        HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
        if(resp != null) {
            System.debug('resp--> '+resp);
            System.debug('resp Status '+resp.getStatusCode());
            System.debug('resp Body '+resp.getBody());
            String jsonResp = resp.getBody();
            VoterVerificationWrapper voterResp = (VoterVerificationWrapper) JSON.deserialize(jsonResp, VoterVerificationWrapper.class);

            List<Triangulation_Data__c> triangulationDatas = [SELECT Id, Loan_Application__c, Application_Applicant__c, Spouse__c,
                                                                Name__c, Father__c, Date_Of_Birth__c, Voter__c, Gender__c, Age__c, 
                                                                Address__c FROM Triangulation_Data__c WHERE Loan_Application__c = :loanId 
                                                                AND Application_Applicant__c = :appId AND Source_Type__c = 'Validation API' 
                                                                AND Document_Type__c = 'Voter Front'];

            if (voterResp != null && voterResp.result != null) {
                String name = voterResp.result.name;
                String rlnType = voterResp.result.rlnType;
                String rlnName = voterResp.result.rlnName;
                String dob = voterResp.result.dob;
                String voterId = voterResp.result.epicNo;
                String gender = voterResp.result.gender;
                String age = String.valueOf(voterResp.result.age);
                String address = voterResp.result.houseNo + ', '+voterResp.result.pin;
                // String state = voterResp.result.state;
                // String district = voterResp.result.district;

                if (!triangulationDatas.isEmpty()) {
                    Triangulation_Data__c data = triangulationDatas[0];

                    if (name != null) data.Name__c = name;
                    if (rlnType == 'F') {
                        if (rlnName != null) data.Father__c = rlnName;
                    } else if (rlnType == 'H') {
                        if (rlnName != null) data.Spouse__c = rlnName;
                    }
                    if (dob != null) data.Date_Of_Birth__c = dob;
                    if (voterId != null) data.Voter__c = voterId;
                    if (gender != null) data.Gender__c = gender;
                    if (age != null) data.Age__c = age;
                    if (address != null) data.Address__c = address;

                    update data;
                } else {
                    Triangulation_Data__c newData = new Triangulation_Data__c();
                    newData.Application_Applicant__c = appId;
                    newData.Loan_Application__c = loanId;
                    newData.Source_Type__c = 'Validation API';
                    newData.Document_Type__c = 'Voter Front';

                    if (name != null) newData.Name__c = name;
                    if (rlnType == 'F') {
                        if (rlnName != null) newData.Father__c = rlnName;
                    } else if (rlnType == 'H') {
                        if (rlnName != null) newData.Spouse__c = rlnName;
                    }
                    if (dob != null) newData.Date_Of_Birth__c = dob;
                    if (voterId != null) newData.Voter__c = voterId;
                    // if (state != null) newData.State__c = state;
                    // if (district != null) newData.District__c = district;
                    if (gender != null) newData.Gender__c = gender;
                    if (age != null) newData.Age__c = age;
                    if (address != null) newData.Address__c = address;

                    insert newData;
                }
            }


            Integration_Details__c inteDetails = new Integration_Details__c();
            inteDetails.Name = processName;
            inteDetails.Loan_Application__c = loanId;
            inteDetails.Related_Record_Id__c = appId;
            inteDetails.Object_Name__c = 'Application_Applicant__c';
            inteDetails.Is_Success_Response__c = true; 
            inteDetails.Endpoint__c = 'https://godrejfinanceservicecloud--gflsit.sandbox.my.salesforce.com/services/apexrest/api/LeadManagement';
            insert inteDetails;
            resultMessage = 'Success';
        }
        return resultMessage;
    }

    public class VoterVerificationWrapper {
        public String requestId;
        public Result result;
        public Integer statusCode;
        public ClientData clientData;
    }
    
    public class Result {
        public String name;
        public String rlnName;
        public String rlnType;
        public String gender;
        public String district;
        public String acName;
        public String pcName;
        public String state;
        public String epicNo;
        public String dob;
        public Integer age;
        public String partNo;
        public String slNoInPart;
        public String psName;
        public String partName;
        public String lastUpdate;
        public String psLatLong;
        public String rlnNameV1;
        public String rlnNameV2;
        public String rlnNameV3;
        public String sectionNo;
        public String id;
        public String nameV1;
        public String nameV2;
        public String nameV3;
        public String acNo;
        public String stCode;
        public String houseNo;
        public String pin;
    }
    
    public class ClientData {
        public String caseId;
    }

    public String invokeMethod(String loanId, String appId, String activityName) {
        return createInputMap(loanId, activityName, appId);
    }
}