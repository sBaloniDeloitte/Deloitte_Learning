/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-24-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class Sales_FetchIntegartionDetails {
    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        
        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getAllApplicants(Id loanId) {
        List<Application_Applicant__c> applicants = [SELECT Id, First_Name__c, Last_Name__c
                                                        FROM Application_Applicant__c WHERE Loan_Application__c = :loanId];
        
        List<PicklistOption> customerPickList = new List<PicklistOption>();
        
        for (Application_Applicant__c app : applicants) {
            String label = app.First_Name__c + ' ' + app.Last_Name__c;
            customerPickList.add(new PicklistOption(label, app.Id));
        }
        System.debug('customerPickList-------'+customerPickList);
        return new Map<String, Object>{
            'customerPickList' => customerPickList
        };
    }

    @AuraEnabled(cacheable=true)
    public static List<ApplicantWrapper> getApplicantsIntegrationInfo(Id loanId, Id appId) {
        List<ApplicantWrapper> applicants = new List<ApplicantWrapper>();
        try {
            String panValue = '';
            String panNameValue = '';
            String panDobValue = '';
            String panNameRespValue = '';
            String panDobResValue = '';
            String panLastModifiedDate = '';
            String panRespStatus = '';

            String panProfileValue = '';
            String panProfileNameValue = '';
            String panProfileDobValue = '';
            String panProfileLastModifiedDate = '';

            String passportNo = '';
            String passportNameValue = '';
            String passportDobValue = '';
            String passportRespNo = '';
            String passportNameRespValue = '';
            String passportDobRespValue = '';
            String passportLastModifiedDate = '';

            String dlValue = '';
            String dlDobValue = '';
            String dlLastModifiedDate = '';
            String dlRespValue = '';
            String dlNameRespValue = '';
            String dlDobRespValue = '';
            String dlFatherRespValue = '';
            String dlStatusRespValue = '';

            String panProfileRespValue = '';
            String panProfileNameRespValue = '';
            String panProfileDobRespValue = '';
            String panProfileStatusRespValue = '';

            String voterProfileValue = '';
            String voterProfileLastModifiedDate = '';
            String voterProfileRespValue = '';
            String voterProfileNameRespValue = '';
            String voterProfileDobRespValue = '';
            List<Integration_Details__c> panStatusIntDetails = [SELECT Id, Name,Request_JSON__c, Response_JSON__c, LastModifiedDate FROM Integration_Details__c 
                                                                WHERE Loan_Application__c =: loanId AND Related_Record_Id__c =: appId AND Object_Name__c = 'Application_Applicant__c' 
                                                                AND Name =: 'Loan Applicant PAN Validation' Order by CreatedDate DESC LIMIT 1];
            List<SourceDetails> sources1 = new List<SourceDetails>();
            if (!panStatusIntDetails.isEmpty() && panStatusIntDetails[0].Request_JSON__c != null) {
                Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(panStatusIntDetails[0].Request_JSON__c);
                panValue = requestMap.containsKey('pan') ? String.valueOf(requestMap.get('pan')) : '';
                panNameValue = requestMap.containsKey('name') ? String.valueOf(requestMap.get('name')) : '';
                panDobValue = requestMap.containsKey('dob') ? String.valueOf(requestMap.get('dob')) : '';
                panLastModifiedDate = panStatusIntDetails[0].LastModifiedDate.format();
            }
            sources1.add(new SourceDetails('  Input Data', panValue, panNameValue, '', '', panDobValue, panLastModifiedDate, ''));

            if (!panStatusIntDetails.isEmpty() && panStatusIntDetails[0].Response_JSON__c != null) {
                Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(panStatusIntDetails[0].Response_JSON__c);
                if (respMap.containsKey('result')) {
                    Map<String, Object> resultMap = (Map<String, Object>) respMap.get('result');
                    panRespStatus = resultMap.containsKey('status') ? String.valueOf(resultMap.get('status')) : '';
                }
                panLastModifiedDate = panStatusIntDetails[0].LastModifiedDate.format();
            }
            sources1.add(new SourceDetails('Output Data', '', '', '', '', '', '', panRespStatus));
            applicants.add(new ApplicantWrapper('Pan Card', sources1));
            List<Integration_Details__c> panProfileStatusIntDetails = [SELECT Id, Name,Request_JSON__c, Response_JSON__c, LastModifiedDate FROM Integration_Details__c 
                                                                WHERE Loan_Application__c =: loanId AND Related_Record_Id__c =: appId AND Object_Name__c = 'Application_Applicant__c' 
                                                                AND Name =: 'Pan Profile' Order by CreatedDate DESC LIMIT 1];
            List<SourceDetails> sources2 = new List<SourceDetails>();
            if (!panProfileStatusIntDetails.isEmpty() && panProfileStatusIntDetails[0].Request_JSON__c != null) {
                Map<String, Object> requestPanProfileMap = (Map<String, Object>) JSON.deserializeUntyped(panProfileStatusIntDetails[0].Request_JSON__c);
                panProfileValue = requestPanProfileMap.containsKey('pan') ? String.valueOf(requestPanProfileMap.get('pan')) : '';
                panProfileNameValue = requestPanProfileMap.containsKey('name') ? String.valueOf(requestPanProfileMap.get('name')) : '';
                panProfileDobValue = requestPanProfileMap.containsKey('dob') ? String.valueOf(requestPanProfileMap.get('dob')) : '';
                panProfileLastModifiedDate = panProfileStatusIntDetails[0].LastModifiedDate.format();
            }
            sources2.add(new SourceDetails('  Input Data', panProfileValue, panProfileNameValue, '', '', panProfileDobValue, panProfileLastModifiedDate, ''));

            if (!panProfileStatusIntDetails.isEmpty() && panProfileStatusIntDetails[0].Response_JSON__c != null) {
                Map<String, Object> respPanProfileMap = (Map<String, Object>) JSON.deserializeUntyped(panProfileStatusIntDetails[0].Response_JSON__c);
                if (respPanProfileMap.containsKey('result')) {
                    Map<String, Object> resultPanProfileMap = (Map<String, Object>) respPanProfileMap.get('result');
                    panProfileRespValue = resultPanProfileMap.containsKey('pan') ? String.valueOf(resultPanProfileMap.get('pan')) : '';
                    panProfileNameRespValue = resultPanProfileMap.containsKey('name') ? String.valueOf(resultPanProfileMap.get('name')) : '';
                    panProfileDobRespValue = resultPanProfileMap.containsKey('dob') ? String.valueOf(resultPanProfileMap.get('dob')) : '';
                    panProfileStatusRespValue = resultPanProfileMap.containsKey('status') ? String.valueOf(resultPanProfileMap.get('status')) : '';
                }
                panLastModifiedDate = panStatusIntDetails[0].LastModifiedDate.format();
            }
            sources2.add(new SourceDetails('Output Data', panProfileRespValue, panProfileNameRespValue, '', '', panProfileDobRespValue, panProfileLastModifiedDate, panProfileStatusRespValue));

            applicants.add(new ApplicantWrapper('Pan Profile', sources2));

            List<Integration_Details__c> voterIdIntDetails = [SELECT Id, Name,Request_JSON__c, Response_JSON__c, LastModifiedDate FROM Integration_Details__c 
                                                                WHERE Loan_Application__c =: loanId AND Related_Record_Id__c =: appId AND Object_Name__c = 'Application_Applicant__c' 
                                                                AND Name =: 'Voter Id' Order by CreatedDate DESC LIMIT 1];
            List<SourceDetails> sources3 = new List<SourceDetails>();
            if (!voterIdIntDetails.isEmpty() && voterIdIntDetails[0].Request_JSON__c != null) {
                Map<String, Object> voterIdProfileMap = (Map<String, Object>) JSON.deserializeUntyped(voterIdIntDetails[0].Request_JSON__c);
                voterProfileValue = voterIdProfileMap.containsKey('epicNo') ? String.valueOf(voterIdProfileMap.get('epicNo')) : '';
                voterProfileLastModifiedDate = voterIdIntDetails[0].LastModifiedDate.format();
            }
            sources3.add(new SourceDetails('  Input Data', voterProfileValue, '', '', '', '', voterProfileLastModifiedDate, ''));

            if (!voterIdIntDetails.isEmpty() && voterIdIntDetails[0].Response_JSON__c != null) {
                Map<String, Object> respVoterProfileMap = (Map<String, Object>) JSON.deserializeUntyped(voterIdIntDetails[0].Response_JSON__c);
                if (respVoterProfileMap.containsKey('result')) {
                    Map<String, Object> resultVoterProfileMap = (Map<String, Object>) respVoterProfileMap.get('result');
                    voterProfileRespValue = resultVoterProfileMap.containsKey('epicNo') ? String.valueOf(resultVoterProfileMap.get('epicNo')) : '';
                    voterProfileNameRespValue = resultVoterProfileMap.containsKey('name') ? String.valueOf(resultVoterProfileMap.get('name')) : '';
                    voterProfileDobRespValue = resultVoterProfileMap.containsKey('dob') ? String.valueOf(resultVoterProfileMap.get('dob')) : '';
                }
                voterProfileLastModifiedDate = voterIdIntDetails[0].LastModifiedDate.format();
            }
            // sources3.add(new SourceDetails('Output Data', 'SXXXXXXXX8', '', '', '', '1999-05-18', '28/02/2025, 5:21 pm', ''));
            sources3.add(new SourceDetails('Output Data', voterProfileRespValue, voterProfileNameRespValue, '', '', voterProfileDobRespValue, voterProfileLastModifiedDate, ''));

            applicants.add(new ApplicantWrapper('Voter ID', sources3));

            List<Integration_Details__c> driversLicenseStatusIntDetails = [SELECT Id, Name,Request_JSON__c, Response_JSON__c, LastModifiedDate FROM Integration_Details__c 
                                                                WHERE Loan_Application__c =: loanId AND Related_Record_Id__c =: appId AND Object_Name__c = 'Application_Applicant__c' 
                                                                AND Name =: 'Drivers License' Order by CreatedDate DESC LIMIT 1];
            List<SourceDetails> sources4 = new List<SourceDetails>();
            if (!driversLicenseStatusIntDetails.isEmpty() && driversLicenseStatusIntDetails[0].Request_JSON__c != null) {
                Map<String, Object> requesDLDetailstMap = (Map<String, Object>) JSON.deserializeUntyped(driversLicenseStatusIntDetails[0].Request_JSON__c);
                dlValue = requesDLDetailstMap.containsKey('dlNo') ? String.valueOf(requesDLDetailstMap.get('dlNo')) : '';
                dlDobValue = requesDLDetailstMap.containsKey('dob') ? String.valueOf(requesDLDetailstMap.get('dob')) : '';
                dlLastModifiedDate = driversLicenseStatusIntDetails[0].LastModifiedDate.format();
            }
            sources4.add(new SourceDetails('  Input Data', dlValue, '', '', '', dlDobValue, dlLastModifiedDate, ''));
            if (!driversLicenseStatusIntDetails.isEmpty() && driversLicenseStatusIntDetails[0].Response_JSON__c != null) {
                Map<String, Object> respDLMap = (Map<String, Object>) JSON.deserializeUntyped(driversLicenseStatusIntDetails[0].Response_JSON__c);
                if (respDLMap.containsKey('result')) {
                    Map<String, Object> resultDLeMap = (Map<String, Object>) respDLMap.get('result');
                    dlRespValue = resultDLeMap.containsKey('dlNumber') ? String.valueOf(resultDLeMap.get('dlNumber')) : '';
                    dlNameRespValue = resultDLeMap.containsKey('name') ? String.valueOf(resultDLeMap.get('name')) : '';
                    dlDobRespValue = resultDLeMap.containsKey('dob') ? String.valueOf(resultDLeMap.get('dob')) : '';
                    dlFatherRespValue = resultDLeMap.containsKey('father/husband') ? String.valueOf(resultDLeMap.get('father/husband')) : '';
                    dlStatusRespValue = resultDLeMap.containsKey('status') ? String.valueOf(resultDLeMap.get('status')) : '';
                    dlLastModifiedDate = driversLicenseStatusIntDetails[0].LastModifiedDate.format();
                }
            }
            // sources4.add(new SourceDetails('Output Data', dlValue, 'PUNEET PANDEY', 'DIVAKAR PANDEY', '', dlDobValue, dlLastModifiedDate, 'Active'));
            sources4.add(new SourceDetails('Output Data', dlRespValue, dlNameRespValue, dlFatherRespValue, '', dlDobRespValue, dlLastModifiedDate, dlStatusRespValue));

            applicants.add(new ApplicantWrapper('Drivers License', sources4));

            // List<SourceDetails> sources5 = new List<SourceDetails>();
            // sources5.add(new SourceDetails('Input Data', '', '', '', '', '', '', ''));
            // sources5.add(new SourceDetails('Output Data', '', '', '', '', '', '', ''));

            // applicants.add(new ApplicantWrapper('Pan Aadhar', sources5));

            // List<SourceDetails> sources6 = new List<SourceDetails>();
            // sources6.add(new SourceDetails('Input Data', '', '', '', '', '', '', ''));
            // sources6.add(new SourceDetails('Output Data', '', '', '', '', '', '', ''));

            // applicants.add(new ApplicantWrapper('Aadhar XML', sources6));

            List<Integration_Details__c> passportStatusIntDetails = [SELECT Id, Name,Request_JSON__c, Response_JSON__c, LastModifiedDate FROM Integration_Details__c 
                                                                        WHERE Loan_Application__c =: loanId AND Related_Record_Id__c =: appId AND Object_Name__c = 'Application_Applicant__c' 
                                                                        AND Name =: 'Passport Verification' Order by CreatedDate DESC LIMIT 1];
            
            List<SourceDetails> sources7 = new List<SourceDetails>();
            if (!passportStatusIntDetails.isEmpty() && passportStatusIntDetails[0].Request_JSON__c != null) {
                Map<String, Object> requestMapPassport = (Map<String, Object>) JSON.deserializeUntyped(passportStatusIntDetails[0].Request_JSON__c);
                passportNo = requestMapPassport.containsKey('passportNo') ? String.valueOf(requestMapPassport.get('passportNo')) : '';
                passportNameValue = requestMapPassport.containsKey('name') ? String.valueOf(requestMapPassport.get('name')) : '';
                passportDobValue = requestMapPassport.containsKey('dob') ? String.valueOf(requestMapPassport.get('dob')) : '';
                passportLastModifiedDate = passportStatusIntDetails[0].LastModifiedDate.format();
            }
            sources7.add(new SourceDetails('  Input Data', passportNo, passportNameValue, '', '', passportDobValue, passportLastModifiedDate, ''));

            if (!passportStatusIntDetails.isEmpty() && passportStatusIntDetails[0].Response_JSON__c != null) {
                System.debug('Response_JSON__c: ' + passportStatusIntDetails[0].Response_JSON__c);
                Map<String, Object> respMapPassport = (Map<String, Object>) JSON.deserializeUntyped(passportStatusIntDetails[0].Response_JSON__c);
                System.debug('respMapPassport --> '+respMapPassport);
                passportLastModifiedDate = passportStatusIntDetails[0].LastModifiedDate.format();
                if (respMapPassport.containsKey('passportNumber')) {
                    Map<String, Object> passportNumberMap = (Map<String, Object>) respMapPassport.get('passportNumber');
                    System.debug('passportNumberMap --> '+passportNumberMap);
                    passportRespNo = passportNumberMap.containsKey('passportNumberFromSource') ? String.valueOf(passportNumberMap.get('passportNumberFromSource')) : '';
                }
        
                if (respMapPassport.containsKey('name')) {
                    Map<String, Object> nameMap = (Map<String, Object>) respMapPassport.get('name');
                    System.debug('nameMap --> '+nameMap);
                    String firstName = nameMap.containsKey('nameFromPassport') ? String.valueOf(nameMap.get('nameFromPassport')) : '';
                    String surname = nameMap.containsKey('surnameFromPassport') ? String.valueOf(nameMap.get('surnameFromPassport')) : '';
                    passportNameRespValue = firstName + ' ' + surname;
                }
            }
            sources7.add(new SourceDetails('Output Data', passportRespNo, passportNameRespValue, '', '', '', passportLastModifiedDate, ''));

            applicants.add(new ApplicantWrapper('Passport', sources7));
        } catch (Exception e) {
            System.debug('Error in getApplicantsIntegrationInfo: ' + e.getMessage());
        }
        // return applicants;
        return (applicants != null) ? applicants : new List<ApplicantWrapper>();
    }

    // Wrapper Class
    public class ApplicantWrapper {
        @AuraEnabled public String parameterName { get; set; }
        @AuraEnabled public List<SourceDetails> sources { get; set; }

        public ApplicantWrapper(String paramName, List<SourceDetails> sourceList) {
            this.parameterName = paramName;
            this.sources = sourceList;
        }
    }

    // Move SourceDetails OUT of ApplicantWrapper to fix the error
    public class SourceDetails {
        @AuraEnabled public String sourceName { get; set; }
        @AuraEnabled public String idNo { get; set; }
        @AuraEnabled public String applicantName { get; set; }
        @AuraEnabled public String fatherName { get; set; }
        @AuraEnabled public String motherName { get; set; }
        @AuraEnabled public String dob { get; set; }
        @AuraEnabled public String dateandTime { get; set; }
        @AuraEnabled public String status { get; set; }

        public SourceDetails(String sourceName, String idNo, String applicantName, String fatherName, String motherName, String dob, String dateandTime, String status) {
            this.sourceName = sourceName;
            this.idNo = idNo;
            this.applicantName = applicantName;
            this.fatherName = fatherName;
            this.motherName = motherName;
            this.dob = dob;
            this.dateandTime = dateandTime;
            this.status = status;
        }
    }
    
    


}