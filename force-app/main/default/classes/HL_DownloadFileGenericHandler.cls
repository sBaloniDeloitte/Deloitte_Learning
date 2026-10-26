public without sharing class HL_DownloadFileGenericHandler {

    public class DownloadFileInput {
        public String fileName; // must include extension
    }

    public static String downloadFile(String fileName) {
        if (fileName == null) return null;
        String payload = buildPayload(fileName);
        return performCallout(payload);
    }

    private static String buildPayload(String fileName) {
        Map<String, Object> body = new Map<String, Object>{
            'source'     => 'SF',
            'bucketName' => 'ghfl-prod-sfdc-apf',
            'fileName'   => fileName
        };
        return JSON.serialize(body);
    }

    private static String performCallout(String payload) {
        System.debug('Download payload: ' + payload);

        Integration_Settings__c api =
            Integration_Settings__c.getValues('download_file_generic');

        HttpRequest req = new HttpRequest();
        req.setEndpoint(api.Endpoint__c);
        req.setMethod('POST');
        req.setTimeout(100000);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + Utility.getAccessToken());
        req.setBody(payload);

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('Download Response: ' + res.getBody());

        // Log Integration Details
        Integration_Details__c integration = new Integration_Details__c();
        integration.Name = 'download_file_generic';
        integration.Process_Name__c = 'download_file_generic';
        integration.Object_Name__c = 'Builder Project Document';
        integration.Endpoint__c = api.Endpoint__c;
        integration.Related_Record_Id__c='';
        integration.Communication_Status__c = 'Published';
        integration.Request_JSON__c = payload;
        integration.Response_JSON__c =
            res != null && res.getBody() != null ? res.getBody() : '';

        insert integration;

        // Extract fileData (ContentVersionId)
        if (res.getStatusCode() == 200 && String.isNotBlank(res.getBody())) {
            Map<String, Object> resp =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (resp.containsKey('data')) {
                Map<String, Object> data =
                    (Map<String, Object>) resp.get('data');
                return (String) data.get('fileData'); // ContentVersionId
            }
        }
        return null;
    }
}