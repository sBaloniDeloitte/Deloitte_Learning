/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-03-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class OCRProcessingService {
    /*
    @AuraEnabled(cacheable=true)
    public static Map<String, Boolean> processOCRData(String docType, String loanApplicationId, String objectName , String appId) {
        // Debug log to show inputs
        System.debug('Processing OCR Data for DocType: ' + docType);
        System.debug('Loan Application ID: ' + loanApplicationId);
        System.debug('Object Name: ' + objectName);

        Map<String, Boolean> resultMap = new Map<String, Boolean>();

        try {
            // Query to get the OCR response from the Response JSON field in the Integration_Details__c object
            String responseJson = [SELECT Response_JSON__c FROM Integration_Details__c WHERE Loan_Application__c = :loanApplicationId and Related_Record_Id__c =:appId LIMIT 1].Response_JSON__c;
            
            // Debug log to show the fetched JSON response
            System.debug('Fetched Response JSON: ' + responseJson);

            // Parse the JSON response into a Map
            Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(responseJson);
            System.debug('Parsed Response: ' + parsedResponse);

            // Extract the result map
            Map<String, Object> result = (Map<String, Object>) parsedResponse.get('result');
            
            // Safely cast the documents field to a List<Object>
            List<Object> documents = (List<Object>) result.get('documents');

            // Check if documents are empty or null
            if (documents == null || documents.isEmpty()) {
                System.debug('No documents found in the response.');
                return resultMap;
            }

            // Loop through each document in the response
            for (Object documentObj : documents) {
                Map<String, Object> document = (Map<String, Object>) documentObj; // Cast the document to a Map
                // Extract the OCR data from the document
                Map<String, Object> ocrData = (Map<String, Object>) document.get('ocrData');
                System.debug('OCR Data: ' + ocrData);

                // Loop through each OCR field in the document
                for (String field : ocrData.keySet()) {
                    Map<String, Object> fieldData = (Map<String, Object>) ocrData.get(field);
                    Double confidenceScore = (Double) fieldData.get('confidence');
                    System.debug('Field: ' + field + ' - Confidence Score: ' + confidenceScore);

                    // Get the API name for the field using the metadata
                    String apiName = getApiNameForField(docType, field);
                    System.debug('API Name for Field "' + field + '": ' + apiName);

                    // Compare the confidence score with 0.8 and store the result in the map
                    Boolean isValid = confidenceScore > 0.8;
                    resultMap.put(apiName, isValid);
                    System.debug('Result for ' + apiName + ': ' + isValid);
                }
            }

        } catch (Exception e) {
            System.debug('Error processing OCR data: ' + e.getMessage());
            throw new AuraHandledException('Error processing OCR data: ' + e.getMessage());
        }

        // Return the result map
        return resultMap;
    }

    */


    @AuraEnabled(cacheable=false)
    public static Map<String, Boolean> processOCRData(String docType, String loanApplicationId, String objectName, String appId) {
        System.debug('>>> Processing OCR Data for DocType: ' + docType);
        System.debug('>>> Loan Application ID: ' + loanApplicationId);
        System.debug('>>> Object Name: ' + objectName);
        System.debug('>>> App ID: ' + appId);

        Map<String, Boolean> resultMap = new Map<String, Boolean>();

        try {
            // Query to get the most recent OCR response from Integration_Details__c
            // Try multiple query variations to find the record
            List<Integration_Details__c> integrationDetails = new List<Integration_Details__c>();
            
            // First Trying with Exact match with Related_Record_Id__c
            integrationDetails = [
                SELECT Response_JSON__c, Request_JSON__c, Status__c, CreatedDate, Name
                FROM Integration_Details__c 
                WHERE Loan_Application__c = :loanApplicationId 
                AND Related_Record_Id__c = :appId
                AND Status__c = '200'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            
            // Second trying with Look for recent OCR records without Related_Record_Id__c filter
            if (integrationDetails.isEmpty()) {
                System.debug('>>> No records found with Related_Record_Id__c, trying broader search...');
                integrationDetails = [
                    SELECT Response_JSON__c, Request_JSON__c, Status__c, CreatedDate, Name, Related_Record_Id__c
                    FROM Integration_Details__c 
                    WHERE Loan_Application__c = :loanApplicationId 
                    AND Name LIKE '%OCR%'
                    AND Status__c = '200'
                    AND CreatedDate = TODAY
                    ORDER BY CreatedDate DESC
                    LIMIT 5
                ];
                
                // Log what we found for debugging
                System.debug('>>> Found ' + integrationDetails.size() + ' potential OCR records');
                for (Integration_Details__c record : integrationDetails) {
                    System.debug('>>> Record: ' + record.Name + ', Related_Record_Id__c: ' + record.Related_Record_Id__c + ', Created: ' + record.CreatedDate);
                }
            }
            
            // Third Trying for any recent successful integration
            if (integrationDetails.isEmpty()) {
                System.debug('>>> No OCR records found, trying any recent successful integration...');
                integrationDetails = [
                    SELECT Response_JSON__c, Request_JSON__c, Status__c, CreatedDate, Name
                    FROM Integration_Details__c 
                    WHERE Loan_Application__c = :loanApplicationId 
                    AND Status__c = '200'
                    AND CreatedDate = TODAY
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
            }
            
            if (integrationDetails.isEmpty()) {
                System.debug('No Integration_Details__c record found');
                
                // Debug: Check what records exist
                List<Integration_Details__c> allRecords = [
                    SELECT Id, Name, Loan_Application__c, Related_Record_Id__c, Status__c, CreatedDate
                    FROM Integration_Details__c 
                    WHERE Loan_Application__c = :loanApplicationId
                    ORDER BY CreatedDate DESC
                    LIMIT 10
                ];
                System.debug('>>> All Integration_Details__c records for loan: ' + allRecords);
                System.debug('>>> No OCR response found, but continuing...');
                return resultMap;
            }
            
            Integration_Details__c latestRecord = integrationDetails[0];
            String responseJson = latestRecord.Response_JSON__c;
            
            System.debug('>>> Using record: ' + latestRecord.Name + ' created at: ' + latestRecord.CreatedDate);
            
            if (String.isBlank(responseJson)) {
                System.debug('>>> OCR response data is empty, but this might be expected for some document types');
                return resultMap;
            }

            // Parse the JSON response into a Map
            Map<String, Object> parsedResponse;
            try {
                parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(responseJson);
            } catch (Exception parseEx) {
                System.debug('JSON parsing error: ' + parseEx.getMessage());
                // Don't throw error, just return empty map
                System.debug('>>> Continuing despite JSON parsing error...');
                return resultMap;
            }
            
            System.debug('>>> Parsed Response keys: ' + parsedResponse.keySet());

            // Extract the result map - handle different response structures
            Map<String, Object> result;
            if (parsedResponse.containsKey('result')) {
                result = (Map<String, Object>) parsedResponse.get('result');
            } else {
                // Sometimes the response might be directly the result
                result = parsedResponse;
            }
            
            if (result == null) {
                System.debug('>>> No result data found in OCR response, but continuing...');
                return resultMap;
            }
            
            // Safely cast the documents field to a List<Object>
            List<Object> documents;
            if (result.containsKey('documents')) {
                documents = (List<Object>) result.get('documents');
            } else {
                System.debug('>>> No documents field found in result');
                return resultMap;
            }

            // Check if documents are empty or null
            if (documents == null || documents.isEmpty()) {
                System.debug('>>> Documents list is empty');
                return resultMap;
            }

            System.debug('>>> Found ' + documents.size() + ' documents in response');

            // Loop through each document in the response
            for (Object documentObj : documents) {
                Map<String, Object> document = (Map<String, Object>) documentObj;
                
                // Extract the OCR data from the document
                if (!document.containsKey('ocrData')) {
                    System.debug('Document missing ocrData field');
                    continue;
                }
                
                Map<String, Object> ocrData = (Map<String, Object>) document.get('ocrData');
                System.debug('>>> OCR Data fields: ' + ocrData.keySet());

                // Loop through each OCR field in the document
                for (String field : ocrData.keySet()) {
                    try {
                        Object fieldDataObj = ocrData.get(field);
                        if (fieldDataObj == null) {
                            System.debug('Field ' + field + ' is null');
                            continue;
                        }
                        
                        Map<String, Object> fieldData = (Map<String, Object>) fieldDataObj;
                        
                        if (fieldData == null || !fieldData.containsKey('confidence')) {
                            System.debug('Field ' + field + ' missing confidence data');
                            continue;
                        }
                        
                        Object confidenceObj = fieldData.get('confidence');
                        Double confidenceScore;
                        
                        // Handle different confidence data types
                        if (confidenceObj instanceof Double) {
                            confidenceScore = (Double) confidenceObj;
                        } else if (confidenceObj instanceof Integer) {
                            confidenceScore = Double.valueOf( String.valueOf( (Integer) confidenceObj ) );
                        } else if (confidenceObj instanceof String) {
                            try {
                                confidenceScore = Double.valueOf((String) confidenceObj);
                            } catch (Exception convEx) {
                                System.debug('Cannot convert confidence to Double for field: ' + field);
                                continue;
                            }
                        } else {
                            System.debug('Unknown confidence data type for field: ' + field);
                            continue;
                        }
                        
                        System.debug('>>> Field: ' + field + ' - Confidence Score: ' + confidenceScore);

                        // Get the API name for the field using the metadata
                        String apiName = getApiNameForField(docType, field);
                        System.debug('>>> API Name for Field "' + field + '": ' + apiName);

                        // Compare the confidence score with 0.8 and store the result in the map
                        Boolean isValid = confidenceScore != null && confidenceScore > 0.8;
                        resultMap.put(apiName, isValid);
                        System.debug('>>> Result for ' + apiName + ': ' + isValid);
                        
                    } catch (Exception fieldEx) {
                        System.debug('Error processing field ' + field + ': ' + fieldEx.getMessage());
                        // Continue processing other fields
                    }
                }
            }
            
            System.debug('>>> Final result map: ' + resultMap);

        } catch (Exception e) {
            System.debug('Error processing OCR data: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            // Don't throw exception, just return what we have
            System.debug('>>> Returning partial results due to error');
        }

        return resultMap;

    }


    // Method to dynamically map the OCR field to the API name using metadata
    public static String getApiNameForField(String docType, String field) {
        // Query the Ocr_docs_mapping__mdt metadata to get the mapping for the given docType and field
        List<Ocr_docs_mapping__mdt> mappings = [SELECT Api_Name__c, Json_Field__c, Doc_Type__c 
                                                 FROM Ocr_docs_mapping__mdt 
                                                 WHERE Doc_Type__c = :docType AND Json_Field__c = :field];

        // Debug log to check if we found any mappings
        System.debug('Found mappings for docType "' + docType + '" and field "' + field + '": ' + mappings);

        // If a mapping is found, return the API name
        if (!mappings.isEmpty()) {
            return mappings[0].Api_Name__c;
        }

        // If no mapping is found, return the field name itself
        return field;
    }

    @AuraEnabled
    public static Map<String, Boolean> checkFieldValues(String docName, String recordId) {
        System.debug('checkFieldValues called with docName=' + docName + ', recordId=' + recordId);
        Map<String, Boolean> resultMap = new Map<String, Boolean>();
        try {
            // Query the metadata records to get the field names
            List<Ocr_Field_Check__mdt> mappings = [SELECT Manual_Field__c, Ocr_Field__c 
                                                   FROM Ocr_Field_Check__mdt 
                                                   WHERE Doc_Name__c = :docName];

            
            // Build the dynamic SOQL query to retrieve the fields from Application_Applicant__c
            System.debug('mappings found: ' + mappings);
            String query = 'SELECT Id';
            for (Ocr_Field_Check__mdt mapping : mappings) {
                query += ', ' + mapping.Manual_Field__c + ', ' + mapping.Ocr_Field__c;
            }
            query += ' FROM Application_Applicant__c WHERE Id = :recordId LIMIT 1';
            System.debug('query '+query);
            // Execute the dynamic query
            Application_Applicant__c applicant = Database.query(query);
            // Compare the fields and add to the resultMap
            for (Ocr_Field_Check__mdt mapping : mappings) {
                String manualField = (String)applicant.get(mapping.Manual_Field__c);
                String ocrField = (String)applicant.get(mapping.Ocr_Field__c);
                System.debug('manualField '+manualField);
                System.debug('ocrField '+ocrField);
                // Compare the fields and add to the resultMap
                System.debug('resultMap : '+resultMap);
                resultMap.put(mapping.Manual_Field__c, manualField == ocrField);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return resultMap;
    }

    
}