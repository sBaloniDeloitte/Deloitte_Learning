public with sharing class BusinessDateEmailController {
	// Fetch from custom label
	Public static String toEmail = System.Label.SendEmailList;
    public static void compareAndNotify(){
        List<integration_details__c> lstIntdet = [Select id,business_date__c from integration_details__c where name = 'fetch application date' order by createddate DESC limit 2];
        if(!lstIntdet.isEmpty()){
            if(lstIntdet[0].business_date__c != lstIntdet[1].business_date__c && toEmail!=null){
                sendEmail(toEmail,lstIntdet[0].business_date__c,lstIntdet[1].business_date__c);
            }
        }
            
    }

	 private static void sendEmail(String recipients, Date latest, Date previous) {
        if (String.isBlank(recipients)) return;

        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        msg.setToAddresses(recipients.split(','));
        msg.setSubject(
            'AHL SFDC PROD PLF Business Date Updated to ' + latest 
        );
        msg.setPlainTextBody(
			'Dear Recepient,\n'+
            'PLF business date field in AHL PROD got updated as below' +
            '\nLatest: ' + latest + 
            '\nPrevious: ' + previous
        );
      
    List<OrgWideEmailAddress> owdList = [
        SELECT Id,Address,IsVerified,Purpose FROM OrgWideEmailAddress where Purpose ='UserSelectionAndDefaultNoReply' and IsVerified = true LIMIT 1
    ];

    
    if (!owdList.isEmpty()) {
        msg.setOrgWideEmailAddressId(owdList[0].Id);
    }

   
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { msg });
    }
}