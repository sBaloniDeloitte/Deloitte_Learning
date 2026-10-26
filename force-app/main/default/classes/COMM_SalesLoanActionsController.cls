/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 05-19-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
//Added
public without sharing class COMM_SalesLoanActionsController {
    @AuraEnabled
    public static List<ActionListWrapper> getActionList(String loanId){
        List<ActionListWrapper> actionWrapList  = new List<ActionListWrapper>();
        Boolean b = false;
        Integer i =1;
        Set<String> addedStages = new Set<String>(); 
        Map<String,String> inputMap = new Map<String,String>();
        inputMap.put('loanId',loanId);
        List<String> completedResults = COMM_SalesLoanLoginController.checkSubStageCompletionApplicantInformation(inputMap);
        List<Opportunity> loanList = [Select Id, Product__c, Login_Completion_Stage__c,Is_Eligible_for_Exception_Approval__c, Branch_Master__c from Opportunity where id=: loanId];
        List<Application_Applicant__c> apDetList = [Select Id, Customer_Type__c, Employment_Type__c from Application_Applicant__c where Loan_Application__c =: loanId and Applicant_Type__c!='Builder'];
        List<Screen_Field__c> screenDetails = new List<Screen_Field__c>();
        //HL-Ishi-25-10
        Map<String,String> inputMapUtility = new  Map<String,String>();
        Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
        Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
        List<Product2> prodList = [Select Id, Name from Product2 where Loan_Application__c =: loanId and RecordType.Name = 'Product' and Name =: loanList[0].Product__c limit 1];
        List<Screen_Field__c> screenFieldToReturn = new List<Screen_Field__c>();
        //HL-Ishi-25-10
        
        screenDetails = [Select Id, Screen_Name__c, Applicable_For_Products__c, Applicable_Login_Stage__c,Master_Screen_Sequence__c,Master_Screen_Name__c from Screen_Field__c where Form_Name__c = 'Loan Login Form' AND  Is_Screen_Active__c = true and (Applicable_For__c = 'Both' or Applicable_For__c = 'Individual-Both' or Applicable_For__c = 'Non Individual-Both')  AND RecordType.Name='Screen' AND Master_Screen_Sequence__c!= null ORDER BY Master_Screen_Sequence__c ASC];
        for(Screen_Field__c scf : screenDetails){
            if(isHlRelated){
                if(!prodList.isEmpty()){
                    if(String.isNotBlank(scf.Applicable_For_Products__c)){
                        List<String> applicableProdList = scf.Applicable_For_Products__c.split(',');
                        if(applicableProdList.contains(prodList[0].Name)){
                            screenFieldToReturn.add(scf);
                        }
                    }
                }
                else{
                    screenFieldToReturn.add(scf);
                }
            }
            else{
                if(String.isBlank(scf.Applicable_For_Products__c)){
                      screenFieldToReturn.add(scf);
                }
              
            }
        }
      
        Set<String> completedStages = new Set<String>();
            if (loanList.size() > 0 && loanList[0].Login_Completion_Stage__c != null) {
                completedStages.addAll(loanList[0].Login_Completion_Stage__c.split(';'));
            }
            System.debug('completedStages-----'+completedStages);
            
        Set<String> screenNames = new Set<String>();
        Set<String> currentStageScreens = new Set<String>();
        System.debug('loanList[0].Branch_Master__c----'+loanList[0].Branch_Master__c);
        for(Screen_Field__c screen : screenFieldToReturn){
            if (!addedStages.contains(screen.Applicable_Login_Stage__c)) {
                System.debug('completedStages-----'+completedStages);
                System.debug('screen.Master_Screen_Name__c-----'+screen.Applicable_Login_Stage__c);
              
                if(loanList[0].Is_Eligible_for_Exception_Approval__c && (loanList[0].Branch_Master__c != null)){
                    ActionListWrapper actWrap = new ActionListWrapper();
                    actWrap.Name = screen.Applicable_Login_Stage__c;
                    //actWrap.completed  = false;
                    //actWrap.isAllComplete = false;
                    if (screen.Master_Screen_Sequence__c == 1 || screen.Master_Screen_Sequence__c == 2) {
                        actWrap.isDisabled = false;
                    }
                    else {
                        actWrap.isDisabled = !(loanList[0].Login_Completion_Stage__c != null &&
                                            (loanList[0].Login_Completion_Stage__c.contains('Applicant Information') &&
                                            loanList[0].Login_Completion_Stage__c.contains('Application Information')));
                    }
                    if (completedStages.contains(screen.Applicable_Login_Stage__c)) {
                        actWrap.completed = true;
                    }
        
                        
                        // if(loanList[0].Login_Completion_Stage__c.contains(screen.Master_Screen_Name__c)){
                        //     actWrap.completed  = true;
                        // }
                        // Integer count = 0;
                        // if(screen.Applicable_Login_Stage__c == 'Product Details' && completedResults.contains('Product Details')){
                        //     count ++;
                        // }
                        // if()

                    
                    actionWrapList.add(actWrap);
                    addedStages.add(screen.Applicable_Login_Stage__c);
                }else if(loanList[0].Is_Eligible_for_Exception_Approval__c && (loanList[0].Branch_Master__c == null)){
                    if(screen.Applicable_Login_Stage__c != 'Exception Flow'){
                        System.debug('completedStages-----'+completedStages);
                        System.debug('screen.Master_Screen_Name__c-----'+screen.Applicable_Login_Stage__c);
                        ActionListWrapper actWrap = new ActionListWrapper();
                        actWrap.Name = screen.Applicable_Login_Stage__c;
                        //actWrap.completed  = false;
                        actWrap.isAllComplete = false;
                        if (screen.Master_Screen_Sequence__c == 1 || screen.Master_Screen_Sequence__c == 2) {
                        actWrap.isDisabled = false;
                        }
                        else {
                            actWrap.isDisabled = !(loanList[0].Login_Completion_Stage__c != null &&
                                                (loanList[0].Login_Completion_Stage__c.contains('Applicant Information') &&
                                                loanList[0].Login_Completion_Stage__c.contains('Application Information')));
                        }
                        
                        if (completedStages.contains(screen.Applicable_Login_Stage__c)) {
                            actWrap.completed = true;
                        }
            
                      
                            // if(loanList[0].Login_Completion_Stage__c.contains(screen.Master_Screen_Name__c)){
                            //     actWrap.completed  = true;
                            // }
                            // Integer count = 0;
                            // if(screen.Applicable_Login_Stage__c == 'Product Details' && completedResults.contains('Product Details')){
                            //     count ++;
                            // }
                            // if()
    
                        
                        actionWrapList.add(actWrap);
                        addedStages.add(screen.Applicable_Login_Stage__c);
                        
                    }
                   
                }else if(!loanList[0].Is_Eligible_for_Exception_Approval__c && screen.Applicable_Login_Stage__c != 'Exception Flow'){
                    ActionListWrapper actWrap = new ActionListWrapper();
                    actWrap.Name = screen.Applicable_Login_Stage__c;
                    //actWrap.completed  = false;
                    //actWrap.isAllComplete = false;
                    if (screen.Master_Screen_Sequence__c == 1 || screen.Master_Screen_Sequence__c == 2) {
                    actWrap.isDisabled = false;
                    }
                    else {
                    actWrap.isDisabled = !(loanList[0].Login_Completion_Stage__c != null &&
                                           (loanList[0].Login_Completion_Stage__c.contains('Applicant Information') &&
                                            loanList[0].Login_Completion_Stage__c.contains('Application Information')));
                    }
                  
                    // if(completedResults.size()>0){
                    //     if(screen.Applicable_Login_Stage__c == 'Product Details' && completedResults.contains('Product Details')){
                    //         actWrap.completed  = true;
                    //     }
                    //     else if(screen.Applicable_Login_Stage__c == 'Loan Details' && completedResults.contains('Loan Details')){
                    //         actWrap.completed  = true;
                    //     }
                    // }
                   
                        // if(loanList[0].Login_Completion_Stage__c.contains(screen.Master_Screen_Name__c)){
                        //     actWrap.completed  = true;
                        // }
                        // Integer count = 0;
                        // if(screen.Applicable_Login_Stage__c == 'Product Details' && completedResults.contains('Product Details')){
                        //     count ++;
                        // }
                        // if()
                        System.debug('completedStages-----'+completedStages);
                        System.debug('screen.Master_Screen_Name__c-----'+screen.Applicable_Login_Stage__c);
                        if (completedStages.contains(screen.Applicable_Login_Stage__c)) {
                            actWrap.completed = true;
                        }
            
                    
                    actionWrapList.add(actWrap);
                    addedStages.add(screen.Applicable_Login_Stage__c);
                    
                }
               
                
            }
        }
        System.debug(actionWrapList);
        
        return actionWrapList;
    }
        @AuraEnabled
    public static ProductWrapper checkIfLoggedInUserIsHLRelated(Map<String,String> inputMap) {
        ProductWrapper pw = new ProductWrapper();
        List<User> u = [
            SELECT Id, Name, Username, Email
            FROM User
            WHERE Id IN (
                SELECT AssigneeId
                FROM PermissionSetAssignment
                WHERE PermissionSet.Name IN ('PS_Sales_Executive_HL','PS_Credit_Manager_HL')
            )
            AND Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (!u.isEmpty()) {
            pw.isHLRelated =true;
        }
        else{
             pw.isHLRelated =false;
        }
        return pw;
    }
        public class ProductWrapper{
        @AuraEnabled public String product;
        @AuraEnabled public String loanProduct;
        @AuraEnabled public Boolean isHLRelated;
        @AuraEnabled public String  productId;
        @AuraEnabled public String  productName;

    }

    @AuraEnabled
    public static String getPANContentVersionId(Id applicantId) {
        try {
            List<Document_Details__c> docList = [
                SELECT Id, Content_Document_Id__c 
                FROM Document_Details__c 
                WHERE Applicant__c = :applicantId AND Name = 'PAN' Order By CreatedDate Desc LIMIT 1];

            if (!docList.isEmpty() && docList[0].Content_Document_Id__c != null) {
                List<ContentVersion> cvList = [
                    SELECT Id,ContentDocumentId, FileExtension
                    FROM ContentVersion 
                    WHERE ContentDocumentId = :docList[0].Content_Document_Id__c
                    ORDER BY CreatedDate DESC 
                    LIMIT 1
                ];
                if (!cvList.isEmpty()) {
                    return cvList[0].Id+' '+cvList[0].ContentDocumentId+' '+cvList[0].FileExtension;
                }
            }
        } catch (Exception ex) {
            System.debug('Error in getPANContentVersionId: ' + ex.getMessage());
        }
        return null; // nothing found
    }

    @AuraEnabled
    public static void deletePanDetails(Map<String, String> inputMap) {
        try {
            String applicantId = inputMap.get('applicantId');
            String contentVersionId = inputMap.containsKey('contentVersionId') ? inputMap.get('contentVersionId') : null;

            // Step 1: Clear PAN fields from Application_Applicant__c
            List<Application_Applicant__c> appList = [SELECT Id, PAN_Number__c, DOB__c, DOI__c, Applicant_Type__c FROM Application_Applicant__c  WHERE Id = :applicantId LIMIT 1];

            if (!appList.isEmpty()) {
                appList[0].PAN_Number__c = null;
                appList[0].DOB__c = null;
                appList[0].DOI__c = null;
                appList[0].Pan_Name__c = null;
                appList[0].Pan_Father_s_Name__c = null;
                appList[0].PAN_DOB__c = null;
                appList[0].First_Name__c = null;
                appList[0].Last_Name__c = null;
                appList[0].Father_s_First_Name__c = null;
                appList[0].Father_s_Last_Name__c = null;
                appList[0].Sector__c = null;
                update appList;
            }

            // Step 2: If contentVersionId is present → delete related Document_Details__c record
            if (String.isNotBlank(contentVersionId)) {
                ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion  WHERE Id = :contentVersionId LIMIT 1];

                if (cv != null && cv.ContentDocumentId != null) {
                    // Find related Document_Details__c
                    List<Document_Details__c> docList = [SELECT Id FROM Document_Details__c WHERE Applicant__c = :applicantId AND Content_Document_Id__c = :cv.ContentDocumentId LIMIT 1];
                    if (!docList.isEmpty()) {
                        delete docList[0];
                    }

                }
            }

        } catch (Exception e) {
            System.debug('Error in deletePanDetails: ' + e.getMessage() + 'at line '+ e.getLineNumber());
            throw new AuraHandledException('Error in deletePanDetails: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<SubStageWrapper> getSubStageList(String loanId, String applicableStage, String formName, String apDetId) {
        System.debug('formname==>'+formName);
        System.debug('applicableStage==>'+applicableStage);
        if(formName == null){
            formName = 'Loan Login Form';
        }
        if(formName.contains('\u2019')){
            formName = formName.replaceAll('\u2019','\'s');
        }
        if(applicableStage.contains('\u2019')){
            applicableStage = applicableStage.replaceAll('\u2019','\'s');
        }
        List<Application_Applicant__c> appApplicant  = new List<Application_Applicant__c>();
        List<SubStageWrapper> subStageList = new List<SubStageWrapper>();
        Set<String> addedSubStages = new Set<String>(); 
        List<Screen_Field__c> screenDetails = new  List<Screen_Field__c>();
        // Fetch screens based on the selected applicable stage
        List<String> completedResults = new List<String>();
        if(apDetId != null){
            Map<String,String> inputMap = new Map<String,String>();
            inputMap.put('applicantId',apDetId);
            inputMap.put('loanId',loanId);
            completedResults = COMM_SalesLoanLoginController.checkSubStageCompletionApplicantInformation(inputMap);
            appApplicant= [Select id, Customer_Type__c,Applicant_Type__c from Application_Applicant__c where id=:apDetId  and Applicant_Type__c!='Builder'];
        }
        else if(loanId != null){
            Map<String,String> inputMap = new Map<String,String>();
            inputMap.put('loanId',loanId);
            completedResults = COMM_SalesLoanLoginController.checkSubStageCompletionApplicantInformation(inputMap);
        }
        List<Product2> mainProd = [SELECT id,Name FROM Product2 WHERE Loan_Application__c =:loanId AND RecordType.name = 'Product' and Product_Type__c='Parent'];
        //HL-Ishi-25-10
        Map<String,String> inputMapUtility = new  Map<String,String>();
        Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
         Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
        //Boolean isHlRelated = false;
        // List<Product2> prodList = [Select Id, Name from Product2 where Loan_Application__c =: loanId and RecordType.Name = 'Product' and Name =: loanList[0].Product__c limit 1];
        List<Screen_Field__c> screenFieldToReturn = new List<Screen_Field__c>();
        //HL-Ishi-25-10
        screenDetails = [
            SELECT Id, Master_Screen_Name__c, Applicable_For__c,Applicable_Login_Stage__c,Screen_Sequence__c,Applicable_For_Products__c
            FROM Screen_Field__c
            
            Where Is_Screen_Active__c = TRUE
            AND Form_Name__c =: formName
            AND Applicable_Login_Stage__c = :applicableStage
            ORDER BY Screen_Sequence__c ASC
        ];
        for(Screen_Field__c scf : screenDetails){
            //HL-ISHI-13-10
            if(isHlRelated){
                if(!mainProd.isEmpty()){
                    if(String.isNotBlank(scf.Applicable_For_Products__c)){
                        List<String> applicableProdList = scf.Applicable_For_Products__c.split(',');
                        System.debug('applicableProdList=:'+applicableProdList);
                        System.debug('mainProd[0].Name=:'+mainProd[0].Name);
                        if(applicableProdList.contains(mainProd[0].Name)){
                            screenFieldToReturn.add(scf);
                        }
                    }
                }
                else{
                    screenFieldToReturn.add(scf);
                }
            }
            else{
                if(String.isBlank(scf.Applicable_For_Products__c)){
                    screenFieldToReturn.add(scf);
                }
                
            }
            //HL-ISHI-13-10
        }
        
        System.debug('mainProd '+mainProd);
        for (Screen_Field__c screen : screenFieldToReturn) {
            System.debug('screen>>'+screen);
            SubStageWrapper subWrap = new SubStageWrapper();
            if(screen.Master_Screen_Name__c == 'PMAY Eligibility') {
                //Boolean show = false;
                Boolean show = true;
               /* if(mainProd.size() > 0) {
                    for(Product2 iterProd : mainProd) {
                        String temp = screen.Applicable_For_Products__c;
                        if(temp.contains(iterProd.name)) {
                            show = true;
                            break;
                        }
                    }
                }else {
                    show = true;
                }*/
                System.debug('show'+show);
                if(show) {
                    if (screen.Master_Screen_Name__c!= null && !addedSubStages.contains(screen.Master_Screen_Name__c)) {
                if((apDetId == null)||(apDetId != null && (screen.Applicable_For__c=='Both' ||screen.Applicable_For__c==appApplicant[0].Customer_Type__c)) ){
                    if(apDetId != null && screen.Master_Screen_Name__c == 'Consent' && appApplicant[0].Applicant_Type__c == 'Primary Applicant'){
                        continue; // Skip Consent screen for non-primary applicants
                    }
                    subWrap.name = screen.Master_Screen_Name__c;
                    //subWrap.isCompleted =false; // Assuming this field tracks completion status
                    subWrap.sequence = String.valueof(screen.Screen_Sequence__c);
                    subWrap.applicableFor = screen.Applicable_For__c;
                    addedSubStages.add(screen.Master_Screen_Name__c);
                    if(completedResults.size()>0){
                        System.debug('completedResults-----'+completedResults);
                        System.debug('screen.Applicable_Login_Stage__c -----'+screen.Applicable_Login_Stage__c );
                       
                        if(screen.Master_Screen_Name__c == 'PAN/Form 60 Details'){
                            if(completedResults.contains('PAN/Form 60 Details')){
                                subWrap.isCompleted =true;
                            }
                        }
                        if(screen.Master_Screen_Name__c == 'Aadhar Details'){
                            if(completedResults.contains('Aadhar Details')){
                                subWrap.isCompleted = true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Dedupe'){
                            if(completedResults.contains('Dedupe')){
                                subWrap.isCompleted =true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Applicant\'s Basic Information'){
                            if(completedResults.contains('Basic Information')){
                                subWrap.isCompleted =true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Consent'){
                            if(completedResults.contains('Consent')){
                                subWrap.isCompleted =true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Employment Details'){
                            if(completedResults.contains('Employment Details')){
                                subWrap.isCompleted =true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'PAN validation'){
                            if(completedResults.contains('PAN Validation')){
                                subWrap.isCompleted =true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Document Details'||screen.Master_Screen_Name__c == 'Document details'){
                            if(completedResults.contains('Document Complete')){
                                subWrap.isCompleted =true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Applicant\'s Additional Information'){
                            if(completedResults.contains('Additional Information')){
                                subWrap.isCompleted =true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Applicant\'s Address Information'){
                            if(completedResults.contains('AddressInformation')){
                                subWrap.isCompleted =true;
                            }
                        }
                        
                        else if(screen.Master_Screen_Name__c == 'Additional Information'){
                            if(completedResults.contains('Application OtherDetails')){
                                subWrap.isCompleted =true;
                            }

                        }
                        else if(screen.Master_Screen_Name__c == 'Additional Information'){
                            if(completedResults.contains('Application OtherDetails')){
                                subWrap.isCompleted =true;
                            }

                        }
                        else if(screen.Master_Screen_Name__c == 'Bureau insights'){
                            if(completedResults.contains('Bureau Insights')){
                                subWrap.isCompleted =true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Product Details'){
                            if(completedResults.contains('Product Completion')){
                            subWrap.isCompleted  = true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Loan Details'){
                            if(completedResults.contains('Loan Details')){
                            subWrap.isCompleted  = true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Login Fees'){
                            if(completedResults.contains('Login Fees')){
                            subWrap.isCompleted  = true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'PMAY Eligibility'){
                            if(completedResults.contains('PMAY Eligibilty')){
                            subWrap.isCompleted  = true;
                            }
                        }
                         else if(screen.Master_Screen_Name__c == 'Address Details'){
                            if(completedResults.contains('Address Details')){
                            subWrap.isCompleted  = true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Application Other Details' ){
                            if(completedResults.contains('Application OtherDetails')){
                                subWrap.isCompleted =true;
                            }
                        }
                         if(screen.Applicable_Login_Stage__c == 'Applicant Other Details'){
                             if(screen.Master_Screen_Name__c == 'Applicant\'s Address Information'){
                                if(completedResults.contains('AddressInformation')){
                                    subWrap.isCompleted =true;
                                }
                            }
                        
                        }
                       
                    }
                    subStageList.add(subWrap);
                }
                // else if(apDetId == null){
                //     subWrap.name = screen.Master_Screen_Name__c;
                //     subWrap.isCompleted =false; // Assuming this field tracks completion status
                //     subWrap.sequence = String.valueof(screen.Screen_Sequence__c);
                //     subStageList.add(subWrap);
                //     addedSubStages.add(screen.Master_Screen_Name__c);
                //     if(completedResults.size()>0){
                //         if(screen.Master_Screen_Name__c == 'PAN Details'){
                //             if(completedResults.contains('PAN Details')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Dedupe'){
                //             if(completedResults.contains('Dedupe')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Applicant\'s Basic Information'){
                //             if(completedResults.contains('Basic Information')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Consent'){
                //             if(completedResults.contains('Consent')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'PAN validation'){
                //             if(completedResults.contains('PAN Validation')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Bureau insights'){
                //             if(completedResults.contains('Bureau Insights')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Document Details'||screen.Master_Screen_Name__c == 'Document details'){
                //             if(completedResults.contains('Document Complete')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Applicant\'s Address Information'){
                //             if(completedResults.contains('AddressInformation')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Applicant Other Details'){
                //             if(completedResults.contains('AddressInformation')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Application Other Details'){
                //             if(completedResults.contains('Application OtherDetails')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Applicant\'s Additional Information'){
                //             if(completedResults.contains('Additional Information')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Additional Information'){
                //             if(completedResults.contains('Application OtherDetails')){
                //                 subWrap.isCompleted =true;
                //             }

                //         }
                //         else if(screen.Master_Screen_Name__c == 'Product Details'){
                //             if(completedResults.contains('Product Completion')){
                //             subWrap.isCompleted  = true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Loan Details'){
                //             if(completedResults.contains('Loan Details')){
                //             subWrap.isCompleted  = true;
                //             }
                //         }
                        
                //     }
                // }
            }
                }
            }
            else {
            if (screen.Master_Screen_Name__c!= null && !addedSubStages.contains(screen.Master_Screen_Name__c)) {
                if((apDetId == null)||(apDetId != null && (screen.Applicable_For__c=='Both' ||screen.Applicable_For__c==appApplicant[0].Customer_Type__c)) ){
                    if(apDetId != null && screen.Master_Screen_Name__c == 'Consent' && appApplicant[0].Applicant_Type__c == 'Primary Applicant'){
                        continue; // Skip Consent screen for non-primary applicants
                    }
                    subWrap.name = screen.Master_Screen_Name__c;
                    //subWrap.isCompleted =false; // Assuming this field tracks completion status
                    subWrap.sequence = String.valueof(screen.Screen_Sequence__c);
                    subWrap.applicableFor = screen.Applicable_For__c;
                    addedSubStages.add(screen.Master_Screen_Name__c);
                    if(completedResults.size()>0){
                        System.debug('completedResults-----'+completedResults);
                        System.debug('screen.Applicable_Login_Stage__c -----'+screen.Applicable_Login_Stage__c );
                       
                        if(screen.Master_Screen_Name__c == 'PAN/Form 60 Details'){
                            if(completedResults.contains('PAN/Form 60 Details')){
                                subWrap.isCompleted =true;
                            }
                        }
                        if(screen.Master_Screen_Name__c == 'Aadhar Details'){
                            if(completedResults.contains('Aadhar Details')){
                                subWrap.isCompleted = true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Dedupe'){
                            if(completedResults.contains('Dedupe')){
                                subWrap.isCompleted =true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Applicant\'s Basic Information'){
                            if(completedResults.contains('Basic Information')){
                                subWrap.isCompleted =true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Consent'){
                            if(completedResults.contains('Consent')){
                                subWrap.isCompleted =true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Employment Details'){
                            if(completedResults.contains('Employment Details')){
                                subWrap.isCompleted =true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'PAN validation'){
                            if(completedResults.contains('PAN Validation')){
                                subWrap.isCompleted =true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Document Details'||screen.Master_Screen_Name__c == 'Document details'){
                            if(completedResults.contains('Document Complete')){
                                subWrap.isCompleted =true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Applicant\'s Additional Information'){
                            if(completedResults.contains('Additional Information')){
                                subWrap.isCompleted =true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Applicant\'s Address Information'){
                            if(completedResults.contains('AddressInformation')){
                                subWrap.isCompleted =true;
                            }
                        }
                        
                        else if(screen.Master_Screen_Name__c == 'Additional Information'){
                            if(completedResults.contains('Application OtherDetails')){
                                subWrap.isCompleted =true;
                            }

                        }
                        else if(screen.Master_Screen_Name__c == 'Additional Information'){
                            if(completedResults.contains('Application OtherDetails')){
                                subWrap.isCompleted =true;
                            }

                        }
                        else if(screen.Master_Screen_Name__c == 'Bureau insights'){
                            if(completedResults.contains('Bureau Insights')){
                                subWrap.isCompleted =true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Product Details'){
                            if(completedResults.contains('Product Completion')){
                            subWrap.isCompleted  = true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Loan Details'){
                            if(completedResults.contains('Loan Details')){
                            subWrap.isCompleted  = true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Login Fees'){
                            if(completedResults.contains('Login Fees')){
                            subWrap.isCompleted  = true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'PMAY Eligibility'){
                            if(completedResults.contains('PMAY Eligibilty')){
                            subWrap.isCompleted  = true;
                            }
                        }
                         else if(screen.Master_Screen_Name__c == 'Address Details'){
                            if(completedResults.contains('Address Details')){
                            subWrap.isCompleted  = true;
                            }
                        }
                        else if(screen.Master_Screen_Name__c == 'Application Other Details' ){
                            if(completedResults.contains('Application OtherDetails')){
                                subWrap.isCompleted =true;
                            }
                        }
                         if(screen.Applicable_Login_Stage__c == 'Applicant Other Details'){
                             if(screen.Master_Screen_Name__c == 'Applicant\'s Address Information'){
                                if(completedResults.contains('AddressInformation')){
                                    subWrap.isCompleted =true;
                                }
                            }
                        
                        }
                       
                    }
                     System.debug('subWrap==>'+subWrap);
                    subStageList.add(subWrap);
                }
                // else if(apDetId == null){
                //     subWrap.name = screen.Master_Screen_Name__c;
                //     subWrap.isCompleted =false; // Assuming this field tracks completion status
                //     subWrap.sequence = String.valueof(screen.Screen_Sequence__c);
                //     subStageList.add(subWrap);
                //     addedSubStages.add(screen.Master_Screen_Name__c);
                //     if(completedResults.size()>0){
                //         if(screen.Master_Screen_Name__c == 'PAN Details'){
                //             if(completedResults.contains('PAN Details')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Dedupe'){
                //             if(completedResults.contains('Dedupe')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Applicant\'s Basic Information'){
                //             if(completedResults.contains('Basic Information')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Consent'){
                //             if(completedResults.contains('Consent')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'PAN validation'){
                //             if(completedResults.contains('PAN Validation')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Bureau insights'){
                //             if(completedResults.contains('Bureau Insights')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Document Details'||screen.Master_Screen_Name__c == 'Document details'){
                //             if(completedResults.contains('Document Complete')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Applicant\'s Address Information'){
                //             if(completedResults.contains('AddressInformation')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Applicant Other Details'){
                //             if(completedResults.contains('AddressInformation')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Application Other Details'){
                //             if(completedResults.contains('Application OtherDetails')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Applicant\'s Additional Information'){
                //             if(completedResults.contains('Additional Information')){
                //                 subWrap.isCompleted =true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Additional Information'){
                //             if(completedResults.contains('Application OtherDetails')){
                //                 subWrap.isCompleted =true;
                //             }

                //         }
                //         else if(screen.Master_Screen_Name__c == 'Product Details'){
                //             if(completedResults.contains('Product Completion')){
                //             subWrap.isCompleted  = true;
                //             }
                //         }
                //         else if(screen.Master_Screen_Name__c == 'Loan Details'){
                //             if(completedResults.contains('Loan Details')){
                //             subWrap.isCompleted  = true;
                //             }
                //         }
                        
                //     }
                // }
                }
                }
                }
        
        System.debug(subStageList);
        return subStageList;
    }

    @AuraEnabled
    public static void deleteFormSixty(String applicantId) {
        try {
            // 1. Fetch applicant
            Application_Applicant__c applicant = [
                SELECT Id, IsForm60Uploaded__c 
                FROM Application_Applicant__c 
                WHERE Id = :applicantId
                LIMIT 1
            ];

            // 2. Find related Form-60 Document Detail
            List<Document_Details__c> docDetails = [
                SELECT Id, Content_Document_Id__c 
                FROM Document_Details__c
                WHERE Applicant__c = :applicant.Id
                AND Name = 'Form 60'
                LIMIT 1
            ];

            if (!docDetails.isEmpty()) {
                Document_Details__c docDetail = docDetails[0];

                // 3. Delete linked file (if exists)
                if (docDetail.Content_Document_Id__c != null) {
                    delete [SELECT Id FROM ContentDocument WHERE Id = :docDetail.Content_Document_Id__c];
                }

                // 4. Delete the Document Detail
                delete docDetail;
            }

            // 5. Update applicant flag
            applicant.IsForm60Uploaded__c = 'No';
            update applicant;

        } catch (Exception ex) {
            System.debug('Error while deleting Form-60: ' + ex.getMessage());
            throw new AuraHandledException('Failed to delete Form-60: ' + ex.getMessage());
        }
    }

    @AuraEnabled
public static String getCkycNumber(Id loanId, Id applicantId) {
    List<Triangulation_Data__c> records = [
        SELECT CKYC_Number__c
        FROM Triangulation_Data__c
        WHERE Loan_Application__c = :loanId
          AND Application_Applicant__c = :applicantId
          AND Source_Type__c = 'CKYC'
        LIMIT 1
    ];
    
    if (!records.isEmpty()) {
        return records[0].CKYC_Number__c;
    }
    return null;
}

    @AuraEnabled
    public static List<Triangulation_Data__c> getTriangulationDataRecord (String loanId, String applicantId){
        List<Triangulation_Data__c> existingRecords = [SELECT Id, CKYCID__c, CKYC_Transaction_Id__c,API_hit_count__c,CKYC_Number__c,CKYC_Doc_ID__c,CKYC_Doc_Type__c,CKYC_Reference_Id__c
            FROM Triangulation_Data__c WHERE Loan_Application__c = :loanId AND Application_Applicant__c = :applicantId AND Source_Type__c = 'CKYC' ORDER BY CreatedDate DESC LIMIT 1];
        return existingRecords.size()>0 ? existingRecords : new List<Triangulation_Data__c>();
    }

    
    @AuraEnabled
    public static List<SubStageWrapper> getLoginChecklistSubStageList(String loanId, String applicableStage) {
        List<SubStageWrapper> subStageList = new List<SubStageWrapper>();
        Set<String> addedSubStages = new Set<String>(); 
        // Fetch screens based on the selected applicable stage
        List<Screen_Field__c> screenDetails = [
            SELECT Id, Master_Screen_Name__c, Applicable_Login_Stage__c,Screen_Sequence__c
            FROM Screen_Field__c
            WHERE Form_Name__c = 'Login Checklist'
            AND Is_Screen_Active__c = TRUE
            AND Applicable_Login_Stage__c = :applicableStage
            ORDER BY Screen_Sequence__c ASC
        ];
        
        for (Screen_Field__c screen : screenDetails) {
            SubStageWrapper subWrap = new SubStageWrapper();
            if (screen.Master_Screen_Name__c!= null && !addedSubStages.contains(screen.Master_Screen_Name__c)) {
                subWrap.name = screen.Master_Screen_Name__c;
                subWrap.isCompleted =false; // Assuming this field tracks completion status
                subWrap.sequence = String.valueof(screen.Screen_Sequence__c);
                subStageList.add(subWrap);
                addedSubStages.add(screen.Master_Screen_Name__c);
            }
        }
        
        System.debug(subStageList);
        return subStageList;
    }
    
    @AuraEnabled
    public static List<SubStageWrapper> getSubStageListSubAccordian(String loanId, String applicableStage,String formName){
        try {
            List<SubStageWrapper> subStageList = new List<SubStageWrapper>();
            Set<String> addedSubStages = new Set<String>(); 

            // 🔹 Fetch HL-related info
            List<Product2> mainProd = [
                SELECT Id, Name 
                FROM Product2 
                WHERE Loan_Application__c = :loanId 
                AND RecordType.Name = 'Product' 
                AND Product_Type__c = 'Parent'
            ];

            Map<String, String> inputMapUtility = new Map<String, String>();
            Utility_V1.ProductWrapper isHLRelatedFinal = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
            Boolean isHlRelated = isHLRelatedFinal.isHLRelated;

            // 🔹 Base query for screen fields
            String query = 'SELECT Id, Master_Screen_Name__c, Applicable_For__c, Applicable_Login_Stage__c, ' +
                        'Screen_Sequence__c, Applicable_For_Products__c ' +
                        'FROM Screen_Field__c WHERE Is_Screen_Active__c = TRUE AND Form_Name__c = :formName ';

            if (formName != 'Bureau insights' && formName != 'Bureau Login Checklist') {
                query += ' AND Applicable_Login_Stage__c = :applicableStage';
            }
            query += ' ORDER BY Screen_Sequence__c ASC';

            List<Screen_Field__c> screenDetails = Database.query(query);
            System.debug('Query Executed: ' + query);

            // 🔹 Filter screen fields for HL users based on product applicability
            List<Screen_Field__c> screenFieldToReturn = new List<Screen_Field__c>();

            for (Screen_Field__c scf : screenDetails) {
                if (isHlRelated) {
                    System.debug('scf----'+scf);
                    if (!mainProd.isEmpty() && String.isNotBlank(scf.Applicable_For_Products__c)) {
                        List<String> applicableProdList = scf.Applicable_For_Products__c.split(',');
                        if (applicableProdList.contains(mainProd[0].Name)) {
                            screenFieldToReturn.add(scf);
                        }
                    }
                } else {
                    // Non-HL users get all screens as before
                    if(String.isBlank(scf.Applicable_For_Products__c)){
                         screenFieldToReturn.add(scf);
                    }
                   
                }
            }

            System.debug('Final Screen List Count: ' + screenFieldToReturn.size());

            // 🔹 Build SubStageWrapper list
            for (Screen_Field__c screen : screenFieldToReturn) {
                if (screen.Master_Screen_Name__c != null && !addedSubStages.contains(screen.Master_Screen_Name__c)) {
                    SubStageWrapper subWrap = new SubStageWrapper();
                    subWrap.name = screen.Master_Screen_Name__c;
                    subWrap.sequence = String.valueOf(screen.Screen_Sequence__c);
                    subWrap.isCompleted = false;
                    subWrap.applicableFor = screen.Applicable_For__c;

                    subStageList.add(subWrap);
                    addedSubStages.add(screen.Master_Screen_Name__c);
                }
            }

            System.debug('Final SubStageList: ' + subStageList);
            return subStageList;

        } catch (Exception e) {
            throw new AuraHandledException('Error in getSubStageListSubAccordian: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<ApplicantWrapper> getApplicantList(String loanId, String applicableStage,String formName) {
        try {
            //HL-Ishi-23-09
            Map<String,String> inputMapUtility = new  Map<String,String>();
            Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
            Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
            String labelValue = System.Label.HL_Eligible_Bureau;
            List<Screen_Field__c> screenFieldToReturn = new List<Screen_Field__c>();
            List<Opportunity> loanList = [Select Id, Product__c from Opportunity where Id =: loanId];
            List<Product2> prodList = new List<Product2>();
            if(!loanList.isEmpty()){
                prodList = [Select Id, Name from Product2 where Loan_Application__c =: loanId and RecordType.Name = 'Product' and Name =: loanList[0].Product__c limit 1];
            }
            System.debug('Label Value: ' + labelValue);
            //HL-Ishi-23-09
            
            Map<String,List<String>> objectToFieldsMap = new Map<String,List<String>>();
            Map<String,String> fieldApiTOLabelMap = new Map<String,String>();
            Map<String,List<SObject>> objectValuesMap = new Map<String,List<SObject>>();
            System.debug('formName -->'+formName);
            System.debug('applicableStage-->'+applicableStage);
            if(formName == null){
                formName = 'Loan Login Form';
            }
            if(formName.contains('\u2019')){
                formName = formName.replaceAll('\u2019','\'s');
            }
            if(applicableStage.contains('\u2019')){
                applicableStage = applicableStage.replaceAll('\u2019','\'s');
            }
            List<ApplicantWrapper> applicantWrapperList = new List<ApplicantWrapper>();
            
            // Fetch applicants for the given LoanId
            List<Application_Applicant__c> appList = [
                SELECT Id,IsForm60Uploaded__c,Applicant_Name__c,Customer_Profile__c,Is_Financial_applicant__c, Applicant_Type__c,Pan_OCR_Confirmed__c ,Aadhaar_Number__c,Aadhaar_Pincode__c,PAN_Number__c,Customer_Type__c,Consent_Status__c,Is_MNRL_Blacklisted__c,CKYC_ReferenceId__c
                FROM Application_Applicant__c
                WHERE Loan_Application__c = :loanId and Applicant_Type__c!='Builder' order by CreatedDate
            ];
            List<Screen_Field__c> screenDetails = new List<Screen_Field__c> ();
            if( applicableStage!='Applicant Other Details' && applicableStage!='Login Checklist'){
                System.debug('Inside first if>');
                screenDetails= [
                    SELECT Id, Master_Screen_Name__c, Applicable_Login_Stage__c, Screen_Sequence__c,Applicable_For__c,
                    Dependent_Field_Object__c,Dependent_Field__c,Dependent_Field_Value__c,Applicable_For_Products__c
                    FROM Screen_Field__c
                    
                    WHERE Is_Screen_Active__c = TRUE
                    AND Form_Name__c =: formName
                    AND Applicable_Login_Stage__c = :applicableStage
                    ORDER BY Screen_Sequence__c ASC
                ];
            }else if( applicableStage=='Login Checklist'){
                screenDetails= [
                    SELECT Id, Master_Screen_Name__c, Applicable_Login_Stage__c, Screen_Sequence__c,Applicable_For__c,
                    Dependent_Field_Object__c,Dependent_Field__c,Dependent_Field_Value__c,Applicable_For_Products__c
                    FROM Screen_Field__c
                    
                    WHERE Is_Screen_Active__c = TRUE
                    AND Form_Name__c =: formName
                    AND Applicable_Login_Stage__c = :applicableStage
                    // AND Master_Screen_Name__c IN ('Personal Information')
                    ORDER BY Screen_Sequence__c ASC
                ];
            }else{
                screenDetails= [
                    SELECT Id, Master_Screen_Name__c, Applicable_Login_Stage__c, Screen_Sequence__c,Applicable_For__c,
                    Dependent_Field_Object__c,Dependent_Field__c,Dependent_Field_Value__c,Applicable_For_Products__c
                    FROM Screen_Field__c
                    // WHERE Form_Name__c =:formName
                    WHERE Is_Screen_Active__c = TRUE
                    AND Form_Name__c =: formName
                    AND Applicable_Login_Stage__c = :applicableStage
                    AND Master_Screen_Name__c IN ('Applicant\'s Additional Information','Applicant\'s Address Information')
                    ORDER BY Screen_Sequence__c ASC
                ];
            }
            for(Screen_Field__c scf : screenDetails){
                //HL-ISHI-13-10
                if(isHlRelated){
                    if(!prodList.isEmpty()){
                        if(String.isNotBlank(scf.Applicable_For_Products__c)){
                            List<String> applicableProdList = scf.Applicable_For_Products__c.split(',');
                            if(applicableProdList.contains(prodList[0].Name)){
                                screenFieldToReturn.add(scf);
                            }
                        }
                    }
                    else{
                        screenFieldToReturn.add(scf);
                    }
                }
                else{
                    if(String.isBlank(scf.Applicable_For_Products__c)){
                         screenFieldToReturn.add(scf);
                    }
                   
                }
                //HL-ISHI-13-10
            }
            for(Screen_Field__c sc : screenFieldToReturn){
                // fieldApiTOLabelMap.put(sc.Dependent_Field_Object__c, sc.Dependent_Field__c);
                if(sc.Dependent_Field_Object__c != null){
                    if(objectToFieldsMap.containsKey(sc.Dependent_Field_Object__c)){
                        if(!objectToFieldsMap.get(sc.Dependent_Field_Object__c).contains(sc.Dependent_Field__c)){
                            objectToFieldsMap.get(sc.Dependent_Field_Object__c).add(sc.Dependent_Field__c);
                        }
                    }
                    else{
                        objectToFieldsMap.put(sc.Dependent_Field_Object__c, new List<String>{sc.Dependent_Field__c});
                    }
                }
            }
            List<Product2> mainProd = [SELECT id,Name FROM Product2 WHERE Loan_Application__c =:loanId AND RecordType.name = 'Product'];
            Map<String, Sobject> idToObjectMap = new Map<String, Sobject>();
            for(String str : objectToFieldsMap.keySet()){
                List<String> fieldApiNames = objectToFieldsMap.get(str);
                String query = 'Select Id ';
                for(String fields : fieldApiNames){
                    System.debug('fields'+fields);
                    query = query+', '+ fields;
                }
                System.debug('query===='+query);
                
                if(str == 'Loan_Application__c'){
                    query += ' FROM '+str +' where Id = \'' +loanId + '\'';
                }
                else if(str == 'Application_Applicant__c'){
                    query += ' FROM '+str +' where Loan_Application__c = \'' +loanId + '\'';
                }
                
                System.debug('query----'+query);
                
                List<SObject> sObjList = Database.query(query);
                if(sObjList.size() > 0){
                    for(Sobject s : sObjList){
                        idToObjectMap.put((String)s.get('Id'),s);
                    }
                }
            }
            System.debug('idToObjectMap=:'+idToObjectMap);
            for (Application_Applicant__c app : appList) {
                ApplicantWrapper iterapp = new ApplicantWrapper();
                iterapp.name = app.Applicant_Name__c + ' (' + app.Applicant_Type__c + ')';
                iterapp.sequence = appList.size();
                iterapp.type = app.Applicant_Type__c;
                iterapp.isMNRLBlacklisted = app.Is_MNRL_Blacklisted__c;
                iterapp.isForm60Uploaded = app.IsForm60Uploaded__c == 'Yes' ? true : false;
                iterapp.customerProfile = app.Customer_Profile__c;
                iterapp.isFinancialApplicant = app.Is_Financial_applicant__c;
                iterapp.isckycinitiated = String.isNotBlank(app.CKYC_ReferenceId__c);
                if( app.Applicant_Type__c!='Primary Applicant'){
                    iterapp.isRemovable = app.Consent_Status__c=='Accepted'? false:true;
                }
                iterapp.applicantId = app.Id;
                iterapp.isNonIndividual = app.Customer_Type__c == 'Non Individual'?true:false;
                List<SubStageWrapper> subStageList = new List<SubStageWrapper>();
                Set<String> addedSubStages = new Set<String>();
                for (Screen_Field__c screen : screenDetails) {
                    Boolean isApplicableScreen = false;
                    if(screen.Applicable_For__c=='Both' ||screen.Applicable_For__c==app.Customer_Type__c ){
                        if(screen.Dependent_Field_Object__c != null){
                            if(screen.Dependent_Field_Object__c == 'Application_Applicant__c'){
                                Sobject sobj = idToObjectMap.get(app.Id);
                                // System.debug('obj.get(screen.Dependent_Field__c)  '+sobj.get(screen.Dependent_Field__c) );
                                // System.debug('screen.Dependent_Field_Value__c '+screen.Dependent_Field_Value__c);


                                if(screen.Dependent_Field__c == 'Pan_Status__c'){
                                    if(sobj.get(screen.Dependent_Field__c) == null || sobj.get(screen.Dependent_Field__c) == screen.Dependent_Field_Value__c){
                                        isApplicableScreen = true;
                                    }
                                }
                               
                                else{
                                    if(screen.Dependent_Field__c == 'Consent_Status__c' && app.PAN_Number__c == null && app.IsForm60Uploaded__c == 'Yes'){
                                    System.debug('612-->'+app.PAN_Number__c);
                                        isApplicableScreen = false;
                                        System.debug('615-->'+app.IsForm60Uploaded__c);
                                    
                                    
                                    }
                                    else if(screen.Dependent_Field__c == 'Consent_Status__c' && app.PAN_Number__c != null){
                                        isApplicableScreen = app.Consent_Status__c == 'Accepted'? true : false;
                                    }
                                    else if(sobj.get(screen.Dependent_Field__c) != null && sobj.get(screen.Dependent_Field__c) == screen.Dependent_Field_Value__c){
                                        isApplicableScreen = true;
                                    }
                                }
                                
                            }
                        }
                        else{
                            isApplicableScreen = true;
                        }
                        
                        if (isApplicableScreen && screen.Master_Screen_Name__c != null && !addedSubStages.contains(screen.Master_Screen_Name__c)) {
                            if(app.PAN_Number__c != null || (app.IsForm60Uploaded__c =='Yes' && app.Aadhaar_Pincode__c != null )){
                                SubStageWrapper subWrap = new SubStageWrapper();
                                subWrap.name = screen.Master_Screen_Name__c;
                                subWrap.isCibil = false;
                                subWrap.isCrif = false;
                                subWrap.isCompleted = false;
                                subWrap.sequence = String.valueOf(screen.Screen_Sequence__c);
                                subWrap.isApplicantCmp = false;
                                subWrap.isConsent = false;
                                subWrap.isDeDupeScreen = false;
                                subWrap.isSwapApplicant = false;
                                subWrap.isBasicDetails = false;
                                subWrap.isPanValidation = true;
                                if(!isHlRelated){
                                subWrap.isBureau = true;
                                }
                                else if(isHlRelated ){
                                    if(labelValue =='Both'){
                                        subWrap.isCibil = true;
                                        subWrap.isCrif = true;
                                    }
                                    else if(labelValue =='Cibil'){
                                        subWrap.isCibil = true;
                                    }
                                    else if(labelValue =='Crif'){
                                        subWrap.isCrif = true;
                                    }
                                    
                                }
                                

                                subWrap.isDocument = false;
                                subWrap.isApplicantAdditionalInformation= false;
                                subWrap.isApplicantAddressInformation= false;
                                subWrap.isPersonalInformation = false;
                                subWrap.isAddressInformation = false;
                                subWrap.isEmploymentInformation = false;
                                subWrap.isCurrentAddressInformation= false;
                                subWrap.isPermanentAddressInformation = false;
                                subWrap.isCurrentEmploymentInformation = false;
                                subWrap.isAnnualIncomeInformation = false; 
                                subWrap.isNonIndividual = app.Customer_Type__c == 'Non Individual'?true:false;
                                if(screen.Master_Screen_Name__c == 'Bureau Insights'){
                                    if(!isHlRelated){
                                subStageList.add(subWrap);
                                addedSubStages.add(screen.Master_Screen_Name__c);
                            }
                                }
                                else if(screen.Master_Screen_Name__c == 'Cibil'){
                                    if(isHLRelated && (labelValue == 'Both' || labelValue == 'Cibil')){
                                        subStageList.add(subWrap);
                                        addedSubStages.add(screen.Master_Screen_Name__c);
                                    }
                                }
                                else if(screen.Master_Screen_Name__c == 'Crif'){
                                    if(isHLRelated && (labelValue == 'Both' || labelValue == 'Crif')){
                                        subStageList.add(subWrap);
                                        addedSubStages.add(screen.Master_Screen_Name__c);
                                    }
                                }
                                else{
                                    subStageList.add(subWrap);
                                    addedSubStages.add(screen.Master_Screen_Name__c);
                                }
                            }
                            else if(app.Aadhaar_Pincode__c == null && app.IsForm60Uploaded__c =='Yes' && screen.Master_Screen_Name__c == 'Aadhar Details'){
                                SubStageWrapper subWrap = new SubStageWrapper();
                                subWrap.name = 'Aadhar Details'; //screen.Master_Screen_Name__c;
                                subWrap.isCompleted = false;
                                subWrap.sequence = '2'; //String.valueOf(screen.Screen_Sequence__c);
                                subWrap.isApplicantCmp = false;
                                subWrap.isCibil = false;
                                subWrap.isCrif = false;
                                subWrap.isConsent = false;
                                subWrap.isDeDupeScreen = false;
                                subWrap.isSwapApplicant = false;
                                subWrap.isBasicDetails = false;
                                subWrap.isPanValidation = false;
                                subWrap.isBureau = false;
                                subWrap.isDocument = false;
                                subWrap.isApplicantAdditionalInformation= false;
                                subWrap.isApplicantAddressInformation= false;
                                subWrap.isPersonalInformation = false;
                                subWrap.isAddressInformation = false;
                                subWrap.isEmploymentInformation = false;
                                subWrap.isCurrentAddressInformation= false;
                                subWrap.isPermanentAddressInformation = false;
                                subWrap.isCurrentEmploymentInformation = false;
                                subWrap.isAnnualIncomeInformation = false; 
                                subWrap.isAadharDetails = true;
                                subWrap.isNonIndividual = app.Customer_Type__c == 'Non Individual'?true:false;
                                if(screen.Master_Screen_Name__c == 'Bureau Insights'){
                                    if(!isHlRelated){
                                subStageList.add(subWrap);
                                addedSubStages.add(screen.Master_Screen_Name__c);
                            }
                                }
                                else if(screen.Master_Screen_Name__c == 'Cibil'){
                                    if(isHLRelated && (labelValue == 'Both' || labelValue == 'Cibil')){
                                        subStageList.add(subWrap);
                                        addedSubStages.add(screen.Master_Screen_Name__c);
                                    }
                                }
                                else if(screen.Master_Screen_Name__c == 'Crif'){
                                    if(isHLRelated && (labelValue == 'Both' || labelValue == 'Crif')){
                                        subStageList.add(subWrap);
                                        addedSubStages.add(screen.Master_Screen_Name__c);
                                    }
                                }
                                else{
                                    subStageList.add(subWrap);
                                    addedSubStages.add(screen.Master_Screen_Name__c);
                                }
                            }
                            else{
                                system.debug('oli screen.Master_Screen_Name__c-----'+screen.Master_Screen_Name__c);
                                if(screen.Master_Screen_Name__c == 'PAN/Form 60 Details' || screen.Master_Screen_Name__c == 'C-KYC Details' ){
                                    SubStageWrapper subWrap = new SubStageWrapper();
                                    subWrap.name = screen.Master_Screen_Name__c;
                                    subWrap.isCompleted = false;
                                    subWrap.isCibil = false;
                                    subWrap.isCrif = false;
                                    subWrap.sequence = String.valueOf(screen.Screen_Sequence__c);
                                    if(app.Pan_OCR_Confirmed__c == false &&screen.Master_Screen_Name__c != 'PAN/Form 60 Details'){
                                        subWrap.disableAccordian= true;
                                    }
                                    else{
                                        subWrap.disableAccordian= false;
                                    }
                                    subWrap.isApplicantCmp = true;
                                    subWrap.isConsent = false;
                                    subWrap.isDeDupeScreen = false;
                                    subWrap.isSwapApplicant = false;
                                    subWrap.isBasicDetails = true;
                                    subWrap.isPanValidation = false;
                                    if(!isHlRelated){
                                    subWrap.isBureau = true;
                                    }
                                    else if(isHlRelated ){
                                        if(labelValue =='Both'){
                                            subWrap.isCibil = true;
                                            subWrap.isCrif = true;
                                        }
                                        else if(labelValue =='Cibil'){
                                            subWrap.isCibil = true;
                                        }
                                        else if(labelValue =='Crif'){
                                            subWrap.isCrif = true;
                                        }
                                        
                                    }
                                    subWrap.isDocument = false;
                                    subWrap.isApplicantAdditionalInformation= false;
                                    subWrap.isApplicantAddressInformation= false;
                                    subWrap.isPersonalInformation = false;
                                    subWrap.isAddressInformation = false;
                                    subWrap.isEmploymentInformation = false;
                                    subWrap.isCurrentAddressInformation= false;
                                    subWrap.isPermanentAddressInformation = false;
                                    subWrap.isCurrentEmploymentInformation = false;
                                    subWrap.isAnnualIncomeInformation = false; 
                                    subWrap.isAadharDetails = false;
                                    subWrap.isEmploymentDetails = true;
                                    if(screen.Master_Screen_Name__c == 'Bureau Insights'){
                                        if(!isHlRelated){
                                    subStageList.add(subWrap);
                                    addedSubStages.add(screen.Master_Screen_Name__c);
                                        }
                                    }
                                    else if(screen.Master_Screen_Name__c == 'Cibil'){
                                        if(isHLRelated && (labelValue == 'Both' || labelValue == 'Cibil')){
                                            subStageList.add(subWrap);
                                            addedSubStages.add(screen.Master_Screen_Name__c);
                                        }
                                    }
                                    else if(screen.Master_Screen_Name__c == 'Crif'){
                                        if(isHLRelated && (labelValue == 'Both' || labelValue == 'Crif')){
                                            subStageList.add(subWrap);
                                            addedSubStages.add(screen.Master_Screen_Name__c);
                                        }
                                    }
                                    else{
                                        subStageList.add(subWrap);
                                        addedSubStages.add(screen.Master_Screen_Name__c);
                                    }
                                }
                            }
                        }
                        
                    }
                    
                    
                }
                if (iterapp.stages == null) {
                    iterapp.stages = new List<SubStageWrapper>();
                }
                iterapp.stages = subStageList;
                applicantWrapperList.add(iterapp);
                
            }
            System.debug('applicantWrapperList==>'+applicantWrapperList);
            return applicantWrapperList;
            
        } catch (Exception e) {
            System.debug('Error at line number>'+e.getLineNumber()+' message-->'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<ApplicantWrapper> getPrimaryApplicantList(String loanId, String applicableStage) {
        try {
            List<ApplicantWrapper> applicantWrapperList = new List<ApplicantWrapper>();
            
            // Fetch applicants for the given LoanId
            List<Application_Applicant__c> appList = [
                SELECT Id, Applicant_Name__c, Applicant_Type__c,Pan_OCR_Confirmed__c,IsForm60Uploaded__c 
                FROM Application_Applicant__c 
                WHERE Loan_Application__c = :loanId  AND Applicant_Type__c = 'Primary Applicant'
            ];
            List<Screen_Field__c> screenDetails = [
                SELECT Id, Master_Screen_Name__c, Applicable_Login_Stage__c, Screen_Sequence__c
                FROM Screen_Field__c
                WHERE Form_Name__c = 'Loan Login Form'
                AND Is_Screen_Active__c = TRUE
                AND Applicable_Login_Stage__c = :applicableStage
                ORDER BY Screen_Sequence__c ASC
            ];
            
            for (Application_Applicant__c app : appList) {
                ApplicantWrapper iterapp = new ApplicantWrapper();
                iterapp.name = app.Applicant_Name__c;
                iterapp.sequence = appList.size();
                iterapp.type = app.Applicant_Type__c;
                iterapp.applicantId = app.Id;
                
                
                // Fetch sub-stages for this applicant based on the given stage
                List<SubStageWrapper> subStageList = new List<SubStageWrapper>();
                Set<String> addedSubStages = new Set<String>();
                
                
                
                for (Screen_Field__c screen : screenDetails) {
                    if (screen.Master_Screen_Name__c != null && !addedSubStages.contains(screen.Master_Screen_Name__c)) {
                        SubStageWrapper subWrap = new SubStageWrapper();
                        subWrap.name = screen.Master_Screen_Name__c;
                        subWrap.isCompleted = false;
                        subWrap.sequence = String.valueOf(screen.Screen_Sequence__c);
                        if(app.Pan_OCR_Confirmed__c == false &&screen.Master_Screen_Name__c != 'PAN/Form 60 Details'){
                            subWrap.disableAccordian= true;
                        }
                        else{
                            subWrap.disableAccordian= false;
                        }
                        subWrap.isApplicantCmp = true;
                        subWrap.isConsent = false;
                        subWrap.isDeDupeScreen = false;
                        subWrap.isSwapApplicant = false;
                        subWrap.isBasicDetails = false;
                        subWrap.isPanValidation = false;
                        subWrap.isDocument = false;
                        String applicantScreenName = 'PAN/Form 60 Details';
                        String applicantScreenNameBasicDetail = 'Applicant\'s Basic Information';
                        subStageList.add(subWrap);
                        addedSubStages.add(screen.Master_Screen_Name__c);
                    }
                }
                if (iterapp.stages == null) {
                    iterapp.stages = new List<SubStageWrapper>();
                }
                iterapp.stages = subStageList;
                applicantWrapperList.add(iterapp);
                
            }
            
            return applicantWrapperList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static List<Negative_dedupe__c> getDedupeList(String loanId) {
      system.debug('loanId>>>>'+loanId);
        
        List<Negative_dedupe__c> negativeDedupeList= [SELECT id,First_Name__c,First_Name_Match__c,DOB__c,DOB_Match__c,Middle_Name__c,Middle_Name_Match__c,Match_found__c,Last_Name__c,Last_Name_Match__c,Address__c,PAN__c,Address_Match__c,Pan_Match__c,Application_Applicant__c,Application_Applicant__r.Negative_list_dispostion__c,Mobile_Number__c, Mobile_Number_Match__c, CIF_Id__c,Application_Applicant__r.Negative_List_Comment__c,Rule__c,Application_Applicant__r.Name
                                                      from Negative_dedupe__c Where Id = 'a0pdN000000uuXNQAY'];/* Negative_list_dispostion__c =: loanId And Application_Applicant__c != null AND (First_Name_Match__c >= 70 OR
                                                                                                                                                                    Middle_Name_Match__c >= 70 OR
                                                                                                                                                                    Last_Name_Match__c >= 70 OR
                                                                                                                                                                    DOB_Match__c >= 70 OR
                                                                                                                                                                    Address_Match__c >= 70 OR
                                                                                                                                                                    Pan_Match__c >= 70 OR
                                                                                                                                                                    Mobile_Number_Match__c >= 70
          )];
        system.debug('negativeDedupeList>>>'+negativeDedupeList);
        system.debug('negativeDedupeList.size>>>'+negativeDedupeList.size());*/
        return negativeDedupeList;
    }
    @AuraEnabled
    public static void updateNegativeDedupeRecords(Map<String, Map<String, String>> recordsToUpdate) {
        System.debug('recordsToUpdate-->'+recordsToUpdate);
        try {
            List<Negative_dedupe__c> recordsList = new List<Negative_dedupe__c>();
            
            
            for (String recordId : recordsToUpdate.keySet()) {
                Negative_dedupe__c dedupeRecord = new Negative_dedupe__c(
                    Id = recordId,
                    Match_Found__c = recordsToUpdate.get(recordId).get('Match_Found__c')
                );
                recordsList.add(dedupeRecord);
            }
            System.debug('recordsList: ' + recordsList);
            update recordsList;
        } catch (Exception e) {
            System.debug('Error updating records: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static Map<String, String> saveCustomerDetails(Map<String, Object> uploadParam) {
        try {
            Map<String, String> response = new Map<String, String>();
            
            // Extract parameters
            String base64 = (String) uploadParam.get('base64');
            String fileName = (String) uploadParam.get('filename');
            String applicantId = (String) uploadParam.get('applicantId');
            String loanId = (String) uploadParam.get('loanId');
            String userName = (String) uploadParam.get('panName');
            String dob = (String) uploadParam.get('dob');
            String fathersName = (String) uploadParam.get('fatherName');
            String panNumber= (String) uploadParam.get('panNumber');
            Boolean isCoApplicant = (Boolean)uploadParam.get('isCoApplicant');
            String constitution = (String) uploadParam.get('constitution');
            String customerType = (String) uploadParam.get('customerType');
            String applicantType = (String) uploadParam.get('applicantType');
            String preferredLanguage = (String) uploadParam.get('preferredLanguage');
            Document_Details__c dd;
            Account customer  = new Account();
            String contentDocumentId;
            Application_Applicant__c applicant = new Application_Applicant__c ();
            // Get Document Master
            List<Account > acc  = [Select id, Applicant_Identifier__c,Duplicate_Customer_Source__c,Match_Response__c,Dedupe_Found_in__c from Account where Pan_Number__c != null AND  Pan_Number__c= :panNumber AND Customer_Type__c=:customerType and Is_Active__c=true];
            /*if(isCoApplicant){
                if (panNumber != null && panNumber.length() >= 4) {
                    String fourthChar = panNumber.substring(3, 4);    
                    if (fourthChar.equalsIgnoreCase('P')) {
    
                    } else {
                        response.put('error', 'Non-Individual');
                        return response;
                    }                            
                }
            }*/
            List<Opportunity> opp = [Select id,Product__c from Opportunity where id=:loanId LIMIT 1];
            List<Document_Master__c> docMaster = new  List<Document_Master__c>();
            
                
                docMaster=[
                    SELECT Id, Name,Document_Type__c,Applicable_Product__c
                    FROM Document_Master__c 
                    WHERE Requirement_At__c = 'Applicant Level' 
                    AND Name = 'PAN' AND Document_Type__c ='POI' AND Stage__c ='Sales Login'
                    AND Is_Active__c = true 
                    LIMIT 1
                ];
            
            Document_Master__c docMasterTemp= new Document_Master__c();
            for(Document_Master__c dm : docMaster){
                if(dm.Applicable_Product__c !=null){
                    List<String> prodList = dm.Applicable_Product__c.split(';');
                    if(prodList.contains(opp[0].Product__c)){
                        docMasterTemp = dm;
                        break;
                    }
                }
            }
            
            
            if (docMaster.isEmpty()) {
                // throw new AuraHandledException('No active Document Master found for PAN.');
            }
            List<Document_Details__c> docDet = [
                SELECT Id, Applicant__c 
                FROM Document_Details__c 
                WHERE Document_Master__c =: docMaster[0].id
                AND Applicant__c =:applicantId
                AND Loan_Application__c =:loanId
                AND Active__c=true 
                LIMIT 1
            ];
            
            
            // Insert ContentVersion
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64);
            cv.IsMajorVersion = true;
            insert cv;
            ContentVersion cvRec = [
                SELECT ContentDocumentId, FileType 
                FROM ContentVersion 
                WHERE Id = :cv.Id 
                LIMIT 1
            ];
            contentDocumentId = cvRec.ContentDocumentId;
            applicant.PAN_Number__c = panNumber;
            // if (panNumber != null && panNumber.length() >= 4) {
            //     String fourthChar = panNumber.substring(3, 4);
            //     if (fourthChar.equalsIgnoreCase('P')) {
            //         applicant.Customer_Type__c = 'Individual';
            //         applicant.DOB__c =  Date.valueOf(dob);
            //     } else {
            //         applicant.Customer_Type__c = 'Non Individual';
            //         applicant.Name_of_Organization__c = userName;
            //         applicant.DOI__c = Date.valueof(dob);
            //     }
            // }

            if (panNumber != null && panNumber.length() >= 4) {
                String fourthChar = panNumber.substring(3, 4);
                
                if (dob != null && dob.contains('/')) {
                    List<String> dateParts = dob.split('/'); // Splitting "14/07/1966" → ["14", "07", "1966"]
                    
                    if (dateParts.size() == 3) {
                        String formattedDate = dateParts[2] + '-' + dateParts[1] + '-' + dateParts[0]; // "1966-07-14"
                        
                        try {
                            // Date parsedDate = Date.parse(formattedDate);
                            Date parsedDate = Date.newInstance(
                                Integer.valueOf(dateParts[2]), // Year
                                Integer.valueOf(dateParts[1]), // Month
                                Integer.valueOf(dateParts[0])  // Day
                            );
                            // Date parsedDate = Date.valueOf(formattedDate); // Convert to Date
                            
                            if (fourthChar.equalsIgnoreCase('P')) {
                                if(constitution == 'Proprietorship' && customerType == 'Non Individual'){
                                    applicant.Customer_Type__c = 'Non Individual';
                                     customer.Customer_Type__c = 'Non Individual';
                                      customer.Date_of_Birth__c = parsedDate;
                                    applicant.DOI__c =  parsedDate;
                                    applicant.Name_of_Organization__c = userName;
                                    applicant.Business_Entity_Name__c = userName;
                                    applicant.Customer_Profile__c = 'SENP';
                                }else {
                                    applicant.Customer_Type__c = 'Individual';
                                    applicant.DOB__c =  parsedDate;
                                    applicant.PAN_DOB__c = parsedDate;
                                    customer.Customer_Type__c = 'Individual';
                                    customer.Date_of_Birth__c = parsedDate;
                                    applicant.Customer_Profile__c = 'SEP';
                                }
                            } else {
                                applicant.Customer_Type__c = 'Non Individual';
                                applicant.Name_of_Organization__c = userName;
                                applicant.Business_Entity_Name__c = userName;
                                customer.Customer_Type__c = 'Non Individual';
                                customer.Date_of_Birth__c = parsedDate;
                                applicant.DOI__c = parsedDate;
                                applicant.Customer_Profile__c = 'SENP';
                            }
                            
                            System.debug('Parsed Date: ' + parsedDate);
                        } catch (Exception e) {
                            System.debug('Error parsing date: ' + e.getMessage());
                        }
                    }
                }else if (dob != null && dob.contains('-')) {
                    List<String> dateParts = dob.split('-'); // Splitting "14/07/1966" → ["14", "07", "1966"]
                    
                    if (dateParts.size() == 3) {
                        String formattedDate;
                        if(dateParts[0].length() == 4){
                            formattedDate = dateParts[0] + '-' + dateParts[1] + '-' + dateParts[2]; // "1966-07-14"  
                        }
                        else if(dateParts[0].length() == 2){
                            formattedDate = dateParts[2] + '-' + dateParts[1] + '-' + dateParts[0];
                        }
                        //String formattedDate = dateParts[0] + '-' + dateParts[1] + '-' + dateParts[2]; // "1966-07-14"                       
                        
                        try {
                            // Date parsedDate = Date.parse(formattedDate);
                            // Date parsedDate = Date.newInstance(
                            //     Integer.valueOf(dateParts[2]), // Year
                            //     Integer.valueOf(dateParts[1]), // Month
                            //     Integer.valueOf(dateParts[0])  // Day
                            // );
                            Date parsedDate = Date.valueOf(formattedDate); // Convert to Date
                            
                            if (fourthChar.equalsIgnoreCase('P')) {
                                if(constitution == 'Proprietorship' && customerType == 'Non Individual'){
                                    applicant.Customer_Type__c = 'Non Individual';
                                    customer.Customer_Type__c = 'Non Individual';
                                    customer.Date_of_Birth__c = parsedDate;
                                    // applicant.DOI__c =  Date.valueOf(dob);
                                    applicant.DOI__c =  parsedDate;
                                    applicant.Name_of_Organization__c = userName;
                                    applicant.Business_Entity_Name__c = userName;
                                    applicant.Customer_Profile__c = 'SENP';
                                }else {
                                    applicant.Customer_Type__c = 'Individual';
                                     customer.Customer_Type__c = 'Individual';
                                    customer.Date_of_Birth__c = parsedDate;
                                    // applicant.DOB__c =  Date.valueOf(dob);
                                    applicant.DOB__c = parsedDate;
                                    applicant.PAN_DOB__c = parsedDate;
                                    //applicant.Customer_Profile__c = 'SEP';
                                }
                            } else {
                                applicant.Customer_Type__c = 'Non Individual';
                                  customer.Customer_Type__c = 'Non Individual';
                                applicant.Name_of_Organization__c = userName;
                                applicant.Business_Entity_Name__c = userName;
                                 customer.Date_of_Birth__c = parsedDate;
                                applicant.DOI__c = parsedDate;
                                applicant.Customer_Profile__c = 'SENP';
                            }
                            
                            System.debug('Parsed Date: ' + parsedDate);
                        } catch (Exception e) {
                            System.debug('Error parsing date: ' + e.getMessage());
                        }
                    }
                }
            }
            

            applicant.Pan_Name__c = userName;
            //applicant.Father_s_First_Name__c = fatherName.split(' ')[0];
            applicant.Loan_Application__c = loanId;
            applicant.Preferred_Language__c = preferredLanguage != null ? preferredLanguage : 'English';
            System.debug('applicantname--+'+userName.split(' ')[0]);
            applicant.Pan_OCR_Confirmed__c = Boolean.valueof(uploadParam.get('panOCRConfirmed'));
            applicant.Sector__c = constitution;
            List<String> nameParts = userName.trim().split(' ');
            
            applicant.First_Name__c = nameParts[0];
           
            if(nameParts.size()>3){
                applicant.First_Name__c = nameParts[0];
                applicant.Middle_Name__c = nameParts[1];
                applicant.Last_Name__c ='';
                for(Integer i=2; i<nameParts.size();i++){
                    applicant.Last_Name__c+= ' '+nameParts[i];
                }
            }
            else if (nameParts.size() == 3) {
                applicant.Middle_Name__c = nameParts[1];
                applicant.Last_Name__c = nameParts[2];
            } else if (nameParts.size() == 2) {
                applicant.Last_Name__c = nameParts[1];
                 applicant.Middle_Name__c = null;
            } else {
                // applicant.Last_Name__c = applicant.First_Name__c;
                // applicant.Middle_Name__c = null;
            }
                if (fathersName != null && fathersName.trim() != '') {
                List<String> fatherNameParts = fathersName.trim().split(' ');
                Integer nameSize = fatherNameParts.size();

                applicant.Father_s_First_Name__c = fatherNameParts[0];
                applicant.Pan_Father_s_Name__c = fathersName;
                if (nameSize == 2) {
                    applicant.Father_s_Middle_Name__c = null;
                    applicant.Father_s_Last_Name__c = fatherNameParts[1];
                } else if (nameSize == 3) {
                    applicant.Father_s_Middle_Name__c = fatherNameParts[1];
                    applicant.Father_s_Last_Name__c = fatherNameParts[2];
                } else if (nameSize >= 4) {
                    applicant.Father_s_Middle_Name__c = fatherNameParts[1];
                    List<String> lastNameParts = new List<String>();
                    for (Integer i = 2; i < nameSize; i++) {
                        lastNameParts.add(fatherNameParts[i]);
                    }
                    applicant.Father_s_Last_Name__c = String.join(lastNameParts, ' ');
                } else {
                    applicant.Father_s_Middle_Name__c = null;
                    applicant.Father_s_Last_Name__c = null;
                }
            }

            
            if(applicantId==null){
                if(acc.size()>0){
                   customer.id = acc[0].id;
                   customer.Match_Response__c ='PAN';
                    customer.Dedupe_Found_in__c='saveCustomerDetails-New';
                }
                else{
                    customer.Name = userName;
                    customer.Pan_Number__c = panNumber;
                }
               
                Id customerRecordTypeId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer').getRecordTypeId();
                customer.RecordTypeId = customerRecordTypeId;
                
                upsert customer;
                applicant.Applicant_Type__c = applicantType != null ? applicantType : 'Co Applicant';
                applicant.Customer__c = customer.id;
                
                insert applicant;
                applicantId= applicant.id;
                
            }
            else{
                String custId = [Select id,Customer__c from Application_Applicant__c where id =:applicantId limit 1].Customer__c;
                List<Account> accToUpdate = new List<Account>();
                if(custId!=null){
                    customer.id = custId; 
                    System.debug('custId'+custId);
                    System.debug('acc'+acc);
                    if(acc.size()>0 && acc[0].Id != custId){
                        if(acc[0].Applicant_Identifier__c!=null){
                            customer.Applicant_Identifier__c=acc[0].Applicant_Identifier__c+','+applicantId;
                        }
                        else{
                            customer.Applicant_Identifier__c=applicantId;
        
                        }
                        customer.Duplicate_Customer_Source__c ='Salesforce';
                        customer.Match_Response__c ='Pan';
                         customer.Dedupe_Found_in__c='saveCustomerDetails-New';
                        customer.id = acc[0].id;
                        response.put('accToDelete', custId);
                        Account cd =  new Account();
                        cd.id = custId;
                        cd.Is_Active__c = false;
                        accToUpdate.add(cd);
                        // delete cd;
                    }
                    else{
                        customer.PAN_Number__c  = panNumber;
                    }
                }
                else{
                    customer.Name = userName;
                    customer.PAN_Number__c  = panNumber;
                }
                
                upsert customer;
                applicant.Customer__c= customer.id;
                applicant.Id = applicantId;
                Upsert applicant;
               
              
                
              
                //applicant.Applicant_Type__c ='Co Applicant';
                Upsert applicant;
                if(accToUpdate.size()>0){
                    Update accToUpdate;
                }
            }
            
            dd = new Document_Details__c();
            dd.Content_Document_Id__c = contentDocumentId;
            dd.Loan_Application__c = loanId;
            dd.Is_Sales_Manual_Document__c= true;
            dd.Applicant__c = applicantId;
            if(docMaster.size()>0){
                dd.Document_Master__c = docMaster[0].Id;
                dd.Document_Details__c= docMaster[0].Document_Type__c;
            }
            dd.Name = 'PAN';
            dd.Requirement_Level__c = 'Applicant Level';
            dd.Consider_for_Loan_Application__c= true;
            if(docDet.size()>0){
                dd.id =docDet[0].id;
            }
            dd.Status__c = 'Uploaded';
            upsert dd;
            
            
            // Create ContentDocumentLink to associate document with Loan or Applicant
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = (applicantId != null) ? applicantId : dd.Id; // Associate with Applicant or Document Details
            cdl.ContentDocumentId = contentDocumentId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;
            
            response.put('ContentDocumentId', contentDocumentId);
            response.put('DocumentDetailId', dd.Id);
            response.put('applicantId', applicantId);
    
            
            List<Triangulation_Data__c> triangulationDatas = [SELECT Id, Loan_Application__c, Application_Applicant__c, Pan__c, Name__c, Father__c, 
                                                              Date_Of_Birth__c FROM Triangulation_Data__c WHERE Loan_Application__c =: loanid 
                                                              AND Application_Applicant__c =: applicantId AND Source_Type__c = 'Confirmed' AND Document_Type__c = 'PAN'];
            if(!triangulationDatas.isEmpty()) {
                triangulationDatas[0].Pan__c = panNumber;
                triangulationDatas[0].Name__c = userName;
                triangulationDatas[0].Father__c = fathersName;
                triangulationDatas[0].Date_Of_Birth__c = dob;
                update triangulationDatas;
            } else {
                Triangulation_Data__c triangulationData = new Triangulation_Data__c();
                triangulationData.Pan__c = panNumber;
                triangulationData.Name__c = userName;
                triangulationData.Father__c = fathersName;
                triangulationData.Date_Of_Birth__c = dob;
                // parameter setting
                triangulationData.Application_Applicant__c = applicantId;
                triangulationData.Loan_Application__c = loanid;
                triangulationData.Source_Type__c = 'Manual';
                triangulationData.Document_Type__c = 'PAN';
                insert triangulationData;
            }
            System.debug('response-->'+response);
            return response;
            
        } 
        catch (Exception e) {
            throw new AuraHandledException('Error uploading file: ' + e.getMessage());
        }
    }  
    
    @AuraEnabled
    public static ContentWrapper createContentVersion(String base64Data,String fileName){
        try {
            ContentWrapper conWrap = new ContentWrapper();
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.IsMajorVersion = true;
            insert cv;
            conWrap.contentVerId = cv.Id;
            
            // Fetch ContentDocumentId from newly inserted ContentVersion
            ContentVersion cvRec = [
                SELECT ContentDocumentId, FileType 
                FROM ContentVersion 
                WHERE Id = :cv.Id 
                LIMIT 1
            ];
            String contentDocId = cvRec.ContentDocumentId;
            conWrap.contentDocId = contentDocId;
            
            return conWrap;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean deleteAadhaarDetails(Map<String, String> inputMap){
        try {
            String applicantId = inputMap.get('applicantId');
            String loanId = inputMap.get('loanId');
            Application_Applicant__c app = [SELECT Id, Aadhaar_Number__c, Aadhaar_Pincode__c, Aadhaar_Address__c,Aadhaar_Back_OCR_Confirmed__c,Aadhaar_City_Town__c,Aadhaar_DOB__c,Aadhaar_Front_OCR_Confirmed__c,
            Aadhaar_Gender__c,Aadhaar_KYC_Verified__c,Aadhaar_First_Name__c,Aadhaar_Middle_Name__c,Aadhaar_Last_Name__c,Aadhaar_Number_Masked__c,Masked_Aadhar_Number__c FROM Application_Applicant__c WHERE Id =: applicantId AND Loan_Application__c =:loanId LIMIT 1];
            
            app.Aadhaar_Number__c = null;
            app.Aadhaar_Pincode__c = null;
            app.Aadhaar_Address__c = null;
            app.Aadhaar_Back_OCR_Confirmed__c = false;
            app.Aadhaar_City_Town__c = null;
            app.Aadhaar_DOB__c = null;
            app.Aadhaar_Front_OCR_Confirmed__c = false;
            app.Aadhaar_Gender__c = null;
            app.Aadhaar_KYC_Verified__c = false;
            app.Aadhaar_First_Name__c = null;
            app.Aadhaar_Middle_Name__c = null;
            app.Aadhaar_Last_Name__c = null;
            app.Aadhaar_Number_Masked__c = null;
            app.Masked_Aadhar_Number__c = null;
            update app;

            List<Document_Details__c> docDet = [SELECT Id, Content_Document_Id__c FROM Document_Details__c WHERE Applicant__c =:applicantId AND Loan_Application__c =:loanId AND Document_Name__c IN ('AADHAAR FRONT','AADHAAR BACK') ];
            List<String> contentDocId = new List<String>();
            for(Document_Details__c dd : docDet){
                if(dd.Content_Document_Id__c != null){
                    contentDocId.add(dd.Content_Document_Id__c);
                }
            }
            if(docDet.size()>0){
                delete docDet;
            }
            List<ContentDocument> contentDocs = [SELECT Id FROM ContentDocument WHERE Id IN :contentDocId];
            if(contentDocs.size()>0){
                delete contentDocs;
            }
            List<Applicant_Address__c> aadhaarAddresses = [ SELECT Id FROM Applicant_Address__c WHERE Applicant__c = :applicantId AND Loan_Application__c = :loanId AND Address_Source__c = 'Aadhaar' ];
            if (!aadhaarAddresses.isEmpty()) {
                delete aadhaarAddresses;
            }
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class ContentWrapper{
        @AuraEnabled public String contentDocId;
        @AuraEnabled public String contentVerId;
    }
    // @AuraEnabled
    // public static void saveExistingCustomerDetails(String loanId, String customerDemographicDetails,String customerId, String totalResp) {
    //     try {
    //         // Parse totalResp JSON into a strongly-typed object
    //         Map<String, Object> totalRespMap = (Map<String, Object>) JSON.deserializeUntyped(totalResp);
    //         List<Application_Applicant__c> appList  = new  List<Application_Applicant__c>();
    //         Account accountDet = new Account();
    //         List<Account> acc  = [Select id, Customer_LMS_Id__c from Account where Customer_LMS_Id__c=:customerId];
    //         if(acc.size()>0){
    //             appList = [Select Id,Customer__c from Application_Applicant__c where Loan_Application__c=:loanId and Customer__c=:acc[0].Id];
    //         }
    //         // Extracting personalInfo from totalRespMap
    //         Map<String, Object> personalInfo = (Map<String, Object>) totalRespMap.get('personalInfo');
    //         List<Object> phones = (List<Object>) totalRespMap.get('phones');
    //         List<Object> addresses = (List<Object>) totalRespMap.get('addresses');
    
    //         Application_Applicant__c apDet = new Application_Applicant__c();
    //         if (customerId != null) {
    //             apDet.Id = appList[0].id;
    
    //         }
    //         else{
    
    //             accountDet.Name = (String) personalInfo.get('firstName') + ' ' + (String) personalInfo.get('lastName');
    //             insert accountDet;
    
    //         }
    
    //         // Extract personal details
    //         apDet.First_Name__c = (String) personalInfo.get('firstName');   
    //         apDet.Last_Name__c = (String) personalInfo.get('lastName');
    //         apDet.Mobile_Number__c = (String) ((Map<String, Object>) phones[0]).get('phoneNumber');
    //         apDet.Loan_Application__c = loanId;
    //         apDet.Customer__c = appList[0].Customer__c;
    //         apDet.Customer_Tagged_From_Dedupe__c =  true;
    //         // Convert date string to Date format
    //         String inputDate = String.valueOf(personalInfo.get('dateofBirth'));
    //         Date parsedDate = Date.newInstance(
    //             Integer.valueOf(inputDate.substring(0, 4)), 
    //             Integer.valueOf(inputDate.substring(5, 7)), 
    //             Integer.valueOf(inputDate.substring(8, 10))
    //         ); 
    //         apDet.DOB__c = parsedDate;
    
    //         // Assign gender
    //         String gender = (String) personalInfo.get('gender');
    //         if (gender == 'M') {
    //             apDet.Gender__c = 'Male';
    //         } else if (gender == 'F') {
    //             apDet.Gender__c = 'Female';
    //         } else {
    //             apDet.Gender__c = 'Female'; // Default
    //         }
    
    //         upsert apDet;
    //         Applicant_Address__c addr = new Applicant_Address__c();
    //         Customer_Address__c newCustomerAddress = new Customer_Address__c();
    //         List<Applicant_Address__c> appAddresses = [Select id, Customer_Address__c,Address_Type__c from Applicant_Address__c where Applicant__c =:apDet.Id and Address_Type__c = 'Permanent'];
    //         if(appAddresses.size()>0){
    //             addr.id = appAddresses[0].id;
    //             newCustomerAddress.id = appAddresses[0].Customer_Address__c;
    //         }
    //         else{
    //             // Insert Customer Address
    
    //             newCustomerAddress.Customer__c = appList[0].Customer__c; // Ensure you have the right reference
    //             newCustomerAddress.Address_Type__c = 'Permanent';
    
    
    //         }
    
    //         upsert   newCustomerAddress;
    
    //         // Insert Applicant Address
    
    //         addr.Loan_Application__c = loanId;
    //         addr.Applicant__c = apDet.Id;
    //         addr.Address_Type__c = 'Permanent';
    
    //         // Extract address details
    //         Map<String, Object> addressDetails = (Map<String, Object>) addresses[0];
    //         addr.Building_Street_Name__c = (String) addressDetails.get('buildingNo');
    //         addr.Post_Office_Name__c = (String) addressDetails.get('poBox');
    //         addr.Customer_Address__c = newCustomerAddress.Id;
    
    //         upsert addr;
    
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }
    public class ActionListWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public Boolean completed;
        @AuraEnabled public Boolean isAllComplete;
        @AuraEnabled public Boolean isDisabled;
        
    }
    public class SubStageWrapper {
        @AuraEnabled public String name;
        @AuraEnabled public Boolean isCompleted;
        @AuraEnabled public String sequence;
         @AuraEnabled public String applicableFor;
        @AuraEnabled public Boolean isApplicantCmp;
        @AuraEnabled public Boolean isConsent;
        @AuraEnabled public Boolean isDeDupeScreen;
        @AuraEnabled public Boolean isBasicDetails;
        @AuraEnabled public Boolean isApplicantCmpActive;
        @AuraEnabled public Boolean isConsentActive;
        @AuraEnabled public Boolean isDeDupeScreenActive;
        @AuraEnabled public Boolean isBasicDetailsActive;
        @AuraEnabled public Boolean isSwapApplicant;
        @AuraEnabled public Boolean disableAccordian;
        @AuraEnabled public Boolean isPanValidation;
        @AuraEnabled public Boolean isDocument;
        @AuraEnabled public Boolean isBureau;
        @AuraEnabled public Boolean isApplicantAdditionalInformation;
        @AuraEnabled public Boolean isApplicantAddressInformation;
        @AuraEnabled public Boolean isPersonalInformation;
        @AuraEnabled public Boolean isAddressInformation;
        @AuraEnabled public Boolean isEmploymentInformation; 
        @AuraEnabled public Boolean isCurrentAddressInformation;
        @AuraEnabled public Boolean isPermanentAddressInformation;
        @AuraEnabled public Boolean isCurrentEmploymentInformation;
        @AuraEnabled public Boolean isAnnualIncomeInformation;     
        @AuraEnabled public Boolean isNonIndividual;   
        @AuraEnabled public Boolean isAadharDetails;  
        @AuraEnabled public Boolean isEmploymentDetails;
        //HL-Ishi-23/09
        @AuraEnabled public Boolean isCibil;
        @AuraEnabled public Boolean isCrif;  
        //HL-Ishi-23/09
    }
    public class ApplicantWrapper {
        @AuraEnabled public String name;
        @AuraEnabled public String type;
        @AuraEnabled public Integer sequence;
         @AuraEnabled public String applicableFor;
        @AuraEnabled public String applicantId;
        @AuraEnabled public List <SubStageWrapper> stages;
        @AuraEnabled public String panNumber;
        @AuraEnabled public String panName;
        @AuraEnabled public String fathersName;
        @AuraEnabled public String dobORDoi;
        @AuraEnabled public boolean isOCRConfirmed;
        @AuraEnabled public String contentDocumentID;
        @AuraEnabled public Boolean reHitDeDupe;
        @AuraEnabled public Boolean isSwapApplicant;
        @AuraEnabled public Boolean disbalePAN;
        @AuraEnabled public Boolean isNonIndividual;
        @AuraEnabled public String customerType;
        @AuraEnabled public String selectedconstitution;
        @AuraEnabled public Boolean isRemovable;
        @AuraEnabled public String leadName;
        @AuraEnabled public String applicantType;
        @AuraEnabled public String aadharNumber;
        @AuraEnabled public Boolean isForm60Uploaded;
        @AuraEnabled public String formSixtyFileCv;
        @AuraEnabled public String formSixtyFileCd;
        @AuraEnabled public String aadharPinCode;
        @AuraEnabled public String aadharAddress;
        @AuraEnabled public String aadharDob;
        @AuraEnabled public String aadharName;
        @AuraEnabled public Boolean isAadhaarFrontOCRConfirmed;
        @AuraEnabled public Boolean isAadhaarBackOCRConfirmed;
        @AuraEnabled public String firstName;
        @AuraEnabled public String middleName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String mobileNumber;
        @AuraEnabled public String aadharFirstName;
        @AuraEnabled public String aadharMiddleName;
        @AuraEnabled public String aadharLastName;
        @AuraEnabled public String aadharNumberUnmasked;
        @AuraEnabled public Boolean isMNRLBlacklisted;
        @AuraEnabled public String addressLine1;
        @AuraEnabled public String addressLine2;
        @AuraEnabled public String addressLine3;
        @AuraEnabled public String pin;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String country;
        @AuraEnabled public String addressType;
        @AuraEnabled public String addressOwnership;
        @AuraEnabled public String customerProfile;
        @AuraEnabled public String isFinancialApplicant;
        @AuraEnabled public Boolean isImage;
        @AuraEnabled public Boolean isPDF;
        @AuraEnabled public Boolean isckycinitiated;
    }
    
    
    @AuraEnabled
    public static ApplicantWrapper getApplicantDetailsOCR(String  applicantId){
        try {
             //HL-Ishi-9/9/2025
            Map<String,String> inputMapUtility = new  Map<String,String>();
            Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
            Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
               
            //HL-Ishi-9/9/2025
            ContentVersion cv = new ContentVersion ();
            List<Application_Applicant__c> appList =[SELECT Id,IsForm60Uploaded__c,Aadhaar_First_Name__c,Aadhaar_Middle_Name__c,Aadhaar_Last_Name__c,Aadhaar_Number__c,Aadhaar_Number_Masked__c,Aadhaar_Pincode__c,Aadhaar_Pincode__r.Name,Aadhaar_DOB__c,Aadhaar_Address__c,Aadhaar_City_Town__c,Customer_Tagged_From_Dedupe__c,Applicant_Type__c,Loan_Application__r.Lead__r.Full_Name_As_Per_Pan__c,PAN_Number__c,Pan_OCR_Confirmed__c,Sector__c,DOI__c,Sub_Employment_Type_Non_Individual__c,Applicant_Name__c, Father_s_First_Name__c,Father_s_Middle_Name__c,Father_s_Last_Name__c,Pan_Name__c,DOB__c,Loan_Application__c,Customer__r.Customer_LMS_Id__c,Customer__r.UCIC_Number__c, Customer_Type__c,Aadhaar_Front_OCR_Confirmed__c,Aadhaar_Back_OCR_Confirmed__c,First_Name__c,Middle_Name__c,Last_Name__c,Mobile_Number__c,Is_MNRL_Blacklisted__c from Application_Applicant__c where id =: applicantId];
            List<Document_Details__c> docDetails = [SELECT Id,Document_Master__r.Name, Content_Document_Id__c from Document_Details__c where Applicant__c =:applicantId AND Loan_Application__c =: appList[0].Loan_Application__c AND Content_Document_Id__c!= null ];
            Map<String,Document_Details__c> mapOfDocDetail = new Map<String,Document_Details__c>();
            List<ContentVersion> lstOfFormSixtyCv = new List<ContentVersion>();
            for(Document_Details__c objDocDetail : docDetails){
                mapOfDocDetail.put(objDocDetail.Document_Master__r.Name,objDocDetail);
            }
            if(docDetails.size()>0 && mapOfDocDetail.containsKey('PAN')){
                cv = [Select id,ContentDocumentId,FileExtension from ContentVersion where ContentDocumentId =: mapOfDocDetail.get('PAN').Content_Document_Id__c];
            }
            if(docDetails.size()>0 && mapOfDocDetail.containsKey('Form 60')){
                lstOfFormSixtyCv  = [Select id,ContentDocumentId,FileExtension from ContentVersion where ContentDocumentId =: mapOfDocDetail.get('Form 60').Content_Document_Id__c];
            }
            
            ApplicantWrapper applicantWrapper = new ApplicantWrapper();
            applicantWrapper.name = appList[0].Applicant_Name__c;
            applicantWrapper.applicantId = applicantId;
            applicantWrapper.panNumber = appList[0].PAN_Number__c;
            applicantWrapper.panName = appList[0].Pan_Name__c;
            applicantWrapper.fathersName = String.join(new List<String>{appList[0].Father_s_First_Name__c,String.isBlank(appList[0].Father_s_Middle_Name__c) ? null : appList[0].Father_s_Middle_Name__c,String.isBlank(appList[0].Father_s_Last_Name__c) ? null : appList[0].Father_s_Last_Name__c},' ');
            applicantWrapper.dobORDoi = appList[0].DOB__c!= null ? String.valueof(appList[0].DOB__c) : (appList[0].DOI__c!= null ? String.valueof(appList[0].DOI__c) : '');
            applicantWrapper.isOCRConfirmed = appList[0].Pan_OCR_Confirmed__c;
            applicantWrapper.customerType = appList[0].Customer_Type__c;
            applicantWrapper.selectedconstitution = appList[0].Sector__c;
            applicantWrapper.leadName = appList[0].Loan_Application__r.Lead__r.Full_Name_As_Per_Pan__c ;
            applicantWrapper.applicantType = appList[0].Applicant_Type__c;
            applicantWrapper.aadharNumber = (!String.isBlank(appList[0].Aadhaar_Number__c) && appList[0].Aadhaar_Number__c.length() == 12) ? 'XXXXXXXX' + appList[0].Aadhaar_Number__c.substring(8) : '';
            applicantWrapper.aadharPinCode = appList[0].Aadhaar_Pincode__r.Name;
            applicantWrapper.aadharDob = String.valueOf(appList[0].Aadhaar_DOB__c);
            applicantWrapper.aadharAddress = String.join(new List<String>{String.isBlank(appList[0].Aadhaar_Address__c) ? null : appList[0].Aadhaar_Address__c,String.isBlank(appList[0].Aadhaar_City_Town__c) ? null : appList[0].Aadhaar_City_Town__c,
                                            (appList[0].Aadhaar_Pincode__r != null && !String.isBlank(appList[0].Aadhaar_Pincode__r.Name)) ? appList[0].Aadhaar_Pincode__r.Name : null}, ' ');
            applicantWrapper.aadharName = String.join(new List<String>{
                                          String.isBlank(appList[0].Aadhaar_First_Name__c) ? null : appList[0].Aadhaar_First_Name__c,
                                          String.isBlank(appList[0].Aadhaar_Middle_Name__c) ? null : appList[0].Aadhaar_Middle_Name__c,
                                          String.isBlank(appList[0].Aadhaar_Last_Name__c)  ? null : appList[0].Aadhaar_Last_Name__c},' ');                               
            applicantWrapper.isAadhaarFrontOCRConfirmed = appList[0].Aadhaar_Front_OCR_Confirmed__c;
            applicantWrapper.isAadhaarBackOCRConfirmed = appList[0].Aadhaar_Back_OCR_Confirmed__c;
            applicantWrapper.firstName = appList[0].First_Name__c;
            applicantWrapper.middleName = appList[0].Middle_Name__c;
            applicantWrapper.lastName = appList[0].Last_Name__c;
            applicantWrapper.mobileNumber = appList[0].Mobile_Number__c;
            applicantWrapper.aadharFirstName = appList[0].Aadhaar_First_Name__c;
            applicantWrapper.aadharMiddleName = appList[0].Aadhaar_Middle_Name__c;
            applicantWrapper.aadharLastName = appList[0].Aadhaar_Last_Name__c;
            applicantWrapper.isMNRLBlacklisted = appList[0].Is_MNRL_Blacklisted__c;
            applicantWrapper.aadharNumberUnmasked = Utility.getDecryptedBase64String(appList[0].Aadhaar_Number_Masked__c);
            applicantWrapper.isPDF = false;
            applicantWrapper.isImage = false;
            if(cv!=null){
                applicantWrapper.contentDocumentID  = cv.Id;//docDetails[0].Content_Document_Id__c;
                if(cv.FileExtension == 'pdf'){
                    applicantWrapper.isPDF = true;
                    applicantWrapper.isImage = false;
                }
                else{
                    applicantWrapper.isImage = true;
                    applicantWrapper.isPDF = false;
                }
            }
            if(appList[0].Customer__r.Customer_LMS_Id__c!=null||appList[0].Customer__r.UCIC_Number__c!=null){
                applicantWrapper.disbalePAN = true;
            }
            applicantWrapper.reHitDeDupe  = appList[0].Customer_Tagged_From_Dedupe__c == true ? false: true;
            if(appList[0].IsForm60Uploaded__c == 'Yes'){
                applicantWrapper.isForm60Uploaded = true;
                if(!lstOfFormSixtyCv.isEmpty()){
                    applicantWrapper.formSixtyFileCv = lstOfFormSixtyCv[0].Id;
                    applicantWrapper.formSixtyFileCd = lstOfFormSixtyCv[0].ContentDocumentId;
                }
            }
            else if(appList[0].IsForm60Uploaded__c == 'No'){
                applicantWrapper.isForm60Uploaded = false;
            }
            List<Applicant_Address__c> appAddr = [Select Id, HL_Address_Line_1__c, HL_Address_Line_2__c, HL_Address_Line_3__c, Pincode__r.Country__c,Address_Ownership__c,
                                                  City__c, State__c, Pincode__c, Address_Line_1__c, Address_Line_2__c, Pincode__r.Name,
                                                  Address_Line_3__c,Address_Type__c,Pincode__r.City__r.Name,Pincode__r.City__r.Country__c from Applicant_Address__c where Applicant__c =: applicantId 
                                                  and Address_Source__c = 'Aadhaar' limit 1];
            if(!appAddr.isEmpty()){
                // if(isHlRelated){
                //     applicantWrapper.addressLine1 = appAddr[0].HL_Address_Line_1__c;
                //     applicantWrapper.addressLine2 = appAddr[0].HL_Address_Line_2__c;
                //     applicantWrapper.addressLine3 = appAddr[0].HL_Address_Line_3__c;
                // }
                // else{
                    applicantWrapper.addressLine1 = appAddr[0].Address_Line_1__c;
                    applicantWrapper.addressLine2 = appAddr[0].Address_Line_2__c;
                    applicantWrapper.addressLine3 = appAddr[0].Address_Line_3__c;
                // }
                applicantWrapper.addressType= appAddr[0].Address_Type__c;
                applicantWrapper.addressOwnership = appAddr[0].Address_Ownership__c;
                applicantWrapper.pin = appAddr[0].Pincode__r.Name;
                applicantWrapper.city = appAddr[0].Pincode__r.City__r.Name;
                applicantWrapper.state = appAddr[0].State__c;
                applicantWrapper.country = appAddr[0].Pincode__r.City__r.Country__c;
            }
            return applicantWrapper;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getTableHeaders() {
        List<String> columnLabels = new List<String>();
        try {
            System.debug('Fetching Offer_Screen_Labels__mdt metadata...');
            
            List<Offer_Screen_Labels__mdt> metadataRecords = [
                SELECT label__c, Sequence__c FROM Offer_Screen_Labels__mdt ORDER BY Sequence__c ASC
            ];
            
            System.debug('Metadata Records: ' + metadataRecords);
            
            for (Offer_Screen_Labels__mdt record : metadataRecords) {
                columnLabels.add(record.label__c);
            }
            
            System.debug('Final column labels: ' + columnLabels);
            return columnLabels;
        } catch (Exception e) {
            System.debug('Error in getTableHeaders: ' + e.getMessage());
            throw new AuraHandledException('Error fetching table labels: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static List<OfferWrapper> getOfferDetails(String custId){
        List<OfferWrapper> offerWrapList = new List<OfferWrapper>();
        List<Account> accList = [Select Id from Account where Customer_LMS_Id__c =: custId];
        List<Offer_Screen_Labels__mdt> metadataRecords = [
            SELECT label__c, Sequence__c, Field_Api_Name__c FROM Offer_Screen_Labels__mdt ORDER BY Sequence__c ASC
        ];
        String offerQuery = 'Select id ';
        for(Offer_Screen_Labels__mdt offer : metadataRecords){
            if(offer.Field_Api_Name__c != null){
                offerQuery = offerQuery +', '+offer.Field_Api_Name__c;
            }
        }
        String accId = accList[0].Id;
        offerQuery = offerQuery + ' from Offers__c where Account__c =:accId';
        List<Offers__c> offerList = Database.query(offerQuery);
        for(Offers__c iterOf : offerList){
            OfferWrapper offerWrap = new OfferWrapper();
            offerWrap.columnValues = new List<String>();
            offerWrap.offerLink = URL.getOrgDomainURL().toExternalForm() + '/' +iterOf.Id;
            offerWrap.offerName = iterOf.Offer_Id__c;
            for(Offer_Screen_Labels__mdt ofmdt : metadataRecords){
                if(ofmdt.Field_Api_Name__c != null && ofmdt.Field_Api_Name__c != 'Offer_Id__c'){
                    if(iterOf.get(ofmdt.Field_Api_Name__c) != null){
                        offerWrap.columnValues.add(String.valueOf(iterOf.get(ofmdt.Field_Api_Name__c)));
                    }
                    else{
                        offerWrap.columnValues.add('-');
                    }
                }
                offerWrap.offerId = iterOf.Id;
                offerWrap.offerStatus = iterOf.Offer_Status__c;
                if( iterOf.Offer_Status__c == 'Offer Sent to Customer'){
                    offerWrap.offersent = true;
                    offerWrap.disableOfferButton = true;
                    
                }
                else if(iterOf.Offer_Status__c=='Offer Accepted' ){
                    offerWrap.offeraccepted = true;
                    offerWrap.disableOfferButton = true;
                }
                else if( iterOf.Offer_Status__c == 'Change Requested'){
                    offerWrap.disableOfferButton = true;
                    offerWrap.changeRequested = true;
                    
                }
                
                else{
                    offerWrap.offerNotSent = true;
                    offerWrap.disableOfferButton = false;
                }
                // else{
                //     offerWrap.columnValues.add('-');
                // }
                
            }
            offerWrapList.add(offerWrap);
        }
        return offerWrapList;
    }
    public class OfferWrapper{
        @AuraEnabled public List<String> columnValues;
        @AuraEnabled public String offerId;
        @AuraEnabled public String offerStatus;
        @AuraEnabled public boolean disableOfferButton;
        @AuraEnabled public boolean offeraccepted;
        @AuraEnabled public boolean offerNotSent;
        @AuraEnabled public boolean offersent;
        @AuraEnabled public boolean changeRequested;
        @AuraEnabled public String offerLink;
        @AuraEnabled public String offerName;
    }
    @AuraEnabled
    public static void updateApplicantDetails(String applicantId,Boolean panConfimed){
        try {
            List<Application_Applicant__c> appList =[Select id, Pan_OCR_Confirmed__c from Application_Applicant__c where id =:applicantId];
            if(appList.size()>0){
                appList[0].Pan_OCR_Confirmed__c =panConfimed;
            }
            update appList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static ExistingOfferWrapper getExisitingCustOfferDetails(String offerId){
        try {
            System.debug('offerId--'+offerId);
            String status;
            List<Offers__c> offerList = [Select Id, Offer_Status__c,Existing_Loan_Number__c,Loan_Amount__c,Loan_ROI__c,Loan_Tenure__c,Valid_Till__c from Offers__c where Id =: offerId];
            ExistingOfferWrapper eoWrap = new ExistingOfferWrapper();
            if(offerList.size()>0){
                
                eoWrap.offerStatus = offerList[0].Offer_Status__c;
                eoWrap.laNumber= offerList[0].Existing_Loan_Number__c;
                eoWrap.laAmount= offerList[0].Loan_Amount__c;
                eoWrap.loanROI= offerList[0].Loan_ROI__c;
                eoWrap.loanTenure= offerList[0].Loan_Tenure__c;
                eoWrap.validTill= String.valueof(offerList[0].Valid_Till__c);
                
            }
            return eoWrap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean checkConsentAppdetails(Id appDet){
       try {
            Schema.SObjectType sObjectType = appDet.getSObjectType();
            String objectName = sObjectType.getDescribe().getName();
            if(objectName == 'Lead'){
            List<Lead> leadDets = [SELECT Id, COMM_Is_Consent_Received__c FROM Lead WHERE Id =: appDet];
            if(!leadDets.isEmpty()) {
                return leadDets[0].COMM_Is_Consent_Received__c;
            } else {
                return false;
            }

            }else{
            List<Application_Applicant__c> appDets = [SELECT Id, Is_Consent_Received__c FROM Application_Applicant__c WHERE Id =: appDet];
            if(!appDets.isEmpty()) {
                return appDets[0].Is_Consent_Received__c;
            } else {
                return false;
            }

            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

     @AuraEnabled
    public static Boolean checkConsentStatus(Id appDet){
        try {
            Schema.SObjectType sObjectType = appDet.getSObjectType();
            String objectName = sObjectType.getDescribe().getName();
            if(objectName == 'Lead'){
            List<Lead> leadDets = [SELECT Id, COMM_Consent_Status__c FROM Lead WHERE Id =: appDet];
            if(!leadDets.isEmpty()) {
                return leadDets[0].COMM_Consent_Status__c == 'Accepted' ? true : false;
            } else {
                return false;
            }
            }else{
            List<Application_Applicant__c> appDets = [SELECT Id, Consent_Status__c FROM Application_Applicant__c WHERE Id =: appDet];
            if(!appDets.isEmpty()) {
                return appDets[0].Consent_Status__c== 'Accepted' ? true : false;
            } else {
                return false;
            }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class ExistingOfferWrapper{
        @AuraEnabled public String offerStatus;
        @AuraEnabled public String laNumber;
        @AuraEnabled public Decimal laAmount;
        @AuraEnabled public String validTill;
        @AuraEnabled public Decimal loanTenure;
        @AuraEnabled public Decimal loanROI;
        @AuraEnabled public String ucic;
        
    }
    
    @AuraEnabled
    public static string saveOfferDetails(Map<String,String> inputMap){
        try {
            String flag ='';
            String offerId = inputMap.get('offerId');
            String status = inputMap.get('status');
            String addressRemarks = inputMap.get('addressRemarks');
            String loanAmount = inputMap.get('loanAmountRemakrs');
            String structure = inputMap.get('structureRemarks');
            List<Offers__c> ofr =[Select id,Offer_Status__c,Address_Remarks__c,Loan_Amount_Remarks__c,Structure_Remarks__c from Offers__c where Id =: offerId];
            if(ofr.size()>0){
                ofr[0].Address_Remarks__c = addressRemarks!=null?addressRemarks:'';
                ofr[0].Loan_Amount_Remarks__c = loanAmount!=null?loanAmount:'';
                ofr[0].Structure_Remarks__c = structure!=null?structure:'';
                ofr[0].Offer_Status__c = status!=null?status:'';
                update ofr;
                flag= 'true';
                
            }
            return flag;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    
    @AuraEnabled
    public static List<loansFoundWrapper> existingLoans(string recordId, string processObject) {
        try {
            List<loansFoundWrapper> loansList = new List<loansFoundWrapper>();
            List<Id> customerIds = new List<Id>();

            if(processObject != 'Account'){
                List<Application_Applicant__c> primaryApplicantList = [SELECT Id, Customer__c FROM Application_Applicant__c WHERE Loan_Application__c = :recordId 
                                                                        AND Customer__r.Customer_LMS_Id__c != null AND Applicant_Type__c = 'Primary Applicant'];
                if (!primaryApplicantList.isEmpty()) { 
                    for (Application_Applicant__c app : primaryApplicantList) { 
                        if (app.Customer__c != null) {  
                            customerIds.add(app.Customer__c);
                        }
                    }
                }
            }
            else{
                customerIds.add(recordId);
            }
            
            if (!customerIds.isEmpty()) {  
                List<Application_Applicant__c> relatedLoanApps = [SELECT Id, Customer__c,Loan_Application__r.StageName, Loan_Application__c, Loan_Application__r.Product__c, Loan_Application__r.Name,Loan_Application__r.Id, Customer__r.Customer_LMS_Id__c,
                                                                  Loan_Application__r.Status__c, Loan_Application__r.Requested_Amount__c FROM Application_Applicant__c WHERE Customer__c IN :customerIds];
                for (Application_Applicant__c app : relatedLoanApps) { 
                    if (app.Loan_Application__c != null && app.Loan_Application__c != recordId) { 
                        loansFoundWrapper loanWrapper = new loansFoundWrapper();
                        loanWrapper.loanExternalId =URL.getOrgDomainURL().toExternalForm() + '/' +app.Loan_Application__r.Id;
                        loanWrapper.loanNo = app.Loan_Application__r.Name;
                        loanWrapper.product = app.Loan_Application__r.Product__c;
                        loanWrapper.loanAmount = String.valueOf(app.Loan_Application__r.Requested_Amount__c);
                        loanWrapper.loanStatus = app.Loan_Application__r.Status__c;
                        loanWrapper.loanStage  = app.Loan_Application__r.StageName;
                        loanWrapper.custLMS = app.Customer__r.Customer_LMS_Id__c;
                        loansList.add(loanWrapper);
                    }
                }
            }
            return loansList;  
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class loansFoundWrapper {
        @AuraEnabled  public String loanNo;            
        @AuraEnabled  public String product;
        @AuraEnabled  public String loanAmount;
        @AuraEnabled  public String loanStatus;
        @AuraEnabled  public String loanStage;
        @AuraEnabled  public String custLMS;
        @AuraEnabled public String loanExternalId;
    }
    /*
    @AuraEnabled
    public static void updateApplicantVerification(Id applicantId, Boolean dobMatch, Boolean nameMatch, String statusActive,String duplicateCheck) {
        try {
            Application_Applicant__c applicant = [SELECT Id, Is_PAN_DOB_Mismatch__c, Is_Pan_Duplicate__c,Pan_Status__c,Is_PAN_Name_Mismatch__c FROM Application_Applicant__c WHERE Id = :applicantId LIMIT 1];
            
            applicant.Is_PAN_DOB_Mismatch__c = dobMatch;
            applicant.Is_PAN_Name_Mismatch__c = nameMatch;
            applicant.Pan_Status__c = statusActive;
            applicant.Is_Pan_Duplicate__c =duplicateCheck!=null?Boolean.valueof(duplicateCheck):false;
            
            update applicant;
            
            System.debug('Application_Applicant__c updated successfully.');
        } catch (Exception e) {
            throw new AuraHandledException('Error updating applicant: ' + e.getMessage());
        }
    }
*/
@AuraEnabled
//Alika full method change
    public static void updateApplicantVerification(Id applicantId, String dobMatch, String nameMatch, String statusActive,String seeding_status,String pan_description,String seeding_status_description,String fathername){ 
        try {
            List<Application_Applicant__c> applicantList = [SELECT Id, Is_PAN_DOB_Mismatch__c, Is_Pan_Duplicate__c, Pan_Status__c, Is_PAN_Name_Mismatch__c, seeding_status__c, Pan_Description__c FROM Application_Applicant__c WHERE Id = :applicantId LIMIT 1];
            if (applicantList.isEmpty()) {
                throw new AuraHandledException('Applicant record not found.');
            }
            Application_Applicant__c applicant = applicantList[0];
    
                if(String.isNotBlank(dobMatch) && dobMatch == 'Y') {
                    applicant.Is_PAN_DOB_Mismatch__c = true;
                } else {
                    applicant.Is_PAN_DOB_Mismatch__c = false;
                }

                if(String.isNotBlank(nameMatch) && nameMatch == 'Y') {
                    applicant.Is_PAN_Name_Mismatch__c = true;
                } else {
                    applicant.Is_PAN_Name_Mismatch__c = false;
                }
 
                // if (String.isBlank(statusActive)) {
   
                // } else if (statusActive == 'F' || statusActive == 'X' || statusActive == 'D' || statusActive == 'N') {
                //     applicant.Pan_Status__c = 'Invalid';
                // } else {
                //     applicant.Pan_Status__c = 'Valid';
                // }
                // ...existing code...
                if (String.isBlank(statusActive)) {
                    
                } else {
                    /*if (!Schema.sObjectType.PAN_Status__mdt.isAccessible()) {
                        throw new AuraHandledException('You do not have permission to access PAN Status metadata.');
                    }*/
                    List<PAN_Status__mdt> panStatusMetaList = [
                        SELECT Validity__c 
                        FROM PAN_Status__mdt 
                        WHERE Code__c = :statusActive
                        LIMIT 1
                    ];
                    if (!panStatusMetaList.isEmpty() && panStatusMetaList[0].Validity__c != null) {
                        applicant.Pan_Status__c = panStatusMetaList[0].Validity__c;
                    } else {
                        applicant.Pan_Status__c = 'Invalid';
                    }
                }

            applicant.seeding_status__c =seeding_status_description;
            applicant.Pan_Description__c = pan_description;
            applicant.Is_Pan_Duplicate__c =false;

            
            update applicant;
            
            System.debug('Application_Applicant__c updated successfully.');
        } catch (Exception e) {
            throw new AuraHandledException('Error updating applicant: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String getNextScreenDetails(String currentAppSeq,String activeSectionName,String formIdentifier){
        try {
            String nextScreenName = '';
            Integer nextSequence;
            Map<String,String> inputMapUtility = new  Map<String,String>();
            Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
            Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
            System.debug('activeSectionName--'+activeSectionName);
            if(activeSectionName =='Applicant\'s Basic Information'){
                nextScreenName = 'Dedupe';
            }
            else if(activeSectionName =='Employment Details'){
                nextScreenName = 'PAN validation';
            }else if(activeSectionName == 'Loan Details'){
                if(isHlRelated){
                    nextScreenName = 'Login Fees';
                }
                else{
                    nextScreenName = 'PMAY Eligibility';
                }
            }
            else if(activeSectionName == 'PMAY Eligibility'){
                nextScreenName = 'Login Fees';
            }
            else {
            nextSequence = Integer.valueOf(currentAppSeq) + 1;
            
            List<Screen_Field__c> screenList = [Select id,Master_Screen_Sequence__c, Master_Screen_Name__c,Screen_Sequence__c, Screen_Name__c, Form_Name__c
                                                from Screen_Field__c where Form_Name__c   ='Loan Login Form' 
                                                and Is_Active__c =true and Is_Screen_Active__c = true
                                                and Screen_Sequence__c =: nextSequence];
            
            if(!screenList.isEmpty()){
                nextScreenName = screenList[0].Master_Screen_Name__c;
            }
        }
            return nextScreenName;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static String getPreviousScreenDetails(String currentAppSeq,String activeSectionName,String formIdentifier){
        try {
            String nextScreenName = '';
            Integer nextSequence = Integer.valueOf(currentAppSeq) - 1;
            
            List<Screen_Field__c> screenList = [Select id,Master_Screen_Sequence__c, Master_Screen_Name__c,Screen_Sequence__c, Screen_Name__c, Form_Name__c
                                                from Screen_Field__c where Form_Name__c   ='Loan Login Form' 
                                                and Is_Active__c =true and Is_Screen_Active__c = true
                                                and Screen_Sequence__c =: nextSequence];
            
            if(!screenList.isEmpty()){
                nextScreenName = screenList[0].Master_Screen_Name__c;
            }
            return nextScreenName;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static PanResponseWrapper getPanResp(String loanId, String apDetId){
        PanResponseWrapper resp = new PanResponseWrapper();
        List<Application_Applicant__c> apDetList = [Select Id,Pan_Number__c, Is_PAN_Name_Mismatch__c,Is_Pan_Duplicate__c,Pan_Status__c, Is_PAN_DOB_Mismatch__c,seeding_status__c from Application_Applicant__c where id =: apDetId]; // Alika Added in query
        resp.nameMatch = apDetList[0].Is_PAN_Name_Mismatch__c ? 'Match':'No Match';
        resp.dobMatch = apDetList[0].Is_PAN_DOB_Mismatch__c ? 'Match':'No Match';
        resp.duplicate = apDetList[0].Is_Pan_Duplicate__c?'Duplicate':'Non Duplicate';
        resp.status = apDetList[0].Pan_Status__c =='Active' || apDetList[0].Pan_Status__c =='Valid'?'Valid':'InValid';//Alika
        resp.nameMatchColour = apDetList[0].Is_PAN_Name_Mismatch__c ? true:false;
        resp.dobMatchColour = apDetList[0].Is_PAN_DOB_Mismatch__c ? true:false;
        resp.panNumber = apDetList[0].Pan_Number__c;
        resp.duplicateMatchColour = apDetList[0].Is_Pan_Duplicate__c?false:true;
        resp.panStatusColour = ((apDetList[0].Pan_Status__c =='Active') ||(apDetList[0].Pan_Status__c =='Valid'))? true:false;
        resp.seedingStatusDescription = apDetList[0].seeding_status__c;//Alika
        resp.seedingStatusDescriptionColor = apDetList[0].seeding_status__c =='Inoperative PAN'?false:true;//Alika
        
        System.debug('resp === '+resp);
        return resp;
    }
    public class PanResponseWrapper{
        @AuraEnabled public String nameMatch;
        @AuraEnabled public String dobMatch;
        @AuraEnabled public String panNumber;
        @AuraEnabled public String response;
        @AuraEnabled public String status;
        @AuraEnabled public String duplicate;
        @AuraEnabled public Boolean nameMatchColour;
        @AuraEnabled public Boolean dobMatchColour;
        @AuraEnabled public Boolean panStatusColour;
        @AuraEnabled public Boolean duplicateMatchColour;
        @AuraEnabled public String seedingStatusDescription;//Alika
        @AuraEnabled public Boolean seedingStatusDescriptionColor;//Alika
        
    }
    
    @AuraEnabled
    public static String documentCheckListUpdation(Map<String, Object> documentMap, Map<String, Object> imagetypeMap, String loanId, String applicantId, String documentType) {
        try {
            Map<String, Id> docNameToMasterId = new Map<String, Id>();
            Map<String, String> docCodeToName = new Map<String, String>();
            System.debug('Received documentMap: ' + JSON.serialize(documentMap));
            System.debug('Received imagetypeMap: ' + JSON.serialize(imagetypeMap));
            System.debug('Loan ID: ' + loanId);
            System.debug('Applicant ID: ' + applicantId);
            System.debug('Document Type: ' + documentType);
            
            // Fetch Document Master Data
            List<Document_Master__c> docMasterList = [
                SELECT Id, CKYC_Image_Code__c, Document_Name__c
                FROM Document_Master__c
                WHERE CKYC_Image_Code__c IN :documentMap.keySet()
            ];
            for (Document_Master__c doc : docMasterList) {
                docNameToMasterId.put(doc.Document_Name__c, doc.Id);
                docCodeToName.put(doc.CKYC_Image_Code__c, doc.Document_Name__c);
            }
            
            List<ContentVersion> contentVersionList = new List<ContentVersion>();
            Map<String, String> contentIdMap = new Map<String, String>();
            List<Document_Details__c> docDetailsList = new List<Document_Details__c>();
            
            // Create ContentVersion records
            for (String imageCode : documentMap.keySet()) {
                Object docValue = documentMap.get(imageCode);
                String base64Data;
                if (docValue instanceof List<Object>) {
                    List<Object> base64List = (List<Object>) docValue;
                    base64Data = (!base64List.isEmpty()) ? (String) base64List[0] : null;
                } else if (docValue instanceof String) {
                    base64Data = (String) docValue;
                } else {
                    throw new AuraHandledException('Unexpected value type for ' + imageCode);
                }
                
                String imageType = imagetypeMap.containsKey(imageCode) ? (String) imagetypeMap.get(imageCode) : null;
                String docName = docCodeToName.get(imageCode);
                System.debug('imageCode ' + imageCode);
                System.debug('imageType ' + imageType);
                System.debug('docName ' + docName);
                
                ContentVersion cv = new ContentVersion();
                cv.Title = docName;
                cv.PathOnClient = docName + (imageType != null ? '.' + imageType : '');
                cv.VersionData = EncodingUtil.base64Decode(base64Data);
                cv.IsMajorVersion = true;
                contentVersionList.add(cv);
            }
            
            // Insert ContentVersion records
            if (!contentVersionList.isEmpty()) {
                insert contentVersionList;
                // Query the inserted ContentVersion records to get ContentDocumentId populated
                List<ContentVersion> insertedCVs = [
                    SELECT Id, ContentDocumentId, Title
                    FROM ContentVersion
                    WHERE Id IN :contentVersionList
                ];
                for (ContentVersion cv : insertedCVs) {
                    contentIdMap.put(cv.Title, cv.ContentDocumentId);
                    Document_Details__c docDetail = new Document_Details__c();
                    docDetail.Name = cv.Title;
                    docDetail.Document_Master__c = docNameToMasterId.get(cv.Title);
                    docDetail.Content_Document_Id__c = cv.ContentDocumentId;
                    docDetail.Loan_Application__c = loanId;
                    docDetail.Applicant__c = applicantId;
                    docDetail.Source__c = documentType;
                    docDetail.Status__c = 'Uploaded';
                    docDetailsList.add(docDetail);
                }
            }
            
            // Insert Document Details records
            if (!docDetailsList.isEmpty()) {
                insert docDetailsList;
                
                // Update existing Document Details records
                List<Document_Details__c> existingDetails = [
                    SELECT Id, Active__c, Document_Details_Lookup__c
                    FROM Document_Details__c
                    WHERE Loan_Application__c = :loanId
                    AND Applicant__c = :applicantId
                    AND Document_Master__c IN :docNameToMasterId.values()
                    AND Id NOT IN :docDetailsList
                ];
                for (Document_Details__c detail : existingDetails) {
                    detail.Active__c = false;
                    detail.Document_Details_Lookup__c = docDetailsList[0].Id;
                }
                if (!existingDetails.isEmpty()) {
                    update existingDetails;
                }
            }
            return 'Success: Content IDs Created - ' + JSON.serialize(contentIdMap);
        } catch (Exception e) {
            throw new AuraHandledException('Error updating document checklist: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string getLoanStage(String recordId){
        try {
            Opportunity loan = [SELECT id,StageName from Opportunity where id =:recordId];
            
            return loan.StageName;
            
            
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

//     @AuraEnabled
// public static List<DeDupeWrapper> getDuplicateCustomerList(String custId, String applicantId, String loanId){
//     try {
//         String customerUniqueId;
//         List<DeDupeWrapper> dupList = new List<DeDupeWrapper>();
//         List<Application_Applicant__c> appList = new List<Application_Applicant__c>();
//         Map<String, Account> idToAccMap = new Map<String, Account>();
//         Map<String, Account> lmsIdToAccMap = new Map<String, Account>();
        
//         // Fetch applicants based on the provided applicantId or loanId
//         if(applicantId == null){
//             appList = [SELECT id, Customer__c, PAN_Number__c, Mobile_Number__c, DOB__c, Customer__r.Customer_LMS_Id__c,
//                        Customer__r.Name, Customer__r.UCIC_Number__c, Customer__r.Match_Response__c, Customer__r.Duplicate_Customer_Source__c
//                        FROM Application_Applicant__c WHERE Loan_Application__c = :loanId];
//         } else {
//             appList = [SELECT id, Customer__c, PAN_Number__c, Mobile_Number__c, DOB__c, Customer__r.Customer_LMS_Id__c,
//                        Customer__r.Name, Customer__r.UCIC_Number__c, Customer__r.Match_Response__c, Customer__r.Duplicate_Customer_Source__c
//                        FROM Application_Applicant__c WHERE id = :applicantId];
//         }

//         // List to hold all customer unique IDs
//         List<String> customerUniqueIds = new List<String>();
//         for(Application_Applicant__c app : appList){
//             if(app.Customer__r != null && app.Customer__r.Customer_LMS_Id__c != null){
//                 customerUniqueIds.add('%' + app.Customer__r.Customer_LMS_Id__c + '%');
//             }
//         }
//         if(applicantId != null){
//             // Query accounts based on the list of customer unique IDs
//             List<Account> accList = [SELECT id, Customer_LMS_Id__c, Name, Gender__c, Duplicate_Customer_Source__c,
//                                     Match_Response__c, Mobile_Number__c, Mobile_Number_Masked__c, PAN_Number__c,
//                                     Date_of_Birth__c, Customer_Type__c, Dedupe_Disposition__c, Dedupe_Disposition_Remarks__c
//                                     FROM Account
//                                     WHERE CustUniqueId__c != null AND CustUniqueId__c IN :customerUniqueIds
//                                     ORDER BY Duplicate_Customer_Source__c DESC];
            
//             // Map to store Accounts by their ID and Customer LMS ID
       
            
//             for(Account acc : accList){
//                 idToAccMap.put(acc.Id, acc);
//                 lmsIdToAccMap.put(acc.Customer_LMS_Id__c, acc);
//             }
            
//     }
//         // Continue with applicant and loan processing...
//         // You can continue as you have done with the applicantList and product list logic.

//         // Wrap each account into DeDupeWrapper and return
//         for(String accId : idToAccMap.keySet()){
//             Account acc = idToAccMap.get(accId);
//             DeDupeWrapper dupWrapper = new DeDupeWrapper();
//             dupWrapper.name = acc.Name;
//             dupWrapper.loanNum = 'LoanNumber';  // Add actual loan number here
//             dupWrapper.loanLink = URL.getOrgDomainURL().toExternalForm() + '/' + 'LoanApplicationId';
//             dupWrapper.customerId = acc.Customer_LMS_Id__c;
//             dupWrapper.dob = String.valueOf(acc.Date_of_Birth__c);
//             dupWrapper.gender = acc.Gender__c;
//             dupWrapper.panNumber = acc.PAN_Number__c;
//             dupWrapper.mobileNumber = acc.Mobile_Number_Masked__c;
//             dupWrapper.matchReason = (acc.Match_Response__c != null) ? acc.Match_Response__c.split('\\|')[0] : null;
//             dupWrapper.accId = acc.Id;
//             dupWrapper.isFromSFDC = acc.Duplicate_Customer_Source__c == 'PLF' ? true : false;
//             dupWrapper.customerType = acc.Customer_Type__c;
//             dupWrapper.sourceSystem = acc.Duplicate_Customer_Source__c;
//             dupWrapper.dispositionStatus = acc.Dedupe_Disposition__c;
//             dupWrapper.dispositionRemarks = acc.Dedupe_Disposition_Remarks__c;
//             dupWrapper.custLink = URL.getOrgDomainURL().toExternalForm() + '/' + acc.id;
//             dupWrapper.product = '-';
//             dupWrapper.stage = 'Disbursement';  // You can replace this based on actual stage
//             dupList.add(dupWrapper);
//         }

//         return dupList;
//     } catch (Exception e) {
//         throw new AuraHandledException(e.getMessage());
//     }
// }

    @AuraEnabled
    public static List<DeDupeWrapper> getAllCustomerDuplicateList(String custId,String loanId){
        List<Application_Applicant__c> appList = new  List<Application_Applicant__c>();
        String customerUniqueId;
        List<DeDupeWrapper> dupList = new List<DeDupeWrapper>();
        appList = [Select id,Customer__c,PAN_Number__c,Mobile_Number__c,DOB__c,Customer__r.Customer_LMS_Id__c,Customer__r.Name,Customer__r.UCIC_Number__c,Customer__r.Match_Response__c,Customer__r.Duplicate_Customer_Source__c from Application_Applicant__c where Loan_Application__c=:loanId];
        for(Application_Applicant__c app : appList){
            List<DeDupeWrapper> dupListTemp = getDuplicateCustomerList(custId,app.id,loanId);
            dupList.addAll(dupListTemp);
        }
        return dupList;
    }

   @AuraEnabled
    public static List<DeDupeWrapper> getDuplicateCustomerList(String custId,String applicantId,String loanId){
        try {
            system.debug(custId);
            system.debug(applicantId);
            system.debug(loanId);
            String customerUniqueId;
            List<DeDupeWrapper> dupList = new List<DeDupeWrapper>();
            List<Application_Applicant__c> appList = new  List<Application_Applicant__c>();
            if(applicantId == null ){
                
                appList = [Select id,Customer__c,PAN_Number__c,Mobile_Number__c,DOB__c,Customer__r.Customer_LMS_Id__c,Customer__r.Name,Customer__r.UCIC_Number__c,Customer__r.Match_Response__c,Customer__r.Duplicate_Customer_Source__c from Application_Applicant__c where Loan_Application__c=:loanId];
            }
            else{
                appList = [Select id,Customer__c,PAN_Number__c,Mobile_Number__c,DOB__c,Customer__r.Customer_LMS_Id__c,Customer__r.Name,Customer__r.UCIC_Number__c,Customer__r.Match_Response__c,Customer__r.Duplicate_Customer_Source__c from Application_Applicant__c where id=:applicantId];
            }
            
            for(Application_Applicant__c app : appList){
                if(app.id!= null){
                    customerUniqueId = app.id;
                    List<DeDupeWrapper> dupListTemp = getDuplicateCustomers(customerUniqueId,app.id,loanId,custId);
                    dupList.addAll(dupListTemp);
                }
                
                
            }
             Integer count = 1;
            for(DeDupeWrapper dw : dupList){
                dw.uniqueCount = count;
                count++;
            }
            return dupList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<DeDupeWrapper> getDuplicateCustomers(String customerUniqueId, String applicantId,String loanId, String custId ){
        List<DeDupeWrapper> dupList = new List<DeDupeWrapper>();
         System.debug('customerUniqueId--'+customerUniqueId);
         System.debug('applicantId--'+applicantId);
         System.debug('loanId--'+loanId);
         System.debug('custId--'+custId);
        customerUniqueId = '%' +customerUniqueId+'%';
        List<Account> accList=[Select id,Customer_LMS_Id__c,Name,Gender__c,Duplicate_Customer_Source__c,Match_Response__c,Mobile_Number__c,Mobile_Number_Masked__c,PAN_Number__c,Date_of_Birth__c,Customer_Type__c,Dedupe_Disposition__c,Dedupe_Disposition_Remarks__c,Applicant_Identifier__c from Account where Applicant_Identifier__c != null and Applicant_Identifier__c Like :customerUniqueId and Is_Active__c = true order by Duplicate_Customer_Source__c DESC];
        Map<String,Account> idToAccMap = new Map<String,Account>();
        Map<String,Account> lmsIdToAccMap = new Map<String,Account>();
        Map<String, Map<String, String>> customertoUniqIdMap= new Map<String, Map<String, String>>();
        Map<String, String> customerToApplicantType= new Map<String, String>();
        Map<String, String> customerToSelectedApplicant= new Map<String, String>();
        List<Application_Applicant__c> loanApplicantList= [SELECT Id, Name, Customer__c, Applicant_Type__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId];
        for(Account acc : accList){
            idToAccMap.put(acc.Id,acc);
            lmsIdToAccMap.put(acc.Customer_LMS_Id__c,acc);
            List<String> appIDListSplit= acc.Applicant_Identifier__c.split(',');
            Map<String, String> applicantMap= new Map<String, String>();
            for(Application_Applicant__c app:loanApplicantList){
                if(appIDListSplit.contains(app.Id)){
                    applicantMap.put(app.Id, app.Name);
                }
                if(app.Customer__c == acc.Id){
                    customerToSelectedApplicant.put(acc.Id, app.Id);
                }
                if(app.Id== applicantId){
                    customerToApplicantType.put(acc.Id, app.Applicant_Type__c);
                }
            }
            customertoUniqIdMap.put(acc.Id, applicantMap);
        }
        List<Application_Applicant__c> applicantList = [Select Id, Customer__c, Loan_Application__c, Loan_Application__r.Name, Loan_Application__r.StageName,Loan_Application__r.CreatedDate, Applicant_Type__c from Application_Applicant__c where Customer__c in: accList  AND Loan_Application__c!=: loanId order by Customer__r.Duplicate_Customer_Source__c DESC, Loan_Application__r.CreatedDate DESC ];
        
        Map<String,List<Application_Applicant__c>> customerToApplicantMap = new Map<String,List<Application_Applicant__c>>();
        List<String> loanIds = new List<String>();
        for(Application_Applicant__c ap : applicantList){
            if(customerToApplicantMap.containsKey(ap.Customer__c)){
                customerToApplicantMap.get(ap.Customer__c).add(ap);
            }
            else{
                customerToApplicantMap.put(ap.Customer__c, new List<Application_Applicant__c>{ap});
            }
            loanIds.add(ap.Loan_Application__c);
        }
         System.debug('customerToApplicantMap----'+customerToApplicantMap);
         System.debug('applicantList----'+applicantList);
        List<Product2> prodList = [Select Id,Loan_Application__c,Name, Product__r.Name from Product2 where Loan_Application__c in: loanIds AND RecordType.DeveloperName IN ('Product','Sub_Product')];
        Map<String,List<String>> loanToProductMap = new Map<String, List<String>>();
        for(Product2 pr : prodList){
            if(loanToProductMap.containsKey(pr.Loan_Application__c)){
                loanToProductMap.get(pr.Loan_Application__c).add(pr.Product__r.Name);
            }
            else{
                loanToProductMap.put(pr.Loan_Application__c, new List<String>{pr.Product__r.Name});
            }
        }
        for(String accId : customerToApplicantMap.keySet()){
            List<Application_Applicant__c> custAppList = customerToApplicantMap.get(accId);
             System.debug('custAppList----'+custAppList);
            for(Application_Applicant__c app : custAppList){
                Account acc = idToAccMap.get(accId);
                DeDupeWrapper dupWrapper = new DeDupeWrapper();
                dupWrapper.name = acc.Name ;
                dupWrapper.loanNum = app.Loan_Application__r.Name;
                dupWrapper.loanCreatedDate = app.Loan_Application__r.CreatedDate.Date();
                dupWrapper.loanLink = URL.getOrgDomainURL().toExternalForm() + '/' +app.Loan_Application__c;
                dupWrapper.loanFromSfdc = true;
                dupWrapper.customerId =acc.Customer_LMS_Id__c;
                dupWrapper.dob =String.valueof(acc.Date_Of_Birth__c);
                dupWrapper.gender =acc.Gender__c;
                dupWrapper.panNumber = acc.PAN_Number__c;
                dupWrapper.mobileNumber = acc.Mobile_Number_Masked__c;
                dupWrapper.matchReason = (acc.Match_Response__c != null) ? acc.Match_Response__c.split('\\|')[0] : null;
                dupWrapper.accId = acc.Id ;
                dupWrapper.isFromSFDC =acc.Duplicate_Customer_Source__c=='PLF'?true:false;
                dupWrapper.customerType  =acc.Customer_Type__c;
                dupWrapper.sourceSystem =acc.Duplicate_Customer_Source__c;
                dupWrapper.dispositionStatus  =acc.Dedupe_Disposition__c;
                dupWrapper.isCoApplicant= customerToApplicantType.containsKey(acc.Id)? (customerToApplicantType.get(acc.Id) == 'Co applicant'? true: false)  : false;
                dupWrapper.dispositionRemarks  =acc.Dedupe_Disposition_Remarks__c;
                dupWrapper.custLink = URL.getOrgDomainURL().toExternalForm() + '/' +acc.id;
                dupWrapper.stage = app.Loan_Application__r.StageName;
                dupWrapper.applicantOptions= customertoUniqIdMap.get(acc.Id);
                dupWrapper.selectedValue= customerToSelectedApplicant.containsKey(acc.Id) ? customerToSelectedApplicant.get(acc.Id): '';
                dupWrapper.custUniqueId= acc.Applicant_Identifier__c;
                dupWrapper.product = '-';
                if(loanToProductMap.containsKey(app.Loan_Application__c)){
                    for(String st : loanToProductMap.get(app.Loan_Application__c)){
                        if(st != null){
                            if(dupWrapper.product=='-'){
                                dupWrapper.product = st;
                            }
                            else{
                                dupWrapper.product = dupWrapper.product+','+st;
                            }
                        }
                        else{
                            
                        }
                        
                        
                    }
                }
                dupList.add(dupWrapper);
            }
        }
        if(lmsIdToAccMap.size()>0){
            Map<String,List<LoanDetailsWrapper>> lmsIdToLoansMap = new Map<String,List<LoanDetailsWrapper>>();
            for(String str : lmsIdToAccMap.keySet()){
                if(str != null){
                    List<COMM_GetFinanceDetailsByUCICController.Finance> financeList =  COMM_GetFinanceDetailsByUCICController.getCustomerFinances(str,'Get Customer By UCIC');
                    
                    for(COMM_GetFinanceDetailsByUCICController.Finance f : financeList){
                        LoanDetailsWrapper ldw = new LoanDetailsWrapper();
                        ldw.loanNum = f.finReference;
                        if(lmsIdToLoansMap.containsKey(str)){
                            lmsIdToLoansMap.get(str).add(ldw);
                        }
                        else{
                            lmsIdToLoansMap.put(str, new List<LoanDetailsWrapper>{ldw});
                        }
                    }
                   
                    // COMM_GetCustomerController.Response custResponse = (COMM_GetCustomerController.Response) JSON.deserialize(
                    //     COMM_GetCustomerController.getCustomerDetails(str, 'Get Customer').respBody,
                    //     COMM_GetCustomerController.Response.class
                    // );
                    // if(custResponse.customerFinanceDetailList!=null){
                    //     for(COMM_GetFinanceDetailsByUCICController.cls_customerFinanceDetailList resp : custResponse.customerFinanceDetailList){
                    //         LoanDetailsWrapper ldw = new LoanDetailsWrapper();
                    //         ldw.loanNum = resp.finReference;
                    //         if(lmsIdToLoansMap.containsKey(str)){
                    //             lmsIdToLoansMap.get(str).add(ldw);
                    //         }
                    //         else{
                    //             lmsIdToLoansMap.put(str, new List<LoanDetailsWrapper>{ldw});
                    //         }
                    //     }
                    // }
                
                }
                
            }
            if(lmsIdToLoansMap.size()>0){
                for(String lmsId : lmsIdToLoansMap.keySet()){
                    if(lmsId != null){
                         List<LoanDetailsWrapper> loanDetails = lmsIdToLoansMap.get(lmsId);
                        for(LoanDetailsWrapper ldw : loanDetails){
                            Account acc = lmsIdToAccMap.get(lmsId);
                            DeDupeWrapper dupWrapper = new DeDupeWrapper();
                            dupWrapper.name = acc.Name ;
                            dupWrapper.loanNum = ldw.loanNum;
                            //dupWrapper.loanLink = URL.getOrgDomainURL().toExternalForm() + '/' +app.Loan_Application__c;
                            dupWrapper.loanFromSfdc = false;
                            dupWrapper.customerId =acc.Customer_LMS_Id__c;
                            dupWrapper.dob =String.valueof(acc.Date_Of_Birth__c);
                            dupWrapper.gender =acc.Gender__c;
                            dupWrapper.panNumber = acc.PAN_Number__c;
                            dupWrapper.mobileNumber = acc.Mobile_Number_Masked__c;
                            dupWrapper.matchReason = (acc.Match_Response__c != null) ? acc.Match_Response__c.split('\\|')[0] : null;
                            dupWrapper.accId = acc.Id ;
                            dupWrapper.isFromSFDC =acc.Duplicate_Customer_Source__c=='PLF'?true:false;
                            dupWrapper.customerType  =acc.Customer_Type__c;
                            dupWrapper.sourceSystem =acc.Duplicate_Customer_Source__c;
                            dupWrapper.dispositionStatus  =acc.Dedupe_Disposition__c;
                            dupWrapper.dispositionRemarks  =acc.Dedupe_Disposition_Remarks__c;
                            dupWrapper.custLink = URL.getOrgDomainURL().toExternalForm() + '/' +acc.id;
                            dupWrapper.product = '-';
                            dupWrapper.applicantOptions= customertoUniqIdMap.get(acc.Id);
                            dupWrapper.selectedValue= customerToSelectedApplicant.containsKey(acc.Id) ? customerToSelectedApplicant.get(acc.Id): '';
                            dupWrapper.custUniqueId= acc.Applicant_Identifier__c;
                            // dupWrapper.stage = 'Disbursement';
                            dupList.add(dupWrapper);
                        }   
                    }
                }
            }
            if(accList.size()>0){
                for(Account acc :accList ){
                    if(lmsIdToLoansMap.containsKey(acc.Customer_LMS_Id__c) || customerToApplicantMap.containsKey(acc.id)){
                        
                    }
                    else{
                        DeDupeWrapper dupWrapper = new DeDupeWrapper();
                        dupWrapper.name = acc.Name ;
                        dupWrapper.customerId =acc.Customer_LMS_Id__c;
                        dupWrapper.dob =String.valueof(acc.Date_Of_Birth__c);
                        dupWrapper.gender =acc.Gender__c;
                        dupWrapper.panNumber = acc.PAN_Number__c;
                        dupWrapper.mobileNumber = acc.Mobile_Number_Masked__c;
                        dupWrapper.matchReason = (acc.Match_Response__c != null) ? acc.Match_Response__c.split('\\|')[0] : null;
                        dupWrapper.accId = acc.Id ;
                        dupWrapper.isFromSFDC =acc.Duplicate_Customer_Source__c=='PLF'?true:false;
                        dupWrapper.customerType  =acc.Customer_Type__c;
                        dupWrapper.sourceSystem =acc.Duplicate_Customer_Source__c;
                        dupWrapper.dispositionStatus  =acc.Dedupe_Disposition__c;
                        dupWrapper.dispositionRemarks  =acc.Dedupe_Disposition_Remarks__c;
                        dupWrapper.custLink = URL.getOrgDomainURL().toExternalForm() + '/' +acc.id;
                        dupWrapper.applicantOptions= customertoUniqIdMap.get(acc.Id);
                        dupWrapper.custUniqueId= acc.Applicant_Identifier__c;
                        dupWrapper.selectedValue= customerToSelectedApplicant.containsKey(acc.Id) ? customerToSelectedApplicant.get(acc.Id): '';
                        dupList.add(dupWrapper);
                    }
                    
                  
                }
            }
           

        }
        // else{
        //     List<Account> acc =[Select id,Customer_LMS_Id__c from Account where Customer_LMS_Id__c != null and Customer_LMS_Id__c =:custId];
        //     if(acc.size()>0){
        //         appList= [Select id,Customer__c,Gender__c,PAN_Number__c,Mobile_Number__c,DOB__c,Customer__r.Customer_LMS_Id__c,Customer__r.Name,Customer__r.UCIC_Number__c,Customer__r.Match_Response__c,Customer__r.Duplicate_Customer_Source__c from Application_Applicant__c where Customer__c =:acc[0].id and Customer__r.Customer_LMS_Id__c!=null];
        //     }
        //     else{
        //         appList= [Select id,Customer__c,Gender__c,Drivers_License_Number__c,PAN_Number__c,Mobile_Number__c,DOB__c,Customer__r.Customer_LMS_Id__c,Customer__r.Name,Customer__r.UCIC_Number__c,Customer__r.Match_Response__c,Customer__r.Duplicate_Customer_Source__c from Application_Applicant__c where id=:applicantId and Customer__r.Customer_LMS_Id__c!=null];
        //     }
        // }
        
        /*if(accList.size()>0){
            for(Account acc :accList ){
                DeDupeWrapper dupWrapper = new DeDupeWrapper();
                dupWrapper.name = acc.Name ;
                dupWrapper.customerId =acc.Customer_LMS_Id__c;
                dupWrapper.dob =String.valueof(acc.Date_Of_Birth__c);
                dupWrapper.gender =acc.Gender__c;
                dupWrapper.panNumber = acc.PAN_Number__c;
                dupWrapper.mobileNumber = acc.Mobile_Number_Masked__c;
                dupWrapper.matchReason = (acc.Match_Response__c != null) ? acc.Match_Response__c.split('\\|')[0] : null;
                dupWrapper.accId = acc.Id ;
                dupWrapper.isFromSFDC =acc.Duplicate_Customer_Source__c=='PLF'?true:false;
                dupWrapper.customerType  =acc.Customer_Type__c;
                dupWrapper.sourceSystem =acc.Duplicate_Customer_Source__c;
                dupWrapper.dispositionStatus  =acc.Dedupe_Disposition__c;
                dupWrapper.dispositionRemarks  =acc.Dedupe_Disposition_Remarks__c;
                dupWrapper.custLink = URL.getOrgDomainURL().toExternalForm() + '/' +acc.id;
                dupList.add(dupWrapper);

            }
        }*/
        //     DeDupeWrapper dupWrapper = new DeDupeWrapper();
        //     dupWrapper.name = appList[0].Customer__r.Name ;
        //     dupWrapper.customerId = appList[0].Customer__r.Customer_LMS_Id__c;
        //     dupWrapper.mobileNumber =appList[0].Mobile_Number__c;
        //     dupWrapper.dob = String.valueof(appList[0].DOB__c);
        //     dupWrapper.panNumber = appList[0].PAN_Number__c;
        //     // dupWrapper.ucic  = appList[0].Customer__r.UCIC_Number__c;
        //     dupWrapper.gender = appList[0].Gender__c;
        //     dupWrapper.custLink = URL.getOrgDomainURL().toExternalForm() + '/' +appList[0].Customer__c;
        //     dupList.add(dupWrapper);
        // }
        // else if(custId!=null && appList.size()==0){

        // }
        // else if(appList.size()>0 && (applicantId==null)){
        //     for(Application_Applicant__c app :appList ){
        //         DeDupeWrapper dupWrapper = new DeDupeWrapper();
        //         dupWrapper.name = app.Customer__r.Name ;
        //         dupWrapper.customerId = app.Customer__r.Customer_LMS_Id__c;
        //         dupWrapper.mobileNumber =app.Mobile_Number__c;
        //         dupWrapper.dob = String.valueof(app.DOB__c);
        //         dupWrapper.panNumber =app.PAN_Number__c;
        //         dupWrapper.ucic  = app.Customer__r.UCIC_Number__c;
        //         dupWrapper.gender =app.Gender__c;
        //         dupWrapper.custLink = URL.getOrgDomainURL().toExternalForm() + '/' +app.Customer__c;
        //         dupList.add(dupWrapper);

        //     }
        
        return dupList;
    }

    public class LoanDetailsWrapper{
        @AuraEnabled public String loanNum;
    }
    public class DeDupeWrapper{
        @AuraEnabled public String customerId;
        @AuraEnabled public String name;
        @AuraEnabled public Date loanCreatedDate;
        @AuraEnabled public String loanNum;
        @AuraEnabled public String loanLink;
        @AuraEnabled public Boolean loanFromSfdc;
        @AuraEnabled public String mobileNumber;
        @AuraEnabled public String panNumber;
        @AuraEnabled public String dob;
        @AuraEnabled public String custLink;
        @AuraEnabled public String ucic;
        @AuraEnabled public String gender;
        @AuraEnabled public String matchReason;
        @AuraEnabled public String accId;
        @AuraEnabled public String customerType;
        @AuraEnabled public String sourceSystem;
        @AuraEnabled public String dispositionStatus;
        @AuraEnabled public String dispositionRemarks;
        @AuraEnabled public Boolean isFromSFDC;
        @AuraEnabled public String DL;
        @AuraEnabled public String product;
        @AuraEnabled public String stage;
        @AuraEnabled public String status;
        @AuraEnabled public Integer uniqueCount;
        @AuraEnabled public String selectedValue;
        @AuraEnabled public String custUniqueId;
        @AuraEnabled public Boolean isCoApplicant;
        @AuraEnabled public Map<String, String> applicantOptions;
    }
    @AuraEnabled
    public static String createLoanAndAppDet(String panNumber, String leadId){
        String loanId;
        List<Application_Applicant__c> apDetList = [Select Id, Customer__c, Customer__r.Customer_LMS_Id__c, PAN_Number__c from Application_Applicant__c where PAN_Number__c =: panNumber and Customer__r.Customer_LMS_Id__c != null];
        if(apDetList.size()>0){
            loanId = createLoanFromLead(leadId,false, apDetList[0].Customer__c);
        }
        else{
            loanId = createLoanFromLead(leadId,true,null);
        }
        return loanId;
    }


@AuraEnabled
public static ReturnWrapper checkSFDedupe(String panNumber, String applicantId, String loanId) {
    ReturnWrapper rw = new ReturnWrapper();
    Application_Applicant__c existingApplicant;
    Account existingApplicantAccount;
    Set<Id> propCustIdSet = new Set<Id>();
    List<Account> recordsToUpdate = new List<Account>();
    List<Account> accountsToUpsert = new List<Account>();
    List<String> ucicIds = new List<String>();
    List<String> custIds = new List<String>();
    String custUniqueID;
    String customerDuplicateId;
    String custCustomerId;
    Boolean executeUpdate = false;
    Map<String, Integer> matchCounts = new Map<String, Integer>{
        'pan' => 0, 'aadhaar' => 0, 'voter' => 0, 'driving' => 0, 'passport' => 0
    };
    Boolean multiMatchHandled = false;
    Boolean panMatchFound = false;

    List<Application_Applicant__c> sameLoanApplicants = [
        SELECT Id, Customer__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId
    ];
    for (Application_Applicant__c app : sameLoanApplicants) {
        propCustIdSet.add(app.Customer__c);
    }

    existingApplicant = String.isBlank(applicantId) 
        ? [SELECT Id, Aadhaar_DOB__c,PAN_DOB__c,DOB__c, Customer__c, Drivers_License_Number__c, Voter_ID_Number__c,
             Pan_Name__c, DOI__c, Customer_Type__c, PAN_Number__c, Name_of_Organization__c, First_Name__c, 
             Middle_Name__c, Last_Name__c, Mobile_Number__c, Aadhaar_Number__c, Passport_Number__c, Aadhaar_Number_Masked__c, Gender__c,Aadhaar_First_Name__c,Aadhaar_Middle_Name__c,Aadhaar_Last_Name__c,
              UCIC_Type__c, UCIC_Number__c
           FROM Application_Applicant__c WHERE Loan_Application__c = :loanId LIMIT 1]
        : [SELECT Id, DOB__c, Customer__c, Drivers_License_Number__c, Voter_ID_Number__c,
             Pan_Name__c,Aadhaar_DOB__c,PAN_DOB__c, DOI__c, Customer_Type__c, PAN_Number__c, Name_of_Organization__c, First_Name__c, 
             Middle_Name__c, Last_Name__c, Mobile_Number__c, Aadhaar_Number__c, Passport_Number__c, Aadhaar_Number_Masked__c, Gender__c,Aadhaar_First_Name__c,Aadhaar_Middle_Name__c,Aadhaar_Last_Name__c,
              UCIC_Type__c, UCIC_Number__c
           FROM Application_Applicant__c WHERE Id = :applicantId LIMIT 1];

    if (!String.isBlank(applicantId)) {
        existingApplicantAccount = [
            SELECT Id, Name, Gender__c, Match_Response__c, CustUniqueId__c, Customer_LMS_Id__c,
                   Pan_Number__c, Date_of_Birth__c, Duplicate_Customer_Source__c, Description,
                    UCIC_Type__c, Mobile_Number__c, Aadhaar_Number__c,UCIC_Number__c,
                   Voter_ID_Number__c, Passport_File_Number__c, Drivers_License_Number__c
            FROM Account WHERE Id = :existingApplicant.Customer__c LIMIT 1
        ];
    }

    custUniqueID = existingApplicant.Id;
    for (Application_Applicant__c ap : [
        SELECT Id FROM Application_Applicant__c 
        WHERE Customer__c = :existingApplicant.Customer__c AND Id != :existingApplicant.Id
    ]) {
        custUniqueID += ',' + ap.Id;
    }

    List<Applicant_Address__c> appAddresses = [
        SELECT Full_Address1__c 
        FROM Applicant_Address__c 
        WHERE Applicant__c = :existingApplicant.Id AND Full_Address1__c != null
    ];
    List<String> fullAddresses = new List<String>();
    for (Applicant_Address__c aa : appAddresses) fullAddresses.add(aa.Full_Address1__c);

    List<Customer_Address__c> matchedCustAddresses = [
        SELECT Customer__c, Customer__r.Applicant_Identifier__c 
        FROM Customer_Address__c 
        WHERE Full_Address1__c IN :fullAddresses AND Customer__c NOT IN :propCustIdSet
    ];

    String panName;

    if (!String.isBlank(existingApplicant.Pan_Name__c)) {
        panName = existingApplicant.Pan_Name__c.trim();
    } else {
        // Collect only non-blank normal names
        List<String> nameParts = new List<String>();
        if (!String.isBlank(existingApplicant.First_Name__c)) {
            nameParts.add(existingApplicant.First_Name__c.trim());
        }
        if (!String.isBlank(existingApplicant.Middle_Name__c)) {
            nameParts.add(existingApplicant.Middle_Name__c.trim());
        }
        if (!String.isBlank(existingApplicant.Last_Name__c)) {
            nameParts.add(existingApplicant.Last_Name__c.trim());
        }
        panName = String.join(nameParts, ' ');

        // If still blank, collect Aadhaar name parts
        if (String.isBlank(panName)) {
            List<String> aadhaarParts = new List<String>();
            if (!String.isBlank(existingApplicant.Aadhaar_First_Name__c)) {
                aadhaarParts.add(existingApplicant.Aadhaar_First_Name__c.trim());
            }
            if (!String.isBlank(existingApplicant.Aadhaar_Middle_Name__c)) {
                aadhaarParts.add(existingApplicant.Aadhaar_Middle_Name__c.trim());
            }
            if (!String.isBlank(existingApplicant.Aadhaar_Last_Name__c)) {
                aadhaarParts.add(existingApplicant.Aadhaar_Last_Name__c.trim());
            }
            panName = String.join(aadhaarParts, ' ');
        }
    }


    String dobOrdoi = existingApplicant.DOB__c != null
    ? String.valueOf(existingApplicant.DOB__c)
    : (existingApplicant.Aadhaar_DOB__c != null
        ? String.valueOf(existingApplicant.Aadhaar_DOB__c)
        : (existingApplicant.PAN_DOB__c != null
            ? String.valueOf(existingApplicant.PAN_DOB__c)
            : (existingApplicant.DOI__c != null
                ? String.valueOf(existingApplicant.DOI__c)
                : null)));


    // --- Callout #1 (already before any DML) ---
    Map<String, String> inputMap = new Map<String, String>{
        'loanId' => loanId,
        'applicantId' => existingApplicant.Id,
        'processName' => 'UCIC De Dupe Check',
        'panNumber' => existingApplicant.PAN_Number__c,
        'panName' => panName,
        'dob' => dobOrdoi,
        'mobileNumber' => String.valueOf(existingApplicant.Mobile_Number__c),
        'dlNumber' => existingApplicant.Drivers_License_Number__c,
        'voterNumber' => existingApplicant.Voter_ID_Number__c,
        'aadharNumber' => Utility.getDecryptedBase64String(existingApplicant.Aadhaar_Number_Masked__c),
        'passportNumber' => existingApplicant.Passport_Number__c,
        'gender' => existingApplicant.Gender__c
    };

    List<String> custIdExisiting = new List<String>();
    Map<String, Account> custToAccountMap = new Map<String, Account>();
    List<Account> accList = new List<Account>();

    String resp = COMM_UCICController.initiateAPIRequest(inputMap); // callout
    if (resp.contains('error')) {
        throw new AuraHandledException('Error while Checking Dedupe: ' + resp);
    }

    COMM_UCICController.UCICDeduplicationInfo dedupeInfo =
        (COMM_UCICController.UCICDeduplicationInfo) JSON.deserialize(resp, COMM_UCICController.UCICDeduplicationInfo.class);

    for (COMM_UCICController.CustomerMatch match : dedupeInfo.duplicateCustomers) {
        String decodedReason = match.matchReason != null ? match.matchReason.replaceAll('&#124;', '|').toLowerCase() : '';
        for (String key : matchCounts.keySet()) if (decodedReason.contains(key)) matchCounts.put(key, matchCounts.get(key) + 1);
        if (!String.isBlank(match.customerId)) custIdExisiting.add(match.customerId);
    }

    accList = [
        SELECT Id, Name, Gender__c, Match_Response__c, CustUniqueId__c, Customer_LMS_Id__c,
               Pan_Number__c, Date_of_Birth__c, Duplicate_Customer_Source__c, Description
        FROM Account 
        WHERE Customer_LMS_Id__c IN :custIdExisiting AND Is_Active__c = true
    ];
    for (Account a : accList) {custToAccountMap.put(a.Customer_LMS_Id__c, a);}

    for (COMM_UCICController.CustomerMatch match : dedupeInfo.duplicateCustomers) {
        String decodedReason = match.matchReason != null ? match.matchReason.replaceAll('&#124;', '|').toLowerCase() : '';
        Boolean isAnyMatch = false;
        for (String key : matchCounts.keySet()) { if (decodedReason.contains(key)) { isAnyMatch = true; break; } }

        Integer maxMatchCount = 0; String maxMatchType = '';
        for (String key : matchCounts.keySet()) {
            if (matchCounts.get(key) > maxMatchCount) { maxMatchCount = matchCounts.get(key); maxMatchType = key; }
        }

        if (isAnyMatch && maxMatchCount > 0 && existingApplicantAccount != null) {
            String multiMatchType = maxMatchType.capitalize();
            if (multiMatchType == 'Aadhar') multiMatchType = 'Aadhaar';
            else if (multiMatchType == 'driving') multiMatchType = 'DL';
            else if (multiMatchType == 'voter') multiMatchType = 'Voter Id';
            else if (multiMatchType == 'passport') multiMatchType = 'Passport';
            else if (multiMatchType == 'pan') multiMatchType = 'Pan';

            // Stage updates (NO DML yet)
            existingApplicantAccount.Customer_LMS_Id__c = match.customerId;
            existingApplicantAccount.Description = 'Created from UCIC Deduplication ' + multiMatchType.capitalize() + ' match';
            existingApplicantAccount.Duplicate_Customer_Source__c = 'PLF';
            existingApplicantAccount.Match_Response__c = match.matchReason;
            if (existingApplicantAccount.CustUniqueId__c == null || !existingApplicantAccount.CustUniqueId__c.contains(custUniqueID)) {
                existingApplicantAccount.CustUniqueId__c =
                    (existingApplicantAccount.CustUniqueId__c == null ? '' : existingApplicantAccount.CustUniqueId__c + ',') + custUniqueID;
            }
            recordsToUpdate.add(existingApplicantAccount);

            rw.freshCustomer = false;
            multiMatchHandled = true;
            executeUpdate = true;
            custCustomerId = match.customerId; // used for second callout
        }

        if (!custToAccountMap.isEmpty()) {
            Account acc = new Account();
            if (custToAccountMap.containsKey(match.customerId)) acc.Id = custToAccountMap.get(match.customerId).Id;
            acc.Name = match.name != null ? match.name : 'Unknown Customer';
            acc.Customer_LMS_Id__c = match.customerId;
            acc.PAN_Number__c = match.panNumber;
            acc.Mobile_Number__c = match.mobileNumber;
            acc.Date_of_Birth__c = match.dob;
            acc.Gender__c = match.gender == 'M' ? 'Male' : (match.gender == 'F' ? 'Female' : 'Transgender');
            acc.Duplicate_Customer_Source__c = 'PLF';
            acc.Match_Response__c = match.matchReason;
            acc.UCIC_Number__c = match.UCIC;
            acc.Description = 'Created from UCIC Deduplication (' + maxMatchType.capitalize() + ' match)';
            if (custToAccountMap.containsKey(match.customerId)) {
                Account existingAcc = custToAccountMap.get(match.customerId);
                if (!String.isBlank(existingAcc.CustUniqueId__c)) {
                    acc.CustUniqueId__c = existingAcc.CustUniqueId__c + ',' + existingApplicant.Id;
                } else {
                    acc.CustUniqueId__c = String.valueOf(existingApplicant.Id);
                }
            } else {
                acc.CustUniqueId__c = String.valueOf(existingApplicant.Id);
            }
            accountsToUpsert.add(acc);
            rw.freshCustomer = false;
            rw.custId = match.customerId;
        }
    }

    // -------------------------
    // Callout #2 BEFORE ANY DML
    // -------------------------
    if (executeUpdate) {
        // This is the callout that used to throw "uncommitted work pending"
        updateCustomerDetails(custCustomerId, applicantId, panNumber, custUniqueID, 'PLF', '');
    }

    // -------------------------
    // DML PHASE (all DML happens after BOTH callouts)
    // -------------------------

    if (!accountsToUpsert.isEmpty()) {
        upsert accountsToUpsert;
    }

    if (!recordsToUpdate.isEmpty()) {
        Map<Id, Account> mapOfAccToUpdate = new Map<Id, Account>();
        for (Account objAcc : recordsToUpdate) mapOfAccToUpdate.put(objAcc.Id, objAcc);
        for (Account acc : mapOfAccToUpdate.values()) {
            if (acc.CustUniqueId__c != null && acc.CustUniqueId__c.length() > 255) {
                acc.CustUniqueId__c = acc.CustUniqueId__c.substring(0, 255);
            }
        }
        update mapOfAccToUpdate.values();
    }

    // Fallback to Salesforce-based deduplication logic
    List<Account> sfdcAccountMatches = [
        SELECT Id, CustUniqueId__c, PAN_Number__c, Aadhar_Number__c, Voter_ID_Number__c, Passport_File_Number__c,
               Mobile_Number__c, Date_of_Birth__c, Name
        FROM Account
        WHERE Id != :existingApplicant.Customer__c AND Is_Active__c = true
        AND (
            (PAN_Number__c != null AND PAN_Number__c = :existingApplicant.PAN_Number__c) OR
            (Aadhar_Number__c != null AND Aadhar_Number__c = :existingApplicant.Aadhaar_Number__c) OR
            (Voter_ID_Number__c != null AND Voter_ID_Number__c = :existingApplicant.Voter_ID_Number__c) OR
            (Passport_File_Number__c != null AND Passport_File_Number__c = :existingApplicant.Passport_Number__c) OR
            (Mobile_Number__c = :existingApplicant.Mobile_Number__c AND Date_of_Birth__c = :existingApplicant.DOB__c 
             AND Name = :panName AND Mobile_Number__c != null AND Date_of_Birth__c != null AND Name != null)
        )
    ];

    if (!sfdcAccountMatches.isEmpty()) {
        for (Account matchedAcc : sfdcAccountMatches) {
            matchedAcc.Duplicate_Customer_Source__c = 'Salesforce';
            List<String> reasons = new List<String>();
            if (matchedAcc.PAN_Number__c == existingApplicant.PAN_Number__c && matchedAcc.PAN_Number__c != null && existingApplicant.PAN_Number__c != null) reasons.add('PAN');
            if (matchedAcc.Aadhar_Number__c == existingApplicant.Aadhaar_Number__c && matchedAcc.Aadhar_Number__c != null && existingApplicant.Aadhaar_Number__c != null) reasons.add('Aadhaar');
            if (matchedAcc.Voter_ID_Number__c == existingApplicant.Voter_ID_Number__c && matchedAcc.Voter_ID_Number__c != null && existingApplicant.Voter_ID_Number__c != null) reasons.add('Voter');
            if (matchedAcc.Passport_File_Number__c == existingApplicant.Passport_Number__c && matchedAcc.Passport_File_Number__c != null && existingApplicant.Passport_Number__c != null) reasons.add('Passport');
            if (matchedAcc.Mobile_Number__c == existingApplicant.Mobile_Number__c && matchedAcc.Date_of_Birth__c == existingApplicant.DOB__c 
                && matchedAcc.Name == panName && matchedAcc.Mobile_Number__c != null && existingApplicant.Mobile_Number__c != null 
                && matchedAcc.Date_of_Birth__c != null && existingApplicant.DOB__c != null && matchedAcc.Name != null) {
                reasons.add('Mobile + DOB + Name');
            }
            matchedAcc.Match_Response__c = String.join(reasons, ', ');

            if (matchedAcc.CustUniqueId__c == null || !matchedAcc.CustUniqueId__c.contains(custUniqueID)) {
                matchedAcc.CustUniqueId__c = (matchedAcc.CustUniqueId__c == null ? '' : matchedAcc.CustUniqueId__c + ',') + custUniqueID;
            }
            recordsToUpdate.add(matchedAcc);
            rw.freshCustomer = false;
            rw.custId = matchedAcc.Id;
        }
        update recordsToUpdate;
    }

    if (matchedCustAddresses.size() > 0) {
        custUniqueID = applicantId;
        List<Account> custAccList = new List<Account>();
        for (Customer_Address__c cust : matchedCustAddresses) {
            Account accCustomer = new Account();
            accCustomer.Id = cust.Customer__c;
            if (cust.Customer__r.CustUniqueId__c != null) {
                if (!cust.Customer__r.CustUniqueId__c.contains(custUniqueID)) {
                    accCustomer.CustUniqueId__c = cust.Customer__r.CustUniqueId__c + ',' + custUniqueID;
                }
            } else {
                accCustomer.CustUniqueId__c = custUniqueID;
            }
            accCustomer.Match_Response__c = 'Address';
            custAccList.add(accCustomer);
            customerDuplicateId = custUniqueID;
            rw.freshCustomer = false;
        }
        update custAccList;
    }

    // UCIC sync (also DML, so keep after callouts)
    if (dedupeInfo.ucicId != null) {
        //if (existingApplicant.UCIC_Number__c != dedupeInfo.ucicId) {
            //existingApplicant.UCIC_Number__c = dedupeInfo.ucicId;
            existingApplicant.UCIC_Type__c  = dedupeInfo.ucicType;
            update existingApplicant;
       // }
        if (existingApplicantAccount != null && existingApplicantAccount.UCIC_Number__c != dedupeInfo.ucicId) {
            existingApplicantAccount.UCIC_Number__c = dedupeInfo.ucicId;
            existingApplicantAccount.UCIC_Type__c  = dedupeInfo.ucicType;
            update existingApplicantAccount;
        }
    }

    rw.loanId = loanId;
    return rw;
}




    // @AuraEnabled
    // public static void updateCustomerDetails(String custId, String applicantId, String panNumber,String custUniqueID,String source,String accountId){
    //     Map<String, List<Integration_Mapping__mdt>> groupByMap = new Map<String, List<Integration_Mapping__mdt>>();
    //     for (Integration_Mapping__mdt mapping : integrationMappings) {
    //         if (!groupByMap.containsKey(mapping.GroupBy__c)) {
    //             groupByMap.put(mapping.GroupBy__c, new List<Integration_Mapping__mdt>());
    //         }
    //         groupByMap.get(mapping.GroupBy__c).add(mapping);
    //     }
      
    //     if(custId!=null ){
    //         GetCustomerController.Response  custRespnse =(GetCustomerController.Response)JSON.deserialize(GetCustomerController.getCustomerDetails(custId,'Get Customer'),GetCustomerController.Response.class);
    //     System.debug('custRespnse----'+custRespnse);
        
    //     List<Application_Applicant__c> appList =[Select id,Customer_Type__c,Customer__c,Customer__r.CustUniqueId__c,Customer__r.Exisiting_Customer__c ,First_Name__c,Last_Name__c,Pan_Name__c,PAN_Number__c,Pan_OCR_Confirmed__c, Loan_Application__c,
    //                                              DOB__c from Application_Applicant__c where id=:applicantId];
    //     Customer_Address__c newCustomerAddress = new Customer_Address__c();
    //     Applicant_Address__c addr = new Applicant_Address__c();
    //     List<Applicant_Address__c> appAddresses = [Select id,Customer_Address__c,Address_Type__c from Applicant_Address__c where Applicant__c =:appList[0].Id and Address_Type__c = ];
    //     System.debug('custRespnse----'+custRespnse);
    //     String inputDate = String.valueOf(custRespnse.personalInfo.dateofBirth);
    //     Date parsedDate = Date.newInstance(Integer.valueOf(inputDate.substring(0, 4)),Integer.valueOf(inputDate.substring(5, 7)),Integer.valueOf(inputDate.substring(8, 10))); 
    //     System.debug('custUniqueID------' +custUniqueID);
    //     appList[0].PAN_Number__c = panNumber;
    //     appList[0].Pan_Name__c = custRespnse.personalInfo.shortName;
    //     appList[0].DOB__c = parsedDate;
     
    //     List<String> nameParts = custRespnse.personalInfo.shortName.trim().split(' ');
    //     // if(customerType!=null && customerType.equalsIgnoreCase('Individual')){  
    //         appList[0].First_Name__c = nameParts[0];
    //     if (nameParts.size() == 3) {
    //         appList[0].Middle_Name__c = nameParts[1];
    //         appList[0].Last_Name__c = nameParts[2];
    //     } else if (nameParts.size() == 2) {
    //         appList[0].Last_Name__c = nameParts[1];
    //         appList[0].Middle_Name__c = '';
    //     } else {
    //         appList[0].Last_Name__c =  appList[0].First_Name__c;
    //         appList[0].Middle_Name__c = '';
    //     }
    // //    First_Name__c = custRespnse.personalInfo.firstName;
    //     // appList[0].Last_Name__c = custRespnse.personalInfo.lastName;
    //     appList[0].Mobile_Number__c = custRespnse.phones[0].phoneNumber;
    //         if(custRespnse.personalInfo.gender== 'F' ){
    //             appList[0].Gender__c ='Female'; 
    //         }
    //         else if(custRespnse.personalInfo.gender== 'M'){
    //             appList[0].Gender__c ='Male'; 
    //         }
    //         else{
    //              appList[0].Gender__c ='';
    //         }
       
        
    //     //appList[0].Customer__r.Customr =custId;
    //     // appList[0].Customer__r.Name =custRespnse.personalInfo.shortName; 
    //     // appList[0].Customer__r.Date_of_Birth__c  = parsedDate;
    //     // appList[0].Customer__r.Pan_Number__c = panNumber;
    //     // appList[0].Customer__r.Mobile_Number__c = custRespnse.phones[0].phoneNumber;
    //     // appList[0].Customer__r.Exisiting_Customer__c = true;
        
    //     System.debug('appList------' +appList);
       
    //     List<Account> accountList = [Select id,Date_of_Birth__c,Customer_LMS_Id__c,CustUniqueId__c,Match_Response__c,Duplicate_Customer_Source__c,Pan_Number__c,Mobile_Number__c,Exisiting_Customer__c from Account where Customer_LMS_Id__c =:custId AND Customer_Type__c=:  appList[0].Customer_Type__c];
    //     accountList[0].Name =custRespnse.personalInfo.shortName; 
    //     accountList[0].Date_of_Birth__c  = parsedDate;
    //     if(panNumber!=null){
    //         accountList[0].Pan_Number__c = panNumber;
    //     }
       
    //     accountList[0].Gender__c = custRespnse.personalInfo.gender;
    //     accountList[0].Mobile_Number__c = custRespnse.phones[0].phoneNumber;
    //     accountList[0].Exisiting_Customer__c = true;

    //     if(source!=null){
    //         accountList[0].Duplicate_Customer_Source__c = source;
    //     }else if( accountList[0].Duplicate_Customer_Source__c == null ){
    //         accountList[0].Duplicate_Customer_Source__c  ='PLF';
    //     }
       
      
    //     accountList[0].Customer_LMS_Id__c =custId;
    //     if( accountList[0].CustUniqueId__c != null){
    //         if(!accountList[0].CustUniqueId__c.contains(custUniqueID)){
    //             accountList[0].CustUniqueId__c = accountList[0].CustUniqueId__c +',' +custUniqueID;
    //          }
    //     }
    //     else{
    //         accountList[0].CustUniqueId__c = custUniqueID;
    //     }
        
    //     //accountList.CustUniqueId__c=custUniqueID;
    //     accountList[0].Match_Response__c = 'Pan|Rule0';
    //     if(accountList!=null){
    //         update accountList;
    //         System.debug('accountList------' +accountList);
    //     }
    //     appList[0].Customer__c = accountList[0].Id;
    //     upsert appList[0];
    //     System.debug('appAddresses----'+appAddresses);
    //     if(appAddresses.size()>0){
    //         addr.id = appAddresses[0].id;
    //         if(appAddresses[0].Customer_Address__c!=null){
    //             newCustomerAddress.id = appAddresses[0].Customer_Address__c;
    //         }
    //         System.debug('appAddresses----'+appAddresses);
    //     }
    //     else{
    //         newCustomerAddress.Customer__c = appList[0].Customer__c; 
    //         newCustomerAddress.Address_Type__c = 'Permanent';
    //         System.debug('newCustomerAddress----'+newCustomerAddress);
    //     }
    //     upsert newCustomerAddress;
    //     addr.Loan_Application__c = appList[0].Loan_Application__c;
    //     addr.Applicant__c = appList[0].Id;
    //     addr.Address_Type__c = 'Permanent';
    //     addr.Building_Street_Name__c =  custRespnse.addresses[0].buildingNo;
    //     addr.Reference_Address_1__c = custRespnse.addresses[0].addrLine1;
    //     System.debug('newCustomerAddress 408----'+newCustomerAddress);
        
    //     addr.Post_Office_Name__c = custRespnse.addresses[0].poBox;
    //     addr.Customer_Address__c = newCustomerAddress.Id;
        
    //     upsert addr;
    //     if(appList[0].Customer__c != null){
    //         List<Account> acc = [Select Id, Customer_LMS_Id__c from Account where id =: appList[0].Customer__c];
    //         if(acc.size()>0 && acc[0].Customer_LMS_Id__c == null){
    //             acc[0].Customer_LMS_Id__c = custId;
    //             update acc;
    //         }
    //     }

    //     }
    //     else{
    //        List<Account> sfdcAccount =[Select id,Gender__c,Name,Date_of_Birth__c,Customer_LMS_Id__c,CustUniqueId__c,Match_Response__c,Duplicate_Customer_Source__c,Pan_Number__c,Mobile_Number__c,Exisiting_Customer__c from Account where id=:accountId ];
    //         Application_Applicant__c appDetails=new Application_Applicant__c();
    //             appDetails.id=applicantId;
    //             appDetails.Pan_Name__c = sfdcAccount[0].Name;
    //             appDetails.Pan_Number__c  = sfdcAccount[0].Pan_Number__c;
    //             if(appDetails.Customer_Type__c == 'Individual'){
    //                     appDetails.DOB__c  =sfdcAccount[0].Date_Of_Birth__c;
    //             }
    //             else{
    //                 appDetails.DOI__c =sfdcAccount[0].Date_Of_Birth__c;
    //             }
    //             if(sfdcAccount[0].Gender__c!= null){
    //                 appDetails.Gender__c =sfdcAccount[0].Gender__c;
    //             }
    //             if(sfdcAccount[0].Mobile_Number__c!= null){
    //                 appDetails.Mobile_Number__c =sfdcAccount[0].Mobile_Number__c;
    //             }
    //             appDetails.Customer__c =sfdcAccount[0].id;
    //             update appDetails;
    //             // if(sfdcAccount[0].CustUniqueId__c!= null ){
    //             //     sfdcAccount[0].CustUniqueId__c = sfdcAccount[0].CustUniqueId__c +','+ applicantId;
    //             // }
    //             // else{
    //             //     sfdcAccount[0].CustUniqueId__c =  applicantId;
    //             // }
    //             // update sfdcAccount;
                
                
    //         }

        
        
    // }


    @AuraEnabled
    public static void updateCustomerDetails(String custId, String applicantId, String panNumber, String custUniqueID, String source, String accountId) {
        // Grouping Integration Mappings
        System.debug('custId---'+custId);
        String ucic;
        List<Integration_Mapping__mdt> integrationMappings = [
            SELECT MasterLabel, Source_Value__c, Target_Value__c, GroupBy__c 
            FROM Integration_Mapping__mdt 
            WHERE GroupBy__c = 'Address_Type__c'
        ];
        System.debug('integrationMappings>>'+integrationMappings);
    
        if (custId != null) {
            if(custId.contains(',')){
                System.debug('custId---'+custId);
                List<String> split =custId.split(',');
                custId= split[0];
                System.debug('custId---'+custId);
                ucic= split[1];
                System.debug('ucic---'+ucic);
            }
            List<Account> accToBeTagged = [Select id, Customer_LMS_Id__c,Name,Pan_Number__c,Mobile_Number__c from Account where Customer_LMS_ID__c=:custId];
            System.debug('accToBeTagged>>'+accToBeTagged);
            // Deserialize response
            COMM_GetCustomerController.Response custRespnse = (COMM_GetCustomerController.Response) JSON.deserialize(COMM_GetCustomerController.getCustomerDetails(custId, 'Get Customer').respBody,COMM_GetCustomerController.Response.class);
            System.debug('custRespnse>>'+custRespnse);
     
            List<COMM_GetCustomerController.cls_addresses> addrFromRespList = custRespnse.addresses;
            System.debug('addrFromRespList>>'+addrFromRespList);

            List<Application_Applicant__c> appList = [
                SELECT Id, Customer_Type__c, Customer__c,Mobile_Number__c, First_Name__c, Last_Name__c, Middle_Name__c, Loan_Application__c 
                FROM Application_Applicant__c 
                WHERE Id = :applicantId
            ];
            System.debug('appList>>'+appList);
            // if (appList.isEmpty()) return;
            Application_Applicant__c app = appList[0];
            if(custRespnse.personalInfo!=null){
              
                app.Pan_Name__c = custRespnse.personalInfo.shortName;
                Date parsedDate = Date.valueOf(custRespnse.personalInfo.dateofBirth);
                app.DOB__c = parsedDate;
        
                List<String> nameParts = custRespnse.personalInfo.shortName.trim().split(' ');
                app.First_Name__c = nameParts[0];
                app.Middle_Name__c = (nameParts.size() == 3) ? nameParts[1] : '';
                app.Last_Name__c = (nameParts.size() >= 2) ? nameParts[nameParts.size() - 1] : '';
                if(custRespnse.phones!=null){
                    app.Mobile_Number__c = (custRespnse.phones != null && !custRespnse.phones.isEmpty()) 
                        ? custRespnse.phones[0].phoneNumber : null;
                }
                app.Gender__c = custRespnse.personalInfo.gender == 'F' ? 'Female' :
                                custRespnse.personalInfo.gender == 'M' ? 'Male' : '';
                
            }
          
            app.PAN_Number__c = panNumber;
            if(accToBeTagged.size()>0){
                app.Customer__c = accToBeTagged[0].id;
                List<Account> accountList = [
                SELECT Id, Date_of_Birth__c, Customer_LMS_Id__c, CustUniqueId__c, Match_Response__c, Name,
                       Duplicate_Customer_Source__c, Pan_Number__c, Mobile_Number__c, Exisiting_Customer__c, 
                       Gender__c 
                FROM Account 
                WHERE Customer_LMS_Id__c = : accToBeTagged[0].Customer_LMS_ID__c
                  AND Customer_Type__c = :app.Customer_Type__c
                    ];
                    if (!accountList.isEmpty()) {
                        Account acc = accountList[0];
                        if(custRespnse.personalInfo!=null){
                            Date parsedDate = Date.valueOf(custRespnse.personalInfo.dateofBirth);
                            acc.Date_of_Birth__c = parsedDate;
                            if(custRespnse.personalInfo.gender =='OTH'){
                                acc.Gender__c ='Transgender';                  
                            }
                            else if(custRespnse.personalInfo.gender =='F'){
                                acc.Gender__c ='Female';     
                            }
                            else if(custRespnse.personalInfo.gender =='M'){
                                acc.Gender__c ='Male';     
                            }
                            else{
                                acc.Gender__c = custRespnse.personalInfo.gender;
                            }
                        
                        }
                        else{
                           if (accountList != null && !accountList.isEmpty() && String.isNotBlank(accountList[0].Name)) {
                                List<String> nameParts = accountList[0].Name.trim().split(' ');
                                app.id  =applicantId;
                                 app.Pan_Name__c = accountList[0].Name;
                                if (nameParts.size() == 3) {
                                    app.First_Name__c = nameParts[0];
                                    app.Middle_Name__c = nameParts[1];
                                    app.Last_Name__c = nameParts[2];
                                } else if (nameParts.size() == 2) {
                                    app.First_Name__c = nameParts[0];
                                    app.Last_Name__c = nameParts[1];
                                } else if (nameParts.size() == 1) {
                                    app.First_Name__c = nameParts[0];
                                } 
                            }
                            if(String.isNotBlank(accountList[0].Mobile_Number__c)){
                                app.Mobile_Number__c =accountList[0].Mobile_Number__c;
                            }
                        }
                        acc.Pan_Number__c = panNumber;
                    
                        acc.Mobile_Number__c = app.Mobile_Number__c;
                      
                        acc.Duplicate_Customer_Source__c = (source != null) ? source : (acc.Duplicate_Customer_Source__c == null ? 'PLF' : acc.Duplicate_Customer_Source__c);
                        if(custId!=null){
                            acc.Customer_LMS_Id__c = custId;
                              acc.Exisiting_Customer__c = true;
                        }
                        if(ucic!=null){
                            acc.UCIC_Number__c = ucic;
                        }
                        acc.Match_Response__c = 'Pan|Rule0';
                        acc.CustUniqueId__c = (acc.CustUniqueId__c != null && !acc.CustUniqueId__c.contains(custUniqueID))
                                            ? acc.CustUniqueId__c + ',' + custUniqueID
                                            : (acc.CustUniqueId__c == null ? custUniqueID : acc.CustUniqueId__c);
                        update acc;
                        app.Customer__c = acc.Id;
                    }
            }
            Trigger_Bypass_Setting__c cs = Trigger_Bypass_Setting__c.getInstance(UserInfo.getUserId());
            if (cs == null) cs = new Trigger_Bypass_Setting__c(SetupOwnerId = UserInfo.getUserId());
            cs.Application_Applicant_Validation_ByPass__c = true;
            upsert cs;
    
            upsert app;

            cs.Application_Applicant_Validation_ByPass__c = false;
            update cs;
                            
            // Fetch existing Applicant Addresses
            Map<String, List<Applicant_Address__c>> existingAddressesMap = new Map<String, List<Applicant_Address__c>>();
            Map<String, List<Customer_Address__c>> existingCustAddressesMap = new Map<String, List<Customer_Address__c>>();
            Map<String,String> custAdd = new Map<String,String>();
            Set<Id> custAddId  = new Set<Id>();
            for (Applicant_Address__c addr : [SELECT Id, Address_Type__c, Customer_Address__c FROM Applicant_Address__c WHERE Applicant__c = :app.Id]) {
                if(existingAddressesMap.containsKey(addr.Address_Type__c)){
                    existingAddressesMap.get(addr.Address_Type__c).add(addr);
                   
                }
                else{
                    existingAddressesMap.put(addr.Address_Type__c,new List<Applicant_Address__c> {addr});
                }
                if(addr.Customer_Address__c!=null){
                    custAdd.put(addr.Customer_Address__c, addr.Address_Type__c);
                }
                
              
            }
            for(Customer_Address__c cust :[Select id, Address_Line_2__c,Address_Line_1__c,Address_Type__c from Customer_Address__c where id In : custAdd.keySet()]){
                String custAddType=custAdd.get(cust.id);
                if(existingCustAddressesMap.containsKey(custAddType)){
                    existingCustAddressesMap.get(custAddType).add(cust);
                   
                }
                else{
                    existingCustAddressesMap.put(custAddType,new List<Customer_Address__c> {cust});
                }
            }
    
            List<Applicant_Address__c> addressesToUpsert = new List<Applicant_Address__c>();
            List<Customer_Address__c> customerAddressesToUpsert = new List<Customer_Address__c>();
            Map<String, Id> customerAddressTypeToId = new Map<String, Id>();
    
            // Process address list from response
            if(addrFromRespList!=null && addrFromRespList.size()>0 ){
                for (COMM_GetCustomerController.cls_addresses addrFromResp : addrFromRespList) {
                    String mappedType = null;
                    for (Integration_Mapping__mdt mapping : integrationMappings) {
                        if (mapping.Source_Value__c == addrFromResp.addrType) {
                            mappedType = mapping.Target_Value__c;
                            break;
                        }
                    }
                    
                    Applicant_Address__c appAddrNew  = new Applicant_Address__c();
                    List<Applicant_Address__c> appAddr = existingAddressesMap.containsKey(mappedType)
                        ? existingAddressesMap.get(mappedType)
                        : new List<Applicant_Address__c>();
                    if(existingAddressesMap.containsKey(mappedType)){
                        for(Applicant_Address__c appAddList: appAddr){
                        
                            appAddList.Applicant__c = app.Id;
                            appAddList.Loan_Application__c = app.Loan_Application__c;
                            appAddList.Address_Type__c = mappedType;
                            appAddList.Address_Line_1__c = addrFromResp.buildingNo + addrFromResp.addrLine1;
                            appAddList.Address_Line_2__c = addrFromResp.addrLine2;
                            appAddList.Post_Office_Name__c = addrFromResp.poBox;
                
                            addressesToUpsert.add(appAddList);
                        }
                    }
                    else{
                        appAddrNew.Applicant__c = app.Id;
                        appAddrNew.Loan_Application__c = app.Loan_Application__c;
                        appAddrNew.Address_Type__c = mappedType;
                        appAddrNew.Address_Line_1__c = addrFromResp.buildingNo + addrFromResp.addrLine1;
                        appAddrNew.Address_Line_2__c = addrFromResp.addrLine2;
                        appAddrNew.Post_Office_Name__c = addrFromResp.poBox;
            
                        addressesToUpsert.add(appAddrNew);
    
                    }
                  
    
                  
                    List<Customer_Address__c> custAddr = new List<Customer_Address__c>();
                    Customer_Address__c custAddress = new Customer_Address__c();
                    if (existingCustAddressesMap.containsKey(mappedType)) {
                        custAddr =existingCustAddressesMap.get(mappedType);
                        for(Customer_Address__c custAddressList: custAddr){
                            custAddressList.Address_Line_1__c = addrFromResp.buildingNo;
                            custAddressList.Address_Line_2__c = addrFromResp.addrLine1;
                            //custAddressList.pinCode = addrFromResp.poBox;
                            if( addrFromResp.addrType=='EMPADD'){
                                custAddressList.Address_Type__c  = 'Employee Address';
                            }
                            // custAddressList.Address_Type__c  = addrFromResp.addrType;
                            if(!customerAddressesToUpsert.contains(custAddressList)){
                            	customerAddressesToUpsert.add(custAddressList);
                            }
                        }
                        // custAddr = [SELECT Id FROM Customer_Address__c WHERE Id IN : appAddr.Customer_Address__c LIMIT 1];
                    } else {
                        custAddress = new Customer_Address__c();
                        custAddress.Customer__c = app.Customer__c;
                        custAddress.Address_Type__c = mappedType;
                        custAddress.Address_Line_1__c = addrFromResp.buildingNo;
                        custAddress.Address_Line_2__c = addrFromResp.addrLine1;
                        if(!customerAddressesToUpsert.contains(custAddress)){
                        	customerAddressesToUpsert.add(custAddress);
                        }
                    }
                }

            }
           
            System.debug('customerAddressesToUpsert--------'+customerAddressesToUpsert);
            if(customerAddressesToUpsert.size()>0){
               // upsert customerAddressesToUpsert;
            }
           
    
            // Map Customer Address Ids back to Applicant_Address
            for (Customer_Address__c ca : customerAddressesToUpsert) {
                customerAddressTypeToId.put(ca.Address_Type__c, ca.Id);
            }
    
            for (Applicant_Address__c addr : addressesToUpsert) {
                addr.Customer_Address__c = customerAddressTypeToId.get(addr.Address_Type__c);
            }
            System.debug('addressesToUpsert--------'+addressesToUpsert);
            if(addressesToUpsert.size()>0){
               // upsert addressesToUpsert;
            }
    
            // Final fix for LMS ID
            if (app.Customer__c != null) {
                List<Account> accs = [SELECT Id,CustUniqueId__c,Pan_Number__c, Customer_LMS_Id__c,Duplicate_Customer_Source__c,UCIC_Number__c,Mobile_Number__c,Exisiting_Customer__c,Match_Response__c FROM Account WHERE Id = :app.Customer__c];
                Application_Applicant__c applicant =[Select id, Mobile_Number__c  from Application_Applicant__c where id = :app.id];
                if (!accs.isEmpty() && accs[0].Customer_LMS_Id__c == null) {
                    if(custId!=null){
                        accs[0].Customer_LMS_Id__c = custId;
                         accs[0].Exisiting_Customer__c = true;
                    }
                    if(ucic!=null){
                        accs[0].UCIC_Number__c = ucic;
                    }
                    // accs[0].Customer_LMS_Id__c = custId;
                    // accs[0].UCIC_Number__c = ucic;
                    accs[0].CustUniqueId__c=custUniqueID;
                    accs[0].Pan_Number__c = panNumber;
                    
                    accs[0].Mobile_Number__c = applicant.Mobile_Number__c;
                   
                    accs[0].Duplicate_Customer_Source__c = (source != null) ? source : (accs[0].Duplicate_Customer_Source__c == null ? 'PLF' : accs[0].Duplicate_Customer_Source__c);
                    accs[0].Match_Response__c = 'Pan|Rule0';
                    accs[0].CustUniqueId__c = (accs[0].CustUniqueId__c != null && !accs[0].CustUniqueId__c.contains(custUniqueID))
                                        ? accs[0].CustUniqueId__c + ',' + custUniqueID
                                        : (accs[0].CustUniqueId__c == null ? custUniqueID : accs[0].CustUniqueId__c);
                    update accs;
                }
            }
        }
        else {
            // Use fallback from SFDC if custId is null
            List<Account> sfdcAccount = [
                SELECT Id, Gender__c, Name, Date_of_Birth__c, Customer_LMS_Id__c, CustUniqueId__c, 
                       Match_Response__c, Duplicate_Customer_Source__c, Pan_Number__c, Mobile_Number__c, 
                       Exisiting_Customer__c 
                FROM Account 
                WHERE Id = :accountId
            ];
            if (!sfdcAccount.isEmpty()) {
                Application_Applicant__c appDetails = new Application_Applicant__c(Id = applicantId);
                appDetails.Pan_Name__c = sfdcAccount[0].Name;
                appDetails.PAN_Number__c = sfdcAccount[0].Pan_Number__c;
                appDetails.DOB__c = sfdcAccount[0].Date_of_Birth__c;
                appDetails.Gender__c = sfdcAccount[0].Gender__c;
                appDetails.Mobile_Number__c = sfdcAccount[0].Mobile_Number__c;
                appDetails.Customer__c = sfdcAccount[0].Id;
                update appDetails;
            }
        }
    }
    

    @AuraEnabled
    public static String createLoanFromLead(String leadId, Boolean createAccount, String custId){
        Lead leadRecord = [SELECT Id, Customer__c from Lead where id =:leadId];
        Set<String> leadFieldSet = new Set<String>();
        Map<String, String> leadAndLoanMapping = new Map<String, String>();
        Map<String,Lead_To_Loan__mdt> allMetaData = Lead_To_Loan__mdt.getAll();
        Map<String, String> leadAndCustomerMapping = new Map<String, String>();
        Map<String, String> leadAndAppAppMapping = new Map<String, String>();
        System.debug('allMetaData-->'+allMetaData);
        if(!allMetaData.values().isEmpty()) {
            for(Lead_To_Loan__mdt leadMappings : allMetaData.values()) {
                System.debug('leadMappings.Sobject__c=:'+leadMappings.Sobject__c);
                if (leadMappings.Sobject__c == 'Opportunity Field') {
                    leadAndLoanMapping.put(leadMappings.Lead_Field__c, leadMappings.Mapping_Field__c);
                    leadFieldSet.add(leadMappings.Lead_Field__c.tolowercase());
                }else if(leadMappings.Sobject__c == 'Customer Field') {
                    leadAndCustomerMapping.put(leadMappings.Lead_Field__c, leadMappings.Mapping_Field__c);
                    leadFieldSet.add(leadMappings.Lead_Field__c.tolowercase());
                }else if(leadMappings.Sobject__c == 'Application Applicant Field') {
                    leadAndAppAppMapping.put(leadMappings.Lead_Field__c, leadMappings.Mapping_Field__c);
                    leadFieldSet.add(leadMappings.Lead_Field__c.tolowercase());
                }
            } 
            
        }
        System.debug('leadAndAppAppMapping=:'+leadAndAppAppMapping);
        
        String fieldSet = String.join(leadFieldSet, ' , ');
        system.debug('fieldSet: '+fieldSet);
        
        String query = 'Select ' + fieldSet + ' from Lead WHERE Id = \'' + leadId + '\'';
        Lead leadObj = Database.query(query);
        
        leadFieldSet.clear();
        
        // Opportunity loanObj = new Opportunity();
        
        // for(String mappingVal : leadAndLoanMapping.keySet()){
        //     String fieldsName = (String)loanObj.put(leadAndLoanMapping.get(mappingVal), leadObj.get(mappingVal));
        // }
        
        
        // //initial loan record values assign here
        // insert loanObj;
        
        // leadAndLoanMapping.clear();
        String accId;
        if(createAccount && leadRecord.Customer__c == null){
            Account accObj = new Account();
            for(String mappingVal : leadAndCustomerMapping.keySet()){
                String fieldsName = (String)accObj.put(leadAndCustomerMapping.get(mappingVal), leadObj.get(mappingVal));
            }
            insert accObj;
            accId = accObj.Id;
        }
        
        leadAndCustomerMapping.clear();

        Opportunity loanObj = new Opportunity();
        
        for(String mappingVal : leadAndLoanMapping.keySet()){
            String fieldsName = (String)loanObj.put(leadAndLoanMapping.get(mappingVal), leadObj.get(mappingVal));
        }
        System.debug('loanObj 3657'+loanObj);
        System.debug('loanObj 3658'+leadRecord.Customer__c);
        if (leadRecord.Customer__c == null) {
            System.debug('3658');
            loanObj.AccountId = accId;
            System.debug('3659');
        }
    
        
        //initial loan record values assign here
        insert loanObj;
        System.debug('loanObj 3668'+leadRecord.Customer__c);
        if(leadRecord.Customer__c != null){
            System.debug('3665');
            loanObj.AccountId = leadRecord.Customer__c;
            Update loanObj;
        }
        
        leadAndLoanMapping.clear();
        
        Application_Applicant__c appApt = new Application_Applicant__c();
        
        for(String mappingVal : leadAndAppAppMapping.keySet()){
            System.debug('leadAndAppAppMapping.get(mappingVal)=:'+leadAndAppAppMapping.get(mappingVal));
            System.debug('leadObj.get(mappingVal)=:'+leadObj.get(mappingVal));
            String fieldsName = (String)appApt.put(leadAndAppAppMapping.get(mappingVal), leadObj.get(mappingVal));
        }
        
        appApt.Loan_Application__c = loanObj.Id;
        appApt.Applicant_Type__c = Constants__mdt.getInstance('Primary_Applicant').Value__c;
        // if(leadRecord.Customer__c == null || leadRecord.Customer__c == ''){
        if(createAccount){
            appApt.Customer__c = accId;
        }
        else{
            appApt.Customer__c = custId;
        }
    // }
        insert appApt;
        if(leadRecord.Customer__c != null){
        System.debug('leadRecord.Customer__c : '+leadRecord.Customer__c);
            appApt.Customer__c = leadRecord.Customer__c;
            Update appApt;
        }
        
        List<Document_Details__c> allLeadDocs = [SELECT Id, Loan_Application__c FROM Document_Details__c WHERE Lead__c =: leadId];
        if(allLeadDocs.size()>0){
            for(Document_Details__c iterDocs : allLeadDocs){
                iterDocs.Loan_Application__c = loanObj.Id;
            }
            update allLeadDocs;
        }
        Boolean insertappaddr = false;
        Lead ld = [Select Id,Pincode__c from Lead where id=:leadId];
        insertappaddr = SalesDocumentCmpController.insertApplicantAddress(loanObj.Id,appApt.Id,'Current',ld.Pincode__c,'','','');
        if(insertappaddr){
        System.debug('Applicant Address inserted succesfully');
        }
        else{
        System.debug('Error in inserting Applicant Address');
        }
        leadAndAppAppMapping.clear();
        
        leadObj.Status = Constants__mdt.getInstance('Closed').Value__c;
        leadObj.Lead_Sub_Status__c = Constants__mdt.getInstance('Converted').Value__c;
        leadObj.Closed_Reasons__c = Constants__mdt.getInstance('Converted_to_Loan_Application').Value__c;
        
        // LeadTriggerHandler.isTriggerDisabled = true;
        update leadObj;
        // LeadTriggerHandler.isTriggerDisabled = false;
        List<Product_Master__c> productMasterList = [SELECT Id, Name FROM Product_Master__c WHERE Name =: leadObj.Product__c LIMIT 1];
        if(productMasterList.size()>0){
            Id productRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
            Product2 prodRecord = new Product2();
            prodRecord.Name = productMasterList[0].Name;
            prodRecord.RecordTypeId = productRecordId;
            prodRecord.Loan_Application__c = loanObj.Id;
            prodRecord.Product_Master__c = productMasterList[0].Id;
            insert prodRecord;
        }
        return loanObj.Id;
    }

         @AuraEnabled
        public static Pincode_Master__c getPincodeDetails(String pinCode) {
            List<Pincode_Master__c> pinList = [
                SELECT Id, City__c, City__r.Name, City__r.State__c, City__r.Country__c
                FROM Pincode_Master__c
                WHERE Name = :pinCode
                LIMIT 1
            ];

            if (!pinList.isEmpty()) {
                return pinList[0];
            } else {
                return null; // This will be handled safely in LWC
            }
        }
    public class CustomerWrapper{
        @AuraEnabled public String custId;
        @AuraEnabled public String name;
        
    }
    
    public class ReturnWrapper{
        @AuraEnabled public String loanId;
        @AuraEnabled public String custId;
        @AuraEnabled public Boolean freshCustomer;
        
    }
    
    @AuraEnabled
    public static List<SubStageWrapper> getSubStageListApplicationInforamtion(String loanId, String applicableStage, String formName) {
        if(formName == null){
            formName = 'Loan Login Form';
        }
        if(formName.contains('\u2019')){
            formName = formName.replaceAll('\u2019','\'s');
        }
        if(applicableStage.contains('\u2019')){
            applicableStage = applicableStage.replaceAll('\u2019','\'s');
        }
        List<SubStageWrapper> subStageList = new List<SubStageWrapper>();
        Set<String> addedSubStages = new Set<String>(); 
        List<Screen_Field__c> screenDetails = new  List<Screen_Field__c>();
        System.debug('formName 3148'+formName);
        System.debug('applicableStage 3149'+applicableStage);
        System.debug('loanId 3150'+loanId);
        // Fetch screens based on the selected applicable stage
        if(formName !='Application Other Information'){
            screenDetails = [
                SELECT Id, Master_Screen_Name__c, Applicable_Login_Stage__c,Screen_Sequence__c
                FROM Screen_Field__c
                
                Where Is_Screen_Active__c = TRUE
                AND Form_Name__c =: formName
                AND Applicable_Login_Stage__c = :applicableStage
                AND Master_Screen_Name__c IN ('Additional Information')
                ORDER BY Screen_Sequence__c ASC
            ];
        }
        for (Screen_Field__c screen : screenDetails) {
            SubStageWrapper subWrap = new SubStageWrapper();
            if (screen.Master_Screen_Name__c!= null && !addedSubStages.contains(screen.Master_Screen_Name__c)) {
                subWrap.name = screen.Master_Screen_Name__c;
                subWrap.isCompleted =false; // Assuming this field tracks completion status
                subWrap.sequence = String.valueof(screen.Screen_Sequence__c);
                subStageList.add(subWrap);
                addedSubStages.add(screen.Master_Screen_Name__c);
            }
        }
        
        System.debug('subStage 3161'+subStageList);
        return subStageList;
    }
    
    @AuraEnabled
    public static Map<String,String> savePanDetailsManually(Map<String,String> inputMap){
        try {
            Map<String, String> response = new Map<String, String>();
            String panOCRConfirmed = (String) inputMap.get('panOCRConfirmed');
            String panName = (String) inputMap.get('panName');
            String applicantId = (String) inputMap.get('applicantId');
            String loanId = (String) inputMap.get('loanId');
            String userName = (String) inputMap.get('panName');
            String dob = (String) inputMap.get('dob');
            String fathersName = (String) inputMap.get('fatherName');
            String panNumber= (String) inputMap.get('panNumber');
            String customerType = (String) inputMap.get('customerType');
            String constitution = (String) inputMap.get('constitution');
            String applicantType = (String) inputMap.get('applicantType');
            String preferredLanguage = (String) inputMap.get('preferredLanguage');
            System.debug('inputMap--'+inputMap);
            System.debug('panOCRConfirmed--'+panOCRConfirmed);
            System.debug('loan Id--'+loanId);
            SalesCustomerDedupeController.InputWrapper duplicateCheckDetails = new SalesCustomerDedupeController.InputWrapper();
            duplicateCheckDetails.applicantId=applicantId;
            duplicateCheckDetails.loanId=loanId;
            duplicateCheckDetails.panNumber=panNumber;
            SalesCustomerDedupeController.ResponseWrapper respDup = new  SalesCustomerDedupeController.ResponseWrapper ();
            respDup.freshCustomer =true;
            if(applicantId!=null){
                response.put('createApp','false');
                //respDup = SalesCustomerDedupeController.checkCustomerDedupe(JSON.serialize(duplicateCheckDetails));
                response.put('freshCust',String.valueOf(true));
            }
            else{
                response.put('createApp','true');
            }
          
            Opportunity opp = [SELECT Id,  Name FROM Opportunity WHERE Id = :loanId];
          
            List<Account > acc  = [Select id, Applicant_Identifier__c,Duplicate_Customer_Source__c,Match_Response__c,Dedupe_Found_in__c from Account where Pan_Number__c != null AND  Pan_Number__c= :panNumber AND Customer_Type__c=:customerType AND Is_Active__c=true ];
        
            Account customer  = new Account();
            String contentDocumentId;
            Application_Applicant__c applicant = new Application_Applicant__c ();
            
            applicant.PAN_Number__c = panNumber;
            applicant.Pan_Name__c= userName;
            //if(customerType!=null){
                applicant.Customer_Type__c = customerType;
            //}
            //else{
              if (panNumber != null && panNumber.length() >= 4) {
                    
                    String fourthChar = panNumber.substring(3, 4);
                    System.debug('fourthChar---'+fourthChar);
                    if (fourthChar.equalsIgnoreCase('P')) {
                        if(constitution == 'Proprietorship' && customerType == 'Non Individual'){
                            applicant.Customer_Type__c = 'Non Individual';
                            applicant.DOI__c =  Date.valueOf(dob);
                            applicant.Name_of_Organization__c = userName;
                            applicant.Business_Entity_Name__c = userName;
                        }else {
                            applicant.Customer_Type__c = 'Individual';
                            applicant.DOB__c =  Date.valueOf(dob);
                            //applicant.Customer_Profile__c = 'SEP';
                        }
                        
                    } else {
                        applicant.Customer_Type__c = 'Non Individual';
                        applicant.DOI__c =  Date.valueOf(dob);
                        applicant.Name_of_Organization__c = userName;
                         applicant.Business_Entity_Name__c = userName;
                    }
                } 
                if(customerType==null){
                    applicant.Customer_Type__c = 'Individual';
                }


            //}
            applicant.Preferred_Language__c = preferredLanguage != null ? preferredLanguage : 'English';
            applicant.Loan_Application__c = loanId;
            
            applicant.Pan_OCR_Confirmed__c = Boolean.valueof(inputMap.get('panOCRConfirmed'));
            applicant.PAN_Number__c = panNumber;
            applicant.Name = userName;
            applicant.Pan_Name__c = userName;
            //applicant.Father_s_First_Name__c = fatherName.split(' ')[0];
            applicant.Loan_Application__c = loanId;
            System.debug('applicantname--+'+userName.split(' ')[0]);
            applicant.Pan_OCR_Confirmed__c = Boolean.valueof(inputMap.get('panOCRConfirmed'));
            List<String> nameParts = userName.trim().split(' ');
            System.debug('nameParts----'+nameParts.size());
            // if(customerType!=null && customerType.equalsIgnoreCase('Individual')){  
            applicant.First_Name__c = nameParts[0];
            Integer i;
            if(nameParts.size()>3){
                System.debug('nameParts----'+nameParts[1]);
                applicant.First_Name__c = nameParts[0];
                applicant.Middle_Name__c = nameParts[1];
                applicant.Last_Name__c ='';
                for(i=2; i<nameParts.size();i++){
                    applicant.Last_Name__c+= ' '+nameParts[i];
                }
                System.debug(' applicant.Last_Name__c----'+ applicant.Last_Name__c);
            }
            else if (nameParts.size() == 3) {
                applicant.Middle_Name__c = nameParts[1];
                applicant.Last_Name__c = nameParts[2];
            } else if (nameParts.size() == 2) {
                applicant.Last_Name__c = nameParts[1];
                applicant.Middle_Name__c = null;
            }
            else{
                  applicant.Last_Name__c = null;
                  applicant.Middle_Name__c = null;
            }
            // } else {
            //     applicant.Last_Name__c = applicant.First_Name__c;
            //     applicant.Middle_Name__c = null;
            // }
            // List<String> fatherName = userName.trim().split(' ');
            if(fathersName!= null && fathersName!= ''){
                List<String> fatherName = fathersName.trim().split(' ');
                applicant.Father_s_First_Name__c = fatherName[0];
                if (fatherName.size() == 3) {
                    applicant.Father_s_Middle_Name__c = fatherName[1];
                    applicant.Father_s_Last_Name__c = fatherName[2];
                } else if (fatherName.size() ==2) {
                    applicant.Father_s_Last_Name__c = fatherName[1];
                } else {
                    applicant.Father_s_Last_Name__c = applicant.Father_s_First_Name__c;
                }
            }
            
            
            
            // }
            if(customerType!=null && customerType.equalsIgnoreCase('Non Individual')) {
                applicant.Name_of_Organization__c = userName;
                 applicant.Business_Entity_Name__c = userName;
                applicant.Customer_Profile__c = 'SENP';
                applicant.Sector__c = constitution;
                applicant.DOI__c =Date.valueof(dob);
            }
            
             if(applicantId==null ){
                if(acc.size()>0){
                    customer.id = acc[0].id;
                    customer.Match_Response__c ='Pan';
                    customer.Dedupe_Found_in__c='savePanManually-New App';
                }
                else{
                    customer.Name = userName;
                    customer.PAN_Number__c  = panNumber;
                }
                
                customer.is_Active__c = true;
                Id customerRecordTypeId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer').getRecordTypeId();
                customer.RecordTypeId = customerRecordTypeId;
                upsert customer;
                applicant.Applicant_Type__c = applicantType != null ? applicantType : 'Co Applicant';
                applicant.Customer__c = customer.id;
                if (applicant.DOB__c != null) {
                    applicant.PAN_DOB__c = applicant.DOB__c;
                }
                List<String> panFatherParts1 = new List<String>();
                if (!String.isBlank(applicant.Father_s_First_Name__c))  panFatherParts1.add(applicant.Father_s_First_Name__c.trim());
                if (!String.isBlank(applicant.Father_s_Middle_Name__c)) panFatherParts1.add(applicant.Father_s_Middle_Name__c.trim());
                if (!String.isBlank(applicant.Father_s_Last_Name__c))   panFatherParts1.add(applicant.Father_s_Last_Name__c.trim());

                String panFatherFullName1 = String.join(panFatherParts1, ' ');
                if (!String.isBlank(panFatherFullName1)) {
                    applicant.Pan_Father_s_Name__c = panFatherFullName1;
                }
                
                insert applicant;
                
                if(acc.size()>0){
                    Account accdupCust =  new Account();
                    accdupCust.id =acc[0].id;
                    System.debug('acc---'+acc[0].id);
                    if(acc.size()>0){
                         System.debug('acc---'+acc[0].id);
                        if(acc[0].Applicant_Identifier__c!=null){
                            if(!acc[0].Applicant_Identifier__c.contains(applicant.Id)){
                            accdupCust.Applicant_Identifier__c=acc[0].Applicant_Identifier__c+','+applicant.Id;
                            }
                        }
                        else{
                            accdupCust.Applicant_Identifier__c=applicant.Id;
                            
                        }
                        accdupCust.Duplicate_Customer_Source__c ='Salesforce';
                        update accdupCust; 

                    }
                }
                applicantId= applicant.id;
                
            }
            else{
               
                 String custId = [Select id,Customer__c from Application_Applicant__c where id =:applicantId limit 1].Customer__c;
                List <Account> accToUpdate = new List<Account>();
                if(custId!=null
                //  && respDup.freshCustomer==false
                 ){
                    customer.id = custId; 
                    String custUniqueId;
                    System.debug('acc---'+acc);
                    System.debug('custId---'+custId);
                    if(acc.size()>0 && acc[0].Id != custId){
                        if(acc[0].Applicant_Identifier__c!=null){
                            custUniqueId = acc[0].Applicant_Identifier__c+','+applicantId;
                        }
                        else{
                            custUniqueId=applicantId;
        
                        }
                       
                        customer.Applicant_Identifier__c = custUniqueId;
                        customer.Duplicate_Customer_Source__c ='Salesforce';
                        customer.Match_Response__c ='Pan';
                        customer.Dedupe_Found_in__c='savePanManually-Exisiting';
                        customer.id = acc[0].id;
                        
                        response.put('accToDelete', custId);
                        Account cd =  new Account();
                        cd.id = custId; 
                        cd.Is_Active__c = false;
                        accToUpdate.add(cd);
                        // delete cd;
                    }
                    else{
                        customer.PAN_Number__c  = panNumber;
                    }
                }
                else{
                    customer.Name = userName;
                    customer.PAN_Number__c  = panNumber;
                }
            
             
                customer.RecordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
                
               
                upsert customer;
                
                applicant.Customer__c= customer.id;
                applicant.Id = applicantId;
                if (applicant.DOB__c != null) {
                    applicant.PAN_DOB__c = applicant.DOB__c;
                }
                List<String> panFatherParts2 = new List<String>();
                if (!String.isBlank(applicant.Father_s_First_Name__c))  panFatherParts2.add(applicant.Father_s_First_Name__c.trim());
                if (!String.isBlank(applicant.Father_s_Middle_Name__c)) panFatherParts2.add(applicant.Father_s_Middle_Name__c.trim());
                if (!String.isBlank(applicant.Father_s_Last_Name__c))   panFatherParts2.add(applicant.Father_s_Last_Name__c.trim());

                String panFatherFullName2 = String.join(panFatherParts2, ' ');
                if (!String.isBlank(panFatherFullName2)) {
                    applicant.Pan_Father_s_Name__c = panFatherFullName2;
                }
                Upsert applicant;
            
                 if(accToUpdate.size()>0){
                     Update accToUpdate; 
                     System.debug('accToUpdate---'+accToUpdate);
                 }
            }
            // String applicantToBeRemoved = '%' + applicantId + '%';
            // List<Account> dupAcc= [Select id,CustUniqueId__c from Account where CustUniqueId__c Like : applicantToBeRemoved ];
           
            // for(Account dupList :dupAcc){
            //     List<String> custUniqueId = dupList.CustUniqueId__c.split(',');
            //     dupList.CustUniqueId__c=dupList.CustUniqueId__c.replaceAll(applicantId,'');
            //     dupList.CustUniqueId__c=dupList.CustUniqueId__c.replaceAll(',,',',');
               
            // }
            // update dupAcc;
           
            response.put('applicantId', applicantId);
            return response;
            
        } catch (Exception e) {
            System.debug('Error in savePanDetailsManually: ' + e.getMessage()+' at line number: '+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    // @future
    // public static void deleteacc(String accToDel){
    //     if(accToDel != null && accToDel != ''){
    //         List<Account> accToDelete = (List<Account>)JSON.deserialize(accToDel,List<Account>.class);
    //         if(accToDelete.size()>0){
    //             Delete accToDelete;
    //         }
    //     }
    // }
    

    @AuraEnabled
    public static Map<String, String> createDocumentDetailsRecord(Map<String, String> inputMap) {
    try {
        Map<String, String> response = new Map<String, String>();
        String applicantId = inputMap.get('applicantId');
        String loanId = inputMap.get('loanId');
        String contentId = inputMap.get('contentId');
        String contentVersionId = inputMap.get('contentVersionId');
        String docType = inputMap.get('docType');

        if (!Schema.sObjectType.Document_Master__c.isAccessible()) {
        throw new AuraHandledException('You do not have permission to access Document Master data.');
        }
        List<Opportunity> oppList = [SELECT Id, Product__c FROM Opportunity WHERE Id =: loanId];
        List<Application_Applicant__c> applicantList= [SELECT Id, Customer_Type__c FROM Application_Applicant__c WHERE Id = :applicantId]; 
        List<Document_Master__c> docMasterList = [
            SELECT Id, Document_Type__c, Applicable_Product__c FROM Document_Master__c 
            WHERE Name = :docType AND Document_Category__c = 'POA' AND Customer_Type__c = :applicantList[0].Customer_Type__c AND Is_Active__c = true
        ];

        Document_Master__c docMaster= new Document_Master__c();
        for(Document_Master__c dm : docMasterList){
            if(dm.Applicable_Product__c !=null){
                List<String> prodList = dm.Applicable_Product__c.split(';');
                if(prodList.contains(oppList[0].Product__c)){
                    docMaster = dm;
                    break;
                }
            }
        }

        if (docMaster == null) {
            throw new AuraHandledException('Document Master Record Not Found');
        }
        if (!Schema.sObjectType.Document_Details__c.isAccessible()) {
            throw new AuraHandledException('You do not have permission to access Document Details data.');
        }
        // Try to find an existing Document_Details__c record
        List<Document_Details__c> existingDocs = [
            SELECT Id,Is_manual_masking_confirmed__c
            FROM Document_Details__c 
            WHERE Loan_Application__c = :loanId 
                AND Applicant__c = :applicantId 
                AND Document_Master__c = :docMaster.Id AND Document_Name__c =:docType
            LIMIT 1
        ];

        Document_Details__c docRecord;
        if (!existingDocs.isEmpty()) {
            docRecord = existingDocs[0]; 
        } else {
            docRecord = new Document_Details__c();
        }
        System.debug('docType'+docType);
        docRecord.Name = docType;
        docRecord.Loan_Application__c = loanId;
        docRecord.Applicant__c = applicantId;
        docRecord.Document_Master__c = docMaster.Id;
        docRecord.Document_Details__c = docMaster.Document_Type__c;
        docRecord.Requirement_Level__c = 'Applicant Level';
        docRecord.Consider_for_Loan_Application__c = true;
        docRecord.Is_Required__c =true;
        docRecord.Requirement_At__c = 'Applicant Level';
        docRecord.Document_Category__c = 'POA';
        docRecord.Document_Name__c = docType.toUpperCase().trim();

        Boolean canCreateDocDetail = Schema.SObjectType.Document_Details__c.isCreateable();
        Boolean canUpdateDocDetail = Schema.SObjectType.Document_Details__c.isUpdateable();

        if (!canCreateDocDetail && !canUpdateDocDetail) {
            throw new AuraHandledException('You do not have permission to upsert Document Details records.');
        }
        upsert docRecord;

        response.put('documentDetailsRecordId', String.valueOf(docRecord.Id));
        response.put('isManualMaskingDone', String.valueOf(docRecord.Is_manual_masking_confirmed__c != null ? docRecord.Is_manual_masking_confirmed__c : false));
        return response;

    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
    }


    @AuraEnabled
    public static Map<String,String> saveAadharDetailsManually(Map<String,String> inputMap){
        try {
            //HL-Ishi-9/9/2025
            Map<String,String> inputMapUtility = new  Map<String,String>();
            inputMapUtility.put('oppId', (String) inputMap.get('loanId'));
            Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.getProductDetails(inputMapUtility);
            Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
                
            //HL-Ishi-9/9/2025
            System.debug('inputMap keyset==>'+inputMap.keyset());
            System.debug('inputMap values==>'+inputMap.values());
            Map<String, String> response = new Map<String, String>();
            String aadharFirstName = (String) inputMap.get('aadharFirstName');
            String aadharLastName = (String) inputMap.get('aadharLastName');
            String aadharMiddleName = (String) inputMap.get('aadharMiddleName');
            String applicantId = (String) inputMap.get('applicantId');
            String loanId = (String) inputMap.get('loanId');
            String dob = (String) inputMap.get('dob');
            String aadharNumber= (String) inputMap.get('aadharNumber');
			String mobileNumber= (String) inputMap.get('mobileNumber');
            String addressLine1 = (String) inputMap.get('addressLine1');
            String addressLine2 = (String) inputMap.get('addressLine2');
            String addressLine3 = (String) inputMap.get('addressLine3');
            String aadharPinCode = inputMap.containsKey('aadharPinCode')? (String)inputMap.get('aadharPinCode'):'';
            String aadharCity = (String) inputMap.get('aadharCity');
            String aadharState = (String) inputMap.get('aadharState');
            String pinCodeMasterRecordId = (String) inputMap.get('pinCodeMasterRecordId');
            String fullAddress = addressLine1 + ',' + addressLine2;
            Boolean frontConfirmed = inputMap.containsKey('frontConfirmed') ? Boolean.valueOf(inputMap.get('frontConfirmed')) : false;
            Boolean backConfirmed = inputMap.containsKey('backConfirmed') ? Boolean.valueOf(inputMap.get('backConfirmed')) : false;
            String aadharFullAddress = inputMap.containsKey('aadharFullAddress')? (String) inputMap.get('aadharFullAddress'):'';
            String addressType = (String) inputMap.get('addressType');
            String addressOwnership = (String) inputMap.get('addressOwnership');
            if(addressLine3!=null){
                 fullAddress = fullAddress+','+addressLine3;
            }
            Application_Applicant__c applicant = new Application_Applicant__c ();
            if(applicantId != null && applicantId != ''){
                applicant.Id = applicantId;
                if(aadharFirstName != null && aadharFirstName != ''){
                    applicant.Aadhaar_First_Name__c = aadharFirstName;
                }
                if(aadharMiddleName != null && aadharMiddleName != ''){
                    applicant.Aadhaar_Middle_Name__c = aadharMiddleName;
                }
                if(aadharLastName != null && aadharLastName != ''){
                    applicant.Aadhaar_Last_Name__c = aadharLastName;
                }
                if(aadharNumber != null && aadharNumber != ''){
                    applicant.Aadhaar_Number__c = aadharNumber;
                    applicant.Aadhaar_Number_Masked__c = Utility.getDecryptedBase64String(aadharNumber);
                }
                if(mobileNumber != null && mobileNumber != ''){
                    applicant.Mobile_Number__c = mobileNumber;
                }  
                if(dob != null && dob != ''){
                    applicant.Aadhaar_DOB__c = Date.valueOf(dob);
                }
                if(fullAddress != null && fullAddress != ''){
                    applicant.Aadhaar_Address__c = fullAddress;
                }
                if(aadharCity != null && aadharCity != '' && aadharState != null && aadharState != ''){
                   // applicant.Aadhaar_City_Town__c = aadharCity + ',' + aadharState;
                }
                if(pinCodeMasterRecordId != null && pinCodeMasterRecordId != ''){
                    applicant.Aadhaar_Pincode__c = pinCodeMasterRecordId;
                }
                if(aadharFullAddress != null && aadharFullAddress != ''){
                    applicant.Aadhaar_Address__c = aadharFullAddress;
                }
                if(aadharPinCode != null && aadharPinCode != ''){
                    Pincode_Master__c pinCodeMaster = [SELECT Id,City__c,State__c,Country__c FROM Pincode_Master__c WHERE Name = :aadharPinCode LIMIT 1];
                    if (pinCodeMaster != null) {
                        applicant.Aadhaar_Pincode__c = pinCodeMaster.Id;
                       // applicant.Aadhaar_City_Town__c = pinCodeMaster.City__c + ',' + pinCodeMaster.State__c;
                    } else {
                        throw new AuraHandledException('Pincode Master Record Not Found for the provided Aadhaar Pincode');
                    }
                    
                }
                if(frontConfirmed){
                    applicant.Aadhaar_Front_OCR_Confirmed__c = true;
                }
                if(backConfirmed){
                    applicant.Aadhaar_Back_OCR_Confirmed__c = true;
                }
                
                } if(frontConfirmed || backConfirmed){
                    update applicant;
                    response.put('applicantId', applicantId);
                    if (backConfirmed) {
                        Boolean canUpdateApplicantAddress = Schema.SObjectType.Applicant_Address__c.isUpdateable();
                        if (!canUpdateApplicantAddress) {
                            throw new AuraHandledException('You do not have permission to update Applicant Address records.');
                        }
                        List<Applicant_Address__c> aadhaarAddrList = [
                            SELECT Id
                            FROM Applicant_Address__c
                            WHERE Applicant__c = :applicantId
                            AND Address_Source__c = 'Aadhaar'
                            ORDER BY CreatedDate DESC
                            LIMIT 1
                        ];

                        if (!aadhaarAddrList.isEmpty()) {
                            Applicant_Address__c aadhaarAddrToUpdate = new Applicant_Address__c(
                                Id = aadhaarAddrList[0].Id,
                                Address_Type__c = addressType,
                                Address_Ownership__c = addressOwnership
                            );
                            update aadhaarAddrToUpdate;
                        }
                    }
                }
            
                if(applicant!=null && !frontConfirmed && !backConfirmed){
                Boolean canUpdateApplicant = Schema.SObjectType.Application_Applicant__c.isUpdateable();
                Boolean canInsertApplicantAddress = Schema.SObjectType.Applicant_Address__c.isCreateable();
                if (!canUpdateApplicant) {
                throw new AuraHandledException('You do not have permission to update Applicant records.');
                }
                update applicant;

                List<Applicant_Address__c> existingAddress = [
                    SELECT Id, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Pincode__c 
                    FROM Applicant_Address__c 
                    WHERE Applicant__c = :applicantId AND Loan_Application__c = :loanId and Address_Source__c = 'Aadhaar'
                    LIMIT 1
                ];


                Applicant_Address__c objApplicantAddress = new Applicant_Address__c();
                if(!existingAddress.isEmpty()) {
                    objApplicantAddress.Id = existingAddress[0].Id;
                }
                // else {
                    objApplicantAddress.Address_Source__c = 'Aadhaar';
                // }
                objApplicantAddress.Address_Type__c = addressType;
                objApplicantAddress.Address_Ownership__c = addressOwnership;
                objApplicantAddress.Address_Line_1__c = addressLine1;
                objApplicantAddress.Address_Line_2__c = addressLine2;
                objApplicantAddress.Address_Line_3__c = addressLine3;
                objApplicantAddress.Applicant__c = applicantId;
                objApplicantAddress.Loan_Application__c = loanId;
                if(pinCodeMasterRecordId != null && pinCodeMasterRecordId != ''){
                    objApplicantAddress.Pincode__c = pinCodeMasterRecordId;
                }
                
                if (!canInsertApplicantAddress) {
                throw new AuraHandledException('You do not have permission to create Applicant Address records.');
                }
                upsert objApplicantAddress;
                response.put(applicant.id,String.valueOf(applicant));

            }
            List<Application_Applicant__c> lstOfApplicantsToUpdate = new List<Application_Applicant__c>();
            List<Account> lstOfAccWithSameAadhar  = [Select id, Applicant_Identifier__c,Duplicate_Customer_Source__c,Match_Response__c,Mobile_Number__c from Account where Aadhar_Number__c != null AND  Aadhar_Number__c = :aadharNumber and Is_Active__c=true];
            String applicantAccountId = [Select id,Customer__c from Application_Applicant__c where id =:applicantId limit 1].Customer__c;
            List<Account> lstOfAcc = new List<Account>();
           if (applicantAccountId != null) {
            Account applicantCust = new Account(Id = applicantAccountId);
            
            if (!lstOfAccWithSameAadhar.isEmpty() && lstOfAccWithSameAadhar[0].Id != applicantAccountId) {
                Account matchingAcc = lstOfAccWithSameAadhar[0];
        
                applicantCust.Id = matchingAcc.Id;
System.debug('matchingAcc.Applicant_Identifier__c---'+matchingAcc.Applicant_Identifier__c);
                System.debug('applicantId--'+applicantId);
                if(!isHlRelated){
                if (!String.isBlank(matchingAcc.Applicant_Identifier__c) && !matchingAcc.Applicant_Identifier__c.contains(applicantId)) {
                    applicantCust.Applicant_Identifier__c = matchingAcc.Applicant_Identifier__c + ',' + applicantId;
                } else {
                    applicantCust.Applicant_Identifier__c = applicantId;
                }

                applicantCust.Duplicate_Customer_Source__c = 'Salesforce';
                applicantCust.Match_Response__c = 'Aadhaar';
                }
                applicantCust.Aadhar_Number__c = aadharNumber;
                applicantCust.Mobile_Number__c=mobileNumber;

                // Deactivate old applicant account
                Account accDeactivate = new Account(Id = applicantAccountId, Is_Active__c = false);

                lstOfAcc.add(accDeactivate);
                lstOfAcc.add(applicantCust);

                // ✅ Directly update applicant without SOQL
                    if(!isHlRelated){
                        lstOfApplicantsToUpdate.add(new Application_Applicant__c(
                        Id = applicantId,
                        Customer__c = matchingAcc.Id
                                ));
                    }
               
                } 
                else {
                    // Same account or no match: just update Aadhaar
                    applicantCust.Aadhar_Number__c = aadharNumber;
                    applicantCust.Is_Active__c = true;
                    if(frontConfirmed){
                        applicantCust.Aadhaar_Front_OCR_Confirmed__c = true;
                    }
                    if(backConfirmed){
                        applicantCust.Aadhaar_Back_OCR_Confirmed__c = true;
                    }
                    lstOfAcc.add(applicantCust);
                }

                if (!lstOfAcc.isEmpty()) 
                { 
                    update lstOfAcc;
                }
                if (!lstOfApplicantsToUpdate.isEmpty()) {
                    update lstOfApplicantsToUpdate;
                }
                }   
            System.debug('response==>'+response);
            return response;
       }catch(Exception ex){
                throw new AuraHandledException(ex.getMessage());
        } 
        
    }

    @AuraEnabled
    public static string checkIfKeyApplicantIsSelected(String recordId){
        try {
            String flag = 'false';
            List<Application_Applicant__c> appList= [Select id,Is_Key_Applicant__c from Application_Applicant__c where Loan_Application__c =:recordId and Is_Key_Applicant__c=true];
            if(appList.size()>0){
                flag='true';
            }
            return flag;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean exceptionCheck(String loanId){
        Boolean flag = false;
        try {
            List<Opportunity> oppList= [SELECT Id, Is_Eligible_for_Exception_Approval__c FROM Opportunity WHERE Id= :loanId];

            if(oppList.size()>0){
                return oppList[0].Is_Eligible_for_Exception_Approval__c;
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return flag;
    }

    // @AuraEnabled
    // public static boolean deleteApplicant(String applicantId){
    //     if(applicantId!=null){
    //         Application_Applicant__c app = new Application_Applicant__c();
    //         app.id = applicantId;
    //         delete app;
    //         return true;
    //     }
    //     else{
    //         return false;
    //     }
        
    // }

@AuraEnabled
public static Map<String, String> uploadFormSixtyToDocumentDetail(Map<String, String> inputMap) {
    String firstName = inputMap.get('firstName');
    String middleName = inputMap.get('middleName');
    String lastName = inputMap.get('lastName');
    String applicantId = inputMap.get('applicantId');
    String loanId = inputMap.get('loanId');
    String mobileNumber = inputMap.get('mobileNumber');
    String formSixtyFileName = inputMap.get('formSixtyFileName');
    String formSixtyBase64Data = inputMap.get('formSixtyBase64Data'); 
    String applicantType = inputMap.get('applicantType'); 
    String preferredLanguage = inputMap.get('preferredLanguage');
    
    if(String.isBlank(formSixtyBase64Data)) {
        throw new AuraHandledException('File data is missing.');
    } 
    
    System.debug('firstName: ' + firstName + ' lastName: ' + lastName + ' mobileNumber:'+mobileNumber);
    System.debug('loanId=>'+loanId + 'form60->'+formSixtyBase64Data);

    Map<String, String> response = new Map<String, String>();

    try {
        // Fetch Document Master
        Document_Master__c docMaster = [SELECT Id FROM Document_Master__c WHERE Name = 'Form 60' LIMIT 1];

        List<Account> accList = [SELECT Id, First_Name__c, Last_Name__c, Mobile_Number__c FROM Account WHERE Mobile_Number__c = :mobileNumber LIMIT 1];
        Account acc;
        Boolean isNewAccount = true;

        if (!accList.isEmpty()) {
            acc = accList[0];
            isNewAccount = false;
        } else {
            acc = new Account();
        }

        acc.First_Name__c = firstName;
        acc.Last_Name__c = lastName;
        acc.Name = firstName + ' ' + lastName;
        acc.Mobile_Number__c = mobileNumber;
        Id customerRecordTypeId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        acc.RecordTypeId = customerRecordTypeId;
        upsert acc; // Handles both insert & update

        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c();
            applicant.Customer__c = acc.Id;
            applicant.Loan_Application__c = loanId;
            applicant.id = applicantId;
            applicant.First_Name__c = firstName;
            applicant.Middle_Name__c = middleName;
            applicant.Last_Name__c = lastName;
            applicant.Preferred_Language__c = preferredLanguage != null ? preferredLanguage : 'English';
            if(applicantId == null || applicantId == ''){
            applicant.Applicant_Type__c = applicantType != null ? applicantType : 'Co Applicant';
            applicant.Customer_Type__c = 'Individual';
            }
            applicant.Mobile_Number__c = mobileNumber;
            applicant.IsForm60Uploaded__c = 'Yes';
            
            upsert applicant;
            
        List<Document_Details__c> docDetailList =[Select id,Name,Loan_Application__c,Applicant__c,Document_Master__c,Requirement_Level__c,Consider_for_Loan_Application__c,Document_Details__c,Is_Required__c from Document_Details__c where Applicant__c=:applicantId and Name='Form 60' and Consider_for_Loan_Application__c=true];
        Document_Details__c docDetail = new Document_Details__c();
       // System.debug('Doc details>'+docDetailList[0]);
        if(docDetailList.size()>0){
            docDetail.id=docDetailList[0].id;
        }
        docDetail.Loan_Application__c = loanId;
        docDetail.Applicant__c= applicant.Id;
        docDetail.Name= 'Form 60';
        docDetail.Document_Master__c= docMaster.Id;
        docDetail.Requirement_Level__c = 'Applicant Level';
        docDetail.Consider_for_Loan_Application__c =true;
        docDetail.Document_Details__c ='POA';
        docDetail.Is_Required__c =true;
        upsert docDetail;
        System.debug('doc details Kshitiz>'+docDetail);
        // Create ContentVersion
        ContentVersion contentVersion = new ContentVersion(
            Title = formSixtyFileName,
            PathOnClient = formSixtyFileName,
            VersionData = EncodingUtil.base64Decode(formSixtyBase64Data),
            IsMajorVersion = true
        );
        insert contentVersion;
        System.debug('Inserted cv Kshitiz>'+contentVersion);
        // Fetch ContentDocumentId
        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];

        // Link ContentDocument to Document Detail
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedCV.ContentDocumentId,
            LinkedEntityId = docDetail.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        System.debug('inserted cdl>'+cdl);
        docDetail.Content_Document_Id__c = insertedCV.ContentDocumentId;
        update docDetail;

        response.put('applicantId', applicant.Id);
        return response;
    } catch (Exception ex) {
        System.debug('Error while uploading Form-60: ' + ex.getMessage());
        throw new AuraHandledException(ex.getMessage());
    }
}

    @AuraEnabled
     public static List<DocumentCheckListWrappper> createDocumentDetailsRequest(String documentChecklistId, String recordId){
          List<String> contentVersionIds =(List<String>) JSON.deserialize(documentChecklistId,List<String>.class); 
            Map<String,String> versionToFileName = new Map<String,String>();
            Map<String,String> VersionToDocId = new Map<String,String>();
            Map<String, String> contentToVersionMap = new Map<String,String>();
            List<ContentVersion> cvRecVersionIdList = [Select Id,Title,ContentDocumentId from ContentVersion where Id IN :contentVersionIds ];
            for(ContentVersion cvId : cvRecVersionIdList) {
                versionToFileName.put(cvId.Id,cvId.Title);
                VersionToDocId.put(cvId.Id,cvId.ContentDocumentId);
                contentToVersionMap.put(cvId.ContentDocumentId,cvId.Id);
            }
            List<Document_Details__c> docDetailsList = [SELECT Id, Name, Content_Document_Id__c,Year_Month_From__c,Year_month_to__c,Transaction_ID__c, Applicant__c
                FROM Document_Details__c 
                WHERE Content_Document_Id__c IN :VersionToDocId.values()
            ];
            DocumentCheckListWrappper dw = new DocumentCheckListWrappper();
            List<Document_Master__c> docMaster = [Select Id, Name, Requirement_Level__c 
                FROM Document_Master__c where Name = :'Bank Statement Analysis Response'];

            Map<Id, List<Document_Details__c>> appToDocMap = new Map<Id, List<Document_Details__c>>();
            Map<Id, List<String>> appToDocIdsMap = new Map<Id, List<String>>();
            for(Document_Details__c doc : docDetailsList){
                if(appToDocMap.containsKey(doc.Applicant__c)){
                    appToDocMap.get(doc.Applicant__c).add(doc);
                } else {
                    appToDocMap.put(doc.Applicant__c, new List<Document_Details__c>{doc});
                }
                if(appToDocIdsMap.containsKey(doc.Applicant__c)){
                    appToDocIdsMap.get(doc.Applicant__c).add(doc.Content_Document_Id__c);
                }
                else{
                    appToDocIdsMap.put(doc.Applicant__c, new List<String>{doc.Content_Document_Id__c});
                }
            }
            List<Document_Details__c> ddList= new List<Document_Details__c>();
           
            for(String appId : appToDocMap.keySet()){
                Document_Details__c dd = new Document_Details__c();
                dd.Name='CallbackResponse';
                dd.Document_Master__c =docMaster[0].id;
                dd.Applicant__c=appId;
                ddList.add(dd);
                Document_Details__c ddExcel = new Document_Details__c();
                ddExcel.Name='BSAExcel';
                ddExcel.Applicant__c=appId;
                ddExcel.Status__c = 'Pending';
                ddList.add(ddExcel);
            }
            insert ddList;
            List<Document_Details__c> docDetailsListFinal =[Select id, Name,Applicant__c from Document_Details__c where id In : ddList];
            Map<String,DocumentCheckListWrappper>  applicanttoDoc = new  Map<String,DocumentCheckListWrappper> ();
            for(Document_Details__c docDetails : docDetailsListFinal){
                if(applicanttoDoc.containsKey(docDetails.Applicant__c)){
                    DocumentCheckListWrappper doc = applicanttoDoc.get(docDetails.Applicant__c);
                    if(docDetails.Name =='CallbackResponse' ){
                        doc.docListResponse.add(docDetails);
                    }
                    else if(docDetails.Name =='BSAExcel'){
                        doc.docListExcel.add(docDetails);
                    }
                }
                else{
                     DocumentCheckListWrappper doc = new DocumentCheckListWrappper();
                     doc.appId  = docDetails.Applicant__c;
                     doc.docListResponse = new List<Document_Details__c>();
                     doc.docListExcel = new List<Document_Details__c>();
                      if(docDetails.Name =='CallbackResponse' ){
                        doc.docListResponse.add(docDetails);
                    }
                    else if(docDetails.Name =='BSAExcel'){
                        doc.docListExcel.add(docDetails);
                    }
                    applicanttoDoc.put(docDetails.Applicant__c,doc);

                }
            }


           
           
            return applicanttoDoc.values();
     }

    @AuraEnabled
    public static Boolean checkLoanDuplicateByPanOrAadhar(Map<String, String> inputMap) {
        String pan = inputMap.get('panNumber');
        String aadhaar = inputMap.get('aadhaarNumber');
        Id loanId = (inputMap.containsKey('loanId') && String.isNotBlank(inputMap.get('loanId')))
            ? Id.valueOf(inputMap.get('loanId'))
            : null;

        if (String.isBlank(pan) && String.isBlank(aadhaar)) {
            return false;
        }

        String baseQuery = 'SELECT Id FROM Application_Applicant__c WHERE ';
        List<String> conditions = new List<String>();

        if (!String.isBlank(pan)) {
            conditions.add('PAN_Number__c = :pan');
        }

        if (!String.isBlank(aadhaar)) {
            conditions.add('Aadhaar_Number__c = :aadhaar');
        }

        baseQuery += '(' + String.join(conditions, ' OR ') + ')';
        List<Application_Applicant__c> dupRecords;
        if (loanId != null) {
            baseQuery += ' AND Loan_Application__c = :loanId';
            dupRecords = Database.query(baseQuery);
        }

        return !dupRecords.isEmpty(); // true = duplicate exists
    }
    

    // @AuraEnabled
    // public static void deleteCust(String custId){
    //     Account acc = new Account();
    //     acc.id = custId;
    //     delete acc;
    // }

     public class DocumentCheckListWrappper{
        @AuraEnabled public String appId;
        @AuraEnabled public List<Document_Details__c> docListResponse; 
        @AuraEnabled public List<Document_Details__c> docListExcel;         
     }

    @AuraEnabled
    public static String updatecustomerOnApplicant(Map<String, String> inputMap){
        String result= 'No link found';
        String custId = inputMap.get('custId');
        String applicantId = inputMap.get('applicantId');

        Application_Applicant__c applicant= new Application_Applicant__c(
            Id= applicantId,
            Customer__c= custId
        );
        update applicant;

        Account acc= new Account(
            Id= custId,
            Dedupe_Disposition__c = 'Match found'
        );
        update acc;

        result= 'sucess';
        return result;
    }

    @AuraEnabled
    public static Boolean validateApplicant( Map<String, String> inputMap){
        Boolean res= false;
        // String custId = inputMap.get('custId');
        String applicantId = inputMap.get('applicantId');

        try {
            List<Application_Applicant__c> appList= [SELECT Id, Customer__c, Customer__r.Dedupe_Disposition__c FROM Application_Applicant__c WHERE Id= :applicantId];
            if(appList.size()>0){
                if(appList[0].Customer__c != null && appList[0].Customer__r.Dedupe_Disposition__c== 'Match found'){
                    res= true;
                }
            }
        } catch (Exception e) {
            System.debug('error in validateApplicant---'+ e.getMessage());
            // throw new AuraHandledException(e.getMessage());
        }

        return res;
    }
    //HL-Ishi
     @AuraEnabled
    public static void updateAccountName(string loanId){
        try {
            List<Application_Applicant__c> appList = [SELECT Id,First_Name__c,Middle_Name__c,Last_Name__c,Pan_Name__c,Customer__c FROM Application_Applicant__c WHERE Loan_Application__c =:loanId];
            List<Account> accList = new List<Account>();
            Set<Id> accIds = new Set<Id>();
            for(Application_Applicant__c app : appList){
                if(app.Customer__c != null){
                    Account acc = new Account();
                    acc.Id = app.Customer__c;
                    acc.First_Name__c = app.First_Name__c;
                    acc.Middle_Name__c = app.Middle_Name__c;
                    acc.Last_Name__c = app.Last_Name__c;
                    acc.Name = app.Pan_Name__c;
                    if(!accIds.contains(acc.Id)){
                        accList.add(acc);
                        accIds.add(acc.Id);
                    }
                }
            }
            if(accList.size()>0){
                update accList;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static DocumentWrapper getDocumentDetailsAadhar(Map<String,String> inputMap){
        try {
            DocumentWrapper docWrap = new DocumentWrapper();
            String documentName = inputMap.get('documentName');
            String applicantId = inputMap.get('applicantId');
            String loanId = inputMap.get('loanId');
            String documentId = inputMap.get('documentId');
            List<Document_Details__c> docDetails = [Select id, Is_manual_masking_confirmed__c from Document_Details__c where Loan_Application__c =:loanId and Applicant__c =:applicantId and Document_Name__c =:documentName and id =:documentId limit 1 ];
            for(Document_Details__c doc : docDetails){
                
                docWrap.documentId = doc.Id;
                docWrap.isMaskingAcknowledged = doc.Is_manual_masking_confirmed__c;
                
            }
            return docWrap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class DocumentWrapper{
        @AuraEnabled public String documentId;
        @AuraEnabled public Boolean isMaskingAcknowledged;
    }
    //HL_Ishi
    //For Aadhar Masking failure_Ayushi
    @AuraEnabled
public static void linkManualDocumentAndUpdate(Id docDetailId, Id newContentVersionId, Id oldContentVersionId) {
    try {
        // 1. Find the new ContentDocumentId from the new ContentVersionId
        ContentVersion newCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :newContentVersionId LIMIT 1];

        // 2. Update the Document_Details__c record to link the new file
        Document_Details__c docToUpdate = new Document_Details__c(
            Id = docDetailId,
            Content_Document_Id__c = newCv.ContentDocumentId,
            Status__c = 'Uploaded',
            Aadhar_Masked_Source__c = 'Manual'
        );
        update docToUpdate;

        // 3. Clean up by deleting the old, failed ContentDocument
        if (oldContentVersionId != null) {
            List<ContentDocument> docsToDelete = [
                SELECT Id FROM ContentDocument 
                WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :oldContentVersionId)
            ];
            if (!docsToDelete.isEmpty()) {
                delete docsToDelete;
            }
        }
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}

    /**
    * @ Author: Kunal Bisht
    * @ JIRA: SFHL-1420
    */
    @AuraEnabled
    public static String getLoanApplicationStageByApplicantId(Id applicantId) { 
        List<Application_Applicant__c> apps = [SELECT id, Loan_Application__r.StageName from Application_Applicant__c where Id =:applicantId limit 1];
        if (apps.isEmpty()) {
                return null;
            }
        
            return apps[0].Loan_Application__r.StageName;
    }

    /**
    * @ Author: Kunal Bisht
    * @ JIRA: SFHL-1420
    */
    @AuraEnabled
    public static Boolean checkIfApplicationVerificationRecordExists(Id coAppId) {
        if (coAppId == null) {
            return false;
        }

        List<Application_Verification__c> verifications = [
            SELECT Id
            FROM Application_Verification__c
            WHERE Applicant__c = :coAppId
            LIMIT 1
        ];

        return !verifications.isEmpty();
    }


    /**
    * @ Author: Kunal Bisht
    * @ JIRA: SFHL-1420
    */
    @AuraEnabled
    public static void deleteCoAppAndRelatedRecords(Id coAppId) {
        if (coAppId == null) {
            return;
        }

        try {
            
            List<Applicant_Address__c> addressListToDelete = [
                SELECT Id
                FROM Applicant_Address__c
                WHERE Applicant__c = :coAppId
                AND Applicant__r.Applicant_Type__c = 'Co Applicant'
            ];
                
            if (!addressListToDelete.isEmpty()) {
                delete addressListToDelete;
            }


            List<Document_Details__c> docsToDelete = [
                SELECT Id
                FROM Document_Details__c
                WHERE Applicant__c = :coAppId
                AND Applicant__r.Applicant_Type__c = 'Co Applicant'
            ];

            if (!docsToDelete.isEmpty()) {
                delete docsToDelete;
            }

            List<Application_Applicant__c> coApplicants = [
                SELECT Id
                FROM Application_Applicant__c
                WHERE Id = :coAppId
                AND Applicant_Type__c = 'Co Applicant'
                LIMIT 1
            ];

            if (!coApplicants.isEmpty()) {
                delete coApplicants;
            }

        } catch (DmlException dmle) {
            System.debug('Error while deleting Co Applicant: ' + dmle.getMessage());
            throw dmle;
    }
}

}