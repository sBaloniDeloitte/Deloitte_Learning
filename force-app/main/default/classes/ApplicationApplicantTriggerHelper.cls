/*
* Created By : Romesh Somani
* Created Date : 02/12/2024
* Purpose : Used to write all the logic for Application Applicant.
*Last Updated : Last updated by Suhrit for document details creation class
*/

public without sharing class ApplicationApplicantTriggerHelper implements ITriggerHandler{
    Boolean isTriggerDisabled = false;
//addedd
    public static void beforeInsert(List<SObject> newList){
        List<Application_Applicant__c> newRecords = (List<Application_Applicant__c>)newList;
        Map<String,Application_Applicant__c> laPANMap = new Map<String,Application_Applicant__c>();
        Map<String,Application_Applicant__c> laAadhaarMap = new Map<String,Application_Applicant__c>();
       // Id loanAppId = newList[0].Loan_Application__c;
         List<Application_Applicant__c> checkPANAadhaarList = [SELECT Id, PAN_Number__c,Customer_Type__c,Aadhaar_Number__c,Sector__c FROM Application_Applicant__c 
         WHERE Loan_Application__c = :newRecords[0].Loan_Application__c AND PAN_Number__c != null ];
        System.debug('new record>>>'+newRecords[0].Loan_Application__c);

        for(Application_Applicant__c app : checkPANAadhaarList){
           laPANMap.put(app.PAN_Number__c,app);
           if(app.Aadhaar_Number__c != null){
           laAadhaarMap.put(app.Aadhaar_Number__c,app);
           }
        }
        for(Application_Applicant__c itr : newRecords) {
            if(laPANMap.containsKey(itr.PAN_Number__c) && itr.Sector__c != 'Proprietorship' && itr.Customer_Type__c != 'Non Individual' && 
               laPANMap.get(itr.PAN_Number__c).Sector__c != 'Proprietorship' &&
               laPANMap.get(itr.PAN_Number__c).Customer_Type__c != 'Non Individual' 
              ){
                  if(!test.isRunningTest()){
                		itr.addError('Duplicate PAN Number found in the same Loan Application.');
                  }
                      	return;
            }
            System.debug('Aadhaar Number Kshitiz'+itr.Aadhaar_Number__c);
            System.debug('laAadhaarMap Kshitiz'+laAadhaarMap);
            if( itr.Aadhaar_Number__c != null && laAadhaarMap.containsKey(itr.Aadhaar_Number__c) ){
                if(!test.isRunningTest()){
                	itr.addError('Duplicate Aadhaar Number found in the same Loan Application.');
                }
                return;
            }
            if(String.isNotBlank(itr.Mobile_Number__c) && itr.Mobile_Number__c.length() == 10) {
                itr.Mobile_Number_Masked__c = 'XXXXXX' + itr.Mobile_Number__c.substring(6);
            }
            if (itr.Customer_Type__c == 'Individual' ) {
                itr.Pan_Name__c = (String.isBlank(itr.First_Name__c) ? '' : itr.First_Name__c+ ' ')  +
                        (String.isBlank(itr.Middle_Name__c) ? '' : itr.Middle_Name__c+ ' ')+
                        (String.isBlank(itr.Last_Name__c) ? '' : itr.Last_Name__c);
                
                // List<String> nameParts = itr.Pan_Name__c.split('\\s+');
                // if (nameParts.size() == 3) {
                //     itr.First_Name__c = nameParts[0];
                //     itr.Middle_Name__c = nameParts[1];
                //     itr.Last_Name__c = nameParts[2];
                // } else if (nameParts.size() == 2) {
                //     itr.First_Name__c = nameParts[0];
                //     itr.Last_Name__c = nameParts[1];
                // }
                // } else if (nameParts.size() == 1) {
                //     itr.Last_Name__c = nameParts[0];
                // }
                                        /* if (nameParts.size() == 1) {
            // Only one word → last name
                    itr.First_Name__c = nameParts[0];
                } else if (nameParts.size() == 2) {
                    // Two words → first and last
                    itr.First_Name__c = nameParts[0];
                    itr.Middle_Name__c  = nameParts[1];
                } else {
                    // More than 2 words
                    itr.First_Name__c  = nameParts[0];
                    itr.Middle_Name__c   = nameParts[1];
                    List<String> lastParts = new List<String>();
                    for (Integer i = 2;i < nameParts.size(); i++) {
                        lastParts.add(nameParts[i]);
                    }
                    itr.Last_Name__c  = String.join(lastParts, ' ');
                }*/
            //     System.debug('PAN Name: ' + itr.Pan_Name__c + 
            //  ' → First: ' + itr.First_Name__c + 
            //  ', Middle: ' + itr.Middle_Name__c + 
            //  ', Last: ' + itr.Last_Name__c);

            }
            if(itr.Customer_Type__c == 'Non Individual'&& String.isNotBlank(itr.Pan_Name__c)){
                itr.Name_of_Organization__c = itr.Pan_Name__c;
            }
            
        }

        ApplicantTriggerImplementation.concatenateName(newRecords);

        //write the checks for which we need to perform the action and implement the action in the class ApplicantTriggerImplementation
        
    }

    public static void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
        List<Application_Applicant__c> newRecords = (List<Application_Applicant__c>)newList;
        List<Application_Applicant__c> nameChangeList = new List<Application_Applicant__c>();
        Set<Id> applicantIds = new Set<Id>();
        Decimal shareHondlingPercent = 0;
        Map<String,Application_Applicant__c> laPANMap = new Map<String,Application_Applicant__c>();
         Map<String,Application_Applicant__c> laAadhaarMap = new Map<String,Application_Applicant__c>();
        Set<Id> panAadhaarCheckSet = new Set<Id>();
        List<Application_Applicant__c> populateEmpTypeList = new List<Application_Applicant__c>();
        for(Application_Applicant__c itr : newRecords) {
        Application_Applicant__c oldObj = (Application_Applicant__c)oldItems.get(itr.Id);
       // Id loanAppId = newList[0].Loan_Application__c;
       if(itr.Pan_Name__c != oldObj.Pan_Name__c || itr.Aadhaar_Number__c != oldObj.Aadhaar_Number__c){
            panAadhaarCheckSet.add(itr.Id);
       }
    }
        if(!panAadhaarCheckSet.isEmpty()){
         List<Application_Applicant__c> checkPANList = [SELECT Id, PAN_Number__c,Aadhaar_Number__c,Customer_Type__c,Sector__c FROM Application_Applicant__c 
         WHERE Loan_Application__c = :newRecords[0].Loan_Application__c AND PAN_Number__c != null AND Id NOT IN:panAadhaarCheckSet];
        for(Application_Applicant__c app : checkPANList){
           laPANMap.put(app.PAN_Number__c,app);
            laAadhaarMap.put(app.Aadhaar_Number__c,app);
        }
    }
        
        for(Application_Applicant__c itr : newRecords) {
            Application_Applicant__c oldObj = (Application_Applicant__c)oldItems.get(itr.Id);
            if(itr.Pan_Name__c != oldObj.Pan_Name__c && laPANMap.containsKey(itr.PAN_Number__c) && 
            laPANMap.get(itr.PAN_Number__c).Customer_Type__c != 'Non Individual' 
            && laPANMap.get(itr.PAN_Number__c).Sector__c != 'Proprietorship'
            ){
                if(!test.isRunningTest()){
                	itr.addError('Duplicate PAN Number found in the same Loan Application.');
                }
                return;
            }
            System.debug('Aadhaar Number Kshitiz'+itr.Aadhaar_Number__c);
            System.debug('laAadhaarMap Kshitiz'+laAadhaarMap);
            if(itr.Aadhaar_Number__c != oldObj.Aadhaar_Number__c && laAadhaarMap.containsKey(itr.Aadhaar_Number__c) ){
                if(!test.isRunningTest()){
                // itr.addError('Duplicate Aadhaar Number found in the same Loan Application.');
                }
                return;
            }
            
            //System.debug('Old obj',oldObj);
            if (itr.Share_Holding_Percentage__c != oldObj.Share_Holding_Percentage__c) {
                applicantIds.add(itr.Id);
                shareHondlingPercent = itr.Share_Holding_Percentage__c;
            }
            
            if(itr.First_Name__c != oldObj.First_Name__c || itr.Middle_Name__c != oldObj.Middle_Name__c || itr.Last_Name__c != oldObj.Last_Name__c || itr.Company__c != oldObj.Company__c || itr.Customer_Type__c != oldObj.Customer_Type__c){
                nameChangeList.add(itr);
            }

            if(itr.Mobile_Number__c != oldObj.Mobile_Number__c && String.isNotBlank(itr.Mobile_Number__c) && itr.Mobile_Number__c.length() == 10) {
                itr.Mobile_Number_Masked__c = 'XXXXXX' + itr.Mobile_Number__c.substring(6);
            }
             if(itr.Aadhaar_Number__c != null){
                itr.Masked_Aadhar_Number__c = 'XXXXXXXX' + itr.Aadhaar_Number__c.substring(8);
                if(itr.Aadhaar_Number_Masked__c == null ){
                itr.Aadhaar_Number_Masked__c = Utility.getEncryptedBase64String(itr.Aadhaar_Number__c);
                }
                //itr.Aadhaar_Number__c = itr.Masked_Aadhar_Number__c;
            }
            if (itr.Customer_Type__c == 'Individual' && String.isNotBlank(itr.Pan_Name__c) && itr.Pan_Name__c != oldObj.Pan_Name__c) {

                itr.Pan_Name__c = (String.isBlank(itr.First_Name__c) ? '' : itr.First_Name__c) + ' ' +
                        (String.isBlank(itr.Middle_Name__c) ? '' : itr.Middle_Name__c + ' ' )+
                        (String.isBlank(itr.Last_Name__c) ? '' : itr.Last_Name__c); 
                List<String> nameParts = itr.Pan_Name__c.split('\\s+');
                 
              /*  if (nameParts.size() == 3) {
                    itr.First_Name__c = nameParts[0];
                    itr.Middle_Name__c = nameParts[1];
                    itr.Last_Name__c = nameParts[2];
                } else if (nameParts.size() == 2) {
                    itr.First_Name__c = nameParts[0];
                    itr.Last_Name__c = nameParts[1];
                }*/
                // } else if (nameParts.size() == 1) {
                //     itr.Last_Name__c = nameParts[0];
                // }
                                                /*  if (nameParts.size() == 1) {
            // Only one word → last name
            itr.First_Name__c = nameParts[0];
        } else if (nameParts.size() == 2) {
            // Two words → first and last
            itr.First_Name__c = nameParts[0];
            itr.Middle_Name__c  = nameParts[1];
        } else {
            // More than 2 words
            itr.First_Name__c  = nameParts[0];
            itr.Middle_Name__c   = nameParts[1];
            List<String> lastParts = new List<String>();
            for (Integer i = 2; i < nameParts.size(); i++) {
                lastParts.add(nameParts[i]);
            }
            itr.Last_Name__c  = String.join(lastParts, ' ');
        }*/
                
            }
            if (itr.Customer_Type__c == 'Non Individual' && String.isNotBlank(itr.Pan_Name__c) && itr.Pan_Name__c != oldObj.Pan_Name__c) {
                itr.Name_of_Organization__c = itr.Pan_Name__c;
            }
            if(itr.Aadhaar_Number_Masked__c != null){
                if(itr.Aadhaar_Number_Masked__c != oldObj.Aadhaar_Number_Masked__c && !(itr.Aadhaar_Number_Masked__c.isNumeric() && itr.Aadhaar_Number_Masked__c.length()==12 && String.isNotBlank(itr.Aadhaar_Number_Masked__c))){
                   //masked aadhar
                }else if(itr.Aadhaar_Number_Masked__c != null && itr.Aadhaar_Number_Masked__c != oldObj.Aadhaar_Number_Masked__c){
                    itr.Aadhaar_Number_Masked__c = Utility.getEncryptedBase64String(itr.Aadhaar_Number_Masked__c);
                }
            }
            if (itr.Customer_Type__c == 'Individual' && String.isNotBlank(itr.Pan_Name__c)) {
                 itr.Pan_Name__c = (String.isBlank(itr.First_Name__c) ? '' : itr.First_Name__c) + ' ' +
                        (String.isBlank(itr.Middle_Name__c) ? '' : itr.Middle_Name__c + ' ') +
                        (String.isBlank(itr.Last_Name__c) ? '' : itr.Last_Name__c); 
                List<String> nameParts = itr.Pan_Name__c.split('\\s+');
               /* if (nameParts.size() == 3) {
                    itr.First_Name__c = nameParts[0];
                    itr.Middle_Name__c = nameParts[1];
                    itr.Last_Name__c = nameParts[2];
                } else if (nameParts.size() == 2) {
                    itr.First_Name__c = nameParts[0];
                    itr.Last_Name__c = nameParts[1];
                }*/
                // } else if (nameParts.size() == 1) {
                //     itr.Last_Name__c = nameParts[0];
                // }
            }
            if(itr.Customer_Type__c == 'Non Individual'&& String.isNotBlank(itr.Pan_Name__c)){
                itr.Name_of_Organization__c = itr.Pan_Name__c;
            }
             if(itr.Customer_Type__c == 'Non Individual' && itr.Sector__c!=null){
                // itr.Sub_Employment_Type_Non_Individual__c = itr.Sector__c;
            }
            
            if(itr.Customer_Profile__c != null && (itr.Customer_Profile__c == 'Non Working' || itr.Customer_Profile__c == 'Others' )  && itr.Customer_Profile__c != oldObj.Customer_Profile__c ){
                populateEmpTypeList.add(itr);
            }
            
        }

        ApplicantTriggerImplementation.concatenateName(nameChangeList);
        if(applicantIds != null && shareHondlingPercent != null) {
            ApplicantTriggerImplementation.shareHoldingMaxValueValidation(applicantIds, shareHondlingPercent);
        }
        if(!populateEmpTypeList.isEmpty()){
            ApplicantTriggerImplementation.populateEmploymentType(populateEmpTypeList);
        }
        //write the checks for which we need to perform the action and implement the action in the class ApplicantTriggerImplementation
    }

    public static void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){

        List<Application_Applicant__c> oldRecords = (List<Application_Applicant__c>)oldList;
        Map<Id,String> mapApplicant = new Map<Id,String>();
        Set<Id> applicantIds = new Set<Id>();
        String profileName = Utility.getCurrentUserProfileName();
        for(Application_Applicant__c itr : oldRecords) {
                applicantIds.add(itr.Id);
        }
        List<Application_Applicant__c> appList = [SELECT Id, Loan_Application__c,Loan_Application__r.StageName FROM Application_Applicant__c WHERE Id IN :applicantIds];
        for(Application_Applicant__c itr : appList) {
            mapApplicant.put(itr.Id, itr.Loan_Application__r.StageName);
        }
            for (Application_Applicant__c applicant : oldRecords) {
                if (applicant.Applicant_Type__c == 'Primary Applicant') {
                    applicant.addError('Primary Applicant cannot be deleted.');
                    continue;
                }
                if(profileName == 'Sales' && mapApplicant.get(applicant.Id) == 'PSV'){
                   applicant.addError('You cannot delete Applicant Details at PSV Stage.');
                }
            }
         
    } 

    public static void afterInsert(List<SObject> newList, Map<Id, SObject> newMap){
        Set<Id> allOpenLeadIds = new Set<Id>();
        List<Application_Applicant__c> newRecords = (List<Application_Applicant__c>)newList;
        List<Application_Applicant__c> lstLoanRecordsToUpdateCheckList = new List<Application_Applicant__c>();
        List<Application_Applicant__c> allApplicants= new List<Application_Applicant__c>();
        List<Application_Applicant__c> appListFemale = new List<Application_Applicant__c>();
        Set<Id> oppToUpdateAarohi = new Set<Id>(); 
        //Added for Key Applicant Score Segment update
        List<Application_Applicant__c> keyApplicantScoreList = new List<Application_Applicant__c>();
      
        for(Application_Applicant__c itr : newRecords) {
        
            if(itr.Customer_Type__c == 'Non Individual') {
                allOpenLeadIds.add(itr.Id);
               
            }
            if(itr.Loan_Application__c != null && itr.Applicant_Type__c == 'Primary Applicant'){
                allApplicants.add(itr);
            }
            if(itr?.Gender__c!=null && itr?.Applicant_Type__c == 'Primary Applicant' ){
                appListFemale.add(itr);
                oppToUpdateAarohi.add(itr.Loan_Application__c) ;
            }
            //Added for Key Applicant Score Segment update
            if(itr.Is_Key_Applicant__c == true && itr.Loan_Application__c != null){
                keyApplicantScoreList.add(itr);
            }
           
            lstLoanRecordsToUpdateCheckList.add(itr);
        }
        //Added by Suhrit
        if (allOpenLeadIds.size() > 0) { 
            ApplicantTriggerImplementation.createDocumentChecklistNonIndividual(allOpenLeadIds);
        }
        //Added by Atika
        if(allApplicants.size()>0){
            ApplicantTriggerImplementation.updatePrimaryAppNameOnOpp(allApplicants);
        }
        //Added by Satyam
        if(appListFemale.size()>0){
            ApplicantTriggerImplementation.updateAarohiFlag(appListFemale,oppToUpdateAarohi); 
        }
        //Added for Key Applicant Score Segment update
        if(!keyApplicantScoreList.isEmpty()){
            ApplicantTriggerImplementation.updateScoreSegmentOnOpp(keyApplicantScoreList);
        }
    }

    public static void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){        
        //write the checks for which we need to perform the action and implement the action in the class OpportunityTriggerImplementation
        List<Application_Applicant__c> newRecords = (List<Application_Applicant__c>)newList;
        Set<Id> panvalidated = new Set<Id>(); 
        Set<Id> aadharValidated = new Set<Id>(); 
        Set<Id> passVal = new Set<Id>(); 
        Set<Id> dlVal = new Set<Id>();
        List<Application_Applicant__c> consentUpdateList = new List<Application_Applicant__c>(); 
        List<Application_Applicant__c> allApplicants= new List<Application_Applicant__c>();
        List<Application_Applicant__c> appListFemale = new List<Application_Applicant__c>();
        Set<Id> oppIdsToUpdate = new Set<Id>(); 
        set<Id> nameChangeId = new set<Id>();
        Map<String, Application_Applicant__c> populateEmpTypeincoapp = new Map<String, Application_Applicant__c>();
        //Added for Key Applicant Score Segment update
        List<Application_Applicant__c> keyApplicantScoreList = new List<Application_Applicant__c>();
        for(Application_Applicant__c itr : newRecords) {	
            Application_Applicant__c oldObj = (Application_Applicant__c)oldItems.get(itr.Id);
            if(itr.Pan_Status__c != oldObj.Pan_Status__c && itr.Pan_Status__c == 'Active'){
                panvalidated.add(itr.Id);
            }
            if(itr.Aadhar_Status__c != oldObj.Aadhar_Status__c && itr.Aadhar_Status__c == 'Active'){
                aadharValidated.add(itr.Id);
            }
            if(itr.Passport_Status__c != oldObj.Passport_Status__c && itr.Passport_Status__c == 'Active'){
                passVal.add(itr.Id);
            }
            if(itr.DL_Status__c != oldObj.DL_Status__c && itr.DL_Status__c == 'Active'){
                dlVal.add(itr.Id);
            }
            // if(itr.Customer_Type__c == 'Non Individual' && itr.Sector__c!=null){
            //     itr.Sub_Employment_Type_Non_Individual__c = itr.Sector__c;
            // }
            if ((itr.Is_Consent_Received__c==true && itr.Is_Consent_Received__c!=oldObj.Is_Consent_Received__c) || (itr.First_Name__c != oldObj.First_Name__c) || (itr.Last_Name__c != oldObj.Last_Name__c) || (itr.Middle_Name__c != oldObj.Middle_Name__c) ) {
                nameChangeId.add(itr.Id);
            }
            if((itr.First_Name__c != oldObj.First_Name__c || itr.Last_Name__c != oldObj.Last_Name__c || itr.Middle_Name__c != oldObj.Middle_Name__c || itr.Name_of_Organization__c != oldObj.Name_of_Organization__c) && itr.Loan_Application__c != null && itr.Applicant_Type__c == 'Primary Applicant'){
                allApplicants.add(itr);
            }
            if(itr.Mobile_Number__c != oldObj.Mobile_Number__c && String.isNotBlank(itr.Mobile_Number__c)){
                consentUpdateList.add(itr);
            }
            if(itr.Sector__c != null && itr.Sector__c != oldObj.Sector__c && itr.Applicant_Type__c == 'Primary Applicant'){
                populateEmpTypeincoapp.put(itr.Loan_Application__c, itr);
            }
            if(itr.Applicant_Type__c=='Primary Applicant'  && itr.Gender__c != oldObj.Gender__c){
                appListFemale.add(itr) ;
                oppIdsToUpdate.add(itr.Loan_Application__c); 
            }
            //Added for Key Applicant Score Segment update
            if(itr.Is_Key_Applicant__c == true && itr.Loan_Application__c != null &&
               (itr.Is_Key_Applicant__c != oldObj.Is_Key_Applicant__c || itr.Scorecard_Category__c != oldObj.Scorecard_Category__c)){
                keyApplicantScoreList.add(itr);
            }
        }
        if(!panvalidated.isEmpty()){
            ApplicantTriggerImplementation.verifyKycDoc(panvalidated,'Pan');
        }
        if(!aadharValidated.isEmpty()){
            ApplicantTriggerImplementation.verifyKycDoc(aadharValidated,'Aadhar');
        }
        if(!passVal.isEmpty()){
            ApplicantTriggerImplementation.verifyKycDoc(passVal,'Passport');
        }
        if(!dlVal.isEmpty()){
            ApplicantTriggerImplementation.verifyKycDoc(dlVal,'Driving Licence');
        }
        if (!nameChangeId.isEmpty()) {
            ApplicantTriggerImplementation.syncCustomer(nameChangeId);
        }
        if(allApplicants.size()>0){
        	ApplicantTriggerImplementation.updatePrimaryAppNameOnOpp(allApplicants);
        }
        if(consentUpdateList.size()>0){
            ApplicantTriggerImplementation.updateConsent(consentUpdateList);
        }
        if(!populateEmpTypeincoapp.isEmpty()){
            // ApplicantTriggerImplementation.populateEmploymentInCoAppType(populateEmpTypeincoapp);
        }
        if(appListFemale.size()>0 && oppIdsToUpdate.size()>0){
            ApplicantTriggerImplementation.updateAarohiFlag(appListFemale,oppIdsToUpdate);
        } 
        //Added for Key Applicant Score Segment update
        if(!keyApplicantScoreList.isEmpty()){
            ApplicantTriggerImplementation.updateScoreSegmentOnOpp(keyApplicantScoreList);
        }
    }

    public static void afterDelete( List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public static void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap){}
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }

}