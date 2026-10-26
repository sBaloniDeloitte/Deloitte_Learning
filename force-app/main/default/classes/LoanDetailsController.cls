/**
* @File Name : LoanDetailsController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : February 25, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | February 25, 2025 |   | Initial Version
**/

public class LoanDetailsController {

    PRIVATE STATIC STRING FORM_NAME = 'Loan Details';
    PRIVATE STATIC STRING Fetch_Application_Date = Constants__mdt.getInstance('Fetch_Application_Date').Value__c;
    PRIVATE STATIC List<STRING> constantNamesList = new List<String>{'Loan_Start_Date_Max_Days','Loan_Start_Date_Min_Days','Selected_Loan_Start_Date_Not_Valid','Loan_Start_Date_Is_Empty'};

    @AuraEnabled
    public static List<Screen_Field__c> getScreenFields(String formIdentifier, String loanType){
        List<Screen_Field__c> screenFieldList = [SELECT Id, Form_Name__c , Parent_Screen__r.Form_Name__c, Name,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c, Filtered_Picklist_Values__c,
                                                            Is_Picklist__c, Is_Multipicklist__c	, Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,Section_Seperator__c,Section_Name__c,
                                                            Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c, Read_Field_Name__c,Applicable_For__c,Picklist_Dependent_On_RecordType__c,
                                                            Visibility_Controlled_By__r.Field_Type__c,Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Visibility_Controlled_By__r.Storage_Field__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c,Default_Value__c 
                                                            FROM Screen_Field__c
                                                            WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Form_Name__c =: formIdentifier AND Loan_Type__c = :loanType order by Field_Sequence__c ASC];
        return screenFieldList;
    }
    
    @AuraEnabled
    public static Loan_Transaction__c createLoanTransaction(Id loanId, List<String> fieldList, String loanType){
        try{
            Boolean isLoanTransactionUpdated = false;
            String fieldNames = String.join(fieldList, CONSTANTS.COMMA);
            String queryStr = 'SELECT Id,Loan_Application__r.Sub_Product__c,'+ fieldNames + ' FROM Loan_Transaction__c WHERE Loan_Application__c = :loanId AND RecordType.Name = \'Transaction Details\' LIMIT 1';
            List<Loan_Transaction__c> loanTransactionList = Database.query(queryStr);
            return loanTransactionList[0];
        }catch(Exception ex){
            Utility.generateException(ex, Constants__mdt.getInstance('Loan_Transaction').value__c, Constants__mdt.getInstance('Loan_Details_Controller_Class').value__c);
            throw new AuraHandledException(ex.getMessage());
        }
        
        
    }
    
    /*@AuraEnabled
    public static Id createStepLoan(Id loanId , String fieldDetails){
        try{
            Map<String,Object> convertedMap = (Map<String, Object>) JSON.deserializeUntyped(fieldDetails);
            SObject record = (sObject)Type.forName(CONSTANTS.LOAN_TRANSACTION_API_NAME).newInstance();
            record.put('Loan_Application__c',loanId);
            record.put('isActive__c',TRUE);
            record.put('RecordTypeId',SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get(CONSTANTS.STEP_LOAN_RECORD_TYPE_DEVELOPER_NAME).getRecordTypeId());
            Schema.SObjectType objType = Schema.getGlobalDescribe().get('Loan_Transaction__c');
            for (String fieldApiName : convertedMap.keySet()) {
                Schema.DescribeFieldResult fieldDesc = objType.getDescribe().fields.getMap().get(fieldApiName).getDescribe();
                if(fieldDesc.getType().name().toLowerCase() == 'double' || fieldDesc.getType().name().toLowerCase() == 'integer'){
                    record.put(fieldApiName, Integer.valueOf(convertedMap.get(fieldApiName)));
                }else if(fieldDesc.getType().name().toLowerCase() == 'boolean'){
                    record.put(fieldApiName, Boolean.valueOf(convertedMap.get(fieldApiName)));
                }else if(fieldDesc.getType().name().toLowerCase() == 'date'){
                    record.put(fieldApiName, Date.valueOf(convertedMap.get(fieldApiName)));
                }else{
                    record.put(fieldApiName, String.valueOf(convertedMap.get(fieldApiName)));
                }
            }
            insert record;
            
            return record.Id;
        }catch(Exception ex){
            Utility.generateException(ex, Constants__mdt.getInstance('Loan_Transaction').value__c, Constants__mdt.getInstance('Loan_Details_Controller_Class').value__c);
            throw new AuraHandledException(ex.getMessage());
        }
        
        
    }*/
    
