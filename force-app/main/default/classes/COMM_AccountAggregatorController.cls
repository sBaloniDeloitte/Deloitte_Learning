public with sharing class COMM_AccountAggregatorController {

    private static final Long RESEND_TWENTY_FOUR_HOURS_MS = 24L * 60L * 60L * 1000L;
    private static final String RESEND_CONSENT_ENDPOINT = 'Callout:LOS_AHL_Account_aggregator_consentRequest';

    @AuraEnabled
    public static String resendAAConsentLink(String recordId, String applicantId, String mobileNumber, String consentHandle) {
        try {
            if (String.isBlank(recordId)) {
                return 'Error: Missing loan record id';
            }
            if (String.isBlank(mobileNumber)) {
                return 'Error: Mobile number is required to resend the link';
            }

            List<Integration_Details__c> intDetList = [
                SELECT Id, Name, Request_JSON__c, Response_JSON__c, CreatedDate, Loan_Application__c, Endpoint__c, Short_link__c
                FROM Integration_Details__c
                WHERE Endpoint__c = :RESEND_CONSENT_ENDPOINT
                  AND Loan_Application__c = :recordId
                ORDER BY CreatedDate DESC
            ];

            if (intDetList.isEmpty()) {
                return 'Error: No previous AA consent request found for this loan';
            }

            final String normalizedMobile = normalizeResendMobile(mobileNumber);
            Integration_Details__c matched = null;
            Map<String, Object> matchedPayload = null;

            for (Integration_Details__c intDet : intDetList) {
                if (String.isBlank(intDet.Request_JSON__c)) continue;
                try {
                    Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(intDet.Request_JSON__c);
                    String reqMobile = safeGetResendString(payload, 'partyIdentifierValue');
                    if (String.isNotBlank(reqMobile) && normalizeResendMobile(reqMobile).equals(normalizedMobile)) {
                        matched = intDet;
                        matchedPayload = payload;
                        break;
                    }
                } catch (Exception ex) {
                    System.debug('resendAAConsentLink skip ' + intDet.Id + ' - ' + ex.getMessage());
                }
            }

            if (matched == null) {
                return 'Error: No previous consent request found for mobile ' + mobileNumber;
            }

            Long ageMs = System.now().getTime() - matched.CreatedDate.getTime();
            if (ageMs > RESEND_TWENTY_FOUR_HOURS_MS) {
                return 'Error: Consent link can only be resent within 24 hours of initiation';
            }

            if (String.isBlank(matched.Short_link__c)) {
                return 'Error: URL is not present for this consent request. Please initiate a fresh Account Aggregator request.';
            }

            String applicantIdToUse = safeGetResendString(matchedPayload, 'applicantId');
            if (String.isBlank(applicantIdToUse)) {
                applicantIdToUse = applicantId;
            }
            if (String.isBlank(applicantIdToUse)) {
                return 'Error: Applicant Id could not be determined for the resend';
            }

            return resendCommunications(recordId, applicantIdToUse, mobileNumber, matched.Short_link__c);

        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }

    private static String resendCommunications(String loanId, String applicantId, String mobileNumber, String shortLink) {
        String templateName = System.Label.whatsapp_sms_template_for_acc;
        Integration_Details__c integrationDetailWhatsapp = null;

        Application_Applicant__c app = [
            SELECT Id, Email__c, Gender__c, Salutation__c, Customer_Profile__c, Customer_Type__c,
                   Pan_Name__c, Mobile_Number__c, Loan_Application__r.Product__c, PAN_Number__c,
                   DOB__c, DOI__c, Applicant_Name__c
            FROM Application_Applicant__c
            WHERE Id = :applicantId
        ];

        List<Product2> subProduct = [
            SELECT Id, Name, Product__r.Name
            FROM Product2
            WHERE RecordType.Name = :constants.get('Sub_Product')
              AND Product__r.Product_Type__c = 'Parent'
              AND Loan_Application__c = :loanId
            LIMIT 1
        ];

        Map<String, Communication_Event_Product_Mapping__mdt> productMetaMapping = Communication_Event_Product_Mapping__mdt.getAll();
        Map<String, Communication_Event_Product_Mapping__mdt> productMapping = new Map<String, Communication_Event_Product_Mapping__mdt>();
        for (Communication_Event_Product_Mapping__mdt meta : productMetaMapping.values()) {
            productMapping.put(meta.Product_Name__c, meta);
        }

        String productName = '';
        if (subProduct.size() > 0) {
            if (subProduct[0].Product__r.Name == 'Affordable Home Loan' || subProduct[0].Product__r.Name == 'Affordable Non-Home Loan') {
                productName = app.Loan_Application__r.Product__c;
            } else {
                productName = productMapping.containsKey(subProduct[0].Name) ? productMapping.get(subProduct[0].Name).Product_Field__c : '';
            }
        }

        List<SMS_Template__mdt> accAggSms = [
            SELECT Id, String_1__c, String_2__c, String_3__c
            FROM SMS_Template__mdt
            WHERE MasterLabel = 'Account Aggregator'
        ];

        if (accAggSms.size() > 0) {
            String smsBody = '';
            if (accAggSms[0].String_1__c != null) smsBody += accAggSms[0].String_1__c;
            if (accAggSms[0].String_2__c != null) smsBody += accAggSms[0].String_2__c;
            if (accAggSms[0].String_3__c != null) smsBody += accAggSms[0].String_3__c;
            smsBody = smsBody.replace('{0}', app.Customer_Type__c == 'Individual' ? app.Salutation__c : 'M/s');
            smsBody = smsBody.replace('{1}', app.Applicant_Name__c);
            smsBody = smsBody.replace('{2}', productName);
            smsBody = smsBody.replace('{3}', shortLink);
            smsBody = smsBody.replace('{4}', app.Customer_Profile__c == 'Salaried' ? '6' : '12');
            System.debug('resend smsBody----' + smsBody);
            SMSRequestService.sendSMS(new List<String>{mobileNumber}, smsBody, constants.get('Salesforce'));
        }

        if (String.isNotBlank(templateName)) {
            System.debug('resend: inside whatsapp callout');
            List<String> params = new List<String>();
            params.add(app.Customer_Type__c == 'Individual' ? app.Salutation__c : 'M/s');
            params.add(app.Applicant_Name__c);
            params.add(productName);
            params.add(shortLink);
            params.add(app.Customer_Profile__c == 'Salaried' ? '6' : '12');
            params.add('48');

            Map<String, Object> whatsappResult = SMSRequestService.sendWhatsappSMS('91' + mobileNumber, templateName, params);
            integrationDetailWhatsapp = new Integration_Details__c();
            integrationDetailWhatsapp.Name = 'WhatsappSMS';
            integrationDetailWhatsapp.Object_Name__c = 'Opportunity';
            integrationDetailWhatsapp.Loan_Application__c = loanId;
            integrationDetailWhatsapp.EndPoint__c = 'callout:whatsappSMS';
            integrationDetailWhatsapp.Request_JSON__c = (String) whatsappResult.get('requestJSON');
            if (whatsappResult != null && whatsappResult.get('resp') != null) {
                integrationDetailWhatsapp.Response_JSON__c = (String) whatsappResult.get('resp');
            }
        } else {
            System.debug('resend: Template name is blank, skipping WhatsApp SMS call.');
        }

        List<EmailTemplate> emailTemplate = [
            SELECT Id, Subject, HtmlValue
            FROM EmailTemplate
            WHERE Name = 'Account Aggregator'
        ];

        if (emailTemplate.size() > 0 && String.isNotBlank(app.Email__c)) {
            Map<String, String> inputMap = new Map<String, String>();
            String emailBody = emailTemplate[0].HtmlValue;
            emailBody = emailBody.replace('{#varSal}', app.Customer_Type__c == 'Individual' ? app.Salutation__c : 'M/s');
            emailBody = emailBody.replace('{#Link}', shortLink);
            emailBody = emailBody.replace('{#varMonth}', app.Customer_Profile__c == 'Salaried' ? '6' : '12');
            emailBody = emailBody.replace('{#varName}', app.Applicant_Name__c);
            emailBody = emailBody.replace('{#Product}', productName);
            inputMap.put('subject', emailTemplate[0].Subject);
            inputMap.put('content', emailBody);
            inputMap.put('email', app.Email__c);
            inputMap.put('applicantId', applicantId);
            inputMap.put('loanId', loanId);
            inputMap.put('processName', 'Email');
            EmailController.initiateAPIRequest(inputMap);
        }


        List<Integration_Details__c> toInsert = new List<Integration_Details__c>{};
        if (integrationDetailWhatsapp != null) {
            toInsert.add(integrationDetailWhatsapp);
        }
        insert toInsert;

        return 'Account Aggregator consent link resent successfully';
    }

    private static String normalizeResendMobile(String m) {
        if (String.isBlank(m)) return '';
        String digits = m.replaceAll('[^0-9]', '');
        return digits.length() > 10 ? digits.substring(digits.length() - 10) : digits;
    }

    private static String safeGetResendString(Map<String, Object> m, String key) {
        if (m == null || !m.containsKey(key)) return null;
        Object v = m.get(key);
        return v == null ? null : String.valueOf(v);
    }

    static string conLabels = 'Initiated,Salesforce,Sub_Product';

    public static Map<string, string> constants = Utility.getConstants(conLabels);

    @AuraEnabled
    public static Map<string, string> getConstants() {
        return constants;
    }

    @AuraEnabled
    public static String sendAccountAggrequest(Map<String, String> inputMap1) {
        try {
            List<string> validatemandate = new List<string>();
            List<string> constructpayload = new List<string>();
            String resultMessage;
            String loanId = inputMap1.get('recordId');
            String applicantId = inputMap1.get('applicantId');
            String processName = inputMap1.get('processName');
            String mobileNumber = inputMap1.get('mobileNumber');
            String docId = inputMap1.get('docId');
            String templateName = System.Label.whatsapp_sms_template_for_acc;
            Integration_Details__c integrationDetailWhatsapp = new Integration_Details__c();

            Application_Applicant__c app = [SELECT id, Email__c, Gender__c, Salutation__c, Customer_Profile__c, Customer_Type__c, Pan_Name__c, Mobile_Number__c, Loan_Application__r.Product__c, PAN_Number__c, DOB__c, DOI__c, Applicant_Name__c FROM Application_Applicant__c WHERE id = :applicantId];
            List<Document_Master__c> dm = [SELECT id, Name, Document_Category__c FROM Document_Master__c WHERE Document_Name__c = '12 months bank statement'];

            String returnResp;
            Integration_Master__mdt metadata = [SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, Client_Id__c, Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, Refresh_Allowed__c, Activity_Name__c FROM Integration_Master__mdt WHERE Activity_Name__c = :processName LIMIT 1];

            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
            wrapper.recordId = applicantId;
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
            wrapper.handlername = metadata.Handler_Class__c;
            wrapper.docId = docId;
            wrapper.mobNumber = mobileNumber;

            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c FROM Integration_Settings__c WHERE Name = 'Loan Applicant Account Aggregator' LIMIT 1];
            Map<String, API_Exceptions__mdt> allMetaData = API_Exceptions__mdt.getAll();

            Integration_Settings__c intSetting = intSettingList[0];
            system.debug('respWrapper.prerequisiteError: ' + respWrapper.prerequisiteError);
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c = String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                resultMessage = String.join(respWrapper.prerequisiteError, ', ');
                returnResp = resultMessage;
            } else {
                Map<String, String> integrationRequestMap = new Map<String, String>();
                integrationRequestMap.put('intSettingName', 'Loan Applicant Account Aggregator');
                integrationRequestMap.put('requestJSON', respWrapper.payload);
                String bearer = Utility.getAccessToken();
                System.debug('bearer----' + bearer);
                integrationRequestMap.put('bearer', bearer);
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);

                AccountAggregatorResponseServiceWrapper responseJSON = new AccountAggregatorResponseServiceWrapper();
                if (resp.getStatusCode() == 200) {
                    responseJSON = (AccountAggregatorResponseServiceWrapper) JSON.deserialize(resp.getBody(), AccountAggregatorResponseServiceWrapper.class);
                    if (responseJSON.status == 'Success') {
                        System.debug('the url is: ' + responseJSON.data.urlDetail.data.webRedirectionUrl);
                        Map<String, String> inputMapURL = new Map<String, String>();
                        inputMapURL.put('s3link', responseJSON.data.urlDetail.data.webRedirectionUrl);
                        inputMapURL.put('processName', 'Loan URL Shortening Service');
                        inputMapURL.put('recordId', applicantId);
                        inputMapURL.put('loanId', loanId);
                        String shortUrl = URLShorteningController.urlShoetening(inputMapURL);

                        if (shortUrl.contains('Error:')) {
                            returnResp = shortUrl;
                        } else {
                            List<Product2> subProduct = [SELECT Id, Name, Product__r.Name FROM Product2 WHERE RecordType.Name = :constants.get('Sub_Product') AND Product__r.Product_Type__c = 'Parent' AND Loan_Application__c = :loanId LIMIT 1];
                            URLShorteningController.URLShorteningResponseServiceWrapper urlRespWrapper = (URLShorteningController.URLShorteningResponseServiceWrapper) JSON.deserialize(shortUrl, URLShorteningController.URLShorteningResponseServiceWrapper.class);

                            Map<String, Communication_Event_Product_Mapping__mdt> productMetaMapping = Communication_Event_Product_Mapping__mdt.getAll();
                            Map<String, Communication_Event_Product_Mapping__mdt> productMapping = new Map<String, Communication_Event_Product_Mapping__mdt>();
                            for (Communication_Event_Product_Mapping__mdt meta : productMetaMapping.values()) {
                                productMapping.put(meta.Product_Name__c, meta);
                            }
                            String productName = '';
                            if (subProduct.size() > 0) {
                                if (subProduct[0].Product__r.Name == 'Affordable Home Loan' || subProduct[0].Product__r.Name == 'Affordable Non-Home Loan') {
                                    productName = app.Loan_Application__r.Product__c;
                                } else {
                                    productName = productMapping.containskey(subProduct[0].Name) ? productMapping.get(subProduct[0].Name).Product_Field__c : '';
                                }
                            }
                            if (urlRespWrapper.status == true) {
                                List<SMS_Template__mdt> accAggSms = [SELECT Id, String_1__c, String_2__c, String_3__c FROM SMS_Template__mdt WHERE MasterLabel = 'Account Aggregator'];
                                List<EmailTemplate> emailTemplate = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE Name = 'Account Aggregator'];
                                System.debug('accAggSms----------------' + urlRespWrapper.data.short_link_with_domain);

                                if (accAggSms.size() > 0) {
                                    String smsBody = '';
                                    if (accAggSms[0].String_1__c != null) smsBody += accAggSms[0].String_1__c;
                                    if (accAggSms[0].String_2__c != null) smsBody += accAggSms[0].String_2__c;
                                    if (accAggSms[0].String_3__c != null) smsBody += accAggSms[0].String_3__c;
                                    smsBody = smsBody.replace('{0}', app.Customer_Type__c == 'Individual' ? app.Salutation__c : 'M/s');
                                    smsBody = smsBody.replace('{1}', app.Applicant_Name__c);
                                    smsBody = smsBody.replace('{2}', productName);
                                    smsBody = smsBody.replace('{3}', urlRespWrapper.data.short_link_with_domain);
                                    smsBody = smsBody.replace('{4}', app.Customer_Profile__c == 'Salaried' ? '6' : '12');
                                    System.debug('smsBody----' + smsBody);
                                    SMSRequestService.sendSMS(new List<String>{mobileNumber}, smsBody, constants.get('Salesforce'));
                                }

                                if (String.isNotBlank(templateName)) {
                                    System.debug('inside whatsapp callout');
                                    List<String> params = new List<String>();
                                    params.add(app.Customer_Type__c == 'Individual' ? app.Salutation__c : 'M/s');
                                    params.add(app.Applicant_Name__c);
                                    params.add(productName);
                                    params.add(urlRespWrapper.data.short_link_with_domain);
                                    params.add(app.Customer_Profile__c == 'Salaried' ? '6' : '12');
                                    params.add('48');

                                    Map<String, Object> whatsappResult = SMSRequestService.sendWhatsappSMS('91' + mobileNumber, templateName, params);
                                    integrationDetailWhatsapp.Name = 'WhatsappSMS';
                                    integrationDetailWhatsapp.Object_Name__c = 'Opportunity';
                                    integrationDetailWhatsapp.Loan_Application__c = loanId;
                                    integrationDetailWhatsapp.EndPoint__c = 'callout:whatsappSMS';
                                    integrationDetailWhatsapp.Request_JSON__c = (String) whatsappResult.get('requestJSON');
                                    if (whatsappResult != null && whatsappResult.get('resp') != null) {
                                        integrationDetailWhatsapp.Response_JSON__c = (String) whatsappResult.get('resp');
                                    }
                                } else {
                                    System.debug('Template name is blank, skipping WhatsApp SMS call.');
                                }

                                if (emailTemplate.size() > 0) {
                                    Map<String, String> inputMap = new Map<String, String>();
                                    String email = app.Email__c;
                                    String emailBody;
                                    emailBody = emailTemplate[0].HtmlValue;
                                    emailBody = emailBody.replace('{#varSal}', app.Customer_Type__c == 'Individual' ? app.Salutation__c : 'M/s');
                                    emailBody = emailBody.replace('{#Link}', urlRespWrapper.data.short_link_with_domain);
                                    emailBody = emailBody.replace('{#varMonth}', app.Customer_Profile__c == 'Salaried' ? '6' : '12');
                                    emailBody = emailBody.replace('{#varName}', app.Applicant_Name__c);
                                    emailBody = emailBody.replace('{#Product}', productName);
                                    inputMap.put('subject', emailTemplate[0].Subject);
                                    inputMap.put('content', emailBody);
                                    inputMap.put('email', email);
                                    inputMap.put('applicantId', applicantId);
                                    inputMap.put('loanId', loanId);
                                    inputMap.put('processName', 'Email');
                                    EmailController.initiateAPIRequest(inputMap);
                                }

                                Document_Details__c dd = new Document_Details__c();
                                dd.Name = '12 months bank statement';
                                dd.Applicant__c = applicantId;
                                dd.Document_Master__c = dm[0].id;
                                dd.Loan_Application__c = loanId;
                                dd.Account_Aggregator_Status__c = responseJSON.data.consentHandle.data.status;
                                dd.Manual_AA__c = 'AA';
                                dd.Status__c = responseJSON.data.consentHandle.data.status;
                                dd.Process_Name__c = 'Income Bank Statement';
                                dd.Loan_Application__c = inputMap1.get('recordId');
                                dd.Transaction_ID__c = responseJSON.data.consentHandle.data.consent_handle;
                                insert dd;

                                returnResp = 'Application Applicant Account Aggregator Service completed successfully';

                                integrationDetail.Calling_Source__c = wrapper.type;
                                integrationDetail.Request_JSON__c = respWrapper.payload;
                                integrationDetail.Response_JSON__c = JSON.serialize(resp.getBody());
                                integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                                integrationDetail.Method_Type__c = intSetting.Request_Method__c;
                                integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                                integrationDetail.Name = 'Account Aggregator';
                                integrationDetail.Related_Record_Id__c = applicantId;
                                integrationDetail.Loan_Application__c = loanid;
                                integrationDetail.Short_link__c = urlRespWrapper.data.short_link_with_domain;
                                insert new List<Integration_Details__c>{integrationDetail, integrationDetailWhatsapp};
                            } else {
                                for (API_Exceptions__mdt execeptionMeta : allMetaData.values()) {
                                    if (execeptionMeta.Error_Code__c == urlRespWrapper.message) {
                                        returnResp = 'Error: ' + execeptionMeta.Error_Message__c;
                                    }
                                }
                            }
                        }
                    } else {
                        for (API_Exceptions__mdt execeptionMeta : allMetaData.values()) {
                            if (execeptionMeta.Error_Code__c == responseJSON.message) {
                                returnResp = 'Error:' + execeptionMeta.Error_Message__c;
                            }
                        }
                    }
                } else if (resp.getStatusCode() == 503) {
                    integrationDetail.Calling_Source__c = wrapper.type;
                    integrationDetail.Request_JSON__c = respWrapper.payload;
                    integrationDetail.Response_JSON__c = JSON.serialize(resp.getBody());
                    integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                    integrationDetail.Method_Type__c = intSetting.Request_Method__c;
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Name = 'Account Aggregator Error';
                    integrationDetail.Related_Record_Id__c = applicantId;
                    integrationDetail.Loan_Application__c = loanid;
                    insert integrationDetail;
                    returnResp = 'Error:' + 'Service Unavailable';
                } else {
                    integrationDetail.Calling_Source__c = wrapper.type;
                    integrationDetail.Request_JSON__c = respWrapper.payload;
                    integrationDetail.Response_JSON__c = JSON.serialize(resp.getBody());
                    integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                    integrationDetail.Method_Type__c = intSetting.Request_Method__c;
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.Name = 'Account Aggregator Error';
                    integrationDetail.Related_Record_Id__c = applicantId;
                    integrationDetail.Loan_Application__c = loanid;
                    insert integrationDetail;
                    returnResp = 'Error:' + 'Please try again later';
                }
            }

            return returnResp;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> getAADocuments(String recordId) {
        List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper> documentList = new List<COMM_DocumentDetailsScreenController.DocumentDetailsWrapper>();
        try {
            List<Integration_Details__c> integrationList = [SELECT Id, Name, Account_Aggregator_Consent_Handler__c FROM Integration_Details__c WHERE Loan_Application__c = :recordId AND Name = 'Account Aggregator'];
            List<Document_Details__c> documentDetailsList = [SELECT Id, Name, Content_Document_Id__c, CreatedBy.Name, Is_BSA_Initated__c, Is_Uploaded__c, Is_Required__c, Document_Master__r.Document_Category__c, Applicant__c, Location__Latitude__s, Location__Longitude__s, Applicant__r.Applicant_Name__c, Applicant__r.Applicant_Type__c, Manual_AA__c, Year_Month_From__c, Year_month_to__c, Account_Aggregator_Status__c, Uploaded_Date_Time__c, Loan_Application__r.Loan_Application_Number__c, Transaction_Id__c FROM Document_Details__c WHERE Loan_Application__c = :recordId AND Name = '12 months bank statement-' ORDER BY CreatedDate DESC];

            Map<String, String> integrationToHandler = new Map<String, String>();
            Map<String, Document_Details__c> handlerToDocument = new Map<String, Document_Details__c>();

            for (Integration_Details__c inte : integrationList) {
                integrationToHandler.put(inte.Id, inte.Account_Aggregator_Consent_Handler__c);
            }

            for (Document_Details__c doc : documentDetailsList) {
                if (!handlerToDocument.containsKey(doc.Transaction_Id__c)) {
                    handlerToDocument.put(doc.Transaction_Id__c, doc);
                }
            }

            for (String integrationId : integrationToHandler.keyset()) {
                String handler = integrationToHandler.get(integrationId);
                COMM_DocumentDetailsScreenController.DocumentDetailsWrapper wrapper = new COMM_DocumentDetailsScreenController.DocumentDetailsWrapper();
                Document_Details__c doc = handlerToDocument.containsKey(handler) ? handlerToDocument.get(handler) : null;
                if (doc != null) {
                }
            }
        } catch (Exception e) {
        }
        return documentList;
    }

    public class AccountAggregatorResponseServiceWrapper {
        @AuraEnabled public String status;
        @AuraEnabled public String traceId;
        @AuraEnabled public String message;
        @AuraEnabled public cls_data data;
    }

    public class cls_data {
        @AuraEnabled public cls_consentHandle consentHandle;
        @AuraEnabled public cls_urlDetail urlDetail;
        @AuraEnabled public String consent_handle;
        @AuraEnabled public String partyIdentifierValue;
        @AuraEnabled public String status;
        @AuraEnabled public String webRedirectionUrl;
    }

    public class cls_consentHandle {
        @AuraEnabled public String status;
        @AuraEnabled public String ver;
        @AuraEnabled public cls_data data;
    }

    public class cls_urlDetail {
        @AuraEnabled public String status;
        @AuraEnabled public String ver;
        @AuraEnabled public String message;
        @AuraEnabled public cls_data data;
    }
}