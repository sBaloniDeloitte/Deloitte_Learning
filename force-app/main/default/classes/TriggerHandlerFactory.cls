public with sharing class TriggerHandlerFactory {

    public static Map<String, List<SObject>> getRecordsByProducts(String objectName, List<SObject> records, String productField) {
        Map<String, List<SObject>> resultMap = new Map<String, List<SObject>>();
        resultMap.put('BL', new List<SObject>());
        resultMap.put('HL', new List<SObject>());
    
        for (SObject record : records) {
            Object productValueObj = record.get(productField);
            if (productValueObj != null) {
                String productValue = String.valueOf(productValueObj);
    
                if (productValue == 'Business Loan') {
                    resultMap.get('BL').add(record);
                } else if (productValue == 'Over Draft') {
                    resultMap.get('HL').add(record);
                } else {
                    if (!resultMap.containsKey(productValue)) {
                        resultMap.put(productValue, new List<SObject>());
                    }
                    resultMap.get(productValue).add(record);
                }
            }
        }
    
        return resultMap;
    }

    public static Map<String, Map<String, List<SObject>>> getObjectRecordsByProducts(String objectName, List<SObject> records, String productField) {
        Map<String, Map<String, List<SObject>>> resultMap = new Map<String, Map<String, List<SObject>>>();
        
        Map<String, String> productToClassMap = new Map<String, String>();
        List<Product_Based_Class_Assignment__mdt> assignmentDetails = [SELECT Product__c, Class_Name__c FROM Product_Based_Class_Assignment__mdt WHERE Object_API_Name__c = :objectName];
        
        for (Product_Based_Class_Assignment__mdt assignment : assignmentDetails) {
            if (assignment.Product__c != null && assignment.Class_Name__c != null) {
                productToClassMap.put(assignment.Product__c, assignment.Class_Name__c);
            }
        }
        
        for (SObject record : records) {
            Object productValueObj = record.get(productField);
            if (productValueObj != null) {
                String productValue = String.valueOf(productValueObj);
                String className = productToClassMap.get(productValue);
                
                if (className != null) {
                    if (!resultMap.containsKey(productValue)) {
                        resultMap.put(productValue, new Map<String, List<SObject>>());
                    }
                    Map<String, List<SObject>> classMap = resultMap.get(productValue);
                    
                    if (!classMap.containsKey(className)) {
                        classMap.put(className, new List<SObject>());
                    }
                    classMap.get(className).add(record);
                }
            }
        }
        
        return resultMap;
    }
    
}