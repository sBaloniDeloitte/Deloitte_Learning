public with sharing class SalesOTPController {
    static string conLabels = Constants__mdt.getInstance('SalesOTPController').Value__c;
    
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
    
    
    @AuraEnabled
    public static void sendLoanOfferEmail(Id loanId,Id applicantId, Id leadId, Boolean offerRelated, String offerId) {
        /*String emailBody;
        String baseUrl = System.Url.getOrgDomainUrl().toExternalForm();
        baseUrl = baseUrl.replace('lightning.force.com', 'my.site.com');
        baseUrl = baseUrl.replace('my.salesforce.com', 'my.site.com') + '/consent/';
        //List<OrgWideEmailAddress> owdEmail = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :constants.get('OrgWideFromAddressEmail')];
        Map<String, String> inputMap = new Map<String, String>();
        String offerParam = offerRelated ? 'true' : 'false';
        String termsLink = Label.TermsLink;
        if (leadId != null) {
            String offerLink = baseUrl + '?applicantDetId=' + leadId + '&offerRelated=' + offerParam + '&offerId=' + offerId;
            // Query Lead Detail
            Lead lead = [SELECT Id, FirstName, LastName, Email, Salutation,Product__c FROM Lead WHERE Id = :leadId LIMIT 1];
            if (!String.isEmpty(lead.Email)) {
                
                if (!offerRelated) {
                EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE Name = 'Customer Consent' LIMIT 1];
                emailBody = emailTemplate.HtmlValue;
                emailBody = emailBody.replace('{#verificationLink}', offerLink);
                emailBody = emailBody.replace('{#termsLink}', termsLink);
                if((lead.Salutation == null || lead.Salutation == '') && (lead.FirstName == null || lead.FirstName == '')){
                 emailBody = emailBody.replace('{#applicant}', Lead.LastName);   
                }else if (lead.Salutation == null || lead.Salutation == ''){
                 emailBody = emailBody.replace('{#applicant}',lead.FirstName +' '+ Lead.LastName);     
                }else if(lead.FirstName == null || lead.FirstName == ''){
                   emailBody = emailBody.replace('{#applicant}',lead.Salutation +' '+ Lead.LastName);
                }else{
                     emailBody = emailBody.replace('{#applicant}',lead.Salutation +' '+ lead.FirstName +' '+ Lead.LastName);
                }
                emailBody = emailBody.replace('{#Product}', lead.Product__c);
                inputMap.put('content', emailBody);
                inputMap.put('subject', 'Verification for your online '+ lead.Product__c+' application with Godrej Finance');
                inputMap.put('email', lead.Email);
                inputMap.put('applicantId', leadId);
                inputMap.put('loanId', loanId);
                inputMap.put('processName', 'Email');
            } else {
                emailBody = 'Dear Receiver,\n\n' +
                    'You have an offer on your loan, please click on the link to navigate to the offer details and take necessary actions.\n\n' +
                    offerLink + '\n\n' +
                    'Thanks and Regards,\n' +
                    'Godrej Capital\n\n' +
                    'This is a system generated mail. Please do not reply.';
            }
         }
            //String fullName = lead.FirstName + ' ' + lead.LastName;
            
        } else {
            String offerLink = baseUrl + '?applicantDetId=' + applicantId + '&offerRelated=' + offerParam + '&offerId=' + offerId;
            // Query Applicant Detail
            Application_Applicant__c applicant = [SELECT Id, First_Name__c, Last_Name__c, Email__c, Applicant_Name__c,Loan_Application__r.Product__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId AND Id = :applicantId LIMIT 1];
            if (applicant != null && !String.isEmpty(applicant.Email__c)) {
                if (!offerRelated) {
                EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE Name = 'Customer Consent' LIMIT 1];
                emailBody = emailTemplate.HtmlValue;
                emailBody = emailBody.replace('{#verificationLink}', offerLink);
                emailBody = emailBody.replace('{#termsLink}', termsLink);
                emailBody = emailBody.replace('{#applicant}', applicant.Applicant_Name__c);
                emailBody = emailBody.replace('{#Product}', applicant.Loan_Application__r.Product__c);
                inputMap.put('content', emailBody);
                inputMap.put('subject', 'Verification for your online '+ applicant.Loan_Application__r.Product__c +' application with Godrej Finance');
                inputMap.put('email', applicant.Email__c);
                inputMap.put('applicantId', applicantId);
                inputMap.put('loanId', loanId);
                inputMap.put('processName', 'Email');
            } else {
                emailBody = 'Dear Receiver,\n\n' +
                    'You have an offer on your loan, please click on the link to navigate to the offer details and take necessary actions.\n\n' +
                    offerLink + '\n\n' +
                    'Thanks and Regards,\n' +
                    'Godrej Capital\n\n' +
                    'This is a system generated mail. Please do not reply.';
            }
                
        }
            //String fullName = applicant.First_Name__c + ' ' + applicant.Last_Name__c;
            
        }*/

        String emailBody;
        String baseUrl = System.Url.getOrgDomainUrl().toExternalForm();
        baseUrl = baseUrl.replace('lightning.force.com', 'my.site.com');
        baseUrl = baseUrl.replace('my.salesforce.com', 'my.site.com') + '/consent/';
        Map<String, String> inputMap = new Map<String, String>();
        String offerParam = offerRelated ? 'true' : 'false';
        String termsLink = 'https://godrejhf.com/ghf/information-and-policies.html#TnCDSfPG';
        String offerLink;
        String email;
        String product='';
        String applicantName;
        String loanStage;

        if (leadId != null) {
            offerLink = baseUrl + '?applicantDetId=' + leadId + '&offerRelated=' + offerParam + '&offerId=' + offerId;
            Lead lead = [SELECT Id, FirstName, LastName,MiddleName, Email, COMM_Purpose_of_Loan__c, Salutation, Product__c FROM Lead WHERE Id = :leadId LIMIT 1];
            email = lead.Email;
            // product = lead.Product__c;
            Map<String, Loan_Purpose_Communication_Mapping__mdt> productMetaMapping = Loan_Purpose_Communication_Mapping__mdt.getAll();
            Map<String, Loan_Purpose_Communication_Mapping__mdt> productMapping= new Map<String, Loan_Purpose_Communication_Mapping__mdt>();
            for (Loan_Purpose_Communication_Mapping__mdt meta : productMetaMapping.values()){
                productMapping.put(meta.Loan_Purpose__c, meta);
            }
            product = productMapping.containsKey(lead.COMM_Purpose_of_Loan__c) ? productMapping.get(lead.COMM_Purpose_of_Loan__c).Product_Name__c : '';
            applicantName = formatApplicantName(lead.FirstName,lead.MiddleName, lead.LastName, lead.Salutation);
        } else {
        offerLink = baseUrl + '?applicantDetId=' + applicantId + '&offerRelated=' + offerParam + '&offerId=' + offerId;
        Application_Applicant__c applicant = [SELECT Id, First_Name__c, Last_Name__c, Email__c, Applicant_Name__c, Loan_Application__r.Product__c, Loan_Application__r.StageName FROM Application_Applicant__c WHERE Loan_Application__c = :loanId AND Id = :applicantId LIMIT 1];
        List<Product2> subProduct = [SELECT Id,Name, Product__r.Name from Product2 WHERE RecordType.Name = :constants.get('Sub_Product') AND Product__r.Product_Type__c = 'Parent' AND Loan_Application__c = :loanId LIMIT 1];
        Map<String, Communication_Event_Product_Mapping__mdt> productMetaMapping = Communication_Event_Product_Mapping__mdt.getAll();
        Map<String, Communication_Event_Product_Mapping__mdt> productMapping= new Map<String, Communication_Event_Product_Mapping__mdt>();
        for (Communication_Event_Product_Mapping__mdt meta : productMetaMapping.values()){
            productMapping.put(meta.Product_Name__c, meta);
        }
        
        if(subProduct.size()>0){
            if(subProduct[0].Product__r.Name == 'Affordable Home Loan' || subProduct[0].Product__r.Name == 'Affordable Non-Home Loan') {
                product = applicant.Loan_Application__r.Product__c;
            }else{
                product= productMapping.containskey(subProduct[0].Name) ? productMapping.get(subProduct[0].Name).	Product_Field__c : applicant.Loan_Application__r.Product__c;
            }
        }
        loanStage = applicant.Loan_Application__r.StageName;
        email = applicant.Email__c;
        // product = applicant.Loan_Application__r.Product__c;
        applicantName = applicant.Applicant_Name__c;
        }

        if (!String.isEmpty(email)) {
            if (!offerRelated) {
            EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE Name = 'Customer Consent' LIMIT 1];
            emailBody = emailTemplate.HtmlValue;
            emailBody = emailBody.replace('{#verificationLink}', offerLink);
            emailBody = emailBody.replace('{#termsLink}', termsLink);
            emailBody = emailBody.replace('{#applicant}', applicantName);
            emailBody = emailBody.replace('{#Product}', product);
            inputMap.put('subject', 'Verification for your online ' + product + ' application with Godrej Housing Finance');
            } else {
            EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE Name = 'Customer Offer' LIMIT 1];
            emailBody = emailTemplate.HtmlValue;
            emailBody = emailBody.replace('{#verificationLink}', offerLink);
            inputMap.put('subject', 'Loan offer for ' + product + ' application with Godrej Housing Finance');
            /*emailBody = 'Dear Receiver,\n\n' +
                        'You have an offer on your loan, please click on the link to navigate to the offer details and take necessary actions.\n\n' +
                        offerLink + '\n\n' +
                        'Thanks and Regards,\n' +
                        'Godrej Capital\n\n' +
                        'This is a system generated mail. Please do not reply.';*/
            }
            inputMap.put('content', emailBody);
            inputMap.put('email', email);
            inputMap.put('applicantId', leadId != null ? leadId : applicantId);
            inputMap.put('loanId', loanId);
            inputMap.put('processName', 'Email');
        }
        
        EmailController.initiateAPIRequest(inputMap);
        if(leadId == null){
            TAT__c tatRecord = new TAT__c();
            tatRecord.Stage__c = loanStage;//metadataList[0].Stage__c; >>chnaged it for better tracking from application
            tatRecord.Activity__c = 'Consent';
            tatRecord.Sub_Activity__c = 'Consent through OTP';
            tatRecord.User_Name__c = UserInfo.getUserId();
            tatRecord.Timestamp__c = System.now();
            tatRecord.End_Timestamp__c = System.now();
            tatRecord.Loan_Application__c = loanId;
            insert tatRecord;
        }
        //System.debug('emailBody --> ' + emailBody);
    }


