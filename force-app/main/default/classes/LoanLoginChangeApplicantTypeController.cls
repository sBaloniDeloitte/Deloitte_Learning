/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-21-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class LoanLoginChangeApplicantTypeController {
    static string conLabels = 'CIBIL_Score_Threshold';
                         
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }

    // @AuraEnabled(cacheable=true)
    // public static List<Application_Applicant__c> getApplicants(Id loanApplicationId) {
    //     if (String.isEmpty(loanApplicationId)) {
    //         throw new AuraHandledException('Loan Application ID is required.');
    //     }
        
    //     try {
    //         return [
    //             SELECT Id, Name, Applicant_Type__c, Mobile_Number__c, Mobile_Number_Masked__c
    //             FROM Application_Applicant__c 
    //             WHERE Loan_Application__c = :loanApplicationId
    //         ];
    //     } catch (Exception ex) {
    //         throw new AuraHandledException('Error fetching applicants: ' + ex.getMessage());
    //     }
    // }



   
    // @AuraEnabled
    // public static List<Application_Applicant__c> updateApplicantTypes(Id primaryApplicantId, Id coApplicantId) {
    //     if (String.isEmpty(primaryApplicantId) || String.isEmpty(coApplicantId)) {
    //         throw new AuraHandledException('Both Primary Applicant and Co-Applicant IDs are required.');
    //     }

    //     try {
    //         // Create a list to hold the applicants to update
    //         List<Application_Applicant__c> applicantsToUpdate = new List<Application_Applicant__c>();

    //         // Add the primary applicant record to update
    //         applicantsToUpdate.add(new Application_Applicant__c(
    //             Id = primaryApplicantId,
    //             Applicant_Type__c = 'Co Applicant'
    //         ));

    //         // Add the co-applicant record to update
    //         applicantsToUpdate.add(new Application_Applicant__c(
    //             Id = coApplicantId,
    //             Applicant_Type__c = 'Primary Applicant'
    //         ));

    //         // Perform the update
    //         Database.SaveResult[] results = Database.update(applicantsToUpdate, false);

    //         // Check for errors
    //         for (Database.SaveResult result : results) {
    //             if (!result.isSuccess()) {
    //                 throw new AuraHandledException('Error updating applicant types.');
    //             }
    //         }

    //         // Query the updated data to ensure consistency
    //         return [
    //             SELECT Id, Name, Applicant_Type__c, Mobile_Number__c, Mobile_Number_Masked__c
    //             FROM Application_Applicant__c
    //             WHERE Id IN :new Set<Id>{primaryApplicantId, coApplicantId}
    //         ];
    //     } catch (Exception ex) {
    //         throw new AuraHandledException('Error updating applicant types: ' + ex.getMessage());
    //     }
    // }

    @AuraEnabled
    public static List<ApplicantDetailsWrapper> applicantDetails(String recordId){
        try {
            Id profileId = userinfo.getProfileId();
            String profileName = [Select Id,Name from Profile where Id=:profileId].Name;
            
            List<Opportunity> oppList = [SELECT Id,Exception_Approval_Status__c FROM Opportunity WHERE Id =: recordId LIMIT 1];
            
            //Integer threshold = Integer.valueOf(constants.get('CIBIL_Score_Threshold'));
            List<ApplicantDetailsWrapper> apDetList=new List<ApplicantDetailsWrapper>();
            List<Application_Applicant__c> appList=[ SELECT Id, Applicant_Name__c, Applicant_Type__c,Is_Key_Applicant__c, Mobile_Number__c, Mobile_Number_Masked__c,CIBIL_Score__c, Customer_Type__c,Is_Financial_applicant__c
                        FROM Application_Applicant__c 
                        WHERE Loan_Application__c = :recordId ];
            if(appList.size()>0){
              
                Boolean isnonInd= false;
                Boolean isSalesProfile = false;
                if(oppList[0].Exception_Approval_Status__c == 'Submitted For Approval' && profileName == 'Sales'){
                    isSalesProfile = true;
                }
                for(Application_Applicant__c apDet: appList){
                    if(apDet.Customer_Type__c == 'Non Individual' && apDet.Applicant_Type__c == 'Primary Applicant'){
                        isnonInd= true;
                    }
                }
                for(Application_Applicant__c apDet: appList){
                   // if(apDet.Customer_Type__c != 'Non Individual'){
                        ApplicantDetailsWrapper wrap=new ApplicantDetailsWrapper();
                         wrap.isCibilFetched=true;
                        wrap.applicantId=apDet.Id;
                        wrap.applicantName=apDet.Applicant_Name__c!=null?apDet.Applicant_Name__c:'';
                        wrap.applicantType=apDet.Applicant_Type__c;
                        wrap.maskedMobileNumber=apDet.Mobile_Number_Masked__c;
                        // wrap.iscibilLow = (apDet.CIBIL_Score__c!=null && apDet.CIBIL_Score__c < threshold) ? true : false;
                        wrap.iscibilLow = false;
                        wrap.isKeyApplicant= apDet.Is_Key_Applicant__c;
                        wrap.isFinancialApplicant = (apDet.Is_Financial_applicant__c == 'Yes');
                        if(isSalesProfile == true){
                            wrap.disableApplicantType= true;
                        }else{
                            wrap.disableApplicantType= isnonInd;
                        }
                        if(apDet.Customer_Type__c!='Non Individual' && String.isBlank(String.valueOf(apDet.Cibil_Score__c))){
                            wrap.isCibilFetched=false;
                        }
                        Map<String, String> inputMap = new Map<String, String>();
                        inputMap.put('oppId', recordId);
                        Utility_V1.ProductWrapper productWrapper = Utility_V1.getProductDetails(inputMap);
                        Boolean isHlRelated = productWrapper.isHLRelated;

                       /* if (isHlRelated) {
                            String thresholdRange = constants.get('CIBIL_Score_Threshold');
                            if (!String.isBlank(thresholdRange) && apDet.CIBIL_Score__c != null) {
                                List<String> limits = thresholdRange.split('-');
                                if (limits.size() == 2) {
                                    Decimal lowerLimit = Decimal.valueOf(limits[0]);
                                    Decimal upperLimit = Decimal.valueOf(limits[1]);
                                    wrap.iscibilLow = (apDet.CIBIL_Score__c > lowerLimit && apDet.CIBIL_Score__c < upperLimit) ? true: false;
                                }
                            }
                        } */
                        apDetList.add(wrap);
                   // }
                }
            }
            return apDetList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    
    public class ApplicantDetailsWrapper{
        @AuraEnabled public String applicantId;
        @AuraEnabled public String applicantName;
        @AuraEnabled public String applicantType;
        @AuraEnabled public Boolean isKeyApplicant;
        @AuraEnabled public String maskedMobileNumber;
        @AuraEnabled public Boolean iscibilLow;
        @AuraEnabled public Boolean disableApplicantType;
        @AuraEnabled public Boolean isFinancialApplicant;
        @AuraEnabled public Boolean isCibilFetched;
    }
    
    @AuraEnabled
    public static void saveApplicantDetails(String applicantList, Boolean cibilScoreLow, String recordId){
        try {
            List<ApplicantDetailsWrapper> apDetList = (List<ApplicantDetailsWrapper>) JSON.deserialize(applicantList, List<ApplicantDetailsWrapper>.class);
            System.debug('apDetList=:'+apDetList);
            List<Application_Applicant__c> appList=new List<Application_Applicant__c>();
            for(ApplicantDetailsWrapper ap : apDetList){
                Application_Applicant__c apDet = new Application_Applicant__c();
                apDet.Id = ap.applicantId;
                apDet.Applicant_Type__c = ap.applicantType;
                apDet.Is_Key_Applicant__c = ap.isKeyApplicant;
                appList.add(apDet);
            }
            if(appList.size()>0){
                
                    // Insert share rows for each record you’re about to update
                    List<SObject> shareRows = new List<SObject>();
                     List<Application_Applicant__Share> shareList = new List<Application_Applicant__Share>();
                    for (Application_Applicant__c rec : appList) {
                        // Always check if the Share object exists (compile-safe if OWD changes later)
                        // // if (Schema.getGlobalDescribe().containsKey('Application_Applicant__Share')) {
                        //     SObjectType shareType = Schema.getGlobalDescribe().get('Application_Applicant__Share');
                        //     SObject shareRow = shareType.newSObject();
                        //     shareRow.put('ParentId', rec.Id);

                        //     // Replace with the Id of the user/group/role that should get access
                        //     // e.g. current user, record owner’s role, or a portal role
                        //     shareRow.put('UserOrGroupId', UserInfo.getUserId());

                        //     // AccessLevel: 'Read' or 'Edit'
                        //     shareRow.put('AccessLevel', 'Edit');

                        //     // RowCause must match a defined reason or 'Manual'
                        //     shareRow.put('RowCause', 'Manual');

                        //     shareRows.add(shareRow);
                        // }
                         Application_Applicant__Share shareApplicant = new Application_Applicant__Share();
                                shareApplicant.parentId = rec.Id;
                                shareApplicant.UserOrGroupId = UserInfo.getUserId();
                                shareApplicant.AccessLevel = 'Edit';
                                shareList.add(shareApplicant);
                    }
                    if (!shareList.isEmpty()) {
                       // Insert shareList; // don’t stop if some fail
                    }
                    System.debug('shareList=='+shareList);
                    // Now proceed with your update

                update appList;
            }

            Opportunity loan= new Opportunity();
            loan.Id=recordId;
            if(loan.Login_Completion_Stage__c!=null){
                loan.Login_Completion_Stage__c = loan.Login_Completion_Stage__c+';'+'Applicant Information';
            }
            else{
                loan.Login_Completion_Stage__c = 'Applicant Information';
            }
           

            if(cibilScoreLow){                
                loan.Exception_Approval_Status__c= 'Not started';
                loan.Reasons_For_Execption_Approval__c= 'Low Cibil Score';
                loan.Is_Eligible_for_Exception_Approval__c= true;
            }else{
                loan.Exception_Approval_Status__c= 'Not started';
                loan.Reasons_For_Execption_Approval__c= '';
                loan.Is_Eligible_for_Exception_Approval__c= false;
            }

            update loan; 
        } catch (Exception e) {
            throw new AuraHandledException(e.getLineNumber() + e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateCibilException(String recordId){
        try {
            Opportunity loan= new Opportunity();
            loan.Id=recordId;
            loan.Exception_Approval_Status__c= 'Not started';
            loan.Reasons_For_Execption_Approval__c= 'Low Cibil Score';
            loan.Is_Eligible_for_Exception_Approval__c= true;

            update loan;    
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static String checkifbureauisfetched(String appId ){
        Boolean cibilFetched = true;
        String errorMessage = '';
        try {
            List<Application_Applicant__c> appList = [
                SELECT Id, Pan_Status__c,Basic_Details_Filled__c ,Customer_Profile__c,Employer_Name__c,Is_Financial_applicant__c,Cibil_Score__c, IsForm60Uploaded__c,Applicant_Type__c, Customer_Type__c 
                FROM Application_Applicant__c 
                WHERE Id = :appId
            ];
            
            for (Application_Applicant__c app : appList) {
                System.debug('app.Id>>'+app.Id);

                System.debug('app.Customer_Type__c>>>'+app.Customer_Type__c);
               
               System.debug('app.Basic_Details_Filled__c>>'+app.Basic_Details_Filled__c);
               System.debug('String.isBlank(app.Basic_Details_Filled__c )>>>'+String.isBlank(app.Basic_Details_Filled__c ));
           if (app.Customer_Type__c == 'Individual') {
               System.debug('app.Customer_Type__c>>>'+app.Customer_Type__c);
               
               System.debug('app.Basic_Details_Filled__c>>'+app.Basic_Details_Filled__c);
               System.debug('String.isBlank(app.Basic_Details_Filled__c )>>>'+String.isBlank(app.Basic_Details_Filled__c ));
               
                /*if((String.isBlank(app.Basic_Details_Filled__c ))){
                    errorMessage = 'Please fill the basic details of the applicant before making them a key applicant.';
                    return errorMessage;
                }*/
                if((app.Customer_Profile__c.contains('Salaried') && String.isBlank(app.Employer_Name__c) && app.Is_Financial_applicant__c == 'Yes')){
                    errorMessage = 'Please fill the Employment Details of the applicant before making them a key applicant.';
                    return errorMessage;

                }
               if(String.isBlank(app.Pan_Status__c) && String.isBlank(String.valueOf(app.Cibil_Score__c)) && String.isBlank(app.IsForm60Uploaded__c)){

                        cibilFetched = false;
                 }

                else if ((String.isBlank(app.Pan_Status__c) && String.isBlank(String.valueOf(app.Cibil_Score__c))) || 
                    (String.isBlank(app.IsForm60Uploaded__c) && String.isBlank(String.valueOf(app.Cibil_Score__c)))) {
                       cibilFetched = false;
                        
                    }
                    if(!cibilFetched){
                        errorMessage = 'The applicant\'s bureau information has not been fetched or PAN has not been validated. Unable to make this applicant a key applicant.';
                       // throw new AuraHandledException(errorMessage);
                    }
                }  
                else if (app.Customer_Type__c == 'Non Individual') {
                   if((String.isBlank(app.Basic_Details_Filled__c ))){
                    errorMessage = 'Please fill the basic details of the applicant before making them a key applicant.';
                    return errorMessage;
                }
                if((app.Customer_Profile__c.contains('Salaried') && String.isBlank(app.Employer_Name__c))){
                    errorMessage = 'Please fill the Employment Details of the applicant before making them a key applicant.';
                    return errorMessage;

                }
               if(String.isBlank(app.Pan_Status__c) /*&& String.isBlank(String.valueOf(app.Cibil_Score__c))*/ && String.isBlank(app.IsForm60Uploaded__c)){
                        cibilFetched = false;
                 }

                else if ((String.isBlank(app.Pan_Status__c) && String.isBlank(String.valueOf(app.Cibil_Score__c))) || 
                    (String.isBlank(app.IsForm60Uploaded__c) && String.isBlank(String.valueOf(app.Cibil_Score__c)))) {
                       cibilFetched = false;
                        
                    }
                    if(!cibilFetched){
                        errorMessage = 'The applicant\'s bureau information has not been fetched or PAN has not been validated. Unable to make this applicant a key applicant.';
                       // throw new AuraHandledException(errorMessage);
                    }
                }
            
        }
        return errorMessage;
    }
         catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}