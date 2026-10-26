/*
* Author    :   Deloitte India
* Purpose   :   Generic controller class to read write data from ScreenFields__c
* @last modified on  : 04-26-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
*/

public without sharing class ScreenGenerationController {
    @AuraEnabled
    public static Account getDefaultSubBranch(){
        try {
            List<Account> subBranches = [SELECT Id,Name FROM Account where RecordType.Name = 'Branch' AND Branch_Type__c = 'REGIONALOFFICE'];
            return subBranches[0];
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static List<Screen_Field__c> getScreenDetails(String formIdentifier, String loanId){
        try{
            List<Screen_Field__c> screenFields = new List<Screen_Field__c>();
            System.debug('formIdentifier---'+formIdentifier);
            // Normalize the apostrophe
            formIdentifier = formIdentifier.replaceAll('[\u2019\u0027]', '\'').trim();
            System.debug('Normalized formIdentifier: ' + formIdentifier);
            System.debug('formIdentifier---17'+formIdentifier);
            //HL-Ishi-13-10
            Map<String,String> inputMapUtility = new  Map<String,String>();
            Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
            Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
            List<Screen_Field__c> screenFieldToReturn = new List<Screen_Field__c>();
            //HL-Ishi-13-10
            
            if(formIdentifier == Constants.LOAN_LOGIN_FORM_IDENTIFIER){
                
                if(string.isNotBlank(loanId)){
                    List<Opportunity> loanList = [Select Id, Login_Completion_Stage__c, Product__c from Opportunity where id =: loanId And Login_Completion_Stage__c != null];
                    List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Customer_Profile__c from Application_Applicant__c where Loan_Application__c=: loanId and Applicant_Type__c = 'Primary Applicant'];
                    //HL-ISHI-13-10
                    List<Product2> prodList = [Select Id, Name from Product2 where Loan_Application__c =: loanId and RecordType.Name = 'Product' and Name =: loanList[0].Product__c limit 1];
                    //HL-ISHI-13-10
                    if(!loanList.isEmpty()) {
                        List<string> applicableStageList = loanList[0].Login_Completion_Stage__c.split(';');
                        List<Screen_Field__c> queryScreens = new List<Screen_Field__c>();
                        if(appDet.size()>0 && appDet[0].Customer_Type__c != null){
                                String custAndEmpType = appDet[0].Customer_Type__c+'-'+appDet[0].Customer_Profile__c;
                                queryScreens = [SELECT Id, Form_Name__c , Parent_Screen__r.Form_Name__c,Applicant_Type_Visibility__c, Name,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c, Filtered_Picklist_Values__c,
                                            Is_Picklist__c,Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,Section_Seperator__c,Section_Name__c, Applicable_For_Products__c,
                                            Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c, Read_Field_Name__c,Applicable_For__c,Picklist_Dependent_On_RecordType__c,Show_in_words__c,
                                            Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c,Is_Multipicklist__c,Enable_for__c
                                            FROM Screen_Field__c
                                            WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Form_Name__c =: formIdentifier And Applicable_Login_Stage__c In : applicableStageList
                                            AND (Parent_Screen__r.Applicable_For__c = 'Both' or Parent_Screen__r.Applicable_For__c = 'Individual-Both' or Parent_Screen__r.Applicable_For__c = 'Non Individual-Both' or Parent_Screen__r.Applicable_For__c =: custAndEmpType)
                                            order by Field_Sequence__c ASC];
                        }
                        else{
                            queryScreens = [SELECT Id, Form_Name__c , Parent_Screen__r.Form_Name__c, Name,Applicant_Type_Visibility__c,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c, Filtered_Picklist_Values__c,
                                            Is_Picklist__c,Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,Section_Seperator__c,Section_Name__c,Show_in_words__c,Applicable_For_Products__c,
                                            Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c, Read_Field_Name__c,Applicable_For__c,Picklist_Dependent_On_RecordType__c,
                                            Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c,Is_Multipicklist__c,Enable_for__c
                                            FROM Screen_Field__c
                                            WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Form_Name__c =: formIdentifier And Applicable_Login_Stage__c In : applicableStageList
                                            order by Field_Sequence__c ASC];
                        } 
                        
                        for(Screen_Field__c scf : queryScreens){
                            //HL-ISHI-13-10
                            if(isHlRelated){
                                if(!prodList.isEmpty()){
                                    if(String.isNotBlank(scf.Applicable_For_Products__c)){
                                        List<String> applicableProdList = scf.Applicable_For_Products__c.split(',');
                                        if(applicableProdList.contains(prodList[0].Name)){
                                            screenFields.add(scf);
                                        }
                                    }
                                }
                                else{
                                    screenFields.add(scf);
                                }
                            }
                            else{
                                screenFields.add(scf);
                            }
                            //HL-ISHI-13-10
                        }
                        //HL-ISHI-13-10
                        screenFieldToReturn.addAll(screenFields);
                        //HL-ISHI-13-10
                    }
                }
                else{
                    screenFields = [SELECT Id,Form_Name__c , Parent_Screen__r.Form_Name__c, Applicant_Type_Visibility__c,Name,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c,Picklist_Dependent_On_RecordType__c, 
                                    Is_Picklist__c,Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,Applicable_For__c,Filtered_Picklist_Values__c,Show_in_words__c,
                                    Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c, Read_Field_Name__c,Section_Seperator__c,Section_Name__c,Applicable_For_Products__c,
                                    Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c,Is_Multipicklist__c,Enable_for__c
                                    FROM Screen_Field__c
                                    WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Form_Name__c =: formIdentifier
                                    order by Field_Sequence__c ASC];
                    screenFieldToReturn.addAll(screenFields);
                }
            }
            else if(formIdentifier == 'Application Other Details' || formIdentifier == 'Applicant Other Details'){
                if(string.isNotBlank(loanId)){
                    screenFields = [SELECT Id,Form_Name__c , Parent_Screen__r.Form_Name__c,Applicant_Type_Visibility__c, Name,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c, Picklist_Dependent_On_RecordType__c,
                                    Is_Picklist__c,Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,Applicable_For__c,Filtered_Picklist_Values__c,Show_in_words__c,
                                    Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c,Read_Field_Name__c,Read_Object_Name__c,Section_Seperator__c,Section_Name__c,Applicable_For_Products__c,
                                    Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c, Screen_Name__c,Is_Multipicklist__c,Enable_for__c
                                    FROM Screen_Field__c
                                    WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Form_Name__c =: formIdentifier
                                    order by Field_Sequence__c ASC];
                    List<Opportunity> loanList = [Select Id, Login_Completion_Stage__c, Product__c from Opportunity where id =: loanId And Login_Completion_Stage__c != null];
                    List<Opportunity> loanList2 = [Select Id, Login_Completion_Stage__c, Product__c from Opportunity where id =: loanId];
                    List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Customer_Profile__c from Application_Applicant__c where Loan_Application__c=: loanId and Applicant_Type__c = 'Primary Applicant'];
                    //HL-ISHI-13-10
                    List<Product2> prodList = [Select Id, Name from Product2 where Loan_Application__c =: loanId and RecordType.Name = 'Product' and Name =: loanList2[0].Product__c limit 1];
                    //HL-ISHI-13-10
                    if(!loanList2.isEmpty()) {
                            for(Screen_Field__c scf : screenFields){
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
                    }
                }
                else{
                    screenFields = [SELECT Id,Form_Name__c , Parent_Screen__r.Form_Name__c,Applicant_Type_Visibility__c, Name,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c, Picklist_Dependent_On_RecordType__c,
                                    Is_Picklist__c,Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,Applicable_For__c,Filtered_Picklist_Values__c,Show_in_words__c,
                                    Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c,Read_Field_Name__c,Read_Object_Name__c,Section_Seperator__c,Section_Name__c,Applicable_For_Products__c,
                                    Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c, Screen_Name__c,Is_Multipicklist__c,Enable_for__c
                                    FROM Screen_Field__c
                                    WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Form_Name__c =: formIdentifier
                                    order by Field_Sequence__c ASC];
                    screenFieldToReturn.addAll(screenFields);
                }
            }
            else{
                screenFields = [SELECT Id,Form_Name__c , Parent_Screen__r.Form_Name__c,Applicant_Type_Visibility__c, Name,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c, Picklist_Dependent_On_RecordType__c,
                                    Is_Picklist__c,Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,Applicable_For__c,Filtered_Picklist_Values__c,Show_in_words__c,
                                    Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c,Read_Field_Name__c,Read_Object_Name__c,Section_Seperator__c,Section_Name__c,Applicable_For_Products__c,
                                    Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c, Screen_Name__c,Is_Multipicklist__c,Enable_for__c
                                    FROM Screen_Field__c
                                    WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Form_Name__c =: formIdentifier
                                    order by Field_Sequence__c ASC];
                screenFieldToReturn.addAll(screenFields);
                // if(string.isNotBlank(loanId)){
                //     screenFields = [SELECT Id,Form_Name__c , Parent_Screen__r.Form_Name__c,Applicant_Type_Visibility__c, Name,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c, Picklist_Dependent_On_RecordType__c,
                //                     Is_Picklist__c,Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,Applicable_For__c,Filtered_Picklist_Values__c,Show_in_words__c,
                //                     Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c,Read_Field_Name__c,Read_Object_Name__c,Section_Seperator__c,Section_Name__c,Applicable_For_Products__c,
                //                     Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c, Screen_Name__c,Is_Multipicklist__c,Enable_for__c
                //                     FROM Screen_Field__c
                //                     WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Form_Name__c =: formIdentifier
                //                     order by Field_Sequence__c ASC];
                //     List<Opportunity> loanList = [Select Id, Login_Completion_Stage__c, Product__c from Opportunity where id =: loanId And Login_Completion_Stage__c != null];
                //     List<Opportunity> loanList2 = [Select Id, Login_Completion_Stage__c, Product__c from Opportunity where id =: loanId];
                //     List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Customer_Profile__c from Application_Applicant__c where Loan_Application__c=: loanId and Applicant_Type__c = 'Primary Applicant'];
                //     //HL-ISHI-13-10
                //     List<Product2> prodList = [Select Id, Name from Product2 where Loan_Application__c =: loanId and RecordType.Name = 'Product' and Name =: loanList2[0].Product__c limit 1];
                //     //HL-ISHI-13-10
                //     if(!loanList2.isEmpty()) {
                //             for(Screen_Field__c scf : screenFields){
                //             //HL-ISHI-13-10
                //             if(isHlRelated){
                //                 if(!prodList.isEmpty()){
                //                     if(String.isNotBlank(scf.Applicable_For_Products__c)){
                //                         List<String> applicableProdList = scf.Applicable_For_Products__c.split(',');
                //                         if(applicableProdList.contains(prodList[0].Name)){
                //                             screenFieldToReturn.add(scf);
                //                         }
                //                     }
                //                 }
                //                 else{
                //                     screenFieldToReturn.add(scf);
                //                 }
                //             }
                //             else{
                //                 screenFieldToReturn.add(scf);
                //             }
                //             //HL-ISHI-13-10
                //         }
                //     }
                // }
                // else{
                //     screenFields = [SELECT Id,Form_Name__c , Parent_Screen__r.Form_Name__c,Applicant_Type_Visibility__c, Name,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c, Picklist_Dependent_On_RecordType__c,
                //                     Is_Picklist__c,Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,Applicable_For__c,Filtered_Picklist_Values__c,Show_in_words__c,
                //                     Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c,Read_Field_Name__c,Read_Object_Name__c,Section_Seperator__c,Section_Name__c,Applicable_For_Products__c,
                //                     Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c, Screen_Name__c,Is_Multipicklist__c,Enable_for__c
                //                     FROM Screen_Field__c
                //                     WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Form_Name__c =: formIdentifier
                //                     order by Field_Sequence__c ASC];
                //     screenFieldToReturn.addAll(screenFields);
                // }
            }
            System.debug('screenfields'+screenFieldToReturn);
            return screenFieldToReturn;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage() + e.getStackTraceString());
        }
    }
    
    
    
    
    @AuraEnabled
    public static List<Map<String, String>> getPicklistValues(string storageObject, string storageField) {
        System.debug('StorageObject' +storageObject);
         System.debug('StorageObject' +storageField);
        try{
            SObjectType picklistObjectType = ((SObject) Type.forName(storageObject).newInstance()).getSObjectType();
    
            DescribeSObjectResult picklistObject = picklistObjectType.getDescribe();
            Schema.DescribeFieldResult picklistField = picklistObject.fields.getMap().get(storageField).getDescribe();
            List<Schema.PicklistEntry> entries = picklistField.getPicklistValues();
            List<Map<String, String>> values = new List<Map<String, String>>();
            
            for(Schema.PicklistEntry entry : entries) {
                Map<String, String> valueMap = new Map<String, String>();
                valueMap.put(Constants.LABEL_CONSTANT, entry.getLabel());
                valueMap.put(Constants.VALUE_CONSTANT, entry.getValue());
                values.add(valueMap);
            }
            return values;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }    
    
    @AuraEnabled
    public static RecordIds savecreateLoanDetails(string loanId, String fieldsDataMap, String formIdentifier, String screenName, String parentScreen, String applicantDetId) {
        RecordIds recordData = new RecordIds();
        System.debug('applicant id'+applicantDetId);
        try {
            System.debug('fieldsDataMap -->' + fieldsDataMap);
            String recordId;
            System.debug('formIdentifier>'+formIdentifier);
            Map<String, Object> objectDetailsMap = (Map<String, Object>) JSON.deserializeUntyped(fieldsDataMap);
            
            System.debug('objectDetailsMap -->' + objectDetailsMap);
            
            List<SObject> dataToInsert = new List<SObject>();
            List<SObject> addressData = new List<SObject>();
            List<SObject> finalDataToCommit = new List<SObject>();
            
            for(String storageObject : objectDetailsMap.keySet()) {
                Schema.SObjectType targetType = Schema.getGlobalDescribe().get(storageObject);
                Sobject objectToInsert = targetType.newSObject();
                String objectName = targetType.getDescribe().getName();
                
                Map<String, Object> fieldValues = (Map<String, Object>) objectDetailsMap.get(storageObject);
                for(String fieldName : fieldValues.keySet()) {
                    
                    Object fieldValue = fieldValues.get(fieldName);
                    System.debug('fieldName----'+fieldName);
                    System.debug('fieldValue-----'+fieldValue);
                    //system.debug('fieldValue: '+fieldValue);
                    
                    if(fieldName.contains('.')) {
                        List<string> fieldTypeTmp = fieldName.split('\\.');
                        fieldName = fieldTypeTmp[0].replace('__r', '__c');
                    }
                    if(fieldName.contains('undefined')){
                        System.debug('fieldName 142');
                        continue;
                    }
                    string fieldType = String.valueOf(targetType.getDescribe().fields.getMap().get(fieldName).getDescribe().getType());
                    system.debug('fieldType: '+fieldType);
                    
                    if(fieldType == 'TIME'){
                        String timeString = String.valueof(fieldValue);
                        List<String> timeParts = timeString.split(':');
                        Integer hours = Integer.valueOf(timeParts[0]);
                        Integer minutes = Integer.valueOf(timeParts[1]);
                        Integer seconds = Integer.valueOf(timeParts[2].split('\\.')[0]);
                        Integer milliseconds = Integer.valueOf(timeParts[2].split('\\.')[1]);
                        Time visitedTime = Time.newInstance(hours, minutes, seconds, milliseconds);
                        objectToInsert.put(fieldName, visitedTime);
                    }
                    if(fieldType == 'DATE'){
                        System.debug('fieldValue: '+fieldValue);
                        System.debug('fieldName: '+fieldName);
                        if (fieldValue != null && String.valueOf(fieldValue).trim() != '') {
                        objectToInsert.put(fieldName, Date.valueOf((String.valueof(fieldValue))));
                        }
                        System.debug('objectToInsert----'+objectToInsert);
                    }
                    else if(fieldType == 'CURRENCY' || fieldType == 'PERCENT' || fieldType == 'DOUBLE'){
                        objectToInsert.put(fieldName, Decimal.valueOf(String.valueof(fieldValue)));
                    }
                    else {
                        objectToInsert.put(fieldName, fieldValue);
                    }
                }
                system.debug('objectToInsert: '+objectToInsert);
                
                if(objectName == 'Applicant_Address__c') {
                    if(fieldValues != null && fieldValues.keySet().size()>0){
                        addressData.add(objectToInsert); // Add to address data
                    }
                }
                else if(objectName == 'Opportunity') {
                    if(string.isBlank(loanId)) {
                        
                        objectToInsert.put('StageName', 'Draft');
                        objectToInsert.put('Status__c', 'New');
                        objectToInsert.put('Login_Completion_Stage__c', 'Aadhar Capture Stage');
                        finalDataToCommit.add(objectToInsert);
                        // insert objectToInsert;
                        
                        // recordId = objectToInsert.Id;
                    }
                    else {
                        if(fieldValues != null && fieldValues.keySet().size()>0){
                            recordId = loanId;
                            objectToInsert.put('Id', loanId);
                            finalDataToCommit.add(objectToInsert);
                            // Database.update(objectToInsert);
                        }
                        
                    }
                }
                else {
                    if(fieldValues != null && fieldValues.keySet().size()>0){
                        System.debug('Object to insert>'+objectToInsert);
                        dataToInsert.add(objectToInsert);
                        if(fieldValues.containsKey('Loan_Application__c') && 
                           (formIdentifier == 'Builder Details' || formIdentifier == 'Seller Details')){//Sanwar Removed && String.isNotBlank(applicantDetId)
                             finalDataToCommit.add(objectToInsert);
                        }
                        
                       // finalDataToCommit.add(objectToInsert);
                    }
                    
                }
            }
            if(finalDataToCommit.size()>0){
                Upsert finalDataToCommit[0];
                recordId = finalDataToCommit[0].id;
            }
            System.debug('recordId -->' + recordId);
            
            if(string.isNotBlank(loanId) && String.isNotBlank(applicantDetId)) {
                List<SObject> sObjectList = [SELECT Id FROM Application_Applicant__c WHERE Id =: applicantDetId LIMIT 1];
                for(Sobject iterSObject : dataToInsert) {
                    String objectTypeName = iterSObject.getSObjectType().getDescribe().getName();
                    if(objectTypeName == 'Application_Applicant__c') {
                        if(!sObjectList.isEmpty()) {
                            iterSObject.put('Id', sObjectList[0].Id);
                            recordData.applicantId = sObjectList[0].Id;
                        }
                    }
                }
                Database.update(dataToInsert);
            }
            // else {
            //     for(Sobject iterSObject : dataToInsert) {
            //         String objectTypeName = iterSObject.getSObjectType().getDescribe().getName();
            
            //         if(objectTypeName == 'Application_Applicant__c') {
            //             Account newAccount = new Account();
            //             newAccount.Name = iterSObject.get('First_Name__c') + ' ' + iterSObject.get('Last_Name__c');
            //             insert newAccount;
            
            //             iterSObject.put('Customer__c', newAccount.Id);
            //             iterSObject.put('Opportunity', recordId);
            //             insert iterSObject;
            
            //             recordData.loanId = recordId;
            //             recordData.applicantId = iterSObject.Id;
            //         }
            //     }
            // }
            
            if(!addressData.isEmpty()) {
                List<SObject> addressToUpsert = new List<Applicant_Address__c>();
                List<Application_Applicant__c> coapplicantdetails = new List<Application_Applicant__c>();
                System.debug('adressData>'+addressData);
                List<Application_Applicant__c> applicantdetails = [SELECT Id, Customer__c FROM Application_Applicant__c WHERE id =: applicantDetId LIMIT 1];
                
                if(!applicantdetails.isEmpty()) {
                    List<String> addrTypeList = new List<String>();
                    for(SObject address : addressData) {
                        String addressType = (String) address.get('Address_Type__c');
                        addrTypeList.add(addressType);
                    }
                    List<Applicant_Address__c> presentAddressList = [SELECT Id,Address_Type__c FROM Applicant_Address__c WHERE Applicant__c =: applicantdetails[0].Id AND Address_Type__c in: addrTypeList];
                    Map<String,Applicant_Address__c> presentAddressMap = new Map<String,Applicant_Address__c>();
                    for(Applicant_Address__c ap : presentAddressList){
                        presentAddressMap.put(ap.Address_Type__c,ap);
                    }
                    List<Customer_Address__c> customerAddrList = new List<Customer_Address__c>();
                    for(String str : addrTypeList){
                        Customer_Address__c newCustomerAddress = new Customer_Address__c();
                        newCustomerAddress.Customer__c = applicantdetails[0].Customer__c;
                        newCustomerAddress.Address_Type__c = str;
                        customerAddrList.add(newCustomerAddress);
                        // insert newCustomerAddress;
                    }
                    Insert customerAddrList;
                    List<Customer_Address__c> customerAddrQuery = [Select Id, Address_Type__c from Customer_Address__c where id in: customerAddrList];
                    Map<String,Customer_Address__c> customerAddrMap = new Map<String,Customer_Address__c>();
                    for(Customer_Address__c c : customerAddrQuery){
                        customerAddrMap.put(c.Address_Type__c,c);
                    }
                    // MARKED CHANGE: Handling for multiple address types
                    // List<Applicant_Address__c> presentAddress = [SELECT Id FROM Applicant_Address__c WHERE Applicant__c =: applicantdetails[0].Id AND Address_Type__c =: addressType LIMIT 1];
                    for(SObject address : addressData) {
                        String addressType = (String) address.get('Address_Type__c');
                        System.debug('Address_Type__c --> ' + addressType);
                        List<Applicant_Address__c> presentAddress = new List<Applicant_Address__c>();
                        if(presentAddressMap.containsKey(addressType)){
                            presentAddress.add(presentAddressMap.get(addressType));
                        } 
                        if(formIdentifier == 'Business Address Form') {
                            // List<Applicant_Address__c> presentAddress = new List<Applicant_Address__c>();
                            // if(presentAddressMap.containsKey(addressType)){
                            //     presentAddress.add(presentAddressMap.get(addressType));
                            // } 
                            if(screenName == 'Add Business Address' && addressType != null) {
                                
                                // MARKED CHANGE: Fetch existing address based on Address_Type__c
                                if(!presentAddress.isEmpty()) {
                                    address.put('Id', presentAddress[0].Id);
                                    addressToUpsert.add(address);
                                    // Database.update(address);
                                }
                                else {
                                    // MARKED CHANGE: Create a new Customer Address record for the specific Address_Type__c
                                    // Customer_Address__c newCustomerAddress = new Customer_Address__c();
                                    // newCustomerAddress.Customer__c = applicantdetails[0].Customer__c;
                                    // newCustomerAddress.Address_Type__c = addressType;
                                    // insert newCustomerAddress;
                                    
                                    address.put('Applicant__c', applicantdetails[0].Id);
                                    address.put('Customer_Address__c', customerAddrMap.get(addressType).Id);
                                    address.put('Address_Type__c', addressType);
                                    addressToUpsert.add(address);
                                    // insert address;
                                }
                            }
                        }
                        else if(formIdentifier == 'Loan Application Login Form') {
                            
                            //List<Applicant_Address__c> presentAddress = [SELECT Id FROM Applicant_Address__c WHERE Applicant__c =: applicantdetails[0].Id AND Address_Type__c = 'Current' LIMIT 1];
                            if(!presentAddress.isEmpty()) {
                                address.put('Id', presentAddress[0].Id);
                                addressToUpsert.add(address);
                                // Database.update(addressData);
                            }
                            else {
                                // createAddressData(applicantdetails[0].Customer__c, applicantdetails[0].Id, 'Current', address, addressData);
                                
                                // Customer_Address__c newCustomerAddress = new Customer_Address__c();
                                // newCustomerAddress.Customer__c = applicantdetails[0].Customer__c;
                                // newCustomerAddress.Address_Type__c = 'Current';
                                // insert newCustomerAddress;
                                
                                address.put('Applicant__c', applicantdetails[0].Id);
                                address.put('Customer_Address__c', customerAddrMap.get(addressType).Id);
                                address.put('Address_Type__c', 'Current');
                                addressToUpsert.add(address);
                                // insert addressData;
                            }
                        }
                        else {
                            system.debug('formIdentifier:: '+formIdentifier);
                            
                            // List<Applicant_Address__c> presentAddress = [SELECT Id FROM Applicant_Address__c WHERE Applicant__c =: applicantdetails[0].Id AND Address_Type__c = 'Permanent' LIMIT 1];
                            if(!presentAddress.isEmpty()) {
                                address.put('Id', presentAddress[0].Id);
                                // Database.update(addressData);
                                addressToUpsert.add(address);
                            }
                            else {
                                // createAddressData(applicantdetails[0].Customer__c, applicantdetails[0].Id, 'Permanent', address, addressData);
                                
                                // Customer_Address__c newCustomerAddress = new Customer_Address__c();
                                // newCustomerAddress.Customer__c = applicantdetails[0].Customer__c;
                                // newCustomerAddress.Address_Type__c = 'Permanent';
                                // insert newCustomerAddress;
                                System.debug('Inside else for address insert');
                                address.put('Applicant__c', applicantdetails[0].Id);
                                address.put('Customer_Address__c', customerAddrMap.get(addressType).Id);
                                address.put('Address_Type__c', 'Permanent');
                                addressToUpsert.add(address);
                                // insert addressData;
                            }
                        }
                    }
                }
                
                if(parentScreen == 'Co Applicant'){
                    
                    coapplicantdetails = [SELECT Id, Customer__c FROM Application_Applicant__c WHERE Applicant_Type__c = 'Co Applicant' AND Loan_application__c =: loanId AND Id =: applicantDetId LIMIT 1];
                    if(!coapplicantdetails.isEmpty()){
                        List<String> addrTypeList = new List<String>();
                        for(SObject address : addressData) {
                            String addressType = (String) address.get('Address_Type__c');
                            addrTypeList.add(addressType);
                        }
                        List<Applicant_Address__c> presentAddressList = [SELECT Id,Address_Type__c FROM Applicant_Address__c WHERE Applicant__c =: coapplicantdetails[0].Id AND Address_Type__c in: addrTypeList];
                        Map<String,Applicant_Address__c> presentAddressMap = new Map<String,Applicant_Address__c>();
                        for(Applicant_Address__c ap : presentAddressList){
                            presentAddressMap.put(ap.Address_Type__c,ap);
                        }
                        List<Customer_Address__c> customerAddrList = new List<Customer_Address__c>();
                        for(String str : addrTypeList){
                            Customer_Address__c newCustomerAddress = new Customer_Address__c();
                            newCustomerAddress.Customer__c = coapplicantdetails[0].Customer__c;
                            newCustomerAddress.Address_Type__c = str;
                            customerAddrList.add(newCustomerAddress);
                            // insert newCustomerAddress;
                        }
                        Insert customerAddrList;
                        List<Customer_Address__c> customerAddrQuery = [Select Id, Address_Type__c from Customer_Address__c where id in: customerAddrList];
                        Map<String,Customer_Address__c> customerAddrMap = new Map<String,Customer_Address__c>();
                        for(Customer_Address__c c : customerAddrQuery){
                            customerAddrMap.put(c.Address_Type__c,c);
                        }
                        // MARKED CHANGE: Handling for multiple address types
                        for(SObject address : addressData) {
                            String addressType = (String) address.get('Address_Type__c');
                            System.debug('Address_Type__c --> ' + addressType);
                            List<Applicant_Address__c> presentAddress = new List<Applicant_Address__c>();
                            if(presentAddressMap.containsKey(addressType)){
                                presentAddress.add(presentAddressMap.get(addressType));
                            } 
                            if(formIdentifier == 'Business Address Form') {
                                
                                if(screenName == 'Add Business Address' && addressType != null) {
                                    
                                    // MARKED CHANGE: Fetch existing address based on Address_Type__c
                                    if(!presentAddress.isEmpty()) {
                                        // Update the existing address record
                                        address.put('Id', presentAddress[0].Id);
                                    }
                                    else {
                                        // Create a new Customer Address record for the specific Address_Type__c
                                        // Customer_Address__c newCustomerAddress = new Customer_Address__c();
                                        // newCustomerAddress.Customer__c = coapplicantdetails[0].Customer__c;
                                        // newCustomerAddress.Address_Type__c = addressType;
                                        // insert newCustomerAddress;
                                        
                                        // Prepare the new address data
                                        address.put('Applicant__c', coapplicantdetails[0].Id);
                                        address.put('Customer_Address__c', customerAddrMap.get(addressType).Id);
                                        address.put('Address_Type__c', addressType);
                                    }
                                    
                                    // Use upsert to handle both insert and update scenarios
                                    addressToUpsert.add(address);
                                    // upsert address;
                                }
                            }
                            else if(formIdentifier == 'Loan Application Login Form') {
                                if(presentAddressMap.containsKey('Current')){
                                    presentAddress.add(presentAddressMap.get(addressType));
                                }
                                // List<Applicant_Address__c> presentAddress = [SELECT Id FROM Applicant_Address__c WHERE Applicant__c =: coapplicantdetails[0].Id AND Address_Type__c = 'Current' LIMIT 1];
                                if(!presentAddress.isEmpty()) {
                                    address.put('Id', presentAddress[0].Id);
                                    // Database.update(addressData);
                                    addressToUpsert.add(address);
                                }
                                else {
                                    // createAddressData(coapplicantdetails[0].Customer__c, coapplicantdetails[0].Id, 'Current', address, addressData);
                                    // Customer_Address__c newCustomerAddress = new Customer_Address__c();
                                    // newCustomerAddress.Customer__c = customerId;
                                    // newCustomerAddress.Address_Type__c = addType;
                                    // insert newCustomerAddress;
                                    
                                    address.put('Applicant__c', coapplicantdetails[0].Customer__c);
                                    address.put('Customer_Address__c', customerAddrMap.get(addressType).Id);
                                    address.put('Address_Type__c', addressType);
                                    addressToUpsert.add(address);
                                    // insert addressData;
                                    // Customer_Address__c newCustomerAddress = new Customer_Address__c();
                                    // newCustomerAddress.Customer__c = coapplicantdetails[0].Customer__c;
                                    // newCustomerAddress.Address_Type__c = 'Current';
                                    // insert newCustomerAddress;
                                    
                                    // address.put('Applicant__c', coapplicantdetails[0].Id);
                                    // address.put('Customer_Address__c', newCustomerAddress.Id);
                                    // address.put('Address_Type__c', 'Current');
                                    // insert addressData;
                                }
                            }
                            else {
                                system.debug('formIdentifier:: '+formIdentifier);
                                if(presentAddressMap.containsKey('Permanent')){
                                    presentAddress.add(presentAddressMap.get(addressType));
                                }
                                // List<Applicant_Address__c> presentAddress = [SELECT Id FROM Applicant_Address__c WHERE Applicant__c =: coapplicantdetails[0].Id AND Address_Type__c = 'Permanent' LIMIT 1];
                                if(!presentAddress.isEmpty()) {
                                    address.put('Id', presentAddress[0].Id);
                                    // Database.update(addressData);
                                    addressToUpsert.add(address);
                                }
                                else {
                                    // createAddressData(coapplicantdetails[0].Customer__c, coapplicantdetails[0].Id, 'Permanent', address, addressData);
                                    
                                    // Customer_Address__c newCustomerAddress = new Customer_Address__c();
                                    // newCustomerAddress.Customer__c = coapplicantdetails[0].Customer__c;
                                    // newCustomerAddress.Address_Type__c = 'Permanent';
                                    // insert newCustomerAddress;
                                    
                                    address.put('Applicant__c', coapplicantdetails[0].Id);
                                    address.put('Customer_Address__c', customerAddrMap.get(addressType).Id);
                                    address.put('Address_Type__c', 'Permanent');
                                    // insert addressData;
                                    addressToUpsert.add(address);
                                }
                            }
                        }
                    }
                }
                if(addressToUpsert.size()>0){
                    System.debug('Before address Upsert>>');
                    Upsert addressToUpsert;
                }
            }
            
            recordData.loanId = recordId;
            
            return recordData;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage()+'-----'+e.getStackTraceString());
        }
    }
    
    @AuraEnabled
    public static List<Application_Applicant__c>  getExistingCustomer(string loanId,string applicantDetId){
        List<Application_Applicant__c> applicationList = [SELECT Id,Applicant_Type__c,Mobile_Number__c,Customer_Profile__c,Customer_Type__c,PAN_Number__c,Sector__c FROM Application_Applicant__c WHERE Loan_Application__c =: loanId AND Id !=: applicantDetId];
        return applicationList;
    }
    
    @Testvisible
    private static void createAddressData(string customerId, string applicantId, string addType, SObject address, List<SObject> addressData) {
        Boolean notTestRunning = !System.Test.isRunningTest();
        Customer_Address__c newCustomerAddress = new Customer_Address__c();
        newCustomerAddress.Customer__c = customerId;
        newCustomerAddress.Address_Type__c = addType;
        if(notTestRunning)insert newCustomerAddress;
    
        address.put('Applicant__c', applicantId);
        address.put('Customer_Address__c', newCustomerAddress.Id);
        address.put('Address_Type__c', addType);
        if(notTestRunning)insert addressData;
    }
    
    public class RecordIds {
        @AuraEnabled public String loanId;
        @AuraEnabled public String applicantId;
    }
    
    public class MyPickListInfo{
        public String validFor;
    }
    
    // @AuraEnabled
    // public static Map<String, List<Map<String, String>>> getFieldDependencies(String objectName, String controllingField, String dependentField){
    //     System.debug('objectName: ' + objectName);
    //     System.debug('controllingField: ' + controllingField);
    //     System.debug('dependentField: ' + dependentField);
    //     Map<String, List<Map<String, String>>> controllingInfo = new Map<String, List<Map<String, String>>>();
    //     Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
    //     Schema.DescribeSObjectResult describeResult = objType.getDescribe();
    //     Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(controllingField).getDescribe();
    //     Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(dependentField).getDescribe();
    //     List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
    //     List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();
        
    //     for(Schema.PicklistEntry currControllingValue : controllingValues){
    //         controllingInfo.put(currControllingValue.getLabel(), new List<Map<String, String>>());
    //     }
    //     System.debug('dependentValues----'+dependentValues);
    //     for(Schema.PicklistEntry currDependentValue : dependentValues){
    //         System.debug('currDependentValue----'+currDependentValue);
    //         String jsonString = JSON.serialize(currDependentValue);
    //         System.debug('jsonString---'+jsonString);
    //         MyPickListInfo info = (MyPickListInfo) JSON.deserialize(jsonString, MyPickListInfo.class);
    //         String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();
    //         Integer baseCount = 0;
            
    //         for(Integer curr : hexString.getChars()){
                
    //             Integer val = 0;
    //             if(curr >= 65){
    //                 val = curr - 65 + 10;
    //             }
    //             else{
    //                 val = curr - 48;
    //             }
                
    //             if((val & 8) == 8){
                    
    //                 System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 0].getLabel());
    //                 Map<String, String> valueMap = new Map<String, String>();
    //                 valueMap.put(Constants.LABEL_CONSTANT, currDependentValue.getLabel());
    //                 valueMap.put(Constants.VALUE_CONSTANT, currDependentValue.getValue());
    //                 controllingInfo.get(controllingValues[baseCount + 0].getLabel()).add(valueMap);
    //             }
    //             if((val & 4) == 4){
                    
    //                 System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 1].getLabel());
    //                 Map<String, String> valueMap = new Map<String, String>();
    //                 valueMap.put(Constants.LABEL_CONSTANT, currDependentValue.getLabel());
    //                 valueMap.put(Constants.VALUE_CONSTANT, currDependentValue.getValue());
    //                 controllingInfo.get(controllingValues[baseCount + 1].getLabel()).add(valueMap);
    //             }
    //             if((val & 2) == 2){
                    
    //                 System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 2].getLabel());
    //                 Map<String, String> valueMap = new Map<String, String>();
    //                 valueMap.put(Constants.LABEL_CONSTANT, currDependentValue.getLabel());
    //                 valueMap.put(Constants.VALUE_CONSTANT, currDependentValue.getValue());
    //                 controllingInfo.get(controllingValues[baseCount + 2].getLabel()).add(valueMap);
    //             }
    //             if((val & 1) == 1){
                    
    //                 System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 3].getLabel());
    //                 Map<String, String> valueMap = new Map<String, String>();
    //                 valueMap.put(Constants.LABEL_CONSTANT, currDependentValue.getLabel());
    //                 valueMap.put(Constants.VALUE_CONSTANT, currDependentValue.getValue());
    //                 controllingInfo.get(controllingValues[baseCount + 3].getLabel()).add(valueMap);
    //             }
    //             baseCount += 4;
    //         }
    //     }
        
    //     System.debug('ControllingInfo -->' + controllingInfo);
    //     return controllingInfo;
    // }
    @AuraEnabled
    public static Map<String, List<Map<String, String>>> getFieldDependencies(
        String objectName,
        String controllingField,
        String dependentField
    ) {
        Map<String, List<Map<String, String>>> controllingInfo =
            new Map<String, List<Map<String, String>>>();

        // Describe object
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType == null) {
            return controllingInfo;
        }

        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();

        // Describe fields
        Schema.DescribeFieldResult controllingDescribe =
            objDescribe.fields.getMap().get(controllingField).getDescribe();
        Schema.DescribeFieldResult dependentDescribe =
            objDescribe.fields.getMap().get(dependentField).getDescribe();

        List<Schema.PicklistEntry> controllingValues =
            controllingDescribe.getPicklistValues();
        List<Schema.PicklistEntry> dependentValues =
            dependentDescribe.getPicklistValues();

        Integer controllingSize = controllingValues.size();

        // Initialize map with controlling labels
        for (Schema.PicklistEntry ctrl : controllingValues) {
            controllingInfo.put(ctrl.getLabel(), new List<Map<String, String>>());
        }

        // Iterate dependent picklist values
        for (Schema.PicklistEntry dep : dependentValues) {

            // Deserialize to access validFor
            String jsonStr = JSON.serialize(dep);
            MyPickListInfo info =
                (MyPickListInfo) JSON.deserialize(jsonStr, MyPickListInfo.class);

            if (String.isBlank(info.validFor)) {
                continue;
            }

            // Decode validFor bitmask
            String hex =
                EncodingUtil.convertToHex(
                    EncodingUtil.base64Decode(info.validFor)
                ).toUpperCase();

            Integer baseIndex = 0;

            for (Integer ch : hex.getChars()) {

                Integer val;
                if (ch >= 65) {        // A-F
                    val = ch - 65 + 10;
                } else {               // 0-9
                    val = ch - 48;
                }

                // Bit 8 (1000)
                if ((val & 8) == 8 && baseIndex < controllingSize) {
                    addDependent(controllingInfo, controllingValues, baseIndex, dep);
                }

                // Bit 4 (0100)
                if ((val & 4) == 4 && baseIndex + 1 < controllingSize) {
                    addDependent(controllingInfo, controllingValues, baseIndex + 1, dep);
                }

                // Bit 2 (0010)
                if ((val & 2) == 2 && baseIndex + 2 < controllingSize) {
                    addDependent(controllingInfo, controllingValues, baseIndex + 2, dep);
                }

                // Bit 1 (0001)
                if ((val & 1) == 1 && baseIndex + 3 < controllingSize) {
                    addDependent(controllingInfo, controllingValues, baseIndex + 3, dep);
                }

                baseIndex += 4;
            }
        }

        return controllingInfo;
    }
    private static void addDependent(
        Map<String, List<Map<String, String>>> controllingInfo,
        List<Schema.PicklistEntry> controllingValues,
        Integer index,
        Schema.PicklistEntry dependent
    ) {
        Map<String, String> valueMap = new Map<String, String>();
        valueMap.put(Constants.LABEL_CONSTANT, dependent.getLabel());
        valueMap.put(Constants.VALUE_CONSTANT, dependent.getValue());

        controllingInfo
            .get(controllingValues[index].getLabel())
            .add(valueMap);
    }
    
    @AuraEnabled
    public static Decimal percentCompletion(String loanId){
        return LoanActionController.percentCompletion(loanId);
    }
    
    public static Decimal customRoundingOffMethod(Object value) {
        Decimal decimalValue = (Decimal) value;

        Decimal roundedValue;
        Decimal fractionalPart = decimalValue - decimalValue.setScale(0, RoundingMode.FLOOR);
        if (fractionalPart >= 0.5) {
            roundedValue = decimalValue.setScale(0, RoundingMode.CEILING);
        } else {
            roundedValue = decimalValue.setScale(0, RoundingMode.FLOOR);
        }
        return roundedValue;
    }


     
    @AuraEnabled
    public static List<DetailsWrapper> getLoanDetailsFromReadObject(String screenName, String loanId, String formIdentifier, String recordId,String loanType){
        try{
            String requiredLoanId = loanId;
            Opportunity opp = [select Id,Loan_Hierarchy__c,Split_Parent_Loan_Application__c,Product__c from Opportunity where Id = :loanId LIMIT 1];
            String productName = opp != null ? opp.Product__c : '';

            List<Charges_Insurance__c> chargeInsurances = [SELECT Id, Product_Name__c FROM Charges_Insurance__c  WHERE Loan_Application__c =:loanId and Product_Name__c =:productName]; //added by Kunal Bisht for SFHL-1404 - hotfix

            Utility_V1.ProductWrapper prodWrapper = Utility_V1.getProductDetails(new Map<String,String>{'oppId' => loanId}); //added by Kunal Bisht for SFHL-1404
            if((chargeInsurances.isEmpty() && prodWrapper.isHLRelated) || (opp.Loan_Hierarchy__c == 'Child' && opp.Split_Parent_Loan_Application__c != null && !prodWrapper.isHLRelated)){ //chargeInsurances and isHLRelated checks and OR condition added by Kunal Bisht for SFHL-1404
                requiredLoanId = opp.Split_Parent_Loan_Application__c;
            }

            String applicantType = 'Primary Applicant';
            List<DetailsWrapper> rowFields = new List<DetailsWrapper>();
            
            List<Screen_Field__c> screenFieldList = [Select Id, Field_Label__c,Applicant_Type_Visibility__c, Field_Placement__c, Read_Field_Name__c, Read_Object_Name__c, Field_Sequence__c, is_Lookup__c 
                                                     from Screen_Field__c 
                                                     where Is_Active__c = true and Parent_Screen__r.Is_Screen_Active__c = true and Parent_Screen__r.Master_Screen_Name__c =: screenName 
                                                     and Parent_Screen__r.Form_Name__c =: formIdentifier and Loan_Type__c=:loanType
                                                     order by Field_Sequence__c asc];
            
            Map<String, List<String>> objectToFieldsMap = new Map<String, List<String>>();
            Map<String, String> fieldApiTOLabelMap = new Map<String, String>();
            
            for(Screen_Field__c sc : screenFieldList){
                system.debug('sc.Read_Object_Name__c: '+sc.Read_Object_Name__c);
                system.debug('sc.Read_Field_Name__c: '+sc.Read_Field_Name__c);
                system.debug('sc.Field_Label__c: '+sc.Field_Label__c);
                
                fieldApiTOLabelMap.put(sc.Read_Field_Name__c, sc.Field_Label__c);
                
                if(objectToFieldsMap.containsKey(sc.Read_Object_Name__c)){
                    if(!objectToFieldsMap.get(sc.Read_Object_Name__c).contains(sc.Read_Field_Name__c)){
                        objectToFieldsMap.get(sc.Read_Object_Name__c).add(sc.Read_Field_Name__c);
                    }
                }
                else{
                    objectToFieldsMap.put(sc.Read_Object_Name__c, new List<String>{sc.Read_Field_Name__c});
                }
            }
            
            Map<String, List<SObject>> objectValuesMap = new Map<String, List<SObject>>();
            for(String objectName : objectToFieldsMap.keySet()){
                system.debug('objectName: '+objectName);
                if(String.isBlank(objectName)){ continue; }
                List<String> fieldApiNames = objectToFieldsMap.get(objectName);
                system.debug('fieldApiNames: '+fieldApiNames);
                
                String query = 'Select Id ';
                for(String fields : fieldApiNames){
                    query = query +', '+ fields;
                }
                
                switch on objectName {
                    
                    when 'Opportunity' {
                        query += ' FROM '+ objectName +' where Id = \'' + loanId + '\' LIMIT 1';
                    }
                    when 'Application_Applicant__c' {
                        query += ' FROM '+ objectName +' where Loan_Application__c = \'' + loanId + '\'' + ' AND Applicant_Type__c =: applicantType LIMIT 1';
                    }
                    when 'Legal__c' {
                        query += ' FROM '+ objectName +' where Id = \'' + loanId + '\'';
                    }
                    when 'Applicant_Address__c' {
                        
                        List<String> addressTypes = new List<String> {'Permanent'};
                            String addressSource = '';  // To store the selected address source
                        
                        if(formIdentifier == 'Current Address Form'){
                            addressTypes = new List<String> {'Current'};
                                }
                        else if(formIdentifier == 'Business Address Form'){
                            addressTypes = new List<String> {
                                'Regional Office', 
                                    'Registered Office', 
                                    'Project Site', 
                                    'Godown', 
                                    'Central Office', 
                                    'Factory Outlet'
                                    };
                                        }
                        
                        // Query the records in priority order and check for availability
                        List<String> priorityOrder = new List<String> {'Aadhaar', 'Passport', 'Voter Id', 'Driving License', 'Manual'};
                            for (String source : priorityOrder) {
                                // Query for records with the current address source in the priority list
                                List<Applicant_Address__c> records = [SELECT Id FROM Applicant_Address__c WHERE Applicant__r.Loan_Application__c = :loanId 
                                                                      AND Applicant__r.Applicant_Type__c = :applicantType 
                                                                      AND Address_Type__c IN :addressTypes 
                                                                      AND Address_Source__c = :source LIMIT 1];
                                
                                // If records are found, assign the address source and break out of the loop
                                if (!records.isEmpty()) {
                                    addressSource = source;
                                    break;
                                }
                            }
                        
                        // Build the query using the selected address source
                        query += ' FROM ' + objectName + 
                            ' WHERE Applicant__r.Loan_Application__c = \'' + loanId + '\'' + 
                            ' AND Applicant__r.Applicant_Type__c = :applicantType' + 
                            ' AND Address_Type__c IN :addressTypes' + 
                            ' AND Address_Source__c = :addressSource' + 
                            ' LIMIT 1';
                        
                        // Optionally, handle the case where no address source is found (if needed)
                        if (addressSource == '') {
                            // Handle the case where no address source was found
                            System.debug('No address source found for the given priority order.');
                        }
                    }
                    when 'Loan_Transaction__c' {
                        query += ' FROM '+ objectName +' where Loan_Application__c = \'' + loanId + '\'' +' AND RecordType.Name=' +'\'Transaction Details\'';
                    }
                    when 'Product2' {
                        query += ' FROM '+ objectName +' where Loan_Application__c = \'' + loanId + '\'';
                        if(screenName== 'Loan Details LAP'){
                            query += ' AND RecordType.Name= \'Sub Product\'';
                        }
                    }
                    when 'Charges_Insurance__c' {
                        query += ' FROM '+ objectName +' where Loan_Application__c = \'' + requiredLoanId + '\'' +' AND Product_Name__c = \'' + productName + '\'';
                    }
                    when 'OpportunityTeamMember' {
                        query += ' FROM '+ objectName +' where OpportunityId = \'' + loanId + '\'';
                    }
                    when 'Application_Collateral__c' {
                        query += ' FROM ' + objectName+ ' where HL_Loan_Application__c = \'' + loanId + '\'';
                    }
                    
                }
                System.debug('query -->'+query);
                
                List<SObject> sObjList = Database.query(query);
                if(!sObjList.isEmpty()){
                    if(objectValuesMap.containsKey(objectName)){
                        objectValuesMap.get(objectName).add(sObjList[0]);
                    }
                    else{
                        objectValuesMap.put(objectName, new List<SObject>{sObjList[0]});
                    }
                }
            }
            
            for(Screen_Field__c sc : screenFieldList){
                List<SObject> sObjList = objectValuesMap.get(sc.Read_Object_Name__c);
                if(sObjList != null){
                for(SObject sObj : sObjList){
                    //system.debug('sObj: '+sObj);
                    //system.debug('sc.Read_Field_Name__c: '+sc.Read_Field_Name__c);
                    
                    DetailsWrapper dw = new DetailsWrapper();
                    dw.fieldLabel = sc.Field_Label__c;
                    dw.fieldApiName = sc.Read_Field_Name__c;
                    dw.sequence = sc.Field_Sequence__c;
                    
                    if(sc.is_Lookup__c) {
                        List<string> lookupField = String.valueOf(sc.Read_Field_Name__c)?.split('\\.');
                        system.debug('lookupField: '+lookupField);
                        
                        // SObject parenObj = sObj?.getSobject(lookupField[0]);
                        // dw.lookUpfieldValue = parenObj?.get(lookupField[1]);
                        
                        // if(lookupField[0].contains('__r')){
                        //     dw.fieldValue = sObj?.get(lookupField[0].replace('__r', '__c'));
                        // }
                        // else {
                        //     dw.fieldValue = sObj?.get(lookupField[0]+'Id');
                        // }

                        Integer index = 0;
                        sObject parenObj = sObj;
                            
                        while(index < (lookupField.size() -1)){
                            if(parenObj != null){
                                parenObj = parenObj?.getSobject(lookupField[index]);
                            }
                            index++;
                        }

                        dw.lookUpfieldValue = parenObj?.get(lookupField[index]);

                        if(lookupField[0].contains('__r')){
                            dw.fieldValue = sObj?.get(lookupField[0].replace('__r', '__c'));
                        }
                        else {
                            dw.fieldValue = sObj?.get(lookupField[0] +'Id');
                        }
                    }
                    else {
                        if(sc.Read_Field_Name__c == 'Sanction_EMI__c' ){
                            

                            dw.fieldValue = (Object)customRoundingOffMethod(sObj?.get(sc.Read_Field_Name__c));
                        }
                        else{
                        dw.fieldValue = sObj?.get(sc.Read_Field_Name__c);
                        }
                    }
                    //system.debug('dw.fieldValue: '+dw.fieldValue);
                    
                    // if(sc.is_Lookup__c) {
                    //     SObject parenObj = sObj.getSobject(String.valueOf(sc.Read_Field_Name__c).split('\\.')[0]);//sc.Read_Object_Name__c;sObj.getSobject(String.valueOf(sc.Read_Field_Name__c).split('\\.')[0]);
                    //     dw.fieldValue = parenObj.get(String.valueOf(sc.Read_Field_Name__c).split('\\.')[1]);
                    // }
                    // else {
                    //     dw.fieldValue = sObj.get(sc.Read_Field_Name__c);
                    // }
                    
                    rowFields.add(dw);
                }
                }
            }
            
            return rowFields;
        }
        catch(Exception e){
            // throw new AuraHandledException(e.getMessage());
            throw new AuraHandledException('Error: ' + e.getMessage() + ' | Line: ' + e.getStackTraceString());
        }
    }
    
   @AuraEnabled
    public static List<DetailsWrapper> getLoanDetailsFromStorageObject(String screenName, String loanId, String formIdentifier, Id technicalEvaluationId, Id recordId ,String did){
        try{
            System.debug('recordId '+recordId);
            System.debug('did '+did);
            String applicantType;
            if(formIdentifier == 'Builder Details' || formIdentifier == 'Seller Details'){
                applicantType = (formIdentifier == 'Builder Details')? 'Builder' : 'Seller';
            }
            else{
             applicantType = 'Primary Applicant';
            }
            System.debug('formIdentifier '+formIdentifier);
            System.debug('applicant type'+applicantType);
            List<DetailsWrapper> rowFields = new List<DetailsWrapper>();
            
            List<Screen_Field__c> screenFieldList = [SELECT Id, Field_Label__c, Applicant_Type_Visibility__c,Field_Placement__c, Storage_Field__c, Storage_Object__c, Field_Sequence__c, is_Lookup__c, Read_Field_Name__c 
                                                     FROM Screen_Field__c 
                                                     WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Master_Screen_Name__c=: screenName 
                                                     AND Parent_Screen__r.Form_Name__c =: formIdentifier
                                                     ORDER BY Field_Sequence__c ASC];
            
            Map<String,List<String>> objectToFieldsMap = new Map<String,List<String>>();
            Map<String,String> fieldApiTOLabelMap = new Map<String,String>();
            
            for(Screen_Field__c sc : screenFieldList){
                system.debug('sc.Read_Object_Name__c: '+sc.Storage_Object__c);
                system.debug('sc.Read_Field_Name__c: '+sc.Storage_Field__c);
                system.debug('sc.Field_Label__c: '+sc.Field_Label__c);
                
                fieldApiTOLabelMap.put(sc.Storage_Field__c, sc.Field_Label__c);
                
                if(objectToFieldsMap.containsKey(sc.Storage_Object__c)){
                    if(!objectToFieldsMap.get(sc.Storage_Object__c).contains(sc.Storage_Field__c)){
                        objectToFieldsMap.get(sc.Storage_Object__c).add(sc.Storage_Field__c);
                    }
                }
                else{
                    objectToFieldsMap.put(sc.Storage_Object__c, new List<String>{sc.Storage_Field__c});
                }
            }
            
            Map<String,List<SObject>> objectValuesMap = new Map<String,List<SObject>>();
            for(String objectName : objectToFieldsMap.keySet()){
                List<String> fieldApiNames = objectToFieldsMap.get(objectName);
                if(formIdentifier == 'Builder Details' || formIdentifier == 'Seller Details'){
                    fieldApiNames.add('Applicant_Type__c');
                }
               // String query = 'Select Id ';
                if(!fieldApiNames.contains('Id')){
                    fieldApiNames.add(0,'Id');
                }
                /*for(String fields : fieldApiNames){
                    query = query +', '+ fields;
                }*/
                String query = 'SELECT ' + String.join(fieldApiNames,', ');
                System.debug('objectName: '+objectName);
                switch on objectName {
                    
                    when 'Opportunity' {
                        query += ' FROM '+ objectName +' where Id = \'' + loanId + '\' LIMIT 1';
                    }
                    when 'Application_Applicant__c' {
                        if(formIdentifier == 'CAM Details'){
                            System.debug('792');
                            query += ' FROM '+ objectName +' where Loan_Application__c = \'' + loanId+ '\'';
                            System.debug('790 query : '+query);
                        }
                        else if(recordId!=null){
                            System.debug('query-->'+query);
                            query += ' FROM '+ objectName +' where Loan_Application__c = \'' + loanId + '\'' + ' AND Id =:recordId  LIMIT 1';
                        }
                        else{
                            query += ' FROM '+ objectName +' where Loan_Application__c = \'' + loanId + '\'' + ' AND Applicant_Type__c =: applicantType LIMIT 1';
                        }
                    }
                    when 'Application_Verification__c' {
                            query += ' FROM '+ objectName +' where Id = \'' + recordId + '\' LIMIT 1';
                        }
                    when 'Applicant_Address__c' {
                        
                        List<String> addressTypes = new List<String> {'Permanent'};
                            
                            if(formIdentifier == 'Current Address Form'){
                                addressTypes = new List<String> {'Current'};
                                    query += ' ,Pincode__c FROM '+ objectName +' where Applicant__r.Loan_Application__c = \''+ loanId + '\'' +' AND Applicant__r.Applicant_Type__c =: applicantType AND Address_Type__c =: addressTypes LIMIT 1';
                            }
                            else if(formIdentifier.contains('Legal')){
                                query += ' ,Pincode__c FROM '+ objectName +' where Legal__c  = \''+ recordId + '\'' +'  LIMIT 1';
                            }
                            else if(formIdentifier.contains('HL Technical')){
                                query += ' ,Pincode__c FROM '+ objectName +' where Technical_Evaluation__c  = \''+ recordId + '\'' +'  LIMIT 1';
                            }
                        // else if(formIdentifier == 'Aadhaar Back'){
                        //     addressTypes = new List<String> {''};
                        //     query += ' ,Pincode__c FROM '+ objectName +' where Applicant__r.Loan_Application__c = \''+ loanId + '\'' +' AND Applicant__c =\''+ recordId + '\''+' AND Address_Source__c = \'Aadhaar\'  LIMIT 1';
                        // }
                        // else if(formIdentifier == 'Voter Back'){
                        //     addressTypes = new List<String> {''};
                        //     query += ' ,Pincode__c FROM '+ objectName +' where Applicant__r.Loan_Application__c = \''+ loanId + '\'' +' AND Applicant__c =\''+ recordId + '\''+' AND Address_Source__c = \'Voter Id\'  LIMIT 1'; 
                        // }
                        // else if(formIdentifier == 'Passport Back'){
                        //     addressTypes = new List<String> {''};
                        //     query += ' ,Pincode__c FROM '+ objectName +' where Applicant__r.Loan_Application__c = \''+ loanId + '\'' +' AND Applicant__c =\''+ recordId + '\''+' AND Address_Source__c = \'Passport\'  LIMIT 1'; 
                        // }
                        // else if(formIdentifier == 'DL' ){
                        //     addressTypes = new List<String> {''};
                        //     query += ' ,Pincode__c FROM '+ objectName +' where Applicant__r.Loan_Application__c = \''+ loanId + '\'' +' AND Applicant__c =\''+ recordId + '\''+' AND Address_Source__c = \'Driving License\'  LIMIT 1'; 
                        // }
                        // else if(formIdentifier =='Utility Bill not more than 2 months old' && recordId!=null ){
                        //     addressTypes = new List<String> {''};
                        //     query += ' ,Pincode__c FROM '+ objectName +' where Applicant__r.Loan_Application__c = \''+ loanId + '\'' +' AND Applicant__c =\''+ recordId + '\''+' AND Address_Source__c = \'Utility Bill\'  LIMIT 1'; 
                        // }
                        
                        else if(formIdentifier == 'Business Address Form' || Test.isRunningTest()){
                            addressTypes = new List<String>{
                                'Regional Office', 
                                    'Registered Office', 
                                    'Project Site', 
                                    'Godown', 
                                    'Central Office', 
                                    'Factory Outlet'
                                    };
                                        query += ' ,Pincode__c FROM '+ objectName +' where Id = \''+recordId +'\'' +'limit 1';
                        }else if(formIdentifier == 'Loan Login Form'){
                            query += '  FROM '+ objectName +' where Applicant__r.Loan_Application__c = \''+ loanId + '\'' +' AND Applicant__r.Applicant_Type__c =: applicantType AND Address_Type__c =: addressTypes LIMIT 1';
                        }
                        else if(did != null){
                            query += ' ,Pincode__c  FROM '+ objectName +' where Document_Details__c = \''+ did + '\'';
                        }
                        else if(recordId!=null ){
                            addressTypes = new List<String> {''};
                                query += ' ,Pincode__c FROM '+ objectName +' where Applicant__r.Loan_Application__c = \''+ loanId + '\'' +' AND Applicant__c =\''+ recordId + '\''+' AND  Document_Details__r.Document_Master__r.Name =:formIdentifier  LIMIT 1'; 
                        }
                        else{
                            query += ' ,Pincode__c FROM '+ objectName +' where Applicant__r.Loan_Application__c = \''+ loanId + '\'' +' AND Applicant__r.Applicant_Type__c =: applicantType AND Address_Type__c =: addressTypes LIMIT 1';
                        }
                        
                    }
                    when 'Document_Details__c' {
                        query += ' FROM '+ objectName +' where Id = \'' + did + '\' LIMIT 1';
                    }
                    when 'Bank_Details__c'{
                        query += ' FROM '+ objectName +' where Id = \'' + recordId + '\' LIMIT 1';
                    }
                    when 'Triangulation_Data__c' {
                        query += ' FROM '+ objectName +' where Loan_Application__c = \'' + loanId + '\''+' AND Application_Applicant__c  =\'' + recordId + '\'';
                    }
                    when 'Technical_Evaluation__c'{
                        if(String.valueOf(recordId).startsWith('006')){
                            query += ' FROM '+ objectName +' where HL_Loan_Application__c = \'' + recordId  + '\''+' AND  Id =:technicalEvaluationId LIMIT 1';  //did changes
                        }
                        else if(String.valueOf(recordId).startsWith('a0gBg')){
                            query += ' FROM '+ objectName +' where HL_Application_Collateral__c = \'' + recordId  + '\''+' AND  Id =:technicalEvaluationId LIMIT 1';  //did changes
                        }
                        else{
                             query += ' FROM '+ objectName +' where id = \'' + recordId  + '\' LIMIT 1';  //did changes
                        }
                        
                    }
                    when 'Legal__c'{
                        query += ' FROM '+ objectName +' where Id = \'' + recordId + '\' LIMIT 1';
                    }
                    when 'Product2'{
                        query += ' FROM '+ objectName +' where Id = \'' + recordId + '\' LIMIT 1';
                    }
                }
                System.debug('query -->'+query);
                
                List<SObject> sObjList = Database.query(query);
                //System.debug('sObjList: '+sObjList[0]);
                System.debug('sObjList size: ' + sObjList.size());
                System.debug('formIdentifier: '+formIdentifier);
                if(!sObjList.isEmpty()){
                    if(formIdentifier == 'CAM Details' || formIdentifier == 'Sales Triangular Screen'){
                        System.debug('832 '+sObjList);
                        if (objectValuesMap.containsKey(objectName)) {
                            objectValuesMap.get(objectName).addAll(sObjList);  // Add all records instead of just one
                        } else {
                            objectValuesMap.put(objectName, new List<SObject>(sObjList));  // Store all records directly
                        }
                    }
                    // else{
                    //     if(objectValuesMap.containsKey(objectName)){
                    //         objectValuesMap.get(objectName).add(sObjList[0]);
                    //     }
                    //     else{
                    //         objectValuesMap.put(objectName, new List<SObject>{sObjList[0]});
                    //     }
                    // }
                    else{
                        if(objectValuesMap.containsKey(objectName)){
                            objectValuesMap.get(objectName).addAll(sObjList);
                        }
                        else{
                            objectValuesMap.put(objectName, new List<SObject>(sObjList));
                        }
                    }
                }
            }
            
            for(Screen_Field__c sc : screenFieldList){
                if(objectValuesMap.containsKey(sc.Storage_Object__c)){
                    List<SObject> sObjList = objectValuesMap.get(sc.Storage_Object__c);
                    System.debug('Processing field: ' + sc.Storage_Field__c + ' | sObjList Size: ' + sObjList.size());
                    System.debug('sObjList contents: ' + sObjList);
                    if(sObjList != null){
                        if (sc.Storage_Object__c == 'Triangulation_Data__c') {
                            Map<String, Map<String, Object>> docTypeToFields = new Map<String, Map<String, Object>>();
                            Map<String, String> docTypeToSource = new Map<String, String>();
                            
                            for (SObject sObj : sObjList) {
                                String docType = (String) sObj.get('Document_Type__c');
                                String sourceType = (String) sObj.get('Source_Type__c');
                                String compositeKey = docType + '___' + sourceType;
                                
                                if (!docTypeToFields.containsKey(compositeKey)) {
                                    docTypeToFields.put(compositeKey, new Map<String, Object>());
                                    docTypeToSource.put(compositeKey, sourceType);
                                }
                                docTypeToFields.get(compositeKey).put(sc.Storage_Field__c, sObj.get(sc.Storage_Field__c));
                            }
                            
                            System.debug('docTypeToFields :'+docTypeToFields);
                            System.debug('docTypeToFieldsSource :'+docTypeToSource); 
                            
                            for (String compositeKey : docTypeToFields.keySet()) {
                                List<String> parts = compositeKey.split('___');
                                String docType = parts[0];
                                String sourceType = parts[1];
                                
                                Map<String, Object> fieldValues = docTypeToFields.get(compositeKey);
                                
                                if (fieldValues.containsKey(sc.Storage_Field__c)) {
                                    DetailsWrapper dw = new DetailsWrapper();
                                    dw.fieldLabel = sc.Field_Label__c + ' (' + docType + ' - ' + sourceType + ')';
                                    dw.fieldApiName = sc.Storage_Field__c;
                                    dw.sequence = sc.Field_Sequence__c;
                                    dw.fieldValue = fieldValues.get(sc.Storage_Field__c);
                                    rowFields.add(dw);
                                }
                            }
                        }
                        else {
                            List<String> fieldLabelList = new List<String>();
                            system.debug(sObjList);
                            for (SObject sObj : sObjList) {
                                DetailsWrapper dw = new DetailsWrapper();
                                dw.fieldLabel = sc.Field_Label__c;
                                dw.fieldApiName = sc.Storage_Field__c;
                                dw.sequence = sc.Field_Sequence__c;
                                 dw.fieldId = sObj.Id;
                               
                                 
                                // if(formIdentifier != 'Field Investigation Form' && formIdentifier != 'Field Investigation Form Business'){
                                //     dw.fieldValue = sObj.get(sc.Storage_Field__c);
                                
                                //     if(sc.is_Lookup__c){
                                //         dw.lookUpfieldValue = sObj.get(sc.Storage_Field__c);
                                //     }
                                // }
                                // else{
                                if(sc.is_Lookup__c) {
                                    Object val = get(sObj,String.valueOf(sc.Storage_Field__c));
                                    String fieldVal = (String) val;
                                    System.debug(fieldVal);
                                    dw.fieldValue = fieldVal;
                                    List<string> lookupField = String.valueOf(sc.Storage_Field__c).split('\\.');
                                    dw.lookUpfieldValue = sObj.get(lookupField[0].replace('__r', '__c'));
                                    //SObject parenObj = sObj.getSobject(lookupField[0]);
                                    // dw.lookUpfieldValue = parenObj.get(lookupField[1]);
                                    
                                    // dw.fieldValue = sObj.get(lookupField[0].replace('__r', '__c'));
                                }
                                else {
                                    dw.fieldValue = sObj.get(sc.Storage_Field__c);
                                }
                                //}
                                
                                if(sc.Storage_Field__c != 'Flag_PO_as_High__c' && sc.Storage_Field__c != 'Flag_Current_Registred_as_Very_High__c' && sc.Storage_Field__c != 'Address_Type__c'){
                                    rowFields.add(dw); 
                                }else{
                                    if(!fieldLabelList.contains(dw.fieldLabel +'-'+dw.fieldValue) && dw.fieldValue == true){
                                        rowFields.add(dw);  
                                        fieldLabelList.add(dw.fieldLabel +'-'+dw.fieldValue);
                                    }
                                    if(sc.Storage_Field__c == 'Address_Type__c'){
                                        if(dw.fieldValue != null){
                                            rowFields.add(dw);
                                        }
                                    }
                                }
                            } 
                        }
                    }
                }
            }
            
            System.debug('rowFields -->'+rowFields);
            return rowFields;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }    
    }
    public static Object get(SObject record, String field)
    {
        if (record == null) return null;
        if (!field.contains('.')) return record.get(field);
        return get(
            record.getSObject(field.substringBefore('.')),
            field.substringAfter('.')
        );
    }
    
    @AuraEnabled
    public static string getLoanCompletionStage(String loanId){
        
        List<Opportunity> loanList = [SELECT Id, Login_Completion_Stage__c FROM Opportunity WHERE Id =: loanId limit 1];
        if(!loanList.isEmpty()){
            return loanList[0].Login_Completion_Stage__c;
        }
        return '';
    }
    
    public class DetailsWrapper{
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public Object fieldValue;
        @AuraEnabled public Object savedName;
        @AuraEnabled public Object lookUpfieldValue;
        @AuraEnabled public Double sequence;
        @AuraEnabled public String fieldId;
    }
    
    @AuraEnabled
    public static Decimal getCurrSeq(String screenIdentifier, String formIdentifier) {
        Decimal seq =0;
        
        try {
            List<Screen_Field__c> screenFields = [SELECT Id,Applicant_Type_Visibility__c, Parent_Screen__r.Screen_Sequence__c
                                                  FROM Screen_Field__c
                                                  WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Form_Name__c =: formIdentifier
                                                  and Screen_Name__c =: screenIdentifier order by Field_Sequence__c ASC];
            
            if(!screenFields.isEmpty()){
                seq = screenFields[0].Parent_Screen__r.Screen_Sequence__c;
            }
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return seq;
    }
    
    @AuraEnabled
    public static string getApplicantDetailId(String loanId){
        
        List<Application_Applicant__c> apDetList = [SELECT Id FROM Application_Applicant__c WHERE Loan_Application__c =: loanId];
        if(!apDetList.isEmpty()) {
            return apDetList[0].Id;
        }
        
        return '';
    }
    
    /**
* @description	    :	Method that create/update the loan related details
* @since			:	2024-07-24
**/    
    @AuraEnabled
    public static Id saveLoanDetails(String loanId, String storageObject, String fieldsDataMap, String fieldsObjectMap, String screenName){
        try{
            String recId = loanId;
            String query;
            system.debug('input field data: ' + fieldsDataMap);
            
            //List<Application_Applicant__c> apDetList = [Select Id from Application_Applicant__c where Loan_Application__c =: loanId and Applicant_Type__c = 'Applicant'];
            Map<String, Object> fieldDetailsMap = (Map<String, Object>)JSON.deserializeUntyped(fieldsDataMap);
            Map<String, Object> fieldsToObjectMap = (Map<String, Object>)JSON.deserializeUntyped(fieldsObjectMap);
            Map<String, String> fieldsToObjectApi = new Map<String, String>();
            Map<String, Sobject> objectToSObj = new Map<String, Sobject>();
            
            for(String field : fieldsToObjectMap.keySet()){
                fieldsToObjectApi.put(field,String.valueOf(fieldsToObjectMap.get(field)));
                
                if(!objectToSObj.containsKey(String.valueOf(fieldsToObjectMap.get(field)))){
                    Schema.SObjectType targetType = Schema.getGlobalDescribe().get(String.valueOf(fieldsToObjectMap.get(field)));
                    Sobject objectToInsert = targetType.newSObject();
                    objectToSObj.put(String.valueOf(fieldsToObjectMap.get(field)), objectToInsert);
                }
            }
            
            Map<String, String> objectToRecIdMap = new Map<String, String>();
            for(String sObj : objectToSObj.keySet()){
                
                if(sObj == 'Application_Applicant__c') {
                    query = 'Select Id from ' + sObj + ' WHERE Loan_Application__c =: loanId LIMIT 1';
                }
                else if(sObj == 'Opportunity') {
                    query = 'Select Id from ' + sObj + ' WHERE Id =: loanId LIMIT 1';
                }
                else if(sObj == 'Application_Verification__c') {
                    query = 'Select Id from ' + sObj + ' WHERE Id =: recId  LIMIT 1';
                }
                else {
                    query = 'Select Id from ' + sObj + ' WHERE Loan_Application__c =: loanId LIMIT 1';
                }
                
                system.debug('query - ' + query);
                List<SObject> sObjectList = Database.query(query);
                
                if(!sObjectList.isEmpty()){
                    objectToRecIdMap.put(sObj, sObjectList[0].Id);
                }
            }
            
            System.debug('objectToRecIdMap=:'+objectToRecIdMap);
            Map<String,Sobject> sObjectToUpsert = new Map<String,Sobject>();
            for(String fieldName : fieldDetailsMap.keySet()){
                
                String strObj = fieldsToObjectApi.get(fieldName);
                Schema.SObjectType targetType = Schema.getGlobalDescribe().get(strObj);
                String objectName = targetType.getDescribe().getName();
                string fieldType = String.valueof(targetType.getDescribe().fields.getMap().get(fieldName).getDescribe().getType());
                String recordId;
                Sobject objectToInsert = objectToSObj.get(objectName);
                
                // if(fieldType == 'DATE'){
                //     objectToInsert.put(fieldName, Date.valueOf(String.valueof(fieldDetailsMap.get(fieldName))));
                // }
                // else if(fieldType == 'CURRENCY' || fieldType == 'PERCENT' || fieldType == 'DOUBLE'){
                //     objectToInsert.put(fieldName, Decimal.valueOf(String.valueof(fieldDetailsMap.get(fieldName))));
                // }
                if(fieldType == 'TIME'){
                    String timeString = String.valueof(fieldDetailsMap.get(fieldName));
                    List<String> timeParts = timeString.split(':');
                    Integer hours = Integer.valueOf(timeParts[0]);
                    Integer minutes = Integer.valueOf(timeParts[1]);
                    Integer seconds = Integer.valueOf(timeParts[2].split('\\.')[0]);
                    Integer milliseconds = Integer.valueOf(timeParts[2].split('\\.')[1]);
                    Time visitedTime = Time.newInstance(hours, minutes, seconds, milliseconds);
                    objectToInsert.put(fieldName, visitedTime);
                }
                else{
                    objectToInsert.put(fieldName, fieldDetailsMap.get(fieldName));
                }
                
                if(objectToRecIdMap.containsKey(objectName)){
                    recordId = objectToRecIdMap.get(objectName);
                    objectToInsert.put('Id', objectToRecIdMap.get(objectName));
                }
                
                if(objectName == 'Application_Applicant__c' && string.isBlank(recordId)){
                    objectToInsert.put('Opportunity', loanId);
                }
                else if(objectName == 'Opportunity'){
                    objectToInsert.put('Id', loanId);
                }
                
                sObjectToUpsert.put(objectName, objectToInsert);
            }
            
            System.debug('sObjectToUpsert=:'+sObjectToUpsert);
            // Upsert sObjectToUpsert;
            Database.UpsertResult[] upsertResults = Database.upsert(sObjectToUpsert.values(), false);
            List<Id> upsertedIds = new List<Id>();
            for(Database.UpsertResult result : upsertResults) {
                if(result.isSuccess()) {
                    upsertedIds.add(result.getId());
                }
                else {
                    System.debug('Upsert failed for record: ' + result.getErrors());
                }
            }
            
            return upsertedIds[0];
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean getFiStatus(String recordId){
        
        List<Application_Verification__c> fs = [Select id from Application_Verification__c where (((Stage__c = 'Approved 1' OR Stage__c = 'Draft' OR Stage__c = 'Not Accepted by Admin') AND OwnerId !=: UserInfo.getUserId()) OR OwnerId =: UserInfo.getUserId()) AND id =: recordId];
        if(!fs.isEmpty()){
            return true;
        }
        
        return false;
    }
    
    @AuraEnabled
public static Boolean saveUploadedAddressProof(String loanId, String applicantType, String contentDocId) {
try {
// Query to fetch the appropriate Applicant record
List<Application_Applicant__c> applicantList = [
SELECT Id, Loan_Application__c
FROM Application_Applicant__c
WHERE Loan_Application__c =: loanId AND Applicant_Type__c =: applicantType
LIMIT 1
];

if(applicantList.isEmpty()) {
throw new AuraHandledException('No applicant found for the given loan ID and applicant type.');
}

// Query Document Master for the 'Current Address Proof' document type
List<Document_Master__c> docMasterList = [
SELECT Id, Name
FROM Document_Master__c
WHERE Name = 'Current Address Proof'
LIMIT 1
];

if(docMasterList.isEmpty()) {
throw new AuraHandledException('No Document Master record found for Current Address Proof.');
}

// Check if a Document_Details__c record already exists for this applicant and document type
List<Document_Details__c> existingDocs = [
SELECT Id, Content_Document_Id__c
FROM Document_Details__c
WHERE Loan_Application__c =: loanId AND Applicant__c =: applicantList[0].Id AND Document_Master__c =: docMasterList[0].Id
LIMIT 1
];

Document_Details__c docDetail;
if(!existingDocs.isEmpty()) {
// Update existing document details
docDetail = existingDocs[0];
}
else {
// Create new document details
docDetail = new Document_Details__c(
Loan_Application__c = loanId,
Applicant__c = applicantList[0].Id,
Document_Master__c = docMasterList[0].Id,
Name = 'Current Address Proof',
Status__c = 'Uploaded'
);
}

// Set the Content Document ID
docDetail.Content_Document_Id__c = contentDocId;

// Upsert the document details record
upsert docDetail;

return true;
}
catch (Exception ex) {
System.debug('Error in saveUploadedAddressProof: ' + ex.getMessage());
throw new AuraHandledException('Failed to save the uploaded address proof. Please try again.');
}
    }
    
    @AuraEnabled
    public static Boolean deleteDocument(String contentDocId) {
        try {
            List<Document_Details__c> existingDocs = [
                SELECT Id
                FROM Document_Details__c
                WHERE Content_Document_Id__c =: contentDocId
                LIMIT 1
            ];
            
            if(!existingDocs.isEmpty()){
                delete existingDocs;
            }
            
            // Delete ContentDocumentLink records associated with the ContentDocument
            List<ContentDocumentLink> linksToDelete = [
                SELECT Id
                FROM ContentDocumentLink
                WHERE ContentDocumentId =: contentDocId
            ];
            
            if(!linksToDelete.isEmpty()) {
                delete linksToDelete;
            }
            
            // Delete the ContentDocument itself
            ContentDocument docToDelete = [
                SELECT Id
                FROM ContentDocument
                WHERE Id =: contentDocId
                LIMIT 1
            ];
            
            delete docToDelete;
            
            return true;
        }
        catch (Exception e) {
            System.debug('Error deleting document: ' + e.getMessage());
            throw new AuraHandledException('Unable to delete document.');
        }
    }
    
    @AuraEnabled
    public static String fetchPincodeName(Id pincodeId) {
        try {
            Pincode_Master__c pincodeRecord = [
                SELECT Name
                FROM Pincode_Master__c 
                WHERE Id =: pincodeId
                LIMIT 1
            ];
            
            return pincodeRecord.Name;
        }
        catch (Exception ex) {
            System.debug('Error fetching Pincode Name: ' + ex.getMessage());
            return null;
        }
    }
    
    @AuraEnabled
    public static String createCurrentAddressRecord(String loanId) {
        // Query the primary applicant based on loanId and applicant type
        List<Application_Applicant__c> primaryApplicant = [
            SELECT Id
            FROM Application_Applicant__c
            WHERE Loan_Application__c =: loanId
            AND Applicant_Type__c = 'Primary Applicant'
            LIMIT 1
        ];
        
        if(primaryApplicant.isEmpty()) {
            throw new AuraHandledException('Primary applicant not found for the given loan ID.');
        }
        
        // Query the permanent address with Address_Source__c = 'Aadhaar'
        List<Applicant_Address__c> permanentAddress = [
            SELECT Floor_Number__c, Building_Street_Name__c, Plot_Number__c, Pincode__c, Landmark__c, Customer_Address__c, Is_Current_Address_Same_As_Permanent__c
            FROM Applicant_Address__c
            WHERE Applicant__c =: primaryApplicant[0].Id
            AND Address_Type__c = 'Permanent'
            AND Address_Source__c = 'Aadhaar'
            LIMIT 1
        ];
        
        if(permanentAddress.isEmpty()) {
            throw new AuraHandledException('Permanent address not found for the primary applicant.');
        }
        
        // Create a new current address record with the same values as the permanent address
        Applicant_Address__c currentAddress = new Applicant_Address__c(
            Applicant__c = primaryApplicant[0].Id,
            Address_Type__c = 'Current',
            Address_Source__c = 'Aadhaar',
            Floor_Number__c = permanentAddress[0].Floor_Number__c,
            Building_Street_Name__c = permanentAddress[0].Building_Street_Name__c,
            Plot_Number__c = permanentAddress[0].Plot_Number__c,
            Pincode__c = permanentAddress[0].Pincode__c,
            Landmark__c = permanentAddress[0].Landmark__c,
            Customer_Address__c = permanentAddress[0].Customer_Address__c,
            Is_Current_Address_Same_As_Permanent__c = 'Yes'
        );
        
        insert currentAddress;
        return 'Current address created successfully with ID: ' + currentAddress.Id;
    }
    
    
    @AuraEnabled
    public static String returnCustType(String loanId) {
        return [SELECT Customer_Type__c FROM Application_Applicant__c WHERE 
                Loan_Application__c = :loanId AND Applicant_Type__c = 'Primary Applicant' LIMIT 1].Customer_Type__c;
    }
    @AuraEnabled
    public static ApplicantDetailInfo getCustomerType(String loanId){
        ApplicantDetailInfo apDet = new ApplicantDetailInfo();
        try {
            List<Application_Applicant__c> apDetList = [Select id, Customer_Profile__c,Customer_Type__c,Applicant_Type__c,Sector__c from Application_Applicant__c where Loan_Application__c =: loanId and Applicant_Type__c = 'Primary Applicant'];
            if(apDetList.size() > 0){
                apDet.customerType = apDetList[0].Customer_Type__c;
                apDet.empType = apDetList[0].Customer_Profile__c;
                apDet.applicantId = apDetList[0].Id; 
                apDet.applicantType = apDetList[0].Applicant_Type__c;
                apDet.sector = apDetList[0].Sector__c; 
            }           
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return apDet;
    }
     @AuraEnabled
    public static ApplicantDetailInfo getCustomerTypeApp(String appId){
        ApplicantDetailInfo apDet = new ApplicantDetailInfo();
        try {
            List<Application_Applicant__c> apDetList = [Select id, Customer_Profile__c,Customer_Type__c,Applicant_Type__c from Application_Applicant__c where  Id =:appId];
            if(apDetList.size() > 0){
                apDet.customerType = apDetList[0].Customer_Type__c;
                apDet.empType = apDetList[0].Customer_Profile__c;
                apDet.applicantId = apDetList[0].Id; 
                apDet.applicantType = apDetList[0].Applicant_Type__c; 
            }           
        } catch (Exception e) {throw new AuraHandledException(e.getMessage());}
        return apDet;
    }
    public class ApplicantDetailInfo{
        @AuraEnabled public String customerType;
        @AuraEnabled public Boolean isReKycReq;
        @AuraEnabled public Boolean isExistingClient;
        @AuraEnabled public Boolean isNRI;
        @AuraEnabled public String empType;
        @AuraEnabled public String subEmpType;
        @AuraEnabled public String applicantId;
        @AuraEnabled public String applicantType;
        @AuraEnabled public String sector;
    }
  
    @AuraEnabled 
    public static string getPANToGSTNumber(string loanId,string applicantId,string panNumber,string gstIn){
        string resultMsg = '';
        resultMsg = getGSTIn(loanId,panNumber,gstIn);
        if(resultMsg == 'APINotFound' || resultMsg == '' ){  
            Map<String, String> inputMap = new Map<String, String>{'loanId' => loanId,'applicantId' => applicantId,'processName' => 'Loan Applicant GST'};
                String responseData = PANToGSTController.initiateAPIRequest(inputMap);
            if(responseData != null){
                resultMsg = getGSTIn(loanId,panNumber,gstIn);
            }      
        }  
        return resultMsg;
    }
 
    public static string getGSTIn(string loanId,string panNumber,string gstIn){
        string resultMsg= '';
        List<Integration_Details__c> integrationList = [SELECT Id,Response_JSON__c,Request_JSON__c,Status__c FROM Integration_Details__c WHERE Loan_Application__c =: loanId AND Name = 'Loan Applicant GST'];
        if(integrationList.size()>0){
            for(Integration_Details__c integration : integrationList){
                if(integration.status__c == '200'){
                Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(integration.Response_JSON__c);
                if(responseMap.get('result') != null){
                    List<Object> jsonList = (List<Object>) responseMap.get('result');
                        if(jsonList.size()>0){
                    for(Object obj : jsonList){
                        Map<String,Object> response = (Map<String,Object>)obj;
                        if(response.containsKey('gstinId') && (String) response.get('pan') == panNumber){
                            String gstInToCheck = (String) response.get('gstinId');
                            if(gstInToCheck == gstIn){
                                resultMsg = 'Success';
                                return resultMsg; 
                            }else{
                                resultMsg = 'NotFound';
                            }
                        }
                    }
                }else{
                    resultMsg = 'APINotFound';
                }
                            }else{
                        resultMsg = 'APINotFound';
                    }
                }else{
                    resultMsg = 'APINotFound';
                }
            }
        }else{
                resultMsg = 'APINotFound';
        }  
        return resultMsg;
    }

}