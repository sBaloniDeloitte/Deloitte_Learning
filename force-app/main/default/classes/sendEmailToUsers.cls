public with sharing class sendEmailToUsers {
        static string conLabels = 'OrgWideFromAddressEmail,Days_to_process_loan';
        
        public static Map<string, string> constants = Utility.getConstants(conLabels);
        //getting the value of constants
        @AuraEnabled
        public static Map<string, string> getConstants(){
            return constants;
        }
        
        @AuraEnabled
        public static void sendEmailToUsers(String loanId, Boolean callQueueableCls) {
            // Query to fetch the applicants for the given loan application
            String labelValue = System.Label.App_form_image_conditions;
            List<String> applicantTypesToExclude = new List<String>();

            if(String.isNotBlank(labelValue)){
                for(String val : labelValue.split(',')){
                    applicantTypesToExclude.add(val.trim());
                }
            }
            List<Application_Applicant__c> appList = [
            SELECT Id, Applicant_Name__c,Loan_Application__r.name,Applicant_Type__c,Name_of_Organization__c,Customer_Type__c,Customer_LMS_Id__c,Customer__r.SF_Customer_ID__c, Salutation__c,First_Name__c, Last_Name__c, Company__c, Loan_Application__r.Product__c, Email__c, Mobile_Number__c, Loan_Application__r.Owner.Name FROM Application_Applicant__c 
            WHERE Loan_Application__c = :loanId AND Applicant_Type__c NOT IN :applicantTypesToExclude
        ];
            
            
            List<Integration_Details__c> communicationList= [SELECT Id FROM Integration_Details__c WHERE Loan_Application__c = :loanId AND Endpoint__c = 'Acknowledge of login'];
            
            
            if (!appList.isEmpty()) {
                String loanProduct;
                String messageWrapper;
                Integration_Details__c integration = new Integration_Details__c();
                List<product2> productList= [SELECT Id, name, Description FROM product2 WHERE  Loan_Application__c = :loanId AND RecordType.name = 'Product'];
                List<CommunicationEventWrapper.LoginAcknowledgeWrapper> loginAcknowledgeList= new List<CommunicationEventWrapper.LoginAcknowledgeWrapper>();
                List<String> toAddresses = new List<String>();
                if(productList.size()>0){
                    loanProduct= productList[0].name;
                    system.debug('loanProduct   '+loanProduct);
                }
                // Gather all email addresses
                for (Application_Applicant__c app : appList) {
                    List<String> sfId= app.Customer__r.SF_Customer_ID__c.split('-');
                    String cifNumber = sfId[1].trim();
                    if (!String.isEmpty(app.Email__c)) {
                        toAddresses.add(app.Email__c);
                    }
                    
                    if(app.Applicant_Type__c == 'Primary Applicant'){
                        // loanProduct = app.Loan_Application__r.Product__c;
                        CommunicationEventWrapper.LoginAcknowledgeWrapper loginWrapper = new CommunicationEventWrapper.LoginAcknowledgeWrapper();
                        loginWrapper.Salutation = app.Customer_Type__c == 'Individual' ? (String.isNotBlank(app.Salutation__c) ? app.Salutation__c: '') : 'M/s';
                        loginWrapper.FirstName = String.isNotBlank(app.First_Name__c)? app.First_Name__c :'';
                        loginWrapper.LastName = String.isNotBlank(app.Last_Name__c) ? app.Last_Name__c: '';
                        loginWrapper.CompanyName = app.Customer_Type__c == 'Individual' ? (String.isNotBlank(app.Company__c) ?  app.Company__c: '') :  (String.isNotBlank(app.Name_of_Organization__c) ?  app.Name_of_Organization__c: '');
                        // loginWrapper.ProductName = loanProduct != null ? (loanProduct == 'Term Loan' ? 'BL': (loanProduct == 'Flexi Funds' ? 'BD': '')): '';
                        loginWrapper.ProductName = loanProduct != null ? 'AHL': '';
                        loginWrapper.LANNumber = String.isNotBlank(app.Loan_Application__r.name) ? app.Loan_Application__r.name : '';
                        loginWrapper.CustomerCategory = app.Customer_Type__c == 'Individual' ? 'RETAIL': (app.Customer_Type__c == 'Non Individual' ? 'CORP' :'' );
                        loginWrapper.emailId = String.isNotBlank(app.Email__c) ? app.Email__c: '';
                        loginWrapper.NoofDays = constants.get('Days_to_process_loan');
                        loginWrapper.mobile_number = app.Mobile_Number__c != null ? String.valueOf(app.Mobile_Number__c): '';
                        loginWrapper.applicantType = String.isNotBlank(app.Applicant_Type__c) ? app.Applicant_Type__c: '';
                        loginWrapper.whatsaap_number = app.Mobile_Number__c != null ? String.valueOf(app.Mobile_Number__c): '';
                        loginWrapper.ProductDescription = productList.size()>0 ? (productList[0].Description != null? productList[0].Description : '') : '';
                        loginWrapper.cif = String.isNotBlank(app.Customer_LMS_Id__c) ? app.Customer_LMS_Id__c: cifNumber;
                        loginAcknowledgeList.add(loginWrapper);
                    }
                    
                }
                
                if(communicationList.size()<=0){
                    messageWrapper = JSON.serialize(loginAcknowledgeList);
                    messageWrapper = messageWrapper.replace('NoofDays', 'No.ofDays');
                    
                    if(messageWrapper != null && messageWrapper!= '' && loanProduct!= null && loanProduct!= ''){
                        integration.name = 'Communication Event';
                        integration.Loan_Application__c = loanId;
                        integration.Endpoint__c = 'Acknowledge of login';
                        integration.Communication_Status__c = 'Published';
                        integration.Request_JSON__c = messageWrapper;
                        // insert integration;
                        
                        System.debug('Message wrapper----'+messageWrapper);
                        String commProduct = loanProduct != null ? 'Affordable Housing loan' : '';
                        Communication__e event = new Communication__e(
                            Message__c = messageWrapper,
                        Record_Id__c = integration.Id,
                        Type__c = 'Acknowledge of login',
                        product__c = commProduct
                            );
                        
                        Database.SaveResult result = EventBus.publish(event);
                        if (result.isSuccess()) {
                            System.debug('Platform Event published successfully.'+result);
                        } else {
                            // Log errors if publishing failed
                            for (Database.Error error : result.getErrors()) {
                                System.debug('Error publishing event: ' + error.getMessage());
                            }
                        }
                    }
                }
                
                if (!toAddresses.isEmpty()) {
                    try {
                        Map<String, String> input = new Map<String, String>();
                        input.put('oppId', loanId);
                        Utility_V1.ProductWrapper productWrapper = Utility_V1.getProductDetails(input);
                        string templateName = productWrapper.isHLRelated ? 'HL Application Form' : 'AHL Application Form';
                        
                        EmailTemplate emailTemplate;
                        if ((loanProduct == 'Affordable Home Loan' || loanProduct == 'Affordable Non-Home Loan') ||(loanProduct=='Home Loan'||loanProduct=='Non-Housing Loan'||loanProduct=='Flexi Loan')) {
                            emailTemplate = [
                                SELECT Id, HtmlValue , Subject FROM EmailTemplate WHERE Name =: templateName
                            ];
                        }
                        
                        Opportunity loanRecord = [
                            SELECT Loan_Application_Number__c , Product__c
                            FROM Opportunity 
                            WHERE Id = :loanId
                        ];
                        // Application_Applicant__c app1;
                        for (Application_Applicant__c app : appList) {
                            Application_Applicant__c app1;
                            // if (app.Applicant_Type__c == 'Primary Applicant') {
                                app1 = app;
                                //     break;
                            // }
                        // }
                        if (app1 != null && emailTemplate != null) {
                            List<OrgWideEmailAddress> owdEmail = [
                                SELECT Id FROM OrgWideEmailAddress WHERE Address = :constants.get('OrgWideFromAddressEmail')
                            ];
                            // Create the email message
                            String body = emailTemplate.HtmlValue;
                            String subject = emailTemplate.Subject;
                            if ((loanProduct == 'Affordable Home Loan'||  loanProduct == 'Affordable Non-Home Loan') ||(loanProduct=='Home Loan'||loanProduct=='Non-Housing Loan'||loanProduct=='Flexi Loan')) {
                                subject = loanRecord.Loan_Application_Number__c + ': ' + subject;
                                String lan = loanRecord.Loan_Application_Number__c;
                                //String days = '24 Hours';
                                String url = 'https://godrejhf.com/ghf/information-and-policies.html#TnCDSfPG';
                                if(app1.Salutation__c != null && app1.Applicant_Name__c != null && lan != null){
                                    body = body.replace('{Salutation}', (app.Customer_Type__c == 'Individual' ? (app1.Salutation__c != null ? app1.Salutation__c : ''): 'M/S'));
                                    body = body.replace('{Name}', app1.Applicant_Name__c);
                                    body = body.replace('{Time}', '24 Hrs');
                                    body = body.replace('{LoanApplicationNumber}', lan);
                                    body = body.replace('{#termsLink}', 'https://godrejhf.com/ghf/information-and-policies.html#TnCDSfPG');
                                }
                                
                            } else {
                                String param0 = app1.Salutation__c != null ? app1.Salutation__c : '';
                                String param1 = app1.First_Name__c != null ? app1.First_Name__c : '';
                                String param2 = app1.Last_Name__c != null ? app1.Last_Name__c : '';
                                String param3 = loanRecord.Product__c != null ? loanRecord.Product__c : '';
                                
                                
                                List<Object> params = new List<Object>{param0,param1,param2,param3};
                                // body = String.format(body, params);
                                body = body.replace('{0}', param0);
                                body = body.replace('{1}', param1);
                                body = body.replace('{2}', param2);
                                body = body.replace('{3}', param3);
                            }
                            
                            
                            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                            if (!owdEmail.isEmpty()) {
                                mail.setOrgWideEmailAddressId(owdEmail[0].Id);
                            }
                            mail.setToAddresses(toAddresses);
                            mail.setSubject(subject);
                            mail.setHtmlBody(body);
                            mail.setTemplateId(emailTemplate.Id);
                            
                            Map<String, String> inputMap = new Map<String, String>();
                            // inputMap.put('email', String.join(toAddresses, ','));
                            system.debug('app1.Email__c  '+app1.Email__c);
                            inputMap.put('email', app1.Email__c);
                            // inputMap.put('subject', emailTemplate.Subject);
                            inputMap.put('subject', subject);
                            inputMap.put('content', body);
                            inputMap.put('loanId', loanId);
                            inputMap.put('applicantId', app1.Id);
                            inputMap.put('processName','Email');
                            // Generate PDF content dynamically using a Visualforce page
                            Blob pdfContent;
                            String pdfBase64;
                            String appFormBase64;
                            //   if (loanProduct == 'Affordable Home Loan' ||(loanProduct=='Home Loan'||loanProduct=='Non-Housing Loan'||loanProduct=='Flexi Loan')) {
                                    
                            //         COMM_DocumentDetailsScreenController.mergedDocWrapper wrapper = COMM_DocumentDetailsScreenController.fetchMergedAppFormDocSales(loanId);
                            //         if (wrapper != null || !String.isBlank(wrapper.fileData)) {
                            //             pdfBase64 = wrapper.fileData;
                            //             system.debug('appFormBase64 fetched '+pdfBase64);
                            //         }
                            //     } else {
                            pdfContent = generatePdf(loanId);
                            if (pdfContent != null) {
                                pdfBase64 = EncodingUtil.base64Encode(pdfContent);
                            }
                            // }
                            system.debug('inputMap  '+inputMap);
                            
                            if (pdfBase64 != null) {
                                
                                system.debug('Checking base64 here-->'+pdfBase64);
                                inputMap.put('base64String', pdfBase64);
                                inputMap.put('fileType', 'pdf');
                                inputMap.put('filename', 'LoanApplicationDetails');
                            }
                            
                            if (callQueueableCls) {
                                System.enqueueJob(new QueueableLogicForSendEmail(inputMap));
                            }
                            
                            if (!callQueueableCls) {
                                EmailController.initiateAPIRequest(inputMap);
                            }
                            // EmailController.initiateAPIRequest(inputMap);
                            // insert integration;
                            
                        }
                    }
                } catch (Exception e) {
                    System.debug('Error sending email: ' + e.getMessage());
                    System.debug('Error sending email: ' + e.getLineNumber());
                }
            }
        }
    }
    
    // Helper method to generate PDF content dynamically
    private static Blob generatePdf(String loanId) {
        // Reference the Visualforce page and pass parameters if needed
        PageReference pdfPage = Page.FCULoanApplicationForm;
        pdfPage.getParameters().put('Id', loanId); // Passing loanId as a parameter to the page
        pdfPage.setRedirect(true);
        return pdfPage.getContent(); // Returns the PDF content as Blob
    }
    
    //code to generate sms communication
    @AuraEnabled
    public static String sendSms(String loanId) {
        try {
            // Fetch all applicants
            List<Application_Applicant__c> appList = [
            SELECT Id, Salutation__c, Applicant_Name__c, Mobile_Number__c, Loan_Application__c
            FROM Application_Applicant__c
            WHERE Loan_Application__c = :loanId
        ];
            
            // Fetch SMS template
            SMS_Template__mdt appFormSms = [
            SELECT String_1__c, String_2__c, String_3__c
            FROM SMS_Template__mdt
            WHERE MasterLabel = 'App Form SMS'
            LIMIT 1
        ];
            
            // Fetch Opportunity
            Opportunity opp = [
            SELECT Id,Name, Loan_Application_Number__c
            FROM Opportunity
            WHERE Id = :loanId
            LIMIT 1
        ];
            String loanAppNum = opp != null ? opp.Loan_Application_Number__c : '';
            
            // Default S3 link
            String s3link = '';
            String shortUrl = '';
            String searchTerm =  opp.Name != null ? opp.Name : '';
            // Fetch document details
            Document_Details__c docDetail = [
            SELECT Content_Document_Id__c
            FROM Document_Details__c
            WHERE Loan_Application__c = :loanId AND Document_Type__c = 'Merged Document-Sales' AND Name LIKE :('%' + searchTerm + '%') order by CreatedDate DESC
            LIMIT 1
        ];
            
            if (docDetail != null) {
                ContentVersion cv = [
                SELECT VersionData, Id, Title, ContentDocumentId, FileExtension
                FROM ContentVersion
                WHERE ContentDocumentId = :docDetail.Content_Document_Id__c
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            system.debug('docDetail: ' + docDetail);
                
                // Fetch integration settings
                Integration_Settings__c s3IntSetting = [
                SELECT Endpoint__c, Content_Type__c, Request_Method__c
                FROM Integration_Settings__c
                WHERE Name = 'S3 Upload Notification'
                LIMIT 1
            ];
                
                // Prepare and send HTTP request
                Map<String, Object> s3Payload = new Map<String, Object>{
                    'fileId' => cv.Id,
                    'fileName' => cv.Title + '.' + cv.FileExtension
                };
                HttpRequest req = new HttpRequest();
                req.setEndpoint(s3IntSetting.Endpoint__c);
                req.setMethod(s3IntSetting.Request_Method__c);
                req.setHeader('Content-Type', s3IntSetting.Content_Type__c);
                req.setHeader('Origin', System.Url.getOrgDomainUrl().toExternalForm());
                req.setBody(JSON.serialize(s3Payload));
                req.setTimeout(120000);

                
                Http http = new Http();
                HttpResponse s3Resp = http.send(req);
                System.debug('the error in s3 is'+s3Resp.getBody());
                if (s3Resp.getStatusCode() == 200) {
                    Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(s3Resp.getBody());
                    if (respMap.containsKey('presignedUrl') && respMap.get('presignedUrl') != null) {
                        s3link = (String) respMap.get('presignedUrl');
                    } else {
                        return 'Error: S3 response missing "presignedUrl"';
                    }
                } else {
                    return 'Error: S3 upload failed with status ' + s3Resp.getStatusCode();
                }
            }
            
            // Proceed only if s3link is not empty
            if (String.isBlank(s3link)) {
                return 'Error: S3 link is empty, cannot proceed to shorten URL';
            }
            
            // Call URL shortener
            Map<String, String> inputMapURL = new Map<String, String>{
                's3link' => s3link,
                'processName' => 'Loan URL Shortening Service',
                'recordId' => appList[0].id,
                'loanId' => loanId
            };
            System.debug('the input map for url is' + inputMapURL);
            String shortUrlResponse = URLShorteningController.urlShoetening(inputMapURL);
            
            if (!shortUrlResponse.contains('Error:')) {
                URLShorteningController.URLShorteningResponseServiceWrapper urlRespWrapper =
                    (URLShorteningController.URLShorteningResponseServiceWrapper) JSON.deserialize(
                    shortUrlResponse,
                URLShorteningController.URLShorteningResponseServiceWrapper.class
                    );
                if (urlRespWrapper.status == true && urlRespWrapper.data.short_link_with_domain != null) {
                    shortUrl = urlRespWrapper.data.short_link_with_domain;
                } else {
                    return 'Error: URL shortener returned invalid status or empty URL';
                }
            } else {
                return 'Error: URL shortening failed - ' + shortUrlResponse;
            }
            
            // Proceed only if shortUrl is not empty
            if (String.isBlank(shortUrl)) {
                return 'Error: Short URL is empty, SMS cannot be sent';
            }
            
            // Prepare and send SMS
            for (Application_Applicant__c app : appList) {
                String mobileNumber = app.Mobile_Number__c;
                String applicantName = app.Applicant_Name__c != null ? app.Applicant_Name__c : '';
                String salutation = app.Salutation__c != null ? app.Salutation__c : 'M/S';
                String smsBody = '';
                smsBody += appFormSms.String_1__c != null ? appFormSms.String_1__c : '';
                smsBody += appFormSms.String_2__c != null ? ' ' + appFormSms.String_2__c : '';
                smsBody += appFormSms.String_3__c != null ? ' ' + appFormSms.String_3__c : '';
                smsBody = smsBody.replace('{#var#}', salutation);
                smsBody = smsBody.replace('{#var1#}', applicantName);
                smsBody = smsBody.replace('{#var2#}', loanAppNum);
                smsBody = smsBody.replace('{#var3#}', shortUrl);
                smsBody = smsBody.replace('{#var4#}', '24 Hrs');
                smsBody = smsBody.replace('{#var5#}', 'https://godrejhf.com/ghf/information-and-policies.html#TnCDSfPG');
                
                if (!String.isBlank(mobileNumber) && !String.isBlank(smsBody)) {
                    // Send SMS for each applicant, even if mobile number is same
                    // System.enqueueJob(
                    //     new QueueableLogicForSendSMS(
                    //         new List<String>{mobileNumber},
                    //         smsBody,
                    //         constants.get('Salesforce')
                    //     )
                    // );
                    SMSRequestService.sendSMS(new List<String>{mobileNumber}, smsBody, constants.get('Salesforce'));
                }
            }
            return 'Success';
        } catch (Exception e) {
            System.debug('Error sending SMS: '+e.getMessage() + e.getLineNumber());
            return 'Error: ' + e.getMessage();
        }
    }
}