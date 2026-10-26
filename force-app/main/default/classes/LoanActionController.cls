/*
* Author    :   Deloitte India
* Purpose   :   Generic controller class to read write data from ScreenFields__c
* @last modified on  : 2024-11-14
* @last modified by  : Soumya Choudhury (souchoudhury@deloitte.com)
*/

public with sharing class LoanActionController {
    @AuraEnabled
    public static Application_Applicant__c getApplicantData(String loanId, String applicantId){
        Application_Applicant__c appData = new Application_Applicant__c();
        try{
            if(applicantId != null){
                appData = [SELECT Id, Relationship_with_Primary_Applicant__c, Customer_Type__c, Residency_Status__c, Employment_Type__c, Sub_Employment_Type__c, Sub_Employment_Type_Non_Individual__c, Financial_Non_Financial__c FROM Application_Applicant__c WHERE Id =: applicantId LIMIT 1];
            }else{
                appData = [SELECT Id, Relationship_with_Primary_Applicant__c, Customer_Type__c, Residency_Status__c, Employment_Type__c, Sub_Employment_Type__c, Sub_Employment_Type_Non_Individual__c, Financial_Non_Financial__c FROM Application_Applicant__c WHERE Loan_Application__c =: loanId AND Applicant_Type__c = 'Primary Applicant' LIMIT 1];
            }
        }catch(Exception exp){
            //Utility.generateException(exp, Constants.LOAN_APPLICATIONS_OBJECT, 'LoanActionController');
            system.debug('exp:: '+exp);
        }
        return appData;
    }

    @AuraEnabled
    public static List<actionListWrapper> getActionList(String loanId){
        List<actionListWrapper> actionList = new List<actionListWrapper>();
        statusWrapper stwrap = getCompletionStatus(loanId);

        Boolean b = false;
        Integer i =1;
        List<Opportunity> loanList = [Select Id, Login_Completion_Stage__c from Opportunity where id=: loanId];
        List<Application_Applicant__c> apDetList = [Select Id, Customer_Type__c, Employment_Type__c from Application_Applicant__c where Loan_Application__c =: loanId and Applicant_Type__c = 'Primary Applicant'];
        List<Screen_Field__c> screenDetails = new List<Screen_Field__c>();
        if(apDetList.size()>0 && apDetList[0].Customer_Type__c != null){
            String custAndEmpType = apDetList[0].Customer_Type__c+'-'+apDetList[0].Employment_Type__c;
            screenDetails = [Select Id, Screen_Name__c, Applicable_Login_Stage__c from Screen_Field__c where Form_Name__c = 'Loan Application Login Form' and Is_Screen_Active__c = true and Screen_Name__c != null and Parent_Screen__r.Is_Screen_Active__c = true and (Applicable_For__c = 'Both' or Applicable_For__c = 'Individual-Both' or Applicable_For__c = 'Non Individual-Both' or  Applicable_For__c =: custAndEmpType) order by Screen_Sequence__c ASC];
        }
        else{
            screenDetails = [Select Id, Screen_Name__c, Applicable_Login_Stage__c from Screen_Field__c where Form_Name__c = 'Loan Application Login Form' and Is_Screen_Active__c = true and Screen_Name__c != null and Parent_Screen__r.Is_Screen_Active__c = true order by Screen_Sequence__c ASC];
        }
        Set<String> screenNames = new Set<String>();
        Set<String> currentStageScreens = new Set<String>();
        for(Screen_Field__c sc : screenDetails){
            if(loanList.size()>0){
                if(sc.Applicable_Login_Stage__c != null && (loanList[0].Login_Completion_Stage__c.contains(sc.Applicable_Login_Stage__c) || sc.Applicable_Login_Stage__c=='Basic Info Capture Stage')){
                    if(loanList[0].Login_Completion_Stage__c.contains(sc.Applicable_Login_Stage__c)){
                        currentStageScreens.add(sc.Screen_Name__c);
                    }
                    screenNames.add(sc.Screen_Name__c);
                }
            }
            else{
                if(sc.Applicable_Login_Stage__c != null){
                    if(sc.Applicable_Login_Stage__c == 'Aadhar Capture Stage'){
                        currentStageScreens.add(sc.Screen_Name__c);
                    }
                    screenNames.add(sc.Screen_Name__c);
                }
            }
        }

        Integer totalWeighttage=0;
        Integer totalCompletedAction = 0;
        for(String loAct : screenNames){
            actionListWrapper act = new actionListWrapper();
            act.completed = false;
            act.Name = loAct;
            i++;
            if(loAct == 'Co-Applicant Details' && stwrap.coApplicantAdded){ // && stwrap.coApplicantAdded
                act.completed = true;
                totalCompletedAction++;
            }
            else if(loAct == 'Switch Applicant / Co-Applicant'){
                act.completed = true;
                totalCompletedAction++;
            }
            else if(loAct == 'Bank Account Information' && stwrap.bankAdded){
                act.completed = true;
                totalCompletedAction++;
            }
            else if(loAct == 'Asset Information' && stwrap.assetAdded){
                act.completed = true;
                totalCompletedAction++;
            }
            else if(loAct == 'Confirm Applicant\'s Basic Details' && stwrap.basicInfo){
                act.completed = true;
                totalCompletedAction++;
            }
            else if(loAct == 'Add Employment Details' && stwrap.empDetails){
                act.completed = true;
                totalCompletedAction++;
            }
            else if(loAct == 'Loan Requirement' && stwrap.loanInfo){
                act.completed = true;
                totalCompletedAction++;
            }
            else if(loAct == 'Product Info' && stwrap.productinfs){
                act.completed = true;
                totalCompletedAction++;
            }
            else if(loAct == 'Get Customer Consent' && stwrap.gcconsent){
                act.completed = true;
                totalCompletedAction++;
            }
            else if(loAct == 'Collect Applicant\'s Consent' && stwrap.gcconsent){
                act.completed = true;
                totalCompletedAction++;
            }
            else if(loAct == 'Reference Details'  && stwrap.referenceAdded){
                act.completed = true;
                totalCompletedAction++;
            }
            else if(loAct == 'Address Information' && stwrap.adressinfo){ //   && stwrap.adressinfo
                act.completed = true;
                totalCompletedAction++;
            }
            else if(loAct == 'Add Business Address' && stwrap.adressbusinessinfo){ 
                act.completed = true;
                totalCompletedAction++;
            }
            else if(loAct == 'Capture Applicant\'s Photo' && stwrap.applicantphoto){ 
                act.completed = true;
                totalCompletedAction++;
            }
            else if(loAct == 'Additional Information'  && stwrap.additionalInfoAdded){
                act.completed = true;
                totalCompletedAction++;
            }
            else if(loAct == 'FTR Documents'){ //   && stwrap.ftrDocUploaded
                act.completed = true;
                totalCompletedAction++;
            }
            else if(loAct == 'Account Aggregator'){ //  && stwrap.isAccAggCompleted
                act.completed = true;
            }
            else if(loAct == 'Validate PAN' && stwrap.isPanValidated){
                act.completed = true;
            }
            else if(loAct == 'Enter Aadhar Details' && stwrap.isAadharValidated){
                act.completed = true;
            }
            else if(loAct == 'Enter OVD Details' && (stwrap.isVoterValidated || stwrap.isPassportValidated || stwrap.isDLValidated || stwrap.isAadharValidated)){
                act.completed = true;
            }
            else if(loAct == 'Eligibility Screen' && stwrap.isEligibleForLogin){
                act.completed = true;
            }
            else if(loAct == 'Login'){
                totalCompletedAction++;
            }
            else if(loAct == 'Business Details' && stwrap.isBusinessDetailsCompleted){
                totalCompletedAction++;
                act.completed = true;
            }
            else if(loAct == 'Basic Details' && stwrap.iscustomerTypeAdded){
                act.completed = true;
                totalCompletedAction++;
            }
            else if(loAct == 'Perfios Banking Integration' && stwrap.isPerfiosCompleted){
                act.completed = true;
                totalCompletedAction++;
            }

            actionList.add(act);
        }
        System.debug('totalCompletedAction=:'+totalCompletedAction);
        System.debug('actionList.size()=:'+actionList.size());
        System.debug('actionList=:'+actionList);
        if(actionList.size() > 0){
            if(totalCompletedAction>=screenNames.size() -4){
                actionList[0].isAllComplete = true;
            }
            else{
                actionList[0].isAllComplete = false;
            }
        }
        for(actionListWrapper actw : actionList){
            if(!currentStageScreens.contains(actw.Name)){
                actw.isDisabled = true;
            }
            else{
                actw.isDisabled = false;
            }
        }
        return actionList;
    }

    @AuraEnabled
    public static statusWrapper getCompletionStatus(String loanId){
        try {
            Boolean hasAadhaar = false;
            Boolean hasDL = false;
            Boolean hasPassport = false;
            Boolean hasVoterId = false;
            Boolean hasPan = false;
            
            statusWrapper stwrap = new statusWrapper();
            stwrap.coApplicantAdded = false;
            stwrap.iscustomerTypeAdded = false;
            stwrap.additionalInfoAdded = false;
            stwrap.referenceAdded = false;
            stwrap.ftrDocUploaded = false;
            stwrap.imdCollected = false;
            stwrap.bankAdded = false;
            stwrap.assetAdded = false;
            stwrap.empDetails = false;
            stwrap.productinfs = false; 
            stwrap.vappscore = false; 
            stwrap.gcconsent = false;
            stwrap.ovdDetails = false;
            stwrap.loanInfo = false;
            stwrap.adressinfo = false;
            stwrap.applicantphoto = false;
            stwrap.adressbusinessinfo = false;
            stwrap.basicInfo = false;
            stwrap.isOVDUpdated = false;
            stwrap.isPanValidated = false;
            stwrap.isAadharValidated = false;
            stwrap.isEligibleForLogin = false;
            stwrap.isVoterValidated = false;
            stwrap.isPassportValidated = false;
            stwrap.isDLValidated = false;
            stwrap.isPerfiosCompleted = false;
            stwrap.isBusinessDetailsCompleted = false;
            List<Id> custIds = new List<Id>();
            Integer consentSize=0;
            // List<Bank_Account__c> bankList = [Select id from Bank_Account__c where Loan_Application__c =: loanId];
            // List<Application_Collateral__c> apColList = [Select Id from Application_Collateral__c where Loan_Application__c =: loanId];
            // List<Address__c> addrList = [Select Id from Address__c where Loan_Application__c =: loanId];
            // if(addrList.size()>0){
            //     stwrap.adressinfo = true;
            // }
            List<Opportunity> loanList = [SELECT Id, Sub_Variant__c, Program__c, PSL__c
                                                    FROM Opportunity WHERE id =: loanId];

            List<Application_Applicant__c> apDetPrimary = [SELECT Id, First_Name__c, Middle_Name__c, Last_Name__c, Gender__c, Nationality__c, Citizenship__c, Customer_Type__c, Sub_Employment_Type__c,  
                                                            PAN_KYC_Verified__c,Aadhaar_KYC_Verified__c,Passport_Number__c,Voter_ID_Number__c,Drivers_License_Number__c,Is_Consent_Received__c,Employment_Type__c
                                                            FROM Application_Applicant__c WHERE Loan_Application__c =: loanId AND Applicant_Type__c = 'Primary Applicant' LIMIT 1];
            List<Application_Applicant__c> apDetCoapp = [SELECT Id, Customer_Type__c, PAN_KYC_Verified__c,Aadhaar_KYC_Verified__c,Passport_Number__c,Voter_ID_Number__c,Drivers_License_Number__c,Is_Consent_Received__c
                                                    FROM Application_Applicant__c where Loan_Application__c =: loanId AND Applicant_Type__c != 'Primary Applicant'];
            
            List<Integration_Details__c> intList = [Select Id from Integration_Details__c where Related_Record_Id__c =: loanId and Name = 'Loan Applicant Bank Statement Analysis'];
            if(intList.size()>0){
                stwrap.isPerfiosCompleted = true;
            }
            if(apDetPrimary.size()>0){
                List<Applicant_Address__c> applicantAddress = [SELECT Id, Is_Current_Address_Same_As_Permanent__c FROM Applicant_Address__c WHERE Applicant__c =: apDetPrimary[0].Id];
                if(applicantAddress.size()>0){
                    //stwrap.adressinfo = true;
                     if(applicantAddress[0].Is_Current_Address_Same_As_Permanent__c != null){
                         stwrap.adressinfo = true;
                     }
                }
                List<Applicant_Address__c> applicantBusinessAddress = [SELECT Id FROM Applicant_Address__c WHERE Applicant__c =: apDetPrimary[0].Id AND Address_Type__c != 'Permanent' AND Address_Type__c != 'Current'];

                if(applicantBusinessAddress.size()>0){
                    stwrap.adressbusinessinfo = true;
                }
                if(apDetPrimary[0].Customer_Type__c != null){
                    stwrap.iscustomerTypeAdded = true;
                }
                if(apDetPrimary[0].PAN_KYC_Verified__c){
                    stwrap.isPanValidated = true;
                }
                if(apDetPrimary[0].Aadhaar_KYC_Verified__c){
                     stwrap.isAadharValidated = true;
                }
                if(apDetPrimary[0].Passport_Number__c != null){
                    stwrap.isPassportValidated = true;
                }
                if(apDetPrimary[0].Voter_ID_Number__c != null){
                    stwrap.isVoterValidated = true;
                }
                if(apDetPrimary[0].Drivers_License_Number__c != null){
                    stwrap.isDLValidated = true;
                }
                if(apDetPrimary[0].Is_Consent_Received__c){
                    consentSize++;
                }
                List<Document_Details__c> docList = [SELECT Id FROM Document_Details__c WHERE Loan_Application__c =: loanId AND Name = 'Applicant Photo' AND Applicant__c =: apDetPrimary[0].Id];
                if(docList.size()>0){
                    stwrap.applicantphoto = true;
                }
                
                if(apDetPrimary[0].First_Name__c != null &&
                    apDetPrimary[0].Middle_Name__c != null &&
                    apDetPrimary[0].Last_Name__c != null &&
                    apDetPrimary[0].Nationality__c != null &&
                    apDetPrimary[0].Gender__c != null &&
                    apDetPrimary[0].Citizenship__c != null
                ){
                    stwrap.basicInfo = true;
                }
                // if(apDetPrimary[0].Father_s_Husband_s_Name__c != null &&
                //     apDetPrimary[0].Caste_Category__c != null &&
                //     apDetPrimary[0].Mother_s_Name__c != null &&
                //     apDetPrimary[0].Marital_Status__c != null &&
                //     apDetPrimary[0].Religion__c != null &&
                //     apDetPrimary[0].Residential_Status__c != null
                // ){
                //     stwrap.additionalInfoAdded = true;
                // }
                if(apDetPrimary[0].Citizenship__c != null &&
                    apDetPrimary[0].Employment_Type__c != null &&
                    apDetPrimary[0].Sub_Employment_Type__c != null
                ){
                    stwrap.empDetails = true;
                }
                // if(apDetPrimary[0].OTP_Consent_Received__c){
                //     consentSize++;
                // }
            }
            if(apDetCoapp.size()>0){
                stwrap.coApplicantAdded = true;
                for(Application_Applicant__c ap : apDetCoapp){
                    if(ap.PAN_KYC_Verified__c){
                        consentSize++;
                    }
                }
            }
            if(loanList.size()>0){
                if(loanList[0].Program__c != null && loanList[0].Sub_Variant__c != null){
                    stwrap.productinfs = true;
                }
                if(loanList[0].PSL__c != null){
                    stwrap.isBusinessDetailsCompleted = true;
                }
            }
            if(consentSize == apDetCoapp.size()+apDetPrimary.size() && consentSize != 0){
                stwrap.gcconsent = true;
            }
            // List<Screen_Field__c> screenList = [Select id, Storage_Object__c, Storage_Field__c, Screen_Name__c, Parent_Screen__r.Master_Screen_Name__c from Screen_Field__c where Form_Name__c ='Loan Application Login Form' and Parent_Screen__r.Is_Active__c = true and RecordType.Name = 'Screen Field' and Is_Mandatory__c = true];

            // if(consentSize == apDetCoapp.size()+apDetPrimary.size()){
            //     stwrap.gcconsent = true;
            // }
            // if(bankList.size()>0){
            //     stwrap.bankAdded = true;
            // }
            // if(apColList.size()>0){
            //     stwrap.assetAdded = true;
            // }

            // System.debug('stwrap.basicInfo -->'+stwrap.basicInfo);
            return stwrap;
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean checkIfAadharDetailsCaptured(String loanId){
        Boolean flag = false;
        statusWrapper stwrap = getCompletionStatus(loanId);
        System.debug('stwrap -->'+stwrap);
        
        if(stwrap.iscustomerTypeAdded && stwrap.isPanValidated){
            List<Opportunity> loanList = [SELECT Id, Login_Completion_Stage__c FROM Opportunity WHERE id =: loanId LIMIT 1];
            if(loanList.size()>0){      
                String currentValues = (String)loanList[0].get('Login_Completion_Stage__c');
                List<String> valuesList = new List<String>();
                if (currentValues != null) {
                    valuesList = currentValues.split(';');
                }
                if (!valuesList.contains('Basic Info Capture Stage')) {
                    valuesList.add('Basic Info Capture Stage');
                }
                String updatedValues = String.join(valuesList, ';');
                loanList[0].put('Login_Completion_Stage__c', updatedValues);
                
                Database.Update(loanList);

                flag = true;
            }
        }
        return flag;
    }








    @AuraEnabled
    public static Decimal percentCompletion(String loanId){
        try {
            List<actionListWrapper> actionList = new List<actionListWrapper>();
            statusWrapper stwrap = getCompletionStatus(loanId);
            Integer i =1;
            List<Screen_Field__c> screenDetails = [Select Id, Screen_Name__c from Screen_Field__c where Form_Name__c = 'Loan Application Login Form' and Is_Screen_Active__c = true and Screen_Name__c != null order by Screen_Sequence__c ASC];
            Set<String> screenNames = new Set<String>();
            for(Screen_Field__c sc : screenDetails){
                screenNames.add(sc.Screen_Name__c);
            }
            Decimal totalWeighttage=0;
            Decimal stepsCompleted = 0;
            for(String loAct : screenNames){
                if(loAct == 'Co-Applicant Details' && stwrap.coApplicantAdded){
                    stepsCompleted = stepsCompleted + 1;
                }
                // else if(loAct == 'Registration Fees Details' && stwrap.imdCollected){
                //     stepsCompleted = stepsCompleted + 1;
                // }
                // else if(loAct == 'Bank Account Information' && stwrap.bankAdded){
                //     stepsCompleted = stepsCompleted + 1;
                // }
                // else if(loAct == 'Asset Information' && stwrap.assetAdded){
                //     stepsCompleted = stepsCompleted + 1;
                // }
                // else if(loAct == 'Applicant\'s Basic Information' && stwrap.basicInfo){
                //     stepsCompleted = stepsCompleted + 1;
                // }
                // else if(loAct == 'Add Employment Details' && stwrap.empDetails){
                //     stepsCompleted = stepsCompleted + 1;
                // }
                // else if(loAct == 'Loan Requirement' && stwrap.loanInfo){
                //     stepsCompleted = stepsCompleted + 1;
                // }
                else if(loAct == 'Product Info' && stwrap.productinfs){
                    stepsCompleted = stepsCompleted + 1;
                }
                // else if(loAct == 'Get Customer Consent' && stwrap.gcconsent){
                //     stepsCompleted = stepsCompleted + 1;
                // }
                // else if(loAct == 'Reference Details'  &&stwrap.referenceAdded){
                //     stepsCompleted = stepsCompleted + 1;
                // }
                else if(loAct == 'Address Information'  &&stwrap.adressinfo){
                    stepsCompleted = stepsCompleted + 1;
                }
                else if(loAct == 'Add Business Address'  &&stwrap.adressbusinessinfo){
                    stepsCompleted = stepsCompleted + 1;
                }
                else if(loAct == 'Capture Applicant\'s Photo'  &&stwrap.applicantphoto){
                    stepsCompleted = stepsCompleted + 1;
                }
                // else if(loAct == 'Additional Information'  && stwrap.additionalInfoAdded){
                //     stepsCompleted = stepsCompleted + 1;
                // }
                // else if(loAct == 'FTR Documents'){ //   && stwrap.ftrDocUploaded
                //     stepsCompleted = stepsCompleted + 1;
                // }
                // else if(loAct == 'Account Aggregator'){ //  && stwrap.isAccAggCompleted
                //     stepsCompleted = stepsCompleted + 1;
                // }
                else if(loAct == 'Validate PAN' && stwrap.isPanValidated){
                    stepsCompleted = stepsCompleted + 1;
                }
                // else if(loAct == 'Enter Aadhar Details' && stwrap.isAadharValidated){
                //     stepsCompleted = stepsCompleted + 1;
                // }else if(loAct == 'Login'){
                //     stepsCompleted = stepsCompleted + 1;
                // }
                else if(loAct == 'Basic Details' && stwrap.iscustomerTypeAdded){
                    stepsCompleted = stepsCompleted + 1;
                }
            }

            System.debug('stepsCompleted=:'+stepsCompleted);
            Decimal percentCompletion = (stepsCompleted/screenNames.size())*100;
            System.debug('percentCompletion=:'+percentCompletion);
            return percentCompletion.setScale(0);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static void checkIfBasicScreenCompleted(String loanId){
        statusWrapper stwrap = getCompletionStatus(loanId);
        List<Screen_Field__c> screenDetails = [Select Id, Screen_Name__c from Screen_Field__c where Form_Name__c = 'Loan Application Login Form' and Is_Screen_Active__c = true and Screen_Name__c != null and Applicable_Login_Stage__c = 'Basic Info Capture Stage' order by Screen_Sequence__c ASC];
        Set<String> screenNames = new Set<String>();
        for(Screen_Field__c sc : screenDetails){
            screenNames.add(sc.Screen_Name__c);
        }
        Decimal stepsCompleted = 0;
        for(String loAct : screenNames){
            if(loAct == 'Co-Applicant Details' && stwrap.coApplicantAdded){
                stepsCompleted = stepsCompleted + 1;
            }
            else if(loAct == 'Registration Fees Details' && stwrap.imdCollected){
                stepsCompleted = stepsCompleted + 1;
            }
            else if(loAct == 'Applicant\'s Basic Information' && stwrap.basicInfo){
                stepsCompleted = stepsCompleted + 1;
            }
            else if(loAct == 'Add Employment Details' && stwrap.empDetails){
                stepsCompleted = stepsCompleted + 1;
            }
            else if(loAct == 'Loan Requirement' && stwrap.loanInfo){
                stepsCompleted = stepsCompleted + 1;
            }
            else if(loAct == 'Product Info' && stwrap.productinfs){
                stepsCompleted = stepsCompleted + 1;
            }
            else if(loAct == 'Address Information'  &&stwrap.adressinfo){
                stepsCompleted = stepsCompleted + 1;
            }
            else if(loAct == 'Additional Information'  && stwrap.additionalInfoAdded){
                stepsCompleted = stepsCompleted + 1;
            }
            else if(loAct == 'Capture Applicant\'s Photo'  && stwrap.applicantphoto){
                stepsCompleted = stepsCompleted + 1;
            }
        }
        if(stepsCompleted == screenNames.size()){
            List<Opportunity> loanList = [Select Id, Login_Completion_Stage__c from Opportunity where id =: loanId];
            if(loanList.size()>0){      
                String currentValues = (String)loanList[0].get('Login_Completion_Stage__c');
                List<String> valuesList = new List<String>();
                if (currentValues != null) {
                    valuesList = currentValues.split(';');
                }
                if (!valuesList.contains('Consent Stage')) {
                    valuesList.add('Consent Stage');
                }
                String updatedValues = String.join(valuesList, ';');
                loanList[0].put('Login_Completion_Stage__c', updatedValues);
                Update loanList[0];
            }
        }
    }

    

    public class statusWrapper{
        @AuraEnabled public Boolean iscustomerTypeAdded;
        @AuraEnabled public Boolean coApplicantAdded;
        @AuraEnabled public Boolean additionalInfoAdded;
        @AuraEnabled public Boolean referenceAdded;
        @AuraEnabled public Boolean ftrDocUploaded;
        @AuraEnabled public Boolean imdCollected;
        @AuraEnabled public Boolean bankAdded;
        @AuraEnabled public Boolean ovdDetails;
        @AuraEnabled public Boolean basicInfo;
        @AuraEnabled public Boolean assetAdded;
        @AuraEnabled public Boolean empDetails;
        @AuraEnabled public Boolean productinfs;
        @AuraEnabled public Boolean vappscore;
        @AuraEnabled public Boolean gcconsent;
        @AuraEnabled public Boolean loanInfo;
        @AuraEnabled public Boolean adressinfo;
        @AuraEnabled public Boolean applicantphoto;
        @AuraEnabled public Boolean adressbusinessinfo;
        @AuraEnabled public Boolean isOVDUpdated;
        @AuraEnabled public Boolean isPanValidated;
        @AuraEnabled public Boolean isAadharValidated;
        @AuraEnabled public Boolean isEligibleForLogin;
        //@AuraEnabled public Boolean isAadharValidated;
        @AuraEnabled public Boolean isVoterValidated;
        @AuraEnabled public Boolean isPassportValidated;
        @AuraEnabled public Boolean isDLValidated;
        @AuraEnabled public Boolean isPerfiosCompleted;
        @AuraEnabled public Boolean isBusinessDetailsCompleted;
    }

    public class actionListWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public Boolean completed;
        @AuraEnabled public Boolean isAllComplete;
        @AuraEnabled public Boolean isDisabled;
    }
    
    @AuraEnabled
    public static void changeLoanStage(String loanid){
        try {
            Opportunity loan = [SELECT Id FROM Opportunity WHERE Id = :loanid LIMIT 1];
            // Opportunity loan = new Opportunity();
            // loan.id = loanid;
            //loan.Stage__c = 'Application Processing';
            
            Update loan;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}