    @AuraEnabled
    public static List<Loan_Transaction__c> deleteUpdateStepLoan(Id stepLoanId , Id loanId){
        
        List<Loan_Transaction__c> updateLoanRecords = new List<Loan_Transaction__c>();
        Map<Id,Loan_Transaction__c> transactionMap = new Map<Id,Loan_Transaction__c>([SELECT Id,Loan_Tenor__c,Step_Number__c,Tenor_Split__c,Number_of_Instruments__c,Step_Amount__c  FROM Loan_Transaction__c WHERE Loan_Application__c = :loanId AND RecordType.DeveloperName = 'Step_Loan_Details' AND isActive__c = TRUE ORDER BY Step_Number__c ASC]);
        try{
            delete transactionMap.get(stepLoanId);
            Integer counter = 1;
            for(Loan_Transaction__c loan : transactionMap.values()){
                if(loan.Id != stepLoanId){
                    Loan_Transaction__c updatedLoan = new Loan_Transaction__c();
                    updatedLoan.Id = loan.Id;
                    updatedLoan.Loan_Tenor__c = loan.Loan_Tenor__c;
                    updatedLoan.Step_Number__c = counter;
                    updatedLoan.Tenor_Split__c = loan.Tenor_Split__c;
                    updatedLoan.Number_of_Instruments__c = loan.Number_of_Instruments__c;
                    updatedLoan.Step_Amount__c = loan.Step_Amount__c;
                    counter++;
                    updateLoanRecords.add(updatedLoan);
                }
            }
            
            if(!updateLoanRecords.isEmpty()){
                update updateLoanRecords;
            }
            
            return updateLoanRecords;
            
        }catch(Exception ex){
            Utility.generateException(ex, Constants__mdt.getInstance('Loan_Transaction').value__c, Constants__mdt.getInstance('Loan_Details_Controller_Class').value__c);
            throw new AuraHandledException(ex.getMessage());
        }
        
    }
    
