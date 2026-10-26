/*
 * Created By : Ishi Jain
 * Created Date : 9/1/2025
 * Purpose : This class is a utility class, all the generic methods and utility methods can be created here, written for HL
 */

public without sharing class Utility_V1 {
   // 
    @AuraEnabled
    public static ProductWrapper getProductDetails(Map<String,String> inputMap) {
        Id recIdCheck;
        String objectType;
        String oppId = inputMap.get('oppId');
        String legalId = inputMap.get('legalId');
        String technicalId = inputMap.get('technicalId');
        
        //Arman's changes start here >>> THIS is being done as legalId was referred in a common class for legal and tech hence the wayaround
        if(String.isNotBlank(legalId)){
            recIdCheck = (Id)(inputMap.get('legalId'));
        }
        else if(String.isNotBlank(technicalId)){
            recIdCheck = (Id)(inputMap.get('technicalId'));
        }
        if(String.isNotBlank(recIdCheck)){
            objectType = recIdCheck.getSObjectType().getDescribe().getName();
        }
        if(objectType =='Legal__c' && String.isBlank(oppId)){
            oppId = [SELECT Loan_Application__c FROM Legal__c WHERE Id =:recIdCheck].Loan_Application__c;
        }
        else if(objectType =='Technical_Evaluation__c' && String.isBlank(oppId)){
            oppId = [SELECT HL_Loan_Application__c FROM Technical_Evaluation__c WHERE Id =:recIdCheck].HL_Loan_Application__c;
        }
        //Arman changes end heree>>

        ProductWrapper pw = new ProductWrapper();
        pw.isHLRelated = false;
        pw.constHomeLoan = String.valueOf(Constants__mdt.getInstance('Home_Loan').Label);
        List<Opportunity> loanList = [SELECT Id, Product__c,Split_Parent_Loan_Application__c FROM Opportunity WHERE Id =: oppId];

        if(!loanList.isEmpty()){
            Opportunity loan = loanList[0];
        pw.loanProduct = loan.Product__c;

        List<Product2> mainProduct = [SELECT Id, Name FROM Product2 WHERE RecordType.Name = 'Product' AND Loan_Application__c =: loan.Id 
                                        AND Name =: loan.Product__c AND Product_Type__c = 'Parent' LIMIT 1];
    
        if(!mainProduct.isEmpty()) {
            pw.productId = mainProduct[0].Id;
            pw.product = mainProduct[0].Name;
            // Identify HL-related products
                if(mainProduct[0].Name ==  pw.constHomeLoan || mainProduct[0].Name == 'Flexi Loan' || mainProduct[0].Name == 'Non Home Loan') {
                pw.isHLRelated = true;
            }
        }
            
        if(loan.Split_Parent_Loan_Application__c!=null ){ //&& pw.loanProduct=='Flexi Loan'
            String requiredLoanId;
            requiredLoanId = loan.Split_Parent_Loan_Application__c;
            List<Product2> parentProd = [SELECT Id, Name FROM Product2 WHERE RecordType.Name = 'Product' AND Loan_Application__c =: requiredLoanId 
                                         AND Product_Type__c = 'Parent' LIMIT 1];
            if(parentProd.size()>0 && parentProd[0].Name == 'Home Loan') {
             pw.isHLRelated = true;
                }
            }
        }
        
        return pw;
    }

    @AuraEnabled
    public static Map<Id, String> getUsers(List<string> role, String userType){ 
        Map<Id, String> userListMap = new Map<Id, String>();

        for(AccountTeamMember atm : [Select Id, UserId, User.Employee_ID__c, User.Name, User.User_Type__c From AccountTeamMember Where TeamMemberRole IN: role Order By User.Name]){
            userListMap.put(atm.UserId, atm.User.Employee_ID__c +'_'+ atm.User.Name +'_'+ atm.User.User_Type__c);
        }
        return userListMap;
    }

    @AuraEnabled
    public static String returnFintypeFromTransactionTypeProduct(String subProductId){
        try {
            List<Product2> prodTranTypeList = [SELECT Id,Product_Master__r.PLF_Loan_Type__c,RecordType.Name,Loan_Application__r.Name,Product__r.RecordType.Name from Product2
            WHERE RecordType.Name = 'Transaction Type' AND Product__c = :subProductId ORDER BY CreatedDate DESC];
            return prodTranTypeList.size()>0 ? prodTranTypeList[0].Product_Master__c!=null ? String.isNotBlank(prodTranTypeList[0].Product_Master__r.PLF_Loan_Type__c) ? prodTranTypeList[0].Product_Master__r.PLF_Loan_Type__c : '' : '' : '';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<Id, String> getBranches(){

        Map<Id, String> branchMap = new Map<Id, String>();
        try {
            List<Account> accountList= [SELECT Id, Name FROM Account WHERE RecordType.Name = 'Branch' AND Branch_Type__c = 'HUB'];
            for(Account acc:accountList){
                branchMap.put(acc.Id, acc.Name);
            }
            System.debug('branchMap---'+branchMap);
        } catch (Exception e) {
            System.debug('exception----'+e.getMessage());
            // throw new AuraHandledException(e.getMessage());
        }
        return branchMap;
    }
    
    @AuraEnabled
    public static ProductWrapper checkIfLoggedInUserIsHLRelated(Map<String,String> inputMap) {
        ProductWrapper pw = new ProductWrapper();
        pw.isHLRelated = false;

        List<User> u = [
            SELECT Id FROM User
            WHERE Id IN (
                SELECT AssigneeId
                FROM PermissionSetAssignment
                WHERE PermissionSet.Name IN ('PS_Sales_Executive_HL','PS_Credit_Manager_HL','PS_Credit_Officer_HL','PS_DSA_Executive_HL','PS_Technical_Manager_HL')
            )
            AND Id =: UserInfo.getUserId()
            LIMIT 1
        ];

        if(!u.isEmpty()) {
            pw.isHLRelated = true;
        }
        return pw;
    }

  @AuraEnabled()
public static List<String> getCurrentUserPermissionSets() {
    try {
        List<PermissionSetAssignment> psaList = [
            SELECT PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
                  AND PermissionSet.IsOwnedByProfile = false
        ];
        Set<String> names = new Set<String>();
        for (PermissionSetAssignment psa : psaList) {
            names.add(psa.PermissionSet.Name);
        }
        List<String> sorted = new List<String>(names);
        sorted.sort();
        return sorted;
    } catch (Exception ex) {
        // Consider adding Platform logging here
        throw new AuraHandledException('Unable to fetch permission sets.');
    }
}


    @AuraEnabled
    public static string getFormattedRemarks(Map<String,String> inputMap) {
        String newRemarks = inputMap.get('newRemarks');
        //String newEntry = UserInfo.getName() +' - '+ System.now().format('yyyy-MM-dd, HH:mm:ss')+': '+ newRemarks;//newRemarks + '-' + UserInfo.getName() +' - '+ System.now().format('yyyy-MM-dd, HH:mm:ss');
        String newEntry = newRemarks +' - '+ System.now().format('yyyy-MM-dd, HH:mm:ss')+': '+ UserInfo.getName();//newRemarks + '-' + UserInfo.getName() +' - '+ System.now().format('yyyy-MM-dd, HH:mm:ss');
        System.debug('newEntry=:'+newEntry);
        // System.debug('existingRemarks=:'+existingRemarks);
        // if(String.isNotBlank(existingRemarks)) {
        //     return newEntry +'<br>'+ existingRemarks;
        // }
        // else{
            return newEntry;
        // }
    }

    @AuraEnabled
    public static List<FieldWrapper> getObjectFields(Id recordId) {
        List<FieldWrapper> fieldList = new List<FieldWrapper>();
        try {
            if(recordId == null) {
                return fieldList;
            }
            SObjectType objType = recordId.getSObjectType();
            DescribeSObjectResult objDescribe = objType.getDescribe();
            Map<String, Schema.SObjectField> fieldsMap = objDescribe.fields.getMap();
            List<String> fieldApiNames = new List<String>(fieldsMap.keySet());
            String soql = 'SELECT ' + String.join(fieldApiNames, ',') + 
                          ' FROM ' + objDescribe.getName() + 
                          ' WHERE Id = :recordId LIMIT 1';
            SObject recordData = Database.query(soql);
            for(String fieldName : fieldApiNames) {
                Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fieldName).getDescribe();
                
                FieldWrapper fw = new FieldWrapper();
                fw.apiName = fieldName;
                fw.label   = fieldDescribe.getLabel();
                fw.type    = String.valueOf(fieldDescribe.getType());
                
                // Get field value and convert to string safely
                Object rawVal = recordData.get(fieldName);
                fw.value = (rawVal == null) ? null : String.valueOf(rawVal);
                
                fieldList.add(fw);
            }
        } 
        catch(Exception ex) {
            System.debug('Error in getObjectFields: ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
        
        return fieldList;
    }

    public class ProductWrapper{
        @AuraEnabled public String product{get; set;}
        @AuraEnabled public String loanProduct{get; set;}
        @AuraEnabled public Boolean isHLRelated{get; set;}
        @AuraEnabled public String productId{get; set;}
        @AuraEnabled public String productName{get; set;}
        @AuraEnabled public String constHomeLoan{get; set;}
        @AuraEnabled public String subProdId{get; set;}
        @AuraEnabled public Boolean isParentProduct{get; set;}
    }

    public class FieldWrapper {
        @AuraEnabled public String apiName {get; set;}
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String type {get; set;}
        @AuraEnabled public String value {get; set;}
    }

    @AuraEnabled
    public static void updateApplicantAddress(Id recordId,  Map<String, Object> fields){
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        List<Applicant_Address__c> addr = new List<Applicant_Address__c>();
        if(sObjName == 'Legal__c'){
            addr = [Select Id from Applicant_Address__c where Legal__c =: recordId limit 1];
        }
        else if(sObjName == 'Technical_Evaluation__c'){
            addr = [Select Id from Applicant_Address__c where Technical_Evaluation__c =: recordId limit 1];
        }
        if(!addr.isEmpty()){
            for(String str : fields.keySet()){
                if(fields.get(str) != null){
                    //addr[0].put(str, String.valueOf(fields.get(str)));
                    addr[0].put(str, fields.get(str));
                }
            }
            Update addr;
        }
    }

    @AuraEnabled
    public static String getLoanStageFromApplicant(String appId) {
        List<Application_Applicant__c> appRecords = [SELECT Id, Loan_Application__r.StageName FROM Application_Applicant__c WHERE Id =: appId];
        return appRecords.get(0).Loan_Application__r.StageName;
    }
    
    @AuraEnabled
    public static String getCurrentUserProfileName(){
        return [Select Name From Profile Where Id =: userinfo.getProfileId()].Name;
    }

    @AuraEnabled
    public static String getObjectNameFromId(Id recordId) {
        String keyPrefix =String.valueOf(recordId).substring(0,3);
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for (String objectName : globalDescribe.keySet()) {
            if (globalDescribe.get(objectName).getDescribe().getKeyPrefix() == keyPrefix) {
                return objectName;
            }
        }
        return null; // Return null if no matching object is found
    }

    @AuraEnabled
    public static List<ProductWrapper> getProductDetailsIncome(Map<String, String> inputMap) {
        List<ProductWrapper> pwList = new List<ProductWrapper>();
        String oppId = inputMap.get('oppId');
        String legalId = inputMap.get('legalId');
        String technicalId = inputMap.get('technicalId');

        // Derive oppId if missing
        if (String.isBlank(oppId) && String.isNotBlank(legalId)) {
            oppId = [SELECT Loan_Application__c FROM Legal__c WHERE Id = :legalId LIMIT 1].Loan_Application__c;
        } else if (String.isBlank(oppId) && String.isNotBlank(technicalId)) {
            oppId = [SELECT HL_Loan_Application__c FROM Technical_Evaluation__c WHERE Id = :technicalId LIMIT 1].HL_Loan_Application__c;
        }

        System.debug('oppID: ' + oppId);

        if (String.isBlank(oppId)) {
            return pwList;
        }

        Opportunity loan = [
            SELECT Id, Product__c 
            FROM Opportunity 
            WHERE Id = :oppId 
            LIMIT 1
        ];

        // Fetch all sub-products first and map them to their parent product
        Map<Id, Id> productToSubProductIdMap = new Map<Id, Id>();
        for (Product2 sp : [
            SELECT Id, Product__c 
            FROM Product2 
            WHERE RecordType.Name = 'Sub Product' 
            AND Loan_Application__c = :oppId
        ]) {
            productToSubProductIdMap.put(sp.Product__c, sp.Id);
        }
        for (Product2 p : [
            SELECT Id, Name, Product_Type__c
            FROM Product2 
            WHERE RecordType.Name = 'Product' 
            AND Loan_Application__c = :oppId
        ]) {
            ProductWrapper pw = new ProductWrapper();
            pw.loanProduct = loan.Product__c;
            pw.productName = p.Name;
            pw.productId = p.Id;
            pw.isParentProduct = p.Product_Type__c == 'Parent';
            pw.subProdId = productToSubProductIdMap.containsKey(p.Id) ? String.valueOf(productToSubProductIdMap.get(p.Id)) : null;
            pwList.add(pw);
        }

        return pwList;
    }


    public class IncomeRecordTypeWrapper {
        @AuraEnabled public Id applicantId { get; set; }
        @AuraEnabled public String applicantName { get; set; }
        @AuraEnabled public String errorMsg { get; set; }
        @AuraEnabled public List<String> recordTypeNames { get; set; }
    }
    @AuraEnabled
     public static List<IncomeRecordTypeWrapper> getApplicantsWithMultipleRecordTypes(Id loanAppId) {
        List<Income_Assessment__c> incomeList = [
            SELECT Id, RecordType.Name, Applicant__c, Applicant__r.Name
            FROM Income_Assessment__c
            WHERE Applicant__r.Loan_Application__c = :loanAppId
            AND Parent__c = NULL
        ];
        Map<Id, Set<String>> applicantToRecordTypes = new Map<Id, Set<String>>();
        Map<Id, String> applicantToName = new Map<Id, String>();

        for (Income_Assessment__c rec : incomeList) {
            if (rec.Applicant__c == null) continue;

            if (!applicantToRecordTypes.containsKey(rec.Applicant__c)) {
                applicantToRecordTypes.put(rec.Applicant__c, new Set<String>());
            }
            applicantToRecordTypes.get(rec.Applicant__c).add(rec.RecordType.Name);
            applicantToName.put(rec.Applicant__c, rec.Applicant__r.Name);
        }
        List<IncomeRecordTypeWrapper> result = new List<IncomeRecordTypeWrapper>();
         System.debug('rapplicantToRecordTypesesult-----'+applicantToRecordTypes.keySet());
        for (Id applicantId : applicantToRecordTypes.keySet()) {
            Set<String> recordTypes = applicantToRecordTypes.get(applicantId);
            if (recordTypes.size() > 1) {
                IncomeRecordTypeWrapper wrap = new IncomeRecordTypeWrapper();
                wrap.applicantId = applicantId;
                wrap.applicantName = applicantToName.get(applicantId);
                wrap.recordTypeNames = new List<String>(recordTypes);
                wrap.errorMsg =applicantToName.get(applicantId) + ' applicant has multiple income records. Please select only one record type.';
                result.add(wrap);
            }
        }
        System.debug('result-----'+result);
        return result;
    }

    @AuraEnabled
    public static string getContentVersionId(String contentDocumentId){
        try {
            String contentVersionId;
            List<ContentVersion> contVersion = [Select id,contentDocumentId from ContentVersion where contentDocumentId=:contentDocumentId limit 1];
            if(contVersion.size()>0){
                contentVersionId=contVersion[0].id;
            }
            return contentVersionId;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<ErrorWrapper> checkTechnicalValidation(String loanId,String productId){
        try { 
            Decimal totalAmt=0; 
            List<ErrorWrapper> errorList = new List<ErrorWrapper>();
            Decimal requestedAmountApplicable =Decimal.valueof('500000');
            Opportunity opp = [Select id,Requested_Amount__c,Parent_Loan_Application__c,Is_Top_Up__c,Parent_Loan_Amount__c from Opportunity where id=:loanId];
            List<Product2> prodList = new List<Product2>();
            if(opp.Parent_Loan_Application__c!=null){
                prodList=[SELECT Id,Sanctioned_Loan_Amount__c FROM Product2 where Loan_Application__c=:opp.Parent_Loan_Application__c and id=:productId];
            }
          
            if(opp.Is_Top_Up__c=='No' && opp.Requested_Amount__c!=null && opp.Requested_Amount__c>requestedAmountApplicable){
                List<Technical_Evaluation__c> techEvalList = [Select id from Technical_Evaluation__c where HL_Loan_Application__c=:loanId and HL_Stage__c='Accepted by Technical Manager'];
                ErrorWrapper ew = new ErrorWrapper();
                if(techEvalList.size()<2){
                    ew.errorMsg = 'Please ensure that a minimum of two Technical Evaluation records are created for the loan application in cases where the requested amount is greater than'+ requestedAmountApplicable+ ' .';
                    errorList.add(ew);
                }
            }
            
            if(opp.Is_Top_Up__c=='Yes'){
                if(opp.Parent_Loan_Application__c!=null){
                totalAmt=opp.Requested_Amount__c + prodList[0].Sanctioned_Loan_Amount__c;
                }
                else{
                    totalAmt=opp.Requested_Amount__c + opp.Parent_Loan_Amount__c;
                }
                if(opp.Requested_Amount__c!=null && totalAmt>requestedAmountApplicable){
                    List<Technical_Evaluation__c> techEvalList = [Select id from Technical_Evaluation__c where HL_Loan_Application__c=:loanId and HL_Stage__c='Accepted by Technical Manager'];
                    ErrorWrapper ew = new ErrorWrapper();
                    if(techEvalList.size()<2){
                        ew.errorMsg = 'Please ensure that a minimum of two Technical Evaluation records are created for the loan application in cases where the requested amount is greater than'+ requestedAmountApplicable+ ' .';
                        errorList.add(ew);
                    }
                } 
            }
            
            //return errorList;
            return null;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    } 

    public class ErrorWrapper{
        @AuraEnabled public String errorMsg;
    }

   
    /*public static List<ErrorWrapper> checkTechnicalValidationHL( Map<String, String> inputMap){
        try {
            String loanId= inputMap.get('loanId');
            String productId = inputMap.get('productId');
            String eligibilityType = inputMap.get('eligibilityType');
            Decimal totalAmt=0; 
            List<ErrorWrapper> errorList = new List<ErrorWrapper>();
            Decimal requestedAmountApplicable = Decimal.valueof('500000');
            Opportunity opp = [Select id,Requested_Amount__c,Parent_Loan_Application__c,Is_Top_Up__c,Parent_Loan_Amount__c from Opportunity where id=:loanId];
            List<Product2> prodList = new List<Product2>();
            if(opp.Parent_Loan_Application__c!=null){
                prodList=[SELECT Id,Sanctioned_Loan_Amount__c FROM Product2 where Loan_Application__c=:opp.Parent_Loan_Application__c and id=:productId];
            }
          
            if(opp.Is_Top_Up__c=='No' && opp.Requested_Amount__c!=null && opp.Requested_Amount__c>requestedAmountApplicable){
                List<Technical_Evaluation__c> techEvalList = [Select id from Technical_Evaluation__c where HL_Loan_Application__c=:loanId and HL_Stage__c='Accepted by Technical Manager'];
                ErrorWrapper ew = new ErrorWrapper();
                if(techEvalList.size()<2 && eligibilityType!= 'Income Eligibility'){
                    ew.errorMsg = 'Please ensure that a minimum of two Technical Evaluation records are created for the loan application in cases where the requested amount is greater than'+ requestedAmountApplicable+ ' .';
                    errorList.add(ew);
                }
            }
            
            if(opp.Is_Top_Up__c=='Yes'){
                if(opp.Parent_Loan_Application__c!=null){
                totalAmt=opp.Requested_Amount__c + prodList[0].Sanctioned_Loan_Amount__c;
                }
                else{
                    totalAmt=opp.Requested_Amount__c + opp.Parent_Loan_Amount__c;
                }
                if(opp.Requested_Amount__c!=null && totalAmt>requestedAmountApplicable){
                    List<Technical_Evaluation__c> techEvalList = [Select id from Technical_Evaluation__c where HL_Loan_Application__c=:loanId and HL_Stage__c='Accepted by Technical Manager'];
                    ErrorWrapper ew = new ErrorWrapper();
                    if(techEvalList.size()<2 && eligibilityType!= 'Income Eligibility'){
                        ew.errorMsg = 'Please ensure that a minimum of two Technical Evaluation records are created for the loan application in cases where the requested amount is greater than'+ requestedAmountApplicable+ ' .';
                        errorList.add(ew);
                    }
                } 
            }
            return errorList;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    } */

    @AuraEnabled
    public static Map<String, Object> getFileSize(Id contentDocumentId) {
        Map<String, Object> result = new Map<String, Object>();

        ContentVersion cv = [
            SELECT Id, VersionData, ContentDocumentId, ContentSize
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        result.put('size', cv.ContentSize);
        result.put('contentVersionId', cv.Id);
        result.put('base64Data', EncodingUtil.base64Encode(cv.VersionData)); 
        return result;
    }
    
    @AuraEnabled
    public static void deleteUploadedFile(Id contentDocumentId) {
        try {
            List<ContentDocument> docs = [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId LIMIT 1];
            if (!docs.isEmpty()) {
                delete docs;
            }
        } catch (Exception e) {
            System.debug('Error deleting ContentDocument: ' + e.getMessage());
            throw new AuraHandledException('Failed to delete uploaded file.');
        }
    }
    @AuraEnabled
    public static string getSubStageValues(String loanId){
        try {
            String subStage;
            Opportunity opp = [Select id,Sub_Stage__c from Opportunity where id=:loanId LIMIT 1];
            subStage= opp.Sub_Stage__c;
            return subStage;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Product2> getSubProductDetails(String loanId){
        try {
            List<Product2> subProductDetails = [SELECT Id,Name,PLR_Code__c,Margin__c,Sanctioned_ROI__c,Sanctioned_Loan_Amount__c,Sanctioned_Tenor__c,HL_Final_EMI__c,HL_Final_FOIR__c,HL_Final_LTVSanctioned_Terms__c,
            HL_Maximum_Loan_Eligibility_basis_Income__c ,Product__r.Name
                                                 FROM Product2 
                                                 WHERE Loan_Application__c = :loanId aND RecordType.Name = 'Sub Product'];
            return subProductDetails;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean checkApplicantAddressType(Map<String,String> inputMap){
        try {
            String loanId = inputMap.get('oppId');
            String applicantId = inputMap.get('appId');
            String addType = inputMap.get('selectedAdd');
            List<Applicant_Address__c> appAddress = [Select id,Address_Type__c,Applicant__c from Applicant_Address__c where Applicant__c=:applicantId and Address_Type__c=:addType];
            if(appAddress.size()>0){
                return true;
            }else{
                return false;
            }

            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static Boolean checkExistingAddresses(Id applicantId, String addressTypes) {
        System.debug('addressTypes=:'+addressTypes);
        List<Applicant_Address__c> existing = new List<Applicant_Address__c>();
        if(addressTypes == 'SelectAll'){
            List<String> addressTypeList = new List<String>{'Current','Permanent'};
            // System.debug('addressTypeList=:'+addressTypeList);
            existing = [
                SELECT Id
                FROM Applicant_Address__c
                WHERE Applicant__c = :applicantId
                AND Address_Type__c in: addressTypeList
                LIMIT 1
            ];
        }
        else if(addressTypes != null){
            existing = [
                SELECT Id
                FROM Applicant_Address__c
                WHERE Applicant__c = :applicantId
                AND Address_Type__c =: addressTypes
                LIMIT 1
            ];
        }
        return !existing.isEmpty();
    }
    @AuraEnabled
    public static string checkeSignStatus(String loanId){
        String status;
        try {
            List<Opportunity> oppList = [SELECT Id, DocGen_Status__c FROM Opportunity WHERE Id = :loanId];
            if(oppList.size()>0){
                status = oppList[0].DocGen_Status__c;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return status;
    }
    
    public static void removePendingApprovalProcess(string recordId){
        List<ProcessInstanceWorkitem> procInstance = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: recordId AND ProcessInstance.Status = 'Pending'];
        if(!procInstance.isEmpty()){
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(procInstance[0].Id);  req.setAction('Removed');

            Approval.ProcessResult result = Approval.process(req);
        }
    }

    @AuraEnabled
    public static void updateEligibleforResanction( Map<String, String> inputMap){
        try {
            Opportunity opp= new Opportunity();
            opp.Id = inputMap.get('loanId');
            opp.Eligible_for_Resanction__c = Boolean.valueOf(inputMap.get('eligible'));
            opp.Is_Pricing_Approval_Required__c= Boolean.valueOf(inputMap.get('pricingApproval'));
            update opp;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}