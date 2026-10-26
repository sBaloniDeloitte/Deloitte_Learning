/*
* Created By : Akash Sharma
* Created Date : 11/04/2024
* Purpose : Lead to loan convertion class
*/

public with sharing class LeadToLoanConversionController {

    @AuraEnabled
    public static String createLoanFromLead(String leadId){        
        Opportunity loanObj = new Opportunity();
        loanObj.Channel_Type__c = 'Direct';
        loanObj.Lead__c = leadId;
        loanObj.Pincode__c = 'a01dN00000xlqiqQAA';
        loanObj.Product__c = 'Home Loan';
        loanObj.LeadSource = 'Website';
        loanObj.Requested_Amount__c = 500000;
        loanObj.CloseDate = System.today();
        loanObj.StageName = 'Sales Login';
        loanObj.Name = 'LA-000000001';
        insert loanObj;
        
        Application_Applicant__c appApt = new Application_Applicant__c();
        appApt.Loan_Application__c = loanObj.Id;
        appApt.Applicant_Type__c = 'Primary Applicant';
        appApt.Business_Type__c = 'General partnership';
        appApt.Business_Vintage__c = 5;
        appApt.Company__c = 'ABC Company Ltd';
        appApt.Customer_Profile__c = 'SEP';
        appApt.Customer_Type__c = 'Individual';
        appApt.DOB__c = Date.valueOf('1990-06-24');
        appApt.Email__c = 'akhsaini@deloitte.com';
        appApt.Customer__c = '001dN00000y6ArlQAE';
        appApt.First_Name__c = 'Abhilash';
        appApt.Gender__c = 'Male';
        appApt.Last_Name__c = 'Saini';
        appApt.Mobile_Number__c = '9987778956';
        appApt.PAN_Number__c = 'AAAPA1334A';
        insert appApt;
        
        
        Opportunity loanApplication = new Opportunity();
        loanApplication.Id = loanObj.Id;
        loanApplication.AccountId = '001dN00000y6ArlQAE';
        update loanApplication;
        
        Lead leadObj = new Lead();
        leadObj.Id = leadId;
        leadObj.Status = 'Closed - Converted';
        leadObj.Lead_Sub_Status__c = 'Converted';
        leadObj.Closed_Reasons__c = 'Converted to Loan Application';
        
        update leadObj;

        Income_Expense_Obligation__c original = [SELECT id,Year__c,Capital_In_Lacs__c,Reserves_and_Surplus_In_lacs__c,TotalExistingBorrowingsExclODCC_In_lacs__c,Total_Creditors_In_lacs__c,
            Total_Debtors_In_lacs__c,Closing_Stock_In_lacs__c,Bank_Cash_Balance__c,Balance_Sheet_Total_In_lacs__c,Sales_Turnover_In_lacs__c,
                                                     Net_Profit_In_lacs__c,Depreciation__c,CA_Name__c,CA_Number__c,Change_in_CA_firm_in_last_2_years__c,
                                                     CA_Result__c,Growth_in_Sales_In__c,Net_Profit_Margin_Ratio_in__c,Current_Ratio__c,
                                                     Cash_Conversion_Cycle_In_days__c,Debtor_turnover_In_days__c,Creditor_turnover_In_days__c,
                                                     Stock_turnover_In_days__c,Total_existing_borrowing_to_sales_In__c,
                                                     Average_OD__c,Interest_or_salary_to_directors_partners__c,Interest_paid_on_loans__c,
                                                     OD_limit__c,Other_one_time_income__c,EBIDTA__c,ITR_Filling_date__c,Type_of_financials__c 
                                                     FROM Income_Expense_Obligation__c where Id = 'a0kdN000002HdDWQA0' order by createddate desc LIMIT 1];

        Income_Expense_Obligation__c cloned = original.clone(false, true);
        System.debug('original + AMan' + original.Id);
        

        insert cloned;
        System.debug('clone + AMan' + cloned.Id);
        cloned.Application_Applicant__c = appApt.Id;
        cloned.Loan_Application__c  = loanObj.Id;
        cloned.Year__c  = '2024';
        cloned.Assessment_Year__c  = '2024';
        update cloned;
        System.debug('clone + AMan update' + cloned.Loan_Application__c);

        
        return loanObj.Id;
    }



    @AuraEnabled
    public static String createLoanFromLead1(String leadId){
        
        Set<String> leadFieldSet = new Set<String>();
        Map<String, String> leadAndLoanMapping = new Map<String, String>();
        
        
        Map<String,Lead_To_Loan__mdt> allMetaData = Lead_To_Loan__mdt.getAll();
        Map<String, String> leadAndCustomerMapping = new Map<String, String>();
        Map<String, String> leadAndAppAppMapping = new Map<String, String>();
        //System.debug('allMetaData-->'+allMetaData);
        if(!allMetaData.values().isEmpty()) {
            for(Lead_To_Loan__mdt leadMappings : allMetaData.values()) {
                //System.debug('leadMappings.Sobject__c=:'+leadMappings.Sobject__c);
                if (leadMappings.Sobject__c == 'Opportunity Field') {
                    leadAndLoanMapping.put(leadMappings.Lead_Field__c, leadMappings.Mapping_Field__c);
                    leadFieldSet.add(leadMappings.Lead_Field__c.tolowercase());
                }else if(leadMappings.Sobject__c == 'Customer Field') {
                    leadAndCustomerMapping.put(leadMappings.Lead_Field__c, leadMappings.Mapping_Field__c);
                    leadFieldSet.add(leadMappings.Lead_Field__c.tolowercase());
                }else if(leadMappings.Sobject__c == 'Application Applicant Field') {
                    leadAndAppAppMapping.put(leadMappings.Lead_Field__c, leadMappings.Mapping_Field__c);
                    leadFieldSet.add(leadMappings.Lead_Field__c.tolowercase());
                }
            } 
            
        }
        //System.debug('leadAndAppAppMapping=:'+leadAndAppAppMapping);
        
        /* for(LeadToOpportunity__mdt leadMappings : [SELECT Lead_Field__c, Opportunity_Field__c FROM LeadToOpportunity__mdt]){
leadAndLoanMapping.put(leadMappings.Lead_Field__c, leadMappings.Opportunity_Field__c);
leadFieldSet.add(leadMappings.Lead_Field__c.tolowercase());
}



for(LeadToCustomer__mdt custMappings : [SELECT Lead_Field__c, Customer_Field__c FROM LeadToCustomer__mdt]){
leadAndCustomerMapping.put(custMappings.Lead_Field__c, custMappings.Customer_Field__c);
leadFieldSet.add(custMappings.Lead_Field__c.tolowercase());
}


for(LeadToApplicationApplicant__mdt leadMappings : [SELECT Lead_Field__c, Application_Applicant_Field__c FROM LeadToApplicationApplicant__mdt]){
leadAndAppAppMapping.put(leadMappings.Lead_Field__c, leadMappings.Application_Applicant_Field__c);
leadFieldSet.add(leadMappings.Lead_Field__c.tolowercase());
}  */
        
        String fieldSet = String.join(leadFieldSet, ' , ');
        //system.debug('fieldSet: '+fieldSet);
        
        String query = 'Select ' + fieldSet + ' from Lead WHERE Id = \'' + leadId + '\'';
        Lead leadObj = Database.query(query);
        
        leadFieldSet.clear();
        
        Opportunity loanObj = new Opportunity();
        
        for(String mappingVal : leadAndLoanMapping.keySet()){
            loanObj.put(leadAndLoanMapping.get(mappingVal), leadObj.get(mappingVal));
        }
        
        //initial loan record values assign here
        insert loanObj;
        
        leadAndLoanMapping.clear();
        
        Account accObj = new Account();
        
        for(String mappingVal : leadAndCustomerMapping.keySet()){
           accObj.put(leadAndCustomerMapping.get(mappingVal), leadObj.get(mappingVal));
        }
        
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        accObj.RecordTypeId = customerRecordTypeId;
        insert accObj;
        
        leadAndCustomerMapping.clear();
        
        Application_Applicant__c appApt = new Application_Applicant__c();
        
        for(String mappingVal : leadAndAppAppMapping.keySet()){
            //System.debug('leadAndAppAppMapping.get(mappingVal)=:'+leadAndAppAppMapping.get(mappingVal));
            //System.debug('leadObj.get(mappingVal)=:'+leadObj.get(mappingVal));
            appApt.put(leadAndAppAppMapping.get(mappingVal), leadObj.get(mappingVal));
        }
        
        appApt.Loan_Application__c = loanObj.Id;
        appApt.Applicant_Type__c = Constants__mdt.getInstance('Primary_Applicant').Value__c;
        appApt.Customer__c = accObj.id;
        insert appApt;
        

        Opportunity loanApplication = new Opportunity();
        loanApplication.Id = loanObj.Id;
        loanApplication.AccountId = accObj.Id;
        update loanApplication;
        
        List<Document_Details__c> allLeadDocs = [SELECT Id, Loan_Application__c FROM Document_Details__c WHERE Lead__c =: leadId];
        if(allLeadDocs.size()>0){
            for(Document_Details__c iterDocs : allLeadDocs){
                iterDocs.Loan_Application__c = loanObj.Id;
            }
            update allLeadDocs;
        }
		
		Boolean insertappaddr = false;
        Lead ld = [Select Id,Pincode__c from Lead where id=:leadId];
        insertappaddr = SalesDocumentCmpController.insertApplicantAddress(loanObj.Id,appApt.Id,'Current',ld.Pincode__c,'','','');
        /*if(insertappaddr){
        System.debug('Applicant Address inserted succesfully');
        }
        else{
        System.debug('Error in inserting Applicant Address');
        }*/
        
        leadAndAppAppMapping.clear();
        
        leadObj.Status = Constants__mdt.getInstance('Closed').Value__c;
        leadObj.Lead_Sub_Status__c = Constants__mdt.getInstance('Converted').Value__c;
        leadObj.Closed_Reasons__c = Constants__mdt.getInstance('Converted_to_Loan_Application').Value__c;
        
        // LeadTriggerHandler.isTriggerDisabled = true;
        update leadObj;
        // LeadTriggerHandler.isTriggerDisabled = false;
        
        updateLoanBranchAndSubBranch(loanObj.Id);
        // Utility.insertTATRecords('C-003', loanObj.Id);
        return loanObj.Id;
    }

    @AuraEnabled
    public static void updateLoanBranchAndSubBranch(Id loanId){
        // try {
            //System.debug('UserInfo.getUserId() : '+UserInfo.getUserId());
            List<AccountTeamMember> accTeamList = [SELECT Id, AccountId, UserId FROM AccountTeamMember WHERE UserId =: UserInfo.getUserId() AND Is_Default_Branch__c = true];
            if(!accTeamList.isEmpty()){
                //System.debug('accTeamList : '+accTeamList);
                Set<Id> accountIds = new Set<Id>();
                for(AccountTeamMember accTeam : accTeamList) {
                    if(accTeam.AccountId != null){
                        accountIds.add(accTeam.AccountId);
                    }
                }
                Id accountBranchRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Branch').getRecordTypeId();
                if (!accountIds.isEmpty()) {
                    //System.debug('accountIds: '+accountIds);
                    List<Account> accs = [SELECT Id, ParentId FROM Account WHERE Id IN :accountIds AND ParentId != null AND RecordTypeId =: accountBranchRecType LIMIT 1];
                    if(!accs.isEmpty()){
                        //System.debug('accs: '+accs);
                        List<Opportunity> loanList = [SELECT Id, Branch_Master__c, Sub_Branch__c FROM Opportunity WHERE Id = :loanId LIMIT 1];
                        if(!loanList.isEmpty()){
                            //System.debug('loanList: '+loanList);
                            loanList[0].Sub_Branch__c = accs[0].Id;
                            loanList[0].Branch_Master__c = accs[0].ParentId;
                            update loanList;
                        }
                    }
                }
            }
        // } catch (Exception e) {
        //     throw new AuraHandledException(e.getMessage());
        // }
    }
}