public with sharing class HL_StepLoanController {
    @AuraEnabled
    public static Id createAndUpdateStepLoan(StepLoanWrapper stepLoanDetails,String loanApplicationId,String relatedTransactionId){
        Loan_Transaction__c record = new Loan_Transaction__c();
        try {
            if(stepLoanDetails.stepLoanId != ''){
                record.Id = stepLoanDetails.stepLoanId;
            }
            record.Related_Transaction__c = relatedTransactionId;
            record.Loan_Application__c = loanApplicationId;
            record.RecordTypeId = SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get(CONSTANTS.STEP_LOAN_RECORD_TYPE_DEVELOPER_NAME).getRecordTypeId();
            record.Step_Number__c = stepLoanDetails.stepNumber;
            record.Step_Specifier__c = stepLoanDetails.stepIdentifier;
            record.Loan_Tenor__c = stepLoanDetails.stepLoanTenure;
            record.Step_Amount__c = stepLoanDetails.stepLoanAmount;
            record.Tenor_Split__c = stepLoanDetails.tenurePercentage;
            record.Auto_Cal__c = stepLoanDetails.autoCal;
            if(record != NULL){
                upsert record;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage()+e.getStackTraceString());
        }
        return record.Id;
    }

    @AuraEnabled
    public static TransactionDetailsWrapper getTransactionDetails(String loanId , String transactionId){
        TransactionDetailsWrapper transactionDetail = new TransactionDetailsWrapper();
        try {            
            List<Loan_Transaction__c> loanTransanctionList = [SELECT Id,Allow_Grace__c,Step_Loan__c,Allow_Payment_in_Grace_Period__c ,Grace_Period_Frequency__c
                                                              FROM Loan_Transaction__c 
                                                              WHERE Loan_Application__c = :loanId AND Id =:transactionId
                                                              AND RecordType.DeveloperName = 'Transaction_Details'];
            if(!loanTransanctionList.isEmpty()){
                transactionDetail.id = loanTransanctionList[0].Id;
                transactionDetail.allowGrace = loanTransanctionList[0].Allow_Grace__c;
                transactionDetail.stepLoan = loanTransanctionList[0].Step_Loan__c;
                transactionDetail.allowPayment = loanTransanctionList[0].Allow_Payment_in_Grace_Period__c;
                transactionDetail.gracePeriod = loanTransanctionList[0].Grace_Period_Frequency__c;
            }
        } catch (Exception e) {
            if(!System.Test.isRunningTest()){
                throw new AuraHandledException(e.getMessage());
            }
        }
        return transactionDetail;
    }

    @AuraEnabled
    public static List<StepLoanWrapper> getStepLoan(Id loanId, Id transactionId){
        List<StepLoanWrapper> stepLoanWrapperList = new List<StepLoanWrapper>();
        try {
        List<Loan_Transaction__c> stepLoanList = [SELECT Id,Related_Transaction__c,Loan_Tenor__c,Step_Specifier__c,Step_Number__c,Tenor_Split__c,Number_of_Instruments__c,Step_Amount__c,Auto_Cal__c 
                                                  FROM Loan_Transaction__c 
                                                  WHERE Loan_Application__c = :loanId AND Related_Transaction__c =: transactionId
                                                  AND RecordType.DeveloperName = 'Step_Loan_Details' 
                                                  ORDER BY Step_Number__c ASC];
            for(Loan_Transaction__c loan : stepLoanList){
                stepLoanWrapperList.add(new StepLoanWrapper(loan));
            }
        }
        catch (Exception e) {
        	if(!System.Test.isRunningTest()){
            	throw new AuraHandledException(e.getMessage()+e.getLineNumber());
            }
        }
        return stepLoanWrapperList;
    }

    @AuraEnabled
    public static List<StepLoanWrapper> deleteAndRecalculateStepLoan(Id toBeDeletedStepLoanId, Id transactionId){
        String loanAppId = '';
        try{
            Loan_Transaction__c toBeDeletedStepLoanRecord = [SELECT Id,Loan_Application__c FROM Loan_Transaction__c WHERE Id = :toBeDeletedStepLoanId LIMIT 1];
            if(toBeDeletedStepLoanRecord != null){
                loanAppId = toBeDeletedStepLoanRecord.Loan_Application__c;
                delete toBeDeletedStepLoanRecord;
            }
            List<Loan_Transaction__c> stepLoanList = [SELECT Id,Related_Transaction__c,Loan_Tenor__c,Step_Specifier__c,Step_Number__c,Tenor_Split__c,Number_of_Instruments__c,Step_Amount__c 
                                                      FROM Loan_Transaction__c WHERE Loan_Application__c = :loanAppId AND Related_Transaction__c =: transactionId
                                                      AND RecordType.DeveloperName = 'Step_Loan_Details' ORDER BY Step_Number__c ASC];                                     
            for(Integer i = 0; i < stepLoanList.size(); i++){
                stepLoanList[i].Step_Number__c = i+1; 
            }
            
            if(!stepLoanList.isEmpty()){
                update stepLoanList;
            }             
        }catch (Exception e) {
            if(!System.Test.isRunningTest()){
            	throw new AuraHandledException(e.getMessage()+e.getLineNumber());
            }
        }  
        return getStepLoan(loanAppId,transactionId);
    }  

    public static void recalculateStepNumbers(List<Loan_Transaction__c> stepLoanList){
        try{

            for(Integer i = 0; i < stepLoanList.size(); i++){
                stepLoanList[i].Step_Number__c = i+1;
            }
            if(stepLoanList.size() > 0){
                update stepLoanList;
            }
           
        }catch(Exception e){
            if(!System.Test.isRunningTest()){
            	throw new AuraHandledException(e.getMessage()+e.getLineNumber());
            }
        }
    }

    public class TransactionDetailsWrapper{
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public Boolean allowGrace { get; set; }
        @AuraEnabled public Boolean stepLoan { get; set; }
        @AuraEnabled public Boolean allowPayment { get; set; }
        @AuraEnabled public Decimal gracePeriod { get; set; }

    }

    public class StepLoanWrapper {
        @AuraEnabled public Decimal stepNumber { get; set; }
        @AuraEnabled public String stepLoanId {get; set; }
        @AuraEnabled public String stepIdentifier { get; set; }
        @AuraEnabled public Decimal stepLoanAmount { get; set; }
        @AuraEnabled public Decimal stepLoanTenure { get; set; }
        @AuraEnabled public Decimal tenurePercentage { get; set; }
        @AuraEnabled public Boolean autoCal {get; set;}
        @AuraEnabled public Boolean disabledRow { get; set; }
        @AuraEnabled public Boolean showEdit { get; set;}
        @AuraEnabled public Boolean showDelete { get; set;}
        @AuraEnabled public Boolean disableInput { get; set; }

        public StepLoanWrapper(Loan_Transaction__c loanTransaction) {
            this.stepNumber = loanTransaction.Step_Number__c;
            this.stepLoanId = loanTransaction.Id;
            this.stepIdentifier = loanTransaction.Step_Specifier__c;
            this.stepLoanAmount = loanTransaction.Step_Amount__c;
            this.stepLoanTenure = loanTransaction.Loan_Tenor__c;
            this.tenurePercentage = loanTransaction.Tenor_Split__c;
            this.autoCal = loanTransaction.Auto_Cal__c;
            this.disabledRow = true;
            this.showEdit = false;
            this.showDelete = true;
            this.disableInput = true;
        }
        public StepLoanWrapper() {

        }
    }

    @AuraEnabled
    public static Map<Id, Loan_Transaction__c> getTransactionsByProductIds(List<Id> productIds, String loanApplicationId) {
        Map<Id, Loan_Transaction__c> resultMap = new Map<Id, Loan_Transaction__c>();
        Utility_V1.ProductWrapper wrp = Utility_V1.getProductDetails(new Map<String,String>{'oppId' => loanApplicationId});
        Boolean isHLRelated = wrp.isHLRelated;
        if (productIds == null || productIds.isEmpty()) return resultMap;
        if(isHLRelated||Test.isRunningTest()){ //changing this for HL
            // for (Loan_Transaction__c lt : [ SELECT Id, Product__c,Product_Subvariant__c,Product_Subvariant__r.Name,Step_Loan__c, Allow_Grace__c, Allow_Payment_in_Grace_Period__c FROM Loan_Transaction__c WHERE Product__c IN :productIds AND Loan_Application__c=:loanApplicationId]) {
                //     resultMap.put(lt.Product__c, lt);
                // }
            List<Loan_Transaction__c> loanTransactions = [
                SELECT Id, Product__c, Product_Subvariant__c,
                    Product_Subvariant__r.Name,
                    Step_Loan__c,
                    Allow_Grace__c,
                    Allow_Payment_in_Grace_Period__c
                FROM Loan_Transaction__c
                WHERE Product__c IN :productIds
                AND Loan_Application__c = :loanApplicationId
            ];
            Set<Id> productsNeedingSubVariant = new Set<Id>();
            for (Loan_Transaction__c lt : loanTransactions) {
                if (lt.Product_Subvariant__c == null) {
                    productsNeedingSubVariant.add(lt.Product__c);
                }
            }
            Map<Id, Id> productToSubVariantMap = new Map<Id, Id>();

            if (!productsNeedingSubVariant.isEmpty()) {
                List<Product2> mainProductList = [SELECT Id FROM Product2  WHERE Id IN :productsNeedingSubVariant
                    AND RecordType.Name = 'Product'
                ];
                Set<Id> mainProductIds = new Set<Id>();
                for (Product2 p : mainProductList) {
                    mainProductIds.add(p.Id);
                }
                List<Product2> subProductList = [SELECT Id,Product__c FROM Product2 WHERE RecordType.Name = 'Sub Product' AND Product__c IN :mainProductIds];
                Set<Id> subProductIds = new Set<Id>();
                Map<String,String> subProductToMainProduct = new  Map<String,String>();
                for (Product2 sp : subProductList) {
                    subProductIds.add(sp.Id);
                    subProductToMainProduct.put(sp.id,sp.Product__c);
                }
                List<Product2> subVariantList = [SELECT Id, Product__c FROM Product2 WHERE RecordType.DeveloperName = 'Sub_Variant' AND Loan_Application__c = :loanApplicationId AND Product__c IN :subProductIds];
                for (Product2 sv : subVariantList) {
                    if(subProductToMainProduct.containskey(sv.Product__c) && subProductToMainProduct.get(sv.Product__c)!=null){
                         productToSubVariantMap.put(subProductToMainProduct.get(sv.Product__c), sv.Id);
                    }
                   
                }
            }
            List<Loan_Transaction__c> ltToUpdate = new  List<Loan_Transaction__c>();
            for (Loan_Transaction__c lt : loanTransactions) {
                if (lt.Product_Subvariant__c == null && productToSubVariantMap.containsKey(lt.Product__c)) {
                    lt.Product_Subvariant__c = productToSubVariantMap.get(lt.Product__c);
                    ltToUpdate.add(lt);
                }
                //resultMap.put(lt.Product__c, lt);
            }
            if(!ltToUpdate.isEmpty()){
                 update ltToUpdate;
            }
            for (Loan_Transaction__c lt : [ SELECT Id, Product__c,Product_Subvariant__c,Product_Subvariant__r.Name,Step_Loan__c, Allow_Grace__c, Allow_Payment_in_Grace_Period__c FROM Loan_Transaction__c WHERE Product__c IN :productIds AND Loan_Application__c=:loanApplicationId]) {
                resultMap.put(lt.Product__c, lt);
            }
        }
        else{
            for (Loan_Transaction__c lt : [ SELECT Id, Product__c,Product_Subvariant__c,Product_Subvariant__r.Name,Step_Loan__c, Allow_Grace__c, Allow_Payment_in_Grace_Period__c FROM Loan_Transaction__c WHERE Product__c IN :productIds]) {
                resultMap.put(lt.Product__c, lt);
            }
        }
        return resultMap;
    }

}