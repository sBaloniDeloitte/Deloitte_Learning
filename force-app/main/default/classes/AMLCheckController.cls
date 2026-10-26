public with sharing class AMLCheckController {
    
    @AuraEnabled
    public static List<DetailsWrapper> getApplicantInformation(String recordId){
        List<DetailsWrapper> applicantDetails = new List<DetailsWrapper>();
        try {
            String amlCheckRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','AML_Check');

            List<Application_Applicant__c> applicantList = [SELECT id,Applicant_Name__c,Customer_Type__c,Business_Type__c,Company__c,GSTIN__c
                                                        FROM Application_Applicant__c WHERE Loan_Application__c =: recordId]; 
            
            List<Application_Verification__c> lstApplicationVerification = [SELECT id,Completion_Date__c,
                                                        Crimewatch__c,Request_Time__c,Risk_Type__c,Crime_Check_File_Link__c,
                                                        Crime_Check_Request_Id__c,Number_of_Cases__c,Any_Remarks_Reasons__c,toLabel(AML_Status_Code__c),
                                                        Crime_Check_Status__c, Applicant__c,Disposition__c,Verification_Remarks__c
                                                        FROM Application_Verification__c 
                                                        WHERE Loan_Application__c =: recordId AND
                                                        recordTypeId =: amlCheckRecordTypeId] ;
            
            Map<String,Application_Verification__c> applicantIdAVMap = new Map<String,Application_Verification__c>();
            Map<String,String> appDocIdMap = new  Map<String,String>();
            if(lstApplicationVerification.size() > 0) {
                for(Application_Verification__c iterAP : lstApplicationVerification) {
                    applicantIdAVMap.put(iterAP.Applicant__c,iterAP);
                }
                
                List<Document_Details__c> docDetails = [SELECT id,Content_Document_Id__c,Application_Verification__r.Applicant__c FROM Document_Details__c WHERE Application_Verification__c IN :lstApplicationVerification];
                for(Document_Details__c docIter : docDetails) {
                    appDocIdMap.put(docIter.Application_Verification__r.Applicant__c,docIter.Content_Document_Id__c);
                }
            }
            
            if(applicantList.size()>0){
                for(Application_Applicant__c applicant : applicantList){
                    DetailsWrapper tempObj = new DetailsWrapper();
                    tempObj.applicantCompName = applicant.Applicant_Name__c;
                    tempObj.applicantId = applicant.id;
                    tempObj.apiStatus = 'Not Initiated';
                    if(applicantIdAVMap.containsKey(applicant.id)) {
                        tempObj.isInitiated = true;

                        Application_Verification__c tempAV = applicantIdAVMap.get(applicant.id);
                        tempObj.apiStatus = tempAV.Crime_Check_Status__c != null ? tempAV.Crime_Check_Status__c: 'Pending';
                        tempObj.amlStatus = tempAV.AML_Status_Code__c;
                        
                        if(tempAV.Crime_Check_Status__c == 'Completed') {
                            tempObj.isCompleted = true;
                            tempObj.appVerificationId = tempAV.id;
                            tempObj.docId = appDocIdMap.containsKey(applicant.Id)?appDocIdMap.get(applicant.Id):'';
                        }else {
                            tempObj.isCompleted = false;
                        }
                    }else {
                        tempObj.isInitiated = false;
                    }
                    applicantDetails.add(tempObj);
                    System.debug('applicantDetails' + applicantDetails);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        return applicantDetails;
        
    }
    
    @AuraEnabled
    public static String initiateAMLCheck(List<String> applicantIds, String recordId) {
        String res = 'success';
        try {
            String processName = 'AML Check';
            for(String appId:applicantIds){
                callAMLCheck(appId, processName, recordId);
            }
        } catch (Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'AMLCheckController', '', '') });
            throw new AuraHandledException(e.getMessage());
        }
        return res;
    }

   // @future(callout=true)
    public static void callAMLCheck(String appId, String processName, String loanId) {
        try {
            List<Application_Applicant__c> applicantsList = [
                SELECT Id, Applicant_Name__c, DOB__c, Gender__c, Customer_Type__c, First_Name__c, Last_Name__c,
                    PAN_Number__c, Masked_Aadhar_Number__c, Passport_Number__c, Loan_Application__c, GSTIN__c,
                    Email__c, Mobile_Number__c, Name_of_Organization__c
                FROM Application_Applicant__c
                WHERE Id = :appId AND Applicant_Type__c != 'Guarantor'
            ];

            if (applicantsList.isEmpty()) {
                return;
            }

            Application_Applicant__c applicant = applicantsList[0];

            // 1. Fixed Ternary Operators and String literals with proper quotes
            String birthYearStr = applicant.DOB__c != null ? String.valueOf(applicant.DOB__c.year()) : '1995';
            String birthDateStr = applicant.DOB__c != null ? Datetime.newInstance(applicant.DOB__c, Time.newInstance(0,0,0,0)).format('dd-MM-yyyy') : '06-04-1995';
            String panStr = applicant.PAN_Number__c != null ? applicant.PAN_Number__c : 'AAAPA1334A';
            String nameStr = applicant.Applicant_Name__c != null ? applicant.Applicant_Name__c : 'Sample Applicant';
            String phoneStr = applicant.Mobile_Number__c != null ? applicant.Mobile_Number__c : '8639930471';
            String emailStr = applicant.Email__c != null ? applicant.Email__c : 'demo.user@company.com';
            
            String mockRequestPayload = '{"DG":[{"SOURCE_SYSTEM":"SFDC-BL-LOS-UAT","Passport":"","PAN":"' + panStr + '","Name":"' + nameStr + '","DrivingLicenseNumber":"","DirectorNameList":null,"DirectorIDList":null,"CompanyName":"NA","CompanyIdentifier":"","BirthYear":"' + birthYearStr + '","BirthPlace":"","BirthDate":"' + birthDateStr + '","AADHAAR":""}],"clientTxnIdentifier":"SFDC-BL-LOS-UAT","ACE":[{"Pincode":"400080","Phone":"' + phoneStr + '","EmailID":"' + emailStr + '","City":"Mumbai","AddressType":"Permanent","Address":"Demo Address Layout, Mumbai, Maharashtra, 400080"}]}';

            // 2. Exact Response JSON string format 
            String mockResponsePayload = '{"screen_request_id":"Xdt7H2frzTcWkMO","match_count":0,"matches":null,"error_message":"","statusCode":200}';

            // 3. Insert Mock Application Verification Records (To toggle UI state immediately)
            String amlCheckRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c', 'AML_Check');
            
            Application_Verification__c mockVerification = new Application_Verification__c();
            mockVerification.Loan_Application__c = loanId;
            mockVerification.Applicant__c = applicant.Id;
            mockVerification.RecordTypeId = amlCheckRecordTypeId;
            mockVerification.Crime_Check_Status__c = 'Completed'; 
            mockVerification.AML_Status_Code__c = '200';       
            mockVerification.Completion_Date__c = System.today();
            mockVerification.Risk_Type__c = 'Low';
            mockVerification.Number_of_Cases__c = 0;
            mockVerification.Verification_Remarks__c = 'Demo Log: Match count is 0. System status clear.';
            insert mockVerification;

            // 4. Insert Mock Integration Tracking Log Record using exact formats
            Integration_Details__c integrationDetail = new Integration_Details__c();
            integrationDetail.Related_Record_Id__c = applicant.Id;
            integrationDetail.Status__c = '200'; 
            integrationDetail.Name = processName;
            integrationDetail.Object_Name__c = 'Application_Applicant__c';
            integrationDetail.Method_Type__c = 'POST';
            integrationDetail.EndPoint__c = 'https://mockenvironment.internal';
            integrationDetail.Request_JSON__c = mockRequestPayload;
            integrationDetail.Response_JSON__c = mockResponsePayload;
            integrationDetail.Loan_Application__c = loanId;
            integrationDetail.Calling_Source__c = processName;
            insert integrationDetail;

        } catch (Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'AMLCheckController', '', '') });
            throw new AuraHandledException(e.getMessage());
        }
    }

    // 5. Added the missing DetailsWrapper structure required by your UI 
    public class DetailsWrapper {
        @AuraEnabled public String applicantCompName {get;set;}
        @AuraEnabled public String applicantId {get;set;}
        @AuraEnabled public String apiStatus {get;set;}
        @AuraEnabled public String amlStatus {get;set;}
        @AuraEnabled public Boolean isInitiated {get;set;}
        @AuraEnabled public Boolean isCompleted {get;set;}
        @AuraEnabled public String appVerificationId {get;set;}
        @AuraEnabled public String docId {get;set;}
    }
}