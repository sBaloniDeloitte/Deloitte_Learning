/*
* Author    :   Deloitte India
* Purpose   :   Generic controller class to read write data from ScreenFields__c
* @last modified on  : 03-05-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
*/

public without sharing class ScreenGenerationLoginChecklistController {
    
    @AuraEnabled
    public static List<Screen_Field__c> getScreenDetails(String formIdentifier, String loanId){
        try{
            List<Screen_Field__c> screenFields = new List<Screen_Field__c>();

            if(formIdentifier == 'Login Checklist1'){

                if(string.isNotBlank(loanId)){
                    List<Opportunity> loanList = [Select Id, Login_Completion_Stage__c from Opportunity where id =: loanId And Login_Completion_Stage__c != null];
                    List<Application_Applicant__c> appDet = [Select Id, Customer_Type__c, Employment_Type__c from Application_Applicant__c where Loan_Application__c=: loanId and Applicant_Type__c = 'Primary Applicant'];
                    if(!loanList.isEmpty()) {
                          
                        List<string> applicableStageList = loanList[0].Login_Completion_Stage__c.split(';');
                        List<Screen_Field__c> queryScreens = new List<Screen_Field__c>();
                        if(appDet.size()>0 && appDet[0].Customer_Type__c != null){
                            String custAndEmpType = appDet[0].Customer_Type__c+'-'+appDet[0].Employment_Type__c;
                            queryScreens = [SELECT Id, Form_Name__c , Parent_Screen__r.Form_Name__c, Name,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c, Filtered_Picklist_Values__c,
                                                            Is_Picklist__c,Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,Section_Seperator__c,Section_Name__c,
                                                            Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c, Read_Field_Name__c,Applicable_For__c,Picklist_Dependent_On_RecordType__c,
                                                            Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c
                                                            FROM Screen_Field__c
                                                            WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Form_Name__c =: formIdentifier And Applicable_Login_Stage__c In : applicableStageList
                                                            AND (Parent_Screen__r.Applicable_For__c = 'Both' or Parent_Screen__r.Applicable_For__c = 'Individual-Both' or Parent_Screen__r.Applicable_For__c = 'Non Individual-Both' or Parent_Screen__r.Applicable_For__c =: custAndEmpType)
                                                            order by Field_Sequence__c ASC];
                        }
                        else{
                            queryScreens = [SELECT Id, Form_Name__c , Parent_Screen__r.Form_Name__c, Name,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c, Filtered_Picklist_Values__c,
                                                            Is_Picklist__c,Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,Section_Seperator__c,Section_Name__c,
                                                            Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c, Read_Field_Name__c,Applicable_For__c,Picklist_Dependent_On_RecordType__c,
                                                            Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c
                                                            FROM Screen_Field__c
                                                            WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Form_Name__c =: formIdentifier And Applicable_Login_Stage__c In : applicableStageList
                                                            order by Field_Sequence__c ASC];
                        } 

                        for(Screen_Field__c scf : queryScreens){
                            screenFields.add(scf);
                        }
                    }
                }
                else{
                    screenFields = [SELECT Id,Form_Name__c , Parent_Screen__r.Form_Name__c, Name,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c,Picklist_Dependent_On_RecordType__c, 
                                    Is_Picklist__c,Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,Applicable_For__c,Filtered_Picklist_Values__c,
                                    Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c, Read_Field_Name__c,Section_Seperator__c,Section_Name__c,
                                    Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c
                                    FROM Screen_Field__c
                                    WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Form_Name__c =: formIdentifier
                                    order by Field_Sequence__c ASC];
                }
            }
            else{
                screenFields = [SELECT Id,Form_Name__c , Parent_Screen__r.Form_Name__c, Name,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c, Picklist_Dependent_On_RecordType__c,
                                Is_Picklist__c,Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,Applicable_For__c,Filtered_Picklist_Values__c,
                                Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c,Read_Field_Name__c,Read_Object_Name__c,Section_Seperator__c,Section_Name__c,
                                Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c, Screen_Name__c
                                FROM Screen_Field__c
                                WHERE Is_Active__c = true AND Parent_Screen__c != null AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Form_Name__c =: formIdentifier
                                order by Field_Sequence__c ASC];
            }

            return screenFields;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

 


    @AuraEnabled
    public static List<Map<String, String>> getPicklistValues(string storageObject, string storageField) {
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
        
        try {
            System.debug('fieldsDataMap -->' + fieldsDataMap);
            String recordId;
    
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
                    //system.debug('fieldValue: '+fieldValue);

                    if(fieldName.contains('.')) {
                        List<string> fieldTypeTmp = fieldName.split('\\.');
                        fieldName = fieldTypeTmp[0].replace('__r', '__c');
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
                        objectToInsert.put(fieldName, Date.valueOf((String.valueof(fieldValue))));
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
                        recordId = loanId;
                        objectToInsert.put('Id', loanId);
                        finalDataToCommit.add(objectToInsert);
                        // Database.update(objectToInsert);
                    }
                }
                else {
                    dataToInsert.add(objectToInsert);
                }
            }
            if(finalDataToCommit.size()>0){
                Upsert finalDataToCommit[0];
                recordId = finalDataToCommit[0].id;
            }
            System.debug('recordId -->' + recordId);
            
            if(string.isNotBlank(loanId)) {
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
                    Upsert addressToUpsert;
                }
            }
    
            recordData.loanId = recordId;
    
            return recordData;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static void createAddressData(string customerId, string applicantId, string addType, SObject address, List<SObject> addressData) {
        Customer_Address__c newCustomerAddress = new Customer_Address__c();
        newCustomerAddress.Customer__c = customerId;
        newCustomerAddress.Address_Type__c = addType;
        insert newCustomerAddress;

        address.put('Applicant__c', applicantId);
        address.put('Customer_Address__c', newCustomerAddress.Id);
        address.put('Address_Type__c', addType);
        insert addressData;
    }
    
    public class RecordIds {
        @AuraEnabled public String loanId;
        @AuraEnabled public String applicantId;
    }

    public class MyPickListInfo{
        public String validFor;
    }
    
    @AuraEnabled
    public static Map<String, List<Map<String, String>>> getFieldDependencies(String objectName, String controllingField, String dependentField){
        Map<String, List<Map<String, String>>> controllingInfo = new Map<String, List<Map<String, String>>>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult describeResult = objType.getDescribe();
        Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(controllingField).getDescribe();
        Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(dependentField).getDescribe();
        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
        List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();
        
        for(Schema.PicklistEntry currControllingValue : controllingValues){
            controllingInfo.put(currControllingValue.getLabel(), new List<Map<String, String>>());
        }
        
        for(Schema.PicklistEntry currDependentValue : dependentValues){
            String jsonString = JSON.serialize(currDependentValue);
            MyPickListInfo info = (MyPickListInfo) JSON.deserialize(jsonString, MyPickListInfo.class);
            String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();
            Integer baseCount = 0;
            
            for(Integer curr : hexString.getChars()){

                Integer val = 0;
                if(curr >= 65){
                    val = curr - 65 + 10;
                }
                else{
                    val = curr - 48;
                }
                
                if((val & 8) == 8){

                    System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 0].getLabel());
                    Map<String, String> valueMap = new Map<String, String>();
                    valueMap.put(Constants.LABEL_CONSTANT, currDependentValue.getLabel());
                    valueMap.put(Constants.VALUE_CONSTANT, currDependentValue.getValue());
                    controllingInfo.get(controllingValues[baseCount + 0].getLabel()).add(valueMap);
                }
                if((val & 4) == 4){

                    System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 1].getLabel());
                    Map<String, String> valueMap = new Map<String, String>();
                    valueMap.put(Constants.LABEL_CONSTANT, currDependentValue.getLabel());
                    valueMap.put(Constants.VALUE_CONSTANT, currDependentValue.getValue());
                    controllingInfo.get(controllingValues[baseCount + 1].getLabel()).add(valueMap);
                }
                if((val & 2) == 2){

                    System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 2].getLabel());
                    Map<String, String> valueMap = new Map<String, String>();
                    valueMap.put(Constants.LABEL_CONSTANT, currDependentValue.getLabel());
                    valueMap.put(Constants.VALUE_CONSTANT, currDependentValue.getValue());
                    controllingInfo.get(controllingValues[baseCount + 2].getLabel()).add(valueMap);
                }
                if((val & 1) == 1){

                    System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 3].getLabel());
                    Map<String, String> valueMap = new Map<String, String>();
                    valueMap.put(Constants.LABEL_CONSTANT, currDependentValue.getLabel());
                    valueMap.put(Constants.VALUE_CONSTANT, currDependentValue.getValue());
                    controllingInfo.get(controllingValues[baseCount + 3].getLabel()).add(valueMap);
                }
                baseCount += 4;
            }
        }

        System.debug('ControllingInfo -->' + controllingInfo);
        return controllingInfo;
    }

    @AuraEnabled
    public static Decimal percentCompletion(String loanId){
        return LoanActionController.percentCompletion(loanId);
    }

    @AuraEnabled
    public static List<DetailsWrapper> getLoanDetailsFromReadObject(String screenName, String loanId, String formIdentifier, String recordId){
        try{
            String applicantType = 'Primary Applicant';
            List<DetailsWrapper> rowFields = new List<DetailsWrapper>();

            List<Screen_Field__c> screenFieldList = [Select Id, Field_Label__c, Field_Placement__c, Read_Field_Name__c, Read_Object_Name__c, Field_Sequence__c, is_Lookup__c 
                                                    from Screen_Field__c 
                                                    where Is_Active__c = true and Parent_Screen__r.Is_Screen_Active__c = true and Parent_Screen__r.Master_Screen_Name__c =: screenName 
                                                    and Parent_Screen__r.Form_Name__c =: formIdentifier
                                                    order by Field_Sequence__c asc];

            Map<String, List<String>> objectToFieldsMap = new Map<String, List<String>>();
            Map<String, String> fieldApiTOLabelMap = new Map<String, String>();

            for(Screen_Field__c sc : screenFieldList){
                //system.debug('sc.Read_Object_Name__c: '+sc.Read_Object_Name__c);
                //system.debug('sc.Read_Field_Name__c: '+sc.Read_Field_Name__c);
                //system.debug('sc.Field_Label__c: '+sc.Field_Label__c);

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

                //if(sObjList != null){
                    for(SObject sObj : sObjList){
                        //system.debug('sObj: '+sObj);
                        //system.debug('sc.Read_Field_Name__c: '+sc.Read_Field_Name__c);

                        DetailsWrapper dw = new DetailsWrapper();
                        dw.fieldLabel = sc.Field_Label__c;
                        dw.fieldApiName = sc.Read_Field_Name__c;
                        dw.sequence = sc.Field_Sequence__c;

                        if(sc.is_Lookup__c) {
                            List<string> lookupField = String.valueOf(sc.Read_Field_Name__c).split('\\.');

                            SObject parenObj = sObj.getSobject(lookupField[0]);
                            dw.lookUpfieldValue = parenObj.get(lookupField[1]);

                            dw.fieldValue = sObj.get(lookupField[0].replace('__r', '__c'));
                        }
                        else {
                            dw.fieldValue = sObj.get(sc.Read_Field_Name__c);
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
                //}
            }
            
            return rowFields;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<DetailsWrapper> getLoanDetailsFromStorageObject(String screenName, String loanId, String formIdentifier, Id recordId ,String did){
        try{
            System.debug('recordId '+recordId);
            System.debug('did '+did);
            String applicantType = 'Primary Applicant';
            System.debug('formIdentifier '+formIdentifier);
            List<DetailsWrapper> rowFields = new List<DetailsWrapper>();

            List<Screen_Field__c> screenFieldList = [SELECT Id, Field_Label__c, Field_Placement__c, Storage_Field__c, Storage_Object__c, Field_Sequence__c, is_Lookup__c, Read_Field_Name__c 
                                                    FROM Screen_Field__c 
                                                    WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Master_Screen_Name__c=: screenName 
                                                    AND Parent_Screen__r.Form_Name__c =: formIdentifier
                                                    ORDER BY Field_Sequence__c ASC];

            Map<String,List<String>> objectToFieldsMap = new Map<String,List<String>>();
            Map<String,String> fieldApiTOLabelMap = new Map<String,String>();

            for(Screen_Field__c sc : screenFieldList){
                //system.debug('sc.Read_Object_Name__c: '+sc.Storage_Object__c);
                //system.debug('sc.Read_Field_Name__c: '+sc.Storage_Field__c);
                //system.debug('sc.Field_Label__c: '+sc.Field_Label__c);

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

                String query = 'Select Id ';
                for(String fields : fieldApiNames){
                    query = query +', '+ fields;
                }

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
                        else if(formIdentifier == 'Business Address Form'){
                            addressTypes = new List<String>{
                                'Regional Office', 
                                'Registered Office', 
                                'Project Site', 
                                'Godown', 
                                'Central Office', 
                                'Factory Outlet'
                            };
                            query += ' ,Pincode__c FROM '+ objectName +' where Id = \''+recordId +'\'' +'limit 1';
                        }
                        else{
                            query += ' ,Pincode__c FROM '+ objectName +' where Applicant__r.Loan_Application__c = \''+ loanId + '\'' +' AND Applicant__r.Applicant_Type__c =: applicantType AND Address_Type__c =: addressTypes LIMIT 1';
                        }
                        
                    }
                    when 'Document_Details__c' {
                        query += ' FROM '+ objectName +' where Id = \'' + did + '\' LIMIT 1';
                    }
                }
                System.debug('query -->'+query);
                
                List<SObject> sObjList = Database.query(query);
                if(!sObjList.isEmpty()){
                    if(formIdentifier == 'CAM Details'){
                        System.debug('832 '+sObjList);
                        if (objectValuesMap.containsKey(objectName)) {
                            objectValuesMap.get(objectName).addAll(sObjList);  // Add all records instead of just one
                        } else {
                            objectValuesMap.put(objectName, new List<SObject>(sObjList));  // Store all records directly
                        }
                    }
                    else{
                    if(objectValuesMap.containsKey(objectName)){
                        objectValuesMap.get(objectName).add(sObjList[0]);
                    }
                    else{
                        objectValuesMap.put(objectName, new List<SObject>{sObjList[0]});
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
                        for(SObject sObj : sObjList){
                            //system.debug('sObj: '+sObj);
                            //system.debug('sc.Storage_Field__c: '+sc.Storage_Field__c);
                                    
                            DetailsWrapper dw = new DetailsWrapper();
                            dw.fieldLabel = sc.Field_Label__c;
                            dw.fieldApiName = sc.Storage_Field__c;
                            dw.sequence = sc.Field_Sequence__c;

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

                            rowFields.add(dw);
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
    }

    @AuraEnabled
    public static Decimal getCurrSeq(String screenIdentifier, String formIdentifier) {
        Decimal seq =0;

        try {
            List<Screen_Field__c> screenFields = [SELECT Id, Parent_Screen__r.Screen_Sequence__c
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
            List<Application_Applicant__c> apDetList = [Select id, Customer_Profile__c,Customer_Type__c,Applicant_Type__c,Employment_Type__c from Application_Applicant__c where Loan_Application__c =: loanId and Applicant_Type__c = 'Primary Applicant'];
            if(apDetList.size() > 0){
                apDet.customerType = apDetList[0].Customer_Type__c;
                apDet.empType = apDetList[0].Customer_Profile__c;
                apDet.applicantId = apDetList[0].Id; 
            }           
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
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
    }
}