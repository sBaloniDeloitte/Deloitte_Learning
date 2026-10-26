/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 04-26-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class COMM_SalesLoanLoginController {
    static string conLabels = Constants__mdt.getInstance('COMM_SalesLoanLoginController').Value__c;
    
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
    @AuraEnabled
public static Boolean checkExistingAddressWithDocument(String applicantId, String addressField, String formIdentifier, String docId) {
    try {
        List<Applicant_Address__c> existingAddresses = [
            SELECT Id, Flag_Current_Registred_as_Very_High__c, Flag_PO_as_High__c
            FROM Applicant_Address__c
            WHERE Applicant__c = :applicantId
            AND Id != :docId
        ];

        for (Applicant_Address__c addr : existingAddresses) {
            if (addressField == 'Flag_Current_Registred_as_Very_High__c' 
                && addr.Flag_Current_Registred_as_Very_High__c == true) {
                return true; // duplicate found
            }
            if (addressField == 'Flag_PO_as_High__c' 
                && addr.Flag_PO_as_High__c == true) {
                return true; // duplicate found
            }
        }
        return false;
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}
    /*@AuraEnabled
    public static List<ApplicantWrapper> getApplicantValues(Map<String,String> inputMap){
        try {
            List<ApplicantWrapper> applicantWrapperList = new List<ApplicantWrapper>();
            String applicantId = inputMap.get('applicantId');
            List<Application_Applicant__c> appList = [select id,Customer_Profile__c,Loan_Application__r.Lead__r.Full_Name_As_Per_Pan__c,Consent_Status__c,Applicant_Type__c,Mobile_Number__c, Is_PAN_DOB_Mismatch__c, Is_Pan_Duplicate__c,Pan_Status__c,Is_PAN_Name_Mismatch__c,PAN_Number__c,DOB__c,DOI__c,Customer_Type__c,Sector__c,Name_of_Organization__c from Application_Applicant__c where id =:applicantId];
            for(Application_Applicant__c app:appList){
                ApplicantWrapper applicantWrapper = new ApplicantWrapper();
                applicantWrapper.applicantId = app.id;
                applicantWrapper.consentStatus = app.Consent_Status__c;
                applicantWrapper.isConsentAccepted = app.Consent_Status__c == 'Accepted' || app.Consent_Status__c == 'Pending' ? true:false;
                applicantWrapper.panNumber = app.PAN_Number__c;
                applicantWrapper.dobORDoi = app.DOB__c!=null?String.valueOf(app.DOB__c):String.valueOf(app.DOI__c);
                applicantWrapper.customerType = app.Customer_Type__c;
                applicantWrapper.isPanValidated = (String.isNotBlank(app.Pan_Status__c) && app.Pan_Status__c != 'Failed') ? true : false;
                applicantWrapper.nameMatch = String.valueof(app.Is_PAN_Name_Mismatch__c);
                applicantWrapper.dobMatch = String.valueof(app.Is_PAN_DOB_Mismatch__c);
                applicantWrapper.duplicate = String.valueof(app.Is_Pan_Duplicate__c);
                applicantWrapper.status = String.valueof(app.Pan_Status__c);
                applicantWrapper.applicantType = String.valueof(app.Applicant_Type__c); 
                applicantWrapper.mobileNumber = app.Mobile_Number__c;
                applicantWrapper.customerProfile = app.Customer_Profile__c;
                applicantWrapper.sector = String.valueof(app.Sector__c);
                applicantWrapper.nameOfOrg= app.Name_of_Organization__c;
                applicantWrapper.doi = String.valueof(app.DOI__c);
                applicantWrapper.consentSent= (app.Consent_Status__c== 'Pending' && app.Consent_Status__c!= 'Accepted')? false:true;
                applicantWrapper.leadName = app.Loan_Application__r.Lead__r.Full_Name_As_Per_Pan__c;
                applicantWrapperList.add(applicantWrapper);
            }
            return applicantWrapperList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }*/
    
    
    @AuraEnabled
    public static List<ApplicantWrapper> getApplicantValues(Map<String, String> inputMap, String parentScreen) {
        try {
            List<ApplicantWrapper> applicantWrapperList = new List<ApplicantWrapper>();
            //String recordId = inputMap.get('applicantId');
            String recordId = inputMap.get('applicantId') != null ? (String) inputMap.get('applicantId') : (String) inputMap.get('leadId');
            //system.debug('recordId>>'+recordId); 
            if (parentScreen == 'Lead Screen') {
                // Query Lead Detail
                List<Lead> leadList = [SELECT Id, Full_Name_As_Per_Pan__c, COMM_Consent_Status__c, MobilePhone, 
                                       Date_of_Birth__c, Date_of_Incorporation__c, Customer_Type__c 
                                       FROM Lead WHERE Id = :recordId];
                for (Lead lead : leadList) {
                    ApplicantWrapper applicantWrapper = new ApplicantWrapper();
                    applicantWrapper.applicantId = lead.Id;
                    applicantWrapper.consentStatus = lead.COMM_Consent_Status__c;
                    //system.debug('lead.COMM_Consent_Status__c'+ lead.COMM_Consent_Status__c);
                    applicantWrapper.isConsentAccepted = lead.COMM_Consent_Status__c == 'Accepted' || lead.COMM_Consent_Status__c == 'Pending' ? true:false;
                    //system.debug('applicantWrapper.isConsentAccepted'+ applicantWrapper.isConsentAccepted);
                    //applicantWrapper.panNumber = lead.PAN_Number__c;
                    applicantWrapper.dobORDoi = lead.Date_of_Birth__c != null ? String.valueOf(lead.Date_of_Birth__c) : String.valueOf(lead.Date_of_Incorporation__c);
                    applicantWrapper.customerType = lead.Customer_Type__c;
                    //applicantWrapper.isPanValidated = (String.isNotBlank(lead.Pan_Status__c) && lead.Pan_Status__c != 'Failed');
                    //applicantWrapper.nameMatch = String.valueOf(lead.Is_PAN_Name_Mismatch__c);
                    //applicantWrapper.dobMatch = String.valueOf(lead.Is_PAN_DOB_Mismatch__c);
                    //applicantWrapper.duplicate = String.valueOf(lead.Is_Pan_Duplicate__c);
                    //applicantWrapper.status = String.valueOf(lead.Pan_Status__c);
                    applicantWrapper.mobileNumber = lead.MobilePhone;
                    //applicantWrapper.sector = String.valueOf(lead.Sector__c);
                    //applicantWrapper.nameOfOrg = lead.Name_of_Organization__c;
                    applicantWrapper.doi = String.valueOf(lead.Date_of_Incorporation__c);
                    applicantWrapper.consentSent = (lead.COMM_Consent_Status__c == 'Pending' && lead.COMM_Consent_Status__c != 'Accepted') ? false : true;
                    applicantWrapper.leadName = lead.Full_Name_As_Per_Pan__c;
                    applicantWrapperList.add(applicantWrapper);
                }
            } else {
                // Query Applicant Detail
                List<Application_Applicant__c> appList = [SELECT Id, Customer_Profile__c, Loan_Application__r.Lead__r.Full_Name_As_Per_Pan__c, 
                                                          Consent_Status__c, Applicant_Type__c, Mobile_Number__c, Is_PAN_DOB_Mismatch__c, 
                                                          Is_Pan_Duplicate__c,IsForm60Uploaded__c, Pan_Status__c, Is_PAN_Name_Mismatch__c, PAN_Number__c, 
                                                          DOB__c, DOI__c, Customer_Type__c,Basic_Details_Filled__c ,Sector__c, Name_of_Organization__c,Is_MNRL_Blacklisted__c,Marital_Status__c 
                                                          FROM Application_Applicant__c WHERE Id = :recordId];
                for (Application_Applicant__c app : appList) {
                    ApplicantWrapper applicantWrapper = new ApplicantWrapper();
                    applicantWrapper.applicantId = app.Id;
                    applicantWrapper.consentStatus = app.Consent_Status__c;
                    applicantWrapper.isConsentAccepted = app.Consent_Status__c == 'Accepted' || app.Consent_Status__c == 'Pending';
                    applicantWrapper.panNumber = app.PAN_Number__c;
                    applicantWrapper.dobORDoi = app.DOB__c != null ? String.valueOf(app.DOB__c) : String.valueOf(app.DOI__c);
                    applicantWrapper.customerType = app.Customer_Type__c;
                    applicantWrapper.basicDetailsFilled = app.Basic_Details_Filled__c;
                    applicantWrapper.isPanValidated = (String.isNotBlank(app.Pan_Status__c) && app.Pan_Status__c != 'Failed');
                    applicantWrapper.nameMatch = String.valueOf(app.Is_PAN_Name_Mismatch__c);
                    applicantWrapper.dobMatch = String.valueOf(app.Is_PAN_DOB_Mismatch__c);
                    applicantWrapper.duplicate = String.valueOf(app.Is_Pan_Duplicate__c);
                    applicantWrapper.status = String.valueOf(app.Pan_Status__c);
                    applicantWrapper.applicantType = String.valueOf(app.Applicant_Type__c);
                    applicantWrapper.mobileNumber = app.Mobile_Number__c;
                    applicantWrapper.customerProfile = app.Customer_Profile__c;
                    applicantWrapper.sector = String.valueOf(app.Sector__c);
                    applicantWrapper.nameOfOrg = app.Name_of_Organization__c;
                    applicantWrapper.doi = String.valueOf(app.DOI__c);
                    applicantWrapper.consentSent = (app.Consent_Status__c == 'Pending' && app.Consent_Status__c != 'Accepted') ? false : true;
                    applicantWrapper.leadName = app.Loan_Application__r.Lead__r.Full_Name_As_Per_Pan__c;
                    applicantWrapper.isMNRLBlacklisted = app.Is_MNRL_Blacklisted__c;
                    applicantWrapper.maritalStatus = app.Marital_Status__c;
                    applicantWrapper.IsForm60Uploaded = app.IsForm60Uploaded__c;
                    applicantWrapperList.add(applicantWrapper);
                }
            }
            return applicantWrapperList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ApplicantWrapper {
        @AuraEnabled  public String applicantId;	
        @AuraEnabled  public String consentStatus;
        @AuraEnabled  public boolean isConsentAccepted;
        @AuraEnabled  public String panNumber;
        @AuraEnabled  public String dobORDoi;
        @AuraEnabled public String customerType;
        @AuraEnabled public Boolean isPanValidated;
        @AuraEnabled public String nameMatch;
        @AuraEnabled public String dobMatch;
        @AuraEnabled public String duplicate;
        @AuraEnabled public String status;
        @AuraEnabled public String applicantType;
        @AuraEnabled public String mobileNumber;
        @AuraEnabled public String customerProfile;
        @AuraEnabled public boolean consentSent;
        @AuraEnabled public String sector;
        @AuraEnabled public String nameOfOrg;
        @AuraEnabled public String doi;
        @AuraEnabled public String leadName;
        @AuraEnabled public Boolean isMNRLBlacklisted;
        @AuraEnabled public String maritalStatus;
        @AuraEnabled public String basicDetailsFilled;
        @AuraEnabled public String isForm60Uploaded;
    }
    @AuraEnabled
    public static ApplicantMainWrapper getApplicantDetailsForOtpConsent(Map<String, Object> params) {
        //system.debug('leadId>>>'+ leadId);
        //system.debug('parentScreen>>>'+ parentScreen);
        //system.debug(' params.get>'+  params.get('loanId'));
        String loanId = params.get('loanId') != null  ? (String) params.get('loanId') : '';
        String applicantId = params.get('applicantId') != null ? (String) params.get('applicantId') : '';
        String leadId = params.get('leadId') != null ? (String) params.get('leadId') : '';
        Decimal next = params.get('next') != null ? (decimal) params.get('next') : 0;
        String parentScreen = params.get('parentScreen') != null ? (String) params.get('parentScreen') : '';
        ApplicantMainWrapper mainWrap = new ApplicantMainWrapper();
        List<ApplicantDataWrapper> lstDetailWrapper = new List<ApplicantDataWrapper>();
        if(parentScreen == 'Lead Screen'){
            Lead lead = [
                SELECT Id,FirstName, LastName, MobilePhone, Mobile_Number_Masked__c, Date_of_Birth__c, Email, 
                Requested_Loan_Amount__c, Product__c, Industry, Business_Vintage__c, Customer_Type__c, 
                Date_of_Incorporation__c,COMM_Is_Consent_Received__c, Employment_Type__c, COMM_Consent_Status__c,Pincode__r.Name
                FROM Lead 
                WHERE Id = :leadId
                LIMIT 1
            ];
            //system.debug('lead>>>'+ lead);
            ApplicantDataWrapper wrapObj = new ApplicantDataWrapper();
                wrapObj.recordApplicationId = lead.Id;
                //system.debug(lead.FirstName);
                wrapObj.applicantName = (lead.FirstName != null ? lead.FirstName : '') + ' ' + (lead.LastName != null ? lead.LastName : '');
               // wrapObj.applicantType = lead.Applicant_Type__c;
                wrapObj.mobileNumber = lead.Mobile_Number_Masked__c;
                wrapObj.originalMobileNumber = (lead.MobilePhone != null) ? lead.MobilePhone : null;
                wrapObj.otpVerified = (lead.COMM_Is_Consent_Received__c == true);
                wrapObj.status = lead.COMM_Consent_Status__c;
                wrapObj.email = lead.Email;
            	lstDetailWrapper.add(wrapObj);
        }
        else if (next == 0) {
            // Handle Co-Applicant scenario
            if (parentScreen != null && parentScreen == 'Co Applicant') {
                List<Application_Applicant__c> coApplicants = [
                    SELECT Id, Customer__c, First_Name__c, Last_Name__c, Customer__r.Name, Applicant_Type__c, 
                    Customer__r.Mobile_Number__c,Customer_Type__c ,Is_Consent_Received__c,Business_Entity_Name__c, Mobile_Number__c, Consent_Status__c, Email__c
                    FROM Application_Applicant__c
                    WHERE Loan_Application__c = :loanId AND Id =:applicantId
                    AND Applicant_Type__c = 'Co Applicant'
                ];
                
                for (Application_Applicant__c coApplicant : coApplicants) {
                    ApplicantDataWrapper wrapObj = new ApplicantDataWrapper();
                    wrapObj.recordApplicationId = coApplicant.Id;
                    //system.debug(coApplicant.First_Name__c);
                    if(coApplicant.Customer_Type__c == 'Non Individual'){
                        wrapObj.applicantName = (coApplicant.Business_Entity_Name__c != null ? coApplicant.Business_Entity_Name__c : '');
                    }
                    else{
                    
                    wrapObj.applicantName = (coApplicant.First_Name__c != null ? coApplicant.First_Name__c : '') + ' ' + (coApplicant.Last_Name__c != null ? coApplicant.Last_Name__c : '');}
                    wrapObj.applicantType = coApplicant.Applicant_Type__c;
                    wrapObj.mobileNumber = (coApplicant.Mobile_Number__c != null) ? Utility.getMaskedString(coApplicant.Mobile_Number__c, '*', 6) : null;
                    wrapObj.originalMobileNumber = (coApplicant.Mobile_Number__c != null) ? coApplicant.Mobile_Number__c : null;
                    wrapObj.otpVerified = true;
                    wrapObj.status = 'Accepted';
                    wrapObj.email = coApplicant.Email__c;
                    lstDetailWrapper.add(wrapObj);
                }
            } 
            // Handle specific Applicant ID scenario
            else if (applicantId != null && applicantId != '') {
                Application_Applicant__c loanObj = [
                    SELECT Id, Customer__c, First_Name__c, Business_Entity_Name__c,Last_Name__c, Customer__r.Name, Applicant_Type__c, 
                    Customer__r.Mobile_Number__c, Is_Consent_Received__c, Customer_Type__c,Mobile_Number__c, Consent_Status__c, Email__c
                    FROM Application_Applicant__c
                    WHERE Loan_Application__c = :loanId 
                    AND Id = :applicantId
                    LIMIT 1
                ];
                
                ApplicantDataWrapper wrapObj = new ApplicantDataWrapper();
                wrapObj.recordApplicationId = loanObj.Id;
                //system.debug(loanObj.First_Name__c);
                if(loanObj.Customer_Type__c == 'Non Individual'){
                    wrapObj.applicantName = (loanObj.Business_Entity_Name__c != null ? loanObj.Business_Entity_Name__c : '');
                }
                else{
                wrapObj.applicantName = (loanObj.First_Name__c != null ? loanObj.First_Name__c : '') + ' ' + (loanObj.Last_Name__c != null ? loanObj.Last_Name__c : '');}
                wrapObj.applicantType = loanObj.Applicant_Type__c;
                wrapObj.mobileNumber = (loanObj.Mobile_Number__c != null) ? Utility.getMaskedString(loanObj.Mobile_Number__c, '*', 6) : null;
                wrapObj.originalMobileNumber = (loanObj.Mobile_Number__c != null) ? loanObj.Mobile_Number__c : null;
                wrapObj.otpVerified = true;
                wrapObj.status = 'Accepted';
                wrapObj.email = loanObj.Email__c;
                lstDetailWrapper.add(wrapObj);
            } 
            // Handle Primary Applicant scenario
            else {
                Application_Applicant__c primaryApplicant = [
                    SELECT Id, Customer__c, First_Name__c,Business_Entity_Name__c ,Last_Name__c, Customer__r.Name, Applicant_Type__c, 
                    Customer__r.Mobile_Number__c, Is_Consent_Received__c,Customer_Type__c, Mobile_Number__c, Consent_Status__c, Email__c
                    FROM Application_Applicant__c
                    WHERE Loan_Application__c = :loanId 
                    AND Applicant_Type__c = 'Primary Applicant'
                    LIMIT 1
                ];
                
                ApplicantDataWrapper wrapObj = new ApplicantDataWrapper();
                wrapObj.recordApplicationId = primaryApplicant.Id;
                if(primaryApplicant.Customer_Type__c == 'Non Individual'){
                    wrapObj.applicantName = (primaryApplicant.Business_Entity_Name__c != null ? primaryApplicant.Business_Entity_Name__c : '');
                }
                else{
                wrapObj.applicantName = (primaryApplicant.First_Name__c != null ? primaryApplicant.First_Name__c : '') + ' ' + (primaryApplicant.Last_Name__c != null ? primaryApplicant.Last_Name__c : '');}
                wrapObj.applicantType = primaryApplicant.Applicant_Type__c;
                wrapObj.mobileNumber = (primaryApplicant.Mobile_Number__c != null) ? Utility.getMaskedString(primaryApplicant.Mobile_Number__c, '*', 6) : null;
                wrapObj.originalMobileNumber = (primaryApplicant.Mobile_Number__c != null) ? primaryApplicant.Mobile_Number__c : null;
                wrapObj.otpVerified = true;
                wrapObj.status = 'Accepted';
                wrapObj.email = primaryApplicant.Email__c;
                lstDetailWrapper.add(wrapObj);
            }
        } 
        // Handle next step
        else if (applicantId != null && applicantId != '' && applicantId != 'undefined') {
            Application_Applicant__c applicantDetails = [
                SELECT Id, Customer__c, First_Name__c, Last_Name__c, Business_Entity_Name__c,Customer_Type__c,Customer__r.Name, Applicant_Type__c, 
                Customer__r.Mobile_Number__c, Is_Consent_Received__c, Mobile_Number__c, Consent_Status__c, Email__c
                FROM Application_Applicant__c
                WHERE Loan_Application__c = :loanId 
                AND Applicant_Type__c != 'Primary Applicant'
                AND Id = :applicantId
                LIMIT 1
            ];
            
            ApplicantDataWrapper wrapObj = new ApplicantDataWrapper();
            wrapObj.recordApplicationId = applicantDetails.Id;
            if(applicantDetails.Customer_Type__c == 'Non Individual'){
                    wrapObj.applicantName = (applicantDetails.Business_Entity_Name__c != null ? applicantDetails.Business_Entity_Name__c : '');
                }
                else{
            wrapObj.applicantName = (applicantDetails.First_Name__c != null ? applicantDetails.First_Name__c : '') + ' ' + (applicantDetails.Last_Name__c != null ? applicantDetails.Last_Name__c : '');}
            wrapObj.applicantType = applicantDetails.Applicant_Type__c;
            wrapObj.mobileNumber = (applicantDetails.Mobile_Number__c != null) ? Utility.getMaskedString(applicantDetails.Mobile_Number__c, '*', 6) : null;
            wrapObj.originalMobileNumber = applicantDetails.Mobile_Number__c;
            wrapObj.otpVerified = true;
            wrapObj.status = 'Accepted';
            wrapObj.email = applicantDetails.Email__c;
            lstDetailWrapper.add(wrapObj);
        }
        
        mainWrap.applicantDetails = lstDetailWrapper;
        return mainWrap;
    }
    
    @AuraEnabled
    public static AAStatusWrapper checkAAStatus(Map<String, String> inputMap) {
        AAStatusWrapper response = new AAStatusWrapper();
        response.isAACompleted = false;
        response.recordFound = false;

        try {
            String recordId = inputMap.get('recordId');
            String applicantId = inputMap.get('applicantId');
            String docId = inputMap.get('docId');

            List<Document_Details__c> docList = [
                SELECT Id, Account_Aggregator_Status__c 
                FROM Document_Details__c 
                WHERE Id = :docId 
                AND Applicant__c = :applicantId 
                AND Loan_Application__c = :recordId 
                LIMIT 1
            ];

            if (!docList.isEmpty()) {
                response.recordFound = true;
                String status = docList[0].Account_Aggregator_Status__c;

                if (status == 'CONSENT_APPROVED' || status == 'Successful') {
                    response.isAACompleted = true;
                }
                response.statusAA = status;
            }
        } catch (Exception e) {
            System.debug('Error in checkAAStatus: ' + e.getMessage());
            // Optional: Add error handling if needed
        }

        return response;
    }

public class AAStatusWrapper {
    @AuraEnabled public Boolean isAACompleted;
    @AuraEnabled public Boolean recordFound;
    @AuraEnabled public String statusAA;
}

    public class AccountAggregatorWrapper{
        @AuraEnabled public Boolean isAACompleted;
    }
    
    public with sharing class ApplicantMainWrapper {
        @AuraEnabled public Boolean isEnachIntiated;
        @AuraEnabled public Boolean isEnachDocuementUploaded;
        @AuraEnabled public String enachDocumentId;
        @AuraEnabled public String mandateid;
        @AuraEnabled public Boolean isEnachSentForapproval;
        @AuraEnabled public List<ApplicantDataWrapper> applicantDetails;
        @AuraEnabled public String eMandateVerificationStatus;
        @AuraEnabled public String mandateUrl;
        @AuraEnabled public String authMode;
        @AuraEnabled public String approvalStatus;
        @AuraEnabled public Boolean checkFields;
        
    }
    
    public with sharing class ApplicantDataWrapper {
        @AuraEnabled public String status;
        @AuraEnabled public String applicantId;
        @AuraEnabled public String applicantName;
        @AuraEnabled public String applicantType;
        @AuraEnabled public String applicantBankName;
        @AuraEnabled public String applicantACNumber;  
        @AuraEnabled public String aCHFeasibility; 
        @AuraEnabled public String ifsc;
        @AuraEnabled public String debitCardStatus;
        @AuraEnabled public String netBankingStatus;
        @AuraEnabled public String bankVerificationStatus;
        @AuraEnabled public String mobileNumber;
        @AuraEnabled public String recordApplicationId;
        @AuraEnabled public Boolean otpVerified = false;
        @AuraEnabled public String originalMobileNumber;
        @AuraEnabled public String bankLink;
        @AuraEnabled public String email;
    }
    
    /*@AuraEnabled
    public static Map<Integer, Id> getLoanAndApplicantDetails(String loanId, String apDetId) {
        // Initialize the result map
        Map<Integer, Id> resultMap = new Map<Integer, Id>();
        // Query the loan record
        if(apDetId != null){
            Application_Applicant__c loanObj = [SELECT Id FROM Application_Applicant__c
                                                WHERE Loan_Application__c = :loanId 
                                                AND id =: apDetId];
            // Add loan record to the result map with serial number 1
            resultMap.put(0, loanObj.Id);
            return resultMap;
        }
        else{
            Application_Applicant__c loanObj = [SELECT Id FROM Application_Applicant__c
                                                WHERE Loan_Application__c = :loanId 
                                                AND Applicant_Type__c = 'Primary Applicant'];
            // Add loan record to the result map with serial number 1
            resultMap.put(0, loanObj.Id);
            // Query applicant detail records related to the loan
            List<Application_Applicant__c> applicantDetailsList = [SELECT Id
                                                                   FROM Application_Applicant__c
                                                                   WHERE Loan_Application__c = :loanId 
                                                                   AND Applicant_Type__c != 'Primary Applicant' 
                                                                   ORDER BY CreatedDate ASC];
            // Initialize serial number counter for applicants
            Integer serialNumber = 1;
            // Add applicant details to the result map
            for (Application_Applicant__c applicant : applicantDetailsList) {
                resultMap.put(serialNumber, applicant.Id);
                serialNumber++;
            }
            return resultMap;
        }
    }*/
    
    @AuraEnabled
    public static Map<Integer, Id> getLoanAndApplicantDetails(Map<String, Object> params) {

        String loanId = params.get('loanId') != null ? (String) params.get('loanId') : '';
        String apDetId = params.get('apDetId') != null ? (String) params.get('apDetId') : '';
        String leadId = params.get('leadId') != null ? (String) params.get('leadId') : '';
        String parentScreen = params.get('parentScreen') != null ? (String) params.get('parentScreen') : '';

        //List<ApplicantDataWrapper> lstDetailWrapper = new List<ApplicantDataWrapper>();
        // Initialize the result map
        Map<Integer, Id> resultMap = new Map<Integer, Id>();
        
        if (parentScreen == 'Lead Screen') {
            // Handle lead object
            if (leadId != null) {
                //Lead leadObj = [SELECT Id FROM Lead WHERE Id = :leadId];
                resultMap.put(0, leadId);
            } 
        } else {
            // Handle existing object
        List<Application_Applicant__c> applicants = [SELECT Id, Applicant_Type__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId ORDER BY CreatedDate ASC];
        Integer serialNumber = 0;
        Boolean primaryApplicantFound = false;

        for (Application_Applicant__c applicant : applicants) {
            if (apDetId != null && applicant.Id == apDetId) {
                resultMap.put(0, applicant.Id);
                break;
            } else if (!primaryApplicantFound && applicant.Applicant_Type__c == 'Primary Applicant') {
                resultMap.put(0, applicant.Id);
                primaryApplicantFound = true;
            } else if (applicant.Applicant_Type__c != 'Primary Applicant') {
                serialNumber++;
                resultMap.put(serialNumber, applicant.Id);
            }
        }
        }
        return resultMap;
    }
    
    
    @AuraEnabled
    public static Boolean checkOTPVerified(Map<string,object> checkOTPVerifiedparams) {
        String recordId = checkOTPVerifiedparams.get('recordId') != null ? (String) checkOTPVerifiedparams.get('recordId'):'';
        String leadId = checkOTPVerifiedparams.get('leadId') != null  ? (String) checkOTPVerifiedparams.get('leadId'):'';
        //Integer next = (Integer) params.get('next');
        String parentScreen = checkOTPVerifiedparams.get('parentScreen') != null  ? (String) checkOTPVerifiedparams.get('parentScreen'):'';
        
        Boolean isUpdated = false; // Variable to track update success
        //System.debug('recordId ' + recordId);
        //System.debug('next ' + next);
        
        try {
            if (parentScreen == 'Lead Screen') {
                // Query Lead Detail
                Lead leadDetails = [SELECT Id, COMM_Is_Consent_Received__c FROM Lead WHERE Id = :leadId LIMIT 1];
                if (leadDetails != null) {
                    // Update the COMM_Is_Consent_Received__c field
                    leadDetails.COMM_Is_Consent_Received__c = true;
                    try {
                        update leadDetails;
                        isUpdated = true; // Mark as updated only if update is successful
                    } catch (DmlException d) {
                        throw new AuraHandledException(d.getMessage());
                        //System.debug('DML Exception in checkOTPVerified: ' + d.getMessage());
                    }
                }
            } else {
                // Query Applicant Detail
                Application_Applicant__c applicantDetails = [SELECT Id, Is_Consent_Received__c FROM Application_Applicant__c WHERE Id = :recordId LIMIT 1];
                if (applicantDetails != null) {
                    // Update the Is_Consent_Received__c field
                    applicantDetails.Is_Consent_Received__c = true;
                    try {
                        update applicantDetails;
                        isUpdated = true; // Mark as updated only if update is successful
                    } catch (DmlException d) {
                        throw new AuraHandledException(d.getMessage());
                        //System.debug('DML Exception in checkOTPVerified: ' + d.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
            //System.debug('Error in checkOTPVerified: ' + e.getMessage());
        }
        
        return isUpdated;
    }
    
    @AuraEnabled
    public static Boolean checkconsentVerified(Map<String, Object> checkconsentverifiedparams) {
        String recordId = checkconsentverifiedparams.get('recordId') != null ? (String) checkconsentverifiedparams.get('recordId'):'';
        String leadId = checkconsentverifiedparams.get('leadId') != null ?(String) checkconsentverifiedparams.get('leadId'):'';
        //Integer next = (Integer) params.get('next');
        String parentScreen = checkconsentverifiedparams.get('parentScreen') != null?(String) checkconsentverifiedparams.get('parentScreen'):'';
        Boolean isUpdated = false; 
        //System.debug('recordId '+recordId);
        //System.debug('next '+next);
        try {
            if (parentScreen == 'Lead Screen') {
                // Query Lead Detail
                Lead leadDetails = [SELECT Id, COMM_Is_Consent_Received__c FROM Lead WHERE Id = :leadId LIMIT 1];
                if (leadDetails != null) {
                    isUpdated = leadDetails.COMM_Is_Consent_Received__c;
                }
            } else {
                // Query Applicant Detail
                Application_Applicant__c applicantDetails = [SELECT Id, Is_Consent_Received__c FROM Application_Applicant__c WHERE Id = :recordId LIMIT 1];
                if (applicantDetails != null) {
                    isUpdated = true;
                }
            }
        } catch (Exception e) {
             throw new AuraHandledException(e.getMessage());
            //System.debug('Error in checkConsentVerified: ' + e.getMessage());
        }
        
        return isUpdated; 
    }
    @AuraEnabled
    public static void otpReceived(String recordId,string leadId,String parentScreen) {
         try {
            if (parentScreen == 'Lead Screen') {
                // Query Lead Detail
                Lead leadDetails = [SELECT Id, COMM_Is_Consent_Received__c, COMM_Consent_Status__c 
                                    FROM Lead 
                                    WHERE Id = :leadId LIMIT 1];
                if (leadDetails != null) {
                    leadDetails.COMM_Consent_Status__c = 'Accepted';
                    update leadDetails;
                }
            } else {
                // Query Applicant Detail
                Application_Applicant__c applicantDetails = [SELECT Id, Is_Consent_Received__c, Consent_Status__c, Loan_Application__c, Applicant_Type__c 
                                                             FROM Application_Applicant__c 
                                                             WHERE Id = :recordId LIMIT 1];
                if (applicantDetails != null) {
                    applicantDetails.Consent_Status__c = 'Accepted';
                    update applicantDetails;
                }
            }
        } catch (DmlException d) {
            throw new AuraHandledException(d.getMessage());
            //System.debug('DML Exception in otpReceived: ' + d.getMessage());
        }
    }
    
    @AuraEnabled
    public static void updateMode(Map<String, Object> params) {
          String recordId = params.get('recordId') != null ? (String) params.get('recordId') : '';
          String leadId = params.get('leadId') != null ? (String) params.get('leadId') : '';
          String parentScreen = params.get('parentScreen') != null ? (String) params.get('parentScreen') : '';
          String mode = params.get('mode') != null ? (String) params.get('mode') : '';
          String status = params.get('status') != null ? (String) params.get('status') : '';

        if (parentScreen == 'Lead Screen' && leadId != null) {
        Lead leadDetails = new Lead();
        leadDetails.Id = leadId;
        leadDetails.COMM_Consent_Mode__c = mode;
        leadDetails.COMM_Consent_Status__c = status;
        update leadDetails;
        } else if (recordId != null) {
        Application_Applicant__c applicantDetails = new Application_Applicant__c();
        applicantDetails.Id = recordId;
        applicantDetails.Consent_Mode__c = mode;
        applicantDetails.Consent_Status__c = status;
        update applicantDetails;
        }
    }
    /*@AuraEnabled
    public static void updatChangeMode(Map<String, Object> params) {
        String recordId = params.get('recordId') != null ?(String) params.get('recordId'):'';
        String leadId = params.get('leadId') != null ?(String) params.get('leadId'):'';
        //Integer next = (Integer) params.get('next');
        String parentScreen = params.get('parentScreen') != null ?(String) params.get('parentScreen'):'';
        if (parentScreen == 'Lead Screen') {
            // Query Lead Detail
            Lead leadDetails = [SELECT Id, COMM_Is_Consent_Received__c, COMM_Consent_Mode__c, COMM_Consent_Status__c 
                                FROM Lead 
                                WHERE Id = :leadId LIMIT 1];
            if (leadDetails != null) {
                leadDetails.COMM_Consent_Mode__c = '';
                leadDetails.COMM_Consent_Status__c = '';
                update leadDetails;
            }
        } else {
            // Query Applicant Detail
            Application_Applicant__c applicantDetails = [SELECT Id, Is_Consent_Received__c, Consent_Mode__c, Consent_Status__c 
                                                         FROM Application_Applicant__c 
                                                         WHERE Id = :recordId LIMIT 1];
            if (applicantDetails != null) {
                applicantDetails.Consent_Mode__c = '';
                applicantDetails.Consent_Status__c = '';
                update applicantDetails;
            }
        }
    }
    @AuraEnabled
    public static void updateModOTP(Map<String, Object> params) {
        String recordId = params.get('recordId') != null ?(String) params.get('recordId'):'';
        String leadId = params.get('leadId') != null ?(String) params.get('leadId'):'';
        //Integer next = (Integer) params.get('next');
        String parentScreen = params.get('parentScreen') != null ?(String) params.get('parentScreen'):'';
        if (parentScreen == 'Lead Screen') {
            // Query Lead Detail
            Lead leadDetails = [SELECT Id, COMM_Is_Consent_Received__c, COMM_Consent_Mode__c, COMM_Consent_Status__c 
                                FROM Lead 
                                WHERE Id = :leadId LIMIT 1];
            if (leadDetails != null) {
                leadDetails.COMM_Consent_Mode__c = 'OTP';
                leadDetails.COMM_Consent_Status__c = 'Pending';
                update leadDetails;
            }
        } else {
            // Query Applicant Detail
            Application_Applicant__c applicantDetails = [SELECT Id, Is_Consent_Received__c, Consent_Mode__c, Consent_Status__c 
                                                         FROM Application_Applicant__c 
                                                         WHERE Id = :recordId LIMIT 1];
            if (applicantDetails != null) {
                applicantDetails.Consent_Mode__c = 'OTP';
                applicantDetails.Consent_Status__c = 'Pending';
                update applicantDetails;
            }
        }
    }*/
    
    @AuraEnabled
    public static boolean checkBranchFromLoan(Id loanId) {
        Boolean returnVal = false;
        try {
            List<Opportunity> loanApps = [SELECT Id, Branch_Master__c, Branch_Master__r.Branch_Type__c,Dsa_Area_Manager__c, Sub_Branch__c, Sourcing_Manager__c FROM Opportunity WHERE Id =: loanId LIMIT 1];
            if(!loanApps.isEmpty()) {
                if(loanApps[0].Branch_Master__c != null) {
                    if(loanApps[0].Branch_Master__r.Branch_Type__c == 'HUB'){
                        if(loanApps[0].Sub_Branch__c != null && (loanApps[0].Dsa_Area_Manager__c != null || loanApps[0].Sourcing_Manager__c != null )){
                            returnVal = true;
                        } 
                    } else {
                        returnVal = true;
                    }  
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return returnVal;
    }
    
    @AuraEnabled
    public static List<String> checkSubStageCompletionApplicantInformation(Map<String,String> inputMap){
        try {
            List<String> finalResult = new List<String>();
            String applicantId;
            if(inputMap.containsKey('applicantId')){
                applicantId = inputMap.get('applicantId');
            }
            String loanId = inputMap.get('loanId');
            //List<String> valuesList = new List<String>();
            List<Application_Applicant__c> appList = [Select id,Aadhaar_Number__c,Aadhaar_Pincode__c,CKYC_ReferenceId__c,Consent_Status__c,Additional_Infromation_Filled__c,Address_Information_Filled__c,Is_Key_Applicant__c,Sub_Stage_Completion__c,PAN_Number__c,Pan_Name__c,DOB__c, DOI__c,Pan_Status__c,Basic_Details_Filled__c,CIBIL_Score__c,IsForm60Uploaded__c,Employer_Name__c from Application_Applicant__c where Loan_Application__c =:loanId
                                                      AND id=:applicantId];
            //List<Document_Details__c> docDetails = [Select id,Is_Required__c,Content_Document_Id__c from Document_Details__c where Loan_Application__c =:loanId and Is_Required__c=true AND Content_Document_Id__c!=null];
            Opportunity opp = [Select id,Login_Completion_Stage__c,Household_Income__c, Requested_Amount__c,Reference_Phone_1__c,Reference_Phone_2__c,Tenor_Months__c,Branch_Master__c,Branch_Master__r.Branch_Type__c,Sub_Branch__c, Exception_Approval_Status__c,Loan_Purpose__c,Women_Entrepreneurship__c from Opportunity where id =: loanId];
           List<Charges_Insurance__c> chargeInsuranceList = [ SELECT Id, Name,Payment_Status__c FROM Charges_Insurance__c WHERE Charges_Fee_Type__c ='Login Fee' AND Name = 'Login Fee' AND Loan_Application__c = :loanId LIMIT 1];
           List<Application_Collateral__c> appCollList = [SELECT Id,Collateral__r.IsActive__c FROM Application_Collateral__c WHERE HL_Loan_Application__c = :loanId];
            List<Product2> prodList = [Select id,RecordType.Name,Product__c from Product2 where Loan_Application__c =: loanId];
            List<Applicant_Address__c> addressList = [SELECT Id, Applicant__c FROM Applicant_Address__c WHERE Applicant__c =: applicantId];
            if(prodList.size()>0){
                Integer count =0;
                for(Product2 p : prodList){
                    if(p.RecordType.Name == 'Product'){
                        count++;
                    }
                    else if((p.RecordType.Name == 'Sub Product' && p.Product__c != null) ||  (p.RecordType.Name == 'Scheme' && p.Product__c != null)){
                        count++;
                    }
                } 
                if(count >=2){
                    finalResult.add('Product Completion');
                }
            }
            
            if(opp != null){
                if(String.isNotBlank(opp.Loan_Purpose__c)){
                    finalResult.add('Loan Details');
                }
                if(opp.Household_Income__c != null){
                    finalResult.add('PMAY Eligibilty');
                }
                if((opp.Reference_Phone_1__c!= null && opp.Reference_Phone_2__c!=null)){
                    finalResult.add('Application OtherDetails');
                }
            }
            if(!chargeInsuranceList.isEmpty()) {
                finalResult.add('Login Fees');
            }
            if(!appCollList.isEmpty()){
                system.debug('700--');
                Boolean allActive = true;
                for(Application_Collateral__c appColl : appCollList){
                    if(appColl.Collateral__r.IsActive__c != true){
                        allActive = false;
                        break;
                    }
                }
                 system.debug('700allActive--'+allActive);
                if(allActive){
                    finalResult.add('Collateral');
                    finalResult.add('Builder Details');
                }
            }

            if (!addressList.isEmpty()) {
                 finalResult.add('Address Details');
            }
            
            System.debug('finalResult----389' + finalResult);
            if (finalResult == null) finalResult = new List<String>();

            if(finalResult.contains('Login Fees')){
                System.debug('finalResult----391' + finalResult);
                if(opp.Login_Completion_Stage__c== null){
                    opp.Login_Completion_Stage__c = 'Application Information';
                    System.debug('finalResult----395' +  opp.Login_Completion_Stage__c);
                }
                else{
                    if(!opp.Login_Completion_Stage__c.containsIgnoreCase('Application information')){
                        opp.Login_Completion_Stage__c =  opp.Login_Completion_Stage__c + ';'+  'Application Information';
                        System.debug('finalResult----401' +  opp.Login_Completion_Stage__c);
                    }
                }
               // finalResult.add('Application information');
            }
            
            /*if(docDetails.size()==0){
                // finalResult.add('Document Complete');
            }*/
            if(finalResult.contains('Document Complete')){
                if(opp.Login_Completion_Stage__c== null){
                    // if(!opp.Login_Completion_Stage__c.contains('Application information')){
                    opp.Login_Completion_Stage__c = 'Document Details';
                    // }
                }
                else{
                    if(!opp.Login_Completion_Stage__c.containsIgnoreCase('Document Details')){
                        opp.Login_Completion_Stage__c =  opp.Login_Completion_Stage__c + ';'+ 'Document Details';
                    }
                }
            }
            if(finalResult.contains('Collateral')){
                if(opp.Login_Completion_Stage__c== null){
                    // if(!opp.Login_Completion_Stage__c.contains('Application information')){
                    opp.Login_Completion_Stage__c = 'Collateral';
                    // }
                }
                else{
                    if(!opp.Login_Completion_Stage__c.containsIgnoreCase('Collateral')){
                        opp.Login_Completion_Stage__c =  opp.Login_Completion_Stage__c + ';'+ 'Collateral';
                    }
                }
            }
            if(appList.size()>0){
                String currentValues = (String)appList[0].get('Sub_Stage_Completion__c');
                if((appList[0].PAN_Number__c != null && appList[0].Pan_Name__c!=null && ( appList[0].DOB__c!=null || appList[0].DOI__c!=null)) || appList[0].IsForm60Uploaded__c == 'Yes'){
                    if(currentValues==null){
                        appList[0].Sub_Stage_Completion__c = 'PAN/Form 60 Details'+';'+'Dedupe';
                    }
                    else{
                        appList[0].Sub_Stage_Completion__c = appList[0].Sub_Stage_Completion__c + ';' +'PAN Details'+';'+'Dedupe';
                    }
                    finalResult.add('PAN/Form 60 Details');
                    finalResult.add('Dedupe');
                }
                if(appList[0].Aadhaar_Number__c!= null && appList[0].Aadhaar_Pincode__c != null){
                    finalResult.add('Aadhar Details');
                }
                if(String.isNotBlank(appList[0].CKYC_ReferenceId__c)){
                    finalResult.add('C-KYC Details');
                }
                if(appList[0].Employer_Name__c != null){
                    finalResult.add('Employment Details');
                }
                if(appList[0].Basic_Details_Filled__c == 'true'){
                    if(currentValues!=null){
                        appList[0].Sub_Stage_Completion__c = appList[0].Sub_Stage_Completion__c + ';' + 'Basic Information'; 
                    }
                    else{
                        appList[0].Sub_Stage_Completion__c = 'Basic Information';
                    }
                    finalResult.add('Basic Information');
                }
                if(appList[0].Consent_Status__c == 'Accepted'){
                    if(currentValues!=null){
                        appList[0].Sub_Stage_Completion__c = appList[0].Sub_Stage_Completion__c + ';' + 'Consent';
                    }
                    else{
                        appList[0].Sub_Stage_Completion__c = 'Consent';
                    }
                    finalResult.add('Consent');
                }
                if(appList[0].Pan_Status__c == 'Valid' || appList[0].Pan_Status__c == 'Active'){
                    if(currentValues!=null){
                        appList[0].Sub_Stage_Completion__c = appList[0].Sub_Stage_Completion__c + ';' + 'PAN Validation';
                    }
                    else{
                        appList[0].Sub_Stage_Completion__c ='PAN Validation';
                    }
                    finalResult.add('PAN Validation');
                }
                if(appList[0].CIBIL_Score__c != null){
                    if(currentValues!=null){
                        appList[0].Sub_Stage_Completion__c = appList[0].Sub_Stage_Completion__c + ';' + 'Bureau Insights';
                    }
                    else{
                        appList[0].Sub_Stage_Completion__c = 'Bureau Insights';
                    }
                    finalResult.add('Bureau Insights');
                }
                if(appList[0].Additional_Infromation_Filled__c!=null && appList[0].Additional_Infromation_Filled__c=='true'){
                    if(currentValues!=null){
                        appList[0].Sub_Stage_Completion__c = appList[0].Sub_Stage_Completion__c + ';' + 'Additional Information';
                    }
                    else{
                        appList[0].Sub_Stage_Completion__c = 'Additional Information';
                    }
                    finalResult.add('Additional Information');
                }
                if(!addressList.isEmpty()){
                    appList[0].Address_Information_Filled__c = 'true';
                    if(currentValues!=null){
                        appList[0].Sub_Stage_Completion__c = appList[0].Sub_Stage_Completion__c + ';' + 'Address Information';
                    }
                    else{
                        appList[0].Sub_Stage_Completion__c = 'Address Information';
                    }
                    finalResult.add('AddressInformation');
                }
                if(finalResult.contains('Application OtherDetails') && finalResult.contains('AddressInformation') ){
                    if(opp.Login_Completion_Stage__c== null){
                        // if(!opp.Login_Completion_Stage__c.contains('Application information')){
                        opp.Login_Completion_Stage__c = 'Other Information';
                        // }
                    }
                    else{
                        if(!opp.Login_Completion_Stage__c.containsIgnoreCase('Other Information')){
                            opp.Login_Completion_Stage__c =  opp.Login_Completion_Stage__c + ';'+ 'Other Information';
                        }
                    }
                    finalResult.add('Other Information');
                }
            }
            if(!addressList.isEmpty()){
                finalResult.add('AddressInformation');
            }
            if(finalResult.contains('Application OtherDetails') && finalResult.contains('AddressInformation') ){
                if(opp.Login_Completion_Stage__c== null){
                    // if(!opp.Login_Completion_Stage__c.contains('Application information')){
                    opp.Login_Completion_Stage__c = 'Other Information';
                    // }
                }
                else{
                    if(!opp.Login_Completion_Stage__c.containsIgnoreCase('Other Information')){
                        opp.Login_Completion_Stage__c =  opp.Login_Completion_Stage__c + ';'+ 'Other Information';
                    }
                }
                finalResult.add('Other Information');
            }
            // if(appList.size()>0){
            //  update appList;
            // }
            if(opp!=null && opp.Exception_Approval_Status__c!= 'Submitted For Approval'){
                update opp;
            }
            System.debug('opp-835--' +  opp);
            System.debug('finalResult' +  finalResult);
            return finalResult;
            
        } catch (Exception e) {
            System.debug('❌ Exception caught = ' + e);
    System.debug('❌ Stack trace = ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string updateDocumentCompletion( String loanId){
        String res= 'fail';
        try {
            List<Opportunity> opp = [SELECT Id,Login_Completion_Stage__c FROM Opportunity WHERE id = :loanId];
            
            if(opp.size()>0){
                Opportunity oppNew= new Opportunity();
                oppNew.Id = opp[0].Id;
                if(opp[0].Login_Completion_Stage__c== null){
                    // if(!opp.Login_Completion_Stage__c.contains('Application information')){
                        oppNew.Login_Completion_Stage__c = 'Document Details';
                    // }
                }
                else{
                    if(!opp[0].Login_Completion_Stage__c.containsIgnoreCase('Document Details')){
                        oppNew.Login_Completion_Stage__c =  opp[0].Login_Completion_Stage__c + ';'+ 'Document Details';
                    }
                }
                update oppNew;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return res;
    }

    @AuraEnabled
    public static ErrorListWrappper checkNextStageMovement(String recordId) {
        ErrorListWrappper response = new ErrorListWrappper();
        response.errors = new List<String>(); 
        
        try {
            Opportunity opp = [
                SELECT Id, Is_Eligible_for_Exception_Approval__c, Login_Completion_Stage__c 
                FROM Opportunity 
                WHERE Id = :recordId  
                LIMIT 1
            ];
            
            // --- Stage Completion Check ---
            List<String> requiredStages;
            if (opp != null && opp.Is_Eligible_for_Exception_Approval__c == false) {
                String applicableStagesStr = Constants.get('Applicable_Login_Values');
                requiredStages = applicableStagesStr.split(',');
                response.moveToEligibility = false;
            } else {
                String applicableStagesStr = Constants.get('Applicable_Login_Values_Exception');
                requiredStages = applicableStagesStr.split(',');
            }

            Set<String> completedStages = new Set<String>();
            if (!String.isEmpty(opp.Login_Completion_Stage__c)) {
                completedStages.addAll(opp.Login_Completion_Stage__c.split(';'));
            }
            for (String stage : requiredStages) {
                stage = stage.trim(); 
                if (!completedStages.contains(stage)) {
                    response.errors.add(stage);
                }
            }

             // --- Extra Check: Sub Product is Present ---
              Id totalTenureRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Total Tenure').getRecordTypeId();
              List<Product2> subProductList = [
                SELECT Id, Name FROM Product2 WHERE RecordTypeId =: totalTenureRecordId AND Loan_Application__c = :opp.Id LIMIT 1];
             if(subProductList.isEmpty()) {
                 response.errors.add('Add Product with Loan Tenure');
            }


            /*// --- Extra Check: Login Fee API ---
            List<Charges_Insurance__c> feeList = [
                SELECT Id, Name, Requested_Amount_INR__c, API_Status__c 
                FROM Charges_Insurance__c 
                WHERE Charges_Fee_Type__c = 'Login Fee' 
                AND Name = 'Login Fee' 
                AND Loan_Application__c = :opp.Id
                LIMIT 1
            ];
            
            if (!feeList.isEmpty()) {
                Charges_Insurance__c feeRecord = feeList[0];
                if (feeRecord.Requested_Amount_INR__c > 0) {
                    if (String.isBlank(feeRecord.API_Status__c) || feeRecord.API_Status__c.toLowerCase() != 'success') {
                        response.errors.add('Login Fee API is not triggered');
                    }
                }
            }*/
            Boolean successResp = false;
            List<Integration_Details__c> inteDetList = [SELECT Id,Name,Loan_Application__c,Is_Success_Response__c,
            CreatedDate from Integration_Details__c WHERE Name = 'Upfront fee' AND Loan_Application__c =:opp.Id ORDER BY CreatedDate DESC];

            if(inteDetList.size()>0){
                for(Integration_Details__c itrIntDetail : inteDetList){
                    if(itrIntDetail.Is_Success_Response__c = true){
                        successResp = true;
                    }
                }/*
                if(!successResp){
                    response.errors.add('A Successful Login Fee API has not triggered.');
                }*/
            }

            // --- Final Decision ---
            if (response.errors.isEmpty()) {
                response.noError = true;
                response.showLogin = true;
            } else {
                response.noError = false;
                response.showLogin = false;
            }
            
            return response;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static boolean isProductAdded(String recordId){
        try {
            Boolean flag = false;
            //Opportunity opp = [Select id,Login_Completion_Stage__c, Requested_Amount__c,Tenor_Months__c,Branch_Master__c,Branch_Master__r.Branch_Type__c,Sub_Branch__c from Opportunity where id =: recordId];
            List<Application_Applicant__c> app = [Select id, Is_Key_Applicant__c,Loan_Application__r.PMAY_flag__c,Loan_Application__r.Household_Income__c from Application_Applicant__c where Loan_Application__c =: recordId AND Applicant_Type__c= 'Primary Applicant'];
            List<Product2> prodList = [Select id,RecordType.Name,Product__c from Product2 where Loan_Application__c =: recordId];
            if(prodList.size()>0){
                Integer count =0;
                for(Product2 p : prodList){
                    if(p.RecordType.Name == 'Product'){
                        count++;
                    }
                    else if((p.RecordType.Name == 'Sub Product' && p.Product__c != null) ||  (p.RecordType.Name == 'Scheme' && p.Product__c != null)){
                        count++;
                    }
                } 
                
                if(count >=2 && app.size()>=1 && (app[0].Loan_Application__r.PMAY_flag__c == false || (app[0].Loan_Application__r.PMAY_flag__c == true && app[0].Loan_Application__r.Household_Income__c != null))){
                    flag=true;
                }
            }
            return flag;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static boolean checkConsent( String recordId){
        try {
            Boolean result= false;
            List<Application_Applicant__c> applicantList= [SELECT Id, Consent_Status__c, Is_Consent_Received__c FROM Application_Applicant__c WHERE Applicant_Type__c = 'Co Applicant' AND Loan_Application__c = :recordId];
            for(Application_Applicant__c applicant: applicantList){
                if(applicant.Consent_Status__c!= 'Accepted'){
                    result= true;
                    break;
                }
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Map<String, String> checkLoanFacility( String loanId){
        Map<String, String> loanFacilityCheck= new Map<String, String>();
    //Changed the Loan_Facility__c field to Account_Type__c the Loan_Facility__c is used in BL functionality but in AHL inplace of Loan_Facility__c we are using Account_Type__c
        try {
            List<Opportunity> loanData= [SELECT Id, Account_Type__c, Sanction_Limit__c FROM Opportunity WHERE Id = :loanId];
            List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> docList= COMM_DocumentDetailsScreenController.getDocumentsList(loanId, 'Bank Statement');
            loanFacilityCheck.put('bsaInitiated', 'true');
            loanFacilityCheck.put('loanFacility', loanData[0].Account_Type__c);
            loanFacilityCheck.put('sanctionLimit', String.valueOf(loanData[0].Sanction_Limit__c));

            for(COMM_DocumentDetailsScreenController.DocumentDetailsWrapper docWrapper:docList){
                if(!docWrapper.bsaInitated){
                    loanFacilityCheck.put('bsaInitiated', 'false');

                }
            }
            
      
            //System.debug('loanFacilityCheck----'+loanFacilityCheck);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
      
       
        return loanFacilityCheck;
    }

    @AuraEnabled
    public static string getCurrApplicantCustType( String applicantId){
        String customerType;
        try {
            List<Application_Applicant__c> appList= [SELECT Id, Customer_Type__c FROM Application_Applicant__c WHERE Id = :applicantId];
            if(appList.size()>0){
                customerType = appList[0].Customer_Type__c;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return customerType;
    }
    public class ErrorListWrappper {
        @AuraEnabled public List<String> errors;
        @AuraEnabled public boolean noError;
        @AuraEnabled public boolean showLogin;
        @AuraEnabled public boolean moveToEligibility;
    }
    
    @AuraEnabled
    public static String callDedupeAPI(String applicantId, String loanId ) {
        Application_Applicant__c apDet = [
            SELECT Id, Customer__c, Name, Applicant_Name__c, Pan_Name__c, Pan_Number__c,Mobile_Number__c, DOB__c
            FROM Application_Applicant__c 
            WHERE Id = :applicantId
            LIMIT 1
        ];
        SalesCustomerDedupeController.InputWrapper iw = new  SalesCustomerDedupeController.InputWrapper();
        iw.panNumber=apDet.Pan_Number__c;
        iw.loanId=loanId;
        iw.applicantId=applicantId;
        
        String panNumner = apDet.Pan_Number__c;
        SalesCustomerDedupeController.checkCustomerDedupe(JSON.serialize(iw));
        //COMM_SalesLoanActionsController.checkSFDedupe(panNumner,applicantId,loanId);
        return 'Success';
        // try {
        //     // String applicantId = inputMapDedupe.get('applicantId');
        //     // String loanId = inputMapDedupe.get('loanId');
        
        
        //     Application_Applicant__c apDet = [
        //         SELECT Id, Customer__c, Name, Applicant_Name__c, Pan_Name__c, Pan_Number__c,Mobile_Number__c, DOB__c
        //         FROM Application_Applicant__c 
        //         WHERE Id = :applicantId
        //         LIMIT 1
        //     ];
        
        //     Account accDet = [
        //         SELECT Id, Name, Gender__c, Match_Response__c, CustUniqueId__c, Customer_LMS_Id__c,
        //                PAN_Number__c, Date_of_Birth__c, Duplicate_Customer_Source__c, Description, Mobile_Number__c
        //         FROM Account 
        //         WHERE Id = :apDet.Customer__c 
        //         LIMIT 1
        //     ];
        
        //     Map<String, String> inputMap = new Map<String, String>();
        //     inputMap.put('loanId',loanId);
        //     inputMap.put('applicantId',apDet.Id);
        //     inputMap.put('processName','UCIC De Dupe Check');
        //     inputMap.put('panNumber',apDet.Pan_Number__c);
        //     inputMap.put('panName',apDet.Pan_Name__c);
        //     inputMap.put('dob',String.valueOf(apDet.DOB__c));
        //     inputMap.put('mobileNumber',String.valueOf(apDet.Mobile_Number__c));
        //     String resp = UCICController.initiateAPIRequest(inputMap);
        //     UCICController.UCICDeduplicationInfo dedupeInfo = 
        //         (UCICController.UCICDeduplicationInfo) JSON.deserialize(resp, UCICController.UCICDeduplicationInfo.class);
        
        //     if (!dedupeInfo.freshCustomer && dedupeInfo.duplicateCustomers != null && !dedupeInfo.duplicateCustomers.isEmpty()) {
        //         List<String> custIdExisting = new List<String>();
        //         for (UCICController.CustomerMatch match : dedupeInfo.duplicateCustomers) {
        //             custIdExisting.add(match.customerId);
        //         }
        
        //         Map<String, Account> custToAccountMap = new Map<String, Account>();
        //         for (Account acc : [
        //             SELECT Id, Customer_LMS_Id__c, CustUniqueId__c 
        //             FROM Account 
        //             WHERE Customer_LMS_Id__c IN :custIdExisting
        //         ]) {
        //             custToAccountMap.put(acc.Customer_LMS_Id__c, acc);
        //         }
        
        //         Integer panMatchCount = 0;
        //         for (UCICController.CustomerMatch match : dedupeInfo.duplicateCustomers) {
        //             String reason = (match.matchReason != null ? match.matchReason.replaceAll('&#124;', '|') : '').toLowerCase();
        //             if (reason.contains('pan|rule0')) panMatchCount++;
        //         }
        
        //         Boolean panMatchHandled = false;
        //         String custUniqueID = applicantId;
        
        //         for (UCICController.CustomerMatch match : dedupeInfo.duplicateCustomers) {
        //             String reason = (match.matchReason != null ? match.matchReason.replaceAll('&#124;', '|') : '').toLowerCase();
        //             Boolean isPanMatch = reason.contains('pan|rule0');
        
        //             if (isPanMatch && panMatchCount == 1 && !panMatchHandled) {
        //                 Sales_LoanActionsController.updateCustomerDetails(match.customerId, applicantId, apDet.Pan_Number__c, custUniqueID, 'PLF', '');
        //                 panMatchHandled = true;
        
        //             } else if (isPanMatch && panMatchCount > 1 && !panMatchHandled) {
        //                 accDet.Name = match.name != null ? match.name : 'Unknown Customer';
        //                 accDet.Customer_LMS_Id__c = match.customerId;
        //                 accDet.PAN_Number__c = match.panNumber;
        //                 accDet.Gender__c = match.gender;
        //                 accDet.Mobile_Number__c = match.mobileNumber;
        //                 accDet.Date_of_Birth__c = match.dob;
        //                 accDet.Duplicate_Customer_Source__c = 'PLF';
        //                 accDet.Match_Response__c = match.matchReason;
        //                 accDet.CustUniqueId__c = custUniqueID;
        //                 accDet.Description = 'Created from UCIC Deduplication (Multiple PAN matches)';
        //                 update accDet;
        
        //                 panMatchHandled = true;
        
        //             } else {
        //                 Account acc = custToAccountMap.containsKey(match.customerId) 
        //                     ? custToAccountMap.get(match.customerId) 
        //                     : new Account();
        
        //                 if (acc.Id == null) {
        //                     acc.Customer_LMS_Id__c = match.customerId;
        //                 }
        
        //                 acc.Name = match.name != null ? match.name : 'Unknown Customer';
        //                 acc.PAN_Number__c = match.panNumber;
        //                 acc.Gender__c = match.gender;
        //                 acc.Mobile_Number__c = match.mobileNumber;
        //                 acc.Date_of_Birth__c = match.dob;
        //                 acc.Duplicate_Customer_Source__c = 'PLF';
        //                 acc.Match_Response__c = match.matchReason;
        
        //                 if (acc.CustUniqueId__c != null) {
        //                     if (!acc.CustUniqueId__c.contains(custUniqueID)) {
        //                         acc.CustUniqueId__c += ',' + custUniqueID;
        //                     }
        //                 } else {
        //                     acc.CustUniqueId__c = custUniqueID;
        //                 }
        
        //                 acc.Description = isPanMatch
        //                     ? 'Created from UCIC Deduplication (Multiple PAN matches)'
        //                     : 'Created from UCIC Deduplication (Non-PAN match)';
        
        //                 upsert acc;
        //             }
        //         }
        //     }
        
        //     return 'Success';
        
        // } catch (Exception e) {
        //     throw new AuraHandledException('Error in callDedupeAPI: ' + e.getMessage());
        // }
    }
    
    @AuraEnabled
    public static List<ApplicantList> getAllApplicants(String loanId){
        try {
            List<ApplicantList>  appList = new List<ApplicantList>();
            List<Application_Applicant__c> apList = [select id from Application_Applicant__c where Loan_Application__c =: loanId];
            for(Application_Applicant__c app : apList){
                ApplicantList appWrap = new ApplicantList();
                appWrap.applicantId = app.id;
                appList.add(appWrap);
            }
            return appList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class ApplicantList{
        @AuraEnabled public String applicantId;
    }
    
    @AuraEnabled
    public static String updateCustomerDisposition(List<String> selectedIds, String remarks, String status) {
        try {
            List<Account> accountsToUpdate = new List<Account>();
            for (String id : selectedIds) {
                Account acc = new Account();
                acc.Id = id;
                acc.Dedupe_Disposition_Remarks__c = remarks;
                acc.Dedupe_Disposition__c = status;
                accountsToUpdate.add(acc);
            }
            
            if (!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
            }
            
            return 'success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string getCustId(String customerId){
        string returnVal = null;
        try {
            List<Account> acc =[Select id,Customer_LMS_Id__c from Account where id =: customerId];
            if(acc.size() > 0){
                returnVal = acc[0].Customer_LMS_Id__c;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return returnVal;
    }
    
    @AuraEnabled
    public static Boolean checkSubBranch( String loanId){
        Boolean isSubBranchReq= false;
        try {
            List<Opportunity> oppList= [SELECT Id, Branch_Master__c, Branch_Master__r.Branch_Type__c, Sub_Branch__c FROM Opportunity WHERE Id = :loanId];
            if(oppList.size() > 0 && oppList[0].Branch_Master__c != null){
                if(oppList[0].Branch_Master__r.Branch_Type__c == 'HUB'){
                    isSubBranchReq= true;
                }
            }
        } catch (Exception e) {
            //System.debug('Error in check sub branch----'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        return isSubBranchReq;
    }
    @AuraEnabled
    public static String createCoAppAddress(Id loanId, Id applicantDetId, String pincode) {
        string returnval;
        try {
            List<Application_Applicant__c> apps = [SELECT Id, Name, Applicant_Type__c FROM Application_Applicant__c WHERE Id = :applicantDetId LIMIT 1];
            if (!apps.isEmpty()) {
                if (apps[0].Applicant_Type__c != 'Primary Applicant') {
                    List<Applicant_Address__c> appAddress = [SELECT Id, Pincode__c, Applicant__c FROM Applicant_Address__c WHERE Applicant__c = :applicantDetId 
                                                             AND Loan_Application__c = :loanId AND Address_Type__c = 'Current'];
                    
                    if (!appAddress.isEmpty()) {
                        appAddress[0].Pincode__c = pincode;
                        update appAddress[0];
                        returnval = 'Address updated successfully';
                    } else {
                        Applicant_Address__c appAdd = new Applicant_Address__c();
                        appAdd.Applicant__c = applicantDetId;
                        appAdd.Loan_Application__c = loanId;
                        appAdd.Pincode__c = pincode;
                        appAdd.Address_Type__c = 'Current';
                        System.debug('before insert address>');
                        insert appAdd;
                        returnval = 'Address created successfully';
                    }
                } else {
                    returnval = 'Applicant is a Primary Applicant, no action taken';
                }
            } else {
                returnval = 'No Application Applicant found for the provided Applicant ID';
            }
        } catch (Exception e) {
            
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
        return returnval;
    }
    // @AuraEnabled
    // public static void saveAddressSource(String applicantId, String addressType, String addressSource){
    //     try {
    //         List<Applicant_Address__c> currentAdd  = [SELECT Id, Address_Source__c,Address_Type__c,Address_Line_1__c,Address_Line_2__c,Address_Line_3__c,Pincode__c FROM Applicant_Address__c WHERE Applicant__c =: applicantId and OCR_Address_Type__c =:addressType  AND  Address_Source__c =:addressSource  ORDER BY CreatedDate DESC LIMIT 1];
    //         List<Applicant_Address__c> appAddList  = [SELECT Id, Address_Source__c,Address_Type__c,Address_Line_1__c,Address_Line_2__c,Address_Line_3__c,Pincode__c FROM Applicant_Address__c WHERE Applicant__c =: applicantId and OCR_Address_Type__c =:addressType  AND  Address_Source__c =:addressSource  ORDER BY CreatedDate DESC LIMIT 1];
    //         if(appAddList.size() > 0){
    //             if(addressType=='Permanent'||addressType=='Current'){
    //                 appAddList[0].Address_Type__c = addressType;
    //                 appAddList[0].OCR_Address_Type__c = addressType;
    //             }
    //             else if(addressType=='Permanent+Current'){
    //                 appAddList[0].Address_Type__c = 'Permanent';
    //                 appAddList[0].OCR_Address_Type__c = 'Permanent';
    //                 Applicant_Address__c appAdd = new  Applicant_Address__c();
    //                 appAdd.Applicant__c = applicantId;
    //                 appAdd.Address_Type__c = 'Current';
    //                 appAdd.Address_Source__c = addressSource;
    //                 appAdd.OCR_Address_Type__c = 'Current';
    //                 appAdd.Address_Line_1__c = appAddList[0].Address_Line_1__c;
    //                 appAdd.Address_Line_2__c = appAddList[0].Address_Line_2__c;
    //                 appAdd.Address_Line_3__c = appAddList[0].Address_Line_3__c;
    //                 appAdd.Pincode__c = appAddList[0].Pincode__c;
    //                 insert appAdd;
    //             }
    //             if(appAddList.size()>0){
    //                 upsert appAddList;
    //             }
    
    //         }
    
    
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }
    
    // @AuraEnabled
    // public static void saveAddressSource(String applicantId, String fieldAPIName, String fieldAPIValue,String addressType, String addressSource,String docId) {
    //     try {
    //         List<Applicant_Address__c> addressListToUpsert = new List<Applicant_Address__c>();
    
    //         // if (addressType == 'Current' || addressType == 'Permanent') {
    //         //     List<Applicant_Address__c> existing = [
    //         //         SELECT Id, Address_Source__c, Address_Type__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Pincode__c 
    //         //         FROM Applicant_Address__c 
    //         //         WHERE Applicant__c = :applicantId 
    //         //         AND Address_Source__c = :addressSource 
    //         //         ORDER BY CreatedDate DESC 
    //         //         LIMIT 1
    //         //     ];
    
    //         //     if (!existing.isEmpty()) {
    //         //         existing[0].Address_Type__c = addressType;
    //         //         existing[0].OCR_Address_Type__c = addressType;
    //         //         existing[0].Document_Details__c = docId;
    //         //         addressListToUpsert.add(existing[0]);
    //         //     }
    //         // }
    //         // else if (addressType == 'Permanent+Current') {
    
    //         //     List<Applicant_Address__c> existingAddList = [
    //         //         SELECT Id, Address_Source__c, Address_Type__c, OCR_Address_Type__c,
    //         //                Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Pincode__c 
    //         //         FROM Applicant_Address__c 
    //         //         WHERE Applicant__c = :applicantId 
    //         //         AND Address_Source__c = :addressSource
    //         //         AND (Address_Type__c = 'Current' OR Address_Type__c = 'Permanent' OR Address_Type__c = null)
    //         //         ORDER BY CreatedDate DESC
    //         //     ];
    
    //         //     Boolean currentExists = false;
    //         //     Boolean permExists = false;
    //         //     Boolean noTypeExists = false;
    //         //     Applicant_Address__c noTypeAddress;
    
    //         //     for (Applicant_Address__c addr : existingAddList) {
    //         //         if (addr.Address_Type__c == 'Current') {
    //         //             currentExists = true;
    //         //         }
    //         //         else if (addr.Address_Type__c == 'Permanent') {
    //         //             permExists = true;
    //         //         }
    //         //         // else if (String.isBlank(addr.OCR_Address_Type__c)) {
    //         //         //     noTypeExists = true;
    //         //         //     noTypeAddress = addr;
    //         //         // }
    //         //     }
    //         //     if(!currentExists  && !permExists){
    //         //         noTypeExists = true;
    //         //         noTypeAddress = new Applicant_Address__c();
    //         //     }
    
    //         //     if (currentExists && !permExists) {
    //         //         for (Applicant_Address__c addr : existingAddList) {
    //         //             if (addr.Address_Type__c == 'Current') {
    //         //                 addr.OCR_Address_Type__c= 'Permanent+Current';
    //         //                 addr.Document_Details__c = docId;
    //         //                 addressListToUpsert.add(addr);
    //         //                 Applicant_Address__c newAddr = new Applicant_Address__c();
    //         //                 newAddr.Applicant__c = applicantId;
    //         //                 newAddr.Address_Type__c = 'Permanent';
    //         //                 newAddr.OCR_Address_Type__c = 'Permanent+Current';
    //         //                 newAddr.Address_Source__c = addressSource;
    //         //                 newAddr.Address_Line_1__c = addr.Address_Line_1__c;
    //         //                 newAddr.Address_Line_2__c = addr.Address_Line_2__c;
    //         //                 newAddr.Address_Line_3__c = addr.Address_Line_3__c;
    //         //                 newAddr.Pincode__c = addr.Pincode__c;
    //         //                 newAddr.Document_Details__c = docId;
    //         //                 addressListToUpsert.add(newAddr);
    //         //                 break;
    //         //             }
    //         //         }
    
    //         //     }
    
    //         //     else if (permExists && !currentExists) {
    //         //         for (Applicant_Address__c addr : existingAddList) {
    //         //             if (addr.Address_Type__c == 'Permanent') {
    //         //                 addr.OCR_Address_Type__c= 'Permanent+Current';
    //         //                 addressListToUpsert.add(addr);
    //         //                 Applicant_Address__c newAddr = new Applicant_Address__c();
    //         //                 newAddr.Applicant__c = applicantId;
    //         //                 newAddr.Address_Type__c = 'Current';
    //         //                 newAddr.OCR_Address_Type__c = 'Permanent+Current';
    //         //                 newAddr.Address_Source__c = addressSource;
    //         //                 newAddr.Address_Line_1__c = addr.Address_Line_1__c;
    //         //                 newAddr.Address_Line_2__c = addr.Address_Line_2__c;
    //         //                 newAddr.Address_Line_3__c = addr.Address_Line_3__c;
    //         //                 newAddr.Pincode__c = addr.Pincode__c;
    //         //                 newAddr.Document_Details__c = docId;
    //         //                 addressListToUpsert.add(newAddr);
    //         //                 break;
    //         //             }
    //         //         }
    //         //     }
    //         //     else if(noTypeExists) {
    //         //         // Update existing record to Permanent
    //         //         noTypeAddress.OCR_Address_Type__c = 'Permanent+Current';
    //         //         noTypeAddress.Address_Type__c = 'Permanent';
    //         //         noTypeAddress.Applicant__c = applicantId;
    //         //         addressListToUpsert.add(noTypeAddress);
    
    //         //         // Create one more as Current
    //         //         Applicant_Address__c newCurrent = new Applicant_Address__c();
    //         //         newCurrent.Applicant__c = applicantId;
    //         //         newCurrent.Address_Type__c = 'Current';
    //         //         newCurrent.OCR_Address_Type__c = 'Permanent+Current';
    //         //         newCurrent.Address_Source__c = addressSource;
    //         //         newCurrent.Address_Line_1__c = noTypeAddress.Address_Line_1__c;
    //         //         newCurrent.Address_Line_2__c = noTypeAddress.Address_Line_2__c;
    //         //         newCurrent.Address_Line_3__c = noTypeAddress.Address_Line_3__c;
    //         //         newCurrent.Pincode__c = noTypeAddress.Pincode__c;
    //         //         newCurrent.Document_Details__c = docId;
    //         //         addressListToUpsert.add(newCurrent);
    //         //     }
    //         //     else if (permExists && currentExists){
    //         //         for(Applicant_Address__c applicantExt : existingAddList){
    //         //             if(fieldAPIName!=null && fieldAPIValue!=null){
    //         //                 applicantExt.put(fieldAPIName,fieldAPIValue);
    //         //                 applicantExt.Document_Details__c = docId;
    //         //                 System.debug('applicantExt------'+applicantExt);
    //         //                 addressListToUpsert.add(applicantExt);
    //         //             }
    //         //         }
    //         //     }
    //         // }
    
    //         if (addressType == 'Current' || addressType == 'Permanent' || addressType == 'Registered' || addressType == 'Correspondence') {
    //             List<Applicant_Address__c> existing = [
    //                 SELECT Id, Address_Source__c, Address_Type__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Pincode__c 
    //                 FROM Applicant_Address__c 
    //                 WHERE Applicant__c = :applicantId 
    //                 AND Address_Source__c = :addressSource 
    //                 ORDER BY CreatedDate DESC 
    //                 LIMIT 1
    //             ];
    
    //             if (!existing.isEmpty()) {
    //                 existing[0].Address_Type__c = addressType;
    //                 existing[0].OCR_Address_Type__c = addressType;
    //                 existing[0].Document_Details__c = docId;
    //                 addressListToUpsert.add(existing[0]);
    //             }
    //         }
    //         else if (addressType == 'Permanent+Current' || addressType == 'Registered+Correspondence') {
    
    //             String type1 = addressType == 'Permanent+Current' ? 'Permanent' : 'Registered';
    //             String type2 = addressType == 'Permanent+Current' ? 'Current' : 'Correspondence';
    
    //             List<Applicant_Address__c> existingAddList = [
    //                 SELECT Id, Address_Source__c, Address_Type__c, OCR_Address_Type__c,
    //                        Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Pincode__c 
    //                 FROM Applicant_Address__c 
    //                 WHERE Applicant__c = :applicantId 
    //                 AND Address_Source__c = :addressSource
    //                 AND (Address_Type__c = :type1 OR Address_Type__c = :type2 OR Address_Type__c = null)
    //                 ORDER BY CreatedDate DESC
    //             ];
    
    //             Boolean type1Exists = false;
    //             Boolean type2Exists = false;
    //             Boolean noTypeExists = false;
    //             Applicant_Address__c noTypeAddress;
    
    //             for (Applicant_Address__c addr : existingAddList) {
    //                 if (addr.Address_Type__c == type1) {
    //                     type1Exists = true;
    //                 }
    //                 else if (addr.Address_Type__c == type2) {
    //                     type2Exists = true;
    //                 }
    //             }
    
    //             if (!type1Exists && !type2Exists) {
    //                 noTypeExists = true;
    //                 noTypeAddress = new Applicant_Address__c();
    //             }
    
    //             if (type2Exists && !type1Exists) {
    //                 for (Applicant_Address__c addr : existingAddList) {
    //                     if (addr.Address_Type__c == type2) {
    //                         addr.OCR_Address_Type__c= addressType;
    //                         addr.Document_Details__c = docId;
    //                         addressListToUpsert.add(addr);
    
    //                         Applicant_Address__c newAddr = new Applicant_Address__c();
    //                         newAddr.Applicant__c = applicantId;
    //                         newAddr.Address_Type__c = type1;
    //                         newAddr.OCR_Address_Type__c = addressType;
    //                         newAddr.Address_Source__c = addressSource;
    //                         newAddr.Address_Line_1__c = addr.Address_Line_1__c;
    //                         newAddr.Address_Line_2__c = addr.Address_Line_2__c;
    //                         newAddr.Address_Line_3__c = addr.Address_Line_3__c;
    //                         newAddr.Pincode__c = addr.Pincode__c;
    //                         newAddr.Document_Details__c = docId;
    //                         addressListToUpsert.add(newAddr);
    //                         break;
    //                     }
    //                 }
    //             }
    //             else if (type1Exists && !type2Exists) {
    //                 for (Applicant_Address__c addr : existingAddList) {
    //                     if (addr.Address_Type__c == type1) {
    //                         addr.OCR_Address_Type__c = addressType;
    //                         addr.Document_Details__c = docId;
    //                         addressListToUpsert.add(addr);
    
    //                         Applicant_Address__c newAddr = new Applicant_Address__c();
    //                         newAddr.Applicant__c = applicantId;
    //                         newAddr.Address_Type__c = type2;
    //                         newAddr.OCR_Address_Type__c = addressType;
    //                         newAddr.Address_Source__c = addressSource;
    //                         newAddr.Address_Line_1__c = addr.Address_Line_1__c;
    //                         newAddr.Address_Line_2__c = addr.Address_Line_2__c;
    //                         newAddr.Address_Line_3__c = addr.Address_Line_3__c;
    //                         newAddr.Pincode__c = addr.Pincode__c;
    //                         newAddr.Document_Details__c = docId;
    //                         addressListToUpsert.add(newAddr);
    //                         break;
    //                     }
    //                 }
    //             }
    //             else if (noTypeExists) {
    //                 noTypeAddress.OCR_Address_Type__c = addressType;
    //                 noTypeAddress.Address_Type__c = type1;
    //                 noTypeAddress.Applicant__c = applicantId;
    //                 addressListToUpsert.add(noTypeAddress);
    
    //                 Applicant_Address__c newAddr = new Applicant_Address__c();
    //                 newAddr.Applicant__c = applicantId;
    //                 newAddr.Address_Type__c = type2;
    //                 newAddr.OCR_Address_Type__c = addressType;
    //                 newAddr.Address_Source__c = addressSource;
    //                 newAddr.Address_Line_1__c = noTypeAddress.Address_Line_1__c;
    //                 newAddr.Address_Line_2__c = noTypeAddress.Address_Line_2__c;
    //                 newAddr.Address_Line_3__c = noTypeAddress.Address_Line_3__c;
    //                 newAddr.Pincode__c = noTypeAddress.Pincode__c;
    //                 newAddr.Document_Details__c = docId;
    //                 addressListToUpsert.add(newAddr);
    //             }
    //             else if (type1Exists && type2Exists){
    //                 for(Applicant_Address__c applicantExt : existingAddList){
    //                     if(fieldAPIName != null && fieldAPIValue != null){
    //                         applicantExt.put(fieldAPIName, fieldAPIValue);
    //                         applicantExt.Document_Details__c = docId;
    //                         addressListToUpsert.add(applicantExt);
    //                     }
    //                 }
    //             }
    //         }
    
    //         else{
    //             List<Applicant_Address__c> existing = [
    //                 SELECT Id, Address_Source__c, Address_Type__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Pincode__c 
    //                 FROM Applicant_Address__c 
    //                 WHERE Applicant__c = :applicantId 
    //                 AND Address_Source__c = :addressSource 
    //                 ORDER BY CreatedDate DESC 
    //                 LIMIT 1
    //             ];
    
    //             Applicant_Address__c appAddress = new Applicant_Address__c();
    //             appAddress.Applicant__c=applicantId;
    //             appAddress.Document_Details__c = docId;
    //             appAddress.put(fieldAPIName,fieldAPIValue);
    //             if(existing.size()>0){
    //                 appAddress.id = existing[0].id;  
    //             }
    //             else{
    //                 if(addressSource!=null){
    //                     appAddress.Address_Source__c=addressSource;
    //                 }
    
    //             }
    //             addressListToUpsert.add(appAddress);
    
    //         }
    
    //         if (!addressListToUpsert.isEmpty()) {
    //             upsert addressListToUpsert;
    //         }
    
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }
    
    
    
    // @AuraEnabled
    // public static void saveAddressSource(String applicantId, String fieldAPIName, String fieldAPIValue, String addressType, String addressSource, String docId) {
    //     try {
    //         List<Applicant_Address__c> addressListToUpsert = new List<Applicant_Address__c>();
            
    //         if (String.isBlank(applicantId) || String.isBlank(addressSource)) {
    //             throw new AuraHandledException('Applicant ID and Address Source are required.');
    //         }
            
    //         // Combined address types
    //         if (addressType == 'Permanent+Current' || addressType == 'Registered+Correspondence') {
    //             String type1 = (addressType == 'Permanent+Current') ? 'Permanent' : 'Registered';
    //             String type2 = (addressType == 'Permanent+Current') ? 'Current' : 'Correspondence';
                
    //             Map<String, Applicant_Address__c> existingMap = new Map<String, Applicant_Address__c>();
    //             List<Applicant_Address__c> existingAddList = [
    //                 SELECT Id, Address_Source__c, Address_Type__c, OCR_Address_Type__c,
    //                 Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Pincode__c 
    //                 FROM Applicant_Address__c 
    //                 WHERE Applicant__c = :applicantId 
    //                 AND Address_Source__c = :addressSource
    //                 AND (Address_Type__c = :type1 OR Address_Type__c = :type2)
    //             ];
                
    //             for (Applicant_Address__c addr : existingAddList) {
    //                 existingMap.put(addr.Address_Type__c, addr);
    //             }
                
    //             // Ensure type1 exists
    //             if (existingMap.containsKey(type1)) {
    //                 Applicant_Address__c addr = existingMap.get(type1);
    //                 addr.OCR_Address_Type__c = addressType;
    //                 addr.Document_Details__c = docId;
    //                 if (!String.isBlank(fieldAPIName) && !String.isBlank(fieldAPIValue)) {
    //                     addr.put(fieldAPIName, fieldAPIValue);
    //                 }
    //                 addressListToUpsert.add(addr);
    //             } else {
    //                 // Create type1 from type2 or blank
    //                 Applicant_Address__c base = existingMap.get(type2);
    //                 Applicant_Address__c newAddr = new Applicant_Address__c();
    //                 newAddr.Applicant__c = applicantId;
    //                 newAddr.Address_Type__c = type1;
    //                 newAddr.OCR_Address_Type__c = addressType;
    //                 newAddr.Address_Source__c = addressSource;
    //                 newAddr.Document_Details__c = docId;
                    
    //                 if (base != null) {
    //                     newAddr.Address_Line_1__c = base.Address_Line_1__c;
    //                     newAddr.Address_Line_2__c = base.Address_Line_2__c;
    //                     newAddr.Address_Line_3__c = base.Address_Line_3__c;
    //                     newAddr.Pincode__c = base.Pincode__c;
    //                 }
    //                 if (!String.isBlank(fieldAPIName) && !String.isBlank(fieldAPIValue)) {
    //                     newAddr.put(fieldAPIName, fieldAPIValue);
    //                 }
    //                 addressListToUpsert.add(newAddr);
    //             }
                
    //             // Ensure type2 exists
    //             if (existingMap.containsKey(type2)) {
    //                 Applicant_Address__c addr = existingMap.get(type2);
    //                 addr.OCR_Address_Type__c = addressType;
    //                 addr.Document_Details__c = docId;
    //                 if (!String.isBlank(fieldAPIName) && !String.isBlank(fieldAPIValue)) {
    //                     addr.put(fieldAPIName, fieldAPIValue);
    //                 }
    //                 addressListToUpsert.add(addr);
    //             } else {
    //                 // Create type2 from type1 or blank
    //                 Applicant_Address__c base = existingMap.get(type1);
    //                 Applicant_Address__c newAddr = new Applicant_Address__c();
    //                 newAddr.Applicant__c = applicantId;
    //                 newAddr.Address_Type__c = type2;
    //                 newAddr.OCR_Address_Type__c = addressType;
    //                 newAddr.Address_Source__c = addressSource;
    //                 newAddr.Document_Details__c = docId;
                    
    //                 if (base != null) {
    //                     newAddr.Address_Line_1__c = base.Address_Line_1__c;
    //                     newAddr.Address_Line_2__c = base.Address_Line_2__c;
    //                     newAddr.Address_Line_3__c = base.Address_Line_3__c;
    //                     newAddr.Pincode__c = base.Pincode__c;
    //                 }
    //                 if (!String.isBlank(fieldAPIName) && !String.isBlank(fieldAPIValue)) {
    //                     newAddr.put(fieldAPIName, fieldAPIValue);
    //                 }
    //                 addressListToUpsert.add(newAddr);
    //             }
    //         }
            
    //         // Single address types
    //         else if (addressType == 'Current' || addressType == 'Permanent' || addressType == 'Registered' || addressType == 'Correspondence') {
    //             // Fetch all addresses with same type (regardless of source, to prevent duplication)
    //             List<Applicant_Address__c> existingList = [
    //                 SELECT Id, Address_Source__c, Address_Type__c 
    //                 FROM Applicant_Address__c 
    //                 WHERE Applicant__c = :applicantId 
    //                 AND Address_Type__c = :addressType
    //                 LIMIT 1
    //             ];
                
    //             Applicant_Address__c addr;
    //             if (!existingList.isEmpty()) {
    //                 addr = existingList[0];
    //             } else {
    //                 addr = new Applicant_Address__c();
    //                 addr.Applicant__c = applicantId;
    //                 addr.Address_Type__c = addressType;
    //             }
                
    //             // Always update these fields
    //             addr.OCR_Address_Type__c = addressType;
    //             addr.Address_Source__c = addressSource;
    //             addr.Document_Details__c = docId;
                
    //             if (!String.isBlank(fieldAPIName) && !String.isBlank(fieldAPIValue)) {
    //                 addr.put(fieldAPIName, fieldAPIValue);
    //             }
                
    //             upsert addr;
    //             return;
    //         }
            
            
    //         // Fallback for unknown address types
    //         else {
    //             List<Applicant_Address__c> existing = [
    //                 SELECT Id 
    //                 FROM Applicant_Address__c 
    //                 WHERE Applicant__c = :applicantId 
    //                 AND Address_Source__c = :addressSource 
    //                 LIMIT 1
    //             ];
                
    //             Applicant_Address__c addr = new Applicant_Address__c();
    //             if (!existing.isEmpty()) {
    //                 addr.Id = existing[0].Id;
    //             } else {
    //                 addr.Applicant__c = applicantId;
    //                 addr.Address_Source__c = addressSource;
    //             }
                
    //             addr.Document_Details__c = docId;
    //             if (!String.isBlank(fieldAPIName) && !String.isBlank(fieldAPIValue)) {
    //                 addr.put(fieldAPIName, fieldAPIValue);
    //             }
                
    //             addressListToUpsert.add(addr);
    //         }
            
    //         if (!addressListToUpsert.isEmpty()) {
    //             upsert addressListToUpsert;
    //         }
            
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }



    // @AuraEnabled
    // public static void saveAddressSource(String applicantId, String fieldAPIName, String fieldAPIValue,String addressType, String formIdentifier,String docId) {
    //     System.debug('fieldAPIValue------' +fieldAPIValue);
    //     System.debug('fieldAPIName------' +fieldAPIName);
    //     try {
    //         List<Applicant_Address__c> addressListToUpsert = new List<Applicant_Address__c>();
            
    //         if (addressType == 'Current' || addressType == 'Permanent') {
    //             List<Applicant_Address__c> existing = [
    //                 SELECT Id, Address_Source__c, Address_Type__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Pincode__c 
    //                 FROM Applicant_Address__c 
    //                 WHERE Applicant__c = :applicantId 
    //                 AND Document_Details__r.Document_Master__r.Name = :formIdentifier 
    //                 ORDER BY CreatedDate DESC 
    //                 LIMIT 1
    //             ];
    
    //             if (!existing.isEmpty()) {
    //                 existing[0].Address_Type__c = addressType;
    //                 existing[0].OCR_Address_Type__c = addressType;
    //                 existing[0].Document_Details__c = docId;
    //                 addressListToUpsert.add(existing[0]);
    //             }
    //         }
    //         else if (addressType == 'Permanent+Current') {
              
    //             List<Applicant_Address__c> existingAddList = [
    //                 SELECT Id, Address_Source__c, Address_Type__c, OCR_Address_Type__c,
    //                 Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Pincode__c 
    //                 FROM Applicant_Address__c 
    //                 WHERE Applicant__c = :applicantId 
    //                 AND Document_Details__r.Document_Master__r.Name = :formIdentifier
    //                 AND (Address_Type__c = 'Current' OR Address_Type__c = 'Permanent' OR Address_Type__c = null)
    //                 ORDER BY CreatedDate DESC
    //             ];
    
    //             Boolean currentExists = false;
    //             Boolean permExists = false;
    //             Boolean noTypeExists = false;
    //             Applicant_Address__c noTypeAddress;
                
    //             for (Applicant_Address__c addr : existingAddList) {
    //                 if (addr.Address_Type__c == 'Current') {
    //                     currentExists = true;
    //                 }
    //                 else if (addr.Address_Type__c == 'Permanent') {
    //                     permExists = true;
    //                 }
    //                 // else if (String.isBlank(addr.OCR_Address_Type__c)) {
    //                 //     noTypeExists = true;
    //                 //     noTypeAddress = addr;
    //                 // }
    //             }
    //             if(!currentExists  && !permExists){
    //                 noTypeExists = true;
    //                 noTypeAddress = new Applicant_Address__c();
    //             }
    
    //             if (currentExists && !permExists) {
    //                 for (Applicant_Address__c addr : existingAddList) {
    //                     if (addr.Address_Type__c == 'Current') {
    //                         addr.OCR_Address_Type__c= 'Permanent+Current';
    //                 addr.Document_Details__c = docId;
    //                 addressListToUpsert.add(addr);
    //                 Applicant_Address__c newAddr = new Applicant_Address__c();
    //                 newAddr.Applicant__c = applicantId;
    //                         newAddr.Address_Type__c = 'Permanent';
    //                         newAddr.OCR_Address_Type__c = 'Permanent+Current';
    //                 // newAddr.Address_Source__c = addressSource;
    //                         newAddr.Address_Line_1__c = addr.Address_Line_1__c;
    //                         newAddr.Address_Line_2__c = addr.Address_Line_2__c;
    //                         newAddr.Address_Line_3__c = addr.Address_Line_3__c;
    //                         newAddr.Pincode__c = addr.Pincode__c;
    //                 newAddr.Document_Details__c = docId;
    //                         addressListToUpsert.add(newAddr);
    //                         break;
    //                 }
    //                 }
                    
    //             }
    
    //             else if (permExists && !currentExists) {
    //                 for (Applicant_Address__c addr : existingAddList) {
    //                     if (addr.Address_Type__c == 'Permanent') {
    //                         addr.OCR_Address_Type__c= 'Permanent+Current';
    //                         addressListToUpsert.add(addr);
    //                         Applicant_Address__c newAddr = new Applicant_Address__c();
    //                         newAddr.Applicant__c = applicantId;
    //                                 newAddr.Address_Type__c = 'Current';
    //                                 newAddr.OCR_Address_Type__c = 'Permanent+Current';
    //                         // newAddr.Address_Source__c = addressSource;
    //                                 newAddr.Address_Line_1__c = addr.Address_Line_1__c;
    //                                 newAddr.Address_Line_2__c = addr.Address_Line_2__c;
    //                                 newAddr.Address_Line_3__c = addr.Address_Line_3__c;
    //                                 newAddr.Pincode__c = addr.Pincode__c;
    //                         newAddr.Document_Details__c = docId;
    //                         addressListToUpsert.add(newAddr);
    //                                 break;
    //                         }
    //                     }
    //             }
    //             else if(noTypeExists) {
    //                 // Update existing record to Permanent
    //                 noTypeAddress.OCR_Address_Type__c = 'Permanent+Current';
    //                 noTypeAddress.Address_Type__c = 'Permanent';
    //                 noTypeAddress.Applicant__c = applicantId;
    //                 if(existingAddList.size()>0){
    //                     noTypeAddress.Id = existingAddList[0].Id;
    //                 }
    //                 addressListToUpsert.add(noTypeAddress);
            
    //                 // Create one more as Current
    //                 Applicant_Address__c newCurrent = new Applicant_Address__c();
    //                 newCurrent.Applicant__c = applicantId;
    //                 newCurrent.Address_Type__c = 'Current';
    //                 newCurrent.OCR_Address_Type__c = 'Permanent+Current';
    //                 // newCurrent.Address_Source__c = addressSource;
    //                 newCurrent.Address_Line_1__c = noTypeAddress.Address_Line_1__c;
    //                 newCurrent.Address_Line_2__c = noTypeAddress.Address_Line_2__c;
    //                 newCurrent.Address_Line_3__c = noTypeAddress.Address_Line_3__c;
    //                 newCurrent.Pincode__c = noTypeAddress.Pincode__c;
    //                 newCurrent.Document_Details__c = docId;
    //                 addressListToUpsert.add(newCurrent);
    //             }
    //             else if (permExists && currentExists){
    //                 for(Applicant_Address__c applicantExt : existingAddList){
    //                     if(fieldAPIName!=null && fieldAPIValue!=null){
    //                         applicantExt.put(fieldAPIName,fieldAPIValue);
    //                         applicantExt.Document_Details__c = docId;
    //                         System.debug('applicantExt------'+applicantExt);
    //                         addressListToUpsert.add(applicantExt);
    //                     }
    //                 }
    //             }
    //         }
    //         else if (addressType == 'Registered' || addressType == 'Correspondence') {
    //             List<Applicant_Address__c> existing = [
    //                 SELECT Id, Address_Source__c,Document_Details__r.Document_Master__r.Name, Address_Type__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Pincode__c 
    //                 FROM Applicant_Address__c 
    //                 WHERE Applicant__c = :applicantId 
    //                 AND Document_Details__r.Document_Master__r.Name = :formIdentifier 
    //                 ORDER BY CreatedDate DESC 
    //                 LIMIT 1
    //             ];
    
    //             if (!existing.isEmpty()) {
    //                 if(addressType=='Registered'){
    //                     existing[0].Address_Type__c = 'Registered Office';
    //                 }
    //                 else{
    //                     existing[0].Address_Type__c = addressType;
    //                 }
                  
    //                 existing[0].OCR_Address_Type__c = addressType;
    //                 existing[0].Document_Details__c = docId;
    //                 addressListToUpsert.add(existing[0]);
    //             }
    //         }
    //         else if (addressType == 'Registered + Correspondence') {
              
    //             List<Applicant_Address__c> existingAddList = [
    //                 SELECT Id, Address_Source__c,Document_Details__r.Document_Master__r.Name, Address_Type__c, OCR_Address_Type__c,
    //                 Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Pincode__c 
    //                 FROM Applicant_Address__c 
    //                 WHERE Applicant__c = :applicantId 
    //                 AND Document_Details__r.Document_Master__r.Name = :formIdentifier
    //                 AND (Address_Type__c = 'Correspondence' OR Address_Type__c = 'Registered' OR Address_Type__c = null)
    //                 ORDER BY CreatedDate DESC
    //             ];
    
    //             Boolean currentExists = false;
    //             Boolean permExists = false;
    //             Boolean noTypeExists = false;
    //             Applicant_Address__c noTypeAddress;
                
    //             for (Applicant_Address__c addr : existingAddList) {
    //                 if (addr.Address_Type__c == 'Correspondence') {
    //                     currentExists = true;
    //                 }
    //                 else if (addr.Address_Type__c == 'Registered Office') {
    //                     permExists = true;
    //                 }
    //                 // else if (String.isBlank(addr.OCR_Address_Type__c)) {
    //                 //     noTypeExists = true;
    //                 //     noTypeAddress = addr;
    //                 // }
    //             }
    //             if(!currentExists  && !permExists){
    //                 noTypeExists = true;
    //                 noTypeAddress = new Applicant_Address__c();
    //             }
    
    //             if (currentExists && !permExists) {
    //                 for (Applicant_Address__c addr : existingAddList) {
    //                     if (addr.Address_Type__c == 'Correspondence') {
    //                         addr.OCR_Address_Type__c= 'Registered + Correspondence';
    //                 addr.Document_Details__c = docId;
    //                 addressListToUpsert.add(addr);
    //                 Applicant_Address__c newAddr = new Applicant_Address__c();
    //                 newAddr.Applicant__c = applicantId;
    //                         newAddr.Address_Type__c = 'Registered Office';
    //                         newAddr.OCR_Address_Type__c = 'Registered + Correspondence';
    //                 // newAddr.Address_Source__c = addressSource;
    //                         newAddr.Address_Line_1__c = addr.Address_Line_1__c;
    //                         newAddr.Address_Line_2__c = addr.Address_Line_2__c;
    //                         newAddr.Address_Line_3__c = addr.Address_Line_3__c;
    //                         newAddr.Pincode__c = addr.Pincode__c;
    //                 newAddr.Document_Details__c = docId;
    //                         addressListToUpsert.add(newAddr);
    //                         break;
    //                 }
    //                 }
                    
    //             }
    
    //             else if (permExists && !currentExists) {
    //                 for (Applicant_Address__c addr : existingAddList) {
    //                     if (addr.Address_Type__c == 'Registered Office') {
    //                         addr.OCR_Address_Type__c= 'Registered + Correspondence';
    //                         addressListToUpsert.add(addr);
    //                         Applicant_Address__c newAddr = new Applicant_Address__c();
    //                         newAddr.Applicant__c = applicantId;
    //                                 newAddr.Address_Type__c = 'Correspondence';
    //                                 newAddr.OCR_Address_Type__c = 'Registered + Correspondence';
    //                         //newAddr.Address_Source__c = addressSource;
    //                                 newAddr.Address_Line_1__c = addr.Address_Line_1__c;
    //                                 newAddr.Address_Line_2__c = addr.Address_Line_2__c;
    //                                 newAddr.Address_Line_3__c = addr.Address_Line_3__c;
    //                                 newAddr.Pincode__c = addr.Pincode__c;
    //                         newAddr.Document_Details__c = docId;
    //                         addressListToUpsert.add(newAddr);
    //                                 break;
    //                         }
    //                     }
    //             }
    //             else if(noTypeExists) {
    //                 // Update existing record to Permanent
    //                 noTypeAddress.OCR_Address_Type__c = 'Registered + Correspondence';
    //                 noTypeAddress.Address_Type__c = 'Registered Office';
    //                 noTypeAddress.Applicant__c = applicantId;
    //                 if(existingAddList.size()>0){
    //                     noTypeAddress.Id = existingAddList[0].Id;
    //                 }
    //                 addressListToUpsert.add(noTypeAddress);
            
    //                 // Create one more as Current
    //                 Applicant_Address__c newCurrent = new Applicant_Address__c();
    //                 newCurrent.Applicant__c = applicantId;
    //                 newCurrent.Address_Type__c = 'Correspondence';
    //                 newCurrent.OCR_Address_Type__c = 'Registered + Correspondence';
    //                 //newCurrent.Address_Source__c = addressSource;
    //                 newCurrent.Address_Line_1__c = noTypeAddress.Address_Line_1__c;
    //                 newCurrent.Address_Line_2__c = noTypeAddress.Address_Line_2__c;
    //                 newCurrent.Address_Line_3__c = noTypeAddress.Address_Line_3__c;
    //                 newCurrent.Pincode__c = noTypeAddress.Pincode__c;
    //                 newCurrent.Document_Details__c = docId;
    //                 addressListToUpsert.add(newCurrent);
    //             }
    //             else if (permExists && currentExists){
    //                 for(Applicant_Address__c applicantExt : existingAddList){
    //                     if(fieldAPIName!=null && fieldAPIValue!=null){
    //                         applicantExt.put(fieldAPIName,fieldAPIValue);
    //                         applicantExt.Document_Details__c = docId;
    //                         System.debug('applicantExt------'+applicantExt);
    //                         addressListToUpsert.add(applicantExt);
    //                     }
    //                 }
    //             }
    //         }


    //         else{
    //             List<Applicant_Address__c> existing = [
    //                 SELECT Id, Address_Source__c, Document_Details__r.Document_Master__r.Name,Address_Type__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Pincode__c 
    //                 FROM Applicant_Address__c 
    //                 WHERE Applicant__c = :applicantId 
    //                 AND Document_Details__r.Document_Master__r.Name = :formIdentifier 
    //                 ORDER BY CreatedDate DESC 
    //                 LIMIT 1
    //             ];
                
    //             Applicant_Address__c appAddress = new Applicant_Address__c();
    //             appAddress.Applicant__c=applicantId;
    //             appAddress.Document_Details__c = docId;
    //             appAddress.put(fieldAPIName,fieldAPIValue);
    //             if(existing.size()>0){
    //                 appAddress.id = existing[0].id;  
    //             }
    //             else{
    //             //     if(addressSource!=null){
    //             //         // appAddress.Address_Source__c=addressSource;
    //             // }
                
    //             }
    //             addressListToUpsert.add(appAddress);

    //         }
            
    //         if (!addressListToUpsert.isEmpty()) {
    //             upsert addressListToUpsert;
    //         }
            
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }

  @AuraEnabled
    public static void saveAddressSource(String applicantId, String fieldAPIName, String fieldAPIValue,List<String> multiselectValues, String formIdentifier,String docId,List<String> addressTypeValue ){
        try {
            Boolean flag = true;
            List<Applicant_Address__c> addressToUpdate = new  List<Applicant_Address__c> ();
            List<Applicant_Address__c> addressListToUpsert = new List<Applicant_Address__c>();
            List<Applicant_Address__c> existingAddList = [
                SELECT Id, Address_Source__c, Address_Type__c, OCR_Address_Type__c,
                Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Pincode__c,Flag_PO_as_High__c,Flag_Current_Registred_as_Very_High__c,Address_Ownership__c
                FROM Applicant_Address__c  
                WHERE Applicant__c = :applicantId 
                AND Document_Details__r.Document_Master__r.Name = :formIdentifier
                AND Document_Details__c= :docId
                ORDER BY CreatedDate DESC
            ];
            Map<String, Applicant_Address__c> existingAddressMap = new Map<String, Applicant_Address__c>();
            for (Applicant_Address__c addr : existingAddList) {
                if (addr.Address_Type__c != null) {
                    existingAddressMap.put(addr.Address_Type__c, addr);
                }
            }
            for(String addVal : existingAddressMap.keySet()){
                Applicant_Address__c add = new Applicant_Address__c();
                if( multiselectValues.size() > 0 ){
                    if(!multiselectValues.contains(addVal)){
                    //addressToDelete.add(existingAddressMap.get(addVal));
                        add.Id = existingAddressMap.get(addVal).Id;
                        add.Address_Type__c = '';
                        add.Flag_Current_Registred_as_Very_High__c = false;
                        add.Flag_PO_as_High__c = false;
                        add.Address_Priority__c = '';
                        addressToUpdate.add(add);
                    }
                }
                else{
                    //addressToDelete.add(existingAddressMap.get(addVal));
                        add.Id = existingAddressMap.get(addVal).Id;
                        add.Address_Type__c = '';
                        add.Flag_Current_Registred_as_Very_High__c = false;
                        add.Flag_PO_as_High__c = false;
                        add.Address_Priority__c = '';
                        addressToUpdate.add(add);
                    }
            }
            if(addressToUpdate.size()>0){
                update addressToUpdate;
            }
        
            if (multiselectValues != null && multiselectValues.size() > 0) {
                Set<Id> Ids = new Set<Id>();
                for (String selectedType : multiselectValues) {
                    selectedType = selectedType.replaceAll('"','');   
                    if (existingAddressMap.containsKey(selectedType)) {
                        Applicant_Address__c existingAddress = existingAddressMap.get(selectedType);
                        if(fieldAPIName!=null && fieldAPIValue!=null){
                            if(fieldAPIName == 'Flag_Current_Registred_as_Very_High__c' && (existingAddress.Address_Type__c == 'Current' || existingAddress.Address_Type__c == 'Registered Office')){
                                existingAddress.put(fieldAPIName, Boolean.valueOf(fieldAPIValue));
                            } 
                            if(fieldAPIName == 'Flag_PO_as_High__c' && (existingAddress.Address_Type__c == 'Permanent' || existingAddress.Address_Type__c == 'Business Operational')){
                                existingAddress.put(fieldAPIName, Boolean.valueOf(fieldAPIValue));
                            } 
                            if(fieldAPIName != 'Flag_Current_Registred_as_Very_High__c' && fieldAPIName != 'Flag_PO_as_High__c'){
                                existingAddress.put(fieldAPIName,fieldAPIValue);
                            }
                            if(fieldAPIName == 'Address_Type__c' && (fieldAPIValue == 'Permanent' || fieldAPIValue == 'Business Operational')){
                                existingAddress.Flag_Current_Registred_as_Very_High__c = false;  
                            }
                            if(fieldAPIName == 'Address_Type__c' && (fieldAPIValue == 'Current' || fieldAPIValue == 'Registered Office')){
                                existingAddress.Flag_PO_as_High__c = false;  
                            }
                        }
                        if(!addressListToUpsert.contains(existingAddress)){
                            addressListToUpsert.add(existingAddress);
                        }
                       
                    } 
                    else {
                        Applicant_Address__c newAddress = new Applicant_Address__c();
                        if(existingAddList.size() == 1 && existingAddList[0].Address_Type__c == null && flag == true){
                        }
                        else{
                            if(existingAddList.size()>0){
                                newAddress = existingAddList[0].clone(false,true,false,false);
                            }
                        }
                        newAddress.Applicant__c = applicantId;
                        newAddress.Document_Details__c=docId;
                        newAddress.Address_Type__c = selectedType;
                        if(newAddress.Address_Type__c == 'Permanent' || newAddress.Address_Type__c == 'Business Operational'){
                            newAddress.Flag_Current_Registred_as_Very_High__c = false;  
                        }
                        if(newAddress.Address_Type__c == 'Current' || newAddress.Address_Type__c == 'Registered Office'){
                            newAddress.Flag_PO_as_High__c = false;  
                        }
                        if(existingAddList.size()==1 && flag == true && !Ids.contains(existingAddList[0].id)){
                            if(existingAddList[0].Address_Type__c == null){
                                newAddress.id =existingAddList[0].id;
                            }
                            if(existingAddList[0].Address_Type__c != null){
                                newAddress.Address_Line_1__c = existingAddList[0].Address_Line_1__c;
                                newAddress.Address_Line_2__c = existingAddList[0].Address_Line_2__c;
                                newAddress.Address_Line_3__c = existingAddList[0].Address_Line_3__c;
                                newAddress.Pincode__c = existingAddList[0].Pincode__c;
                                newAddress.Address_Ownership__c = existingAddList[0].Address_Ownership__c;
                            }
                            flag = false;
                        }

                        if(existingAddList.size()==2 && flag == true){
                            if(existingAddList[0].Address_Type__c == null && newAddress.id == null && !Ids.contains(existingAddList[0].id)){
                                newAddress.id =existingAddList[0].id;
                            }
                            if(existingAddList[1].Address_Type__c == null && newAddress.id == null && !Ids.contains(existingAddList[1].id)){
                                newAddress.id =existingAddList[1].id;
                            }
                            if(existingAddList[0].Address_Type__c != null){
                                newAddress.Address_Line_1__c = existingAddList[0].Address_Line_1__c;
                                newAddress.Address_Line_2__c = existingAddList[0].Address_Line_2__c;
                                newAddress.Address_Line_3__c = existingAddList[0].Address_Line_3__c;
                                newAddress.Pincode__c = existingAddList[0].Pincode__c;
                                newAddress.Address_Ownership__c = existingAddList[0].Address_Ownership__c;
                            }
                        }
                        
                        if(fieldAPIName!=null && fieldAPIValue!=null){
                            if(fieldAPIName == 'Flag_Current_Registred_as_Very_High__c' && (newAddress.Address_Type__c == 'Current' || newAddress.Address_Type__c == 'Registered Office')){
                                newAddress.put(fieldAPIName, Boolean.valueOf(fieldAPIValue));
                            } 
                            if(fieldAPIName == 'Flag_PO_as_High__c' && (newAddress.Address_Type__c == 'Permanent' || newAddress.Address_Type__c == 'Business Operational')){
                                newAddress.put(fieldAPIName, Boolean.valueOf(fieldAPIValue));
                            } 
                            if(fieldAPIName != 'Flag_Current_Registred_as_Very_High__c' && fieldAPIName != 'Flag_PO_as_High__c'){
                                newAddress.put(fieldAPIName,fieldAPIValue);
                            }
                        }
                        newAddress.Flag_PO_as_High__c = false;  
                        newAddress.Flag_Current_Registred_as_Very_High__c = false; 
                        if(newAddress.Id != null){
                            Ids.add(newAddress.Id);
                        }
                        if(!addressListToUpsert.contains(newAddress)){
                            addressListToUpsert.add(newAddress);
                        }
                       
                    }
                }
            }
            else{
                if(fieldAPIName!= null && fieldAPIValue!=null)
                {
                    List<Applicant_Address__c> existing = [
                        SELECT Id, Address_Source__c, Document_Details__r.Document_Master__r.Name,Address_Type__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Pincode__c,Flag_PO_as_High__c,Flag_Current_Registred_as_Very_High__c,Address_Ownership__c 
                        FROM Applicant_Address__c 
                        WHERE Applicant__c = :applicantId 
                        AND Document_Details__r.Document_Master__r.Name = :formIdentifier 
                        AND Document_Details__c = :docId
                        ORDER BY CreatedDate DESC 
                        LIMIT 1
                    ];
                    
                    Applicant_Address__c appAddress = new Applicant_Address__c();
                    appAddress.Applicant__c=applicantId;
                    appAddress.Document_Details__c = docId;
                    system.debug('In else If '+ appAddress.Address_Type__c);
                    if(fieldAPIName == 'Flag_Current_Registred_as_Very_High__c' && (appAddress.Address_Type__c == 'Current' || appAddress.Address_Type__c == 'Registered Office')){
                        appAddress.put(fieldAPIName, Boolean.valueOf(fieldAPIValue));
                    } 
                    if(fieldAPIName == 'Flag_PO_as_High__c' && (appAddress.Address_Type__c == 'Permanent' || appAddress.Address_Type__c == 'Business Operational')){
                        appAddress.put(fieldAPIName, Boolean.valueOf(fieldAPIValue));
                    } 
                    if(fieldAPIName != 'Flag_Current_Registred_as_Very_High__c' && fieldAPIName != 'Flag_PO_as_High__c'){
                        appAddress.put(fieldAPIName,fieldAPIValue);
                    }
                    if(fieldAPIName == 'Address_Type__c' && (fieldAPIValue == 'Permanent' || fieldAPIValue == 'Business Operational')){
                        appAddress.Flag_Current_Registred_as_Very_High__c = false;  
                    }
                    if(fieldAPIName == 'Address_Type__c' && (fieldAPIValue == 'Current' || fieldAPIValue == 'Registered Office')){
                        appAddress.Flag_PO_as_High__c = false;  
                    }
                    if(existing.size()>0){
                        appAddress.id = existing[0].id;  
                    }
                    else{
                    //     if(addressSource!=null){
                    //         // appAddress.Address_Source__c=addressSource;
                    // }
                    
                    }
                    addressListToUpsert.add(appAddress);

                }
            }
            if (!addressListToUpsert.isEmpty() ) {
                if(!System.Test.isRunningTest()){ 
                    upsert addressListToUpsert;}
                Utility.updateTriangulationManualAddressData(applicantId, formIdentifier, docId);
            }
        }
        catch (Exception e) {
            System.debug('test 2'+e.getMessage()+'at line number '+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }


    }
    @AuraEnabled
    public static Boolean checkApplicantProfile(String loanId){
        Boolean isApplicantProfileSEP= false;
        try {
            List<Application_Applicant__c> applicantList= [SELECT Id, Customer_Profile__c, Loan_Application__r.Nature_of_Business__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId AND Applicant_Type__c = 'Primary Applicant'];
            if(applicantList.size()>0){
                if(applicantList[0].Customer_Profile__c == 'SEP'){
                    isApplicantProfileSEP=true;
                    // if(applicantList[0].Loan_Application__r.Nature_of_Business__c!= null && applicantList[0].Loan_Application__r.Nature_of_Business__c!= ''){
                    Opportunity opp= new Opportunity();
                    opp.Id= loanId;
                    opp.Nature_of_Business__c = 'NON IT SERVICE';
                    update opp;
                    // }
                    
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return isApplicantProfileSEP;
    }
    
    @AuraEnabled(Cacheable=true)
    public static Boolean checkExceptionStatus(String loanId){
        boolean isExceptionStatus = false;
        try{
            Id profileId = userinfo.getProfileId();
            String profileName = [Select Id,Name from Profile where Id=:profileId].Name;
            
            List<Opportunity> oppList = [SELECT Id,Exception_Approval_Status__c FROM Opportunity WHERE Id =: loanId LIMIT 1];
            if(oppList[0].Exception_Approval_Status__c == 'Submitted For Approval' && profileName == 'Sales'){
                isExceptionStatus = true;
            }
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return isExceptionStatus;
    }

     @AuraEnabled
    public static Map<string, string> uploadFile(Map<string, object> uploadParam) {
        //system.debug('uploadParam: '+uploadParam);
        Savepoint sp = Database.setSavepoint();
        Map<string, string> result = new Map<string, string>();
        try {
            //Map<String, Object> compressedAPIresult  = null;
            Set<Id> shareWithUserId = new Set<Id>();
            String contentDocId           = (string) uploadParam.get('contentDocId');
            String docDetailId      = (string) uploadParam.get('docDetailId');
            string docName          = (string) uploadParam.get('docName');
            //string otherDocName     = (string) uploadParam.get('otherDocName');
            //String docLinkRecodId   = (string) uploadParam.get('docLinkRecodId');
            Decimal latitude        = (Decimal) uploadParam.get('latitude');
            Decimal longitude       = (Decimal) uploadParam.get('longitude');
            String bank             = (string)uploadParam.get('bank');
            String passWord         = (string)uploadParam.get('password');
            String toDate           = (string)uploadParam.get('toDate');
            String fromDate         =  (string)uploadParam.get('fromDate');
            String bankDetails      =  (string)uploadParam.get('bankDetails');
            String drawingPower     =  (string)uploadParam.get('drawingPower');
            String multipleFilesDocumentId  =  (string)uploadParam.get('multipleFilesDocumentId');
            String sanctionLimit =  (string)uploadParam.get('sanctionLimit');
            String accountType =  (string)uploadParam.get('accountType');
            // Boolean eSignflag       =  (Boolean)uploadParam.get('eSignflag');
            String institutionId;
            String bankAccountId;
            if(bankDetails!=null && bankDetails!=''){
                // Bank_Details__c bankdetail = (Bank_Details__c) JSON.deserialize(String.valueOf(uploadParam.get('bankDetails')), Bank_Details__c.class);
                //system.debug('bankdetail'+bankdetails);
                // String bankName = bankdetail.Name;
                //String branchId= bankDetails;
                List<Bank_Branch_Master__c> bankMasterList = [
                    SELECT Id, Bank_Name__c, Institution_Id__c
                    FROM Bank_Branch_Master__c 
                    WHERE id = :bankDetails 
                ];
                institutionId = String.valueof(bankMasterList[0].Institution_Id__c);
                bankAccountId= bankDetails;
            
            }
            if(string.isNotBlank(multipleFilesDocumentId)) {
                //system.debug('2185---');
                Document_Details__c dd = new Document_Details__c();
                dd.id = multipleFilesDocumentId;
                dd.Year_Month_To__c =Date.valueof(toDate);
                dd.Year_Month_From__c =Date.valueof(fromDate);
                dd.Password__c  = passWord;
                dd.Sanction_Amount__c =sanctionLimit;
                if(institutionId!= null){
                    dd.Institution_Id__c = Decimal.valueof(institutionId);
                }
                dd.Bank__c=bank;
                dd.Bank_Branch_Master__c= bankAccountId;
                dd.Drawing_Power_Amount__c = drawingPower;
                dd.Consider_for_Loan_Application__c = true;
                update dd ;
                //system.debug('dd: '+dd);
                docDetailId = dd.Id;
                List<Document_Details__c> docList = [SELECT Id,Name,Document_Master__r.Document_Category__c,Loan_Application__c from Document_Details__c where id =: docDetailId];
                Opportunity opp= [Select id, Account_Type__c from Opportunity where id=:docList[0].Loan_Application__c];
                if(accountType.contains('Current')||accountType.contains('Saving')){
                    accountType='NONE';
                }
                else if(accountType.contains('Overdraft')){
                    accountType='OD';
                }
                else if(accountType.contains('Cash Credit')){
                     accountType='CC';
                }
                opp.Account_Type__c=accountType;
                update opp;
                //system.debug('docList.size()2214'+docList.size());
                if(docList.size()>0){
                        result.put('docName', docName +' ('+ docList[0].Document_Master__r.Document_Category__c +')');
                }
                

                //system.debug('result2219--'+result);
            }
            else{
                //system.debug('2222----');
            ContentVersion cvRecVersionId = [Select Id, VersionData, title, FileType, ContentDocumentId from ContentVersion where ContentDocumentId =:contentDocId];
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = docDetailId;
            cdl.ContentDocumentId = contentDocId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;

            //Document_Details__c dde = [Select Id,name,Applicant__c,Loan_Application__c,Document_Master__c from Document_Details__c where Id=:docDetailId];
            

                Document_Details__c dd = new Document_Details__c (
                    Id = docDetailId,
                    Content_Document_Id__c = cvRecVersionId.ContentDocumentId,
                    Status__c = 'Uploaded',
                    Location__Latitude__s = latitude,
                    Location__Longitude__s = longitude,
                    Uploaded_Date_Time__c = System.Now()
                );
                update dd;
                  List<Document_Details__c> doc  = [SELECT Id,Name from Document_Details__c where id =: docDetailId];
            if(doc.size()>0){
                result.put('docName',doc[0].Name);
            }
            // Create sharing records for the document
            if(!shareWithUserId.isEmpty()) {

                List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
                for(Id i : shareWithUserId) {
                    Utility.SharingInfo si = new Utility.SharingInfo();
                    si.objectName = 'Document_Details__c';
                    si.userOrGroupId = i;
                    si.recordToShareId = docDetailId;
                    si.sharingAccess = 'Edit';
                    sharingList.add(si);
                }

                //System.debug('sharingList: '+sharingList);
                Utility.createShareRecord(JSON.serialize(sharingList));
            }
            result.put('ContentVersionId2263', cvRecVersionId.Id);
            result.put('ContentDocumentId2263', cvRecVersionId.ContentDocumentId);
            result.put('FileType2265', cvRecVersionId.FileType);
            result.put('uploadedFileName2266',cvRecVersionId.title );
            }
            result.put('docDetailId', docDetailId);
        
            //system.debug('result2270--'+result);
            //return result;
        }
        catch(Exception e) {
            //System.debug('Error: ' + e);
            //System.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
            Database.rollback(sp);
        }
        
        return result;
    }


    @AuraEnabled
    public static List<String> getAllRelatedAddresses(String docheckId, String appId){
         List<String> addressTypeList = new List<String>();
    
        try {
            List<Applicant_Address__c> addressList;
        
           if (docheckId != null) {
            addressList = [SELECT Id, Address_Type__c 
                           FROM Applicant_Address__c 
                           WHERE Applicant__c = :appId 
                           AND Document_Details__c = :docheckId 
                           AND Address_Type__c != null 
                           ORDER BY CreatedDate DESC];
            } else {
            addressList = [SELECT Id, Address_Type__c 
                           FROM Applicant_Address__c 
                           WHERE Applicant__c = :appId 
                           AND Document_Details__c != null 
                           AND Address_Type__c != null];
            }
        
            for (Applicant_Address__c addr : addressList) {
            if (!addressTypeList.contains(addr.Address_Type__c)) {
                addressTypeList.add(addr.Address_Type__c);
                }
            }
           } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
       }
    
        return addressTypeList;
  }

    @AuraEnabled
    public static List<String> getRelatedDocAddressType(String docId){
        List<String> addressTypeList = new  List<String> ();
        List<Document_Details__c> docList = [Select id, Document_Master__r.Address_Type__c from Document_Details__c where Id =: docId];
          if(docList.size() > 0 && docList[0].Document_Master__r != null && String.isNotBlank(docList[0].Document_Master__r.Address_Type__c)){
              addressTypeList = docList[0].Document_Master__r.Address_Type__c.split(';');
        }
        return addressTypeList;
    }

    /*@AuraEnabled
    public static List<string> getAllRelatedDocAddressType(String appId){
        try {
            List<String> addressTypeList = new  List<String> ();
            List<Applicant_Address__c> addList = [Select id,Address_Type__c from Applicant_Address__c where Document_Details__c!=null AND Applicant__c =: appId];
                for(Applicant_Address__c addr : addList){
                    addressTypeList.add(addr.Address_Type__c);
                }
                return addressTypeList;
            } 
            catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }*/
    @AuraEnabled
    public static void removeDocumentDetailsFromCompletionStage(Id recordId) {
        Opportunity loanApp = [SELECT Id, Login_Completion_Stage__c FROM Opportunity WHERE Id = :recordId LIMIT 1];
    
        if (loanApp.Login_Completion_Stage__c != null) {
            List<String> stages = new List<String>();
            stages.addAll(loanApp.Login_Completion_Stage__c.split(';'));
    
            Integer indexToRemove = -1;
            for (Integer i = 0; i < stages.size(); i++) {
                if (stages[i].trim() == 'Document Details') {
                    indexToRemove = i;
                    break;
                }
            }
    
            if (indexToRemove != -1) {
                stages.remove(indexToRemove);
                loanApp.Login_Completion_Stage__c = String.join(stages, ';');
                update loanApp;
            }
        }
    }
    /*@AuraEnabled
    public static Boolean checkExistingAddressWithDocument(Id applicantId, String addressType) {
        List<Applicant_Address__c> existingAddresses = [
            SELECT Id FROM Applicant_Address__c
            WHERE Applicant__c = :applicantId
            AND Address_Type__c = :addressType
            AND Document_Details__c != null
            LIMIT 1
        ];
        return !existingAddresses.isEmpty();
    }*/
    @AuraEnabled
    public static Boolean checkExistingAddresses(Id applicantId, List<String> addressTypes) {
        List<Applicant_Address__c> existing = [
            SELECT Id
            FROM Applicant_Address__c
            WHERE Applicant__c = :applicantId
            AND Address_Type__c IN :addressTypes
            AND Document_Details__c != null
            LIMIT 1
        ];
        return !existing.isEmpty();
    }
    
    @AuraEnabled
    public static List<String> getCoApplicantRelationFieldValues( String loanId, String applicantId){
        List<String> relationshipValues= new List<String>();
        try {
            List<Application_Applicant__c> applicantList= [SELECT Id, Applicant_Type__c, Sector__c FROM Application_Applicant__c WHERE  Loan_Application__c = :loanId ORDER BY CreatedDate ASC];
            Integer coApplicants= 0;
            String constitution='';
            Integer count=1;
            Map<String, Integer> applicantCount = new Map<String, Integer>();
            for(Application_Applicant__c applicant: applicantList){
                if(applicant.Applicant_Type__c == 'Co Applicant'){
                    coApplicants++;
                    applicantCount.put(applicant.Id, count);
                    count++;
                }else if(applicant.Applicant_Type__c == 'Primary Applicant'){
                    constitution = applicant.Sector__c;
                }
            }
            //System.debug('applicantCount---'+applicantCount);
            if(constitution!= null && constitution != ''){
                List<NonIndividual_Applicant_Relation_Mapping__mdt> relationMapping = [SELECT Id, Constitution__c, First_co_applicant_relation__c, Second_co_applicant_relation__c FROM NonIndividual_Applicant_Relation_Mapping__mdt WHERE Constitution__c = :constitution];
                if(relationMapping.size() >0){
                    if(applicantCount.get(applicantId)==1){
                        relationshipValues.addAll(relationMapping[0].First_co_applicant_relation__c.split(','));
                    }
                    // if(coApplicants == 1){
                        
                    // }
                    // else if(coApplicants > 1){
                    else {
                        relationshipValues.addAll(relationMapping[0].Second_co_applicant_relation__c.split(','));
                    }
                }
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
            //System.debug('Exception----'+e.getMessage());
        }

        return relationshipValues;
    }

    @AuraEnabled
    public static String checkPanAndBureau(String applicantList, String recordId) {
        String returnVal = '';
        Boolean cibilFetched = true;
        try {
            //String flag = '';
            List<Application_Applicant__c> appList = [
                SELECT Id, Pan_Status__c,Basic_Details_Filled__c ,Customer_Profile__c,Employer_Name__c,Is_Financial_applicant__c,Cibil_Score__c, IsForm60Uploaded__c,Applicant_Type__c, Customer_Type__c,seeding_status__C
                FROM Application_Applicant__c 
                WHERE Loan_Application__c = :recordId
            ];

            for (Application_Applicant__c app : appList) {
                if (app.Customer_Type__c == 'Individual') {
                if((String.isBlank(app.Basic_Details_Filled__c ))){
                    returnVal = 'Basic details of one or more applicants are missing.';
                    return returnVal;
                }
                if((app.Customer_Profile__c.contains('Salaried') && String.isBlank(app.Employer_Name__c) && app.Is_Financial_applicant__c == 'Yes')){
                    returnVal = 'Employment Details of one or more applicants are missing.';
                    return returnVal;

                }
               if(String.isBlank(app.Pan_Status__c) && String.isBlank(String.valueOf(app.Cibil_Score__c)) && String.isBlank(app.IsForm60Uploaded__c)){

                        cibilFetched = false;
                 }

                else if ((String.isBlank(app.Pan_Status__c) && String.isBlank(String.valueOf(app.Cibil_Score__c))) || 
                    (String.isBlank(app.IsForm60Uploaded__c) && String.isBlank(String.valueOf(app.Cibil_Score__c))) ||

                    (String.isNotBlank(app.Pan_Status__c) && String.isBlank(String.valueOf(app.Cibil_Score__c))) ||
                    (String.isNotBlank(app.IsForm60Uploaded__c)  && String.isBlank(String.valueOf(app.Cibil_Score__c))))
                     {
                       cibilFetched = false;
                        
                    }
                    if(!cibilFetched){
                        returnVal = 'The applicant\'s bureau information has not been fetched or PAN has not been validated for one or more applicants.';
                       // throw new AuraHandledException(returnVal);
                    }
                    //Alika S
                    if(app.Pan_Status__c =='Invalid')
                    {
                        returnVal = 'PAN is Invalid';
                    }
                    //Alika E
                }  
                else if (app.Customer_Type__c == 'Non Individual') {
                   if((String.isBlank(app.Basic_Details_Filled__c ))){
                    returnVal = 'Basic details of one or more applicants are missing.';
                    return returnVal;
                }
                if((app.Customer_Profile__c.contains('Salaried') && String.isBlank(app.Employer_Name__c))){
                    returnVal = 'Employment Details of one or more applicants are missing.';
                    return returnVal;

                }
               if(String.isBlank(app.Pan_Status__c) && String.isBlank(String.valueOf(app.Cibil_Score__c)) && String.isBlank(app.IsForm60Uploaded__c)){
                        cibilFetched = false;
                 }

                else if ((String.isBlank(app.Pan_Status__c) && String.isBlank(String.valueOf(app.Cibil_Score__c))) || 
                    (String.isBlank(app.IsForm60Uploaded__c) && String.isBlank(String.valueOf(app.Cibil_Score__c)))) {
                       cibilFetched = false;
                        
                    }
                    if(!cibilFetched){
                        returnVal = 'The applicant\'s bureau information has not been fetched or PAN has not been validated for one or more applicants.';
                       // throw new AuraHandledException(returnVal);
                    }
                }
              /*  if (app.Customer_Type__c == 'Individual') {
                    if(String.isBlank(app.Pan_Status__c) && !String.isBlank(String.valueOf(app.Cibil_Score__c))){
                        returnVal = 'PanStatusBlank';
                    }

                    else if ((String.isBlank(app.Pan_Status__c) && String.isBlank(String.valueOf(app.Cibil_Score__c))) || 
                    (String.isBlank(app.IsForm60Uploaded__c) && String.isBlank(String.valueOf(app.Cibil_Score__c)))) {
                        returnVal = 'AllDetailsBlank';
                        
                    }
                }  
                else if (app.Customer_Type__c == 'Non Individual') {
                    if (String.isBlank(app.Pan_Status__c)) {
                        returnVal = 'PanStatusBlank';
                          
                    }
                }*/
            }

            
        } catch (Exception e) {
            System.debug('Exception in checkPanAndBureau: ' + e.getMessage() + ' StackTrace: ' + e.getStackTraceString());
            throw new AuraHandledException(e.getStackTraceString());
           // returnVal = 'Error';
        }
        return returnVal;
    }

 //Multiple Files
    @AuraEnabled
    public static String createDocumentChecklistForSales(Map<String,String> uploadParam){
        String docDetailId;
        try{  
            string docName = (string) uploadParam.get('docName');
            string selfFundedName = 'Login Fee Receipt';
            //String loanid  = (string) uploadParam.get('loanid');
            String docRequiredFor  = (string) uploadParam.get('docRequiredFor');
            String docCategory  = (string) uploadParam.get('docCategory');
            //String manualAA  = (string) uploadParam.get('manualAA');
            String applicantId = (string) uploadParam.get('applicantId');
              Document_Details__c dd = new Document_Details__c();
            string sQuery = 'Select Id, Is_Required__c, Document_Category__c From Document_Master__c Where Is_Active__c = true ';
             switch on docRequiredFor {

                when 'Income Bank Statement'{
                    sQuery += ' AND Name = :docName AND Requirement_At__c = \'Applicant Level\' AND Document_Category__c =: docCategory LIMIT 1';

                    dd.Applicant__c=applicantId;
                    dd.Process_Name__c ='Income Bank Statement';
                    //dd.Manual_AA__c=(string) uploadParam.get('manualAA');
                    dd.Loan_Application__c=(string)uploadParam.get('loanid');
                     // DEMO DATA
                    dd.Bank_Name__c = 'Kotak Mahindra Bank';
                    dd.Manual_AA__c = 'Manual';
                    dd.Is_BSA_Initated__c = false;
                }

                when 'Login Fee Receipt'{
                    sQuery += ' AND Name = :docName  AND Document_Category__c =: docCategory LIMIT 1';
                    dd.Process_Name__c ='Login Fee';
                    dd.Manual_AA__c=(string) uploadParam.get('manualAA');
                    dd.Loan_Application__c=(string)uploadParam.get('loanid');
                }
                 when 'Self Funded'{
                    sQuery += ' AND Name = :selfFundedName  AND Document_Category__c =: docCategory LIMIT 1';
                    dd.Process_Name__c ='Upfront Charges Login Fee';
                    dd.Manual_AA__c=(string) uploadParam.get('manualAA');
                    dd.Loan_Application__c=(string)uploadParam.get('loanid');
                }
                when 'ITR'{
                    sQuery += ' AND Name = :docName AND Requirement_At__c = \'Applicant Level\' AND Document_Category__c =: docCategory LIMIT 1';
                     dd.Applicant__c=applicantId;
                     dd.Process_Name__c ='Income ITR';
                     dd.Year__c = (string) uploadParam.get('year');
                    dd.Manual_AA__c=(string) uploadParam.get('manualAA');
                    dd.Loan_Application__c=(string)uploadParam.get('loanid');
                }
                when 'GST Return'{
                    sQuery += ' AND Name = :docName AND Requirement_At__c = \'Applicant Level\' AND Document_Category__c =: docCategory LIMIT 1';
                     dd.Applicant__c=applicantId;
                     dd.Process_Name__c ='Income GST';
                      dd.Year__c = (string) uploadParam.get('year');
                    dd.Manual_AA__c=(string) uploadParam.get('manualAA');
                    dd.Loan_Application__c=(string)uploadParam.get('loanid');
                }
                
                
            }
            //system.debug('sQuery##'+sQuery);
            Document_Master__c dm = Database.query(sQuery);
            //system.debug('dm: '+dm);

            if(dm != null){
                dd.Name =docName;
                dd.Document_Master__c = dm.Id;
                dd.Description__c = 'Document created and uploaded manually';
                dd.Is_Required__c = dm.Is_Required__c;
                
                insert dd;
                //system.debug('dd: '+dd);
                
                docDetailId = dd.Id;
                
            }
         //return docDetailId;
         //

        }
        catch (Exception e) {
            //System.debug('Exception in checkPanAndBureau: ' + e.getMessage());
            docDetailId = 'Error';
        }
        return docDetailId;    
       
    }
      @AuraEnabled
    public static void insertFileRecord(String fileContentDocumentId, String recordId) {
        try {
            // Create a ContentDocumentLink to associate the file with the record
            ContentDocumentLink docLink = new ContentDocumentLink();
            docLink.ContentDocumentId = fileContentDocumentId;
            docLink.LinkedEntityId = recordId; // Associate with the record
            docLink.ShareType = 'V'; // View permission
            docLink.Visibility = 'AllUsers'; // Set visibility to all users (adjust as necessary)
            insert docLink;
            Document_Details__c doc = new Document_Details__c();
            doc.Id = recordId;
            doc.Content_Document_Id__c = fileContentDocumentId;
            doc.Status__c = 'Uploaded';
            Update doc;
            //Set<Id> shareWithUserId = new Set<Id>();
            //List<Document_Details__c> docList = [SELECT Id,Name from Document_Details__c where id =: doc.Id];
            // if(docList.size()>0){
            //     result.put('docName',docList[0].Name);
            // }
            // Create sharing records for the document
            /*if(!shareWithUserId.isEmpty()) {

                List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
                for(Id i : shareWithUserId) {
                    Utility.SharingInfo si = new Utility.SharingInfo();
                    si.objectName = 'Document_Details__c';
                    si.userOrGroupId = i;
                    si.recordToShareId = docList[0].id;
                    si.sharingAccess = 'Edit';
                    sharingList.add(si);
                }

                //System.debug('sharingList: '+sharingList);
                Utility.createShareRecord(JSON.serialize(sharingList));
            }*/
        } catch (Exception e) {
            throw new AuraHandledException('Error associating file with record: ' + e.getMessage());
        }
    }

     @AuraEnabled
    public static boolean deleteContentDoctId(String docId, String cdLId){
        Boolean flag = false;
        List<ContentDocumentLink> contLinkList = new List<ContentDocumentLink>();
        contLinkList = [SELECT Id ,ContentDocumentId from ContentDocumentLink where Id =: cdLId];
        if(contLinkList.size()>0){
            Delete [SELECT Id FROM ContentDocument WHERE Id =:contLinkList[0].ContentDocumentId]; 
            flag=true;
            List<ContentDocumentLink> currentContLinkList = new List<ContentDocumentLink>();
            currentContLinkList = [SELECT Id ,ContentDocumentId from ContentDocumentLink where LinkedEntityId =:docId]; 
            if(currentContLinkList.size()==0){
                 Delete [SELECT Id FROM Document_Details__c WHERE Id =:docId]; 
                 flag=true;
            }     
            else{
                Document_Details__c doc = new Document_Details__c();
                doc.Id = docId;
                doc.Content_Document_Id__c = currentContLinkList[0].ContentDocumentId;
                Update doc;
                flag=true;
            }    
        }

        return flag;
    }
    


     public class ApplicantDetailsWrapper{
        @AuraEnabled public String applicantId;
        @AuraEnabled public String applicantName;
        @AuraEnabled public String applicantType;
        @AuraEnabled public Boolean isKeyApplicant;
        @AuraEnabled public String maskedMobileNumber;
        @AuraEnabled public Boolean iscibilLow;
        @AuraEnabled public Boolean disableApplicantType;
        @AuraEnabled public Boolean consentStatus;
    }  
     @AuraEnabled
    public static string fetchLoanApplicationForm(String recordId){
        try {
            Document_Details__c doc = [ SELECT Content_Document_Id__c 
                                        FROM Document_Details__c 
                                        WHERE Loan_Application__c = :recordId 
                                        AND Name = 'Loan Application Form'
                                        AND Active__c = true 
                                        LIMIT 1
                                        ];
            ContentVersion version = [SELECT Id 
                                      FROM ContentVersion 
                                      WHERE ContentDocumentId = :doc.Content_Document_Id__c 
                                      ORDER BY CreatedDate DESC 
                                      LIMIT 1
                                      ];
            return version.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    } 

    @AuraEnabled
    public static List<string> getErrorMessage(String recordId){
        try {
            List<String> result = new List<String>();
            List<Integration_Details__c> intDet = [SELECT Id, Name, Loan_Application__c,Response_JSON__c from Integration_Details__c where Name Like 'BSACallBack %' and Loan_Application__c =:recordId Order by CreatedDate DESC LIMIT 1];
            if(intDet.size()>0){
                String name = intDet[0].Name;
                if(name =='BSACallBack -1'){
                    String requestBody = intDet[0].Response_JSON__c;
                     BSAResponseWrapper callbackResp = (BSAResponseWrapper) JSON.deserialize(requestBody, BSAResponseWrapper.class);
                    for(ClsFiles cs:callbackResp.data.files ){
                        for(ClsDetails cd : cs.Message.error.details){
                            result.add(cs.filename + '-' + cd.message);
                        }
                    }
                }
                else if(name =='BSACallBack -2'){
                     String requestBody = intDet[0].Response_JSON__c;
                      COMM_BSAResponseService respWrap = (COMM_BSAResponseService)JSON.deserialize(requestBody, COMM_BSAResponseService.class);
                      result.add(respWrap.data.errorMessage);

                }
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<String> getSectorFieldValues( String loanId, String applicantId){
        List<String> sectorValues= new List<String>();
        try {
            List<Application_Applicant__c> applicantList= [SELECT Id, Applicant_Type__c, Sector__c FROM Application_Applicant__c WHERE  Id = :applicantId ORDER BY CreatedDate ASC];
             SObjectType picklistObjectType = ((SObject) Type.forName('Application_Applicant__c').newInstance()).getSObjectType();
            DescribeSObjectResult picklistObject = picklistObjectType.getDescribe();
            Schema.DescribeFieldResult picklistField = picklistObject.fields.getMap().get('Sector__c').getDescribe();
            List<Schema.PicklistEntry> entries = picklistField.getPicklistValues();
            
            List<String> values = new List<String>();
            for (Schema.PicklistEntry entry : entries) {
                values.add(entry.getValue());
            }
            for(Application_Applicant__c applicant: applicantList){
                if(applicant.Applicant_Type__c == 'Primary Applicant'){
                    for (String val : values) {
                        if (val != 'Others') {
                            sectorValues.add(val);
                        }
                    }
                }else {
                    for (String val : values) {
                        sectorValues.add(val);
                    }
                }
            }
        } catch (Exception e) {
             throw new AuraHandledException(e.getMessage());
            //System.debug('Exception----'+e.getMessage());
        }

        return sectorValues;
    }

    @AuraEnabled
    public static String updateLoanApplicationStage(String loanId){
        String status;
        List<Charges_Insurance__c> chargesToDelete = new List<Charges_Insurance__c>();
        List<Loan_Transaction__c> loanTransactionsToDelete = new List<Loan_Transaction__c>();
        try {
            Opportunity oppObj =  [SELECT Id, StageName FROM Opportunity WHERE Id =:loanId];
            if(oppObj.StageName != 'Sales login'){
                oppObj.StageName = 'Sales login';
                oppObj.Sub_stage__c = 'Login in-progress';
                update oppObj;
            }

            // Handle rollback from PSV → Sales login
            // chargesToDelete = [SELECT Id FROM Charges_Insurance__c WHERE Loan_Application__c = :loanId AND Charges_Fee_Type__c != 'Login Fee'];
            // loanTransactionsToDelete = [SELECT Id FROM Loan_Transaction__c WHERE Loan_Application__c = :loanId];
            // if (!chargesToDelete.isEmpty()) delete chargesToDelete;
            // if (!loanTransactionsToDelete.isEmpty()) delete loanTransactionsToDelete;
           
            status = 'Success';
        } catch (Exception e) {
            status = 'Error';
            //system.debug('Sales_LoanLoginController->updateLoanApplicationStage----'+e.getMessage()+'--'+e.getLineNumber()+'----'+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }

        return status;
    }

    public class BSAResponseWrapper{
        public boolean status;
        public ClsData data;
        public String message;//Transaction Cancel
        public String statusCode;	//bsa-200
        public String traceId;//98dc312d-1bdd-4cbb-90db-d4f6acc8fa55
        public String perfiosTransactionId;	//399Y1749128684898
    }
        public class ClsData {
            public String perfiosTransactionId;//399Y1749128684898
            public ClsFiles[] files;
            public String cancelTransactionResult;//successfully cancel treansaction
        }
        public class ClsFiles {
            public String filename;	//bank 1.pdf
            public String fileID;//f82dcc351a18b4abae5c6b57309e0a469ba9d3b5
            public String statusCode;	//bsa-400
            public ClsMessage message;
        }
        public class ClsMessage {
            public ClsError error{get;set;}
        }
        public class ClsError {
            public String code;//CannotProcessFile
            public String message;//We could not process the statement file uploaded by the Client
            public ClsDetails[] details;
        }
        public class ClsDetails {
            public String code;	//E_STATEMENT_WRONG_INSTITUTION
            public ClsField field;
            public String message;//Uploaded statement does not seem to be from the selected institution
            public ClsValue value;
        }
        public class ClsField {
        }
        public class ClsValue {
        }

    @AuraEnabled
    public static void byPassStageForWhitelisting (String loanId){
        List<Opportunity> opp =[Select id,Login_Completion_Stage__c from Opportunity where id=:loanId];
        if(opp[0].Login_Completion_Stage__c == null) {
    opp[0].Login_Completion_Stage__c = '';
}
        if(!opp[0].Login_Completion_Stage__c.containsIgnoreCase('Income Eligibility')){
            opp[0].Login_Completion_Stage__c =  opp[0].Login_Completion_Stage__c + ';'+ 'Income Eligibility';
        }
        update opp;
    }

@AuraEnabled(cacheable=false)
    public static List<Applicant_Address__c> getOrCreateAddressRecords(Id docDetailId,Id applicantId) {
        Document_Details__c dd = [
        SELECT Document_Master__r.Name,Document_Master__r.Address_Type__c,Document_Master__r.Document_Type__c, Content_Document_Id__c FROM Document_Details__c
        WHERE Id = :docDetailId
        LIMIT 1
        ];
        String masterName    = dd.Document_Master__r.Name;
        Map<String,String> mapSource = new Map<String,String>{
        'Aadhaar Back'  => 'Aadhaar',
        'Passport Back' => 'Passport',
        'Voter Back'    => 'Voter Id',
        'DL' => 'Driving License',
        'Certificate of license issued by professional body' => 'Manual',
        'Registered Rent Agreement' =>'Registered Rent',
        'GST Certificate' => 'Manual',
        'Bank Statement' => 'Manual',
        'Certificate of Incorporation' => 'Manual',
        'Notarized rent agreement with utility bill' => 'Notarized Rent',
        'Utility Bill not more than 2 months old' =>'Utility Bill',
        'Letter head' =>'Manual',
        'Prescription Letter' => 'Manual',
        'Firm Card' => 'Manual',
        'Certificate of Practice'=>'Manual',
        'Registration Certificate'=>'Manual'
        };
        String addressSource = mapSource.get(masterName);
        String docType = dd.Document_Master__r.Document_Type__c;
        Boolean isPOA = (docType != null && docType.equalsIgnoreCase('POA'));
        Boolean isProofOfOffice = (docType != null && (docType.equalsIgnoreCase('Proof of office') ));

        List<Applicant_Address__c> existing = [
        SELECT Id,
                Address_Type__c,
                Address_Source__c
            FROM Applicant_Address__c
        WHERE Document_Details__c = :docDetailId
            AND Applicant__c        = :applicantId
        ];
        Boolean isUploaded = (dd.Content_Document_Id__c != null);
        Map<String,String> inputMapUtility = new  Map<String,String>();
        Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
        Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
        if(isHlRelated && masterName== 'Aadhaar Back'){
            List<Applicant_Address__c> existingAddress = [
            SELECT Id,
                    Address_Type__c,
                    Address_Source__c,
                    Document_Details__c
                FROM Applicant_Address__c WHERE Applicant__c =:applicantId
                AND Document_Details__c= null AND Address_Source__c = 'Aadhaar'];
            if(existingAddress.size()>0){
                existingAddress[0].Document_Details__c = docDetailId;
                update existingAddress;
                existing = new List<Applicant_Address__c>{ existingAddress[0] };
            }
        }
        if (existing.isEmpty()&& addressSource != null && isUploaded && (isPOA || isProofOfOffice)) {
            Applicant_Address__c blank = new Applicant_Address__c(
                Applicant__c        = applicantId,
                Document_Details__c = docDetailId,
                Address_Source__c   = addressSource
            );
            insert blank;
            existing = new List<Applicant_Address__c>{ blank };
        }
        return existing;
    }
        public class SplitResult {
            @AuraEnabled public Id permanentAddressId;
            @AuraEnabled public Id currentAddressId;
        }

        @AuraEnabled
        public static SplitResult splitAddressType(Id addressId, Id applicantId, Id docId, List<String> selected) {
            if (addressId == null || applicantId == null || docId == null) {
                throw new AuraHandledException('Missing required ids');
            }
            Set<String> sel = new Set<String>();
            if (selected != null) {
                for (String s : selected) if (String.isNotBlank(s)) sel.add(s.trim());
            }
            if (!(sel.contains('Permanent') && sel.contains('Current'))) {
                throw new AuraHandledException('splitAddressType should be called only when both values are selected.');
            }

            Applicant_Address__c base = [
                SELECT Id, Applicant__c, Document_Details__c, Address_Type__c,
                    Address_Line_1__c, Address_Line_2__c, Address_Line_3__c,
                    Pincode__c, City__c, State__c,
                    Address_Ownership__c, Landmark__c, Address_Source__c
                FROM Applicant_Address__c
                WHERE Id = :addressId
                LIMIT 1
            ];

            Map<String, Applicant_Address__c> existingByType = new Map<String, Applicant_Address__c>();
            for (Applicant_Address__c a : [
                SELECT Id, Address_Type__c
                FROM Applicant_Address__c
                WHERE Applicant__c = :applicantId
                AND Document_Details__c = :docId
                AND Address_Type__c IN ('Permanent','Current')
            ]) {
                existingByType.put(a.Address_Type__c, a);
            }

            base.Address_Type__c = 'Permanent';
            update base;

            Applicant_Address__c currentAddr;
            if (existingByType.containsKey('Current') && existingByType.get('Current').Id != base.Id) {
                currentAddr = existingByType.get('Current');
                currentAddr.Address_Line_1__c = base.Address_Line_1__c;
                currentAddr.Address_Line_2__c = base.Address_Line_2__c;
                currentAddr.Address_Line_3__c = base.Address_Line_3__c;
                currentAddr.Pincode__c       = base.Pincode__c;
                currentAddr.Address_Source__c= base.Address_Source__c;
                currentAddr.Address_Ownership__c     = base.Address_Ownership__c;
                currentAddr.Landmark__c      = base.Landmark__c;
                update currentAddr;
            } else {
                currentAddr = base.clone(false, false, false, false);
                currentAddr.Address_Type__c = 'Current';
                insert currentAddr;
            }

            SplitResult r = new SplitResult();
            r.permanentAddressId = base.Id;
            r.currentAddressId   = currentAddr.Id; 
            return r;
    }

    @AuraEnabled
    public static Id shrinkAddressTypes(Id addressId, Id applicantId, Id docId, List<String> selected) {
        if (addressId == null || applicantId == null || docId == null)
            throw new AuraHandledException('Missing required ids');
        if (selected == null || selected.size() != 1)
            throw new AuraHandledException('Provide exactly one remaining selected value.');

        String keepType = selected[0]?.trim();
        if (String.isBlank(keepType))
            throw new AuraHandledException('Invalid remaining selection.');
        String otherType;
        if (keepType == 'Permanent')                 otherType = 'Current';
        else if (keepType == 'Current')              otherType = 'Permanent';
        else if (keepType == 'Registered Office')    otherType = 'Business Operational';
        else if (keepType == 'Business Operational') otherType = 'Registered Office';
        else throw new AuraHandledException('Unsupported address type: ' + keepType);

        List<Applicant_Address__c> rows = [
            SELECT Id, Address_Type__c
            FROM Applicant_Address__c
            WHERE Applicant__c = :applicantId
            AND Document_Details__c = :docId
            AND Address_Type__c IN :new Set<String>{ keepType, otherType }
        ];

        Applicant_Address__c keepRec, removeRec;
        for (Applicant_Address__c a : rows) {
            if (a.Address_Type__c == keepType) keepRec = a; else removeRec = a;
        }
        if (keepRec == null) {
            Applicant_Address__c base = [SELECT Id, Address_Type__c FROM Applicant_Address__c WHERE Id = :addressId LIMIT 1];
            base.Address_Type__c = keepType;
            update base;
            keepRec = base;
        }

        if (removeRec != null) {
            delete removeRec;
        }
        return keepRec.Id;
    }
    //HL-Ishi-1/10
      @AuraEnabled
        public static void callUCICAPI(String loanId, String applicantId){
            List<Application_Applicant__c> appDet =[Select id, Customer__r.UCIC_Number__c,DOB__c,DOI__c,Customer_Type__c,Loan_Application__c,PAN_Number__c from Application_Applicant__c where Customer__r.UCIC_Number__c=null and id =:applicantId LIMIT 1];
            if(appDet.size()>0 && applicantId!=null){
                for (Application_Applicant__c applicant : appDet) {
                    Map<String, String> inputMap = new Map<String, String>();
                    inputMap.put('recordId', applicant.Loan_Application__c);
                    inputMap.put('applicantId', applicant.Id);
                    inputMap.put('processName', 'UCIC Search AND Create');
                    inputMap.put('panNum', applicant.PAN_Number__c);
                    // Use DOB for Individual, otherwise use DOI
                    Date identityDate;
                    if (applicant.Customer_Type__c != null && applicant.Customer_Type__c.equalsIgnoreCase('Individual')) {
                        identityDate = applicant.DOB__c;
                    } else {
                        identityDate = applicant.DOI__c;
                    }
                    if (identityDate != null) {
                        inputMap.put('dob', String.valueOf(identityDate));
                        UCICCreateAndSearchCustomerController.initiateAPIRequest(inputMap);
                    } else {
                        System.debug('Skipping due to missing DOB/DOI: ' + applicant.Id);
                    }
                }
        }
    }
       /*@AuraEnabled
    public static Boolean checkExistingAddressWithDocument(Id applicantId, String addressField,String formIdentifier,String docId) {
        system.debug(formIdentifier);
        system.debug(docId);
        List<String> strList = new List<String>();
        //Set<Id> Ids = new Set<Id>();
        Document_Details__c doc = [SELECT Id,Document_Details__c FROM Document_Details__c WHERE ID =: docId];
        system.debug(doc);
        List<Applicant_Address__c> existing = [SELECT Id,Address_Type__c FROM Applicant_Address__c WHERE Applicant__c = :applicantId AND Document_Details__r.Document_Master__r.Name =: formIdentifier AND Document_Details__c =: docId AND Document_Details__c != null];
        for(Applicant_Address__c add : existing){
            strList.add(add.Address_Type__c);
            Ids.add(add.Id);
}
        //String query = 'SELECT Id, Flag_Current_Registred_as_Very_High__c, Flag_PO_as_High__c,Address_Type__c,Document_Details__r.Document_Type__c FROM Applicant_Address__c WHERE Applicant__c =: applicantId AND Address_Type__c In: strList AND Document_Details__r.Document_Type__c =: docMaster.Document_Type__c AND' + String.escapeSingleQuotes(addressField) + ' = true LIMIT 1';
		String query = 'SELECT Id, Flag_Current_Registred_as_Very_High__c, Flag_PO_as_High__c,Address_Type__c,Document_Details__r.Document_Details__c FROM Applicant_Address__c WHERE Applicant__c =: applicantId AND Document_Details__r.Document_Details__c = \'' + doc.Document_Details__c + '\' AND ' + String.escapeSingleQuotes(addressField) + ' = true LIMIT 1';        system.debug(query);
        List<SObject> existingAddresses = Database.query(query);
        system.debug(existingAddresses);
        return !existingAddresses.isEmpty();
    }*/
    //HL-Ishi-1/10
    @AuraEnabled
public static String validateNSDLPan(String recordId) {
    String returnVal = 'OK'; // default if nothing is invalid
    // Query related applicants; add LIMIT if appropriate
    List<Application_Applicant__c> appList = [
        SELECT Id, Pan_Status__c,seeding_status__c 
        FROM Application_Applicant__c
        WHERE Loan_Application__c = :recordId
    ];
    
    for (Application_Applicant__c app : appList) {
        // Use null-safe checks and reference fields via the variable
        if ((app.Pan_Status__c == 'Invalid')) {
            return 'PanStatusInvalid';
        }
    }
    
    // If no invalid found
    return returnVal;
}
    @AuraEnabled
    public static void clonePrimaryAddress(Id coApplicantId, Id docDetailId, String documentName, String category) {
        Id loanAppId = [SELECT Loan_Application__c FROM Application_Applicant__c WHERE Id = :coApplicantId LIMIT 1].Loan_Application__c;
        Application_Applicant__c primaryApp = [SELECT Id FROM Application_Applicant__c WHERE Applicant_Type__c = 'Primary Applicant' AND Loan_Application__c = :loanAppId LIMIT 1];
        List<Applicant_Address__c> primaryList = [
            SELECT Id, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c,
                City__c, State__c, Pincode__c, Address_Type__c,Address_Ownership__c,Address_Source__c
            FROM Applicant_Address__c
            WHERE Applicant__c = :primaryApp.Id
            AND Document_Details__r.Name = :documentName
            AND Document_Details__r.Document_Master__r.Document_Category__c = :category
            AND Address_Source__c !='Manual'
            LIMIT 1
        ];
        if (primaryList.isEmpty()) {
            throw new AuraHandledException('Primary applicant address not found');
        }
        Applicant_Address__c primaryAddress = primaryList[0];

        //Get existing Co-applicant address (already created)
        Applicant_Address__c coAddress = [SELECT Id FROM Applicant_Address__c WHERE Document_Details__c = :docDetailId LIMIT 1];

        Applicant_Address__c cloneAddress = primaryAddress.clone(false);
        cloneAddress.Id = coAddress.Id;
        cloneAddress.Applicant__c = coApplicantId;
        cloneAddress.Document_Details__c = docDetailId;
        cloneAddress.Same_As_Primary_Applicant__c = true;
        update cloneAddress;
    }
    @AuraEnabled
    public static void clearCoApplicantAddress(Id docDetailId) {
        Applicant_Address__c coAddress = [SELECT Id, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, City__c, State__c, Pincode__c, Address_Type__c, Same_As_Primary_Applicant__c FROM Applicant_Address__c
            WHERE Document_Details__c = :docDetailId LIMIT 1];
        coAddress.Address_Line_1__c = null;
        coAddress.Address_Line_2__c = null;
        coAddress.Address_Line_3__c = null;
        coAddress.Pincode__c = null;
        coAddress.Address_Type__c = null;
        coAddress.Address_Source__c =null;
        coAddress.Same_As_Primary_Applicant__c = false;
        coAddress.Address_Ownership__c =null;
        update coAddress;
    }
}