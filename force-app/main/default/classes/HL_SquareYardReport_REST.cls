@RestResource(urlMapping='/api/SquareYard')
global with sharing class HL_SquareYardReport_REST
{
    @HttpPost
    global static ResponseWrapper saveReport() {
        RestRequest restReq = RestContext.request;

        ResponseWrapper res = new ResponseWrapper();
        res.methodType = restReq.httpMethod;
        
        String requestBody = restReq.requestBody.toString();
        system.debug('requestBody: '+requestBody);

        if(!requestBody.contains('apiAction') || !requestBody.contains('requestId') || !requestBody.contains('fileName') || !requestBody.contains('fileExtension') || !requestBody.contains('versionData')){
            res.statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_REQUIRED_FIELD_MISSING').Value__c);
            res.errorMessage = 'Required parameter missing.';
            return res;
        }

        string loanId = '';
        RequestWrapper req = new RequestWrapper();

        try{
            req = (RequestWrapper)JSON.deserialize(requestBody, RequestWrapper.class);
            //System.debug('req: '+req);

            if(String.isBlank(req.apiAction)) {
                res.statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_REQUIRED_FIELD_MISSING').Value__c);
                res.errorMessage = Constants__mdt.getInstance('ERROR_MESSAGE_API_ACTION').Value__c;
                return res;
            }

            if(String.isBlank(req.requestId)){
                res.statusCode = Constants.STATUS_CODE_REQUIRED_FIELD_MISSING;
                res.errorMessage = 'RequestId is missing.';
                return res;
            }

            req.fileName = req.fileName.trim();
            req.fileExtension = req.fileExtension.trim();

            if(String.isBlank(req.versionData) || String.isBlank(req.fileName) || String.isBlank(req.fileExtension)){
                res.statusCode = Constants.STATUS_CODE_REQUIRED_FIELD_MISSING;
                res.errorMessage = 'Report datails are missing.';
                return res;
            }

            switch on req.apiAction.toUpperCase() {
                when 'SAVE REPORT' {
                    loanId = saveReport(req, res);
                }
            }
        }
        catch(Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'Square Yard saveReport', '', '') });
                        
            res.statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_ERROR').Value__c);
            res.errorMessage = e.getMessage();
        }
        finally{
            string endpoint = URL.getOrgDomainURL().toExternalForm() + restReq.resourcePath;

            Utility.createIntegrationRecord(new List<Integration_Details__c>{ Utility.fillIntegrationRecord('SquareYard API', requestBody, JSON.serialize(res), res.statusCode.toString(), res.methodType, endpoint, '', '', 'SquareYard saveReport', loanId) });
        }
        
        //system.debug('res: '+ JSON.serialize(res));
        return res;
    }

    private static string saveReport(RequestWrapper req, ResponseWrapper res){

        String loanId = '';
        List<Technical_Evaluation__c> tech = [Select Id, HL_Loan_Application__c From Technical_Evaluation__c Where HL_SquareYard_RequestId__c =: req.requestId];
        //system.debug('tech: '+tech);
        
        if(!tech.isEmpty()){

            loanId = tech[0].HL_Loan_Application__c;

            List<Document_Details__c> dd = [Select Id, Content_Document_Id__c, Status__c From Document_Details__c Where Technical__c =: tech[0].Id];
            if(!dd.isEmpty()){

                ContentVersion cv = new ContentVersion();
                cv.Title = req.fileName;
                cv.PathOnClient = req.fileName +'.'+ req.fileExtension.removeStart('.');
                cv.VersionData = EncodingUtil.base64Decode(req.versionData);
                cv.IsMajorVersion = true;
                insert cv;

                ContentVersion cvRec = [Select ContentDocumentId From ContentVersion Where Id =: cv.Id];
                //System.debug('cvRec: '+cvRec);

                ContentDocumentLink cd = new ContentDocumentLink();
                cd.LinkedEntityId = dd[0].Id;
                cd.ContentDocumentId = cvRec.ContentDocumentId;
                cd.ShareType = 'V';
                cd.Visibility = 'AllUsers';
                insert cd;
            
                dd[0].Status__c = Constants.STATUS_UPLOADED;
                dd[0].Content_Document_Id__c = cvRec.ContentDocumentId;
                update dd;

                res.statusCode = 200;
                res.contentVersionId = cv.Id;
                res.documentDetailsId = dd[0].Id;
            }
            else {
                res.statusCode = 320;
                res.errorMessage = 'Related document details record with RequestId not found.';
            }
        }
        else {
            res.statusCode = 310;
            res.errorMessage = 'Related technical record with RequestId not found.';
        }

        return loanId;
    }

    public class RequestWrapper {
        public String apiAction;            //This is used to capture what action this API will do like lead dedupe, pincode serviceable check, lead create/update etc.
        public String requestId;            //Square Yard report initiation request id
        public String fileName;
        public String fileExtension;        //File extension need to paas eg: .pdf, .jpg, .doc etc.
        public string versionData;          //Paas base64Encode(Blob inputBlob) in this attribute for single document only
    }

    global class ResponseWrapper {
        public Integer statusCode;
        public String errorMessage;
        public String methodType;
        public String contentVersionId;
        public String documentDetailsId;
    }
}