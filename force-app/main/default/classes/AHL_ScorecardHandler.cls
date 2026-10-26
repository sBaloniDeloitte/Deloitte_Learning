public class AHL_ScorecardHandler implements IntegrationInterface {

    public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) {
        List<String> errorMessages = new List<String>();
        List<Document_Details__c> docDetails = [
            SELECT Id, Content_Document_Id__c
            FROM Document_Details__c
            WHERE Loan_Application__c = :wrapper.loanApplicationId
              AND Applicant__c = :wrapper.applicantId
              AND Content_Document_Id__c != null
              AND Name = 'CRIF Response'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (docDetails.isEmpty()) {
            errorMessages.add('Please hit crif first.');
        }
        return errorMessages;
    }

    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<Document_Details__c> docLst = [
            SELECT Id, Content_Document_Id__c
            FROM Document_Details__c
            WHERE Name = 'CRIF Response'
              AND Applicant__c = :wrapper.applicantId
              AND Loan_Application__c = :wrapper.loanApplicationId
              AND Content_Document_Id__c != null
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (docLst.isEmpty()) {
            throw new HandlerException('CRIF Response document not found for applicant.');
        }

        List<ContentVersion> conversionLst = [
            SELECT Id, VersionData
            FROM ContentVersion
            WHERE ContentDocumentId = :docLst[0].Content_Document_Id__c
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (conversionLst.isEmpty()) {
            throw new HandlerException('CRIF Response file content not found.');
        }

        String crifAllResponse = conversionLst[0].VersionData.toString();

        Object rootObj;
        try {
            rootObj = JSON.deserializeUntyped(crifAllResponse);
        } catch (Exception e) {
            throw new HandlerException('Stored CRIF response is not valid JSON: ' + e.getMessage());
        }
        if (!(rootObj instanceof Map<String, Object>)) {
            throw new HandlerException('Stored CRIF response is not a JSON object.');
        }

        Map<String, Object> root = (Map<String, Object>) transformKeys(rootObj);

        Object cirObj = root.get('CIR-REPORT-FILE');
        if (cirObj instanceof Map<String, Object>) {
            ((Map<String, Object>) cirObj).remove('SalesforceDetails');
        }

        root.put('Response', new Map<String, Object>());

        return JSON.serialize(root);
    }
    @TestVisible
    private static Object transformKeys(Object node) {
        if (node instanceof Map<String, Object>) {
            Map<String, Object> src = (Map<String, Object>) node;
            Map<String, Object> transformed = new Map<String, Object>();
            for (String key : src.keySet()) {
                transformed.put(key.replace('_', '-'), transformKeys(src.get(key)));
            }
            return transformed;
        }
        if (node instanceof List<Object>) {
            List<Object> src = (List<Object>) node;
            List<Object> transformed = new List<Object>();
            for (Object item : src) {
                transformed.add(transformKeys(item));
            }
            return transformed;
        }
        return node;
    }

    public class HandlerException extends Exception {}
}