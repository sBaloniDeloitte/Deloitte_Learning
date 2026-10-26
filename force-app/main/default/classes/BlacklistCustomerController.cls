/*This is controller class for fetchBlacklistCustomers LWC*/
public with sharing class BlacklistCustomerController {

    PRIVATE STATIC STRING SQL1 = Constants__mdt.getInstance('BlackList_Customer_SOQL1').Value__c ;
    PRIVATE STATIC STRING SQL2 = Constants__mdt.getInstance('Blacklist_Customer_SOQL2').Value__c ;
    PRIVATE STATIC STRING SQL3 = Constants__mdt.getInstance('Blacklist_Customer_SOQL3').Value__c ;
    PRIVATE STATIC STRING SQL4 = Constants__mdt.getInstance('Blacklist_Customer_SOQL4').Value__c ;
    PRIVATE STATIC STRING SQL5 = Constants__mdt.getInstance('Blacklist_Customer_SOQL5').Value__c ;
    PRIVATE STATIC STRING SQL6 = Constants__mdt.getInstance('Blacklist_Customer_SOQL6').Value__c ;
    PRIVATE STATIC STRING SQL7 = Constants__mdt.getInstance('Blacklist_Customer_SOQL7').Value__c ;
    PRIVATE STATIC STRING SQL8 = Constants__mdt.getInstance('Blacklist_Customer_SOQL8').Value__c ;

    PRIVATE STATIC STRING FIRST_NAME = 'FIRST_NAME';
    PRIVATE STATIC STRING MOBILE_NUMBER = 'MOBILE_NUMBER';
    PRIVATE STATIC STRING DOB = 'DOB';
    PRIVATE STATIC STRING PAN_NUMBER = 'PAN_NUMBER';
    PRIVATE STATIC STRING ADDRESS = 'ADDRESS';

    PRIVATE STATIC Map<String, String> hybridScoreMap = new Map<String, String>{
                                                            'FIRST_NAME'=>Constants__mdt.getInstance('Blacklist_Customer_FirstName_Min_Match').Value__c,
                                                            'ADDRESS'=>Constants__mdt.getInstance('Blacklist_Customer_Address_Min_Match').Value__c
                                                            };
    PRIVATE STATIC STRING activityName = Constants__mdt.getInstance('Blacklist_Customer_Activity_Name').Value__c;
    PRIVATE STATIC STRING success = Constants__mdt.getInstance('SUCCESS').Value__c;

    PRIVATE STATIC STRING BLANK_SPACE = ' ';

    PRIVATE STATIC List<Negative_dedupe__c> existingNegativeDedupeList = new List<Negative_dedupe__c>();
    PRIVATE STATIC Map<String,Negative_dedupe__c> dedubeMap= new Map<String,Negative_dedupe__c>();
    

    @AuraEnabled
    public static List<String> fetchBlackListCustomers(String loanId) {
        // try{
            Set<String> resultSet = new Set<String>();
            Set<Id> existingNegativeDedupeId = new Set<Id>();

            existingNegativeDedupeList   = [SELECT Id FROM Negative_dedupe__c where Id = 'a0pdN000000uuXNQAY'];// WHERE Negative_list_dispostion__c = :loanId ];

            List<String> resultList = new List<String>();
            resultList.add('success');
            return resultList;
            /*List<Application_Applicant__c> applicantList = [SELECT Id,First_Name__c,
                                                            Last_Name__c,Mobile_Number__c,PAN_Number__c,
                                                            DOB__c,Middle_Name__c, (SELECT Id,Full_Address__c 
                                                            FROM Applicant_Address__r) 
                                                            FROM Application_Applicant__c 
                                                            WHERE Loan_Application__c  = :loanId];

            Integration_Master__mdt metadata = [SELECT 
                                                        Process_Name__c,
                                                        Handler_Class__c,
                                                        Endpoint__c,
                                                        Request_Method__c,
                                                        Client_Id__c,
                                                        Client_Secret__c,
                                                        Allowed_Retry__c,
                                                        Gestation_Period__c,
                                                        Refresh_Allowed__c,
                                                        Activity_Name__c,
                                                        Is_Production__c
                                                    FROM Integration_Master__mdt 
                                                    WHERE Activity_Name__c = :activityName LIMIT 1];
            
            Map<String, String> inputMap = new Map<String, String>();
            String result;
            for(Application_Applicant__c applicant : applicantList){
                String Name = '';
                Name += applicant.First_Name__c != null ? applicant.First_Name__c + BLANK_SPACE : '';
                Name += applicant.Middle_Name__c != null ? applicant.Middle_Name__c + BLANK_SPACE : '';
                Name += applicant.Last_Name__c != null ? applicant.Last_Name__c : '';
                if(String.isNotBlank(Name)){
                    inputMap.put(FIRST_NAME,Name);
                }
                if(applicant.Mobile_Number__c != null){
                    inputMap.put(MOBILE_NUMBER,applicant.Mobile_Number__c);
                }
                if(applicant.DOB__c != null){
                    inputMap.put(DOB,String.valueOf(applicant.DOB__c));
                }
                if(applicant.PAN_Number__c != null){
                        inputMap.put(PAN_NUMBER,applicant.PAN_Number__c);
                }
                if(!applicant.Applicant_Address__r.isEmpty()){
                    for(Applicant_Address__c applicantAdd : applicant.Applicant_Address__r){
                        if(applicantAdd.Full_Address__c != null){
                            inputMap.put(ADDRESS,applicantAdd.Full_Address__c);
                        }
                        if(metadata.Is_Production__c) {
                            result = fetchCustomersProd(inputMap,loanId,applicant.Id);
                        }else{
                            result = fetchCustomersSandbox(inputMap,loanId,applicant.Id);
                            // result = fetchCustomersProd(inputMap,loanId,applicant.Id);
                        }
                    }
                }else{
                    if(metadata.Is_Production__c) {
                        result = fetchCustomersProd(inputMap,loanId,applicant.Id);
                    }else{
                        result = fetchCustomersSandbox(inputMap,loanId,applicant.Id);
                        // result = fetchCustomersProd(inputMap,loanId,applicant.Id);
                    }
                }
                resultSet.add(result);
                
            }
           

            try{
                if(!existingNegativeDedupeList.isEmpty()){ 
                    DELETE existingNegativeDedupeList; 
                }
                if(!dedubeMap.values().isEmpty()){
                    Database.INSERT(dedubeMap.values());
                }
                
            }catch(Exception ex){
                system.debug('ex>>>>'+ex);
                    throw new AurahandledException(ex.getMessage());
            }

            List<String> resultList = new List<String>();
            resultList.addAll(resultSet);
            return resultList;*/
        // }catch(Exception e){
        //     System.debug(e.getStackTraceString());
        //     throw new AuraHandledException(e.getMessage());
        // }
        
    }


    public static String fetchCustomersProd(Map<String, String> inputMap, String loanId, String applicantId) {
        // try{
            String resultMessage;
            String soql = createSOQL(inputMap);
            ConnectApi.CdpQueryOutputV2 response;
            
            ConnectApi.CdpQueryInput queryInput = new ConnectApi.CdpQueryInput();
            queryInput.sql = soql;
            //this needs to be uncommented while deplying to Production
            // response = ConnectApi.CdpQuery.queryAnsiSqlV2(
            //     queryInput
            // );

            System.debug('response fetch customer prod : '+response);        
        	
			String responseJson = JSON.serialize(response?.data);
			
            System.debug('Response JSON to store customer prod : ' + responseJson);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            integrationDetail.Loan_Application__c = loanId;
            integrationDetail.Response_JSON__c = responseJson;
            integrationDetail.Name = 'Blacklist Customers';
            integrationDetail.Object_Name__c = 'Negative_dedupe__c';
            integrationDetail.EndPoint__c = 'End point in Integration setting (Name = Blacklist Customers)';
            
            Map<String,Negative_dedupe__c> dedubeMap= new Map<String,Negative_dedupe__c>();
            for(integer i = 0; i<response.data.size(); i++){
                    Boolean isFirstNameLessThan70 = false;
                    Boolean isAddressLessThan70 = false; 
                    Negative_dedupe__c newDedupe = dedubeMap.get((String) response.data[i].rowData[0]) ?? new Negative_dedupe__c();
                    newDedupe.Negative_list_dispostion__c = (String) loanId;
                    newDedupe.Application_Applicant__c = (String) applicantId;
                    newDedupe.CIF_Id__c = (String) response.data[i].rowData[0];

                    String PARAM = (String) response.data[i].rowData[10];

                    SWITCH ON PARAM {
                        WHEN 'PAN_NUMBER' {
                             System.debug('inside when PAN_NUMBER');
                            newDedupe.PAN__c = (String) response.data[i].rowData[7];
                            newDedupe.Pan_Match__c = 100;
                            newDedupe.Rule__c = newDedupe.Rule__c != NULL ? newDedupe.Rule__c.contains('PAN_NUMBER') ? newDedupe.Rule__c : newDedupe.Rule__c + ', PAN_NUMBER' : 'PAN_NUMBER';

                            newDedupe.First_Name__c = String.isBlank((String) response.data[i].rowData[4]) ? '' : ((String) response.data[i].rowData[4]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[4];
                            newDedupe.DOB__c = String.isBlank((String) response.data[i].rowData[8]) ? '' : ((String) response.data[i].rowData[8]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[8];
                            newDedupe.Mobile_Number__c = String.isBlank((String) response.data[i].rowData[6]) ? '' : ((String) response.data[i].rowData[6]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[6];
                            newDedupe.Address__c = String.isBlank((String) response.data[i].rowData[9]) ? '' : ((String) response.data[i].rowData[9]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[9];

                        }   WHEN 'FIRST_NAME_DOB' {
                            // newDedupe.First_Name__c = (String) response.data[i].rowData[4];
                            Decimal similarity = similarityCheck.getNormalizedLevenshtein(inputMap.get(FIRST_NAME),(String) response.data[i].rowData[1]);
                            String similarityStr = String.valueOf(similarity * 100);
                            Integer similarityLen = similarityStr.length() > 4 ? 5 : similarityStr.length();
                        
                            Decimal similarityPercentage = Decimal.valueOf(similarityStr.substring(0, similarityStr.length() > 4 ? 5 : similarityStr.length()));
                            Boolean isSimilarityMet = similarity > Decimal.valueOf(hybridScoreMap.get(FIRST_NAME));
                            System.debug('similarityPercentage : '+similarityPercentage);
                            System.debug('isSimilarityMet : '+isSimilarityMet);

                            // newDedupe.First_Name_Match__c = Decimal.valueOf(similarityStr.substring(0, similarityLen));
                            if( isSimilarityMet && (newDedupe.First_Name__c == NULL || newDedupe.First_Name_Match__c < similarityPercentage)){
                                newDedupe.First_Name__c = (String) response.data[i].rowData[4];
                                newDedupe.First_Name_Match__c = similarityPercentage;
                                
                            }else if(!isSimilarityMet) {
                                isFirstNameLessThan70 = true;
                            }
                            newDedupe.DOB__c = (String) response.data[i].rowData[8];
                            newDedupe.DOB_Match__c = 100;
                            newDedupe.Rule__c = newDedupe.Rule__c != NULL ? newDedupe.Rule__c.contains('FIRST_NAME_DOB') ? newDedupe.Rule__c : newDedupe.Rule__c + ', FIRST_NAME_DOB' : 'FIRST_NAME_DOB';

                            newDedupe.PAN__c = String.isBlank((String) response.data[i].rowData[7]) ? '' : ((String) response.data[i].rowData[7]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[7];
                            newDedupe.Mobile_Number__c = String.isBlank((String) response.data[i].rowData[6]) ? '' : ((String) response.data[i].rowData[6]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[6];
                            newDedupe.Address__c = String.isBlank((String) response.data[i].rowData[9]) ? '' : ((String) response.data[i].rowData[9]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[9];

                        }   WHEN 'MOBILE_NUMBER' {
                            newDedupe.Mobile_Number__c = (String) response.data[i].rowData[6];
                            newDedupe.Mobile_Number_Match__c    = 100;
                            newDedupe.Rule__c = newDedupe.Rule__c != NULL ? newDedupe.Rule__c.contains('MOBILE_NUMBER') ? newDedupe.Rule__c : newDedupe.Rule__c + ', MOBILE_NUMBER' : 'MOBILE_NUMBER';

                            newDedupe.PAN__c = String.isBlank((String) response.data[i].rowData[7]) ? '' : ((String) response.data[i].rowData[7]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[7];
                            newDedupe.First_Name__c = String.isBlank((String) response.data[i].rowData[4]) ? '' : ((String) response.data[i].rowData[4]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[4];
                            newDedupe.DOB__c = String.isBlank((String) response.data[i].rowData[8]) ? '' : ((String) response.data[i].rowData[8]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[8];
                            newDedupe.Address__c = String.isBlank((String) response.data[i].rowData[9]) ? '' : ((String) response.data[i].rowData[9]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[9];

                        }   WHEN 'FIRST_NAME_ADDRESS' {
                            // newDedupe.First_Name__c = (String) response.data[i].rowData[4];
                            Decimal similarity = similarityCheck.getNormalizedLevenshtein(inputMap.get(FIRST_NAME),(String) response.data[i].rowData[1]);
                            String similarityStr = String.valueOf(similarity * 100);
                            Integer similarityLen = similarityStr.length() > 4 ? 5 : similarityStr.length();
                            Decimal similarityPercentage = Decimal.valueOf(similarityStr.substring(0, similarityStr.length() > 4 ? 5 : similarityStr.length()));
                            Boolean isSimilarityMet = similarity > Decimal.valueOf(hybridScoreMap.get(FIRST_NAME));
                            // newDedupe.First_Name_Match__c = Decimal.valueOf(similarityStr.substring(0, similarityLen));
                            if(isSimilarityMet && (newDedupe.First_Name__c == NULL || newDedupe.First_Name_Match__c < similarityPercentage)){
                                newDedupe.First_Name__c = (String) response.data[i].rowData[4];
                                newDedupe.First_Name_Match__c = similarityPercentage;
                                // newDedupe.Address__c = (String) response.data[i].rowData[9];
                                // newDedupe.Address_Match__c = similarityPercentageAdd;
                            }else if(!isSimilarityMet) {
                                isFirstNameLessThan70 = true;
                            }
                            Decimal similarityAdd = similarityCheck.getNormalizedLevenshtein(inputMap.get(ADDRESS),(String) response.data[i].rowData[9]);
                            String similarityStrAdd = String.valueOf(similarityAdd * 100);
                            Decimal similarityPercentageAdd = Decimal.valueOf(similarityStrAdd.substring(0, similarityStrAdd.length() > 4 ? 5 : similarityStrAdd.length()));
                            Boolean isSimilarityAddMet = similarityAdd > Decimal.valueOf(hybridScoreMap.get('ADDRESS'));
                            if(isSimilarityAddMet && (newDedupe.Address__c == NULL || newDedupe.Address_Match__c < similarityPercentageAdd)){
                                newDedupe.Address__c = address;
                                newDedupe.Address_Match__c = similarityPercentageAdd;
                            }else if(!isSimilarityAddMet){
                                isAddressLessThan70 = true;
                            }
                            newDedupe.Rule__c = newDedupe.Rule__c != NULL ? newDedupe.Rule__c.contains('FIRST_NAME_ADDRESS') ? newDedupe.Rule__c : newDedupe.Rule__c + ', FIRST_NAME_ADDRESS' : 'FIRST_NAME_ADDRESS';

                            newDedupe.PAN__c = String.isBlank((String) response.data[i].rowData[7]) ? '' : ((String) response.data[i].rowData[7]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[7];
                            newDedupe.DOB__c = String.isBlank((String) response.data[i].rowData[8]) ? '' : ((String) response.data[i].rowData[8]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[8];
                            newDedupe.Mobile_Number__c = String.isBlank((String) response.data[i].rowData[6]) ? '' : ((String) response.data[i].rowData[6]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[6];
                            
                        }   WHEN 'FIRST_NAME' {
                            // newDedupe.First_Name__c = (String) response.data[i].rowData[4];
                            Decimal similarity = similarityCheck.getNormalizedLevenshtein(inputMap.get(FIRST_NAME),(String) response.data[i].rowData[4]);
                            String similarityStr = String.valueOf(similarity * 100);
                            Integer similarityLen = similarityStr.length() > 4 ? 5 : similarityStr.length();
                            // newDedupe.First_Name_Match__c = Decimal.valueOf(similarityStr.substring(0, similarityLen));
                            Decimal similarityPercentage = Decimal.valueOf(similarityStr.substring(0, similarityStr.length() > 4 ? 5 : similarityStr.length()));
                            System.debug('inside when FIRST_NAME similarityPercentage'+ similarityPercentage);
                            Boolean isSimilarityMet = similarity > Decimal.valueOf(hybridScoreMap.get(FIRST_NAME));
                            if( isSimilarityMet && (newDedupe.First_Name__c == NULL || newDedupe.First_Name_Match__c < similarityPercentage)){
                                newDedupe.First_Name__c = (String) response.data[i].rowData[4];
                                newDedupe.First_Name_Match__c = Decimal.valueOf(similarityStr.substring(0, similarityLen));                    
                            }else if(!isSimilarityMet) {
                                isFirstNameLessThan70 = true;
                            }
                            newDedupe.Rule__c = newDedupe.Rule__c != NULL ? newDedupe.Rule__c.contains('FIRST_NAME') ? newDedupe.Rule__c : newDedupe.Rule__c + ', FIRST_NAME' : 'FIRST_NAME';

                            newDedupe.PAN__c = String.isBlank((String) response.data[i].rowData[7]) ? '' : ((String) response.data[i].rowData[7]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[7];
                            newDedupe.DOB__c = String.isBlank((String) response.data[i].rowData[8]) ? '' : ((String) response.data[i].rowData[8]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[8];
                            newDedupe.Mobile_Number__c = String.isBlank((String) response.data[i].rowData[6]) ? '' : ((String) response.data[i].rowData[6]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[6];
                            newDedupe.Address__c = String.isBlank((String) response.data[i].rowData[9]) ? '' : ((String) response.data[i].rowData[9]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[9];

                        }   WHEN 'FIRST_NAME_DOB_ADDRESS' {
                            System.debug('inside when FIRST_NAME_DOB_ADDRESS similarityPercentage');
                            newDedupe.First_Name__c = (String) response.data[i].rowData[4];
                            Decimal similarity = similarityCheck.getNormalizedLevenshtein(inputMap.get(FIRST_NAME),(String) response.data[i].rowData[1]);
                            String similarityStr = String.valueOf(similarity * 100);
                            Integer similarityLen = similarityStr.length() > 4 ? 5 : similarityStr.length();
                            newDedupe.First_Name_Match__c = Decimal.valueOf(similarityStr.substring(0, similarityLen));

                            newDedupe.Address__c = (String) response.data[i].rowData[9];
                            newDedupe.Address_Match__c    = Decimal.valueOf(String.valueOf(Decimal.valueOf((String) response.data[i].rowData[3]) * 100).substring(0, 5));
                            
                            newDedupe.DOB__c = (String) response.data[i].rowData[8];
                            newDedupe.DOB_Match__c = 100;
                            newDedupe.Rule__c = newDedupe.Rule__c != NULL ? newDedupe.Rule__c.contains('FIRST_NAME_DOB_ADDRESS') ? newDedupe.Rule__c : newDedupe.Rule__c + ', FIRST_NAME_DOB_ADDRESS' : 'FIRST_NAME_DOB_ADDRESS';

                            newDedupe.PAN__c = String.isBlank((String) response.data[i].rowData[7]) ? '' : ((String) response.data[i].rowData[7]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[7];
                            newDedupe.Mobile_Number__c = String.isBlank((String) response.data[i].rowData[6]) ? '' : ((String) response.data[i].rowData[6]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[6];
                            
                        }   WHEN 'FIRST_NAME_DOB_MOBILE' {
                            System.debug('inside when FIRST_NAME_DOB_MOBILE');
                            // newDedupe.First_Name__c = (String) response.data[i].rowData[4];
                            Decimal similarity = similarityCheck.getNormalizedLevenshtein(inputMap.get(FIRST_NAME),(String) response.data[i].rowData[1]);
                            String similarityStr = String.valueOf(similarity * 100);
                            Integer similarityLen = similarityStr.length() > 4 ? 5 : similarityStr.length();
                            // newDedupe.First_Name_Match__c = Decimal.valueOf(similarityStr.substring(0, similarityLen));
                            Decimal similarityPercentage = Decimal.valueOf(similarityStr.substring(0, similarityStr.length() > 4 ? 5 : similarityStr.length()));
                            Boolean isSimilarityMet = similarity > Decimal.valueOf(hybridScoreMap.get(FIRST_NAME));
                            if( isSimilarityMet && (newDedupe.First_Name__c == NULL || newDedupe.First_Name_Match__c < similarityPercentage)){
                                newDedupe.First_Name__c = (String) response.data[i].rowData[4];
                                newDedupe.First_Name_Match__c = Decimal.valueOf(similarityStr.substring(0, similarityLen));                    
                            }else if(!isSimilarityMet) {
                                isFirstNameLessThan70 = true;
                            }

                            newDedupe.Mobile_Number__c = (String) response.data[i].rowData[6];
                            newDedupe.Mobile_Number_Match__c    = 100;
                            
                            newDedupe.DOB__c = (String)  response.data[i].rowData[8];
                            newDedupe.DOB_Match__c = 100;
                            newDedupe.Rule__c = newDedupe.Rule__c != NULL ? newDedupe.Rule__c.contains('FIRST_NAME_DOB_MOBILE') ? newDedupe.Rule__c : newDedupe.Rule__c + ', FIRST_NAME_DOB_MOBILE' : 'FIRST_NAME_DOB_MOBILE';

                            newDedupe.PAN__c = String.isBlank((String) response.data[i].rowData[7]) ? '' : ((String) response.data[i].rowData[7]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[7];
                            newDedupe.Address__c = String.isBlank((String) response.data[i].rowData[9]) ? '' : ((String) response.data[i].rowData[9]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[9];

                        }   WHEN 'ADDRESS_DOB' {
                             System.debug('inside when ADDRESS_DOB');
                            newDedupe.Address__c = (String) response.data[i].rowData[9];
                            newDedupe.Address_Match__c = Decimal.valueOf(String.valueOf(Decimal.valueOf((String) response.data[i].rowData[3]) * 100).substring(0, 5));
                            
                            Decimal similarityAdd = similarityCheck.getNormalizedLevenshtein(inputMap.get(ADDRESS),address);
                            String similarityStrAdd = String.valueOf(similarityAdd * 100);
                            Decimal similarityPercentageAdd = Decimal.valueOf(similarityStrAdd.substring(0, similarityStrAdd.length() > 4 ? 5 : similarityStrAdd.length()));
                            Boolean isSimilarityAddMet = similarityAdd > Decimal.valueOf(hybridScoreMap.get('ADDRESS'));
                            if(isSimilarityAddMet && (newDedupe.Address__c == NULL || newDedupe.Address_Match__c < similarityPercentageAdd)){
                                newDedupe.Address__c = (String) response.data[i].rowData[9];
                                newDedupe.Address_Match__c = Decimal.valueOf(String.valueOf(Decimal.valueOf((String) response.data[i].rowData[3]) * 100).substring(0, 5));
                            }else if(!isSimilarityAddMet){
                                isAddressLessThan70 = true;
                            }

                            newDedupe.DOB__c = (String) response.data[i].rowData[8];
                            newDedupe.DOB_Match__c = 100;
                            newDedupe.Rule__c = newDedupe.Rule__c != NULL ? newDedupe.Rule__c.contains('ADDRESS_DOB') ? newDedupe.Rule__c : newDedupe.Rule__c + ', ADDRESS_DOB' : 'ADDRESS_DOB';

                            newDedupe.DOB__c = String.isBlank((String) response.data[i].rowData[8]) ? '' : ((String) response.data[i].rowData[8]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[8];
                            newDedupe.Address__c = String.isBlank((String) response.data[i].rowData[9]) ? '' : ((String) response.data[i].rowData[9]).toUpperCase() == 'NULL' ? '' : (String) response.data[i].rowData[9];

                        }
                    }
                    if(!isFirstNameLessThan70 && !isAddressLessThan70){
                    dedubeMap.put((String) response.data[i].rowData[0],newDedupe);
                    }
                    
                }

                if(!dedubeMap.values().isEmpty()){
                    insert dedubeMap.values();
                }
                insert integrationDetail;
                resultMessage = 'success';
                return resultMessage;
        // }catch(Exception ex){
        //         throw new AuraHandledException(ex.getMessage());
        //     }
        }
    

    public static String fetchCustomersSandbox(Map<String, String> inputMap, String loanId, String applicantId) {
System.debug('inputMap>>>>'+ inputMap);
        // try {
            String resultMessage;
            
            intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
            wrapper.recordId = loanId;
            wrapper.loanApplicationId = loanId;  
            wrapper.type = activityName;
            wrapper.inputMap = inputMap;

            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);

            List<Integration_Settings__c> intSettingList = [
                SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c 
                FROM Integration_Settings__c 
                WHERE Name = 'Blacklist Customers' LIMIT 1
            ];
            
            Integration_Settings__c intSetting = intSettingList[0];  

            Integration_Details__c integrationDetail = new Integration_Details__c();
            System.debug('respWrapper.prerequisiteError>>'+respWrapper.prerequisiteError);
            
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                // Collect all validation errors and send back to JS
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = 'Blacklist Customers';
                integrationDetail.Object_Name__c = 'Negative_dedupe__c';
                integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                resultMessage = String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Response_JSON__c = resultMessage;

                insert integrationDetail;
            } else {
                system.debug('inside negative dedupe');

                insertNegativeDedube(respWrapper.payload, loanId, applicantId, inputMap);
                resultMessage = 'success';
            
            }
            return resultMessage;
         
    //  } catch (Exception e) {
    //     System.debug(e.getStackTraceString());
    //      throw new AuraHandledException('Error: ' + e.getMessage());
    //     }
         
    }

    public static String createSOQL(Map<String, String> inputMap) {
        try{
            Map<String, String> paramMap = new Map<String, String>();
            paramMap.put(FIRST_NAME,Constants__mdt.getInstance('Blacklist_Customer_Param_LastName').Value__c);
            paramMap.put(ADDRESS,Constants__mdt.getInstance('Blacklist_Customer_Param_Address').Value__c); 
            paramMap.put(PAN_NUMBER,Constants__mdt.getInstance('Blacklist_Customer_Param_Pan').Value__c);
            paramMap.put(MOBILE_NUMBER,Constants__mdt.getInstance('Blacklist_Customer_Param_MobileNumber').Value__c);

            String sql = '';

            if(inputMap.get(PAN_NUMBER) != NULL){
                sql = sql != '' ? sql + BLANK_SPACE + Constants__mdt.getInstance('UNION_KEYWORD_SOQL').Value__c + BLANK_SPACE : '';
                sql += '(SELECT main_data.custcif__c,0 as firstname_hybrid_score__c,0 as lastname_hybrid_score__c,0 as address_hybrid_score__c,main_data.custfname__c,main_data.custlname__c,main_data.mobilenumber__c, main_data.custcrcpr__c, main_data.custdob__c, main_data.address__c,\'PAN_NUMBER\' as Input_param FROM blacklistcustomers__dlm main_data WHERE main_data.custcrcpr__c = \'';
                sql += inputMap.get(PAN_NUMBER) +'\' GROUP BY main_data.custcif__c, main_data.custfname__c,main_data.custlname__c,main_data.mobilenumber__c, main_data.custcrcpr__c, main_data.custdob__c, main_data.address__c)';
            }

            if(inputMap.get(FIRST_NAME) != NULL && inputMap.get(DOB) != NULL){
                sql = sql != '' ? sql + BLANK_SPACE + Constants__mdt.getInstance('UNION_KEYWORD_SOQL').Value__c + BLANK_SPACE : '';
                sql += '(SELECT hsearch.custcif__c,hsearch.hybrid_score__c as firstname_hybrid_score__c,0 as lastname_hybrid_score__c,0 as address_hybrid_score__c,main_data.custfname__c,main_data.custlname__c,main_data.mobilenumber__c,main_data.custcrcpr__c,main_data.custdob__c,main_data.address__c,\'FIRST_NAME_DOB\' as Input_param FROM hybrid_search(TABLE(blacklist_firstname_search_index_index__dlm),\'';
                sql +=  inputMap.get(FIRST_NAME) + '\',\'\', 100 ) hsearch INNER JOIN blacklistcustomers__dlm main_data ON hsearch.custcif__c = main_data.custcif__c WHERE main_data.custfname__c != \'NULL\' AND hsearch.hybrid_score__c > ' + hybridScoreMap.get(FIRST_NAME);
                sql += ' AND main_data.custdob__c = CAST(\'' + inputMap.get(DOB) + 'T00:00:00.000Z\' AS Timestamp) GROUP BY hsearch.custcif__c,hsearch.hybrid_score__c,main_data.custfname__c,main_data.custlname__c,main_data.mobilenumber__c,main_data.custcrcpr__c,main_data.custdob__c,main_data.address__c ORDER BY hsearch.hybrid_score__c DESC)';
            }

            if(inputMap.get(MOBILE_NUMBER) != NULL){
                sql = sql != '' ? sql + BLANK_SPACE + Constants__mdt.getInstance('UNION_KEYWORD_SOQL').Value__c + BLANK_SPACE : '';
                sql += '(SELECT main_data.custcif__c, 0 as firstname_hybrid_score__c,0 as lastname_hybrid_score__c,0 as address_hybrid_score__c,main_data.custfname__c,main_data.custlname__c,main_data.mobilenumber__c, main_data.custcrcpr__c, main_data.custdob__c, main_data.address__c,\'MOBILE_NUMBER\' as Input_param FROM blacklistcustomers__dlm main_data WHERE main_data.mobilenumber__c = \'';
                sql +=  inputMap.get(MOBILE_NUMBER) + '\' GROUP BY main_data.custcif__c, main_data.custfname__c,main_data.custlname__c,main_data.mobilenumber__c, main_data.custcrcpr__c, main_data.custdob__c, main_data.address__c)';
            }

            if(inputMap.get(FIRST_NAME) != NULL && inputMap.get(ADDRESS) != NULL){
                sql = sql != '' ? sql + BLANK_SPACE + Constants__mdt.getInstance('UNION_KEYWORD_SOQL').Value__c + BLANK_SPACE : '';
                sql +='(SELECT ahsearch.custcif__c, Fname.hybrid_score__c as firstname_hybrid_score__c,0 as lastname_hybrid_score__c,ahsearch.hybrid_score__c as address_hybrid_score__c,fmain_data.custfname__c,fmain_data.custlname__c,fmain_data.mobilenumber__c,fmain_data.custcrcpr__c,fmain_data.custdob__c,fmain_data.address__c,\'FIRST_NAME_ADDRESS\' as Input_param FROM hybrid_search(TABLE(blacklist_address_search_index_index__dlm),\'';
                sql += inputMap.get(ADDRESS) + '\',\'\', 100 ) ahsearch INNER JOIN (SELECT fhsearch.custcif__c,fhsearch.hybrid_score__c,main_data.custfname__c,main_data.custlname__c,main_data.mobilenumber__c,main_data.custcrcpr__c,main_data.custdob__c FROM hybrid_search(TABLE(blacklist_firstname_search_index_index__dlm),\'';
                sql += inputMap.get(FIRST_NAME) + '\',\'\', 100 ) fhsearch INNER JOIN blacklistcustomers__dlm main_data ON fhsearch.custcif__c = main_data.custcif__c WHERE main_data.custfname__c != \'NULL\' AND fhsearch.hybrid_score__c > ' + hybridScoreMap.get(FIRST_NAME);
                sql += ' GROUP BY fhsearch.custcif__c,fhsearch.hybrid_score__c,main_data.custfname__c,main_data.custlname__c,main_data.mobilenumber__c,main_data.custcrcpr__c,main_data.custdob__c,main_data.address__c ORDER BY fhsearch.hybrid_score__c DESC) Fname ON Fname.custcif__c = ahsearch.custcif__c INNER JOIN blacklistcustomers__dlm fmain_data ON ahsearch.custcif__c = fmain_data.custcif__c WHERE fmain_data.address__c != \'NULL\' AND ahsearch.hybrid_score__c > '+ hybridScoreMap.get('ADDRESS');
                sql += ' GROUP BY ahsearch.custcif__c,ahsearch.hybrid_score__c,Fname.hybrid_score__c,fmain_data.custfname__c,fmain_data.custlname__c,fmain_data.mobilenumber__c,fmain_data.custcrcpr__c,fmain_data.custdob__c,fmain_data.address__c ORDER BY ahsearch.hybrid_score__c DESC)';
            }
            
            if(inputMap.get(FIRST_NAME) != NULL){
                sql = sql != '' ? sql + BLANK_SPACE + Constants__mdt.getInstance('UNION_KEYWORD_SOQL').Value__c + BLANK_SPACE : '';
                sql += '(SELECT hsearch.custcif__c,hsearch.hybrid_score__c as firstname_hybrid_score__c,0 as lastname_hybrid_score__c,0 as address_hybrid_score__c,main_data.custfname__c,main_data.custlname__c,main_data.mobilenumber__c,main_data.custcrcpr__c,main_data.custdob__c,main_data.address__c,\'FIRST_NAME\' as Input_param FROM hybrid_search(TABLE(blacklist_firstname_search_index_index__dlm),\'';
                sql += inputMap.get(FIRST_NAME) + '\',\'\', 100 ) hsearch INNER JOIN blacklistcustomers__dlm main_data ON hsearch.custcif__c = main_data.custcif__c WHERE main_data.custfname__c != \'NULL\' AND hsearch.hybrid_score__c > ' + hybridScoreMap.get(FIRST_NAME);
                sql += ' GROUP BY hsearch.custcif__c,hsearch.hybrid_score__c,main_data.custfname__c,main_data.custlname__c,main_data.mobilenumber__c,main_data.custcrcpr__c,main_data.custdob__c,main_data.address__c ORDER BY hsearch.hybrid_score__c DESC)';
            }

            if(inputMap.get(FIRST_NAME) != NULL && inputMap.get(ADDRESS) != NULL && inputMap.get(DOB) != NULL){
                sql = sql != '' ? sql + BLANK_SPACE + Constants__mdt.getInstance('UNION_KEYWORD_SOQL').Value__c + BLANK_SPACE : '';
                sql += '(SELECT ahsearch.custcif__c,ahsearch.hybrid_score__c as Address_hybrid_score__c,0 as lastname_hybrid_score__c,Fname.hybrid_score__c as firstname_hybrid_score__c,fmain_data.custfname__c,fmain_data.custlname__c,fmain_data.mobilenumber__c,fmain_data.custcrcpr__c,fmain_data.custdob__c,fmain_data.address__c,\'FIRST_NAME_DOB_ADDRESS\' as Input_param FROM hybrid_search(TABLE(blacklist_address_search_index_index__dlm),\'';
                sql += inputMap.get(ADDRESS) + '\',\'\', 100 ) ahsearch INNER JOIN (SELECT fhsearch.custcif__c,fhsearch.hybrid_score__c,main_data.custfname__c,main_data.custlname__c,main_data.mobilenumber__c,main_data.custcrcpr__c,main_data.custdob__c FROM hybrid_search(TABLE(blacklist_firstname_search_index_index__dlm),\'';
                sql += inputMap.get(FIRST_NAME) + '\',\'\', 100 ) fhsearch INNER JOIN blacklistcustomers__dlm main_data ON fhsearch.custcif__c = main_data.custcif__c WHERE main_data.custfname__c != \'NULL\' AND fhsearch.hybrid_score__c > ' + hybridScoreMap.get(FIRST_NAME);
                sql += ' AND main_data.custdob__c = CAST(\'' +  inputMap.get(DOB) + 'T00:00:00.000Z\' AS Timestamp) GROUP BY fhsearch.custcif__c,fhsearch.hybrid_score__c,main_data.custfname__c,main_data.custlname__c,main_data.mobilenumber__c,main_data.custcrcpr__c,main_data.custdob__c,main_data.address__c ORDER BY fhsearch.hybrid_score__c DESC) Fname ON Fname.custcif__c = ahsearch.custcif__c INNER JOIN blacklistcustomers__dlm fmain_data ON ahsearch.custcif__c = fmain_data.custcif__c WHERE fmain_data.address__c != \'NULL\' AND ahsearch.hybrid_score__c > ' + hybridScoreMap.get(FIRST_NAME);
                sql += ' AND fmain_data.custdob__c = CAST(\''+inputMap.get(DOB) + 'T00:00:00.000Z\' AS Timestamp) GROUP BY ahsearch.custcif__c,ahsearch.hybrid_score__c,Fname.hybrid_score__c,fmain_data.custfname__c,fmain_data.custlname__c,fmain_data.mobilenumber__c,fmain_data.custcrcpr__c,fmain_data.custdob__c,fmain_data.address__c ORDER BY ahsearch.hybrid_score__c DESC)';
            }

            if(inputMap.get(FIRST_NAME) != NULL && inputMap.get(DOB) != NULL && inputMap.get(MOBILE_NUMBER) != NULL){
                sql = sql != '' ? sql + BLANK_SPACE + Constants__mdt.getInstance('UNION_KEYWORD_SOQL').Value__c + BLANK_SPACE : '';
                sql += '(SELECT hsearch.custcif__c,hsearch.hybrid_score__c as firstname_hybrid_score__c,0 as lastname_hybrid_score__c,0 as address_hybrid_score__c,main_data.custfname__c,main_data.custlname__c,main_data.mobilenumber__c,main_data.custcrcpr__c,main_data.custdob__c,main_data.address__c,\'FIRST_NAME_DOB_MOBILE\' as Input_param FROM hybrid_search(TABLE(blacklist_firstname_search_index_index__dlm),\'';
                sql += inputMap.get(FIRST_NAME) + '\',\'\', 100 ) hsearch INNER JOIN blacklistcustomers__dlm main_data ON hsearch.custcif__c = main_data.custcif__c WHERE main_data.custfname__c != \'NULL\' AND hsearch.hybrid_score__c > ' + hybridScoreMap.get(FIRST_NAME);
                sql += ' AND main_data.custdob__c = CAST(\'' + inputMap.get(DOB) + 'T00:00:00.000Z\' AS Timestamp) AND main_data.mobilenumber__c = \'' + inputMap.get(MOBILE_NUMBER) ;
                sql += '\' GROUP BY hsearch.custcif__c,hsearch.hybrid_score__c,main_data.custfname__c,main_data.custlname__c,main_data.mobilenumber__c,main_data.custcrcpr__c,main_data.custdob__c,main_data.address__c ORDER BY hsearch.hybrid_score__c DESC)';
            }

            if(inputMap.get(ADDRESS) != NULL && inputMap.get(DOB) != NULL){
                sql = sql != '' ? sql + BLANK_SPACE + Constants__mdt.getInstance('UNION_KEYWORD_SOQL').Value__c + BLANK_SPACE : '';
                sql += '(SELECT hsearch.custcif__c,0 as firstname_hybrid_score__c,0 as lastname_hybrid_score__c,hsearch.hybrid_score__c as address_hybrid_score__c,main_data.custfname__c,main_data.custlname__c,main_data.mobilenumber__c,main_data.custcrcpr__c,main_data.custdob__c,main_data.address__c,\'ADDRESS_DOB\' as Input_param FROM hybrid_search(TABLE(blacklist_address_search_index_index__dlm),\'';
                sql += inputMap.get(ADDRESS) +'\',\'\', 100 ) hsearch INNER JOIN blacklistcustomers__dlm main_data ON hsearch.custcif__c = main_data.custcif__c WHERE main_data.address__c != \'NULL\' AND hsearch.hybrid_score__c > ' + hybridScoreMap.get(FIRST_NAME);
                sql += ' AND main_data.custdob__c = CAST(\''+inputMap.get(DOB) + 'T00:00:00.000Z\' AS Timestamp) GROUP BY hsearch.custcif__c,hsearch.hybrid_score__c,main_data.custfname__c,main_data.custlname__c,main_data.mobilenumber__c,main_data.custcrcpr__c,main_data.custdob__c,main_data.address__c ORDER BY hsearch.hybrid_score__c DESC)';
            }
        
            System.debug('sql281'+sql);
            return sql;
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        
    }

    public static void insertNegativeDedube(String payload, String loanId, String applicantId, Map<String, String> inputMap){
        Map<String, String> integrationRequestMap = new Map<String, String>();
        System.debug('requestJSON payload : '+payload);
        integrationRequestMap.put('intSettingName', 'Blacklist Customers');
        integrationRequestMap.put('requestJSON', payload);
        HTTPResponse res = Utility.executeAPIRequest(integrationRequestMap);
        System.debug('insertNegativeDedupe res --> ' + res);
        List<Integration_Settings__c> intSettingList = [
                SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c 
                FROM Integration_Settings__c 
                WHERE Name = 'Blacklist Customers' LIMIT 1
            ];
        Integration_Details__c integrationDetail = new Integration_Details__c();
        integrationDetail.Name = 'Blacklist Customers';
        integrationDetail.Request_JSON__c = payload;
        integrationDetail.Endpoint__c = intSettingList[0].Endpoint__c;
        integrationDetail.Loan_Application__c = loanId;
        // insert integrationDetail;
        if(res != null){
            System.debug('insertNegativeDedupe res.getBody()'+res.getBody());
            integrationDetail.Response_JSON__c = res.getBody();
            blackListCustomerWrapper response = (blackListCustomerWrapper) System.JSON.deserialize(res.getbody(), blackListCustomerWrapper.class);
            for(integer i = 0; i<response.data.size(); i++){
                Boolean isFirstNameLessThan70 = false;
                Boolean isAddressLessThan70 = false;
                Negative_dedupe__c newDedupe = dedubeMap.get(response.data[i][0]) ?? new Negative_dedupe__c();
                newDedupe.Negative_list_dispostion__c = loanId;
                newDedupe.Application_Applicant__c = applicantId;
                newDedupe.CIF_Id__c = response.data[i][0];

                SWITCH ON response.data[i][10] {
                    when 'PAN_NUMBER' {
                        system.debug('inside PAN_NUMBER ');

                        newDedupe.PAN__c = response.data[i][7];
                        newDedupe.Pan_Match__c = 100;

                        newDedupe.Rule__c = newDedupe.Rule__c != NULL ? newDedupe.Rule__c.contains('PAN_NUMBER') ? newDedupe.Rule__c : newDedupe.Rule__c + ', PAN_NUMBER' : 'PAN_NUMBER';

                        newDedupe.First_Name__c = String.isBlank(response.data[i][4]) && String.isBlank(newDedupe.First_Name__c) ? '' : String.isNotBlank(newDedupe.First_Name__c) ? newDedupe.First_Name__c : response.data[i][4].toUpperCase() == 'NULL' ? '' : response.data[i][4];
                        newDedupe.DOB__c = String.isBlank(response.data[i][8]) && String.isBlank(newDedupe.DOB__c) ? '' : String.isNotBlank(newDedupe.DOB__c) ? newDedupe.DOB__c : response.data[i][8].toUpperCase() == 'NULL' ? '' : response.data[i][8];
                        newDedupe.Mobile_Number__c = String.isBlank(response.data[i][6]) && String.isBlank(newDedupe.Mobile_Number__c) ? '' : String.isNotBlank(newDedupe.Mobile_Number__c) ? newDedupe.Mobile_Number__c : response.data[i][6].toUpperCase() == 'NULL' ? '' : response.data[i][6];
                        newDedupe.Address__c = String.isBlank(response.data[i][9]) && String.isBlank(newDedupe.Address__c) ? '' : String.isNotBlank(newDedupe.Address__c) ? newDedupe.Address__c : response.data[i][9].toUpperCase() == 'NULL' ? '' : response.data[i][9];

                    }   when 'FIRST_NAME_DOB' {
                        system.debug('inside FIRST_NAME_DOB ');
                        String firstName = response.data[i][4];
                        String dob = response.data[i][8];

                        Decimal similarity = similarityCheck.getNormalizedLevenshtein(inputMap.get(FIRST_NAME),response.data[i][4]);
                        String similarityStr = String.valueOf(similarity * 100);
                        Decimal similarityPercentage = Decimal.valueOf(similarityStr.substring(0, similarityStr.length() > 4 ? 5 : similarityStr.length()));
                        Boolean isSimilarityMet = similarity > Decimal.valueOf(hybridScoreMap.get(FIRST_NAME));
                        if( isSimilarityMet && (newDedupe.First_Name__c == NULL || newDedupe.First_Name_Match__c < similarityPercentage)){
                            newDedupe.First_Name__c = firstName;
                            newDedupe.First_Name_Match__c = similarityPercentage;
                            
                        }else if(!isSimilarityMet) {
                            isFirstNameLessThan70 = true;
                        }

                        newDedupe.DOB__c = dob;
                        newDedupe.DOB_Match__c = 100;

                        newDedupe.Rule__c = newDedupe.Rule__c != NULL ? newDedupe.Rule__c.contains('FIRST_NAME_DOB') ? newDedupe.Rule__c : newDedupe.Rule__c + ', FIRST_NAME_DOB' : 'FIRST_NAME_DOB';

                        newDedupe.Mobile_Number__c = String.isBlank(response.data[i][6]) && String.isBlank(newDedupe.Mobile_Number__c) ? '' : String.isNotBlank(newDedupe.Mobile_Number__c) ? newDedupe.Mobile_Number__c : response.data[i][6].toUpperCase() == 'NULL' ? '' : response.data[i][6];
                        newDedupe.Address__c = String.isBlank(response.data[i][9]) && String.isBlank(newDedupe.Address__c) ? '' : String.isNotBlank(newDedupe.Address__c) ? newDedupe.Address__c : response.data[i][9].toUpperCase() == 'NULL' ? '' : response.data[i][9];
                        newDedupe.PAN__c = String.isBlank(response.data[i][7]) && String.isBlank(newDedupe.PAN__c) ? '' : String.isNotBlank(newDedupe.PAN__c) ? newDedupe.PAN__c : response.data[i][7].toUpperCase() == 'NULL' ? '' : response.data[i][7];

                    }   when 'MOBILE_NUMBER' {
                        system.debug('inside MOBILE_NUMBER ');
                        newDedupe.Mobile_Number__c = response.data[i][6];
                        newDedupe.Mobile_Number_Match__c    = 100;

                        newDedupe.Rule__c = newDedupe.Rule__c != NULL ? newDedupe.Rule__c.contains('MOBILE_NUMBER') ? newDedupe.Rule__c : newDedupe.Rule__c + ', MOBILE_NUMBER' : 'MOBILE_NUMBER';

                        newDedupe.First_Name__c = String.isBlank(response.data[i][4]) && String.isBlank(newDedupe.First_Name__c) ? '' : String.isNotBlank(newDedupe.First_Name__c) ? newDedupe.First_Name__c : response.data[i][4].toUpperCase() == 'NULL' ? '' : response.data[i][4];
                        newDedupe.Address__c = String.isBlank(response.data[i][9]) && String.isBlank(newDedupe.Address__c) ? '' : String.isNotBlank(newDedupe.Address__c) ? newDedupe.Address__c : response.data[i][9].toUpperCase() == 'NULL' ? '' : response.data[i][9];
                        newDedupe.PAN__c = String.isBlank(response.data[i][7]) && String.isBlank(newDedupe.PAN__c) ? '' : String.isNotBlank(newDedupe.PAN__c) ? newDedupe.PAN__c : response.data[i][7].toUpperCase() == 'NULL' ? '' : response.data[i][7];
                        newDedupe.DOB__c = String.isBlank(response.data[i][8]) && String.isBlank(newDedupe.DOB__c) ? '' : String.isNotBlank(newDedupe.DOB__c) ? newDedupe.DOB__c : response.data[i][8].toUpperCase() == 'NULL' ? '' : response.data[i][8];
                        
                    }   when 'FIRST_NAME_ADDRESS' {
                        system.debug('inside FIRST_NAME_ADDRESS ');

                        String firstName = response.data[i][4];
                        String address = response.data[i][9];

                        Decimal similarity = similarityCheck.getNormalizedLevenshtein(inputMap.get(FIRST_NAME),response.data[i][4]);
                        String similarityStr = String.valueOf(similarity * 100);
                        Decimal similarityPercentage = Decimal.valueOf(similarityStr.substring(0, similarityStr.length() > 4 ? 5 : similarityStr.length()));
                        Boolean isSimilarityMet = similarity > Decimal.valueOf(hybridScoreMap.get(FIRST_NAME));
                        if( isSimilarityMet && (newDedupe.First_Name__c == NULL || newDedupe.First_Name_Match__c < similarityPercentage)){
                            newDedupe.First_Name__c = firstName;
                            newDedupe.First_Name_Match__c = similarityPercentage;
                            
                        }else if(!isSimilarityMet) {
                            isFirstNameLessThan70 = true;
                        }

                        Decimal similarityAdd = similarityCheck.getNormalizedLevenshtein(inputMap.get(ADDRESS),address);
                        String similarityStrAdd = String.valueOf(similarityAdd * 100);
                        Decimal similarityPercentageAdd = Decimal.valueOf(similarityStrAdd.substring(0, similarityStrAdd.length() > 4 ? 5 : similarityStrAdd.length()));
                        Boolean isSimilarityAddMet = similarityAdd > Decimal.valueOf(hybridScoreMap.get('ADDRESS'));
                        if(isSimilarityAddMet && (newDedupe.Address__c == NULL || newDedupe.Address_Match__c < similarityPercentageAdd)){
                            newDedupe.Address__c = address;
                            newDedupe.Address_Match__c = similarityPercentageAdd;
                        }else if(!isSimilarityAddMet){
                            isAddressLessThan70 = true;
                        }

                        newDedupe.Rule__c = newDedupe.Rule__c != NULL ? newDedupe.Rule__c.contains('FIRST_NAME_ADDRESS') ? newDedupe.Rule__c : newDedupe.Rule__c + ', FIRST_NAME_ADDRESS' : 'FIRST_NAME_ADDRESS';

                        newDedupe.PAN__c = String.isBlank(response.data[i][7]) && String.isBlank(newDedupe.PAN__c) ? '' : String.isNotBlank(newDedupe.PAN__c) ? newDedupe.PAN__c : response.data[i][7].toUpperCase() == 'NULL' ? '' : response.data[i][7];
                        newDedupe.DOB__c = String.isBlank(response.data[i][8]) && String.isBlank(newDedupe.DOB__c) ? '' : String.isNotBlank(newDedupe.DOB__c) ? newDedupe.DOB__c : response.data[i][8].toUpperCase() == 'NULL' ? '' : response.data[i][8];
                        newDedupe.Mobile_Number__c = String.isBlank(response.data[i][6]) && String.isBlank(newDedupe.Mobile_Number__c) ? '' : String.isNotBlank(newDedupe.Mobile_Number__c) ? newDedupe.Mobile_Number__c : response.data[i][6].toUpperCase() == 'NULL' ? '' : response.data[i][6];
                        
                    }   when 'FIRST_NAME' {
                        System.debug('inside when FIRST_NAME'+ response.data);
                        String firstName = response.data[i][4];
                        System.debug('inside when FIRST_NAME firstName : '+firstName);
                        Decimal similarity = similarityCheck.getNormalizedLevenshtein(inputMap.get(FIRST_NAME),response.data[i][4]);
                        System.debug('inside when FIRST_NAME similarity'+ similarity);
                        String similarityStr = String.valueOf(similarity * 100);
                        System.debug('inside when FIRST_NAME similarityStr'+ similarityStr);
                        Decimal similarityPercentage = Decimal.valueOf(similarityStr.substring(0, similarityStr.length() > 4 ? 5 : similarityStr.length()));
                        System.debug('inside when FIRST_NAME similarityPercentage'+ similarityPercentage);
                        Boolean isSimilarityMet = similarity > Decimal.valueOf(hybridScoreMap.get(FIRST_NAME));
                        System.debug('inside when FIRST_NAME isSimilarityMet'+ isSimilarityMet);
                        if( isSimilarityMet && (newDedupe.First_Name__c == NULL || newDedupe.First_Name_Match__c < similarityPercentage)){
                            System.debug('inside when FIRST_NAME isSimilarityMet firstName : '+firstName + ' similarityPercentage : '+similarityPercentage);
                            newDedupe.First_Name__c = firstName;
                            newDedupe.First_Name_Match__c = similarityPercentage;                    
                        }else if(!isSimilarityMet) {
                            System.debug('inside when FIRST_NAME isSimilarityMet not firstName : '+firstName + ' similarityPercentage : '+similarityPercentage);
                            isFirstNameLessThan70 = true;
                        }

                        newDedupe.Rule__c = newDedupe.Rule__c != NULL ? newDedupe.Rule__c.contains('FIRST_NAME') ? newDedupe.Rule__c : newDedupe.Rule__c + ', FIRST_NAME' : 'FIRST_NAME';

                        newDedupe.Mobile_Number__c = String.isBlank(response.data[i][6]) && String.isBlank(newDedupe.Mobile_Number__c) ? '' : String.isNotBlank(newDedupe.Mobile_Number__c) ? newDedupe.Mobile_Number__c : response.data[i][6].toUpperCase() == 'NULL' ? '' : response.data[i][6];
                        newDedupe.Address__c = String.isBlank(response.data[i][9]) && String.isBlank(newDedupe.Address__c) ? '' : String.isNotBlank(newDedupe.Address__c) ? newDedupe.Address__c : response.data[i][9].toUpperCase() == 'NULL' ? '' : response.data[i][9];
                        newDedupe.PAN__c = String.isBlank(response.data[i][7]) && String.isBlank(newDedupe.PAN__c) ? '' : String.isNotBlank(newDedupe.PAN__c) ? newDedupe.PAN__c : response.data[i][7].toUpperCase() == 'NULL' ? '' : response.data[i][7];
                        newDedupe.DOB__c = String.isBlank(response.data[i][8]) && String.isBlank(newDedupe.DOB__c) ? '' : String.isNotBlank(newDedupe.DOB__c) ? newDedupe.DOB__c : response.data[i][8].toUpperCase() == 'NULL' ? '' : response.data[i][8];

                    }   when 'FIRST_NAME_DOB_ADDRESS' {

                        String firstName = response.data[i][4];
                        String dob = response.data[i][8];
                        String address = response.data[i][9];

                        Decimal similarity = similarityCheck.getNormalizedLevenshtein(inputMap.get(FIRST_NAME),response.data[i][4]);
                        String similarityStr = String.valueOf(similarity * 100);
                        Decimal similarityPercentage = Decimal.valueOf(similarityStr.substring(0, similarityStr.length() > 4 ? 5 : similarityStr.length()));
                        Boolean isSimilarityMet = similarity > Decimal.valueOf(hybridScoreMap.get(FIRST_NAME));
                        if( isSimilarityMet && (newDedupe.First_Name__c == NULL || newDedupe.First_Name_Match__c < similarityPercentage)){
                            newDedupe.First_Name__c = firstName;
                            newDedupe.First_Name_Match__c = similarityPercentage;
                            
                        }else if(!isSimilarityMet) {
                            isFirstNameLessThan70 = true;
                        }

                        Decimal similarityAdd = similarityCheck.getNormalizedLevenshtein(inputMap.get(ADDRESS),address);
                        String similarityStrAdd = String.valueOf(similarityAdd * 100);
                        Decimal similarityPercentageAdd = Decimal.valueOf(similarityStrAdd.substring(0, similarityStrAdd.length() > 4 ? 5 : similarityStrAdd.length()));
                        Boolean isSimilarityAddMet = similarityAdd > Decimal.valueOf(hybridScoreMap.get('ADDRESS'));
                        if(isSimilarityAddMet && (newDedupe.Address__c == NULL || newDedupe.Address_Match__c < similarityPercentageAdd)){
                            newDedupe.Address__c = address;
                            newDedupe.Address_Match__c = similarityPercentageAdd;
                        }else if(!isSimilarityAddMet){
                            isAddressLessThan70 = true;
                        }

                        newDedupe.DOB__c = dob;
                        newDedupe.DOB_Match__c = 100;

                        newDedupe.Rule__c = newDedupe.Rule__c != NULL ? newDedupe.Rule__c.contains('FIRST_NAME_DOB_ADDRESS') ? newDedupe.Rule__c : newDedupe.Rule__c + ', FIRST_NAME_DOB_ADDRESS' : 'FIRST_NAME_DOB_ADDRESS';

                        newDedupe.Mobile_Number__c = String.isBlank(response.data[i][6]) && String.isBlank(newDedupe.Mobile_Number__c) ? '' : String.isNotBlank(newDedupe.Mobile_Number__c) ? newDedupe.Mobile_Number__c : response.data[i][6].toUpperCase() == 'NULL' ? '' : response.data[i][6];
                        newDedupe.PAN__c = String.isBlank(response.data[i][7]) && String.isBlank(newDedupe.PAN__c) ? '' : String.isNotBlank(newDedupe.PAN__c) ? newDedupe.PAN__c : response.data[i][7].toUpperCase() == 'NULL' ? '' : response.data[i][7];
                        
                    }   when 'FIRST_NAME_DOB_MOBILE' {

                        String firstName = response.data[i][4];
                        String dob = response.data[i][8];
                        String mobile = response.data[i][6];

                        Decimal similarity = similarityCheck.getNormalizedLevenshtein(inputMap.get(FIRST_NAME),response.data[i][4]);
                        String similarityStr = String.valueOf(similarity * 100);
                        Decimal similarityPercentage = Decimal.valueOf(similarityStr.substring(0, similarityStr.length() > 4 ? 5 : similarityStr.length()));
                        Boolean isSimilarityMet = similarity > Decimal.valueOf(hybridScoreMap.get(FIRST_NAME));
                        if( isSimilarityMet && (newDedupe.First_Name__c == NULL || newDedupe.First_Name_Match__c < similarityPercentage)){
                            newDedupe.First_Name__c = firstName;
                            newDedupe.First_Name_Match__c = similarityPercentage;
                            
                        }else if(!isSimilarityMet) {
                            isFirstNameLessThan70 = true;
                        }

                        newDedupe.Mobile_Number__c = mobile;
                        newDedupe.Mobile_Number_Match__c    = 100;
                        
                        newDedupe.DOB__c = dob;
                        newDedupe.DOB_Match__c = 100;

                        newDedupe.Rule__c = newDedupe.Rule__c != NULL ? newDedupe.Rule__c.contains('FIRST_NAME_DOB_MOBILE') ? newDedupe.Rule__c : newDedupe.Rule__c + ', FIRST_NAME_DOB_MOBILE' : 'FIRST_NAME_DOB_MOBILE';

                        newDedupe.Address__c = String.isBlank(response.data[i][9]) && String.isBlank(newDedupe.Address__c) ? '' : String.isNotBlank(newDedupe.Address__c) ? newDedupe.Address__c : response.data[i][9].toUpperCase() == 'NULL' ? '' : response.data[i][9];
                        newDedupe.PAN__c = String.isBlank(response.data[i][7]) && String.isBlank(newDedupe.PAN__c) ? '' : String.isNotBlank(newDedupe.PAN__c) ? newDedupe.PAN__c : response.data[i][7].toUpperCase() == 'NULL' ? '' : response.data[i][7];

                    }   when 'ADDRESS_DOB' {
                        system.debug('inside address>>>'+response.data[i][9]);
                        String address = response.data[i][9];
                        String dob = response.data[i][8];

                        Decimal similarityAdd = similarityCheck.getNormalizedLevenshtein(inputMap.get(ADDRESS),address);
                        String similarityStrAdd = String.valueOf(similarityAdd * 100);
                        Decimal similarityPercentageAdd = Decimal.valueOf(similarityStrAdd.substring(0, similarityStrAdd.length() > 4 ? 5 : similarityStrAdd.length()));
                        Boolean isSimilarityAddMet = similarityAdd > Decimal.valueOf(hybridScoreMap.get('ADDRESS'));
                        if(isSimilarityAddMet && (newDedupe.Address__c == NULL || newDedupe.Address_Match__c < similarityPercentageAdd)){
                            newDedupe.Address__c = address;
                            newDedupe.Address_Match__c = similarityPercentageAdd;
                        }else if(!isSimilarityAddMet){
                            isAddressLessThan70 = true;
                        }

                        newDedupe.DOB__c = response.data[i][8];
                        newDedupe.DOB_Match__c = 100;

                        newDedupe.Rule__c = newDedupe.Rule__c != NULL ? newDedupe.Rule__c.contains('ADDRESS_DOB') ? newDedupe.Rule__c : newDedupe.Rule__c + ', ADDRESS_DOB' : 'ADDRESS_DOB';
                        
                        newDedupe.Address__c = String.isBlank(response.data[i][9]) && String.isBlank(newDedupe.Address__c) ? '' : String.isNotBlank(newDedupe.Address__c) ? newDedupe.Address__c : response.data[i][9].toUpperCase() == 'NULL' ? '' : response.data[i][9];
                        newDedupe.PAN__c = String.isBlank(response.data[i][7]) && String.isBlank(newDedupe.PAN__c) ? '' : String.isNotBlank(newDedupe.PAN__c) ? newDedupe.PAN__c : response.data[i][7].toUpperCase() == 'NULL' ? '' : response.data[i][7];
                                                
                    }
                }
                if(!isFirstNameLessThan70 && !isAddressLessThan70){
                    dedubeMap.put(response.data[i][0],newDedupe);
                }
            }
        } else {
            integrationDetail.Response_JSON__c = 'Response is comming as null from the api';
        }
        //insert integrationDetail;
        createIntegrationDetailsFuture(JSON.serialize(integrationDetail));
    }
    @future
    public static void createIntegrationDetailsFuture(string recListJSON){
        System.debug('recListJSON>>>>'+ recListJSON);
       Integration_Details__c recList = (Integration_Details__c) JSON.deserialize(recListJSON, Integration_Details__c.class);
       insert recList;
    } 
}