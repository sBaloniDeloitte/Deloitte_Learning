public class PricingApprovalController {
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
    
    
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getLoanRecords(Id opportunityId) {
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
    public static string submitforResanction( String loanId){
        String res;
        String currentUserId= UserInfo.getuserId();
        try {
            
            System.debug('loanId---'+loanId);
            List<Opportunity> loanData = [SELECT Id,StageName,Sub_stage__c, Branch_Master__c,Eligible_for_Resanction__c,Resanction__c,Approval_Status__c,Approval_Sub_Status__c
            FROM Opportunity WHERE Id = :loanId];

            System.debug('loanData-'+loanData[0]);
            if (!loanData.isEmpty()) {
                Opportunity loan = loanData[0];
                loan.StageName = 'Credit Underwriting';
                loan.Sub_stage__c = 'Credit in-progress';
                loan.Resanction__c = true;
                loan.Eligible_for_Resanction__c = false;
                loan.Approval_Status__c = 'In Progress';
                loan.Approval_Sub_Status__c = '';
                update loan;
                res= 'success';
            }
            
        }
        catch (Exception e) {
            res= 'Error: '+e.getMessage();
            // throw new AuraHandledException(e.getMessage());
        }
        
        return res;
    }
    
    
    @AuraEnabled
    public static void updateNegotiatedValues(Id opportunityId, Map<String, Object> updatedFields) {
        try {
            Opportunity opp = new Opportunity();
            
            Opportunity currentOpportunityValues = [SELECT Id,Sanction_Loan_Amount__c,
                                                    Sanction_Rate_Of_Interest__c, Sanction_Tenure__c
                                                    FROM Opportunity
                                                    WHERE Id = :opportunityId
                                                    LIMIT 1];

            
            
            System.debug('updatedFields--'+updatedFields);
            opp.Id = opportunityId;
            //for (String fieldName : updatedFields.keySet()){
            
            if(updatedFields.containskey('Negotiated_Loan_Amount__c')){
                opp.Negotiated_Loan_Amount__c = Double.valueOf(updatedFields.get('Negotiated_Loan_Amount__c'));
                if(opp.Negotiated_Loan_Amount__c <= currentOpportunityValues.Sanction_Loan_Amount__c){
                    opp.Final_Amount__c = opp.Negotiated_Loan_Amount__c;

                }
               
            }
            
            if(updatedFields.containskey('Negotiated_Rate_Of_Interest__c')){
                opp.Negotiated_Rate_Of_Interest__c = Double.valueOf(updatedFields.get('Negotiated_Rate_Of_Interest__c'));
                if(opp.Negotiated_Rate_Of_Interest__c >= currentOpportunityValues.Sanction_Rate_Of_Interest__c){
                    opp.Final_Rate_Of_Interest__c = opp.Negotiated_Rate_Of_Interest__c;
                }
            }
            
            if(updatedFields.containskey('Negotiated_Tenure__c')){
                opp.Negotiated_Tenure__c = Double.valueOf(updatedFields.get('Negotiated_Tenure__c'));
                if(opp.Negotiated_Tenure__c <= currentOpportunityValues.Sanction_Tenure__c){
                    opp.Final_Tenure__c = opp.Negotiated_Tenure__c;
                }
            }
            
            
            //} 
            
            System.debug('opp--'+opp);
            
            update opp;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating records: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Product2 getVariantRecord(String productPicklistValue,Id opportunityId) {
        // Step 1: Get Product2 with RecordType = 'Product' and Name = Product__c (picklist value)
        Product2 mainProduct = [
            SELECT Id
            FROM Product2
            WHERE RecordType.Name = 'Product' AND Name = :productPicklistValue AND Loan_Application__c = :opportunityId
            LIMIT 1
        ];

        // Step 2: Get Sub Product (RecordType = 'Sub Product') under Product
        Product2 subProduct = [
            SELECT Id
            FROM Product2
            WHERE RecordType.Name = 'Sub Product' AND Product__c = :mainProduct.Id AND Loan_Application__c = :opportunityId
            LIMIT 1
        ];

        // Step 3: Get Variant (RecordType = 'Variant') under Sub Product
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
    
}