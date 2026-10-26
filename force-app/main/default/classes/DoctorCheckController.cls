public with sharing class DoctorCheckController implements DynamicInvoker  {

    @AuraEnabled
    public static String createInputMap(Id loanId, String processName, String appId) {
        System.debug('Inside createInputMap');
        System.debug('loanId: ' + loanId);
        System.debug('processName: ' + processName);
        System.debug('appId: ' + appId);
        try {
            List<Application_Applicant__c> applicants = [SELECT Id,Name, Medical_Council_Name__c, Doctor_Registration_Number__c, Year_of_Registration__c FROM Application_Applicant__c 
                                                        WHERE Id = :appId AND Loan_Application__c = :loanId];
            InputWrapper inputWrapper = new InputWrapper();
            inputWrapper.loanId = loanId;
            inputWrapper.processName = processName;
            inputWrapper.applicantId = appId;
            inputWrapper.yearOfReg = String.valueOf(applicants[0].Year_of_Registration__c);
            inputWrapper.councilName = applicants[0].Medical_Council_Name__c;
            inputWrapper.registrationNo = applicants[0].Doctor_Registration_Number__c;
            String inputWrapperString = JSON.serialize(inputWrapper);

            return initiateDoctorCheck(inputWrapperString);

        } catch (Exception e) {
            throw new AuraHandledException('Error in createInputMap: ' + e.getMessage());
        }
    }

    static string conLabels = 'Doctor_Check';
                         
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }

    @AuraEnabled
    public static string initiateDoctorCheck( String inputWrapperString){
        String res= 'fail';
        try {

            InputWrapper inputWrapper = (InputWrapper)JSON.deserialize(inputWrapperString,InputWrapper.class);

            String resultMessage;
            String loanId = InputWrapper.loanId;
            String applicantId= InputWrapper.applicantId;
            String processName = InputWrapper.processName;
            // String processName = 'Loan Doctor Membership Authentication';

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
            wrapper.councilName = InputWrapper.councilName;
            wrapper.registrationNo = InputWrapper.registrationNo;
            wrapper.yearOfReg = InputWrapper.yearOfReg;

            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);

            Integration_Details__c integrationDetail = new Integration_Details__c();
            integrationDetail.Related_Record_Id__c = applicantId;
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                // Collect all validation errors and send back to JS
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = 'Loan_Application__c';
                
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                return resultMessage;
            }else{
                Map<String,String> integrationRequestMap = new Map<String,String>();
                integrationRequestMap.put('intSettingName','Doctor_Check');
                integrationRequestMap.put('requestJSON',respWrapper.payload);
                String bearer=Utility.getAccessToken();
                System.debug('bearer----'+bearer);
                integrationRequestMap.put('bearer',bearer);
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
				System.debug('resp: '+resp);
                // String resp='{"requestId": "8c227db3-1969-474d-a19d-a1d9de0d24bb","result": {"doctorId": "1000082","additionalAddresses": "","additionalQualifications": [{"qualification": "","qualificationYear": "","university": "","college": ""},{"qualification": "","qualificationYear": "","university": "","college": ""},{"qualification": "","qualificationYear": "","university": "","college": ""}],"address": "C/O. SHIVAJI BHAGAT , C-1-304 , VALLEY TOWERS , KHEVRA CIRCLE , POKHRAN ROAD-2 , MANPADA , THANE - 400607","category": "","dateOfBirth": "06-09-1986","dateOfRegistration": "07-10-2010","fatherName": "BHAGAT SHIVAJI LAHANUJI","firstName": "","husbandName": "","isNewlyRegisteredDoctor": false,"name": "BHAGAT (Ms.) PRIYANKA SHIVAJI","qualification": {"qualification": "MBBS","qualificationYear": "2010","university": "U.Maha.Health Sciences, Nashik","college": ""},"registrationNumber": "2010103028","removedStatus": true,"restoredOn": "14-11-2023","restoredStatus": true,"stateMedicalCouncil": "Maharashtra Medical Council","stateMedicalCouncilId": "16","uniquePermanentRegistrationNumber": "","yearOfInfo": "2010","yearOfPassing": "2010","isBlacklistedDoctor": true,"suspensions": [{"suspensionDate": "15/11/2018","restorationDate": "14/11/2023","remarks": "Vide Order no. MMC/DC/CPS/02/2018/2018/03879 dated 15.11.2018"}]},"statusCode": 101,"clientData": {"caseId": "123456"}}';
                
                // DoctorCheckResponseWrapper response= (DoctorCheckResponseWrapper)JSON.deserialize(resp.getBody(), DoctorCheckResponseWrapper.class);
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
                integrationDetail.Related_Record_Id__c = applicantId;
                integrationDetail.Is_Success_Response__c = true;

                insert integrationDetail;
                res= 'success';
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return res;
    }

    @AuraEnabled
    public static List<DoctorCheckResponseWrapper> getDoctorCheckData( String loanId){
        List<DoctorCheckResponseWrapper> docCheckWrapperList= new List<DoctorCheckResponseWrapper>();
        try {
            Map<String, String> inteToApplicant= new Map<String, String>();
            List<Integration_Details__c> integrationDetails=  Utility.getIntegrationRecordsForCreditAPIs(loanId, 'Loan Doctor Membership Authentication');
            for(Integration_Details__c integration: integrationDetails){
                inteToApplicant.put(integration.Id, integration.Related_Record_Id__c);
            }
            Map<Id,Application_Applicant__c> applicantList= new Map<Id,Application_Applicant__c>([SELECT Id, Name, Applicant_Name__c FROM Application_Applicant__c WHERE Id IN :inteToApplicant.values()]);
            for(Integration_Details__c inte: integrationDetails){
                system.debug('150');
                String cleanJson = inte.Response_JSON__c.replace('\\"','"').replace('"{','{').replace('}"','}');
                DoctorCheckResponseWrapper respWrapper = (DoctorCheckResponseWrapper)JSON.deserialize(cleanJson, DoctorCheckResponseWrapper.Class);
                system.debug('respWrapper: '+JSON.serialize(respWrapper));
                Application_Applicant__c applicant = applicantList.get(inte.Related_Record_Id__c);
                respWrapper.applicantName = applicant.Name;
                docCheckWrapperList.add(respWrapper);

                List<Cls_QualificationWrapper> additionalQualifications= respWrapper.result.additionalQualifications;
                if(additionalQualifications.size()>0){
                    Integer count=1;
                    for(Cls_QualificationWrapper qual: additionalQualifications){
                        qual.srno = count;
                        count = count+1;
                    }
                }

                List<Cls_SuspensionWrapper> suspensions= respWrapper.result.suspensions;
                if(suspensions.size()>0){
                    Integer count=1;
                    for(Cls_SuspensionWrapper qual: suspensions){
                        qual.srno = count;
                        count = count+1;
                    }
                }

            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return docCheckWrapperList;
    }

    public class InputWrapper{
        @AuraEnabled public String loanId;
        @AuraEnabled public String applicantId;
        @AuraEnabled public String councilName;
        @AuraEnabled public String registrationNo;
        @AuraEnabled public String yearOfReg;
        @AuraEnabled public String processName;
    }

    public class  DoctorCheckResponseWrapper{
        @AuraEnabled public String applicantName;
        @AuraEnabled public String requestId { get; set; }
        @AuraEnabled public Cls_ResultWrapper result { get; set; }
        @AuraEnabled public Integer statusCode { get; set; }
        @AuraEnabled public ClientResponseDataWrapper clientData { get; set; }
    }

    public class Cls_ResultWrapper {
        @AuraEnabled public String doctorId { get; set; }
        @AuraEnabled public String additionalAddresses { get; set; }
        @AuraEnabled public List<Cls_QualificationWrapper> additionalQualifications { get; set; }
        @AuraEnabled public String address { get; set; }
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public String dateOfBirth { get; set; }
        @AuraEnabled public String dateOfRegistration { get; set; }
        @AuraEnabled public String fatherName { get; set; }
        @AuraEnabled public String firstName { get; set; }
        @AuraEnabled public String husbandName { get; set; }
        @AuraEnabled public Boolean isNewlyRegisteredDoctor { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Cls_QualificationWrapper qualification { get; set; }
        @AuraEnabled public String registrationNumber { get; set; }
        @AuraEnabled public Boolean removedStatus { get; set; }
        @AuraEnabled public String restoredOn { get; set; }
        @AuraEnabled public Boolean restoredStatus { get; set; }
        @AuraEnabled public String stateMedicalCouncil { get; set; }
        @AuraEnabled public String stateMedicalCouncilId { get; set; }
        @AuraEnabled public String uniquePermanentRegistrationNumber { get; set; }
        @AuraEnabled public String yearOfInfo { get; set; }
        @AuraEnabled public String yearOfPassing { get; set; }
        @AuraEnabled public Boolean isBlacklistedDoctor { get; set; }
        @AuraEnabled public List<Cls_SuspensionWrapper> suspensions { get; set; }
    }

    public class Cls_QualificationWrapper {
        @AuraEnabled public Integer srno { get; set; }
        @AuraEnabled public String qualification { get; set; }
        @AuraEnabled public String qualificationYear { get; set; }
        @AuraEnabled public String university { get; set; }
        @AuraEnabled public String college { get; set; }
    }

    public class Cls_SuspensionWrapper {
        @AuraEnabled public Integer srno { get; set; }
        @AuraEnabled public String suspensionDate { get; set; }
        @AuraEnabled public String restorationDate { get; set; }
        @AuraEnabled public String remarks { get; set; }
    }

    public class ClientResponseDataWrapper {
        @AuraEnabled public String caseId { get; set; }
    }
    public String invokeMethod(String loanId, String appId, String activityName) {
        return createInputMap(loanId, activityName, appId);
    }
}