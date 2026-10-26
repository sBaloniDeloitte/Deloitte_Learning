public with sharing class ApplicantController {
    @AuraEnabled(cacheable=true)
    public static List<Application_Applicant__c> getApplicants(Id loanApplicantionId) {
        return [SELECT Id, Name, Father_s_First_Name__c, Mother_s_First_Name__c, Spouse_First_Name__c,
                       DOB__c, Mobile_Number__c, Customer_Type__c,Applicant_Type__c, Is_Financial_applicant__c,
                       Pan_Status__c, Aadhar_Status__c, Driving_License_Status__c,
                       Voter_ID_Status__c, Passport_Status__c,Customer_Profile__c,Business_Type__c
                FROM Application_Applicant__c
                WHERE Loan_Application__c = :loanApplicantionId];
    }
     @AuraEnabled(cacheable=true)
    public static List<Application_Applicant__c> getPrimaryApplicant(Id loanApplicantionId) {
        return [SELECT Id, Name, Father_s_First_Name__c, Mother_s_First_Name__c, Spouse_First_Name__c,
                       DOB__c, Mobile_Number__c, Customer_Type__c, Applicant_Type__c, Is_Financial_applicant__c, Business_Type__c,
                       Pan_Status__c, Aadhar_Status__c, Driving_License_Status__c,
                       Voter_ID_Status__c, Passport_Status__c,
                       Applicant_Name__c, GSTIN__c, Udhyam_Registration_No__c,
                       Nature_of_Business__c,Sector__c,MSME_Category__c
                FROM Application_Applicant__c
                WHERE Loan_Application__c = :loanApplicantionId 
                AND Applicant_Type__c ='Primary Applicant'];
    }
}