public with sharing class PANStatusCheckHandler implements IntegrationInterface {
    static string conLabels = 'PAN_Validation_API';
                         
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String loanApplicationId = wrapper.loanApplicationId;
        String panNumber = wrapper.panNumber;
        String applicantId = wrapper.recordId;
		Date dob = wrapper.customerDOB;
        if(String.isBlank(applicantId) || String.isBlank(loanApplicationId)){
            errorMessages.add('Error: Applicant Id is missing');
        }
        if(String.isBlank(panNumber)){
            errorMessages.add('Error: Applicant\'s Pan Number is missing');
        }
       
        if(dob==null){
            errorMessages.add('Error: DOB  is missing for '+ dob );
        }
        return errorMessages;
    }
    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();
        try {
			String applicantId = wrapper.recordId;
			List<Application_Applicant__c> applicantList = [SELECT Id, Customer_Type__c, Applicant_Name__c,DOB__c,Company__c, DOI__c,Name_of_Organization__c from Application_Applicant__c where id =: applicantId];
            String loanApplicationId = wrapper.loanApplicationId;
            String panNumber = wrapper.panNumber;
            Date dob = wrapper.customerDOB;
//Protean -s
			/*List<PanRequestWrapper> csWrapperList = new List<PanRequestWrapper>();
            PanRequestWrapper csWrapper = new PanRequestWrapper();
                csWrapper.pan = panNumber;
                if (applicantList[0].Customer_Type__c == 'Individual') {
                    csWrapper.name = applicantList[0].Applicant_Name__c;
                    csWrapper.dob = formatDate(applicantList[0].DOB__c);
                } else {
                    csWrapper.name = applicantList[0].Name_of_Organization__c;
                    csWrapper.dob = formatDate(applicantList[0].DOI__c);
                }
                
                // Helper method to format Date as dd/MM/yyyy
               
                
              
                csWrapper.consent='Y';
                csWrapper.clientData = new cls_clientData();
                csWrapper.clientData.caseId=applicantList[0].id;

                Integration_Details__c integrationDetails = new Integration_Details__c();
                String requestJSON = JSON.serialize(csWrapper);
                return requestJSON;*/ 
//Protean-E
//Protean -s
List<InputData> inputDataList = new List<InputData>();
        InputData input = new InputData();
        input.pan = wrapper.panNumber;
            if (applicantList[0].Customer_Type__c == 'Individual') {
                input.name =applicantList[0].Applicant_Name__c;
                input.fathername='';
                input.dob = formatDate(applicantList[0].DOB__c);
            }else{
                input.name =applicantList[0].Name_of_Organization__c;
                input.fathername='';
                input.dob = formatDate(applicantList[0].DOI__c);
            }
           inputDataList.add(input);
        PANPayloadWrapper payload = new PANPayloadWrapper();
        payload.inputData = inputDataList;
        String ts=Datetime.now().formatGmt('yyyyMMdd\'T\'HHmmssSSS\'Z\'');
        payload.transactionId =applicantList[0].id +ts;
         Integration_Details__c integrationDetails = new Integration_Details__c();
                String requestJSON = JSON.serialize(payload);
                return requestJSON; // Set as per your logic
// Protean -E
        }
        catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'Createhunterpayload', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }

    }
/*    public class PanRequestWrapper{
    public String pan;	//BXXXXXXXXR
	public String name;	//Omkar Milind Shirhatti
	public String dob;	//17/08/1987
	public String consent;	//Y
	public cls_clientData clientData;
    }
    public class cls_clientData {
		public String caseId;	//123456
	}
      // Helper method to format Date as dd/MM/yyyy
      public static String formatDate(Date inputDate) {
        if (inputDate == null) return '';
        return String.valueOf(inputDate.day()) + '/' +
               String.valueOf(inputDate.month()) + '/' +
               String.valueOf(inputDate.year());
    }*/
//Protean- S
public class PANPayloadWrapper {
    public List<InputData> inputData;
    public String transactionId;
}
public class InputData {
    public String pan;
    public String name;
    public String fathername;
    public String dob;
} 
      public static String formatDate(Date inputDate) {
        if (inputDate == null) return '';
     String dayStr = inputDate.day() < 10 ? '0' + String.valueOf(inputDate.day()) : String.valueOf(inputDate.day());
     String monthStr = inputDate.month() < 10 ? '0' + String.valueOf(inputDate.month()) : String.valueOf(inputDate.month());
     String yearStr = String.valueOf(inputDate.year());
       return dayStr + '/' + monthStr + '/' + yearStr;
    }
//Protean- E
}