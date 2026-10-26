public with sharing class COMM_DeDupeHandler implements IntegrationInterface {

    static string conLabels = 'MatchingCustomerRule,DeDupeRequestType,Salesforce';
                         
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
        String voterNumber = wrapper.voterNumber;
        String dlNumber = wrapper.dlNumber;
        String passportNumber = wrapper.passportNumber;
        String aadhaarNumber = wrapper.aadharNumber;
        String customerDOB = wrapper.customerDOB != null ? String.valueOf(wrapper.customerDOB) : '';
        //HL-Ishi-31/10
        Boolean isforFL = wrapper.isforFL;
        //HL-Ishi-31/10
        //Application_Applicant__c applicant = [SELECT Id, First_Name__c, Customer__r.SF_Customer_ID__c,Last_Name__c, PAN_Number__c from Application_Applicant__c where id =: applicantId];
        if(!isforFL && String.isBlank(applicantId) && String.isBlank(loanApplicationId)){
            errorMessages.add('Error: Applicant Id is missing');
        }
        if(!isforFL && String.isBlank(cutomerFirstName)){
            errorMessages.add('Error: Applicant\'s First name is missing');
        }
        // if(String.isBlank(cutomerLastName)){
        //     errorMessages.add('Error: Applicant\'s last name is missing');
        // }
        if(!isforFL && String.isBlank(panNumber) && String.isBlank(voterNumber) && String.isBlank(dlNumber) && String.isBlank(passportNumber) && String.isBlank(aadhaarNumber)){
            errorMessages.add('Error: Please add at least one amount Pan,VoterId,Driving License,Passport Number,Aadhaar Number');
        }
        if(!isforFL && customerDOB==null){
           errorMessages.add('Error: DOB is missing for '+ cutomerFirstName + ' ' + cutomerLastName);
        }
        return errorMessages;
    }

    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        System.debug('wrapper in DeDupeHandler'+wrapper);
        try {
            String applicantId = wrapper.recordId;
            String panNumber = wrapper.panNumber != null ? wrapper.panNumber : '';
            String customerFirstName = wrapper.customerFirstName != null ? wrapper.customerFirstName : '';
            String customerLastName = wrapper.customerLastName != null ? wrapper.customerLastName : '';
            String voterNumber = wrapper.voterNumber != null ? wrapper.voterNumber : '';
            String aadharNumber = wrapper.aadharNumber != null ? wrapper.aadharNumber : '';
            String passportNumber = wrapper.passportNumber != null ? wrapper.passportNumber : '';
            String dlNumber = wrapper.dlNumber != null ? wrapper.dlNumber : '';
            String gender = wrapper.gender != null ? wrapper.gender : '';
            //HL-Ishi-31/10
            Boolean isforFL = wrapper.isforFL;
            //HL-Ishi-31/10

             Application_Applicant__c applicant = new Application_Applicant__c();
             List<Applicant_Address__c> addresses = new List<Applicant_Address__c>();
    
            // Get Applicant with required fields
            if(!isforFL && applicantId != null && applicantId != ''){
                applicant = [
                    SELECT Id, First_Name__c, Last_Name__c, Gender__c, Mobile_Number__c,Customer_Type__c,
                        Voter_ID_Number__c, Drivers_License_Number__c, Passport_Number__c, Aadhaar_Number__c, PAN_Number__c,
                        Customer__r.SF_Customer_ID__c,Email__c,Loan_Application__r.HL_AHL_Vertical__c
                    FROM Application_Applicant__c 
                    WHERE Id = :applicantId
                ];
        
                // Get related addresses
                addresses = [
                    SELECT Address_Type__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c,
                        Pincode__r.Name
                    FROM Applicant_Address__c 
                    WHERE Applicant__c = :applicantId
                ];
            }
    
            // Start building the request wrapper
            RequestWrapper requestWrap = new RequestWrapper();
            requestWrap.Request = new Request();
            String vertical = applicant.Loan_Application__r.HL_AHL_Vertical__c;
            requestWrap.Request.RequestId = Utility.generateRequestId(vertical);                        //String.valueOf(System.currentTimeMillis());
             String customerId = '';
           if(!isforFL && applicantId != null && applicantId != ''){
            customerId = (applicant.Customer__r != null && applicant.Customer__r.SF_Customer_ID__c != null)
                                ? applicant.Customer__r.SF_Customer_ID__c : '';
            if (customerId.startsWith('C-')) {
                customerId = customerId.substring(2);
            }
           }else{
            customerId = String.valueOf(System.currentTimeMillis());
           }
            if (!String.isBlank(customerId) && !customerId.startsWith('SF')) {
                customerId = 'SF' + customerId;
            }
            requestWrap.Request.SourceCustomerID = customerId;
    
            requestWrap.Request.MatchingRuleProfile = constants.get('MatchingCustomerRule');
            requestWrap.Request.RequestType = constants.get('DeDupeRequestType');
            requestWrap.Request.CustomerCategory = applicant.Customer_Type__c == 'Individual' ? 'RETAIL' : 'CORP'; 
    
            // Fill Demographics with null checks
            Demographics demographics = new Demographics();
            demographics.SourceSystem = 'GHF';
            demographics.FirstName = customerFirstName;
            demographics.LastName = customerLastName;
            demographics.PanNo = panNumber;
            demographics.VoterID = voterNumber;
            demographics.DrivingLicense = dlNumber;
            demographics.PassportNo = passportNumber;
            demographics.Aadhar = aadharNumber;
            demographics.Gender = gender; //String.isNotBlank(applicant.Gender__c) ? applicant.Gender__c : '';
    
            if (wrapper.customerDOB != null) {
                demographics.Dob = String.format('{0}-{1}-{2}', 
                    new String[]{
                        String.valueOf(wrapper.customerDOB.day()),
                        String.valueOf(wrapper.customerDOB.month()),
                        String.valueOf(wrapper.customerDOB.year())
                    }
                );
            } else {
                demographics.Dob = '';
            }
    
            requestWrap.Request.Demographics = demographics;
            List<ACEWrapper> aceList = new List<ACEWrapper>();

             if(!isforFL && applicantId != null && applicantId != ''){
                // Build ACE list from addresses with null checks
                // List<ACEWrapper> aceList = new List<ACEWrapper>();
                for (Applicant_Address__c addr : addresses) {
                    ACEWrapper ace = new ACEWrapper();
                    ace.AddressType = String.isNotBlank(addr.Address_Type__c) ? addr.Address_Type__c : '';
        
                    List<String> addrParts = new List<String>();
                    if (String.isNotBlank(addr.Address_Line_1__c)) addrParts.add(addr.Address_Line_1__c);
                    if (String.isNotBlank(addr.Address_Line_2__c)) addrParts.add(addr.Address_Line_2__c);
                    if (String.isNotBlank(addr.Address_Line_3__c)) addrParts.add(addr.Address_Line_3__c);
                    ace.Address = addrParts.isEmpty() ? '' : String.join(addrParts, ', ');
        
                    ace.Country = 'IN';
                    ace.Pincode = (addr.Pincode__r != null && String.isNotBlank(addr.Pincode__r.Name)) ? addr.Pincode__r.Name : '';
        
                    ace.City = '';       // Update if city is available
                    ace.State = '';      // Update if state is available
                    ace.Phone = String.isNotBlank(applicant.Mobile_Number__c) ? applicant.Mobile_Number__c : '';
                    ace.PhoneType = String.isNotBlank(ace.Phone) ? 'Mobile' : '';
                    ace.Email = '';      // Update if email is available
                    ace.EmailType = '';
        
                    aceList.add(ace);
                }
                
            }
            if(aceList.isEmpty()){
                ACEWrapper ace = new ACEWrapper();
                ace.AddressType = '';
    
                
                ace.Address ='';
    
                ace.Country = '';
                ace.Pincode =  '';
    
                ace.City = '';       // Update if city is available
                ace.State = '';      // Update if state is available
                ace.Phone =  '';
                ace.PhoneType ='';
                ace.Email = '';      // Update if email is available
                ace.EmailType = '';
    
                aceList.add(ace);
            }
    
            requestWrap.Request.ACE = aceList;
    
            String requestJSON = JSON.serialize(requestWrap);
            System.debug('Final Payload JSON: ' + requestJSON);
            return requestJSON;
    
        } catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{
                Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'CreateHunterPayload', '', '')
            });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
    }
    


    public class RequestWrapper {
        public Request Request;
    }

    public class Request {
        public String RequestId;              // Unique request ID
        public String SourceCustomerID;       // Source customer ID
        public String MatchingRuleProfile;    // Matching rule profile ID
        public String RequestType;             // Type of request ('Q')
        public String CustomerCategory;  //New Tag Added         
        public Demographics Demographics;     // Demographics details
        public List<ACEWrapper> ACE;          // ACE details (address, etc.)
    }

    public class Demographics {
        public String SourceSystem;           // Source system name
        public String FirstName;              // First name
        public String MiddleName;             // Middle name (optional)
        public String LastName;               // Last name
        public String Dob;                    // Date of birth
        public String Gender;                 // Gender
        public String PanNo;                  // PAN number
        public String VoterID;                // Voter ID (optional)
        public String PassportNo;             // Passport number (optional)
        public String Aadhar;                 // Aadhaar number (optional)
        public String DrivingLicense;         // Driving license number (optional)
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


}