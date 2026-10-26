public with sharing class COMM_LoanSchedulerContoller {

    static String conLabels = 'MESSAGEID,Language,ServiceName,ENTITYID,ServiceVersion';

    public static Map <String,String> constants = Utility.getConstants(conLabels);

    //getting the value of constants 
    public static Map <String,String> getConstants() {
        return constants;
    }

    @AuraEnabled
    public static List<Opportunity> getOpportunitiesForLWC(Id recordId) {
        return [SELECT Id, Name, StageName, Login_Completion_Stage__c,Loan_Application_Number__c,Requested_Amount__c, Sanction_Loan_Amount__c 
                FROM Opportunity WHERE Id = :recordId];
    }
    @AuraEnabled
    public static void updateWhatIfStatus(Id loginFeeId, String status) {
        Charges_Insurance__c fee = new Charges_Insurance__c(Id = loginFeeId, whatifAPIStatus__c = status);
        update fee;
    }
    @AuraEnabled(cacheable=true)
    public static String getWhatIfStatus(Id loanId) {
        Charges_Insurance__c fee = [
            SELECT Id,Charges_Fee_Type__c, whatifAPIStatus__c 
            FROM Charges_Insurance__c 
            WHERE Loan_Application__c = :loanId and Charges_Fee_Type__c = 'Login Fee'
            LIMIT 1
        ];
        return fee.whatifAPIStatus__c;
    }
    
    @AuraEnabled
    public static String upsertChargesForMultiProd(Map<String, String> inputMap, List<Opportunity> oppList, String invocationType) {
        try {
            String returnMessage = 'Success';
            String loanId = inputMap.get('loanId');
            String stageName = inputMap.get('stageName');
            String chargeRecordType = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName().get('Charges').getRecordTypeId();
            List<Charges_Insurance__c> consolidatedChargeListToUpsert = new List<Charges_Insurance__c>();
            List<Charges_Insurance__c> chargesToDelete = new List<Charges_Insurance__c>();

            if (String.isEmpty(loanId)) {
                throw new AuraHandledException('Error: Missing loanId.');
            }

            List<Product2> productList = [Select Id,Name,RecordType.Name,Sanctioned_Loan_Amount__c,Sanctioned_Tenor__c,Requested_Loan_Amount__c,Product_Master__c,Product_Master__r.Name,Product__c,Product__r.Product_Master__r.Name,Product__r.Product_Type__c from Product2 
                                          WHERE RecordType.Name = 'Sub Product' AND Loan_Application__c = :loanId];

            Map<String, Map<String, Object>> feeTypeToMasterDataMap = new Map<String, Map<String, Object>>();
            List<Charges_Insurance_Master__c> chargesInsuranceMasterRecords = [
                        SELECT Id, Charges_Fee_Type__c, Tax__c, Category__c,Max_Percent__c,Min_Percent__c
                        FROM Charges_Insurance_Master__c
                        WHERE Category__c != 'LMS' AND Charges_Fee_Type__c !=null AND Charges_Fee_Type__c not in ('Login Fee','LUC')
                    ];

            for (Charges_Insurance_Master__c master : chargesInsuranceMasterRecords) {
                Map<String, Object> masterData = new Map<String, Object>();
                masterData.put('MasterId', master.Id);
                masterData.put('Tax', master.Tax__c != null ? master.Tax__c : 0); // Default tax to 0 if null
                masterData.put('Category',master.Category__c != null ? master.Category__c:'');
                masterData.put('MinPercent',master.Min_Percent__c != null ? master.Min_Percent__c:0);
                masterData.put('MaxPercent',master.Max_Percent__c != null ? master.Max_Percent__c:0);
                feeTypeToMasterDataMap.put(master.Charges_Fee_Type__c, masterData);
            }    
            
            for(Product2 prod : productList){
               String productId = prod.Product__c; 
               Decimal productWiseTotalChargeAmount = 0;
               Decimal loginFeesPSV = 0;
               Set<String> feeCodes = new Set<String>();
               Map<String, Charges_Insurance__c> existingChargesMap = new Map<String, Charges_Insurance__c>();
               List<Charges_Insurance__c> chargeList = new List<Charges_Insurance__c>();

                for(String feeType : feeTypeToMasterDataMap.keyset()){
                    feeCodes.add(feeType);
                }

                for (Charges_Insurance__c ci : [
                    SELECT Id,Name,Stage__c,Allocated_Amount__c,Requested_Amount_INR__c,Balance_Fees__c,Balance_Login_Fees__c,Login_Fees__c, Charges_Fee_Type__c,Paid_Orginal__c,Paid_Amount_Gst__c,Adjusted_Login_Fee__c
                    FROM Charges_Insurance__c
                    WHERE Loan_Application__c = :loanId
                    AND Charges_Fee_Type__c IN :feeCodes AND Product__c = :productId
                ]) {
                    existingChargesMap.put(ci.Charges_Fee_Type__c, ci);
                }

               Charges_Insurance__c newCharge= new Charges_Insurance__c();
               for(String feeType : feeTypeToMasterDataMap.keyset()){
                    Decimal defaultAmount = 0;
                    Decimal defaultValue = 0;
                    Login_Fees__mdt mapping = Login_Fees__mdt.getInstance(feeType);
                    if (mapping != null) {
                        defaultValue = mapping.Default_Value__c;
                    }
                    if(feeType == 'PROCFEE'){
                        defaultAmount = (prod.Sanctioned_Loan_Amount__c * defaultValue) / 100;
                    }
                    else{
                        defaultAmount = defaultValue;
                    }

                    if (existingChargesMap.containsKey(feeType)) {
                        System.debug('line 289--->>');
                        newCharge = existingChargesMap.get(feeType);
                        newCharge.Allocated_Amount__c = defaultAmount;
                        newCharge.Default_Amount_INR__c = defaultAmount;
                        
                    } else {      
                        newCharge = new Charges_Insurance__c();
                        newCharge.Name = feeType;
                        newCharge.Fee_Method__c = 'DISB';
                        newCharge.Charges_Fee_Type__c = feeType;
                        system.debug('line 256-->>'+ newCharge.Charges_Fee_Type__c);
                        newCharge.Loan_Application__c = loanId;
                        newCharge.Default_Amount_INR__c = defaultAmount;
                        newCharge.RecordTypeID = chargeRecordType;
                        newCharge.Product__c = productId;
                        newCharge.Stage__c = stageName;
                        newCharge.GST_Exempt__c = 'E';
                        newCharge.Allocated_Amount__c = defaultAmount;  
                    }

                    if (feeTypeToMasterDataMap.containsKey(feeType)) {
                        Map<String, Object> masterData = feeTypeToMasterDataMap.get(feeType);
                        newCharge.Charges_Insurance_Master__c = (Id) masterData.get('MasterId');
                        newCharge.Tax__c = (Decimal) masterData.get('Tax');
                        newCharge.Category__c = (String) masterData.get('Category');
                        newCharge.Min_Percent__c = (Decimal) masterData.get('MinPercent');
                        newCharge.Max_Percent__c = (Decimal) masterData.get('MaxPercent');
                    } else {
                        newCharge.Tax__c = 0;
                    }
                        
                    newCharge.Final_Amount_INR__c = defaultAmount;
                    newCharge.Tax_INR__c = 0;

                    Decimal totalChargeAmount = defaultAmount != null ? defaultAmount : 0;
                    productWiseTotalChargeAmount += totalChargeAmount;

                    //login fee calculation
                    if(existingChargesMap.containsKey(feeType)){
                        loginFeesPSV = existingChargesMap.get(feeType).Adjusted_Login_Fee__c != null ? existingChargesMap.get(feeType).Adjusted_Login_Fee__c : 0 ;
                    }
                    else{
                        loginFeesPSV = 0;
                    }
                
                    newCharge.Login_Fees__c = loginFeesPSV;
                    newCharge.Balance_Charge_Amount__c = newCharge.Allocated_Amount__c - loginFeesPSV;
                    newCharge.Requested_Amount_INR__c =  newCharge.Balance_Charge_Amount__c;
                    newCharge.Balance_Fees__c =  newCharge.Requested_Amount_INR__c;
                    newCharge.Final_Amount_INR__c =  newCharge.Requested_Amount_INR__c;
                    newCharge.Balance_Login_Fees__c = 0;
                    newCharge.Adjusted_Login_Fee__c = loginFeesPSV;

                    chargeList.add(newCharge);
               }
               
                //parent charge logic
                Charges_Insurance__c parentChargeProductwise= new Charges_Insurance__c();
                List<Charges_Insurance__c> parentChargeListProductwise = new List<Charges_Insurance__c>();
                List<Charges_Insurance__c> existingTotalChargesRecords = [
                        SELECT Id,name, Loan_Application__c,Loan_Application__r.StageName,Balance_Login_Fees__c,Loan_Application__r.Requested_Amount__c, Total_Charges__c,Requested_Amount_INR__c, Total_Fee_to_be_deducted__c
                        FROM Charges_Insurance__c
                        WHERE Loan_Application__c = :loanId AND Name = 'Total Charges' AND Product__c = :productId];

                if(!existingTotalChargesRecords.isEmpty()){
                    parentChargeProductwise = existingTotalChargesRecords[0];
                }
                else{
                    // **Create a New Total Charges Record**
                    Charges_Insurance__c parentCharge = new Charges_Insurance__c();
                    parentCharge.Name = 'Total Charges';
                    parentCharge.Loan_Application__c = loanId;
                    parentCharge.RecordTypeID = chargeRecordType;
                    parentCharge.Product__c = productId;
                    parentCharge.Total_Charges__c = productWiseTotalChargeAmount;
                    parentCharge.Total_Fee_to_be_deducted__c = productWiseTotalChargeAmount;
                    
                    parentChargeListProductwise.add(parentCharge);
                }

                if (!parentChargeListProductwise.isEmpty()) {
                    System.debug('Inserting Parent Charge Records: ' + parentChargeListProductwise);
                    insert parentChargeListProductwise;
                    parentChargeProductwise = parentChargeListProductwise[0];
                }

                for(Charges_Insurance__c charge : chargeList){
                  charge.Charges_Insurance__c = parentChargeProductwise.Id;
                }

                consolidatedChargeListToUpsert.addAll(chargeList);
            }


            if(!consolidatedChargeListToUpsert.isEmpty()){
                System.debug('Inserting consolidatedChargeListToUpsert: ' + consolidatedChargeListToUpsert);
                if(System.Test.isrunningTest()){
                    upsert consolidatedChargeListToUpsert[0];
                }else {
                upsert consolidatedChargeListToUpsert;
                }

            }

            //delete the charges reocords where product is null
            chargesToDelete = [SELECT Id FROM Charges_Insurance__c WHERE Loan_Application__c = :loanId AND Name != 'Login fee' AND Product__c = null];
            if (!chargesToDelete.isEmpty()) delete chargesToDelete;

            return returnMessage;
        } catch (Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'COMM_LoanScheduler', '', '') });
            System.debug('Exception in COMM_LoanScheduler: ' + e.getMessage()+' line number: '+ e.getStackTraceString());
            throw new AuraHandledException('Salesforce Exception: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String initiateAPIRequestForMultiProd(Map<String, String> inputMap, List<Opportunity> oppList, String invocationType) {
        try {
            MultiproductChargesResponseWrapper responseForAHL;
            MultiproductChargesResponseWrapper responseForAHLChild;
            MultiproductChargesResponseWrapper responseForFL;
            MultiproductChargesResponseWrapper responseForANHL;
            MultiproductChargesResponseWrapper responseForHL;
            MultiproductChargesResponseWrapper responseForNHL;
            String returnMessage = 'Success';
            Map<String, String> inputMapFL = new Map<String, String>(inputMap);
            Map<String, String> inputMapANHL = new Map<String, String>(inputMap);
            Map<String, String> inputMapHL = new Map<String, String>(inputMap);
            Map<String, String> inputMapNHL = new Map<String, String>(inputMap);
            Map<String, String> inputMapAHLChild = new Map<String, String>(inputMap);
            String loanId = inputMap.get('loanId');
            String stageName = inputMap.get('stageName');
            Decimal totalChargeAmountAHL = 0;
            Decimal totalChargeAmountAHLChild = 0;
            Decimal totalChargeAmountFL = 0;
            Decimal totalChargeAmountANHL = 0;
            Decimal totalChargeAmountHL = 0;
            Decimal totalChargeAmountNHL = 0;
            String chargeRecordType = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName().get('Charges').getRecordTypeId();
            List<Integration_Details__c> integrationToInsert = new List<Integration_Details__c>();
            List<Charges_Insurance__c> ahlChargeListToUpsert = new List<Charges_Insurance__c>();
            List<Charges_Insurance__c> ahlChildChargeListToUpsert = new List<Charges_Insurance__c>();
            List<Charges_Insurance__c> flChargeListToUpsert = new List<Charges_Insurance__c>();
            List<Charges_Insurance__c> hlChargeListToUpsert = new List<Charges_Insurance__c>();
            List<Charges_Insurance__c> nhlChargeListToUpsert = new List<Charges_Insurance__c>();
            List<Charges_Insurance__c> anhlChargeListToUpsert = new List<Charges_Insurance__c>();
            List<Charges_Insurance__c> parentChargeListAHL = new List<Charges_Insurance__c>();
            List<Charges_Insurance__c> parentChargeListAHLChild = new List<Charges_Insurance__c>();
            List<Charges_Insurance__c> parentChargeListFL = new List<Charges_Insurance__c>();
            List<Charges_Insurance__c> parentChargeListANHL = new List<Charges_Insurance__c>();
            List<Charges_Insurance__c> parentChargeListHL = new List<Charges_Insurance__c>();
            List<Charges_Insurance__c> parentChargeListNHL = new List<Charges_Insurance__c>();
            List<Charges_Insurance__c> consolidatedChargeListToUpsert = new List<Charges_Insurance__c>();
            List<Charges_Insurance__c> chargesToDelete = new List<Charges_Insurance__c>();

            if (String.isEmpty(loanId)) {
                throw new AuraHandledException('Error: Missing loanId.');
            }

            List<Product2> productList = [Select Id,Name,RecordType.Name,Sanctioned_Loan_Amount__c,Sanctioned_Tenor__c,Requested_Loan_Amount__c,Product_Master__c,Product_Master__r.Name,Product__c,Product__r.Product_Master__r.Name,Product__r.Product_Type__c from Product2 
                                          WHERE RecordType.Name = 'Sub Product' AND Loan_Application__c = :loanId ];
            for(Product2 prod : productList){
                if(prod.Product__r.Product_Master__r.Name == 'Affordable Home Loan' && prod.Product__r.Product_Type__c == 'Parent'){
                    inputMap.put('productId', prod.Product__c);
                    inputMap.put('productName', prod.Product__r.Product_Master__r.Name);
                    // TODO : when calling from sales stage pass requested amount from product2 instead of sanction amt
                    if(stageName == 'Sales Login'){
                        inputMap.put('sanctionLoanAmount', String.valueof(prod.Requested_Loan_Amount__c)); 
                        inputMap.put('sanctionLoanTenure', '0');
                    }
                    else{
                        inputMap.put('sanctionLoanAmount', String.valueof(prod.Sanctioned_Loan_Amount__c)); 
                        inputMap.put('sanctionLoanTenure', String.valueof(prod.Sanctioned_Tenor__c));
                    }
                }
                else if(prod.Product__r.Product_Master__r.Name == 'Affordable Home Loan' && prod.Product__r.Product_Type__c == 'Child'){
                    inputMapAHLChild.put('productId', prod.Product__c);
                    inputMapAHLChild.put('productName', prod.Product__r.Product_Master__r.Name);
                    // TODO : when calling from sales stage pass requested amount from product2 instead of sanction amt
                    if(stageName == 'Sales Login'){
                        inputMapAHLChild.put('sanctionLoanAmount', String.valueof(prod.Requested_Loan_Amount__c));
                        inputMapAHLChild.put('sanctionLoanTenure', '0'); 
                    }
                    else{
                        inputMapAHLChild.put('sanctionLoanAmount', String.valueof(prod.Sanctioned_Loan_Amount__c)); 
                        inputMapAHLChild.put('sanctionLoanTenure', String.valueof(prod.Sanctioned_Tenor__c));
                    }
                }
                else if(prod.Product__r.Product_Master__r.Name == 'Affordable Non-Home Loan'){
                    inputMapANHL.put('productName', prod.Product__r.Product_Master__r.Name);
                    inputMapANHL.put('productId', prod.Product__c);
                    if(stageName == 'Sales Login'){
                        inputMapANHL.put('sanctionLoanAmount', String.valueof(prod.Requested_Loan_Amount__c)); 
                        inputMapANHL.put('sanctionLoanTenure', '0'); 
                    }
                    else{
                        inputMapANHL.put('sanctionLoanAmount', String.valueof(prod.Sanctioned_Loan_Amount__c));
                        inputMapANHL.put('sanctionLoanTenure', String.valueof(prod.Sanctioned_Tenor__c)); 
                    }
                }
                else if(prod.Product__r.Product_Master__r.Name == 'Flexi Loan'){
                    inputMapFL.put('productName', prod.Product__r.Product_Master__r.Name);
                    inputMapFL.put('productId', prod.Product__c);
                    if(stageName == 'Sales Login'){
                        inputMapFL.put('sanctionLoanAmount', String.valueof(prod.Requested_Loan_Amount__c)); 
                        inputMapFL.put('sanctionLoanTenure', '0'); 
                    }
                    else{
                        inputMapFL.put('sanctionLoanAmount', String.valueof(prod.Sanctioned_Loan_Amount__c)); 
                        inputMapFL.put('sanctionLoanTenure', String.valueof(prod.Sanctioned_Tenor__c)); 
                    }
                }
                else if(prod.Product__r.Product_Master__r.Name == 'Home Loan' && prod.Product__r.Product_Type__c == 'Parent' ){
                    inputMapHL.put('productName', prod.Product__r.Product_Master__r.Name);
                    inputMapHL.put('productId', prod.Product__c);
                    if(stageName == 'Sales Login'){
                        inputMapHL.put('sanctionLoanAmount', String.valueof(prod.Requested_Loan_Amount__c)); 
                    }
                    else{
                        inputMapHL.put('sanctionLoanAmount', String.valueof(prod.Sanctioned_Loan_Amount__c)); 
                    }
                }
                else if(prod.Product__r.Product_Master__r.Name == 'Non Home Loan'){
                    inputMapNHL.put('productName', prod.Product__r.Product_Master__r.Name);
                    inputMapNHL.put('productId', prod.Product__c);
                    if(stageName == 'Sales Login'){
                        inputMapNHL.put('sanctionLoanAmount', String.valueof(prod.Requested_Loan_Amount__c)); 
                    }
                    else{
                        inputMapNHL.put('sanctionLoanAmount', String.valueof(prod.Sanctioned_Loan_Amount__c)); 
                    }
                }
                }
            system.debug('inputMapNHL---'+inputMapNHL);
            String loginFeesStr;
            Decimal loginFees;
            if (inputMap.containsKey('loginFee') && inputMap.get('loginFee') != null) {
                loginFeesStr = inputMap.get('loginFee');
            } else {
            loginFeesStr = null; 
            }
            //String loginFeesStr = inputMap.get('loginFee');
            if(loginFeesStr!=null){
             loginFees  = Integer.valueOf(loginFeesStr);
            }
        
        
            /////////// AHL /////////////
            if(returnMessage == 'Success' && inputMap.containsKey('productName') && inputMap.get('productName') == 'Affordable Home Loan'){
                responseForAHL = initiateAPIRequestProductWise(inputMap, oppList, invocationType);
                integrationToInsert.add(responseForAHL.intDetail);
                if(responseForAHL.returnStatus == 'Success'){
                    Decimal loginFeesPSV;
                    returnMessage = responseForAHL.returnStatus;

                    String productId = inputMap.get('productId');           
                    Set<String> feeCodes = new Set<String>();
                    Map<String, Charges_Insurance__c> existingChargesMap = new Map<String, Charges_Insurance__c>();
                
                    // **Charge Creation Logic**
                    List<Charges_Insurance__c> chargeList = new List<Charges_Insurance__c>();
                    Map<String, Map<String, Object>> feeTypeToMasterDataMap = new Map<String, Map<String, Object>>();
                    
                    // **Query Charges_Insurance_Master__c Records**
                    List<Charges_Insurance_Master__c> chargesInsuranceMasterRecords = [
                        SELECT Id, Charges_Fee_Type__c, Tax__c, Category__c,Max_Percent__c,Min_Percent__c
                        FROM Charges_Insurance_Master__c
                        WHERE Category__c != 'LMS'
                    ];
                    
                    // **Map Master Records by Fee Type**
                    for (Charges_Insurance_Master__c master : chargesInsuranceMasterRecords) {
                        Map<String, Object> masterData = new Map<String, Object>();
                        masterData.put('MasterId', master.Id);
                        masterData.put('Tax', master.Tax__c != null ? master.Tax__c : 0); // Default tax to 0 if null
                        masterData.put('Category',master.Category__c != null ? master.Category__c:'');
                        masterData.put('MinPercent',master.Min_Percent__c != null ? master.Min_Percent__c:0);
                        masterData.put('MaxPercent',master.Max_Percent__c != null ? master.Max_Percent__c:0);
                        feeTypeToMasterDataMap.put(master.Charges_Fee_Type__c, masterData);
                    }
                    
                    // **Process API Fees & Update Total Charges**
                    //Map<Id, Charges_Insurance__c> updatedParentChargeMap = new Map<Id, Charges_Insurance__c>();
                    
                    for (Opportunity opp : oppList) {  
                        System.debug('Processing LOS Charges for Opportunity: ' + opp.Id);
                        
                        for (Fee fee : responseForAHL.fees) {
                            feeCodes.add(fee.feeCode);
                        }
                        
                        for (Charges_Insurance__c ci : [
                            SELECT Id,Name,Stage__c,Allocated_Amount__c,Requested_Amount_INR__c,Balance_Fees__c,Balance_Login_Fees__c,Login_Fees__c, Charges_Fee_Type__c,Paid_Orginal__c,Paid_Amount_Gst__c
                            FROM Charges_Insurance__c
                            WHERE Loan_Application__c = :opp.Id
                            AND Charges_Fee_Type__c IN :feeCodes AND Product__c = :productId
                        ]) {
                            existingChargesMap.put(ci.Charges_Fee_Type__c, ci);
                        }
                        
                        if (responseForAHL != null && responseForAHL.fees != null) {
                            System.debug('Fees Found AHL: ' + responseForAHL.fees);
                            Charges_Insurance__c newCharge= new Charges_Insurance__c();
                            for (Fee fee : responseForAHL.fees) {            
                                if(stageName == 'Sales Login' || stageName == 'PSV' || stageName == 'Disbursement'){           
                                    if (existingChargesMap.containsKey(fee.feeCode)) {
                                        System.debug('line 289--->>');
                                        newCharge = existingChargesMap.get(fee.feeCode);
                                            newCharge.Allocated_Amount__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        newCharge.Default_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        //newCharge.Requested_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        
                                    } else {      
                                        newCharge = new Charges_Insurance__c();
                                        newCharge.Name = fee.feeCode;
                                        newCharge.Fee_Method__c = fee.feeMethod;
                                        //newCharge.Charges_Insurance__c = parentCharge.Id;
                                        newCharge.Charges_Fee_Type__c = fee.feeCode;
                                        system.debug('line 256-->>'+ newCharge.Charges_Fee_Type__c);
                                        newCharge.Loan_Application__c = opp.Id;
                                        newCharge.Default_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        //newCharge.Requested_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        //newCharge.Category__c = 'LOS';
                                        newCharge.RecordTypeID = chargeRecordType;
                                        newCharge.Product__c = productId;
                                        newCharge.Stage__c = stageName;
                                        //newCharge.Allocation__c = (requestedAmount) / (Utility.truncateTwoZeros(fee.feeAmount)) * 100;
                                        Login_Fees__mdt mapping = Login_Fees__mdt.getInstance(fee.feeCode);
                                        if (mapping != null) {
                                                newCharge.Priority__c = mapping.Priority__c;
                                            }
                                        newCharge.GST_Exempt__c = 'E';
                                        
                                        /*if(fee.feeCode == 'PROCFEE'){
                                            newCharge.Priority__c = 1;
                                        }
                                        else if(fee.feeCode == 'STFRCHG'){
                                            newCharge.Priority__c = 3;
                                        }*/
                                        newCharge.Allocated_Amount__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        if(loginFees!=null){
                                        newCharge.Login_Fees__c = loginFees;
                                        }   
                                    }
                                }
                                    
                                Decimal taxPercentage = 0; // Default to 0%
                                Decimal taxAmount = 0;      // Calculated tax amount
                                
                                // **Tag the Master Record ID based on Fee Type**
                                newCharge.Name = fee.feeCode;
                                if (feeTypeToMasterDataMap.containsKey(fee.feeCode)) {
                                    Map<String, Object> masterData = feeTypeToMasterDataMap.get(fee.feeCode);
                                    newCharge.Charges_Insurance_Master__c = (Id) masterData.get('MasterId');
                                    newCharge.Tax__c = (Decimal) masterData.get('Tax');
                                    newCharge.Category__c = (String) masterData.get('Category');
                                    newCharge.Min_Percent__c = (Decimal) masterData.get('MinPercent');
                                    newCharge.Max_Percent__c = (Decimal) masterData.get('MaxPercent');
                                    taxPercentage = (Decimal) masterData.get('Tax'); 
                                } else {
                                    newCharge.Tax__c = 0;
                                }
                                // **Calculate Tax Amount (Tax % of Fee Amount)**
                                /*if (taxPercentage > 0 && Utility.truncateTwoZeros(fee.feeAmount) != null) {
                                taxAmount = (Utility.truncateTwoZeros(fee.feeAmount) * taxPercentage) / 100;
                                    }

                                newCharge.Final_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount) + taxAmount;*/
                                if (taxPercentage > 0 && Utility.truncateTwoZeros(fee.feeAmount) != null) {
                                    Decimal rawTaxAmount = (Utility.truncateTwoZeros(fee.feeAmount) * taxPercentage) / 100;
                                    Decimal decimalPart = rawTaxAmount - Math.floor(rawTaxAmount);
                                    taxAmount = decimalPart < 0.5 ? Math.floor(rawTaxAmount) : Math.ceil(rawTaxAmount);
                                }
                                
                                newCharge.Final_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount) + taxAmount;
                                newCharge.Tax_INR__c = 0;

                                
                                if(System.Test.isrunningTest()){
                                    newCharge.Allocated_Amount__c= 0;
                                }
                                
                                chargeList.add(newCharge);
                                
                                // **Update Parent Charge Totals (Including Tax)**
                                Decimal totalChargeAmount = (Utility.truncateTwoZeros(fee.feeAmount) != null ? Utility.truncateTwoZeros(fee.feeAmount) : 0) + taxAmount;
                                
                                totalChargeAmountAHL += totalChargeAmount;

                                // parentCharge.Total_Charges__c += totalChargeAmount;
                                // parentCharge.Total_Fee_to_be_deducted__c += totalChargeAmount;
                                // updatedParentChargeMap.put(parentCharge.Id, parentCharge);
                            }
                            
                            chargeList.sort(new ChargePriorityComparator());
                            for (Charges_Insurance__c newChargee : chargeList) {
                                
                                if(stageName == 'Sales login'){
                                newChargee.Requested_Amount_INR__c =  newChargee.Allocated_Amount__c;
                                }
                                else{
                                        //for non-sales
                                    if(existingChargesMap.containsKey(newChargee.Name)){
                                        loginFeesPSV = existingChargesMap.get(newChargee.Name).Paid_Orginal__c != null ? existingChargesMap.get(newChargee.Name).Paid_Orginal__c : 0 ;
                                    }
                                    else{
                                        loginFeesPSV = 0;
                                    }
                                    decimal remainingloginfeePSV = loginFeesPSV;
                                    decimal adjustedLoginFeePSV = loginFeesPSV;
                                
                                        if(newChargee.name == 'PROCFEE'){
                                            newChargee.Login_Fees__c = loginFeesPSV;
                                        }
        
                                        if(loginFeesPSV!=null){
                                        if (newChargee.Allocated_Amount__c > loginFeesPSV) {
                                            
                                            newChargee.Balance_Charge_Amount__c = newChargee.Allocated_Amount__c - loginFeesPSV;
                                            newChargee.Requested_Amount_INR__c =  newChargee.Balance_Charge_Amount__c;
                                            newChargee.Balance_Fees__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Final_Amount_INR__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Balance_Login_Fees__c = 0;
                                            newChargee.Adjusted_Login_Fee__c = adjustedLoginFeePSV;
                                            loginFeesPSV = 0; 
                                            
                                            if(newChargee.name == 'PROCFEE'){
                                                
                                                remainingloginfeePSV =newChargee.Balance_Login_Fees__c;
                                                adjustedLoginFeePSV = newChargee.Balance_Login_Fees__c ;
                                            }
                                            if(newChargee.name != 'PROCFEE'){
                                                newChargee.Login_Fees__c = remainingloginfeePSV;
                                            }
                                            system.debug('line 409--'+newChargee.Login_Fees__c);
                                            system.debug('line 410--'+newCharge.Allocated_Amount__c);
                                            
                                            
                                        } else {
                                            
                                            newChargee.Balance_Charge_Amount__c = 0;
                                            newChargee.Balance_Login_Fees__c = loginFeesPSV - newChargee.Allocated_Amount__c;
                                            newChargee.Requested_Amount_INR__c =  newChargee.Balance_Login_Fees__c;
                                            newChargee.Balance_Fees__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Final_Amount_INR__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Adjusted_Login_Fee__c  = newChargee.Allocated_Amount__c;
                                            if(newChargee.name == 'PROCFEE'){   
                                                remainingloginfeePSV = newChargee.Balance_Login_Fees__c;
                                                adjustedLoginFeePSV = loginFeesPSV - newChargee.Allocated_Amount__c;
                                            }
                                            
                                            loginFeesPSV -= newChargee.Allocated_Amount__c;
                                            
                                            if(newChargee.name == 'STFRCHG'){
                                                newChargee.Login_Fees__c = remainingloginfeePSV;     
                                            }                            
                                        }
                                    } 
                                    }
                            
                        }
                    }
                        
                    if (!chargeList.isEmpty()) {
                        ahlChargeListToUpsert.addAll(chargeList);
                    }
                
                    // **Charge Creation Logic**

                    }
                }
                else{
                    returnMessage = responseForAHL.returnStatus;
                }
            }

            /////////// AHL CHILD /////////////
            if(returnMessage == 'Success' && inputMapAHLChild.containsKey('productName') && inputMapAHLChild.get('productName') == 'Affordable Home Loan'){
                responseForAHLChild = initiateAPIRequestProductWise(inputMapAHLChild, oppList, invocationType);
                integrationToInsert.add(responseForAHLChild.intDetail);
                if(responseForAHLChild.returnStatus == 'Success'){
                    Decimal loginFeesPSV;
                    returnMessage = responseForAHLChild.returnStatus;

                    String productId = inputMapAHLChild.get('productId');           
                    Set<String> feeCodes = new Set<String>();
                    Map<String, Charges_Insurance__c> existingChargesMap = new Map<String, Charges_Insurance__c>();
                
                    // **Charge Creation Logic**
                    List<Charges_Insurance__c> chargeList = new List<Charges_Insurance__c>();
                    Map<String, Map<String, Object>> feeTypeToMasterDataMap = new Map<String, Map<String, Object>>();
                    
                    // **Query Charges_Insurance_Master__c Records**
                    List<Charges_Insurance_Master__c> chargesInsuranceMasterRecords = [
                        SELECT Id, Charges_Fee_Type__c, Tax__c, Category__c,Max_Percent__c,Min_Percent__c
                        FROM Charges_Insurance_Master__c
                        WHERE Category__c != 'LMS'
                    ];
                    
                    // **Map Master Records by Fee Type**
                    for (Charges_Insurance_Master__c master : chargesInsuranceMasterRecords) {
                        Map<String, Object> masterData = new Map<String, Object>();
                        masterData.put('MasterId', master.Id);
                        masterData.put('Tax', master.Tax__c != null ? master.Tax__c : 0); // Default tax to 0 if null
                        masterData.put('Category',master.Category__c != null ? master.Category__c:'');
                        masterData.put('MinPercent',master.Min_Percent__c != null ? master.Min_Percent__c:0);
                        masterData.put('MaxPercent',master.Max_Percent__c != null ? master.Max_Percent__c:0);
                        feeTypeToMasterDataMap.put(master.Charges_Fee_Type__c, masterData);
                    }
                    
                    // **Process API Fees & Update Total Charges**
                    //Map<Id, Charges_Insurance__c> updatedParentChargeMap = new Map<Id, Charges_Insurance__c>();
                    
                    for (Opportunity opp : oppList) {  
                        System.debug('Processing LOS Charges for Opportunity: ' + opp.Id);
                        
                        for (Fee fee : responseForAHLChild.fees) {
                            feeCodes.add(fee.feeCode);
                        }
                        
                        for (Charges_Insurance__c ci : [
                            SELECT Id,Name,Stage__c,Allocated_Amount__c,Requested_Amount_INR__c,Balance_Fees__c,Balance_Login_Fees__c,Login_Fees__c, Charges_Fee_Type__c,Paid_Orginal__c,Paid_Amount_Gst__c
                            FROM Charges_Insurance__c
                            WHERE Loan_Application__c = :opp.Id
                            AND Charges_Fee_Type__c IN :feeCodes AND Product__c = :productId
                        ]) {
                            existingChargesMap.put(ci.Charges_Fee_Type__c, ci);
                        }
                        
                        if (responseForAHLChild != null && responseForAHLChild.fees != null) {
                            System.debug('Fees Found AHL: ' + responseForAHLChild.fees);
                            Charges_Insurance__c newCharge;
                            for (Fee fee : responseForAHLChild.fees) {            
                                if(stageName == 'Sales Login' || stageName == 'PSV' || stageName == 'Disbursement'){           
                                    if (existingChargesMap.containsKey(fee.feeCode)) {
                                        System.debug('line 289--->>');
                                        newCharge = existingChargesMap.get(fee.feeCode);
                                            newCharge.Allocated_Amount__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        newCharge.Default_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        //newCharge.Requested_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        
                                    } else {      
                                        newCharge = new Charges_Insurance__c();
                                        newCharge.Name = fee.feeCode;
                                        newCharge.Fee_Method__c = fee.feeMethod;
                                        //newCharge.Charges_Insurance__c = parentCharge.Id;
                                        newCharge.Charges_Fee_Type__c = fee.feeCode;
                                        system.debug('line 256-->>'+ newCharge.Charges_Fee_Type__c);
                                        newCharge.Loan_Application__c = opp.Id;
                                        newCharge.Default_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        //newCharge.Requested_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        //newCharge.Category__c = 'LOS';
                                        newCharge.RecordTypeID = chargeRecordType;
                                        newCharge.Product__c = productId;
                                        newCharge.Stage__c = stageName;
                                        //newCharge.Allocation__c = (requestedAmount) / (Utility.truncateTwoZeros(fee.feeAmount)) * 100;
                                        Login_Fees__mdt mapping = Login_Fees__mdt.getInstance(fee.feeCode);
                                        if (mapping != null) {
                                                newCharge.Priority__c = mapping.Priority__c;
                                            }
                                        newCharge.GST_Exempt__c = 'E';
                                        
                                        /*if(fee.feeCode == 'PROCFEE'){
                                            newCharge.Priority__c = 1;
                                        }
                                        else if(fee.feeCode == 'STFRCHG'){
                                            newCharge.Priority__c = 3;
                                        }*/
                                        newCharge.Allocated_Amount__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        if(loginFees!=null){
                                        newCharge.Login_Fees__c = loginFees;
                                        }   
                                    }
                                }
                                    
                                Decimal taxPercentage = 0; // Default to 0%
                                Decimal taxAmount = 0;      // Calculated tax amount
                                
                                // **Tag the Master Record ID based on Fee Type**
                                if (feeTypeToMasterDataMap.containsKey(fee.feeCode)) {
                                    Map<String, Object> masterData = feeTypeToMasterDataMap.get(fee.feeCode);
                                    newCharge.Charges_Insurance_Master__c = (Id) masterData.get('MasterId');
                                    newCharge.Tax__c = (Decimal) masterData.get('Tax');
                                    newCharge.Category__c = (String) masterData.get('Category');
                                    newCharge.Min_Percent__c = (Decimal) masterData.get('MinPercent');
                                    newCharge.Max_Percent__c = (Decimal) masterData.get('MaxPercent');
                                    taxPercentage = (Decimal) masterData.get('Tax'); 
                                } else {
                                    newCharge.Tax__c = 0;
                                }
                                // **Calculate Tax Amount (Tax % of Fee Amount)**
                                /*if (taxPercentage > 0 && Utility.truncateTwoZeros(fee.feeAmount) != null) {
                                taxAmount = (Utility.truncateTwoZeros(fee.feeAmount) * taxPercentage) / 100;
                                    }

                                newCharge.Final_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount) + taxAmount;*/
                                if (taxPercentage > 0 && Utility.truncateTwoZeros(fee.feeAmount) != null) {
                                    Decimal rawTaxAmount = (Utility.truncateTwoZeros(fee.feeAmount) * taxPercentage) / 100;
                                    Decimal decimalPart = rawTaxAmount - Math.floor(rawTaxAmount);
                                    taxAmount = decimalPart < 0.5 ? Math.floor(rawTaxAmount) : Math.ceil(rawTaxAmount);
                                }
                                
                                newCharge.Final_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount) + taxAmount;
                                newCharge.Tax_INR__c = 0;
                                
                                chargeList.add(newCharge);
                                
                                // **Update Parent Charge Totals (Including Tax)**
                                Decimal totalChargeAmount = (Utility.truncateTwoZeros(fee.feeAmount) != null ? Utility.truncateTwoZeros(fee.feeAmount) : 0) + taxAmount;
                                
                                totalChargeAmountAHLChild += totalChargeAmount;

                                // parentCharge.Total_Charges__c += totalChargeAmount;
                                // parentCharge.Total_Fee_to_be_deducted__c += totalChargeAmount;
                                // updatedParentChargeMap.put(parentCharge.Id, parentCharge);
                            }
                            
                            chargeList.sort(new ChargePriorityComparator());
                            for (Charges_Insurance__c newChargee : chargeList) {
                                
                                if(stageName == 'Sales login'){
                                newChargee.Requested_Amount_INR__c =  newChargee.Allocated_Amount__c;
                                }
                                else{
                                        //for non-sales
                                    if(existingChargesMap.containsKey(newChargee.Name)){
                                        loginFeesPSV = existingChargesMap.get(newChargee.Name).Paid_Orginal__c != null ? existingChargesMap.get(newChargee.Name).Paid_Orginal__c : 0 ;
                                    }
                                    else{
                                        loginFeesPSV = 0;
                                    }
                                    decimal remainingloginfeePSV = loginFeesPSV;
                                    decimal adjustedLoginFeePSV = loginFeesPSV;
                                
                                        if(newChargee.name == 'PROCFEE'){
                                            newChargee.Login_Fees__c = loginFeesPSV;
                                        }
        
                                        if(loginFeesPSV!=null){
                                        if (newChargee.Allocated_Amount__c > loginFeesPSV) {
                                            
                                            newChargee.Balance_Charge_Amount__c = newChargee.Allocated_Amount__c - loginFeesPSV;
                                            newChargee.Requested_Amount_INR__c =  newChargee.Balance_Charge_Amount__c;
                                            newChargee.Balance_Fees__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Final_Amount_INR__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Balance_Login_Fees__c = 0;
                                            newChargee.Adjusted_Login_Fee__c = adjustedLoginFeePSV;
                                            loginFeesPSV = 0; 
                                            
                                            if(newChargee.name == 'PROCFEE'){
                                                
                                                remainingloginfeePSV =newChargee.Balance_Login_Fees__c;
                                                adjustedLoginFeePSV = newChargee.Balance_Login_Fees__c ;
                                            }
                                            if(newChargee.name != 'PROCFEE'){
                                                newChargee.Login_Fees__c = remainingloginfeePSV;
                                            }
                                            system.debug('line 409--'+newChargee.Login_Fees__c);
                                            system.debug('line 410--'+newCharge.Allocated_Amount__c);
                                            
                                            
                                        } else {
                                            
                                            newChargee.Balance_Charge_Amount__c = 0;
                                            newChargee.Balance_Login_Fees__c = loginFeesPSV - newChargee.Allocated_Amount__c;
                                            newChargee.Requested_Amount_INR__c =  newChargee.Balance_Login_Fees__c;
                                            newChargee.Balance_Fees__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Final_Amount_INR__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Adjusted_Login_Fee__c  = newChargee.Allocated_Amount__c;
                                            if(newChargee.name == 'PROCFEE'){   
                                                remainingloginfeePSV = newChargee.Balance_Login_Fees__c;
                                                adjustedLoginFeePSV = loginFeesPSV - newChargee.Allocated_Amount__c;
                                            }
                                            
                                            loginFeesPSV -= newChargee.Allocated_Amount__c;
                                            
                                            if(newChargee.name == 'STFRCHG'){
                                                newChargee.Login_Fees__c = remainingloginfeePSV;     
                                            }                            
                                        }
                                    } 
                                    }
                            
                        }
                    }
                        
                    if (!chargeList.isEmpty()) {
                        ahlChildChargeListToUpsert.addAll(chargeList);
                    }
                
                    // **Charge Creation Logic**

                    }
                }
                else{
                    returnMessage = responseForAHLChild.returnStatus;
                }
            }

            ////////   ANHL ////////////
            if(returnMessage == 'Success' && inputMapANHL.containsKey('productName') && inputMapANHL.get('productName') == 'Affordable Non-Home Loan'){
               responseForANHL = initiateAPIRequestProductWise(inputMapANHL, oppList, invocationType);
               integrationToInsert.add(responseForANHL.intDetail);
                if(responseForANHL.returnStatus == 'Success'){
                    loginFees = 0;
                    Decimal loginFeesPSV;
                    returnMessage = responseForANHL.returnStatus;

                    //logic here
                     String productId = inputMapANHL.get('productId');
                     Set<String> feeCodes = new Set<String>();
                     Map<String, Charges_Insurance__c> existingChargesMap = new Map<String, Charges_Insurance__c>();

                    // **Charge Creation Logic**
                    List<Charges_Insurance__c> chargeList = new List<Charges_Insurance__c>();
                    Map<String, Map<String, Object>> feeTypeToMasterDataMap = new Map<String, Map<String, Object>>();
                    
                    // **Query Charges_Insurance_Master__c Records**
                    List<Charges_Insurance_Master__c> chargesInsuranceMasterRecords = [
                        SELECT Id, Charges_Fee_Type__c, Tax__c, Category__c,Max_Percent__c,Min_Percent__c
                        FROM Charges_Insurance_Master__c
                        WHERE Category__c != 'LMS'
                    ];
                    
                    // **Map Master Records by Fee Type**
                    for (Charges_Insurance_Master__c master : chargesInsuranceMasterRecords) {
                        Map<String, Object> masterData = new Map<String, Object>();
                        masterData.put('MasterId', master.Id);
                        masterData.put('Tax', master.Tax__c != null ? master.Tax__c : 0); // Default tax to 0 if null
                        masterData.put('Category',master.Category__c != null ? master.Category__c:'');
                        masterData.put('MinPercent',master.Min_Percent__c != null ? master.Min_Percent__c:0);
                        masterData.put('MaxPercent',master.Max_Percent__c != null ? master.Max_Percent__c:0);
                        feeTypeToMasterDataMap.put(master.Charges_Fee_Type__c, masterData);
                    }
                    
                    // **Process API Fees & Update Total Charges**
                    //Map<Id, Charges_Insurance__c> updatedParentChargeMap = new Map<Id, Charges_Insurance__c>();
                    
                    for (Opportunity opp : oppList) {  
                        System.debug('Processing LOS Charges for Opportunity: ' + opp.Id);
                        
                        for (Fee fee : responseForANHL.fees) {
                            feeCodes.add(fee.feeCode);
                        }
                        
                        for (Charges_Insurance__c ci : [
                            SELECT Id,Name,Stage__c,Allocated_Amount__c,Requested_Amount_INR__c,Balance_Fees__c,Balance_Login_Fees__c,Login_Fees__c, Charges_Fee_Type__c,Paid_Orginal__c
                            FROM Charges_Insurance__c
                            WHERE Loan_Application__c = :opp.Id
                            AND Charges_Fee_Type__c IN :feeCodes AND Product__c = :productId
                        ]) {
                            existingChargesMap.put(ci.Charges_Fee_Type__c, ci);
                        }
                        
                        if (responseForANHL != null && responseForANHL.fees != null) {
                            System.debug('Fees Found FL: ' + responseForANHL.fees);
                            Charges_Insurance__c newCharge;
                            for (Fee fee : responseForANHL.fees) {            
                                if(stageName == 'Sales Login' || stageName == 'PSV' || stageName == 'Disbursement'){           
                                    if (existingChargesMap.containsKey(fee.feeCode)) {
                                        System.debug('line 289--->>');
                                        newCharge = existingChargesMap.get(fee.feeCode);
                                            newCharge.Allocated_Amount__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        newCharge.Default_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        //newCharge.Requested_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        
                                    } else {      
                                        newCharge = new Charges_Insurance__c();
                                        newCharge.Name = fee.feeCode;
                                        newCharge.Fee_Method__c = fee.feeMethod;
                                        //newCharge.Charges_Insurance__c = parentCharge.Id;
                                        newCharge.Charges_Fee_Type__c = fee.feeCode;
                                        system.debug('line 256-->>'+ newCharge.Charges_Fee_Type__c);
                                        newCharge.Loan_Application__c = opp.Id;
                                        newCharge.Default_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        //newCharge.Requested_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        //newCharge.Category__c = 'LOS';
                                        newCharge.RecordTypeID = chargeRecordType;
                                        newCharge.Product__c = productId;
                                        newCharge.Stage__c = stageName;
                                        //newCharge.Allocation__c = (requestedAmount) / (Utility.truncateTwoZeros(fee.feeAmount)) * 100;
                                        Login_Fees__mdt mapping = Login_Fees__mdt.getInstance(fee.feeCode);
                                        if (mapping != null) {
                                                newCharge.Priority__c = mapping.Priority__c;
                                            }
                                        newCharge.GST_Exempt__c = 'E';
                                        
                                        /*if(fee.feeCode == 'PROCFEE'){
                                            newCharge.Priority__c = 1;
                                        }
                                        else if(fee.feeCode == 'STFRCHG'){
                                            newCharge.Priority__c = 3;
                                        }*/
                                        newCharge.Allocated_Amount__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        if(loginFees!=null){
                                        newCharge.Login_Fees__c = loginFees;
                                        }   
                                    }
                                }
                                    
                                Decimal taxPercentage = 0; // Default to 0%
                                Decimal taxAmount = 0;      // Calculated tax amount
                                
                                // **Tag the Master Record ID based on Fee Type**
                                if (feeTypeToMasterDataMap.containsKey(fee.feeCode)) {
                                    Map<String, Object> masterData = feeTypeToMasterDataMap.get(fee.feeCode);
                                    newCharge.Charges_Insurance_Master__c = (Id) masterData.get('MasterId');
                                    newCharge.Tax__c = (Decimal) masterData.get('Tax');
                                    newCharge.Category__c = (String) masterData.get('Category');
                                    newCharge.Min_Percent__c = (Decimal) masterData.get('MinPercent');
                                    newCharge.Max_Percent__c = (Decimal) masterData.get('MaxPercent');
                                    taxPercentage = (Decimal) masterData.get('Tax'); 
                                } else {
                                    newCharge.Tax__c = 0;
                                }
                                // **Calculate Tax Amount (Tax % of Fee Amount)**
                                /*if (taxPercentage > 0 && Utility.truncateTwoZeros(fee.feeAmount) != null) {
                                taxAmount = (Utility.truncateTwoZeros(fee.feeAmount) * taxPercentage) / 100;
                                    }

                                newCharge.Final_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount) + taxAmount;*/
                                if (taxPercentage > 0 && Utility.truncateTwoZeros(fee.feeAmount) != null) {
                                    Decimal rawTaxAmount = (Utility.truncateTwoZeros(fee.feeAmount) * taxPercentage) / 100;
                                    Decimal decimalPart = rawTaxAmount - Math.floor(rawTaxAmount);
                                    taxAmount = decimalPart < 0.5 ? Math.floor(rawTaxAmount) : Math.ceil(rawTaxAmount);
                                }
                                
                                newCharge.Final_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount) + taxAmount;
                                newCharge.Tax_INR__c = 0;
                                
                                chargeList.add(newCharge);
                                
                                // **Update Parent Charge Totals (Including Tax)**
                                Decimal totalChargeAmount = (Utility.truncateTwoZeros(fee.feeAmount) != null ? Utility.truncateTwoZeros(fee.feeAmount) : 0) + taxAmount;
                                
                                totalChargeAmountANHL += totalChargeAmount;

                                // parentCharge.Total_Charges__c += totalChargeAmount;
                                // parentCharge.Total_Fee_to_be_deducted__c += totalChargeAmount;
                                // updatedParentChargeMap.put(parentCharge.Id, parentCharge);
                            }
                            
                            chargeList.sort(new ChargePriorityComparator());
                            for (Charges_Insurance__c newChargee : chargeList) {
                                if(stageName == 'Sales login'){
                                newChargee.Requested_Amount_INR__c =  newChargee.Allocated_Amount__c;
                                }
                                else{
                                    //for non-sales
                                    if(existingChargesMap.containsKey(newChargee.Name)){
                                        loginFeesPSV = existingChargesMap.get(newChargee.Name).Paid_Orginal__c != null ? existingChargesMap.get(newChargee.Name).Paid_Orginal__c : 0 ;
                                    }
                                    else{
                                        loginFeesPSV = 0;
                                    }
                                    decimal remainingloginfeePSV = loginFeesPSV;
                                    decimal adjustedLoginFeePSV = loginFeesPSV;
                                
                                        if(newChargee.name == 'PROCFEE'){
                                            newChargee.Login_Fees__c = loginFeesPSV;
                                        }
        
                                        if(loginFeesPSV!=null){
                                        if (newChargee.Allocated_Amount__c > loginFeesPSV) {
                                            
                                            newChargee.Balance_Charge_Amount__c = newChargee.Allocated_Amount__c - loginFeesPSV;
                                            newChargee.Requested_Amount_INR__c =  newChargee.Balance_Charge_Amount__c;
                                            newChargee.Balance_Fees__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Final_Amount_INR__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Balance_Login_Fees__c = 0;
                                            newChargee.Adjusted_Login_Fee__c = adjustedLoginFeePSV;
                                            loginFeesPSV = 0; 
                                            
                                            if(newChargee.name == 'PROCFEE'){
                                                
                                                remainingloginfeePSV =newChargee.Balance_Login_Fees__c;
                                                adjustedLoginFeePSV = newChargee.Balance_Login_Fees__c ;
                                            }
                                            if(newChargee.name != 'PROCFEE'){
                                                newChargee.Login_Fees__c = remainingloginfeePSV;
                                            }
                                            system.debug('line 409--'+newChargee.Login_Fees__c);
                                            system.debug('line 410--'+newCharge.Allocated_Amount__c);
                                            
                                            
                                        } else {
                                            
                                            newChargee.Balance_Charge_Amount__c = 0;
                                            newChargee.Balance_Login_Fees__c = loginFeesPSV - newChargee.Allocated_Amount__c;
                                            newChargee.Requested_Amount_INR__c =  newChargee.Balance_Login_Fees__c;
                                            newChargee.Balance_Fees__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Final_Amount_INR__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Adjusted_Login_Fee__c  = newChargee.Allocated_Amount__c;
                                            if(newChargee.name == 'PROCFEE'){   
                                                remainingloginfeePSV = newChargee.Balance_Login_Fees__c;
                                                adjustedLoginFeePSV = loginFeesPSV - newChargee.Allocated_Amount__c;
                                            }
                                            
                                            loginFeesPSV -= newChargee.Allocated_Amount__c;
                                            
                                            if(newChargee.name == 'STFRCHG'){
                                                newChargee.Login_Fees__c = remainingloginfeePSV;     
                                            }                            
                                        }
                                    } 
                                    }
                            }
                            
                        }
                    }
                        
                    if (!chargeList.isEmpty()) {
                        anhlChargeListToUpsert.addAll(chargeList);
                    }
                
                    // **Charge Creation Logic**
                }
                else{
                    returnMessage = responseForANHL.returnStatus;
                }
            }

            ////////  FL /////////////
            if(returnMessage == 'Success' && inputMapFL.containsKey('productName') && inputMapFL.get('productName') == 'Flexi Loan'){
               responseForFL = initiateAPIRequestProductWise(inputMapFL, oppList, invocationType);
               integrationToInsert.add(responseForFL.intDetail);
                if(responseForFL.returnStatus == 'Success'){
                    loginFees = 0;
                    Decimal loginFeesPSV;
                    returnMessage = responseForFL.returnStatus;

                    //logic here
                     String productId = inputMapFL.get('productId');
                     Set<String> feeCodes = new Set<String>();
                     Map<String, Charges_Insurance__c> existingChargesMap = new Map<String, Charges_Insurance__c>();

                    // **Charge Creation Logic**
                    List<Charges_Insurance__c> chargeList = new List<Charges_Insurance__c>();
                    Map<String, Map<String, Object>> feeTypeToMasterDataMap = new Map<String, Map<String, Object>>();
                    
                    // **Query Charges_Insurance_Master__c Records**
                    List<Charges_Insurance_Master__c> chargesInsuranceMasterRecords = [
                        SELECT Id, Charges_Fee_Type__c, Tax__c, Category__c,Max_Percent__c,Min_Percent__c
                        FROM Charges_Insurance_Master__c
                        WHERE Category__c != 'LMS'
                    ];
                    
                    // **Map Master Records by Fee Type**
                    for (Charges_Insurance_Master__c master : chargesInsuranceMasterRecords) {
                        Map<String, Object> masterData = new Map<String, Object>();
                        masterData.put('MasterId', master.Id);
                        masterData.put('Tax', master.Tax__c != null ? master.Tax__c : 0); // Default tax to 0 if null
                        masterData.put('Category',master.Category__c != null ? master.Category__c:'');
                        masterData.put('MinPercent',master.Min_Percent__c != null ? master.Min_Percent__c:0);
                        masterData.put('MaxPercent',master.Max_Percent__c != null ? master.Max_Percent__c:0);
                        feeTypeToMasterDataMap.put(master.Charges_Fee_Type__c, masterData);
                    }
                    
                    // **Process API Fees & Update Total Charges**
                    //Map<Id, Charges_Insurance__c> updatedParentChargeMap = new Map<Id, Charges_Insurance__c>();
                    
                    for (Opportunity opp : oppList) {  
                        System.debug('Processing LOS Charges for Opportunity: ' + opp.Id);
                        
                        for (Fee fee : responseForFL.fees) {
                            feeCodes.add(fee.feeCode);
                        }
                        
                        for (Charges_Insurance__c ci : [
                            SELECT Id,Name,Stage__c,Allocated_Amount__c,Requested_Amount_INR__c,Balance_Fees__c,Balance_Login_Fees__c,Login_Fees__c, Charges_Fee_Type__c,Paid_Orginal__c
                            FROM Charges_Insurance__c
                            WHERE Loan_Application__c = :opp.Id
                            AND Charges_Fee_Type__c IN :feeCodes AND Product__c = :productId
                        ]) {
                            existingChargesMap.put(ci.Charges_Fee_Type__c, ci);
                        }
                        
                        if (responseForFL != null && responseForFL.fees != null) {
                            System.debug('Fees Found FL: ' + responseForFL.fees);
                            Charges_Insurance__c newCharge= new Charges_Insurance__c();
                            for (Fee fee : responseForFL.fees) {            
                                if(stageName == 'Sales Login' || stageName == 'PSV' || stageName == 'Disbursement'){           
                                    if (existingChargesMap.containsKey(fee.feeCode)) {
                                        System.debug('line 289--->>');
                                        newCharge = existingChargesMap.get(fee.feeCode);
                                            newCharge.Allocated_Amount__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        newCharge.Default_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        //newCharge.Requested_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        
                                    } else {      
                                        newCharge = new Charges_Insurance__c();
                                        newCharge.Name = fee.feeCode;
                                        newCharge.Fee_Method__c = fee.feeMethod;
                                        //newCharge.Charges_Insurance__c = parentCharge.Id;
                                        newCharge.Charges_Fee_Type__c = fee.feeCode;
                                        system.debug('line 256-->>'+ newCharge.Charges_Fee_Type__c);
                                        newCharge.Loan_Application__c = opp.Id;
                                        newCharge.Default_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        //newCharge.Requested_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        //newCharge.Category__c = 'LOS';
                                        newCharge.RecordTypeID = chargeRecordType;
                                        newCharge.Product__c = productId;
                                        newCharge.Stage__c = stageName;
                                        //newCharge.Allocation__c = (requestedAmount) / (Utility.truncateTwoZeros(fee.feeAmount)) * 100;
                                        Login_Fees__mdt mapping = Login_Fees__mdt.getInstance(fee.feeCode);
                                        if (mapping != null) {
                                                newCharge.Priority__c = mapping.Priority__c;
                                            }
                                        newCharge.GST_Exempt__c = 'E';
                                        
                                        /*if(fee.feeCode == 'PROCFEE'){
                                            newCharge.Priority__c = 1;
                                        }
                                        else if(fee.feeCode == 'STFRCHG'){
                                            newCharge.Priority__c = 3;
                                        }*/
                                        newCharge.Allocated_Amount__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        if(loginFees!=null){
                                        newCharge.Login_Fees__c = loginFees;
                                        }   
                                    }
                                }
                                    
                                Decimal taxPercentage = 0; // Default to 0%
                                Decimal taxAmount = 0;      // Calculated tax amount
                                
                                // **Tag the Master Record ID based on Fee Type**
                                if (feeTypeToMasterDataMap.containsKey(fee.feeCode)) {
                                    Map<String, Object> masterData = feeTypeToMasterDataMap.get(fee.feeCode);
                                    newCharge.Charges_Insurance_Master__c = (Id) masterData.get('MasterId');
                                    newCharge.Tax__c = (Decimal) masterData.get('Tax');
                                    newCharge.Category__c = (String) masterData.get('Category');
                                    newCharge.Min_Percent__c = (Decimal) masterData.get('MinPercent');
                                    newCharge.Max_Percent__c = (Decimal) masterData.get('MaxPercent');
                                    taxPercentage = (Decimal) masterData.get('Tax'); 
                                } else {
                                    newCharge.Tax__c = 0;
                                }
                                // **Calculate Tax Amount (Tax % of Fee Amount)**
                                /*if (taxPercentage > 0 && Utility.truncateTwoZeros(fee.feeAmount) != null) {
                                taxAmount = (Utility.truncateTwoZeros(fee.feeAmount) * taxPercentage) / 100;
                                    }

                                newCharge.Final_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount) + taxAmount;*/
                                if (taxPercentage > 0 && Utility.truncateTwoZeros(fee.feeAmount) != null) {
                                    Decimal rawTaxAmount = (Utility.truncateTwoZeros(fee.feeAmount) * taxPercentage) / 100;
                                    Decimal decimalPart = rawTaxAmount - Math.floor(rawTaxAmount);
                                    taxAmount = decimalPart < 0.5 ? Math.floor(rawTaxAmount) : Math.ceil(rawTaxAmount);
                                }
                                
                                newCharge.Final_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount) + taxAmount;
                                newCharge.Tax_INR__c = 0;
                                
                                chargeList.add(newCharge);
                                
                                // **Update Parent Charge Totals (Including Tax)**
                                Decimal totalChargeAmount = (Utility.truncateTwoZeros(fee.feeAmount) != null ? Utility.truncateTwoZeros(fee.feeAmount) : 0) + taxAmount;
                                
                                totalChargeAmountFL += totalChargeAmount;

                                // parentCharge.Total_Charges__c += totalChargeAmount;
                                // parentCharge.Total_Fee_to_be_deducted__c += totalChargeAmount;
                                // updatedParentChargeMap.put(parentCharge.Id, parentCharge);
                            }
                            
                          
                            chargeList.sort(new ChargePriorityComparator());
                            
                            for (Charges_Insurance__c newChargee : chargeList) {
                                if(stageName == 'Sales login'){
                                newChargee.Requested_Amount_INR__c =  newChargee.Allocated_Amount__c;
                                }
                                else{
                                        //for non-sales
                                    if(existingChargesMap.containsKey(newChargee.Name)){
                                        loginFeesPSV = existingChargesMap.get(newChargee.Name).Paid_Orginal__c != null ? existingChargesMap.get(newChargee.Name).Paid_Orginal__c : 0 ;
                                    }
                                    else{
                                        loginFeesPSV = 0;
                                    }
                                    decimal remainingloginfeePSV = loginFeesPSV;
                                    decimal adjustedLoginFeePSV = loginFeesPSV;
                                
                                        if(newChargee.name == 'PROCFEE'){
                                            newChargee.Login_Fees__c = loginFeesPSV;
                                        }
        
                                        if(loginFeesPSV!=null){
                                        if (newChargee.Allocated_Amount__c > loginFeesPSV) {
                                            
                                            newChargee.Balance_Charge_Amount__c = newChargee.Allocated_Amount__c - loginFeesPSV;
                                            newChargee.Requested_Amount_INR__c =  newChargee.Balance_Charge_Amount__c;
                                            newChargee.Balance_Fees__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Final_Amount_INR__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Balance_Login_Fees__c = 0;
                                            newChargee.Adjusted_Login_Fee__c = adjustedLoginFeePSV;
                                            loginFeesPSV = 0; 
                                            
                                            if(newChargee.name == 'PROCFEE'){
                                                
                                                remainingloginfeePSV =newChargee.Balance_Login_Fees__c;
                                                adjustedLoginFeePSV = newChargee.Balance_Login_Fees__c ;
                                            }
                                            if(newChargee.name != 'PROCFEE'){
                                                newChargee.Login_Fees__c = remainingloginfeePSV;
                                            }
                                            system.debug('line 409--'+newChargee.Login_Fees__c);
                                            system.debug('line 410--'+newCharge.Allocated_Amount__c);
                                            
                                            
                                        } else {
                                            
                                            newChargee.Balance_Charge_Amount__c = 0;
                                            newChargee.Balance_Login_Fees__c = loginFeesPSV - newChargee.Allocated_Amount__c;
                                            newChargee.Requested_Amount_INR__c =  newChargee.Balance_Login_Fees__c;
                                            newChargee.Balance_Fees__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Final_Amount_INR__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Adjusted_Login_Fee__c  = newChargee.Allocated_Amount__c;
                                            if(newChargee.name == 'PROCFEE'){   
                                                remainingloginfeePSV = newChargee.Balance_Login_Fees__c;
                                                adjustedLoginFeePSV = loginFeesPSV - newChargee.Allocated_Amount__c;
                                            }
                                            
                                            loginFeesPSV -= newChargee.Allocated_Amount__c;
                                            
                                            if(newChargee.name == 'STFRCHG'){
                                                newChargee.Login_Fees__c = remainingloginfeePSV;     
                                            }                            
                                        }
                                    } 
                                    }
                            }
                            
                        }
                    }
                        
                    if (!chargeList.isEmpty()) {
                        flChargeListToUpsert.addAll(chargeList);
                    }
                
                    // **Charge Creation Logic**
                }
                else{
                    returnMessage = responseForFL.returnStatus;
                }
            }
            //Hl-Ishi-11/10/2025
             ////////  Home Loan /////////////
            if(returnMessage == 'Success' && inputMapHL.containsKey('productName') && inputMapHL.get('productName') == 'Home Loan'){
               //responseForHL = initiateAPIRequestProductWise(inputMapHL, oppList, invocationType);
               responseForHL = new MultiproductChargesResponseWrapper(); 
               responseForHL.returnStatus = 'Success';
                // Fees
                Fee fee1 = new Fee();
                fee1.feeAmount = 200000;
                fee1.feeBalance = 0;
                fee1.feeCategory = 'FC';
                fee1.feeCode = 'STFRCHG';
                fee1.feeMethod = 'DISB';
                fee1.paidAmount = 200000;
                fee1.paymentID = null;
                fee1.scheduleTerms = 0;
                fee1.version = 0;
                fee1.waiverAmount = 0;
                fee1.finFeeReceipts = new List<FinFeeReceipt>();

                Fee fee2 = new Fee();
                fee2.feeAmount = 10000000;
                fee2.feeBalance = 0;
                fee2.feeCategory = 'FC';
                fee2.feeCode = 'PROCFEE';
                fee2.feeMethod = 'DISB';
                fee2.paidAmount = 10000000;
                fee2.paymentID = null;
                fee2.scheduleTerms = 0;
                fee2.version = 0;
                fee2.waiverAmount = 0;
                fee2.finFeeReceipts = new List<FinFeeReceipt>();

                responseForHL.fees = new List<Fee>{
                    fee1,
                    fee2
                };

                // Integration Detail
                responseForHL.intDetail = new Integration_Details__c(
                    Calling_Source__c = 'Loan Scheduler Create Charges',
                    Request_JSON__c = '{"step":[]}',
                    Response_JSON__c =
                        '[{"waiverAmount":0,"version":0,"scheduleTerms":0,"paymentID":null,"paidAmount":200000,' +
                        '"finFeeReceipts":[],"feeMethod":"DISB","feeCode":"STFRCHG","feeCategory":"FC",' +
                        '"feeBalance":0,"feeAmount":200000},' +
                        '{"waiverAmount":0,"version":0,"scheduleTerms":0,"paymentID":null,"paidAmount":10000000,' +
                        '"finFeeReceipts":[],"feeMethod":"DISB","feeCode":"PROCFEE","feeCategory":"FC",' +
                        '"feeBalance":0,"feeAmount":10000000}]',
                    Comments__c = 'Charges API Invocation',
                    Status__c = '200',
                    Method_Type__c = 'POST',
                    Endpoint__c = 'Callout:Create_Schedule_Simulation_API_LOS',
                    Name = 'Loan Scheduler Create Charges',
                    Loan_Application__c = oppList[0].Id, // replace with actual Id
                    Is_Success_Response__c = true,
                    Object_Name__c = 'Document_Details__c'
                );

               System.debug('responseForHL =>'+responseForHL);
               integrationToInsert.add(responseForHL.intDetail);
                if(responseForHL.returnStatus == 'Success'){
                    loginFees = 0;
                    Decimal loginFeesPSV;
                    returnMessage = responseForHL.returnStatus;

                    //logic here
                     String productId = inputMapHL.get('productId');
                     Set<String> feeCodes = new Set<String>();
                     Map<String, Charges_Insurance__c> existingChargesMap = new Map<String, Charges_Insurance__c>();

                    // **Charge Creation Logic**
                    List<Charges_Insurance__c> chargeList = new List<Charges_Insurance__c>();
                    Map<String, Map<String, Object>> feeTypeToMasterDataMap = new Map<String, Map<String, Object>>();
                    
                    // **Query Charges_Insurance_Master__c Records**
                    List<Charges_Insurance_Master__c> chargesInsuranceMasterRecords = [
                        SELECT Id, Charges_Fee_Type__c, Tax__c, Category__c,Max_Percent__c,Min_Percent__c
                        FROM Charges_Insurance_Master__c
                        WHERE Category__c != 'LMS'
                    ];
                    
                    // **Map Master Records by Fee Type**
                    for (Charges_Insurance_Master__c master : chargesInsuranceMasterRecords) {
                        Map<String, Object> masterData = new Map<String, Object>();
                        masterData.put('MasterId', master.Id);
                        masterData.put('Tax', master.Tax__c != null ? master.Tax__c : 0); // Default tax to 0 if null
                        masterData.put('Category',master.Category__c != null ? master.Category__c:'');
                        masterData.put('MinPercent',master.Min_Percent__c != null ? master.Min_Percent__c:0);
                        masterData.put('MaxPercent',master.Max_Percent__c != null ? master.Max_Percent__c:0);
                        feeTypeToMasterDataMap.put(master.Charges_Fee_Type__c, masterData);
                    }
                    
                    // **Process API Fees & Update Total Charges**
                    //Map<Id, Charges_Insurance__c> updatedParentChargeMap = new Map<Id, Charges_Insurance__c>();
                    
                    for (Opportunity opp : oppList) {  
                        System.debug('Processing LOS Charges for Opportunity: ' + opp.Id);
                        
                        for (Fee fee : responseForHL.fees) {
                            feeCodes.add(fee.feeCode);
                        }
                        
                        for (Charges_Insurance__c ci : [
                            SELECT Id,Name,Stage__c,Allocated_Amount__c,Requested_Amount_INR__c,Balance_Fees__c,Balance_Login_Fees__c,Login_Fees__c, Charges_Fee_Type__c,Paid_Orginal__c
                            FROM Charges_Insurance__c
                            WHERE Loan_Application__c = :opp.Id
                            AND Charges_Fee_Type__c IN :feeCodes AND Product__c = :productId
                        ]) {
                            existingChargesMap.put(ci.Charges_Fee_Type__c, ci);
                        }
                        
                        if (responseForHL != null && responseForHL.fees != null) {
                            System.debug('Fees Found FL: ' + responseForHL.fees);
                            Charges_Insurance__c newCharge;
                            for (Fee fee : responseForHL.fees) {            
                                if(stageName == 'Sales Login' || stageName == 'PSV' || stageName == 'Disbursement'){           
                                    if (existingChargesMap.containsKey(fee.feeCode)) {
                                        System.debug('line 289--->>');
                                        newCharge = existingChargesMap.get(fee.feeCode);
                                        newCharge.Allocated_Amount__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        newCharge.Default_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        //newCharge.Requested_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        
                                    } else {      
                                        newCharge = new Charges_Insurance__c();
                                        newCharge.Name = fee.feeCode;
                                        newCharge.Fee_Method__c = fee.feeMethod;
                                        //newCharge.Charges_Insurance__c = parentCharge.Id;
                                        newCharge.Charges_Fee_Type__c = fee.feeCode;
                                        system.debug('line 256-->>'+ newCharge.Charges_Fee_Type__c);
                                        newCharge.Loan_Application__c = opp.Id;
                                        newCharge.Default_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        //newCharge.Requested_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        //newCharge.Category__c = 'LOS';
                                        newCharge.RecordTypeID = chargeRecordType;
                                        newCharge.Product__c = productId;
                                        newCharge.Stage__c = stageName;
                                        //newCharge.Allocation__c = (requestedAmount) / (Utility.truncateTwoZeros(fee.feeAmount)) * 100;
                                        Login_Fees__mdt mapping = Login_Fees__mdt.getInstance(fee.feeCode);
                                        if (mapping != null) {
                                                newCharge.Priority__c = mapping.Priority__c;
                                            }
                                        newCharge.GST_Exempt__c = 'E';
                                        
                                        /*if(fee.feeCode == 'PROCFEE'){
                                            newCharge.Priority__c = 1;
                                        }
                                        else if(fee.feeCode == 'STFRCHG'){
                                            newCharge.Priority__c = 3;
                                        }*/
                                        newCharge.Allocated_Amount__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        if(loginFees!=null){
                                        newCharge.Login_Fees__c = loginFees;
                                        }   
                                    }
                                }
                                    
                                Decimal taxPercentage = 0; // Default to 0%
                                Decimal taxAmount = 0;      // Calculated tax amount
                                
                                // **Tag the Master Record ID based on Fee Type**
                                if (feeTypeToMasterDataMap.containsKey(fee.feeCode)) {
                                    Map<String, Object> masterData = feeTypeToMasterDataMap.get(fee.feeCode);
                                    newCharge.Charges_Insurance_Master__c = (Id) masterData.get('MasterId');
                                    newCharge.Tax__c = (Decimal) masterData.get('Tax');
                                    newCharge.Category__c = (String) masterData.get('Category');
                                    newCharge.Min_Percent__c = (Decimal) masterData.get('MinPercent');
                                    newCharge.Max_Percent__c = (Decimal) masterData.get('MaxPercent');
                                    taxPercentage = (Decimal) masterData.get('Tax'); 
                                } else {
                                    newCharge.Tax__c = 0;
                                }
                                // **Calculate Tax Amount (Tax % of Fee Amount)**
                                /*if (taxPercentage > 0 && Utility.truncateTwoZeros(fee.feeAmount) != null) {
                                taxAmount = (Utility.truncateTwoZeros(fee.feeAmount) * taxPercentage) / 100;
                                    }

                                newCharge.Final_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount) + taxAmount;*/
                                if (taxPercentage > 0 && Utility.truncateTwoZeros(fee.feeAmount) != null) {
                                    Decimal rawTaxAmount = (Utility.truncateTwoZeros(fee.feeAmount) * taxPercentage) / 100;
                                    Decimal decimalPart = rawTaxAmount - Math.floor(rawTaxAmount);
                                    taxAmount = decimalPart < 0.5 ? Math.floor(rawTaxAmount) : Math.ceil(rawTaxAmount);
                                }
                                
                                newCharge.Final_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount) + taxAmount;
                                newCharge.Tax_INR__c = 0;
                                
                                chargeList.add(newCharge);
                                
                                // **Update Parent Charge Totals (Including Tax)**
                                Decimal totalChargeAmount = (Utility.truncateTwoZeros(fee.feeAmount) != null ? Utility.truncateTwoZeros(fee.feeAmount) : 0) + taxAmount;
                                
                                totalChargeAmountHL += totalChargeAmount;

                                // parentCharge.Total_Charges__c += totalChargeAmount;
                                // parentCharge.Total_Fee_to_be_deducted__c += totalChargeAmount;
                                // updatedParentChargeMap.put(parentCharge.Id, parentCharge);
                            }
                            
                            chargeList.sort(new ChargePriorityComparator());
                            for (Charges_Insurance__c newChargee : chargeList) {
                                if(stageName == 'Sales login'){
                                newChargee.Requested_Amount_INR__c =  newChargee.Allocated_Amount__c;
                                }
                                else{
                                        //for non-sales
                                    if(existingChargesMap.containsKey(newChargee.Name)){
                                        loginFeesPSV = existingChargesMap.get(newChargee.Name).Paid_Orginal__c != null ? existingChargesMap.get(newChargee.Name).Paid_Orginal__c : 0 ;
                                    }
                                    else{
                                        loginFeesPSV = 0;
                                    }
                                    decimal remainingloginfeePSV = loginFeesPSV;
                                    decimal adjustedLoginFeePSV = loginFeesPSV;
                                
                                        if(newChargee.name == 'PROCFEE'){
                                            newChargee.Login_Fees__c = loginFeesPSV;
                                        }
        
                                        if(loginFeesPSV!=null){
                                        if (newChargee.Allocated_Amount__c > loginFeesPSV) {
                                            
                                            newChargee.Balance_Charge_Amount__c = newChargee.Allocated_Amount__c - loginFeesPSV;
                                            newChargee.Requested_Amount_INR__c =  newChargee.Balance_Charge_Amount__c;
                                            newChargee.Balance_Fees__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Final_Amount_INR__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Balance_Login_Fees__c = 0;
                                            newChargee.Adjusted_Login_Fee__c = adjustedLoginFeePSV;
                                            loginFeesPSV = 0; 
                                            
                                            if(newChargee.name == 'PROCFEE'){
                                                
                                                remainingloginfeePSV =newChargee.Balance_Login_Fees__c;
                                                adjustedLoginFeePSV = newChargee.Balance_Login_Fees__c ;
                                            }
                                            if(newChargee.name != 'PROCFEE'){
                                                newChargee.Login_Fees__c = remainingloginfeePSV;
                                            }
                                            system.debug('line 409--'+newChargee.Login_Fees__c);
                                            system.debug('line 410--'+newCharge.Allocated_Amount__c);
                                            
                                            
                                        } else {
                                            
                                            newChargee.Balance_Charge_Amount__c = 0;
                                            newChargee.Balance_Login_Fees__c = loginFeesPSV - newChargee.Allocated_Amount__c;
                                            newChargee.Requested_Amount_INR__c =  newChargee.Balance_Login_Fees__c;
                                            newChargee.Balance_Fees__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Final_Amount_INR__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Adjusted_Login_Fee__c  = newChargee.Allocated_Amount__c;
                                            if(newChargee.name == 'PROCFEE'){   
                                                remainingloginfeePSV = newChargee.Balance_Login_Fees__c;
                                                adjustedLoginFeePSV = loginFeesPSV - newChargee.Allocated_Amount__c;
                                            }
                                            
                                            loginFeesPSV -= newChargee.Allocated_Amount__c;
                                            
                                            if(newChargee.name == 'STFRCHG'){
                                                newChargee.Login_Fees__c = remainingloginfeePSV;     
                                            }                            
                                        }
                                    } 
                                    }
                            }
                            
                        }
                    }
                        
                    if (!chargeList.isEmpty()) {
                        hlChargeListToUpsert.addAll(chargeList);
                    }
                
                    // **Charge Creation Logic**
                }
                else{
                    returnMessage = responseForHL.returnStatus;
                }
            }
            //Hl-Ishi-11/10/2025
            //Hl-Prachi-
             ////////  Non Home Loan /////////////
            if(returnMessage == 'Success' && inputMapNHL.containsKey('productName') && inputMapNHL.get('productName') == 'Non Home Loan'){
               responseForNHL = initiateAPIRequestProductWise(inputMapNHL, oppList, invocationType);
               system.debug('responseForNHL---'+responseForNHL);
               integrationToInsert.add(responseForNHL.intDetail);
                if(responseForNHL.returnStatus == 'Success'){
                    loginFees = 0;
                    Decimal loginFeesPSV;
                    returnMessage = responseForNHL.returnStatus;

                    //logic here
                     String productId = inputMapNHL.get('productId');
                     Set<String> feeCodes = new Set<String>();
                     Map<String, Charges_Insurance__c> existingChargesMap = new Map<String, Charges_Insurance__c>();

                    // **Charge Creation Logic**
                    List<Charges_Insurance__c> chargeList = new List<Charges_Insurance__c>();
                    Map<String, Map<String, Object>> feeTypeToMasterDataMap = new Map<String, Map<String, Object>>();
                    
                    // **Query Charges_Insurance_Master__c Records**
                    List<Charges_Insurance_Master__c> chargesInsuranceMasterRecords = [
                        SELECT Id, Charges_Fee_Type__c, Tax__c, Category__c,Max_Percent__c,Min_Percent__c
                        FROM Charges_Insurance_Master__c
                        WHERE Category__c != 'LMS'
                    ];
                    
                    // **Map Master Records by Fee Type**
                    for (Charges_Insurance_Master__c master : chargesInsuranceMasterRecords) {
                        Map<String, Object> masterData = new Map<String, Object>();
                        masterData.put('MasterId', master.Id);
                        masterData.put('Tax', master.Tax__c != null ? master.Tax__c : 0); // Default tax to 0 if null
                        masterData.put('Category',master.Category__c != null ? master.Category__c:'');
                        masterData.put('MinPercent',master.Min_Percent__c != null ? master.Min_Percent__c:0);
                        masterData.put('MaxPercent',master.Max_Percent__c != null ? master.Max_Percent__c:0);
                        feeTypeToMasterDataMap.put(master.Charges_Fee_Type__c, masterData);
                    }
                    
                    // **Process API Fees & Update Total Charges**
                    //Map<Id, Charges_Insurance__c> updatedParentChargeMap = new Map<Id, Charges_Insurance__c>();
                    
                    for (Opportunity opp : oppList) {  
                        System.debug('Processing LOS Charges for Opportunity: ' + opp.Id);
                        
                        for (Fee fee : responseForNHL.fees) {
                            feeCodes.add(fee.feeCode);
                        }
                        
                        for (Charges_Insurance__c ci : [
                            SELECT Id,Name,Stage__c,Allocated_Amount__c,Requested_Amount_INR__c,Balance_Fees__c,Balance_Login_Fees__c,Login_Fees__c, Charges_Fee_Type__c,Paid_Orginal__c
                            FROM Charges_Insurance__c
                            WHERE Loan_Application__c = :opp.Id
                            AND Charges_Fee_Type__c IN :feeCodes AND Product__c = :productId
                        ]) {
                            existingChargesMap.put(ci.Charges_Fee_Type__c, ci);
                        }
                        
                        if (responseForNHL != null && responseForNHL.fees != null) {
                            System.debug('Fees Found FL: ' + responseForNHL.fees);
                            Charges_Insurance__c newCharge;
                            for (Fee fee : responseForNHL.fees) {            
                                if(stageName == 'Sales Login' || stageName == 'PSV' || stageName == 'Disbursement'){           
                                    if (existingChargesMap.containsKey(fee.feeCode)) {
                                        System.debug('line 289--->>');
                                        newCharge = existingChargesMap.get(fee.feeCode);
                                        newCharge.Allocated_Amount__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        newCharge.Default_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        //newCharge.Requested_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        
                                    } else {      
                                        newCharge = new Charges_Insurance__c();
                                        newCharge.Name = fee.feeCode;
                                        newCharge.Fee_Method__c = fee.feeMethod;
                                        //newCharge.Charges_Insurance__c = parentCharge.Id;
                                        newCharge.Charges_Fee_Type__c = fee.feeCode;
                                        system.debug('line 256-->>'+ newCharge.Charges_Fee_Type__c);
                                        newCharge.Loan_Application__c = opp.Id;
                                        newCharge.Default_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        //newCharge.Requested_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        //newCharge.Category__c = 'LOS';
                                        newCharge.RecordTypeID = chargeRecordType;
                                        newCharge.Product__c = productId;
                                        newCharge.Stage__c = stageName;
                                        //newCharge.Allocation__c = (requestedAmount) / (Utility.truncateTwoZeros(fee.feeAmount)) * 100;
                                        Login_Fees__mdt mapping = Login_Fees__mdt.getInstance(fee.feeCode);
                                        if (mapping != null) {
                                                newCharge.Priority__c = mapping.Priority__c;
                                            }
                                        newCharge.GST_Exempt__c = 'E';
                                        
                                        /*if(fee.feeCode == 'PROCFEE'){
                                            newCharge.Priority__c = 1;
                                        }
                                        else if(fee.feeCode == 'STFRCHG'){
                                            newCharge.Priority__c = 3;
                                        }*/
                                        newCharge.Allocated_Amount__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        if(loginFees!=null){
                                        newCharge.Login_Fees__c = loginFees;
                                        }   
                                    }
                                }
                                    
                                Decimal taxPercentage = 0; // Default to 0%
                                Decimal taxAmount = 0;      // Calculated tax amount
                                
                                // **Tag the Master Record ID based on Fee Type**
                                if (feeTypeToMasterDataMap.containsKey(fee.feeCode)) {
                                    Map<String, Object> masterData = feeTypeToMasterDataMap.get(fee.feeCode);
                                    newCharge.Charges_Insurance_Master__c = (Id) masterData.get('MasterId');
                                    newCharge.Tax__c = (Decimal) masterData.get('Tax');
                                    newCharge.Category__c = (String) masterData.get('Category');
                                    newCharge.Min_Percent__c = (Decimal) masterData.get('MinPercent');
                                    newCharge.Max_Percent__c = (Decimal) masterData.get('MaxPercent');
                                    taxPercentage = (Decimal) masterData.get('Tax'); 
                                } else {
                                    newCharge.Tax__c = 0;
                                }
                                // **Calculate Tax Amount (Tax % of Fee Amount)**
                                /*if (taxPercentage > 0 && Utility.truncateTwoZeros(fee.feeAmount) != null) {
                                taxAmount = (Utility.truncateTwoZeros(fee.feeAmount) * taxPercentage) / 100;
                                    }

                                newCharge.Final_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount) + taxAmount;*/
                                if (taxPercentage > 0 && Utility.truncateTwoZeros(fee.feeAmount) != null) {
                                    Decimal rawTaxAmount = (Utility.truncateTwoZeros(fee.feeAmount) * taxPercentage) / 100;
                                    Decimal decimalPart = rawTaxAmount - Math.floor(rawTaxAmount);
                                    taxAmount = decimalPart < 0.5 ? Math.floor(rawTaxAmount) : Math.ceil(rawTaxAmount);
                                }
                                
                                newCharge.Final_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount) + taxAmount;
                                newCharge.Tax_INR__c = 0;
                                
                                chargeList.add(newCharge);
                                
                                // **Update Parent Charge Totals (Including Tax)**
                                Decimal totalChargeAmount = (Utility.truncateTwoZeros(fee.feeAmount) != null ? Utility.truncateTwoZeros(fee.feeAmount) : 0) + taxAmount;
                                
                                totalChargeAmountNHL += totalChargeAmount;

                                // parentCharge.Total_Charges__c += totalChargeAmount;
                                // parentCharge.Total_Fee_to_be_deducted__c += totalChargeAmount;
                                // updatedParentChargeMap.put(parentCharge.Id, parentCharge);
                            }
                            
                            chargeList.sort(new ChargePriorityComparator());
                            for (Charges_Insurance__c newChargee : chargeList) {
                                if(stageName == 'Sales login'){
                                newChargee.Requested_Amount_INR__c =  newChargee.Allocated_Amount__c;
                                }
                                else{
                                        //for non-sales
                                    if(existingChargesMap.containsKey(newChargee.Name)){
                                        loginFeesPSV = existingChargesMap.get(newChargee.Name).Paid_Orginal__c != null ? existingChargesMap.get(newChargee.Name).Paid_Orginal__c : 0 ;
                                    }
                                    else{
                                        loginFeesPSV = 0;
                                    }
                                    decimal remainingloginfeePSV = loginFeesPSV;
                                    decimal adjustedLoginFeePSV = loginFeesPSV;
                                
                                        if(newChargee.name == 'PROCFEE'){
                                            newChargee.Login_Fees__c = loginFeesPSV;
                                        }
        
                                        if(loginFeesPSV!=null){
                                        if (newChargee.Allocated_Amount__c > loginFeesPSV) {
                                            
                                            newChargee.Balance_Charge_Amount__c = newChargee.Allocated_Amount__c - loginFeesPSV;
                                            newChargee.Requested_Amount_INR__c =  newChargee.Balance_Charge_Amount__c;
                                            newChargee.Balance_Fees__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Final_Amount_INR__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Balance_Login_Fees__c = 0;
                                            newChargee.Adjusted_Login_Fee__c = adjustedLoginFeePSV;
                                            loginFeesPSV = 0; 
                                            
                                            if(newChargee.name == 'PROCFEE'){
                                                
                                                remainingloginfeePSV =newChargee.Balance_Login_Fees__c;
                                                adjustedLoginFeePSV = newChargee.Balance_Login_Fees__c ;
                                            }
                                            if(newChargee.name != 'PROCFEE'){
                                                newChargee.Login_Fees__c = remainingloginfeePSV;
                                            }
                                            system.debug('line 409--'+newChargee.Login_Fees__c);
                                            system.debug('line 410--'+newCharge.Allocated_Amount__c);
                                            
                                            
                                        } else {
                                            
                                            newChargee.Balance_Charge_Amount__c = 0;
                                            newChargee.Balance_Login_Fees__c = loginFeesPSV - newChargee.Allocated_Amount__c;
                                            newChargee.Requested_Amount_INR__c =  newChargee.Balance_Login_Fees__c;
                                            newChargee.Balance_Fees__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Final_Amount_INR__c =  newChargee.Requested_Amount_INR__c;
                                            newChargee.Adjusted_Login_Fee__c  = newChargee.Allocated_Amount__c;
                                            if(newChargee.name == 'PROCFEE'){   
                                                remainingloginfeePSV = newChargee.Balance_Login_Fees__c;
                                                adjustedLoginFeePSV = loginFeesPSV - newChargee.Allocated_Amount__c;
                                            }
                                            
                                            loginFeesPSV -= newChargee.Allocated_Amount__c;
                                            
                                            if(newChargee.name == 'STFRCHG'){
                                                newChargee.Login_Fees__c = remainingloginfeePSV;     
                                            }                            
                                        }
                                    } 
                                    }
                            }
                            
                        }
                    }
                        
                    if (!chargeList.isEmpty()) {
                        nhlChargeListToUpsert.addAll(chargeList);
                    }
                
                    // **Charge Creation Logic**
                }
                else{
                    returnMessage = responseForNHL.returnStatus;
                }
            }
            //Hl-Prachi-


            //If both AHL & ANHL & Fl API are success then upsert parent charge and chargelist
            if(returnMessage == 'Success'){
                //handling logic for parent charge record for AHL
                if(inputMap.containsKey('productName') && inputMap.get('productName') == 'Affordable Home Loan'){
                    Charges_Insurance__c parentChargeAHL= new Charges_Insurance__c();

                    List<Charges_Insurance__c> existingTotalChargesRecords = [
                            SELECT Id,name, Loan_Application__c,Loan_Application__r.StageName,Balance_Login_Fees__c,Loan_Application__r.Requested_Amount__c, Total_Charges__c,Requested_Amount_INR__c, Total_Fee_to_be_deducted__c
                            FROM Charges_Insurance__c
                            WHERE Loan_Application__c = :loanId AND Name = 'Total Charges' AND Product__c = :inputMap.get('productId')];

                    if(!existingTotalChargesRecords.isEmpty()){
                        parentChargeAHL = existingTotalChargesRecords[0];
                    }
                    else{
                        // **Create a New Total Charges Record**
                        Charges_Insurance__c parentCharge = new Charges_Insurance__c();
                        parentCharge.Name = 'Total Charges';
                        parentCharge.Loan_Application__c = loanId;
                        parentCharge.RecordTypeID = chargeRecordType;
                        parentCharge.Product__c = inputMap.get('productId');
                        parentCharge.Total_Charges__c = totalChargeAmountAHL;
                        parentCharge.Total_Fee_to_be_deducted__c = totalChargeAmountAHL;
                        
                        parentChargeListAHL.add(parentCharge);
                    }

                    if (!parentChargeListAHL.isEmpty()) {
                        System.debug('Inserting Parent Charge Records AHL: ' + parentChargeListAHL);
                        insert parentChargeListAHL;
                        parentChargeAHL = parentChargeListAHL[0];
                    }

                    for(Charges_Insurance__c chargeAHL : ahlChargeListToUpsert){
                    chargeAHL.Charges_Insurance__c = parentChargeAHL.Id;
                    }

                    consolidatedChargeListToUpsert.addAll(ahlChargeListToUpsert);

                    //Insert LMS charges for AHL
                    if(stageName != 'Sales Login'){
                        insertLMSChargesForMultiproduct(oppList,inputMap.get('productId'),inputMap.get('productName'));
                    }
                }

                //handling logic for parent charge record for AHL CHILD
                if(inputMapAHLChild.containsKey('productName') && inputMapAHLChild.get('productName') == 'Affordable Home Loan'){
                    Charges_Insurance__c parentChargeAHLChild= new Charges_Insurance__c();

                    List<Charges_Insurance__c> existingTotalChargesRecords = [
                            SELECT Id,name, Loan_Application__c,Loan_Application__r.StageName,Balance_Login_Fees__c,Loan_Application__r.Requested_Amount__c, Total_Charges__c,Requested_Amount_INR__c, Total_Fee_to_be_deducted__c
                            FROM Charges_Insurance__c
                            WHERE Loan_Application__c = :loanId AND Name = 'Total Charges' AND Product__c = :inputMapAHLChild.get('productId')];

                    if(!existingTotalChargesRecords.isEmpty()){
                        parentChargeAHLChild = existingTotalChargesRecords[0];
                    }
                    else{
                        // **Create a New Total Charges Record**
                        Charges_Insurance__c parentCharge = new Charges_Insurance__c();
                        parentCharge.Name = 'Total Charges';
                        parentCharge.Loan_Application__c = loanId;
                        parentCharge.RecordTypeID = chargeRecordType;
                        parentCharge.Product__c = inputMapAHLChild.get('productId');
                        parentCharge.Total_Charges__c = totalChargeAmountAHLChild;
                        parentCharge.Total_Fee_to_be_deducted__c = totalChargeAmountAHLChild;
                        
                        parentChargeListAHLChild.add(parentCharge);
                    }

                    if (!parentChargeListAHLChild.isEmpty()) {
                        System.debug('Inserting Parent Charge Records AHL Child: ' + parentChargeListAHLChild);
                        insert parentChargeListAHLChild;
                        parentChargeAHLChild = parentChargeListAHLChild[0];
                    }

                    for(Charges_Insurance__c chargeAHL : ahlChildChargeListToUpsert){
                    chargeAHL.Charges_Insurance__c = parentChargeAHLChild.Id;
                    }

                    consolidatedChargeListToUpsert.addAll(ahlChildChargeListToUpsert);
                }

                //handling logic for parent charge record for ANHL
                if(inputMapANHL.containsKey('productName') && inputMapANHL.get('productName') == 'Affordable Non-Home Loan'){

                    Charges_Insurance__c parentChargeANHL= new Charges_Insurance__c();
                    List<Charges_Insurance__c> existingTotalChargesRecordsANHL = [
                            SELECT Id,name, Loan_Application__c,Loan_Application__r.StageName,Balance_Login_Fees__c,Loan_Application__r.Requested_Amount__c, Total_Charges__c,Requested_Amount_INR__c, Total_Fee_to_be_deducted__c
                            FROM Charges_Insurance__c
                            WHERE Loan_Application__c = :loanId AND Name = 'Total Charges' AND Product__c = :inputMapANHL.get('productId')];

                    if(!existingTotalChargesRecordsANHL.isEmpty()){
                        parentChargeANHL = existingTotalChargesRecordsANHL[0];
                    }
                    else{
                        // **Create a New Total Charges Record**
                        Charges_Insurance__c parentCharge = new Charges_Insurance__c();
                        parentCharge.Name = 'Total Charges';
                        parentCharge.Loan_Application__c = loanId;
                        parentCharge.RecordTypeID = chargeRecordType;
                        parentCharge.Product__c = inputMapANHL.get('productId');
                        parentCharge.Total_Charges__c = totalChargeAmountANHL;
                        parentCharge.Total_Fee_to_be_deducted__c = totalChargeAmountANHL;
                        
                        parentChargeListANHL.add(parentCharge);
                    }

                    if (!parentChargeListANHL.isEmpty()) {
                        System.debug('Inserting Parent Charge Records FL: ' + parentChargeListANHL);
                        insert parentChargeListANHL;
                        parentChargeANHL = parentChargeListANHL[0];
                    }

                    for(Charges_Insurance__c chargeANHL : anhlChargeListToUpsert){
                        chargeANHL.Charges_Insurance__c = parentChargeANHL.Id;
                    }

                    consolidatedChargeListToUpsert.addAll(anhlChargeListToUpsert);
                }

                //handling logic for parent charge record for FL
                if(inputMapFL.containsKey('productName') && inputMapFL.get('productName') == 'Flexi Loan'){

                    Charges_Insurance__c parentChargeFL= new Charges_Insurance__c();
                    List<Charges_Insurance__c> existingTotalChargesRecordsFL = [
                            SELECT Id,name, Loan_Application__c,Loan_Application__r.StageName,Balance_Login_Fees__c,Loan_Application__r.Requested_Amount__c, Total_Charges__c,Requested_Amount_INR__c, Total_Fee_to_be_deducted__c
                            FROM Charges_Insurance__c
                            WHERE Loan_Application__c = :loanId AND Name = 'Total Charges' AND Product__c = :inputMapFL.get('productId')];

                    if(!existingTotalChargesRecordsFL.isEmpty()){
                        parentChargeFL = existingTotalChargesRecordsFL[0];
                    }
                    else{
                        // **Create a New Total Charges Record**
                        Charges_Insurance__c parentCharge = new Charges_Insurance__c();
                        parentCharge.Name = 'Total Charges';
                        parentCharge.Loan_Application__c = loanId;
                        parentCharge.RecordTypeID = chargeRecordType;
                        parentCharge.Product__c = inputMapFL.get('productId');
                        parentCharge.Total_Charges__c = totalChargeAmountFL;
                        parentCharge.Total_Fee_to_be_deducted__c = totalChargeAmountFL;
                        
                        parentChargeListFL.add(parentCharge);
                    }

                    if (!parentChargeListFL.isEmpty()) {
                        System.debug('Inserting Parent Charge Records FL: ' + parentChargeListFL);
                        insert parentChargeListFL;
                        parentChargeFL = parentChargeListFL[0];
                    }

                    for(Charges_Insurance__c chargeAHL : flChargeListToUpsert){
                    chargeAHL.Charges_Insurance__c = parentChargeFL.Id;
                    }

                    consolidatedChargeListToUpsert.addAll(flChargeListToUpsert);

                }
                //handling logic for parent charge record for HL-Ishi
                if(inputMapHL.containsKey('productName') && inputMapHL.get('productName') == 'Home Loan'){

                    Charges_Insurance__c parentChargeHL= new Charges_Insurance__c();
                    List<Charges_Insurance__c> existingTotalChargesRecordsHL = [
                            SELECT Id,name, Loan_Application__c,Loan_Application__r.StageName,Balance_Login_Fees__c,Loan_Application__r.Requested_Amount__c, Total_Charges__c,Requested_Amount_INR__c, Total_Fee_to_be_deducted__c
                            FROM Charges_Insurance__c
                            WHERE Loan_Application__c = :loanId AND Name = 'Total Charges' AND Product__c = :inputMapHL.get('productId')];

                    if(!existingTotalChargesRecordsHL.isEmpty()){
                        parentChargeHL = existingTotalChargesRecordsHL[0];
                    }
                    else{
                        // **Create a New Total Charges Record**
                        Charges_Insurance__c parentCharge = new Charges_Insurance__c();
                        parentCharge.Name = 'Total Charges';
                        parentCharge.Loan_Application__c = loanId;
                        parentCharge.RecordTypeID = chargeRecordType;
                        parentCharge.Product__c = inputMapHL.get('productId');
                        parentCharge.Total_Charges__c = totalChargeAmountHL;
                        parentCharge.Total_Fee_to_be_deducted__c = totalChargeAmountHL;
                        
                        parentChargeListHL.add(parentCharge);
                    }

                    if (!parentChargeListHL.isEmpty()) {
                        System.debug('Inserting Parent Charge Records FL: ' + parentChargeListHL);
                        insert parentChargeListHL;
                        parentChargeHL = parentChargeListHL[0];
                    }

                    for(Charges_Insurance__c chargeAHL : hlChargeListToUpsert){
                    chargeAHL.Charges_Insurance__c = parentChargeHL.Id;
                    }

                    consolidatedChargeListToUpsert.addAll(hlChargeListToUpsert);

                }
                //handling logic for parent charge record for HL-Ishi
                //handling logic for parent charge record for HL-Prachi
                if(inputMapNHL.containsKey('productName') && inputMapNHL.get('productName') == 'Non Home Loan'){

                    Charges_Insurance__c parentChargeNHL= new Charges_Insurance__c();
                    List<Charges_Insurance__c> existingTotalChargesRecordsNHL = [
                            SELECT Id,name, Loan_Application__c,Loan_Application__r.StageName,Balance_Login_Fees__c,Loan_Application__r.Requested_Amount__c, Total_Charges__c,Requested_Amount_INR__c, Total_Fee_to_be_deducted__c
                            FROM Charges_Insurance__c
                            WHERE Loan_Application__c = :loanId AND Name = 'Total Charges' AND Product__c = :inputMapNHL.get('productId')];

                    if(!existingTotalChargesRecordsNHL.isEmpty()){
                        parentChargeNHL = existingTotalChargesRecordsNHL[0];
                    }
                    else{
                        // **Create a New Total Charges Record**
                        Charges_Insurance__c parentCharge = new Charges_Insurance__c();
                        parentCharge.Name = 'Total Charges';
                        parentCharge.Loan_Application__c = loanId;
                        parentCharge.RecordTypeID = chargeRecordType;
                        parentCharge.Product__c = inputMapNHL.get('productId');
                        parentCharge.Total_Charges__c = totalChargeAmountNHL;
                        parentCharge.Total_Fee_to_be_deducted__c = totalChargeAmountNHL;
                        
                        parentChargeListNHL.add(parentCharge);
                    }

                    if (!parentChargeListNHL.isEmpty()) {
                        System.debug('Inserting Parent Charge Records FL: ' + parentChargeListNHL);
                        insert parentChargeListNHL;
                        parentChargeNHL = parentChargeListNHL[0];
                    }

                    for(Charges_Insurance__c chargeAHL : nhlChargeListToUpsert){
                    chargeAHL.Charges_Insurance__c = parentChargeNHL.Id;
                    }

                    consolidatedChargeListToUpsert.addAll(nhlChargeListToUpsert);

                }
                //handling logic for parent charge record for HL-Prachi
            }

            // all the consolidated DML for both AHL and FL will happen here
            if(!integrationToInsert.isEmpty()){
                System.debug('Inserting integrationToInsert: ' + integrationToInsert);
                insert integrationToInsert;
            }

            if(!consolidatedChargeListToUpsert.isEmpty()){
                System.debug('Inserting consolidatedChargeListToUpsert: ' + consolidatedChargeListToUpsert);
                if(System.Test.isrunningTest()){
                    upsert consolidatedChargeListToUpsert[0];
                }else {
                upsert consolidatedChargeListToUpsert;
                }

            }

            //delete the charges reocords where product is null
            chargesToDelete = [SELECT Id FROM Charges_Insurance__c WHERE Loan_Application__c = :loanId AND Name != 'Login fee' AND Product__c = null];
            if (!chargesToDelete.isEmpty()) delete chargesToDelete;

            return returnMessage;
        } catch (Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'COMM_LoanScheduler', '', '') });
            System.debug('Exception in COMM_LoanScheduler: ' + e.getMessage()+' line number: '+ e.getStackTraceString());
            throw new AuraHandledException('Salesforce Exception: ' + e.getMessage());
        }
    }

    public static void insertLMSChargesForMultiproduct(List<Opportunity> oppListForAPI, string productId, string productname){

       List<Charges_Insurance__c> chargeList = new List<Charges_Insurance__c>();

        if (!oppListForAPI.isEmpty()) {
            System.debug('Processing Opportunities for LMS charges: ' + oppListForAPI);
            
            // Step 2: Fetch Existing LMS Charges for the Opportunities
            Set<Id> oppIds = new Set<Id>();
            for (Opportunity opp : oppListForAPI) {
                oppIds.add(opp.Id);
            }

            Map<String, Set<Id>> existingChargeTypeVsOppIds = new Map<String, Set<Id>>();
            List<Charges_Insurance__c> existingCharges = [
                SELECT Id, Charges_Fee_Type__c, Loan_Application__c
                FROM Charges_Insurance__c
                WHERE Loan_Application__c IN :oppIds AND Category__c = 'LMS' AND Product_Name__c = :productname
            ];

            for (Charges_Insurance__c charge : existingCharges) {
                if (!existingChargeTypeVsOppIds.containsKey(charge.Charges_Fee_Type__c)) {
                    existingChargeTypeVsOppIds.put(charge.Charges_Fee_Type__c, new Set<Id>());
                }
                existingChargeTypeVsOppIds.get(charge.Charges_Fee_Type__c).add(charge.Loan_Application__c);
            }
            
            System.debug('Existing Charges Found: ' + existingChargeTypeVsOppIds);
            
            // Step 3: Fetch Related Product2 Records
            Product2 mainProduct =[SELECT Id from Product2 WHERE RecordType.Name = 'Product' AND Name = :productname AND Loan_Application__c IN :oppIds LIMIT 1];
            Product2 subProduct = [SELECT Id from Product2 WHERE RecordType.Name = 'Sub Product' AND Product__c =:mainProduct.Id AND Loan_Application__c IN :oppIds LIMIT 1];
            
            List<Product2> relatedProductRecords = [
                SELECT Id, Name, RecordType.Name, Loan_Application__c
                FROM Product2
                WHERE Loan_Application__c IN :oppIds AND RecordType.Name = 'Variant' AND Product__c = :subProduct.Id
            ];
            
            List<Product2> subVariant = [SELECT Id, Name, RecordType.Name, Loan_Application__c from Product2 WHERE RecordType.Name = 'Sub Variant' AND Variant__c =:relatedProductRecords[0].Id AND Loan_Application__c IN :oppIds LIMIT 1];

            Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.getGlobalDescribe()
                .get('Charges_Insurance__c')
                .getDescribe()
                .getRecordTypeInfosByName();
            Id chargesRecordTypeId = recordTypeMap.get('Charges').getRecordTypeId();
            Map<Id, Map<String, String>> oppIdVsProductRecords = new Map<Id, Map<String, String>>();
            
            for (Product2 prod : relatedProductRecords) {
                if (!oppIdVsProductRecords.containsKey(prod.Loan_Application__c)) {
                    oppIdVsProductRecords.put(prod.Loan_Application__c, new Map<String, String>());
                }
                oppIdVsProductRecords.get(prod.Loan_Application__c).put(prod.RecordType.Name, prod.Name);
            }

            if(!subVariant.isEmpty()){
                if (!oppIdVsProductRecords.containsKey(subVariant[0].Loan_Application__c)) {
                    oppIdVsProductRecords.put(subVariant[0].Loan_Application__c, new Map<String, String>());
                }
                oppIdVsProductRecords.get(subVariant[0].Loan_Application__c).put(subVariant[0].RecordType.Name, subVariant[0].Name);
            }
            //system.debug('oppIdVsProductRecords: '+ JSON.serialize(oppIdVsProductRecords));

            // Step 4: Fetch LMS Charge Types
            List<Charges_Insurance_Master__c> chargesInsuranceMasterRecords = [
                SELECT Id, Charges_Fee_Type__c, Default_Value__c, Category__c, 
                Sub_Product__c, Sub_Product__r.Product__c, Sub_Product__r.Product__r.Name,
                Sub_Product__r.Name,Max_Percent__c,Min_Percent__c, Sub_Variant__r.Name
                FROM Charges_Insurance_Master__c
                WHERE Category__c = 'LMS'
            ];

            // Step 5: Create LMS Charges if not already created
            for (Opportunity opp : oppListForAPI) {
                Map<String, String> productRecords = oppIdVsProductRecords.get(opp.Id);

                if (productRecords != null) {
                    for (Charges_Insurance_Master__c chargeInsuranceMaster : chargesInsuranceMasterRecords) {
                        //System.debug('chargeInsuranceMaster: '+chargeInsuranceMaster);
                        
                        String requiredSubProduct = chargeInsuranceMaster.Sub_Product__r.Name;
                        String requiredSubVariant = chargeInsuranceMaster.Sub_Variant__c != null ? chargeInsuranceMaster.Sub_Variant__r.Name : '';

                        String actualSubProduct = productRecords.get('Variant');
                        String actualSubVariant = productRecords.containsKey('Sub Variant') ? productRecords.get('Sub Variant') : '';

                        if ((actualSubProduct == requiredSubProduct && String.isBlank(requiredSubVariant)) || (String.isNotBlank(requiredSubVariant) && actualSubVariant == requiredSubVariant)) {
                            
                            Boolean chargeAlreadyExists = existingChargeTypeVsOppIds.containsKey(chargeInsuranceMaster.Charges_Fee_Type__c) &&
                                                        existingChargeTypeVsOppIds.get(chargeInsuranceMaster.Charges_Fee_Type__c).contains(opp.Id);
                            
                            if (!chargeAlreadyExists) {  // Only create if it doesn't exist
                                Charges_Insurance__c newLMSCharge = new Charges_Insurance__c();
                                newLMSCharge.Name = chargeInsuranceMaster.Charges_Fee_Type__c;
                                newLMSCharge.Charges_Fee_Type__c = chargeInsuranceMaster.Charges_Fee_Type__c;
                                newLMSCharge.Default_Percentage__c = chargeInsuranceMaster.Default_Value__c;
                                newLMSCharge.Requested_Percentage__c = chargeInsuranceMaster.Default_Value__c;
                                newLMSCharge.Final_Amount_INR__c = chargeInsuranceMaster.Default_Value__c;
                                newLMSCharge.Loan_Application__c = opp.Id;
                                newLMSCharge.Category__c = chargeInsuranceMaster.Category__c;
                                newLMSCharge.Max_Percent__c = chargeInsuranceMaster.Max_Percent__c;
                                newLMSCharge.Min_Percent__c = chargeInsuranceMaster.Min_Percent__c;
                                newLMSCharge.RecordTypeID = chargesRecordTypeId;
                                newLMSCharge.Product__c = productId;
                                chargeList.add(newLMSCharge);
                            }
                        }
                    }
                }
            }

            if (!chargeList.isEmpty()) {
                System.debug('Inserting New LMS Charges: ' + chargeList);
                insert chargeList;
            }
        }
    }

    @AuraEnabled
    public static MultiproductChargesResponseWrapper initiateAPIRequestProductWise(Map<String, String> inputMap, List<Opportunity> oppList, String invocationType) {
        try {
            String resultMessage;
            String returnResp;
            String loanId = inputMap.get('loanId');
            String processName = inputMap.get('processName');
            String sanctionLoanAmount = inputMap.get('sanctionLoanAmount');
            String sanctionLoanTenure = inputMap.get('sanctionLoanTenure');
            String productName = inputMap.get('productId');
            String returnText;

            if (String.isEmpty(loanId) || String.isEmpty(processName)) {
                throw new AuraHandledException('Error: Missing required parameters.');
            }
            if (String.isEmpty(sanctionLoanAmount)) {
                throw new AuraHandledException('Error: Missing required parameters.');
            }
            
            // Fetch Metadata
            Integration_Master__mdt metadata = [
                SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, Client_Id__c, 
                Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, Refresh_Allowed__c, Activity_Name__c
                FROM Integration_Master__mdt 
                WHERE Activity_Name__c = :processName 
                LIMIT 1
            ];
            
            if (metadata == null) {
                throw new AuraHandledException('Error: No metadata found for the given process.');
            }
            
            intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
            wrapper.recordId = loanId;
            wrapper.loanApplicationId = loanId;  
            wrapper.type = processName;
            wrapper.endpoint = metadata.Endpoint__c;
            wrapper.requestMethod = metadata.Request_Method__c;
            wrapper.clientId = metadata.Client_Id__c;
            wrapper.clientSecret = metadata.Client_Secret__c;
            wrapper.allowedRetry = metadata.Allowed_Retry__c;
            wrapper.gestationPeriod = metadata.Gestation_Period__c;
            wrapper.activityname = metadata.Activity_Name__c;
            wrapper.refreshallowed = metadata.Refresh_Allowed__c;
            wrapper.handlername = metadata.Handler_Class__c;
            wrapper.loanSchedulerInvocationType = invocationType;
            wrapper.sanctionLoanAmount = Decimal.valueOf(sanctionLoanAmount);
            wrapper.sanctionLoanTenure = sanctionLoanTenure!=null?Integer.valueOf(sanctionLoanTenure):0;
            wrapper.productName = productName;
            
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            MultiproductChargesResponseWrapper responseWrapper = new MultiproductChargesResponseWrapper();
            
            // Fetch Integration Settings
            Integration_Settings__c intSetting = [
                SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c,
                Authorization__c, Cookie__c
                FROM Integration_Settings__c 
                WHERE Name = :processName
                LIMIT 1
            ];
            if(System.Test.isRunningTest()){
                respWrapper.payload='respWrapper';
            }
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = '';
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');
                System.debug('resultMessage: '+resultMessage);
                returnResp = resultMessage;
                responseWrapper.returnStatus = returnResp;
                responseWrapper.intDetail = integrationDetail;
            }else {
                // Prepare API Request
                Map<String, String> integrationRequestMap = new Map<String, String>();
                integrationRequestMap.put('intSettingName', 'Loan Scheduler Create Charges');
                integrationRequestMap.put('requestJSON', respWrapper.payload);
                integrationRequestMap.put('endpoint',intSetting.Endpoint__c);
                integrationRequestMap.put('auth',intSetting.Authorization__c);
                integrationRequestMap.put('contentType',intSetting.Content_Type__c);
                integrationRequestMap.put('requestMethod',intSetting.Request_Method__c);
                integrationRequestMap.put('cookie',intSetting.Cookie__c);
                String bearer = Utility.getAccessToken();
                integrationRequestMap.put('bearer',bearer);
                System.debug('request map initial API   '+integrationRequestMap);
                // Make API Call
                HTTPResponse resp = executeRESTAPIRequest(integrationRequestMap, loanId);
                system.debug('line 845-->>'+resp);
                // Deserialize the actual API response
                LoanSchedulerCreateChargesResponseWrapper responseJSON = (LoanSchedulerCreateChargesResponseWrapper) 
                    JSON.deserialize(resp.getBody(), LoanSchedulerCreateChargesResponseWrapper.class);
                
                // Extract returnText
                if(responseJSON.returnStatus != null && responseJSON.returnStatus.returnText != null){
                    returnText = responseJSON.returnStatus.returnText;
                }else{
                    returnText = 'Some issue in API, empty return status';
                }
                responseWrapper.returnStatus = returnText;
                responseWrapper.fees = responseJSON.fees;
                
                Boolean isSuccessResponse = false;
                if(returnText == 'Success'){
                    isSuccessResponse = true;
                }
                
                // Save API Response in Integration_Details__c
                integrationDetail.Calling_Source__c = wrapper.type;
                integrationDetail.Request_JSON__c = respWrapper.payload;
                integrationDetail.Response_JSON__c = JSON.serialize(responseJSON.fees);
                integrationDetail.Comments__c = invocationType;
                integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                integrationDetail.Method_Type__c = intSetting.Request_Method__c;
                integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                integrationDetail.Name = processName;
                integrationDetail.Loan_Application__c = loanId;
                integrationDetail.Is_Success_Response__c = isSuccessResponse;
                integrationDetail.Object_Name__c = 'Document_Details__c';
                //integrationDetail.Related_Record_Id__c = checklist.Id;
                responseWrapper.intDetail = integrationDetail;
            } 
            
            return responseWrapper;
        } catch (Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'LoanScheduler', '', '') });
            //throw new AuraHandledException('Error: ' + e.getMessage() + e.getStackTraceString());
            System.debug('Exception in LoanScheduler product wise: ' + e.getMessage()+' line number: '+ e.getStackTraceString());
            throw new AuraHandledException('Salesforce Exception: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String initiateAPIRequest(Map<String, String> inputMap, List<Opportunity> oppList, String invocationType) {
        try {
            String resultMessage;
            String returnResp;
            String loanId = inputMap.get('loanId');
            String processName = inputMap.get('processName');

            String loginFeesStr;
            Decimal loginFees;
            Decimal loginFeesPSV;
            if (invocationType == 'Charges API Invocation' && inputMap.containsKey('loginFee') && inputMap.get('loginFee') != null) {
                loginFeesStr = inputMap.get('loginFee');
            } else {
            loginFeesStr = null; 
            }
            //String loginFeesStr = inputMap.get('loginFee');
            if(loginFeesStr!=null){
             loginFees  = Integer.valueOf(loginFeesStr);
            }
            //Decimal remainingLoginFee = loginFees;
            String stageName = inputMap.get('stageName');
            Set<String> feeCodes = new Set<String>();
            Map<String, Charges_Insurance__c> existingChargesMap = new Map<String, Charges_Insurance__c>();
            //Decimal requestedAmount = Integer.valueOf('requestedAmount'); 
            String returnText;
            List<Charges_Insurance__c> tempChargesList = new List<Charges_Insurance__c>();
            if (String.isEmpty(loanId) || String.isEmpty(processName)) {
                throw new AuraHandledException('Error: Missing required parameters.');
            }
            // if (invocationType == 'Charges API Invocation' && (String.isEmpty(productId) || String.isEmpty(sanctionLoanAmount))) {
            //     throw new AuraHandledException('Error: Missing required parameters.');
            // }
            
            // Fetch Metadata
            // Integration_Master__mdt metadata = [
            //     SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, Client_Id__c, 
            //     Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, Refresh_Allowed__c, Activity_Name__c
            //     FROM Integration_Master__mdt 
            //     WHERE Activity_Name__c = :processName 
            //     LIMIT 1
            // ];
            
            // if (metadata == null) {
            //     throw new AuraHandledException('Error: No metadata found for the given process.');
            // }
            
            intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
            wrapper.recordId = loanId;
            wrapper.loanApplicationId = loanId;  
            wrapper.type = processName;
            // wrapper.endpoint = metadata.Endpoint__c;
            // wrapper.requestMethod = metadata.Request_Method__c;
            // wrapper.clientId = metadata.Client_Id__c;
            // wrapper.clientSecret = metadata.Client_Secret__c;
            // wrapper.allowedRetry = metadata.Allowed_Retry__c;
            // wrapper.gestationPeriod = metadata.Gestation_Period__c;
            // wrapper.activityname = metadata.Activity_Name__c;
            // wrapper.refreshallowed = metadata.Refresh_Allowed__c;
            // wrapper.handlername = metadata.Handler_Class__c;
            wrapper.loanSchedulerInvocationType = invocationType;
            
            //intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            
            // if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
            //     return 'Error: ' + String.join(respWrapper.prerequisiteError, ', ');
            // }
            
            // // Fetch Integration Settings
            // Integration_Settings__c intSetting = [
            //     SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c,
            //     Authorization__c, Cookie__c
            //     FROM Integration_Settings__c 
            //     WHERE Name = :processName
            //     LIMIT 1
            // ];
            // if(System.Test.isRunningTest()){
            //     respWrapper.payload='respWrapper';
            // }
            // if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
            //     integrationDetail.Status__c = String.valueof('412');
            //     integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
            //     integrationDetail.Name = processName;
            //     integrationDetail.Object_Name__c = '';
            //     resultMessage =  String.join(respWrapper.prerequisiteError, ', ');
            //     System.debug('resultMessage: '+resultMessage);
            //     returnResp = resultMessage;
            // }else {
                // Prepare API Request
                // Map<String, String> integrationRequestMap = new Map<String, String>();
                // integrationRequestMap.put('intSettingName', 'Loan Scheduler Create Charges');
                // integrationRequestMap.put('requestJSON', respWrapper.payload);
                // integrationRequestMap.put('endpoint',intSetting.Endpoint__c);
                // integrationRequestMap.put('auth',intSetting.Authorization__c);
                // integrationRequestMap.put('contentType',intSetting.Content_Type__c);
                // integrationRequestMap.put('requestMethod',intSetting.Request_Method__c);
                // integrationRequestMap.put('cookie',intSetting.Cookie__c);
                // String bearer = Utility.getAccessToken();
                // integrationRequestMap.put('bearer',bearer);
                // System.debug('request map initial API   '+integrationRequestMap);
                // // Make API Call
                // HTTPResponse resp = executeRESTAPIRequest(integrationRequestMap, loanId);
                
                String apiResponse = '{"finReference":"GFL0000BL4137592","fees":[{"feeCategory":"FC","feeCode":"STFRCHG","netAmountOriginal":200000,"netAmountGST":0,"netAmount":200000,"paidAmountOriginal":0,"paidAmountGST":0,"paidAmount":200000,"feeBalance":0,"netTDS":0,"paidTDS":0,"remTDS":0,"waiverAmount":0,"feeMethod":"DISB","scheduleTerms":0,"version":0,"finFeeReceipts":[],"refundAmount":0,"feeAmount":200000},{"feeCategory":"FC","feeCode":"PROCFEE","netAmountOriginal":500000,"netAmountGST":0,"netAmount":500000,"paidAmountOriginal":0,"paidAmountGST":0,"paidAmount":500000,"feeBalance":0,"netTDS":0,"paidTDS":0,"remTDS":0,"waiverAmount":0,"feeMethod":"DISB","scheduleTerms":0,"version":0,"finFeeReceipts":[],"refundAmount":0,"feeAmount":500000},{"feeCategory":"FC","feeCode":"FWRFEE","netAmountOriginal":649900,"netAmountGST":0,"netAmount":649900,"paidAmountOriginal":0,"paidAmountGST":0,"paidAmount":649900,"feeBalance":0,"netTDS":0,"paidTDS":0,"remTDS":0,"waiverAmount":0,"feeMethod":"DISB","scheduleTerms":0,"version":0,"finFeeReceipts":[],"refundAmount":0,"feeAmount":649900}],"feeDues":[],"insurance":[],"step":[],"schedules":[{"schDate":"2049-04-24T00:00:00","pftAmount":0,"schdPft":0,"schdPftPaid":0,"schdPri":0,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":0,"endBal":340000000.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-04-24T00:00:00","version":0,"instNumber":0,"repayOnSchDate":false,"rvwOnSchDate":false,"disbOnSchDate":true,"bpiOrHoliday":"","frqDate":false,"balanceForPftCal":0,"calculatedRate":12.650000000,"profitBalance":0,"disbAmount":340000000.00,"cpzAmount":0,"specifier":"E","bpiAmount":0},{"schDate":"2049-05-03T00:00:00","pftAmount":1075300,"schdPft":0,"schdPftPaid":0,"schdPri":0,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":0,"endBal":340000000.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-05-03T00:00:00","version":0,"instNumber":0,"repayOnSchDate":false,"rvwOnSchDate":false,"disbOnSchDate":false,"bpiOrHoliday":"B","frqDate":true,"balanceForPftCal":340000000.00,"calculatedRate":12.650000000,"profitBalance":1075300,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":1075300},{"schDate":"2049-06-03T00:00:00","pftAmount":3584200,"schdPft":4659500,"schdPftPaid":0,"schdPri":4318200,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":8977700,"endBal":335681800.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-06-03T00:00:00","version":0,"instNumber":1,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":340000000.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2049-07-03T00:00:00","pftAmount":3916300,"schdPft":3916300,"schdPftPaid":0,"schdPri":3986100,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":331695700.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-07-03T00:00:00","version":0,"instNumber":2,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":335681800.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2049-08-03T00:00:00","pftAmount":3869700,"schdPft":3869700,"schdPftPaid":0,"schdPri":4032700,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":327663000.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-08-03T00:00:00","version":0,"instNumber":3,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":331695700.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2049-09-03T00:00:00","pftAmount":3822800,"schdPft":3822800,"schdPftPaid":0,"schdPri":4079600,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":323583400.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-09-03T00:00:00","version":0,"instNumber":4,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":327663000.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2049-10-03T00:00:00","pftAmount":3775100,"schdPft":3775100,"schdPftPaid":0,"schdPri":4127300,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":319456100.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-10-03T00:00:00","version":0,"instNumber":5,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":323583400.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2049-11-03T00:00:00","pftAmount":3727000,"schdPft":3727000,"schdPftPaid":0,"schdPri":4175400,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":315280700.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-11-03T00:00:00","version":0,"instNumber":6,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":319456100.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2049-12-03T00:00:00","pftAmount":3678300,"schdPft":3678300,"schdPftPaid":0,"schdPri":4224100,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":311056600.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2049-12-03T00:00:00","version":0,"instNumber":7,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":315280700.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2050-01-03T00:00:00","pftAmount":3629000,"schdPft":3629000,"schdPftPaid":0,"schdPri":4273400,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":306783200.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2050-01-03T00:00:00","version":0,"instNumber":8,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":311056600.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2050-02-03T00:00:00","pftAmount":3579100,"schdPft":3579100,"schdPftPaid":0,"schdPri":4323300,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":302459900.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2050-02-03T00:00:00","version":0,"instNumber":9,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":306783200.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2050-03-03T00:00:00","pftAmount":3528700,"schdPft":3528700,"schdPftPaid":0,"schdPri":4373700,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":298086200.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2050-03-03T00:00:00","version":0,"instNumber":10,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":302459900.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2050-04-03T00:00:00","pftAmount":3477700,"schdPft":3477700,"schdPftPaid":0,"schdPri":4424700,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":293661500.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2050-04-03T00:00:00","version":0,"instNumber":11,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":298086200.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2050-05-03T00:00:00","pftAmount":3426000,"schdPft":3426000,"schdPftPaid":0,"schdPri":4476400,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":289185100.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2050-05-03T00:00:00","version":0,"instNumber":12,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":293661500.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2050-06-03T00:00:00","pftAmount":3373900,"schdPft":3373900,"schdPftPaid":0,"schdPri":4528500,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":284656600.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2050-06-03T00:00:00","version":0,"instNumber":13,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":289185100.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2050-07-03T00:00:00","pftAmount":3320900,"schdPft":3320900,"schdPftPaid":0,"schdPri":4581500,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":280075100.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2050-07-03T00:00:00","version":0,"instNumber":14,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":284656600.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2050-08-03T00:00:00","pftAmount":3267600,"schdPft":3267600,"schdPftPaid":0,"schdPri":4634800,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":275440300.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2050-08-03T00:00:00","version":0,"instNumber":15,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":280075100.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2050-09-03T00:00:00","pftAmount":3213500,"schdPft":3213500,"schdPftPaid":0,"schdPri":4688900,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":270751400.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2050-09-03T00:00:00","version":0,"instNumber":16,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":275440300.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2050-10-03T00:00:00","pftAmount":3158700,"schdPft":3158700,"schdPftPaid":0,"schdPri":4743700,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":266007700.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2050-10-03T00:00:00","version":0,"instNumber":17,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":270751400.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2050-11-03T00:00:00","pftAmount":3103500,"schdPft":3103500,"schdPftPaid":0,"schdPri":4798900,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":261208800.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2050-11-03T00:00:00","version":0,"instNumber":18,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":266007700.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2050-12-03T00:00:00","pftAmount":3047400,"schdPft":3047400,"schdPftPaid":0,"schdPri":4855000,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":256353800.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2050-12-03T00:00:00","version":0,"instNumber":19,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":261208800.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2051-01-03T00:00:00","pftAmount":2990800,"schdPft":2990800,"schdPftPaid":0,"schdPri":4911600,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":251442200.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2051-01-03T00:00:00","version":0,"instNumber":20,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":256353800.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2051-02-03T00:00:00","pftAmount":2933500,"schdPft":2933500,"schdPftPaid":0,"schdPri":4968900,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":246473300.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2051-02-03T00:00:00","version":0,"instNumber":21,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":251442200.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2051-03-03T00:00:00","pftAmount":2875500,"schdPft":2875500,"schdPftPaid":0,"schdPri":5026900,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":241446400.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2051-03-03T00:00:00","version":0,"instNumber":22,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":246473300.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2051-04-03T00:00:00","pftAmount":2816900,"schdPft":2816900,"schdPftPaid":0,"schdPri":5085500,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":236360900.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2051-04-03T00:00:00","version":0,"instNumber":23,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":241446400.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2051-05-03T00:00:00","pftAmount":2757500,"schdPft":2757500,"schdPftPaid":0,"schdPri":5144900,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":231216000.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2051-05-03T00:00:00","version":0,"instNumber":24,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":236360900.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2051-06-03T00:00:00","pftAmount":2697500,"schdPft":2697500,"schdPftPaid":0,"schdPri":5204900,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":226011100.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2051-06-03T00:00:00","version":0,"instNumber":25,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":231216000.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2051-07-03T00:00:00","pftAmount":2636800,"schdPft":2636800,"schdPftPaid":0,"schdPri":5265600,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":220745500.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2051-07-03T00:00:00","version":0,"instNumber":26,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":226011100.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2051-08-03T00:00:00","pftAmount":2575400,"schdPft":2575400,"schdPftPaid":0,"schdPri":5327000,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":215418500.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2051-08-03T00:00:00","version":0,"instNumber":27,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":220745500.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2051-09-03T00:00:00","pftAmount":2513200,"schdPft":2513200,"schdPftPaid":0,"schdPri":5389200,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":210029300.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2051-09-03T00:00:00","version":0,"instNumber":28,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":215418500.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2051-10-03T00:00:00","pftAmount":2450400,"schdPft":2450400,"schdPftPaid":0,"schdPri":5452000,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":204577300.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2051-10-03T00:00:00","version":0,"instNumber":29,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":210029300.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2051-11-03T00:00:00","pftAmount":2386700,"schdPft":2386700,"schdPftPaid":0,"schdPri":5515700,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":199061600.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2051-11-03T00:00:00","version":0,"instNumber":30,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":204577300.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2051-12-03T00:00:00","pftAmount":2322400,"schdPft":2322400,"schdPftPaid":0,"schdPri":5580000,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":193481600.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2051-12-03T00:00:00","version":0,"instNumber":31,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":199061600.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2052-01-03T00:00:00","pftAmount":2257300,"schdPft":2257300,"schdPftPaid":0,"schdPri":5645100,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":187836500.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2052-01-03T00:00:00","version":0,"instNumber":32,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":193481600.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2052-02-03T00:00:00","pftAmount":2191400,"schdPft":2191400,"schdPftPaid":0,"schdPri":5711000,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":182125500.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2052-02-03T00:00:00","version":0,"instNumber":33,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":187836500.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2052-03-03T00:00:00","pftAmount":2124800,"schdPft":2124800,"schdPftPaid":0,"schdPri":5777600,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":176347900.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2052-03-03T00:00:00","version":0,"instNumber":34,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":182125500.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2052-04-03T00:00:00","pftAmount":2057400,"schdPft":2057400,"schdPftPaid":0,"schdPri":5845000,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":170502900.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2052-04-03T00:00:00","version":0,"instNumber":35,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":176347900.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2052-05-03T00:00:00","pftAmount":1989200,"schdPft":1989200,"schdPftPaid":0,"schdPri":5913200,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":164589700.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2052-05-03T00:00:00","version":0,"instNumber":36,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":170502900.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2052-06-03T00:00:00","pftAmount":1920200,"schdPft":1920200,"schdPftPaid":0,"schdPri":5982200,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":158607500.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2052-06-03T00:00:00","version":0,"instNumber":37,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":164589700.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2052-07-03T00:00:00","pftAmount":1850400,"schdPft":1850400,"schdPftPaid":0,"schdPri":6052000,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":152555500.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2052-07-03T00:00:00","version":0,"instNumber":38,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":158607500.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2052-08-03T00:00:00","pftAmount":1779800,"schdPft":1779800,"schdPftPaid":0,"schdPri":6122600,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":146432900.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2052-08-03T00:00:00","version":0,"instNumber":39,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":152555500.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2052-09-03T00:00:00","pftAmount":1708400,"schdPft":1708400,"schdPftPaid":0,"schdPri":6194000,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":140238900.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2052-09-03T00:00:00","version":0,"instNumber":40,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":146432900.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2052-10-03T00:00:00","pftAmount":1636100,"schdPft":1636100,"schdPftPaid":0,"schdPri":6266300,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":133972600.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2052-10-03T00:00:00","version":0,"instNumber":41,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":140238900.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2052-11-03T00:00:00","pftAmount":1563000,"schdPft":1563000,"schdPftPaid":0,"schdPri":6339400,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":127633200.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2052-11-03T00:00:00","version":0,"instNumber":42,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":133972600.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2052-12-03T00:00:00","pftAmount":1489100,"schdPft":1489100,"schdPftPaid":0,"schdPri":6413300,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":121219900.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2052-12-03T00:00:00","version":0,"instNumber":43,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":127633200.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2053-01-03T00:00:00","pftAmount":1414200,"schdPft":1414200,"schdPftPaid":0,"schdPri":6488200,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":114731700.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2053-01-03T00:00:00","version":0,"instNumber":44,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":121219900.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2053-02-03T00:00:00","pftAmount":1338600,"schdPft":1338600,"schdPftPaid":0,"schdPri":6563800,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":108167900.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2053-02-03T00:00:00","version":0,"instNumber":45,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":114731700.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2053-03-03T00:00:00","pftAmount":1261900,"schdPft":1261900,"schdPftPaid":0,"schdPri":6640500,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":101527400.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2053-03-03T00:00:00","version":0,"instNumber":46,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":108167900.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2053-04-03T00:00:00","pftAmount":1184500,"schdPft":1184500,"schdPftPaid":0,"schdPri":6717900,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":94809500.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2053-04-03T00:00:00","version":0,"instNumber":47,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":101527400.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2053-05-03T00:00:00","pftAmount":1106100,"schdPft":1106100,"schdPftPaid":0,"schdPri":6796300,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":88013200.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2053-05-03T00:00:00","version":0,"instNumber":48,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":94809500.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2053-06-03T00:00:00","pftAmount":1026800,"schdPft":1026800,"schdPftPaid":0,"schdPri":6875600,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":81137600.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2053-06-03T00:00:00","version":0,"instNumber":49,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":88013200.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2053-07-03T00:00:00","pftAmount":946600,"schdPft":946600,"schdPftPaid":0,"schdPri":6955800,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":74181800.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2053-07-03T00:00:00","version":0,"instNumber":50,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":81137600.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2053-08-03T00:00:00","pftAmount":865500,"schdPft":865500,"schdPftPaid":0,"schdPri":7036900,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":67144900.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2053-08-03T00:00:00","version":0,"instNumber":51,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":74181800.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2053-09-03T00:00:00","pftAmount":783400,"schdPft":783400,"schdPftPaid":0,"schdPri":7119000,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":60025900.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2053-09-03T00:00:00","version":0,"instNumber":52,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":67144900.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2053-10-03T00:00:00","pftAmount":700300,"schdPft":700300,"schdPftPaid":0,"schdPri":7202100,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":52823800.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2053-10-03T00:00:00","version":0,"instNumber":53,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":60025900.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2053-11-03T00:00:00","pftAmount":616200,"schdPft":616200,"schdPftPaid":0,"schdPri":7286200,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":45537600.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2053-11-03T00:00:00","version":0,"instNumber":54,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":52823800.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2053-12-03T00:00:00","pftAmount":531300,"schdPft":531300,"schdPftPaid":0,"schdPri":7371100,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":38166500.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2053-12-03T00:00:00","version":0,"instNumber":55,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":45537600.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2054-01-03T00:00:00","pftAmount":445300,"schdPft":445300,"schdPftPaid":0,"schdPri":7457100,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":30709400.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2054-01-03T00:00:00","version":0,"instNumber":56,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":38166500.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2054-02-03T00:00:00","pftAmount":358300,"schdPft":358300,"schdPftPaid":0,"schdPri":7544100,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":23165300.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2054-02-03T00:00:00","version":0,"instNumber":57,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":30709400.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2054-03-03T00:00:00","pftAmount":270200,"schdPft":270200,"schdPftPaid":0,"schdPri":7632200,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":15533100.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2054-03-03T00:00:00","version":0,"instNumber":58,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":23165300.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2054-04-03T00:00:00","pftAmount":181200,"schdPft":181200,"schdPftPaid":0,"schdPri":7721200,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7902400,"endBal":7811900.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2054-04-03T00:00:00","version":0,"instNumber":59,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":15533100.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"R","bpiAmount":0},{"schDate":"2054-05-03T00:00:00","pftAmount":91200.00,"schdPft":91200.00,"schdPftPaid":0,"schdPri":7811900.00,"schdPriPaid":0,"feeSchd":0,"tDSAmount":0,"totalAmount":7903100,"endBal":0.00,"limitDrop":0,"dropLineLimit":0,"availableLimit":0,"dueDate":"2054-05-03T00:00:00","version":0,"instNumber":60,"repayOnSchDate":true,"rvwOnSchDate":true,"disbOnSchDate":false,"bpiOrHoliday":"","frqDate":true,"balanceForPftCal":7811900.00,"calculatedRate":14.000000000,"profitBalance":0,"disbAmount":0,"cpzAmount":0,"specifier":"M","bpiAmount":0}],"planEMIHmonths":[],"planEMIHDates":[],"planPRIHDates":[],"planPRIHMonths":[],"overdueCharges":[],"summary":{"effectiveRateOfReturn":0,"totalGracePft":0,"totalGraceCpz":0,"totalGrossGrcPft":0,"totalCpz":0,"totalProfit":135220000.00,"totalRepayAmt":475220000.00,"feeChargeAmount":0,"numberOfTerms":60,"loanTenor":60,"maturityDate":"2054-05-03T00:00:00","firstEmiAmount":8977700,"nextSchDate":"2049-05-03T00:00:00","nextRepayAmount":0,"futureInst":60,"futureTenor":60,"firstInstDate":"2049-06-03T00:00:00","paidTotal":0,"paidPri":0,"paidPft":0,"lastRepayDate":"2049-04-24T00:00:00","outstandingTotal":475220000.00,"outstandingPri":340000000.00,"outstandingPft":135220000.00,"overdueTotal":0,"overduePri":0,"overduePft":0,"overdueInst":0,"overDueCharges":0,"overdueTotalIncludeCharges":0,"overdueCharges":[],"advPaymentAmount":0,"finActiveStatus":"A","fullyDisb":false,"limitBalance":0,"billedAmount":0,"unbilledAmount":0,"DPDDays":0,"limitDrop":0,"currentDroplineLimit":0,"utilisation":0,"availableLimit":0,"graceInst":0,"graceTenor":0,"futureGraceInst":0,"futureGraceTenor":0,"totalRevisedTenure":0,"revisedLastStepTerms":0},"vas":[],"outstandingPri":0,"returnStatus":{"returnCode":"0000","returnText":"Success"},"version":0,"isUpfrontAuto":false,"excessAmount":0,"intervalFee":[],"disbursements":[]}';
                //String apiResponse = resp.getBody();
                system.debug('line 988-->>'+apiResponse);
                ContentVersion content = new ContentVersion();
                content.Title = 'LoanScheduler.txt';
                content.PathOnClient = 'LoanScheduler_Response.txt';
                content.VersionData = Blob.valueOf((apiResponse));
                content.IsMajorVersion = true;
                insert content;
                
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id LIMIT 1].ContentDocumentId;
                
                // Create Document_Details__c record
                Document_Details__c checklist = new Document_Details__c();
                checklist.Content_Document_Id__c = cdl.ContentDocumentId;
                checklist.Loan_Application__c = loanid;
                checklist.Name = 'Loan Scheduler Response';
                insert checklist;
                
                cdl.LinkedEntityId =checklist.id ; // Temp link to User so ContentDocument exists
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                insert cdl;
                
                // Deserialize the actual API response
                LoanSchedulerCreateChargesResponseWrapper responseJSON = (LoanSchedulerCreateChargesResponseWrapper) 
                    JSON.deserialize(apiResponse, LoanSchedulerCreateChargesResponseWrapper.class);
                
                // Extract returnText
                if(responseJSON.returnStatus != null && responseJSON.returnStatus.returnText != null){
                    returnText = responseJSON.returnStatus.returnText;
                }else{
                    returnText = 'Some issue in API, empty return status';
                }
                Boolean isSuccessResponse = false;
                if(returnText == 'Success'){
                    isSuccessResponse = true;
                }
                
                // Save API Response in Integration_Details__c
                // integrationDetail.Calling_Source__c = wrapper.type;
                // integrationDetail.Request_JSON__c = respWrapper.payload;
                // //integrationDetail.Response_JSON__c = resp.getBody()/*mockApiResponse*/;
                // integrationDetail.Comments__c = invocationType;
                // integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                // integrationDetail.Method_Type__c = intSetting.Request_Method__c;
                // integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                // integrationDetail.Name = processName;
                // integrationDetail.Loan_Application__c = loanId;
                // integrationDetail.Is_Success_Response__c = isSuccessResponse;
                // integrationDetail.Object_Name__c = 'Document_Details__c';
                // integrationDetail.Related_Record_Id__c = checklist.Id;
                // insert integrationDetail;
                
                system.debug('invocationType::: '+invocationType);
                //remove from 653 and only keep else with invocationType == 'RepaymentLWC'
                if (returnText == 'Success' && invocationType != 'RepaymentLWC') {
                    System.debug('Processing Loan Scheduler for LOS Charges');
                    
                    // **Charge Creation Logic**
                    List<Charges_Insurance__c> chargeList = new List<Charges_Insurance__c>();
                    List<Charges_Insurance__c> parentChargeList = new List<Charges_Insurance__c>();
                    Map<Id, Opportunity> updatedOpportunityMap = new Map<Id, Opportunity>();
                    Map<Id, Charges_Insurance__c> parentChargeMap = new Map<Id, Charges_Insurance__c>();
                    Map<String, Map<String, Object>> feeTypeToMasterDataMap = new Map<String, Map<String, Object>>();
                    String chargeRecordType = Schema.SObjectType.Charges_Insurance__c.getRecordTypeInfosByName().get('Charges').getRecordTypeId();
                    Map<Id, Charges_Insurance__c> oppIdVsChargeInsuranceMap = new Map<Id, Charges_Insurance__c>();
                    
                    // **Query Charges_Insurance_Master__c Records**
                    List<Charges_Insurance_Master__c> chargesInsuranceMasterRecords = [
                        SELECT Id, Charges_Fee_Type__c, Tax__c, Category__c,Max_Percent__c,Min_Percent__c
                        FROM Charges_Insurance_Master__c
                        WHERE Category__c != 'LMS'
                    ];
                    
                    // **Map Master Records by Fee Type**
                    for (Charges_Insurance_Master__c master : chargesInsuranceMasterRecords) {
                        Map<String, Object> masterData = new Map<String, Object>();
                        masterData.put('MasterId', master.Id);
                        masterData.put('Tax', master.Tax__c != null ? master.Tax__c : 0); // Default tax to 0 if null
                        masterData.put('Category',master.Category__c != null ? master.Category__c:'');
                        masterData.put('MinPercent',master.Min_Percent__c != null ? master.Min_Percent__c:0);
                        masterData.put('MaxPercent',master.Max_Percent__c != null ? master.Max_Percent__c:0);
                        feeTypeToMasterDataMap.put(master.Charges_Fee_Type__c, masterData);
                    }
                    
                    // **Query Existing Total Charges Records**
                    Map<Id, Charges_Insurance__c> existingTotalChargesMap = new Map<Id, Charges_Insurance__c>();
                    List<Charges_Insurance__c> existingTotalChargesRecords = [
                        SELECT Id,name, Loan_Application__c,Loan_Application__r.StageName,Balance_Login_Fees__c,Loan_Application__r.Requested_Amount__c, Total_Charges__c,Requested_Amount_INR__c, Total_Fee_to_be_deducted__c
                        FROM Charges_Insurance__c
                        WHERE Loan_Application__c IN :oppList AND Name = 'Total Charges'
                    ];
                    
                    // Store existing Total Charges records in a Map
                    for (Charges_Insurance__c totalCharge : existingTotalChargesRecords) {
                        existingTotalChargesMap.put(totalCharge.Loan_Application__c, totalCharge);
                        
                    }
                    
                    // **Create Parent Charge Records (Total Charges) Only If Needed**
                    for (Opportunity opp : oppList) {
                        Charges_Insurance__c parentCharge;
                        
                        if (existingTotalChargesMap.containsKey(opp.Id)) {
                            // **Total Charges Record Exists, Update It**
                            parentCharge = existingTotalChargesMap.get(opp.Id);
                        } else {
                            // **Create a New Total Charges Record**
                            parentCharge = new Charges_Insurance__c();
                            parentCharge.Name = 'Total Charges';
                            parentCharge.Loan_Application__c = opp.Id;
                            parentCharge.RecordTypeID = chargeRecordType;
                            
                            // **Initialize fields to prevent null issues**
                            parentCharge.Total_Charges__c = 0;
                            parentCharge.Total_Fee_to_be_deducted__c = 0;
                            
                            parentChargeList.add(parentCharge);
                        }
                        
                        // Store in Map for later processing
                        oppIdVsChargeInsuranceMap.put(opp.Id, parentCharge);
                    }
                    
                    // Insert New Total Charges Records if Needed
                    if (!parentChargeList.isEmpty()) {
                        System.debug('Inserting Parent Charge Records: ' + parentChargeList);
                        insert parentChargeList;
                        
                        // Update the Map with newly created records
                        for (Charges_Insurance__c newParentCharge : parentChargeList) {
                            oppIdVsChargeInsuranceMap.put(newParentCharge.Loan_Application__c, newParentCharge);
                        }
                    }
                    
                    // **Process API Fees & Update Total Charges**
                    Map<Id, Charges_Insurance__c> updatedParentChargeMap = new Map<Id, Charges_Insurance__c>();
                    
                    for (Opportunity opp : oppList) {
                        
                        System.debug('Processing LOS Charges for Opportunity: ' + opp.Id);
                        
                        if (!oppIdVsChargeInsuranceMap.containsKey(opp.Id)) {
                            System.debug('No Parent Charge Found for Opportunity: ' + opp.Id);
                            continue;
                        }
                        
                        Charges_Insurance__c parentCharge = oppIdVsChargeInsuranceMap.get(opp.Id);
                        
                        
                        for (Fee fee : responseJSON.fees) {
                            feeCodes.add(fee.feeCode);
                        }
                        
                        for (Charges_Insurance__c ci : [
                            SELECT Id,Name,Stage__c,Allocated_Amount__c,Requested_Amount_INR__c,Balance_Login_Fees__c,Login_Fees__c, Charges_Fee_Type__c,Paid_Orginal__c,Paid_Amount_Gst__c
                            FROM Charges_Insurance__c
                            WHERE Loan_Application__c = :opp.Id
                            AND Charges_Fee_Type__c IN :feeCodes
                        ]) {
                            existingChargesMap.put(ci.Charges_Fee_Type__c, ci);
                        }
                        
                        
                        
                        if (responseJSON != null && responseJSON.fees != null) {
                            System.debug('Fees Found: ' + responseJSON.fees);
                            Charges_Insurance__c newCharge= new Charges_Insurance__c();
                            for (Fee fee : responseJSON.fees) {
                                
                                
                                if(stageName == 'Sales Login' || stageName == 'PSV' || stageName == 'Disbursement'){
                                    
                                    
                                    
                                    if (existingChargesMap.containsKey(fee.feeCode)) {
                                        System.debug('line 289--->>');
                                        newCharge = existingChargesMap.get(fee.feeCode);
                                         newCharge.Allocated_Amount__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        newCharge.Default_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        newCharge.Requested_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        
                                    } else {
                                        
                                        newCharge = new Charges_Insurance__c();
                                        newCharge.Name = fee.feeCode;
                                        newCharge.Fee_Method__c = fee.feeMethod;
                                        newCharge.Charges_Insurance__c = parentCharge.Id;
                                        newCharge.Charges_Fee_Type__c = fee.feeCode;
                                        system.debug('line 256-->>'+ newCharge.Charges_Fee_Type__c);
                                        newCharge.Loan_Application__c = opp.Id;
                                        newCharge.Default_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        newCharge.Requested_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        //newCharge.Category__c = 'LOS';
                                        newCharge.RecordTypeID = chargeRecordType;
                                        newCharge.Stage__c = stageName;
                                        //newCharge.Allocation__c = (requestedAmount) / (Utility.truncateTwoZeros(fee.feeAmount)) * 100;
                                        Login_Fees__mdt mapping = Login_Fees__mdt.getInstance(fee.feeCode);
                                        if (mapping != null) {
                                              newCharge.Priority__c = mapping.Priority__c;
                                         }
                                        newCharge.GST_Exempt__c = 'E';
                                        
                                        /*if(fee.feeCode == 'PROCFEE'){
                                            newCharge.Priority__c = 1;
                                        }
                                        else if(fee.feeCode == 'STFRCHG'){
                                            newCharge.Priority__c = 3;
                                        }*/
                                        newCharge.Allocated_Amount__c = Utility.truncateTwoZeros(fee.feeAmount);
                                        if(loginFees!=null){
                                        newCharge.Login_Fees__c = loginFees;
                                        }
                                        
                                        
                                    }
                                }
                                
                                
                                Decimal taxPercentage = 0; // Default to 0%
                                Decimal taxAmount = 0;      // Calculated tax amount
                                
                                // **Tag the Master Record ID based on Fee Type**
                                if (feeTypeToMasterDataMap.containsKey(fee.feeCode)) {
                                    Map<String, Object> masterData = feeTypeToMasterDataMap.get(fee.feeCode);
                                    newCharge.Charges_Insurance_Master__c = (Id) masterData.get('MasterId');
                                    newCharge.Tax__c = (Decimal) masterData.get('Tax');
                                    newCharge.Category__c = (String) masterData.get('Category');
                                    newCharge.Min_Percent__c = (Decimal) masterData.get('MinPercent');
                                    newCharge.Max_Percent__c = (Decimal) masterData.get('MaxPercent');
                                    taxPercentage = (Decimal) masterData.get('Tax'); 
                                } else {
                                    newCharge.Tax__c = 0;
                                }
                                // **Calculate Tax Amount (Tax % of Fee Amount)**
                                /*if (taxPercentage > 0 && Utility.truncateTwoZeros(fee.feeAmount) != null) {
                                taxAmount = (Utility.truncateTwoZeros(fee.feeAmount) * taxPercentage) / 100;
                                 }

                                newCharge.Final_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount) + taxAmount;*/
                                if (taxPercentage > 0 && Utility.truncateTwoZeros(fee.feeAmount) != null) {
                                    Decimal rawTaxAmount = (Utility.truncateTwoZeros(fee.feeAmount) * taxPercentage) / 100;
                                    Decimal decimalPart = rawTaxAmount - Math.floor(rawTaxAmount);
                                    taxAmount = decimalPart < 0.5 ? Math.floor(rawTaxAmount) : Math.ceil(rawTaxAmount);
                                }
                                
                                newCharge.Final_Amount_INR__c = Utility.truncateTwoZeros(fee.feeAmount) + taxAmount;
                                newCharge.Tax_INR__c = 0;
                                
                                // if(Test.isrunningTest()){
                                //     newCharge.Allocated_Amount__c= 0;
                                // }               
                                chargeList.add(newCharge);
                                
                                // **Update Parent Charge Totals (Including Tax)**
                                Decimal totalChargeAmount = (Utility.truncateTwoZeros(fee.feeAmount) != null ? Utility.truncateTwoZeros(fee.feeAmount) : 0);
                                
                                parentCharge.Total_Charges__c += totalChargeAmount;
                                parentCharge.Total_Fee_to_be_deducted__c += totalChargeAmount;
                                updatedParentChargeMap.put(parentCharge.Id, parentCharge);
                            }
                            
                            decimal remainingloginfee = loginFees;
                            decimal adjustedLoginFee = loginFees;
                            // if(!Test.isrunningTest()){
                            // chargeList.sort(new ChargePriorityComparator());
                            // }
                            for (Charges_Insurance__c newChargee : chargeList) {
                                
                                if(stageName == 'Sales login'){

                                    if(newChargee.name == 'PROCFEE'){
                                        newChargee.Login_Fees__c = loginFees;
                                    }
    
                                    if(loginFees!=null){
                                    if (newChargee.Allocated_Amount__c > loginFees) {
                                        
                                        newChargee.Balance_Charge_Amount__c = newChargee.Allocated_Amount__c - loginFees;
                                        newChargee.Requested_Amount_INR__c =  newChargee.Balance_Charge_Amount__c;
                                        newChargee.Final_Amount_INR__c =  newChargee.Requested_Amount_INR__c;
                                        newChargee.Balance_Login_Fees__c = 0;
                                        newChargee.Adjusted_Login_Fee__c = adjustedLoginFee;
                                        loginFees = 0; 
                                        
                                        if(newChargee.name == 'PROCFEE'){
                                            
                                            remainingloginfee =newChargee.Balance_Login_Fees__c;
                                            adjustedLoginFee = newChargee.Balance_Login_Fees__c ;
                                        }
                                        if(newChargee.name != 'PROCFEE'){
                                            newChargee.Login_Fees__c = remainingloginfee;
                                        }
                                         system.debug('line 409--'+newChargee.Login_Fees__c);
                                        system.debug('line 410--'+newCharge.Allocated_Amount__c);
                                        
                                        
                                    } else {
                                        
                                        newChargee.Balance_Charge_Amount__c = 0;
                                        newChargee.Balance_Login_Fees__c = loginFees - newChargee.Allocated_Amount__c;
                                        newChargee.Requested_Amount_INR__c =  newChargee.Balance_Login_Fees__c;
                                        newChargee.Adjusted_Login_Fee__c  = newChargee.Allocated_Amount__c;
                                        if(newChargee.name == 'PROCFEE'){
                                            
                                            remainingloginfee = newChargee.Balance_Login_Fees__c;
                                            adjustedLoginFee = loginFees - newChargee.Allocated_Amount__c;
                                        }
                                         
                                     
                                        loginFees -= newChargee.Allocated_Amount__c;
                                        
                                        if(newChargee.name == 'STFRCHG'){
                                            newChargee.Login_Fees__c = remainingloginfee;
                                            
                                          
                                        }
                                        
                                         
                                         
                                        
                                    }
                                }           
                                }
                                else{
                                    //for non-sales
                                   if(existingChargesMap.containsKey(newChargee.Name)){
                                      loginFeesPSV = existingChargesMap.get(newChargee.Name).Paid_Orginal__c != null ? existingChargesMap.get(newChargee.Name).Paid_Orginal__c : 0 ;
                                   }
                                   else{
                                    loginFeesPSV = 0;
                                   }
                                   decimal remainingloginfeePSV = loginFeesPSV;
                                   decimal adjustedLoginFeePSV = loginFeesPSV;
                            
                                    if(newChargee.name == 'PROCFEE'){
                                        newChargee.Login_Fees__c = loginFeesPSV;
                                    }
    
                                    if(loginFeesPSV!=null){
                                    if (newChargee.Allocated_Amount__c > loginFeesPSV) {
                                        
                                        newChargee.Balance_Charge_Amount__c = newChargee.Allocated_Amount__c - loginFeesPSV;
                                        newChargee.Requested_Amount_INR__c =  newChargee.Balance_Charge_Amount__c;
                                        newChargee.Final_Amount_INR__c =  newChargee.Requested_Amount_INR__c;
                                        newChargee.Balance_Login_Fees__c = 0;
                                        newChargee.Adjusted_Login_Fee__c = adjustedLoginFeePSV;
                                        loginFeesPSV = 0; 
                                        
                                        if(newChargee.name == 'PROCFEE'){
                                            
                                            remainingloginfeePSV =newChargee.Balance_Login_Fees__c;
                                            adjustedLoginFeePSV = newChargee.Balance_Login_Fees__c ;
                                        }
                                        if(newChargee.name != 'PROCFEE'){
                                            newChargee.Login_Fees__c = remainingloginfeePSV;
                                        }
                                         system.debug('line 409--'+newChargee.Login_Fees__c);
                                        system.debug('line 410--'+newCharge.Allocated_Amount__c);
                                        
                                        
                                    } else {
                                        
                                        newChargee.Balance_Charge_Amount__c = 0;
                                        newChargee.Balance_Login_Fees__c = loginFeesPSV - newChargee.Allocated_Amount__c;
                                        newChargee.Requested_Amount_INR__c =  newChargee.Balance_Login_Fees__c;
                                        newChargee.Adjusted_Login_Fee__c  = newChargee.Allocated_Amount__c;
                                        if(newChargee.name == 'PROCFEE'){   
                                            remainingloginfeePSV = newChargee.Balance_Login_Fees__c;
                                            adjustedLoginFeePSV = loginFeesPSV - newChargee.Allocated_Amount__c;
                                        }
                                         
                                        loginFeesPSV -= newChargee.Allocated_Amount__c;
                                        
                                        if(newChargee.name == 'STFRCHG'){
                                            newChargee.Login_Fees__c = remainingloginfeePSV;     
                                        }                            
                                    }
                                } 
                                }
                            }
                            
                        }
                    }
                    
                    
                    // **Insert and Update Records**
                    if (!chargeList.isEmpty()) {
                        System.debug('Inserting LOS Charges: ' + chargeList);
                       
                        upsert chargeList;
                        
                    }
                    
                    if (!updatedParentChargeMap.isEmpty()) {
                        List<Charges_Insurance__c> updatedParentChargeList = new List<Charges_Insurance__c>(updatedParentChargeMap.values());
                        System.debug('Updating Parent Charges: ' + updatedParentChargeList);
                        update updatedParentChargeList;
                    }
                    
                    if (!updatedOpportunityMap.isEmpty()) {
                        List<Opportunity> updatedOpportunityList = new List<Opportunity>(updatedOpportunityMap.values());
                        System.debug('Updating Opportunities: ' + updatedOpportunityList);
                        update updatedOpportunityList;
                    }

                    //Insert LMS charges for AHL
                    if(stageName != 'Sales Login'){
                        insertLMSChargesForAHL(oppList);
                    }
                }
                else if(returnText == 'Success'){
                    system.debug('responseJSON.schedule: '+responseJSON.schedules);
                    
                    Date loanStartDatePerSchedule;
                    Boolean hasGrace=false;
                     for (Schedule sc : responseJSON.schedules) {
                        if (sc.specifier == 'G') {
                            hasGrace = true;
                        }
                    }
                    for (Schedule sc : responseJSON.schedules) {
                        if (loanStartDatePerSchedule == null && sc.schDate != null) {
                            loanStartDatePerSchedule = sc.schDate.date();
                            system.debug('sc.schDate  '+sc.schDate);
                            system.debug('loanStartDatePerSchedule  '+loanStartDatePerSchedule);
                        }
                        // if (sc.specifier == 'G') {
                        //     hasGrace = true;
                        // }

                        if ((!hasGrace && sc.specifier == 'R' && sc.bpiAmount == 0 && sc.instNumber == 2)||(hasGrace && sc.specifier == 'R' && sc.bpiAmount == 0)) {
                            System.debug('329 : '+sc.totalAmount);
                            Opportunity op = new Opportunity(
                                Id = loanId,
                                EMI_Amount_Repayment_Schedule__c = Utility.truncateTwoZeros(sc.totalAmount)
                            );
                            update op;
                            break;
                        }
                    }

                    Integer scheduleCount = responseJSON.schedules != null ? responseJSON.schedules.size() : 0;
                    system.debug('scheduleCount: '+scheduleCount);
                    Loan_Transaction__c loanTrans = [
                        SELECT Id, Number_of_Terms__c, Loan_Start_Date_Repayment_Schedule__c,Repayment_Schedule_DateTime__c 
                        FROM Loan_Transaction__c 
                        WHERE Loan_Application__c = :loanId AND RecordType.DeveloperName = 'Transaction_Details'
                        LIMIT 1
                    ];

                    loanTrans.Number_of_Terms__c = String.valueOf(scheduleCount);
                    loanTrans.Loan_Start_Date_Repayment_Schedule__c = loanStartDatePerSchedule;
                    loanTrans.Repayment_Schedule_DateTime__c = Datetime.now();//added by kalpesh
                    update loanTrans;
                }
            //} 
            
            return returnText;
        } catch (Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'LoanScheduler', '', '') });
            System.debug('Error: ' + e.getMessage() + e.getStackTraceString());
            throw new AuraHandledException('Salesforce Exception: ' + e.getMessage());
        }
    }
    

    public static void insertLMSChargesForAHL(List<Opportunity> oppListForAPI){

       List<Charges_Insurance__c> chargeList = new List<Charges_Insurance__c>();

        if (!oppListForAPI.isEmpty()) {
            System.debug('Processing Opportunities for LMS charges: ' + oppListForAPI);
            
            // Step 2: Fetch Existing LMS Charges for the Opportunities
            Set<Id> oppIds = new Set<Id>();
            for (Opportunity opp : oppListForAPI) {
                oppIds.add(opp.Id);
            }

            Map<String, Set<Id>> existingChargeTypeVsOppIds = new Map<String, Set<Id>>();
            List<Charges_Insurance__c> existingCharges = [
                SELECT Id, Charges_Fee_Type__c, Loan_Application__c
                FROM Charges_Insurance__c
                WHERE Loan_Application__c IN :oppIds AND Category__c = 'LMS'
            ];

            for (Charges_Insurance__c charge : existingCharges) {
                if (!existingChargeTypeVsOppIds.containsKey(charge.Charges_Fee_Type__c)) {
                    existingChargeTypeVsOppIds.put(charge.Charges_Fee_Type__c, new Set<Id>());
                }
                existingChargeTypeVsOppIds.get(charge.Charges_Fee_Type__c).add(charge.Loan_Application__c);
            }
            
            System.debug('Existing Charges Found: ' + existingChargeTypeVsOppIds);
            
            // Step 3: Fetch Related Product2 Records
            Product2 mainProduct =[SELECT Id from Product2 WHERE RecordType.Name = 'Product' AND Loan_Application__c IN :oppIds LIMIT 1];
            Product2 subProduct = [SELECT Id from Product2 WHERE RecordType.Name = 'Sub Product' AND Product__c =:mainProduct.Id AND Loan_Application__c IN :oppIds LIMIT 1];
            
            List<Product2> relatedProductRecords = [
                SELECT Id, Name, RecordType.Name, Loan_Application__c
                FROM Product2
                WHERE Loan_Application__c IN :oppIds AND RecordType.Name = 'Variant' AND Product__c = :subProduct.Id
            ];
            
            List<Product2> subVariant = [SELECT Id, Name, RecordType.Name, Loan_Application__c from Product2 WHERE RecordType.Name = 'Sub Variant' AND Variant__c =:relatedProductRecords[0].Id AND Loan_Application__c IN :oppIds LIMIT 1];

            Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.getGlobalDescribe()
                .get('Charges_Insurance__c')
                .getDescribe()
                .getRecordTypeInfosByName();
            Id chargesRecordTypeId = recordTypeMap.get('Charges').getRecordTypeId();
            Map<Id, Map<String, String>> oppIdVsProductRecords = new Map<Id, Map<String, String>>();
            
            for (Product2 prod : relatedProductRecords) {
                if (!oppIdVsProductRecords.containsKey(prod.Loan_Application__c)) {
                    oppIdVsProductRecords.put(prod.Loan_Application__c, new Map<String, String>());
                }
                oppIdVsProductRecords.get(prod.Loan_Application__c).put(prod.RecordType.Name, prod.Name);
            }

            if(!subVariant.isEmpty()){
                if (!oppIdVsProductRecords.containsKey(subVariant[0].Loan_Application__c)) {
                    oppIdVsProductRecords.put(subVariant[0].Loan_Application__c, new Map<String, String>());
                }
                oppIdVsProductRecords.get(subVariant[0].Loan_Application__c).put(subVariant[0].RecordType.Name, subVariant[0].Name);
            }
            //system.debug('oppIdVsProductRecords: '+ JSON.serialize(oppIdVsProductRecords));

            // Step 4: Fetch LMS Charge Types
            List<Charges_Insurance_Master__c> chargesInsuranceMasterRecords = [
                SELECT Id, Charges_Fee_Type__c, Default_Value__c, Category__c, 
                Sub_Product__c, Sub_Product__r.Product__c, Sub_Product__r.Product__r.Name,
                Sub_Product__r.Name,Max_Percent__c,Min_Percent__c, Sub_Variant__r.Name
                FROM Charges_Insurance_Master__c
                WHERE Category__c = 'LMS'
            ];

            // Step 5: Create LMS Charges if not already created
            for (Opportunity opp : oppListForAPI) {
                Map<String, String> productRecords = oppIdVsProductRecords.get(opp.Id);

                if (productRecords != null) {
                    for (Charges_Insurance_Master__c chargeInsuranceMaster : chargesInsuranceMasterRecords) {
                        //System.debug('chargeInsuranceMaster: '+chargeInsuranceMaster);
                        
                        String requiredSubProduct = chargeInsuranceMaster.Sub_Product__r.Name;
                        String requiredSubVariant = chargeInsuranceMaster.Sub_Variant__c != null ? chargeInsuranceMaster.Sub_Variant__r.Name : '';

                        String actualSubProduct = productRecords.get('Variant');
                        String actualSubVariant = productRecords.containsKey('Sub Variant') ? productRecords.get('Sub Variant') : '';

                        if ((actualSubProduct == requiredSubProduct && String.isBlank(requiredSubVariant)) || (String.isNotBlank(requiredSubVariant) && actualSubVariant == requiredSubVariant)) {
                            
                            Boolean chargeAlreadyExists = existingChargeTypeVsOppIds.containsKey(chargeInsuranceMaster.Charges_Fee_Type__c) &&
                                                        existingChargeTypeVsOppIds.get(chargeInsuranceMaster.Charges_Fee_Type__c).contains(opp.Id);
                            
                            if (!chargeAlreadyExists) {  // Only create if it doesn't exist
                                Charges_Insurance__c newLMSCharge = new Charges_Insurance__c();
                                newLMSCharge.Name = chargeInsuranceMaster.Charges_Fee_Type__c;
                                newLMSCharge.Charges_Fee_Type__c = chargeInsuranceMaster.Charges_Fee_Type__c;
                                newLMSCharge.Default_Percentage__c = chargeInsuranceMaster.Default_Value__c;
                                newLMSCharge.Requested_Percentage__c = chargeInsuranceMaster.Default_Value__c;
                                newLMSCharge.Loan_Application__c = opp.Id;
                                newLMSCharge.Category__c = chargeInsuranceMaster.Category__c;
                                newLMSCharge.Max_Percent__c = chargeInsuranceMaster.Max_Percent__c;
                                newLMSCharge.Min_Percent__c = chargeInsuranceMaster.Min_Percent__c;
                                newLMSCharge.RecordTypeID = chargesRecordTypeId;
                                chargeList.add(newLMSCharge);
                            }
                        }
                    }
                }
            }

            if (!chargeList.isEmpty()) {
                System.debug('Inserting New LMS Charges: ' + chargeList);
                insert chargeList;
            }
        }
    }

    public static HTTPResponse executeRESTAPIRequest(Map<String, String> integrationRequestMap, Id loanId) {
        try {            
            HttpRequest req = new HttpRequest();
            Http http = new Http();
    
            // Extract data from Map
            String endpoint = integrationRequestMap.get('endpoint');//'Callout:Create_Schedule_Simulation_API_LOS'; // Hardcoded Endpoint
            String requestBody = integrationRequestMap.get('requestJSON');
            String bearer = integrationRequestMap.get('bearer');
            String contentType = integrationRequestMap.get('contentType');
            String requestMethod = integrationRequestMap.get('requestMethod');
            String cookie = integrationRequestMap.get('cookie');

            System.debug('request body execute API   '+requestBody);
    
            req.setEndpoint(endpoint);
            req.setMethod(requestMethod);
            // req.setTimeout(30000);
    
            // Set Headers
            req.setHeader('Content-Type', contentType);
             req.setHeader('Authorization', 'Bearer ' + bearer);
            req.setHeader('Cookie', cookie);
            req.setHeader('MESSAGEID', constants.get('MESSAGEID')/*'167036797111'*/);
            req.setHeader('Language', constants.get('Language')/*'ENG'*/);
            req.setHeader('ServiceName', constants.get('ServiceName')/*'createLoanSchedule'*/);
            req.setHeader('ENTITYID', constants.get('ENTITYID')/*'14589954555'*/);
            req.setHeader('ServiceVersion', constants.get('ServiceVersion')/*'1'*/);
            req.setHeader('RequestTime', Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss'));
    
            // Set Body
            req.setBody(requestBody);
            System.debug('Executing API Request: ' + requestBody);
    
            // Send the HTTP request
            HTTPResponse res = http.send(req);
            System.debug('API Response: ' + res.getBody());

            //colending data sent 

        List<Opportunity> oppList = [
                SELECT Id, Name, Co_lending__c
                FROM Opportunity
                WHERE Co_lending__c = 'Yes'
                AND Id = :loanId
                LIMIT 1
               ];      
        String Colending_Status = '';
        String LoanApplication_Name = '';
        if (!oppList.isEmpty() && oppList[0].Co_lending__c != null) {
            Colending_Status = oppList[0].Co_lending__c;
        }
         if (!oppList.isEmpty() && oppList[0].Name != null) {
            LoanApplication_Name = oppList[0].Name;
        }

            System.debug('opp with opp.Co_lending__c'+ Colending_Status);
         if (Colending_Status == 'Yes') {
                HttpRequest reqData = new HttpRequest();
            //Http http = new Http();
            // Build wrapper JSON
            Map<String, Object> wrapper = new Map<String, Object>();
            wrapper.put('applicationNumber', LoanApplication_Name);
            wrapper.put('rawRequest', JSON.deserializeUntyped(requestBody));

            Object rawJson;
            try {
                rawJson = JSON.deserializeUntyped(res.getBody());
            } catch (Exception e) {
                rawJson = res.getBody();
            }
            wrapper.put('rawResponse', rawJson);

            String requestBodyForColending = JSON.serialize(wrapper);
            req.setEndpoint('Callout:HL_Colending_RPS_Syncing');
            ///req.setEndpoint('https://uat-hl-sf.godrejhf.com/colending-ghf/api/v1/rps/upsert');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(requestBodyForColending);

            System.debug('Forwarding body: ' + requestBodyForColending);

            HttpResponse resData = http.send(req);

            System.debug('Forward API Response: ' + resData.getBody());
            }
        return res;
        } catch (Exception e) {
            System.debug('API Call Failed: ' + e.getMessage());
            //throw new AuraHandledException('API Call Failed: ' + e.getMessage());
            throw e;
        }
    }
    
    // Wrapper Class for Multiproduct
    public class MultiproductChargesResponseWrapper {
        public String returnStatus;
        public Integration_Details__c intDetail;
        public List<Fee> fees;
    }

    // Wrapper Class for API Response
    public class LoanSchedulerCreateChargesResponseWrapper {
        public String finReference;
        public List<Fee> fees;
        public List<Insurance> insurance;
        public List<Schedule> schedules;
        public List<OverdueCharge> overdueCharges;
        public Decimal advPaymentAmount;
        public String finActiveStatus;
        public Boolean fullyDisb;
        public ReturnStatus returnStatus;
    }

    public class Fee {
        public String feeCategory;
        public String feeCode;
        public Decimal feeAmount;
        public Decimal waiverAmount;
        public String feeMethod;
        public Decimal paidAmount;
        public Integer scheduleTerms;
        public Integer paymentID;
        public Decimal feeBalance;
        public Integer version;
        public List<FinFeeReceipt> finFeeReceipts;
    }

    public class FinFeeReceipt {
        public Integer receiptID;
        public Decimal paidAmount;
    }

    public class Insurance {
        public String policyCode;
        public String insReference;
        public Boolean insuranceReq;
    }

    public class Schedule {
        public DateTime schDate;
        public String event;
        public Decimal pftAmount;
        public String specifier;
        public Decimal totalAmount;
        public Decimal bpiAmount;
        public Decimal instNumber;
    }

    public class OverdueCharge {
        public Date odDate;
        public Decimal odPftPaid;
    }

    public class ReturnStatus {
        public String returnCode;
        public String returnText;
    }
}