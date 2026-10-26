/*
* Created By : Romesh Somani
* Created Date : 15/10/2024 
* Purpose : This class is a utility class, all the generic methods and utility methods can be created here
*/

public without sharing class Utility
{ 
    public static Boolean byPassOwnershipUpdate = false;
    public static Boolean ahlOpportunityOwnerChangeByPass = false;
    static string conLabels = 'Encryption_Key,AES_Algorithm,IV_Key';
                         
    public static Map<string, string> constantsMeta = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constantsMeta;
    }

    // to check whether the entered values us numeric or not
    public static Boolean isNumeric(String value){
        Boolean returnValue;
        
        try{
            Decimal.valueOf(value);
            returnValue = true;
        }
        catch(Exception e) {
            returnValue = false;
        }
        
        return returnValue;
    }
    public static String fetchUserProfile(String profileId){
        String proName = '';
        List<profile> pro = [Select Name From Profile Where Id =: profileId];
        
        if(!pro.isEmpty()){
            proName = pro[0].Name;
        }
        //system.debug('Profile Name: ' + proName);
        return proName;
    }
    
    
    //  Publishes a Communication__e Platform Event.
    
    public static Boolean publishCommunicationEvent(String message, Id recordId, String type) {
        try {
            Opportunity opp = [SELECT Id,Product__c FROM Opportunity WHERE Id = :recordId];
            Integration_Details__c intgration = new Integration_Details__c();
            intgration.name = 'Communication Event';
            intgration.Loan_Application__c = opp.Id;
            intgration.Endpoint__c = type; 
            intgration.Communication_Status__c = 'Published';
            intgration.Request_JSON__c = message;
            insert intgration;
            
            // Create an instance of the Communication__e platform event
            Communication__e event = new Communication__e(
                Message__c = message,
                Record_Id__c = intgration.Id,
                Type__c = type,
                product__c = opp.Product__c
            );
            
            // Publish the event
            Database.SaveResult result = EventBus.publish(event);
            
            // Check if the publishing was successful
            if (result.isSuccess()) {
                System.debug('Platform Event published successfully.'+result);
                return true;
            } else {
                // Log errors if publishing failed
                for (Database.Error error : result.getErrors()) {
                    System.debug('Error publishing event: ' + error.getMessage());
                }
                return false;
            }
        } catch (Exception e) {
            // Handle any unexpected exceptions
            System.debug('Exception while publishing Platform Event: ' + e.getMessage());
            return false;
        }
    }
    // to check whether the entered values is in the date format or not
    public static Boolean isDate(String value){
        Boolean returnValue;
        
        try{
            Date.valueOf(value);
            returnValue = true;
        }
        catch(Exception e) {
            returnValue = false;
        }
        
        return returnValue;
    }
    
    public static Map<String, Schema.SObjectField> getObjectFieldInfoMap(string objectName){
        system.debug('objectName: '+objectName);
        
        try
        {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            Schema.SObjectType sobjType = gd.get(objectName);
            Schema.DescribeSObjectResult r = sobjType.getDescribe();
            return r.fields.getMap();
        }
        catch(Exception e){
            System.debug('Error: ' + e);
            System.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
        }
        
        return null;
    }
    
    //to check if object is accessible by user
    public static Boolean checkObjectIsAccessible(string objectName, string accessType){
        boolean result = false;
        
        try
        {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            Schema.SObjectType sobjType = gd.get(objectName);
            Schema.DescribeSObjectResult r = sobjType.getDescribe();
            
            switch on accessType{
                when 'Create'{
                    result = r.isCreateable();
                }
                when 'Update'{
                    result = r.isUpdateable();
                }
                when 'Delete'{
                    result = r.isDeletable();
                }
            }
        }
        catch(Exception e){
            System.debug('Error: ' + e);
            System.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
        }
        
        system.debug('checkObjectIsAccessible result: '+result);
        return result;
    }
    
    //masking a string
    public static string getMaskedString(string value){
        string temp = '';
        String rightSide;
        
        if(string.isNotBlank(value)){
            try{
                String leftSide;
                
                rightSide = value.right(4);
                leftSide = value.removeEnd(rightSide);
                
                Integer i=0;
                do{
                    if(i < leftSide.length()){
                        temp = temp + 'X';
                    }
                    
                    i=i+1;
                }
                while(i < leftSide.length());
            }
            catch(Exception e){
                System.debug('Error: ' + e);
                System.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
            }
        }
        
        
        return temp + rightSide;
    }
    
    
    @AuraEnabled
    public static String getCurrentUserProfileName(){
        return [Select Name From Profile Where Id =: userinfo.getProfileId()].Name;
    }
    
    public static Id getRecordTypeIdByDeveloperName(String objApiName, String developerName){
        String[] types = new String[]{objApiName};
            Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        
        if(!results.isEmpty()) {
            Schema.RecordTypeInfo rt = results[0].getRecordTypeInfosByDeveloperName().get(developerName);
            if(rt != null){
                return rt.getRecordTypeId();
            }
        }
         
        return null;
    }

    public static Map<string, Schema.RecordTypeInfo> getRecordTypeDetails(String objApiName){ 
        String[] types = new String[]{objApiName};
        
        try{
            return Schema.describeSObjects(types)[0]?.getRecordTypeInfosByDeveloperName();
        }
        catch(Exception e){
            System.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
        }
        
        return null;
    }
    
    @AuraEnabled
    public static String getNumberTOWordConvertion(Decimal num) {
        string result = '';
        
        if(num != null && num > -1){
            Decimal junkVal = num;
            Decimal junkValPaisa = junkVal - Math.floor(junkVal);
            junkVal = Math.floor(junkVal);
            
            String obStr = junkVal.toPlainString();
            String[] numReversed = obStr.split('');
            String[] actnumber = reverse(numReversed);
            String firstHalf = convertInWords(numReversed, actnumber);
            
            Integer tmp = Math.round(junkValPaisa * 100);
            junkValPaisa = (Decimal) tmp / 100; 
            
            String paisaStr = junkValPaisa.toPlainString();
            String secondHalf;
            
            if (paisaStr == '0') {
                secondHalf = '';
            } 
            else if(paisaStr.length() != 4) {
                paisaStr = paisaStr + '0';
                paisaStr = paisaStr.substring(2);
                String [] numReversedPaisa = paisaStr.split('');
                String[] actnumberPaisa = reverse(numReversedPaisa);
                secondHalf = convertInWords(numReversedPaisa, actnumberPaisa);
            }
            else {
                paisaStr = paisaStr.substring(2);
                String [] numReversedPaisa = paisaStr.split('');
                String[] actnumberPaisa = reverse(numReversedPaisa);
                secondHalf = convertInWords(numReversedPaisa, actnumberPaisa);
            }
            
            String sumOFHalves = '';
            
            if(secondHalf.length() > 4) {
                firstHalf = firstHalf.replace('Only', 'Rupees And ');
                secondHalf = secondHalf.replace('Only', 'Paisa Only');
                sumOFHalves = firstHalf + secondHalf;
            } 
            else {
                firstHalf = firstHalf.replace('Only', 'Rupees Only');
                sumOFHalves = firstHalf;
            }
            
            // IF amount has any value
            if(sumOFHalves.length() > 5) {
                result = sumOFHalves;
            }
        }
        
        system.debug('getNumberTOWordConvertion result: '+result);
        return result;
    }
    
    private static List<String> reverse(List<String> strToRev) {
        List<String> revList = new List<String>();
        for(Integer i = strToRev.size() -1; i >= 0; i--) {
            revList.add(strToRev.get(i));
        }
        
        revList.add('');
        return revList;
    }
    
    private static String convertInWords(String[] numRev, String[] actnum) {
        List<String> iWords = new List<String> {'Zero', ' One', ' Two', ' Three', ' Four', ' Five', ' Six', ' Seven', ' Eight', ' Nine'};
            List<String> ePlace = new List<String> {' Ten', ' Eleven', ' Twelve', ' Thirteen', ' Fourteen', ' Fifteen', ' Sixteen', ' Seventeen', ' Eighteen', ' Nineteen'};
                List<String> tensPlace = new List<String> {'dummy', ' Ten', ' Twenty', ' Thirty', ' Forty', ' Fifty', ' Sixty', ' Seventy', ' Eighty', ' Ninety' };
                    
                    Integer iWordsLength = numRev.size();
        List<String> inWords = new List<String>();
        
        for(Integer k = 0; k < iWordsLength; k++) {
            inWords.add('');
        }
        
        String finalWord = '';
        Integer j = 0;
        
        // Main For loop
        for(Integer i = 0; i < iWordsLength; i++) {
            
            switch on i {
                when 0 {
                    if(actnum[i] == '0' || actnum[i + 1] == '1') {
                        inWords[j] = '';
                    } 
                    else {
                        inWords[j] = iWords[Integer.valueof(actnum[i])];
                    }
                    
                    inWords[j] = inWords[j] + ' Only';
                }
                when 1 {
                    if (actnum[i] == '0') {
                        inWords[j] = '';
                    } 
                    else if (actnum[i] == '1') {
                        inWords[j] = ePlace[Integer.valueof(actnum[i - 1])];
                    } 
                    else {
                        inWords[j] = tensPlace[Integer.valueof(actnum[i])];
                    }   
                }
                when 2 {
                    if (actnum[i] == '0') {
                        inWords[j] = '';
                    } 
                    else if (actnum[i - 1] != '0' && actnum[i - 2] != '0') {
                        inWords[j] = iWords[Integer.valueof(actnum[i])] + ' Hundred and';
                    } 
                    else {
                        inWords[j] = iWords[Integer.valueof(actnum[i])] + ' Hundred';
                    }
                }
                when 3 {
                    if (actnum[i] == '0' || actnum[i + 1] == '1') {
                        inWords[j] = '';
                    } 
                    else {
                        inWords[j] = iWords[Integer.valueof(actnum[i])];
                    }
                    if (actnum[i + 1] != '0' || Integer.valueof(actnum[i]) > 0) {
                        inWords[j] = inWords[j] + ' Thousand';
                    }   
                }
                when 4 {
                    if (actnum[i] == '0') {
                        inWords[j] = '';
                    } 
                    else if (actnum[i] == '1') {
                        inWords[j] = ePlace[Integer.valueof(actnum[i - 1])];
                    } 
                    else {
                        inWords[j] = tensPlace[Integer.valueof(actnum[i])];
                    }
                }
                when 5 {
                    if (actnum[i] == '0' || actnum[i + 1] == '1') {
                        inWords[j] = '';
                    } 
                    else {
                        inWords[j] = iWords[Integer.valueof(actnum[i])];
                    }
                    if (actnum[i + 1] != '0' || Integer.valueof(actnum[i]) > 0) {
                        inWords[j] = inWords[j] + ' Lakh';
                    }
                }
                when 6 {
                    if (actnum[i] == '0') {
                        inWords[j] = '';
                    } 
                    else if (actnum[i] == '1') {
                        inWords[j] = ePlace[Integer.valueof(actnum[i - 1])];
                    } 
                    else {
                        inWords[j] = tensPlace[Integer.valueof(actnum[i])];
                    }
                }
                when 7 {
                    if (actnum[i] == '0' || actnum[i + 1] == '1' ) {
                        inWords[j] = '';
                    } 
                    else {
                        inWords[j] = iWords[Integer.valueof(actnum[i])];
                    }
                    
                    inWords[j] = inWords[j] + ' Crore';
                }
                when 8 {
                    if (actnum[i] == '0') {
                        inWords[j] = '';
                    } 
                    else if (actnum[i] == '1') {
                        inWords[j] = ePlace[Integer.valueof(actnum[i - 1])];
                    } 
                    else {
                        inWords[j] = tensPlace[Integer.valueof(actnum[i])];
                    }
                }
            }
            
            j++;
        }
        // End of For loop
        
        // Reverse the List
        inWords = reverse(inWords);
        
        for(Integer i = 0; i < inWords.size(); i++) {
            finalWord += inWords[i];
        }
        
        system.debug('convertInWords result: '+finalWord);
        return finalWord;
    }
    
    public static String getRecordTypeNameById(String objectName, Id strRecordTypeId){
        return Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosById().get(strRecordTypeId).getName();
    }
    
    public static String getRecordTypeDeveloperNameById(String objectName, Id strRecordTypeId){
        return Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosById().get(strRecordTypeId).getdeveloperName();
    }
    
    // Validate name fields (alphabets, and special characters)
    public static boolean isValidName(string name){
        return (String.isNotBlank(name) && Pattern.matches('^[A-Za-z]+([ ]?[A-Za-z]+)*$', name));
    }
    
    // Validate mobile number (10 digits only)
    public static boolean isValidMobileNumber(string mobileNo){
        return (String.isNotBlank(mobileNo) && Pattern.matches('^\\d{10}$', mobileNo));
    }
    //Validate email
    
    public static boolean isEmailValid(String email) {
        return (String.isNotBlank(email) && Pattern.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$', email));
    }
    
    //validate company name
    public static boolean isCompanyNameValid(string companyName){
        return(String.isNotBlank(companyName));
    }
    
    public static HTTPResponse executeAPIRequest(Map<string, string> apiParam){
        try{
            System.debug('------------'+apiParam);
            String integrationSettingName = apiParam.get('intSettingName');
            
            Integration_Settings__c intDetails = [SELECT Client_Id__c, Cookie__c, Client_Secret__c, Endpoint__c, Content_Type__c, Authorization__c, Request_Method__c
                                                  FROM Integration_Settings__c WHERE Name =: apiParam.get('intSettingName') Limit 1];
            
            HttpRequest req = new HttpRequest();
            if(apiParam.get('intSettingName') != 'Bank Statement Analysis' && apiParam.get('intSettingName') != 'Blacklist Customers'){
                req.setHeader('Cookie', intDetails.Cookie__c);
            }

            System.debug('Inside authorization header setting for Callout: '+integrationSettingName);
            String authorizationHeader = 'Bearer ' + apiParam.get('bearer');
            req.setHeader('Authorization', authorizationHeader);
            System.debug('Auth header set for Callout: '+integrationSettingName);

            if(apiParam.containsKey('Origin')){
                req.setHeader('Origin', apiParam.get('Origin'));
            }
            if(apiParam.containsKey('serviceName')){
                req.setHeader('ServiceName', apiParam.get('serviceName'));
            }
            if(apiParam.containsKey('MESSAGEID')){
                req.setHeader('MESSAGEID', apiParam.get('MESSAGEID'));
            }
            if(apiParam.containsKey('ENTITYID')){
                req.setHeader('ENTITYID', apiParam.get('ENTITYID'));
            }
            if(apiParam.containsKey('ServiceVersion')){
                req.setHeader('ServiceVersion', apiParam.get('ServiceVersion'));
            }
            if(apiParam.containsKey('RequestTime')){
                req.setHeader('RequestTime', apiParam.get('RequestTime'));
            }
            if(apiParam.containsKey('Language')){
                req.setHeader('Language', apiParam.get('Language'));
            }
            
            if(apiParam.containsKey('endPoint')){
                req.setEndpoint(apiParam.get('endPoint'));
            }
            else{
                req.setEndpoint(intDetails.EndPoint__c);
            }

            req.setTimeout(120000);
            req.setMethod(intDetails.Request_Method__c);
            req.setHeader('Content-Type', intDetails.Content_Type__c);
            
            if(apiParam.containsKey('requestJSON')){
                string requestJSON = apiParam.get('requestJSON');
                req.setBody(requestJSON);
                //system.debug('requestJSON: '+ requestJSON);
            }
           
            System.debug('Request: '+ req);
            
            Http http = new Http();
            HTTPResponse res = http.send(req);
            
            return res;
        }
        catch(System.Exception e){
            String fullStackTrace = e.getStackTraceString();
            String lineNumberInfo = '';

            if(String.isNotBlank(fullStackTrace)) {
                List<String> lines = fullStackTrace.split('\n');
                if(!lines.isEmpty()) {
                    lineNumberInfo = lines[0]; 
                }
            }
            System.debug('ï¸Exception at:utility ' + lineNumberInfo);
            System.debug('Error Message:utility ' + e.getMessage());
            return null;
        }
    }
    
    public static HTTPResponse executeRESTAPIRequest(Map<string, string> apiParam){
        try{
            System.debug('------------');
            
            Integration_Settings__c intDetails = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                                                  FROM Integration_Settings__c WHERE Name =: apiParam.get('intSettingName') Limit 1];
            
            HttpRequest req = new HttpRequest();
            req.setHeader('Content-Type', intDetails.Content_Type__c);
            req.setHeader('client_id', intDetails.Client_Id__c);
            req.setHeader('client_secret', intDetails.Client_Secret__c);
            req.setHeader('Authorization', 'Bearer ' + apiParam.get('bearer'));
            
            string endpoint = intDetails.EndPoint__c + (apiParam.containsKey('customEndpoint') ? apiParam.get('customEndpoint') : '');
            req.setEndpoint(endpoint);
            //System.debug('Endpoint: ' + endpoint);
            
            req.setMethod(intDetails.Request_Method__c);
            //System.debug('Method: '+ intDetails.Request_Method__c);
            
            req.setTimeout(120000);
            //System.debug('Timeout: 120000');
            
            if(apiParam.containsKey('requestJSON')){
                string requestJSON = apiParam.get('requestJSON');
                req.setBody(requestJSON);
                system.debug('requestJSON: '+ requestJSON);
            }
            
            //System.debug('Source: '+ URL.getOrgDomainURL().toExternalForm());
            System.debug('Request: '+ req);
            
            Http http = new Http();
            HTTPResponse res = http.send(req);
            
            //System.debug('Response: '+ res);
            System.debug('Response body: ' + res.getBody());
            system.debug('Response code: ' + res.getStatusCode());
            System.debug('------------');
            
            return res;
        }
        catch(System.Exception e){
            System.debug('Error: ' + e);
            System.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
            
            return null;
        }
    }
    
    
    public static Integration_Details__c fillIntegrationRecord(string source, string reqJSON, string resJSON, string status, string method, string endpoint, string objName, string relRecordId, string process, string loanAppId){
        Integration_Details__c rec = new Integration_Details__c();
        rec.Calling_Source__c = source;
        rec.Request_JSON__c = reqJSON;
        rec.Response_JSON__c = resJSON;
        rec.Status__c = status;
        rec.Method_Type__c = method;
        rec.EndPoint__c = endpoint;
        rec.Object_Name__c = objName;
        rec.Related_Record_Id__c = relRecordId;
        rec.Name = process;
        if(loanAppId!=''){
        rec.Loan_Application__c = loanAppId;
        }
        return rec;
    }
    
    public static void createIntegrationRecord(List<Integration_Details__c> recList){
        if(System.isFuture()){
            insert recList;
        }
        else{
            createIntegrationDetailsRecordInFuture(JSON.serialize(recList));
        }
    }
    
    @future
    public static void createIntegrationDetailsRecordInFuture(string recListJSON){
        List<Integration_Details__c> recList = (List<Integration_Details__c>)JSON.deserialize(recListJSON, List<Integration_Details__c>.class);
        insert recList;
    }
    
    public static Error_Logs__c fillErrorRecord(string errorDetails, string stackTrace, string processName, string objName, string relRecordId){
        Error_Logs__c log = new Error_Logs__c();
        log.Error_Details__c = errorDetails;
        log.Stack_Trace__c = stackTrace;
        log.Process_Name__c = processName;
        log.Object_Name__c = objName;
        log.Related_Record_Id__c = relRecordId;
        return log;
    }
    
    public static Error_Logs__c logException(String errorDetails, String stackTrace, String processName, String loanId) {
        Error_Logs__c log = new Error_Logs__c();
        log.Error_Details__c = errorDetails;
        log.Stack_Trace__c = stackTrace;
        log.Class_Name__c = processName;
        log.Loan_Application__c = loanId;
        return log;
    }

    public static void createErrorLogRecord(List<Error_Logs__c> logList){
        if(System.isFuture()){
            insert logList;
        }
        else{
            createErrorLogRecordInFuture(JSON.serialize(logList));
        }
    }
    
    @future
    public static void createErrorLogRecordInFuture(string logListJSON){
        List<Error_Logs__c> logList = (List<Error_Logs__c>)JSON.deserialize(logListJSON, List<Error_Logs__c>.class);
        insert logList;
    }
    
    @future
    public static void deleteDocumentRecordOnFailure(Set<string> docDetailsIdSet, Set<string> conDocIdSet){
        if(!docDetailsIdSet.isEmpty()){
            List<Document_Details__c> ddList = [SELECT Id FROM Document_Details__c WHERE Id IN : docDetailsIdSet];
            delete ddList;
        }
        if(!conDocIdSet.isEmpty()){
            List<ContentDocument> cdList = [SELECT Id FROM ContentDocument WHERE Id IN : conDocIdSet];
            delete cdList;
        }
    }
    
    @AuraEnabled
    public static Map<string, Lead> getExistingLead(Map<String, String> mobileNoToCustomerTypeMap, string source){
        
        Map<String, Lead> mobileToExistingLeadMap = new Map<String, Lead>();
        Set<String> nonBlankAssignedUserIds = new Set<String>();
        
        for(Lead itr : [Select Id, MobilePhone, Lead_Number__c, FirstName, MiddleName, LastName, Company, Lead_Age_In_Hrs__c, Pincode__c, Assigned_Sales_User__c, 
                        Email, Customer_Type__c, Date_of_Birth__c, Date_of_Incorporation__c
                        From Lead where (MobilePhone != null and MobilePhone In : mobileNoToCustomerTypeMap.keySet()) and Status = 'Open' Order By CreatedDate Desc])
        {    
            if(!mobileToExistingLeadMap.containsKey(itr.MobilePhone) && mobileNoToCustomerTypeMap.get(itr.MobilePhone) == itr.Customer_Type__c){
                
                //check gestation period
                if(itr.Lead_Age_In_Hrs__c > integer.valueOf(Label.Lead_Gestation_Duration_In_Hrs)){
                    mobileToExistingLeadMap.put(itr.MobilePhone, itr);
                }
                else {
                    //check minimum action period
                    if(itr.Lead_Age_In_Hrs__c > integer.valueOf(Label.Lead_MAP_Duration_In_Hrs)){
                        mobileToExistingLeadMap.put(itr.MobilePhone, itr);
                    }
                    else{
                        if(source == 'API'){
                            mobileToExistingLeadMap.put(itr.MobilePhone, itr);
                        }
                        //send notification to the original owner if the user is different
                        if (itr.Assigned_Sales_User__c != null) {
                            nonBlankAssignedUserIds.add(itr.Assigned_Sales_User__c);
                            // Call notification method if there are valid user IDs
                            if (!nonBlankAssignedUserIds.isEmpty()) {
                                sendInAppNotification(itr.Id,'Duplicate Lead', 'An user is trying to create a duplicate lead. Please click to see the reference.', nonBlankAssignedUserIds, 'Duplicate_Lead');
                            }
                        }
                        //LeadManagementController.createTask(itr.Id);
                    }
                }
            }
        }
        
        mobileNoToCustomerTypeMap.clear();
        
        //system.debug('mobileToExistingLeadMap: '+mobileToExistingLeadMap);
        return mobileToExistingLeadMap;
    } 
    
    public static Account getNearestBranchByPincode(String pinCode) {
        Account branch = new Account();
        
        try{
            if(string.isNotBlank(pinCode)){
                Map<String, Location> pinToGeolocationMap = new Map<String, Location>();
                
                for(Pincode_Master__c pm : [SELECT Name, LatLong__Latitude__s, LatLong__Longitude__s FROM Pincode_Master__c 
                                            WHERE Name =: pinCode And LatLong__Latitude__s != null AND LatLong__Longitude__s != null]) {
                                                
                                                pinToGeolocationMap.put(pm.Name, Location.newInstance(pm.LatLong__Latitude__s, pm.LatLong__Longitude__s));
                                            }
                
                if(!pinToGeolocationMap.isEmpty()) {
                    
                    Double minDist = 0;
                    Location custLocation = pinToGeolocationMap.get(pinCode);
                    
                    for(Account bm : [SELECT Id, Name, Location__Latitude__s, Location__Longitude__s FROM Account
                                      WHERE Is_Active__c = true And Location__Latitude__s != null AND Location__Longitude__s != null]) {
                                          
                                          Location branchLocation = Location.newInstance(bm.Location__Latitude__s, bm.Location__Longitude__s);
                                          Double distance = Location.getDistance(branchLocation, custLocation, Constants.KM);
                                          //System.debug('distance---'+distance);
                                          if(distance <= minDist) {
                                              minDist = distance;
                                              branch = bm;
                                              //System.debug('branch---'+branch);
                                          }
                                      }
                }
            }
        }
        catch(Exception e){
            System.debug('Error: ' + e);
            System.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
        }
        
        return branch;
    }
    
    public static void createShareRecord(string sharingListJSON){
        try{
            System.debug('sharingListJSON 951 : '+sharingListJSON);
            List<LeadShare> leadShareList = new List<LeadShare>();
            List<Application_Verification__Share> fieldInvestiagationShareList = new List<Application_Verification__Share>();
            List<OpportunityShare> oppShareList = new List<OpportunityShare>();
            List<Document_Details__Share> docShareList = new List<Document_Details__Share>();
            List<Application_Applicant__Share> appShareList = new List<Application_Applicant__Share>();
            List<Query__Share> queryList = new List<Query__Share>();
            List<SharingInfo> sharingList = (List<SharingInfo>)JSON.deserialize(sharingListJSON, List<SharingInfo>.class);
            
            for(SharingInfo si : sharingList){
                
                switch on si.objectName { 
                    when 'Lead'
                    {
                        LeadShare rcdShr = new LeadShare();
                        rcdShr.LeadId = si.recordToShareId;
                        rcdShr.UserOrGroupId = si.userOrGroupId;
                        rcdShr.LeadAccessLevel = si.sharingAccess;
                        
                        if(si.sharingReason == Constants.ROW_CAUSE_MANUAL){
                            rcdShr.RowCause = Constants.ROW_CAUSE_MANUAL;
                        }
                        
                        leadShareList.add(rcdShr);
                    }
                    when 'Application_Verification__c'{
                        Application_Verification__Share rcdShr = new Application_Verification__Share();
                        rcdShr.parentId = si.recordToShareId;
                        rcdShr.UserOrGroupId = si.userOrGroupId;
                        rcdShr.AccessLevel = si.sharingAccess;
                        
                        if(si.sharingReason == Constants.ROW_CAUSE_MANUAL){
                            rcdShr.RowCause = Constants.ROW_CAUSE_MANUAL;
                        }
                        
                        fieldInvestiagationShareList.add(rcdShr);
                    }
                    when 'Opportunity' 
                    {
                        OpportunityShare rcdShr = new OpportunityShare();
                        rcdShr.OpportunityAccessLevel = si.sharingAccess;
                        rcdShr.OpportunityId = si.recordToShareId;
                        if(si.sharingReason == Constants.ROW_CAUSE_MANUAL){
                            rcdShr.RowCause = Constants.ROW_CAUSE_MANUAL;
                        }
                        
                        
                        rcdShr.UserOrGroupId = si.userOrGroupId;
                        oppShareList.add(rcdShr);
                        
                    }
                    when 'Document_Details__c' 
                    {
                        Document_Details__Share rcdShr = new Document_Details__Share();
                        rcdShr.AccessLevel= si.sharingAccess;
                        rcdShr.parentId = si.recordToShareId;
                        if(si.sharingReason == Constants.ROW_CAUSE_MANUAL){
                            rcdShr.RowCause = Constants.ROW_CAUSE_MANUAL;
                        }
                        
                        
                        rcdShr.UserOrGroupId = si.userOrGroupId;
                        docShareList.add(rcdShr);
                        
                    }
                    when 'Application_Applicant__c' 
                    {
                        Application_Applicant__Share rcdShr = new Application_Applicant__Share();
                        rcdShr.AccessLevel= si.sharingAccess;
                        rcdShr.parentId = si.recordToShareId;
                        if(si.sharingReason == Constants.ROW_CAUSE_MANUAL){
                            rcdShr.RowCause = Constants.ROW_CAUSE_MANUAL;
                        }
                        
                        
                        rcdShr.UserOrGroupId = si.userOrGroupId;
                        appShareList.add(rcdShr);
                        
                    }
                    when 'Query__c'{
                        Query__Share rcdShr = new  Query__Share();
                        rcdShr.parentId = si.recordToShareId;
                        rcdShr.UserOrGroupId = si.userOrGroupId;
                        rcdShr.AccessLevel = si.sharingAccess;
                        if(si.sharingReason == Constants.ROW_CAUSE_MANUAL){
                            rcdShr.RowCause = Constants.ROW_CAUSE_MANUAL;
                        }
                        queryList.add(rcdShr);
                    }
                }
            }
            
            if(!leadShareList.isEmpty())
                insert leadShareList;
            if(!fieldInvestiagationShareList.isEmpty())
                insert fieldInvestiagationShareList;
            if(!oppShareList.isEmpty()){
                insert oppShareList;
            }
            if(!docShareList.isEmpty()){
                insert docShareList;
            }
            if(!appShareList.isEmpty()){
                insert appShareList;
            }
            if(!queryList.isEmpty()){
                System.debug('queryList : '+queryList);
                insert queryList;
            }
            
            // if(!lapShareList.isEmpty())
            //     insert lapShareList;
        }
        catch(Exception e){
            system.debug('Error: ' + e);
            system.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
        }
    }
    
    @AuraEnabled
    public static string getImageURL(String contentId){
        return '/sfc/servlet.shepherd/document/download/' +contentId+'?operationContext=native';
    }
    
    
    @AuraEnabled(cacheable=true)
    public static String getFieldLabel(String fieldApiName, String objectApiName) {
        string result = 'Field not found';
        
        try {
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();
            if(fieldMap.containsKey(fieldApiName)) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldApiName).getDescribe();
                result = fieldDescribe.getLabel();
            }
        }
        catch (Exception e) {
            system.debug('Error: ' + e);
            system.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
            result = 'Error fetching field label';
        }
        
        return result; 
    }
    

    @AuraEnabled
    public static CustomerDedupeController.DuplicateCustomerInfo callDedupeApi(Map<String, String> inputParams) {
        CustomerDedupeController.DuplicateCustomerInfo dupCust = new CustomerDedupeController.DuplicateCustomerInfo();
        
        dupCust.dupDetails = new List<CustomerDedupeController.DuplicateCustomerDetails>();
        dupCust.freshCustomer = true;
        
        
        CustomerDedupeWrapper.cls_Data custWrap = new CustomerDedupeWrapper.cls_Data();
        String dynamicAccQuery;
        
        String isKYCSelected = inputParams.get('isKYCSelected');
        String isCustIdPresent = inputParams.get('isCustIdPresent');
        String isMobScreen = inputParams.get('isMobScreen');
        
        String mobileNum = inputParams.get('mobileNum');
        String kycNum = inputParams.get('kycNum');
        String custId = inputParams.get('custId');
        String selectedKYC = inputParams.get('selectedKYC');
        String objectName = inputParams.get('objectName');
        String product = inputParams.get('product');
        
        System.debug('mobileNum '+mobileNum);
        System.debug('objectName '+objectName);
        System.debug('product '+product);
        
        // KYC Selection Logic
        if(Boolean.valueOf(isKYCSelected) && kycNum != null) {
            custWrap.FlgIndividual = '';
            
            // Switch logic for KYC
            switch on selectedKYC {
                
                when 'LEAD_OVD_1' { // PAN Number
                    custWrap.PANNumber = kycNum;
                    dynamicAccQuery = 'SELECT Id, Name, Mobile_Number__c, Customer_LMS_ID__c, PAN__c, DOB__c FROM Account ' +
                        'WHERE Customer_LMS_ID__c != null AND Type_of_Client__c = \'Existing Client\' ' +
                        'AND PAN__c != null AND PAN__c =: kycNum';
                }
                when 'LEAD_OVD_2' { // Voter ID
                    custWrap.VoterId = kycNum;
                    dynamicAccQuery = 'SELECT Id, Name, Mobile_Number__c, Customer_LMS_ID__c, PAN__c, DOB__c FROM Account ' +
                        'WHERE Customer_LMS_ID__c != null AND Type_of_Client__c = \'Existing Client\' ' +
                        'AND Voter_Id_Number__c != null AND Voter_Id_Number__c =: kycNum';
                }
                when 'LEAD_OVD_3' { // Passport
                    custWrap.PassportNumber = kycNum;
                    dynamicAccQuery = 'SELECT Id, Name, Mobile_Number__c, Customer_LMS_ID__c, PAN__c, DOB__c FROM Account ' +
                        'WHERE Customer_LMS_ID__c != null AND Type_of_Client__c = \'Existing Client\' ' +
                        'AND PassportNumber__c != null AND PassportNumber__c =: kycNum';
                }
                when 'LEAD_OVD_4' { // DL
                    custWrap.DrivingLicenseNumber = kycNum;
                    dynamicAccQuery = 'SELECT Id, Name, Mobile_Number__c, Customer_LMS_ID__c, PAN__c, DOB__c FROM Account ' +
                        'WHERE Customer_LMS_ID__c != null AND Type_of_Client__c = \'Existing Client\' ' +
                        'AND DrivingLicenseNumber__c != null AND DrivingLicenseNumber__c =: kycNum';
                }
                when else {
                    throw new IllegalArgumentException('Invalid selectedKYC value.');
                }
            }
        }

        // Customer ID logic
        else if(Boolean.valueOf(isCustIdPresent) && custId != null) { 
            custWrap.customerId = custId;
            dynamicAccQuery = 'SELECT Id, Name, Mobile_Number__c, Customer_LMS_ID__c, PAN__c, DOB__c FROM Account ' +
                'WHERE Customer_LMS_ID__c != null AND Type_of_Client__c = \'Existing Client\' ' +
                'AND Customer_LMS_ID__c =: custId';
        }
        // Mobile Screen logic
        else if(Boolean.valueOf(isMobScreen) && mobileNum != null){
            dupCust.softDedupe = true;
            custWrap.FlgIndividual = '';
            custWrap.Mobilenumber = mobileNum;
            dynamicAccQuery = 'Select Id, Name, Mobile_Number__c, Date_of_Birth__c, Customer_LMS_ID__c, PAN_Number__c from Account '+
                'where Mobile_Number__c != null and Mobile_Number__c =: mobileNum';
        } 
        else {
            throw new IllegalArgumentException('No valid inputs found.');
        }
        
        System.debug('Account Query :: ' + dynamicAccQuery);
        
        // Execute Dynamic Account Query
        List<Account> accList = new List<Account>();
        if(dynamicAccQuery != null) {
            accList = Database.query(dynamicAccQuery);
            System.debug('accList '+accList);
        }
        
        // Handle Account Results
        if(!accList.isEmpty()) {
            System.debug('991');
            dupCust.freshCustomer = false;
            dupCust.duplicateCustFromApi = false;
            
            for(Account resp : accList) {
                CustomerDedupeController.DuplicateCustomerDetails dupInfo = new CustomerDedupeController.DuplicateCustomerDetails();
                dupInfo.customerName = resp.Name;
                dupInfo.customerNumber = resp.Customer_LMS_ID__c != null ? Integer.valueOf(resp.Customer_LMS_ID__c) : null;
                dupInfo.dateOfBirth = resp.Date_of_Birth__c;
                dupInfo.mobileNumber = resp.Mobile_Number__c != null ? String.valueOf(resp.Mobile_Number__c) : '-';
                dupInfo.maskedMobileNumber = resp.Mobile_Number__c != null ? getMaskedString(String.valueOf(resp.Mobile_Number__c), 'X', 6) : '-';
                //dupInfo.panNumber = resp.PAN__c != null ? resp.PAN__c : '-';  // Revisit PAN Issue
                dupInfo.Id = resp.Id;
                //dupInfo.maskedPanNumber = resp.PAN__c != null ? getMaskedString(String.valueOf(resp.PAN__c), 'X', 6) : '-';
                dupCust.dupDetails.add(dupInfo);
            }
        }
        else {
            // Call external API logic here (if necessary)
        }
        //  catch (Exception exp) {
        //     // Utility.generateException(exp, Constants.LEAD_OBJECT_NAME, Constants.LEAD_CLASS_3);
        // }
        
        // dupCust.freshCustomer = true; // Uncomment to bypass dedupe
        System.debug('dupCust '+dupCust.dupDetails);
        return dupCust;
    }
    
    public static String getMaskedString(String inputStr, String replacementCharacter, Integer segmentLength){
        String outputString = '';
        
        if(inputStr.length() >= segmentLength) {
            String replacementString = replacementCharacter.repeat(segmentLength);
            outputString = replacementString + inputStr.substring(segmentLength);
        }
        
        return outputString;
    }
    
    // send notification to assigned user
    public static void sendInAppNotification(string leadId, string title, string notificationBody, set<string> recipientsIds, String notifictnType){
        System.debug('leadId '+leadId);
        System.debug('recipientsIds '+recipientsIds);
        if(!recipientsIds.isEmpty()){
            CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName =: notifictnType];
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle(title);
            notification.setBody(notificationBody);
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(leadId);
            notification.send(recipientsIds);
        }
    } 
    
    @AuraEnabled
    public static String encodeRecordId(String recordId) {
        if(String.isNotBlank(recordId)) {
            Blob inputBlob = Blob.valueOf(recordId); // Convert the string to Blob
            return EncodingUtil.base64Encode(inputBlob); // Base64 encode the Blob
        }
        
        return null;
    }
    
    @AuraEnabled
    public static String decodeRecordId(String encodedRecordId) {
        if(String.isNotBlank(encodedRecordId)) {
            return EncodingUtil.base64Decode(encodedRecordId).toString();
        }
        
        return null;
    }
    
    public class SharingInfo {
        public String objectName;
        public String userOrGroupId;
        public String recordToShareId;
        public String sharingAccess;
        public String sharingReason;
    }
    
    public class FieldInfo {
        @AuraEnabled
        public String labelName;
        @AuraEnabled
        public String apiName;
        @AuraEnabled
        public String type;
    }
    
    @AuraEnabled
    public static LeadWrapper getActiveLeadDetails(String leadName){
        Lead rec = [SELECT Id, Lead_Number__c, Owner.Id, Pan__c, Assigned_Sales_User__c from Lead where Lead_Number__c =: leadName];
        LeadWrapper leadData = new LeadWrapper();
        leadData.activeLeadId = rec.Id;
        leadData.activeLeadName = rec.Lead_Number__c;
        leadData.activeLeadOwnerId = rec.Owner.Id;
        // leadData.activeLeadMobileNo = rec.Assigned_User__r.MobilePhone;
        leadData.activeLeadPANNo = rec.Pan__c;
        leadData.userIdAssignedRo = rec.Assigned_Sales_User__c;
        return leadData;
    }
    
    public class LeadWrapper{
        @AuraEnabled public String userIdAssignedRo;
        @AuraEnabled public String activeLeadId;
        @AuraEnabled public String activeLeadName;
        @AuraEnabled public String activeLeadOwnerId;
        @AuraEnabled public String activeLeadPANNo;
    }
    
    @AuraEnabled
    public static String getreferenceLead(String phoneNumber,String leadId) {
        List<Lead> leads = [
            SELECT Id,Lead_Number__c FROM Lead WHERE MobilePhone = :phoneNumber AND Status != 'Closed' AND Id != :leadId LIMIT 1];
        if(!leads.isEmpty()) {
            return leads[0].Id;
        }
        else {
            return null; // No matching lead found
        }
    }
    
    
    @AuraEnabled
    public static string getreferenceLeadforPan(String pan){
        List<Lead> leads = [SELECT Id, Name FROM Lead WHERE Pan__c =: pan];
        if(!leads.isEmpty()){
            return leads[0].Id;
        }
        else {
            return null;
        }
    }
    @AuraEnabled
    public static string pincodeName(String pinId){
        try {
            List<Pincode_Master__c> PM = [Select Id,Name from Pincode_Master__c where Id=:pinId];
            return PM[0].Name ;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public static Error_Logs__c generateException(Exception objErr, String strObject, String strClassName) {
        Error_Logs__c exceptionObj = new Error_Logs__c
            (
                Error_Details__c = objErr.getMessage(),
                //Exception_Type__c = objErr.getTypeName(),
                //Cause__c = String.valueOf(objErr.getCause()),
                //Class_Name__c = strClassName,
                Object_Name__c = strObject,
                //Line_No__c = String.valueOf(objErr.getLineNumber()),
                //Occurence_Date__c = Date.today(),
                Stack_Trace__c = objErr.getStackTraceString(),
                OwnerId = Userinfo.getUserId()
            );
        insert exceptionObj;
        
        return exceptionObj;
    }
    public static void sendNotification(String notificationId, String bodyMessage, String title, String targetId, String sendTo){
        Messaging.CustomNotification assignToCCENotification = new Messaging.CustomNotification();
        assignToCCENotification.setNotificationTypeId(notificationId);
        assignToCCENotification.setSenderId(UserInfo.getUserId());
        assignToCCENotification.setBody(bodyMessage);
        assignToCCENotification.setTitle(title);
        assignToCCENotification.setTargetId(targetId);
        assignToCCENotification.send(new Set<String> {sendTo});
    }
    
    @AuraEnabled
    public static void updateConsentFields(String recordId) {
        try {
            if (String.isEmpty(recordId)) {
                throw new AuraHandledException('Record ID is required.');
            }
            
            // Fetch the Application_Applicant__c record
            List<Application_Applicant__c> applicantList = [SELECT Id, Loan_Application__c, Applicant_Consent_Received__c FROM Application_Applicant__c WHERE Loan_Application__c = :recordId];

            Opportunity loan= [SELECT Id, Is_Consent_Received__c, Consent_Status__c  FROM Opportunity WHERE Id = :recordId];
            
            // Update fields
            loan.Is_Consent_Received__c = true;
            loan.Consent_Status__c = 'Accepted';
            // applicant.Is_Mobile_Verified__c = true;
            
            // Perform update
            update loan; 

            for(Application_Applicant__c applicant: applicantList){
                applicant.Applicant_Consent_Received__c = 'yes';
            }
            update applicantList;
        } catch (DmlException e) {
            throw new AuraHandledException('Failed to update consent fields: ' + e.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException('An unexpected error occurred: ' + ex.getMessage());
        }
    }
    
    public static String getObjectApiNameFromLookup(String objectName, String fieldName){
        Schema.DescribeFieldResult f = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe();
        return f.getReferenceTo()[0].getDescribe().getName();
    }
    
    @AuraEnabled
    public static Boolean evaluateLeadConditions(Id leadId) {
        Lead leadRecord = [
            SELECT Product__c, Customer_Type__c, Age_of_Individual_Organisation__c, 
            Business_Vintage__c, Requested_Loan_Amount__c
            FROM Lead
            WHERE Id = :leadId
        ];
        List<Eligibility_Criterias__mdt> metadataList = [
            SELECT Product__c, Customer_Type__c, Field_Api_Name__c, Operator__c, Value__c
            FROM Eligibility_Criterias__mdt
            WHERE Product__c = :leadRecord.Product__c 
            AND Customer_Type__c = :leadRecord.Customer_Type__c
        ];
        
        for (Eligibility_Criterias__mdt condition : metadataList) {
            String fieldValue = String.valueOf(leadRecord.get(condition.Field_Api_Name__c));
            String operator = condition.Operator__c;
            String value = condition.Value__c;
            System.debug('fieldValue '+fieldValue+' operator '+operator+' value' +value);
            if (evaluateCondition(fieldValue, operator, value)) {
                System.debug('1300 false');
                return false;
            }
        }
        System.debug('1304 true');
        return true;
    }
    
    // Helper method to evaluate a condition
    public static Boolean evaluateCondition(String fieldValue, String operator, String value) { 
        try {
            switch on operator {
                when '>=' { 
                    return Decimal.valueOf(fieldValue) >= Decimal.valueOf(value); 
                }
                when '<=' { 
                    return Decimal.valueOf(fieldValue) <= Decimal.valueOf(value); 
                }
                when '=' { 
                    return fieldValue == value; 
                }
                when '!=' { 
                    return fieldValue != value; 
                }
                when '>' { 
                    return Decimal.valueOf(fieldValue) > Decimal.valueOf(value); 
                }
                when '<' { 
                    return Decimal.valueOf(fieldValue) < Decimal.valueOf(value); 
                }
                when else { 
                    return false; // Unsupported operator
                }
            }
        } catch (Exception e) {
            System.debug('Error evaluating condition: ' + e.getMessage());
            return false; // Handle invalid comparisons
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String getReportIdByName(String reportName){
        return [SELECT Id FROM Report WHERE Name =: reportName LIMIT 1]?.Id;
    }
    
    @AuraEnabled
    public static void assignUserRoundRobinBulk(List<Id> leadIds) {
        //try {
        
        set<Id> assignedUsers = new set<Id>();
        for(Lead itr : [SELECT Id, Assigned_Telesales_User__c FROM Lead WHERE Status = 'Open' AND Assigned_Telesales_User__c != NULL ORDER BY Lead_Number__c DESC]){
            assignedUsers.add(itr.Assigned_Telesales_User__c);
        }
        System.debug('assignedUsers: '+assignedUsers);
        
        Set<Id> unassignedUsers = new Set<Id>();
        for(User itr : [SELECT Id FROM User WHERE Profile.Name =: Label.Profile_GC_Tele_Sales_User AND Id Not IN : assignedUsers ]){ //AND LastLoginDate = LAST_N_DAYS:1
            unassignedUsers.add(itr.Id);
        }
        System.debug('unassignedUsers: '+unassignedUsers);
        
        List<Id> availableUser = new List<Id>();
        
        if(!unassignedUsers.isEmpty()){
            availableUser.addAll(unassignedUsers);
        }
        
        if(!assignedUsers.isEmpty()) {
            List<Id> temp = new List<Id>(assignedUsers);
            
            for(Integer i = temp.size() - 1; i >= 0; i--) {
                availableUser.add(temp[i]);
            }
        }
        
        unassignedUsers.clear();
        assignedUsers.clear();
        
        System.debug('availableUser: '+availableUser);
        System.debug('availableUser size: '+availableUser.size());
        
        Integer totalAvailableUsers = availableUser.size();
        
        if(totalAvailableUsers > 0){
            Integer counter = 0;
            
            List<Lead> leadToAssignList = [SELECT Id, Assigned_Telesales_User__c FROM Lead WHERE Id In : leadIds And Assigned_Telesales_User__c = NULL];
            
            for(Lead itr : leadToAssignList){
                
                if(counter >= totalAvailableUsers){
                    counter = 0;
                }
                
                itr.Assigned_Telesales_User__c = availableUser[counter];
                counter++;
            }
            
            System.debug('LeadToAssignList: '+LeadToAssignList);
            
            LeadTriggerHandler.isTriggerDisabled = true;
            update LeadToAssignList;
            LeadTriggerHandler.isTriggerDisabled = false;
        }
        //}
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
    
    //Used for Image capture cmp
    @AuraEnabled
    public static List<DocWrapper> fetchDoc(Id fieldId){
        String objectName  = fieldId.getSObjectType().getDescribe().getName();
        List<DocWrapper> docCheckList = new List<DocWrapper>();
        List<Application_Verification__c> fi= new  List<Application_Verification__c> ();
        List<id> contentDocumentIdList = new  List<id>();
        List<Document_Details__c> docList= new  List<Document_Details__c>();
        Map<String, String> contentIdToType = new  Map<String, String>();
        if(objectName=='Application_Verification__c'){
            fi=[Select id, Name from Application_Verification__c where id=:fieldId];
            String documentName=fi[0].Name+' '+'Report';
            docList = [Select Id, Name, Content_Document_Id__c, Is_Required__c,Application_Verification__r.Geo_coordinates__Latitude__s,Application_Verification__r.Geo_coordinates__Longitude__s  FROM Document_Details__c WHERE Application_Verification__c =: fieldId and Name!=:documentName];
        }
        for(Document_Details__c doc :docList){
            contentDocumentIdList.add(doc.Content_Document_Id__c);
        }
        List<ContentVersion> contentVersion = [SELECT FileType,ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN : contentDocumentIdList];
        for(ContentVersion c : contentVersion){
            contentIdToType.put(c.ContentDocumentId,c.FileType);
        }
        
        for(Document_Details__c docListIter : docList){
            DocWrapper docCheck = new DocWrapper();
            if(docListIter.Content_Document_Id__c != null){
                docCheck.isUploaded = true;
                
            }else{
                docCheck.isUploaded = false;
            }
            docCheck.name = docListIter.Name;
            
            docCheck.docId = docListIter.Id;
            docCheck.contentId = docListIter.Content_Document_Id__c;
            docCheck.isPDF=contentIdToType.get(docListIter.Content_Document_Id__c)=='PDF'?true:false;
            
            if(docListIter.Is_Required__c == true){
                docCheck.requiredDoc = true;
            }else{
                docCheck.requiredDoc = false;
            }
            if(objectName=='Application_Verification__c'){
                docCheck.recordId=docListIter.Application_Verification__c;
                docCheck.lat=docListIter.Application_Verification__r.Geo_coordinates__Latitude__s;
                docCheck.longitude=docListIter.Application_Verification__r.Geo_coordinates__Longitude__s;
            }
            
            docCheckList.add(docCheck);
        }
        
        System.debug('docCheckList -->' + docCheckList);
        return docCheckList;
    }
    
    // Used for Remarks capture cmp
    @AuraEnabled
    public static string getFormattedRemarks(string newRemarks, string existingRemarks) {
        
        //String newEntry = UserInfo.getName() +' - '+ System.now().format('yyyy-MM-dd, HH:mm:ss')+': '+ newRemarks;//newRemarks + '-' + UserInfo.getName() +' - '+ System.now().format('yyyy-MM-dd, HH:mm:ss');
        String newEntry = newRemarks +' - '+ System.now().format('yyyy-MM-dd, HH:mm:ss')+': '+ UserInfo.getName();//newRemarks + '-' + UserInfo.getName() +' - '+ System.now().format('yyyy-MM-dd, HH:mm:ss');
        System.debug('newEntry=:'+newEntry);
        System.debug('existingRemarks=:'+existingRemarks);
        if(String.isNotBlank(existingRemarks)) {
            return newEntry +'<br>'+ existingRemarks;
        }
        else{
            return newEntry;
        }
    }
    
    
    public class DocWrapper{
        @AuraEnabled public String docId;
        @AuraEnabled public String name;
        @AuraEnabled public Boolean isUploaded;
        @AuraEnabled public Boolean requiredDoc;
        @AuraEnabled public String imageUrl;
        @AuraEnabled public String contentId;
        @AuraEnabled public String recordId;
        @AuraEnabled public decimal lat;
        @AuraEnabled public decimal longitude;
        @AuraEnabled public boolean isPDF;
    }
    // Wrapper class to hold customer details
    public class CustomerDetails {
        @AuraEnabled  public String firstName;
        @AuraEnabled  public String lastName;
        @AuraEnabled public String nationality;
        @AuraEnabled public String product;
        @AuraEnabled public String mobileNumber;
        @AuraEnabled public String pinCode;
        @AuraEnabled public Date dob;
        @AuraEnabled public String email;
        @AuraEnabled public String panNumber;
        @AuraEnabled public String loanAmount;
        @AuraEnabled public String businessIndustry;
        @AuraEnabled public Decimal businessVintage;
        @AuraEnabled public String addreeDetails;
        @AuraEnabled public String custType;
        @AuraEnabled public String nameOfOrganization;
        @AuraEnabled public Date dateOfIncorporation;
        @AuraEnabled public String mobileNumberMasked;
        @AuraEnabled public String customerProfile;
        @AuraEnabled public String consentStatus;
        @AuraEnabled public String applicantType;
        @AuraEnabled public Boolean isNonIndividual= false;
        @AuraEnabled public Boolean isSenpCustomer = false;
        @AuraEnabled public String insuranceRequirement;
        @AuraEnabled public List<String> insuranceProducts;
    }

        //to delete shared record
        @AuraEnabled
        public static void deleteSharedRecord(Map<String, String> sharingParams) {
            try {
                if (!sharingParams.containsKey('objectName') || 
                    !sharingParams.containsKey('recordId') || 
                    !sharingParams.containsKey('userId')) {
                    throw new IllegalArgumentException('Required keys: objectName, recordId, userId');
                }
                String objectName = sharingParams.get('objectName');
                String recordId = sharingParams.get('recordId');
                String userId = sharingParams.get('userId');
                String query = 'SELECT Id FROM ' + objectName + 
                               ' WHERE ParentId = :recordId AND UserOrGroupId = :userId';
                List<SObject> sharingRecords = Database.query(query);
                if (!sharingRecords.isEmpty()) {
                    delete sharingRecords;
                }
            } catch (Exception e) {
                throw new AuraHandledException('Error deleting shared record: ' + e.getMessage());
            }
        }
    
    
    
//     /**
// * Method to fetch customer details based on recordId
// * @param recordId - Id of the Application_Applicant__c record
// * @return CustomerDetails - Populated wrapper object
// */
    //to get customer details based on recordId
     @AuraEnabled
    public static CustomerDetails getCustomerDetails(String recordId) {
        // Query the Application_Applicant__c object and related fields
        Application_Applicant__c applicant =
        [SELECT First_Name__c,Last_Name__c,Mobile_Number__c,Mobile_Number_Masked__c,DOB__c,PAN_Number__c,Email__c,Loan_Application__r.Requested_Amount__c,Name_of_Organization__c,
        Loan_Application__r.Product__c,Industry__c,Business_Vintage__c,Customer_Type__c,DOI__c,Customer_Profile__c,Type_of_Insurance__c,Insurance_Requirement__c,
        Loan_Application__r.Consent_Status__c,Loan_Application__r.Pincode__r.Name FROM Application_Applicant__c WHERE Id = :recordId LIMIT 1];
        List<Applicant_Address__c> appAddresses = [Select id,Full_Address__c from Applicant_Address__c where Applicant__c=: recordId AND Address_Type__c ='Permanent' LIMIT 1];
        // Map the queried fields to the wrapper object
        CustomerDetails customerDetails = new CustomerDetails();
        customerDetails.firstName = applicant.First_Name__c;
        customerDetails.lastName = applicant.Last_Name__c;
        customerDetails.nationality = 'Indian'; // Hardcoded as per the given structure
        customerDetails.product = applicant.Loan_Application__r.Product__c;
        customerDetails.mobileNumber = applicant.Mobile_Number__c;
        customerDetails.mobileNumberMasked = applicant.Mobile_Number_Masked__c;
        customerDetails.pinCode = applicant.Loan_Application__r.Pincode__r.Name;
        customerDetails.dob = applicant.DOB__c;
        customerDetails.email = applicant.Email__c;
        customerDetails.panNumber = applicant.PAN_Number__c;
        customerDetails.custType = applicant.Customer_Type__c;
        customerDetails.loanAmount = applicant.Loan_Application__r.Requested_Amount__c != null ? String.valueOf(applicant.Loan_Application__r.Requested_Amount__c) : null;
        if(applicant.Customer_Profile__c == 'SENP'){
            customerDetails.businessIndustry = applicant.Industry__c;
        }
        customerDetails.customerProfile = applicant.Customer_Profile__c;
        customerDetails.businessVintage = applicant.Business_Vintage__c;
        customerDetails.nameOfOrganization = applicant.Name_of_Organization__c;
        customerDetails.dateOfIncorporation = applicant.DOI__c;
        customerDetails.consentStatus = applicant.Loan_Application__r.Consent_Status__c;
        customerDetails.insuranceRequirement = applicant.Insurance_Requirement__c;
        // if(appAddresses!=null){
        if(!appAddresses.isEmpty()){
            customerDetails.addreeDetails= appAddresses[0].Full_Address__c;
        
        }
        if (applicant.Type_of_Insurance__c != null) {
    List<String> vasCodes = applicant.Type_of_Insurance__c.split(';');
    Set<String> vasDescriptionsSet = new Set<String>();

    for (Charges_Insurance_Master__c cim : [
        SELECT VAS_Description__c 
        FROM Charges_Insurance_Master__c 
        WHERE VAS_Code__c IN :vasCodes
    ]) {
        if (cim.VAS_Description__c != null) {
            vasDescriptionsSet.add(cim.VAS_Description__c);
        }
    }

    customerDetails.insuranceProducts = new List<String>(vasDescriptionsSet);
                }else{
                    List<String> defaultList = new List<String>();
    defaultList.add('NA');
    customerDetails.insuranceProducts = defaultList;
}

      
        return customerDetails;
    }

    @AuraEnabled
    public static List<CustomerDetails> getCustomerDetailsFromLoan( String loanId){
        List<CustomerDetails> applicantsInformation= new List<CustomerDetails>();
        try {
            List<Application_Applicant__c> applicantList =[SELECT Id,First_Name__c,Applicant_Type__c,Pincode__c,Pincode__r.Name,Last_Name__c,Mobile_Number__c,Mobile_Number_Masked__c,DOB__c,PAN_Number__c,Email__c,Loan_Application__r.Requested_Amount__c,Name_of_Organization__c,
                    Loan_Application__r.Product__c,Industry__c,Business_Vintage__c,Customer_Type__c,DOI__c,Customer_Profile__c,Insurance_Requirement__c,Type_of_Insurance__c,
                    Loan_Application__r.Consent_Status__c,Loan_Application__r.Pincode__r.Name FROM Application_Applicant__c WHERE Loan_Application__c = :loanId ORDER BY CreatedDate ASC];
            List<Applicant_Address__c> appAddresses = [SELECT id,Full_Address__c,Applicant__c  FROM Applicant_Address__c WHERE Applicant__c IN  :applicantList AND Address_Type__c ='Permanent'];
            Map<String, String> applicantAddressMap= new Map<String, String>();

            for(Applicant_Address__c address: appAddresses){
                applicantAddressMap.put(address.Applicant__c, address.Full_Address__c);  
            }

            for(Application_Applicant__c applicant: applicantList){
                CustomerDetails customerDetails = new CustomerDetails();
                customerDetails.firstName = applicant.First_Name__c;
                customerDetails.lastName = applicant.Last_Name__c;
                customerDetails.nationality = 'Indian'; // Hardcoded as per the given structure
                customerDetails.product = applicant.Loan_Application__r.Product__c;
                customerDetails.applicantType = applicant.Applicant_Type__c;
                customerDetails.mobileNumber = applicant.Mobile_Number__c;
                customerDetails.mobileNumberMasked = applicant.Mobile_Number_Masked__c;
                if(applicant.Applicant_Type__c== 'Primary Applicant'){
                    customerDetails.pinCode = applicant.Loan_Application__r.Pincode__r.Name;
                }else if(applicant.Applicant_Type__c!= 'Primary Applicant'){
                    customerDetails.pinCode = applicant.Pincode__c != null ? applicant.Pincode__r.Name : '';
                }
                customerDetails.dob = applicant.DOB__c;
                customerDetails.email = applicant.Email__c;
                customerDetails.panNumber = applicant.PAN_Number__c;
                customerDetails.custType = applicant.Customer_Type__c;
                customerDetails.isNonIndividual = applicant.Customer_Type__c == 'Individual' ? false : true;
                customerDetails.loanAmount = applicant.Loan_Application__r.Requested_Amount__c != null ? String.valueOf(applicant.Loan_Application__r.Requested_Amount__c) : null;
                if(applicant.Customer_Profile__c == 'SENP'){
                    customerDetails.businessIndustry = applicant.Industry__c;
                    customerDetails.isSenpCustomer = true;
                }
                customerDetails.customerProfile = applicant.Customer_Profile__c;
                customerDetails.businessVintage = applicant.Business_Vintage__c;
                customerDetails.nameOfOrganization = applicant.Name_of_Organization__c;
                customerDetails.dateOfIncorporation = applicant.DOI__c;
                customerDetails.consentStatus = applicant.Loan_Application__r.Consent_Status__c;
                if(applicantAddressMap.containsKey(applicant.Id)){
                    customerDetails.addreeDetails = applicantAddressMap.get(applicant.Id);
                }
                customerDetails.insuranceRequirement = applicant.Insurance_Requirement__c;
                 if (applicant.Type_of_Insurance__c != null) {
    List<String> vasCodes = applicant.Type_of_Insurance__c.split(';');
    Set<String> vasDescriptionsSet = new Set<String>();

    for (Charges_Insurance_Master__c cim : [
        SELECT VAS_Description__c 
        FROM Charges_Insurance_Master__c 
        WHERE VAS_Code__c IN :vasCodes
    ]) {
        if (cim.VAS_Description__c != null) {
            vasDescriptionsSet.add(cim.VAS_Description__c);
        }
    }

    customerDetails.insuranceProducts = new List<String>(vasDescriptionsSet);
                }else{
                    List<String> defaultList = new List<String>();
    defaultList.add('NA');
    customerDetails.insuranceProducts = defaultList;
                }
                
                applicantsInformation.add(customerDetails);
            }
        } catch (Exception e) {
            // throw new AuraHandledException(e.getMessage());
        }
        return applicantsInformation;
    }
	
    public static string  getAccessToken() {
        Integration_Settings__c intDetails = [SELECT Client_Id__c,Cookie__c, Client_Secret__c, Endpoint__c, Content_Type__c, Authorization__c,Request_Method__c
        FROM Integration_Settings__c WHERE Name ='Get Token' Limit 1];

                HttpRequest req = new HttpRequest();
                req.setMethod(intDetails.Request_Method__c);
                string endpoint = intDetails.EndPoint__c;
                String body = 'grant_type=client_credentials' +
                      '&client_id=f9709782-85ea-49fc-848a-6abcbfa65611' + 
                      '&client_secret=REDACTED_CLIENT_SECRET';


                req.setBody(body);
              

                req.setEndpoint(endpoint);
                req.setTimeout(60000);
                Http http = new Http();
                HttpResponse res = http.send(req);
                System.debug('Response Body: ' + res.getBody());
                // Check if the response is successful
                if (res.getStatusCode() == 200) {
                    // Parse the response JSON
                    OAuthResponseWrapper oauthResponse = (OAuthResponseWrapper) JSON.deserialize(res.getBody(), OAuthResponseWrapper.class);
        
                    // Return the access token
                    return oauthResponse.access_token;
                   
                }
                else {
                    // Handle error response
                     return '';
                }
              

    }

    public class OAuthResponseWrapper {
        public String token_type;
        public Integer expires_in;
        public Integer ext_expires_in;
        public Integer expires_on;
        public Integer not_before;
        public String resource;
        public String access_token;
    }
    public static List<Integration_Details__c> getIntegrationRecordsForCreditAPIs( String loanId, String apiName){
        List<Integration_Details__c> integrationRecords = [SELECT Id, Response_JSON__c, Request_JSON__c, Related_Record_Id__c FROM Integration_Details__c WHERE Loan_Application__c = :loanId AND Name = :apiName ];
        return integrationRecords;
    }
    public static String getPDParentRecord(String loanId) {
        String parentRecId = '';
        String pdRecordType = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Personal_Discussion');
        List<Application_Verification__c> parentRec = [SELECT id FROM Application_Verification__c WHERE Loan_Application__c =: loanId AND
                                                      recordTypeId =: pdRecordType AND IsParent__c = true];
        if(parentRec.size() > 0) {
            parentRecId =  parentRec[0].id;
        }else {
            Application_Verification__c parentPd = new Application_Verification__c();
            parentPd.RecordTypeId = pdRecordType;
            parentPd.IsParent__c = true;
            parentPd.Loan_Application__c = loanId;
            insert parentPd;
            parentRecId = parentPd.id;
        }
        return parentRecId;
    }

    @AuraEnabled
    public static void insertTATRecords(String code, String loanId) {
        try {
            List<TAT__c> tatRecordList = new List<TAT__c>();
            List<TAT_Master__mdt> metadataList = [SELECT Stage__c, Activity__c, Sub_Activity__c FROM TAT_Master__mdt WHERE Code__c = :code and Is_Active__c = true];

            List<TAT__c> existingTatRecords= [SELECT Id, End_Timestamp__c, Activity__c FROM TAT__c WHERE Loan_Application__c = :loanId AND End_Timestamp__c = null  AND Activity__c!= 'Sub Stage Change'];

            if(metadataList.size() > 0){
                if(existingTatRecords.size()>0){
                    for(TAT__c tat: existingTatRecords){
                        if(tat.Activity__c==  metadataList[0].Activity__c){
                            tat.End_Timestamp__c = System.now();
                            tatRecordList.add(tat);
                        }
                    }
                }
                TAT__c tatRecord = new TAT__c();
                tatRecord.Stage__c = metadataList[0].Stage__c;
                tatRecord.Activity__c = metadataList[0].Activity__c;
                tatRecord.Sub_Activity__c = metadataList[0].Sub_Activity__c;
                tatRecord.User_Name__c = UserInfo.getUserId();
                tatRecord.Timestamp__c = System.now();
                tatRecord.Loan_Application__c = loanId;
                tatRecord.Code__c = code;
                tatRecordList.add(tatRecord);
            }
            if(tatRecordList.size() > 0){
                upsert tatRecordList;
            }
        }
        catch (Exception e) {
            system.debug('Error: ' + e);
            system.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
        }
    }

    public static Decimal truncateTwoZeros(Decimal inputNumber) {
        // Divide the number by 100 to remove the last two zeros
        return inputNumber / 100;
    }

    // Method to add two zeros to the number
    public static Decimal addTwoZeros(Decimal inputNumber) {
        // Multiply the number by 100 to add two zeros
        return inputNumber * 100;
    }
   /**
    * @description This is used to encrypt string based on given key.
    */
    public static string getEncryptedBase64String(String value){
        string result = '';
        
        if(string.isNotBlank(value)){
            try{
                Blob exampleIv = Blob.valueOf(constantsMeta.get('IV_Key')); 
                Blob key = Blob.valueOf(constantsMeta.get('Encryption_Key'));
                Blob data = Blob.valueOf(value);
                Blob encrypted = Crypto.encrypt(constantsMeta.get('AES_Algorithm'), key, exampleIv, data);
                result = EncodingUtil.Base64Encode(encrypted);
            }
            catch(Exception e){
                //system.debug('Error: ' + e);
                //system.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
            }
        }
        
        return result;
    }

    /**
    * @description This is used to decrypt the encrypted string.
    */
    public static string getDecryptedBase64String(String value){
        string result = '';

        if(string.isNotBlank(value)){
            try{
                Blob key = Blob.valueOf(constantsMeta.get('Encryption_Key'));
                Blob exampleIv = Blob.valueOf(constantsMeta.get('IV_Key')); 
                Blob dest = EncodingUtil.base64Decode(value);
                Blob decrypted = Crypto.decrypt(constantsMeta.get('AES_Algorithm'), key, exampleIv, dest);
                result = decrypted.toString();

                //system.debug('Data to be decrypted : '+ result);
            }
            catch(Exception e){
                //system.debug('Error: ' + e);
                //system.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
            }
        }
        return result;
    } 
    @AuraEnabled
    public static String getObjectNameFromId(Id recordId) {
        String keyPrefix =String.valueOf(recordId).substring(0,3);
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for (String objectName : globalDescribe.keySet()) {
            if (globalDescribe.get(objectName).getDescribe().getKeyPrefix() == keyPrefix) {
                return objectName;
            }
        }
        return null; // Return null if no matching object is found
    }
       public static Map<String, Boolean> checkDataFilledOrNot(Set<String> formNames, Id applicantId) {
        Map<String, Boolean> resultMap = new Map<String, Boolean>();
        try {
            String objectName = getObjectNameFromId(applicantId);
            if (objectName == null) {
                throw new AuraHandledException('Invalid ID or object not found.');
            }
    
            // Query the mandatory fields for the given form names
            List<Screen_Field__c> screenFields = [SELECT Storage_Field__c, Parent_Screen__r.Form_Name__c 
                                                  FROM Screen_Field__c 
                                                  WHERE Is_Active__c = true 
                                                    AND Is_Mandatory__c = true 
                                                    AND Parent_Screen__r.Is_Screen_Active__c = true 
                                                    AND Parent_Screen__r.Form_Name__c IN :formNames 
                                                  ORDER BY Field_Sequence__c ASC];
            
            // Group the fields by form name
            Map<String, Set<String>> formFieldMap = new Map<String, Set<String>>();
            Set<String> uniqueFields = new Set<String>();
            for (Screen_Field__c field : screenFields) {
                String formName = field.Parent_Screen__r.Form_Name__c;
                String fieldName = field.Storage_Field__c;
                if (!formFieldMap.containsKey(formName)) {
                    formFieldMap.put(formName, new Set<String>());
                }
                formFieldMap.get(formName).add(fieldName);
                uniqueFields.add(fieldName);
            }
            // Build the dynamic query
            String query = 'SELECT Id';
            for (String fieldName : uniqueFields) {
                query += ', ' + fieldName;
            }
            query += ' FROM ' + objectName + ' WHERE Id = :applicantId LIMIT 1';
            System.debug('query : ' + query);
            // Execute the dynamic query
            SObject applicant = Database.query(query);
            // Check if all mandatory fields are filled
            for (String formName : formFieldMap.keySet()) {
                Boolean allFieldsFilled = true;
                for (String fieldName : formFieldMap.get(formName)) {
                    Object fieldValue = applicant.get(fieldName);
                    System.debug('applicant : fieldName : ' + fieldValue);
                    if (fieldValue == null) {
                        allFieldsFilled = false;
                        break;
                    }
                }
                resultMap.put(formName, allFieldsFilled);
                System.debug('resultMap ' + resultMap);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return resultMap;
    }

    @AuraEnabled
    public static Map<String, Map<String, String>> getDependentPicklistValues(String fieldName) {
        System.debug('Inside getDependentPicklistValues');
        Schema.DescribeFieldResult depend;
        if(fieldName == 'caseType') {
            depend  = Case.Case_Type__c.getDescribe();
        }else if(fieldName == 'constitution') {
            depend  = Application_Applicant__c.Sector__c.getDescribe();
        }

        Schema.sObjectField controlToken = depend.getController();
        if (controlToken == null) {
            return new Map<String, Map<String, String>>();
        }
        
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries;
        if(control.getType() != Schema.DisplayType.Boolean) {
            controlEntries = control.getPicklistValues();
        }
        
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<String, Map<String, String>> dependentPicklistValues = new Map<String, Map<String, String>>();
        for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
            if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
                List<String> base64chars =
                    String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    Object controlValue =
                        (controlEntries == null
                         ?   (Object) (index == 1)
                         :   (Object) (controlEntries[index].isActive() ? controlEntries[index].getLabel() : null)
                        );
                    Integer bitIndex = index / 6;
                    if (bitIndex > base64chars.size() - 1) {
                        break;
                    }
                    Integer bitShift = 5 - Math.mod(index, 6);
                    if (controlValue == null || (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0)
                        continue;
                    if (!dependentPicklistValues.containsKey(controlEntries[index].getLabel())) {
                        dependentPicklistValues.put(controlEntries[index].getLabel(), new Map<String, String>());
                    }
                    
                    dependentPicklistValues.get(controlEntries[index].getLabel()).put(entry.getLabel(), entry.getValue());
                }
            }
        }
        System.debug('Inside dependentPicklistValues : '+ dependentPicklistValues);
        return dependentPicklistValues;
    }

    //fetching loan stage
	@AuraEnabled
    public static String getLoanStage(String loanId) {
        List<Opportunity> oppRecords = [SELECT Id, Name, StageName FROM Opportunity WHERE Id =: loanId];
        return oppRecords.get(0).StageName;
    }

    @AuraEnabled
    public static String getLoanSubStage(String loanId) {
        List<Opportunity> oppRecords = [SELECT Id, Name, StageName, Sub_stage__c FROM Opportunity WHERE Id =: loanId];
        return oppRecords.get(0).Sub_stage__c;
    }

    @AuraEnabled
    public static Boolean checkUserHavePsFcuSamplerPermissionSet() {
        List<PermissionSetAssignment> permissionSetAssignmentRecord = [SELECT Id, PermissionSet.Name, AssigneeId
                                                                       FROM PermissionSetAssignment
                                                                       WHERE PermissionSet.Name = 'PS_FCU_Sampler' AND AssigneeId =: UserInfo.getUserId()];
        return !permissionSetAssignmentRecord.isEmpty();
    }
    // Below method is used to check PS_Cross_sell_Sales_Executive permission set assigned to user or not
    @AuraEnabled
    public static Boolean checkUserHavePsCrossSellTeamPermissionSet() {
        List<PermissionSetAssignment> permissionSetAssignmentRecord = [SELECT Id, PermissionSet.Name, AssigneeId
                                                                       FROM PermissionSetAssignment
                                                                       WHERE PermissionSet.Name = 'PS_Cross_sell_Sales_Executive' AND AssigneeId =: UserInfo.getUserId()];
        return !permissionSetAssignmentRecord.isEmpty();
    }
    // Above Method is for Cross Sell Sales Executive Permission Set Check
    @AuraEnabled
    public static Integer getVendorInvoiceNextNumber(string recordType){

        integer seqNo = 1;
        for(Vendor_Invoice__c rec : [SELECT Name FROM Vendor_Invoice__c WHERE RecordType.Name =: recordType AND Existing_Invoice_No__c = null Order By Name Desc Limit 1]){
            List<string> recName = rec.Name.split('-');
            if(!recName.isEmpty() && recName.size() >1){
                seqNo = Integer.valueOf(recName[1]) + 1;
                break;
            }
        }

        System.debug('recordType: '+recordType +' new Seq: '+seqNo);
        return seqNo;
    }
    @AuraEnabled
    public static void addOppTeamMember(Id opportunityId, Id userId, String teamMemberRole, String opportunityAccessLevel) {
    try {
        OpportunityTeamMember otm = new OpportunityTeamMember(
            OpportunityId = opportunityId,         
            UserId = userId,                       
            TeamMemberRole = teamMemberRole,       
            OpportunityAccessLevel = opportunityAccessLevel 
        );

        insert otm;

        System.debug('Opportunity Team Member added successfully for Opportunity: ' + opportunityId);
        
    } catch (Exception e) {

        throw new AuraHandledException('Error adding Opportunity Team Member: ' + e.getMessage());
    }
}
@AuraEnabled
    public static String getCurrentUserProfileName1(){
        String profileName = '';
        Id profileId=userinfo.getProfileId();
        String profileNameStr=[Select Id,Name from Profile where Id=:profileId].Name;
        if(profileNameStr == 'System Administrator') {
                profileName = 'admin';
                return 'Admin';
            }
        for(PermissionSetAssignment iter :[SELECT Id, PermissionSet.Name, PermissionSet.ProfileId, PermissionSet.Profile.Name, AssigneeId, Assignee.Name FROM PermissionSetAssignment WHERE Assignee.id=: UserInfo.getUserId()]){
           
            if(iter.PermissionSet.Name == 'PS_FCU_Admin') {
                profileName = 'FCU Admin';
                return 'FCU Admin';
            }
            if(iter.PermissionSet.Name == 'PS_FCU_Executive') {
                profileName = 'FCU Executive';
                return 'FCU Executive';
            }
            if(iter.PermissionSet.Name == 'PS_Credit_Manager') {
                profileName = 'Credit Manager';
                return 'Credit Manager';
            }
           if(iter.PermissionSet.Name == 'PS_FI_Executive') {
                profileName = 'FI';
                return 'FI';
            } 
            if(iter.PermissionSet.Name == 'PS_FCU_Sampler' || iter.PermissionSet.Name == 'PS_FCU_Sampler_Head') {
                profileName = 'Sampler';
                return 'Sampler';
            }
        }
        return profileName;
}

    @AuraEnabled
    public static void saveTriangulationDataManual(String docName, String fieldAPIName, Id appId, String currentValue, Id loanId) {
        List<Triangulation_Data_Save_Manual__mdt> triangulationManualMtds = [SELECT Id, Document_in_triangulation__c, Field_in_triangulation__c 
                                                                            FROM Triangulation_Data_Save_Manual__mdt WHERE Document_Name__c = :docName AND Field_Name__c = :fieldAPIName LIMIT 1];
        System.debug('triangulationManualMtds: ' + triangulationManualMtds);
        String source = 'Manual';
        if (!triangulationManualMtds.isEmpty()) {
            Triangulation_Data_Save_Manual__mdt mdt = triangulationManualMtds[0];
            String query = 'SELECT Id';
            
            if (mdt.Field_in_triangulation__c != null) {
                query += ', ' + mdt.Field_in_triangulation__c;
            }
            
            query += ' FROM Triangulation_Data__c WHERE Loan_Application__c = \'' + loanId + '\'';
            query += ' AND Application_Applicant__c = \'' + appId + '\'';
            
            if (mdt.Document_in_triangulation__c != null) {
                query += ' AND Document_Type__c = \'' + String.escapeSingleQuotes(mdt.Document_in_triangulation__c) + '\'';
            }

            query += ' AND Source_Type__c =:source LIMIT 1';
            
            System.debug('query--> saveTriangulationDataManual: ' + query);
            
            List<Triangulation_Data__c> triangulationDatas = Database.query(query);
            System.debug('triangulationDatas: ' + triangulationDatas);
            
            Triangulation_Data__c data;
            if (!triangulationDatas.isEmpty()) {
                data = triangulationDatas[0];
            } else {
                data = new Triangulation_Data__c(
                    Application_Applicant__c = appId,
                    Loan_Application__c = loanId,
                    Document_Type__c = mdt.Document_in_triangulation__c,
                    Source_Type__c = 'Manual'
                );
            }

            if (mdt.Field_in_triangulation__c != null) {
                data.put(mdt.Field_in_triangulation__c, currentValue);
            }

            if (data.Id != null) {
                update data;
            } else {
                insert data;
            }
        }
    }

    @AuraEnabled
    public static void updateTriangulationManualAddressData (String applicantId, String formIdentifier, String docId) {
        List<Application_Applicant__c> apps = [SELECT Id, Loan_Application__c FROM Application_Applicant__c WHERE Id =: applicantId LIMIT 1];
        String loanApp = apps[0].Loan_Application__c;
        String address = '';
        List<Applicant_Address__c> existingAddress = [SELECT Id, Address_Source__c, Document_Details__r.Document_Master__r.Name,Address_Type__c, Address_Line_1__c, 
                                                        Address_Line_2__c, Address_Line_3__c, Pincode__c FROM Applicant_Address__c WHERE Applicant__c = :applicantId 
                                                        AND Document_Details__r.Document_Master__r.Name = :formIdentifier AND Document_Details__c = :docId
                                                        ORDER BY CreatedDate DESC LIMIT 1];
        if(!existingAddress.isEmpty()) {
            if(existingAddress[0].Address_Line_1__c != null){
                address = existingAddress[0].Address_Line_1__c;
            }
            if(existingAddress[0].Address_Line_2__c != null){
                if(address != '') {
                    address = address+', '+existingAddress[0].Address_Line_2__c;
                } else {
                    address = existingAddress[0].Address_Line_2__c;
                }
            }
            if(existingAddress[0].Address_Line_3__c != null){
                if(address != '') {
                    address = address+', '+existingAddress[0].Address_Line_3__c;
                } else {
                    address = existingAddress[0].Address_Line_3__c;
                }
            }
            if(existingAddress[0].Pincode__c != null){
                    if(address != '') {
                    address = address+', '+existingAddress[0].Pincode__c;
                    } else {
                    address = existingAddress[0].Pincode__c;
                }
            }
            List<Triangulation_Data_Save_Manual__mdt> triangulationManualMtds = [SELECT Id, Document_in_triangulation__c FROM Triangulation_Data_Save_Manual__mdt WHERE Document_Name__c = :formIdentifier LIMIT 1];
            if(!triangulationManualMtds.isEmpty()) {
                Triangulation_Data_Save_Manual__mdt triangulationManualMtd = triangulationManualMtds[0];
                if(triangulationManualMtd.Document_in_triangulation__c != null){
                    List<Triangulation_Data__c> triangulationData = [SELECT Id, Address__c FROM Triangulation_Data__c WHERE Loan_Application__c = :loanApp AND Application_Applicant__c = :applicantId 
                                                                        AND Document_Type__c =:triangulationManualMtd.Document_in_triangulation__c AND Source_Type__c = 'Manual'];
                    if(!triangulationData.isEmpty()) {
                        Triangulation_Data__c data = triangulationData[0];
                        data.Address__c = address;
                        update data;
                    } else {
                        Triangulation_Data__c data = new Triangulation_Data__c(
                            Application_Applicant__c = applicantId,
                            Loan_Application__c = loanApp,
                            Document_Type__c = triangulationManualMtd.Document_in_triangulation__c,
                            Source_Type__c = 'Manual'
                        );
                        insert data;
                    }
                }
            }
        }
    }
    @AuraEnabled
    public static String savePDF(String loanId , String docName) {
        Savepoint sp = Database.setSavepoint();

        try {
            Document_Details__c existingDoc;
            opportunity loan = [Select id , name FROM opportunity WHERE id =: loanId LIMIT 1];
            List<Document_Details__c> existingDocs = [
                SELECT Id, Name, Version_Number__c, Content_Document_Id__c, Active__c,Loan_Application__r.name
                FROM Document_Details__c
                WHERE Loan_Application__c = :loanId
                AND Name =: docName
                AND Active__c = true
                LIMIT 1
            ];

            Document_Details__c newDoc;
            if (!existingDocs.isEmpty()) {
                existingDoc = existingDocs[0];
                newDoc = existingDoc.clone(false);
                newDoc.Content_Document_Id__c = null;
                newDoc.Version_Number__c = (existingDoc.Version_Number__c == null ? 2 : existingDoc.Version_Number__c + 1);
                newDoc.Description__c = 'Auto-generated ' + docName + ' PDF';
                insert newDoc;

                existingDoc.Active__c = false;
                existingDoc.Document_Details_Lookup__c = newDoc.Id;
                update existingDoc;
            } else {
                newDoc = new Document_Details__c(
                    Loan_Application__c = loanId,
                    Name = loan.name + '_' +docName + 'PDF',
                    Description__c = 'Auto-generated ' + docName + ' PDF',
                    Version_Number__c = 1,
                    Active__c = true
                );
                insert newDoc;
            }

            // Step 3: Generate PDF from VF page
            PageReference pdfPage = Page.DisbursmentMemo;
            pdfPage.getParameters().put('Id', loanId);
            pdfPage.setRedirect(true);
            Blob pdfBlob = pdfPage.getContentAsPDF();

            // Step 4: Create ContentVersion (upload PDF)
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = docName + '_' + System.now().getTime();
            contentVersion.PathOnClient = docName + '.pdf';
            contentVersion.VersionData = pdfBlob;
            contentVersion.FirstPublishLocationId = newDoc.Id;
            insert contentVersion;

            // Step 5: Link content version to loan and update document detail
            ContentVersion insertedCV = [SELECT ContentDocumentId, FileType FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];

            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = loanId;
            cdl.ContentDocumentId = insertedCV.ContentDocumentId;
            cdl.ShareType = 'I';
            cdl.Visibility = 'AllUsers';
            insert cdl;

            newDoc.Content_Document_Id__c = insertedCV.ContentDocumentId;
            newDoc.Status__c = 'Uploaded';
            update newDoc;

            return 'Disbursement Memo PDF generated and uploaded successfully.';
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Failed to generate Disbursement Memo: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean getComponentEditability(String loanId, String component) {
        String currentUserProfile = getCurrentUserProfileName();
        Boolean isDisable = false;
        String loanStage;
        String loanSubStage;
        Set<String> excludedSubStages = new Set<String>();

        if (!String.isBlank(Label.Disabled_Sub_Stages)) {
            excludedSubStages.addAll(Label.Disabled_Sub_Stages.split(';'));
        }
        System.debug('excludedSubStages : ' + excludedSubStages);

        List<Opportunity> loanApp = [
                                    SELECT Id, StageName, Sub_stage__c 
                                     FROM Opportunity
                                     WHERE Id = :loanId 
                                     AND Sub_stage__c NOT IN :excludedSubStages 
                                    LIMIT 1
                                    ];
        System.debug('loanApp List : ' + loanApp);

        if (!loanApp.isEmpty()) {
            loanStage   = loanApp[0].StageName;
            loanSubStage = loanApp[0].Sub_stage__c;
        } else {
            isDisable = true;
        }

        System.debug('component :' + component);
        System.debug('loanStage :' + loanStage);
        System.debug('loanSubStage :' + loanSubStage);
        System.debug('currentUserProfile : ' + currentUserProfile);

        Boolean hasPerm = FeatureManagement.checkPermission('CP_FCU_Sampler');

        /*if (!String.isBlank(component) && !String.isBlank(loanStage) && !String.isBlank(loanSubStage)) {

            List<Component_Editability__mdt> editabilityRecords = new List<Component_Editability__mdt>();
            editabilityRecords = [
                SELECT Id, Is_Editable__c
                FROM Component_Editability__mdt
                WHERE Loan_Stage__c     = :loanStage
                AND Loan_Sub_Stage__c = :loanSubStage
                AND User_Profile__c   = :currentUserProfile
                AND Component_Name__c = :component
                LIMIT 1
            ];
            if (editabilityRecords.isEmpty() && hasPerm) {
                editabilityRecords = [
                    SELECT Id, Is_Editable__c
                    FROM Component_Editability__mdt
                    WHERE Loan_Stage__c     = :loanStage
                    AND Loan_Sub_Stage__c = :loanSubStage
                    AND Custom_Permission__c = 'CP_FCU_Sampler'
                    AND Component_Name__c = :component
                    LIMIT 1
                ];
            }
            if (!editabilityRecords.isEmpty() && isDisable != true) {
                if (editabilityRecords[0].Is_Editable__c == true) {
                    isDisable = false;
                } else {
                    isDisable = true;
                }
            }
        }*/

        return isDisable;
    }
    

    @AuraEnabled
    public static String getLoanStageFromApplicant(String appId) {
        List<Opportunity> appRecords = [SELECT StageName FROM Opportunity WHERE Id =: appId];
        if (appRecords.isEmpty()) {
            List<Application_Applicant__c> appStage = [SELECT Id, Loan_Application__r.StageName FROM Application_Applicant__c WHERE Id =: appId];
            return appStage.get(0).Loan_Application__r.StageName;
        }
        return appRecords.get(0).StageName;
    }
    

    /*@AuraEnabled
    public static Boolean getComponentEditability(String loanId, String component) {
        String currentUserProfile = getCurrentUserProfileName();
        Boolean isDisable = false;
        String loanStage;
        String loanSubStage;
        Set<String> excludedSubStages = new Set<String>();

        if (!String.isBlank(Label.Disabled_Sub_Stages)) {
            excludedSubStages.addAll(Label.Disabled_Sub_Stages.split(';'));
        }
        System.debug('excludedSubStages : ' + excludedSubStages);

        List<Opportunity> loanApp = [
                                    SELECT Id, StageName, Sub_stage__c 
                                     FROM Opportunity
                                     WHERE Id = :loanId 
                                     AND Sub_stage__c NOT IN :excludedSubStages 
                                    LIMIT 1
                                    ];
        System.debug('loanApp List : ' + loanApp);

        if (!loanApp.isEmpty()) {
            loanStage   = loanApp[0].StageName;
            loanSubStage = loanApp[0].Sub_stage__c;
        } else {
            isDisable = true;
        }

        System.debug('component :' + component);
        System.debug('loanStage :' + loanStage);
        System.debug('loanSubStage :' + loanSubStage);
        System.debug('currentUserProfile : ' + currentUserProfile);

        Boolean hasPerm = FeatureManagement.checkPermission('CP_FCU_Sampler');

        if (!String.isBlank(component) && !String.isBlank(loanStage) && !String.isBlank(loanSubStage)) {

            List<Component_Editability__mdt> editabilityRecords = new List<Component_Editability__mdt>();
            editabilityRecords = [
                SELECT Id, Is_Editable__c
                FROM Component_Editability__mdt
                WHERE Loan_Stage__c     = :loanStage
                AND Loan_Sub_Stage__c = :loanSubStage
                AND User_Profile__c   = :currentUserProfile
                AND Component_Name__c = :component
                LIMIT 1
            ];
            if (editabilityRecords.isEmpty() && hasPerm) {
                editabilityRecords = [
                    SELECT Id, Is_Editable__c
                    FROM Component_Editability__mdt
                    WHERE Loan_Stage__c     = :loanStage
                    AND Loan_Sub_Stage__c = :loanSubStage
                    AND Custom_Permission__c = 'CP_FCU_Sampler'
                    AND Component_Name__c = :component
                    LIMIT 1
                ];
            }
            if (!editabilityRecords.isEmpty() && isDisable != true) {
                if (editabilityRecords[0].Is_Editable__c == true) {
                    isDisable = false;
                } else {
                    isDisable = true;
                }
            }
        }

        return isDisable;
    }*/
    
    @AuraEnabled
    public static Decimal fetchCibilScore(String applicantId) {
        try {
            if (String.isBlank(applicantId)) {
                throw new AuraHandledException('Applicant ID must not be blank.');
            }
            Application_Applicant__c applicant = [SELECT CIBIL_Score__c FROM Application_Applicant__c
                WHERE Id = :applicantId LIMIT 1];
    
            return applicant.CIBIL_Score__c;
        
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching CIBIL Score: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static string fetchMobileNumber(String loanId){
        try {
            String se = '';
            List<Application_Applicant__c> app = [Select Id,Mobile_Number_Masked__c from  Application_Applicant__c WHERE Loan_Application__c = :loanId ORDER BY CreatedDate ASC Limit 1];
            if(!app.isEmpty()){
                se =  app[0].Mobile_Number_Masked__c;
            }
            return se;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
     // new added
    @AuraEnabled
    public static List<Application_Applicant__c> getAllApplicants(String loanId){
        try {
            List<Application_Applicant__c> applicants = [SELECT Id, Applicant_Name__c, Applicant_Type__c
                                                         FROM Application_Applicant__c 
                                                         WHERE Loan_Application__c =: loanId
                                                         ORDER BY Applicant_Type__c];
            return applicants;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String randomUsernameFriendly() {
        String prefix = 'user';
        String unique = String.valueOf(System.currentTimeMillis());
        Integer rand = Math.mod(Crypto.getRandomInteger(), 10000000);
        return prefix + rand + unique + '@mailexample.com';
    }

    @AuraEnabled
    public static List<Screen_Field__c> getScreenFieldsBasisComponentName(String componentName) {
        System.debug('Inside getScreenFieldsBasisComponentName for component: '+ componentName);

        if (componentName != null && componentName != '') {
            return [SELECT Id, Form_Name__c , Parent_Screen__r.Form_Name__c,Applicant_Type_Visibility__c, Name,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c, Filtered_Picklist_Values__c,
        Is_Picklist__c,Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,Section_Seperator__c,Section_Name__c,
        Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c, Read_Field_Name__c,Applicable_For__c,Picklist_Dependent_On_RecordType__c,Show_in_words__c,
        Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c,Is_Multipicklist__c,Enable_for__c
        FROM Screen_Field__c
        WHERE Is_Active__c = true AND Custom_Component_Name__c =: componentName
        order by Field_Sequence__c ASC];
        }
        System.debug('No component name passed; returning from getScreenFieldsBasisComponentName');
        return null;
    }
    
    @AuraEnabled
    public static Map<String, String> getConstantsBasisNonStaticLabels(String labels) {
        try {
            List<string> cons = labels.split(',');
            Map<string, string> constants = new Map<string, string>();
            Map<String,Constants__mdt> allMetaData = Constants__mdt.getAll();
            
            for(Constants__mdt itr : allMetaData.values()){
                if(cons.contains(itr.DeveloperName)){
                    constants.put(itr.DeveloperName, itr.Value__c);
                }
            }
            System.debug('constants=:'+constants);
            return constants;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getApprovalSataus(String loanId) {
        List<Opportunity> oppRecords = [SELECT Id, Name, Approval_Status__c FROM Opportunity WHERE Id =: loanId];
        return oppRecords.get(0).Approval_Status__c;
    }
    
    @AuraEnabled
    public static String generateRequestId() {
        String prefix = System.Label.requestIdPrefix;
        // Generate a random 9-digit number: 100000000 to 999999999
        Integer min = 100000000;
        Integer max = 999999999;
        Integer randomInt = Math.abs(Crypto.getRandomInteger());
        Integer nineDigit = min + Math.mod(randomInt, max - min + 1);
        return prefix + String.valueOf(nineDigit);
    }

     @AuraEnabled
            public static List<Application_Applicant__c> getApplicant(Id applicationCollateralId) {
               // Id applicationId = [SELECT Id,HL_Loan_Application__c FROM Application_Collateral__c];
                List<Application_Applicant__c> applicantList = new List<Application_Applicant__c>();
                
                
                    
                        applicantList = [
            SELECT Id, Name, Applicant_Type__c
            FROM Application_Applicant__c
            WHERE Loan_Application__c = '006dN00000El6rWQAR'
            ];
                
                
                return applicantList;
            }


     @AuraEnabled
    public static Map<String, Object> getFileSize(Id contentDocumentId) {
        Map<String, Object> result = new Map<String, Object>();
        
        ContentVersion cv = [
        SELECT Id, VersionData, ContentDocumentId, ContentSize
        FROM ContentVersion
        WHERE ContentDocumentId = :contentDocumentId
        ORDER BY CreatedDate DESC
        LIMIT 1
        ];
        
        result.put('size', cv.ContentSize);
        result.put('contentVersionId', cv.Id);
        result.put('base64Data', EncodingUtil.base64Encode(cv.VersionData));
        return result;
    }

    @AuraEnabled
    public static void deleteUploadedFile(Id contentDocumentId) {
        try {
            List<ContentDocument> docs = [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId LIMIT 1];
            if (!docs.isEmpty()) {
                delete docs;
            }
        } catch (Exception e) {
            System.debug('Error deleting ContentDocument: ' + e.getMessage());
            throw new AuraHandledException('Failed to delete uploaded file.');
        }
    }
    public static List<ContentVersion> getallContent(Set<Id> contentIds){
                return [SELECT Id, ContentDocumentId, VersionData, FileExtension, Title
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :contentIds
                    AND FileExtension IN ('pdf','PDF','jpg','png','jpeg','docx')
                    ORDER BY CreatedDate DESC
                ];
    }
      @AuraEnabled
        public static Map<Id, String> getLegalUsers(ID loanId, String type){ //as discussed with Kshitiz
            Map<Id, String> legalIdToAddressMap = new Map<Id, String>();
            //Set<String> userids = new Set<String>(); //set of accountteammember's user idss
            Set<Id> accountIds = new Set<Id>(); //set of accountvendors who are of legal type
            Map<Id, Integer> userLegalCountMap = new Map<Id, Integer>(); //to get the count of legal records on a single owner
            try{
                //String internalUserCheck = internalUser ==true ? 'Internal' : '';
                
                // Query to get the count of Legal__c records for each user
                List<AggregateResult> legalCounts = [SELECT OwnerId, COUNT(Id) countOfOwner
                                             FROM Legal__c
                                             WHERE Stage__c Not IN ('Not Accepted By Admin','Accepted By Credit Manager')
                                             AND  RecordTypeId !=null
                                             GROUP BY OwnerId];
                // Populate the userLegalCountMap with the counts
                for (AggregateResult ar : legalCounts) {
                    userLegalCountMap.put((Id)ar.get('OwnerId'), (Integer)ar.get('countOfOwner'));
                }
                
                String sObjName = loanId.getSObjectType().getDescribe().getName();
                if(sObjName=='Opportunity'){
                    List<Opportunity> loanList = [Select Id, Branch_Master__c, (SELECT Id,Pincode__c, Pincode__r.Name FROM Applicant_Address__r WHERE Applicant__r.Applicant_Type__c='Primary Applicant' AND Address_Type__c = 'Current' ) from Opportunity where id =: loanId];
                    
                    if(loanList.size() > 0){
                        String pincode = loanList[0].Applicant_Address__r.size()>0 ? loanList[0].Applicant_Address__r[0].Pincode__r!=null ? loanList[0].Applicant_Address__r[0].Pincode__r.Name : '' : '';
                        List<Account> accountsWithMatchingPincode = new List<Account>();
                        List<AccountTeamMember> accountTeamMemberList =  new List<AccountTeamMember>();
                        
                        accountsWithMatchingPincode = [ SELECT Id,Partner_Type__c FROM Account WHERE Partner_Type__c =:type]; //need to add Pincode logic once sufficient vendor master received
                        
                        for (Account acc : accountsWithMatchingPincode) {
                            accountIds.add(acc.Id);
                        }
                        
                        if (type == 'Legal') {
                            List<AccountTeamMember> accountTeamMembers = [
                        SELECT UserId, User.Employee_ID__c, User.Name, User.User_Type__c
                        FROM AccountTeamMember
                        WHERE TeamMemberRole = 'Legal Admin' AND Id = '01MdN000006Gv3hUAC'
                          //AND AccountId IN :accountIds
                    ];
                            for (AccountTeamMember atm : accountTeamMembers) {
                                Integer count = userLegalCountMap.get(atm.UserId) != null ? userLegalCountMap.get(atm.UserId) : 0;
                                legalIdToAddressMap.put( atm.UserId,atm.User.Employee_ID__c + '_' + atm.User.Name + '_' + atm.User.User_Type__c + ' (' + count + ')'
                                    );
                            }
                        }
                        
                        // For Technical type - decide by current user's type
                        else if (type == 'Technical') {
                            User currentUser = [
                        SELECT Id, Profile.Name
                        FROM User
                        WHERE Id = :UserInfo.getUserId()
                    ];
                            
                            String userProfile = currentUser.Profile.Name;
                            if(userprofile == 'System Administrator'){
                                List<AccountTeamMember> accountTeamMembers = [ SELECT UserId, User.Employee_ID__c, User.Name, User.User_Type__c FROM AccountTeamMember WHERE TeamMemberRole = 'Technical Admin' AND Id= '01MdN000006Gv25UAC'];
                                for (AccountTeamMember atm : accountTeamMembers) {
                                    Integer count = userLegalCountMap.get(atm.UserId) != null ? userLegalCountMap.get(atm.UserId) : 0;
                                    legalIdToAddressMap.put(
                                        atm.UserId,
                                    atm.User.Employee_ID__c + '_' + atm.User.Name + '_' + atm.User.User_Type__c + ' (' + count + ')'
                                        );
                                }
                            }
                            else {
                                List<OpportunityTeamMember> opportunityTeamMembers = [SELECT UserId, User.Employee_ID__c, User.Name, User.User_Type__c FROM OpportunityTeamMember WHERE OpportunityId = :loanId AND TeamMemberRole = 'Technical Manager'];
                                for (OpportunityTeamMember otm : opportunityTeamMembers) {
                                    Integer count = userLegalCountMap.get(otm.UserId) != null ? userLegalCountMap.get(otm.UserId) : 0;
                                    legalIdToAddressMap.put(
                                        otm.UserId,
                                    otm.User.Employee_ID__c + '_' + otm.User.Name + '_' + otm.User.User_Type__c + ' (' + count + ')'
                                        );
                                }
                            }
                        }
                        
                        
                        
                        
                        
                        // if(type == 'Legal'){
                            //   accountTeamMemberList = [SELECT TeamMemberRole, UserId, User.Employee_ID__c, User.Name, User.User_Type__c, accountId FROM AccountTeamMember where TeamMemberRole='Legal Admin' AND accountId IN : accountIds];
                        // }
                        // else if(type == 'Technical'){
                            //       accountTeamMemberList = [SELECT TeamMemberRole, UserId, User.Employee_ID__c, User.Name, User.User_Type__c, accountId FROM AccountTeamMember where TeamMemberRole='Technical Admin' AND accountId IN : accountIds];
                        // }
                        
                        // System.debug('accIds>'+accountIds);
                        // for(AccountTeamMember iterObj : accountTeamMemberList){ //(accountId = :loanList[0].Branch_Master__c OR (account.Pincode__r.Name = :pincode AND account.Partner_Type__c='FCU'))]) {
                                //     //userids.add(iterObj.UserId);
                                //     Integer count = userLegalCountMap.get(iterObj.UserId) != null ? userLegalCountMap.get(iterObj.UserId) : 0;
                                //     if(iterObj.User.User_Type__c == 'External'){
                                    //         legalIdToAddressMap.put( iterObj.UserId, iterObj.User.Employee_ID__c+'_'+iterObj.User.Name +'_'+iterObj.User.User_Type__c+ ' (' + count + ')');
                                //     }
                                //     else{
                                    //         legalIdToAddressMap.put( iterObj.UserId, iterObj.User.Employee_ID__c+'_'+iterObj.User.Name +'_'+iterObj.User.User_Type__c+ ' (' + count + ')');
                                //     }
                            // }
                        }
                    }
                    /*if(sObjName=='Project__C'){ comment for now : pick when apf comes>>>
                        List<Project__C> project = [SELECT Branch__c,Branch__r.Branch_ID__c, OwnerId 
                                        FROM Project__C 
                                        WHERE Id =: loanId];
                        opportunityTeamMemberObj = [SELECT User__c, User__r.Name ,User__r.IsActive,Vendor_del__c,Vendor_del__r.IsActive__c
                             FROM Branch_User__c
                             WHERE Branch__c =: project[0].Branch__c and Role__C='Legal' and User__r.IsActive=true];
                    }*/
                }
                catch(Exception exp){
                    throw new AuraHandledException('Error fetching user data: ' + exp.getStackTraceString());
                }
                return legalIdToAddressMap;
            }
}