/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 05-23-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class COMM_OCRController {
    @AuraEnabled
    public static String initiateAPIRequest(Map<String, String> inputMap){
        String retunrResp;
   // try {
            List<string> validatemandate = new List<string>();
            List<string> constructpayload = new List<string>();
            String resultMessage;
            String loanId = inputMap.get('loanId');
            String applicantId = inputMap.get('applicantId');
            String processName = inputMap.get('processName');
            String base64 = inputMap.get('contentId');
            String imageType = inputMap.get('docType');
            String fileName = inputMap.get('fileName');
            String contentVersionId = inputMap.get('contentVersionId');
            String documentId =  inputMap.get('documentId');
            String sector =  inputMap.get('sector');
            System.debug('sector-----' +sector);
            String setSource = 'OCR'; // Added by Anish for triangulation Object
            String uploadedFileName = inputMap.get('uploadedFileName') ;
            Boolean isConfirmed = inputMap.containsKey('panOCRConfirmed') && inputMap.get('panOCRConfirmed') == 'true';
            if (!Schema.sObjectType.Application_Applicant__c.isAccessible()) {
                throw new AuraHandledException('You do not have permission to access Application Applicant data.');
            }
            List<Application_Applicant__c> app =[Select id,Name,Aadhaar_First_Name__c,Aadhaar_Last_Name__c,Aadhaar_Middle_Name__c,Aadhaar_Number_Masked__c,IsForm60Uploaded__c,Pan_Name__c,PAN_Number__c,
                                                 Aadhaar_Number__c,Aadhaar_Pincode__c,Aadhaar_Gender__c,Customer_Type__c,Sector__c,Name_of_Organization__c,Applicant_Type__c from Application_Applicant__c where id =:applicantId];
            Map<String,API_Exceptions__mdt> allMetaData = API_Exceptions__mdt.getAll();
            
            //  ContentVersion cv = new ContentVersion();
            //  cv.Title = fileName;
            //  cv.PathOnClient = fileName;
            //  cv.VersionData = EncodingUtil.base64Decode(base64);
            //  cv.IsMajorVersion = true;
            //  insert cv;
            //system.debug('cv: '+cv);
            
            //  ContentVersion cvRec = [SELECT ContentDocumentId, FileType FROM ContentVersion WHERE Id =: cv.Id Limit 1];
            
            
            
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
                                                Activity_Name__c
                                                FROM Integration_Master__mdt 
                                                WHERE Activity_Name__c = :processName LIMIT 1];
            
            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
            
            wrapper.recordId =applicantId ;
            wrapper.loanApplicationId = loanId;  
            wrapper.type = processName;
            wrapper.endpoint = metadata.Endpoint__c;
            wrapper.requestMethod = metadata.Request_Method__c;
            wrapper.handlerClass = metadata.Handler_Class__c;
            wrapper.clientId = metadata.Client_Id__c;
            wrapper.clientSecret = metadata.Client_Secret__c;
            wrapper.allowedRetry = metadata.Allowed_Retry__c;
            wrapper.gestationPeriod = metadata.Gestation_Period__c;
            wrapper.activityname = metadata.Activity_Name__c;
            wrapper.refreshallowed = metadata.Refresh_Allowed__c;
            wrapper.handlername =  metadata.Handler_Class__c;
            wrapper.fileBase64 =  base64;
            wrapper.contentVersionId = contentVersionId;
            wrapper.docType =imageType;
            // Map<String,String> inputMapUtility = new  Map<String,String>();
            // Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
            // Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
            IntHandler.processResWrapper respWrapper;
            //IntHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                                                            FROM Integration_Settings__c WHERE Name = 'Loan Applicant OCR' LIMIT 1];
            
            Integration_Settings__c intSetting = intSettingList[0];
        /*
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name =processName ;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                retunrResp = resultMessage;
            }*/
            if(true){
                /*
                Map<String,String> integrationRequestMap = new Map<String,String>();
                String bearer = Utility.getAccessToken();
                integrationRequestMap.put('bearer', bearer);
                integrationRequestMap.put('intSettingName','Loan Applicant OCR');
                integrationRequestMap.put('requestJSON',respWrapper.payload);
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);*/
                 HttpResponse resp = new HttpResponse();
                resp.setStatusCode(200);
                resp.setHeader('Content-Type', 'application/json');
                System.debug('Response of Request-->'+resp.getBody());
                String jsonResp;
                System.debug('imageType : '+imageType);
                if(imageType =='PAN' ){ 
                     String mockResponse =
                    '{' +
                    '"requestId":"675ca3ae-512d-4f6e-9083-ad0c01b26d64",' +
                    '"result":{' +
                    '"documents":[' +
                    '{' +
                    '"documentType":"PAN",' +
                    '"subType":"",' +
                    '"pageNo":1,' +
                    '"ocrData":{' +
                    '"dob":{"value":"14/12/1980","confidence":1.0},' +
                    '"doi":{"value":"03/01/2024","confidence":1.0},' +
                    '"father":{"value":"RANGNATH NARAYAN DHAWAN","confidence":0.9},' +
                    '"name":{"value":"RAMESH RANGNATH DHAWAN","confidence":0.94},' +
                    '"pan":{"value":"AKQPD8335B","confidence":1.0}' +
                    '},' +
                    '"additionalDetails":{}' +
                    '}' +
                    ']' +
                    '},' +
                    '"statusCode":101' +
                    '}';
                
                resp.setBody(mockResponse);
                    COMM_PANOCRController.PanResponseWrapper panResp = new COMM_PANOCRController.PanResponseWrapper();
                    
                    // panResp = (PANOCRController.PanResponseWrapper)JSON.deserialize(jsonResp, PANOCRController.PanResponseWrapper.class);
                    
                    System.debug('panResp---'+panResp);
                    if(resp.getStatusCode()== 200){
                        panResp = (COMM_PANOCRController.PanResponseWrapper)JSON.deserialize(resp.getBody(), COMM_PANOCRController.PanResponseWrapper.class);
                        System.debug('panResp---'+panResp+'--------'+resp.getBody());
                        System.debug('panResp.statusCode---'+panResp.statusCode);
                        if(panResp.statusCode == 101){
                            String dobString =  panResp.result.documents[0].ocrData.dob.value;
                            String doiString = panResp.result.documents[0].ocrData.doi.value;
                            Date birthDate;
                            Date issueDate;
                            // }
                            // String dobString = panResp.result.documents[0].ocrData.dob.value; // "14/07/1966"
                            
                            // Split the string into day, month, and year
                            List<String> dateParts = dobString.split('/');
                            List<String> doiList = new List<String>();
                            if(doiString!= null && doiString!= ''){
                                doiList = doiString.split('/');
                            }
                            if (dateParts.size() == 3) {
                                String formattedDate = dateParts[2] + '-' + dateParts[1] + '-' + dateParts[0]; // "1966-07-14"
                                
                                try {
                                    birthDate = Date.valueOf(formattedDate);
                                    panResp.result.documents[0].ocrData.dob.value = formattedDate;
                                } catch (Exception e) {
                                    System.debug('Error converting date: ' + e.getMessage());
                                }
                            } else {
                                System.debug('Invalid date format received: ' + dobString);
                            }
                            if (doiList.size() == 3) {
                                String formattedDate = doiList[2] + '-' + doiList[1] + '-' + doiList[0]; // "1966-07-14"
                                
                                try {
                                    issueDate = Date.valueOf(formattedDate);
                                    panResp.result.documents[0].ocrData.doi.value = formattedDate;
                                } catch (Exception e) {
                                    System.debug('Error converting date: ' + e.getMessage());
                                }
                            } else {
                                System.debug('Invalid date format received: ' + dobString);
                            }
                            if (isConfirmed) {
                                if(app.size()>0){
                                    if(app[0].Customer_Type__c =='Individual'){
                                        //HL-Ishi-8/9/2025
                                        //if(!isHLRelated){
                                          //  app[0].Pan_Name__c = panResp.result.documents[0].ocrData.name.value;
                                            //app[0].PAN_DOB__c = birthDate;
                                        //}
                                        //else{
                                            List<String> nameParts = panResp.result.documents[0].ocrData.name.value.trim().split(' ');
                                            if (nameParts.size() == 3) {
                                                app[0].First_Name__c = nameParts[0];
                                                app[0].Middle_Name__c = nameParts[1];
                                                app[0].Last_Name__c = nameParts[2];
                                            } else if (nameParts.size() == 2) {
                                                app[0].First_Name__c = nameParts[0];
                                                app[0].Last_Name__c = nameParts[1];
                                            } else if (nameParts.size() == 1) {
                                                app[0].First_Name__c = nameParts[0];
                                            } 
                                        //}
                                        //HL-Ishi-8/9/2025
                                        
                                    }
                                    else if(app[0].Customer_Type__c =='Non Individual'){
                                        if(sector!='Proprietorship' && app[0].Applicant_Type__c!='Primary Applicant'){
                                            // app[0].Pan_Name__c = panResp.result.documents[0].ocrData.name.value;
                                            // app[0].PAN_DOB__c = birthDate;
                                        }
                                        // else
                                        // {
                                        //    app[0].Pan_Name__c = app[0].Name_of_Organization__c;
                                        // }
                                    }
                                    
                                    
                                    app[0].PAN_Number__c = panResp.result.documents[0].ocrData.pan.value;
                                    app[0].Pan_Father_s_Name__c = panResp.result.documents[0].ocrData.father.value;
                                    
                                    app[0].PAN_Date_of_Issue__c = issueDate;
                                    System.debug('app000000-----' +app);
                                    // app[0].PAN_DOB__c = Date.valueOf(panResp.result.documents[0].ocrData.dob.value);
                                    // app[0].PAN_Date_of_Issue__c = Date.valueOf(panResp.result.documents[0].ocrData.doi.value);
                                    update app;
                                }
                            }
                            retunrResp = JSON.serialize(panResp);
                            if (isConfirmed) {
                                
                                List<Triangulation_Data__c> triangulationDatas = [SELECT Id, Loan_Application__c, Application_Applicant__c, Pan__c, Name__c, Father__c, Date_Of_Birth__c, Date_Of_Issue__c FROM Triangulation_Data__c 
                                                                                  WHERE Loan_Application__c =: loanid AND Application_Applicant__c =: applicantId AND Source_Type__c =: setSource AND Document_Type__c =: imageType];
                                if(!triangulationDatas.isEmpty()) {
                                    triangulationDatas[0].Pan__c = getValueWithConfidence(panResp.result.documents[0].ocrData.pan.value, panResp.result.documents[0].ocrData.pan.confidence);
                                    triangulationDatas[0].Father__c = getValueWithConfidence(panResp.result.documents[0].ocrData.father.value, panResp.result.documents[0].ocrData.father.confidence);
                                    triangulationDatas[0].Name__c = getValueWithConfidence(panResp.result.documents[0].ocrData.name.value, panResp.result.documents[0].ocrData.name.confidence);
                                    triangulationDatas[0].Date_Of_Birth__c = getValueWithConfidence(panResp.result.documents[0].ocrData.dob.value, panResp.result.documents[0].ocrData.dob.confidence);
                                    triangulationDatas[0].Date_Of_Issue__c = getValueWithConfidence(panResp.result.documents[0].ocrData.doi.value, panResp.result.documents[0].ocrData.doi.confidence);
                                    
                                    update triangulationDatas;
                                }else {
                                    Triangulation_Data__c triangulationData = new Triangulation_Data__c();
                                    triangulationData.Pan__c = getValueWithConfidence(panResp.result.documents[0].ocrData.pan.value, panResp.result.documents[0].ocrData.pan.confidence);
                                    triangulationData.Father__c = getValueWithConfidence(panResp.result.documents[0].ocrData.father.value, panResp.result.documents[0].ocrData.father.confidence);
                                    triangulationData.Name__c = getValueWithConfidence(panResp.result.documents[0].ocrData.name.value, panResp.result.documents[0].ocrData.name.confidence);
                                    triangulationData.Date_Of_Birth__c = getValueWithConfidence(panResp.result.documents[0].ocrData.dob.value, panResp.result.documents[0].ocrData.dob.confidence);
                                    triangulationData.Date_Of_Issue__c = getValueWithConfidence(panResp.result.documents[0].ocrData.doi.value, panResp.result.documents[0].ocrData.doi.confidence);
                                    // parameter setting
                                    triangulationData.Application_Applicant__c = applicantId;
                                    triangulationData.Loan_Application__c = loanid;
                                    triangulationData.Source_Type__c = setSource;
                                    triangulationData.Document_Type__c = imageType;
                                    insert triangulationData;
                                }
                            }
                            
                            System.debug('resp---');
                            resultMessage = 'Sucess';
                        }
                        else{
                            retunrResp = 'Error:' + 'No Data from Ocr';
                        }
                    }
                    else if(resp.getStatusCode()== 503){
                        retunrResp = 'Error:' + 'Service Temporarily Unavailable';
                    }
                    else if(resp.getStatusCode()== 429){
                        retunrResp = 'Error:' + 'Too many Api requests';
                    }
                    else if(resp.getStatusCode()==502){
                        retunrResp = 'Error:' + 'Bad Gateway';
                    }
                    else{
                        
                        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                        String errorCode = (String) responseMap.get('error');
                        for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                            if(execeptionMeta.Error_Code__c == errorCode){
                                retunrResp = 'Error: ' + execeptionMeta.Error_Message__c;
                            }
                        }
                    }
                    //String newId = storOcrRequestandResponseAsFile(respWrapper.payload,imageType, resp.getBody(),applicantId,loanid);
                    String newId = 'NULL';
                    integrationDetail.Calling_Source__c = wrapper.type; 
                    integrationDetail.Request_JSON__c = newId; 
                    integrationDetail.Response_JSON__c = resp.getBody();
                    integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
                    integrationDetail.Method_Type__c = intSetting.Request_Method__c; 
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Name = processName; 
                    integrationDetail.Loan_Application__c = loanid;
                    insert integrationDetail;
                    
                }
                else if(imageType =='Aadhaar Back' ){
                    COMM_AadharBackController.AadharBackControllerResponseWrapper aadharBack = new  COMM_AadharBackController.AadharBackControllerResponseWrapper();
                    Boolean isValid = true;
                    List<Pincode_Master__c> pincodeList = new List<Pincode_Master__c>();
                    String pinCode;
                    //aadharFront = (AadharBackController.AadharBackControllerResponseWrapper)JSON.deserialize(jsonResp, AadharBackController.AadharBackControllerResponseWrapper.class);
      
                    System.debug('resp.getBody()----'+ resp.getBody());
                    System.debug('imageType back : '+ imageType);
                    System.debug('resp.getStatusCode()----'+ resp.getStatusCode());
                    String newId = storOcrRequestandResponseAsFile(respWrapper.payload,imageType, resp.getBody(),applicantId,loanid);
                    if(resp.getStatusCode()== 200){
                        // integrationDetail.Response_JSON__c =jsonResp; 
                        integrationDetail.Status__c ='200'; 
                        integrationDetail.Method_Type__c = intSetting.Request_Method__c; 
                        integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                        integrationDetail.Object_Name__c = 'Application_Applicant__c';
                        integrationDetail.Related_Record_Id__c = applicantId;
                        integrationDetail.Name = 'Loan OCR Aadhar Back'; 
                        integrationDetail.Request_JSON__c = newId; 
                        integrationDetail.Loan_Application__c = loanid;
                        insert integrationDetail;
                        aadharBack = (COMM_AadharBackController.AadharBackControllerResponseWrapper)JSON.deserialize(resp.getBody(), COMM_AadharBackController.AadharBackControllerResponseWrapper.class);
                        retunrResp = JSON.serialize(aadharBack);
                        System.debug('retunrResp Aadhaar back : '+retunrResp);
                        String aadhaarNumber = aadharBack.result.documents[0]?.ocrData?.aadhaar?.value.trim();
                        pinCode = aadharBack?.result?.documents[0]?.additionalDetails?.addressSplit?.pin!=null?aadharBack.result.documents[0].additionalDetails.addressSplit.pin:'';
                        if (String.isNotBlank(pinCode) && Schema.sObjectType.Pincode_Master__c.isAccessible()) {
                            pincodeList = [
                                SELECT Id, Name FROM Pincode_Master__c WHERE Name = :pinCode LIMIT 1
                            ];
                        }
                        System.debug('debug aadhaarNumber : '+aadhaarNumber);
                        System.debug('Utility.getDecryptedBase64String(app[0].Aadhaar_Number__c) : '+Utility.getDecryptedBase64String(app[0].Aadhaar_Number__c));
          /*if(app[0].Aadhaar_Number__c != null && app[0].Aadhaar_Number__c != aadhaarNumber){
                retunrResp = 'Error: Aadhaar Number MisMatch,Please Upload Correct File';
                return retunrResp; 
          } */
                        /*
                        if(app[0].Aadhaar_Number__c == null){
                            retunrResp = 'Error: Please Upload Front Image First';
                            return retunrResp; 
                        }
                        */
                    }
                    else if(resp.getStatusCode()== 503){
                        retunrResp = 'Error:' + 'Service Temporarily Unavailable';
                        // app[0].Aadhar_Masked_Source__c= 'Manual';
                        update app;
                        
                        List<Triangulation_Data__c> triangulationDatas = [SELECT Id, Loan_Application__c, Application_Applicant__c, Aadhar__c, Address__c, Name__c FROM Triangulation_Data__c 
                                                                          WHERE Loan_Application__c =: loanid AND Application_Applicant__c =: applicantId AND Source_Type__c =: 'Aadhar' AND Document_Type__c =: imageType];
                        if(!triangulationDatas.isEmpty()) {
                            triangulationDatas[0].Address__c = getValueWithConfidence(aadharBack.result.documents[0].ocrData.address.value, aadharBack.result.documents[0].ocrData.address.confidence);
                            update triangulationDatas;
                        } else {
                            Triangulation_Data__c triangulationData = new Triangulation_Data__c();
                            if(!Test.isrunningtest()){
                                triangulationData.Address__c = getValueWithConfidence(aadharBack.result.documents[0].ocrData.address.value, aadharBack.result.documents[0].ocrData.address.confidence);   
                            }                                                
                            triangulationData.Application_Applicant__c = applicantId;
                            triangulationData.Loan_Application__c = loanid;
                            triangulationData.Source_Type__c = setSource;
                            triangulationData.Document_Type__c = 'Aadhar Back';
                            insert triangulationData;
                        }
                        
                        List<ContentDocument> docList = [
                            SELECT Id FROM ContentDocument 
                            WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId)
                        ];
                        
                        if (!docList.isEmpty()) {
                            delete docList;  // This will delete associated ContentVersion(s) as well
                            System.debug('Deleted ContentDocument: ' + docList);
                        }
                        
                        if(documentId!= null){
                            Document_Details__c document= new Document_Details__c();
                            document.Content_Document_Id__c = null;
                            document.Id= documentId;
                            document.Status__c = '';
                            document.Aadhar_Masked_Source__c= 'Manual';
                            update document;
                        }
                    }
                    else if(resp.getStatusCode()== 429){
                        retunrResp = 'Error:' + 'Too many Api requests';
                    }
                    else{
                        try {
                            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                            String errorCode = (String) responseMap.get('error');
                            for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                                if(execeptionMeta.Error_Code__c == errorCode){
                                    retunrResp = 'Error: ' + execeptionMeta.Error_Message__c; 
                                }
                                else{
                                    retunrResp = 'Error:' + 'Please try again later.';
                                } 
                            }
                        } catch (Exception ex) {
                            System.debug('ex '+ex);
                            retunrResp = 'Error:' + 'Please try again later.';
                        }
                        //  app[0].Aadhar_Masked_Source__c= 'Manual';
                        // update app;
                        List<ContentDocument> docList = [
                            SELECT Id FROM ContentDocument 
                            WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId)
                        ];
                        
                        if (!docList.isEmpty()) {
                            delete docList;  // This will delete associated ContentVersion(s) as well
                            System.debug('Deleted ContentDocument: ' + docList);
                        }
                        
                        if(documentId!= null){
                            Document_Details__c document= new Document_Details__c();
                            document.Content_Document_Id__c = null;
                            document.Id= documentId;
                            document.Status__c = 'Pending';
                            document.Aadhar_Masked_Source__c= 'Manual';
                            update document;
                        }
                    }
                    System.debug('aadharBack---'+aadharBack);
                    if(resp.getStatusCode()== 200){
                        String responseBody = resp.getBody();
                        Map<String, Object> parsedJson1 = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                        List<Object> documentcheck = (List<Object>) ((Map<String, Object>) parsedJson1.get('result')).get('documents');
                        
                        for (Object docObj : documentcheck) {
                            Map<String, Object> doc = (Map<String, Object>) docObj;
                            String subType = (String) doc.get('subType');
                            if (subType == 'FRONT_TOP' || subType == 'FRONT_BOTTOM') {
                                isValid = false;
                                break;
                            }
                        }
                        if(isValid){
                            Boolean maskedStatus = aadharBack.result.documents[0]?.additionalDetails?.outputMaskStatus;
                            System.debug('maskedStatus---'+maskedStatus);
                            System.debug('maskedStatus---'+aadharBack.result.documents[0].documentBase64);
                            System.debug('maskedStatus---'+aadharBack.result.fileBase64);
                            if(maskedStatus!= null && maskedStatus && ((aadharBack.result.documents[0]?.documentBase64!=null && aadharBack.result.documents[0].documentBase64!='')||(aadharBack.result.fileBase64!=null && aadharBack.result.fileBase64!='') )){
                                app[0].Id = applicantId;
                                app[0].Loan_Application__c = loanid;
                                // app[0].Aadhaar_Number_Masked__c=Utility.getEncryptedBase64String(aadharBack.result.documents[0].ocrData.aadhaar.value);
                                System.debug('encryptedd--'+app[0].Aadhaar_Number_Masked__c);
                                app[0].Aadhaar_Address__c =aadharBack.result.documents[0].ocrData.address.value;
                                app[0].Aadhaar_Pincode__c = pincodeList.isEmpty() ? null : pincodeList[0].Id;
                                // app[0].Aadhar_Masked_Source__c= 'API';
                                // Applicant_Address__c add = new Applicant_Address__c();
                                // add.Type__c = 'Permanent Address';
                                
                                
                                update app;
                                
                                List<ContentDocument> docList = [
                                    SELECT Id FROM ContentDocument 
                                    WHERE Id=:contentVersionId
                                ];
                                
                                if (!docList.isEmpty()) {
                                    //delete docList;  // This will delete associated ContentVersion(s) as well
                                    System.debug('Deleted ContentDocument: ' + docList);
                                }
                                
                                //String base64Data= aadharBack.result.documents[0].documentBase64;
                                String base64Data = aadharBack.result.documents[0].documentBase64 != null
                                    ? aadharBack.result.documents[0].documentBase64
                                    : (aadharBack.result.fileBase64 != null
                                       ? aadharBack.result.fileBase64
                                       : null);
                                           ContentVersion cv = new ContentVersion();
                                cv.Title = uploadedFileName;
                                cv.PathOnClient = uploadedFileName;
                                cv.VersionData = EncodingUtil.base64Decode(base64Data);
                                cv.IsMajorVersion = true;
                                insert cv;
                                
                                ContentVersion cvRec = [SELECT Id, ContentDocumentId, FileType FROM ContentVersion WHERE Id =: cv.Id Limit 1];
                                retunrResp = retunrResp + cvRec;
                                if(documentId!= null){
                                    Document_Details__c document= new Document_Details__c();
                                    document.Content_Document_Id__c = cvRec.ContentDocumentId;
                                    document.Id= documentId;
                                    document.Status__c = Constants.STATUS_UPLOADED;
                                    document.Aadhar_Masked_Source__c= 'API';
                                    update document;
                                    ContentDocumentLink cdl = new ContentDocumentLink();
                                    cdl.LinkedEntityId = documentId;
                                    cdl.ContentDocumentId = cvRec.ContentDocumentId;
                                    cdl.ShareType = 'V';
                                    cdl.Visibility = 'AllUsers';
                                    insert cdl;
                                }
                                
                            }else{
                                retunrResp = 'Error: Aadhar has not been masked properly. Please upload the masked aadhar document.';
                                // app[0].Aadhar_Masked_Source__c= 'Manual';
                                update app;
                                List<ContentDocument> docList = [
                                    SELECT Id FROM ContentDocument 
                                    WHERE Id=:contentVersionId
                                ];
                                
                                if (!docList.isEmpty()) {
                                    //delete docList;  // This will delete associated ContentVersion(s) as well
                                    System.debug('Deleted ContentDocument: ' + docList);
                                }
                                
                                if(documentId!= null){
                                    Document_Details__c document= new Document_Details__c();
                                    document.Content_Document_Id__c = null;
                                    document.Id= documentId;
                                    document.Status__c = 'Pending';
                                    document.Aadhar_Masked_Source__c= 'Manual';
                                    update document;
                                }
                            }
                            // System.debug('Aadhar Addresss------------------------ 677 '+ aadharBack.result.documents[0].additionalDetails.addressSplit.building);
                            if(aadharBack.result.documents[0].additionalDetails?.addressSplit?.building != null ||
                               aadharBack.result.documents[0].additionalDetails?.addressSplit?.floor != null ||
                               aadharBack.result.documents[0].additionalDetails?.addressSplit?.house != null) {

                                   Applicant_Address__c addressAadhar = new Applicant_Address__c();
                                   
                                   String building = aadharBack.result.documents[0].additionalDetails.addressSplit.building;
                                   String floor = aadharBack.result.documents[0].additionalDetails.addressSplit.floor;
                                   String house = aadharBack.result.documents[0].additionalDetails.addressSplit.house;
                                   String street = aadharBack.result.documents[0].additionalDetails.addressSplit.street;
                                   String locality = aadharBack.result.documents[0].additionalDetails.addressSplit.locality;
                                   String city = aadharBack.result.documents[0].additionalDetails.addressSplit.city;
                                   String district = aadharBack.result.documents[0].additionalDetails.addressSplit.district;
                                   String state = aadharBack.result.documents[0].additionalDetails.addressSplit.state;
                                   //String pinCode = aadharBack.result.documents[0].additionalDetails.addressSplit.pin;
                                   addressAadhar.Address_Line_1__c = String.join(new List<String>{house, floor, building}, ', ');
                                   addressAadhar.Address_Line_2__c = String.join(new List<String>{street, locality}, ', ');
                                   addressAadhar.Address_Line_3__c = String.join(new List<String>{ district, city,state}, ', ');
                                   addressAadhar.Address_Source__c = 'Aadhaar';
                                   addressAadhar.Document_Details__c =  documentId;

                                  List<Applicant_Address__c> existingAadhaarAddr = [ SELECT Id FROM Applicant_Address__c WHERE Applicant__c = :applicantId AND Address_Source__c = 'Aadhaar' LIMIT 1];
                                   
                                   for (String line : new List<String>{addressAadhar.Address_Line_1__c, addressAadhar.Address_Line_2__c, addressAadhar.Address_Line_3__c}) {
                                       if (String.isNotBlank(line)) {
                                           line = line.replaceAll('^,\\s*|\\s*,\\s*$',''); 
                                       }
                                   }
                                   
                                   if (String.isNotBlank(pinCode)) {
                                       /* List<Pincode_Master__c> pincodeList = [
SELECT Id, Name FROM Pincode_Master__c WHERE Name = :pinCode LIMIT 1
]; */
                                       if (!pincodeList.isEmpty()) {
                                           addressAadhar.Pincode__c = pincodeList[0].id;
                                       }
                                       else {
                                           retunrResp = 'Error: Pincode is not available in the database,Please Contact System Administrator';
                                           return retunrResp;
                                       }
                                   }
            /*
                                   addressAadhar.Applicant__c =applicantId;
                                   System.debug('addressAadhar------- 677 '+ addressAadhar);
            insert addressAadhar;
            */
            if (existingAadhaarAddr.isEmpty()) {
                addressAadhar.Applicant__c = applicantId;
                System.debug('addressAadhar (insert) ------- 677 ' + addressAadhar);
                insert addressAadhar;
            } else {
                addressAadhar.Id = existingAadhaarAddr[0].Id;
                System.debug('addressAadhar (update) ------- 677 ' + addressAadhar);
                update addressAadhar;
            }
                               }
                        }
                        else{
                            retunrResp = 'Error: Please upload Aadhaar Back document only.';
                            // app[0].Aadhar_Masked_Source__c= 'Manual';
                            update app;
                            List<ContentDocument> docList = [
                                SELECT Id FROM ContentDocument 
                                WHERE Id=:contentVersionId
                            ];
                            
                            if (!docList.isEmpty()) {
                                delete docList;  // This will delete associated ContentVersion(s) as well
                                System.debug('Deleted ContentDocument: ' + docList);
                            }
                        }
                    }
                }
                else if (imageType == 'Aadhaar Front') {
                    Boolean isValid = true;
                    System.debug('contentVersionId : '+contentVersionId);
                    COMM_AadharFrontTopController.AadharFrontTopResponseWrapper aadharFrontTop = new COMM_AadharFrontTopController.AadharFrontTopResponseWrapper();
                    COMM_AadharFrontBottomController.AadharFrontBottomResponseWrapper aadharFrontBottom = new COMM_AadharFrontBottomController.AadharFrontBottomResponseWrapper();
                    System.debug('resp.getBody()---- 607' + resp.getBody());
                    if (resp.getStatusCode() == 200) {
                        String responseBody = resp.getBody();
                        Map<String, Object> parsedJson1 = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                        List<Object> documentcheck = (List<Object>) ((Map<String, Object>) parsedJson1.get('result')).get('documents');
                        
                        for (Object docObj : documentcheck) {
                            Map<String, Object> doc = (Map<String, Object>) docObj;
                            String subType = (String) doc.get('subType');
                            if (subType == 'BACK') {
                                isValid = false;
                                break;
                            }
                        }
                        if (isValid) {
                            Map<String, Object> parsedJson2 = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                            List<Object> documents = (List<Object>) ((Map<String, Object>) parsedJson2.get('result')).get('documents');
                            if (!documents.isEmpty()) {
                                Map<String, Object> firstDoc = (Map<String, Object>) documents[0];
                                String subType = (String) firstDoc.get('subType');
                                System.debug('subType Aadhaar: '+subType);
                                if (subType == 'FRONT_TOP') {
                                    aadharFrontTop = (COMM_AadharFrontTopController.AadharFrontTopResponseWrapper) JSON.deserialize(responseBody, COMM_AadharFrontTopController.AadharFrontTopResponseWrapper.class);
                                    retunrResp = JSON.serialize(aadharFrontTop);
                                    Boolean maskedStatus = aadharFrontTop.result.documents[0].additionalDetails.outputMaskStatus;
                                    if (maskedStatus) {
                                        app[0].Id = applicantId;
                                        app[0].Loan_Application__c = loanid;
                                        app[0].Aadhaar_Number_Masked__c = Utility.getEncryptedBase64String(aadharFrontTop.result.documents[0].ocrData.aadhaar.value);
                                        app[0].Aadhaar_Number__c = aadharFrontTop.result.documents[0].ocrData.aadhaar.value;
                                        app[0].Aadhaar_Address__c = aadharFrontTop.result.documents[0].ocrData.address.value;
                                        String fullName = aadharFrontTop.result.documents[0].ocrData.name.value.trim();
                                        List<String> nameParts = fullName.split(' ');
                                        // if(app[0].Pan_Number__c!= null && app[0].Pan_Name__c != fullName){
                                        //   retunrResp = 'Error: Name MisMatch With the Applicant Name';
                                        //   return retunrResp; 
                                        // }
                                        if (nameParts.size() == 3) {
                                            app[0].Aadhaar_First_Name__c = nameParts[0];
                                            app[0].Aadhaar_Middle_Name__c = nameParts[1];
                                            app[0].Aadhaar_Last_Name__c = nameParts[2];
                                        } else if (nameParts.size() == 2) {
                                            app[0].Aadhaar_First_Name__c = nameParts[0];
                                            app[0].Aadhaar_Last_Name__c = nameParts[1];
                                        } else if (nameParts.size() == 1) {
                                            app[0].Aadhaar_First_Name__c = nameParts[0];
                                        }
                                        update app;
                                        List<ContentDocument> docList = [
                                            SELECT Id FROM ContentDocument 
                                            WHERE Id=:contentVersionId
                                        ];
                                        System.debug('docList : '+docList);
                                        if (!docList.isEmpty()) {
                                            System.debug('Deleted ContentDocument: ' + docList);
                                            delete docList;
                                            
                                        }
                                        //String base64Data = aadharFrontTop.result.documents[0].documentBase64; // You need to get actual base64 data from documentLink or other source
                                        // String base64Data = !String.isBlank(aadharFrontTop.result.documents[0].documentBase64) ?
                                        // aadharFrontTop.result.documents[0].documentBase64 :
                                        // (!String.isBlank(aadharFrontTop.result.documents[0].fileBase64) ?
                                        // aadharFrontTop.result.documents[0].fileBase64 : null);
                                        String base64Data = aadharFrontTop.result.documents[0].documentBase64 != null
                                            ? aadharFrontTop.result.documents[0].documentBase64
                                            : (aadharFrontTop.result.fileBase64 != null
                                               ? aadharFrontTop.result.fileBase64
                                               : null);
                                                   ContentVersion cv = new ContentVersion();
                                        cv.Title = uploadedFileName;
                                        cv.PathOnClient = uploadedFileName;
                                        cv.VersionData = EncodingUtil.base64Decode(base64Data);
                                        cv.IsMajorVersion = true;
                                        insert cv;
                                        ContentVersion cvRec = [SELECT Id, ContentDocumentId, FileType FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
                                          retunrResp = retunrResp + cvRec;
                                        if (documentId != null) {
                                            Document_Details__c document = new Document_Details__c();
                                            document.Id = documentId;
                                            document.Content_Document_Id__c = cvRec.ContentDocumentId;
                                            document.Status__c = Constants.STATUS_UPLOADED;
                                            document.Aadhar_Masked_Source__c = 'API';
                                            update document;
                                        }
                                        if (aadharFrontTop.result.documents[0].additionalDetails.addressSplit != null) {
                                            Applicant_Address__c addressAadhar = new Applicant_Address__c();
                                            addressAadhar.Address_Line_1__c = String.join(new List<String>{
                                                aadharFrontTop.result.documents[0].additionalDetails.addressSplit.house,
                                                    aadharFrontTop.result.documents[0].additionalDetails.addressSplit.floor,
                                                    aadharFrontTop.result.documents[0].additionalDetails.addressSplit.building
                                                    }, ', ');
                                            addressAadhar.Address_Line_2__c = String.join(new List<String>{
                                                aadharFrontTop.result.documents[0].additionalDetails.addressSplit.street,
                                                    aadharFrontTop.result.documents[0].additionalDetails.addressSplit.locality
                                                    }, ', ');
                                            addressAadhar.Address_Line_3__c = String.join(new List<String>{
                                                aadharFrontTop.result.documents[0].additionalDetails.addressSplit.district,
                                                    aadharFrontTop.result.documents[0].additionalDetails.addressSplit.city,
                                                    aadharFrontTop.result.documents[0].additionalDetails.addressSplit.state
                                                    }, ', ');
                                            addressAadhar.Address_Source__c = 'Aadhaar';
                                            for (String line : new List<String>{
                                                addressAadhar.Address_Line_1__c,
                                                    addressAadhar.Address_Line_2__c,
                                                    addressAadhar.Address_Line_3__c
                                                    }) {
                                                        if (String.isNotBlank(line)) {
                                                            line = line.replaceAll('^,\\s*|\\s*,\\s*$', '');
                                                        }
                                                    }
                                            String pinCode = aadharFrontTop.result.documents[0].additionalDetails.addressSplit.pin;
                                            if (String.isNotBlank(pinCode)) {
                                                List<Pincode_Master__c> pincodeList = [
                                                    SELECT Id, Name FROM Pincode_Master__c WHERE Name = :pinCode LIMIT 1
                                                ];
                                                if (!pincodeList.isEmpty()) {
                                                    addressAadhar.Pincode__c = pincodeList[0].Id;
                                                }
                                            }
                                            
                                            addressAadhar.Applicant__c = applicantId;
                                            System.debug('addressAadhar------- 677 ' + addressAadhar);
                                            insert addressAadhar;
                                        }
                                    } else {
                                        retunrResp = 'Error: Aadhar has not been masked properly. Please upload the masked aadhar document.';
                                        update app;
                                        List<ContentDocument> docList = [
                                            SELECT Id FROM ContentDocument 
                                            WHERE Id=:contentVersionId
                                        ];
                                        if (!docList.isEmpty()) {
                                            System.debug('Deleted ContentDocument: ' + docList);
                                            delete docList;
                                        }
                                        System.debug('docList : '+docList);
                                        
                                        if (documentId != null) {
                                            Document_Details__c document = new Document_Details__c();
                                            document.Id = documentId;
                                            document.Content_Document_Id__c = null;
                                            document.Status__c = 'Pending';
                                            document.Aadhar_Masked_Source__c = 'Manual';
                                            update document;
                                        }
                                    }
                                    List<Triangulation_Data__c> triangulationDatas = [SELECT Id, Loan_Application__c, Application_Applicant__c, Aadhar__c, Address__c, Name__c FROM Triangulation_Data__c 
                                                                                      WHERE Loan_Application__c =: loanid AND Application_Applicant__c =: applicantId AND Source_Type__c =: 'Aadhar' AND Document_Type__c =: imageType];
                                    if(!triangulationDatas.isEmpty()) {
                                        triangulationDatas[0].Aadhar__c = getValueWithConfidence(aadharFrontTop.result.documents[0].ocrData.aadhaar.value, aadharFrontTop.result.documents[0].ocrData.aadhaar.confidence);
                                        triangulationDatas[0].Name__c = getValueWithConfidence(aadharFrontTop.result.documents[0].ocrData.name.value, aadharFrontTop.result.documents[0].ocrData.name.confidence);
                                        triangulationDatas[0].Address__c = getValueWithConfidence(aadharFrontTop.result.documents[0].ocrData.address.value, aadharFrontTop.result.documents[0].ocrData.address.confidence);
                                        update triangulationDatas;
                                    } else {
                                        Triangulation_Data__c triangulationData = new Triangulation_Data__c();
                                        triangulationData.Aadhar__c = getValueWithConfidence(aadharFrontTop.result.documents[0].ocrData.aadhaar.value, aadharFrontTop.result.documents[0].ocrData.aadhaar.confidence);
                                        triangulationData.Name__c = getValueWithConfidence(aadharFrontTop.result.documents[0].ocrData.name.value, aadharFrontTop.result.documents[0].ocrData.name.confidence);
                                        triangulationData.Address__c = getValueWithConfidence(aadharFrontTop.result.documents[0].ocrData.address.value, aadharFrontTop.result.documents[0].ocrData.address.confidence);
                                        triangulationData.Application_Applicant__c = applicantId;
                                        triangulationData.Loan_Application__c = loanid;
                                        triangulationData.Source_Type__c = setSource;
                                        triangulationData.Document_Type__c = 'Aadhar Front Top';
                                        insert triangulationData;
                                    }
                                } else if (subType == 'FRONT_BOTTOM') {
                                    aadharFrontBottom = (COMM_AadharFrontBottomController.AadharFrontBottomResponseWrapper) JSON.deserialize(responseBody, COMM_AadharFrontBottomController.AadharFrontBottomResponseWrapper.class);
                                    retunrResp = JSON.serialize(aadharFrontBottom);
                                    System.debug('aadhar number in response---'+aadharFrontBottom.result.documents[0].ocrData.aadhaar.value);
                                    Boolean maskedStatus= aadharFrontBottom.result.documents[0].additionalDetails.outputMaskStatus;
                                    List<String> dobParts = aadharFrontBottom.result.documents[0].ocrData.dob.value.split('/');
                                    String fullName = aadharFrontBottom.result.documents[0].ocrData.name.value.trim();
                                    List<String> nameParts = fullName.split(' ');
                                    // if(app[0].Pan_Number__c!= null && app[0].Pan_Name__c != fullName){
                                    //     retunrResp = 'Error: Name MisMatch With the Applicant Name';
                                    //     return retunrResp; 
                                    //   }
                                    // if(app[0].Pan_Number__c == null && app[0].IsForm60Uploaded__c == 'Yes' && app[0].Name!= fullName){
                                    //     retunrResp = 'Error: Name MisMatch With the Applicant Name';
                                    //     return retunrResp; 
                                    // } 
                                    if(maskedStatus){
                                        app[0].Id = applicantId;
                                        app[0].Loan_Application__c = loanid;
                                        // app[0].Aadhar_Masked_Source__c= 'API';
                                        app[0].Aadhaar_Number_Masked__c=Utility.getEncryptedBase64String(aadharFrontBottom.result.documents[0].ocrData.aadhaar.value);
                                        app[0].Masked_Aadhar_Number__c = aadharFrontBottom.result.documents[0].ocrData.aadhaar.value;
                                        app[0].Aadhaar_Gender__c = aadharFrontBottom.result.documents[0].ocrData.gender.value;
                                        if (nameParts.size() == 3) {
                                            app[0].Aadhaar_First_Name__c = nameParts[0];
                                            app[0].Aadhaar_Middle_Name__c = nameParts[1];
                                            app[0].Aadhaar_Last_Name__c = nameParts[2];
                                        } else if (nameParts.size() == 2) {
                                            app[0].Aadhaar_First_Name__c = nameParts[0];
                                            app[0].Aadhaar_Last_Name__c = nameParts[1];
                                        } else if (nameParts.size() == 1) {
                                            app[0].Aadhaar_First_Name__c = nameParts[0];
                                        }
                                        if (dobParts.size() == 3) {
                                            app[0].Aadhaar_DOB__c = Date.valueOf(dobParts[2] + '-' + dobParts[1] + '-' + dobParts[0]);
                                        }
                                        System.debug('encryptedd--'+app[0].Aadhaar_Number_Masked__c);
                                        System.debug('decryptedd---'+ Utility.getDecryptedBase64String(Utility.getEncryptedBase64String(aadharFrontBottom.result.documents[0].ocrData.aadhaar.value)));
                                        update app;
                                        List<ContentDocument> docList = [
                                            SELECT Id FROM ContentDocument 
                                            WHERE Id=:contentVersionId
                                        ];
                                        if (!docList.isEmpty()) {
                                            System.debug('Deleted ContentDocument: ' + docList);
                                            delete docList;  // This will delete associated ContentVersion(s) as well
                                            
                                        }
                                        //String base64Data= aadharFrontBottom.result.documents[0].documentBase64;
                                        String base64Data = aadharFrontBottom.result.documents[0].documentBase64 != null
                                            ? aadharFrontBottom.result.documents[0].documentBase64
                                            : (aadharFrontBottom.result.fileBase64 != null
                                               ? aadharFrontBottom.result.fileBase64
                                               : null);
                                                   // String base64Data = !String.isBlank(aadharFrontBottom.result.documents[0].documentBase64) ?
                                                   // aadharFrontBottom.result.documents[0].documentBase64 :
                                                   // (!String.isBlank(aadharFrontBottom.result.documents[0].fileBase64) ?
                                                   // aadharFrontBottom.result.documents[0].fileBase64 : null);
                                                   System.debug('uploadedFileName- at 661---'+uploadedFileName);
                                        System.debug('base64Data : '+base64Data);
                                        ContentVersion cv = new ContentVersion();
                                        cv.Title = uploadedFileName;
                                        cv.PathOnClient = uploadedFileName;
                                        cv.VersionData = EncodingUtil.base64Decode(base64Data);
                                        cv.IsMajorVersion = true;
                                        insert cv;
                                        ContentVersion cvRec = [SELECT Id, ContentDocumentId, FileType FROM ContentVersion WHERE Id =: cv.Id Limit 1];
                                        retunrResp = retunrResp + cvRec;
                                        ContentDocumentLink cdl = new ContentDocumentLink();
                                        cdl.LinkedEntityId = documentId;
                                        cdl.ContentDocumentId = cvRec.ContentDocumentId;
                                        cdl.ShareType = 'V';
                                        cdl.Visibility = 'AllUsers';
                                        insert cdl;
                                        if(documentId!= null){
                                            Document_Details__c document= new Document_Details__c();
                                            document.Content_Document_Id__c = cvRec.ContentDocumentId;
                                            document.Id= documentId;
                                            document.Status__c = Constants.STATUS_UPLOADED;
                                            document.Aadhar_Masked_Source__c= 'API';
                                            update document;
                                        }
                                        List<Triangulation_Data__c> triangulationDatas = [SELECT Id, Loan_Application__c, Application_Applicant__c, Aadhar__c, Address__c, Name__c FROM Triangulation_Data__c 
                                                                                          WHERE Loan_Application__c =: loanid AND Application_Applicant__c =: applicantId AND Source_Type__c =: 'Aadhar' AND Document_Type__c =: imageType];
                                        if(!triangulationDatas.isEmpty()) {
                                            triangulationDatas[0].Aadhar__c = getValueWithConfidence(aadharFrontBottom.result.documents[0].ocrData.aadhaar.value, aadharFrontBottom.result.documents[0].ocrData.aadhaar.confidence);
                                            triangulationDatas[0].Name__c = getValueWithConfidence(aadharFrontBottom.result.documents[0].ocrData.name.value, aadharFrontBottom.result.documents[0].ocrData.name.confidence);
                                            
                                            update triangulationDatas;
                                        } else {
                                            Triangulation_Data__c triangulationData = new Triangulation_Data__c();
                                            triangulationData.Aadhar__c = getValueWithConfidence(aadharFrontBottom.result.documents[0].ocrData.aadhaar.value, aadharFrontBottom.result.documents[0].ocrData.aadhaar.confidence);
                                            triangulationData.Name__c = getValueWithConfidence(aadharFrontBottom.result.documents[0].ocrData.name.value, aadharFrontBottom.result.documents[0].ocrData.name.confidence);
                                            triangulationData.Application_Applicant__c = applicantId;
                                            triangulationData.Loan_Application__c = loanid;
                                            triangulationData.Source_Type__c = setSource;
                                            triangulationData.Document_Type__c = 'Aadhar Front Bottom';
                                            insert triangulationData;
                                        }
                                    }else{
                                        retunrResp = 'Error: Aadhar has not been masked properly. Please upload the masked aadhar document.';
                                        // app[0].Aadhar_Masked_Source__c= 'Manual';
                                        update app;
                                        List<ContentDocument> docList = [
                                            SELECT Id FROM ContentDocument 
                                            WHERE Id = :contentVersionId
                                        ];
                                        if (!docList.isEmpty()) {
                                            System.debug('Deleted ContentDocument: ' + docList);
                                            delete docList;  // This will delete associated ContentVersion(s) as well
                                            
                                        }
                                        if(documentId!= null){
                                            Document_Details__c document= new Document_Details__c();
                                            document.Content_Document_Id__c = null;
                                            document.Id= documentId;
                                            document.Status__c = '';
                                            document.Aadhar_Masked_Source__c= 'Manual';
                                            update document;
                                        }
                                    }
                                } else {
                                    retunrResp = 'Error:We are currently unable to process the type of Aadhar document uploaded. Kindly upload Aadhar front and Aadhar back separately in respective placeholders.';
                                    List<ContentDocument> docList = [
                                        SELECT Id FROM ContentDocument 
                                        WHERE Id=:contentVersionId
                                    ];
                                    if (!docList.isEmpty()) {
                                        System.debug('Deleted ContentDocument: ' + docList);
                                        delete docList;
                                    }
                                    
                                    if (documentId != null) {
                                        Document_Details__c document = new Document_Details__c();
                                        document.Id = documentId;
                                        document.Content_Document_Id__c = null;
                                        document.Status__c = 'Pending';
                                        // document.Aadhar_Masked_Source__c = 'Manual';
                                        update document;
                                    }
                                }
                            }
                        }
                        else{
                            retunrResp = 'Error:Kindly upload Aadhaar Front Top or Aadhaar Front Bottom';
                            List<ContentDocument> docList = [
                                SELECT Id FROM ContentDocument 
                                WHERE Id=:contentVersionId
                            ];
                            if (!docList.isEmpty()) {
                                System.debug('Deleted ContentDocument: ' + docList);
                                delete docList;
                            }
                            System.debug('docList : '+docList);
                            
                            if (documentId != null) {
                                Document_Details__c document = new Document_Details__c();
                                document.Id = documentId;
                                document.Content_Document_Id__c = null;
                                document.Status__c = '';
                                document.Aadhar_Masked_Source__c = 'Manual';
                                update document;
                            }
                        }
                    } else if (resp.getStatusCode() == 503) {
                        retunrResp = 'Error: Service Temporarily Unavailable';
                        update app;
                        List<ContentDocument> docList = [
                            SELECT Id FROM ContentDocument 
                            WHERE Id=:contentVersionId
                        ];
                        if (!docList.isEmpty()) {
                            delete docList;
                        }
                        if (documentId != null) {
                            Document_Details__c document = new Document_Details__c();
                            document.Id = documentId;
                            document.Content_Document_Id__c = null;
                            document.Status__c = '';
                            document.Aadhar_Masked_Source__c = 'Manual';
                            update document;
                        }
                    } 
                    else if(resp.getStatusCode()== 429){
                        retunrResp = 'Error:' + 'Too many Api requests';
                    }
                    else {
                        try {
                            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                            String errorCode = (String) responseMap.get('status');
                            for (API_Exceptions__mdt execeptionMeta : allMetaData.values()) {
                                if (execeptionMeta.Error_Code__c == errorCode) {
                                    retunrResp = 'Error: ' + execeptionMeta.Error_Message__c;
                                } else {
                                    retunrResp = 'Error: Please try again later.';
                                }
                            }
                        } catch (Exception ex) {
                            System.debug('ex ' + ex);
                            retunrResp = 'Error: Please try again later.';
                        }
                        
                        // update app;
                        List<ContentDocument> docList = [
                            SELECT Id FROM ContentDocument 
                            WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId)
                        ];
                        if (!docList.isEmpty()) {
                            delete docList;
                        }
                        if (documentId != null) {
                            Document_Details__c document = new Document_Details__c();
                            document.Id = documentId;
                            document.Content_Document_Id__c = null;
                            document.Status__c = '';
                            document.Aadhar_Masked_Source__c = 'Manual';
                            update document;
                        }
                    }
                    String newId = storOcrRequestandResponseAsFile(respWrapper.payload,imageType, resp.getBody(),applicantId,loanid);
                    integrationDetail.Calling_Source__c = wrapper.type; 
                    integrationDetail.Request_JSON__c = newId; 
                    integrationDetail.Response_JSON__c = newId;
                    integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
                    integrationDetail.Method_Type__c = intSetting.Request_Method__c; 
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Name = processName; 
                    integrationDetail.Loan_Application__c = loanid;
                    insert integrationDetail;        
                }
                
                else if(imageType =='Aadhar Front Bottom' ){
                    COMM_AadharFrontBottomController.AadharFrontBottomResponseWrapper aadharFrontBottom = new  COMM_AadharFrontBottomController.AadharFrontBottomResponseWrapper();
                    System.debug('resp.getBody()----'+ resp.getBody());
                    if(resp.getStatusCode()== 200){
                        System.debug('resp.getBody()----'+ resp.getBody());
                        aadharFrontBottom = (COMM_AadharFrontBottomController.AadharFrontBottomResponseWrapper)JSON.deserialize(resp.getBody(), COMM_AadharFrontBottomController.AadharFrontBottomResponseWrapper.class);
                        retunrResp = JSON.serialize(aadharFrontBottom);
                        System.debug('aadhar number in response---'+aadharFrontBottom.result.documents[0].ocrData.aadhaar.value);
                        
                        Boolean maskedStatus= aadharFrontBottom.result.documents[0].additionalDetails.outputMaskStatus;
                        
                        
                        if(maskedStatus){
                            
                            app[0].Id = applicantId;
                            app[0].Loan_Application__c = loanid;
                            // app[0].Aadhar_Masked_Source__c= 'API';
                            app[0].Aadhaar_Number_Masked__c=Utility.getEncryptedBase64String(aadharFrontBottom.result.documents[0].ocrData.aadhaar.value);
                            System.debug('encryptedd--'+app[0].Aadhaar_Number_Masked__c);
                            System.debug('decryptedd---'+ Utility.getDecryptedBase64String(Utility.getEncryptedBase64String(aadharFrontBottom.result.documents[0].ocrData.aadhaar.value)));
                            update app;
                            
                            List<ContentDocument> docList = [
                                SELECT Id FROM ContentDocument 
                                WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId)
                            ];
                            
                            if (!docList.isEmpty()) {
                                delete docList;  // This will delete associated ContentVersion(s) as well
                                System.debug('Deleted ContentDocument: ' + docList);
                            }
                            
                            //String base64Data= aadharFrontBottom.result.documents[0].documentBase64;
                            String base64Data = aadharFrontBottom.result.documents[0].documentBase64 != null
                                ? aadharFrontBottom.result.documents[0].documentBase64
                                : (aadharFrontBottom.result.fileBase64 != null
                                   ? aadharFrontBottom.result.fileBase64
                                   : null);
                                       // String base64Data = !String.isBlank(aadharFrontBottom.result.documents[0].documentBase64) ?
                                       // aadharFrontBottom.result.documents[0].documentBase64 :
                                       // (!String.isBlank(aadharFrontBottom.result.documents[0].fileBase64) ?
                                       // aadharFrontBottom.result.documents[0].fileBase64 : null);
                                       System.debug('uploadedFileName- at 661---'+uploadedFileName);
                            ContentVersion cv = new ContentVersion();
                            cv.Title = uploadedFileName;
                            cv.PathOnClient = uploadedFileName;
                            cv.VersionData = EncodingUtil.base64Decode(base64Data);
                            cv.IsMajorVersion = true;
                            insert cv;
                            
                            ContentVersion cvRec = [SELECT Id, ContentDocumentId, FileType FROM ContentVersion WHERE Id =: cv.Id Limit 1];
                            
                            ContentDocumentLink cdl = new ContentDocumentLink();
                            cdl.LinkedEntityId = documentId;
                            cdl.ContentDocumentId = cvRec.ContentDocumentId;
                            cdl.ShareType = 'V';
                            cdl.Visibility = 'AllUsers';
                            insert cdl;
                            
                            
                            if(documentId!= null){
                                Document_Details__c document= new Document_Details__c();
                                document.Content_Document_Id__c = cvRec.ContentDocumentId;
                                document.Id= documentId;
                                document.Status__c = Constants.STATUS_UPLOADED;
                                document.Aadhar_Masked_Source__c= 'API';
                                update document;
                            }
                            
                            List<Triangulation_Data__c> triangulationDatas = [SELECT Id, Loan_Application__c, Application_Applicant__c, Aadhar__c, Address__c, Name__c FROM Triangulation_Data__c 
                                                                              WHERE Loan_Application__c =: loanid AND Application_Applicant__c =: applicantId AND Source_Type__c =: 'Aadhar' AND Document_Type__c =: imageType];
                            if(!triangulationDatas.isEmpty()) {
                                triangulationDatas[0].Aadhar__c = getValueWithConfidence(aadharFrontBottom.result.documents[0].ocrData.aadhaar.value, aadharFrontBottom.result.documents[0].ocrData.aadhaar.confidence);
                                triangulationDatas[0].Name__c = getValueWithConfidence(aadharFrontBottom.result.documents[0].ocrData.name.value, aadharFrontBottom.result.documents[0].ocrData.name.confidence);
                                
                                update triangulationDatas;
                            } else {
                                Triangulation_Data__c triangulationData = new Triangulation_Data__c();
                                triangulationData.Aadhar__c = getValueWithConfidence(aadharFrontBottom.result.documents[0].ocrData.aadhaar.value, aadharFrontBottom.result.documents[0].ocrData.aadhaar.confidence);
                                triangulationData.Name__c = getValueWithConfidence(aadharFrontBottom.result.documents[0].ocrData.name.value, aadharFrontBottom.result.documents[0].ocrData.name.confidence);
                                triangulationData.Application_Applicant__c = applicantId;
                                triangulationData.Loan_Application__c = loanid;
                                triangulationData.Source_Type__c = setSource;
                                triangulationData.Document_Type__c = 'Aadhar';
                                insert triangulationData;
                            }
                            
                        }else{
                            retunrResp = 'Error: Aadhar has not been masked properly. Please upload the masked aadhar document.';
                            // app[0].Aadhar_Masked_Source__c= 'Manual';
                            update app;
                            List<ContentDocument> docList = [
                                SELECT Id FROM ContentDocument 
                                WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId)
                            ];
                            
                            if (!docList.isEmpty()) {
                                delete docList;  // This will delete associated ContentVersion(s) as well
                                System.debug('Deleted ContentDocument: ' + docList);
                            }
                            
                            if(documentId!= null){
                                Document_Details__c document= new Document_Details__c();
                                document.Content_Document_Id__c = null;
                                document.Id= documentId;
                                document.Status__c = '';
                                document.Aadhar_Masked_Source__c= 'Manual';
                                update document;
                            }
                        }
                        
                    }
                    else if(resp.getStatusCode()== 503){
                        retunrResp = 'Error:' + 'Service Temporarily Unavailable';
                        // app[0].Aadhar_Masked_Source__c= 'Manual';
                        update app;
                        List<ContentDocument> docList = [
                            SELECT Id FROM ContentDocument 
                            WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId)
                        ];
                        
                        if (!docList.isEmpty()) {
                            delete docList;  // This will delete associated ContentVersion(s) as well
                            System.debug('Deleted ContentDocument: ' + docList);
                        }
                        
                        if(documentId!= null){
                            Document_Details__c document= new Document_Details__c();
                            document.Content_Document_Id__c = null;
                            document.Id= documentId;
                            document.Status__c = '';
                            document.Aadhar_Masked_Source__c= 'Manual';
                            update document;
                        }
                    }
                    else{
                        
                        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                        String errorCode = (String) responseMap.get('error');
                        for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                            if(execeptionMeta.Error_Code__c == errorCode){
                                retunrResp = 'Error: ' + execeptionMeta.Error_Message__c;
                                
                            }
                            else{
                                retunrResp = 'Error: ' + 'Please try again later.';
                            } 
                        }
                        // app[0].Aadhar_Masked_Source__c= 'Manual';
                        update app;
                        List<ContentDocument> docList = [
                            SELECT Id FROM ContentDocument 
                            WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId)
                        ];
                        
                        if (!docList.isEmpty()) {
                            delete docList;  // This will delete associated ContentVersion(s) as well
                            System.debug('Deleted ContentDocument: ' + docList);
                        }
                        
                        if(documentId!= null){
                            Document_Details__c document= new Document_Details__c();
                            document.Content_Document_Id__c = null;
                            document.Id= documentId;
                            document.Status__c = '';
                            document.Aadhar_Masked_Source__c= 'Manual';
                            update document;
                        }
                    }       
                    
                    // aadharFront = (AadharFrontBottomController.AadharFrontBottomResponseWrapper)JSON.deserialize(resp.getBody(), AadharFrontTopController.AadharFrontBottomResponseWrapper.class);
                    System.debug('aadharFrontBottom---'+aadharFrontBottom);
                    
                    // retunrResp = JSON.serialize(aadharFrontBottom);
                    System.debug('resp---');
                    resultMessage = 'Sucess';
                    // integrationDetail.Calling_Source__c = wrapper.type; 
                    // integrationDetail.Request_JSON__c = respWrapper.payload; 
                    // integrationDetail.Response_JSON__c =jsonResp; 
                    // integrationDetail.Status__c ='200';
                    // integrationDetail.Response_JSON__c = resp.getBody();
                    // integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
                    // integrationDetail.Method_Type__c = intSetting.Request_Method__c; 
                    // integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                    // integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    // integrationDetail.Related_Record_Id__c = applicantId;
                    // integrationDetail.Name = 'Loan OCR Aadhar Front Bottom'; 
                    // integrationDetail.Loan_Application__c = loanid;
                    // insert integrationDetail;
                }
                else if (imageType =='Passport Front') {
                    PassportFrontController.PassportFrontResponseWrapper passportFront = new  PassportFrontController.PassportFrontResponseWrapper();
                    if(resp.getStatusCode()== 200){
                        passportFront = (PassportFrontController.PassportFrontResponseWrapper)JSON.deserialize(resp.getBody(), PassportFrontController.PassportFrontResponseWrapper.class);
                        retunrResp = JSON.serialize(passportFront);
                        System.debug('retunrResp 1202 : '+retunrResp);
                    }
                    else if(resp.getStatusCode()== 503){
                        retunrResp = 'Error:' + 'Service Temporarily Unavailable';
                    }
                    else{
                        
                        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                        String errorCode = (String) responseMap.get('error');
                        for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                            if(execeptionMeta.Error_Code__c == errorCode){
                                retunrResp = 'Error: ' + execeptionMeta.Error_Message__c;
                                
                            }
                            else{
                                
                            } retunrResp = 'Error:' + 'Please try again later.';
                        }
                    }      
                    //passportFront = (PassportFrontController.PassportFrontResponseWrapper)JSON.deserialize(jsonResp, PassportFrontController.PassportFrontResponseWrapper.class);
                    
                    System.debug('aadharFrontBotton---'+passportFront);
                    
                    //retunrResp = JSON.serialize(passportFront);
                    System.debug('resp---');
                    resultMessage = 'Sucess';
                    // integrationDetail.Calling_Source__c = wrapper.type; 
                    // integrationDetail.Request_JSON__c = respWrapper.payload; 
                    // integrationDetail.Response_JSON__c =jsonResp; 
                    String newId = storOcrRequestandResponseAsFile(respWrapper.payload,imageType, resp.getBody(),applicantId,loanid);
                    integrationDetail.Status__c ='200';
                    integrationDetail.Response_JSON__c = resp.getBody();
                    integrationDetail.Request_JSON__c = newId; 
                    integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
                    integrationDetail.Method_Type__c = intSetting.Request_Method__c; 
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Related_Record_Id__c = applicantId;
                    integrationDetail.Name = 'Loan OCR Passport Front '; 
                    integrationDetail.Loan_Application__c = loanid;
                    insert integrationDetail;
                    
                    if(String.valueof(resp.getStatusCode())== '200'){
                        System.debug('passportFront.statusCode '+passportFront.statusCode);
                        if(passportFront.statusCode == 101){
                            List<String> dobParts = passportFront.result.documents[0].ocrData.dob.value.split('/');
                            List<String> doiParts = passportFront.result.documents[0].ocrData.doi.value.split('/');
                            List<String> doeParts = passportFront.result.documents[0].ocrData.doe.value.split('/');
                            app[0].Passport_Number__c = passportFront.result.documents[0].ocrData.passportNumber.value;
                            app[0].Passport_Nationality__c = passportFront.result.documents[0].ocrData.nationality.value;
                            app[0].Passport_Place_of_Birth__c = passportFront.result.documents[0].ocrData.placeOfBirth.value;
                            if (dobParts.size() == 3) {
                                app[0].Passport_DOB__c = Date.valueOf(dobParts[2] + '-' + dobParts[1] + '-' + dobParts[0]);
                            }
                            if (doiParts.size() == 3) {
                                app[0].Passport_Date_of_Issue__c = Date.valueOf(doiParts[2] + '-' + doiParts[1] + '-' + doiParts[0]);
                            }
                            app[0].Passport_Place_of_Issue__c = passportFront.result.documents[0].ocrData.placeOfIssue.value;
                            if (doeParts.size() == 3) {
                                app[0].Passport_Date_of_Expiry__c = Date.valueOf(doeParts[2] + '-' + doeParts[1] + '-' + doeParts[0]);
                            }
                            
                            System.debug('app dt: ' + app);
                            update app;
                            System.debug('app dt'+app);
                            update app;
                            
                            String fullName = passportFront.result.documents[0].ocrData.givenName.value + passportFront.result.documents[0].ocrData.surname.value;
                            List<Triangulation_Data__c> triangulationDatas = [SELECT Id, Loan_Application__c, Application_Applicant__c, Passport__c, Address__c, Name__c, Date_Of_Expiry__c, Date_Of_Issue__c, Date_Of_Birth__c, Gender__c, 
                                                                              Country_Code__c, Nationality__c, Place_Of_Birth__c, Place_Of_Issue__c FROM Triangulation_Data__c WHERE Loan_Application__c =: loanid 
                                                                              AND Application_Applicant__c =: applicantId AND Source_Type__c =: setSource AND Document_Type__c =: 'Passport'];
                            // if(!triangulationDatas.isEmpty()) {
                            //   System.debug('1257 triangulation');
                            //     triangulationDatas[0].Passport__c = passportFront.result.documents[0].ocrData.passportNumber.value;
                            //     triangulationDatas[0].Name__c = fullName;
                            //     triangulationDatas[0].Date_Of_Birth__c = passportFront.result.documents[0].ocrData.dob.value;
                            //     triangulationDatas[0].Date_Of_Issue__c = passportFront.result.documents[0].ocrData.doi.value;
                            //     triangulationDatas[0].Place_Of_Issue__c = passportFront.result.documents[0].ocrData.placeOfIssue.value;
                            //     triangulationDatas[0].Place_Of_Birth__c = passportFront.result.documents[0].ocrData.placeOfIssue.value;
                            //     triangulationDatas[0].Date_Of_Expiry__c = passportFront.result.documents[0].ocrData.doe.value;
                            //     triangulationDatas[0].Gender__c = passportFront.result.documents[0].ocrData.gender.value;
                            //     triangulationDatas[0].Nationality__c = passportFront.result.documents[0].ocrData.nationality.value;
                            //     triangulationDatas[0].Country_Code__c = passportFront.result.documents[0].ocrData.countryCode.value;
                            
                            //     update triangulationDatas;
                            // } else {
                            //     Triangulation_Data__c triangulationData = new Triangulation_Data__c();
                            //     triangulationData.Passport__c = passportFront.result.documents[0].ocrData.passportNumber.value;
                            //     triangulationData.Name__c = fullName;
                            //     triangulationData.Date_Of_Birth__c = passportFront.result.documents[0].ocrData.dob.value;
                            //     triangulationData.Date_Of_Issue__c = passportFront.result.documents[0].ocrData.doi.value;
                            //     triangulationData.Place_Of_Issue__c = passportFront.result.documents[0].ocrData.placeOfIssue.value;
                            //     triangulationData.Place_Of_Birth__c = passportFront.result.documents[0].ocrData.placeOfIssue.value;
                            //     triangulationData.Date_Of_Expiry__c = passportFront.result.documents[0].ocrData.doe.value;
                            //     triangulationData.Gender__c = passportFront.result.documents[0].ocrData.gender.value;
                            //     triangulationData.Nationality__c = passportFront.result.documents[0].ocrData.nationality.value;
                            //     triangulationData.Country_Code__c = passportFront.result.documents[0].ocrData.countryCode.value;
                            //     // parameter setting
                            //     triangulationData.Application_Applicant__c = applicantId;
                            //     triangulationData.Loan_Application__c = loanid;
                            //     triangulationData.Source_Type__c = setSource;
                            //     triangulationData.Document_Type__c = imageType;
                            //     insert triangulationData;
                            // }
                            if(!triangulationDatas.isEmpty()) {
                                System.debug('1257 triangulation');
                                triangulationDatas[0].Passport__c = getValueWithConfidence(passportFront.result.documents[0].ocrData.passportNumber.value, passportFront.result.documents[0].ocrData.passportNumber.confidence);
                                triangulationDatas[0].Name__c = fullName + ' (80 %)';
                                triangulationDatas[0].Date_Of_Birth__c = getValueWithConfidence(passportFront.result.documents[0].ocrData.dob.value, passportFront.result.documents[0].ocrData.dob.confidence);
                                triangulationDatas[0].Date_Of_Issue__c = getValueWithConfidence(passportFront.result.documents[0].ocrData.passportNumber.value, passportFront.result.documents[0].ocrData.passportNumber.confidence);
                                triangulationDatas[0].Place_Of_Issue__c = getValueWithConfidence(passportFront.result.documents[0].ocrData.placeOfIssue.value, passportFront.result.documents[0].ocrData.placeOfIssue.confidence);
                                triangulationDatas[0].Place_Of_Birth__c = getValueWithConfidence(passportFront.result.documents[0].ocrData.placeOfBirth.value, passportFront.result.documents[0].ocrData.placeOfBirth.confidence);
                                triangulationDatas[0].Date_Of_Expiry__c = getValueWithConfidence(passportFront.result.documents[0].ocrData.doe.value, passportFront.result.documents[0].ocrData.doe.confidence);
                                triangulationDatas[0].Gender__c = getValueWithConfidence(passportFront.result.documents[0].ocrData.gender.value, passportFront.result.documents[0].ocrData.gender.confidence);
                                triangulationDatas[0].Nationality__c = getValueWithConfidence(passportFront.result.documents[0].ocrData.nationality.value, passportFront.result.documents[0].ocrData.nationality.confidence);
                                triangulationDatas[0].Country_Code__c = getValueWithConfidence(passportFront.result.documents[0].ocrData.countryCode.value, passportFront.result.documents[0].ocrData.countryCode.confidence);
                                
                                update triangulationDatas;
                            } else {
                                Triangulation_Data__c triangulationData = new Triangulation_Data__c();
                                triangulationData.Passport__c = getValueWithConfidence(passportFront.result.documents[0].ocrData.passportNumber.value, passportFront.result.documents[0].ocrData.passportNumber.confidence);
                                triangulationData.Name__c = fullName + ' (80 %)';
                                triangulationData.Date_Of_Birth__c = getValueWithConfidence(passportFront.result.documents[0].ocrData.dob.value, passportFront.result.documents[0].ocrData.dob.confidence);
                                triangulationData.Date_Of_Issue__c = getValueWithConfidence(passportFront.result.documents[0].ocrData.passportNumber.value, passportFront.result.documents[0].ocrData.passportNumber.confidence);
                                triangulationData.Place_Of_Issue__c = getValueWithConfidence(passportFront.result.documents[0].ocrData.placeOfIssue.value, passportFront.result.documents[0].ocrData.placeOfIssue.confidence);
                                triangulationData.Place_Of_Birth__c = getValueWithConfidence(passportFront.result.documents[0].ocrData.placeOfBirth.value, passportFront.result.documents[0].ocrData.placeOfBirth.confidence);
                                triangulationData.Date_Of_Expiry__c = getValueWithConfidence(passportFront.result.documents[0].ocrData.doe.value, passportFront.result.documents[0].ocrData.doe.confidence);
                                triangulationData.Gender__c = getValueWithConfidence(passportFront.result.documents[0].ocrData.gender.value, passportFront.result.documents[0].ocrData.gender.confidence);
                                triangulationData.Nationality__c = getValueWithConfidence(passportFront.result.documents[0].ocrData.nationality.value, passportFront.result.documents[0].ocrData.nationality.confidence);
                                triangulationData.Country_Code__c = getValueWithConfidence(passportFront.result.documents[0].ocrData.countryCode.value, passportFront.result.documents[0].ocrData.countryCode.confidence);
                                triangulationData.Application_Applicant__c = applicantId;
                                triangulationData.Loan_Application__c = loanid;
                                triangulationData.Source_Type__c = setSource;
                                triangulationData.Document_Type__c = 'Passport';
                                insert triangulationData;
                            }
                        }
                        else{
                            retunrResp = 'Error:' + 'No Data from Ocr';
                        }
                    }
                }
                else if (imageType =='Passport Back') {
                    //     jsonResp = '{' +
                    //     '"requestId": "d0075247-8668-4867-aee0-6a89b2e5a988",' +
                    //     '"result": {' +
                    //         '"documents": [' +
                    //             '{' +
                    //                 '"documentType": "PASSPORT",' +
                    //                 '"subType": "BACK",' +
                    //                 '"pageNo": 1,' +
                    //                 '"ocrData": {' +
                    //                     '"father": {"value": "", "confidence": 0.99},' +
                    //                     '"fileNumber": {"value": "", "confidence": 1},' +
                    //                     '"mother": {"value": "", "confidence": 0.95},' +
                    //                     '"oldDoi": {"value": "", "confidence": 0},' +
                    //                     '"oldPassportNumber": {"value": "", "confidence": 0},' +
                    //                     '"oldPlaceOfIssue": {"value": "", "confidence": 0},' +
                    //                     '"passportNumber": {"value": "", "confidence": 0.95},' +
                    //                     '"pin": {"value": "", "confidence": 0.8},' +
                    //                     '"spouse": {"value": "", "confidence": 0},' +
                    //                     '"address": {"value": "", "confidence": 0.95}' +
                    //                 '},' +
                    //                 '"additionalDetails": {' +
                    //                     '"addressSplit": {' +
                    //                         '"building": "", "city": "", "district": "", "pin": "",' +
                    //                         '"floor": "", "house": "", "locality": "", "state": "",' +
                    //                         '"street": "", "complex": "", "landmark": "", "untagged": ""' +
                    //                     '}' +
                    //                 '},' +
                    //                 '"qualityChecks": [' +
                    //                     '{ "score": 0.77, "flag": false, "type": "BRIGHTNESS" },' +
                    //                     '{ "score": 1, "flag": true, "type": "BLACK_AND_WHITE" },' +
                    //                     '{ "score": 0.01, "flag": false, "type": "BLUR" },' +
                    //                     '{ "score": 0.21, "flag": false, "type": "CUT_CARD" }' +
                    //                 '],' +
                    //                 '"documentLink": null' +
                    //             '}' +
                    //         ']' +
                    //     '},' +
                    //     '"statusCode": 101,' +
                    //     '"clientData": { "caseId": "123456" }' +
                    // '}';
                    System.debug('resp PBack '+resp.getBody());
                    PassportBackController.PassportBackResponseWrapper passportBack = new  PassportBackController.PassportBackResponseWrapper();
                    //  passportBack = (PassportBackController.PassportBackResponseWrapper)JSON.deserialize(jsonResp, PassportBackController.PassportFrontResponseWrapper.class);
                    if(resp.getStatusCode()== 200){
                        passportBack = (PassportBackController.PassportBackResponseWrapper)JSON.deserialize(resp.getBody(), PassportBackController.PassportBackResponseWrapper.class);
                        retunrResp = JSON.serialize(passportBack);
                        System.debug('passportBack resp : '+passportBack);
                    }
                    else if(resp.getStatusCode()== 503){
                        retunrResp = 'Error:' + 'Service Temporarily Unavailable';
                    }
                    else{
                        
                        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                        String errorCode = (String) responseMap.get('error');
                        for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                            if(execeptionMeta.Error_Code__c == errorCode){
                                retunrResp = 'Error: ' + execeptionMeta.Error_Message__c;
                                
                            }
                            else{
                                retunrResp = 'Error:' + 'Please try again later.';
                            } 
                        }
                    }    
                    
                    System.debug('Passport Back---'+passportBack);
                    
                    //retunrResp = JSON.serialize(passportBack);
                    System.debug('resp---');
                    resultMessage = 'Sucess';
                    integrationDetail.Calling_Source__c = wrapper.type; 
                    // integrationDetail.Request_JSON__c = respWrapper.payload; 
                    //  integrationDetail.Response_JSON__c =jsonResp; 
                    // integrationDetail.Status__c ='200';
                    String newId = storOcrRequestandResponseAsFile(respWrapper.payload,imageType, resp.getBody(),applicantId,loanid);
                    integrationDetail.Response_JSON__c = resp.getBody();
                    integrationDetail.Request_JSON__c = newId; 
                    integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
                    integrationDetail.Method_Type__c = intSetting.Request_Method__c; 
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Related_Record_Id__c = applicantId;
                    integrationDetail.Name = 'Loan OCR Passport Back '; 
                    integrationDetail.Loan_Application__c = loanid;
                    insert integrationDetail;
                    if(String.valueOf(resp.getStatusCode()) == '200') {
                        if(passportBack.statusCode == 101) {
                            if(String.isNotBlank(passportBack.result.documents[0].ocrData.oldDoi.value)){
                                List<String> dobParts = passportBack.result.documents[0].ocrData.oldDoi.value.split('/');
                                if (dobParts.size() == 3) {
                                    app[0].Passport_Date_of_Issue__c = Date.valueOf(dobParts[2] + '-' + dobParts[1] + '-' + dobParts[0]);
                                }
                            }
                            app[0].Passport_Number__c = (passportBack.result.documents[0].ocrData.passportNumber.value != null) ? passportBack.result.documents[0].ocrData.passportNumber.value : '';
                            app[0].Passport_Address__c = (passportBack.result.documents[0].ocrData.address.value != null) ? passportBack.result.documents[0].ocrData.address.value : '';
                            // app[0].Passport_Date_of_Issue__c = (String.isNotBlank(passportBack.result.documents[0].ocrData.oldDoi.value)) ? Date.valueOf(passportBack.result.documents[0].ocrData.oldDoi.value) : null;
                            app[0].Passport_Place_of_Issue__c = (passportBack.result.documents[0].ocrData.oldPlaceOfIssue.value != null) ? passportBack.result.documents[0].ocrData.oldPlaceOfIssue.value : '';
                            app[0].Passport_Mother_s_Name__c = (passportBack.result.documents[0].ocrData.mother.value != null) ? passportBack.result.documents[0].ocrData.mother.value : '';
                            app[0].Passport_Son_Daughter_Wife_of__c = (passportBack.result.documents[0].ocrData.father.value != null) ? passportBack.result.documents[0].ocrData.father.value : '';
                            app[0].Passport_Spouse_Name__c = (passportBack.result.documents[0].ocrData.spouse.value != null) ? passportBack.result.documents[0].ocrData.spouse.value : '';
                            update app;
                            
                            // Store Address - Ishi
                            System.debug('passportBack ------------------------ 677 ' + passportBack.result.documents[0].additionalDetails.addressSplit.building);
                            
                            Boolean isAddressPresent = (passportBack.result.documents[0].additionalDetails.addressSplit.building != null ||
                                                        passportBack.result.documents[0].additionalDetails.addressSplit.floor != null ||
                                                        passportBack.result.documents[0].additionalDetails.addressSplit.house != null);
                            
                            if(isAddressPresent) {
                                Applicant_Address__c addressAadhar = new Applicant_Address__c();
                                
                                String building = (passportBack.result.documents[0].additionalDetails.addressSplit.building != null) ? passportBack.result.documents[0].additionalDetails.addressSplit.building : '';
                                String floor = (passportBack.result.documents[0].additionalDetails.addressSplit.floor != null) ? passportBack.result.documents[0].additionalDetails.addressSplit.floor : '';
                                String house = (passportBack.result.documents[0].additionalDetails.addressSplit.house != null) ? passportBack.result.documents[0].additionalDetails.addressSplit.house : '';
                                String street = (passportBack.result.documents[0].additionalDetails.addressSplit.street != null) ? passportBack.result.documents[0].additionalDetails.addressSplit.street : '';
                                String locality = (passportBack.result.documents[0].additionalDetails.addressSplit.locality != null) ? passportBack.result.documents[0].additionalDetails.addressSplit.locality : '';
                                String city = (passportBack.result.documents[0].additionalDetails.addressSplit.city != null) ? passportBack.result.documents[0].additionalDetails.addressSplit.city : '';
                                String district = (passportBack.result.documents[0].additionalDetails.addressSplit.district != null) ? passportBack.result.documents[0].additionalDetails.addressSplit.district : '';
                                String state = (passportBack.result.documents[0].additionalDetails.addressSplit.state != null) ? passportBack.result.documents[0].additionalDetails.addressSplit.state : '';
                                String pinCode = (passportBack.result.documents[0].additionalDetails.addressSplit.pin != null) ? passportBack.result.documents[0].additionalDetails.addressSplit.pin : '';
                                
                                addressAadhar.Address_Line_1__c = String.join(new List<String>{house, floor, building}, ', ');
                                addressAadhar.Address_Line_2__c = String.join(new List<String>{street, locality}, ', ');
                                addressAadhar.Address_Line_3__c = String.join(new List<String>{district, city, state}, ', ');
                                addressAadhar.Address_Source__c = 'Passport';
                                addressAadhar.Document_Details__c = documentId;
                                
                                for (String line : new List<String>{addressAadhar.Address_Line_1__c, addressAadhar.Address_Line_2__c, addressAadhar.Address_Line_3__c}) {
                                    if (String.isNotBlank(line)) {
                                        line = line.replaceAll('^,\\s*|\\s*,\\s*$', '');
                                    }
                                }
                                
                                if (String.isNotBlank(pinCode)) {
                                    List<Pincode_Master__c> pincodeList = [
                                        SELECT Id, Name FROM Pincode_Master__c WHERE Name = :pinCode LIMIT 1
                                    ];
                                    if (!pincodeList.isEmpty()) {
                                        addressAadhar.Pincode__c = pincodeList[0].Id;
                                    }
                                }
                                addressAadhar.Applicant__c = applicantId;
                                System.debug('addressAadhar------- 677 ' + addressAadhar);
                                insert addressAadhar;
                            }
                            
                            List<Triangulation_Data__c> triangulationDatas = [SELECT Id, Loan_Application__c, Application_Applicant__c, Passport__c, Address__c, Old_Date_Of_Issue__c, Old_Passport_Number__c, File_Number__c,
                                                                              Spouse__c, Father__c, Mother__c, Old_Place_Of_Issue__c FROM Triangulation_Data__c WHERE Loan_Application__c = :loanid 
                                                                              AND Application_Applicant__c = :applicantId AND Source_Type__c = :setSource AND Document_Type__c = :'Passport'];
                            
                            if (!triangulationDatas.isEmpty()) {
                                triangulationDatas[0].Passport__c = getValueWithConfidence(passportBack.result.documents[0].ocrData.passportNumber.value, passportBack.result.documents[0].ocrData.passportNumber.confidence);
                                triangulationDatas[0].File_Number__c = getValueWithConfidence(passportBack.result.documents[0].ocrData.fileNumber.value, passportBack.result.documents[0].ocrData.fileNumber.confidence);
                                triangulationDatas[0].Old_Passport_Number__c = getValueWithConfidence(passportBack.result.documents[0].ocrData.fileNumber.value, passportBack.result.documents[0].ocrData.oldPassportNumber.confidence);
                                triangulationDatas[0].Old_Date_Of_Issue__c = getValueWithConfidence(passportBack.result.documents[0].ocrData.oldDoi.value, passportBack.result.documents[0].ocrData.oldDoi.confidence);
                                triangulationDatas[0].Old_Place_Of_Issue__c = getValueWithConfidence(passportBack.result.documents[0].ocrData.oldPlaceOfIssue.value, passportBack.result.documents[0].ocrData.oldPlaceOfIssue.confidence);
                                triangulationDatas[0].Spouse__c = getValueWithConfidence(passportBack.result.documents[0].ocrData.spouse.value, passportBack.result.documents[0].ocrData.spouse.confidence);
                                triangulationDatas[0].Father__c = getValueWithConfidence(passportBack.result.documents[0].ocrData.father.value, passportBack.result.documents[0].ocrData.father.confidence);
                                triangulationDatas[0].Mother__c = getValueWithConfidence(passportBack.result.documents[0].ocrData.mother.value, passportBack.result.documents[0].ocrData.mother.confidence);
                                triangulationDatas[0].Address__c = getValueWithConfidence(passportBack.result.documents[0].ocrData.address.value, passportBack.result.documents[0].ocrData.address.confidence);
                                
                                update triangulationDatas;
                            } else {
                                Triangulation_Data__c triangulationData = new Triangulation_Data__c();
                                triangulationData.Passport__c = getValueWithConfidence(passportBack.result.documents[0].ocrData.passportNumber.value, passportBack.result.documents[0].ocrData.passportNumber.confidence);
                                triangulationData.File_Number__c = getValueWithConfidence(passportBack.result.documents[0].ocrData.fileNumber.value, passportBack.result.documents[0].ocrData.fileNumber.confidence);
                                triangulationData.Old_Passport_Number__c = getValueWithConfidence(passportBack.result.documents[0].ocrData.fileNumber.value, passportBack.result.documents[0].ocrData.oldPassportNumber.confidence);
                                triangulationData.Old_Date_Of_Issue__c =  getValueWithConfidence(passportBack.result.documents[0].ocrData.oldDoi.value, passportBack.result.documents[0].ocrData.oldDoi.confidence);
                                triangulationData.Old_Place_Of_Issue__c = getValueWithConfidence(passportBack.result.documents[0].ocrData.oldPlaceOfIssue.value, passportBack.result.documents[0].ocrData.oldPlaceOfIssue.confidence);
                                triangulationData.Spouse__c = getValueWithConfidence(passportBack.result.documents[0].ocrData.spouse.value, passportBack.result.documents[0].ocrData.spouse.confidence);
                                triangulationData.Father__c = getValueWithConfidence(passportBack.result.documents[0].ocrData.father.value, passportBack.result.documents[0].ocrData.father.confidence);
                                triangulationData.Mother__c = getValueWithConfidence(passportBack.result.documents[0].ocrData.mother.value, passportBack.result.documents[0].ocrData.mother.confidence);
                                triangulationData.Address__c = getValueWithConfidence(passportBack.result.documents[0].ocrData.address.value, passportBack.result.documents[0].ocrData.address.confidence);
                                // parameter setting
                                triangulationData.Application_Applicant__c = applicantId;
                                triangulationData.Loan_Application__c = loanid;
                                triangulationData.Source_Type__c = setSource;
                                triangulationData.Document_Type__c = 'Passport';
                                insert triangulationData;
                            }
                        }
                        else{
                            retunrResp = 'Error:' + 'No Data from Ocr';
                        }
                    }
                    
                }
                else if (imageType =='Voter Front') {
                    //     jsonResp = '{' +
                    //     '"requestId": "9060072d-947b-4df7-9a85-5f5bbcd499b3",' +
                    //     '"result": {' +
                    //         '"documents": [' +
                    //             '{' +
                    //                 '"documentType": "VOTER",' +
                    //                 '"subType": "FRONT_NEW",' +
                    //                 '"pageNo": 1,' +
                    //                 '"ocrData": {' +
                    //                     '"voterId": {"value": "", "confidence": 0.1},' +
                    //                     '"name": {"value": "", "confidence": 0.87},' +
                    //                     '"relationName": {"value": "", "confidence": 0.78}' +
                    //                 '},' +
                    //                 '"additionalDetails": {},' +
                    //                 '"qualityChecks": [' +
                    //                     '{ "score": 0.66, "flag": false, "type": "BRIGHTNESS" },' +
                    //                     '{ "score": 0, "flag": false, "type": "BLACK_AND_WHITE" },' +
                    //                     '{ "score": 0.36, "flag": false, "type": "BLUR" },' +
                    //                     '{ "score": 0.22, "flag": false, "type": "CUT_CARD" }' +
                    //                 '],' +
                    //                 '"tamperCheck": {' +
                    //                     '"score": 0.9,' +
                    //                     '"tamperRisk": "HIGH",' +
                    //                     '"status": "SUCCESS"' +
                    //                 '},' +
                    //                 '"documentLink": null' +
                    //             '}' +
                    //         ']' +
                    //     '},' +
                    //     '"statusCode": 101,' +
                    //     '"clientData": { "caseId": "123456" }' +
                    // '}';
                    
                    VoterIdFrontController.VoterIdFrontResponseWrapper voterFront = new  VoterIdFrontController.VoterIdFrontResponseWrapper();
                    
                    //voterFront = (VoterIdFrontController.VoterIdFrontResponseWrapper)JSON.deserialize(jsonResp, VoterIdFrontController.VoterIdFrontResponseWrapper.class);
                    if(resp.getStatusCode()== 200){
                        voterFront = (VoterIdFrontController.VoterIdFrontResponseWrapper)JSON.deserialize(resp.getBody(), VoterIdFrontController.VoterIdFrontResponseWrapper.class);
                        retunrResp = JSON.serialize(voterFront);
                    }
                    else if(resp.getStatusCode()== 503){
                        retunrResp = 'Error:' + 'Service Temporarily Unavailable';
                    }
                    else{
                        
                        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                        String errorCode = (String) responseMap.get('error');
                        for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                            if(execeptionMeta.Error_Code__c == errorCode){
                                retunrResp = 'Error: ' + execeptionMeta.Error_Message__c;
                            }
                            else{
                                retunrResp = 'Error:' + 'Please try again later.';
                            }
                        }
                    }   
                    
                    System.debug('aadharFrontBotton---'+voterFront);
                    
                    // retunrResp = JSON.serialize(voterFront);
                    System.debug('resp---');
                    resultMessage = 'Sucess';
                    String newId = storOcrRequestandResponseAsFile(respWrapper.payload,imageType, resp.getBody(),applicantId,loanid);
                    integrationDetail.Calling_Source__c = wrapper.type; 
                    integrationDetail.Request_JSON__c = newId; 
                    //  integrationDetail.Response_JSON__c =jsonResp; 
                    // integrationDetail.Status__c ='200';
                    integrationDetail.Response_JSON__c = resp.getBody();
                    integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
                    integrationDetail.Method_Type__c = intSetting.Request_Method__c; 
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Related_Record_Id__c = applicantId;
                    integrationDetail.Name = 'Loan OCR Voter Front '; 
                    integrationDetail.Loan_Application__c = loanid;
                    insert integrationDetail;
                    
                    if (String.valueOf(resp.getStatusCode()) == '200') {
                        if (voterFront.statusCode == 101) {
                            app[0].Voter_ID_Number__c = (voterFront.result.documents[0].ocrData.voterId.value != null && !String.isEmpty(voterFront.result.documents[0].ocrData.voterId.value)) ? voterFront.result.documents[0].ocrData.voterId.value : '';
                            app[0].Voter_ID_First_Name__c = (voterFront.result.documents[0].ocrData.name.value != null && !String.isEmpty(voterFront.result.documents[0].ocrData.name.value)) ? voterFront.result.documents[0].ocrData.name.value : '';
                            app[0].Voter_ID_Son_Daughter_Wife_of__c = (voterFront.result.documents[0].ocrData.relationName.value != null && !String.isEmpty(voterFront.result.documents[0].ocrData.relationName.value)) ? voterFront.result.documents[0].ocrData.relationName.value : '';
                            
                            update app;
                            
                            List<Triangulation_Data__c> triangulationDatas = [
                                SELECT Id, Loan_Application__c, Application_Applicant__c, Voter__c, Relation_Name__c 
                                FROM Triangulation_Data__c 
                                WHERE Loan_Application__c = :loanid 
                                AND Application_Applicant__c = :applicantId 
                                AND Source_Type__c = :setSource 
                                AND Document_Type__c = :'Voter Id'
                            ];
                            
                            if (!triangulationDatas.isEmpty()) {
                                triangulationDatas[0].Voter__c = getValueWithConfidence(voterFront.result.documents[0].ocrData.voterId.value, voterFront.result.documents[0].ocrData.voterId.confidence);
                                triangulationDatas[0].Name__c = getValueWithConfidence(voterFront.result.documents[0].ocrData.name.value, voterFront.result.documents[0].ocrData.name.confidence);
                                triangulationDatas[0].Relation_Name__c = getValueWithConfidence(voterFront.result.documents[0].ocrData.relationName.value, voterFront.result.documents[0].ocrData.relationName.confidence);
                                
                                update triangulationDatas;
                            } else {
                                Triangulation_Data__c triangulationData = new Triangulation_Data__c();
                                triangulationData.Voter__c = getValueWithConfidence(voterFront.result.documents[0].ocrData.voterId.value, voterFront.result.documents[0].ocrData.voterId.confidence);
                                triangulationData.Name__c = getValueWithConfidence(voterFront.result.documents[0].ocrData.name.value, voterFront.result.documents[0].ocrData.name.confidence);
                                triangulationData.Relation_Name__c = getValueWithConfidence(voterFront.result.documents[0].ocrData.relationName.value, voterFront.result.documents[0].ocrData.relationName.confidence);
                                triangulationData.Application_Applicant__c = applicantId;
                                triangulationData.Loan_Application__c = loanid;
                                triangulationData.Source_Type__c = setSource;
                                triangulationData.Document_Type__c = 'Voter Id';
                                
                                insert triangulationData;
                            }
                        }
                        else{
                            retunrResp = 'Error:' + 'No Data from Ocr';
                        }
                    }
                    
                    
                }
                else if (imageType =='Voter Back') {
                    //     jsonResp = '{' +
                    //     '"requestId": "8c49e926-1f4d-4465-93e3-df0af9137337",' +
                    //     '"result": {' +
                    //         '"documents": [' +
                    //             '{' +
                    //                 '"documentType": "VOTER",' +
                    //                 '"subType": "BACK_NEW",' +
                    //                 '"pageNo": 1,' +
                    //                 '"ocrData": {' +
                    //                     '"voterId": {"value": "", "confidence": 0},' +
                    //                     '"gender": {"value": "", "confidence": 0.59},' +
                    //                     '"lastUpdatedDate": {"value": "", "confidence": 0},' +
                    //                     '"dob": {"value": "", "confidence": 0},' +
                    //                     '"age": {"value": "33", "confidence": 1},' +
                    //                     '"address": {"value": "", "confidence": 0.71}' +
                    //                 '},' +
                    //                 '"additionalDetails": {' +
                    //                     '"addressSplit": {' +
                    //                         '"building": "", "city": "", "district": "", "pin": "",' +
                    //                         '"floor": "", "house": "", "locality": "", "state": "",' +
                    //                         '"street": "", "complex": "", "landmark": "", "untagged": ""' +
                    //                     '}' +
                    //                 '},' +
                    //                 '"qualityChecks": [' +
                    //                     '{ "score": 0.71, "flag": false, "type": "BRIGHTNESS" },' +
                    //                     '{ "score": 0, "flag": false, "type": "BLACK_AND_WHITE" },' +
                    //                     '{ "score": 0.38, "flag": false, "type": "BLUR" },' +
                    //                     '{ "score": 0.21, "flag": false, "type": "CUT_CARD" }' +
                    //                 '],' +
                    //                 '"tamperCheck": {' +
                    //                     '"score": 0.9,' +
                    //                     '"tamperRisk": "HIGH",' +
                    //                     '"status": "SUCCESS"' +
                    //                 '},' +
                    //                 '"documentLink": null' +
                    //             '}' +
                    //         ']' +
                    //     '},' +
                    //     '"statusCode": 101,' +
                    //     '"clientData": { "caseId": "123456" }' +
                    // '}';
                    System.debug('voterBack body : '+resp.getBody());
                    System.debug('voterBack Code : '+resp.getStatusCode());
                    VoterBackController.VoterBackResponseWrapper voterBack = new  VoterBackController.VoterBackResponseWrapper();
                    if(resp.getStatusCode()== 200){
                        voterBack = (VoterBackController.VoterBackResponseWrapper)JSON.deserialize(resp.getBody(), VoterBackController.VoterBackResponseWrapper.class);
                        retunrResp = JSON.serialize(voterBack);
                        System.debug('voterBack vb : '+voterBack);
                    }
                    else if(resp.getStatusCode()== 503){
                        retunrResp = 'Error:' + 'Service Temporarily Unavailable';
                    }
                    else{
                        
                        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                        String errorCode = (String) responseMap.get('error');
                        for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                            if(execeptionMeta.Error_Code__c == errorCode){
                                retunrResp = 'Error: ' + execeptionMeta.Error_Message__c;
                            }              
                            else{
                                retunrResp = 'Error:' + 'Please try again later.';
                            } 
                        }
                    }       
                    /// voterBack = (VoterBackController.VoterBackResponseWrapper)JSON.deserialize(jsonResp, VoterBackController.VoterBackResponseWrapper.class);
                    
                    
                    //retunrResp = JSON.serialize(voterBack);
                    System.debug('resp---');
                    resultMessage = 'Sucess';
                    String newId = storOcrRequestandResponseAsFile(respWrapper.payload,imageType, resp.getBody(),applicantId,loanid);
                    integrationDetail.Calling_Source__c = wrapper.type; 
                    integrationDetail.Request_JSON__c = newId; 
                    //  integrationDetail.Response_JSON__c =jsonResp; 
                    // integrationDetail.Status__c ='200';
                    integrationDetail.Response_JSON__c = resp.getBody();
                    integrationDetail.Status__c = String.valueof(resp.getStatusCode()); 
                    integrationDetail.Method_Type__c = intSetting.Request_Method__c; 
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Related_Record_Id__c = applicantId;
                    integrationDetail.Name = 'Loan OCR Voter Back '; 
                    integrationDetail.Loan_Application__c = loanid; 
                    insert integrationDetail;
                    if (String.valueOf(resp.getStatusCode()) == '200') {
                        if (voterBack.statusCode == 101) {
                            app[0].Voter_ID_Number__c = (voterBack.result.documents[0].ocrData.voterId.value != null && !String.isEmpty(voterBack.result.documents[0].ocrData.voterId.value)) ? voterBack.result.documents[0].ocrData.voterId.value : '';
                            app[0].Voter_Address__c = (voterBack.result.documents[0].ocrData.address.value != null && !String.isEmpty(voterBack.result.documents[0].ocrData.address.value)) ? voterBack.result.documents[0].ocrData.address.value : '';
                            
                            // Store Address - Ishi
                            System.debug('Aadhar Addresss------------------------ 677 ' + voterBack.result.documents[0].additionalDetails.addressSplit.building);
                            if (voterBack.result.documents[0].additionalDetails.addressSplit.building != null || 
                                voterBack.result.documents[0].additionalDetails.addressSplit.floor != null || 
                                voterBack.result.documents[0].additionalDetails.addressSplit.house != null) {
                                    
                                    Applicant_Address__c addressAadhar = new Applicant_Address__c();
                                    
                                    String building = (voterBack.result.documents[0].additionalDetails.addressSplit.building != null) ? voterBack.result.documents[0].additionalDetails.addressSplit.building : '';
                                    String floor = (voterBack.result.documents[0].additionalDetails.addressSplit.floor != null) ? voterBack.result.documents[0].additionalDetails.addressSplit.floor : '';
                                    String house = (voterBack.result.documents[0].additionalDetails.addressSplit.house != null) ? voterBack.result.documents[0].additionalDetails.addressSplit.house : '';
                                    String street = (voterBack.result.documents[0].additionalDetails.addressSplit.street != null) ? voterBack.result.documents[0].additionalDetails.addressSplit.street : '';
                                    String locality = (voterBack.result.documents[0].additionalDetails.addressSplit.locality != null) ? voterBack.result.documents[0].additionalDetails.addressSplit.locality : '';
                                    String city = (voterBack.result.documents[0].additionalDetails.addressSplit.city != null) ? voterBack.result.documents[0].additionalDetails.addressSplit.city : '';
                                    String district = (voterBack.result.documents[0].additionalDetails.addressSplit.district != null) ? voterBack.result.documents[0].additionalDetails.addressSplit.district : '';
                                    String state = (voterBack.result.documents[0].additionalDetails.addressSplit.state != null) ? voterBack.result.documents[0].additionalDetails.addressSplit.state : '';
                                    String pinCode = (voterBack.result.documents[0].additionalDetails.addressSplit.pin != null) ? voterBack.result.documents[0].additionalDetails.addressSplit.pin : '';
                                    
                                    addressAadhar.Address_Line_1__c = String.join(new List<String>{house, floor, building}, ', ');
                                    addressAadhar.Address_Line_2__c = String.join(new List<String>{street, locality}, ', ');
                                    addressAadhar.Address_Line_3__c = String.join(new List<String>{district, city, state}, ', ');
                                    addressAadhar.Address_Source__c = 'Voter ID';
                                    addressAadhar.Document_Details__c =  documentId;
                                    
                                    for (String line : new List<String>{addressAadhar.Address_Line_1__c, addressAadhar.Address_Line_2__c, addressAadhar.Address_Line_3__c}) {
                                        if (String.isNotBlank(line)) {
                                            line = line.replaceAll('^,\\s*|\\s*,\\s*$', ''); 
                                        }
                                    }
                                    
                                    if (String.isNotBlank(pinCode)) {
                                        List<Pincode_Master__c> pincodeList = [
                                            SELECT Id, Name FROM Pincode_Master__c WHERE Name = :pinCode LIMIT 1
                                        ];
                                        if (!pincodeList.isEmpty()) {
                                            addressAadhar.Pincode__c = pincodeList[0].Id;
                                        }
                                    }
                                    
                                    addressAadhar.Applicant__c = applicantId;
                                    System.debug('addressAadhar------- 677 ' + addressAadhar);
                                    insert addressAadhar;
                                }
                            
                            List<Triangulation_Data__c> triangulationDatas = [
                                SELECT Id, Loan_Application__c, Application_Applicant__c, Voter__c, Relation_Name__c, Voter_Last_Updated__c, 
                                Date_Of_Birth__c, Age__c, Address__c 
                                FROM Triangulation_Data__c 
                                WHERE Loan_Application__c = :loanid 
                                AND Application_Applicant__c = :applicantId 
                                AND Source_Type__c = :setSource 
                                AND Document_Type__c = :'Voter Id'
                            ];
                            
                            if (!triangulationDatas.isEmpty()) {
                                Triangulation_Data__c existing = triangulationDatas[0];
                                existing.Voter__c = getValueWithConfidence(voterBack.result.documents[0].ocrData.voterId.value, voterBack.result.documents[0].ocrData.voterId.confidence);
                                existing.Gender__c = getValueWithConfidence(voterBack.result.documents[0].ocrData.gender.value, voterBack.result.documents[0].ocrData.gender.confidence);
                                existing.Voter_Last_Updated__c = getValueWithConfidence(voterBack.result.documents[0].ocrData.lastUpdatedDate.value, voterBack.result.documents[0].ocrData.lastUpdatedDate.confidence);
                                existing.Date_Of_Birth__c = getValueWithConfidence(voterBack.result.documents[0].ocrData.dob.value, voterBack.result.documents[0].ocrData.dob.confidence);
                                existing.Age__c = getValueWithConfidence(voterBack.result.documents[0].ocrData.age.value, voterBack.result.documents[0].ocrData.age.confidence);
                                existing.Address__c = getValueWithConfidence(voterBack.result.documents[0].ocrData.address.value, voterBack.result.documents[0].ocrData.address.confidence);
                                update existing;
                            } else {
                                Triangulation_Data__c newData = new Triangulation_Data__c();
                                newData.Voter__c = getValueWithConfidence(voterBack.result.documents[0].ocrData.voterId.value, voterBack.result.documents[0].ocrData.voterId.confidence);
                                newData.Gender__c = getValueWithConfidence(voterBack.result.documents[0].ocrData.gender.value, voterBack.result.documents[0].ocrData.gender.confidence);
                                newData.Voter_Last_Updated__c = getValueWithConfidence(voterBack.result.documents[0].ocrData.lastUpdatedDate.value, voterBack.result.documents[0].ocrData.lastUpdatedDate.confidence);
                                newData.Date_Of_Birth__c = getValueWithConfidence(voterBack.result.documents[0].ocrData.dob.value, voterBack.result.documents[0].ocrData.dob.confidence);
                                newData.Age__c = getValueWithConfidence(voterBack.result.documents[0].ocrData.age.value, voterBack.result.documents[0].ocrData.age.confidence);
                                newData.Address__c = getValueWithConfidence(voterBack.result.documents[0].ocrData.address.value, voterBack.result.documents[0].ocrData.address.confidence);
                                
                                newData.Application_Applicant__c = applicantId;
                                newData.Loan_Application__c = loanid;
                                newData.Source_Type__c = setSource;
                                newData.Document_Type__c = 'Voter Id';
                                insert newData;
                            }
                        }
                        else{
                            retunrResp = 'Error:' + 'No Data from Ocr';
                        }
                    }
                    
                    
                    update app;
                }
                if(imageType =='Driving licence'){
                    //   jsonResp = '{' +
                    //     '"requestId": "014b9c92-2388-4c6b-88b9-b7895db039a4",' +
                    //     '"result": {' +
                    //         '"documents": [' +
                    //             '{' +
                    //                 '"documentType": "DL",' +
                    //                 '"subType": "",' +
                    //                 '"pageNo": null,' +
                    //                 '"ocrData": {' +
                    //                     '"dlNo": {"value": "CIXPD6631F", "confidence": 0.79},' +
                    //                     '"name": {"value": "", "confidence": 0.91},' +
                    //                     '"dob": {"value": "05-01-1995", "confidence": 0.68},' +
                    //                     '"doi": {"value": "13-01-2015", "confidence": 0.66},' +
                    //                     '"doe": {"value": "12-01-2035", "confidence": 0.88},' +
                    //                     '"relationName": {"value": "", "confidence": 0.91},' +
                    //                     '"address": {"value": "kkhkjhj", "confidence": 0.91},' +
                    //                     '"pin": {"value": "", "confidence": 0.77}' +
                    //                 '},' +
                    //                 '"additionalDetails": {' +
                    //                     '"faceDetected": true,' +
                    //                     '"addressSplit": {' +
                    //                         '"building": "", "city": "", "district": "", "pin": "",' +
                    //                         '"floor": "", "house": "", "locality": "", "state": "",' +
                    //                         '"street": "", "complex": "", "landmark": "", "untagged": ""' +
                    //                     '}' +
                    //                 '}' +
                    //             '}' +
                    //         ']' +
                    //     '},' +
                    //     '"statusCode": 101,' +
                    //     '"clientData": {"caseId": "123456"}' +
                    // '}';
                    DLController.DLResponseWrapper dl = new  DLController.DLResponseWrapper();
                    if(resp.getStatusCode()== 200){
                        dl = (DLController.DLResponseWrapper)JSON.deserialize(resp.getBody(), DLController.DLResponseWrapper.class);
                        retunrResp = JSON.serialize(dl);
                        System.debug('dl---'+dl);
                        // Store Address - Ishi
                        // System.debug('Aadhar Addresss------------------------ 677 '+ dl.result.documents[0].additionalDetails.addressSplit.building);
                        if(dl.statusCode == 101){
                            if (dl.result.documents[0].additionalDetails.addressSplit.building != null ||
                                dl.result.documents[0].additionalDetails.addressSplit.floor != null ||
                                dl.result.documents[0].additionalDetails.addressSplit.house != null) {
                                    
                                    Applicant_Address__c addressAadhar = new Applicant_Address__c();
                                    
                                    // Using ternary operator to check if the value is null or not and assign it
                                    String building = dl.result.documents[0].additionalDetails.addressSplit.building != null ? dl.result.documents[0].additionalDetails.addressSplit.building : '';
                                    String floor = dl.result.documents[0].additionalDetails.addressSplit.floor != null ? dl.result.documents[0].additionalDetails.addressSplit.floor : '';
                                    String house = dl.result.documents[0].additionalDetails.addressSplit.house != null ? dl.result.documents[0].additionalDetails.addressSplit.house : '';
                                    String street = dl.result.documents[0].additionalDetails.addressSplit.street != null ? dl.result.documents[0].additionalDetails.addressSplit.street : '';
                                    String locality = dl.result.documents[0].additionalDetails.addressSplit.locality != null ? dl.result.documents[0].additionalDetails.addressSplit.locality : '';
                                    String city = dl.result.documents[0].additionalDetails.addressSplit.city != null ? dl.result.documents[0].additionalDetails.addressSplit.city : '';
                                    String district = dl.result.documents[0].additionalDetails.addressSplit.district != null ? dl.result.documents[0].additionalDetails.addressSplit.district : '';
                                    String state = dl.result.documents[0].additionalDetails.addressSplit.state != null ? dl.result.documents[0].additionalDetails.addressSplit.state : '';
                                    String pinCode = dl.result.documents[0].additionalDetails.addressSplit.pin != null ? dl.result.documents[0].additionalDetails.addressSplit.pin : '';
                                    
                                    // Using String.join with ternary checks
                                    addressAadhar.Address_Line_1__c = String.join(new List<String>{house, floor, building}, ', ');
                                    addressAadhar.Address_Line_2__c = String.join(new List<String>{street, locality}, ', ');
                                    addressAadhar.Address_Line_3__c = String.join(new List<String>{district, city, state}, ', ');
                                    addressAadhar.Address_Source__c = 'Driving License';
                                    addressAadhar.Document_Details__c = documentId;
                                    
                                    // Clean up address lines if necessary (no need to change this logic)
                                    for (String line : new List<String>{addressAadhar.Address_Line_1__c, addressAadhar.Address_Line_2__c, addressAadhar.Address_Line_3__c}) {
                                        if (String.isNotBlank(line)) {
                                            line = line.replaceAll('^,\\s*|\\s*,\\s*$', ''); 
                                        }
                                    }
                                    
                                    // Handle pin code and assign to address if available
                                    if (String.isNotBlank(pinCode)) {
                                        List<Pincode_Master__c> pincodeList = [
                                            SELECT Id, Name FROM Pincode_Master__c WHERE Name = :pinCode LIMIT 1
                                        ];
                                        if (!pincodeList.isEmpty()) {
                                            addressAadhar.Pincode__c = pincodeList[0].Id;
                                        }
                                    }
                                    
                                    addressAadhar.Applicant__c = applicantId;
                                    System.debug('addressAadhar------- 677 ' + addressAadhar);
                                    
                                    insert addressAadhar;
                                }
                        }
                        else{
                            retunrResp = 'Error:' + 'No Data from Ocr';
                        }
                    }
                    else if(resp.getStatusCode()== 503){
                        retunrResp = 'Error:' + 'Service Temporarily Unavailable';
                    }
                    else{
                        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                        String errorCode = (String) responseMap.get('error');
                        for(API_Exceptions__mdt execeptionMeta : allMetaData.values()){
                            if(execeptionMeta.Error_Code__c == errorCode){
                                retunrResp = 'Error: ' + execeptionMeta.Error_Message__c;
                            }
                            else{
                            } retunrResp = 'Error:' + 'Please try again later.';
                        }
                    }       
                    System.debug('resp---');
                    resultMessage = 'Sucess';
                    String newId = storOcrRequestandResponseAsFile(respWrapper.payload,imageType, resp.getBody(),applicantId,loanid);
                    integrationDetail.Calling_Source__c = wrapper.type; 
                    integrationDetail.Request_JSON__c = newId; 
                    integrationDetail.Response_JSON__c = resp.getBody();
                    //  integrationDetail.Status__c = '200'; 
                    integrationDetail.Method_Type__c = intSetting.Request_Method__c; 
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c; 
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Related_Record_Id__c = applicantId;
                    integrationDetail.Name = 'Loan OCR DL'; 
                    integrationDetail.Loan_Application__c = loanid; 
                    insert integrationDetail;
                    if(String.valueof(resp.getStatusCode())== '200'){
                        if(dl.statusCode == 101){
                            app[0].Drivers_License_Number__c = dl.result.documents[0].ocrData.dlNo.value;
                            app[0].Drivers_License_Address__c = dl.result.documents[0].ocrData.address.value;
                        }
                        else{
                            retunrResp = 'Error:' + 'No Data from Ocr';
                        }
                    }
                    update app;
                }
            }
            system.debug('result-->'+retunrResp);
            return retunrResp;
