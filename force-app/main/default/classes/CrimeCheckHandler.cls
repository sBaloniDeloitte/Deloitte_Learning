public with sharing class CrimeCheckHandler implements IntegrationInterface {
    
    public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String applicantId = wrapper.recordId;
        List<Application_Applicant__c> applicants = [
            SELECT Id, Applicant_Name__c, Applicant_Type__c, Mobile_Number__c, PAN_Number__c, Customer_Type__c,
            Email__c, DOB__c, Father_s_First_Name__c, Father_s_Last_Name__c,Company__c,Business_Type__c,GSTIN__c,
            (SELECT Id, Address_Type__c, Building_Street_Name__c, Town__c, Pincode__r.Name, State__c FROM Applicant_Address__r 
             WHERE Address_Type__c ='Business' OR Address_Type__c ='Permanent')
            FROM Application_Applicant__c 
            WHERE Id =:applicantId];
        
        for (Application_Applicant__c applicant : applicants) { 
            if (String.isEmpty(applicant.PAN_Number__c) && applicant.Customer_Type__c == 'Individual') {
                errorMessages.add('Error: Missing PAN Number for Applicant ' + applicant.Applicant_Name__c);
            }
            if (String.isEmpty(applicant.GSTIN__c) && applicant.Customer_Type__c != 'Individual') {
                errorMessages.add('Error: Missing GSTIN Number of ' + applicant.Company__c);
            }
            if ((applicant.Applicant_Address__r == null || applicant.Applicant_Address__r.isEmpty()) && applicant.Customer_Type__c != 'Individual') {
                errorMessages.add('Error:No address found of :' + applicant.Applicant_Name__c);
                
            } 
        }
        
        return errorMessages;
    }
    
    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();
        
        try {
            system.debug('are we inside construct??');
            
            String applicantId = wrapper.recordId;
            
            
            Integration_Details__c integrationDetails = new Integration_Details__c();
            
            List<Application_Applicant__c> applicants = [SELECT Id, Applicant_Name__c, Applicant_Type__c, Mobile_Number__c, PAN_Number__c, Customer_Type__c,Loan_Application__c,Sector__c,
                                                         Email__c, DOB__c, Father_s_First_Name__c, Father_s_Last_Name__c,Company__c,Business_Type__c,GSTIN__c,Loan_Application__r.Name,
                                                         (SELECT Id, Full_Address__c,Address_Type__c, Building_Street_Name__c, Town__c, Pincode__r.Name, State__c,Full_Address1__c FROM Applicant_Address__r 
                                                          WHERE Address_Type__c ='Business' OR Address_Type__c ='Permanent')
                                                         FROM Application_Applicant__c 
                                                         WHERE Id = :applicantId AND IsForm60Uploaded__c != 'Yes'
                                                        ];
            String requestJSON;
            if (applicants.size() > 0) {
                if(applicants[0].Customer_Type__c == 'Individual') {
                    CrimeCheckRequestIndividualWrapper iniDiwrap = new CrimeCheckRequestIndividualWrapper();
                    iniDiwrap.name = applicants[0].Applicant_Name__c;
                    iniDiwrap.panNumber = applicants[0].PAN_Number__c;
                    iniDiwrap.fatherName = applicants[0].Father_s_First_Name__c+' '+applicants[0].Father_s_Last_Name__c;
                    if(applicants[0].Applicant_Address__r != null && String.isNotBlank(applicants[0].Applicant_Address__r[0].Full_Address__c)) {
                        iniDiwrap.address = applicants[0].Applicant_Address__r[0].Full_Address__c;
                    }else if(applicants[0].Applicant_Address__r != null && String.isNotBlank(applicants[0].Applicant_Address__r[0].Full_Address1__c) && String.isBlank(iniDiwrap.address)){
                        iniDiwrap.address = applicants[0].Applicant_Address__r[0].Full_Address1__c;
                    }else {
                        iniDiwrap.address = 'No full address found';
                    }
                    
                    iniDiwrap.lan = applicants[0].Loan_Application__c;
                    iniDiwrap.dob = String.valueOf(applicants[0].DOB__c);
                    iniDiwrap.callbackUrl = URL.getOrgDomainURL().toExternalForm()+'/services/apexrest/api/crimeCheck';
                    
                    // requestJSON = JSON.serialize(iniDiwrap);

                    // String requestBody = 'name=' +applicants[0].Applicant_Name__c+
                    //  '&panNumber=' +applicants[0].PAN_Number__c+
                    //  '&fatherName=' +iniDiwrap.fatherName+
                    //  '&address=' +iniDiwrap.address +
                    //  '&lan=' +iniDiwrap.lan+
                    //  '&dob=' +iniDiwrap.dob+
                    //  '&callbackUrl='+iniDiwrap.callbackUrl;
                    
                    // requestJSON = requestBody;
                    
                    Map<String, String> formParams = new Map<String, String>{
                        'name' =>applicants[0].Applicant_Name__c,
                        'panNumber' => applicants[0].PAN_Number__c,
                        'fatherName' => iniDiwrap.fatherName,
                        'address' => iniDiwrap.address,
                        'lan' => iniDiwrap.lan,
                        'dob' => iniDiwrap.dob,
                        'callbackUrl' => iniDiwrap.callbackUrl
                    };
    
                    // Convert the form data to URL-encoded format
                    List<String> formBody = new List<String>();
                   for (String key : formParams.keySet()) {
                        String value = formParams.get(key);
                        formBody.add(
                            EncodingUtil.urlEncode(key, 'UTF-8') + '=' +
                            EncodingUtil.urlEncode(value != null ? value : '', 'UTF-8')
                        );
                    }
                    requestJSON = String.join(formBody, '&');
                }else {
                    CrimeCheckRequestCompanyWrapper nonIndiwrap = new CrimeCheckRequestCompanyWrapper();
                    nonIndiwrap.companyName = applicants[0].Applicant_Name__c;
                    nonIndiwrap.companyAddress = applicants[0].Applicant_Address__r != null ? applicants[0].Applicant_Address__r[0].Full_Address1__c:'';
                    nonIndiwrap.gstNumber = applicants[0].GSTIN__c;
                    nonIndiwrap.lan = applicants[0].Loan_Application__c;
                    nonIndiwrap.ticketSize = '';
                    nonIndiwrap.callbackUrl = URL.getOrgDomainURL().toExternalForm()+'/services/apexrest/api/crimeCheck';
                    nonIndiwrap.clientRefNo = applicants[0].Loan_Application__r.Name;
                    nonIndiwrap.companyType = applicants[0].Sector__c;
                    
                    List<Application_Applicant__c> directorsLst = [SELECT Id, Applicant_Name__c, Applicant_Type__c, Mobile_Number__c, PAN_Number__c, Customer_Type__c,Loan_Application__c,Sector__c,
                                                         Email__c, DOB__c, Father_s_First_Name__c, Father_s_Last_Name__c,Company__c,Business_Type__c,GSTIN__c,Loan_Application__r.Name,
                                                         (SELECT Id, Full_Address__c,Address_Type__c, Building_Street_Name__c, Town__c, Pincode__r.Name, State__c,Full_Address1__c FROM Applicant_Address__r 
                                                          WHERE Address_Type__c ='Business' OR Address_Type__c ='Permanent')
                                                         FROM Application_Applicant__c 
                                                         WHERE Id != :applicantId AND Loan_Application__c =:applicants[0].Loan_Application__c AND Relationship_with_Primary_Applicant__c = 'Director'
                                                        ];
                    List<CrimeCheckCompanyDirectors> directorsl = new List<CrimeCheckCompanyDirectors>();
                    if(directorsLst.size() > 0) {
                        
                        for(Application_Applicant__c iterApp : directorsLst) {
                            CrimeCheckCompanyDirectors temp = new CrimeCheckCompanyDirectors();
                            temp.name = iterApp.Applicant_Name__c;
                            temp.panNumber = iterApp.PAN_Number__c;
                            temp.fatherName = iterApp.Father_s_First_Name__c+' '+iterApp.Father_s_Last_Name__c;
                            if(iterApp.Applicant_Address__r != null && String.isNotBlank(iterApp.Applicant_Address__r[0].Full_Address__c)) {
                                temp.address = iterApp.Applicant_Address__r[0].Full_Address__c;
                            }else if(applicants[0].Applicant_Address__r != null && String.isNotBlank(iterApp.Applicant_Address__r[0].Full_Address1__c) && String.isBlank(temp.address)){
                                temp.address = iterApp.Applicant_Address__r[0].Full_Address1__c;
                            }else {
                                temp.address = 'No full address found';
                            }
                            temp.dob = String.valueOf(iterApp.DOB__c);
                            directorsl.add(temp);
                        }
                    }
                    List<List<CrimeCheckCompanyDirectors>> wrappedDirectors = new List<List<CrimeCheckCompanyDirectors>>();
                    wrappedDirectors.add(directorsl);
                    nonIndiwrap.directors = wrappedDirectors;
                    String directorsJson = JSON.serialize(nonIndiwrap.directors);
                    Map<String, String> formParams = new Map<String, String>{
                        'companyName' =>nonIndiwrap.companyName,
                        'companyAddress' => nonIndiwrap.companyAddress,
                        'gstNumber' => nonIndiwrap.gstNumber,
                        'ticketSize' => nonIndiwrap.ticketSize,
                        'clientRefNo' => nonIndiwrap.clientRefNo,
                        'companyAddress' => nonIndiwrap.companyAddress,
                        'lan' => nonIndiwrap.lan,
                        'companyType'=>nonIndiwrap.companyType,
                        'directors' =>directorsJson,
                        'callbackUrl' => nonIndiwrap.callbackUrl
                    };
    
                    // Convert the form data to URL-encoded format
                    List<String> formBody = new List<String>();
                    for (String key : formParams.keySet()) {
                        formBody.add(EncodingUtil.urlEncode(key, 'UTF-8') + '=' + EncodingUtil.urlEncode(formParams.get(key), 'UTF-8'));
                    }
                    requestJSON = String.join(formBody, '&');
                }
                
            }
            //
            System.debug('requestJSON '+requestJSON);
            return requestJSON;
            
        } catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'Createhunterpayload', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
        
    }
    public class CrimeCheckRequestIndividualWrapper {
        public String name;
        public String panNumber;
        public String fatherName;
        public String address;
        public String lan;
        public String dob;
        public String callbackUrl;
    }
    public class CrimeCheckRequestCompanyWrapper {
        public String companyName;
        public String companyAddress;
        public String companyType;
        public String gstNumber;
        public String lan;
        public String ticketSize;
        public String callbackUrl;
        public String clientRefNo;
        public List<List<CrimeCheckCompanyDirectors>> directors;
    }
    public class CrimeCheckCompanyDirectors {
        public String name;
        public String panNumber;
        public String fatherName;
        public String address;
        public String dob;
    }
}