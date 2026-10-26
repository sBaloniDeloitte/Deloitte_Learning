/*
* Created By : Akash Sharma
* Created Date : 11/04/2024
* Purpose : Lead to loan convertion class
*/

public without sharing class Comm_LeadToLoanConversionController {

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
        loanObj.Branch_Master__c = '001dN00000y3PKPQA2';
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

        // Income_Expense_Obligation__c original = [SELECT id,Year__c,Capital_In_Lacs__c,Reserves_and_Surplus_In_lacs__c,TotalExistingBorrowingsExclODCC_In_lacs__c,Total_Creditors_In_lacs__c,
        //     Total_Debtors_In_lacs__c,Closing_Stock_In_lacs__c,Bank_Cash_Balance__c,Balance_Sheet_Total_In_lacs__c,Sales_Turnover_In_lacs__c,
        //                                              Net_Profit_In_lacs__c,Depreciation__c,CA_Name__c,CA_Number__c,Change_in_CA_firm_in_last_2_years__c,
        //                                              CA_Result__c,Growth_in_Sales_In__c,Net_Profit_Margin_Ratio_in__c,Current_Ratio__c,
        //                                              Cash_Conversion_Cycle_In_days__c,Debtor_turnover_In_days__c,Creditor_turnover_In_days__c,
        //                                              Stock_turnover_In_days__c,Total_existing_borrowing_to_sales_In__c,
        //                                              Average_OD__c,Interest_or_salary_to_directors_partners__c,Interest_paid_on_loans__c,
        //                                              OD_limit__c,Other_one_time_income__c,EBIDTA__c,ITR_Filling_date__c,Type_of_financials__c 
        //                                              FROM Income_Expense_Obligation__c where Id = 'a0ra3002Fgnu8Hg' order by createddate desc LIMIT 1];

        // Income_Expense_Obligation__c cloned = original.clone(false, true);
        // System.debug('original + AMan' + original.Id);
        

        // insert cloned;
        // System.debug('clone + AMan' + cloned.Id);
        // cloned.Application_Applicant__c = appApt.Id;
        // cloned.Loan_Application__c  = loanObj.Id;
        // cloned.Year__c  = '2024';
        // cloned.Assessment_Year__c  = '2024';
        // update cloned;
        // System.debug('clone + AMan update' + cloned.Loan_Application__c);

        
        return loanObj.Id;
    }


    @AuraEnabled
    public static String createLoanFromLead1(String leadId){
        
        Set<String> leadFieldSet = new Set<String>();
        Map<String, String> leadAndLoanMapping = new Map<String, String>();
        Map<String, String> addressTypeMap = new Map<String, String>();
        Map<String, String> religionMap   = new Map<String, String>();
        Map<String, String> sectorMap     = new Map<String, String>();
        Map<String, String> industryMap   = new Map<String, String>();
        Map<String, String> genderMap     = new Map<String, String>();
        Map<String, String> casteMap      = new Map<String, String>();
        Map<String, String> natioanlityMap = new Map<String, String>();
        Map<String, String> salutationMap = new Map<String, String>();
         for (PLF_Master__c master : [
                SELECT Master_Type__c, Description__c, FICO_Code__c 
                FROM PLF_Master__c 
                WHERE Master_Type__c IN ('Address Type','Religion','Sector','Industry','Gender','Caste','Nationality','Salutation')
            ]) {
                if(master.Master_Type__c == 'Address Type') addressTypeMap.put(master.FICO_Code__c, master.Description__c);
                if(master.Master_Type__c == 'Religion') religionMap.put(master.FICO_Code__c, master.Description__c);
                if(master.Master_Type__c == 'Sector') sectorMap.put(master.FICO_Code__c, master.Description__c);
                if(master.Master_Type__c == 'Industry') industryMap.put(master.FICO_Code__c, master.Description__c);
                if(master.Master_Type__c == 'Gender') genderMap.put(master.FICO_Code__c, master.Description__c);
                if(master.Master_Type__c == 'Caste') casteMap.put(master.FICO_Code__c, master.Description__c);
                if(master.Master_Type__c == 'Nationality') natioanlityMap.put(master.FICO_Code__c, master.Description__c);
                if(master.Master_Type__c == 'Salutation') salutationMap.put(master.FICO_Code__c, master.Description__c);
            }

            Set<String> uniquePincodes = new Set<String>();
    
        
        Map<String,Lead_To_Loan__mdt> allMetaData = Lead_To_Loan__mdt.getAll();
        Map<String, String> leadAndCustomerMapping = new Map<String, String>();
        Map<String, String> leadAndAppAppMapping = new Map<String, String>();
        System.debug('allMetaData-->'+allMetaData);
        if(!allMetaData.values().isEmpty()) {
            for(Lead_To_Loan__mdt leadMappings : allMetaData.values()) {
                System.debug('leadMappings.Sobject__c=:'+leadMappings.Sobject__c);
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
        
        String query = 'Select RecordType.DeveloperName,Assigned_Sales_User__c,' + fieldSet + ' from Lead WHERE Id = \'' + leadId + '\'';
        Lead leadObj = Database.query(query);
        leadFieldSet.clear();
        Account accObj;
        Boolean isExistingCustomer = false;
        String hlCustomerLmsField;
        String customerLmsField;
        for(String key : leadAndCustomerMapping.keySet()){
            if(key == 'HL_Customer_LMS_ID__c'){
                hlCustomerLmsField = key;
                customerLmsField = leadAndCustomerMapping.get(key);
                break;
            }
        }
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        COMM_GetCustomerController.Response custRespFinal = new  COMM_GetCustomerController.Response();
        List<Account> existingAccList = new  List<Account> ();
        String leadLmsId;
        if(String.isNotBlank(hlCustomerLmsField)){
            leadLmsId=(String) leadObj.get(hlCustomerLmsField);
        }
      
        if(String.isNotBlank(leadLmsId)){
        COMM_GetCustomerController.ResponseWrapper finalResp = COMM_GetCustomerController.getCustomerDetails(leadLmsId, 'Get Customer');
        COMM_GetCustomerController.Response custResp = 
            (COMM_GetCustomerController.Response) JSON.deserialize(finalResp.respBody, COMM_GetCustomerController.Response.class);
        if (custResp == null || custResp.returnStatus == null || custResp.returnStatus.returnCode != '0000') {
            throw new AuraHandledException('Failed to fetch customer details for CIF: ' + leadLmsId);
        }
         custRespFinal = custResp;
               existingAccList= [
                SELECT Id, Customer_LMS_Id__c, Exisiting_Customer__c,Pan_Number__c
                FROM Account 
                WHERE Customer_LMS_Id__c = :leadLmsId AND Is_Active__c=true
                LIMIT 1
            ];
            if(!existingAccList.isEmpty()){
                accObj = existingAccList[0];
                accObj.Exisiting_Customer__c = true;
                isExistingCustomer = true;
            }
            else{
              accObj = new Account(
                Name = custResp.personalInfo.firstName + ' ' + custResp.personalInfo.middleName + ' ' + custResp.personalInfo.lastName,
                    First_Name__c = custResp.personalInfo.firstName,
                    Last_Name__c  = custResp.personalInfo.lastName,
                    Customer_LMS_Id__c = leadLmsId,
                    RecordTypeId = customerRecordTypeId,
                    Date_of_Birth__c = String.isNotBlank(custResp.personalInfo.dateofBirth) ? Date.valueOf(custResp.personalInfo.dateofBirth) : null,
                    PAN_Number__c = custResp.personalInfo.custCRCPR
                );
                if (custResp.categoryCode == 'RETAIL') {
                    if (custResp.extendedDetails != null && !custResp.extendedDetails.isEmpty()) {
                        for (COMM_GetCustomerController.cls_extendedDetails detail : custResp.extendedDetails) {
                            if (detail.extendedFields != null && !detail.extendedFields.isEmpty()) {
                                for (COMM_GetCustomerController.cls_extendedFields extField : detail.extendedFields) {
                                    if (extField.fieldName == 'IDNUMBER' && String.isNotBlank(extField.fieldValue)) {
                                        accObj.Aadhar_Number__c = String.valueOf(extField.fieldValue);
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        if(accObj == null){
            accObj = new Account();
            for(String mappingVal : leadAndCustomerMapping.keySet()){
                    accObj.put(leadAndCustomerMapping.get(mappingVal), leadObj.get(mappingVal));
            }
           
            accObj.RecordTypeId = customerRecordTypeId;
            insert accObj;
        } 
        else
        {
            upsert accObj;
        }
        
        
        // for(String mappingVal : leadAndCustomerMapping.keySet()){
        //    accObj.put(leadAndCustomerMapping.get(mappingVal), leadObj.get(mappingVal));
        // }
        
        // Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        // accObj.RecordTypeId = customerRecordTypeId;
        // insert accObj;
        
        leadAndCustomerMapping.clear();
        
        Application_Applicant__c appApt = new Application_Applicant__c();
        if(String.isNotBlank(leadLmsId)){
            String gender =genderMap.get(custRespFinal.personalInfo.gender);
               appApt = new Application_Applicant__c  (
                    Salutation__c       = salutationMap.get(custRespFinal.personalInfo.salutation),
                    Name                = custRespFinal.personalInfo.firstName + ' ' + custRespFinal.personalInfo.middleName + ' ' + custRespFinal.personalInfo.lastName,
                    Pan_Name__c         = custRespFinal.personalInfo.firstName + ' ' + custRespFinal.personalInfo.middleName + ' ' + custRespFinal.personalInfo.lastName,
                    First_Name__c       = custRespFinal.personalInfo.firstName,
                    Middle_Name__c      = custRespFinal.personalInfo.middleName,
                    Last_Name__c        = custRespFinal.personalInfo.lastName,
                    Customer_Type__c    = custRespFinal.categoryCode == 'RETAIL' ? 'Individual' : 'Non Individual',
                    Customer_Profile__c = custRespFinal.personalInfo.subCategory=='SALARIED'?'Salaried Indian':custRespFinal.personalInfo.subCategory,
                    Email__c            = (custRespFinal.emails != null && !custRespFinal.emails.isEmpty()) ? custRespFinal.emails[0].custEmail : null,
                    Mobile_Number__c    = (custRespFinal.phones != null && !custRespFinal.phones.isEmpty()) ? custRespFinal.phones[0].phoneNumber : null,
                    Gender__c           = gender=='Others'?'Male':gender,
                    Nationality__c      = natioanlityMap.get(String.valueOf(custRespFinal.personalInfo.nationality)),
                    PAN_Number__c       = custRespFinal.personalInfo.custCRCPR,
                    Cast_Category__c    = casteMap.get(String.valueOf(custRespFinal.personalInfo.caste)),
                    Religion__c         = religionMap.get(String.valueOf(custRespFinal.personalInfo.religion))
                   // Industry__c         = industryMap.get(custResp.personalInfo.industry),
                   // Sector__c           = sectorMap.get(custResp.personalInfo.sector),
                    
                );
        }
        if(String.isBlank(leadLmsId)){
            for(String mappingVal : leadAndAppAppMapping.keySet()){
                System.debug('leadAndAppAppMapping.get(mappingVal)=:'+leadAndAppAppMapping.get(mappingVal));
                System.debug('leadObj.get(mappingVal)=:'+leadObj.get(mappingVal));
                appApt.put(leadAndAppAppMapping.get(mappingVal), leadObj.get(mappingVal));
            }
        }
     
        
        
        
        Opportunity loanObj = new Opportunity();
        string recordTypeDevName = leadObj.RecordType.DeveloperName;
        for(String mappingVal : leadAndLoanMapping.keySet()){
            loanObj.put(leadAndLoanMapping.get(mappingVal), leadObj.get(mappingVal));
        }
        RecordTypeInfo oppRtInfo = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(recordTypeDevName);

        if (oppRtInfo != null) {
        loanObj.RecordTypeId = oppRtInfo.getRecordTypeId();
        }
        
        //initial loan record values assign here
        //insert loanObj;
        //Opportunity loanApplication = new Opportunity();
        //loanApplication.Id = loanObj.Id;
        loanObj.AccountId = accObj.Id;
        //update loanApplication;
        //loanObj.ownerId = UserInfo.getUserId();
        insert loanObj;
        //HL-Ishi-13/10/2025
        List<Opportunity> opp = [Select id,Product__c from Opportunity where id=: loanObj.id and Product__c!=null];
        if(opp.size()>0){
            List<Product_Master__c> prodMaster = [Select id,Name,HL_Maximum_LTV_as_per_Policy_1__c, HL_Maximum_LTV_as_per_Policy_2__c, HL_Maximum_LTV_as_per_Policy_3__c 
                                                    from Product_Master__c where Name=:opp[0].Product__c and RecordType.Name='Product' LIMIT 1];
            if(prodMaster.size()>0){
                if(opp[0].Product__c!='Flexi Loan'){
                Product2 prod = new Product2();
                prod.Name = opp[0].Product__c;
                prod.Loan_Application__c = opp[0].id;
                prod.Product_Master__c=prodMaster[0].id;
                prod.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
                prod.Product_Type__c='Parent';
                prod.HL_Maximum_LTV_as_per_Policy_1__c = prodMaster[0].HL_Maximum_LTV_as_per_Policy_1__c;
                prod.HL_Maximum_LTV_as_per_Policy_2__c = prodMaster[0].HL_Maximum_LTV_as_per_Policy_2__c;
                prod.HL_Maximum_LTV_as_per_Policy_3__c = prodMaster[0].HL_Maximum_LTV_as_per_Policy_3__c;
                // if(opp[0].Product__c=='Home Loan'){
                //     prod.Product_Type__c='Parent';
                // }
                insert prod;
                System.debug('Product----'+prod.Product_Type__c);
                }
                if(opp[0].Product__c=='Flexi Loan'){
                    
                        List<Product_Master__c> prodMasterRec = [Select Id, Name, RecordType.Name, HL_Maximum_LTV_as_per_Policy_1__c, HL_Maximum_LTV_as_per_Policy_2__c, HL_Maximum_LTV_as_per_Policy_3__c  from Product_Master__c WHERE IsApplicableForHL__c = true];
                        Map<String,Product_Master__c> nameToMasterMap = new Map<String,Product_Master__c>();
                        for(Product_Master__c iterMstr : prodMasterRec){
                            nameToMasterMap.put(iterMstr.Name, iterMstr);
                        }
                        Map<String, Product_Master__c> productMasterMap = new Map<String, Product_Master__c>(); 
                        Map<String, Product_Master__c> subProductMasterMap = new Map<String, Product_Master__c>(); 
                        Map<String, Product_Master__c> variantMasterMap = new Map<String, Product_Master__c>(); 
                        Map<String, Product_Master__c> subVariantMasterMap = new Map<String, Product_Master__c>(); 
                        Map<String, Product_Master__c> schemeMasterMap = new Map<String, Product_Master__c>(); 
                        for(Product_Master__c master: prodMasterRec){
                            if(master.RecordType.Name=='Product'){
                                productMasterMap.put(master.Name, master);
                            }
                            if(master.RecordType.Name=='Sub Product'){
                                subProductMasterMap.put(master.Name, master);
                            }
                            if(master.RecordType.Name=='Variant'){
                                variantMasterMap.put(master.Name, master);
                            }
                            if(master.RecordType.Name=='Sub Variant'){
                                subVariantMasterMap.put(master.Name, master);
                            }
                            if(master.RecordType.Name=='Scheme'){
                                schemeMasterMap.put(master.Name, master);
                            }
                        }   
                        Product2 prod = new Product2();
                        prod.Name = opp[0].Product__c;
                        prod.Loan_Application__c = opp[0].id;
                        prod.Product_Master__c=productMasterMap.get(opp[0].Product__c).id;
                        prod.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
                        prod.Product_Type__c='Parent';
                        prod.HL_Maximum_LTV_as_per_Policy_1__c = productMasterMap.get(opp[0].Product__c).HL_Maximum_LTV_as_per_Policy_1__c;
                        prod.HL_Maximum_LTV_as_per_Policy_2__c = productMasterMap.get(opp[0].Product__c).HL_Maximum_LTV_as_per_Policy_2__c;
                        prod.HL_Maximum_LTV_as_per_Policy_3__c = productMasterMap.get(opp[0].Product__c).HL_Maximum_LTV_as_per_Policy_3__c;
                        // if(opp[0].Product__c=='Home Loan'){
                        //     prod.Product_Type__c='Parent';
                        // }
                        
                        insert prod;
                        System.debug('Product----'+prod.Product_Type__c);
                        Id recTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Product').getRecordTypeId();
                        Id recTypeIdSubProduct = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Product').getRecordTypeId();
                        Id recTypeIdVariant = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Variant').getRecordTypeId();
                        Id recTypeIdSubVariant = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Variant').getRecordTypeId();
                        Id recTypeIdTenure = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Hybrid_Tenure').getRecordTypeId();
                        Id recTypeIdFullEmiTenure = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Full_EMI').getRecordTypeId();
                        Id recTypeIdScheme = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Scheme').getRecordTypeId();
                        Id recTypeIdTotalTnr = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Total_Tenure').getRecordTypeId();
                        
                        Product2 subProd = new Product2();
                        subProd.Loan_Application__c = opp[0].id;
                        subProd.Name ='Flexi Loan';
                        subProd.RecordTypeId = recTypeIdSubProduct;
                        subProd.Product_Master__c = subProductMasterMap.get('Flexi Loan').Id;
                        subProd.Product__c = prod.id;
                        Insert subProd;
                        Product2 varProd = new Product2();
                        varProd.Loan_Application__c =  opp[0].id;
                        varProd.Name = 'Term Loan';
                        varProd.RecordTypeId = recTypeIdVariant;
                        varProd.Product_Master__c = variantMasterMap.get('Term Loan').Id;
                        varProd.Product__c = subProd.Id;
                        Insert varProd;
                        Product2 subVar = new Product2();
                        subVar.Loan_Application__c =  opp[0].id;
                        String subVariant;
                        subVar.Name = 'Regular';
                        subVariant = 'Regular';
                        subVar.RecordTypeId = recTypeIdSubVariant;
                        subVar.Product_Master__c = subVariantMasterMap.get(subVariant).Id;
                        subVar.Product__c = subProd.Id;
                        subVar.Variant__c = varProd.Id;
                        Insert subVar;
                        Product2 schemeProd = new Product2();
                        schemeProd.Loan_Application__c =  opp[0].id;
                        schemeProd.Name = 'Regular';
                        schemeProd.RecordTypeId = recTypeIdScheme;
                        schemeProd.Product_Master__c = schemeMasterMap.get('Regular').Id;
                        schemeProd.Product__c = subProd.Id;
                        schemeProd.Variant__c = varProd.Id;
                        schemeProd.Sub_Variant__c = subVar.Id;
                        Insert schemeProd;
                       
                        
                }
            
            }
        }
        //HL-Ishi-13/10/2025
        System.debug('loan objId>'+loanObj.Id);
        System.debug('lead obj sales user>'+leadObj.Assigned_Sales_User__c);
        System.debug('opp owner Id>'+loanObj.ownerId);
        if(leadObj.Assigned_Sales_User__c != UserInfo.getUserId() && leadObj.Assigned_Sales_User__c != null){
            OpportunityShare oppShare = new OpportunityShare();
            oppShare.OpportunityId = loanObj.Id;
            oppShare.UserOrGroupId = leadObj.Assigned_Sales_User__c;
            oppShare.OpportunityAccessLevel = 'Edit';
            //if (Schema.SObjectType.OpportunityShare.isCreateable()) {
                insert oppShare;
           // }
            
            system.debug('oppShare'+oppShare);
        }
        appApt.Loan_Application__c = loanObj.Id;
        appApt.Applicant_Type__c = Constants__mdt.getInstance('Primary_Applicant').Value__c;
        if(leadObj.Company != null){
        appApt.Business_Entity_Name__c = leadObj.Company;
        }

        appApt.Customer__c = accObj.id;
       
        if(!existingAccList.isEmpty()){
            appApt.Pan_Number__c = existingAccList[0].Pan_Number__c;
        }
        insert appApt;
        List<Document_Details__c> allLeadDocs = [SELECT Id, Loan_Application__c FROM Document_Details__c WHERE Lead__c =: leadId];
        if(allLeadDocs.size()>0){
            for(Document_Details__c iterDocs : allLeadDocs){
                iterDocs.Loan_Application__c = loanObj.Id;
            }
            update allLeadDocs;
        }
		
		Boolean insertappaddr = false;
        Lead ld = [Select Id,Pincode__c from Lead where id=:leadId];
        //insertappaddr = SalesDocumentCmpController.insertApplicantAddress(loanObj.Id,appApt.Id,'Current',ld.Pincode__c,'','','');
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
        // List<TAT__c> tatRecList = Utility.insertTATRecords('C-003', loanObj.Id, '');
        // if(tatRecList.size()>0){
        //     insert tatRecList;
        // }
        return loanObj.Id;
    }

@AuraEnabled
public static void updateLoanBranchAndSubBranch(Id loanId){
    // try {
         Map<String,String> inputMap = new Map<String,String>();
         inputMap.put('oppId', loanId);
        Utility_V1.ProductWrapper wrp = Utility_V1.getProductDetails(inputMap);
        Boolean isHLRelated = wrp.isHLRelated; 
        List<Opportunity> loanList = [SELECT Id, Branch_Master__c, Sub_Branch__c, Sourcing_Manager__c FROM Opportunity WHERE Id = :loanId LIMIT 1];
        if(isHLRelated){
             loanList[0].Sourcing_Manager__c = UserInfo.getUserId();
        }
        //System.debug('UserInfo.getUserId() : '+UserInfo.getUserId());
        List<AccountTeamMember> accTeamList = [SELECT Id, AccountId, UserId FROM AccountTeamMember WHERE UserId =: UserInfo.getUserId()];
        if(!accTeamList.isEmpty()){
            //System.debug('accTeamList : '+accTeamList);
            Id accountBranchRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Branch').getRecordTypeId();
            // Query the child branch whose parent is the Opportunity's Branch_Master__c
            if(!loanList.isEmpty() && loanList[0].Branch_Master__c != null){
                List<Account> accs = [SELECT Id, ParentId FROM Account WHERE ParentId = :loanList[0].Branch_Master__c AND RecordTypeId =: accountBranchRecType LIMIT 1];
                if(!accs.isEmpty()){
                    //System.debug('accs: '+accs);
                    loanList[0].Sub_Branch__c = accs[0].Id;
                }
            }
            insert new OpportunityTeamMember(
                            OpportunityId          = loanId,
                            UserId                 = UserInfo.getUserId(),
                            TeamMemberRole         = 'Sales',
                            OpportunityAccessLevel = 'Edit',
                            Associated_With_Loan_Application__c = true
                         );
                         System.debug('OpportunityTeamMember inserted successfully' + loanId);
        }
        if(!loanList.isEmpty()){
            update loanList;
        }
    // } catch (Exception e) {
    //     throw new AuraHandledException(e.getMessage());
    // }
}    @AuraEnabled
    public static LoanDetailsWrapper createLoanFromLeadFL(Map<String,String> inputMap){
        LoanDetailsWrapper loanWrap = new LoanDetailsWrapper();
        String leadId= inputMap.get('recordId');
        Set<String> leadFieldSet = new Set<String>();
        Map<String, String> leadAndLoanMapping = new Map<String, String>();

    
        
        Map<String,Lead_To_Loan__mdt> allMetaData = Lead_To_Loan__mdt.getAll();
        Map<String, String> leadAndCustomerMapping = new Map<String, String>();
        Map<String, String> leadAndAppAppMapping = new Map<String, String>();
        System.debug('allMetaData-->'+allMetaData);
        if(!allMetaData.values().isEmpty()) {
            for(Lead_To_Loan__mdt leadMappings : allMetaData.values()) {
                System.debug('leadMappings.Sobject__c=:'+leadMappings.Sobject__c);
                if (leadMappings.Sobject__c == 'Opportunity Field') {
                    leadAndLoanMapping.put(leadMappings.Lead_Field__c, leadMappings.Mapping_Field__c);
                    leadFieldSet.add(leadMappings.Lead_Field__c.tolowercase());
                }
            } 
            
        }
  
        String fieldSet = String.join(leadFieldSet, ' , ');
        //system.debug('fieldSet: '+fieldSet);
        
        String query = 'Select RecordType.DeveloperName,Assigned_Sales_User__c,Parent_Loan_Number__c,FL_Source__c,' + fieldSet + ' from Lead WHERE Id = \'' + leadId + '\'';
        Lead leadObj = Database.query(query);
        leadFieldSet.clear();
         Opportunity loanObj = new Opportunity();
        string recordTypeDevName = leadObj.RecordType.DeveloperName;
        for(String mappingVal : leadAndLoanMapping.keySet()){
            loanObj.put(leadAndLoanMapping.get(mappingVal), leadObj.get(mappingVal));
        }
        RecordTypeInfo oppRtInfo = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(recordTypeDevName);

        if (oppRtInfo != null) {
        loanObj.RecordTypeId = oppRtInfo.getRecordTypeId();
		}
        insert loanObj;
        // List<Opportunity> opp = [Select id,Product__c from Opportunity where id=: loanObj.id and Product__c!=null];
        // if(opp.size()>0){
        //     List<Product_Master__c> prodMaster = [Select id,Name from Product_Master__c where Name=:opp[0].Product__c and RecordType.Name='Product' LIMIT 1];
        //     if(prodMaster.size()>0){
        //         Product2 prod = new Product2();
        //         prod.Name = opp[0].Product__c;
        //         prod.Loan_Application__c = opp[0].id;
        //         prod.Product_Master__c=prodMaster[0].id;
        //         prod.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        //         prod.Product_Type__c='Parent';
        //         // if(opp[0].Product__c=='Home Loan'){
        //         //     prod.Product_Type__c='Parent';
        //         // }
        //         insert prod;
        //     }
        // }
     
        if(leadObj.Assigned_Sales_User__c != UserInfo.getUserId() && leadObj.Assigned_Sales_User__c != null){
            OpportunityShare oppShare = new OpportunityShare();
            oppShare.OpportunityId = loanObj.Id;
            oppShare.UserOrGroupId = leadObj.Assigned_Sales_User__c;
            oppShare.OpportunityAccessLevel = 'Edit';
            //if (Schema.SObjectType.OpportunityShare.isCreateable()) {
                insert oppShare;
           // }
            
            system.debug('oppShare'+oppShare);
        }
      
        Lead ld = [Select Id,Pincode__c from Lead where id=:leadId];
       
        leadAndAppAppMapping.clear();
        
        leadObj.Status = Constants__mdt.getInstance('Closed').Value__c;
        leadObj.Lead_Sub_Status__c = Constants__mdt.getInstance('Converted').Value__c;
        leadObj.Closed_Reasons__c = Constants__mdt.getInstance('Converted_to_Loan_Application').Value__c;
        
        // LeadTriggerHandler.isTriggerDisabled = true;
        update leadObj;
        // LeadTriggerHandler.isTriggerDisabled = false;
        loanWrap.parentLoanNum=leadObj.Parent_Loan_Number__c;
        loanWrap.loanId=loanObj.Id;
        //COMM_SalesLoanLoginTopUpFlowController.createRelatedRecords(leadObj.Parent_Loan_Number__c,loanObj.Id);
        
        //updateLoanBranchAndSubBranch(loanObj.Id);
        // List<TAT__c> tatRecList = Utility.insertTATRecords('C-003', loanObj.Id, '');
        // if(tatRecList.size()>0){
        //     insert tatRecList;
        // }
        return loanWrap;
    }


     @AuraEnabled
    public static LoanDetailsWrapper cloneLoanApplicationFL(Map<String,String> inputMap) {
        LoanDetailsWrapper loanWrap = new LoanDetailsWrapper();
        try {
            System.debug('inputMap---'+inputMap);
            String loanNum= inputMap.get('loanNum');
            Opportunity opp=[Select id from Opportunity where Name=:loanNum];
            String sourceOppId =opp.id;
            String leadId =inputMap.get('recordId');
            String query = 'Select RecordType.DeveloperName,Assigned_Sales_User__c,Parent_Loan_Number__c,FL_Source__c from Lead WHERE Id = \'' + leadId + '\'';
            Lead leadObj = Database.query(query);
           
            string recordTypeDevName = leadObj.RecordType.DeveloperName;
            
            Map<String, Schema.SObjectField> oppToFieldMap = Schema.SObjectType.Opportunity.fields.getMap();
            List<String> oppFieldNames = new List<String>(oppToFieldMap.keySet());
            System.debug('Applicant Field Names: ' + oppFieldNames);


           String loanSOQL = 'SELECT ' + String.join(oppFieldNames, ',') + 
                       ' FROM Opportunity WHERE id = \'' + sourceOppId + '\'';
            RecordTypeInfo oppRtInfo = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(recordTypeDevName);
           
            List<Opportunity> oppToClone = Database.query(loanSOQL);
            Opportunity loanObj = oppToClone[0].clone(false,true,true,false);
            loanObj.StageName='Sales Login';
            loanObj.Sub_stage__c='Login in-progress';
            loanObj.RecordTypeId = oppRtInfo.getRecordTypeId();
            loanObj.Product__c='Flexi Loan';
            loanObj.Name='';
            insert loanObj;

            // loanObj.Parent_Loan_Application__c=sourceOppId;
            // insert loanObj;
            // === Clone Applicants ===
            Map<String, Schema.SObjectField> applicantFieldMap = Schema.SObjectType.Application_Applicant__c.fields.getMap();
            List<String> applicantFieldNames = new List<String>(applicantFieldMap.keySet());
            System.debug('Applicant Field Names: ' + applicantFieldNames);


           String applicantSOQL = 'SELECT ' + String.join(applicantFieldNames, ',') + 
                       ' FROM Application_Applicant__c WHERE Loan_Application__c = \'' + sourceOppId + '\'';

                                System.debug('Constructed SOQL query: ' + applicantSOQL);


            List<Application_Applicant__c> applicantsToClone = Database.query(applicantSOQL);

            Map<Id, Id> oldToNewApplicantIdMap = new Map<Id, Id>();
            if (!applicantsToClone.isEmpty()) {
                List<Application_Applicant__c> clonedApplicants = new List<Application_Applicant__c>();

                for (Application_Applicant__c oldApplicant : applicantsToClone) {
                    System.debug('Cloning applicant Customer_Profile__c: ' + oldApplicant.Customer_Profile__c);
                    if(oldApplicant.Customer_Profile__c == 'SENP'){
                        oldApplicant.Customer_Profile__c ='SEP';
                    }
                    Application_Applicant__c newApplicant = oldApplicant.clone(false, false, false, false);
                    newApplicant.Loan_Application__c = loanObj.id;
                    newApplicant.Consent_Status__c = '';
                    newApplicant.Cibil_Score__c = null;
                    newApplicant.Pan_Status__c = '';
                    newApplicant.Is_Consent_Received__c = false;
                    clonedApplicants.add(newApplicant);
                }
                system.debug('clonedApplicants---'+clonedApplicants);

                insert clonedApplicants;

                for (Integer i = 0; i < applicantsToClone.size(); i++) {
                    oldToNewApplicantIdMap.put(applicantsToClone[i].Id, clonedApplicants[i].Id);
                }
            }

            // === Clone Address__c related to Applicants ===
            if (!oldToNewApplicantIdMap.isEmpty()) {
                Map<String, Schema.SObjectField> addressFieldMap = Schema.SObjectType.Applicant_Address__c.fields.getMap();
                List<String> addressFieldNames = new List<String>(addressFieldMap.keySet());
                Set<Id> oldApplicantIds = oldToNewApplicantIdMap.keySet();

                List<String> applicantIds = new List<String>();
                for (Id idVal : oldApplicantIds) {
                    applicantIds.add('\'' + String.escapeSingleQuotes(idVal) + '\'');
                }

                String idString = String.join(applicantIds, ',');

                String soql = 'SELECT ' + String.join(addressFieldNames, ',') + ' FROM Applicant_Address__c WHERE Applicant__c IN (' + idString + ')';

                List<Applicant_Address__c> addressesToClone = Database.query(soql);


                if (!addressesToClone.isEmpty()) {
                    List<Applicant_Address__c> clonedAddresses = new List<Applicant_Address__c>();

                    for (Applicant_Address__c oldAddress : addressesToClone) {
                        Applicant_Address__c newAddress = oldAddress.clone(false, false, false, false);
                        newAddress.Applicant__c = oldToNewApplicantIdMap.get(oldAddress.Applicant__c);
                         newAddress.Loan_Application__c = loanObj.id;
                        clonedAddresses.add(newAddress);
                    }

                    insert clonedAddresses;
                }
            }

            // === Clone Application_Collateral__c ===
            List<Application_Collateral__c> existingCollaterals = [SELECT Id, Collateral__c FROM Application_Collateral__c WHERE HL_Loan_Application__c = :sourceOppId AND Collateral__r.IsActive__c =true];

            Map<Id, Id> oldToNewCollateralIdMap = new Map<Id, Id>();
            if (!existingCollaterals.isEmpty()) {
                List<Application_Collateral__c> clonedCollaterals = new List<Application_Collateral__c>();

                for (Application_Collateral__c ac : existingCollaterals) {
                    Application_Collateral__c newCollateral = new Application_Collateral__c(
                        HL_Loan_Application__c = loanObj.id,
                        Collateral__c = ac.Collateral__c
                    );
                    clonedCollaterals.add(newCollateral);
                }

                insert clonedCollaterals;

                for (Integer i = 0; i < existingCollaterals.size(); i++) {
                    oldToNewCollateralIdMap.put(existingCollaterals[i].Id, clonedCollaterals[i].Id);
                }
            }

            // === Clone Collateral_Owner__c ===
            if (!oldToNewCollateralIdMap.isEmpty() && !oldToNewApplicantIdMap.isEmpty()) {
                List<Collateral_Owner__c> ownersToClone = [SELECT Id, Application_Applicant__c, Application_Collateral__c FROM Collateral_Owner__c WHERE Application_Collateral__c IN :existingCollaterals];

                if (!ownersToClone.isEmpty()) {
                    List<Collateral_Owner__c> clonedOwners = new List<Collateral_Owner__c>();

                    for (Collateral_Owner__c oldOwner : ownersToClone) {
                        Collateral_Owner__c newOwner = new Collateral_Owner__c();
                        newOwner.Application_Applicant__c = oldToNewApplicantIdMap.get(oldOwner.Application_Applicant__c);
                        newOwner.Application_Collateral__c = oldToNewCollateralIdMap.get(oldOwner.Application_Collateral__c);
                        clonedOwners.add(newOwner);
                    }

                    insert clonedOwners;
                }
            }

            if(leadObj.Assigned_Sales_User__c != UserInfo.getUserId() && leadObj.Assigned_Sales_User__c != null){
            OpportunityShare oppShare = new OpportunityShare();
            oppShare.OpportunityId = loanObj.Id;
            oppShare.UserOrGroupId = leadObj.Assigned_Sales_User__c;
            oppShare.OpportunityAccessLevel = 'Edit';
            //if (Schema.SObjectType.OpportunityShare.isCreateable()) {
                insert oppShare;
           // }
                
                system.debug('oppShare'+oppShare);
            }
        
            Lead ld = [Select Id,Pincode__c from Lead where id=:leadId];
            leadObj.Status = Constants__mdt.getInstance('Closed').Value__c;
            leadObj.Lead_Sub_Status__c = Constants__mdt.getInstance('Converted').Value__c;
            leadObj.Closed_Reasons__c = Constants__mdt.getInstance('Converted_to_Loan_Application').Value__c;
            update leadObj;
            loanWrap.parentLoanNum=leadObj.Parent_Loan_Number__c;
            loanWrap.loanId=loanObj.Id;
            updateLoanBranchAndSubBranch(loanObj.Id);
            // List<TAT__c> tatRecList = Utility.insertTATRecords('C-003', loanObj.Id, '');
            // if(tatRecList.size()>0){
            //     insert tatRecList;
            // }
            Map<String,String> cloneFLMap = new  Map<String,String>();
            cloneFLMap.put('oppToUpdate',loanObj.Id);
            insertFLProduct(cloneFLMap);
            return loanWrap;

        } catch (Exception e) {
            return loanWrap;
        }
    }

    public class LoanDetailsWrapper{
        @AuraEnabled public String parentLoanNum;
        @AuraEnabled public Id loanId;
    }

    @AuraEnabled
    public static void insertFLProduct(Map<String,String> inputMap){
        try {
            String oppToUpdate = inputMap.get('oppToUpdate');
            List<Product_Master__c> prodMaster = [Select Id, Name, RecordType.Name from Product_Master__c];
            Map<String,Product_Master__c> nameToMasterMap = new Map<String,Product_Master__c>();
            for(Product_Master__c iterMstr : prodMaster){
                nameToMasterMap.put(iterMstr.Name, iterMstr);
            }
            Id recTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Product').getRecordTypeId();
            Id recTypeIdSubProduct = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Product').getRecordTypeId();
            Id recTypeIdVariant = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Variant').getRecordTypeId();
            Id recTypeIdSubVariant = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Variant').getRecordTypeId();
            Id recTypeIdTenure = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Hybrid_Tenure').getRecordTypeId();
            Id recTypeIdFullEmiTenure = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Full_EMI').getRecordTypeId();
            Id recTypeIdScheme = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Scheme').getRecordTypeId();
            Id recTypeIdTotalTnr = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Total_Tenure').getRecordTypeId();
            String loanProd = [Select id,Product__c from Opportunity where id=:oppToUpdate].Product__c;
            List<Product_Master__c> prod= new List<Product_Master__c>();
            prod=[Select id from Product_Master__c where RecordType.Name='Product' and Name=:loanProd AND IsApplicableForHL__c = true Limit 1];
            if(loanProd !='Flexi Loan'){
             
                Product2 mainProd = new Product2();
                mainProd.Loan_Application__c =oppToUpdate;
                mainProd.Name = 'Home Loan';
                mainProd.RecordTypeId = recTypeId;
                mainProd.Product_Master__c = nameToMasterMap.get('Home Loan').Id;
                if(prod.size()==0){
                    Insert mainProd;
                }
                else{
                    mainProd.Id =prod[0].id;
                    update mainProd;

                }
            
                Product2 subProd = new Product2();
                subProd.Loan_Application__c = oppToUpdate;
                subProd.Name ='HL Top up';
                subProd.RecordTypeId = recTypeIdSubProduct;
                subProd.Product_Master__c = nameToMasterMap.get('HL Top up').Id;
                subProd.Product__c = mainProd.Id;
                Insert subProd;
                Product2 varProd = new Product2();
                varProd.Loan_Application__c = oppToUpdate;
                varProd.Name = 'Term Loan';
                varProd.RecordTypeId = recTypeIdVariant;
                varProd.Product_Master__c = nameToMasterMap.get('Term Loan').Id;
                varProd.Product__c = subProd.Id;
                Insert varProd;
                Product2 subVar = new Product2();
                subVar.Loan_Application__c =oppToUpdate;
                String subVariant;
                subVar.Name = 'Regular';
                subVariant = 'Regular';
                subVar.RecordTypeId = recTypeIdSubVariant;
                subVar.Product_Master__c = nameToMasterMap.get(subVariant).Id;
                subVar.Product__c = subProd.Id;
                subVar.Variant__c = varProd.Id;
                Insert subVar;
                Product2 schemeProd = new Product2();
                schemeProd.Loan_Application__c = oppToUpdate;
                schemeProd.Name = 'Regular';
                schemeProd.RecordTypeId = recTypeIdScheme;
                schemeProd.Product_Master__c = nameToMasterMap.get('Regular').Id;
                schemeProd.Product__c = subProd.Id;
                schemeProd.Variant__c = varProd.Id;
                schemeProd.Sub_Variant__c = subVar.Id;
                Insert schemeProd;
            }
            else{
            Product2 prodMain = new Product2();
            prodMain.Name = loanProd;
            prodMain.Loan_Application__c =  oppToUpdate;
            prodMain.Product_Master__c=prod[0].id;
            prodMain.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
            prodMain.Product_Type__c='Parent';
            // if(opp[0].Product__c=='Home Loan'){
            //     prod.Product_Type__c='Parent';
            // }
            insert prodMain;
            System.debug('Product----'+prodMain.Product_Type__c);
            if(loanProd=='Flexi Loan'){
                
                    List<Product_Master__c> prodMasterRec = [Select Id, Name, RecordType.Name from Product_Master__c where IsApplicableForHL__c = true];
              
                for(Product_Master__c iterMstr : prodMasterRec){
                    nameToMasterMap.put(iterMstr.Name, iterMstr);
                }
                    Map<String, Product_Master__c> subProductMasterMap = new Map<String, Product_Master__c>(); 
                    Map<String, Product_Master__c> variantMasterMap = new Map<String, Product_Master__c>(); 
                    Map<String, Product_Master__c> subVariantMasterMap = new Map<String, Product_Master__c>(); 
                    Map<String, Product_Master__c> schemeMasterMap = new Map<String, Product_Master__c>(); 
                    for(Product_Master__c master: prodMasterRec){
                        if(master.RecordType.Name=='Sub Product'){
                            subProductMasterMap.put(master.Name, master);
                        }
                        if(master.RecordType.Name=='Variant'){
                            variantMasterMap.put(master.Name, master);
                        }
                        if(master.RecordType.Name=='Sub Variant'){
                            subVariantMasterMap.put(master.Name, master);
                        }
                        if(master.RecordType.Name=='Scheme'){
                            schemeMasterMap.put(master.Name, master);
                        }
                    }                      
                Product2 subProd = new Product2();
                subProd.Loan_Application__c = oppToUpdate;
                subProd.Name ='Flexi Loan';
                subProd.RecordTypeId = recTypeIdSubProduct;
                    subProd.Product_Master__c = subProductMasterMap.get('Flexi Loan').Id;
                subProd.Product__c = prodMain.id;
                Insert subProd;
                Product2 varProd = new Product2();
                varProd.Loan_Application__c = oppToUpdate;
                varProd.Name = 'Term Loan';
                varProd.RecordTypeId = recTypeIdVariant;
                    varProd.Product_Master__c = variantMasterMap.get('Term Loan').Id;
                varProd.Product__c = subProd.Id;
                Insert varProd;
                Product2 subVar = new Product2();
                subVar.Loan_Application__c =oppToUpdate;
                String subVariant;
                subVar.Name = 'Regular';
                subVariant = 'Regular';
                subVar.RecordTypeId = recTypeIdSubVariant;
                    subVar.Product_Master__c = subVariantMasterMap.get(subVariant).Id;
                subVar.Product__c = subProd.Id;
                subVar.Variant__c = varProd.Id;
                Insert subVar;
                Product2 schemeProd = new Product2();
                schemeProd.Loan_Application__c =oppToUpdate;
                schemeProd.Name = 'Regular';
                schemeProd.RecordTypeId = recTypeIdScheme;
                    schemeProd.Product_Master__c = schemeMasterMap.get('Regular').Id;
                schemeProd.Product__c = subProd.Id;
                schemeProd.Variant__c = varProd.Id;
                schemeProd.Sub_Variant__c = subVar.Id;
                Insert schemeProd;
            }
        }
                    
        
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}