public with sharing class COMM_CreditChargesTableController {

    static String conLabels = 'Transaction_Detail_Record_type,Loan_Schedule_API_Endpoint,Calling_Source_Loan_Schedule_API,Charges_API_Invocation,Charges_Record_Type,Pricing_Approval_Approved,Pricing_Approval_Submitted_For_Approval';

    @AuraEnabled(cacheable=true)
    public static String getMetadataValue(String metadataName) {
        try {
            Constants__mdt metadataRecord = Constants__mdt.getInstance(metadataName);
            if (metadataRecord != null) {
                return metadataRecord.Value__c;
            }
        } catch (Exception e) {
            System.debug('Error fetching metadata: ' + e.getMessage());
        }
        return null;
    }
    

    public static Map <String,String> constants = Utility.getConstants(conLabels);

    //getting the value of constants
    public static Map <String,String> getConstants() {
        return constants;
    }

    @AuraEnabled
    public static Boolean checkPricingApprovalStatus(String loanApplicationId){
        try {
            List<Opportunity> oppList = [SELECT Id, Pricing_Approval_Status__c,Loan_Hierarchy__c,Product__c FROM Opportunity  WHERE Id = :loanApplicationId  LIMIT 1];
            if (!oppList.isEmpty()) {
                String status = oppList[0].Pricing_Approval_Status__c;
                String loanHierarchy = oppList[0].Loan_Hierarchy__c;
                return (status == constants.get('Pricing_Approval_Submitted_For_Approval') || loanHierarchy == 'Parent');
            }
            return false;
        } catch (Exception e) {
            System.debug('Error in checkPricingApprovalStatus: ' + e.getMessage());
            throw new AuraHandledException('Error checking pricing approval status: ' + e.getMessage());
        }
        
    }

    @AuraEnabled(cacheable=true)
    public static Boolean checkLoanTransaction(String loanApplicationId) {
        List<Loan_Transaction__c> transactions = [SELECT Id FROM Loan_Transaction__c WHERE Loan_Application__c = :loanApplicationId AND RecordType.DeveloperName = :constants.get('Transaction_Detail_Record_type') LIMIT 1];
        return !transactions.isEmpty();
    }

    @AuraEnabled
    public static Boolean createLoanTransaction(String loanApplicationId) {
        try {
            Opportunity loanApplication = [SELECT Id, Final_Amount__c FROM Opportunity where Id =:loanApplicationId];
            Id transactionRecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get(constants.get('Transaction_Detail_Record_type')).getRecordTypeId();
            system.debug('transactionRecordTypeId:: '+transactionRecordTypeId);
            Loan_Transaction__c newTransaction = new Loan_Transaction__c(
                Loan_Application__c = loanApplicationId,
                RecordTypeId = transactionRecordTypeId
                //Schedule_Method__c = 'EQUAL',
                //Interest_Frequency__c = 'Monthly',
                //Disbursement_Amount__c = loanApplication.Final_Amount__c
                
            );
            insert newTransaction;
            return true;
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while creating the loan transaction: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean checkChargesAPI(Id recordId) {
        // Query Integration_Details__c based on specified criteria except Comments__c
        List<Integration_Details__c> integrationDetails = [
            SELECT Id, Comments__c FROM Integration_Details__c 
            WHERE EndPoint__c = :constants.get('Loan_Schedule_API_Endpoint') 
            AND Loan_Application__c = :recordId 
            AND Is_Success_Response__c = true 
            AND Calling_Source__c = :constants.get('Calling_Source_Loan_Schedule_API') 
            AND Status__c = '200'
        ];

        // Filter records by Comments__c in Apex code
        Boolean hasValidIntegrationDetail = false;
        for (Integration_Details__c detail : integrationDetails) {
            if (detail.Comments__c == constants.get('Charges_API_Invocation') ) {
                hasValidIntegrationDetail = true;
                break;
            }
        }

        if (hasValidIntegrationDetail) {
            // Query Charges_Insurance__c based on specified criteria
            List<Charges_Insurance__c> charges = [
                SELECT Id FROM Charges_Insurance__c 
                WHERE Loan_Application__c = :recordId 
                AND RecordType.Name = :constants.get('Charges_Record_Type') 
                AND Category__c = 'LOS'
            ];

            if (!charges.isEmpty()) {
                return true; // Charges API has been hit and charges exist
            }else{
                return false;
            }
        }
        // Return false if no valid integration detail is found
        return false;
    }


    @AuraEnabled
    public static List<Charges_Insurance__c> getChargesRecords(Id opportunityId) {
        try {
            return [SELECT Id, Name,Processing_fee_negotiated_percentage__c,Processing_fee_default_percentage__c, Is_Charges_waived__c,
                    Charges_Insurance__c,Category__c,Total_Charges__c,Total_Fee_to_be_deducted__c, Default_Amount_INR__c, 
                    Default_Percentage__c, Requested_Amount_INR__c,Min_Percent__c,Max_Percent__c, 
                    Requested_Percentage__c, Tax_INR__c, Final_Amount_INR__c, Percent_of_Loan_Amount__c, Tax__c,
                    Application_Applicant__c, Charges_Insurance_Master__c, Charges_Fee_Type__c,Loan_Application__c,Loan_Application__r.StageName,Loan_Application__r.Sub_stage__c,
                    Charges_Insurance_Master__r.Min_Value__c,Charges_Insurance_Master__r.Max_Value__c,RecordType.Name,Product_Name__c,Product__c,Waived_Charge_Amount__c,
                    VAS_Code__c,Total_VAS_Amount__c,Allocated_Amount__c,Adjusted_Login_Fee__c,Fee_Method__c,Login_Fees__c	,Balance_Login_Fees__c,Balance_Charge_Amount__c,Balance_Fees__c,Product__r.Product_Type__c,Negotiated_Percentage__c/*,Default_Charge_of_Sanction_Amount__c*/
                    FROM Charges_Insurance__c WHERE Loan_Application__c = :opportunityId AND 
                    RecordType.Name = :constants.get('Charges_Record_Type') AND Name != 'Login fee'];// Sanwar added Waived_Charge_Amount__c,Is_Charges_waived__c
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching records: ' + e.getMessage());
        }
    }


    @AuraEnabled
    public static String updateChargesRecords(List<SObject> updatedRecords, String productId, Decimal balanceFees) {
        Map<String, constants__mdt> constMap = constants__mdt.getAll();
        String Min_Max_Req_Amt_Error = constMap.containsKey('Min_Max_Req_Amt_Error') ? constMap.get('Min_Max_Req_Amt_Error').Value__c : 'Requested Amount can not be updated as its beyond threshold amount.';
        String Min_Max_Req_Percentage_Error	 = constMap.containsKey('Min_Max_Req_Percentage_Error') ? constMap.get('Min_Max_Req_Percentage_Error').Value__c : 'Requested Percentage is beyond threshold percentage.';
            System.debug('updatedRecords====>' + updatedRecords);
            List<Charges_Insurance__c> chargesToValidate = new List<Charges_Insurance__c>();
            Set<Id> oppIds = new Set<Id>();

            for (SObject record : updatedRecords) {
                if (record instanceof Charges_Insurance__c) {
                    Charges_Insurance__c rec = (Charges_Insurance__c)record;
                    chargesToValidate.add(rec);
                    if (rec.Loan_Application__c != null && rec.Category__c != 'LMS') {
                        oppIds.add(rec.Loan_Application__c);
                    }
                }
            }

            // Step 2: Fetch Opportunities with Negotiated_Loan_Amount__c
            // Map<Id, Product2> prodMap = new Map<Id, Product2>(
            //     [SELECT Id, Negotiated_Loan_Amount__c FROM Product2 WHERE Loan_Application__c IN :oppIds and Product__c = :productId]
            // );
            Product2 prodMap = [SELECT Id, Negotiated_Loan_Amount__c FROM Product2 WHERE Loan_Application__c IN :oppIds and Product__c = :productId limit 1];

            // Step 3: Validate each record
            for (Charges_Insurance__c rec : chargesToValidate) {
                system.debug('rec:: '+rec);
                if (rec.Requested_Amount_INR__c != null &&
                    rec.Min_Percent__c != null &&
                    rec.Max_Percent__c != null &&
                    rec.Loan_Application__c != null && rec.Category__c == 'LOS') {
                    
                    Product2 prod = prodMap;
                    if (prod != null && prod.Negotiated_Loan_Amount__c != null) {
                        Decimal negotiatedLoanAmt = prod.Negotiated_Loan_Amount__c;
                        Decimal minAllowed = (rec.Min_Percent__c / 100) * negotiatedLoanAmt;
                        system.debug('minAllowed:: '+minAllowed);
                        Decimal maxAllowed = (rec.Max_Percent__c / 100) * negotiatedLoanAmt;
                        system.debug('maxAllowed:: '+maxAllowed);

                        // if (rec.Requested_Amount_INR__c < minAllowed || rec.Requested_Amount_INR__c > maxAllowed) {
                        //     system.debug('I am inside:: '+rec.Requested_Amount_INR__c);
                        //     throw new AuraHandledException('Requested Amount should be between ' + minAllowed.setScale(0) + ' and ' + maxAllowed.setScale(0)); //Sanwar
                        // }
                        if (rec.Requested_Amount_INR__c > balanceFees) {
                            throw new AuraHandledException('Negotiated Fee cannot be greater than Balance Fee'); 
                        }
                        // if (rec.Requested_Amount_INR__c < minAllowed) {
                        //     system.debug('I am inside:: '+rec.Requested_Amount_INR__c);
                        //     throw new AuraHandledException('Requested Amount should be greater than ' + minAllowed.setScale(0)); //Sanwar
                        // }
                    }
                }
                if (rec.Category__c == 'LMS' && rec.Requested_Percentage__c != null && rec.Min_Percent__c != null && rec.Max_Percent__c != null) {
                    if (rec.Requested_Percentage__c < rec.Min_Percent__c || rec.Requested_Percentage__c > rec.Max_Percent__c) {
                        system.debug('I am inside 2:: '+rec.Requested_Percentage__c);
                        throw new AuraHandledException(Min_Max_Req_Percentage_Error);
                    }
                }
            }
            update updatedRecords;
            List<Charges_Insurance__c> relatedInsuranceRecordsToUpdate = new List<Charges_Insurance__c>();
            List<Charges_Insurance__c> parsedRecords = new List<Charges_Insurance__c>();
            Set<Id> recordIds = new Set<Id>();
            String feeMethod;
            Decimal pospAmount = 0;
            Decimal disbAmount = 0;
            // Check for null values and handle them
            for (SObject record : updatedRecords) {
                system.debug('record:: '+record);
                Charges_Insurance__c chargesRecord = (Charges_Insurance__c) record;
                system.debug('chargesRecord:: '+chargesRecord);
                system.debug('chargesRecord.Id:: '+chargesRecord.Id);
                system.debug('chargesRecord.Fee_Method__c:: '+chargesRecord.Fee_Method__c);
                if(chargesRecord.Id != null){
                    parsedRecords.add(chargesRecord);
                    recordIds.add(chargesRecord.Id);
                    feeMethod = chargesRecord.Fee_Method__c;
                }
            }
            String relatedInsuranceId;
            Map<String, String> relatedInsuranceRecordsMap = new Map<String, String>();

            List<Charges_Insurance__c> updatedRec = new List<Charges_Insurance__c>();
            updatedRec = [SELECT Id, Related_Insurance__c FROM Charges_Insurance__c WHERE Id IN :recordIds];
            system.debug('updatedRec:: '+updatedRec);
            for(Charges_Insurance__c record : updatedRec){
                relatedInsuranceId = record.Related_Insurance__c;
                system.debug('relatedInsuranceId:: '+relatedInsuranceId);
            }
            relatedInsuranceRecordsMap.put(relatedInsuranceId,feeMethod);
            system.debug('relatedInsuranceRecordsMap:: '+relatedInsuranceRecordsMap);

            // Update related insurance records
            List<Charges_Insurance__c> relatedInsuranceRecords = [SELECT Id, Fee_Method__c FROM Charges_Insurance__c WHERE Id IN :relatedInsuranceRecordsMap.keySet()];
            for (Charges_Insurance__c relatedRecord : relatedInsuranceRecords) {
                relatedRecord.Fee_Method__c = relatedInsuranceRecordsMap.get(relatedRecord.Id);
                relatedInsuranceRecordsToUpdate.add(relatedRecord);
            }

            if (!relatedInsuranceRecordsToUpdate.isEmpty()) {
                update relatedInsuranceRecordsToUpdate;
            }

            System.debug('updatedRecords after update====>' + updatedRecords);

            Decimal totalChargeFee = 0;
            Decimal totalchargedect = 0;
            Charges_Insurance__c totalFeechargeRecord = new Charges_Insurance__c();
            Product2 productRecord = [SELECT Id, Sanctioned_Loan_Amount__c, Final_Loan_Amount__c FROM Product2 WHERE Id =:productId AND Loan_Application__c =:parsedRecords[0].Loan_Application__c];
            List<Charges_Insurance__c> newUpdatedRecords = new List<Charges_Insurance__c>();

            for (Charges_Insurance__c record : [SELECT Id, Charges_Insurance__c, Total_Charges__c, Total_Fee_to_be_deducted__c, Name, Category__c, Default_Amount_INR__c, Default_Percentage__c, Requested_Amount_INR__c, 
            Requested_Percentage__c, Tax_INR__c, Final_Amount_INR__c, Percent_of_Loan_Amount__c, 
            Application_Applicant__c, Charges_Insurance_Master__c, Charges_Fee_Type__c, Loan_Application__c,
            Charges_Insurance_Master__r.Min_Value__c, Charges_Insurance_Master__r.Max_Value__c, RecordType.Name,
            VAS_Code__c, Total_VAS_Amount__c, Fee_Method__c
            FROM Charges_Insurance__c WHERE Loan_Application__c = :parsedRecords[0].Loan_Application__c AND (Self_Funded__c = FALSE OR RecordType.Name != 'Insurance') AND Product__c =:productId]) {
                
                if (record.Charges_Insurance__c == null && record.Name == 'Total Charges') {
                    totalFeechargeRecord = record;
                }
                
                if (record.Charges_Insurance__c != null && record.Category__c == 'LOS' && record.Final_Amount_INR__c != null) {
                    totalChargeFee += record.Final_Amount_INR__c;
                }
                if (record.Charges_Insurance__c != null && record.Category__c == 'LOS' && record.Final_Amount_INR__c != null && record.Fee_Method__c != 'Pay Upfront') {
                    totalchargedect += record.Final_Amount_INR__c;
                }
                system.debug('Fee_Method__c:: '+record.Fee_Method__c);
                if (record.Fee_Method__c == 'POSP' && record.Final_Amount_INR__c != null) {
                    pospAmount += record.Final_Amount_INR__c; // Accumulate POSP amounts
                }
                /*else if (record.Fee_Method__c == 'DISB' && record.Final_Amount_INR__c != null) {
                    disbAmount += record.Final_Amount_INR__c; // Accumulate DISB amounts
                }*/
                system.debug('pospAmount:: '+pospAmount);
            }

            System.debug('totalFeeRecord====>' + totalChargeFee);
            System.debug('totalChargesRecord====>' + totalchargedect);

            totalFeechargeRecord.Total_Charges__c = totalChargeFee;
            totalFeechargeRecord.Total_Fee_to_be_deducted__c = totalchargedect;
            update totalFeechargeRecord;
            // Update loan application's final amount considering both POSP and DISB
        if (pospAmount > 0 || disbAmount > 0) {
            // Start with the sanction loan amount
            Decimal finalAmount = productRecord.Sanctioned_Loan_Amount__c != null ? productRecord.Sanctioned_Loan_Amount__c : 0;
            
            // Add POSP amount if any
            if (pospAmount > 0) {
                finalAmount += pospAmount;
            }
            
            Product2 prodToUpdate = new Product2();//Sanwar - Start - Updating only Fuinal Amount due validation rules
            prodToUpdate.Id = productRecord.Id;
            prodToUpdate.Final_Loan_Amount__c = finalAmount;
            
            system.debug('productRecord.Final_Loan_Amount__c:: '+prodToUpdate.Final_Loan_Amount__c);
            Database.update(prodToUpdate, AccessLevel.SYSTEM_MODE);//Sanwar - End - Updating only Fuinal Amount due validation rules
        }           

            return 'Records updated successfully';
        /*} catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }*/
    }

    

    @AuraEnabled
    public static void updateTotalCharges(List<Charges_Insurance__c> totalChargesRecord) {
        try {
            update totalChargesRecord;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to update total charges: ' + e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true)
    public static Map<String, String> getPicklistValues() {
        Map<String, String> picklistMap = new Map<String, String>();
        try {
            Schema.DescribeFieldResult fieldResult = Charges_Insurance__c.Charges_Fee_Type__c.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

            for (Schema.PicklistEntry entry : picklistValues) {
                picklistMap.put(entry.getValue(), entry.getLabel()); // API Name → Label
            }
            return picklistMap;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching picklist values: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
	public static Boolean canUserEditChargesPricing(String opportunityId) {
        Utility_V1.ProductWrapper wrp = Utility_V1.getProductDetails(new Map<String,String>{'oppId' => opportunityId});
        Boolean isHLRelated = wrp.isHLRelated;
		Opportunity opp = [SELECT Id, StageName, Sub_stage__c, Pricing_Approval_Status__c, Loan_Hierarchy__c, Product__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        if(isHLRelated){
            return true;
        }
        /*if(opp.Product__c == 'Home Loan'){ //editable in all cases for HL. Given by Neeti on 10th December >> 23rd March 2026 > commenting this and moving this to HL check thats above
            return true;
        }*/
        List<Loan_Transaction__c> loanTxn = [SELECT Id, Quick_Disbursement__c, QDP_Status__c, STP__c, RecordType.DeveloperName, Loan_Application__c FROM Loan_Transaction__c WHERE Loan_Application__c= :opportunityId
        AND RecordType.DeveloperName = 'Transaction_Details' LIMIT  1];
		final Boolean isQDP = !loanTxn.isEmpty() && loanTxn[0].Quick_Disbursement__c && loanTxn[0].QDP_Status__c == 'Awaiting for confirmation'; //Armann : removed htis check QDP-ONHOLD
        if (isQDP || (opp.Sub_stage__c == 'Ops Author' || opp.Sub_stage__c == 'Disbursed')) {
            return false;
        }
		return true; 
	}

    @AuraEnabled
    public static Map<String, Object> getLoginFee(String recordId) {

        Map<String, Object> response = new Map<String, Object>();

        Charges_Insurance__c charges = [
            SELECT Id, Name, Login_Fees__c, Requested_Amount_INR__c,
                Receipt_No_PSV__c, Remarks_PSV__c, 
                Sub_Receipt_Mode_PSV__c, Transaction_Reference_PSV__c
            FROM Charges_Insurance__c
            WHERE Loan_Application__r.Id = :recordId
            AND Requested_Amount_INR__c != NULL
            AND Charges_Fee_Type__c = 'Login Fee'
            LIMIT 1
        ];

        // Add values to the map
        response.put('loginFee', charges.Requested_Amount_INR__c);
        response.put('Id', charges.Id);
        response.put('receiptNo', charges.Receipt_No_PSV__c);
        response.put('remarks', charges.Remarks_PSV__c);
        response.put('subReceiptMode', charges.Sub_Receipt_Mode_PSV__c);
        response.put('transactionRef', charges.Transaction_Reference_PSV__c);

        return response;
    }
    

    @AuraEnabled
    public static List<Login_Fees__mdt> getMetadataRecords() {
        return [SELECT DeveloperName, Charge_Name__c, Is_GST_Applicable__c, Is_Waiver__c, Is_Balance_Fee_Editable__c, Is_Accrued_Amount_Editable__c, Is_Collected_Fees_Editable__c FROM Login_Fees__mdt];
    }

    @AuraEnabled
	public static Boolean canUserGenerateSanctionLetter(String opportunityId) {
		Opportunity opp = [
			SELECT Id, StageName, Sub_stage__c, Pricing_Approval_Status__c, Loan_Hierarchy__c 
			FROM Opportunity
			WHERE Id = :opportunityId
			LIMIT 1
		];

        List<Loan_Transaction__c> loanTxn =
            [SELECT Id,
                    Quick_Disbursement__c,
                    QDP_Status__c,
                    STP__c,
                    RecordType.DeveloperName,
                    Loan_Application__c
             FROM   Loan_Transaction__c
             WHERE  Loan_Application__c = :opportunityId
             AND    RecordType.DeveloperName = 'Transaction_Details'
             LIMIT  1];

		final Boolean isQDP = !loanTxn.isEmpty() && loanTxn[0].Quick_Disbursement__c && loanTxn[0].QDP_Status__c == 'Awaiting for confirmation';

        if (isQDP) {
            return false;
        }
		if (opp.StageName != 'Disbursement' || (opp.StageName == 'Disbursement' && opp.Sub_stage__c == 'Ops Maker' )) {
            return true;
		}
		return false;
    }
    
    @AuraEnabled
    public static void upsertLoginFeeRecord(String input) {
	    COMM_SalesLoginFeeController.LoginFeeWrapper lstRecords = (COMM_SalesLoginFeeController.LoginFeeWrapper)JSON.deserialize(input, COMM_SalesLoginFeeController.LoginFeeWrapper.Class);
		
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

        charge.Receipt_No_PSV__c = lstRecords.receiptNo;
        charge.Transaction_Reference_PSV__c = lstRecords.transactionRef;
        charge.Sub_Receipt_Mode_PSV__c = lstRecords.subReceiptMode;
        charge.Remarks_PSV__c = lstRecords.remarks;
        upsert charge;
    }
}