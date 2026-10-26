public with sharing class COMM_SalesLoginIncomeController {
    static string conLabels = 'Banking';
     public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
    @AuraEnabled
    public static List<Application_Applicant__c> getApplicantDetails(String recordId){
        try {
            List<Application_Applicant__c> appDets =[Select id, Applicant_Name__c,Applicant_Type__c,Mobile_Number__c from Application_Applicant__c where Loan_Application__c=:recordId];
            return appDets;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string createAccountAggregatorDocumentChecklist(Map<String,String> inputMap){
        try {
            String applicantId = inputMap.get('applicantId');
            String loanId = inputMap.get('loanId');
            String passWord = inputMap.get('password');
            String toDate = inputMap.get('toDate');
            String fromDate = inputMap.get('fromDate');
            List<Document_Master__c> dm =[Select id, Name,Document_Category__c from Document_Master__c where Document_Name__c='12 months bank statement'];

            Document_Details__c dd = new Document_Details__c();
                dd.Name='12 months bank statement';
                dd.Applicant__c=applicantId;
                dd.Document_Master__c=dm[0].id;
                dd.Loan_Application__c =loanId;
                dd.Status__c = 'Pending';
                dd.Manual_AA__c='AA';
                dd.Password__c  = passWord;
                dd.Process_Name__c='Income Bank Statement';
                dd.Loan_Application__c=inputMap.get('recordId');
                // dd.Year_Month_To__c =Date.valueof(toDate)!=null?;
                // dd.Year_Month_From__c =Date.valueof(fromDate);
                insert dd;

                return dd.id;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ProductWrapper{
        @AuraEnabled public String programId;
        @AuraEnabled public boolean isBakingProgram=false;
        @AuraEnabled public boolean isITR=false;
        @AuraEnabled public boolean isGST=false;
    }
  
}