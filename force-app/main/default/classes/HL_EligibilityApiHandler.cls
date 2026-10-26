/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-17-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class HL_EligibilityApiHandler implements IntegrationInterface{

    static string conLabels = 'CUSTOMER_TYPE_INDIVIDUAL,Zero,PLF,GHF,Zero_Decimal,Primary_Applicant,Division,BUTTON,Bank_Statement_Document,Interest_Day_Basis,isGrossProfitGrowthSutainable';

    public static Map<string, string> constants = Utility.getConstants(conLabels);
    public static Boolean isFromSalesModule = false;

    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }

    public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();

        try{
            String loanId = wrapper.loanApplicationId;

            Opportunity loanObj = [SELECT Id, Name, Branch_Master__r.Branch_Code__c, Resanction__c, HL_Construction_Stage__c, Loan_Hierarchy__c 
                                    FROM Opportunity WHERE Id =: loanId];
            
            isFromSalesModule = wrapper.isIncomeFromSales;

            Product2 subProduct = [SELECT Id, Requested_Loan_Amount__c, Product__r.Product_Type__c, Product__r.Name FROM Product2 
                                    WHERE Loan_Application__c =: loanId AND RecordType.Name = 'Sub Product' 
                                    AND Product__r.RecordType.Name = 'Product' And Product__r.Name =: wrapper.productName LIMIT 1];

            if(wrapper.isIncomeFromSales || loanObj.Resanction__c){
                return errorMessages;
            }

            //Income Program
            string incProgName = '';
            Set<Id> incomeAppIds = new Set<Id>();
            Set<Id> parentRecIdSet = new Set<Id>();
            List<Income_Assessment__c> incomProgList = [Select Id, Applicant__c, RecordType.Name From Income_Assessment__c 
                                                        Where Loan_Application__c =: loanId And Parent__c = null
                                                        And RecordType.Name IN ('Salaried Individual','Cash Profit','Salaried NRI','Director Renumeration','Sep Multiplier','Gross Margin','Merchant Navy','Banking','Low LTV Program')];

            if(!incomProgList.isEmpty()){
                for(Income_Assessment__c rec : incomProgList){
                    parentRecIdSet.add(rec.Id);
                    incomeAppIds.add(rec.Applicant__c);
                    incProgName = rec.RecordType.Name;
                }

                List<Income_Assessment__c> childRecList = [Select Id From Income_Assessment__c Where Parent__c IN : parentRecIdSet 
                                                            And RecordType.Name IN ('Salaried Individual','Salaried Incentive Component','Salaried Yearly Component','Cash Profit','Salaried NRI','Director Renumeration','Sep Multiplier','Gross Margin','Child Rental Income','Merchant Navy','Banking','Low LTV Program')];

                if(!childRecList.isEmpty()){}
                else{
                    errorMessages.add('Error: Data not filled in selected Income Program');
                }
            }
            else{
                errorMessages.add('Error: Income Program not selected');
            }

            List<Bank_Details__c> applicantBanks = new List<Bank_Details__c>();

            if(incProgName != 'Merchant Navy' && incProgName != 'Salaried NRI'){
                applicantBanks = [SELECT id, Name, Account_Type__c, Account_Number__c, OD_CC_Limit__c, Application_Applicant__c, Account_type_FICO__c,
                                    Account_Holder_Name__c
                                    FROM Bank_Details__c WHERE Application_Applicant__c IN : incomeAppIds AND Is_Consider_for_Eligibility__c = true];

                if(applicantBanks.isEmpty()){
                    errorMessages.add('Error: Kindly select a bank account to be considered for eligibility.');
                }
            }

            if(subProduct.Product__r.Product_Type__c == 'Child'){
                List<Product2> subProductParent = [SELECT Id, EMI_Amount__c FROM Product2 WHERE Loan_Application__c =: loanId AND RecordType.Name = 'Sub Product' 
                                                    AND Product__r.RecordType.Name = 'Product' AND Product__r.Product_Type__c = 'Parent' And EMI_Amount__c != null LIMIT 1];
                
                if(subProductParent.isEmpty()){
                    errorMessages.add('Error: Please call BRE for parent product first!');
                }
            }

            if(loanObj.HL_Construction_Stage__c == null){
                errorMessages.add('Error: Construction Stage missing on LA');
            }

            if(wrapper.eligibilityType == 'Income Eligibility'){
                return errorMessages;
            }

            if(loanObj.Branch_Master__r == null || loanObj.Branch_Master__r.Branch_Code__c == null){
                errorMessages.add('Error: Branch details missing on LA');
            }

            Map<String, String> conDocIds = new Map<String, String>();
            Map<String, String> applicantTuffRes = new Map<String, String>();
            Map<String, List<Document_Details__c>> kycDocumentMap = new Map<String, List<Document_Details__c>>();
            Map<String, List<Applicant_Address__c>> applicatAddressMap = new Map<String, List<Applicant_Address__c>>();
            Map<String, List<Bank_Details__c>> applicantBanksMap = new Map<String, List<Bank_Details__c>>();

            List<Application_Applicant__c> lstApplicants = [SELECT Id, Name, Customer_Type__c, DOB__c, Marital_Status__c, Customer__r.SF_Customer_ID__c, DOI__c, Aadhaar_Number__c,
                                                            Cast_Category__c, Applicant_Type__c, Qualification__c, Sub_Segment__c, Sector__c, Industry__c, Total_Work_Experience_Years__c, 
                                                            Employment_Type__c, Customer_Profile__c, Residency_Status__c, Mobile_Number__c, Email__c, PAN_Number__c,
                                                            Passport_Date_of_Issue__c, Passport_Date_of_Expiry__c, Voter_ID_Number__c, Passport_Number__c, Drivers_License_Number__c 
                                                            FROM Application_Applicant__c WHERE Id =: incomeAppIds AND (Applicant_Type__c = 'Primary Applicant' OR Applicant_Type__c = 'Co Applicant')];

            if(lstApplicants.isEmpty()){
                errorMessages.add('Error: No record found for Applicant Type Primary or Co Applicant.');
            }
            else{
                for(Bank_Details__c iterBanks : applicantBanks) {
                    if(applicantBanksMap.containsKey(iterBanks.Application_Applicant__c)) {
                        applicantBanksMap.get(iterBanks.Application_Applicant__c).add(iterBanks);
                    }else {
                        applicantBanksMap.put(iterBanks.Application_Applicant__c, new List<Bank_Details__c>{iterBanks});
                    }
                }

                for(Document_Details__c docIter : [SELECT Id, Name, Content_Document_Id__c, Applicant__c, Document_Master__r.Document_Type__c, Document_Master__r.Document_Category__c, Consider_for_Loan_Application__c
                                                    From Document_Details__c Where Applicant__c IN : lstApplicants And ((Document_Master__r.Document_Category__c = 'POA') Or Name IN ('Cibil Response','Bank_Statement_Document')) 
                                                    Order by CREATEDDATE DESC]) {

                    if(docIter.Document_Master__r.Document_Category__c == 'POA' && docIter.Consider_for_Loan_Application__c == true){
                        if(kycDocumentMap.containsKey(docIter.Applicant__c)) {
                            kycDocumentMap.get(docIter.Applicant__c).add(docIter);
                        }
                        else {
                            kycDocumentMap.put(docIter.Applicant__c, new List<Document_Details__c>{docIter});
                        }
                    }
                    else {
                        if(docIter.Name == 'Cibil Response'){
                            conDocIds.put(docIter.Content_Document_Id__c, docIter.Applicant__c);
                        }
                    }
                }

                for(ContentVersion iterConVersion : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN : conDocIds.keySet()]) {
                    applicantTuffRes.put(conDocIds.get(iterConVersion.ContentDocumentId), 'CIBIL Report');
                }

                for(Applicant_Address__c iterAdd : [SELECT Id, Name, Applicant__c, Address_Type__c, Pincode__r.City__r.Name, Address_Priority__c
                                                    FROM Applicant_Address__c WHERE Applicant__c IN : lstApplicants And Document_Details__c != null 
                                                    And Address_Priority__c In ('5','4')]) {

                    if(applicatAddressMap.containsKey(iterAdd.Applicant__c)) {
                        applicatAddressMap.get(iterAdd.Applicant__c).add(iterAdd);
                    }
                    else {
                        applicatAddressMap.put(iterAdd.Applicant__c, new List<Applicant_Address__c>{iterAdd});
                    }
                }

                for(Application_Applicant__c app : lstApplicants){
                    if(app.Customer__r == null || app.Customer__r.SF_Customer_ID__c == null){
                        errorMessages.add('Error: Customer CIF missing for applicant - '+ app.Name);
                    }
                    if(String.isBlank(app.Applicant_Type__c)){
                        errorMessages.add('Error: Applicant Type missing for applicant - '+ app.Name);
                    }
                    if(String.isBlank(app.Customer_Profile__c)){
                        errorMessages.add('Error: Customer Profile missing for applicant - '+ app.Name);
                    }
                    if(String.isBlank(app.Residency_Status__c)){
                        errorMessages.add('Error: Residency Status missing for applicant - '+ app.Name);
                    }
                    if(String.isBlank(app.Mobile_Number__c)){
                        errorMessages.add('Error: Mobile No missing for applicant - '+ app.Name);
                    }
                    if(String.isBlank(app.Email__c)){
                        errorMessages.add('Error: Email missing for applicant - '+ app.Name);
                    }

                    if(app.Customer_Type__c == constants.get('CUSTOMER_TYPE_INDIVIDUAL')){
                        if(app.DOB__c == null){
                            errorMessages.add('Error: DOB missing for applicant - '+ app.Name);
                        }
                        if(app.Qualification__c == null){
                            errorMessages.add('Error: Qualification missing for applicant - '+ app.Name);
                        }
                        if(String.isBlank(app.Marital_Status__c)){
                            errorMessages.add('Error: Maritial Status missing for applicant - '+ app.Name);
                        }
                        if(String.isBlank(app.Cast_Category__c)){
                            errorMessages.add('Error: Caste missing for applicant - '+ app.Name);
                        }

                        if(incProgName == 'SEP Multiplier' && app.Total_Work_Experience_Years__c == null){
                            errorMessages.add('Error: Total work experience years missing for applicant - '+ app.Name);
                        }
                        else if(incProgName == 'Director Renumeration' && app.Customer_Profile__c != 'SENP'){
                            errorMessages.add('Error: Customer Profile should be SENP for Director Renumeration income program for applicant - '+ app.Name);
                        }

                        if(!applicantTuffRes.containsKey(app.Id)){
                            errorMessages.add('Error: CIBIL report missing for applicant - '+ app.Name);
                        }
                    }
                    else{
                        if(app.DOI__c == null){
                            errorMessages.add('Error: DOI missing for applicant - '+ app.Name);
                        }
                        if(app.Sector__c == null){
                            errorMessages.add('Error: Sector missing for applicant - '+ app.Name);
                        }
                        else if((app.Sector__c == 'Doctor' || app.Sector__c == 'Dentist') && app.Sub_Segment__c == null){
                            errorMessages.add('Error: Sub Segment missing for applicant - '+ app.Name);
                        }
                        if(app.Industry__c == null){
                            errorMessages.add('Error: Industry missing for applicant - '+ app.Name);
                        }
                    }

                    //Document
                    if(kycDocumentMap.containsKey(app.Id)){
                        for(Document_Details__c docRec : kycDocumentMap.get(app.Id)){
                            if(docRec.Document_Master__r.Document_Type__c == null){
                                errorMessages.add('Error: Document Type missing for document - '+ docRec.Name);
                            }

                            // if(app.Customer_Type__c == constants.get('CUSTOMER_TYPE_INDIVIDUAL')){
                            //     if(docRec.Name.contains('Passport')){
                            //         if(app.Passport_Number__c == null){
                            //             errorMessages.add('Error: Passport Number missing for applicant - '+ app.Name);
                            //         }
                            //         if(app.Passport_Date_of_Issue__c == null){
                            //             errorMessages.add('Error: Passport Issue Date missing for applicant - '+ app.Name);
                            //         }
                            //         if(app.Passport_Date_of_Expiry__c == null){
                            //             errorMessages.add('Error: Passport Expiry Date missing for applicant - '+ app.Name);
                            //         }
                            //     }
                            //     else if(docRec.Name.contains('Voter')){
                            //         if(app.Voter_ID_Number__c == null){
                            //             errorMessages.add('Error: Voter Id missing for applicant - '+ app.Name);
                            //         }
                            //     }
                            //     else if(docRec.Name.contains('Adhaar') || docRec.Name.contains('Aadhaar')){
                            //         if(app.Aadhaar_Number__c == null){
                            //             errorMessages.add('Error: Aadhaar No missing for applicant - '+ app.Name);
                            //         }
                            //     }
                            //     else if(docRec.Name.contains('Driving License') || docRec.Name.contains('DL')){
                            //         if(app.Drivers_License_Number__c == null){
                            //             errorMessages.add('Error: DL No missing for applicant - '+ app.Name);
                            //         }
                            //     }
                            // }

                            if(docRec.Name.contains('PAN')){
                                if(app.PAN_Number__c == null){
                                    errorMessages.add('Error: PAN missing for applicant - '+ app.Name);
                                }
                            }
                        }
                    }
                    else{
                        errorMessages.add('Error: POA document missing for applicant - '+ app.Name);
                    }
                    //Document

                    //Address
                    if(applicatAddressMap.containsKey(app.Id)){
                        for(Applicant_Address__c addRec : applicatAddressMap.get(app.Id)){
                            if(addRec.Address_Type__c == null){
                                errorMessages.add('Error: Address Type missing for address - '+ addRec.Name);
                            }
                            if(addRec.Pincode__r == null || addRec.Pincode__r.City__r.Name == null){
                                errorMessages.add('Error: Pincode details missing for address - '+ addRec.Name);
                            }
                            if(addRec.Address_Priority__c == null){
                                errorMessages.add('Error: Address Priority missing for address - '+ addRec.Name);
                            }
                        }
                    }
                    else{
                        errorMessages.add('Error: Address details missing for applicant - '+ app.Name);
                    }
                    //Address

                    //Bank details
                    if(applicantBanksMap.containsKey(app.Id)){
                        for(Bank_Details__c iterAppBank : applicantBanksMap.get(app.Id)) {
                            if(iterAppBank.Account_Holder_Name__c == null){
                                errorMessages.add('Error: Account Holder Name missing for bank - '+ iterAppBank.Name);
                            }
                            if(iterAppBank.Account_Type__c == null){
                                errorMessages.add('Error: Account Type missing for bank - '+ iterAppBank.Name);
                            }
                            if(iterAppBank.Account_Number__c == null){
                                errorMessages.add('Error: Account Number missing for bank - '+ iterAppBank.Name);
                            }
                        }
                    }
                    else{
                        if(incProgName != 'Merchant Navy' && incProgName != 'Salaried NRI'){
                            errorMessages.add('Error: Kindly select a bank account to be considered for eligibility for '+ app.Name);
                        }
                    }
                    //Bank details
                }

                // //FI, FCU, PD
                // integer fiCount = 0;
                // integer fcuCount = 0;
                // integer pdCount = 0;
                // for(Application_Verification__c av : [Select Id, Name, Address_Type__c, Verification_Remarks__c, RecordType.Name, Vendor__r.Name, Banking_Details__c, 
                //                                         Stage__c, IsParent__c, Type_of_Address__c
                //                                         From Application_Verification__c Where Applicant__c IN : lstApplicants 
                //                                         And RecordType.Name IN ('Business Verification', 'Residence Verification', 'Collateral Verification', 'FCU', 'Personal Discussion AHL')]){

                //     if(av.RecordType.Name == 'Business Verification' || av.RecordType.Name == 'Collateral Verification' || av.RecordType.Name == 'Residence Verification'){
                //         if(av.Stage__c != 'Waived'){
                //             if(av.Address_Type__c == null){
                //                 errorMessages.add('Error: Address Type missing for '+ av.RecordType.Name +' - '+ av.Name);
                //             }
                //             if(av.Verification_Remarks__c == null){
                //                 errorMessages.add('Error: Verification Remarks missing for '+ av.RecordType.Name +' - '+ av.Name);
                //             }
                //             if(av.Vendor__r == null || av.Vendor__r.Name == null){
                //                 errorMessages.add('Error: Vendor details missing for '+ av.RecordType.Name.replace(' AHL', '') +' verification - '+ av.Name);
                //             }
                //         }
                        
                //         fiCount++;
                //     }
                //     else if(av.RecordType.Name == 'FCU'){
                //         if(av.IsParent__c){
                //             if(av.Verification_Remarks__c == null){
                //                 errorMessages.add('Error: Verification Remarks missing for FCU verification - '+ av.Name);
                //             }
                //             if(av.Vendor__r == null || av.Vendor__r.Name == null){
                //                 errorMessages.add('Error: Vendor details missing for '+ av.RecordType.Name.replace(' AHL', '') +' verification - '+ av.Name);
                //             }
                //         }

                //         fcuCount++;
                //     }
                //     else if(av.RecordType.Name == 'Personal Discussion AHL'){
                //         if(av.Type_of_Address__c == null){
                //             errorMessages.add('Error: type of address missing for Personal Discussion verification - '+ av.Name);
                //         }

                //         pdCount++;
                //     }
                // }

                // if(fiCount == 0){
                //     errorMessages.add('Error: FI verification not found');
                // }
                // if(fcuCount == 0){
                //     errorMessages.add('Error: FCU verification not found');
                // }
                // if(pdCount == 0){
                //     errorMessages.add('Error: PD verification not found');
                // }
                // //FI, FCU, PD
            }

            string prodTransactionType;
            string prodLoanPurpose;
            Product2 prodObj;
            
            for(Product2 rec : [SELECT Id, Name, RecordType.Name, Variant__r.Name, Variant__r.PLR_Value__c,Product__r.Product_Type__c FROM product2 WHERE Loan_Application__c =: loanId 
                                And Product__c =: subProduct.Id And RecordType.Name IN ('Total Tenure','Transaction Type','Loan Purpose')]){

                switch on rec.RecordType.Name {
                    when 'Total Tenure' {
                        prodObj = rec;
                    }
                    when 'Transaction Type' {
                        prodTransactionType = rec.Name;
                    }
                    when 'Loan Purpose' {
                        prodLoanPurpose = rec.Name;
                    }
                }
            }

            if(prodObj == null || prodObj.Variant__r == null || prodObj.Variant__r.Name == null){
                errorMessages.add('Error: Variant details missing on product');
            }
            // if(prodObj?.Variant__r?.PLR_Value__c == null){
            //     errorMessages.add('Error: PLR value missing on Variant');
            // }
            if(prodTransactionType == null){
                errorMessages.add('Error: Transaction Type missing on Product');
            }
            if(prodLoanPurpose == null){
                errorMessages.add('Error: Loan Purpose missing on Product');
            }

            if(loanObj.Loan_Hierarchy__c != 'Child' && subProduct.Product__r.Name == 'Home Loan'){
                //Collateral
                List<Application_Collateral__c> collList = [Select Id, Name, Collateral__r.Builder__r.Name, Collateral__r.Collateral_Type__c,
                                                            Collateral__r.APF__c, Collateral__r.Market_Value__c, Collateral__r.Current_Usage__c
                                                            // , Collateral__r.Remarks__c  //type change
                                                            From Application_Collateral__c Where HL_Loan_Application__c =: loanId];

                if(!collList.isEmpty()){
                    for(Application_Collateral__c rec : collList){
                        if(rec.Collateral__r == null || rec.Collateral__r.Collateral_Type__c == null){
                            errorMessages.add('Error: Collateral Type missing for collateral - '+ rec.Name);
                        }
                        if(rec.Collateral__r == null || rec.Collateral__r.Market_Value__c == null){
                            errorMessages.add('Error: Valuation missing for collateral - '+ rec.Name);
                        }
                        if(rec.Collateral__r == null || rec.Collateral__r.Current_Usage__c == null){
                            errorMessages.add('Error: Current Usage missing for collateral - '+ rec.Name);
                        }
                        // if(rec.Collateral__r == null || rec.Collateral__r.Remarks__c == null){ //type change
                        //     errorMessages.add('Error: Remarks missing for collateral - '+ rec.Name);
                        // }
                    }

                    //TV
                    List<Technical_Evaluation__c> techList = [Select Id, Name, HL_Application_Collateral__r.Asset_Type__c, HL_Vendor_Agency__r.Name, 
                                                                HL_Application_Collateral__r.Collateral__r.Remarks__c, HL_Application_Collateral__r.Collateral__r.Market_Value__c
                                                                From Technical_Evaluation__c Where HL_Loan_Application__c =: loanId And HL_Is_Final_Valuation__c = true Limit 1];

                    if(!techList.isEmpty()){
                        if(techList[0].HL_Application_Collateral__r == null || techList[0].HL_Application_Collateral__r.Asset_Type__c == null){
                            errorMessages.add('Error: Asset Type missing for Technical verification - '+ techList[0].Name);
                        }
                        if(techList[0].HL_Vendor_Agency__r == null || techList[0].HL_Vendor_Agency__r.Name == null){
                            errorMessages.add('Error: Vendor Agency details missing for Technical verification - '+ techList[0].Name);
                        }
                        if(techList[0].HL_Application_Collateral__r == null || techList[0].HL_Application_Collateral__r.Collateral__r.Remarks__c == null){
                            errorMessages.add('Error: Remarks missing for Technical verification - '+ techList[0].Name);
                        }
                        if(techList[0].HL_Application_Collateral__r == null || techList[0].HL_Application_Collateral__r.Collateral__r == null || techList[0].HL_Application_Collateral__r.Collateral__r.Market_Value__c == null){
                            errorMessages.add('Error: Please select Market valuation on Collateral for Technical verification - '+ techList[0].Name);
                        }
                    }
                    else{
                        errorMessages.add('Error: Technical valuation not found');
                    }
                    //TV

                    // //LV
                    // if(collList[0].Collateral__r != null && collList[0].Collateral__r.APF__c == 'No'){
                    //     List<Legal__c> legalList = [Select Id, Name, Application_Collateral__r.Name, Vendor_Agency__r.Name, Stage__c, Report_Status__c 
                    //                                 From Legal__c Where Loan_Application__c =: loanId Limit 1];
                    //     if(!legalList.isEmpty()){
                    //         if(legalList[0].Application_Collateral__r == null || legalList[0].Application_Collateral__r.Name == null){
                    //             errorMessages.add('Error: Collateral details missing for Legal verification - '+ legalList[0].Name);
                    //         }
                    //         if(legalList[0].Vendor_Agency__r == null || legalList[0].Vendor_Agency__r.Name == null){
                    //             errorMessages.add('Error: Vendor details missing for Legal verification - '+ legalList[0].Name);
                    //         }
                    //         if(legalList[0].Report_Status__c == null){
                    //             errorMessages.add('Error: Report Status missing for Legal verification - '+ legalList[0].Name);
                    //         }
                    //         if(legalList[0].Stage__c == null){
                    //             errorMessages.add('Error: Stage missing for Legal verification - '+ legalList[0].Name);
                    //         }
                    //     }
                    //     else{
                    //         errorMessages.add('Error: Legal valuation not found');
                    //     }
                    // }
                    // //LV
                }
                else{
                    errorMessages.add('Error: Collateral not found');
                }
                //Collateral   
            }
        }
        catch(Exception e){
            errorMessages.add('Error: '+ e.getMessage());
        }

        return errorMessages;
    }

    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        try {
            return createRequestWrapper(wrapper.loanApplicationId, wrapper.productName, wrapper.isIncomeFromSales, wrapper.userCalValues, wrapper.showCalculator);
        }
        catch(Exception e) {
            System.debug('Exception: ' + e.getMessage() +' '+ e.getStackTraceString()); //added to get stackTrace too in the debug
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'Eligibility API', '', '') });
            throw new AuraHandledException('An error occurred: ' + e.getMessage());
        }
    }

    public static String createRequestWrapper(String loanId, string productType, Boolean isIncomeFromSales, string userCalValues, Boolean isFromCalculator) {
        system.debug('userCalValues: '+userCalValues);
        System.debug('productType: '+productType);
        System.debug('isIncomeFromSales: '+isIncomeFromSales);

        Boolean checkTest = Test.isRunningTest();
        Decimal zeroDecimal = Decimal.valueOf(constants.get('Zero_Decimal'));
        Integer zeroInteger = Integer.valueOf(constants.get('Zero'));

        Decimal grossSalary = zeroDecimal;
        Decimal totalDeductions = zeroDecimal;
        Decimal previousYearBonus = zeroDecimal;
        Decimal latestYearBonus = zeroDecimal;
        Decimal month1Net = zeroDecimal;
        Decimal month2Net = zeroDecimal;
        Decimal month3Net = zeroDecimal;
        Decimal month4Net = zeroDecimal;
        Decimal month5Net = zeroDecimal;
        Decimal month6Net = zeroDecimal;
        Decimal rentalIncome = zeroDecimal;
        Integer totalObligation = zeroInteger;
        Integer docmarketVal = zeroInteger;
        Decimal finalLoanAmount = zeroDecimal;
        String roi = '8.8';
        Integer tenor = zeroInteger;
        Decimal additionalFOIR = zeroDecimal;

        if(!isIncomeFromSales){
            Map<string, string> userValuesMap = (Map<String,String>)JSON.deserialize(userCalValues, Map<String, String>.class);
            system.debug('userValuesMap: '+JSON.serialize(userValuesMap));

            if(isFromCalculator){
                grossSalary = userValuesMap.containsKey('grossSalary') ? Decimal.valueOf((String)userValuesMap.get('grossSalary')) : grossSalary;
                totalDeductions = userValuesMap.containsKey('totalDeductions') ? Decimal.valueOf((String)userValuesMap.get('totalDeductions')) : totalDeductions;
                previousYearBonus = userValuesMap.containsKey('previousYearBonus') ? Decimal.valueOf((String)userValuesMap.get('previousYearBonus')) : previousYearBonus;
                latestYearBonus = userValuesMap.containsKey('latestYearBonus') ? Decimal.valueOf((String)userValuesMap.get('latestYearBonus')) : latestYearBonus;
                month1Net = userValuesMap.containsKey('month1Net') ? Decimal.valueOf((String)userValuesMap.get('month1Net')) : month1Net;
                month2Net = userValuesMap.containsKey('month2Net') ? Decimal.valueOf((String)userValuesMap.get('month2Net')) : month2Net;
                month3Net = userValuesMap.containsKey('month3Net') ? Decimal.valueOf((String)userValuesMap.get('month3Net')) : month3Net;
                month4Net = userValuesMap.containsKey('month4Net') ? Decimal.valueOf((String)userValuesMap.get('month4Net')) : month4Net;
                month5Net = userValuesMap.containsKey('month5Net') ? Decimal.valueOf((String)userValuesMap.get('month5Net')) : month5Net;
                month6Net = userValuesMap.containsKey('month6Net') ? Decimal.valueOf((String)userValuesMap.get('month6Net')) : month6Net;
                rentalIncome = userValuesMap.containsKey('rentalIncome') ? Decimal.valueOf((String)userValuesMap.get('rentalIncome')) : rentalIncome;
                totalObligation = userValuesMap.containsKey('TotalObligation') ? Integer.valueOf((String)userValuesMap.get('TotalObligation')) : totalObligation;
                docmarketVal = userValuesMap.containsKey('docmarketVal') ? Integer.valueOf((String)userValuesMap.get('docmarketVal')) : docmarketVal;
            }

            finalLoanAmount = userValuesMap.containsKey('finalLoanAmount') ? Decimal.valueOf((String)userValuesMap.get('finalLoanAmount')) : finalLoanAmount;
            roi = userValuesMap.containsKey('roi') ? String.valueOf(userValuesMap.get('roi')) : roi;
            additionalFOIR = userValuesMap.containsKey('additionalFOIR') ? Decimal.valueOf((String)userValuesMap.get('additionalFOIR')) : additionalFOIR;
            tenor = userValuesMap.containsKey('tenor') ? Integer.valueOf((String)userValuesMap.get('tenor')) : tenor;
        }

        //Query records start
        Opportunity loanObj = [SELECT Id, Name, Nature_of_Business__c, Branch_Master__r.Branch_Code__c, CreatedDate, Lead__r.Channel_Code__c, HL_Construction_Stage__c, 
                                Reference_Phone_1__c, Reference_Phone_2__c, Reference_Name_1__c, Reference_Name_2__c, Reference_Last_Name_1__c, Reference_Last_Name_2__c,
                                Reference_Details_Pincode_1__r.Name, Reference_Details_Pincode_2__r.Name, Reference_Address_1__c, Reference_Address_2__c
                                FROM Opportunity WHERE Id =: loanId];

        Map<String, List<Application_Applicant__c>> applicantMap = new Map<String, List<Application_Applicant__c>>();

        string prodTransactionType;
        string prodLoanPurpose;
        Product2 prodObj;
        Product2 fullEmiProd;
        Product2 subProduct = [SELECT Id, Requested_Loan_Amount__c, EMI_Amount__c, Product__r.Product_Type__c FROM Product2 WHERE Loan_Application__c =: loanId AND RecordType.Name = 'Sub Product' 
                                AND Product__r.RecordType.Name = 'Product' And Product__r.Name =: productType LIMIT 1];

        for(Product2 rec : [SELECT Id, Name, RecordType.Name, Variant__r.Name, Variant__r.PLR_Value__c, Sub_Variant__c, Sub_Variant__r.Name 
                            FROM product2 WHERE Loan_Application__c =: loanId And Product__c =: subProduct.Id
                            And RecordType.Name IN ('Total Tenure','Full EMI','Transaction Type','Loan Purpose')]){

            switch on rec.RecordType.Name {
                when 'Total Tenure' {
                    prodObj = rec;
                }
                when 'Full EMI' {
                    fullEmiProd = rec;
                }
                when 'Transaction Type' {
                    prodTransactionType = rec.Name;
                }
                when 'Loan Purpose' {
                    prodLoanPurpose = rec.Name;
                }
            }
        }

        List<Product2> hybridTenureRecords = [SELECT Id, Name FROM Product2 WHERE Product__c =: prodObj.Sub_Variant__c And RecordType.Name = 'Hybrid Tenure'];

        Date currentDate = Date.today();
        Integer tenureInt = Integer.valueOf(prodObj.Name);
        String maturityDate = currentDate.day() > 15 ? String.valueOf(currentDate.addMonths(tenureInt + 1)) : String.valueOf(currentDate.addMonths(tenureInt));
        String businessVertical = '';
        String graceperiodroi = hybridTenureRecords[0].Name;
        
        if(prodObj.Variant__c != null && prodObj.Variant__r.Name == 'Flexi Funds') {
            if(prodObj.Sub_Variant__r.Name == 'Hybrid'){
                businessVertical = prodObj.Sub_Variant__r.Name;
            }
            else if(prodObj.Sub_Variant__r.Name == 'Dropline'){
                businessVertical = 'Drop';
            }
        }

        //obligations
        Decimal emis = 0;
        decimal parentLoanAmount = 0;
        for(Income_Expense_Obligation__c iterObli : [SELECT Id, Imputed_EMI__c 
                                                        FROM Income_Expense_Obligation__c WHERE Type__c = 'Obligation' And Imputed_EMI__c != null
                                                        AND Loan_Application__c =: loanId And Is_Considered_Obligation__c = true 
                                                        AND RecordType.Name = 'Income Expense & Obligation']) {

            emis = emis + iterObli.Imputed_EMI__c;
        }

        if(subProduct.Product__r.Product_Type__c == 'Child' && !checkTest){
            Product2 subProductParent = [SELECT Id, EMI_Amount__c, Sanctioned_Loan_Amount__c FROM Product2 WHERE Loan_Application__c =: loanId AND RecordType.Name = 'Sub Product' 
                                        AND Product__r.RecordType.Name = 'Product' AND Product__r.Product_Type__c = 'Parent' And EMI_Amount__c != null LIMIT 1];
            
            emis = emis + subProductParent.EMI_Amount__c;
            parentLoanAmount = subProductParent.Sanctioned_Loan_Amount__c;
        }

		Decimal shareholdingKey = 0;
        String primaryAppId = '';
        Decimal cibilScore = 0;
        string primaryAppCustomerCIF = '';
        string primaryAppName = '';

        //Income Programe
        List<string> selectedIncomeProgram = new List<string>();
        Set<Id> incomeAppIds = new Set<Id>();
        Set<Id> parentIdSet = new Set<Id>();
        Set<Id> parentRecIdSet = new Set<Id>();
        Map<string, Map<string, Income_Assessment__c>> appIncomeAssMap = new Map<string, Map<string, Income_Assessment__c>>();
        Map<string, Map<string, List<Income_Assessment__c>>> parentIncomeAssMap = new Map<string, Map<string, List<Income_Assessment__c>>>();

        for(Income_Assessment__c rec : [Select Id, Applicant__c, Type_of_Income_Assesment__c, RecordType.Name, Gross_Monthly_Salary__c, Is_Turnover_Growth_Sustainable__c, 
                                        Is_Cash_Profit_Sustainable__c, Is_Gross_Profit_Sustainable__c, Is_Growth_Sustainable__c, Override_ABB_EMI_Ratio__c, 
                                        Additional_Gross_Margin__c, Additional_Multiplier__c, HL_Additional_FOIR__c
                                        From Income_Assessment__c Where Loan_Application__c =: loanId And Parent__c = null
                                        And RecordType.Name IN ('Salaried Individual','Cash Profit','Salaried NRI','Director Renumeration','Sep Multiplier','Gross Margin','Merchant Navy','Banking','Low LTV Program')
                                        Order By Applicant__c]){
            
            string key = (rec.RecordType.Name == 'Salaried NRI' || rec.RecordType.Name == 'Merchant Navy') ? rec.Type_of_Income_Assesment__c : rec.Id;

            if(appIncomeAssMap.containsKey(rec.Applicant__c)) {
                appIncomeAssMap.get(rec.Applicant__c).put(key, rec);
            }else {
                appIncomeAssMap.put(rec.Applicant__c, new Map<string, Income_Assessment__c>{ key => rec });
            }
            
            parentRecIdSet.add(rec.Id);
            incomeAppIds.add(rec.Applicant__c);
            selectedIncomeProgram.add(rec.RecordType.Name);
        }
        system.debug('appIncomeAssMap: '+JSON.serialize(appIncomeAssMap));
        system.debug('selectedIncomeProgram: '+JSON.serialize(selectedIncomeProgram));

        for(Income_Assessment__c rec : [Select Id, Parent__c, Yearly_Amount__c, Growth__c, RecordType.Name, Cash_Profit_Particular__c, Yearly_Component__c, 
                                        HL_Gross_Margin_Particular__c, Amount_in_Foreign__c, Exchange_Rate__c, Particulars__c, SepMultiplierParticulars__c, Multiplier__c, 
                                        HL_Abb_EMI_Ratio__c, Average_Bank_Balance__c, Parent__r.Type_of_Income_Assesment__c, Net_Amount__c, Override_ABB_EMI_Ratio__c,Additional_Multiplier__c,HL_Additional_FOIR__c
                                        From Income_Assessment__c Where Parent__c IN : parentRecIdSet 
                                        And RecordType.Name IN ('Salaried Incentive Component','Salaried Yearly Component','Cash Profit','Salaried NRI','Director Renumeration','Sep Multiplier','Gross Margin','Child Rental Income','Merchant Navy','Banking','Low LTV Program')
                                        Order By Parent__c, RecordType.Name, Yearly_Component__c]){

            if(parentIncomeAssMap.containsKey(rec.Parent__c)) {
                if(parentIncomeAssMap.get(rec.Parent__c).containsKey(rec.RecordType.Name)) {
                    parentIncomeAssMap.get(rec.Parent__c).get(rec.RecordType.Name).add(rec);
                }else {
                    parentIncomeAssMap.get(rec.Parent__c).put( rec.RecordType.Name, new List<Income_Assessment__c>{rec} );
                }
            }else {
                parentIncomeAssMap.put(rec.Parent__c, new Map<string, List<Income_Assessment__c>>{ rec.RecordType.Name => new List<Income_Assessment__c>{rec} });
            }

            parentIdSet.add(rec.Id);
        }
        system.debug('parentIncomeAssMap: '+JSON.serialize(parentIncomeAssMap));
        system.debug('parentIdSet: '+parentIdSet);
        
        Map<string, Map<string, List<Income_Assessment__c>>> appIncomeChildMap = new Map<string, Map<string, List<Income_Assessment__c>>>();
        for(Income_Assessment__c rec : [SELECT Id, Year_Name__c, Yearly_Amount__c, Average_Amount__c, Growth__c, HL_Gross_Margin_Particular__c, Applicant__c, 
                                        RecordType.Name, Average_Bank_Balance__c, HL_Abb_EMI_Ratio__c, Particulars__c, Exchange_Rate__c, Amount_in_Foreign__c, 
                                        Cash_Profit_Particular__c, SepMultiplierParticulars__c, Parent__r.SepMultiplierParticulars__c
                                        FROM Income_Assessment__c where Parent__c IN : parentIdSet Order By Applicant__c, Cash_Profit_Particular__c, 
                                        HL_Gross_Margin_Particular__c, Year_Name__c Desc]){
            
            string key = '';
            switch on rec.RecordType.Name {
                when 'Cash Profit' {
                    key = rec.Cash_Profit_Particular__c;
                }
                when 'Salaried NRI', 'Merchant Navy' {
                    key = rec.Particulars__c;
                }
                when 'Gross Margin' {
                    key = rec.HL_Gross_Margin_Particular__c;
                }
                when 'Sep Multiplier' {
                    key = rec.Parent__r.SepMultiplierParticulars__c;
                }
            }
            
            if(appIncomeChildMap.containsKey(rec.Applicant__c)) {
                if(appIncomeChildMap.get(rec.Applicant__c).containsKey(key)) {
                    appIncomeChildMap.get(rec.Applicant__c).get(key).add(rec);
                }else {
                    appIncomeChildMap.get(rec.Applicant__c).put( key, new List<Income_Assessment__c>{rec} );
                }
            }else {
                appIncomeChildMap.put(rec.Applicant__c, new Map<string, List<Income_Assessment__c>>{ key => new List<Income_Assessment__c>{rec} });
            }
        }
        system.debug('appIncomeChildMap: '+JSON.serialize(appIncomeChildMap));

        Map<string, List<decimal>> appIncomeDeductionMap = new Map<string, List<decimal>>();

        if(selectedIncomeProgram.contains('Salaried Individual')){
            for(AggregateResult ar : [Select SUM(Average_Amount__c), Applicant__c, Add_Less__c From Income_Assessment__c Where Loan_Application__c =: loanId 
                                        And Parent__c != null And RecordType.Name = 'Salaried Individual' And Average_Amount__c >0 Group By Applicant__c, 
                                        Add_Less__c Order By Applicant__c, Add_Less__c]){

                string app = ar.get('Applicant__c').toString();
                decimal amount = Decimal.valueOf(ar.get('expr0').toString());
                decimal annualValue = amount * 12;

                if(appIncomeDeductionMap.containsKey(app)) {
                    appIncomeDeductionMap.get(app).add(annualValue);
                }else {
                    appIncomeDeductionMap.put(app, new List<decimal>{annualValue});
                }
            }
        }
        
        if(selectedIncomeProgram.contains('Merchant Navy') || selectedIncomeProgram.contains('Salaried NRI')){
            decimal totalAmount = 0;
            Map<string, decimal> applIncomeMap = new Map<string, decimal>();

            for(Income_Assessment__c rec : [Select Amount_in_Foreign__c, Exchange_Rate__c, Applicant__c From Income_Assessment__c 
                                            Where Parent__r.Applicant__c IN : incomeAppIds And Parent__r.Particulars__c = 'Income Total' 
                                            And RecordType.Name IN ('Salaried NRI','Merchant Navy') And Amount_in_Foreign__c >0 Order By Applicant__c]){

                if(applIncomeMap.containsKey(rec.Applicant__c)) {
                    totalAmount += (rec.Amount_in_Foreign__c * rec.Exchange_Rate__c);
                }else {
                    totalAmount = (rec.Amount_in_Foreign__c * rec.Exchange_Rate__c);
                }

                applIncomeMap.put(rec.Applicant__c, totalAmount);
            }

            for(string key : applIncomeMap.keySet()){
                if(appIncomeDeductionMap.containsKey(key)) {
                    appIncomeDeductionMap.get(key).add(applIncomeMap.get(key) * 12);
                }else {
                    appIncomeDeductionMap.put(key, new List<decimal>{applIncomeMap.get(key) * 12});
                }
            }
        }
        system.debug('appIncomeDeductionMap: '+JSON.serialize(appIncomeDeductionMap));

        List<Application_Applicant__c> lstApplicants = [SELECT Id, Applicant_Type__c, name, Customer__r.SF_Customer_ID__c, Customer_Type__c, Employment_Type__c,
                                                        Marital_Status__c, Sector__c, PEP__c, Customer_Profile__c, Share_Holding_Percentage__c, CIBIL_Score__c,
                                                        Sub_Employment_Type__c, PAN_Number__c, DOB__c, DOI__c, Loan_Application__r.Name, Sub_Segment__c,
                                                        Nature_of_Business__c, Address_Ownership__c, Specialization__c, Qualification__c, Industry__c, Email__c,
                                                        Is_Key_Applicant__c, Total_Work_Experience_Years__c, Office_Ownership__c, Sub_Employment_Type_Non_Individual__c,
                                                        Residency_Status__c, Cast_Category__c, Passport_Date_of_Issue__c, Passport_Date_of_Expiry__c, Mobile_Number__c,
                                                        Customer__r.Name, Voter_ID_Number__c, Aadhaar_Number__c, Passport_Number__c, Drivers_License_Number__c, 
                                                        AmountConsideredForEligibilityPurpos__c, Borrower_Profile__c
                                                        FROM Application_Applicant__c
                                                        WHERE Id In : incomeAppIds AND (Applicant_Type__c = 'Primary Applicant' OR Applicant_Type__c = 'Co Applicant')];

        for(Application_Applicant__c iterApplicants : lstApplicants) {
            if(iterApplicants.Share_Holding_Percentage__c != null) {
                shareholdingKey = shareholdingKey + iterApplicants.Share_Holding_Percentage__c;
            }

            if(iterApplicants.Is_Key_Applicant__c) {
                cibilScore = iterApplicants.CIBIL_Score__c;
            }

            if(iterApplicants.Applicant_Type__c == constants.get('Primary_Applicant')) {
                primaryAppId = iterApplicants.id;
                primaryAppCustomerCIF = iterApplicants.Customer__r?.SF_Customer_ID__c.split('-')[1];
                primaryAppName = iterApplicants.Customer__r.Name;
            }

            if(applicantMap.containsKey(iterApplicants.Applicant_Type__c)) {
                applicantMap.get(iterApplicants.Applicant_Type__c).add(iterApplicants);
            }else {
                applicantMap.put(iterApplicants.Applicant_Type__c, new List<Application_Applicant__c>{iterApplicants});
            }
        }

        Income_Expense_Obligation__c primaryFSACY = new Income_Expense_Obligation__c();
        Income_Expense_Obligation__c primaryFSAPY = new Income_Expense_Obligation__c();
        List<Income_Expense_Obligation__c> cprimaryFSARec = [SELECT id, year__c
                                                            FROM Income_Expense_Obligation__c WHERE recordType.Name = 'FSA' AND IsParent__c = false
                                                            AND Loan_Application__c =: loanId AND Application_Applicant__c =: primaryAppId];

        if(cprimaryFSARec.size() == 2) {
            Integer yearRec1 = Integer.valueOf(cprimaryFSARec[0].year__c);
            Integer yearRec2 = Integer.valueOf(cprimaryFSARec[1].year__c);
            if(yearRec1 > yearRec2) {
                primaryFSACY = cprimaryFSARec[0];
                primaryFSAPY = cprimaryFSARec[1];
            }
            else {
                primaryFSACY = cprimaryFSARec[1];
                primaryFSAPY = cprimaryFSARec[0];
            }
        }
        //FSA primary applicant

        //address
        Map<String, List<Applicant_Address__c>> applicatAddressMap = new Map<String, List<Applicant_Address__c>>();

        for(Applicant_Address__c iterAdd : [SELECT Id, Pincode__r.Name, Pincode__r.Is_Pincode_Servicable__c, Applicant__c, Address_Ownership__c,
                                            Address_Type__c, Pincode__r.City__r.Name, Address_Priority__c, Landmark__c
                                            FROM Applicant_Address__c WHERE Applicant__c IN : lstApplicants And Document_Details__c != null 
                                            And Address_Priority__c In ('5','4') Order By Applicant__c, Address_Priority__c Desc]) {

            if(applicatAddressMap.containsKey(iterAdd.Applicant__c)) {
                applicatAddressMap.get(iterAdd.Applicant__c).add(iterAdd);
            }else {
                applicatAddressMap.put(iterAdd.Applicant__c, new List<Applicant_Address__c>{iterAdd});
            }
        }
        //address end

        //Bank data
        // Decimal allOdccLimit = 0;
        Set<String> accountTypeSet = new Set<String>();
        Map<String,List<Bank_Details__c>> applicantBanksMap = new Map<String,List<Bank_Details__c>>();
        List<Bank_Details__c> applicantBanks = [SELECT id, Account_Type__c, Account_Number__c, OD_CC_Limit__c, Application_Applicant__c, Account_type_FICO__c,
                                                Account_Holder_Name__c
                                                FROM Bank_Details__c WHERE Application_Applicant__c IN : lstApplicants AND Is_Consider_for_Eligibility__c = true];

        for(Bank_Details__c iterBanks : applicantBanks) {
            accountTypeSet.add(iterBanks.Account_Type__c);

            if(applicantBanksMap.containsKey(iterBanks.Application_Applicant__c)) {
                applicantBanksMap.get(iterBanks.Application_Applicant__c).add(iterBanks);
            }else {
                applicantBanksMap.put(iterBanks.Application_Applicant__c, new List<Bank_Details__c>{iterBanks});
            }
        }

        String accTypeForbanking = '';
        if(!accountTypeSet.isEmpty()) {
            if((accountTypeSet.contains('Overdraft') || accountTypeSet.contains('CashCredit')) && (accountTypeSet.contains('Current') || accountTypeSet.contains('Saving'))) {
                accTypeForbanking = 'NONOD_OD';
            }else if(accountTypeSet.contains('Current') || accountTypeSet.contains('Saving')) {
                accTypeForbanking = 'NONOD';
            }else if(accountTypeSet.contains('Overdraft') || accountTypeSet.contains('CashCredit')) {
                accTypeForbanking = 'OD';
            }
        }
        //Bank data end

        //BSA data start
        Bank_Statement_Analysis__c consolidatedBsarec = BsaSelectBankController.getEligibleRecord(loanId);
        Decimal minimumCreditCount = 0;
        Decimal minimunCreditAmount = 0;
        Decimal totalAmtOfbusinessCredit = 0;
        Decimal gblmetCredit = 0;
        Map<String,List<Bank_Statement_Analysis__c>> bsaBankMap = new Map<String,List<Bank_Statement_Analysis__c>>();
        Map<String,Decimal> monthWiseBusinesCredit = new Map<String,Decimal>();
        Map<String,Decimal> monthWiseAbb = new Map<String,Decimal>();
        Map<String,Decimal> monthWiseBusinesCreditAmount = new Map<String,Decimal>();
        Map<String,Map<String,Decimal>> abbLogicMap = new Map<String,Map<String,Decimal>>();
        Map<String,List<Bank_Statement_Analysis__c>> applicantWiseBsaMap = new Map<String,List<Bank_Statement_Analysis__c>>();
        List<Bank_Statement_Analysis__c> bsaLSt = [SELECT Id, Bank_Details__c, Sanction_Limit__c, Bank_Details__r.Application_Applicant__c, ABB__c, 
                                                    Bank_Details__r.Account_Type__c, Average_EOD_Balance__c, Total_Number_of_Business_Credits__c, Month__c, 
                                                    Total_number_of_inward_Cheque_return__c, Average_Limit_Utilisation__c, Bank_Details__r.Account_type_FICO__c, 
                                                    Total_Number_of_Business_Debits__c, Total_number_of_out_bounce__c, Total_Amount_of_Business_Credits__c
                                                    FROM Bank_Statement_Analysis__c WHERE Bank_Details__c IN : applicantBanks AND recordType.Name = 'Derived Analysis'
                                                    AND Bank_Details__r.Is_Consider_for_Eligibility__c = true AND Parent_Bant_Statement__c != null];

        for(Bank_Statement_Analysis__c iterBsa : bsaLSt) {
            if(minimunCreditAmount == 0) {
                minimunCreditAmount = iterBsa.Total_Amount_of_Business_Credits__c;
            }else {
                if(minimunCreditAmount > iterBsa.Total_Amount_of_Business_Credits__c) {
                    minimunCreditAmount = iterBsa.Total_Amount_of_Business_Credits__c;
                }
            }

            if(minimumCreditCount == 0) {
                minimumCreditCount = iterBsa.Total_Number_of_Business_Credits__c;
            }else {
                if(minimumCreditCount > iterBsa.Total_Number_of_Business_Credits__c) {
                    minimumCreditCount = iterBsa.Total_Number_of_Business_Credits__c;
                }
            }
            
            if(iterBsa.Total_Amount_of_Business_Credits__c != null) {
                gblmetCredit = gblmetCredit + iterBsa.Total_Amount_of_Business_Credits__c;
            }
            
            decimal abb = iterBsa.ABB__c != null ? iterBsa.ABB__c : 0;
            if(monthWiseAbb.containsKey(iterBsa.Month__c)) {
                Decimal tempVal = monthWiseAbb.get(iterBsa.Month__c);
                monthWiseAbb.put(iterBsa.Month__c, abb + tempVal);
            }else {
                monthWiseAbb.put(iterBsa.Month__c, abb);
            }

            if(monthWiseBusinesCredit.containsKey(iterBsa.Month__c)) {
                Decimal tempVal = monthWiseBusinesCredit.get(iterBsa.Month__c);
                monthWiseBusinesCredit.put(iterBsa.Month__c, iterBsa.Total_Number_of_Business_Credits__c + tempVal);
            }else {
                monthWiseBusinesCredit.put(iterBsa.Month__c, iterBsa.Total_Number_of_Business_Credits__c);
            }

            if(monthWiseBusinesCreditAmount.containsKey(iterBsa.Month__c)) {
                Decimal tempVal = monthWiseBusinesCreditAmount.get(iterBsa.Month__c);
                monthWiseBusinesCreditAmount.put(iterBsa.Month__c, iterBsa.Total_Amount_of_Business_Credits__c + tempVal);
            }else {
                monthWiseBusinesCreditAmount.put(iterBsa.Month__c, iterBsa.Total_Amount_of_Business_Credits__c);
            }

            if(bsaBankMap.containsKey(iterBsa.Bank_Details__c)) {
                bsaBankMap.get(iterBsa.Bank_Details__c).add(iterBsa);
            }else {
                bsaBankMap.put(iterBsa.Bank_Details__c, new List<Bank_Statement_Analysis__c>{iterBsa});
            }

            if(applicantWiseBsaMap.containsKey(iterBsa.Bank_Details__r.Application_Applicant__c)) {
                applicantWiseBsaMap.get(iterBsa.Bank_Details__r.Application_Applicant__c).add(iterBsa);
            }else {
                applicantWiseBsaMap.put(iterBsa.Bank_Details__r.Application_Applicant__c, new List<Bank_Statement_Analysis__c>{iterBsa});
            }
        }

        //calculate average abb
        Decimal minimumCreditTxn = 0;
        if(!monthWiseBusinesCredit.isEmpty()) {
            List<String> sortedMonthsLst = new List<String>(monthWiseBusinesCredit.keySet());
            List<String> reverseMonthsLst = new List<String>();
            for(Integer i = sortedMonthsLst.size() - 1; i >= 0; i--){
                reverseMonthsLst.add(sortedMonthsLst[i]);
            }

            Integer count = 0;
            for (String month : reverseMonthsLst) {
                if (count < 6) {
                    if(minimumCreditTxn == 0) {
                        minimumCreditTxn = monthWiseBusinesCredit.get(month);
                    }else {
                        if(minimumCreditTxn > monthWiseBusinesCredit.get(month)){
                            minimumCreditTxn = monthWiseBusinesCredit.get(month);
                        }
                    }
                }else {
                    break;
                }
                count = count + 1;
            }
        }

        Decimal minimumCreditAmount = 0;
        totalAmtOfbusinessCredit = 0;
        if(!monthWiseBusinesCreditAmount.isEmpty()) {
            List<String> sortedMonthsLst = new List<String>(monthWiseBusinesCreditAmount.keySet());
            List<String> reverseMonthsLst = new List<String>();
            for(Integer i = sortedMonthsLst.size() - 1; i >= 0; i--){
                reverseMonthsLst.add(sortedMonthsLst[i]);
            }

            Integer count = 0;
            for(String month : reverseMonthsLst) {
                if(count < 6) {
                    totalAmtOfbusinessCredit = totalAmtOfbusinessCredit + monthWiseBusinesCreditAmount.get(month);
                    if(minimumCreditAmount == 0) {
                        minimumCreditAmount = monthWiseBusinesCreditAmount.get(month);
                    }else {
                        if(minimumCreditAmount > monthWiseBusinesCreditAmount.get(month)){
                            minimumCreditAmount = monthWiseBusinesCreditAmount.get(month);
                        }
                    }
                }else {
                    break;
                }
                count = count + 1;
            }
        }

        Decimal monthWiseLimitMax = 0;
        for(String bankIterId : bsaBankMap.keySet()) {
            Decimal tempVal = 0;
            Integer count = 0;
            for(Bank_Statement_Analysis__c iterBSADA : bsaBankMap.get(bankIterId)) {
                tempVal = tempVal + iterBSADA.Average_Limit_Utilisation__c;
                count = count + 1;
            }

            if(monthWiseLimitMax == 0 && count != 0) {
                monthWiseLimitMax = tempVal / count;
            }else {
                if(count != 0) {
                    Decimal val = tempVal / count;
                    if(monthWiseLimitMax < val) {
                        monthWiseLimitMax = val;
                    }
                }
            }
        }

        for(String applicantId : applicantWiseBsaMap.keySet()) {
            Map<String,Decimal> tempMap = new Map<String,Decimal>();
            for(Bank_Statement_Analysis__c iterBSAForAbb : applicantWiseBsaMap.get(applicantId)) {
                if(tempMap.containsKey(iterBSAForAbb.Month__c)) {
                    //System.debug(tempMap.get(iterBSAForAbb.Month__c) +'----'+iterBSAForAbb.ABB__c);
                    Decimal tempABB = tempMap.get(iterBSAForAbb.Month__c);

                    Decimal iterAbbtemp = iterBSAForAbb.Average_EOD_Balance__c != null ? iterBSAForAbb.Average_EOD_Balance__c : 0;
                    tempABB = tempABB + iterAbbtemp;
                    tempMap.put(iterBSAForAbb.Month__c, tempABB);
                }else {
                    tempMap.put(iterBSAForAbb.Month__c, iterBSAForAbb.Average_EOD_Balance__c != null ? iterBSAForAbb.Average_EOD_Balance__c : 0);
                }
            }
            //System.debug('tempMap------ 521'+ tempMap);
            abbLogicMap.put(applicantId, tempMap);
        }

        Decimal minimumAbb = 0;
        Decimal minimumAbbSales = 0;
        Decimal last6MonADB = 0;
        Map<String, Map<String, Decimal>> latestSixMonthsMap = new Map<String, Map<String, Decimal>>();
        Map<String,Decimal> addedAdd = new Map<String,Decimal>();
        
        for(String applicantId : abbLogicMap.keySet()) {
            addedAdd.put(applicantId,0);
            Map<String, Decimal> monthValues = abbLogicMap.get(applicantId);
            List<String> sortedMonths = new List<String>(monthValues.keySet());
            List<String> reverseMonths = new List<String>();
            for(Integer i = sortedMonths.size() - 1; i >= 0; i--){
                reverseMonths.add(sortedMonths[i]);
            }

            // Get the latest 6 months
            Map<String, Decimal> latestSixMonths = new Map<String, Decimal>();
            Integer count = 0;
            for (String month : reverseMonths) {
                if (count < 6) {
                    decimal value = monthValues.get(month) != null ? monthValues.get(month) : 0;
                    last6MonADB = last6MonADB + value;
                    latestSixMonths.put(month, value);
                    Decimal tempVal = addedAdd.get(applicantId);
                    tempVal = tempVal + value;
                    addedAdd.put(applicantId, tempVal);
                    count = count + 1;
                } else {
                    break;
                }
            }

            latestSixMonthsMap.put(applicantId, latestSixMonths);
        }

        if(!monthWiseAbb.isEmpty()) {
            List<String> sortedMonthsLst = new List<String>(monthWiseAbb.keySet());
            List<String> reverseMonthsLst = new List<String>();
            for(Integer i = sortedMonthsLst.size() - 1; i >= 0; i--){
                reverseMonthsLst.add(sortedMonthsLst[i]);
            }

            Integer count = 0;
            for(String month : reverseMonthsLst) {
                if (count < 6) {
                    decimal value = monthWiseAbb.get(month) != null ? monthWiseAbb.get(month) : 0;
                    minimumAbbSales = minimumAbbSales + value;
                    if(minimumAbb == 0) {
                        minimumAbb = value;
                    }else {
                        if(minimumAbb > value){
                            minimumAbb = value;
                        }
                    }
                }else {
                    break;
                }
                count = count + 1;
            }
        }

        last6MonADB = last6MonADB / 6 ;
        minimumAbbSales = minimumAbbSales / 6;

        Map<String,Integer> applicantAddCount = new Map<String,Integer>();
        for(String applicantId : addedAdd.keySet()) {
            Decimal val = addedAdd.get(applicantId);
            Integer count = 0;

            val = val / 18;
            Map<String,Decimal> monthValues = latestSixMonthsMap.get(applicantId);
            for(String monthNam : monthValues.keySet()) {
                if(val > monthValues.get(monthNam)){
                    count = count + 1;
                }
            }
            applicantAddCount.put(applicantId, count);
        }
        //BSA data end

        Map<String, String> conDocIds = new Map<String, String>();
        Map<String, String> perfiosTransactionidMap = new Map<String, String>();
        Map<String, List<Document_Details__c>> kycDocumentMap = new Map<String, List<Document_Details__c>>();

        for(Document_Details__c docIter : [SELECT Id, Name, Content_Document_Id__c, Applicant__c, Document_Master__r.Document_Type__c, Document_Master__r.Document_Category__c, Consider_for_Loan_Application__c
                                            From Document_Details__c Where Applicant__c IN : lstApplicants And ((Document_Master__r.Document_Category__c = 'POA') Or Name IN ('Cibil Response','Bank_Statement_Document'))
                                            Order by CREATEDDATE DESC]) {

            if(docIter.Document_Master__r.Document_Category__c == 'POA' && docIter.Consider_for_Loan_Application__c == true){
                if(kycDocumentMap.containsKey(docIter.Applicant__c)) {
                    kycDocumentMap.get(docIter.Applicant__c).add(docIter);
                }else {
                    kycDocumentMap.put(docIter.Applicant__c, new List<Document_Details__c>{docIter});
                }
            }
            else {
                if(docIter.Name == 'Cibil Response'){
                    conDocIds.put(docIter.Content_Document_Id__c, docIter.Applicant__c);
                }
                else if(docIter.Name == constants.get('Bank_Statement_Document')){
                    perfiosTransactionidMap.put(docIter.Applicant__c, docIter.Transaction_ID__c);
                }
            }
        }

        //tuffresponse
        Map<String,String> applicantTuffRes = new Map<String,String>();
        for(ContentVersion iterConVersion : [SELECT Id, VersionData, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN : conDocIds.keySet()]) {
            String xmlResponse = iterConVersion.VersionData.toString();
            Integer startIndex = xmlResponse.indexOf('<CreditReport>');
            Integer endIndex = xmlResponse.indexOf('</CreditReport>');
            endIndex = endIndex + ('</CreditReport>'.length());
            xmlResponse = xmlResponse.substring(startIndex, endIndex);
            //System.debug('xmlResponse '+xmlResponse);
            applicantTuffRes.put(conDocIds.get(iterConVersion.ContentDocumentId), xmlResponse);
        }
        //tuffresponse

        //Collateral List
        List<Application_Collateral__c> collList = [Select Id, Collateral__r.Builder__r.Name, Collateral__r.Collateral_Type__c,
                                                    Collateral__r.Unit_Property_Type__c, Collateral__r.Market_Value__c, /*Collateral__r.Project_Name__c,*/
                                                    Collateral__r.Current_Usage__c, Collateral__r.Agreement_Value__c 
                                                    From Application_Collateral__c Where HL_Loan_Application__c =: loanId];

        Map<string, List<PLF_Master__c>> masterCodeMap = new Map<string, List<PLF_Master__c>>();
        List<string> masterTypes = ('Customer Category,Qualification,Segment,Sub segment,Sector,Sub sector,Sub product,Specialization,Address Type,Account Type,Loan Purpose,Customer Profile,Construction Stage').split(',');

        List<PLF_Master__c> masterLst = [SELECT Master_Type__c, FICO_Code__c, Description__c, Customer_Type__c, Sector_Code__c, Transaction_Type__c
                                        FROM PLF_Master__c Where Master_Type__c In : masterTypes Order By Master_Type__c Desc];

        //System.debug('masterLst '+masterLst);

        string purposeOfLoanFICO ='';
        string constructionStageFICO = '';

        for(PLF_Master__c rec : masterLst){
            if(masterCodeMap.containsKey(rec.Master_Type__c)) {
                masterCodeMap.get(rec.Master_Type__c).add(rec);
            }else {
                masterCodeMap.put(rec.Master_Type__c, new List<PLF_Master__c>{rec});
            }
            
            if(prodLoanPurpose == rec.description__c && prodTransactionType == rec.Transaction_Type__c){
                purposeOfLoanFICO = rec.FICO_Code__c;
            }
            else if(rec.description__c == loanObj.HL_Construction_Stage__c){
                constructionStageFICO = rec.FICO_Code__c;
            }
        }

        //application verification
        List<Application_Verification__c> appVerList = [Select Id, Applicant__r.Applicant_Type__c, Applicant__r.Customer__r.SF_Customer_ID__c, Applicant__r.Name,
                                                        Address_Type__c, Verification_Remarks__c, RecordType.Name, Vendor__r.Name, Banking_Details__c, Stage__c, 
                                                        IsParent__c, Parent_FCU__r.Verification_Remarks__c, Type_of_Address__c
                                                        From Application_Verification__c Where Applicant__c IN : lstApplicants 
                                                        And RecordType.Name IN ('Business Verification','Residence Verification','Collateral Verification','FCU','Personal Discussion AHL')];

        //Technical valuation
        List<Technical_Evaluation__c> techList = [Select Id, HL_Application_Collateral__r.Asset_Type__c, HL_Vendor_Agency__r.Name, HL_Application_Collateral__r.Collateral__r.Remarks__c, 
                                                    HL_Application_Collateral__r.Collateral__r.Market_Value__c
                                                    From Technical_Evaluation__c Where HL_Loan_Application__c =: loanId And HL_Is_Final_Valuation__c = true Limit 1];

        //Legal valuation
        List<Legal__c> legalList = [Select Id, Application_Collateral__r.Name, Vendor_Agency__r.Name, Stage__c, CreatedDate, Report_Status__c 
                                    From Legal__c Where Loan_Application__c =: loanId Limit 1];

        string formattedLoanDate = loanObj.CreatedDate.format('yyyy-MM-dd') +'+00:00';
        string formattedCurrentDate = Date.today().toString().replace(' 00:00:00', '+00:00');

        //Query records ends

        //wrapper creation start
        HL_EligibilityApiHandler outerWrap = new HL_EligibilityApiHandler();
        cls_message mainWrap = new cls_message();
        cls_request requestWrap = new cls_request();

        cls_application applicationWrap = new cls_application();
        applicationWrap.source = constants.get('GHF');     //mandatory
        applicationWrap.entity = constants.get('PLF');     //mandatory
        applicationWrap.pdDoneBy = UserInfo.getName();      //mandatory

        integer bankAccCounter = 0;
        List<cls_applicants> applicantsData = new List<cls_applicants>();

        for(string key : applicantMap.keySet()){

            for(Application_Applicant__c app : applicantMap.get(key)){
                string appCustomerCIF = app.Customer__r?.SF_Customer_ID__c.split('-')[1];

                cls_applicants appWrapper = new cls_applicants();
                if(app.Customer_Type__c == constants.get('CUSTOMER_TYPE_INDIVIDUAL')){
                    appWrapper.creditBureauReports = replacedOutputStr(applicantTuffRes.get(app.id));      //mandatory
                    appWrapper.dateOfBirth = String.valueOf(app.DOB__c);        //mandatory
                    appWrapper.dateOfIncorporation = '';        //mandatory
                    appWrapper.maritalStatus = replacedOutputStr(app.Marital_Status__c);       //mandatory
                    appWrapper.caste = replacedOutputStr(app.Cast_Category__c);       //mandatory
                }
                else{
                    appWrapper.creditBureauReports = '';        //mandatory
                    appWrapper.dateOfBirth = '';        //mandatory
                    appWrapper.dateOfIncorporation = String.valueOf(app.DOI__c);        //mandatory
                    appWrapper.maritalStatus = '';      //mandatory
                    appWrapper.caste = '';       //mandatory
                }

                appWrapper.customerCif = replacedOutputStr(appCustomerCIF);        //mandatory
                appWrapper.applicantType = app.Applicant_Type__c == 'Primary Applicant' ? 'MainApp' : 'CoApp';      //mandatory
                appWrapper.customerCategory = '';   //mandatory     FICO Code
                appWrapper.addressOwnershipType = app.Address_Ownership__c;
                appWrapper.qualification = '';      //mandatory     FICO Code
                appWrapper.segment = '';            //mandatory     FICO Code
                appWrapper.subSegment = '';        //mandatory      FICO Code
                appWrapper.sector = '';         //mandatory         FICO Code
                appWrapper.subSector = '';      //mandatory         FICO Code
                appWrapper.employmentType = '';     //mandatory     FICO Code

                cls_applicantAdditionalDetails appAddDetails = new cls_applicantAdditionalDetails();
                appAddDetails.natureOfEmployment = '';
                appAddDetails.buffer1 = '';
                appAddDetails.buffer2 = '';

                for(PLF_Master__c iter : masterLst) {

                    switch on iter.Master_Type__c {
                        when 'Customer Category' {
                            if(iter.Description__c == app.Customer_Type__c){
                                appWrapper.customerCategory = replacedOutputStr(iter.FICO_Code__c);        //mandatory
                            }
                        }
                        when 'Qualification' {
                            if(iter.Description__c == app.Qualification__c){
                                appWrapper.qualification = replacedOutputStr(iter.FICO_Code__c);       //mandatory
                            }
                        }
                        when 'Segment' {
                            if(iter.Description__c == app.Customer_Type__c && iter.Description__c == app.Customer_Profile__c && iter.Description__c == app.Sub_Employment_Type_Non_Individual__c){
                                appWrapper.segment = replacedOutputStr(iter.FICO_Code__c);     //mandatory
                            }
                        }
                        when 'Sub segment' {
                            if(iter.Description__c == app.Sub_Segment__c){
                                appWrapper.subSegment = replacedOutputStr(iter.FICO_Code__c);      //mandatory
                            }
                        }
                        when 'Sector' {
                            if(iter.Description__c == app.Sector__c && iter.Customer_Type__c == app.Customer_Profile__c){
                                appWrapper.sector = replacedOutputStr(iter.FICO_Code__c);      //mandatory
                            }
                        }
                        when 'Sub sector' {
                            if(iter.Description__c == app.Industry__c && iter.Sector_Code__c == appWrapper.sector){
                                appWrapper.subSector = replacedOutputStr(iter.FICO_Code__c);       //mandatory
                            }
                        }
                        when 'Customer Profile' {
                            if(iter.Description__c == app.Customer_Profile__c){
                                appWrapper.employmentType = replacedOutputStr(iter.FICO_Code__c);       //mandatory
                            }
                        }
                        when 'Specialization' {
                            if(iter.Description__c == app.Specialization__c){
                                appAddDetails.natureOfEmployment = replacedOutputStr(iter.FICO_Code__c);
                            }
                        }
                    }
                }

                appWrapper.panNumber = replacedOutputStr(app.PAN_Number__c);
                appWrapper.numOfDependents = zeroInteger;
                appWrapper.companyCategory = '';
                appWrapper.natureOfBusiness = '';
                appWrapper.residentialStatus = replacedOutputStr(app.Residency_Status__c);      //mandatory
                appWrapper.customerBranch = replacedOutputStr(loanObj.Branch_Master__r.Branch_Code__c);         //mandatory
                appWrapper.dsaCode = loanObj.Lead__r?.Channel_Code__c;
                appWrapper.posidex = '';

                //customerIds
                List<cls_customerIds> applicantIdsLst = new List<cls_customerIds>();
                
                if(kycDocumentMap.containsKey(app.Id)){
                    for(Document_Details__c docRec : kycDocumentMap.get(app.Id)){
                        cls_customerIds applicantIds = new cls_customerIds();
                        applicantIds.customerCif = replacedOutputStr(appCustomerCIF);      //mandatory
                        applicantIds.idType = replacedOutputStr(docRec.Document_Master__r.Document_Type__c);           //mandatory
                        applicantIds.documentName = docRec.Name;
                        applicantIds.idNumber = '';         //mandatory
                        applicantIds.issuedCountry = 'IN';    //mandatory
                        applicantIds.issuedOn = '';         //mandatory
                        applicantIds.expiryDate = '';       //mandatory

                        if(app.Customer_Type__c == constants.get('CUSTOMER_TYPE_INDIVIDUAL')){
                            if(docRec.Name.contains('Passport')){
                                applicantIds.idNumber = app.Passport_Number__c;
                                applicantIds.issuedOn = app.Passport_Date_of_Issue__c != null ? app.Passport_Date_of_Issue__c.toString() : '';         //mandatory
                                applicantIds.expiryDate = app.Passport_Date_of_Expiry__c != null ? app.Passport_Date_of_Expiry__c.toString() : '';       //mandatory
                            }
                            else if(docRec.Name.contains('Voter')){
                                applicantIds.idNumber = replacedOutputStr(app.Voter_ID_Number__c);         //mandatory
                            }
                            else if(docRec.Name.contains('Adhaar') || docRec.Name.contains('Aadhaar')){
                                applicantIds.idNumber = replacedOutputStr(app.Aadhaar_Number__c);          //mandatory
                            }
                            else if(docRec.Name.contains('Driving License') || docRec.Name.contains('DL')){
                                applicantIds.idNumber = replacedOutputStr(app.Drivers_License_Number__c);          //mandatory
                            }
                        }

                        if(docRec.Name.contains('PAN')){
                            applicantIds.idNumber = replacedOutputStr(app.PAN_Number__c);              //mandatory
                        }

                        applicantIds.remarks = '';
                        applicantIdsLst.add(applicantIds);
                    }
                }
                //customerIds

                //addressDetails
                List<cls_addressDetails> applicantAddreDetailsLst = new List<cls_addressDetails>();

                if(applicatAddressMap.containsKey(app.Id)){
                    for(Applicant_Address__c addRec : applicatAddressMap.get(app.Id)){
                        cls_addressDetails appAddreDetails = new cls_addressDetails();
                        appAddreDetails.addressType = '';         //mandatory  FICO Code

                        if(masterCodeMap.containsKey('Address Type')){
                            for(PLF_Master__c iter : masterCodeMap.get('Address Type')) {
                                if(iter.description__c == addRec.Address_Type__c){
                                    appAddreDetails.addressType = replacedOutputStr(iter.FICO_Code__c);      //mandatory     FICO Code
                                    break;
                                }
                            }
                        }

                        appAddreDetails.landmark = addRec.Landmark__c;
                        appAddreDetails.locality = '';
                        appAddreDetails.city = replacedOutputStr(addRec.Pincode__r.City__r.Name);        //mandatory
                        appAddreDetails.pinCode = replacedOutputStr(addRec.Pincode__r.Name);       //mandatory
                        appAddreDetails.priority = String.isNotBlank(addRec.Address_Priority__c) ? Integer.valueOf(addRec.Address_Priority__c) : 5;     //mandatory
                        appAddreDetails.pinCodeServicability = addRec.Pincode__r.Is_Pincode_Servicable__c;        //mandatory
                        applicantAddreDetailsLst.add(appAddreDetails);
                    }
                }
                //addressDetails

                //phoneDetails
                cls_phoneDetails appPhoneDetails = new cls_phoneDetails();
                appPhoneDetails.customerCif = replacedOutputStr(appCustomerCIF);      //mandatory
                appPhoneDetails.phoneTypeCode = '';
                appPhoneDetails.phoneNumber = replacedOutputStr(app.Mobile_Number__c);             //mandatory
                appPhoneDetails.priority = '5';                //mandatory
                //phoneDetails

                cls_emailDetails appEmailDetails = new cls_emailDetails();
                appEmailDetails.customerCif = replacedOutputStr(appCustomerCIF);      //mandatory
                appEmailDetails.emailType = '';
                appEmailDetails.email = replacedOutputStr(app.Email__c);           //mandatory
                appEmailDetails.priority = '5';        //mandatory

                //emailDetails
                cls_kycDetails applicantKey = new cls_kycDetails();
                applicantKey.customerIds = applicantIdsLst;
                applicantKey.addressDetails = applicantAddreDetailsLst;
                applicantKey.phoneDetails = appPhoneDetails;
                applicantKey.emailDetails = appEmailDetails;
                appWrapper.kycDetails = applicantKey;
                //emailDetails

                appAddDetails.leadSquaredLeadId = '';
                appAddDetails.occupationCategory = '';

                //customerSalaried
                cls_customerSalaried customerSalaried = new cls_customerSalaried();
                customerSalaried.employerName = '';
                customerSalaried.emailIdOfficial = '';
                customerSalaried.ifSalaried = '';
                customerSalaried.designation = '';
                customerSalaried.currentWorkExperience = zeroInteger;
                customerSalaried.totalWorkExperience = app.Total_Work_Experience_Years__c != null ? Integer.valueOf(app.Total_Work_Experience_Years__c) : zeroInteger;     // Total work experience in years up to one decimal place (confirmed)
                customerSalaried.idType = '';
                //customerSalaried

                //customerSep
                cls_customerSep customerSep = new cls_customerSep();
                customerSep.industry = '';
                customerSep.product = '';
                customerSep.typeOfService = '';
                customerSep.totalWorkExperience = app.Total_Work_Experience_Years__c != null ? Integer.valueOf(app.Total_Work_Experience_Years__c) : zeroInteger;     // Total work experience in years up to one decimal place (confirmed)
                //customerSep

                //customerSenp
                cls_customerSenp customerSenp = new cls_customerSenp();
                customerSenp.senp = '';
                customerSenp.dateOfCommencement = String.valueOf(app.DOI__c);
                customerSenp.totalWorkExperience = app.Total_Work_Experience_Years__c != null ? Integer.valueOf(app.Total_Work_Experience_Years__c) : zeroInteger;
                //customerSenp

                //customerEntityType
                cls_customerEntityType customerEntityType = new cls_customerEntityType();
                customerEntityType.businessOrProffessional = '';
                customerEntityType.landmark = '';
                customerEntityType.pinCode = zeroInteger;
                //customerEntityType

                //customerAreaName
                cls_customerAreaName customerAreaName = new cls_customerAreaName();
                customerAreaName.city = '';
                customerAreaName.district = '';
                customerAreaName.state = '';
                //customerAreaName

                //customerIndividualSalaried
                cls_customerIndividualSalaried customerIndSalaried = new cls_customerIndividualSalaried();
                if(isFromCalculator){
                    customerIndSalaried.grossAnnualSalaryIncome = grossSalary * 12;
                }else{
                    customerIndSalaried.grossAnnualSalaryIncome = appIncomeDeductionMap.containsKey(app.Id) ? appIncomeDeductionMap.get(app.Id)[0] : zeroDecimal;
                }

                customerIndSalaried.rentalIncome = zeroDecimal;
                customerIndSalaried.otherIncome = zeroDecimal;
                //customerIndividualSalaried

                //customerSelfEmployedProfesional
                cls_customerSelfEmployedProfesional customerSelfEmployedProf = new cls_customerSelfEmployedProfesional();
                customerSelfEmployedProf.grossTurnOver = zeroInteger;
                customerSelfEmployedProf.grossReceiptFromBusiness = zeroInteger;
                customerSelfEmployedProf.profession = zeroInteger;
                customerSelfEmployedProf.rentalIncome = zeroInteger;
                customerSelfEmployedProf.otherIncome = zeroInteger;
                //customerSelfEmployedProfesional

                //customerNonIndividual
                cls_customerNonIndividual customerNonIndividual = new cls_customerNonIndividual();
                customerNonIndividual.netProfitFromBusiness = zeroDecimal;
                customerNonIndividual.profession = zeroDecimal;
                customerNonIndividual.otherIncome = zeroDecimal;
                //customerNonIndividual

                //associatedCompanies
                cls_associatedCompanies associatedCompanies = new cls_associatedCompanies();
                associatedCompanies.associatedCompanyName1 = '';
                associatedCompanies.associatedCompanyName2 = '';
                associatedCompanies.associatedCompanyName3 = '';
                associatedCompanies.associatedCompanyName4 = '';
                associatedCompanies.associatedCompanyName5 = '';
                //associatedCompanies

                //poaHolderDetails
                cls_poaHolderDetails poaHolderDetails = new cls_poaHolderDetails();
                poaHolderDetails.fullName = '';
                poaHolderDetails.addressType = '';
                poaHolderDetails.landmark = '';
                poaHolderDetails.locality = '';
                poaHolderDetails.city = '';
                poaHolderDetails.subDistrict = '';
                poaHolderDetails.district = '';
                poaHolderDetails.state = '';
                poaHolderDetails.country = '';
                poaHolderDetails.pinCode = '';
                poaHolderDetails.poBox = '';
                poaHolderDetails.photoIdType = '';
                poaHolderDetails.photoIdNo = '';
                poaHolderDetails.addressIdType = '';
                poaHolderDetails.addressIdNo = '';
                poaHolderDetails.mobileNo = '';
                poaHolderDetails.relationWithApplicant = '';
                //poaHolderDetails

                //nriIncomeDetails
                cls_nriIncomeDetails nriIncomeDetails = new cls_nriIncomeDetails();
                nriIncomeDetails.currencyRemove = '';
                nriIncomeDetails.dateOfConversion = '';
                nriIncomeDetails.rateOfConversion = zeroDecimal;
                nriIncomeDetails.monthlyNetSalaryForeignCurrency = '';
                nriIncomeDetails.workExperienceAbroadMonths = '';
                //nriIncomeDetails

                //sepEligibility
                cls_sepEligibility sepEligibility = new cls_sepEligibility();
                sepEligibility.grossAnnualRecieptsLatestYear = zeroDecimal;
                sepEligibility.grossAnnualRecieptsPreviousYear = zeroDecimal;
                sepEligibility.isGrowthSustainable = '';
                sepEligibility.additionalMultiplier = zeroDecimal;
                sepEligibility.additionalFoir = additionalFOIR;
                sepEligibility.GROWANNRC = '';
                sepEligibility.INCMG = '';
                sepEligibility.MAXFOIRSEP = '';
                //sepEligibility

                //senpRiskScoreEligibility
                cls_senpRiskScoreEligibility senpRiskScoreEligibility = new cls_senpRiskScoreEligibility();
                senpRiskScoreEligibility.ccOdUtilization = '';
                senpRiskScoreEligibility.debtEquityRatio = zeroDecimal;
                senpRiskScoreEligibility.abbEmiRatio = zeroDecimal;
                senpRiskScoreEligibility.processBelowRiskCutOff = '';
                //senpRiskScoreEligibility

                //senpLatestYearEligibility
                cls_senpLatestYearEligibility senpLatestYearEligibility = new cls_senpLatestYearEligibility();
                senpLatestYearEligibility.oneTimeIncome = zeroDecimal;
                senpLatestYearEligibility.turnover = zeroDecimal;
                senpLatestYearEligibility.grossProfit = zeroDecimal;
                senpLatestYearEligibility.netPbt = zeroDecimal;
                senpLatestYearEligibility.depreciation = zeroDecimal;
                senpLatestYearEligibility.salaryPartner = zeroDecimal;
                senpLatestYearEligibility.interestPartner = zeroDecimal;
                senpLatestYearEligibility.interestRelative = zeroDecimal;
                senpLatestYearEligibility.interestBank = zeroDecimal;
                senpLatestYearEligibility.oneTimeExpense = zeroDecimal;
                senpLatestYearEligibility.CASHPROFLAST = '';
                senpLatestYearEligibility.otherIncome = zeroDecimal;
                //senpLatestYearEligibility

                //senpPreviousYearEligibility
                cls_senpPreviousYearEligibility senpPreviousYearEligibility = new cls_senpPreviousYearEligibility();
                senpPreviousYearEligibility.oneTimeIncome = zeroDecimal;
                senpPreviousYearEligibility.turnover = zeroDecimal;
                senpPreviousYearEligibility.grossProfit = zeroDecimal;
                senpPreviousYearEligibility.netPbt = zeroDecimal;
                senpPreviousYearEligibility.depreciation = zeroDecimal;
                senpPreviousYearEligibility.salaryPartner = zeroDecimal;
                senpPreviousYearEligibility.interestPartner = zeroDecimal;
                senpPreviousYearEligibility.interestRelative = zeroDecimal;
                senpPreviousYearEligibility.interestBank = zeroDecimal;
                senpPreviousYearEligibility.oneTimeExpense = zeroDecimal;
                senpPreviousYearEligibility.CASHPROFPREV = '';
                senpPreviousYearEligibility.otherIncome = zeroDecimal;
                //senpPreviousYearEligibility

                //senpGrowthPercentageEligibility
                cls_senpGrowthPercentageEligibility senpGrowthPercentageEligibility = new cls_senpGrowthPercentageEligibility();
                senpGrowthPercentageEligibility.isTurnoverGrowthSutainable = '';
                senpGrowthPercentageEligibility.isGrossProfitGrowthSutainable = constants.get('isGrossProfitGrowthSutainable');
                senpGrowthPercentageEligibility.isCashProfitGrowthSutainable = '';
                senpGrowthPercentageEligibility.TURNGROPER = '';
                senpGrowthPercentageEligibility.GRPRGRPER = '';
                senpGrowthPercentageEligibility.CASFPRGPER = '';
                //senpGrowthPercentageEligibility

                //otherSenpInputEligibility
                cls_otherSenpInputEligibility otherSenpInputEligibility = new cls_otherSenpInputEligibility();
                otherSenpInputEligibility.industryMarginCRISIL = zeroDecimal;
                otherSenpInputEligibility.annulisedSalaryDirector = zeroDecimal;     //Mandatory (Direcotr)
                otherSenpInputEligibility.avgMonthlyBalancePerfios = zeroDecimal;
                otherSenpInputEligibility.maxAbbEmiRatioAllowed = '';
                otherSenpInputEligibility.additionalFoir = additionalFOIR;
                otherSenpInputEligibility.overrideAbbEmiRatio = zeroDecimal;
                otherSenpInputEligibility.additionalGrossMargin = zeroDecimal;
                otherSenpInputEligibility.processBelowRiskCutOff = '';
                otherSenpInputEligibility.incomeProgram = '';       //mandatory (SENP - Gross Margin, Cash Profit)
                otherSenpInputEligibility.ELIMAXLA = '';
                otherSenpInputEligibility.MAXFOIRSENP = '';
                otherSenpInputEligibility.MAXGROSSENP = '';
                //otherSenpInputEligibility

                //salariedEligibility
                cls_salariedEligibility salariedEligibility = new cls_salariedEligibility();
                salariedEligibility.latestYearBonus = zeroDecimal;
                salariedEligibility.previousYearBonus = zeroDecimal;
                salariedEligibility.incentiveMonth1 = zeroDecimal;
                salariedEligibility.incentiveMonth2 = zeroDecimal;
                salariedEligibility.incentiveMonth3 = zeroDecimal;
                salariedEligibility.incentiveMonth4 = zeroDecimal;
                salariedEligibility.incentiveMonth5 = zeroDecimal;
                salariedEligibility.incentiveMonth6 = zeroDecimal;
                salariedEligibility.additionalFoir = additionalFOIR;
                salariedEligibility.processCaseRiskCutoff = '';
                salariedEligibility.buffer1 = '100';        //Mandatory hardcoded value for Salaried
                salariedEligibility.buffer2 = '';
                salariedEligibility.buffer3 = '';
                salariedEligibility.buffer4 = '';
                salariedEligibility.buffer5 = '';
                salariedEligibility.buffer6 = '';
                salariedEligibility.buffer7 = '';
                salariedEligibility.buffer8 = '';
                salariedEligibility.buffer9 = '';
                salariedEligibility.buffer10 = '';
                salariedEligibility.MAXFOIRSAL = '';
                //salariedEligibility
                
                decimal incomeProgramObligation = 0;
                
                if(isFromCalculator){
                    salariedEligibility.latestYearBonus = latestYearBonus;
                    salariedEligibility.previousYearBonus = previousYearBonus;

                    salariedEligibility.incentiveMonth1 = month1Net;
                    salariedEligibility.incentiveMonth2 = month2Net;
                    salariedEligibility.incentiveMonth3 = month3Net;
                    salariedEligibility.incentiveMonth4 = month4Net;
                    salariedEligibility.incentiveMonth5 = month5Net;
                    salariedEligibility.incentiveMonth6 = month6Net;

                    customerIndSalaried.rentalIncome = rentalIncome;
                }
                else{
                    if(appIncomeAssMap.containsKey(app.Id)){
                        Map<string, Income_Assessment__c> appIncomeAssMapTmp = appIncomeAssMap.get(app.Id);

                        for(string appKey : appIncomeAssMapTmp.keySet()){
                            
                            Income_Assessment__c parentRec = appIncomeAssMapTmp.get(appKey);
                            system.debug('parentRec: '+parentRec);

                            switch on parentRec.RecordType.Name {
                                when 'Director Renumeration' {
                                    if(app.AmountConsideredForEligibilityPurpos__c != null){
                                        otherSenpInputEligibility.annulisedSalaryDirector = Decimal.valueOf(app.AmountConsideredForEligibilityPurpos__c);
                                        otherSenpInputEligibility.incomeProgram = 'DIRECTOR RENUMERATION';
                                    }
                                    sepEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                    // otherSenpInputEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                    // salariedEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                }
                                when 'Gross Margin' {
                                    senpGrowthPercentageEligibility.isTurnoverGrowthSutainable = String.valueOf(parentRec.Is_Turnover_Growth_Sustainable__c);
                                    senpGrowthPercentageEligibility.isGrossProfitGrowthSutainable = String.valueOf(parentRec.Is_Gross_Profit_Sustainable__c);
                                    senpGrowthPercentageEligibility.isCashProfitGrowthSutainable = String.valueOf(parentRec.Is_Cash_Profit_Sustainable__c);
                                    otherSenpInputEligibility.additionalGrossMargin = parentRec.Additional_Gross_Margin__c != null ? parentRec.Additional_Gross_Margin__c : 0;
                                    // sepEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                    otherSenpInputEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                    // salariedEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                }
                                when 'Cash Profit' {
                                    senpGrowthPercentageEligibility.isTurnoverGrowthSutainable = String.valueOf(parentRec.Is_Turnover_Growth_Sustainable__c);
                                    senpGrowthPercentageEligibility.isGrossProfitGrowthSutainable = String.valueOf(parentRec.Is_Gross_Profit_Sustainable__c);
                                    senpGrowthPercentageEligibility.isCashProfitGrowthSutainable = String.valueOf(parentRec.Is_Cash_Profit_Sustainable__c);
                                    // sepEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                    otherSenpInputEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                    // salariedEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                }
                                when 'Sep Multiplier' {
                                    sepEligibility.isGrowthSustainable = String.valueOf(parentRec.Is_Growth_Sustainable__c);
                                    sepEligibility.additionalMultiplier=parentRec.Additional_Multiplier__c != null ? parentRec.Additional_Multiplier__c: 0; 
                                    sepEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                    // otherSenpInputEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                    // salariedEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                }
                                when 'Banking' {
                                    otherSenpInputEligibility.overrideAbbEmiRatio = parentRec.Override_ABB_EMI_Ratio__c;
                                }
                                when 'Low LTV Program' {
                                    otherSenpInputEligibility.overrideAbbEmiRatio = parentRec.Override_ABB_EMI_Ratio__c;
                                    // sepEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                    otherSenpInputEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                    // salariedEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                }
                                when 'Rental Income Program' {
                                    // sepEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                    otherSenpInputEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                    // salariedEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                }
                                when 'Liquid Income Program' {
                                    // sepEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                    otherSenpInputEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                    // salariedEligibility.additionalFoir = parentRec.HL_Additional_FOIR__c;
                                }
                            }

                            if(parentIncomeAssMap.containsKey(parentRec.Id)){ 
                                
                                Map<string, List<Income_Assessment__c>> incomeAssRecordTypeMap = parentIncomeAssMap.get(parentRec.Id);
                                system.debug('incomeAssRecordTypeMap: '+ JSON.serialize(incomeAssRecordTypeMap));

                                //Salaried Ind
                                if(incomeAssRecordTypeMap.containsKey('Salaried Yearly Component')){
                                    decimal lowerMultiplier = 0;
                                    for(Income_Assessment__c rec : incomeAssRecordTypeMap.get('Salaried Yearly Component')){
                                        switch on rec.Yearly_Component__c {
                                            when 'Latest Year Bonus' {
                                                salariedEligibility.latestYearBonus = rec.Net_Amount__c != null ? rec.Net_Amount__c : 0;
                                            }
                                            when 'Previous Year Bonus' {
                                                salariedEligibility.previousYearBonus = rec.Net_Amount__c != null ? rec.Net_Amount__c : 0;
                                            }
                                        }

                                        lowerMultiplier = (rec.Multiplier__c >0 && rec.Multiplier__c < lowerMultiplier) ? rec.Multiplier__c : lowerMultiplier;
                                    }

                                    salariedEligibility.buffer10 = lowerMultiplier.toString();
                                    otherSenpInputEligibility.annulisedSalaryDirector = zeroDecimal;
                                    customerSenp.dateOfCommencement = '';
                                }

                                if(incomeAssRecordTypeMap.containsKey('Salaried Incentive Component')){
                                    decimal lowerMultiplier = 0;
                                    for(Income_Assessment__c rec : incomeAssRecordTypeMap.get('Salaried Incentive Component')){
                                        switch on rec.Yearly_Component__c {
                                            when 'Month 1' {
                                                salariedEligibility.incentiveMonth1 = rec.Net_Amount__c != null ? rec.Net_Amount__c : 0;
                                            }
                                            when 'Month 2' {
                                                salariedEligibility.incentiveMonth2 = rec.Net_Amount__c != null ? rec.Net_Amount__c : 0;
                                            }
                                            when 'Month 3' {
                                                salariedEligibility.incentiveMonth3 = rec.Net_Amount__c != null ? rec.Net_Amount__c : 0;
                                            }
                                            when 'Month 4' {
                                                salariedEligibility.incentiveMonth4 = rec.Net_Amount__c != null ? rec.Net_Amount__c : 0;
                                            }
                                            when 'Month 5' {
                                                salariedEligibility.incentiveMonth5 = rec.Net_Amount__c != null ? rec.Net_Amount__c : 0;
                                            }
                                            when 'Month 6' {
                                                salariedEligibility.incentiveMonth6 = rec.Net_Amount__c != null ? rec.Net_Amount__c : 0;
                                            }
                                        }

                                        lowerMultiplier = (rec.Multiplier__c >0 && rec.Multiplier__c < lowerMultiplier) ? rec.Multiplier__c : lowerMultiplier;
                                    }

                                    salariedEligibility.buffer2 = lowerMultiplier.toString();
                                    otherSenpInputEligibility.annulisedSalaryDirector = zeroDecimal;
                                    customerSenp.dateOfCommencement = '';
                                }
                                //Salaried Ind

                                //Cash Profit
                                if(incomeAssRecordTypeMap.containsKey('Cash Profit')){
                                    Map<string, List<Income_Assessment__c>> cashProfitMap = appIncomeChildMap.get(app.Id);
                                    system.debug('cashProfitMap: '+ JSON.serialize(cashProfitMap));
                                    
                                    for(Income_Assessment__c rec : incomeAssRecordTypeMap.get('Cash Profit')){
            
                                        if(rec.Cash_Profit_Particular__c == 'Turnover' && cashProfitMap.containsKey(rec.Cash_Profit_Particular__c)) {
                                            List<Income_Assessment__c> monthsData = cashProfitMap.get(rec.Cash_Profit_Particular__c);
                                            senpLatestYearEligibility.turnover = monthsData[0].Average_Amount__c;
                                            senpPreviousYearEligibility.turnover = monthsData[1].Average_Amount__c;

                                            senpGrowthPercentageEligibility.TURNGROPER = monthsData[0].Growth__c != null ? monthsData[0].Growth__c.toString() : '0';
                                        }
                                        else if(rec.Cash_Profit_Particular__c == 'Net PBT' && cashProfitMap.containsKey(rec.Cash_Profit_Particular__c)) {
                                            List<Income_Assessment__c> monthsData = cashProfitMap.get(rec.Cash_Profit_Particular__c);
                                            senpLatestYearEligibility.netPbt = monthsData[0].Average_Amount__c;
                                            senpPreviousYearEligibility.netPbt = monthsData[1].Average_Amount__c;
                                        }
                                        else if(rec.Cash_Profit_Particular__c == 'Depreciation' && cashProfitMap.containsKey(rec.Cash_Profit_Particular__c)) {
                                            List<Income_Assessment__c> monthsData = cashProfitMap.get(rec.Cash_Profit_Particular__c);
                                            senpLatestYearEligibility.depreciation = monthsData[0].Average_Amount__c;
                                            senpPreviousYearEligibility.depreciation = monthsData[1].Average_Amount__c;
                                        }
                                        else if(rec.Cash_Profit_Particular__c == 'Salary paid to Partners/Directors who are on loan structure' && cashProfitMap.containsKey(rec.Cash_Profit_Particular__c)) {
                                            List<Income_Assessment__c> monthsData = cashProfitMap.get(rec.Cash_Profit_Particular__c);
                                            senpLatestYearEligibility.salaryPartner = monthsData[0].Average_Amount__c;
                                            senpPreviousYearEligibility.salaryPartner = monthsData[1].Average_Amount__c;
                                        }
                                        else if(rec.Cash_Profit_Particular__c == 'Interest paid to Partner/Directors who are on loan structure' && cashProfitMap.containsKey(rec.Cash_Profit_Particular__c)) {
                                            List<Income_Assessment__c> monthsData = cashProfitMap.get(rec.Cash_Profit_Particular__c);
                                            senpLatestYearEligibility.interestPartner = monthsData[0].Average_Amount__c;
                                            senpPreviousYearEligibility.interestPartner = monthsData[1].Average_Amount__c;
                                        }
                                        else if(rec.Cash_Profit_Particular__c == 'Interest paid to close relative’s u/s. 40A2 (b) as per tax audit report; close relatives who are on loan structure' && cashProfitMap.containsKey(rec.Cash_Profit_Particular__c)) {
                                            List<Income_Assessment__c> monthsData = cashProfitMap.get(rec.Cash_Profit_Particular__c);
                                            senpLatestYearEligibility.interestRelative = monthsData[0].Average_Amount__c;
                                            senpPreviousYearEligibility.interestRelative = monthsData[1].Average_Amount__c;
                                        }
                                        else if(rec.Cash_Profit_Particular__c == 'Interest Paid on Loans to Banks/Fis (Incl. CC/OD)' && cashProfitMap.containsKey(rec.Cash_Profit_Particular__c)) {
                                            List<Income_Assessment__c> monthsData = cashProfitMap.get(rec.Cash_Profit_Particular__c);
                                            senpLatestYearEligibility.interestBank = monthsData[0].Average_Amount__c;
                                            senpPreviousYearEligibility.interestBank = monthsData[1].Average_Amount__c;
                                        }
                                        else if(rec.Cash_Profit_Particular__c == 'One time expense' && cashProfitMap.containsKey(rec.Cash_Profit_Particular__c)) {
                                            List<Income_Assessment__c> monthsData = cashProfitMap.get(rec.Cash_Profit_Particular__c);
                                            senpLatestYearEligibility.oneTimeExpense = monthsData[0].Average_Amount__c;
                                            senpPreviousYearEligibility.oneTimeExpense = monthsData[1].Average_Amount__c;
                                        }
                                        else if(rec.Cash_Profit_Particular__c == 'One time income (Less)' && cashProfitMap.containsKey(rec.Cash_Profit_Particular__c)) {
                                            List<Income_Assessment__c> monthsData = cashProfitMap.get(rec.Cash_Profit_Particular__c);
                                            senpLatestYearEligibility.oneTimeIncome = monthsData[0].Average_Amount__c;
                                            senpPreviousYearEligibility.oneTimeIncome = monthsData[1].Average_Amount__c;
                                        }
                                        else if(rec.Cash_Profit_Particular__c == 'Gross profit' && cashProfitMap.containsKey(rec.Cash_Profit_Particular__c)) {
                                            List<Income_Assessment__c> monthsData = cashProfitMap.get(rec.Cash_Profit_Particular__c);
                                            senpLatestYearEligibility.grossProfit = monthsData[0].Average_Amount__c;
                                            senpPreviousYearEligibility.grossProfit = monthsData[1].Average_Amount__c;

                                            senpGrowthPercentageEligibility.GRPRGRPER = monthsData[0].Growth__c != null ? monthsData[0].Growth__c.toString() : '0';
                                        }
                                        else if(rec.Cash_Profit_Particular__c == 'Cash Profit' && cashProfitMap.containsKey(rec.Cash_Profit_Particular__c)) {
                                            List<Income_Assessment__c> monthsData = cashProfitMap.get(rec.Cash_Profit_Particular__c);
                                            senpLatestYearEligibility.CASHPROFLAST = String.valueOf(monthsData[0].Average_Amount__c);
                                            senpPreviousYearEligibility.CASHPROFPREV = String.valueOf(monthsData[1].Average_Amount__c);

                                            senpGrowthPercentageEligibility.CASFPRGPER = monthsData[0].Growth__c != null ? monthsData[0].Growth__c.toString() : '0';
                                        }
                                    }

                                    otherSenpInputEligibility.incomeProgram = 'CASH PROFIT';
                                }
                                //Cash Profit

                                //Gross Margin
                                if(incomeAssRecordTypeMap.containsKey('Gross Margin')){
                                    Map<string, List<Income_Assessment__c>> grossMarginMap = appIncomeChildMap.get(app.Id);
                                    system.debug('grossMarginMap: '+ JSON.serialize(grossMarginMap));
                                    
                                    for(Income_Assessment__c rec : incomeAssRecordTypeMap.get('Gross Margin')){
            
                                        if(rec.HL_Gross_Margin_Particular__c == 'Turnover' && grossMarginMap.containsKey(rec.HL_Gross_Margin_Particular__c)) {
                                            List<Income_Assessment__c> monthsData = grossMarginMap.get(rec.HL_Gross_Margin_Particular__c);
                                            senpLatestYearEligibility.turnover = monthsData[0].Yearly_Amount__c;
                                            senpPreviousYearEligibility.turnover = monthsData[1].Yearly_Amount__c;

                                            senpGrowthPercentageEligibility.TURNGROPER = monthsData[0].Growth__c != null ? monthsData[0].Growth__c.toString() : '0';
                                        }
                                        else if(rec.HL_Gross_Margin_Particular__c == 'Gross Profit (From P&L)' && grossMarginMap.containsKey(rec.HL_Gross_Margin_Particular__c)) {
                                            List<Income_Assessment__c> monthsData = grossMarginMap.get(rec.HL_Gross_Margin_Particular__c);
                                            senpLatestYearEligibility.grossProfit = monthsData[0].Yearly_Amount__c;
                                            senpPreviousYearEligibility.grossProfit = monthsData[1].Yearly_Amount__c;

                                            senpGrowthPercentageEligibility.GRPRGRPER = monthsData[0].Growth__c != null ? monthsData[0].Growth__c.toString() : '0';
                                        }
                                    }

                                    otherSenpInputEligibility.incomeProgram = 'GROSS MARGIN';
                                }
                                //Gross Margin

                                //Salaried NRI
                                if(incomeAssRecordTypeMap.containsKey('Salaried NRI')){
                                    
                                    for(Income_Assessment__c rec : incomeAssRecordTypeMap.get('Salaried NRI')){
                                        if(rec.Amount_in_Foreign__c != null && rec.Amount_in_Foreign__c >0){
                                            
                                            if(rec.Parent__r.Type_of_Income_Assesment__c == 'Obligations'){
                                                incomeProgramObligation += rec.Amount_in_Foreign__c * rec.Exchange_Rate__c;
                                            }else{
                                                nriIncomeDetails.monthlyNetSalaryForeignCurrency = (rec.Amount_in_Foreign__c * rec.Exchange_Rate__c).toString();
                                            }
                                        }
                                    }

                                    appWrapper.residentialStatus = '';
                                    customerIndSalaried.grossAnnualSalaryIncome = zeroDecimal;
                                }
                                //Salaried NRI

                                //Merchant Navy
                                if(incomeAssRecordTypeMap.containsKey('Merchant Navy')){

                                    for(Income_Assessment__c rec : incomeAssRecordTypeMap.get('Merchant Navy')){
                                        if(rec.Amount_in_Foreign__c != null && rec.Amount_in_Foreign__c >0){
                                            
                                            if(rec.Parent__r.Type_of_Income_Assesment__c == 'Obligations'){
                                                incomeProgramObligation += rec.Amount_in_Foreign__c * rec.Exchange_Rate__c;
                                            }else{
                                                nriIncomeDetails.monthlyNetSalaryForeignCurrency = rec.Amount_in_Foreign__c.toString();
                                            }
                                        }
                                    }

                                    appWrapper.residentialStatus = '';
                                    customerIndSalaried.grossAnnualSalaryIncome = zeroDecimal;
                                }
                                //Merchant Navy

                                //Sep Multiplier
                                if(incomeAssRecordTypeMap.containsKey('Sep Multiplier')){
                                    Map<string, List<Income_Assessment__c>> sepMultiplierMap = appIncomeChildMap.get(app.Id);
                                    system.debug('sepMultiplierMap: '+ JSON.serialize(sepMultiplierMap));

                                    for(Income_Assessment__c rec : incomeAssRecordTypeMap.get('Sep Multiplier')){
                                        if(rec.SepMultiplierParticulars__c == 'Gross Annual Reciepts' && sepMultiplierMap.containsKey(rec.SepMultiplierParticulars__c)){
                                            List<Income_Assessment__c> monthsData = sepMultiplierMap.get(rec.SepMultiplierParticulars__c);
                                            sepEligibility.grossAnnualRecieptsLatestYear = monthsData[0].Yearly_Amount__c;
                                            sepEligibility.grossAnnualRecieptsPreviousYear = monthsData[1].Yearly_Amount__c;
                                            sepEligibility.GROWANNRC = String.ValueOf(monthsData[0].Growth__c);
                                        }
                                    }

                                    otherSenpInputEligibility.incomeProgram = 'SEP MULTIPLIER';
                                }
                                //Sep Multiplier

                                //Rental Income
                                if(incomeAssRecordTypeMap.containsKey('Child Rental Income')){
                                    if(selectedIncomeProgram.contains('Salaried Individual')){
                                        customerIndSalaried.rentalIncome = incomeAssRecordTypeMap.get('Child Rental Income')[0].Yearly_Amount__c != null ? incomeAssRecordTypeMap.get('Child Rental Income')[0].Yearly_Amount__c : 0;
                                    }else{
                                        customerSelfEmployedProf.rentalIncome = incomeAssRecordTypeMap.get('Child Rental Income')[0].Yearly_Amount__c != null ? incomeAssRecordTypeMap.get('Child Rental Income')[0].Yearly_Amount__c : 0;
                                    }
                                }
                                //Rental Income

                                //Banking
                                if(incomeAssRecordTypeMap.containsKey('Banking')){
                                    otherSenpInputEligibility.avgMonthlyBalancePerfios = incomeAssRecordTypeMap.get('Banking')[0].Average_Bank_Balance__c;
                                    otherSenpInputEligibility.maxAbbEmiRatioAllowed = incomeAssRecordTypeMap.get('Banking')[0].HL_Abb_EMI_Ratio__c != null ? String.valueof(incomeAssRecordTypeMap.get('Banking')[0].HL_Abb_EMI_Ratio__c) : '';
                                    otherSenpInputEligibility.overrideAbbEmiRatio=incomeAssRecordTypeMap.get('Banking')[0].Override_ABB_EMI_Ratio__c;
                                    otherSenpInputEligibility.incomeProgram = 'BANKING SURROGATE';
                                }
                                //Banking

                                //Low LTV Program
                                if(incomeAssRecordTypeMap.containsKey('Low LTV Program')){
                                    otherSenpInputEligibility.avgMonthlyBalancePerfios = incomeAssRecordTypeMap.get('Low LTV Program')[0].Average_Bank_Balance__c;
                                    otherSenpInputEligibility.maxAbbEmiRatioAllowed = incomeAssRecordTypeMap.get('Low LTV Program')[0].HL_Abb_EMI_Ratio__c != null ? String.valueof(incomeAssRecordTypeMap.get('Low LTV Program')[0].HL_Abb_EMI_Ratio__c) : '';
                                    otherSenpInputEligibility.overrideAbbEmiRatio=incomeAssRecordTypeMap.get('Low LTV Program')[0].Override_ABB_EMI_Ratio__c;
                                    otherSenpInputEligibility.incomeProgram = 'LOW LTV';
                                }
                                //Low LTV Program
                            }
                        }
                    }
                }

                appAddDetails.customerSalaried = customerSalaried;
                appAddDetails.customerSep = customerSep;
                appAddDetails.customerSenp = customerSenp;
                appAddDetails.customerEntityType = customerEntityType;
                appAddDetails.customerAreaName = customerAreaName;
                appAddDetails.customerIndividualSalaried = customerIndSalaried;
                appAddDetails.customerSelfEmployedProfesional = customerSelfEmployedProf;
                appAddDetails.customerNonIndividual = customerNonIndividual;
                appAddDetails.associatedCompanies = associatedCompanies;
                appAddDetails.poaHolderDetails = poaHolderDetails;
                appAddDetails.nriIncomeDetails = nriIncomeDetails;
                appAddDetails.sepEligibility = sepEligibility;
                appAddDetails.senpRiskScoreEligibility = senpRiskScoreEligibility;
                appAddDetails.senpLatestYearEligibility = senpLatestYearEligibility;
                appAddDetails.senpPreviousYearEligibility = senpPreviousYearEligibility;
                appAddDetails.senpGrowthPercentageEligibility = senpGrowthPercentageEligibility;
                appAddDetails.otherSenpInputEligibility = otherSenpInputEligibility;
                appAddDetails.salariedEligibility = salariedEligibility;

                //bankingDetails
                List<cls_bankingDetails> applicantBankLst = new List<cls_bankingDetails>();

                if(applicantBanksMap.containsKey(app.Id)){
                    bankAccCounter++;
                    integer liabilitySequence = 0;
                    boolean isAddedIncPrgObligation = false;

                    for(Bank_Details__c iterAppBank : applicantBanksMap.get(app.Id)) {
                        cls_bankingDetails appBankObj = new cls_bankingDetails();
                        appBankObj.customerCif = replacedOutputStr(appCustomerCIF);      //mandatory
                        appBankObj.addToBeneficiary = null;
                        appBankObj.accHolderName = replacedOutputStr(iterAppBank.Account_Holder_Name__c);        //mandatory
                        appBankObj.bankName = '';
                        appBankObj.bankBranch = replacedOutputStr(loanObj.Branch_Master__r?.Branch_Code__c);       //mandatory
                        appBankObj.accountType = '';      //mandatory     FICO Code

                        if(masterCodeMap.containsKey('Account Type')){
                            for(PLF_Master__c iter : masterCodeMap.get('Account Type')) {
                                if(iter.description__c == iterAppBank.Account_Type__c){
                                    appBankObj.accountType = replacedOutputStr(iter.FICO_Code__c);       //mandatory     FICO Code
                                    break;
                                }
                            }
                        }

                        appBankObj.accountNo = replacedOutputStr(iterAppBank.Account_Number__c);   //mandatory
                        appBankObj.salaryAccount = null;
                        appBankObj.accountOpenDate = formattedCurrentDate;      //mandatory
                        appBankObj.repaymentFrom = '';
                        appBankObj.phoneNumber = app.Mobile_Number__c;
                        appBankObj.numOfMonthsBanking = 1;
                        appBankObj.ccLimit = Integer.valueOf(iterAppBank.OD_CC_Limit__c);

                        Decimal odCCLimit = 0;
                        Decimal averageABB = 0;
                        Boolean isOverDraft = false;
                        if(bsaBankMap.containsKey(iterAppBank.Id)){
                            for(Bank_Statement_Analysis__c itenBS : bsaBankMap.get(iterAppBank.Id)) {
                                if(itenBS.Bank_Details__r.Account_Type__c == 'Overdraft') {
                                    isOverDraft = true;
                                    odCCLimit = odCCLimit + (itenBS.Sanction_Limit__c != null ? itenBS.Sanction_Limit__c : 0);
                                }
                            }
                        }

                        if(applicantWiseBsaMap.containsKey(primaryAppId)){
                            for(Bank_Statement_Analysis__c itenBSA : applicantWiseBsaMap.get(primaryAppId)) {
                                if(itenBSA.ABB__c != null) {
                                    averageABB = averageABB + itenBSA.ABB__c;
                                }
                            }
                        }

                        if(isOverDraft) {
                            appBankObj.ccLimit = Integer.valueOf(odCCLimit);
                        }

                        appBankObj.typeOfBanks = '';
                        appBankObj.iwOwRatio = String.valueOf(applicantAddCount.get(primaryAppId));
                        appBankObj.documentName = iterAppBank.Account_type_FICO__c;
                        appBankObj.monthAndYearDayBalance = '';

                        //accountBehaviourDetails
                        cls_accountBehaviourDetails appBankBehaDetails = new cls_accountBehaviourDetails();
                        appBankBehaDetails.customerCif = replacedOutputStr(appCustomerCIF);      //mandatory
                        appBankBehaDetails.chequeSequence = zeroInteger;
                        appBankBehaDetails.monthAndYear = '';
                        appBankBehaDetails.paymentCheques = zeroInteger;
                        appBankBehaDetails.salaryOrIncome = zeroInteger;
                        appBankBehaDetails.debits = zeroInteger;
                        appBankBehaDetails.returnChequeAmount = zeroInteger;
                        appBankBehaDetails.returnCount = zeroInteger;        //mandatory
                        appBankBehaDetails.remarks = '';
                        //accountBehaviourDetails

                        appBankObj.accountBehaviourDetails = appBankBehaDetails;

                        List<cls_externalLiabilities> externalLiabilitiesList = new List<cls_externalLiabilities>();

                        cls_externalLiabilities extLiab = new cls_externalLiabilities();
                        extLiab.liabilitySequence = liabilitySequence;
                        extLiab.product = '';        //mandatory
                        extLiab.bankName = '';       //mandatory
                        extLiab.otherFinancialInstitute = '';
                        
                        cls_installmentAmount clsInstallAmt = new cls_installmentAmount();
                        clsInstallAmt.amount = 0;

                        if(!isFromCalculator){
                            clsInstallAmt.amount = Integer.valueOf(emis);
                        }

                        extLiab.installmentAmount = clsInstallAmt;
                        extLiab.outstandingBalance = '';
                        extLiab.originalAmount = constants.get('Zero_Decimal');         //mandatory
                        extLiab.loanDate = formattedLoanDate;               //mandatory
                        extLiab.status = '';                 //mandatory
                        extLiab.roi = '';
                        extLiab.totalTenure = zeroInteger;      //mandatory
                        extLiab.balanceTenure = zeroInteger;    //mandatory
                        extLiab.noOfBouncesL3m = zeroInteger;
                        extLiab.noOfBouncesL6m = zeroInteger;
                        extLiab.noOfBouncesL12m = zeroInteger;
                        extLiab.pos = '';
                        extLiab.overdue = '';
                        extLiab.emiConsideredForFoir = bankAccCounter == 1;        //send this true when you want BRE to consider obligation for FOIR calculation, in case of multiple bank account considerd for income then only first account should be true remaining will be false
                        extLiab.sourceOfInfo = zeroInteger;         //mandatory
                        extLiab.trackCheckFrom = zeroInteger;       //mandatory
                        extLiab.securityDetails = '';
                        extLiab.endUseOfFunds = '';          //mandatory
                        extLiab.repaymentFrom = '';          //mandatory
                        extLiab.repaymentBankAccNo = '';
                        extLiab.consideredRtrBasedLoan = null;
                        extLiab.imputedEmi = '';
                        extLiab.ownerShip = '';
                        extLiab.last24Months = zeroInteger;
                        extLiab.last6Months = zeroInteger;
                        extLiab.last3Months = zeroInteger;
                        extLiab.mob = zeroInteger;
                        extLiab.remarks = '';
                        
                        externalLiabilitiesList.add(extLiab);
                        liabilitySequence++;

                        if((isAddedIncPrgObligation == false && incomeProgramObligation >0) || isFromCalculator == true){
                            isAddedIncPrgObligation = true;

                            cls_externalLiabilities extLiab1 = new cls_externalLiabilities();
                            extLiab1.liabilitySequence = liabilitySequence;
                            extLiab1.product = '';        //mandatory
                            extLiab1.bankName = '';       //mandatory
                            extLiab1.otherFinancialInstitute = '';
                            
                            cls_installmentAmount clsInstallAmt1 = new cls_installmentAmount();
                            clsInstallAmt1.amount = totalObligation;

                            if(!isFromCalculator){
                                clsInstallAmt1.amount = Integer.valueOf(incomeProgramObligation);
                            }

                            extLiab1.installmentAmount = clsInstallAmt1;
                            extLiab1.outstandingBalance = '';
                            extLiab1.originalAmount = constants.get('Zero_Decimal');         //mandatory
                            extLiab1.loanDate = formattedLoanDate;               //mandatory
                            extLiab1.status = '';                 //mandatory
                            extLiab1.roi = '';
                            extLiab1.totalTenure = zeroInteger;      //mandatory
                            extLiab1.balanceTenure = zeroInteger;    //mandatory
                            extLiab1.noOfBouncesL3m = zeroInteger;
                            extLiab1.noOfBouncesL6m = zeroInteger;
                            extLiab1.noOfBouncesL12m = zeroInteger;
                            extLiab1.pos = '';
                            extLiab1.overdue = '';
                            extLiab1.emiConsideredForFoir = true;        //send this true when you want BRE to consider obligation for FOIR calculation, this will be true as this is not comming from CIBIL
                            extLiab1.sourceOfInfo = zeroInteger;         //mandatory
                            extLiab1.trackCheckFrom = zeroInteger;       //mandatory
                            extLiab1.securityDetails = '';
                            extLiab1.endUseOfFunds = '';          //mandatory
                            extLiab1.repaymentFrom = '';          //mandatory
                            extLiab1.repaymentBankAccNo = '';
                            extLiab1.consideredRtrBasedLoan = null;
                            extLiab1.imputedEmi = '';
                            extLiab1.ownerShip = '';
                            extLiab1.last24Months = zeroInteger;
                            extLiab1.last6Months = zeroInteger;
                            extLiab1.last3Months = zeroInteger;
                            extLiab1.mob = zeroInteger;
                            extLiab1.remarks = '';
                            
                            externalLiabilitiesList.add(extLiab1);
                            liabilitySequence++;
                        }

                        appBankObj.externalLiabilities = externalLiabilitiesList;

                        applicantBankLst.add(appBankObj);
                    }
                }
                //bankingDetails

                appWrapper.bankingDetails = applicantBankLst;

                //cibil
                cls_cibil cibil = new cls_cibil();
                cibil.dateProcessed = '';
                cibil.timeProcessed = '';
                cibil.scoreName = '';
                cibil.scorecardName = '';
                cibil.scorecardVersion = '';
                cibil.score = '';
                cibil.memberReferenceNo = '';

                if(applicantTuffRes.containsKey(app.Id)){
                    String xmlResponse = applicantTuffRes.get(app.Id);
                    while(xmlResponse.contains('&')){     xmlResponse = xmlResponse.replace('&', '');    }
                    String JSONRes = XmlToJSONParser.XMLToJSON(xmlResponse);

                    TuffResponseWrapper.TuffResponse objRecords = (TuffResponseWrapper.TuffResponse)JSON.deserialize(JSONRes, TuffResponseWrapper.TuffResponse.class);
                    JSONRes = '';

                    if(app.Customer_Type__c == constants.get('CUSTOMER_TYPE_INDIVIDUAL')){
                        string dateProcess = objRecords.CreditReport.Header.DateProcessed;
                        if(dateProcess.length() == 8){
                            String day = dateProcess.substring(0,2);
                            String mon = dateProcess.substring(2,4);
                            String year = dateProcess.substring(4,8);
                            cibil.dateProcessed = day+'/'+mon+'/'+year;
                        }

                        string timeProcess = objRecords.CreditReport.Header.TimeProcessed;
                        if(timeProcess.length() == 6){
                            String day = timeProcess.substring(0,2);
                            String mon = timeProcess.substring(2,4);
                            String year = timeProcess.substring(4,6);
                            cibil.timeProcessed = day+':'+mon+':'+year;
                        }

                        cibil.memberReferenceNo = (objRecords.CreditReport.Header.MemberCode).trim();
                        cibil.scoreName = objRecords.CreditReport.ScoreSegment.ScoreName;
                        cibil.scorecardName = objRecords.CreditReport.ScoreSegment.ScoreCardName;
                        cibil.scorecardVersion = objRecords.CreditReport.ScoreSegment.ScoreCardVersion;
                        cibil.score = objRecords.CreditReport.ScoreSegment.Score;
                    }
                }

                cibil.liveCreditCardOutstanding = zeroDecimal;
                cibil.liveHlOrLapLoanAmount = zeroDecimal;
                cibil.liveAutoLoanAmount = zeroDecimal;
                cibil.live2WheelerLoanAmount = zeroDecimal;
                cibil.liveBlLoanAmount = zeroDecimal;
                cibil.livePlLoanAmount = zeroDecimal;
                cibil.noAccountsDeliquentL6m = zeroInteger;
                cibil.noAccounts30DpdL12m = zeroInteger;
                cibil.liveEducationLoanAmount = zeroDecimal;
                cibil.creditCardOverdueAmount = zeroDecimal;
                cibil.customerName = app.Name;
                cibil.panNumber = app.PAN_Number__c;
                cibil.noInquiryL3m = zeroInteger;
                cibil.plus30DpdL12m = zeroInteger;
                cibil.emiBounceL12m = zeroInteger;
                cibil.noInquiryL1m = zeroInteger;
                cibil.plus30PdpL6m = zeroInteger;
                cibil.recentLoans = zeroInteger;
                cibil.emiBouncesL3m = zeroInteger;
                cibil.emiBouncesL6m = zeroInteger;
                cibil.anyDpdL12m = zeroInteger;
                cibil.plus60DpdL3m = zeroInteger;
                cibil.derog = '';
                cibil.writeOffNonCredit = '';
                cibil.creditAmountOverdue = '';
                cibil.writeOffCredit = '';
                cibil.settle = '';
                cibil.restructured = '';
                cibil.writeOff = '';
                cibil.executionResponse = '';
                cibil.emiBounceL3m = zeroInteger;
                cibil.liveCreditCardEmi = zeroDecimal;
                cibil.liveHlOrLapLoanEmi = zeroDecimal;
                cibil.live2WheelerLoanEmi = zeroDecimal;
                cibil.liveAutoLoanEmi = zeroDecimal;
                cibil.liveBusinessLoanEmi = zeroDecimal;
                cibil.livePersonalLoanEmi = zeroDecimal;
                cibil.liveEducationLoanEmi = zeroDecimal;
                cibil.liveConsumerLoan = zeroDecimal;
                cibil.liveConsumerLoanEmi = zeroDecimal;
                cibil.liveCommercialVehicleLoan = zeroDecimal;
                cibil.liveCommercialVehicleLoanEmi = zeroDecimal;
                cibil.liveUsedCardLoan = zeroDecimal;
                cibil.liveUsedCardLoanEmi = zeroDecimal;
                cibil.liveSecuredCardOutstanding = zeroDecimal;
                cibil.liveSecuredAndEmi = zeroDecimal;
                cibil.liveLoanOnCreditCard = zeroDecimal;
                cibil.liveLoanOnCreditCardEmi = zeroDecimal;
                //cibil

                appAddDetails.cibil = cibil;

                //additionalDetail
                cls_additionalDetail additionalDetail = new cls_additionalDetail();
                additionalDetail.purposeOfLoanOthers = purposeOfLoanFICO;
                additionalDetail.netBonus = zeroDecimal;

                decimal netAnnual = 0;
                if(appIncomeDeductionMap.containsKey(app.Id)){
                    integer recordCount = appIncomeDeductionMap.get(app.Id).size();
                    decimal earning = recordCount >0 ? appIncomeDeductionMap.get(app.Id)[0] : 0;
                    decimal deduction = recordCount >1 ? appIncomeDeductionMap.get(app.Id)[1] : 0;
                    netAnnual = earning - deduction;
                }

                if(isFromCalculator) {
                    additionalDetail.netAnnual = (grossSalary - totalDeductions) * 12;
                }else{
                    additionalDetail.netAnnual = netAnnual;
                }

                additionalDetail.buffer1 = '';
                additionalDetail.buffer2 = '';
                additionalDetail.buffer3 = '';
                additionalDetail.buffer4 = '';

                Decimal primaryAppOdCCLimit = 0;
                Map<String,Decimal> bankWiseCCLimit = new Map<String,Decimal>();
                if(applicantWiseBsaMap.containsKey(primaryAppId)){
                    for(Bank_Statement_Analysis__c itenBS : applicantWiseBsaMap.get(primaryAppId)) {
                        if(itenBS.Bank_Details__r.Account_Type__c == 'Overdraft' && itenBS.Sanction_Limit__c != null && !bankWiseCCLimit.containsKey(itenBS.Bank_Details__c)) {
                            bankWiseCCLimit.put(itenBS.Bank_Details__c, itenBS.Sanction_Limit__c);
                        }
                    }
                }

                if(!bankWiseCCLimit.isEmpty()) {
                    for(String bakId : bankWiseCCLimit.keyset()) {
                        primaryAppOdCCLimit = primaryAppOdCCLimit + bankWiseCCLimit.get(bakId);
                    }
                }

                additionalDetail.buffer5 = String.valueOf(primaryAppOdCCLimit);
                //additionalDetail

                appAddDetails.additionalDetail = additionalDetail;

                //digitalData
                cls_digitalData digitalData = new cls_digitalData();
                digitalData.perfiosIncome = '';
                digitalData.perfiosObligation = '';
                digitalData.bureauObligation = '';
                //digitalData

                appAddDetails.digitalData = digitalData;
                appAddDetails.GROWPER = '';
                appAddDetails.buffer3 = '';
                appAddDetails.buffer4 = '';
                appAddDetails.buffer5 = '';
                appAddDetails.buffer6 = '';
                appAddDetails.buffer7 = '';
                appAddDetails.buffer8 = '';
                appAddDetails.buffer9 = '';
                appAddDetails.buffer10 = '';
                appAddDetails.buffer11 = '';
                appAddDetails.buffer12 = '';
                appAddDetails.buffer13 = '';
                appAddDetails.buffer14 = '';
                appAddDetails.buffer15 = replacedOutputStr(app.Borrower_Profile__c);
                appAddDetails.buffer16 = '';
                appAddDetails.buffer17 = '';
                appAddDetails.buffer18 = '';
                appAddDetails.buffer19 = '';
                appAddDetails.buffer20 = '';

                appWrapper.applicantAdditionalDetails = appAddDetails;

                applicantsData.add(appWrapper);
            }
        }

        applicationWrap.applicants = applicantsData;

        //cls_loanBasicDetail
        cls_loanBasicDetail loanBasicDetails = new cls_loanBasicDetail();

        loanBasicDetails.loanReference = loanObj.Name;
        loanBasicDetails.loanType = '';     //mandatory     FICO Code

        if(masterCodeMap.containsKey('Sub product')){
            for(PLF_Master__c iter : masterCodeMap.get('Sub product')) {
                if(iter.description__c == prodObj.Variant__r.Name){
                    loanBasicDetails.loanType = replacedOutputStr(iter.FICO_Code__c);      //mandatory     FICO Code
                    break;
                }
            }
        }

        loanBasicDetails.division = 'RETAIL';
        loanBasicDetails.businessVertical ='';
        loanBasicDetails.productCategory = 'CONV';
        loanBasicDetails.interestDaysBasis = constants.get('Interest_Day_Basis');        //mandatory
        loanBasicDetails.applicationNo = loanObj.Name;
        loanBasicDetails.leadId = '';

        //sourcingDetails
        cls_sourcingDetails sourcingDetails = new cls_sourcingDetails();
        Decimal sumOfTotalInwCheqReturn = 0;
        Decimal sumOfTotalBusinessDebits = 0;
        Decimal sumOfTotalOwReturn = 0;
        Decimal sumOfTotalBusinessCredits = 0;
        Decimal minimunCreditTxn = 0;

        for(Bank_Statement_Analysis__c iterBsa : bsaLSt) {
            sumOfTotalInwCheqReturn = sumOfTotalInwCheqReturn + iterBsa.Total_number_of_inward_Cheque_return__c;
            sumOfTotalBusinessDebits = sumOfTotalBusinessDebits + iterBsa.Total_Number_of_Business_Debits__c;

            if(iterBsa.Total_number_of_out_bounce__c != null) {
                sumOfTotalOwReturn = sumOfTotalOwReturn + iterBsa.Total_number_of_out_bounce__c;
            }

            sumOfTotalBusinessCredits = sumOfTotalBusinessCredits + iterBsa.Total_Number_of_Business_Credits__c;
        }

        if(consolidatedBsarec != null) {
            sourcingDetails.sourcingBranch = consolidatedBsarec.I_w_returns_as_of_total_debits_Manual__c != null ? String.valueOf(consolidatedBsarec.I_w_returns_as_of_total_debits_Manual__c) : String.valueOf(consolidatedBsarec.I_w_returns_as_of_total_debits__c);
            sourcingDetails.sourcingChannelCategory = consolidatedBsarec.O_w_returns_as_of_total_credits_manual__c != null ? String.valueOf(consolidatedBsarec.O_w_returns_as_of_total_credits_manual__c) : String.valueOf(consolidatedBsarec.O_w_returns_as_of_total_credits__c);
            sourcingDetails.sourcingOfficer = constants.get('Zero');
            sourcingDetails.buffer1 = constants.get('Zero');
            sourcingDetails.salesDepartment = constants.get('Zero_Decimal');
            sourcingDetails.buffer2 = constants.get('Zero_Decimal');
        }
        else {
            sourcingDetails.sourcingBranch = '';
            if(sumOfTotalBusinessDebits != 0) {
                sourcingDetails.sourcingBranch = String.valueOf((sumOfTotalInwCheqReturn/sumOfTotalBusinessDebits).setscale(2));
            }

            sourcingDetails.sourcingChannelCategory = '';
            if(sumOfTotalBusinessCredits != 0) {
                sourcingDetails.sourcingChannelCategory = String.valueOf((sumOfTotalOwReturn/sumOfTotalBusinessCredits).setscale(2));
            }

            sourcingDetails.sourcingOfficer = constants.get('Zero');
            sourcingDetails.buffer1 = constants.get('Zero');
            sourcingDetails.salesDepartment = constants.get('Zero_Decimal');
            sourcingDetails.buffer2 = constants.get('Zero_Decimal');
        }

        sourcingDetails.loanBranch = replacedOutputStr(loanObj.Branch_Master__r.Branch_Code__c);        //mandatory
        sourcingDetails.purposeOfLoan = replacedOutputStr(purposeOfLoanFICO);      //mandatory     FICO Code
        sourcingDetails.directSalesAgent = '';
        sourcingDetails.refferalId = '';
        sourcingDetails.dmaCode = '';
        sourcingDetails.asmName = String.valueOf(shareholdingKey); // field to be added
        sourcingDetails.employeeName = '';
        sourcingDetails.buffer3 = '';
        sourcingDetails.buffer4 = String.valueOf(cibilScore);
        //sourcingDetails

        loanBasicDetails.sourcingDetails = sourcingDetails;

        //keyDetails
        cls_keyDetails keyDetails = new cls_keyDetails();
        keyDetails.loanStartDate = formattedLoanDate;          //mandatory
        keyDetails.applicationRequestDate = formattedLoanDate;
        keyDetails.firstDisbursementAmount = zeroDecimal;    //mandatory
        keyDetails.netLoanAmount = replacedOutputDecimal(parentLoanAmount);     //mandatory
        keyDetails.loanAmount = finalLoanAmount;        //mandatory
        keyDetails.totalDisbursements = zeroDecimal;
        keyDetails.tdsApplicable = null;
        keyDetails.allowGrace = null;
        keyDetails.stepLoan = null;
        keyDetails.eligibilityMethod = '';
        keyDetails.allowOCR = null;
        keyDetails.allowLoanSplit = null;
        keyDetails.parentLoanReference = '';
        //keyDetails

        loanBasicDetails.keyDetails = keyDetails;

        //paymentDetails
        cls_paymentDetails paymentDetails = new cls_paymentDetails();
        paymentDetails.numberOfInstallments = tenor;    //Integer.valueOf(fullEmiProd.Name);
        paymentDetails.paymentAmount = zeroDecimal;
        paymentDetails.interestRateType = '';
        paymentDetails.allowBPI = false;
        paymentDetails.bpiTreatment = 'No BPI';       //mandatory
        paymentDetails.baseRate = roi;
        paymentDetails.fixedRate = zeroDecimal;        //mandatory
        paymentDetails.actualInterestRate = zeroDecimal;       //mandatory
        paymentDetails.minInterestRate = zeroDecimal;      //mandatory
        paymentDetails.maxInterestRate = zeroDecimal;      //mandatory
        paymentDetails.scheduleMethod = 'EQUAL';         //mandatory
        paymentDetails.interestFrequency = 'M0003';      //mandatory
        paymentDetails.interestReviewFrequency = 'M0003';    //mandatory
        paymentDetails.paymentFrequency = '0';        //mandatory
        paymentDetails.nextInterestFreqDate = formattedCurrentDate;   //mandatory
        paymentDetails.nextInterestReviewFreqDate = formattedCurrentDate;     //mandatory
        paymentDetails.nextPaymentFreqDate = formattedCurrentDate;        //mandatory
        paymentDetails.allowPlannedEMIHoliday = null;
        paymentDetails.allowPlannedEMIHolidayGrace = null;
        paymentDetails.unplannedEMIHolidayLockPeriod = zeroInteger;
        paymentDetails.maxUnplannedEMIHolidays = zeroInteger;
        paymentDetails.maturityDate = maturityDate;
        //paymentDetails

        loanBasicDetails.paymentDetails = paymentDetails;

        applicationWrap.loanBasicDetail = loanBasicDetails;

        //cls_verifications
        cls_verifications verificationWrap = new cls_verifications();

        List<cls_fiInitiation> fiLst = new List<cls_fiInitiation>();
        List<cls_rcuInitiation> clsRcuInitLst = new List<cls_rcuInitiation>();
        List<cls_pdInitiation> clsPdInitLst = new List<cls_pdInitiation>();

        for(Application_Verification__c av : appVerList){
            if(av.RecordType.Name == 'Business Verification' || av.RecordType.Name == 'Collateral Verification' || av.RecordType.Name == 'Residence Verification'){
                if(av.Stage__c != 'Waived'){
                    string customerCIF = av.Applicant__r.Customer__r?.SF_Customer_ID__c.split('-')[1];

                    cls_fiInitiation fiInit = new cls_fiInitiation();
                    fiInit.applicantType = replacedOutputStr(av.Applicant__r.Applicant_Type__c);       //mandatory
                    fiInit.cif = replacedOutputStr(customerCIF);     //mandatory
                    fiInit.name = replacedOutputStr(av.Applicant__r.Name);    //mandatory
                    fiInit.addressType = replacedOutputStr(av.Address_Type__c);     //mandatory
                    fiInit.fiv = replacedOutputStr(av.Stage__c);       //mandatory
                    fiInit.agency = replacedOutputStr(av.Vendor__r.Name);      //mandatory
                    fiInit.reason = constants.get('Zero');
                    fiInit.remark = replacedOutputStr(av.Verification_Remarks__c);      //mandatory
                    fiInit.lastVerficationAgency = '';
                    fiInit.lastStatus = '';
                    fiInit.lastVerificationDate = '';

                    fiLst.add(fiInit);
                }
            }
            else if(av.RecordType.Name == 'FCU'){
                cls_rcuInitiation rcuInit = new cls_rcuInitiation();
                rcuInit.documentType = constants.get('Zero');       //mandatory
                rcuInit.rcu = zeroInteger;          //mandatory
                rcuInit.bankName = '';      //replacedOutputStr(av.Banking_Details__c);       //mandatory
                rcuInit.bankAccountNumber = zeroInteger;      //mandatory
                rcuInit.agency = replacedOutputStr(av.Vendor__r.Name);     //mandatory
                rcuInit.reason = constants.get('Zero');
                rcuInit.remark = replacedOutputStr(av.IsParent__c ? av.Verification_Remarks__c : av.Parent_FCU__r?.Verification_Remarks__c);     //mandatory
                rcuInit.lastVerficationAgency = '';
                rcuInit.lastStatus = '';
                rcuInit.lastVerificationDate = '';

                clsRcuInitLst.add(rcuInit);
            }
            else if(av.RecordType.Name == 'Personal Discussion AHL'){
                cls_pdInitiation pdInit = new cls_pdInitiation();
                pdInit.applicantType = replacedOutputStr(av.Applicant__r.Applicant_Type__c);       //mandatory
                pdInit.cif = replacedOutputStr(av.Applicant__r.Customer__r.SF_Customer_ID__c);     //mandatory
                pdInit.name = replacedOutputStr(av.Applicant__r.Name);        //mandatory
                pdInit.addressType = replacedOutputStr(av.Type_of_Address__c);     //mandatory
                pdInit.pdv = zeroInteger;       //mandatory
                pdInit.agency = '';      //mandatory
                pdInit.reason = zeroInteger;
                pdInit.remark = '';
                pdInit.lastVerficationAgency = '';
                pdInit.lastStatus = '';
                pdInit.lastVerificationDate = '';

                clsPdInitLst.add(pdInit);
            }
        }
        
        verificationWrap.fiInitiation = fiLst;
        verificationWrap.rcuInitiation = clsRcuInitLst;
        verificationWrap.pdInitiation = clsPdInitLst;

        //tvInitiation
        cls_tvInitiation tvInit = new cls_tvInitiation();
        tvInit.collatarelType = !techList.isEmpty() ? techList[0].HL_Application_Collateral__r?.Asset_Type__c : '';      //mandatory     later they confirmed can send empty
        tvInit.depositCif = replacedOutputStr(primaryAppCustomerCIF);          //mandatory
        tvInit.depositName = replacedOutputStr(primaryAppName);         //mandatory
        tvInit.tv = zeroInteger;        //mandatory
        tvInit.verificationCategory = zeroInteger;      //mandatory
        tvInit.agency = !techList.isEmpty() ? techList[0].HL_Vendor_Agency__r.Name : '';      //mandatory
        tvInit.reason = zeroInteger;
        tvInit.remark = !techList.isEmpty() ? ((techList[0].HL_Application_Collateral__r.Collateral__r.Remarks__c != null && techList[0].HL_Application_Collateral__r.Collateral__r.Remarks__c.length() > 255) ? techList[0].HL_Application_Collateral__r.Collateral__r.Remarks__c.substring(0, 255) : replacedOutputStr(techList[0].HL_Application_Collateral__r.Collateral__r.Remarks__c)) : '';      //mandatory
        tvInit.lastVerficationAgency = '';
        tvInit.lastStatus = '';
        tvInit.lastVerificationDate = '';
        //tvInitiation

        verificationWrap.tvInitiation = tvInit;

        //lvInitiation
        cls_lvInitiation lvInit = new cls_lvInitiation();
        lvInit.collatarel = !legalList.isEmpty() ? legalList[0].Application_Collateral__r.Name : '';          //mandatory
        lvInit.agency = !legalList.isEmpty() ? legalList[0].Vendor_Agency__r.Name : '';              //mandatory
        lvInit.remark = '';
        lvInit.decision = !legalList.isEmpty() ? legalList[0].Report_Status__c : '';            //mandatory
        lvInit.status = !legalList.isEmpty() ? legalList[0].Stage__c : '';              //mandatory
        lvInit.verificationdate = !legalList.isEmpty() ? legalList[0].CreatedDate.toString() : '';    //mandatory
        verificationWrap.lvInitiation = lvInit;
        //lvInitiation

        //lvWaiver
        cls_lvWaiver lvWaiver = new cls_lvWaiver();
        lvWaiver.collatarel = '';        //mandatory
        lvWaiver.documentType = constants.get('Zero');      //mandatory
        lvWaiver.reason = zeroInteger;
        lvWaiver.remark = '';
        lvWaiver.verificationdate = '';
        lvWaiver.decision = '';
        lvWaiver.status = constants.get('Zero');        //mandatory
        //lvWaiver

        verificationWrap.lvWaiver = lvWaiver;

        applicationWrap.verifications = verificationWrap;

        //schedule
        cls_schedule schedule = new cls_schedule();
        schedule.loanType = replacedOutputStr(loanBasicDetails.loanType);      //mandatory
        schedule.loanReference = '';     //mandatory
        schedule.firstdisbursementdate = formattedCurrentDate;     //mandatory
        schedule.currencyRemove = 'INR';        //mandatory
        schedule.maturityDate = maturityDate;      //mandatory
        schedule.loanAmount = replacedOutputDecimal(subProduct.Requested_Loan_Amount__c);      //mandatory
        schedule.emitenure = zeroInteger;       //mandatory
        schedule.emiamount = Integer.valueOf(emis);       //mandatory

        if(isFromCalculator){
            schedule.emiamount = totalObligation;
        }
        
        schedule.installmentroi = zeroInteger;       //mandatory
        schedule.preemiapplicableornot = null;
        schedule.preamitenure = zeroInteger;       //mandatory
        schedule.preemiamount = zeroInteger;
        schedule.moratoriumappliableornot = null;
        schedule.moratoriumtenure = zeroInteger;
        schedule.graceperiodroi = Integer.valueOf(graceperiodroi);
        schedule.emiholidayepplicableornot = null;
        //schedule

        applicationWrap.schedule = schedule;

        //ocrdetails
        cls_ocrdetails ocrDetails = new cls_ocrdetails();
        ocrDetails.ocrapplicableornot = null;
        ocrDetails.parentloanreferencenumber = '';
        ocrDetails.ocrid = '';
        ocrDetails.ocrdescription = productType;
        ocrDetails.customerportionpercentage = zeroInteger;     //mandatory
        ocrDetails.ocrtype = '';         //mandatory
        ocrDetails.totaldemand = zeroInteger;       //mandatory
        ocrDetails.totalocrreceivable = zeroInteger;        //mandatory
        //ocrdetails

        applicationWrap.ocrdetails = ocrDetails;

        //step
        cls_step clsStep = new cls_step();
        clsStep.stepapplicableornot = null;
        //step

        applicationWrap.step = clsStep;

        cls_coAppAndGuarantors coAppAndGuranWrap = new cls_coAppAndGuarantors();

        //coApplicantDetails
        cls_coApplicantDetails coApplicant = new cls_coApplicantDetails();
        coApplicant.customerCif = '';        //mandatory
        coApplicant.customerName = '';       //mandatory
        coApplicant.authoritySignatory = null;
        coApplicant.exposureSolePrimary = zeroInteger;
        coApplicant.exposureCoapplicant = zeroInteger;
        coApplicant.status = '';
        coApplicant.worstStatus = '';
        //coApplicantDetails

        coAppAndGuranWrap.coApplicantDetails = coApplicant;

        //guarantorsDetails
        cls_guarantorsDetails guarantor = new cls_guarantorsDetails();
        guarantor.id = '';       //mandatory
        guarantor.guarantorsName = '';       //mandatory
        guarantor.idType = '';       //mandatory
        guarantor.gurantee = zeroInteger;   //mandatory
        guarantor.exposureSolePrimary = zeroInteger;
        guarantor.exposureCoapplicant = zeroInteger;
        guarantor.exposureGuarantor = zeroInteger;
        guarantor.status = '';
        guarantor.worstStatus = '';
        guarantor.contactNumber = '';
        guarantor.idProof = '';      //mandatory
        //guarantorsDetails

        coAppAndGuranWrap.guarantorsDetails = guarantor;

        applicationWrap.coAppAndGuarantors = coAppAndGuranWrap;

        //cls_applicationAdditionalDetails
        cls_applicationAdditionalDetails applicationAddiDetails = new cls_applicationAdditionalDetails();
        applicationAddiDetails.selfEmployedRiskScore = zeroInteger;
        applicationAddiDetails.selfEmployedRiskSegment = zeroInteger;
        applicationAddiDetails.hunterStatus = '';
        applicationAddiDetails.lanHunterStatus = '';
        applicationAddiDetails.hunterRcuStatus = '';
        applicationAddiDetails.hunterRemark = '';
        applicationAddiDetails.remark1 = '';
        applicationAddiDetails.buffer1 = '';
        applicationAddiDetails.buffer2 = '';
        applicationAddiDetails.buffer3 = '';
        applicationAddiDetails.buffer4 = '';
        applicationAddiDetails.buffer5 = '';
        applicationAddiDetails.buffer6 = '';
        applicationAddiDetails.buffer7 = '';
        applicationAddiDetails.buffer8 = '';
        applicationAddiDetails.buffer9 = '';
        applicationAddiDetails.buffer10 = '';

        //referenceDetails
        cls_referenceDetails referenceWrap = new cls_referenceDetails();
        referenceWrap.givenGuaranteeToLoan = null;

        //reference1
        cls_reference reference = new cls_reference();
        reference.firstName = loanObj.Reference_Name_1__c;
        reference.lastName = loanObj.Reference_Last_Name_1__c;
        reference.address = loanObj.Reference_Address_1__c;
        reference.city = '';
        reference.mobileNo = loanObj.Reference_Phone_1__c;
        reference.state = '';
        reference.pincode = loanObj.Reference_Details_Pincode_1__r.Name;
        reference.relationshipWithApplicant = '';
        //reference1

        referenceWrap.reference1 = reference;

        //reference2
        cls_reference reference2 = new cls_reference();
        reference2.firstName = loanObj.Reference_Name_2__c;
        reference2.lastName = loanObj.Reference_Last_Name_2__c;
        reference2.address = loanObj.Reference_Address_2__c;
        reference2.city = '';
        reference2.mobileNo = loanObj.Reference_Phone_2__c;
        reference2.state = '';
        reference2.pincode = loanObj.Reference_Details_Pincode_2__r.Name;
        reference2.relationshipWithApplicant = '';
        //reference2

        referenceWrap.reference2 = reference2;
        //referenceDetails

        applicationAddiDetails.referenceDetails = referenceWrap;

        //finalOffer
        cls_finalOffer finalOffer = new cls_finalOffer();
        finalOffer.additionalLtv = '';
        finalOffer.LOANAMTOFFR = '';
        finalOffer.ROINTR = '';
        finalOffer.LOANTENU = '';
        finalOffer.MAXLOELIGINC = '';
        finalOffer.MAXLOELIGLTV = '';
        finalOffer.MAXLTV = '';
        finalOffer.EMIFINOFF = '';
        finalOffer.FINALFOIR = '';
        finalOffer.FINALLTV = '';
        //finalOffer

        applicationAddiDetails.finalOffer = finalOffer;

        //sourcingDetail
        cls_sourcingDetail sourcingDetail = new cls_sourcingDetail();
        sourcingDetail.channelPartnerCode = '';
        sourcingDetail.ghfRm = '';
        sourcingDetail.ghfAsm = '';
        sourcingDetail.refCode1 = '';
        sourcingDetail.refCode2 = '';
        sourcingDetail.refCode3 = '';
        sourcingDetail.refCode4 = '';
        sourcingDetail.refCode5 = '';
        sourcingDetail.refCode6 = '';
        sourcingDetail.schemeCode = '';
        sourcingDetail.employeeCode = '';
        //sourcingDetail

        applicationAddiDetails.sourcingDetail = sourcingDetail;

        //other
        cls_other other = new cls_other();
        other.psl = '';
        other.pep = '';
        other.borrowerType = '';
        other.lendingType = '';
        other.propertyIdentified = '';
        other.riskCategorization = '';
        other.cinNo = '';
        other.finalFoirPercentage = zeroInteger;
        other.finalLtvPercentage = zeroInteger;
        other.finalLoanAmount = zeroInteger;
        other.eligibilityMethod = '';
        other.sblMet = '';
        other.gblMet = '';
        other.stageOfConstruction = '';
        other.creExposure = null;
        other.rentalIncomeProgram = '';
        other.buffer1 = '';
        other.buffer2 = '';
        other.buffer3 = '';
        other.buffer4 = '';
        other.buffer5 = constants.get('Zero');
        other.buffer6 = '';
        other.buffer7 = '';
        other.buffer8 = '';
        other.buffer9 = '';
        other.buffer10 = '';
        other.buffer11 = replacedOutputStr(constructionStageFICO);        //Mandatory      construction status(Ready Possession, Under Construction)
        other.buffer12 = '';
        other.buffer13 = '';
        other.buffer14 = '';
        other.buffer15 = '';
        other.buffer16 = '';
        other.buffer17 = '';
        other.buffer18 = '';
        other.buffer19 = '';
        other.buffer20 = '';
        other.buffer21 = '';
        other.buffer22 = '';
        other.buffer23 = '';
        other.buffer24 = '';
        other.buffer25 = '';
        //other

        applicationAddiDetails.other = other;

        //balanceTransfer
        cls_balanceTransfer balanceTransfer = new cls_balanceTransfer();
        balanceTransfer.nameOfFinancialInstitute = '';
        balanceTransfer.nameOfOtherFinancialInst = '';
        balanceTransfer.moratoriumSchemeFlagging = null;
        balanceTransfer.btLoanLanNo = zeroDecimal;
        balanceTransfer.btOutstanding = zeroDecimal;
        balanceTransfer.btMob = zeroInteger;
        balanceTransfer.topUpLanNo = '';
        balanceTransfer.topUpAmount = zeroInteger;
        balanceTransfer.consolidatedLtv = '';
        balanceTransfer.currentOccupancyOfProperty = '';
        balanceTransfer.endUseForTopUp = '';
        balanceTransfer.specifyOtherEndUse = '';
        //balanceTransfer

        applicationAddiDetails.balanceTransfer = balanceTransfer;

        applicationWrap.applicationAdditionalDetails = applicationAddiDetails;

        //collateral
        cls_collateral collateral = new cls_collateral();

        //property
        Integer finalMarketValue = 0;
        List<cls_property> propertyList = new List<cls_property>();

        if(collList.isEmpty()){
            cls_property property = new cls_property();
            property.collateralType = '';        //mandatory
            property.collateralUsage = '';
            property.collateralReference = '';
            property.markertValue = zeroInteger;
            property.propertyType = '';
            property.constructionType = replacedOutputStr(constructionStageFICO);      //mandatory
            property.projectName = '';
            property.developerName = '';     //mnadatory
            property.documentedValue = zeroInteger;

            if(isFromCalculator){
                property.documentedValue = docmarketVal;
            }

            property.carpetArea = zeroInteger;
            property.buffer1 = '';
            property.buffer2 = '';
            property.buffer3 = '';
            property.buffer4 = '';
            property.buffer5 = '';

            propertyList.add(property);
        }
        else{
            for(Application_Collateral__c rec : collList){
                cls_property property = new cls_property();
                
                property.collateralReference = '';
                property.constructionType = replacedOutputStr(constructionStageFICO);      //mandatory
                property.projectName = '';
                property.collateralType = replacedOutputStr(rec.Collateral__r.Collateral_Type__c);        //mandatory
                property.markertValue = rec.Collateral__r.Market_Value__c != null ? Integer.valueOf(rec.Collateral__r.Market_Value__c) : zeroInteger;
                property.propertyType = replacedOutputStr(rec.Collateral__r.Unit_Property_Type__c);
                property.documentedValue = rec.Collateral__r.Agreement_Value__c != null ? Integer.valueOf(rec.Collateral__r.Agreement_Value__c) : zeroInteger;
                property.developerName = replacedOutputStr(rec.Collateral__r.Builder__r?.Name);     //mnadatory
                property.collateralUsage = replacedOutputStr(rec.Collateral__r.Current_Usage__c);      //mandatory

                if(isFromCalculator){
                    property.documentedValue = docmarketVal;
                }

                property.carpetArea = zeroInteger;
                property.buffer1 = '';
                property.buffer2 = '';
                property.buffer3 = '';
                property.buffer4 = '';
                property.buffer5 = '';

                propertyList.add(property);

                finalMarketValue += rec.Collateral__r.Market_Value__c != null ? Integer.valueOf(rec.Collateral__r.Market_Value__c) : zeroInteger;
            }
        }
        //property

        collateral.property = propertyList;

        applicationWrap.collateral = collateral;

        //score
        cls_score score = new cls_score();
        score.appScoreRequired = '';
        score.experianScoreRequired = '';
        score.experianScoreType = '';
        //score

        applicationWrap.score = score;

        //tvApproval
        cls_tvApproval tvApproval = new cls_tvApproval();

        //finalValuationAmount
        cls_finalValuationAmount finalValuationAmount = new cls_finalValuationAmount();
        finalValuationAmount.collateralReference = '';
        finalValuationAmount.finalValAmount = finalMarketValue;
        //finalValuationAmount

        tvApproval.finalValuationAmount = finalValuationAmount;
        //tvApproval

        applicationWrap.tvApproval = tvApproval;

        requestWrap.application = applicationWrap;
        mainWrap.request = requestWrap;

        //response
        cls_response responseWrap = new cls_response();
        responseWrap.systemDecision = '';
        responseWrap.systemDecisionDate = '';
        responseWrap.systemDecisionDateTime = '';
        responseWrap.strategyUsed = '';
        responseWrap.finalApprovalLevel = '';
        responseWrap.scoreDecision = '';

        //calculatedVariables
        cls_calculatedVariables calculatedVariables = new cls_calculatedVariables();
        calculatedVariables.fieldName = '';
        calculatedVariables.fieldType = '';
        calculatedVariables.fieldValue = '';
        calculatedVariables.productCode = '';
        calculatedVariables.entityId = '';
        calculatedVariables.entityType = '';
        calculatedVariables.purpose = '';
        //calculatedVariables

        responseWrap.calculatedVariables = calculatedVariables;

        //errorResponse
        cls_errorResponse errorResponse = new cls_errorResponse();
        errorResponse.errorType = '';
        errorResponse.errorId = '';
        errorResponse.errorName = '';
        errorResponse.errorAction = '';
        errorResponse.errorCode = '';
        errorResponse.errorText = '';
        //errorResponse

        responseWrap.errorResponse = errorResponse;

        //responseDeviations
        cls_responseDeviations responseDeviations = new cls_responseDeviations();
        responseDeviations.ruleId = '';
        responseDeviations.ruleName = '';
        responseDeviations.ruleDescription = '';
        responseDeviations.ruleAction = '';
        responseDeviations.ruleCategory = '';
        responseDeviations.reasonText = '';
        responseDeviations.approvalLevel = '';
        responseDeviations.deviationType = '';
        responseDeviations.ruleLevel = '';
        responseDeviations.entityId = '';
        responseDeviations.entityType = '';
        responseDeviations.accountNo = '';
        responseDeviations.recommendationText = '';
        //responseDeviations

        responseWrap.responseDeviations = responseDeviations;

        //scoreCardDetails
        cls_scoreCardDetails scroreCard = new cls_scoreCardDetails();
        scroreCard.scorecardName = '';
        scroreCard.scorecardScore = '0';
        scroreCard.characteristicCount = '0';
        scroreCard.scorecardKey = '';
        scroreCard.purpose = '';
        scroreCard.entityId = '';
        scroreCard.entityType = '';

        //scoreCardCharacteristics
        cls_scoreCardCharacteristics scoreCardCharacteristics = new cls_scoreCardCharacteristics();
        scoreCardCharacteristics.characteristicName = '';
        scoreCardCharacteristics.characteristicValue = '';
        scoreCardCharacteristics.partialScore = '';
        //scoreCardCharacteristics

        scroreCard.scoreCardCharacteristics = scoreCardCharacteristics;
        //scoreCardDetails

        responseWrap.scoreCardDetails = scroreCard;
        mainWrap.response = responseWrap;

        cls_invocation invocation = new cls_invocation();
        invocation.version = ''; //
        invocation.applicationNumber = loanObj.Name; // #LAN
        invocation.applicationDate = formattedLoanDate; // 2025-10-12+00:00
        invocation.decisionPointAction = 'BUTTON'; // BUTTON
        invocation.decisionPoint = isIncomeFromSales ? 'QS' : 'HL_CREDIT';      // #DECISION_POINT
        invocation.decisionService = 'HL'; // #DECISION_SERVICE
        invocation.serviceexecute = 'FICO';
        invocation.responseStatus = ''; //

        mainWrap.invocation = invocation;
        outerWrap.message = mainWrap;
        String requestJSON = JSON.serialize(outerWrap);
        return requestJSON;
    }

    private static String replacedOutputStr(String val){
        return val == null ? '' : val;
    }

    private static Decimal replacedOutputDecimal(Decimal val){
        return val == null ? 0 : val;
    }

    public cls_message message;

    public class cls_message {
        public cls_request request;
        public cls_response response;
        public cls_invocation invocation;
    }

    public class cls_request {
        public cls_application application;
    }

    public class cls_application {
        public String source;	//GHF
        public String entity;	//PLF
        public String pdDoneBy;
        public cls_applicants[] applicants;
        public cls_loanBasicDetail loanBasicDetail;
        public cls_verifications verifications;
        public cls_schedule schedule;
        public cls_ocrdetails ocrdetails;
        public cls_step step;
        public cls_coAppAndGuarantors coAppAndGuarantors;
        public cls_applicationAdditionalDetails applicationAdditionalDetails;
        public cls_collateral collateral;
        public cls_score score;
        public cls_tvApproval tvApproval;
    }

    public class cls_applicants {
        public String creditBureauReports;	//#CoApp_CreaditReport     //Will pass TuffResponse -> CibilBureauResponse -> BureauResponseRaw -> BureauResponseXml -> CreditReport from the CIBIL response of the main applicant as confirmed by Gayatri  -> confirmed
        public string customerCif;	//#Main_CIF
        public String applicantType;	//MainApp
        public String customerCategory;	//#Main_Category
        public String panNumber;	//#Main_PAN
        public String dateOfBirth;	//#Main_DOB
        public String dateOfIncorporation;	//#Main_DOI
        public Integer numOfDependents;
        public String employmentType;	//#employmentType
        public String addressOwnershipType;	//#Main_AddressOwnership
        public String maritalStatus;
        public String companyCategory;
        public String qualification;	//#qualification
        public String natureOfBusiness;
        public String residentialStatus;
        public String segment;	//#Main_Segment
        public String sector;	//#Main_Sector
        public String subSegment;
        public String subSector;	//#Main_SubSector
        public String customerBranch;
        public String dsaCode;
        public String caste;
        public cls_kycDetails kycDetails;
        public cls_bankingDetails[] bankingDetails;
        public cls_applicantAdditionalDetails applicantAdditionalDetails;
        public String posidex;
        // public String sourcingOfficer;
        // public String buffer1;	//#KeyPerson
    }

    public class cls_kycDetails {
        public cls_customerIds[] customerIds;
        public cls_addressDetails[] addressDetails;
        // public cls_employmentDetails employmentDetails;
        public cls_phoneDetails phoneDetails;
        public cls_emailDetails emailDetails;
    }

    public class cls_customerIds {
        public String customerCif;
        public String idType;
        public String documentName;
        public String idNumber;
        public String issuedCountry;
        public String issuedOn;
        public String expiryDate;
        public String remarks;
    }

    public class cls_addressDetails {
        public String addressType;
        public String landmark;
        public String locality;
        public String city;
        public String pinCode;	//#PinCode
        public Integer priority;	//#PinPriority
        public Boolean pinCodeServicability;	//#Pinservicability
    }

    public class cls_phoneDetails {
        public String customerCif;
        public String phoneTypeCode;
        public String phoneNumber;
        public String priority;
    }

    public class cls_emailDetails {
        public String customerCif;
        public String emailType;
        public String email;
        public String priority;
    }

    public class cls_bankingDetails {
        public String customerCif;
        public Boolean addToBeneficiary;
        public String accHolderName;
        public String bankName;
        public String bankBranch;
        public String accountType;	//#Account_Type
        public String accountNo;	//#Account_Number
        public Boolean salaryAccount;
        public String accountOpenDate;
        public String repaymentFrom;
        public String phoneNumber;
        public Integer numOfMonthsBanking;
        public Integer ccLimit;	//#ccLimit
        public String typeOfBanks;
        public String documentName;	//#docName
        public String iwOwRatio;	//#Main_IwOwRatio
        public String monthAndYearDayBalance;
        public cls_accountBehaviourDetails accountBehaviourDetails;
        public List<cls_externalLiabilities> externalLiabilities;
    }

    public class cls_accountBehaviourDetails {
        public String customerCif;
        public Integer chequeSequence;
        public String monthAndYear;
        public Integer paymentCheques;
        public Integer salaryOrIncome;
        public Integer debits;
        public Integer returnChequeAmount;
        public Integer returnCount;
        public String remarks;
    }

    public class cls_externalLiabilities {
        public Integer liabilitySequence;
        public String product;
        public String bankName;
        public String otherFinancialInstitute;
        public cls_installmentAmount installmentAmount;
        public String outstandingBalance;
        public String originalAmount;
        public String loanDate;
        public String status;
        public String roi;
        public Integer totalTenure;
        public Integer balanceTenure;
        public Integer noOfBouncesL3m;
        public Integer noOfBouncesL6m;
        public Integer noOfBouncesL12m;
        public String pos;
        public String overdue;
        public Boolean emiConsideredForFoir;
        public Integer sourceOfInfo;
        public Integer trackCheckFrom;
        public String securityDetails;
        public String endUseOfFunds;
        public String repaymentFrom;
        public String repaymentBankAccNo;
        public Boolean consideredRtrBasedLoan;
        public String imputedEmi;
        public String ownerShip;
        public Integer last24Months;
        public Integer last6Months;
        public Integer last3Months;
        public Integer mob;
        public String remarks;
    }

    public class cls_installmentAmount {
        public Integer amount;
    }

    public class cls_applicantAdditionalDetails {
        public String natureOfEmployment;
        public String leadSquaredLeadId;
        public String occupationCategory;
        public cls_customerSalaried customerSalaried;
        public cls_customerSep customerSep;
        public cls_customerSenp customerSenp;
        public cls_customerEntityType customerEntityType;
        public cls_customerAreaName customerAreaName;
        public cls_customerIndividualSalaried customerIndividualSalaried;
        public cls_customerSelfEmployedProfesional customerSelfEmployedProfesional;
        public cls_customerNonIndividual customerNonIndividual;
        public cls_associatedCompanies associatedCompanies;
        public cls_poaHolderDetails poaHolderDetails;
        public cls_nriIncomeDetails nriIncomeDetails;
        public cls_sepEligibility sepEligibility;
        public cls_senpRiskScoreEligibility senpRiskScoreEligibility;
        public cls_senpLatestYearEligibility senpLatestYearEligibility;
        public cls_senpPreviousYearEligibility senpPreviousYearEligibility;
        public cls_senpGrowthPercentageEligibility senpGrowthPercentageEligibility;
        public cls_otherSenpInputEligibility otherSenpInputEligibility;
        public cls_salariedEligibility salariedEligibility;
        public cls_cibil cibil;
        public cls_additionalDetail additionalDetail;
        public cls_digitalData digitalData;
        public String GROWPER;
        public String buffer1;	//#Residence_Ownership_Main
        public String buffer2;	//#Residence_Ownership_CoApp
        public String buffer3;
        public String buffer4;
        public String buffer5;
        public String buffer6;	//#PEP
        public String buffer7;
        public String buffer8;
        public String buffer9;
        public String buffer10;
        public String buffer11;
        public String buffer12;
        public String buffer13;
        public String buffer14;
        public String buffer15;
        public String buffer16;
        public String buffer17;
        public String buffer18;
        public String buffer19;
        public String buffer20;
    }

    public class cls_customerSalaried {
        public String employerName;
        public String emailIdOfficial;
        public String ifSalaried;
        public String designation;
        public Decimal currentWorkExperience;
        public Decimal totalWorkExperience;
        public String idType;
    }

    public class cls_customerSep {
        public String industry;
        public String product;
        public String typeOfService;
        public Decimal totalWorkExperience;	//#totalWorkExperience
    }

    public class cls_customerSenp {
        public String senp;
        public String dateOfCommencement;
        public Decimal totalWorkExperience;
    }

    public class cls_customerEntityType {
        public String businessOrProffessional;
        public String landmark;
        public Integer pinCode;
    }

    public class cls_customerAreaName {
        public String city;
        public String district;
        public String state;
    }

    public class cls_customerIndividualSalaried {
        public Decimal grossAnnualSalaryIncome;
        public Decimal rentalIncome;
        public Decimal otherIncome;
    }

    public class cls_customerSelfEmployedProfesional {
        public Integer grossTurnOver;
        public Decimal grossReceiptFromBusiness;
        public Decimal profession;
        public Decimal rentalIncome;
        public Decimal otherIncome;
    }

    public class cls_customerNonIndividual {
        public Decimal netProfitFromBusiness;
        public Decimal profession;
        public Decimal otherIncome;
    }

    public class cls_associatedCompanies {
        public String associatedCompanyName1;
        public String associatedCompanyName2;
        public String associatedCompanyName3;
        public String associatedCompanyName4;
        public String associatedCompanyName5;
    }

    public class cls_poaHolderDetails {
        public String fullName;
        public String addressType;
        public String landmark;
        public String locality;
        public String city;
        public String subDistrict;
        public String district;
        public String state;
        public String country;
        public String pinCode;
        public String poBox;
        public String photoIdType;
        public String photoIdNo;
        public String addressIdType;
        public String addressIdNo;
        public String mobileNo;
        public String relationWithApplicant;
    }

    public class cls_nriIncomeDetails {
        public String currencyRemove;
        public String dateOfConversion;
        public Decimal rateOfConversion;
        public String monthlyNetSalaryForeignCurrency;
        public String workExperienceAbroadMonths;
    }

    public class cls_sepEligibility {
        public Decimal grossAnnualRecieptsLatestYear;
        public Decimal grossAnnualRecieptsPreviousYear;
        public String isGrowthSustainable;
        public Decimal additionalMultiplier;
        public Decimal additionalFoir;
        public String GROWANNRC;
        public String INCMG;
        public String MAXFOIRSEP;
    }

    public class cls_senpRiskScoreEligibility {
        public String ccOdUtilization;
        public Decimal debtEquityRatio;
        public Decimal abbEmiRatio;
        public String processBelowRiskCutOff;
    }

    public class cls_senpLatestYearEligibility {
        public Decimal oneTimeIncome;
        public Decimal turnover;
        public Decimal grossProfit;
        public Decimal netPbt;
        public Decimal depreciation;
        public Decimal salaryPartner;
        public Decimal interestPartner;
        public Decimal interestRelative;
        public Decimal interestBank;
        public Decimal oneTimeExpense;
        public String CASHPROFLAST;
        public Decimal otherIncome;
    }

    public class cls_senpPreviousYearEligibility {
        public Decimal oneTimeIncome;
        public Decimal turnover;
        public Decimal grossProfit;
        public Decimal netPbt;
        public Decimal depreciation;
        public Decimal salaryPartner;
        public Decimal interestPartner;
        public Decimal interestRelative;
        public Decimal interestBank;
        public Decimal oneTimeExpense;
        public String CASHPROFPREV;
        public Decimal otherIncome;
    }

    public class cls_senpGrowthPercentageEligibility {
        public String isTurnoverGrowthSutainable;
        public String isGrossProfitGrowthSutainable;
        public String isCashProfitGrowthSutainable;
        public String TURNGROPER;
        public String GRPRGRPER;
        public String CASFPRGPER;
    }

    public class cls_otherSenpInputEligibility {
        public Decimal industryMarginCRISIL;
        public Decimal annulisedSalaryDirector;
        public Decimal avgMonthlyBalancePerfios;
        public String maxAbbEmiRatioAllowed;
        public Decimal additionalFoir;
        public Decimal overrideAbbEmiRatio;
        public Decimal additionalGrossMargin;
        public String processBelowRiskCutOff;
        public String incomeProgram;
        public String ELIMAXLA;
        public String MAXFOIRSENP;
        public String MAXGROSSENP;
    }

    public class cls_salariedEligibility {
        public Decimal latestYearBonus;
        public Decimal previousYearBonus;
        public Decimal incentiveMonth1;
        public Decimal incentiveMonth2;
        public Decimal incentiveMonth3;
        public Decimal incentiveMonth4;
        public Decimal incentiveMonth5;
        public Decimal incentiveMonth6;
        public Decimal additionalFoir;
        public String processCaseRiskCutoff;
        public String buffer1;
        public String buffer2;
        public String buffer3;
        public String buffer4;
        public String buffer5;
        public String buffer6;
        public String buffer7;
        public String buffer8;
        public String buffer9;
        public String buffer10;
        public String MAXFOIRSAL;
    }

    public class cls_cibil {
        public String dateProcessed;	//#CIBIL_dateProcessed
        public Decimal liveCreditCardOutstanding;
        public Decimal liveHlOrLapLoanAmount;
        public Decimal liveAutoLoanAmount;
        public Decimal live2WheelerLoanAmount;
        public Decimal liveBlLoanAmount;
        public Decimal livePlLoanAmount;
        public Integer noAccountsDeliquentL6m;
        public Integer noAccounts30DpdL12m;
        public Decimal liveEducationLoanAmount;
        public Decimal creditCardOverdueAmount;
        public String customerName;
        public String panNumber;
        public String memberReferenceNo;
        public String timeProcessed;
        public String scoreName;
        public String scorecardName;
        public String scorecardVersion;
        public String score;	//#Commercial_Bureau_Score
        public Integer noInquiryL3m;
        public Integer plus30DpdL12m;
        public Integer emiBounceL12m;
        public Integer noInquiryL1m;
        public Integer plus30PdpL6m;
        public Integer recentLoans;
        public Integer emiBouncesL3m;
        public Integer emiBouncesL6m;
        public Integer anyDpdL12m;
        public Integer plus60DpdL3m;
        public String derog;
        public String writeOffNonCredit;
        public String creditAmountOverdue;
        public String writeOffCredit;
        public String settle;
        public String restructured;
        public String writeOff;
        public String executionResponse;
        public Integer emiBounceL3m;
        public Decimal liveCreditCardEmi;
        public Decimal liveHlOrLapLoanEmi;
        public Decimal live2WheelerLoanEmi;
        public Decimal liveAutoLoanEmi;
        public Decimal liveBusinessLoanEmi;
        public Decimal livePersonalLoanEmi;
        public Decimal liveEducationLoanEmi;
        public Decimal liveConsumerLoan;
        public Decimal liveConsumerLoanEmi;
        public Decimal liveCommercialVehicleLoan;
        public Decimal liveCommercialVehicleLoanEmi;
        public Decimal liveUsedCardLoan;
        public Decimal liveUsedCardLoanEmi;
        public Decimal liveSecuredCardOutstanding;
        public Decimal liveSecuredAndEmi;
        public Decimal liveLoanOnCreditCard;
        public Decimal liveLoanOnCreditCardEmi;
    }

    public class cls_additionalDetail {
        public String purposeOfLoanOthers;
        public Decimal netBonus;
        public Decimal netAnnual;
        public String buffer1;
        public String buffer2;
        public String buffer3;
        public String buffer4;
        public String buffer5;	//#cc_limit
    }

    public class cls_digitalData {
        public String perfiosIncome;
        public String perfiosObligation;
        public String bureauObligation;
    }

    public class cls_loanBasicDetail {
        public String loanReference;	//#LAN
        public String loanType;	//#LOANTYPE
        public String division;	//CORP
        public String businessVertical;	//#ElasticCreditTypeForOD
        public String productCategory;	//CONV
        public String interestDaysBasis;
        public String applicationNo;
        public String leadId;	//#STPSTATUS
        public cls_sourcingDetails sourcingDetails;
        public cls_keyDetails keyDetails;
        public cls_paymentDetails paymentDetails;
    }

    public class cls_sourcingDetails {
        public String sourcingBranch;	//#AverageI/wReturnasofTotalNoofBusinessDebits
        public String loanBranch;	//#TotalNoofInwardChequeReturns
        public String sourcingChannelCategory;	//#AverageO/wReturnsAsofTotalCredits
        public String directSalesAgent;
        public String refferalId;	//#MonthlyObligationUnsecureLoans
        public String dmaCode;
        public String asmName;	//#ShareHoldingpercentageAllco
        public String employeeName;	//#MaximumDelaydays
        public String sourcingOfficer;	//#MinimunCreditCountPM
        public String salesDepartment;	//#MinimumABB6m
        public String purposeOfLoan;	//#MinimunCreditAmountPM
        public String buffer1;	//#MinimunCreditCountPM
        public String buffer2;	//#AverageLimitUtilisation
        public String buffer3;
        public String buffer4;	//#Key_CIBIL
    }

    public class cls_keyDetails {
        public String loanStartDate;
        public String applicationRequestDate;
        public Decimal firstDisbursementAmount;	//#LOANAMOUNT
        public Decimal netLoanAmount;	//#LOANAMOUNT
        public Decimal loanAmount;	//#LOANAMOUNT
        public Decimal totalDisbursements;
        public Boolean tdsApplicable;
        public Boolean allowGrace;
        public Boolean stepLoan;
        public String eligibilityMethod;
        public Boolean allowOCR;
        public Boolean allowLoanSplit;
        public String parentLoanReference;
    }

    public class cls_paymentDetails {
        public Integer numberOfInstallments;	//#Tenor
        public Decimal paymentAmount;
        public String interestRateType;
        public Boolean allowBPI;
        public String bpiTreatment;
        public String baseRate;	//#BaseRate
        public Decimal fixedRate;
        public Decimal actualInterestRate;
        public Decimal minInterestRate;
        public Decimal maxInterestRate;
        public String scheduleMethod;
        public String interestFrequency;
        public String interestReviewFrequency;
        public String paymentFrequency;
        public String nextInterestFreqDate;
        public String nextInterestReviewFreqDate;
        public String nextPaymentFreqDate;
        public Boolean allowPlannedEMIHoliday;
        public Boolean allowPlannedEMIHolidayGrace;
        public Integer unplannedEMIHolidayLockPeriod;
        public Integer maxUnplannedEMIHolidays;
        public String maturityDate;	//#maturitydate
    }

    public class cls_verifications {
        public cls_fiInitiation[] fiInitiation;
        public cls_tvInitiation tvInitiation;
        public cls_rcuInitiation[] rcuInitiation;
        public cls_pdInitiation[] pdInitiation;
        public cls_lvInitiation lvInitiation;
        public cls_lvWaiver lvWaiver;
    }

    public class cls_fiInitiation {
        public String applicantType;
        public String cif;
        public String name;
        public String addressType;
        public String fiv;
        public String agency;
        public String reason;
        public String remark;
        public String lastVerficationAgency;
        public String lastStatus;	//#FiBL
        public String lastVerificationDate;
    }

    public class cls_tvInitiation {
        public String collatarelType;
        public String depositCif;
        public String depositName;
        // public String collatarelReference;
        public Integer tv;
        public Integer verificationCategory;
        public String agency;
        public Integer reason;
        public String remark;
        public String lastVerficationAgency;
        public String lastStatus;
        public String lastVerificationDate;
    }

    public class cls_rcuInitiation {
        public String documentType;
        public Integer rcu;
        public String bankName;
        public Integer bankAccountNumber;
        public String agency;
        public String reason;
        public String remark;
        public String lastVerficationAgency;
        public String lastStatus;	//#RCUBL
        public String lastVerificationDate;
    }

    public class cls_pdInitiation {
        public String applicantType;
        public String cif;
        public String name;
        public String addressType;
        public Integer pdv;
        public String agency;
        public Integer reason;
        public String remark;
        public String lastVerficationAgency;
        public String lastStatus;
        public String lastVerificationDate;
    }

    public class cls_lvInitiation {
        public String collatarel;
        public String agency;
        public String remark;
        public String decision;
        public String status;
        public String verificationdate;
    }

    public class cls_lvWaiver {
        public String collatarel;
        public String documentType;
        public Integer reason;
        public String remark;
        public String verificationdate;
        public String decision;
        public String status;
    }

    public class cls_schedule {
        public String loanType;
        public String loanReference;
        public String firstdisbursementdate;
        public String currencyRemove;
        public String maturityDate;
        public Decimal loanAmount;
        public Decimal emiamount;
        public Integer emitenure;
        public Integer installmentroi;
        public Boolean preemiapplicableornot;
        public Integer preamitenure;
        public Integer preemiamount;
        public Boolean moratoriumappliableornot;
        public Integer moratoriumtenure;
        public Integer graceperiodroi;
        public Boolean emiholidayepplicableornot;
    }

    public class cls_ocrdetails {
        public Boolean ocrapplicableornot;
        public String parentloanreferencenumber;
        public String ocrid;
        public String ocrdescription;
        public Integer customerportionpercentage;
        public String ocrtype;
        public Integer totaldemand;
        public Integer totalocrreceivable;
    }

    public class cls_step {
        public Boolean stepapplicableornot;
    }

    public class cls_coAppAndGuarantors {
        public cls_coApplicantDetails coApplicantDetails;
        public cls_guarantorsDetails guarantorsDetails;
    }

    public class cls_coApplicantDetails {
        public String customerCif;
        public String customerName;
        public Boolean authoritySignatory;
        public Integer exposureSolePrimary;
        public Integer exposureCoapplicant;
        //public Integer exposureGuarantor;
        public String status;
        public String worstStatus;
    }

    public class cls_guarantorsDetails {
        public String id;
        public String guarantorsName;
        public String idType;
        public Integer gurantee;
        public Integer exposureSolePrimary;
        public Integer exposureCoapplicant;
        public Integer exposureGuarantor;
        public String status;
        public String worstStatus;
        public String contactNumber;
        public String idProof;
    }

    public class cls_applicationAdditionalDetails {
        public Integer selfEmployedRiskScore;
        public Integer selfEmployedRiskSegment;
        public String hunterStatus;
        public String lanHunterStatus;
        public String hunterRcuStatus;
        public String hunterRemark;
        public String remark1;
        public String buffer1;
        public String buffer2;
        public String buffer3;	//#Main_NatureOFBussiness
        public String buffer4;	//#TurnoverasperFinancialsPer
        public String buffer5;
        public String buffer6;	//#PATGrowthPer
        public String buffer7;	//#TurnoverGSTRatio
        public String buffer8;
        public String buffer9;
        public String buffer10;	//#TurnoverasperGSTprev
        public cls_referenceDetails referenceDetails;
        public cls_finalOffer finalOffer;
        public cls_sourcingDetail sourcingDetail;
        public cls_other other;
        public cls_balanceTransfer balanceTransfer;
    }

    public class cls_referenceDetails {
        public Boolean givenGuaranteeToLoan;
        public cls_reference reference1;
        public cls_reference reference2;
    }

    public class cls_reference {
        public String firstName;
        public String lastName;
        public String address;
        public String city;
        public String mobileNo;
        public String state;
        public String pincode;
        public String relationshipWithApplicant;
    }

    public class cls_finalOffer {
        public String additionalLtv;
        public String LOANAMTOFFR;
        public String ROINTR;
        public String LOANTENU;
        public String MAXLOELIGINC;
        public String MAXLOELIGLTV;
        public String MAXLTV;
        public String EMIFINOFF;
        public String FINALFOIR;
        public String FINALLTV;
    }

    public class cls_sourcingDetail {
        public String channelPartnerCode;
        public String ghfRm;
        public String ghfAsm;
        public String refCode1;
        public String refCode2;
        public String refCode3;
        public String refCode4;
        public String refCode5;
        public String refCode6;
        public String schemeCode;	//#CRIFSegmentEditableDTO
        public String employeeCode;
    }

    public class cls_other {
        public String psl;	//#TurnoverasperFinancialsCur
        public String pep;	//#GrossProfitCur
        public String borrowerType;	//#PATCur
        public String lendingType;	//#DepreciationCur
        public String propertyIdentified;	//#SalaryPaidtoPartnerCur
        public String riskCategorization;	//#InterestPaidtoPartnerCur
        public String cinNo;	//#DirectorsRenumerationCur
        public Integer finalFoirPercentage;	//#NonOperatingExpenseCur
        public Integer finalLtvPercentage;	//#OtherIncomeCur
        public Integer finalLoanAmount;	//#OtherExpenseCur
        public String eligibilityMethod;	//#NonOperatingIncomeCur
        public String sblMet;	//#TurnoverasperGSTCur
        public String gblMet;	//#SumofBusinessCreditfor12months
        public String stageOfConstruction;	//#MonthlyAverageBankBalancefor12months
        public Boolean creExposure;	//#TotalMonthlyObligationforBankingSurrogateMethod
        public String rentalIncomeProgram;	//#FinalLoanAmount
        //public String endusageoffunds;	//#EligibilityMethod
        public String buffer1;
        public String buffer2;	//#RequestedLoanAmount
        public String buffer3;
        public String buffer4;	//#TurnoverasperFinancialsprev
        public String buffer5;	//#GrossProfitprev
        public String buffer6;	//#PATprev
        public String buffer7;	//#Depreciationprev
        public String buffer8;	//#SalaryPaidtoPartnerprev
        public String buffer9;	//#InterestPaidtoPartnerprev
        public String buffer10;	//#DirectorsRenumerationprev
        public String buffer11;
        public String buffer12;	//#NonOperatingExpenseprev
        public String buffer13;	//#OtherIncomeprev
        public String buffer14;	//#OtherExpenseprev
        public String buffer15;	//#TotalMonthlyObligationforIncomeandGSTMethod
        public String buffer16;	//#TotalAnnualObligation
        public String buffer17;	//#GreatestIndividualcontributionper
        public String buffer18;	//#ITRFillingDateprev
        public String buffer19;	//#TypeofFinancialsCur
        public String buffer20;	//#TypeofFinancialsprev
        public String buffer21;	//#ITRFillingDateCur
        public String buffer22;
        public String buffer23;	//#TotalincomeCur
        public String buffer24;	//#Totalincomeprev
        public String buffer25;	//#NonOperatingIncomeprev
    }

    public class cls_balanceTransfer {
        public String nameOfFinancialInstitute;
        public String nameOfOtherFinancialInst;
        public Boolean moratoriumSchemeFlagging;
        public Decimal btLoanLanNo;	//#SumofBusinessCredit6m
        public Decimal btOutstanding;	//#Adb180Days
        public Integer btMob;	//#MinimumABB6m
        public String topUpLanNo;	//#MinimumCreditCountP.M.norm6m
        public Integer topUpAmount;	//#MinimumCreditAmountP.M.norm6m
        public String consolidatedLtv;
        public String currentOccupancyOfProperty;
        public String endUseForTopUp;
        public String specifyOtherEndUse;	//#BSASummaryAccountType
    }

    public class cls_collateral {
        public List<cls_property> property;
    }

    public class cls_property {
        public String collateralType;
        public String collateralUsage;
        public String collateralReference;
        public Integer markertValue;
        public String propertyType;
        public String constructionType;
        public String projectName;
        public String developerName;
        public Integer documentedValue;
        public Integer carpetArea;
        public String buffer1;
        public String buffer2;
        public String buffer3;
        public String buffer4;
        public String buffer5;
    }

    public class cls_score {
        public String appScoreRequired;
        public String experianScoreRequired;
        public String experianScoreType;
    }

    public class cls_tvApproval {
        public cls_finalValuationAmount finalValuationAmount;
    }

    public class cls_finalValuationAmount {
        public String collateralReference;
        public Integer finalValAmount;	//#LIMIT_BSA
    }

    public class cls_response {
        public String systemDecision;
        public String systemDecisionDate;	//2050-11-10+05:30
        public String systemDecisionDateTime;	//2022-09-19T19:46:36.789+05:30
        public String strategyUsed;
        public String finalApprovalLevel;
        public cls_calculatedVariables calculatedVariables;
        public cls_errorResponse errorResponse;
        public cls_responseDeviations responseDeviations;
        public String scoreDecision;
        public cls_scoreCardDetails scoreCardDetails;
    }

    public class cls_calculatedVariables {
        public String fieldName;
        public String fieldType;
        public String fieldValue;
        public String productCode;
        public String entityId;
        public String entityType;
        public String purpose;
    }

    public class cls_errorResponse {
        public String errorType;
        public String errorId;
        public String errorName;
        public String errorAction;
        public String errorCode;
        public String errorText;
    }

    public class cls_responseDeviations {
        public String ruleId;
        public String ruleName;
        public String ruleDescription;
        public String ruleAction;
        public String ruleCategory;
        public String reasonText;
        public String approvalLevel;
        public String deviationType;
        public String ruleLevel;
        public String entityId;
        public String entityType;
        public String accountNo;
        public String recommendationText;
    }

    public class cls_scoreCardDetails {
        public String scorecardName;
        public String scorecardScore;
        public String characteristicCount;
        public String scorecardKey;
        public String purpose;
        public String entityId;
        public String entityType;
        public cls_scoreCardCharacteristics scoreCardCharacteristics;
    }

    public class cls_scoreCardCharacteristics {
        public String characteristicName;
        public String characteristicValue;
        public String partialScore;
    }

    public class cls_invocation {
        public String version;
        public String applicationNumber;	//#LAN
        public String applicationDate;	//2025-01-01+00:00
        public String decisionPointAction;	//BUTTON
        public String decisionPoint;	//#DECISION_POINT
        public String decisionService;	//#DECISION_SERVICE
        public String serviceexecute;	//SENP
        public String responseStatus;
    }
}