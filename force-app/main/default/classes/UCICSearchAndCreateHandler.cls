public with sharing class UCICSearchAndCreateHandler implements IntegrationInterface {
    static string conLabels = 'UCICRequestType,Salesforce';
                         
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String loanApplicationId = wrapper.loanApplicationId;
        String panNumber = wrapper.panNumber;
        String cutomerFirstName = wrapper.customerFirstName;
        String cutomerLastName = wrapper.customerLastName;
        String applicantId = wrapper.recordId;
        System.debug('panNumber---'+panNumber);
       
        Application_Applicant__c applicant = [SELECT Id, First_Name__c, Last_Name__c,DOB__c, DOI__c,PAN_Number__c from Application_Applicant__c where id =: applicantId];
        if(String.isBlank(applicantId) || String.isBlank(loanApplicationId)){
            errorMessages.add('Error: Applicant Id is missing');
        }
        if(String.isBlank(panNumber)){
            errorMessages.add('Error: Pan number is missing for '+ applicant.First_Name__c + ' ' + applicant.Last_Name__c);
        }
        if(String.isBlank(applicant.First_Name__c)){
            errorMessages.add('Error: Applicant\'s First name is missing');
        }
        // if(String.isBlank(applicant.Last_Name__c)){
        //     errorMessages.add('Error: Applicant\'s Last name is missing');
        // }
        // if((applicant.DOB__c==null) || applicant.DOI__c==null){
        //     errorMessages.add('Error: Applicant\'s Date of Birth is missing or DOI is missing');
        // }
        return errorMessages;
    }
    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();

        try {
            String applicantId = wrapper.recordId;
            String loanApplicationId = wrapper.loanApplicationId;
            String panNumber = wrapper.panNumber;
            String requestJSON ;
            List<Application_Applicant__c> applicantList= new List<Application_Applicant__c>();
            applicantList=[Select Id,Applicant_Name__c,First_Name__c,Last_Name__c,Middle_Name__c,Customer__c,Customer__r.UCIC_Number__c,Customer__r.SF_Customer_ID__c,DOB__c,DOI__c,Email__c,Company__c,Loan_Application__c,PAN_Number__c,Customer_Type__c,Gender__c,Loan_Application__r.HL_AHL_Vertical__c from Application_Applicant__c where Loan_Application__c=:wrapper.loanApplicationId  and id=:wrapper.recordId];
            list<Applicant_Address__c> appAdd = [Select id, Address_Type__c, City__c,State__c,Pincode__r.Name,Floor_Number__c, Plot_Number__c, Building_Street_Name__c, Landmark__c from Applicant_Address__c where Applicant__c=:applicantList[0].id];
            if(applicantList[0].Customer__r.UCIC_Number__c==null){
                UCICSearchRequestServiceWrapper us = new UCICSearchRequestServiceWrapper();
                us.Request = new cls_Request();
               String vertical = applicantList[0].Loan_Application__r.HL_AHL_Vertical__c;

                us.Request.RequestId= Utility.generateRequestId(vertical);             //String.valueOf(System.currentTimeMillis());
                // us.Request.RequestId='SF123000033';
                String customerId = applicantList[0].Customer__r.SF_Customer_ID__c;
                if (customerId.startsWith('C-')) {
                    customerId = customerId.substring(2); // Remove the first 2 characters (C-)
                }
                if (!String.isBlank(customerId) && !customerId.startsWith('SF')) {
                    customerId = 'SF' + customerId;
                }
                //  requestWrap.Request.SourceCustomerID = customerId;
                us.Request.SourceCustomerID=customerId;
                us.Request.MatchingRuleProfile='2';
                us.Request.CustomerCategory = applicantList[0].Customer_Type__c == 'Individual' ? 'Retail'  : (applicantList[0].Customer_Type__c == 'Non Individual' ? 'Corporate': '');
    
                System.debug('ucicreqtype=:'+constants.get('UCICRequestType'));
                System.debug('Salesforce=:'+constants.get('Salesforce'));
                us.Request.RequestType='QA';
                us.Request.Demographics = new cls_Demographics();
                us.Request.Demographics.SourceSystem=constants.get('Salesforce');
                us.Request.Demographics.FirstName=applicantList[0].First_Name__c;
                us.Request.Demographics.MiddleName=applicantList[0].Middle_Name__c!=null?applicantList[0].Middle_Name__c:'';
                us.Request.Demographics.LastName=applicantList[0].Last_Name__c!=null?applicantList[0].Last_Name__c:'';
                // us.Request.Demographics.Dob=applicantList[0].DOB__c!=null?String.valueOf(applicantList[0].DOB__c):String.valueOf(applicantList[0].DOI__c);


                if (applicantList[0].DOB__c != null) {
                    us.Request.Demographics.Dob = String.format('{1}-{0}-{2}', 
                                        new String[]{ 
                                           
                                            String.valueOf(applicantList[0].DOB__c.month()), 
                                            String.valueOf(applicantList[0].DOB__c.day()),
                                            String.valueOf(applicantList[0].DOB__c.year())
                                           
                                            
                                        });
                }
                else{
                    us.Request.Demographics.Dob = String.format('{1}-{0}-{2}', 
                    new String[]{ 
                       
                        String.valueOf(applicantList[0].DOI__c.month()), 
                        String.valueOf(applicantList[0].DOI__c.day()),
                        String.valueOf(applicantList[0].DOI__c.year())
                       
                        
                    });
                }
                us.Request.Demographics.Gender=applicantList[0].Gender__c!=null?applicantList[0].Gender__c:'';
                us.Request.Demographics.PanNo=applicantList[0].PAN_Number__c;
                us.Request.Demographics.VoterID='';
                us.Request.Demographics.Aadhar='';
                us.Request.Demographics.PassportNo='';
                us.Request.Demographics.DrivingLicense='';
                
                us.Request.ACE= new List<cls_ACE>();
                if(appAdd.size()>0){
                for(Applicant_Address__c app:appAdd){
                        cls_ACE  adwrap = new cls_ACE();
                        adwrap.AddressType=app.Address_Type__c!=null?app.Address_Type__c:'';
                        adwrap.Address=app.Floor_Number__c+' '+app.Plot_Number__c+''+app.Building_Street_Name__c;
                        adwrap.City=app.City__c!=null?app.City__c:'';
                        adwrap.State=app.State__c!=null?app.State__c:'';
                        adwrap.Pincode=app.Pincode__r.Name!=null?app.Pincode__r.Name:'';
                        us.Request.ACE.add(adwrap);
                    }
                }
                else{
                    us.Request.ACE = new List<cls_ACE>();
                }
                requestJSON = JSON.serialize(us);
                
            }
            
            return requestJSON;
        }
        catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'Createhunterpayload', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
    }
    public class UCICSearchRequestServiceWrapper {

        public cls_Request Request;
        }
        public class cls_Request {
            public String RequestId;	//051220594
            public String SourceCustomerID;	//00010169
            public String MatchingRuleProfile;	//8
            public String CustomerCategory;
            public String RequestType;	//Q
            public cls_Demographics Demographics;
            public cls_ACE[] ACE;
        }
        public class cls_Demographics {
            public String SourceSystem;	//Salesforce
            public String FirstName;	//Salesforce
            public String MiddleName;	//
            public String LastName;	//Application
            public String Dob;	//06-12-2024
            public String Gender;	//
            public String PanNo;	//SFAPL1233T
            public String VoterID;	//
            public String PassportNo;	//
            public String Aadhar;	//
            public String DrivingLicense;	//
        }
        public class cls_ACE {
            public String AddressType;	//OFFADD
            public String Address;	//
            public String City;	//
            public String State;	//DL
            public String Country;	//IN
            public String Pincode;	//
            public String Phone;	//
            public String PhoneType;	//
            public String Email;	//
            public String EmailType;	//
        }
       
}