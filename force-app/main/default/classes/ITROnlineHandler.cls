public class ITROnlineHandler  implements IntegrationInterface {
    public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String panNumber = wrapper.panNumber;
        Date dob = wrapper.customerDOB;
        if (String.isEmpty(panNumber)) {
            errorMessages.add('Error: Missing PAN number.');
        }  
        if (dob == null) {
            errorMessages.add('Error: Missing DOB.');
        }  
        return errorMessages;
    }
    
    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();
        String body = '';
        try {
            system.debug('are we inside construct??');
            String panNumber = wrapper.panNumber;
            Date dob = wrapper.customerDOB;
            String day = (dob.day() < 10) ? '0' + String.valueOf(dob.day()) : String.valueOf(dob.day());
            String month = (dob.month() < 10) ? '0' + String.valueOf(dob.month()) : String.valueOf(dob.month());
            String year = String.valueOf(dob.year());
            String applicantId = wrapper.applicantId;
            ITROnlineHandler reqWrap = new ITROnlineHandler();
            reqWrap.transactionCompleteCallbackUrl = (String)URL.getOrgDomainURL().toExternalForm()+'/services/apexrest/api/itr-callback';
            reqWrap.scanned = 'false';
            reqWrap.clientTxnId = applicantId;
            reqWrap.dob = year+'-'+month+'-'+day;
            reqWrap.type = 'IncomeTaxOnline';
            reqWrap.pan = panNumber;
            reqWrap.redirectUrl = (String)'https://www.godrejcapital.com';
            reqWrap.pan = panNumber;
            cls_optionalConfigParams innerWrap = new cls_optionalConfigParams();
            innerWrap.fetchForm26AS = true;
            innerWrap.fetchITRV = true;
            innerWrap.fetchITR = true;
            innerWrap.noOfYearsForForm26AS = 1;
            innerWrap.noOfYearsForITR = 1;
            reqWrap.optionalConfigParams = innerWrap;
            System.debug('Request ----'+JSON.serialize(reqWrap));
            return JSON.serialize(reqWrap);
            
        } catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'ITROnlineHandler', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
        
    }
    
    public String transactionCompleteCallbackUrl;	//http://172.24.4.232:8082/api/itrcallback
	public String scanned;	//false
	public cls_optionalConfigParams optionalConfigParams;
	public String clientTxnId;	//12345
	public String dob;	//2001-09-13
	public String pan;	//EJMPR7654F
	public String type;	//IncomeTaxOnline
	public String redirectUrl;	//https://www.godrejcapital.com
	public class cls_optionalConfigParams {
		public boolean fetchITRV;
		public boolean fetchForm26AS;
		public Integer noOfYearsForForm26AS;	//1
		public Integer noOfYearsForITR;	//1
		public boolean fetchITR;
	}
    
}