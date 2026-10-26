/*
* Created By : Akash Sharma
* Created Date : 30/10/2024
* Purpose :This class would be used to bulk upload
*/

public without sharing class BulkUpsertRecordScreenController {
    //Method written to parse the data from the columns of excel upload
    
        static string conLabels = Constants__mdt.getInstance('LeadManagementController').Value__c;
        public static Map<string, string> constants = getConstants(conLabels);
        //getting the value of constants
        @AuraEnabled
        public static Map<string, string> getConstants(){
            return constants;
        }

        @AuraEnabled
        public static String getCurrentUserProfileName(){
            return [Select Name From Profile Where Id =: userinfo.getProfileId()].Name;
        }

        public static Map<string, string> getConstants(string conLabels){
            List<string> cons = conLabels.split(',');
            Map<string, string> constants = new Map<string, string>();
            Map<String,Constants__mdt> allMetaData = Constants__mdt.getAll();
            
            for(Constants__mdt itr : allMetaData.values()){
                if(cons.contains(itr.DeveloperName)){
                    constants.put(itr.DeveloperName, itr.Value__c);
                }
            }
            System.debug('constants=:'+constants);
            return constants;
        }

        @AuraEnabled
        public static List<String> saveFile(String fileID, String objectName) {
            
            List<String> result = new List<String>();
            Map<String, String> productToRecordType = new Map<String, String>{
            'Affordable Home Loan' => 'Affordable_Home_Loan',
            'Home Loan' => 'Home_Loan'
            };
            try{
                Map<String,BulkUpsertDetails__mdt> mapOfMetaData = new Map<String,BulkUpsertDetails__mdt>();
                Map<String, BulkUpsertDetails__mdt> allMetaData = BulkUpsertDetails__mdt.getAll();
               System.debug('object Name>'+objectName);
               System.debug('all metadata>'+allMetaData);
               // Query inactive users
               Set<Id> inactiveUserIds = new Set<Id>();
               List<User> inactiveUsers = [SELECT Id FROM User WHERE IsActive = false];
               for (User u : inactiveUsers) {
                    inactiveUserIds.add(u.Id);
                }

                if(!allMetaData.values().isEmpty()) {
                    for(BulkUpsertDetails__mdt iterMeta : allMetaData.values()) {
                        if (iterMeta.ObjectName__c == objectName) {
                            System.debug('Inside iter foreach'+iterMeta.Label);
                            mapOfMetaData.put(iterMeta.Label, iterMeta);
                        }
                    } 
                }
                else {
                    result.add('No master data found.');
                    return result;
                } 
                
               ContentVersion objDoc = new ContentVersion();
                //System.debug('mapOfMetaData '+mapOfMetaData);
                if(Schema.sObjectType.ContentVersion.isAccessible()){
                    objDoc = [SELECT id, VersionData, title, fileExtension FROM ContentVersion WHERE ContentDocumentId =: fileID LIMIT 1];
                
                }
    
               
                if(objDoc != null){
                    Blob base64Data = objDoc.VersionData;
                    String data = base64Data.toString();
                    List<String> lstCSVLines = data.split('\n');
                    
                    Boolean isInvalidColumn = false;
                    List<String> headerColumn = getHeader(lstCSVLines[0]);
                    System.debug('headerColumn'+headerColumn);
                    System.debug('mapOfMetaData'+mapOfMetaData.keySet());
                    System.debug('mapOfMetaData condition'+mapOfMetaData.containsKey('First Name'));
                    for(String st : headerColumn) {
                        System.debug('st>'+st);
                        if(!mapOfMetaData.containsKey(st.trim())){
                            System.debug('inside error condition>'+st);
                            result.add('Invalid Column '+st);
                            isInvalidColumn = true;
                        }
                    }
                    //System.debug('headerColumn '+headerColumn);
                    //System.debug('headerColumn[0] '+headerColumn[0]);
        
                    if(isInvalidColumn){
                        return result;
                    }
        
                    Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
                    Schema.SObjectType objSchema = schemaMap.get(objectName);
                    Map<String, Schema.SObjectField> fieldMap = objSchema.getDescribe().fields.getMap();
        
                    List<Lead> lstLeads = new List<Lead>();
                    Map<String, String> resultMap = new Map<String, String>();
                    Group ahlTeleCallerQueue;
                    Group hlTeleCallerQueue;
                    // if(Schema.sObjectType.Group.isAccessible()){
                    //  ahlTeleCallerQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'AHL Tele Caller Lead Queue' LIMIT 1];
                    //  hlTeleCallerQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'HL Tele Caller Lead Queue' LIMIT 1];
                    // }
                    for(Integer i = 1; i < lstCSVLines.size(); i++){
                        String csvLine = lstCSVLines[i];
                        //String prevLine = csvLine;
                        Integer startIndex;
                        Integer endIndex;
                        
                        while(csvLine.indexOf('"') > -1){
                            if(startIndex == null){
                                startIndex = csvLine.indexOf('"');
                                csvLine = csvLine.substring(0, startIndex) + ':quotes:' + csvLine.substring(startIndex +1, csvLine.length());
                            }
                            else{
                                if(endIndex == null){
                                    endIndex = csvLine.indexOf('"');
                                    csvLine = csvLine.substring(0, endIndex) + ':quotes:' + csvLine.substring(endIndex +1, csvLine.length());
                                }
                            }
        
                            if(startIndex != null && endIndex != null){
                                String sub = csvLine.substring(startIndex, endIndex);
                                sub = sub.replaceAll(',', ':comma:');
                                csvLine = csvLine.substring(0, startIndex) + sub + csvLine.substring(endIndex, csvLine.length());
                                startIndex = null;
                                endIndex = null;
                            }
                        }
        
                        List<String> csvRowData = new List<String>();
                        Integer indexXount = 0;
                        Lead leadObj = new Lead();
                        String extId = '';
                        String errorMsg = '';
                        Boolean iserror = false;
                        
                        for(String column : csvLine.split(',')){
                            column = column.replaceAll(':quotes:', '').replaceAll(':comma:', ',');
                            column = column.replaceAll('\r', '');
                            csvRowData.add(column);

                            if(headerColumn.size() >indexXount) {
                                if (column == 'null'|| column == null) {
                                   column = '';
                                }
                            }
        
                            if(headerColumn.size() >indexXount && headerColumn[indexXount] == 'External Id') {
                                extId = column;
                            }

                            // if(headerColumn.size() >indexXount && headerColumn[indexXount] == 'Owner Id') {
                            //      if (column == 'null'|| column == null || column == '' || inactiveUserIds.contains(column)) {
                            //        column = ahlTeleCallerQueue.Id;
                            //      }
                            // }
        
                            if(String.isBlank(column) && mapOfMetaData.get(headerColumn[indexXount]).Is_Mandatory__c) {
                                errorMsg = errorMsg + ' '+ Constants__mdt.getInstance('ERROR_REQUIRED_FIELD_MISSING').Value__c+' '+headerColumn[indexXount];
                                iserror = true;
                            }
        
                            if(headerColumn.size() >indexXount && headerColumn[indexXount] == 'First Name') {
                                if(!(isValidName(column))){
                                    iserror = true;
                                    errorMsg = errorMsg + ' '+  Constants__mdt.getInstance('ERROR_MESSGAE_NAME').Value__c;
                                }
                            }

                            if(headerColumn.size() >indexXount && headerColumn[indexXount] == 'Last Name') {
                                if(!(isValidName(column))){
                                    iserror = true;
                                    errorMsg = errorMsg + ' '+  Constants__mdt.getInstance('ERROR_MESSGAE_LAST_NAME').Value__c;
                                }
                            }

                            // if(headerColumn.size() >indexXount && headerColumn[indexXount] == 'Middle Name') {
                            //     if(string.isNotBlank(column) && !(isValidName(column))){
                            //         iserror = true;
                            //         errorMsg = errorMsg + ' '+ Constants__mdt.getInstance('ERROR_MESSGAE_MIDDLE_NAME').Value__c;
                            //     }
                            // }
        
                            if(headerColumn.size() >indexXount && headerColumn[indexXount] == 'Mobile Number') {
                                System.debug('column 1 '+column+' == '+isValidMobileNumber(column));
                                if(!(isValidMobileNumber(column))) {
                                    iserror = true;
                                    errorMsg = errorMsg + ' '+ Constants__mdt.getInstance('ERROR_MESSGAE_MOBILE_NUMBER').Value__c;
                                }
                            }
        
                            if(String.isNotBlank(column) && !iserror) {
                                List<String> dateParts = column.split('-'); 
                                Schema.DisplayType fielddataType = fieldMap.get(mapOfMetaData.get(headerColumn[indexXount]).FieldAPIName__c).getDescribe().getType();
                                System.debug('fielddataType '+fielddataType);
        						System.debug('Schema.DisplayType.Date '+Schema.DisplayType.Date);
                                System.debug('dateParts '+dateParts);
                                System.debug('dateParts '+dateParts.size());
                                if(fielddataType == Schema.DisplayType.CURRENCY || fielddataType == Schema.DisplayType.DOUBLE || fielddataType == Schema.DisplayType.PERCENT) {
                                    leadObj.put(mapOfMetaData.get(headerColumn[indexXount]).FieldAPIName__c, Double.valueOf(column));
                                } else if(fielddataType == Schema.DisplayType.Date && dateParts.size() == 3){
                                    
                                   column = column.trim();
                                    Date formattedDate;
                                            Integer month = Integer.valueOf(dateParts[0]);
                                            Integer day = Integer.valueOf(dateParts[1]);
                                            Integer year = Integer.valueOf(dateParts[2]);
                                            year = year<100 ? year += 2000 : year;
                                            
                                             formattedDate = Date.newInstance(year, month, day);
                                            System.debug('Formatted Date: ' + formattedDate);
                                        
									
                                    System.debug('column##'+column);
                                   
                                    System.debug('formattedDate##'+formattedDate);
                                    System.debug('fidl name##'+mapOfMetaData.get(headerColumn[indexXount]).FieldAPIName__c);
                                   
                                    leadObj.put(mapOfMetaData.get(headerColumn[indexXount]).FieldAPIName__c, formattedDate);
    
                                }
                                else{
                                    leadObj.put(mapOfMetaData.get(headerColumn[indexXount]).FieldAPIName__c, column);
                                }
                            }
        
                            //System.debug('column '+column);
                            indexXount++;
                        }
        
                        errorMsg = extId +','+ errorMsg;
                        resultMap.put(extId, errorMsg);
                        
                        System.debug('resultMap--'+resultMap);
                        if(!iserror) {
                            leadObj.Company = leadObj.FirstName + (string.isNotBlank(leadObj.MiddleName) ? +' '+ leadObj.MiddleName : '') +' '+ leadObj.LastName;
                            //if(leadObj.OwnerId == null && leadObj.OwnerId == ''){
                            leadObj.OwnerId = '005dN00000CrmPNQAZ';//UserInfo.getUserId();  //ahlTeleCallerQueue.Id;
                            Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Home_Loan').getRecordTypeId();
                            leadObj.RecordTypeId = recordTypeId; // recordTypeId != null ? recordTypeId : '';
                            //}
                            // if(leadObj.Product__c != '' && leadObj.Product__c != null){
                            //     String recordTypeDevName = productToRecordType.containsKey(leadObj.Product__c) ? productToRecordType.get(leadObj.Product__c) : null;
                            //     if (recordTypeDevName != null) {
                            //     Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(recordTypeDevName).getRecordTypeId();
                            //     leadObj.RecordTypeId = '012KY000001E364YAC'; // recordTypeId != null ? recordTypeId : '';
                            //     }
                            // }
                            lstLeads.add(leadObj);
                            resultMap = new Map<String, String>();
                        }
                        
                        // System.debug('csvRowData--'+csvRowData);
                        // if(csvRowData.size()< 3){
                        //     //result.add('Failed');
                        //     //result.add('Wrong data uploaded');
                        //     //return result;
                        // }
                    }
                    // System.debug('lstCases--'+lstCases);
        
                    if(!lstLeads.isEmpty()) {
                        System.debug('lstLeads--'+lstLeads);
        
                        Database.SaveResult[] results = Database.insert(lstLeads, false);
                        system.debug('Result--->'+results);
        
                        Set<Id> leadIdSet = new Set<Id>();
                        Map<Id, String> caseNoMap = new Map<Id, String>();
                        for(Database.SaveResult iterRes : results) {
                            if(iterRes.isSuccess()) {
                                leadIdSet.add(iterRes.getId());
                            }
                        }
        
                        if(!leadIdSet.isEmpty() && Schema.sObjectType.Lead.isAccessible()){
                            for(Lead cseRec : [SELECT ID, name From Lead Where Id In : leadIdSet]){
                                caseNoMap.put(cseRec.Id, cseRec.name);
                            }
                        }
        
                        Integer index= 0;
                        for(Database.SaveResult iterRes : results) {
                            System.debug('caseNoMap----'+ caseNoMap);
                            //String tem = '';
                            if(iterRes.isSuccess() && !caseNoMap.isEmpty() && !resultMap.containsKey(caseNoMap.get(iterRes.getId()))) {
                                
                                    String responsedata = caseNoMap.get(iterRes.getId()) +','+ iterRes.getId() +',Success,';
                                    resultMap.put(caseNoMap.get(iterRes.getId()), responsedata);   
                            
                            }
                            else {
                                String errorMsg= '';
                                for(Database.Error err : iterRes.getErrors()) {
                                    errorMsg = errorMsg + err.getMessage();
                                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                    String userName= lstLeads[index].FirstName + (string.isNotBlank(lstLeads[index].MiddleName) ? +' '+ lstLeads[index].MiddleName : '') +' '+ lstLeads[index].LastName;
                                    String responsedata = userName +','+ iterRes.getId() +',Fail,'+ errorMsg;
                                    resultMap.put(userName, responsedata); 
                                } 
                            }
                            index = index +1;
                            System.debug('resultMap-----'+resultMap);
                            //result.add(tem);
                        }
                    }
        
                    result.addAll(resultMap.values());
                    System.debug('result---'+result);
                    return result;
                }
                else{
                    result.add('No master data found.');
                    return result;
                }
            }
            catch (System.Exception e){
                System.debug('Error: ' + e);
                System.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
                result.add('Failed');
                result.add('Error message: ' + e.getMessage());
                return result;
            }
        }
        //To read the data from the headers
        public static List<String> getHeader(String headerLine) {
            String csvLine = headerLine;
            //String prevLine = csvLine;
            Integer startIndex;
            Integer endIndex;
    
            while(csvLine.indexOf('"') > -1){
                if(startIndex == null){
                    startIndex = csvLine.indexOf('"');
                    csvLine = csvLine.substring(0, startIndex) + ':quotes:' + csvLine.substring(startIndex +1, csvLine.length());
                }
                else{
                    if(endIndex == null){
                        endIndex = csvLine.indexOf('"');
                        csvLine = csvLine.substring(0, endIndex) + ':quotes:' + csvLine.substring(endIndex +1, csvLine.length());
                    }
                }
                System.debug('endIndex'+endIndex);
                System.debug('startIndex'+startIndex);
                System.debug('csvLine'+csvLine);
                if(startIndex != null && endIndex != null){
                    String sub = csvLine.substring(startIndex, endIndex);
                    sub = sub.replaceAll(',', ':comma:');
                    csvLine = csvLine.substring(0, startIndex) + sub + csvLine.substring(endIndex, csvLine.length());
                    startIndex = null;
                    endIndex = null;
                }
            }
    
            List<String> csvRowData = new List<String>();
            for(String column : csvLine.split(',')){
                column = column.replaceAll(':quotes:', '').replaceAll(':comma:', ',');
                column = column.replaceAll('\r','');
                csvRowData.add(column);
            }
    
            return csvRowData;
        }
        
        // public class ResponseWrap {
        //     public String status;
        //     public Integer count;
        // }
        //To download the sample CSV needed for upload
        @AuraEnabled
        public static List<String> getSampleCSV(String objectName) {
            List<String> result = new List<String>();
            
          //  List<BulkUpsertDetails__mdt> lstMetaData = [SELECT SampleData__c, Label FROM BulkUpsertDetails__mdt WHERE ObjectName__c =: objectName];
           Map<String, BulkUpsertDetails__mdt> allMetaData = BulkUpsertDetails__mdt.getAll();
    
            if(!allMetaData.Values().isEmpty()) {
                String header = '';
                String sampleData = '';
    
                for(BulkUpsertDetails__mdt iterMeta : allMetaData.Values()) {
                    header = header + iterMeta.Label +',';
                    sampleData = sampleData + iterMeta.SampleData__c +',';
                }
    
                header = header.removeEnd(',');
                sampleData = sampleData.removeEnd(',');
                result.add(header);
                result.add(sampleData);
    
                return result;
            }
            else {
                result.add('No master data found.');
                return result;
            }
        }

        public static boolean isValidName(string name){
            return (String.isNotBlank(name) && Pattern.matches('^[A-Za-z]+([ ]?[A-Za-z]+)*$', name));
        }
        
        // Validate mobile number (10 digits only)
        public static boolean isValidMobileNumber(string mobileNo){
            return (String.isNotBlank(mobileNo) && Pattern.matches('^\\d{10}$', mobileNo));
        }
    }