public without sharing class COMM_SalesLoginFeeController {

    public class LoginFeeWrapper {
        @AuraEnabled public String recordId;
		@AuraEnabled public String loanId;
        @AuraEnabled public String loginFeeCollected;
        @AuraEnabled public String loginFeeToBeCollected;
        @AuraEnabled public String paymentStatus;
        @AuraEnabled public String receiptNo;
        @AuraEnabled public String  transactionRef;
        @AuraEnabled public String  remarks;
        @AuraEnabled public String  subReceiptMode;
        @AuraEnabled public Boolean  showRetry;
    }

    @AuraEnabled
    public static LoginFeeWrapper getLoginFeeRecord(String loanId) {
        LoginFeeWrapper wrapper = new LoginFeeWrapper();

        try {
            System.debug('>>> LoanId received:>> ' + loanId);
            Id chargesInsuranceMasterRecordId = Schema.SObjectType.Charges_Insurance_Master__c
                .getRecordTypeInfosByName()
                .get('Charges')
                .getRecordTypeId();

            Charges_Insurance_Master__c chargeInsuranceMaster = [
                SELECT Id 
                FROM Charges_Insurance_Master__c 
                WHERE Charges_Fee_Type__c = 'Login Fee' 
                LIMIT 1
            ];
            
            // List<Charges_Insurance__c> chargeInsuranceList = [
            //     SELECT Id, Name,Remarks__c, Default_Amount_INR__c,Requested_Amount_INR__c,
            //            Payment_Status__c, Receipt_No__c,Transaction_Reference__c,Sub_Receipt_Mode__c
            //     FROM Charges_Insurance__c 
            //     WHERE Name = 'Login Fee'
            //     AND Loan_Application__c = :loanId 
            //     LIMIT 1
            // ];

            List<Charges_Insurance__c> chargeInsuranceList = [
                SELECT Id, Name,Remarks__c, Default_Amount_INR__c,Requested_Amount_INR__c,
                       Payment_Status__c, Receipt_No__c,Transaction_Reference__c,Sub_Receipt_Mode__c
                FROM Charges_Insurance__c 
                WHERE Name = 'Login Fee'
                AND Loan_Application__c = '006dN00000F1KIbQAN' 
                LIMIT 1
            ];
            System.debug('>>> chargeInsuranceList size: ' + chargeInsuranceList.size());
            // List<Charges_Insurance__c> chargeInsuranceListProcFee = [
            //     SELECT Id, Name
            //     FROM Charges_Insurance__c 
            //     WHERE Name = 'PROCFEE' AND Charges_Fee_type__c = 'PROCFEE'
            //     AND Loan_Application__c = :loanId 
            //     LIMIT 1
            // ];

            List<Charges_Insurance__c> chargeInsuranceListProcFee = [
                SELECT Id, Name
                FROM Charges_Insurance__c 
                WHERE Name = 'PROCFEE' AND Charges_Fee_type__c = 'PROCFEE'
                AND Loan_Application__c = '006dN00000F1KIbQAN' 
                LIMIT 1
            ];

           System.debug('>>> chargeInsuranceListProcFee size: ' + chargeInsuranceListProcFee.size());
            if (!chargeInsuranceList.isEmpty()) {
                Charges_Insurance__c record = chargeInsuranceList[0];
                wrapper.recordId = record.Id;
                wrapper.loginFeeCollected = String.valueOf(record.Requested_Amount_INR__c);
                wrapper.paymentStatus = record.Payment_Status__c;
                wrapper.receiptNo = record.Receipt_No__c;
                wrapper.transactionRef = record.Transaction_Reference__c;
				wrapper.remarks = record.Remarks__c;
                wrapper.subReceiptMode = record.Sub_Receipt_Mode__c;
                wrapper.showRetry = chargeInsuranceListProcFee.isEmpty() ? true : false;
            }

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching login fee record: ' + e.getMessage());
        }

        return wrapper;
    }

    @AuraEnabled
    public static Boolean checkIFLoginFeeCreated(String loanId){
        Boolean isRecPresent = false;
        List<Charges_Insurance__c> chargeList = [Select id from Charges_Insurance__c where Loan_Application__c =: loanId and Charges_Fee_Type__c = 'Login Fee'];
        if(!chargeList.isEmpty()){
            isRecPresent = true;
        }
        return isRecPresent;
    }
    @AuraEnabled
    public static void upsertLoginFeeRecord(String input) {
	    LoginFeeWrapper lstRecords = (LoginFeeWrapper)JSON.deserialize(input, LoginFeeWrapper.Class);
		system.debug('lstRecords--55--'+lstRecords);
		system.debug('lstRecords.loanId--'+ lstRecords.loanId);
        if (lstRecords == null || String.isBlank(lstRecords.loanId)) {
            throw new AuraHandledException('Loan ID is required.');
        }

        Charges_Insurance__c charge = new Charges_Insurance__c();

        if (String.isNotBlank(lstRecords.recordId)) {
            // Existing record - update
            charge = [
                SELECT Id FROM Charges_Insurance__c WHERE Id = :lstRecords.recordId LIMIT 1
            ];
        } else {
            // New record - create
            charge = new Charges_Insurance__c();
            
            Id chargesInsuranceMasterRecordId = Schema.SObjectType.Charges_Insurance_Master__c
                .getRecordTypeInfosByName()
                .get('Charges')
                .getRecordTypeId();

            Charges_Insurance_Master__c master = [
                SELECT Id FROM Charges_Insurance_Master__c 
                WHERE Charges_Fee_Type__c = 'Login Fee' AND recordTypeId =:chargesInsuranceMasterRecordId LIMIT 1
            ];
            charge.Name = 'Login Fee';
            charge.Charges_Insurance_Master__c = master.Id;
            charge.Loan_Application__c = lstRecords.loanId;
            charge.Charges_Fee_Type__c = 'Login Fee';
            
        }

        charge.Requested_Amount_INR__c = Decimal.valueOf(lstRecords.loginFeeCollected);
        charge.Payment_Status__c = lstRecords.paymentStatus;
        charge.Receipt_No__c = lstRecords.receiptNo;
        charge.Transaction_Reference__c = lstRecords.transactionRef;
        charge.Default_Amount_INR__c =  Decimal.valueOf(lstRecords.loginFeeToBeCollected);
        charge.Category__c = 'LOS';
        charge.Sub_Receipt_Mode__c = lstRecords.subReceiptMode;
        if(lstRecords.remarks != null){
        charge.Remarks__c = lstRecords.remarks;
        }
        upsert charge;
    }

    @AuraEnabled
    public static void updateChargesByAllocatedAmount(Id loanApplicationId, String loginFees) {
        try {
            List<Charges_Insurance__c> chargeList = [
                SELECT Id, Name, Allocated_Amount__c, Balance_Charge_Amount__c, 
                    Requested_Amount_INR__c, Final_Amount_INR__c, Login_Fees__c, Balance_Login_Fees__c,
                    Adjusted_Login_Fee__c
                FROM Charges_Insurance__c
                WHERE Loan_Application__c = :loanApplicationId
                AND Name NOT IN ('Total Charges', 'Login Fee')
                AND RecordType.Name = 'Charges' AND Product__r.Product_Type__c = 'Parent'
                ORDER BY Allocated_Amount__c DESC
            ];

            Decimal remainingLoginFee = 0;
                if (loginFees != null) {
                    remainingLoginFee = Decimal.valueOf(loginFees);
                }

            for (Charges_Insurance__c charge : chargeList) {
                Decimal allocated = charge.Final_Amount_INR__c != null ? charge.Final_Amount_INR__c : 0;
                if(remainingLoginFee > 0){
                if (remainingLoginFee == allocated) {
                    // Fully pay this charge
                    charge.Balance_Charge_Amount__c = 0;
                    charge.Adjusted_Login_Fee__c = remainingLoginFee;
                    charge.Balance_Login_Fees__c = 0;
                    remainingLoginFee -= allocated;
                }else if(remainingLoginFee > allocated){
                     // Partially pay this charge
                    charge.Balance_Charge_Amount__c = 0;
                    charge.Adjusted_Login_Fee__c = allocated;
                    charge.Balance_Login_Fees__c = 0;
                    remainingLoginFee -= allocated;
                }else {
                    // Partially pay this charge
                    charge.Balance_Charge_Amount__c = allocated - remainingLoginFee;
                    charge.Adjusted_Login_Fee__c = remainingLoginFee;
                    charge.Balance_Login_Fees__c =  allocated - remainingLoginFee;
                    remainingLoginFee -= allocated;
                }

                charge.Login_Fees__c = Decimal.valueOf(loginFees);
            }else if(remainingLoginFee == 0){
                 charge.Adjusted_Login_Fee__c = null;
                 charge.Balance_Charge_Amount__c = allocated;
                 charge.Balance_Login_Fees__c = null;
            }
            }

            if (!chargeList.isEmpty()) {
                update chargeList;
            }

        } catch (Exception e) {
            System.debug('Error updating charges: ' + e.getMessage());
            throw new AuraHandledException('Unable to update Charges.');
        }
    }

    @AuraEnabled
    public static List<Charges_Insurance__c> getTotalCharges(Id recordId) {
        try {
            //List<Charges_Insurance__c> chargeList = [SELECT Total_Charges__c,GstCalculated__c FROM Charges_Insurance__c WHERE Loan_Application__c = :recordId AND Name = 'Total Charges' AND RecordType.Name = 'Charges' AND Product__r.Product_Type__c = 'Parent' LIMIT 1];
            List<Charges_Insurance__c> chargeList = [SELECT Total_Charges__c,GstCalculated__c FROM Charges_Insurance__c WHERE Name = 'Total Charges' AND RecordType.Name = 'Charges' AND Product__r.Product_Type__c = 'Parent' LIMIT 1];

             return chargeList;
        } catch (Exception e) {
            System.debug('Error fetching Total Charges: ' + e.getMessage());
            return new List<Charges_Insurance__c>();
        }
    }

    @AuraEnabled
    public static void updateTotalCharges(Id recordId) {
        try {
            // 1. Get all "Total Charges" records for this Loan Application
            List<Charges_Insurance__c> totalChargeRecords = [
                SELECT Id, Product__c, Total_Charges__c, GstCalculated__c FROM Charges_Insurance__c WHERE Loan_Application__c = :recordId AND Name = 'Total Charges' AND RecordType.Name = 'Charges' ];

            if (totalChargeRecords.isEmpty()) {
                System.debug('No Total Charges records found for Loan: ' + recordId);
                return;
            }
             List<Login_Fees__mdt> gstMappings = [
            SELECT MasterLabel,
            Is_GST_Applicable__c
            FROM Login_Fees__mdt
            WHERE Is_GST_Applicable__c = true
        ];

        // 3) Build the allowed charge-name set (exact name match)
        Set<String> allowedNames = new Set<String>();
        for (Login_Fees__mdt m : gstMappings) {
         allowedNames.add(m.MasterLabel);
        }
            // 2. Get all other charge records (excluding Total Charges and Login Fee)
            List<Charges_Insurance__c> otherCharges = [
                SELECT Id, Product__c, Final_Amount_INR__c FROM Charges_Insurance__c WHERE Loan_Application__c = :recordId AND Name IN ('PROCFEE','STFRCHG') AND RecordType.Name = 'Charges'];

            // 3. Group other charges by Product__c (using the lookup Id)
            Map<Id, Decimal> productWiseTotal = new Map<Id, Decimal>();
            for (Charges_Insurance__c c : otherCharges) {
                if (c.Product__c != null) {
                    Decimal existingTotal = productWiseTotal.containsKey(c.Product__c) ? productWiseTotal.get(c.Product__c) : 0;
                    productWiseTotal.put(c.Product__c, existingTotal + (c.Final_Amount_INR__c != null ? c.Final_Amount_INR__c : 0));
                }
            }

            // 4. Update each Total Charges record based on its Product__c
            for (Charges_Insurance__c totalCharge : totalChargeRecords) {
                if (totalCharge.Product__c != null && productWiseTotal.containsKey(totalCharge.Product__c)) {
                    totalCharge.Total_Charges__c = productWiseTotal.get(totalCharge.Product__c);
                    totalCharge.GstCalculated__c = true;
                } else {
                    totalCharge.Total_Charges__c = 0;
                    totalCharge.GstCalculated__c = false;
                }
            }

            System.debug('Updated Total Charges Records: ' + totalChargeRecords);

            // 5. Update all Total Charges records
            if (!totalChargeRecords.isEmpty()) {
                update totalChargeRecords;
            }

        } catch (Exception e) {
            System.debug('Error updating Total Charges: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Charges_Insurance__c> getChargesRecords(Id loanId) {
        try {
             // 2) Read CMDT where GST is applicable for this product & sub-product
        // Replace Login_Fees_Mappings__mdt with your actual CMDT API name
        List<Login_Fees__mdt> gstMappings = [
            SELECT MasterLabel,
            Is_GST_Applicable__c
            FROM Login_Fees__mdt
            WHERE Is_GST_Applicable__c = true
        ];

        // 3) Build the allowed charge-name set (exact name match)
        Set<String> allowedNames = new Set<String>();
        for (Login_Fees__mdt m : gstMappings) {
         allowedNames.add(m.MasterLabel);
        }
            List<Charges_Insurance__c> chargesList = [SELECT Id, Name, Product__c,Product_Name__c,Requested_Amount_INR__c FROM Charges_Insurance__c WHERE Loan_Application__c = :loanId AND Name IN :allowedNames and Product__r.Product_Type__c='Parent'];
            
            return chargesList;
            
        } catch (Exception ex) {
            System.debug('Unexpected Exception: ' + ex.getMessage());
            return new List<Charges_Insurance__c>();
        }
    }

    @AuraEnabled
    public static boolean deleteContentDoctIdLoginFee(String docId, String cdLId){
        Boolean flag = false;
        String loanId =[Select id, Loan_Application__c from Document_Details__c WHERE Id =:docId].Loan_Application__c;
        List<Charges_Insurance__c> chargInsurance = [Select id,Charges_Fee_Type__c from Charges_Insurance__c where Loan_Application__c=:loanId and Charges_Fee_type__c='Login Fee'];
        System.debug('chargInsurance>>'+chargInsurance);
        if(cdLId != null){
            Delete [SELECT Id FROM ContentDocument WHERE Id =:cdLId]; 
            flag=true;
            if(docId != null){
                 Delete [SELECT Id FROM Document_Details__c WHERE Id =:docId]; 
                 flag=true;
            }     
        
        }
        if(chargInsurance.size()>0){
            Charges_Insurance__c chargeRecord = new Charges_Insurance__c();
            chargeRecord.id=chargInsurance[0].id;
            delete chargeRecord;
            flag=true;
        }
        return flag;
    }

    @AuraEnabled
    public static boolean deletecontentDocumentAndDocFile(String docId, String cdLId){
        try {
            Boolean flag = false;
            if (String.isNotBlank(cdLId)) {
                Delete [SELECT Id FROM ContentDocument WHERE Id =:cdLId];
                flag = true;
            }
            if(String.isNotBlank(docId)){
                Delete [SELECT Id FROM Document_Details__c WHERE Id =:docId];
                flag = true;
            }
            return flag;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + '-' + e.getStackTraceString());
        }
        
    }

     @AuraEnabled
    public static String getPrimaryApplicant(String recordId) {
        String applicantName = '';
        Application_Applicant__c primaryApplicant = [SELECT id,Applicant_Type__c,name FROM Application_Applicant__c WHERE Loan_Application__c =:recordId AND Applicant_Type__c = 'Primary Applicant' Limit 1];
        if(primaryApplicant != Null) {
            applicantName = primaryApplicant.name;
        }
        return applicantName;
    }

     @AuraEnabled
     public static void whatIfApiCallOut(String recordId){

     }

}