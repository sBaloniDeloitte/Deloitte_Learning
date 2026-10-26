public with sharing class AHL_LoanTransactionController {

    @AuraEnabled
    public static List<Screen_Field__c> getScreenDetails(String formIdentifier, String loanId) {
        try {
            List<Screen_Field__c> screenFields = new List<Screen_Field__c>();

            if (String.isNotBlank(loanId)) {
                // Fetch loan details from Opportunity
                List<Opportunity> loanList = [
                    SELECT Id, Login_Completion_Stage__c 
                    FROM Opportunity 
                    WHERE Id = :loanId AND Login_Completion_Stage__c != null
                ];

                if (!loanList.isEmpty()) {
                    // Fetch Screen Fields based on the given formIdentifier
                    screenFields = [
                        SELECT Id, Form_Name__c, Parent_Screen__r.Form_Name__c, Name, Parent_Screen__r.Screen_Sequence__c,
                               Parent_Screen__r.Master_Screen_Name__c, Screen_Object__c, Picklist_Dependent_On_RecordType__c,
                               Is_Picklist__c, Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c,
                               Field_Sequence__c, Applicable_For__c, Filtered_Picklist_Values__c, Field_Type__c, Is_Lookup__c,
                               Custom_Component_Name__c, Is_Controlling_Picklist__c, Dependent_Picklist__c, Read_Field_Name__c,
                               Read_Object_Name__c, Section_Seperator__c, Section_Name__c, Visibility_Controlled_By__c,
                               Visibility_Controlled_By_Value__c, Is_Hidden__c, Applicable_Login_Stage__c, Is_Disabled__c,
                               Maximum_Length__c, Is_Formula_Feild__c, Screen_Name__c
                        FROM Screen_Field__c
                        WHERE Is_Active__c = true 
                          AND Parent_Screen__r.Is_Screen_Active__c = true 
                          AND Parent_Screen__r.Form_Name__c = :formIdentifier
                        ORDER BY Field_Sequence__c ASC
                    ];
                }
            }
            return screenFields;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistValueWrapper> getPicklistValues(String storageObject, String storageField) {
        List<PicklistValueWrapper> picklistValues = new List<PicklistValueWrapper>();

        try {
            // Check if Object exists
            if (!Schema.getGlobalDescribe().containsKey(storageObject)) {
                throw new AuraHandledException('Invalid Object Name: ' + storageObject);
            }

            Schema.SObjectType objType = Schema.getGlobalDescribe().get(storageObject);
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();

            // Check if Field exists
            if (!objDescribe.fields.getMap().containsKey(storageField)) {
                throw new AuraHandledException('Invalid Field Name: ' + storageField);
            }

            Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get(storageField).getDescribe();

            // Ensure it is a picklist
            if (fieldDescribe != null && fieldDescribe.getType() == Schema.DisplayType.Picklist) {
                for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                    picklistValues.add(new PicklistValueWrapper(entry.getLabel(), entry.getValue()));
                }
            } else {
                throw new AuraHandledException('Field is not a Picklist: ' + storageField);
            }
        } catch (Exception e) {
            System.debug('Error in getPicklistValues: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving picklist values: ' + e.getMessage());
        }
        
        return picklistValues;
    }

    // Wrapper class for picklist values
    public class PicklistValueWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public PicklistValueWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class DetailsWrapper {
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public Object fieldValue;
        @AuraEnabled public Integer sequence;
        @AuraEnabled public Boolean isLookup;
        @AuraEnabled public String lookupFieldValue;
        @AuraEnabled public String fieldType;
        @AuraEnabled public Boolean isDisabled;
        @AuraEnabled public String storageObject;
        @AuraEnabled public Boolean isMandatory;
    }

    @AuraEnabled
    public static List<DetailsWrapper> getDetailsForDisbursement(String screenName, String loanId, String formIdentifier) {
        try {
            List<Screen_Field__c> screenFieldList = [
                SELECT Id, Field_Label__c, Storage_Field__c, Storage_Object__c, Field_Sequence__c, is_Lookup__c,Field_Type__c,Is_Disabled__c,Is_Mandatory__c
                FROM Screen_Field__c 
                WHERE Is_Active__c = true 
                  AND Parent_Screen__r.Is_Screen_Active__c = true 
                  AND Parent_Screen__r.Form_Name__c = :formIdentifier
                  AND Screen_Name__c = :screenName
                ORDER BY Field_Sequence__c ASC
            ];

            Map<String, List<String>> objectToFieldsMap = new Map<String, List<String>>();
            Map<String, String> fieldApiToLabelMap = new Map<String, String>();

            Map<String, SObject> objectValuesMap = new Map<String, SObject>();

            // Construct query mappings for each objectName
            for (Screen_Field__c field : screenFieldList) {
                if (!objectToFieldsMap.containsKey(field.Storage_Object__c)) {
                    objectToFieldsMap.put(field.Storage_Object__c, new List<String>());
                }
                objectToFieldsMap.get(field.Storage_Object__c).add(field.Storage_Field__c);
            }

            // Execute separate queries for each object outside the loop
            for (String objectName : objectToFieldsMap.keySet()) {
                List<String> fieldApiNames = objectToFieldsMap.get(objectName);
                List<SObject> result;
                String query;

                // Custom conditions for specific objects
                if (objectName == 'Loan_Transaction__c') {
                    query = 'SELECT Id, ' + String.join(fieldApiNames, ', ') + 
                            ' FROM ' + objectName + 
                            ' WHERE Loan_Application__c = :loanId AND RecordType.Name = \'Transaction Details\' LIMIT 1';
                } else if (objectName == 'Charges_Insurance__c') {
                    query = 'SELECT Id, ' + String.join(fieldApiNames, ', ') + 
                            ' FROM ' + objectName + 
                            ' WHERE Loan_Application__c = :loanId AND RecordType.Name = \'Insurance\' LIMIT 1';
                } else {
                    query = 'SELECT Id, ' + String.join(fieldApiNames, ', ') + 
                            ' FROM ' + objectName + 
                            ' WHERE Loan_Application__c = :loanId LIMIT 1';
                }

                System.debug('Executing Query: ' + query);

                // Run the query outside the loop to avoid performance issues
                result = Database.query(query);
                
                if (!result.isEmpty()) {
                    objectValuesMap.put(objectName, result[0]);
                }
            }


            List<DetailsWrapper> rowFields = new List<DetailsWrapper>();
            for (Screen_Field__c field : screenFieldList) {
                if (objectValuesMap.containsKey(field.Storage_Object__c)) {
                    SObject sObj = objectValuesMap.get(field.Storage_Object__c);
                    DetailsWrapper dw = new DetailsWrapper();
                    dw.fieldLabel = field.Field_Label__c;
                    dw.fieldApiName = field.Storage_Field__c;
                    dw.sequence = Integer.valueOf(field.Field_Sequence__c);
                    dw.isLookup = field.is_Lookup__c;
                    dw.fieldType = field.Field_Type__c;
                    dw.isDisabled = field.Is_Disabled__c;
                    dw.storageObject = field.Storage_Object__c;
                    dw.isMandatory = field.Is_Mandatory__c;

                    if (field.is_Lookup__c) {
                        dw.fieldValue = sObj.get(field.Storage_Field__c);
                        String[] lookupField = field.Storage_Field__c.split('\\.');
                        dw.lookupFieldValue = String.valueOf(sObj.get(lookupField[0].replace('__r', '__c')));
                    } else {
                        dw.fieldValue = sObj.get(field.Storage_Field__c);
                    }

                    rowFields.add(dw);
                }
            }

            return rowFields;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching loan details: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<DetailsWrapper> getDetailsForPayment(String screenName, String loanId, String formIdentifier) {
        try {
            // Get all fields from Screen_Field__c for the given screen
            List<Screen_Field__c> screenFieldList = [
                SELECT Id, Field_Label__c, Storage_Field__c, Storage_Object__c, Field_Sequence__c, 
                    is_Lookup__c, Field_Type__c, Is_Disabled__c, Is_Picklist__c,Is_Mandatory__c
                FROM Screen_Field__c 
                WHERE Is_Active__c = true 
                AND Parent_Screen__r.Is_Screen_Active__c = true 
                AND Parent_Screen__r.Form_Name__c = :formIdentifier 
                AND Screen_Name__c = :screenName
                ORDER BY Field_Sequence__c ASC
            ];
            
            List<DetailsWrapper> rowFields = new List<DetailsWrapper>();

            // Loop through the metadata and return empty values for UI
            for (Screen_Field__c field : screenFieldList) {
                DetailsWrapper dw = new DetailsWrapper();
                dw.fieldLabel = field.Field_Label__c;
                dw.fieldApiName = field.Storage_Field__c;
                dw.sequence = Integer.valueOf(field.Field_Sequence__c);
                dw.isLookup = field.is_Lookup__c;
                dw.fieldType = field.Field_Type__c;
                dw.isDisabled = field.Is_Disabled__c;
                dw.storageObject = field.Storage_Object__c;
                dw.isMandatory = field.Is_Mandatory__c;
                
                // No existing value since we're creating new records
                dw.fieldValue = ''; // Always empty for new creation
                
                rowFields.add(dw);
            }

            return rowFields;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching payment fields: ' + e.getMessage());
        }
    }


     @AuraEnabled
    public static List<DetailsWrapper> getDetailsForBank(String loanId, String formIdentifier) {
        try {
            // Get all fields from Screen_Field__c for the given screen
            List<Screen_Field__c> screenFieldList = [
                SELECT Id, Field_Label__c, Storage_Field__c, Storage_Object__c, Field_Sequence__c, 
                    is_Lookup__c, Field_Type__c, Is_Disabled__c, Is_Picklist__c,Is_Mandatory__c
                FROM Screen_Field__c 
                WHERE Is_Active__c = true 
                AND Parent_Screen__r.Is_Screen_Active__c = true 
                AND Parent_Screen__r.Form_Name__c = :formIdentifier 
                ORDER BY Field_Sequence__c ASC
            ];
            
            List<DetailsWrapper> rowFields = new List<DetailsWrapper>();

            // Loop through the metadata and return empty values for UI
            for (Screen_Field__c field : screenFieldList) {
                DetailsWrapper dw = new DetailsWrapper();
                dw.fieldLabel = field.Field_Label__c;
                dw.fieldApiName = field.Storage_Field__c;
                dw.sequence = Integer.valueOf(field.Field_Sequence__c);
                dw.isLookup = field.is_Lookup__c;
                dw.fieldType = field.Field_Type__c;
                dw.isDisabled = field.Is_Disabled__c;
                dw.storageObject = field.Storage_Object__c;
                dw.isMandatory = field.Is_Mandatory__c;
                
                // No existing value since we're creating new records
                dw.fieldValue = ''; // Always empty for new creation
                
                rowFields.add(dw);
            }

            return rowFields;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching payment fields: ' + e.getMessage());
        }
    }



    @AuraEnabled
    public static date getLoanStartDate(string loanId) {
        //Utility_V1.ProductWrapper wrp = Utility_V1.getProductDetails(new Map<String,String>{'oppId' => loanId});
        Date loanStartDate;
        /*Boolean isHLRelated = wrp.isHLRelated;
        if(isHLRelated){
            loanStartDate = [Select Id, Loan_Start_Date__c, Product__r.Product_Type__c, Product__c From Loan_Transaction__c Where Loan_Application__c =: loanId And RecordType.Name = 'Transaction Details' AND Product__c!=null AND Product__r.Product_Type__c = 'Parent' LIMIT 1].Loan_Start_Date__c;
    }
        else{*/
            loanStartDate = [Select Id, Loan_Start_Date__c, Product__r.Product_Type__c, Product__c From Loan_Transaction__c Where Loan_Application__c =: loanId And RecordType.Name = 'Transaction Details' LIMIT 1].Loan_Start_Date__c;
        //}
        return loanStartDate;
    }
        

    @AuraEnabled
    public static Integer getNextPaymentSequence(String loanId) {
        try {
            List<Loan_Transaction__c> payments = [
                SELECT Payment_Sequence__c FROM Loan_Transaction__c
                WHERE Loan_Application__c = :loanId AND RecordType.Name = 'Payment'
                ORDER BY CreatedDate DESC LIMIT 1
            ];

            // Ensure proper increment
            if (!payments.isEmpty() && payments[0].Payment_Sequence__c != null) {
                return Integer.valueOf(payments[0].Payment_Sequence__c.intValue() + 1);
            } else {
                return 1;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error calculating payment sequence: ' + e.getMessage());
        }
    }

    public static String extractPartnerBankName(List<PicklistValueWrapper> partnerBankPicklist,String code){
        for(PicklistValueWrapper pc : partnerBankPicklist){
            if(pc.value == code){
                return pc.label;
            }
        }
        return '';
    }


    @AuraEnabled
    public static Map<String, Object> getPaymentTableRecords(String loanId) {
        Map<String, Object> responseMap = new Map<String, Object>();
        
        try {
            List<PicklistValueWrapper> partnerBankPicklist = getPicklistValues('Loan_Transaction__c','Partner_bank__c');
            

            // Query to get Payment Records (Loan Transaction records)
            List<Map<String, Object>> paymentRecords = new List<Map<String, Object>>();
            List<Loan_Transaction__c> payments = [
                SELECT Id,Payment_Sequence__c, Disbursement_Party__c, Disbursement_Type__c,Scheduled_Disbursement_Date__c,Related_Transaction__c,
                Bank__c, Application_Applicant__r.Name, Customer_Name__c,Disbursement_Amount__c, Partner_bank__c,IFSC__c,
                Account_Holder_Name__c,Favoring_Name__c,Account_Number__c,Cheque_DD_Number__c,Status__c, Net_Amount__c,QDP_Status__c 
                FROM Loan_Transaction__c
                WHERE Loan_Application__c = :loanId
                AND RecordType.Name = 'Payment'
                ORDER BY Payment_Sequence__c ASC
            ];

            for (Loan_Transaction__c payment : payments) {
                Map<String, Object> paymentData = new Map<String, Object>{
                    'id' => payment.Id,
                    'paymentSequence' => payment.Payment_Sequence__c != null ? String.valueOf(payment.Payment_Sequence__c) : '' ,
                    'disbursementParty' => payment.Disbursement_Party__c,
                    'disbursementType' => payment.Disbursement_Type__c,
                    'bank' => payment.Bank__c,
                    'name' => String.isNotBlank(payment.Account_Holder_Name__c) ? 
                                                payment.Account_Holder_Name__c : 
                                                (String.isNotBlank(payment.Favoring_Name__c) ? 
                                                    payment.Favoring_Name__c : 
                                                    (payment.Application_Applicant__r != null ? 
                                                        payment.Application_Applicant__r.Name : 
                                                        null)
                                                ),
                    'accountChequeDD' => String.isNotBlank(payment.Account_Number__c)?
                    payment.Account_Number__c : String.isNotBlank(payment.Cheque_DD_Number__c) ?
                    payment.Cheque_DD_Number__c : null,                   
                    'amount' => payment.Net_Amount__c,
                    'qdpStatus' => payment.QDP_Status__c,
                    'isActionsRequired' => payment.Disbursement_Party__c != 'VAS',
                    'partnerBank' => extractPartnerBankName(partnerBankPicklist,payment.Partner_bank__c),
                    'ifsc' => payment.IFSC__c,
                    'disbursementDate' => payment.Scheduled_Disbursement_Date__c != null ? DateTime.newInstance(payment.Scheduled_Disbursement_Date__c, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd') : '',//format('dd-MM-yyyy') : '',
                    'enableRefresh' => payment.Disbursement_Party__c == 'VAS',
                    'transactionId' => payment.Related_Transaction__c //added by Arman on 26-11 to fetch the parent transactionid
                };
                paymentRecords.add(paymentData);
            }
            responseMap.put('paymentRecords', paymentRecords);
            return responseMap;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching payment records: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<SObject> getApplicantsForLoan(String loanId, List<String> applicantType) {
        try {
            System.debug('loan Id'+ loanId);
            System.debug('applicant type'+ applicantType);
            
            Opportunity opp = [select Id,Loan_Hierarchy__c,Split_Parent_Loan_Application__c from Opportunity where Id = :loanId LIMIT 1];
            if(opp.Loan_Hierarchy__c == 'Child' && opp.Split_Parent_Loan_Application__c != null){
                loanId = opp.Split_Parent_Loan_Application__c;
            }

            List<SObject> applicants = [
                SELECT Id, Name, Applicant_Type__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId AND Applicant_Type__c IN : applicantType
            ];
            return applicants;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching applicants: ' + e.getMessage());
        }
    }

    @AuraEnabled //Sanwar
    public static List<SObject> getApplicantsForBuilderApf(String loanId) {
        try {      
            Opportunity opp = [select Id,Loan_Hierarchy__c,Split_Parent_Loan_Application__c from Opportunity where Id = :loanId LIMIT 1];
            if(opp.Loan_Hierarchy__c == 'Child' && opp.Split_Parent_Loan_Application__c != null){
                loanId = opp.Split_Parent_Loan_Application__c;
            }     
            List<SObject> applicants = [
                Select Id, Collateral__c , Collateral__r.Builder__r.Name From Application_Collateral__c  Where HL_Loan_Application__c =:loanId AND Collateral__r.Builder__c != null
            ];
            return applicants;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching applicants: ' + e.getMessage());
        }
    }

    @AuraEnabled //Sanwar 
    public static List<SObject> getBankDetailsForBuilderApf(String applicantCollateralId) {
        try {           
            Application_Collateral__c bankDetails = [
                Select Id, Collateral__c , Collateral__r.Builder__r.Name, Collateral__r.Project__c From Application_Collateral__c  Where Id =:applicantCollateralId And Collateral__r.Builder__c != null Limit 1
            ];
            
            List<Bank_Details__c> bankDetailsList = [SELECT Id, Account_Holder_Name__c, Name, Account_Number__c, Account_Type__c, 
                OD_CC_Limit__c, ABB__c, Source__c, Application_Applicant__r.Applicant_Type__c, Application_Applicant__r.Mobile_Number__c,
                Bank_Master__r.Name, Bank_Master__r.IFSC__c,  Bank_Master__r.MICR__c, Is_Repayment_Account__c, Bank_Master__r.Branch_Name__c, 
                Bank_Master__r.Branch_Location__c
                FROM Bank_Details__c
                WHERE Project_Name__c = :bankDetails.Collateral__r.Project__c ];
            return bankDetailsList;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching data: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String savePaymentTransaction(Map<String, Object> paymentRecordData, Map<String, Object> beneficiaryData, Map<String, Object> chequeDDData, String loanId, String selectedCusBankDetailId) {
        try {
            if (paymentRecordData.isEmpty()) {
                return 'ERROR: No data received for saving.';
            }
            //sanwar 31/12/2025
            if (selectedCusBankDetailId != null && selectedCusBankDetailId != '' && beneficiaryData != null &&beneficiaryData.containsKey('Account_Number__c')){
                Bank_Details__c bankRec = new Bank_Details__c(
                    Id = selectedCusBankDetailId,
                    Account_Number__c = (String) beneficiaryData.get('Account_Number__c')
                );
                update bankRec;
            }


            
            // Fetch Payment Record Type ID dynamically
            Id paymentRecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByName().get('Payment').getRecordTypeId();
            Id transactionDetailsRecordTypeId = Schema.SObjectType.Loan_Transaction__c.getRecordTypeInfosByName().get('Transaction Details').getRecordTypeId();

            // Fetch latest Payment Sequence and increment
            Integer nextSequence = getNextPaymentSequence(loanId);
            // Step 1: Fetch existing Loan Transaction record (Transaction Details type)
            Loan_Transaction__c transactionDetails;
            try {
                List<Loan_Transaction__c> transactionList = [
                    SELECT Id FROM Loan_Transaction__c 
                    WHERE Loan_Application__c = :loanId
                    AND RecordTypeId = :transactionDetailsRecordTypeId
                    LIMIT 1
                ];
                transactionDetails = !transactionList.isEmpty() ? transactionList[0] : null;
            } catch (Exception e) {
                System.debug('No Transaction Details record found.');
                transactionDetails = null;
            }
            Loan_Transaction__c paymentRecord;
            Boolean isUpdate = false;

            if (paymentRecordData.containsKey('Id') && paymentRecordData.get('Id') != null) {
                Id existingRecordId = (Id) paymentRecordData.get('Id');
                paymentRecord = [SELECT Id FROM Loan_Transaction__c WHERE Id = :existingRecordId LIMIT 1];
                isUpdate = true;
            }else{
                paymentRecord = new Loan_Transaction__c();
                paymentRecord.RecordTypeId = paymentRecordTypeId;
                paymentRecord.Loan_Application__c = loanId; // Ensure Loan Application ID is linked
                paymentRecord.Related_Transaction__c = (transactionDetails != null) ? transactionDetails.Id : null;
                paymentRecord.Payment_Sequence__c = nextSequence;
                paymentRecord.Status__c = 'New';
                paymentRecord.QDP_Status__c = 'New';
            }

            // Dynamically populate fields for Loan_Transaction__c
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('Loan_Transaction__c').getDescribe().fields.getMap();

            for (String fieldName : paymentRecordData.keySet()) {
                if (fieldMap.containsKey(fieldName)) {
                    Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();

                    // Convert field values based on type
                    Object fieldValue = paymentRecordData.get(fieldName);
                    system.debug('fieldValue:: '+fieldValue);
                    if (fieldValue != null && String.valueOf(fieldValue).trim() != '') {
                        if (fieldDescribe.getType() == Schema.DisplayType.Date) {
                            paymentRecord.put(fieldName, Date.valueOf((String) fieldValue));
                        }else if (fieldDescribe.getType() == Schema.DisplayType.Double) {
                            paymentRecord.put(fieldName, Decimal.valueOf(String.valueOf(fieldValue)));
                        }else if (fieldDescribe.getType() == Schema.DisplayType.Integer) {
                            paymentRecord.put(fieldName, Integer.valueOf((String) fieldValue));
                        } else if (fieldDescribe.getType() == Schema.DisplayType.Boolean) {
                            paymentRecord.put(fieldName, Boolean.valueOf((String) fieldValue));
                        } else {
                            paymentRecord.put(fieldName, fieldValue);
                        }
                    }else{
                        paymentRecord.put(fieldName, null);
                    }
                }
            }

            // Step 3: Handle Beneficiary Details
            if (beneficiaryData != null && !beneficiaryData.isEmpty()) {
                for (String fieldName : beneficiaryData.keySet()) {
                    if (fieldMap.containsKey(fieldName)) {
                        Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();

                        Object fieldValue = beneficiaryData.get(fieldName);
                        if (fieldValue != null && String.valueOf(fieldValue).trim() != '') {
                            if (fieldDescribe.getType() == Schema.DisplayType.Date) {
                                paymentRecord.put(fieldName, Date.valueOf((String) fieldValue));
                            } else if (fieldDescribe.getType() == Schema.DisplayType.Double) {
                                paymentRecord.put(fieldName, Decimal.valueOf(String.valueOf(fieldValue)));
                            } else if (fieldDescribe.getType() == Schema.DisplayType.Integer) {
                                paymentRecord.put(fieldName, Integer.valueOf((String) fieldValue));
                            } else if (fieldDescribe.getType() == Schema.DisplayType.Boolean) {
                                paymentRecord.put(fieldName, Boolean.valueOf((String) fieldValue));
                            } else {
                                paymentRecord.put(fieldName, fieldValue);
                            }
                        }else{
                            paymentRecord.put(fieldName, null);
                        }
                    }
                }
            }

            
            // Step 4: Handle Third Party Disbursement & Bank Detail Creation

            if ((paymentRecord.Disbursement_Party__c == 'Third Party' || paymentRecord.Disbursement_Party__c =='Vendor') && !new Set<String>{'CHEQUE', 'DD - DEMAND DRAFT'}.contains(paymentRecord.Disbursement_Type__c)) {

                Bank_Details__c newBank = new Bank_Details__c();
                Map<String, Schema.SObjectField> bankFieldMap = Schema.getGlobalDescribe().get('Bank_Details__c').getDescribe().fields.getMap();

                for (String fieldName : beneficiaryData.keySet()) {
                    if (bankFieldMap.containsKey(fieldName)) {
                        newBank.put(fieldName, beneficiaryData.get(fieldName));
                    }
                }

                // **Ensure required fields are populated**
                if (!beneficiaryData.containsKey('Account_Type__c') || String.isBlank((String) beneficiaryData.get('Account_Type__c'))) {
                    return 'ERROR: Account Type is required for Bank Details.';
                }
                if (!beneficiaryData.containsKey('Account_Holder_Name__c') || String.isBlank((String) beneficiaryData.get('Account_Holder_Name__c'))) {
                    return 'ERROR: Account Holder Name is required for Bank Details.';
                }
                if (!beneficiaryData.containsKey('IFSC__c') || String.isBlank((String) beneficiaryData.get('IFSC__c'))) {
                    return 'ERROR: IFSC is required for Bank Details.';
                }

                String ifscCode = (String) beneficiaryData.get('IFSC__c');
                List<Bank_Branch_Master__c> bankBranchMasterData = [
                                            SELECT Id,Bank_Name__c,Bank_Code__c,Branch_Name__c,Branch_Code__c,Bank__r.Name
                                            FROM Bank_Branch_Master__c 
                                            WHERE IFSC__c  =: ifscCode AND Bank_Name__c != NULL AND Branch_Name__c != NULL LIMIT 1];
                                           
                if (bankBranchMasterData.isEmpty()){
                    return 'ERROR: IFSC is not available in the master, please contact admin.';
                }                            
                newBank.IFSC__c  = ifscCode;
                newBank.Bank_Master__c = bankBranchMasterData[0].Id;

                // Assign required values if they exist
                newBank.Account_Type__c = (String) beneficiaryData.get('Account_Type__c');
                newBank.Account_Holder_Name__c = (String) beneficiaryData.get('Account_Holder_Name__c');

                // Insert Bank Detail Record
                insert newBank;

                // Link Bank Details ID to Loan Transaction Record
                paymentRecord.Bank_Details__c = newBank.Id;
                paymentRecord.Bank__c = bankBranchMasterData[0].Bank_Name__c;
                paymentRecord.Bank_Branch__c = bankBranchMasterData[0].Branch_Name__c;
            }

            if (new Set<String>{'Builder','Customer','Seller'}.contains(paymentRecord.Disbursement_Party__c) && !new Set<String>{'CHEQUE', 'DD - DEMAND DRAFT'}.contains(paymentRecord.Disbursement_Type__c)) {
                if(isUpdate == false || (isUpdate == true && selectedCusBankDetailId != null && selectedCusBankDetailId != '')){
                   paymentRecord.Bank_Details__c = (selectedCusBankDetailId != null && selectedCusBankDetailId != '') ? selectedCusBankDetailId : null;
                }
            }

            //Step 5: Handle Cheque/DD Details
            if (chequeDDData != null && !chequeDDData.isEmpty()) {
                for (String fieldName : chequeDDData.keySet()) {
                    if (fieldMap.containsKey(fieldName)) {
                        Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                        Object fieldValue = chequeDDData.get(fieldName);
                        if (fieldValue != null && String.valueOf(fieldValue).trim() != '') {
                            if (fieldDescribe.getType() == Schema.DisplayType.Date) {
                                paymentRecord.put(fieldName, Date.valueOf((String) fieldValue));
                            } else if (fieldDescribe.getType() == Schema.DisplayType.Double) {
                                paymentRecord.put(fieldName, Decimal.valueOf(String.valueOf(fieldValue)));
                            } else if (fieldDescribe.getType() == Schema.DisplayType.Integer) {
                                paymentRecord.put(fieldName, Integer.valueOf((String) fieldValue));
                            } else if (fieldDescribe.getType() == Schema.DisplayType.Boolean) {
                                paymentRecord.put(fieldName, Boolean.valueOf((String) fieldValue));
                            } else {
                                paymentRecord.put(fieldName, fieldValue);
                            }
                        }else{
                                paymentRecord.put(fieldName, null);
                        }
                        //paymentRecord.put(fieldName, chequeDDData.get(fieldName));
                    }
                }
            }
            system.debug('Payment record:: '+paymentRecord);
            // Step 6: Insert Loan Transaction Record
            
            // Insert or Update based on flag
            if (isUpdate) {
                update paymentRecord;
            } else {
                insert paymentRecord;
            }

            return 'SUCCESS';

        } catch (Exception e) {
            System.debug('ERROR in savePaymentTransaction: ' + e.getMessage());
            return 'ERROR: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static string saveBankDetailRecord(Bank_Details__c bankRecords, String applicantId){
        try{
            if (bankRecords==null) {
            return 'ERROR: No data received for saving.';
            }
            //sanwar(12/12/2025)
            String recordIdObjName = getObjectApiNameFromId(applicantId);//sanwar(12/12/2025)
            if(recordIdObjName == 'Application_Collateral__c'){
                Application_Collateral__c bankDetails = [
                    SELECT Id, Collateral__c , Collateral__r.Builder__r.Name, Collateral__r.Project__c 
                    FROM Application_Collateral__c  
                    WHERE Id =:applicantId 
                    AND Collateral__r.Builder__c != null Limit 1
                ];
                bankRecords.Project_Name__c = bankDetails.Collateral__r.Project__c;
            }
            else{
                bankRecords.Application_Applicant__c = applicantId;
            }
            insert bankRecords;
            
            return bankRecords.Id;
        }catch (Exception e) {
            System.debug('ERROR in saveBankDetails: ' + e.getMessage() + e.getLineNumber());
            return 'ERROR: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static String uploadFile(String base64Data, String fileName, String fileType, String recordId, String selecteddocCheckId) {
        try {
            System.debug('selecteddocCheckId: ' + selecteddocCheckId);
            
            if (base64Data != null && fileName != null && fileType != null) {
                Blob fileBlob = EncodingUtil.base64Decode(base64Data);
                System.debug('File Name: ' + fileName);
                System.debug('File Type: ' + fileType);
                System.debug('Record ID: ' + recordId);

                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = fileName;
                contentVersion.PathOnClient = fileName;
                contentVersion.VersionData = fileBlob;
                contentVersion.ContentLocation = 'S'; // Storing in Salesforce
                insert contentVersion;

                String contentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
                System.debug('Uploaded Content ID: ' + contentId);

                List<Document_Master__c> docMaster = [SELECT Id, Name, Requirement_Level__c 
                                                    FROM Document_Master__c 
                                                    WHERE Requirement_At__c = 'Loan Application' 
                                                    AND Name = 'Other' LIMIT 1];

                Document_Details__c doc = new Document_Details__c();
                doc.Status__c = 'Uploaded';
                doc.Content_Document_Id__c = contentId;
                doc.Name = docMaster[0].Name;
                doc.Requirement_Level__c = docMaster[0].Requirement_Level__c;
                doc.Loan_Application__c = recordId;
doc.Loan_Transaction__c = selecteddocCheckId;
                insert doc;

                System.debug('File uploaded successfully: ' + contentId);
                return contentId; // Return ContentDocumentId to JavaScript

            } else {
                System.debug('Missing required parameters for file upload.');
                return null;
            }
        } catch (Exception exp) {
            System.debug('Exception in uploadFile: ' + exp.getMessage());
            return null;
        }
    }

    @AuraEnabled
    public static Document_Details__c getUploadedDocument(String contentId) {
        try {
            return [SELECT Id, Content_Document_Id__c FROM Document_Details__c 
                    WHERE Content_Document_Id__c = :contentId LIMIT 1];
        } catch (Exception e) {
            System.debug('Error fetching uploaded document: ' + e.getMessage());
            return null;
        }
    }

    @AuraEnabled
    public static Id getUploadedDocumentPerLT(String loanTxnId) {
        try {
            List<Document_Details__c> docs = [
                SELECT Content_Document_Id__c 
                FROM Document_Details__c 
                WHERE Loan_Transaction__c = :loanTxnId 
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];

            if (docs.isEmpty()) {
                return null;
            }

            return docs[0].Content_Document_Id__c;

        } catch (Exception e) {
            System.debug('Error fetching uploaded document: ' + e.getMessage());
            return null;
        }
    }
   
    @AuraEnabled
    public static Decimal getTotalFee(String loanId) {
        try {
            Charges_Insurance__c totalChargesRecord = [
                SELECT Total_Fee_to_be_deducted__c 
                FROM Charges_Insurance__c
                WHERE Loan_Application__c = :loanId 
                AND Name = 'Total Charges'
                LIMIT 1
            ];
            
            return totalChargesRecord != null ? totalChargesRecord.Total_Fee_to_be_deducted__c : 0;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Total Fee: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Decimal getInsuranceAmount(String loanId) {
        try {
            Charges_Insurance__c insuranceRecord = [
                SELECT Total_VAS_Amount__c 
                FROM Charges_Insurance__c
                WHERE Loan_Application__c = :loanId 
                AND RecordType.Name = 'Insurance'
                LIMIT 1
            ];
            
            return (insuranceRecord != null) ? insuranceRecord.Total_VAS_Amount__c : 0;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Insurance Amount: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Decimal> getDisbursalDetails(String loanId) {
        try {
            Map<String, Decimal> disbursalData = new Map<String, Decimal>();

            Opportunity opp = [select Id,Product__c,Loan_Hierarchy__c,Split_Parent_Loan_Application__c from Opportunity where Id = :loanId LIMIT 1];
            String productName = opp.Product__c;
            String requiredLoanId = loanId;
            if(opp.Loan_Hierarchy__c == 'Child' && opp.Split_Parent_Loan_Application__c != null){
                requiredLoanId = opp.Split_Parent_Loan_Application__c;
            }

            // Fetch Total Fee from Charges_Insurance__c
            List<Charges_Insurance__c> totalChargesRecord = [
                SELECT Total_Fee_to_be_deducted__c 
                FROM Charges_Insurance__c
                WHERE Loan_Application__c = :requiredLoanId 
                AND Name = 'Total Charges' AND Product_Name__c = :productName
                LIMIT 1
            ];

            Decimal totalFee = !totalChargesRecord.isEmpty() ? totalChargesRecord[0].Total_Fee_to_be_deducted__c : 0;

            // Fetch Total Loan Amount from Loan_Transaction__c (since it's a formula, we don't need calculations)
            List<Loan_Transaction__c> loanTransaction = [
                SELECT Total_Loan_Amount__c , First_Disbursement_Amount__c
                FROM Loan_Transaction__c
                WHERE Loan_Application__c = :loanId AND RecordType.name = 'Transaction Details'
                LIMIT 1
            ];

            Decimal totalLoanAmount = !loanTransaction.isEmpty() ? loanTransaction[0].Total_Loan_Amount__c : 0;
            Decimal firstDisbursementAmount = !loanTransaction.isEmpty() ? loanTransaction[0].First_Disbursement_Amount__c : 0;

            // Calculate Total Disbursal Amount
            Decimal totalDisbursalAmount = totalLoanAmount - totalFee;
            Decimal totalDisbursedAmount = firstDisbursementAmount - totalFee;


            List<Charges_Insurance__c> insuranceRecords = [
                SELECT Total_VAS_Amount__c 
                FROM Charges_Insurance__c
                WHERE Loan_Application__c = :requiredLoanId 
                AND RecordType.Name = 'Insurance' AND Product_Name__c = :productName
                LIMIT 10
            ];

            Decimal totalInsurance = 0;
            if(!insuranceRecords.isEmpty()){            
                for (Charges_Insurance__c chargeInsurance : insuranceRecords) {
                    if(chargeInsurance.Total_VAS_Amount__c !=null){
                        totalInsurance += chargeInsurance.Total_VAS_Amount__c;
                    }
                }
            }
            // Store in map and return
            disbursalData.put('Total_Fee__c', totalFee);
            disbursalData.put('Total_Loan_Amount__c', totalLoanAmount);
            disbursalData.put('Total_Disbursal_Amount__c', totalDisbursalAmount);
            disbursalData.put('Insurance_Amount__c', totalInsurance);
            disbursalData.put('Total_Disbursed_Amount__c', totalDisbursedAmount);
            disbursalData.put('First_Disbursement_Amount__c',firstDisbursementAmount);

            return disbursalData;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Disbursal Details: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String updateFirstDisbursementAmount(String loanId, Decimal newAmount, Decimal totalDisbAmount) {
        try {
            Loan_Transaction__c loanTransaction = [
                SELECT Id, First_Disbursement_Amount__c, Total_Disbursed_Amount__c
                FROM Loan_Transaction__c
                WHERE Loan_Application__c = :loanId And RecordType.Name = 'Transaction Details'
                LIMIT 1
            ];
            
            if (loanTransaction != null) {
                loanTransaction.First_Disbursement_Amount__c = newAmount;
                loanTransaction.Total_Disbursed_Amount__c = totalDisbAmount;
                update loanTransaction;
                return 'SUCCESS:'+loanTransaction.Id ;
            }
            return 'ERROR: Loan Transaction not found.';
        } catch (Exception e) {
            return 'ERROR: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static List<DetailsWrapper> getPaymentRecord(String screenName, String loanId, String formIdentifier, String paymentRecordId){
        try {
            // Step 1: Fetch all active screen fields for the given screen
            List<Screen_Field__c> screenFieldList = [
                SELECT Id, Field_Label__c, Storage_Field__c, Storage_Object__c, Field_Sequence__c, 
                    is_Lookup__c, Field_Type__c, Is_Disabled__c, Is_Picklist__c,Is_Mandatory__c
                FROM Screen_Field__c 
                WHERE Is_Active__c = true 
                AND Parent_Screen__r.Is_Screen_Active__c = true 
                AND Parent_Screen__r.Form_Name__c = :formIdentifier 
                AND Screen_Name__c = :screenName
                ORDER BY Field_Sequence__c ASC
            ];
            // Step 2: Prepare a map to store object names and their corresponding fields
            Map<String, List<String>> objectToFieldsMap = new Map<String, List<String>>();
            for (Screen_Field__c field : screenFieldList) {
                if (!objectToFieldsMap.containsKey(field.Storage_Object__c)) {
                    objectToFieldsMap.put(field.Storage_Object__c, new List<String>());
                }
                objectToFieldsMap.get(field.Storage_Object__c).add(field.Storage_Field__c);
            }

            Map<String, SObject> queriedRecords = new Map<String, SObject>();
            // Step 3: Query the records dynamically based on paymentRecordId
            for (String objectName : objectToFieldsMap.keySet()) {
                List<String> fieldApiNames = objectToFieldsMap.get(objectName);
                String query = 'SELECT Id, ' + String.join(fieldApiNames, ', ') + 
                               ' FROM ' + objectName + 
                               ' WHERE Id = :paymentRecordId LIMIT 1';
    
                System.debug('Executing Query: ' + query);
    
                List<SObject> results = Database.query(query);
                if (!results.isEmpty()) {
                    queriedRecords.put(objectName, results[0]);
                }
            }
            // Step 4: Populate field details with queried values
            List<DetailsWrapper> fieldDetails = new List<DetailsWrapper>();

            for (Screen_Field__c field : screenFieldList) {
                if (queriedRecords.containsKey(field.Storage_Object__c)) {
                    SObject record = queriedRecords.get(field.Storage_Object__c);
                    DetailsWrapper dw = new DetailsWrapper();
                    dw.fieldLabel = field.Field_Label__c;
                    dw.fieldApiName = field.Storage_Field__c;
                    dw.sequence = Integer.valueOf(field.Field_Sequence__c);
                    dw.isLookup = field.is_Lookup__c;
                    dw.isDisabled = field.Is_Disabled__c;
                    dw.fieldType = field.Field_Type__c;
                    dw.isMandatory = field.Is_Mandatory__c;
                    dw.storageObject = field.Storage_Object__c;

                    // Fetching value from queried record
                    dw.fieldValue = record.get(field.Storage_Field__c);

                    fieldDetails.add(dw);
                }
            }

            return fieldDetails;

        } catch (Exception e) {
            System.debug('Error in getDetailsForPayment: ' + e.getMessage());
            throw new AuraHandledException('Error fetching payment details: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String deletePaymentRecord(String paymentRecordId) {
        try {
            if (String.isBlank(paymentRecordId)) {
                return 'ERROR: Invalid Payment Record ID.';
            }

            Loan_Transaction__c paymentRecord = [SELECT Id FROM Loan_Transaction__c WHERE Id = :paymentRecordId LIMIT 1];

            delete paymentRecord;
            return 'SUCCESS';
        } catch (Exception e) {
            return 'ERROR: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static Boolean updateDisbursementDate(String recordId){
        try {
            Loan_Transaction__c loanTransaction = [SELECT Loan_Start_Date__c, Scheduled_Disbursement_Date__c FROM Loan_Transaction__c WHERE Id =: recordId];
            loanTransaction.Scheduled_Disbursement_Date__c = loanTransaction.Loan_Start_Date__c;
            update loanTransaction;

            return true;
            
        } catch (Exception e) {
            System.debug('AHL_LoanTransactionController->updateDisbursementDate ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled //Sanwar
    public static Boolean getDisburmentPartyRecord(String disParty, String loanId){
            try {
                if(disparty == 'Builder' || disparty == 'Seller'){
                    List<Application_Applicant__c> records = [
                        SELECT Id 
                        FROM Application_Applicant__c 
                        WHERE Applicant_Type__c = :disParty 
                        AND Loan_Application__c = :loanId
                    ];
                    if (!records.isEmpty()) {
                        return true;
                    } else {
                        return false;
                    }
                }
                else{
                    List<Application_Collateral__c> records = [
                        SELECT Id, Collateral__r.Builder__c
                        FROM Application_Collateral__c 
                        WHERE HL_Loan_Application__c = :loanId AND Collateral__r.Builder__c != null
                    ];
                    if (!records.isEmpty()) {
                        return true;
                    } else {
                        return false;
                    }
                }
            } catch (Exception e) {
                System.debug('line number ' + e.getLineNumber());
                throw new AuraHandledException('Something went wrong: ' + e.getMessage());
            }
    }
    //sanwar(12/12/2025)
    @AuraEnabled
    public static String getObjectApiNameFromId(String recordId) {
        return Id.valueOf(recordId).getSObjectType().getDescribe().getName();
    }
/*@AuraEnabled
    public static Boolean getDisPartyRecMultiSellerBuilder(String disParty, String loanId, String selectedName) {
        if(disParty == 'Seller' || disParty == 'Builder'){
            List<Application_Applicant__c> records = [
                SELECT Id
                FROM Application_Applicant__c
                WHERE Applicant_Type__c = :disParty
                AND Loan_Application__c = :loanId
                AND Name = :selectedName
            ];
            return !records.isEmpty();
        }
        return false;
    }
    @AuraEnabled(cacheable=true)
public static List<PicklistValueWrapper> getSellerBuilderList(String loanId, String disParty) {
    List<PicklistValueWrapper> options = new List<PicklistValueWrapper>();

    if (String.isBlank(loanId) || String.isBlank(disParty)) return options;

    List<Application_Applicant__c> records = [
        SELECT Id, Name
        FROM Application_Applicant__c
        WHERE Loan_Application__c = :loanId
          AND Applicant_Type__c = :disParty    // 'Seller' OR 'Builder'
        ORDER BY Name
    ];

    for (Application_Applicant__c rec : records) {
        options.add(new PicklistValueWrapper(rec.Name, (String)rec.Id)); // label, value
    }
    System.debug('Apex class picklist options  '+options);
    return options;
    }*/
}