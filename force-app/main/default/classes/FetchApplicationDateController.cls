public with sharing class FetchApplicationDateController {
    @AuraEnabled
     public static String initiateFetchDate() {
        try {
            return fetchApplicationDateLogic();
        } catch (Exception e) {
            // Only throw AuraHandledException in UI context
            throw new AuraHandledException('Error fetching date: ' + e.getMessage());
        }
    }
    public static String fetchApplicationDateLogic() {
        try {
            Integration_Settings__c intSettings = [SELECT Id, Name, Request_Method__c, Endpoint__c, Authorization__c, Content_Type__c, Entity_Id__c, Message_Id__c FROM Integration_Settings__c 
                                                    WHERE Name = 'Fetch Application Date' LIMIT 1];
            
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            String bearer = Utility.getAccessToken();
            req.setHeader('Authorization', 'Bearer ' + bearer);
            req.setHeader('ENTITYID', intSettings.Entity_Id__c);
            req.setHeader('ServiceName', 'getSystemDate');
            req.setHeader('Language', 'ENG');
            req.setHeader('RequestTime', DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
            req.setHeader('ServiceVersion', '1');
            req.setHeader('MESSAGEID', intSettings.Message_Id__c);
            req.setHeader('Content-Type', intSettings.Content_Type__c);

            req.setEndpoint(intSettings.Endpoint__c);
            req.setMethod(intSettings.Request_Method__c);
            req.setTimeout(60000);

            HttpResponse res = http.send(req);
            System.debug('Response body: ' + res.getBody());
            String responseBody = res.getBody();
            String appDateString;
            if (String.isNotBlank(responseBody)) {
                Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                if (resultMap.containsKey('appDate')) {
                    appDateString = (String) resultMap.get('appDate');
                }
            }

            Integration_Details__c integrationDetail= new Integration_Details__c();
            // integrationDetail.Request_JSON__c = respWrapper.payload; 
            integrationDetail.Response_JSON__c = res.getBody();
            // integrationDetail.Status__c = String.valueof(res.getStatusCode()); 
            integrationDetail.Method_Type__c = intSettings.Request_Method__c; 
            integrationDetail.EndPoint__c = intSettings.EndPoint__c; 
            integrationDetail.Name = 'Fetch Application Date'; 
            if (String.isNotBlank(appDateString)) {
                integrationDetail.Business_Date__c = Date.valueOf(appDateString);
            }
            insert integrationDetail;

            return res.getBody(); 

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching date: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String getFetchAppDateIntDetails() {
        List<Integration_Details__c> integrationDetailsList = [SELECT Id, Name, Method_Type__c, EndPoint__c, Response_JSON__c, Request_JSON__c, Business_Date__c 
                                                                FROM Integration_Details__c WHERE Name = 'Fetch Application Date' AND Method_Type__c = 'GET' order by CreatedDate DESC];
        if (!integrationDetailsList.isEmpty()) {
            if (integrationDetailsList[0].Business_Date__c != null) {
                return integrationDetailsList[0].Business_Date__c.format();
            } else {
                return 'No Records found';
            }
        } else {
            return 'No Records found';
        }
    }
}