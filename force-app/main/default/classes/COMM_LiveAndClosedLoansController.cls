public class COMM_LiveAndClosedLoansController {
	@AuraEnabled
    public static List<LiveAndClosedLoanDataWrapper> getLiveLoanData(String recordId, String loanType) {
        List<LiveAndClosedLoanDataWrapper> dataWrap = new List<LiveAndClosedLoanDataWrapper>();
        
        List<Opportunity> loanList = [Select Id, Login_Completion_Stage__c from Opportunity where id =: recordId];
        if(loanType == 'closed') {
            loanType = 'Closed Loan';
        }else { 
            loanType = 'Live Loan';
        }
        System.debug('recordId12: '+recordId);
        List<Income_Expense_Obligation__c> liveLoanAndClosed = [Select Id,Balance_Tenure__c, Application_Applicant__r.name, Application_Applicant__r.Applicant_Type__c,Account_Type__c,
                                                                Loan_Amount__c, Current_Balance__c, Overdue__c, Ownership__c, Start_Date__c, Last_Payment_Date__c, 
                                                                DPD_in_Tradeline__c, DPD__c, Secured_Unsecured__c, Reported_Date__c,Credit_Remarks__c from Income_Expense_Obligation__c 
                                                                where Loan_Application__c =: recordId];

        system.debug('liveLoanAndClosed----'+liveLoanAndClosed);
        if(liveLoanAndClosed.size() > 0) {
            Integer count = 1;
            for(Income_Expense_Obligation__c iterRec : liveLoanAndClosed) {
                LiveAndClosedLoanDataWrapper iterData = new LiveAndClosedLoanDataWrapper();
                iterData.docCount = count;
                iterData.customerName = iterRec.Application_Applicant__r.name;
                iterData.customerType = iterRec.Application_Applicant__r.Applicant_Type__c;
                iterData.accountType = iterRec.Account_Type__c;
                iterData.loanAmount = String.valueOf(Integer.valueOf(iterRec.Loan_Amount__c).format());
                iterData.currentBalance = String.valueOf(Integer.valueOf(iterRec.Current_Balance__c).format());
                iterData.balanceTenure = iterRec.Balance_Tenure__c != null ? String.valueOf(Integer.valueOf(iterRec.Balance_Tenure__c).format()):'';
                iterData.overdue = String.valueOf(Integer.valueOf(iterRec.Overdue__c).format());
                iterData.ownership = iterRec.Ownership__c;
                iterData.startDate = String.valueOf(iterRec.Start_Date__c);
                iterData.lastPaymentDate = String.valueOf(iterRec.Last_Payment_Date__c);
                iterData.dpdTradeline = iterRec.DPD_in_Tradeline__c;
                iterData.dpd = iterRec.DPD__c;
                iterData.securedUnsecured = iterRec.Secured_Unsecured__c;
                iterData.reportedDate = String.valueOf(iterRec.Reported_Date__c);
                iterData.intDetRecordId = iterRec.id;
                if(loanType == 'closed') {
                    iterData.isLiveLoan = false;
                }
                if(loanType == 'live') {
                    iterData.isLiveLoan = true;
                }
                if(iterRec.DPD_in_Tradeline__c == 'Yes') {
                    iterData.isDPDRed = true;
                }else {
                    iterData.isDPDRed = false;
                }
                iterData.creditRemarks = String.isNotBlank(iterRec.Credit_Remarks__c)?iterRec.Credit_Remarks__c:'';
                dataWrap.add(iterData);
                count = count + 1;
            }
            
            
        }
        /*
        String tempDtaa = '[{"docCount":1,"customerName":"Akash Sharma","customerType":"Applicant","accountType":"Two-wheelerloan","loanAmount":"40000","currentBalance":"60000","overdue":"Yes","ownership":"individual","startDate":"11/11/2000","lastPaymentDate":"11/11/2000","dpdTradeline":"No","dpd":"01/05/2024 0000 00XX 0000 30/06/2022","securedUnsecured":"Secured","reportedDate":"11/11/2024","intDetRecordId":"7654fdsdfghjkhgf","isLiveLoan":false,"isDPDRed":false},{"docCount":2,"customerName":"Yash","customerType":"Co-applicant","accountType":"Two-wheelerloan","loanAmount":"40000","currentBalance":"60000","overdue":"Yes","ownership":"individual","startDate":"11/11/2000","lastPaymentDate":"11/11/2000","dpdTradeline":"No","dpd":"01/10/2022 0000 000XX 000X XXX0 20/11/2020","securedUnsecured":"Secured","reportedDate":"11/11/2024","intDetRecordId":"7654fdsdfghjkhgf","isLiveLoan":false,"isDPDRed":false}]';
        if(loanType == 'closed') {
            tempDtaa = '[{"docCount":1,"customerName":"Akash Sharma","customerType":"Applicant","accountType":"Two-wheelerloan","loanAmount":"40000","currentBalance":"60000","overdue":"Yes","ownership":"individual","startDate":"11/11/2000","lastPaymentDate":"11/11/2000","dpdTradeline":"No","dpd":"01/05/2024 0000 00XX 0000 30/06/2022","securedUnsecured":"Secured","reportedDate":"11/11/2024","intDetRecordId":"7654fdsdfghjkhgf","isLiveLoan":false,"isDPDRed":false},{"docCount":2,"customerName":"Yash","customerType":"Co-applicant","accountType":"Two-wheelerloan","loanAmount":"40000","currentBalance":"60000","overdue":"Yes","ownership":"individual","startDate":"11/11/2000","lastPaymentDate":"11/11/2000","dpdTradeline":"Yes","dpd":"01/10/2022 0000 000XX 000X 0111 20/11/2020","securedUnsecured":"Secured","reportedDate":"11/11/2024","intDetRecordId":"7654fdsdfghjkhgf","isLiveLoan":false,"isDPDRed":true}]';
        }
        
        dataWrap = (List<LiveAndClosedLoanDataWrapper>)JSON.deserialize(tempDtaa, List<LiveAndClosedLoanDataWrapper>.class);
        */
        return dataWrap;
    }
    @AuraEnabled
    public static Map<String,String> getApplicants(String recordId) {
        Map<String,String> applicantsMap = new Map<String,String>();
        List<Application_Applicant__c> lstApplicants = [SELECT id,Applicant_Type__c,name FROM Application_Applicant__c WHERE Loan_Application__c =:recordId];
        if(lstApplicants.size() > 0) {
            for(Application_Applicant__c iterApp : lstApplicants) {
                applicantsMap.put(iterApp.name,iterApp.name+' ('+iterApp.Applicant_Type__c+')');
            }
        }
        return applicantsMap;
    }
    @AuraEnabled
    public static String updateCreditRemarks(String recordId, String remarks) {
        String res = 'fail';
        List<Income_Expense_Obligation__c> liveLoanAndClosed = [Select Id, Credit_Remarks__c from Income_Expense_Obligation__c 
                                                                where Id =: recordId];
        if(liveLoanAndClosed.size() > 0) {
            liveLoanAndClosed[0].Credit_Remarks__c = remarks;
            update liveLoanAndClosed;
            res = 'success';
        }
        return res;
    }
    
    public class LiveAndClosedLoanDataWrapper{
        @AuraEnabled public Integer docCount;
        @AuraEnabled public String customerName;
        @AuraEnabled public String customerType;
        @AuraEnabled public String accountType;
        @AuraEnabled public String loanAmount;
        @AuraEnabled public String balanceTenure;
        @AuraEnabled public String currentBalance;
        @AuraEnabled public String overdue;
        @AuraEnabled public String ownership;
        @AuraEnabled public String startDate;
        @AuraEnabled public String lastPaymentDate;
        @AuraEnabled public String dpdTradeline;
        @AuraEnabled public String dpd;
        @AuraEnabled public String securedUnsecured;
        @AuraEnabled public String reportedDate;
        @AuraEnabled public String intDetRecordId;
        @AuraEnabled public Boolean isLiveLoan;
        @AuraEnabled public Boolean isDPDRed;
        @AuraEnabled public String creditRemarks;
    }
}