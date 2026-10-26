public with sharing class HunterHandler implements IntegrationInterface {

    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String loanApplicationId = wrapper.loanApplicationId;
        List<Application_Applicant__c> applicants = [
            SELECT Id, First_Name__c, Middle_Name__c, Last_Name__c, Applicant_Type__c, Mobile_Number__c, PAN_Number__c, 
                Email__c, DOB__c, Mother_s_First_Name__c, Mother_s_Last_Name__c, Father_s_First_Name__c, Father_s_Last_Name__c,
                (SELECT Id, Address_Type__c, Building_Street_Name__c, Town__c, Pincode__r.Name, State__c,Address_Source__c,Document_Details__c FROM Applicant_Address__r where Address_Type__c != 'BSA' AND Address_Type__c!=null)
            FROM Application_Applicant__c 
            WHERE Loan_Application__c = :loanApplicationId AND Applicant_Type__c != 'Guarantor'
        ];

        for (Application_Applicant__c applicant : applicants) { 
            if (String.isEmpty(applicant.PAN_Number__c)) {
                errorMessages.add('Error: Missing PAN Number for Applicant ' + applicant.First_Name__c + ' ' + applicant.Last_Name__c);
            }
            if (applicant.Applicant_Address__r == null || applicant.Applicant_Address__r.isEmpty()) {
                errorMessages.add('Error:No address found for applicant:' + applicant.First_Name__c);
                System.debug('No address found for applicant: ' + applicant.First_Name__c);
            } 
            if (applicant.Applicant_Address__r != null) {
                for (Applicant_Address__c addr : applicant.Applicant_Address__r) {
                    if(!(addr.Address_Source__c == 'Manual' && addr.Address_Type__c == 'Current' && addr.Document_Details__c==null)){
                        if (addr.Pincode__r == null || String.isEmpty(addr.Pincode__r.Name)) {
                            errorMessages.add('Error: Missing Pincode for address of applicant: ' + applicant.First_Name__c);
                            System.debug('Missing Pincode for address of applicant: ' + applicant.First_Name__c);
                        }
                    }
                    
                }
            } 
        }

        return errorMessages;
    }

    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();

        try {
            Map<String, List<Integration_Mapping__mdt>> groupByMap = new Map<String, List<Integration_Mapping__mdt>>();

            // Fetch all the records from Integration_Mapping__mdt
            List<Integration_Mapping__mdt> integrationMappings = [SELECT id, API_Name__c, GroupBy__c, Source_Value__c, Target_Value__c 
                                                                FROM Integration_Mapping__mdt];
        
            // Group the records by GroupBy__c and store them in the map
            for (Integration_Mapping__mdt mapping : integrationMappings) {
                if (!groupByMap.containsKey(mapping.GroupBy__c)) {
                    groupByMap.put(mapping.GroupBy__c, new List<Integration_Mapping__mdt>());
                }
                groupByMap.get(mapping.GroupBy__c).add(mapping);
            }
            system.debug('are we inside construct??');
            String appproductCode = '';
            if (groupByMap.containsKey('Constant')) {
                for (Integration_Mapping__mdt mapping : groupByMap.get('Constant')) {
                    if (mapping.Source_Value__c == 'HL_IND') {
                        appproductCode = mapping.Target_Value__c;
                        break; 
                    }
                }
            }

            HunterRequestWrapper request = new HunterRequestWrapper();
            string loanid = wrapper.loanApplicationId;
            request.applicationName = 'VSJ';  
            request.entity = 'NBFC';        
            request.appproductCode = appproductCode;
            request.loanReference = loanid;
            
            Integration_Details__c integrationDetails = new Integration_Details__c();
            
            List<Application_Applicant__c> appApplicantsOnLoan1 = [
                SELECT id, First_Name__c, Middle_Name__c, Last_Name__c, Applicant_Type__c,Name_of_Organization__c,Customer_Type__c, Mobile_Number__c, PAN_Number__c, 
                Email__c, DOB__c, Mother_s_First_Name__c, Mother_s_Last_Name__c, Father_s_First_Name__c, Father_s_Last_Name__c,
                (SELECT id, Address_Type__c, Building_Street_Name__c, Town__c, Pincode__r.name, State__c , City__c ,Address_Line_1__c,Address_Source__c,Document_Details__c  FROM Applicant_Address__r WHERE Address_Type__c != 'BSA' AND Address_Line_1__c != null)
                FROM Application_Applicant__c WHERE Loan_Application__c = :loanid AND Applicant_Type__c != 'Guarantor'
            ];
            List<ClsContacts> contacts1 = new List<ClsContacts>();
            
            for (Application_Applicant__c app : appApplicantsOnLoan1) {
                
                // Null check for Applicant_Address__r and its first element
                // 
                system.debug( 'app.Applicant_Address__r -->' + app.Applicant_Address__r );
                string state = '';
                if (app.Applicant_Address__r != null && !app.Applicant_Address__r.isEmpty()) {
                    state = app.Applicant_Address__r[0].State__c != null ? app.Applicant_Address__r[0].State__c.replace(' ','_') : '';
                }
                string statename = '';
                if (state != null) {
                    statename = Constants__mdt.getInstance(state).value__c;
                }
                string country = null;
                    if (groupByMap.containsKey('Country')) {
                        Integration_Mapping__mdt countryMapping = groupByMap.get('Country')[0];
                        if (countryMapping.Source_Value__c == 'India') {
                            country = countryMapping.Target_Value__c;
                        }
                    }
                    ClsContacts contactObj = new ClsContacts();
                
                // Null checks for each of these fields
                string firstName;
                string middleName;
                string lastName;
                string applicantType;
                if( app.Customer_Type__c != 'Non Individual')
                {
                 firstName = app.First_Name__c != null ? app.First_Name__c : null;
                 middleName = app.Middle_Name__c != null ? app.Middle_Name__c : null;
                 lastName = app.Last_Name__c != null ? app.Last_Name__c : null;
                 applicantType = app.Applicant_Type__c != null ? app.Applicant_Type__c : null;
                }
                else {
                     firstName = app.Name_of_Organization__c != null ? app.Name_of_Organization__c : null;
                     middleName = app.Middle_Name__c != null ? app.Middle_Name__c : null;
                     lastName = app.Last_Name__c != null ? app.Last_Name__c : null;
                }
                    cls_personNames applicant = new cls_personNames(
                    /*applicantType*/'CURRENT', firstName, middleName, lastName
                    );
                    contactObj.personNames = new List<cls_personNames> { applicant };
                        
                // Null check for Applicant_Address__r and nested fields
                //contactObj.addresses1 = new List<cls_addresses1>();
                // if (app.Applicant_Address__r != null && !app.Applicant_Address__r.isEmpty()) {
                //     contactObj.addresses1.add(new cls_addresses1(
                //         app.Applicant_Address__r[0].Address_Type__c != null ? app.Applicant_Address__r[0].Address_Type__c : null,
                //         app.Applicant_Address__r[0].Building_Street_Name__c != null ? app.Applicant_Address__r[0].Building_Street_Name__c : null,
                //         app.Applicant_Address__r[0].Building_Street_Name__c != null ? app.Applicant_Address__r[0].Building_Street_Name__c : null,
                //         null, null, 
                //         app.Applicant_Address__r[0].City__c != null ? app.Applicant_Address__r[0].City__c : null,
                //         app.Applicant_Address__r[0].Pincode__r != null && app.Applicant_Address__r[0].Pincode__r.name != null ? app.Applicant_Address__r[0].Pincode__r.name : null,
                //         statename, country
                //     ));
                // }
                contactObj.addresses1 = new List<cls_addresses1>();

                // Loop through all addresses related to this applicant
                if (app.Applicant_Address__r != null && !app.Applicant_Address__r.isEmpty()) {
                    for (Applicant_Address__c addr : app.Applicant_Address__r) {
                        
                        if(!(addr.Address_Source__c == 'Manual' && addr.Address_Type__c == 'Current' && addr.Document_Details__c==null)){
                            
                        
                    contactObj.addresses1.add(new cls_addresses1(
                            addr.Address_Type__c != null ? addr.Address_Type__c : null,
                            addr.Building_Street_Name__c != null ? addr.Building_Street_Name__c : null,
                            addr.Building_Street_Name__c != null ? addr.Building_Street_Name__c : null,
                            null,
                            null,
                            addr.City__c != null ? addr.City__c : null,
                            addr.Pincode__r != null ? addr.Pincode__r.name : null,
                            addr.State__c != null ? addr.State__c.replace(' ', '_') : statename,
                            country
                    ));
                    }
                }
                }
                
                // Null check for mobile number
                contactObj.telephones = new List<cls_telephones>();
                if (app.Mobile_Number__c != null) {
                    contactObj.telephones.add(new cls_telephones(app.Mobile_Number__c, 'MOBILE'));
                }
                
                // Null check for PAN number
                contactObj.identityDoc = new List<cls_identityDoc>();
                if (app.PAN_Number__c != null) {
                    contactObj.identityDoc.add(new cls_identityDoc(app.PAN_Number__c, 'PAN'));
                }
                
                // Null check for email
                contactObj.emails1 = new List<cls_emails1>();
                if (app.Email__c != null) {
                    contactObj.emails1.add(new cls_emails1('PER', app.Email__c));
                }
                
                // Null check for DOB
                Date dob = app.DOB__c != null ? Date.valueOf(app.DOB__c) : null;
                string motherName = (app.Mother_s_First_Name__c != null && app.Mother_s_Last_Name__c != null) 
                                     ? app.Mother_s_First_Name__c + ' ' + app.Mother_s_Last_Name__c : '';
                string fatherName = (app.Father_s_First_Name__c != null && app.Father_s_Last_Name__c != null) 
                                     ? app.Father_s_First_Name__c + ' ' + app.Father_s_Last_Name__c : null;
                                                                    contactObj.personDetails = new cls_personDetails(
                    'CURRENT', dob, motherName, fatherName
                );
                
                // Null check for empHistory and employerTelephones
                contactObj.empHistory = new List<cls_empHistory>();
                contactObj.empHistory.add(new cls_empHistory(null, new cls_empAddress(), null));

                contactObj.employerTelephones = new List<cls_employerTelephones>();
                contactObj.employerTelephones.add(new cls_employerTelephones());
                
                // Null check for Applicant_Type__c before adding to applicants
                                                                        if (app.Applicant_Type__c == 'Primary Applicant') {
                    contactObj.applicants = new List<cls_applicants> { new cls_applicants('MAIN_APPLICANT') };
                                                                                        } else if (app.Applicant_Type__c == 'Co Applicant') {
                    contactObj.applicants = new List<cls_applicants> { new cls_applicants('JOINT_APPLICANT') };
                                                                                                        }
                    
                    contacts1.add(contactObj);
            }
            request.contacts1 = contacts1;
            String requestJSON = JSON.serialize(request);
            return requestJSON;
          
        } catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage() + exp.getStackTraceString() + 'Createhunterpayload' );

            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'Createhunterpayload', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage() + exp.getStackTraceString() + 'Createhunterpayload');
        }

    }
    public class HunterRequestWrapper {
        public String applicationName;    
        public String entity;             
        public ClsContacts[] contacts1;
        public String appproductCode;     
        public String loanReference;
        
    }
    
    public class ClsContacts {
        public cls_personNames[] personNames;
        public cls_addresses1[] addresses1;
        public cls_telephones[] telephones;
        public cls_identityDoc[] identityDoc;
        public cls_emails1[] emails1;
        public cls_personDetails personDetails;
        public cls_applicants[] applicants;
        public cls_empHistory[] empHistory; 
        public cls_employerTelephones[] employerTelephones; 
        
        public ClsContacts(){
            
        }
        public ClsContacts(cls_personNames[] personNames, cls_addresses1[] addresses1, cls_telephones[] telephones, 
                             cls_identityDoc[] identityDoc, cls_emails1[] emails1, cls_personDetails personDetails, 
                             cls_applicants[] applicants, cls_empHistory[] empHistory, cls_employerTelephones[] employerTelephones) {
                                 this.personNames = personNames;
                                 this.addresses1 = addresses1;
                                 this.telephones = telephones;
                                 this.identityDoc = identityDoc;
                                 this.emails1 = emails1;
                                 this.personDetails = personDetails;
                                 this.applicants = applicants;
                                 this.empHistory = empHistory;
                                 this.employerTelephones = employerTelephones;
                             }
    }
    
    public class cls_personNames {
        public String type;      
        public String firstName; 
        public String middleNames;
        public String surName;
        
        public cls_personNames(String type, String firstName, String middleNames, String surName) {
            this.type = type;
            this.firstName = firstName;
            this.middleNames = middleNames;
            this.surName = surName;
        }
    }
    
    public class cls_addresses1 {
        public String addressType;
        public String buildingName;
        public String street;
        public String subLocality;
        public String locality;
        public String postTown;  
        public String postal;    
        public String stateProvinceCode;  
        public String countryCode;      
        
        public cls_addresses1(String addressType, String buildingName, String street, String subLocality, String locality,
                              String postTown, String postal, String stateProvinceCode, String countryCode) {
                                  this.addressType = addressType;
                                  this.buildingName = buildingName;
                                  this.street = street;
                                  this.subLocality = subLocality;
                                  this.locality = locality;
                                  this.postTown = postTown;
                                  this.postal = postal;
                                  this.stateProvinceCode = stateProvinceCode;
                                  this.countryCode = countryCode;
                              }
    }
    
    public class cls_telephones {
        public String numberval; 
        public String type;         
        
        public cls_telephones(String numberval, String type) {
            this.numberval = numberval;
            this.type = type;
        }
    }
    
    public class cls_identityDoc {
        public String documentNumber;  
        public String documentType;    
        
        public cls_identityDoc(String documentNumber, String documentType) {
            this.documentNumber = documentNumber;
            this.documentType = documentType;
        }
    }
    
    public class cls_emails1 {
        public String type;  
        public String email;  
        
        public cls_emails1(String type, String email) {
            this.type = type;
            this.email = email;
        }
    }
    
    public class cls_personDetails {
        public String typeOfPerson;   
        public Date dateOfBirth;    
        public String mothersFullName;
        public String fathersFullName;
        
        public cls_personDetails(String typeOfPerson, Date dateOfBirth, String mothersFullName, String fathersFullName) {
            this.typeOfPerson = typeOfPerson;
            this.dateOfBirth = dateOfBirth;
            this.mothersFullName = mothersFullName;
            this.fathersFullName = fathersFullName;
        }
        public cls_personDetails() {
            // default
            this.typeOfPerson = '';
            this.dateOfBirth = null;
            this.mothersFullName = '';
            this.fathersFullName = '';
        }
    }
    
    public class cls_applicants {
        public String applicantType;  
        
        public cls_applicants(String applicantType) {
            this.applicantType = applicantType;
        }
    }
    public class cls_empHistory {
        public String employerName; 
        public cls_empAddress empaddress;  
        public String employmentType;
        
        public cls_empHistory(String employerName, cls_empAddress empaddress, String employmentType) {
            this.employerName = employerName;
            this.empaddress = empaddress;
            this.employmentType = employmentType;
        }
        public cls_empHistory() {
            this.employerName = null;  
            this.empaddress = new cls_empAddress();  
            this.employmentType = null; 
        }
    }
    
    public class cls_empAddress {
        public String empbuildingName;
        public String empstreet;
        public String empsubLocality;
        public String emplocality;
        public String emppostTown;
        public String emppostal;
        public String empstateProvinceCode;
        public String empcountryCode;
        
        
        public cls_empAddress(String empbuildingName, String empstreet, String empsubLocality, String emplocality,
                              String emppostTown, String emppostal, String empstateProvinceCode, String empcountryCode) {
                                  this.empbuildingName = empbuildingName;
                                  this.empstreet = empstreet;
                                  this.empsubLocality = empsubLocality;
                                  this.emplocality = emplocality;
                                  this.emppostTown = emppostTown;
                                  this.emppostal = emppostal;
                                  this.empstateProvinceCode = empstateProvinceCode;
                                  this.empcountryCode = empcountryCode;
                              }
                              public cls_empAddress() {
                                this.empbuildingName = null;
                                this.empstreet = null;
                                this.empsubLocality = null;
                                this.emplocality = null;
                                this.emppostTown = null;
                                this.emppostal = null;
                                this.empstateProvinceCode = null;
                                this.empcountryCode = null;
                            }
    }
    
    public class cls_employerTelephones {
        public String empnumber;
        
        public cls_employerTelephones() {
            this.empnumber = null; 
        }
        public cls_employerTelephones(String empnumber) {
            this.empnumber = empnumber;
        }
    }
}