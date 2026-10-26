public with sharing class DocGenerationRestUtility {
    //1.compressedAPI working
    public static HttpResponse getCompressedDocument(string jsonbody){	
        return  callDocGenAPI(jsonbody, 'Callout:LOS_Digi_Doc_API/' + 'ghf/v1/pdf/compress', 'POST', 'f7aKO@d1e2f8a4bE7e8f9g0h1Q2j3k4KRV8D');                
    }
    //Added
    //2.DocGenAPI
    public static HttpResponse generateDocumentAPI(string jsonbody){	
        return  callDocGenAPI(jsonbody, 'Callout:LOS_Digi_Doc_API/' + 'v1/ghf/api/digi/get-digidocket-preview', 'POST', '');               
    }
    //3.ESignAPI
    public static HttpResponse generateESignDocumentAPI(string jsonbody){	
        return  callDocGenAPI(jsonbody, 'Callout:LOS_Digi_Doc_API/' + 'v1/ghf/api/digi/doc-esign', 'POST', '');                
    }

    //4.CancelESign 
    public static HttpResponse cancelEsignAPI(string linkedRecId){	
        return  callDocGenAPI('', 'Callout:LOS_Digi_Doc_API/' + 'v1/ghf/api/digi/cancel-esign?did=' + linkedRecId, 'GET', '');
    }

     //5.ESignStatuscheckAPI
    public static HttpResponse checkESignStatusAPI(string jsonbody){	
        return  callDocGenAPI(jsonbody, 'Callout:LOS_Digi_Doc_API/' + 'v1/ghf/api/digi/get-esign-status', 'POST', '');                
    }

    //6.DownloadEsignedDocAPI
    public static HttpResponse downLoadDigiDocAPI(string linkedRecId){	
        return  callDocGenAPI('', 'Callout:LOS_Digi_Doc_API/' + 'v1/ghf/api/digi/get-download-digidocket?did=' + linkedRecId, 'GET', '');              
    }
    //7.DocGenAPIAsync
    public static HttpResponse generateDocumentAPIAsync(string jsonbody){
        return  callDocGenAPI(jsonbody, 'Callout:LOS_Digi_Doc_API/' + 'v1/ghf/api/digi/get-digidocket-preview-async', 'POST', '');               
    }

    public static HttpResponse callDocGenAPI(string jsonbody, string endPoint, string method, string xAuthKey){	
		Http http = new Http();
        HttpRequest request = new HttpRequest();
        String bearer = Utility.getAccessToken();
        String authorizationHeader = 'Bearer ' + bearer;
        // request.setEndpoint('Callout:LOS_Digi_Doc_Generation_API');
        request.setEndpoint(endPoint);
        if(Method == 'POST')
        {
            request.setBody(jsonbody);
        }
        if(xAuthKey != ''){
            request.setHeader('X-Auth-Key', xAuthKey);
        }

        // if (xAuthKey == '') {
        request.setHeader('Authorization', authorizationHeader);
        // }
        request.setTimeout(120000);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('accept', '*/*');
        //request.setHeader('Origin', System.URL.getOrgDomainUrl().toExternalForm());//Added by kalpesh
        request.setMethod(method);
        System.debug('request : '+request);
        System.debug('Endpoint: ' + request.getEndpoint());
        System.debug('Method: ' + request.getMethod());
        System.debug('Body: ' + request.getBody());
        System.debug('xAuthKey: ' + xAuthKey);
        System.debug('authorizationHeader: ' + authorizationHeader);
        return http.send(request);                 
    }
}