//   }
//   catch (Exception e) {
//     String returnResp = 'Error: We couldn\'t auto-fill some details from the document. Please review and complete the missing information manually.';
//     return returnResp;
// }
    }
    public static String getValueWithConfidence(String val, Decimal conf) {
        String valWithConfidence = (val != null && !String.isEmpty(val)) ? val + ' (' + (conf != null ? String.valueOf(conf*100)+' %' : 'N/A') + ')' : '';
        System.debug('valWithConfidence: '+valWithConfidence);
        return valWithConfidence;
    }
    public static String storOcrRequestandResponseAsFile(String request, String Name, String response, Id applicantId, Id loanId) {
        // Create the combined request and response string
        String newreqres = 'Request :' +request + (String.isNotBlank(response) ? 'Response : '+response : '');
        
        // Create ContentVersion (File)
        ContentVersion content = new ContentVersion();
        content.Title = Name + '.txt';
        content.PathOnClient = Name + '.txt';
        content.VersionData = Blob.valueOf(newreqres);
        content.IsMajorVersion = true;
        insert content;
        
        // Fetch ContentDocumentId
        List<ContentVersion> contentVersions = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id LIMIT 1];
        
        // Create Document_Details__c record
        Document_Details__c checklist = new Document_Details__c();
        checklist.Applicant__c = applicantId;
        checklist.Content_Document_Id__c = contentVersions[0].ContentDocumentId;
        checklist.Loan_Application__c = loanId;
        checklist.Name = Name + ' Request and Response File';
        insert checklist;
        
        // Create ContentDocumentLink to link the document to the checklist record
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = checklist.Id;
        cdl.ContentDocumentId = contentVersions[0].ContentDocumentId;
        cdl.ShareType = 'V'; // Viewer permission
        cdl.Visibility = 'AllUsers'; // Make it visible to all users
        insert cdl;
        
        // Debugging message
        System.debug('New response stored successfully.');
        return checklist.Id;
    }
    
    
}