    @AuraEnabled
    public static List<Loan_Transaction__c> getStepLoan(Id loanId){
        try{
            System.debug('>>>'+[SELECT Id,Loan_Tenor__c,Step_Specifier__c,Step_Number__c,Tenor_Split__c,Number_of_Instruments__c,Step_Amount__c FROM Loan_Transaction__c WHERE Loan_Application__c = :loanId AND RecordType.DeveloperName = 'Step_Loan_Details' ORDER BY Step_Number__c ASC]);
        return [SELECT Id,Loan_Tenor__c,Step_Specifier__c,Step_Number__c,Tenor_Split__c,Number_of_Instruments__c,Step_Amount__c FROM Loan_Transaction__c WHERE Loan_Application__c = :loanId AND RecordType.DeveloperName = 'Step_Loan_Details' ORDER BY Step_Number__c ASC];
        }catch(Exception e){
             throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void StepLoanActivationHandler(Id loanId, Boolean changedValue){
        Boolean currentValue = !changedValue;
        try{
            List<Loan_Transaction__c> updateList = new List<Loan_Transaction__c>();
            for(Loan_Transaction__c loan : [SELECT Id FROM Loan_Transaction__c WHERE Loan_Application__c = :loanId AND RecordType.DeveloperName = 'Step_Loan_Details' AND isActive__c = :currentValue]){
                Loan_Transaction__c updatedLoan = new Loan_Transaction__c();
                updatedLoan.Id = loan.Id;
                updatedLoan.isActive__c = changedValue;
                updateList.add(updatedLoan);
            }
            
            if(!updateList.isEmpty()){
                update updateList;
            }
        }catch(Exception ex){
            Utility.generateException(ex, Constants__mdt.getInstance('Loan_Transaction').value__c, Constants__mdt.getInstance('Loan_Details_Controller_Class').value__c);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void resetFieldValues(Id loanTransactionId, List<String> fieldNames){

        Loan_Transaction__c loanTransaction = [SELECT Id FROM Loan_Transaction__c WHERE Id = :loanTransactionId];

        sObject loan = (sObject) Type.forName(CONSTANTS.LOAN_TRANSACTION_API_NAME).newInstance();
        loan.put('Id',loanTransactionId);
        
        Schema.SObjectType objType = Schema.getGlobalDescribe().get('Loan_Transaction__c');

        for (String fieldApiName : fieldNames) {
            Schema.DescribeFieldResult fieldDesc = objType.getDescribe().fields.getMap().get(fieldApiName).getDescribe();
            if(fieldDesc.getType().name().toLowerCase() == 'double' || fieldDesc.getType().name().toLowerCase() == 'integer'){
                loan.put(fieldApiName, 0);
            }else if(fieldDesc.getType().name().toLowerCase() == 'boolean'){
                loan.put(fieldApiName, FALSE);
            }else if(fieldDesc.getType().name().toLowerCase() == 'date'){
                loan.put(fieldApiName, NULL);
            }else{
                loan.put(fieldApiName, '');
            }
                
        }

        try{
            update loan;
        }catch(Exception ex){
            Utility.generateException(ex, Constants__mdt.getInstance('Loan_Transaction').value__c, Constants__mdt.getInstance('Loan_Details_Controller_Class').value__c);
            throw new AuraHandledException(ex.getMessage());
        }
        

    }

    @AuraEnabled
    public static void deleteAllStepLoans(Id loanId) {
    try {
        List<Loan_Transaction__c> stepLoans = [
            SELECT Id 
            FROM Loan_Transaction__c 
            WHERE Loan_Application__c = :loanId 
            AND RecordType.DeveloperName = 'Step_Loan_Details'
        ];

        if (!stepLoans.isEmpty()) {
            delete stepLoans;
        }
    } catch (Exception ex) {
        Utility.generateException(
            ex, 
            Constants__mdt.getInstance('Loan_Transaction').value__c, 
            Constants__mdt.getInstance('Loan_Details_Controller_Class').value__c
        );
        throw new AuraHandledException(ex.getMessage());
    }
}

    @AuraEnabled(cacheable=true)
    public static List<OpportunityTeamMember> getOpportunityTeamMembers(Id loanId){
        return [SELECT Id,Name,TeamMemberRole,User.EmployeeNumber, OpportunityAccessLevel FROM OpportunityTeamMember WHERE OpportunityId = :loanId AND TeamMemberRole IN ('DSA Executive','Sales Rep','OPS Maker','OPS Author', 'Credit')];
    }

    @AuraEnabled(cacheable=true)
    public static List<AccountTeamMember> getAccountTeamMembers(){
        return [SELECT Id, User.Id, UserId,  TeamMemberRole,User.EmployeeNumber FROM AccountTeamMember WHERE TeamMemberRole IN ('Credit')];
    }

    @AuraEnabled(cacheable=true)
    public static Loan_Transaction__c getLoanTransactionDetails(Id loanId){
        List<Loan_Transaction__c> loanTxn =
            [SELECT Id,
                    Quick_Disbursement__c,
                    QDP_Status__c,
                    STP__c,
                    RecordType.DeveloperName,
                    Loan_Application__r.StageName,
                    Loan_Application__c
             FROM   Loan_Transaction__c
             WHERE  Loan_Application__c = :loanId
             AND    RecordType.DeveloperName = 'Transaction_Details'
             LIMIT  1];

        return loanTxn.isEmpty() ? null : loanTxn[0];
    }

    @AuraEnabled(cacheable=true)
    Public static Product2 getSubProduct(Id loanId){
        Product2 product = [SELECT Id FROM Product2 WHERE Loan_Application__c = :loanId AND Name = 'Business Loan' LIMIT 1];
        Product2 subProduct = [SELECT Id FROM Product2 WHERE Product__c = :product.Id AND RecordType.Name = 'Sub Product' LIMIT 1];
        Product2 variant = [SELECT Id,Name,PLR_Value__c,PLR_Code__c FROM Product2 WHERE Product__c = :subProduct.Id AND RecordType.Name = 'Variant' LIMIT 1];
        return variant;
        //return [SELECT Id,Name,RecordType.DeveloperName,PLR_Value__c FROM Product2 WHERE Loan_Application__c  =:loanId];
    }

    @AuraEnabled
    public static Decimal chargesInsuranceDetails(Id loanId){
        try {
            List<Charges_Insurance__c> chargesInsuranceList =  [
                SELECT Total_Fee_to_be_deducted__c
                FROM Charges_Insurance__c
                WHERE Loan_Application__c = :loanId
                AND Name = 'Total Charges'
            ];

            System.debug('chargesInsuranceList => ' + chargesInsuranceList);
            if(chargesInsuranceList.size() > 0){
                return chargesInsuranceList[0].Total_Fee_to_be_deducted__c;
            }
            return 0;
 
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable= true)
    public static Map<String,sObject> getProductData(Id loanId){
        try {
            Map<String,sObject> productData = new Map<String,sObject>();
            List<Product2> product = [SELECT Id,Name FROM Product2 WHERE Loan_Application__c = :loanId AND Name = 'Affordable Home Loan' LIMIT 1]; //Business Loan
            if(!product.isEmpty()){
                productData.put('productName',product[0]);
                List<Product2> subProduct = [SELECT Id,Name FROM Product2 WHERE Product__c = :product[0].Id AND RecordType.Name = 'Sub Product' LIMIT 1];
                if(!subProduct.isEmpty()){
                    productData.put('subProductName',subProduct[0]);
                    List<Product2> variant = [SELECT Id,Name,PLR_Value__c,PLR_Code__c FROM Product2 WHERE Product__c = :subProduct[0].Id AND RecordType.Name = 'Variant' LIMIT 1];
                    if(!variant.isEmpty()){
                        productData.put('variant',variant[0]);
                        List<Product2> subVariant = [SELECT Id,Name FROM Product2 WHERE Variant__c = :variant[0].Id AND RecordType.Name = 'Sub Variant' LIMIT 1];
                        if(!subVariant.isEmpty()){
                            productData.put('subVariant',!subVariant.isEmpty() ? subVariant[0] : null);
                            List<Product2> hybridTenure = [SELECT Id,Name FROM Product2 WHERE Product__c = :subVariant[0].Id AND RecordType.Name = 'Hybrid Tenure' LIMIT 1];
                            productData.put('hybridTenure',!hybridTenure.isEmpty() ? hybridTenure[0] : null);
                            List<Product2> scheme = [SELECT Id,Name FROM Product2 WHERE Sub_Variant__c = :subVariant[0].Id AND RecordType.Name = 'Scheme' LIMIT 1];
                            productData.put('scheme',!scheme.isEmpty() ? scheme[0] : null);
                            List<Product2> fullEmi = [SELECT Id,Name FROM Product2 WHERE Sub_Variant__c = :subVariant[0].Id AND RecordType.Name = 'Full EMI' LIMIT 1];
                            productData.put('fullEmi',!fullEmi.isEmpty() ? fullEmi[0] : null);
                            List<Product2> totalTenure = [SELECT Id,Name FROM Product2 WHERE Sub_Variant__c = :subVariant[0].Id AND RecordType.Name = 'Total Tenure' LIMIT 1];
                            productData.put('totalTenure',!totalTenure.isEmpty() ? totalTenure[0] : null);
                        }
                    }
                }
            }
            system.debug('@@@@@@ prod response ::' + productData);
            return productData;
            
        } catch (Exception e) {
            system.debug('@@@@@@ '+e.getMessage()+'##### '+e.getLineNumber()+'###### '+e.getStackTraceString()+'##### '+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true)
    Public static Integration_Details__c getIntegrationDetail(){
        return [SELECT Id,Business_Date__c FROM Integration_Details__c WHERE Name = :Fetch_Application_Date ORDER BY Createddate desc LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    Public static Map<String, Constants__mdt> constantsMetadata(){
        Map<String, Constants__mdt> constantMap = new Map<String,Constants__mdt>();
        for(Constants__mdt constant  : [SELECT Id,DeveloperName,Value__c FROM Constants__mdt WHERE DeveloperName IN :constantNamesList]){
            constantMap.put(constant.DeveloperName, constant);
        }

        return constantMap;
    }

    @AuraEnabled
    public static Loan_Transaction__c invokeBPIFlow(Id loanId) {
        try {
            System.debug('=== invokeBPIFlow START ===');

            Map<String, Object> flowInputs = new Map<String, Object>();
            flowInputs.put('recordId', loanId);

            Flow.Interview flowInterview = Flow.Interview.createInterview('BPI_Field_Flow_Automated', flowInputs);

            flowInterview.start();

            List<Loan_Transaction__c> txnList = [
                SELECT Id, Interest_Due_date__c, Allow_BPI__c, BPI_Treatment__c
                FROM Loan_Transaction__c
                WHERE Loan_Application__c = :loanId
                AND RecordType.DeveloperName = 'Transaction_Details'
                LIMIT 1
            ];

            System.debug('=== invokeBPIFlow END ===');
            return txnList.isEmpty() ? null : txnList[0];

        } catch (Exception ex) {
            throw new AuraHandledException('Error invoking BPI Flow: ' + ex.getMessage());
        }
    }

}