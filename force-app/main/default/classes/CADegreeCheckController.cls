public with sharing class CADegreeCheckController implements DynamicInvoker {

    static string conLabels = 'CA_Degree_Check';
                         
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
	
    
    @AuraEnabled
    public static String createInputMap(Id loanId, String processName, String appId) {
        System.debug('Inside createInputMap');
        System.debug('loanId: ' + loanId);
        System.debug('processName: ' + processName);
        System.debug('appId: ' + appId);
        try {
            List<Application_Applicant__c> applicants = [SELECT Id,Name, CA_Membership_Number__c FROM Application_Applicant__c 
                                                        WHERE Id = :appId AND Loan_Application__c = :loanId];
            System.debug('app>'+applicants[0]);
            System.debug('applicant ca number>'+applicants[0].CA_Membership_Number__c);
            InputWrapper inputWrapper = new InputWrapper();
            inputWrapper.loanId = loanId;
            inputWrapper.membershipnumber = applicants[0].CA_Membership_Number__c;
            inputWrapper.processName = processName;
            inputWrapper.applicantId = appId;
            String inputWrapperString = JSON.serialize(inputWrapper);

            return initiateCACheck(inputWrapper);

        } catch (Exception e) {
            throw new AuraHandledException('Error in createInputMap: ' + e.getMessage() +'at' +e.getLineNumber());
        }
    }
    @AuraEnabled 
    public static string initiateCACheck( InputWrapper inputWrapper){
        String res= 'fail';
        try {
            String resultMessage;
            String loanId = InputWrapper.loanId;
            String applicantId= InputWrapper.applicantId;
            String processName = InputWrapper.processName;
            // String processName = 'Loan CA Membership Authentication';

            // List<String> customerType = new List<String>();
            // customerType.add('Individual');

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

            // Map<String,Integration_Master__mdt> customerTypeMD = new Map<String,Integration_Master__mdt>();
            // for(Integration_Master__mdt iterMeta : metadata) {
            //     customerTypeMD.put(iterMeta.Customer_Type__c,iterMeta);
            // }

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
            wrapper.registrationNo = InputWrapper.membershipnumber; //ask Anurag about this


            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);

            Integration_Details__c integrationDetail = new Integration_Details__c();
            integrationDetail.Related_Record_Id__c = applicantId;
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                // Collect all validation errors and send back to JS
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = 'Application_applicant__c';
                
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                return resultMessage;
            }else{
                Map<String,String> integrationRequestMap = new Map<String,String>();
                integrationRequestMap.put('intSettingName','CA Degree Check');
                integrationRequestMap.put('requestJSON',respWrapper.payload);
                System.debug('request json>'+respWrapper.payload);
                String bearer=Utility.getAccessToken();
                System.debug('bearer----'+bearer);
                integrationRequestMap.put('bearer',bearer);
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
				System.debug('response>'+resp.getBody());
                // String resp= '{"result": {"name": "RAMACHANDRAN P","address": "D NO 29/3 ARUL JOTHI COMPLEX 2ND FLOOR NO 16 BINNY MAIN ROAD TIRUPUR - 641601, TAMIL NADU, INDIA","gender": "M","AssociateYear": "A2014","Qualification": "BCOM","COPStatus": "Full Time","FellowYear": "","memberStatus": "Active","mobileNo": "9894782553","email": "caramachandran@yahoo.com"},"request_id": "9d53d131-940d-46ee-90ff-9f9972afcb16","status-code": "101","clientData": {"caseId": "123456"}}';
                CADegreeCheckResponseWrapper response= (CADegreeCheckResponseWrapper)JSON.deserialize(resp.getBody(), CADegreeCheckResponseWrapper.class);

                resultMessage = 'Sucess';
                integrationDetail.Calling_Source__c = wrapper.type; 
                integrationDetail.Request_JSON__c = respWrapper.payload; 
                integrationDetail.Response_JSON__c = JSON.serialize(resp.getBody()); 
                integrationDetail.Status__c = String.valueof('200'); 
                integrationDetail.Method_Type__c = 'POST'; 
                integrationDetail.EndPoint__c = wrapper.endpoint; 
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                integrationDetail.Name = processName; 
                integrationDetail.Loan_Application__c = loanId;
				integrationDetail.Is_Success_Response__c = true;
                insert integrationDetail;
                res= 'success';
            }
        } catch (Exception e) {
            System.debug('message CA fail>'+e.getMessage() + 'at ' +e.getLineNumber());
            throw new AuraHandledException(e.getMessage() + 'at' +e.getLineNumber());
        }

        return res;
    }

    @AuraEnabled
    public static List<CADegreeCheckResponseWrapper> getCACheckdata( String loanId){
        List<CADegreeCheckResponseWrapper> caCheckWrapper= new List<CADegreeCheckResponseWrapper>();
        try {
            Map<String, String> inteToApplicant= new Map<String, String>();
            List<Integration_Details__c> integrationDetails=  Utility.getIntegrationRecordsForCreditAPIs(loanId, 'Loan CA Membership Authentication');
            for(Integration_Details__c integration: integrationDetails){
                inteToApplicant.put(integration.Id, integration.Related_Record_Id__c);
            }
            Map<Id,Application_Applicant__c> applicantList= new Map<Id,Application_Applicant__c>([SELECT Id, Name, Applicant_Name__c FROM Application_Applicant__c WHERE Id IN :inteToApplicant.values()]);
            for(Integration_Details__c inte: integrationDetails){
                CADegreeCheckResponseWrapper respWrapper = (CADegreeCheckResponseWrapper)JSON.deserialize(inte.Response_JSON__c, CADegreeCheckResponseWrapper.Class);
                Application_Applicant__c applicant = applicantList.get(inte.Related_Record_Id__c);
                respWrapper.applicantName = applicant.Name;
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
        @AuraEnabled public String membershipnumber;
        @AuraEnabled public String processName;
    }

    public class CADegreeCheckResponseWrapper{
        @AuraEnabled public String applicantName;
        @AuraEnabled public Cls_ResultWrapper result { get; set; }
        @AuraEnabled public String request_id { get; set; }
        @AuraEnabled public String status_code { get; set; }
        @AuraEnabled public ClientResponseDataWrapper clientData { get; set; }
    }

    public class Cls_ResultWrapper {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String address { get; set; }
        @AuraEnabled public String gender { get; set; }
        @AuraEnabled public String AssociateYear { get; set; }
        @AuraEnabled public String Qualification { get; set; }
        @AuraEnabled public String COPStatus { get; set; }
        @AuraEnabled public String FellowYear { get; set; }
        @AuraEnabled public String memberStatus { get; set; }
        @AuraEnabled public String mobileNo { get; set; }
        @AuraEnabled public String email { get; set; }
    }
	public String invokeMethod(String loanId, String appId, String activityName) {
        return createInputMap(loanId, activityName, appId);
    }
    public class ClientResponseDataWrapper {
        @AuraEnabled public String caseId { get; set; }
    }
}