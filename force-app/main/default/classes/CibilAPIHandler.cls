/**
 * @description       : Handles CIBIL API integration.
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @last modified on  : 07-18-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CibilAPIHandler implements IntegrationInterface {
    static String conLabels = 'CIBIL_API';
    public static Map<String, String> constants = Utility.getConstants(conLabels);

    @AuraEnabled
    public static Map<String, String> getConstants() {
        return constants;
    }

    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) {
        String loanApplicationId = wrapper.loanApplicationId;
        String applicantId = wrapper.recordId;
        Integer hasFivePriority =0;
        List<String> errorMessages = new List<String>();

        if (String.isBlank(applicantId)) {
            errorMessages.add('Error: Applicant Id is missing');
            return errorMessages;
        }

        List<Application_Applicant__c> applicants = [
            SELECT Id, First_Name__c, Middle_Name__c, Last_Name__c, Applicant_Type__c, Mobile_Number__c, PAN_Number__c,Loan_Application__r.StageName,Loan_Application__c,
                   Email__c, DOB__c, Mother_s_First_Name__c, Mother_s_Last_Name__c, Father_s_First_Name__c, Father_s_Last_Name__c,
                   (SELECT Id FROM Applicant_Address__r)
            FROM Application_Applicant__c
            WHERE Loan_Application__c = :loanApplicationId AND Id = :applicantId
        ];

        if (applicants.isEmpty()) {
            errorMessages.add('Error: No applicant found with the provided ID.');
        } else if (applicants[0].Applicant_Address__r.isEmpty()) {
            errorMessages.add('Error: No address found for applicant: ' + applicants[0].First_Name__c);
        }
        List<Applicant_Address__c> addressList=  new   List<Applicant_Address__c>();
        if(applicants[0].Loan_Application__r.StageName=='Credit Underwriting'){
            addressList= [SELECT City__c, Landmark__c, Pincode__r.Name ,State__c, Address_Priority__c, Building_Street_Name__c,Pincode__r.City__r.City_Code__c,Pincode__r.City__r.Country__c,Pincode__r.City__r.Name,Pincode__r.State__c,Pincode__r.City__r.State__c
                                FROM Applicant_Address__c
                                WHERE Applicant__c = :applicants[0].Id AND Pincode__c!= null];

            for(Applicant_Address__c address : addressList){
                if(address.Address_Priority__c == '5'){
                    hasFivePriority ++;
                }
            }

            if(hasFivePriority==0){
                  errorMessages.add('Error: There is no address with priority 5 for ' + applicants[0].First_Name__c);
            }
        }
        return errorMessages;
    }

    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        try {
            String applicantId = wrapper.recordId;
            String loanApplicationId = wrapper.loanApplicationId;

            List<Application_Applicant__c> applicantList = [
                SELECT Id, Mobile_Number__c, First_Name__c, PAN_Number__c, Gender__c, Middle_Name__c, Last_Name__c, Customer_Type__c,
                       Applicant_Name__c, DOB__c, Company__c, DOI__c,Loan_Application__c,Loan_Application__r.Lead__c
                FROM Application_Applicant__c
                WHERE Id = :applicantId
            ];
            Lead ld = [Select Id,Name,Requested_Loan_Amount__c from Lead where Id=:applicantList[0].Loan_Application__r.Lead__c Limit 1];
            Opportunity opes = [Select Id,Requested_Amount__c, StageName from Opportunity where Id=:applicantList[0].Loan_Application__c Limit 1];

            if (applicantList.isEmpty()) {
                throw new AuraHandledException('Applicant not found');
            }

            CIBILRequestWrapper cibilRequestWrapper = new CIBILRequestWrapper();

            List<AddressDetails> addressWrapperList = new List<AddressDetails>();
            List<Applicant_Address__c> addressList= new List<Applicant_Address__c>();
            Applicant_Address__c iterAddress = new Applicant_Address__c();
            if(opes.StageName== 'Sales Login'){
                addressList= [SELECT City__c, Landmark__c, Pincode__r.Name ,State__c, Address_Priority__c, Building_Street_Name__c,Pincode__r.City__r.City_Code__c,Pincode__r.City__r.Country__c,Pincode__r.City__r.Name,Pincode__r.State__c,Pincode__r.City__r.State__c
                                    FROM Applicant_Address__c
                                    WHERE Applicant__c = :applicantList[0].Id AND Pincode__c!= null LIMIT 1];
                if(addressList.size()>0){
                    iterAddress = addressList[0];
                }
            }else if(opes.StageName== 'Credit Underwriting'){
                addressList= [SELECT City__c, Landmark__c, Pincode__r.Name ,State__c, Address_Priority__c, Building_Street_Name__c,Pincode__r.City__r.City_Code__c,Pincode__r.City__r.Country__c,Pincode__r.City__r.Name,Pincode__r.State__c,Pincode__r.City__r.State__c
                                    FROM Applicant_Address__c
                                    WHERE Applicant__c = :applicantList[0].Id AND Pincode__c!= null];

                for(Applicant_Address__c address : addressList){
                    if(address.Address_Priority__c == '5'){
                        iterAddress= address;
                        break;
                    }
                }
                if(iterAddress== null && addressList.size()>0){
                    iterAddress = addressList[0];
                }
            }
            // Applicant_Address__c iterAddress = [
            //     SELECT City__c, Landmark__c, Pincode__r.Name ,State__c, Building_Street_Name__c,Pincode__r.City__r.City_Code__c,Pincode__r.City__r.Country__c,Pincode__r.City__r.Name,Pincode__r.State__c,Pincode__r.City__r.State__c
            //     FROM Applicant_Address__c
            //     WHERE Applicant__c = :applicantList[0].Id AND Pincode__c!= null LIMIT 1
            // ];

            AddressDetails tempaddressWrapper = new AddressDetails();
            if (iterAddress == null) {
                Opportunity op = [
                    SELECT Id, Pincode__r.Name, Pincode__r.City__r.Name,Pincode__r.State__c
                    FROM Opportunity
                    WHERE Id = :loanApplicationId LIMIT 1
                ];
                // tempaddressWrapper.city = 'PNE';
                // tempaddressWrapper.state = 'MH';
                // tempaddressWrapper.pincode = op.Pincode__r.Name;
            } else {
                tempaddressWrapper.city = iterAddress.Pincode__r.City__r.Name;
                tempaddressWrapper.state = iterAddress.Pincode__r.City__r.State__c;
                tempaddressWrapper.pincode = iterAddress.Pincode__r.Name;
                tempaddressWrapper.landmark = iterAddress.Landmark__c!=null?iterAddress.Landmark__c:'';
                tempaddressWrapper.street = iterAddress.Building_Street_Name__c!=null?iterAddress.Building_Street_Name__c:'';
            }

            tempaddressWrapper.country = iterAddress.Pincode__r.City__r.Country__c;
            String flatNumber;
            if( iterAddress.Pincode__c!=null){
                flatNumber=iterAddress.Pincode__r.City__r.Name+' '+iterAddress.Pincode__r.City__r.State__c+' '+iterAddress.Pincode__r.Name;
            }
            
            tempaddressWrapper.flatNumber = flatNumber;
            tempaddressWrapper.locality = '';
            addressWrapperList.add(tempaddressWrapper);
            System.debug('addressWrapperList : '+addressWrapperList);
            cibilRequestWrapper.addressDetails = addressWrapperList;

            PhoneDetails tempPhoneWrapper = new PhoneDetails();
            tempPhoneWrapper.mobile = applicantList[0].Mobile_Number__c;
            cibilRequestWrapper.phoneDetails = tempPhoneWrapper;

            cibilRequestWrapper.dateOfBirth = String.valueOf(applicantList[0].DOB__c);
            cibilRequestWrapper.firstName = applicantList[0].First_Name__c;
            cibilRequestWrapper.middleName = applicantList[0].Middle_Name__c != null ? applicantList[0].Middle_Name__c : '';
            cibilRequestWrapper.lastName = applicantList[0].Last_Name__c!= null ? applicantList[0].Last_Name__c : '';
            if(applicantList[0].Gender__c!=null && applicantList[0].Gender__c=='Male'){
                cibilRequestWrapper.gender = 'M';
            }
            else if(applicantList[0].Gender__c!=null && applicantList[0].Gender__c=='Female'){
                cibilRequestWrapper.gender = 'F';
            }
            else{
                cibilRequestWrapper.gender = 'OTH';
            }
           
            cibilRequestWrapper.pan = applicantList[0].PAN_Number__c;
            cibilRequestWrapper.purpose = '02';
            cibilRequestWrapper.loanAmount = opes.Requested_Amount__c;
            cibilRequestWrapper.requestsource = 'SFDC';

            // if(opes.StageName == 'Sales Login'){
                cibilRequestWrapper.retriggerCibil = false;
            // }else{
            //     cibilRequestWrapper.retriggerCibil = true;
            // }

            String requestJSON = JSON.serialize(cibilRequestWrapper);
            return requestJSON;

        } catch (Exception exp) {
            System.debug('Exception:CreateCibilPayload ' + exp.getStackTraceString());
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
    }

    public class CIBILRequestWrapper {
        public List<AddressDetails> addressDetails;
        public String dateOfBirth;
        public String firstName;
        public String gender;
        public String middleName;
        public String lastName;
        public String pan;
        public String requestsource;
        public String purpose;
        public Decimal loanAmount;
        public Boolean retriggerCibil;
        public PhoneDetails phoneDetails;
    }

    public class AddressDetails {
        public String city;
        public String country;
        public String flatNumber;
        public String landmark;
        public String locality;
        public String pincode;
        public String state;
        public String street;
    }

    public class PhoneDetails {
        public String mobile;
    }
}