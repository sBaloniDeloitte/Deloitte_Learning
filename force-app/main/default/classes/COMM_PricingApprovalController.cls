public class COMM_PricingApprovalController {
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
    
    
    @AuraEnabled(cacheable=false)
    public static List<Opportunity> getLoanRecords(Id opportunityId) {
        try {
            return [SELECT Id, Sanction_Tenure__c,Sub_Product__c, Sanction_Rate_Of_Interest__c, Pricing_Approval_Status__c,Is_Pricing_Approval_Required__c,
                    Sanction_Loan_Amount__c, Negotiated_Tenure__c, Negotiated_Loan_Amount__c,
                    Negotiated_Rate_Of_Interest__c,Emi_amount__c,Resanction__c,Eligible_for_Resanction__c, 
                    Product__c,Repayment_Facility__c,Scheme__c,Customer_Profile__c,Tenor_Months__c,Final_Tenure__c,Final_Rate_Of_Interest__c,
                    Final_Amount__c From Opportunity WHERE id = :opportunityId];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching records: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getLoanProductRecords(Id opportunityId) {
        try {
            return [Select Id,Name,RecordType.Name,Sanctioned_Loan_Amount__c,Sanctioned_ROI__c,Sanctioned_Tenor__c,
                    Negotiated_Loan_Amount__c,Negotiated_ROI__c,Negotiated_Tenure__c,Final_Loan_Amount__c,Final_ROI__c,
                    Final_Tenure__c,Product__r.Product_Master__r.Name,Product__r.Product_Type__c from Product2 WHERE RecordType.Name = 'Sub Product' AND Loan_Application__c = :opportunityId];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching records: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<Opportunity> getLatestLoanRecords(Id opportunityId) {
        try {
            return [SELECT Id, Sanction_Tenure__c,Sub_Product__c, Sanction_Rate_Of_Interest__c, 
                    Sanction_Loan_Amount__c, Negotiated_Tenure__c, Negotiated_Loan_Amount__c,
                    Negotiated_Rate_Of_Interest__c,Emi_amount__c,Resanction__c,Eligible_for_Resanction__c, 
                    Product__c,Repayment_Facility__c,Scheme__c,Customer_Profile__c,Tenor_Months__c,Final_Tenure__c,Final_Rate_Of_Interest__c,
                    Final_Amount__c From Opportunity WHERE id = :opportunityId];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching records: ' + e.getMessage());
        }
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<Charges_Approval_Criteria__mdt> getChargesApprovalCriteria() {
        Map<String,Charges_Approval_Criteria__mdt> allMetaData = Charges_Approval_Criteria__mdt.getAll();
         
        System.debug(allMetaData.values());
        return allMetaData.values();
    }
    @AuraEnabled
    public static void resetResanctionFlag(Id opportunityId) {
        Opportunity opp = [SELECT Id, Resanction__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        opp.Resanction__c = false;
        update opp;
    }
    
    @AuraEnabled
    public static void resetPricingFlag(Id opportunityId,String productName ){
        try {
           List <Product2> prod2 = [SELECT Id,Loan_Application__r.Is_Pricing_Approval_Required__c, Sanctioned_Loan_Amount__c,Sanctioned_ROI__c,Sanctioned_Tenor__c,Product__r.Product_Type__c 
                                                    FROM Product2
                                                    WHERE Id = :productName AND
                                                    RecordType.Name = 'Sub Product' AND Loan_Application__c = :opportunityId];
        if (!prod2.isEmpty()) {
            Opportunity lan = new Opportunity(
                Id = opportunityId,
                Is_Pricing_Approval_Required__c = true
            );
            update lan;
        }
    } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static string submitforResanction( String loanId, String remarks){
        String res;
        String currentUserId= UserInfo.getuserId();
        try {

            List<Opportunity> childLoansToUpdate = new List<Opportunity>();
            System.debug('loanId---'+loanId);
            List<Opportunity> loanData = [SELECT Id,StageName,Sub_stage__c, Branch_Master__c,Eligible_for_Resanction__c,Resanction__c,Approval_Status__c,Approval_Sub_Status__c,Loan_Hierarchy__c
            FROM Opportunity WHERE Id = :loanId];

            System.debug('loanData-'+loanData[0]);
            if (!loanData.isEmpty()) {
                Opportunity loan = loanData[0];
                loan.StageName = 'Credit Underwriting';
                loan.Sub_stage__c = 'Credit in-progress';
                loan.Resanction__c = true;
                loan.Eligible_for_Resanction__c = false;
                loan.Resanctioned_Loan__c = true;
                loan.Resanction_Remarks__c = remarks;
                loan.Approval_Status__c = 'In Progress';
                loan.Approval_Sub_Status__c = '';
                if(loan.Loan_Hierarchy__c == 'Parent'){
                   loan.Recredit_Multiproduct__c = true;
                }
                update loan;

                if(loan.Loan_Hierarchy__c == 'Parent'){
                    List<Opportunity> childLoans = [SELECT Id, StageName, Sub_stage__c, Branch_Master__c,Eligible_for_Resanction__c,Resanction__c,Approval_Status__c,Approval_Sub_Status__c FROM Opportunity WHERE Split_Parent_Loan_Application__c = :loanId AND StageName != 'Abandoned'];
                    for(Opportunity childLoan : childLoans){
                        childLoan.StageName = 'Credit Underwriting';
                        childLoan.Sub_stage__c = 'Credit in-progress';
                        childLoan.Resanction__c = true;
                        childLoan.Eligible_for_Resanction__c = false;
                        childLoan.Resanctioned_Loan__c = true;
                        childLoan.Resanction_Remarks__c = remarks;
                        childLoan.Approval_Status__c = 'In Progress';
                        childLoan.Approval_Sub_Status__c = '';
                        childLoan.Recredit_Multiproduct__c = true;
                        childLoansToUpdate.add(childLoan);
                    }
                }
                if(!childLoansToUpdate.isEmpty()){
                    update childLoansToUpdate;
                }
                
                res= 'success';
            }
            
        }
        catch (Exception e) {
            res= 'Error: '+e.getMessage();
        }
        
        return res;
    }
    
    
    @AuraEnabled
    public static void updateNegotiatedValues(Id opportunityId, Map<String, Object> updatedFields, String productName) {
        try {
            Product2 product = new Product2();
            
            Product2 currentProductValues = [SELECT Id,Sanctioned_Loan_Amount__c,Sanctioned_ROI__c,Sanctioned_Tenor__c,Product__r.Product_Type__c 
                                                    FROM Product2
                                                    WHERE Id = :productName AND
                                                    RecordType.Name = 'Sub Product' AND Loan_Application__c = :opportunityId
                                                    LIMIT 1];

            
            
            System.debug('updatedFields--'+updatedFields);
            product.Id = currentProductValues.Id;
            
            if(updatedFields.containskey('Negotiated_Loan_Amount__c')){
                product.Negotiated_Loan_Amount__c = Double.valueOf(updatedFields.get('Negotiated_Loan_Amount__c'));
                //product.Final_Loan_Amount__c = product.Negotiated_Loan_Amount__c;
            }
            
            if(updatedFields.containskey('Negotiated_ROI__c')){
                product.Negotiated_ROI__c = Double.valueOf(updatedFields.get('Negotiated_ROI__c'));
                //product.Final_ROI__c = product.Negotiated_ROI__c;
                // if(currentProductValues.Product__r.Product_Type__c == 'Parent'){ Commented as a hotfix for CR-1404 AA
                //     List<Opportunity> loanData = [SELECT Id,Negotiated_Rate_Of_Interest__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
                //     loanData[0].Negotiated_Rate_Of_Interest__c = product.Negotiated_ROI__c;
                //     update loanData;
                // }
                List<Opportunity> loanData = [
                    SELECT Id, Negotiated_Rate_Of_Interest__c, Split_Parent_Loan_Application__c, HL_AHL_Vertical__c
                    FROM Opportunity
                    WHERE Id = :opportunityId
                    LIMIT 1
                ];

                Boolean isHlRelated = loanData[0].HL_AHL_Vertical__c == 'HL';

                Boolean isParentProduct = currentProductValues.Product__r.Product_Type__c == 'Parent';
                Boolean isHlChildSplit = isHlRelated
                    && currentProductValues.Product__r.Product_Type__c == 'Child'
                    && loanData[0].Split_Parent_Loan_Application__c != null;

                if (isParentProduct || isHlChildSplit) {
                    loanData[0].Negotiated_Rate_Of_Interest__c = product.Negotiated_ROI__c;
                    update loanData;
                }
            }
            
            if(updatedFields.containskey('Negotiated_Tenure__c')){
                product.Negotiated_Tenure__c = Double.valueOf(updatedFields.get('Negotiated_Tenure__c'));
                //product.Final_Tenure__c = product.Negotiated_Tenure__c;
            }
            
            
            System.debug('product--'+product);
            
            update product;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating records: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateFinalValues(Id opportunityId, Map<String, Object> updatedFields, String productName) {
        try {
            Product2 product = new Product2();
            
            Product2 currentProductValues = [SELECT Id,Sanctioned_Loan_Amount__c,Sanctioned_ROI__c,Sanctioned_Tenor__c,Product__r.Product_Type__c 
                                                    FROM Product2
                                                    WHERE Id = :productName AND
                                                    RecordType.Name = 'Sub Product' AND Loan_Application__c = :opportunityId
                                                    LIMIT 1];

            
            
            System.debug('updatedFields--'+updatedFields);
            product.Id = currentProductValues.Id;
            
            if(updatedFields.containskey('Negotiated_Loan_Amount__c')){
                product.Negotiated_Loan_Amount__c = Double.valueOf(updatedFields.get('Negotiated_Loan_Amount__c'));
                product.Final_Loan_Amount__c = product.Negotiated_Loan_Amount__c;
            }
            List<Opportunity> loanData = [
                    SELECT Id, Negotiated_Rate_Of_Interest__c, Split_Parent_Loan_Application__c, HL_AHL_Vertical__c
                    FROM Opportunity
                    WHERE Id = :opportunityId
                    LIMIT 1
            ];

            if(updatedFields.containskey('Negotiated_ROI__c')){
                product.Negotiated_ROI__c = Double.valueOf(updatedFields.get('Negotiated_ROI__c'));
                product.Final_ROI__c = product.Negotiated_ROI__c;
                // if(currentProductValues.Product__r.Product_Type__c == 'Parent'){ Commented as a hotfix for CR-1404 AA
                //     List<Opportunity> loanData = [SELECT Id,Negotiated_Rate_Of_Interest__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
                //     loanData[0].Negotiated_Rate_Of_Interest__c = product.Negotiated_ROI__c;
                //     update loanData;
                // }

                Boolean isHlRelated = loanData[0].HL_AHL_Vertical__c == 'HL';

                Boolean isParentProduct = currentProductValues.Product__r.Product_Type__c == 'Parent';
                Boolean isHlChildSplit = isHlRelated
                    && currentProductValues.Product__r.Product_Type__c == 'Child'
                    && loanData[0].Split_Parent_Loan_Application__c != null;

                if (isParentProduct || isHlChildSplit) {
                    loanData[0].Negotiated_Rate_Of_Interest__c = product.Negotiated_ROI__c;
                    update loanData;
                }
            }

                OpportunityTriggerHandler.isTriggerDisabled = true;
                Opportunity applicationObj = new Opportunity(Id = loanData[0].Id, Pricing_Approval_Status__c = 'Approved');
                update applicationObj;
                OpportunityTriggerHandler.isTriggerDisabled = false;
            
            if(updatedFields.containskey('Negotiated_Tenure__c')){
                product.Negotiated_Tenure__c = Double.valueOf(updatedFields.get('Negotiated_Tenure__c'));
                product.Final_Tenure__c = product.Negotiated_Tenure__c;
            }
            
            
            System.debug('product--'+product);
            
            update product;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating records: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Product2 getVariantRecord(String productPicklistValue,Id opportunityId) {
        Product2 mainProduct = [
            SELECT Id
            FROM Product2
            WHERE RecordType.Name = 'Product' AND Name = :productPicklistValue AND Loan_Application__c = :opportunityId
            LIMIT 1
        ];

        Product2 subProduct = [
            SELECT Id
            FROM Product2
            WHERE RecordType.Name = 'Sub Product' AND Product__c = :mainProduct.Id AND Loan_Application__c = :opportunityId
            LIMIT 1
        ];

        Product2 variant = [
            SELECT Id, Name
            FROM Product2
            WHERE RecordType.Name = 'Variant' AND Product__c = :subProduct.Id AND Loan_Application__c = :opportunityId
            LIMIT 1
        ];

        return variant;
    }

    @AuraEnabled
    public static Application_Applicant__c getCustomerProfile(Id opportunityId){
        try {
            Application_Applicant__c primaryApplicant = [
                SELECT Id, Customer_Profile__c 
                FROM Application_Applicant__c
                WHERE Loan_Application__c = :opportunityId AND Applicant_Type__c = 'Primary Applicant' LIMIT 1
            ];
            return primaryApplicant;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean checkChildLoan(String recordId){
        Boolean result= false;
        List<Opportunity> oppList = [SELECT Id, Split_Parent_Loan_Application__c FROM Opportunity WHERE Id = :recordId];
        if(oppList.size()>0){
            if(oppList[0].Split_Parent_Loan_Application__c!= null){
                result = true;
            }
        }
        return result;
    }
}