public with sharing class Sales_OTPController {
    static string conLabels = 'OrgWideFromAddressEmail';
                         
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }


        @AuraEnabled
    public static void sendLoanOfferEmail(Id loanId, Id applicantId, Boolean offerRelated, String offerId) {
        Application_Applicant__c applicant = [
            SELECT Id, First_Name__c, Last_Name__c, Email__c,Applicant_Name__c 
            FROM Application_Applicant__c 
            WHERE Loan_Application__c = :loanId AND Id = :applicantId 
            LIMIT 1
        ];
        
        if (applicant == null || String.isEmpty(applicant.Email__c)) {
            System.debug('No valid email found for the applicant.');
            return;
        }
        
        String fullName = applicant.First_Name__c + ' ' + applicant.Last_Name__c;
        String baseUrl = System.Url.getOrgDomainUrl().toExternalForm();
        baseUrl = baseUrl.replace('lightning.force.com', 'my.site.com');
        baseUrl = baseUrl.replace('my.salesforce.com', 'my.site.com') + '/consent/';
        
        List<OrgWideEmailAddress> owdEmail = [
            SELECT Id FROM OrgWideEmailAddress WHERE Address = :constants.get('OrgWideFromAddressEmail')
        ];
        Map<String,String> inputMap = new Map<String,String>();
        String applicantDetId = applicant.Id;
        String offerParam = offerRelated ? 'true' : 'false';
        String offerLink = baseUrl + '?applicantDetId=' + applicantDetId + '&offerRelated=' + offerParam + '&offerId=' + offerId;
        String emailBody ;
        System.debug('offerLink --> ' + offerLink);
        EmailTemplate emailTemplate = new EmailTemplate();
        if(offerRelated== false) {
        // Fetch the email template
            emailTemplate =[
                SELECT Id, Subject, HtmlValue 
                FROM EmailTemplate 
                WHERE Name = 'Customer Consent' 
                LIMIT 1
            ];
            emailBody = emailTemplate.HtmlValue;
            emailBody = emailBody.replace('{#verificationLink}', offerLink);
            emailBody = emailBody.replace('{#termsLink}', offerLink); 
            emailBody= emailBody.replace('{#applicant}', applicant.Applicant_Name__c); 
            inputMap.put('content',emailBody) ;
            inputMap.put('subject','Verification for your online Business Loan application with Godrej Finance') ;
            inputMap.put('email',applicant.Email__c) ;
            inputMap.put('applicantId',applicantId) ;
            inputMap.put('loanId',loanId) ;
            inputMap.put('processName','Email');
        }
        if(offerRelated ==true ){
                     emailBody = 'Dear Receiver,\n\n'
                                 + 'You have an offer on your loan, please click on the link to navigate to the offer details and take necessary actions.\n\n'
                                 + offerLink+ '\n\n' +
                    'Thanks and Regards,'+ '\n' +
                                'Godrej Capital' + '\n\n' +
                                'This is a system generated mail. Please do not reply.';
            }
                EmailController.initiateAPIRequest(inputMap);
                //Utility.insertTATRecords('C-011', loanId, '');
        
        System.debug('emailBody --> ' + emailBody);
        
        // Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        // if (!owdEmail.isEmpty()) {
        //     mail.setOrgWideEmailAddressId(owdEmail[0].Id);
        // }
        
        // mail.setToAddresses(new List<String>{ applicant.Email__c });
        // mail.setSubject(emailTemplate.Subject);
        // mail.setHtmlBody(emailBody);
        
        // Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
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