private static String formatApplicantName(String firstName, String middleName, String lastName, String salutation) {
       if ((salutation == null || salutation == '') &&
    (firstName == null || firstName == '') &&
    (middleName == null || middleName == '')) {
    return lastName;
} else if ((salutation == null || salutation == '') &&
           (firstName == null || firstName == '')) {
    return middleName + ' ' + lastName;
} else if (salutation == null || salutation == '') {
    return firstName + ' ' + (middleName != null && middleName != '' ? middleName + ' ' : '') + lastName;
} else if (firstName == null || firstName == '') {
    return salutation + ' ' + (middleName != null && middleName != '' ? middleName + ' ' : '') + lastName;
} else {
    return salutation + ' ' + firstName + ' ' + (middleName != null && middleName != '' ? middleName + ' ' : '') + lastName;
}
 }
    
    
    // @AuraEnabled
    // public static void sendLoanOfferEmail(Id loanId, Id applicantId, Boolean offerRelated,String offerId) {
    //     Application_Applicant__c applicant = [SELECT Id, First_Name__c, Last_Name__c, Email__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId AND Id = :applicantId LIMIT 1];
    //     if (applicant == null || String.isEmpty(applicant.Email__c)) {
    //         System.debug('No valid email found for the applicant.');
    //         return;
    //     }
    //     String fullName = applicant.First_Name__c + ' ' + applicant.Last_Name__c;
    //     String baseUrl = System.Url.getOrgDomainUrl().toExternalForm();
    //     baseUrl = baseUrl.replace('lightning.force.com', 'my.site.com');
    //     baseUrl = baseUrl.replace('my.salesforce.com', 'my.site.com') + '/consent/';
    //     List<OrgWideEmailAddress> owdEmail =[SELECT Id FROM OrgWideEmailAddress WHERE Address=:constants.get('OrgWideFromAddressEmail')];
    //     System.debug('baseUrl --> '+baseUrl);
    //     String applicantDetId = applicant.Id;
    //     // String offerLink = baseUrl + '?applicantDetId=' + applicantDetId&offerRelated;
    //     String offerParam = offerRelated ? 'true' : 'false';
    //     String offerLink = baseUrl + '?applicantDetId=' + applicantDetId + '&offerRelated=' + offerParam + '&offerId=' + offerId ;
    //     System.debug('offerLink --> '+offerLink);
    //     String emailBody;
    //     if(offerRelated== false) {
    //         emailBody = 'Dear ' + fullName + ',\n\n'
    //                     + 'To continue on the process, please click on the link to navigate to the offer details and take necessary actions.\n\n'
    //                     + offerLink;
    //     }
    //     if(offerRelated ==true ){
    //          emailBody = 'Dear Receiver,\n\n'
    //                      + 'You have an offer on your loan, please click on the link to navigate to the offer details and take necessary actions.\n\n'
    //                      + offerLink+ '\n\n' +
    //         'Thanks and Regards,'+ '\n' +
    //                     'Godrej Capital' + '\n\n' +
    //                     'This is a system generated mail. Please do not reply.';
    //     }
    //     System.debug('emailBody --> '+emailBody);
    //     Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    //     if(owdEmail.size()>0){
    //         mail.setOrgWideEmailAddressId(owdEmail[0].Id); 
    //     }
    
    //     mail.setToAddresses(new List<String>{ applicant.Email__c });
    //     mail.setSubject('Loan Offer Notification');
    //     mail.setPlainTextBody(emailBody);
    //     Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    // }
}