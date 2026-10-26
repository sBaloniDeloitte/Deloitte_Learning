public with sharing class CaptureMandateController {
//Added
    @AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getLoanDetails(String loanApplicationId) {
        try {
            // Fetch Loan Details Including EMI Amount
            Opportunity loan = [
                SELECT Sanction_Loan_Amount__c, Sanction_EMI__c
                FROM Opportunity 
                WHERE Id = :loanApplicationId 
                LIMIT 1
            ];

            // Create Map to return both values
            Map<String, Decimal> loanDetails = new Map<String, Decimal>();
            loanDetails.put('loanAmount', loan.Sanction_Loan_Amount__c);
            loanDetails.put('emiAmount', loan.Sanction_EMI__c);

            return loanDetails;

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching loan details: ' + e.getMessage());
        }
    }

   
    @AuraEnabled //Sanwar - remove cacheable
    public static List<Bank_Details__c> getRepaymentAccountDetails(Id loanApplicationId) {
        try {
            Opportunity opp = [select Id,Loan_Hierarchy__c,Split_Parent_Loan_Application__c from Opportunity where Id = :loanApplicationId LIMIT 1];
            if(opp.Loan_Hierarchy__c == 'Child' && opp.Split_Parent_Loan_Application__c != null){
                loanApplicationId = opp.Split_Parent_Loan_Application__c;
            }
            List<Application_Applicant__c> applicants = [
                SELECT Id FROM Application_Applicant__c WHERE Loan_Application__c = :loanApplicationId
            ];
            
            Set<Id> applicantIds = new Set<Id>();
            for (Application_Applicant__c applicant : applicants) {
                applicantIds.add(applicant.Id);
            }

            List<Bank_Details__c> repaymentAccounts = new List<Bank_Details__c>();
            if (!applicantIds.isEmpty()) {
                repaymentAccounts = [
                    SELECT Id, Account_Holder_Name__c, Name, Account_Number__c, Account_Type__c, 
                           OD_CC_Limit__c, ABB__c, Source__c, Application_Applicant__c, Application_Applicant__r.Applicant_Type__c, 
                           Bank_Master__r.Name,  Bank_Master__r.MICR__c,Bank_Master__r.Branch_Name__c, 
                           Bank_Master__r.Branch_Location__c, Bank_Master__r.IFSC__c
                    FROM Bank_Details__c
                    WHERE Application_Applicant__c IN :applicantIds 
                    AND Is_Repayment_Account__c = TRUE
                ];
            }
            return repaymentAccounts;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching repayment account details: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Instrument_Mandate__c upsertMandateRecord(Id loanApplicationId, Id bankDetailId, String mandateType, String mandateMode ,String periodicity, String pennyDrop, Decimal maxLimit, String startDate, String endDate, Id customerId) {
        try {
            Date startDt ;
            Date endDt ;

            if(startDate!=null && String.isNotBlank(startDate)){
                startDt = Date.valueOf(startDate);
                System.debug('Start Date'+startDt);
            }
            if(endDate!=null && String.isNotBlank(endDate)){
                endDt = Date.valueOf(endDate);
            }
            

            // Fetch the Bank_Details__c record to get IFS Code
            Bank_Details__c bankDetail = [SELECT Id, Bank_Master__r.Name FROM Bank_Details__c WHERE Id = :bankDetailId LIMIT 1];

            if (bankDetail == null || String.isEmpty(bankDetail.Bank_Master__r.Name)) {
                throw new AuraHandledException('Bank details not found or missing IFS Code.');
            }

             // **Fetch Loan Application Details**
                Opportunity loan = [
                SELECT Sanction_Loan_Amount__c, Sanction_EMI__c, CreatedDate, EMI_Amount_Repayment_Schedule__c, Name
                    FROM Opportunity 
                    WHERE Id = :loanApplicationId
                    LIMIT 1
                ]; // Sanwar - added Name field in query to populate value in ENACH_Ext_ID__c field

                if (loan == null) {
                    throw new AuraHandledException('Loan Application not found!');
                }

                Decimal loanAmount = loan.Sanction_Loan_Amount__c;
            Decimal emiAmount = loan.EMI_Amount_Repayment_Schedule__c != null ? loan.EMI_Amount_Repayment_Schedule__c : 0;

                // Convert CreatedDate (Datetime) to Date for Comparison
                Date loanCreatedDate = loan.CreatedDate.date(); 
            
                // **Validation: Max Limit must be at least 2X EMI Amount for Repayment Mandate**
            if (mandateType == 'Repayment Mandate' && (emiAmount * 2) > maxLimit) {
                    throw new AuraHandledException('Mandate Max Limit amount cannot be lower than 2X of EMI amount!');
                }

                // **Validation for Security Mandate**
                if (mandateType == 'Security Mandate') {
                    if (loanAmount < 10000000) { // Loan Amount < 1 Cr
                        if (maxLimit < loanAmount) {
                            throw new AuraHandledException('Mandate Max Limit cannot be lower than Loan Amount!');
                        }
                    } else { // Loan Amount >= 1 Cr
                        if (maxLimit < 10000000) { // 1 Cr = 100000000
                            throw new AuraHandledException('Mandate Max Limit cannot be lower than ₹1 Cr for loans above ₹1 Cr!');
                        }
                    }
                }

                // Validate Mandate Start Date (Should be same as Loan Created Date)
                

                // Validate Mandate End Date (Minimum End Date = Loan Maturity Date + 1 Month)
                /*Date minimumEndDate = loan.Maturity_Date__c.addMonths(1);
                if (endDt < minimumEndDate) {
                    throw new AuraHandledException('Mandate End Date cannot be earlier than ' + minimumEndDate + ' (Loan Maturity Date + 1 Month)!');
                }*/

            // Check if repayment Mandate record already exists
            List<Instrument_Mandate__c> repaymentMandateList = [
                SELECT Id, Mandate_Type__c, Max_Limit__c, Start_Date__c, End_Date__c,
                Periodicity__c, Bank_Details__c, Mandate_Mode__c
                FROM Instrument_Mandate__c
                WHERE Loan_Application__c = :loanApplicationId AND (ENACH_Status__c = 'Pending' or ENACH_Status__c = 'Success')
                /*AND Bank_Details__c = :bankDetailId*/ AND Mandate_Type__c ='Repayment Mandate'
                
            ];
            List<Instrument_Mandate__c> securityMandateList = [
                SELECT Id, Mandate_Type__c, Max_Limit__c, Start_Date__c, End_Date__c,
                Periodicity__c, Bank_Details__c, Mandate_Mode__c
                FROM Instrument_Mandate__c
                WHERE Loan_Application__c = :loanApplicationId AND (ENACH_Status__c = 'Pending' or ENACH_Status__c = 'Success')
                /*AND Bank_Details__c = :bankDetailId*/ AND Mandate_Type__c ='Security Mandate'
                
            ];

            // If an existing repayment mandate is found and the user is creating another repayment mandate, prevent creation
            if (!repaymentMandateList.isEmpty() && mandateType == 'Repayment Mandate') {
                throw new AuraHandledException('A repayment mandate already exists for this loan application.');
            }
            //added by kalpesh
             if (!securityMandateList.isEmpty() && mandateType == 'Security Mandate') {
                throw new AuraHandledException('A security mandate already exists for this loan application.');
            }

            // Create new Mandate record
            Instrument_Mandate__c newMandate = new Instrument_Mandate__c();
            newMandate.RecordTypeId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByName().get('Mandate').getRecordTypeId();
            newMandate.Loan_Application__c = loanApplicationId;
            newMandate.Bank_Details__c = bankDetailId;
            newMandate.Mandate_Type__c = mandateType;
            newMandate.Mandate_Mode__c = mandateMode;
//mandate changes start
            newMandate.Max_Limit__c = loanAmount < 10000000?loanAmount:9999999;
            //mandate changes end
            newMandate.Start_Date__c = startDt; 
            newMandate.End_Date__c = endDt;
            newMandate.Periodicity__c = periodicity;
            newMandate.Penny_Drop_Result__c = pennyDrop;
            newMandate.Application_Applicant__c = customerId;
            newMandate.ENACH_Status__c = 'Pending';
            // if(mandateType == 'Repayment Mandate'){ //Start - Sanwar - Added LA Name field to populate value in ENACH_Ext_ID__c field
            //     newMandate.ENACH_Ext_ID__c = loan.Name;
            // } // End - Sanwar - Added LA Name field to populate value in ENACH_Ext_ID__c field
            insert newMandate;

            return [SELECT Id, Mandate_Type__c, Application_Applicant__c, Max_Limit__c, Start_Date__c, End_Date__c, 
                    Periodicity__c, Penny_Drop_Result__c, Bank_Details__c, Mandate_Mode__c,Bank_Details__r.Account_Number__c, Bank_Details__r.Bank_Master__r.Name,Bank_Details__r.Bank_Master__r.Bank_Name__c, ENACH_Status__c 
                    FROM Instrument_Mandate__c where Id=:newMandate.id];
            

        } 
        catch (AuraHandledException e) {
            throw e;
        } 
        catch (Exception e) {
            throw new AuraHandledException('Error processing Mandate: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Id updateMandateRecord(String mandateId ,Id loanApplicationId, Id bankDetailId, String mandateType, String mandateMode ,String periodicity, Decimal maxLimit, String startDate, String endDate,String status) {
        try {
            Date startDt ;
            Date endDt ;

            if(startDate!=null && String.isNotBlank(startDate)){
                startDt = Date.valueOf(startDate);
            }
            if(endDate!=null && String.isNotBlank(endDate)){
                endDt = Date.valueOf(endDate);
            }
        
            // Fetch the Bank_Details__c record to get IFS Code
            Bank_Details__c bankDetail = [SELECT Id, Bank_Master__r.Name FROM Bank_Details__c WHERE Id = :bankDetailId LIMIT 1];

            if (bankDetail == null || String.isEmpty(bankDetail.Bank_Master__r.Name)) {
                throw new AuraHandledException('Bank details not found or missing IFS Code.');
            }

            // **Fetch Loan Application Details**
        // **Fetch Loan Application Details**
        Opportunity loan = [
                SELECT Sanction_Loan_Amount__c, Sanction_EMI__c, CreatedDate, EMI_Amount_Repayment_Schedule__c
            FROM Opportunity 
            WHERE Id = :loanApplicationId
            LIMIT 1
        ];

        if (loan == null) {
            throw new AuraHandledException('Loan Application not found!');
        }

        Decimal loanAmount = loan.Sanction_Loan_Amount__c;
            Decimal emiAmount = loan.EMI_Amount_Repayment_Schedule__c != null ? loan.EMI_Amount_Repayment_Schedule__c : 0;

        Loan_Transaction__c result = getLoanStartDateForLoanApplication(loanApplicationId);    
         // Convert CreatedDate (Datetime) to Date for Comparison
        Date loanCreatedDate = result.Loan_Start_Date__c != null ? result.Loan_Start_Date__c : Date.today();
        //Date loanCreatedDate = Utility.fetchBusinessDateFromIntDetail();
        // **Validation: Max Limit must be at least 2X EMI Amount for Repayment Mandate**
            if (mandateType == 'Repayment Mandate' && (emiAmount * 2) > maxLimit) {
            throw new AuraHandledException('Mandate Max Limit amount cannot be lower than 2X of EMI amount!');
        }

        // **Validation for Security Mandate**
        if (mandateType == 'Security Mandate') {	
            if (loanAmount < 10000000 && maxLimit < loanAmount) { // Loan Amount < 1 Cr
                if (maxLimit < loanAmount) {
                    throw new AuraHandledException('Mandate Max Limit cannot be lower than Loan Amount!');
                }
            } else { // Loan Amount >= 1 Cr
                if (loanAmount >= 10000000 && maxLimit < 10000000) { // 1 Cr = 10000000
                    throw new AuraHandledException('Mandate Max Limit cannot be lower than ₹1 Cr for loans above ₹1 Cr!');
                }
            }
        }

        if (startDt != loanCreatedDate) {
            throw new AuraHandledException('Mandate Start Date must be the same as Loan Start Date!');
        }

            // Check if a Mandate record already exists for this Bank Account & IFS Code
            List<Instrument_Mandate__c> mandateList = [
                SELECT Id, Mandate_Type__c, Max_Limit__c, Start_Date__c, End_Date__c, 
                Periodicity__c, Bank_Details__c, Mandate_Mode__c
                FROM Instrument_Mandate__c
                WHERE Id = :mandateId
            ];

            if (mandateList!=null && !mandateList.isEmpty()) {
                Instrument_Mandate__c newMandate = mandateList[0];
                newMandate.Loan_Application__c = loanApplicationId;
                newMandate.Bank_Details__c = bankDetailId!=null && String.isNotBlank(bankDetailId) ? bankDetailId :newMandate.Bank_Details__c;
                newMandate.Mandate_Type__c = mandateType!=null && String.isNotBlank(mandateType) ? mandateType :newMandate.Mandate_Type__c ;
                newMandate.Mandate_Mode__c = mandateMode!=null && String.isNotBlank(mandateMode) ? mandateMode :newMandate.Mandate_Mode__c ;
//mandate changes start
                newMandate.Max_Limit__c = loanAmount < 10000000?loanAmount:9999999;
                //mandate changes end
                newMandate.Start_Date__c =  startDt!=null  ? startDt :newMandate.Start_Date__c ;
                newMandate.End_Date__c = endDt!=null ? endDt :newMandate.End_Date__c ; 
                newMandate.Periodicity__c = periodicity!=null && String.isNotBlank(periodicity) ? periodicity :newMandate.Periodicity__c ;
                newMandate.ENACH_Status__c= status;
                update newMandate;
                return newMandate.Id;
            }
            return null;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error processing Mandate: ' + e.getMessage());
        }
    }

    //delete mandate 
    @AuraEnabled
    public static String deleteMandate(Id mandateId){
       try {
            delete [SELECT Id FROM Instrument_Mandate__c WHERE Id = :mandateId LIMIT 1];
            return 'Mandate deleted successfully';
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting mandate: ' + e.getMessage());
        } 
    }


    @AuraEnabled(cacheable=true)
    public static List<Application_Applicant__c> getApplicants(Id loanApplicationId) {
        Opportunity opp = [select Id,Loan_Hierarchy__c,Split_Parent_Loan_Application__c from Opportunity where Id = :loanApplicationId LIMIT 1];
        if(opp.Loan_Hierarchy__c == 'Child' && opp.Split_Parent_Loan_Application__c != null){
                loanApplicationId = opp.Split_Parent_Loan_Application__c;
            }

        return [
            SELECT Id, Name, Applicant_Type__c 
            FROM Application_Applicant__c 
            WHERE Loan_Application__c = :loanApplicationId
        ];
    }

    @AuraEnabled
    public static List<Bank_Details__c> getBankDetails(Id applicantId) {
        return [
            SELECT Id, Account_Holder_Name__c, Name, Account_Number__c, Account_Type__c, 
            OD_CC_Limit__c, ABB__c, Source__c, Application_Applicant__r.Applicant_Type__c, Application_Applicant__r.Mobile_Number__c,
            Bank_Master__r.Name, Bank_Master__r.IFSC__c,  Bank_Master__r.MICR__c, Is_Repayment_Account__c, Bank_Master__r.Branch_Name__c, 
            Bank_Master__r.Branch_Location__c
            FROM Bank_Details__c
            WHERE Application_Applicant__c = :applicantId
        ];
    }



    @AuraEnabled(cacheable=true)
    public static List<String> getMandateTypeValues() {
        return getPicklistValues('Instrument_Mandate__c', 'Mandate_Type__c');
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getMandateModeValues() {
        return getPicklistValues('Instrument_Mandate__c', 'Mandate_Mode__c');
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getPeriodicityValues() {
        return getPicklistValues('Instrument_Mandate__c', 'Periodicity__c');
    }

    @AuraEnabled(cacheable=true) //Sanwar
    public static List<String> getPennyDropOptions() {
        return getPicklistValues('Instrument_Mandate__c', 'Penny_Drop_Result__c');
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getPurposeValues() {
        return getPicklistValues('Instrument_Mandate__c', 'Purpose__c');
    }

    private static List<String> getPicklistValues(String objectName, String fieldName) {
        List<String> picklistValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe();
        
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            picklistValues.add(entry.getLabel());
        }
        return picklistValues;
    }

    @AuraEnabled
    public static List<Instrument_Mandate__c> getExistingMandate(Id loanApplicationId, Id bankDetailId) {
        Id recordTypeId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByName().get('Mandate').getRecordTypeId();
        System.debug('IDD'+ recordTypeId);
        try {
            List<Instrument_Mandate__c> mandates = [
                SELECT Id, Mandate_Type__c, Max_Limit__c, Start_Date__c, End_Date__c, 
                        Periodicity__c, Penny_Drop_Result__c, Mandate_Mode__c, 
                        Bank_Details__r.Account_Number__c, Bank_Details__r.Bank_Master__r.Name, Bank_Details__r.Bank_Master__r.Branch_Name__c, ENACH_Status__c,
                        Bank_Details__r.Bank_Master__r.Branch_Location__c,Bank_Details__r.Bank_Master__r.Bank_Name__c
                FROM Instrument_Mandate__c
                WHERE Loan_Application__c = :loanApplicationId AND recordTypeId =:recordTypeId
            ];

            if (!mandates.isEmpty()) {
                return mandates; // Return the existing Mandate
            }
            return null; // No Mandate exists
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Mandate: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Loan_Transaction__c getLoanStartDateForLoanApplication(Id loanAppId) {
        if (loanAppId == null) return null;
    
        Loan_Transaction__c loanTransaction = [
            SELECT Id, Loan_Start_Date__c, Loan_Application__r.Tenor_Months__c,Loan_Application__r.Sanction_Tenure__c 
            FROM Loan_Transaction__c 
            WHERE Loan_Application__c = :loanAppId 
            AND RecordType.Name = 'Transaction Details'
            LIMIT 1
        ];
    
        return loanTransaction;
    }
    


    @AuraEnabled
    public static String createInstruments(Id loanApplicationId, Id bankDetailId, String purpose, Integer startNumber, Integer endNumber, Id customerId) {
        try {
            Set<Decimal> alreadyExistingInstrumentNumbers = new Set<Decimal>();
             List<Instrument_Mandate__c> alreadyExistingInstruments = [SELECT Id, Instrument_Number__c, Purpose__c, Bank_Details__r.Name, Application_Applicant__r.Name,Instrument_Date__c, Instrument_Amount__c
                                                                       FROM Instrument_Mandate__c 
                                                                       WHERE Loan_Application__c = :loanApplicationId AND recordType.Name = 'Instrument'
                                                                       ORDER BY Instrument_Number__c ASC];
            for(Instrument_Mandate__c im : alreadyExistingInstruments){
                alreadyExistingInstrumentNumbers.add((Integer)im.Instrument_Number__c);
            }
            for(Integer i = startNumber; i<endNumber + 1;i++){
                if(alreadyExistingInstrumentNumbers.contains(i)){
                    return 'Instrument Number already exists.';
                }
            }
            if (startNumber == null || endNumber == null) {
                return 'Instrument numbers cannot be null.';
            }

            if (startNumber > endNumber) {
                return 'Ending instrument number must be greater than the starting number.';
            }

            // Validate that numbers are in sequence
            Integer expectedCount = endNumber - startNumber + 1;
            if (expectedCount != Math.abs(endNumber - startNumber) + 1) {
                return 'Instrument numbers must be sequential.';
            }

            // List<InstrumentWrapper> existingInstruments = fetchCreatedInstruments(loanApplicationId);

            // if(!existingInstruments.isEmpty() && (Integer.valueOf(existingInstruments[existingInstruments.size()-1].instrumentNumber) +1) != startNumber){
            //     return 'Instrument numbers must be sequential with the existing instruments.';
            // }

            List<Instrument_Mandate__c> instrumentsToCreate = new List<Instrument_Mandate__c>();

            for (Integer i = startNumber; i <= endNumber; i++) {
                Instrument_Mandate__c newInstrument = new Instrument_Mandate__c();
                newInstrument.RecordTypeId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
                newInstrument.Loan_Application__c = loanApplicationId;
                newInstrument.Bank_Details__c = bankDetailId;
                newInstrument.Purpose__c = purpose;
                newInstrument.Instrument_Number__c = Decimal.valueOf(i);
                newInstrument.Application_Applicant__c = customerId;
                newInstrument.Active__c = true;
                newInstrument.Type_of_Instrument_Record__c = 'Child';
                
                instrumentsToCreate.add(newInstrument);
            }

            if (!instrumentsToCreate.isEmpty()) {
                insert instrumentsToCreate;
            }

            List<Instrument_Mandate__c> parentInstrumentsToCreate = new List<Instrument_Mandate__c>();
            if (!instrumentsToCreate.isEmpty()) {
                Instrument_Mandate__c newInstrument = new Instrument_Mandate__c();
                newInstrument.RecordTypeId = Schema.SObjectType.Instrument_Mandate__c.getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
                newInstrument.Loan_Application__c = loanApplicationId;
                newInstrument.Bank_Details__c = bankDetailId;
                newInstrument.Starting_Instrument_Number__c = startNumber;
                newInstrument.Type_of_Instrument_Record__c = 'Parent';
                newInstrument.Ending_Instrument_Number__c = endNumber;
                if(startNumber!=endNumber){
                newInstrument.Cheque_Range__c = getFormattedInstrumentNumber(startNumber.toString())+'-'+getFormattedInstrumentNumber(endNumber.toString());
                }else{
                newInstrument.Cheque_Range__c = getFormattedInstrumentNumber(startNumber.toString());
                }
                newInstrument.Number_of_Cheques__c = instrumentsToCreate.size();
                parentInstrumentsToCreate.add(newInstrument);
            }
            if (!parentInstrumentsToCreate.isEmpty()) {
                insert parentInstrumentsToCreate;
            }
            if(!parentInstrumentsToCreate.isEmpty()){
                for(Instrument_Mandate__c inst : instrumentsToCreate){
                    inst.Instrument_Mandate__c = parentInstrumentsToCreate[0].Id;
                }
            }
            if (!instrumentsToCreate.isEmpty()) {
                update instrumentsToCreate;
            }


            return 'Instruments created successfully';
        } catch (Exception e) {
            throw new AuraHandledException('Error creating instruments: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<InstrumentWrapper> fetchCreatedInstruments(Id loanApplicationId) {

        List<InstrumentWrapper> record = new List<InstrumentWrapper>();

        Set<Id> conDocIds = new Set<Id>();
        Map<string, Document_Details__c> instrumentDocMap = new Map<string, Document_Details__c>();
        Map<Id, Instrument_Mandate__c> instMandMap = new Map<Id, Instrument_Mandate__c>([Select Id From Instrument_Mandate__c WHERE Loan_Application__c = :loanApplicationId AND recordType.Name = 'Instrument']);

        for(Document_Details__c rec : [Select Id, EntityReferenceId__c, Content_Document_Id__c From Document_Details__c Where Active__c = true 
                                        And EntityReferenceName__c = 'Instrument_Mandate__c' And EntityReferenceId__c In : instMandMap.keySet()]){
            
            instrumentDocMap.put(rec.EntityReferenceId__c, rec);
            conDocIds.add(rec.Content_Document_Id__c);
        }

        Map<Id, string> contentIdFileTypeMap = new Map<Id, string>();
        for(ContentVersion con : [SELECT ContentDocumentId, FileType FROM ContentVersion WHERE ContentDocumentId In : conDocIds]){
            contentIdFileTypeMap.put(con.ContentDocumentId, con.FileType);
        }

        for(Instrument_Mandate__c rec : [SELECT Id, Instrument_Number__c, Purpose__c, Bank_Details__r.Name, Application_Applicant__r.Name,
                                        Instrument_Date__c, Instrument_Amount__c
                                        FROM Instrument_Mandate__c 
                                        WHERE Loan_Application__c = :loanApplicationId AND recordType.Name = 'Instrument' AND Type_of_Instrument_Record__c = 'Child'
                                        ORDER BY Instrument_Number__c ASC]){

            InstrumentWrapper inst = new InstrumentWrapper();
            inst.id = rec.Id;
            inst.instrumentnumber = getFormattedInstrumentNumber(rec.Instrument_Number__c.toString());
            inst.purpose = rec.Purpose__c;
            inst.bankName = rec.Bank_Details__r.Name;
            inst.customername = rec.Application_Applicant__r.Name;
            inst.instrumentdate = rec.Instrument_Date__c;
            inst.instrumentamount = rec.Instrument_Amount__c;
            inst.showUpload = true;
            inst.showView = false;
            inst.fileType = '';

            if(instrumentDocMap.containsKey(rec.Id)){
                Document_Details__c dd = instrumentDocMap.get(rec.Id);
                inst.showUpload = false;
                inst.showView = true;
                inst.docDetailId = dd.Id;
                inst.contentDoclId = dd.Content_Document_Id__c;
                inst.fileType = contentIdFileTypeMap.containsKey(dd.Content_Document_Id__c) ? contentIdFileTypeMap.get(dd.Content_Document_Id__c) : '';
            }
            
            record.add(inst);
        }

        //system.debug('record: '+record);
        return record;
    }

    public static string getFormattedInstrumentNumber(string instrumentNo) {
        string instNo = '';
        if(String.isNotBlank(instrumentNo)){
            Integer charSize = instrumentNo.length();
            while (charSize <6) {
                instNo += '0';
                charSize++;
            }
            instNo += instrumentNo;
        }
        return instNo;
    }

    public class InstrumentWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public string instrumentnumber;
        @AuraEnabled public String purpose;
        @AuraEnabled public String bankName;
        @AuraEnabled public String customername;
        @AuraEnabled public Date instrumentdate;
        @AuraEnabled public Decimal instrumentamount;
        @AuraEnabled public Boolean showUpload;
        @AuraEnabled public Boolean showView;
        @AuraEnabled public String docDetailId;
        @AuraEnabled public String contentDoclId;
        @AuraEnabled public String fileType;
    }

    @AuraEnabled
    public static String deleteInstrument(Id instrumentId, string loanId) {
        Savepoint sp = Database.setSavepoint();

        try {
            List<Instrument_Mandate__c> instMandateList = [Select Id FROM Instrument_Mandate__c WHERE Loan_Application__c =: loanId 
                                                            And Purpose__c In ('Security', 'Installment', 'Pre EMI') Order by Instrument_Number__c asc];
            
            Set<Id> contentDocumentIds = new Set<Id>();                                                
            Integer index =1;
            Instrument_Mandate__c recToDel;

            for(Instrument_Mandate__c rec : instMandateList){

                //if((index == 1 || index == instMandateList.size()) && rec.Id == instrumentId){
                if( rec.Id == instrumentId){
                    System.debug('499');
                    recToDel = rec;
                    break;
                }

                index++;
            }

            // if(recToDel == null){
            //     return 'Error deleting instrument: First or Last Instrument in the sequence can be deleted';
            // }

            List<Document_Details__c> dd = [SELECT Id, Content_Document_Id__c FROM Document_Details__c WHERE EntityReferenceId__c =: instrumentId And EntityReferenceName__c = 'Instrument_Mandate__c'];
            for(Document_Details__c doc : dd){
				if(doc != null && doc.Content_Document_Id__c != null){
					contentDocumentIds.add(doc.Content_Document_Id__c);
					doc.Content_Document_Id__c = null;
                }
				}
                            if (!dd.isEmpty()) {
                update dd;
			}
            if(!contentDocumentIds.isEmpty()) {
				DELETE [SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIds];
			}
            if(!dd.isEmpty()){
                delete dd;
            }

            delete recToDel;

            return 'Instrument deleted successfully';
        }
        catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error deleting instrument: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static string updateInstrument(string loanId, Id instrumentId, String newPurpose, Decimal newInstrumentNumber, string instrumentDate, Decimal instrumentAmount) {
        try {
            Map<Id, Instrument_Mandate__c> instrumentMap = new Map<Id, Instrument_Mandate__c> ([SELECT Id,Purpose__c,Instrument_Number__c,Instrument_Date__c,Instrument_Amount__c 
                                                                                                FROM Instrument_Mandate__c WHERE Loan_Application__c =: loanId AND recordType.name = 'instrument']);

            Instrument_Mandate__c instrument = instrumentMap.get(instrumentId);
            instrument.Purpose__c = newPurpose;
            instrument.Instrument_Number__c = newInstrumentNumber;
            instrument.Instrument_Date__c = null;
            instrument.Instrument_Amount__c = null;

            if(newPurpose == 'Installment'){
                List<string> instDateList = instrumentDate.split('-');
                Map<string, string> months = new Map<string, string> {'Jan' => '01', 'Feb' => '02', 'Mar' => '03', 'Apr' => '04', 'May' => '05', 'Jun' => '06', 'Jul' => '07', 'Aug' => '08', 'Sep' => '09', 'Oct' => '10', 'Nov' => '11', 'Dec' => '12'};
                // date instDate = date.parse(instDateList[0] +'/'+ (months.get(instDateList[1]) +'/'+ instDateList[2]));
                
                Integer day   = Integer.valueOf(instDateList[0]);
                Integer month = Integer.valueOf(months.get(instDateList[1]));
                Integer year  = Integer.valueOf(instDateList[2]);
                Date instDate = Date.newInstance(year, month, day);

                for(Instrument_Mandate__c rec : instrumentMap.values()){
                    if(rec.Purpose__c == 'Installment' && rec.Instrument_Date__c == instDate){
                        return 'Instrument date has already taken, please select another date.';
                    }
                }

                instrument.Instrument_Date__c = instDate;
                instrument.Instrument_Amount__c = instrumentAmount;
            }

            update instrument;

            return 'Success';
        }
        catch(Exception e) {
            System.debug('tes#'+e.getMessage());
            throw new AuraHandledException('Failed to update instrument: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<string> reUploadInstrumentFile(Map<string, object> uploadParam) {
        Savepoint sp = Database.setSavepoint();

        try {
            List<string> result = new List<string>();

            String docDetailId = (string) uploadParam.get('docDetailId');

            system.debug('docDetailId: '+docDetailId);

            Document_Details__c dd = [Select Id, Loan_Application__c, Process_Name__c, Name, Document_Master__c, Description__c, Is_Required__c, Version_Number__c,
                                        EntityReferenceId__c, EntityReferenceName__c, Content_Document_Id__c, Status__c, Active__c
                                        From Document_Details__c Where Id =: docDetailId];
            System.debug('dd '+dd);

            SObject clonedRecord = dd.clone(false);
            clonedRecord.put('Version_Number__c', (dd.Version_Number__c == null ? 1 : (dd.Version_Number__c +1)));
            clonedRecord.put('Content_Document_Id__c', null);
            insert clonedRecord;

            List<Document_Details__c> oldRecordsToUpdate = [SELECT Id, Document_Details_Lookup__c, Active__c FROM Document_Details__c WHERE Document_Details_Lookup__c =: docDetailId Or Id =: docDetailId];
            // Iterate through and update the lookup field for each old record
            if(!oldRecordsToUpdate.isEmpty()){
                for(Document_Details__c oldRecord : oldRecordsToUpdate) {
                    oldRecord.Document_Details_Lookup__c = clonedRecord.Id;  // Point to the new cloned record
                    oldRecord.Active__c = false;
                }
                update oldRecordsToUpdate;
            }

            result.addAll(uploadInstrumentFile(uploadParam, clonedRecord));

            System.debug('result: '+result);
            return result;
        }
        catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('File upload failed: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<string> uploadInstrumentFile(Map<string, object> uploadParam, SObject docDetail) {
        Savepoint sp = Database.setSavepoint();

        try {
            System.debug('uploadParam: '+uploadParam);
            List<string> result = new List<string>();

            List<Document_Master__c> docMaster = [Select Id, Document_Name__c, Is_Required__c From Document_Master__c Where Document_Category__c = 'Banking' 
                                                    And Document_Name__c = 'Instrument' And Is_Active__c = true Limit 1];

            if(!docMaster.isEmpty()){
                Document_Details__c dd;

                if(docDetail != null){
                    dd = (Document_Details__c) docDetail;
                }
                else{
                    dd = new Document_Details__c();
                    dd.Loan_Application__c = (string) uploadParam.get('loanId');
                    dd.Process_Name__c = 'Instrument Creation';
                    dd.Name = docMaster[0].Document_Name__c;
                    dd.Document_Master__c = docMaster[0].Id;
                    dd.Description__c = 'Instrument image';
                    dd.Is_Required__c = docMaster[0].Is_Required__c;
                    dd.EntityReferenceId__c = (string) uploadParam.get('selectedInstrumentId');
                    dd.EntityReferenceName__c = 'Instrument_Mandate__c';
                    insert dd;
                }

                // Create Content Version
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = (string) uploadParam.get('filename');
                contentVersion.PathOnClient = (string) uploadParam.get('filename');
                contentVersion.VersionData = EncodingUtil.base64Decode((string) uploadParam.get('base64'));
                contentVersion.ContentLocation = 'S'; // Stored in Salesforce
                contentVersion.FirstPublishLocationId = dd.Id;
                insert contentVersion;
                
                // Retrieve the newly created ContentDocument ID
                List<ContentVersion> conList = [SELECT ContentDocumentId, FileType FROM ContentVersion WHERE Id = :contentVersion.Id];
                if(!conList.isEmpty()){
                    //Link the file to the Instrument (if needed separately)
                    ContentDocumentLink link = new ContentDocumentLink();
                    link.LinkedEntityId = (string) uploadParam.get('loanId');
                    link.ContentDocumentId = conList[0].ContentDocumentId;
                    link.ShareType = 'I';
                    link.Visibility = 'AllUsers';
                    insert link;

                    Document_Details__c ddRec = new Document_Details__c();
                    ddRec.Id = dd.Id;
                    ddRec.Content_Document_Id__c = conList[0].ContentDocumentId;
                    ddrec.Status__c = 'Uploaded';
                    ddRec.Active__c = true;
                    update ddRec;
                    
                    result.add(conList[0].ContentDocumentId);
                    result.add(conList[0].FileType);
                }

                result.add(dd.Id);
            }

            return result;
        } 
        catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('File upload failed: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String getUploadedFileUrl(String instrumentId) {
        ContentDocumentLink link = [
            SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :instrumentId LIMIT 1
        ];
        if (link != null) {
            return '/lightning/r/ContentDocument/' + link.ContentDocumentId + '/view';
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static Opportunity getLoanInfo(Id loanApplicationId) {
        
        return [
                    SELECT Sanction_Tenure__c, StageName FROM Opportunity 
                    WHERE Id =: loanApplicationId
                    LIMIT 1
                ];
    }

    @AuraEnabled
	public static Boolean canUserEditMandate(String opportunityId) {
		// Step 1: Fetch opportunity with sub-stage and stage
		Opportunity opp = [
			SELECT Id, StageName, Sub_stage__c
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

		final Boolean isQDP = !loanTxn.isEmpty() && loanTxn[0].Quick_Disbursement__c && loanTxn[0].QDP_Status__c == 'QDP-ONHOLD';

       
        if(opp.Sub_stage__c == 'Disbursed' || isQDP){
            return false;
        }

		// If not Disbursement stage or not Ops Maker sub-stage, return true (allow editing)
        if (opp.StageName != 'Disbursement' || (opp.Sub_stage__c != 'Ops Maker' && opp.Sub_stage__c != 'Ops Author')) {
            if (opp.StageName != 'PSV') {
                return true;
            }
		}

		// Step 2: Fetch current user’s Opportunity Team Member record
		List<OpportunityTeamMember> teamMembers = [
			SELECT Id, UserId, TeamMemberRole, OpportunityAccessLevel
			FROM OpportunityTeamMember
			WHERE OpportunityId = :opp.Id AND UserId = :UserInfo.getUserId()
			LIMIT 1
		];

		// Step 3: Check if role is Ops Maker
		// if (!teamMembers.isEmpty() && opp.Sub_stage__c == 'OPS Maker' && teamMembers[0].TeamMemberRole == 'OPS Maker') {
		// 	return true; // User can edit
		// }

        // Step 3: Check permissions based on roles and access
        if (!teamMembers.isEmpty()) {
            OpportunityTeamMember teamMember = teamMembers[0];

            if (opp.Sub_stage__c == 'OPS Maker' && teamMember.TeamMemberRole == 'OPS Maker') {
                return true;
            }

            if (opp.StageName == 'PSV' && teamMember.TeamMemberRole == 'Credit') {
                return teamMember.OpportunityAccessLevel == 'Edit';
            } else {
                // Not Credit role — allow edit
                return true;
            }
        }

		return false; // Others can only preview
	}
//Sanwar - Start
    @AuraEnabled
    public static List<Collateral__c> getCollateralData(Id loanAppId) {
        return [SELECT Id, Name, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Carpet_Area_of_Residential_Unit_sq_m__c
                FROM Collateral__c
                WHERE Id IN (
                    SELECT Collateral__c FROM Application_Collateral__c
                    WHERE HL_Loan_Application__c = :loanAppId
                )
                LIMIT 10];
    }

    @AuraEnabled
    public static List<Loan_Transaction__c> getNOIRecords(Id loanAppId){
        try {
            Id noiRecordTypeId = Schema.SObjectType.Loan_Transaction__c
            .getRecordTypeInfosByName()
            .get('NOI').getRecordTypeId();

            return [
                SELECT Id, Name, NOI_Number__c,  Account_Holder_Name__c, NOI_Status__c, Remark__c
                FROM Loan_Transaction__c
                WHERE Loan_Application__c = :loanAppId
                AND RecordTypeId = :noiRecordTypeId
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
//Sanwar - End
    @AuraEnabled //Sanwar
    public static string updateBankDetailRecord(String recordId ,String bankMasterId, String MandateType, String loanId){//sanwar(add bank master id)
        try {
            if(MandateType == 'Repayment Mandate'){
                List<Bank_Details__c> bankRecords = [Select Id, Is_Repayment_Account__c from Bank_Details__c where id !=:recordId And Application_Applicant__r.Loan_Application__c =:loanId];
                if (!bankRecords.isEmpty()) {
                    List<Bank_Details__c> bankRecordsToUpdate = new List<Bank_Details__c>();
                    for(Bank_Details__c bankDetail : bankRecords){
                        if(bankDetail.Is_Repayment_Account__c == true){
                            bankDetail.Is_Repayment_Account__c = false;
                            bankRecordsToUpdate.add(bankDetail);
                        }
                    }
                    update bankRecordsToUpdate;
                }
                Bank_Details__c record = new Bank_Details__c();
                record.Id = recordId;
                record.Is_Repayment_Account__c = true;
                record.Bank_Master__c = bankMasterId;//sanwar
                update record;
                return 'Success';
            }
            return 'failure';

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled//sanwar
    public static List<Bank_Branch_Master__c> getBranchNameForBank(String bankName){
        try {
            List<Bank_Branch_Master__c> branchName = [SELECT Id, Name, Branch_Name__c, IFSC__c, MICR__c,Bank_Name__c, Branch_Location__c FROM Bank_Branch_Master__c WHERE (Bank_Name__c = :bankName OR Bank__r.Perfios_Bank_Name__c = :bankName) AND Branch_Name__c != null AND IFSC__c != null AND RecordType.Name = 'Branch'];
            return branchName;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}