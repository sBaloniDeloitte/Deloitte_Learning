/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-07-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public  without sharing class AHL_CalculateGstHandler implements IntegrationInterface{
       public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) {
        String loanApplicationId = wrapper.loanApplicationId;
        String applicantId = wrapper.recordId;
        String productName = wrapper.productName;
        String feeType = wrapper.feeType;
        List<String> errorMessages = new List<String>();

        // if (String.isBlank(applicantId)) {
        //     errorMessages.add('Error: Applicant Id is missing');
        //     return errorMessages;
        // }

        List<Opportunity> op = [Select Id,Branch_Master__c,Branch_Master__r.Pincode__c,StageName from Opportunity where Id=:loanApplicationId Limit 1];
        if(!op.isEmpty()){
            if(op[0].Branch_Master__r.Pincode__c!=null){

            }
            else{
                 errorMessages.add('Error: Pincode not added in Branch record');
            }
        }

       List<Applicant_Address__c> add = [Select Pincode__r.City__r.State__c from Applicant_Address__c 
         where Applicant__r.Applicant_Type__c = 'Primary Applicant' and Address_Priority__c = '5' and Address_Type__c != 'BSA' AND Document_Details__c != null
         and Address_Line_1__c!=null AND Applicant__r.Loan_Application__c=:loanApplicationId and Applicant__r.Applicant_Type__c = 'Primary Applicant'];
        if(add.isEmpty() && op[0].StageName != 'Sales login'){
            errorMessages.add('Error: Highest priority address is missing');
        }
        // List<Product2> prodId = [Select id from Product2 where Name=:productName and Loan_Application__c=:loanApplicationId Limit 1];
        // System.debug('prodId====='+prodId);
        /*List<Charges_Insurance__c> ciS  = [SELECT Id, Name,Requested_Amount_INR__c,Loan_Application__c FROM Charges_Insurance__c WHERE Name =: feeType AND Loan_Application__c =:loanApplicationId AND Product__c =:productName];
        System.debug('ciS====='+ciS);
        if(!ciS.isEmpty()){

        }
        else{
             errorMessages.add('Error: PROCFEE/STFRCHG not added in Loan Application record');
        }*/
        return errorMessages;
    }

    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        try {
            String loanApplicationId = wrapper.loanApplicationId;
            String productName = wrapper.productName;
            String feeType = wrapper.feeType;
            Boolean isWaiverAmountCalc = wrapper.isWaiverAmountCalc;
            Decimal gstAmountForApi = wrapper.gstAmountForApi;
             List<Applicant_Address__c> lAP = new List<Applicant_Address__c>();
            List<Application_Applicant__c> appDet = [Select id,Customer_Profile__c from Application_Applicant__c where Loan_Application__c=:loanApplicationId and Applicant_Type__c='Primary Applicant' LIMIT 1];
            // if(appDet[0].Customer_Profile__c!='Salaried NRI'){
                lAP = [Select Id,Pincode__r.City__r.State__c,Pincode__c,Pincode__r.name from Applicant_Address__c where Applicant__r.Loan_Application__c=:loanApplicationId 
                                                AND Address_Priority__c = '5' AND Address_Type__c != 'BSA' AND Document_Details__c != null AND Address_Line_1__c!=null
                                                and Applicant__r.Applicant_Type__c = 'Primary Applicant'];
            // }
            // else{
            //     lAP = [Select Id,Pincode__r.City__r.State__c,Pincode__c,Pincode__r.name from Applicant_Address__c where Applicant__r.Loan_Application__c=:loanApplicationId 
            //                                     AND Address_Priority__c = '4' AND Address_Type__c != 'BSA' AND Document_Details__c != null AND Address_Line_1__c!=null
            //                                     and Applicant__r.Applicant_Type__c = 'Primary Applicant'];
            // }
            List<Charges_Insurance__c> ciS  = [SELECT Id, Name,Requested_Amount_INR__c,Loan_Application__c,GST_Exempt__c,Default_Amount_INR__c,Adjusted_Login_Fee__c,Balance_Fees__c,Waived_Charge_Amount__c FROM Charges_Insurance__c WHERE Name =: feeType AND Loan_Application__c =:loanApplicationId AND Product__c =:productName Limit 1];
            List<Opportunity> op = [Select Id,Branch_Master__c ,Branch_Master__r.Pincode__c,Branch_Master__r.Pincode__r.City__r.State__c,StageName,Lead__c,Pricing_Approval_Status__c from Opportunity where Id=:loanApplicationId Limit 1];
            List<Lead> ld = [SELECT Id, Pincode__c,Pincode__r.City__r.State__c FROM Lead WHERE Id = :op[0].Lead__c LIMIT 1];
            if(lAP.isEmpty() && op[0].StageName != 'Sales login'){
                throw new AuraHandledException('Highest Priority Address not found.');
            }
            List<Applicant_Address__c> appAddr = new List<Applicant_Address__c>();
            if(op[0].StageName == 'Sales Login'){
                appAddr = [SELECT Id, Pincode__r.City__r.State__c FROM Applicant_Address__c WHERE Applicant__r.Loan_Application__c = :loanApplicationId AND Applicant__r.Applicant_Type__c = 'Primary Applicant' LIMIT 1];
            }


            GstApiRequestWrapper gstrequestWrapper = new GstApiRequestWrapper();
            gstrequestWrapper.fees = new List<cls_fees>();
            cls_fees feeObj = new cls_fees();
            feeObj.sequence = 1; 
            feeObj.gstType = gstAmountForApi == null ? ciS[0].GST_Exempt__c : 'I';
            if(isWaiverAmountCalc == true){
                if(ciS[0].Requested_Amount_INR__c != null && ciS[0].Default_Amount_INR__c != null && ciS[0].Adjusted_Login_Fee__c != null) {
                    Decimal waiveAmount = (ciS[0].Default_Amount_INR__c - ciS[0].Adjusted_Login_Fee__c) - ciS[0].Requested_Amount_INR__c;
                    feeObj.amount = Utility.addTwoZeros(waiveAmount);
                }
                else{
                    feeObj.amount = 0;
                }
            }
            else{
                Decimal requestedAmount;
                if(gstAmountForApi!=null){
                    requestedAmount = gstAmountForApi;
                }
                else{
                    if(op[0].StageName == 'Sales login') {
                        requestedAmount = (ciS[0].Requested_Amount_INR__c != null) ? ciS[0].Requested_Amount_INR__c : 0;
                    }else{
                        requestedAmount = ((ciS[0].Balance_Fees__c != null && ciS[0].Balance_Fees__c != 0) ? ciS[0].Balance_Fees__c : 0) - ((op[0].Pricing_Approval_Status__c == 'Approved' && ciS[0].Waived_Charge_Amount__c != null && ciS[0].Waived_Charge_Amount__c != 0) ? ciS[0].Waived_Charge_Amount__c : 0);
                    }
                }
                feeObj.amount = (requestedAmount != null) ? Utility.addTwoZeros(requestedAmount) : 0;
            }
            gstrequestWrapper.gstType = gstAmountForApi == null ? ciS[0].GST_Exempt__c : 'I';
            gstrequestWrapper.fromState = op[0].Branch_Master__r.Pincode__r.City__r.State__c;
            gstrequestWrapper.toState = 'MH';//op[0].StageName != 'Sales login' ? lAP[0].Pincode__r.City__r.State__c : appAddr[0].Pincode__r.City__r.State__c;
           gstrequestWrapper.fees.add(feeObj);
            String requestJSON = JSON.serialize(gstrequestWrapper);
            System.debug('requestJSON : '+requestJSON);
            return requestJSON;

        } catch (Exception exp) {
           System.debug('Exception Message: ' + exp.getMessage());
            System.debug('Stack Trace: ' + exp.getStackTraceString());
            System.debug('Stack Trace: ' + exp.getLineNumber());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'CreateCibilPayload', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
    }

    public class GstApiRequestWrapper {
        public cls_fees[] fees;
        public String fromState;
        public String toState;
        public String gstType;
    }
    public class cls_fees {
		public Integer sequence;	//1
		public Decimal amount;	//500000
		public String gstType;	//E
	}

}