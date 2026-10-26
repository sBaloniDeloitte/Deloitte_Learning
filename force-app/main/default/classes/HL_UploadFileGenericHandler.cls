public without sharing class HL_UploadFileGenericHandler implements Queueable, Database.AllowsCallouts {
    
    private List<Id> contentVersionIds;
    private List<ContentDocumentLink> cdlForProject;
    
    public HL_UploadFileGenericHandler(List<Id> cvIds,List<ContentDocumentLink> cdlForProject) {
        this.contentVersionIds = cvIds;
        this.cdlForProject = cdlForProject;
    }
    
    public void execute(QueueableContext context) {
        Map<Id, Id> contentDocToBPDMap = new Map<Id, Id>();
        for (ContentDocumentLink cdl : cdlForProject) {
            contentDocToBPDMap.put(cdl.ContentDocumentId,cdl.LinkedEntityId);
        }
        Map<Id, Builder_Project_Document__c> bpdToProjectMap = new Map<Id, Builder_Project_Document__c>();
        for (Builder_Project_Document__c bpd : [SELECT Id, Project__c,Document_Name__c
                                                FROM Builder_Project_Document__c
                                                WHERE Id IN :contentDocToBPDMap.values()]) 
        {
            bpdToProjectMap.put(bpd.Id, bpd);
        }
        
        List<ContentVersion> cvs = [
            SELECT Id, Title, FileType, ContentDocumentId
            FROM ContentVersion
            WHERE Id IN :contentVersionIds
        ];
        
        for (ContentVersion cv : cvs) {
            uploadFile(cv, contentDocToBPDMap, bpdToProjectMap);
        }
    }
    
    private static void uploadFile(ContentVersion cv,Map<Id, Id> contentDocToBPDMap,Map<Id, Builder_Project_Document__c> bpdToProjectMap) {
        String contentType = getContentType(cv.FileType);
        if (String.isBlank(contentType)) return;
        String payload = JSON.serialize(new Map<String, Object>{
            'source'      => 'SF',
                'bucketName'  => 'ghfl-prod-sfdc-apf',
                'fileName'    => cv.Title + '_' + cv.Id + '.' + cv.FileType.toLowerCase(),
                'contentType' => contentType,
                'content'     => cv.Id
                });
        
        performCallout(payload, cv, contentDocToBPDMap, bpdToProjectMap);
    }
    
    private static void performCallout(String payload,ContentVersion cv,Map<Id, Id> contentDocToBPDMap,Map<Id, Builder_Project_Document__c> bpdToProjectMap) {
        Integration_Settings__c api =Integration_Settings__c.getValues('upload_file_generic');
        HttpRequest req = new HttpRequest();
        req.setEndpoint(api.Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + Utility.getAccessToken());
        req.setBody(payload);
        HttpResponse res = new Http().send(req);
        UploadResponse response =(UploadResponse) JSON.deserialize(res.getBody(), UploadResponse.class);
        List<Integration_Details__c> integrationList = new List<Integration_Details__c>();
        Integration_Details__c integration = new Integration_Details__c();
        integration.Name = 'upload_file_generic ';
        integration.Process_Name__c ='upload_file_generic';
        integration.Object_Name__c='Builder Project Document';
        integration.Endpoint__c = api.Endpoint__c; 
        integration.Related_Record_Id__c= contentDocToBPDMap.get(cv.ContentDocumentId);
        integration.Communication_Status__c = 'Published';
        integration.Request_JSON__c = payload;
        integration.Response_JSON__c = res!=null && res.getBody() !=null ? res.getBody() :'';
        integrationList.add(integration);
        insert integrationList;
        if (response != null && response.statusCode == 200) {
            Document_Details__c doc = new Document_Details__c();
            doc.Description__c=cv.Title + '_' + cv.Id + '.' + cv.FileType.toLowerCase();
            doc.Document_Uploaded__c = true;
            doc.Status__c = 'Uploaded';
            doc.is_APF_Doc__c = true;
            doc.Content_Version_Id__c = cv.Id;
            doc.Content_Document_Id__c = cv.ContentDocumentId;
            Id bpdId = contentDocToBPDMap.get(cv.ContentDocumentId);
            if (bpdId != null && bpdToProjectMap.containsKey(bpdId)) {
                Builder_Project_Document__c bpd = bpdToProjectMap.get(bpdId);
                doc.Name = bpd.Document_Name__c;
                doc.Project__c = bpd.Project__c;
            }
            doc.Requirement_Level__c='Collateral level';
            doc.Uploaded_Date_Time__c=Datetime.now();
            insert doc;
        }
    }
    
    private static String getContentType(String ext) {
        Map<String, String> mapExtToType = new Map<String, String>{
            'pdf' => 'application/pdf',
                'jpg' => 'image/jpg',
                'jpeg'=> 'image/jpeg',
                'png' => 'image/png'
                };
                    return mapExtToType.get(ext != null ? ext.toLowerCase() : null);
    }
    
    public class UploadResponse {
        public Integer statusCode;
        public String message;
        public Object data;
    }
}